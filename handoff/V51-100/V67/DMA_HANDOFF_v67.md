# 📦 DMA_HANDOFF_v67.md — PARENT PORTAL FOUNDATION + CHILD JOURNEY ENTRY

> **Phiên:** V67 · **Ngày chốt:** 2026-07-08 18:50 GMT+7
> **Loại:** Foundation nhẹ — dựng nền đầu tiên cho Parent Portal (`/parent` landing + Child Journey Summary). KHÔNG phải Parent Portal hoàn chỉnh.
> **Chốt scope:** Parent Portal Foundation · **frontend-only** · 0 DB/RPC/RLS/Auth/PIN/device-pairing/migration · 0 AI thật · không Radar/game/upload/notification.

---

## 1. V67 LÀ GÌ

Trước V67, `/parent` chỉ `throw redirect({to:"/parent/journal"})` và `home-path.ts` map PH thẳng vào `/parent/journal` → **landing "vô hình"**, phụ huynh không có cổng tổng quan. V67 biến `/parent` thành **landing thật**: cửa đầu tiên sau khi PH đăng nhập, cho ba mẹ một cái nhìn tổng quan về hành trình nghệ thuật của con, chọn con, rồi đi vào nhật ký.

Câu định hướng: *"Ba mẹ có một cổng riêng để thấy hành trình nghệ thuật thật của con, hiểu con đang có tác phẩm/khoảnh khắc nào, và có lối vào nhẹ nhàng để cùng con xem lại."*

Đây là **foundation**, không phải Parent Portal đầy đủ (dashboard nhiều con, journey detail… thuộc version sau).

---

## 2. AUDIT TRƯỚC KHI CODE (C1 — quan trọng)

Audit code thật qua Lovable `read_file`:
- **`/parent` KHÔNG cần tạo mới** — đã có 5 route dùng chung shell amber `parent.tsx` (header + nav Album/Quyền riêng tư/Cổng của bé/Hỗ trợ/Thông báo + `<Outlet/>`):
  - `parent.index.tsx` → **chỉ redirect → `/parent/journal`** (chưa có landing).
  - `parent.journal.tsx` → nhật ký con đầy đủ (timeline + creations + moments + skills + badges).
  - `parent.kid.tsx` → quản lý Cổng của bé (PIN, ghép thiết bị, khung giờ).
  - `parent.consent.tsx` → quyền riêng tư.
- **Data thật có sẵn (0 RPC mới):** danh sách con qua bảng `child_parents` theo `parent_profile_id`; số liệu con qua RPC **`get_child_journal(p_child_id)`** → `{journey, skills, badges, moments, creations}`.
- **2 quyết định Jean chốt:** ① đổi `home-path.ts` PH → `/parent` (landing-first). ② CTA chính → `/parent/journal`, phụ → `/parent/kid`, **KHÔNG trỏ `/kid`** (kid cần PIN + device pairing, máy ba mẹ không vào được).

---

## 3. ĐÃ SHIP (1 build · auto-app · deploy 1 lần)

| # | Nội dung |
|---|----------|
| **home-path** | `src/lib/home-path.ts` — 1 dòng: PH `primary_parent`/`secondary_parent` → `/parent` (trước `/parent/journal`). Routing thuần, KHÔNG chạm Auth/RLS/session/PIN. |
| **C2 landing shell** | Hero amber "Chào ba mẹ của {tên} 💛" (else "Chào ba mẹ 💛") + subcopy + 2 CTA (Xem hành trình của con → `/parent/journal`; Cổng của bé → `/parent/kid`). |
| **C3 Summary Card** | Đọc `child_parents` + `get_child_journal(p_child_id)` → đếm 🎨 Tác phẩm (`creations` drawing) · 🎵 Giọng hát (recording) · 📸 Khoảnh khắc (`moments`) · 🌱 hạt giống top (`skills`) · 🎖️ huy hiệu (`badges`). Child-selector pills khi >1 con. CTA "Xem hành trình của con". |
| **C4 guidance** | Section "Ba mẹ có thể cùng con…" — 3 gợi ý STATIC (xem lại tác phẩm / hỏi khoảnh khắc / khích lệ thử mới). |
| **C6 empty-state** | Chưa liên kết con → "Chưa có hồ sơ con nào được liên kết."; có con nhưng data rỗng/`get_child_journal` fail → "Hành trình của {tên} sẽ dần đầy lên khi có thêm tác phẩm và khoảnh khắc được lưu." KHÔNG số giả. |

