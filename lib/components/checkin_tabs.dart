import 'dart:async';

import 'package:bizcomfort_checkin/domain/unlock_record.dart';
import 'package:bizcomfort_checkin/page/log/log_page.dart';
import 'package:bizcomfort_checkin/page/scan/scan_page.dart';
import 'package:bizcomfort_checkin/page/scan/unlock_and_record.dart';
import 'package:bizcomfort_checkin/page/scan/unlock_trace.dart';
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
  bool _following = false;
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
    final UnlockRecord? latest = widget.watchUnlockLog.latest;
    if (!mounted) {
      return;
    }
    if (latest != null && latest.url.toString() == url.toString()) {
      final bool proceed = await _confirmRepeatedUrl();
      if (!proceed || !mounted) {
        return;
      }
    }
    if (recorder == null) {
      widget.onUnlockUrl(url);
      return;
    }
    _setCameraOpen(false);
    final UnlockTrace trace = recorder.trace;
    setState(() => _following = true);
    trace.reset();
    trace.add('ページを開いています');
    final UnlockAttempt? attempt = await recorder.call(
      url: url,
      confirm: () async {
        final Completer<void> pending = Completer<void>();
        setState(() => _confirm = pending);
        trace.add('ログインの確認を待っています');
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
    final List<String> lines = List<String>.of(trace.lines);
    setState(() {
      _confirm = null;
      _following = false;
    });
    trace.reset();
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
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                const SizedBox(height: 16),
                const Text('処理の経過'),
                for (final String line in lines) Text('・$line'),
              ],
            ),
          ),
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

  Future<bool> _confirmRepeatedUrl() async {
    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text('最新の解錠記録と同一の QR コードを読み込もうとしています。\nもう一度読み込みますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('読み込む')),
          ],
        );
      },
    );
    return proceed ?? false;
  }

  void _setCameraOpen(bool open) {
    if (_cameraOpen.value == open) {
      return;
    }
    _cameraOpen.value = open;
  }

  void _acceptLogin() {
    widget.unlockAndRecord?.trace.add('ログインボタンを押しました');
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
    final UnlockTrace? trace = widget.unlockAndRecord?.trace;
    final bool waiting = _confirm != null;
    if (!_following && !waiting) {
      return null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_following && trace != null) _traceBox(trace.lines),
        if (waiting) ...[
          const SizedBox(height: 12),
          Row(
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
        ],
      ],
    );
  }

  Widget _traceBox(List<String> lines) {
    return Material(
      color: Colors.white,
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  ),
                  SizedBox(width: 8),
                  Text('処理の経過', style: TextStyle(color: Colors.black)),
                ],
              ),
              for (final String line in lines)
                Text('・$line', style: const TextStyle(color: Colors.black)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final UnlockTrace? trace = widget.unlockAndRecord?.trace;
    if (trace == null) {
      return _scaffold(context);
    }
    return ListenableBuilder(
      listenable: trace,
      builder: (BuildContext context, Widget? child) => _scaffold(context),
    );
  }

  Widget _scaffold(BuildContext context) {
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
              left: -4000,
              top: 0,
              width: 390,
              height: 844,
              child: IgnorePointer(child: widget.hiddenWebView),
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
