# DMA_V114A_GAP_REUSE_REMEDIATION_MATRIX.md

> **File 5/6** · Ma trận gap · tái dùng · khắc phục — **kèm Phụ lục A: Edge Authorization Boundary Inventory 16/16**
> **Baseline:** code HEAD `b87b576b` · 103 migrations · 87 tables · 190 secdef · 164 policies · 52 routes · **16 edge functions (16/16 đã có phán quyết)**
> **Đầu vào:** File 1–4 (đã áp toàn bộ đính chính CTO) + truy vết tĩnh 16 Edge Function từ **source đã triển khai** (không dùng bản trong repo)
> **Trạng thái:** audit-only. Không code, không migration, không mutate production.

---

## 0. QUY TẮC PHÂN LOẠI — BA THỨ KHÁC NHAU

Ba thuật ngữ dưới đây **không đồng nghĩa**. Bản audit trước dùng lẫn lộn và đó là lý do nhiều thứ bị gán `READY NOW` sai.

| Nhãn | Nghĩa |
|---|---|
| **FUNCTIONALLY REUSABLE** | Code chạy đúng, UX dùng được. **Chưa nói gì về quyền hay phát hành.** |
| **AUTHORIZATION-READY** | Ranh giới uỷ quyền đã đúng và đã kiểm chứng. |
| **RELEASE-READY** | Cả hai điều trên **và** không còn phán quyết bịa, không còn CTA chắc chắn hỏng, hợp đồng route đã chốt, quy tắc domain đã có. |

**Không được gán `READY NOW` khi:** phụ thuộc Edge P1/UNVERIFIED · lộ dữ liệu qua 4 RPC `same_school` rộng · cần quy tắc stale/quá hạn chưa định nghĩa · trình bày một phán quyết không có cơ sở · CTA chắc chắn hỏng với một persona hợp lệ · hợp đồng route chưa giải.

**Viết tắt cột:** `TT` = trung thực hiện tại · `TD` = phân loại tái dùng · `Chặn` = SEC1A/SEC1B · `M` = mốc khắc phục (E1–E4 / S1–S3 / **R** = gói remediation tiền-build) · `Cổng` = điều kiện phát hành.

---

## 1. PRINCIPAL

