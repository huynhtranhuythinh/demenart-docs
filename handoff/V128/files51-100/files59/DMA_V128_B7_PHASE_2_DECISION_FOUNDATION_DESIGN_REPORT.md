# V128-B7 PHASE-2 DECISION FOUNDATION DESIGN REPORT

> **Mode:** AUDIT-FIRST / DESIGN-ONLY. No migration · no SQL apply · no mutation · no function replace · no FE · no canonical append · no memory reconstruction.
> **Sources:** canonical files on disk + live read-only Supabase audit (`xcvhacymrbhdhohyylyq`) + real function/constraint bodies + CTO-approved Phase-1 decisions. Audit 2026-08-15.
> **Status:** DESIGN ONLY — WAITING CTO APPROVAL. No implementation authorized.

---

## 1 · Canonical state

Read directly (not memory). Required files all present: `DMA_RULES.md`, `DMA_SYSTEM_MAP.md`, `DMA_HANDOFF_V128-B6.3-PHASE-3_CLOSEOUT.md`, `DMA_V128_B7_PHASE_1_AUDIT_REPORT.md`.

- **Endpoint:** RULES **D363** · SYSTEM_MAP **v1.51** · HANDOFF **V128-B6.3-PHASE-3**.
- **Milestone:** V128-B6.3 CLOSED (Owner-stamped 2026-08-15); G1·G2·G3·G4 CLOSED; 8/8 frozen invariants.
- **Next gate:** V128-B7 (new milestone) — Phase 1 CTO-approved, entering Phase 2 design.
- **Frozen invariants carried into B7:** execute = SECURITY INVOKER + public contract frozen · `_mc_begin_action` = DEFINER server-owned forge · `_mc_commit_action` = DEFINER sole terminal writer · registry = WHAT (not approval engine) · adapter = HOW (Decision Layer never calls adapter directly).
- **CTO-approved Phase-1 decisions (locked):** Q1 Hybrid B+C gate · Q2 registry-only risk · Q3 per `intent_fingerprint` (1 fp = 1 decision) · Q4 LOW/MEDIUM→auto, HIGH/CRITICAL→approval · Q5 Decision emits, Memory projects · Q6 class-scoped approver = school authority/master, not platform admin.

## 2 · Live state (read-only re-pin)

| Metric | Live | B6.3 closeout | Match |
|---|---|---|---|
| Migration tail | `20260815101138` | `20260815101138` | ✅ |
| tables / fns / secdef / policies / triggers | 92 / 248 / 236 / 167 / 33 | 92 / 248 / 236 / 167 / 33 | ✅ |
| `mc_internal` fns | 3 | 3 | ✅ |

**Zero drift.** No STOP condition. Frozen MC md5s unchanged (execute `7a526354…` INVOKER; begin `f47260ef…`; commit `ce36c5fe…`; lookup `5d940037…`; adapter `03a1510b…`; gaa `3596633c…`).

## 3 · Decision substrate verification

Widened sweep (`…|resolution|resolve|…`):

| Match | Class | Note |
|---|---|---|
| `mission_control_action_requests` | C false-positive | the ledger (matched "request") |
| `privacy_requests`, `support_requests` | B domain | GDPR / support objects |
| `moment_is_approved`, `media_consent_check` | B domain | FMN / media consent |
| `resolve_mission_control_object_context` | C false-positive | MC **object-context** discovery resolver — not decision resolution |

**Verdict:** still **ZERO Mission Control decision substrate** (Category A = none). Greenfield confirmed a third time with the widest net. Building `mission_control_decisions` introduces no collision.

## 4 · Foundation object model — `mission_control_decisions`

**Purpose — the WHETHER axis.** A durable, auditable record that binds an *approval decision* to an *exact action intent*, gating whether a HIGH/CRITICAL intent reaches the adapter.

```
intent_fingerprint (G3) ──1:1──► mission_control_decisions ──gates──► adapter execution
        │                                                                    │
   ledger request_id ◄── action_request_id (FK) ────────── resume ───────────┘
```

**Candidate columns** (design only — no DDL). *Mut* = mutability.

