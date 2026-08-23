# DMA_V114A_CURRENT_SYSTEM_AUDIT.md

> **Trạng thái:** Audit 1 ✅ · Audit 3 (một phần) ✅ · Audit 4 ✅ **ĐÃ SỬA DIỄN GIẢI** · Audit 2 ⏳ ĐANG LÀM
> **Baseline sống (20/07/2026):** 87 tables · 190 secdef · 164 policies · 1 cron · **103 migrations** · 52 routes · 16 edge functions
> **Code HEAD:** `b87b576b` · **Docs HEAD:** `a95d9d0c`
> **Canonical:** RULES D309 · SYSTEM_MAP v1.14 · HANDOFF v113G-M1 *(file handoff chưa có trong Project Knowledge → mọi fact chỉ có trong đó = `UNVERIFIED`)*
> **Nguyên tắc:** mọi số trong file này lấy từ DB sống hoặc source thật. Không trích tài liệu lịch sử.

---

## 0. ĐÍNH CHÍNH BẮT BUỘC — diễn giải Audit 4 lần đầu là SAI

Bản audit đầu tiên trình bày:

> "Teacher và School cùng dùng `same_school`, nên một RPC Today duy nhất phục vụ được cả hai."

**Đây là suy luận ngược và phải bị loại bỏ.** Nó lấy một *sự tiện lợi khi tái dùng* rồi suy ra *tính đúng đắn về quyền*. Thực tế ngược lại: việc GV đọc được toàn trường **là một khiếm khuyết least-privilege cần điều tra**, không phải nền tảng để xây trên.

**Lọc ở UI không phải ranh giới bảo mật.** `get_teacher_home` lọc đúng, nhưng đó là lựa chọn trình bày, không phải ràng buộc. Client nào cũng gọi thẳng PostgREST được.

---

## 1. AUDIT 1 — ROUTE & SCREEN INVENTORY (đọc `routeTree.gen.ts`, không đọc tài liệu)

**57 raw fullPaths / 52 route thực.** Khớp canonical.

### School — 8 route
`/school` (shell) · `/school/` (index) · `curriculum` · `drive` · `moments` · `notifications` · `settings` · `support`

**KHÔNG tồn tại** `/school/classes`, `/school/teachers`, `/school/children`, `/school/sessions`.
Lớp / GV / Trẻ là **query-param tab** (`?tab=classes|teachers|children`) bên trong `school.index`, render qua `ManagementView` → `Tabs`. Brief V114A giả định chúng là route riêng — **giả định sai**.

### Teacher — 11 route
`/teacher` (shell) · index · `classes` · `classroom` · `curriculum` · `journal` · `media` · `moments` · `notifications` · `support` · `session/$id`

- `Remote` **không** thuộc `/teacher`; là route gốc `/remote`, **ngoài `_authenticated`** → xem §5 (P0, đã xử lý ở SEC0).
- Teacher có **cả** `moments` **và** `media`; School chỉ có `moments`. Divergence shell có thật.

### Bất đối xứng cốt lõi của V114
| | "Hôm nay" | "Toàn bộ / Quản lý" |
|---|---|---|
| **Teacher** | **đã có ~65%** (`teacher.index` đã là nhịp ngày) | IA rõ, 9 route thật |
| **School** | **≈ 0%** (không tồn tại khái niệm hôm nay) | 3 tab nhét trong 1 route — IA cần dọn |

→ Principal Today gần như greenfield; Teacher Today là hoàn thiện. Thứ tự sprint trong brief cần xem lại.

---

## 2. AUDIT 3 (một phần) — TRUTHFULNESS CỦA NGUỒN DỮ LIỆU

### 2.1 Timezone — nghi vấn lịch sử ĐÃ BỊ BÁC BỎ
| RPC | `Asia/Ho_Chi_Minh` | `now()` |
|---|---|---|
| `get_teacher_home` | ✅ | ✅ |
| `get_teacher_todo_counts` | ✅ | ✅ |
| `get_teacher_journals` | ✅ | ✅ |
| `get_school_week_schedule` | ✅ | — |
| **`get_school_overview`** | **❌** | **❌** |

`get_school_overview` **không có trục thời gian** — thuần luỹ kế. Đây là lý do kỹ thuật khiến Principal không thể biết "hôm nay thế nào".

