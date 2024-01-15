#!/bin/bash

source /usr/src/upgrade-test-scripts/env_setup.sh

export_genesis() {
  GENESIS_EXPORT_DIR="$1"
  shift
  GENESIS_HEIGHT_ARG=

  if [ -n "$1" ]; then
    GENESIS_HEIGHT_ARG="--height $1"
    shift
  fi

  agd export --export-dir "$GENESIS_EXPORT_DIR" $GENESIS_HEIGHT_ARG "$@"
}

make_swing_store_snapshot() { (
  set -euo pipefail
  EXPORT_DIR="$1"
  shift
  /usr/src/agoric-sdk/packages/cosmic-swingset/src/export-kernel-db.js --home "$HOME/.agoric" --export-dir "$EXPORT_DIR" --verbose --artifact-mode replay --export-data-mode all "$@"

  EXPORT_MANIFEST_FILE="$EXPORT_DIR/export-manifest.json"
  EXPORT_HEIGHT=$(cat "$EXPORT_MANIFEST_FILE" | jq -r .blockHeight)

  [ "x${WITHOUT_GENESIS_EXPORT:-0}" = "x1" ] || {
    EXPORT_DATA_FILE="$EXPORT_DIR/$(cat "$EXPORT_MANIFEST_FILE" | jq -r .data)"
    EXPORT_DATA_UNTRUSTED_FILE="${EXPORT_DATA_FILE%.*}-untrusted.jsonl"
    EXPORT_MANIFEST="$(cat $EXPORT_MANIFEST_FILE)"

    mv "$EXPORT_DATA_FILE" "$EXPORT_DATA_UNTRUSTED_FILE"
    export_genesis "$EXPORT_DIR/genesis-export" $EXPORT_HEIGHT
    cat $EXPORT_DIR/genesis-export/genesis.json | jq -cr '.app_state.swingset.swing_store_export_data[] | [.key,.value]' >"$EXPORT_DATA_FILE"

    jq -n "$EXPORT_MANIFEST | .untrustedData=\"$(basename -- "$EXPORT_DATA_UNTRUSTED_FILE")\"" >"$EXPORT_MANIFEST_FILE"
  }

  echo "Successful swing-store export for block $EXPORT_HEIGHT"
); }

restore_swing_store_snapshot() { (
  set -euo pipefail
  rm -f $HOME/.agoric/data/agoric/swingstore.sqlite
  EXPORT_DIR="$1"
  shift

  /usr/src/agoric-sdk/packages/cosmic-swingset/src/import-kernel-db.js --home "$HOME/.agoric" --export-dir "$EXPORT_DIR" --verbose --artifact-mode replay --export-data-mode all "$@"
); }

compare_swing_store_export_data() {
  EXPORT_DIR="$1"
  EXPORT_MANIFEST_FILE="$EXPORT_DIR/export-manifest.json"
  EXPORT_DATA_FILE="$(cat "$EXPORT_MANIFEST_FILE" | jq -r .data)"
  EXPORT_DATA_UNTRUSTED_FILE="$(cat "$EXPORT_MANIFEST_FILE" | jq -r .untrustedData)"

  if [ -z "$EXPORT_DATA_FILE" ]; then
    echo "missing-export-data"
    return
  fi

  if [ -z "$EXPORT_DATA_UNTRUSTED_FILE" ]; then
    echo "missing-untrusted-export-data"
    return
  fi

  sort $EXPORT_DIR/$EXPORT_DATA_FILE >"${EXPORT_DIR}/sorted_${EXPORT_DATA_FILE}"
  sort $EXPORT_DIR/$EXPORT_DATA_UNTRUSTED_FILE >"${EXPORT_DIR}/sorted_${EXPORT_DATA_UNTRUSTED_FILE}"

  diff "${EXPORT_DIR}/sorted_${EXPORT_DATA_FILE}" "${EXPORT_DIR}/sorted_${EXPORT_DATA_UNTRUSTED_FILE}" >&2 && {
    echo "match"
  } || {
    echo "mismatch"
  }
}
