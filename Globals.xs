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
  if (change.newValue === "verifies agreement" && agreementDecision !== "") {
    kleindorfersTerms = kleindorfersTerms.map(function (t) {
      return t.terms === offeredTerm
        ? {
            terms: t.terms,
            policy: agreementDecision === "yes" ? "Accept" : "Reject",
          }
        : t;
    });
    aliceDataStore = [
      ...aliceDataStore,
      makeStoreEntry(
        offeredTerm +
          " (" +
          (agreementDecision === "yes" ? "accepted" : "rejected") +
          ")",
        "Kleindorfer's",
      ),
    ];
    kleindorfersDataStore = [
      ...kleindorfersDataStore,
      makeStoreEntry(
        offeredTerm +
          " (" +
          (agreementDecision === "yes" ? "accepted" : "rejected") +
          ")",
        "Alice",
      ),
    ];
    if (agreementDecision === "yes") {
      acceptedCount = acceptedCount + 1;
      canvas.addEdge(
        "e-signed-" + acceptedCount,
        "person",
        "entity-agent",
        "right-magnet",
        "left-magnet",
        "signed: " + offeredTerm + " \u2282\u2283",
        true,
      );
    }
    phase = 0;
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
  window.__reactFlowCanvasApi.pulseEdge("delegates to", 1800);
  window.__reactFlowCanvasApi.pulseEdge("delegates personal agency", 1800);
  phase = "delegating";
}

function start() {
  phase = 2;
  pulse = { active: true, edges: ["lookup terms"], step: 0, currentEdge: "" };
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
  const _v = '' +
    phase +
    pulse.active +
    pulse.currentEdge +
    offeredTerm +
    agreementDecision +
    agreementCount +
    acceptedCount +
    aliceDataStore.length +
    kleindorfersDataStore.length;
  const data = { label: label, _v: _v };
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
    makeNode("control", "Control", { chrome: true }),
  ];
}

function getEdges() {
  return [
    {
      id: "e-p-ag",
      source: "person",
      target: "agreements",
      sourceHandle: "right-upper",
      targetHandle: "left-upper",
      data: { label: "lookup terms" },
    },
    {
      id: "e-p-pa",
      source: "person",
      target: "person-agent",
      sourceHandle: "bottom",
      targetHandle: "top",
      data: { label: "delegates personal agency" },
    },
    {
      id: "e-pa-ea",
      source: "person-agent",
      target: "entity-agent",
      sourceHandle: "right-upper",
      targetHandle: "left-lower",
      data: { label: "proffers" },
    },
    {
      id: "e-ea-e",
      source: "entity",
      target: "entity-agent",
      sourceHandle: "top",
      targetHandle: "bottom",
      data: { label: "delegates to" },
    },
    {
      id: "e-ea-verify",
      source: "entity-agent",
      target: "entity",
      sourceHandle: "right-upper",
      targetHandle: "right-upper",
      data: { label: "verifies agreement" },
    },
  ];
}

var layout = null;
