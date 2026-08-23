# DMA — V114B-E3 · PHASE 1 FINAL AUDIT ADDENDUM

> Sinh theo **OG-E3-PHASE1-FINAL — APPROVED**.
> Hợp nhất `DMA_V114B_E3_PHASE1_AUDIT.md` · `..._SWEEP_PART1.md` · `..._SWEEP_PART2.md`. Không lặp toàn văn.
> Ký hiệu: **[DB]** truy vấn live · **[R]** đọc repo · **[I]** suy ra · ⬜ chưa làm.

---

## 1. PHASE 1 FINAL VERDICT

**Phase 1 = COMPLETE.** Đủ sự thật để thiết kế migration 105.

| Baseline | Giá trị | |
|---|---|---|
| Repository HEAD | `7ee7eeba` | **[R]** không drift |
| Migration cao nhất | `20260721023957_v114b_e2_school_ops_spine` (104) | **[DB]** |
| Tables · secdef · policies · edge · cron | 87 · 196 · 165 · 16 · 1 | **[DB]** |
| lesson_sessions | 8 dòng · 3 có `taught_by` | **[DB]** |
| session_teachers | 2 dòng (`assist` ×1 · `lead` ×1) | **[DB]** |
| child_observations | 5 dòng · **0 có actor** | **[DB]** |
| learning_moments | 18 dòng · `uploaded_by` null ×0 · `approved_by` null ×13 | **[DB]** |
| profiles | 27 dòng · **tất cả `state='active'`** | **[DB]** |

**Kết luận nền:** hệ thống chưa từng có khái niệm *actual teacher*. Cái đang tồn tại là **distribution lead hiện tại**, được dùng làm proxy cho mọi câu hỏi ownership cấp session — và vì lead có thể đổi bất kỳ lúc nào, **mọi quyền phái sinh từ nó đều hồi tố**.

### Sweep coverage

| Bề mặt | Trạng thái |
|---|---|
| DB: 196 secdef, RLS toàn bảng liên quan, FK, grants, trigger | ✅ **[DB]** |
| `school.schedule.tsx` · `school.manage.tsx` · `teacher.session.$id.tsx` · `parent.journal.tsx` | ✅ **[R]** toàn văn |
| `teacher.index/classes/journal/moments.tsx` · `parent.index.tsx` · `features/journey/*` | ⬜ chưa đọc từng dòng — **rủi ro còn lại là câu chữ UI, không phải dependency** (4 RPC nguồn đã inventory đủ ở §4.1 audit gốc; **[DB]** chứng minh parent payload không chứa attribution) |

### `taught_by` — dependency sweep final

| Tầng | Đọc | Ghi |
|---|---|---|
| 196 secdef function | **0** | 1 — `start_session` |
| Frontend đã đọc toàn văn (4 file) | **0** | qua `start_session` |
| Type `SessionInfo` | không có trường | — |

➡️ Theo **10-B**: giữ cột, chỉ `COMMENT ON COLUMN`. **Không rename.** Sweep frontend còn dư địa nhưng quyết định 10-B khiến rename không còn nằm trong scope, nên khoảng trống này **không chặn Phase 2**.

---

## 2. D293 VERDICT

🟢 **KHÔNG VI PHẠM.**

| | Nguồn |
|---|---|
| UI gate `StepReview` | `get_teacher_classes.is_lead` ⟸ `cd.lead_teacher_id = current_profile()` |
| RPC `submit_session_journal` | `is_session_lead()` ⟸ `cd.lead_teacher_id = current_profile()` |
| Nhánh `cancelled` | UI ẩn (RPC list loại `cancelled`) · RPC trả `bad_state` — **cùng từ chối** |

**Nhưng:** UI tự suy luận capability bằng một RPC *danh sách lớp*, thay vì nhận capability từ read model của chính session. Sự trùng khớp hôm nay là **may mắn cấu trúc**, không phải hợp đồng.

**Bắt buộc sau E3 (Owner §5):**
- Bỏ suy luận riêng ở UI. UI lấy capability từ `get_session_detail` (hoặc gọi đúng authority resolver).
- RPC là enforcement source of truth duy nhất.
- Quyền gửi journal ⟸ **active responsible teacher của session**, không phải distribution lead.
- Đổi distribution lead **không** đổi quyền trên session lịch sử.
- **Không đổi wording thành lời hứa mới trước khi resolver tồn tại.**

