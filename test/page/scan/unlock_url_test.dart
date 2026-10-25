import 'package:bizcomfort_checkin/page/scan/unlock_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const String entry = 'https://mypage.bizcomfort.jp/unlock/entry/a0KRB000018nb3q2AA/';
  const String exit = 'https://mypage.bizcomfort.jp/unlock/exit/a0KRB000018nb3q2AA/';

  test('入室と退室の URL を受け付ける', () {
    expect(isBizcomfortUnlockUrl(Uri.parse(entry)), isTrue);
    expect(isBizcomfortUnlockUrl(Uri.parse(exit)), isTrue);
  });

  test('別ホストや http は拒む', () {
    expect(
      isBizcomfortUnlockUrl(Uri.parse('http://mypage.bizcomfort.jp/unlock/entry/id/')),
      isFalse,
    );
    expect(isBizcomfortUnlockUrl(Uri.parse('https://example.com/unlock/entry/id/')), isFalse);
    expect(isBizcomfortUnlockUrl(Uri.parse('https://mypage.bizcomfort.jp/login')), isFalse);
  });
}
