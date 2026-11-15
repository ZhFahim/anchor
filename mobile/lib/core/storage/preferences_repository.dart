import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../network/custom_headers.dart';
import '../theme/note_typography.dart';
import 'secure_storage_provider.dart';
import 'storage_keys.dart';

part 'preferences_repository.g.dart';

@Riverpod(keepAlive: true)
PreferencesRepository preferencesRepository(Ref ref) {
  return PreferencesRepository(ref.watch(secureStorageProvider));
}

class PreferencesRepository {
  final FlutterSecureStorage _storage;

  const PreferencesRepository(this._storage);

  Future<bool> getSortChecklistItems() async {
    final value = await _storage.read(key: StorageKeys.sortChecklistItems);
    return value != 'false';
  }

  Future<void> setSortChecklistItems(bool value) async {
    await _storage.write(
      key: StorageKeys.sortChecklistItems,
      value: value.toString(),
    );
  }

  /// Most recent last.
  Future<List<String>> getFoldedChecklistNotes() =>
      _readIds(StorageKeys.foldedChecklistNotes);

  Future<void> setFoldedChecklistNotes(List<String> noteIds) =>
      _writeIds(StorageKeys.foldedChecklistNotes, noteIds);

  Future<List<String>> getOpenArchivedTags() =>
      _readIds(StorageKeys.openArchivedTags);

  Future<void> setOpenArchivedTags(List<String> tagIds) =>
      _writeIds(StorageKeys.openArchivedTags, tagIds);

