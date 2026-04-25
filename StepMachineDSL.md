# Step Machine DSL

A declarative step machine for XMLUI apps that use `ReactFlowCanvas` to present animated process diagrams.

Instead of writing per-phase functions and completion callbacks, you declare steps as data. A generic runtime in `Globals.xs` interprets the declarations and writes to XMLUI globals that your templates react to.

## Quick Start

Define your steps in `Globals.xs`:

```js
function getProcessFlowSteps() {
  return [
    {
      id: 'lookup',
      title: '1',
      message: 'Alice looks up terms',
      actionLabel: 'Lookup',
      phase: 1,
      completeAfterRoundTrip: true,
      run: [
        { type: 'addEdge', id: 'e-p-ag', source: 'person', target: 'agreements',
          sourceHandle: 'right-top', targetHandle: 'left-top', label: 'lookup' },
        { type: 'pulseRoundTrip', edge: 'lookup', durationMs: pulseDuration },
      ],
      cleanup: [
        { type: 'removeEdge', edgeId: 'e-p-ag' },
      ],
    },
    // ... more steps
  ];
}
```

Add completion triggers in your page markup:

```xml
<!-- Fixed-duration completion -->
<Timer
  enabled="{running && getProcessFlowSteps()[stepIndex].completeAfterMs > 0}"
  interval="{pulseDuration}"
  onTick="{() => { onTimerComplete() }}" />

<!-- Round-trip completion -->
<Timer
  enabled="{running && getProcessFlowSteps()[stepIndex].completeAfterRoundTrip}"
  interval="{pulseDuration * 2}"
  onTick="{() => { onRoundTripTimerComplete() }}" />

<!-- Pulse sequence completion -->
<ChangeListener
  listenTo="{pulse.active}"
  onDidChange="{() => { if (!pulse.active && running) { onPulseSequenceComplete() } }}" />
```

## Step Properties

### Required

| Property | Type | Description |
|----------|------|-------------|
| `id` | string | Unique step identifier. Used by `next`, `nextIf`, and `findStepIndex()`. |
| `phase` | number or string | Written to the `phase` global. Templates use `phase` to gate visibility. |

### Display

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `title` | string | `''` | Written to `phaseLabel`. Typically the step number. |
| `message` | string | `''` | Written to `phaseMessage`. Describes what happens in this step. |
| `actionLabel` | string | `''` | Written to `buttonLabel`. If empty, no button is shown. |
| `actionEnabled` | boolean | `true` | Written to `buttonEnabled`. Set to `false` for steps that advance automatically (e.g., waiting for user input in a node). |

### Effects

