import test from 'ava';
import { getIncarnation } from '@agoric/synthetic-chain';

test.todo('try with a bad invitation');
test.todo('upgrade wf');

test(`walletFactory was upgraded`, async t => {
  const incarantion = await getIncarnation('walletFactory');
  t.is(incarantion, 3);
});
