import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../domain/share_context.dart';
import '../domain/share_entry.dart';

/// `context.json`, the sheet's `staging/` and the saved shares in `inbox/`.
class ShareInbox {
  const ShareInbox(this.root);

  static const _channel = MethodChannel('anchor/share');

  /// Null where the platform has no shared folder, such as an iOS build
  /// without its App Group.
  static Future<ShareInbox?> find() async {
    try {
      final path = await _channel.invokeMethod<String>('folder');
      return path == null ? null : ShareInbox(Directory(path));
    } on MissingPluginException {
      return null;
    }
  }

  static void listen(VoidCallback? onChanged) {
    _channel.setMethodCallHandler(
      onChanged == null
          ? null
          : (call) async {
              if (call.method == 'inboxChanged') onChanged();
            },
    );
  }

  final Directory root;

  Directory get _inbox => Directory('${root.path}/inbox');

  File get _context => File('${root.path}/context.json');

  /// Oldest first; folders that aren't a readable entry are dropped.
  Future<List<({ShareEntry entry, Directory folder})>> entries() async {
    if (!await _inbox.exists()) return const [];
    final found = <({ShareEntry entry, Directory folder})>[];
    await for (final folder in _inbox.list()) {
      if (folder is! Directory) continue;
      final entry = await _read(File('${folder.path}/manifest.json'));
      if (entry == null) {
        await remove(folder);
      } else {
        found.add((entry: entry, folder: folder));
      }
    }
    return found..sort((a, b) => a.entry.savedAt.compareTo(b.entry.savedAt));
  }

  Future<ShareEntry?> _read(File manifest) async {
    try {
      return ShareEntry.fromJson(jsonDecode(await manifest.readAsString()));
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Moves [staging], which may not exist yet, into the inbox with only the
  /// entry's files.
  Future<void> save(ShareEntry entry, Directory staging) async {
    await staging.create(recursive: true);
    final kept = {for (final file in entry.files) file.file};
    await for (final entity in staging.list()) {
      if (entity is File && !kept.contains(entity.uri.pathSegments.last)) {
        await entity.delete();
      }
    }
    await File(
      '${staging.path}/manifest.json',
    ).writeAsString(jsonEncode(entry.toJson()), flush: true);
    await _inbox.create(recursive: true);
    await staging.rename('${_inbox.path}/${entry.id}');
  }

  Future<void> remove(Directory folder) async {
    try {
      await folder.delete(recursive: true);
    } on FileSystemException {
      // Already gone.
    }
  }

  Future<void> removeEntriesOf(String userId) async {
    for (final (:entry, :folder) in await entries()) {
      if (entry.userId == userId) await remove(folder);
    }
  }

  Future<ShareContext> readContext() async {
    try {
      return ShareContext.fromJson(jsonDecode(await _context.readAsString()));
    } on FileSystemException {
      return const ShareContext();
    } on FormatException {
      return const ShareContext();
    }
  }

  Future<void> writeContext(ShareContext context) async {
    await root.create(recursive: true);
    final next = File('${_context.path}.next');
    await next.writeAsString(jsonEncode(context.toJson()), flush: true);
    await next.rename(_context.path);
  }
}
