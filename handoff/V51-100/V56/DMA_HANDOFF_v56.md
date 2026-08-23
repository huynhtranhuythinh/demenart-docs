# DMA_HANDOFF_v56.md — GIAO CA PHIÊN

> **Đọc kèm:** `DMA_00_START_HERE.md` → `DMA_RULES.md` (đến D175) → `DMA_SYSTEM_MAP.md` (v0.51). Đây là handoff mới nhất.
> **Phiên này:** /kid V2 (Sprint lớn K1–K4) + nâng Realtime Broadcast + Notification Hub làn-2. **Ngày:** 2026-07-06 (GMT+7).

---

## 1. LÀM GÌ PHIÊN NÀY (tóm tắt 1 câu)

Dựng trọn **cổng Kid V2** (trẻ PIN-based, ba mẹ duyệt) từ móng DB đến UI; nâng cấp cả cổng Kid **và** hệ thông báo toàn hệ thống lên **realtime thật** (Supabase Realtime Broadcast), đặt nền **Notification Hub 2-làn** dùng chung cho mọi feature.

---

## 2. ĐÃ SHIP (đã publish production, nghiệm thu login thật đầy đủ qua ảnh)

### 2.1. /kid V2 — cổng trẻ PIN-based (K1–K4)
- **K1 — móng DB (mig 093):** 5 bảng `kid_access` (PIN bcrypt + khung giờ jsonb + lockout 5-sai-khoá-15') · `kid_devices` (thiết bị ghép, token sha256) · `kid_pairing_codes` (mã 6 số, hạn 10') · `kid_sessions` (phiên 60', token sha256) · `kid_reactions` (❤️⭐🌈🎵👏, unique child×moment, KHÔNG đếm/xếp hạng). 9 RPC: PH-facing (set_pin/update_access/create_pairing_code/revoke_device) + service-only (pair/login/album/react).
- **K2 — Edge `kid_gate`:** một cổng, actions `pair·login·album·ping·react·logout`. Bé KHÔNG có `auth.uid()` (G149/G160) → mọi truy cập qua Edge service-side, không RLS self-query. Album = subset an toàn (moments approved + badges + skills, KHÔNG teacher note, KHÔNG so sánh); ảnh ký URL tại chỗ gương `get_signed_media_url`. Audit `actor_id=null` + `metadata.kid_child_id` (D88 — bé không mượn danh ai).
- **K3 — `/parent/kid` "Cổng của bé":** bật/tắt cổng · khung giờ (2 ô time) · đặt PIN 4 số (InputOTP) · ghép thiết bị (mã 6 số) + danh sách thiết bị + thu hồi. Nav "Cổng của bé" (KeyRound) trong `parent.tsx`.
- **K4 — `/kid` công khai:** state machine pair→pin→album + locked/outside/blocked. Bàn phím số to cho bé mầm non, dialog reaction 5 emoji, album ấm (khoảnh khắc/huy hiệu/hạt giống/hành trình). Không so sánh, không số liệu.

### 2.2. Realtime thật cho /kid (mig 094)
- `kid_sessions.channel_key` (ngẫu nhiên mint lúc login, pattern D164). Thu hồi/tắt cổng → RPC bắn `kick` (kèm reason `revoked`/`disabled`) qua `realtime.send` → bé văng TỨC THÌ. Ghép xong → bắn `paired` cho PH đang chờ → mã tự ẩn + toast, KHÔNG refresh.
- Polling hạ xuống **lưới an toàn**: bé ping 60s + on-focus; PH refresh 30s.
- **Kick routing theo reason (vá sau nghiệm thu):** `revoked` → về màn **nhập mã kết nối** (xoá ghép, hết ngõ cụt PIN) · `disabled` → màn "💛 Nhờ ba mẹ mở cổng" (thiết bị vẫn ghép) · else → màn PIN. Cả 4 đường (broadcast/ping/album/react) đều phân loại; `kid_gate` v4 thêm `device_revoked` cho ping.

### 2.3. Notification Hub làn-2 (mig 095)
- Trigger `notifications_broadcast_new` AFTER INSERT → bắn nudge RỖNG NỘI DUNG vào `notif:{profile_id}` → **mọi feature chỉ cần insert notification là tự động realtime**, không viết thêm code realtime.
- Hook `useRealtimeNotifications(profileId, onNew)` dùng chung; gắn vào **cả 5 shell** (parent/teacher/school/admin/**portal**) + `NotificationsView`. Poll cũ 30s → 60s (dự phòng). Chuông nhảy tức thì (nghiệm thu 2 phát bắn thật, PH Hùng).

---

## 3. TRẠNG THÁI DB (audit live cuối phiên)

**61 bảng · 101 SECURITY DEFINER · 153 policy · mig 001→095 · admin_modules 62 · Edge 13 · cron 1 active · 3 tenant.**

- Bảng +5: kid_access, kid_devices, kid_pairing_codes, kid_sessions, kid_reactions.
- Hàm definer +8 nhóm kid + 1 broadcast helper + 1 notify trigger fn (so v55: 93 → 101).
- Policy +3 (kid_access/devices/reactions SELECT parent).
- Edge +1: `kid_gate` (v4). Tổng 13.

---

## 4. VIỆC TAY JEAN (⚠️ chưa xong)

- 🟡 **Giải nén backup vào GitHub repo:** `DMA_repo_backup_093-095.zip` (mig 093–095 + `kid_gate` v4) + zip 079–092 từ v55 (nếu chưa commit). Repo đủ mig 001→095 + 13 Edge sau khi giải nén.
- 🟢 **Verify cron đêm đầu** (nợ mang từ v55): `cron.job_run_details` + `get_logs` — lần chạy có-chìa-khoá đầu tiên là 02:15 rạng 7/7.

---

## 5. VIỆC TREO (ngã kế)

- ⭐ **Notification Hub làn-2b — CONFIG ADMIN (Jean đặt hàng rõ):** nuôi `notification_types` thành **registry điều khiển hành vi** — mỗi loại có bật/tắt, **kiểu hiển thị** (badge thầm lặng / toast trượt / popup giữa màn), **tiếng chuông** (chọn từ `notification_sounds`, bảng đã có), có thể theo vai. Admin chỉnh trong `/admin`; client đọc config lúc nhận nudge → hiển thị đúng kiểu + phát đúng tiếng + **chớp nháy**. HIỆN mới có badge thầm lặng (chưa âm thanh/animation) — đây là tầng trình bày còn thiếu. → **ngã mở đầu phiên sau.**
- 🔴 **"Try to fix all" Lovable — CHƯA ĐỘNG, ĐỪNG BẤM** (D5/D14).
- Giai điệu cue TV mới (lát nhỏ) · Bunny cleanup nếu còn · Parent portal 3-tier privacy label moments.

---

## 6. NGÃ KẾ (chọn đầu phiên sau)

1. **Notification Hub làn-2b — Config Admin** (đổi tiếng chuông / kiểu hiển thị toast·popup / bật-tắt loại + tầng trình bày âm thanh+animation). ⭐ Jean đã đặt hàng, tiếp mạch tự nhiên.
2. **Kid V2.2** — thêm hoạt động/adventure nếu muốn mở rộng (đã khử cạnh tranh, giữ linh hồn).
3. Lát nhỏ tuỳ hứng.

---

## 7. KỶ LUẬT GIỮ NGUYÊN (nhắc nhanh)

D1 audit live · D92 3-khối · D15 re-grant · D95 file trọn · D90/D112 dump-từ-live + reconcile · D106 registry ngay · D113 verify đọc-thẳng-data · D116/D117 đọc source thật trước khi mirror/paste · D134 auto-áp + get_diff từng lượt · D164 Edge anon tự gate + channel key ngẫu nhiên · D171 cron vault secret · D173 Edge backup qua get_edge_function · **D174 MỚI: cổng Kid = Edge-gated session (bé không auth.uid → không postgres_changes, mọi truy cập qua Edge service-side) + Broadcast kick theo reason** · **D175 MỚI: doctrine 2-làn realtime (tín hiệu điều khiển = Broadcast key ngẫu nhiên; thông báo bền vững = dòng DB + trigger nudge rỗng → client refetch qua RLS)** · KHÔNG auto-publish đường phát để Jean test Preview.

*Handoff v56 — 2026-07-06 14:30 GMT+7. Nguồn: Tài liệu A–G + tầm nhìn founder + DMWS. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
