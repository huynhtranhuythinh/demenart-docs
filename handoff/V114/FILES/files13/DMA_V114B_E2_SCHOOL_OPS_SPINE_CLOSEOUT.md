# DMA — V114B-E2 · SCHOOL OPS SPINE — CLOSEOUT

> Sinh trong WP5 theo OWNER AUTHORIZATION — OPEN WP5.
> **Không canonicalize RULES. Không canonicalize SYSTEM_MAP. Không mở E3.**

**Quy ước bằng chứng dùng suốt file này:**

| Ký hiệu | Nghĩa |
|---|---|
| **[B]** | Browser evidence — đo trực tiếp trên `demenart.com` bằng phiên đăng nhập thật |
| **[DB]** | Database evidence — truy vấn live trên project `xcvhacymrbhdhohyylyq` |
| **[R]** | Repo evidence — `read_file` / `get_diff` / `list_edits` trên repo Lovable |
| **[I]** | Inference — suy ra từ hai nguồn trên, **không** đo trực tiếp. Luôn ghi rõ suy ra từ đâu |
| **[P]** | Prior-session — ghi nhận từ WP1/WP2/WP3, **không** tái kiểm trong WP5 |

---

## 1. EXECUTIVE VERDICT

# `V114B-E2 PASS WITH 1 P1 OWNER DECISION (E2-01)`

Milestone giao được **năng lực xếp lịch thật** cho Hiệu trưởng: trước E2, production chỉ có 4 buổi fixture do SQL bơm thẳng, **không tồn tại đường tạo buổi nào ở tầng ứng dụng**. Sau E2, toàn bộ vòng đời buổi học — tạo · sửa · đổi giờ · gán giáo viên tham gia · huỷ · tái dùng slot đã huỷ — chạy được từ giao diện, qua 5 SECURITY DEFINER RPC, có audit trail, có gate quyền đúng vai.

**15/15 bước QA trình duyệt PASS.** Một P1 duy nhất còn mở (**E2-01**) **không phải lỗi triển khai của E2** — nó là một quyết định kiến trúc chưa được ra, tồn tại từ trước milestone này, và được E2 phát hiện chứ không gây ra. Owner đã phân loại nó là **Architectural Decision Pending → Owner Gate E3**.

---

## 2. MILESTONE SCOPE

**Khung ban đầu:** "Principal Today view".
**Khung sau audit live (WP1):** *Scheduling capability first.*

Lý do đổi khung: audit DB đầu phiên cho thấy `lesson_sessions` chỉ chứa fixture, sinh bằng SQL trực tiếp. Dựng một bề mặt "Hôm nay" trên một hệ **không ai xếp lịch được** sẽ là bề mặt trình bày lại dữ liệu chết. Scope được nắn thành vertical slice đầy đủ: DB → RPC → RLS → UI → QA.

**Trong phạm vi:** năng lực xếp lịch cho School Admin · gán Giáo viên tham gia · đổi Giáo viên chính của distribution · hiển thị lịch tuần đọc-được cho toàn trường.

**Ngoài phạm vi (không chạm):** Teacher Today (`V114C`, vẫn bị chặn bởi SEC1 + V114A-P1-5/P1-6) · Remote/Classroom (SEC1A) · `/school` → Today route activation (`SCHOOL_VIEWS.today.available` giữ `false`).

---

## 3. OWNER DECISIONS

| # | Quyết định | Hệ quả |
|---|---|---|
| OD-1 | Kích hoạt route `/school → Today` phải gate theo **độ hoàn chỉnh năng lực và xử lý trạng thái**, không theo việc hôm đó có dữ liệu hay không | Today giữ `available:false`, không dựng card rỗng |
| OD-2 | Giá trị enum `rescheduled` **không bao giờ được ghi**; đổi lịch = `UPDATE scheduled_at` tại chỗ | Nghiệm thu ở bước QA 6 |
| OD-3 | `session_teachers` là **"Giáo viên tham gia / trợ giảng"**, không phải "Giáo viên phụ trách". Quyền sở hữu thực thi thuộc **duy nhất** `class_distributions.lead_teacher_id` | Ép nguyên văn hai câu vào UI |
| OD-4 | **CTO Addendum:** `profile_school_id` phải được mô tả là **RLS support function (not an application RPC)**; `EXECUTE` cho `authenticated` là **yêu cầu kỹ thuật của việc đánh giá predicate RLS**, không phải API surface được phơi ra | Xem §12 |
| OD-5 | Phương án **B** cho vòng sửa cuối: chỉ sửa E2-02 | `7ee7eeba` |
| OD-6 | E2-01: **không sửa, không workaround, không đổi wording** → Owner Gate E3 | Xem §6 và §23 |

---

## 4. IMPLEMENTATION SUMMARY

| WP | Nội dung | Trạng thái |
|---|---|---|
| WP1 | Migration 104 — 5 RPC + 1 RLS support function + schema additions + RLS hardening | ✅ **[P]** |
| WP2 | Security regression bằng JWT impersonation | ✅ **[P]**, tái kiểm trong WP5 → §13 |
| WP3 | Frontend: route `/school/schedule` mới, sửa nav, thêm quản lý Giáo viên chính vào `/school/manage` | ✅ **[R]** |
| WP3.1 | 3 defect sửa trong phạm vi: `p_title` null-vs-empty · so sánh thời điểm sai · `lesson embed 300` | ✅ **[B][DB]** |
| WP4 | End-to-end QA trình duyệt, 15 bước | ✅ **[B]** — §14 |
| WP4.1 | E2-02 remediation + QA lại bước 3 · 9 · 10 + regression 15 | ✅ **[B][DB]** |
| WP5 | Closeout (file này) | ✅ |

