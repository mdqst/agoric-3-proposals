#!/bin/bash

echo ENV_SETUP starting

# FIXME not used anywhere; restore these debug flags
export DEBUG="SwingSet:ls,SwingSet:vat"

export CHAINID=agoriclocal
shopt -s expand_aliases

alias agops="/usr/src/agoric-sdk/node_modules/.bin/agops"
if test -f "$HOME/.agoric/envs"; then
  source "$HOME/.agoric/envs"
fi

export binary=ag0
if [ -x "$(command -v "agd")" ]; then
  export binary=agd
fi
export GOV1ADDR=$($binary keys show gov1 -a --keyring-backend="test")
export GOV2ADDR=$($binary keys show gov2 -a --keyring-backend="test")
export GOV3ADDR=$($binary keys show gov3 -a --keyring-backend="test")
export VALIDATORADDR=$($binary keys show validator -a --keyring-backend="test")
export USER1ADDR=$($binary keys show user1 -a --keyring-backend="test")

if [[ "$binary" == "agd" ]]; then
  configdir=/usr/src/agoric-sdk/packages/vm-config
  test -d "$configdir" || configdir=/usr/src/agoric-sdk/packages/vats
  # Support testnet addresses
  sed -i "s/agoric1ldmtatp24qlllgxmrsjzcpe20fvlkp448zcuce/$GOV1ADDR/g" "$configdir"/*.json
  sed -i "s/agoric140dmkrz2e42ergjj7gyvejhzmjzurvqeq82ang/$GOV2ADDR/g" "$configdir"/*.json
  sed -i "s/agoric1w8wktaur4zf8qmmtn3n7x3r0jhsjkjntcm3u6h/$GOV3ADDR/g" "$configdir"/*.json

  # Support mainnet addresses
  sed -i "s/agoric1gx9uu7y6c90rqruhesae2t7c2vlw4uyyxlqxrx/$GOV1ADDR/g" "$configdir"/*.json
  sed -i "s/agoric1d4228cvelf8tj65f4h7n2td90sscavln2283h5/$GOV2ADDR/g" "$configdir"/*.json
  sed -i "s/agoric1zayxg4e9vd0es9c9jlpt36qtth255txjp6a8yc/$GOV3ADDR/g" "$configdir"/*.json
  sed -i '/agoric14543m33dr28x7qhwc558hzlj9szwhzwzpcmw6a/d' "$configdir"/*.json
  sed -i '/agoric13p9adwk0na5npfq64g22l6xucvqdmu3xqe70wq/d' "$configdir"/*.json
  sed -i '/agoric1el6zqs8ggctj5vwyukyk4fh50wcpdpwgugd5l5/d' "$configdir"/*.json

  # change names to gov1/2/3 since order is significant for invitation sending
  sed -i "s/Jason Potts/gov1/g" "$configdir"/*.json
  sed -i "s/Chloe White/gov2/g" "$configdir"/*.json
  sed -i "s/Joe Clark/gov3/g" "$configdir"/*.json

  # Oracle Addresses
  sed -i "s/agoric1krunjcqfrf7la48zrvdfeeqtls5r00ep68mzkr/$GOV1ADDR/g" "$configdir"/*.json
  sed -i "s/agoric1n4fcxsnkxe4gj6e24naec99hzmc4pjfdccy5nj/$GOV2ADDR/g" "$configdir"/*.json
  sed -i '/agoric19uscwxdac6cf6z7d5e26e0jm0lgwstc47cpll8/d' "$configdir"/*.json
  sed -i '/agoric144rrhh4m09mh7aaffhm6xy223ym76gve2x7y78/d' "$configdir"/*.json
  sed -i '/agoric19d6gnr9fyp6hev4tlrg87zjrzsd5gzr5qlfq2p/d' "$configdir"/*.json

  # committeeSize
  sed -i 's/committeeSize": 6/committeeSize": 3/g' "$configdir"/*.json
  sed -i 's/minSubmissionCount": 3/minSubmissionCount": 1/g' "$configdir"/*.json
fi

startAgd() {
  agd start --log_level warn "$@" &
  AGD_PID=$!
  echo $AGD_PID >$HOME/.agoric/agd.pid
  wait_for_bootstrap
  waitForBlock 2
}

killAgd() {
  AGD_PID=$(cat $HOME/.agoric/agd.pid)
  kill $AGD_PID
  rm $HOME/.agoric/agd.pid
  wait $AGD_PID || true
}

waitAgd() {
  wait $(cat $HOME/.agoric/agd.pid)
  rm $HOME/.agoric/agd.pid
}

provisionSmartWallet() {
  addr="$1"
  amount="$2"
  echo "funding $addr"
  agd tx bank send "validator" "$addr" "$amount" -y --keyring-backend=test --chain-id="$CHAINID"
  waitForBlock
  echo "provisioning $addr"
  agd tx swingset provision-one my-wallet "$addr" SMART_WALLET --keyring-backend=test --yes --chain-id="$CHAINID" --from="$addr"
  echo "Waiting for wallet $addr to reach vstorage"
  waitForBlock 5
  echo "Reading $addr from vstorage"
  agoric wallet show --from "$addr"
}

wait_for_bootstrap() {
  echo "waiting for bootstrap..."
  endpoint="localhost"
  while true; do
    if json=$(curl -s --fail -m 15 "$endpoint:26657/status"); then
      if [[ "$(echo "$json" | jq -r .jsonrpc)" == "2.0" ]]; then
        if last_height=$(echo "$json" | jq -r .result.sync_info.latest_block_height); then
          if [[ "$last_height" != "1" ]]; then
            echo "$last_height"
            return
          else
            echo "$last_height"
          fi
        fi
      fi
    fi
    sleep 2
  done
  echo "done"
}

waitForBlock() (
  echo "waiting for block..."
  times=${1:-1}
  echo "$times"
  for ((i = 1; i <= times; i++)); do
    b1=$(wait_for_bootstrap)
    while true; do
      b2=$(wait_for_bootstrap)
      if [[ "$b1" != "$b2" ]]; then
        echo "block produced"
        break
      fi
      sleep 1
    done
  done
  echo "done"
)

fail() {
  echo "FAIL: $1"
  exit 1
}

success() {
  echo "SUCCESS: $1"
}

test_val() {
  want="$2"
  got="$1"
  testname="${3:-unnamedtest}"
  if [[ "$want" != "$got" ]]; then
    fail "TEST: $testname: wanted $want, got $got"
  else
    success "TEST: $testname: wanted $want, got $got"
  fi
}

test_not_val() {
  want="$2"
  got="$1"
  testname="${3:-unnamedtest}"
  if [[ "$want" == "$got" ]]; then
    fail "TEST: $testname:  $want is equal to $got"
  else
    success "TEST: $testname: $want is not equal to $got"
  fi
}

voteLatestProposalAndWait() {
  waitForBlock
  proposal=$($binary q gov proposals -o json | jq -r '.proposals[-1].proposal_id')
  waitForBlock
  $binary tx gov deposit $proposal 50000000ubld --from=validator --chain-id="$CHAINID" --yes --keyring-backend test
  waitForBlock
  $binary tx gov vote $proposal yes --from=validator --chain-id="$CHAINID" --yes --keyring-backend test
  waitForBlock

  while true; do
    status=$($binary q gov proposal $proposal -ojson | jq -r .status)
    case $status in
    PROPOSAL_STATUS_PASSED)
      break
      ;;
    PROPOSAL_STATUS_REJECTED)
      echo "Proposal rejected"
      exit 1
      ;;
    *)
      echo "Waiting for proposal to pass (status=$status)"
      sleep 1
      ;;
    esac
  done
}

printKeys() {
  echo "========== GOVERNANCE KEYS =========="
  echo "gov1: $GOV1ADDR"
  cat ~/.agoric/gov1.key || true
  echo "gov2: $GOV2ADDR"
  cat ~/.agoric/gov2.key || true
  echo "gov3: $GOV3ADDR"
  cat ~/.agoric/gov3.key || true
  echo "validator: $VALIDATORADDR"
  cat ~/.agoric/validator.key || true
  echo "user1: $USER1ADDR"
  cat ~/.agoric/user1.key || true
  echo "========== GOVERNANCE KEYS =========="
}

export USDC_DENOM="ibc/295548A78785A1007F232DE286149A6FF512F180AF5657780FC89C009E2C348F"
export ATOM_DENOM="ibc/BA313C4A19DFBF943586C0387E6B11286F9E416B4DD27574E6909CABE0E342FA"
export PSM_PAIR="IST.USDC_axl"

echo ENV_SETUP finished