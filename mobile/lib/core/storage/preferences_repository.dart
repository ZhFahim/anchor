import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../network/custom_headers.dart';
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

  Future<String?> getNoteTextSize() =>
      _storage.read(key: StorageKeys.noteTextSize);

  Future<void> setNoteTextSize(String textSize) async {
    await _storage.write(key: StorageKeys.noteTextSize, value: textSize);
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

  /// Most recent last.
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

  Future<void> setCustomHeaders(List<CustomHeader> headers) =>
      _storage.write(
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
}
