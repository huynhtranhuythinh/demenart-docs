# V128-B7 — DECISION CONTROL PLANE FOUNDATION · DESIGN REVIEW

> **Mode:** AUDIT-FIRST / DESIGN-ONLY. No implementation · no SQL apply · no migration · no FE · no canonical append.
> **Basis:** canonical files read directly (not from memory) + live read-only DB audit, project `xcvhacymrbhdhohyylyq`, 2026-08-15.
> **Status:** DESIGN READY FOR CTO APPROVAL. No phase authorized by this document.

---

## STEP 0 · CANONICAL BOOT — VERIFIED (no drift)

| Axis | Expected (boot prompt) | Live canonical | Verdict |
|---|---|---|---|
| RULES endpoint | D361 → D362 → D363 | **D363** | ✅ lineage exact |
| SYSTEM_MAP endpoint | v1.49 → v1.50 → v1.51 | **v1.51** | ✅ lineage exact |
| B6.3 milestone | CLOSED | **CLOSED — Owner-stamped 2026-08-15** | ✅ |
| G1 / G2 / G3 / G4 | all CLOSED | **all CLOSED** (8/8 invariants) | ✅ |
| Backend migration tail | — | **`20260815101138`** | ✅ |
| FE main pin | — | `@lovable.dev/vite-tanstack-config = 2.8.5` | ✅ |
| Append convention | — | `---` separator · prior block → `HISTORICAL SNAPSHOT (BẤT BIẾN)` · endpoint footer line | captured |

**One drift note (non-blocking, documentation only):** the top-of-file *"CURRENT CANONICAL ENDPOINT"* header inside `DMA_SYSTEM_MAP.md` still reads `D358 / v1.46 / B6.1.5`. The authoritative accumulated endpoint blocks + RULES agree on **D363 / v1.51**. This is a stale header pointer, not a lineage drift — flagged for correction at the next canonical write, not a STOP condition.

---

## STEP 1 · LIVE DATABASE RE-PIN (read-only) — MATCHES CLOSEOUT

**Inventory (live measured):** public tables **92** · fns **248** · secdef **236** · policies **167** · triggers **33** · cron **1** · `mc_internal` **{3 fn / 3 secdef}**. Identical to Phase-3 closeout.

**Action execution pipeline (live-verified, v1.51):**

```
actor
 → execute_mission_control_action        [INVOKER · md5 7a526354… · search_path='']
    → _mc_lookup_action('class', key)     [DEFINER · registry authority: dispatchable / adapter_key /
    │                                       required_context / input_schema / risk_level]
    → declarative context + input validation
    → RLS object gate (select school_id from classes where id=object_id)   ← INVOKER ⇒ E2b OBJECT_NOT_FOUND
    → _mc_begin_action(...)               [DEFINER · md5 f47260ef… · forge intent_fingerprint (sha256) +
    │                                       INSERT status='processing' ON CONFLICT(request_id) DO NOTHING]
    ├─ inserted=true →  static CASE resolver  WHEN 'class.assign.v1' THEN assign_class_distribution(...)
    │                     [adapter DEFINER · md5 03a1510b… · domain WHO-authz]
    │                   → _mc_commit_action(...)   [DEFINER · md5 ce36c5fe… · SOLE terminal writer]
    └─ inserted=false → intent-integrity replay guard
                          (fp match → replay · mismatch → MC_ACTION_REQUEST_CONFLICT · in-flight → IN_PROGRESS)
```

**Ledger (`mission_control_action_requests`) — fully sealed:**
- Columns: `… actor_id, created_at, started_at, completed_at, intent_hash_version, intent_fingerprint`.
- `authenticated` grants: **SELECT only** (INSERT/UPDATE/DELETE = false).
- Policies: **1** — `mission_control_action_requests_select_own` (SELECT). INSERT policy dropped in P3 (168→167).
- Both ledger write boundaries DEFINER-exclusive: forge (`_mc_begin_action`) + terminal (`_mc_commit_action`).

