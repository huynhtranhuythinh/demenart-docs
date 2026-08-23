# DMA_HANDOFF_v57.md — GIAO CA PHIÊN

> **Đọc kèm:** `DMA_00_START_HERE.md` → `DMA_RULES.md` (đến **D177**) → `DMA_SYSTEM_MAP.md` (**v0.52**). Đây là handoff mới nhất.
> **Phiên này:** Notification Hub **làn-2b — Tầng trình bày** (Jean đặt hàng ở v56). **Ngày:** 2026-07-06 (GMT+7).

---

## 1. LÀM GÌ PHIÊN NÀY (tóm tắt 1 câu)

Hoàn tất **tầng trình bày** cho Notification Hub: nuôi `notification_types` thành registry điều khiển hành vi (thêm **kiểu hiển thị**), và dựng **client presenter** để khi nhận nudge (D175) thì hiển thị đúng kiểu (toast trượt / popup giữa màn / thầm lặng) + phát đúng tiếng + chớp nháy — bù đúng phần "mới có badge thầm lặng" mà v56 ghi còn thiếu.

---

## 2. ĐÃ SHIP (đã publish production, nghiệm thu login thật PH Hùng qua ảnh)

### 2.1. DB — mig 096 (chỉ +1 cột, additive thuần)
- Thêm cột **`notification_types.display_style`** ∈ {`silent`,`toast`,`popup`} — NOT NULL default `'toast'` + CHECK constraint. Code cũ bỏ qua hoàn toàn (không đụng RLS/data/engine).
- Backfill mặc định theo loại: `consent_request` + `license_expiring` → **popup**; `share_created` → **silent**; còn lại → **toast**.
- Cập nhật `description` module `notifications` (registry — D106/KỶ LUẬT VÀNG).
- **3 trục trực giao (D176):** `display_style` (KIỂU) · `position` (CHỖ toast, 6 vị trí, sẵn có) · `sound` (slug→`notification_sounds`, sẵn có). Không gộp.

### 2.2. Config UI — `admin.notifications.tsx` (agent, 1.9 credit, get_diff sạch)
- Thêm dropdown **"Kiểu hiển thị"** (Toast trượt / Popup giữa màn / Thầm lặng). Khối chuyển 3→4 dropdown, lưới 2×2: Kiểu · Đối tượng · Vị trí · Âm báo.
- Cast `as unknown` cho `tRes.data` (types.ts generated chưa biết cột mới → né TS strict, KHÔNG sửa types.ts).

### 2.3. Client presenter — `@/components/portal/NotificationPresenter.tsx` MỚI (agent, 3.3 credit)
- **Mount DUY NHẤT 1 chỗ** ở `_authenticated/route.tsx` (layout gate phủ cả 4 portal) — KHÔNG cắm 4 shell (D177).
- Tự subscribe `notif:{profileId}`; on nudge → refetch `read=false AND created_at > lastSeen` (join `notification_types`) → render:
  - **silent** = chỉ badge (không toast/tiếng)
  - **toast** = thẻ kem trượt theo `position`, tự tắt 6s, viền honey **chớp 1 nhịp**
  - **popup** = thẻ giữa màn + backdrop + nút "Đã hiểu"
- **Tiếng** = best-effort từ zone công khai `dma-public` (`https://dma-public.b-cdn.net`+bunny_path); autoplay bị chặn thì bỏ qua êm, hình vẫn hiện. Phát ĐỘC LẬP với popup (popup mở không nuốt tiếng).
- **Kỷ luật (D177):** `lastSeen=now()` lúc mount (không blast thông báo cũ) · seen-set dedupe theo id · **SUPPRESS** khi ở `/teacher/classroom` + `/remote` (chỉ badge, không phá buổi chiếu) · **badge unread do shell tự lo — hook cũ KHÔNG đụng** (presenter thuần additive, badge còn chạy dù presenter lỗi).

