import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/repository/secure_credential_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('email と password のキーで往復する', () async {
    final MapSecureKeyValue storage = MapSecureKeyValue();
    final SecureCredentialRepository repository = SecureCredentialRepository(storage);

    await repository.write(const Credentials(email: 'member@example.com', password: 'secret'));

    expect(await storage.read('email'), 'member@example.com');
    expect(await storage.read('password'), 'secret');
    expect(
      await repository.read(),
      const Credentials(email: 'member@example.com', password: 'secret'),
    );
  });
}
