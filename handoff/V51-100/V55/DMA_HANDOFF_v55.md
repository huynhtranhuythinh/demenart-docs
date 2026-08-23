# 🧾 DMA_HANDOFF_v55.md — PHIÊN ĐÔI: ĐÓNG NỢ REPO TRỌN 079–092 + 7 EDGE (MD5 verify) · CHÚ VỊT CON PHẦN 4 SỐNG · POLISH (drift 057 · leaky sweep · secret cron SET) — 2026-07-06 09:31 GMT+7

> **Boot phiên sau:** đọc `DMA_00_START_HERE.md` → `DMA_RULES.md` → file này. Audit live trước khi viết code/SQL (D1).
> **Phiên này = 2 ngã liên tiếp (C rồi B), 0 credit Lovable, KHÔNG migration mới, KHÔNG đụng UI/route.** Mọi thay đổi live = 1 policy (đóng drift 057) + data demo (Chú Vịt Con).

---

## 0. TL;DR

- **Ngã C — nợ repo D90 đóng TRỌN:** dump verbatim **14 migration 079–092** từ `schema_migrations` (**verify MD5 khớp 14/14** với live) + **7 Edge** dump source nguyên văn từ live deploy qua tool MCP `Supabase:get_edge_function` (**D173 MỚI — hết thời copy tay Dashboard**). Giao gói `DMA_repo_backup_079-092.zip` (+ `MANIFEST_079_092.md`) — giải nén vào gốc repo là cây `supabase/migrations/` + `supabase/functions/` tự khớp. **Repo giờ đủ mig 001→092.**
- **⚠️ D112 bắt drift lần nữa:** v54 ghi nợ "086–092" nhưng audit thực = **079–092** (079–085 apply ở v52/v53 nhưng chưa từng giao repo — v52 chỉ giao tới 078). Gói này gom trọn.
- **Ngã B — Chú Vịt Con Phần 4 SỐNG:** Jean upload chuẩn qua `/admin/curriculum-admin` → media `b137bd7a-…f87c` (1.87MB, tự link đúng version demo `ac0a5c13`) → Phần 4 (move) thay nhạc-mưa-placeholder; Phần 1 (warmup) gỡ file hỏng về "Không học liệu" đúng thiết kế gốc v42; 2 file Chú Vịt Con hỏng cũ → `state='deleted'` + Jean đã xoá tay 2 byte mồ côi trên Bunny dma-learning. **Nghiệm thu login thật ĐẠT** (GV Mỹ Linh, 2 ảnh): Phần 1 "Không học liệu" · Phần 4 phát "Chú Vịt Con" 1:17 đang chiếu TV + watermark.
- **Polish:** đóng drift mig 057 (policy `notification_sounds_select_enabled` vào live → **150 policy**, gỡ dấu * treo từ v37) · leaky-grant sweep 93 secdef SẠCH (duy nhất `redeem_session_remote_code` anon — cố ý D131) · phát hiện 16 file deleted dma-private ĐÃ `bunny_purged` từ trước (mục treo "15 file mồ côi" thực ra đã xong — gạch sổ) · **🔴→✅ SECRET CRON ĐÃ SET** (`CRON_PURGE_SECRET` vào Edge Secrets 09:30 GMT+7 — cron đêm 02:15 từ nay chạy thật).

---

## 1. Trạng thái DB (audit live cuối phiên — D1)

- **56 bảng · 93 SECURITY DEFINER · migrations 001→092 · 150 RLS policy (+1: notification_sounds_select_enabled) · admin_modules 62 · Edge 12 · cron 1 active (secret ĐÃ SET) · 3 tenants.**
- **KHÔNG migration mới, KHÔNG hàm mới, KHÔNG route mới.** SYSTEM_MAP giữ **v0.50 (KHÔNG bump)**.
- Data demo đổi (chi tiết §3). 2 tệp test của Jean vẫn trong thùng rác — sẽ tự purge khi đủ 7 ngày (cron nay đã có chìa).

## 2. Mạch C — Gói backup repo 079–092 + 7 Edge

