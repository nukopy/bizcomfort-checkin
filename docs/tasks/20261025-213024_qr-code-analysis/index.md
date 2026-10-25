# QR コード解析

洗足池ブース ① の入室用・退室用 QR が指す URL を確定する。このタスクは終了。アプリ実装は [MVP 実装](../20261026-000452_mvp-implementation/index.md) に分ける。

## 状態

- 調査: 終了。結果は [contexts/investigations/door-qr-urls.md](contexts/investigations/door-qr-urls.md)
- 計画: [plan-01-decode-door-qr.md](plan-01-decode-door-qr.md) は実行済み

## 入力

プレートの表記はどちらも「BIZcomfort洗足池」「①」「1分プラン 7円」。上部の「ライトプラン会員はカードキーをタッチ」は別手段で、この QR の対象外。

| 用途 | ファイル | プレートの文字 |
| --- | --- | --- |
| 入室 | [contexts/sources/entry-senzokuike-booth-1.jpg](contexts/sources/entry-senzokuike-booth-1.jpg) | 入室用 |
| 退室 | [contexts/sources/exit-senzokuike-booth-1.jpg](contexts/sources/exit-senzokuike-booth-1.jpg) | 退室用 |

退室側の写真は QR 中央に照明の反射がある。全面をそのままデコードして空なら、切り出しと二値化に進む。

## テスト用の表示

入室・退室の QR 写真を置くだけ。

- [contexts/test/door-qr.md](contexts/test/door-qr.md)

## 成果物

[contexts/investigations/door-qr-urls.md](contexts/investigations/door-qr-urls.md)

記録すること:

- 入室・退室それぞれの完全な URL
- scheme / host / path / query / fragment
- 二つの差分（パスのどこが入れ替わり、どこが共通か）
- 写真から分からないこと。ログインが要るか、ID がこのブース固有か、他店舗で形が変わるか

## 範囲外

- URL へのアクセス、ログイン、ドア解除
- 認証情報の記録
- Flutter / iOS アプリの変更
