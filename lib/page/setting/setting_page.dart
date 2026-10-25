import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/usecase/load_credentials.dart';
import 'package:bizcomfort_checkin/usecase/save_credentials.dart';
import 'package:bizcomfort_checkin/usecase/watch_location_permission.dart';
import 'package:flutter/material.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({
    super.key,
    required this.loadCredentials,
    required this.saveCredentials,
    required this.watchLocationPermission,
  });

  final LoadCredentials loadCredentials;
  final SaveCredentials saveCredentials;
  final WatchLocationPermission watchLocationPermission;

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  LocationAccess _access = LocationAccess.needsRequest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Credentials? credentials = await widget.loadCredentials();
    final LocationAccess access = await widget.watchLocationPermission.read();
    if (!mounted) {
      return;
    }
    setState(() => _access = access);
    if (credentials == null) {
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
      primary: false,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _SettingSection(
              icon: Icons.lock_outline,
              title: 'メールアドレスとパスワード',
              children: [
                TextField(
                  key: const Key('email'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'メールアドレス',
                    border: OutlineInputBorder(),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('password'),
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'パスワード',
                    border: OutlineInputBorder(),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    await widget.saveCredentials(
                      Credentials(email: _email.text, password: _password.text),
                    );
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('保存に成功しました'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('保存'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingSection(
              icon: Icons.verified_user_outlined,
              title: 'アクセス許可',
              children: [
                _locationStatus(context),
                if (_access == LocationAccess.needsRequest) ...<Widget>[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      final LocationAccess next = await widget.watchLocationPermission.request();
                      if (mounted) {
                        setState(() => _access = next);
                      }
                    },
                    child: const Text('許可する'),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: widget.watchLocationPermission.openSettings,
                  child: const Text('設定を開く'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationStatus(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool granted = _access == LocationAccess.granted;
    return Row(
      children: [
        Icon(Icons.place_outlined, color: scheme.onSurfaceVariant),
        const SizedBox(width: 12),
        const Expanded(child: Text('位置情報')),
        DecoratedBox(
          decoration: BoxDecoration(
            color: granted ? scheme.primaryContainer : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              granted ? '許可' : '未許可',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: granted ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingSection extends StatelessWidget {
  const _SettingSection({required this.icon, required this.title, required this.children});

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
