# V128-B6.2 — IMPLEMENTATION DESIGN SPECIFICATION

> **Milestone:** V128-B6.2 · ACTION GOVERNANCE HARDENING
> **Vai trò:** Builder (Claude) · **Authority:** Owner (Jean) · CTO/CPO Architecture (ChatGPT)
> **Trạng thái:** Implementation Design — ✅ AUTHORIZED · Apply — ❌ NOT AUTHORIZED
> **Ngày:** 2026-08-14 (GMT+7) · **Loại:** Design specification, 0 mutation, không canonicalize, không migration, không apply.
> **Grounding:** Toàn bộ spec ground trên **live audit read-only** (D1), KHÔNG trên library memory. Divergence memory↔live được ghi ở §0.

---

## 0. GROUNDING NOTE — live audit vs canonical (đọc trước)

Baseline B6.1.5 sinh ra từ drift docs-vs-runtime. Em lặp lại kỷ luật đó: mọi con số dưới đây là **live read-only** tại thời điểm viết.

| Trục | Live (audit) | Khớp B6.1.5? |
|---|---|---|
| Migration tail | `20260813113400` | ✅ |
| Inventory | 92 tables · 248 fn · 236 secdef · 169 policies | ✅ |
| Object registry | 17 types (wired 8 / registered 3 / none 6) | ✅ |
| Action registry | 2 rows: `class.assign` (MEDIUM), `class.edit` (LOW) | ✅ |
| execute RPC | `execute_mission_control_action` — SECURITY **INVOKER**, `search_path=''` | ✅ |
| Adapter | `assign_class_distribution` — SECURITY **DEFINER**, `search_path=''` | ✅ |

**Cảnh báo cho Owner:** in-context library của Builder tụt phiên (dừng ở D356/v1.44/B3.3). Spec này **không** dùng nó. Nguồn = live DB + B6.1.5 canonical.

---

## 1. EXECUTIVE SUMMARY

B6.2 nâng **Action Execution Foundation** → **Governed Action Foundation** bằng cách **tách authorization ra khỏi domain adapter thành một governance seam tường minh, có bằng chứng, versioned** — KHÔNG thay `execute_mission_control_action`, KHÔNG mở action/object mới, KHÔNG build approval workflow.

Hiện trạng (grounded): authorization của `class.assign` đang **inline & ẩn** trong adapter `assign_class_distribution`:

```
is_admin()
  OR ( current_profile_role() IN ('master_admin','sub_admin')
       AND v_school_id = ANY(user_school_ids()) )
```

Vấn đề governance:
1. **Decision vô hình** — không có bằng chứng "vì sao được phép/bị từ chối" ở bất kỳ layer nào. `audit_logs` chỉ ghi *business event* (đã xảy ra gì), không ghi *authorization decision* (vì sao được phép).
2. **Không versioned** — predicate là code chết, không có policy version, không diff được, không audit-được theo thời gian.
3. **Không tái sử dụng** — mỗi adapter tương lai lại copy predicate → drift authz.
4. **Không tách risk** — `risk_level` sống trong registry nhưng **chưa có semantics**: MEDIUM và LOW hiện hành xử y hệt.

**Đề xuất cốt lõi (★):** một **decision function** `evaluate_action_policy()` (source of truth, DEFINER, internal-only) đọc một **declarative policy layer** nhỏ, trả **versioned decision DTO**, và ghi **governance evidence** vào một **Governance Ledger tách biệt** với Execution Ledger. Rollout **2 pha**: Shadow (quan sát, 0 behavior change) → Enforcement (gate trước dispatch, reversible). Adapter giữ nguyên inner-authz làm defense-in-depth.

Bám đúng house-pattern DMA đã có: **logic ở function, `policy_registry` là read-surface** (giống `consent`, `evidence_derivation`, `family_space_access`).

---

## 2. RECOMMENDED ARCHITECTURE

