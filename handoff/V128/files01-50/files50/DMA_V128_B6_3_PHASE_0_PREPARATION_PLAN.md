# V128-B6.3 — PHASE 0 PREPARATION PLAN

> **Mode:** DESIGN → EXECUTION PREPARATION ONLY. **Không:** SQL apply · migration · DB mutation · FE · canonical append.
> **Authority:** CTO đã APPROVE B6.3 DESIGN. Scope khoá: G1 · G2 · G3. Out: class.edit executor · Decision layer · Memory expansion · FE.
> **Ngày:** 2026-08-15 (GMT+7).

---

## 0. CANONICAL BOOT (live-verified, không memory)

Boot: `DMA_RULES.md` → `DMA_SYSTEM_MAP.md` → `HANDOFF V128-B6.2-A2_CLOSEOUT` → live audit (D1).

| Trục | Giá trị | Trạng thái |
|---|---|---|
| RULES | **D360** | khớp |
| SYSTEM_MAP | **v1.48** | khớp |
| HANDOFF | **V128-B6.2-A2** | CLOSED |
| Inventory | **92 · 248 · 236 · 168 · 33 · 1** | khớp live |
| Migration tail | **`20260814114948`** | khớp |
| Live vs canonical | **ZERO DRIFT** | verified |

**6 invariant khoá (Phase 0 xác nhận, mọi phase B6.3 giữ):** (1) client không mutate terminal ledger · (2) commit boundary chỉ qua `mc_internal._mc_commit_action` · (3) `execute` = INVOKER · (4) commit-core = DEFINER completed-only · (5) `assign_class_distribution` FREEZE · (6) public execute contract (signature+envelope) BẤT BIẾN.

---

## 1. CURRENT FROZEN STATE (baseline snapshot — captured live)

### 1.1 Registry — `mission_control_action_registry`
- **Cột (11):** `id · object_type · action_key · label · capability · risk_level · audit_event · status(def 'active') · metadata jsonb(def '{}') · created_at · updated_at`.
- **Index:** PK(id) · **UNIQUE(object_type, action_key)** ← natural key cho `_mc_lookup_action`.
- **Rows (2 active):** `class.assign` (MEDIUM, `CLASS_ASSIGNMENT_CREATED`, metadata `{}`) · `class.edit` (LOW, `CLASS_UPDATED`, metadata `{}`).
- **Security:** RLS **ON** · **0 policy** · grants `{service_role:SELECT}` only · authenticated/anon = 0 access · **0 trigger**.
- **Nature:** DESCRIPTOR CATALOG. Đọc bởi discovery (DEFINER); KHÔNG tham chiếu bởi execute.

### 1.2 Execute — `execute_mission_control_action(p_action_key, p_object_id, p_context, p_input, p_request_id) → jsonb`
- **Posture:** plpgsql · **SECURITY INVOKER** · `search_path=''` · owner postgres · EXECUTE `{authenticated, postgres}` (routine grant confirm: `authenticated:EXECUTE`).
- **Gate order (literal — freeze cho equivalence):**
  | # | Điều kiện | Error code |
  |---|---|---|
  | G-1 | `auth.uid()` null | `MC_ACTION_PERMISSION_DENIED` |
  | G-2 | `current_profile()` null | `MC_ACTION_PERMISSION_DENIED` |
  | G-3 | `action_key ≠ 'class.assign'` | `MC_ACTION_NOT_FOUND` |
  | G-4 | `object_id` null ∨ `request_id` null | `MC_ACTION_INPUT_INVALID` |
  | G-5 | context không-object ∨ thiếu `school_id` ∨ có key thừa ∨ school_id không cast uuid | `MC_ACTION_CONTEXT_DENIED` |
  | G-6 | input không-object ∨ thiếu `program_id` ∨ key ∉{program_id,lead_teacher_id} ∨ không cast uuid ∨ program_id null | `MC_ACTION_INPUT_INVALID` |
  | G-7 | class→school lookup null | `MC_ACTION_OBJECT_NOT_FOUND` |
  | G-8 | `context.school_id ≠ class.school_id` | `MC_ACTION_CONTEXT_DENIED` |
