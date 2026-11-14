import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/widgets/grouped_list.dart';
import '../../../core/widgets/switch_row.dart';
import '../../../l10n/l10n.dart';
import '../../../main.dart' show scaffoldMessengerKey;
import '../data/backup_cipher.dart';
import '../data/backup_reader.dart';
import '../data/backup_restorer.dart';
import '../domain/backup_settings.dart';
import 'backup_controller.dart';
import 'backup_settings_controller.dart';
import 'restore_sheet.dart';

class BackupSection extends ConsumerWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(backupSettingsControllerProvider).value;
    final running = ref.watch(backupControllerProvider);
    if (settings == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    return GroupedList(
      children: [
        GroupedListTile(
          icon: LucideIcons.archive,
          label: l10n.backupFolder,
          value: settings.folderDisplayName ?? l10n.backupChooseFolder,
          showChevron: true,
          onTap: () => _pickFolder(context, ref),
        ),
        GroupedListTile(
          icon: LucideIcons.download,
          label: running ? l10n.backupRunning : l10n.backupNow,
          showChevron: !running,
          trailing: running
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: running ? null : () => _backupNow(context, ref),
        ),
        GroupedListTile(
          icon: LucideIcons.archiveRestore,
          label: l10n.backupRestore,
          showChevron: !running,
          onTap: running ? null : () => _restore(context, ref),
        ),
        SwitchRow(
          icon: LucideIcons.history,
          label: l10n.backupAutomatic,
          value: settings.automatic,
          onChanged: (value) => ref
              .read(backupSettingsControllerProvider.notifier)
              .setAutomatic(value),
        ),
        GroupedListTile(
          icon: LucideIcons.calendarClock,
          label: l10n.backupPeriod(settings.periodDays),
          showChevron: true,
          onTap: () => _pickPeriod(context, ref, settings),
        ),
        GroupedListTile(
          icon: LucideIcons.copy,
          label: l10n.backupKeep(settings.keepFiles),
          showChevron: true,
          onTap: () => _pickKeep(context, ref, settings),
        ),
        GroupedListTile(
          icon: LucideIcons.keyRound,
          label: l10n.backupPassword,
          value: settings.password == null ? l10n.backupPasswordNone : '••••••',
          showChevron: true,
          onTap: () => _pickPassword(context, ref),
        ),
      ],
    );
  }

  Future<void> _pickFolder(BuildContext context, WidgetRef ref) async {
    final choice = await ref.read(backupFolderProvider).pick();
    if (choice == null) return;
    await ref
        .read(backupSettingsControllerProvider.notifier)
        .setFolder(choice.uri, name: choice.name);
  }

  Future<void> _backupNow(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final result = await ref
        .read(backupControllerProvider.notifier)
        .run(automatic: false);
    final message = switch (result.outcome) {
      BackupOutcome.done => l10n.backupDone(result.fileName ?? ''),
      BackupOutcome.noFolder => l10n.backupNoFolder,
      BackupOutcome.failed => l10n.backupFailed(result.error ?? ''),
    };
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.pickFile();
    final pickedPath = picked?.path;
    if (pickedPath == null || !context.mounted) return;

    final l10n = context.l10n;
    BackupReader reader;
    try {
      List<int> bytes = await File(pickedPath).readAsBytes();
      if (BackupCipher.isEncrypted(bytes)) {
        if (!context.mounted) return;
        final password = await _askPassword(context);
        if (password == null) return;
        try {
          bytes = await BackupCipher.decrypt(bytes, password);
        } on WrongPasswordException {
          _toast(l10n.restoreWrongPassword);
          return;
        }
      }
      reader = BackupReader(bytes);
    } on BackupFormatException {
      _toast(l10n.restoreBadFile);
      return;
    }

    if (!context.mounted) return;
    final mode = await showRestoreSheet(
      context,
      notes: reader.contents.notes.length,
      attachments: reader.manifest.attachments,
    );
    if (mode == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.restoreConfirm(reader.contents.notes.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonReplace),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final documents = await getApplicationDocumentsDirectory();
    final written = await BackupRestorer(
      ref.read(appDatabaseProvider),
      Directory(path.join(documents.path, 'attachments')),
    ).restore(reader, mode);
    _toast(l10n.restoreDone(written));
  }

  Future<String?> _askPassword(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.backupPassword),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPeriod(
    BuildContext context,
    WidgetRef ref,
    BackupSettings settings,
  ) async {
    final value = await _pickNumber(
      context,
      title: context.l10n.backupPeriod(settings.periodDays),
      current: settings.periodDays,
      min: BackupSettings.minPeriodDays,
      max: BackupSettings.maxPeriodDays,
    );
    if (value == null) return;
    await ref
        .read(backupSettingsControllerProvider.notifier)
        .setPeriodDays(value);
  }

  Future<void> _pickKeep(
    BuildContext context,
    WidgetRef ref,
    BackupSettings settings,
  ) async {
    final value = await _pickNumber(
      context,
      title: context.l10n.backupKeep(settings.keepFiles),
      current: settings.keepFiles,
      min: BackupSettings.minKeepFiles,
      max: BackupSettings.maxKeepFiles,
    );
    if (value == null) return;
    await ref
        .read(backupSettingsControllerProvider.notifier)
        .setKeepFiles(value);
  }

  Future<int?> _pickNumber(
    BuildContext context, {
    required String title,
    required int current,
    required int min,
    required int max,
  }) {
    var value = current;
    return showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            label: '$value',
            onChanged: (next) => setState(() => value = next.round()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(value),
              child: Text(context.l10n.commonSave),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPassword(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.backupPassword),
        content: TextField(controller: controller, obscureText: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(context.l10n.backupPasswordNone),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(context.l10n.commonReplace),
          ),
        ],
      ),
    );
    if (value == null) return;
    await ref
        .read(backupSettingsControllerProvider.notifier)
        .setPassword(value.isEmpty ? null : value);
  }

  void _toast(String message) {
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
