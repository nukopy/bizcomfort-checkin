class Credentials {
  const Credentials({required this.email, required this.password});

  final String email;
  final String password;

  @override
  bool operator ==(Object other) {
    return other is Credentials && other.email == email && other.password == password;
  }

  @override
  int get hashCode => Object.hash(email, password);
}

abstract class CredentialRepository {
  Future<Credentials?> read();

  Future<void> write(Credentials credentials);
}
