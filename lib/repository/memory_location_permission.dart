import 'package:bizcomfort_checkin/usecase/watch_location_permission.dart';

class MemoryLocationPermission implements LocationPermissionGateway {
  MemoryLocationPermission({this.access = LocationAccess.needsRequest});

  LocationAccess access;

  @override
  Future<LocationAccess> read() async => access;

  @override
  Future<LocationAccess> request() async {
    access = LocationAccess.granted;
    return access;
  }

  @override
  Future<void> openSettings() async {}
}
