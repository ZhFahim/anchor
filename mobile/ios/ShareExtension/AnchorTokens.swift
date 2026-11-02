// Generated from design/tokens by design/build. Do not edit by hand.
//
// AnchorTokens holds what stays the same in light and dark, AnchorColors the
// rest. Text styles carry size, weight, line height and tracking only.

import SwiftUI

enum AnchorTokens {
    /// Dark slate: light text, primary and inverse
    static let colorBrandSlate: Color = Color(.sRGB, red: 0.1765, green: 0.1922, blue: 0.2588, opacity: 1)
    /// Slate blue: light secondary text
    static let colorBrandSlateBlue: Color = Color(.sRGB, red: 0.3098, green: 0.3647, blue: 0.4588, opacity: 1)
    /// Between slate blue and mist
    static let colorBrandSlateGray: Color = Color(.sRGB, red: 0.4196, green: 0.4784, blue: 0.5608, opacity: 1)
    /// Dark secondary text
    static let colorBrandMist: Color = Color(.sRGB, red: 0.6118, green: 0.6588, blue: 0.7216, opacity: 1)
    /// Light page
    static let colorBrandCloud: Color = Color(.sRGB, red: 0.9412, green: 0.9569, blue: 0.9725, opacity: 1)
    /// Dark page
    static let colorBrandNight: Color = Color(.sRGB, red: 0.0667, green: 0.0706, blue: 0.0784, opacity: 1)
    /// Dark surface
    static let colorBrandDusk: Color = Color(.sRGB, red: 0.1098, green: 0.1137, blue: 0.1294, opacity: 1)
    /// Dark text
    static let colorBrandOffWhite: Color = Color(.sRGB, red: 0.9176, green: 0.9176, blue: 0.9176, opacity: 1)
    /// White
    static let colorBrandWhite: Color = Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
    /// Burnt orange, the accent
    static let colorBrandOrange: Color = Color(.sRGB, red: 0.9373, green: 0.5137, blue: 0.3294, opacity: 1)
    /// Large fills and tints only: text selection and the drop area
    static let colorAccentFill: Color = Color(.sRGB, red: 0.9373, green: 0.5137, blue: 0.3294, opacity: 1)
    /// The round knob of a switch
    static let colorControlKnob: Color = Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
    static let colorAvatarRust: Color = Color(.sRGB, red: 0.6431, green: 0.3216, blue: 0.1647, opacity: 1)
    static let colorAvatarBlue: Color = Color(.sRGB, red: 0.2471, green: 0.4353, blue: 0.651, opacity: 1)
    static let colorAvatarPurple: Color = Color(.sRGB, red: 0.5412, green: 0.3098, blue: 0.6392, opacity: 1)
    static let colorAvatarTeal: Color = Color(.sRGB, red: 0.1843, green: 0.4902, blue: 0.4275, opacity: 1)
    static let colorAvatarOlive: Color = Color(.sRGB, red: 0.4157, green: 0.4353, blue: 0.1647, opacity: 1)
    static let colorAvatarBrown: Color = Color(.sRGB, red: 0.4784, green: 0.2941, blue: 0.1843, opacity: 1)
    static let colorAvatarRose: Color = Color(.sRGB, red: 0.6314, green: 0.2471, blue: 0.3608, opacity: 1)
    static let colorAvatarNavy: Color = Color(.sRGB, red: 0.2314, green: 0.3725, blue: 0.5412, opacity: 1)
    static let colorAvatarAmber: Color = Color(.sRGB, red: 0.6039, green: 0.3569, blue: 0.0863, opacity: 1)
    static let colorAvatarIndigo: Color = Color(.sRGB, red: 0.302, green: 0.3608, blue: 0.6196, opacity: 1)
    static let colorAvatarMoss: Color = Color(.sRGB, red: 0.3333, green: 0.4196, blue: 0.1843, opacity: 1)
    /// Initials on an avatar
    static let colorAvatarText: Color = Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
    /// The cool glow behind the sign-in collage
    static let colorDecorGlow: Color = Color(.sRGB, red: 0.3922, green: 0.7098, blue: 0.9647, opacity: 1)
    /// Behind the picture viewer
    static let colorMediaScrim: Color = Color(.sRGB, red: 0.0471, green: 0.0549, blue: 0.0706, opacity: 0.95)
    /// Over a picture, behind a count like +3
    static let colorMediaShade: Color = Color(.sRGB, red: 0.0471, green: 0.0549, blue: 0.0706, opacity: 0.45)
    /// Behind a small count on a thumbnail
    static let colorMediaShadeStrong: Color = Color(.sRGB, red: 0.0471, green: 0.0549, blue: 0.0706, opacity: 0.6)
    /// Text over pictures and in the viewer
    static let colorMediaText: Color = Color(.sRGB, red: 0.9451, green: 0.949, blue: 0.9569, opacity: 1)
    /// Second lines in the viewer, 8.5 : 1 on its shade
    static let colorMediaMuted: Color = Color(.sRGB, red: 0.6627, green: 0.6863, blue: 0.7333, opacity: 1)
    /// Hints in the viewer, 6 : 1 on its shade
    static let colorMediaFaint: Color = Color(.sRGB, red: 0.5529, green: 0.5804, blue: 0.6314, opacity: 1)
    /// Buttons in the viewer
    static let colorMediaControl: Color = Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.1)
    /// Those buttons when hovered
    static let colorMediaControlHover: Color = Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.18)
    /// A hairline inside a picture tile
    static let colorMediaEdge: Color = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.06)
    static let space0: CGFloat = 0
    static let space2: CGFloat = 2
    static let space4: CGFloat = 4
    static let space6: CGFloat = 6
    static let space8: CGFloat = 8
    static let space10: CGFloat = 10
    static let space12: CGFloat = 12
    static let space14: CGFloat = 14
    static let space16: CGFloat = 16
    static let space20: CGFloat = 20
    static let space24: CGFloat = 24
    static let space28: CGFloat = 28
    static let space32: CGFloat = 32
    static let space40: CGFloat = 40
    static let space48: CGFloat = 48
    static let space56: CGFloat = 56
    static let space64: CGFloat = 64
    static let space80: CGFloat = 80
    static let space96: CGFloat = 96
    /// Mobile AppDimensions.xxs
    static let spaceXxs: CGFloat = 4
    /// Mobile AppDimensions.xs
    static let spaceXs: CGFloat = 8
    /// Mobile AppDimensions.sm
    static let spaceSm: CGFloat = 12
    /// Mobile AppDimensions.md
    static let spaceMd: CGFloat = 16
    /// Mobile AppDimensions.lg
    static let spaceLg: CGFloat = 20
    /// Mobile AppDimensions.xl
    static let spaceXl: CGFloat = 24
    /// Mobile AppDimensions.xxl
    static let spaceXxl: CGFloat = 32
    /// Side padding of a page on desktop
    static let spaceGutter: CGFloat = 28
    /// Side padding of a page on phones, the same as mobile's screenGutter
    static let spaceGutterPhone: CGFloat = 16
    /// Checkboxes, keyboard keys, small badges
    static let radiusXs: CGFloat = 6
    /// Menu items, small buttons, swatches
    static let radiusSm: CGFloat = 8
    /// Buttons, fields, rows in the sidebar
    static let radiusMd: CGFloat = 10
    /// Tiles and the floating bars on a note
    static let radiusLg: CGFloat = 12
    /// Grouped lists, picture cards, bars and menus
    static let radiusXl: CGFloat = 14
    /// Cards, panels and pop-overs
    static let radius2xl: CGFloat = 16
    /// Dialogs
    static let radius3xl: CGFloat = 20
    /// Phone: sheets, dialogs and the drawer
    static let radius4xl: CGFloat = 28
    /// Notes and note cards
    static let radiusNote: CGFloat = 18
    /// The floating new-note button, like mobile's AppRadius.fab
    static let radiusFab: CGFloat = 18
    /// Chips, badges, switches
    static let radiusPill: CGFloat = 999
    static let radiusCheckbox: CGFloat = 6
    static let radiusMenuItem: CGFloat = 8
    static let radiusMenu: CGFloat = 14
    static let radiusPopover: CGFloat = 16
    static let radiusButton: CGFloat = 10
    static let radiusField: CGFloat = 10
    static let radiusTile: CGFloat = 12
    static let radiusFloating: CGFloat = 12
    static let radiusCard: CGFloat = 16
    static let radiusDialog: CGFloat = 20
    static let radiusSheet: CGFloat = 28
    /// The smallest anything clickable may be (WCAG 2.2, 2.5.8)
    static let sizeTargetMin: CGFloat = 24
    /// Icon buttons on desktop
    static let sizeTargetDesktop: CGFloat = 34
    /// Icon buttons on phones
    static let sizeTargetPhone: CGFloat = 40
    /// Phone: the smallest thing a finger can tap; Android pads it to 48 with the hit area, not the drawing
    static let sizeTargetTouch: CGFloat = 44
    /// Phone: small buttons and pills, like Done in a sheet; the touch area stays 44
    static let sizeControlSmall: CGFloat = 32
    /// Phone: icon buttons, segmented controls, menu items, the toolbar, search in a sheet
    static let sizeControlMedium: CGFloat = 44
    /// Phone: buttons, fields, one-line rows, the dock
    static let sizeControlLarge: CGFloat = 52
    /// Phone: in small text and small controls: meta lines, chips, help, counts
    static let sizeIconSmall: CGFloat = 16
    /// Phone: in rows, fields, menus, buttons, banners
    static let sizeIconMedium: CGFloat = 20
    /// Phone: in bars, the toolbar, the dock and the selection bar
    static let sizeIconLarge: CGFloat = 24
    /// Text fields
    static let sizeField: CGFloat = 40
    /// Text fields and buttons on sign in
    static let sizeFieldLarge: CGFloat = 44
    /// Phone: text fields
    static let sizeFieldPhone: CGFloat = 52
    /// Tag and reminder chips
    static let sizeChip: CGFloat = 27
    /// Chips on cards
    static let sizeChipCard: CGFloat = 22
    /// Checkboxes
    static let sizeCheckbox: CGFloat = 18
    /// Checkboxes on cards
    static let sizeCheckboxCard: CGFloat = 14
    /// Toolbar buttons are a little taller than wide
    static let sizeToolbarButtonWidth: CGFloat = 26
    /// Toolbar buttons
    static let sizeToolbarButtonHeight: CGFloat = 28
    /// Square on phones
    static let sizeToolbarButtonPhone: CGFloat = 40
    /// Each list level
    static let sizeListIndent: CGFloat = 26
    /// Each list level on cards
    static let sizeListIndentCard: CGFloat = 14
    /// Lists go three levels deep
    static let sizeListDepth: CGFloat = 3
    /// The sidebar
    static let sizeSidebar: CGFloat = 248
    /// Folded to icons
    static let sizeSidebarFolded: CGFloat = 64
    /// The drawer on phones
    static let sizeSidebarDrawer: CGFloat = 292
    /// Phone: buttons in sheets, forms and docks
    static let sizeButtonPhone: CGFloat = 52
    /// Phone: the floating search field and the round buttons beside it
    static let sizeDock: CGFloat = 52
    /// Phone: the least height of a row in a grouped list; a row with a second line grows, 12 above and below
    static let sizeRow: CGFloat = 52
    static let densityDefaultSpace8: CGFloat = 8
    static let densityDefaultSpace12: CGFloat = 12
    static let densityDefaultSpace16: CGFloat = 16
    static let densityDefaultSpace24: CGFloat = 24
    static let densityDefaultSpace32: CGFloat = 32
    static let densityDefaultSpace48: CGFloat = 48
    /// Buttons, fields, one-line rows, the dock, New note and snackbars
    static let densityDefaultControl: CGFloat = 52
    /// The top bar under the status bar
    static let densityDefaultBar: CGFloat = 52
    /// Line height of note text in the editor and versions
    static let densityDefaultNoteLineHeight: CGFloat = 1.7
    static let densityDefaultPreviewMasonry: CGFloat = 6
    static let densityDefaultPreviewGrid: CGFloat = 4
    static let densityDefaultPreviewList: CGFloat = 2
    static let densityDefaultPreviewPictures: CGFloat = 4
    static let densityCompactSpace8: CGFloat = 4
    static let densityCompactSpace12: CGFloat = 8
    static let densityCompactSpace16: CGFloat = 12
    static let densityCompactSpace24: CGFloat = 16
    static let densityCompactSpace32: CGFloat = 24
    static let densityCompactSpace48: CGFloat = 32
    /// What is 52 at Default is 44, still a full touch area
    static let densityCompactControl: CGFloat = 44
    /// The top bar under the status bar, as tall as its buttons
    static let densityCompactBar: CGFloat = 44
    /// Line height of note text in the editor and versions
    static let densityCompactNoteLineHeight: CGFloat = 1.55
    static let densityCompactPreviewMasonry: CGFloat = 4
    static let densityCompactPreviewGrid: CGFloat = 3
    static let densityCompactPreviewList: CGFloat = 1
    static let densityCompactPreviewPictures: CGFloat = 2
    /// The page
    static let layerBase: CGFloat = 0
    /// A part lifted inside its own component, like the actions on a card
    static let layerRaised: CGFloat = 1
    /// The top bar and the save bar
    static let layerSticky: CGFloat = 10
    /// The selection bar and the new-note button
    static let layerFloat: CGFloat = 20
    /// The shade behind the phone drawer
    static let layerScrim: CGFloat = 30
    /// The sidebar
    static let layerDrawer: CGFloat = 40
    /// Dialogs and the shade behind them
    static let layerOverlay: CGFloat = 50
    /// Menus and pickers, also when opened from a dialog
    static let layerPopover: CGFloat = 60
    /// Toasts, above everything you can act on
    static let layerToast: CGFloat = 70
    /// Tooltips
    static let layerTooltip: CGFloat = 80
    /// Larger phones in landscape
    static let breakpointSm: CGFloat = 640
    /// Below this: the phone layout (drawer, new-note button, sheets, toolbar at the bottom)
    static let breakpointMd: CGFloat = 768
    /// From here: the sidebar is open and sign in shows the collage
    static let breakpointLg: CGFloat = 1024
    /// Wide screens
    static let breakpointXl: CGFloat = 1280
    static let fontWeightRegular: Int = 400
    static let fontWeightMedium: Int = 500
    static let fontWeightSemibold: Int = 600
    static let fontWeightBold: Int = 700
    /// Note title in the editor
    static let typeNoteTitle: AnchorTextStyle = AnchorTextStyle(size: 34, lineHeight: 1.12, weight: 700, tracking: -0.952)
    /// Note title on phones
    static let typeNoteTitlePhone: AnchorTextStyle = AnchorTextStyle(size: 27, lineHeight: 1.12, weight: 700, tracking: -0.756)
    /// Note text
    static let typeBody: AnchorTextStyle = AnchorTextStyle(size: 16.5, lineHeight: 1.7, weight: 500, tracking: 0)
    /// Code blocks (mono)
    static let typeCode: AnchorTextStyle = AnchorTextStyle(size: 13.5, lineHeight: 1.7, weight: 400, tracking: 0)
    /// Details under the title, save status
    static let typeMeta: AnchorTextStyle = AnchorTextStyle(size: 13, lineHeight: 1.4, weight: 400, tracking: 0)
    /// Tag and reminder chips
    static let typeChip: AnchorTextStyle = AnchorTextStyle(size: 12.5, lineHeight: 1, weight: 500, tracking: 0)
    /// Title on a note card
    static let typeCardTitle: AnchorTextStyle = AnchorTextStyle(size: 15.5, lineHeight: 1.3, weight: 600, tracking: -0.186)
    /// Text on a note card
    static let typeCardBody: AnchorTextStyle = AnchorTextStyle(size: 13.5, lineHeight: 1.5, weight: 500, tracking: 0)
    /// Uppercase group labels
    static let typeLabel: AnchorTextStyle = AnchorTextStyle(size: 12, lineHeight: 1.3, weight: 600, tracking: 0.72)
    /// Keyboard keys, day letters, the smallest labels
    static let typeCaption: AnchorTextStyle = AnchorTextStyle(size: 11.5, lineHeight: 1.3, weight: 500, tracking: 0)
    /// Card footers, hints at the foot of a panel, and the small buttons on code blocks and attachments
    static let typeFootnote: AnchorTextStyle = AnchorTextStyle(size: 12, lineHeight: 1.4, weight: 400, tracking: 0)
    /// Help under a field, second lines, counts
    static let typeSmall: AnchorTextStyle = AnchorTextStyle(size: 12.5, lineHeight: 1.45, weight: 400, tracking: 0)
    /// Buttons, tabs, menu items
    static let typeControl: AnchorTextStyle = AnchorTextStyle(size: 13.5, lineHeight: 1.3, weight: 500, tracking: 0)
    /// Text in the app around the notes
    static let typeUi: AnchorTextStyle = AnchorTextStyle(size: 14, lineHeight: 1.45, weight: 400, tracking: 0)
    /// The line under a big title, large buttons
    static let typeLead: AnchorTextStyle = AnchorTextStyle(size: 15, lineHeight: 1.5, weight: 400, tracking: 0)
    /// Section titles in settings and admin
    static let typeTitle: AnchorTextStyle = AnchorTextStyle(size: 16, lineHeight: 1.35, weight: 600, tracking: -0.16)
    /// Dialog titles, empty states, the reminder summary
    static let typeHeading: AnchorTextStyle = AnchorTextStyle(size: 18, lineHeight: 1.3, weight: 700, tracking: -0.252)
    /// Page titles
    static let typePage: AnchorTextStyle = AnchorTextStyle(size: 23, lineHeight: 1.2, weight: 700, tracking: -0.506)
    /// Page titles on phones
    static let typePagePhone: AnchorTextStyle = AnchorTextStyle(size: 21, lineHeight: 1.2, weight: 700, tracking: -0.462)
    /// Sign in and big numbers
    static let typeDisplay: AnchorTextStyle = AnchorTextStyle(size: 28, lineHeight: 1.15, weight: 700, tracking: -0.784)
    /// Phone: a page title at the top of a list, before it collapses into the bar. Lining figures.
    static let typeLargeTitle: AnchorTextStyle = AnchorTextStyle(size: 28, lineHeight: 1.15, weight: 700, tracking: -0.28)
    /// Phone: the title in the bar once the large title has scrolled away
    static let typeNavTitle: AnchorTextStyle = AnchorTextStyle(size: 17, lineHeight: 1.3, weight: 600, tracking: -0.17)
    /// Phone: the title of a sheet
    static let typeSheetTitle: AnchorTextStyle = AnchorTextStyle(size: 20, lineHeight: 1.25, weight: 700, tracking: -0.3)
    /// Phone: rows, buttons, fields and search
    static let typeRow: AnchorTextStyle = AnchorTextStyle(size: 16, lineHeight: 1.35, weight: 400, tracking: 0)
    /// Heading 1 in a note: size as a multiple of the note text
    static let headingH1Scale: CGFloat = 1.55
    static let headingH1LineHeight: CGFloat = 1.22
    static let headingH1Weight: Int = 700
    /// Letter spacing in em
    static let headingH1Tracking: CGFloat = -0.022
    /// Heading 2: size as a multiple of the note text
    static let headingH2Scale: CGFloat = 1.24
    static let headingH2LineHeight: CGFloat = 1.3
    static let headingH2Weight: Int = 700
    /// Letter spacing in em
    static let headingH2Tracking: CGFloat = -0.012
    /// Heading 3, in secondary text color: size as a multiple of the note text
    static let headingH3Scale: CGFloat = 1.03
    static let headingH3LineHeight: CGFloat = 1.45
    static let headingH3Weight: Int = 600
    /// Letter spacing in em
    static let headingH3Tracking: CGFloat = 0
    /// A button being pressed
    static let motionDurationPress: TimeInterval = 0.1
    /// Hover and press feedback
    static let motionDurationHover: TimeInterval = 0.15
    /// Things fading in: menus, tooltips, the background changing color
    static let motionDurationFade: TimeInterval = 0.2
    /// A ticked item sliding below the open ones, after a 320 ms pause
    static let motionDurationSink: TimeInterval = 0.28
    /// The header sliding away and back while scrolling
    static let motionDurationHeader: TimeInterval = 0.3
    /// The check mark popping in
    static let motionDurationTick: TimeInterval = 0.3
    /// Progress bars, pictures fading in, a sheet leaving
    static let motionDurationSlow: TimeInterval = 0.3
    /// A new highlight drawing in, line by line
    static let motionDurationPaint: TimeInterval = 0.6
    /// Things coming in or sliding to a new place: bars, dialogs, cards, chips, the chosen option
    static let motionDurationMove: TimeInterval = 0.24
    /// The pause before a ticked item sinks
    static let motionDurationSinkDelay: TimeInterval = 0.32
    /// Things leaving: menus, pop-overs, dialogs, toasts and tooltips fade out faster than they came in
    static let motionDurationExit: TimeInterval = 0.14
    /// A card growing into the open note, and shrinking back
    static let motionDurationMorph: TimeInterval = 0.38
    /// The read-only bar shaking when you try to type
    static let motionDurationNudge: TimeInterval = 0.42
    /// A late reminder's bell ringing once
    static let motionDurationRing: TimeInterval = 0.9
    /// One blink of a text caret
    static let motionDurationBlink: TimeInterval = 1
    /// One turn of a spinner
    static let motionDurationSpin: TimeInterval = 1
    /// One sweep of a loading shimmer
    static let motionDurationShimmer: TimeInterval = 1.4
    /// A flash that says “here”: a highlight you jumped to, a person just added
    static let motionDurationFlash: TimeInterval = 1.4
    /// One slow sway: the floating cards on sign in, the waiting picture
    static let motionDurationSway: TimeInterval = 2.4
    /// Phone: how long a finger rests before a long press starts selecting
    static let motionDurationLongPress: TimeInterval = 0.42
    static let motionSpringSmoothDuration: TimeInterval = 0.5
    static let motionSpringSmoothBounce: CGFloat = 0
    static let motionSpringSnappyDuration: TimeInterval = 0.32
    static let motionSpringSnappyBounce: CGFloat = 0.12
    static let motionSpringPopDuration: TimeInterval = 0.42
    static let motionSpringPopBounce: CGFloat = 0.35
    static let motionSpringKeyboardDuration: TimeInterval = 0.38
    static let motionSpringKeyboardBounce: CGFloat = 0
    /// Percent of the late red mixed into a late reminder chip
    static let blendLateChip: CGFloat = 10

    /// Tag palette names by the color a tag stores.
    static let tagNames: [String: String] = [
        "#E57373": "red",
        "#F06292": "pink",
        "#BA68C8": "purple",
        "#9575CD": "deepPurple",
        "#7986CB": "indigo",
        "#64B5F6": "blue",
        "#4FC3F7": "lightBlue",
        "#4DD0E1": "cyan",
        "#4DB6AC": "teal",
        "#81C784": "green",
        "#AED581": "lightGreen",
        "#DCE775": "lime",
        "#FFD54F": "amber",
        "#FFB74D": "orange",
        "#FF8A65": "deepOrange",
        "#A1887F": "brown",
        "#90A4AE": "blueGrey",
    ]

    /// The note palette of a note with no background.
    static let defaultNotePalette = "none"
}

