import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../app_initializer.dart';

part 'active_user_id_provider.g.dart';

@Riverpod(keepAlive: true)
class ActiveUserId extends _$ActiveUserId {
  @override
  String? build() => initialUserId;

  void set(String? id) => state = id;
}
