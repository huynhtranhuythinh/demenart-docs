# 🚀 DMA_00_START_HERE.md — ĐỌC FILE NÀY TRƯỚC TIÊN

> **Dành cho:** Claude làm việc trong Project **DMA – Dế Mèn Art**. Sản phẩm đầu tiên: **CTAN – Cảm Thụ Âm Nhạc Dế Mèn** (không dùng "DMMA").
> **Mục đích:** Tờ hướng dẫn dán ở cửa. Mỗi phiên đọc file này ĐẦU TIÊN → biết đọc gì tiếp, làm theo quy trình nào, và **kỷ luật tự-cập-nhật** bắt buộc.

---

## 0. ⭐ LINH HỒN của DMA (đọc kỹ — đây là điều dễ hiểu sai nhất)

**DMA trước hết là cuốn NHẬT KÝ NGHỆ THUẬT suốt tuổi thơ của một đứa trẻ — thuộc về Trẻ và Ba Mẹ.** Nó ghi lại hành trình lớn lên qua nghệ thuật: bé học Piano ở Dế Mèn, học Múa ở Cung Thiếu Nhi, vẽ ở nhà ba mẹ tự ghi — **tất cả đổ về MỘT cuốn nhật ký duy nhất của bé**, không thuộc về bất kỳ trường nào.

**Mô hình kiếm tiền (bán license B2B cho trường) chỉ là MỘT LỚP gắn vào, KHÔNG phải trái tim.** Trường (kể cả Dế Mèn) chỉ là *một nguồn đóng góp* vào nhật ký của trẻ. Trường hết hạn license / trẻ chuyển đi → **nhật ký của trẻ vẫn nguyên vẹn**, vì nó là tài sản của trẻ, không phải của trường.

> Nếu thiết kế DMA như "phần mềm quản lý trường có cho phụ huynh xem" → **SAI linh hồn**. Đúng là: "album nghệ thuật suốt đời của trẻ, mà trường là một nơi đóng góp vào".

**Hệ quả thiết kế cốt lõi (2 thép chờ — xem §4):** hành trình treo vào ĐỨA TRẺ (không treo vào trường); môn nghệ thuật là danh mục TOÀN CỤC (Piano ở đâu cũng là "Piano").

**Triết lý không được vi phạm:** ấm – nghệ thuật – cao cấp (như album gia đình, KHÔNG phải SaaS dashboard lạnh); **KHÔNG chấm điểm / xếp hạng / so sánh trẻ**; badge = "dấu mốc kỷ niệm", sao = ghi nhận RIÊNG từng trẻ (không bảng xếp hạng); privacy/consent rất chặt vì xử lý dữ liệu trẻ vị thành niên.

---

## 1. V1 (tài liệu) vs TOÀN DỰ ÁN (tầm nhìn) — KHÔNG mâu thuẫn

| | Phạm vi | Nguồn |
|---|---|---|
| **V1 / pilot** | 4 portal: Admin · School · Teacher · Parent. Trẻ CHƯA đăng nhập. Nhật ký nguồn từ Dế Mèn/trường. | Tài liệu A–G |
| **Toàn dự án** | Thêm **cổng Kid** (trẻ vào bằng PIN), nhật ký **xuyên-tổ-chức** (gồm nơi ngoài Dế Mèn + PH tự thêm). | Tầm nhìn founder |

**Nguyên tắc:** **build V1 theo tài liệu, nhưng schema CHỪA THÉP CHỜ cho toàn dự án** (§4) — để lên "tầng 2" (Kid + xuyên-tổ-chức) KHÔNG phải đập móng.

---

## 2. Năm cổng (4 V1 + Kid V2) + cách chúng quan hệ

> **⭐ DMA có 5 cổng (chốt v24):** `/admin` · `/school` · `/teacher` · `/parent` · `/kid`. Bốn cổng đầu là V1; `/kid` là **V2 reserved** (trẻ vào bằng PIN, ba mẹ duyệt). Mọi thiết kế tách portal phải **chừa sẵn namespace `/kid`** (khỏi đập route sau — tinh thần thép chờ). Cổng PH `/parent` đã tách ở v24 (D95); 3 cổng còn lại (`/teacher`·`/school`·`/admin`) tách dần theo khuôn `parent.tsx`.

