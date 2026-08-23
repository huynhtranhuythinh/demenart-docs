# 📦 DMA_HANDOFF_v66.md — KID JOURNEY TRUST POLISH + PARENT READING EXPERIENCE

> **Phiên:** V66 · **Ngày chốt:** 2026-07-08 17:48 GMT+7
> **Loại:** Polish version sau V65 — nhịp tăng "độ tin cậy" + "khả năng đọc" cho phụ huynh, KHÔNG thêm tính năng lớn.
> **Chốt scope:** Journey Trust Polish + Parent Reading Experience · **frontend-only** · 0 DB/RPC/RLS/Auth/migration · 0 AI thật · không game mới · không Art Growth Radar.

---

## 1. V66 LÀ GÌ

V66 tiếp nối V65 (Journey Timeline Polish + Parent Preview). Không phải sprint kỹ thuật — là nhịp **polish trust + readability** để khi phụ huynh vào `/kid`, họ không chỉ thấy timeline đẹp mà còn hiểu rõ: (1) dữ liệu đến từ đâu, (2) vì sao hệ thống nói vậy, (3) đâu là quan sát thật / đâu là AI placeholder, (4) làm sao cùng con xem lại hành trình một cách nhẹ nhàng.

Câu định hướng: *"Ba mẹ xem được hành trình thật của con, hiểu dữ liệu đến từ đâu, và biết cách cùng con trò chuyện về nghệ thuật."*

Toàn bộ V66 dùng lại **Option A (gộp frontend read-time)** của V64/V65 — 5 mảng thật từ `get_kid_album_service` → `kidJourneyModel.ts` → `JourneyEventViewModel[]`. **Không nâng RPC, không đụng DB, KHÔNG đụng `kidJourneyModel.ts`** (model đã đủ).

---

## 2. ĐÃ SHIP (3 commit · thứ tự C1→C2→C3 · deploy 1 lần cuối)

| # | SHA | Nội dung |
|---|-----|----------|
| **C1** | `751a31bd` | **Trust copy + source label color-code.** (a) Footnote nghiêng nguồn dữ liệu dưới Parent Preview 💛: *"Tổng hợp từ những hoạt động và khoảnh khắc đã được lưu trong hành trình của con."* (b) Helper thuần MỚI `journeyLabelClass(category)` → color-code nhãn timeline: `tac_pham`→rose · `am_nhac`→teal · `lop_hoc`→sky · `cot_moc`→violet · default→amber. Áp cho cả card đơn (`e.category`) lẫn card gom tranh (`"tac_pham"`). **Text nhãn GIỮ NGUYÊN.** (`kid.tsx`) |
| **C2** | `23170377` | **AI Review disclaimer + Parent conversation prompt.** (a) Micro-section *"Gợi ý ba mẹ hỏi con hôm nay 💬"* — 3 câu hỏi mềm STATIC (không phụ thuộc AI/event), đặt NGAY SAU Parent Preview, TRƯỚC AI Review. (b) Viết lại copy nhánh insufficient-data của AI Review non-diagnostic rõ: *"AI chưa đưa ra nhận xét phát triển vì hành trình của {tên} cần thêm dữ liệu theo thời gian. Khi đủ dữ liệu, AI chỉ hỗ trợ ba mẹ và giáo viên quan sát xu hướng nghệ thuật của con — không thay thế nhận xét của giáo viên."* (`kid.tsx`) |
| **C3** | `c3f535b7` | **Artwork soft-paper background + empty-state.** (a) Letterbox artwork `object-contain` (timeline single + drawingGroup thumbnails) đổi từ xám `bg-black/5` → **cream `bg-amber-50/50`** (soft-paper, hợp ivory/honey); TÁCH bg vào từng nhánh để moment `object-cover` GIỮ NGUYÊN `bg-black/5`; tranh của bé KHÔNG bị cắt. (b) Empty-state Tác phẩm mềm hơn. (`kid.tsx`) |

Quy trình mỗi commit theo D134: `send_message` → `get_diff` (verify) → typecheck pass. Deploy 1 lần cuối (`demenart.lovable.app` / production `demenart.com`) — tránh 3 build production thừa. Diff sạch từng lượt. Tổng ~4.8 credit.

---

## 3. KIẾN TRÚC (không đổi cấu trúc)

