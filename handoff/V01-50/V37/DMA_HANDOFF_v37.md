# 🧾 DMA_HANDOFF_v37.md — DỌN NỢ REPO TRỌN GIỎ (DUMP TỪ LIVE) — 2026-06-29 23:42 GMT+7

> **Boot phiên sau:** đọc `DMA_00_START_HERE.md` → `DMA_RULES.md` → file này. Audit live trước khi viết code (D1).
> **Phiên này = THUẦN REPO** (không đụng schema/RLS/Edge/route trên live). Mục tiêu: dump trọn giỏ nợ repo từ live DB (D90) → file `.sql`/`.ts` hoàn chỉnh để Jean lưu GitHub.

---

## ⭐ LÀM ĐƯỢC PHIÊN NÀY

Nối tiếp v36 (Admin Dashboard "Mission Control"). Jean chọn nhánh **(B) dọn nợ repo** trước khi vào Nội thất. Giỏ nợ phình từ v22→v36 nay **SẠCH TRỌN**.

### Phương pháp (D90/D96/D107 — không tái dựng từ trí nhớ)
- **Hàm + grants:** dump `pg_get_functiondef` + `aclexplode` từ live → tái tạo file + khối re-harden D15.
- **Bảng/RLS/FK/constraint:** dump `information_schema.columns` + `pg_get_constraintdef` + `pg_policies` + `pg_get_triggerdef` → dựng DDL.
- **Seed registry (013):** sinh SQL bằng script Python từ chính JSON dump live (tránh sai sót chép tay 55 module) → idempotent `ON CONFLICT`, giữ UUID live cho FK ổn định.
- **Edge:** Jean copy source nguyên văn từ Supabase Dashboard → đóng gói path `supabase/functions/<name>/index.ts`.

### File đã giao (đủ giỏ nợ)
**SQL migrations (gộp 8 file cho 9 mig):**
- `045_get_child_parents.sql` — replace nới gate read-only lead/assistant (v28).
- `051-053_session_recording.sql` — `skill_catalog` + UNIQUE(session_id,child_id) child_observations + moment_children DELETE policy + 3 RPC (`get_session_roster`/`get_session_moments`/`submit_session_journal`) (v32).
- `054_consent_group_default_on.sql` — `provision_parent_and_link` replace (+INSERT consent group default-on) + backfill idempotent NOT EXISTS (v33, D104).
- `055_get_teacher_classes.sql` — Tab "Lớp" 1-RPC nested (v33, D105).
- `056_reference_center_tables.sql` — 4 bảng registry + ALTER `status` 2 bảng cũ + 5 FK + RLS admin_all + 2 trigger (v34, D106/D107).
- `057_notification_sounds_public_read.sql` — policy `notification_sounds_select_enabled` (v35) — **xem PHÁT HIỆN bên dưới**.
- `058_admin_dashboard_rpcs.sql` — 5 RPC admin aggregate (v36, D108/D110).

**Seed (2 file):**
- `seed_013_registry.sql` — 13 nhóm · 55 module · 9 cạnh · 1 playbook · 5 bước (khớp đếm v34). Sinh từ JSON dump, ON CONFLICT(id)/(slug)/(uniq).
- `seed_014_notification_sounds.sql` — 3 âm thiết kế (soft/chime/alert); `chime` giữ `bunny_path` THẬT; soft/alert path=NULL.

**Edge (3 file, nguyên văn live):**
- `invite_staff/index.ts` · `invite_parent/index.ts` (nợ từ v22) · `upload_notification_sound/index.ts` (v35).

### Verify dump
- 11/11 hàm `leaky=false`, grantees đồng nhất `{authenticated,postgres,service_role}`.
- Registry đếm khớp: 13/55/9/1/5.
- Constraint/FK/trigger/RLS khớp dump live.

---

## ⚠️ 2 PHÁT HIỆN D1 (audit dump bắt được drift)

