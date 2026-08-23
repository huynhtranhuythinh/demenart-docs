# DMA_V114A_SCHOOL_WORKSTYLE_MAP.md

> **File 2/6 — HOÀN TẤT** · Audit 2 (Principal P1–P5, đủ 17 trường, luồng A + B) · Audit 5 (Principal Hôm nay) · Audit 6 (bảo tồn School)
> **Rev Part 2 (20/07/2026):** đã áp 3 đính chính CTO — (A) tách vắng mặt khỏi chưa-phân-công + defect `V114A-P1-8`; (B) sửa toàn bộ phân loại readiness lạc quan; (C) đổi disposition badge cấp lớp thành remediation bắt buộc trước phát hành.
> **Baseline:** code HEAD `b87b576b` · 103 migrations · 164 policies
> **Nguồn:** đọc source thật `school.index.tsx`, `routeTree.gen.ts`, `prosrc` của `get_school_overview` / `get_school_week_schedule` / `get_school_moments`, và 164 policy sống.
> **Ràng buộc quyền đã chốt ở file 1:** RLS **chặn** school admin ở `session_marks`, `session_media`, `child_observations`, `prep_items`. Mọi đề xuất dưới đây tuân thủ.

---

## 1. HIỆN TRẠNG — BỀ MẶT PRINCIPAL

`/school` (shell) · `/school/` index · `curriculum` · `drive` · `moments` · `notifications` · `settings` · `support`.
Lớp / GV / Trẻ **không phải route** — là `?tab=` trong `school.index`.

`school.index` chia 3 zone: **Zone 1** Welcome + 6 KPI + card dữ liệu triển khai · **Zone 2** Tiến độ theo lớp + Lịch tuần + Khoảnh khắc + Tương tác PH (placeholder) · **Zone 3** Hỗ trợ/Thông báo + Gợi ý.

**Chi phí tải lần sơn đầu:** `get_school_overview` + `get_school_week_schedule` + `get_school_moments` + 2 query bảng trực tiếp (`support_requests`, `notifications`) + **N lần invoke Edge `get_signed_media_url`, mỗi ảnh một lần**.

**Sự thật nền tảng chi phối toàn bộ file này:** `get_school_overview` **không có `now()`, không có `Asia/Ho_Chi_Minh`** → **không tồn tại khái niệm "hôm nay" ở phía School.** Nguồn duy nhất có trục thời gian là `get_school_week_schedule`, và nó theo **tuần**, với `p_week_start` do **client** truyền.

---

## 2. AUDIT 2 — JOURNEY PRINCIPAL (17 trường)

Ký hiệu: **A** = luồng đầu ngày bình thường · **B** = luồng ngày bị gián đoạn.

### P1 — Kiểm tra buổi sáng
| Trường | Ghi nhận |
|---|---|
| Persona · kịch bản | Hiệu trưởng, 7:30 sáng, mở máy trước giờ đón trẻ |
| Câu hỏi khởi đầu | "Hôm nay trường có ổn không? Có gì cần tôi can thiệp?" |
| Bề mặt bắt đầu thật | `/school` — Welcome + 6 KPI **luỹ kế** |
| Chạm | **A: 0 chạm nhưng KHÔNG trả lời được câu hỏi.** Để tiệm cận: cuộn xuống Lịch tuần → cuộn ngang lưới `min-width 760px` → tự dò cột hôm nay = **1 cuộn dọc + 1 cuộn ngang + đọc mắt N hàng** |
| Chuyển route/module | 0 |
| Mất ngữ cảnh | KPI luỹ kế và lưới tuần **không nối với nhau**; không có neo "hôm nay" ở đâu cả |
| Phải tự suy ra | Hôm nay là thứ mấy · cột nào là hôm nay · nhãn `Sắp diễn ra` nghĩa là chưa tới giờ hay đã trễ · buổi nào thiếu GV (**không hiển thị ở đâu**) |
| Điều kiện ẩn | Lớp phải có distribution `active` mới xuất hiện trong lưới |
| Phải vào lại | Có — mỗi lần muốn kiểm tra lại phải cuộn + dò lại từ đầu |
| Bị RLS chặn / gây hiểu nhầm | **Có (đã sửa một phần)**: điểm sức khoẻ `33/100` + `Cần hỗ trợ` là số bịa ở client → đã gỡ ở V114-H. **Còn lại:** badge `Cần hỗ trợ` cấp lớp (server-side, 1 chiều, n=3) — vẫn hiện |
| Ngõ cụt | **Ô lưới lịch tuần không click được.** Thấy `Thiếu nhật ký` nhưng không đi tới buổi đó được |
| Xác nhận hoàn tất | **Không có.** Không có trạng thái "đã xem xong hôm nay" |
| Dữ liệu cần cho quyết định kế tiếp | Buổi hôm nay + trạng thái · buổi thiếu GV · buổi quá giờ chưa bắt đầu → **cả ba đều KHÔNG có** |
| Luồng A | Không hoàn thành được câu hỏi khởi đầu |
| Luồng B | Xấu hơn hẳn — xem P1-B dưới |
| Ngoài phân công? *(N/A — persona School)* | — |

