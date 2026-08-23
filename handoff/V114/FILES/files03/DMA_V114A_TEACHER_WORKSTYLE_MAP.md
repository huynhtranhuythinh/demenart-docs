# DMA_V114A_TEACHER_WORKSTYLE_MAP.md

> **File 3/6** · Audit 2 phía Teacher (T1–T6, đủ 17 trường, luồng A + B) · trường 16 CTO (chạm dữ liệu ngoài phân công) · trường 17 (phân loại tái dùng)
> **Baseline đã verify lại đầu phiên:** code HEAD `b87b576b` · 103 migrations · 87 tables · 190 secdef · 164 policies · 1 cron — **không delta so với handoff**
> **Nguồn:** đọc source thật `teacher.tsx` (shell) · `teacher.index.tsx` · `teacher.session.$id.tsx` · `teacher.classes.tsx` · `teacher.journal.tsx` · `teacher.classroom.tsx`, và `prosrc` sống của 13 RPC liên quan. **Không suy đoán từ tên route.**
> **Ràng buộc:** Teacher `Toàn bộ` = toàn bộ **công cụ và không gian làm việc của cô đó**, KHÔNG phải toàn bộ dữ liệu trường. Không đề xuất mở dữ liệu trẻ toàn trường cho GV.

---

## 0. BẢN ĐỒ BỀ MẶT THẬT

### 0.1 Shell `teacher.tsx` — 7 mục nav, không có "Toàn bộ"

| Nhóm | Mục |
|---|---|
| Lớp học | Hôm nay (`/teacher`) · Lớp của tôi (`/teacher/classes`) · Nhật ký (`/teacher/journal`) |
| Chương trình & Media | Giáo án (`/teacher/curriculum`) · Học liệu (`/teacher/media`) |
| Hỗ trợ | Hỗ trợ từ Dế Mèn (`/teacher/support`) · Thông báo (`/teacher/notifications`) |
| Sắp ra mắt · V1.5 | Hồ sơ (khoá) |

**3 route Teacher tồn tại nhưng KHÔNG có trong nav — cả ba đều đúng thiết kế:**
- `/teacher/moments` — **redirect đã nghỉ hưu từ V89**: toast *"Khoảnh khắc hiện được tạo và gửi trong từng buổi học"* → `navigate('/teacher', replace: true)`. Giữ lại để xử lý bookmark cũ. **Không phải bề mặt chết** *(đính chính: bản nháp đầu của File 3 gọi đây là route mồ côi — sai, đã rút)*;
- `/teacher/classroom` — chỉ mở qua `window.open` từ Bước 2 (màn TV);
- `/teacher/session/$id` — chỉ tới qua điều hướng.

### 0.2 Ma trận RPC — trục uỷ quyền thật *(bằng chứng quyết định cho trường 16)*

| RPC | Guard thật trong `prosrc` | Phạm vi thực tế |
|---|---|---|
| `get_teacher_home` | `cd.lead_teacher_id = me` **OR** `session_teachers.profile_id = me` | ✅ **theo phân công** |
| `get_teacher_todo_counts` | như trên | ✅ theo phân công |
| `get_teacher_journals` | như trên | ✅ theo phân công |
| `get_teacher_classes` | như trên | ✅ theo phân công |
| **`get_session_detail`** | `is_admin() OR same_school(...)` | ❌ **toàn trường** |
| **`get_session_roster`** | `same_school(...)` | ❌ **toàn trường** |
| **`get_session_moments`** | `same_school(...)` | ❌ **toàn trường** |
| **`get_lesson_guide`** | `same_school(...)` | ❌ **toàn trường** |
| `start_session` | `is_session_lead` / `is_session_teacher` | ✅ least-privilege |
| `submit_session_journal` | `is_session_lead` | ✅ least-privilege |
| `remove_moment_media_service` | `is_session_lead` / `is_session_teacher` | ✅ |
| `archive_empty_draft_moment_service` | `is_session_lead` / `is_session_teacher` | ✅ |
| `mint_session_remote_code` | **thân hàm rỗng — luôn trả `remote_temporarily_disabled`** | 🚫 đã vô hiệu ở SEC0 |

**Bất đối xứng cốt lõi phía Teacher:** *bốn RPC vào-buổi đọc theo `same_school`, trong khi bốn RPC danh-sách đọc theo phân công.* Nghĩa là **danh sách thì đúng, cửa vào thì rộng**. Đây không còn là quan sát ở tầng policy — đây là **một route thật, có thể gõ tay**.

---

## 1. AUDIT 2 — JOURNEY TEACHER (T1–T6)

Ký hiệu: **A** = đầu ngày bình thường · **B** = ngày bị gián đoạn.
Persona chuẩn: **GV Mỹ Linh** (`gv.linh.kidshouse@demo.demenart.com` / `Test@123`), lead_teacher, Kids House Montessori Đà Nẵng.

---

### T1 — "Hôm nay tôi phải làm gì?"

