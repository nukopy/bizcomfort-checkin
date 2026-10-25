import 'dart:async';

import 'package:bizcomfort_checkin/page/log/log_page.dart';
import 'package:bizcomfort_checkin/page/scan/scan_page.dart';
import 'package:bizcomfort_checkin/page/scan/unlock_and_record.dart';
import 'package:bizcomfort_checkin/page/setting/setting_page.dart';
import 'package:bizcomfort_checkin/usecase/load_credentials.dart';
import 'package:bizcomfort_checkin/usecase/save_credentials.dart';
import 'package:bizcomfort_checkin/usecase/watch_location_permission.dart';
import 'package:bizcomfort_checkin/usecase/watch_unlock_log.dart';
import 'package:flutter/material.dart';

class CheckinTabs extends StatefulWidget {
  const CheckinTabs({
    super.key,
    required this.loadCredentials,
    required this.saveCredentials,
    required this.watchUnlockLog,
    required this.watchLocationPermission,
    required this.scanSource,
    required this.onUnlockUrl,
    this.unlockAndRecord,
    this.hiddenWebView,
  });

  final LoadCredentials loadCredentials;
  final SaveCredentials saveCredentials;
  final WatchUnlockLog watchUnlockLog;
  final WatchLocationPermission watchLocationPermission;
  final QrScanSource scanSource;
  final ValueChanged<Uri> onUnlockUrl;
  final UnlockAndRecord? unlockAndRecord;
  final Widget? hiddenWebView;

  @override
  State<CheckinTabs> createState() => _CheckinTabsState();
}

class _CheckinTabsState extends State<CheckinTabs> {
  int _index = 0;
  bool? _hasCredentials;
  Completer<void>? _confirm;
  bool _cancelUnlock = false;
  final ValueNotifier<bool> _cameraOpen = ValueNotifier<bool>(true);
  late final Future<void> _credentialsReady = _loadCredentials();

  @override
  void dispose() {
    _cameraOpen.dispose();
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    final credentials = await widget.loadCredentials();
    if (!mounted) {
      return;
    }
    setState(() {
      _hasCredentials =
          credentials != null && credentials.email.isNotEmpty && credentials.password.isNotEmpty;
    });
  }

  Future<void> _unlock(Uri url) async {
    await _credentialsReady;
    if (_hasCredentials == false) {
      return;
    }
    final UnlockAndRecord? recorder = widget.unlockAndRecord;
    if (recorder == null) {
      widget.onUnlockUrl(url);
      return;
    }
    _setCameraOpen(false);
    final UnlockAttempt? attempt = await recorder.call(
      url: url,
      confirm: () async {
        final Completer<void> pending = Completer<void>();
        setState(() => _confirm = pending);
        await pending.future;
        if (_cancelUnlock) {
          _cancelUnlock = false;
          throw const UnlockCancelled();
        }
      },
    );
    if (!mounted) {
      return;
    }
    setState(() => _confirm = null);
    if (attempt == null) {
      _setCameraOpen(true);
      return;
    }
    if (!context.mounted) {
      return;
    }
    final String message = !attempt.failed
        ? '解錠に成功しました'
        : attempt.errorMessage == null
        ? '解錠に失敗しました'
        : '解錠に失敗しました\nエラー：${attempt.errorMessage}';
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('閉じる')),
          ],
        );
      },
    );
    if (mounted) {
      _setCameraOpen(true);
    }
  }

  void _setCameraOpen(bool open) {
    if (_cameraOpen.value == open) {
      return;
    }
    _cameraOpen.value = open;
  }

  void _acceptLogin() {
    final Completer<void>? pending = _confirm;
    setState(() => _confirm = null);
    pending?.complete();
  }

  void _cancelLogin() {
    _cancelUnlock = true;
    final Completer<void>? pending = _confirm;
    setState(() => _confirm = null);
    pending?.complete();
  }

  Widget? _loginActions() {
    if (_confirm == null) {
      return null;
    }
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(onPressed: _cancelLogin, child: const Text('キャンセル')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(onPressed: _acceptLogin, child: const Text('ログイン')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget scan = Stack(
      children: [
        ScanPage(
          source: widget.scanSource,
          onUnlockUrl: _unlock,
          cameraOpen: _cameraOpen,
          footer: _loginActions(),
        ),
        if (_hasCredentials == false)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                elevation: 6,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'メールアドレス、パスワードが設定されていません',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: () => setState(() => _index = 2),
                        child: const Text('設定する'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    final List<Widget> pages = <Widget>[
      scan,
      Navigator(
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return LogPage(watchUnlockLog: widget.watchUnlockLog, now: DateTime.now());
            },
          );
        },
      ),
      SettingPage(
        loadCredentials: widget.loadCredentials,
        saveCredentials: widget.saveCredentials,
        watchLocationPermission: widget.watchLocationPermission,
      ),
    ];
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.hiddenWebView != null)
            Positioned(
              left: 0,
              top: 0,
              width: 8,
              height: 8,
              child: Offstage(child: widget.hiddenWebView),
            ),
          pages[_index],
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (int index) {
          setState(() => _index = index);
          if (index == 0) {
            _loadCredentials();
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'QRコード読み取り'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'ログ'),
          NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}