1. **Policy `notification_sounds_select_enabled` (mig 057) KHÔNG có trong live.** Dump `pg_policies` cho `notification_sounds` chỉ trả `notification_sounds_admin_all`. v35 ghi nhận đã áp 057 (+1 → 137 policy). Nếu thật sự vắng → **live đang ~136 policy, không phải 137**, và **PH/GV chưa đọc được thư viện âm** (chỉ admin). File `057` đã viết đúng thiết kế; chạy nó là khôi phục read-cho-authenticated. Chưa chặn (cổng PH/GV chưa phát âm thật — v35 hardcode host). **Cần xác nhận lại policy count khi vào phiên có đụng RLS.**
2. **`seed_014` = 3 âm thiết kế, live chỉ có `chime`.** Soft/alert chưa từng persist (3 file CDN cùng path chime = retry lúc DNS chưa map, DB ghi 1 dòng chime là ĐÚNG). Seed dựng lại bộ chuẩn 3 âm cho admin có lựa chọn.

---

## 📊 TRẠNG THÁI DB (KHÔNG ĐỔI — phiên thuần repo)
- **52 bảng · 65 hàm definer · 137 policy*** · mig **001→058** · seed 001→014 · **7 Edge** · 3 tenant/3 master.
  - *(*) policy: nếu `notification_sounds_select_enabled` vắng (phát hiện #1) thì thực tế **136** — cần xác nhận.*
- **SYSTEM_MAP KHÔNG bump** (giữ v0.33 — không đụng schema/route/Edge).
- **Giỏ nợ repo: SẠCH** (code+data) — mig 001→058 + functions/grants + 7 Edge + seed 000/demo001/010-014 + registry.

---

## 🆕 D-RULE MỚI — **D112** (append vào RULES hiện hành)
**D112 — Drift live↔handoff: dump-để-backup phải reconcile, không tin handoff = live.** Một object (policy/grant/cột) được handoff ghi "đã áp" CÓ THỂ vắng trong live (drift âm thầm — lần 2 dính: v3 "mig 010 đóng public execute" sai; v37 `notification_sounds_select_enabled` vắng dù v35 ghi +1). Khi dump repo: **audit live** (`pg_policies`/`pg_proc`/`aclexplode`) và đối chiếu thiết kế; nếu live THIẾU object thiết kế → viết file repo theo **thiết kế đúng** + **cờ rõ "live đang thiếu, chạy để khôi phục"**, KHÔNG giả định handoff = live. Hệ quả: policy count trong handoff cũng cần verify bằng dump, không cộng dồn niềm tin.

---

## 🔧 VIỆC TREO

**Mới phát sinh:**
- 🟡 Xác nhận lại policy count live + cân nhắc **chạy `057`** để khôi phục read thư viện âm cho PH/GV (trước khi cổng phát âm thật).

**Mang theo (chưa đụng):**
- 🟢 Nội thất School → Teacher (demo-grade, mặt khách ký license) — **kế tiếp đề xuất**.
- 🟢 Admin: wire nút "Xử lý" Action Center · re-theme trang con admin sang cosmic (D111) · điền `route` ~50 module → nav data-driven (gỡ hardcode D109).
- 🟡 Tinh chỉnh ngưỡng risk School Health (Kids House 50 = "Rủi ro" hơi gắt).
- 🟡 `get_admin_pulse` + reaction "Lời cảm ơn" khi có `demen_marketing` data.
- 🟡 Dọn seed `[v29-test]`+demo_seed · 2 PH email-null · GV/PH pilot chưa login · 2 file nhạc curriculum · Vercel dormant · **lock 1 linh vật** · blur-mặt V2 · đổi `pwa.theme_color` `#E11D63`→brand khi chốt theme.

**Library (⚠️ tụt phiên — sửa ngay):**
- Bản `DMA_RULES.md` trong project snapshot kết footer ở **v34** (thiếu D108–D111 + footer v35/v36). Bản Jean đang giữ là nguồn-thật. Phiên này KHÔNG ghi đè RULES từ snapshot cũ — chỉ append D112 + footer v37 vào bản hiện hành.

---

## ▶️ KẾ TIẾP (đề xuất)
**Nội thất School V1** (emerald, mở rộng ngôn ngữ kem-ấm đã chốt; mặt khách ký license — đúng thứ tự demo Jean chốt). Boot → audit D1 cổng School (RPC/route/data thật) trước khi đụng UI → HANDOFF v38.

*Phiên thuần repo theo khuôn v27. Dump thẳng từ live (D90), không tái dựng trí nhớ. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