| Trường | Ghi nhận |
|---|---|
| 1. Persona · kịch bản | GV Mỹ Linh, 7:15 sáng, mở laptop trong phòng giáo viên |
| 2. Câu hỏi khởi đầu | "Hôm nay tôi dạy gì, mấy giờ, và còn việc gì chưa xong?" |
| 3. Bề mặt bắt đầu thật | `/teacher` — Greeting + `today_count` + **1 thẻ buổi** + Chuẩn bị + Việc cần làm |
| 4. Chạm | **A: 0 chạm** để thấy buổi *đầu tiên*. Nhưng xem buổi **thứ hai** trở đi = **không có đường nào từ Home** |
| 5. Chuyển route/module | 0 |
| 6. Mất ngữ cảnh | Có — `today_count` nói "3 tiết", giao diện chỉ dựng **một** thẻ |
| 7. Phải tự suy ra | Hai tiết còn lại nằm ở đâu · "Lớp tiếp theo" là tiết sau trong ngày hay ngày khác · vì sao "3 tiết" mà chỉ có một thẻ |
| 8. Điều kiện ẩn | `get_teacher_home` có **`limit 1`** ở `today_pick`, và `next_pick` lọc `scheduled_at >= v_today_end` → **"Lớp tiếp theo" KHÔNG BAO GIỜ là tiết thứ hai của hôm nay** |
| 9. Phải vào lại / gánh nặng nhớ | **Có, nặng.** Cô phải tự nhớ mình còn mấy lớp rồi vòng qua `/teacher/classes` dò lại |
| 10. Bị RLS chặn / gây hiểu nhầm | Không bị chặn. **Gây hiểu nhầm: có.** Nhãn "Lớp tiếp theo" mô tả sai nội dung |
| 11. Ngõ cụt | **Có.** Tiết 2 và 3 của hôm nay không có đường vào từ bề mặt Hôm nay |
| 12. Xác nhận hoàn tất | Có một phần — headline "Mọi việc đã sẵn sàng 🌿", nhưng chỉ tính theo **một** buổi |
| 13. Dữ liệu cần cho quyết định kế tiếp | Danh sách **tất cả** tiết hôm nay + giờ + trạng thái → **chỉ có count, không có danh sách** |
| 14. Luồng A | Trả lời được **một phần** — đúng với GV 1 tiết/ngày, sai với GV nhiều tiết |
| 15. Luồng B | Xem T1-B dưới |
| 16. **Chạm dữ liệu ngoài phân công?** | **KHÔNG.** `get_teacher_home` + `get_teacher_todo_counts` đều khoá theo `lead_teacher_id`/`session_teachers`. Bề mặt này sạch |
| 17. Phân loại tái dùng | **READY WITH UI CHANGE + NEEDS RPC EXTENSION** — dữ liệu đã đúng scope, nhưng RPC phải trả **mảng** thay vì `limit 1` |

**T1-B (gián đoạn: cô được xếp dạy thay một lớp không phải lớp mình lúc 7:40).**
Buổi dạy thay chỉ xuất hiện ở `/teacher` **nếu** đã có bản ghi trong `session_teachers` hoặc `lead_teacher_id`. Trước khi được ghi nhận chính thức, cô **không thấy gì**. Sau khi được ghi nhận, buổi xuất hiện — nhưng nếu cô đã có tiết khác cùng ngày ưu tiên cao hơn theo thứ tự `in_progress → report_pending → scheduled`, buổi dạy thay có thể **bị `limit 1` che mất**. Không có bề mặt nào nói "hôm nay lịch của cô vừa thay đổi".

---

### T2 — Chuẩn bị lớp kế tiếp

| Trường | Ghi nhận |
|---|---|
| 1. Persona · kịch bản | Mỹ Linh, 8:20, còn 25 phút trước tiết CTAN lớp Hoa Hồng |
| 2. Câu hỏi khởi đầu | "Buổi này cần chuẩn bị gì, học liệu có sẵn chưa?" |
| 3. Bề mặt bắt đầu thật | `/teacher` → thẻ `PrepCard` (checklist nhãn thật, lấy từ `get_session_detail`) |
| 4. Chạm | **A: 0 chạm để ĐỌC checklist. 1 chạm ("Xem chuẩn bị") để TICK.** Home render checklist nhưng các dòng **không tương tác được** — chỉ `<li>`, không phải `<button>` |
| 5. Chuyển route | `/teacher` → `/teacher/session/$id` (Bước 1) |
| 6. Mất ngữ cảnh | Nhẹ — vào đúng Bước 1 nhờ `stepForState` |
| 7. Phải tự suy ra | Tick xong rồi thì buổi có tự chuyển `prep_ready` không (**không** — `toggle()` chỉ `update prep_items.is_ready`, không đổi `lesson_sessions.state`) · "Thiếu học liệu" nghĩa là thiếu file hay thiếu đồ vật lớp |
| 8. Điều kiện ẩn | `PrepCard` **tự ẩn khi `total === 0`** → buổi không có mục chuẩn bị thì Home **không nói gì cả**, giống hệt trạng thái "chưa tải xong" |
| 9. Phải vào lại | Có — đọc ở Home, tick ở Bước 1: **hai nơi cho một việc** |
| 10. Bị RLS chặn / hiểu nhầm | `prep_items` policy gán role `{public}` (P2 hygiene đã ghi ở file 1). Ghi được đúng least-privilege |
| 11. Ngõ cụt | Không |
| 12. Xác nhận hoàn tất | Có — thanh tiến độ + `(ready/total)` + gạch ngang dòng đã xong |
| 13. Dữ liệu cần | Nội dung buổi · học liệu có sẵn không → **chỉ biết sau khi vào Bước 2**; Bước 1 không hé lộ giáo án |
| 14. Luồng A | ✅ hoàn thành được, chi phí thấp |
| 15. Luồng B | Học liệu lỗi → nút **"Báo thiếu học liệu"** ghi thẳng `support_requests`. **Đây là một trong những chỗ trung thực nhất của toàn hệ**: không giả vờ cô sửa được, đúng D75 |
| 16. **Chạm dữ liệu ngoài phân công?** | ⚠️ **CÓ.** `get_session_detail` gate `same_school` → gõ `/teacher/session/<id-lớp-khác>` sẽ trả **prep_items + readiness + child_count** của buổi cô không dạy |
| 17. Phân loại tái dùng | **READY NOW** cho nội dung · **BLOCKED BY SEC1B** cho ranh giới truy cập |

