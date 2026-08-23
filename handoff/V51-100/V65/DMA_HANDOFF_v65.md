# 📦 DMA_HANDOFF_v65.md — KID JOURNEY TIMELINE POLISH + PARENT PREVIEW

> **Phiên:** V65 · **Ngày chốt:** 2026-07-08 14:40 GMT+7
> **Loại:** Polish version sau V64 — nhịp làm đẹp Timeline, KHÔNG thêm tính năng lớn.
> **Chốt scope:** Journey Timeline Polish + Parent Preview · **frontend-only** · 0 DB/RPC/RLS/Auth/migration · 0 AI thật · không game mới · không Art Growth Radar.

---

## 1. V65 LÀ GÌ

V65 tiếp nối V64 (Kid Journey Timeline). Không phải sprint kỹ thuật — là nhịp **polish UI/UX** để Timeline trở thành phần đáng xem nhất của Kid Portal, và thêm một cửa sổ nhỏ cho phụ huynh hiểu đây là **nhật ký hành trình nghệ thuật của con**, không phải activity log.

Câu định hướng: *"Mỗi ngày con đang lớn lên một chút qua nghệ thuật."*

Toàn bộ V65 dùng lại **Option A (gộp frontend read-time)** của V64 — 5 mảng thật từ `get_kid_album_service` → `kidJourneyModel.ts` → `JourneyEventViewModel[]`. **Không nâng RPC, không đụng DB.**

---

## 2. ĐÃ SHIP (5 commit · thứ tự C1→C3→C4→C5→C2 · tất cả deploy production)

| # | SHA | Nội dung |
|---|-----|----------|
| **C1** | `eb52ccf9` | **Timeline card visual polish** — tranh timeline dùng `object-contain` (hết cắt xén tác phẩm của bé), moment photo giữ `object-cover`. Height responsive: tranh `max-h-[280px] sm:max-h-[380px]`, moment `max-h-[300px] sm:max-h-[400px]`. Branch theo `e.eventType === "moment"`. (`kid.tsx`) |
| **C3** | `c38613eb` | **Moment copy polish** — storyText mềm hơn, không bịa: có caption → *"Cô đã lưu lại một khoảnh khắc của {tên} ở lớp: '…'."*; không caption → bỏ dấu hai chấm. Không suy đoán nội dung/cảm xúc/tiến bộ. (`kidJourneyModel.ts`) |
| **C4** | `8a8a2df3` | **Parent Preview micro-section** — block "Ba mẹ nhìn lại cùng {tên} 💛" đặt ĐẦU section Hành trình, TRƯỚC thẻ AI Review. Helper thuần `journeySummary(feed)` → `{works, music, moments, sessions, seeds, total}`. Đủ data (total≥3) → chips 🎨/🎵/📸 + "Hạt giống đang xuất hiện: …"; ít data → câu mềm không "nổi bật". (`kidJourneyModel.ts` + `kid.tsx`) |
| **C5** | `502a030b` | **Low-data/Empty state** — khi `feed.length===0` hiện thẻ *"Hành trình của {tên} vừa bắt đầu…"* + CTA nhẹ (Vẽ / Hát, reuse `onStartDraw`/`onStartRecord`), không gamification. Additive, không đụng block timeline. (`kid.tsx`) |
| **C2** | `2ad722e8` | **Group tranh cùng ngày** — helper thuần `groupDrawingRows(shownFeed)`: gom ≥3 tranh (`kind='drawing'` + media image) **CÙNG NGÀY (giờ HCM) LIÊN TIẾP** thành 1 thẻ mini-grid `grid-cols-3` (tối đa 6 thumbnail). Chỉ gom tranh — KHÔNG audio/moment/session/badge. Chạy SAU filter nên sort/filter đúng, không mất tác phẩm. (`kidJourneyModel.ts` + `kid.tsx`) |

Quy trình mỗi commit theo D134: `send_message` → `get_diff` (verify) → `deploy_project`. Typecheck pass + diff sạch từng lượt.

---

## 3. KIẾN TRÚC (không đổi cấu trúc)

- **Tầng gộp:** `src/lib/kidJourneyModel.ts` (thuần TS, 0 side-effect). `buildJourneyFeed(album)` giữ nguyên từ V64.
- **Exports MỚI trong V65:**
  - `journeySummary(feed, topN=3): JourneySummary` + type `JourneySummary = {works, music, moments, sessions, seeds, total}` — đếm theo eventType/kind, top seeds theo tần suất. (C4)
  - `groupDrawingRows(feed): TimelineRow[]` + type `TimelineRow = {kind:"single",event} | {kind:"drawingGroup",id,occurredAt,events[]}` + private `dayKeyHCM(iso)` (Intl `Asia/Ho_Chi_Minh`, en-CA → YYYY-MM-DD). (C2)
- **Render Timeline (`kid.tsx`):** `<ul>` map qua `groupDrawingRows(shownFeed)` — 2 nhánh row: `drawingGroup` (mini-grid) và `single` (giữ nguyên render V64 + object-fit C1). Connector line dùng `!isLast`.
- **0 DB · 0 RPC mới · 0 RLS/Auth/PIN/device-pairing change · 0 Edge · 0 AI call thật.**

---

## 4. HAI RÀO TRUNG THỰC (giữ nguyên, V65 tái khẳng định)

- **Rào 1 — Tô màu chưa tách khỏi Tranh:** coloring + drawing vẫn chung `kind='drawing'` (schema không phân biệt) → chỉ dùng nhãn chung **"Tranh"**. V65 KHÔNG hiện "Tô màu"/"Coloring"/"Tranh tô màu". Card gom C2 cũng chỉ gắn nhãn "Tranh".
- **Rào 2 — Chưa có media origin taxonomy:** moment origin chưa có source thật → chỉ dùng **"Khoảnh khắc ở lớp"**. V65 KHÔNG hiện "Workshop"/"Sân khấu"/"Event"/"Biểu diễn".

