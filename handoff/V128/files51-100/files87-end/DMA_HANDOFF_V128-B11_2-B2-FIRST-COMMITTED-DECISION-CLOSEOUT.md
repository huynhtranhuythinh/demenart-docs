# 🧭 DMA_HANDOFF — V128-B11.2-B2 · FIRST COMMITTED GOVERNED DECISION · CLOSEOUT

> **Milestone:** V128-B11.2-B2 (Gate β activation — first committed governed decision)
> **Status:** ✅ **PASS** — one-way door **OPENED**; lifecycle **1 decision / 2 transitions** (PERMANENT). Gate β **PROOF COMPLETE**.
> **Date:** 2026-08-20
> **Supersedes endpoint:** V128-B11.2-B1-IMPLEMENTATION-CLOSEOUT (D373/v1.61) → now **D374 / v1.62**.
> **Canonical:** RULES **D374** · SYSTEM_MAP **v1.62** · backend tail **`20260820021437`** (UNCHANGED) · FE main pin **`2.8.5`**.

---

## 0 · Boot pin (verify at next session start — hard-stop on mismatch)

| Marker | Value |
|---|---|
| RULES endpoint | **D374** |
| SYSTEM_MAP | **v1.62** |
| HANDOFF | **V128-B11.2-B2-FIRST-COMMITTED-DECISION-CLOSEOUT** (this) |
| Backend migration tail | **`20260820021437`** (UNCHANGED — B2 was 0 migration) |
| Decision lifecycle | **ACTIVE — decisions 1 / transitions 2** (one-way door OPENED — **never 0/0 again**) |
| Registry `class.edit` | **LOW · active · authority_gated=true** (armed HIGH for proof, disarmed to LOW) |
| FE main pin | `2.8.5` |

**Frozen anchors (must match — all UNCHANGED in B2):** begin `54b5af57…` · executor `954bcc40…` · commit `ce36c5fe…` · open_decision `b376edd7…` · transition `fe0eea59…` · resolver `56b5e3f5…` · gate `bc5ea1a2…` · class_edit_v1 `63f3ab5a…` · resolve `bb79a521…` · inbox `af21682d…` · assign_class_distribution `03a1510b…`

---

## 1 · What this milestone did

Activated **Gate β** and executed the **first committed governed decision** end-to-end on committed data. Synthetic requester **R** opened a `class.edit@HIGH` decision; distinct synthetic approver **P** approved it through the resolver-backed RPC; R resumed with the exact approved payload, mutating the synthetic class and terminalizing the ledger. The governed lifecycle moved permanently from **0/0 → 1/2**. `class.edit` was reversibly armed LOW→HIGH and disarmed HIGH→LOW. **Zero function-body / schema / migration change** (tail unchanged). Both D372.8 flags now carry committed proof. Executed via controlled DML (`execute_sql`); the two Auth identities were **Owner-created via Supabase Auth Admin** (no raw `auth.users` SQL).

---

## 2 · Committed evidence (immutable — DO NOT delete/reset)

- **Decision** `5d3b8897-ab2b-45ab-ac44-359e335d8ea3` — state `approved` · requested_by R `b112b2b2-0ac7-4000-8000-000000000001` · decided_by P `b112b2b2-0ac7-4000-8000-000000000002` · object C `b112b2b2-c1a5-4000-8000-000000000001` (class) · risk `HIGH` · intent_fingerprint `28d71f14af533edc039ba09a3f8010932ca9806d2cc556e343833d28123ae0d1` · opened `06:04:16.540336Z` · decided `06:05:26.53498Z`.
- **Transitions (append-only):** `5d6e1297-2a47-40f7-8acb-30aec7cdc495` (NULL→pending / R / 06:04:16) · `ee4ac2cd-5044-4b8e-bdab-672fc29ce92d` (pending→approved / P / 06:05:26).
- **Proof action_request** `b112b2b2-9e00-4000-8000-0000000000f1` — status `completed` (06:06:08) · result `{ok:true, CLASS_UPDATED, changed_fields:[name], replayed:true}`.
- **Audit** `0a9f3528-dcd8-4da2-8ffe-2dcec2ca594b` — `CLASS_UPDATED` · actor R · entity_id C · entity_type class · metadata `{kind:edit, changed_fields:[name]}`. (Total CLASS_UPDATED across all classes = 1.)

---

## 3 · Proof sequence (as committed)

