import 'dart:io';

import 'package:anchor/core/logging/app_logger.dart';
import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/features/notes/presentation/widgets/notes_bottom_bar.dart';
import 'package:anchor/features/settings/presentation/log_viewer_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    await AppLogger.instance.clear();
    // Short lines first: the list's first guess at its length is too small.
    for (var i = 0; i < 60; i++) {
      AppLogger.instance.debug('Test', 'line $i');
    }
    for (var i = 60; i < 90; i++) {
      AppLogger.instance.debug('Test', 'line $i ${'and more words ' * 12}');
    }
  });

  tearDown(() => AppLogger.instance.clear());

  testWidgets('opens with the newest line 16 above the dock', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const LogViewerScreen()),
    );
    await tester.pumpAndSettle();

    final newest = tester.getRect(
      find.bySemanticsLabel(RegExp(r'Test\. line 89 ')),
    );
    final bottomBar = tester.getRect(find.byType(NotesBottomBar));
    expect(bottomBar.top - newest.bottom, moreOrLessEquals(16, epsilon: 0.5));
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const LogViewerScreen()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> waitFor(WidgetTester tester, bool Function() isDone) async {
    for (var i = 0; i < 100 && !isDone(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
  }

  Future<void> choose(WidgetTester tester, String item) async {
    await tester.tap(find.bySemanticsLabel('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  testWidgets('Copy all copies only the newest logs when they are too long', (
    tester,
  ) async {
    final logs = await tester.runAsync(() async {
      await AppLogger.instance.clear();
      for (var i = 0; i < 1000; i++) {
        AppLogger.instance.debug('Test', 'line $i ${'x' * 240}');
      }
      return AppLogger.instance.dumpAll();
    });
    await open(tester);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );

    await choose(tester, 'Copy all');
    final newest = find.text(
      'Newest logs copied. Save to a file to get them all.',
    );
    await waitFor(tester, () => newest.evaluate().isNotEmpty);

    expect(logs!.length, greaterThan(200000));
    expect(copied!.length, lessThanOrEqualTo(200000));
    expect(logs, endsWith(copied!));
    expect(logs.split('\n'), contains(copied!.split('\n').first));
    expect(newest, findsOneWidget);
  });

  testWidgets('Save to a file shares the logs on a phone with no save screen', (
    tester,
  ) async {
    final picker = FilePickerPlatform.instance;
    FilePickerPlatform.instance = _NoSaveScreen();
    addTearDown(() => FilePickerPlatform.instance = picker);
    final temp = Directory.systemTemp.createTempSync('anchor-logs');
    addTearDown(() => temp.deleteSync(recursive: true));
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => temp.path,
    );
    List<Object?>? shared;
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        shared = (call.arguments as Map)['paths'] as List<Object?>;
        return null;
      },
    );

    await open(tester);
    await choose(tester, 'Save to a file');
    await waitFor(tester, () => shared != null);

    expect(
      File(shared!.single! as String).readAsStringSync(),
      contains('line 89'),
    );
    expect(find.text('Couldn’t save the logs'), findsNothing);
  });
}

class _NoSaveScreen extends FilePickerPlatform {
  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) => throw PlatformException(code: 'explorer_not_found');
}
