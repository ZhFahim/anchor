import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/logging/log_tags.dart';
import '../../../core/motion/haptics.dart';
import '../../../core/motion/springs.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/theme/tokens/anchor_tokens.dart';
import '../../../core/widgets/anchor_dialog.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/check_circle.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../core/widgets/grouped_list.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/segmented_control.dart';
import '../../../core/widgets/selection_bar.dart';
import '../../../l10n/l10n.dart';
import '../../notes/presentation/widgets/notes_bottom_bar.dart';
import 'log_viewer_controller.dart';

enum _LogsMenuAction { copy, save, select, clear }

const _clipboardLimit = 200000;

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final _scroll = ScrollController();
  late final _logs = LogViewerController(onLineAdded: _lineAdded);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _toEnd());
  }

  @override
  void dispose() {
    _logs.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _lineAdded() {
    if (!mounted) return;
    final isAtEnd =
        _scroll.hasClients &&
        _scroll.offset >= _scroll.position.maxScrollExtent - 32;
    if (isAtEnd) WidgetsBinding.instance.addPostFrameCallback((_) => _toEnd());
  }

  /// A lazy list's maxScrollExtent grows as it lays out lines; jump until it
  /// holds still.
  void _toEnd([int attempts = 8]) {
    if (!mounted || !_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels == position.maxScrollExtent) return;
    _scroll.jumpTo(position.maxScrollExtent);
    if (attempts > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _toEnd(attempts - 1));
    }
  }

  Future<void> _copy(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    AppSnackbar.show(context, message, kind: SnackbarKind.success);
  }

  Future<void> _copySelected() async {
    final lines = _logs.selectedLines();
    if (lines.isEmpty) return;
    _logs.stopSelecting();
    await _copy(lines.join('\n'), context.l10n.logsCopied(lines.length));
  }

  Future<void> _copyAll() async {
    final l10n = context.l10n;
    final dump = await AppLogger.instance.dumpAll();
    if (dump.length <= _clipboardLimit) {
      return _copy(dump, l10n.logsCopiedAll);
    }
    final start = dump.length - _clipboardLimit;
    final lineEnd = dump.indexOf('\n', start);
    await _copy(
      dump.substring(lineEnd < 0 ? start : lineEnd + 1),
      l10n.logsCopiedNewest,
    );
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final dump = await AppLogger.instance.dumpAll();
    final name =
        'anchor-logs-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}.log';
    try {
      final saved = await _saveToFile(name, dump, l10n.logsSaveDialog);
      if (saved != null && mounted) {
        AppSnackbar.show(context, l10n.logsSaved(name));
      }
    } catch (e, stack) {
      AppLogger.instance.error(
        LogTags.logs,
        'Saving the logs failed',
        error: e,
        stackTrace: stack,
      );
      if (mounted) {
        AppSnackbar.show(
          context,
          l10n.logsSaveFailed,
          kind: SnackbarKind.error,
        );
      }
    }
  }

  /// Opens the phone's save screen, or the share sheet when it has none.
  Future<Uri?> _saveToFile(String name, String dump, String title) async {
    try {
      return await FilePicker.saveFile(
        dialogTitle: title,
        fileName: name,
        bytes: Uint8List.fromList(utf8.encode(dump)),
      );
    } on PlatformException catch (error) {
      if (error.code != 'explorer_not_found') rethrow;
      final file = File(p.join((await getTemporaryDirectory()).path, name));
      await file.writeAsString(dump);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'text/plain')]),
      );
      return null;
    }
  }

  Future<void> _more() async {
    final l10n = context.l10n;
    final choice = await showChoiceSheet<_LogsMenuAction>(
      context,
      title: l10n.logsTitle,
      subtitle: l10n.logsMenuHelp,
      choices: [
        SheetChoice(
          value: _LogsMenuAction.copy,
          icon: LucideIcons.copy,
          label: l10n.logsCopyAll,
        ),
        SheetChoice(
          value: _LogsMenuAction.save,
          icon: LucideIcons.download,
          label: l10n.logsSaveToFile,
        ),
        SheetChoice(
          value: _LogsMenuAction.select,
          icon: LucideIcons.listChecks,
          label: l10n.commonSelect,
        ),
        null,
        SheetChoice(
          value: _LogsMenuAction.clear,
          icon: LucideIcons.trash2,
          label: l10n.logsClear,
          isDanger: true,
          enabled: _logs.hasEntries,
        ),
      ],
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case _LogsMenuAction.copy:
        await _copyAll();
      case _LogsMenuAction.save:
        await _save();
      case _LogsMenuAction.select:
        _logs.startSelecting();
      case _LogsMenuAction.clear:
        final isConfirmed = await showAnchorDialog(
          context,
          title: l10n.logsClearTitle,
          message: l10n.logsClearMessage,
          confirmLabel: l10n.logsClear,
          icon: LucideIcons.trash2,
          isDanger: true,
        );
        if (!isConfirmed) return;
        await _logs.clear();
        if (!mounted) return;
        AppSnackbar.show(context, l10n.logsCleared);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _logs,
      builder: (context, _) => _page(context),
    );
  }

  Widget _page(BuildContext context) {
    final rows = _logs.shown;
    final isSelecting = _logs.isSelecting;
    final l10n = context.l10n;
    return PopScope(
      canPop: !isSelecting && !_logs.isSearching,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        isSelecting ? _logs.stopSelecting() : _logs.stopSearch();
      },
      child: AppScaffold(
        title: !isSelecting
            ? l10n.logsTitle
            : _logs.selectedCount == 0
            ? l10n.logsSelectTitle
            : l10n.commonSelectedCount(_logs.selectedCount),
        background: PageBackground.gradient,
        controller: _scroll,
        leading: isSelecting
            ? BarButton(
                icon: LucideIcons.x,
                label: l10n.commonStopSelecting,
                onPressed: _logs.stopSelecting,
              )
            : null,
        actions: [
          if (!isSelecting)
            BarButton(
              icon: LucideIcons.ellipsis,
              label: l10n.commonMore,
              onPressed: _more,
            ),
        ],
        bottomBar: SelectionBarSwitcher(
          isSelecting: isSelecting,
          bottomBar: NotesBottomBar(
            placeholder: l10n.logsSearch,
            compact: false,
            searching: _logs.isSearching,
            query: _logs.query,
            onStartSearch: _logs.startSearch,
            onQuery: _logs.search,
            onCancel: () {
              FocusScope.of(context).unfocus();
              _logs.stopSearch();
            },
          ),
          selectionBar: SelectionBar(
            label: l10n.logsSelected,
            enabled: true,
            actions: [
              SelectionAction(
                icon: LucideIcons.listChecks,
                label: _logs.isAllShownSelected
                    ? l10n.commonDeselectAll
                    : l10n.commonSelectAll,
                onPressed: () {
                  Haptics.selection();
                  _logs.toggleAllShown();
                },
              ),
              SelectionAction(
                icon: LucideIcons.copy,
                label: l10n.commonCopy,
                onPressed: _copySelected,
              ),
            ],
          ),
        ),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, context.density.space8, 16, 4),
            sliver: SliverList.list(
              children: [
                SegmentedControl<LogLevel?>(
                  semanticLabel: l10n.logsLevel,
                  value: _logs.level,
                  segments: [
                    Segment(value: null, label: l10n.logsAll),
                    Segment(value: LogLevel.error, label: l10n.logsErrors),
                    Segment(value: LogLevel.warn, label: l10n.logsWarnings),
                    Segment(value: LogLevel.info, label: l10n.logsInfo),
                    Segment(value: LogLevel.debug, label: l10n.logsDebug),
                  ],
                  onChanged: _logs.showLevel,
                ),
                SizedBox(height: context.density.space12),
                SectionFooter(l10n.logsSessionNote),
                SizedBox(height: context.density.space8),
              ],
            ),
          ),
          if (rows.isEmpty)
            SliverAppEmptyState(
              kind: EmptyStateKind.search,
              title: _logs.hasEntries ? l10n.logsNoMatches : l10n.logsEmpty,
              message: _logs.hasEntries
                  ? l10n.logsNoMatchesHelp
                  : l10n.logsEmptyHelp,
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AnchorTokens.space16,
              ),
              sliver: DecoratedSliver(
                decoration: GroupedList.decorationOf(context),
                sliver: SliverList.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final entry = rows[index];
                    return _LogRow(
                      entry: entry,
                      isFirst: index == 0,
                      isLast: index == rows.length - 1,
                      isExpanded: _logs.isExpanded(entry),
                      isSelecting: isSelecting,
                      isSelected: _logs.isSelected(entry),
                      onTap: () {
                        Haptics.selection();
                        _logs.toggle(entry);
                      },
                      onLongPress: isSelecting
                          ? null
                          : () {
                              Haptics.medium();
                              _logs.startSelecting(entry);
                            },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One entry, as a row of the group the entries make together.
class _LogRow extends StatelessWidget {
  const _LogRow({
    required this.entry,
    required this.isFirst,
    required this.isLast,
    required this.isExpanded,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final LogEntry entry;
  final bool isFirst;
  final bool isLast;
  final bool isExpanded;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final (level, color) = switch (entry.level) {
      LogLevel.error => (context.l10n.logLevelError, colors.statusDanger),
      LogLevel.warn => (context.l10n.logLevelWarning, colors.statusWarnText),
      LogLevel.info => (context.l10n.logLevelInfo, colors.appMuted),
      LogLevel.debug => (context.l10n.logLevelDebug, colors.appMuted),
    };
    final time = DateFormat('HH:mm:ss').format(entry.timestamp.toLocal());
    final mono = AppTypography.codeSmall.copyWith(
      height: 1.4,
      color: colors.appText,
    );
    final detail = AppTypography.footnote.tabular.copyWith(
      color: colors.appMuted,
    );
    const corner = Radius.circular(AnchorTokens.radius2xl);
    final radius = BorderRadius.vertical(
      top: isFirst ? corner : Radius.zero,
      bottom: isLast ? corner : Radius.zero,
    );
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: GroupedListTile.inset,
        vertical: context.density.space12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AnchorTokens.space12,
        children: [
          if (isSelecting)
            Padding(
              padding: const EdgeInsets.only(top: AnchorTokens.space4),
              child: CheckCircle(
                value: isSelected,
                ringColor: colors.appMuted.withValues(alpha: 0.6),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AnchorTokens.space4,
              children: [
                Row(
                  spacing: AnchorTokens.space8,
                  children: [
                    Text(
                      level.toUpperCase(),
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(time, style: detail),
                    Text('·', style: detail),
                    Flexible(
                      child: Text(
                        entry.tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: detail,
                      ),
                    ),
                  ],
                ),
                Text(
                  entry.message,
                  maxLines: isExpanded ? null : 3,
                  overflow: isExpanded ? null : TextOverflow.ellipsis,
                  style: mono,
                ),
                if (isExpanded && entry.error != null)
                  Text(
                    '${entry.error}',
                    style: mono.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.statusDanger,
                    ),
                  ),
                if (isExpanded && entry.stackTrace != null)
                  Text(
                    '${entry.stackTrace}'.trim(),
                    style: mono.copyWith(color: colors.appMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return Pressable(
      style: PressStyle.row,
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: '$level, $time, ${entry.tag}. ${entry.message}',
      selected: isSelecting ? isSelected : null,
      tintRadius: radius,
      child: AnimatedContainer(
        duration: context.motion(AnchorTokens.motionDurationHover),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentStrong.withValues(alpha: 0.1) : null,
          borderRadius: radius,
        ),
        child: isFirst ? content : GroupedList.lineAbove(context, content),
      ),
    );
  }
}
