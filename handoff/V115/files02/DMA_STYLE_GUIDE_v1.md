# DMA — BỘ NGUYÊN TẮC THIẾT KẾ UI/UX (v1)

**Vì sao có file này:** UX Audit (vừa xong) cho thấy DMA đang có 2 chuẩn cùng tồn tại — Parent Journal (ấm, cảm xúc, đúng gu) và School Dashboard/Teacher session (kỹ thuật, dạng BI dashboard). Nguyên nhân: `/teacher` từng qua 1 vòng thiết kế bài bản (D98 "Classroom Companion"), nhưng `/school` thì chưa — nó chỉ được tách route (v25) chứ chưa được "thổi hồn". File này hệ thống hoá lại thành **1 bộ chuẩn dùng chung cho cả 5 cổng**, kế thừa toàn bộ token đã chốt (D97/D98), không đổi màu/logo/route.

**Không đổi (giữ nguyên từ quyết định trước):**
- Màu thương hiệu `#149A76` (xanh ngọc, sample từ logo Dế Mèn)
- Linh vật = con dế — bản mark nhỏ (hình học, gọn) cho chrome, bản dế-tròn cho empty/sent/illustration
- Gu tổng thể: **"album con / vui trẻ thơ"** — ấm, tinh tế, không "cold SaaS dashboard", không "cartoon quá trớn"
- Accent theo cổng: School = emerald/forest · Teacher = ivory `#FBF8F1` + forest `#149A76` + honey `#EFA63A` · Parent = amber · Admin = slate · Kid = reserved

**Bổ sung mới trong file này:** nguyên tắc phân cấp nội dung, giọng văn, hệ icon, quy tắc ẩn/hiện dữ liệu — áp dụng đồng đều cho cả 5 cổng, ưu tiên vá trước cho School.

---

## 1. NGUYÊN TẮC GỐC — "Người trước, hệ thống sau"

Mọi màn hình, trước khi thiết kế, phải trả lời được: **"Người này mở app lên để cảm thấy gì / biết điều gì, không phải để hệ thống báo cáo gì."**

| Persona | Câu hỏi cảm xúc cần trả lời trước tiên | KHÔNG mở đầu bằng |
|---|---|---|
| School (Hiệu trưởng) | "Trường mình có ổn không, có cần tôi làm gì không?" | Bảng KPI/% thống kê |
| Teacher (Giáo viên) | "Hôm nay tôi cần làm gì, tôi có tự tin dạy không?" | Thư viện học liệu / chỉ số hệ thống |
| Parent (Phụ huynh) | "Con tôi hôm nay thế nào?" | Danh sách "buổi học đã diễn ra" |

**Hệ quả trực tiếp:** con số/thống kê không biến mất, nhưng luôn đứng **sau** một câu chuyện/trạng thái cảm xúc, không đứng ở vị trí hero. Đây là gốc rễ để sửa đúng lỗi "School dashboard mở đầu bằng 6 KPI card" mà audit đã chỉ ra.

---

## 2. GIỌNG VĂN (COPYWRITING VOICE)

Một giọng, ba sắc thái — không phải ba giọng khác nhau:

- **Gốc chung:** chủ động, cụ thể, không thuật ngữ kỹ thuật, câu ngắn. Gọi tên thứ người dùng *điều khiển và nhận ra*, không gọi theo cách hệ thống xây dựng ("nhật ký" chứ không phải "bản ghi", "gửi" chứ không phải "submit").
- **School:** ấm nhưng có tư thế chuyên nghiệp — như một cộng sự vận hành, không phải một cái máy đo hiệu suất.
- **Teacher:** như một đồng nghiệp thân thiện đứng cạnh — đã đúng tinh thần ở D98 ("Cô nghỉ ngơi một chút nhé"), giữ nguyên chuẩn này và lan sang mọi micro-copy khác trong `/teacher`.
- **Parent:** cảm xúc, cá nhân hoá, gọi tên con — đã đúng chuẩn ở "Xem ký ức này", dùng làm mẫu gốc cho toàn bộ Parent portal.

**Quy tắc rỗng/lỗi (từ frontend-design skill, áp cho DMA):**
- Empty state là lời mời hành động, không phải thông báo trống rỗng. Mẫu tốt đã có: *"Hành trình của Phúc đang bắt đầu — con đã có hoạt động được ghi nhận, nhưng chưa có hình ảnh nào để xem lại."* — nhân bản văn phong này sang mọi empty state khác (kể cả `/school`, `/teacher`).
- Lỗi/cảnh báo nói rõ chuyện gì xảy ra + cách sửa, bằng giọng hệ thống, không giả vờ là người: không xin lỗi, không mơ hồ.

**Cấm dùng trong copy hướng người dùng cuối (School/Teacher/Parent):** thuật ngữ hạ tầng — "RPC", "buổi/session ID", "MB", "%N/N mẫu", "cache", tên bảng/route kỹ thuật. Những thứ này chỉ được xuất hiện ở `/admin`.

---

## 3. HỆ ICON & LINH VẬT

Vấn đề hiện tại: emoji rời rạc (🚌, 📸, 👶) chọn theo tiện chứ không theo hệ thống — mỗi cổng "tự bốc" icon khác nhau.

