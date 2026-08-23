# V128-B6.3 — ACTION CONTROL PLANE FOUNDATION · DESIGN REVIEW

> **Loại:** DESIGN ONLY · Builder = Claude · Gate = CTO (ChatGPT).
> **Không có trong package này:** migration · SQL apply · DB mutation · code/FE implementation · cleanup · canonical append.
> **Ngày:** 2026-08-15 (GMT+7).

---

## 0. CANONICAL STATE (booted live, không reconstruct từ memory)

**Boot đọc trực tiếp:** `DMA_RULES.md` → `DMA_SYSTEM_MAP.md` → `HANDOFF V128-B6.2-A2_CLOSEOUT` → audit live DB (D1).

| Trục | Giá trị (verified live) |
|---|---|
| RULES endpoint | **D360** |
| SYSTEM_MAP endpoint | **v1.48** |
| HANDOFF | **V128-B6.2-A2 — CLOSED** |
| Inventory (structural) | **92 tables · 248 fn · 236 SECDEF · 168 policies · 33 triggers · 1 cron** |
| Migration tail | **`20260814114948`** |
| FE main pin | `@lovable.dev/vite-tanstack-config = 2.8.5` |
| Live vs canonical | **ZERO DRIFT** — mọi contract khớp D358–D360 byte-nghĩa |

**B6.2 đã chứng minh runtime (D359/D360):** action execution · ledger finalization · replay safety · conflict handling · forge protection. **G4 (ledger forge) = CLOSED, runtime-proven.**

**4 invariant B6.2 (KHÓA — B6.3 không được vi phạm):**
1. Client KHÔNG mutate terminal ledger state.
2. Commit boundary CHỈ qua server-side commit core (`mc_internal._mc_commit_action`).
3. Replay phải deterministic.
4. Conflict phải rollback-only (β2 subtransaction).

**Invariant contract bổ sung (từ A1/D359, giữ nguyên):** `execute` = INVOKER · public contract (signature + envelope) BẤT BIẾN · `assign_class_distribution` definition + grants BẤT BIẾN · commit-core = DEFINER completed-only · `mc_internal` unexposed PostgREST.

---

## 1. CURRENT CONTRACT FREEZE (live audit — không sửa)

### 1.1 Action Registry — `public.mission_control_action_registry`

- **Cột (11):** `id · object_type · action_key · label · capability · risk_level · audit_event · status(def 'active') · metadata jsonb(def '{}') · created_at · updated_at`.
- **Row active (2):** `class.assign` (MEDIUM, audit `CLASS_ASSIGNMENT_CREATED`) · `class.edit` (LOW, audit `CLASS_UPDATED`). `metadata = {}` cả hai.
- **Security posture:** RLS **ON** · **0 policy** · table grant duy nhất `service_role:SELECT`. `authenticated`/`anon` **không** SELECT/INSERT/UPDATE. ⇒ registry write đã privileged-only (postgres/migration); registry read cho client CHỈ qua DEFINER (discovery).

**Bản chất hiện tại: registry = DESCRIPTOR CATALOG.**
- Được discovery (`get_available_actions`, DEFINER) đọc để quảng bá menu.
- **KHÔNG** được `execute` tham chiếu để dispatch.
- **KHÔNG** chứa binding tới executor (thiếu `adapter_key`), execution semantics, hay contract (`required_context`/`input_schema`).
→ Registry là *authority danh nghĩa* nhưng *không phải authority thực thi*.

### 1.2 Execute Contract — `public.execute_mission_control_action(p_action_key, p_object_id, p_context, p_input, p_request_id)`

- **Posture:** LANGUAGE plpgsql · **SECURITY INVOKER** · `search_path=''` · owner postgres · EXECUTE `{authenticated, postgres}`.
- **Gate order (literal, hardcoded):**
  1. `auth.uid()` null → `MC_ACTION_PERMISSION_DENIED`
  2. `current_profile()` null → `MC_ACTION_PERMISSION_DENIED`
  3. **`if p_action_key is distinct from 'class.assign' → MC_ACTION_NOT_FOUND`** ← literal dispatch
  4. null object/request → `MC_ACTION_INPUT_INVALID`
  5. context phải là object CHỈ chứa key `school_id` (else `MC_ACTION_CONTEXT_DENIED`) ← hardcoded contract
  6. input phải có `program_id` (+optional `lead_teacher_id`, cấm key khác, else `MC_ACTION_INPUT_INVALID`) ← hardcoded contract
  7. class→school lookup (`MC_ACTION_OBJECT_NOT_FOUND`)
  8. `context.school_id ≠ class.school_id` → `MC_ACTION_CONTEXT_DENIED`
