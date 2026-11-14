import Combine
import ImageIO
import SwiftUI
import UIKit

/// The same sheet as share_sheet.dart.
struct ShareSheetView: View {
    @ObservedObject var intake: SharedIntake
    let context: ShareContext
    let endEditing: () -> Void
    let onClose: (_ isSaved: Bool) -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var isShown = false
    @State private var title = ""
    @State private var text = ""
    @State private var tagIds: Set<String> = []
    @State private var removed: Set<String> = []
    @State private var isSaving = false
    @State private var drag: CGFloat = 0
    @State private var keyboard: CGFloat = 0
    @State private var cardHeight: CGFloat = 400
    @State private var contentHeight: CGFloat = 0

    private var style: ShareStyle { ShareStyle(scheme: scheme, isCompact: context.isCompact) }
    private var isFloating: Bool { keyboard == 0 }
    private var files: [SharedFile] { intake.files.filter { !removed.contains($0.id) } }

    private var wasNothingShared: Bool {
        !intake.isReading && intake.title.isEmpty && intake.text.isEmpty && intake.link == nil && intake.files.isEmpty
    }

    private var hasContent: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || intake.link != nil || !files.isEmpty
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            style.colors.appOverlay
                .opacity(isShown ? max(0, 1 - drag / cardHeight) : 0)
                .ignoresSafeArea()
                .onTapGesture { close(isSaved: false) }
                .accessibilityHidden(true)
            if isShown {
                card
                    .offset(y: drag)
                    .transition(.move(edge: .bottom))
            }
        }
        .onAppear { withAnimation(Springs.smooth) { isShown = true } }
        .onReceive(keyboardHeight) { height in withAnimation(Springs.smooth) { keyboard = height } }
        .onChange(of: intake.isReading) { _ in
            title = intake.title
            text = intake.text
        }
    }

    private var card: some View {
        VStack(spacing: 0) {
            handle
            header
            ScrollView {
                VStack(alignment: .leading, spacing: style.space16) { content }
                    .background(GeometryReader { box in
                        Color.clear.onAppear { contentHeight = box.size.height }
                            .onChange(of: box.size.height) { contentHeight = $0 }
                    })
            }
            .frame(maxHeight: contentHeight)
            footer
        }
        .background(GeometryReader { box in
            Color.clear.onAppear { cardHeight = box.size.height }
                .onChange(of: box.size.height) { cardHeight = $0 }
        })
        .background(style.colors.appSurface)
        .clipShape(cardShape)
        .shadows(style.colors.shadowDialog)
        .padding(.horizontal, isFloating ? 8 : 0)
        .padding(.bottom, isFloating ? 8 : 0)
        .ignoresSafeArea(.container, edges: isFloating ? .bottom : [])
        .padding(.top, 6)
    }

    private var cardShape: SheetShape {
        isFloating
            ? SheetShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
            : SheetShape(TopRoundedRectangle(radius: AnchorTokens.radiusSheet))
    }

    private var handle: some View {
        Capsule()
            .fill(style.colors.appMuted.opacity(0.38))
            .frame(width: 36, height: 5)
            .frame(maxWidth: .infinity, minHeight: 20)
            .contentShape(Rectangle())
            .gesture(dismissDrag)
            .accessibilityHidden(true)
    }

    private var header: some View {
        Text(L.text("shareSheetTitle"))
            .anchor(AnchorTokens.typeSheetTitle, color: style.colors.appText)
            .lineLimit(1)
            .frame(maxWidth: .infinity, minHeight: AnchorTokens.sizeControlMedium)
            .padding(.horizontal, 16)
            .padding(.bottom, style.space16)
            .contentShape(Rectangle())
            .gesture(dismissDrag)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder private var content: some View {
        if context.userId == nil {
            NoticeView(text: L.text("shareSignIn"), isWarning: false, style: style).padding(.horizontal, 16)
        } else if wasNothingShared {
            NoticeView(text: skippedMessage ?? L.text("shareNothing"), isWarning: true, style: style)
                .padding(.horizontal, 16)
        } else {
            DraftCard(
                title: $title, text: $text, link: intake.link, files: files, staging: intake.staging,
                style: style, onRemove: { file in
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation(Springs.snappy) { _ = removed.insert(file.id) }
                }
            )
            .padding(.horizontal, 16)
            if !context.tags.isEmpty {
                TagChoices(tags: context.tags, selected: $tagIds, style: style)
            }
            if let skippedMessage {
                NoticeView(text: skippedMessage, isWarning: true, style: style).padding(.horizontal, 16)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if context.userId == nil || wasNothingShared {
                SheetButton(label: L.text("commonClose"), isPrimary: true, style: style) { close(isSaved: false) }
            } else {
                SheetButton(label: L.text("commonCancel"), isPrimary: false, style: style, isEnabled: !isSaving) {
                    close(isSaved: false)
                }
                SheetButton(
                    label: L.text("commonSave"), isPrimary: true, style: style,
                    isEnabled: hasContent && !isSaving && !intake.isReading, isBusy: isSaving, action: save
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, style.space8 + style.space8)
        .padding(.bottom, isFloating ? style.space16 : 8)
    }

    private var skippedMessage: String? {
        let count = intake.skipped.values.reduce(0, +)
        guard count > 0 else { return nil }
        guard intake.skipped.count == 1, let reason = intake.skipped.keys.first else {
            return L.count("shareNotAdded", count)
        }
        switch reason {
        case .unsupported: return L.count("shareUnsupported", count)
        case .tooBig: return L.count("shareTooBig", count)
        case .overLimit: return L.text("shareOverLimit")
        case .unreadable: return L.count("shareNotAdded", count)
        }
    }

    private var dismissDrag: some Gesture {
        DragGesture()
            .onChanged { value in drag = max(0, value.translation.height) }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.height - value.translation.height
                if velocity > 300 || drag > cardHeight * 0.4 {
                    close(isSaved: false)
                } else {
                    withAnimation(Springs.smooth) { drag = 0 }
                }
            }
    }

    private func save() {
        guard let userId = context.userId, let staging = intake.staging else { return }
        isSaving = true
        Task { @MainActor in
            while intake.isCopying { try? await Task.sleep(nanoseconds: 100_000_000) }
            let kept = files.filter(\.isReady)
            let keptNames = Set(kept.compactMap(\.file))
            for name in (try? FileManager.default.contentsOfDirectory(atPath: staging.path)) ?? []
            where !keptNames.contains(name) {
                try? FileManager.default.removeItem(at: staging.appendingPathComponent(name))
            }
            let entry = ShareEntry(
                id: intake.id, userId: userId, savedAt: ISO8601DateFormatter().string(from: Date()),
                title: title, text: text, link: intake.link,
                tagIds: context.tags.map(\.id).filter(tagIds.contains),
                files: kept.map { ShareEntryFile(file: $0.file!, name: $0.name, mime: $0.mime) }
            )
            do {
                try ShareFolder.save(entry, staging: staging)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                close(isSaved: true)
            } catch {
                isSaving = false
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }

    private func close(isSaved: Bool) {
        endEditing()
        withAnimation(Springs.snappy) {
            isShown = false
            drag = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + AnchorTokens.motionSpringSnappyDuration) {
            onClose(isSaved)
        }
    }

    private var keyboardHeight: AnyPublisher<CGFloat, Never> {
        Publishers.Merge(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                .map { ($0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0 },
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification).map { _ in CGFloat(0) }
        )
        .eraseToAnyPublisher()
    }
}

struct SheetShape: Shape {
    private let make: (CGRect) -> Path

    init<S: Shape>(_ shape: S) { make = { shape.path(in: $0) } }

    func path(in rect: CGRect) -> Path { make(rect) }
}

struct TopRoundedRectangle: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect, byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}

private struct DraftCard: View {
    @Binding var title: String
    @Binding var text: String
    let link: String?
    let files: [SharedFile]
    let staging: URL?
    let style: ShareStyle
    let onRemove: (SharedFile) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AnchorTokens.space8) {
            Field(text: $title, placeholder: L.text("noteTitleHint"), textStyle: AnchorTokens.typeNavTitle,
                  isMultiline: false, style: style)
            Field(text: $text, placeholder: L.text("editorPlaceholder"), textStyle: AnchorTokens.typeRow,
                  isMultiline: true, style: style)
            if let link {
                LinkRow(link: link, style: style).padding(.top, AnchorTokens.space4)
            }
            if !files.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AnchorTokens.space8) {
                        ForEach(files) { file in
                            FileTile(file: file, staging: staging, style: style) { onRemove(file) }
                                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        }
                    }
                }
                .frame(height: 96)
                .padding(.top, AnchorTokens.space4)
            }
        }
        .padding(16)
        .background(style.note.bg)
        .clipShape(RoundedRectangle(cornerRadius: AnchorTokens.radiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AnchorTokens.radiusCard, style: .continuous)
                .strokeBorder(style.note.border, lineWidth: 1)
        )
    }
}

