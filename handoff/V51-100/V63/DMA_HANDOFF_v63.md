# DMA_HANDOFF_v63.md — GIAO CA PHIÊN

> **Đọc kèm:** `DMA_00_START_HERE.md` → `DMA_RULES.md` (**bản SỐNG ĐÃ NỐI tới D195 + 2 named rule** — xuất phiên này) → `DMA_SYSTEM_MAP.md` (**v0.57** — xuất phiên này). Đây là handoff mới nhất.
> **Phiên này (v63):** SPRINT NÂNG CẤP CỔNG KID — nâng **IA "Thế giới sáng tạo"**, thêm **2 game** (Con Gõ Lại Nhé, Pha Màu Thần Kỳ), dựng **Tô Màu Truyện Tranh (coloring template engine + save thật)**, và **1 nhịp polish có kỷ luật**. Toàn bộ **thuần frontend**, **0 DB/Edge/Bunny/migration**. **Ngày:** 2026-07-08 (GMT+7).
> **✅ Sổ sách ĐÃ ĐỒNG BỘ:** Jean cung cấp bản SỐNG (RULES D188 / MAP v0.56) → em đã nối trọn **D189–D195 + DMA-KID-IA-001 + DMA-KID-MEDIA-001** và bump **MAP v0.57**, xuất 2 file hoàn chỉnh (base byte-identical). Snapshot `/mnt/project/` cũ (D173/v0.50) — KHÔNG dùng làm gốc; file mới xuất là chuẩn.
> **⚠️ DB:** phiên này KHÔNG chạm DB. Số liệu DB mang nguyên từ v62 (chưa audit live phiên này) → **phiên sau BẮT BUỘC audit live đầu phiên theo D1** trước khi tin số.

---

## 1. KID PORTAL IA HIỆN TẠI

**Route:** `/kid` (public, device token + PIN — không auth guard). Khung ở `src/routes/kid.tsx`; mỗi game 1 component trong `src/components/kid/*` (D189).

**Màn Album (sau khi bé đăng nhập PIN) — "Thế giới sáng tạo của bé":**
- **Hero:** tiêu đề `Thế giới sáng tạo của {tên bé} 🌈` + subtitle "Hôm nay con muốn vẽ, hát hay chơi nhạc?" + **bạn đồng hành 🐱** (placeholder) với lời chào. Nền pastel xanh mint → kem (`#e7f4ec → #FBF8F1`), chỉ trong màn album (không ảnh hưởng Pair/PIN vẫn amber).
- **3 vùng hoạt động (thay grid menu phẳng):**
  - **Con tự sáng tạo ✨** (thẻ tint đào/hồng): Vẽ một bức tranh · Hát cho ba mẹ nghe
  - **Vùng âm nhạc 🎵** (thẻ tint vàng/xanh ngọc): Nghe và chạm · Chuông Định Âm · Đàn Piano · Con Gõ Lại Nhé
  - **Vùng sắc màu 🎨** (thẻ tint hồng/kem): Pha Màu Thần Kỳ · Tô Màu Truyện Tranh
- **Các mục dưới (khi có data):**
  - **Tác phẩm của {tên} 🎨** — filter pill (Tất cả / Tranh / Giọng hát), tranh badge "Tranh", audio card kid-friendly (nút play honey + thời lượng), **+ empty state** khi chưa có gì (mới thêm phiên này).
  - **Khoảnh khắc của {tên} 📸** — ảnh lớp/sự kiện, badge nguồn (Lớp học/Workshop/Sân khấu — **đang MOCK deterministic**, chờ taxonomy thật).
  - **Huy hiệu của bé 🏅** (giữ nguyên).
  - **Hạt giống đang lớn 🌱** — 4 seed card cố định (🎵 Cảm âm · 🎨 Sắc màu · 🎤 Giọng hát · 🩰 Vận động); Sắc màu/Giọng hát hiện **số thật** (đếm tranh/bài hát), còn lại trạng thái nhẹ.
  - **Hành trình của {tên} 🚌** — timeline mềm (chấm nối dây + icon môn + tên bài + ngày).

**Nguyên tắc IA (DMA-KID-IA-001):** Cổng Kid là "thế giới sáng tạo của bé", KHÔNG phải "album + menu chức năng". "Album" chỉ là khái niệm lưu trữ, không phải định danh chính của portal.

---

## 2 & 3. DANH SÁCH GAME KID + TRẠNG THÁI TỪNG GAME

Cổng Kid hiện có **8 hoạt động / 3 vùng**. Tất cả **đã chạy production** (nghiệm thu qua ảnh trên demenart.com).

