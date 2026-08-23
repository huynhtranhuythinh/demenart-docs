# DMA V114B-E3 — WP2 IMPLEMENTATION READINESS PACK

**Loại:** readiness only · 0 migration · 0 code · 0 apply · 0 deploy · 0 canonicalize
**Đo live:** 21/07/2026 · project `xcvhacymrbhdhohyylyq` · repo HEAD `d9d56000…`
**Vào:** WP1 FORMALLY PASS/CLOSED · HEAD `85e24768` · migration inventory **106**
**Ra:** migration inventory **106** — không đụng gì

> **VERDICT: READY FOR S0A — CONDITIONAL.** Điều kiện duy nhất còn lại: đóng nốt residual Edge sweep (§B.3). Data model, schema, sequence và invariant đã đủ chốt để implement.

---

## A. WP1 CLOSEOUT RECONCILIATION

Đã đọc `DMA_V114B_E3_WP1_CLOSEOUT.md` đầy đủ (§1–§9). Mọi khẳng định được **đo lại trên live**, không tin tài liệu (D1).

### A.1 Đối chiếu từng invariant

| Closeout khẳng định | Đo live | Kết quả |
|---|---|---|
| migration 105 `20260721094857` md5 `30f29f7f94c300a0ad234ec8ec5cadf1` | `30f29f7f94c300a0ad234ec8ec5cadf1` | ✅ byte-identical |
| migration 106 `20260721104516` md5 `b4446fd46ab3b3f96a25e41f110ad979` | `b4446fd46ab3b3f96a25e41f110ad979` | ✅ byte-identical |
| migration inventory 106 | **106** | ✅ |
| `dma_write_is_privileged` SECURITY **INVOKER** | `prosecdef = false` · owner `postgres` | ✅ |
| `guard_learning_moments_actor` INVOKER | `prosecdef = false` | ✅ |
| `guard_child_observations_actor` INVOKER | `prosecdef = false` | ✅ |
| `guard_profiles_protected_cols` DEFINER | `prosecdef = true` · trigger `trg_guard_profiles_protected` BEFORE UPDATE live | ✅ |
| `learning_moments` table-level INSERT revoked khỏi `authenticated` | `has_table_privilege = false` | ✅ |
| `uploaded_by` không client nào ghi được | `has_column_privilege(…,'uploaded_by','INSERT') = false` | ✅ |
| `child_observations.recorded_by` · `updated_by` tồn tại | cả 2 cột live, cuối bảng | ✅ |
| `learning_moments` = 22 | **22** | ✅ |
| `approved` + `approved_by` NULL = 6 | **6** | ✅ |
| `uploaded_by` NULL toàn bảng = 0 | **0** | ✅ |
| `child_observations` = 9 | **9** | ✅ |
| `recorded_by` NULL (legacy) = 5 | **5** | ✅ |

### A.2 ANOMALY-1 — forensic invariant

| | Closeout §4.3 | Live 21/07 |
|---|---|---|
| id | `f51039be-48e8-42c5-9900-b03f3472cd1f` | idem |
| state | `approved` | `approved` |
| `approved_by` | NULL | **NULL** |
| `updated_at` | `2026-07-09 07:31:01.160368+00` | `2026-07-09 07:31:01.160368+00` |

**Không đổi một byte.** WP2 **không được** chạm bản ghi này, không backfill, không dùng làm fixture.

### A.3 Parent SELECT / consent invariants

`learning_moments_select_school_or_parent` phải giữ byte-identical:

```
(same_school(class_school_id(class_id)) OR (is_moment_parent(id) AND (state = 'approved'::moment_state)))
```

WP2 **không đụng**: `media_consent_check` · `get_signed_media_url` v23 · consent data · Parent RPC · media signing. Không có bước nào trong S0A–S5 chạm các bề mặt này. QA phải chứng minh zero-delta (§L·Q17).

**QA debt kế thừa, không đóng trong WP2:** `CONSENT-NEGATIVE-FIXTURE` (approved single-child moment với child thiếu `display_in_app`). Ba bé thiếu `display_in_app` (Bé Jimmy Demo · Bùi Yến Nhi · Trịnh Khánh Vi) đều không có moment single-child. WP2 không tạo và không sửa fixture này.

### A.4 E3-SG-01 — trạng thái được giữ nguyên

> **PARTIALLY CONTAINED; AUTHORITY SEMANTICS PENDING WP4**

| Điều kiện | WP1 | WP2 làm gì |
|---|---|---|
| 1 · không giả mạo `uploaded_by` | ✅ | không đụng |
| 2 · không sửa `uploaded_by` sau creation | ✅ | không đụng |
| 3 · không tự approve từ client | ✅ | không đụng |
| 4 · **approve phải có đúng session responsibility** | ⛔ PENDING WP4 | **KHÔNG đóng.** Xem §I |
| 5 · không cross-school | ✅ | mở rộng sang assignment |
| 6 · Parent không thấy unapproved metadata | ✅ | không đụng |
| 7 · service-role path không bypass | ✅ | mở rộng sang assignment (§K) |
| 8 · media/consent PASS | ✅ compensating | không đụng |

Closeout ghi rõ điều kiện 4 vẫn phụ thuộc `is_session_lead` (hồi tố). **WP2 gỡ hồi tố ở lớp assignment ownership nhưng KHÔNG gỡ ở lớp journal authority** — xem §I. Không được viết `E3-SG-01 CLOSED` ở bất kỳ artifact nào của WP2.

### A.5 Candidate rules — kế thừa, chưa canonicalize

| Mã tạm | Áp dụng vào WP2 như thế nào |
|---|---|
| **D310-cand** | Thu quyền ghi phải `REVOKE ... ON TABLE` **trước** rồi `GRANT (cols)`. Verify bằng `has_table_privilege` **và** `has_column_privilege`, không dùng `information_schema.column_privileges`. → áp cho S0A và S4. |
| **D311-cand** | Guard trigger function của WP2 **bắt buộc SECURITY INVOKER**; migration phải có guard `prosecdef = false`. Dùng lại `dma_write_is_privileged()` sẵn có, **không tạo hàm detection thứ hai**. |
| **D312-cand** | `service_role` có `BYPASSRLS = true` ⇒ containment phải ở **tầng trigger**; RLS là lớp phụ. → mọi invariant §I phải có trigger, không chỉ RLS. |

D310/D311/D312 giữ nguyên trạng thái **candidate**. WP2 không gán D-number canonical. Nếu WP2 sinh rule mới, cũng ghi dạng `-cand` và gộp một lần ở E3 milestone closeout.

### A.6 Boundary WP2 không được vượt

Kế thừa từ closeout §9 + chỉ thị revision:

- ❌ không đóng E3-SG-01
- ❌ không chuyển journal authority (WP4)
- ❌ không tạo actual assignment · không tạo responsible assignment
- ❌ không đổi `lesson_sessions.taught_by` (rename/backfill/reinterpret)
- ❌ không suy actual teacher từ `taught_by` hoặc từ `state`
- ❌ không drop legacy `session_teachers` · không repurpose `session_teachers.role`
- ❌ không chạm Parent attribution (E3-11 vẫn deferred — backlog "Parent Artifact Attribution Experience")
- ❌ không chạm ANOMALY-1
- ❌ không canonicalize RULES / SYSTEM_MAP
- ❌ không mở WP3/WP4

---

## B. DEPENDENCY SWEEP

### B.1 Frontend — **ĐÓNG**

Đọc đầy đủ, không đoán:

