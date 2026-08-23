# DMA_HANDOFF_v50.md
**Phiên:** v50 · **Ngày:** 04/07/2026 08:25 GMT+7 (Asia/Ho_Chi_Minh)
**Chủ đề phiên:** **ORG CLOUD (O1–O5) + HỌC LIỆU CÔ THÊM: Phần(0) Nền mở đầu + slideshow, "Học liệu bổ trợ" chiếu-chèn (một-slot), video GV (MP4 ≤100MB), Remote carousel LP-style, đồng bộ guide, mở khoá autoplay.** Nghiệm thu thật laptop + iPhone. Rất nhiều tính năng + nhiều vòng fix engine phát.

---

## 0. TL;DR đọc trước
- **XONG + nghiệm thu thật** (Jean: "đã chạy đúng theo test"). Toàn bộ đường "học liệu cô thêm cho buổi" + Phần(0) nền + aux chiếu-chèn + video GV + Remote carousel đã chạy trên laptop (Mac Chrome) và iPhone.
- **session_media có `kind`** ('background' | 'supplement', default 'supplement'). **(0) Nền mở đầu** = `background` → thành **"Phần 0" (`_intro`)** tự chiếu khi đón lớp. **Học liệu bổ trợ** = `supplement` → **KHÔNG phải một phần**; là palette "chiếu chèn" ở mọi phần. **Hai thứ KHÁC nhau** (Jean bắt lỗi gộp — D147).
- **aux "chiếu chèn" = MỘT slot phát duy nhất:** bấm → `auxMediaId` → media hiệu lực = aux, **giữ nguyên "Phần x/N"**; đổi element (key=url) → nguồn cũ tự dừng, **không đụp**; "Về bài dạy" clear; đổi phần **auto-clear aux** (D148).
- **Video GV = MP4 thẳng** (zone `dma-private`, signed URL ngắn hạn), trần **100MB** trong config `SESSION_VIDEO_MAX` (upload_media v11). Bunny Stream để dành curriculum Dế Mèn (D149).
- **Slideshow Phần(0):** ảnh `SLIDE_MS=5000` (5s) / video **muted autoplay hết-file** / lặp; **CHỈ ở Phần 0** (khu trú → buổi không nền chạy y nguyên); **rời Phần 0 = dừng**; toggle "Tạm dừng/Bật tự chạy nền" trên Remote + laptop (D150).
- **Fix quan trọng (nhiều vòng):** (1) **guideRev** — Monitor phải nạp lại guide khi media-buổi đổi, nếu không lệch index (bấm (0) ra (1)) — D151. (2) **shown gate** — tránh `<video src=ảnh>` khi loop slideshow → SRC_NOT_SUPPORTED — D152. (3) **autoplay cần cử chỉ** — play() tiếng bị chặn khi điều khiển từ xa (rõ nhất Incognito) → lớp phủ **"Chạm để bật tiếng"** — D153. (4) **fade chặn phá play** — đã bỏ `await fadeVol` — D154.
- **DB: 53 bảng · 77 hàm SECURITY DEFINER · `session_media` +`kind`+`sort_order` · 9 Edge Functions · migrations (đánh số nội bộ) 073→078 phiên Org Cloud.**
- **Quy trình Lovable:** mặc định PASTE tiết kiệm credit; "tự áp"/"auto áp" → agent. Phiên này chủ yếu **auto áp** (Jean ra ngoài) + vài đoạn paste khi Lovable API chập chờn (D156).

---

