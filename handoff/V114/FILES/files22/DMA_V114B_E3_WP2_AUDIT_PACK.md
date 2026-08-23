# DMA V114B-E3 — WP2 AUDIT PACK

**Loại:** audit-only · 0 migration · 0 code · 0 apply · 0 deploy
**Ngày đo live:** 21/07/2026
**Vai trò:** Claude = Builder/DB Engineer · ChatGPT = CTO/CPO · Owner = Jean Huỳnh
**Stop condition:** dừng sau khi giao pack này. Không viết migration cho tới khi CTO/Owner chốt data model.

---

## 0. GHI CHÚ VỀ CANONICAL ENTRY POINT

`DMA_V114B_E3_WP1_CLOSEOUT.md` **không có trong project knowledge** ở thời điểm phiên này. Không đọc được file.

Em **không** suy đoán nội dung. Thay vào đó em xác minh lại trạng thái WP1 **trực tiếp trên live DB** và đối chiếu với các con số anh khai trong brief:

| Khai trong brief | Đo live | Kết quả |
|---|---|---|
| migration inventory 106 | **106** (`20260721104516`) | ✅ khớp |
| WP1 đóng attribution forgery | `guard_profiles_protected_cols` trigger live trên `profiles` | ✅ hiện diện |
| `child_observations` có actor capture | cột `recorded_by` + `updated_by` live | ✅ hiện diện |

Baseline live khác: **87 bảng · 196 secdef · 165 policy · 1 cron**.

> Nếu anh muốn em cross-check nội dung WP1 closeout chi tiết hơn, cần upload file. Mọi kết luận dưới đây dựa **hoàn toàn** trên live DB + repo HEAD, không dựa vào tài liệu.

---

## A. LIVE INVENTORY

### A.1 Schema — 3 bảng lõi

**`session_teachers`** (5 cột)

| Cột | Kiểu | Null | Default |
|---|---|---|---|
| `id` | uuid | NO | `gen_random_uuid()` |
| `session_id` | uuid | NO | — |
| `profile_id` | uuid | NO | — |
| `role` | text | YES | — |
| `created_at` | timestamptz | NO | `now()` |

> **Không có** `created_by`, `assigned_by`, `assigned_at`, `state`, `removed_at`, `removed_by`, `updated_at`.
> Đây là junction table thuần. **Không có bất kỳ năng lực lịch sử hay actor attribution nào ở cấp hàng.**

**`lesson_sessions`** — 16 cột. Liên quan: `class_distribution_id` (NOT NULL), `state` (enum `session_state`, default `scheduled`), `taught_by` (uuid, nullable), `cancel_reason`.

**`class_distributions`** — 11 cột. Liên quan: `class_id`, `program_id`, `lead_teacher_id` (nullable), `state` (text, default `'active'`), `applied_by`, `applied_at`.

**Enum `session_state`** (9 giá trị): `scheduled, prep_ready, in_progress, taught_report_pending, report_pending_approval, completed, cancelled, rescheduled, makeup`.
→ **Không tồn tại `draft`.** Xác nhận contract: session bắt đầu ở `scheduled`.

### A.2 Constraints

```
session_teachers_pkey                     PRIMARY KEY (id)
session_teachers_session_id_profile_id_key UNIQUE (session_id, profile_id)
session_teachers_role_chk                 CHECK (role IS NULL OR role IN ('lead','assist'))
session_teachers_session_id_fkey          FK → lesson_sessions(id) ON DELETE CASCADE
session_teachers_profile_id_fkey          FK → profiles(id)        ON DELETE CASCADE   ⚠️
lesson_sessions_cd_slot_uidx              UNIQUE (class_distribution_id, scheduled_at) WHERE state <> 'cancelled'
class_distributions_lead_teacher_id_fkey  FK → profiles(id)        ON DELETE SET NULL
lesson_sessions_taught_by_fkey            FK → profiles(id)        ON DELETE SET NULL
```

### A.3 Index

| Bảng | Index |
|---|---|
| `session_teachers` | `_pkey` (id), `_session_id_profile_id_key` (session_id, profile_id) |
| `lesson_sessions` | `_pkey`, `_cd_slot_uidx` (partial), `_remote_code_uidx` (partial) |
| `class_distributions` | `_pkey` **only** |

> **Không có index trên `session_teachers(profile_id)`** — mọi truy vấn "buổi của tôi" quét tuần tự.

### A.4 Trigger

