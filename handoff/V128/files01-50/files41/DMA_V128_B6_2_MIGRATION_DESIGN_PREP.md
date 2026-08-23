# V128-B6.2 — MIGRATION DESIGN PREPARATION

> **Milestone:** V128-B6.2 · ACTION GOVERNANCE HARDENING
> **Vai trò:** Builder (Claude) · **Authority:** Owner (Jean) · CTO/CPO (ChatGPT)
> **Trạng thái:** Architecture ✅ · Implementation Plan ✅ · Migration Design Prep ➡️ THIS DOC
> **Ràng buộc:** MIGRATION DESIGN ONLY — KHÔNG SQL final · KHÔNG apply · KHÔNG mutate · KHÔNG canonical · KHÔNG bump version · KHÔNG mở scope.
> **Grounding:** live read-only audit trong phiên (tail `20260813113400`, inv 92/248/236/169). Ngày 2026-08-14 (GMT+7).

**Frozen (đã hấp thụ):** PATH B (execute giữ INVOKER + `_mc_commit_action` DEFINER, result server-derived) · govern chỉ `class.assign` · capability dormant (không gate) · HIGH/CRITICAL declared-only · policy lifecycle `shadow/enforcing/disabled` riêng · evidence = `mission_control_action_authorizations`.

**Grounded ownership (quyết định cho §7):** mọi function/table liên quan **owned by `postgres`**; các DEFINER helper (`is_admin`, `current_profile`, `current_profile_role`, `user_school_ids`, `assign_class_distribution`, `write_audit_log`) đều `postgres` + `search_path=''`; `execute` = INVOKER. **Không tồn tại schema private** — chỉ public + schema hệ thống Supabase.

---

## 1. MIGRATION STRATEGY OVERVIEW

**Vì sao thứ tự này:**
1. **Additive-dormant trước, live-path sau.** M1 (schema) + M2 (evaluator) thuần additive, zero runtime — không ai đọc/gọi → rủi ro ~0, apply/rollback tự do.
2. **Integrity (M3) TRƯỚC shadow (M4).** Shadow ghi evidence vào bảng client-deny-write → cần trusted DEFINER writer (`_mc_commit_action`) tồn tại trước. Dựng commit-core = chính cơ chế integrity. Nếu shadow trước integrity → hở cửa sổ client-write vào evidence. Đây là ràng buộc dependency cứng.
3. **Enforcement (M5) = data-only flip** cuối cùng, sau khi shadow chứng minh divergence=0.

**Safety boundary (bất biến qua mọi migration):**
- Business data (`class_distributions`, `audit_logs`, ledger business rows) **KHÔNG bao giờ** bị mutate/drop.
- Mỗi phase = **1 migration** → rollback checkpoint sạch, độc lập.
- Mỗi migration tuân **D92 three-block**: CREATE/REPLACE → REVOKE/GRANT re-harden (D231) → VERIFY (rollback-safe simulation, `DO $sim$ … RAISE EXCEPTION`).
- **Verify KHÔNG dùng `apply_migration`** — chỉ rollback-safe simulation. `apply_migration` wrap 1 transaction → `RAISE EXCEPTION` = full atomic rollback.
- Governance layer 100% additive → gỡ sạch về pre-B6.2 bất kỳ lúc nào.

---

## 2. MIGRATION SEQUENCE

### Migration 0 — Precondition Audit (read-only)
- **Objective:** Re-confirm live TRƯỚC mọi write (D1); không tin snapshot phiên trước.
- **Verify:** tail `20260813113400` · inv 92/248/236/169 · `execute_mission_control_action` INVOKER + signature nguyên · 3 ledger policy (`insert_own_processing`/`finish_own`/`select_own`) predicate khớp audit · registry 2 rows · ACL các helper · `assign_class_distribution` DEFINER/postgres.
- **Touched:** none. **Runtime wiring:** none.
- **Nếu drift:** STOP → báo Owner. Không tiến M1.