struct AnchorTextStyle {
    let size: CGFloat
    /// A multiple of [size].
    let lineHeight: CGFloat
    let weight: Int
    let tracking: CGFloat
}

struct AnchorShadow {
    let color: Color
    let x: CGFloat
    let y: CGFloat
    let blur: CGFloat
    let spread: CGFloat
}

struct AnchorNoteColors {
    let bg: Color
    let surface: Color
    let border: Color
    let pattern: Color
    let muted: Color
}

/// How a tag is drawn: its stored color, the # on a chip, and its swatch fill.
struct AnchorTagColors {
    let stored: Color
    let hash: Color
    let tintFill: Color
}

struct AnchorColors {
    /// Anything thin in orange: ticked boxes, rings, focus, the current marker, progress, drop lines
    let accentStrong: Color
    /// Orange text, such as links
    let accentInk: Color
    /// Page background
    let appPage: Color
    /// Cards, menus, dialogs and plain notes
    let appSurface: Color
    /// Text and primary buttons
    let appText: Color
    /// Secondary text and icons
    let appMuted: Color
    /// Borders of cards and menus
    let appBorder: Color
    /// Lines inside a card or list
    let appDivider: Color
    /// Muted fills and hover
    let appSubtle: Color
    /// The sidebar, beside the page
    let appSidebar: Color
    /// The selection bar, save bar and toasts
    let appInverse: Color
    /// Text on those
    let appOnInverse: Color
    /// Undo on a toast
    let appInverseLink: Color
    /// The icon and time line on an error toast
    let appInverseDanger: Color
    /// Behind dialogs and the phone drawer
    let appOverlay: Color
    /// Text field borders, 3 : 1 on the page
    let appFieldLine: Color
    /// The tick inside a ticked box
    let checkMark: Color
    /// Delete buttons, errors, failed uploads
    let statusDanger: Color
    /// A reminder that has passed
    let statusLate: Color
    /// Added text in history (mixed into the note color)
    let statusAdded: Color
    /// Removed text in history (mixed into the note color)
    let statusRemoved: Color
    /// The + sign and bar
    let statusAddedInk: Color
    /// The − sign and bar
    let statusRemovedInk: Color
    /// Warning labels, like “Not saved”
    let statusWarnText: Color
    /// Behind warning labels
    let statusWarnFill: Color
    /// Text on a red button
    let statusOnDanger: Color
    /// Percent of green behind an added line
    let blendAddedLine: CGFloat
    /// Percent of green behind an added word
    let blendAddedWord: CGFloat
    /// Percent of red behind a removed line
    let blendRemovedLine: CGFloat
    /// Percent of red behind a removed word
    let blendRemovedWord: CGFloat
    /// Notes and cards
    let shadowRaised: [AnchorShadow]
    /// Floating bars on a note
    let shadowFloating: [AnchorShadow]
    /// Menus and pop-overs
    let shadowMenu: [AnchorShadow]
    /// A card being hovered or dragged
    let shadowLift: [AnchorShadow]
    /// Dialogs
    let shadowDialog: [AnchorShadow]
    /// A hairline around the logo and pictures
    let shadowEdge: [AnchorShadow]
    /// A control that sits a little above its row
    let shadowXs: [AnchorShadow]
    /// Small buttons over a picture or card
    let shadowSm: [AnchorShadow]
    /// The dark New note button
    let shadowControl: [AnchorShadow]
    /// The knob of a switch
    let shadowKnob: [AnchorShadow]
    /// The selection bar, save bar and toasts
    let shadowBar: [AnchorShadow]
    /// The new-note button on phones
    let shadowFab: [AnchorShadow]
    /// The small picture that follows the pointer while dragging
    let shadowGhost: [AnchorShadow]

