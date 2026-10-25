import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/page/scan/unlock_url.dart';

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