---

### T3 — Bắt đầu và tiến hành buổi dạy

| Trường | Ghi nhận |
|---|---|
| 1. Persona · kịch bản | Mỹ Linh, 8:45, 12 bé đã vào lớp, TV đã bật |
| 2. Câu hỏi khởi đầu | "Bắt đầu buổi, chiếu học liệu lên TV, dẫn dắt theo giáo án" |
| 3. Bề mặt bắt đầu thật | `/teacher/session/$id` Bước 1 → nút **"Vào dạy"** (`start_session`) → Bước 2 |
| 4. Chạm | **Vào dạy = 1 chạm.** Chiếu lên TV = 1 chạm mở cửa sổ + **1 chạm "Bắt đầu trình chiếu" trên chính màn TV** (bắt buộc — mở khoá autoplay). Tổng tối thiểu **3 chạm trên 2 thiết bị/cửa sổ** |
| 5. Chuyển route/module | `/teacher/session/$id` (điều khiển) ⟷ `/teacher/classroom?session=&k=` (màn phát), đồng bộ qua `useSessionChannel` |
| 6. Mất ngữ cảnh | Có — đây là mô hình **hai cửa sổ**. Cửa sổ điều khiển và cửa sổ phát là hai ngữ cảnh riêng, không có bề mặt nào nói rõ cái nào đang là "thật" |
| 7. Phải tự suy ra | "Trình chiếu" khác gì "Chiếu lên TV" · vì sao có lúc phải "Chạm để bật tiếng trên TV" · aux "chiếu chèn" khác gì học liệu trong phần |
| 8. Điều kiện ẩn | Autoplay policy trình duyệt (`needTap`) · `slideshowOn` chỉ ở Phần `_intro` · video chờ bấm chứ không tự phát |
| 9. Phải vào lại | Không, nếu không đóng cửa sổ Màn chiếu |
| 10. **Bị RLS chặn / gây hiểu nhầm** | 🔴 **CÓ — defect mới, xem T3-SEC dưới** |
| 11. Ngõ cụt | 🔴 **CÓ — nhóm nút Remote** |
| 12. Xác nhận hoàn tất | Có — pill trạng thái (`Sẵn sàng/Đang phát/Tạm dừng/Không học liệu/Lỗi phát`) + chỉ báo `● Màn chiếu` |
| 13. Dữ liệu cần | Kịch bản từng phần · câu hỏi gợi mở · học liệu → **có đủ**, `get_lesson_guide` trả `objective/script/questions/media/materials` tách vai trò `present` vs `teacher_guide` |
| 14. Luồng A | ✅ Đây là bề mặt **hoàn thiện nhất** của toàn sản phẩm |
| 15. Luồng B | Mất mạng → `onMediaError` có retry 1 lần + xoá cache URL ký; lỗi ký URL báo lý do thật. Xử lý gián đoạn **tốt** |
| 16. **Chạm dữ liệu ngoài phân công?** | ⚠️ **CÓ.** `get_lesson_guide` gate `same_school`. Ngoài ra `/teacher/classroom?session=<id>` nhận `session` **trực tiếp từ URL** và gọi `get_lesson_guide` — cửa vào bằng query param, cũng chỉ chặn ở mức trường |
| 17. Phân loại tái dùng | Trải nghiệm phát/TV = **FUNCTIONALLY REUSABLE** · uỷ quyền route Classroom + buổi = **BLOCKED BY SEC1B** · Remote/ghép cặp = **BLOCKED BY SEC1A**. **Route Classroom và `get_lesson_guide` KHÔNG được coi là sẵn sàng phát hành chừng nào còn đọc ngang trong cùng trường** |

#### 🔴 T3-SEC — DEFECT MỚI: cụm Remote nói dối và mời thử lại vô hạn

Bằng chứng tĩnh, ba mảnh khớp nhau:

1. `mint_session_remote_code` hiện là **thân hàm rỗng**:
   `begin return jsonb_build_object('ok', false, 'reason', 'remote_temporarily_disabled'); end;`
2. `REMOTE_STATES = ["scheduled","prep_ready","makeup","in_progress"]` → với buổi đang dạy, `remoteAllowed === true` → UI **vẫn dựng đủ 3 nút** "Chiếu lên TV" · "Mở điều khiển" · "Kết nối điều khiển", và `useEffect` **tự động gọi RPC** ngay khi vào Bước 2.
3. `mapRemoteReason()` **không có nhánh cho `remote_temporarily_disabled`** → rơi vào `default`:
   *"Chưa tạo được mã điều khiển. Cô kiểm tra mạng rồi thử lại nhé."* với **`retry: true`** → nút **"Thử lại"** được vẽ ra.

Hệ quả thực tế với cô giáo:
- hệ **đổ lỗi cho mạng của trường** trong khi nguyên nhân là một quyết định bảo mật của Dế Mèn;
- hệ **mời cô bấm lại** một hành động chắc chắn không bao giờ thành công → **vi phạm D290** ("cửa chắc chắn dẫn tới không-được-phép là bug");
- `openMonitor()`/`openRemote()` vẫn chạy dù `ensureRemoteCode()` trả `null`: `openRemote` mở `/remote#k=` **rỗng** (hỏng thật), `openMonitor` mở `/teacher/classroom?session=…&k=` rỗng — may mắn còn chạy được vì `channelKey = k || sessionId`.

