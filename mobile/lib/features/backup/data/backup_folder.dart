import 'package:flutter/services.dart';

/// The folder the person picked, and the name Android gave it.
class BackupFolderChoice {
  const BackupFolderChoice(this.uri, this.name);

  final String uri;
  final String? name;
}

/// The folder the person picked, reached through Android's document tree so it
/// stays writable after a restart.
class BackupFolder {
  BackupFolder([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('anchor/backup');

  final MethodChannel _channel;

  Future<BackupFolderChoice?> pick() async {
    final result = await _channel.invokeMethod<Object?>('pickFolder');
    if (result == null) return null;
    if (result is String) return BackupFolderChoice(result, null);
    final map = Map<String, dynamic>.from(result as Map);
    final uri = map['uri'] as String?;
    if (uri == null || uri.isEmpty) return null;
    final raw = map['name'] as String?;
    final name = raw == null || raw.trim().isEmpty ? null : raw;
    return BackupFolderChoice(uri, name);
  }

  /// `bytes` must reach Kotlin as a byte array, so it is sent as a Uint8List.
  /// A plain `List<int>` arrives as an int array and the plugin refuses it.
  Future<void> write(String folderUri, String name, List<int> bytes) {
    return _channel.invokeMethod<void>('writeFile', {
      'folder': folderUri,
      'name': name,
      'bytes': Uint8List.fromList(bytes),
    });
  }

  Future<List<String>> list(String folderUri) async {
    final names = await _channel.invokeListMethod<String>('listFiles', {
      'folder': folderUri,
    });
    return names ?? const [];
  }

  Future<void> delete(String folderUri, String name) {
    return _channel.invokeMethod<void>('deleteFile', {
      'folder': folderUri,
      'name': name,
    });
  }
}
