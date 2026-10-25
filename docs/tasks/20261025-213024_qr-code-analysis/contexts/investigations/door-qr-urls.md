# 洗足池ブース ① のドア QR

写真二枚をローカルでデコードした。URL へのリクエストはしていない。

## 入室

- ファイル: `contexts/sources/entry-senzokuike-booth-1.jpg`
- URL: `https://mypage.bizcomfort.jp/unlock/entry/a0KRB000018nb3q2AA/`

## 退室

- ファイル: `contexts/sources/exit-senzokuike-booth-1.jpg`
- URL: `https://mypage.bizcomfort.jp/unlock/exit/a0KRB000018nb3q2AA/`

## 構成

| 部品 | 入室 | 退室 |
| --- | --- | --- |
| scheme | `https` | `https` |
| host | `mypage.bizcomfort.jp` | `mypage.bizcomfort.jp` |
| path | `/unlock/entry/a0KRB000018nb3q2AA/` | `/unlock/exit/a0KRB000018nb3q2AA/` |
| query | なし | なし |
| fragment | なし | なし |

path は 3 セグメントで、末尾にスラッシュがある。

| 順 | 入室 | 退室 | 関係 |
| --- | --- | --- | --- |
| 1 | `unlock` | `unlock` | 共通 |
| 2 | `entry` | `exit` | ここだけ入れ替わる |
| 3 | `a0KRB000018nb3q2AA` | `a0KRB000018nb3q2AA` | 共通。18 文字の ID。中身は未分割 |

入室と退室の差は、2 番目のセグメントが `entry` か `exit` かだけ。ホストも 3 番目の ID も同じ。

## ウェブページの挙動

2026-10-25 に入室 URL を手動で確認した。URL へこちらの環境からリクエストはしていない。退室 URL は同じ形だが、ページ単体の確認はまだない。

3 番目のセグメント `a0KRB000018nb3q2AA` は、URL 上では 1 つの ID のまま分かれていない。ページはこの ID から、次の 2 つを別々に出している。

| 表示 | 値 |
| --- | --- |
| 拠点 | BIZcomfort洗足池 |
| ドア | 洗足池① |

根拠の画面: `contexts/sources/unlock-page-location-and-door.png`

拠点だけの ID とは限らない。この ID が拠点とドアの組を指している可能性がある。URL の文字面からは、どこまでが拠点でどこからがドアかは切れない。

入室 URL を開いたあとの流れ:

1. ログインセッションが残っていれば、追加のログインなしでドアを解除する。
2. セッションが残っていなければログインページへ移る。そこでログインすると、ドア解除まで進む。

ページは GPS を取る。その拠点の近くにいないと、解除できないように見える。判定距離や、位置情報が取れないときの扱いは見ていない。

## まだ分からないこと

- 3 番目の ID が拠点とドアをどう持っているか。1 つの組を指すだけか、文字の並びで分かれているか
- 「近く」の判定距離と、GPS を拒否したときの表示
- 退室 URL も入室と同じセッション・GPS の流れか
- 他の拠点・ドアで ID が変わり、パスの形は同じままか