---

## 5. ROUTE AND UI CHANGES

**[R]** Ba file chạm, không hơn:

1. **`src/routes/_authenticated/school.schedule.tsx`** — file mới. Lưới tuần thao tác được (4 distribution × 7 ngày), Sheet panel bên phải cho tạo/sửa/huỷ, checkbox nhiều giáo viên tham gia, bảng map 12 mã lỗi → tiếng Việt (`mapOpsErr`).
2. **`src/routes/_authenticated/school.tsx`** — gỡ `{ key: "schedule" }` khỏi mảng `LOCKED · SẮP RA MẮT V1.5`, đưa vào `NAV_GROUPS` nhóm "Quản lý trường" ngay sau "Tổng quan". `SCHOOL_VIEWS.today.available` **giữ nguyên `false`**.
3. **`src/routes/_authenticated/school.manage.tsx`** — lưới tuần giữ read-only + link "Mở lịch triển khai"; `ClassSubjectsPanel` thêm đổi/gỡ Giáo viên chính qua `set_distribution_lead`.

**Hai câu hợp đồng ép nguyên văn vào UI (OD-3):**
- *"Người gửi nhật ký cho buổi là Giáo viên chính của môn, không phải danh sách này."* — **[B]** xác nhận hiện trên cả panel Tạo và panel Chi tiết.
- *"Đổi giáo viên chính chỉ áp dụng cho buổi tạo mới, không thay đổi buổi đã xếp."* — **[B]** xác nhận hiện trên `/school/manage?tab=classes`. ⚠️ **Câu này hiện chưa được dữ liệu bảo chứng — xem E2-01, §6 và §19.**

---

## 6. DATABASE MIGRATION

**[DB]** Migration duy nhất: `20260721023957_v114b_e2_school_ops_spine` (22.854 ký tự).

| | |
|---|---|
| Migrations | 103 → **104** (+1) |
| Bảng | 87 → **87** (+0) |
| SECURITY DEFINER functions | 190 → **196** (+6) |
| RLS policies | 164 → **165** (+1 ròng) |
| Edge Functions | 16 → **16** (+0) |
| cron jobs | 1 → **1** (+0) |

Schema additions **[P]**: cột `cancel_reason`, CHECK constraint cho role, partial unique index trên `(class_distribution_id, scheduled_at)` **loại trừ `cancelled`**.

**[DB]** Partial unique index được chứng minh sống ở §17: hai dòng cùng `class_distribution_id`, cùng `scheduled_at = 2026-07-22 14:00 VN`, một `cancelled` một `scheduled`, **cùng tồn tại**.

---

## 7. RPC CONTRACTS

**[DB]** Chữ ký thật đọc từ `pg_get_function_identity_arguments`:

| RPC | Tham số | `already` | Bắt `unique_violation` |
|---|---|---|---|
| `create_lesson_session` | `p_class_distribution_id uuid, p_scheduled_at timestamptz, p_duration_min integer, p_title text, p_lesson_version_id uuid, p_teacher_ids uuid[]` | — | ✅ |
| `update_lesson_session` | `p_session_id uuid, p_scheduled_at timestamptz, p_duration_min integer, p_title text, p_lesson_version_id uuid, p_clear_lesson boolean` | — | ✅ |
| `cancel_lesson_session` | `p_session_id uuid, p_reason text` | ✅ | — |
| `set_session_teachers` | `p_session_id uuid, p_teacher_ids uuid[]` | — | — |
| `set_distribution_lead` | `p_class_distribution_id uuid, p_lead_teacher_id uuid` | ✅ | — |

Tất cả trả `json` dạng `{ok, reason}` — **không raise exception ra client**. Nghiệm thu **[B]**: mọi lần từ chối trong QA đều hiện toast tiếng Việt, không có màn hình lỗi trắng.

**12 mã lỗi được map** (`mapOpsErr`, **[R]**): `not_authenticated` · `not_authorized_for_school` / `not_authorized` · `distribution_not_found` / `distribution_orphaned` / `distribution_not_active` · `session_not_found` · `scheduled_at_required` · `duration_out_of_range` · `lesson_version_invalid` · `teacher_invalid` · `lead_teacher_invalid` · `session_slot_taken` · `bad_state`.

---

## 8. RLS AND AUTHORIZATION CHANGES

**[DB]** Policy sống trên 3 bảng liên quan, tất cả role `{authenticated}`:

**`session_teachers`** — 4 policy, do migration 104 tạo/thay:
- `SELECT` — `same_school(session_school_id(session_id))`
- `INSERT` WITH CHECK — `(is_session_lead(...) OR (is_school_admin() AND same_school(...))) AND profile_school_id(profile_id) IS NOT NULL AND profile_school_id(profile_id) = session_school_id(session_id)`
- `UPDATE` USING + WITH CHECK — như trên
- `DELETE` USING — `is_session_lead(...) OR (is_school_admin() AND same_school(...))`