### 2.4. Nghiệm thu (bắn thật qua `create_notification` cho PH Hùng)
- Toast trượt góc trên-phải "bé An có khoảnh khắc mới" + tiếng **chime** ✅
- Popup giữa màn "Cần xác nhận quyền riêng tư" + "Đã hiểu" (loại này gán `soft` — chưa có file → im, đúng cấu hình) ✅
- 3 toast liên tiếp cách 5s = **3 tiếng tách biệt** → chứng tiếng độc lập, không chặn nhau ✅
- Badge nhảy đúng, list hiển thị đủ 2 loại. Dọn sạch 5 notif test sau nghiệm thu (Jean chọn A).

---

## 3. TRẠNG THÁI DB (audit live cuối phiên)

**61 bảng · 103 SECURITY DEFINER · 153 policy · mig 001→096 · admin_modules 62 · Edge 13 · cron 1 active · 3 trường.**

So v56: **KHÔNG đổi cấu trúc** — chỉ +1 cột `display_style` trên `notification_types`. (Lưu ý sổ sách: v56 handoff ghi 101 hàm definer nhưng audit live = 103; live là chân lý — D112, không có hàm lạ, chỉ lệch đếm.)

---

## 4. VIỆC TAY JEAN (⚠️ chưa xong)

- 🟡 **Giải nén backup vào GitHub repo:** `DMA_repo_backup_093-095.zip` (từ v56) + mig 096 phiên này (khi Jean muốn em đóng gói). Repo cần đủ mig 001→096 + 13 Edge.
- 🟢 **Verify cron đêm đầu** (nợ mang từ v55/v56): `cron.job_run_details` + `get_logs` — lần chạy có-chìa-khoá đầu tiên **02:15 rạng 7/7** (chưa tới lúc kiểm phiên này).

---

## 5. VIỆC TREO (ngã kế)

- **Làn-2b mở rộng (nếu muốn):** upload file âm cho `soft` + `alert` ở `/admin/notification-sounds` (hiện chỉ `chime` có file) → popup/các loại khác cũng kêu; hoặc âm/kiểu theo VAI (per-role) nếu cần. *Hạ tầng đã sẵn — chỉ thêm data.*
- 🔴 **"Try to fix all" Lovable — ĐỪNG BẤM** (D5/D14).
- **Kid V2.2** — thêm hoạt động/adventure cho cổng bé (đã khử cạnh tranh, giữ linh hồn).
- **Parent portal 3-tier privacy label** cho moments (cần consent field trong `get_school_moments`).
- Giai điệu cue TV mới · Bunny cleanup nếu còn.

---

## 6. NGÃ KẾ (chọn đầu phiên sau)

1. **Kid V2.2** — mở rộng hoạt động cổng bé (sprint vừa).
2. **Upload âm bổ sung** cho `soft`/`alert` → hoàn thiện tiếng cho mọi loại thông báo (lát nhỏ, đã có sẵn màn upload).
3. Lát nhỏ tuỳ hứng (3-tier privacy · giai điệu cue).

---

## 7. KỶ LUẬT GIỮ NGUYÊN (nhắc nhanh)

D1 audit live · D92 3-khối · D15 re-grant · D95 file trọn · D90/D112 dump-từ-live + reconcile (phiên này đã reconcile RULES/SYSTEM_MAP tụt-2-phiên về đúng live) · D106 registry ngay · D116/D117 đọc source thật trước khi mirror/paste · D134 auto-áp + get_diff từng lượt · D164 Edge anon tự gate + channel key ngẫu nhiên · D173 Edge backup qua get_edge_function · **D174 cổng Kid = Edge-gated session (bé không auth.uid → không postgres_changes) + Broadcast kick theo reason** · **D175 doctrine 2-làn realtime (điều khiển = Broadcast key ngẫu nhiên; notification = dòng DB + nudge rỗng → client refetch RLS)** · **D176 MỚI: `notification_types` = registry điều khiển hành vi, 3 trục trực giao (display_style/position/sound)** · **D177 MỚI: client presenter mount 1 chỗ `_authenticated/route.tsx`, lastSeen-guard + seen-dedupe + suppress-buổi-dạy + tiếng best-effort; badge shell tách biệt** · KHÔNG auto-publish đường phát để Jean test Preview.

*Handoff v57 — 2026-07-06 16:36 GMT+7. Nguồn: Tài liệu A–G + tầm nhìn founder + DMWS + live audit. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
