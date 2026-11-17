import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/widgets/anchor_sheet.dart';
import '../../../../core/widgets/grouped_list.dart';
import '../../../../core/widgets/segmented_control.dart';
import '../../../../l10n/l10n.dart';
import '../notes_view_options.dart';

Future<void> showViewOptionsSheet(BuildContext context) => showAnchorSheet(
  context,
  semanticLabel: context.l10n.listViewOptions,
  builder: (_) => const _ViewOptionsSheet(),
);

class _ViewOptionsSheet extends ConsumerWidget {
  const _ViewOptionsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options =
        ref.watch(notesViewOptionsProvider).value ?? const NotesViewOptions();
    final notifier = ref.read(notesViewOptionsProvider.notifier);
    final byTitle = options.sortOption == SortOption.title;
    final l10n = context.l10n;
    Widget sortTile(SortOption option, IconData icon, String label) =>
        GroupedListTile(
          icon: icon,
          label: label,
          checked: options.sortOption == option,
          onTap: () {
            if (options.sortOption == option) return;
            notifier.setSort(option, isAscending: option == SortOption.title);
          },
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title: l10n.listViewOptions, showDone: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Section.gapOf(context),
            children: [
              Section(
                label: l10n.viewLayout,
                child: SegmentedControl<ViewType>(
                  semanticLabel: l10n.viewLayout,
                  value: options.viewType,
                  onChanged: notifier.setViewType,
                  segments: [
                    Segment(
                      value: ViewType.masonry,
                      label: l10n.viewMasonry,
                      icon: LucideIcons.layoutDashboard,
                    ),
                    Segment(
                      value: ViewType.grid,
                      label: l10n.viewGrid,
                      icon: LucideIcons.layoutGrid,
                    ),
                    Segment(
                      value: ViewType.list,
                      label: l10n.viewList,
                      icon: LucideIcons.rows3,
                    ),
                  ],
                ),
              ),
              Section(
                label: l10n.viewSortBy,
                child: GroupedList(
                  semanticLabel: l10n.viewSortBy,
                  children: [
                    sortTile(
                      SortOption.dateModified,
                      LucideIcons.pencilLine,
                      l10n.viewDateEdited,
                    ),
                    sortTile(
                      SortOption.dateCreated,
                      LucideIcons.calendarPlus,
                      l10n.viewDateCreated,
                    ),
                    sortTile(
                      SortOption.title,
                      LucideIcons.aLargeSmall,
                      l10n.viewTitle,
                    ),
                  ],
                ),
              ),
              Section(
                label: l10n.viewOrder,
                child: SegmentedControl<bool>(
                  semanticLabel: l10n.viewOrder,
                  value: options.isAscending,
                  onChanged: notifier.setSortDirection,
                  segments: byTitle
                      ? [
                          Segment(value: true, label: l10n.viewAtoZ),
                          Segment(value: false, label: l10n.viewZtoA),
                        ]
                      : [
                          Segment(value: false, label: l10n.viewNewestFirst),
                          Segment(value: true, label: l10n.viewOldestFirst),
                        ],
                ),
              ),
            ],
          ),
        ),
        const SheetBottomSpace(),
      ],
    );
  }
}
