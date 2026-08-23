# 🧾 DMA_HANDOFF_v43.md — FIX UTC (mig 066) + DỌN NỢ REPO 060–065 + ⭐ SPRINT 3A CLASSROOM TRIO + HẠ TẦNG CUSTOM DOMAIN CDN (D120–D123) — 2026-07-01 14:11 GMT+7

> **Boot phiên sau:** đọc `DMA_00_START_HERE.md` → `DMA_RULES.md` → file này. Audit live trước khi viết code (D1).
> **Phiên này = 3 mạch:** (A) fix bug UTC + dọn nợ repo · (B) Sprint 3A Classroom Trio (UI mới, KHÔNG DB) · (C) hạ tầng CDN custom domain né ISP chặn `.b-cdn.net`.

---

## ⭐ LÀM ĐƯỢC PHIÊN NÀY

### (A) Fix bug UTC (mig 066) + dọn nợ repo 060–065 (D90)
- **mig 066** — `get_teacher_home` + `get_teacher_todo_counts`: `date_trunc('day', now())` (UTC) → `date_trunc('day', now() AT TIME ZONE 'Asia/Ho_Chi_Minh') AT TIME ZONE 'Asia/Ho_Chi_Minh'`. 3-block D92 + re-harden D15. **VERIFY ĐẠT** (has_hcm=true · still_naive=false · secdef · grants sạch no-anon/PUBLIC).
  - **🔎 D112 correction:** `get_teacher_classes` **KHÔNG dính bug** — body không lọc "hôm nay" (chỉ trả mọi buổi order desc). Handoff v40 + RULES ghi sai tên hàm này. Đã đính chính. Chỉ **2 hàm** trên dính (bắt được `get_teacher_todo_counts` nhờ quét `naive_date_scan`, suýt sót nếu chỉ vá 2 hàm-được-đặt-tên).
- **Dọn nợ repo (D90 — dump từ live, KHÔNG tái dựng trí nhớ):** 6 file SQL repo-ready cho mig 060–065 + 1 file data:
  - `060_get_school_overview.sql` · `061_get_school_week_schedule.sql` · `062_get_school_moments.sql`
  - `063_065_get_lesson_guide.sql` (gộp — live chỉ giữ thân cuối mig065; thân 063 gốc không tái dựng)
  - `064_lesson_activity_media.sql` (DDL+RLS; ⚠️ **grant cấp-BẢNG = convention default, chưa audit** — cần `role_table_grants` verify)
  - `data_demo_rain_track.sql` (v41 clone `ac0a5c13` + 2 UPDATE / v42 seed activities / v42 gán 2 media). Media `34ad7ff4` do Edge upload — chỉ tham chiếu, không SQL.
- `066_fix_teacher_utc.sql` cũng đã xuất repo.

### (B) ⭐ SPRINT 3A — CLASSROOM TRIO (UI mới, KHÔNG DB/Edge/policy)
Kiến trúc same-laptop BroadcastChannel (chốt v40), bọc transport trừu tượng → sau nâng Realtime KHÔNG viết lại UI. **3 file:**
- **`src/hooks/useSessionChannel.ts`** — transport trừu tượng (BroadcastChannel) + hook đối xứng 2 vai. Remote sở hữu **ClassroomState** (partIndex, mediaIndex, command, blackout, seekReq); Monitor sở hữu **MonitorStatus** (isPlaying, positionSec, durationSec, ready). Last-write-wins theo `ts`. **+heartbeat ping 2s** (v2 — fix connected flap). `hello` khi mount → peer re-broadcast state để vào-sau tự sync. Nâng Realtime = đổi DUY NHẤT `createTransport()`.
- **`src/routes/_authenticated/teacher.classroom.tsx`** — Monitor/TV. `fixed inset-0 z-50` phủ shell (không sửa `teacher.tsx`, tránh D116). Nút "Bắt đầu trình chiếu" (gesture: fullscreen + audio-context unlock). Tái dùng NGUYÊN engine Bước 2: `get_lesson_guide` → `guide[].media[]`, `kindOf` MIME, `get_signed_media_url` Edge, player audio/video/image, watermark trôi. Blackout overlay (TẮT màn — trẻ tập trung vào cô). Diagnostic lỗi phân biệt fetch-fail vs media-onError (mã element.error.code).
- **`src/routes/_authenticated/teacher.remote.tsx`** — Remote mobile, nút to 1-tay. Nạp guide → đọc lời-dẫn/câu-hỏi trên phone + điều khiển: chọn Phần/media, play/pause/stop, tua (theo status), TẮT/BẬT màn TV. `?session=<id>` search param.
- **Nghiệm thu login thật ĐẠT** (GV Mỹ Linh, session a0001): "TV đã sẵn sàng" (heartbeat), state sync đúng Phần 2/5, play/tua/blackout/chuyển-Phần OK. Cơ chế báo lỗi chính nó giúp chẩn được sự cố CDN.
- **Scope 3A CHỐT:** chỉ điều-khiển-trình-chiếu. Điểm-danh-nhanh / chụp / kết-thúc-buổi trên Remote → **hoãn 3B** (trùng engine `StepRecord`, tránh dựng đôi).
- **CHƯA wire nút** trong `teacher.session.$id.tsx` (khối "Chiếu lên TV" vẫn teaser) — test bằng URL trực tiếp. Wire = việc treo đầu bảng.