| # | Năng lực | Bề mặt hiện tại | Nguồn dữ liệu | Ranh giới uỷ quyền | Edge | TT | TD | Cần gì | Chặn | Mức | M | Cổng |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| P-01 | Projection Hôm nay | **không tồn tại** | — | `is_school_admin` | — | n/a | **NEW CAPABILITY** | domain rule + server projection | — | P1 | E2 | DC-1·2·3 |
| P-02 | Danh sách ngoại lệ | không tồn tại | — | `is_school_admin` | — | n/a | **NEW CAPABILITY** | domain rule + server projection | — | P1 | E2 | DC-1·2·3 |
| P-03 | Dòng thời gian trường | card Lịch tuần trong `school.index` | `get_school_week_schedule` (có `Asia/Ho_Chi_Minh`) | same-school admin | — | ✅ đúng | **REUSABLE SOURCE** | lọc 1 ngày **ở server** + ô click được | — | P2 | E2/E3 | — |
| P-04 | Buổi chưa phân công | không hiển thị ở đâu | `class_distributions.lead_teacher_id` | — | — | n/a | **NEEDS SERVER PROJECTION** | projection + §5.1a ngữ nghĩa | — | P1 | E2 | §5.1a |
| P-05 | GV được phân công không có mặt | **không tồn tại** | **không nguồn nào** | — | — | n/a | **CAPABILITY GAP** | **tín hiệu vận hành mới** | — | P1 | OD-1 | OD-1 |
| P-06 | Người thay / uỷ quyền tạm | không tồn tại | `session_teachers` (ghi được bởi admin) | `is_school_admin` | — | n/a | **NEW CAPABILITY** | vòng đời có hạn + ghi công đúng người | **SEC1B** | P1 | S2 | SEC1B |
| P-07 | Buổi bỏ ngỏ & quá hạn | lẫn trong `in_progress` | `lesson_sessions.state` | — | — | ❌ **gộp sai** | **REUSABLE STATE, NEEDS STALE RULE** | DC-1 + DC-2 | — | P1 | E2 | DC-1·2 |
| P-08 | Loại trừ fixture/demo | **không có** | — | — | — | ❌ **fixture lên báo cáo** | **NEW DOMAIN RULE** | DC-3 | — | **P1** | E2 | **DC-3 — chặn cứng** |
| P-09 | Trạng thái cuối ngày | **không tồn tại** (P5) | — | — | — | n/a | **NEW CAPABILITY** | domain definition + projection | — | P1 | E2 | DC-1·2·3 |
| P-10 | Điều hướng theo lớp | `ClassProgress` | `get_school_overview` | — | — | ❌ **ảo giác** | **NEEDS UI CHANGE + ROUTE** | `/school/classes/<id>` | — | **P1** (`P1-7`) | E3 | — |
| P-11 | Mở sâu vào buổi | **ô lịch không click được** | `get_school_week_schedule` | same-school | — | ⚠️ | **NEEDS UI CHANGE + ROUTE** | `/school/sessions/<id>` | — | P2 (`P2-4`) | E3 | — |
| P-12 | Verdict `Cần hỗ trợ` cấp lớp | badge trong `school.index` | `get_school_overview` (server-side) | — | — | ❌ **phán quyết bịa** | **DO NOT SHIP** | gỡ hoặc thay bằng phát biểu trung thực | — | **P1** (`P1-2`) | **R** | **trước School Today / demo kế** |
| P-13 | Khoảnh khắc + media đã ký | card + `/school/moments` | `get_school_moments` (**chỉ moment đã duyệt**) + Edge ký | consent MIN | Edge #1 **nhánh moment — PASS** | ✅ đúng | **FUNCTIONALLY REUSABLE** | đưa `/school/moments` vào nav | — | P2 (`P2-13`) | E3 | — *(không bị chặn bởi EDGE-P1-B)* |
| P-14 | Re-home School Management | `?tab=` + nav shell | — | — | — | ✅ | **REUSABLE AS-IS** | thêm deep link **cấp thực thể**, giữ `?tab=` | — | P2 | E3 | **OD-2** |

---

## 2. TEACHER