### 2.2 P1 — Điểm sức khoẻ trường (ĐÃ SỬA — V114-H)
Công thức cũ (trình duyệt): `mean([Σdone/Σtotal, journal_sent_pct, media_pct])` → ngưỡng 80/50.
**Vô hiệu vì hai lý do độc lập:**
1. Ba đầu vào là **cùng một phân số trên cùng một tập buổi** (KHM: cả ba = 1/3). Trung bình của ba bản sao = chính nó.
2. Mẫu số coi `in_progress` là "đã dạy" — mà 2 buổi `in_progress` của KHM là **fixture demo bỏ dở từ 03/07 và 14/07**.
→ Trường bị gán "Cần hỗ trợ" vì hai buổi demo không ai đóng.
**Đã gỡ** ở commit `b87b576b`. **QA debt còn mở: chưa xác minh bằng mắt trạng thái zero-data.** V114-H **CHƯA SEALED**.

### 2.3 P1 MỚI — Verdict cấp LỚP vẫn còn (decision-integrity)
`get_school_overview` tính **server-side** cho từng distribution:
```
journal_pct >= 80 → good | >= 50 → attention | else → support ("Cần hỗ trợ")
```
Chỉ dựa **một chiều** `journal_pct`, mẫu số vẫn tính `in_progress`.

| Lớp · Môn | done/taught | journal_pct | Badge |
|---|---|---|---|
| **Hoa Hồng · CTAN** | 1/3 | 33 | 🔴 **Cần hỗ trợ** |
| Hoa Hồng · Ballet | 0/0 | — | Chưa bắt đầu |
| Hướng Dương · CTAN / Ballet | 0/0 | — | Chưa bắt đầu |

Cùng bệnh gốc với điểm trường: phán xét ngưỡng trên n=3, 2/3 là fixture chết. **P1 — chưa sửa, ngoài phạm vi V114-H.**

### 2.4 P1 — Việc cần làm của GV không dẫn tới hành động
`TodoSection` render "Lớp chưa điểm danh: N" bằng `<div>`, **không phải `<Link>`**. `get_teacher_todo_counts` chỉ trả **số đếm**, không trả `session_id`. Cô thấy còn việc nhưng không có đường đi tới → phải tự nhớ lớp nào rồi đi vòng. **Đây là trình bày lại dữ liệu, không giảm tải công việc.** Khắc phục = `NEEDS RPC EXTENSION` (nhỏ), không phải capability mới.

---

## 3. AUDIT 4 — QUYỀN & LEAST-PRIVILEGE *(đã sửa diễn giải)*

### 3.1 Truy vết tĩnh chuỗi guard
```
same_school(X)        := X = any(user_school_ids())
user_school_ids()     := array_agg(school_id) FROM profiles WHERE user_id = auth.uid()
                                                            AND school_id IS NOT NULL
```
→ Với **mọi** GV (lead lẫn trợ giảng), `same_school` đúng cho **toàn bộ trường**, độc lập hoàn toàn với việc được phân công dạy lớp nào.

```
user_class_ids()  := (lớp mình làm lead distribution) ∪ (lớp mình có trong session_teachers)
```
→ **Nguyên thuỷ least-privilege ĐÃ ĐƯỢC XÂY.** Nhưng:

> **`user_class_ids()` KHÔNG ĐƯỢC DÙNG TRONG BẤT KỲ POLICY NÀO.** (kiểm chứng: quét toàn bộ `pg_policies`, 0 kết quả)

Đây là bằng chứng quyết định: một **primitive class-scoping chưa dùng** đã tồn tại, nhưng **chưa từng được áp lên tầng ĐỌC**.

> ⚠️ **`user_class_ids()` KHÔNG phải phương án khắc phục đã được duyệt.** Nó là *bằng chứng về một primitive bị bỏ quên*, không phải một đặc tả uỷ quyền. **Cấm** thay thế máy móc mọi policy `same_school()` bằng `user_class_ids()`. Mô hình least-privilege cuối cùng phải xử lý được: GV chính · trợ giảng · GV chuyên biệt dạy nhiều lớp · dạy thay tạm thời · uỷ quyền có thời điểm bắt đầu và hết hạn · bản ghi do chính mình soạn · chuyển lớp · buổi học lịch sử · quản trị viên trường · vai trò giám sát chuyên môn · offboarding tức thì và thu hồi session. `user_class_ids()` hiện **không** mô hình hoá được phần lớn các trường hợp này.

**27 policy SELECT** dùng `same_school(...)` hoặc `child_in_my_school(...)`.