| Column | Type | Why it exists | Security implication | Mut |
|---|---|---|---|---|
| `id` | uuid pk | decision identity | server-generated | **immutable** |
| `action_request_id` | uuid | FK → `mission_control_action_requests.request_id` (the parked intent); resume anchor | FK integrity; never client-set | **immutable** |
| `intent_fingerprint` | text | G3 fingerprint = the decision key; approval binds to exact intent | server-copied from ledger at open; **UNIQUE** (Q3: 1 fp = 1 decision) | **immutable** |
| `intent_hash_version` | smallint | fingerprint-scheme version | pairs with fp for verification | **immutable** |
| `action_key` | text | action snapshot; scope + audit | authority sourced from registry, not client | **immutable** |
| `object_type` | text | e.g. `class`; drives approver-scope resolution | resolution input | **immutable** |
| `object_id` | uuid | the class id; resolves `school_id` for approver eligibility | resolution input | **immutable** |
| `risk_level` | text | **snapshot** of tier at open-time | audit stability even if registry risk later changes; CHECK ∈ {LOW,MEDIUM,HIGH,CRITICAL} | **immutable** |
| `state` | text | lifecycle; CHECK ∈ {pending,approved,rejected,expired,cancelled} | transitions only via DEFINER helper, `pending`→terminal once | **mutable (once, server)** |
| `requested_by` | uuid | actor (`profiles.id` via `current_profile()`) | SoD anchor + audit; never client-set | **immutable** |
| `decided_by` | uuid null | approver (`profiles.id`); set on resolve | enforced `<> requested_by`; must be eligible approver | **mutable (null→once)** |
| `decision_reason` | text null | approver rationale | audit | **mutable (once, at resolve)** |
| `expires_at` | timestamptz | TTL → deadlock avoidance | set at open; drives expiry sweep | **immutable after open** |
| `created_at` | timestamptz | open time | audit | **immutable** |
| `updated_at` | timestamptz | last transition | audit | **mutable (system)** |

**Indexes/constraints (design):** UNIQUE(`intent_fingerprint`) enforces Q3 · FK(`action_request_id`) · index(`state`,`expires_at`) for the expiry sweep · index(`object_type`,`object_id`) for approver-inbox reads.

**Deliberate contrast with the ledger (surface for CTO):** the ledger intentionally has **no** unique index on `intent_fingerprint` (D363.5 — fp verified per-request, no cross-request dedup). The decision table **does** dedup on fingerprint (Q3 literal: 1 fp = 1 decision). Consequence: two different `request_id`s carrying a byte-identical intent share **one** decision. This is the correct Q3 realization but is a *divergence* from the ledger's fingerprint semantics → flagged as CTO gate G-A.

**Not built in v1** (Q5 + over-engineering guard): no separate `decision_events` table (state transitions + timestamps *are* the event stream; a dedicated projection table is deferred until the Memory Layer needs it); no `decision_approval` table (single approver = the `pending→approved` transition; multi-approver/quorum out of scope).

## 5 · State machine

```
   (gate opens, HIGH/CRITICAL only) ──► pending ─┬─► approved   (terminal · sole state that unlocks resume)
                                                 ├─► rejected   (terminal)
                                                 ├─► expired    (terminal · now() > expires_at)
                                                 └─► cancelled  (terminal · withdrawn)
```

- **Valid transitions:** only `pending → {approved, rejected, expired, cancelled}`. No terminal→any. `approved` is the **only** state that permits execution resume.
- **Terminal states:** approved, rejected, expired, cancelled — all immutable.
- **Who can transition:**
  - *open* (create `pending`): server gate via `_mc_open_decision` (DEFINER) — only for HIGH/CRITICAL with no existing decision for the fingerprint.
  - *approve / reject*: an **eligible approver** via `_mc_resolve_decision` (DEFINER) — enforces eligibility + SoD.
  - *expire*: system sweep `_mc_expire_decisions` (DEFINER; lazy-on-read and/or cron) — no human.
  - *cancel*: requester (self) or platform admin via `_mc_cancel_decision` (DEFINER).
- **Replay behavior:** on repeat of an intent, execute recomputes the fingerprint and finds the decision. `approved` (fp byte-identical) → resume; `pending` → `MC_ACTION_DECISION_REQUIRED` (replayed); `rejected`/`expired`/`cancelled` → terminal error. Approval honored **only** for a byte-identical fingerprint (defeats approve-then-swap).

## 6 · Security model

