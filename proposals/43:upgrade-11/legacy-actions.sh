#!/bin/bash

source ./swing-store-helpers.sh

# hacky restore of pruned artifacts
killAgd
EXPORT_DIR=$(mktemp -t -d swing-store-export-upgrade-11-XXX)
WITHOUT_GENESIS_EXPORT=1 make_swing_store_snapshot $EXPORT_DIR --artifact-mode debug || fail "Couldn't make swing-store snapshot"
HISTORICAL_ARTIFACTS="$(
  cd $HOME/.agoric/data/agoric/swing-store-historical-artifacts/
  for i in *; do echo -n "[\"$i\",\"$i\"],"; done
)"
mv -n $HOME/.agoric/data/agoric/swing-store-historical-artifacts/* $EXPORT_DIR || fail "some historical artifacts not pruned"
mv $EXPORT_DIR/export-manifest.json $EXPORT_DIR/export-manifest-original.json
cat $EXPORT_DIR/export-manifest-original.json | jq -r ".artifacts = .artifacts + [${HISTORICAL_ARTIFACTS%%,}] | del(.artifactMode)" >$EXPORT_DIR/export-manifest.json
restore_swing_store_snapshot $EXPORT_DIR || fail "Couldn't restore swing-store snapshot"
startAgd
rm -rf $EXPORT_DIR
