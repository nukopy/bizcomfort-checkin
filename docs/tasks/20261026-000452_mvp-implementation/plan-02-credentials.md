# 認証情報の保存 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 設定タブでメールアドレスとパスワードを保存し、OS の安全なストレージから読み戻せるようにする。

**Architecture:** 画面は `LoadCredentials` と `SaveCredentials` だけを呼ぶ。use case はコンストラクタで `CredentialRepository` を受け取る。組み立ては `AppWire`。保存キーは secure 実装の中だけにある。

**Tech Stack:** Flutter。この plan の Task 2 で `flutter pub add flutter_secure_storage` を実行する。

## Global Constraints

- メールアドレスとパスワードをログやソースに直書きしない
- 保存キーは `email` と `password`。`SecureCredentialRepository` の private 定数にする
- 設定画面は use case だけを受け取る。repository を page に import しない
- 単一引用符。`flutter test` のあと `flutter analyze --fatal-infos`
- plan-01 の三タブがすでにある

---

### Task 1: 設定画面が認証情報を保存する

**Files:**
- Create: `lib/domain/credentials.dart`
- Create: `lib/repository/memory_credential_repository.dart`
- Create: `lib/usecase/load_credentials.dart`
- Create: `lib/usecase/save_credentials.dart`
- Create: `lib/wire/app_wire.dart`
- Modify: `lib/page/setting/setting_page.dart`
- Modify: `lib/components/checkin_tabs.dart`
- Test: `test/repository/memory_credential_repository_test.dart`
- Test: `test/page/setting/setting_page_test.dart`

**Interfaces:**
- Consumes: plan-01 の `SettingPage`
- Produces: `Credentials`、`CredentialRepository`、`LoadCredentials`、`SaveCredentials`。plan-05 は repository を直接呼ばず、wire から渡された use case を使う

- [ ] **Step 1: Write the failing test**

`test/repository/memory_credential_repository_test.dart`

```dart
import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/repository/memory_credential_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('書いた認証情報を読める', () async {
    final MemoryCredentialRepository repository = MemoryCredentialRepository();

    expect(await repository.read(), isNull);

    const Credentials credentials = Credentials(
      email: 'member@example.com',
      password: 'secret',
    );
    await repository.write(credentials);

    expect(await repository.read(), credentials);
  });
}
```

`test/page/setting/setting_page_test.dart`

```dart
import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/page/setting/setting_page.dart';
import 'package:bizcomfort_checkin/repository/memory_credential_repository.dart';
import 'package:bizcomfort_checkin/usecase/load_credentials.dart';
import 'package:bizcomfort_checkin/usecase/save_credentials.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('保存すると repository に残る', (WidgetTester tester) async {
    final MemoryCredentialRepository repository = MemoryCredentialRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingPage(
          loadCredentials: LoadCredentials(repository),
          saveCredentials: SaveCredentials(repository),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('email')), 'member@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'secret');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(
      await repository.read(),
      const Credentials(email: 'member@example.com', password: 'secret'),
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/repository/memory_credential_repository_test.dart test/page/setting/setting_page_test.dart`

Expected: FAIL。`credentials.dart` が無い。

- [ ] **Step 3: Write minimal implementation**

`lib/domain/credentials.dart` はアプリが操作する形だけ。

```dart
class Credentials {
  const Credentials({required this.email, required this.password});

  final String email;
  final String password;

  @override
  bool operator ==(Object other) {
    return other is Credentials && other.email == email && other.password == password;
  }

  @override
  int get hashCode => Object.hash(email, password);
}

abstract class CredentialRepository {
  Future<Credentials?> read();

  Future<void> write(Credentials credentials);
}
```

`lib/repository/memory_credential_repository.dart`

```dart
import 'package:bizcomfort_checkin/domain/credentials.dart';

class MemoryCredentialRepository implements CredentialRepository {
  Credentials? _credentials;

  @override
  Future<Credentials?> read() async => _credentials;

  @override
  Future<void> write(Credentials credentials) async {
    _credentials = credentials;
  }
}
```

`lib/usecase/load_credentials.dart` と `lib/usecase/save_credentials.dart`。