**Phương pháp (D90/D112/D173):**
- Mig = verbatim `array_to_string(statements)` từ `supabase_migrations.schema_migrations` (14 mig này đều apply qua MCP `apply_migration` nên có vết nguyên văn). **Verify MD5 file-vs-DB khớp 14/14** (079/080 DB content tự có newline cuối — file khớp tuyệt đối; 12 mig còn lại khớp khi cộng newline POSIX cuối file).
- Edge = source nguyên văn từ live deploy qua **`Supabase:get_edge_function`** — Jean KHÔNG cần copy tay từ Dashboard nữa (nâng cấp pattern v37 → **D173**).

**Nội dung gói (`DMA_repo_backup_079-092.zip` + `MANIFEST_079_092.md`):**
- `supabase/migrations/` 14 file: 079 journal sprint (get_teacher_journals + get_child_journal+note + session_marks) · 080 registry teacher-journal · 081/082/085 capture gate (remote_code → channel_key → bỏ trần moment) · 083 school_settings · 084 registry school-settings + backfill 33 desc · 086 drive_folders · 087 5 RPC drive + DATA dọn ngăn · 088 thùng rác + quota gồm rác · 089 vault secret + cron · 090 drive_my_zone · 091 registry teacher-media · 092 restore-path.
- `supabase/functions/` 7 file: `upload_media` v12 · `get_signed_media_url` v18 · `delete_session_media` v3 · `school_media_admin` v1 · `capture_session_media` v2 · `purge_trash` v1 · `capture_session_moment` v3 (stub 410 — snapshot trung thực). 5 Edge còn lại không đổi từ backup v19/v27/v37.
- MANIFEST ghi rõ: thứ tự phục hồi · lưu ý mig 089 replay tạo secret vault MỚI (D171 — giá trị không nằm repo) → sau restore phải copy sang `CRON_PURGE_SECRET` · danh sách env Edge cần.

## 3. Mạch B — Chú Vịt Con + dọn kho (DATA LIVE, không migration)

**Audit trước-fix (version demo `ac0a5c13`, buổi a0001):** move = nhạc mưa placeholder · warmup = file hỏng `bb9cd504` (size null, path `/Chu_Vit_Con.mp3` sai chuẩn) · `93ddea79-55e2-…` (1.7MB SRC hỏng) rác kho không gán đâu. ⚠️ id `93ddea79` trong v49 ghi đuôi khác — live mới là chân lý (D1).

**Thay đổi (1 transaction DO $$, guard counts 1/1/2 — lệch là RAISE rollback):**
1. `lesson_activity_media` (ac0a5c13, 'move'): `34ad7ff4` (mưa) → **`b137bd7a-5250-4575-885b-338c4127f87c`** ("Chú Vịt Con" mới, audio/mpeg 1.87MB, path `/curriculum/ac0a5c13/88a56557….mp3`, dma-learning, private_curriculum — UI curriculum-admin tự set đủ, không vá tay).
2. (ac0a5c13, 'warmup'): DELETE gán `bb9cd504` → Phần 1 về "Không học liệu".
3. `bb9cd504` + `93ddea79-55e2` → `state='deleted'`.

**Verify D113 + nghiệm thu thật ĐẠT** (GV Mỹ Linh `gv.linh.kidshouse@demo.demenart.com`/`Test@123`, 2 ảnh): Phần 1 badge "Không học liệu" + "Phần này không dùng học liệu trình diễn" · Phần 4 "Chú Vịt Con" 1:17 Đang phát + "Đang chiếu trên TV" + watermark trôi. **Bunny tay Jean ĐÃ XOÁ** 2 file dma-learning: `/Chu_Vit_Con.mp3` + `/curriculum/47c52596…/fe7a6eaf….mp3` (giữ nguyên `1269dc34….mp3` — nhạc mưa đang sống).

## 4. Polish đã xử

