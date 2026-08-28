# V128-B7 PHASE-1 AUDIT REPORT — DECISION CONTROL PLANE FOUNDATION

> **Mode:** AUDIT-FIRST / DESIGN-ONLY. No implementation · no migration · no mutation · no FE · no canonical append · no reconstruction from memory.
> **Sources:** canonical files on disk + live read-only Supabase audit (project `xcvhacymrbhdhohyylyq`) + real function/constraint definitions. Audit date 2026-08-15.
> **Status:** DESIGN ONLY — WAITING CTO APPROVAL. No implementation authorized.

---

## 1 · Canonical state

Read directly from disk (not memory):

| File | Present | Endpoint / status captured |
|---|---|---|
| `DMA_RULES.md` | ✅ | endpoint **D363** |
| `DMA_SYSTEM_MAP.md` | ✅ | endpoint **v1.51** |
| `DMA_HANDOFF_V128-B6.3-PHASE-3_CLOSEOUT.md` | ✅ | V128-B6.3 **milestone CLOSED**, Owner-stamped 2026-08-15 |
| `CTO_DECISIONS.md` | ❌ **absent** | optional file ("nếu tồn tại") — not present, not referenced anywhere. Not a STOP (the 3 Required files all present). |

- **B6.3 status:** CLOSED. G1 Registry Authority ✅ · G2 Adapter Resolver ✅ · G3 Intent Integrity ✅ · G4 Ledger Security Boundary ✅. 8/8 frozen invariants.
- **Migration tail recorded:** `20260815101138` (`v128_b6_3_p3_intent_integrity`).
- **FE main pin:** `@lovable.dev/vite-tanstack-config = 2.8.5`.
- **Invariant list (must preserve):** execute = SECURITY INVOKER + public contract frozen · `_mc_begin_action` = DEFINER server-owned forge · `_mc_commit_action` = DEFINER sole terminal writer · registry = WHAT (not an approval engine) · adapter = HOW (Decision Layer never calls adapter directly).
- **Next gate (per canonical):** "V128-B6.3 CLOSED. No successor phase within B6.3. Decision layer / FE decoupling / multi-object = new milestone." → **B7 is that new milestone.**

**One documentation note (non-blocking):** the `DMA_SYSTEM_MAP.md` top-of-file *"CURRENT CANONICAL ENDPOINT"* header still reads `D358 / v1.46 / B6.1.5`; the authoritative accumulated endpoint blocks + RULES agree on **D363 / v1.51**. Stale header pointer, not lineage drift.

## 2 · Live state (read-only)

| Metric | Live | B6.3 closeout | Match |
|---|---|---|---|
| Migration tail | `20260815101138` | `20260815101138` | ✅ |
| public tables | 92 | 92 | ✅ |
| public functions | 248 | 248 | ✅ |
| SECURITY DEFINER | 236 | 236 | ✅ |
| policies | 167 | 167 | ✅ |
| triggers | 33 | 33 | ✅ |
| cron | 1 | 1 | ✅ |
| `mc_internal` fn/secdef | 3 / 3 | 3 / 3 | ✅ |

**MC function posture (live md5, all frozen):** execute `7a526354…` (INVOKER, `secdef=false`) · `_mc_begin_action` `f47260ef…` (DEFINER) · `_mc_commit_action` `ce36c5fe…` (DEFINER) · `_mc_lookup_action` `5d940037…` (DEFINER) · `assign_class_distribution` `03a1510b…` (DEFINER) · `get_mission_control_actions` `3596633c…` (DEFINER). All `search_path=''`.

**Ledger (`mission_control_action_requests`) sealed:** authenticated = SELECT-only (INSERT/UPDATE/DELETE false); 1 policy (`…_select_own`); columns include `intent_fingerprint`, `intent_hash_version`.

## 3 · Drift analysis

**Canonical ↔ Live: NO DRIFT.** Every inventory count, function md5, grant, and policy matches the Phase-3 closeout exactly. No reconciliation required; no STOP condition triggered. Proceeding to design.

## 4 · Decision substrate discovery

Full DB sweep, `public` + `mc_internal`, keyword net widened to `decision|approval|review|escalation|workflow|authorization|consent|request` (tables) and `approve|reject|decide|escalate|authorize|consent` (functions).

**Tables matched → classification:**

