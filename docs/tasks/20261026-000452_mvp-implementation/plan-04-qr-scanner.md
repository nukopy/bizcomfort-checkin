# QR リーダー Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** アプリ起動と同時に QR リーダーが表示され、ドアの URL だけを読み取り結果として渡す。

**Architecture:** 画面は `QrScanSource` の文字列を受ける。カメラ本体は `mobile_scanner`。テストは文字列を流す実装で行う。URL 判定は純粋関数。

**Tech Stack:** Flutter。Task 2 で `flutter pub add mobile_scanner`。iOS の `NSCameraUsageDescription` と Android の `CAMERA` を同じタスクで足す。

## Global Constraints

- リーダーを開くボタンは作らない。`ScanPage` の最初のフレームに読み取り面がある
- 受け付ける URL は調査メモの形だけ。例: `https://mypage.bizcomfort.jp/unlock/entry/a0KRB000018nb3q2AA/`
- `http`、別ホスト、`entry` / `exit` 以外は無視する
- この plan ではドア解除もログ追加もしない。読み取った `Uri` を `onUnlockUrl` に渡すところまで
- 単一引用符。`flutter test` のあと `flutter analyze --fatal-infos`

---

### Task 1: ドア URL だけを受け取る

**Files:**
- Create: `lib/page/scan/unlock_url.dart`
- Modify: `lib/page/scan/scan_page.dart`
- Test: `test/page/scan/unlock_url_test.dart`
- Test: `test/page/scan/scan_page_test.dart`

**Interfaces:**
- Consumes: plan-01 の `ScanPage`
- Produces: `bool isBizcomfortUnlockUrl(Uri uri)`、`QrScanSource`、`ScanPage.onUnlockUrl`。plan-05 がコールバックで解除を始める

- [ ] **Step 1: Write the failing test**

`test/page/scan/unlock_url_test.dart`

```dart
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
    expect(
      isBizcomfortUnlockUrl(Uri.parse('https://example.com/unlock/entry/id/')),
      isFalse,
    );
    expect(
      isBizcomfortUnlockUrl(Uri.parse('https://mypage.bizcomfort.jp/login')),
      isFalse,
    );
  });
}
```

`test/page/scan/scan_page_test.dart`

```dart
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
        home: ScanPage(
          source: source,
          onUnlockUrl: accepted.add,
        ),
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/page/scan`

Expected: FAIL。`unlock_url.dart` が無い。

- [ ] **Step 3: Write minimal implementation**

`lib/page/scan/unlock_url.dart`

```dart
bool isBizcomfortUnlockUrl(Uri uri) {
  if (uri.scheme != 'https' || uri.host != 'mypage.bizcomfort.jp') {
    return false;
  }
  final List<String> segments = uri.pathSegments.where((String s) => s.isNotEmpty).toList();
  if (segments.length != 3 || segments.first != 'unlock') {
    return false;
  }
  return segments[1] == 'entry' || segments[1] == 'exit';
}
```

`ScanPage` は `QrScanSource source` と `ValueChanged<Uri> onUnlockUrl` を受ける。`initState` で `source.codes` を購読し、`Uri.tryParse` して `isBizcomfortUnlockUrl` が真のときだけ `onUnlockUrl` する。読み取り面は `KeyedSubtree(key: Key('qr-scanner'), child: source.buildView())`。`ListQrScanSource` はテスト用で、購読開始時に列を流し、`buildView` は `SizedBox.shrink()` を key の子に置く。

既存の `test/widget_test.dart` は `ScanPage()` の必須引数が増えるので、`CheckinTabs` がテスト用 source を受け取れるようにする。未指定時の source は Task 2 のカメラ実装。Task 1 の間は `CheckinTabs` のデフォルト source を、何も流さない `ListQrScanSource(const [])` にしてウィジェットテストを通す。

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/page/scan lib/components/checkin_tabs.dart test/page/scan test/widget_test.dart
git commit -m "$(cat <<'EOF'
feat(mobile): accept only BIZcomfort unlock URLs from the scanner

EOF
)"
```

---

### Task 2: カメラの読み取り面を起動時に出す

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Modify: `lib/page/scan/scan_page.dart`
- Modify: `ios/Runner/Info.plist`
- Modify: `android/app/src/main/AndroidManifest.xml`

**Interfaces:**
- Consumes: `QrScanSource`
- Produces: `MobileScannerQrSource`。`CheckinTabs` のデフォルト source がこれになる

- [ ] **Step 1: Add the scanner package and permissions**

```bash
flutter pub add mobile_scanner
```

`ios/Runner/Info.plist` に次を足す。

```xml
<key>NSCameraUsageDescription</key>
<string>ドアの QR コードを読み取るためにカメラを使います。</string>
```

`android/app/src/main/AndroidManifest.xml` の `manifest` 直下に次を足す。

```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

- [ ] **Step 2: Mount the camera view on the scan tab**

`MobileScannerQrSource.buildView()` は `MobileScanner` を返し、検出した `barcode.rawValue` を `codes` に流す。カメラを渡すのは `main()` だけ。`MyApp` の source を省略したテストは `ListQrScanSource(const [])` のままで、カメラを起動しない。

- [ ] **Step 3: Run tests**

Run: `flutter test`

Expected: PASS

Run: `flutter analyze --fatal-infos`

Expected: No issues found

実機のカメラ起動はこのコマンドでは確認しない。シミュレータで読み取りタブにカメラプレビューが出ることだけ、実装後に見る。

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/page/scan lib/components/checkin_tabs.dart ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml
git commit -m "$(cat <<'EOF'
feat(mobile): show the QR scanner when the app opens

EOF
)"
```
