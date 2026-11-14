import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/preferences_repository.dart';
import '../domain/backup_settings.dart';

part 'backup_settings_controller.g.dart';

@Riverpod(keepAlive: true)
class BackupSettingsController extends _$BackupSettingsController {
  @override
  Future<BackupSettings> build() async {
    final repository = ref.watch(preferencesRepositoryProvider);
    final folderUri = await repository.getBackupFolder();
    return BackupSettings(
      folderUri: folderUri,
      folderName: folderUri == null ? null : BackupSettings.nameFromUri(folderUri),
      automatic: await repository.getBackupAutomatic(),
      periodDays: await repository.getBackupPeriodDays(),
      keepFiles: await repository.getBackupKeepFiles(),
      password: await repository.getBackupPassword(),
      lastBackupAt: await repository.getBackupLastAt(),
    );
  }

  Future<void> setFolder(String? uri, {String? name}) async {
    await ref.read(preferencesRepositoryProvider).setBackupFolder(uri);
    _update(
      (settings) => uri == null
          ? settings.copyWith(clearFolder: true)
          : settings.copyWith(
              folderUri: uri,
              folderName: name ?? BackupSettings.nameFromUri(uri),
            ),
    );
  }

  Future<void> setAutomatic(bool value) async {
    await ref.read(preferencesRepositoryProvider).setBackupAutomatic(value);
    _update((settings) => settings.copyWith(automatic: value));
  }

  Future<void> setPeriodDays(int days) async {
    final clamped = days.clamp(
      BackupSettings.minPeriodDays,
      BackupSettings.maxPeriodDays,
    );
    await ref.read(preferencesRepositoryProvider).setBackupPeriodDays(clamped);
    _update((settings) => settings.copyWith(periodDays: clamped));
  }

  Future<void> setKeepFiles(int count) async {
    final clamped = count.clamp(
      BackupSettings.minKeepFiles,
      BackupSettings.maxKeepFiles,
    );
    await ref.read(preferencesRepositoryProvider).setBackupKeepFiles(clamped);
    _update((settings) => settings.copyWith(keepFiles: clamped));
  }

  Future<void> setPassword(String? password) async {
    await ref.read(preferencesRepositoryProvider).setBackupPassword(password);
    _update(
      (settings) => password == null
          ? settings.copyWith(clearPassword: true)
          : settings.copyWith(password: password),
    );
  }

  Future<void> markBackedUp(DateTime at) async {
    await ref.read(preferencesRepositoryProvider).setBackupLastAt(at);
    _update((settings) => settings.copyWith(lastBackupAt: at));
  }

  void _update(BackupSettings Function(BackupSettings) change) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(change(current));
  }
}
