# DMA_V128_B6_2_M0_LIVE_CAPTURE

> **Milestone:** V128-B6.2 · Production Migration Preparation · **STEP 0/1 — M0 LIVE CAPTURE**
> **Loại:** read-only capture (0 mutation) · Ngày 2026-08-14 (GMT+7)
> **Verdict:** ⚠ **CONFLICT phát hiện — xem §CRITICAL FINDING + escalation doc kèm theo. Production M3 draft ĐÃ DỪNG.**

---

## A. RUNTIME BASELINE (live, read-only)

| Item | Value |
|---|---|
| migration tail | `20260813113400` |
| tables | 92 |
| functions | 248 |
| secdef | 236 |
| policies | 169 |
| triggers | 33 |
| cron | 1 |
| `mc_internal` schema exists | **false** (clean baseline) |

Khớp canonical B6.1.5 (92/248/236/169/33/1). Không drift inventory.

---

## B. FUNCTION FINGERPRINTS (live)

| Function | identity args | owner | security | search_path | body_md5 | len |
|---|---|---|---|---|---|---|
| `public.execute_mission_control_action` | `p_action_key text, p_object_id uuid, p_context jsonb, p_input jsonb, p_request_id uuid` | postgres | **INVOKER** | `''` | `41c86f12091355049779fc97f69db2d9` | 7076 |
| `public.assign_class_distribution` | `p_class_id uuid, p_program_id uuid, p_lead_teacher_id uuid` | postgres | DEFINER | `''` | `03a1510bd827c03a650a3a88312fbe3a` | 1904 |
| `public.current_profile` | — | postgres | DEFINER | `''` | `dbc65dcaac223c2a71b05ee965dd6ab8` | 222 |
| `public.current_profile_role` | — | postgres | DEFINER | `''` | `8a5d021c0587f7412b106c10b46a6a8f` | 237 |
| `public.user_school_ids` | — | postgres | DEFINER | `''` | `a998d7436cd92acbc793067561cf7393` | 280 |
| `public.is_admin` | — | postgres | DEFINER | `''` | `b4c3c9c2fa267d1b84d7bfb386371abb` | 378 |

**ACL (live):**
- `execute_mission_control_action`: `postgres=EXECUTE`, `authenticated=EXECUTE`. *(NO service_role — M3 re-assert phải giữ đúng: REVOKE PUBLIC; GRANT authenticated; KHÔNG thêm service_role.)*
- `assign_class_distribution`: `postgres`, `authenticated`, `service_role` = EXECUTE.
- 4 helper: `postgres`, `authenticated`, `service_role` = EXECUTE.

**Identity-authz helper bodies (verified — nền cho §7 guarantee):**
- `current_profile()` = `select id from public.profiles where user_id = auth.uid()`.
- `current_profile_role()` = `select role from public.profiles where user_id = auth.uid()` (returns `profile_role` enum).
- `user_school_ids()` = `array_agg(school_id) … where user_id = auth.uid()`.
- `is_admin()` = role ∈ {super_admin, content_admin, senior_content_admin, operation_admin, sales_admin, support_admin} theo `auth.uid()`.
- **Kết luận:** mọi authz key theo `auth.uid()` → DEFINER không đổi được → guarantee "DEFINER không bypass domain authz" đứng vững.

**Adapter authz predicate (từ body live):** `is_admin() OR (current_profile_role() IN ('master_admin','sub_admin') AND v_school_id = ANY(user_school_ids()))` + business (`has_subject_entitlement`, `dma_assignable_teacher_reason`, dup-guard) + `write_audit_log('CLASS_ASSIGNMENT_CREATED', …)`.

---

## C. LEDGER CAPTURE — `mission_control_action_requests`

**Columns:** `id, request_id, action_key, object_type, object_id, status(default 'received'), result_payload, error_code, actor_id, created_at, started_at, completed_at`.