Mệnh đề `profile_school_id(profile_id) = session_school_id(session_id)` chính là **chặn cross-school ở tầng RLS** — nghiệm thu §13 test C.

**`lesson_sessions`** — 3 policy (`SELECT` same_school · `INSERT`/`UPDATE` cho `is_distribution_lead OR (is_school_admin AND same_school)`).
**[DB]** Kiểm chứng: chuỗi `lesson_sessions_insert_lead_or_schooladmin` và `..._update_...` **không xuất hiện** trong nội dung migration 104 ⇒ **có trước E2**, không phải do E2 tạo. Xem §20 debt.

**Không có privilege expansion:** **[DB]** `0` policy nào trên 3 bảng này cấp cho `anon` hay `{public}`.

---

## 9. RACE-SAFETY AND IDEMPOTENCY

| Cơ chế | Bằng chứng |
|---|---|
| Trùng slot không dựa vào kiểm-trước-khi-ghi mà dựa vào **partial unique index**; `create`/`update` bắt `unique_violation` và trả `session_slot_taken` | **[DB]** `pg_get_functiondef` chứa xử lý 23505 ở cả hai hàm; **[B]** toast đúng nguyên văn ở bước 3 |
| Slot đã huỷ **không** giữ chỗ — index loại `cancelled` | **[B]** bước 10 tạo lại thành công; **[DB]** hai dòng cùng slot cùng tồn tại (§17) |
| `cancel_lesson_session` **idempotent** — huỷ lại trả `already` thay vì lỗi; frontend chấp nhận cả `ok` lẫn `already` | **[DB]** hàm chứa nhánh `already`; **[R]** `if (!data?.ok && !data?.already)` |
| `set_distribution_lead` **idempotent** | **[DB]** hàm chứa nhánh `already` |
| Chặn double-submit ở UI: nút disable khi `submitting`/`saving`/`cancelling` | **[R]** |
| Huỷ có **xác nhận hai bước** (`confirmCancel` state) | **[B]** *"Bạn chắc chắn muốn huỷ buổi này? Hành động không thể khôi phục."* + `Không huỷ` / `Xác nhận huỷ` |

**Chưa đo:** concurrency thật (hai client ghi cùng lúc). Không có bằng chứng, không tuyên bố. → §20.

---

## 10. SEMANTIC PARAMETER AUDIT

Ba defect bắt được **trước khi publish**, cả ba đã nghiệm thu sống trong WP4:

**① `p_title` — đảo `null` / `""`.**
Frontend gửi `title.trim()` (chuỗi rỗng khi xoá trắng); RPC coi `null` là "không đổi". Hậu quả trước khi sửa: **không thể xoá tiêu đề buổi** — lưu xong tiêu đề cũ quay lại, im lặng, không báo lỗi.
**[B]** Bước 5: xoá trắng → lưu → đóng → mở lại = **rỗng**. **[DB]** `title IS NULL` (không phải `''`).

**② So sánh thời điểm sai làm audit ghi nhầm.**
So chuỗi ISO thay vì so mốc thời gian ⇒ mọi lần lưu đều bị coi là đổi lịch, audit sinh `scheduled_at_from ≠ scheduled_at_to` giả. Sửa bằng so `getTime()` và chỉ truyền `p_scheduled_at` khi thật sự đổi.
**[DB]** 5 dòng `session_updated`: 4 dòng có `from == to`, đúng 1 dòng `02:00Z → 07:00Z` — trùng khớp chính xác lần đổi giờ 09:00→14:00 ở bước 6.

**③ `lesson embed 300`.**
`lessons` và `lesson_versions` có **hai** khoá ngoại vòng tròn (`lesson_versions.lesson_id → lessons.id` và `lessons.current_version_id → lesson_versions.id`), PostgREST từ chối đoán ⇒ `300 Multiple Choices` ⇒ ô "Bài học" luôn rỗng + toast đỏ mỗi lần mở panel. Sửa bằng bỏ hẳn cú pháp nhúng, tách hai truy vấn tuần tự.
**[B]** Network tab: `GET /rest/v1/lessons?...` **200** và `GET /rest/v1/lesson_versions?...&state=eq.published` **200**, không còn embed.

---

## 11. CTO VERIFICATION ADDENDUM

**`profile_school_id(p_profile_id uuid)` — RLS support function (not an application RPC).**

Hàm này **không** là API surface. Nó tồn tại vì predicate RLS trên `session_teachers` cần đọc `school_id` của một profile **bên thứ ba** (người đang được gán), mà chính người gọi có thể không có quyền `SELECT` trực tiếp lên dòng đó. `EXECUTE` cho `authenticated` là **yêu cầu kỹ thuật của việc đánh giá predicate RLS** — Postgres đánh giá policy dưới quyền của vai đang gọi — chứ không phải một cánh cửa được mở ra cho client.

**[DB]** Xác nhận: `prosecdef = true`, `EXECUTE` chỉ cho `authenticated, postgres, service_role`, **không PUBLIC, không anon**.

**Hệ quả cho kiểm kê:** application RPC surface của E2 = **5**, không phải 6. `profile_school_id` được đếm riêng ở dòng "RLS support functions".

---

## 12. API SURFACE SUMMARY