- **Drift mig 057 (treo v37) ĐÓNG:** live thiếu policy `notification_sounds_select_enabled` (PH/GV bị chặn đọc thư viện âm) → tạo đúng nội dung file repo 057 (`FOR SELECT TO authenticated USING (is_enabled = true)`) → notification_sounds đủ 2 policy, **tổng 150** (hết dấu *).
- **Leaky sweep 93 secdef:** chỉ `redeem_session_remote_code` có anon (cố ý D131); không hàm nào proacl NULL/PUBLIC. Sạch.
- **Mục treo "Dọn rác kho Bunny 15 file" = ĐÃ XONG TỪ TRƯỚC:** 16 file deleted dma-private đều mang cờ `bunny_purged` (Jean đã bấm nút mà sổ chưa gạch). Đóng.
- **🔴 SECRET CRON ĐÃ SET** (ảnh Dashboard 09:30 GMT+7): `CRON_PURGE_SECRET` nằm trong Edge Secrets, khớp vault. Đêm 02:15 HCM cron chạy thật lần đầu.

## 5. File đã đụng phiên này

**DB:** 1 policy (drift 057) + data (lesson_activity_media 2 thao tác · media_assets 2 state) — KHÔNG migration. **UI/Edge/route:** KHÔNG. **Giao Jean:** `DMA_repo_backup_079-092.zip` + `MANIFEST_079_092.md`. **Credits Lovable: 0.**

## 6. ⭐ Tài khoản test (luôn kèm khi nhờ Jean test — password `Test@123`, domain `@demo.demenart.com`)

GV Mỹ Linh `gv.linh.kidshouse` · Master KHM `hieutruong.kidshouse` (Nguyệt Thi) · PH Hùng `ph.hung.kidshouse` · Master MNDM `hieutruong.demen` (Phương Dung) · GV Hân `gv.han.demen` · PH Thành `ph.thanh.demen` · GV My `gv.my.kidshouse` (password tạm) · PH Toản `ph.toan.kidshouse` (password tạm) · Super admin `info@demenart.com` (password của Jean). Buổi demo: `aaaa0000-0000-4000-8000-0000000a0001` (lớp Hoa Hồng, "Tiếng mưa rơi").

## 7. VIỆC TREO

- 🟡 **Jean giải nén `DMA_repo_backup_079-092.zip` vào gốc repo GitHub backup** (gói đã giao trong chat phiên này).
- 🟢 **Verify cron đêm đầu (phiên sau, 1 phút):** đọc `cron.job_run_details` + `Supabase:get_logs` service edge-function — xác nhận purge_trash trả 200 (hết 403). 2 tệp test trong thùng rác sẽ tự bay khi đủ 7 ngày.
- 🔴 **"Try to fix all" 11 issues Lovable — CHƯA ĐỘNG, ĐỪNG BẤM** (D5/D14).
- `/kid` V2 (cửa khoá placeholder) · Thêm giai điệu cue TV mới (lát riêng nếu cần).

## 8. NGÃ KẾ (chọn đầu phiên sau)

1. **`/kid` V2** — cổng trẻ PIN-based + parent approval. Sổ sách giờ SẠCH TRỌN (repo đủ 001→092, secret set, demo chuẩn) — đúng lúc vào sprint lớn.
2. **Lát nhỏ tuỳ hứng** — giai điệu cue mới / verify cron / bất kỳ vết Jean thấy khi dùng.

## 9. Kỷ luật giữ nguyên (nhắc nhanh)

D1 audit live · D92 3-khối · D15 re-grant · D95 file trọn · D90/D112 dump-từ-live + reconcile (phiên này bắt drift lần 3: nợ 086–092 thực là 079–092) · D106 registry ngay · D113 verify đọc-thẳng-data · D134 auto-áp + get_diff · D168–D172 (drive/trash/cron/UI) · **D173 MỚI: Edge backup = `Supabase:get_edge_function` dump verbatim từ live deploy — KHÔNG copy tay Dashboard, KHÔNG tái dựng từ trí nhớ** · KHÔNG auto-publish đường phát, để Jean test Preview.

*Handoff v55 — 2026-07-06 09:31 GMT+7. Nguồn: Tài liệu A–G + tầm nhìn founder + DMWS. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
