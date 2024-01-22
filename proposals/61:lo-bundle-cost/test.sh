#!/bin/bash
set -e

expected=20000000

params="$(agd query swingset params -o json)"
cost="$(echo $params | jq -r ".beans_per_unit | .[] | select(.key == \"storageByte\") | .beans" )"

# fail if cost is not expected
if [ "$cost" != "$expected" ]; then
    echo "Expected cost $expected, got $cost"
    exit 1
else
    echo "Cost is $cost"
fi

