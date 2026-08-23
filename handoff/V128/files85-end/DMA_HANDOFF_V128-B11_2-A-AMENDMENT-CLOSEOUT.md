# 🧭 DMA_HANDOFF — V128-B11.2-A-AMENDMENT · GATE α · IMPLEMENTATION CLOSEOUT

> **Milestone:** V128-B11.2-A-AMENDMENT (Gate α — executor resume-path `class.edit` support)
> **Status:** ✅ **GATE α VERIFIED & CLOSED** — additive executor amendment applied, INERT, zero residue.
> **Date:** 2026-08-19
> **Supersedes endpoint:** V128-B11.1-IMPLEMENTATION-CLOSEOUT (D371/v1.59) → now D372/v1.60.
> **Canonical:** RULES **D372** · SYSTEM_MAP **v1.60** · backend tail **`20260819182957`** · FE main pin **`2.8.5`**.

---

## 0 · Boot pin (verify at next session start — hard-stop on mismatch)

| Marker | Value |
|---|---|
| RULES endpoint | **D372** |
| SYSTEM_MAP | **v1.60** |
| HANDOFF | **V128-B11.2-A-AMENDMENT-CLOSEOUT** (this) |
| Backend migration tail | **`20260819182957`** (`v128_b112a_amend_executor_resume_class_edit`) |
| Decision lifecycle | **DORMANT — decisions 0 / transitions 0** (one-way door NOT opened) |
| Registry `class.edit` | **LOW · active · authority_gated=true** (NOT elevated) |
| FE main pin | `2.8.5` (`@lovable.dev/vite-tanstack-config`) |

**Executor md5 (current):** `2228611a65c3678d092b1c15ecc19c68`
**Frozen anchors (must match):** resolver `56b5e3f5…` · transition `fe0eea59…` · open_decision `b376edd7…` · authority_gate `bc5ea1a2…` · class_edit_v1 `63f3ab5a…` · resolve `bb79a521…` · cancel `924c3f9a…` · inbox `af21682d…` · expire `c57c40b8…` · assign_class_distribution `03a1510b…`

---

## 1 · What this milestone did (one paragraph)

Fixed the **G1 blocker** from B11.2-A: the executor's *resume-approved* adapter dispatch handled only `class.assign.v1`, so a `class.edit.v1` decision could open + approve but **could not resume into mutation** (`adapter_unresolved` → `MC_ACTION_EXECUTION_FAILED`, 0 mutation). Applied a **scoped additive amendment (Option 1)** to `public.execute_mission_control_action` **only**: relocated `v_result` into each resume `case` arm, added a `class.edit.v1` arm (calls `public.class_edit_v1`, audit `CLASS_UPDATED`), and added four `class.edit` domain error mappings — mirroring the fresh path. The fix is **INERT**: `class.edit` stays `LOW`, so the new arm is unreachable in production; lifecycle stays **0/0**; the permanent one-way door is **not** opened. Activation + first committed proof are **Gate β** (deferred, separate re-gate).

---

## 2 · Migration applied

- **Name:** `v128_b112a_amend_executor_resume_class_edit`
- **Tail:** `20260819092150` → **`20260819182957`**
- **Shape:** D92 3-block atomic — (1) DDL `CREATE OR REPLACE execute_mission_control_action` (body-only; resume-approved block changed); (2) REVOKE ALL FROM PUBLIC/anon/authenticated/service_role → GRANT EXECUTE authenticated (D15/D231 ACL restore); (3) `DO $verify$` fail-closed guard — INVOKER assert · 0 anon/service_role/PUBLIC leak · authenticated EXECUTE present · resume `class.edit.v1` arm present (≥2 occurrences) — + `NOTIFY pgrst`.
- **Result:** success; VERIFY guard passed.
- **Executor md5:** `da733e9a636e9efd4457123e923057dd` → **`2228611a65c3678d092b1c15ecc19c68`** (INVOKER preserved `prosecdef=false`; ACL `{authenticated=EXECUTE, postgres=EXECUTE}` exact-restored).

---

## 3 · Verification matrix (all rehearsals JWT-impersonated, sentinel-RAISE rolled back, zero residue)

Fixture (rolled back): requester = platform `super_admin` (`profiles.id e86e45d1…`, user `446de75d…`) · approver = demo-school master (`profiles.id 2fee5a07…`, user `5396961a…`, school `b6a4ac35…`). Rehearsal class = `eeeeeeee-0000-4000-8000-000000000005` (B6.2 QA Test Class). JWT pattern: `set_config('request.jwt.claims', json_build_object('sub',<auth.users.id>,'role','authenticated')::text, true)` + `SET LOCAL ROLE authenticated` + `RESET ROLE` (sub = `profiles.user_id`).

