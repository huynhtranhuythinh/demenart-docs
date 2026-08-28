# V128-B9.1 — AUTHORITY CONTRACT & RESOLUTION DESIGN FREEZE

**Mode:** DESIGN FREEZE ONLY · conceptual architecture contract
**Implementation:** 0 · **Migration:** 0 · **SQL:** 0 · **DB mutation:** 0 · **FE/UI:** 0 · **Canonical append:** 0 · **Invariant minted:** 0
**Status:** Ready for CTO ratification (Jean + ChatGPT architecture review)

---

## STEP 0 — CANONICAL BOOT (verified, zero drift)

| File | Endpoint required | Live | Status |
|---|---|---|---|
| `DMA_RULES.md` | D365 | D365 | ✓ |
| `DMA_SYSTEM_MAP.md` | v1.53 | v1.53 | ✓ |
| `DMA_HANDOFF_V128-B8_CLOSEOUT.md` | V128-B8 CLOSEOUT | Decision Lifecycle Foundation | ✓ |
| Backend tail | `20260815182235` | `v128_b8_i1_decision_lifecycle_foundation` | ✓ |

B8 CLOSEOUT confirms: governed path **dormant**; `_mc_transition_decision` = sole mutation boundary; authority resolver / delegation / notification / inbox UI / workflow builder / AI recommendation / child.transfer / object-scope expansion **all deferred**. B9 audit live re-pin (decisions 0 · transitions 0 · action_requests 12 · class.assign MEDIUM · class.edit disabled LOW) accepted per B9.1 boot. **No drift → freeze proceeds.**

**Accepted audit conclusion:** DMA authority determination today is **distributed** across (1) action projection guards, (2) RLS/object visibility, (3) adapter guards, (4) decision RPC guards. B8 centralized **state mutation**; B8 did **not** centralize **authority determination**. B9.1 freezes the conceptual contract of an independent Authority Resolver primitive.

---

## PART 1 — AUTHORITY RESOLVER DEFINITION

### What the Authority Resolver IS

A **pure policy-decision primitive**. It answers exactly one question, deterministically and without side effects:

> *"Does this actor have authority to exercise this capability, on this object, in this context — and from which authority source?"*

Properties:

- **Read-only.** Never mutates decision, business object, ledger, or audit.
- **Deterministic.** Same inputs → same verdict. No dependence on row-selection order, wall-clock, or hidden state.
- **Explainable.** Returns not just a boolean but the **authority source** and **machine-readable reason codes**.
- **Consumed, not embedded.** Callers (projection, executor, decision layer) *invoke* it; they do not re-derive authority independently.

### What the Authority Resolver IS NOT — explicit rejections

| It is NOT | Because |
|---|---|
| **A simple role checker** | Role is one *input* to the verdict, not the verdict. `master_admin` of School A has no authority over School B's object. `role IN (...)` moved into a function is not an authority model (see Risk 1). |
| **A permission-checker replacement** | `profiles.permissions[]` / `has_permission()` is one *possible authority source*, not the authority model. It is currently 0/27 populated and unused by Mission Control. |
| **An RLS replacement** | RLS governs **row visibility** (can the actor even SELECT the row). It stays as a coarse pre-filter and defense-in-depth. The resolver operates on *already-resolved* object context. |
| **An adapter replacement** | The adapter enforces **domain invariants + transactional safety** (e.g., cannot assign a teacher outside the school; entitlement gating; `distribution_exists` dedup). Those stay local. |
| **A lifecycle-controller replacement** | `_mc_transition_decision` keeps its B8 boundary: lock + legal transition + mutation + immutable evidence. No role/school/delegation logic is ever pushed into it. |

### Authority definition (frozen)

```
Authority =
    WHO                    (actor identity)
  + WHAT                   (capability / action_key)
  + WHERE                  (organization scope)
  + ON WHICH OBJECT        (resolved object context)
  + UNDER WHICH            (decision context: self-approval prohibition,
    DECISION CONTEXT        requester identity, decision phase)
```