**P1-B (gián đoạn: một GV báo nghỉ lúc 7:00).** Hiệu trưởng phải: mở `?tab=classes` → chọn từng lớp → đọc `GV chính:` trong panel môn → đối chiếu thủ công với lịch tuần. **Không có màn hình nào ghép hai thứ đó.** Ước tính **≥6 chạm cho 1 lớp**, nhân tuyến tính theo số lớp.

**Đính chính quan trọng (CTO Part 2):** ngay cả khi làm hết 6 chạm đó, Hiệu trưởng **vẫn không** trả lời được câu hỏi thật. Việc dò `?tab=classes` chỉ cho biết **ai được phân công**, chứ không cho biết **ai vắng**. Cuộc gọi báo nghỉ lúc 7:00 **không để lại dấu vết nào trong hệ**. Đây là hai vấn đề tách rời:
- *"Buổi này chưa có người phụ trách"* → suy ra được từ dữ liệu hiện có, chỉ thiếu projection phía server;
- *"Người phụ trách buổi này hôm nay không đến"* → **hệ không biết, và không có chỗ nào để biết** → xem `V114A-P1-8`.

---

### P2 — Tìm ra vấn đề
| Trường | Ghi nhận |
|---|---|
| Câu hỏi khởi đầu | "Lớp/GV nào đang có vấn đề, chi tiết ra sao?" |
| Bề mặt bắt đầu | Card "Tiến độ theo lớp" (Zone 2) |
| Chạm | 1 chạm vào hàng lớp |
| Chuyển route | `/school` → `/school?tab=classes` (đổi search param, `window.scrollTo(0)`) |
| **Ngõ cụt nghiêm trọng** | **Mọi hàng lớp đều gọi cùng một `onView` → luôn nhảy tới `?tab=classes` chung, KHÔNG mở đúng lớp vừa bấm.** Ngữ cảnh lớp bị mất hoàn toàn |
| Mất ngữ cảnh | Toàn phần — phải tìm lại lớp trong danh sách |
| Phải tự suy ra | `Cần hỗ trợ` nghĩa là gì (chỉ dựa `journal_pct`, không nói ra) |
| Bị RLS chặn / hiểu nhầm | Badge lớp là verdict ngưỡng trên n nhỏ — **P1 chưa sửa** |
| Xác nhận hoàn tất | Không |
| Dữ liệu cần | Buổi nào của lớp đó có vấn đề · GV phụ trách · thiếu gì cụ thể → **chỉ có % tổng hợp** |
| Luồng B | Không khác — vốn đã hỏng ở A |

**Đây là P1 defect mới: `ClassProgress` tạo ảo giác điều hướng theo lớp nhưng thực chất là một nút chung.**

---

### P3 — Kiểm tra hoàn tất giảng dạy
| Trường | Ghi nhận |
|---|---|
| Câu hỏi | "Các buổi đã dạy xong chưa? Nhật ký/bằng chứng đã đủ chưa?" |
| Bề mặt bắt đầu | KPI `Buổi đã dạy` + `Nhật ký đã gửi %` + `Buổi có media %` |
| Chạm | 0 để thấy %, **∞ để thấy buổi cụ thể nào thiếu** |
| Ngõ cụt | **Không có danh sách buổi thiếu nhật ký.** Chỉ có % và ô màu trong lưới tuần |
| Phải tự suy ra | Mẫu số của % (chỉ ghi "trên buổi đã dạy", mà "đã dạy" bao gồm cả `in_progress` — **không nói ra**) |
| Bị hiểu nhầm | **Có.** 2 buổi demo kẹt `in_progress` từ 03/07 và 14/07 đang kéo tụt cả 3 chỉ số |
| Dữ liệu cần | Danh sách buổi + trạng thái nhật ký → **không có** |
| Luồng B | Không có đường thoát |

