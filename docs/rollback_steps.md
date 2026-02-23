# Orca で Open JTalk を使うための設定手順と戻し方

この手順は、ユーザー設定の Speech Dispatcher に Open JTalk モジュールを追加して
Orca から利用できるようにするためのものです。システム全体は変更せず、
ユーザー設定のみを変更します。

## 事前確認
- Open JTalk が動作することを確認済みであること
  - 例: `echo "これはテストです。" | scripts/openjtalk_say.sh`
  - 例: `spd-say -l ja "これはテストです。"`

## 変更対象
- `~/.config/speech-dispatcher/modules/openjtalk-generic.conf`（新規作成/更新）
- `~/.config/speech-dispatcher/modules/espeak-ng.conf`（必要に応じてコピー）
- `~/.config/speech-dispatcher/speechd.conf`（追記・変更）
- `conf/word_replacements.tsv`（置換テーブル）

## 実施手順（変更）
1. 設定ディレクトリの作成
```bash
mkdir -p ~/.config/speech-dispatcher/modules
```

2. Open JTalk モジュール設定の配置
```bash
cp /home/shibata/Internal/dev/orca-jtalk/conf/openjtalk-generic.conf ~/.config/speech-dispatcher/modules/
```

3. espeak-ng 設定のコピー（英語切替が必要な場合）
```bash
cp /etc/speech-dispatcher/modules/espeak-ng.conf ~/.config/speech-dispatcher/modules/
```

4. 既存設定のバックアップ
```bash
cp ~/.config/speech-dispatcher/speechd.conf ~/.config/speech-dispatcher/speechd.conf.bak.$(date +%Y%m%d-%H%M%S)
```

5. `speechd.conf` の編集（追記 or 変更）
以下を `speechd.conf` に追加または更新します。
```
AddModule "openjtalk" "sd_generic" "openjtalk-generic.conf"
AddModule "espeak-ng" "sd_espeak-ng" "espeak-ng.conf"
LanguageDefaultModule "ja" "openjtalk"
LanguageDefaultModule "en" "espeak-ng"
DefaultModule espeak-ng
```
既に同等の設定がある場合は差し替えます。

6. Speech Dispatcher を再起動
```bash
systemctl --user restart speech-dispatcher
```

7. 置換テーブルの編集（任意）
`conf/word_replacements.tsv` を編集します。

8. Orca から音声出力を確認
- Orca の設定で音声サーバーが Speech Dispatcher になっていること
- 日本語読み上げが Open JTalk になること

## 戻し方（ロールバック）
1. `speechd.conf` をバックアップに戻す
```bash
cp ~/.config/speech-dispatcher/speechd.conf.bak.YYYYMMDD-HHMMSS ~/.config/speech-dispatcher/speechd.conf
```
（YYYYMMDD-HHMMSS は実際のバックアップ名に置き換え）

2. モジュール設定を削除（必要に応じて）
```bash
rm ~/.config/speech-dispatcher/modules/openjtalk-generic.conf
rm ~/.config/speech-dispatcher/modules/espeak-ng.conf
```

3. Speech Dispatcher を再起動
```bash
systemctl --user restart speech-dispatcher
```

## 補足
- バックアップが複数ある場合は、`ls ~/.config/speech-dispatcher/speechd.conf.bak.*` で一覧できます。
- 問題がなければ、元の `DefaultModule`（例: `espeak-ng` など）に戻すだけでも構いません。
