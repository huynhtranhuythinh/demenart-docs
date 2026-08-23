# 🧾 DMA_HANDOFF_v54.md — SPRINT ORG DRIVE & TEACHER DRIVE (cây thư mục 3 cấp · thùng rác restore-dựng-lại-cây · cron dọn đêm · DriveExplorer + Học liệu của tôi) — 2026-07-06 00:49 GMT+7

> **Boot phiên sau:** đọc `DMA_00_START_HERE.md` → `DMA_RULES.md` → file này. Audit live trước khi viết code/SQL (D1).
> **Phiên này = 1 sprint lớn 3 tầng (DB → Edge → UI), TẤT CẢ đã publish production + nghiệm thu thật 18 ảnh (Master + GV) qua 2 vòng:** vòng 1 build trọn; vòng 2 vá 2 lỗi Jean bắt được (menu ⋯ bị che · restore phải dựng lại thư mục).

---

## 0. TL;DR

- **Org Drive (D168):** kho media trường thành cây Finder-like 3 cấp — **Gốc kho (Master) → Ngăn từng GV → thư mục con**. Cây LOGIC trong DB (`media_assets.folder_id`), không đổi path Bunny, không đụng `session_media` → di chuyển file không bao giờ vỡ tiết đang dạy. Đọc MỞ cả trường (scoped-model DMWS); thao tác file theo `uploaded_by`, folder theo `owner_profile_id`, owner đi theo lãnh thổ khi move. BỎ hẳn Copy/Paste (copy = nhân đôi byte Bunny).
- **Thùng rác (D169/D170):** xoá folder = xoá cả ruột (cảnh báo) nhưng file vào thùng rác — **quota vẫn tính đến khi purge** (chống lách); Khôi phục **dựng lại nguyên chuỗi thư mục** từ snapshot path (mig 092 — Jean bác bản "file về gốc, folder mất"); tự dọn sau 7 ngày (school_settings key, D167); purge 2 pha an toàn (Bunny fail → đêm sau thử lại).
- **Cron đêm (D171):** `purge-drive-trash-nightly` 02:15 giờ HCM — pg_cron + pg_net + secret trong Vault → Edge `purge_trash` gate `x-cron-secret`. ⚠️ Còn 1 việc tay Jean (mục 7).
- **Chụp/Quay từ Remote giờ tự xếp ngăn nắp:** Ngăn GV → "Chụp tại lớp" → YYYY-MM-DD.
- **UI:** component chung `DriveExplorer` (kéo-thả nội bộ + upload từ Finder + thùng rác + **fix tile video vỡ**) · `/school/drive` thay ruột · route MỚI `/teacher/media` "Học liệu của tôi" (GV tự lãnh ngăn qua `drive_my_zone`).

---

## 1. Trạng thái DB (audit live cuối phiên — D1/D90)

- **56 bảng (+`drive_folders`) · 93 SECURITY DEFINER · migrations 001→092 · admin_modules 62 · Edge 12 · cron 1 active · 3 tenants.**
- Mig 086–092 apply qua **MCP `apply_migration`** → có vết `supabase_migrations.schema_migrations` (khỏi nợ D90). Grants verify sạch mọi vòng (aclexplode, leaky=[]); body verify qua `pg_get_functiondef` (D114).
- Thực địa lúc đóng phiên: 2 tệp đang nằm thùng rác (test của Jean), quota 25.5/5000 MB (KHM).

| Mig | Nội dung |
|---|---|
| 086 | Bảng **`drive_folders`** (unique tên-per-parent COALESCE sentinel + lower · unique zone-root (school,owner) WHERE parent NULL · RLS 4 policy: SELECT same_school / write admin OR owner=me) + `media_assets.folder_id` FK SET NULL |
| 087 | 5 RPC drive: `drive_ensure_path` (**service_role only**, idempotent, chống race) · `drive_list` (breadcrumb + folders + files + can_write + quota) · `drive_create_folder` (gốc = master-only) · `drive_rename` (folder / file-title jsonb_set) · `drive_move` (chống cycle recursive-CTE, cấm zone root, owner cả subtree theo ĐÍCH) + **DATA:** dọn 10 file cũ vào ngăn "Đặng Mỹ Linh" (`ea33649f-…`) |
| 088 | Thùng rác: cột `trashed_at`/`trashed_by`/`restore_folder_id` + `drive_trash_retention_days` (school_settings fb 7) + `drive_trash`/`drive_list_trash`/`drive_restore` + purge 2 pha `drive_purge_expired_list`/`drive_purge_finalize` (**service_role only**) + CREATE EXTENSION pg_cron/pg_net + **REPLACE 3 hàm quota → đếm active+trashed** |
| 089 | `vault.create_secret(gen_random_uuid())` 'cron_purge_secret' + `cron.schedule` '15 19 * * *' UTC (=02:15 HCM) net.http_post → Edge purge_trash, header đọc từ vault mỗi lần chạy |
| 090 | `drive_my_zone(p_school_id)` — GV tự lãnh ngăn (tạo nếu chưa có), authenticated |
| 091 | Registry D106: +module `teacher-media` (route /teacher/media, đủ 4 trường) + update school-drive → cạnh 2 chiều · **62 module** |
| 092 | **Restore-dựng-lại-cây (vá sau nghiệm thu):** cột `restore_owner_profile_id` + `restore_path text[]` · `drive_folder_pathinfo` (loại tên zone-root) · REPLACE `drive_trash`/`drive_restore`/`drive_list_trash` (snapshot mọi cửa + "sẽ về: <path>") · `drive_trash_media_service` (**service_role only** — cho Edge) |

