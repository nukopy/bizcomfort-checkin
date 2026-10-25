import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/usecase/load_credentials.dart';
import 'package:bizcomfort_checkin/usecase/save_credentials.dart';
import 'package:flutter/material.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key, required this.loadCredentials, required this.saveCredentials});

  final LoadCredentials loadCredentials;
  final SaveCredentials saveCredentials;

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Credentials? credentials = await widget.loadCredentials();
    if (!mounted || credentials == null) {
      return;
    }
    _email.text = credentials.email;
    _password.text = credentials.password;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('メールアドレスとパスワード'),
          const SizedBox(height: 16),
          TextField(
            key: const Key('email'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'メールアドレス'),
          ),
          TextField(
            key: const Key('password'),
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'パスワード'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              widget.saveCredentials(Credentials(email: _email.text, password: _password.text));
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