```
Object (mission_control_object_registry)
  ↓
Context (validate_mission_control_object_context_match)
  ↓
Action Definition (mission_control_action_registry — identity · risk_level · status · audit_event)
  ↓
┌─────────── ACTION GOVERNANCE LAYER (B6.2, mới) ───────────┐
│  Declarative policy   →  mission_control_action_policies  │
│  Decision function    →  evaluate_action_policy()  ★SoT   │
│  Risk semantics       →  risk_level → requirement tier    │
│  Documentation        →  policy_registry row (house-style)│
└───────────────────────────────────────────────────────────┘
  ↓ (decision = allow)
Execution Boundary (execute_mission_control_action — INVOKER, UNCHANGED signature)
  ↓
Domain Action (assign_class_distribution — DEFINER, inner-authz retained as backstop)
  ↓
Business Audit (audit_logs)  +  Governance Evidence (mission_control_action_authorizations)
  ↓
Memory (get_mission_control_memory — business-only projection, KHÔNG thấy authz decision)
```

**Nguyên tắc bất biến giữ nguyên (frozen B6.1.5):**
- `execute_mission_control_action` signature & INVOKER contract — **không đổi**.
- `mission_control_action_requests` = **Execution Ledger**, KHÔNG biến thành Governance Ledger.
- Adapter path `execute → assign_class_distribution → write_audit_log` — **không đổi** output.

---

## 3. DATA MODEL PROPOSAL

### PHASE A trả lời — Governance policy nằm ở đâu?

**★ Recommendation: Option C (Hybrid), tinh chỉnh theo precedent DMA.**

| | Descriptor (đã có) | Governance policy (mới) |
|---|---|---|
| Bảng | `mission_control_action_registry` | `mission_control_action_policies` |
| Chứa | identity · `object_type` · `label` · `capability` · `risk_level` · `audit_event` · `status` | authorization inputs only |
| Ai đọc | `get_available_actions` → **FE thấy được** | `evaluate_action_policy` → **internal-only, FE KHÔNG thấy** |

**Vì sao KHÔNG Option A (nhồi `governance_policy jsonb` vào registry):**
- Registry là **discovery surface** (`get_available_actions` project `action_key/label/risk_level` ra FE). Nhồi authz predicate vào đây → (a) leak governance intent ra client, (b) trộn "cái gì tồn tại" với "ai được phép", (c) phá separation mà object registry đã dựng.

**Vì sao KHÔNG Option B thuần (bảng policy rời, không link):**
- Tạo catalog thứ hai vô hình với `policy_registry` documentation surface → nghịch với kỷ luật DMA (mọi versioned policy đều có 1 row `policy_registry`).

**Option C tinh chỉnh = Descriptor registry (giữ nguyên) + Declarative policy table + Evaluator function (SoT) + policy_registry documentation row.** Đúng house-pattern: *logic ở function, registry là bề mặt đọc*.

### 3.1 `mission_control_action_policies` (declarative — proposed shape)

| Column | Type | Ghi chú |
|---|---|---|
| `action_key` | text PK/FK → registry | 1:1 với registry action |
| `required_scope` | text | enum `{platform, tenant, assignment}` (allowlist B3.1.5) |
| `min_role_set` | text[] | vd `{master_admin, sub_admin}`; platform-admin xử lý qua `is_admin()` fast-path |
| `required_capability` | text NULL | reserved — map `profiles.permissions text[]` (hiện rỗng → no-op) |
| `risk_requirement` | text | derived-from-registry `risk_level`; xem §6 |
| `policy_version` | text | vd `b6.2-v1` — để diff/audit theo thời gian |
| `evaluator` | text | = `'evaluate_action_policy'` (mirror `policy_registry.defined_in`) |
| `status` | text | `active` / `shadow` / `disabled` — cũng là enforcement switch (xem §8) |
| `updated_at` | timestamptz | |

- **`risk_level` vẫn authoritative ở registry** (nó đã drive FE badge). Policy table **reference** action_key, KHÔNG copy risk_level → single source. `risk_requirement` là *derivation* của risk_level, không phải nguồn thứ hai. → **CTO DECISION #1**.
- Seed 2 rows: `class.assign` (scope=tenant, min_role={master_admin,sub_admin}) · `class.edit` (scope=tenant, min_role={master_admin,sub_admin}). *(class.edit chỉ có policy, chưa có adapter — xem §9 boundary.)*
- RLS: `SELECT` admin-only (giống `policy_registry_select_admin`); **không** client-write.

### 3.2 `policy_registry` documentation row (house-style, mới 1 row)