| Bảng | Trigger |
|---|---|
| `lesson_sessions` | `trg_lesson_sessions_updated_at` → `set_updated_at()` |
| `class_distributions` | `trg_class_distributions_updated_at` → `set_updated_at()` |
| `profiles` | `trg_guard_profiles_protected` → `guard_profiles_protected_cols()` (WP1) · `trg_profiles_updated_at` |
| **`session_teachers`** | **KHÔNG CÓ TRIGGER NÀO** |

### A.5 RLS — bật trên cả 4 bảng (`relforcerowsecurity = false` ở tất cả)

**`session_teachers`** — 4 policy, **đủ SELECT/INSERT/UPDATE/DELETE cho `authenticated`**:

| cmd | qual | with_check |
|---|---|---|
| SELECT | `same_school(session_school_id(session_id))` | — |
| INSERT | — | `(is_session_lead(session_id) OR (is_school_admin() AND same_school(...))) AND profile_school_id(profile_id) IS NOT NULL AND profile_school_id(profile_id) = session_school_id(session_id)` |
| UPDATE | `is_session_lead(...) OR (is_school_admin() AND same_school(...))` | same as INSERT |
| DELETE | `is_session_lead(...) OR (is_school_admin() AND same_school(...))` | — |

**`lesson_sessions`** — SELECT (same_school) · INSERT · UPDATE (lead hoặc school admin). **Không có DELETE policy** ✅

**`class_distributions`** — chỉ 2 policy SELECT (`is_admin()`, `same_school(...)`). **Không có INSERT/UPDATE/DELETE policy** ⇒ mọi ghi phải qua SECDEF RPC ✅

### A.6 Grants

Cả 3 bảng: `authenticated`, `anon`, `service_role` đều có **full table-level DML** (SELECT/INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER/MAINTAIN), không có column-level grant.
Gate duy nhất là RLS. `anon` không rò rỉ vì `current_profile()` → NULL, nhưng lệch chuẩn least-privilege.

### A.7 Function inventory — mọi hàm chạm `session_teachers` / `taught_by`

| Hàm | secdef | Vai trò |
|---|---|---|
| **`create_lesson_session`** | ✅ | **WRITER** — INSERT `session_teachers` |
| **`set_session_teachers`** | ✅ | **WRITER** — DELETE + INSERT `session_teachers` |
| `start_session` | ✅ | WRITER `lesson_sessions.taught_by` |
| `is_session_teacher` | ✅ | READER — guard |
| `user_class_ids` | ✅ | READER — scope |
| `check_session_media_upload_access` | ✅ | READER — quyền upload media |
| `get_teacher_home` | ✅ | READER |
| `get_teacher_classes` | ✅ | READER |
| `get_teacher_todo_counts` | ✅ | READER |
| `get_teacher_journals` | ✅ | READER |
| `admin_lookup_user` | ✅ | READER — đếm `session_teacher_rows` |

**Tổng: 2 writer · 9 reader.** Không có hàm nào khác chạm `session_teachers`.

Hàm phụ trợ liên quan: `set_distribution_lead` (writer `class_distributions.lead_teacher_id`), `is_session_lead`, `is_distribution_lead`, `session_school_id`, `cd_school_id`, `profile_school_id`, `current_profile`, `current_profile_role`, `user_school_ids`, `is_school_admin` (**INVOKER**, không phải definer), `write_audit_log`.

### A.8 Frontend consumers (repo HEAD)

| File | Chạm gì | Kiểu |
|---|---|---|
| `src/routes/_authenticated/school.schedule.tsx` | `rpc("create_lesson_session")` · `rpc("set_session_teachers")` · `rpc("update_lesson_session")` · `rpc("cancel_lesson_session")` | RPC ✅ |
| ↳ cùng file | `.from("session_teachers").select("profile_id").eq("session_id", …)` | **direct table READ** ⚠️ |
| ↳ cùng file | `.from("class_distributions").select(…).eq("state","active")` | direct table READ |
| ↳ cùng file | `.from("profiles").select("id,full_name,email,role").in("role",["lead_teacher","assistant_teacher"])` | direct READ — **không lọc `state='active'`, không lọc school** ⚠️ |

**Không tìm thấy direct WRITE `session_teachers` nào ở frontend.** Mọi ghi đi qua RPC.

### A.9 Edge Functions — 16, service-role path

`capture_session_media` (v4) đã đọc đầy đủ: **stub fail-closed SEC0**, 503 `remote_capture_temporarily_disabled`, không ghi DB, không attribution. ✅

### A.10 Row counts (live)