### Migration 1 — Governance Schema Foundation (additive, dormant)
- **CREATE tables:** `mission_control_action_policies` · `mission_control_action_authorizations`.
- **CREATE index:** authorizations `(request_id)` + `(action_key, created_at)`; policies unique `(action_key)`.
- **CREATE RLS:** policies → SELECT admin-only, deny client-write. authorizations → SELECT admin-only, deny client-write. (Không có INSERT/UPDATE policy cho client trên cả hai.)
- **SEED:** đúng **1 row** `mission_control_action_policies` = `class.assign` (scope=`tenant`, min_role={master_admin,sub_admin}, risk_requirement derived từ registry MEDIUM, policy_version=`b6.2-v1`, lifecycle=`shadow`, evaluator=`evaluate_action_policy`, required_capability=NULL dormant). **KHÔNG seed `class.edit`.**
- **CREATE row:** 1 documentation row trong `policy_registry` (`mission_control_action_governance`, defined_in=`evaluate_action_policy + mission_control_action_policies`, admin_editable=false).
- **Runtime wiring:** none — chưa function/execute nào đọc.
- **PostgREST:** `notify pgrst reload` để admin SELECT được (nếu FE admin cần đọc); nếu không, bỏ qua.

### Migration 2 — Governance Evaluator (dormant)
- **CREATE:** `evaluate_action_policy(p_actor_id uuid, p_action_key text, p_object_type text, p_object_id uuid, p_context jsonb, p_input jsonb) RETURNS jsonb`.
  - **Security:** DEFINER · **owner:** postgres · `search_path=''`.
  - **ACL:** REVOKE ALL FROM PUBLIC, anon, authenticated → **internal-only** (chỉ owner + commit-core reachable). *(Xem §7 về cơ chế reachable.)*
  - **Input:** actor được caller (commit-core) truyền từ `current_profile()`; evaluate không tự nhận từ client raw.
  - **Output:** `ActionPolicyDecision/v1` — `{decision, policy_version, reason_code, risk_level, risk_requirement, evaluated{role_ok,scope_ok,context_ok,platform_override}}`.
  - **Failure:** deny = return-value (fail-closed). RAISE chỉ khi config vỡ (policy thiếu cho action `active` → `MC_POLICY_UNDEFINED`). **Không** capability gate (frozen).
- **Runtime wiring:** none — execute chưa gọi.

### Migration 3 — Execution Integrity (MOST SENSITIVE)
- **CREATE:** `_mc_commit_action(...)` — DEFINER · owner postgres · `search_path=''` · **result server-derived** (không nhận `result_payload`/`status` từ caller). Trách nhiệm: derive actor nội bộ (`current_profile()`) → (M3 giai đoạn này chưa gọi evaluate — chỉ chuyển finalize) → gọi `assign_class_distribution` → build result server-side → finalize ledger (UPDATE completed/failed, bypass RLS as postgres). *(evaluate/evidence wiring để M4.)*
- **REPLACE:** `execute_mission_control_action` — **GIỮ INVOKER + signature + ACL**. Giữ toàn bộ gate (auth/shape/context/cross-tenant) + **pristine INSERT** (client-create qua `insert_own_processing`) + idempotency/replay detection **nguyên trạng**; chỉ **delegate** phần adapter-call+finalize sang `_mc_commit_action(v_request_pk, …)` cho nhánh new-execution.
- **DROP policy:** `mission_control_action_requests_finish_own` (client mất quyền finalize).
- **KEEP:** `insert_own_processing` (client-create) · `select_own` (client đọc status).
- **ACL re-harden (D231):** sau mỗi CREATE OR REPLACE, Supabase auto-grant anon/authenticated → REVOKE lại tường minh cho các surface internal; GRANT EXECUTE `_mc_commit_action` cho `authenticated` (bắt buộc — INVOKER execute gọi dưới role client). *(§7: cơ chế để grant này KHÔNG tạo public RPC.)*
- **Behavior invariant:** `class.assign` **byte-identical** — cùng INSERT `class_distributions`, cùng audit `CLASS_ASSIGNMENT_CREATED`, cùng result DTO, cùng ledger transition, cùng idempotent replay.