## 1. Trạng thái DB (audit live — D1/D90)
- **53 bảng · 77 SECURITY DEFINER · 9 Edge Functions · 3 tenants.** (v49 = 74 definer → +3 net phiên Org Cloud.)
- **`session_media`** (audit thật): `id, session_id, media_id, source, added_by, created_at, sort_order (int default 0), kind (text default 'supplement')`. `sort_order` đếm **riêng theo từng kind** (background/supplement).
- **RPC mới/đụng phiên Org Cloud (secdef, verify hiện diện):**
  - `get_school_storage_usage(p_school_id)` — dung lượng đã dùng / hạn mức trường.
  - `check_session_media_upload_access(p_session_id, p_viewer_profile)` — gate GV-của-buổi **theo profile** (vì Edge = service_role, không có auth.uid — D146).
  - `get_school_media_library(p_school_id, p_scope)` — kho media trường (scope 'school' cần master/super; else 'mine').
  - `get_lesson_guide(p_session_id)` — **REPLACE thêm-only** (khối phần-thật byte-giống hệt bản cũ → buổi thật KHÔNG đổi); nay build **`_intro`** (Phần 0) TỪ session_media `kind='background'` + trả thêm mảng **`aux`** = session_media `kind='supplement'`.
  - `mint_session_remote_code` / `redeem_session_remote_code` — remote PIN (nguyên).
- **KHÔNG có data reseed** phiên này. (Phần 4 "Chú Vịt Con" chuẩn vẫn treo từ v49.)

---

## 2. Sprint hoàn thành phiên này

### 2.1 Org Cloud O1–O5 (migrations 073–078)
- **073 (O1):** `session_media` +`sort_order` +DELETE policy; RPC `get_school_storage_usage`.
- **074 (O2 gate):** `check_session_media_upload_access` (secdef, gate theo profile — D146). Grant authenticated+service_role.
- **075 (O3):** `get_school_media_library` (kho trường; scope theo vai).
- **076→078 (O5/aux):** `get_lesson_guide` REPLACE thêm-only — Phần(0) `_intro` từ background + mảng `aux` từ supplement. Re-GRANT sau mỗi replace (D15).
- **077 (B1):** `session_media` +`kind` text default 'supplement' CHECK in (background, supplement).

### 2.2 Edge Functions (9 tổng)
- **`upload_media` v11:** nhánh media-buổi (session_id) nhận **ảnh (10MB) + video mp4/webm/mov/x-m4v (100MB = `SESSION_VIDEO_MAX`)** + đọc form `kind` (background/supplement) + `sort_order` đếm theo kind. **Nhánh ảnh trẻ (dma-private) + curriculum (dma-learning) GIỮ NGUYÊN byte** (D149). `videoExt()` helper.
- **`get_signed_media_url` v18:** nhánh `private_school_resource` (gate `prof.school_id === media.linked_school_id`) → ký dma-private, is_stream=false.
- **`delete_session_media` v1:** gate GV-của-buổi → xoá junction → nếu media mồ côi (0 junction) xoá file Bunny + state='deleted'.
- **`school_media_admin` v1:** gate master/super → 'delete' (chỉ khi used_count=0) | 'purge' (quét state='deleted' mồ côi, xoá file Bunny).

### 2.3 Học liệu cô thêm — Phần(0) + aux + video (frontend)
- **`SessionResourcePanel.tsx`** — 2 khu: **"Nền mở đầu"** (kind=background) / **"Học liệu bổ trợ"** (kind=supplement); mỗi khu nút upload riêng gửi đúng `kind`, nhận ảnh+video; preview video có badge "Video"; xoá qua `delete_session_media`; đọc danh sách qua `get_lesson_guide` (bg=_intro.media, sup=aux); quota bar; `onChanged` callback.
- **`teacher.session.$id.tsx` (StepTeach/laptop):** đánh số (0)/1–N; chip (0) disable khi chưa có nền; palette aux + "Về bài dạy"; `reloadGuide(resetIndex)` (fix bug ảnh cũ đọng); nút **toggle nền** (bgPlay) khi ở Phần 0; đổi phần/media → `auxMediaId:null` + bump **`guideRev`** khi media-buổi đổi.
- **`teacher.classroom.tsx` (Màn chiếu):** media hiệu lực = aux > slideshow(Phần 0) > media phần; **slideshow** (ảnh 5s / video muted hết-file / lặp, chỉ Phần 0); **`shown` gate** (D152); **lớp phủ "Chạm để bật tiếng"** khi play bị chặn (D153); reload guide theo `guideRev` (D151); banner lỗi `mediaError` đẩy về Remote.
- **`school.drive.tsx` + nav "Kho của trường"** (O3): master xem media trường, quota bar, xoá chưa dùng, "Dọn rác kho" (purge).