---

## 3. E3-SG-01 — SECURITY STOP-GATE **TRIGGERED**

Owner bác cách phân loại của em (em đề nghị 🟢 vì không cross-school, không rò media). **Owner đúng theo quy định đã khoá trước:** `uploaded_by` giả mạo được ⇒ Stop-Gate kích hoạt. Không cần cross-school hay media leak.

### Bằng chứng **[DB]** — `learning_moments`

RLS, cả 3 policy role `{public}`:

| cmd | qual | with_check |
|---|---|---|
| INSERT | — | `same_school(class_school_id(class_id))` |
| UPDATE | `same_school(class_school_id(class_id))` | `same_school(class_school_id(class_id))` |
| SELECT | `same_school(...) OR (is_moment_parent(id) AND state='approved')` | — |

Column grants: `authenticated` **và** `anon` có INSERT + UPDATE trên **toàn bộ cột**, gồm `uploaded_by` · `approved_by` · `state` · `class_id` · `session_id`.

| # | Lỗ hổng | Mức |
|---|---|---|
| SG-a | Client gửi `uploaded_by` tuỳ ý — **kể cả profile ngoài trường** (cột này không hề bị kiểm school) | 🔴 |
| SG-b | `uploaded_by` **sửa được sau INSERT** bằng normal UPDATE | 🔴 |
| SG-c | `approved_by` client ghi/sửa được tự do | 🔴 |
| SG-d | `state='approved'` set trực tiếp từ client ⇒ **vượt mặt `submit_session_journal`** | 🔴 |
| SG-e | Qua SG-d, parent metadata hiện ra **không qua journal approval workflow** | 🔴 |

`submit_session_journal` áp 3 điều kiện mà direct UPDATE bỏ qua hoàn toàn: session ở `in_progress` · moment đã gắn bé · có `media_assets` active.

**Consent gate không bị ảnh hưởng** — MIN-consent gác ở tầng ký signed URL, không ở `learning_moments.state`. Ảnh không rò. Nhưng metadata thì có.

**[DB] chưa kết luận:** 13/18 moment có `approved_by IS NULL`. Chưa đối chiếu từng dòng với `state` ⇒ **không tuyên bố có bị lạm dụng hay không**. Việc này thuộc WP1 evidence.

---

## 4. OWNER RESOLUTION CỦA E3-SG-01

**Điều kiện Owner:** containment E3-08/E3-09 phải nằm trong 105, **trước hoặc cùng** atomic security foundation với assignment model. Không triển khai Principal Today / Teacher Today / UI ownership mới trước khi containment PASS.

### 4.1 Thiết kế containment — E3-08 (attribution integrity)

**Nguyên tắc: không dựa vào frontend honesty. Database override, không phải database trust.**

| Lớp | Biện pháp |
|---|---|
| 1 · Trigger | `BEFORE INSERT` trên `learning_moments`: non-privileged ⇒ `new.uploaded_by := current_profile()`; `new.approved_by := null`; `new.state := 'draft'` |
| 2 · Trigger | `BEFORE UPDATE`: non-privileged ⇒ ghim `uploaded_by`, `approved_by`, `state`, `class_id`, `session_id` về `old` (gương `guard_profiles_protected_cols()`) |
| 3 · Grant | `REVOKE INSERT (uploaded_by, approved_by, state), UPDATE (uploaded_by, approved_by, state, class_id, session_id) ON learning_moments FROM authenticated, anon` |
| 4 · Kênh đặc quyền | RPC/Edge SECURITY DEFINER đặt `set_config('dma.privileged_write','1', true)`; trigger đọc `current_setting('dma.privileged_write', true)` để bỏ qua ghim. **Local-scope**, hết hiệu lực cuối transaction |

Đáp ứng đủ contract Owner: client không chọn actor · actor derive server-side · same-school đảm bảo qua `current_profile()` · `uploaded_by` immutable sau creation · legacy non-null giữ nguyên · legacy null giữ null · **không backfill**.

