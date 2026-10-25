import 'package:bizcomfort_checkin/domain/credentials.dart';

class LoadCredentials {
  const LoadCredentials(this._repository);

  final CredentialRepository _repository;

  Future<Credentials?> call() => _repository.read();
}
