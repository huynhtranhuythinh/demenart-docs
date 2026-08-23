# DMA — PRODUCT UX AUDIT · REAL SCHOOL DAY WALKTHROUGH

**Phương pháp:** Đăng nhập trực tiếp vào demenart.com bằng 3 tài khoản demo thật (School / Teacher / Parent), đi theo journey như người dùng thật — không đọc code, không đọc migration, không đánh giá bảo mật/kiến trúc.

**Tài khoản đã dùng:**
- School: `hieutruong.kidshouse@demo.demenart.com` — Hiệu trưởng Huỳnh Trần Nguyệt Thi, Kids House Montessori Đà Nẵng
- Teacher: `gv.linh.kidshouse@demo.demenart.com` — GV Đặng Mỹ Linh, phụ trách lớp Hoa Hồng
- Parent: `ph.thanh.demen@demo.demenart.com` — phụ huynh của 2 bé: Hà và Phúc

**Ngày audit thực tế trên hệ thống:** Thứ Bảy 25/07/2026 (ảnh hưởng tới dữ liệu "hôm nay" quan sát được — xem ghi chú trong từng phần).

---

## PART 1 — CURRENT JOURNEY MAPS

### 1.1 Journey — SCHOOL (Hiệu trưởng)

| Bước | User Goal | Information Seen | Decision | Action | System Response | Emotion |
|---|---|---|---|---|---|---|
| Start | "Hôm nay trường mình có ổn không?" | Landing demenart.com → chọn "Nhà trường" | Vào School Portal | Click | Vào thẳng `/school/manage` — dashboard tổng quan | Trung tính, tò mò |
| 1 | Trường có đang chạy tốt không? | 6 KPI card (Lớp học, Học sinh, Giáo viên, Buổi đã dạy, % Nhật ký, % Media) + banner "Chưa đủ dữ liệu để đánh giá" | Đọc số liệu | Lướt mắt | Không có hành động, chỉ đọc | Hơi rối vì vừa có số % vừa có cảnh báo "chưa đủ dữ liệu" cùng lúc |
| 2 | Lớp nào đang ổn, lớp nào cần để ý? | "Tiến độ theo lớp" — 4 dòng lớp×môn, phần lớn "0/0 buổi — chưa có buổi nào" | Muốn xem chi tiết 1 lớp | Click "Quản lý lớp" | Nhảy sang màn **Lớp & Môn** (form "Thêm lớp mới" + danh sách 2 lớp) — không phải màn tiến độ chi tiết | Bất ngờ — kỳ vọng xem tiến độ, nhận được màn quản trị |
| 3 | Tuần này lớp nào dạy ngày nào, có buổi nào cần chú ý? | Bảng lịch tuần T2–CN với 5 trạng thái màu (Hoàn thành / Đang dạy / Sắp diễn ra / Thiếu nhật ký / Đổi lịch) | Muốn mở rộng xem cả tháng/lịch đầy đủ | Click "Mở lịch triển khai" | **Không có gì xảy ra** — ở lại đúng trang cũ | Hụt hẫng, nghĩ là bấm nhầm hoặc bị lỗi |
| 4 | Có khoảnh khắc đẹp nào ở lớp không? | "Khoảnh khắc nổi bật" — 4 thẻ, phần lớn caption generic ("Khoảnh khắc", "Bé làm workshop") | Xem lướt | Lướt | Ảnh gắn nhãn "Nội bộ trường" | Dễ chịu nhưng caption hơi nghèo nội dung |
| 5 | Phụ huynh có đang tương tác không? | "Tương tác phụ huynh" — toàn dấu "—", nhãn "Sắp ra mắt V1.5" | Nhận ra tính năng chưa bật | Không làm gì | — | Hơi thất vọng — đây đúng là câu hỏi hiệu trưởng quan tâm nhất nhưng chưa có |
| End | Có cần làm gì hôm nay không? | Khối "Hỗ trợ & vận hành": 1 tin hướng dẫn kỹ thuật, thông báo trống, 2 CTA chung chung | Không có việc cụ thể cần làm | Đóng tab | — | Không rõ "hôm nay mình cần làm gì tiếp theo" |

