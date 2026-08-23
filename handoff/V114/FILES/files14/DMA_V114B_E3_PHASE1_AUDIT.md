# DMA — V114B-E3 · PHASE 1 AUDIT

> Owner verdict áp dụng: **APPROVE C — START ACTOR AS EVIDENCE, NOT ACTUAL TRUTH**
> **Chưa chạm code. Chưa apply migration.**

Ký hiệu bằng chứng: **[DB]** truy vấn live · **[R]** đọc repo · **[B]** đo trình duyệt · **[I]** suy ra · **⬜** chưa làm.

---

## 0. BASELINE — VERIFIED

| | Giá trị | |
|---|---|---|
| Repository HEAD | `7ee7eeba` | **[R]** khớp, không drift |
| Migration cao nhất | `20260721023957_v114b_e2_school_ops_spine` | **[DB]** |
| Tổng migrations | **104** | **[DB]** |
| Migration kế tiếp | **105** | chưa tạo |
| Tables · secdef · policies · edge · cron | 87 · 196 · 165 · 16 · 1 | **[DB]** |

Không có mismatch đáng kể so với prompt. **Không kích hoạt Stop-Gate baseline.**

---

## 1. SCHEMA TRUTH

### 1.1 `lesson_sessions` — 16 cột **[DB]**

`id · class_distribution_id · lesson_version_id · distribution_item_id · title · scheduled_at · duration_min · content_override · state · **taught_by** · created_at · updated_at · remote_channel_key · remote_code · remote_code_rotated_at · cancel_reason`

**Không có** cột nào cho planned teacher, responsible teacher, hay confirmation status.

### 1.2 `session_state` — 9 giá trị **[DB]**

`scheduled · prep_ready · in_progress · taught_report_pending · report_pending_approval · completed · cancelled · rescheduled · makeup`

Map sang lifecycle contract của prompt §5:

| Prompt | Production | Ghi chú |
|---|---|---|
| Draft | **không tồn tại** | Session sinh ra thẳng ở `scheduled` |
| Scheduled / Published | `scheduled` · `prep_ready` · `makeup` | Ba trạng thái này là nhóm "editable" của E2 |
| In progress | `in_progress` | |
| Completed | `taught_report_pending` · `report_pending_approval` · `completed` | **Ba trạng thái, không phải một** |
| Cancelled | `cancelled` | |
| — | `rescheduled` | **Enum tồn tại nhưng OD-2 cấm ghi** — dead value |

**Hệ quả quan trọng cho §2.2 của Owner Contract:** vì không có Draft, **mọi session sinh ra đã ở trạng thái có hiệu lực vận hành**. Nên planned assignment phải được materialize **ngay trong `create_lesson_session`**, cùng transaction. Không có giai đoạn nháp để hoãn.

### 1.3 `session_teachers` — cấu trúc hiện tại **[DB]**

```
id          uuid  PK
session_id  uuid  NOT NULL → lesson_sessions ON DELETE CASCADE
profile_id  uuid  NOT NULL → profiles        ON DELETE CASCADE   ⚠️
role        text  CHECK (role IS NULL OR role IN ('lead','assist'))
created_at  timestamptz NOT NULL DEFAULT now()
UNIQUE (session_id, profile_id)
```

**Thiếu hoàn toàn:** assignment dimension · confirmation status · source · state/soft-delete · valid_from/superseded · actor · reason · school_id.

Dữ liệu hiện có: **2 dòng**, role dùng cả `assist` lẫn `lead`.

⚠️ **Mâu thuẫn nội tại:** CHECK cho phép `role='lead'`, nhưng OD-3 của E2 khẳng định `session_teachers` **không phải** người phụ trách. Giá trị `lead` đang tồn tại trong dữ liệu thật. Hai nguồn sự thật cho khái niệm "lead" — đúng loại conflation mà E3 phải gỡ.

---

## 2. `taught_by` — SỰ THẬT ĐẦY ĐỦ

| | **[DB]** |
|---|---|
| Ghi bởi | **duy nhất `start_session`**, `set taught_by = v_me` |
| Đọc bởi | **0 hàm** trong schema `public` |
| Dòng có giá trị | **3 / 8** |
| FK | `→ profiles ON DELETE SET NULL` (lịch sử được giữ, attribution bị null) |

Đúng như Owner phán định: đây là **actor của `start_session`**, không phải actual teacher. Tên cột nói mạnh hơn behavior.

