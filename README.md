# Orca + Open JTalk (user-space experiment)

This repository contains a user-space integration of Open JTalk with Speech Dispatcher
so that Orca can use Japanese TTS.

## 日本語ドキュメント
See `README_JA.md`.

## Layout
- conf/: Speech Dispatcher module configuration
- scripts/: wrapper scripts

## Quick start (Ubuntu)
This environment uses `sd_generic` to call Open JTalk.

1. Clone:
```
git clone https://github.com/jidaikobo-shibata/orca-jtalk <install-path>
cd <install-path>
```

2. Link the module config (recommended):
```
mkdir -p ~/.config/speech-dispatcher/modules
ln -s <install-path>/conf/openjtalk-generic.conf ~/.config/speech-dispatcher/modules/openjtalk-generic.conf
```

3. Add to `~/.config/speech-dispatcher/speechd.conf`:
```
AddModule "openjtalk" "sd_generic" "openjtalk-generic.conf"
LanguageDefaultModule "ja" "openjtalk"
DefaultModule openjtalk
```

4. Restart and test:
```
systemctl --user restart speech-dispatcher
spd-say -l ja "これはテストです。"
```

## Pronunciation tuning (recommended)
Use `conf/word_replacements.dist.tsv` for default replacements and
`conf/word_replacements.local.tsv` for your own overrides. The wrapper script
applies both automatically for Orca and spd-say, and `local` can override `dist`.

## Orca note
At the moment, automatic language switching based on context is not available.

## Wrapper script
`scripts/openjtalk_say.sh` reads text from stdin, applies replacements,
then generates a wav file via `open_jtalk` and plays it.

If the dictionary or voice path differs from defaults, set:
- `OPENJTALK_DICT`
- `OPENJTALK_VOICE`

## Text logging (optional)
If `OPENJTALK_LOG_TEXT=1` is enabled in `conf/openjtalk-generic.conf`,
logs are written daily and the latest log is available at:
```
tail -f <install-path>/logs/openjtalk_text.log
```

## Speed tuning
Set `OPENJTALK_SPEED` in `conf/openjtalk-generic.conf`.
Default is `1.0`, and larger values are faster.
After changing, restart:
```
systemctl --user restart speech-dispatcher
```

### Local-only speed setting
Create `conf/openjtalk-generic.local.conf` for your own environment and
link it in `~/.config/speech-dispatcher/modules/`.

## Browser note
At the moment, **structural navigation such as heading skip is confirmed only in Firefox**.
Chrome / Chromium may not support the same navigation, so Firefox is recommended.