**User Outcome:** Hiệu trưởng biết được vài con số tổng quan nhưng **không kết thúc journey với một hành động rõ ràng**. Không có "day-close" hay "cần làm gì tiếp" nào được đề xuất chủ động.

---

### 1.2 Journey — TEACHER (Giáo viên)

| Bước | User Goal | Information Seen | Decision | Action | System Response | Emotion |
|---|---|---|---|---|---|---|
| Start | "Hôm nay tôi cần làm gì?" | Đăng nhập xong | — | — | **Rơi thẳng vào `/teacher/curriculum`** (thư viện học liệu: ảnh/video/audio demo) — không phải trang "hôm nay" | Lạc hướng ngay từ giây đầu tiên |
| 1 | Vậy hôm nay tôi dạy gì? | Phải tự tìm nav "Hôm nay" | Click "Hôm nay" | Click | Vào `/teacher` — "Chào cô Linh · Thứ Bảy 25/7 · 0 tiết hôm nay" | Ổn định lại, nhưng đã mất 1 bước không cần thiết |
| 2 | Không có lớp thì làm gì? | Empty state ấm áp: "Cô nghỉ ngơi một chút nhé" + banner hệ thống về màn chiếu tạm ngưng (không liên quan ngày nghỉ) | Xem 2 CTA phụ: "Xem giáo án", "Nhật ký bé" | Click "Nhật ký bé" | Vào `/teacher/journal` | Banner bảo trì xuất hiện cả ngày không có lớp — hơi thừa |
| 3 | Buổi nào tôi còn thiếu nhật ký? | "CẦN GHI NHẬN" (1 buổi) + "ĐÃ GỬI & LỊCH SỬ" — nhưng lẫn trong đó là dữ liệu test: **"QA S0A — DO NOT USE"**, "QA buoi 2 cung ngay" | Nhận ra có buổi cần ghi | Click "Ghi nhận ngay" | Vào wizard buổi học 4 bước | Mất niềm tin nhẹ khi thấy nhãn "DO NOT USE" trong dữ liệu thật |
| 4 (Chuẩn bị→Dạy học) | Tôi cần chuẩn bị gì trước khi dạy? | "Học liệu buổi học" trống, "Hướng dẫn giảng dạy" ghi thẳng "Đội ngũ Dế Mèn đang biên soạn kịch bản..." | Không có kịch bản, phải tự dạy | Kéo xuống thấy "32.39/5000 MB" (dung lượng lưu trữ) | Hệ thống lộ chỉ số kỹ thuật (MB) cho giáo viên — không liên quan việc dạy | Không tự tin — thấy hệ thống thừa nhận nội dung chưa xong |
| 5 (Điểm danh/Ghi nhận) | Ai có mặt hôm nay? | Danh sách 4 bé, 3 trạng thái mỗi bé (Có mặt/Muộn/Vắng), "Có mặt 0/4" | Có thể bỏ qua không điểm danh | Click "Tiếp tục — Nhật ký" mà **không điểm danh ai** | Hệ thống cho qua, chỉ cảnh báo nhẹ ở bước sau | Ngạc nhiên — tưởng bắt buộc nhưng không |
| 6 (Nhật ký) | Gửi gì cho phụ huynh? | "Tóm tắt buổi học" (0 có mặt), cảnh báo "Còn 4 bé chưa điểm danh", "Ảnh gửi tới ba mẹ: Chưa có ảnh", ghi chú nội bộ | Có thể bấm gửi mà không có ảnh, không điểm danh | (dừng audit ở đây, không bấm gửi thật) | CTA cuối: "Hoàn tất & gửi nhật ký" luôn sáng, không bị khoá | Rủi ro: giáo viên có thể gửi một nhật ký rỗng cho phụ huynh mà hệ thống không ngăn |

