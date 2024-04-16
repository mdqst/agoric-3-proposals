# Proposal to upgrade walletFactory to incarnation 2

This uses the walletFactory in

It's currently a draft proposal, built from that branch with,

```
# whatever your checkout
A3P=/opt/agoric/agoric-3-proposals
cd packages/builders
# build the proposal
agoric run scripts/smart-wallet/build-wallet-factory3-upgrade.js
# copy the proposal
cp upgrade-wallet-factory* $A3P/proposals/a\:wf3/submission/
# copy the bundles built for the proposal
cp $(jq -r '.bundles[].fileName' ./upgrade-wallet-factory-plan.json ) $A3P/proposals/a\:wf3/submission/
```
