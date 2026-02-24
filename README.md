# Orca + Open JTalk (user-space experiment)

This repository contains a user-space integration of Open JTalk with Speech Dispatcher
so that Orca can use Japanese TTS.

## 日本語ドキュメント
See `docs/README_JA.md`.

## Layout
- conf/: Speech Dispatcher module configuration
- docs/: notes and setup steps
- scripts/: wrapper scripts
- tests/: test helpers
- logs/: logs (if used)

## Quick start (confirmed)
This environment uses `sd_generic` to call Open JTalk.

1. Create `~/.config/speech-dispatcher/modules/openjtalk-generic.conf`:
```
cp /home/shibata/Internal/dev/orca-jtalk/conf/openjtalk-generic.conf ~/.config/speech-dispatcher/modules/
```

2. Copy espeak-ng module config (for English switching):
```
cp /etc/speech-dispatcher/modules/espeak-ng.conf ~/.config/speech-dispatcher/modules/
```

3. Add to `~/.config/speech-dispatcher/speechd.conf`:
```
AddModule "openjtalk" "sd_generic" "openjtalk-generic.conf"
AddModule "espeak-ng" "sd_espeak-ng" "espeak-ng.conf"
LanguageDefaultModule "ja" "openjtalk"
LanguageDefaultModule "en" "espeak-ng"
DefaultModule espeak-ng
```

4. Restart and test:
```
systemctl --user restart speech-dispatcher
spd-say -l ja "これはテストです。"
spd-say -l ja "link"
```

## Pronunciation tuning (recommended)
Use `conf/word_replacements.dist.tsv` for default replacements and
`conf/word_replacements.local.tsv` for your own overrides. The wrapper script
applies both automatically for Orca and spd-say, and `local` can override `dist`.

## Orca note
Orca only switches language when the application exposes the `language` text attribute.
If it doesn't, Orca won't send `SET LANGUAGE`, so auto switching won't happen.

## Wrapper script
`scripts/openjtalk_say.sh` reads text from stdin, applies replacements,
then generates a wav file via `open_jtalk` and plays it.

If the dictionary or voice path differs from defaults, set:
- `OPENJTALK_DICT`
- `OPENJTALK_VOICE`
- `OPENJTALK_REPLACE_FILE`
