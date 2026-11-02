import 'package:anchor/features/auth/domain/magic_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MagicLink.parse', () {
    test('reads the web page link, whose server is the one it is on', () {
      expect(
        MagicLink.parse('https://notes.example.com/magic-login?code=a-b_c'),
        const MagicLink(serverUrl: 'https://notes.example.com', code: 'a-b_c'),
      );
      expect(
        MagicLink.parse('http://192.168.1.5:3000/magic-login?code=xyz'),
        const MagicLink(serverUrl: 'http://192.168.1.5:3000', code: 'xyz'),
      );
    });

    test('reads the link the web page hands the app', () {
      expect(
        MagicLink.parse(
          'anchorplus://magic-login?server=https%3A%2F%2Fnotes.example.com%3A8443&code=abc',
        ),
        const MagicLink(
          serverUrl: 'https://notes.example.com:8443',
          code: 'abc',
        ),
      );
    });

    test('turns down anything else', () {
      for (final text in [
        '',
        'hello',
        'https://notes.example.com/magic-login',
        'https://notes.example.com/login?code=abc',
        'anchorplus://magic-login?code=abc',
        'anchorplus://other?server=https%3A%2F%2Fa.com&code=abc',
        'anchorplus://magic-login?server=javascript%3Aalert(1)&code=abc',
        'ftp://notes.example.com/magic-login?code=abc',
      ]) {
        expect(MagicLink.parse(text), isNull, reason: text);
      }
    });
  });
}
