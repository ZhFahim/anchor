import 'package:anchor/core/network/connectivity_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isOnlineFromResults handles connectivity states', () {
    expect(isOnlineFromResults([ConnectivityResult.wifi]), isTrue);
    expect(
      isOnlineFromResults([ConnectivityResult.mobile, ConnectivityResult.vpn]),
      isTrue,
    );
    expect(isOnlineFromResults([ConnectivityResult.none]), isFalse);
    expect(isOnlineFromResults([]), isFalse);
  });
}