⚠️ **Ràng buộc frontend:** `teacher.session.$id.tsx` hiện gửi `uploaded_by: profile?.id` trong INSERT. Sau lớp 3, INSERT sẽ **lỗi quyền cột**. Cutover bắt buộc cùng nhịp: WP1 phải gỡ trường này khỏi payload, hoặc chuyển INSERT sang RPC. **Không được deploy lớp 3 trước khi frontend cutover.**

### 4.2 Thiết kế containment — E3-09 (approval integrity)

- Approval **chỉ** qua `submit_session_journal` hoặc một approval RPC đặc quyền tương đương.
- Lớp 2 + lớp 3 ở trên đã chặn client tự set `state='approved'`.
- `submit_session_journal` giữ nguyên mọi guard hiện có, **cộng thêm**: authority chuyển từ `is_session_lead` → `session_responsible()` (WP4), và `approved_by = current_profile()` (đã có).
- Normal UPDATE chỉ còn whitelist: `caption` · `theme_tag` · `album_id` · `feedback_note` · `updated_at`.
- **Regression-test consent signing riêng.** Không được làm yếu consent gate.

### 4.3 Điều kiện đóng E3-SG-01

| # | Phải chứng minh bằng test thật (real login, không SQL Editor — D2/D3) |
|---|---|
| 1 | Không giả mạo `uploaded_by` |
| 2 | Không sửa `uploaded_by` sau creation |
| 3 | Không tự approve từ client |
| 4 | Không approve khi không có journal authority |
| 5 | Không cross-school |
| 6 | Parent không thấy unapproved metadata |
| 7 | Service-role path không bypass invariant |
| 8 | Media/consent behavior hiện có vẫn PASS |

Closeout ghi: **`E3-SG-01 CLOSED — ATTRIBUTION AND APPROVAL INTEGRITY`**. Thiếu 1 trong 8 ⇒ **E3 không được close**.

---

## 5. CONSOLIDATED DEFECT REGISTER

| ID | Mức | Nội dung | Ship trong 105 |
|---|---|---|---|
| **E3-SG-01** | 🔴 **STOP-GATE** | Attribution + approval integrity (`learning_moments`) | ✅ **WP1, trước mọi thứ khác** |
| E3-08 | 🔴 P1 | `uploaded_by` giả mạo & sửa được | ✅ WP1 |
| E3-09 | 🔴 P1 | `state='approved'` set trực tiếp, vượt journal workflow | ✅ WP1 |
| E3-12 | 🟡 | `profiles.state` không được trigger ghim | ✅ WP1 |
| E3-01 | 🔴 P1 | `session_teachers.profile_id` FK CASCADE | ✅ WP2 — **`ON DELETE RESTRICT`** |
| E3-02 | 🔴 P1 | Media/remote authorization hồi tố theo lead | ✅ WP4 |
| E3-06 | 🔴 P1 | Quyền gửi nhật ký hồi tố theo lead (D293 **không** vi phạm) | ✅ WP4 |
| E3-07 | 🔴 P1 | `child_observations` không actor **+ gate hồi tố** | ✅ WP1(cột)/WP4(gate) |
| E3-10 | 🔴 P1 | `set_session_teachers` hard-delete lịch sử, cả khi `in_progress` | ✅ WP3 |
| E3-04 | 🟡 | `profiles.state='active'` guard mở rộng | ✅ WP2/WP3 |
| E3-03 | 🟡 P2 | `session_teachers.role` — **0 consumer toàn hệ** | deprecate only, **không drop** |
| E3-05 | 🟡 P2 | enum `rescheduled` chết, còn trong legend ×2 file | ❌ deferred |
| **E3-11** | 🔴 | Parent-facing **không có** attribution; `approved_by` 0 người đọc | ❌ **DEFERRED** — §7 |

---

## 6. DECISION 10-B — FINAL

3 dòng `lesson_sessions.taught_by`:

- ✅ Giữ nguyên tại cột hiện tại · thêm `COMMENT ON COLUMN`.
- ❌ Không tạo dòng `dimension='actual'` · không `confirmation_status='candidate'` · không actual-unconfirmed.
- ❌ Không dùng cho historical teacher · Parent Portal · reporting · workload · xác nhận người thực sự dạy.
- ❌ Không rename · không remove · không dual-write rename.

**Semantics chính thức:**
> `taught_by` legacy = actor đã thực hiện `start_session`. **Không** phải actual teacher.