**Vì sao frozen INVOKER invariant vẫn an toàn:**
`execute` **không đổi** security mode (vẫn INVOKER), signature, ACL, hay client-callability → B6.1.5 invariant nguyên vẹn. Cái thay đổi là **ai ghi ledger finalize**: trước đây client (qua `finish_own` RLS), giờ là `_mc_commit_action` DEFINER. execute vẫn là INVOKER entry point; nó chỉ *delegate* privileged-write xuống một DEFINER core. Vì `auth.uid()` **bất biến** qua ranh giới DEFINER (DEFINER đổi *executing role*, không đổi *JWT identity*), mọi authz downstream (evaluate + adapter) vẫn key theo đúng client. → INVOKER giữ nguyên mà vẫn đóng được forge.

### Migration 4 — Shadow Governance (behavior-identical)
- **REPLACE:** `_mc_commit_action` — thêm: gọi `evaluate_action_policy(actor,…)` → ghi decision + **actual authz outcome** vào `mission_control_action_authorizations` (as postgres, bypass RLS) → **KHÔNG branch** trên decision. Policy lifecycle=`shadow`.
- **Behavior invariant:** class.assign byte-identical; chỉ thêm evidence rows.
- **Runtime wiring:** evaluate giờ live-đọc nhưng inert (không ảnh hưởng verdict).

### Migration 5 — Enforcement Readiness (data-only, Owner Gate)
- **REPLACE (nếu chưa có branch từ M4):** `_mc_commit_action` đọc `lifecycle`; khi `enforcing` + `decision='deny'` → finalize failed(`MC_ACTION_PERMISSION_DENIED`) + record deny evidence + **KHÔNG** gọi adapter.
- **FLIP:** UPDATE `mission_control_action_policies.lifecycle` `shadow → enforcing` — **data-only**, không đổi code.
- **Gate:** divergence=0 + QA pass + **Owner approval**.
- **Adapter inner-authz giữ nguyên** (backstop).

---

## 3. OBJECT TOUCH MATRIX

| Object | CREATE | REPLACE | ALTER | ACL/RLS | Risk |
|---|---|---|---|---|---|
| `mission_control_action_policies` (table) | M1 | — | — | RLS SELECT admin; deny client-write (M1) | LOW |
| `mission_control_action_authorizations` (table) | M1 | — | — | RLS SELECT admin; deny client-write (M1) | LOW |
| idx authorizations `(request_id)`,`(action_key,created_at)` | M1 | — | — | — | LOW |
| `policy_registry` (doc row, data) | M1 (INSERT row) | — | — | (bảng đã có RLS admin) | LOW |
| `evaluate_action_policy()` | M2 | — | — | REVOKE anon/auth → internal-only (M2) | LOW |
| `_mc_commit_action()` | M3 | M4, M5 | — | GRANT EXECUTE authenticated; internal (M3) | MEDIUM |
| `execute_mission_control_action()` | — | M3 | — | GIỮ INVOKER + ACL nguyên; re-harden sau REPLACE | **HIGH** |
| `mission_control_action_requests` RLS | — | — | DROP `finish_own` (M3) | keep `insert_own_processing`+`select_own` | MEDIUM |
| `assign_class_distribution()` | — | — | — | **KHÔNG chạm** | — |
| `mission_control_action_registry` | — | — | — | **KHÔNG chạm** (risk_level authoritative ở đây) | — |
| `audit_logs` / `class_distributions` | — | — | — | **KHÔNG chạm** | — |
| `mission_control_action_policies.lifecycle` (data) | — | — | UPDATE shadow→enforcing (M5) | data-only | MEDIUM |

*(Không table/schema nào bị ALTER cấu trúc; ledger schema bất biến — chỉ đổi RLS. "Không redesign ledger" đảm bảo.)*

---

## 4. DEPENDENCY GRAPH