- **Execution:** INSERT ledger `processing` `ON CONFLICT (request_id) DO NOTHING` → nếu inserted: gọi **hardcoded `assign_class_distribution(...)`** → build result envelope → `mc_internal._mc_commit_action(request_id, result)`.
- **Failure model (β2):** INSERT-processing + adapter + commit-core trong 1 subtransaction `BEGIN…EXCEPTION`. Domain exception → map `MC_ACTION_*`; adapter fail → rollback-only (no orphan, no `failed` persist) → `{ok:false, error_code}` graceful.
- **Replay/conflict branch (khi conflict DO NOTHING):** đọc existing → so **CHỈ** `action_key + object_type + object_id` → mismatch → `MC_ACTION_REQUEST_CONFLICT`; in-flight → `MC_ACTION_REQUEST_IN_PROGRESS`; else replay stored `result_payload` (`replayed=true`).

**→ LITERAL DISPATCH DEPENDENCY xác nhận:** cả *authority check* (bước 3) lẫn *executor selection* (`assign_class_distribution`) đều là literal hardcode. Registry không tham gia đường thực thi.

### 1.3 Ledger Contract — `public.mission_control_action_requests`

- **Cột (12):** `id · request_id · action_key · object_type · object_id · status · result_payload · error_code · actor_id · created_at · started_at · completed_at`. **Không có `intent_fingerprint`.**
- **Constraint (KHÓA — không đổi):** PK(id) · **UNIQUE(request_id)** (xương sống idempotency) · `status_check` ∈ {received,processing,completed,failed} · `lifecycle_check` (received/processing→all-null; completed→result NOT NULL, error NULL, completed_at NOT NULL; failed→result+error+completed_at NOT NULL) · FK `actor_id→profiles ON DELETE SET NULL`.
- **RLS (2 policy):** `insert_own_processing` (INSERT, `authenticated`, CHECK own∧processing∧terminal-null) · `select_own` (SELECT, `authenticated`, own). **`finish_own` đã DROP (A1).**
- **Column grants:** `authenticated` có INSERT+SELECT mọi cột, **0 UPDATE** → terminal forge chặn ở **grant layer** (D360 QA-3: `42501`).

**Điểm có thể mở rộng = INTENT INTEGRITY.** Idempotency hiện dựa DUY NHẤT trên `request_id` (UNIQUE). Không có ràng buộc "cùng request_id ⇒ cùng intent". Cùng `request_id` + input/context/actor KHÁC → replay-branch trả result của intent ĐẦU TIÊN (structural check bỏ qua input/context/actor). FE mitigate bằng `lastIntentRef` (D358.7) nhưng **backend không enforce** → đây là mặt mở của G3.

### 1.4 Commit Boundary Contract — `mc_internal._mc_commit_action(request_id, result_payload)` (FREEZE)

- DEFINER · owner postgres · `search_path=''` · EXECUTE `{authenticated, postgres}` · schema `mc_internal` USAGE `{authenticated, postgres}`, unexposed PostgREST.
- **Completed-only:** derive actor nội bộ (`current_profile()`, KHÔNG nhận actor_id) · `FOR UPDATE` · validate `status='processing'` ∧ `actor_id=derived` · UPDATE `status='completed', result_payload, error_code=null, completed_at=now()`. KHÔNG dispatch, KHÔNG derive business result.
- **B6.3 KHÔNG chạm hàm này.** Mọi finalization vẫn qua đây (Invariant 2).

### 1.5 Domain Adapter — `assign_class_distribution(uuid,uuid,uuid DEFAULT NULL)` (FREEZE)

DEFINER · owner postgres · EXECUTE `{authenticated, postgres, service_role}` · shared bởi (a) MC execution qua `execute`, (b) School Portal direct (`school.manage.tsx`). Internal authz riêng (`is_admin ∨ role∈{master,sub}∧school∈user_school_ids` → entitlement → teacher-valid → dup-guard → INSERT + `write_audit_log`). **BẤT BIẾN toàn milestone (G4b unification DEFERRED).**

---