**Dependency đã verify:** tầng DB — xong. Tầng frontend — ⬜ **chưa quét hết**. Theo §4 của Owner ("không rename trước khi verify toàn bộ read/write dependency"), **em chưa được phép đề xuất rename**. Xem §9.4.

---

## 3. WRITE PATHS

### 3.1 Tầng DB **[DB]**

| Thao tác | Hàm | Số lượng |
|---|---|---|
| `INSERT INTO lesson_sessions` | **`create_lesson_session`** | **1 — duy nhất** |
| `UPDATE lesson_sessions` | `update_lesson_session` · `cancel_lesson_session` · `start_session` | 3 |
| Ghi `session_teachers` | `set_session_teachers` (và `create_lesson_session` qua `p_teacher_ids`) | 2 |
| Ghi `class_distributions.lead_teacher_id` | `set_distribution_lead` · `assign_class_distribution` | 2 |

**Không có** trigger sinh session · **không có** recurring generator · **không có** bulk import · **không có** copy-schedule.

➡️ **Trả lời Stop-Gate #9 của prompt:** tồn tại **đúng một điểm xác định** để materialize planned assignment. Không phải patch nhiều đường. Đây là điều kiện thuận lợi nhất của E3.

### 3.2 Tầng frontend ⬜ **CHƯA QUÉT ĐẦY ĐỦ**

Đã đọc trọn vẹn **[R]**: `src/routes/_authenticated/school.schedule.tsx` — mọi mutation đi qua 5 RPC, không có ghi bảng trực tiếp.
Chưa đọc: `school.manage.tsx` · `teacher.session.$id.tsx` · `teacher.index.tsx` · `teacher.classes.tsx` · `teacher.journal.tsx` · `teacher.moments.tsx` · `parent.*`.

---

## 4. READ PATHS — 33 HÀM CHẠM BỀ MẶT OWNERSHIP **[DB]**

### 4.1 Phân loại resolver (prompt §3.3 · Owner §7.8)

| Resolver hiện tại | Đang dùng | **Phải dùng sau E3** |
|---|---|---|
| `get_teacher_home` | `lead_teacher_id` + `session_teachers` | **planned** (sắp tới) + **responsible** (việc còn lại) |
| `get_teacher_classes` | `lead_teacher_id` + `session_teachers` | **distribution lead** cho câu "lớp tôi phụ trách"; **planned** cho buổi bên trong |
| `get_teacher_todo_counts` | `lead_teacher_id` + `session_teachers` | **responsible** |
| `get_teacher_journals` | `lead_teacher_id` + `session_teachers` | **artifact actor** (author) |
| `get_session_readiness` | `lead_teacher_id` | **planned** |
| `get_school_week_schedule` | *không dùng lead* | **planned** — cần bổ sung |
| `get_session_detail` | *không dùng lead* | **planned** + **actual** + **responsible** |
| **`check_session_media_upload_access`** | `lead_teacher_id` + `session_teachers` | **participation/assignment** — xem §5 |
| **`check_remote_capture_access`** | `lead_teacher_id` | **participation/assignment** — xem §5 |
| `is_distribution_lead` · `is_session_lead` | `lead_teacher_id` | **distribution lead** — đúng mục đích, giữ |
| `is_session_teacher` | `session_teachers` | **participation** |
| `user_class_ids` | cả hai | **distribution lead** ∪ **participation** |
| `get_admin_action_center` · `get_admin_health_score` · `admin_lookup_user` | `lead_teacher_id` | cần phân loại từng chỉ số ⬜ |
| `get_child_journal` · `get_kid_album_service` | *không* | **artifact actor** — kiểm tra Parent-facing ⬜ |

**Số hàm đọc `taught_by`: 0.** Không có resolver nào cho actual teacher — vì actual teacher **chưa từng là một khái niệm trong hệ**.

---

## 5. AUTHORIZATION FINDING (Owner §5) — XÁC MINH

### 5.1 `check_session_media_upload_access` **[DB]** toàn văn đã đọc

```
allowed ⟸ (cd.lead_teacher_id = viewer)  OR  EXISTS(session_teachers where profile_id = viewer)
```

**Ba khiếm khuyết:**

1. **Hồi tố** — vế `cd.lead_teacher_id` đọc lead **hiện tại**. Đổi lead ⇒ lead mới lập tức có quyền upload lên **mọi buổi lịch sử** của distribution; lead cũ — người thật sự đã dạy — **mất quyền** trên chính buổi mình dạy. Đây là P1 authorization semantics đúng như Owner mô tả.
2. **Không đọc `profiles.state`** — giáo viên đã vô hiệu hoá vẫn giữ quyền nếu còn là lead hoặc còn dòng `session_teachers`. Vi phạm §13.3 sẽ áp cho E3.
3. Hàm **không** kiểm tra `p_viewer_profile` với `auth.uid()` — nó là **oracle phán quyết**, không phải điểm enforcement.