- **Execution:** INSERT ledger `processing` `ON CONFLICT(request_id) DO NOTHING` → nếu inserted: `assign_class_distribution(object_id, program_id, lead_teacher_id)` → build success envelope → `mc_internal._mc_commit_action(request_id, result)`.
- **Adapter-exception map (β2, rollback-only):** `unique_violation`/`distribution_exists`→`MC_ACTION_CONFLICT` · `not_authorized_for_school`→`MC_ACTION_PERMISSION_DENIED` · `class_not_found`→`MC_ACTION_OBJECT_NOT_FOUND` · `subject_not_entitled`/`lead_teacher_invalid`→`MC_ACTION_INPUT_INVALID` · else→`MC_ACTION_EXECUTION_FAILED`.
- **Replay/conflict branch (conflict path):** existing not-found ∨ (action_key/object_type/object_id mismatch)→`MC_ACTION_REQUEST_CONFLICT` · existing status∈{received,processing}→`MC_ACTION_REQUEST_IN_PROGRESS` (`replayed=true`) · else→stored `result_payload` với `replayed=true`.
- **Envelope shapes (freeze):**
  - Success: `{ok:true, replayed:false, request_id, action_key:'class.assign', object_type:'class', object_id, result:{class_distribution_id}, audit:{event:'CLASS_ASSIGNMENT_CREATED', recorded:true}}`
  - Gate/early error: `{ok:false, replayed:false, error:{code:<CODE>}}`
  - Adapter failure: `{ok:false, replayed:false, request_id, action_key:'class.assign', object_type:'class', object_id, error:{code:<CODE>}}`
  - Replay: stored success envelope với `replayed=true`.

### 1.3 Ledger — `mission_control_action_requests`
- **Cột (12):** `id · request_id · action_key · object_type · object_id · status · result_payload · error_code · actor_id · created_at · started_at · completed_at`. **Không `intent_fingerprint`.**
- **Index:** PK(id) · **UNIQUE(request_id)** ← idempotency backbone · `actor_id_idx`.
- **Constraint (freeze):** `status_check`∈{received,processing,completed,failed} · `lifecycle_check` (processing→terminal-null; completed→result NOT NULL/error NULL/completed_at NOT NULL; failed→result+error+completed_at NOT NULL) · FK `actor_id→profiles ON DELETE SET NULL`.
- **RLS (2):** `insert_own_processing` (INSERT authenticated, own∧processing∧terminal-null) · `select_own` (SELECT authenticated own). `finish_own` **DROPPED (A1)**. **0 trigger.**
- **Grants:** authenticated INSERT+SELECT mọi cột, **0 UPDATE** → terminal forge chặn grant-layer (D360 QA-3: `42501`).

### 1.4 Adapter — `assign_class_distribution(p_class_id, p_program_id, p_lead_teacher_id DEFAULT NULL) → uuid` (FREEZE)
- DEFINER · owner postgres · EXECUTE `{authenticated, postgres, service_role}`. Shared: MC execution + School Portal direct.
- **Authz nội bộ:** `is_admin ∨ (role∈{master_admin,sub_admin} ∧ school∈user_school_ids)` → `has_subject_entitlement` → `dma_assignable_teacher_reason` → active-dup guard → INSERT `class_distributions` → `write_audit_log('CLASS_ASSIGNMENT_CREATED', …)`.
- **Domain errors (freeze):** `class_not_found · not_authorized_for_school · subject_not_entitled · lead_teacher_invalid · distribution_exists`.

### 1.5 Commit boundary — `mc_internal._mc_commit_action(request_id, result_payload) → void` (FREEZE)
- DEFINER · owner postgres · `search_path=''` · EXECUTE `{authenticated, postgres}` · schema `mc_internal` USAGE `{authenticated, postgres}`, unexposed PostgREST. Completed-only; derive actor; `FOR UPDATE`; validate processing∧owner. **B6.3 KHÔNG chạm.**

---

## 2. BASELINE CHECKLIST (read-only capture protocol — RE-RUN tại Phase 1 entry)

> Chạy **ngay trước** khi apply Phase 1 (D1 — re-audit tại thời điểm mutate, không tin snapshot cached). Mọi giá trị phải khớp §1; lệch bất kỳ = **STOP**, không apply.

