function responsive(small, large) {
  return mediaSize.sizeIndex <= 2 ? small : large;
}

function makeStoreEntry(term, counterparty) {
  return {
    term: term,
    counterparty: counterparty,
    timestamp: new Date().toISOString(),
    country: "USA",
  };
}

function lookupTermPolicy(term) {
  for (let i = 0; i < kleindorfersTerms.length; i++) {
    if (kleindorfersTerms[i].terms === term) return kleindorfersTerms[i].policy;
  }
  return "Reject";
}

function pulseReached(edgeLabel) {
  if (!pulse.active && pulse.currentEdge === "") return false;
  if (!pulse.active) return true;
  return (
    pulse.edges.indexOf(pulse.currentEdge) > pulse.edges.indexOf(edgeLabel)
  );
}

function pulseNotReached(edgeLabel) {
  return !pulseReached(edgeLabel);
}

function onPulseEdgeChange(change) {
  if (change.newValue === "proffers" && offeredTerm !== "") {
    agreementDecision =
      kleindorfersTerms.find(function (t) {
        return t.terms === offeredTerm;
      }) &&
      kleindorfersTerms.find(function (t) {
        return t.terms === offeredTerm;
      }).policy === "Accept"
        ? "yes"
        : "no";
  }
}

function delegate() {
  offeredTerm = "";
  agreementDecision = "";
  acceptedCount = 0;
  aliceDataStore = [];
  kleindorfersDataStore = [];
  kleindorfersTerms = [
    { terms: "SD-BASE", policy: "Accept" },
    { terms: "PDC-AI", policy: "Reject" },
  ];
  window.__reactFlowCanvasApi.clearPulse();
  window.__reactFlowCanvasApi.pulseEdge("delegates agency", pulseDuration);
  window.__reactFlowCanvasApi.pulseEdge("delegates personal agency", pulseDuration);
  phase = "delegating";
}

function getTerms() {
  phase = 2;
  phaseLabel = '2';
  phaseMessage = 'Alice looks up terms';
  const api = window.__reactFlowCanvasApi;
  api.addEdge('e-p-ag', 'person', 'agreements', 'right-top', 'left-top', 'lookup');
  api.pulseEdgeRoundTrip('lookup', pulseDuration);
  roundTrip = 'lookup';
}

function sendTerm() {
  phase = 'sending';
  phaseLabel = '3';
  phaseMessage = 'Alice sends term to agent';
  const api = window.__reactFlowCanvasApi;
  api.addEdge('e-p-pa-send', 'person', 'person-agent', 'bottom-right', 'top-right', 'send', false, { labelPosition: 60 });
  pulse = { active: true, edges: ['send'], step: 0, currentEdge: 'lookup' };
}

function cleanupSendEdge() {
  window.__reactFlowCanvasApi.removeEdge('e-p-pa-send');
}

function proffer() {
  phase = 5;
  phaseLabel = '5';
  phaseMessage = 'Proffering agreement';
  pulse = { active: true, edges: ['proffers'], step: 0, currentEdge: 'lookup' };
}

function applyPolicy() {
  phase = 7;
  phaseLabel = '7';
  phaseMessage = 'Consulting policy';
  const api = window.__reactFlowCanvasApi;
  api.addEdge('e-ea-consult', 'entity-agent', 'entity', 'bottom-left', 'top-left', 'consults policy');
  api.pulseEdgeRoundTrip('consults policy', pulseDuration);
  roundTrip = 'consults policy';
}