---

### P4 — Xem hoạt động có ý nghĩa
| Trường | Ghi nhận |
|---|---|
| Câu hỏi | "Trẻ đang được học gì đẹp?" |
| Bề mặt bắt đầu | Card "Khoảnh khắc nổi bật", 4 ảnh |
| Chạm | 0 để xem 4 ảnh; 1 để sang `/school/moments` |
| Chi phí ẩn | **Mỗi ảnh 1 lần invoke Edge `get_signed_media_url`**, chạy song song sau khi RPC trả về → ảnh nhấp nháy vào sau |
| Ngõ cụt nhẹ | Ảnh trong card **không click được**, không mở lớn, không dẫn tới buổi/lớp |
| Bị RLS chặn | Không — `get_school_moments` chỉ trả moment đã duyệt |
| **Đánh giá** | **Đây là phần hoạt động ĐÚNG NHẤT của School hiện nay.** Trung thực, có nhãn "Nội bộ trường", có ghi chú consent |
| Luồng B | Không liên quan |

---

### P5 — Kiểm tra cuối ngày
| Trường | Ghi nhận |
|---|---|
| Câu hỏi | "Còn gì chưa xong trước khi tôi về?" |
| Bề mặt bắt đầu | **KHÔNG TỒN TẠI** |
| Chạm | Không đo được — không có bề mặt |
| Ngõ cụt | Toàn phần. Lịch tuần cho biết trạng thái nhưng không lọc theo hôm nay, không tổng hợp "còn tồn" |
| Dữ liệu cần | Buổi hôm nay chưa hoàn tất · nhật ký chưa gửi hôm nay · GV nào còn việc → **không cái nào có** |
| Luồng B | — |

**P5 là khoảng trống lớn nhất của Principal.**

---

### Tổng hợp Audit 2 — Principal
| Journey | Trả lời được câu hỏi khởi đầu? | Nút thắt chính |
|---|---|---|
| P1 Sáng | ❌ | Không có trục "hôm nay" |
| P2 Tìm vấn đề | ❌ | Điều hướng theo lớp là ảo giác |
| P3 Hoàn tất dạy | ⚠️ chỉ % | Không có danh sách buổi |
| P4 Hoạt động đẹp | ✅ | (chỉ thiếu mở ảnh) |
| P5 Cuối ngày | ❌ | Không có bề mặt |

**Kết luận Audit 2 phía Principal: DMA hiện đang *trình bày lại dữ liệu*, không *giảm tải công việc*.** 4/5 journey không dẫn tới hành động.

---

## 3. AUDIT 5 — PRINCIPAL "HÔM NAY" (content model, chỉ dùng dữ liệu đã kiểm chứng)

Nguyên tắc bảo vệ: **exception-first, không KPI-first.** Hiệu trưởng không cần thấy mọi thứ — cần biết trường **bình thường hay có gì cần can thiệp**.

> **ĐÍNH CHÍNH CTO (Part 2).** Bảng phân loại đầu tiên lạc quan quá mức: nhãn `READY WITH UI AGGREGATION` ngụ ý "chỉ cần gom ở client là xong", điều đó **sai** vì (a) projection theo ngày phải suy ra ở server, (b) nhiều khối còn thiếu **quy tắc nghiệp vụ**, không chỉ thiếu dữ liệu. Bảng dưới đây thay thế hoàn toàn.