### 2.4 Remote carousel LP-style (`remote.tsx`)
- Layout **Gọn** = **carousel "trang phần"** kiểu app đặt lịch LP: card giữa to+viền nổi, **hé mép** trước/sau, **snap giữa**, **cuộn dọc trong card**, chạm card → chiếu phần + snap về giữa; badge "● ĐANG CHIẾU". Gộp bỏ "Phần kế"/"Lướt chọn phần" cũ (D155).
- Layout **Full (ngang)** giữ 2 cột; nút **Ghim**.
- Palette **"Học liệu bổ sung"** + "Về bài dạy"; tên rút gọn giữa (`midEllipsis`) + icon loại; **toggle nền** trên card Phần 0; **banner lỗi** `mediaError` dưới thanh trạng thái.
- **Đánh số (0)/1–N** khớp giáo án.

### 2.5 Hook (`useSessionChannel.ts`) — field mới (thêm-có-default, tương thích ngược)
- `ClassroomState`: **`auxMediaId`** (aux chiếu-chèn), **`bgPlay`** (toggle slideshow, default true), **`guideRev`** (bump → Monitor reload guide).
- `MonitorStatus`: **`mediaError`** (Monitor báo lỗi → Remote banner).
- Message kênh thêm `aux` (Monitor→Remote danh sách học liệu bổ sung).

---

## 3. Loạt fix engine phát (thứ tự thời gian — quan trọng cho phiên sau)
1. **Bug lệch index (0)/(1):** Monitor nạp guide 1 lần lúc mở → thêm nền sau đó không reload → Monitor/Remote giữ guide cũ, bấm (0) ra (1). **Fix: `guideRev`** — StepTeach bump khi media-buổi đổi → Monitor reload guide + publish (D151).
2. **Video nền loop → SRC_NOT_SUPPORTED rồi đóng:** khe ký URL, `isVideo` đổi ngay nhưng `loaded` async → render `<video src=URL-ảnh>`. **Fix: `shown`** = chỉ render khi `loaded.mediaId === effMediaId` (D152).
3. **Toggle nền: pause OK, bấm lại không phát (video):** `autoPlay` chỉ chạy lúc mount. **Fix:** effect gọi `el.play()` thủ công khi bgPlaying bật lại.
4. **Qua phần audio/video bấm Play không phát:** `await fadeVol` 400ms chặn `setLoaded` → play bấm trong khe rơi vào element cũ đang fade→im, element mới im. **Fix: BỎ fade chặn** (D154). Crossfade mượt để làm lại sau bằng 2-element.
5. **Vẫn không phát khi điều khiển từ xa (chưa chạm Màn chiếu):** chính sách **autoplay** — play() tiếng cần **cử chỉ trực tiếp trên tab Monitor**; điều khiển từ xa bị chặn (`NotAllowedError`), rõ nhất **Incognito** (không tích luỹ Media Engagement Index). **Fix: lớp phủ "Chạm để bật tiếng trên TV"** — cô chạm 1 lần → mở khoá cả buổi (D153, nối D143).

---

## 4. File đã đụng phiên này (tất cả BUILD PASS)
**Frontend:**
- `src/hooks/useSessionChannel.ts` — +`auxMediaId`, +`bgPlay`, +`guideRev`, +`mediaError`, +message `aux`.
- `src/routes/_authenticated/teacher.classroom.tsx` — aux/slideshow/shown/lớp-phủ/guideRev/mediaError.
- `src/routes/_authenticated/teacher.session.$id.tsx` — đánh số 0/1–N, palette aux, reloadGuide, toggle nền, bump guideRev.
- `src/routes/remote.tsx` — **(BẢN ĐANG DÙNG /remote)** carousel LP-style + palette aux + toggle nền + banner lỗi + đánh số.
- `src/components/SessionResourcePanel.tsx` — 2 khu upload (background/supplement), ảnh+video, preview video badge.
- `src/routes/_authenticated/school.drive.tsx` + `school.tsx` (nav "Kho của trường") — O3.

**Edge (Supabase):** `upload_media` v11 · `get_signed_media_url` v18 · `delete_session_media` v1 · `school_media_admin` v1.
**Migrations:** 073–078 (đánh số nội bộ; áp qua execute_sql, VERIFY pass).