| File | dòng | `session_teachers` | `class_distributions` | assignment RPC |
|---|---|---|---|---|
| `school.schedule.tsx` | ~900 | **direct READ** `.from("session_teachers").select("profile_id").eq("session_id",…)` | direct READ `.eq("state","active")` | `create_lesson_session` · `set_session_teachers` · `update_lesson_session` · `cancel_lesson_session` |
| `school.manage.tsx` | 2424 | ❌ NEGATIVE | direct READ `.eq("class_id",…).eq("state","active")` | `set_distribution_lead` · `assign_class_distribution` |
| `teacher.session.$id.tsx` | ~1200 | ❌ NEGATIVE | ❌ (gián tiếp qua `get_teacher_classes`) | ❌ |
| `teacher.classes.tsx` | ~250 | ❌ NEGATIVE | ❌ | ❌ |

**Kết luận frontend: 0 direct WRITE `session_teachers`. Đúng 1 direct READ.** Mọi ghi assignment đi qua RPC.

Direct write khác trong `teacher.session.$id.tsx` (ngoài phạm vi assignment, ghi nhận để không bất ngờ ở QA): `prep_items` UPDATE · `child_observations` UPSERT · `moment_children` INSERT/DELETE · `learning_moments` INSERT/UPDATE caption · `support_requests` INSERT.
Direct write trong `school.manage.tsx`: `classes` INSERT · `profiles` INSERT (thêm GV).

### B.2 Edge Functions — đã đọc đầy đủ 4/16

| Slug | v | `verify_jwt` | Kết quả |
|---|---|---|---|
| `capture_session_media` | 4 | **true** | **NEGATIVE** — stub SEC0 fail-closed, 503 `remote_capture_temporarily_disabled`. Không parse body, không ghi storage/DB/audit, không attribution. |
| `capture_session_moment` | 4 | false | **NEGATIVE** — stub deprecated, 410 `use: capture_session_media`. Giết bề mặt anon cũ. |
| `delete_session_media` | 4 | false | **POSITIVE (capability consumer)** — `svc.rpc("check_session_media_upload_access", {p_session_id, p_viewer_profile})` bằng **service_role**. Không đọc/ghi `session_teachers` trực tiếp. Có `svc.from("session_media").delete()` (hard-delete link, ngoài phạm vi assignment). |
| `upload_media` | 19 | false | **POSITIVE (capability consumer)** — NHÁNH C gọi cùng `check_session_media_upload_access` bằng service_role; ghi `media_assets` + `session_media`. Không đọc/ghi `session_teachers` trực tiếp. Sáu nhánh còn lại (A/B/D/E/F/G) không chạm session assignment. |

**Kết luận từng phần:** hai positive hit **không** phải writer — chúng là **capability consumer gián tiếp qua đúng một RPC** (`check_session_media_upload_access`). Vì vậy khi S3 thêm filter vào RPC đó, cả hai Edge thừa hưởng tự động, **không cần sửa Edge code**. Đây là kết quả tốt và làm hẹp bề mặt cutover.

### B.3 Residual Edge sweep — **CHƯA ĐÓNG — điều kiện của S0A**

Còn 12/16 chưa đọc:

`get_signed_media_url` (v23) · `school_media_admin` · `kid_gate` · `purge_trash` · `resolve_share_link` · `invite_master` · `invite_staff` · `invite_parent` · `accept_parent_invitation` · `accept_family_invitation` · `upload_notification_sound` · `upload_kid_game_sound`

Em **không** kết luận chúng sạch dựa trên tên. Không có công cụ grep trên Edge source từ môi trường này — mỗi file phải fetch và đọc. Em dừng ở 4 file có bề mặt session để không tiêu hết ngân sách phiên trước khi giao pack.

**Phân loại rủi ro có căn cứ (không phải kết luận):**

| Nhóm | Slug | Vì sao vẫn phải đọc |
|---|---|---|
| Cao | `school_media_admin` · `kid_gate` · `purge_trash` · `get_signed_media_url` | có service-role client, có khả năng đọc session/class scope |
| Trung | `invite_staff` · `invite_master` | ghi `profiles` — chạm `state`/`role`, tức chạm điều kiện hợp lệ của assignee |
| Thấp | 6 file còn lại (invite/accept PH-gia đình, 2 upload asset) | không có bề mặt session/assignment đã biết |

**Ràng buộc:** residual sweep phải PASS **trước khi apply S0A**, không phải trước khi chốt data model. Nếu phát hiện service-role writer ẩn, nó chỉ **thêm** vào danh sách consumer/writer — không đổi §D/§E/§J.

---

## C. DEFECT MATRIX (cập nhật)

### P0 — SECURITY / AUTHORIZATION

| ID | Mô tả | Bằng chứng live |
|---|---|---|
| **WP2-P0-1** | Direct-table write path vòng qua `set_session_teachers`. `authenticated` + `anon` giữ **full table DML** trên `session_teachers`; RLS có đủ policy INSERT/UPDATE/DELETE. | `has_table_privilege('authenticated','session_teachers','INSERT') = **true**` · `has_table_privilege('anon','session_teachers','DELETE') = **true**` — **đối lập trực tiếp** với `learning_moments` INSERT = `false` sau WP1 |
| **WP2-P0-2** | Uỷ quyền lệch RPC ↔ RLS. RPC: `is_admin() OR master/sub_admin cùng school`. RLS: **thêm `is_session_lead()`**. Lead teacher không gán được qua RPC nhưng gán được qua PostgREST. | so sánh `set_session_teachers` vs `session_teachers_insert_lead_or_schooladmin` |
| **WP2-P0-3** | RLS không enforce `profiles.state='active'` và không enforce role. Chỉ check `profile_school_id(profile_id) = session_school_id(...)`. Direct path gán được profile inactive hoặc `master_admin`/`sub_admin` làm "giáo viên". | policy `with_check` |
| **WP2-P0-4** | RLS không check `lesson_sessions.state`. RPC chặn `completed`/`cancelled`/`taught_report_pending`/`report_pending_approval`; RLS không. ⇒ sửa/xoá phân công của buổi đã đóng. | policy `qual` vs RPC `bad_state` |

> P0-1…4 là **cùng một lỗ**: `session_teachers` chưa bao giờ được đóng thành RPC-only. WP1 đã làm đúng việc này cho `learning_moments`; đây là bề mặt tương đương chưa xử lý. **S0A đóng cả bốn.**

### P1 — SEMANTIC / HISTORY / INTEGRITY / PRODUCT-TRUTH