**User Outcome:** Giáo viên hoàn thành được luồng 4 bước, nhưng **khởi đầu sai trang**, **gặp dữ liệu test lẫn trong dữ liệu thật**, và **không có rào chắn nào ngăn gửi nhật ký rỗng** — đúng lúc đây là sản phẩm cốt lõi mà phụ huynh trả tiền để nhận.

---

### 1.3 Journey — PARENT (Phụ huynh)

| Bước | User Goal | Information Seen | Decision | Action | System Response | Emotion |
|---|---|---|---|---|---|---|
| Start | "Hôm nay con tôi có gì đáng chú ý?" | Đăng nhập → `/parent` — "Hôm nay của Hà" | — | — | Landing đúng ý định, ấm áp, đúng tên con | Được chào đón, đúng cảm xúc |
| 1 | Có khoảnh khắc gì mới của con không? | 1 thẻ "Khoảnh khắc ở lớp" — mô tả tự nhiên: "Hà say sưa lắc trống lục lạc theo điệu nhạc vui" | Muốn xem kỹ hơn | Click "Xem ký ức này" | Vào `/parent/journal?focus=...` — trang chi tiết đẹp: khoá riêng tư 🔒, gợi ý trò chuyện, "kệ kỷ vật" mini-timeline | Gần gũi, cảm động — đây là điểm mạnh nhất của sản phẩm |
| 2 | Con đã học được gì theo thời gian? | "Hành trình — Đã lưu 3 điều" | Xem lướt "Gần đây": 1 khoảnh khắc thật (📸) + 2 mục 🚌 "Buổi học — Cảm Thụ Âm Nhạc Dế Mèn" không có nội dung gì thêm | Không click sâu | — | 2/3 mục trong "Gần đây" không mang lại thông tin gì — chỉ là "có buổi học diễn ra" |
| 3 | Ông bà có xem được không? | Vào "Gia đình" | Thấy form trống "Tạo không gian gia đình" (Tên không gian, Bạn là) | Chưa tạo | — | Tính năng có nhưng chưa kích hoạt — không rõ vì sao nên tạo, lợi ích gì |
| 4 | Có thông báo gì mới không? | "Thông báo" — trống hoàn toàn | — | — | "Chưa có thông báo nào" | Bình thường, không xấu |
| 5 | Con có thể tự dùng app không? | "Thế giới của con" → `/parent/kid` | Toggle tắt, cần đặt PIN, khung giờ, ghép thiết bị — chưa có gì được cấu hình | Không làm gì (audit, không cấu hình) | — | Rõ ràng đây là tính năng phụ huynh phải tự set up, không tự động |
| 6 | Còn bé thứ hai (Phúc) thì sao? | Chuyển tab "Phúc" | "Hành trình của Phúc đang bắt đầu — con đã có hoạt động được ghi nhận nhưng chưa có hình ảnh nào" | Đọc | — | Copy empty-state rất tốt, nhưng "Gần đây" của Phúc chỉ có 2 mục 🚌 generic, không có gì để cảm nhận | Nhạt — không có lý do quay lại app ngày mai cho bé Phúc |

**User Outcome:** Với bé có khoảnh khắc (Hà), trải nghiệm **rất tốt và cảm động**. Với bé chưa có khoảnh khắc nào (Phúc), app gần như trống rỗng về mặt cảm xúc — chỉ còn lại nhãn "buổi học đã diễn ra" không có sức nặng.

---

## PART 2 — TOP UX FRICTIONS

### 🔴 Critical

