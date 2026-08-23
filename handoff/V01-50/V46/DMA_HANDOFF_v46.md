# 🤝 DMA_HANDOFF_v46.md — BÀN GIAO PHIÊN (Kho Học Liệu LÁT 1a + 1b)

> **Chốt lúc:** 2026-07-01 21:46 GMT+7
> **Phiên trước:** v45 (Kho Học Liệu LÁT 0 — nền đa-nguồn + Admin gán vai + player lọc material_role).
> **Boot phiên sau:** đọc **file này** → `DMA_00_START_HERE.md` → `DMA_RULES.md` trước khi làm gì. Claude trình menu, Jean chọn.

---

## 0. TL;DR PHIÊN NÀY

**Sprint: Kho Học Liệu — LÁT 1a (ảnh curriculum) + LÁT 1b (video qua Bunny Stream + HLS).**

- **LÁT 1a XONG + nghiệm thu login thật:** nâng `upload_media` nhận **ảnh** curriculum (jpg/png/webp ≤10MB) + UI admin mở `accept`. Ảnh render trong Bước 2 qua `<img>` + watermark + StatusPill "Hình ảnh" + Classroom Trio. Video vẫn reject (đi Bunny Stream).
- **LÁT 1b XONG + nghiệm thu TV thật:** video curriculum phát qua **Bunny Stream + HLS (hls.js)** — băm chunk thật (`.ts` segment, bảo vệ IP như Jean yêu cầu, KHÔNG cho tải nguyên file). Giải được **chuỗi 403 hạ tầng Bunny rất khó** (mất ~3h). Watermark fullscreen + Classroom Trio + **video chờ bấm trên Monitor** đều đạt.
- **KHÔNG migration** cả phiên (schema đã sẵn từ v45/mig068). Chỉ Edge (2) + UI (2) + data test.

**Bài học lớn (3 D-rule mới D126–128):** path-based token BẮT BUỘC cho HLS · block-direct-access phá HLS · fullscreen phải phủ container watermark + video-chờ-bấm chặn qua ts-guard.

---

## 1. ĐÃ LÀM

### LÁT 1a — Ảnh curriculum (Edge + UI, KHÔNG mig)

**Edge `upload_media` (deploy):** Branch B (curriculum → `dma-learning`) giờ nhận **audio HOẶC ảnh** (`CURR_IMG_TYPES` = jpg/png/webp ≤10MB, thêm helper `imgExt()`). Branch A (ảnh trẻ → `dma-private`) giữ nguyên. **Video vẫn reject** kèm hint "sẽ qua Bunny Stream" (D119 trả nợ 1 nửa).

**UI `admin.curriculum-admin.tsx` (áp Lovable):** `accept="audio/*,image/jpeg,image/png,image/webp"`, relabel, `mapReason` đọc `raw.max`. Route `createFileRoute("/_authenticated/admin/curriculum-admin")` verify không đổi (D117).

**Nghiệm thu login thật ĐẠT** (super_admin `info@demenart.com` + GV Mỹ Linh): upload ảnh "Ảnh mưa demo" (`media_id a639f0c7-97fc-4808-92c8-22c4541d1f26`) → gán vào Phần "Chọn hình ảnh" (`pick_image`) qua Kho Học Liệu → render `<img>` ở Bước 2 + watermark trôi + StatusPill "Hình ảnh" + Classroom Trio. 3 lớp (Admin gán / Bước 2 / Trio) đạt.

### LÁT 1b — Video qua Bunny Stream + HLS (Edge + UI, KHÔNG mig)

**Quyết cơ chế:** HLS qua **hls.js** (băm segment thật, adaptive bitrate, bảo vệ IP) — Jean chọn B (bảo vệ IP) thay vì MP4 progressive. Native `<video>` giữ nguyên (hls.js chỉ bơm segment qua MSE) → watermark/blackout/Trio/timeline không đổi. Safari→HLS native; Chrome/FF→hls.js.