| # | Capture | Nguồn | Expected (khớp §1) |
|---|---|---|---|
| C1 | Inventory re-pin | `pg_tables/pg_proc/pg_policies/pg_trigger` + `schema_migrations` | `92·248·236·168·33·1` · tail `20260814114948` |
| C2 | Registry schema+rows+RLS+grants | `information_schema.columns` · registry table · `pg_policies` · `role_table_grants` | 11 cột · 2 active · RLS ON · 0 policy · `{service_role:SELECT}` |
| C3 | Registry natural key | `pg_indexes` | UNIQUE(object_type, action_key) present |
| C4 | Execute posture+grants+body | `pg_proc.prosecdef/proconfig` · `pg_get_functiondef` · `role_routine_grants` | INVOKER · `search_path=''` · `{authenticated,postgres}` · body == §1.2 |
| C5 | Ledger cols+constraints+indexes+policies+grants | `information_schema` · `pg_constraint` · `pg_indexes` · `pg_policies` · `role_column_grants` | 12 cột (no fingerprint) · UNIQUE(request_id) · lifecycle_check · 2 policy · authenticated 0 UPDATE |
| C6 | Commit-core posture+ACL | `pg_proc` (mc_internal) · `aclexplode` | DEFINER completed-only · EXECUTE `{authenticated,postgres}` · schema USAGE `{authenticated,postgres}` |
| C7 | Adapter signature+security+grants | `pg_proc` · `aclexplode` | `(uuid,uuid,uuid DEFAULT NULL)` DEFINER owner postgres · `{authenticated,postgres,service_role}` |
| C8 | Discovery predicate | `pg_get_functiondef(get_available_actions)` | reads registry `status='active'` by object_type (advertises class.assign+class.edit) |
| C9 | Object registry (class) | `mission_control_object_registry` | class = kind `core`, projector_status `wired` |

**Acceptance của checklist:** 9/9 khớp → Phase 1 apply được. Bất kỳ lệch → STOP + reconcile trước.

---

## 3. PHASE 1 ENTRY CRITERIA (Registry Authority Foundation)

**Transition:** registry `descriptor` → `authority source`. Phase 1 nội dung (thiết kế, chưa apply): thêm cột authority ADDITIVE nullable (`adapter_key · execution_mode · required_context · input_schema · disabled_reason`) · populate `class.assign` (contract reproduce gate §1.2) · set `class.edit.adapter_key=NULL` (registered, non-dispatchable) · tạo `_mc_lookup_action(object_type,action_key)` DEFINER · đổi discovery predicate → `is_dispatchable`.

| # | Acceptance criterion | Verifiable bằng |
|---|---|---|
| A1 | `class.assign` VẪN executable (chưa cutover execute; discovery vẫn trả class.assign) | discovery returns class.assign; execute path unchanged |
| A2 | `class.edit` KHÔNG còn được discovery quảng bá như executable | `get_available_actions(class,…)` KHÔNG chứa class.edit |
| A3 | **No public contract change** — execute signature+envelope BẤT BIẾN | `pg_get_function_arguments` unchanged; execute body chưa đụng (Phase 1 chỉ registry+discovery+helper) |
| A4 | **No ledger behavior change** — cột/constraint/policy/grant ledger nguyên | C5 re-capture == §1.3 |
| A5 | **No commit boundary change** — commit-core nguyên | C6 re-capture == §1.5 |
| A6 | **Rollback possible** — mọi thêm là ADDITIVE, reversible | §5 P1 rollback verified dry (design) |
| A7 | Registry write vẫn privileged-only (cột mới không nới grant) | `role_table_grants` == `{service_role:SELECT}` |
| A8 | `_mc_lookup_action` = DEFINER, internal ACL `{authenticated,postgres}`, trả authority CHỈ cho dispatchable row | ACL check + functional check (class.assign→row, class.edit→not-dispatchable) |

**Ràng buộc:** Phase 1 **KHÔNG** chạm `execute` body (cutover là Phase 2). Discovery đổi predicate nhưng execute vẫn literal-dispatch → trong khoảng P1→P2, execute và discovery TẠM đồng thuận (cả hai chỉ class.assign) qua hai đường khác nhau; G1 đóng hình thức tại discovery, đóng thực thi tại P2.

---

## 4. PHASE 2 EQUIVALENCE MATRIX (thiết kế — KHÔNG chạy ở Phase 0)