1. **Nhật ký có thể gửi rỗng cho phụ huynh.** Ở bước cuối luồng dạy (Nhật ký), giáo viên có thể bấm "Hoàn tất & gửi nhật ký" dù chưa điểm danh ai và chưa có ảnh nào. Đây là sản phẩm lõi (nhật ký = giá trị mà phụ huynh trả tiền để nhận) nhưng không có rào chắn chất lượng tối thiểu trước khi gửi.
2. **Dữ liệu test lẫn vào màn hình thật của giáo viên.** "QA S0A — DO NOT USE" và các mục "QA..." xuất hiện thẳng trong "Nhật ký lớp học" — màn hình mà một hiệu trưởng/giáo viên thật của trường pilot sẽ nhìn thấy đầu tiên. Rủi ro mất niềm tin ngay lần dùng đầu.
3. **Giáo viên đăng nhập vào sai trang.** Sau khi login, hệ thống đưa thẳng vào `/teacher/curriculum` (thư viện học liệu) thay vì "Hôm nay" — trong khi "Hôm nay tôi cần làm gì" là câu hỏi đầu tiên và duy nhất của một giáo viên vào buổi sáng.

### 🟠 High

4. **CTA dẫn tới màn sai bối cảnh.** "Quản lý lớp" nằm dưới phần "Tiến độ theo lớp" (kỳ vọng: xem chi tiết tiến độ) nhưng thực tế dẫn tới màn hình quản trị "Lớp & Môn" để tạo lớp mới — sai kỳ vọng hoàn toàn.
5. **Nút chết (dead-end CTA).** "Mở lịch triển khai" (School) và "Lớp của tôi" (Teacher) — bấm vào không có gì xảy ra. Với hiệu trưởng, đây đúng lúc họ đang tìm hiểu sâu hơn về lịch — bị chặn ngay tại điểm tò mò nhất.
6. **Thông tin kỹ thuật lộ ra màn hình không phải của mình.** "32.39/5000 MB" dung lượng lưu trữ hiện giữa màn dạy học của giáo viên — không ai đứng lớp cần biết con số này.
7. **Chỉ số "% Nhật ký đã gửi", "% Buổi có media" tính trên mẫu quá nhỏ (3 buổi) nhưng hiển thị như số liệu chính thức.** Có banner cảnh báo đi kèm ("chưa đủ dữ liệu"), nhưng số % to, đậm vẫn là thứ mắt nhìn thấy đầu tiên — cảnh báo nhỏ hơn nhiều so với con số nó đang cảnh báo.

### 🟡 Medium

8. **Banner bảo trì xuất hiện không đúng ngữ cảnh.** Thông báo "Màn chiếu và điều khiển từ xa đang tạm ngưng để nâng cấp bảo mật" xuất hiện cả trên trang "Hôm nay cô không có lớp" (ngày nghỉ) — banner này không liên quan gì tới ngày không có buổi dạy.
9. **Caption "Khoảnh khắc nổi bật" phía School quá chung chung** ("Khoảnh khắc", "Bé làm workshop") — không đủ sức thuyết phục một hiệu trưởng rằng chương trình đang "tạo giá trị thật" như tiêu đề dashboard tuyên bố.
10. **"Gần đây" phía Parent trộn lẫn 2 loại nội dung khác chất lượng** — khoảnh khắc thật (ảnh + caption cảm xúc) và "Buổi học đã diễn ra" (không có nội dung gì) — hiển thị cùng cấp độ trực quan khiến phụ huynh khó phân biệt cái nào đáng mở.
11. **Tính năng "Gia đình" (FMN) không có lời mời rõ ràng vì sao nên dùng** — chỉ là một form trống, thiếu 1–2 câu giá trị ("ông bà ở xa vẫn xem được khoảnh khắc của cháu") ngay trên đầu trang.

### 🟢 Low

12. Icon 🚌 dùng cho "Buổi học" trong feed phụ huynh hơi khó hiểu về mặt liên tưởng (xe bus ↔ buổi học nghệ thuật) — không nguy hiểm nhưng không trực quan.
13. "Tương tác phụ huynh — Sắp ra mắt V1.5" hiển thị nguyên một khối 3 chỉ số toàn dấu "—" — chiếm chỗ dashboard cho một tính năng chưa có, có thể thu gọn lại.

---

## PART 3 — JOURNEY BREAKS

