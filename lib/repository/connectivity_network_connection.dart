import 'package:bizcomfort_checkin/domain/network_connection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

bool hasNetworkConnection(List<ConnectivityResult> results) {
  return results.any(
    (ConnectivityResult result) =>
        result != ConnectivityResult.none && result != ConnectivityResult.bluetooth,
  );
}

class ConnectivityNetworkConnection implements NetworkConnection {
  ConnectivityNetworkConnection({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<bool> get online async* {
    yield hasNetworkConnection(await _connectivity.checkConnectivity());
    yield* _connectivity.onConnectivityChanged.map(hasNetworkConnection);
  }
}
