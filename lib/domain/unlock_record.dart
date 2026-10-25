import 'package:flutter/foundation.dart';

enum DoorDirection { enter, exit }

enum UnlockStatus {
  success,
  failed;

  String get label => switch (this) {
    UnlockStatus.success => 'SUCCESS',
    UnlockStatus.failed => 'FAILED',
  };

  static UnlockStatus fromLabel(String label) {
    return UnlockStatus.values.firstWhere((UnlockStatus status) => status.label == label);
  }
}

class UnlockRecord {
  const UnlockRecord({
    required this.url,
    required this.at,
    required this.latitude,
    required this.longitude,
    required this.locality,
    required this.status,
    this.siteName = '',
    this.doorName = '',
    this.errorMessage,
    this.shotBytes,
    this.shotName,
  });

  final Uri url;
  final DateTime at;
  final double? latitude;
  final double? longitude;
  final String locality;
  final UnlockStatus status;
  final String siteName;
  final String doorName;
  final String? errorMessage;
  final Uint8List? shotBytes;
  final String? shotName;

  DoorDirection get direction {
    final List<String> segments = url.pathSegments.where((String s) => s.isNotEmpty).toList();
    if (segments.length >= 2 && segments[1] == 'exit') {
      return DoorDirection.exit;
    }
    return DoorDirection.enter;
  }
}

abstract class UnlockLogRepository extends ChangeNotifier {
  List<UnlockRecord> get records;

  void add(UnlockRecord record);

  UnlockShot shotFor(UnlockRecord record, {required DateTime now});
}

enum UnlockShotState { image, expired, missing }

class UnlockShot {
  const UnlockShot.expired() : state = UnlockShotState.expired, bytes = null;

  const UnlockShot.missing() : state = UnlockShotState.missing, bytes = null;

  UnlockShot.image(this.bytes) : state = UnlockShotState.image;

  final UnlockShotState state;
  final Uint8List? bytes;
}

bool shotRetained(DateTime at, DateTime now) {
  return now.difference(at) < const Duration(days: 31);
}

String formatMonthHeading(DateTime month) {
  final DateTime local = month.toLocal();
  return '${local.year} 年 ${local.month} 月';
}

String formatUnlockRowDate(DateTime at) {
  final DateTime local = at.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.month}月${local.day}日 ${two(local.hour)}:${two(local.minute)}';
}

String formatGps(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) {
    return '';
  }
  return '${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}';
}