### (C) HẠ TẦNG CDN — CUSTOM DOMAIN né ISP chặn `.b-cdn.net` (D121)
- **Sự cố phát hiện khi test 3A:** audio học liệu lỗi `SRC_NOT_SUPPORTED` → Console lộ `ERR_NAME_NOT_RESOLVED` cho `dma-learning.b-cdn.net`. **KHÔNG phải bug code** (Edge ký `signed OK hasUrl:true`, CẢ 2 file đều lỗi = zone-wide). **Đổi mạng → chạy** → xác nhận ISP mạng cũ chặn DNS `*.b-cdn.net`.
- **Đã dựng 3 custom hostname** (Bunny + Cloudflare CNAME **DNS-only** không proxy + SSL Let's Encrypt), **giữ `.b-cdn.net` System làm fallback:**
  - `learn.demenart.com` → dma-learning · `media.demenart.com` → dma-private · `cdn.demenart.com` → dma-public
- **Fix Edge = KHÔNG sửa code (D120).** Audit `get_signed_media_url` (đọc thật): host build từ **biến môi trường** `BUNNY_LEARNING_HOST`/`BUNNY_PRIVATE_HOST`; chữ ký `SHA256(key + path + expires)` **KHÔNG gồm hostname** → đổi host cùng zone không vỡ token.
  - **⏳ PENDING JEAN (nghiệm thu CHƯA xong):** đổi 2 secret Supabase Edge → `BUNNY_LEARNING_HOST=learn.demenart.com`, `BUNNY_PRIVATE_HOST=media.demenart.com` (host trần, no `https://`, no `/` cuối), **KHÔNG đụng TOKEN_KEY**, **redeploy** `get_signed_media_url`, rồi **test trên MẠNG CŨ đã chặn** → phải phát được audio (`urlHead: https://learn.demenart.com/...`). Rollback = đổi secret về `.b-cdn.net`.
  - `dma-public`/`cdn.demenart.com` KHÔNG qua Edge này (asset công khai ghép URL nơi khác) — nếu cũng bị chặn phải sửa riêng, chưa làm.

---

## 📊 TRẠNG THÁI DB
- **53 bảng · 69 hàm definer · 138 policy\* · mig 001→066 · seed 001→014 · 7 Edge · 3 tenant/3 master.**
  - mig 066 **REPLACE** 2 hàm (không +hàm) → vẫn 69. Bảng/policy/Edge/seed KHÔNG đổi.
  - *(\*) drift `notification_sounds_select_enabled` (mig 057) vẫn CHƯA chạy → thực tế có thể 137. Chưa đụng.*
- **SYSTEM_MAP v0.39 (BUMP — mig 066 + 3 route/hook Classroom Trio + custom domain CDN).**
- **Routes:** TẠO `_authenticated/teacher.classroom.tsx` · `_authenticated/teacher.remote.tsx` · `src/hooks/useSessionChannel.ts`. SỬA (DB): mig 066.

---

## 🆕 D-RULES (đã append RULES): D120 · D121 · D122 · D123

- **D120** — Bunny host = biến môi trường; token ký không gồm hostname → đổi custom domain cùng zone = đổi secret + redeploy, KHÔNG sửa code. Env var chính là cờ rollback.
- **D121** — ISP VN chặn `*.b-cdn.net` (ERR_NAME_NOT_RESOLVED) = rủi ro pilot thật → custom domain CNAME **DNS-only** (không proxy Cloudflare — proxy phá token+SSL), giữ `.b-cdn.net` fallback.
- **D122** — BroadcastChannel `connected` cần heartbeat ping chủ động (status event-driven không đủ → idle false dương-tính-giả). Abstraction transport đã kiểm chứng (đổi Realtime = 1 hàm).
- **D123** — Route fullscreen no-chrome = `fixed inset-0 z-50` (không sửa layout cha, tránh D116). + Diagnostic media: phân biệt fetch-fail vs `element.error.code`.

---

## 🔧 VIỆC TREO

**⏳ Đóng nốt phiên (ưu tiên):**
- 🔴 **Đổi 2 secret Edge + redeploy + test mạng-cũ** (mục C) — chưa nghiệm thu, là mảnh cuối của fix CDN.
- 🟢 **Wire nút** `teacher.session.$id.tsx`: khối "Chiếu lên TV" → mở `/teacher/classroom?session=<id>` + `/teacher/remote?session=<id>` thật (D95 bản thay thế đầy đủ).
- 🟡 **Registry (D106) — CHƯA cập nhật phiên này:** cần audit `admin_modules` (cột + nội dung) trước khi thêm route classroom/remote (D1 — không bịa schema). Query: `SELECT * FROM admin_modules LIMIT 5;`
- 🟡 `064_lesson_activity_media.sql` grant cấp-bảng `⚠️ VERIFY` (`role_table_grants`).

**Cụm Classroom & Journal (tiếp):**
- 🟢 **3B — Route Nhật ký** `/teacher/journal` (nháp/chờ-gửi/đã-gửi) + mở-khoá sidebar — đụng DB (audit `lesson_sessions.state`, có thể RPC `get_teacher_journals`).
- 🟢 Remote V1.2: điểm-danh-nhanh / chụp-khoảnh-khắc / kết-thúc-buổi (hoãn từ 3A, tái dùng engine StepRecord).
- 🟡 Autoplay: máy chặn gắt có thể im tới lần chạm play thứ 2 (Realtime sau khác luồng).

**Hạ tầng/nợ cũ:**
- 🟡 `dma-public` custom domain `cdn.demenart.com` đã dựng nhưng Edge không dùng — nếu asset public bị ISP chặn phải sửa nơi ghép URL công khai.
- 🟡 Media Library Manager V1 + nâng `upload_media` video/image (D119).
- 🟡 drift mig057 · Admin wire/re-theme/route (D109/D111) · 3-tier privacy label moments · nợ cũ (seed test · 2 PH email-null · pilot chưa login · Vercel dormant · lock linh vật · pwa.theme_color).

---

## ▶️ KẾ TIẾP — chọn 1
1. **Đóng nốt CDN + wire nút** (đổi secret/test mạng-cũ + wire 2 nút TV/Remote) — hoàn tất trọn vẹn 3A + fix CDN cho demo bấm-là-chạy.
2. **3B — Route Nhật ký** `/teacher/journal` (DB-first: audit state + RPC).
3. **Remote V1.2** (điểm-danh/chụp/kết-thúc trên phone).

*Boot phiên sau → audit D1 → đề xuất (D98) → build → nghiệm thu login thật (D2/D3) → verify đúng-nguồn (D113) → HANDOFF v44. Cập nhật registry khi đóng (D106 — nợ từ phiên này). "Tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*

> **Demo accounts (luôn kèm khi nhờ test):** GV KHM Mỹ Linh `gv.linh.kidshouse@demo.demenart.com` / `Test@123`. Session demo "Tiếng mưa rơi" = `aaaa0000-0000-4000-8000-0000000a0001` (Phần listen→audio mưa `34ad7ff4`, Phần move→"Chú Vịt Con" `93ddea79`).