## 2. CONFIRMED GAPS

| Gap | Nguồn | Trạng thái live (đã verify) |
|---|---|---|
| **G1 — Registry authority chưa enforce end-to-end** | D358.9.1 | Discovery (`get_available_actions`) trả **mọi** row `status='active'` theo object_type → quảng bá cả `class.assign` **và** `class.edit`. Execute literal-reject mọi `action_key ≠ 'class.assign'` → `MC_ACTION_NOT_FOUND`. **Registry↔executor mismatch: discovery hứa 2, execute làm 1.** Registry là descriptor, không phải executable authority. |
| **G2 — Dispatch hardcoded, chưa có adapter seam** | D358.9.2 | Execute = `if action_key == 'class.assign'` → gọi cứng `assign_class_distribution`. Registry **thiếu** `adapter_key · execution_mode · required_context · input_schema · disabled_reason`. Thêm action mới = sửa body execute, không phải khai báo. |
| **G3 — Intent fingerprint chưa có** | D358.9.3 | Ledger **không** cột `intent_fingerprint`. Replay-conflict so `action_key+object_type+object_id` (bỏ input/context/actor) ⇒ `MC_ACTION_INTENT_MISMATCH` **không phát sinh được**; cùng request_id + intent khác = silent wrong-replay. Backend không enforce intent, chỉ FE (`lastIntentRef`). |

**Ngoài scope B6.3 (DEFERRED — không giải ở đây):** G4b (School Portal unification) · G5 (generic FE renderer, D358.9.5) · G6 (memory single-domain, D358.9.6) · 3 debt B3.3 (`subscription`/`support_case`/`privacy_request`).

---

## 3. PROPOSED ARCHITECTURE — ACTION CONTROL PLANE

Mục tiêu: chuyển registry `descriptor → executable authority`, dựng adapter resolution layer, và làm backend authoritative về intent — **giữ nguyên** 4 invariant B6.2 + contract A1.

### 3.1 Target dispatch flow

```
execute RPC (INVOKER)  ── giữ public contract BẤT BIẾN
   │
   ├─ auth gate (auth.uid / current_profile)                       [unchanged]
   │
   ├─ _mc_lookup_action(object_type, action_key)   ── DEFINER helper
   │     → trả authority row cho action DISPATCHABLE (active ∧ adapter_key resolvable)
   │     → không tìm thấy / không dispatchable → MC_ACTION_NOT_FOUND / MC_ACTION_DISABLED
   │
   ├─ declarative validation (đọc required_context + input_schema từ authority row)
   │     → thay các gate hardcode bước 5–6 hiện tại
   │
   ├─ intent_fingerprint := server-hash(canonical intent tuple)    [G3]
   │
   ├─ INSERT ledger processing (request_id, intent_fingerprint)
   │     ON CONFLICT (request_id) → replay/mismatch branch (§3.4)
   │
   ├─ adapter resolver  ── static allowlist CASE (adapter_key → executor)   [G2]
   │     → assign_class_distribution(...)  [DEFINER domain adapter, UNCHANGED]
   │
   └─ mc_internal._mc_commit_action(request_id, result)   [FREEZE — Invariant 2]
```

### 3.2 Registry Authority Model (G1)

**Transition:** `registry = descriptor` → `registry = executable authority`.

Cột authority MỚI (thiết kế — ADDITIVE nullable, chưa apply):
- `adapter_key text` — tên logic của executor. `NULL` ⇒ action **không dispatchable** (descriptor thuần).
- `execution_mode text` — ràng buộc cách resolver marshalling/invoke. Hiện: `single_domain_rpc`. Slot cho mode tương lai (multi-step / edge-delegated) không phải sửa gate.
- `required_context jsonb` — contract context khai báo (vd `{"keys":["school_id"],"exclusive":true}`). Thay gate hardcode "context chỉ chứa school_id".
- `input_schema jsonb` — contract input khai báo (vd `{"required":["program_id"],"optional":["lead_teacher_id"]}`). Thay gate hardcode "input phải có program_id…".
- `disabled_reason text` — lý do khi status inactive/disabled (surface cho FE).

