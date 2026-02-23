# Notes

Goal: integrate Open JTalk as a Speech Dispatcher module so Orca can use Japanese TTS.

## Files
- scripts/openjtalk_say.sh: wrapper to generate and play wav
- conf/openjtalk-generic.conf: sd_generic config for Open JTalk
- conf/word_replacements.tsv: word replacement table (LINK -> リンク)
- tests/test_spd_say.sh: quick test script

## Current setup (user space, confirmed)
This environment uses sd_generic to call Open JTalk.

1. Create `~/.config/speech-dispatcher/modules/openjtalk-generic.conf` from the repo.

2. Edit `~/.config/speech-dispatcher/speechd.conf` and add:
```
AddModule "openjtalk" "sd_generic" "openjtalk-generic.conf"
AddModule "espeak-ng" "sd_espeak-ng" "espeak-ng.conf"
LanguageDefaultModule "ja" "openjtalk"
LanguageDefaultModule "en" "espeak-ng"
DefaultModule espeak-ng
```

3. Restart speech-dispatcher (user service)
```
systemctl --user restart speech-dispatcher
```

4. Word replacements (applies to Orca and spd-say)
- Edit `conf/word_replacements.tsv`
- No rebuild needed; applied by wrapper at runtime

5. Test
```
spd-say -l ja "これはテストです。"
spd-say -l ja "link"
```

## Orca language switching note
Orca only changes language if the application exposes the `language` text attribute.
If a page/app does not expose it, Orca will not send `SET LANGUAGE`, so auto switching
will not happen even when Speech Dispatcher is configured for it.

## Environment variables
- OPENJTALK_DICT: path to Open JTalk dictionary
- OPENJTALK_VOICE: path to .htsvoice file
- OPENJTALK_REPLACE_FILE: replacement table path
- OPENJTALK_SPEED: speech speed (default 1.0)
- OPENJTALK_ALPHA: all-pass constant (default 0.55)
- OPENJTALK_BETA: postfilter coefficient (default 0.0)
- OPENJTALK_NO_PLAY=1: generate wav only
