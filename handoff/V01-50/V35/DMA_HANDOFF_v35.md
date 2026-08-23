# 🤝 DMA_HANDOFF_v35.md — BÀN GIAO PHIÊN (HOÀN TẤT TẦNG 1 MÓNG-CHUNG: THÔNG BÁO + THƯ VIỆN ÂM + GIAO DIỆN — 2026-06-29 17:24 GMT+7)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v35. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết (D1).
> **Naming:** DMA = nền tảng (`demenart.com`); CTAN = sản phẩm đầu. DMWS = business workshop riêng — chỉ blueprint pattern, KHÔNG cùng hệ. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

Nối tiếp v34 (đã dựng Móng Tra Cứu 3 lớp). Phiên này **hoàn tất Tầng 1 móng-dùng-chung** — 3 màn admin quản trị tài nguyên "trước-sau-gì-cũng-dùng" (thông báo/âm/giao diện). Engine ở DB đã có sẵn từ trước (v34 audit lộ), phiên này chủ yếu **thuần UI + 1 Edge + 1 mig nhỏ + tạo zone Bunny mới**. Chọn nhánh (A) của v34 — móng-chung trước nội thất.

**Lát 1 — Màn Thông báo `/admin/notifications`** (KHÔNG mig): edit-only 10 loại `notification_types` (tiêu đề · mẫu nội dung `{child}` · đối tượng · vị trí · âm báo · bật/tắt), Lưu theo dòng. RLS admin SELECT+UPDATE đã sẵn. Nghiệm thu login thật super_admin ĐẠT (sửa `moment_new` ghi DB thật).

**Lát 2 — Thư viện âm `/admin/notification-sounds`** (CẦN mig 057 + seed 014 + Edge mới + zone Bunny):
- **Tạo zone `dma-public`** (audit D1 lộ memory sai: "3 zones" thực ra chỉ 2 — `dma-learning`+`dma-private`; `dma-public` CHƯA tồn tại). Jean tạo: Storage Zone `dma-public` (region **Singapore SG** khớp `sg.storage.bunnycdn.com`) + Pull Zone `dma-public` (origin=storage, **token OFF**, host `dma-public.b-cdn.net`) + secret `BUNNY_PUBLIC_STORAGE_KEY` (= **Password read-write** của storage, KHÔNG read-only).
- **mig 057** (3-khối D92): SELECT `authenticated` where `is_enabled` cho `notification_sounds` (để cổng PH/GV đọc phát âm) + giữ admin ALL + thu hồi anon rõ.
- **seed 014** (idempotent NOT EXISTS): 3 âm `soft`/`chime`/`alert`, `bunny_path`=null tới khi upload.
- **Edge mới `upload_notification_sound`** (Edge thứ 7): gác admin qua **probe `admin_module_groups` bằng userClient** (RLS `is_admin()` chạy đúng context — KHÔNG hardcode role); PUT lên `dma-public` (nhân khuôn `putBunny` của `upload_media`); tự cập nhật `bunny_path`. **Verify JWT OFF** (hàm tự gác).
- **UI**: list/thêm/sửa/bật-tắt âm + chọn file → upload → nghe thử. CRUD dòng âm = client qua RLS admin; chỉ PUT-file đi Edge.
- Nghiệm thu ĐẠT: upload `chime` → 3 file thật trên storage → URL CDN phát được (sau khi đổi mạng — **NXDOMAIN ban đầu = DNS chưa lan, KHÔNG phải bug**).

**Lát 3 — Giao diện & Ngôn ngữ `/admin/settings`** (KHÔNG mig): đọc/ghi `app_settings` data-driven theo `group_name` (footer/contact/social/pwa/i18n — **ẩn nhóm `internal`**), Lưu theo dòng, key chứa `color` có swatch xem trước. RLS admin đã sẵn. Nghiệm thu ĐẠT (sửa `footer.intro` ghi thật). **Module registry `languages` mở rộng vai → "Giao diện & Ngôn ngữ"** (quản trọn `app_settings`, không chỉ i18n).