- **Tầng gộp:** `src/lib/kidJourneyModel.ts` — **V66 KHÔNG ĐỤNG** (giữ nguyên `buildJourneyFeed` / `journeySummary` / `groupDrawingRows` từ V64/V65).
- **`kid.tsx` — thay đổi V66 (9 edit, cùng 1 file):**
  - C1: helper thuần MỚI `journeyLabelClass(category): string` đặt sau `journeyEmoji`; footnote Parent Preview; 2 nhãn card (single + drawingGroup) dùng `cn(..., journeyLabelClass(...))`.
  - C2: khối `<div>` micro-section 💬 (map 3 câu static) chèn trước comment `{/* AI Growth Review ... */}`; đổi copy `<p>` nhánh else của AI Review.
  - C3: `bg-black/5` → `bg-amber-50/50` ở thumbnail drawingGroup; tách bg theo nhánh moment/tranh ở ảnh card đơn; đổi copy empty-state Tác phẩm.
- **0 DB · 0 RPC mới · 0 RLS/Auth/PIN/device-pairing change · 0 Edge · 0 AI call thật.**

---

## 4. HAI RÀO TRUNG THỰC (giữ nguyên, V66 tái khẳng định)

- **Rào 1 — Tô màu chưa tách khỏi Tranh:** coloring + drawing vẫn chung `kind='drawing'` → chỉ dùng nhãn chung **"Tranh"** (rose). V66 KHÔNG hiện "Tô màu"/"Coloring".
- **Rào 2 — Chưa có media origin taxonomy:** moment origin chưa có source thật → chỉ dùng **"Khoảnh khắc ở lớp"** (sky). V66 KHÔNG hiện "Workshop"/"Sân khấu"/"Event".

**⭐ D199-nguyên-tắc (mới):** color-code nhãn theo category ĐỦ để phụ huynh đọc nhanh — **KHÔNG đổi wording nhãn tham** ("Tác phẩm của con"/"Hoạt động âm nhạc"…) vì tạo cảm giác có phân loại backend mới (nợ dữ liệu) trong khi backend không đổi.

(DMA-KID-MEDIA-001 · DMA-KID-JOURNEY-001/002/003 · DMA-KID-AI-REVIEW-002/003)

---

## 5. NGHIỆM THU (13/13 PASS — verify tận mắt trên `/kid` phiên An, 9 ảnh Jean)

1. `/kid` chạy production/dev không lỗi ✅
2. Parent Preview vẫn dùng số liệu thật, không hardcode (🎨 6 tác phẩm · 🎵 2 âm nhạc · 🎬 3 khoảnh khắc) ✅
3. Timeline vẫn dùng dữ liệu thật từ model hiện có ✅
4. Không có migration ✅
5. Không có RPC mới ✅
6. Không gọi AI thật ✅
7. AI Review copy trung thực, không tạo nhận xét giả ("chưa đủ dữ liệu… không thay thế giáo viên") ✅
8. Source label/copy giúp phụ huynh hiểu loại nội dung (color-code rose/teal/sky/violet) ✅
9. Có gợi ý hội thoại nhẹ cho ba mẹ và con (card 💬 3 câu) ✅
10. Artwork vẫn không bị cắt (soft-paper cream letterbox) ✅
11. Empty/low-data copy polish tích cực (Tác phẩm; 2 empty-state khác giữ nguyên vì đã tích cực) ✅ — không trigger vì An có data thật (đúng thiết kế)
12. Không làm UI rối hơn V65 ✅
13. Nghiệm thu bằng `/kid` với feed hiện tại ✅

**Cách verify /kid:** PH An = `ph.hung.kidshouse@demo.demenart.com` / `Test@123` → bật "Cổng của bé", ghép thiết bị, nhập PIN An → `/kid` → mục "Hành trình của An".

**Nhiễu môi trường (KHÔNG phải bug app):**
- Overlay nút đỏ **"📌 Save"** đè lên ảnh = **extension Pinterest** của trình duyệt Jean tự chèn lên mọi `<img>`. Tắt extension / tab ẩn danh là hết.
- Card **gom tranh cùng ngày** (V65 C2) CHƯA trigger vì feed An chưa có ngày nào ≥3 tranh LIÊN TIẾP (8/7 có 2 tranh; 7/7 & 6/7 bị giọng hát chen giữa phá chuỗi). Logic đúng, chờ data phù hợp.

---

## 6. FILE ĐỤNG (chỉ 1)