Quy trình: `send_message` (auto-app, full file byte-exact + scope guard) → `get_diff` (verify sạch đúng 2 file, khớp chính xác) → `deploy_project`. Typecheck PASS. **Lưu ý vận hành:** `send_message` trả lỗi execution do **response timeout** (KHÔNG phải build fail) — `list_messages` xác nhận agent đã hoàn tất đúng 2 edit + typecheck pass; `get_diff` sạch. Bài học: gặp lỗi tool sau `send_message` → `list_messages`/`get_diff` kiểm tra trước khi gửi lại (tránh double-build tốn credit).

---

## 4. KIẾN TRÚC (không đổi cấu trúc)

- **2 file đụng (không hơn):** `src/lib/home-path.ts` + `src/routes/_authenticated/parent.index.tsx`.
- **KHÔNG đụng:** `parent.tsx`(shell) · `parent.journal.tsx` · `parent.kid.tsx` · `parent.consent.tsx` · `kidJourneyModel.ts` · `routeTree.gen.ts` · Supabase · Edge. (Route path `/parent` không đổi — chỉ chuyển index từ `redirect` sang `component` → `routeTree.gen.ts` không cần regenerate.)
- **0 DB · 0 RPC mới · 0 RLS/Auth/PIN/device-pairing · 0 Edge · 0 AI call thật · 0 npm mới.**

---

## 5. NGUYÊN TẮC TRUNG THỰC (giữ nguyên + mới)

- **Rào 1 — Tô màu chưa tách khỏi Tranh:** coloring + drawing chung `kind='drawing'` → Summary Card gộp thành nhãn chung **"Tác phẩm"**.
- **Rào 2 — Chưa có media origin taxonomy:** moment chỉ đếm số, không bịa nguồn.
- **⭐ D200-nguyên-tắc (mới):** Parent đọc journey qua **`get_child_journal`** (RLS `is_child_parent`, không PIN), KHÔNG `get_kid_album_service` (cần kid token). `/kid` = màn thiết bị bé → **Parent Portal KHÔNG trỏ `/kid` trực tiếp**. CTA: chính `/parent/journal`, phụ `/parent/kid`. Hai đường đọc journey vẫn tách rời → số có thể lệch giữa route parent vs kid (đã biết, KHÔNG bug); với An hiện KHỚP 6/2/3.
- **D200-note:** đổi `homePathForRole` đích PH → `/parent` là routing thuần frontend, KHÔNG đụng Auth/RLS/PIN — reversible.

(DMA-KID-MEDIA-001 · linh hồn "nhật ký thuộc về trẻ + gia đình, không chấm điểm trẻ")

---

## 6. NGHIỆM THU (14/14 PASS — PH Nguyễn Văn Hùng, con An/Khang, 3 ảnh Jean)

1. `/parent` chạy production ✅
2. Parent Portal landing V1 rõ ràng (hero + subcopy + CTA) ✅
3. Child Journey Summary Card hiển thị ✅
4. Summary dùng dữ liệu thật (An: 🎨 6 tác phẩm · 🎵 2 giọng hát · 📸 3 khoảnh khắc · 🌱 "Hát theo") — không hardcode ✅
5. CTA "Xem hành trình của con" → `/parent/journal` (KHÔNG `/kid`) ✅
6. Section "Ba mẹ có thể cùng con…" ✅
7. Không hardcode số giả ✅
8. Không migration ✅
9. Không RPC mới ✅
10. Không sửa RLS/Auth/PIN/device-pairing ✅
11. Không gọi AI thật ✅
12. Không Radar/game/upload/notification ✅
13. UI đồng bộ cảm xúc Kid Portal V66 (amber tone) ✅
14. PH login vào thẳng `/parent` (home-path đổi) + child-selector An/Khang chạy ✅

**Bonus xác nhận:** số 6/2/3 ở landing (`get_child_journal`) **KHỚP** Parent Preview ở `/kid` (`get_kid_album_service`) cho An → hai đường đọc trả cùng kết quả, không lệch.

**Cách verify:** PH An/Khang = `ph.hung.kidshouse@demo.demenart.com` / `Test@123` → login → vào thẳng `/parent`.

**Nhiễu môi trường (KHÔNG phải bug app):** panel bên phải mọi ảnh nghiệm thu là tab `/kid` "Chào An!" (màn PIN, phiên bé) — tab riêng, không liên quan Parent Portal.

---

## 7. FILE ĐỤNG (chỉ 2)