| Đối tượng | Số |
|---|---|
| `lesson_sessions` | **8** |
| `session_teachers` | **2** |
| `class_distributions` | 8 (0 inactive · 0 thiếu lead) |
| `profiles` | 27 active · **0 inactive** |
| session có ≥1 `session_teachers` | **2 / 8** |
| session có `taught_by` | **3 / 8** |
| `session_teachers.role = 'lead'` | 1 (legacy) |
| `session_teachers.role = 'assist'` | 1 |
| `role IS NULL` | 0 |

**Integrity scan — tất cả sạch:**

| Kiểm tra | Kết quả |
|---|---|
| cross-school assignment | **0** ✅ |
| assignee `state <> 'active'` | **0** ✅ |
| assignee role không phải teacher | **0** ✅ |
| orphan profile | **0** ✅ |
| duplicate (session, profile) | 0 (unique enforce) ✅ |
| `session_teachers` trên session `completed`/`cancelled` | **2** ⚠️ |
| session có lead **không** nằm trong `session_teachers` | **7 / 8** ⚠️ |

### A.11 Audit log — hoạt động assignment

| action | n | ghi chú |
|---|---|---|
| `session_created` | 4 | actor + metadata đầy đủ ✅ |
| `session_updated` | 5 | ✅ |
| `session_cancelled` | 2 | ✅ |
| `session_teachers_changed` | **2** | actor đầy đủ, **nhưng chỉ ghi danh sách kết quả** |
| `distribution_lead_changed` | 2 | có `lead_from` / `lead_to` ✅ |
| `session_started` | 3 | **actor_id NULL · entity_id NULL · metadata NULL** ❌ |

---

## B. CURRENT ASSIGNMENT LIFECYCLE — CHÍNH XÁC THEO CODE LIVE

```
① distribution configuration
   set_distribution_lead(cd_id, lead_teacher_id)
     ↳ guard: is_admin() OR (role ∈ {master_admin,sub_admin} AND cùng school)
     ↳ validate: profile cùng school + state='active' + role ∈ {lead_teacher, assistant_teacher, sub_admin, master_admin}
     ↳ UPDATE class_distributions.lead_teacher_id  ← GHI ĐÈ, không lưu lịch sử ở bảng
     ↳ audit 'distribution_lead_changed' có lead_from/lead_to  ← lịch sử CHỈ nằm ở audit_logs

② session creation
   create_lesson_session(cd_id, scheduled_at, …, p_teacher_ids[])
     ↳ guard: is_admin() OR (master/sub_admin cùng school).  Lead teacher KHÔNG tạo được buổi qua RPC.
     ↳ validate cd.state='active'; scheduled_at NOT NULL; duration 5..480; lesson_version published & cùng program
     ↳ validate mỗi teacher_id: cùng school + state='active' + role ∈ {lead_teacher, assistant_teacher}
     ↳ INSERT lesson_sessions (state='scheduled')  ← unique_violation ⇒ 'session_slot_taken'
     ↳ INSERT session_teachers (session_id, profile_id, role='assist')  ← role HARDCODE
        · CHỈ những id caller truyền vào
        · lead_teacher_id của distribution KHÔNG được materialize
     ↳ audit 'session_created' (atomic trong cùng transaction ✅)

③ session teacher assignment (sửa sau)
   set_session_teachers(session_id, p_teacher_ids[])
     ↳ guard: is_admin() OR (master/sub_admin cùng school)
     ↳ state phải ∈ {scheduled, prep_ready, makeup, in_progress}
     ↳ validate teacher như trên
     ↳ DELETE FROM session_teachers WHERE session_id=? AND profile_id <> ALL(new_ids)   ← HARD DELETE
     ↳ INSERT … ON CONFLICT DO NOTHING
     ↳ audit 'session_teachers_changed' metadata = {teacher_ids: [danh sách MỚI], added, removed}
        · KHÔNG ghi ai bị gỡ ⇒ danh tính người bị gỡ MẤT VĨNH VIỄN

④ session start
   start_session(session_id)
     ↳ guard: is_session_lead OR is_session_teacher   ← KHÔNG kiểm tra profiles.state
     ↳ UPDATE lesson_sessions SET state='in_progress', taught_by = current_profile()
     ↳ audit 'session_started' — payload dùng key {session_id, actor}
        nhưng write_audit_log chỉ đọc {actor_id, entity_id, entity_type, metadata}
        ⇒ 3/3 hàng audit RỖNG HOÀN TOÀN

⑤ completion / cancellation
   cancel_lesson_session → state='cancelled' + cancel_reason.  session_teachers GIỮ NGUYÊN.
   Không có path nào dọn session_teachers khi đóng buổi. ✅
```