| Game | Component | Vùng | Frontend-only | Lưu tác phẩm | Rotate-gate | Ghi chú |
|---|---|---|---|---|---|---|
| **Vẽ một bức tranh** | `DrawView` | Con tự sáng tạo | ✅ (canvas) | ✅ `drawing` → `kid_creations` | ❌ | bút/tẩy/đổ màu/tem, undo/redo, tranh mẫu, tải về |
| **Hát cho ba mẹ nghe** | `RecordView` | Con tự sáng tạo | ✅ (MediaRecorder) | ✅ `recording` → `kid_creations` | ❌ | thu tối đa 60s, disable + spinner khi lưu |
| **Nghe và chạm** | `GameView` | Vùng âm nhạc | ⚠️ **không thuần FE** — đọc `game_items` qua Edge `kid_gate` (không sinh data trẻ) | ❌ | ❌ | 2 category (instrument/mood), chooser khi ≥2 cat có ≥3 item |
| **Chuông Định Âm** | `BellsView` | Vùng âm nhạc | ✅ Web Audio (celesta) | ❌ | ✅ mềm | 8 chuông C→C', 5 bài chơi-theo có dẫn đường |
| **Đàn Piano** | `PianoView` | Vùng âm nhạc | ✅ Web Audio (ấm) | ❌ | ✅ mềm | 8 trắng+5 đen, mở rộng 2 quãng, phím tắt bàn phím, glissando |
| **Con Gõ Lại Nhé** | `EchoView` | Vùng âm nhạc | ✅ Web Audio (reuse chuông) | ❌ | ✅ mềm | echo notes: nghe mẫu → gõ lại; 3 cấp (2/3/4 nốt), đúng 3 lần liên tiếp lên cấp; không điểm/không phạt |
| **Pha Màu Thần Kỳ** | `MixColorView` | Vùng sắc màu | ✅ | ❌ | ❌ | 2 mode (Chơi tự do + Thử thách), 8 công thức order-insensitive, bảng màu, hint sau 2 lần |
| **Tô Màu Truyện Tranh** | `ColorBookView` | Vùng sắc màu | ✅ (SVG) | ✅ rasterize PNG → `drawing` → `kid_creations` | ❌ | **template engine 5 tranh** + 2 mode (Tô tự do / Tô theo mẫu), undo per-tranh, palette 12 màu |

**Rotate-gate mềm** (D189e): chỉ chặn khi `(orientation:portrait)` **và** `(pointer:coarse)` (mobile/tablet); desktop/iPad-ngang không bao giờ chặn; chỉ MỜI xoay (iOS Safari không lock được). Áp dụng cho nhạc cụ phím ngang (Chuông/Piano/Con Gõ Lại) để giữ **8 note một hàng khi landscape**. Game sắc màu (Pha Màu/Tô Màu) **không cần rotate-gate** (layout dọc chạy tốt cả portrait).

---

## 4. POLISH VỪA LÀM (nhịp cuối, có kỷ luật)

Audit cả 8 game trước → kết luận hệ Kid Games **đã rất nhất quán** (header + X close top-right, nút lưu disable + spinner, feedback sai/miss đều dịu không "Sai", theme theo nhóm là cố ý). Chỉ vá **2 chỗ lệch thật** (~1.3 credit):

1. **Empty state "Tác phẩm của {tên}"** — trước đây section bị ẩn hoàn toàn khi bé chưa có tác phẩm → bé mới thấy trống. Thêm card mời "Con chưa có tác phẩm nào. Hãy vẽ, hát hoặc tô màu để tạo tác phẩm đầu tiên nhé!". Chỉ ADD, không đụng nhánh cũ.
2. **Header Vẽ khớp card** — header `DrawView` đổi "🎨 Vẽ tranh cho album" → "🎨 Vẽ một bức tranh" cho khớp thẻ entry.

---

## 5. NHỮNG QUYẾT ĐỊNH **KHÔNG LÀM** (cố ý)

- **KHÔNG extract `KidGameShell` chung** — sẽ đụng cả 8 file đang chạy, rủi ro hồi quy > lợi ích. Hệ đang ổn thì không refactor lớn.
- **KHÔNG fake badge "Tô màu"** — tranh tô màu lưu dưới `kind:"drawing"`, ở tầng album **không phân biệt được** với tranh vẽ tay (không có marker). Tách "Tô màu" cần metadata → nằm chung task "Coloring JSON schema" (backlog). Không bịa badge.
- **KHÔNG migration / KHÔNG chạm DB** phiên này.
- **KHÔNG đụng logic đang chạy** (playback, auth, RLS, các game khác khi thêm game mới — mỗi bước đều `get_diff` xác minh chỉ đúng file/vùng cần).

---