## 2. Edge Functions (12)

| Edge | Bản | Đổi gì |
|---|---|---|
| `capture_session_media` | **v2** | quota gồm rác (`.in state active,trashed`) + `drive_ensure_path(school, cô-chính, ["Chụp tại lớp", YYYY-MM-DD giờ HCM])` → insert `folder_id` (lỗi folder KHÔNG chặn upload — file rơi về gốc ngăn) |
| `upload_media` | **v12** | (1) nhánh C: folder đích = form `folder_id` (validate cùng trường + owner/admin) hoặc gốc Ngăn GV; (2) **NHÁNH D MỚI** — form chỉ `folder_id` = kéo-thả Finder vào Drive: gate cùng trường + (master OR chủ ngăn), quota, dma-private `/school/{school}/`, KHÔNG gắn buổi, metadata source `drive_upload`; (3) quota gồm rác. Nhánh A (ảnh trẻ) + B (học liệu) GIỮ NGUYÊN verbatim |
| `delete_session_media` | **v3** | gỡ link như cũ; mồ côi → RPC `drive_trash_media_service` (state='trashed' KÈM snapshot path — D170), **KHÔNG xoá Bunny** |
| `purge_trash` | **v1 MỚI** | verify_jwt=false + gate header `x-cron-secret === env CRON_PURGE_SECRET`; flow: purge_expired_list → Bunny DELETE từng file (`sg.storage.bunnycdn.com`, key BUNNY_PRIVATE_STORAGE_KEY; 404 vẫn finalize) → purge_finalize. Fail → giữ trashed đêm sau thử lại |

8 Edge còn lại KHÔNG đổi. ⏳ **Repo tay Jean:** 5 nợ cũ (4 file v52 + capture v1) nay thành **9 file** (thêm capture v2, upload v12, delete v3, purge_trash v1) — copy từ Dashboard pattern v37.

## 3. UI (Lovable — auto-áp agent, get_diff sạch từng lượt, đã publish; ~11.3 credits)

- **`src/components/portal/DriveExplorer.tsx` MỚI (shared D115):** quota bar (+dòng "🗑 Thùng rác đang chiếm X MB — tự dọn sau N ngày") · breadcrumb "Kho của trường › …" (mỗi mấu = drop-target) · toolbar Tạo thư mục / sort Tên-Mới-Dung lượng-Loại / grid-list / Thùng rác · tile folder (zone root = 🧑 + "Ngăn của <tên>") · tile file (**video `<video preload="metadata" muted playsInline>` — FIX vỡ tile**, badge "Đang dùng N buổi") · menu ⋯ Đổi tên/Di chuyển (dialog navigator, disable khi không có quyền đích)/Bỏ vào thùng rác (folder = cảnh báo xoá-cả-ruột) · multi-select Ctrl/Cmd + action bar nổi · kéo-thả nội bộ (`application/x-dma-drive`) · kéo-thả TỪ FINDER (overlay "Thả để tải vào thư mục này", progress từng file, pre-check jpg/png/webp ≤10MB · mp4/webm/mov/m4v ≤100MB) · view Thùng rác ("sẽ về: <path>", còn N ngày, Khôi phục).
- **`school.drive.tsx`** = wrapper mỏng (route id giữ nguyên; nút "Dọn rác kho" Bunny giữ trong header).
- **`teacher.media.tsx` MỚI** (`/teacher/media` "Học liệu của tôi") — `drive_my_zone` → `DriveExplorer initialFolderId=ngăn` ; GV mới chưa có ngăn vẫn vào được ngay.
- **`teacher.tsx`**: nav "Học liệu" (FolderOpen) giữa Giáo án và Khoảnh khắc. **`SessionResourcePanel.tsx`**: tooltip 🗑 mới ("…tệp sẽ vào thùng rác của kho, khôi phục được trong 7 ngày").
- **Vòng 2 vá (D172):** menu ⋯ tile file bị `overflow-hidden` của card cắt cụt → dời hidden xuống thumbnail (`rounded-t-2xl`), card mở menu bump zIndex.

## 4. Nghiệm thu thật (Jean, 18 ảnh, 2 vòng)