**"Ai dạy buổi này" hiện được suy ra ở READ TIME, không phải lưu ở WRITE TIME.**
Cả 4 RPC teacher (`get_teacher_home`, `get_teacher_classes`, `get_teacher_todo_counts`, `get_teacher_journals`) dùng cùng một vị từ:

```sql
cd.lead_teacher_id = v_profile
OR EXISTS (SELECT 1 FROM session_teachers st WHERE st.session_id = ls.id AND st.profile_id = v_profile)
```

Vì `cd.lead_teacher_id` là **giá trị hiện tại**, đổi lead sẽ **hồi tố** toàn bộ buổi cũ của distribution đó.

---

## C. DEFECT MATRIX

### P0 — SECURITY / AUTHORIZATION

| ID | Mô tả | Bằng chứng |
|---|---|---|
| **WP2-P0-1** | **Direct-table write path vòng qua `set_session_teachers`.** `authenticated` có full DML grant + RLS policy INSERT/UPDATE/DELETE trên `session_teachers`. Client gọi thẳng PostgREST là ghi được, không qua RPC. | grants A.6 + policies A.5 |
| **WP2-P0-2** | **Uỷ quyền lệch giữa RPC và RLS.** RPC yêu cầu `is_admin() OR master/sub_admin`. RLS **còn cho phép `is_session_lead()`** — tức lead_teacher **không** phân công được qua RPC nhưng **phân công được** qua direct write. Hai nguồn sự thật uỷ quyền khác nhau trên cùng một bảng. | so sánh `set_session_teachers` vs `session_teachers_insert_lead_or_schooladmin` |
| **WP2-P0-3** | **RLS không enforce `profiles.state='active'` và không enforce role.** RPC chặn inactive + chặn non-teacher role; RLS chỉ kiểm tra `profile_school_id(profile_id) = session_school_id(...)`. ⇒ direct path gán được profile **inactive**, hoặc profile `master_admin`/`sub_admin` làm "giáo viên". (Parent bị chặn gián tiếp vì `school_id IS NULL`.) | policy `with_check` |
| **WP2-P0-4** | **RLS không kiểm tra `state` của buổi.** RPC chặn ở `completed`/`cancelled`/`taught_report_pending`/`report_pending_approval`. RLS **không**. ⇒ direct path **sửa/xoá được phân công của buổi đã hoàn thành**. Rewrite lịch sử đã đóng. | policy qual vs RPC `bad_state` |

> P0-1..4 là **cùng một lỗ**: `session_teachers` chưa bao giờ được đóng lại thành RPC-only. WP1 đã làm đúng việc này cho `learning_moments`. Đây là bề mặt tương đương chưa xử lý.

### P1 — SEMANTIC / HISTORY / INTEGRITY