> Chạy tại **Phase 2 entry**: capture baseline output (literal-dispatch execute) rồi diff với registry-driven execute. Cùng input ⇒ **byte-identical** envelope + cùng side-effect (ledger/distribution/audit) + cùng ledger terminal state. Method: **JWT-impersonation real-login** (actor master.demo, master_admin @ Trường Demo Dế Mèn, D2/D360), mỗi case trong `BEGIN…ROLLBACK` để zero net side-effect khi capture baseline.

| Case | Precondition / Input | Expected code | Expected envelope + side-effect (freeze) |
|---|---|---|---|
| **E1 Success** | fixture (class, program) chưa assign; input `{program_id, lead_teacher_id?}`; context `{school_id}` khớp | — (`ok:true`) | success envelope §1.2; ledger→`completed` server-side; +1 distribution; +1 audit `CLASS_ASSIGNMENT_CREATED` |
| **E2 Permission — no auth** | `auth.uid()` null | `MC_ACTION_PERMISSION_DENIED` | `{ok:false,replayed:false,error:{code}}`; 0 side-effect |
| **E2b Permission — adapter authz** | actor không quyền school | `MC_ACTION_PERMISSION_DENIED` | adapter `not_authorized_for_school`→map; β2 rollback; 0 side-effect, no orphan |
| **E3 Context denied — bad shape** | context thiếu/ thừa key ∨ school_id sai kiểu | `MC_ACTION_CONTEXT_DENIED` | early return; 0 side-effect |
| **E3b Context denied — mismatch** | context.school_id ≠ class.school_id | `MC_ACTION_CONTEXT_DENIED` | early return; 0 side-effect |
| **E4 Invalid input** | input thiếu program_id ∨ key thừa ∨ không cast | `MC_ACTION_INPUT_INVALID` | early return; 0 side-effect |
| **E5 Not found — action** | action_key ≠ 'class.assign' (registry-driven: không dispatchable) | `MC_ACTION_NOT_FOUND` | early return; 0 side-effect *(registry-driven phải reproduce literal outcome)* |
| **E6 Object not found** | object_id không tồn tại class | `MC_ACTION_OBJECT_NOT_FOUND` | early return; 0 side-effect |
| **E7 Duplicate (replay)** | same request_id, same intent, sau E1 | `ok:true, replayed:true` | stored result envelope; **Δ side-effect = 0** (QA-1 pattern) |
| **E8 In-progress** | same request_id còn `processing` | `MC_ACTION_REQUEST_IN_PROGRESS` | `replayed:true`; 0 mutation |
| **E9 Conflict (rollback-only)** | new request_id, distribution đã tồn tại | `MC_ACTION_CONFLICT` | β2 rollback; ledger row cho request = 0; no duplicate; no audit (QA-2 pattern) |
| **E10 Audit event** | E1 success | — | audit `CLASS_ASSIGNMENT_CREATED` present, actor+program+class metadata; append-only |

**Equivalence acceptance:** mọi case E1–E10 output (code + envelope + side-effect + ledger terminal state) **identical** giữa literal-dispatch baseline và registry-driven. Lệch bất kỳ = cutover FAIL, giữ literal body.

**Fixture note (Phase 2, không seed ở Phase 0):** E7/E9 dùng được fixture persisted B6.2-A2 (class `eeeeeeee-…0005`, program `…00a5`, entitlement `…00e5`, distribution `2a40a52f…` active). E1 (fresh success) cần một cặp (class, program) CHƯA assign — chuẩn bị fixture riêng tại Phase 2 entry.

---

## 5. ROLLBACK STRATEGY

Mỗi phase = migration D92 3-block (DDL → REVOKE/GRANT re-harden → VERIFY rollback-guard); mỗi rollback là migration ngược riêng, Owner Gate.

### Phase 1 — Registry Authority Foundation
- **Data rollback:** UPDATE registry set cột authority = NULL (hoặc DROP COLUMN nếu ADDITIVE thuần) — reverse populate class.assign/class.edit.
- **Helper removal:** `DROP FUNCTION _mc_lookup_action(text,text)`.
- **Discovery revert:** `CREATE OR REPLACE get_available_actions` về body §1.2 (predicate `status='active'`), re-harden ACL.
- **An toàn:** execute CHƯA wired vào registry → ledger/adapter/commit 0 ảnh hưởng. `NOTIFY pgrst`.