### 3.2 Ma trận quyền (ĐỌC vs GHI dùng hai trục khác nhau)
| Hành vi | Master/Sub admin | GV chính | Trợ giảng | PH |
|---|---|---|---|---|
| Đọc **mọi** buổi trong trường | ✅ | ✅ | ✅ | ❌ |
| Đổi phân công (`session_teachers`) | ✅ | ✅ (buổi mình) | ❌ | ❌ |
| Tạo/sửa buổi | ✅ | ✅ (distribution mình) | ❌ | ❌ |
| Viết/duyệt nhật ký buổi | ✅ | ✅ | ❌ | ❌ |
| **Điểm danh** (`session_marks`) | ❌ | ✅ | ✅ | ❌ |
| **Ghi media buổi** | ❌ | ✅ | ✅ | ❌ |
| **Nhận xét trẻ** | ❌ | ✅ | ✅ | ❌ |
| **Tick chuẩn bị** | ❌ | ✅ | ✅ | ❌ |
| Consent | ❌ | ❌ | ❌ | ✅ con mình |

**Ghi = `is_session_lead` / `is_session_teacher` / `is_school_admin` — đã đúng least-privilege.**
**Đọc = `same_school` — KHÔNG.** Bất đối xứng này là lỗi, không phải thiết kế.

### 3.3 Đo mức phơi nhiễm thật — GV Mỹ Linh (lead_teacher, KHM)
*(đếm bằng logic policy, KHÔNG impersonate, KHÔNG khai thác)*

| Đối tượng | Theo phân công | **Đọc được thực tế** |
|---|---|---|
| Trẻ (enrollments) | 4 | **8** (toàn trường) |
| Bản ghi consent | — | **20** |
| Learning moments | — | **13** |
| Nhận xét phát triển của trẻ | — | **toàn bộ trong trường** |
| Buổi học | — | **toàn bộ trong trường** |

### 3.4 Trả lời 7 câu CTA giao
1. **GV đọc buổi của GV khác?** → **CÓ**, toàn trường.
2. **GV đọc media lớp khác?** → **CÓ** (`session_media_select_school`).
3. **GV đọc nhận xét trẻ ngoài lớp mình?** → **CÓ** (`child_observations_select_school`). Nhạy cảm nhất.
4. **GV đọc report / enrollments / moments ngoài phân công?** → **CÓ**, cả ba. `learning_moments`: nhánh trường **không** đòi `state='approved'` (nhánh PH thì có) → GV đọc được cả moment **chưa duyệt / nháp** của lớp khác.
5. **Cái nào do mô hình vận hành cố ý?** → xem §3.5 phân loại.
6. **Cái nào là hệ quả vô tình của `same_school`?** → phần lớn; xem §3.5.
7. **Quyền có mất sau khi đổi phân công / chuyển lớp / nghỉ việc?**

   **Chỉ ghi những gì đã chứng minh:**
   - **Không guard nào kiểm tra `profiles.state`** — kiểm chứng: 0/5 hàm guard (`same_school`, `user_school_ids`, `current_profile`, `current_school_id`, `child_in_my_school`) tham chiếu `state`.
   - **Đổi `state` từ `active` sang không-active, tự nó, KHÔNG thu hồi quyền truy cập.** Quyền vẫn còn chừng nào `user_id` và liên kết `school_id` còn hợp lệ.
   - **Đổi phân công không thu hẹp quyền đọc.** `user_class_ids()` thay đổi, nhưng không policy nào dùng nó.
   - **Hiện không có fixture non-active** để kiểm chứng cơ chế thu hồi theo `state`. **Không được tạo fixture "nhân viên cũ" bằng cách mutate production.**
   - **Quy trình offboarding vận hành thực tế: `UNVERIFIED`.**

   **Rà soát mã: có workflow nào thực hiện gỡ quyền không?**

   | Hành vi gỡ quyền | Kết quả rà soát |
   |---|---|
   | Xoá `school_id` của nhân sự | **Không tìm thấy.** Chuỗi `school_id = null` duy nhất nằm trong `provision_parent_and_link` — đó là thiết kế "PH có `school_id` NULL", không phải offboarding. |
   | Gỡ liên kết `user_id` | **Không tìm thấy** |
   | Xoá profile nhân sự khỏi trường | **Không tìm thấy** |
   | Vô hiệu hoá tài khoản Auth | **Không tìm thấy** |
   | Thu hồi session / refresh token | **Không tìm thấy** |
   | Hành động gỡ quyền tường minh khác | **Không tìm thấy** |

   Rà cả 190 secdef function **và** cả 16 Edge Function. Tồn tại đầy đủ chuỗi *kết nạp* — `invite_master`, `invite_staff`, `invite_parent`, `accept_parent_invitation`, `accept_family_invitation` — nhưng **không tìm thấy hàm đối xứng nào để gỡ**.

   → **Không tìm thấy năng lực offboarding hoặc thu hồi quyền trong tầng ứng dụng đã audit. Quy trình thủ công qua Supabase Dashboard, Auth Admin hoặc vận hành ngoài ứng dụng vẫn `UNVERIFIED`.**

