import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/repository/memory_credential_repository.dart';
import 'package:bizcomfort_checkin/usecase/load_credentials.dart';
import 'package:bizcomfort_checkin/usecase/save_credentials.dart';

class AppWire {
  AppWire(CredentialRepository repository)
    : loadCredentials = LoadCredentials(repository),
      saveCredentials = SaveCredentials(repository);

  factory AppWire.memory() => AppWire(MemoryCredentialRepository());

  final LoadCredentials loadCredentials;
  final SaveCredentials saveCredentials;
}
