# DMA_HANDOFF_v48.md
**Phiên:** v48 · **Ngày:** 02/07/2026 15:49 GMT+7 (Asia/Ho_Chi_Minh)
**Chủ đề phiên:** Remote v2 — **R2c UI Pro 2-layout XONG & ship production** + preview Phần kế + **PIN 6→4 số (mig 072)** + banner lỗi tự-tắt + auto-recover + tách thông báo entitlement + **quy ước auto-publish**. Chẩn đoán lỗi TV `DECODE` = giới hạn môi trường (không phải bug).

---

## 0. TL;DR đọc trước
- **R2c (UI Pro) HOÀN TẤT, đã publish production.** Remote công khai `demenart.com/remote` giờ là bản Pro: **2 layout theo tay** (dọc **Gọn** ↔ ngang **Full**) + **nút Ghim** (khoá hướng), volume/mute/loop **thật**, seek, blackout, part-nav, **thẻ "PHẦN KẾ"** (preview Phần sau, chỉ hiển thị — không bấm), carve nút "sắp có", nút đỏ **Thoát điều khiển** (≠ Kết thúc buổi). Nghiệm thu thật trên điện thoại ĐẠT.
- **PIN đổi 6 ký tự → 4 chữ số** (mig 072). Bàn phím số trên điện thoại. Unique index thu hẹp **chỉ trong buổi còn sống** để không cạn kho 10.000 mã.
- **Lỗi TV `DECODE`/`SRC_NOT_SUPPORTED`**: đã chẩn xong = **giới hạn môi trường máy chiếu** (Chrome ↔ CoreAudio/HDMI/thiết bị âm ảo trên Mac), **KHÔNG phải bug DMA**. File phát êm trên loa laptop, chỉ chết khi xuất âm ra HDMI (dây lẫn không dây). **Chốt lớp học: âm qua loa laptop/Bluetooth, TV chỉ hình.**
- **PHÁT HIỆN CÒN TREO (R2e):** trang **Tiết học (laptop) KHÔNG đồng bộ** với Remote/Màn chiếu — nó có player CỤC BỘ riêng, không nối kênh. Cần lát riêng để hợp nhất (xem §6).

---

## 1. Trạng thái DB (audit live cuối phiên — D90)
- **53 bảng · 74 SECURITY DEFINER · migrations 001→072 · 7 Edge Functions (KHÔNG đổi phiên này) · admin_modules 58 · 3 tenants**
- Số hàm definer **giữ 74** (mig 072 = `CREATE OR REPLACE` hàm `mint_session_remote_code` sẵn có, không thêm hàm mới).

### Migration 072 (MỚI phiên này) — đã apply live, VERIFY pass
Đổi `remote_code` 6 ký tự chữ-số → **4 CHỮ SỐ** + thu phạm vi unique:
- **`mint_session_remote_code(uuid)`** REPLACE: alphabet `0123456789`, độ dài `1..4`, chống trùng **CHỈ trong buổi sống** (`scheduled·prep_ready·makeup·in_progress`), chốt chặn 50 lần thử (`code_pool_exhausted`). Logic get-or-create + audit + gate quyền **giữ nguyên**.
- **Index** `lesson_sessions_remote_code_uidx` DROP→CREATE **partial mới**: `WHERE remote_code IS NOT NULL AND state IN (scheduled/prep_ready/makeup/in_progress)` → buổi chết **trả mã về kho** (chống cạn 10.000 mã).
- **`redeem_session_remote_code`** KHÔNG đổi (đã lọc buổi sống + `len ≥ 4` + khớp chuỗi; uppercase vô hại với chữ số).
- Re-harden grants sau CREATE OR REPLACE (D15): `mint → [authenticated]` (không anon/public). VERIFY: `4_digits_OK` · index predicate scoped-live · grants authenticated-only. ✅
- **Data:** reset buổi demo `a0001` (`remote_code=null, remote_channel_key=null, remote_code_rotated_at=null`) để lần mint kế sinh 4 số mới. Đã test thật → ra mã 4 số, điều khiển được.

---

## 2. Sprint đã hoàn thành phiên này — R2c UI Pro + tinh chỉnh