  Future<List<String>> _readIds(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) return const [];
    try {
      final ids = jsonDecode(value);
      return ids is List ? ids.whereType<String>().toList() : const [];
    } on FormatException {
      return const [];
    }
  }

  Future<void> _writeIds(String key, List<String> ids) =>
      _storage.write(key: key, value: jsonEncode(ids));

  Future<bool> getNotificationsAsked() async {
    final value = await _storage.read(key: StorageKeys.notificationsAsked);
    return value == 'true';
  }

  Future<void> setNotificationsAsked(bool value) async {
    await _storage.write(
      key: StorageKeys.notificationsAsked,
      value: value.toString(),
    );
  }

  Future<bool> getExactAlarmsOffered() async {
    final value = await _storage.read(key: StorageKeys.exactAlarmsOffered);
    return value == 'true';
  }

  Future<void> setExactAlarmsOffered(bool value) async {
    await _storage.write(
      key: StorageKeys.exactAlarmsOffered,
      value: value.toString(),
    );
  }

  Future<String?> getNoteFont() => _storage.read(key: StorageKeys.noteFont);

  Future<void> setNoteFont(String font) async {
    await _storage.write(key: StorageKeys.noteFont, value: font);
  }

  Future<double> getNoteTextSize() async => NoteTextSize.fromStored(
    await _storage.read(key: StorageKeys.noteTextSize),
  );

  Future<void> setNoteTextSize(double textSize) async {
    await _storage.write(
      key: StorageKeys.noteTextSize,
      value: textSize.toString(),
    );
  }

  Future<String?> getThemeMode() => _storage.read(key: StorageKeys.themeMode);

  Future<void> setThemeMode(String mode) async {
    await _storage.write(key: StorageKeys.themeMode, value: mode);
  }

  Future<String?> getDisplayDensity() =>
      _storage.read(key: StorageKeys.displayDensity);

  Future<void> setDisplayDensity(String density) async {
    await _storage.write(key: StorageKeys.displayDensity, value: density);
  }

  Future<bool> getAllowSelfSignedCert() async {
    final value = await _storage.read(key: StorageKeys.allowSelfSignedCert);
    return value == 'true';
  }

  Future<void> setAllowSelfSignedCert(bool value) async {
    await _storage.write(
      key: StorageKeys.allowSelfSignedCert,
      value: value.toString(),
    );
  }

  Future<List<CustomHeader>> getCustomHeaders() async {
    final value = await _storage.read(key: StorageKeys.customHeaders);
    if (value == null) return const [];
    try {
      final headers = jsonDecode(value);
      if (headers is! List) return const [];
      return headers
          .whereType<Map<String, dynamic>>()
          .map(CustomHeader.fromJson)
          .take(maxCustomHeaders)
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> setCustomHeaders(List<CustomHeader> headers) => _storage.write(
    key: StorageKeys.customHeaders,
    value: jsonEncode([
      for (final header in headers.take(maxCustomHeaders)) header.toJson(),
    ]),
  );

  Future<String?> getNotesViewType() =>
      _storage.read(key: StorageKeys.notesViewType);

  Future<void> setNotesViewType(String viewType) async {
    await _storage.write(key: StorageKeys.notesViewType, value: viewType);
  }

  Future<String?> getNotesSortOption() =>
      _storage.read(key: StorageKeys.notesSortOption);

  Future<void> setNotesSortOption(String sortOption) async {
    await _storage.write(key: StorageKeys.notesSortOption, value: sortOption);
  }

  Future<bool> getNotesSortAscending() async {
    final value = await _storage.read(key: StorageKeys.notesSortAscending);
    return value == 'true';
  }

  Future<void> setNotesSortAscending(bool isAscending) async {
    await _storage.write(
      key: StorageKeys.notesSortAscending,
      value: isAscending.toString(),
    );
  }

  Future<bool> getAppLockEnabled() async {
    final value = await _storage.read(key: StorageKeys.appLockEnabled);
    return value == 'true';
  }

  Future<void> setAppLockEnabled(bool isEnabled) async {
    await _storage.write(
      key: StorageKeys.appLockEnabled,
      value: isEnabled.toString(),
    );
  }

  Future<int> getLockGraceMinutes() async {
    final value = await _storage.read(key: StorageKeys.lockGraceMinutes);
    return int.tryParse(value ?? '') ?? 5;
  }

  Future<void> setLockGraceMinutes(int minutes) async {
    await _storage.write(
      key: StorageKeys.lockGraceMinutes,
      value: minutes.toString(),
    );
  }

  Future<DateTime?> getLastUnlockedAt() async {
    final value = await _storage.read(key: StorageKeys.lastUnlockedAt);
    final millis = int.tryParse(value ?? '');
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastUnlockedAt(DateTime? at) async {
    if (at == null) {
      await _storage.delete(key: StorageKeys.lastUnlockedAt);
      return;
    }
    await _storage.write(
      key: StorageKeys.lastUnlockedAt,
      value: at.millisecondsSinceEpoch.toString(),
    );
  }

  Future<String?> getMotionSpeedName() =>
      _storage.read(key: StorageKeys.motionSpeed);

  Future<void> setMotionSpeedName(String name) async {
    await _storage.write(key: StorageKeys.motionSpeed, value: name);
  }

  Future<String?> getBackupFolder() =>
      _storage.read(key: StorageKeys.backupFolder);

  Future<void> setBackupFolder(String? uri) => uri == null
      ? _storage.delete(key: StorageKeys.backupFolder)
      : _storage.write(key: StorageKeys.backupFolder, value: uri);

  Future<bool> getBackupAutomatic() async =>
      await _storage.read(key: StorageKeys.backupAutomatic) != 'false';

  Future<void> setBackupAutomatic(bool value) =>
      _storage.write(key: StorageKeys.backupAutomatic, value: value.toString());

  Future<int> getBackupPeriodDays() async =>
      int.tryParse(
        await _storage.read(key: StorageKeys.backupPeriodDays) ?? '',
      ) ??
      7;

  Future<void> setBackupPeriodDays(int days) =>
      _storage.write(key: StorageKeys.backupPeriodDays, value: '$days');

  Future<int> getBackupKeepFiles() async =>
      int.tryParse(
        await _storage.read(key: StorageKeys.backupKeepFiles) ?? '',
      ) ??
      3;

  Future<void> setBackupKeepFiles(int count) =>
      _storage.write(key: StorageKeys.backupKeepFiles, value: '$count');

  Future<String?> getBackupPassword() =>
      _storage.read(key: StorageKeys.backupPassword);

  Future<void> setBackupPassword(String? password) => password == null
      ? _storage.delete(key: StorageKeys.backupPassword)
      : _storage.write(key: StorageKeys.backupPassword, value: password);

  Future<DateTime?> getBackupLastAt() async {
    final stored = await _storage.read(key: StorageKeys.backupLastAt);
    return stored == null ? null : DateTime.tryParse(stored);
  }

  Future<void> setBackupLastAt(DateTime at) => _storage.write(
    key: StorageKeys.backupLastAt,
    value: at.toUtc().toIso8601String(),
  );
}
