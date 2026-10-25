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