**Registry (2 rows):**
- `class.assign` — status `active` · risk **MEDIUM** · adapter `class.assign.v1` · execution_mode `single_domain_rpc` · required_context `{keys:[school_id], types:{school_id:uuid}, exclusive:true}` · input_schema `MissionActionInputSchema/v1`.
- `class.edit` — status `disabled` · risk **LOW** · adapter `null` · disabled_reason "No executor bound; class.edit executor out of B6.3 scope".

---

## STEP 2 · DECISION LAYER GAP AUDIT

### A · Existing decision primitives — **NONE**

Live search across `public` + `mc_internal` for `approv|decision|escalat|risk|review|authoriz|sign-off|human`:

- **Decision / approval / escalation / risk-policy / human-loop / audit-decision tables:** `[]` — **confirmed absent.**
- **Decision-named functions:** only `public.moment_is_approved` — this is **FMN group-moment consent** (MIN-consent rule: every tagged child must consent), **unrelated** to Mission Control. Not a reusable decision substrate.

**Verdict:** the Decision Control Plane is greenfield. There is no approval object, no decision state, no escalation concept, no risk-policy engine, no human-approval boundary, no decision audit event. Substrate must be built from zero.

### B · Current action risk model — **METADATA ONLY**

`risk_level` exists on the registry (`class.assign=MEDIUM`, `class.edit=LOW`) and is surfaced through the read path:

| Function | References `risk`? | Role |
|---|---|---|
| `_mc_lookup_action` | **yes** | carries risk_level as authority metadata |
| `get_mission_control_actions` | **yes** | surfaces risk_level to FE (presentation) |
| `execute_mission_control_action` | **no** | never branches on risk |
| `_mc_begin_action` | **no** | forge ignores risk |
| `_mc_commit_action` | **no** | terminal write ignores risk |

**Verdict:** `risk_level` is currently **presentation/metadata only — zero execution enforcement, zero approval routing.** It is a *label*. The Decision Layer will be its **first executable consumer**, promoting `risk_level` from descriptor to governance dimension.

### C · Execution boundary & insertion point

The pipeline above has exactly one enforced entry (`execute`, sole dispatch path; ledger DEFINER-sealed so no side-door forge). Three candidate placements:

- **Option A — before execute** (`actor → decision gate → execute`): a pre-flight advisory call.
  **✗ REJECTED.** `authenticated` holds direct EXECUTE on `execute_mission_control_action`. A pre-flight gate is **bypassable** — any caller can skip it and dispatch directly. Fatal for HIGH/CRITICAL.

- **Option B — inside execute** (`execute → decision evaluation → adapter`): gate check in-band.
  **✓ ENFORCEMENT SEAT.** execute is the sole registry-driven path; the ledger is DEFINER-sealed. A gate here cannot be bypassed. Precedent: P2/P3 already evolved execute's *body* (P2→P3 md5 change) while holding signature + return envelope + INVOKER + no-dynamic-SQL invariant. The natural seam is **immediately after `_mc_begin_action`** (fingerprint already forged ⇒ available as the decision correlation key) and at the **same precedence tier where the P3 replay guard already lives**.

- **Option C — after ledger intent creation** (`request → decision → execution`): decouple into forge-then-resume.
  **✓ FOR THE WAIT.** This is the async human-in-the-loop half: when a tier requires approval, the forged intent parks (does not reach adapter/commit) and execution resumes via a separate authorized call once a decision reaches `approved`.

**⭐ RECOMMENDATION — HYBRID B+C:**
Place the *gate evaluation* **inside execute, post-begin** (Option B — the only bypass-proof seat), keyed on the `intent_fingerprint` produced by `_mc_begin_action`. For tiers requiring approval with no existing approved decision for that exact fingerprint, execute **does not dispatch** — it parks the intent and returns a deterministic `MC_ACTION_DECISION_REQUIRED` envelope (Option C async model). Execution resumes only when an `approved` decision bound to the byte-identical fingerprint exists. **Reject Option A** (advisory-only, bypassable).

