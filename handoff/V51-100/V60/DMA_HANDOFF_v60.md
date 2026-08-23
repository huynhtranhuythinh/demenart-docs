# DMA_HANDOFF_v60.md — GIAO CA PHIÊN

> **Đọc kèm:** `DMA_00_START_HERE.md` → `DMA_RULES.md` (đến **D186**) → `DMA_SYSTEM_MAP.md` (**v0.55**). Đây là handoff mới nhất.
> **Phiên này:** đóng nốt sổ sách (backup 103–104), **fix bug video tile** ở kho drive, và **dọn data demo journal bé An**. **Ngày:** 2026-07-07 (GMT+7).
> **⚠️ Bản sống RULES/SYSTEM_MAP nằm ở phía Jean.** Snapshot trong project Claude vẫn tụt **v55/v0.50** (RULES thiếu D132–D186, MAP thiếu v0.29–v0.55). Claude KHÔNG tái dựng file đầy đủ từ snapshot cũ (D90/D112) — dùng bản SỐNG của Jean, nối delta ở mục 7.

---

## 1. LÀM GÌ PHIÊN NÀY (tóm tắt 1 câu)

Backup 103–104 (MD5 khớp live 100%), **sửa tile video trong kho trường/kho GV** (mov/mp4 hết trắng-đen + thêm lightbox xem/phát), và **dọn journal demo của bé An** (xoá ảnh a1 nhầm rồi khôi phục, xoá hẳn card trống a3 "bước nhún").

---

## 2. ĐÃ SHIP (production qua Cloudflare, nghiệm thu login thật)

### 2.0. Backup repo 103–104 (đóng nợ v59) — 0 mig
- Dump **verbatim từ live** 2 migration 103→104 qua base64 strip-newline (bài học v59), **MD5 khớp live 100% từng file** (103 `f67db3be…`, 104 `b630ad3f…`). Byte-length file (`wc -c`) > char-length live (`length()`) do UTF-8 multibyte tiếng Việt — MD5 là chuẩn, không phải character-count.
- 103–104 **chỉ đổi DB, KHÔNG đụng Edge** (kid_gate giữ v6) → không backup Edge phiên này.
- Giao `DMA_repo_backup_103-104.zip` + `MANIFEST_103_104.md`. **Nợ: Jean commit lên GitHub** (gộp cùng 093–102 chưa commit từ v59).

### 2.1. Fix bug video tile trong kho drive (mig 0 · UI DriveExplorer)
- **Chẩn đoán data-first (D1):** kho có 3 video — **2 `.mov` (video/quicktime) + 1 `.mp4`**, KHÔNG có `bunny_stream_video_id` (lưu file thường trên dma-private, không phải HLS). `DriveExplorer.tsx` render thumbnail video bằng `<video preload="metadata" object-cover>` → Chrome/FF không decode container QuickTime → **tile `.mov` trắng**; `.mp4` ra frame đen vì không seek. Thêm: bấm file **chỉ chọn, không xem/phát được**.
- **UI (agent Lovable, auto-áp — commit `234cb5ff`, 2.3 credit, get_diff sạch 1 file):** `DriveExplorer.tsx`:
  - Tile video → **placeholder gradient (`#1c3b30→#0F6E56`) + nút Play tròn** (bỏ `<video>` inline — hết trắng/đen bất kể định dạng, chuẩn như Google Drive).
  - Thêm **lightbox** (`preview` state, z-50): bấm Play (video) / nút Maximize (ảnh, hiện khi hover) → modal `<video controls autoPlay>` hoặc ảnh full. List-view double-click file cũng mở. Giờ GV **thật sự xem/phát** được media, không chỉ chọn.
  - Ảnh giữ `<img>`. Dùng chung cho **cả `/school/drive` và `/teacher/media`** (cùng component).
- **Teacher-view supplementary: PHÁT HIỆN ĐÃ BUILD SẴN** (drift vs memory cũ, D112 tin live): `teacher.media.tsx` gọi `drive_my_zone` → ngăn riêng "Học liệu của tôi", đã nằm trong nav teacher ("Chương trình & Media"). Không dựng lại → tiết kiệm credit.

