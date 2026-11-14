import 'package:anchor/features/backup/data/backup_folder.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('anchor/backup');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'pickFolder' => {'uri': 'content://tree/backups', 'name': 'Backups'},
            'listFiles' => ['anchor-auto-1.zip', 'anchor-auto-2.zip'],
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('pick returns the folder and its name', () async {
    final choice = await BackupFolder().pick();
    expect(choice?.uri, 'content://tree/backups');
    expect(choice?.name, 'Backups');
  });

  test('write sends the name and the bytes', () async {
    await BackupFolder().write('content://tree/backups', 'a.zip', [1, 2]);
    expect(calls.single.method, 'writeFile');
    expect(calls.single.arguments['name'], 'a.zip');
    expect(calls.single.arguments['bytes'], isA<Uint8List>());
    expect(calls.single.arguments['bytes'], [1, 2]);
  });

  test('list returns the file names', () async {
    expect(await BackupFolder().list('content://tree/backups'), [
      'anchor-auto-1.zip',
      'anchor-auto-2.zip',
    ]);
  });

  test('delete sends the name', () async {
    await BackupFolder().delete('content://tree/backups', 'a.zip');
    expect(calls.single.method, 'deleteFile');
    expect(calls.single.arguments['name'], 'a.zip');
  });
}
