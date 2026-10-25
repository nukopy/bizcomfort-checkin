import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/domain/unlock_record.dart';
import 'package:bizcomfort_checkin/page/scan/scan_page.dart';
import 'package:bizcomfort_checkin/repository/memory_credential_repository.dart';
import 'package:bizcomfort_checkin/repository/memory_location_permission.dart';
import 'package:bizcomfort_checkin/repository/memory_unlock_log_repository.dart';
import 'package:bizcomfort_checkin/usecase/load_credentials.dart';
import 'package:bizcomfort_checkin/usecase/save_credentials.dart';
import 'package:bizcomfort_checkin/usecase/watch_location_permission.dart';
import 'package:bizcomfort_checkin/usecase/watch_unlock_log.dart';

class AppWire {
  AppWire({
    required CredentialRepository credentials,
    required UnlockLogRepository unlockLog,
    required LocationPermissionGateway locationPermission,
    required this.scanSource,
  }) : loadCredentials = LoadCredentials(credentials),
       saveCredentials = SaveCredentials(credentials),
       watchUnlockLog = WatchUnlockLog(unlockLog),
       watchLocationPermission = WatchLocationPermission(locationPermission);

  factory AppWire.memory() => AppWire(
    credentials: MemoryCredentialRepository(),
    unlockLog: MemoryUnlockLogRepository(),
    locationPermission: MemoryLocationPermission(),
    scanSource: ListQrScanSource(const <String>[]),
  );

  final LoadCredentials loadCredentials;
  final SaveCredentials saveCredentials;
  final WatchUnlockLog watchUnlockLog;
  final WatchLocationPermission watchLocationPermission;
  final QrScanSource scanSource;
}
