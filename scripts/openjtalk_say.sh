#!/usr/bin/env bash
set -euo pipefail

# Open JTalk wrapper for Speech Dispatcher GenericExecuteSynth.
# Reads text from stdin, applies optional replacements, synthesizes a wav,
# and plays it. Designed to be called by Speech Dispatcher with $DATA.

# Resolve project-local paths and ensure a writable log directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${LOG_DIR:-"${SCRIPT_DIR}/../logs"}"

mkdir -p "${LOG_DIR}"

# Use a temp working directory for intermediate files (input, normalized input, wav).
TMP_DIR="$(mktemp -d)"
cleanup() {
  if [[ "${OPENJTALK_DEBUG:-0}" == "1" ]]; then
    echo "DEBUG: temp dir preserved at ${TMP_DIR}" >&2
  else
    rm -rf "${TMP_DIR}"
  fi
}
trap cleanup EXIT

TEXT_FILE="${TMP_DIR}/input.txt"
TEXT_NORM_FILE="${TMP_DIR}/input_norm.txt"
WAV_FILE="${TMP_DIR}/output.wav"
LOG_TEXT_PATH="${OPENJTALK_LOG_TEXT_PATH:-"${LOG_DIR}/openjtalk_text.log"}"

# Read input text from stdin as provided by Speech Dispatcher.
cat > "${TEXT_FILE}"

if [[ ! -s "${TEXT_FILE}" ]]; then
  echo "No input text" >&2
  exit 1
fi

# Apply word replacements (optional):
# A simple tab-separated table where each entry is a direct string replacement.
# The base (dist) table is always read if present, then a local override table.
REPLACE_DIST_FILE="${OPENJTALK_REPLACE_FILE:-"${SCRIPT_DIR}/../conf/word_replacements.dist.tsv"}"
REPLACE_LOCAL_FILE="${OPENJTALK_REPLACE_LOCAL_FILE:-"${SCRIPT_DIR}/../conf/word_replacements.local.tsv"}"
if [[ -f "${REPLACE_DIST_FILE}" || -f "${REPLACE_LOCAL_FILE}" ]]; then
  OPENJTALK_TEXT_FILE="${TEXT_FILE}" \
  OPENJTALK_TEXT_NORM_FILE="${TEXT_NORM_FILE}" \
  OPENJTALK_REPLACE_FILE="${REPLACE_DIST_FILE}" \
  OPENJTALK_REPLACE_LOCAL_FILE="${REPLACE_LOCAL_FILE}" \
  python3 - <<'PY'
import os, sys
src = os.environ.get("OPENJTALK_TEXT_FILE")
dst = os.environ.get("OPENJTALK_TEXT_NORM_FILE")
rep = os.environ.get("OPENJTALK_REPLACE_FILE")
rep_local = os.environ.get("OPENJTALK_REPLACE_LOCAL_FILE")

with open(src, "r", encoding="utf-8") as f:
    text = f.read()

def load_replacements(path):
    replacements = []
    if not path or not os.path.exists(path):
        return replacements
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "\t" not in line:
                continue
            a, b = line.split("\t", 1)
            replacements.append((a, b))
    return replacements

replacements = []
replacements.extend(load_replacements(rep))
replacements.extend(load_replacements(rep_local))

for a, b in replacements:
    text = text.replace(a, b)

with open(dst, "w", encoding="utf-8") as f:
    f.write(text)
PY
else
  cp "${TEXT_FILE}" "${TEXT_NORM_FILE}"
fi

# Optional logging of the final text that will be synthesized.
if [[ "${OPENJTALK_LOG_TEXT:-0}" == "1" ]]; then
  {
    printf '[%s]\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    cat "${TEXT_NORM_FILE}"
    printf '\n----\n'
  } >> "${LOG_TEXT_PATH}"
fi

# Resolve Open JTalk dictionary path.
# Open JTalk requires a MeCab dictionary; we point to common install locations.
DICT_CANDIDATES=(
  "${OPENJTALK_DICT:-}"
  "/var/lib/mecab/dic/open-jtalk/naist-jdic"
  "/usr/share/mecab/dic/open-jtalk/naist-jdic"
)
DICT_PATH=""
for d in "${DICT_CANDIDATES[@]}"; do
  if [[ -n "${d}" && -d "${d}" ]]; then
    DICT_PATH="${d}"
    break
  fi
done

if [[ -z "${DICT_PATH}" ]]; then
  echo "Open JTalk dictionary not found. Set OPENJTALK_DICT." >&2
  exit 1
fi

# Resolve HTS voice path (voice model).
VOICE_CANDIDATES=(
  "${OPENJTALK_VOICE:-}"
  "/usr/share/hts-voice/nitech-jp-atr503-m001/nitech_jp_atr503_m001.htsvoice"
  "/usr/share/hts-voice/mei/mei_normal.htsvoice"
)
VOICE_PATH=""
for v in "${VOICE_CANDIDATES[@]}"; do
  if [[ -n "${v}" && -f "${v}" ]]; then
    VOICE_PATH="${v}"
    break
  fi
done

if [[ -z "${VOICE_PATH}" ]]; then
  echo "HTS voice not found. Set OPENJTALK_VOICE." >&2
  exit 1
fi

# Debug output for troubleshooting paths and files.
if [[ "${OPENJTALK_DEBUG:-0}" == "1" ]]; then
  echo "DEBUG: OPENJTALK_DICT=${DICT_PATH}" >&2
  echo "DEBUG: OPENJTALK_VOICE=${VOICE_PATH}" >&2
  echo "DEBUG: OPENJTALK_REPLACE_DIST_FILE=${REPLACE_DIST_FILE}" >&2
  echo "DEBUG: OPENJTALK_REPLACE_LOCAL_FILE=${REPLACE_LOCAL_FILE}" >&2
  echo "DEBUG: TEXT_FILE=${TEXT_FILE}" >&2
  echo "DEBUG: TEXT_NORM_FILE=${TEXT_NORM_FILE}" >&2
fi

# Optional synthesis parameters.
SPEED="${OPENJTALK_SPEED:-1.0}"
ALPHA="${OPENJTALK_ALPHA:-0.55}"
BETA="${OPENJTALK_BETA:-0.0}"

# Synthesize to wav using Open JTalk.
open_jtalk \
  -x "${DICT_PATH}" \
  -m "${VOICE_PATH}" \
  -r "${SPEED}" \
  -a "${ALPHA}" \
  -b "${BETA}" \
  -ow "${WAV_FILE}" \
  "${TEXT_NORM_FILE}"

if [[ ! -s "${WAV_FILE}" ]]; then
  echo "Failed to generate wav" >&2
  exit 1
fi

# Optionally skip playback and only output the wav path.
if [[ "${OPENJTALK_NO_PLAY:-0}" == "1" ]]; then
  echo "WAV: ${WAV_FILE}"
  exit 0
fi

# Play the generated wav using available audio tools.
if command -v aplay >/dev/null 2>&1; then
  aplay -q "${WAV_FILE}"
elif command -v pw-play >/dev/null 2>&1; then
  pw-play "${WAV_FILE}"
elif command -v paplay >/dev/null 2>&1; then
  paplay "${WAV_FILE}"
else
  echo "No audio player found (aplay, pw-play, paplay)." >&2
  exit 1
fi