```
code        = 'mission_control_action_governance'
title       = 'Mission Control — Action Authorization Governance'
active_version = 'b6.2-v1'
classification = 'VERSIONED_POLICY'
defined_in  = 'evaluate_action_policy + mission_control_action_policies'
admin_editable = false
summary     = { scope_allowlist, deny_precedence, risk_tiers, evidence_layer }
```

---

## 4. FUNCTION BOUNDARY — `evaluate_action_policy()`

### PHASE B trả lời

**1. Đặt ở đâu:** `public.evaluate_action_policy(...)`. Là **governance dependency** của execute, KHÔNG thay execute.

**2. SECURITY DEFINER hay INVOKER — ★ DEFINER, `search_path=''`, internal-only ACL.**
- DEFINER để đọc `mission_control_action_policies` + object metadata deterministic bất kể RLS caller — giống mọi projector/`is_admin()` của DMA.
- DEFINER **không** đổi `auth.uid()` → actor identity vẫn đúng (đã verify: `is_admin`/`current_profile` là DEFINER và vẫn resolve `auth.uid()`).
- **Internal-only:** `REVOKE ALL ... FROM PUBLIC, anon, authenticated` (D231). Nó là decision-dependency, KHÔNG phải client RPC → chặn client probe authz trực tiếp. Không expose PostgREST.
- **Pure read, side-effect-free** (không INSERT/UPDATE bên trong). Evidence-write do caller (execute) làm — giữ function thuần & testable.

**3. Input contract (proposed):**
```
evaluate_action_policy(
  p_actor_id     uuid,     -- resolved actor (execute truyền current_profile())
  p_action_key   text,
  p_object_type  text,
  p_object_id    uuid,
  p_context      jsonb,
  p_input        jsonb      -- optional, cho future input-scoped policy
) RETURNS jsonb
```
- Nhận `p_actor_id` **tường minh** (không tự resolve) → testable + cho shadow-eval truyền actor bất kỳ. An toàn vì internal-only ACL: chỉ execute (đã derive `current_profile()`) gọi được. → **CTO DECISION #2** (explicit param vs internal `current_profile()`).

**4. Output contract — versioned decision DTO (`ActionPolicyDecision/v1`), mirror `WorkspaceProjectionDTO/v1`:**
```json
{
  "envelope": "ActionPolicyDecision/v1",
  "decision": "allow" | "deny",
  "policy_version": "b6.2-v1",
  "action_key": "class.assign",
  "risk_level": "MEDIUM",
  "risk_requirement": "evidence_required",
  "reason_code": null | "MC_POLICY_ROLE_DENIED" | "MC_POLICY_SCOPE_DENIED" | "MC_POLICY_CONTEXT_DENIED" | "MC_POLICY_CAPABILITY_DENIED" | "MC_POLICY_UNDEFINED",
  "evaluated": { "role_ok": true, "scope_ok": true, "context_ok": true, "capability_ok": true, "platform_override": false },
  "actor_id": "…"
}
```
- **Deny là giá trị trả về, KHÔNG raise.** Function chỉ `RAISE` khi invariant nội bộ vỡ (config lỗi) — xem failure modes.

**5. Failure modes (fail-closed):**
| Tình huống | Kết quả |
|---|---|
| actor NULL | `deny` / `MC_POLICY_UNDEFINED` (hoặc `_PERMISSION_DENIED`) |
| policy thiếu cho action đang `active` | `deny` / `MC_POLICY_UNDEFINED` — **fail-closed**, không allow-by-default |
| role không thuộc `min_role_set` | `deny` / `MC_POLICY_ROLE_DENIED` |
| scope không thoả | `deny` / `MC_POLICY_SCOPE_DENIED` |
| context.school_id ≠ object.school_id | `deny` / `MC_POLICY_CONTEXT_DENIED` |
| bất kỳ ambiguity | `deny` (deny-by-default) |

---

## 5. AUTHORIZATION FLOW

### PHASE C trả lời — Actor → Role → Scope → Context → Action → Decision

**Policy evaluation order (fail-closed, first-failing-gate wins reason_code):**

