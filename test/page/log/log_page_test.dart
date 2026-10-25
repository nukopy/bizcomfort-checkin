import 'dart:typed_data';

import 'package:bizcomfort_checkin/domain/unlock_record.dart';
import 'package:bizcomfort_checkin/page/log/log_detail_page.dart';
import 'package:bizcomfort_checkin/page/log/log_page.dart';
import 'package:bizcomfort_checkin/repository/memory_unlock_log_repository.dart';
import 'package:bizcomfort_checkin/usecase/watch_unlock_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('月日と時刻と市区町村と入退室とステータスを出す', (WidgetTester tester) async {
    final MemoryUnlockLogRepository repository = MemoryUnlockLogRepository();
    final WatchUnlockLog watch = WatchUnlockLog(repository);
    repository.add(
      UnlockRecord(
        url: Uri.parse('https://mypage.bizcomfort.jp/unlock/exit/older/'),
        at: DateTime(2026, 2, 2, 8, 0),
        latitude: 35.0,
        longitude: 139.0,
        locality: '東京都目黒区',
        status: UnlockStatus.failed,
        siteName: 'BIZcomfort目黒',
        doorName: '目黒①',
      ),
    );
    repository.add(
      UnlockRecord(
        url: Uri.parse('https://mypage.bizcomfort.jp/unlock/entry/newer/'),
        at: DateTime(2026, 3, 19, 9, 5),
        latitude: 35.561,
        longitude: 139.715,
        locality: '東京都大田区',
        status: UnlockStatus.success,
        siteName: 'BIZcomfort洗足池',
        doorName: '洗足池①',
      ),
    );
    repository.add(
      UnlockRecord(
        url: Uri.parse('https://mypage.bizcomfort.jp/unlock/entry/same-month/'),
        at: DateTime(2026, 3, 18, 8, 0),
        latitude: 35.0,
        longitude: 139.0,
        locality: '東京都大田区',
        status: UnlockStatus.success,
        siteName: 'BIZcomfort蒲田',
        doorName: '蒲田①',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LogPage(watchUnlockLog: watch, now: DateTime(2026, 3, 19)),
      ),
    );

    expect(find.text('2026 年 3 月'), findsOneWidget);
    expect(find.text('記録はまだありません'), findsNothing);
    expect(find.text('3月19日 09:05'), findsOneWidget);
    expect(find.textContaining('BIZcomfort洗足池'), findsOneWidget);
    expect(find.textContaining('洗足池①'), findsOneWidget);
    expect(find.text('東京都大田区'), findsNothing);
    expect(find.textContaining('enter'), findsNWidgets(2));
    expect(find.text('SUCCESS'), findsNWidgets(2));
    expect(find.byType(Divider), findsOneWidget);
    expect(find.text('FAILED'), findsNothing);
    expect(find.text('東京都目黒区'), findsNothing);
    expect(find.textContaining('unlock/entry/newer'), findsNothing);
  });

  testWidgets('カレンダーでリリース月の記録へ切り替える', (WidgetTester tester) async {
    final MemoryUnlockLogRepository repository = MemoryUnlockLogRepository();
    repository.add(
      UnlockRecord(
        url: Uri.parse('https://mypage.bizcomfort.jp/unlock/entry/oct/'),
        at: DateTime(2026, 10, 26, 8, 0),
        latitude: 35.0,
        longitude: 139.0,
        locality: '東京都大田区',
        status: UnlockStatus.success,
        siteName: 'BIZcomfort洗足池',
        doorName: '洗足池①',
      ),
    );
    repository.add(
      UnlockRecord(
        url: Uri.parse('https://mypage.bizcomfort.jp/unlock/exit/nov/'),
        at: DateTime(2026, 11, 2, 18, 0),
        latitude: 35.0,
        longitude: 139.0,
        locality: '東京都目黒区',
        status: UnlockStatus.failed,
        siteName: 'BIZcomfort目黒',
        doorName: '目黒①',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LogPage(watchUnlockLog: WatchUnlockLog(repository), now: DateTime(2026, 11, 2)),
      ),
    );

    expect(find.textContaining('BIZcomfort目黒'), findsOneWidget);
    await tester.tap(find.byKey(const Key('log-month')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026 年 10 月').last);
    await tester.pumpAndSettle();

    expect(find.text('2026 年 10 月'), findsOneWidget);
    expect(find.textContaining('BIZcomfort洗足池'), findsOneWidget);
    expect(find.textContaining('BIZcomfort目黒'), findsNothing);
  });

  testWidgets('詳細に URL と緯度経度を出す', (WidgetTester tester) async {
    final MemoryUnlockLogRepository repository = MemoryUnlockLogRepository();
    repository.add(
      UnlockRecord(
        url: Uri.parse('https://mypage.bizcomfort.jp/unlock/entry/newer/'),
        at: DateTime(2026, 3, 19, 9, 5),
        latitude: 35.561,
        longitude: 139.715,
        locality: '東京都大田区',
        status: UnlockStatus.success,
        siteName: 'BIZcomfort洗足池',
        doorName: '洗足池①',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LogPage(watchUnlockLog: WatchUnlockLog(repository), now: DateTime(2026, 3, 19)),
      ),
    );

    await tester.tap(find.text('3月19日 09:05'));
    await tester.pumpAndSettle();

    expect(find.text('・解錠時刻：3月19日 09:05'), findsOneWidget);
    expect(find.text('・拠点名：BIZcomfort洗足池'), findsOneWidget);
    expect(find.text('・ドア名：洗足池①'), findsOneWidget);
    expect(find.text('・現在地（市区町村）：東京都大田区'), findsOneWidget);
    expect(find.text('・現在地（GPS）：35.56, 139.72'), findsOneWidget);
    expect(find.text('・スクショ：保存できませんでした'), findsOneWidget);
  });

  testWidgets('スクショがあれば画像を出し、期限後はその旨を出す', (WidgetTester tester) async {
    final UnlockRecord record = UnlockRecord(
      url: Uri.parse('https://mypage.bizcomfort.jp/unlock/entry/newer/'),
      at: DateTime(2026, 3, 19, 9, 5),
      latitude: 35.561,
      longitude: 139.715,
      locality: '東京都大田区',
      status: UnlockStatus.success,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LogDetailPage(record: record, shot: UnlockShot.image(_png)),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('・スクショ：'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: LogDetailPage(record: record, shot: const UnlockShot.expired()),
      ),
    );
    expect(find.text('・スクショ：保存期限が過ぎました'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}

final Uint8List _png = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);
