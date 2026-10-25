# 三タブ Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** カウンターをやめ、起動直後に QR コード読み取りタブが開いている三タブにする。

**Architecture:** タブバーは `lib/components/checkin_tabs.dart` の共通 UI で、常に表示する。中身だけを `lib/page/scan`（初期）、`lib/page/log`、`lib/page/setting` で差し替える。この plan では各ページに文言だけ置く。

**Tech Stack:** Flutter。新しいパッケージは入れない。

## Global Constraints

- タブは「QRコード読み取り」「ログ」「設定」の順。初期選択は 0。タブバーは常に表示し、ページは body だけを差し替える
- 単一引用符。`flutter test` のあと `flutter analyze --fatal-infos`
- この plan ではカメラも保存もしない

---

### Task 1: 起動直後のタブを QR コード読み取りにする

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/components/checkin_tabs.dart`
- Create: `lib/page/scan/scan_page.dart`
- Create: `lib/page/log/log_page.dart`
- Create: `lib/page/setting/setting_page.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: なし
- Produces: `CheckinTabs`。`ScanPage`、`LogPage`、`SettingPage` は後続 plan が中身を足す

- [ ] **Step 1: Write the failing test**

`test/widget_test.dart` を次で置き換える。

```dart
import 'package:bizcomfort_checkin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('起動直後はQRコード読み取りタブ', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    final NavigationBar bar = tester.widget(find.byType(NavigationBar));
    expect(bar.selectedIndex, 0);
    expect(find.text('QRコードをかざす'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('ログと設定に切り替えられる', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('ログ'));
    await tester.pumpAndSettle();
    expect(find.text('記録はまだありません'), findsOneWidget);

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    expect(find.text('メールアドレスとパスワード'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`

Expected: FAIL。`NavigationBar` が無い。

- [ ] **Step 3: Write minimal implementation**

`lib/page/scan/scan_page.dart`

```dart
import 'package:flutter/material.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('QRコードをかざす'));
  }
}
```

`lib/page/log/log_page.dart`

```dart
import 'package:flutter/material.dart';

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('記録はまだありません'));
  }
}
```

`lib/page/setting/setting_page.dart`

```dart
import 'package:flutter/material.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('メールアドレスとパスワード'));
  }
}
```

`lib/components/checkin_tabs.dart`

```dart
import 'package:bizcomfort_checkin/page/log/log_page.dart';
import 'package:bizcomfort_checkin/page/scan/scan_page.dart';
import 'package:bizcomfort_checkin/page/setting/setting_page.dart';
import 'package:flutter/material.dart';

class CheckinTabs extends StatefulWidget {
  const CheckinTabs({super.key});

  @override
  State<CheckinTabs> createState() => _CheckinTabsState();
}

class _CheckinTabsState extends State<CheckinTabs> {
  static const List<Widget> _pages = <Widget>[ScanPage(), LogPage(), SettingPage()];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'QRコード読み取り',
          ),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'ログ'),
          NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}
```

`lib/main.dart` は `MyApp` だけにし、`home` を `const CheckinTabs()` にする。カウンターのクラスは削除する。

```dart
import 'package:bizcomfort_checkin/components/checkin_tabs.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BIZcomfort Checkin',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const CheckinTabs(),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`

Expected: PASS

Run: `flutter analyze --fatal-infos`

Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/components/checkin_tabs.dart lib/page/scan/scan_page.dart lib/page/log/log_page.dart lib/page/setting/setting_page.dart test/widget_test.dart
git commit -m "$(cat <<'EOF'
feat(mobile): open the app on the QR tab

EOF
)"
```
