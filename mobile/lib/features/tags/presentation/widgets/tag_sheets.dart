import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';

import '../../../../core/motion/haptics.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/theme/tokens/anchor_tokens.dart';
import '../../../../core/widgets/anchor_dialog.dart';
import '../../../../core/widgets/anchor_sheet.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/check_circle.dart';
import '../../../../core/widgets/grouped_list.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/selection_ring.dart';
import '../../../../l10n/l10n.dart';
import '../../../notes/data/repository/notes_repository.dart';
import '../../../notes/domain/note.dart';
import '../../domain/tag.dart';
import '../tag_colors.dart';
import '../tags_controller.dart';

String _tagErrorMessage(Object error, AppLocalizations l10n) =>
    error is TagNameTakenException
    ? l10n.tagNameTaken(error.name)
    : l10n.tagSaveFailed;

Future<void> showTagPicker(BuildContext context, List<Note> notes) {
  return showAnchorSheet(
    context,
    detent: SheetDetent.medium,
    canGrow: true,
    semanticLabel: notes.length > 1
        ? context.l10n.tagNotesTitle
        : context.l10n.tagsTitle,
    builder: (_) =>
        _TagPicker(noteIds: notes.map((n) => n.id).toList(), initial: notes),
  );
}

class _TagPicker extends ConsumerStatefulWidget {
  const _TagPicker({required this.noteIds, required this.initial});

  final List<String> noteIds;
  final List<Note> initial;

  @override
  ConsumerState<_TagPicker> createState() => _TagPickerState();
}

class _TagPickerState extends ConsumerState<_TagPicker> {
  final _query = TextEditingController();
  late final Map<String, Set<String>> _tagsOf = {
    for (final n in widget.initial) n.id: {...n.tagIds},
  };

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// Whether the notes have [tagId]: all of them, none, or null for some.
  bool? _hasTag(String tagId) {
    final count = widget.noteIds
        .where((id) => _tagsOf[id]!.contains(tagId))
        .length;
    return count == 0
        ? false
        : count == widget.noteIds.length
        ? true
        : null;
  }

  Future<void> _toggle(Tag tag) async {
    Haptics.selection();
    final repo = ref.read(notesRepositoryProvider);
    final isRemoving = _hasTag(tag.id) == true;
    setState(() {
      for (final id in widget.noteIds) {
        isRemoving ? _tagsOf[id]!.remove(tag.id) : _tagsOf[id]!.add(tag.id);
      }
    });
    try {
      if (isRemoving) {
        await repo.removeTags(widget.noteIds, [tag.id]);
      } else {
        await repo.addTags(widget.noteIds, [tag.id]);
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          context.l10n.tagUpdateFailed,
          kind: SnackbarKind.error,
        );
      }
    }
  }

  Future<void> _create(String name) async {
    try {
      final tag = await ref
          .read(tagsControllerProvider.notifier)
          .createTag(name);
      _query.clear();
      await _toggle(tag);
      Haptics.success();
    } catch (error) {
      if (mounted) {
        AppSnackbar.show(
          context,
          _tagErrorMessage(error, context.l10n),
          kind: SnackbarKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final tags = sortTagsByName(
      ref.watch(tagsControllerProvider).value ?? const <Tag>[],
    );
    final counts = ref.watch(tagNoteCountsProvider);
    final query = _query.text.trim();
    final shown = tags
        .where((t) => t.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final exact = isTagNameTaken(tags, query);
    final bulk = widget.noteIds.length > 1;
    final l10n = context.l10n;

    final rows = <Widget>[
      if (query.isNotEmpty && !exact)
        GroupedListTile(
          label: l10n.tagCreateNamed(query),
          leading: Icon(
            LucideIcons.plus,
            size: AnchorTokens.sizeIconMedium,
            color: colors.appText,
          ),
          onTap: () => _create(query),
        ),
      for (final t in shown)
        GroupedListTile(
          label: t.name,
          leading: SizedBox(
            width: AnchorTokens.sizeIconMedium,
            child: Icon(
              LucideIcons600.hash,
              size: AnchorTokens.sizeIconSmall,
              color: tagColorsOf(context, t.color).hash,
            ),
          ),
          value: '${counts[t.id] ?? 0}',
          trailing: CheckCircle(value: _hasTag(t.id)),
          semanticLabel: switch (_hasTag(t.id)) {
            null => l10n.tagAddedToSome(t.name),
            true => l10n.tagAdded(t.name),
            false => l10n.tagNotAdded(t.name),
          },
          onTap: () => _toggle(t),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(
          title: bulk ? l10n.tagNotesTitle : l10n.tagsTitle,
          subtitle: bulk ? l10n.notesCount(widget.noteIds.length) : null,
          showDone: true,
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, context.density.space16),
          child: AppTextField(
            controller: _query,
            icon: LucideIcons.search,
            hint: l10n.tagSearchOrCreate,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              expandSheet(context);
              setState(() {});
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty && !exact) _create(value.trim());
            },
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 0, 16, context.density.space16),
            children: [
              if (rows.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: context.density.space16,
                  ),
                  child: Text(
                    l10n.tagsEmpty,
                    style: AppTypography.secondary.copyWith(
                      color: colors.appMuted,
                    ),
                  ),
                )
              else
                GroupedList(semanticLabel: l10n.tagsTitle, children: rows),
              const SheetBottomSpace(),
            ],
          ),
        ),
      ],
    );
  }
}

