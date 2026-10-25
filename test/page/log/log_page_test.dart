import 'package:bizcomfort_checkin/domain/unlock_record.dart';
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

    await tester.pumpWidget(
      MaterialApp(
        home: LogPage(watchUnlockLog: watch, now: DateTime(2026, 3, 19)),
      ),
    );

    expect(find.text('2026 年 3 月'), findsOneWidget);
    expect(find.text('記録はまだありません'), findsNothing);
    expect(find.text('3月19日 09:05'), findsOneWidget);
    expect(find.text('BIZcomfort洗足池'), findsOneWidget);
    expect(find.text('洗足池①'), findsOneWidget);
    expect(find.text('東京都大田区'), findsNothing);
    expect(find.text('enter'), findsOneWidget);
    expect(find.text('SUCCESS'), findsOneWidget);
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

    expect(find.text('BIZcomfort目黒'), findsOneWidget);
    await tester.tap(find.byKey(const Key('log-month')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026 年 10 月').last);
    await tester.pumpAndSettle();

    expect(find.text('2026 年 10 月'), findsOneWidget);
    expect(find.text('BIZcomfort洗足池'), findsOneWidget);
    expect(find.text('BIZcomfort目黒'), findsNothing);
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

    await tester.tap(find.byKey(const Key('log-detail')));
    await tester.pumpAndSettle();

    expect(find.text('https://mypage.bizcomfort.jp/unlock/entry/newer/'), findsOneWidget);
    expect(find.text('拠点名'), findsOneWidget);
    expect(find.text('BIZcomfort洗足池'), findsOneWidget);
    expect(find.text('ドア名'), findsOneWidget);
    expect(find.text('洗足池①'), findsOneWidget);
    expect(find.text('現在地（市区町村）'), findsOneWidget);
    expect(find.text('東京都大田区'), findsOneWidget);
    expect(find.text('現在地（GPS）'), findsOneWidget);
    expect(find.text('35.561'), findsOneWidget);
    expect(find.text('139.715'), findsOneWidget);
    expect(find.text('SUCCESS'), findsOneWidget);
  });
}