```
School  ──────────────►  Teacher  ──────────────►  Journal  ──────────────►  Parent  ──────────────►  END
 (dashboard)              (dạy & ghi nhận)          (nhật ký buổi học)        (xem hành trình)
```

**Đứt ở đâu:**

- **School → Teacher:** Không đứt về mặt kỹ thuật, nhưng đứt về mặt **kỳ vọng nội dung** — School dashboard hứa hẹn "chương trình đang tạo giá trị thật" nhưng không có đường dẫn nào từ dashboard hiệu trưởng đi thẳng tới xem một buổi dạy cụ thể của giáo viên đang "Đang dạy" trên lịch tuần (trạng thái "Đang dạy" hiển thị nhưng không click được).

- **Teacher → Journal:** Đây là điểm đứt nghiêm trọng nhất trong toàn bộ chuỗi. Hệ thống **không bắt buộc** điểm danh hoặc ảnh trước khi "Hoàn tất & gửi nhật ký". Nghĩa là chuỗi giá trị "dạy → ghi nhận → nhật ký → phụ huynh xem" có thể đứt ngay tại nguồn: một nhật ký rỗng vẫn đi tiếp xuống Parent.

- **Journal → Parent:** Khi nhật ký có nội dung thật (như trường hợp bé Hà), trải nghiệm bên Parent rất tốt — không đứt, thậm chí là điểm sáng nhất toàn hệ thống. Nhưng khi nhật ký chỉ là "buổi học đã diễn ra" không ảnh (trường hợp bé Phúc), phía Parent **nhận được vỏ mà không có ruột** — về mặt cảm xúc, coi như đứt, vì phụ huynh mở app lên và không thấy gì đáng nhớ.

- **Parent → END:** Không có lời mời quay lại rõ ràng. Sau khi xem xong 1 khoảnh khắc, không có gợi ý nào kiểu "ngày mai quay lại xem tiếp" hay lịch nhắc. "Nhìn lại" (insight tổng hợp theo thời gian) vẫn ở trạng thái "đang dần cho thấy" — chưa có nội dung thật để đóng vòng lặp thành thói quen hàng ngày.

---

## PART 4 — QUICK WINS (không cần backend/kiến trúc)

1. **Đổi trang landing sau login của Teacher** từ `/teacher/curriculum` → `/teacher` (Hôm nay). Đây là thay đổi routing/default view thuần UI.
2. **Xoá/đổi tên dữ liệu QA** ("QA S0A — DO NOT USE", "QA buoi 2 cung ngay") trong danh sách nhật ký của tài khoản demo trước khi cho trường pilot thấy — việc dọn dữ liệu demo, không phải sửa code.
3. **Ẩn con số MB dung lượng** khỏi màn hình giáo viên (hoặc chuyển vào màn Admin/School nếu cần theo dõi) — thay đổi hiển thị, không đổi logic lưu trữ.
4. **Sửa hoặc ẩn 2 nút chết**: "Mở lịch triển khai" và "Lớp của tôi" — nếu chưa build màn đích, tạm ẩn nút thay vì để bấm vô tác dụng.
5. **Đổi đích của "Quản lý lớp"** dưới block "Tiến độ theo lớp" — hoặc đổi tên nút thành "Quản lý lớp & môn" để đúng kỳ vọng, hoặc trỏ nó tới đúng màn tiến độ chi tiết.
6. **Làm nhỏ/thu gọn khối "Tương tác phụ huynh — Sắp ra mắt"** để đỡ chiếm không gian dashboard cho một tính năng chưa hoạt động.
7. **Ẩn banner bảo trì màn chiếu khi giáo viên không có buổi dạy hôm nay** — banner chỉ nên xuất hiện trong context có buổi học thật.
8. **Thêm 1 dòng cảnh báo rõ hơn ở nút "Hoàn tất & gửi nhật ký"** khi chưa điểm danh/chưa có ảnh — không cần chặn cứng, chỉ cần một dòng đỏ "Nhật ký này chưa có ảnh — phụ huynh sẽ không thấy gì" ngay cạnh nút, để giáo viên tự cân nhắc.
9. **Thêm 1 câu giá trị ở đầu trang "Gia đình" (Family)** giải thích lợi ích cụ thể trước khi hiện form trống, ví dụ nói rõ ông/bà xem được khoảnh khắc dù ở xa.