**Nav `/admin`** (`admin.tsx`): +3 link labeled "Thông báo" (Megaphone) · "Thư viện âm" (Music) · "Giao diện" (SlidersHorizontal); đổi aria chuông hộp-thư cũ → "Hộp thư thông báo" để khỏi lẫn. **Dashboard ruột `admin.index.tsx` KHÔNG đụng** (sơ sài từ v26 — để dành pass Nội thất, Quyết A Jean).

---

## 2. ⭐ NGHIỆM THU (login thật super_admin `info@demenart.com` — ĐẠT)

- **Lát 1:** nav có "Thông báo" · 10 thẻ render · sửa `moment_new` → "✓ Đã lưu" → reload còn → DB `updated_at` nhảy.
- **Lát 2:** seed 3 âm hiện · upload `chime` mp3 → "✓ Đã tải lên" → `bunny_path`=`/sounds/chime/efd669ac-…mp3` trong DB · 3 file thật trên Storage `dma-public/sounds/chime/` · URL CDN `dma-public.b-cdn.net/...` phát 0:02/0:03 (đổi mạng). Dropdown âm ở `/admin/notifications` hết nhãn "(chưa trong thư viện)".
- **Lát 3:** nav có "Giao diện" · 5 nhóm·11 cấu hình (ẩn internal) · sửa `footer.intro` → "✓ Đã lưu" → DB ghi đúng kiểu string jsonb.
- **Registry D106 (đã chạy):** 3 module `notifications`/`notification-sounds`/`languages` → `status='live'` + route thật + description đầy.
- **Dọn:** `footer.intro` xóa tiền tố test "1 - " về câu gốc.

---

## 3. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc (gần như KHÔNG đổi):** **52 bảng** (KHÔNG đổi) · **60 hàm SECURITY DEFINER** (KHÔNG đổi) · **137 RLS policy** (+1: `notification_sounds_select_enabled`) · **mig 001→057** · **seed 001→014** · **7 Edge** (+`upload_notification_sound`) · 3 tenant/3 master. SYSTEM_MAP **v0.32** (bump — +1 Edge + 1 policy + zone dma-public + 3 module live).
- **Edge Functions (7):** `get_signed_media_url` · `upload_media` · `resolve_share_link` · `invite_master` · `invite_staff` · `invite_parent` · **`upload_notification_sound`** (MỚI).
- **Bunny zones (nay 3 — ĐÚNG memory cũ):** `dma-public` (MỚI — public, token OFF, host `dma-public.b-cdn.net`, storage SG) · `dma-learning` (token on) · `dma-private` (token on).
- **Routes app:** 5 cổng + `/portal` shell + `/kid` reserved. **MỚI 3 route admin:** `admin.notifications.tsx` · `admin.notification-sounds.tsx` · `admin.settings.tsx`.
- **Teacher V1 vẫn COMPLETE** · Tra Cứu v34 sống · không đụng phiên này.

> **Data state:** `notification_sounds` = 3 dòng (`chime` có bunny_path thật từ test; `soft`/`alert` path=null). `notification_types` GIỮ 10 seed (chỉ `moment_new` từng sửa test rồi trả lại). `app_settings` GIỮ 12 dòng (`footer.intro` đã dọn). **`pwa.theme_color` VẪN `#E11D63` (hồng cũ) — Jean CHỦ ĐỘNG giữ, đổi sau khi chốt theme mới.** Mọi consent/journal từ v33 không đổi.

---

## 4. FILE PHIÊN NÀY

**Migration + seed (Jean lưu repo — D90):**
- `057_notification_sounds_public_read.sql` — SELECT authenticated(is_enabled) + grant/revoke (3 khối D92).
- `seed_014_notification_sounds.sql` — 3 âm soft/chime/alert (idempotent NOT EXISTS).

**Edge (Jean deploy — Verify JWT OFF):**
- `supabase/functions/upload_notification_sound/index.ts` (**MỚI** — Edge thứ 7).

**UI (Jean áp Lovable full paste-over):**
- `src/routes/_authenticated/admin.notifications.tsx` (**MỚI**)
- `src/routes/_authenticated/admin.notification-sounds.tsx` (**MỚI**)
- `src/routes/_authenticated/admin.settings.tsx` (**MỚI**)
- `src/routes/_authenticated/admin.tsx` (SỬA — +3 nav link)