Đồng thời **mâu thuẫn nội bộ về thông điệp**: `/teacher` (Home) treo nhãn *"Sắp ra mắt · V1.1"* lên đúng hai năng lực **"Mở Classroom View trên TV"** và **"Kết nối điện thoại làm remote"**, trong khi `/teacher/session/$id` lại **mời cô dùng ngay hai thứ đó**. Một sản phẩm, hai lời khai.

→ Ghi nhận **V114A-P1-9**. Không vá trong V114A (audit-only), đưa vào gói remediation trước build.

---

### T4 — Ghi nhận bằng chứng và media

| Trường | Ghi nhận |
|---|---|
| 1. Persona · kịch bản | Mỹ Linh, giữa buổi, bé Bo lần đầu gõ đúng nhịp — cô muốn chụp lại |
| 2. Câu hỏi khởi đầu | "Chụp nhanh, gắn đúng bé, đừng làm gãy mạch lớp" |
| 3. Bề mặt bắt đầu thật | Bước 2 → thanh điều khiển nhanh → **"Chụp khoảnh khắc"** → `goToRecord("photo")` → Bước 3 Tab Ảnh |
| 4. Chạm | **1 chạm** để tới Tab Ảnh · 1 chạm "Thêm ảnh" · chọn file · rồi **1 chạm/bé để gắn**. Quay lại dạy = 1 chạm |
| 5. Chuyển route | 0 — Bước 2↔3 là state nội bộ, **không đổi route**. Thiết kế tốt |
| 6. Mất ngữ cảnh | **Có, thật sự:** rời Bước 2 nghĩa là rời bảng điều khiển. Nếu đang phát, việc phát trên TV vẫn tiếp tục (kênh riêng), nhưng cô **mất mắt nhìn** vào timeline/âm lượng |
| 7. Phải tự suy ra | Ảnh chưa gắn bé thì có gửi đi không (**không** — có cảnh báo, tốt) · draft khác approved thế nào · bé vắng vì sao không hiện trong danh sách gắn |
| 8. Điều kiện ẩn | Chỉ nhận JPG/PNG/WEBP ≤10MB · phải có `meta.class_id` · bé `absent` **bị ẩn khỏi danh sách gắn** trừ khi đã lỡ gắn trước đó |
| 9. Phải vào lại | Có — gắn bé thường làm sau buổi, phải quay lại Bước 3 Tab Ảnh (có đường tắt "Sửa ảnh & ghi nhận" ở Bước 4 — tốt, D103) |
| 10. Bị RLS chặn / hiểu nhầm | Ghi đúng least-privilege. Upload nhiều ảnh có xử lý **partial failure** tử tế: thành công một phần → giữ draft + cảnh báo; thất bại toàn phần → `archive_empty_draft_moment_service`, **không hard-delete, không tự retry**, và nếu dọn lỗi thì **báo lỗi thật** thay vì giả vờ sạch |
| 11. Ngõ cụt | Nhẹ — không có đường từ ảnh sang `/teacher/media` hay `/teacher/moments` |
| 12. Xác nhận hoàn tất | Có — `Đang tải x/y ảnh…`, badge `Đã gửi tới ba mẹ`, cảnh báo `Chưa gắn bé — ảnh chưa gửi được` |
| 13. Dữ liệu cần | Bé nào có mặt · bé nào chưa consent → **có mặt: có** · **consent: KHÔNG hiện ở đây**, chỉ nói chung chung "Bé chưa đồng ý sẽ tạm giữ với gia đình bé đó" |
| 14. Luồng A | ✅ |
| 15. Luồng B | Bé vắng bị gắn nhầm → cảnh báo đỏ, có nút bỏ gắn. Tốt |
| 16. **Chạm dữ liệu ngoài phân công?** | ⚠️ **CÓ ở tầng đọc** — `get_session_moments` gate `same_school`. Tầng ghi thì sạch |
| 17. Phân loại tái dùng | **READY NOW** · consent hiển thị = **NEEDS DOMAIN RULE** (cô cần **kết quả quyền ở mức hành động**, không phải bản ghi consent thô — đúng §3.5 file 1) |

---

### T5 — Hoàn tất điểm danh và việc còn tồn