Authority is a **contextual verdict**, not a classification and not an entitlement.

---

## PART 2 — INPUT CONTRACT FREEZE (mandatory decision)

**FROZEN:** `capability` / `action_key` is the **first-class, primary** authority input.
**FROZEN:** `decision_type` is **secondary/downstream context** — it MUST NOT be the primary authority anchor.

### Why capability/action_key is primary — not decision_type

Authority binds to **the action being authorized (WHAT)**. `decision_type` describes the *lifecycle/workflow wrapper* around an action once a risk gate routes it into a Decision.

The decisive argument is path symmetry:

```
MEDIUM action  → execute_mission_control_action → adapter        (NO decision wrapper)
HIGH+  action  → execute → Decision open → resolve → transition  (decision wrapper)
```

- The **capability/action_key is present in BOTH paths** (it lives in the action registry).
- `decision_type` **only exists in the HIGH+ path.**

If `decision_type` were the primary input, every **direct-execute MEDIUM action would have no authority anchor** — the resolver could not authorize the most common path at all. Capability is the only identifier stable across direct-execute and decision-gated flows. Therefore capability/action_key must anchor authority; decision_type merely enriches it (self-approval prohibition, requester identity, decision phase).

### Conceptual contract signature (no API, no SQL, no implementation)

```
resolve_authority(
    actor,                      -- authenticated + profile identity
    capability_or_action_key,   -- PRIMARY: WHAT is being authorized
    object_context,             -- resolved, typed object context (from B3 seam)
    decision_context            -- SECONDARY/optional: requester, self-approval rule, phase
)
```

`decision_context` is optional: absent for direct-execute authorization, present when a Decision lifecycle wraps the action.

---

## PART 3 — AUTHORITY MODEL BOUNDARY

### Dependency chain (frozen ordering)

```
Actor
  ↓
Identity            (auth.uid → profile; single authority-bearing identity — see Part 5)
  ↓
Role                (coarse classification — input)
  ↓
Permission / Grant  (explicit entitlement datum — one possible source)
  ↓
Organization Scope  (school / membership)
  ↓
Object Context      (resolved via existing B3 registry + context resolver)
  ↓
Capability          (the WHAT — action_key / capability vocabulary)
  ↓
AUTHORITY RESOLVER  ← the missing primitive; consumes all of the above
  ↓
Decision / Execution
```

The resolver **consumes** the chain above it. It **never re-implements** object resolution — the B3 context seam (`resolve_mission_control_object_context` / `validate…` / `…match`) is a dependency input, not something the resolver rewrites.

### Role vs Permission vs Capability vs Authority

| Concept | Nature | Example | Role in authority |
|---|---|---|---|
| **Role** | Coarse actor classification | `master_admin`, `lead_teacher` | **Input.** Necessary, never sufficient. `master_admin` alone ≠ authority over a specific object. |
| **Permission / Grant** | Explicit entitlement datum | `profiles.permissions[]`, `has_permission()` | **One possible authority *source*.** A grant that *may* feed the verdict. Not the verdict. |
| **Capability** | Named action type (the WHAT) | `class.assign`, `class.edit` | **Vocabulary.** Describes what action *exists*. Says nothing about who may exercise it. |
| **Authority** | Contextual verdict | eligible + source + reasons | **The output.** `WHO × WHAT × WHERE × OBJECT × DECISION CONTEXT` resolved to a deterministic, explainable verdict. |

Key inequalities frozen:

```
Role         ≠ Authority   (Role → input to Authority)
Permission   ≠ Authority   (Permission → possible source of Authority)
Capability   ≠ Authority   (Capability = WHAT; Authority = WHO may do WHAT here)
```

---

## PART 4 — AUTHORITY vs ENFORCEMENT BOUNDARY (frozen)

### Ownership split

**Authority Resolver OWNS:**
- Authority policy decision
- Eligibility verdict (`eligible`)
- Authority source (`authority_source`)
- Reason codes (`reason_codes`)