### 3.5 Phân loại tài nguyên và mặc định quyền tạm thời

**Mặc định tạm thời do CTO ấn định. Mọi dòng dưới đây là `PROVISIONAL` cho tới khi có kiểm chứng vận hành.**
Quyền nhìn thấy *lịch* không tự động biện minh cho quyền truy cập *chi tiết chuẩn bị* hay *nội dung gắn với trẻ*.

| Tài nguyên | Mặc định tạm thời | Hiện trạng | Phân loại |
|---|---|---|---|
| Lịch trường & cấu trúc vận hành (`classes`, `class_distributions`, `lesson_sessions`) | có thể nhìn toàn trường — **PROVISIONAL** | toàn trường | **1 (tạm)** |
| `prep_items` | **KHÔNG** mặc định toàn trường; lịch ≠ chi tiết chuẩn bị | toàn trường | **2** |
| Danh sách trẻ & dữ liệu trẻ cơ bản (`children`, `enrollments`) | chỉ lớp được phân công / uỷ quyền | toàn trường | **2** |
| Điểm danh (`session_marks`) | nhân sự của buổi + vai trò giám sát được uỷ quyền | toàn trường | **2** |
| Nhận xét phát triển (`child_observations`) | nhân sự được phân công, **tác giả**, và vai trò chuyên môn được uỷ quyền tường minh | toàn trường | **2** |
| Media buổi (`session_media`) | nhân sự lớp được phân công, tác giả, giám sát được uỷ quyền | toàn trường | **2** |
| `learning_moments` **nháp/chưa duyệt** | **không bao giờ** toàn trường theo mặc định | toàn trường (nhánh trường không đòi `state='approved'`) | **2 — vi phạm mặc định rõ rệt** |
| `consents` | GV chỉ nên nhận **kết quả quyền ở mức hành động**, không phải bản ghi consent thô | đọc thô toàn trường (20 bản ghi) | **2** |
| Dữ liệu liên hệ PH | hạn chế; **không** phải danh bạ same-school | qua `profiles`/`get_child_parents` | **2 — cần rà riêng** |
| `session_reports` | theo phân công / uỷ quyền | toàn trường | **2** |
| `profiles` đồng nghiệp | danh bạ chính đáng, nhưng `email`/`phone` cần tối thiểu hoá theo cột | toàn trường | **1, cần siết cột** |
| **Nhân sự cũ** | **không còn quyền** | **không có cơ chế gỡ ở tầng ứng dụng** | **xem §3.6** |

### 3.6 Xác định mức — KHÔNG dùng từ "Stop-Gate"

**Security/Privacy P1 — Current Internal Exposure.**
*Build-blocking cho các trải nghiệm Teacher có dữ liệu, nhưng không đòi hỏi dừng khẩn production.*

Ý nghĩa vận hành:
- Audit V114A **chỉ đọc** → **được tiếp tục**.
- Production **không** cần shutdown.
- **V114C vẫn bị chặn.**
- **Mọi trải nghiệm Teacher mở rộng hoặc phụ thuộc vào quyền đọc rộng toàn trường hiện tại đều bị chặn.**
- Phải khắc phục và kiểm chứng **trước khi phát hành** phần dual-view Teacher có mang dữ liệu.

*Không dùng thuật ngữ "Stop-Gate" cho tình trạng không làm dừng workstream bị ảnh hưởng.*

Cơ sở phân mức: không rò rỉ liên trường (`user_school_ids()` khoá theo `profiles.school_id`); không có ghi ẩn danh mới (đã đóng ở SEC0); không PH nào đọc được dữ liệu trường. Phơi nhiễm nằm trong nội bộ một trường.