1. **Resolve actor** — `p_actor_id` (NULL → DENY).
2. **Resolve policy** — `mission_control_action_policies` theo `action_key`; missing/`disabled` → DENY `MC_POLICY_UNDEFINED`.
3. **Platform override** — `is_admin()` = true → thoả **role+scope** (fast-path), NHƯNG vẫn phải qua **context validation** (bước 5). *(Khớp hiện trạng: is_admin() short-circuit school-role trong adapter, nhưng context-match ở execute luôn chạy.)*
4. **Role gate** — `current_profile_role() ∈ policy.min_role_set` → else DENY `MC_POLICY_ROLE_DENIED`.
5. **Scope gate** — theo `policy.required_scope`:
   - `platform` → yêu cầu `is_admin()`.
   - `tenant` → `object.school_id ∈ user_school_ids()`.  ← *class.assign hiện tại*
   - `assignment` → actor được assign trực tiếp vào object (vd teacher↔class). Allowlist B3.1.5 có nhưng **chưa action live** → model sẵn, inert.
   - else DENY `MC_POLICY_SCOPE_DENIED`.
6. **Context coherence** — `context.school_id === object.school_id` (cross-tenant gate) → else DENY `MC_POLICY_CONTEXT_DENIED`.
7. **Capability gate** — `policy.required_capability ∈ profiles.permissions`. Hiện `permissions` **rỗng toàn bộ** → treat như *role-implies-capability* (no-op passthrough). → **CTO DECISION #4**.

→ **ALLOW chỉ khi tất cả gate pass.** Bất kỳ DENY → short-circuit.

**Deny precedence:** DENY luôn thắng ALLOW. Fail-closed nghĩa là thứ tự gate KHÔNG đổi verdict, chỉ đổi `reason_code` (trả gate fail đầu tiên cho determinism).

**Context validation boundary (quan trọng — tránh dual source of truth):**
- `execute` GIỮ: context **shape/whitelist hygiene** (đúng object, đúng keys `{school_id}`, không key thừa) — input sanitation.
- `evaluate` SỞ HỮU: context **authorization coherence** (school_id match = cross-tenant authz).
- → **CTO DECISION #3**: có duplicate school-match ở cả hai (belt-and-suspenders) hay dời hẳn vào evaluate? Em nghiêng **giữ shape ở execute + coherence ở evaluate** (mỗi bên một trách nhiệm rõ ràng).

---

## 6. RISK GOVERNANCE MODEL

### PHASE D trả lời — risk_level → governance requirement (KHÔNG approval workflow)

Map `risk_level` → **requirement tier** (nghĩa vụ bằng chứng/verify, KHÔNG phải phê duyệt người):

| risk_level | requirement | Nghĩa vụ | Live? |
|---|---|---|---|
| `LOW` | `audit_only` | evaluate + business audit; không bắt buộc governance evidence row | class.edit |
| `MEDIUM` | `evidence_required` | evaluate + **persist authorization evidence** (decision row) | **class.assign** |
| `HIGH` | `evidence_strict` | MEDIUM + re-verify scope + context completeness bắt buộc | reserved, inert |
| `CRITICAL` | `evidence_strict + stepup_hook` | HIGH + hook step-up (**KHÔNG build ở B6.2**) | reserved, inert |

- LOW/MEDIUM live; HIGH/CRITICAL **declared-but-inert** (respect "Không build approval workflow"). → **CTO DECISION #6**: chấp nhận inert-declared, hay bỏ hẳn HIGH/CRITICAL khỏi model đến khi có action cần?
- Mapping đặt trong `evaluate` (CASE) + document ở `policy_registry.summary` — không cần bảng riêng cho 2 tier live.

---

## 7. EVIDENCE MODEL

### PHASE E trả lời — audit_logs.metadata (A) hay evidence layer riêng (B)?

**★ Recommendation: B — Governance evidence layer riêng.** Handoff nói tường minh: **không trộn business event với authorization decision.** DMA đã tách sẵn: business → `audit_logs`; execution lifecycle → ledger; authorization → *chưa có chỗ*. B6.2 bổ khuyết đúng chỗ trống đó.

**Vì sao KHÔNG A (`audit_logs.metadata`):**
- `get_mission_control_memory` project `audit_logs` thành UI user-facing ("Assigned <program>"). Nhét authz decision vào đây → **leak** decision ra Memory + pollute business stream (business-semantic).

**Proposed: `mission_control_action_authorizations` (Governance Ledger — TÁCH khỏi Execution Ledger):**