| ID | Mô tả | Bằng chứng live |
|---|---|---|
| **WP2-P1-1** | **Hard-delete xoá sạch lịch sử phân công.** `set_session_teachers` DELETE thật. | audit `d5d09c47` 06:42:25 — `{removed:1, teacher_ids:[]}` trên session `8dcf9f2e`. **Không thể biết ai bị gỡ.** 15 giây sau gán `…014`. Sự kiện đã xảy ra trên production. |
| **WP2-P1-2** | **Hàng phân công không có actor và không có thời điểm thay đổi.** Chỉ `created_at`. Không `assigned_by`, không `removed_by/at`. Truy vết chỉ tồn tại ở `audit_logs`, và audit không ghi ai bị gỡ (P1-1). | schema A.1 |
| **WP2-P1-3** | **Planned teacher không được materialize khi tạo buổi.** 6/8 buổi có 0 hàng `session_teachers`; 7/8 buổi có lead **không** nằm trong `session_teachers`. | A.10 |
| **WP2-P1-4** | **Lịch sử bị viết lại hồi tố bởi current distribution lead.** 4 RPC teacher resolve quyền sở hữu buổi qua `cd.lead_teacher_id` hiện tại. Buổi `completed` và `taught_report_pending` đều bị ảnh hưởng. | `set_distribution_lead` chạy 2 lần hôm nay: 06:53:13 → `…013`, 06:55:04 → `…011`. Trong 111 giây đó, **mọi buổi lịch sử của distribution `…031` được quy cho Ngọc Hân**. Không phải giả định — đã xảy ra. |
| **WP2-P1-5** | **Assignment presence = live capability.** 9 reader coi hàng `session_teachers` là quyền hiện tại: `is_session_teacher` (gate `start_session` + prep write), `user_class_ids`, `check_session_media_upload_access`, 4 RPC teacher, `admin_lookup_user`. ⇒ **Bất kỳ mô hình append-only nào cũng là migration bảo mật, không phải migration dữ liệu.** Nếu ngừng xoá mà không sửa 9 consumer, giáo viên bị gỡ **giữ quyền vĩnh viễn**. Đây là hình dạng **D288**. | A.7 |
| **WP2-P1-6** | **`start_session` audit rỗng.** Payload dùng key `session_id`/`actor`; `write_audit_log` chỉ đọc `actor_id`/`entity_id`/`metadata`. 3/3 hàng `session_started` có actor_id NULL, entity_id NULL, metadata NULL. Bằng chứng ai bắt đầu buổi **chỉ** còn ở `taught_by`. | audit query + `write_audit_log` body |
| **WP2-P1-7** | **FK `session_teachers.profile_id ON DELETE CASCADE`.** Xoá 1 profile là xoá âm thầm toàn bộ lịch sử phân công của người đó. Hướng đã chốt: RESTRICT. | A.2 |
| **WP2-P1-8** | **Guard không đọc `profiles.state`.** `is_session_lead`, `is_session_teacher`, `is_distribution_lead`, `current_profile`, `user_school_ids` — không hàm nào lọc `state`. GV nghỉ việc giữ nguyên quyền. (= V114A-P1-6, vẫn mở.) **Ranh giới:** enforce active cho *assignment actor* thuộc WP2; enforce active trong *authority guard* thuộc WP4. | function bodies A.7 |
| **WP2-P1-9** | **Picker giáo viên ở frontend không lọc `state='active'`.** `school.schedule.tsx` query `profiles` chỉ lọc `role`. Chọn GV inactive ⇒ RPC trả `teacher_invalid`. Cửa chắc chắn dẫn tới lỗi = **vi phạm D290**. Hiện đang tiềm ẩn (0 profile inactive). | A.8 |

### P2 — CLEANUP / DEPRECATION (không chặn build)

| ID | Mô tả |
|---|---|
| **WP2-P2-1** | `session_teachers.role` không có consumer nào. 1 hàng `lead` legacy trên buổi `completed` (`2fab0c56`, Cô Thúy Ngân). Cả 2 writer hardcode `'assist'`. **Không drop trong WP2.** |
| **WP2-P2-2** | Không có index `session_teachers(profile_id)`. Mọi read "buổi của tôi" seq-scan. |
| **WP2-P2-3** | `lesson_sessions.taught_by` 3/8 populated, 0 consumer. Phân loại **start-actor evidence**. Giữ nguyên, không rename, không backfill. |
| **WP2-P2-4** | Buổi `aaaa…0003` ở `in_progress` nhưng `taught_by IS NULL` — state được seed trực tiếp, không qua `start_session`. Bằng chứng **state ≠ actor truth**; không được suy actual teacher từ state. |
| **WP2-P2-5** | `anon` giữ full DML grant trên cả 3 bảng. Không rò rỉ (RLS + `current_profile()` NULL) nhưng lệch chuẩn — cùng bệnh V114A-P2-1. |
| **WP2-P2-6** | `class_distributions` chỉ có `_pkey`, không index `class_id`/`lead_teacher_id`. |

---

## D. PROPOSED WP2 DATA MODEL — HAI PHƯƠNG ÁN

Cả hai đều giả định các bổ sung chung sau:

- materialize planned teacher **atomically** trong `create_lesson_session` (bao gồm cả distribution lead tại thời điểm tạo)
- `assigned_by`, `assigned_at` bắt buộc
- không hard-delete
- FK `profile_id` → `ON DELETE RESTRICT`
- đóng direct-write (`REVOKE` + bỏ policy ghi, RPC-only)

### PHƯƠNG ÁN 1 — APPEND-ONLY EVENT MODEL

Bảng mới `session_teacher_events(id, session_id, profile_id, event 'assigned'|'unassigned', role_at_event, actor_id, occurred_at, reason)`. `session_teachers` trở thành **view** (hoặc materialized projection) = fold các event.