### Phase 2 — Adapter Resolver Cutover
- **Execute restore:** `CREATE OR REPLACE execute_mission_control_action` về **B6.2 frozen body** (§1.2, single function replace).
- **Grants restore:** re-harden `REVOKE…GRANT EXECUTE {authenticated,postgres}` (D15/D231/D359 — proacl reset on replace).
- **No ledger repair:** ledger/commit-core/adapter không đụng ở P2 → **0 data repair**. `NOTIFY pgrst`.
- **Trigger:** rollback nếu equivalence matrix (§4) fail bất kỳ case.

### Phase 3 — Intent Integrity
- **Column revert:** `DROP COLUMN intent_fingerprint` (ADDITIVE nullable → drop sạch; legacy rows chưa dùng).
- **Replay branch revert:** `CREATE OR REPLACE execute` về replay-branch structural-only (P2 body).
- **No ledger repair:** fingerprint chỉ discriminator, không đổi terminal state semantics → 0 data repair.

**Nguyên tắc chung:** mọi thay đổi B6.3 là ADDITIVE + function-replace → rollback = drop-additive + replace-back, **không có data-migration ngược**. Ledger terminal contract (A1/D359) không bị B6.3 chạm ở bất kỳ phase nào.

---

## 6. RISKS

1. **Drift giữa Phase 0 capture và Phase 1 apply.** Mitigate: checklist §2 re-run bắt buộc tại P1 entry; lệch = STOP.
2. **Discovery contract change (A2) ảnh hưởng FE.** class.edit biến khỏi menu. Xác nhận FE không hard-depend class.edit hiện diện TRƯỚC P1. (class.edit vốn không execute được → 0 functional loss, nhưng UI có thể render nút chết — nếu có, đây đúng là D290 "cửa dẫn tới not_authorized = bug", đóng luôn.)
3. **Equivalence gap ẩn (P2).** Literal body có nhánh tinh vi (cast-exception → CONTEXT_DENIED/INPUT_INVALID; extra-key rejection). Matrix §4 phải phủ cả các nhánh cast/extra-key, không chỉ happy-path. Mitigate: E3/E4 gồm sub-case bad-cast + extra-key.
4. **Baseline capture side-effect.** Capture E1/E7/E9 tạo distribution/ledger. Mitigate: `BEGIN…ROLLBACK` per case (net-zero) HOẶC dùng fixture demo school (không phải khách thật) + cleanup Owner Gate.
5. **Registry read path cho execute (P2).** execute INVOKER không SELECT registry được → phụ thuộc `_mc_lookup_action` DEFINER. Nếu helper sai/ chậm → execute fail. Mitigate: helper STABLE, verify trong P1 acceptance (A8) trước khi P2 dùng.
6. **Legacy NULL-fingerprint replay (P3).** Row trước-B6.3 fingerprint NULL. Mitigate: fallback structural cho NULL-fingerprint, test riêng.

---

## 7. RECOMMENDATION

**★ Khuyến nghị DUYỆT Phase 0 và cho phép Phase 1 sau khi checklist §2 PASS 9/9 tại apply-time.**

Chốt:
- Baseline §1 = frozen reference; checklist §2 = gate re-run bắt buộc (D1) ngay trước P1.
- Phase 1 thuần ADDITIVE + không chạm execute body → rollback rẻ, risk thấp; điều kiện then chốt = A8 (`_mc_lookup_action` đúng) vì P2 phụ thuộc nó.
- Phase 2 = gate cứng sau **equivalence matrix §4 PASS toàn bộ E1–E10** (gồm sub-case cast/extra-key/replay/conflict). Không PASS = giữ literal body.
- Tách P2 (cutover behavior-identical) và P3 (intent) — equivalence proof sạch trước, intent enforcement sau.
- Trước P1: xác nhận FE không hard-depend class.edit (risk #2).

**Đề xuất thứ tự Owner Gate:** Phase 0 (gate này) → [FE class.edit check] → Phase 1 → Phase 2 (sau equivalence) → Phase 3 → canonical append (gate riêng).

**Không có trong Phase 0:** SQL apply · migration · mutation · canonical append. Baseline capture (§4) chạy ở Phase 2, KHÔNG ở Phase 0.

---

## DESIGN READY FOR CTO APPROVAL