function onRoundTripComplete() {
  if (roundTrip === 'lookup') {
    window.__reactFlowCanvasApi.removeEdge('e-p-ag');
    phase = 3;
    phaseLabel = '3';
    phaseMessage = "Choose a term from Alice's list";
  }
  if (roundTrip === 'consults policy') {
    window.__reactFlowCanvasApi.removeEdge('e-ea-consult');
    if (agreementDecision === 'yes') {
      phase = 8;
      phaseLabel = '8';
      phaseMessage = "Kleindorfer's agent verifies agreement";
    } else {
      phase = 10;
      phaseLabel = '';
      phaseMessage = 'Agreement rejected';
    }
  }
  if (roundTrip === 'verifies agreement') {
    window.__reactFlowCanvasApi.removeEdge('e-ea-verify');
    kleindorfersTerms = kleindorfersTerms.map(function(t) {
      return t.terms === offeredTerm ? { terms: t.terms, policy: agreementDecision === 'yes' ? 'Accept' : 'Reject' } : t;
    });
    aliceDataStore = [...aliceDataStore, makeStoreEntry(offeredTerm + ' (' + (agreementDecision === 'yes' ? 'accepted' : 'rejected') + ')', "Kleindorfer's")];
    kleindorfersDataStore = [...kleindorfersDataStore, makeStoreEntry(offeredTerm + ' (' + (agreementDecision === 'yes' ? 'accepted' : 'rejected') + ')', 'Alice')];
    if (agreementDecision === 'yes') {
      acceptedCount = acceptedCount + 1;
      window.__reactFlowCanvasApi.addEdge('e-signed-' + acceptedCount, 'person', 'entity-agent', 'right-magnet', 'left-magnet', 'signed: ' + offeredTerm + ' \u2282\u2283', true);
    }
    phase = 10;
    phaseLabel = '';
    phaseMessage = agreementDecision === 'yes' ? 'Agreement signed and posted to ledger' : 'Agreement rejected';
  }
  roundTrip = '';
}

function agree() {
  phase = 9;
  phaseLabel = '9';
  phaseMessage = 'Verifying agreement';
  const api = window.__reactFlowCanvasApi;
  api.addEdge('e-ea-verify', 'entity-agent', 'entity', 'bottom-left', 'top-left', 'verifies agreement', false, { labelPosition: 30 });
  api.pulseEdge('verifies agreement', pulseDuration * 2);
  roundTrip = 'verifies agreement';
}

function startOver() {
  const api = window.__reactFlowCanvasApi;
  // Remove all signed edges
  for (let i = 1; i <= acceptedCount; i++) {
    api.removeEdge('e-signed-' + i);
  }
  offeredTerm = '';
  agreementDecision = '';
  acceptedCount = 0;
  aliceDataStore = [];
  kleindorfersDataStore = [];
  kleindorfersTerms = [
    { terms: 'SD-BASE', policy: 'Accept' },
    { terms: 'PDC-AI', policy: 'Reject' },
  ];
  api.clearPulse();
  phase = 0;
  phaseLabel = '1';
  phaseMessage = "Alice and Kleindorfer's delegate agency";
}

function saveLayout() {
  const json = JSON.stringify(window.__reactFlowCanvasApi.getLayout(), null, 2);
  const blob = new Blob([json], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'layout.json';
  a.click();
  URL.revokeObjectURL(url);
}

function makeNode(id, label, extra) {
  const n = layout.nodes[id];
  const data = { label: label };
  if (extra) {
    for (const k in extra) {
      data[k] = extra[k];
    }
  }
  return { id: id, position: { x: n.x, y: n.y }, data: data, width: n.width, height: n.height };
}

function getNodes() {
  return [
    makeNode("person", "Alice", { magnetY: "12%" }),
    makeNode("person-agent", "Alices Agent"),
    makeNode("agreements", "Agreements"),
    makeNode("entity-agent", "Kleindorfer's Agent", { magnetY: "22%" }),
    makeNode("entity", "Kleindorfer's"),
    makeNode("control", "Control", { chrome: false }),
  ];
}

function getEdges() {
  return [
    {
      id: "e-p-pa",
      source: "person",
      target: "person-agent",
      sourceHandle: "bottom-left",
      targetHandle: "top-left",
      data: { label: "delegates personal agency", labelPosition: 40 },
    },
    {
      id: "e-pa-ea",
      source: "person-agent",
      target: "entity-agent",
      sourceHandle: "right-top",
      targetHandle: "left-bottom",
      data: { label: "proffers" },
    },
    {
      id: "e-ea-e",
      source: "entity",
      target: "entity-agent",
      sourceHandle: "top-right",
      targetHandle: "bottom-right",
      data: { label: "delegates agency", labelPosition: 30 },
    },
  ];
}

var layout = null;
