#!/bin/bash

# Exit when any command fails
set -e

source /usr/src/upgrade-test-scripts/env_setup.sh

agd tx gov submit-proposal param-change lower-bundle-cost.json \
	${SUBMIT_PROPOSAL_OPTS:+"--missing-env-setup"}

voteLatestProposalAndWait