| # | Năng lực | Bề mặt hiện tại | Nguồn dữ liệu | Ranh giới uỷ quyền | Edge | TT | TD | Cần gì | Chặn | Mức | M | Cổng |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| T-01 | Tất cả buổi hôm nay | `teacher.index` HeroCard | `get_teacher_home` **`limit 1`** | ✅ theo phân công | — | ❌ count ≠ số thẻ | **NEEDS RPC EXTENSION** | trả mảng | — | **P1** (`P1-10`) | E4 | SEC1B |
| T-02 | Phân biệt đang / kế / muộn hơn | "Lớp tiếp theo" | `next_pick` lọc `>= today_end` | ✅ | — | ❌ **nhãn sai** | **NEEDS UI + RPC** | 3 vùng trong 1 dòng thời gian | — | P1 | E4 | SEC1B |
| T-03 | Báo lịch thay đổi | không tồn tại | — | ✅ | — | n/a | **NEW CAPABILITY** | thông báo thay đổi, không đổi ngầm | — | P2 | E4 | SEC1B |
| T-04 | Phân công dạy thay | không tồn tại | `session_teachers` | — | — | n/a | **NEW CAPABILITY** | nhãn tạm + mốc hết hạn | **SEC1B** | P1 | S2 | SEC1B |
| T-05 | Todo dẫn tới hành động | `TodoSection` `<div>` | `get_teacher_todo_counts` (không trả `session_id`) | ✅ | — | ⚠️ đếm đúng, không đi đâu | **NEEDS RPC EXTENSION** | trả `session_id` + bước đích | — | **P1** (`P1-3`) | E4 | SEC1B |
| T-06 | Quy tắc điểm danh quá hạn | `attendance_pending` | chỉ hôm nay + 2 state | ✅ | — | ⚠️ khung thời gian lệch | **NEEDS DOMAIN RULE** | DC-1 (**không** chỉ thêm `scheduled`) | — | **P1** (`P1-11`) | E2→E4 | DC-1 |
| T-07 | Việc nhật ký còn tồn | `journal_pending` **toàn thời gian** | — | ✅ | — | ⚠️ trộn im lặng | **NEEDS DOMAIN RULE** | khối "Còn tồn" riêng | — | P1 (`P1-11`) | E4 | DC-1 |
| T-08 | Hành động theo vai trò | Bước 4 dựng CTA cho trợ giảng | `is_lead` **đã có** trong `get_teacher_classes` | ghi = `is_session_lead` | — | ❌ **cửa hỏng** | **READY WITH UI CHANGE** | suy từ vai trò hiệu lực server | — | **P1** (`P1-12`) | **R**/E4 | D290·D293 |
| T-09 | Gửi nhật ký | `submit_session_journal` | — | ✅ `is_session_lead` | — | ✅ | **RELEASE-READY** *(logic)* | — | — | — | — | **OD-3** |
| T-10 | Kết quả consent mức hành động | chỉ có câu chung ở Tab Ảnh | `media_consent_check` (đã tồn tại) | consent MIN | — | ⚠️ mơ hồ | **NEEDS RPC EXTENSION + DOMAIN RULE** | trả **kết quả quyền**, không phải consent thô | — | P2 (`P2-12`) | E4 | OV-3 |
| T-11 | Phát / Màn chiếu TV | `teacher.classroom` | `get_lesson_guide` + Edge ký | — | Edge #1 **nhánh entitlement — PASS**; nhánh session media — **P1** | ✅ UX tốt | **FUNCTIONALLY REUSABLE** | — | — | P2 | — | học liệu: thông · media buổi: **SEC1B** |
| T-12 | Uỷ quyền route Classroom | `?session=` từ URL | `get_lesson_guide` **`same_school`** | ❌ toàn trường | ✅ | ❌ | **BLOCKED** | thu hẹp theo phân công | **SEC1B** | **P1** | S2 | SEC1B |
| T-13 | Remote / điều khiển điện thoại | 3 nút vẫn dựng | `mint_session_remote_code` = **thân rỗng** | — | `capture_session_media` 503 | ❌ **nói dối + mời thử lại** | **BLOCKED** | gỡ/ẩn/nói thật **ngay**; năng lực chờ SEC1A-R | **SEC1A-R** | **P1** (`P1-9`) | **R** → S1 | **trước QA/demo Teacher kế** |
| T-14 | Học liệu của tôi (Drive) | `/teacher/media` | `drive_my_zone` | ngăn cá nhân | Edge #1 nhánh `private_school_resource` — **P1** | ✅ | **FUNCTIONALLY REUSABLE** | re-home + SEC1B định nghĩa lớp "Drive cá nhân" | **SEC1B** | P2 | E4 | SEC1B lớp tài nguyên |
| T-15 | Đặt tên thư viện giáo trình | nav "Giáo án" → `CurriculumView` | `list_curriculum_media` | entitlement trường | ✅ | ❌ **nhãn sai** | **READY WITH UI CHANGE** | đổi thành "Thư viện CTAN" | — | P2 (`P2-14`) | E4 | — |
| T-16 | Ngữ cảnh quay lại buổi | `BackLink` **cứng** `/teacher` | — | — | — | ❌ ném sai chỗ | **READY WITH UI CHANGE** | mang theo nơi xuất phát | — | P2 | E4 | — |
| T-17 | IA Teacher Toàn bộ | nav shell hiện có | — | — | — | ✅ | **REUSABLE AS-IS** | tách view, **không mở thêm dữ liệu** | — | P2 | E1 | — |

---

## 3. BẢO MẬT & QUẢN TRỊ

