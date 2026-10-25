# WebView ログイン Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 読み取ったドア URL を WebView で開き、保存済みの認証情報でログインする。ログイン後の解除はパスワードを再送せず、WebView のセッションを使う。

**Architecture:** 手順の判断は `LoginRunner`。画面への入力は `LoginFormTarget`、セッションの有無は `UnlockSession`。実体は Task 2 の `flutter_inappwebview`。WebView は読み取りタブの裏で動かし、成功しても失敗しても画面には出さない。失敗はポップアップで知らせ、成功も失敗もログに残す。

**Tech Stack:** Flutter。Task 2 で `flutter pub add flutter_inappwebview`。

## Global Constraints

- 手順は仕様の順。認証情報の取得、HTTPS の確認、フォーム入力、ユーザーのログイン確定、以後はセッション
- セッションが残っていれば、フォーム入力と確定をせず URL を開く
- セッションが無ければ、保存済みの認証情報で取り直す。ユーザーにメールアドレスとパスワードは打たせない
- 許可するページは `https://mypage.bizcomfort.jp` だけ。違うサイトには入力しない
- フォームの CSS セレクタは `#id_email`、`#id_password`、`input.form-btn`。`contexts/investigations/login-form.md` に記録済み
- 成功も失敗も `UnlockLogRepository.add` する。`status` は `UnlockStatus.success`（表示 `SUCCESS`）か `UnlockStatus.failed`（表示 `FAILED`）
- 失敗したときはポップアップ「解除に失敗しました」を出す。ページからエラー文を取り出せたときだけ、同じポップアップにその文を足す。取り出せなければ文は足さない。WebView は `Offstage` のまま
- ページの位置情報要求には `onGeolocationPermissionsShowPrompt` で応答する。origin が `https://mypage.bizcomfort.jp` で、アプリの位置情報が許可済みのときだけ `allow: true` と `retain: true`。それ以外は拒否する。OS の許可ダイアログは出さない。詳細は `contexts/investigations/webview-geolocation.md`
- パスワードをログに出さない
- 単一引用符。`flutter test` のあと `flutter analyze --fatal-infos`

---

### Task 1: ログイン手順をセッションの有無で分ける

**Files:**
- Create: `lib/page/scan/login_runner.dart`
- Test: `test/page/scan/login_runner_test.dart`

**Interfaces:**
- Consumes: `Credentials`、`CredentialRepository`、`isBizcomfortUnlockUrl`
- Produces: `LoginRunner`。plan の Task 2 が WebView を `LoginFormTarget` と `UnlockSession` として渡す

- [ ] **Step 1: Write the failing test**

`test/page/scan/login_runner_test.dart`

```dart
import 'package:bizcomfort_checkin/page/scan/login_runner.dart';
import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Credentials credentials = Credentials(
    email: 'member@example.com',
    password: 'secret',
  );
  final Uri unlockUrl = Uri.parse(
    'https://mypage.bizcomfort.jp/unlock/entry/a0KRB000018nb3q2AA/',
  );

  test('セッションが無いときは保存済みの情報で入力し、確定後はセッションを使う', () async {
    final MemoryCredentialRepository repository = MemoryCredentialRepository();
    await repository.write(credentials);
    final FakeLoginForm form = FakeLoginForm();
    final FakeUnlockSession session = FakeUnlockSession(hasSession: false);
    var confirmed = false;

    await LoginRunner().open(
      repository: repository,
      url: unlockUrl,
      form: form,
      session: session,
      confirm: () async {
        confirmed = true;
        expect(session.usedCookieSession, isFalse);
      },
    );

    expect(confirmed, isTrue);

    expect(form.filledEmail, 'member@example.com');
    expect(form.filledPassword, 'secret');
    expect(session.usedCookieSession, isTrue);
    expect(session.opened, unlockUrl);
  });

  test('セッションが残っていればパスワードを入力しない', () async {
    final MemoryCredentialRepository repository = MemoryCredentialRepository();
    await repository.write(credentials);
    final FakeLoginForm form = FakeLoginForm();
    final FakeUnlockSession session = FakeUnlockSession(hasSession: true);

    await LoginRunner().open(
      repository: repository,
      url: unlockUrl,
      form: form,
      session: session,
      confirm: () async => fail('confirm should not run'),
    );

    expect(form.filledEmail, isNull);
    expect(session.usedCookieSession, isTrue);
  });

  test('別サイトには入力しない', () async {
    final MemoryCredentialRepository repository = MemoryCredentialRepository();
    await repository.write(credentials);
    final FakeLoginForm form = FakeLoginForm();

    expect(
      () => LoginRunner().open(
        repository: repository,
        url: Uri.parse('https://example.com/unlock/entry/id/'),
        form: form,
        session: FakeUnlockSession(hasSession: false),
        confirm: () async {},
      ),
      throwsA(isA<InvalidUnlockUrl>()),
    );
    expect(form.filledEmail, isNull);
  });
}
```

`FakeLoginForm` と `FakeUnlockSession` はこのテストファイルに書く。`confirm` の中で `usedCookieSession` がまだ false であることも、上のテストが固定する。

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/page/scan/login_runner_test.dart`

Expected: FAIL。`login_runner.dart` が無い。

- [ ] **Step 3: Write minimal implementation**

`lib/page/scan/login_runner.dart` に次を置く。

```dart
import 'package:bizcomfort_checkin/page/scan/unlock_url.dart';
import 'package:bizcomfort_checkin/domain/credentials.dart';

