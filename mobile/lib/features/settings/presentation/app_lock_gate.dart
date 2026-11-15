import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/context_extensions.dart';
import '../../../core/theme/tokens/anchor_tokens.dart';
import '../../../core/widgets/anchor_logo.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../l10n/l10n.dart';
import 'app_lock_controller.dart';

/// Covers the app while the lock is on and the device has not authenticated the
/// person.
///
/// The covered app stays mounted underneath, so a note that was open is still
/// there after unlocking, and the cover is drawn over the screen the person
/// left.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  AppLockProblem? _problem;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _handleForeground();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cover the notes the moment the app leaves the screen, so the switch to
    // another app does not show them.
    // Covering on the way out means the switch to another app, and the
    // thumbnail the system keeps, show the cover and not the note. The gate
    // asks the device on the way back, after the grace check.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(appLockControllerProvider.notifier).lock();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _handleForeground();
    }
  }

  void _handleForeground() {
    if (!ref.read(appLockEnabledProvider)) return;
    if (!ref.read(appLockControllerProvider)) return;
    final controller = ref.read(appLockControllerProvider.notifier);
    if (controller.isWithinGrace(DateTime.now())) {
      controller.uncover();
      return;
    }
    _unlock();
  }

  Future<void> _unlock() async {
    final problem = await ref.read(appLockControllerProvider.notifier).unlock();
    if (!mounted) return;
    setState(() => _problem = problem);
  }

  @override
  Widget build(BuildContext context) {
    final isLocked =
        ref.watch(appLockEnabledProvider) &&
        ref.watch(appLockControllerProvider);
    return Stack(
      children: [
        ExcludeSemantics(
          excluding: isLocked,
          child: TickerMode(enabled: !isLocked, child: widget.child),
        ),
        if (isLocked)
          Positioned.fill(
            child: AppLockScreen(problem: _problem, onUnlock: _unlock),
          ),
      ],
    );
  }
}

/// The cover itself. The gate decides when to ask the device.
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key, required this.onUnlock, this.problem});

  final AppLockProblem? problem;
  final Future<void> Function() onUnlock;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _isAsking = false;

  Future<void> _ask() async {
    if (_isAsking) return;
    setState(() => _isAsking = true);
    await widget.onUnlock();
    if (mounted) setState(() => _isAsking = false);
  }

  String? _message(BuildContext context) => switch (widget.problem) {
    null => null,
    AppLockProblem.noCredentials => context.l10n.appLockNoCredentials,
    AppLockProblem.interrupted => context.l10n.appLockInterrupted,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.anchor;
    final l10n = context.l10n;
    final message = _message(context);
    return Scaffold(
      backgroundColor: colors.appPage,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AnchorTokens.space32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AnchorLogo(size: AnchorLogo.heading),
                const SizedBox(height: AnchorTokens.space24),
                Text(
                  l10n.appLockTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AnchorTokens.space8),
                Text(
                  message ?? l10n.appLockSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: message == null
                        ? colors.appMuted
                        : colors.statusDanger,
                  ),
                ),
                const SizedBox(height: AnchorTokens.space24),
                AppButton(
                  label: _isAsking ? l10n.appLockAsking : l10n.appLockUnlock,
                  icon: _isAsking ? null : LucideIcons.fingerprint,
                  hasShadow: true,
                  onPressed: _isAsking ? null : _ask,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
