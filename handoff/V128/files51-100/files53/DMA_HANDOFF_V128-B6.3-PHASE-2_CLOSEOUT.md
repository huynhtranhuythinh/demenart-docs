# 🗂️ DMA_HANDOFF_V128-B6.3-PHASE-2_CLOSEOUT.md — ACTION CONTROL PLANE · ADAPTER RESOLVER CUTOVER

> **Ngày:** 2026-08-15 (GMT+7) · **Loại:** Phase 2 apply + canonical closeout (1 migration; execute cutover + get_mission_control_actions reconcile; 0 ledger/FE change).
> **Boot phiên sau:** file này → `DMA_RULES.md` (tip **D362**) → `DMA_SYSTEM_MAP.md` (**v1.50**) → audit live DB (D1) → re-pin.
> **Endpoint:** RULES **D362** · SYSTEM_MAP **v1.50** · HANDOFF **V128-B6.3-PHASE-2** · backend migration tail **`20260815085223`** (`v128_b6_3_p2_adapter_resolver_cutover`) · FE main pin `2.8.5`.

---

## 1. STATUS

**PHASE 2 CLOSED.** V128-B6.3 overall: **NOT CLOSED.**

Adapter Resolver Cutover applied + verified live (PRE/POST E1–E12 equivalence EMPTY diff; P2-A1–A20 PASS; zero drift). Đóng **G1** (execution-side mismatch) + **G2** (adapter seam). **G3** (intent integrity) = Phase 3.

---

## 2. OBJECTIVE

Thay literal dispatch (`if action_key='class.assign' → hardcoded assign_class_distribution`) bằng **registry-driven authority lookup → declarative validation → static adapter resolver → existing adapter → existing commit-core**, KHÔNG đổi public behavior. Reconcile `get_mission_control_actions` sang authority/presentation split. CTO-locked 7 micro-decisions.

---

## 3. LIVE STATE

- **migration:** `20260815085223` (`v128_b6_3_p2_adapter_resolver_cutover`) — D92 3-block, VERIFY fail-closed PASS, `NOTIFY pgrst`.
- **public inventory:** `92 · 248 · 236 · 168 · 33 · 1` (BẤT BIẾN).
- **mc_internal:** **2 fn / 2 secdef** (BẤT BIẾN — no Phase-2 helper).
- **registry:** class.assign (active · `class.assign.v1` · single_domain_rpc · required_context **typed** · v1 · label 'Assign Teacher') · class.edit (disabled · NULL).

---

## 4. DELIVERED

- **execute registry-driven:** action selection qua `mc_internal._mc_lookup_action('class', p_action_key)` thay literal action gate (cùng precedence point). `found=false ∨ dispatchable=false → MC_ACTION_NOT_FOUND`.
- **required_context typed declaratively:** `{"keys":["school_id"],"exclusive":true,"types":{"school_id":"uuid"}}`.
- **bounded declarative validators:** context (keys/exclusive/types, uuid grammar → CONTEXT_DENIED) + MissionActionInputSchema/v1 (declared-keys/required/nullable/uuid → INPUT_INVALID; unsupported version → EXECUTION_FAILED, unreachable).
- **static adapter allowlist:** `CASE adapter_key WHEN 'class.assign.v1' → assign_class_distribution ELSE raise → EXECUTION_FAILED`. **No dynamic SQL / no name-from-registry / no regprocedure.**
- **get_mission_control_actions reconcile:** authority (key/risk_level/input_schema-structure) từ registry qua `_mc_lookup_action`; object/context gate (`get_available_actions`) preserved; presentation (label 'Assign Program', description, field labels, dynamic options) server-owned; registry label 'Assign Teacher' KHÔNG surface.
- **E1–E12 equivalence proof** PRE vs POST (JWT-impersonation, BEGIN…ROLLBACK).

---

## 5. FROZEN / UNCHANGED (md5 proven post-apply)

