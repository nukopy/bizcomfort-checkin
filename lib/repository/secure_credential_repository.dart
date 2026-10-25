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
