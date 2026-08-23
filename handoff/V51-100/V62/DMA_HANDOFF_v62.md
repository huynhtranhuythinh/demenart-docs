# DMA_HANDOFF_v62.md — GIAO CA PHIÊN

> **Đọc kèm:** `DMA_00_START_HERE.md` → `DMA_RULES.md` (bản SỐNG tới **D188**, +**D189–D190** phiên này) → `DMA_SYSTEM_MAP.md` (bản SỐNG **v0.56** → bump **v0.57**). Đây là handoff mới nhất.
> **Phiên này:** SPRINT GAME CỔNG KID — dựng **Chuông Định Âm**, **tách kiến trúc games ra file riêng**, **nâng DrawView full tính năng**, thêm **Đàn Piano** (+2 quãng · phím tắt bàn phím · glissando ấn-kéo). Toàn bộ **thuần frontend**, **0 DB/Edge/Bunny/migration**. **Ngày:** 2026-07-07 (GMT+7).
> **⚠️ Sổ sách:** snapshot project (`DMA_RULES.md`) đang cũ (tới D173) — KHÔNG phải bản sống. Bản sống Jean = D188/v0.56 (v61). D189–D190 phiên này CHỜ nối vào bản sống (xem §4).

---

## 1. LÀM GÌ PHIÊN NÀY (tóm tắt 1 câu)

Xây **2 nhạc cụ Web Audio** (🔔 Chuông Định Âm + 🎹 Đàn Piano) và **nâng 🎨 Vẽ một bức tranh** lên full công cụ cho Cổng Kid, đồng thời **tách mỗi game ra một component riêng** trong `src/components/kid/*` để dễ mở rộng — tất cả frontend, không đụng backend.

---

## 2. ĐÃ SHIP (production qua Cloudflare demenart.com, agent-mode + get_diff từng lượt, D134)

### 2.1. 🔔 Chuông Định Âm — nhạc cụ mới (`components/kid/BellsView.tsx`)
- **Nhạc cụ 8 chuông** C-D-E-F-G-A-B-C' (Web Audio synth, KHÔNG file audio), màu Chroma-Notes (tham chiếu concept color-coded bells, KHÔNG clone Prodigies), nhãn nốt + solfège Việt (Đô-Rê-Mi).
- **Tiếng chuông trong sáng** (glockenspiel/celesta): fundamental yếu + dồn bồi âm cao (2×/3×/…/8.2×) + highpass 260Hz cắt trầm + high-shelf +4dB + delay ngân sạch (bỏ reverb-noise vì đục).
- **3 cách chơi:** Chơi tự do · 🎵 Nghe thang âm (chuông tự sáng theo) · 🎶 **Chơi theo bài có hướng dẫn** — dãy chip 5 bài dưới bàn chuông (🌈 Đô Rê Mi · ⭐ Ngôi Sao Nhỏ · 🦋 Kìa Con Bướm Vàng · 🎉 Niềm Vui/Ode to Joy · 🐑 Chú Cừu Con, đều trong 1 quãng tám), bấm chip là **nghe mẫu trước** (đúng tiết tấu theo `beats`) rồi tới lượt bé — chuông cần gõ **nhấp nháy honey** dẫn đường, gõ đúng thì tiến (thanh %), gõ sai vẫn nghe tiếng, **KHÔNG điểm/không phạt** (LINH HỒN).
- **Rotate-gate mềm:** portrait + pointer:coarse → mời "Xoay ngang máy" (8 chuông 1 hàng `grid-cols-8`); desktop/iPad ngang không chặn.

### 2.2. 🎨 Vẽ một bức tranh — full tính năng (`components/kid/DrawView.tsx`)
- **4 công cụ:** ✏️ Bút · 🩹 Tẩy · 🪣 Đổ màu (flood-fill scanline) · 🌟 Tem (dán emoji).
- **3 cỡ nét** (nhỏ/vừa/to) cho bút+tẩy+tem · **12 màu** (thêm đen/nâu/trắng…) · **12 tem** (⭐🌈🦋☀️🌸🐱🌳❤️🐟🌙☁️🎈).
- **Hoàn tác/Làm lại** (↩️↪️, stack ImageData cap 16).
- **Trang:** 6 nền giấy pastel + 6 tranh tô mẫu line-art (☀️🏠🌸🐟⭐🌳) → chọn rồi bấm **🗒️ Trang mới** (tránh xoá nhầm); flood-fill tô trong đường viền tranh mẫu.
- **Lưu:** 🗑️ Xoá (làm mới đúng trang) · ⬇️ Tải về máy (PNG) · 💛 Cất vào album (qua `saveCreation` cũ, KHÔNG đổi).