### 5.2 Điểm enforcement thật — `upload_media` Edge v19 **[R]** toàn văn đã đọc

```ts
const { data: { user } } = await userClient.auth.getUser();
if (!user) return 401;
const { data: prof } = await svc.from("profiles").select(...).eq("user_id", user.id).maybeSingle();
...
await svc.rpc("check_session_media_upload_access", { p_session_id: sessionId, p_viewer_profile: prof.id });
```

`prof.id` được **resolve phía server từ JWT**. Client **không** gửi được `profile_id` tuỳ ý.

### 5.3 🟢 SECURITY STOP-GATE — **KHÔNG KÍCH HOẠT**

| Kiểm tra Stop-Gate | Kết luận |
|---|---|
| Cross-school assignment khả thi? | **Không** — RLS `session_teachers` có `profile_school_id(profile_id) = session_school_id(session_id)`; RPC chặn ở tầng ứng dụng. Đã test lại ở E2 WP5 |
| Client gửi arbitrary teacher/school ID? | **Không** — §5.2 |
| Service-role path bỏ qua invariant? | **Không tìm thấy** — nhánh C của `upload_media` đi qua đúng gate |
| Truy cập ngoài tenant? | **Không tìm thấy** |

**Đây là P1 in-scope của E3, không phải sự cố bảo mật đang chảy máu.** Em không dừng milestone.

### 5.4 `check_remote_capture_access`

`EXECUTE` chỉ cho `postgres, service_role` — **không** cho `authenticated` **[DB]**. Cùng bệnh hồi tố qua `lead_teacher_id`. Remote hiện đang tắt (SEC0), nên rủi ro vận hành bằng 0 lúc này.

---

## 6. FK DELETION BEHAVIOR **[DB]**

| FK | ON DELETE | Đánh giá |
|---|---|---|
| **`session_teachers.profile_id → profiles`** | **CASCADE** | 🔴 **Xoá profile ⇒ xoá sạch lịch sử phân công.** Vi phạm trực tiếp §13.15 và invariant "Teacher deactivation không xóa historical assignment" |
| `lesson_sessions.taught_by → profiles` | SET NULL | ✅ giữ dòng, null attribution |
| `class_distributions.lead_teacher_id → profiles` | SET NULL | ✅ |
| `learning_moments.uploaded_by` · `media_assets.uploaded_by` · `media_assets.created_by` · `audit_logs.actor_id` | SET NULL | ✅ artifact sống sót |
| `session_marks.created_by` · `prep_items.created_by` | NO ACTION | ✅ chặn xoá |
| `session_teachers.session_id → lesson_sessions` | CASCADE | ✅ đúng — session mất thì phân công mất theo |
| `lesson_sessions.class_distribution_id → class_distributions` | CASCADE | ⚠️ xoá distribution ⇒ xoá toàn bộ session. Ghi nhận, ngoài scope E3 |

➡️ **P1 mới — E3-01.** `session_teachers.profile_id` phải chuyển sang `ON DELETE SET NULL` (hoặc RESTRICT) trong migration 105, và bảng assignment mới **không được** dùng CASCADE trên `profile_id`.

---

## 7. TEACHER ACTIVE / DISABLED SEMANTICS **[DB]**

- `profiles.state text` — giá trị đang tồn tại: **chỉ `active`**. Không có mẫu `inactive`/`disabled` nào trên production.
- **Không có** cột `deactivated_at`, `is_active`.
- Không guard nào trong 5 RPC của E2 đọc `profiles.state` (xác nhận lại V114A-P1-6).

➡️ **Hệ quả cho E3:** yêu cầu §13.3 *"Disabled teacher không được nhận assignment mới"* hiện **không có ngữ nghĩa để thi hành** — chưa tồn tại khái niệm disabled đang được dùng. E3 phải hoặc (a) định nghĩa và enforce `profiles.state <> 'active'` trong assignment guard, hoặc (b) ghi debt rõ. **Em đề xuất (a)** — chi phí thấp, chỉ là một điều kiện trong guard, và nó khoá sẵn cửa trước khi trường đầu tiên cho nghỉ việc thật.

---

## 8. UI WORDING INVENTORY ⬜ **MỘT PHẦN**

