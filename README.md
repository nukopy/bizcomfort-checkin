# bizcomfort-checkin

## 概要

シェアオフィス BIZcomfort のチェックインシステムを便利にするためのモバイルアプリ

## 解決する課題

BIZcomfort のドア解除は、部屋の QR コードを読み取るところから始まる。いまの QR が開くのはログインページだけで、そこから先は入室のたびに同じ手作業になる。

1. iPhone のカメラ、または QR コードリーダーでコードを読む
2. モバイルブラウザが起動し、その場のログインページが開く
3. メールアドレスとパスワードを入力する
4. ログインできて、やっとドアを解除できる

解除そのものより、そこへ至る手順の方が長い。カメラアプリからブラウザへ渡り、認証情報を打ち直す。この往復が、毎回のチェックインを面倒にしている。

このアプリが目指すのは、QR コードを読み取っただけでチェックインが完了する状態。ブラウザを開き、ログインし直す手間を、読み取りの一回にまとめる。

## Prerequisites

- mise 2026.10.17 macos-arm64 (2026-10-20)
- lefthook v2.2.2

## Setup

Check if prerequisites exists in local environment:

```sh
mise --version
lefthook --version
```

Show mise tasks:

```sh
mise tasks
```

Install languages and tools:

```sh
# install
mise install

# check versions
dart --version
flutter --version
markdownlint-cli2 --version
```

## Development

- Show available devices

```sh
mise devices
# e.g.
# [devices] $ flutter devices
# Found 3 connected devices:
#   iPhone 17e (mobile) • **** • ios            • com.apple.CoreSimulator.SimRuntime.iOS-27-0 (simulator)
#   macOS (desktop)     • macos                                • darwin-arm64   • macOS 26.6 25G72 darwin-arm64
#   Chrome (web)        • chrome                               • web-javascript • Google Chrome 156.0.8078.47
```

- Run the app on the selected device

```sh
mise dev -d "iPhone 17e"
```

- Format

```sh
mise format
```

- Lint

```sh
mise lint
```

- Test

```sh
mise test
```

- Check (Format, Lint, Test)

```sh
mise run check
```
