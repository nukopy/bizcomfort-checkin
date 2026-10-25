import 'dart:io';
import 'dart:typed_data';

import 'package:bizcomfort_checkin/domain/unlock_record.dart';
import 'package:bizcomfort_checkin/repository/file_unlock_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('アプリを終了してもファイルから読み戻せる', () {
    final Directory directory = Directory.systemTemp.createTempSync('unlock-log');
    final File file = File('${directory.path}/unlock-log.json');
    addTearDown(() => directory.deleteSync(recursive: true));

    final DateTime at = DateTime.utc(2026, 10, 26, 1, 2);
    final Uint8List shot = Uint8List.fromList(<int>[1, 2, 3, 4]);
    final FileUnlockLogRepository first = FileUnlockLogRepository(file);
    first.add(
      UnlockRecord(
        url: Uri.parse('https://mypage.bizcomfort.jp/unlock/entry/id/'),
        at: at,
        latitude: null,
        longitude: null,
        locality: 'NOT_PERMITTED',
        status: UnlockStatus.failed,
        siteName: 'BIZcomfort洗足池',
        doorName: '洗足池①',
        errorMessage: '拠点から離れています。',
        shotBytes: shot,
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
    expect(second.records.single.at, at);
    final UnlockShot kept = second.shotFor(second.records.single, now: at);
    expect(kept.state, UnlockShotState.image);
    expect(kept.bytes, shot);
    final File saved = File('${directory.path}/unlock-shots/${at.microsecondsSinceEpoch}.jpg');
    expect(saved.existsSync(), isTrue);

    final UnlockShot expired = second.shotFor(
      second.records.single,
      now: at.add(const Duration(days: 31)),
    );
    expect(expired.state, UnlockShotState.expired);
    expect(saved.existsSync(), isFalse);
    expect(shotRetained(at, at.add(const Duration(days: 30))), isTrue);
  });
}