private struct Field: View {
    @Binding var text: String
    let placeholder: String
    let textStyle: AnchorTextStyle
    let isMultiline: Bool
    let style: ShareStyle

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .anchor(textStyle, color: style.note.muted)
                    .accessibilityHidden(true)
            }
            input
                .font(.anchor(textStyle))
                .foregroundColor(style.colors.appText)
                .accentColor(AnchorTokens.colorAccentFill)
                .accessibilityLabel(placeholder)
        }
    }

    @ViewBuilder private var input: some View {
        if isMultiline, #available(iOS 16.0, *) {
            TextField("", text: $text, axis: .vertical).lineLimit(1 ... 8)
        } else {
            TextField("", text: $text).submitLabel(.next)
        }
    }
}

private struct LinkRow: View {
    let link: String
    let style: ShareStyle

    var body: some View {
        let host = URL(string: link)?.host?.replacingOccurrences(of: "^www\\.", with: "", options: .regularExpression)
        HStack(spacing: 12) {
            IconView(icon: .link, size: AnchorTokens.sizeIconMedium, color: style.note.muted)
            VStack(alignment: .leading, spacing: 0) {
                if let host, !host.isEmpty {
                    Text(host).anchor(AnchorTokens.typeUi, weight: 600, color: style.colors.appText).lineLimit(1)
                }
                Text(link).anchor(AnchorTokens.typeFootnote, color: style.note.muted)
                    .lineLimit(1).truncationMode(.tail)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(style.note.surface)
        .clipShape(RoundedRectangle(cornerRadius: AnchorTokens.radiusTile, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AnchorTokens.radiusTile, style: .continuous)
                .strokeBorder(style.note.border.opacity(0.6), lineWidth: 1)
        )
    }
}

private struct FileTile: View {
    let file: SharedFile
    let staging: URL?
    let style: ShareStyle
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            tile
                .frame(width: file.kind == .picture ? 96 : 210, height: 96)
                .background(style.note.surface)
                .clipShape(RoundedRectangle(cornerRadius: AnchorTokens.radiusTile, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AnchorTokens.radiusTile, style: .continuous)
                        .strokeBorder(style.colors.appText.opacity(0.08), lineWidth: 1)
                )
            Button(action: onRemove) {
                IconView(icon: .x, size: 12, color: style.colors.appText)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(style.note.surface.opacity(0.92)))
                    .shadows(style.colors.shadowKnob)
                    .frame(width: AnchorTokens.sizeControlMedium, height: AnchorTokens.sizeControlMedium)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainPress())
            .padding(.top, 4 - 10)
            .padding(.trailing, 4 - 10)
            .accessibilityLabel(L.text("shareRemoveItem", file.name))
        }
    }

    @ViewBuilder private var tile: some View {
        if let name = file.file, let staging {
            if file.kind == .picture {
                Thumbnail(url: staging.appendingPathComponent(name))
            } else {
                AudioTile(file: file, style: style)
            }
        } else {
            ShimmerView(color: style.note.border.opacity(0.6))
        }
    }
}