**Bunny Stream config:**
- Library **dma-stream** (ID **694835**), CDN host **vz-78716e0a-811.b-cdn.net** (pull-zone 6089136). Region Frankfurt-main (Bunny khoá) + Singapore replica. DRM off, MP4 fallback on, encode free-tier 240p→1080p H.264.
- Video demo **Bay_Vao_Vu_Tru.mp4** 40s (**GUID 552a5c42-e76d-4d52-aba3-257e0570a36b**).
- **Security cuối cùng (QUAN TRỌNG):** `CDN token authentication = ON` · `Enable direct play = ON` · **`Block direct url file access = OFF`** · Allowed/Blocked domains = trống. (Xem D127 — block-direct-access phá HLS.)
- Secrets Edge: `BUNNY_STREAM_HOST` (không bí mật) + `BUNNY_STREAM_TOKEN_KEY` (Security tab). hls.js@1.6.16.

**SQL data (KHÔNG migration — chỉ INSERT/UPDATE row):** tạo `media_assets` video row (`media_id 5e72a438-cac6-43e9-94ec-4021adc44b35`, `cdn_pull_zone='dma-stream'`, `bunny_path='/552a5c42-.../'`, `bunny_stream_video_id=GUID`, `file_type='video/mp4'`, `access_level='private_curriculum'`, `source='dma_global'`, `watermark_required=true`) → gán vào Phần **share** (Chia sẻ cảm nhận) version `ac0a5c13`, role present.

**Edge `get_signed_media_url` (deploy):** thêm nhánh `dma-stream`. 2 nhánh cũ (audio/ảnh via Storage) byte-identical. **Chữ ký directory-token** = `SHA256(key + dir + expires + "token_path=" + dir)` (dir = `/{guid}/`). **URL = PATH-BASED** (D126): `https://{host}/bcdn_token={token}&expires={exp}&token_path={enc(dir)}{dir}playlist.m3u8`. Trả `is_stream:true`, `playback_url`(.m3u8), `mp4_fallback`(play_720p.mp4).

**UI `teacher.session.$id.tsx` (áp Lovable):** StepTeach — nhánh video Stream gắn hls.js vào `<video>` sẵn có. Safari→native HLS; else `import("hls.js")` config sạch (`{enableWorker:true}` — KHÔNG cần loader/xhrSetup vì token path-based tự thừa kế). MANIFEST_PARSED→play nếu wantPlay; fatal ERROR→MP4 fallback. **Fix fullscreen**: fullscreen trên `previewRef` (container bọc video+watermark) KHÔNG `mediaRef` (video trần) → watermark còn trong fullscreen (D128).

**UI `teacher.classroom.tsx` (áp Lovable — Monitor/TV):** **video chờ bấm** — video mới nạp + Remote chưa play → effect lặp Stop 8 nhịp/1.6s kéo về đầu (thắng autoplay HLS bắn-trễ); áp lệnh Remote CHỈ khi `state.ts` mới (`lastCmdTsRef`) → không re-fire lệnh play cũ khi loaded đổi (D128). Audio giữ autoplay.

**Nghiệm thu TV thật ĐẠT** (GV Mỹ Linh, TV thật kéo màn Monitor sang): video vũ trụ HLS phát trên TV, Network lọc `vz` = master `.m3u8` + variant `240p/video.m3u8` + `.ts` segment (video0/1/2.ts) **toàn 206** (băm chunk thật) · watermark trôi (fullscreen giữ) · Remote play/pause/seek/blackout sync · video **đứng khung đầu chờ bấm** (không autoplay).

---

## 2. TRẠNG THÁI DB (sau phiên)

**53 bảng · 72 hàm definer · 138 policy\* · mig 001→070 · seed 001→014 · 7 Edge · admin_modules 58 row · 3 tenant/3 master.**

**KHÔNG ĐỔI so với v45** — cả phiên KHÔNG migration. Edge `upload_media` + `get_signed_media_url` = REPLACE code (không đổi số Edge = 7). Thay đổi DB = chỉ **data live**:
- +2 `media_assets` row: `a639f0c7` (ảnh mưa demo, qua UI) + `5e72a438` (video vũ trụ Stream, qua SQL).
- +2 `lesson_activity_media` link: `pick_image`→ảnh, `share`→video (version `ac0a5c13`, role present).

