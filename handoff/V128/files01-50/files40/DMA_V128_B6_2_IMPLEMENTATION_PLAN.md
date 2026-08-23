# V128-B6.2 — IMPLEMENTATION PLAN

> **Milestone:** V128-B6.2 · ACTION GOVERNANCE HARDENING
> **Vai trò:** Builder (Claude) · **Authority:** Owner (Jean) · CTO/CPO Architecture (ChatGPT)
> **Trạng thái:** Architecture ✅ APPROVED · Implementation Design ✅ APPROVED-WITH-DECISIONS · Implementation Plan ➡️ THIS DOC
> **Ràng buộc:** KHÔNG code · KHÔNG SQL · KHÔNG apply · KHÔNG sửa canonical · KHÔNG mở scope. Plan-level only.
> **Ngày:** 2026-08-14 (GMT+7)

---

## 0. FROZEN CTO DECISIONS — đã hấp thụ vào plan

| # | Decision | Ảnh hưởng plan |
|---|---|---|
| 1 | Hybrid governance layer (registry → policies → evaluate → authorizations → execute → adapter) | §2 change map |
| 2 | Chỉ govern **`class.assign`**. `class.edit` **KHÔNG** seed policy, KHÔNG execution path | §1 P1 seed 1 row duy nhất |
| 3 | Capability: **reserved field only**, KHÔNG activate, KHÔNG "role-implies-capability" | evaluate **bỏ hẳn** capability gate; cột `required_capability` dormant |
| 4 | Risk LOW/MEDIUM/HIGH/CRITICAL giữ; HIGH/CRITICAL **declared-only**, không workflow | risk→requirement chỉ LOW/MEDIUM có tác dụng |
| 5 | Rollout dùng **policy lifecycle riêng** (`shadow`/`enforcing`/`disabled`), KHÔNG dùng registry status | §5–6 flip = data-only trên `mission_control_action_policies` |
| 6 | Evidence = `mission_control_action_authorizations` (KHÔNG audit_logs, KHÔNG ledger) | §1 P1 |
| 7 | **FOLD execution-integrity hardening**: client không được forge completion; "client create request / system finalize" | §4 (đường B, giữ INVOKER) |

**Ghi chú capability (D3):** vì CTO cấm cả "role-implies-capability", evaluate **không** có capability gate trong B6.2. Cột `required_capability` tồn tại nhưng evaluate **bỏ qua** hoàn toàn. Không có no-op passthrough logic — đơn giản là không tồn tại nhánh capability.

---

## 1. IMPLEMENTATION PHASES

Thứ tự đề xuất **khác** ví dụ minh hoạ của CTO ở một điểm: **integrity hardening (P3) đặt TRƯỚC shadow (P4)**, không sau. Lý do dependency: shadow phải ghi evidence vào bảng client-deny-write → cần DEFINER writer reachable → cần commit-core DEFINER (chính là cơ chế integrity). Viết evidence trước khi dựng commit-core sẽ để hở cửa sổ client-write. Đây là **sequencing recommendation** (trong thẩm quyền Builder), không đổi architecture.

### Phase 0 — Precondition audit
- **Objective:** Re-confirm live TRƯỚC mọi write (D1). Không tin snapshot phiên trước.
- **Kiểm:** tail = `20260813113400`; inventory 92/248/236/169; 3 ledger policy (`insert_own_processing`/`finish_own`/`select_own`) còn nguyên với predicate đã audit; `execute_mission_control_action` INVOKER; `assign_class_distribution` DEFINER; registry 2 rows. Surface bất kỳ drift.
- **Touched:** none (read-only).
- **Risk:** none.
- **Rollback:** n/a. Nếu drift → **STOP**, báo Owner.

### Phase 1 — Schema foundation (additive, dormant)
- **Objective:** Dựng data model governance, chưa wire.
- **CREATE:** `mission_control_action_policies` (+ seed **1 row `class.assign`** duy nhất) · `mission_control_action_authorizations` (governance evidence) · 1 row documentation trong `policy_registry` (`mission_control_action_governance`).
- **Touched:** 2 bảng mới + 1 row catalog. Zero tác động runtime (chưa ai đọc/gọi).
- **Risk:** LOW — thuần additive; RLS mới phải deny client-write ngay từ đầu.
- **Rollback:** DROP 2 bảng + DELETE 1 catalog row. Non-destructive (chưa có business data).