| Loại | Số | Tên |
|---|---|---|
| **Application RPC (mới)** | **5** | `create_lesson_session` · `update_lesson_session` · `cancel_lesson_session` · `set_session_teachers` · `set_distribution_lead` |
| **RLS support function (mới)** | **1** | `profile_school_id` |
| Read RPC tái dùng (không sửa) | 5 | `get_school_week_schedule` · `get_session_readiness` · `get_teacher_home` · `get_teacher_classes` · `get_school_overview` |
| Edge Function mới | **0** | — |
| Enum value mới | **0** | `rescheduled` **không bao giờ được ghi** (OD-2) |

**[DB]** Cả 6 hàm mới: `SECURITY DEFINER`, `EXECUTE` = `{authenticated, postgres, service_role}`.

---

## 13. SECURITY REGRESSION AFTER DEPLOY

Chạy lại trên production **sau** commit `7ee7eeba`, bằng JWT impersonation. **Không để lại dữ liệu test mới.**

| # | Test | Danh tính giả lập | Kết quả | Bằng chứng |
|---|---|---|---|---|
| **A** | Cross-school **tại RPC** — Master MNDM tạo buổi trên distribution của KHM | Mai Phương Dung (`07fbcbbf…`) | ✅ **BLOCKED** `{"ok":false,"reason":"not_authorized_for_school"}` | **[DB]** |
| **B1** | Giáo viên gọi `set_distribution_lead` | Đặng Mỹ Linh (`fd9322e1…`) | ✅ **BLOCKED** `not_authorized_for_school` | **[DB]** |
| **B2** | Giáo viên gọi `create_lesson_session` | như trên | ✅ **BLOCKED** | **[DB]** |
| **B3** | Giáo viên gọi `cancel_lesson_session` | như trên | ✅ **BLOCKED** | **[DB]** |
| **B4** | Giáo viên gọi `set_session_teachers` | như trên | ✅ **BLOCKED** | **[DB]** |
| **C** | Cross-school **tại RLS** — Master KHM `INSERT` vào `session_teachers` một profile của MNDM | Nguyệt Thi (`589f0390…`) | ✅ **BLOCKED** — `SQLSTATE 42501`, *new row violates row-level security policy for table "session_teachers"* | **[DB]** |
| **D** | Master admin thực thi đúng quyền | Nguyệt Thi | ✅ **PASS** — 4 buổi tạo thành công, 2 huỷ, 2 lần đổi Giáo viên chính, toàn bộ qua UI thật | **[B]** §14 |
| **E** | `session_teachers` policy INSERT/UPDATE/DELETE | — | ✅ đủ 4 policy, đúng vai `{authenticated}`, có mệnh đề cross-school ở INSERT và UPDATE | **[DB]** §8 |
| **F** | EXECUTE cho PUBLIC hoặc anon | — | ✅ **0** hàm SECURITY DEFINER nào trong schema `public` cấp EXECUTE cho `PUBLIC`/`anon` | **[DB]** |
| **G** | 5 application RPC vẫn grant đúng chủ đích | — | ✅ `{authenticated, postgres, service_role}`, không hơn | **[DB]** |
| **H** | `profile_school_id` phân loại đúng | — | ✅ RLS support function, xem §11 | **[DB]** |
| **I** | Policy cấp cho `anon` trên 3 bảng E2 | — | ✅ **0** | **[DB]** |

**Kỹ thuật rollback (test C):** INSERT chạy trong `DO` block có `EXCEPTION` handler, và block kết thúc bằng `RAISE EXCEPTION` cố ý để **ép rollback toàn bộ transaction**. Thông điệp kết quả đi ra qua chính error text. **Không dòng nào được ghi.** Test A và B1–B4 không cần rollback vì RPC từ chối trước khi ghi — **[DB]** đối chiếu `session_created` = 4 = đúng số buổi tồn tại, không có dòng thừa.

**Kết luận §13: không phát hiện P0/P1 mới. Không có privilege expansion.**

---

## 14. BROWSER QA MATRIX 15/15

Lớp dùng chung: **Hoa Hồng · Cảm Thụ Âm Nhạc Dế Mèn** (distribution `d1000000-…-031`), trường KHM-DN. Toàn bộ **[B]**.