- **Ownership:** create = server gate (`_mc_open_decision`); resolve = eligible approver (`_mc_resolve_decision`); read = requester + eligible approvers (+ platform admin for audit).
- **Separation of duties (hard invariant):** `_mc_resolve_decision` enforces `decided_by <> requested_by`; non-overridable.
- **Privilege boundary (mirror the ledger seal exactly):** client (`authenticated`) = **SELECT only**; all mutation via DEFINER helpers in `mc_internal` (`search_path=''`, explicit REVOKE-then-GRANT per D15, `mc_internal` unexposed to PostgREST). No client INSERT/UPDATE/DELETE. Grants `{authenticated SELECT}` on the table + `{authenticated, postgres}` EXECUTE on helpers only.
- **RLS read design (avoid cross-table recursion):** simple `…_select_own` SELECT policy for the requester (mirrors ledger `_select_own`); the *approver inbox* is served by a DEFINER read RPC (`get_pending_decisions_for_school`) rather than a complex RLS predicate that would need a `classes`/`profiles` join in the USING clause.
- **Commit boundary preserved:** `_mc_commit_action` stays the sole terminal writer, unchanged. The Decision Layer governs *whether* adapter+commit are reached; it never writes execution results (G4 intact).
- **No privilege elevation:** an approved decision authorizes the *intent to proceed*; on resume the adapter re-runs its own WHO-authz against the **original actor** (D362.5). Approval ≠ execution right.

## 7 · Approver model (class-scoped, grounded in live schema)

Live evidence: `classes.school_id` exists; `profiles` = `{id, role, school_id, user_id}`; `is_school_admin()` = `current_profile_role() in ('master_admin','sub_admin')`; role enum `profile_role` = super_admin, content_admin, senior_content_admin, operation_admin, sales_admin, support_admin, **master_admin**, **sub_admin**, **lead_teacher**, **assistant_teacher**, primary_parent, secondary_parent, family_member.

**Resolution chain:**
```
decision.object_id (class)
   → classes.school_id                         (S)
approver profile P (the caller of _mc_resolve_decision)
   → P.role ∈ {master_admin, sub_admin}         (reuses is_school_admin semantics)
   → P.school_id = S                            (same-school scope)
   → P.id ≠ decision.requested_by               (SoD)
   ⇒ P is an eligible approver
```

**Who qualifies:**
- **`master_admin`** — school master/principal → **qualifies.**
- **`sub_admin`** — school sub-admin → **qualifies.**
- **`lead_teacher` / `assistant_teacher`** — **do NOT qualify** (teachers may *request*, never *approve*).
- Platform-tier roles (super_admin, content_admin, operation_admin, …) — **not** default approvers for class-scoped actions (Q6 + D48 privacy-moat consistency). A platform-level override, if ever wanted, is a separate explicit decision — out of v1 scope.

Note: `current_profile_role()` is SECURITY DEFINER but keys on `auth.uid()` (the actual caller), so eligibility naturally evaluates the *approver*, not the requester — even inside the DEFINER resolve helper.

## 8 · Execute integration design (Phase C — no code now)

**Current:** `begin → adapter → commit`.
**Future:**
```
_mc_begin_action  (fingerprint forged, G3)
   → decision gate: read risk_level (already in scope from _mc_lookup_action)
        ├─ tier ∈ {LOW, MEDIUM}          → proceed unchanged (auto)  → adapter → commit
        └─ tier ∈ {HIGH, CRITICAL}       → find/open decision by fingerprint
              ├─ approved (fp match)     → resume → adapter → commit
              └─ pending/none            → PARK · return MC_ACTION_DECISION_REQUIRED
```
- **Insertion point:** inside execute, **after `_mc_begin_action` returns, before the static CASE adapter resolver** (Q1 seat B; the P3 replay guard already lives at this tier).
- **Must preserve:** execute signature · return envelope · SECURITY INVOKER · no dynamic SQL (gate is a read + branch + DEFINER helper calls only) · commit boundary (`_mc_commit_action` sole terminal writer).
- **Ledger-status interaction (surface for CTO — gate G-C):** on *park*, the ledger row sits `status='processing'`, which today's replay guard reads as `IN_PROGRESS`. To make a parked intent return `DECISION_REQUIRED` (not `IN_PROGRESS`) on replay, execute's replay/gate path must consult the decision table **before** the in-flight check. **Recommendation:** keep the ledger schema unchanged (G4 invariant) and let the **decision state take precedence** in the gate/replay path — avoids adding an `awaiting_decision` ledger status. Alternative (adds a ledger status value) available if CTO prefers explicit ledger-side state.

## 9 · Migration phases (NO SQL — none authorized)