```
M0 precondition audit
   │ (clean baseline — blocker nếu drift)
   ▼
M1 policy + authorizations tables + seed class.assign + doc row
   │ (evaluate đọc mission_control_action_policies → phải có trước)
   ▼
M2 evaluate_action_policy()          [dormant]
   │ (commit-core sẽ gọi evaluate + ghi authorizations → cả hai phải có trước)
   ▼
M3 _mc_commit_action() + execute delegate + DROP finish_own   [integrity]
   │ (trusted DEFINER writer phải tồn tại trước khi shadow ghi evidence)
   ▼
M4 shadow wiring (evaluate + evidence, no branch)
   │ (divergence=0 phải chứng minh trước khi enforce)
   ▼
M5 enforcing (data-only flip)         [Owner Gate]
```

**Blockers tường minh:**
- M1→M2: evaluate không thể tồn tại có nghĩa nếu bảng policy chưa có (đọc `mission_control_action_policies`).
- M2→M3: commit-core cần evaluate + authorizations table sẵn để wire ở M4; M3 dựng writer.
- M3→M4: **cứng** — evidence client-deny-write chỉ ghi được qua DEFINER commit-core; shadow-trước-integrity = lỗ hổng.
- M4→M5: enforcement chỉ mở sau divergence=0 (false-allow=0 ∧ false-deny=0) + Owner Gate.

---

## 5. VERIFICATION DESIGN

*(Mọi verify = rollback-safe simulation trong `DO $sim$ … RAISE EXCEPTION` cuối; KHÔNG `apply_migration` khi verify.)*

### M1 — Schema Foundation
- **Structural:** 2 bảng tồn tại (`to_regclass`); cột đúng shape; index hiện diện; RLS ON; policy SELECT admin tồn tại, **không** policy INSERT/UPDATE client. Seed: đúng **1 row** policies (`action_key='class.assign'`), **0 row** cho class.edit. Doc row `policy_registry` hiện diện.
- **Behavioral:** none (dormant) — assert execute path **không đổi** (smoke class.assign vẫn chạy như cũ).
- **Security:** impersonate authenticated non-admin → SELECT/INSERT/UPDATE 2 bảng mới đều **denied**.

### M2 — Evaluator
- **Structural:** `to_regprocedure('public.evaluate_action_policy(uuid,text,text,uuid,jsonb,jsonb)')` NOT NULL; `prosecdef=true`; `proowner`=postgres; `proconfig IS NOT DISTINCT FROM ARRAY['search_path=""']`; ACL qua `aclexplode(coalesce(proacl,acldefault('f',proowner)))` → **không** anon/authenticated EXECUTE.
- **Behavioral:** gọi evaluate (từ owner ctx) với fixtures: admin→allow; wrong-role→deny ROLE; wrong-school→deny SCOPE; context-mismatch→deny CONTEXT; policy-missing→raise UNDEFINED. **Không** capability branch.
- **Security:** impersonate authenticated → direct call evaluate → **permission denied** (internal-only).

### M3 — Execution Integrity
- **Structural:** `execute` vẫn `prosecdef=false` (INVOKER), signature + ACL **bất biến**. `_mc_commit_action` DEFINER/postgres/`search_path=''`. `finish_own` **không còn** (`pg_policies` absence check). `insert_own_processing` + `select_own` **còn**.
- **Behavioral (byte-identical — bắt buộc):** rollback-safe sim với impersonation master_admin: run class.assign → assert INSERT `class_distributions` (1 row) · audit `CLASS_ASSIGNMENT_CREATED` ghi · result DTO khớp cũ · ledger `processing→completed` · idempotent replay cùng `request_id` trả replayed đúng. Fail path (wrong-school) → `MC_ACTION_PERMISSION_DENIED` + ledger `failed` như cũ.
- **Security:** impersonate authenticated → direct UPDATE ledger set `status='completed',result_payload=forged` → **DENIED** (finish_own gone). Direct call `_mc_commit_action` với forged input → result thực = adapter-derived (không forge). evaluate vẫn internal-only.

### M4 — Shadow
- **Structural:** commit-core REPLACE giữ DEFINER/ACL; evaluate reachable từ commit-core.
- **Behavioral:** class.assign byte-identical (như M3) **cộng** đúng 1 evidence row/allow, 1/deny; decision **không** ảnh hưởng verdict (branch off). Divergence probe: false-allow=0, false-deny=0 trên fixtures (isolate authz outcome — loại business failures entitlement/dup/teacher).
- **Security:** evidence chỉ ghi bởi commit-core; client direct write authorizations → denied.

