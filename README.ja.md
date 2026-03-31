# speedtest_swiftbar

`networkQuality` を定期実行し、現在の Wi-Fi SSID と一緒にログへ記録して、直近の結果を SwiftBar のメニューバーに表示する macOS 用プラグインです。

English README: [README.md](./README.md)

## 特徴

- SwiftBar の実行間隔設定で、たとえば 10 分ごとに計測できる
- `networkQuality` の結果を接続中の SSID とセットで記録できる
- 最近の macOS で SSID 取得に必要になる位置情報権限を、小さな補助アプリで扱う
- 現在ログと過去ログを分けて保存できる

## ディレクトリ構成

```text
plugin/
  260331_speedtest_swiftbar.sh
helper/
  WiFiSSIDHelper/
    main.swift
    Info.plist
    build.sh
    build/
      WiFiSSIDHelper.app
logs/
  current/
  archive/
```

## 必要なもの

- macOS
- SwiftBar
- Xcode Command Line Tools
- `networkQuality` コマンドが使える環境

## セットアップ

1. 補助アプリをビルドします。

```bash
cd /path/to/speedtest_swiftbar
./helper/WiFiSSIDHelper/build.sh
```

2. 補助アプリを 1 回起動して、位置情報アクセスを許可します。

```bash
open ./helper/WiFiSSIDHelper/build/WiFiSSIDHelper.app
```

3. SwiftBar のプラグインディレクトリへシンボリックリンクを作成します。

```bash
ln -sf "$PWD/plugin/260331_speedtest_swiftbar.sh" \
  "$HOME/.swiftbar/speedtest_swiftbar.10m.sh"
```

4. SwiftBar をリフレッシュします。

## 補足

- 最近の macOS では、シェルコマンドだけだと SSID が `<SSID Redacted>` になったり、空になったりすることがあります。
- そのため、このリポジトリでは `WiFiSSIDHelper.app` を使って SSID を取得します。
- プラグインはシンボリックリンク先ではなく実体パスを解決するので、`~/.swiftbar/` 経由で動かしても `helper` と `logs` を正しく参照できます。
- 現在のログは `logs/current/` に書き込みます。
- 過去ログは `logs/archive/` に置いています。

## トラブルシュート

SSID が `Unknown` のままになる場合は、次を確認してください。

1. 補助アプリをもう一度開く
2. `システム設定 > プライバシーとセキュリティ > 位置情報サービス` に補助アプリが出ているか確認する
3. `helper/WiFiSSIDHelper/build/WiFiSSIDHelper.app` が存在するか確認する
4. 一度プラグインを直接実行する

```bash
"$HOME/.swiftbar/speedtest_swiftbar.10m.sh"
```

`networkQuality` が失敗した場合、空欄ではなく `N/A` を記録するようにしています。

## ライセンス

MIT ライセンスです。詳細は [LICENSE](./LICENSE) を参照してください。