Đã xác nhận **[B]** trên production:

| Vị trí | Câu | Phán định |
|---|---|---|
| `/school/manage?tab=classes` | *"Đổi giáo viên chính chỉ áp dụng cho buổi tạo mới, không thay đổi buổi đã xếp."* | 🔴 **SAI** — dữ liệu không bảo chứng |
| `/school/schedule` panel ×2 | *"Người gửi nhật ký cho buổi là Giáo viên chính của môn, không phải danh sách này."* | 🟡 **đúng-hiện-tại nhưng sẽ sai sau E3** — sau E3 người gửi nhật ký là **responsible teacher**, không phải distribution lead |
| `/school/schedule` panel | *"Buổi chưa gắn bài sẽ hiện 'Thiếu học liệu' với giáo viên."* | ✅ trung tính |
| `/school/schedule` panel | *"Buổi đã huỷ sẽ không còn hiện với giáo viên, nhưng vẫn lưu trên lịch của trường."* | 🟡 **E2-06** — sai ở `/school/schedule`, GV vẫn thấy |
| `/teacher` | *"Lớp gần nhất sắp tới"* | 🟡 **E2-07** — thiếu ngày |
| `/teacher/classes` | *"Các lớp cô phụ trách"* | ⚠️ cần phân biệt: phụ trách **lớp** (distribution lead) ≠ được xếp dạy **buổi** |

⬜ Chưa quét: `teacher.session.$id.tsx` · `teacher.journal.tsx` · `parent.journal.tsx` · `parent.index.tsx` · các component `features/journey/*` (Parent-facing attribution).

---

## 9. PROPOSED MINIMAL SCHEMA

### 9.1 Quyết định thiết kế: **relation table**, không phải field-only

Field-only trên `lesson_sessions` bị loại vì không biểu diễn được co-teaching, không giữ được lịch sử khi reassign, và không tách được confirmation status. Prompt §4 cấm chọn field-only chỉ vì nhanh.

### 9.2 `session_teacher_assignments` (mới)

```
id                    uuid PK
session_id            uuid NOT NULL → lesson_sessions(id) ON DELETE CASCADE
profile_id            uuid NULL     → profiles(id)        ON DELETE SET NULL   ← KHÔNG CASCADE
school_id             uuid NOT NULL → schools(id)                              ← tenant guard denormalized

dimension             text NOT NULL CHECK IN ('planned','actual','responsible')
participation_role    text NOT NULL CHECK IN ('primary','co_teacher','assistant')
confirmation_status   text NOT NULL CHECK IN ('confirmed','unconfirmed','candidate') DEFAULT 'confirmed'

source                text NOT NULL CHECK IN (
                        'distribution_default','manual','substitution','bulk_reassignment',
                        'legacy_backfill','legacy_session_start_actor','retrospective_correction')

state                 text NOT NULL CHECK IN ('active','superseded') DEFAULT 'active'
valid_from            timestamptz NOT NULL DEFAULT now()
superseded_at         timestamptz
superseded_by         uuid → session_teacher_assignments(id)

assigned_by           uuid → profiles(id) ON DELETE SET NULL
reason                text
created_at            timestamptz NOT NULL DEFAULT now()
```

**Ba nghĩa, ba tên, ba resolver — không dùng chung** (Owner §3):

| Khái niệm | Biểu diễn |
|---|---|
| `start_actor` | `lesson_sessions.taught_by` (giữ nguyên, canonicalize semantics) + audit `session_started` |
| `actual_candidate` | `dimension='actual'` **AND** `confirmation_status IN ('candidate','unconfirmed')` |
| `confirmed_actual_teacher` | `dimension='actual'` **AND** `confirmation_status='confirmed'` |

**Invariant bắt buộc:** không resolver nào được trả `candidate`/`unconfirmed` như confirmed actual. Thi hành bằng **hai view/hàm tách bạch**, không phải bằng kỷ luật đọc code.

### 9.3 Ràng buộc

