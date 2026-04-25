# MyTerms Demo: Next Steps for IIW

Ideas for expanding the demo beyond protocol negotiation to show what happens *after* agreements are signed — how they influence real transactions and give individuals visibility and control.

## 1. Post-Agreement Value Exchange

After Alice and Kleindorfer's sign an agreement, simulate an actual service interaction where the agreement governs data sharing in real time.

**Scenario:** Alice shops at Kleindorfer's online store. Kleindorfer's makes a series of data requests. Alice's agent checks each request against the signed agreement and grants or blocks it automatically.

Example data requests and outcomes:

| Request | Under SD-BASE | Without agreement |
|---|---|---|
| Shipping address (for delivery) | Allowed — service delivery | Allowed, but also sold to brokers |
| Browsing history (for recommendations) | Allowed — scoped to session | Harvested permanently, shared with ad networks |
| Purchase history (for AI model training) | Blocked (no PDC-AI) | Used freely |
| Email (for third-party marketing) | Blocked | Sold |

**What the audience sees:**

- Data requests pulse from Kleindorfer's through the agents
- Alice's agent checks each against the signed agreement
- Each request resolves as granted or blocked
- Optional: side-by-side contrast showing "with agreement" vs. "status quo" to make the privacy impact visceral

**Why it matters:** This answers the "so what?" question. The agreement isn't just a signed document — it actively governs behavior. Alice never sees a cookie banner or reads fine print; her agent enforces her terms automatically.

**Architecture:** Extends the existing step machine with a post-signing phase. Data requests are a small table; each row resolves based on which agreements are in force. No structural changes needed.

### PDC-AI needs a visible quid pro quo

In the current demo, there's no reason for Alice to proffer PDC-AI — it grants access to her data for AI training with nothing in return. PDC-AI only makes sense as part of an explicit value exchange: a discount, a data dividend, access to a premium service tier, etc.

This makes PDC-AI the strongest motivating example for the post-agreement simulation:

- Kleindorfer's offers Alice a 20% discount (or monthly data dividend) if she signs PDC-AI
- Alice's dashboard shows the tradeoff: "sharing training data with Kleindorfer's → receiving $X/month"
- Alice can revoke PDC-AI and see the compensation stop
- Without this, PDC-AI in the demo is just a way to trigger the "rejected" path — useful for showing protocol mechanics, but it makes Alice look like she's acting against her own interests

## 2. Alice's Relationship Dashboard

Evolve Alice's "Personal Data Store" from a transaction log into a dashboard she actively uses to manage her digital relationships.

**What Alice wants to know:**

- **Active agreements** — which entities she has agreements with, and what terms are in force
- **Data shared** — a ledger of what personal data went where, under which agreement
- **Requests blocked** — what her agent denied, so she can see the agreement working for her
- **Compliance signals** — whether an entity is honoring its terms (e.g., making requests that exceed the agreement scope)
- **Expiration / renewal** — when agreements need attention
- **Entity comparison** — Kleindorfer's accepted SD-BASE and PDC-AI; Acme only accepted SD-BASE — so Alice can make informed choices about who to do business with

**Why it matters:** This turns the personal data store from a receipt box into a control panel. It's the concrete expression of the individual-as-first-party vision: Alice doesn't just sign agreements and hope for the best, she has ongoing visibility into how her data is being used across all her relationships.

**Possible UI:** A dedicated view (or an expanded PersonNode panel) with tabs or sections for each entity, showing agreement status, data exchange history, and any compliance flags.

## 3. Multiple Entities

Add a second entity (e.g., "Acme Corp") with different policies. This lets Alice:

- Proffer terms to different organizations
- See different outcomes based on each entity's policies
- Compare her relationships across entities in the dashboard

This demonstrates that IEEE 7012 isn't about one bilateral relationship — it's a protocol that scales across the web.

## 4. Autonomous Agent Mode

Add a toggle between manual step-through and autonomous mode. After delegation, Alice's agent runs on its own — auto-proffering terms and handling data requests based on her configured preferences. This demonstrates the end-state vision: configure once, then your agent handles privacy negotiations and enforcement on your behalf.