| # | Bước | Kết quả | Bằng chứng đo được |
|---|---|---|---|
| 1 | Sidebar | ✅ | "Lịch triển khai" trong **QUẢN LÝ TRƯỜNG**; khu khoá chỉ còn "Tương tác phụ huynh" |
| 2 | Tạo buổi | ✅ | toast *Đã tạo buổi học* · ô hiện `09:00 Sắp diễn ra` · panel prefill đúng ngày ô vừa bấm |
| 3 | Trùng khung giờ | ✅ | toast **"Khung giờ này của lớp đã có buổi học khác."** · panel **giữ mở** · tiêu đề + giờ đã nhập **không mất** · **[DB]** không sinh dòng, không sinh audit |
| 4 | Đổi tiêu đề | ✅ | lưu được, mở lại giữ nguyên |
| 5 | **Xoá trắng tiêu đề** | ✅ | mở lại **rỗng** · **[DB]** `title IS NULL` — fix ① |
| 6 | **Đổi giờ 09:00 → 14:00** | ✅ | badge **vẫn "Sắp diễn ra"**, không phải "Đổi lịch" (OD-2) · **[DB]** audit `02:00Z → 07:00Z` |
| 7 | Bỏ tick trợ giảng | ✅ | **[DB]** `session_teachers_changed removed:1` · mở lại vẫn unchecked |
| 8 | Tick lại | ✅ | **[DB]** `added:1 teacher_ids:[…014]` |
| 9 | Huỷ buổi | ✅ | xác nhận 2 bước · ô `Đã huỷ` gạch ngang · mở lại: khối *Lý do huỷ*, 4 input `disabled`, combobox bài học `disabled`, **không nút Lưu, không nút Huỷ, không nút khôi phục** |
| 10 | **Tái dùng slot đã huỷ** | ✅ | sau `7ee7eeba`: ô có `+` trở lại → tạo buổi 14:00 thành công → ô hiện đồng thời `14:00 Đã huỷ` + `14:00 Sắp diễn ra` |
| 3b | Buổi thứ hai cùng ngày | ✅ | tạo 16:00 cùng ngày thành công; ô chứa 3 buổi và **vẫn còn `+`** |
| 11 | Đổi Giáo viên chính | ✅ | hai chiều: Mỹ Linh → Khánh Vy → Mỹ Linh · toast *Đã cập nhật giáo viên chính* · **[DB]** `lead_teacher_id` khớp cả hai lần |
| 12 | **Teacher Portal visibility** | ✅ | GV Mỹ Linh `/teacher/classes` thấy **"Buổi học · lúc 14:00 23 tháng 7 · Sắp tới"**, **không** thấy buổi đã huỷ |
| 13 | `/teacher` home | 🟡 **đo phần khả thi** | Buổi QA rơi vào 23/07, không phải hôm nay ⇒ nhánh "Bắt đầu buổi học" **không tồn tại để đo**. Đo được: *"Thứ Ba, 21/7 · 0 tiết hôm nay"* + *"Hôm nay cô không có lớp"* đúng, và buổi QA nổi lên ở **"Lớp gần nhất sắp tới · Hoa Hồng · 14:00"** |
| 14 | Responsive | ✅ | §15 |
| 15 | **Read-only cho GV** | ✅ | §16 |

**Bước 13 được ghi trung thực là "đo phần khả thi", không phải PASS toàn phần.** Nhánh CTA hôm-nay chưa có bằng chứng → §20.

---

## 15. RESPONSIVE EVIDENCE

**[B]** Đo bằng `resize_window` + đọc `getBoundingClientRect` thật, không phải ước lượng bằng mắt.

| Viewport | `document.body` tràn ngang | Lưới cuộn trong khung | Panel |
|---|---|---|---|
| `innerWidth = 638` | **false** | ✅ `scrollWidth 768 > clientWidth 564` | — |
| `innerWidth = 400` | **false** | ✅ | `left = 0`, `right = 400`, **không tràn phải**; ô `date` và `time` rộng **170px** — chạm được; `date/time/number/text` đều `visible` |

Mẫu đúng: **không có page-level overflow**, chỉ có inner-container scroll.

**Ghi chú kiểm kê:** V114B-E1a từng ghi nợ *"không hạ được cửa sổ dưới 480px nên không đo được mobile breakpoint"*. Vòng QA này đạt **400px**. **Nợ đó đóng được** cho phạm vi `/school/schedule`.

---

## 16. TEACHER PORTAL EVIDENCE

Tài khoản: `gv.linh.kidshouse@demo.demenart.com` — Đặng Mỹ Linh, `lead_teacher`, KHM-DN. Toàn bộ **[B]**.

**`/teacher/classes`** — thấy buổi `scheduled` 23/07 14:00 (hiển thị *"Buổi học"* vì `title IS NULL` — fallback đúng), **không** thấy buổi `cancelled`.

**`/teacher`** — *"0 tiết hôm nay"*, *"Hôm nay cô không có lớp"*, khối *"Lớp gần nhất sắp tới · Hoa Hồng · 14:00"*.

**`/school/schedule`** (bước 15, đo **sau** `7ee7eeba`):

| | |
|---|---|
| Nút `Thêm buổi` | **0** — bản vá E2-02 **không rò quyền sang giáo viên** |
| *"Bạn đang xem ở chế độ chỉ đọc."* | có |
| Ô rỗng | `–` (27 dấu = 26 ô rỗng + 1 dấu trong dải "20/07 – 26/07") |
| Buổi hiển thị | đủ 4, đọc được |
| Mở panel chi tiết | `date/time/number/text` **disabled=true** · 4 checkbox **disabled** · **0 textarea** · nút còn lại chỉ `Close` · **không toast lỗi** |

**D290 giữ được:** không tồn tại affordance nào chắc chắn dẫn tới `not_authorized`. **D293 giữ được:** gate UI phản chiếu đúng mọi nhánh authorization của RPC — RPC từ chối giáo viên ở cả 4 hành động (§13 B1–B4), UI không mở cửa nào trong 4 hành động đó.

---

## 17. PRODUCTION DATA INVENTORY

### 17.1 Bốn tầng trạng thái

| Tầng | Ý nghĩa |
|---|---|
| **Baseline trước V114B-E2** | trạng thái tại `e81c3179` (HEAD kết thúc E1a) |
| **Sau migration 104** | schema + RPC + RLS đã lên, chưa có dữ liệu người dùng |
| **Sau QA production** | trạng thái hiện tại, gồm dữ liệu do QA sinh từ UI |
| **Dữ liệu QA giữ có chủ đích** | §17.3 |

