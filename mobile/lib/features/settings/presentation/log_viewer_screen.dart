import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../core/theme/tokens/app_radius.dart';

class LogViewerScreen extends ConsumerStatefulWidget {
  const LogViewerScreen({super.key});

  @override
  ConsumerState<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends ConsumerState<LogViewerScreen> {
  LogLevel? _filter;
  String _search = '';
  bool _searchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<LogEntry> _entries = [];
  StreamSubscription<LogEntry>? _sub;
  final ScrollController _scrollController = ScrollController();
  bool _stickToBottom = true;

  final Set<LogEntry> _selected = <LogEntry>{};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _entries = List.of(AppLogger.instance.snapshot);
    _sub = AppLogger.instance.stream.listen(_onNewEntry);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) {
        // Hiding the bar clears the query so the list isn't silently filtered.
        _searchController.clear();
        _search = '';
      }
    });
    if (_searchVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  void _onNewEntry(LogEntry entry) {
    if (!mounted) return;
    setState(() {
      _entries = List.of(AppLogger.instance.snapshot);
      // Drop selections for entries that fell off the buffer.
      _selected.retainAll(_entries);
      if (_selected.isEmpty) _selectionMode = false;
    });
    _maybeAutoScroll();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom =
        _scrollController.offset >=
        _scrollController.position.maxScrollExtent - 32;
    if (atBottom != _stickToBottom) {
      _stickToBottom = atBottom;
    }
  }

  void _jumpToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  void _maybeAutoScroll() {
    if (!_stickToBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  List<LogEntry> get _visibleEntries {
    Iterable<LogEntry> it = _entries;
    if (_filter != null) {
      it = it.where((e) => e.level == _filter);
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      it = it.where(
        (e) =>
            e.message.toLowerCase().contains(q) ||
            e.tag.toLowerCase().contains(q),
      );
    }
    return identical(it, _entries) ? _entries : it.toList();
  }

  void _enterSelection(LogEntry entry) {
    setState(() {
      _selectionMode = true;
      _selected.add(entry);
    });
  }

  void _toggleSelection(LogEntry entry) {
    setState(() {
      if (_selected.contains(entry)) {
        _selected.remove(entry);
        if (_selected.isEmpty) _selectionMode = false;
      } else {
        _selected.add(entry);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selected.clear();
    });
  }

  void _selectAllVisible() {
    setState(() {
      _selected.addAll(_visibleEntries);
    });
  }

  Future<void> _copySelected() async {
    // Preserve chronological order from the visible list.
    final lines = _visibleEntries
        .where(_selected.contains)
        .map((e) => e.format())
        .toList();
    if (lines.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    AppSnackbar.showSuccess(context, message: '${lines.length} entries copied');
    _exitSelectionMode();
  }

  Future<void> _copyAll() async {
    final dump = await AppLogger.instance.dumpAll();
    await Clipboard.setData(ClipboardData(text: dump));
    if (!mounted) return;
    AppSnackbar.showSuccess(context, message: 'Logs copied to clipboard');
  }

  Future<void> _exportToFile() async {
    final dump = await AppLogger.instance.dumpAll();
    final bytes = Uint8List.fromList(utf8.encode(dump));
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final filename = 'anchor-logs-$stamp.log';

    Uri? result;
    try {
      result = await FilePicker.saveFile(
        dialogTitle: 'Save logs',
        fileName: filename,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: const ['log'],
      );
    } catch (e, st) {
      AppLogger.instance.error(
        'LogViewer',
        'Export picker failed',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      AppSnackbar.showError(context, message: 'Export failed: $e');
      return;
    }
    if (result == null) return; // user cancelled

    if (!mounted) return;
    AppSnackbar.showSuccess(context, message: 'Saved $filename');
  }

  void _confirmClear() {
    showDialog(
      context: context,
      builder: (ctx) => ConfirmDialog(
        icon: LucideIcons.trash2,
        title: 'Clear Logs',
        message: 'This will delete all stored logs from this device. Continue?',
        cancelText: 'Cancel',
        confirmText: 'Clear',
        onConfirm: () async {
          await AppLogger.instance.clear();
          if (mounted) {
            setState(() {
              _entries = List.of(AppLogger.instance.snapshot);
              _selected.clear();
              _selectionMode = false;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dims = context.dims;

    final visible = _visibleEntries;

    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectionMode) _exitSelectionMode();
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: context.colorTokens.pageGradient),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, theme),
                _buildToolbar(context, theme),
                Expanded(
                  child: visible.isEmpty
                      ? Center(
                          child: Text(
                            'No log entries yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(
                            horizontal: dims.md,
                            vertical: dims.sm,
                          ),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final entry = visible[index];
                            return _LogTile(
                              key: ValueKey(entry),
                              entry: entry,
                              selectionMode: _selectionMode,
                              selected: _selected.contains(entry),
                              onTap: () => _toggleSelection(entry),
                              onLongPress: () => _enterSelection(entry),
                            );
                          },
                        ),
                ),
                if (visible.isNotEmpty) _buildBottomBar(context, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool destructive = false,
  }) {
    final theme = Theme.of(context);
    final fg = destructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    final bg = destructive
        ? theme.colorScheme.error.withValues(alpha: 0.1)
        : context.colorTokens.cardFill;
    final borderColor = destructive
        ? theme.colorScheme.error.withValues(alpha: 0.22)
        : theme.colorScheme.onSurface.withValues(alpha: 0.08);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.buttonBorder,
          child: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.buttonBorder,
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              icon,
              size: AppIconSizes.md,
              color: fg.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _primaryAction({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Expanded(
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: context.dims.md),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorder,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ThemeData theme) {
    final dims = context.dims;

    final List<Widget> children;
    if (_selectionMode) {
      final count = _selected.length;
      children = [
        _iconAction(
          icon: LucideIcons.x,
          onPressed: _exitSelectionMode,
          tooltip: 'Cancel selection',
        ),
        SizedBox(width: dims.sm),
        _iconAction(
          icon: LucideIcons.listChecks,
          onPressed: _selectAllVisible,
          tooltip: 'Select all',
        ),
        SizedBox(width: dims.sm),
        _primaryAction(
          icon: LucideIcons.copy,
          label: 'Copy ($count)',
          onPressed: count == 0 ? null : _copySelected,
        ),
      ];
    } else {
      children = [
        _iconAction(
          icon: LucideIcons.trash2,
          onPressed: _confirmClear,
          tooltip: 'Clear logs',
          destructive: true,
        ),
        SizedBox(width: dims.sm),
        _iconAction(
          icon: LucideIcons.download,
          onPressed: _exportToFile,
          tooltip: 'Export to file',
        ),
        SizedBox(width: dims.sm),
        _primaryAction(
          icon: LucideIcons.copy,
          label: 'Copy all',
          onPressed: _copyAll,
        ),
      ];
    }

    return Container(
      decoration: BoxDecoration(
        color: context.colorTokens.inputFill,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(dims.md, dims.sm, dims.md, dims.md),
        child: Row(children: children),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final dims = context.dims;
    if (_selectionMode) {
      return Padding(
        padding: EdgeInsets.fromLTRB(dims.xs, dims.xs, dims.md, dims.xxs),
        child: Row(
          children: [
            IconButton(
              icon: Container(
                padding: EdgeInsets.all(dims.xs),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: AppRadius.smBorder,
                ),
                child: Icon(
                  LucideIcons.x,
                  size: AppIconSizes.md,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              onPressed: _exitSelectionMode,
            ),
            SizedBox(width: dims.xxs),
            Text(
              '${_selected.length} selected',
              style: AppTypography.serif(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(dims.xs, dims.xs, dims.md, dims.xxs),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(dims.xs),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: AppRadius.smBorder,
              ),
              child: Icon(
                LucideIcons.arrowLeft,
                size: AppIconSizes.md,
                color: theme.colorScheme.onSurface,
              ),
            ),
            onPressed: () => context.pop(),
          ),
          if (Platform.isIOS) const Spacer(),
          Text(
            'Logs',
            style: AppTypography.serif(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: _searchVisible ? 'Hide search' : 'Search',
            icon: Container(
              padding: EdgeInsets.all(dims.xs),
              decoration: BoxDecoration(
                color: _searchVisible
                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                    : theme.colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: AppRadius.smBorder,
              ),
              child: Icon(
                _searchVisible ? LucideIcons.x : LucideIcons.search,
                size: AppIconSizes.md,
                color: _searchVisible
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
            onPressed: _toggleSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, ThemeData theme) {
    final dims = context.dims;
    return Padding(
      padding: EdgeInsets.fromLTRB(dims.md, dims.xxs, dims.md, dims.xs),
      child: Column(
        children: [
          if (_searchVisible) ...[
            TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: (value) => setState(() => _search = value),
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search messages and tags',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(LucideIcons.x, size: 18),
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      ),
                filled: true,
                fillColor: context.colorTokens.inputFill,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: dims.sm,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.buttonBorder,
                  borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.buttonBorder,
                  borderSide: BorderSide(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
            SizedBox(height: dims.xs),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', null, theme),
                _filterChip('Debug', LogLevel.debug, theme),
                _filterChip('Info', LogLevel.info, theme),
                _filterChip('Warn', LogLevel.warn, theme),
                _filterChip('Error', LogLevel.error, theme),
              ],
            ),
          ),
          SizedBox(height: dims.xs),
          Row(
            children: [
              Icon(
                LucideIcons.info,
                size: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'This list shows logs from the current session only. '
                  'Export and Copy all include the full saved history.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, LogLevel? level, ThemeData theme) {
    final selected = _filter == level;
    return Padding(
      padding: EdgeInsets.only(right: context.dims.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = level),
      ),
    );
  }
}

class _LogTile extends StatefulWidget {
  const _LogTile({
    super.key,
    required this.entry,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final LogEntry entry;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  State<_LogTile> createState() => _LogTileState();
}

class _LogTileState extends State<_LogTile> {
  bool _expanded = false;

  Color _levelColor(LogLevel level, ColorScheme cs) {
    switch (level) {
      case LogLevel.debug:
        return cs.onSurface.withValues(alpha: 0.5);
      case LogLevel.info:
        return cs.primary;
      case LogLevel.warn:
        return context.colorTokens.warning;
      case LogLevel.error:
        return cs.error;
    }
  }

  String _levelLabel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warn:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }

  String _shortTime(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final ss = t.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dims = context.dims;
    final color = _levelColor(widget.entry.level, theme.colorScheme);

    final background = widget.selected
        ? theme.colorScheme.primary.withValues(alpha: 0.18)
        : context.colorTokens.cardFill;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          if (widget.selectionMode) {
            widget.onTap();
          } else {
            setState(() => _expanded = !_expanded);
          }
        },
        onLongPress: widget.onLongPress,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: dims.sm, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.selectionMode) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 10),
                  child: Icon(
                    widget.selected
                        ? LucideIcons.checkCircle
                        : LucideIcons.circle,
                    size: 18,
                    color: widget.selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _levelLabel(widget.entry.level),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        SizedBox(width: dims.xs),
                        Text(
                          _shortTime(widget.entry.timestamp),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: 'monospace',
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(width: dims.xs),
                        Flexible(
                          child: Text(
                            widget.entry.tag,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: dims.xxs),
                    Text(
                      widget.entry.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                      maxLines: _expanded ? null : 3,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                    ),
                    if (_expanded && widget.entry.error != null) ...[
                      SizedBox(height: dims.xxs),
                      Text(
                        'error: ${widget.entry.error}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    if (_expanded && widget.entry.stackTrace != null) ...[
                      SizedBox(height: dims.xxs),
                      Text(
                        widget.entry.stackTrace.toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
