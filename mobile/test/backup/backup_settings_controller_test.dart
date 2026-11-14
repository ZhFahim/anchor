import 'package:anchor/core/storage/preferences_repository.dart';
import 'package:anchor/features/backup/presentation/backup_settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPreferencesRepository extends Mock implements PreferencesRepository {}

void main() {
  late MockPreferencesRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockPreferencesRepository();
    when(() => repository.getBackupFolder()).thenAnswer((_) async => null);
    when(() => repository.getBackupAutomatic()).thenAnswer((_) async => true);
    when(() => repository.getBackupPeriodDays()).thenAnswer((_) async => 7);
    when(() => repository.getBackupKeepFiles()).thenAnswer((_) async => 3);
    when(() => repository.getBackupPassword()).thenAnswer((_) async => null);
    when(() => repository.getBackupLastAt()).thenAnswer((_) async => null);
    when(() => repository.setBackupFolder(any())).thenAnswer((_) async {});
    when(() => repository.setBackupPeriodDays(any())).thenAnswer((_) async {});
    when(() => repository.setBackupKeepFiles(any())).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [preferencesRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  test('the defaults are a week and three files', () async {
    final settings = await container.read(
      backupSettingsControllerProvider.future,
    );
    expect(settings.periodDays, 7);
    expect(settings.keepFiles, 3);
    expect(settings.automatic, isTrue);
    expect(settings.folderUri, isNull);
  });

  test('a picked folder keeps the name it came with', () async {
    final controller = container.read(
      backupSettingsControllerProvider.notifier,
    );
    await container.read(backupSettingsControllerProvider.future);

    await controller.setFolder(
      'content://tree/primary%3ABackups',
      name: 'Backups',
    );

    final settings = container.read(backupSettingsControllerProvider).value!;
    expect(settings.folderUri, 'content://tree/primary%3ABackups');
    expect(settings.folderDisplayName, 'Backups');
  });

  test('a period outside 1 to 31 is clamped', () async {
    final controller = container.read(
      backupSettingsControllerProvider.notifier,
    );
    await container.read(backupSettingsControllerProvider.future);

    await controller.setPeriodDays(0);
    expect(
      container.read(backupSettingsControllerProvider).value!.periodDays,
      1,
    );

    await controller.setPeriodDays(99);
    expect(
      container.read(backupSettingsControllerProvider).value!.periodDays,
      31,
    );
  });

  test('kept files outside 1 to 10 is clamped', () async {
    final controller = container.read(
      backupSettingsControllerProvider.notifier,
    );
    await container.read(backupSettingsControllerProvider.future);

    await controller.setKeepFiles(0);
    expect(
      container.read(backupSettingsControllerProvider).value!.keepFiles,
      1,
    );

    await controller.setKeepFiles(50);
    expect(
      container.read(backupSettingsControllerProvider).value!.keepFiles,
      10,
    );
  });
}