### 2.3. 🎹 Đàn Piano — nhạc cụ mới (`components/kid/PianoView.tsx`)
- **8 phím trắng + 5 phím đen** (thăng C#/D#/F#/G#/A#), nhãn Đô-Rê-Mi + dải màu Chroma đáy phím trắng; đa phím (bé bấm nhiều tay).
- **Tiếng piano ấm:** bồi âm nguyên 1..5 giảm dần + lowpass 4200Hz + tắt percussive (khác chuông sáng — phân biệt rõ 2 nhạc cụ).
- Chơi tự do + 🎵 Nghe thang âm + rotate-gate mềm.
- **➕ Mở rộng 2 quãng tám** (toggle 1↔2 quãng — bàn phím sinh động: 1 quãng 8 trắng/5 đen · 2 quãng 15 trắng/10 đen, tần số + vị trí phím đen tự tính; 2 quãng ẩn solfège cho gọn).
- **⌨️ Phím tắt bàn phím** (nốt trắng `A S D F G H J K…` · nốt đen `W E T Y U…` theo thứ tự cao độ) — gõ phím vật lý kêu + sáng.
- **🖱️ Ấn-kéo/quét glissando** — giữ + kéo ngang qua phím → chạy nốt liên tiếp (chuột lẫn cảm ứng, dùng `document.elementFromPoint` để không vướng pointer-capture; `touch-action:none` chống cuộn trang).

### 2.4. Kiến trúc — TÁCH GAMES RA FILE RIÊNG (refactor thuần, 0 đổi hành vi)
- Trước: mọi màn Kid nhồi trong 1 file `kid.tsx` (~2.100 dòng).
- Sau:
  - `src/routes/kid.tsx` — chỉ khung: auth (Pair/Pin), Album, `saveCreation`, điều phối activity + import.
  - `src/components/kid/shared.ts` — `callGate` (dùng chung).
  - `src/components/kid/DrawView.tsx` · `RecordView.tsx` · `GameView.tsx` · `BellsView.tsx` · `PianoView.tsx`.
- **KHÔNG phải route** (component thường) → `routeTree.gen.ts` KHÔNG dính, route `/kid` giữ nguyên. Từ nay mỗi game sửa 1 file nhỏ → rẻ credit, `get_diff` ngắn, an toàn.

### 2.5. Cổng Kid hiện có **5 hoạt động**
🎨 Vẽ một bức tranh · 🎤 Hát cho ba mẹ nghe · 🎧 Nghe và chạm · 🔔 Chuông Định Âm · 🎹 Đàn Piano. (Grid AlbumView `sm:grid-cols-2`.)

**Commit phiên (9 lượt, ~38 credit Lovable):** `78e4f28` chuông v1 → `e8cc5ab` gate+1hàng+reverb → `860d610` tiết-tấu+resetAudio+sáng hơn → `cce8976` celesta trong sáng → `c734d48` 5 bài+chip → `6b07530` **tách file** → `f84df36` DrawView full → `0143305` **Piano** → `723b6f9` **Piano 2-quãng + phím tắt + glissando**. Typecheck sạch + get_diff sạch từng lượt.

---

## 3. TRẠNG THÁI DB (audit live đầu phiên)

**63 bảng · 105 SECURITY DEFINER · 155 policy · mig 001→104 · Edge 14 · cron 1 active · 3 trường.**

So v61: **KHÔNG đổi gì** — phiên thuần frontend Kid. Không migration/bảng/hàm/policy/Edge/data. `kid_gate` giữ v6 (sáng tác của bé vẫn qua `save_creation` cũ). Nhạc cụ Chuông/Piano **không sinh dữ liệu trẻ** → không cần consent/DB.

---

## 4. VIỆC TAY JEAN (⚠️ chưa xong)

- 🟠 **Sổ sách RULES/MAP:** nối **D189–D190** (nội dung trọn ở §7) vào bản SỐNG `DMA_RULES.md` sau D188 → **D190**; bump `DMA_SYSTEM_MAP.md` **v0.56 → v0.57** (thêm mục Kid: 5 hoạt động + `components/kid/*`). *HOẶC* gửi Claude bản SỐNG RULES(D188)+MAP(v0.56) → Claude nối trọn xuất 2 file (như v61). **(Snapshot project đang cũ tới D173 — đừng dùng nó làm gốc.)**
- 🟢 **Nghiệm thu 5 game Kid** trên tablet/máy tốt (đăng nhập Kid thật qua PH ghép PIN, vd `ph.hung.kidshouse@demo.demenart.com` / `Test@123`): Chuông (tiếng + chơi theo bài) · Piano (phím đen + tiếng) · Vẽ (4 công cụ + undo + đổ màu + tem + tải về). Mở tab mới sau deploy (Cloudflare không auto-reload).
- 🟡 **(mang từ v61, nếu chưa):** ghi đè RULES→D188 + MAP→v0.56 bản sống · upload `logo-standing.webp` lên `dma-public/landing/` · nghiệm thu login `/auth` mới.

---

## 5. VIỆC TREO (ngã kế)

- **Kid games mở rộng:** thêm bài cho Chuông (chỉ sửa mảng `SONGS` trong BellsView) · thêm game item Nghe&chạm qua `/admin/kid-sound-game` · thêm tranh mẫu/tem cho Vẽ · ý tưởng game mới (xylophone, trống, ghép hình nhạc…).
- **Invite backend:** "Tôi có mã mời" (landing + login) vẫn là modal placeholder — cần thiết kế mã mời thật.
- **Landing hero watercolor** (slot `LANDING_ASSETS` để ngỏ) · **Video Stream V2** (poster + HLS thật) · **Trò cảm thụ/Parent** đào sâu (mang từ v60/v61).
- 🔴 **"Try to fix all" Lovable — ĐỪNG BẤM** (D5/D14).

---

## 6. NGÃ KẾ (chọn đầu phiên sau)

1. **Thêm game Kid mới** (xylophone / trống / ghép nhạc…) — kiến trúc đã sẵn, mỗi game 1 file.
2. **Nội dung Kid** (thêm bài chuông/piano, game item, tranh mẫu) — phần lớn không cần code.
3. **Invite backend** — mã mời thật (school/DMA cấp → onboard).
4. **Landing/Public polish** — hero watercolor · trang Giới thiệu/Hỗ trợ.

---

## 7. KỶ LUẬT — D-RULE MỚI PHIÊN NÀY (nối vào RULES bản sống sau D188)

**D189 MỚI [kid · kiến trúc games tách file + Web Audio nhạc cụ]:** (a) Mỗi game Kid = 1 component trong `src/components/kid/*.tsx` — **KHÔNG đặt trong `src/routes/`** (sẽ thành route TanStack, đụng `routeTree.gen.ts`); `kid.tsx` chỉ giữ khung auth+album+điều phối + import; `callGate` dùng chung ở `components/kid/shared.ts`. (b) Nhạc cụ Web Audio: `AudioContext` tạo **lazy sau user-gesture** (chống autoplay-block) + `ctx.resume()` nếu suspended; mỗi note tạo osc+gain envelope (attack ~vài ms, decay exp) rồi `disconnect` trong `onended` → không leak. (c) **BUG CHỒNG ÂM:** `clearTimeout` chỉ xoá highlight, **KHÔNG dừng oscillator đã lên lịch** trên timeline — muốn "dừng/đổi bài" phải **`ctx.close()`** (huỷ sạch lịch) rồi tạo lại ctx mới lần sau. (d) Timbre phân biệt: chuông = bồi âm **lệch hài** + highpass + delay (sáng, tươi); piano = bồi âm **nguyên** + lowpass (ấm). (e) Nhạc cụ phím ngang → **rotate-gate mềm**: chỉ chặn khi `(orientation:portrait)` **và** `(pointer:coarse)` (mobile/tablet); desktop không bao giờ chặn; web KHÔNG `screen.orientation.lock()` được trên iOS Safari nên chỉ MỜI xoay. (f) Play-along giữ LINH HỒN: chuông sáng dẫn đường, gõ sai vẫn nghe tiếng, KHÔNG điểm/không phạt. (g) **Nhạc cụ nhiều phím có thể sinh động** theo số quãng (bàn phím build từ NOTE_DEFS + semitone → freq = C4·2^(semi/12)); **phím tắt bàn phím** = map key vật lý theo thứ tự cao độ (keydown bỏ `e.repeat`); **glissando ấn-kéo/quét** = KHÔNG dùng `setPointerCapture` (nó chặn pointerenter sang phím kế) mà dò `document.elementFromPoint` trên `pointermove` ở container (chạy cả chuột lẫn cảm ứng) + `touch-action:none` chống cuộn.

**D190 MỚI [kid · vẽ canvas full-tool]:** (a) DrawView dùng **1 canvas** (nền + line-art tranh mẫu + nét bé CHUNG một lớp pixel) để **flood-fill dừng ở đường viền** — nếu tách nền/line ra lớp khác thì đổ màu tràn cả tranh. (b) Undo/Redo = **stack `ImageData`** (getImageData/putImageData, cap ~16 chống ngốn RAM), snapshot sau mỗi thao tác hoàn tất; con trỏ top = trạng thái hiện tại. (c) Tẩy = **vẽ màu nền hiện tại** (không destination-out, vì 1-canvas). (d) Đổi nền/tranh mẫu KHÔNG áp ngay — chỉ **"Trang mới"** mới tô lại (tránh xoá nhầm tranh đang vẽ); Xoá = tô lại đúng trang hiện tại. (e) Flood-fill scanline chạy trên **pixel thật** (toạ độ CSS × dpr), tolerance ~40; lưu = `toDataURL` thẳng (canvas đã đủ nền+nét). (f) "Tải về" = `a.download` dataURL — tác phẩm của chính bé, không phải file ngoài.

**Giữ nguyên (nhắc nhanh):** D1 audit live · D2/D3 verify thật · D5/D14 KHÔNG "Try fix all" · D48 nhật ký/sáng tác trẻ thuộc trẻ+gia đình (kid creation source='kid', dma-private, parent-only) · D95 file trọn khi close · D116/D117 đọc source thật trước sửa · D134 auto-áp + get_diff từng lượt · D187 landing/brand-hex · D188 z-index positioned đè static.

*Handoff v62 — 2026-07-07 GMT+7. Nguồn: v61 + live audit đầu phiên + get_diff từng lượt + deploy production. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