| # | Hạng mục | Hiện trạng | Bằng chứng | Mức | Chủ khắc phục | Cổng |
|---|---|---|---|---|---|---|
| S-01 | Least-privilege nhân sự | đọc = `same_school`, ghi = đúng phân công | File 1 §3.2 · 27 policy SELECT | **P1** | **SEC1B** | chặn E4 |
| S-02 | 4 RPC vào-buổi rộng | `get_session_detail` · `_roster` · `_moments` · `get_lesson_guide` chỉ gate `same_school` | `prosrc` sống | **P1** | SEC1B | chặn E4 |
| S-03 | Dữ liệu trẻ liên lớp | roster trả tên · điểm danh · `needs_support` · `follow_up_needed` · `skills_observed` · `note` | `get_session_roster` `prosrc` | **P1** | SEC1B | chặn E4 |
| S-04 | Uỷ quyền tạm thời | **không tồn tại** | rà 190 secdef | P1 | SEC1B | chặn P-06·T-04 |
| S-05 | Offboarding | **không tìm thấy năng lực gỡ quyền nào** ở tầng ứng dụng | File 1 §3.4 | **P1** (`P1-6`) | SEC1B | chặn E4 |
| S-06 | Thu hồi token/session | không tìm thấy | File 1 §3.4 | P1 | SEC1B | chặn E4 |
| S-07 | Tối thiểu hoá consent thô | GV đọc 20 bản ghi consent thô | File 1 §3.3 | P2 | SEC1B | OV-3 |
| S-08 | Moment nháp | nhánh trường **không** đòi `state='approved'` | File 1 §3.4 câu 4 | P2 | SEC1B | — |
| S-09 | Tối thiểu hoá liên hệ PH | `email`/`phone` mở toàn trường qua `profiles` | File 1 §3.5 | P2 | SEC1B | — |
| S-10 | **Ghép thiết bị Kid** | mã 6 chữ số, **không đếm lần thử, không khoá**, Edge chỉ `sleep(300)` | **Edge #8 — phát hiện mới** | **P1** | **SEC1A-K** | chặn **phát hành ghép thiết bị Kid** *(không chặn nền dual-view)* |
| S-11 | Ghi công người thực hiện | **Các mutation của nhân sự đã xác thực được rà trong inventory này đều suy ra danh tính người thực hiện từ người gọi đã được server xác minh, và không tin định danh actor do client gửi.** Luồng public, luồng thiết bị và luồng hệ thống dùng mô hình quy kết khác hoặc không có người thực hiện là con người | Edge #1·2·3·4·12·13 | ✅ **PASS** | — | — |
| S-12 | Audit logging | **Quan sát thấy audit trên các nhánh nhạy cảm về bảo mật đã ghi trong inventory từng hàm** (gồm cả nhánh cho phép lẫn từ chối ở các hàm đó); không ghi mật khẩu hay token thô. **Không suy rộng thành audit phủ kín toàn hệ ngoài phạm vi bằng chứng đã ghi** | inventory từng hàm §A.1 | ✅ **PASS** *(trong phạm vi đã quan sát)* | — | — |

---

## 4. NỀN DUAL-VIEW

| # | Hạng mục | TD | Cần gì | Mức | M | Cổng |
|---|---|---|---|---|---|---|
| D-01 | Chuyển view | **NEW, KHÔNG chạm dữ liệu** | segmented control 2 nhánh | P2 | E1 | — |
| D-02 | Preference | **NEW** | lưu theo profile; **không bao giờ là đầu vào uỷ quyền** | P2 | E1 | — |
| D-03 | Bộ giải route | **NEW** | chỉ cần ở Phương án B | P2 | E1 | **OD-2** |
| D-04 | **Hợp đồng route gốc** | **CHƯA GIẢI** | chọn A hoặc B | **P1** | **trước E1** | **OD-2 — chặn V114B** |
| D-05 | Deep link | một phần đã có | giữ `?tab=`; thêm cấp thực thể | P2 | E3 | — |
| D-06 | Tiện ích toàn cục | **REUSABLE AS-IS** | Support · Notifications ở tầng shell | — | E1 | — |
| D-07 | Trạng thái tắt / không quyền | **NEEDS UI CHANGE** | 6 trạng thái §8 File 4; không dựng cửa hỏng | P1 | E1/E4 | D290 |

---

# PHỤ LỤC A — EDGE AUTHORIZATION BOUNDARY INVENTORY (16/16)

**Phương pháp:** truy vết tĩnh source **đã triển khai** qua `list_edge_functions` + `get_edge_function`; xác minh thêm ở tầng DB cho các gate mà Edge uỷ nhiệm (`kid_login_service`, `kid_pair_device_service`, `kid_create_pairing_code`, `create_private_share_link`). **Không khai thác production. Không upload. Không gửi mail. Không mutate Auth.**

**Kết luận nền:** `verify_jwt:false` ở 15/16 hàm **không phải khiếm khuyết**. Phân bố cơ chế xác thực đã kiểm chứng:

