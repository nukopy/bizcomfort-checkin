# Development Workflow

以下に本プロジェクトにおける開発のワークフローを示す。

## 全体像

**機能単位に分解し、1単位ずつ実装して、green になったらコミットする**。これを繰り返して機能を積み上げる。
各ステップは [superpowers](https://github.com/obra/superpowers) のスキルで駆動する（各スキルの概要は後述「Superpowers Guidelines」を参照）。ステップごとに使用するスキルをインデントで示す。

1. **分解**：タスクを機能単位（＝コミット境界）に分ける。
   - `brainstorming` — 設計を精緻化する
   - `using-git-worktrees` — 隔離した作業環境を用意する
   - `writing-plans` — 小さなタスクに分割した計画を作る
2. **実装**：1単位だけ実装する。
   - `subagent-driven-development` / `executing-plans` — 計画を実行する。特に指示がない場合はデフォルトで `subagent-driven-development` を使用する。
   - `test-driven-development` — RED-GREEN-REFACTOR で実装する
3. **検証**：その単位がテスト・lint を通る（green）ことを確認する。
   - `test-driven-development` — テストで green を確認する
   - `requesting-code-review` — 計画に照らしてレビューする
4. **コミット**：検証が通ったら git でステージングし、コミットメッセージを Conventional Commits 形式で入力しコミット。
5. 次の単位へ。**1〜5 を繰り返す**。すべてのタスクが完了したら：
   - `finishing-a-development-branch` — テスト確認・マージ / PR などの後処理をする

各コミットがテスト通過済みの完結単位になり、レビュー、ロールバックが容易になる。粒度の判断を一番安い計画時に行える。

## Superpowers Guidelines

[superpowers](https://github.com/obra/superpowers) の basic workflow に登場するスキルとその概要：

- `brainstorming` — コードを書く前に有効化。質問を通じて曖昧なアイデアを精緻化し、代替案を検討し、設計をセクションごとに提示して検証する。設計ドキュメントを保存する。
- `using-git-worktrees` — 設計承認後に有効化。新しいブランチ上に隔離されたワークスペースを作成し、プロジェクトのセットアップを実行、クリーンなテストベースラインを確認する。
- `writing-plans` — 承認された設計とともに有効化。作業を小さなタスク（各2〜5分）に分割する。各タスクは正確なファイルパス・完全なコード・検証手順を持つ。
- `subagent-driven-development` / `executing-plans` — 計画とともに有効化。タスクごとに新しいサブエージェントを割り当て、2段階レビュー（仕様適合 → コード品質）を行う。または人間のチェックポイントを挟みながらバッチ実行する。
- `test-driven-development` — 実装中に有効化。RED-GREEN-REFACTOR を強制する：失敗するテストを書く → 失敗を確認 → 最小限のコードを書く → 成功を確認 → コミット。テストより前に書いたコードは削除する。
- `requesting-code-review` — タスク間で有効化。計画に照らしてレビューし、問題を重大度別に報告する。重大な問題は進行をブロックする。
- `finishing-a-development-branch` — タスク完了時に有効化。テストを確認し、選択肢（マージ / PR / 保持 / 破棄）を提示し、worktree をクリーンアップする。

エージェントはあらゆるタスクの前に関連スキルを確認する。これらは推奨ではなく必須のワークフロー。

## 計画ドキュメントの作成（writing-plans × task-creation ルール）

`writing-plans` で実装計画を起こす際は、`.claude/rules/task-creation.mdc`（`.cursor/rules/task-creation.mdc` と同内容）の task ディレクトリ規約に従う。

- 配置: `docs/tasks/yyyymmdd-hhmmss_<title>/` に作る。**1 つの task dir は複数の plan ドキュメントを持てる**（大きなロードマップ index ＋ `plan-<id>-<name>.md` を随時追加）。
- 中身: plan は writing-plans 形式（bite-sized な RED-GREEN-REFACTOR タスク、正確なファイルパス・完全なコード・検証コマンド・頻繁コミット）。
- 調査先行: 既存コード・外部仕様の調査は `contexts/investigations/` に保存してから plan を書く。
- レビュー: plan 作成後は**実装前に人間がレビュー**（不可逆操作の前ゲート）。レビュー結果は `reviews/yymmdd-hhmmss-review.md`。
- プレビュー: 作成・更新後は `mo plan-<id>-<name>.md` でブラウザ確認。
- 例: `docs/tasks/20260614-014948_mvp-implementation/`（MVP ロードマップ ＋ 各サブプラン）。

## ワークフローの考え方

このワークフローは「自律性（エージェントの自走時間）」と「精度」を両立させるための設計。背景にある考え方を残す。

- **承認は「前（計画）・後（PR）・不可逆操作」に集約し、コミットごとには止めない。** コミットはローカルで可逆、品質は lefthook ＋ TDD が機械的に担保する。人間の承認が最も効くのは設計・計画。最初の段階で**まとまった範囲（複数機能）を計画・承認**しておくと、その分だけ自走時間が伸びる。
- **「計画を大きくする＝精度が下がる」ではない。** タスク粒度は `writing-plans` が小さく保つ（各2〜5分）。範囲が広くても個々のタスクは細かいまま。精度低下の真因は「機能数」ではなく、(a) 計画の質と (b) 長時間無人実行での誤りの伝播（drift）。精度のために機能を絞る必要はなく、広く承認して自走を最大化してよい。
- **テストは「壊れている」は防ぐが「間違ったものを作った」は防げない。** 仕様からズレたもの（spec drift）はテストを通ってしまう。per-commit で人間が見ない分、`subagent-driven-development` の自動レビュー（仕様適合 → コード品質）で吸収する。これが `executing-plans`（人間チェックポイント）ではなく `subagent-driven-development` を既定にすべき理由。
- **自走を成立させる4点セット**：① 良い計画（`brainstorming` + `writing-plans` に投資）② 自動レビュー（subagent。critical のみ人間にエスカレーション）③ STOP 条件（暴走の遮断器）④ worktree 隔離（丸ごと破棄できる安全なサンドボックス）。
- **STOP 条件**（自走を止めて人間に確認する）：計画の曖昧さ・前提の食い違い、テストが直らない、計画スコープを超える変更、不可逆・破壊的操作（push / merge / 削除 / マイグレーション / secrets）。
- **残る人間ゲート**：完了時に PR でまとめてレビュー（per-commit ではなく per-branch）。push / merge / deploy は常に人間（既存の git ポリシー）。

## Common Development Commands

リポジトリルートの `README.md` を参照。

## Skills

TBD