## 6. RULES MỚI CẦN GHI (nối vào `DMA_RULES.md` bản sống sau D188)

**D189 (treo từ v62)** — kid · kiến trúc games tách file + Web Audio nhạc cụ. *(nội dung trọn ở HANDOFF v62 §7)*
**D190 (treo từ v62)** — kid · vẽ canvas full-tool. *(nội dung trọn ở HANDOFF v62 §7)*

**D191 MỚI [kid · Echo Notes / Con Gõ Lại Nhé]:** Game cảm âm dạng "nghe mẫu → gõ lại", **reuse nguyên note-engine của Chuông Định Âm** (celesta synth: `ensureCtx`/`playNote` bồi âm lệch hài + highpass + delay). Không sinh data trẻ (không lưu). Tiến trình theo cấp: đúng N lần liên tiếp → tăng độ dài chuỗi (2→3→4 nốt). Giữ LINH HỒN: gõ sai vẫn nghe tiếng, **không điểm/không phạt**, thông báo dịu. Dừng/đổi bài phải `ctx.close()` (huỷ lịch oscillator) rồi tạo ctx mới (D189c).

**D192 MỚI [kid · Pha Màu Thần Kỳ]:** (a) Công thức pha màu **order-insensitive** — key = `[a,b].sort().join("+")`. (b) Tổ hợp chưa định nghĩa → **tự trộn RGB trung bình** + copy "một sắc màu thật đặc biệt" (KHÔNG "Sai"). (c) Mode Thử thách: so `resultKey` của kết quả với target; sai → động viên + auto reset, hint thematic sau 2 lần; **không điểm số/không áp lực**. (d) Không rotate-gate (game sắc màu layout dọc).

**D193 MỚI [kid · Tô Màu = coloring template engine]:** Tô Màu Truyện Tranh **KHÔNG phải 1 SVG hardcoded** — mỗi tranh là **data** (`{id,title,category,icon,viewBox,regions:path[],deco,sampleRegions}`), một engine `ColoringCanvas` render generic (fill theo `coloredRegions[id]||DEFAULT_FILL`). Thêm tranh = thêm 1 object data, không lặp JSX. Mỗi region = 1 `<path>` riêng (KHÔNG flood-fill pixel). State màu + undo stack **riêng từng template**. Mode "Tô theo mẫu": so hex **uppercase chuẩn hoá** (`.toUpperCase()`) giữa `coloredRegions` và `sampleRegions`; đúng → khen + sparkle, khác → "Màu này cũng đẹp đó" (không "Sai").

**D194 MỚI [kid · lưu tác phẩm phải thật]:** Game có "lưu tác phẩm" thì save **phải thực sự xuất hiện** trong "Tác phẩm của {tên}" (nguồn = bảng `kid_creations` qua Edge `kid_gate` action `save_creation`, KHÔNG phải React state/localStorage). Tô Màu lưu bằng cách **rasterize SVG → PNG** rồi gọi **chính `saveCreation("drawing", pngDataUrl, "image/png")`** như Vẽ → vào đúng nguồn, badge "Tranh", persist Supabase, `loadAlbum()` refetch. **KHÔNG tạo `kind:"coloring"` mới khi schema chưa hỗ trợ** — hệ quả: tô màu và vẽ tay hiện KHÔNG phân biệt được ở album (cùng badge "Tranh") cho tới khi có schema coloring (backlog).

**D195 MỚI [deploy · stale chunk sau deploy]:** Client báo `404` trên `assets/*.js` + `Failed to fetch dynamically imported module` = **KHÔNG phải lỗi code** — tab cũ đi tìm chunk hash cũ (Vite đổi hash khi thêm/tách component). Xử lý: hard reload (`Cmd+Shift+R`) → đóng sạch tab demenart.com mở lại → đợi 1–2 phút cho Cloudflare build. Chỉ đào build thật khi *sau khi đóng sạch tab + đợi build* vẫn 404. Test nhanh trên Lovable Preview để tách code-lỗi vs cache-cũ.

**Named rule — DMA-KID-IA-001 [Kid Portal identity]:** Kid Portal is not an album page. It is the child's creative world. Home screen tổ chức trải nghiệm thành: (1) Hoạt động sáng tạo hôm nay, (2) Vùng nhạc/sắc màu, (3) Tác phẩm của bé, (4) Khoảnh khắc từ lớp/workshop/event, (5) Hạt giống / tín hiệu năng lực, (6) Timeline hành trình học. "Album" là khái niệm lưu trữ, không phải định danh chính.