| ID | Mô tả | Bằng chứng live |
|---|---|---|
| **WP2-P1-1** | Hard-delete xoá sạch lịch sử phân công. | audit `d5d09c47` 21/07 06:42:25 — `{removed:1, teacher_ids:[]}` trên session `8dcf9f2e`. **Danh tính người bị gỡ không phục hồi được.** 15 giây sau gán `…014` |
| **WP2-P1-2** | Hàng phân công không có actor, không có thời điểm gỡ. Chỉ `created_at`. | schema: `id, session_id, profile_id, role, created_at` |
| **WP2-P1-3** | Planned teacher không materialize khi tạo buổi. 6/8 buổi có 0 hàng; **7/8 buổi có lead không nằm trong `session_teachers`**. | count live |
| **WP2-P1-4** | Lịch sử bị rewrite hồi tố bởi current distribution lead. | `set_distribution_lead` chạy 2 lần 21/07: 06:53:13 → `…013`, 06:55:04 → `…011`. Trong 111 giây, mọi buổi lịch sử của distribution `…031` (gồm 1 `completed` + 2 `taught_report_pending`) được quy cho Ngọc Hân |
| **WP2-P1-5** | Assignment presence = live capability. 9 secdef reader + 2 Edge coi hàng `session_teachers` là quyền hiện tại. **Ngừng xoá mà chưa cutover consumer = GV bị gỡ giữ quyền vĩnh viễn** (hình dạng D288). | §H |
| **WP2-P1-6** | `start_session` audit rỗng. Payload dùng key `session_id`/`actor`; `write_audit_log` chỉ đọc `actor_id`/`entity_id`/`entity_type`/`metadata`. | 3/3 hàng `session_started` có actor_id NULL · entity_id NULL · metadata NULL |
| **WP2-P1-7** | FK `session_teachers.profile_id ON DELETE CASCADE` — xoá 1 profile là xoá âm thầm toàn bộ lịch sử phân công. | `pg_constraint` |
| **WP2-P1-8** | Guard không đọc `profiles.state`: `is_session_lead`, `is_session_teacher`, `is_distribution_lead`, `current_profile`, `user_school_ids`. (= V114A-P1-6, vẫn mở.) **Ranh giới:** active cho *assignment actor* = WP2; active trong *authority guard* = WP4. | function bodies |
| **WP2-P1-9** | Picker giáo viên thiếu `state='active'` — **4 control ở 2 file**. Cửa chắc chắn dẫn tới `teacher_invalid` = **D290**. | §C.1 dưới |
| **WP2-P1-10** ⭐ | **PRODUCT-TRUTH DEFECT.** Copy production `school.manage.tsx` khẳng định: *"Giáo viên chính là người gửi nhật ký của môn. Đổi giáo viên chính chỉ áp dụng cho buổi tạo mới, không thay đổi buổi đã xếp."* Backend **vi phạm** vế thứ hai. Đây là product contract hiện hành đang bị phá. | copy live + P1-4 |
| **WP2-P1-11** ⭐ | **Hai writer `lead_teacher_id` không đồng nhất.** `assign_class_distribution` **không** kiểm `pr.state='active'`; `set_distribution_lead` **có**. ⇒ distribution có thể sinh ra với lead inactive, và snapshot planned-primary sẽ kế thừa actor vi phạm ngay tại nguồn. | §G |
| **WP2-P1-12** ⭐ | **Frontend tự suy quyền gửi nhật ký.** `teacher.session.$id.tsx` StepReview tính `leadOfThis = rows.some(c => c.is_lead && c.sessions.some(s => s.id === session.id))` từ `get_teacher_classes`. Client tự dựng authority từ `class_distributions.lead_teacher_id` hiện tại. | code live |

### C.1 Picker inventory (P1-9) — chính xác từng control