**Authority Resolver does NOT own:**
- Data integrity
- Transaction safety
- Business invariants
- RLS enforcement

**Adapter KEEPS (domain safety, defense-in-depth):**
- Domain invariant checks (e.g., teacher must belong to school; entitlement/license gate; `distribution_exists` dedup)
- Impossible-state prevention
- Transactional safety

**RLS KEEPS:**
- Row visibility pre-filter (a coarse necessary gate, not the authority verdict)

**Executor KEEPS:**
- Orchestration, context validation, registry lookup, risk routing — and now **consumes the resolver verdict** rather than re-deriving authority.

### The single-source contract (the most important freeze point)

> The Authority Resolver is the **single deterministic source of the authority verdict.**
> The adapter's residual role/school checks, where retained, are **domain-safety defense-in-depth — not a parallel authority policy engine.**

This directly closes **Risk 3 (policy divergence)**: today projection may allow while adapter denies, or Decision may admit an actor projection would not. Under the freeze, all four layers derive their authority answer from one resolver; only *domain-safety* checks remain distributed. The adapter must **not** evolve into a second authority policy engine.

Clarifying the audit's "visibility vs authority mixed" finding: RLS returning *object-not-found* is a **visibility** outcome, not an **authority** verdict. The contract keeps these distinct — the resolver reasons over resolved object context; RLS remains a safety net beneath it.

### Migration direction (conceptual)

```
CURRENT                              FUTURE
────────                             ──────
Projection guard   ┐                 Authority Resolver = canonical
Adapter guard      ├─ distributed    authority policy decision (single source)
Decision RPC guard ┘  authority
                                     Adapter = domain safety only
                                     RLS     = row visibility only
                                     Executor/Decision = consume verdict
```

Authority *policy* centralizes; enforcement *layers* remain but stop making independent authority decisions.

---

## PART 5 — IDENTITY CARDINALITY DECISION

### Current live state

- `profiles.user_id` → FK to `auth.users(id)`, **no UNIQUE constraint**
- duplicate `user_id` = **0** · max profiles/user = **1**
- helpers resolve via `LIMIT 1` (e.g., `current_profile()`)
- Invite flows (D93) already handle non-UNIQUE `user_id` by de-duplicating on email and linking the existing `user_id` rather than creating a second profile — i.e., the *operational* intent is already 1:1.

### The two options

**Option A — `auth.user → exactly one authority-bearing profile`**
**Option B — `auth.user → multiple profiles / context identities`**

### Analysis (not implementation convenience — architectural)

| Dimension | Option A (1:1) | Option B (1:many) |
|---|---|---|
| **Authority complexity** | Actor identity is unambiguous; resolver takes the profile as the stable authority-bearing identity. | Every `resolve_authority` call must carry an explicit *acting-identity selector*; ambiguity if omitted (Risk 9). |
| **Audit implications** | `audit_logs.actor_id = profiles.id` (D88) maps cleanly 1:1; provenance unambiguous. | Audit must additionally record *which* identity acted; provenance branches. |
| **Resolver complexity** | Lower — one identity in, one verdict out. | Higher — identity resolution becomes part of every authority call. |
| **Delegation implications** | Delegation modeled cleanly as an **authority source** (a grant from A to B) layered on top of a single identity. | Multi-profile blurs delegation vs identity — the wrong primitive: "acting as another profile" is not the same as "was delegated authority." |

### Recommendation (frozen as design decision, not yet as schema)

**Option A** — the authority model assumes **one authenticated user → exactly one authority-bearing profile.** Representation and delegation are modeled as **authority *sources*** on top of that single identity, never as multiple profiles.

**Precondition flagged for the implementation milestone (NOT done here):** enforcing a `UNIQUE(user_id)` constraint is an implementation step requiring a reconciliation pass — (a) re-verify duplicates still = 0 at implementation time, and (b) confirm the D93 invite/link flow (which today tolerates non-UNIQUE `user_id`) is not broken by the constraint. This is a **precondition to review**, deliberately deferred out of the freeze.

