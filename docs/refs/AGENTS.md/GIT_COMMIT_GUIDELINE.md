# Git Commit Guideline

開発中の git の使い方に関するガイドラインです。

## コミット粒度

- **1コミット = 1つの論理変更**（1つの振る舞い、機能の変更 + そのテスト）。
- 機能変更とリファクタを同じコミットに**混ぜない**。整形のみの変更は分ける。
- 依存される側を先にコミットする（**依存順**）。
- 大きすぎ（`feat: 全部実装`）も小さすぎ（1行ごと）も避ける。

## コミットメッセージガイドライン

Conventional Commits に従う。形式は `<type>(<scope>)?: <subject>`（`scope` は任意。例 `server` / `mobile`）。

| type       | 用途                                           |
| ---------- | ---------------------------------------------- |
| `feat`     | 機能追加、バグ修正以外の機能修正               |
| `fix`      | バグ修正                                       |
| `docs`     | ドキュメントのみ                               |
| `style`    | 挙動に影響しない変更（整形・空白など）         |
| `refactor` | 機能追加でもバグ修正でもないコード変更         |
| `perf`     | パフォーマンス改善                             |
| `test`     | テストの追加・修正                             |
| `build`    | ビルド・依存関係（pnpm / wrangler / Xcode 等） |
| `ci`       | CI / フック設定（GitHub Actions / lefthook）   |
| `chore`    | 上記以外の雑多な変更                           |
| `revert`   | コミットの取り消し                             |

- 破壊的変更は `feat!:` のように `!` を付ける。
- 例: `feat(server): add /api/v1/health endpoint` / `fix(mobile): handle empty search result` / `ci: add lefthook hooks`

## 使用可能な git コマンド

確認・ステージ・コミット・ブランチ作成など、非破壊的な操作は自由に使ってよい。

- `git status` / `git diff` / `git log` / `git show` — 状態・差分・履歴の確認
- `git add <path>` — パス指定でのステージ
- `git commit` — コミット（フックを通す）
- `git switch -c <branch>` / `git branch <name>` — ブランチ作成
- `git switch <branch>` / `git checkout <branch>` — ブランチ切替（ファイルは破棄しない）
- `git fetch` — リモートの取得

## 使用禁止な git コマンド

履歴の書き換え・変更の破棄・リモートへの共有を伴うものは、**ユーザーの明示的な指示がない限り絶対に実行しない**。

- `git push`（特に `--force` / `--force-with-lease` は厳禁）— 共有・不可逆
- `git merge` / `git rebase` — 履歴の統合・書き換え
- `git reset`（特に `--hard`）— ステージ / コミット / 作業ツリーの破棄
- `git revert` — コミットの打ち消し
- `git commit --amend` — 既存コミットの書き換え
- `git restore <path>` / `git checkout -- <path>` による未コミット変更の破棄 — 作業の消失
- `git clean -f` / `-fd` — 追跡外ファイルの削除
- `git branch -D` — ブランチの強制削除
- `git stash drop` / `git stash clear` — stash の破棄
- `--no-verify` フラグ — フック（品質ゲート）のスキップ
