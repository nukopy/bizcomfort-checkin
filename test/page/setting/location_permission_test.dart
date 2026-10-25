import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/page/setting/setting_page.dart';
import 'package:bizcomfort_checkin/usecase/load_credentials.dart';
import 'package:bizcomfort_checkin/usecase/save_credentials.dart';
import 'package:bizcomfort_checkin/usecase/watch_location_permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('未許可なら許可を求め、許可になる', (WidgetTester tester) async {
    final _FakeLocationPermission gateway = _FakeLocationPermission(LocationAccess.needsRequest);
    await tester.pumpWidget(
      MaterialApp(
        home: SettingPage(
          loadCredentials: LoadCredentials(_UnusedCredentials()),
          saveCredentials: SaveCredentials(_UnusedCredentials()),
          watchLocationPermission: WatchLocationPermission(gateway),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('アクセス許可'), findsOneWidget);
    expect(find.text('位置情報'), findsOneWidget);
    expect(find.text('未許可'), findsOneWidget);

    await tester.tap(find.text('許可する'));
    await tester.pumpAndSettle();

    expect(gateway.requests, 1);
    expect(find.text('許可'), findsOneWidget);
  });

  testWidgets('OS が拒否しているときは設定を開く', (WidgetTester tester) async {
    final _FakeLocationPermission gateway = _FakeLocationPermission(LocationAccess.blocked);
    await tester.pumpWidget(
      MaterialApp(
        home: SettingPage(
          loadCredentials: LoadCredentials(_UnusedCredentials()),
          saveCredentials: SaveCredentials(_UnusedCredentials()),
          watchLocationPermission: WatchLocationPermission(gateway),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('設定を開く'));
    await tester.pumpAndSettle();

    expect(gateway.opened, 1);
    expect(find.text('許可する'), findsNothing);
  });
}

class _FakeLocationPermission implements LocationPermissionGateway {
  _FakeLocationPermission(this.access);

  LocationAccess access;
  int requests = 0;
  int opened = 0;

  @override
  Future<LocationAccess> read() async => access;

  @override
  Future<LocationAccess> request() async {
    requests += 1;
    access = LocationAccess.granted;
    return access;
  }

  @override
  Future<void> openSettings() async {
    opened += 1;
  }
}

class _UnusedCredentials implements CredentialRepository {
  @override
  Future<Credentials?> read() async => null;

  @override
  Future<void> write(Credentials credentials) async {}
}