| Cổng | Namespace | Nhiệm vụ |
|---|---|---|
| **Dế Mèn (Admin)** | `/admin` (sau) | Quản trị nền tảng + kho giáo trình + license + xem data ẩn danh/tổng hợp |
| **Trường (School)** | `/school` (sau) | Chủ trường: quản lý tổng thể các Lớp + Giáo viên toàn trường |
| **Giáo viên (Teacher)** | `/teacher` (sau) | Quản lý Tiết dạy / giáo án / nhận xét / khoảnh khắc — của Lớp mình phụ trách |
| **Phụ Huynh (Parent)** | `/parent` ✅ v24 | Giữ nhật ký cho con: xem, comment (nếu trường bật), quản consent, (tương lai) duyệt PIN/giờ cho Kid |
| **Kid (V2)** | `/kid` (reserved) | Trẻ có tài khoản riêng vào bằng **PIN** (ba mẹ duyệt PIN + khung giờ); khử so sánh/xếp hạng |

**Quan hệ School ↔ Teacher (quan trọng — ánh xạ từ `/b2b` DMWS):**
School và Teacher là **2 portal THÔNG NHAU** (1 nhóm đối tượng "Nhà Trường & GV", 2 cổng phụ). GV vào được Portal Trường để nắm thông tin. **Mô hình quyền = scoped như DMWS B2B:** mọi thành viên trường **THẤY** mọi buổi học nghệ thuật của các GV khác trong trường, nhưng chỉ **TRUY CẬP/THAO TÁC** được **môn-lớp mình là lead / tiết mình là assistant**. (DMA "Lớp" ↔ DMWS "Đợt"/`org_session`.)

> **⭐ Lớp = HOMEROOM đa môn (Cách Y — đã chốt):** một "Lớp" là nhóm trẻ cố định, học **nhiều môn**; mỗi môn rót vào lớp qua `class_distributions` và có **GV chính riêng**. Trẻ ghi danh vào homeroom (`enrollments`), tách khỏi hồ sơ trẻ. **License (đã chốt):** `Tổng = (số môn × giá) + (số tk GV × giá) + storage` — môn & seat **tách bạch**; seat subject-agnostic; Master bundled không seat. Chi tiết: RULES D49–D51, móng C v2.

**Cổng Kid (toàn dự án, chưa làm V1):** trẻ có tài khoản riêng vào bằng **PIN** (ba mẹ duyệt PIN + khung giờ) — pattern Kid Portal DMWS (adventure/khóa-giờ/gate), **khử phần so sánh/xếp hạng giữa các trẻ**.

---

## 3. Bộ tài liệu nền (đọc theo thứ tự)

