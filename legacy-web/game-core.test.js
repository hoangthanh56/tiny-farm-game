const test = require('node:test');
const assert = require('node:assert/strict');
const { initial, act, ready, value, valid, CROPS } = require('./game-core');

test('Full farming cycle for every crop, including reload and exact maturity time', () => {
  for (const [id, crop] of Object.entries(CROPS)) {
    let state = initial();
    const startSeeds = state.seeds[id];
    act(state, { type: 'buy', crop: id });
    assert.equal(state.money, 80 - crop.buy);
    assert.equal(state.seeds[id], startSeeds + 1);
    act(state, { type: 'plant', crop: id, index: 0 }, 1000);
    act(state, { type: 'harvest', index: 0 }, 999999);
    assert.equal(state.harvested, 0, 'Unwatered crops cannot mature');
    act(state, { type: 'water', index: 0 }, 2000);
    act(state, { type: 'water', index: 0 }, 3000);
    assert.equal(state.plots[0].wateredAt, 2000, 'Watering twice does not restart growth');
    state = JSON.parse(JSON.stringify(state));
    assert.equal(valid(state), true);
    const maturity = 2000 + crop.seconds * 1000;
    assert.equal(ready(state.plots[0], maturity - 1), false);
    act(state, { type: 'harvest', index: 0 }, maturity - 1);
    assert.equal(state.harvested, 0);
    act(state, { type: 'harvest', index: 0 }, maturity);
    assert.equal(state.harvested, 1);
    assert.equal(state.plots[0], null);
    assert.equal(value(state), crop.sell);
    act(state, { type: 'sell' });
    assert.equal(state.money, 80 - crop.buy + crop.sell);
    act(state, { type: 'sell' });
    assert.equal(state.money, 80 - crop.buy + crop.sell, 'Cannot sell twice');
  }
});

test('Invalid actions cannot spend resources or overwrite crops', () => {
  const state = initial();
  state.money = 0;
  const snapshot = JSON.stringify(state);
  act(state, { type: 'buy', crop: 'pumpkin' });
  act(state, { type: 'plant', crop: 'pumpkin', index: 0 });
  act(state, { type: 'plant', crop: 'carrot', index: 12 });
  act(state, { type: 'plant', crop: 'carrot', index: -1 });
  act(state, { type: 'expand' });
  assert.equal(JSON.stringify(state), snapshot);
  act(state, { type: 'plant', crop: 'carrot', index: 0 });
  const planted = JSON.stringify(state);
  act(state, { type: 'plant', crop: 'wheat', index: 0 });
  assert.equal(JSON.stringify(state), planted);
});

test('Expansion charges increasing prices and stops at 24 plots', () => {
  const state = initial();
  state.money = 500;
  for (const expected of [16, 20, 24]) {
    act(state, { type: 'expand' });
    assert.equal(state.unlocked, expected);
  }
  assert.equal(state.money, 80);
  act(state, { type: 'expand' });
  assert.equal(state.money, 80);
  act(state, { type: 'plant', crop: 'carrot', index: 23 });
  assert.equal(state.plots[23].crop, 'carrot');
});

test('Save validation rejects malformed and incompatible data', () => {
  assert.equal(valid(initial()), true);
  for (const state of [null, {}, { ...initial(), version: 2 }, { ...initial(), money: -1 },
    { ...initial(), unlocked: 100 }, { ...initial(), plots: [] }, { ...initial(), seeds: {} }]) {
    assert.equal(Boolean(valid(state)), false);
  }
  const state = initial();
  state.plots[0] = { crop: 'unknown', wateredAt: 0 };
  assert.equal(valid(state), false);
  state.plots[0] = { crop: 'carrot', wateredAt: 'yesterday' };
  assert.equal(valid(state), false);
});