**Trả lời 5 câu hỏi authority:**
- **Action lifecycle?** `status` chuẩn hoá: `active` (dispatchable ∧ discoverable) · `disabled` (registered, có adapter nhưng tạm khoá → discovery ẩn, execute `MC_ACTION_DISABLED` + disabled_reason) · `registered` (descriptor thuần, `adapter_key=NULL`, chưa có executor → discovery ẩn, execute `MC_ACTION_NOT_FOUND`). Draft/deprecated là mở rộng tương lai.
- **Active/inactive semantics?** MỘT predicate DUY NHẤT — `is_dispatchable := status='active' ∧ adapter_key IS NOT NULL ∧ adapter_key ∈ allowlist` — **được CẢ discovery LẪN execute tiêu thụ**. Đây là gốc đóng G1: mismatch không tái phát vì hai surface đọc chung một sự thật.
- **Adapter ownership?** Registry chỉ *khai báo* `adapter_key` (binding). Executor thật (`assign_class_distribution`) vẫn là server-owned DEFINER function. **Registry KHÔNG chứa code/SQL động.**
- **Validation responsibility?** Registry *khai báo WHAT* (required_context/input_schema); server *sở hữu HOW* (validator đọc contract rồi enforce). Client không thấy/điều khiển enforcement.
- **Security boundary?** Registry write giữ privileged-only (đã đúng: 0 client grant). Cột authority mới không nới grant. Registry read cho execute đi qua `_mc_lookup_action` (DEFINER) — vì `authenticated` không SELECT được registry trực tiếp (RLS default-deny).

### 3.3 Adapter Resolution Layer (G2)

- **`_mc_lookup_action(object_type, action_key)`** — STABLE SECURITY DEFINER, `search_path=''`, internal ACL `{authenticated, postgres}`. Trả authority projection (`adapter_key, execution_mode, required_context, input_schema, audit_event`) CHỈ cho row dispatchable; else signal not-found/disabled. Lý do DEFINER: execute là INVOKER, `authenticated` không đọc registry được (§1.1) → giữ registry RLS khoá, chỉ lộ projection có kiểm soát. Đối xứng doctrine với object projectors (`admin_lookup_*`, D356).
- **Adapter resolver = STATIC ALLOWLIST CASE (KHÔNG dynamic dispatch).** `CASE adapter_key WHEN 'class.assign.v1' THEN assign_class_distribution(<validated inputs>) … END`. Thêm action = thêm registry row **+** thêm một CASE-arm (code review, migration) — KHÔNG phải runtime registration tuỳ ý. Tuân **D350.2** (static CASE, no dynamic dispatch). **TUYỆT ĐỐI không** `EXECUTE format('SELECT %I(...)', adapter_key)` (injection/escalation).
- **`execution_mode`** quyết marshalling. Hiện một mode `single_domain_rpc`.
- **Failure handling:** giữ β2 subtransaction. Code mới: `MC_ACTION_DISABLED` (status disabled) · `MC_ACTION_ADAPTER_UNRESOLVED` (adapter_key ngoài allowlist — defensive, không nên xảy ra nếu migration discipline giữ) · `MC_ACTION_INTENT_MISMATCH` (§3.4).
- **KHÔNG bypass `mc_internal._mc_commit_action`** — finalization vẫn độc quyền qua commit-core.

### 3.4 Intent Fingerprint (G3)

- **Cột MỚI:** `mission_control_action_requests.intent_fingerprint text` (ADDITIVE nullable).
- **Fingerprint source:** canonical intent tuple = `(action_key, object_type, object_id, canonical(context), canonical(input), actor_id)`. actor_id vào tuple để chống cross-actor request_id collision (defense-in-depth; actor vẫn derive server-side).
- **Canonicalization rules:** chuẩn hoá deterministic — CHỈ trích các key **đã khai báo** trong `input_schema`/`required_context` theo thứ tự cố định vào một jsonb normalized (key-sorted, whitespace-normalized, null-rule xác định), rồi hash. Trích theo declared-keys tránh hash key thừa (đã bị validation loại). **Canonicalization + hash 100% SERVER-SIDE.**
- **Hashing boundary:** `encode(digest(canonical_text,'sha256'),'hex')` tính TRONG execute (server-owned), sau validation, tại/ trước INSERT-processing. **Client KHÔNG cung cấp fingerprint** (nếu client cấp → có thể ép collision/mismatch giả → cấm).
- **Replay behavior (thay structural check hiện tại làm discriminator chính):**
  - **CASE A — `existing.intent_fingerprint = computed`** → cùng intent → **replay** (trả stored result, `replayed=true`). Deterministic (Invariant 3).
  - **CASE B — `existing.intent_fingerprint ≠ computed`** → cùng request_id, intent khác → **`MC_ACTION_INTENT_MISMATCH`**, rollback-only, no mutation (Invariant 4).
  - **NULL-safety (legacy):** row trước-B6.3 có `intent_fingerprint = NULL` → không so được → **fallback** structural (`action_key+object_type+object_id`) cho NULL-fingerprint rows. Row mới luôn có fingerprint. *(Bài học NULL-safety BLOCK-3, B3.3.)*