### R2c — UI Pro 2-layout (remote.tsx viết lại) ✅ ship production
- **Tông tối premium** (BG #0C100E, CARD #161C18, GREEN #3FBF6E, FOREST #149A76, HONEY #EFA63A, RED #E5675C).
- **Dọc = Gọn** (context + toggle "Lời cô" + cụm nút to ở đáy tầm ngón cái) ↔ **Ngang = Full** (2 cột: trái = monitor-bỏ-túi script/câu-hỏi/học-liệu/Các-Phần, phải = cụm điều khiển).
- **Theo tay** (matchMedia orientation) + nút **Ghim** (khoá layout, hiện "Ghim Gọn"/"Ghim Full"). **BỎ vuốt** (chống chạm nhầm — Jean chốt).
- **Volume/Mute/Loop THẬT** (đụng engine Monitor): thêm `volume(0..1)/muted/loop` vào `ClassroomState` + `DEFAULT_STATE` (hook **v4**) với default backward-compatible (publishState merge patch — remote cũ không vỡ). Monitor áp `el.volume/muted/loop` qua 1 effect idempotent (deps `[volume,muted,loop,loaded]`).
- **Thẻ "PHẦN KẾ · n/N — <tên>"** + mục tiêu + số học liệu — **thẻ thông tin, KHÔNG bấm** (tránh nhảy Phần nhầm). Hiện luôn ở Gọn (dưới "Lời cô") và cột trái Full. Ẩn ở Phần cuối.
- Carve nút "sắp có" (Tín hiệu TV/Ghi nhận/Chụp/Quay — không nối engine). Nút đỏ duy nhất = **Thoát điều khiển** (không có "Kết thúc buổi" trên remote anon).

### PIN 4 số ✅
- `remote.tsx` ô nhập: `maxLength=4`, `inputMode="numeric"`, `pattern="[0-9]*"`, chặn ký-tự-chữ (`replace(/\D/g,'')`), nhãn "Mã 4 số". Panel `$id.tsx` KHÔNG cần đổi (chỉ hiển thị mã mint trả về).

### Banner lỗi tự-tắt + auto-recover ✅ (đụng engine — có báo trước)
- `classroom.tsx`: `<video>`+`<audio>` thêm **`onCanPlay → setLoadErr(null)`** → lỗi thoáng qua (CDN chập chờn) rồi phát được thì banner tự biến mất.
- Thêm **`onMediaError`**: khi lỗi (DECODE/SRC) → `el.load()` lại **1 lần/1 media** (`recoverRef` guard) để ép Chrome re-init pipeline giải mã theo thiết bị xuất mới. KHÔNG đụng logic play/pause/seek/volume.

### Tách thông báo entitlement ✅
- `mapMediaReason` (cả `classroom.tsx` + `$id.tsx`) tách:
  - `not_school_member` → **"Tài khoản này không thuộc trường nào — đăng nhập bằng tài khoản giáo viên của trường."**
  - `no_active_entitlement` → giữ **"Trường chưa kích hoạt môn học này."**

### Quy ước AUTO-PUBLISH (chốt với Jean, đã ghi memory) ✅
- Sửa code + **build pass** → Claude **tự publish thẳng production**, chỉ báo kết quả, KHÔNG chờ phê duyệt từng lần.
- **Chỉ DỪNG hỏi trước** khi: (1) build/TS fail; (2) đụng schema/dữ liệu Supabase (migration, xoá/sửa data — vẫn viết SQL+VERIFY); (3) đổi thứ có thể phá buổi đang chạy (engine phát, auth, RLS).

---

## 3. File đã đụng phiên này (commit chính)
- `supabase` migration **072** (apply_migration `072_remote_code_4digits_live_scoped`) + reset data buổi demo.
- `src/hooks/useSessionChannel.ts` — **v4** (+volume/muted/loop). commit `c74ea14`.
- `src/routes/_authenticated/teacher.classroom.tsx` — áp volume/loop (`4225124`) · banner onCanPlay + auto-recover onMediaError (`0ba9ade`,`d045fa3`) · tách thông báo (`cbb3ecb`).
- `src/routes/remote.tsx` — R2c viết lại (`f9cf37c`) · thẻ PHẦN KẾ (`42c446f`) · PIN 4 số (`fc1389f`).
- `src/routes/_authenticated/teacher.session.$id.tsx` — tách thông báo (`cbb3ecb`).
- **Bản làm việc local** 3 file R2c ở `/mnt/user-data/outputs/` (khớp bản deploy): `remote.tsx`, `teacher.classroom.tsx`, `useSessionChannel.ts`.

---

## 4. CHẨN ĐOÁN LỖI TV (chốt — để phiên sau khỏi đào lại)
**Triệu chứng:** phát media ra TV qua HDMI (dây lẫn không dây) → Chrome báo `DECODE` / `SRC_NOT_SUPPORTED`, không phát. Đổi output âm về **loa laptop → phát êm**. Cả **audio (mp3, Phần 4) lẫn video (mp4, Phần 5)** đều chết trên đường HDMI.
**Kết luận:** file & app **KHÔNG lỗi** (app dùng `<audio>/<video>` chuẩn; laptop giải mã đúng; verdict entitlement `allowed`). Yếu tố chung = **đường âm HDMI trên máy Mac này** — nghi **thiết bị âm ảo** (Microsoft Teams Audio / EPSON Projector MPP Audio) chen vào chuỗi CoreAudio của Chrome. Đổi 48kHz/16-bit trong Audio MIDI Setup không cứu. → **Giới hạn môi trường trình chiếu, không phải bug DMA.**
**Chốt vận hành lớp:** **HDMI ra TV cho HÌNH · âm qua loa laptop/Bluetooth.** (Cửa sổ Monitor nằm trên laptop nên để output = loa laptop là Monitor phát tiếng qua loa laptop, TV chỉ hình — khớp mô hình "laptop = tiếng, TV = hình" Jean chọn.)
*(Muốn truy tiếp sau: thoát hẳn Teams + phần mềm EPSON rồi test lại; hoặc test Safari để tách biến Chrome. Không gấp.)*

---

## 5. Nghiệm thu / bài học phiên này (→ D134–D138, xem RULES)
- **Áp code qua connector byte-exact** (code--write/line_replace + build pass + read-back) chạy trơn nhiều lần — D134.
- 4 số = 10k tổ hợp: phải scope unique theo buổi sống, không thì cạn kho — D135.
- Banner lỗi phải tự tắt khi canPlay; auto-recover load() — D136.
- DECODE-on-TV = môi trường, không phải app — D137.
- Thông báo entitlement phải tách not_school_member ≠ no_active_entitlement; **vào nhầm `info@demenart.com` (school=null) sẽ bị chặn học liệu ĐÚNG luật** → test học liệu bằng tài khoản GV thật — D138.

---

## 6. VIỆC TREO (phiên sau vào thẳng)
### 🔴 R2e — ĐỒNG BỘ TRANG TIẾT HỌC ↔ KÊNH (ưu tiên — Jean yêu cầu)
Trang `teacher.session.$id.tsx` (StepTeach) có **player cục bộ riêng**, KHÔNG dùng `useSessionChannel` → điều khiển trên laptop **không** đẩy sang Màn chiếu/Remote (ảnh: laptop Phần 4, TV Phần 1 "Chờ Remote"). **Mô hình đã chốt với Jean:** nối trang tiết học vào **cùng kênh** làm bộ điều khiển (đẩy part/media/play/seek) → Màn chiếu + Remote + trang tiết học khớp 2 chiều; **Màn chiếu = màn phát duy nhất** (tiếng ra loa laptop, hình ra TV); trang tiết học **thôi tự phát tiếng** (thành preview + điều khiển) để hết đúp tiếng. Là sửa **engine + kiến trúc đồng bộ** → làm cẩn thận, đọc file thật, test kỹ (đừng edit mù cuối phiên).

### Remote v2 — tầng trên còn lại
- **R2d — Nền chờ TV Tầng 0**: Monitor tự vẽ màn chào từ tên bài + trường (không upload). Nút "Nền chờ TV" cạnh "Che màn TV". (Tầng 1–2 upload ảnh = sau.)
- Nút "khoá màn" chống trẻ nghịch.
- TV Signal overlay · Ghi nhận/Chụp/Quay (= sprint Nhật ký/Record).

### Backlog khác
- **Bug CDN học liệu** `SRC_NOT_SUPPORTED` lẻ tẻ `learn.demenart.com` (audio vẫn chạy) — D126–128. Giờ **hạ ưu tiên** (đã rõ không phải nguyên nhân lỗi TV). Audit `get_signed_media_url` + Bunny khi rảnh.
- (Nếu muốn chặt hơn) rate-limit cho `redeem` (4 số = 10k, anon) — nhưng Remote chỉ điều khiển phát, không PII (D129), mã chết theo buổi.
- **"Try to fix all" 11 Security issues Lovable — CHƯA ĐỘNG, đừng bấm.**
- LÁT 1b-ii upload video TUS (D119) · LÁT 1c My Drive · LÁT 2 quota · 3B Nhật ký.
- Lưu repo backup mig 060–072 (D90) · policy drift mig057 · 3-tier privacy moments · parent portal design.
- **Registry D106:** route `/remote` công khai — kiểm có cần ghi `admin_modules` không.

---

## 7. Boot phiên sau
1. Đọc HANDOFF v48 → `DMA_00_START_HERE.md` → `DMA_RULES.md`.
2. Audit live DB trước khi viết SQL/UI (D1).
3. **Nếu làm R2e (đồng bộ trang tiết học):** đọc `useSessionChannel.ts` (v4) + `teacher.session.$id.tsx` (StepTeach) + `teacher.classroom.tsx` THẬT. Nối StepTeach vào kênh làm controller; Monitor giữ vai màn-phát-duy-nhất; StepTeach mute local. Test 2 chiều (laptop↔Remote↔TV) kỹ trước khi ship.
4. Áp code qua connector: byte-exact, build pass, read-back verify (D134). Publish theo quy ước auto-publish (dừng khi build-fail/schema-data/live-breaking).
