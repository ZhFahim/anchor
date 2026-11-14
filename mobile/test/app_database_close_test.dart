import 'package:anchor/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a second close while the first is running is safe', () async {
    for (var delay = 0; delay < 30; delay++) {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final subscriptions = [
        for (var i = 0; i < 5; i++)
          db
              .customSelect('SELECT $i', readsFrom: {db.notes})
              .watch()
              .listen((_) {}),
      ];
      await pumpEventQueue();

      final first = db.close();
      for (var i = 0; i < delay; i++) {
        await Future<void>.value();
      }
      await Future.wait([first, db.close()]);

      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    }
  });
}
