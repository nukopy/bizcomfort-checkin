# WebView の位置情報

2026-10-26 に、`flutter_inappwebview` がページの Geolocation 要求へ応答できるかを確認した。パッケージはこの時点では未導入。

## 二段ある

1. OS の許可。iOS は Core Location、Android は location permission。これはアプリがユーザーに求める。WebView のコールバックでは付与できない。
2. ページ（origin）への応答。サイトが Geolocation API を呼んだとき、その origin に許可するかをアプリが返す。

2 を許可しても、1 が無ければページは座標を取れない。

## アプリから返せる範囲

`flutter_inappwebview` の `onGeolocationPermissionsShowPrompt` が 2 の入口である。戻り値は `GeolocationPermissionShowPromptResponse` で、`allow` と `origin` と `retain` を持つ。Android 専用だった `androidOnGeolocationPermissionsShowPrompt` は、このコールバックへ置き換え済み。

https://pub.dev/documentation/flutter_inappwebview/latest/flutter_inappwebview/PlatformInAppWebViewWidgetCreationParams/onGeolocationPermissionsShowPrompt.html

iOS では WKWebView が `WKUIDelegate` の位置情報コールバックでアプリに判断を求める。プラグインはこの判断を上のコールバックへ載せる。

https://developer.apple.com/documentation/webkit/wkuidelegate/webview(_:requestgeolocationpermissionfor:initiatedbyframe:decisionhandler:)

このアプリが返す規則は、origin が `https://mypage.bizcomfort.jp` で、かつアプリの位置情報がすでに許可されているときだけ `allow: true`、`retain: true`。それ以外は拒否する。

## OS のダイアログはアプリ側で先に出す

WebView 自身にシステムの許可ダイアログを出させない。iOS 26 では、そのダイアログの許可ボタンが押せない報告が開いたままである。

https://github.com/pichillilorenzo/flutter_inappwebview/issues/2831

許可の確認は設定タブの「アクセス許可」と、解除の前のアプリ側の要求で行う。WebView は、すでに許可されているときだけサイトへ応答する。
