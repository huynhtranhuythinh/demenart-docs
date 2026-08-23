# 🧭 DMA_HANDOFF — V128-B14 · CLASS.EDIT FE-FACING DISCOVERY PRESENTATION (name-only) · BACKEND CLOSEOUT

> **Milestone:** V128-B14 (VISIBLE FE BUILD — Class Workspace / `class.edit` slice) — **BACKEND presentation half**.
> **Status:** ✅ **PASS** — `get_mission_control_actions` now projects `class.edit` (name-only) into the FE-facing discovery envelope, alongside the byte-preserved `class.assign` item. **Presentation-only**; executor / resolver / authority-gate / registry / decision-lifecycle / `class_edit_v1` / audit contract all **FROZEN** (md5 VERIFY-asserted).
> **Date:** 2026-08-20
> **Supersedes endpoint:** V128-B13.2-IMPLEMENTATION-CLOSEOUT (D377/v1.65) → now **D378 / v1.66**.
> **Canonical:** RULES **D378** · SYSTEM_MAP **v1.66** · backend tail **`20260820122518`** · FE main pin **`2.8.5`**.

---

## 0 · Boot pin (verify at next session start — hard-stop on mismatch)

| Marker | Value |
|---|---|
| RULES endpoint | **D378** |
| SYSTEM_MAP | **v1.66** |
| HANDOFF | **V128-B14-BACKEND-PRESENTATION-CLOSEOUT** (this) |
| Backend migration tail | **`20260820122518`** (`v128_b14_project_class_edit_presentation`) |
| Decision lifecycle | **1 decision / 2 transitions** (permanent; UNCHANGED) |
| Registry rows | **4** (unchanged) |
| FE main pin | `2.8.5` (0 change — FE slice NOT yet built) |

**Changed anchor:** `get_mission_control_actions` `3596633c6f7f1b7ecdc81822691475d4` → **`fba330c7a2d6d36171086d9761a0bf23`**
**Frozen anchors (VERIFY-asserted UNCHANGED):** executor `954bcc40…` · gate `bc5ea1a2…` · resolver `56b5e3f5…` · class_edit_v1 `63f3ab5a…` · lookup `eb22ad49…` · begin `54b5af57…` · commit `ce36c5fe…` · get_available_actions `fd874243…` · get_mission_control_workspace `87244baf…`.

---

## 1 · What this milestone did

The FE-facing discovery RPC `public.get_mission_control_actions(text,uuid)` was hardcoded to project **only** `class.assign` (single-item `v_items`; early-return `items:[]` when assign not discoverable). It **dropped `class.edit` entirely** despite `get_available_actions` exposing it (D376) and the executor/adapter contract being live since B9.4. This blocked any FE surfacing of `class.edit`.

The patch **decouples the per-action gate**: the `class.assign` item is now built inside `if exists(assign)` (byte-identical body, index 0 preserved) and a **new `if exists(class.edit)`** block appends a **name-only** `class.edit` item. Result envelope for an authorized master on a class with a free program: `items:[class.assign@0, class.edit@1]`.

**Scope = presentation only.** No executor, resolver, gate, registry, lifecycle, adapter, audit, or schema change.

---

## 2 · Migration
- **Name:** `v128_b14_project_class_edit_presentation` · **tail:** `20260820092306` → **`20260820122518`**
- **Shape (D92 3-block):** DDL `CREATE OR REPLACE get_mission_control_actions` (decoupled assign/edit projection) → REVOKE ALL FROM PUBLIC/anon/authenticated/service_role + GRANT EXECUTE **authenticated** (preserve exact ACL `{authenticated, postgres}` — FE-facing, **no service_role**) → `DO $verify$` fail-closed guard (projection present + 9 frozen-anchor md5 asserts + registry class.edit invariants + ACL exact-set) → `NOTIFY pgrst`.
- **Rehearsed rolled-back before apply** (sentinel-RAISE, zero residue): OLD vs NEW captured under the same impersonated master; `assign_preserved=true` (jsonb equality of item[0]); edit item shape asserted; DDL rolled back; post-rehearsal md5 == `3596633c…` (residue zero).

---

## 3 · class.edit projected item (name-only)
```
{ "key":"class.edit", "label":"Edit Class", "description":"Cập nhật thông tin lớp",
  "risk_level":"LOW",
  "input_schema":{ "version":"MissionActionInputSchema/v1",
    "fields":[ {"key":"name","label":"Tên lớp","value_type":"text","control":"text","required":false} ] } }
```
`risk_level` + `input_schema.version` sourced from registry via `_mc_lookup_action` (authority-structure single-source). Field presentation (label/control/value_type) synthesized in the projection because the registry `input_schema` for class.edit is a **skeleton** (`{key,required}` only).