    /// Note colors by palette name.
    let notes: [String: AnchorNoteColors]

    /// Tag colors by palette name.
    let tags: [String: AnchorTagColors]

    static let light = AnchorColors(
        accentStrong: Color(.sRGB, red: 0.8, green: 0.3725, blue: 0.1765, opacity: 1),
        accentInk: Color(.sRGB, red: 0.6431, green: 0.251, blue: 0.0157, opacity: 1),
        appPage: Color(.sRGB, red: 0.9412, green: 0.9569, blue: 0.9725, opacity: 1),
        appSurface: Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1),
        appText: Color(.sRGB, red: 0.0706, green: 0.0784, blue: 0.102, opacity: 1),
        appMuted: Color(.sRGB, red: 0.2275, green: 0.2353, blue: 0.2588, opacity: 1),
        appBorder: Color(.sRGB, red: 0.8471, green: 0.8706, blue: 0.902, opacity: 1),
        appDivider: Color(.sRGB, red: 0.902, green: 0.9216, blue: 0.9451, opacity: 1),
        appSubtle: Color(.sRGB, red: 0.9098, green: 0.9255, blue: 0.9451, opacity: 1),
        appSidebar: Color(.sRGB, red: 0.9137, green: 0.9333, blue: 0.9529, opacity: 1),
        appInverse: Color(.sRGB, red: 0.1765, green: 0.1922, blue: 0.2588, opacity: 1),
        appOnInverse: Color(.sRGB, red: 0.9608, green: 0.9647, blue: 0.9725, opacity: 1),
        appInverseLink: Color(.sRGB, red: 0.9529, green: 0.6039, blue: 0.4392, opacity: 1),
        appInverseDanger: Color(.sRGB, red: 1, green: 0.5608, blue: 0.5216, opacity: 1),
        appOverlay: Color(.sRGB, red: 0.1098, green: 0.1216, blue: 0.1647, opacity: 0.3608),
        appFieldLine: Color(.sRGB, red: 0.4706, green: 0.5176, blue: 0.5922, opacity: 1),
        checkMark: Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1),
        statusDanger: Color(.sRGB, red: 0.7529, green: 0.2235, blue: 0.1686, opacity: 1),
        statusLate: Color(.sRGB, red: 0.651, green: 0.1176, blue: 0.0784, opacity: 1),
        statusAdded: Color(.sRGB, red: 0.1216, green: 0.6157, blue: 0.3333, opacity: 1),
        statusRemoved: Color(.sRGB, red: 0.8157, green: 0.2275, blue: 0.3098, opacity: 1),
        statusAddedInk: Color(.sRGB, red: 0.0863, green: 0.4353, blue: 0.2667, opacity: 1),
        statusRemovedInk: Color(.sRGB, red: 0.6902, green: 0.1333, blue: 0.2157, opacity: 1),
        statusWarnText: Color(.sRGB, red: 0.5412, green: 0.2941, blue: 0.0314, opacity: 1),
        statusWarnFill: Color(.sRGB, red: 0.9922, green: 0.9255, blue: 0.7843, opacity: 1),
        statusOnDanger: Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1),
        blendAddedLine: 14,
        blendAddedWord: 30,
        blendRemovedLine: 16,
        blendRemovedWord: 26,
        shadowRaised: [AnchorShadow(color: Color(.sRGB, red: 0.1765, green: 0.1922, blue: 0.2588, opacity: 0.06), x: 0, y: 8, blur: 24, spread: 0), AnchorShadow(color: Color(.sRGB, red: 0.1765, green: 0.1922, blue: 0.2588, opacity: 0.05), x: 0, y: 1, blur: 2, spread: 0)],
        shadowFloating: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.14), x: 0, y: 8, blur: 22, spread: 0)],
        shadowMenu: [AnchorShadow(color: Color(.sRGB, red: 0.1765, green: 0.1922, blue: 0.2588, opacity: 0.14), x: 0, y: 16, blur: 32, spread: -8), AnchorShadow(color: Color(.sRGB, red: 0.1765, green: 0.1922, blue: 0.2588, opacity: 0.1), x: 0, y: 4, blur: 10, spread: -2), AnchorShadow(color: Color(.sRGB, red: 0.1765, green: 0.1922, blue: 0.2588, opacity: 0.06), x: 0, y: 1, blur: 2, spread: 0)],
        shadowLift: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.05), x: 0, y: 2, blur: 6, spread: 0), AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.2), x: 0, y: 14, blur: 30, spread: -10)],
        shadowDialog: [AnchorShadow(color: Color(.sRGB, red: 0.1098, green: 0.1216, blue: 0.1647, opacity: 0.28), x: 0, y: 32, blur: 64, spread: -16), AnchorShadow(color: Color(.sRGB, red: 0.1098, green: 0.1216, blue: 0.1647, opacity: 0.12), x: 0, y: 12, blur: 24, spread: -6), AnchorShadow(color: Color(.sRGB, red: 0.1098, green: 0.1216, blue: 0.1647, opacity: 0.06), x: 0, y: 2, blur: 4, spread: 0)],
        shadowEdge: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.06), x: 0, y: 0, blur: 0, spread: 1)],
        shadowXs: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.06), x: 0, y: 1, blur: 2, spread: 0)],
        shadowSm: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.08), x: 0, y: 2, blur: 6, spread: 0)],
        shadowControl: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.4), x: 0, y: 6, blur: 14, spread: -8), AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.1), x: 0, y: 1, blur: 2, spread: 0)],
        shadowKnob: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.28), x: 0, y: 1, blur: 3, spread: 0)],
        shadowBar: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.5), x: 0, y: 18, blur: 40, spread: -14)],
        shadowFab: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.12), x: 0, y: 2, blur: 6, spread: 0), AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.45), x: 0, y: 10, blur: 24, spread: -8)],
        shadowGhost: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.12), x: 0, y: 2, blur: 5, spread: 0), AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.22), x: 0, y: 6, blur: 18, spread: 0)],
        notes: [
            "paper": AnchorNoteColors(bg: Color(.sRGB, red: 0.9333, green: 0.9412, blue: 0.9529, opacity: 1), surface: Color(.sRGB, red: 0.8667, green: 0.902, blue: 0.9373, opacity: 1), border: Color(.sRGB, red: 0.7922, green: 0.8314, blue: 0.8745, opacity: 1), pattern: Color(.sRGB, red: 0.8392, green: 0.8902, blue: 0.9451, opacity: 1), muted: Color(.sRGB, red: 0.2275, green: 0.2353, blue: 0.2549, opacity: 1)),
            "slate": AnchorNoteColors(bg: Color(.sRGB, red: 0.9137, green: 0.949, blue: 0.9686, opacity: 1), surface: Color(.sRGB, red: 0.8392, green: 0.9098, blue: 0.9529, opacity: 1), border: Color(.sRGB, red: 0.7608, green: 0.8392, blue: 0.8863, opacity: 1), pattern: Color(.sRGB, red: 0.8078, green: 0.898, blue: 0.9569, opacity: 1), muted: Color(.sRGB, red: 0.2235, green: 0.2353, blue: 0.2588, opacity: 1)),
            "red": AnchorNoteColors(bg: Color(.sRGB, red: 1, green: 0.9098, blue: 0.8941, opacity: 1), surface: Color(.sRGB, red: 1, green: 0.851, blue: 0.8353, opacity: 1), border: Color(.sRGB, red: 0.949, green: 0.7804, blue: 0.7608, opacity: 1), pattern: Color(.sRGB, red: 1, green: 0.8314, blue: 0.8118, opacity: 1), muted: Color(.sRGB, red: 0.2392, green: 0.2275, blue: 0.2431, opacity: 1)),
            "orange": AnchorNoteColors(bg: Color(.sRGB, red: 1, green: 0.9176, blue: 0.8392, opacity: 1), surface: Color(.sRGB, red: 1, green: 0.8667, blue: 0.7647, opacity: 1), border: Color(.sRGB, red: 0.9373, green: 0.7922, blue: 0.6902, opacity: 1), pattern: Color(.sRGB, red: 1, green: 0.8471, blue: 0.7333, opacity: 1), muted: Color(.sRGB, red: 0.2392, green: 0.2314, blue: 0.2353, opacity: 1)),
            "yellow": AnchorNoteColors(bg: Color(.sRGB, red: 1, green: 0.9529, blue: 0.7922, opacity: 1), surface: Color(.sRGB, red: 0.9725, green: 0.9059, blue: 0.7098, opacity: 1), border: Color(.sRGB, red: 0.902, green: 0.8353, blue: 0.6314, opacity: 1), pattern: Color(.sRGB, red: 0.9647, green: 0.8941, blue: 0.6745, opacity: 1), muted: Color(.sRGB, red: 0.2392, green: 0.2353, blue: 0.2275, opacity: 1)),
            "green": AnchorNoteColors(bg: Color(.sRGB, red: 0.8784, green: 0.9686, blue: 0.8941, opacity: 1), surface: Color(.sRGB, red: 0.8118, green: 0.9333, blue: 0.8314, opacity: 1), border: Color(.sRGB, red: 0.7373, green: 0.8627, blue: 0.7608, opacity: 1), pattern: Color(.sRGB, red: 0.7843, green: 0.9255, blue: 0.8078, opacity: 1), muted: Color(.sRGB, red: 0.2157, green: 0.2392, blue: 0.2431, opacity: 1)),
            "teal": AnchorNoteColors(bg: Color(.sRGB, red: 0.8549, green: 0.9686, blue: 0.9647, opacity: 1), surface: Color(.sRGB, red: 0.7725, green: 0.9333, blue: 0.9294, opacity: 1), border: Color(.sRGB, red: 0.6941, green: 0.8627, blue: 0.8627, opacity: 1), pattern: Color(.sRGB, red: 0.7373, green: 0.9255, blue: 0.9216, opacity: 1), muted: Color(.sRGB, red: 0.2118, green: 0.2392, blue: 0.2588, opacity: 1)),
            "blue": AnchorNoteColors(bg: Color(.sRGB, red: 0.8784, green: 0.9529, blue: 1, opacity: 1), surface: Color(.sRGB, red: 0.8078, green: 0.9098, blue: 1, opacity: 1), border: Color(.sRGB, red: 0.7333, green: 0.8392, blue: 0.9373, opacity: 1), pattern: Color(.sRGB, red: 0.7804, green: 0.902, blue: 1, opacity: 1), muted: Color(.sRGB, red: 0.2157, green: 0.2353, blue: 0.2627, opacity: 1)),
            "dark_blue": AnchorNoteColors(bg: Color(.sRGB, red: 0.9255, green: 0.9333, blue: 1, opacity: 1), surface: Color(.sRGB, red: 0.8706, green: 0.8863, blue: 1, opacity: 1), border: Color(.sRGB, red: 0.8, green: 0.8157, blue: 0.9412, opacity: 1), pattern: Color(.sRGB, red: 0.8549, green: 0.8706, blue: 1, opacity: 1), muted: Color(.sRGB, red: 0.2235, green: 0.2314, blue: 0.2627, opacity: 1)),
            "purple": AnchorNoteColors(bg: Color(.sRGB, red: 0.9804, green: 0.9176, blue: 0.9922, opacity: 1), surface: Color(.sRGB, red: 0.949, green: 0.8627, blue: 0.9647, opacity: 1), border: Color(.sRGB, red: 0.8784, green: 0.7922, blue: 0.898, opacity: 1), pattern: Color(.sRGB, red: 0.9451, green: 0.8431, blue: 0.9647, opacity: 1), muted: Color(.sRGB, red: 0.2353, green: 0.2314, blue: 0.2627, opacity: 1)),
            "pink": AnchorNoteColors(bg: Color(.sRGB, red: 1, green: 0.9098, blue: 0.9529, opacity: 1), surface: Color(.sRGB, red: 0.9882, green: 0.8549, blue: 0.9098, opacity: 1), border: Color(.sRGB, red: 0.9216, green: 0.7804, blue: 0.8431, opacity: 1), pattern: Color(.sRGB, red: 0.9882, green: 0.8314, blue: 0.902, opacity: 1), muted: Color(.sRGB, red: 0.2392, green: 0.2275, blue: 0.2549, opacity: 1)),
            "brown": AnchorNoteColors(bg: Color(.sRGB, red: 0.9804, green: 0.9294, blue: 0.898, opacity: 1), surface: Color(.sRGB, red: 0.9608, green: 0.8784, blue: 0.8235, opacity: 1), border: Color(.sRGB, red: 0.898, green: 0.8039, blue: 0.749, opacity: 1), pattern: Color(.sRGB, red: 0.9647, green: 0.8588, blue: 0.7922, opacity: 1), muted: Color(.sRGB, red: 0.2353, green: 0.2314, blue: 0.2471, opacity: 1)),
            "none": AnchorNoteColors(bg: Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1), surface: Color(.sRGB, red: 0.9412, green: 0.9569, blue: 0.9686, opacity: 1), border: Color(.sRGB, red: 0.8471, green: 0.8745, blue: 0.902, opacity: 1), pattern: Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1), muted: Color(.sRGB, red: 0.2392, green: 0.2431, blue: 0.2627, opacity: 1)),
        ],
        tags: [
            "red": AnchorTagColors(stored: Color(.sRGB, red: 0.898, green: 0.451, blue: 0.451, opacity: 1), hash: Color(.sRGB, red: 0.7529, green: 0.3216, blue: 0.3294, opacity: 1), tintFill: Color(.sRGB, red: 1, green: 0.8588, blue: 0.851, opacity: 1)),
            "pink": AnchorTagColors(stored: Color(.sRGB, red: 0.9412, green: 0.3843, blue: 0.5725, opacity: 1), hash: Color(.sRGB, red: 0.7922, green: 0.2431, blue: 0.4471, opacity: 1), tintFill: Color(.sRGB, red: 1, green: 0.8588, blue: 0.898, opacity: 1)),
            "purple": AnchorTagColors(stored: Color(.sRGB, red: 0.7294, green: 0.4078, blue: 0.7843, opacity: 1), hash: Color(.sRGB, red: 0.6471, green: 0.3294, blue: 0.702, opacity: 1), tintFill: Color(.sRGB, red: 0.9725, green: 0.8706, blue: 0.9882, opacity: 1)),
            "deepPurple": AnchorTagColors(stored: Color(.sRGB, red: 0.5843, green: 0.4588, blue: 0.8039, opacity: 1), hash: Color(.sRGB, red: 0.5255, green: 0.4, blue: 0.7412, opacity: 1), tintFill: Color(.sRGB, red: 0.9255, green: 0.8824, blue: 1, opacity: 1)),
            "indigo": AnchorTagColors(stored: Color(.sRGB, red: 0.4745, green: 0.5255, blue: 0.7961, opacity: 1), hash: Color(.sRGB, red: 0.4078, green: 0.4549, blue: 0.7333, opacity: 1), tintFill: Color(.sRGB, red: 0.8706, green: 0.902, blue: 1, opacity: 1)),
            "blue": AnchorTagColors(stored: Color(.sRGB, red: 0.3922, green: 0.7098, blue: 0.9647, opacity: 1), hash: Color(.sRGB, red: 0.1725, green: 0.502, blue: 0.7451, opacity: 1), tintFill: Color(.sRGB, red: 0.8039, green: 0.9255, blue: 1, opacity: 1)),
            "lightBlue": AnchorTagColors(stored: Color(.sRGB, red: 0.3098, green: 0.7647, blue: 0.9686, opacity: 1), hash: Color(.sRGB, red: 0, green: 0.5255, blue: 0.7176, opacity: 1), tintFill: Color(.sRGB, red: 0.7804, green: 0.9373, blue: 1, opacity: 1)),
            "cyan": AnchorTagColors(stored: Color(.sRGB, red: 0.302, green: 0.8157, blue: 0.8824, opacity: 1), hash: Color(.sRGB, red: 0, green: 0.549, blue: 0.6157, opacity: 1), tintFill: Color(.sRGB, red: 0.7608, green: 0.949, blue: 0.9765, opacity: 1)),
            "teal": AnchorTagColors(stored: Color(.sRGB, red: 0.302, green: 0.7137, blue: 0.6745, opacity: 1), hash: Color(.sRGB, red: 0, green: 0.5608, blue: 0.5216, opacity: 1), tintFill: Color(.sRGB, red: 0.7647, green: 0.9529, blue: 0.9294, opacity: 1)),
            "green": AnchorTagColors(stored: Color(.sRGB, red: 0.5059, green: 0.7804, blue: 0.5176, opacity: 1), hash: Color(.sRGB, red: 0.2824, green: 0.549, blue: 0.302, opacity: 1), tintFill: Color(.sRGB, red: 0.8314, green: 0.9451, blue: 0.8314, opacity: 1)),
            "lightGreen": AnchorTagColors(stored: Color(.sRGB, red: 0.6824, green: 0.8353, blue: 0.5059, opacity: 1), hash: Color(.sRGB, red: 0.3922, green: 0.5294, blue: 0.2078, opacity: 1), tintFill: Color(.sRGB, red: 0.8706, green: 0.9373, blue: 0.8, opacity: 1)),
            "lime": AnchorTagColors(stored: Color(.sRGB, red: 0.8627, green: 0.9059, blue: 0.4588, opacity: 1), hash: Color(.sRGB, red: 0.4824, green: 0.5098, blue: 0, opacity: 1), tintFill: Color(.sRGB, red: 0.9059, green: 0.9255, blue: 0.7765, opacity: 1)),
            "amber": AnchorTagColors(stored: Color(.sRGB, red: 1, green: 0.8353, blue: 0.3098, opacity: 1), hash: Color(.sRGB, red: 0.6118, green: 0.4549, blue: 0, opacity: 1), tintFill: Color(.sRGB, red: 0.9569, green: 0.9059, blue: 0.7647, opacity: 1)),
            "orange": AnchorTagColors(stored: Color(.sRGB, red: 1, green: 0.7176, blue: 0.302, opacity: 1), hash: Color(.sRGB, red: 0.6745, green: 0.4118, blue: 0, opacity: 1), tintFill: Color(.sRGB, red: 0.9922, green: 0.8941, blue: 0.7686, opacity: 1)),
            "deepOrange": AnchorTagColors(stored: Color(.sRGB, red: 1, green: 0.5412, blue: 0.3961, opacity: 1), hash: Color(.sRGB, red: 0.7608, green: 0.3255, blue: 0.1843, opacity: 1), tintFill: Color(.sRGB, red: 1, green: 0.8667, blue: 0.8157, opacity: 1)),
            "brown": AnchorTagColors(stored: Color(.sRGB, red: 0.6314, green: 0.5333, blue: 0.498, opacity: 1), hash: Color(.sRGB, red: 0.5765, green: 0.4431, blue: 0.3961, opacity: 1), tintFill: Color(.sRGB, red: 0.9922, green: 0.8824, blue: 0.8431, opacity: 1)),
            "blueGrey": AnchorTagColors(stored: Color(.sRGB, red: 0.5647, green: 0.6431, blue: 0.6824, opacity: 1), hash: Color(.sRGB, red: 0.3922, green: 0.498, blue: 0.549, opacity: 1), tintFill: Color(.sRGB, red: 0.8431, green: 0.9255, blue: 0.9647, opacity: 1)),
        ]
    )

    static let dark = AnchorColors(
        accentStrong: Color(.sRGB, red: 0.9373, green: 0.5137, blue: 0.3294, opacity: 1),
        accentInk: Color(.sRGB, red: 0.9961, green: 0.5922, blue: 0.4235, opacity: 1),
        appPage: Color(.sRGB, red: 0.0667, green: 0.0706, blue: 0.0784, opacity: 1),
        appSurface: Color(.sRGB, red: 0.1098, green: 0.1137, blue: 0.1294, opacity: 1),
        appText: Color(.sRGB, red: 0.9686, green: 0.9686, blue: 0.9686, opacity: 1),
        appMuted: Color(.sRGB, red: 0.8078, green: 0.8078, blue: 0.8078, opacity: 1),
        appBorder: Color(.sRGB, red: 0.2039, green: 0.2078, blue: 0.2275, opacity: 1),
        appDivider: Color(.sRGB, red: 0.149, green: 0.1529, blue: 0.1725, opacity: 1),
        appSubtle: Color(.sRGB, red: 0.149, green: 0.1529, blue: 0.1725, opacity: 1),
        appSidebar: Color(.sRGB, red: 0.0392, green: 0.0431, blue: 0.0471, opacity: 1),
        appInverse: Color(.sRGB, red: 0.8941, green: 0.902, blue: 0.9216, opacity: 1),
        appOnInverse: Color(.sRGB, red: 0.0667, green: 0.0706, blue: 0.0784, opacity: 1),
        appInverseLink: Color(.sRGB, red: 0.6588, green: 0.2667, blue: 0.0588, opacity: 1),
        appInverseDanger: Color(.sRGB, red: 0.702, green: 0.149, blue: 0.1176, opacity: 1),
        appOverlay: Color(.sRGB, red: 0.0235, green: 0.0275, blue: 0.0392, opacity: 0.6),
        appFieldLine: Color(.sRGB, red: 0.4196, green: 0.4549, blue: 0.5098, opacity: 1),
        checkMark: Color(.sRGB, red: 0.1098, green: 0.1137, blue: 0.1294, opacity: 1),
        statusDanger: Color(.sRGB, red: 1, green: 0.5412, blue: 0.502, opacity: 1),
        statusLate: Color(.sRGB, red: 1, green: 0.6157, blue: 0.5804, opacity: 1),
        statusAdded: Color(.sRGB, red: 0.2471, green: 0.8118, blue: 0.5569, opacity: 1),
        statusRemoved: Color(.sRGB, red: 1, green: 0.4196, blue: 0.5059, opacity: 1),
        statusAddedInk: Color(.sRGB, red: 0.4353, green: 0.8902, blue: 0.6588, opacity: 1),
        statusRemovedInk: Color(.sRGB, red: 1, green: 0.6039, blue: 0.6627, opacity: 1),
        statusWarnText: Color(.sRGB, red: 0.9882, green: 0.8314, blue: 0.6039, opacity: 1),
        statusWarnFill: Color(.sRGB, red: 0.2902, green: 0.2039, blue: 0.0745, opacity: 1),
        statusOnDanger: Color(.sRGB, red: 0.0667, green: 0.0706, blue: 0.0784, opacity: 1),
        blendAddedLine: 14,
        blendAddedWord: 26,
        blendRemovedLine: 16,
        blendRemovedWord: 26,
        shadowRaised: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.25), x: 0, y: 8, blur: 24, spread: 0), AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.3), x: 0, y: 1, blur: 2, spread: 0)],
        shadowFloating: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.14), x: 0, y: 8, blur: 22, spread: 0)],
        shadowMenu: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.45), x: 0, y: 22, blur: 44, spread: -12), AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.35), x: 0, y: 8, blur: 18, spread: -4), AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.35), x: 0, y: 1, blur: 2, spread: 0)],
        shadowLift: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.6), x: 0, y: 16, blur: 32, spread: -10)],
        shadowDialog: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.7), x: 0, y: 32, blur: 70, spread: -18), AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.4), x: 0, y: 2, blur: 6, spread: 0), AnchorShadow(color: Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.05), x: 0, y: 0, blur: 0, spread: 1)],
        shadowEdge: [AnchorShadow(color: Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 0.06), x: 0, y: 0, blur: 0, spread: 1)],
        shadowXs: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.3), x: 0, y: 1, blur: 2, spread: 0)],
        shadowSm: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.3), x: 0, y: 2, blur: 6, spread: 0)],
        shadowControl: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.6), x: 0, y: 6, blur: 14, spread: -8), AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.3), x: 0, y: 1, blur: 2, spread: 0)],
        shadowKnob: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.28), x: 0, y: 1, blur: 3, spread: 0)],
        shadowBar: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.7), x: 0, y: 18, blur: 40, spread: -14)],
        shadowFab: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.3), x: 0, y: 2, blur: 6, spread: 0), AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.7), x: 0, y: 10, blur: 24, spread: -8)],
        shadowGhost: [AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.12), x: 0, y: 2, blur: 5, spread: 0), AnchorShadow(color: Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.22), x: 0, y: 6, blur: 18, spread: 0)],
        notes: [
            "paper": AnchorNoteColors(bg: Color(.sRGB, red: 0.1569, green: 0.1725, blue: 0.1882, opacity: 1), surface: Color(.sRGB, red: 0.2, green: 0.2235, blue: 0.2471, opacity: 1), border: Color(.sRGB, red: 0.2667, green: 0.2824, blue: 0.298, opacity: 1), pattern: Color(.sRGB, red: 0.2235, green: 0.2588, blue: 0.298, opacity: 1), muted: Color(.sRGB, red: 0.8235, green: 0.8235, blue: 0.8275, opacity: 1)),
            "slate": AnchorNoteColors(bg: Color(.sRGB, red: 0.1294, green: 0.1765, blue: 0.2078, opacity: 1), surface: Color(.sRGB, red: 0.1647, green: 0.2275, blue: 0.2667, opacity: 1), border: Color(.sRGB, red: 0.2353, green: 0.2902, blue: 0.3216, opacity: 1), pattern: Color(.sRGB, red: 0.1843, green: 0.2667, blue: 0.3176, opacity: 1), muted: Color(.sRGB, red: 0.8157, green: 0.8275, blue: 0.8314, opacity: 1)),
            "red": AnchorNoteColors(bg: Color(.sRGB, red: 0.2627, green: 0.1216, blue: 0.1137, opacity: 1), surface: Color(.sRGB, red: 0.3255, green: 0.1686, blue: 0.1569, opacity: 1), border: Color(.sRGB, red: 0.3843, green: 0.2353, blue: 0.2235, opacity: 1), pattern: Color(.sRGB, red: 0.3765, green: 0.1961, blue: 0.1843, opacity: 1), muted: Color(.sRGB, red: 0.8431, green: 0.8157, blue: 0.8157, opacity: 1)),
            "orange": AnchorNoteColors(bg: Color(.sRGB, red: 0.2471, green: 0.1412, blue: 0.0471, opacity: 1), surface: Color(.sRGB, red: 0.3098, green: 0.1843, blue: 0.0863, opacity: 1), border: Color(.sRGB, red: 0.3686, green: 0.251, blue: 0.1608, opacity: 1), pattern: Color(.sRGB, red: 0.3569, green: 0.2157, blue: 0.102, opacity: 1), muted: Color(.sRGB, red: 0.8392, green: 0.8196, blue: 0.8039, opacity: 1)),
            "yellow": AnchorNoteColors(bg: Color(.sRGB, red: 0.2157, green: 0.1608, blue: 0.0157, opacity: 1), surface: Color(.sRGB, red: 0.2706, green: 0.2118, blue: 0.051, opacity: 1), border: Color(.sRGB, red: 0.3294, green: 0.2745, blue: 0.1373, opacity: 1), pattern: Color(.sRGB, red: 0.3137, green: 0.2471, blue: 0.0588, opacity: 1), muted: Color(.sRGB, red: 0.8314, green: 0.8235, blue: 0.7961, opacity: 1)),
            "green": AnchorNoteColors(bg: Color(.sRGB, red: 0.0902, green: 0.1961, blue: 0.1176, opacity: 1), surface: Color(.sRGB, red: 0.1333, green: 0.251, blue: 0.1569, opacity: 1), border: Color(.sRGB, red: 0.2039, green: 0.3098, blue: 0.2235, opacity: 1), pattern: Color(.sRGB, red: 0.1529, green: 0.2902, blue: 0.1843, opacity: 1), muted: Color(.sRGB, red: 0.8118, green: 0.8314, blue: 0.8157, opacity: 1)),
            "teal": AnchorNoteColors(bg: Color(.sRGB, red: 0.0314, green: 0.1961, blue: 0.1961, opacity: 1), surface: Color(.sRGB, red: 0.0667, green: 0.251, blue: 0.251, opacity: 1), border: Color(.sRGB, red: 0.1608, green: 0.3098, blue: 0.3098, opacity: 1), pattern: Color(.sRGB, red: 0.0706, green: 0.2902, blue: 0.2902, opacity: 1), muted: Color(.sRGB, red: 0.8, green: 0.8314, blue: 0.8314, opacity: 1)),
            "blue": AnchorNoteColors(bg: Color(.sRGB, red: 0.0627, green: 0.1804, blue: 0.2706, opacity: 1), surface: Color(.sRGB, red: 0.102, green: 0.2314, blue: 0.3333, opacity: 1), border: Color(.sRGB, red: 0.1765, green: 0.2941, blue: 0.3922, opacity: 1), pattern: Color(.sRGB, red: 0.1216, green: 0.2667, blue: 0.3843, opacity: 1), muted: Color(.sRGB, red: 0.8039, green: 0.8275, blue: 0.8431, opacity: 1)),
            "dark_blue": AnchorNoteColors(bg: Color(.sRGB, red: 0.149, green: 0.1529, blue: 0.2824, opacity: 1), surface: Color(.sRGB, red: 0.1961, green: 0.2039, blue: 0.349, opacity: 1), border: Color(.sRGB, red: 0.2549, green: 0.2667, blue: 0.4078, opacity: 1), pattern: Color(.sRGB, red: 0.2275, green: 0.2353, blue: 0.4, opacity: 1), muted: Color(.sRGB, red: 0.8196, green: 0.8235, blue: 0.8471, opacity: 1)),
            "purple": AnchorNoteColors(bg: Color(.sRGB, red: 0.2157, green: 0.1333, blue: 0.2353, opacity: 1), surface: Color(.sRGB, red: 0.2745, green: 0.1765, blue: 0.2941, opacity: 1), border: Color(.sRGB, red: 0.3333, green: 0.2431, blue: 0.3529, opacity: 1), pattern: Color(.sRGB, red: 0.3176, green: 0.2078, blue: 0.3412, opacity: 1), muted: Color(.sRGB, red: 0.8314, green: 0.8196, blue: 0.8353, opacity: 1)),
            "pink": AnchorNoteColors(bg: Color(.sRGB, red: 0.2471, green: 0.1216, blue: 0.1843, opacity: 1), surface: Color(.sRGB, red: 0.3098, green: 0.1647, blue: 0.2353, opacity: 1), border: Color(.sRGB, red: 0.3686, green: 0.2314, blue: 0.298, opacity: 1), pattern: Color(.sRGB, red: 0.3569, green: 0.1922, blue: 0.2745, opacity: 1), muted: Color(.sRGB, red: 0.8392, green: 0.8157, blue: 0.8275, opacity: 1)),
            "brown": AnchorNoteColors(bg: Color(.sRGB, red: 0.2078, green: 0.1569, blue: 0.1255, opacity: 1), surface: Color(.sRGB, red: 0.2667, green: 0.2039, blue: 0.1647, opacity: 1), border: Color(.sRGB, red: 0.3216, green: 0.2706, blue: 0.2353, opacity: 1), pattern: Color(.sRGB, red: 0.3137, green: 0.2353, blue: 0.1843, opacity: 1), muted: Color(.sRGB, red: 0.8314, green: 0.8235, blue: 0.8157, opacity: 1)),
            "none": AnchorNoteColors(bg: Color(.sRGB, red: 0.0667, green: 0.0706, blue: 0.0784, opacity: 1), surface: Color(.sRGB, red: 0.1098, green: 0.1137, blue: 0.1294, opacity: 1), border: Color(.sRGB, red: 0.2039, green: 0.2078, blue: 0.2275, opacity: 1), pattern: Color(.sRGB, red: 0.0667, green: 0.0706, blue: 0.0784, opacity: 1), muted: Color(.sRGB, red: 0.8078, green: 0.8078, blue: 0.8078, opacity: 1)),
        ],
        tags: [
            "red": AnchorTagColors(stored: Color(.sRGB, red: 0.898, green: 0.451, blue: 0.451, opacity: 1), hash: Color(.sRGB, red: 1, green: 0.5647, blue: 0.5608, opacity: 1), tintFill: Color(.sRGB, red: 0.3608, green: 0.1961, blue: 0.1961, opacity: 1)),
            "pink": AnchorTagColors(stored: Color(.sRGB, red: 0.9412, green: 0.3843, blue: 0.5725, opacity: 1), hash: Color(.sRGB, red: 1, green: 0.502, blue: 0.6824, opacity: 1), tintFill: Color(.sRGB, red: 0.3529, green: 0.1961, blue: 0.2392, opacity: 1)),
            "purple": AnchorTagColors(stored: Color(.sRGB, red: 0.7294, green: 0.4078, blue: 0.7843, opacity: 1), hash: Color(.sRGB, red: 0.9059, green: 0.5725, blue: 0.9608, opacity: 1), tintFill: Color(.sRGB, red: 0.3059, green: 0.2078, blue: 0.3255, opacity: 1)),
            "deepPurple": AnchorTagColors(stored: Color(.sRGB, red: 0.5843, green: 0.4588, blue: 0.8039, opacity: 1), hash: Color(.sRGB, red: 0.7686, green: 0.6431, blue: 1, opacity: 1), tintFill: Color(.sRGB, red: 0.2667, green: 0.2196, blue: 0.3569, opacity: 1)),
            "indigo": AnchorTagColors(stored: Color(.sRGB, red: 0.4745, green: 0.5255, blue: 0.7961, opacity: 1), hash: Color(.sRGB, red: 0.6431, green: 0.698, blue: 0.9843, opacity: 1), tintFill: Color(.sRGB, red: 0.2118, green: 0.2392, blue: 0.3725, opacity: 1)),
            "blue": AnchorTagColors(stored: Color(.sRGB, red: 0.3922, green: 0.7098, blue: 0.9647, opacity: 1), hash: Color(.sRGB, red: 0.4314, green: 0.749, blue: 1, opacity: 1), tintFill: Color(.sRGB, red: 0.1333, green: 0.2627, blue: 0.3647, opacity: 1)),
            "lightBlue": AnchorTagColors(stored: Color(.sRGB, red: 0.3098, green: 0.7647, blue: 0.9686, opacity: 1), hash: Color(.sRGB, red: 0.3216, green: 0.7725, blue: 0.9804, opacity: 1), tintFill: Color(.sRGB, red: 0.0941, green: 0.2706, blue: 0.3529, opacity: 1)),
            "cyan": AnchorTagColors(stored: Color(.sRGB, red: 0.302, green: 0.8157, blue: 0.8824, opacity: 1), hash: Color(.sRGB, red: 0.2824, green: 0.8, blue: 0.8667, opacity: 1), tintFill: Color(.sRGB, red: 0.0353, green: 0.2824, blue: 0.3137, opacity: 1)),
            "teal": AnchorTagColors(stored: Color(.sRGB, red: 0.302, green: 0.7137, blue: 0.6745, opacity: 1), hash: Color(.sRGB, red: 0.3843, green: 0.8, blue: 0.7608, opacity: 1), tintFill: Color(.sRGB, red: 0.0431, green: 0.2902, blue: 0.2706, opacity: 1)),
            "green": AnchorTagColors(stored: Color(.sRGB, red: 0.5059, green: 0.7804, blue: 0.5176, opacity: 1), hash: Color(.sRGB, red: 0.5216, green: 0.8, blue: 0.5333, opacity: 1), tintFill: Color(.sRGB, red: 0.1647, green: 0.2824, blue: 0.1725, opacity: 1)),
            "lightGreen": AnchorTagColors(stored: Color(.sRGB, red: 0.6824, green: 0.8353, blue: 0.5059, opacity: 1), hash: Color(.sRGB, red: 0.6275, green: 0.7765, blue: 0.451, opacity: 1), tintFill: Color(.sRGB, red: 0.2118, green: 0.2745, blue: 0.1333, opacity: 1)),
            "lime": AnchorTagColors(stored: Color(.sRGB, red: 0.8627, green: 0.9059, blue: 0.4588, opacity: 1), hash: Color(.sRGB, red: 0.7176, green: 0.7569, blue: 0.3059, opacity: 1), tintFill: Color(.sRGB, red: 0.2471, green: 0.2627, blue: 0.1059, opacity: 1)),
            "amber": AnchorTagColors(stored: Color(.sRGB, red: 1, green: 0.8353, blue: 0.3098, opacity: 1), hash: Color(.sRGB, red: 0.8627, green: 0.698, blue: 0.1137, opacity: 1), tintFill: Color(.sRGB, red: 0.2941, green: 0.2431, blue: 0.0863, opacity: 1)),
            "orange": AnchorTagColors(stored: Color(.sRGB, red: 1, green: 0.7176, blue: 0.302, opacity: 1), hash: Color(.sRGB, red: 0.9333, green: 0.6549, blue: 0.2275, opacity: 1), tintFill: Color(.sRGB, red: 0.3255, green: 0.2275, blue: 0.0941, opacity: 1)),
            "deepOrange": AnchorTagColors(stored: Color(.sRGB, red: 1, green: 0.5412, blue: 0.3961, opacity: 1), hash: Color(.sRGB, red: 1, green: 0.5725, blue: 0.4275, opacity: 1), tintFill: Color(.sRGB, red: 0.3569, green: 0.2039, blue: 0.1569, opacity: 1)),
            "brown": AnchorTagColors(stored: Color(.sRGB, red: 0.6314, green: 0.5333, blue: 0.498, opacity: 1), hash: Color(.sRGB, red: 0.8275, green: 0.6824, blue: 0.6314, opacity: 1), tintFill: Color(.sRGB, red: 0.3098, green: 0.2275, blue: 0.1961, opacity: 1)),
            "blueGrey": AnchorTagColors(stored: Color(.sRGB, red: 0.5647, green: 0.6431, blue: 0.6824, opacity: 1), hash: Color(.sRGB, red: 0.6275, green: 0.7412, blue: 0.7961, opacity: 1), tintFill: Color(.sRGB, red: 0.1922, green: 0.2627, blue: 0.2941, opacity: 1)),
        ]
    )
}