| # | Ràng buộc |
|---|---|
| I1 | Partial UNIQUE `(session_id)` WHERE `dimension='planned' AND participation_role='primary' AND state='active'` |
| I2 | Partial UNIQUE `(session_id)` WHERE `dimension='actual' AND participation_role='primary' AND state='active' AND confirmation_status='confirmed'` |
| I3 | Partial UNIQUE `(session_id)` WHERE `dimension='responsible' AND state='active'` |
| I4 | UNIQUE `(session_id, profile_id, dimension, participation_role)` WHERE `state='active'` |
| I5 | CHECK `dimension='responsible' ⇒ participation_role='primary'` |
| I6 | CHECK `state='superseded' ⇒ superseded_at IS NOT NULL` |
| I7 | `school_id` phải bằng `session_school_id(session_id)` — enforce trong RPC **và** RLS WITH CHECK |
| I8 | `profile_id` phải thuộc cùng school **và** `profiles.state='active'` **tại thời điểm tạo assignment mới** (không áp cho dòng `superseded`) |
| I9 | **Không hard-delete.** Reassign ⇒ `state='superseded'` + dòng mới. DELETE bị RLS từ chối hoàn toàn |

Index cho query nóng: `(session_id, dimension, state)` · `(profile_id, dimension, state)` · `(school_id, dimension, state)`.

### 9.4 `taught_by` — đề xuất **hướng 1**, chưa phải hướng 2

**Giữ cột, canonicalize semantics thành start actor**, thêm `COMMENT ON COLUMN` ghi rõ *"actor đã bấm bắt đầu buổi — KHÔNG phải confirmed actual teacher"*.

**Chưa đề xuất rename sang `started_by`** vì §4 của Owner đòi verify toàn bộ dependency, mà tầng frontend **chưa quét xong**. Rename an toàn (add → dual-write → deprecate) để lại cho một bước sau khi §3.2 và §8 hoàn tất.

---

## 10. BACKFILL PLAN — CHÍNH XÁC THEO 8 DÒNG THẬT

Trạng thái production **[DB]**, tổng **8** session:

| state | n | có `taught_by` | tương lai | quá khứ |
|---|---|---|---|---|
| `scheduled` | 2 | 0 | 2 | 0 |
| `cancelled` | 2 | 0 | 2 | 0 |
| `in_progress` | 2 | 1 | 0 | 2 |
| `taught_report_pending` | 1 | 1 | 0 | 1 |
| `completed` | 1 | 1 | 0 | 1 |

### Kế hoạch

| Nhóm | planned | actual | responsible |
|---|---|---|---|
| `scheduled` ×2 (tương lai) | ✅ tạo từ `cd.lead_teacher_id`, `source='legacy_backfill'`, `confirmed` | ❌ không tạo | ✅ = planned primary |
| `cancelled` ×2 | ✅ tạo từ lead, `legacy_backfill` (§15.5 giữ lịch sử planned) | ❌ **không bao giờ** | ❌ không |
| `in_progress` ×2 | ✅ tạo từ lead, `legacy_backfill` (§15.3) | ❌ không tạo | ✅ = planned primary |
| `taught_report_pending` ×1 · `completed` ×1 | ✅ tạo từ lead, `legacy_backfill` | ⚠️ **xem dưới** | ✅ = planned primary |

**Nếu `cd.lead_teacher_id IS NULL`** ⇒ **không tạo dòng nào** cho planned. Giữ **explicit unassigned** (vắng mặt dòng active planned/primary = chưa xếp giáo viên). Không tạo teacher giả. Hiện tại cả 8 session đều thuộc distribution có lead, nên nhánh này chưa kích hoạt — nhưng resolver phải xử lý được.

### ⚠️ Điểm cần Owner xác nhận trước Phase 2

3 dòng có `taught_by`. Owner §1 cấm biến chúng thành confirmed actual. Còn lại hai cách ghi nhận, **em không tự chọn**:

**10-A ★ (em nghiêng)** — Tạo dòng `dimension='actual'`, `confirmation_status='candidate'`, `source='legacy_session_start_actor'`. Ưu: một nơi duy nhất để nhìn, đúng chuỗi tên Owner đặt, sẵn sàng cho confirmation UI. Nhược: một dòng `actual` tồn tại cho lịch sử — mọi resolver **bắt buộc** phải lọc `confirmation_status='confirmed'`, sai một chỗ là rò.

**10-B** — Không tạo dòng nào. `taught_by` ở nguyên chỗ cũ như legacy evidence. Ưu: tuyệt đối không thể rò. Nhược: hai nơi chứa evidence (cột cũ + bảng mới cho dữ liệu tương lai), resolver phải đọc cả hai.

Cả hai đều thoả Owner Contract. Khác nhau ở chỗ **đặt rủi ro ở đâu**: 10-A đặt rủi ro vào kỷ luật query; 10-B đặt rủi ro vào sự phân mảnh.

### Verification bắt buộc (§15.7)