| Cơ chế | Số | Hàm |
|---|---|---|
| **Xác thực nội bộ bằng `auth.getUser()`** | **8** | `get_signed_media_url` · `upload_media` · `invite_staff` · `invite_master` · `delete_session_media` · `school_media_admin` · `upload_notification_sound` · `upload_kid_game_sound` |
| **Luồng public có chủ đích, dùng token/credential chuyên dụng** | **4** | `accept_parent_invitation` · `accept_family_invitation` *(token 256-bit, DB giữ sha256)* · `resolve_share_link` *(token 192-bit + re-check consent)* · `kid_gate` *(device token + PIN bcrypt)* |
| **Stub đã nghỉ hưu, từ chối vô điều kiện** | **2** | `invite_parent` (410) · `capture_session_moment` (410) |
| **Bí mật cron phía server** | **1** | `purge_trash` (`x-cron-secret`) |
| **`verify_jwt:true`, hiện fail-closed 503** | **1** | `capture_session_media` (ngăn chặn SEC0) |
| | **16** | |

**Giữ nguyên:** 16/16 đã rà · **0 P0** · **0 UNVERIFIED**.

## A.1 Bảng phán quyết

| # | Hàm | v | JWT | Người gọi | Xác thực nội bộ | Uỷ quyền | Scope | Tin ID từ client? | `service_role` | Mutation | Dữ liệu trẻ | Ghi công | Fail | **Phán quyết** | Chủ |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `get_signed_media_url` | 23 | off | mọi portal | `getUser` → 401 | 6 nhánh gate riêng | entitlement · consent · guardian · space · **same-school** | `media_id` — **có kiểm** | đọc + audit | không | ✅ ảnh trẻ | `prof.id` | closed | **P1 — SEC1B** *(chỉ 1/6 nhánh — xem A.3)* | SEC1B |
| 2 | `upload_media` | 19 | off | teacher · parent · family | `getUser` → 401 | 7 nhánh, mỗi nhánh RPC gate | moment · session · folder · space | có kiểm | ghi + storage | DB + Bunny | ✅ | `prof.id` | closed | **PASS WITH P2 DEBT** | — |
| 3 | `invite_staff` | 7 | off | master/sub admin | `getUser` → 401 | role + **cùng trường** | school của caller | `staff_profile_id` — **có kiểm** | tạo user + link | Auth | không | `caller.id` | closed | **PASS WITH P2 DEBT** | — |
| 4 | `invite_master` | 8 | off | platform admin | `getUser` → 401 | 3 role nền tảng | toàn nền tảng (đúng vai) | có kiểm | tạo user + link | Auth | không | `caller.id` | closed | **PASS WITH P2 DEBT** | — |
| 5 | `invite_parent` | 8 | off | — | — | — | — | — | **không** | **không** | không | — | closed | **PASS** *(410 — nghỉ hưu D260)* | — |
| 6 | `accept_parent_invitation` | 2 | off | **public có chủ đích** | token 256-bit, DB giữ sha256 | `peek_parent_invitation` | theo lời mời | token — **có kiểm hình dạng + DB** | tạo user + accept | Auth + DB | tên bé *(sau khi token hợp lệ)* | — | closed | **PASS WITH P2 DEBT** | — |
| 7 | `accept_family_invitation` | 1 | off | **public có chủ đích** | như trên | `peek_family_invitation` | theo lời mời | có kiểm | tạo user + accept | Auth + DB | tên space | — | closed | **PASS WITH P2 DEBT** | — |
| 8 | `kid_gate` | 8 | off | Cổng Kid | device token + **PIN bcrypt** | RPC service-only | theo bé | session token — có kiểm | ghi + ký + storage | DB + Bunny | ✅ **album trẻ** | — | closed | 🔴 **P1 — SEC1A-K** | **SEC1A-K** |
| 9 | `resolve_share_link` | 8 | off | **public có chủ đích** | token 192-bit | **re-check consent lúc xem** | 1 moment | token — có kiểm | đọc + ký | không | ✅ 1 ảnh | — | closed | **PASS WITH P2 DEBT** | — |
| 10 | `capture_session_media` | 4 | **on** | — | — | — | — | **không parse body** | **không** | **không** | không | — | closed | **PASS** *(SEC0 — 503)* | SEC1A-R *(khôi phục)* |
| 11 | `capture_session_moment` | 4 | off | — | — | — | — | — | **không** | **không** | không | — | closed | **PASS** *(410 — stub)* | — |
| 12 | `delete_session_media` | 4 | off | GV/master của buổi | `getUser` → 401 | `check_session_media_upload_access` | school của buổi | `session_id`+`media_id` — **có kiểm chéo** | ghi | DB *(soft)* | không | `prof.id` | closed | **PASS** | — |
| 13 | `school_media_admin` | 2 | off | master/super | `getUser` → 401 | role + **đối chiếu `school_id`** | trường được chỉ định | `school_id` — **có đối chiếu** | ghi + xoá | DB + **Bunny cứng** | không | `prof.id` | closed | **PASS WITH P2 DEBT** | — |
| 14 | `purge_trash` | 2 | off | **pg_cron** | header `x-cron-secret` *(không lộ frontend)* | chỉ item đã quá hạn | toàn hệ, giới hạn theo hạn lưu | không nhận ID | ghi + xoá | DB + Bunny | không | hệ thống | closed | **PASS WITH P2 DEBT** | — |
| 15 | `upload_notification_sound` | 6 | off | platform admin | `getUser` → 401 | **probe RLS `is_admin()`** | toàn nền tảng | `slug` — **phải tồn tại** | ghi + storage | DB + Bunny | không | — | closed | **PASS** | — |
| 16 | `upload_kid_game_sound` | 1 | off | platform admin | `getUser` → 401 | probe RLS | toàn nền tảng | `item_id` — phải tồn tại | ghi + storage | DB + Bunny | không | — | closed | **PASS** | — |

