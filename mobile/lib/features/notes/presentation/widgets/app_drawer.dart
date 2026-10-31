import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';

import '../../../../core/motion/haptics.dart';
import '../../../../core/motion/springs.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/theme/tokens/anchor_tokens.dart';
import '../../../../core/widgets/anchor_logo.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/cap_height_text.dart';
import '../../../../core/widgets/grouped_list.dart';
import '../../../../core/widgets/person_avatar.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../l10n/l10n.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/tag_colors.dart';
import '../../../tags/presentation/tags_controller.dart';
import '../../../tags/presentation/widgets/tag_sheets.dart';
import '../../domain/note.dart';
import '../note_folder.dart';
import '../notes_controller.dart';
import '../notes_list_controller.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({
    super.key,
    required this.onClose,
    required this.onOpenSettings,
    required this.onOpenList,
  });

  final VoidCallback onClose;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenList;

  static const double width = 316; // off-scale: drawer

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  final Map<String, GlobalKey> _rowKeys = {};
  final GlobalKey _listKey = GlobalKey();
  Rect? _pill;

  GlobalKey _key(String id) => _rowKeys.putIfAbsent(id, GlobalKey.new);

  void _measure(String current) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final row =
          _rowKeys[current]?.currentContext?.findRenderObject() as RenderBox?;
      final list = _listKey.currentContext?.findRenderObject() as RenderBox?;
      if (row == null || list == null || !row.attached) return;
      final rect = row.localToGlobal(Offset.zero, ancestor: list) & row.size;
      if (rect != _pill) setState(() => _pill = rect);
    });
  }

  void _openFolder(NoteFolder folder, {String? tagId}) {
    Haptics.selection();
    ref.read(noteFolderProvider.notifier).go(folder);
    final tags = ref.read(selectedTagFilterProvider.notifier);
    if (tagId == null) {
      tags.clear();
    } else {
      tags.select(tagId);
    }
    ref.read(searchQueryProvider.notifier).set('');
    NoteSelection(ref).end();
    widget.onOpenList();
    Future.delayed(
      context.motion(const Duration(milliseconds: 160)),
      widget.onClose,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final density = context.density;
    final folder = ref.watch(noteFolderProvider);
    final tagId = ref.watch(selectedTagFilterProvider);
    final tags = sortTagsByName(
      ref.watch(tagsControllerProvider).value ?? const <Tag>[],
    );
    final notes = ref.watch(allActiveNotesProvider).value ?? const <Note>[];
    final counts = ref.watch(tagNoteCountsProvider);
    final current = folder == NoteFolder.notes
        ? (tagId ?? 'notes')
        : folder.name;
    _measure(current);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: AppDrawer.width,
        decoration: BoxDecoration(
          color: colors.appSidebar,
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(AnchorTokens.radius4xl),
          ),
          boxShadow: colors.shadowDialog,
        ),
        padding: EdgeInsets.fromLTRB(
          8,
          MediaQuery.paddingOf(context).top + density.space8,
          8,
          context.safeBottom + 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                8,
                density.space8,
                8,
                density.space16,
              ),
              child: Row(
                children: [
                  const AnchorLogo(size: AnchorLogo.drawer, isRaised: false),
                  const SizedBox(width: 12),
                  CapHeightText(
                    context.l10n.settingsAppNameShort,
                    style: AppTypography.serifText(
                      fontSize: AppTypography.sheetTitle.fontSize,
                      color: colors.appText,
                    ).copyWith(letterSpacing: -0.1),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Stack(
                  key: _listKey,
                  children: [
                    if (_pill != null)
                      AnimatedPositioned(
                        duration: context.motion(Spring.snappy.duration),
                        curve: Spring.snappy.curve,
                        left: _pill!.left,
                        top: _pill!.top,
                        width: _pill!.width,
                        height: _pill!.height,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.appSurface,
                            borderRadius: BorderRadius.circular(
                              AnchorTokens.radiusLg,
                            ),
                            boxShadow: colors.shadowXs,
                          ),
                        ),
                      ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 4,
                      children: [
                        _Item(
                          key: _key('notes'),
                          icon: LucideIcons.notebookText,
                          label: context.l10n.navNotes,
                          count: notes.length,
                          isCurrent: current == 'notes',
                          onTap: () => _openFolder(NoteFolder.notes),
                        ),
                        _Item(
                          key: _key('archive'),
                          icon: LucideIcons.archive,
                          label: context.l10n.navArchive,
                          isCurrent: current == 'archive',
                          onTap: () => _openFolder(NoteFolder.archive),
                        ),
                        _Item(
                          key: _key('trash'),
                          icon: LucideIcons.trash2,
                          label: context.l10n.navTrash,
                          isCurrent: current == 'trash',
                          onTap: () => _openFolder(NoteFolder.trash),
                        ),
                        const _TagsHeading(),
                        for (final t in tags)
                          _Item(
                            key: _key(t.id),
                            leading: SizedBox(
                              width: AnchorTokens.sizeIconMedium,
                              child: Icon(
                                LucideIcons600.hash,
                                size: AnchorTokens.sizeIconSmall,
                                color: tagColorsOf(context, t.color).hash,
                              ),
                            ),
                            label: t.name,
                            count: counts[t.id] ?? 0,
                            isCurrent: current == t.id,
                            onTap: () =>
                                _openFolder(NoteFolder.notes, tagId: t.id),
                            onLongPress: () {
                              Haptics.medium();
                              showTagMenu(context, t);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(top: density.space8),
              margin: EdgeInsets.only(top: density.space8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colors.appBorder.withValues(alpha: 0.7),
                  ),
                ),
              ),
              child: _Account(onTap: widget.onOpenSettings),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagsHeading extends StatelessWidget {
  const _TagsHeading();

  static const double _addButtonSize = AnchorTokens.sizeControlSmall;

  @override
  Widget build(BuildContext context) {
    final top = context.density.space16;
    return SizedBox(
      height: top + _addButtonSize + 4,
      child: Stack(
        children: [
          Positioned(
            left: 8,
            right: _addButtonSize,
            top: top,
            height: _addButtonSize,
            child: SectionHeader(
              context.l10n.tagsTitle,
              padding: EdgeInsets.zero,
            ),
          ),
          Positioned(
            right: 0,
            top: top - 8,
            child: BarButton(
              icon: LucideIcons.plus,
              label: context.l10n.tagNew,
              size: BarButtonSize.small,
              hitPadding: const EdgeInsets.fromLTRB(12, 8, 0, 4),
              onPressed: () => showTagEditor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    super.key,
    this.icon,
    this.leading,
    required this.label,
    this.count,
    required this.isCurrent,
    required this.onTap,
    this.onLongPress,
  });

  final IconData? icon;
  final Widget? leading;
  final String label;
  final int? count;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    return Pressable(
      style: PressStyle.row,
      onTap: onTap,
      onLongPress: onLongPress,
      selected: isCurrent,
      semanticLabel: count == null ? label : '$label, $count',
      tintRadius: BorderRadius.circular(AnchorTokens.radiusLg),
      child: SizedBox(
        height: AnchorTokens.sizeControlMedium,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              leading ??
                  Icon(
                    icon,
                    size: AnchorTokens.sizeIconMedium,
                    color: isCurrent ? colors.accentStrong : colors.appMuted,
                  ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.row.copyWith(
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: colors.appText,
                  ),
                ),
              ),
              if (count != null)
                Text(
                  '$count',
                  style: AppTypography.footnote.tabular.copyWith(
                    color: colors.appMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Account extends ConsumerWidget {
  const _Account({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.anchor;
    final user = ref.watch(authControllerProvider).value;
    return Pressable(
      style: PressStyle.row,
      onTap: onTap,
      semanticLabel: user == null
          ? context.l10n.settingsTitle
          : context.l10n.drawerAccount(user.name),
      tintRadius: BorderRadius.circular(AnchorTokens.radiusLg),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: context.density.space8,
        ),
        child: Row(
          children: [
            if (user != null)
              PersonAvatar(
                name: user.name,
                imageUrl: user.profileImage,
                size: PersonAvatar.row,
              )
            else
              Icon(
                LucideIcons.settings,
                size: AnchorTokens.sizeIconMedium,
                color: colors.appMuted,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: user == null
                  ? Text(
                      context.l10n.settingsTitle,
                      style: AppTypography.row.copyWith(color: colors.appText),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.secondary.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.appText,
                          ),
                        ),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.footnote.copyWith(
                            color: colors.appMuted,
                          ),
                        ),
                      ],
                    ),
            ),
            if (user != null)
              Icon(
                LucideIcons.settings,
                size: AnchorTokens.sizeIconSmall,
                color: colors.appMuted,
              ),
          ],
        ),
      ),
    );
  }
}
