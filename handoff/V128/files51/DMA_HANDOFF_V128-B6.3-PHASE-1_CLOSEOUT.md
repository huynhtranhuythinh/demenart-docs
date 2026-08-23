# 🗂️ DMA_HANDOFF_V128-B6.3-PHASE-1_CLOSEOUT.md — ACTION CONTROL PLANE · REGISTRY AUTHORITY FOUNDATION

> **Ngày:** 2026-08-15 (GMT+7) · **Loại:** Phase 1 apply + canonical closeout (1 migration, additive; 0 execute/FE/ledger change).
> **Boot phiên sau:** file này → `DMA_RULES.md` (tip **D361**) → `DMA_SYSTEM_MAP.md` (**v1.49**) → audit live DB (D1) → re-pin.
> **Endpoint:** RULES **D361** · SYSTEM_MAP **v1.49** · HANDOFF **V128-B6.3-PHASE-1** · backend migration tail **`20260815080313`** (`v128_b6_3_p1_registry_authority_foundation`) · FE main pin `2.8.5`.

---

## 1. STATUS

**PHASE 1 CLOSED.** V128-B6.3 overall: **NOT CLOSED.**

Phase 1 (Registry Authority Foundation) applied + verified live (A1–A12 PASS, zero drift). Đóng G1 ở tầng dispatchability authority + discovery internal truth. Execute cutover (G2), intent integrity (G3) = phases sau.

---

## 2. OBJECTIVE

Chuyển `mission_control_action_registry` từ descriptor catalog → **dispatchability authority foundation**, KHÔNG cutover execute, KHÔNG chạm FE. Option A conservative (CTO-locked).

---

## 3. LIVE STATE

- **migration:** `20260815080313` (`v128_b6_3_p1_registry_authority_foundation`) — atomic D92 3-block, VERIFY fail-closed PASS.
- **public inventory:** `92 · 248 · 236 · 168 · 33 · 1` (BẤT BIẾN).
- **mc_internal:** **2 fn / 2 secdef** (`_mc_commit_action` + `_mc_lookup_action`).
- **registry:** class.assign (active, class.assign.v1, 'Assign Teacher') · class.edit (disabled, NULL, disabled_reason set).

---

## 4. DELIVERED

- **+5 registry authority fields** (additive nullable): `adapter_key · execution_mode · required_context · input_schema · disabled_reason`.
- **class.assign authority binding:** adapter_key `class.assign.v1` · execution_mode `single_domain_rpc` · required_context `{"keys":["school_id"],"exclusive":true}` · input_schema `MissionActionInputSchema/v1` skeleton (options_source=dynamic; no runtime options in registry). Label `'Assign Teacher'` giữ nguyên.
- **class.edit disabled:** status `disabled` · adapter_key NULL · disabled_reason `'No executor bound; class.edit executor out of B6.3 scope'`. No executor created.
- **`mc_internal._mc_lookup_action(text,text)`:** DEFINER · owner postgres · `search_path=''` · STABLE · ACL `{authenticated,postgres}`; 3-way verdict (dispatchable / present-not-dispatchable / absent); **A9 bounded 8-field projection**; no authz / no `auth.uid`.
- **`get_available_actions` → dispatchable-only predicate** (`status='active' AND adapter_key IS NOT NULL`); ACL `{postgres,service_role}` preserved; signature/envelope unchanged.

---

## 5. FROZEN / UNCHANGED (md5 proven post-apply)

| Object | md5 | Note |
|---|---|---|
| `public.execute_mission_control_action` | `771470473d17c31a247999a51e499094` | INVOKER, literal-dispatch — untouched |
| `mc_internal._mc_commit_action` | `ce36c5fe109e99a919158a4482940c6a` | DEFINER completed-only — untouched |
| `public.assign_class_distribution` | `03a1510bd827c03a650a3a88312fbe3a` | domain adapter — untouched |
| `public.get_mission_control_actions` | `e4fdd0138e27f40eb9c76aa4f4b6ab65` | FE-facing hardcoded projection — untouched |

- **Ledger** `mission_control_action_requests`: schema/constraints/indexes/RLS/policies/grants UNCHANGED; **no `intent_fingerprint`**; authenticated terminal UPDATE = 0.
- **FE:** 0 change (pin `2.8.5`). Runtime proof: `get_mission_control_actions('class',fixture)` → 1 item `class.assign` (label 'Assign Program', v1, dynamic options), no class.edit — envelope byte-compatible.

---

## 6. GAP DISPOSITION

| Gap | State | Detail |
|---|---|---|
| **G1** | **PARTIAL** | dispatchability authority + discovery internal truth (`get_available_actions`) = registry-driven LIVE; **execute vẫn literal-dispatch** `class.assign` (chưa consume registry) |
| **G2** | **OPEN** | adapter resolver cutover chưa làm; execute chưa qua `_mc_lookup_action`/static-CASE resolver |
| **G3** | **OPEN** | `intent_fingerprint` chưa có; replay-conflict vẫn structural-only |
| **G4** | **CLOSED** | terminal forge chặn grant-layer (B6.2/D359–D360); no regression |

**KHÔNG tuyên bố:** B6.3 CLOSED · generic action execution complete · Decision layer ready · intent integrity complete. **Latent FE coupling** (`ClassWorkspaceScreen` submit path còn class.assign-specific) = future debt, CHƯA fix.

---

## 7. NEXT GATE

**V128-B6.3 Phase 2 — ADAPTER RESOLVER CUTOVER.** No implementation authorized by this handoff.

---

## 8. RESTRICTIONS (Phase 2 phải)

- Preserve `execute_mission_control_action` **public contract** (signature + return envelope) BẤT BIẾN.
- Preserve **commit boundary** (`mc_internal._mc_commit_action`, completed-only DEFINER).
- Preserve **adapter behavior** (`assign_class_distribution` BẤT BIẾN).
- **Run equivalence matrix E1–E12 before/after cutover** (JWT-impersonation, `BEGIN…ROLLBACK`); byte-identical outcome bắt buộc trước khi gỡ literal.
- **Include `get_mission_control_actions` reconciliation dưới E12** (registry-driven descriptor + dynamic option merge, giữ FE envelope byte-compatible).
- **KHÔNG add `intent_fingerprint` yet** (G3 = Phase 3).

---

## STRUCTURAL DELTA (Phase 1)

Registry +5 columns (additive) · +1 `mc_internal._mc_lookup_action` (+1 secdef, ngoài public count) · `get_available_actions` REPLACE (net 0 public fn) · 2 registry rows updated · ledger/commit/adapter/execute/get_mc_actions/FE/Edge/Bunny 0. Public inventory BẤT BIẾN `92·248·236·168·33·1`; mc_internal {2 fn / 2 secdef}. Migration tail `20260814114948` → `20260815080313`.

**Rollback:** DROP `mc_internal._mc_lookup_action(text,text)` → CREATE OR REPLACE `get_available_actions` về md5 `626d84d21dc0442ba2b7ef5a09194eaa` (predicate `status='active'`) + re-harden ACL `{postgres,service_role}` → UPDATE class.edit `status='active',disabled_reason=NULL` → UPDATE class.assign clear 5 authority cols → ALTER DROP COLUMN ×5 → NOTIFY pgrst. 0 data-repair.

**Canonical Endpoint:** RULES **D361** · SYSTEM_MAP **v1.49** · HANDOFF **V128-B6.3-PHASE-1** · backend tail `20260815080313` · FE main pin `2.8.5`. Khối D360/v1.48 (B6.2-A2) = HISTORICAL SNAPSHOT (BẤT BIẾN).