## A.2 Thống kê phán quyết

| Phán quyết | Số |
|---|---|
| PASS | **6** |
| PASS WITH P2 DEBT | **8** |
| P1 — SEC1A-K | **1** |
| P1 — SEC1B | **1** |
| P0 — SECURITY STOP-GATE | **0** |
| UNVERIFIED | **0** |

**Không điều kiện dừng nào kích hoạt.** Cụ thể, đã kiểm và **không** tìm thấy: ghi bằng `service_role` mà không xác thực người gọi · tin ID client mà không kiểm quyền · coi bí mật lộ ở frontend là đủ thẩm quyền · cho phép đọc/ghi liên trường · tạo tài khoản/lời mời/vai trò mà không có danh tính đặc quyền đã xác minh · quy hành động cho người khác với người gọi thật · thẩm quyền bearer phát lại được mà không có hạn/thu hồi · fail-open.

## A.3 Hai phát hiện P1

### 🔴 EDGE-P1-A — `kid_gate` action=`pair` không có chống dò *(MỚI)*

`kid_create_pairing_code` sinh mã **6 chữ số** (10⁶), TTL 10 phút, dùng một lần, chỉ phụ huynh đã xác thực tạo được. Phía nhận, `kid_pair_device_service` **không đếm lần thử và không khoá**; Edge chỉ `sleep(300)` khi sai và **không chặn gọi song song**.

Kẻ tấn công **không cần đăng nhập** dò được không gian 10⁶ trong cửa sổ 10 phút. Thành công trả `device_token` + `child_id` + **tên hiển thị của bé**, đồng thời **đốt mã** làm hỏng lần ghép hợp lệ.

**Vì sao là P1 chứ không phải P0:** `kid_login_service` vẫn chặn bằng **PIN bcrypt có đếm — 5 lần sai → khoá 15 phút**, cộng play window và kill switch `kid_access.enabled`. Ghép thiết bị **không** mở được album của trẻ.

**Chủ: `V114-SEC1A-K`** *(gói mới — xem §A.5)*.

### 🔴 EDGE-P1-B — nhánh `private_school_resource` của `get_signed_media_url` *(theo từng nhánh, không quơ đũa cả nắm)*

`get_signed_media_url` có **sáu nhánh uỷ quyền độc lập**. **Chỉ một nhánh** mang P1. Không được xếp mọi consumer của hàm này là bị chặn.