- **Commit-core KHÔNG đổi:** fingerprint set ở INSERT-processing (trạng thái processing), commit-core vẫn completed-only.

---

## 4. SECURITY MODEL

| Trục | Posture sau B6.3 | Ghi chú |
|---|---|---|
| `execute` | **INVOKER giữ nguyên** (INV-B62-A1-03) | Registry read qua `_mc_lookup_action` (DEFINER) vì authenticated không SELECT registry được. |
| `mc_internal._mc_commit_action` | **DEFINER completed-only, FREEZE** | Sole terminal writer. B6.3 không chạm. |
| Registry **trust boundary** | Write privileged-only — **đã đúng** (0 client grant, RLS default-deny, chỉ `service_role:SELECT`) | Cột authority mới KHÔNG nới grant. |
| Adapter **trust boundary** | `adapter_key` resolve qua **static allowlist**, không dynamic EXECUTE | Barrier kép chống malicious registration. |
| Malicious adapter registration | Chặn 2 lớp: (1) không ghi được registry; (2) kể cả ghi được, adapter_key ngoài allowlist → `MC_ACTION_ADAPTER_UNRESOLVED`, không thực thi code lạ | |
| Privilege escalation | Registry điều khiển *dispatchability*, KHÔNG điều khiển *authorization*. Authz vẫn ở domain adapter + `is_admin()` (sole authz boundary). Registry-driven KHÔNG bypass adapter authz. | Nguyên tắc #4: permission cộng-scope, không flip role. |
| Intent forgery | fingerprint server-computed, không nhận client input → không ép replay-match/mismatch giả | |
| Terminal forge (G4) | **CLOSED, giữ nguyên** (grant-layer 42501, D360) | B6.3 không hồi quy. |

---

## 5. MIGRATION STRATEGY (DESIGN ONLY — chưa SQL)

Mỗi phase = 1 migration riêng, D92 3-block (CREATE/REPLACE → REVOKE/GRANT re-harden → VERIFY rollback-guard), **Owner Gate riêng**. B6.3 design KHÔNG apply gì.

| Phase | Objective | Dependency | Risk | Rollback | Verification |
|---|---|---|---|---|---|
| **0 — Preparation** | Verify registry write privileged (authenticated không mutate); chụp baseline gate-matrix của `class.assign` (permission/context/input/object/conflict/replay); xác nhận không action_key nào dispatchable-nhầm | — | **Low** (read-only) | n/a | Registry RLS admin-only proven; baseline captured |
| **1 — Registry authority foundation** | Thêm cột authority (adapter_key/execution_mode/required_context/input_schema/disabled_reason, ADDITIVE nullable); populate `class.assign` (contract = gate hiện tại); set `class.edit.adapter_key=NULL` (registered, non-dispatchable); tạo `_mc_lookup_action` (DEFINER); đổi discovery predicate → `is_dispatchable` (ẩn class.edit) | P0 | **Med** — discovery output đổi (class.edit biến mất). class.edit vốn không execute được → 0 functional loss; xác nhận FE không hard-depend class.edit | Drop cột / revert discovery / drop helper. Execute CHƯA wired → an toàn | Discovery chỉ trả class.assign; helper trả authority đúng; class.edit ẩn |
| **2 — Adapter resolver cutover** | Thay literal `if action_key<>'class.assign'` bằng `_mc_lookup_action` + static-CASE resolver + declarative validation. **Behavior-identical** cho class.assign; public contract BẤT BIẾN | P1 | **HIGH** — đây là live execution path (pilot feature). Divergence = break class.assign. β2 + commit-core phải nguyên | `CREATE OR REPLACE execute` về body B6.2 frozen (single fn replace) + re-harden ACL (D231/D359). Ledger/adapter không đụng | **Equivalence proof** full gate-matrix qua JWT-impersonation real-login (D2/D360); result envelope + audit event byte-identical; inventory delta accounted |
| **3 — Intent integrity (G3)** | Thêm `intent_fingerprint` (ADDITIVE nullable); server-compute + store ở INSERT-processing; replay = fingerprint-compare + NULL-fallback; emit `MC_ACTION_INTENT_MISMATCH` (CASE B) | P2 | **Med** — replay semantics thêm reject-path; không được break legacy replay (NULL fallback) | Drop cột + revert replay branch về structural-only | CASE A replay idempotent (Δ side-effect 0, QA-1 pattern); CASE B → INTENT_MISMATCH rollback-only (QA-2 pattern); legacy NULL-fingerprint replay vẫn chạy |
| **4 — Remove literal dispatch debt** | Gỡ residual literal (`'class.assign'` constants trong result-build); confirm registry = sole authority; document G1/G2/G3 closed | P2+P3 proven | **Low** (cleanup) | n/a (ngoài các phase trước) | Không còn action_key literal ở gate; discovery↔execute agreement proven; inventory re-pin |

