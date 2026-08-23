# 🧾 DMA_HANDOFF_v44.md — WIRE NÚT "CHIẾU LÊN TV" (Classroom Trio LIVE) + NGHIỆM THU CDN MẠNG-CŨ + REGISTRY mig 067 (D124) — 2026-07-01 15:04 GMT+7

> **Boot phiên sau:** đọc `DMA_00_START_HERE.md` → `DMA_RULES.md` → file này. Audit live trước khi viết code (D1).
> **Phiên này = đóng nốt 2 mảnh dở của v43 + trả nợ registry:** (A) nghiệm thu fix CDN trên mạng-cũ-đã-chặn · (B) wire 2 nút TV/Remote trong session (Classroom Trio nay bấm-là-chạy) · (C) trả nợ registry D106 (mig 067).

---

## ⭐ LÀM ĐƯỢC PHIÊN NÀY

### (A) ✅ NGHIỆM THU FIX CDN — mạng-cũ-đã-chặn PHÁT ĐƯỢC (đóng mạch C của v43)
- Jean áp 2 secret Edge (`BUNNY_LEARNING_HOST=learn.demenart.com` · `BUNNY_PRIVATE_HOST=media.demenart.com`, host trần, KHÔNG đụng TOKEN_KEY) + redeploy `get_signed_media_url` → **test trên mạng cũ (mạng trước đó `ERR_NAME_NOT_RESOLVED`) → audio "Lắng Nghe Tiếng Mưa" phát OK**, `urlHead: https://learn.demenart.com/...`. D120 xác nhận thực chiến: đổi host cùng zone = đổi secret, KHÔNG sửa code, token vẫn hợp lệ. `.b-cdn.net` giữ fallback.

### (B) ⭐ WIRE NÚT "CHIẾU LÊN TV" — Classroom Trio bấm-là-chạy (D95 paste-over)
- **SỬA `src/routes/_authenticated/teacher.session.$id.tsx`** (Bước 2 "Dạy học", khối player):
  - Khối "Chiếu lên TV" cũ = teaser toggle 🔒 V1.1 → thay bằng **2 nút thật**:
    - **"Chiếu lên TV"** (xanh đặc) → `window.open('/teacher/classroom?session=<id>', 'dma_monitor_<id>')`
    - **"Mở điều khiển"** (viền xanh + icon `Smartphone`) → `window.open('/teacher/remote?session=<id>', 'dma_remote_<id>')`
  - Named-window target → bấm lại focus cửa sổ cũ, không mở trùng. Dùng `session.id` của buổi đang mở.
  - Giữ nút "Báo lỗi phát" + hint hướng dẫn (kéo Monitor sang TV, Remote cùng máy, blackout giữ bé tập trung). Bỏ state chết `tvHint` + badge V1.1.
  - Thêm import icon `Smartphone`. Route đích `createFileRoute("/_authenticated/teacher/session/$id")` verify KHÔNG đổi (D117). `{}` 961/961 · `[]` 144/144 cân bằng.
- **Param sync = `?session=<id>`** — khớp nghiệm thu URL-trực-tiếp v43 (đúng, không đoán).
- **🆕 Nghiệm thu login thật ĐẠT** (GV Mỹ Linh, session a0001, 5 ảnh):
  1. Session Bước 2 → 2 nút mới + hint hiển thị đúng.
  2. `/teacher/classroom?session=a0001` → Monitor "Màn chiếu Dế Mèn" + "Bắt đầu trình chiếu", **"Remote đã kết nối"** (heartbeat D122).
  3. `/teacher/remote?session=a0001` → **"TV đã sẵn sàng"**, sync Phần 1/5.
  4. **Phần 2/5 "Lắng nghe âm thanh"** → chip "Lắng Nghe Tiếng Mưa · Audio", **timeline 0:02/9:59 chạy**, Monitor phát + **watermark trôi "DMA · CTAN · Kids House Mon... 14:43:00 1/7/2026"** (fix CDN + wire nút chứng cùng một màn).
  5. **Blackout** "Tắt màn TV" → Monitor đen ("DẾ MÈN" mờ), nút đổi "Bật lại màn TV", **audio vẫn chạy 0:08** (tắt màn không ngắt nhạc).
- **Đã deploy production:** ảnh 15:03 chụp URL `demenart.com/teacher/session/...` (domain thật, không Preview) → file đã commit + Cloudflare Pages rebuild (D84). LIVE.

