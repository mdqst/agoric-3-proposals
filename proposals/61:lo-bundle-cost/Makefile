# reverse-engineer Proposal 61: Lower bundle cost

# `agd tx gov submit-proposal param-change` seems
# to JSON.stringify the value in the proposal.
# So we need to `fromjson` it before feeding it back to `agd`.
lower-bundle-cost.json: tx-61.json
	jq '.tx.body.messages[0].content | .changes[0].value |= fromjson' tx-61.json >$@

# To get the hash of the tx for proposal 61,
# we found the proposer (either using an explorer or
# `agd --node $ARCHIVE_NODE query gov proposer 61`)
# and looked at their transaction history.
hash=6EA7B46DFDD0973338BB50781B33D651FE0E8EE8ABF4D7BCB1BF8235334AAFE0
ARCHIVE_NODE="https://main-a.rpc.agoric.net:443"
tx-61.json:
	agd --node $(ARCHIVE_NODE) query tx $(hash) -o json >$@

# clean up locally computed files
clean:
	rm -f lower-bundle-cost.json

# clean up files cached from the network as well
realclean: clean
	rm -f tx-61.json
