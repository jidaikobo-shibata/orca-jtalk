#!/usr/bin/env bash
set -euo pipefail

if ! command -v spd-say >/dev/null 2>&1; then
  echo "spd-say not found." >&2
  exit 1
fi

TEXT="${1:-"\u3053\u308c\u306f\u30c6\u30b9\u30c8\u3067\u3059\u3002"}"

# Use the openjtalk module explicitly
spd-say -o openjtalk -l ja "${TEXT}"