### 2.2. Dọn data demo journal bé An (mig 0 · data cleanup)
- Bối cảnh: Jean "dọn" nhưng ảnh An vẫn còn. **Nguyên nhân: ảnh moment trẻ là pool `private_child_media` (dma-private), TÁCH HOÀN TOÀN với kho trường `private_school_resource`** — "Dọn rác kho"/drive purge KHÔNG bao giờ chạm ảnh riêng của trẻ (đúng D48). → D184.
- **Bé An** = Nguyễn Hoàng An (`d1…041`), tenant DEMO. 2 việc:
  - Ảnh "tiếng đàn" (moment `…00a1`, media `4002c7c2`): Jean chốt A xoá → set `state='deleted'`; **hiểu nhầm — Jean muốn giữ ảnh này** → **khôi phục** `state='active'` (byte Bunny chưa ai xoá nên phục hồi trọn vẹn). ⚠️ **ĐỪNG xoá byte `/moments/…a1/07b9ca2c….jpg`** — đang dùng lại.
  - Card trống "bước nhún" (moment `…00a3`, 0 ảnh, seed demo, luôn hiện "chưa có ảnh"): Jean chốt A xoá hẳn → **hard-delete** theo FK con→cha trong 1 transaction (`kid_reactions`→`moment_children`→`learning_moments`; a3 media=0 nên không mồ côi byte). → D186.
- **Nghiệm thu (An, PH Hùng — production):** journal còn đúng **3 card đều có ảnh** (Bé chăm chú xem 👨‍👩‍👧 · Hình ảnh thử nghiệm 👨‍👩‍👧 · An tiếng đàn 🔒). Hết card "chưa có ảnh". ✅

### 2.3. Polish soft-delete media (learning từ 2.2)
- `media_assets.state` có `active/trashed/deleted`, chỉ trigger `updated_at` (vô hại), không CHECK/guard cột state → soft-delete/khôi phục an toàn qua `execute_sql`. `get_child_journal` lọc `state='active'` → non-active ẩn ngay, media_id null → UI "chưa có ảnh" (polish db27396c v59). **Byte `private_child_media` KHÔNG auto-purge** (cron chỉ dọn drive `private_school_resource`) → xoá byte tay nếu muốn sạch.

---

## 3. TRẠNG THÁI DB (audit live cuối phiên)

**63 bảng · 105 SECURITY DEFINER · 155 policy · mig 001→104 · Edge 14 · cron 1 active · 3 trường.**

So v59: **KHÔNG thêm mig/bảng/hàm/policy/Edge** (phiên UI + data cleanup thuần). Thay đổi DATA: xoá 1 `learning_moments` (a3) + 1 `moment_children` + kid_reactions của a3; `media_assets 4002c7c2` (a1) net = `active` (không đổi so đầu phiên). Cấu trúc schema giữ nguyên hoàn toàn.

---

## 4. VIỆC TAY JEAN (⚠️ chưa xong)

- 🟡 **Backup repo GitHub:** commit `DMA_repo_backup_093-102.zip` (từ v59) **+** `DMA_repo_backup_103-104.zip` (phiên này).
- 🟠 **Cập nhật file library (bản SỐNG của anh) — DÙNG BẢN SỐNG, không để Claude tái dựng từ snapshot tụt (D90/D112):**
  - RULES.md → nối **D181–D183** (từ v59, chưa nối) **+ D184–D186** (mục 7 dưới).
  - SYSTEM_MAP → **v0.53→v0.55**: (v0.54 từ v59: `kid_game_items.category`; `get_kid_game_items_service` & `get_child_journal` output; nhãn riêng tư parent journal) **+ v0.55 phiên này**: DriveExplorer video placeholder+lightbox; ghi rõ 2 media-pool tách (`private_child_media` vs `private_school_resource`).
- ⚪ (tùy) Xoá byte Bunny mồ côi nếu còn — **KHÔNG xoá byte a1** (đang dùng). a3 không có byte.

---

## 5. VIỆC TREO (ngã kế)

