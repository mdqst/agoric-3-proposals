import test from 'ava';
import { getIncarnation } from '@agoric/synthetic-chain/src/lib/vat-status.js';

test(`Zoe vat was upgraded`, async t => {
  const incarantion = await getIncarnation('zoe');
  t.is(incarantion, 1);
});
