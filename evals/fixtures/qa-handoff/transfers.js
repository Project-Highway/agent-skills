'use strict';

// Transfer history for a user's account, backed by an in-memory store.
function listTransfers(store, userId) {
  return store.filter((t) => t.userId === userId);
}

function totalOut(store, userId) {
  return listTransfers(store, userId)
    .filter((t) => t.direction === 'out')
    .reduce((sum, t) => sum + t.amount, 0);
}

module.exports = { listTransfers, totalOut };