| Trường | Ghi nhận |
|---|---|
| 1. Persona · kịch bản | Mỹ Linh, 11:30, vừa dạy xong 2 lớp, nhớ mang máng lớp sáng chưa điểm danh xong |
| 2. Câu hỏi khởi đầu | "Lớp nào còn thiếu điểm danh, đi thẳng tới đó" |
| 3. Bề mặt bắt đầu thật | `/teacher` → `TodoSection` → dòng **"Lớp chưa điểm danh: N"** |
| 4. Chạm | **Từ Home: 0 đường đi.** Dòng đó là `<div>`, không phải `<Link>`, và `get_teacher_todo_counts` **không trả `session_id`**. Đường vòng thật: `/teacher/classes` (1) → dò đúng lớp (0 chạm, đọc mắt) → chạm dòng buổi (1) → Bước 3 → tab Điểm danh (1) = **≥3 chạm + 1 lần phải nhớ**. Đường vòng tốt hơn: `/teacher/journal` (1) → mục "Cần ghi nhận" → "Ghi nhận ngay" (1) = **2 chạm**, nhưng Home **không hề trỏ tới** |
| 5. Chuyển route | `/teacher` → `/teacher/classes` hoặc `/teacher/journal` → `/teacher/session/$id` |
| 6. Mất ngữ cảnh | Toàn phần — con số ở Home không mang theo danh tính buổi nào |
| 7. Phải tự suy ra | Buổi nào đang bị đếm · vì sao buổi sáng qua không nằm trong đó |
| 8. **Điều kiện ẩn — nghiêm trọng** | `attendance_pending` chỉ đếm buổi **hôm nay** ***và*** state ∈ `('in_progress','taught_report_pending')`. `journal_pending` ở ngay dòng dưới lại đếm **toàn thời gian, không giới hạn ngày**. Hai dòng cạnh nhau dưới một tiêu đề **"Việc cần làm hôm nay"** chạy trên **hai khung thời gian khác nhau**, và không dòng nào nói ra. **Đính chính CTO:** KHÔNG được kết luận rằng mọi buổi `scheduled` thiếu điểm danh lẽ ra phải đang chờ — một buổi chưa tới giờ mà chưa điểm danh là **bình thường**. Vấn đề thật là **khung thời gian không nhất quán + thiếu quy tắc nghiệp vụ cho điểm danh quá hạn**. Xem `V114A-P1-11` |
| 9. Phải vào lại | Có, nhiều lần |
| 10. Bị RLS chặn / gây hiểu nhầm | **Gây hiểu nhầm: có.** Xem trường 8. Thêm: dòng **"Phản hồi phụ huynh mới"** luôn hiện với giá trị `—` vì `v_parent_replies` **hardcode = 0** ("chưa có bảng reaction/message"). Một affordance chết nằm vĩnh viễn trong danh sách việc |
| 11. Ngõ cụt | **Có** — chính là P1-3 |
| 12. Xác nhận hoàn tất | Có, trong Bước 3: `Có mặt N/M` + "Đã tự động lưu" |
| 13. Dữ liệu cần | `session_id` của buổi còn thiếu → **KHÔNG có** |
| 14. Luồng A | ❌ không đi thẳng được |
| 15. Luồng B | Buổi hôm qua bỏ dở: **không xuất hiện ở Home**, cũng **không xuất hiện ở mục "Cần ghi nhận"** của `/teacher/journal` (mục đó chỉ lọc `journal_status === 'in_progress'`) → buổi quá hạn chưa từng bắt đầu bị đẩy xuống **"Đã gửi & lịch sử"** với nhãn `Chưa ghi`. **Việc trễ bị chôn trong lịch sử.** |
| 16. **Chạm dữ liệu ngoài phân công?** | **KHÔNG** ở tầng đếm. `get_teacher_todo_counts` khoá đúng phân công, `photos_untagged` còn khoá thêm `uploaded_by = me` (tác giả) — đúng chuẩn |
| 17. Phân loại tái dùng | **NEEDS RPC EXTENSION** (trả `session_id[]`) + **NEEDS DOMAIN RULE** (thống nhất khung thời gian) — **KHÔNG phải capability mới**. Bề mặt đích (`/teacher/journal` mục "Cần ghi nhận" có CTA đi thẳng) **đã tồn tại và đã đúng scope** |

---

### T6 — Hoàn tất nhật ký và đóng ngày

| Trường | Ghi nhận |
|---|---|
| 1. Persona · kịch bản | Mỹ Linh, 16:40, trước khi về |
| 2. Câu hỏi khởi đầu | "Còn gì chưa gửi cho ba mẹ? Ngày hôm nay đã đóng chưa?" |
| 3. Bề mặt bắt đầu thật | `/teacher/session/$id` Bước 4, hoặc `/teacher/journal` |
| 4. Chạm | Từ Bước 3: **1 chạm**. Từ Home: xem T5 (không đi thẳng được). Gửi = **1 chạm** |
| 5. Chuyển route | 0 nếu đang trong session flow |
| 6. Mất ngữ cảnh | Nhẹ |
| 7. Phải tự suy ra | "Gửi lại nhật ký" làm gì (có câu giải thích — tốt) · ghi chú nào tới ba mẹ, ghi chú nào chỉ nội bộ (**có nói rõ** — tốt) |
| 8. Điều kiện ẩn | `submit_session_journal` gate **`is_session_lead`** → **trợ giảng KHÔNG gửi được nhật ký**. Bước 4 **vẫn dựng nút "Hoàn tất & gửi nhật ký"** cho trợ giảng; chỉ khi bấm mới nhận *"Chỉ giáo viên phụ trách buổi mới gửi được nhật ký."* → **cửa dẫn tới `forbidden`, vi phạm D290**, cùng họ với **D293** (gate UI phải phản chiếu **mọi** nhánh uỷ quyền của RPC, không chỉ nhánh sở hữu) |
| 9. Phải vào lại | Có nếu quên gắn bé — nhưng có đường tắt "Sửa ảnh & ghi nhận" |
| 10. Bị RLS chặn / gây hiểu nhầm | **CÓ — trường hợp trợ giảng ở trên** |
| 11. Ngõ cụt | Không, sau khi gửi có nút "Về Hôm nay" |
| 12. Xác nhận hoàn tất | ✅ **Xuất sắc** — màn xác nhận nói **số thật**: `journey_created` bé, `moments_approved` ảnh, kèm câu về bé chưa consent. Không hô khẩu hiệu |
| 13. Dữ liệu cần | Tổng kết điểm danh · bé nổi bật · bé cần theo dõi · ảnh gửi được / chưa gắn / gắn nhầm bé vắng → **có đủ, tính ở client từ roster + moments, đúng logic** |
| 14. Luồng A | ✅ |
| 15. Luồng B | Còn bé chưa điểm danh → cảnh báo *"Còn N bé chưa điểm danh"* nhưng **vẫn cho gửi**. Đây là **lựa chọn thiết kế cần Owner xác nhận**, không tự động là bug |
| 16. **Chạm dữ liệu ngoài phân công?** | Đọc: **CÓ** (roster + moments qua `same_school`). Ghi: **KHÔNG** (`is_session_lead`) |
| 17. Phân loại tái dùng | **READY NOW** · gate UI cho trợ giảng = **READY WITH UI CHANGE** · ranh giới đọc = **BLOCKED BY SEC1B** |

