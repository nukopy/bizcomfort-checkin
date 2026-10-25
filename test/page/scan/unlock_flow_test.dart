import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/domain/unlock_record.dart';
import 'package:bizcomfort_checkin/page/scan/login_runner.dart';
import 'package:bizcomfort_checkin/page/scan/scan_page.dart';
import 'package:bizcomfort_checkin/page/scan/unlock_and_record.dart';
import 'package:bizcomfort_checkin/repository/memory_credential_repository.dart';
import 'package:bizcomfort_checkin/repository/memory_location_permission.dart';
import 'package:bizcomfort_checkin/repository/memory_unlock_log_repository.dart';
import 'package:bizcomfort_checkin/usecase/load_credentials.dart';
import 'package:bizcomfort_checkin/usecase/save_credentials.dart';
import 'package:bizcomfort_checkin/usecase/watch_location_permission.dart';
import 'package:bizcomfort_checkin/usecase/watch_unlock_log.dart';
import 'package:bizcomfort_checkin/components/checkin_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String entry = 'https://mypage.bizcomfort.jp/unlock/entry/a0KRB000018nb3q2AA/';

  testWidgets('確定後に成功を1件残す', (WidgetTester tester) async {
    final MemoryCredentialRepository credentials = MemoryCredentialRepository();
    await credentials.write(const Credentials(email: 'member@example.com', password: 'secret'));
    final MemoryUnlockLogRepository log = MemoryUnlockLogRepository();
    final _ScriptedSession session = _ScriptedSession(
      hasSession: false,
      html: '<p>拠点</p><p>ドア</p>',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: _tabs(
          credentials: credentials,
          log: log,
          source: ListQrScanSource([entry]),
          session: session,
        ),
      ),
    );
    await tester.pump();
    expect(log.records, isEmpty);
    expect(find.text('ログイン'), findsOneWidget);
    expect(find.text('キャンセル'), findsOneWidget);
    expect(find.text('QRコードの読み取りができました'), findsOneWidget);
    expect(find.text(entry), findsOneWidget);
    expect(find.text('QRコードをかざす'), findsNothing);
    expect(find.byKey(const Key('qr-scanner')), findsNothing);
    final double loginX = tester.getCenter(find.text('ログイン')).dx;
    await tester.pump();
    expect(tester.getCenter(find.text('ログイン')).dx, loginX);
    expect(loginX, greaterThan(tester.getSize(find.byType(Scaffold)).width * 0.4));

    await tester.tap(find.text('ログイン'));
    await tester.pumpAndSettle();

    expect(log.records, hasLength(1));
    expect(log.records.single.status, UnlockStatus.success);
    expect(find.text('解錠に成功しました'), findsOneWidget);
    expect(find.byKey(const Key('qr-scanner')), findsNothing);
    expect(find.text('QRコードをかざす'), findsNothing);

    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();

    expect(find.text('解錠に成功しました'), findsNothing);
    expect(find.byKey(const Key('qr-scanner')), findsOneWidget);
    expect(find.text('QRコードをかざす'), findsOneWidget);
  });

  testWidgets('失敗はログに残り、取れたエラー文だけ足す', (WidgetTester tester) async {
    final MemoryCredentialRepository credentials = MemoryCredentialRepository();
    await credentials.write(const Credentials(email: 'member@example.com', password: 'secret'));
    final MemoryUnlockLogRepository log = MemoryUnlockLogRepository();
    final _ScriptedSession session = _ScriptedSession(
      hasSession: true,
      html: '<div class="alert-danger">このドアから離れています</div>',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: _tabs(
          credentials: credentials,
          log: log,
          source: ListQrScanSource([entry]),
          session: session,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(log.records.single.status, UnlockStatus.failed);
    expect(find.textContaining('解除に失敗しました'), findsOneWidget);
    expect(find.textContaining('このドアから離れています'), findsOneWidget);
  });

  testWidgets('キャンセルすると記録せずカメラを開く', (WidgetTester tester) async {
    final MemoryCredentialRepository credentials = MemoryCredentialRepository();
    await credentials.write(const Credentials(email: 'member@example.com', password: 'secret'));
    final MemoryUnlockLogRepository log = MemoryUnlockLogRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: _tabs(
          credentials: credentials,
          log: log,
          source: ListQrScanSource([entry]),
          session: _ScriptedSession(hasSession: false, html: '<p>ドア</p>'),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(log.records, isEmpty);
    expect(find.text('ログイン'), findsNothing);
    expect(find.text('QRコードの読み取りができました'), findsNothing);
    expect(find.byKey(const Key('qr-scanner')), findsOneWidget);
    expect(find.text('QRコードをかざす'), findsOneWidget);
  });

  testWidgets('認証情報が無いときは設定タブへ移る', (WidgetTester tester) async {
    final MemoryCredentialRepository credentials = MemoryCredentialRepository();
    final MemoryUnlockLogRepository log = MemoryUnlockLogRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: _tabs(
          credentials: credentials,
          log: log,
          source: ListQrScanSource([entry]),
          session: _ScriptedSession(hasSession: true, html: '<p>ドア</p>'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('メールアドレス、パスワードが設定されていません'), findsOneWidget);
    expect(log.records, isEmpty);

    await tester.tap(find.text('設定する'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('email')), findsOneWidget);
  });
}

Widget _tabs({
  required MemoryCredentialRepository credentials,
  required MemoryUnlockLogRepository log,
  required QrScanSource source,
  required _ScriptedSession session,
}) {
  return CheckinTabs(
    loadCredentials: LoadCredentials(credentials),
    saveCredentials: SaveCredentials(credentials),
    watchUnlockLog: WatchUnlockLog(log),
    watchLocationPermission: WatchLocationPermission(MemoryLocationPermission()),
    scanSource: source,
    onUnlockUrl: (_) {},
    unlockAndRecord: UnlockAndRecord(
      credentials: credentials,
      log: log,
      runner: LoginRunner(),
      form: session,
      session: session,
      pageHtml: session.pageHtml,
      position: _FixedPosition(),
      locality: _FixedLocality(),
      now: () => DateTime(2026, 10, 26, 9, 5),
    ),
  );
}

class _ScriptedSession implements LoginFormTarget, UnlockSession {
  _ScriptedSession({required this.hasSession, required this.html});

  @override
  final bool hasSession;
  final String html;

  @override
  Future<void> open(Uri url) async {}

  @override
  void useCookieSession() {}

  @override
  void fill({required String email, required String password}) {}

  Future<String> pageHtml() async => html;
}

class _FixedPosition implements CurrentPositionReader {
  @override
  Future<GeoFix?> read() async => const GeoFix(35.561, 139.715);
}

class _FixedLocality implements LocalityReader {
  @override
  Future<String?> read(GeoFix fix) async => '東京都大田区';
}
