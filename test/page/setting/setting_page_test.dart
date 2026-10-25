import 'dart:async';

import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/page/setting/setting_page.dart';
import 'package:bizcomfort_checkin/repository/memory_credential_repository.dart';
import 'package:bizcomfort_checkin/repository/memory_location_permission.dart';
import 'package:bizcomfort_checkin/usecase/load_credentials.dart';
import 'package:bizcomfort_checkin/usecase/save_credentials.dart';
import 'package:bizcomfort_checkin/usecase/watch_location_permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('保存すると repository に残る', (WidgetTester tester) async {
    final MemoryCredentialRepository repository = MemoryCredentialRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingPage(
          loadCredentials: LoadCredentials(repository),
          saveCredentials: SaveCredentials(repository),
          watchLocationPermission: WatchLocationPermission(MemoryLocationPermission()),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('email')), 'member@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'secret');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(
      await repository.read(),
      const Credentials(email: 'member@example.com', password: 'secret'),
    );
    expect(find.text('保存に成功しました'), findsOneWidget);
  });

  testWidgets('ステータスバーに重ならない', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    tester.view.padding = const FakeViewPadding(top: 59);
    tester.view.viewPadding = const FakeViewPadding(top: 59);
    addTearDown(tester.view.reset);

    final MemoryCredentialRepository repository = MemoryCredentialRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingPage(
          loadCredentials: LoadCredentials(repository),
          saveCredentials: SaveCredentials(repository),
          watchLocationPermission: WatchLocationPermission(MemoryLocationPermission()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('メールアドレスとパスワード')).dy, greaterThanOrEqualTo(59));
  });

  testWidgets('認証情報を読み込んでも保存ボタンは動かない', (WidgetTester tester) async {
    final Completer<Credentials?> pending = Completer<Credentials?>();
    final _GatedCredentials repository = _GatedCredentials(pending);
    await tester.pumpWidget(
      MaterialApp(
        home: SettingPage(
          loadCredentials: LoadCredentials(repository),
          saveCredentials: SaveCredentials(repository),
          watchLocationPermission: WatchLocationPermission(MemoryLocationPermission()),
        ),
      ),
    );
    await tester.pump();
    final double before = tester.getTopLeft(find.text('保存')).dy;

    pending.complete(const Credentials(email: 'member@example.com', password: 'secret'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.getTopLeft(find.text('保存')).dy, before);
  });
}

class _GatedCredentials implements CredentialRepository {
  _GatedCredentials(this.pending);

  final Completer<Credentials?> pending;
  Credentials? stored;

  @override
  Future<Credentials?> read() => pending.future;

  @override
  Future<void> write(Credentials credentials) async {
    stored = credentials;
  }
}
