'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const { listTransfers, totalOut } = require('./transfers');

const store = [
  { id: 1, userId: 'u1', direction: 'out', amount: 20, status: 'settled' },
  { id: 2, userId: 'u1', direction: 'in', amount: 50, status: 'settled' },
  { id: 3, userId: 'u2', direction: 'out', amount: 10, status: 'settled' },
];

test('lists only the requested user transfers', () => {
  assert.equal(listTransfers(store, 'u1').length, 2);
});

test('sums outgoing transfers for a user', () => {
  assert.equal(totalOut(store, 'u1'), 20);
});
