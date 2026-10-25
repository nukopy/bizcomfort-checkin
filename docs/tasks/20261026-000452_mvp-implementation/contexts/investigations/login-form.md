# ログインフォーム

2026-10-26 に、未ログインの状態で入室 URL へ GET した。

`https://mypage.bizcomfort.jp/unlock/entry/a0KRB000018nb3q2AA/`

## セッション

セッション用の Cookie が無いと、`302` でログインへ移る。

- 移動先: `/login?next=/unlock/entry/a0KRB000018nb3q2AA/`
- 応答は `Cookie` で変わる（`vary: Cookie`）
- 同時に `csrftoken` Cookie が付く。Django のログイン

セッションが残っているかは、解除 URL を開いた結果で判断する。ログインへ飛ばなければセッションは生きている。飛ばされたら切れている。

## フォーム

ログインページの `form` は `method="POST"`。送り先は表示中のログイン URL。

- email: `#id_email`（`name="email"`、`type="email"`）
- password: `#id_password`（`name="password"`、`type="password"`、`minlength="12"`）
- submit: `input.form-btn`（`type="submit"`、表示は「ログイン」）

hidden の `next` に、元の解除パスが入る。ログイン後はそこへ戻る。

CSRF 用の hidden フィールド名は `csrfmiddlewaretoken`。値はリクエストごとに発行されるので、ここには書かない。