class InvalidUnlockUrl implements Exception {
  InvalidUnlockUrl(this.url);

  final Uri url;
}

abstract class LoginFormTarget {
  void fill({required String email, required String password});
}

abstract class UnlockSession {
  bool get hasSession;

  Future<void> open(Uri url);

  void useCookieSession();
}

class LoginRunner {
  Future<void> open({
    required CredentialRepository repository,
    required Uri url,
    required LoginFormTarget form,
    required UnlockSession session,
    required Future<void> Function() confirm,
  }) async {
    if (!isBizcomfortUnlockUrl(url)) {
      throw InvalidUnlockUrl(url);
    }
    if (session.hasSession) {
      session.useCookieSession();
      await session.open(url);
      return;
    }
    final Credentials? credentials = await repository.read();
    if (credentials == null) {
      throw StateError('credentials are missing');
    }
    form.fill(email: credentials.email, password: credentials.password);
    await confirm();
    session.useCookieSession();
    await session.open(url);
  }
}
```

`confirm` が返るまで `useCookieSession` も `open` もしない。この順は上のテストの「確定後はセッションを使う」で、`confirm` の中から `session.usedCookieSession` がまだ false であることを追加の expect で固定する。

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/page/scan/login_runner_test.dart`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/page/scan/login_runner.dart test/page/scan/login_runner_test.dart
git commit -m "$(cat <<'EOF'
feat(mobile): reuse the WebView session after one login

EOF
)"
```

---

### Task 2: WebView で解除し、成功と失敗をログに残す

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Create: `docs/tasks/20261026-000452_mvp-implementation/contexts/investigations/login-form.md`
- Create: `lib/page/scan/bizcomfort_form.dart`
- Create: `lib/page/scan/unlock_webview.dart`
- Modify: `lib/components/checkin_tabs.dart`
- Test: `test/page/scan/unlock_flow_test.dart`

**Interfaces:**
- Consumes: `LoginRunner`、`CredentialRepository`、`UnlockLogRepository`、`ScanPage.onUnlockUrl`。画面はこれらを受け取らない。`AppWire` が解除 use case のコンストラクタに渡し、スキャン画面にはその use case だけを渡す
- Produces: 読み取りからログまでの一連。成功は `UnlockStatus.success`、失敗は `UnlockStatus.failed` とポップアップ。WebView は表示しない

- [x] **Step 1: Record the login form selectors**

記録済み: `contexts/investigations/login-form.md`。

- email: `#id_email`
- password: `#id_password`
- submit: `input.form-btn`

未ログインの解除 URL は `302` で `/login?next=<元のパス>` になる。セッションが生きているかは、この移動が起きたかで判断する。`bizcomfort_form.dart` の定数はこの三つのセレクタにする。

- [ ] **Step 2: Write the failing widget test**

`CheckinTabs` にフェイクの `UnlockSession` を注入し、ドア URL を流したときログに 1 件増えることをテストする。セッションが無く、`confirm` 前はログが空。確定後に `status` が `UnlockStatus.success` の記録が 1 件。`open` が例外を投げたら `UnlockStatus.failed` が 1 件で、ダイアログに「解除に失敗しました」が出る。WebView を見つける widget は無い。フェイクがエラー文を返したときだけ、その文もダイアログにある。エラー文が空なら「解除に失敗しました」以外のエラー文は出ない。

セレクタ定数は Step 1 の三つの文字列と一致するテストを `test/page/scan/bizcomfort_form_test.dart` に書く。Step 1 のファイルが空ならこのテストは失敗したまま止める。

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/page/scan`

Expected: FAIL。WebView 側の実装が無い。

- [ ] **Step 4: Add the WebView package and wire the scan tab**

```bash
flutter pub add flutter_inappwebview
```

`InAppWebView` は `Offstage` に置いたままにする。失敗しても外さない。`onLoadStop` の URL の host が `mypage.bizcomfort.jp` で scheme が `https` のときだけ、Step 1 のセレクタで `evaluateJavascript` し、メールアドレスとパスワードを入れる。確定はアプリの「ログイン」ボタンで、仕様の「ユーザーがログインを確定する」に対応する。押したあとは同じ WebView のクッキーを使い、読み取った URL を `loadUrl` する。

解除ページに拠点名またはドア名が出たら `UnlockStatus.success`。ページがエラーを出したら、または host が違うなら `UnlockStatus.failed`。失敗のときは読み取りタブに留まり、`AlertDialog` で「解除に失敗しました」と出す。ページ本文からエラー文を取り出せたときだけ、同じダイアログにその文を足す。取り出せなければ足さない。

`onGeolocationPermissionsShowPrompt` は、origin が `https://mypage.bizcomfort.jp` かつアプリの位置情報が許可済みのときだけ `GeolocationPermissionShowPromptResponse(allow: true, retain: true)` を返す。それ以外は `allow: false`。OS の許可ダイアログはアプリ側の「アクセス許可」に任せ、このコールバックからは出さない。

結果は `UnlockLogRepository.add` する。時刻は `DateTime.now()`。成功でも失敗でも 1 件追加する。緯度経度が取れなければ null、市区町村は `NOT_PERMITTED` または `FAILED` の規則に従う。

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test`

Expected: PASS

Run: `flutter analyze --fatal-infos`

Expected: No issues found

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/page/scan lib/components/checkin_tabs.dart test/page/scan docs/tasks/20261026-000452_mvp-implementation/contexts/investigations/login-form.md
git commit -m "$(cat <<'EOF'
feat(mobile): unlock the door from a scanned URL

EOF
)"
```
