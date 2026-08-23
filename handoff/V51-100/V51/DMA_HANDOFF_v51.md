# DMA_HANDOFF_v51.md
**Phiên:** v51 · **Ngày:** 05/07/2026 08:00 GMT+7 (Asia/Ho_Chi_Minh)
**Chủ đề phiên:** **POLISH ENGINE PHÁT + AN TOÀN BUỔI HỌC** — (1) Registry D106 hygiene + `media-vault` description; (2) Preload URL + cross-dissolve ảnh (hết chớp đen nền Phần 0); (3) **Screen-lock chống trẻ chạm**; (4) **FIX VIDEO HLS bằng hls.js** (Bunny Stream không phát được trên Chrome). Nghiệm thu thật + đã publish production.

---

## 0. TL;DR đọc trước
- **Tất cả XONG + đã PUBLISH production** (Jean xác nhận "chạy mượt"). 4 mảng: registry, preload/cross-dissolve, screen-lock, video HLS.
- **VIDEO HLS = FIX LỚN NHẤT PHIÊN:** video curriculum Bunny Stream (`stream_only=true`, HLS `.m3u8`) **không phát được bằng `<video src=.m3u8>` thường trên Chrome/Firefox** (chỉ Safari phát native). → Thêm **`hls.js@1.6.16`**, Màn chiếu gắn nguồn HLS qua hls.js (MediaSource); Safari + MP4 thường dùng `src` native (D157). Token path-based tự phủ segment → an toàn nguyên vẹn, còn *chống tải lậu tốt hơn* mp4 (không lộ URL file).
- **Screen-lock:** field kênh **`locked`** (Remote bật/tắt, default false). Màn chiếu phủ lớp **nuốt-chạm** + huy hiệu "🔒 Màn đang khoá"; **van an toàn giữ-3s tại TV** mở khẩn cấp. Chống chạm *trong web* (KHÔNG chặn Esc/phím vật lý) — D160.
- **Preload + cross-dissolve:** nền Phần 0 trôi ảnh **hết chớp đen** (preload URL slide kế, cache RAM TTL 8'); ảnh mờ chồng nhau (`xfade-in .8s`, chỉ ẢNH). Dọn dead code `fadeVol` (D159).
- **Registry D106:** `teacher-remote` route `/teacher/remote`(chết)→`/remote`; tạo mới `school-drive`; điền `media-vault` description; liên kết 2 chiều media-vault↔school-drive.
- **DB KHÔNG đổi cấu trúc:** vẫn **53 bảng · 77 SECURITY DEFINER · 9 Edge · 3 tenant**. Phiên này chỉ update **data** bảng `admin_modules` (không migration).
- **2 việc treo v50 hoá ra đã xong:** `teacher.remote.tsx` đã xoá khỏi repo từ trước; toggle nền laptop đã có sẵn trong StepTeach.

---

## 1. Trạng thái DB (audit live — D1/D90)
- **53 bảng · 77 SECURITY DEFINER · 9 Edge Functions · 3 tenants** — **không đổi** so với v50 (không migration phiên này).
- **`admin_modules` (registry) — CÓ CẬP NHẬT DATA:**
  - `teacher-remote`: `route` `/teacher/remote`→**`/remote`**; title "Điều khiển trình chiếu (Remote /remote)"; description/usage_note/search_keywords làm mới đúng bản công khai PIN/QR + Realtime Broadcast (bỏ mô tả "BroadcastChannel" cũ).
  - **`school-drive`** (MỚI): route `/school/drive`, group `bee86ee4-…` (🏫 Trường & Lớp), status live, đầy đủ description + usage_note + search_keywords + `related_slugs=['media-vault']`.
  - `media-vault`: **điền `description`** (kho media giáo trình admin, khác school-drive); `related_slugs` +`school-drive` (đối xứng 2 chiều — KỶ LUẬT VÀNG §6).
  - *Còn 51 module khác trống `description` — GẦN HẾT là roadmap/chưa build (`kid-*`, `submit-journal`, `video-recap`…). Trống là bình thường; KHÔNG điền hàng loạt (đoán mò). Nếu cần: audit tách live-vs-planned rồi chỉ backfill module đang chạy.*
- **Video demo "Bay Vào Vũ Trụ"** `5e72a438-cac6-43e9-94ec-4021adc44b35`: `access_level=private_curriculum`, `stream_only=true`, `cdn_pull_zone=dma-stream`, `bunny_stream_video_id=552a5c42-…`, `watermark_required=true`, `download_allowed=false`, `expires_policy_minutes=15`. Gate qua RPC `check_curriculum_media_access` (trả `cdn_pull_zone='dma-stream'` → Edge vào nhánh stream, `is_stream=true`, ký cả `playback_url`(.m3u8) + `mp4_fallback`).

---

## 2. Sprint hoàn thành phiên này (tất cả BUILD PASS + PUBLISHED)

### 2.1 Registry D106 + media-vault (Supabase execute_sql, kênh riêng)
Sửa `teacher-remote` route chết; tạo `school-drive`; điền `media-vault` description; đối xứng 2 chiều. Verify: không còn module LIVE nào trống description.

### 2.2 Preload + cross-dissolve ảnh (`teacher.classroom.tsx`)
- **`urlCacheRef`** (Map media_id→{url,watermark,at}, TTL `URL_TTL_MS=8'`): effect ký URL **ưu tiên cache** (hit→dùng ngay, hết khe ký URL→hết chớp đen); miss→ký+lưu cache.
- **Effect preload:** ở nền Phần 0 (`slideshowOn && bgPlaying`) ký trước URL **slide kế** `introSlides[(bgIdx+1)%n]` → cache.
- **Cross-dissolve ảnh:** state `imgLayers` (tối đa 2 lớp), render 2 `<img absolute inset-0>` với `animation: xfade-in .8s` (Jean chỉnh từ .4s→.8s cho chậm đẹp hơn). **Chỉ ẢNH** (không tiếng để đụp); video/audio giữ một-slot key=url.
- **Dọn dead code:** bỏ hàm `fadeVol` (D154), comment cũ, `console.error("play() rejected")`.
- `onMediaError` xoá cache media lỗi để ký lại.

### 2.3 Screen-lock chống trẻ chạm (3 file)
- **`useSessionChannel.ts`:** `ClassroomState` +`locked: boolean`; `DEFAULT_STATE` +`locked:false` (additive-default, client cũ không vỡ).
- **`remote.tsx`:** import `Lock,Unlock`; `toggleLock()`=`publishState({locked:!state.locked})`; nút 🔒 "Khoá màn / Đã khoá" ở StatusBar (luôn thấy).
- **`teacher.classroom.tsx`:** state `unlockedAtTV` + re-arm effect (locked→true reset false); `lockPressRef` giữ-3s; khi `state.locked && !unlockedAtTV` → phủ `<div absolute inset-0 z-30>` nuốt onClick/onContextMenu/onPointer + huy hiệu "🔒 Màn đang khoá · giữ 3 giây để mở"; needTap bump **z-20→z-40** (trên lớp khoá).
- **Giới hạn:** chống chạm trong web; KHÔNG chặn Esc/bàn phím/nút vật lý TV (nói rõ với Jean).

### 2.4 FIX VIDEO HLS bằng hls.js (`teacher.classroom.tsx` + package.json) ⭐
- **Gốc lỗi:** Màn chiếu dùng `<video src=.m3u8>` → Chrome/Firefox báo `SRC_NOT_SUPPORTED` (chỉ Safari phát HLS native). Đây là **lỗ hổng CÓ SẴN**, không do polish phiên này.
- **Vòng 1 (BỎ):** thử `mp4_fallback` (play_720p.mp4) theo `canPlayType` — KHÔNG ăn (canPlayType Chrome có thể trả "maybe"; rendition mp4 tuỳ chọn). Audit log xác nhận Edge trả `hls_stream` đúng → vấn đề ở client.
- **Vòng 2 (ĐÚNG):** thêm **`hls.js@1.6.16`**; `pickPlayUrl` trả `signed_url` (=.m3u8); bỏ `src={shown.url}` khỏi `<video>`; **effect gắn nguồn:** url `.m3u8` + không native HLS + `Hls.isSupported()` → `new Hls();loadSource;attachMedia`; else `el.src=url` (MP4/Safari). `Hls.Events.ERROR` fatal → `onMediaError`. Cleanup `hls.destroy()`.
- **An toàn:** không đụng gate/ký/token/audit/watermark (đều ở Edge+RPC). HLS còn *chống tải lậu tốt hơn* (segment qua MediaSource blob, không lộ URL file). Token path-based phủ segment (kiến trúc đã chốt) → chạy được = mọi segment qua cửa token OK.

---

## 3. Học được — thêm D-rules (D157–D160) → GHI VÀO DMA_RULES.md
- **D157 — HLS phải dùng hls.js:** video Bunny Stream (`stream_only`, `.m3u8`) KHÔNG phát bằng `<video src>` thường trên Chrome/Firefox; chỉ Safari/iOS native. Dùng **hls.js** (attach MediaSource) cho non-Safari. `mp4_fallback` KHÔNG đáng tin (canPlayType "maybe" + rendition tuỳ chọn). Token path-based tự kế thừa xuống variant playlist + segment.
- **D158 — Chẩn lỗi phát, đừng đoán:** `SRC_NOT_SUPPORTED` (media code 4) = nhận nguồn nhưng không giải mã (định dạng/HLS) ≠ NETWORK (code 2) = 404/403/token. Phân biệt để sửa đúng. Soi Edge/RPC bằng `get_edge_function` + `pg_get_functiondef` + `audit_logs.metadata->>'kind_delivery'` thay vì đoán URL.
- **D159 — Preload cache & cross-dissolve:** cache signed URL trong RAM (không localStorage), **TTL < `expires_policy_minutes`** (8' < 10–15') để không dùng URL chết. Cross-dissolve chỉ áp ẢNH (không tiếng để đụp); video/audio giữ một-slot key=url.
- **D160 — Screen-lock:** field kênh mới luôn **additive-default** (`locked:false`) để client cũ không vỡ. Lớp nuốt-chạm z-30 < needTap z-40; van an toàn local (`unlockedAtTV`, giữ-3s, re-arm khi locked→true). Chống chạm chỉ trong web, KHÔNG chặn Esc/phím vật lý.

**Vận hành (không đánh số D, nhưng nhớ):**
- **Supabase MCP có thể rớt quyền giữa phiên** (`-32600 permission denied` cả `SELECT 1`) → reconnect connector; đôi khi phải **gỡ-thêm lại** hoặc chờ OAuth refresh. Reload tool (tool_search) không tự sửa.
- **routeTree.gen.ts churn:** agent build đôi khi regenerate file route, bỏ khối `declare module '@tanstack/react-start'` Register — typecheck vẫn pass, runtime SSR OK (khối tự mọc lại khi dev local). **Luôn `get_diff` sau mỗi agent apply** để bắt churn ngoài ý muốn.
- **Auto-áp đường phát video/engine:** áp vào repo/Preview qua agent OK, nhưng **KHÔNG auto-publish** — để Jean test Preview (Chrome+Safari+iPhone) rồi tự Publish.

---

## 4. File đã đụng phiên này
**Frontend (Lovable, auto-áp qua agent — Jean cho phép "auto áp"):**
- `src/routes/_authenticated/teacher.classroom.tsx` — preload cache + cross-dissolve ảnh + dọn fadeVol + screen-lock overlay + **hls.js video source attach**.
- `src/routes/remote.tsx` — nút 🔒 Khoá màn + `toggleLock`.
- `src/hooks/useSessionChannel.ts` — +`locked` field.
- `package.json` — +`hls.js@1.6.16`.

**Supabase (execute_sql, kênh riêng không tốn credit Lovable):**
- `admin_modules` — teacher-remote route fix, school-drive INSERT, media-vault description, đối xứng related_slugs.

**KHÔNG có migration, KHÔNG đụng Edge Functions phiên này.**

> Diff mọi agent-apply đã `get_diff` verify sạch (chỉ đúng file/edit định làm). Một lần EDIT screen-lock có churn `routeTree.gen.ts` (vô hại, đã báo Jean).

---

## 5. VIỆC TREO (phiên sau)

### 🟢 Sẵn sàng làm ngay (frontend, đã bàn)
- **Tín hiệu TV** — nút "Tín hiệu TV" ("sắp có" trên Remote). Hướng đã đề xuất: **cue quản lớp** bắn lên Màn chiếu (👀 Nhìn lên cô · 👏 Vỗ tay · 🤫 Trật tự · 🔔 Nghe cô). Thêm 1 field kênh + lớp phủ Màn chiếu. **Chờ Jean chốt nội dung cue.**
- **prev/next giữa các aux** (giờ bấm từng chip).

### 🟡 Cần anh tự tay
- **Dọn rác Bunny (15 file** state='deleted' mồ côi**)** — nút "Dọn rác kho" trong `/school/drive` (O3 purge). Xoá vĩnh viễn.

### 🟡 Sprint lớn (chờ Supabase + thời gian)
- **Journal sprint** — Ghi nhận / Chụp / Quay (3 ô "sắp có" còn lại): cần bảng + storage + Edge.
- **`/kid` portal V2** (PIN-based, ba mẹ duyệt; namespace đã giữ).

### 🟡 Nhỏ / dọn dẹp
- **51 module registry trống description** — gần hết roadmap; nếu làm, chỉ backfill module LIVE.
- Admin portal interior design pass.

### Treo cũ (từ v49–v50, CHƯA động)
- **Upload "Chú Vịt Con" chuẩn** → trỏ `lesson_activity_media` Phần 4 (`ac0a5c13`) về media_id đúng (đang tạm "Tiếng Mưa" `34ad7ff4`).
- **"Try to fix all" 11 Security issues Lovable — ĐỪNG BẤM** (D5/D14).
- Lưu repo backup migrations 060–078 (D90) · drift mig057 · 3-tier privacy moments · parent portal design.

**✅ ĐÃ GIẢI QUYẾT (gỡ khỏi treo v50):** `teacher.remote.tsx` đã xoá khỏi repo (D142 xong) · toggle nền laptop đã có trong StepTeach · registry `/remote` + `/school/drive` đã ghi (D106) · media-vault description đã điền · crossfade/preload đã làm.

---

## 6. Boot phiên sau
1. Đọc **HANDOFF v51** → `DMA_00_START_HERE.md` → `DMA_RULES.md` (nhớ thêm D157–D160).
2. **Audit live DB** (D1/D90): kỳ vọng **53 bảng · 77 definer · 9 Edge · 3 tenant**; `admin_modules` có `school-drive`, `teacher-remote` route=`/remote`.
3. **Quy trình Lovable:** mặc định code byte-exact cho Jean **paste** (tiết kiệm credit); "tự áp"/"auto áp" → agent (`send_message`, ~1.5–3 credit/lần). Lovable API đôi lúc lỗi read/ghi → thử lại / fallback paste (D156). **Preview URL luôn phản ánh commit mới.** **Luôn `get_diff` verify sau agent apply.**
4. **Media engine (nhạy):** một nguồn phát · aux một-slot · slideshow khu-trú Phần 0 · `shown` gate · `guideRev` reload · autoplay cần cử chỉ (lớp phủ) · **video HLS qua hls.js** (D157) · **preload cache TTL 8'** (D159) · **screen-lock `locked`** (D160). Sửa engine → cực cẩn thận, test cả buổi không-nền + Chrome/Safari/iPhone; **KHÔNG auto-publish engine/đường phát**, để Jean Publish.
5. **Nhớ:** sửa remote = `src/routes/remote.tsx` (D142). Video stream test bằng "Bay Vào Vũ Trụ (demo)".
6. **Supabase MCP** có thể cần reconnect nếu `-32600 permission`.

**Tài khoản test** (password `Test@123`, domain `@demo.demenart.com`):
- GV: `gv.linh.kidshouse@demo.demenart.com` · Master (Kho của trường): `hieutruong.kidshouse@demo.demenart.com`
**Preview:** `https://id-preview--d9d56000-3cf9-4c46-9890-651edc53d73f.lovable.app/`
**IDs:** Supabase `xcvhacymrbhdhohyylyq` · Lovable `d9d56000-3cf9-4c46-9890-651edc53d73f` · buổi demo `aaaa0000-0000-4000-8000-0000000a0001` (lesson "Tiếng mưa rơi", version `ac0a5c13-aad4-4c66-a7e0-d32ce1d749ab`) · trường KHM `d1000000-0000-4000-8000-000000000001` · video demo HLS `5e72a438-cac6-43e9-94ec-4021adc44b35`.

*Nguồn: Tài liệu A–G + tầm nhìn founder + DMWS. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