### M5 — Enforcement
- **Structural:** lifecycle=`enforcing` trên row class.assign (data check).
- **Behavioral:** deny fixtures → chặn **trước** adapter (không INSERT class_distributions), ledger `failed`, evidence deny. Allow fixtures → unchanged. Flip ngược `enforcing→shadow` khôi phục hành vi shadow.
- **Security:** cross-school + wrong-role thật (real login 6 demo accounts) → denied.

---

## 6. ROLLBACK CHECKPOINTS

*(Tất cả non-destructive; business data preserved; reversible.)*

| Migration | Rollback | Destructive? |
|---|---|---|
| M0 | n/a (read-only) | No |
| M1 | DROP 2 bảng mới + DELETE doc row `policy_registry`. Chưa business data. | No |
| M2 | DROP `evaluate_action_policy`. Chưa ai gọi. | No |
| M3 | **Restore prior `execute` definition** (INVOKER, pre-B6.2 body) + **re-CREATE `finish_own`** policy + DROP `_mc_commit_action`. Ledger về pre-B6.2. | No |
| M4 | REPLACE commit-core bỏ nhánh evaluate/evidence **hoặc** kill-switch lifecycle=`disabled` (data-only). Evidence rows đã ghi = giữ (audit, vô hại). | No |
| M5 | FLIP lifecycle `enforcing→shadow` (data-only, instant). | No |

**Nguyên tắc:** rollback phase sau **không** phá phase trước. `class_distributions`/`audit_logs`/ledger business rows **không bao giờ** bị đụng. Full teardown về pre-B6.2 = M3-restore + drop M2/M1 objects.

---

## 7. CRITICAL SECURITY REVIEW

### Câu hỏi: DEFINER privilege của commit-core có bypass domain authorization không?
**Trả lời: KHÔNG.** Guarantee dựa trên một invariant grounded:

> **SECURITY DEFINER escalate *executing role* (cho RLS/table-privilege), KHÔNG escalate *JWT identity* (`auth.uid()`).** `auth.uid()` bất biến xuyên suốt request bất kể bao nhiêu ranh giới DEFINER.

Grounded evidence (live audit): `is_admin()`, `current_profile()`, `current_profile_role()`, `user_school_ids()` đều là `select … where user_id = auth.uid()`. Chúng đọc identity từ JWT, không từ executing role.

**Ba lớp phòng thủ:**

**Lớp 1 — Policy (`evaluate_action_policy`):** decision tính từ `p_actor_id` = `current_profile()` (auth.uid-derived, do commit-core set nội bộ, **không** nhận từ client raw). Quyết định luôn theo đúng caller thật.

**Lớp 2 — Execution (`_mc_commit_action`, DEFINER/postgres):** privilege chỉ dùng để **bypass RLS ghi** ledger-finalize + evidence (trusted-writer). Nó **không** chế/nhận identity giả (actor derive nội bộ từ auth.uid) và **không** nhận result từ caller (server-derived từ adapter return). Privilege scoped vào ghi bảng governance/ledger, **không** vào việc "cho phép hành động".

**Lớp 3 — Adapter (`assign_class_distribution`, DEFINER/postgres) — backstop:** predicate `is_admin() OR (current_profile_role() IN ('master_admin','sub_admin') AND school ∈ user_school_ids())` — tất cả đọc `auth.uid()`. Dù bị gọi từ commit-core DEFINER owned-postgres, adapter vẫn authorize theo client thật. **Đây là lớp cuối:** kể cả policy/commit có bug, adapter vẫn chặn.

**Kết luận:** DEFINER có thể bypass row-level table access (đúng ý đồ: ghi ledger/evidence), nhưng **không thể** bypass identity-based domain authz vì mọi check key theo `auth.uid()` — thứ DEFINER không đổi được.