| Khối | Nguồn dữ liệu đã verify | Phân loại (ĐÃ SỬA) |
|---|---|---|
| Trạng thái chung hôm nay | không nguồn nào có trục ngày | **NEEDS DOMAIN DEFINITION + SERVER PROJECTION** |
| **Việc cần chú ý** (exception list) | cần lọc theo ngày + trạng thái + quy tắc ngoại lệ | **NEEDS DOMAIN RULE + SERVER PROJECTION** |
| Lớp / buổi hôm nay | `get_school_week_schedule` có `scheduled_at` + `Asia/Ho_Chi_Minh` | **REUSABLE SOURCE — FINAL TODAY PROJECTION STILL NEEDED** |
| **Buổi chưa phân công / phân công thiếu** | `class_distributions.lead_teacher_id` NULL-able + `session_teachers` — dữ liệu suy ra được, chưa RPC nào trả | **NEEDS SERVER PROJECTION** |
| **GV đã phân công nhưng báo nghỉ** | **không nguồn nào trong hệ đã audit biểu thị được** | **CAPABILITY GAP / NEEDS OPERATIONAL INPUT** |
| Buổi quá giờ chưa bắt đầu | cần so `scheduled_at` với `now()` phía server **và** cần định nghĩa "quá giờ" | **NEEDS DOMAIN RULE + SERVER TIME EVALUATION** |
| Buổi chờ hoàn tất | `state` có sẵn trong week schedule, nhưng `in_progress` hiện lẫn cả fixture chết | **REUSABLE STATE, NEEDS STALE-STATE RULE** |
| Thiếu bằng chứng/media | `media_pct` chỉ là % tổng; cần theo từng buổi | **REUSABLE STATE, NEEDS SESSION-LEVEL PROJECTION** |
| Nhật ký/report chưa xong | `taught_report_pending` có trong week schedule, mức tuần | **REUSABLE STATE, NEEDS SESSION-LEVEL PROJECTION** |
| Hoạt động đã hoàn thành hôm nay | như trên | **REUSABLE STATE, NEEDS SESSION-LEVEL PROJECTION** |
| Khoảnh khắc gần đây | `get_school_moments` | **READY NOW** |
| Trạng thái cuối ngày | tổ hợp các khối trên | **NEEDS DOMAIN DEFINITION + SERVER PROJECTION** |
| ~~Điểm sức khoẻ~~ | — | **DO NOT BUILD** |
| ~~Tương tác phụ huynh %~~ | không có engine | **DO NOT BUILD** |
| ~~"GV nào cần giúp đỡ"~~ | không có định nghĩa nghiệp vụ | **DO NOT BUILD** |

### 3.1 Phân biệt bắt buộc — trạng thái buổi học KHÔNG được gộp

`in_progress` **không** đồng nghĩa với "có vấn đề". Mọi projection Hôm nay phải tách được 5 trường hợp:

| Trường hợp | Ý nghĩa | Có phải cảnh báo cho Hiệu trưởng? |
|---|---|---|
| Đang dạy hợp lệ | trong khung giờ dự kiến | **Không** |
| Quá hạn | đã qua giờ kết thúc dự kiến + biên độ chưa định nghĩa | Có |
| Bỏ ngỏ do quên đóng | quá hạn rất xa, không hoạt động kèm theo | Có, nhưng **khác loại** — là nhắc dọn, không phải sự cố dạy học |
| Huỷ / dời lịch | quyết định vận hành hợp lệ | **Không** |
| Fixture / demo bỏ dở | dữ liệu thử nghiệm | **Không bao giờ** được lên cảnh báo |

**Ràng buộc thiết kế:** bản ghi `in_progress` cũ **không được** tự động trở thành cảnh báo của Hiệu trưởng. Hai buổi KHM kẹt từ 03/07 và 14/07 là bằng chứng sống của lỗi này. Cần quy tắc stale-state trước khi bất kỳ exception list nào được phát hành.

### 3.2 Ba tình huống nhân sự — KHÔNG được gộp làm một

Bản audit trước đã mô tả `lead_teacher_id IS NULL` / thiếu `session_teachers` như bằng chứng "GV vắng". **Sai.** Hệ chỉ biết **phân công**, không biết **sự có mặt**.

| Tình huống | Hệ hiện có suy ra được không? | Phân loại |
|---|---|---|
| Buổi chưa phân công / phân công thiếu | ✅ suy ra được từ dữ liệu hiện tại | **NEEDS SERVER PROJECTION** |
| GV đã phân công nhưng báo nghỉ | ❌ **không có tín hiệu nào** | **CAPABILITY GAP / NEEDS OPERATIONAL INPUT** |
| Dạy thay | ❌ chưa có | tương lai: **phân công lại hoặc uỷ quyền tường minh, có thời hạn, ghi nhận đúng người thực hiện** |

**Giới hạn phạm vi:** không thiết kế hệ thống chấm công / HR đầy đủ bên trong V114. Chỉ cần tín hiệu khả dụng tối thiểu đủ để Hôm nay nói thật.

**Khuyến nghị KHÔNG đưa vào Hôm nay:** 6 thẻ KPI luỹ kế (thuộc "Quản lý"), Lịch tuần đầy đủ (link sang), Gợi ý/marketing.