- `src/routes/kid.tsx` — C1 (helper `journeyLabelClass` + footnote + 2 nhãn), C2 (micro-section 💬 + AI Review copy), C3 (bg cream + empty-state).
- **0** file khác. **KHÔNG đụng `kidJourneyModel.ts`**, `routeTree.gen.ts`, `components/kid/*`, `parent.journal.tsx`, Supabase, Edge.
- Lưu ý phụ: C1 Lovable tự bump devDep `@lovable.dev/vite-tanstack-config` 2.7.0→2.7.1 (patch build-config nội bộ, không phải code app, vô hại).

---

## 7. KHÔNG LÀM TRONG V66 (guard đã tôn trọng)

Không migration · không RPC mới · không nâng `get_kid_journey_service` · không sửa `get_child_journal` · không ghi creations/moments vào `child_journey` · không AI Review thật · không gọi AI · không đổi text nhãn taxonomy · không Parent Portal đầy đủ · không Journey Detail (chi tiết từng tác phẩm) · không upload media · không notification · không sửa auth/schema · không game mới · không Art Growth Radar · không gom tranh theo ngày (logic V65 giữ nguyên) · không social/comment/share public.

---

## 8. BACKLOG / ON THE HORIZON

**Mới ghi nhận từ V66:**
- 🟡 **Group artwork** chỉ hiện khi có ≥3 tranh cùng ngày LIÊN TIẾP (logic đã ship V65 `groupDrawingRows`) — chờ data phù hợp, không phải bug.
- 🟡 **Empty-state** (Hành trình rỗng + Parent Preview <3) cần một child ÍT DATA để nghiệm thu — hiện An có đủ data nên không trigger.

**Kế thừa (chưa làm) — KHÔNG thuộc V66, cân nhắc version sau:**
- 🟠 **Parent Portal đầy đủ** / **Journey Detail** (chi tiết từng tác phẩm) / **Art Growth Radar** (V67, DMA-KID-ART-RADAR-001/002/003 còn treo).
- 🟠 **AI Growth Review THẬT** — cần policy + consent + ngôn ngữ non-diagnostic (DMA-KID-AI-REVIEW-001 còn treo).
- 🟠 **RPC `get_kid_journey_service`** — PH + Radar dùng chung taxonomy seed.
- 🟠 **`child_journey` enrichment** — creations & moments chưa chảy vào spine (hiện chỉ session + badge).
- 🔴 **Coloring JSON schema** — lưu `{type:"coloring", templateId, coloredRegions}` phân biệt drawing/coloring (cần Jean duyệt trước migration).
- 🔴 **Media origin taxonomy** — thay mock origin bằng taxonomy thật (Workshop/Sân khấu/Event).
- Backlog GitHub backup commits (migrations 093–104): Jean thủ công.

---

## 9. BOOT PROTOCOL PHIÊN SAU

1. Đọc `DMA_HANDOFF_v66.md` (file này).
2. Đọc `DMA_00_START_HERE.md` + `DMA_RULES.md` (endpoint D199+).
3. Đọc `DMA_SYSTEM_MAP.md` (v0.60+).
4. Audit live database — KHÔNG tin disk snapshot. (Với sprint frontend-only: audit code thật qua Lovable `read_file` là đủ, không cần query Supabase.)
5. Nếu Project Library chưa cập nhật → báo trước khi làm.

**Workflow mặc định:** Claude đưa code byte-exact để Jean tự paste (tiết kiệm credit). Chuyển agent mode (`send_message`→`get_diff`→deploy) khi Jean nói "tự áp"/"auto-app". Sau sửa code UI + BUILD PASS → tự publish; chỉ dừng hỏi khi (1) build fail, (2) đụng schema/data Supabase, (3) có thể phá buổi đang chạy thật.

---

## 10. TÀI KHOẢN DEMO (password `Test@123` · `@demo.demenart.com`)

- **PH An/Khang — KHM Nguyễn Văn Hùng:** `ph.hung.kidshouse` *(dùng nghiệm thu /kid của An)*
- Master KHM Nguyệt Thi: `hieutruong.kidshouse`
- GV KHM Mỹ Linh: `gv.linh.kidshouse`
- Master MNDM Phương Dung: `hieutruong.demen`
- GV MNDM Ngọc Hân: `gv.han.demen`
- PH MNDM Văn Thành: `ph.thanh.demen`

*(Ghi email đầy đủ + mật khẩu khi nhờ Jean test — không để Jean tự tra.)*

---

*V66 = Journey Trust Polish + Parent Reading Experience · frontend-only · 0 DB/RPC/RLS/Auth/migration · 0 AI thật · không game mới · không Radar · chỉ `kid.tsx` (không đụng `kidJourneyModel.ts`). Đóng sổ 2026-07-08 17:48 GMT+7.*
