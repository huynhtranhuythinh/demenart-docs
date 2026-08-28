# DMA HANDOFF — V128-B9.4 · AUTHORITY RESOLVER CONSUMPTION — IMPLEMENTATION CLOSEOUT

**Milestone:** V128-B9.4 IMPLEMENTATION — Authority Resolver Phase-1 consumption. First governed action (`class.edit`) authorized via the Authority Resolver at the executor seam. Strangler **Phase-1 complete**.
**Mode:** IMPLEMENTATION (applied). Migrations A→B→C + Mig-A reconcile + Mig-B fix. Verified by JWT-impersonated rehearsals (rolled back, zero production residue).
**Date:** 2026-08-16
**Status:** ✅ **LIVE + VERIFIED.** Canonical appended (RULES D368 · SYSTEM_MAP v1.56).

---

## Boot verification (STEP 0)

| Check | Required at start | Live | Status |
|---|---|---|---|
| `DMA_RULES.md` | D367 | D367 (B9.3 block) | ✅ |
| `DMA_SYSTEM_MAP.md` | v1.55 | v1.55 | ✅ |
| Design authority | `DMA_V128-B9.4-PHASE-C-DESIGN-FREEZE` (A+B+C, D1=A) | present, byte-identical round-trip (md5 `56ab8549…`) | ✅ |
| Backend tail at start | `20260815201925` | matched | ✅ |
| FE | `2.8.5` | matched | ✅ |

Re-pinned live before EACH migration (D1). Drift caught at Mig-A (see below) and reconciled.

---

## What was applied (5 migrations)

| tail | migration | scope |
|---|---|---|
| `20260816083423` | `v128_b94_mig_a_authority_gated_column` | **external** (outside session) — added `authority_gated`, **nullable** (deviated from freeze `NOT NULL`) |
| `20260816090017` | `v128_b94_mig_a_reconcile_authority_gated_notnull` | reconcile → `SET NOT NULL` (0 nulls; D92 verify) |
| `20260816090950` | `v128_b94_mig_b_authority_gate_class_edit` | NEW `_mc_authority_gate` + NEW `class_edit_v1` + MODIFY `_mc_lookup_action` (surface flag) + MODIFY executor (G1) |
| `20260816094033` | `v128_b94_mig_c_enable_class_edit` | activate class.edit (adapter/context/input_schema/`authority_gated=true`) |
| `20260816094225` | `v128_b94_mig_b_fix_class_edit_array_append` | **bug-fix**: `class_edit_v1` `||`→`array_append` (22P02) |

Each migration: D92 pattern (DDL → REVOKE/GRANT D15/D231 → VERIFY RAISE-guard → NOTIFY pgrst), atomic.

---

## Verification evidence (all rehearsals JWT-impersonated, RAISE-rolled-back, 0 residue)

- **Gate resolver-tier 7/7 PASS** — `_mc_authority_gate('class.edit', …)`: platform→`platform_role/authority_granted` · master same-school→`organization_role/authority_granted` · master cross-school→`organization_scope_mismatch` · teacher/parent→`role_not_eligible` · missing school→`object_context_mismatch` · unknown→`actor_unresolved`.
- **class.edit happy** (master KHM, class 021) — `ok=true` · name mutated (`Hoa Hồng`→`Hoa Hồng [REHEARSAL]`) · audit `CLASS_UPDATED` · `changed_fields=[name]`.
- **class.edit deny** (lead_teacher gv.linh) — `MC_ACTION_PERMISSION_DENIED` · `reason_codes=[role_not_eligible]` · `authority_source=none` · **0 mutation · 0 ledger (12→12)** (gate denies before `_mc_begin_action`).
- **class.assign regression** (master, real assign on QA Partial class + Ballet) — `ok=true` · distribution created + audit · rolled back → executor rewrite **did not break** the live MEDIUM path.
- **Final residue audit** — class 021 unchanged · action_requests 12 · `CLASS_UPDATED` persisted 0 · class_distributions 21 · lifecycle 0/0.

---

## Honest records (surfaced, not hidden)

1. **D367.4 legacy-isolation SUPERSEDED** — executor md5 `09ef5f48f3318bfb53e126f3bc81d40a` → `da733e9a636e9efd4457123e923057dd`. Intentional Phase-1 consumption; "executor unchanged" no longer holds. Transition controller `fe0eea59…` still unchanged.
2. **Mig-A drift** — `authority_gated` first landed via an external migration (nullable); reconciled to `NOT NULL`. Retroactive reconciliation, no rogue assertion (D367.7).
3. **Bug caught + fixed** — `class_edit_v1` v1 `||` array-append defect (22P02), detected by rehearsal **before any production use**, fixed via `array_append`. Rehearsal-before-declare discipline validated.

---

## Live state (post-milestone)

Backend tail **`20260816094225`**. Public: tables **94** · fns **253** · secdef **241** · policies **169** · triggers **34** · cron **1**; `mc_internal` {**9** fn / **8** secdef} + **1** table (`authority_probe_log`). Registry `+1 col` `authority_gated`. **class.edit LOW active GATED** (adapter `class.edit.v1`) · **class.assign MEDIUM active ungated** (behavior preserved) · authority.probe LOW active ungated. Resolver caller-set `{execute_authority_probe, _mc_authority_gate}`; `_resolve_authority` body+ACL unchanged. Decision lifecycle dormant (0/0). FE main pin `2.8.5`.

---

## Deferred (NOT authorized by B9.4 — each needs explicit CTO authorization)

- **FE wiring for class.edit** (executor is live; no UI consumes it yet).
- Strangler **Phase-2** (decision paths open/inbox/resolve/cancel consume resolver).
- Strangler **Phase-3** (legacy adapter authority migration, incl. `assign_class_distribution` self-authorization → resolver).
- Strangler **Phase-4** (legacy admin RPCs).
- `authority_source`/`reason_code` pg-enum mint · `UNIQUE(user_id)` enforcement · delegation · object-scope expansion (`child.transfer`, session/school) · multi-approver/quorum · notification · inbox UI · HIGH/CRITICAL activation.

---

## Next milestone

Owner's choice — candidates: **FE wiring for class.edit** (surface the governed edit in `/school` or `/admin`), or **Strangler Phase-2** (decision-path consumption), or a **second governed action** to broaden gate exercise (toward vocabulary mint). Standing discipline: hard STOP at authorized scope; await explicit authorization before any new SQL/migration/FE.

---

## Boot pointer (next session)

Read canonical directly (never memory): `DMA_RULES.md` (→ **D368**) · `DMA_SYSTEM_MAP.md` (→ **v1.56**) · this handoff · `DMA_V128-B9.4-PHASE-C-DESIGN-FREEZE`. Endpoint to re-pin: RULES **D368** · SYSTEM_MAP **v1.56** · HANDOFF **V128-B9.4-IMPLEMENTATION-CLOSEOUT** · backend tail **`20260816094225`** · FE main pin `2.8.5`. Authority Resolver = **consumed in production (Phase-1)** by class.edit. Executor md5 = `da733e9a…` (changed by design). Block D367/v1.55 (B9.3 skeleton reconcile) = HISTORICAL SNAPSHOT (BẤT BIẾN).
