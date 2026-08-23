# DMA_HANDOFF_v47.md
**Phiên:** v47 · **Ngày:** 02/07/2026 (Asia/Ho_Chi_Minh)
**Chủ đề phiên:** Remote v2 — hoàn tất PHẦN MÓNG (R1 + R2a + R2b). Cross-device thật, mô hình ghế đứng vững.

---

## 0. TL;DR đọc trước
- **Remote v2 phần móng XONG & nghiệm thu thật trên điện thoại.** Điện thoại (không đăng nhập) quét QR **hoặc** nhập PIN → điều khiển được Màn chiếu qua Supabase Realtime.
- **Mô hình ghế bảo toàn:** Remote KHÔNG phải account. Ghế GV chỉ "tiêu" ở máy Monitor (nơi GV đăng nhập). Điện thoại cầm Remote chỉ là bộ điều khiển ghép-theo-buổi.
- **Chưa làm (tầng trên, không phải móng):** R2c (UI Pro 2-layout dọc/ngang), R2d (Nền chờ TV Tầng 0). Xem §6.

---

## 1. Trạng thái DB (audit live cuối phiên — D90)
- **53 bảng · 74 SECURITY DEFINER · migrations 001→071 · 7 Edge Functions (KHÔNG đổi phiên này) · 3 tenants**
- `secdef_fns` tăng 72→74 = đúng 2 RPC mới của mig 071.

### Migration 071 (MỚI phiên này) — đã apply, VERIFY pass
`lesson_sessions` thêm 3 cột:
- `remote_channel_key text` — bí mật entropy cao (2× gen_random_uuid ghép). Vừa là **tên "phòng" Realtime**, vừa là payload trong QR (sau dấu `#`).
- `remote_code text` — PIN 6 ký tự, alphabet `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (bỏ O/0/I/1). Unique index `lesson_sessions_remote_code_uidx` (where not null).
- `remote_code_rotated_at timestamptz` — cho nút "Đổi mã" tương lai (chưa dùng).

2 RPC (khuôn theo `start_session` — D-first):
- `mint_session_remote_code(p_session_id uuid)` → **authenticated only** (`is_session_lead OR is_session_teacher`). Get-or-create mã. State cho phép: `scheduled·prep_ready·makeup·in_progress`. Trả `{ok, channel_key, code, state}`. Audit qua `write_audit_log` (actor = current_profile → D88).
- `redeem_session_remote_code(p_code text)` → **anon + authenticated** (cố ý mở anon — đây là thứ giữ mô hình ghế). Chuẩn hoá mã (upper, bỏ whitespace), tìm buổi còn "sống", trả `{ok, session_id, channel_key, title, state}`.

Grants verify: `mint → [authenticated]`, `redeem → [anon, authenticated]`, mint_no_anon_public = true. ✅

---

## 2. Sprint đã hoàn thành phiên này — Remote v2 MÓNG

### R1 — móng PIN + transport Realtime ✅
- `useSessionChannel.ts` **v3**: transport BroadcastChannel → **Supabase Realtime Broadcast** (public mode, `broadcast:{self:false}`, hàng đợi flush sau SUBSCRIBED). Chữ ký hook GIỮ NGUYÊN → không đập UI (D122). Nghiệm thu: cross-device (điện thoại khác máy) đồng bộ được — thứ BroadcastChannel không làm được.
- Đổi khoá kênh `sessionId` → `channelKey` (fallback sessionId, R1-safe).

### R2a — panel "Kết nối điều khiển" + channel_key ✅
- `teacher/session/$id.tsx` (StepTeach): nút **"Kết nối điều khiển"** → gọi `mint` → panel hiện **QR + PIN 6 ký tự**. Mã CHỈ hiện trong panel (sau đăng nhập GV), **KHÔNG lên TV** (Jean chốt: chống phụ huynh/người lạ quét).
- `openMonitor`/`openRemote` truyền `k=channel_key` (Monitor qua `?k=`, Remote qua `#k=`).
- Dependency mới: **`qrcode.react ^4.2.0`** (React 19). Render QR thuần SVG **client-side** (channel_key là bí mật, không gửi ra dịch vụ QR ngoài).

### R2b — /remote công khai + guide qua Realtime (hướng A) ✅
- **Route MỚI `src/routes/remote.tsx`** = `demenart.com/remote` (NGOÀI `_authenticated` → công khai). 2 đường vào: `#k=` (QR) hoặc ô nhập PIN → `redeem`.
- **Hướng A:** Remote công khai KHÔNG gọi `get_lesson_guide` (RPC authenticated). Guide nhận qua Realtime: Monitor broadcast `guide` khi nghe `hello` từ Remote.
  - `useSessionChannel.ts`: thêm message type `guide` + `GuideActivityLite`/`GuideMediaLite` + `publishGuide` + nhận vào `guide` state; `hello` handler (monitor) đẩy lại `status` + `guide`.
  - `classroom.tsx`: sau khi nạp guide → `publishGuide(...)` (CHỈ media `present` — tài liệu-của-cô không lọt sang Remote công khai, D75).
