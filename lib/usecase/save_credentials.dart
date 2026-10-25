import 'package:bizcomfort_checkin/domain/credentials.dart';

class SaveCredentials {
  const SaveCredentials(this._repository);

  final CredentialRepository _repository;

  Future<void> call(Credentials credentials) => _repository.write(credentials);
}