| Nhánh | Gate | Kết luận |
|---|---|---|
| Học liệu / entitlement | `check_curriculum_media_access` | ✅ **PASS** — tài sản thể chế, `same_school` ở đây là **đúng** |
| Guardian (kỷ vật PH · sáng tác của bé) | `child_parents` | ✅ **PASS** |
| Family (card · contribution) | `check_family_card_media_access` / `check_family_contribution_media_access` | ✅ **PASS** — consent MIN re-check tại tầng ký |
| Suy từ consent (ảnh trẻ theo moment) | `media_consent_check` | ✅ **PASS** |
| Moment School **đã duyệt** | `get_school_moments` chỉ trả moment approved + nhánh consent | ✅ **PASS** |
| **`private_school_resource` same-school** | chỉ `prof.school_id === media.linked_school_id` | 🔴 **P1 — SEC1B** |

**P1 áp ở đúng chỗ:** media gắn với **trẻ hoặc buổi học** ký được cho **bất kỳ nhân sự nào trong trường** mà **không cần phân công và không cần một vai trò giám sát có cơ sở**. Đây là bản sao ở tầng Edge của `V114A-P1-5` — **không tạo ID mới**.

**Yêu cầu cho SEC1B:** định nghĩa truy cập **theo lớp tài nguyên**, không theo một công tắc chung:

| Lớp tài nguyên | Mặc định cần định nghĩa |
|---|---|
| Học liệu / tài sản thể chế | same-school **hợp lệ** — giữ |
| Tài sản toàn trường đã duyệt | same-school **hợp lệ** — giữ |
| Drive cá nhân của nhân sự | chủ sở hữu |
| Media buổi học | nhân sự được phân công + giám sát được uỷ quyền tường minh |
| Media gắn với trẻ | phân công / consent |
| Media nháp / chưa công bố | **không bao giờ** same-school mặc định |

> ⚠️ **Không được gỡ máy móc quyền same-school khỏi tài nguyên thể chế chính đáng.** Sửa quá tay ở đây sẽ làm hỏng thư viện giáo trình và kho trường — hai thứ đang đúng.

## A.5 Tách gói thực thi SEC1A

`SEC1A` giữ vai trò **ô bảo mật chung**, nhưng **tách thành hai gói thực thi và hai cổng phát hành độc lập**.

| Gói | Phạm vi | Yêu cầu |
|---|---|---|
| **`V114-SEC1A-R`** — Remote của Giáo viên | kế thừa SEC0 | mang **nguyên vẹn 4 residual risk của SEC0**, không xoá, không hạ mức · pairing challenge · one-time · session-bound · TTL · rate-limit · capability token có scope · `channel_key` thành định danh không-bí-mật · audit · kill switch |
| **`V114-SEC1A-K`** — Siết ghép thiết bị Cổng Kid *(MỚI)* | `kid_gate` + RPC ghép | đếm lần thử ghép · rate-limit **an toàn khi gọi song song** · throttle theo **challenge / IP / thiết bị** · tiêu thụ một-lần **atomic** · cooldown/lockout · **phản hồi lỗi chung chung** · audit · chống phát lại · thu hồi thiết bị · **giới hạn metadata trả về trước khi PIN xác thực thành công** |

**Hai gói cần QA, rollback và phán quyết PASS/FAIL riêng.**

> **Ranh giới chặn:** `SEC1A-K` **chặn phát hành ghép thiết bị Cổng Kid**. Nó **không** tự động chặn shell V114B, Principal Today, hay phần IA Teacher không liên quan Remote.

## A.4 Nợ P2 gom lại

| Nợ | Hàm |
|---|---|
| Không rate-limit trên endpoint public | 6 · 7 · 9 · 8 |
| `listUsers` trần phân trang (200 / 2000 user) | 3 · 4 · 6 · 7 |
| Không kiểm magic-byte, chỉ tin MIME + đuôi tệp | 2 · 15 · 16 |
| Token share lưu **plaintext** khi nghỉ (token lời mời thì lưu sha256) | 9 |
| Xoá vĩnh viễn **không có cửa sổ hoàn tác**, lệch mô hình thùng rác | 13 |
| So sánh bí mật **không hằng thời gian**; bí mật tĩnh, chưa thấy cơ chế xoay vòng | 14 |
| Consent album Kid chọn **`child_parents ... limit(1)`** — lấy một người giám hộ bất kỳ làm "người xem" | 8 |