### 3.7 Hệ quả cho V114 — thay cho kết luận sai ban đầu
- **View KHÔNG BAO GIỜ tham gia uỷ quyền:** rà 164 policy — **không predicate nào tham chiếu view / preference / chế độ hiển thị**. Quyền chỉ khoá theo *danh tính* + *phân công*. Đây là fact đã kiểm chứng, không phải niềm tin. ✅
- **Nhưng KHÔNG được suy ra "một RPC public dùng chung".** Theo phán quyết CTO §6–§8: backend chung ≠ RPC public chung. Dùng **projection theo persona ở phía server**, cùng domain logic bên dưới, **role và scope suy ra từ JWT phía server**, client **không** được yêu cầu projection rộng hơn qua tham số.
- **Teacher "Toàn bộ" = toàn bộ *công cụ và không gian làm việc của GV đó*, KHÔNG phải toàn bộ dữ liệu trường.** Điều này nghĩa là: V114 **không được** dựa vào quyền đọc rộng hiện tại để dựng màn hình. Nếu Teacher "Toàn bộ" cần dữ liệu ngoài phân công, phải **thiết kế uỷ quyền tường minh**, không mượn `same_school`.
- **Hiệu trưởng KHÔNG được cấp CTA "làm thay cô":** RLS chặn admin ở điểm danh, media, nhận xét trẻ, prep. Đặt nút đó = vi phạm **D290** (cửa chắc chắn dẫn tới `not_authorized`). Vắng GV → dùng **phân công lại / uỷ quyền tạm thời có ghi nhận đúng người thực hiện** (phán quyết CTO §4).

### 3.8 P2 hygiene
`learning_moments` và `prep_items` gán policy cho role `{public}` thay vì `{authenticated}`. Không rò rỉ (guard đi qua `current_profile()` → null với anon) nhưng lệch chuẩn so với phần còn lại.

---

## 4. AUDIT 2 — ⏳ ĐANG LÀM

Phương pháp đã khoá theo chỉ thị CTO: mỗi journey ghi persona · câu hỏi khởi đầu · bề mặt bắt đầu thật · số chạm · chuyển route/module · mất ngữ cảnh · điều người dùng phải tự suy ra · điều kiện ẩn · phải vào lại · hành động bị RLS chặn hoặc gây hiểu nhầm · ngõ cụt · xác nhận hoàn tất · dữ liệu cần để ra quyết định kế tiếp · luồng bình thường · luồng ngoại lệ.
Đo **cả A (đầu ngày) và B (ngày bị gián đoạn)**.

Kết quả sơ bộ đã có (sẽ đo đầy đủ):
- **T5 — hoàn tất điểm danh còn tồn:** Home → (không click được) → `/teacher/classes` → chọn lớp → tìm buổi → `/teacher/session/$id` = **≥4 chạm + 1 lần phải nhớ**, trong khi dữ liệu để đi thẳng 1 chạm đã nằm sẵn trong `get_teacher_todo_counts`.
- **P1 — Hiệu trưởng kiểm tra buổi sáng:** không có bề mặt "hôm nay"; phải đọc lưới tuần 7 cột × N lớp, `min-width 760px`, **cuộn ngang**, tự dò cột ngày hôm nay; ô lưới **không click được**.

---

## 5. DEFECT REGISTER

| ID | Mức | Mô tả | Trạng thái |
|---|---|---|---|
| V114A-P0-1 | P0 | `/remote` — điều khiển & upload ẩn danh, mã 4 số, không TTL/rate-limit/audit | ✅ **ĐÃ ĐÓNG (SEC0)** |
| V114A-P0-2 | P0 | Upload từ Remote ghi danh nghĩa cô giáo (`actor_id`/`uploaded_by`) → bằng chứng audit sai | ✅ chặn ở SEC0; provenance đúng thuộc SEC1 |
| V114A-P1-1 | P1 | Điểm sức khoẻ trường bịa ở client | ✅ **ĐÃ SỬA (V114-H)** — chờ ảnh zero-data |
| V114A-P1-2 | P1 | Verdict "Cần hỗ trợ" cấp **lớp** (server-side, 1 chiều, n nhỏ) | ❌ **MỞ** |
| V114A-P1-3 | P1 | Todo counts không actionable (không có `session_id`) | ❌ **MỞ** |
| V114A-P1-4 | P1 | Copy "Sắp ra mắt · V1.1" trong khi `/remote` đã build xong | ⚠️ nay đã đúng sự thật (remote đang tắt) — xem lại ở SEC1 |
| V114A-P1-5 | P1 | **Đọc rộng toàn trường cho GV; `user_class_ids()` không dùng ở đâu** | ❌ **MỞ → SEC1B · BUILD-BLOCKING** |
| V114A-P1-6 | P1 | **Quyền không co lại sau đổi phân công / nghỉ việc; guard không đọc `profiles.state`; không tìm thấy năng lực gỡ quyền ở tầng ứng dụng** | ❌ **MỞ → SEC1B · BUILD-BLOCKING** |
| V114A-P2-1 | P2 | `learning_moments` / `prep_items` policy gán `{public}` | ❌ mở |
| V114A-P2-2 | P2 | `QuickActions` 3 mục trong lưới 2 cột, thiếu lối tắt moments/media/journal | ❌ mở |
| V114A-P2-3 | P2 | School index: 2 RPC + 2 query bảng + **N lần invoke Edge ký ảnh** ngay lần sơn đầu | ❌ mở |