**[DB] xác nhận tiền đề:** `start_session` gate = `is_session_lead(...) OR is_session_teacher(...)`. Trợ giảng nằm trong `session_teachers` ⇒ **bấm được**. Actor ≠ actual teacher là hành vi đo được, không phải suy đoán.

Actual confirmed **chỉ** sinh bởi confirmation workflow mới.

**Verification bắt buộc trong BLOCK 3 của 105:**

```
legacy actual confirmed created   = 0
legacy actual candidates created  = 0
legacy actual-unconfirmed created = 0
```

Sai bất kỳ ⇒ `RAISE EXCEPTION` ⇒ rollback toàn bộ (D92).

---

## 7. E3-11 — DEFERRED

**[DB] cơ sở:**

| Function | `uploaded_by` | `approved_by` |
|---|---|---|
| `get_child_journal` (Parent) | ❌ | ❌ |
| `get_kid_album_service` (Kid) | ❌ | ❌ |
| `admin_lookup_media` · `get_school_media_library` · `drive_*` ×6 · `archive_empty_draft_moment_service` · `finalize_voice_contribution` · `get_teacher_todo_counts` | ✅ | — |
| `submit_session_journal` | — | ✅ **ghi** |

`approved_by`: **0 function đọc**. **[R]** `parent.journal.tsx` chỉ tiêu thụ payload `get_child_journal` (`journey · skills · badges · moments · creations`), không đọc bảng trực tiếp, không có trường tên giáo viên.

➡️ **Regression risk Parent-facing = 0.** §2.5 phải **xây mới**, không phải bảo toàn.

**105 vẫn phải:** ghi actor truth đúng cho dữ liệu mới · bảo vệ khỏi giả mạo · không rewrite khi assignment đổi · chuẩn bị resolver/data contract. **105 không được:** thêm teacher name vào Parent payload · đổi Parent UI. **Regression-test Parent Timeline + Parent Journal giữ nguyên.**

**Backlog canonical: `Parent Artifact Attribution Experience`** — milestone sau phải phân biệt confirmed actual teacher · journal author · media uploader · observation recorder · evidence creator. **Không được hiển thị distribution lead hiện tại như historical teacher.**

---

## 8. FINAL SCHEMA RECOMMENDATION

### 8.1 `session_teacher_assignments` (mới) — source of truth

```
id                    uuid PK
session_id            uuid NOT NULL → lesson_sessions(id) ON DELETE CASCADE
profile_id            uuid NULL     → profiles(id)        ON DELETE RESTRICT
school_id             uuid NOT NULL → schools(id)

dimension             text NOT NULL CHECK IN ('planned','actual','responsible')
participation_role    text NOT NULL CHECK IN ('primary','co_teacher','assistant')
confirmation_status   text NOT NULL CHECK IN ('confirmed','unconfirmed','candidate') DEFAULT 'confirmed'

source                text NOT NULL CHECK IN (
                        'distribution_default','manual','substitution','bulk_reassignment',
                        'legacy_backfill','retrospective_correction')
                      -- 'legacy_session_start_actor' ĐÃ GỠ theo 10-B

state                 text NOT NULL CHECK IN ('active','superseded') DEFAULT 'active'
valid_from            timestamptz NOT NULL DEFAULT now()
superseded_at         timestamptz
superseded_by         uuid → session_teacher_assignments(id)

assigned_by           uuid → profiles(id) ON DELETE SET NULL
reason                text
created_at            timestamptz NOT NULL DEFAULT now()
```

**Thay đổi so với §9.2 audit gốc:** `profile_id` FK **`ON DELETE RESTRICT`** (đồng bộ E3-01, không phải SET NULL — assignment vô danh bị cấm); `source` bỏ giá trị `legacy_session_start_actor` vì 10-B cấm sinh dòng từ `taught_by`.

**Ba khái niệm, ba tên, ba resolver — không dùng chung:**

| Khái niệm | Biểu diễn |
|---|---|
| `start_actor` | `lesson_sessions.taught_by` + audit `session_started` — **evidence only** |
| `confirmed_actual_teacher` | `dimension='actual' AND confirmation_status='confirmed'` |
| `responsible_teacher` | `dimension='responsible' AND state='active'` |

### 8.2 Ràng buộc