**Secret (Jean set Supabase):** `BUNNY_PUBLIC_STORAGE_KEY` = Password read-write của storage zone `dma-public`.

**SQL lẻ đã chạy:** 3 UPDATE registry (notifications/notification-sounds/languages → live) · dọn `footer.intro`.

**3 file library:** `DMA_HANDOFF_v35.md` · `DMA_RULES.md` (+D108 + footer) · `DMA_SYSTEM_MAP.md` (v0.32 + footer).

---

## 5. VIỆC TREO

**🟢 Móng-chung (Tầng 1 — XONG TRỌN; còn polish nhỏ không chặn):**
- Upload âm cho `soft`/`alert` (mới có `chime`); cân nhắc seed sẵn 3 file âm chuẩn.
- (Tương lai) chuyển host `dma-public.b-cdn.net` vào `app_settings` khi cổng PH/GV bắt đầu PHÁT âm thật — giờ hardcode trong UI là đủ.
- Edge `upload_notification_sound` chưa ghi audit (chủ đích — asset hệ thống nhẹ); thêm sau nếu cần.

**🟢 Tra Cứu (mang từ v34):** điền `route` ~50 module còn trống · SVG graph tab Sơ đồ · UI sửa registry trong app.

**🟡 Nợ cũ mang theo:**
- **Lưu repo:** `057`+`seed_014`+Edge `upload_notification_sound` (mới) + nợ cũ `045`(v28)+`051-055`(v32/33)+`056`+`seed_013`(v34) + 2 Edge `invite_staff.ts`/`invite_parent.ts`(v22).
- Teacher: tab Nhật ký/Hồ sơ (build hay giữ khoá) · reaction "Lời cảm ơn" (flex) · desktop nav `/teacher/classes` · land GV `/teacher`.
- **Dashboard ruột `/admin` sơ sài** (admin.index.tsx — Quyết A để dành Nội thất).
- Dọn seed `[v29-test]`+`demo_seed`. 2 PH email-null. GV/PH pilot chưa login. 2 file nhạc curriculum. Vercel dormant. **Lock 1 linh vật** (3 phân vai đã rõ — chừa node reserved).
- **Đổi `pwa.theme_color` `#E11D63`→brand** khi Jean chốt theme mới (Jean tự làm qua `/admin/settings`).

---

## 6. KẾ HOẠCH PHIÊN SAU

Boot sạch → audit D1 → chọn 1 nhánh:

- **(A) Vào NỘI THẤT V1** — **Parent trước** (linh hồn + engine `get_child_journal` sẵn nhất, khớp mockup ảnh-2), rồi School. **KHÔNG chọn lại thẩm mỹ** (đã chốt D98: mở rộng ngôn ngữ Teacher đã build — kem ấm `#FBF8F1` + xanh-rừng `#149A76` + honey `#EFA63A`; mỗi cổng accent-tint riêng, Parent=amber). Cửa `/kid` khoá "Sắp ra mắt" ở `/parent`. **Dashboard ruột `/admin` cũng làm đẹp trong pass này.** *(recommend — gần pilot nhất, mặt khách-hàng-cuối)*
- **(B) Dọn nợ repo** — dump toàn bộ mig/seed/Edge còn treo lên GitHub (giỏ nợ đang phình: 045/051-057 + seed_013/014 + 3 Edge). Phiên repo thuần, không đụng schema.

> **D106 nhắc:** phiên sau thêm/sửa module hay flow → cập nhật registry TRƯỚC khi đóng. Quên = phiên chưa đóng.

Đóng = HANDOFF v36.

---

*Tầng 1 móng-dùng-chung (Thông báo + Thư viện âm + Giao diện) sống — tài nguyên trước-sau-gì-cũng-dùng đã build-shared-trong-Admin, các cổng khác gọi ra. Đúng nguyên tắc v34. Engine có sẵn ở DB từ trước → phiên này chủ yếu mặc UI + 1 Edge + tạo zone dma-public. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
