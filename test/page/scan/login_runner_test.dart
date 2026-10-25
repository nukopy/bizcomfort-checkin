import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/page/scan/login_runner.dart';
import 'package:bizcomfort_checkin/repository/memory_credential_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Credentials credentials = Credentials(email: 'member@example.com', password: 'secret');
  final Uri unlockUrl = Uri.parse('https://mypage.bizcomfort.jp/unlock/entry/a0KRB000018nb3q2AA/');

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

class FakeLoginForm implements LoginFormTarget {
  String? filledEmail;
  String? filledPassword;

  @override
  void fill({required String email, required String password}) {
    filledEmail = email;
    filledPassword = password;
  }
}

class FakeUnlockSession implements UnlockSession {
  FakeUnlockSession({required this.hasSession});

  @override
  final bool hasSession;

  bool usedCookieSession = false;
  Uri? opened;

  @override
  Future<void> open(Uri url) async {
    opened = url;
  }

  @override
  void useCookieSession() {
    usedCookieSession = true;
  }
}