| # | |
|---|---|
| I1 | Partial UNIQUE `(session_id)` WHERE `dimension='planned' AND participation_role='primary' AND state='active'` |
| I2 | Partial UNIQUE `(session_id)` WHERE `dimension='actual' AND participation_role='primary' AND state='active' AND confirmation_status='confirmed'` |
| I3 | Partial UNIQUE `(session_id)` WHERE `dimension='responsible' AND state='active'` |
| I4 | UNIQUE `(session_id, profile_id, dimension, participation_role)` WHERE `state='active'` |
| I5 | CHECK `dimension='responsible' ⇒ participation_role='primary'` |
| I6 | CHECK `state='superseded' ⇒ superseded_at IS NOT NULL` |
| I7 | `school_id = session_school_id(session_id)` — enforce ở RPC **và** RLS WITH CHECK |
| I8 | `profile_id` cùng school **và** `profiles.state='active'` tại thời điểm tạo dòng active mới (không áp cho `superseded`) |
| I9 | **Không hard-delete.** RLS từ chối DELETE hoàn toàn |

Index: `(session_id, dimension, state)` · `(profile_id, dimension, state)` · `(school_id, dimension, state)`.

### 8.3 `child_observations` — thêm actor (E3-07)

```
recorded_by  uuid NULL → profiles(id) ON DELETE RESTRICT   -- bất biến sau creation
updated_by   uuid NULL → profiles(id) ON DELETE RESTRICT   -- actor sửa gần nhất
```

Trigger derive từ `current_profile()`, client không giả mạo được (cùng cơ chế §4.1). **Legacy 5 dòng giữ `recorded_by = NULL`. Không backfill. Không suy diễn.** Đổi teacher assignment **không** đổi hai trường này.

Phân biệt rõ 4 khái niệm — **không dùng một field `owner`**: attendance/evidence recorder · last editor · responsible teacher · actual teacher.

---

## 9. MIGRATION 105 BOUNDARY

### 9.1 Must ship (20 mục theo Owner §11)

Assignment source of truth · planned tạo atomically trong `create_lesson_session` · responsible assignment · actual confirmed model (không fabricate legacy) · start-actor evidence semantics · conservative backfill · FK RESTRICT · hard-delete removal/cutover · media upload authz · remote capture authz · journal submission authz · observation actor · observation authz · **E3-08 containment** · **E3-09 containment** · `profiles.state='active'` guard · protect `profiles.state` self-update · assignment/audit history · explicit grants/RLS (D15) · DB verification guards (D92 BLOCK 3).

### 9.2 May ship

Bulk reassign future unstarted sessions · candidate evidence infrastructure cho `start_session` **tương lai** (nếu cách ly tuyệt đối khỏi actual confirmed) · compatibility view cho legacy `session_teachers`.

### 9.3 Deferred

Parent-facing attribution display · payroll/workload · full teacher offboarding · advanced co-teaching UI · multi-person approval · destructive cleanup / drop legacy columns · rename `taught_by` · drop `session_teachers.role` · dead `rescheduled` enum cleanup.

### 9.4 Cấu trúc D92

**BLOCK 1 DDL** — bảng + constraint + index · ALTER FK · `COMMENT ON COLUMN` · cột `child_observations` · trigger containment · resolver + RPC · RLS + policy · backfill idempotent (`WHERE NOT EXISTS`).
**BLOCK 2 REVOKE/GRANT** — `REVOKE ALL FROM PUBLIC` + `GRANT EXECUTE TO authenticated` từng hàm (D15: `CREATE OR REPLACE` reset grants về PUBLIC) · column-level REVOKE trên `learning_moments` · verify bằng `aclexplode(coalesce(p.proacl, acldefault('f', p.proowner)))`.
**BLOCK 3 VERIFY** — 13 con số + 3 số legacy=0 (§6) + kiểm 0 duplicate primary / 0 cross-school; sai ⇒ `RAISE EXCEPTION` ⇒ rollback atomic.

⚠️ **D289:** `apply_migration` thành công **không** nghĩa là client gọi được RPC mới. Gửi `notify pgrst` và verify bằng browser thật (D291) trước khi tuyên bố PASS.

---

## 10. EXACT DB OBJECTS / FUNCTIONS BỊ THAY