\* policy 138: drift mig057 (`notification_sounds_select_enabled`) có thể khiến thực-có 137 — CHƯA reconcile (D112).

**Data note test phiên này (có thể gỡ nếu demo sạch):** ảnh `a639f0c7`@pick_image + video `5e72a438`@share đều là học liệu **test** trên session a0001.

---

## 3. LÁT TIẾP THEO — Kho Học Liệu

LÁT 0 + 1a + 1b xong. Còn:

1. **LÁT 1b-ii — Upload video lớn browser→Bunny (TUS resumable):** hiện video vào kho bằng **upload thẳng lên Bunny Stream dashboard** rồi tạo media_asset qua SQL. Cần luồng UI: browser upload video → Bunny Stream (TUS resumable, KHÔNG qua Edge vì Deno payload/timeout — D119) → tự tạo media_asset. Đây là mảnh còn thiếu để admin tự thêm video không cần SQL tay.
2. **LÁT 1c — My Drive (teacher) / Drive School:** nguồn `teacher`/`school` (mig068 đã có cột `source`).
3. **LÁT 2 — Quota:** `school_subscriptions.storage_base_mb`+`addon_mb` sẵn. Lọc theo `access_level` KHÔNG `source`. dma_global KHÔNG tính quota Org.
4. **LÁT 3 — Admin browser kho:** Finder duyệt toàn kho + "dùng ở đâu" (chiều ngược `lesson_activity_media`).
5. **LÁT 4 — Picker khi đứng lớp.**

---

## 4. 📋 REMOTE v2 — UX/UI UPGRADE (ghi từ ý Jean phiên này)

Jean nêu cụm nâng cấp Remote (làm sprint riêng, tươi tỉnh):

1. **UI remote "pro"** — làm giống điều khiển thật đẹp, dùng 1 tay trên điện thoại.
2. **Nút Volume** — mute on/off + tăng/giảm (gửi lệnh volume qua channel → Monitor).
3. **Fullscreen + Đóng Monitor TỪ Remote** — thay việc rê chuột sang TV bấm "Bắt đầu trình chiếu" (khó, không pro khi màn đã kéo sang TV). Remote bấm → Monitor tự fullscreen; kèm nút "Đóng Monitor". ⚠️ *Kỹ thuật: fullscreen cần user-gesture trên chính cửa sổ Monitor — điều khiển qua BroadcastChannel có thể vướng policy; Monitor nhận lệnh rồi tự `requestFullscreen()` trong handler, nếu browser chặn → fallback nút trên Monitor. Cần nghiên cứu lúc làm.*
4. **Nút chế độ lặp** — loop liên tục / phát 1 lần cho media đang chọn.
5. **Preview Phần tiếp theo** — hiển thị nhỏ nội dung Phần kế để GV chủ động chuẩn bị.
6. **Back/Next media trong Phần** — làm rõ: nút cạnh Play để chuyển giữa **nhiều học liệu trong CÙNG 1 Phần** (`part.media[]` + `mediaIndex` đã có sẵn). ✅ **Kiểm tra kiến trúc (D1): CÓ hỗ trợ nhiều học liệu/Phần** — `part.media[]` là mảng, `state.mediaIndex` chọn từng cái. Demo hiện mỗi Phần 1 học liệu nên chưa thấy tác dụng; cần seed demo 1 Phần 2-3 học liệu để test.

---

## 5. VIỆC TREO KHÁC (mang từ v45)

