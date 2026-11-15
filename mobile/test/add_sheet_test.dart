import 'dart:io';

import 'package:anchor/core/theme/app_theme.dart';
import 'package:anchor/features/notes/data/image_compressor.dart';
import 'package:anchor/features/notes/domain/note_attachment.dart';
import 'package:anchor/features/notes/presentation/widgets/add_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

class _FakeRecorder extends Fake implements RecordPlatform {
  RecordConfig? config;
  String? path;
  bool isOn = false;

  @override
  Future<void> create(String recorderId) async {}

  @override
  Future<bool> hasPermission(String recorderId, {bool request = true}) async =>
      true;

  @override
  Future<void> start(
    String recorderId,
    RecordConfig config, {
    required String path,
  }) async {
    this.config = config;
    this.path = path;
    isOn = true;
    File(path).writeAsBytesSync([0]);
  }

  @override
  Future<String?> stop(String recorderId) async {
    isOn = false;
    return path;
  }

  @override
  Future<bool> isRecording(String recorderId) async => isOn;

  @override
  Future<Amplitude> getAmplitude(String recorderId) async =>
      Amplitude(current: -30, max: 0);

  @override
  Stream<RecordState> onStateChanged(String recorderId) => const Stream.empty();

  @override
  Future<void> dispose(String recorderId) async {}
}

class _FakeCompressor implements ImageCompressor {
  @override
  Future<CompressedImage> compress(SourceImage image) async =>
      CompressedImage(
        path: image.path,
        mime: image.mime,
        originalSize: 1024,
        compressedSize: 512,
      );
}

void main() {
  Future<void> waitFor(WidgetTester tester, bool Function() isDone) async {
    for (var i = 0; i < 40 && !isDone(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('a long recording stops at the size limit and is kept', (
    tester,
  ) async {
    final recorder = _FakeRecorder();
    final platform = RecordPlatform.instance;
    RecordPlatform.instance = recorder;
    addTearDown(() => RecordPlatform.instance = platform);
    final temp = Directory.systemTemp.createTempSync('anchor-record');
    addTearDown(() => temp.deleteSync(recursive: true));
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => temp.path,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.just_audio.methods'),
      (_) async => <String, Object?>{},
    );
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    AddedFile? added;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          imageCompressorProvider.overrideWithValue(_FakeCompressor()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => added = await showAddSheet(context),
              child: const Text('Add'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Record audio'));
    await waitFor(tester, () => recorder.isOn);
    expect(recorder.config!.bitRate, 96000);
    expect(recorder.config!.numChannels, 1);

    File(recorder.path!).openSync(mode: FileMode.write)
      ..setPositionSync(maxAttachmentBytes - 1024 * 1024)
      ..writeByteSync(0)
      ..closeSync();
    await waitFor(tester, () => added != null);

    expect(recorder.isOn, isFalse);
    expect(added!.path, recorder.path);
    expect(File(added!.path).existsSync(), isTrue);
  });
}