### 10.1 Tạo mới

| Loại | Tên |
|---|---|
| Bảng | `session_teacher_assignments` |
| Resolver | `session_planned_primary(uuid)` · `session_confirmed_actual(uuid)` · `session_responsible(uuid)` · `session_actual_candidates(uuid)` |
| RPC | `set_session_planned_teacher` · `confirm_session_actual_teacher` · `set_session_responsible_teacher` · `correct_session_assignment` · `bulk_reassign_future_sessions` *(may ship)* |
| Trigger fn | `guard_learning_moments_actor()` · `guard_child_observations_actor()` |
| Trigger | `trg_guard_learning_moments_actor` (BEFORE INSERT OR UPDATE) · `trg_guard_child_observations_actor` (BEFORE INSERT OR UPDATE) |

### 10.2 CREATE OR REPLACE

| Function | Đổi gì |
|---|---|
| `create_lesson_session` | **[DB] hiện không ghi planned từ `cd.lead_teacher_id`** — chỉ ghi `p_teacher_ids` thành `'assist'`. Phải materialize planned primary atomically |
| `set_session_teachers` | Bỏ hard-delete → `superseded` + dòng mới; chặn normal-edit sau khi session bắt đầu |
| `set_distribution_lead` | Không còn ảnh hưởng session lịch sử; sinh planned cho session tương lai chưa bắt đầu |
| `assign_class_distribution` | Đồng bộ với trên |
| `start_session` | `taught_by` giữ nguyên semantics start-actor; **không** sinh actual confirmed |
| `check_session_media_upload_access` | `cd.lead_teacher_id OR session_teachers` → participation/assignment + `profiles.state='active'` |
| `check_remote_capture_access` | như trên (EXECUTE hiện chỉ cho `postgres, service_role`) |
| `submit_session_journal` | `is_session_lead` → `session_responsible()` |
| `guard_profiles_protected_cols` | **thêm ghim `state`** (E3-12) |
| `is_session_lead` · `is_distribution_lead` | Giữ — đúng mục đích *distribution lead*. **Không** dùng cho session authority |
| `is_session_teacher` | → participation qua bảng mới |
| `user_class_ids` | distribution lead ∪ participation |

### 10.3 Read paths phải sửa (WP5)

`get_school_week_schedule` · `get_session_detail` · `get_session_readiness` · `get_teacher_home` · `get_teacher_classes` · `get_teacher_todo_counts` · `get_teacher_journals`

⬜ Cần phân loại từng chỉ số: `get_admin_action_center` · `get_admin_health_score` · `admin_lookup_user`.

### 10.4 ALTER / GRANT

- `session_teachers.profile_id` FK CASCADE → **`ON DELETE RESTRICT`**
- `COMMENT ON COLUMN lesson_sessions.taught_by`
- `COMMENT ON COLUMN session_teachers.role` — deprecated
- `child_observations` + `recorded_by`, `updated_by`
- `REVOKE` column-level trên `learning_moments` (§4.1 lớp 3)

**Không đụng:** `learning_moments` SELECT policy (consent gate) · `moment_children` · `media_assets` · toàn bộ Parent/Kid RPC.

---

## 11. EXACT FRONTEND FILES BỊ THAY

| File | WP | Thay gì |
|---|---|---|
| `teacher.session.$id.tsx` | **WP1** | **Gỡ `uploaded_by` khỏi INSERT payload** (bắt buộc cùng nhịp với REVOKE cột) |
| `teacher.session.$id.tsx` | WP4/WP6 | `StepReview` bỏ suy luận `get_teacher_classes.is_lead` → dùng capability từ session detail; sửa 2 câu *"Chỉ giáo viên phụ trách buổi mới gửi được nhật ký."* |
| `school.manage.tsx` | WP6 | 🔴 **Xoá/viết lại** *"Đổi giáo viên chính chỉ áp dụng cho buổi tạo mới, không thay đổi buổi đã xếp."* · `DistributionRowItem` thêm confirm + phạm vi ảnh hưởng |
| `school.schedule.tsx` | WP6 | *"Người gửi nhật ký cho buổi là Giáo viên chính của môn…"* → responsible teacher |
| `teacher.classes.tsx` | WP6 | *"Các lớp cô phụ trách"* — phân biệt phụ trách **lớp** vs được xếp dạy **buổi** |
| `teacher.index.tsx` · `teacher.journal.tsx` · `teacher.moments.tsx` | WP5/WP6 | ⬜ chờ đọc toàn văn ở đầu WP5 |
| `parent.*` · `features/journey/*` | — | ❌ **KHÔNG ĐỔI** — regression-test only |