> ⚠️ Còn 1 dòng `console.error("[classroom] play() rejected", err)` trong catch của command effect (vô hại, để soi lỗi phát). Gỡ hay giữ tuỳ Jean.

---

## 5. VIỆC TREO (phiên sau)
### 🟡 Polish đã hứa
- **Fade mượt khi đổi nguồn** — làm lại đúng bằng **crossfade 2-element** (KHÔNG chặn setLoaded); giảm **chớp đen ~0.2s** ở khe ký URL slideshow bằng **preload URL kế** (D154).
- **Nút toggle nền trên laptop (việc B)** — đã đưa paste; xác nhận Jean đã dán chưa (nếu chưa, chèn khối `actIsIntro` trước comment "học liệu trong phần" trong StepTeach).

### 🟡 Remote — tính năng còn thiếu
- **4 ô "sắp có"**: Tín hiệu TV · Ghi nhận · Chụp · Quay (từ xa) — sprint Nhật ký/Record.
- **prev/next giữa các aux** (giờ phải bấm từng chip).

### 🟡 Kho/rác
- **Dọn 7 file Bunny rác cũ** (state='deleted', quota=0 nhưng file Bunny chưa xoá) qua nút **"Dọn rác kho"** (O3 purge) — Jean/master bấm.

### Treo cũ (từ v49)
- **Upload "Chú Vịt Con" chuẩn** → trỏ `lesson_activity_media` Phần 4 (move/present, `ac0a5c13`) về media_id đúng (đang tạm "Tiếng Mưa" `34ad7ff4`).
- **Dọn `teacher.remote.tsx`** (bản cũ không dùng — D142).
- **"Try to fix all" 11 Security issues Lovable — CHƯA ĐỘNG, đừng bấm** (D5/D14).
- Admin portal interior design pass · registry D106 kiểm route `/remote` + `/school/drive` (school.drive) có cần ghi `admin_modules`.
- Lưu repo backup migrations 060–078 (D90) · drift mig057 · 3-tier privacy moments · parent portal design.
- `/kid` portal V2 (khoá cửa, namespace giữ).

---

## 6. Boot phiên sau
1. Đọc **HANDOFF v50** → `DMA_00_START_HERE.md` → `DMA_RULES.md`.
2. **Audit live DB** trước khi viết SQL/UI (D1/D90): kỳ vọng 53 bảng · 77 definer · session_media có kind+sort_order.
3. **Quy trình Lovable:** mặc định code byte-exact cho Jean **paste** (tiết kiệm credit); "tự áp" → agent. Lovable API có lúc lỗi ghi/deploy (read OK) → fallback paste; **Preview URL luôn phản ánh commit mới** để test (D156).
4. **Nhớ 2 file remote (D142):** sửa = `src/routes/remote.tsx`.
5. **Media engine (nhạy):** một nguồn phát (Monitor) · aux một-slot · slideshow khu-trú Phần 0 · `shown` gate · `guideRev` reload · autoplay cần cử chỉ (lớp phủ). Sửa engine → cực cẩn thận, test cả buổi không-nền để không hồi quy.
6. **Deploy (D145):** tab không tự nạp code mới → hard-reload/đóng-mở 3 tab; test Preview.

**Tài khoản test:** GV `gv.linh.kidshouse@demo.demenart.com` / `Test@123` · buổi demo `a0001` (lesson "Tiếng mưa rơi", version `ac0a5c13-…`) · Master `hieutruong.kidshouse@demo.demenart.com` / `Test@123` (để test "Kho của trường").
**Preview:** `https://id-preview--d9d56000-3cf9-4c46-9890-651edc53d73f.lovable.app/`
**IDs:** Supabase `xcvhacymrbhdhohyylyq` · Lovable `d9d56000-3cf9-4c46-9890-651edc53d73f` · buổi demo `aaaa0000-0000-4000-8000-0000000a0001` · trường KHM `d1000000-0000-4000-8000-000000000001`.

*Nguồn: Tài liệu A–G + tầm nhìn founder + DMWS. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
