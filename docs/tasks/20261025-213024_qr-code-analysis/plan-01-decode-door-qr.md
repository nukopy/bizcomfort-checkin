# ドア QR の URL 確定 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 洗足池ブース ① の入室用・退室用 QR の URL を読み、構成と差分を `contexts/investigations/door-qr-urls.md` に残す。

**Architecture:** アプリには依存を足さない。写真二枚をローカルのワンショットでデコードし、結果だけを調査メモに書く。URL へはリクエストしない。

**Tech Stack:** Python 3、ワンショット venv の `opencv-python-headless`。デコード後に venv は捨てる。リポジトリの依存には加えない。

## Global Constraints

- 成果物は `docs/tasks/20261025-213024_qr-code-analysis/contexts/investigations/door-qr-urls.md` のみ。アプリのコード、`pubspec.yaml`、README は変えない。
- 読み取った URL に HTTP リクエストを送らない。ログイン画面も開かない。
- メールアドレス、パスワード、セッションは書かない。
- 調査メモは日本語。URL とパスの部品は原文のまま書く。
- デコードできなかった側を推測で埋めない。失敗した手順と、まだ空である旨を書く。

---

### Task 1: 入室用・退室用 QR をデコードする

**Files:**

- Read: `docs/tasks/20261025-213024_qr-code-analysis/contexts/sources/entry-senzokuike-booth-1.jpg`
- Read: `docs/tasks/20261025-213024_qr-code-analysis/contexts/sources/exit-senzokuike-booth-1.jpg`
- Create: `docs/tasks/20261025-213024_qr-code-analysis/contexts/investigations/door-qr-urls.md`

**Interfaces:**

- Consumes: 上記二枚。入室は「入室用」、退室は「退室用」のプレート。
- Produces: 調査メモ。後続のチェックイン設計が参照する URL 原文と比較表。

- [x] **Step 1: 写真とプレートの対応を確認する**

入室ファイルのプレートに「入室用」、退室ファイルに「退室用」と読めること。どちらも「BIZcomfort洗足池」と丸数字の「1」。違う写真ならここで止める。

- [x] **Step 2: ワンショットのデコード環境を作る**

リポジトリの外に venv を作る。プロジェクトの依存には加えない。

```bash
python3 -m venv /tmp/qrdecode
/tmp/qrdecode/bin/pip install opencv-python-headless
```

- [x] **Step 3: 二枚をデコードする**

作業ディレクトリはリポジトリルート。入室は写真全体で読む。退室は反射で空になることがあるので、空ならグレースケールにして Otsu 二値化し、位置をずらしながら切り出して再試行する。

```bash
/tmp/qrdecode/bin/python - << 'PY'
import cv2

entry_path = "docs/tasks/20261025-213024_qr-code-analysis/contexts/sources/entry-senzokuike-booth-1.jpg"
exit_path = "docs/tasks/20261025-213024_qr-code-analysis/contexts/sources/exit-senzokuike-booth-1.jpg"
det = cv2.QRCodeDetector()

def decode(path):
    img = cv2.imread(path)
    if img is None:
        return ""
    data, _, _ = det.detectAndDecode(img)
    if data:
        return data
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    h, w = gray.shape
    for y0 in range(180, 420, 40):
        for x0 in range(140, 360, 40):
            for size in (280, 340, 420, 500):
                crop = gray[y0:min(h, y0 + size), x0:min(w, x0 + size)]
                if crop.size == 0:
                    continue
                _, th = cv2.threshold(crop, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
                data, _, _ = det.detectAndDecode(th)
                if data:
                    return data
    return ""

print("entry", decode(entry_path))
print("exit", decode(exit_path))
PY
```

Expected: `entry` と `exit` の両方に URL が 1 件ずつ出る。どちらかが空なら、その旨を調査メモに書き、URL を作らない。

- [x] **Step 4: 調査メモを書く**

`docs/tasks/20261025-213024_qr-code-analysis/contexts/investigations/door-qr-urls.md` を、次の見出しで作る。URL は Step 3 の出力をそのまま入れる。

```markdown
# 洗足池ブース ① のドア QR

## 入室

- ファイル: `contexts/sources/entry-senzokuike-booth-1.jpg`
- URL:

## 退室

- ファイル: `contexts/sources/exit-senzokuike-booth-1.jpg`
- URL:

## 構成

| 部品 | 入室 | 退室 |
| --- | --- | --- |
| scheme |  |  |
| host |  |  |
| path |  |  |
| query |  |  |
| fragment |  |  |

path はセグメントに分け、どのセグメントが共通で、どこが入室と退室で入れ替わるかを書く。

## 写真から分からないこと

- この URL を開いたときログインが要るか
- path 内の ID が洗足池ブース ① 固有か
- 他店舗・他ブースで同じ形か
```

- [x] **Step 5: メモを読み返して止める**

確認すること:

- 入室・退室の URL が Step 3 の出力と一致している
- 空だった側を推測で埋めていない
- URL 以外のファイルを変更していない
- ワンショット venv を消す: `rm -rf /tmp/qrdecode`

このタスクはここで終わる。アプリ実装の計画は、このメモをレビューしたあとに別タスクで切る。
