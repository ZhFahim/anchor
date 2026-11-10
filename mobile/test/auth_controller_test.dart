import 'dart:convert';

import 'package:anchor/core/network/custom_headers.dart';
import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/core/session/active_user_id_provider.dart';
import 'package:anchor/features/auth/data/remote/auth_service.dart';
import 'package:anchor/features/auth/domain/auth_failure.dart';
import 'package:anchor/features/auth/presentation/auth_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _ada = {
  'id': 'user-1',
  'email': 'ada@example.com',
  'name': 'Ada',
  'profileImage': '/profiles/ada.jpg',
};

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.isReviewing = false}) : super(Dio());

  final bool isReviewing;
  int profileReads = 0;

  @override
  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
  ) async => isReviewing
      ? {'user': _ada, 'message': 'Your account is pending approval.'}
      : {'access_token': 'access', 'refresh_token': 'refresh', 'user': _ada};

  @override
  Future<Map<String, dynamic>> login(String email, String password) async =>
      throw const InvalidCredentialsFailure();

  @override
  Future<Map<String, dynamic>> getProfile() async {
    profileReads++;
    return {..._ada, 'hasPassword': true};
  }

  @override
  Future<Map<String, dynamic>> removeProfileImage() async => {
    ..._ada,
    'profileImage': null,
  };
}

class _FixedServerConfig extends ServerConfig {
  @override
  Future<String?> build() async => 'https://anchor.example.com';
}

class _NoSelfSignedCert extends AllowSelfSignedCert {
  @override
  Future<bool> build() async => false;
}

class _NoCustomHeaders extends CustomHeaders {
  @override
  Future<List<CustomHeader>> build() async => const [];
}

ProviderContainer _container(_FakeAuthService service) {
  final container = ProviderContainer(
    overrides: [
      authServiceProvider.overrideWithValue(service),
      serverConfigProvider.overrideWith(_FixedServerConfig.new),
      allowSelfSignedCertProvider.overrideWith(_NoSelfSignedCert.new),
      customHeadersProvider.overrideWith(_NoCustomHeaders.new),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('signed out', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('signing up on an open server signs in', () async {
      final container = _container(_FakeAuthService());
      expect(await container.read(authControllerProvider.future), isNull);

      final isSignedIn = await container
          .read(authControllerProvider.notifier)
          .register('ada@example.com', 'long enough', 'Ada');

      expect(isSignedIn, isTrue);
      expect(container.read(authControllerProvider).value?.id, 'user-1');
      expect(container.read(activeUserIdProvider), 'user-1');
    });

    test('signing up for review stays signed out', () async {
      final container = _container(_FakeAuthService(isReviewing: true));
      await container.read(authControllerProvider.future);

      final isSignedIn = await container
          .read(authControllerProvider.notifier)
          .register('ada@example.com', 'long enough', 'Ada');

      expect(isSignedIn, isFalse);
      expect(container.read(authControllerProvider).value, isNull);
      expect(container.read(activeUserIdProvider), isNull);
    });

    test('a wrong password leaves the app’s sign-in state alone', () async {
      final container = _container(_FakeAuthService());
      await container.read(authControllerProvider.future);

      await expectLater(
        container
            .read(authControllerProvider.notifier)
            .login('ada@example.com', 'wrong'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
      final state = container.read(authControllerProvider);
      expect(state.hasError, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.value, isNull);
    });
  });

  test('removing the photo shows at once, without loading again', () async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'access',
      'refresh_token': 'refresh',
      'user_data': jsonEncode(_ada),
    });
    final service = _FakeAuthService();
    final container = _container(service);
    final user = await container.read(authControllerProvider.future);
    expect(user?.profileImage, '/profiles/ada.jpg');
    // The background refresh after starting from the stored profile.
    await pumpEventQueue();
    final reads = service.profileReads;

    final auth = container.read(authControllerProvider.notifier);
    await auth.removePhoto();

    final state = container.read(authControllerProvider);
    expect(state.value?.profileImage, isNull);
    expect(state.value?.hasPassword, isTrue);
    expect(service.profileReads, reads);
  });
}