### (C) ✅ TRẢ NỢ REGISTRY D106 — mig 067 (nợ từ v43)
- **D1 audit `admin_modules` trước** (cột + status hợp lệ + group + slug + row mẫu): 14 cột; `status ∈ {building,live,planned,reserved}`; `route`/`icon` đa số null (D109); group gần nhất = `lesson-session` (`f9d9e657-5f02-4d95-b0f5-6d5f2873f285`, enabled); `related_slugs` toàn `[]`.
- **mig 067 (2-block, bọc replica D85):** INSERT 2 module `teacher-classroom` + `teacher-remote` (đủ `description`/`usage_note`/`search_keywords`/`related_slugs`/`route`/`status=live` — D106), cùng group `lesson-session`; UPDATE nối ngược `lesson-session.related_slugs += [classroom,remote]` → **liên kết 2 chiều đối xứng** (KỶ LUẬT VÀNG — hub không line vô hình).
- **VERIFY ĐẠT:** `symmetric_2way_ok=true` · `all_enabled=true` (cả 3 hub enabled) · `total_modules 55→57` · `lesson_session_related=[teacher-classroom,teacher-remote]`.
- Xuất repo `067_registry_classroom_remote.sql` (D90).

---

## 📊 TRẠNG THÁI DB
- **53 bảng · 69 hàm definer · 138 policy\* · mig 001→067 · seed 001→014 · 7 Edge · 3 tenant/3 master.**
  - **mig 067 = DATA change** (INSERT 2 + UPDATE 1 vào `admin_modules`), **KHÔNG đổi cấu trúc** → bảng/hàm/policy/Edge/seed GIỮ NGUYÊN. `admin_modules` row 55→57.
  - *(\*) drift `notification_sounds_select_enabled` (mig 057) vẫn CHƯA chạy → thực tế có thể 137. Chưa đụng.*
- **SYSTEM_MAP v0.40 (BUMP — wire nút session→Classroom Trio + registry 2 module).**
- **Routes:** SỬA `_authenticated/teacher.session.$id.tsx` (wire 2 nút TV/Remote; đã deploy production). SỬA (DB): mig 067 registry.

---

## 🆕 D-RULES (đã append RULES): D124

- **D124** — Registry-driven self-documenting (P0.7 + D106): route mới TẠO ở phiên trước mà CHƯA vào `admin_modules` là NỢ phải trả ngay phiên sau; audit schema thật trước (status hợp lệ, group cha, slug để nối), INSERT đủ metadata + nối `related_slugs` **đối xứng 2 chiều tới hub enabled** (không line vô hình). "Chỗ mở cửa" giữa route-app và registry: route sống nhưng registry câm = search operator không thấy công cụ.

---

## 🔧 VIỆC TREO

**Cụm Classroom & Journal (tiếp — ưu tiên):**
- 🟢 **3B — Route Nhật ký** `/teacher/journal` (nháp/chờ-gửi/đã-gửi) + mở-khoá sidebar (hiện 🔒 "SẮP RA MẮT · V1.5") — đụng DB (audit `lesson_sessions.state`, có thể RPC `get_teacher_journals`).
- 🟢 **Remote V1.2:** điểm-danh-nhanh / chụp-khoảnh-khắc / kết-thúc-buổi trên phone (hoãn từ 3A, tái dùng engine StepRecord).
- 🟡 Autoplay: máy chặn gắt có thể im tới lần chạm play thứ 2 (Realtime sau khác luồng).
- 🟡 Nâng transport BroadcastChannel → Supabase Realtime (phone khác máy) — chỉ thay `createTransport()` (D122 đã kiểm chứng abstraction).

**Hạ tầng/nợ cũ:**
- 🟡 `dma-public` custom domain `cdn.demenart.com` đã dựng nhưng Edge không dùng — nếu asset public bị ISP chặn phải sửa nơi ghép URL công khai.
- 🟡 `064_lesson_activity_media.sql` grant cấp-bảng `⚠️ VERIFY` (`role_table_grants`).
- 🟡 Media Library Manager V1 + nâng `upload_media` video/image (D119) · video lớn → Bunny Stream.
- 🟡 drift mig057 · Admin wire/re-theme/route (D109/D111) · 3-tier privacy label moments (consent field trong `get_school_moments`) · nợ cũ (seed test · 2 PH email-null · pilot chưa login · Vercel dormant · lock linh vật · pwa.theme_color).

---

## ▶️ KẾ TIẾP — chọn 1
1. **3B — Route Nhật ký** `/teacher/journal` (DB-first: audit `lesson_sessions.state` + RPC `get_teacher_journals` + mở-khoá sidebar).
2. **Remote V1.2** (điểm-danh/chụp/kết-thúc trên phone — tái dùng StepRecord).
3. **Nâng Realtime** cho Classroom Trio (phone khác máy — đổi `createTransport()`).

*Boot phiên sau → audit D1 → đề xuất (D98) → build → nghiệm thu login thật (D2/D3) → verify đúng-nguồn (D113) → HANDOFF v45. "Tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*

> **Demo accounts (luôn kèm khi nhờ test):** GV KHM Mỹ Linh `gv.linh.kidshouse@demo.demenart.com` / `Test@123`. Session demo "Tiếng mưa rơi" = `aaaa0000-0000-4000-8000-0000000a0001` (Phần listen→audio mưa `34ad7ff4`, Phần move→"Chú Vịt Con" `93ddea79`). Classroom Trio: `/teacher/classroom?session=<id>` + `/teacher/remote?session=<id>` (same-laptop BroadcastChannel).
