import 'dart:async';
import 'dart:convert';

import 'package:bizcomfort_checkin/domain/credentials.dart';
import 'package:bizcomfort_checkin/page/scan/bizcomfort_form.dart';
import 'package:bizcomfort_checkin/page/scan/login_runner.dart';
import 'package:bizcomfort_checkin/usecase/watch_location_permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class UnlockWebHost implements LoginFormTarget, UnlockSession {
  UnlockWebHost(this._permission);

  final LocationPermissionGateway _permission;
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
    await _load(url);
    final WebUri? current = await (await _ready()).getUrl();
    _hasSession = current != null && !current.path.startsWith('/login');
  }

  @override
  Future<void> open(Uri url) => _load(url);

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

  Future<String> pageHtml() async {
    return await (await _ready()).getHtml() ?? '';
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

class WebLoginRunner extends LoginRunner {
  WebLoginRunner(this._web);

  final UnlockWebHost _web;

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
        await _web.submitAndWait();
      },
    );
  }
}
