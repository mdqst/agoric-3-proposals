#!/bin/bash

# Exit when any command fails
set -e

source /usr/src/upgrade-test-scripts/env_setup.sh

ls -al

yarn ava pre.test.js

./performActions.js

./legacy-actions.sh