| Phase | Objective | Risk | Rollback |
|---|---|---|---|
| **A — Foundation table** | Create `mission_control_decisions` + constraints (UNIQUE fp, CHECK state/risk, FK) + indexes + `…_select_own` RLS + `authenticated` SELECT grant. **Dormant, no wiring.** | Minimal — additive table, no execute change, zero live effect. | `DROP TABLE mission_control_decisions` (0 data-repair). |
| **B — Decision helpers** | `mc_internal` DEFINER helpers: `_mc_open_decision`, `_mc_resolve_decision`, `_mc_cancel_decision`, `_mc_expire_decisions` + approver read RPC. `search_path=''`, D15 REVOKE/GRANT. Still **no execute wiring**. | Low — helpers callable but unused by execute; verify tight grants + SoD in VERIFY. | DROP helpers; table remains dormant. |
| **C — Execute integration** | Wire gate into execute (begin→gate→adapter/park) + resume path + tier map. D92 3-block, fail-closed VERIFY, PRE/POST equivalence for LOW/MEDIUM (must be byte-identical to today's path), `NOTIFY pgrst`. | **Highest** — touches frozen execute body; must hold 5 invariants; risk of altering the auto path. | Restore `execute_mission_control_action` to P3 md5 `7a526354c820ab5f767ee7403c6e917d`; helpers/table remain (dormant again). |
| **D — Canonicalization** | RULES **D364** + SYSTEM_MAP **v1.52** + `DMA_HANDOFF_V128-B7-*` complete replacement files; prior blocks → HISTORICAL SNAPSHOT. | Doc-only. | Remove block. |

**Dormancy property:** with Q4's map, the only live dispatchable action (`class.assign`, MEDIUM) stays on the **auto** path — the gate governs nothing live until a HIGH/CRITICAL action is registered. Phases A–C can land with zero effect on current class.assign traffic.

## 10 · Risks

1. **Approval deadlock** — no eligible approver, or all approvers = requester. *Mitigation:* `_mc_open_decision` fail-closed check that ≥1 eligible approver (`master_admin`/`sub_admin`, same school, ≠ requester) **exists** before creating a `pending` row (else distinct error, no un-approvable row) + `expires_at` TTL + expire sweep.
2. **Self-approval** — `decided_by = requested_by`. *Mitigation:* hard invariant in `_mc_resolve_decision`.
3. **Privilege escalation** — approver green-lights an action the actor can't run. *Mitigation:* adapter re-runs WHO-authz against the original actor on resume; approver eligibility ≠ execution grant.
4. **Stale approval** — approval sits while domain state shifts. *Mitigation:* fingerprint binding + adapter guards at resume (`distribution_exists → CONFLICT`) + TTL expiry.
5. **Intent mismatch** — resume under a different intent than approved. *Mitigation:* recompute fingerprint at resume; must equal `decision.intent_fingerprint`; else `MC_ACTION_REQUEST_CONFLICT`.
6. **Over-engineering** — drift to a generic workflow/BPM engine. *Mitigation:* 1 decision/fingerprint · fixed 5-state machine · registry-sourced tier (no DSL) · single-approver v1 · no `decision_events` table yet · no dynamic dispatch (D362.3/D362.4 restraint doctrine).

## 11 · CTO approval gates

Phase-1 (Q1–Q6) already approved. New gates required before **Phase A** build:

- **G-A — Fingerprint uniqueness.** Approve UNIQUE(`intent_fingerprint`) on decisions (Q3 realization) despite the ledger's deliberate non-uniqueness — i.e. two identical-intent requests share one decision. ⭐ *Recommend approve.*
- **G-B — Approver eligibility set.** Confirm eligible approver = role ∈ {`master_admin`,`sub_admin`} AND same `school_id` AND ≠ requester (reusing `is_school_admin` semantics); teachers excluded. ⭐ *Recommend approve.*
- **G-C — Park vs ledger status.** Keep ledger unchanged; decision state takes precedence in the gate/replay path (recommended) **vs** add an `awaiting_decision` ledger status. ⭐ *Recommend "keep ledger unchanged."*
- **G-D — Expiry mechanism.** Lazy-expire-on-read (+ optional cron sweep) **vs** cron-only. ⭐ *Recommend lazy + optional cron.*
- **G-E — Cancel authority.** Requester self-cancel + platform admin. ⭐ *Confirm.*
- **G-F — Authorize Phase A** (foundation table only, dormant) — or hold for further review. ⭐ *Awaiting your call.*

---

## STATUS

**DESIGN ONLY — WAITING CTO APPROVAL.**
No implementation authorized. No migration · no SQL · no mutation · no function replace · no FE · no canonical write. Nothing built.

*Endpoint at audit time: RULES **D363** · SYSTEM_MAP **v1.51** · HANDOFF **V128-B6.3-PHASE-3** · backend tail `20260815101138` · FE main pin `2.8.5`.*