**Named rule — DMA-KID-MEDIA-001 [Moment origin taxonomy]:** Badge nguồn moment (Workshop/Lớp học/Sân khấu…) **phải đến từ dữ liệu media origin/context thật**, KHÔNG phải nhãn UI mock. **Không thêm cột `source` đơn giản** cho tới khi định nghĩa đủ taxonomy media origin (class_session / workshop / event / teacher_upload / parent_upload / kid_creation + visibility + linked lesson/event/class). Hiện badge đang MOCK deterministic theo `moment_id` — chấp nhận tạm.

---

## 7. BACKLOG (cần Jean chốt trước khi làm)

1. 🔴 **Coloring JSON schema** — lưu `{type:"coloring", templateId, coloredRegions}` để (a) phân biệt drawing vs coloring ở album (badge/filter "Tô màu"), (b) mở lại chỉnh sửa. Cần migration + có thể sửa Edge `save_creation`/`album`. **Chưa làm — chờ duyệt.**
2. 🔴 **Moment media source taxonomy** — schema nguồn moment thật để bỏ mock badge (DMA-KID-MEDIA-001). Cần migration. **Chưa làm — chờ duyệt.**
3. 🟡 **Companion chính thức** thay 🐱 placeholder (Echo/Mix/ColorBook) — nhân vật đồng hành DMA riêng (gợi ý cũ: "Miu Nắng").
4. 🟡 **Official DMA SVG coloring templates** — thay 5 tranh demo (path toạ độ "mù") bằng asset designer/AI. Kiến trúc data-driven đã sẵn, chỉ thay object.
5. ✅ **ĐÃ XONG — `DMA_RULES.md` (→ D195 + 2 named rule) và `DMA_SYSTEM_MAP.md` (v0.57, thêm 8 game / 3 vùng / components/kid/*)** đã nối từ bản sống Jean gửi, xuất 2 file hoàn chỉnh (base byte-identical, verify pass).

**Mang từ v61/v62 (nếu chưa xong):** commit backup zip 093–102 & 103–104 lên GitHub · append D181–D190 vào RULES sống · upload `logo-standing.webp` lên `dma-public/landing/` · nghiệm thu login `/auth` mới · thêm content Kid (bài chuông/piano, game item Nghe&chạm, tranh mẫu).

---

## 8. TRẠNG THÁI DB (mang từ v62 — CHƯA audit live phiên này)

**63 bảng · 105 SECURITY DEFINER · 155 policy · mig 001→104 · Edge 14 · cron 1 active · 3 zone Bunny.**
Phiên này thuần frontend Kid → **không migration/bảng/hàm/policy/Edge/data mới**. `kid_gate` giữ nguyên (creation của bé — gồm tranh tô màu — vẫn qua `save_creation` cũ, `kind:"drawing"`). **Phiên sau: audit live đầu phiên (D1) trước khi tin số này.**

---

## 9. COMMIT PHIÊN NÀY (agent-mode, `get_diff` từng lượt trước deploy — D134)

1. `32ec419` — AlbumView IA: "Thế giới sáng tạo" + 2 section + Tác phẩm (filter + audio card) + Khoảnh khắc (source badge) + Hạt giống (4 seed) + Hành trình (timeline)
2. `48c0ffb` — **EchoView** (Con Gõ Lại Nhé) + nối `kid.tsx`
3. `d2a1c85` — **MixColorView** (Pha Màu Thần Kỳ) + section Vùng sắc màu
4. `f0082ab` — Mix V2: 2 mode (Chơi tự do + Thử thách) + bảng màu
5. `7ee4dc4` — **ColorBookView** (Tô Màu Truyện Tranh) V1
6. `3423933` — ColorBook **template engine** (5 tranh data-driven)
7. `0fe4dce` — ColorBook **save thật** (rasterize→`saveCreation`) + mode Tô theo mẫu
8. `2e69050` — polish: empty state Tác phẩm + title Vẽ khớp card

Mỗi lượt: typecheck sạch + `get_diff` sạch + deploy production Cloudflare. **Auto-publish** vì không đụng DB/auth/playback.

---

## 10. VIỆC KẾ (chọn đầu phiên sau)

1. ~~Chốt sổ sách~~ ✅ ĐÃ XONG phiên này (RULES→D195+named · MAP v0.57).
2. **Coloring JSON schema** (backlog #1) — nếu duyệt: migration + Edge, để badge/filter "Tô màu" + mở lại chỉnh.
3. **Moment media source taxonomy** (backlog #2) — nếu duyệt.
4. **Thay asset thật:** companion chính thức + official SVG coloring templates.

*Handoff v63 — 2026-07-08 GMT+7. Nguồn: v62 + get_diff từng lượt + deploy production + audit đọc 8 file game. DB số liệu mang từ v62 (chưa audit live phiên này). Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
