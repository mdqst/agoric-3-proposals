#!/bin/bash

# Exit when any command fails
set -e

source /usr/src/upgrade-test-scripts/env_setup.sh

GAS_ADJUSTMENT=1.2
SIGN_BROADCAST_OPTS="--keyring-backend=test --chain-id=$CHAINID \
		--gas=auto --gas-adjustment=$GAS_ADJUSTMENT \
		--yes -b block"

agd tx gov submit-proposal param-change lower-bundle-cost.json \
    $SIGN_BROADCAST_OPTS --from validator

voteLatestProposalAndWait