---

## 2. TỔNG HỢP AUDIT 2 — TEACHER

| Journey | Trả lời được câu hỏi khởi đầu? | Nút thắt chính |
|---|---|---|
| T1 Hôm nay làm gì | ⚠️ chỉ đúng với GV 1 tiết/ngày | `limit 1` che các tiết còn lại |
| T2 Chuẩn bị | ✅ | checklist đọc-một-nơi / tick-một-nơi |
| T3 Dạy học | ✅ về chức năng | cụm Remote nói dối (P1-9) |
| T4 Ghi nhận & media | ✅ | consent không hiện ở điểm quyết định |
| T5 Việc còn tồn | ❌ | đếm không dẫn tới hành động + hai khung thời gian trộn lẫn |
| T6 Đóng ngày | ✅ | cửa gửi nhật ký mở sai cho trợ giảng |

**Kết luận Audit 2 phía Teacher:** ngược hẳn với Principal. **Teacher đã có nhịp ngày thật và luồng làm việc thật (T2→T3→T4→T6 gần như liền mạch).** Chỗ gãy nằm ở **hai đầu**: đầu vào (`Hôm nay` chỉ dựng một buổi) và đường quay lại (`Việc cần làm` không dẫn đi đâu). Đây là bài toán **hoàn thiện**, không phải bài toán **xây mới** — điều này xác nhận lại nhận định ở File 1 §1: thứ tự sprint trong brief V114 gốc cần đảo.

---

## 3. TỔNG HỢP TRƯỜNG 16 — RANH GIỚI TRUY CẬP CỦA TEACHER

**Phát hiện quan trọng nhất của File 3.**

Ở File 1, việc GV đọc rộng toàn trường được ghi ở **tầng policy** (27 policy SELECT dùng `same_school`). File 3 nâng nó lên **tầng route có thật**:

> **`/teacher/session/<bất kỳ session_id nào trong trường>` là một route dựng được, gọi được, và trả về dữ liệu đầy đủ.**
> `get_session_roster` chỉ chặn `same_school` và trả về: **họ tên từng bé · điểm danh · `is_highlight` · `needs_support` · `follow_up_needed` · `skills_observed` · `note` riêng của cô khác**.

Đây là **loại dữ liệu nhạy cảm nhất trong hệ** (nhận xét phát triển của trẻ), và nó **không nằm sau một API nội bộ mơ hồ** — nó nằm sau **một thanh địa chỉ**.

| | Tầng danh sách | Tầng vào-buổi |
|---|---|---|
| Nguồn | `get_teacher_home` · `_classes` · `_journals` · `_todo_counts` | `get_session_detail` · `_roster` · `_moments` · `get_lesson_guide` |
| Guard | phân công (`lead_teacher_id` / `session_teachers`) | `same_school` |
| Kết quả | ✅ đúng least-privilege | ❌ toàn trường |

### 3.1 Phát biểu đúng mức *(đính chính CTO — không được hạ giọng)*

Đây **không phải** rủi ro tiềm ẩn, và **không** phụ thuộc vào việc đoán ra một UUID khó đoán. Ghi đúng năm điều sau:

1. **GV hiện đọc được bản ghi buổi học của toàn trường** — 27 policy SELECT dùng `same_school`, và `lesson_sessions` nằm trong số đó.
2. **Do đó `session_id` KHÔNG phải là bí mật uỷ quyền.** Nó là một giá trị GV đã có quyền đọc hợp lệ, không phải một token phải đoán.
3. **Bốn RPC vào-buổi chấp nhận chính những ID đó** và trả về **dữ liệu trẻ của lớp khác**: họ tên · điểm danh · `needs_support` · `follow_up_needed` · `skills_observed` · `note` riêng của cô khác.
4. → Đây là **phơi nhiễm ngang liên-lớp, ở trạng thái đã xác thực, đang tồn tại** — không phải kịch bản giả định.
5. **Lọc ở UI không làm giảm quyền hiệu lực.** Việc giao diện không vẽ cửa chỉ thay đổi *xác suất đi qua*, không thay đổi *quyền*.

**Mức:** giữ nguyên **P1 — Current Internal Exposure** (phơi nhiễm nội bộ trong một trường, không rò rỉ liên trường, không PH nào chạm tới). **Chủ sở hữu khắc phục: SEC1B.** Không nâng lên P0, không hạ xuống P2.

**Ý nghĩa cho V114:**

1. `Teacher Toàn bộ` **tuyệt đối không được** dựng trên bốn RPC vào-buổi này ở phạm vi hiện tại;
2. bất kỳ tính năng nào sinh ra **danh sách buổi rộng hơn phân công** (ví dụ "buổi của tổ chuyên môn", "buổi tôi dạy thay") sẽ **mở rộng phơi nhiễm đang tồn tại thành luồng sử dụng hàng ngày** — không phải tạo ra rủi ro mới, mà là **đưa rủi ro sẵn có ra mặt tiền**;
3. khắc phục **thuộc SEC1B**, và phải xử lý cả trợ giảng · GV chuyên biệt nhiều lớp · dạy thay có thời hạn · tác giả bản ghi · buổi lịch sử — chứ **không** thay máy móc `same_school()` bằng `user_class_ids()` (cảnh báo đã chốt ở File 1 §3.1).

