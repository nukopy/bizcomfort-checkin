import 'package:bizcomfort_checkin/page/scan/unlock_page_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('拠点かドアが出ていれば成功', () {
    expect(unlockPageSucceeded('<p>拠点 BIZcomfort洗足池</p><p>ドア 洗足池①</p>'), isTrue);
    expect(unlockPageSucceeded('<form id="login"></form>'), isFalse);
  });

  test('エラー欄の文を取り、無ければ null', () {
    expect(extractUnlockError('<div class="alert-danger">このドアから離れています</div>'), 'このドアから離れています');
    expect(extractUnlockError('<p>ログイン</p>'), isNull);
  });
}