> Mục cuối đáng chú ý: khi một bé có **hai người giám hộ với trạng thái consent khác nhau**, hệ **chọn tuỳ tiện một người** để làm căn cứ. Chưa gây rò rỉ đã chứng minh, nhưng **trái tinh thần MIN-consent** đang áp ở mọi nơi khác. → **P2, chuyển vào SEC1B kèm OV-3.**

---

## 5. NĂNG LỰC ĐÃ THÔNG SAU FILE 5

| Đã thông | Vì sao |
|---|---|
| **E1 — V114B shell · switch · preference · ngữ pháp nav** | không chạm projection dữ liệu; view không tham gia uỷ quyền (đã kiểm 164 policy) · **với điều kiện chốt OD-2 trước** |
| **E3 — re-home School Management** | `?tab=` đã địa chỉ hoá được; thêm deep link cấp thực thể không đụng ranh giới quyền |
| **Soạn thảo DC-1 · DC-2 · DC-3** | quy tắc domain viết được ngay, không phụ thuộc bảo mật |
| **Gói remediation R** | gỡ thông điệp Remote sai · gỡ/thay badge lớp · gate CTA trợ giảng — cả ba là **gỡ bỏ**, không mở rộng |

## 6. NĂNG LỰC VẪN BỊ CHẶN

| Còn chặn | Bởi |
|---|---|
| E4 — hoàn thiện Teacher Today (T-01·02·05·06·07·10·14) | **SEC1B** (S-01·02·03·05·06) |
| Uỷ quyền route Classroom (T-12) | SEC1B |
| Năng lực Remote (T-13) | **SEC1A-R** |
| **Ghép thiết bị Cổng Kid (S-10)** | **SEC1A-K** *(không chặn V114B / Principal Today / IA Teacher không-Remote)* |
| Phát hành Principal Today (P-01·02·07·08·09) | DC-1 · DC-2 · **DC-3** |
| Tín hiệu vắng mặt (P-05) | **OD-1** |
| Người thay / uỷ quyền (P-06 · T-04) | SEC1B |
| Build V114B | **OD-2 — hợp đồng route gốc** |

## 7. ĐIỀU KIỆN TIÊN QUYẾT CHO FILE 6

| # | Điều kiện | Trạng thái |
|---|---|---|
| 1 | 16/16 Edge có phán quyết, không còn UNVERIFIED | ✅ **đạt** |
| 2 | File 3 · 4 · 5 hoàn tất | ✅ **đạt** |
| 3 | Không phát hiện nào bị âm thầm gỡ bỏ | ✅ — `P2-7` được **rút công khai kèm lý do**, không xoá lặng |
| 4 | Chặn V114C không bị hạ xuống P2 | ✅ — S-01·02·03·05·06 giữ P1 build-blocking |
| 5 | Nợ bằng chứng zero-data V114-H | ❌ **VẪN MỞ** — File 6 phải ghi là nợ, **không được tuyên bố đã đóng** |
| 6 | SEC1A tách thành SEC1A-R và SEC1A-K | ✅ ghi ở A.5 |

**Phán quyết:** **V114A ĐƯỢC PHÉP TIẾN TỚI CLOSEOUT.**

Cần phân biệt rõ: **V114A có thể AUDIT-COMPLETE trong khi việc khắc phục vẫn còn mở.** Hai chuyện khác nhau. Nợ bằng chứng zero-data V114-H **vẫn mở**, nhưng nó **không làm bộ sáu file thiếu hoàn chỉnh** — nó là một khoản nợ đã được ghi nhận, không phải một lỗ hổng trong audit.

Phán quyết đề xuất cho File 6: **`V114A AUDIT COMPLETE — PASS WITH BLOCKERS`**. **Không** dùng "PASS" trần, **không** "FORMALLY CLOSED", **không** "SEALED", **không** "RELEASE AUTHORIZED". Phán quyết chính thức thuộc về CTO/Owner sau khi duyệt File 6.

---

*Sinh trong V114A. Không canonicalize. Không cập nhật RULES/SYSTEM_MAP. Không code. Không mutate production.*