| Object | md5 | Note |
|---|---|---|
| `mc_internal._mc_commit_action` | `ce36c5fe109e99a919158a4482940c6a` | completed-only DEFINER — untouched |
| `public.assign_class_distribution` | `03a1510bd827c03a650a3a88312fbe3a` | domain adapter — untouched |
| `mc_internal._mc_lookup_action` | `5d940037687be0a398a232cf987bfcf6` | DEFINER · A9 8-field whitelist — untouched |
| `public.get_available_actions` | `fd874243a90e20d171058f3ddb648356` | dispatchable-only — untouched |

**Changed (Phase 2):** `execute_mission_control_action` → **`cf446902587cd6d0dea9d578d645bf71`** (INVOKER, `search_path=''`, sig BẤT BIẾN) · `get_mission_control_actions` → **`3596633c6f7f1b7ecdc81822691475d4`** (DEFINER, sig BẤT BIẾN).

- **Ledger** `mission_control_action_requests`: schema/constraints/indexes/RLS/policies/grants UNCHANGED; **no `intent_fingerprint`**; authenticated terminal UPDATE = 0; authenticated grants INSERT,SELECT.
- **FE:** 0 change (pin `2.8.5`).

---

## 6. CURRENT EXECUTION PIPELINE

```
auth.uid            → PERMISSION_DENIED
current_profile     → PERMISSION_DENIED
registry lookup     mc_internal._mc_lookup_action('class', p_action_key)
action verdict      found=false ∨ dispatchable=false → NOT_FOUND   (precedence: before object/ctx/input)
object/request null → INPUT_INVALID
context validation  declarative (keys/exclusive/types) → CONTEXT_DENIED
input validation    declarative v1 (keys/required/uuid) → INPUT_INVALID
object lookup       classes (INVOKER, RLS-filtered) → OBJECT_NOT_FOUND
context/object match context.school_id ≠ class.school_id → CONTEXT_DENIED
ledger processing   INSERT ON CONFLICT / replay branch (structural triple, unchanged)
static adapter CASE  class.assign.v1 → assign_class_distribution ; ELSE → EXECUTION_FAILED
adapter exception    β2 map (verbatim)
commit-core          mc_internal._mc_commit_action (unchanged)
```

`object_type` = constant `'class'` (execute vẫn class-implicit; KHÔNG generalize multi-object trong B6.3).

---

## 7. EQUIVALENCE (PRE vs POST — EMPTY semantic diff)

- **execute:** semantic jsonb equality trên `ok/replayed/request_id/action_key/object_type/object_id/result/audit/error.code` + side-effect (ledger/distribution/audit) equality + ledger terminal state equality. (Chỉ khác: `class_distribution_id` tx-local uuid ở E1/E7 — cả hai rolled back; structure + intra-pair equality identical.)
- **get_mission_control_actions:** semantic jsonb + **array-order** equality (items/fields/options).

| Case | PRE | POST |
|---|---|---|
| E1 success | ok, dist, audit | ✓ identical |
| E2 no-auth | PERMISSION_DENIED | ✓ |
| E2b no-right | **OBJECT_NOT_FOUND** | ✓ |
| E3 ×5 | CONTEXT_DENIED | ✓ |
| E4 ×6 | INPUT_INVALID | ✓ |
| E5 ×5 (incl precedence) | NOT_FOUND | ✓ |
| E6 | OBJECT_NOT_FOUND | ✓ |
| E7 replay | replayed, same-dist, Δ=0 | ✓ |
| E8 in-progress | REQUEST_IN_PROGRESS | ✓ |
| E9 conflict | CONFLICT, ledger_R9=0 | ✓ |
| E11 discovery | [class.assign] | ✓ |
| E12 FE item | label 'Assign Program', v1, options order | ✓ identical |

---

## 8. E2b CORRECTION (design expectation corrected by live evidence)

