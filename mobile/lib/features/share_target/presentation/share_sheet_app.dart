import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/theme/system_bars.dart';
import '../../../core/widgets/anchor_sheet.dart';
import '../../../l10n/l10n.dart';
import '../data/share_inbox.dart';
import '../data/share_sheet_channel.dart';
import '../domain/share_context.dart';
import '../domain/share_entry.dart';
import 'share_sheet.dart';

/// Never opens the notes database; the app imports what the sheet saves.
Future<void> runShareSheet() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  final channel = ShareSheetChannel();
  final inbox = await ShareInbox.find();
  final shareContext = await inbox?.readContext() ?? const ShareContext();
  final intake = await channel.load();
  runApp(
    ShareSheetApp(
      channel: channel,
      inbox: inbox,
      shareContext: shareContext,
      intake: intake,
    ),
  );
}

class ShareSheetApp extends StatelessWidget {
  const ShareSheetApp({
    super.key,
    required this.channel,
    required this.inbox,
    required this.shareContext,
    required this.intake,
  });

  final ShareSheetChannel channel;
  final ShareInbox? inbox;
  final ShareContext shareContext;
  final SharedIntake intake;

  @override
  Widget build(BuildContext context) {
    final density = shareContext.density;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.l10n.appName,
      color: Colors.transparent,
      theme: AppTheme.light(density),
      darkTheme: AppTheme.dark(density),
      themeMode: shareContext.themeMode,
      themeAnimationStyle: AnimationStyle.noAnimation,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        // The status bar sits over the app that shared.
        final behind = systemBarsStyle(
          dark: MediaQuery.platformBrightnessOf(context) == Brightness.dark,
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: context.systemBars.copyWith(
            statusBarBrightness: behind.statusBarBrightness,
            statusBarIconBrightness: behind.statusBarIconBrightness,
          ),
          child: child!,
        );
      },
      home: _SheetHost(app: this),
    );
  }
}

class _SheetHost extends StatefulWidget {
  const _SheetHost({required this.app});

  final ShareSheetApp app;

  @override
  State<_SheetHost> createState() => _SheetHostState();
}

class _SheetHostState extends State<_SheetHost> {
  ShareSheetApp get _app => widget.app;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    final gone = Completer<void>();
    final isSaved = await showAnchorSheet<bool>(
      context,
      semanticLabel: context.l10n.shareSheetTitle,
      onGone: gone.complete,
      builder: (_) => ShareSheet(
        intake: _app.intake,
        shareContext: _app.shareContext,
        onSave: _save,
        onOpenApp: _app.channel.openApp,
      ),
    );
    await gone.future;
    await _app.channel.close(saved: isSaved ?? false);
  }

  Future<void> _save(ShareDraft draft) async {
    final inbox = _app.inbox;
    final userId = _app.shareContext.userId;
    if (inbox == null || userId == null) return;
    await inbox.save(
      ShareEntry(
        id: _app.intake.id,
        userId: userId,
        savedAt: DateTime.now(),
        title: draft.title,
        text: draft.text,
        link: draft.link,
        tagIds: draft.tagIds,
        files: [
          for (final file in draft.files)
            if (file.file case final staged?)
              ShareFile(file: staged, name: file.name, mime: file.mime ?? ''),
        ],
      ),
      Directory(_app.intake.staging),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