private struct Thumbnail: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image).resizable().scaledToFill().transition(.opacity)
            }
        }
        .frame(width: 96, height: 96)
        .clipped()
        .task {
            let image = await Task.detached { Self.load(url) }.value
            withAnimation(.easeOut(duration: AnchorTokens.motionDurationFade)) { self.image = image }
        }
    }

    /// The app's cacheWidth: 320.
    private static func load(_ url: URL) -> UIImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceCreateThumbnailWithTransform: true,
                  kCGImageSourceThumbnailMaxPixelSize: 320,
              ] as CFDictionary)
        else { return nil }
        return UIImage(cgImage: image)
    }
}

private struct AudioTile: View {
    let file: SharedFile
    let style: ShareStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            IconView(icon: .audioLines, size: AnchorTokens.sizeIconMedium, color: style.note.muted)
            Spacer(minLength: 0)
            Text((file.name as NSString).deletingPathExtension)
                .anchor(AnchorTokens.typeUi, weight: AnchorTokens.fontWeightMedium, color: style.colors.appText)
                .lineLimit(1)
            if let duration = file.duration {
                Text(Self.label(duration))
                    .font(.anchor(AnchorTokens.typeFootnote))
                    .monospacedDigit()
                    .foregroundColor(style.note.muted)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    /// As durationLabel in note_dates.dart.
    static func label(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let (hours, minutes, rest) = (total / 3600, total % 3600 / 60, total % 60)
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, rest)
            : String(format: "%d:%02d", minutes, rest)
    }
}