| Table | Class | Notes |
|---|---|---|
| `consents` | **B — unrelated domain** | FMN / media child-consent. Not MC governance. |
| `privacy_requests` | **B — unrelated domain** | `privacy_request` object (GDPR-style DSAR). Domain, not MC decisions. |
| `support_requests` | **B — unrelated domain** | `support_case` object. Domain, not MC decisions. |
| `mission_control_action_requests` | **C — false positive** | The ledger itself (matched on "request"). Not a decision table. |

**Functions matched → classification:**

| Function | Class | Notes |
|---|---|---|
| `moment_is_approved` | **B — unrelated domain** | FMN MIN-consent (group-moment). Not MC. |
| `media_consent_check` | **B — unrelated domain** | Media consent gate. Not MC. |

**Verdict:** **ZERO Mission Control decision substrate.** No approval object, no decision state, no escalation concept, no risk-policy engine, no human-approval boundary, no decision audit event under Mission Control. Category-A (MC-related) matches = none. The Decision Control Plane is **greenfield** — confirmed with the widened net.

## 5 · Risk model assessment

**Where risk lives (verified, not assumed):**
- `mission_control_object_registry` (D349, the *object* catalog) — columns: `object_type, kind, scope, privacy_policy, projector_status, discovery_fields, forbidden_groups, capability_vocab, sort_order, notes, context_requirements`. **`risk_level` column present = FALSE.** The object registry carries **no** risk. (STEP 3's premise corrected by live evidence: the risk model is not on the object registry.)
- `mission_control_action_registry` (the *action* registry) — **`risk_level` present = TRUE**, with `CHECK (risk_level = ANY (ARRAY['LOW','MEDIUM','HIGH','CRITICAL']))`. Present values today: **LOW, MEDIUM**. HIGH/CRITICAL are valid-but-unused.

**Current actions:** `class.assign` (active, MEDIUM, adapter `class.assign.v1`) · `class.edit` (disabled, LOW, no adapter). **Active/dispatchable = 1** (`class.assign`).

**Enforcement (verified by function-body inspection):**

| Function | References `risk`? | Meaning |
|---|---|---|
| `_mc_lookup_action` | yes | carries risk_level as authority metadata |
| `get_mission_control_actions` | yes | surfaces risk_level to FE (presentation) |
| `execute_mission_control_action` | **no** | never branches on risk |
| `_mc_begin_action` | **no** | forge ignores risk |
| `_mc_commit_action` | **no** | terminal write ignores risk |

**Verdict: B — METADATA ONLY.** `risk_level` is surfaced (registry → lookup → gaa → FE) but has **zero execution enforcement and zero approval routing**. The 4-tier vocabulary is already DB-constrained, so the Decision Layer inherits a ready tier alphabet and becomes risk's first *executable* consumer. No assumption made — enforcement absence is body-verified.

## 6 · Gate placement recommendation

Live runtime (verified):

```
User
 → execute_mission_control_action            [INVOKER · sole dispatch path]
    → _mc_lookup_action (registry: risk_level, adapter_key, contracts)
    → context + input validation
    → RLS object gate
    → _mc_begin_action  ← intent_fingerprint forged here (G3)
    ├─ inserted → adapter resolver (static CASE) → assign_class_distribution → _mc_commit_action → ledger
    └─ replay guard
```

**Option A — before begin.** Gate before the fingerprint exists.
✗ **Rejected.** No stable correlation key yet (fingerprint forged *inside* begin), and any gate outside the sealed dispatch is bypassable since `authenticated` holds direct EXECUTE. Advisory only.

**Option B — after begin, before adapter.** Gate in-band, at the seat where the P3 replay guard already lives.
✓ **Enforcement seat.** execute is the sole path; ledger DEFINER-sealed ⇒ unbypassable. `intent_fingerprint` already forged ⇒ it becomes the decision correlation key. Precedent: P2/P3 already evolved execute's *body* while holding signature + envelope + INVOKER + no-dynamic-SQL.

**Option C — async pending/resume.** For tiers requiring approval, the intent parks (no adapter/commit) and resumes via a separate authorized call once `approved`.
✓ **The human-in-the-loop half.**

**⭐ RECOMMENDATION — HYBRID B + C.** Gate *evaluation* after begin / before adapter (B, the only bypass-proof seat), keyed on `intent_fingerprint`; approval *wait* via async park→resume (C). Reject A. This reuses G1 (tier source), G3 (fingerprint = decision integrity key), G4 (sealed ledger = bypass-proofing) — the very reason the Decision Layer sequences *after* B6.3.

## 7 · Decision Control Plane architecture

**Design intent (no SQL, no DDL):**

```
intent → registry (WHAT) → tier lookup (risk_level) → begin (fingerprint, G3)
       → decision evaluation ── requires approval? ── no ─→ adapter (WHO) → commit → ledger
                              │
                              yes → open/find decision (keyed on fingerprint)
                                  → PARK · return DECISION_REQUIRED
                                        │  approver (≠ requester) resolves
                                        ▼
                              approved → resume → adapter (WHO re-check) → commit → ledger
                              rejected / expired / cancelled → terminal, no execution
                                  └─→ decision event (later: Memory projection)
```

**Core objects (candidate; bounded — *not* a workflow engine):**

- **`mission_control_decisions`** — one decision per governed intent.
  - *Why it exists:* the missing WHETHER axis; a durable, auditable record binding an approval to an exact intent.
  - *Ownership:* client SELECT-only; INSERT/UPDATE DEFINER-exclusive (mirrors the ledger seal). Owner `postgres`; grants `{authenticated SELECT}` + DEFINER helpers.
  - *Lifecycle:* opened by the gate → resolved by an authority → terminal & immutable.
  - *Candidate fields:* `id · action_request_id (FK→ledger request_id) · intent_fingerprint · intent_hash_version · object_type · object_id · action_key · risk_level (snapshot) · state · requested_by · decided_by · decision_reason · expires_at · created_at · updated_at`.
- **Decision event** — *not a separate table in v1.* The decision row transitions *are* the event stream (created/resolved timestamps + state). A dedicated `decision_events` table is deferred until the Memory Layer needs an append-only projection source (avoids premature generality; §10 over-engineering risk).
- **`decision_approval`** — *not needed as a separate object* in v1: a single approver resolves a single decision; approval is the `pending→approved` transition on the decision row itself. Multi-approver / quorum is a later extension, explicitly out of scope.

**Bounded doctrine (mirrors D362.3/D362.4):** exactly one decision per `intent_fingerprint`; fixed 5-state machine; tier source = registry `risk_level` (no policy DSL); no dynamic dispatch; no generic workflow surface.

## 8 · Security model

**State machine:**

```
   (open) pending ─┬─► approved   (terminal · sole state that unlocks resume)
                   ├─► rejected   (terminal)
                   ├─► expired    (terminal · expires_at reached)
                   └─► cancelled  (terminal · requester/admin withdraw)
```

Transitions: only `pending` is non-terminal; each terminal state is immutable; a resume is honored **only** when a decision's `intent_fingerprint` equals the recomputed fingerprint of the resuming call (reuses G3 to defeat approve-then-swap TOCTOU).

**Separation of duties:**
- `requested_by` = actor (`public.current_profile()`), never client-supplied.
- `decided_by` = approver, resolved by a scope policy (class-scoped ⇒ school authority/master; consistent with the D48 privacy moat — platform admins must not be the default approver for tenant-scoped actions).
- **Self-approval prevention (hard invariant):** the resolve helper enforces `decided_by <> requested_by`; non-overridable.

**Bypass prevention:** in-band gate (B) + sole dispatch path + DEFINER-write-sealed ledger *and* decisions table (client SELECT-only). No path reaches the adapter without passing the gate.

**No privilege elevation:** an approved decision authorizes the *intent to proceed*; on resume the adapter re-runs its own WHO-authz against the **original actor** (D362.5 preserved). Approval is a third gate (WHETHER), never a substitute for the adapter's WHO gate.

**Commit boundary preserved:** `_mc_commit_action` remains the sole terminal writer, unchanged. The Decision Layer governs *whether* adapter+commit are reached; it never writes execution results (G4 seal intact).

## 9 · Migration phases proposal (NO SQL — none authorized)

**Phase 1 (this document) = architecture foundation only.** Per the Phase-1 scope boundary, Phase 1 **MUST NOT**: modify execute · add a decision gate · change the ledger · add any approval requirement · change FE · add any migration. Phase 1 delivers the audit + design; **zero DB touch.**

Subsequent phases — proposed sequence, each separately authorized:
- **Phase 2 — Foundation build (dormant).** `mission_control_decisions` table + `_mc_open_decision` / `_mc_resolve_decision` DEFINER helpers + tier→requires_approval map + RLS SELECT for stakeholders. **No execute wiring** — machinery inert. No backfill. (D92 3-block + fail-closed VERIFY + `NOTIFY pgrst`.)
- **Phase 3 — Execution integration.** Wire the gate into execute after begin / before adapter (park + `MC_ACTION_DECISION_REQUIRED`; proceed only on fingerprint-matched `approved`) + resume path. Preserve execute signature + envelope + INVOKER + no-dynamic-SQL.
- **Phase 4 — Canonicalization.** RULES **D364** + SYSTEM_MAP **v1.52** + `DMA_HANDOFF_V128-B7-*` complete replacement files; prior blocks → HISTORICAL SNAPSHOT.

**Safest rollout property:** with a *LOW/MEDIUM → auto-proceed, HIGH/CRITICAL → require decision* map, the gate ships **dormant** — the only live dispatchable action is `class.assign` (MEDIUM), so no live traffic is gated until a HIGH/CRITICAL action is first registered.

## 10 · Risks

- **Approval deadlock** — empty approver set or all approvers = requester ⇒ intent never approvable. *Mitigation:* fail-closed "no eligible approver" detection at open-time (no un-approvable row created) + `expires_at` TTL.
- **Privilege escalation** — approver green-lights an action they couldn't run. *Mitigation:* adapter re-runs WHO-authz against the original actor on resume; approval never elevates domain rights.
- **Bypass path** — direct execute call skipping the gate. *Mitigation:* in-band seat + sole dispatch path + DEFINER-sealed ledger & decisions (§8).
- **TOCTOU (approve → resume)** — intent or domain state changes between approval and resume. *Mitigation:* fingerprint binding voids approval on intent change; domain-state changes still hit adapter guards (`distribution_exists → CONFLICT`).
- **Over-engineering** — drift toward a generic workflow/BPM engine (multi-approver, quorum, DSL). *Mitigation:* one decision per fingerprint · fixed 5-state machine · registry-sourced tier (no DSL) · single-approver v1 · defer `decision_events` until Memory needs it. Same restraint doctrine as D362.3/D362.4.

## 11 · CTO decisions required

**Q1 — Gate placement.** ⭐ Hybrid **B + C** (evaluate after begin / before adapter, keyed on fingerprint; async park→resume for the wait). Reject A (pre-begin / bypassable). *Decision?*

**Q2 — Risk model: registry-only or separate policy engine?** ⭐ **Registry-only** in v1 (risk_level + existing 4-tier CHECK already present). Defer a per-tenant policy engine. *Decision?*

**Q3 — Approval granularity: per action / per object / per tenant?** ⭐ **Per action-instance** (per `intent_fingerprint`) for the decision; **approver authority resolved per object scope** (school-scoped for class actions). *Decision?*

**Q4 — Should LOW/MEDIUM/HIGH/CRITICAL become executable governance?** ⭐ **Yes, bounded** — map recommended **LOW/MEDIUM auto-proceed · HIGH/CRITICAL require decision** (gate ships dormant given current actions). *Confirm mapping; confirm whether MEDIUM should require approval.*

**Q5 — Should the Decision Layer own Memory events later?** ⭐ Decision **emits** decision events (source of truth); Memory **projects** them. Do not make Decision own Memory storage. Defer a dedicated `decision_events` table until Memory needs it. *Decision?*

**Additional decision surfaced by this audit —**
**Q6 — Object-scope approver authority for class actions:** confirm class-scoped decisions are approved by **school authority (principal/master)**, *not* platform admin (D48 privacy-moat consistency). *Decision?*

---

## STATUS

**DESIGN ONLY — WAITING CTO APPROVAL.**
No implementation authorized. No migration · no SQL · no mutation · no FE · no canonical write. Phase 1 = architecture foundation only (zero DB touch).

*Endpoint at audit time: RULES **D363** · SYSTEM_MAP **v1.51** · HANDOFF **V128-B6.3-PHASE-3** · backend tail `20260815101138` · FE main pin `2.8.5`.*
