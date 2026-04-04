function responsive(small, large) {
  return mediaSize.sizeIndex <= 2 ? small : large;
}

function makeStoreEntry(term, counterparty) {
  return { term: term, counterparty: counterparty, timestamp: new Date().toISOString(), country: 'USA' };
}

function lookupTermPolicy(term) {
  for (let i = 0; i < kleindorfersTerms.length; i++) {
    if (kleindorfersTerms[i].terms === term) return kleindorfersTerms[i].policy;
  }
  return 'Reject';
}

var personX = 50;
var personAgentX = 420;
var entityAgentX = 790;
var entityX = 1200;