| Test | Result | Evidence |
|---|---|---|
| **A** class.assign regression | ✅ PASS | A1 existing-pair → `MC_ACTION_CONFLICT` (NOT `adapter_unresolved`/`EXECUTION_FAILED`); A2 free-pair fresh (INSERT-only) → `ok:true` · `audit=CLASS_ASSIGNMENT_CREATED` · `result={class_distribution_id}` |
| **B** class.edit@HIGH resume proof | ✅ PASS | open→`MC_ACTION_DECISION_REQUIRED` (pending, name unchanged) → approve (demo master, `approved`) → **resume `ok:true · replayed:true · audit=CLASS_UPDATED · result={changed_fields:[name]}` · name changed**; decisions=1, transitions=2 `[NULL→pending, pending→approved]` |
| **C** replay semantics | ✅ PASS | 3rd call same request_id → `ok:false` + name stable → 0 duplicate decision / 0 duplicate transition / 0 net duplicate mutation |
| **D** adapter failure routing | ✅ PASS | resume empty `{}` → `class_edit_v1` raises `no_editable_fields` → `MC_ACTION_INPUT_INVALID`; name unchanged (subtxn rollback); decision still `approved` (retryable); transitions=2 (no dup); ledger `processing` (retryable intermediate, not corrupt) |
| **E** hash + inert | ✅ PASS | executor `2228611a…`; 6+ frozen anchors unchanged; class.edit LOW; lifecycle 0/0 |

**Post-run zero-residue (live):** decisions/transitions **0/0** · class.edit **LOW** · QA class name original · `mission_control_action_requests` **12** unchanged.

**Honest boundary:** verified through rolled-back rehearsal + runtime hash/ACL only. **No committed decision exists; no HIGH/CRITICAL activated; no "proven on committed data" claim.** Resume arm proven mechanically, runtime-unreachable until Gate β.

---

## 4 · ⭐ Gate β flags (carry forward — pre-existing B7 properties, NOT regressions; disposition before first committed decision)

1. **Approved-resume idempotency review.** Approved-HIGH replay **re-dispatches the adapter** (does not return stored `result_payload`). `class.assign` is protected by `assign_class_distribution` uniqueness; **`class_edit_v1` has no uniqueness guard** → a same-request_id replay re-invokes the edit with the live `p_input` (commit-guard + subtxn rolled it back in rehearsal). **Harden:** approved-HIGH replay returns stored payload, or `class_edit_v1` gains idempotency/version guard.
2. **`intent_fingerprint` payload-binding review.** Fingerprint = hash(`action`,`object`,`school`[,`program`,`lead`]) — **excludes edited field values**. Approved `class.edit` decision authorizes the *intent to edit class X*, not specific values; resume executes live `p_input`. **Harden:** bind field values into fingerprint, or snapshot `p_input` at decision-open and execute the snapshot.

---

## 5 · Rollback (fully reversible; NOT performed)

`CREATE OR REPLACE execute_mission_control_action` back to md5 `da733e9a636e9efd4457123e923057dd` + re-assert ACL (REVOKE ALL FROM PUBLIC/anon/authenticated/service_role → GRANT EXECUTE authenticated; owner postgres) + `NOTIFY pgrst`. **0 data-repair** (lifecycle 0/0; no schema/registry/data change). Reverting re-introduces the G1 gap — acceptable while `class.edit` stays LOW.

---

## 6 · Next — GATE β (NOT authorized; requires explicit CTO re-gate)

Gate β = the one-way door. Scope when authorized:
1. Seed **dedicated synthetic fixture** (G4) — a tenant with a valid requester + eligible approver; pilots `d1000000-…-001` / `d2000000-…-001` **off-limits**.
2. Disposition the **two D372.8 flags** (idempotency + fingerprint binding) — decide harden-now vs accept-with-record.
3. Registry `class.edit` risk **LOW → HIGH** activation (1 UPDATE).
4. **First COMMITTED decision** (open → approve → resume → mutation on committed data) — this **permanently opens the one-way door 0/0 → 1/2** (immutable by design).
5. Data rollback + **disarm** (risk HIGH → LOW) + Gate β canonical closeout (next D-rule / SYSTEM_MAP bump).

**Deferred beyond Gate β:** `child.transfer` / object-scope expansion · Strangler Phase-3 (`assign_class_distribution` / class.assign executor embedded authority) · multi-approver/quorum · enum/taxonomy mint · `UNIQUE(user_id)` · delegation · notification · inbox UI · FE wiring for `class.edit` · Phase-4 (legacy admin RPCs).

---

## 7 · Canonical sync checklist (this session — FULL files assembled, append-only proven)

- [x] `DMA_RULES.md` — FULL file: base (endpoint D371) + appended **D372** block. Prefix-SHA append-only proof PASS; base sha256 `0a0eb0dd…` == final[0:1066021]. Final sha256 `7e54fc4f…`.
- [x] `DMA_SYSTEM_MAP.md` — FULL file: base (endpoint v1.59) + appended **v1.60** block. Prefix-SHA append-only proof PASS; base sha256 `2848d8dd…` == final[0:590827]. Final sha256 `37bbfa0c…`.
- [x] `DMA_HANDOFF_V128-B11_2-A-AMENDMENT-CLOSEOUT.md` (this file; filename normalized to project convention, in-doc identifier retains `V128-B11.2-A-AMENDMENT-CLOSEOUT`).
- [x] `DMA_V128-B11.2-A-AMENDMENT_APPEND_ONLY_INTEGRITY_REPORT.md` (integrity proof).

*Assembly was byte-safe append-only: historical content through D371 / v1.59 is byte-identical to base (prefix-SHA verified); no history rewrite, no renumbering. Files NOT uploaded to Project Knowledge.*
