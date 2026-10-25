import 'dart:io';

import 'package:bizcomfort_checkin/domain/unlock_record.dart';
import 'package:bizcomfort_checkin/repository/file_unlock_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('アプリを終了してもファイルから読み戻せる', () {
    final Directory directory = Directory.systemTemp.createTempSync('unlock-log');
    final File file = File('${directory.path}/unlock-log.json');
    addTearDown(() => directory.deleteSync(recursive: true));

    final FileUnlockLogRepository first = FileUnlockLogRepository(file);
    first.add(
      UnlockRecord(
        url: Uri.parse('https://mypage.bizcomfort.jp/unlock/entry/id/'),
        at: DateTime.utc(2026, 10, 26, 1, 2),
        latitude: null,
        longitude: null,
        locality: 'NOT_PERMITTED',
        status: UnlockStatus.failed,
        siteName: 'BIZcomfort洗足池',
        doorName: '洗足池①',
        errorMessage: '拠点から離れています。',
      ),
    );

    final FileUnlockLogRepository second = FileUnlockLogRepository(file);
    expect(second.records, hasLength(1));
    expect(second.records.single.locality, 'NOT_PERMITTED');
    expect(second.records.single.latitude, isNull);
    expect(second.records.single.status, UnlockStatus.failed);
    expect(second.records.single.siteName, 'BIZcomfort洗足池');
    expect(second.records.single.doorName, '洗足池①');
    expect(second.records.single.errorMessage, '拠点から離れています。');
    expect(second.records.single.at, DateTime.utc(2026, 10, 26, 1, 2));
  });
}
