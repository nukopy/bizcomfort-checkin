import 'dart:async';
import 'dart:convert';

import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/page/scan/bizcomfort_form.dart';
import 'package:bizcomfort_checkin/page/scan/login_runner.dart';
import 'package:bizcomfort_checkin/page/scan/unlock_page_text.dart';
import 'package:bizcomfort_checkin/page/scan/unlock_trace.dart';
import 'package:bizcomfort_checkin/usecase/watch_location_permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class UnlockWebHost implements LoginFormTarget, UnlockSession {
  UnlockWebHost(this._permission, this._trace);

  final LocationPermissionGateway _permission;
  final UnlockTrace _trace;
  final Completer<InAppWebViewController> _created = Completer<InAppWebViewController>();
  Completer<void>? _loaded;
  bool _hasSession = false;
  String? _email;
  String? _password;

  @override
  bool get hasSession => _hasSession;

  Widget buildView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri('about:blank')),
      initialSettings: InAppWebViewSettings(geolocationEnabled: true),
      onWebViewCreated: (InAppWebViewController controller) {
        if (!_created.isCompleted) {
          _created.complete(controller);
        }
      },
      onLoadStop: (InAppWebViewController controller, WebUri? uri) {
        final Completer<void>? pending = _loaded;
        if (pending != null && !pending.isCompleted) {
          pending.complete();
        }
      },
      onGeolocationPermissionsShowPrompt: (InAppWebViewController controller, String origin) async {
        final Uri? parsed = Uri.tryParse(origin);
        final bool hostOk =
            parsed != null && parsed.scheme == 'https' && parsed.host == 'mypage.bizcomfort.jp';
        final bool allowed = hostOk && await _permission.read() == LocationAccess.granted;
        return GeolocationPermissionShowPromptResponse(
          origin: origin,
          allow: allowed,
          retain: true,
        );
      },
    );
  }

  Future<void> prepare(Uri url) async {
    _trace.add('ログイン状態を確認しています');
    await _load(url);
    final WebUri? current = await (await _ready()).getUrl();
    _hasSession = current != null && !current.path.startsWith('/login');
    _trace.add(_hasSession ? 'ログイン済みです' : 'ログインが必要です');
  }

  @override
  Future<void> open(Uri url) async {
    _trace.add('解錠ページを読み込んでいます');
    await _load(url);
    _trace.add('解錠ページを読み込みました');
  }

  @override
  void useCookieSession() {}

  @override
  void fill({required String email, required String password}) {
    _email = email;
    _password = password;
  }

  Future<void> submitAndWait() async {
    final InAppWebViewController controller = await _ready();
    final WebUri? current = await controller.getUrl();
    if (current == null || current.scheme != 'https' || current.host != 'mypage.bizcomfort.jp') {
      throw StateError('refusing to fill a page outside BIZcomfort');
    }
    final String email = jsonEncode(_email ?? '');
    final String password = jsonEncode(_password ?? '');
    final String emailSelector = jsonEncode(bizcomfortEmailSelector);
    final String passwordSelector = jsonEncode(bizcomfortPasswordSelector);
    final String submitSelector = jsonEncode(bizcomfortSubmitSelector);
    await controller.evaluateJavascript(
      source:
          '''
        (function() {
          var email = document.querySelector($emailSelector);
          var password = document.querySelector($passwordSelector);
          if (email) email.value = $email;
          if (password) password.value = $password;
          var submit = document.querySelector($submitSelector);
          if (submit) submit.click();
        })();
      ''',
    );
    await _nextLoad();
  }

  Future<UnlockPageReading> readSettledPage() async {
    final InAppWebViewController controller = await _ready();
    final DateTime started = DateTime.now();
    String? quiet;
    UnlockPageReading latest = const UnlockPageReading(succeeded: true);
    while (DateTime.now().difference(started) < const Duration(seconds: 16)) {
      final _PageSignals signals = await _readSignals(controller);
      final String signature =
          '${signals.errorShown}|${signals.busy}|${signals.errorText}|${signals.siteName}|${signals.doorName}';
      final bool repeatedQuiet = !signals.busy && quiet == signature;
      quiet = signals.busy ? null : signature;
      final Duration elapsed = DateTime.now().difference(started);
      _trace.add('表示を確認しています（${elapsed.inSeconds}秒）');
      _trace.add(signals.traceLine);
      if (signals.href.isNotEmpty) {
        _trace.add('ページ：${signals.href}');
      }
      latest = signals.reading;
      if (unlockObservationSettled(
        errorShown: signals.errorShown,
        busy: signals.busy,
        elapsed: elapsed,
        repeatedQuiet: repeatedQuiet,
      )) {
        return latest;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    _trace.add('表示の確認を打ち切りました');
    return latest;
  }

  Future<_PageSignals> _readSignals(InAppWebViewController controller) async {
    try {
      final Object? value = await controller.evaluateJavascript(source: _pageSignalsScript);
      return _PageSignals.fromJson(_stringMap(value));
    } catch (_) {
      _trace.add('ページの表示を読めませんでした');
      return const _PageSignals.empty();
    }
  }

  Future<InAppWebViewController> _ready() {
    return _created.future.timeout(const Duration(seconds: 10));
  }

  Future<void> _load(Uri url) async {
    final InAppWebViewController controller = await _ready();
    final Completer<void> done = Completer<void>();
    _loaded = done;
    await controller.loadUrl(urlRequest: URLRequest(url: WebUri(url.toString())));
    await done.future.timeout(const Duration(seconds: 20));
  }

  Future<void> _nextLoad() async {
    final Completer<void> done = Completer<void>();
    _loaded = done;
    await done.future.timeout(const Duration(seconds: 20));
  }
}

const String _pageSignalsScript = r'''
(function() {
  function text(el) {
    return el ? (el.textContent || '').replace(/\s+/g, ' ').trim() : '';
  }
  function shown(el) {
    if (!el) return false;
    var style = window.getComputedStyle(el);
    return style.display !== 'none' && style.visibility !== 'hidden';
  }
  function named(title) {
    var nodes = document.querySelectorAll('.unlock-select-title');
    for (var i = 0; i < nodes.length; i++) {
      if (text(nodes[i]) === title) return text(nodes[i].nextElementSibling);
    }
    return '';
  }
  var error = document.getElementById('error-message');
  var state = document.getElementById('state-message');
  var loader = document.getElementById('loader');
  var errorText = text(error);
  return JSON.stringify({
    errorShown: shown(error) && errorText.length > 0,
    errorText: errorText,
    busy: shown(state) || shown(loader),
    siteName: named('拠点'),
    doorName: named('ドア'),
    href: location.href
  });
})()
''';

class _PageSignals {
  const _PageSignals({
    required this.errorShown,
    required this.errorText,
    required this.busy,
    required this.siteName,
    required this.doorName,
    required this.href,
  });

  const _PageSignals.empty()
    : errorShown = false,
      errorText = '',
      busy = false,
      siteName = '',
      doorName = '',
      href = '';

  final bool errorShown;
  final String errorText;
  final bool busy;
  final String siteName;
  final String doorName;
  final String href;

  factory _PageSignals.fromJson(Map<String, Object?> json) {
    return _PageSignals(
      errorShown: json['errorShown'] == true,
      errorText: json['errorText'] is String ? json['errorText'] as String : '',
      busy: json['busy'] == true,
      siteName: json['siteName'] is String ? json['siteName'] as String : '',
      doorName: json['doorName'] is String ? json['doorName'] as String : '',
      href: json['href'] is String ? json['href'] as String : '',
    );
  }

  UnlockPageReading get reading {
    return UnlockPageReading(
      succeeded: !errorShown,
      errorMessage: errorShown ? errorText : null,
      siteName: siteName,
      doorName: doorName,
    );
  }

  String get traceLine {
    final String place =
        '拠点：${siteName.isEmpty ? 'なし' : siteName} / ドア：${doorName.isEmpty ? 'なし' : doorName}';
    if (errorShown) {
      return 'エラー：表示（$errorText） / $place';
    }
    if (errorText.isEmpty) {
      return 'エラー：なし / $place';
    }
    return 'エラー：非表示（本文「$errorText」） / $place';
  }
}

Map<String, Object?> _stringMap(Object? value) {
  if (value is String && value.isNotEmpty) {
    final Object? decoded = jsonDecode(value);
    return _stringMap(decoded);
  }
  if (value is Map<String, dynamic>) {
    return value.map((String key, dynamic item) => MapEntry<String, Object?>(key, item as Object?));
  }
  if (value is Map) {
    final Map<String, Object?> mapped = <String, Object?>{};
    for (final MapEntry<Object?, Object?> entry in value.entries) {
      final Object? key = entry.key;
      if (key is String) {
        mapped[key] = entry.value;
      }
    }
    return mapped;
  }
  return const <String, Object?>{};
}

class WebLoginRunner extends LoginRunner {
  WebLoginRunner(this._web, this._trace);

  final UnlockWebHost _web;
  final UnlockTrace _trace;

  @override
  Future<void> open({
    required CredentialRepository repository,
    required Uri url,
    required LoginFormTarget form,
    required UnlockSession session,
    required Future<void> Function() confirm,
  }) async {
    await _web.prepare(url);
    await super.open(
      repository: repository,
      url: url,
      form: form,
      session: session,
      confirm: () async {
        await confirm();
        _trace.add('ログイン情報を送信しています');
        await _web.submitAndWait();
        _trace.add('ログイン後のページを開きました');
      },
    );
  }
}