| Tiêu chí | Đánh giá |
|---|---|
| Integrity | **Cao nhất.** Không có UPDATE, không có DELETE. Lịch sử bất biến theo cấu trúc, không theo kỷ luật. |
| Query cost | **Cao nhất.** Mọi read hiện tại là `EXISTS(...)` đơn giản → thành fold/window. 9 consumer đều phải viết lại logic, không chỉ thêm filter. |
| Migration compat | **Khó.** `session_teachers` là bảng thật đang có RLS + grant + FK. Chuyển thành view làm mất RLS policy hiện có, mất unique constraint, và **frontend `.from("session_teachers")` sẽ đổi hành vi**. |
| Concurrency | **Đơn giản nhất** — chỉ INSERT, không tranh chấp hàng. Nhưng cần chống double-assign bằng logic fold, không bằng unique index ⇒ cần advisory lock hoặc serializable. |
| Auditability | **Cao nhất.** Trả lời được "ai gỡ ai, lúc nào, vì sao" ngay trong domain, không phụ thuộc `audit_logs`. |
| Frontend cutover | Nặng. Direct read hiện tại phải đổi sang RPC hoặc view mới. |
| WP3/WP4 readiness | **Tốt nhất.** Actual teacher và responsible teacher là các loại event mới, không phải schema mới. |

### PHƯƠNG ÁN 2 — VERSIONED CURRENT-ROW + SUPERSESSION ★ (em nghiêng)

Giữ nguyên bảng `session_teachers`, thêm cột:

```
assignment_state text NOT NULL DEFAULT 'active' CHECK (assignment_state IN ('active','superseded'))
assigned_by      uuid NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT
assigned_at      timestamptz NOT NULL DEFAULT now()
unassigned_by    uuid NULL REFERENCES profiles(id) ON DELETE RESTRICT
unassigned_at    timestamptz NULL
supersede_reason text NULL
```

Bỏ unique cũ, thay bằng:

```
UNIQUE (session_id, profile_id) WHERE assignment_state = 'active'
```

"Gỡ" = `UPDATE … SET assignment_state='superseded', unassigned_by, unassigned_at`. Gán lại người cũ = hàng `active` **mới**.

| Tiêu chí | Đánh giá |
|---|---|
| Integrity | Cao, **nhưng do kỷ luật** — cần trigger chặn UPDATE trên hàng `superseded` và chặn DELETE tuyệt đối. Có thể enforce cứng bằng trigger + revoke DELETE. |
| Query cost | **Thấp nhất.** 9 consumer chỉ thêm `AND st.assignment_state = 'active'`. Không đổi hình dạng truy vấn. |
| Migration compat | **Dễ nhất.** ADD COLUMN với default; hàng hiện có (2 hàng) backfill `assignment_state='active'`. `assigned_by` NOT NULL cần giá trị cho 2 hàng legacy — **cần Owner quyết** (xem G.4). |
| Concurrency | **Mạnh nhất** — partial unique index xử lý race ở tầng DB, không cần lock. |
| Auditability | Đủ. Trả lời được "ai gỡ ai lúc nào". Kém phương án 1 ở chỗ chuỗi assign→unassign→assign lại của cùng một người tạo nhiều hàng — đọc timeline cần ORDER BY, không tự nhiên bằng event log. |
| Frontend cutover | **Nhẹ nhất.** `.from("session_teachers").select("profile_id").eq("session_id",…)` chỉ cần thêm `.eq("assignment_state","active")` — và cutover này **backward-compatible** vì mọi hàng cũ đều `active`. |
| WP3/WP4 readiness | Đủ cho planned teacher. **Actual teacher và responsible teacher sẽ cần bảng riêng** (không nhồi vào bảng này) — thêm schema ở WP3/WP4. |

### PHƯƠNG ÁN 3 (hybrid) — current-row + event side-table

Phương án 2 cho trạng thái hiện hành + bảng event append-only chỉ để ghi lịch sử. Có ưu điểm cả hai; nhược điểm là **hai nguồn sự thật phải luôn nhất quán**, phải enforce bằng trigger. Em **không khuyến nghị** trong WP2: đây chính là loại phức tạp mà D15/D92 nói là dễ trôi.

### Vì sao em nghiêng phương án 2 — và vì sao em không tự chốt

Lý do nghiêng: **P1-5 là rủi ro lớn nhất của WP2.** Ngừng xoá mà không sửa 9 consumer = biến bug lịch sử thành lỗ hổng quyền. Phương án 2 làm cutover 9 consumer thành **một filter mỗi chỗ**, kiểm chứng được từng cái. Phương án 1 làm cutover thành **viết lại logic mỗi chỗ** — cùng lúc với việc lần đầu có lịch sử. Hai thay đổi rủi ro chồng lên nhau.