**Không có tài liệu nào cho thấy phạm vi `same_school` ở bốn RPC này là quyết định vận hành có chủ ý.** Xếp `UNVERIFIED`, đưa vào bộ câu hỏi cho Cô Ngân (File 1 §8).

---

## 4. DEFECT BỔ SUNG TỪ AUDIT 2 — TEACHER

| ID | Mức | Mô tả | Trạng thái |
|---|---|---|---|
| **V114A-P1-9** | **P1** | **Cụm Remote ở Bước 2 nói dối và mời thử lại vô hạn.** `mint_session_remote_code` là thân hàm rỗng luôn trả `remote_temporarily_disabled`; `mapRemoteReason` không có nhánh này nên hiện *"kiểm tra mạng rồi thử lại"* kèm nút **Thử lại** (`retry: true`). Ba nút Remote vẫn được dựng với buổi `in_progress`. **Vi phạm D290.** Kèm mâu thuẫn thông điệp: Home dán *"Sắp ra mắt · V1.1"* lên đúng hai năng lực mà session route đang mời dùng | ❌ MỞ |
| **V114A-P1-10** | **P1** | **`get_teacher_home` `limit 1`:** Home báo `today_count = N` nhưng chỉ dựng **một** thẻ buổi, và `next_session` lọc `>= v_today_end` nên **không bao giờ** là tiết thứ hai trong ngày. GV nhiều tiết/ngày **không có đường nào** từ Hôm nay tới các tiết còn lại | ❌ MỞ |
| **V114A-P1-11** | **P1** | **Todo dùng khung thời gian không nhất quán và thiếu quy tắc nghiệp vụ cho điểm danh quá hạn.** `attendance_pending` = chỉ hôm nay + chỉ state `in_progress`/`taught_report_pending`; `journal_pending` = **toàn thời gian**; cả hai nằm dưới một tiêu đề "Việc cần làm hôm nay". Xem khung quy tắc bắt buộc bên dưới bảng | ❌ MỞ |
| **V114A-P1-12** | **P1** | **Bước 4 dựng nút "Hoàn tất & gửi nhật ký" cho trợ giảng**, trong khi `submit_session_journal` gate `is_session_lead`. Cửa chắc chắn dẫn tới `forbidden` → **D290**, và gate UI không phản chiếu đủ nhánh uỷ quyền của RPC → **D293** | ❌ MỞ |
| ~~V114A-P2-7~~ | — | ~~`/teacher/moments` là route mồ côi~~ → **RÚT LẠI. Phát hiện SAI.** Khi đọc source thật (rà có giới hạn trước File 4), `/teacher/moments` là **redirect có chủ đích từ V89**: hiển thị toast *"Khoảnh khắc hiện được tạo và gửi trong từng buổi học"* rồi `navigate('/teacher', replace: true)`. Đây là **xử lý bookmark cũ đúng chuẩn**, không phải bề mặt chết. Việc nó vắng mặt trong nav là **cố ý và đúng**. Bài học: kết luận "mồ côi" chỉ từ vắng-mặt-trong-nav là suy đoán từ tên route — đúng thứ CTO đã cấm | ✅ **RÚT** |
| **V114A-P2-13** | P2 | **`/school/moments` KHÔNG có trong nav shell School** (`NAV_GROUPS` chỉ có overview · classes · teachers · children · settings · curriculum · drive · support · notifications). Đường vào duy nhất là card "Khoảnh khắc nổi bật" ở `school.index`. Khác với `/teacher/moments`, đây là **route sống, có nội dung, không có redirect** — mất card đó là mất đường vào | ❌ mở |
| **V114A-P2-14** | P2 | **Nhãn nav Teacher "Giáo án" trỏ tới một thư viện học liệu, không phải giáo án.** `/teacher/curriculum` mount `CurriculumView`, H1 hiển thị *"Học liệu CTAN"*, dữ liệu là `list_curriculum_media` (danh sách track theo entitlement). Giáo án thật (`objective`/`script`/`questions`) chỉ tồn tại trong `get_lesson_guide` bên trong buổi học. Cùng lúc, `/teacher/media` lại mang nhãn "Học liệu" → **hai nhãn hoán đổi cho nhau** | ❌ mở |
| V114A-P2-8 | P2 | **Dòng "Phản hồi phụ huynh mới" là affordance chết** — `v_parent_replies` hardcode `0`, luôn hiện `—`, chiếm chỗ vĩnh viễn trong danh sách việc | ❌ mở |
| V114A-P2-9 | P2 | **`/teacher/journal`: badge `👶 N bé đã điểm danh` sai nghĩa.** `obs_count` đếm **mọi** `child_observations` của buổi, kể cả bản ghi chỉ có kỹ năng/ghi chú mà `attendance IS NULL` | ❌ mở |
| V114A-P2-10 | P2 | **Buổi quá hạn chưa từng bắt đầu bị chôn trong lịch sử.** Mục "Cần ghi nhận" chỉ lọc `journal_status === 'in_progress'`; buổi `scheduled` đã qua giờ rơi xuống "Đã gửi & lịch sử" với nhãn `Chưa ghi` | ❌ mở |
| V114A-P2-11 | P2 | **Checklist chuẩn bị đọc một nơi, tick một nơi.** `PrepCard` ở Home render `<li>` không tương tác; muốn tick phải sang Bước 1. Ngoài ra `PrepCard` **tự ẩn khi `total === 0`**, không phân biệt được với trạng thái đang tải |
| V114A-P2-12 | P2 | **Consent không hiện ở điểm quyết định.** Tab Ảnh chỉ có câu chung *"Bé chưa đồng ý sẽ tạm giữ với gia đình bé đó"*; cô không thấy **kết quả quyền ở mức hành động** cho từng bé trước khi gắn |

