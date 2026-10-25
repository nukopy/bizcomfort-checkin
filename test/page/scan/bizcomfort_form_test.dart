import 'package:bizcomfort_checkin/page/scan/bizcomfort_form.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ログイン欄のセレクタは調査どおり', () {
    expect(bizcomfortEmailSelector, '#id_email');
    expect(bizcomfortPasswordSelector, '#id_password');
    expect(bizcomfortSubmitSelector, 'input.form-btn');
  });
}