| Phase | Action | Result | Lifecycle |
|---|---|---|---|
| D1 | R open `class.edit@HIGH`, payload A | `MC_ACTION_DECISION_REQUIRED`; class BEFORE; ledger processing | 0/0 → **1/1** |
| D2 | R self-approve | `self_decision_forbidden`; no change | 1/1 |
| D3 | P approve (resolver-backed RPC) | `approved`; class BEFORE | 1/1 → **1/2** |
| D4 | R resume, drifted payload | `MC_ACTION_REQUEST_CONFLICT`; 0 mutation | 1/2 |
| D5 | R resume, EXACT payload A | `ok:true`, CLASS_UPDATED; class **AFTER**; ledger completed | 1/2 |
| D6 | R replay same reqid+payload | `ok:false / MC_ACTION_EXECUTION_FAILED` (subtxn rollback); no dup | 1/2 |

D4 = committed proof of **Flag 2** (approved WHAT = executed WHAT). D6 = committed proof of **Flag 1** (at-most-once effective mutation).

---

## 4 · Permanent synthetic fixture (KEEP ALL — provenance chain)

| Sym | ID | Note |
|---|---|---|
| Ru | `b92bfb6d-2745-4cae-84c5-8a05bc9f81c5` | auth.users (Owner-created via Auth Admin) |
| Pu | `5029da7b-ef4d-47dc-b69f-648aae12c9c2` | auth.users (Owner-created via Auth Admin) |
| S | `b112b2b2-5c00-4000-8000-000000000001` | synthetic school |
| R | `b112b2b2-0ac7-4000-8000-000000000001` | master_admin @ S → Ru (requester; FK-bound via action_requests.actor_id) |
| P | `b112b2b2-0ac7-4000-8000-000000000002` | master_admin @ S → Pu (approver) |
| C | `b112b2b2-c1a5-4000-8000-000000000001` | class, **AFTER** = `MC-B11.2-B2-FIXTURE-PROOF` (bound via audit_logs.entity_id) |

Data disposition = **Option A** (leave C in AFTER). Do NOT delete/reset/revert.

---

## 5 · Corrected canonical fact (forward clarification, no historical rewrite)

**`public.profiles.user_id` → `auth.users(id)` ON DELETE SET NULL** (authoritative `pg_constraint`). The B2 design-gate exploration wrongly concluded no FK because `information_schema.constraint_column_usage` privilege-omits cross-schema constraints. **Use `pg_constraint`/`pg_get_constraintdef` for cross-schema FK detection.** Consequence: synthetic profiles need real `auth.users` ids; raw `auth.users` SQL was forbidden; Auth Admin `createUser` was unavailable in the Builder toolchain; Owner created Ru/Pu via Dashboard; Builder verified UUID↔email + no prior link before seeding. No raw `auth.users` write in B2.

---

## 6 · Isolation / no-pilot

Only the synthetic fixture was touched. Footprint: +1 action_request (12→13) · +1 decision · +2 transitions · +1 CLASS_UPDATED · fixture retained. `class.edit` action_requests = 1; all decisions object = C; total CLASS_UPDATED (all classes) = 1.

---

## 7 · Gate β status & next

**Gate β = PROOF COMPLETE.** The governed decision lifecycle is ACTIVE and proven on committed data. **New permanent baseline = 1 decision / 2 transitions** — future audits must NOT expect 0/0.

**Deferred (each needs explicit CTO authorization):** child.transfer / object-scope · Strangler Phase-3 (`assign_class_distribution`) · reject/expire/cancel committed proof · multi-approver/quorum · enum mint · `UNIQUE(user_id)` · delegation · notification · decision inbox UI · FE wiring for class.edit · Phase-4 (legacy admin RPCs).

**NEXT:** POST-CANONICAL RETRIEVAL VERIFY (separate run) — re-read the uploaded canonical files and confirm D374/v1.62 endpoints + append-only prefix proofs.

---

## 8 · Canonical integrity (this closeout)

- `DMA_RULES.md` — base (D373) + **D374**. Prefix-SHA proof PASS (`c5c92948…` == final[0:1088710]); final `0bc3faa5fa15aad39a21a308964bdcdbc4932b8bfe64120639a7c5947074f43d`.
- `DMA_SYSTEM_MAP.md` — base (v1.61) + **v1.62**. Prefix-SHA proof PASS (`75ef1c4f…` == final[0:601263]); final `a5210f8bff72e45e2a6ffca860ff382b2aa1d0f9d379ba1f70a8222b1a0e73cf`.

See `DMA_V128-B11.2-B2_APPEND_ONLY_INTEGRITY_REPORT.md` for full proof.
