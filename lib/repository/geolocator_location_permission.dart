import 'package:bizcomfort_checkin/usecase/watch_location_permission.dart';
import 'package:geolocator/geolocator.dart';

class GeolocatorLocationPermission implements LocationPermissionGateway {
  @override
  Future<LocationAccess> read() async {
    return _map(await Geolocator.checkPermission());
  }

  @override
  Future<LocationAccess> request() async {
    return _map(await Geolocator.requestPermission());
  }

  @override
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }

  LocationAccess _map(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.always || LocationPermission.whileInUse => LocationAccess.granted,
      LocationPermission.deniedForever => LocationAccess.blocked,
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => LocationAccess.needsRequest,
    };
  }
}
