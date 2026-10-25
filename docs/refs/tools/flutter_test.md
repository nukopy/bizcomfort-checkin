はい。Flutterには公式のE2Eテスト機能があります。

ただし、`flutter test`はE2Eテスト専用のコマンドではありません。 Unit Test、Widget Test、Integration Test（E2E）の実行に使用できるコマンドです。

Flutter公式では、E2Eテストに相当するものを主に Integration Test と呼びます。

[image](https://www.google.com/s2/favicons?domain=https://docs.flutter.dev\&sz=32)

Flutter

+1



## 1. Flutterのテストは3種類

| 種類                    | テスト対象     | 実行環境         | コマンド                                         |
| --------------------- | --------- | ------------ | -------------------------------------------- |
| Unit Test             | 関数・クラス    | Dart VM      | `flutter test test/`                         |
| Widget Test           | UIコンポーネント | Flutterテスト環境 | `flutter test test/`                         |
| Integration Test（E2E） | アプリ全体の操作  | Simulator・実機 | `flutter test integration_test/ -d <device>` |

つまり、コマンドは同じでも、テストファイルと実行環境が違います。

## 2. E2Eテストのセットアップ

### Step 1. パッケージの追加

Flutter公式の`integration_test`を追加します。

```
flutter pub add 'dev:integration_test:{"sdk":"flutter"}'
```

`pubspec.yaml`には次の依存関係が追加されます。

```
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

### Step 2. テストファイルを作成

```
my_app/
├── lib/
│   └── main.dart
├── test/
│   ├── unit/
│   └── widget/
└── integration_test/
    └── login_test.dart
```

例えばログイン画面を操作するE2Eテストは、次のように書けます。

```
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login flow', (tester) async {
    app.main();

    await tester.pumpAndSettle();

    // Enter credentials
    await tester.enterText(
      find.byKey(const Key('email')),
      'test@example.com',
    );

    await tester.enterText(
      find.byKey(const Key('password')),
      'test-password',
    );

    // Tap login button
    await tester.tap(find.byKey(const Key('login_button')));

    await tester.pumpAndSettle();

    // Verify navigation
    expect(find.text('Welcome'), findsOneWidget);
  });
}
```

この例は、アプリ側に対応する`Key`が設定されていることを前提としています。また、テスト用アカウントとテスト環境を使う必要があります。

### Step 3. iOS Simulatorで実行

```
# デバイスを確認
flutter devices

# 特定のSimulatorで実行
flutter test integration_test/ -d <SIMULATOR_ID>
```

アプリがSimulator上で起動し、フォーム入力・ボタン操作・結果検証が行われます。

[image](https://www.google.com/s2/favicons?domain=https://docs.flutter.dev\&sz=32)

Flutter



## 3. テストがどの範囲まで動くか

Integration Testの実行イメージ

Flutter Test Runner

テストシナリオを実行

iOS Simulator / Android Emulator

実際に起動したFlutterアプリ

画面表示 → 入力 → タップ → 遷移

Assertion

期待する画面・状態になったか確認

ただし、標準の`integration_test`には制約があります。

例えば、iOSの権限ダイアログやWebView内のHTML要素を、Flutter Widgetと同じ方法で操作できるわけではありません。

今回開発している外部Webサイトへの自動ログインアプリでは、これは重要な違いです。

WebView内の実際のログインフォームまでテストしたい場合、ネイティブUIへの操作に対応した`patrol`なども検討できます。

[image](https://www.google.com/s2/favicons?domain=https://docs.flutter.dev\&sz=32)

Flutter



## 4. miseに追加するなら

Unit/Widget TestとE2Eテストは、実行時間や必要な環境が違うので分けましょう。

```
# Unit / Widget tests
[tasks.test]
description = "Run unit and widget tests"
run = "flutter test test/"

# E2E tests
[tasks."test:e2e"]
description = "Run integration tests on iOS Simulator"
usage = '''
arg "[device]" help="Target device ID" default="ios"
'''
run = 'flutter test integration_test/ -d "$usage_device"'
```

ただし、`ios`は常に有効なデバイスIDとは限りません。確実に動作させるには、`flutter devices`で取得したSimulator IDを渡すか、以前作成した`dev`タスクと同じSimulator起動・選択処理を組み込む必要があります。

CIなら、次のような使い分けがおすすめです。

| タイミング           | テスト               |
| --------------- | ----------------- |
| pre-commit      | Unit / Widget     |
| Pull Request    | Unit / Widget     |
| mainへのマージ前・定期実行 | E2E               |
| リリース前           | iOS / AndroidのE2E |

E2EはSimulatorの起動やアプリのビルドが必要なため、Unit/Widgetテストより時間がかかります。

結論として、FlutterのE2Eテストは公式の`integration_test`パッケージで実現でき、`flutter test integration_test/ -d <device>`で実行できます。

まず公式の`integration_test`でFlutterアプリ自体の動作を検証し、WebView内部やOSの認証ダイアログまで操作する必要が出た段階で、Patrolなどに拡張するのがよいと思います。

公式ドキュメント：[Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests?utm_source=chatgpt.com)