This reuses G3 (fingerprint = decision integrity key), G1 (registry = tier source), and G4 (sealed ledger = bypass-proofing). The Decision Layer is *unbuildable* without all three — which is precisely why it sequences after B6.3.

---

## STEP 3 · DESIGN PACKAGE

### 1 · Objective

Introduce a **WHETHER** axis to Mission Control: a bounded, bypass-proof gate that can require human approval for high-consequence action intents before they reach the domain adapter — without weakening the frozen INVOKER execute contract, the DEFINER ledger seal, or the Authority≠Authorization split.

### 2 · Why the Decision Layer now

Three axes exist today; the fourth is missing:

- **WHAT** may execute — registry authority (`_mc_lookup_action`) · G1 ✅
- **WHO** may execute — domain adapter authz (`assign_class_distribution`) · D362.5 ✅
- **THAT it happened, exactly once, as intended** — ledger + intent fingerprint · G3/G4 ✅
- **WHETHER this specific intent should proceed *now*** — **MISSING.** This is the Decision Layer.

`risk_level` is already computed and surfaced but enforced nowhere (Step 2.B). The machinery to *act* on risk is the single remaining gap in the Action Control Plane.

### 3 · Dependency analysis

**Why after B6.3 (hard prerequisite, not preference):**
- Needs **G3 intent_fingerprint** as the decision correlation key — an approval must bind to the *exact* intent; a different intent ⇒ different fingerprint ⇒ approval void. Without G3 there is nothing stable to approve.
- Needs **G1 registry authority** to source the risk tier declaratively.
- Needs **G4 sealed ledger** so the gate cannot be bypassed by a client-forged ledger row.
All three are B6.3 deliverables. B6.3 was the substrate; B7 is its first governance consumer.

**Why before the Memory Layer:**
Decision events (who approved/rejected what, when, why) are *source-of-truth events* the Memory Layer will later project. Ship Memory first and it has no decision events to consume → guaranteed rework. Decision Layer must own the event source; Memory owns projection.

**Why before Multi-object Expansion:**
Every new object/action multiplies the consequence surface. Governing WHETHER *before* multiplying WHAT means each new action inherits the gate by construction. Expanding first forces a governance retrofit across a wider surface and a larger bypass-audit.

### 4 · Proposed architecture

```
Action intent
 → Registry authority (WHAT)                         [_mc_lookup_action · risk_level]
 → Decision policy (tier → requires_approval?)        [bounded map, registry-sourced]
 → Intent forge (fingerprint)                         [_mc_begin_action · G3]
 → Decision gate  ───── requires approval? ──── no ──→ Execute (adapter WHO-authz) → Commit → Ledger
                                              │
                                              yes → open/find decision (keyed on fingerprint)
                                                   → PARK intent · return DECISION_REQUIRED
                                                          │
                          approver (≠ requester) resolves │
                                                          ▼
                                              approved → resume execute → adapter → commit → ledger
                                              rejected/expired/cancelled → terminal, no execution
                                                          │
                                                          └─→ decision event  (later: Memory projection)
```

### 5 · Proposed objects (DESIGN ONLY — no DDL)

**`public.mission_control_decisions`** — one decision per governed intent, keyed on the fingerprint. Mirrors the ledger sealing pattern (client SELECT-only; all writes DEFINER-exclusive).

Candidate fields:
- `id` (uuid, pk)
- `action_request_id` (uuid) — FK to `mission_control_action_requests.request_id` (the parked intent)
- `intent_fingerprint` (text) — **binds decision to exact intent** (reuses G3; approval invalid if intent differs)
- `intent_hash_version` (smallint)
- `object_type` / `object_id` — for approver-scope resolution (school-scoped, etc.)
- `action_key`
- `risk_level` (text) — snapshot of the tier at decision-open (audit stability)
- `state` (text) — `pending | approved | rejected | expired | cancelled`
- `requested_by` (uuid, actor)
- `decided_by` (uuid, nullable) — **enforced `<> requested_by`** (separation of duties)
- `decision_reason` (text, nullable)
- `expires_at` (timestamptz) — TTL for deadlock avoidance
- `created_at` / `updated_at`