| Column | Ghi chú |
|---|---|
| `id` uuid PK | |
| `request_id` uuid | link → Execution Ledger (join 3 layer) |
| `actor_id` uuid | |
| `action_key` · `object_type` · `object_id` | |
| `decision` text | allow/deny |
| `reason_code` text NULL | |
| `policy_version` text | |
| `risk_level` text | |
| `evaluated` jsonb | snapshot các gate |
| `created_at` timestamptz | |

- Thoả bất biến B6.1.5: **Execution Ledger KHÔNG thành Governance Ledger** — đây là bảng thứ hai, tách bạch.
- Ghi bởi **execute** (caller), KHÔNG bởi evaluate (evaluate thuần read).
- RLS: **deny-all client-write**; SELECT admin-only. Insert qua execute (INVOKER) cần policy hoặc DEFINER-writer helper — xem §8 hardening.
- **Linkage 3 tầng:** `request_id` nối *Execution* (đã chạy gì) ↔ *Governance* (vì sao được phép) ↔ *audit_logs* (business fact).
- **Persistence policy:** Shadow → ghi **mọi** decision (full observability). Enforcement → **deny luôn ghi** + allow ghi cho **MEDIUM+** (risk-tiered, bound table growth cho LOW volume cao). → **CTO DECISION #5**.

---

## 8. MIGRATION STRATEGY (design only — KHÔNG apply)

Tuân D92 three-block (CREATE/REPLACE → REVOKE/GRANT re-harden → VERIFY rollback-guard), D231 (re-harden ACL sau CREATE OR REPLACE), D289 (`notify pgrst` reload cho table client-read mới). Sequencing DB-first (B6.2 backend-only; FE generic renderer là E-item **deferred**, ngoài phạm vi).

### Phase 1 — SHADOW (0 behavior change)
1. Tạo `mission_control_action_policies` + seed 2 rows.
2. Tạo `evaluate_action_policy()` (DEFINER, internal-only ACL).
3. Tạo `mission_control_action_authorizations` (Governance Ledger, RLS deny-write).
4. Thêm `policy_registry` row `mission_control_action_governance`.
5. Trong `execute_mission_control_action`: **SAU** các gate hiện có, quanh dispatch — gọi `evaluate_action_policy`, **ghi decision** vào Governance Ledger, **KHÔNG branch** trên nó (hành vi bất biến).
- **Success gate:** trên corpus request thật, `evaluate.decision` === outcome adapter thực tế (allow ↔ adapter succeed; deny ↔ adapter raise `not_authorized_for_school`). **Divergence = 0** trong cửa sổ shadow.
- ⚠️ Phase 1 **chạm schema + REPLACE execute** → theo auto-publish rule của DMA, đây là **STOP-and-ask** (Supabase schema mutation). Spec này chỉ *thiết kế*; apply chờ Owner Gate riêng.

### Phase 2 — ENFORCEMENT READINESS
1. Flip execute: nếu `evaluate.decision='deny'` → return `MC_ACTION_PERMISSION_DENIED` (mapped) **TRƯỚC dispatch**, không gọi adapter.
2. Adapter inner-authz **GIỮ NGUYÊN** (defense-in-depth — cuối cùng vẫn chặn).
3. **Enforcement switch reversible** không cần đổi code: qua `mission_control_action_policies.status` (`shadow` → `active`) hoặc `app_settings` flag. → **CTO DECISION #7**.
4. **Rollout gate:** shadow divergence = 0 đủ N ngày + Owner Gate → mới flip.

*(Vì execute signature bất biến & evaluate internal-only, PostgREST reload chỉ cần cho table mới nếu có client SELECT.)*

---

## 9. QA ACCEPTANCE CRITERIA

### PHASE G — test matrix

**ALLOWED**
- `master_admin` của school X, class ∈ X → `allow`.
- `super_admin` (is_admin) → `allow` bất kỳ school.

**DENIED — wrong scope**
- `master_admin` school X, class ∈ school Y → `deny / MC_POLICY_SCOPE_DENIED` (+ context mismatch).

**DENIED — wrong role**
- `lead_teacher` / `assistant_teacher` / `primary_parent` gọi `class.assign` → `deny / MC_POLICY_ROLE_DENIED`.

