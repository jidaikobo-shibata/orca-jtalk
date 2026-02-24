# Orca + Open JTalk（日本語導入手順 / Ubuntu）

このプロジェクトは、Speech Dispatcher の `sd_generic` を使って Open JTalk を呼び出し、
Orca と `spd-say` の日本語読み上げを実現するための最小構成です。

## 前提環境（Ubuntu）

以下が動く状態を想定しています。
- Orca が起動できること
- Speech Dispatcher がユーザーサービスとして動いていること
- Open JTalk と日本語辞書、HTS音声がインストール済みであること

パッケージ例（Ubuntu）:
```bash
sudo apt install speech-dispatcher open-jtalk open-jtalk-mecab-naist-jdic hts-voice-nitech-jp-atr503-m001
```

## 1. GitHub から取得

```bash
git clone https://github.com/jidaikobo-shibata/orca-jtalk <インストール先>
cd <インストール先>
```

## 2. Speech Dispatcher のモジュール設定

Open JTalk 用のモジュール設定をユーザー設定へリンクします。
リポジトリ側の変更が即反映されるため、シンボリックリンクを推奨します。

```bash
mkdir -p ~/.config/speech-dispatcher/modules
ln -s <インストール先>/conf/openjtalk-generic.conf ~/.config/speech-dispatcher/modules/openjtalk-generic.conf
```

※ `<インストール先>` を移動するとリンクが切れるので、配置場所は固定してください。
※ 1回だけ反映で良い場合は `cp` でも構いません。

## 3. speechd.conf の設定

`~/.config/speech-dispatcher/speechd.conf` に Open JTalk を登録します。

```conf
AddModule "openjtalk" "sd_generic" "openjtalk-generic.conf"
LanguageDefaultModule "ja" "openjtalk"
DefaultModule openjtalk
```

いまのところ、文脈等から言語を判断することはできていません。
英語の自動切り替えは基本的に期待しない前提で運用してください。

## 4. Speech Dispatcher を再起動

```bash
systemctl --user restart speech-dispatcher
```

## 5. 動作確認

```bash
spd-say -l ja "これはテストです。"
```

## Orca の起動方法

### GUI から起動（Ubuntu）
- 「設定」→「アクセシビリティ」を開きます。
- 「常にアクセシビリティメニューを表示する」をオンにします。
- 画面上部のアクセシビリティメニューから「スクリーンリーダ」をオンにします。

### コマンドラインから起動
```bash
orca
```

設定画面を開く場合:
```bash
orca --setup
```

## 6. 読み上げの置換（おすすめ）

置換ルールは `dist` と `local` に分かれています。
`local` を作ると自分好みに辞書を追加でき、**`dist` を上書き**できます。

- `conf/word_replacements.dist.tsv`
- `conf/word_replacements.local.tsv`

例:
```
LINK	リンク
link	リンク
```

`openjtalk_say.sh` が毎回読み込むので、再起動は不要です。

## 7. 読み上げテキストのログ（任意）

`conf/openjtalk-generic.conf` で `OPENJTALK_LOG_TEXT=1` を有効化している場合、
読み上げテキストは日次ログに追記され、最新ログは
`logs/openjtalk_text.log` から参照できます。

```bash
tail -f <インストール先>/logs/openjtalk_text.log
```

## 読み上げスピードの変更

`conf/openjtalk-generic.conf` で `OPENJTALK_SPEED` を指定すると速度を変更できます。
標準値は `1.0` で、**数値が大きいほど速く**なります。
例:
```conf
"printf %s '$DATA' | OPENJTALK_SPEED=1.2 /path/to/openjtalk_say.sh"
```

変更後は反映のため、`speech-dispatcher` を再起動してください。
```bash
systemctl --user restart speech-dispatcher
```

### ローカル専用の速度設定（例）

配布用はそのままにして、自分の環境だけ速度を変えたい場合は、
`conf/openjtalk-generic.local.conf` を作って運用できます。

例:
```conf
GenericExecuteSynth \
"printf %s '$DATA' | OPENJTALK_LOG_TEXT=1 OPENJTALK_SPEED=2.5 /path/to/openjtalk_say.sh"
```

ユーザー設定側ではローカル版へリンクします。
```bash
ln -s <インストール先>/conf/openjtalk-generic.local.conf ~/.config/speech-dispatcher/modules/openjtalk-generic.conf
systemctl --user restart speech-dispatcher
```

## トラブルシュート

### Open JTalk の辞書が見つからない
`openjtalk_say.sh` は以下のパスを探します。
- `/var/lib/mecab/dic/open-jtalk/naist-jdic`
- `/usr/share/mecab/dic/open-jtalk/naist-jdic`

異なる場合は `OPENJTALK_DICT` を設定してください。

### 音声モデルが見つからない
`openjtalk_say.sh` は以下のパスを探します。
- `/usr/share/hts-voice/nitech-jp-atr503-m001/nitech_jp_atr503_m001.htsvoice`
- `/usr/share/hts-voice/mei/mei_normal.htsvoice`

異なる場合は `OPENJTALK_VOICE` を設定してください。
