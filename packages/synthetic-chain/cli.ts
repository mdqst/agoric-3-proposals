#!/usr/bin/env tsx

import { parseArgs } from 'node:util';
import path from 'node:path';
import { execSync } from 'node:child_process';
import {
  buildProposalSubmissions,
  bakeImages,
  readBuildConfig,
} from './src/cli/build.js';
import {
  writeBakefileProposals,
  writeDockerfile,
} from './src/cli/dockerfileGen.js';
import { matchOneProposal, readProposals } from './src/cli/proposals.js';
import { debugTestImage, runTestImages } from './src/cli/run.js';
import { runDoctor } from './src/cli/doctor.js';

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
build           - build the synthetic-chain "use" images

test [--debug]  - build the "test" images and run them
test -m <name>  - target a particular proposal by substring match

doctor          - diagnostics and quick fixes
`;

/**
 * Put into places files that building depends upon.
 */
const prepareDockerBuild = () => {
  execSync(
    // XXX very brittle
    'cp -r node_modules/@agoric/synthetic-chain/upgrade-test-scripts .',
  );
  writeDockerfile(allProposals, buildConfig.fromTag);
  writeBakefileProposals(allProposals);
  buildProposalSubmissions(proposals);
  // to aid debugging CI out of disk space
  execSync('df -h');
};

switch (cmd) {
  case 'build': {
    prepareDockerBuild();
    bakeImages('use', values.dry);
    break;
  }
  case 'test':
    // Always rebuild all test images to keep it simple. With the "use" stages
    // cached, these are pretty fast building doesn't run agd.
    prepareDockerBuild();
    bakeImages('test', values.dry);
    if (values.debug) {
      debugTestImage(matchOneProposal(proposals, match!));
    } else {
      runTestImages(proposals);
    }
    break;
  case 'doctor':
    runDoctor(allProposals);
    break;
  default:
    console.log(usage);
}