```dart
import 'package:bizcomfort_checkin/domain/credentials.dart';

class LoadCredentials {
  const LoadCredentials(this._repository);

  final CredentialRepository _repository;

  Future<Credentials?> call() => _repository.read();
}

class SaveCredentials {
  const SaveCredentials(this._repository);

  final CredentialRepository _repository;

  Future<void> call(Credentials credentials) => _repository.write(credentials);
}
```

`SettingPage` は `LoadCredentials` と `SaveCredentials` を受け取る。`TextField` の key は `email` と `password`。パスワード欄は `obscureText: true`。ボタンの文言は「保存」。`TextEditingController` は `State` が持つ。`initState` で `loadCredentials()` し、あれば二つの欄に入れる。保存ボタンは `saveCredentials(Credentials(...))` を呼ぶ。

`AppWire` が repository を作り、二つの use case に渡す。`CheckinTabs` は use case だけを受け取り、`SettingPage` に渡す。テストが wire を省略したときは `MemoryCredentialRepository` から use case を作る。plan-02 Task 2 で wire の本番 repository を secure 実装へ差し替える。

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/page/setting test/widget_test.dart`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/domain/credentials.dart lib/repository/memory_credential_repository.dart lib/usecase/load_credentials.dart lib/usecase/save_credentials.dart lib/wire/app_wire.dart lib/page/setting/setting_page.dart lib/components/checkin_tabs.dart test/repository/memory_credential_repository_test.dart test/page/setting/setting_page_test.dart
git commit -m "$(cat <<'EOF'
feat(mobile): save email and password from settings

EOF
)"
```

---

### Task 2: OS の安全なストレージへ保存する

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Create: `lib/repository/secure_credential_repository.dart`
- Modify: `lib/main.dart`
- Test: `test/repository/secure_credential_repository_test.dart`

**Interfaces:**
- Consumes: `CredentialRepository`、`Credentials`
- Produces: `SecureCredentialRepository`。キー値の読み書きは `SecureKeyValue` 経由なので、OS なしでテストできる

- [ ] **Step 1: Write the failing test**

```dart
import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/repository/secure_credential_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('email と password のキーで往復する', () async {
    final MapSecureKeyValue storage = MapSecureKeyValue();
    final SecureCredentialRepository repository = SecureCredentialRepository(storage);

    await repository.write(
      const Credentials(email: 'member@example.com', password: 'secret'),
    );

    expect(await storage.read('email'), 'member@example.com');
    expect(await storage.read('password'), 'secret');
    expect(
      await repository.read(),
      const Credentials(email: 'member@example.com', password: 'secret'),
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/repository/secure_credential_repository_test.dart`

Expected: FAIL。`secure_credential_repository.dart` が無い。

- [ ] **Step 3: Write minimal implementation**

```bash
flutter pub add flutter_secure_storage
```

`lib/repository/secure_credential_repository.dart`

```dart
import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureKeyValue {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class MapSecureKeyValue implements SecureKeyValue {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}

class FlutterSecureKeyValue implements SecureKeyValue {
  FlutterSecureKeyValue(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
}

class SecureCredentialRepository implements CredentialRepository {
  SecureCredentialRepository(this._storage);

  static const String _emailKey = 'email';
  static const String _passwordKey = 'password';

  final SecureKeyValue _storage;

  @override
  Future<Credentials?> read() async {
    final String? email = await _storage.read(_emailKey);
    final String? password = await _storage.read(_passwordKey);
    if (email == null || password == null) {
      return null;
    }
    return Credentials(email: email, password: password);
  }

  @override
  Future<void> write(Credentials credentials) async {
    await _storage.write(_emailKey, credentials.email);
    await _storage.write(_passwordKey, credentials.password);
  }
}
```

`main()` だけが `AppWire` を作る。本番の wire は `SecureCredentialRepository(FlutterSecureKeyValue(const FlutterSecureStorage()))` を `LoadCredentials` と `SaveCredentials` に渡す。画面と `CheckinTabs` は repository を受け取らない。

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test`

Expected: PASS

Run: `flutter analyze --fatal-infos`

Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/repository/secure_credential_repository.dart lib/main.dart lib/components/checkin_tabs.dart test/repository/secure_credential_repository_test.dart
git commit -m "$(cat <<'EOF'
feat(mobile): store credentials in the OS secure storage

EOF
)"
```
