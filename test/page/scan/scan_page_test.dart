import 'package:bizcomfort_checkin/page/scan/scan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('起動直後から読み取り面があり、ドア URL だけ伝える', (WidgetTester tester) async {
    final ListQrScanSource source = ListQrScanSource([
      'https://example.com/nope',
      'https://mypage.bizcomfort.jp/unlock/entry/a0KRB000018nb3q2AA/',
    ]);
    final List<Uri> accepted = [];

    await tester.pumpWidget(
      MaterialApp(
        home: ScanPage(source: source, onUnlockUrl: accepted.add),
      ),
    );

    expect(find.byKey(const Key('qr-scanner')), findsOneWidget);
    await tester.pump();

    expect(accepted, hasLength(1));
    expect(
      accepted.single.toString(),
      'https://mypage.bizcomfort.jp/unlock/entry/a0KRB000018nb3q2AA/',
    );
  });

  testWidgets('同じ URL は連続して一度だけ伝える', (WidgetTester tester) async {
    const String entry = 'https://mypage.bizcomfort.jp/unlock/entry/a0KRB000018nb3q2AA/';
    final List<Uri> accepted = [];

    await tester.pumpWidget(
      MaterialApp(
        home: ScanPage(source: ListQrScanSource([entry, entry]), onUnlockUrl: accepted.add),
      ),
    );
    await tester.pump();

    expect(accepted, hasLength(1));
  });
}
