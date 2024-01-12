#!/usr/bin/env tsx

import { parseArgs } from 'node:util';
import path from 'node:path';
import { execSync } from 'node:child_process';
import {
  buildProposalSubmissions,
  buildTestImages,
  readBuildConfig,
} from './src/cli/build.js';
import { writeDockerfile } from './src/cli/dockerfileGen.js';
import { matchOneProposal, readProposals } from './src/cli/proposals.js';
import { debugTestImage, runTestImages } from './src/cli/run.js';

const { positionals, values } = parseArgs({
  options: {
    match: { short: 'm', type: 'string' },
    dry: { type: 'boolean' },
    debug: { type: 'boolean' },
  },
  allowPositionals: true,
});

const root = path.resolve('.');
const buildConfig = readBuildConfig(root);
const allProposals = readProposals(root);

const { match } = values;
const proposals = match
  ? allProposals.filter(p => p.proposalName.includes(match))
  : allProposals;

const [cmd] = positionals;

// TODO consider a lib like Commander for auto-gen help
const usage = `USAGE:
build           - build the synthetic-chain

test [--debug]  - run the tests of the proposals
`;

const buildImages = () => {
  execSync(
    // XXX very brittle
    'cp -r node_modules/@agoric/synthetic-chain/upgrade-test-scripts .',
  );
  buildProposalSubmissions(proposals);
  buildTestImages(proposals, values.dry);
};

switch (cmd) {
  case 'build': {
    const { fromTag } = buildConfig;
    writeDockerfile(allProposals, fromTag);
    buildImages();
    break;
  }
  case 'test':
    if (values.debug) {
      debugTestImage(matchOneProposal(proposals, match!));
    } else {
      runTestImages(proposals);
    }
    break;
  default:
    console.log(usage);
}