Master Nguyệt Thi: thấy ngăn "Đặng Mỹ Linh" 10 tệp · tạo "Thư Mục Test" · menu folder chạy · breadcrumb sâu 3 cấp (ngăn → Chụp tại lớp → 2026-07-05, capture từ Remote TỰ XẾP đúng chỗ) · grid + list view. GV Mỹ Linh: `/teacher/media` mở sẵn ngăn · kéo-thả 2 file từ Finder (IMG_8037/8038 progress ✓) · dialog Di chuyển navigator chạy · cảnh báo xoá-folder-cả-ruột · thùng rác days_left + Khôi phục (2 vòng: trước 092 file về gốc — Jean bác; sau 092 nhãn "sẽ về" + dựng lại cây) · **vòng 2: menu ⋯ tile file hiện đủ 3 nút** · quota 25.5/5000 + "Thùng rác đang chiếm 7.19 MB — tự dọn sau 7 ngày" đúng thực tế.

## 5. File đã đụng phiên này

**DB:** mig 086–092 (qua `apply_migration`). **Edge:** capture v2 · upload v12 · delete v3 · purge_trash v1 MỚI.
**UI:** `DriveExplorer.tsx` (MỚI) · `school.drive.tsx` (thay ruột) · `teacher.media.tsx` (MỚI) · `teacher.tsx` (nav) · `SessionResourcePanel.tsx` (copy 🗑).

## 6. ⭐ Tài khoản test (luôn kèm khi nhờ Jean test — password `Test@123`, domain `@demo.demenart.com`)

GV Mỹ Linh `gv.linh.kidshouse` · Master KHM `hieutruong.kidshouse` (Nguyệt Thi) · PH Hùng `ph.hung.kidshouse` · Master MNDM `hieutruong.demen` (Phương Dung) · GV Hân `gv.han.demen` · PH Thành `ph.thanh.demen` · GV My `gv.my.kidshouse` (password tạm) · PH Toản `ph.toan.kidshouse` (password tạm) · Super admin `info@demenart.com` (password của Jean). Buổi demo: `aaaa0000-0000-4000-8000-0000000a0001` (lớp Hoa Hồng, "Tiếng mưa rơi").

## 7. VIỆC TREO

- 🔴 **SECRET CRON (tay Jean, 30 giây — cron đêm chỉ chạy sau việc này):** SQL Editor `SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name='cron_purge_secret';` → Dashboard Edge Functions → Secrets → thêm `CRON_PURGE_SECRET` = giá trị đó. Chưa set thì cron gọi vào bị Edge từ chối — vô hại, rác chỉ nằm chờ.
- 🟡 **Copy Edge vào repo (tay Jean):** nay 9 file — 4 nợ v52 (`upload_media` cũ đã lên v12, lấy bản MỚI NHẤT) + `capture_session_media` v2 + `delete_session_media` v3 + `purge_trash` v1 + `get_signed_media_url` v18 + `school_media_admin`.
- 🟡 **Backup mig 086–092 vào repo** (dump từ live — D90, phiên sau hoặc gộp đợt).
- 🟡 **Upload "Chú Vịt Con" chuẩn** — Phần 4 buổi demo vẫn placeholder; chờ file từ Jean (giờ có thể kéo-thả thẳng vào Drive!).
- 🟡 **Dọn rác kho Bunny 15 file mồ côi cũ** — nút "Dọn rác kho" trong /school/drive (Jean bấm; khác hệ thùng rác mới).
- 🔴 **"Try to fix all" 11 issues Lovable — CHƯA ĐỘNG, ĐỪNG BẤM** (D5/D14).
- `/kid` V2 (cửa khoá placeholder) · Thêm giai điệu cue TV mới (lát riêng nếu cần).

## 8. NGÃ KẾ (chọn đầu phiên sau)

1. **`/kid` V2** — cổng trẻ PIN-based + parent approval (sprint lớn, đã đến lượt tự nhiên).
2. **Chú Vịt Con + polish nhỏ** — nếu Jean có file nhạc (giờ upload dễ: kéo vào Drive).
3. **Repo backup đợt 086–092 + 9 Edge** — đóng nợ D90 gọn một phiên.

## 9. Kỷ luật giữ nguyên (nhắc nhanh)

D1 audit live · D92 3-khối · D15 re-grant · D95 file trọn · D90/D112 dump-từ-live · D106 registry ngay · D114 verify body · D134 auto-áp + get_diff từng lượt · D164 gate channel_key · D167 school_settings config · **D168 drive = cây logic + owner theo lãnh thổ, zone root bất khả xâm** · **D169 quota gồm rác, purge 2 pha, gỡ link lúc bỏ rác** · **D170 restore dựng lại cây từ snapshot path (mọi cửa bỏ rác đều phải chụp)** · **D171 cron = vault secret + pg_cron/pg_net + Edge gate x-cron-secret** · **D172 overflow-hidden nuốt dropdown — bo góc ở thumbnail, không ở card** · KHÔNG auto-publish đường phát, để Jean test Preview.

*Handoff v54 — 2026-07-06 00:49 GMT+7. Nguồn: Tài liệu A–G + tầm nhìn founder + DMWS. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