---

## PART 5 — BIG PRODUCT OPPORTUNITIES

1. **"Nhật ký tối thiểu" (Journal Quality Gate).** Định nghĩa một tiêu chuẩn tối thiểu để một buổi học được coi là "đã ghi nhận đầy đủ" (vd: đã điểm danh + có ít nhất 1 ảnh/note) và phản ánh rõ trạng thái này ngược lên dashboard School — biến "% Nhật ký đã gửi" từ một con số đơn thuần thành một tín hiệu chất lượng thật.

2. **Đường link trực tiếp từ School dashboard xuống buổi học cụ thể.** Hiệu trưởng nhìn thấy lịch tuần với trạng thái "Thiếu nhật ký" nhưng không click được để xem/nhắc giáo viên. Đây là khoảng trống lớn nhất giữa vai trò quản lý và vai trò vận hành hàng ngày.

3. **Tương tác phụ huynh thật (không chỉ V1.5 placeholder).** Đây chính là câu hỏi số 1 mà mọi hiệu trưởng mầm non sẽ hỏi ngay khi dùng thử: "Phụ huynh có thực sự xem không?" — hiện dashboard trưng ra một khối số liệu trống, đúng lúc đây lại là bằng chứng thuyết phục nhất để trường quyết định mua/gia hạn.

4. **Cơ chế "nhắc nhở khép vòng" cho Parent.** Một khoảnh khắc thật đã tạo được cảm xúc rất tốt (trường hợp bé Hà) — nhưng chưa có gì kéo phụ huynh quay lại vào ngày hôm sau. Một dạng "hôm nay tới lượt xem tiếp" nhẹ nhàng (không phải notification dồn dập) có thể biến sản phẩm từ "xem 1 lần" thành thói quen hằng ngày.

5. **Định vị rõ giá trị "Gia đình" (FMN) như một tính năng bán hàng, không chỉ là setting.** Đây là một trong những tính năng được đầu tư nhiều nhất về mặt kỹ thuật (theo lịch sử build gần đây) nhưng trải nghiệm hiện tại của nó chỉ là một form cấu hình trống — chưa kể được câu chuyện "vì sao gia đình nên dùng".

---

## PART 6 — SCREENS NEEDING REDESIGN

| Màn hình | User question | Vì sao chưa tốt | Mục tiêu mới |
|---|---|---|---|
| Teacher — trang mặc định sau login (`/teacher/curriculum`) | "Hôm nay tôi cần làm gì?" | Trả lời sai câu hỏi — đưa thẳng vào thư viện học liệu | Sau login phải trả lời ngay: có lớp hôm nay không, cần làm gì trước |
| School — "Tiến độ theo lớp" + nút "Quản lý lớp" | "Lớp nào đang ổn, lớp nào cần chú ý?" | Nút dẫn sai chỗ — vào màn quản trị thay vì màn chi tiết tiến độ | Click vào 1 lớp phải mở ra chi tiết: buổi nào thiếu nhật ký, ai chưa gửi |
| School — Lịch triển khai tuần + "Mở lịch triển khai" | "Tuần này có gì cần can thiệp?" | Nút chết, và bản thân bảng lịch không click được vào từng buổi | Click 1 ô lịch → thấy chi tiết buổi đó, trạng thái, ai dạy |
| Teacher — bước "Dạy học" trong session | "Tôi cần chuẩn bị/dẫn dắt gì?" | Lộ chỉ số kỹ thuật (MB), thừa nhận nội dung chưa xong ngay trên UI | Ẩn thông tin kỹ thuật; nếu học liệu chưa có, đưa gợi ý thay thế cụ thể thay vì để trống |
| Teacher — bước "Nhật ký" cuối buổi | "Tôi đã sẵn sàng gửi cho phụ huynh chưa?" | Không có tín hiệu cảnh báo đủ mạnh khi nhật ký rỗng | Cảnh báo rõ ràng, có thể yêu cầu xác nhận thêm khi gửi nhật ký thiếu ảnh/điểm danh |
| Parent — "Gần đây" (feed) | "Hôm nay/gần đây con có gì đáng chú ý?" | Trộn lẫn nội dung có ý nghĩa (khoảnh khắc) và nội dung rỗng (buổi học không ảnh) cùng cấp | Phân tách rõ 2 loại, hoặc ẩn bớt các mục "buổi học" không có nội dung gì thêm |
| Parent — "Gia đình" (Family) | "Vì sao/làm sao để ông bà cùng xem?" | Form trống không có câu chuyện giá trị | Thêm phần giới thiệu giá trị + ví dụ trước form nhập liệu |

