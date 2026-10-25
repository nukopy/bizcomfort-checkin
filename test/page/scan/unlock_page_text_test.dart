import 'package:bizcomfort_checkin/page/scan/unlock_page_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String place = '''
<div class="unlock-select-block" style="display: block;">
  <p class="unlock-select-title">拠点</p>
  <p class="unlock-select-text">BIZcomfort洗足池</p>
  <p class="unlock-select-title">ドア</p>
  <p class="unlock-select-text">洗足池①</p>
</div>
''';

  test('拠点から離れていますが表示されていなければ成功', () {
    final UnlockPageReading hidden = readUnlockPage(
      '<p id="error-message" style="display: none;">拠点から離れています。</p>$place',
    );
    expect(hidden.succeeded, isTrue);
    expect(hidden.errorMessage, isNull);
    expect(hidden.siteName, 'BIZcomfort洗足池');
    expect(hidden.doorName, '洗足池①');

    final UnlockPageReading shown = readUnlockPage(
      '<p id="error-message" class="unlock-select-error" style="display: block;">拠点から離れています。</p>$place',
    );
    expect(shown.succeeded, isFalse);
    expect(shown.errorMessage, '拠点から離れています。');
    expect(shown.siteName, 'BIZcomfort洗足池');
    expect(shown.doorName, '洗足池①');
  });
}