**Bounded, not a workflow engine:** exactly **one** decision per `intent_fingerprint`; fixed 5-state machine; tier source = registry `risk_level` (no policy DSL in v1). This mirrors the D362.3 doctrine ("bounded declarative validators, NOT a generic JSON-Schema engine").

**DEFINER helpers (design intent, `mc_internal`, `search_path=''`):**
- `_mc_open_decision(...)` — sole INSERT owner; fail-closed if no eligible approver exists (avoids un-approvable rows).
- `_mc_resolve_decision(...)` — sole state-transition owner; enforces approver authority + `decided_by <> requested_by` + `pending`-only source.
Client (`authenticated`) gets **SELECT only** on the decisions table — identical seal to the ledger.

### 6 · State machine

```
                 ┌────────────► approved   (terminal · unlocks resume)
                 │
   (open) pending├────────────► rejected   (terminal)
                 │
                 ├────────────► expired     (terminal · TTL reached)
                 │
                 └────────────► cancelled   (terminal · requester/admin withdraw)
```

Invariants: only `pending` is non-terminal; every terminal state is immutable; `approved` is the *sole* state that permits execution resume; a resume is honored **only** for a decision whose `intent_fingerprint` equals the recomputed fingerprint of the resuming call.

### 7 · Security model

- **Who requests?** The gate opens the decision on behalf of the actor; `requested_by` = actor (`public.current_profile()`), never client-supplied.
- **Who approves?** Authority resolved **per object scope**, not a single global role. Class-scoped actions ⇒ school-scoped authority (principal/master), consistent with the D48 privacy moat (platform admins see zero child records and must not be the default approver for tenant-scoped actions). Resolution is a policy function, not a hardcoded role.
- **Can the requester approve their own action?** **No.** `_mc_resolve_decision` enforces `decided_by <> requested_by` as a hard, non-overridable invariant (separation of duties).
- **How is bypass prevented?** execute is the sole registry-driven dispatch path; the gate sits in-band post-begin; both the ledger and the decisions table are DEFINER-write-exclusive with client SELECT-only. There is no path to the adapter that skips the gate.
- **Integration with the commit boundary?** `_mc_commit_action` stays the **sole terminal writer** — unchanged. The Decision Layer never writes execution results; it only governs *whether* the adapter+commit are reached. The B6.2/G4 terminal seal is preserved verbatim.
- **No privilege elevation:** an approved decision authorizes the *intent to proceed*; on resume the domain adapter still runs its own WHO-authz against the **original actor**. Approval is a third gate (WHETHER), never a substitute for the adapter's WHO gate — an approved actor with no domain right still fails at the adapter.

### 8 · Migration strategy (phases only — NO SQL)

- **Phase 0 — Audit.** This document. Substrate confirmed greenfield; insertion seat identified.
- **Phase 1 — Foundation (dormant).** Decision table + `_mc_open_decision` / `_mc_resolve_decision` DEFINER helpers + tier→requires_approval map + RLS SELECT for stakeholders. **No execute wiring** — machinery ships inert. Zero live-traffic effect. No backfill.
- **Phase 2 — Execution integration.** Wire the gate into execute post-begin (find/open decision on fingerprint; park + `DECISION_REQUIRED` when required; proceed when an `approved` decision matches the exact fingerprint) + resume path. Preserve execute signature + return envelope + INVOKER + no-dynamic-SQL. D92 3-block + fail-closed VERIFY + `NOTIFY pgrst`.
- **Phase 3 — Canonicalization.** RULES **D364** + SYSTEM_MAP **v1.52** + `DMA_HANDOFF_V128-B7-PHASE-*` — complete replacement files, prior block → HISTORICAL SNAPSHOT.