| # | File | Control | Query | Thiếu |
|---|---|---|---|---|
| 1 | `school.schedule.tsx` | `loadRefs()` → `teachers` (dùng cho **Create panel** + **Detail panel**) | `.from("profiles").select("id, full_name, email, role").in("role",["lead_teacher","assistant_teacher"]).order("full_name")` | `state='active'`; school chỉ dựa RLS ngầm |
| 2 | `school.manage.tsx` | `ClassSubjectsPanel.loadAll()` → `teachers`, dùng ở **"Rót môn vào lớp" → GV chính** | `.from("profiles").select("id, full_name, email, role, state, user_id").in("role",["lead_teacher","assistant_teacher"])` | có select `state` nhưng **không filter**; school ngầm |
| 3 | `school.manage.tsx` | `DistributionRowItem` → **"Lưu GV chính"** (dùng chung mảng `teachers` của #2) | idem #2 | idem |
| 4 | `school.manage.tsx` | `TeachersTab.load()` → danh sách nhân sự | `.in("role",["lead_teacher","assistant_teacher","sub_admin"])` | không filter `state` (đây là màn quản lý — hiển thị inactive **hợp lệ**; chỉ cần nhãn trạng thái, **không** phải picker) |

**Yêu cầu S3:** #1, #2, #3 phải lọc `same school` + `state='active'` + `role ∈ {lead_teacher, assistant_teacher}` (riêng picker GV chính của distribution: tập role theo `set_distribution_lead` là `{lead_teacher, assistant_teacher, sub_admin, master_admin}` — **phải khớp đúng RPC, không rộng hơn, không hẹp hơn**). #4 giữ nguyên nhưng thêm nhãn trạng thái.

### P2 — CLEANUP / DEPRECATION (không chặn build)

| ID | Mô tả |
|---|---|
| **WP2-P2-1** | `session_teachers.role` không consumer. 1 hàng `lead` legacy trên buổi completed (`2fab0c56`). Cả 2 writer hardcode `'assist'`. **Không drop.** |
| **WP2-P2-2** | Không index `session_teachers(profile_id)` — mọi read "buổi của tôi" seq-scan. |
| **WP2-P2-3** | `lesson_sessions.taught_by` 3/8 populated, 0 consumer. Phân loại **start-actor evidence**. Giữ nguyên. |
| **WP2-P2-4** | Buổi `aaaa…0003` `in_progress` nhưng `taught_by` NULL — state seed trực tiếp. Bằng chứng **state ≠ actor truth**. |
| **WP2-P2-5** | `anon` giữ full DML grant trên `lesson_sessions` + `class_distributions` (S0A chỉ thu trên `session_teachers`). |
| **WP2-P2-6** | `class_distributions` không có unique `(class_id, program_id) WHERE state='active'` — chống trùng chỉ ở application logic (`assign_class_distribution`), có race window. |
| **WP2-P2-7** | `class_distributions` chỉ có `_pkey`; không index `class_id`/`lead_teacher_id`. |

---

## D. CANONICAL SCHEMA — `session_teacher_assignments`

Quan hệ canonical mới. Legacy `session_teachers` **giữ nguyên vật lý**, trở thành compatibility/deprecation surface.

```
public.session_teacher_assignments

id                   uuid        PK   default gen_random_uuid()
session_id           uuid        NOT NULL  FK → lesson_sessions(id)  ON DELETE RESTRICT
profile_id           uuid        NOT NULL  FK → profiles(id)         ON DELETE RESTRICT
school_id            uuid        NOT NULL  FK → schools(id)          ON DELETE RESTRICT
dimension            text        NOT NULL  -- 'planned' | 'actual' | 'responsible'
participation_role   text        NOT NULL  -- 'primary' | 'supporting'
confirmation_status  text        NOT NULL  -- 'planned' | 'confirmed' | 'unconfirmed'
source               text        NOT NULL  -- xem §E.3
state                text        NOT NULL  default 'active'  -- 'active' | 'superseded'
valid_from           timestamptz NOT NULL  default now()
superseded_at        timestamptz NULL
superseded_by        uuid        NULL      FK → profiles(id) ON DELETE RESTRICT
assigned_by          uuid        NULL      FK → profiles(id) ON DELETE RESTRICT
reason               text        NULL
created_at           timestamptz NOT NULL  default now()
```

### D.1 Ghi chú thiết kế bắt buộc

- **`school_id` denormalized có chủ đích.** Không phải tiện lợi — nó cho phép enforce same-school bằng CHECK/trigger **tại chính hàng**, không phải bằng subquery FK-chain có thể trôi khi session đổi distribution. Bất biến sau khi tạo.
- **`dimension` mở sẵn 3 giá trị nhưng WP2 chỉ ghi/đọc `'planned'`.** `'actual'` và `'responsible'` được CHECK chấp nhận nhưng **bị trigger chặn INSERT trong WP2** (§I·I13) để không ai vô tình mở WP3/WP4 bằng một dòng SQL. Gỡ chặn là hành động tường minh của WP3/WP4.
- **`participation_role` tách khỏi legacy `role`.** Không repurpose. Legacy `role ∈ {lead, assist}` không được dùng làm bằng chứng `primary`.
- **`assigned_by` nullable ở cấp cột nhưng NOT NULL theo `source`** — enforce bằng CHECK (§E.2), theo G.4: không fake actor, không sentinel.
- **`superseded_by` + `superseded_at` + `reason` phải cùng có** khi `state='superseded'` — CHECK.
- **`confirmation_status`:** trong WP2 mọi hàng `dimension='planned'` đều `'planned'`. Cột tồn tại để WP3 dùng, không để WP2 diễn giải.

---

## E. CONSTRAINTS · INDEXES · SOURCE/STATE INVARIANTS

### E.1 Constraints

| Tên | Loại | Định nghĩa |
|---|---|---|
| `sta_pkey` | PK | `(id)` |
| `sta_dimension_chk` | CHECK | `dimension IN ('planned','actual','responsible')` |
| `sta_participation_role_chk` | CHECK | `participation_role IN ('primary','supporting')` |
| `sta_confirmation_chk` | CHECK | `confirmation_status IN ('planned','confirmed','unconfirmed')` |
| `sta_state_chk` | CHECK | `state IN ('active','superseded')` |
| `sta_source_chk` | CHECK | `source IN ('distribution_default','manual_assignment','primary_override','legacy_cutover_snapshot','legacy_participation')` |
| `sta_actor_chk` | CHECK | `(source IN ('legacy_cutover_snapshot','legacy_participation') AND assigned_by IS NULL) OR (source NOT IN (...) AND assigned_by IS NOT NULL)` |
| `sta_supersede_chk` | CHECK | `(state='active' AND superseded_at IS NULL AND superseded_by IS NULL) OR (state='superseded' AND superseded_at IS NOT NULL AND superseded_by IS NOT NULL AND reason IS NOT NULL)` |
| `sta_session_fkey` | FK | → `lesson_sessions(id)` **ON DELETE RESTRICT** |
| `sta_profile_fkey` | FK | → `profiles(id)` **ON DELETE RESTRICT** |
| `sta_school_fkey` | FK | → `schools(id)` **ON DELETE RESTRICT** |
| `sta_assigned_by_fkey` | FK | → `profiles(id)` **ON DELETE RESTRICT** |
| `sta_superseded_by_fkey` | FK | → `profiles(id)` **ON DELETE RESTRICT** |

> Mọi FK **RESTRICT**, không CASCADE. Lịch sử phân công không được biến mất vì xoá một profile hay một session. Đây là sửa trực tiếp WP2-P1-7.

### E.2 Indexes

| Tên | Định nghĩa | Vì sao |
|---|---|---|
| `sta_active_person_uidx` | `UNIQUE (session_id, profile_id, dimension) WHERE state='active'` | một người không active hai lần trên cùng session cùng dimension. **Đây là cơ chế concurrency chính** — race do DB quyết, không cần lock |
| `sta_active_primary_uidx` | `UNIQUE (session_id, dimension) WHERE state='active' AND participation_role='primary'` | tối đa **một** primary đang hiệu lực mỗi session mỗi dimension |
| `sta_session_dim_state_idx` | `(session_id, dimension, state)` | resolver "ai của buổi này" |
| `sta_profile_dim_state_idx` | `(profile_id, dimension, state)` | resolver "buổi của tôi" — sửa WP2-P2-2 |
| `sta_school_idx` | `(school_id)` | scope audit |

### E.3 `source` — ngữ nghĩa cố định

| Giá trị | Sinh ra khi | `assigned_by` | `participation_role` |
|---|---|---|---|
| `distribution_default` | `create_lesson_session` snapshot `class_distributions.lead_teacher_id` tại thời điểm tạo session | NOT NULL (actor tạo session) | `primary` |
| `manual_assignment` | teacher IDs được chọn thêm lúc tạo, hoặc `set_session_teachers` sau đó | NOT NULL | `supporting` |
| `primary_override` | RPC riêng đổi primary của **một** session | NOT NULL | `primary` |
| `legacy_cutover_snapshot` | migration S1, chỉ một lần | **NULL** | `primary` |
| `legacy_participation` | migration S1, từ 2 hàng `session_teachers` cũ | **NULL** | `supporting` |

### E.4 State machine

```
(không tồn tại) ──INSERT──▶ state='active'
                              │
                              └──UPDATE──▶ state='superseded'   [TERMINAL]
                                           + superseded_at, superseded_by, reason

CẤM: superseded → active        (gán lại = hàng active MỚI)
CẤM: DELETE ở mọi trạng thái
CẤM: UPDATE bất kỳ cột nào của hàng superseded
CẤM: UPDATE session_id | profile_id | school_id | dimension | source | assigned_by | valid_from | created_at
```

---

## F. LEGACY CUTOVER TRUTH TABLE

Dữ liệu live: **8 session · 2 hàng `session_teachers` · 8 distribution · 0 profile inactive · 0 cross-school · 0 orphan · 0 duplicate**.

Quy tắc (G.2 + LEGACY CUTOVER):
`source='legacy_cutover_snapshot'` · `valid_from = migration timestamp` (**không backdate**) · `assigned_by = NULL` · `reason = 'V114B-E3 WP2 cutover snapshot của current distribution lead tại thời điểm migration. KHÔNG phải bằng chứng planned teacher tại ngày session được tạo.'`

### F.1 Bảng sự thật — 8 session

| # | session_id | state | class · school | current lead | `taught_by` | legacy `session_teachers` | Cutover primary | Cutover supporting |
|---|---|---|---|---|---|---|---|---|
| 1 | `2fab0c56` | `completed` | Lớp Mầm A · `b6a4ac35` | Cô Thúy Ngân `1810667b` | Thúy Ngân | Thúy Ngân `role='lead'` | **⚠️ GATE-1** — nếu snapshot: Thúy Ngân `primary` | — · **MERGED** (xem F.2) |
| 2 | `aaaa…0a0002` | `taught_report_pending` | Hoa Hồng · `d1000000…0001` | Đặng Mỹ Linh `…011` | Mỹ Linh | — | **⚠️ GATE-1** — Mỹ Linh `primary` | — |
| 3 | `aaaa…0a0001` | `taught_report_pending` | Hoa Hồng | Mỹ Linh | Mỹ Linh | — | **⚠️ GATE-1** — Mỹ Linh `primary` | — |
| 4 | `aaaa…0a0003` | `in_progress` | Hoa Hồng | Mỹ Linh | **NULL** | — | Mỹ Linh `primary` | — |
| 5 | `8dcf9f2e` | `cancelled` | Hoa Hồng | Mỹ Linh | NULL | Lê Thảo My `…014` `role='assist'` | **⚠️ GATE-1** — Mỹ Linh `primary` | Lê Thảo My `supporting` · `legacy_participation` |
| 6 | `91bc03d8` | `scheduled` | Hoa Hồng | Mỹ Linh | NULL | — | Mỹ Linh `primary` | — |
| 7 | `3bfb9730` | `scheduled` | Hoa Hồng | Mỹ Linh | NULL | — | Mỹ Linh `primary` | — |
| 8 | `ea85798a` | `cancelled` | Hoa Hồng | Mỹ Linh | NULL | — | **⚠️ GATE-1** — Mỹ Linh `primary` | — |

### F.2 Merge / skip report bắt buộc

| Trường hợp | Xử lý | Lý do |
|---|---|---|
| Session 1 · Thúy Ngân vừa là legacy `role='lead'` vừa là current distribution lead | **MERGE thành 1 hàng** `primary` · `source='legacy_cutover_snapshot'` | Chỉ thị: *"profile trùng cutover primary không được tạo duplicate active assignment"*. Vai `primary` đến từ cutover snapshot, **không** từ `role='lead'` — legacy role không được dùng làm bằng chứng primary |
| Session 5 · Lê Thảo My `role='assist'` | 1 hàng `supporting` · `source='legacy_participation'` · `assigned_by=NULL` | Có bằng chứng tham gia thật; không có bằng chứng ai gán (audit `30e99596` có actor `…010` nhưng đó là actor của lần gán **sau cùng**, không phải của hàng gốc — không suy diễn) |
| Session 5 · người bị gỡ lúc 06:42:25 | **KHÔNG tái tạo** | Danh tính không tồn tại trong bất kỳ nguồn nào (P1-1). Không bịa. Ghi vào migration report là **irrecoverable history loss**, không phải skip |
| Session 4 · `in_progress` nhưng `taught_by` NULL | snapshot primary bình thường | State không phải actor evidence (P2-4). Không suy actual |
| Mọi session | **KHÔNG** tạo `dimension='actual'` | Chỉ thị + §A.6 |

### F.3 Kết quả dự kiến sau S1

| Nếu GATE-1 = "snapshot tất cả 8" | Nếu GATE-1 = "chỉ snapshot session mở" |
|---|---|
| 9 hàng: 8 `primary` + 1 `supporting` | 4 hàng: 3 `primary` (#4,#6,#7) + 1 `supporting` (#5) |
| mọi session có planned primary | 4 session đóng không có planned primary — resolver phải trả "không xác định", **không** fallback về distribution lead |

Cả hai phương án đều **không** rewrite `session_teachers`, **không** đụng `taught_by`, **không** backdate.

---

## G. TẤT CẢ WRITER — DISTRIBUTION LEAD VÀ ASSIGNMENT

### G.1 Writer `class_distributions.lead_teacher_id`

| # | Writer | secdef | Authority gate | school | role | **`state='active'`** | Trạng thái |
|---|---|---|---|---|---|---|---|
| 1 | `set_distribution_lead(p_class_distribution_id, p_lead_teacher_id)` | ✅ | `is_admin() OR (role ∈ {master_admin,sub_admin} AND cùng school)` | ✅ | `{lead_teacher, assistant_teacher, sub_admin, master_admin}` | ✅ **CÓ** | giữ, chuẩn hoá qua shared validator |
| 2 | `assign_class_distribution(p_class_id, p_program_id, p_lead_teacher_id)` | ✅ | idem | ✅ | idem | ❌ **KHÔNG** | **WP2-P1-11 — phải sửa ở S0B** |
| 3 | RLS direct write | — | **không có policy INSERT/UPDATE/DELETE trên `class_distributions`** | — | — | — | ✅ đã đóng sẵn |

**S0B** tạo shared validator `assert_distribution_teacher_valid(p_profile_id, p_school_id)` (hoặc tương đương trả `boolean`/`text` reason) để cả #1 và #2 dùng chung — **không duplicate logic**, tránh drift. Sau mỗi `CREATE OR REPLACE` phải re-run REVOKE/GRANT và verify `aclexplode` (**D15**).

### G.2 Writer assignment

| # | Writer | Bảng | Sau WP2 |
|---|---|---|---|
| 1 | `create_lesson_session` | `session_teachers` INSERT (`role='assist'` hardcode) | **cutover S2** → ghi `session_teacher_assignments`: 1 hàng `primary`/`distribution_default` (nếu distribution có lead) + N hàng `supporting`/`manual_assignment`. Ngừng ghi legacy |
| 2 | `set_session_teachers` | `session_teachers` DELETE + INSERT | **cutover S2** → compatibility writer, **chỉ quản lý planned non-primary**; supersede thay delete. Không chạm primary |
| 3 | **RPC MỚI** `set_session_planned_primary(p_session_id, p_profile_id, p_reason)` | — | **S2** — đường duy nhất đổi planned primary của một session. Actor + reason bắt buộc. `source='primary_override'`. Chỉ tác động đúng 1 session |
| 4 | RLS direct write `session_teachers` | INSERT/UPDATE/DELETE | **S0A đóng** |
| 5 | service-role Edge | — | không có writer nào (§B.2, pending §B.3) |

### G.3 Writer `lesson_sessions.taught_by`

| Writer | Sau WP2 |
|---|---|
| `start_session` | **giữ nguyên hành vi ghi `taught_by`**. Chỉ sửa audit payload (P1-6). Không rename, không backfill, không coi là actual teacher |

---

## H. TẤT CẢ READER / CAPABILITY CONSUMER

### H.1 Đọc `session_teachers` (9 secdef)

| # | Function | Loại | Cutover S3 |
|---|---|---|---|
| 1 | `is_session_teacher(p_session_id)` | **capability guard** — gate `start_session`, mirror prep write | → `session_teacher_assignments` · `dimension='planned'` · `state='active'` |
| 2 | `user_class_ids()` | scope | idem |
| 3 | `check_session_media_upload_access(p_session_id, p_viewer_profile)` | **capability guard** — media upload/delete | idem |
| 4 | `get_teacher_home()` | workspace | idem |
| 5 | `get_teacher_classes()` | workspace + **nguồn của P1-12** | idem + §I |
| 6 | `get_teacher_todo_counts()` | workspace | idem |
| 7 | `get_teacher_journals()` | workspace | idem |
| 8 | `admin_lookup_user(p_profile_id)` | forensic — đếm `session_teacher_rows` | đọc **cả hai** (legacy + canonical), nhãn tách bạch |
| 9 | `session_teachers_select_school` policy | RLS SELECT | giữ (legacy read-only) |

### H.2 Đọc `class_distributions.lead_teacher_id` để resolve **ownership buổi** (phải bỏ ở S3)

| Function | Vị từ hiện tại |
|---|---|
| `get_teacher_home` | `cd.lead_teacher_id = v_profile OR EXISTS(session_teachers…)` |
| `get_teacher_classes` | `cd.lead_teacher_id = v_profile OR EXISTS(…)` |
| `get_teacher_todo_counts` | idem |
| `get_teacher_journals` | idem |
| `check_session_media_upload_access` | `cd.lead_teacher_id = p_viewer_profile` → `is_lead` |
| `is_session_lead(p_session_id)` | `cd.lead_teacher_id = current_profile()` |

**Quy tắc S3:** ownership/history của **một session** resolve từ `session_teacher_assignments`, **không** từ current distribution lead.
**Ngoại lệ có chủ đích:** `is_session_lead` **giữ nguyên** — nó là authority function của journal/approve, thuộc WP4 (§I).

### H.3 Consumer frontend

| Surface | Hiện tại | S3 |
|---|---|---|
| `school.schedule.tsx` Detail panel | `.from("session_teachers").select("profile_id")` | → đọc canonical qua RPC hoặc direct với `dimension='planned' AND state='active'`; **tách primary vs supporting** |
| `school.schedule.tsx` Create panel copy | "Giáo viên tham gia (trợ giảng, ghi nhận)" | phân biệt 3 khái niệm (§I.3) |
| `teacher.classes.tsx` | badge "Trợ giảng" khi `!is_lead` | nguồn `is_lead` đổi sang planned primary của session |
| `teacher.session.$id.tsx` StepReview | `leadOfThis` tự tính | **gỡ** → `can_submit_journal` server-derived (§I) |
| `school.manage.tsx` | copy "chỉ áp dụng cho buổi tạo mới" | copy **giữ nguyên** — S2 làm nó thành đúng |

### H.4 Consumer Edge (service-role)

| Edge | Cơ chế | Cần sửa code? |
|---|---|---|
| `upload_media` NHÁNH C | `svc.rpc("check_session_media_upload_access")` | **KHÔNG** — thừa hưởng từ H.1·#3 |
| `delete_session_media` | idem | **KHÔNG** |
| 12 Edge còn lại | chưa xác định | **§B.3** |

---

## I. JOURNAL-AUTHORITY COMPATIBILITY BOUNDARY

Đây là ranh giới quan trọng nhất của WP2. Ghi rõ để không ai vượt.

### I.1 Hai lớp tách bạch

| | **A — Assignment ownership / read** | **B — Journal submission authority** |
|---|---|---|
| Nguồn sự thật sau WP2 | `session_teacher_assignments` (`planned`/`active`) | **`class_distributions.lead_teacher_id` — GIỮ NGUYÊN** |
| Function | `is_session_teacher` · `user_class_ids` · `check_session_media_upload_access` · 4 RPC teacher | `submit_session_journal` · `is_session_lead` |
| WP2 làm gì | **cutover sang canonical** | **KHÔNG đổi semantics** |
| Hồi tố? | **hết hồi tố** sau S2/S3 | **vẫn hồi tố** — đây là lý do E3-SG-01 điều kiện 4 còn mở |
| Khi nào đổi | — | **WP4**, bằng `dimension='responsible'` |

> **Planned teacher ≠ responsible teacher.** WP2 **không** dùng canonical planned assignment làm journal authority. Không tuyên bố điều kiện 4 của E3-SG-01 đã đóng.

### I.2 `can_submit_journal` — server-derived capability

Vấn đề (P1-12): frontend tự dựng authority từ `get_teacher_classes().is_lead`. Điều đó (a) là inference ở client, (b) trộn hai lớp A và B, (c) sẽ **sai** ngay khi S3 đổi `is_lead` sang planned primary.

**Giải pháp WP2 — capability do server trả, semantics backend không đổi:**

| Hạng mục | Nội dung |
|---|---|
| Nơi trả | `get_session_detail(p_session_id)` — thêm field vào payload hiện có. **Không thêm RPC mới**, không thêm round-trip |
| Field | `can_submit_journal boolean` · `submit_block_reason text NULL` |
| Cách tính | **Mirror chính xác** nhánh authorization của `submit_session_journal` — cùng function, cùng thứ tự, cùng kết quả. Không tái hiện thủ công |
| Ràng buộc | UI và DB phải cho **cùng một kết quả** trong mọi trường hợp (D293: UI gate mirror **mọi** nhánh authorization của RPC, không chỉ nhánh ownership) |
| Frontend | `teacher.session.$id.tsx` gỡ `leadOfThis` + gỡ lời gọi `get_teacher_classes` trong `StepReview.load()`; `canSubmit` đọc thẳng từ `get_session_detail` |
| Giữ nguyên | `submit_session_journal` **không sửa một dòng nào** trong WP2 |

**Phải audit trước khi implement:** đọc `submit_session_journal` và `get_session_detail` đầy đủ ở đầu S2 (chưa đọc trong pack này — cả hai nằm ngoài phạm vi assignment sweep). Nếu `submit_session_journal` có nhánh authorization ngoài `is_session_lead`, `can_submit_journal` phải mirror **hết**.

### I.3 Ba khái niệm phải phân biệt trong copy (S3)

| Khái niệm | Nơi sống | Copy |
|---|---|---|
| **Distribution default teacher** | `class_distributions.lead_teacher_id` | "Giáo viên chính của môn" — mặc định cho buổi **tạo mới** |
| **Planned primary teacher của buổi** | `sta` `planned`/`primary`/`active` | "Giáo viên phụ trách buổi này" |
| **Planned supporting teachers của buổi** | `sta` `planned`/`supporting`/`active` | "Giáo viên tham gia" |

Copy hiện tại của `school.manage.tsx` (*"…chỉ áp dụng cho buổi tạo mới, không thay đổi buổi đã xếp"*) **giữ nguyên nguyên văn** — S2 làm nó trở thành đúng. QA phải chứng minh (§L·Q3).

---

## J. SEQUENCE — S0A → S5

Mỗi stage một migration độc lập theo **D92 ba-block** (DDL → REVOKE/GRANT → VERIFY với `RAISE` làm rollback guard).

### S0A — LEGACY TABLE SECURITY CONTAINMENT
**Điều kiện tiên quyết: §B.3 residual Edge sweep PASS.**

- `REVOKE INSERT, UPDATE, DELETE ON public.session_teachers FROM authenticated, anon` (**table-level trước** — D310-cand)
- `DROP POLICY session_teachers_insert_lead_or_schooladmin` · `_update_…` · `_delete_…`
- **GIỮ** `session_teachers_select_school`
- **CHƯA** thêm trigger cấm DELETE — `set_session_teachers` cũ vẫn dùng DELETE và vẫn phải chạy
- VERIFY: `has_table_privilege` **và** `has_column_privilege` = false cho cả 2 role; `create_lesson_session` + `set_session_teachers` (SECURITY DEFINER, owner `postgres`) vẫn INSERT/DELETE được — probe in-transaction
- **Đóng WP2-P0-1…P0-4.** Backward compatible với frontend hiện tại (chỉ có direct READ, không direct WRITE — §B.1)

### S0B — HARMONIZE DISTRIBUTION-LEAD WRITERS
- Tạo shared validator (same school · `state='active'` · role hợp lệ · profile tồn tại)
- `CREATE OR REPLACE assign_class_distribution` dùng validator → **thêm `state='active'`** (sửa P1-11)
- `CREATE OR REPLACE set_distribution_lead` dùng cùng validator (hành vi không đổi, chỉ khử duplicate logic)
- **Bắt buộc re-run REVOKE/GRANT sau mỗi `CREATE OR REPLACE`** + verify `aclexplode` (D15)
- **Không được bật planned-primary snapshot trước khi S0B PASS**

### S1 — CANONICAL FOUNDATION
- `CREATE TABLE session_teacher_assignments` (§D) + toàn bộ constraint/index (§E)
- Legacy cutover snapshot (§F) — một lần, idempotent, có merge/skip report
- Enable RLS, chỉ policy SELECT; grants tối thiểu (§K)
- **Chưa đổi reader/writer nào**
- VERIFY: row count khớp truth table · 0 duplicate active · 0 cross-school · 0 `assigned_by` sai theo `source` · legacy `session_teachers` **2 hàng nguyên vẹn**

### S2 — WRITER CUTOVER
- `create_lesson_session`: snapshot lead → `primary`/`distribution_default`; teacher IDs → `supporting`/`manual_assignment`; **normalize duplicate profile trước INSERT**; distribution không lead ⇒ **không tạo fake primary**, session explicitly unassigned; atomic cùng session
- `set_session_teachers`: compatibility writer, **chỉ planned non-primary**; supersede thay delete; actor/reason bắt buộc; audit ghi **cả `removed_profile_ids`** (sửa P1-1)
- **RPC mới** `set_session_planned_primary(p_session_id, p_profile_id, p_reason)`
- `start_session`: sửa audit payload → `actor_id` · `entity_type='lesson_session'` · `entity_id=p_session_id` · metadata đầy đủ (sửa P1-6). **Không đổi hành vi `taught_by`**
- `get_session_detail`: thêm `can_submit_journal` + `submit_block_reason` (§I.2)
- Idempotency: gọi lại cùng payload ⇒ `added=0, superseded=0`, **không sinh hàng mới, không sinh audit sai**
- Concurrency: dựa `sta_active_person_uidx` + `sta_active_primary_uidx`, không lock

### S3 — READER + FRONTEND CUTOVER
- 8 secdef reader (§H.1 #1–#8) → canonical, luôn lọc `dimension='planned' AND state='active'`
- Bỏ `cd.lead_teacher_id` khỏi resolve ownership buổi (§H.2) — **trừ `is_session_lead`**
- Frontend: `school.schedule.tsx` (đọc canonical + tách primary/supporting + copy 3 khái niệm) · `teacher.session.$id.tsx` (gỡ `leadOfThis` → `can_submit_journal`) · `teacher.classes.tsx` (nguồn `is_lead`)
- **4 picker** → same school + `state='active'` + role khớp đúng RPC tương ứng (§C.1)
- Deploy frontend **trước** S4

### S4 — FINAL HARDENING
- `session_teacher_assignments`: RPC-only. `REVOKE INSERT/UPDATE/DELETE FROM authenticated, anon` (table-level trước)
- Trigger **SECURITY INVOKER** (D311-cand), dùng `dma_write_is_privileged()` sẵn có:
  - `BEFORE DELETE` → `RAISE` vô điều kiện
  - `BEFORE UPDATE` → chặn nếu `OLD.state='superseded'`; chặn đổi `session_id`/`profile_id`/`school_id`/`dimension`/`source`/`assigned_by`/`valid_from`/`created_at`
  - `BEFORE INSERT` → chặn `dimension <> 'planned'` (§D.1); derive `assigned_by` server-side, client không gửi được
- **`service_role` cũng phải qua trigger** (D312-cand — BYPASSRLS không bypass trigger)
- Legacy `session_teachers` → read-only/deprecated (SELECT policy giữ)
- Verify ACL/RLS/`aclexplode` + `has_table_privilege` + `has_column_privilege`

### S5 — QA
Xem §L. Login thật 2 trường (D2/D3), không SQL Editor một mình.

**Ràng buộc thứ tự tuyệt đối:** S0A trước S1 · S0B trước S2 · **S3 trước S4** (đảo = GV bị gỡ giữ quyền, P1-5) · frontend deploy trước S4 (bài học WP1 Stage C).

---

## K. GRANTS / RLS / TRIGGER PLAN

### K.1 `session_teacher_assignments`

| Giai đoạn | `authenticated` | `anon` | `service_role` |
|---|---|---|---|
| Sau S1 | SELECT (qua RLS `same_school(school_id)`) | không gì | SELECT (+ DML tạm cho migration) |
| Sau S4 | **chỉ SELECT** | **không gì** | SELECT; DML đi qua trigger, không bypass invariant |

RLS: `ENABLE ROW LEVEL SECURITY`. Chỉ **một** policy `sta_select_school` — `same_school(school_id)`. Không policy ghi. Mọi ghi qua SECURITY DEFINER RPC owner `postgres`.

### K.2 `session_teachers` (legacy)

| Giai đoạn | `authenticated` | `anon` |
|---|---|---|
| Hiện tại | **full DML** ⚠️ | **full DML** ⚠️ |
| Sau S0A | SELECT | không gì |
| Sau S4 | SELECT (deprecated, read-only) | không gì |

### K.3 Trigger inventory sau S4

| Trigger | Bảng | Timing | secdef |
|---|---|---|---|
| `trg_sta_no_delete` | `session_teacher_assignments` | BEFORE DELETE | **INVOKER** |
| `trg_sta_immutable` | idem | BEFORE UPDATE | **INVOKER** |
| `trg_sta_actor_and_dimension` | idem | BEFORE INSERT | **INVOKER** |

Migration phải có guard `prosecdef = false` cho cả ba (D311-cand). Dùng lại `dma_write_is_privileged()`, **không tạo detection thứ hai**.

### K.4 Grant discipline

Sau **mọi** `CREATE OR REPLACE FUNCTION` (S0B, S2, S3): re-run `REVOKE ... FROM PUBLIC, anon` + `GRANT ... TO authenticated, service_role` trong **block riêng**, verify bằng `aclexplode(coalesce(proacl, acldefault('f', proowner)))` (**D15** + D231).

---

## L. QA MATRIX

| # | Test | Phương pháp | PASS = |
|---|---|---|---|
| **Q1** | Tạo session snapshot **current** distribution lead | login master KHM, tạo buổi mới | 1 hàng `primary`/`distribution_default`, profile = lead hiện tại, `assigned_by` = actor thật |
| **Q2** | Đổi distribution lead **không** đổi session cũ | đổi lead → đọc lại toàn bộ 8 session | 0 hàng `sta` đổi · 4 RPC teacher trả kết quả **byte-identical** trước/sau |
| **Q3** ⭐ | **Copy production trở thành đúng** | đổi lead → mở `/school/manage` + `/teacher` bằng cả 2 GV | Buổi cũ vẫn thuộc GV cũ, đúng như copy hứa. Chụp màn hình làm bằng chứng |
| **Q4** | Session mới sau khi đổi lead → snapshot lead **mới** | tạo buổi tiếp | primary = lead mới |
| **Q5** | Primary override chỉ đổi **đúng** session | `set_session_planned_primary` 1 session | hàng cũ `superseded` có actor+reason+timestamp · hàng mới `active` · **các session khác 0 delta** · `class_distributions` 0 delta |
| **Q6** | Assign / remove / reassign giữ đủ history | gán A → gỡ A → gán lại A | 3 hàng: `superseded`(A) + `active`(A) mới; 0 DELETE; truy được ai gỡ, lúc nào, vì sao |
| **Q7** | Removed teacher **mất** capability | gỡ GV khỏi buổi → login GV đó | không thấy buổi ở `get_teacher_home`/`classes`/`todo`/`journals` · `start_session` → `forbidden` · upload media → `not_session_teacher` |
| **Q8** | Idempotency | gọi `set_session_teachers` 2 lần cùng payload | lần 2: `added=0, superseded=0` · 0 hàng mới · audit không sinh dòng sai |
| **Q9** | Concurrency | 2 phiên gán song song cùng profile | đúng 1 hàng `active`; phiên kia nhận lỗi rõ, không double-active |
| **Q10** | Inactive teacher bị từ chối ở **assignment** | set `state='inactive'` cho fixture → gán | `teacher_invalid` |
| **Q11** ⭐ | Inactive teacher bị từ chối ở **cả hai** distribution writer | `set_distribution_lead` **và** `assign_class_distribution` | cả hai → `lead_teacher_invalid` |
| **Q12** ⭐ | Inactive teacher **không xuất hiện** ở mọi picker | 3 picker §C.1 #1–#3 | không có trong dropdown/checkbox nào |
| **Q13** | Wrong-role / cross-school rejected | JWT impersonation + UI | `teacher_invalid` ở RPC; RLS chặn ở tầng dưới |
| **Q14** | Closed session immutable | thử gán trên `completed`/`cancelled` | RPC `bad_state`; direct PostgREST **403** |
| **Q15** | Direct PostgREST assignment write bị chặn | `.from("session_teachers").insert/update/delete` và `.from("session_teacher_assignments")…` từ browser thật | tất cả **403 permission denied** |
| **Q16** ⭐ | **Journal UI capability khớp backend** | với lead, với supporting, với GV ngoài buổi | `can_submit_journal` = kết quả thật của `submit_session_journal` trong **cả 3** trường hợp; không có nút dẫn tới `forbidden` (D290/D293) |
| **Q17** ⭐ | **Journal authority chưa chuyển sang planned teacher** | đặt planned primary ≠ distribution lead → thử gửi nhật ký | planned primary **KHÔNG** gửi được; distribution lead **vẫn** gửi được. Semantics WP4 chưa bị đụng |
| **Q18** | Legacy rows không mất | đếm `session_teachers` | **2 hàng**, nội dung byte-identical, `role='lead'`/`'assist'` nguyên |
| **Q19** | `taught_by` không đổi | 3 giá trị populated + 5 NULL | 0 delta |
| **Q20** | `start_session` audit đầy đủ | bắt đầu 1 buổi | audit có `actor_id` · `entity_type='lesson_session'` · `entity_id` · metadata; **3 hàng cũ rỗng giữ nguyên**, không backfill |
| **Q21** ⭐ | **WP1 invariants không regression** | đo lại toàn bộ §A.1 + §A.2 | mọi số khớp; ANOMALY-1 byte-identical; `learning_moments` table INSERT vẫn `false`; 3 guard vẫn INVOKER |
| **Q22** | Parent regression | login PH Hùng + PH Thành | journal/moment/consent 0 delta; policy `learning_moments_select_school_or_parent` byte-identical |
| **Q23** | Trigger chặn service_role | `execute_sql` thử DELETE trên `sta` | `RAISE` — BYPASSRLS không bypass trigger (D312-cand) |
| **Q24** | `dimension` không mở ngoài `planned` | thử INSERT `dimension='responsible'` | trigger chặn |

**Tài khoản QA** (mật khẩu `Test@123`):
`hieutruong.kidshouse@demo.demenart.com` · `gv.linh.kidshouse@demo.demenart.com` · `gv.my.kidshouse@demo.demenart.com` · `hieutruong.demen@demo.demenart.com` · `gv.han.demen@demo.demenart.com` · `ph.hung.kidshouse@demo.demenart.com` · `ph.thanh.demen@demo.demenart.com`

**Fixture cần Owner cho phép mutate:** Q10/Q11/Q12 cần ít nhất 1 profile `state <> 'active'` (live hiện **0**). Không mutate GV đang dùng — tạo fixture riêng, dọn sạch sau QA, báo cáo residue = 0 (mẫu D236).

---

## M. ROLLBACK BOUNDARIES

| Stage | Rollback | Mất dữ liệu? | Ghi chú |
|---|---|---|---|
| **S0A** | re-`GRANT` + re-`CREATE POLICY` 3 policy (giữ nguyên văn định nghĩa hiện tại trong migration comment) | Không | Rollback mở lại P0-1…4 — chỉ làm nếu S0A phá vỡ path hợp lệ chưa lường |
| **S0B** | `CREATE OR REPLACE` về bản cũ + **re-run REVOKE/GRANT** (D15) | Không | Rollback đưa P1-11 trở lại |
| **S1** | `DROP TABLE session_teacher_assignments CASCADE` | Chỉ mất cutover snapshot — **tái tạo được** vì nguồn (`class_distributions`, `session_teachers`) chưa đổi | Ranh giới an toàn nhất |
| **S2** | `CREATE OR REPLACE` 4 function về bản cũ + `DROP FUNCTION set_session_planned_primary` + re-grant | **Mất dữ liệu mới sinh sau S2** (assignment tạo qua đường canonical). Legacy `session_teachers` không còn được ghi từ S2 ⇒ rollback S2 để lại **khoảng trống dữ liệu** | ⚠️ **Điểm không thể quay lui sạch.** Sau khi S2 chạy và có session mới, rollback phải kèm re-materialize thủ công. Cân nhắc kỹ trước khi apply |
| **S3** | revert từng function độc lập + revert frontend commit | Không | Backward compatible vì mọi hàng cutover đều `active` |
| **S4** | re-`GRANT` + `DROP TRIGGER` ×3 | Không | Mở lại direct write — chỉ khẩn cấp |

**Ranh giới không thể quay lui:** **S2**. Trước S2, rollback sạch tuyệt đối. Từ S2 trở đi, rollback là thao tác có mất mát. Owner phải biết điều này trước khi cho phép S2.

**Rollback boundary riêng cho frontend:** deploy S3 frontend trước S4. Nếu revert frontend sau S4, direct read cũ (`session_teachers`) vẫn chạy (SELECT còn) nhưng trả **dữ liệu legacy đứng yên** — hiển thị sai chứ không lỗi. Phải revert S4 kèm theo.

---

## N. REMAINING OWNER GATES

Chỉ những điểm còn trade-off thật, không thể suy ra từ các quyết định đã đóng.

### GATE-1 — Có snapshot cutover primary cho session ĐÃ ĐÓNG không?

Áp dụng cho 5 session: `2fab0c56` (completed) · `aaaa…0002` · `aaaa…0001` (taught_report_pending) · `8dcf9f2e` · `ea85798a` (cancelled).

| | **A — snapshot cả 8** | **B — chỉ snapshot session mở (3)** |
|---|---|---|
| Ưu | resolver đồng nhất, mọi session có primary; 4 RPC teacher không cần nhánh fallback | **không khẳng định điều không có bằng chứng**; đúng tinh thần "không backdate, không fake" nhất |
| Nhược | với 5 session đã đóng, hàng `primary` là **suy đoán từ trạng thái hiện tại**, dù `source` và `reason` đã ghi rõ | 5 session đóng mất ownership ở workspace GV — Mỹ Linh **không còn thấy** buổi `taught_report_pending` của mình ⇒ **regression trải nghiệm thật**, và 2 buổi đó đang chờ gửi nhật ký |

Em nghiêng **A**, vì `source='legacy_cutover_snapshot'` + `assigned_by=NULL` + `reason` tường minh **đã** mã hoá sự thật "đây không phải bằng chứng plan gốc" ngay trong dữ liệu — người đọc sau không thể nhầm. Còn B tạo regression vận hành thật trên 2 buổi đang chờ nhật ký. Nhưng đây là đánh đổi giữa *độ sạch của bằng chứng* và *tính liên tục của trải nghiệm* — thuộc thẩm quyền Owner/CTO.

### GATE-2 — `set_session_teachers` giữ tên hay đổi tên?

- **A** — giữ tên, đổi ngữ nghĩa thành "chỉ quản lý planned non-primary". Frontend không đổi lời gọi. Rủi ro: tên nói "set teachers" nhưng không set được primary → dễ hiểu lầm ở lần đọc code sau.
- **B** — tạo `set_session_supporting_teachers` mới, giữ `set_session_teachers` làm alias deprecated. Rõ nghĩa hơn, tốn thêm 1 bước cutover frontend ở S3.

Em nghiêng **B** — tên hàm là tài liệu, và WP2 đang sửa đúng cái bệnh "tên không khớp sự thật". Nhưng nó làm S3 dài thêm.

### GATE-3 — Fixture inactive profile cho QA

Q10/Q11/Q12 cần ≥1 profile `state <> 'active'`; live hiện **0**. Cần Owner cho phép **tạo fixture profile riêng** (không mutate GV thật), dùng xong dọn sạch, báo residue = 0.
Không có fixture ⇒ ba test này thành `NOT EXECUTABLE`, và invariant "active profile" chỉ có bằng chứng in-transaction, không có bằng chứng real-login.

---

## O. TRẠNG THÁI CHỐT

| | |
|---|---|
| WP1 | **FORMALLY PASS / CLOSED** — reconciled, 0 drift (§A) |
| E3-SG-01 | **PARTIALLY CONTAINED; AUTHORITY SEMANTICS PENDING WP4** — **không đóng** |
| WP2 | **READINESS DELIVERED · IMPLEMENTATION CHƯA MỞ** |
| Điều kiện mở S0A | §B.3 residual Edge sweep PASS + GATE-1 chốt |
| Migration inventory | **106** — không đổi |
| DB / code / data / deploy | **không sửa gì trong phiên này** |
| `DMA_RULES.md` / `DMA_SYSTEM_MAP.md` | **không đụng** |
| D310/D311/D312 | vẫn **candidate**, chưa gán D-number |
| WP3 / WP4 | chưa mở |

---

*V114B-E3 · WP2 Implementation Readiness · không canonicalize · không mở WP3/WP4 · E3-SG-01 không đóng. Kỷ luật vàng D1: audit live trước khi tin số.*
