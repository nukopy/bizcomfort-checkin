import 'dart:async';

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

  testWidgets('カメラを開き直すと同じ QR を一度だけ再度伝える', (WidgetTester tester) async {
    const String entry = 'https://mypage.bizcomfort.jp/unlock/entry/a0KRB000018nb3q2AA/';
    const String exit = 'https://mypage.bizcomfort.jp/unlock/exit/a0KRB000018nb3q2AA/';
    final _PushSource source = _PushSource();
    final ValueNotifier<bool> camera = ValueNotifier<bool>(true);
    final List<Uri> accepted = <Uri>[];
    addTearDown(camera.dispose);
    addTearDown(source.close);

    await tester.pumpWidget(
      MaterialApp(
        home: ScanPage(source: source, onUnlockUrl: accepted.add, cameraOpen: camera),
      ),
    );
    source.add(entry);
    await tester.pump();
    expect(accepted, hasLength(1));

    camera.value = false;
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    camera.value = true;
    await tester.pump();
    source.add(entry);
    await tester.pump();
    expect(accepted, hasLength(2));

    source.add(entry);
    await tester.pump();
    expect(accepted, hasLength(2));

    await tester.pump(const Duration(milliseconds: 1500));
    source.add(entry);
    await tester.pump();
    expect(accepted, hasLength(3));

    source.add(exit);
    await tester.pump();
    expect(accepted, hasLength(4));
  });
}

class _PushSource implements QrScanSource {
  final StreamController<String> _codes = StreamController<String>.broadcast();

  @override
  Stream<String> get codes => _codes.stream;

  void add(String value) {
    _codes.add(value);
  }

  Future<void> close() => _codes.close();

  @override
  Widget buildView() => const SizedBox.shrink();
}