*Không có defect Teacher nào đạt mức P0 trong File 3.* Rủi ro nghiêm trọng nhất (đọc rộng ngoài phân công) đã được đăng ký ở **V114A-P1-5**, và File 3 **nâng bằng chứng** cho nó chứ không tạo ID mới.

### 4.1 `V114A-P1-11` — phạm vi bỏ sót và khung quy tắc bắt buộc

Logic hiện tại **có thể** bỏ sót:
- buổi đã qua giờ kết thúc dự kiến mà chưa từng bắt đầu;
- buổi đã diễn ra trên thực tế nhưng còn kẹt ở state sai;
- buổi tồn từ những ngày trước, chưa được xử lý dứt điểm;
- buổi bị bỏ ngỏ hoặc mở nhầm rồi quên đóng.

Quy tắc cuối cùng **phải** tính tới: giờ bắt đầu dự kiến và giờ kết thúc dự kiến · biên độ ân hạn · buổi huỷ hoặc dời · trạng thái bỏ ngỏ · loại trừ fixture/demo · phân công đã xác thực của chính GV đang đăng nhập.

> ⚠️ **Không được khắc phục bằng cách chỉ thêm `scheduled` vào truy vấn hiện tại.** Làm vậy sẽ biến mọi buổi chưa tới giờ thành "việc cần làm" — đổi một lời nói dối này lấy một lời nói dối khác.

### 4.2 `V114A-P1-9` — disposition *(đính chính CTO)*

**`REMOVE / HIDE / REPLACE WITH TRUTHFUL DISABLED STATE` — trước lần QA phiên dạy, pilot hoặc demo đối ngoại kế tiếp, cái nào tới trước.**

Không chờ SEC1A hoàn tất mới ngừng đổ lỗi cho mạng của trường và ngừng mời cô bấm một nút không thể thành công. Hai việc này độc lập: SEC1A là **khôi phục năng lực**; gỡ thông điệp sai là **ngừng nói dối**. **Không vá trong V114A** — chuyển thẳng vào gói remediation tiền-build.

### 4.3 `V114A-P1-12` — nguyên tắc phải giữ trong kiến trúc cuối

- **Không dựng CTA gửi nhật ký ở trạng thái bật** khi RPC đòi `is_session_lead`;
- kiến trúc cuối phải suy ra **khả dụng của hành động** từ **vai trò hiệu lực do server uỷ quyền**, không từ trạng thái client;
- **UI không được suy ra quyền hành động từ việc đọc được buổi.** Đọc được ≠ làm được — và ở DMA hiện tại, đọc được còn rộng hơn nhiều so với làm được.

---

## 5. TỔNG HỢP TRƯỜNG 17 — PHÂN LOẠI TÁI DÙNG

| Năng lực | Phân loại |
|---|---|
| Nhịp ngày của GV (greeting · count · thẻ buổi · prep · todo) | **READY WITH UI CHANGE** |
| Danh sách **tất cả** buổi hôm nay | **NEEDS RPC EXTENSION** (bỏ `limit 1`, trả mảng) |
| Todo dẫn thẳng tới buổi | **NEEDS RPC EXTENSION** (trả `session_id`) + **NEEDS DOMAIN RULE** (thống nhất khung thời gian) |
| Danh sách lớp + lịch sử buổi (`/teacher/classes`) | **READY NOW** |
| Sổ nhật ký + mục "Cần ghi nhận" (`/teacher/journal`) | **READY NOW** — đã đúng scope, đã có CTA đi thẳng |
| Luồng 4 bước trong buổi | **READY NOW** |
| Trải nghiệm phát / Màn chiếu TV (player, slideshow, cross-dissolve, watermark, xử lý lỗi phát) | **FUNCTIONALLY REUSABLE** |
| Uỷ quyền cho route Classroom và buổi học (`get_lesson_guide`, `?session=` từ URL) | **BLOCKED BY SEC1B** |
| Remote điện thoại / ghép cặp | **BLOCKED BY SEC1A** — và phải **gỡ hoặc nói thật cửa vào** trước đó |
| Gate UI theo vai trò lead vs trợ giảng | **READY WITH UI CHANGE** (đọc `is_lead` đã có sẵn trong `get_teacher_classes`) |
| Kết quả consent ở mức hành động cho từng bé | **NEEDS DOMAIN RULE** + **NEEDS RPC EXTENSION** |
| Bất kỳ dữ liệu nào ngoài phân công của GV | **BLOCKED BY SEC1B** |
| Tín hiệu GV vắng / dạy thay | **CAPABILITY GAP** (xem `V114A-P1-8` ở File 2) |

---

## 6. CÒN LẠI CHO FILE 4/6

Đã đọc đủ để dựng IA dual-view: shell Teacher · nhịp Hôm nay · luồng buổi · sổ nhật ký · danh sách lớp · màn chiếu.
**Chưa đọc, và File 4 không cần:** `teacher.curriculum` · `teacher.media` · `teacher.moments` · `teacher.support` · `teacher.notifications` — đây là các bề mặt **tra cứu/hỗ trợ**, sẽ được **re-home vào `Toàn bộ`** chứ không tham gia định nghĩa `Hôm nay`. Nếu File 4 cần khẳng định điều gì về nội dung bên trong chúng, phải **đọc trước, không suy đoán**.

---

*Sinh trong V114A. Không canonicalize. Không code dual-view. Không mutate production.*
