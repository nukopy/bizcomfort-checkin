import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/repository/memory_credential_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('書いた認証情報を読める', () async {
    final MemoryCredentialRepository repository = MemoryCredentialRepository();

    expect(await repository.read(), isNull);

    const Credentials credentials = Credentials(email: 'member@example.com', password: 'secret');
    await repository.write(credentials);

    expect(await repository.read(), credentials);
  });
}