- `src/lib/home-path.ts` — 1 dòng (PH → `/parent`).
- `src/routes/_authenticated/parent.index.tsx` — paste-over (redirect → landing).
- **0** file khác.

---

## 8. KHÔNG LÀM TRONG V67 (guard đã tôn trọng)

Không migration · không RPC mới · không sửa RLS/Auth/PIN/device-pairing · không AI thật · không Parent Portal đầy đủ (dashboard nhiều con) · không quản lý nhiều con hoàn chỉnh · không parent approval · không notification · không media upload · không Art Growth Radar · không Journey Detail/lightbox · không game mới · không schema/migration · không trỏ `/kid` trực tiếp từ Parent Portal · không hardcode số giả.

---

## 9. BACKLOG / ON THE HORIZON

**Mới ghi nhận từ V67:**
- 🟠 **Parent Portal đầy đủ** — multi-child dashboard, quản lý nhiều con, các tiện ích ba mẹ sâu hơn (V67 chỉ là foundation landing).
- 🟠 **Journey Detail** — chi tiết từng tác phẩm/khoảnh khắc.
- 🟠 **Canonical spine hợp nhất 2 đường đọc journey** — `get_child_journal` (parent) ↔ `get_kid_album_service` (kid) còn tách rời; hợp nhất về 1 spine (creations/moments → `child_journey`) để số liệu luôn đồng nhất.

**Kế thừa (chưa làm) — cân nhắc version sau:**
- 🟠 **Art Growth Radar** (DMA-KID-ART-RADAR-001/002/003 còn treo).
- 🟠 **AI Growth Review THẬT** — cần policy + consent + ngôn ngữ non-diagnostic (DMA-KID-AI-REVIEW-001 còn treo).
- 🟠 **RPC `get_kid_journey_service`** — PH + Radar dùng chung taxonomy seed.
- 🟠 **`child_journey` enrichment** — creations & moments chưa chảy vào spine (hiện chỉ session + badge).
- 🔴 **Coloring JSON schema** — `{type:"coloring", templateId, coloredRegions}` phân biệt drawing/coloring (cần Jean duyệt trước migration).
- 🔴 **Media origin taxonomy** — thay mock origin bằng taxonomy thật.
- Backlog GitHub backup commits (migrations 093–104): Jean thủ công.

---

## 10. BOOT PROTOCOL PHIÊN SAU

1. Đọc `DMA_HANDOFF_v67.md` (file này).
2. Đọc `DMA_00_START_HERE.md` + `DMA_RULES.md` (endpoint **D200+**).
3. Đọc `DMA_SYSTEM_MAP.md` (**v0.61+**).
4. Audit live database — KHÔNG tin disk snapshot. (Sprint frontend-only: audit code thật qua Lovable `read_file` là đủ.)
5. Nếu Project Library chưa cập nhật → báo trước khi làm.

**Workflow mặc định:** Claude đưa code byte-exact để Jean tự paste (tiết kiệm credit). Chuyển agent mode (`send_message`→`get_diff`→`deploy`) khi Jean nói "tự áp"/"auto-app". Sau sửa code UI + BUILD PASS → tự publish; chỉ dừng hỏi khi (1) build fail, (2) đụng schema/data Supabase, (3) có thể phá buổi đang chạy thật. **Gặp lỗi tool sau `send_message` → `list_messages`/`get_diff` kiểm tra TRƯỚC khi gửi lại** (tránh double-build).

---

## 11. TÀI KHOẢN DEMO (password `Test@123` · `@demo.demenart.com`)

- **PH An/Khang — KHM Nguyễn Văn Hùng:** `ph.hung.kidshouse` *(dùng nghiệm thu Parent Portal — có 2 con An/Khang, test được child-selector)*
- Master KHM Nguyệt Thi: `hieutruong.kidshouse`
- GV KHM Mỹ Linh: `gv.linh.kidshouse`
- Master MNDM Phương Dung: `hieutruong.demen`
- GV MNDM Ngọc Hân: `gv.han.demen`
- PH MNDM Văn Thành: `ph.thanh.demen`

*(Ghi email đầy đủ + mật khẩu khi nhờ Jean test — không để Jean tự tra.)*

---

*V67 = Parent Portal Foundation + Child Journey Entry · frontend-only · 0 DB/RPC/RLS/Auth/migration · 0 AI thật · không Radar/game/upload/notification · chỉ `home-path.ts` + `parent.index.tsx`. Nghiệm thu 14/14 PASS. Đóng sổ 2026-07-08 18:50 GMT+7.*