### 17.2 Kiểm kê before → after

| Hạng mục | Baseline | Sau E2 | Δ | Nguồn |
|---|---|---|---|---|
| Tables | 87 | **87** | 0 | **[DB]** |
| Migrations | 103 | **104** | +1 | **[DB]** |
| SECURITY DEFINER functions | 190 | **196** | +6 | **[DB]** |
| RLS policies | 164 | **165** | +1 ròng | **[DB]** |
| Edge Functions | 16 | **16** | 0 | **[DB]** liệt kê đủ 16 slug |
| cron jobs | 1 | **1** | 0 | **[DB]** |
| Application RPC surface | — | **5** | +5 | **[DB]** §12 |
| RLS support functions | — | **1** | +1 | **[DB]** §11 |
| Route files trên đĩa | 60 | **61** | +1 | **[R]** |
| Navigable routes | 53 | **54** | +1 | **[I]** — 61 file trừ 7 file layout/root (`__root`, `_authenticated/route`, `admin`, `parent`, `portal`, `school`, `teacher`). Khớp chuỗi 52 (V113G) → 53 (E1a) → 54 (E2) |

### 17.3 Dữ liệu QA còn trên production

**[DB]** Distribution **Hoa Hồng · Cảm Thụ Âm Nhạc Dế Mèn** (`d1000000-0000-4000-8000-000000000031`), trường KHM-DN:

| # | Giờ VN | State | `cancel_reason` | id |
|---|---|---|---|---|
| 1 | 22/07 14:00 | `cancelled` | GV nghỉ ốm | `8dcf9f2e…` |
| 2 | 22/07 14:00 | `scheduled` | — | `3bfb9730…` |
| 3 | 22/07 16:00 | `cancelled` | QA regression E2-02 | `ea85798a…` |
| 4 | 23/07 14:00 | `scheduled` | — | `91bc03d8…` |

**Đây là dữ liệu QA có chủ đích, được giữ lại để bảo toàn evidence** — cụ thể dòng 1 và 2 là bằng chứng vật lý của partial unique index loại `cancelled`, và dòng 3 là bằng chứng của bước 3b (nhiều buổi trong một ngày).

**Đây KHÔNG phải fixture chuẩn.** Không được dùng làm dữ liệu tham chiếu cho bất kỳ demo, seed, hay tính toán chỉ số nào. Cả 4 dòng đều có `title` rỗng hoặc mang nhãn QA.

**Không xoá trong WP5** — không dòng nào gây production risk: chúng nằm trong trường pilot, thuộc một lớp, không gắn trẻ, không gắn media, không gắn nhật ký.

**Distribution lead assignments** — **[DB]** `d1000000-…-031` hiện `lead_teacher_id = d1000000-…-011` (**Đặng Mỹ Linh**) = **đúng giá trị trước QA**. Bước 11 đã đổi đi và đổi về; trạng thái cuối không drift.

---

## 18. AUDIT LOG VERIFICATION

### 18.1 Mapping tên action

Owner liệt kê 5 hành động nghiệp vụ. Tên thật trong production khác 2 chỗ — **dùng tên production, không sửa schema để khớp wording**:

| Owner ghi | Tên thật `audit_logs.action` |
|---|---|
| `session_created` | `session_created` ✅ |
| `session_updated` | `session_updated` ✅ |
| `session_cancelled` | `session_cancelled` ✅ |
| `session_teachers_updated` | → **`session_teachers_changed`** |
| `distribution_lead_updated` | → **`distribution_lead_changed`** |

### 18.2 Bằng chứng từng action

**[DB]** Cửa sổ QA 21/07/2026, giờ Việt Nam. **Actor duy nhất: Huỳnh Trần Nguyệt Thi (`d1000000-…-010`, master_admin). School scope duy nhất: Kids House Montessori Đà Nẵng.** Không có dòng nào mang actor khác, không có dòng nào mang school khác.

| Action | Rows | Khoảng giờ VN | Target | Payload chính |
|---|---|---|---|---|
| `session_created` | **4** | 13:21:48 → 14:30:17 | `lesson_session` | `class_distribution_id` · `scheduled_at` · `duration_min` · `lesson_version_id` · `teacher_ids[]` |
| `session_updated` | **5** | 13:26:57 → 13:42:40 | `lesson_session` | `scheduled_at_from` · `scheduled_at_to` · `duration_min` · `lesson_version_id` · `cleared_lesson` |
| `session_cancelled` | **2** | 13:44:44 · 14:30:49 | `lesson_session` | `reason` = "GV nghỉ ốm" / "QA regression E2-02"; `metadata.state_from` = `scheduled` |
| `session_teachers_changed` | **2** | 13:42:25 · 13:42:40 | `lesson_session` | `removed:1, teacher_ids:[]` rồi `added:1, teacher_ids:[…014]` |
| `distribution_lead_changed` | **2** | 13:53:13 · 13:55:04 | `class_distribution` | `lead_from …011 → lead_to …013`, rồi `lead_from …013 → lead_to …011` |

**Có phát sinh row hay không — đối chiếu quan trọng nhất:**
`session_created` = **4** = đúng số buổi tồn tại trong DB (§17.3). Lần tạo trùng slot ở bước 3 và lần cross-school ở test A **không sinh dòng nào**. Lần đổi ngày bị từ chối ở vòng QA đầu cũng **không sinh dòng nào**. ⇒ **Ghi hỏng không để lại vết giả.**

