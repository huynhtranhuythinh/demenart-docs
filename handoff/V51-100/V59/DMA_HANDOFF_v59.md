# DMA_HANDOFF_v59.md — GIAO CA PHIÊN

> **Đọc kèm:** `DMA_00_START_HERE.md` → `DMA_RULES.md` (đến **D183**) → `DMA_SYSTEM_MAP.md` (**v0.54**). Đây là handoff mới nhất.
> **Phiên này:** **Backup 093–102 + dọn Bunny + verify cron** (ngã kế #1+#2 ở v58) rồi **sprint nội dung C2a/C2b + C1** (ngã kế #3). **Ngày:** 2026-07-07 (GMT+7).

---

## 1. LÀM GÌ PHIÊN NÀY (tóm tắt 1 câu)

Đóng nốt sổ sách (backup repo 093–102 + 9 Edge, dọn byte mồ côi Bunny, verify cron đêm đầu), rồi **mở rộng trò cảm thụ âm thành nhiều loại** (🎵 Nhạc cụ + 😊 Vui hay buồn?) và **gắn nhãn riêng tư cho khoảnh khắc ở nhật ký phụ huynh** (🔒 Riêng gia đình / 👨‍👩‍👧 Ảnh chung nhiều bé) — tất cả bám đúng consent engine sẵn có.

---

## 2. ĐÃ SHIP (production qua Cloudflare, nghiệm thu login thật)

### 2.0. Backup repo 093–102 + 9 Edge (đóng nợ v58) — 0 mig
- Dump **verbatim từ live** 10 migration 093→102 qua base64 stripped-newline (`translate(encode(...,'base64'),E'\n','')` → `base64 -d`), **MD5 khớp live 100% từng file**. Bài học: base64 Postgres wrap 76 ký tự → JSON `\n` → transcribe sai; phải strip newline.
- Dump 9 Edge qua `get_edge_function` (D173): kid_gate v6 · upload_kid_game_sound v1 · get_signed_media_url v20 · upload_media v13 · delete_session_media v4 · capture_session_media v3 · capture_session_moment v4 (stub 410) · purge_trash v2 · school_media_admin v2.
- Giao `DMA_repo_backup_093-102.zip` + `MANIFEST_093_102.md` — **thay thế** zip 093-095 + mig 096 cũ. **Nợ: Jean commit lên GitHub.**

### 2.1. Dọn byte mồ côi Bunny (đóng nợ v58) — 0 mig
- Query `media_assets` source='kid': đúng 3 file hợp lệ của An trong `/kid/{An}/`. Jean xoá tay 2 byte lưu vẽ hỏng (trước mig 099) → xong.

### 2.2. Verify cron (đóng nợ 🟢 v55→v58)
- `purge-drive-trash-nightly` chạy đúng **02:15 HCM**. Đêm đầu (rạng 6/7) fail `secret_not_configured` (secret chưa add lúc đó — vô hại, thùng rác 7 ngày chưa có gì quá hạn). Test lại bằng `net.http_post` secret sai → **403 forbidden** → cơ chế đúng. Từ đêm 7/7 chạy trọn.

### 2.3. C2a + C2b — trò cảm thụ mở rộng nhiều loại (mig 103 · UI · nội dung)
- **Mig 103** (additive thuần): `kid_game_items` **+cột `category`** ('instrument'|'mood', default 'instrument', CHECK) → 5 nhạc cụ cũ tự về 'instrument'. **`get_kid_game_items_service`** REPLACE +field `'category'` (D15 re-grant service_role-only). **kid_gate KHÔNG đổi** — action game_items spread nguyên item nên `category` trôi qua tự động (D181).
- **UI (agent Lovable, auto-áp — commit f5d090ce, ~5 credit, get_diff sạch):**
  - `kid.tsx` GameView: nhóm item theo `category`, **màn CHỌN TRÒ** khi >1 loại đủ bài (≥3), vào thẳng nếu 1 loại (giữ trải nghiệm cũ), nút "← Đổi trò". Câu hỏi theo loại: instrument "Tiếng gì đây? 🎵" / mood "Nghe xong bé thấy sao? 😊". Cơ chế vòng chơi giữ nguyên (distractor cùng loại).
  - `admin.kid-sound-game.tsx`: ô **Loại** khi thêm/sửa (Nhạc cụ/Cảm xúc), badge mỗi dòng, đếm "≥3 mới hiện" **theo từng loại**.
- **Nội dung:** Claude synth (numpy+ffmpeg, mp3 ≤60KB): 3 âm **cảm xúc** (Vui😊 major upbeat · Buồn😢 minor slow · Bình yên😌 gentle) + 2 nhạc cụ (Sáo🎵 · Mõ🪵). Jean nạp qua `/admin/kid-sound-game` (upload cần JWT admin → bước tay Jean). Live cuối: instrument 7 ready, mood 3 ready → cả 2 loại hiện màn chọn.

### 2.4. C1 — nhãn riêng tư khoảnh khắc ở nhật ký phụ huynh (mig 104 · UI)
- **Mig 104** (additive thuần): `get_child_journal` REPLACE, mỗi moment +field **`tagged_count`** = số bé tag. **D15 re-grant giữ `authenticated`+`service_role`** (RPC này phụ huynh gọi TRỰC TIẾP client-side, KHÔNG service-only — kiểm proacl gốc trước khi revoke, D182). Verify authenticated còn execute + anon/public không lọt.
- **UI (agent Lovable, auto-áp — commit d08a9a2b):** `parent.journal.tsx` +`MomentPrivacyBadge`: `tagged_count≥2` → 👨‍👩‍👧 "Ảnh chung nhiều bé" (sky), else → 🔒 "Riêng gia đình" (amber); tooltip nêu rõ nhà trường luôn xem được. Badge dưới ảnh cùng hàng ngày, **luôn hiện** (mô tả bản chất ảnh, không phụ thuộc ảnh mở được).
- **Map tier bám consent engine (D183):** 1 bé cần `display_in_app` (riêng); ≥2 cần `group_moment_in_class` (chung, MIN rule); trường = baseline nhánh `school_staff` → tooltip, không tách tier riêng (trung thực với data: 2 phạm vi thực + trường làm nền).
- **Nghiệm thu (An, PH Hùng — ảnh production):** 2 ảnh 👨‍👩‍👧 + 2 ảnh 🔒 hiện đúng, màu phân biệt rõ. ✅

### 2.5. Polish — phân biệt "chưa có ảnh" vs "bị chặn" (0 mig)
- Điều tra 1 moment 🔒 của An báo "chưa xem được" → **không phải bug**: moment seed có caption nhưng `media_total=0` (chưa có ảnh) → `media_id=null` → rơi nhánh denied mặc định.
- **UI (agent Lovable, auto-áp — commit db27396c):** `parent.journal.tsx` MomentImage +status `"empty"`: khi `media_id` null → hiện "Khoảnh khắc này chưa có ảnh" (trung tính) thay vì "Ảnh tạm thời chưa xem được". Nhánh denied thật giữ nguyên.

---

## 3. TRẠNG THÁI DB (audit live cuối phiên)

**63 bảng · 105 SECURITY DEFINER · 155 policy · mig 001→104 · Edge 14 · cron 1 active · 3 trường.**

So v58: **+2 mig** (103, 104) — **KHÔNG thêm bảng/hàm/policy/Edge** (103 = ALTER +cột `category` + REPLACE get_kid_game_items_service; 104 = REPLACE get_child_journal). Thay đổi schema: `kid_game_items.category` (cột mới), output `get_kid_game_items_service` +category, output `get_child_journal` moments +tagged_count. **kid_gate giữ v6** (không cần đổi). Migration 103–104 xác nhận đúng tên trong `schema_migrations`.

---

## 4. VIỆC TAY JEAN (⚠️ chưa xong)

- 🟡 **Backup repo:** commit `DMA_repo_backup_093-102.zip` (10 mig + 9 Edge) lên GitHub backup repo. **Chưa cần backup 103–104** phiên này — để gộp phiên sau, nhưng ghi nhớ.
- 🟠 **Cập nhật file library (bản SỐNG của anh):**
  - RULES.md → nối **D181–D183** (text ở mục 7 dưới).
  - SYSTEM_MAP v0.53 → **v0.54**: `kid_game_items` +cột `category`; `get_kid_game_items_service` & `get_child_journal` output mở rộng; nhãn riêng tư parent journal.
  - *(Snapshot project của Claude vẫn tụt v55/v0.50 — dùng bản SỐNG của anh, đừng để Claude tái dựng từ snapshot cũ — D90/D112.)*
- ⚪ (tùy) Backup 2 âm mood/instrument mới nếu muốn lưu bản gốc synth — file ở outputs phiên này.

---

## 5. VIỆC TREO (ngã kế)

- **Trò cảm thụ — thêm loại/nội dung nữa:** hạ tầng category sẵn sàng, chỉ cần nạp data (âm thật thu/mua; hoặc thêm category mới cần nới CHECK `kid_game_items_category_chk` — additive).
- **Parent portal — sâu hơn:** lọc/nhóm khoảnh khắc theo tier; hoặc nút "quản lý đồng ý" ngay trên card.
- **Moment seed thiếu ảnh:** vài moment demo (vd An "…bước nhún…" `…00a3`) không có media — data demo, production thật sẽ có ảnh. Dọn nếu muốn sạch demo.
- 🔴 **"Try to fix all" Lovable — ĐỪNG BẤM** (D5/D14).
- Giai điệu cue TV mới · Bunny cleanup nếu còn · Media Organization Sprint (teacher-view của supplementary, fix video tile trong school drive) — mang từ trước.

---

## 6. NGÃ KẾ (chọn đầu phiên sau)

1. **Đóng nợ sổ sách:** xác nhận Jean đã commit backup 093–102; backup 103–104 + cập nhật RULES/SYSTEM_MAP bản sống.
2. **Media Organization Sprint** (teacher-view supplementary + fix video tile school drive) — nợ kỹ thuật cũ.
3. **Trò cảm thụ / Parent** đào sâu thêm (thêm loại trò, hoặc UX consent trên card).

---

## 7. KỶ LUẬT — D-RULE MỚI PHIÊN NÀY (nối vào RULES bản sống, sau D180)

**D181 MỚI:** Thêm field vào output một RPC mà Edge chỉ *spread/return nguyên item* thì **KHÔNG cần đổi Edge** — field mới trôi qua tự động (vd `category` vào `get_kid_game_items_service` → kid_gate v6 game_items tự có). Chỉ đổi Edge khi Edge *đọc/biến đổi* field cụ thể.

**D182 MỚI:** Trước khi REVOKE sau `CREATE OR REPLACE` (D15), **kiểm proacl GỐC** (`aclexplode`) để biết ai được execute: RPC gọi **trực tiếp bởi authenticated** (client `supabase.rpc`) phải **grant lại `authenticated`+`service_role`**; RPC **service-only** (chỉ Edge gọi) mới `service_role`-only. Đừng khoá nhầm `authenticated` (sẽ vỡ portal). `get_child_journal`/`get_kid_album_service` = authenticated; `get_kid_game_items_service`/`*_service` qua Edge = service-only.

**D183 MỚI:** Nhãn riêng tư moment cho phụ huynh bám **`child_count`/`tagged_count`**: 1 bé = `display_in_app` (🔒 riêng gia đình) · ≥2 bé = `group_moment_in_class` (👨‍👩‍👧 ảnh chung, MIN rule). Nhà trường = **baseline** (nhánh `school_staff` trong `media_consent_check` luôn allowed) → nêu ở tooltip, KHÔNG tách thành tier riêng. Trong UI ảnh: `media_id = null` (chưa có ảnh) ≠ denied (bị chặn) — tách state riêng, câu chữ trung tính.

**Giữ nguyên (nhắc nhanh):** D1 audit live · D92 3-khối · D15 re-grant + verify aclexplode · D90/D112 dump-từ-live + reconcile · D95 file trọn · D106 registry ngay · D116/D117 đọc source thật trước mirror/paste · D134 auto-áp + get_diff từng lượt · D164 Edge anon tự gate · D173 Edge backup qua get_edge_function · D174 Cổng Kid = Edge-gated session · D178 sáng tác bé thuộc trẻ+gia đình · D179 trò cảm thụ toàn cục dma-public, hình=emoji, không điểm, ≥3 item · D180 nới CHECK khi thêm nguồn media + MediaRecorder split(';')[0].

*Handoff v59 — 2026-07-07 GMT+7. Nguồn: Tài liệu A–G + tầm nhìn founder + DMWS + live audit. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
