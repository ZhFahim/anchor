import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons_500.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';

import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/session/session_expired_provider.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/theme/tokens/anchor_tokens.dart';
import '../../../../core/widgets/bar_title.dart';
import '../../../../l10n/l10n.dart';
import '../../../sync/data/sync_compatibility.dart';
import '../../../sync/data/sync_manager.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/tag_colors.dart';
import '../../domain/note_dates.dart';
import '../note_folder.dart';
import '../notes_controller.dart';

String? listTitleLine(
  AppLocalizations l10n, {
  required NoteFolder folder,
  required bool isOnline,
  required int unsynced,
  required bool hasSyncFailed,
}) {
  if (!isOnline) {
    return unsynced > 0
        ? l10n.listOfflineChanges(unsynced)
        : l10n.listOfflineSaved;
  }
  if (hasSyncFailed) return l10n.listSyncFailed;
  return switch (folder) {
    NoteFolder.archive => l10n.listArchiveLine,
    NoteFolder.trash => l10n.listTrashLine(trashDays),
    NoteFolder.notes => null,
  };
}

String _titleOf(NoteFolder folder, Tag? tag, AppLocalizations l10n) =>
    tag == null ? folder.titleIn(l10n) : '#${tag.name}';

class ListLargeTitle extends ConsumerWidget {
  const ListLargeTitle({
    super.key,
    required this.folder,
    required this.tag,
    required this.onOpenMenu,
  });

  final NoteFolder folder;
  final Tag? tag;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.anchor;
    final tag = this.tag;
    final isOnline = ref.watch(isOnlineProvider);
    final compatibility = ref.watch(syncCompatibilityProvider).value;
    final line = listTitleLine(
      context.l10n,
      folder: folder,
      isOnline: isOnline,
      unsynced: ref.watch(unsyncedNoteCountProvider),
      hasSyncFailed:
          ref.watch(syncFailedProvider) &&
          !ref.watch(sessionExpiredProvider) &&
          !(compatibility?.isMismatch ?? false),
    );
    return LargeBarTitle(
      tag?.name ?? folder.titleIn(context.l10n),
      semanticLabel: context.l10n.listTitleMenu(
        _titleOf(folder, tag, context.l10n),
      ),
      onTap: onOpenMenu,
      leading: tag == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons600.hash,
                  size: AnchorTokens.sizeIconLarge,
                  color: tagColorsOf(context, tag.color).hash,
                ),
                const SizedBox(width: 2),
              ],
            ),
      line: line == null
          ? null
          : BarTitleLine(
              line,
              leading: isOnline
                  ? null
                  : Icon(
                      LucideIcons.cloudOff,
                      size: AnchorTokens.sizeIconSmall,
                      color: colors.appMuted,
                    ),
            ),
    );
  }
}

class ListBarTitle extends StatelessWidget {
  const ListBarTitle({
    super.key,
    required this.folder,
    required this.tag,
    required this.onOpenMenu,
  });

  final NoteFolder folder;
  final Tag? tag;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final tag = this.tag;
    return BarTitle(
      tag?.name ?? folder.titleIn(context.l10n),
      semanticLabel: context.l10n.listTitleMenu(
        _titleOf(folder, tag, context.l10n),
      ),
      onTap: onOpenMenu,
      leading: tag == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons600.hash,
                  size: AnchorTokens.sizeIconSmall,
                  color: tagColorsOf(context, tag.color).hash,
                ),
                const SizedBox(width: 2),
              ],
            ),
      trailing: Padding(
        padding: const EdgeInsetsDirectional.only(start: 4),
        child: Icon(
          LucideIcons500.chevronDown,
          size: AnchorTokens.sizeIconSmall,
          color: context.anchor.appMuted,
        ),
      ),
    );
  }
}