---

## 6. BUILD BLOCKER

**V114B (nền dual-view + preference):** không bị chặn. View không tham gia uỷ quyền — đã kiểm chứng.

**V114C (Teacher Today):** **BỊ CHẶN** bởi
- V114-SEC1 + controlled validation (lệnh Owner), **và**
- V114A-P1-5 / P1-6 — vì Teacher "Toàn bộ" **không được** dựng trên quyền đọc rộng hiện tại.

## 7. HAI NHÁNH KHẮC PHỤC — KHÔNG GỘP

Hai mô hình mối đe doạ khác nhau, **không được gộp vào một gói migration chung**.

### V114-SEC1A — Remote Capability Root Remediation
Kế thừa từ SEC0. Pairing challenge 6 số / one-time / session-bound / TTL ~5 phút; rate-limit; capability token ngắn hạn có scope; `channel_key` thành định danh không-bí-mật; media capture đòi capability hợp lệ; audit + kill switch.
**Mang theo nguyên vẹn 4 residual risk của SEC0, không xoá, không hạ mức.**

### V114-SEC1B — Staff Least-Privilege & Offboarding
Phải bao gồm:
- ma trận truy cập **theo từng tài nguyên**, không gộp;
- suy ra vai trò và phân công **ở phía server**;
- vòng đời **uỷ quyền tạm thời** (bắt đầu · hết hạn · thu hồi);
- offboarding + thu hồi token/session;
- tối thiểu hoá **theo cột hoặc theo projection** ở chỗ quyền theo dòng còn quá rộng (vd `email`/`phone`, consent thô);
- rà soát tương thích migration;
- **negative test xuyên lớp**;
- test đổi phân công và test hết hạn uỷ quyền;
- **test từ chối với nhân sự cũ**, dùng fixture được duyệt (**không** mutate production để tạo nhân sự cũ);
- rollback + bằng chứng audit.

---

## 8. CÂU HỎI KIỂM CHỨNG VẬN HÀNH — CHO CÔ NGÂN

Đây là câu hỏi **kịch bản**, không phải một câu nhị phân. Phỏng vấn vận hành **cung cấp thông tin cho thiết kế nhưng tự nó không cho phép mở rộng quyền** — mặc định riêng tư vẫn là quyết định của CTO/Owner.

1. GV dạy thay cần thấy gì **trước khi** được phân công chính thức?
2. Sau khi được phân công tạm thời thì có thêm dữ liệu gì?
3. Khi phân công hết hạn thì **phải mất đi** những gì?
4. GV chuyên biệt dạy nhiều lớp cần dữ liệu trẻ nào?
5. Ai cần **nhận xét phát triển** để phối hợp chuyên môn chính đáng?
6. Có GV nào cần **bản ghi consent thô** không, hay chỉ cần **kết quả quyền ở mức hành động**?
7. Ai được xem **moment nháp / media chưa công bố**?
8. **Quy trình offboarding nhân sự thực tế của trường là gì?**

---

## 9. CÂU HỎI BẢO MẬT/RIÊNG TƯ CHƯA GIẢI QUYẾT

1. Mặc định riêng tư cho `child_observations` xuyên lớp — chờ §8 rồi CTO/Owner quyết.
2. Quy trình offboarding vận hành thực tế — `UNVERIFIED`; ở tầng ứng dụng **chưa có** năng lực gỡ quyền.
3. Siết cột `email`/`phone` trong `profiles_select_same_school`.
4. `learning_moments` nháp lộ toàn trường — cố ý hay sót?
5. **14/16 Edge Function đang `verify_jwt: false`** (chỉ `capture_session_media` đã bật ở SEC0). Mỗi hàm tự làm auth riêng — chưa rà từng cái. Ghi nhận để SEC1A/SEC1B quyết phạm vi, **không kết luận trong V114A**.

---

*Sinh trong V114A. Không canonicalize. Không cập nhật RULES/SYSTEM_MAP trong giai đoạn này.*