---

## 4 · Live functional proof (committed, JWT-impersonated master @ b6a4ac35, read-only)
`get_mission_control_actions('class','2405fed8-…')` → `ok:true` · keys `[class.assign, class.edit]` · edit present · label `Edit Class` · version `MissionActionInputSchema/v1` · fields `[name/text]`. **0 mutation** (read-only DO block).

---

## 5 · Frozen / unchanged (post-apply verified)
- md5 UNCHANGED: executor `954bcc40…` · gate `bc5ea1a2…` · resolver `56b5e3f5…` · class_edit_v1 `63f3ab5a…` · get_available_actions `fd874243…` · get_mission_control_workspace `87244baf…` · begin/commit/lookup.
- Decision lifecycle **1/2** (B11.2-B2 one-way-door evidence intact).
- Registry **4 rows** unchanged (class.edit still LOW · active · gated · `class.edit.v1`).
- ACL `get_mission_control_actions` = `{authenticated, postgres}` (preserved; no anon/service_role leak).
- Inventory: no schema change (function-body + ACL only).

---

## 6 · Honest boundaries & deferred (NOT authorized here)
- **age_group_id / level_id edit = DEFERRED (contract gap).** Registry input_schema carries all three, but (a) `get_mission_control_workspace` does **not** expose current `age_group_id`/`level_id` (only `name` via `object.label` and derived program names), and (b) no option source (`age_groups`/`levels`) is hydrated in the projection. Full 3-field edit requires extending BOTH `get_mission_control_actions` (option hydration) and `get_mission_control_workspace` (current-value exposure). Name-only avoids this entirely.
- **FE slice NOT built (B14-FE pending).** `class.edit` is now **discoverable**, but `ClassWorkspaceScreen` still hardwires the drawer submit to the assign hook. ⚠️ **Interim exposure:** in the admin-only Mission Control class workspace, an **"Edit Class" button now renders in production**; opening it shows a name field, and submit currently routes to `buildAssignClassPayload` → fails closed with `missing_program` ("Dữ liệu không hợp lệ") — **no wrong mutation**, but a broken affordance until FE #1–#6 land. Recommend FE wiring as the immediate next authorized step.
- Discovery-gate WHO of `get_mission_control_actions` remains **embedded** (`is_admin`/`current_profile_role`/`user_school_ids`) — visibility gate only; execution authority stays resolver-sourced. Not touched here.

---

## 7 · Rollback (recorded; NOT performed)
`CREATE OR REPLACE public.get_mission_control_actions` back to md5 `3596633c6f7f1b7ecdc81822691475d4` + `REVOKE ALL FROM PUBLIC,anon,authenticated,service_role` + `GRANT EXECUTE TO authenticated` + `NOTIFY pgrst`. **0 data-repair** (presentation-only; ledger/decision/registry/audit untouched). class.edit disappears from discovery; assign unaffected.

---

## 8 · NEXT (frozen APPLY order — FE half)
Per the B14 frozen plan: **FE #1–#6** (paste-mode default) → QA (assign regression + class.edit QA-1..13) → consolidated B14 FE closeout.
1. `class/classActions.ts` — CLASS_EDIT key + dirty-aware `buildClassEditPayload` + `describeEditResult`.
2. `class/class-adapter.ts` — `parseClassEditExecuteResult` (changed_fields; no class_distribution_id); rename `parseExecuteResult→parseAssignExecuteResult`.
3. `adapters/missionControlAdapter.ts` — generic `executeAction<T>(args, parse)` (transport action-agnostic).
4. `class/hooks/useClassEditAction.ts` — new (mirror assign: request_id/lock/invalidate; dirty submit).
5. `renderer/ActionDrawer.tsx` — optional `initialValues` + dirty (disable when 0 changed).
6. `class/ClassWorkspaceScreen.tsx` — dispatch drawer by `openActionKey`; seed `initialValues={name:identity.label}`.

---

## 9 · Canonical integrity (this closeout)
- `DMA_RULES.md` — base (D377) + **D378** (append-only; prefix-SHA proof in the append run).
- `DMA_SYSTEM_MAP.md` — base (v1.65) + **v1.66** (append-only; prefix-SHA proof in the append run).

**Endpoint: RULES D378 · SYSTEM_MAP v1.66 · HANDOFF V128-B14-BACKEND-PRESENTATION-CLOSEOUT · backend tail `20260820122518` · FE main pin `2.8.5`.** Khối D377/v1.65 (B13.2) = HISTORICAL SNAPSHOT (BẤT BIẾN). Lifecycle baseline remains **1 decision / 2 transitions**.
