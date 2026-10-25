enum LocationAccess { granted, needsRequest, blocked }

abstract class LocationPermissionGateway {
  Future<LocationAccess> read();

  Future<LocationAccess> request();

  Future<void> openSettings();
}

class WatchLocationPermission {
  const WatchLocationPermission(this._gateway);

  final LocationPermissionGateway _gateway;

  Future<LocationAccess> read() => _gateway.read();

  Future<LocationAccess> request() => _gateway.request();

  Future<void> openSettings() => _gateway.openSettings();
}