**D8/D95/D117 áp dụng:** paste-over toàn file, đọc `createFileRoute(...)` xác nhận đích, `read_file` verify sau mỗi paste (Lovable nuốt ký tự `<` cuối dòng).

---

## 12. CONSERVATIVE BACKFILL

**[DB]** 8 session:

| state | n | có `taught_by` |
|---|---|---|
| `scheduled` | 2 | 0 |
| `cancelled` | 2 | 0 |
| `in_progress` | 2 | 1 |
| `taught_report_pending` | 1 | 1 |
| `completed` | 1 | 1 |

| Nhóm | planned | actual | responsible |
|---|---|---|---|
| `scheduled` ×2 | ✅ từ `cd.lead_teacher_id`, `legacy_backfill`, `confirmed` | ❌ | ✅ = planned primary |
| `cancelled` ×2 | ✅ (giữ lịch sử planned) | ❌ **không bao giờ** | ❌ |
| `in_progress` ×2 | ✅ | ❌ | ✅ = planned primary |
| `taught_report_pending` ×1 · `completed` ×1 | ✅ | ❌ **10-B** | ✅ = planned primary |

- `cd.lead_teacher_id IS NULL` ⇒ **không tạo dòng nào** — vắng mặt dòng active planned/primary = *explicit unassigned*. Không tạo teacher giả. (Hiện cả 8 session đều có lead; resolver vẫn phải xử lý được nhánh này.)
- `session_teachers` 2 dòng → `dimension='planned'`, `participation_role='co_teacher'` (**không** `primary` — dòng `role='lead'` không có evidence là primary), `source='legacy_backfill'`.
- `child_observations` 5 dòng → `recorded_by = NULL`. **Không backfill.**
- `learning_moments` → `uploaded_by` non-null giữ nguyên, null giữ null. **Không rewrite.**

**Idempotent** (`WHERE NOT EXISTS`), rerun an toàn.

**13 con số báo trước/sau:** total · future · in_progress · completed · cancelled · planned created · explicit unassigned · actual confirmed · actual unconfirmed · invalid/cross-school candidates · orphaned teacher refs · duplicate primary · rows skipped + lý do.

---

## 13. QA MATRIX

### 13.1 Security — E3-SG-01 (8 điều kiện §4.3) — **gate cứng**

| # | Test | Tài khoản |
|---|---|---|
| S1 | INSERT moment với `uploaded_by` = profile khác ⇒ bị override hoặc reject | GV KHM Mỹ Linh `gv.linh.kidshouse@demo.demenart.com` / `Test@123` |
| S2 | UPDATE `uploaded_by` moment đã có ⇒ reject | như trên |
| S3 | UPDATE `state='approved'` trực tiếp ⇒ reject | như trên |
| S4 | Gửi journal khi không phải responsible ⇒ `forbidden` | GV MNDM Ngọc Hân `gv.han.demen@demo.demenart.com` / `Test@123` |
| S5 | INSERT moment với `class_id` trường khác ⇒ reject | GV Mỹ Linh (KHM) trỏ sang MNDM |
| S6 | PH không thấy moment chưa approved | PH KHM Nguyễn Văn Hùng `ph.hung.kidshouse@demo.demenart.com` / `Test@123` |
| S7 | Edge `upload_media` (service-role) vẫn derive actor từ JWT, không bypass | GV Mỹ Linh |
| S8 | Consent MIN-multi-child vẫn chặn ký URL như trước | PH MNDM Văn Thành `ph.thanh.demen@demo.demenart.com` / `Test@123` |

### 13.2 Attribution & assignment

