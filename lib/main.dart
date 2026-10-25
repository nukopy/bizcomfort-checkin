import 'dart:io';

import 'package:bizcomfort_checkin/components/checkin_tabs.dart';
import 'package:bizcomfort_checkin/components/offline_gate.dart';
import 'package:bizcomfort_checkin/domain/network_connection.dart';
import 'package:bizcomfort_checkin/page/scan/mobile_scanner_qr_source.dart';
import 'package:bizcomfort_checkin/page/scan/unlock_and_record.dart';
import 'package:bizcomfort_checkin/page/scan/unlock_trace.dart';
import 'package:bizcomfort_checkin/page/scan/unlock_webview.dart';
import 'package:bizcomfort_checkin/repository/connectivity_network_connection.dart';
import 'package:bizcomfort_checkin/repository/device_location.dart';
import 'package:bizcomfort_checkin/repository/file_unlock_log_repository.dart';
import 'package:bizcomfort_checkin/repository/geolocator_location_permission.dart';
import 'package:bizcomfort_checkin/repository/secure_credential_repository.dart';
import 'package:bizcomfort_checkin/wire/app_wire.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Directory directory = await getApplicationSupportDirectory();
  final SecureCredentialRepository credentials = SecureCredentialRepository(
    FlutterSecureKeyValue(const FlutterSecureStorage()),
  );
  final FileUnlockLogRepository unlockLog = FileUnlockLogRepository(
    File('${directory.path}/unlock-log.json'),
  );
  final GeolocatorLocationPermission locationPermission = GeolocatorLocationPermission();
  final UnlockTrace trace = UnlockTrace();
  final UnlockWebHost web = UnlockWebHost(locationPermission, trace);
  runApp(
    MyApp(
      connection: ConnectivityNetworkConnection(),
      wire: AppWire(
        credentials: credentials,
        unlockLog: unlockLog,
        locationPermission: locationPermission,
        scanSource: MobileScannerQrSource(),
        hiddenWebView: web.buildView(),
        unlockAndRecord: UnlockAndRecord(
          credentials: credentials,
          log: unlockLog,
          runner: WebLoginRunner(web, trace),
          form: web,
          session: web,
          readPage: web.readSettledPage,
          captureShot: web.captureShot,
          trace: trace,
          position: GeolocatorCurrentPosition(),
          locality: PlatformLocality(),
          now: DateTime.now,
        ),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.wire, this.connection});

  final AppWire? wire;
  final NetworkConnection? connection;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppWire _wire = widget.wire ?? AppWire.memory();

  @override
  Widget build(BuildContext context) {
    final NetworkConnection? connection = widget.connection;
    return MaterialApp(
      title: 'BIZcomfort Checkin',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      builder: connection == null
          ? null
          : (BuildContext context, Widget? child) {
              return OfflineGate(connection: connection, child: child ?? const SizedBox.shrink());
            },
      home: CheckinTabs(
        loadCredentials: _wire.loadCredentials,
        saveCredentials: _wire.saveCredentials,
        watchUnlockLog: _wire.watchUnlockLog,
        watchLocationPermission: _wire.watchLocationPermission,
        unlockAndRecord: _wire.unlockAndRecord,
        hiddenWebView: _wire.hiddenWebView,
        scanSource: _wire.scanSource,
        onUnlockUrl: (_) {},
      ),
    );
  }
}