| Property | Type | Description |
|----------|------|-------------|
| `run` | array | Effects to execute when the user clicks the action button. See [Effect Types](#effect-types). |
| `runningPhase` | any | If set, `phase` changes to this value while effects are running. Useful for gating animations. |
| `cleanup` | array | Effects to execute when the step completes, before advancing. Typically `removeEdge` calls for transient edges. |

### Completion

| Property | Type | Description |
|----------|------|-------------|
| `completeAfterMs` | number | Complete after a fixed duration. Requires a Timer with `enabled="{running && getProcessFlowSteps()[stepIndex].completeAfterMs > 0}"`. |
| `completeAfterRoundTrip` | boolean | Complete after a round-trip animation finishes. Requires a Timer with `enabled="{running && getProcessFlowSteps()[stepIndex].completeAfterRoundTrip}"` and `interval="{pulseDuration * 2}"`. |
| `restartOnAction` | boolean | Clicking the button resets the flow instead of advancing. |

### Navigation

| Property | Type | Description |
|----------|------|-------------|
| `next` | number or string | Next step after completion. Can be a step index or step id. Defaults to next in array order. |
| `nextIf` | array | Conditional branching. Array of `{ when: () => boolean, goto: string }` objects. First matching `when` determines the next step. Falls through to `next` if none match. |

### Callbacks

| Property | Type | Description |
|----------|------|-------------|
| `onEnter` | function | Called when the step becomes active. Use for state initialization (e.g., resetting globals). |
| `onComplete` | function | Called when the step completes, after cleanup but before advancing. Use for domain side effects (e.g., writing to data stores). |

## Effect Types

Effects are objects in the `run` or `cleanup` arrays.

| Type | Fields | Description |
|------|--------|-------------|
| `pulse` | `edge`, `durationMs` | Pulse-animate a named edge. Multiple pulses fire in parallel. |
| `pulseRoundTrip` | `edge`, `durationMs` | Round-trip pulse animation on a named edge. |
| `pulseSequence` | `edges` | Start a multi-edge pulse sequence driven by the pulse Timer. |
| `clearPulse` | — | Clear all active pulse animations. |
| `addEdge` | `id`, `source`, `target`, `sourceHandle`, `targetHandle`, `label`, `noArrow`, `data` | Add a transient edge to the canvas. |
| `removeEdge` | `edgeId` | Remove an edge from the canvas. |

## Conditional Branching

Use `nextIf` to branch based on runtime state:

```js
{
  id: 'consult',
  // ...
  nextIf: [
    { when: () => agreementDecision === 'yes', goto: 'verify' },
    { when: () => agreementDecision === 'no', goto: 'rejected' },
  ],
}
```

The `when` functions are evaluated at completion time. The first match wins. If none match, falls through to `next` or sequential advance.

## Node-Driven Step Triggers

Some steps advance without a button click — they wait for user interaction inside a node component. For example, selecting a term in a dropdown:

```js
// In Globals.xs
function onTermSelected() {
  if (offeredTerm !== '' && phase === 3) {
    stepIndex = findStepIndex('send');
    sendTermEffects();
    running = true;
  }
}
```

```xml
<!-- In ReactFlowPage.xmlui -->
<ChangeListener
  listenTo="{offeredTerm}"
  onDidChange="{() => { onTermSelected() }}" />
```

The pattern: a ChangeListener watches a global that a node component writes to. The handler advances `stepIndex`, starts effects, and sets `running = true`. The normal completion triggers then handle the rest.

## Completion Callbacks

Use `onComplete` for domain side effects that happen when a step finishes:

```js
{
  id: 'verify',
  onComplete: () => {
    const status = agreementDecision === 'yes' ? 'accepted' : 'rejected';
    alicePersonalDataStore = [...alicePersonalDataStore, makeStoreEntry(offeredTerm + ' (' + status + ')', "Kleindorfer's")];
    if (agreementDecision === 'yes') {
      acceptedCount = acceptedCount + 1;
      window.__reactFlowCanvasApi.addEdge('e-signed-' + acceptedCount, ...);
    }
  },
}
```

`onComplete` runs after `cleanup` effects but before the step advances.

## Restart Behavior

Steps with `restartOnAction: true` reset the flow when the button is clicked:

```js
{
  id: 'done',
  title: '7',
  message: 'Agreement signed',
  actionLabel: 'Start Over',
  phase: 7,
  restartOnAction: true,
}
```

The restart logic in `nextStep()` handles cleanup (clearing pulses, removing accumulated edges) and jumps back to the appropriate starting step. In myterms, subsequent runs skip the delegate step since agency is already established.

## Runtime Globals

Declare these in `Main.xmlui`:

| Global | Type | Description |
|--------|------|-------------|
| `phase` | any | Current phase from the active step. |
| `phaseLabel` | string | Title text. |
| `phaseMessage` | string | Message text. |
| `buttonLabel` | string | Action button label. |
| `buttonEnabled` | boolean | Whether the button is enabled. |
| `running` | boolean | `true` while effects are executing. |
| `stepIndex` | number | Current step index. |
| `pulseDuration` | number | Default pulse duration in ms. |
| `pulse` | object | Pulse sequence state: `{ active, edges, step, currentEdge }`. |

## Adding a Step

1. Add an object to the `getProcessFlowSteps()` array.
2. Set `id`, `phase`, `title`, `message`, `actionLabel`.
3. Add `run` effects if the step triggers animations.
4. Choose a completion mode: `completeAfterMs`, `completeAfterRoundTrip`, pulse sequence, or node-driven.
5. Add `cleanup` if the step creates transient edges.
6. Add `nextIf` for conditional branching, or `next` for non-sequential flow.
7. Add `onComplete` for domain side effects.

No new functions, Timers, or ChangeListeners needed unless you introduce a new completion mode.
