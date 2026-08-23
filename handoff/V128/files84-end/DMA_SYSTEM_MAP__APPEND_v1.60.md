<!-- ================================================================= -->
<!-- APPEND-ONLY BLOCK — paste VERBATIM at the END of DMA_SYSTEM_MAP.md -->
<!-- Anchor: immediately AFTER the v1.59 endpoint line                  -->
<!--   ("… Khối v1.58/D370 … = HISTORICAL SNAPSHOT (BẤT BIẾN).")         -->
<!-- Byte-prefix through v1.59 is IMMUTABLE. Do not rewrite history.    -->
<!-- ================================================================= -->

## 🗂️ SYSTEM_MAP v1.60 — V128-B11.2-A-AMENDMENT · EXECUTOR RESUME-PATH `class.edit` SUPPORT (Gate α — additive executor amendment; INERT, one-way door NOT opened) — 2026-08-19

> **Authority block hiện hành** (supersede v1.59; v1.59/D371 B11.1 inbox authority reconciliation = HISTORICAL SNAPSHOT BẤT BIẾN). Executor **resume-approved** dispatch now supports `class.edit.v1` (previously `class.assign.v1`-only → G1 blocker). **INERT:** `class.edit` stays LOW → new arm unreachable; lifecycle DORMANT 0/0; first committed decision (one-way door) deferred to Gate β. Canonical rule: **RULES D372**.

### Executor dispatch topology (v1.60 — runtime verified)

`public.execute_mission_control_action` (INVOKER, orchestration-only) — two dispatch sites, now symmetric on adapter coverage:

| Site | Reached when | Adapters handled | `v_result` built | Error map |
|---|---|---|---|---|
| **Fresh** (`v_inserted=true`) | first call; risk LOW/MED auto, or HIGH/CRIT opens decision then parks | `class.assign.v1` · `class.edit.v1` | per-arm (B9.4) | full (assign + edit codes) |
| **Resume-approved** (`v_inserted=false`, decision `approved`, C-2 actor guard) | replay after approval | `class.assign.v1` · **`class.edit.v1`** ⭐ (B11.2-A-α) | **per-arm** ⭐ (relocated) | **+ `no_editable_fields`/`name_invalid`/`age_group_invalid`/`level_invalid`** ⭐ |

Both sites: adapter *called* (never inline mutation) → `_mc_commit_action`. Mutation owner = adapter (`class_edit_v1` DEFINER, md5 `63f3ab5a…` unchanged). `else → raise adapter_unresolved` fallthrough preserved. Invariants: **Resolver = WHO · Decision Lifecycle = WHETHER · Adapter = HOW · Ledger = execution truth · Memory = projection.**

### INERT property (v1.60 — the safety of Gate α)

`class.edit` risk = **LOW** (unchanged) → LOW never enters the HIGH/CRIT decision branch → the resume-approved `class.edit.v1` arm is **runtime-unreachable**. `class.assign` = MEDIUM (auto, fresh). ⇒ amendment = **0 observable behaviour change**, resume path only made *ready*. Governed lifecycle DORMANT (0/0). **One-way door (first immutable committed transition) NOT opened** — deferred to Gate β.

### Frozen anchors (v1.60 — regression-proven UNCHANGED)

resolver `56b5e3f5…` · transition `fe0eea59…` · open_decision `b376edd7…` · authority_gate `bc5ea1a2…` · class_edit_v1 `63f3ab5a…` · resolve `bb79a521…` · cancel `924c3f9a…` · inbox `af21682d…` · expire `c57c40b8…` · **assign_class_distribution `03a1510b…` (new anchor, not in DDL scope)**. **Changed (this milestone):** executor `da733e9a…` → **`2228611a65c3678d092b1c15ecc19c68`** (INVOKER preserved; ACL `{authenticated,postgres}` exact-restored).

### Verification (v1.60 — rolled-back rehearsals, zero residue)

A class.assign regression PASS (A1 conflict → `MC_ACTION_CONFLICT`; A2 fresh success → `ok:true`+`CLASS_ASSIGNMENT_CREATED`+`{class_distribution_id}`) · **B class.edit@HIGH resume proof PASS** (open→`DECISION_REQUIRED`→approve→resume `ok:true replayed:true CLASS_UPDATED changed_fields:[name]`; decisions=1 transitions=2) · C replay PASS (0 dup decision/transition/net-mutation) · D adapter failure PASS (empty input → `no_editable_fields` → `MC_ACTION_INPUT_INVALID`, name unchanged, decision retryable) · E hash+inert PASS. Fixture rolled back: decisions/transitions 0/0, class.edit LOW, QA class unchanged, action_requests 12.

### Gate β flags carried (v1.60 — pre-existing B7 properties, NOT regressions)

1. **Approved-resume idempotency** — approved-HIGH replay re-dispatches the adapter (does not return stored payload). `class.assign` guarded by `distribution_exists`; **`class_edit_v1` has no uniqueness guard** → same-request_id replay re-runs the edit with live `p_input` (commit-guard + subtxn rolled it back in rehearsal). Harden before first committed decision.
2. **`intent_fingerprint` payload binding** — fingerprint excludes edited field values → an approved `class.edit` decision authorizes the *intent to edit class X*, not specific values; resume executes live `p_input`. Harden = bind values into fp, or snapshot input at open.

### Honest dormancy (v1.60 — MUST NOT over-claim)

Verified through rolled-back JWT-impersonated rehearsal + runtime hash/ACL verification only. Lifecycle **DORMANT** (0/0); no committed production decision; no HIGH/CRITICAL action activated. Resume `class.edit.v1` arm proven **mechanically**, **runtime-unreachable** until Gate β. First committed decision = deferred.

### Deferred (v1.60)

**Gate β** (separate re-gate): registry `class.edit` LOW→HIGH activation · synthetic fixture seed (G4; pilots off-limits) · first COMMITTED decision (opens one-way door 0/0→1/2 permanent) · disposition of the two flags above · data rollback + disarm + Gate β closeout. **Beyond:** `child.transfer` / object-scope · Strangler Phase-3 (`assign_class_distribution` / class.assign executor authority) · quorum/multi-approver · enum mint · `UNIQUE(user_id)` · delegation · notification · inbox UI · FE wiring for class.edit · Phase-4 (legacy admin RPCs).

**Endpoint: RULES D372 · SYSTEM_MAP v1.60 · HANDOFF V128-B11.2-A-AMENDMENT-CLOSEOUT · backend tail `20260819182957` · FE main pin `2.8.5`.** Khối v1.59/D371 (B11.1 Decision Inbox Authority Reconciliation) = HISTORICAL SNAPSHOT (BẤT BIẾN).