---

## PART 6 — ADOPTION STRATEGY (migration boundary only — no migration)

### Big bang vs Strangler

**Big bang** — rewrite all authority sites (≈51 `is_admin`, ≈29 hardcoded `master_admin/sub_admin`, ≈18 `same_school`) to call the resolver in one pass. **Rejected:** maximal blast radius on a live multi-tenant system; no rollback granularity; couples an authority *refactor* with live behavioral *risk*; violates the standing discipline of contained, verifiable steps.

**Strangler (recommended):**

```
Phase 1  New governed actions authorize via resolver from birth.
Phase 2  Decision paths (open / inbox / resolve / cancel) consume resolver.
Phase 3  Existing adapters migrate authority policy into resolver
         (keeping domain-safety checks local).
Phase 4  Legacy admin RPCs (broad is_admin surface) migrate last.
```

### Why this ordering

- **Phase 1 first** — new surfaces have no legacy behavior to preserve; the resolver proves itself with zero regression risk.
- **Phase 2 next** — the four Decision functions concentrate the *highest* authority duplication (`master/sub + same school + not-self` repeated) on the *smallest*, most-contained, highest-value surface. Consolidating here removes the most dangerous duplication early and hard-centralizes self-approval prohibition (closes Risk 4).
- **Phase 3** — adapters migrate authority *policy* only; domain-safety checks stay, preserving defense-in-depth.
- **Phase 4 last** — legacy admin RPCs are the largest count but lowest decision-criticality; safest to migrate once the contract is battle-tested.

Each phase is independently verifiable and independently rollback-able. Crucially, freezing the authority-source contract *before* Phase 3 is what prevents **Risk 1** (the resolver degenerating into relocated `role IN (...)` hardcode): adapters migrate *into* a contract, not into an empty function.

---

## PART 7 — FUTURE OUTPUT CONTRACT (conceptual — no enum mint, no invariant)

```
eligible: boolean

authority_source:            -- illustrative, NOT a minted enum
    platform_role
    organization_role
    explicit_permission
    assignment
    delegation               -- future only
    none

reason_codes:                -- illustrative, NOT canonical vocabulary
    actor_unresolved
    object_context_mismatch
    organization_scope_mismatch
    role_not_eligible
    capability_not_granted
    self_decision_forbidden
    authority_granted
```

**Contract principle:** output must be **deterministic, explainable, and machine-readable**, so that no caller hardcodes its own exception strings. The final `authority_source` enum and `reason_code` taxonomy are **minted at ratification/implementation**, not here.

---

## PART 8 — CTO REVIEW PACKAGE

### 8.1 Authority Resolver conceptual contract

```
resolve_authority(actor, capability_or_action_key, object_context, decision_context)
    → { eligible, authority_source, reason_codes }

Pure · deterministic · read-only · explainable · consumed-not-embedded.
```

### 8.2 Dependency graph

```
        ┌──────────────┐
        │    Actor     │
        └──────┬───────┘
               ▼
        ┌──────────────┐
        │   Identity   │   single authority-bearing profile (Option A)
        └──────┬───────┘
               ▼
        ┌──────────────────┐
        │ Role / Grants    │   inputs / possible sources
        └──────┬───────────┘
               ▼
        ┌──────────────────┐
        │ Organization     │   school / membership
        └──────┬───────────┘
               ▼
        ┌──────────────────┐
        │ Object Context   │   B3 resolver + registry (dependency, not rebuilt)
        └──────┬───────────┘
               ▼
        ┌──────────────────┐
        │ Capability       │   action_key / capability vocabulary (PRIMARY input)
        └──────┬───────────┘
               ▼
        ┌──────────────────┐
        │ AUTHORITY VERDICT│   ← the primitive B9 identified as missing
        └──────┬───────────┘
          eligible / denied (+ source + reasons)
               ▼
        ┌──────────────────┐
        │ Decision Layer   │   authority resolved BEFORE lifecycle mutation
        └──────┬───────────┘
               ▼
        ┌──────────────────┐
        │ Lifecycle Ctrl   │   _mc_transition_decision — mutation only (B8 boundary intact)
        └──────────────────┘
```