**Constraints (live):**
- PK `(id)` · UNIQUE `(request_id)` · FK `actor_id → profiles(id) ON DELETE SET NULL`.
- CHECK `status_check`: status ∈ {received, processing, completed, failed}.
- CHECK **`lifecycle_check`**: (received/processing → result/error/completed_at NULL) OR (completed → result NOT NULL, error NULL, completed_at NOT NULL) OR (failed → result NOT NULL, error NOT NULL, completed_at NOT NULL). *(commit-core finalize phải thoả — design hiện thoả.)*

**RLS enabled:** true. **Policies (3):**
- `insert_own_processing` (INSERT, authenticated) — WITH CHECK actor=current_profile() ∧ status='processing' ∧ payloads null.
- `finish_own` (UPDATE, authenticated) — qual actor=current_profile() ∧ status='processing'; WITH CHECK completed/failed shape.
- `select_own` (SELECT, authenticated) — actor=current_profile().

**Grants (relacl raw):** `postgres=arwdDxtm/postgres | authenticated=ar/postgres`.
→ `authenticated` = **a(INSERT) + r(SELECT) only**. **NO w(UPDATE).** No PUBLIC grant. anon: nothing.

**has_table_privilege (definitive):**

| role | INSERT | SELECT | UPDATE | DELETE |
|---|---|---|---|---|
| authenticated | ✅ | ✅ | ❌ | ❌ |
| anon | — | — | ❌ | — |
| service_role | — | — | ❌ | — |

`authenticated` UPDATE `class_distributions` = ❌ cũng.

---

## D. GROUND-TRUTH ROW STATE

- Ledger: **5 completed** (all completed_at+result set) · **3 failed** (all completed_at+result+error set). Recent actor `d1000000-…010` (seed profile) + real UUIDs.
- `class_distributions`: 15 total / 15 active; latest applied `2026-08-14T03:32`.
- Completed/failed rows **bắt buộc** được ghi bằng UPDATE → nhưng chỉ `postgres` có UPDATE → **các row này ghi dưới role postgres** (impersonation set JWT-claim nhưng không `SET ROLE authenticated`). **KHÔNG** row nào chứng minh finalize chạy dưới `authenticated` thật.

---

## E. FROZEN INVARIANTS (record)

1. `execute_mission_control_action` **MUST remain INVOKER** (`prosecdef=false` verified).
2. `assign_class_distribution` **untouched** (md5 `03a1510b…`).
3. Adapter remains business backstop (authz + entitlement + audit).
4. `audit_logs` untouched.

---

## ⚠ CRITICAL FINDING (drives escalation)

**`authenticated` KHÔNG có UPDATE privilege trên ledger** (`has_table_privilege=false`, relacl `ar` only). Hệ quả **chắc chắn theo INVOKER semantics**:

1. **Forge §E.4 KHÔNG live-exploitable.** Client thiếu base UPDATE → không thể PATCH ledger. `finish_own` là **dead policy** (RLS filter nhưng không có base privilege để filter). "Drop finish_own = đóng forge" là **tiền đề SAI**.
2. **`execute` finalize FAIL dưới authenticated thật.** `execute` INVOKER chạy dưới `authenticated`; finalize `UPDATE … SET status='completed'` → **permission denied** → rollback toàn transaction (kể cả `class_distributions` + audit). → **class.assign chưa từng complete được dưới real login**; 5 completed rows là artifact role-postgres.

→ Tiền đề "M3 byte-identical" và "forge hardening" trong toàn bộ chuỗi doc B6.2 **không khớp live**. Chi tiết impact + options ở:

**`DMA_V128_B6_2_M3_PREMISE_CONFLICT_CTO_ESCALATION.md`** — **CTO DECISION REQUIRED. Production M3 draft đã DỪNG chờ chốt.**

---

**Capture status:** COMPLETE + accurate (0 reconstruct-from-memory; mọi fingerprint từ live). Baseline sạch cho M1/M2 (unaffected). M3+ chờ CTO resolve conflict.
