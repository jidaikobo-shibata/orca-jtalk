#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV="${OPENJTALK_USERDICT_CSV:-"${SCRIPT_DIR}/../conf/openjtalk_userdict.csv"}"
OUT="${OPENJTALK_USERDICT_OUT:-"${SCRIPT_DIR}/../conf/openjtalk_userdict.dic"}"
DICT_DIR="${OPENJTALK_DICT_DIR:-"/var/lib/mecab/dic/ipadic"}"
DICTINDEX_DIR="${OPENJTALK_DICTINDEX_DIR:-""}"
LOCAL_DIC_DIR="${SCRIPT_DIR}/../conf/openjtalk_dictindex"
LOCAL_DICRC="${LOCAL_DIC_DIR}/dicrc"

create_local_dictindex_dir() {
  mkdir -p "${LOCAL_DIC_DIR}"

  # Link dictionary files
  local -a files=(
    "char.bin"
    "left-id.def"
    "matrix.bin"
    "pos-id.def"
    "rewrite.def"
    "right-id.def"
    "sys.dic"
    "unk.dic"
  )
  for f in "${files[@]}"; do
    ln -sf "${DICT_DIR}/${f}" "${LOCAL_DIC_DIR}/${f}"
  done

  rm -f "${LOCAL_DICRC}"
  if [[ -f "${DICT_DIR}/dicrc" ]]; then
    ln -sf "${DICT_DIR}/dicrc" "${LOCAL_DICRC}"
  else
    cat > "${LOCAL_DICRC}" <<'EOT'
; Auto-generated dicrc for user dictionary build
cost-factor = 800
bos-feature = BOS/EOS,*,*,*,*,*,*,*,*
eval-size = 8
unk-eval-size = 4
config-charset = UTF-8
node-format-yomi = %pS%f[7]
unk-format-yomi = %M
eos-format-yomi  = \n
EOT
  fi
}

if [[ ! -f "${CSV}" ]]; then
  echo "CSV not found: ${CSV}" >&2
  exit 1
fi

DICT_INDEX=""
if command -v mecab-dict-index >/dev/null 2>&1; then
  DICT_INDEX="$(command -v mecab-dict-index)"
elif [[ -x /usr/lib/mecab/mecab-dict-index ]]; then
  DICT_INDEX="/usr/lib/mecab/mecab-dict-index"
elif [[ -x /usr/lib/x86_64-linux-gnu/mecab/mecab-dict-index ]]; then
  DICT_INDEX="/usr/lib/x86_64-linux-gnu/mecab/mecab-dict-index"
fi

if [[ -z "${DICT_INDEX}" ]]; then
  echo "mecab-dict-index not found. Install mecab utils (e.g. 'sudo apt install mecab-utils')." >&2
  exit 1
fi

if [[ -z "${DICTINDEX_DIR}" ]]; then
  create_local_dictindex_dir
  DICTINDEX_DIR="${LOCAL_DIC_DIR}"
fi

ASSIGN_IDS_FLAG=""
if [[ -f "${DICTINDEX_DIR}/rewrite.def" ]]; then
  ASSIGN_IDS_FLAG="-a"
fi

"${DICT_INDEX}" \
  -d "${DICTINDEX_DIR:-${DICT_DIR}}" \
  ${ASSIGN_IDS_FLAG} \
  -u "${OUT}" \
  -f utf-8 \
  -t utf-8 \
  "${CSV}"

echo "Built user dict: ${OUT}"
