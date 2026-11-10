import 'dart:convert';
import 'dart:typed_data';

import 'package:anchor/core/logging/app_logger.dart';
import 'package:anchor/core/logging/logging_interceptor.dart';
import 'package:anchor/core/network/custom_headers.dart';
import 'package:anchor/core/network/dio_provider.dart';
import 'package:anchor/core/storage/preferences_repository.dart';
import 'package:anchor/core/storage/storage_keys.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeServer implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '[]',
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('header names', () {
    test('letters, numbers, and dashes are allowed', () {
      expect(isHeaderNameValid('X-Anchor-User'), isTrue);
      expect(isHeaderNameValid('X_Ander_1'), isTrue);
      expect(isHeaderNameValid(''), isFalse);
      expect(isHeaderNameValid('X Anchor'), isFalse);
      expect(isHeaderNameValid('X:Anchor'), isFalse);
      expect(isHeaderNameValid('XéAnchor'), isFalse);
    });

    test('the names the app sets itself are off limits', () {
      expect(isHeaderNameReserved('Authorization'), isTrue);
      expect(isHeaderNameReserved('content-type'), isTrue);
      expect(isHeaderNameReserved('X-Anchor-Protocol'), isTrue);
      expect(isHeaderNameReserved('X-Forwarded-User'), isFalse);
    });

    test('names repeat case-insensitively', () {
      const earlier = [CustomHeader(name: 'X-A', value: '1')];
      expect(isHeaderNameDuplicate('x-a', earlier), isTrue);
      expect(isHeaderNameDuplicate('X-B', earlier), isFalse);
    });
  });

  group('rows', () {
    test('blank rows are skipped', () {
      expect(
        validCustomHeadersOf([const CustomHeader(name: '', value: '')]),
        isEmpty,
      );
    });

    test('rows with problems are left out', () {
      final headers = validCustomHeadersOf(const [
        CustomHeader(name: 'X-Good', value: 'yes'),
        CustomHeader(name: 'bad name', value: 'no'),
        CustomHeader(name: 'Authorization', value: 'no'),
        CustomHeader(name: 'x-good', value: 'again'),
      ]);
      expect(headers, [const CustomHeader(name: 'X-Good', value: 'yes')]);
    });

    test('at most ten are kept', () {
      final headers = List.generate(
        12,
        (i) => CustomHeader(name: 'X-$i', value: '$i'),
      );
      final kept = validCustomHeadersOf(headers);
      expect(kept, hasLength(maxCustomHeaders));
      expect(kept.last, const CustomHeader(name: 'X-9', value: '9'));
    });

    test('a header with a value has to be named', () {
      expect(
        customHeaderIssueOf(0, const [CustomHeader(name: '', value: '1')]),
        CustomHeaderIssue.missingName,
      );
      expect(
        customHeaderIssueOf(0, const [CustomHeader(name: 'X-A', value: '')]),
        isNull,
      );
    });

    test('a value outside printable ASCII is never sent', () {
      const headers = [
        CustomHeader(name: 'X-Dash', value: 'a—b'),
        CustomHeader(name: 'X-Accent', value: 'café'),
        CustomHeader(name: 'X-Tab', value: 'a\tb ~'),
      ];
      expect(customHeaderIssueOf(0, headers), CustomHeaderIssue.invalidValue);
      expect(customHeaderMapOf(headers), {'X-Tab': 'a\tb ~'});
    });
  });

  test('the headers stay out of the logs', () async {
    await AppLogger.instance.clear();
    addTearDown(AppLogger.instance.clear);
    final dio =
        createServerDio(
            'https://notes.example.com',
            allowSelfSigned: false,
            customHeaders: const [
              CustomHeader(name: 'CF-Access-Client-Id', value: 'client-1'),
              CustomHeader(
                name: 'CF-Access-Client-Secret',
                value: 'secret-7f3a',
              ),
            ],
          )
          ..httpClientAdapter = _FakeServer()
          ..interceptors.add(LoggingInterceptor());

    await dio.get<Object?>('/api/notes');

    final logged = AppLogger.instance.snapshot
        .map((entry) => entry.message)
        .join('\n');
    expect(logged, contains('CF-Access-Client-Secret: ***'));
    expect(logged, isNot(contains('secret-7f3a')));
    expect(logged, isNot(contains('client-1')));
  });

  test('dio sends the custom headers along', () {
    final dio = createServerDio(
      'https://notes.example.com',
      allowSelfSigned: false,
      customHeaders: const [
        CustomHeader(name: 'X-Anchor-User', value: 'ada'),
        CustomHeader(name: 'X-Empty', value: ''),
        CustomHeader(name: 'bad name', value: 'no'),
        CustomHeader(name: 'Authorization', value: 'no'),
      ],
    );
    expect(dio.options.headers['X-Anchor-User'], 'ada');
    expect(dio.options.headers['X-Empty'], '');
    expect(dio.options.headers.containsKey('bad name'), isFalse);
    expect(dio.options.headers.containsKey('Authorization'), isFalse);
    expect(dio.options.headers['Content-Type'], 'application/json');
  });

  group('storage', () {
    PreferencesRepository repository() =>
        PreferencesRepository(FlutterSecureStorage());

    test('headers make the round trip', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final repo = repository();
      const headers = [
        CustomHeader(name: 'X-Anchor-User', value: 'ada'),
        CustomHeader(name: 'X-Empty', value: ''),
      ];
      await repo.setCustomHeaders(headers);
      expect(await repo.getCustomHeaders(), headers);
    });

    test('a broken store reads as no headers', () async {
      FlutterSecureStorage.setMockInitialValues({
        StorageKeys.customHeaders: 'not json',
      });
      expect(await repository().getCustomHeaders(), isEmpty);
    });

    test('more than ten stored are trimmed on read', () async {
      final many = List.generate(
        12,
        (i) => CustomHeader(name: 'X-$i', value: '$i'),
      );
      FlutterSecureStorage.setMockInitialValues({
        StorageKeys.customHeaders: jsonEncode([
          for (final header in many) header.toJson(),
        ]),
      });
      expect(await repository().getCustomHeaders(), hasLength(10));
    });
  });
}