Trước và sau migration, báo đủ 13 con số: total · future · in_progress · completed · cancelled · planned created · explicit unassigned · actual confirmed · actual unconfirmed · invalid/cross-school candidates · orphaned teacher refs · duplicate primary · rows skipped + lý do. Backfill viết dạng **idempotent** (`WHERE NOT EXISTS`), rerun an toàn.

---

## 11. FILE INVENTORY DỰ KIẾN

### Migration
- `105_v114b_e3_session_teacher_assignment.sql` — theo D92 ba block, block 3 `RAISE` làm rollback guard

### DB objects mới
- bảng `session_teacher_assignments` + 3 index + 4 partial unique
- resolver tách bạch: `session_planned_primary()` · `session_confirmed_actual()` · `session_responsible()` · `session_actual_candidates()`
- RPC: `set_session_planned_teacher` · `confirm_session_actual_teacher` · `set_session_responsible_teacher` · `correct_session_assignment` (retrospective) · `bulk_reassign_future_sessions`
- REPLACE: `create_lesson_session` · `set_session_teachers` · `set_distribution_lead` · `start_session` · `check_session_media_upload_access` · `check_remote_capture_access`
- ALTER: `session_teachers.profile_id` FK CASCADE → SET NULL (**E3-01**)

### Read paths phải sửa
`get_school_week_schedule` · `get_session_detail` · `get_session_readiness` · `get_teacher_home` · `get_teacher_classes` · `get_teacher_todo_counts` · `get_teacher_journals`

### Frontend (sơ bộ — chờ §3.2/§8 hoàn tất)
`school.schedule.tsx` · `school.manage.tsx` · `teacher.session.$id.tsx` · `teacher.index.tsx` · `teacher.classes.tsx`

---

## 12. MIGRATION 105 — DESIGN, CHƯA APPLY

Thứ tự trong một transaction, theo D92:

**BLOCK 1 — DDL:** tạo bảng + constraint + index · ALTER FK `session_teachers.profile_id` · `COMMENT ON COLUMN lesson_sessions.taught_by` · tạo 4 resolver + RPC · enable RLS + policy.
**BLOCK 2 — REVOKE/GRANT:** `REVOKE ALL FROM PUBLIC` rồi `GRANT EXECUTE TO authenticated` cho từng hàm (D15 — `CREATE OR REPLACE` reset grants về PUBLIC).
**BLOCK 3 — VERIFY:** đếm dòng backfill, kiểm 0 duplicate primary, 0 cross-school, 0 actual confirmed được sinh ra; sai bất kỳ điều nào ⇒ `RAISE EXCEPTION` ⇒ rollback toàn bộ.

Backfill chạy **trong cùng migration**, sau DDL, dạng idempotent.

**Chưa apply.** Chờ Owner chốt §10-A hay §10-B.

---

## 13. TỔNG KẾT PHASE 1

### Đã xong
Baseline · schema · lifecycle mapping · `taught_by` truth · write paths tầng DB · read path inventory + phân loại · authorization finding (§5) · FK deletion · teacher active/disabled · `session_teachers` structure · proposed schema · backfill plan · file inventory · migration design.

### Chưa xong ⬜
Frontend read/write path sweep đầy đủ · UI wording inventory đầy đủ (Parent-facing chưa đụng).

### Defect phát hiện trong Phase 1

| ID | Mức | |
|---|---|---|
| **E3-01** | 🔴 P1 | `session_teachers.profile_id → profiles ON DELETE CASCADE` xoá sạch lịch sử phân công khi xoá profile |
| **E3-02** | 🔴 P1 | `check_session_media_upload_access` + `check_remote_capture_access` cấp quyền theo lead **hiện tại** ⇒ hồi tố (Owner §5 đã ghi nhận) |
| **E3-03** | 🟡 P2 | `session_teachers.role` cho phép `'lead'`, mâu thuẫn OD-3 của E2; dữ liệu thật đang dùng giá trị này |
| **E3-04** | 🟡 P2 | `profiles.state` chỉ có `active`; §13.3 chưa có ngữ nghĩa để thi hành |
| **E3-05** | 🟡 P2 | Enum `rescheduled` là dead value — tồn tại, bị cấm ghi, vẫn hiện trong legend UI |

### Security Stop-Gate: 🟢 **KHÔNG KÍCH HOẠT**
Không tìm thấy cross-school, không tìm thấy client-supplied identity, không tìm thấy service-role bypass.

---

*Sinh trong V114B-E3 Phase 1 · HEAD `7ee7eeba` · migration 104 · chưa chạm code.*