### 8.3 Boundaries with existing layers

| Layer | Owns | Relationship to resolver |
|---|---|---|
| **RLS** | Row visibility | Coarse pre-filter beneath the resolver. Not the verdict. Object-not-found ≠ not-authorized. |
| **Adapter** | Domain invariants, transactional safety | Keeps domain-safety defense-in-depth. Must NOT be a parallel authority engine. Consumes/trusts the verdict for authority. |
| **Executor** | Orchestration, context validation, risk routing | Consumes the verdict instead of re-deriving authority. |
| **Decision lifecycle** | State mutation, immutable evidence | Authority resolved **before** `_mc_transition_decision`. Controller stays mutation-only — no role/school/delegation logic pushed in (B8 boundary preserved). |

### 8.4 Identity model recommendation

**Option A — one authenticated user → exactly one authority-bearing profile.** Delegation/representation modeled as authority *sources*, not multiple profiles. `UNIQUE(user_id)` enforcement deferred to implementation, gated on a reconciliation pass against the D93 invite/link flow.

### 8.5 Adoption strategy

**Strangler, 4 phases:** new governed actions → decision paths → adapter authority policy → legacy admin RPCs. Contained, independently verifiable, rollback-able per phase. Contract frozen before Phase 3.

### 8.6 Risks if implemented incorrectly

| # | Risk | Guard in this contract |
|---|---|---|
| 1 | **Role becomes authority** (resolver = relocated `role IN (...)`) | Authority-source contract frozen *before* any adapter migrates (Part 4, Part 6). |
| 2 | **Capability theatre** (registry has `capability` but authority ignores it) | Capability is the PRIMARY input (Part 2). |
| 3 | **Policy divergence** (projection allows, adapter denies) | Single-source verdict contract (Part 4). |
| 4 | **Self-approval regression** | `decision_context` carries requester identity + self-approval rule; consolidated in Phase 2 (Part 2, Part 6). |
| 5 | **Cross-school decision leakage** | Object context is a mandatory resolver input; org scope in the chain (Part 3). |
| 6 | **Lifecycle-controller pollution** | `_mc_transition_decision` stays mutation-only; authority resolved before it (Part 4, 8.3). |
| 7 | **Delegation built too early** | Delegation modeled as an authority *source* on a single identity; deferred (Part 5, Part 7). |
| 8 | **Multi-object expansion multiplies duplication** | Strangler + single source before object expansion (Part 6). |
| 9 | **Non-deterministic identity** (`current_profile() LIMIT 1` under future 1:many) | Option A fixes 1:1 as the authority-identity invariant (Part 5). |

### 8.7 Recommended next milestone after B9.1

**B9.2 — Authority Contract Canonical Ratification (governance, still no implementation).**
After CTO (Jean + ChatGPT) ratify this freeze, append the authority contract to `DMA_RULES.md` (new D-rule series) and `DMA_SYSTEM_MAP.md` — mint the `authority_source` enum and `reason_code` taxonomy as canonical vocabulary, and record the Option-A identity invariant + its `UNIQUE(user_id)` reconciliation precondition. **No SQL, no migration** — this is the canonical-append step the freeze deliberately withholds.

**Then B9.3 — Phase-1 resolver skeleton** (first implementation: resolver authorizes one *new* governed action end-to-end, verify matrix, zero legacy touch).

Delegation, object expansion (`child.transfer`, session/school), multi-approver/quorum, notification, inbox UI, workflow builder, AI recommendation, and HIGH/CRITICAL activation **remain deferred** until the contract is ratified and the resolver is proven on the contained surface.

---

## STRICT STOP — honored

No canonical mismatch (boot passed). No DB mutation, SQL, migration, FE, or UI was required or performed to produce this contract. **B9.1 is DESIGN FREEZE ONLY — architecture contract ready for CTO ratification.**