Lý do **không** tự chốt: đây là trade-off Owner thật, không phải sở thích kỹ thuật. Nếu định hướng sản phẩm là **ba lớp sự thật (planned / actual / responsible) đều sẽ có lịch sử riêng**, thì phương án 1 trả nợ một lần ở WP2 thay vì trả ba lần ở WP2/WP3/WP4. Chi phí ngắn hạn cao hơn, tổng chi phí có thể thấp hơn. Đó là câu hỏi lộ trình, không phải câu hỏi schema.

---

## E. MIGRATION SEQUENCE — STAGED ROLLOUT

Mỗi stage là một migration độc lập theo **D92 ba-block** (DDL → REVOKE/GRANT → VERIFY với `RAISE` làm rollback guard), có QA đi kèm.

| Stage | Nội dung | Backward compatible? | Rollback boundary |
|---|---|---|---|
| **S1 — Foundation** | ADD COLUMN (nullable trước) · partial unique index · FK CASCADE→RESTRICT · index `(profile_id)` · backfill 2 hàng · SET NOT NULL | ✅ frontend + RPC cũ chạy nguyên | Drop column/index. Không mất dữ liệu. |
| **S2 — Writer cutover** | Viết lại `set_session_teachers` (supersede thay vì delete, ghi actor, audit ghi cả `removed_profile_ids`) · `create_lesson_session` materialize planned teacher gồm distribution lead · sửa audit payload `start_session` (P1-6) | ✅ chữ ký RPC không đổi | `CREATE OR REPLACE` về bản cũ + **bắt buộc re-run REVOKE/GRANT (D15)** |
| **S3 — Reader cutover** | 9 consumer thêm `assignment_state='active'` · frontend `school.schedule.tsx` thêm filter + lọc `state='active'` ở picker (P1-9) | ✅ vì mọi hàng cũ đều `active` | Revert từng hàm độc lập |
| **S4 — Lockdown** | `REVOKE INSERT/UPDATE/DELETE ON session_teachers FROM authenticated, anon` · DROP 3 policy ghi · trigger chặn DELETE và chặn UPDATE hàng `superseded` · giữ SELECT policy | ❌ **BREAKING nếu S3 chưa xong** | Re-grant + re-create policy |
| **S5 — QA + evidence** | Login thật 2 trường (D2/D3): master gán/gỡ/gán lại · GV thấy đúng buổi · GV bị gỡ mất quyền · buổi completed không sửa được · direct-write bị chặn · aclexplode verify (D15) | — | — |

**Ràng buộc thứ tự tuyệt đối:** **S4 không được chạy trước S3.** Nếu đảo, GV bị gỡ giữ quyền (P1-5). Nếu S4 chạy trước khi bundle mới lên production, thao tác của trường sẽ 403 — đúng bài học Stage C của WP1.

**Không thuộc WP2:** actual-teacher confirmation, responsible-teacher handoff, chuyển journal authority, đụng `taught_by`, drop `role`, mở WP4.

---

## F. SECURITY & INTEGRITY INVARIANTS (đề xuất khoá cho WP2)

| # | Invariant | Enforce ở đâu |
|---|---|---|
| I1 | **Same-school** — assignee.school_id = session.school_id, cả hai NOT NULL | RPC + RLS `with_check` + trigger |
| I2 | **Active profile** — assignee `profiles.state='active'` tại thời điểm gán | RPC + trigger (RLS hiện thiếu — đóng P0-3) |
| I3 | **Role hợp lệ** — assignee role ∈ {lead_teacher, assistant_teacher} | RPC + trigger |
| I4 | **No hard-delete** — DELETE trên `session_teachers` bị chặn tuyệt đối, kể cả cho `authenticated` | REVOKE + drop policy + trigger `BEFORE DELETE … RAISE` |
| I5 | **Immutable history** — hàng `superseded` không sửa được | trigger `BEFORE UPDATE` |
| I6 | **No cross-session mutation** — không đổi `session_id` của hàng đã tồn tại | trigger |
| I7 | **Actor attribution** — `assigned_by` NOT NULL, do server gán từ `current_profile()`, **client không gửi được** (bài học WP1) | column-level grant + trigger |
| I8 | **Completed/cancelled preservation** — session ở `completed`/`cancelled`/`taught_report_pending`/`report_pending_approval` không nhận mutation phân công | RPC + RLS + trigger |
| I9 | **Idempotency** — gọi `set_session_teachers` hai lần cùng payload ⇒ lần hai `added=0, removed=0`, **không sinh hàng mới, không sinh audit sai** | logic RPC |
| I10 | **Concurrency** — hai admin gán song song ⇒ partial unique index quyết định, không double-active | index |
| I11 | **Single authorization truth** — uỷ quyền phân công chỉ định nghĩa **một chỗ**; RLS không được rộng hơn RPC (đóng P0-2) | S4 |
| I12 | **Planned ≠ actual ≠ responsible** — WP2 chỉ ghi planned. Không suy actual từ `taught_by`, không suy từ `state`, không backfill. | kỷ luật + review |

