# 🧭 DMA_HANDOFF — V128-B14 · CLASS.EDIT VISIBLE FE BUILD (name-only) · FE IMPLEMENTATION CLOSEOUT

> **Milestone:** V128-B14 (VISIBLE FE BUILD — Class Workspace / `class.edit` slice) — **FE implementation half**.
> **Status:** ✅ **IMPLEMENTED** — `class.edit` (name-only) wired end-to-end in the admin Mission Control class workspace through an **action-agnostic transport**. Backend presentation half remains **D378** (0 change). Documentation-only closeout: **0 repo/DB/SQL/migration/registry mutation**.
> **Date:** 2026-08-20
> **Supersedes endpoint:** V128-B14-BACKEND-PRESENTATION-CLOSEOUT (D378/v1.66) → now **D379 / v1.67**.
> **Canonical:** RULES **D379** · SYSTEM_MAP **v1.67** · backend tail **`20260820122518`** (0 change) · **FE HEAD `6a0f3504`** · FE main pin **`2.8.5`**.

---

## 0 · Boot pin (verify at next session start — hard-stop on mismatch)

| Marker | Value |
|---|---|
| RULES endpoint | **D379** |
| SYSTEM_MAP | **v1.67** |
| HANDOFF | **V128-B14-FE-IMPLEMENTATION-CLOSEOUT** (this) |
| Backend migration tail | **`20260820122518`** (0 change this milestone) |
| Decision lifecycle | **1 decision / 2 transitions** (permanent; UNCHANGED) |
| Registry rows | **4** (unchanged) |
| FE HEAD | **`6a0f35040906dfc718fafb1a7bb8947aab9f8fb5`** |
| FE main pin | **`2.8.5`** (`@lovable.dev/vite-tanstack-config`; package.json + bun.lock) |

**FE HEAD lineage:** `f4aa5798` (7-file apply + agent pin float) → **`6a0f3504`** (targeted package.json re-pin; current HEAD).
**Backend frozen anchors (re-verified post-FE, read-only):** executor `954bcc40…` · class_edit_v1 `63f3ab5a…` · resolver `56b5e3f5…` · discovery `fba330c7…`.

---

## 1 · What this milestone did

Wired the visible FE slice for the governed `class.edit` action (name-only). Before this, D378 made `class.edit` discoverable but `ClassWorkspaceScreen` hardwired the drawer submit to the assign hook, so opening "Edit Class" and submitting failed closed with `missing_program` (no wrong mutation). This closeout routes edit through its own controller with the correct payload.

End-to-end chain now live:

```
ClassWorkspaceScreen
  → ActionsBand (renders class.edit@1 from D378 discovery)
  → ActionDrawer (seeded initialValues, raw dirty-gate)
  → useClassEditAction
  → missionControlAdapter.executeAction<T>(args, parseClassEditExecuteResult)
  → execute_mission_control_action('class.edit', class_id, {school_id}, {name}, request_id)
  → class_edit_v1(class_id, {name})   [verbatim store; audit CLASS_UPDATED]
  → invalidate workspace / actions / memory
```

**Scope = FE only.** No executor/resolver/gate/registry/lifecycle/adapter/schema change.

---

## 2 · FE source delta (7 files; HEAD `6a0f3504`)

1. `class/classActions.ts` — `CLASS_EDIT_ACTION_KEY`, `buildClassEditPayload` (verbatim name send; blank-test only), `describeEditResult`.
2. `class/class-adapter.ts` — rename `parseExecuteResult` → `parseAssignExecuteResult` (body byte-identical) + new `parseClassEditExecuteResult` (`changed_fields`).
3. `adapters/missionControlAdapter.ts` — `executeAction<T>(args, parse)` action-agnostic; removed action-specific imports.
4. `class/hooks/useClassEditAction.ts` — **new**; byte-mirror of `useAssignClassAction` (request_id/lock/successNonce), passes `parseClassEditExecuteResult`.
5. `renderer/ActionDrawer.tsx` — optional `initialValues` + RAW dirty gate (`editBlocked = hasInitial && !isDirty`); **emit path unchanged (no trim)**.
6. `class/ClassWorkspaceScreen.tsx` — `edit` hook, `active` selector, **two explicit per-controller** auto-close effects, seed `{name: identity.label}`, branch-scoped reset.
7. `class/hooks/useAssignClassAction.ts` — import + pass `parseAssignExecuteResult` (approved 7th file for the agnostic transport).

Architecture: transport knows no action key/parser; domain hooks supply parsers. class.edit payload = context `{school_id}` (required + exclusive by registry gate) + input `{name}` (verbatim). class.assign behavior preserved (mechanical delta only). successNonce isolated per controller.

---

## 3 · Name semantics (matches backend contract)

`class_edit_v1` stores `p_input->>'name'` **verbatim** and rejects blank via `length(btrim(name))=0 → name_invalid` (btrim is test-only server-side). FE mirrors:
- **Blank-test** (`buildClassEditPayload`): reject `trim(name)===""` — trim used only to decide validity.
- **Dirty-test** (`ActionDrawer`): entered vs seeded, RAW/untrimmed (a whitespace change is a real change).
- **Sent-value**: raw entered string, verbatim.