/// As the app's Shimmer.
private struct ShimmerView: View {
    let color: Color
    @State private var phase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        color
            .overlay(GeometryReader { box in
                LinearGradient(
                    colors: [.white.opacity(0), .white.opacity(0.35), .white.opacity(0)],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(width: box.size.width * 0.6)
                .offset(x: phase * box.size.width * 1.6)
                .opacity(reduceMotion ? 0 : 1)
            })
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: AnchorTokens.motionDurationShimmer).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

private struct TagChoices: View {
    let tags: [ShareTag]
    @Binding var selected: Set<String>
    let style: ShareStyle

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AnchorTokens.space8) {
                ForEach(tags) { tag in
                    let isOn = selected.contains(tag.id)
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        if isOn { selected.remove(tag.id) } else { selected.insert(tag.id) }
                    } label: {
                        HStack(spacing: AnchorTokens.space8) {
                            IconView(icon: .hash, size: AnchorTokens.sizeIconSmall,
                                     color: isOn ? style.colors.appSurface : style.hash(of: tag.color))
                            Text(tag.name)
                                .anchor(AnchorTokens.typeUi, weight: isOn ? 600 : 400,
                                        color: isOn ? style.colors.appSurface : style.colors.appText)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .frame(minHeight: AnchorTokens.sizeControlSmall)
                        .background(Capsule().fill(isOn ? style.colors.appText : style.colors.appText.opacity(0.07)))
                        .animation(.easeOut(duration: AnchorTokens.motionDurationHover), value: isOn)
                    }
                    .buttonStyle(ScalePress())
                    .accessibilityLabel(L.text("shareTag", tag.name))
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct NoticeView: View {
    let text: String
    let isWarning: Bool
    let style: ShareStyle

    var body: some View {
        Text(text)
            .anchor(AnchorTokens.typeUi, color: isWarning ? style.colors.statusWarnText : style.colors.appText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, style.space12)
            .background(
                RoundedRectangle(cornerRadius: AnchorTokens.radius2xl, style: .continuous)
                    .fill(isWarning ? style.colors.statusWarnFill : style.colors.appText.opacity(0.06))
            )
    }
}

/// As the app's AppButton.
private struct SheetButton: View {
    let label: String
    let isPrimary: Bool
    let style: ShareStyle
    var isEnabled = true
    var isBusy = false
    let action: () -> Void

    var body: some View {
        let foreground = isPrimary ? style.colors.appOnInverse : style.colors.appText
        Button(action: action) {
            HStack(spacing: 8) {
                if isBusy { Spinner(color: foreground) }
                Text(label)
                    .font(.anchor(AnchorTokens.typeRow, weight: 600))
                    .foregroundColor(foreground)
                    .lineLimit(1)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, minHeight: style.control, maxHeight: style.control)
            .background(Capsule().fill(isPrimary ? style.colors.appInverse : style.colors.appText.opacity(0.08)))
            .opacity(isEnabled || isBusy ? 1 : Press.disabledButton)
            .animation(.easeOut(duration: AnchorTokens.motionDurationFade), value: isEnabled)
        }
        .buttonStyle(ScalePress())
        .disabled(!isEnabled)
    }
}

private struct Spinner: View {
    let color: Color
    @State private var turned = false

    var body: some View {
        IconView(icon: .loaderCircle, size: AnchorTokens.sizeIconMedium, color: color)
            .rotationEffect(.degrees(turned ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: AnchorTokens.motionDurationSpin).repeatForever(autoreverses: false)) {
                    turned = true
                }
            }
    }
}

/// As PressStyle.button.
private struct ScalePress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? Press.buttonScale : 1)
            .animation(Springs.snappy, value: configuration.isPressed)
    }
}

/// As PressStyle.plain.
private struct PlainPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? Press.plainOpacity : 1)
            .animation(.easeOut(duration: AnchorTokens.motionDurationPress), value: configuration.isPressed)
    }
}