### Phân tách hành động theo yêu cầu CTO
| Mức | Được phép ở Principal Hôm nay? |
|---|---|
| **Quan sát** | ✅ |
| **Điều tra** (mở buổi/lớp cụ thể) | ✅ — RLS cho phép đọc |
| **Phân công lại / uỷ quyền** | ✅ — `session_teachers` cho phép `is_school_admin` |
| **Làm thay GV** | ❌ **CẤM.** RLS chặn admin ở điểm danh, media, nhận xét trẻ, prep. Đặt CTA = vi phạm D290. Vắng GV → phân công lại hoặc uỷ quyền tạm có ghi nhận đúng người thực hiện |

---

## 4. AUDIT 6 — BẢO TỒN BỀ MẶT SCHOOL HIỆN CÓ

| Thành phần | Phân loại |
|---|---|
| 6 thẻ KPI luỹ kế | **PRESERVE UNCHANGED** (chuyển sang "Quản lý") |
| Lịch triển khai tuần | **PRESERVE, POLISH LATER** — cần ô click được |
| Tiến độ theo lớp | **PRESERVE, POLISH LATER** — **P1: sửa điều hướng ảo giác** |
| Khoảnh khắc nổi bật | **LINK FROM TODAY VIEW** |
| Card dữ liệu triển khai (sau V114-H) | **PRESERVE UNCHANGED** |
| Tab Lớp & Môn / Giáo viên / Trẻ & PH | **REHOME IN FULL VIEW** — thoát khỏi `?tab=`, cho IA thật |
| Hỗ trợ + Thông báo | **LINK FROM TODAY VIEW** |
| Gợi ý cho trường | **PRESERVE, POLISH LATER** |
| **Tương tác phụ huynh (placeholder khoá)** | **HIDE UNTIL REAL** |
| Badge trạng thái lớp `Cần hỗ trợ` | **REMOVE OR REPLACE BEFORE SCHOOL TODAY / NEXT EXTERNAL DEMO** — P1 decision-integrity đã xác nhận |

Không thành phần nào bị gỡ chỉ vì không thuộc Hôm nay.

**Ghi chú disposition badge lớp (đính chính CTO Part 2).** Nhãn cũ `REMOVE ONLY IF OWNER APPROVES` đặt sai vấn đề: nó coi đây là lựa chọn thẩm mỹ. Thực tế đây là **khiếm khuyết decision-integrity P1 đã xác nhận** — verdict một chiều dựa `journal_pct`, mẫu số n=3 với 2/3 là fixture chết. V114A vẫn là **audit-only nên KHÔNG vá bây giờ**, nhưng defect này đi thẳng vào **gói remediation trước khi build**, và phải được gỡ hoặc thay bằng phát biểu trung thực **trước khi** phát hành School Hôm nay hoặc trước lần demo đối ngoại kế tiếp — cái nào tới trước.

---

## 5. DEFECT BỔ SUNG TỪ AUDIT 2

| ID | Mức | Mô tả |
|---|---|---|
| V114A-P1-7 | **P1** | `ClassProgress`: mọi hàng lớp gọi chung `onView` → luôn về `?tab=classes`, không mở đúng lớp. Ảo giác điều hướng, mất ngữ cảnh toàn phần |
| **V114A-P1-8** | **P1** | **Không có tín hiệu khả dụng / vắng mặt nhân sự.** Hệ biết **phân công**, nhưng không xác định được người được phân công hôm nay **có mặt để dạy hay không**. Hệ quả: mọi bề mặt "Hôm nay" của Hiệu trưởng không thể phân biệt buổi chưa phân công với buổi có GV nhưng GV nghỉ |
| V114A-P2-4 | P2 | Ô lịch tuần không click được → thấy vấn đề nhưng không đi tới được |
| V114A-P2-5 | P2 | Ảnh khoảnh khắc không mở lớn, không dẫn tới buổi/lớp |
| V114A-P2-6 | P2 | Nhãn KPI "trên buổi đã dạy" không tiết lộ rằng "đã dạy" gồm cả `in_progress` |

---

## 6. CÒN LẠI CHO FILE 3/6 (Teacher)

Journey T1 và T6 đã đo xong từ `teacher.index.tsx`. **T2, T3, T4 và phần đuôi của T5 cần đọc `teacher.session.$id`, `teacher.classes`, `teacher.journal`, `teacher.classroom` — chưa đọc, KHÔNG suy đoán.**
Trường bổ sung của CTO (route/query có chạm dữ liệu ngoài phân công không, kể cả khi UI không hiện) sẽ áp cho từng journey Teacher khi đọc xong.

---

*Sinh trong V114A. Không canonicalize. Không code dual-view.*
