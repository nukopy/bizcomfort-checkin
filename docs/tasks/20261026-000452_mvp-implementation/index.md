# MVP 実装

仕様は [docs/spec/mvp_20261026-000213.md](../../spec/mvp_20261026-000213.md)。ドア URL の調査は終了した [QR コード解析](../20261025-213024_qr-code-analysis/index.md) を使う。

このタスクは実装計画まで。パッケージの追加とアプリの変更は、各 plan のレビュー後に行う。

## 状態

- 計画: 作成済み。実装は未着手
- 順序: plan-01 から順に。後ろの plan は前の plan が緑になってから

## 計画

1. [plan-01-three-tabs.md](plan-01-three-tabs.md) — 三タブ。起動直後は QR コード読み取り
2. [plan-02-credentials.md](plan-02-credentials.md) — 設定画面と、暗号化した認証情報の保存
3. [plan-03-unlock-log.md](plan-03-unlock-log.md) — 当日の月のログ。成功と失敗の `status`、月からさかのぼり、詳細で URL と緯度経度を見る。設定に位置情報のアクセス許可
4. [plan-04-qr-scanner.md](plan-04-qr-scanner.md) — 起動と同時に動くアプリ内 QR リーダー
5. [plan-05-webview-login.md](plan-05-webview-login.md) — WebView でログインし、以降はセッションで解除する

## ディレクトリ

タブバーは常に表示する。ページ遷移でタブを消さない。解除の WebView は読み取りタブの裏に置き、失敗しても画面には出さない。失敗はポップアップで知らせる。

- `lib/domain/` — モデルと repository の interface
- `lib/repository/` — repository の実装。保存の仕方はこの中に閉じる
- `lib/usecase/` — 画面が呼ぶ操作。コンストラクタで repository を受け取る
- `lib/wire/` — 起動時に repository を作り、use case を組み立て、画面へ渡す
- `lib/components/` — 共通 UI。三タブの殻はここ
- `lib/page/scan/` — 初期タブ。読み取りと、その場のログイン
- `lib/page/log/` — ログ
- `lib/page/setting/` — メールアドレス、パスワード、位置情報のアクセス許可

## ファイル

| ファイル | 責任 | 入る plan |
| --- | --- | --- |
| `lib/constants.dart` | `appReleaseDate`。ログで選べる最古の月 | 記載済み |
| `lib/main.dart` | `AppWire` を作って `MyApp` に渡す | 01 で起動、02 以降で wire を足す |
| `lib/wire/app_wire.dart` | repository と use case の組み立て | 02 から |
| `lib/components/checkin_tabs.dart` | 三タブと初期選択 | 01 |
| `lib/page/scan/scan_page.dart` | 読み取りタブ | 01 で枠、04 でリーダー |
| `lib/page/log/log_page.dart` | 月ごとのログ一覧 | 01 で枠、03 で中身 |
| `lib/page/log/log_detail_page.dart` | 1 件の URL と緯度経度 | 03 |
| `lib/page/setting/setting_page.dart` | メールアドレス、パスワード、位置情報のアクセス許可 | 01 で枠、02 で保存、03 でアクセス許可 |
| `lib/usecase/watch_location_permission.dart` | 設定タブに出す位置情報の許可状態 | 03 |
| `lib/domain/credentials.dart` | `Credentials` と `CredentialRepository` | 02 |
| `lib/repository/secure_credential_repository.dart` | OS ストレージへの保存 | 02 |
| `lib/domain/unlock_record.dart` | `UnlockRecord` と `UnlockLogRepository` | 03 |
| `lib/repository/memory_unlock_log_repository.dart` | ログのメモリ実装 | 03 |
| `lib/page/scan/unlock_url.dart` | ドア URL の判定 | 04 |
| `lib/page/scan/login_runner.dart` | ログイン手順とセッション再利用 | 05 |

## 実装時の制約

- 検証は `flutter test`。通ったら `flutter analyze --fatal-infos`
- コミットは Conventional Commits。scope は `mobile`
- `flutter_secure_storage` は plan-02、`geolocator` は plan-03、`mobile_scanner` は plan-04、`flutter_inappwebview` は plan-05 で入れる。それより前に入れない
- ログにメールアドレスとパスワードを書かない
- 画面は use case だけを呼ぶ。repository は wire が use case のコンストラクタに渡す。画面へは出さない
- タブ選択や入力中の文字は `State` が持つ。保存やログの更新は use case が行う
- 解除してよい URL は `https://mypage.bizcomfort.jp/unlock/entry/` または `.../unlock/exit/` に続くものだけ
- ログインフォームのセレクタは `#id_email`、`#id_password`、`input.form-btn`。plan-05 の調査に記録済み
- ドアを開けてよいかの近接判定はページ側のままにする。アプリは解除時の緯度経度をログに残し、市区町村名へ引く
- 解除の成功と失敗はどちらもログに残す。`status` は `SUCCESS` または `FAILED`
- 失敗時の WebView は出さない。ポップアップは「解除に失敗しました」。ページからエラー文を取れたときだけ足す
- WebView の位置情報応答は `https://mypage.bizcomfort.jp` に限り、アプリの位置情報が許可済みのときだけ許可する。OS の許可ダイアログはアプリ側で先に出す