**Safest possible rollout property:** only `class.assign` (MEDIUM) is dispatchable today; `class.edit` (LOW) is disabled. If the v1 tier map is *LOW/MEDIUM → auto-proceed, HIGH/CRITICAL → require decision*, then **the gate ships dormant** — exercised only when a HIGH/CRITICAL action is first registered. The machinery lands with zero risk to live class.assign traffic.

### 9 · Risks

- **Approval deadlock.** Empty approver set, or all eligible approvers = requester ⇒ intent never approvable. **Mitigation:** `_mc_open_decision` fail-closed detection of "no eligible approver" at open-time (distinct error, no un-approvable row created) + `expires_at` TTL.
- **Privilege escalation.** Approver green-lights an action they couldn't run, elevating the actor. **Mitigation:** adapter WHO-authz still runs against the original actor on resume (§7). Approval never elevates domain rights.
- **Bypass path.** **Mitigation:** in-band gate + sole dispatch path + DEFINER-sealed ledger & decisions (§7).
- **TOCTOU (approve → resume).** Domain state changes between approval and resume. **Mitigation:** fingerprint binding voids approval if intent changed; if only domain state changed, the adapter's own guards (`distribution_exists → CONFLICT`, etc.) fire — resume stays safe.
- **Over-engineering.** Drift toward a generic workflow/BPM engine. **Mitigation:** one decision per fingerprint · fixed 5-state machine · tier from registry `risk_level` (no policy DSL) · bounded to live actions. Same restraint doctrine as D362.3 / D362.4 (static allowlist, no dynamic dispatch).

---

## STEP 4 · CTO QUESTIONS (decisions required before Phase 1)

**Q1 — Decision gate placement.**
⭐ *Recommendation:* **Hybrid B+C** — gate evaluation **inside execute, post-begin** (bypass-proof seat, keyed on intent_fingerprint) + **async resume** (Option C) for the approval wait. **Reject Option A** (pre-flight = bypassable). *Decision?*

**Q2 — Risk model: registry-only or separate policy engine?**
⭐ *Recommendation:* **Registry-only** tier source in v1 (`risk_level` already surfaced by `_mc_lookup_action`). No separate policy engine yet — a per-tenant risk-override engine is a *later* option if demand appears. Avoid premature generality. *Decision?*

**Q3 — Approval granularity: per action / per object / per tenant?**
⭐ *Recommendation:* **Per action-instance** (per `intent_fingerprint`) for the *decision*; **approver authority resolved per object scope** (school-scoped for class actions). Not blanket per-object-type, not blanket per-tenant. *Decision?*

**Q4 — Should LOW/MEDIUM/HIGH/CRITICAL become executable governance?**
⭐ *Recommendation:* **Yes, bounded.** Define a tier→requires_approval map; recommend **LOW/MEDIUM auto-proceed, HIGH/CRITICAL require decision**. Consequence: v1 gate ships **dormant** (only MEDIUM class.assign is live) — safest rollout. *Confirm the mapping, and whether MEDIUM should require approval.*

**Q5 — Should the Decision Layer own Memory events later?**
⭐ *Recommendation:* Decision Layer **emits** decision events (source of truth); Memory Layer **projects/consumes** them. Decision owns the event source; Memory owns projection. Do **not** make Decision own Memory storage. *Decision?*

---

## STOP

Design package complete. No migration · no SQL · no apply · no FE · no code · no canonical files written.
**Awaiting CTO decisions on Q1–Q5 before any Phase 1 authorization.**

*Endpoint at audit time: RULES **D363** · SYSTEM_MAP **v1.51** · HANDOFF **V128-B6.3-PHASE-3** · backend tail `20260815101138` · FE main pin `2.8.5`.*