| # | Test | Tài khoản |
|---|---|---|
| A1 | Đổi GV chính distribution ⇒ **GV cũ giữ** quyền upload/gửi journal buổi đã dạy | Master KHM Nguyệt Thi `hieutruong.kidshouse@demo.demenart.com` / `Test@123` |
| A2 | Đổi GV chính ⇒ GV mới **không** có quyền trên buổi lịch sử | GV Lê Thảo My `gv.my.kidshouse@demo.demenart.com` |
| A3 | Reassign ⇒ dòng cũ `superseded`, **không** biến mất | Nguyệt Thi |
| A4 | Không reassign được session `completed`/`cancelled` bằng đường thường | Nguyệt Thi |
| A5 | `recorded_by` observation mới = actor thật, bất biến | GV Ngọc Hân |
| A6 | `updated_by` đổi khi sửa, `recorded_by` **không** đổi | GV Ngọc Hân |
| A7 | Profile `state<>'active'` ⇒ không nhận assignment mới | Master MNDM Phương Dung `hieutruong.demen@demo.demenart.com` / `Test@123` |
| A8 | Non-admin không tự sửa `profiles.state` của mình (E3-12) | GV Ngọc Hân |
| A9 | Xoá profile còn assignment ⇒ **RESTRICT** chặn | SQL (D1 audit-only) |

### 13.3 Regression — không được đổi

| # | Test | Tài khoản |
|---|---|---|
| R1 | Parent Journal timeline giống hệt trước 105 | PH Hùng · PH Thành |
| R2 | Parent Home / child switcher / `?focus` deep-link | PH Hùng |
| R3 | Kid album | — |
| R4 | Ghi chú nội bộ *"không gửi cho ba mẹ"* vẫn không rò | GV Mỹ Linh → PH Hùng |
| R5 | Nhật ký gửi lại (idempotent branch) vẫn duyệt ảnh bổ sung | GV Mỹ Linh |
| R6 | Lịch tuần trường + Teacher Home đếm đúng | Nguyệt Thi · GV Mỹ Linh |
| R7 | `/kid` namespace không bị chạm | — |

**Không claim PASS trước security evidence.** WP1 phải xanh đủ 8 điều S1–S8 trước khi mở WP2.

---

## 14. P2 BACKLOG

| | Mục |
|---|---|
| 1 | **Parent Artifact Attribution Experience** (E3-11) — phân biệt 5 vai, không hiển thị distribution lead như historical teacher |
| 2 | Rename `taught_by → started_by` (add → dual-write → deprecate) |
| 3 | Drop `session_teachers` + cột `role` sau ≥1 sprint compatibility |
| 4 | Dead enum `rescheduled` — gỡ khỏi legend `school.schedule.tsx` + `school.manage.tsx`, rồi khỏi enum |
| 5 | Full teacher offboarding UI + phát hiện future session của profile bị deactivate |
| 6 | Advanced co-teaching UI · multi-person approval · payroll/workload |
| 7 | `moment_children` DELETE hard — gỡ gắn bé không để lại vết |
| 8 | `lesson_sessions.class_distribution_id → class_distributions ON DELETE CASCADE` — xoá distribution xoá sạch session |
| 9 | Phân loại chỉ số ownership trong `get_admin_action_center` · `get_admin_health_score` · `admin_lookup_user` |
| 10 | Đọc toàn văn `teacher.index/classes/journal/moments.tsx` · `parent.index.tsx` · `features/journey/*` cho UI wording |
| 11 | Đối chiếu 13 moment `approved_by IS NULL` với `state` — xác định có dấu vết lạm dụng SG-d hay không |

---

## 15–17. TRẠNG THÁI

| | |
|---|---|
| **15 · HEAD** | `7ee7eeba` — **unchanged** |
| **16 · Migration 105** | **not created, not applied**. Migration cao nhất vẫn là 104 |
| **17 · Code** | **no code changed**. Không `send_message`, không `apply_migration`, không deploy |

Mọi truy vấn trong Phase 1 là `execute_sql` **read-only** (`select` / `pg_get_functiondef` / `pg_policies` / `information_schema`) và `read_file` (miễn phí). Không mutation nào được thực hiện.

---

## GATE

**OG-E3-PHASE1-FINAL — APPROVED.** Addendum này **không phát sinh Stop-Gate mới**.

➡️ Được vào **Phase 2 · WP1 — Security containment** (E3-08 · E3-09 · profile-state protection · tests).

---

*Sinh trong V114B-E3 Phase 1 · HEAD `7ee7eeba` · migration 104 · chưa chạm code.*
