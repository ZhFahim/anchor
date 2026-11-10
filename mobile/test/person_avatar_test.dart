import 'package:anchor/core/network/custom_headers.dart';
import 'package:anchor/core/network/server_config_provider.dart';
import 'package:anchor/core/widgets/person_avatar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ProxyHeaders extends CustomHeaders {
  @override
  Future<List<CustomHeader>> build() async => const [
    CustomHeader(name: 'CF-Access-Client-Secret', value: 'secret-7f3a'),
  ];
}

void main() {
  Future<Map<String, String>?> headersSentFor(
    WidgetTester tester,
    String imageUrl,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          serverUrlProvider.overrideWithValue('https://notes.example.com'),
          customHeadersProvider.overrideWith(_ProxyHeaders.new),
        ],
        child: MaterialApp(
          home: PersonAvatar(name: 'Ada Lovelace', imageUrl: imageUrl),
        ),
      ),
    );
    await tester.pump();
    return tester
        .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
        .httpHeaders;
  }

  testWidgets('a picture on the server gets the server’s headers', (
    tester,
  ) async {
    expect(await headersSentFor(tester, '/uploads/profiles/ada.png'), {
      'CF-Access-Client-Secret': 'secret-7f3a',
    });
  });

  testWidgets('a sign-in provider’s picture never does', (tester) async {
    expect(
      await headersSentFor(tester, 'https://id.example.com/picture/ada'),
      isNull,
    );
  });
}