**CONTEXT mismatch**
- `context.school_id ≠ object.school_id` → `deny / MC_POLICY_CONTEXT_DENIED`.
- Context malformed / key thừa → chặn ở execute shape-gate (bất biến).

**FAIL-CLOSED**
- actor NULL → deny. Action active nhưng thiếu policy → `deny / MC_POLICY_UNDEFINED`.

**REGRESSION (frozen invariants — bắt buộc pass)**
- `class.assign` happy path **byte-identical**: cùng INSERT `class_distributions`, cùng audit `CLASS_ASSIGNMENT_CREATED`, cùng result DTO.
- Execution Ledger lifecycle bất biến: `processing → completed/failed`, idempotent replay theo `request_id`.
- `audit_logs` bất biến. Memory projection bất biến (KHÔNG thấy authz decision).
- **Shadow phase: hành vi byte-identical** — chỉ thêm Governance Ledger rows, không branch.

**SECURITY**
- `evaluate_action_policy` KHÔNG EXECUTE-able bởi anon/authenticated (internal-only) — direct probe denied.
- Governance Ledger KHÔNG client-writable (RLS deny / DEFINER-only insert).

**Method (D2/D3):** impersonation harness — `set_config('request.jwt.claims', json_build_object('sub',uid,'role','authenticated'), true)` + `SET LOCAL ROLE authenticated` + `RESET ROLE` trong exception handler — cho path RLS/authz; **real login** verify cho enforcement flip. Verification qua rollback-safe simulation (`DO $sim$ … RAISE EXCEPTION`), KHÔNG `apply_migration` khi verify.

---

## 10. OPEN QUESTIONS FOR CTO REVIEW

> Builder dừng ở đây cho các điểm architecture chưa chốt — **CTO DECISION REQUIRED**:

1. **Policy placement final:** `mission_control_action_policies` rời (★ em đề xuất) vs authz-columns nhồi vào registry? Và xác nhận `risk_level` giữ authoritative ở registry (policy chỉ reference)?
2. **evaluate actor param:** explicit `p_actor_id` (★, testable/shadow) vs internal `current_profile()` resolution?
3. **Context coherence ownership:** school-match giữ duplicate ở execute + evaluate (belt-and-suspenders) hay dời hẳn vào evaluate?
4. **Capability gate:** `profiles.permissions text[]` hiện rỗng — treat `required_capability` như role-implied no-op (★) hay defer capability hoàn toàn khỏi B6.2?
5. **Evidence layer:** Governance Ledger riêng (★) vs `audit_logs` event-class? Và persistence policy (all-in-shadow / risk-tiered-in-enforcement)?
6. **Risk tiers:** HIGH/CRITICAL declared-but-inert (★, không approval workflow) hay bỏ hẳn đến khi có action cần?
7. **Enforcement switch:** `policies.status` (★) vs `app_settings` flag vs migration-gated — cơ chế reversible nào?
8. **Ledger forge vuln (B6.1.5 §E.4):** `finish_own` policy cho phép client forge `completed/failed/result_payload` qua PostgREST. Đây là **integrity của governed action** — fold vào B6.2 hardening hay giữ deferred? *(Adjacent nhưng không nằm trong 3 trục permission/risk/evidence mà CTO scope.)* — **CTO DECISION**.
9. **class.edit mismatch:** `class.edit` active trong registry (get_available_actions quảng cáo) nhưng execute hardcode reject ≠ `class.assign`, và không có adapter. B6.2 có seed policy cho `class.edit` → sẽ thành *"policy-allowed nhưng execution-unavailable"*. Adapter-dispatch-seam là **E-item riêng (deferred)**. Xác nhận: B6.2 chỉ seed policy `class.edit` (consistency) và **KHÔNG** mở execution cho nó? — **CTO DECISION**.
10. **Scope taxonomy:** xác nhận `{platform, tenant, assignment}` là closed-set cho B6.2. `assignment` chưa có action live (class.assign = tenant) — model-inert now hay defer khỏi schema?

---

**FINAL RULE tuân thủ:** Builder KHÔNG tự mở scope, KHÔNG tạo migration, KHÔNG apply. 0 mutation đã thực hiện — chỉ live read-only audit. Deliverable = design spec. Các điểm chưa rõ → đánh **CTO DECISION REQUIRED** và dừng, chờ Owner Gate cho apply.