**Canonical append (RULES/SYSTEM_MAP/HANDOFF) = Owner Gate riêng SAU khi các phase apply + QA PASS — KHÔNG thuộc design này.**

---

## 6. RISKS

1. **Phase 2 cutover = live-path risk (cao nhất).** `class.assign` là feature pilot đang chạy. Mitigate: equivalence-proof bắt buộc TRƯỚC khi gỡ literal; rollback = single `CREATE OR REPLACE` về body B6.2.
2. **Discovery contract change (Phase 1).** class.edit biến khỏi menu. Cần xác nhận FE không giả định class.edit hiện diện. Nếu FE có, xử lý trước.
3. **Static-CASE resolver = seam bán-khai báo.** Thêm action vẫn cần code-arm (không phải pure runtime registration). Đây là **đánh đổi có chủ đích** đổi lấy an toàn (chống dynamic dispatch). CTO cần chấp nhận ranh giới này.
4. **Intent fingerprint canonicalization drift.** Nếu quy tắc canonical đổi giữa các version → cùng intent cho fingerprint khác → false MISMATCH. Mitigate: canonicalization rule versioned + freeze; chỉ hash declared-keys.
5. **Legacy replay NULL-fingerprint window.** Row cũ không có fingerprint → fallback structural. Đúng nhưng là code-path kép cần test riêng.
6. **class.edit executor scope creep.** Cám dỗ "trong lúc này làm luôn class.edit executor". **Khuyến nghị KHÔNG** — giữ B6.3 bounded (đóng mismatch, không thêm domain executor).

---

## 7. RECOMMENDATION

**★ Khuyến nghị: DUYỆT thiết kế 4-phase, DB-first, mỗi phase một Owner Gate + QA gate.**

Nguyên tắc chốt:
- Đóng **G1** trung thực: `class.edit` → `registered` (non-dispatchable), discovery + execute chung MỘT predicate `is_dispatchable`. **Không** thêm class.edit executor trong B6.3.
- Đóng **G2** bằng adapter seam = **declarative binding (registry) + static-allowlist resolver** (KHÔNG dynamic dispatch — tuân D350.2).
- Đóng **G3** bằng `intent_fingerprint` server-computed, additive, NULL-safe cho legacy.
- Giữ tuyệt đối: execute INVOKER · commit-core DEFINER completed-only · adapter shared BẤT BIẾN · public contract BẤT BIẾN · 4 invariant B6.2.
- Phase 2 (cutover) gate sau **equivalence proof** đầy đủ.

**Phương án loại bỏ:** dynamic dispatcher (`EXECUTE format(...)`) — **REJECT**: injection/privilege-escalation, vi phạm D350.2.

**Câu hỏi mở cho CTO (cần quyết trước Phase 1):**
1. B6.3 scope = *chỉ đóng mismatch* (class.edit → registered) hay *có làm class.edit executor*? (Builder khuyến nghị: chỉ đóng mismatch.)
2. Chấp nhận ranh giới "adapter seam = static-CASE, không pure-runtime registration"?
3. Gộp Phase 2+3 vào một cutover hay tách? (Builder: **tách** — cutover behavior-identical trước, intent integrity sau, để equivalence proof sạch.)

---

## DESIGN READY FOR CTO APPROVAL
