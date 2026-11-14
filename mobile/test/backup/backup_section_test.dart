import 'package:anchor/core/widgets/grouped_list.dart';
import 'package:anchor/features/backup/domain/backup_settings.dart';
import 'package:anchor/features/backup/presentation/backup_controller.dart';
import 'package:anchor/features/backup/presentation/backup_section.dart';
import 'package:anchor/features/backup/presentation/backup_settings_controller.dart';
import 'package:anchor/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FakeSettings extends BackupSettingsController {
  FakeSettings(this.initial);

  final BackupSettings initial;

  @override
  Future<BackupSettings> build() async => initial;
}

class FakeBackup extends BackupController {
  @override
  bool build() => false;
}

void main() {
  Future<void> pump(WidgetTester tester, BackupSettings settings) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          backupSettingsControllerProvider.overrideWith(
            () => FakeSettings(settings),
          ),
          backupControllerProvider.overrideWith(FakeBackup.new),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: BackupSection()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('with no folder it asks for one', (tester) async {
    await pump(tester, const BackupSettings());
    expect(find.text('Choose a folder'), findsOneWidget);
  });

  testWidgets('the folder row uses the shared tile and a chevron', (tester) async {
    await pump(
      tester,
      const BackupSettings(
        folderUri: 'content://tree/backups',
        folderName: 'Backups',
      ),
    );
    expect(find.byType(GroupedListTile), findsWidgets);
    expect(find.byIcon(LucideIcons.chevronRight), findsWidgets);
  });

  testWidgets('with a folder it offers a backup now', (tester) async {
    await pump(
      tester,
      const BackupSettings(
        folderUri: 'content://tree/backups',
        folderName: 'Backups',
      ),
    );
    expect(find.text('Backups'), findsOneWidget);
    expect(find.text('Back up now'), findsOneWidget);
    expect(find.text('Choose a folder'), findsNothing);
  });
}
