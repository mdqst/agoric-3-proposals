import test from 'ava';
import { getIncarnation } from '@agoric/synthetic-chain/src/lib/vat-status.js';

test(`Provisioning vat was upgraded`, async t => {
  const incarantion = await getIncarnation('provisioning');
  t.is(incarantion, 1);
});
