# Proposal to upgrade Zoe to incarnation 1

This uses the Zoe in https://github.com/Agoric/agoric-sdk/pull/8453/

It's currently a draft proposal, built from that branch with,

```
# whatever your checkout
A3P=/opt/agoric/agoric-3-proposals
cd packages/builders
# build the proposal
agoric run scripts/vats/upgrade-zoe.js | tee run-report.txt
# copy the proposal
cp upgrade-zoe* $A3P/proposals/b:zoe1/submission
# copy the bundles built for the proposal
cat run-report.txt | grep install-bundle | sed "s/agd tx swingset install-bundle @//" |xargs -I _ cp _ $A3P/proposals/b:zoe1/submission
```