- **Trò cảm thụ — thêm loại/nội dung:** hạ tầng `category` sẵn (v59), chỉ cần nạp data; thêm category mới cần nới CHECK `kid_game_items_category_chk` (additive).
- **Parent portal — sâu hơn:** lọc/nhóm khoảnh khắc theo tier; nút "quản lý đồng ý" trên card.
- **Video drive — thumbnail thật:** nếu muốn poster thật cho video (thay placeholder), phải đẩy video qua **Bunny Stream** (`bunny_stream_video_id`) khi upload — hiện file thường không có poster. Cân nhắc V2.
- **Moment seed thiếu ảnh khác:** đã dọn a3 của An; các bé khác nếu còn card trống demo → dọn tương tự (D186) nếu muốn sạch.
- 🔴 **"Try to fix all" Lovable — ĐỪNG BẤM** (D5/D14).
- Giai điệu cue TV mới · Bunny cleanup nếu còn · Media Organization Sprint phần còn lại (nếu phát sinh) — mang từ trước.

---

## 6. NGÃ KẾ (chọn đầu phiên sau)

1. **Đóng nợ sổ sách:** xác nhận commit backup 093–102 + 103–104; nối RULES D181–D186 + SYSTEM_MAP →v0.55 bản sống.
2. **Trò cảm thụ / Parent** đào sâu (thêm loại trò, UX consent trên card, lọc theo tier).
3. **Video Stream (V2):** đẩy video drive qua Bunny Stream để có poster + HLS thật.

---

## 7. KỶ LUẬT — D-RULE MỚI PHIÊN NÀY (nối vào RULES bản sống, sau D183)

**D184 MỚI:** **Media pool tách theo `access_level`.** Ảnh/nhật ký riêng của trẻ = `private_child_media` (zone `dma-private`, thuộc trẻ+gia đình, D48); học liệu GV/trường = `private_school_resource`. Chúng TÁCH HOÀN TOÀN: "Dọn rác kho"/drive purge/`school_media_admin`/`drive_*` chỉ đụng `private_school_resource` → KHÔNG BAO GIỜ chạm ảnh moment của trẻ. Muốn dọn ảnh trẻ phải thao tác đúng pool `private_child_media`. Byte `private_child_media` KHÔNG có nightly-purge (cron chỉ dọn drive) → xoá byte Bunny tay.

**D185 MỚI:** **Tile video trong drive/finder KHÔNG render `<video>` inline làm thumbnail** cho file thường: Chrome/FF không decode container `video/quicktime` (.mov) → tile trắng; `.mp4` ra frame đen vì `preload="metadata"` không seek/paint. Dùng **placeholder (gradient + nút Play) + lightbox `<video controls>`** khi bấm. Chỉ file qua **Bunny Stream** (`media_assets.bunny_stream_video_id` không null) mới có poster/HLS thật; file thường (chỉ `bunny_path`) thì không.

**D186 MỚI:** **Xoá hẳn record có FK inbound → kiểm `constraint_column_usage` tìm bảng con TRƯỚC**, xoá con→cha trong 1 transaction (vd moment a3: `kid_reactions`→`moment_children`→`learning_moments`). `learning_moments` chỉ có state `approved/draft` (KHÔNG có 'deleted') → hide bằng set 'draft' sẽ rơi vào hàng chờ GV, không sạch → hard-delete record. Moment không ảnh (media=0) nên không mồ côi byte; moment có ảnh thì soft-delete media (`state='deleted'`) TRƯỚC + dọn byte. `media_assets.state` = `active/trashed/deleted`, chỉ trigger `updated_at`, không guard → toggle qua execute_sql an toàn, get_child_journal lọc `active` nên ẩn/hiện tức thì.

**Giữ nguyên (nhắc nhanh):** D1 audit live · D2/D3 verify login thật · D15 re-grant + aclexplode · D48 nhật ký trẻ thuộc trẻ+gia đình · D90/D112 dump-từ-live + reconcile, không tái dựng từ snapshot cũ · D92 3-khối · D95 file trọn · D116/D117 đọc source thật trước mirror/paste · D134 auto-áp + get_diff từng lượt · D173 Edge backup qua get_edge_function · D178 sáng tác bé thuộc trẻ+gia đình · D181 field mới trôi qua Edge spread · D182 kiểm proacl gốc trước REVOKE · D183 nhãn riêng tư moment bám child_count.

*Handoff v60 — 2026-07-07 GMT+7. Nguồn: v59 + live audit + login thật production. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