---

## G. OWNER DECISIONS REQUIRED

Chỉ những điểm em **không** được tự quyết:

**G.1 — Data model.** Phương án 1 (append-only event) hay **2 ★** (versioned supersession)? Trade-off thật nằm ở lộ trình WP3/WP4, không nằm ở WP2. → §D.

**G.2 — Có materialize distribution lead vào `session_teachers` khi tạo buổi không?**
- **A** — có, snapshot lead tại thời điểm tạo ⇒ đóng P1-4 (lịch sử không bị viết lại hồi tố), nhưng đổi ngữ nghĩa: `session_teachers` không còn thuần "trợ giảng" như copy UI hiện tại.
- **B** — không, giữ lead động ⇒ P1-4 vẫn mở tới WP4.
Em nghiêng **A**, vì P1-4 đã chứng minh xảy ra thật hôm nay. Nhưng nó chạm product copy và ngữ nghĩa vai trò — anh quyết.

**G.3 — Lead teacher có được phân công trợ giảng không?** RLS hiện nói CÓ, RPC nói KHÔNG (P0-2). Phải chọn một. Em nghiêng **KHÔNG** (chỉ master/sub_admin), khớp với "phân công lại là hành vi quản lý" trong V114A workstyle map.

**G.4 — `assigned_by` cho 2 hàng legacy.** `assigned_by` NOT NULL cần giá trị cho hàng `2fab0c56/Thúy Ngân` (role `lead`) và `8dcf9f2e/Thảo My`. Ba lựa chọn: (a) NULL-able cho hàng lịch sử + CHECK "NOT NULL từ ngày X", (b) gán sentinel `system_backfill`, (c) suy từ audit — chỉ khả thi cho hàng `8dcf9f2e` (actor `…010`), hàng còn lại **không có audit**. Em nghiêng **(a)** — không bịa actor. Trùng tinh thần "không fake backfill lịch sử".

**G.5 — Mở P1-6 (`start_session` audit rỗng) trong WP2 hay tách?** Sửa 3 dòng payload, rủi ro gần 0, nhưng nằm ngoài scope chữ "assignment". Em nghiêng **đưa vào S2** vì nó là actor-capture, cùng họ với WP1.

**G.6 — Cửa sổ cho S4 (lockdown).** WP1 Stage C đã cho thấy revoke grant làm bundle cũ 403. Hiện chỉ Owner thao tác trên dữ liệu demo ⇒ có thể chạy ngay sau S3 verify. Xác nhận lại giả định này còn đúng.

---

## H. UNVERIFIED — CHƯA ĐỌC, KHÔNG SUY ĐOÁN

Ghi rõ để không nhận là đã audit đủ:

| Hạng mục | Trạng thái |
|---|---|
| `DMA_V114B_E3_WP1_CLOSEOUT.md` | **không có trong project knowledge** — chưa đọc |
| `teacher.session.$id.tsx`, `teacher.classes.tsx`, `school.manage.tsx` | **chưa đọc** — cần sweep xác nhận không có direct read/write `session_teachers` ngoài `school.schedule.tsx` |
| 15/16 Edge Function (đã đọc `capture_session_media`) | **chưa đọc** — cần xác nhận không có service-role write vào `session_teachers` |

Ba mục này **phải đóng trước S2**, không phải trước khi chốt data model. Chúng có thể làm phát sinh thêm consumer trong danh sách cutover S3, nhưng không đổi lựa chọn ở §D.

---

## I. TRẠNG THÁI CHỐT

| | |
|---|---|
| WP1 | **FORMALLY PASS / CLOSED** (giữ nguyên) |
| E3-SG-01 | **PARTIALLY CONTAINED; AUTHORITY SEMANTICS PENDING WP4** — không đóng |
| WP2 | **AUDIT DELIVERED · IMPLEMENTATION CHƯA MỞ** |
| Migration inventory | **106** — không đổi |
| DB / code / data | **không sửa gì trong phiên này** |
| `DMA_RULES.md` / `DMA_SYSTEM_MAP.md` | **không đụng** — canonicalize một lần ở cuối E3 |
| WP4 | chưa mở |

---

*Audit-only · V114B-E3 · WP2 · không canonicalize · không closeout. Kỷ luật vàng D1: audit live trước khi tin số.*