| Thứ tự | File | Khi nào đọc |
|---|---|---|
| 1 | **`DMA_00_START_HERE.md`** (file này) | Mỗi phiên, đầu tiên |
| 2 | **`DMA_RULES.md`** | Mỗi phiên — túi khôn, đọc trước khi viết SQL/code |
| 3 | **`DMA_SYSTEM_MAP.md`** | Khi cần toàn cảnh kiến trúc + bản đồ tái dùng DMWS |
| 4 | **`DMA_BUILD_PATH.md`** | Khi lên kế hoạch chặng build kế tiếp |
| 5 | **`DMA_05_DMWS_REFERENCE.md`** | Khi cần đối chiếu pattern/schema/bài học THẬT của DMWS (RLS, media, Lovable, scope creep) |
| 6 | `DMA_HANDOFF_v[mới nhất].md` | Mỗi phiên — trạng thái phiên gần nhất (nếu có) |
| — | Tài liệu A–G (PRD/IA/DataModel/PageSpec/BuildPlan/DemoData/**MediaSecurity**) | Tra spec chi tiết. **Tài liệu G = nguồn sự thật cho mọi thứ về media.** |

---

## 4. ⭐ HAI THÉP CHỜ (thiết kế V1 phải để sẵn cho toàn dự án)

Giống đổ móng nhà 1 tầng nhưng chừa thép chờ để lên tầng 2 khỏi đập móng:

**Thép chờ #1 — Nhật ký treo vào ĐỨA TRẺ, không treo vào trường.**
Bảng hành trình (`child_journey`) gắn `child_id` làm gốc + sẵn cột **nguồn** (`source`: V1 luôn = "demen", nhưng cột đã có). Môn nghệ thuật (`programs`) là **danh mục TOÀN CỤC** — "Piano" ở Dế Mèn và "Piano" ở nơi khác cùng một program. → Thêm nguồn ngoài / PH tự thêm sau = thêm 1 giá trị `source`, KHÔNG đổi cấu trúc. *Nếu lỡ thiết kế nhật ký THUỘC trường → sau phải đập.*

**Thép chờ #2 — `children` KHÔNG bị khóa cứng khỏi việc sau này có danh tính riêng.**
V1 trẻ không đăng nhập (đúng tài liệu), nhưng đừng mô hình hóa trẻ kiểu "vĩnh viễn không thể là user". Để ngỏ chỗ gắn PIN/quyền-vào-app sau (vd cột nullable dành sẵn, hoặc tách identity khỏi enrollment). → Mở cổng Kid sau = không tái cấu trúc `children`.

> Phần còn lại (gộp cổng Trường&GV về mặt nhóm, PH thêm hoạt động ngoài) chỉ là UI/luồng — làm sau dễ, KHÔNG cần thép chờ schema.

---

## 5. BOOT PROTOCOL — đầu mỗi phiên

1. Đọc file này.
2. Đọc `DMA_HANDOFF_v[mới nhất]` nếu có → trạng thái + việc dở.
3. **AUDIT THẬT** library trên đĩa (đừng tin mô tả): luật cuối + footer có khớp phiên gần nhất không. *(DMWS từng boot ra library tụt 2 phiên — đừng lặp lại.)*
4. Trước khi viết **bất kỳ SQL/code nào**: audit schema THẬT (`information_schema`, `pg_get_functiondef`, `pg_policies`). KHÔNG đoán. *(D1)*
5. Sequencing: **DB → RLS/Function → Edge Function → UI.**

---

## 6. ⭐ KỶ LUẬT VÀNG — làm tới đâu, ghi tới đó (KHÔNG bỏ sót)

DMA tồn tại để làm KHÁC DMWS chỗ này: DMWS mãi tới phiên 162 mới có hệ thư viện + Trung Tâm Tra Cứu → 161 phiên đầu sai/lặp. **DMA dựng cả hai NGAY Phase 1.** Mỗi khi xong một thay đổi có cấu trúc, cập nhật NGAY:

1. **Library** (file `.md`): thêm luật vào `DMA_RULES.md`; cập nhật `DMA_SYSTEM_MAP.md` nếu thêm/sửa bảng/module.
2. **Trung Tâm Tra Cứu** (registry trong app): module mới phải có **đủ** `description` + `usage_note` + `search_keywords` + `related_slugs` NGAY lúc tạo. *(DMWS để 42/46 module thiếu `search_keywords` → search câm.)*
   - Hub/registry (gom nhiều con / quét nhiều bảng) phải liên kết **đối xứng hai chiều** với con.
   - Hub trỏ tới module **ẩn** → line vô hình; phải trỏ thêm ≥1 module *enabled*.

> Library (cho Claude) và Tra Cứu (cho operator) = HAI MẶT của một sự thật. Update CÙNG NHỊP.

---

## 7. HANDOFF — cuối phiên (khi Jean chốt)

- Tự đánh giá + viết **đúng 1 file** `DMA_HANDOFF_vX.md` mới (nhúng mục lục phiên ở đầu).
- Tự cập nhật **TRỌN** các file library có thay đổi → xuất **FILE HOÀN CHỈNH đã áp patch**, gửi qua `present_files`. KHÔNG đưa "patch để Jean tự chèn". File không đổi thì nói rõ.
- Đọc giờ qua `TZ='Asia/Ho_Chi_Minh' date` (GMT+7). KHÔNG tự suy "sprint mất X giờ".
- KHÔNG tự ý viết handoff — HỎI Jean trước.

---

## 8. Cách làm việc với Jean

- Tiếng Việt hoàn toàn. Xưng **anh** (Jean) / **em** (Claude). KHÔNG "chị".
- Jean **không phải developer** → Claude viết toàn bộ SQL/code/prompt để Jean tự apply (Supabase SQL Editor, Lovable, Dashboard). Jean verify bằng **ảnh thật + SQL JSON**; Claude không truy cập trực tiếp DB/repo.
- **SQL chia khối nhỏ đánh số** (SQL Editor chỉ trả kết quả statement cuối → đặt SELECT verify cuối).
- Mỗi lượt: **multiple-choice có recommendation** + **một next action** duy nhất.
- Push back khi over-engineer. **"Có phức tạp không?"** = tín hiệu reset MVP.
- Verify bằng bằng chứng thật — KHÔNG tin "build OK"/"Lovable xong". *(D3)*

---

*Khởi tạo cho Project DMA, chắt lọc kinh nghiệm DMWS v1→v170. Cập nhật khi quy trình/tầm nhìn thay đổi.*