- 🟢 **3B Route Nhật ký** `/teacher/journal` (DB-first: `lesson_sessions.state` + RPC `get_teacher_journals` + mở-khoá sidebar).
- 🟢 **Remote V1.2** (điểm-danh/chụp/kết-thúc — StepRecord trên remote).
- 🟡 **Nâng BroadcastChannel → Supabase Realtime** (phone khác máy — đổi `createTransport()`, D122).
- 🟡 **Lưu repo mig 060–066** (dump từ live, D90) — nợ tích từ v39, CHƯA làm.
- 🟡 **Lưu repo SQL data phiên này** (INSERT video media + link share/pick_image — D90) — tuy là data không phải schema, nên ghi lại để tái tạo demo.
- 🟡 **`lesson_activity_media` grant-verify** (flag ⚠ mig065 dump v42).
- 🟡 **Drift mig057** — xác nhận policy count + chạy khôi phục read âm.
- 🟡 **Admin** wire "Xử lý" Action Center + re-theme cosmic + điền route ~50 module (D109/D111).
- 🟡 **3-tier privacy label** moments (cần field consent vào `get_school_moments`).
- 🟡 **`cdn.demenart.com` Edge chưa dùng.**
- 🟡 **Watermark nung-vĩnh-viễn (server-side burn-in)** — hiện watermark là overlay app (không nung vào file; mở URL `.ts`/`.m3u8` trực tiếp là video gốc chưa watermark). Mô hình hiện tại đủ cho pilot (token ngắn hạn + chunking + overlay răn đe). Nếu cần bảo vệ mạnh hơn → Bunny Encoding "Watermark" (tốn phí). Ghi để cân nhắc.
- Nợ cũ: dọn seed test/demo_seed · 2 PH email-null (Chi/Dung) · GV/PH pilot chưa login · file nhạc curriculum chưa nguồn lưu · Vercel dormant · lock 1 linh vật · pwa.theme_color.

---

## 6. FILE GIAO PHIÊN NÀY (paste-over/repo)

| File | Loại | Ghi chú |
|---|---|---|
| `upload_media_v1a_index.ts` | Edge paste-over | LÁT 1a — nhận ảnh curriculum. Đã deploy. |
| `admin.curriculum-admin.tsx` | route paste-over | LÁT 1a — accept ảnh. Đã áp. |
| `get_signed_media_url_stream_index.ts` | Edge paste-over | LÁT 1b — nhánh dma-stream path-based token. Đã deploy. |
| `teacher.session.$id.tsx` | route paste-over | LÁT 1b — hls.js + fullscreen container. Đã áp. |
| `teacher.classroom.tsx` | route paste-over | LÁT 1b — video chờ bấm (ts-guard + stop-loop). Đã áp. |
| `DMA_RULES.md` | library | +D126/D127/D128 + update v46, footer v46 |
| `DMA_SYSTEM_MAP.md` | library | v0.42 |
| `DMA_HANDOFF_v46.md` | library | file này |

---

## 7. NGUYÊN TẮC BẤT BIẾN (nhắc)

- **D1:** audit live trước mọi SQL/code. **D92:** 3-block CREATE→REVOKE/GRANT→VERIFY. **D15:** re-harden grant sau CREATE OR REPLACE.
- **D95:** giao file paste-over trọn, không diff. **D2/D3:** verify login thật, không chỉ SQL Editor. **D5/D14:** KHÔNG "Try to fix all" Lovable.
- **D48:** admin không chạm PII trẻ. **D75:** GV không thay curriculum media. **D117:** verify `createFileRoute` trước paste.
- **🆕 D126:** HLS = PATH-BASED token (`/bcdn_token=.../`), KHÔNG query token. **🆕 D127:** `Block direct url file access` phá HLS — OFF (token vẫn bảo vệ). **🆕 D128:** fullscreen phủ container (giữ watermark) + video-chờ-bấm chặn qua ts-guard, không đấu autoplay.
- **KỶ LUẬT VÀNG:** tới đâu ghi tới đó.

**Demo accounts (luôn kèm khi nhờ Jean test):** super_admin `info@demenart.com` · GV Mỹ Linh `gv.linh.kidshouse@demo.demenart.com`/`Test@123`. Session demo "Tiếng mưa rơi" = `aaaa0000-0000-4000-8000-0000000a0001` (version `ac0a5c13-aad4-4c66-a7e0-d32ce1d749ab`). Video demo GUID = `552a5c42-e76d-4d52-aba3-257e0570a36b`, media_id `5e72a438-cac6-43e9-94ec-4021adc44b35`. Ảnh demo media_id `a639f0c7-97fc-4808-92c8-22c4541d1f26`.