### 18.3 Debt E2-03 — ghi trung thực

Audit trail của E2 **không hoàn hảo**. Hai khiếm khuyết thật, cả hai là **P2 backlog**, không chặn closeout:

**① `session_updated` không ghi `title`.** Metadata chỉ chứa `duration_min`, `cleared_lesson`, `scheduled_at_from/to`, `lesson_version_id`. Hệ quả: lần xoá trắng tiêu đề ở bước QA 5 — **một thay đổi thật, và đúng là thay đổi mà fix ① sinh ra để bảo vệ** — trong audit trông y hệt một lần lưu không đổi gì. Audit không chứng minh được chính điều mà nó cần chứng minh nhất ở milestone này.

**② Thao tác lưu không đổi vẫn sinh audit row.** **[DB]** 3 trong 5 dòng `session_updated` có `scheduled_at_from == scheduled_at_to` và không kèm thay đổi nào khác đo được. Mỗi cú bấm "Lưu thay đổi" đều ghi một dòng, kể cả no-op.

**Không được mô tả audit của E2 là hoàn chỉnh.** Nó đủ để truy vết *ai làm gì lúc nào trên đối tượng nào*, và đủ để chứng minh *ghi hỏng không để lại vết*. Nó **chưa** đủ để tái dựng *nội dung* thay đổi ở trường `title`.

---

## 19. DEFECT REGISTER

| ID | Mức | Mô tả | Trạng thái |
|---|---|---|---|
| **E2-01** | 🔴 **P1** | Đổi Giáo viên chính **có hiệu lực hồi tố** lên mọi buổi đã xếp; câu chữ UI hứa ngược lại | **ARCHITECTURAL DECISION PENDING → OWNER GATE E3** — §6, §23 |
| **E2-02** | 🔴 P1 | Ô lịch có buổi mất hẳn nút `+` ⇒ không xếp được 2 buổi/ngày, slot đã huỷ thành đất chết | ✅ **CLOSED** · commit `7ee7eeba` · production browser QA PASS (bước 10 · 3 · 3b · 9 · 15) |
| **E2-03** | 🟡 P2 | Audit `session_updated` không ghi `title`; lưu no-op vẫn sinh row | Backlog — §18.3 |
| **E2-04** | 🟡 P2 | Danh sách môn trong `/school/manage?tab=classes` **đảo thứ tự sau mỗi lần lưu** (CTAN ↔ Ballet); hai nút "Lưu GV chính" giống hệt nhau ⇒ rủi ro gán nhầm Giáo viên chính | Backlog |
| **E2-05** | ⚪ | *"Nút buổi mất `aria-label` sau update"* | ❌ **WITHDRAWN** — sai sót khi đọc evidence, không phải regression thật. **[R]** nút buổi chỉ có `title`, chưa bao giờ có `aria-label`; nhãn thấy ở lần đo đầu là nhãn mô tả do công cụ `find` tự sinh |
| **E2-06** | 🟡 P2 | Câu *"Buổi đã huỷ sẽ không còn hiện với giáo viên"* **sai ở `/school/schedule`**: **[B]** GV Mỹ Linh vẫn thấy `14:00 Đã huỷ` và `16:00 Đã huỷ`. Câu đúng cho `/teacher/*`, không đúng cho toàn hệ | Backlog |
| **E2-07** | 🟡 P2 | *"Lớp gần nhất sắp tới · Hoa Hồng · 14:00"* — **không có ngày**; buổi cách 2 hôm đọc như hôm nay | Backlog |

**E2-01, E2-06 và V114A-P1-1 cùng một bệnh gốc: chữ trên màn hình chưa được dữ liệu bảo chứng.** Ba ca trong một milestone. Ghi nhận để cân nhắc thành D-rule riêng khi canonicalize — **không canonicalize trong WP5**.

---

## 20. REMAINING DEBT

| Debt | Loại | Ghi chú |
|---|---|---|
| **E2-01** | Architectural | Owner Gate E3 — §23 |
| Bước QA 13 — nhánh "Bắt đầu buổi học" khi buổi rơi đúng hôm nay | Evidence debt | Không dựng dữ liệu chỉ để tô xanh một ô. Đo khi có buổi thật vào ngày chạy QA |
| Concurrency thật (hai client ghi cùng slot cùng lúc) | Evidence debt | Cơ chế là partial unique index + bắt `unique_violation` — **[DB]** đã xác nhận; hành vi dưới tải song song **chưa đo** |
| `lesson_sessions` INSERT/UPDATE policy cho `is_distribution_lead` | Pre-existing | **[DB]** không do migration 104 tạo. `authenticated` có table grant rộng ⇒ về lý thuyết giáo viên chính có thể ghi thẳng qua PostgREST dù cả 5 RPC lẫn UI đều từ chối. **Không phải regression của E2**; thuộc họ V114A-P1-5 / P1-6 → **V114-SEC1B** |
| `anon` có table grant trên `lesson_sessions`, `session_teachers`, `class_distributions` | Pre-existing | Mặc định Supabase. **[DB]** 0 policy nào cấp cho `anon` ⇒ bị RLS chặn. Ghi nhận, không hạ mức, thuộc SEC1B |
| E2-03 · E2-04 · E2-06 · E2-07 | P2 | §19 |
| Route count 54 | Inference | §17.2 — đếm gián tiếp theo quy ước dự án, không phải đếm route đã đăng ký trong `routeTree.gen.ts` |

