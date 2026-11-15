import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/app_bootstrap.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/log_tags.dart';
import '../../../core/storage/preferences_repository.dart';

part 'app_lock_controller.g.dart';

/// Why the app lock could not be turned on, or could not let the person in.
enum AppLockProblem {
  /// The device has no screen lock and no enrolled biometrics.
  noCredentials,

  /// The system stopped the prompt: a lockout, or another prompt already up.
  interrupted,
}

/// The device's own authentication, behind an interface so tests can stand in
/// for it.
abstract interface class DeviceAuthenticator {
  /// True when the person proved it is them.
  Future<bool> authenticate();
}

@Riverpod(keepAlive: true)
DeviceAuthenticator deviceAuthenticator(Ref ref) =>
    LocalDeviceAuthenticator(ref.watch(localAuthenticationProvider));

@Riverpod(keepAlive: true)
LocalAuthentication localAuthentication(Ref ref) => LocalAuthentication();

class LocalDeviceAuthenticator implements DeviceAuthenticator {
  const LocalDeviceAuthenticator(this._auth);

  final LocalAuthentication _auth;

  @override
  Future<bool> authenticate() {
    return _auth.authenticate(
      localizedReason: AppLockPrompts.reason,
      // The screen lock is the fallback, so a device without biometrics works.
      biometricOnly: false,
      // The prompt survives the settings screen the person may have to open.
      persistAcrossBackgrounding: true,
    );
  }
}

/// Whether the app lock is on. The person's choice, kept on the device.
@Riverpod(keepAlive: true)
class AppLockEnabled extends _$AppLockEnabled {
  @override
  bool build() => ref.watch(appBootstrapProvider).appLockEnabled;

  Future<void> set(bool isEnabled) async {
    state = isEnabled;
    await ref.read(preferencesRepositoryProvider).setAppLockEnabled(isEnabled);
  }
}

/// How long a quick return skips the biometric prompt.
///
/// A `NotifierProvider` keeps the choice out of the code generation pipeline
/// that the rest of this file uses.
class AppLockGraceMinutes extends Notifier<int> {
  @override
  int build() => ref.watch(appBootstrapProvider).lockGraceMinutes;

  void set(int minutes) {
    state = minutes;
  }
}

final appLockGraceMinutesProvider = NotifierProvider<AppLockGraceMinutes, int>(
  AppLockGraceMinutes.new,
);

/// Whether the notes are covered right now.
///
/// Starts covered when the setting is on, so a cold start never shows a note
/// before the device authenticates the person.
@Riverpod(keepAlive: true)
class AppLockController extends _$AppLockController {
  /// True while the system prompt is up, so the pause it causes does not lock.
  bool _asking = false;

  /// The last time the device let the person in. A return inside the grace
  /// window does not ask again.
  DateTime? lastUnlockedAt;

  @override
  bool build() {
    lastUnlockedAt = ref.read(appBootstrapProvider).lastUnlockedAt;
    return ref.read(appLockEnabledProvider);
  }

  /// Covers the notes again. Does nothing while the lock is off.
  void lock() {
    if (!ref.read(appLockEnabledProvider) || _asking) return;
    state = true;
  }

  /// Clears the cover without asking the device. Used on a return inside the
  /// grace window.
  void uncover() {
    state = false;
  }

  /// True when the last unlock is inside the grace window, so a quick return
  /// does not ask the device again.
  bool isWithinGrace(DateTime now) {
    final at = lastUnlockedAt;
    final minutes = ref.read(appLockGraceMinutesProvider);
    if (at == null || minutes <= 0) return false;
    return now.difference(at) < Duration(minutes: minutes);
  }

  @visibleForTesting
  void debugMarkUnlocked(DateTime at) {
    lastUnlockedAt = at;
  }

  /// Asks the device to authenticate the person and uncovers the notes.
  ///
  /// Returns null when the person got in, or the problem when they did not.
  Future<AppLockProblem?> unlock() async {
    if (_asking) return null;
    _asking = true;
    try {
      final didAuthenticate = await ref
          .read(deviceAuthenticatorProvider)
          .authenticate();
      if (!didAuthenticate) return AppLockProblem.interrupted;
      final now = DateTime.now();
      lastUnlockedAt = now;
      state = false;
      try {
        await ref.read(preferencesRepositoryProvider).setLastUnlockedAt(now);
      } catch (error) {
        AppLogger.instance.warn(
          LogTags.auth,
          'Could not save the last unlock time: $error',
        );
      }
      return null;
    } on LocalAuthException catch (error) {
      AppLogger.instance.warn(
        LogTags.auth,
        'App lock prompt failed: ${error.code.name}',
      );
      return switch (error.code) {
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noBiometricHardware =>
          AppLockProblem.noCredentials,
        _ => AppLockProblem.interrupted,
      };
    } on PlatformException catch (error) {
      // Older Android versions answer this way on a device with no screen lock.
      AppLogger.instance.warn(
        LogTags.auth,
        'App lock prompt failed: ${error.code}',
      );
      return error.code == 'NotAvailable' || error.code == 'NotEnrolled'
          ? AppLockProblem.noCredentials
          : AppLockProblem.interrupted;
    } finally {
      _asking = false;
    }
  }

  /// Turns the lock on or off, asking the device first.
  ///
  /// Returns null when it changed, or the problem when it did not.
  Future<AppLockProblem?> setEnabled(bool isEnabled) async {
    if (isEnabled) {
      final problem = await unlock();
      if (problem != null) return problem;
    }
    await ref.read(appLockEnabledProvider.notifier).set(isEnabled);
    state = false;
    return null;
  }
}

/// The words the cover and the system prompt show, so both say the same thing.
abstract final class AppLockPrompts {
  static const reason = 'Unlock Anchor to read your notes';
}