**Nguyên tắc:**
- **Một bộ icon line-art nhất quán** (không emoji hệ điều hành) cho toàn bộ trạng thái/hành động lặp lại: buổi học, điểm danh, ảnh, nhật ký, thông báo. Icon set nên **thuộc về brand**, không phải bộ icon mặc định của thư viện UI dùng nguyên bản.
- **Dế = điểm nhấn cảm xúc, không phải icon chức năng.** Dùng dế-tròn ở: empty state, trạng thái "đã gửi/hoàn thành", welcome/greeting. Không dùng dế để đại diện cho một loại dữ liệu (vd không dùng dế thay cho icon "buổi học").
- Mỗi loại nội dung trong feed (khoảnh khắc thật có ảnh, buổi học không nội dung, thông báo hệ thống) nên có **icon + màu nền khác cấp độ trực quan rõ rệt** — để phụ huynh phân biệt được cái nào đáng mở, thay vì tất cả nhìn giống nhau như hiện tại.

---

## 4. QUY TẮC ẨN/HIỆN DỮ LIỆU — "Ai cần thấy gì"

Đây là nguyên tắc trực tiếp vá lỗi Critical trong audit (số MB lộ ra màn Teacher).

| Loại dữ liệu | Ai được thấy |
|---|---|
| Chỉ số vận hành/hạ tầng (dung lượng, % mẫu nhỏ, trạng thái hệ thống/bảo trì) | Chỉ `/admin`. Không xuất hiện ở School/Teacher/Parent dưới bất kỳ hình thức nào. |
| Chỉ số tiến độ chương trình (buổi đã dạy, % nhật ký) | School — nhưng **luôn đi kèm ngữ cảnh** (mẫu nhỏ → nói rõ bằng câu, không chỉ số %) |
| Trạng thái buổi học, điểm danh | Teacher — ngôn ngữ hành động ("cần ghi nhận"), không phải ngôn ngữ log |
| Khoảnh khắc, hành trình, nhật ký con | Parent — trọng tâm là câu chuyện, số liệu (nếu có) đứng sau |

**Quy tắc mẫu nhỏ:** khi số liệu được tính trên mẫu quá nhỏ để có ý nghĩa (như "3 buổi" hiện tại), **không hiển thị số % to/đậm** làm điểm nhấn thị giác chính — hoặc chuyển hẳn sang câu chữ ("3/5 buổi đã dạy — còn sớm để đánh giá") thay vì số phần trăm kèm cảnh báo nhỏ bên dưới.

---

## 5. TỶ LỆ "CÂU CHUYỆN : SỐ LIỆU" THEO CỔNG

Đây là cách cụ thể hoá nguyên tắc §1 thành tỷ lệ bố cục có thể áp trực tiếp khi thiết kế:

- **Parent:** ~80% câu chuyện/cảm xúc — 20% số liệu. (Đã đúng ở Parent Journal, cần lan sang Parent Home.)
- **Teacher:** ~60% hành động/trạng thái cần làm — 40% thông tin hỗ trợ (giáo án, học liệu).
- **School:** ~50% câu chuyện thành công (khoảnh khắc, tiến độ theo lớp kể bằng câu) — 50% số liệu vận hành, nhưng số liệu phải **luôn có một dòng diễn giải bằng lời** đi kèm, không đứng trơ trọi.

**Hệ quả cụ thể cho School dashboard** (đang lệch hẳn về phía số liệu — gần 90% là số/bảng/%): đây là màn cần ưu tiên làm lại đầu tiên để về đúng tỷ lệ 50/50.

---

## 6. CHECKLIST TRƯỚC KHI SHIP MỘT MÀN HÌNH MỚI

Dùng checklist này mỗi khi build/sửa 1 màn hình — mục tiêu là chặn đúng loại lỗi mà UX Audit đã tìm thấy, không để lặp lại:

- [ ] Câu đầu tiên người dùng đọc là cảm xúc/trạng thái, không phải một con số?
- [ ] Có chỉ số kỹ thuật/hạ tầng nào lọt ra khỏi `/admin` không? (MB, %mẫu-nhỏ, trạng thái hệ thống...)
- [ ] Mọi icon dùng trong màn có nằm trong bộ icon chuẩn, không phải emoji tự chọn?
- [ ] Empty state có phải là một lời mời hành động (có giọng văn ấm), không phải dòng "không có dữ liệu"?
- [ ] Mọi nút bấm có dẫn đúng tới nơi wording của nó hứa hẹn không? (đối chiếu lỗi "Quản lý lớp" dẫn sai chỗ, nút chết trong audit)
- [ ] Nếu màn có số liệu trên mẫu nhỏ — có diễn giải bằng câu, không chỉ trưng số %?

---

## 7. BƯỚC KẾ TIẾP (đề xuất)

★ Áp checklist này thí điểm vào **1 màn: School Dashboard** — vì đây là màn lệch xa nhất so với chuẩn đã có ở Parent/Teacher, và là màn hiệu trưởng mở đầu tiên mỗi ngày. Sau khi có 1 bản mẫu "đạt chuẩn", dùng nó làm tham chiếu để rà lại các màn còn lại (Teacher session, Parent Home).
