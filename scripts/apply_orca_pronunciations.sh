#!/usr/bin/env bash
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../conf/orca_pronunciations.json"
DST="$HOME/.local/share/orca/user-settings.conf"

if [[ ! -f "$SRC" ]]; then
  echo "Source not found: $SRC" >&2
  exit 1
fi

if [[ ! -f "$DST" ]]; then
  echo "Orca settings not found: $DST" >&2
  exit 1
fi

python3 - <<'PY'
import json, os, sys, shutil, time

src = os.path.expanduser("~/Internal/dev/orca-jtalk/conf/orca_pronunciations.json")
dst = os.path.expanduser("~/.local/share/orca/user-settings.conf")

with open(src, "r", encoding="utf-8") as f:
    add = json.load(f)

with open(dst, "r", encoding="utf-8") as f:
    data = json.load(f)

pron = data.get("pronunciations") or {}
# merge/overwrite
for k, v in add.items():
    pron[k] = v

data["pronunciations"] = pron

# backup
ts = time.strftime('%Y%m%d-%H%M%S')
shutil.copyfile(dst, dst + ".bak." + ts)

with open(dst, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=4)
    f.write("\n")
PY

printf 'Updated Orca pronunciations. Restart Orca to apply.\n'