### Phase 2 — Policy evaluator (dormant)
- **Objective:** Dựng decision function, chưa gọi từ execute.
- **CREATE:** `evaluate_action_policy()` — DEFINER, `search_path=''`, **internal-only ACL** (revoke anon/authenticated), pure-read, trả `ActionPolicyDecision/v1`.
- **Touched:** 1 function mới. Zero runtime (execute chưa gọi).
- **Risk:** LOW — không nằm trên bất kỳ live path.
- **Rollback:** DROP function.

### Phase 3 — Execution integrity hardening (đường B — giữ INVOKER)
- **Objective:** Đóng forge (decision #7) mà **giữ frozen invariant** `execute = INVOKER`.
- **CREATE:** DEFINER commit-core (đặt tên vd `_mc_commit_action`) — chứa adapter-call + ledger-finalize + evidence-write, **result server-derived** (không nhận `result_payload` từ caller).
- **REPLACE:** `execute_mission_control_action` — GIỮ INVOKER, giữ signature; các gate hiện có + pristine INSERT (client-create) **giữ nguyên**; phần adapter-call + finalize **delegate** sang commit-core.
- **DROP:** RLS policy `mission_control_action_requests_finish_own` (client mất quyền finalize).
- **KEEP:** `insert_own_processing` (client-create, decision #7) · `select_own`.
- **Touched:** live path `class.assign`. **Đây là phase rủi ro nhất.**
- **Behavior invariant:** class.assign **byte-identical** — cùng INSERT `class_distributions`, cùng audit `CLASS_ASSIGNMENT_CREATED`, cùng result DTO, cùng ledger transition `processing→completed/failed`, cùng idempotent replay.
- **Risk:** MEDIUM-HIGH — chạm execute + live ledger. Bắt buộc verify byte-identical qua rollback-safe simulation trước apply.
- **Rollback:** restore prior `execute` definition + re-CREATE `finish_own` policy + DROP commit-core. Non-destructive.

### Phase 4 — Shadow integration
- **Objective:** evaluate chạy song song, ghi evidence, **KHÔNG branch** (0 behavior change).
- **REPLACE:** commit-core — thêm gọi `evaluate_action_policy` → ghi decision vào `authorizations` + ghi **actual authz outcome** để so; **KHÔNG** dùng decision để chặn. Policy lifecycle = `shadow`.
- **Touched:** commit-core (execute signature bất biến).
- **Risk:** LOW — additive observability; class.assign vẫn byte-identical.
- **Rollback:** REPLACE commit-core bỏ nhánh evaluate; hoặc set policy lifecycle=`disabled` (kill-switch data-only).

### Phase 5 — Enforcement readiness (chờ Owner Gate)
- **Objective:** Bật gate: `decision='deny'` → return `MC_ACTION_PERMISSION_DENIED` **trước** adapter dispatch.
- **CHANGE:** policy lifecycle `shadow → enforcing` (**data-only** trên `mission_control_action_policies`). Commit-core đã có nhánh branch-on-lifecycle từ P4/P5 replace.
- **Adapter inner-authz GIỮ NGUYÊN** (defense-in-depth cuối).
- **Gate:** divergence=0 + QA pass + Owner approval (§6).
- **Risk:** MEDIUM — thay đổi verdict thật. Nhưng reversible tức thì.
- **Rollback:** lifecycle `enforcing → shadow` (data-only, instant, non-destructive).

---

## 2. DATABASE CHANGE PLAN (plan only, no SQL)

**CREATE — tables**
- `mission_control_action_policies` — declarative authz inputs (P1).
- `mission_control_action_authorizations` — governance evidence / decision ledger (P1).

**CREATE — functions**
- `evaluate_action_policy()` — DEFINER, internal-only, pure-read (P2).
- `_mc_commit_action` (DEFINER commit-core) — privileged adapter-call + finalize + evidence-write, result server-derived (P3).

**CREATE — rows (data)**
- 1 seed row trong `mission_control_action_policies` = `class.assign` (P1).
- 1 documentation row trong `policy_registry` = `mission_control_action_governance` (P1).

**CREATE — indexes**
- `mission_control_action_authorizations`: index theo `request_id` (join Execution Ledger) + `(action_key, created_at)` (divergence query). PK trên id.
- `mission_control_action_policies`: PK/unique trên `action_key`.

**ALTER — existing objects**
- KHÔNG ALTER registry (risk_level giữ authoritative ở đó). KHÔNG ALTER ledger schema (decision #7: không redesign ledger). KHÔNG ALTER `audit_logs`.

**REPLACE — functions**
- `execute_mission_control_action` — GIỮ INVOKER/signature; delegate adapter+finalize sang commit-core (P3). Tái áp mỗi phase chạm nó (P3, P4/P5) → mỗi lần re-harden ACL (D231) + verify.
- `_mc_commit_action` — REPLACE ở P4 (thêm evaluate/evidence), P5 (thêm branch-on-lifecycle).

**REVOKE/GRANT — ACL**
- `evaluate_action_policy`: REVOKE ALL FROM PUBLIC, anon, authenticated → internal-only (owner + commit-core reachable). GRANT không cho client.
- `_mc_commit_action`: GRANT EXECUTE cho `authenticated` (bắt buộc, vì INVOKER execute gọi nó dưới role client). An toàn: forge-proof by construction (result server-derived + adapter tự authz).
- Sau mỗi `CREATE OR REPLACE`: re-harden theo D231 (Supabase auto-grant anon/authenticated → REVOKE lại tường minh). D92 three-block (CREATE→REVOKE/GRANT→VERIFY) cho mọi migration.
- Ledger RLS: DROP `finish_own`; giữ `insert_own_processing` + `select_own`.
- `mission_control_action_authorizations` RLS: SELECT admin-only; **deny client write** (chỉ commit-core DEFINER ghi).
- `mission_control_action_policies` RLS: SELECT admin-only; deny client write.

**PostgREST (D289):** `notify pgrst, 'reload schema'` sau P1 nếu client cần SELECT bảng mới. `evaluate`/commit-core internal → không cần expose. `execute` signature bất biến → client cache không đổi.

---

## 3. FUNCTION CHANGE MAP

### `execute_mission_control_action()`
| Trục | B6.2 |
|---|---|
| Signature | **KHÔNG đổi** (`p_action_key, p_object_id, p_context, p_input, p_request_id`) |
| Security mode | **GIỮ INVOKER** (đường B — tôn trọng frozen B6.1.5) |
| ACL | KHÔNG đổi (vẫn client-callable) |
| Body | Giữ gates (auth/shape/context/cross-tenant) + pristine INSERT (client-create); **delegate** adapter+finalize sang commit-core |

### `_mc_commit_action` (mới — DEFINER commit-core)
- Mới hoàn toàn. DEFINER, `search_path=''`. GRANT authenticated (để INVOKER execute gọi được).
- Trách nhiệm: (P3) idempotent finalize + adapter-call + evidence-write; (P4) evaluate + record decision; (P5) branch-on-lifecycle.
- **Result server-derived** — không nhận `result_payload`/`status` từ caller → forge-proof.

### `evaluate_action_policy()` (mới — DEFINER, internal-only)
- Pure-read decision. Gates: role → scope → context-coherence. **KHÔNG** capability gate (D3). Trả `ActionPolicyDecision/v1`. Deny = return-value, không raise (raise chỉ khi config vỡ = policy thiếu cho action active → fail-closed).

### `assign_class_distribution()` (adapter)
- **GIỮ NGUYÊN.** Inner-authz predicate (`is_admin() OR master/sub_admin+school`) ở lại làm defense-in-depth backstop. Không đụng.

---

## 4. EXECUTION INTEGRITY HARDENING

**Current (forge vector):** `execute` = INVOKER; RLS `finish_own` cấp `authenticated` UPDATE `status→completed/failed` + `result_payload` + `completed_at`. Client bỏ qua execute, PATCH thẳng ledger qua PostgREST → forge completion. Không predicate RLS nào phân biệt được vì execute-INVOKER cũng ghi dưới role `authenticated`.

**Root cause:** kết quả (`result_payload`) đi qua trust boundary do caller cung cấp. Muốn chặn forge, hàm **gọi adapter** phải **cũng là** hàm **ghi kết quả**, và không nhận kết quả từ caller.

**★ Đường B (recommended) — giữ INVOKER + DEFINER commit-core:**
```
client → execute (INVOKER, unchanged)
           |  gates + pristine INSERT (client-create)
           v
        _mc_commit_action (DEFINER, owner priv)
           |  evaluate → adapter → RESULT server-derived → finalize ledger → write evidence
           v
        done
```
- **RLS change:** DROP `finish_own`. Client mất hoàn toàn quyền finalize. Giữ `insert_own_processing` (client-create, đúng decision #7) + `select_own` (client đọc status của mình).
- **Helper:** `_mc_commit_action` DEFINER. Ghi ledger-completion + evidence dưới owner (bypass RLS). Kết quả derive từ adapter return, **không** từ input.
- **Ownership boundary:** client chỉ có thể (a) tạo pristine processing row, (b) đọc row của mình. **Không** finalize, **không** ghi evidence, **không** set result. Direct call `_mc_commit_action` = một execution thật (adapter tự authz + result thật) → **không phải forge**.
- **Frozen invariant:** `execute` vẫn INVOKER → B6.1.5 không bị reopen.

**Đường A (alternative, KHÔNG chọn):** flip `execute` → DEFINER (đơn giản hơn 1 function) nhưng **reopen frozen INVOKER invariant** → cần CTO unfreeze. Ghi ở §9 để CTO cân nhắc; plan mặc định đi đường B.

**Không redesign ledger:** schema ledger bất biến; lifecycle values (`processing→completed/failed`) bất biến. Chỉ đổi **ai được ghi** (RLS + DEFINER writer). Đúng ràng buộc decision #7.

---

## 5. SHADOW ROLLOUT DESIGN

```
execute (INVOKER, gates + INSERT)
   → _mc_commit_action (DEFINER)
        → evaluate_action_policy()          [governance decision]
        → assign_class_distribution()        [existing adapter authz = ground truth]
        → COMPARE(decision, actual_authz_outcome)
        → record → mission_control_action_authorizations
        → (shadow: KHÔNG branch)
```

**Divergence detection — điểm tinh tế bắt buộc đúng:**
- evaluate quyết định **CHỈ trên authorization** (role + scope + context). Adapter còn có **business rules** (`has_subject_entitlement`, `dma_assignable_teacher_reason`, dup-guard) — **KHÔNG** phải authz.
- Ground truth authz = adapter raise `not_authorized_for_school` (→ `MC_ACTION_PERMISSION_DENIED`) hay không. Các failure khác (`subject_not_entitled`/`distribution_exists`/`lead_teacher_invalid`) là business outcome → **loại khỏi so sánh divergence**.
- **Divergence types ghi lại:**
  - **FALSE-ALLOW** (evaluate=allow nhưng adapter denied authz) — **NGUY HIỂM**, phải = 0 trước enforce.
  - **FALSE-DENY** (evaluate=deny nhưng adapter cho phép authz) — sẽ over-block nếu enforce; phải = 0.
- **Metrics:** đếm theo type trên cửa sổ; query trên `authorizations` (decision) join actual outcome. Không cần dashboard mới — SQL aggregate đủ.
- **Stop criteria:** FALSE-ALLOW = 0 **và** FALSE-DENY = 0 trên N request thật / T ngày (N, T do Owner/CTO chốt — §9).

---

## 6. ENFORCEMENT PLAN

**Chuyển `shadow → enforcing` khi ĐỦ:**
1. Divergence = 0 (cả false-allow lẫn false-deny) suốt cửa sổ shadow.
2. QA execution plan (§7) pass toàn bộ.
3. **Owner approval** (Owner Gate riêng).

**Cơ chế flip:** UPDATE `mission_control_action_policies.lifecycle` `shadow → enforcing` (**data-only**, decision #5 — không dùng registry status, không đổi code). Commit-core đọc lifecycle → khi `enforcing`, `decision='deny'` chặn **trước** adapter dispatch, return `MC_ACTION_PERMISSION_DENIED`.

**Reversibility:** `enforcing → shadow` bất kỳ lúc nào (data-only, instant). Không destructive.

---

## 7. QA EXECUTION PLAN

**Authorization**
- ALLOW: `master_admin` school X + class∈X → allow. `super_admin` (is_admin) → allow bất kỳ school.
- DENY wrong-school: `master_admin` school X + class∈Y → `MC_POLICY_SCOPE_DENIED`.
- DENY wrong-role: `lead_teacher`/`assistant_teacher`/`primary_parent` → `MC_POLICY_ROLE_DENIED`.

**Context**
- `context.school_id ≠ object.school_id` → `MC_POLICY_CONTEXT_DENIED`.
- Malformed/extra key → chặn ở execute shape-gate (bất biến).

**Evidence**
- ALLOW recorded: row trong `authorizations` với decision=allow + policy_version + risk_level.
- DENY recorded: row với decision=deny + reason_code.
- Evidence table **client-deny-write** verify (direct client INSERT/UPDATE fail).

**Integrity (decision #7)**
- Client direct PATCH ledger `status/result_payload/completed_at` → **DENIED** (finish_own đã drop).
- Client direct call `_mc_commit_action` với forged result → result thực tế = server-derived (adapter thật) → **không forge được**.
- `evaluate_action_policy` direct call bởi authenticated → **DENIED** (internal-only ACL).

**Regression (frozen)**
- class.assign happy path **byte-identical**: INSERT `class_distributions`, audit `CLASS_ASSIGNMENT_CREATED`, result DTO, ledger transition, idempotent replay theo `request_id` — tất cả bất biến.
- `class.edit` **không** đổi (không seed policy, không govern) — vẫn reject ≠ class.assign như cũ.
- Memory (`get_mission_control_memory`) projection bất biến; authz decision **không** lọt vào Memory.
- Shadow phase: hành vi byte-identical, chỉ thêm evidence rows.

**Method (D2/D3):** impersonation harness — `set_config('request.jwt.claims', json_build_object('sub',uid,'role','authenticated'), true)` + `SET LOCAL ROLE authenticated`, `RESET ROLE` trong exception handler. Verify qua rollback-safe simulation (`DO $sim$ … RAISE EXCEPTION`), **KHÔNG** `apply_migration` khi verify. Enforcement flip → **real login** verify (6 demo pilot accounts, `Test@123`).

---

## 8. ROLLBACK PLAN

**Database rollback boundary (non-destructive — không drop business data):**
- **Tables:** `mission_control_action_policies`, `mission_control_action_authorizations` → DROP an toàn (chỉ chứa governance metadata/evidence, không phải business data). `policy_registry` doc row → DELETE.
- **Functions:** `evaluate_action_policy`, `_mc_commit_action` → DROP. `execute_mission_control_action` → **restore prior definition** (INVOKER, pre-B6.2 body).
- **ACL/RLS:** re-CREATE `finish_own` policy (khôi phục trạng thái ledger pre-B6.2); revert ACL grants.

**Behavior rollback (không cần migration):**
- Kill-switch tức thì: policy lifecycle → `disabled` (evaluate không chặn) hoặc `enforcing → shadow`. Data-only, instant.

**Nguyên tắc:** KHÔNG destructive rollback. Business data (`class_distributions`, `audit_logs`, ledger business rows) **không bao giờ** bị đụng trong rollback. Governance layer là additive → gỡ sạch được về pre-B6.2.

**Rollback theo phase:** mỗi phase §1 có rollback riêng, độc lập; phase sau rollback không phá phase trước.

---

## 9. OPEN CTO QUESTIONS

1. **[Awareness / confirm] Đường B — DEFINER commit-core granted `authenticated`.** Plan mặc định giữ `execute` INVOKER (tôn trọng frozen B6.1.5) + thêm `_mc_commit_action` DEFINER, granted authenticated (bắt buộc để INVOKER execute gọi được). Đây là **surface privileged mới** dù forge-proof by construction. CTO confirm chấp nhận đường B, hay muốn **đường A** (flip execute→DEFINER, đơn giản hơn nhưng **reopen frozen INVOKER invariant**)? — *Builder recommend B.*

2. **[Parameter] Shadow stop-criteria cụ thể:** N (số request thật) và T (số ngày) cho divergence-zero window? Pilot traffic thấp (2 school) → cần Owner/CTO ấn định ngưỡng thực tế thay vì để mở.

3. **[Confirm] Evidence persistence policy:** shadow ghi **mọi** decision (đề xuất, full observability). Enforcement: ghi deny luôn + allow cho MEDIUM+ (class.assign=MEDIUM → ghi). Confirm, hay ghi tất cả cả khi enforcing?

*(Không có architecture conflict tồn đọng. Đường B giải quyết decision #7 mà không đụng frozen invariant → không cần STOP. Ba mục trên là confirm/parameter, không chặn việc chuẩn bị migration khi được authorize apply.)*

---

**FINAL:** Plan-level, 0 code, 0 SQL, 0 apply, 0 canonical edit. Apply chờ Owner Gate riêng. Khi được authorize, migration tuân D92 three-block + D231 ACL re-harden + rollback-safe verify, sequencing DB-first, mỗi phase một migration để rollback boundary sạch.
