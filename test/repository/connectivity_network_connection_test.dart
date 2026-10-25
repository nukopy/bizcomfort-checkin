import 'package:bizcomfort_checkin/repository/connectivity_network_connection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('通信できる接続だけをオンラインにする', () {
    expect(hasNetworkConnection(const <ConnectivityResult>[]), isFalse);
    expect(hasNetworkConnection(const <ConnectivityResult>[ConnectivityResult.none]), isFalse);
    expect(hasNetworkConnection(const <ConnectivityResult>[ConnectivityResult.bluetooth]), isFalse);
    expect(hasNetworkConnection(const <ConnectivityResult>[ConnectivityResult.wifi]), isTrue);
    expect(hasNetworkConnection(const <ConnectivityResult>[ConnectivityResult.mobile]), isTrue);
    expect(
      hasNetworkConnection(const <ConnectivityResult>[
        ConnectivityResult.none,
        ConnectivityResult.wifi,
      ]),
      isTrue,
    );
  });
}
