# Pronunciation Tuning (Japanese Environment)

英語を自動で切り替えられない場合、頻出英単語を置換するのが現実的です。

## 置換テーブル（Orca + spd-say 両方に効く）

### 管理ファイル
- `conf/word_replacements.tsv`

例:
```
LINK	リンク
link	リンク
```

### 反映
`openjtalk_say.sh` が自動で読み込むので、編集後に再起動は不要です。
Speech Dispatcher 経由の確認は以下で行えます。

```bash
spd-say -l ja "link"
```

## 補足
- 置換は単純な文字列置換です。
- 置換対象が意図せず変わる場合は、表を調整してください。
