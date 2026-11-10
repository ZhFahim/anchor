import 'dart:convert';

import 'package:anchor/core/logging/redaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('logged bodies keep no note text, names or passwords', () {
    final body = redactBody({
      'changes': [
        {
          'id': 'n1',
          'title': 'Dentist',
          'content': '{"ops":[{"insert":"Call at 9\\n"}]}',
          'tags': [
            {'id': 't1', 'name': 'health', 'color': '#4FC3F7'},
          ],
          'user': {'name': 'Mia', 'email': 'mia@example.com'},
        },
      ],
      'password': 'secret-1',
      'nextCursor': 'abc',
    });

    final logged = jsonDecode(body) as Map<String, dynamic>;
    final change = (logged['changes'] as List).single as Map<String, dynamic>;
    expect(change['id'], 'n1');
    expect(change['title'], '***');
    expect(change['content'], '***');
    expect((change['tags'] as List).single, {
      'id': 't1',
      'name': '***',
      'color': '#4FC3F7',
    });
    expect(change['user'], {'name': '***', 'email': '***'});
    expect(logged['password'], '***');
    expect(logged['nextCursor'], 'abc');
    for (final text in ['Dentist', 'Call at 9', 'health', 'Mia', 'secret-1']) {
      expect(body, isNot(contains(text)));
    }
  });

  test('a proxy’s headers are logged by name only', () {
    final headers = redactHeaders({
      'X-Anchor-Protocol': '4',
      'Authorization': 'Bearer abc.def',
      'CF-Access-Client-Id': 'client-1.access',
      'CF-Access-Client-Secret': 'secret-7f3a',
    });

    expect(headers, {
      'X-Anchor-Protocol': '4',
      'Authorization': 'Bearer ***',
      'CF-Access-Client-Id': '***',
      'CF-Access-Client-Secret': '***',
    });
  });

  test('a people search keeps its words out of the logs', () {
    final query = redactQuery(Uri.parse('/api/users/search?q=maya&limit=5'));

    expect(query, 'q=***&limit=5');
  });
}