*(Không mockup theo yêu cầu — chỉ liệt kê mục tiêu.)*

---

## PART 7 — FINAL VERDICT

**Nếu đem DMA cho một trường mầm non nhỏ dùng thử hôm nay:**

**Điều họ sẽ thích:**
- Trang phụ huynh khi có nội dung thật (trường hợp bé Hà) — ấm áp, cá nhân hoá, đúng cảm xúc "gần con hơn" mà sản phẩm hướng tới. Đây là điểm bán hàng mạnh nhất hiện có.
- Giao diện tiếng Việt, tông giọng thân thiện, empty-state được viết tử tế (không phải "No data" khô khan).
- Luồng dạy học 4 bước (Chuẩn bị → Dạy học → Ghi nhận → Nhật ký) có cấu trúc rõ ràng, giáo viên không bị lạc giữa chừng.

**Điều họ sẽ đánh giá cao:**
- Dashboard hiệu trưởng có đủ số liệu cơ bản để cảm thấy "có kiểm soát" trong tuần đầu dùng thử.
- Cảnh báo trung thực "chưa đủ dữ liệu để đánh giá" — cho thấy sản phẩm không cố tô hồng số liệu.

**Điều họ sẽ không hiểu:**
- Vì sao "Tương tác phụ huynh" — đúng câu hỏi họ quan tâm nhất — lại toàn dấu "—".
- Vì sao bấm "Mở lịch triển khai" hoặc "Lớp của tôi" không có chuyện gì xảy ra.
- Vì sao trong nhật ký lại có dòng "QA S0A — DO NOT USE" — họ sẽ nghĩ đây là lỗi hệ thống, không phải dữ liệu thử nghiệm.

**Điều họ sẽ hỏi ngay:**
- "Phụ huynh có thực sự đọc/xem nhật ký không? Sao không thấy số liệu đó?"
- "Tại sao vào xong là thấy Học liệu chứ không phải lịch dạy hôm nay?" (câu hỏi này sẽ tới từ giáo viên, không phải hiệu trưởng)

**Điều khiến họ bối rối:**
- Sự lệch pha giữa cái dashboard *nói* ("chương trình đang tạo giá trị thật") và cái dashboard *cho thấy* (nhiều mục 0/0, nhiều dấu "—", 1 nút chết).

**Điều có thể khiến họ bỏ cuộc:**
- Nếu buổi dùng thử đầu tiên rơi vào đúng lúc một giáo viên gửi một nhật ký gần như rỗng (không ảnh, không điểm danh) — phụ huynh mở app lên, không thấy gì, và không quay lại lần hai. Đây là rủi ro lớn nhất về mặt sản phẩm: **toàn bộ giá trị của DMA phụ thuộc vào chất lượng đầu vào của giáo viên, nhưng hệ thống hiện không có gì đảm bảo chất lượng đầu vào đó.**

---

*Audit thực hiện bằng browser thật trên demenart.com, không sửa dữ liệu, không submit form thật (dừng lại trước bước "Hoàn tất & gửi nhật ký" để không tạo dữ liệu giả trong hệ thống demo).*