- Spike xác nhận (bằng thực nghiệm, D1): anon **redeem được + join Realtime được + send được**, dù `realtime.messages` RLS bật + 0 policy — vì kênh chạy **public mode**, không đụng bảng đó.

**Nghiệm thu thật:** mở Màn chiếu (laptop) → Bắt đầu trình chiếu → điện thoại (không login) quét QR / nhập PIN → nhận guide + điều khiển play/pause/seek/blackout/đổi Phần. ✅

---

## 3. File đã đụng phiên này
- `supabase` migration **071** (SQL Editor, 3 khối CREATE→GRANT→VERIFY).
- `src/hooks/useSessionChannel.ts` — v3 (Realtime + message `guide`).
- `src/routes/_authenticated/teacher/classroom.tsx` — nhận `?k=`, `publishGuide`.
- `src/routes/_authenticated/teacher/remote.tsx` — nhận `#k=` fallback sessionId (route authenticated cũ, vẫn giữ cho đường "Mở điều khiển" trên máy cô).
- `src/routes/_authenticated/teacher/session/$id.tsx` — panel QR/PIN (mint), QR trỏ `/remote#k=`, openMonitor/openRemote truyền k.
- `src/routes/remote.tsx` — **MỚI**, route công khai.
- `package.json` — thêm `qrcode.react ^4.2.0`.

---

## 4. Kiến trúc Remote v2 (chốt — để phiên sau không phá)
- **channel_key** = khoá phòng Realtime = bí mật. QR mang nó sau dấu `#` (không lọt server log). PIN 6 ký tự là đường phao → `redeem` đổi ra channel_key.
- **Mã treo theo BUỔI** (`lesson_sessions`), 1 mã/buổi, sống suốt buổi, chết khi buổi rời trạng thái sống. Nhiều remote cùng mã OK (không rò ghế). remote_id per-device chưa cần lưu DB.
- **Monitor = nguồn sự thật** hiển thị + nguồn đẩy guide. Remote công khai chỉ nhận, chỉ chạm 1 RPC anon = `redeem`. Bề mặt tấn công anon tối thiểu.
- **Layout theo TAY + nút Ghim** (hướng A đã chốt cho UI Pro — CHƯA build, xem R2c).

---

## 5. Nghiệm thu / bài học phiên này (→ D-rules mới, xem RULES)
- Deploy lag Cloudflare 2 lần gây "quét QR đá /auth" & "realtime=0" — đều là D105, không phải bug code. Test trên Lovable Preview để tách.
- `qrcode.react` thiếu trong package.json → Rollup fail resolve; thêm tay `^4.2.0` (React 19).
- Icon lucide `QrCode` thiếu import → ReferenceError crash trang → thay bằng `<QRCodeSVG size={16}>` đã import.

---

## 6. VIỆC TREO (phiên sau vào thẳng)
### Remote v2 — tầng trên (chưa làm)
- **R2c — UI Pro 2-layout** (dọc "Gọn" ↔ ngang "Full"), theo 2 mockup đã chốt (tông tối, xanh rừng + honey). Hướng A: theo tay + nút Ghim. Điện thoại-first: landscape 2 cột (KHÔNG 4). Carve nút "sắp có" (Tín hiệu TV / Ghi nhận / Chụp) — không nối engine. Tách 2 nút đỏ (Thoát ≠ Kết thúc). BỎ vuốt (Jean chốt: chống trẻ/tay chạm nhầm).
- **R2d — Nền chờ TV Tầng 0**: Monitor tự vẽ màn chào từ tên bài + tên trường (không upload). Nút "Nền chờ TV" cạnh "Che màn TV". (Tầng 1–2 chọn/upload ảnh = để sau, "sắp có".)
- Nút "khoá màn" chống trẻ nghịch (ghi để sau).
- (Nếu muốn) đổi `openRemote` trên máy cô sang `/remote#k=` cho nhất quán.

### Backlog khác
- **Bug CDN học liệu**: `SRC_NOT_SUPPORTED` / `ERR_ADDRESS_UNREACHABLE` lẻ tẻ từ `learn.demenart.com` (audio vẫn chạy). Con cháu D126–128. Audit `get_signed_media_url` + Bunny. **Chưa cản gì**, tách lát riêng.
- **"Try to fix all" 11 Security issues trong Lovable — CHƯA ĐỘNG, đừng bấm.** Soi thủ công sau.
- Tầng sau: Tín hiệu-lên-TV overlay · Ghi nhận nhanh/Chụp/Quay (= sprint Nhật ký/Record, đụng moments + consent + upload video D119).
- Backlog cũ v46: Media Library thêm tier · policy drift mig057 · lưu repo backup mig 060–066 (D90) · 3-tier privacy moments · parent portal design.

---

## 7. Boot phiên sau
1. Đọc HANDOFF v47 → `DMA_00_START_HERE.md` → `DMA_RULES.md`.
2. Audit live DB trước khi viết SQL/UI (D1).
3. Nếu làm R2c: đọc lại 2 mockup đã chốt trong lịch sử chat + `remote.tsx` (bản R2b) làm nền — bọc UI Pro lên, KHÔNG viết lại logic điều khiển.
4. `admin_modules` registry: kiểm xem route `/remote` công khai có cần ghi nhận không (D106).