---

## 21. COMMIT AND DEPLOYMENT CHAIN

**[R]** `list_edits`:

```
e81c3179   ← baseline vào E2 (HEAD kết thúc V114B-E1a)
   │
58d98843   WP3  · "Added School Ops Spine frontend"
   │
d920263c   WP3.1· "Sửa lỗi lưu session & audit log"   (fix ① p_title, fix ② so sánh thời điểm)
   │
665d8e68   WP3.1· "Sửa lỗi truy vấn lesson embed"     (fix ③ PostgREST 300)
   │
7ee7eeba   WP4.1· "Tách nút cộng và danh sách buổi"   (E2-02)  ← HEAD
```

**Migration:** `20260721023957_v114b_e2_school_ops_spine` — migration duy nhất của milestone.

**Deployment:** production `demenart.com` qua **Cloudflare Pages CI trên nhánh `main`**, chế độ direct-main (D309). `deploy_project` **không** được gọi.
**[B]** Xác nhận `7ee7eeba` đã phục vụ production: sau reload, `/school/schedule` với Master hiện **28 nút `Thêm buổi`** = 4 distribution × 7 ngày — hành vi chỉ tồn tại ở `7ee7eeba`, không tồn tại ở `665d8e68`.

**Single-writer:** **[R]** `list_edits` re-pin trước mỗi work package. Không có commit lạ xen vào chuỗi. Không có writer thứ hai.

**Kiểm scope cuối (D134):** `get_diff 7ee7eeba` = **1 file · 1 cặp hunk · 0 file rò rỉ**. Không chạm RPC, schema, migration, security.

---

## 22. FINAL VERDICT

# `V114B-E2 PASS WITH 1 P1 OWNER DECISION (E2-01)`

| Phân loại | |
|---|---|
| **E2-01** | Architectural Decision Pending · Owner Gate E3 · **không phải implementation failure của E2** |
| **E2-02** | **CLOSED** · commit `7ee7eeba` · production browser QA PASS |
| **E2-05** | **WITHDRAWN** · sai sót khi đọc evidence, không phải regression thật |
| **E2-03 · E2-04 · E2-06 · E2-07** | P2 backlog · **không chặn closeout** |

**Security regression sau deploy: không phát hiện P0/P1 mới.**
**Không có privilege expansion. Không có EXECUTE cho PUBLIC hoặc anon.**
**Không tạo migration mới, không thêm RPC, không đổi RLS trong WP5.**

---

## 23. E3 READINESS AND OWNER GATE

### 23.1 E2-01 — sự thật hiện tại, giữ nguyên văn

1. **[DB]** `lesson_sessions` **chưa lưu teacher snapshot** — không tồn tại cột nào khớp `%teacher%` hay `%lead%` trên bảng này.
2. **[DB]** Teacher Portal resolve `class_distributions.lead_teacher_id` **tại thời điểm đọc** — cả 4 RPC `get_teacher_home`, `get_teacher_classes`, `get_teacher_todo_counts`, `get_teacher_journals` đều tham chiếu `lead_teacher_id` trong định nghĩa hàm.
3. Do (1) và (2): **đổi Giáo viên chính có hiệu lực hồi tố lên các buổi đã xếp**, kể cả buổi đã dạy xong. Người chịu trách nhiệm gửi nhật ký cho một buổi trong quá khứ có thể trở thành người chưa từng đứng lớp đó.
4. **[B]** Câu chữ hiện tại trên `/school/manage?tab=classes` — *"Đổi giáo viên chính chỉ áp dụng cho buổi tạo mới, không thay đổi buổi đã xếp."* — **chưa được dữ liệu bảo chứng**.

**Không sửa code. Không workaround. Không đổi domain trong WP5.**

### 23.2 Hai lựa chọn loại trừ — Owner quyết ở E3

| | Phương án | Ý nghĩa |
|---|---|---|
| **A** | **Snapshot lead teacher vào session khi tạo** | Buổi đã xếp giữ nguyên người chịu trách nhiệm. Câu chữ hiện tại trở thành đúng. Cần cột mới + backfill + quyết định backfill dùng giá trị nào cho dữ liệu lịch sử |
| **B** | **Giữ dynamic lead resolution và sửa product wording/contract** | Không đụng dữ liệu. Phải viết lại câu chữ cho đúng, và phải trả lời: đổi Giáo viên chính có nên cảnh báo về ảnh hưởng hồi tố không |

**Claude không tự chọn thay Owner.**

### 23.3 Điều kiện mở E3

E3 chưa mở. Khi mở, cần trước tiên:
- Owner Gate cho E2-01 (A hay B);
- V114C (Teacher Today) vẫn bị chặn độc lập bởi **V114-SEC1** và **V114A-P1-5 / P1-6** — E2 không gỡ chặn đó và không tuyên bố đã gỡ.

---

## KẾT

**Milestone dừng tại đây.**

Không canonicalize RULES. Không canonicalize SYSTEM_MAP. Không mở E3. Không tạo thêm migration, RPC, RLS, feature.

*Sinh trong V114B-E2 WP5 · HEAD `7ee7eeba` · migration 104 · 21/07/2026.*
