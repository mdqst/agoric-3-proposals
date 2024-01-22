
lower-bundle-cost.json:
	jq '.tx.body.messages[0].content | .changes[0].value |= fromjson' tx-61.json >$@

hash=6EA7B46DFDD0973338BB50781B33D651FE0E8EE8ABF4D7BCB1BF8235334AAFE0
tx-61.json:
	agd --node $(ARCHIVE_NODE) query tx $(hash) -o json >$@

clean:
	rm -f lower-bundle-cost.json

realclean: clean
	rm -f tx-61.json