class TagColorRow extends StatelessWidget {
  const TagColorRow({super.key, required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String> onChanged;

  static String _hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static String _name(String palette, AppLocalizations l10n) =>
      switch (palette) {
        'red' => l10n.colorRed,
        'pink' => l10n.colorPink,
        'purple' => l10n.colorPurple,
        'deepPurple' => l10n.colorDeepPurple,
        'indigo' => l10n.colorIndigo,
        'blue' => l10n.colorBlue,
        'lightBlue' => l10n.colorLightBlue,
        'cyan' => l10n.colorCyan,
        'teal' => l10n.colorTeal,
        'green' => l10n.colorGreen,
        'lightGreen' => l10n.colorLightGreen,
        'lime' => l10n.colorLime,
        'amber' => l10n.colorAmber,
        'orange' => l10n.colorOrange,
        'deepOrange' => l10n.colorDeepOrange,
        'brown' => l10n.colorBrown,
        'blueGrey' => l10n.colorBlueGrey,
        'yellow' => l10n.colorYellow,
        _ => palette,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final selectedPalette = tagPaletteOf(value);
    return Semantics(
      label: context.l10n.tagColor,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final entry in AnchorTokens.tagStored.entries)
            Pressable(
              style: PressStyle.thumb,
              onTap: () {
                if (entry.key != selectedPalette) Haptics.selection();
                onChanged(_hex(entry.value));
              },
              selected: entry.key == selectedPalette,
              semanticLabel: _name(entry.key, context.l10n),
              child: SelectionRing(
                isShown: entry.key == selectedPalette,
                borderRadius: BorderRadius.circular(AnchorTokens.radiusPill),
                child: Container(
                  width: 40, // off-scale: a color swatch
                  height: 40, // off-scale: as above
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.tags[entry.key]!.tintFill,
                  ),
                  child: Icon(
                    LucideIcons600.hash,
                    size: AnchorTokens.sizeIconSmall,
                    color: colors.tags[entry.key]!.hash,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showTagMenu(BuildContext context, Tag tag) {
  return showAnchorSheet(
    context,
    semanticLabel: context.l10n.tagSheetLabel(tag.name),
    builder: (_) => _TagMenu(tagId: tag.id),
  );
}

class _TagMenu extends ConsumerWidget {
  const _TagMenu({required this.tagId});

  final String tagId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tag = ref
        .watch(tagsControllerProvider)
        .value
        ?.where((t) => t.id == tagId)
        .firstOrNull;
    if (tag == null) {
      return const SizedBox(height: 120); // off-scale: room while it loads
    }
    final count = ref.watch(tagNoteCountsProvider)[tag.id] ?? 0;
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(
          title: '#${tag.name}',
          titleChild: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '#',
                  style: TextStyle(color: tagColorsOf(context, tag.color).hash),
                ),
                TextSpan(text: tag.name),
              ],
            ),
          ),
          subtitle: l10n.notesCount(count),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: context.density.space16,
              children: [
                Section(
                  label: l10n.tagColor,
                  isBoxed: false,
                  child: TagColorRow(
                    value: tag.color,
                    onChanged: (hex) => ref
                        .read(tagsControllerProvider.notifier)
                        .updateTag(tag.copyWith(color: hex)),
                  ),
                ),
                GroupedList(
                  children: [
                    GroupedListTile(
                      icon: LucideIcons.pencil,
                      label: l10n.tagRename,
                      onTap: () {
                        Navigator.of(context).pop();
                        showTagEditor(context, tag: tag);
                      },
                    ),
                    GroupedListTile(
                      icon: LucideIcons.trash2,
                      label: l10n.tagDelete,
                      isDanger: true,
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        final ok = await showAnchorDialog(
                          context,
                          title: l10n.tagDeleteTitle(tag.name),
                          message: count > 0
                              ? l10n.tagDeleteMessage(count)
                              : l10n.tagDeleteUnused,
                          confirmLabel: l10n.tagDelete,
                          icon: LucideIcons.trash2,
                          isDanger: true,
                        );
                        if (!ok) return;
                        if (ref.read(selectedTagFilterProvider) == tag.id) {
                          ref.read(selectedTagFilterProvider.notifier).clear();
                        }
                        await ref
                            .read(tagsControllerProvider.notifier)
                            .deleteTag(tag.id);
                        navigator.pop();
                        if (context.mounted) {
                          AppSnackbar.show(context, l10n.tagDeleted(tag.name));
                        }
                      },
                    ),
                  ],
                ),
                const SheetBottomSpace(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> showTagEditor(BuildContext context, {Tag? tag}) {
  return showAnchorSheet(
    context,
    semanticLabel: tag == null ? context.l10n.tagNew : context.l10n.tagRename,
    builder: (_) => _TagEditor(tag: tag),
  );
}

class _TagEditor extends ConsumerStatefulWidget {
  const _TagEditor({this.tag});

  final Tag? tag;

  @override
  ConsumerState<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends ConsumerState<_TagEditor> {
  late final TextEditingController _name = TextEditingController(
    text: widget.tag?.name ?? '',
  );
  late String _color = widget.tag?.color ?? generateRandomTagColor();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    setState(() => _busy = true);
    try {
      final controller = ref.read(tagsControllerProvider.notifier);
      if (widget.tag == null) {
        await controller.createTag(name, color: _color);
      } else {
        await controller.updateTag(widget.tag!.copyWith(name: name));
      }
      Haptics.success();
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        AppSnackbar.show(
          context,
          _tagErrorMessage(error, context.l10n),
          kind: SnackbarKind.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final tags = ref.watch(tagsControllerProvider).value ?? const <Tag>[];
    final name = _name.text.trim();
    final isNameTaken = isTagNameTaken(tags, name, exceptId: widget.tag?.id);
    final valid =
        name.isNotEmpty &&
        !isNameTaken &&
        (widget.tag == null || name != widget.tag!.name);
    final hash = tagColorsOf(context, _color).hash;
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title: widget.tag == null ? l10n.tagNew : l10n.tagRename),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: context.density.space16,
              children: [
                Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: AnchorTokens.sizeControlSmall,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                        colors.appText.withValues(alpha: 0.06),
                        colors.appSurface,
                      ),
                      borderRadius: BorderRadius.circular(
                        AnchorTokens.radiusPill,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Icon(
                          LucideIcons600.hash,
                          size: AnchorTokens.sizeIconSmall,
                          color: hash,
                        ),
                        Flexible(
                          child: Text(
                            name.isEmpty ? l10n.tagNamePreview : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.secondary.copyWith(
                              fontWeight: FontWeight.w600,
                              color: name.isEmpty
                                  ? colors.appMuted
                                  : colors.appText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AppTextField(
                  controller: _name,
                  icon: LucideIcons.hash,
                  hint: l10n.tagNameHint,
                  autofocus: true,
                  error: isNameTaken ? l10n.tagNameTaken(name) : null,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (valid) _save();
                  },
                ),
                if (widget.tag == null)
                  TagColorRow(
                    value: _color,
                    onChanged: (hex) => setState(() => _color = hex),
                  ),
              ],
            ),
          ),
        ),
        SheetFooter(
          children: [
            AppButton(
              label: l10n.commonCancel,
              kind: AppButtonKind.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
            AppButton(
              label: widget.tag == null ? l10n.tagCreate : l10n.tagRenameAction,
              isBusy: _busy,
              onPressed: valid ? _save : null,
            ),
          ],
        ),
      ],
    );
  }
}