(DMA-KID-MEDIA-001 · DMA-KID-JOURNEY-001/002/003 · DMA-KID-AI-REVIEW-002/003)

---

## 5. NGHIỆM THU (13/13 PASS — verify tận mắt trên `/kid` phiên An)

1. Timeline dùng dữ liệu thật từ V64 ✅
2. Timeline gọn/đẹp/dễ scroll hơn ✅
3. Card media không ngập màn hình (height cap) ✅
4. Nhiều tranh cùng ngày: có quyết định rõ (group ≥3 cùng ngày; data hiện tại ~2 tranh/ngày nên chưa trigger — đúng thiết kế) ✅
5. Moment copy mềm nhưng trung thực ✅
6. Parent Preview giúp PH hiểu là nhật ký hành trình nghệ thuật ✅
7. AI Review vẫn placeholder an toàn ("AI hỗ trợ quan sát" + insufficient-data) ✅
8. Không fake "Tô màu"/"Workshop"/"Sân khấu" ✅
9. Không gọi AI thật ✅
10. 0 migration/RPC/RLS/Auth/PIN/device-pairing change ✅
11. Typecheck pass (mọi commit) ✅
12. Mobile không vỡ (branch object-fit + flex-wrap chips + grid-cols-3) ✅
13. Kid Portal giữ cảm giác đẹp/ấm/cảm xúc ✅

**Cách verify /kid:** PH An = `ph.hung.kidshouse@demo.demenart.com` / `Test@123` → bật "Cổng của bé", ghép thiết bị, nhập PIN An → `/kid` → mục "Hành trình của An". (Lưu ý: `?` vỡ ảnh ở phiên Safari trước là cache/CORS của trình duyệt đó — qua Chrome load đủ; đường signed-URL/Bunny khỏe, KHÔNG phải bug.)

---

## 6. FILE ĐỤNG (chỉ 2)

- `src/lib/kidJourneyModel.ts` — C3 (storyText moment), C4 (`journeySummary`), C2 (`groupDrawingRows` + `dayKeyHCM` + type `TimelineRow`).
- `src/routes/kid.tsx` — C1 (object-fit/height), C4 (import + block Parent Preview), C5 (empty-state), C2 (import + paste-over `<ul>` timeline).
- **0** file khác. Không đụng `routeTree.gen.ts`, `components/kid/*`, `parent.journal.tsx`, Supabase, Edge.

---

## 7. KHÔNG LÀM TRONG V65 (guard đã tôn trọng)

Không migration · không RPC mới · không nâng `get_kid_journey_service` · không sửa `get_child_journal` · không ghi creations/moments vào `child_journey` · không AI Review thật · không gọi AI · không Parent Art Growth Radar · không radar chart · không tách Coloring schema · không tạo media origin taxonomy · không fake Workshop/Sân khấu/Tô màu · không game mới · không refactor sâu 8 game · không social/comment/share public.

---

## 8. BACKLOG / ON THE HORIZON

**Mới từ V65:**
- 🟡 **Artwork letterbox:** tranh nét mảnh để `object-contain` hiện dải **nền xám (`bg-black/5`) hai bên** — cân nhắc đổi sang **nền trắng / soft-paper** ở version sau. KHÔNG sửa trong V65 (đúng chủ trương không cắt tranh của bé).
- 🟡 **Group C2 chưa hiển thị trong demo:** cần ≥3 tranh cùng 1 ngày; data An hiện ~2/ngày. Logic đã ship, sẽ tự trigger khi có data phù hợp.

**Kế thừa từ V64 (chưa làm):**
- 🔴 **Coloring JSON schema** — lưu `{type:"coloring", templateId, coloredRegions}` phân biệt drawing/coloring (cần Jean duyệt trước migration).
- 🔴 **Media origin taxonomy** — thay mock origin bằng taxonomy thật (Workshop/Sân khấu/Event).
- 🟠 **`child_journey` enrichment** — creations & moments chưa chảy vào spine (hiện chỉ session + badge).
- 🟠 **RPC `get_kid_journey_service`** (V66 — PH + Radar dùng chung taxonomy seed).
- 🟠 **AI Growth Review THẬT** (V66 — cần policy + ngôn ngữ non-diagnostic; DMA-KID-AI-REVIEW-001 còn treo).
- 🟠 **Art Growth Radar** (V67 — DMA-KID-ART-RADAR-001/002/003 còn treo).
- Backlog GitHub backup commits (migrations 093–104): Jean thủ công.

---

## 9. BOOT PROTOCOL PHIÊN SAU

1. Đọc `DMA_HANDOFF_v65.md` (file này).
2. Đọc `DMA_00_START_HERE.md` + `DMA_RULES.md` (endpoint D198+).
3. Đọc `DMA_SYSTEM_MAP.md` (v0.59+).
4. Audit live database — KHÔNG tin disk snapshot.
5. Nếu Project Library chưa cập nhật → báo trước khi làm.

**Workflow mặc định:** Claude đưa code byte-exact để Jean tự paste (tiết kiệm credit). Chuyển agent mode khi Jean nói "tự áp". Sau sửa code UI + BUILD PASS → tự publish; chỉ dừng hỏi khi (1) build fail, (2) đụng schema/data Supabase, (3) có thể phá buổi đang chạy thật.

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

*V65 = Journey Timeline Polish + Parent Preview · frontend-only · 0 DB/RPC/RLS/Auth/migration · 0 AI thật · không game mới · không Radar. Đóng sổ 2026-07-08 14:40 GMT+7.*
