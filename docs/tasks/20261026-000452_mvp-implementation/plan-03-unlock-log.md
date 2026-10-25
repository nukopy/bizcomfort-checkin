# 解除ログ Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ログタブは今日が属する月だけを出し、成功と失敗の両方を `SUCCESS` または `FAILED` で残し、検索から過去の月へ切り替え、1 件の詳細で URL と緯度経度を見せる。設定タブで位置情報の許可状態を見る。

**Architecture:** 一覧と詳細は `WatchUnlockLog` だけを見る。use case はコンストラクタで `UnlockLogRepository` を受け、選ばれた年月の記録と更新通知を外に出す。組み立ては `AppWire`。月の下限は `appReleaseDate`。

**Tech Stack:** Flutter。時刻と月の文字は自前で組む。`intl` は入れない。市区町村への逆ジオコードは記録時に行い、結果の文字列を記録に含める。

## Global Constraints

- 初期表示は `clock.now()` が属する月。見出しは `2026 年 3 月`。数字と「年」「月」のあいだに半角スペースを置く
- 右上の検索ボタンで月のリストを開く。上から新しい月で、`appReleaseDate` の月まで。全件表示とページングはしない
- 月の下限は `lib/constants.dart` の `appReleaseDate`（2026-10-26）。変えるときはこの定数だけ
- 一覧の 1 行は月日、時刻、市区町村、`enter` または `exit`、`SUCCESS` または `FAILED`。入退室は URL パスの `entry` / `exit` から取る。解除結果は `UnlockStatus` で、表示は `SUCCESS` と `FAILED`。URL 自体は行に出さない
- 市区町村は都道府県と市区町村まで。例は「東京都大田区」
- 行の末尾のボタンで詳細へ進む。詳細は一覧の項目に加え、URL と緯度、経度。タブバーは隠さず、ログタブの中の `Navigator` で開く
- 成功した解除も失敗した解除も、必ず 1 件追加する。追加するのは plan-05 の解除 use case
- ログ画面は `WatchUnlockLog` だけを受け取る。repository を page に import しない
- メールアドレスとパスワードは記録しない
- ログは端末内に保存し、アプリを終了しても残す。本番の repository はメモリ実装ではない
- 位置情報を許可されなければ市区町村の欄は `NOT_PERMITTED`、緯度と経度は null。逆引きに失敗すれば市区町村の欄は `FAILED`、成功していれば市区町村（例「東京都大田区」）。この `FAILED` は市区町村の欄で、解除結果の `FAILED` とは別
- 設定タブに「アクセス許可」を出す。中の行は「位置情報」。状態を見て、未許可なら許可を求め、OS が拒否したあとは端末の設定を開く。画面は use case だけを呼ぶ
- その月が空なら「記録はまだありません」
- 単一引用符。`flutter test` のあと `flutter analyze --fatal-infos`

---

### Task 1: ログを新しい順に表示する

**Files:**
- Create: `lib/domain/unlock_record.dart`
- Create: `lib/repository/memory_unlock_log_repository.dart`
- Create: `lib/usecase/watch_unlock_log.dart`
- Modify: `lib/page/log/log_page.dart`
- Modify: `lib/components/checkin_tabs.dart`
- Test: `test/page/log/log_page_test.dart`

**Interfaces:**
- Consumes: plan-01 の `LogPage`
- Produces: `UnlockRecord`、`DoorDirection`、`UnlockLogRepository`、`WatchUnlockLog`。plan-05 は画面から `add` せず、解除 use case が repository に追加する

- [ ] **Step 1: Write the failing test**

`test/page/log/log_page_test.dart`

```dart
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
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: LogPage(watchUnlockLog: watch, now: DateTime(2026, 3, 19))),
    );

    expect(find.text('2026 年 3 月'), findsOneWidget);
    expect(find.text('記録はまだありません'), findsNothing);
    expect(find.text('3月19日 09:05'), findsOneWidget);
    expect(find.text('東京都大田区'), findsOneWidget);
    expect(find.text('enter'), findsOneWidget);
    expect(find.text('SUCCESS'), findsOneWidget);
    expect(find.text('FAILED'), findsNothing);
    expect(find.text('東京都目黒区'), findsNothing);
    expect(find.textContaining('unlock/entry/newer'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/page/log/log_page_test.dart`

Expected: FAIL。`unlock_record.dart` が無い。

- [ ] **Step 3: Write minimal implementation**

`lib/domain/unlock_record.dart` はアプリが操作する形。`UnlockLogRepository` は追加と参照だけを持つ。

```dart
import 'package:flutter/foundation.dart';

enum DoorDirection { enter, exit }

enum UnlockStatus {
  success,
  failed;

  String get label => switch (this) {
    UnlockStatus.success => 'SUCCESS',
    UnlockStatus.failed => 'FAILED',
  };
}

class UnlockRecord {
  const UnlockRecord({
    required this.url,
    required this.at,
    required this.latitude,
    required this.longitude,
    required this.locality,
    required this.status,
  });

  final Uri url;
  final DateTime at;
  final double? latitude;
  final double? longitude;
  final String locality;
  final UnlockStatus status;

  DoorDirection get direction {
    final List<String> segments = url.pathSegments.where((String s) => s.isNotEmpty).toList();
    if (segments.length >= 2 && segments[1] == 'exit') {
      return DoorDirection.exit;
    }
    return DoorDirection.enter;
  }
}

abstract class UnlockLogRepository extends ChangeNotifier {
  List<UnlockRecord> get records;

  void add(UnlockRecord record);
}

String formatMonthHeading(DateTime month) {
  final DateTime local = month.toLocal();
  return '${local.year} 年 ${local.month} 月';
}

String formatUnlockRowDate(DateTime at) {
  final DateTime local = at.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${local.month}月${local.day}日 ${two(local.hour)}:${two(local.minute)}';
}
```