### Constraint "commit-core không phải public API / không expose FE"
**Vấn đề grounded:** PATH B + `execute` INVOKER ⇒ `authenticated` **bắt buộc** có EXECUTE trên `_mc_commit_action` (để INVOKER execute gọi được). Live audit: DMA **không có schema private** — mọi thứ trong `public`. Function `public` + grant `authenticated` ⇒ **PostgREST phơi nó thành RPC endpoint** ⇒ vi phạm "không phải public API".

**★ Recommendation — dựng schema non-exposed `mc_internal`:**
- `CREATE SCHEMA mc_internal`; đặt `_mc_commit_action` (và có thể `evaluate_action_policy`) trong đó.
- `GRANT USAGE ON SCHEMA mc_internal TO authenticated` + `GRANT EXECUTE` trên commit-core → INVOKER execute (public) gọi fully-qualified `mc_internal._mc_commit_action(...)` được.
- PostgREST config Supabase mặc định chỉ expose `public` + `graphql_public` → **`mc_internal` KHÔNG thành RPC endpoint** ⇒ thoả "không phải public API / không expose FE" theo **đúng nghĩa đen**, dù authenticated có EXECUTE để gọi nội bộ.
- Điều kiện: **không** thêm `mc_internal` vào `PGRST_DB_SCHEMAS`. Verify config trước apply.

**Alternative (không chọn):** giữ commit-core trong `public` + convention `_` prefix + không wire FE. Đơn giản hơn (không schema mới) nhưng commit-core **vẫn** technically là PostgREST RPC (dù forge-proof + identity-safe) → **không** thoả nghĩa đen "không phải public API".

→ **CTO DECISION REQUIRED #1:** duyệt dựng schema `mc_internal` (pattern mới, DMA chưa có tiền lệ private-schema) để thoả literal constraint; hay chấp nhận alternative public+convention (forge-proof nhưng technically-exposed)? Builder recommend **mc_internal**.

---

## 8. MIGRATION RISK ASSESSMENT

| Migration | Risk | Rationale |
|---|---|---|
| M0 Precondition audit | **LOW** | Read-only; không mutate. |
| M1 Schema foundation | **LOW** | Thuần additive; dormant; deny-write RLS từ đầu; rollback = drop. |
| M2 Evaluator | **LOW** | Function mới, không trên live path; internal-only ACL; rollback = drop. |
| M3 Execution integrity | **HIGH** | Chạm `execute` (frozen) + live ledger RLS (drop finish_own) + dựng DEFINER writer. Đòi hỏi byte-identical proof + security proof trước apply. Rủi ro lớn nhất milestone. |
| M4 Shadow | **LOW–MEDIUM** | Additive observability; behavior byte-identical; nhưng REPLACE commit-core (live path) → cần re-verify identical. |
| M5 Enforcement | **MEDIUM** | Đổi verdict thật; nhưng data-only flip + reversible tức thì + gated bởi divergence=0 + Owner. |

**Điểm nóng:** M3. Đề xuất treat M3 như một apply-session riêng, có real-login regression (6 demo accounts) ngay sau, trước khi tiến M4.

---

## OPEN CTO ITEMS

1. **[DECISION REQUIRED]** Schema `mc_internal` cho commit-core (thoả "không public API" — recommend) vs public+convention. (§7)
2. **[Confirm]** `evaluate_action_policy` đặt cùng `mc_internal` (khuyến nghị, gom internal surface) hay giữ `public` internal-only-ACL?
3. **[Parameter]** Shadow stop-criteria: N request thật / T ngày cho divergence-zero (pilot traffic thấp).
4. **[Confirm]** `min_role_set` dùng `profile_role[]` (enum array, type-safe — recommend) hay `text[]`?

---

**FINAL:** Migration design only. 0 SQL final, 0 apply, 0 mutate, 0 canonical, 0 version bump. Khi được authorize apply: mỗi phase 1 migration, D92 three-block + D231 re-harden + rollback-safe verify, M3 tách session riêng + real-login regression. Một điểm chờ CTO chốt (§7 mc_internal) trước khi soạn migration SQL.
