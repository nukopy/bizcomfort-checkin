import 'package:bizcomfort_checkin/page/scan/unlock_and_record.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class GeolocatorCurrentPosition implements CurrentPositionReader {
  @override
  Future<GeoFix?> read() async {
    try {
      final LocationPermission permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
        return null;
      }
      final Position position = await Geolocator.getCurrentPosition();
      return GeoFix(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }
}

class PlatformLocality implements LocalityReader {
  final Geocoding _geocoding = Geocoding();

  @override
  Future<String?> read(GeoFix fix) async {
    try {
      final List<Placemark> marks = await _geocoding.placemarkFromCoordinates(
        fix.latitude,
        fix.longitude,
        locale: const Locale('ja', 'JP'),
      );
      if (marks.isEmpty) {
        return null;
      }
      final Placemark mark = marks.first;
      final String admin = mark.administrativeArea ?? '';
      final String? locality = mark.locality;
      final String city = locality != null && locality.isNotEmpty
          ? locality
          : (mark.subAdministrativeArea ?? '');
      final String joined = '$admin$city'.trim();
      return joined.isEmpty ? null : joined;
    } catch (_) {
      return null;
    }
  }
}