---

## 4 · Implementation evidence (this session)

- **Typecheck:** `bunx tsgo --noEmit` → **exit 0**; 0 leftover `parseExecuteResult` references.
- **class.edit rolled-back rehearsal:** JWT-impersonated master `589f0390…`, class `d1000000…021` ("Hoa Hồng"), school `d1000000…001`. Exact call `execute_mission_control_action('class.edit', class_id, {school_id}, {name}, request_id)` → `ok:true` · `result.changed_fields:[name]` · `replayed:false`. Verbatim proven: input `"Hoa Hồng [REH] "` (trailing space) stored byte-identical (`verbatim_stored:true`, `trailing_space_preserved:true`); full rollback → residue zero (`Hoa Hồng` name restored).
- **Backend frozen-anchor verify:** PASS (executor/class_edit_v1/resolver/discovery md5 unchanged; registry 4; lifecycle 1/2).
- **Diff scope:** `get_diff` confirmed exactly the 7 FE files (+ reverted package.json). No `routeTree.gen.ts`, no `bun.lock` change.

---

## 5 · ⚠️ Tooling incident — DETECTED AND CONTAINED (recorded honestly)

During the authorized Lovable agent apply (commit `f4aa5798`), the agent unexpectedly changed `@lovable.dev/vite-tanstack-config` **`2.8.5 → 2.13.1`** in `package.json` — tripping the explicit tooling STOP condition. Detected **immediately via independent `get_diff`** (not the agent's self-report). Remediation: targeted `package.json`-only revert (commit `6a0f3504`).

**Final state:** `package.json` = **2.8.5** · `bun.lock` = **2.8.5** (never changed) · `routeTree.gen.ts` unchanged. Recorded as **TOOLING DRIFT DETECTED AND CONTAINED — NOT "zero drift occurred."**

---

## 6 · ⚠️ QA boundary — do not overclaim

**VERIFIED this run:** static wiring · typecheck · payload contract · idempotency pattern · assign behavioral preservation · backend execution rehearsal · zero backend residue · tooling final state · diff scope.

**PENDING OWNER VERIFICATION (not independently proven this run):** full manual browser click-through · real iPhone Safari interaction · production visual auto-close/toast behavior. No fabricated PASS.

Owner QA account: master KHM **`hieutruong.kidshouse@demo.demenart.com`** / **`Test@123`** → Mission Control → lớp "Hoa Hồng". Suggested checks: assign regression (unchanged), edit happy (name pre-filled → change → "Đã cập nhật tên lớp", auto-close), edit guards (no-change disabled, blank → "Dữ liệu không hợp lệ" no mutation), verbatim (leading/trailing space preserved), cross-inherit (edit success → open Assign clean, and vice-versa).

---

## 7 · Deploy note

FE commit sits on `main`; Cloudflare auto-deploys `main → demenart.com` (D105). No `deploy_project` was called in this closeout. Production surfaces after the Cloudflare build; owner UI QA follows.

---

## 8 · Final status

- **V128-B14 CLASS WORKSPACE VISIBLE FE BUILD — class.edit name-only**
- IMPLEMENTATION: **COMPLETE**
- BACKEND PRESENTATION: **COMPLETE** (D378)
- FE WIRING: **COMPLETE** (D379)
- AUTHORITY: **UNCHANGED** (resolver = sole WHO; UI visibility ≠ enablement ≠ authorization)
- SYSTEM-WIDE WHO CONVERGENCE: **NOT CLAIMED**
- BROWSER / iPhone QA: **PENDING OWNER VERIFICATION**

---

## 9 · Deferred / on the horizon

- age_group_id / level_id FE edit (needs `get_mission_control_workspace` current-value exposure + `get_mission_control_actions` option hydration).
- class.edit in school/teacher portals · dead `renderer/bands/*` cleanup · HIGH/decision arming for class.edit · discovery-gate WHO convergence for `get_mission_control_actions` · 6 legacy embedded-WHO RPCs.
- **NEXT:** POST-B14 owner QA → next milestone selection.

---

## 10 · Canonical integrity (this closeout)

- `DMA_RULES.md` — base (D378) + **D379** (append-only; prefix-SHA proof in `DMA_V128-B14_FE_APPEND_ONLY_INTEGRITY_REPORT.md`).
- `DMA_SYSTEM_MAP.md` — base (v1.66) + **v1.67** (append-only; prefix-SHA proof in the integrity report).

**Endpoint: RULES D379 · SYSTEM_MAP v1.67 · HANDOFF V128-B14-FE-IMPLEMENTATION-CLOSEOUT · backend tail `20260820122518` · FE HEAD `6a0f3504` · FE main pin `2.8.5`.** Khối D378/v1.66 (B14 backend presentation half) = HISTORICAL SNAPSHOT (BẤT BIẾN). Lifecycle baseline remains **1 decision / 2 transitions**. Browser/iPhone QA = **PENDING OWNER VERIFICATION**.
