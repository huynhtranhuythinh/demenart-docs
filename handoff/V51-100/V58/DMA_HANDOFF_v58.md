# DMA_HANDOFF_v58.md — GIAO CA PHIÊN

> **Đọc kèm:** `DMA_00_START_HERE.md` → `DMA_RULES.md` (đến **D180**) → `DMA_SYSTEM_MAP.md` (**v0.53**). Đây là handoff mới nhất.
> **Phiên này:** **Kid V2.2 — 3 hoạt động Cổng Kid** (ngã kế #1 ở v57) + đóng nốt âm `soft`/`alert`. **Ngày:** 2026-07-06 (GMT+7).

---

## 1. LÀM GÌ PHIÊN NÀY (tóm tắt 1 câu)

Nuôi Cổng Kid từ "chỉ xem album" thành **sân sáng tạo 3 hoạt động** — 🎨 **Góc vẽ**, 🎤 **Bé hát** (thu âm), 🎧 **Nghe & chạm** (trò cảm thụ âm nhạc) — mỗi thứ trọn 2 đầu (bé làm ↔ ba mẹ xem), đúng linh hồn *sáng tác thuộc về trẻ & gia đình, không thi đua*; đồng thời đóng nốt file âm `soft`/`alert` còn thiếu từ v57.

---

## 2. ĐÃ SHIP (đã lên production qua Cloudflare, nghiệm thu login thật qua ảnh)

### 2.0. Notification âm `soft`/`alert` — đóng nợ v57 (0 mig, chỉ data)
- Synth 2 mp3 ấm (soft = A5→C#6 dịu; alert = E5→A5→C#6) → Jean thêm 2 dòng `notification_sounds` (soft "Nhẹ nhàng" / alert "Nhắc nhở") + upload qua `/admin/notification-sounds`.
- Nghiệm thu: bắn `child_new_activity` (soft/toast) + `license_expiring` (alert/popup) cho PH Hùng → **cả 2 kêu đúng tiếng**. Dọn 2 notif test. Giờ mọi loại thông báo đều có âm.

### 2.1. Nền chung "bé tự làm" (mig 097–100) — dùng lại cho MỌI sáng tác sau này
- **`kid_creations`** (id · child_id→children · kind∈{drawing,recording} · media_id→media_assets · caption · created_at) + RLS bật (không policy permissive — chỉ secdef chạm).
- **`kid_save_creation_service`** (mig 097, revoke anon/auth mig 098 — D15): validate session → insert `media_assets` (source='kid' · private_child_media · dma-private · stream_only=**false** · linked_child_id) + dòng kid_creations.
- **Mig 099** = vá bug 500: `media_assets_source_chk` CHECK cũ chỉ {dma_global,school,teacher} → thêm **'kid'** (D180).
- **`get_kid_album_service`** REPLACE +mảng `creations`; **`get_child_journal`** REPLACE +`creations` **CHỈ khi `is_child_parent`** (mig 100) → **trường KHÔNG thấy sáng tác của bé** (linh hồn).

### 2.2. 🎨 Góc vẽ + 🎤 Bé hát (kid_gate v5 · get_signed_media_url v20 · UI)
- **kid_gate v5:** action `save_creation` (decode base64 → PUT dma-private `/kid/{child}/{uuid}.ext` bằng `BUNNY_PRIVATE_STORAGE_KEY` → RPC) + ký creations trong album. Nhận cả drawing (png ≤5MB) lẫn recording (webm/mp4… ≤20MB).
- **get_signed_media_url v20:** thêm **nhánh sáng-tác-bé** (source='kid' && linked_child_id) → check `child_parents` trực tiếp qua service → **ba mẹ của bé xem KHÔNG cần consent** (là của bé, ba mẹ giám hộ). 3 nhánh cũ (học liệu/moment/kho trường) giữ verbatim, additive thuần.
- **UI (`kid.tsx`):** DrawView (canvas pointer, 8 sáp ấm + tẩy + xoá + save→png) · RecordView (MediaRecorder ≤60s, nghe lại/thu lại/cất; mime strip codecs — D180) · khu "Bé tự làm" trong album bé (tranh + player 🎤). `parent.journal.tsx`: khu "Bé tự làm" (CreationCard ký qua v20).
- **Nghiệm thu (An, PH Hùng):** vẽ bông hồng → hiện album bé + album ba mẹ; thu âm → 🎤 player nghe được cả 2 nơi. Trường không thấy. ✅

### 2.3. 🎧 Nghe & chạm — trò cảm thụ âm (mig 101–102 · Edge · UI)
- **Cơ chế (không thi đua):** bé nghe 1 âm nhạc cụ → chạm đúng **emoji** trong 3 lựa chọn. Đúng → 🌸 "Giỏi quá!" + câu mới; sai → rung + "Nghe lại nhé 💛". **Không điểm, không thua, không xếp hạng.**
- **`kid_game_items`** (mig 101): label · **emoji** (hình = emoji, KHÔNG cần tải ảnh) · sound_path (dma-public) · is_enabled · sort. RLS `is_admin()` + `select_enabled`. **`get_kid_game_items_service`** (session-gated, chỉ trả item bật + có âm; revoke anon/auth — D15).
- **Edge:** `upload_kid_game_sound` v1 MỚI (admin-gated qua probe admin_module_groups, ≤2MB audio, PUT dma-public `/kid-game/{id}/…`, cập nhật sound_path) — gương `upload_notification_sound`. **kid_gate v6:** action `game_items` (RPC → build URL từ `dma-public.b-cdn.net`).
- **Registry (mig 102, D106):** module `kid-sound-game` route `/admin/kid-sound-game` nhóm "🧒 Cổng Kid" + metadata đủ + cạnh 2 chiều với `notification-sounds`.
- **UI (agent Lovable — Jean "tự áp", ~11.5 credit, get_diff sạch 2 lượt):** `admin.kid-sound-game.tsx` MỚI (thêm item label+emoji · upload âm · bật/tắt · xoá · đếm "≥3 mới hiện") + `admin.tsx` nav "Trò cảm thụ âm" · `kid.tsx` +GameView (nút 🎧, 🔊 nghe = gesture-safe, 3 emoji, shuffle). Agent thêm `as unknown`/`as any` vì `kid_game_items` chưa trong generated types (đúng pattern).
- **Nội dung khởi đầu (option B):** Claude synth 5 âm (Trống🥁 · Piano🎹 · Chuông🔔 · Ghi-ta🎸 · Kèn🎷) → Jean nạp qua admin.
- **Nghiệm thu (An):** "Tiếng gì đây?" → 🔊 → chọn 🔔 đúng → 🌸 Giỏi quá!; chọn sai → Nghe lại nhé. ✅

---

## 3. TRẠNG THÁI DB (audit live cuối phiên)

**63 bảng · 105 SECURITY DEFINER · 155 policy · mig 001→102 · admin_modules 63 · Edge 14 · cron 1 active · 3 trường.**

So v57: **+2 bảng** (`kid_creations`, `kid_game_items`) · **+2 hàm definer** (kid_save_creation_service, get_kid_game_items_service; get_kid_album_service & get_child_journal là REPLACE) · **+2 policy** (kid_game_items ×2; kid_creations bật RLS không policy) · **+6 mig** (097→102) · **+1 admin_module** (kid-sound-game) · **+1 Edge** (upload_kid_game_sound; kid_gate→v6, get_signed_media_url→v20 là bump). Migration 097–102 xác nhận đúng tên trong `schema_migrations`.

---

## 4. VIỆC TAY JEAN (⚠️ chưa xong)

- 🟡 **Backup repo:** mig **097–102** (6 file) + **3 Edge** phiên này — `kid_gate` v6, `get_signed_media_url` v20, `upload_kid_game_sound` v1 (dump qua `get_edge_function` — D173). Cộng vào nợ cũ: `DMA_repo_backup_093-095.zip` + mig 096 (từ v57 chưa giải nén).
- 🟢 **Verify cron đêm đầu** (nợ v55→v57): lần chạy có-chìa-khoá đầu **02:15 rạng 7/7** — `cron.job_run_details` + `get_logs`.
- 🟠 **Cập nhật file library:** RULES.md của anh (bản sống D177) + nối **D178–D180** phiên này → D180; SYSTEM_MAP v0.52 → **v0.53** (2 bảng kid). *(Snapshot project của Claude đang tụt về v55/v0.50 — dùng bản SỐNG của anh, đừng để Claude tái dựng từ snapshot cũ.)*

---

## 5. VIỆC TREO (ngã kế)

- **Dọn 2 byte mồ côi Bunny** dma-private ở `/kid/{An}/…` — 2 lần lưu vẽ hỏng TRƯỚC mig 099 (source chưa nới 'kid' → 500 sau khi byte đã PUT). Lọc `media_assets` state='active' source='kid' đối chiếu Bunny → xoá byte thừa.
- **Trò cảm thụ mở rộng:** thêm nhạc cụ / âm thật (thu/mua) qua màn admin đã có; hoặc biến thể (nghe giai điệu → đoán vui/buồn) nếu muốn — hạ tầng emoji+âm sẵn, chỉ thêm data.
- 🔴 **"Try to fix all" Lovable — ĐỪNG BẤM** (D5/D14).
- **Parent portal 3-tier privacy label** cho moments (cần consent field trong `get_school_moments`) — mang từ v57.
- Giai điệu cue TV mới · Bunny cleanup nếu còn.

---

## 6. NGÃ KẾ (chọn đầu phiên sau)

1. **Backup repo 097–102 + 3 Edge** (đóng nợ sổ sách — lát gọn, đúng lúc sau sprint).
2. **Dọn byte mồ côi Bunny** + polish nhỏ.
3. **Parent 3-tier privacy** HOẶC mở rộng trò cảm thụ (thêm nội dung/biến thể).

---

## 7. KỶ LUẬT GIỮ NGUYÊN (nhắc nhanh)

D1 audit live · D92 3-khối · D15 re-grant (revoke anon/auth/public sau CREATE OR REPLACE, verify aclexplode) · D95 file trọn · D90/D112 dump-từ-live + reconcile · D106 registry ngay · D116/D117 đọc source thật trước khi mirror/paste · D134 auto-áp + get_diff từng lượt · D164 Edge anon tự gate · D173 Edge backup qua get_edge_function · D174 Cổng Kid = Edge-gated session · **D178 MỚI: sáng tác bé = `media source='kid'`, thuộc trẻ+gia đình — album bé + ba mẹ (parent-only trong journal), trường KHÔNG thấy; ký qua get_signed_media_url nhánh source='kid' KHÔNG cần consent (check child_parents)** · **D179 MỚI: trò cảm thụ = nội dung TOÀN CỤC ở dma-public, hình=emoji (chỉ âm cần upload), không điểm/không thua, cần ≥3 item bật** · **D180 MỚI: nới CHECK `source` khi thêm nguồn media mới (bug 500 mig 099); MediaRecorder `blob.type` có `;codecs=…` phải `split(';')[0]` trước khi so allowTypes ở Edge** · KHÔNG auto-publish đường phát/engine để Jean test Preview trước.

*Handoff v58 — 2026-07-06 GMT+7. Nguồn: Tài liệu A–G + tầm nhìn founder + DMWS + live audit. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
