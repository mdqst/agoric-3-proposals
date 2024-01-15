#!/bin/bash

source ./swing-store-helpers.sh

# verify swing-store export-data is consistent and perform genesis style "upgrade"
killAgd
EXPORT_DIR=$(mktemp -t -d swing-store-export-upgrade-11-XXX)
make_swing_store_snapshot $EXPORT_DIR --artifact-mode none || fail "Couldn't make swing-store snapshot"
test_val "$(compare_swing_store_export_data $EXPORT_DIR)" "match" "swing-store consistent cosmos kvstore"

TMP_GENESIS_DIR=$EXPORT_DIR/genesis-export
cp $HOME/.agoric/config/genesis.json $TMP_GENESIS_DIR/old_genesis.json
agd tendermint unsafe-reset-all
mv $TMP_GENESIS_DIR/* $HOME/.agoric/config/
rm -rf $EXPORT_DIR
startAgd