`lib/repository/memory_unlock_log_repository.dart`

```dart
import 'package:bizcomfort_checkin/domain/unlock_record.dart';

class MemoryUnlockLogRepository extends UnlockLogRepository {
  final List<UnlockRecord> _records = [];

  @override
  List<UnlockRecord> get records => List<UnlockRecord>.unmodifiable(_records);

  @override
  void add(UnlockRecord record) {
    _records.insert(0, record);
    notifyListeners();
  }
}
```

`lib/usecase/watch_unlock_log.dart`

```dart
import 'package:bizcomfort_checkin/domain/unlock_record.dart';
import 'package:flutter/foundation.dart';

class WatchUnlockLog {
  const WatchUnlockLog(this._repository);

  final UnlockLogRepository _repository;

  List<UnlockRecord> recordsIn(int year, int month) {
    return _repository.records.where((UnlockRecord record) {
      final DateTime local = record.at.toLocal();
      return local.year == year && local.month == month;
    }).toList();
  }

  Listenable get updates => _repository;
}
```

`LogPage` は `WatchUnlockLog watchUnlockLog` と、初期月を決める `DateTime now` を受け取る。見出しは選ばれた月。一覧は `recordsIn` の結果で、各行は月日、時刻、`locality`、`direction.name`、`status.label`。その月が空なら「記録はまだありません」。行の末尾のボタンで `LogDetailPage` を、ログタブ内の `Navigator` に積む。詳細には同じ項目に加え、URL と緯度、経度を出す。緯度または経度が null の欄は空にする。

右上の検索ボタンは、`appReleaseDate` の月から `now` の月までを新しい順に並べ、選ぶと見出しと一覧をその月へ変える。

`AppWire` が `MemoryUnlockLogRepository` を `WatchUnlockLog` に渡す。`CheckinTabs` は use case だけを受け取り、`LogPage` に渡す。

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test`

Expected: PASS

Run: `flutter analyze --fatal-infos`

Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add lib/domain/unlock_record.dart lib/repository/memory_unlock_log_repository.dart lib/usecase/watch_unlock_log.dart lib/page/log/log_page.dart lib/wire/app_wire.dart lib/components/checkin_tabs.dart test/page/log/log_page_test.dart
git commit -m "$(cat <<'EOF'
feat(mobile): show the month log with unlock status

EOF
)"
```

---

### Task 2: 設定タブに位置情報のアクセス許可を出す

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Create: `lib/usecase/watch_location_permission.dart`
- Modify: `lib/page/setting/setting_page.dart`
- Modify: `lib/wire/app_wire.dart`
- Modify: `ios/Runner/Info.plist`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Test: `test/page/setting/location_permission_test.dart`

**Interfaces:**
- Consumes: plan-02 の `SettingPage`
- Produces: `WatchLocationPermission`。plan-05 の WebView は、この許可が済んでいるときだけサイトの位置情報要求に `allow: true` を返す

- [ ] **Step 1: Write the failing test**

`test/page/setting/location_permission_test.dart` は `WatchLocationPermission` のフェイクを `SettingPage` に渡す。見出し「アクセス許可」と行「位置情報」、状態「未許可」が出る。`許可する` を押すとフェイクの `request` が 1 回呼ばれ、状態が「許可」に変わる。OS が拒否した状態では「設定を開く」が出て、それを押すと `openSettings` が 1 回呼ばれる。

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/page/setting/location_permission_test.dart`

Expected: FAIL。`watch_location_permission.dart` が無い。

- [ ] **Step 3: Write minimal implementation**

```bash
flutter pub add geolocator
```

`WatchLocationPermission` は許可状態の読み取り、`request`、`openSettings` を持つ。画面はこの use case だけを呼ぶ。テストはフェイクを渡し、`geolocator` のプラットフォームチャネルは叩かない。

`SettingPage` の認証情報の下に見出し「アクセス許可」と、行「位置情報」を置く。表示は「許可」「未許可」のどちらか。未許可ならボタン「許可する」。OS が以後の確認を拒否しているときは「許可する」の代わりに「設定を開く」。

iOS の `Info.plist` に `NSLocationWhenInUseUsageDescription` を置く。文言は「解除した場所をログに残し、ドアのページが現在地を確認できるようにします。」Android のメインマニフェストに `ACCESS_FINE_LOCATION` と `ACCESS_COARSE_LOCATION` を置く。

`AppWire` が本番の `WatchLocationPermission` を作り、`SettingPage` に渡す。

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test`

Expected: PASS

Run: `flutter analyze --fatal-infos`

Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/usecase/watch_location_permission.dart lib/page/setting/setting_page.dart lib/wire/app_wire.dart ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml test/page/setting/location_permission_test.dart
git commit -m "$(cat <<'EOF'
feat(mobile): show location permission in settings

EOF
)"
```