Design doc kỳ vọng E2b → `MC_ACTION_PERMISSION_DENIED` (adapter authz). **Live PRE + POST đều = `MC_ACTION_OBJECT_NOT_FOUND`.**

Lý do: `execute` là **SECURITY INVOKER**; object lookup gate-7 (`select school_id from classes`) bị **RLS lọc theo caller**. Actor không có school-visibility → không thấy class → OBJECT_NOT_FOUND **trước** khi tới adapter authz. Adapter `not_authorized_for_school → PERMISSION_DENIED` branch chỉ kích hoạt với actor **thấy-được-class-nhưng-không-được-assign** (hẹp hơn), và branch đó vẫn được bảo toàn verbatim trong β2 exception map (exercised live bởi E9 `distribution_exists → CONFLICT`).

**Đây là:** DESIGN EXPECTATION CORRECTED BY LIVE EVIDENCE. **KHÔNG phải:** regression / new policy / semantic change. POST == PRE.

---

## 9. GAP DISPOSITION

| Gap | State | Detail |
|---|---|---|
| **G1** | **CLOSED** | registry drives action selection + adapter_key + required_context + input_schema; literal action gate removed |
| **G2** | **CLOSED** | static adapter resolver seam (`adapter_key → allowlisted RPC`); no dynamic dispatch |
| **G3** | **OPEN** | `intent_fingerprint` chưa có; replay-conflict vẫn structural-triple-only |
| **G4** | **CLOSED** | terminal forge chặn grant-layer (B6.2/D359–D360); no regression |

**Invariant nhấn mạnh:** **Registry decides WHAT can execute. Domain adapter decides WHO can execute.** `_mc_lookup_action` KHÔNG phải authz authority.

**KHÔNG tuyên bố:** B6.3 CLOSED · intent integrity done · replay hardening done · generic multi-object executor · generic schema engine · Decision layer. **Latent FE coupling** (`ClassWorkspaceScreen` submit path class.assign-specific) = future debt, CHƯA fix.

---

## 10. NEXT GATE

**V128-B6.3 Phase 3 — INTENT INTEGRITY.** No implementation authorized by this handoff.

---

## 11. PHASE 3 RESTRICTIONS

Phase 3 phải: preserve execute public signature · preserve registry-driven resolver · preserve static CASE allowlist · preserve adapter/commit behavior · preserve ledger terminal ownership (`_mc_commit_action` DEFINER) · **add intent integrity only** · KHÔNG generic object engine · KHÔNG modify FE trừ khi authorized riêng.

---

## STRUCTURAL DELTA (Phase 2)

`execute_mission_control_action` REPLACE (net 0 public fn) · `get_mission_control_actions` REPLACE (net 0) · 1 registry row updated (required_context typed) · ACL re-harden ×2 ({authenticated,postgres}) · ledger/commit/adapter/lookup/gaa/FE/Edge/Bunny 0. Public inventory BẤT BIẾN `92·248·236·168·33·1`; mc_internal {2 fn / 2 secdef}. Migration tail `20260815080313` → `20260815085223`.

**Rollback (nếu CTO yêu cầu):** CREATE OR REPLACE `execute_mission_control_action` về md5 `771470473d17c31a247999a51e499094` + CREATE OR REPLACE `get_mission_control_actions` về md5 `e4fdd0138e27f40eb9c76aa4f4b6ab65` + UPDATE class.assign.required_context về `{"keys":["school_id"],"exclusive":true}` + re-harden ACL {authenticated,postgres} ×2 + NOTIFY pgrst. **KHÔNG** ledger/adapter/commit/column repair.

**Canonical Endpoint:** RULES **D362** · SYSTEM_MAP **v1.50** · HANDOFF **V128-B6.3-PHASE-2** · backend tail `20260815085223` · FE main pin `2.8.5`. Khối D361/v1.49 (Phase 1) = HISTORICAL SNAPSHOT (BẤT BIẾN).
