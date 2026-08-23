# 🤝 DMA_HANDOFF_v45.md — BÀN GIAO PHIÊN (Kho Học Liệu LÁT 0)

> **Chốt lúc:** 2026-07-01 16:47 GMT+7
> **Phiên trước:** v44 (wire nút "Chiếu lên TV" + CDN + registry mig 067).
> **Boot phiên sau:** đọc **file này** → `DMA_00_START_HERE.md` → `DMA_RULES.md` trước khi làm gì. Claude trình menu, Jean chọn.

---

## 0. TL;DR PHIÊN NÀY

**Sprint: Media Library Manager "Kho Học Liệu" — LÁT 0 (nền đa-nguồn).** Mô hình tham chiếu ClassIn (nghiên cứu + phê phán, KHÔNG rebuild — DMA đã có tương đương mạnh hơn). Chốt **Hướng B** (kho dùng chung thật). **LÁT 0 khép hoàn toàn trên production**, nghiệm thu login thật ĐẠT trọn.

3 migration (068/069/070 — đã chạy + verify LIVE), 1 route Admin mới, 4 file UI sửa (nav + 3 player). Tất cả deploy production `demenart.com`.

---

## 1. ĐÃ LÀM (verify LIVE, nghiệm thu login thật)

### mig 068 — Nền đa-nguồn
- `media_assets.source` (dma_global | school | teacher) default dma_global + CHECK.
- `lesson_activity_media.material_role` (present | teacher_guide | home_practice | reference) + `parent_visible` + `kid_visible` + CHECK.
- `schools.curriculum_scope` (school | subject) + `master_sees_teacher_drive`.
- REPLACE `get_lesson_guide` → mỗi media kèm source/material_role/parent_visible. Re-harden grant (D15).
- Verify: 3 constraint OK · grant sạch (authenticated/service_role) · source_backfill dma_global:11 · lam_roles present:2.
- ⚠ **Quota LÁT 2:** 11 dma_global GỒM 8 ảnh trẻ private → quota Org lọc theo `access_level` KHÔNG theo `source`. Dùng lại cột `size_bytes` (không tạo file_size).

### mig 069 — Engine kho dùng chung (Hướng B)
- 3 RPC secdef, `is_admin()`-gated, `search_path=''`, grant sạch:
  - `get_curriculum_library_tree()` → cây Program→Bài→Version→Phần + media gán, + `library[]` kèm `assigned_count` (dò mồ côi).
  - `set_activity_media(version, activity_key, media_id, role, parent_visible, sort)` → gán/cập nhật, **cho phép chéo bài**, idempotent.
  - `unset_activity_media(row_id)` → gỡ.
- `tree_smoke='false'` ở SQL Editor là ĐÚNG (postgres ≠ admin → gate sống). Verify thật = login super_admin.

### Admin UI — Kho Học Liệu
- Route mới `_authenticated/admin.curriculum-library.tsx` (cosmic slate). Cột trái = cây (Program→Bài→version-CÓ-Phần→Phần, ⚠ badge Phần trống/mồ côi). Cột phải = cửa gán (4 vai + toggle Ba mẹ + gỡ + picker "Thêm học liệu" gán chéo bài).
- Nav `admin.tsx`: +import `FolderTree` + mục "Kho Học Liệu" `/admin/curriculum-library` nhóm Vận hành.
- **Fix bug hiển thị:** cây chọn version ưu-tiên `activities>0` (không cứng `is_current`) — vì `lessons.current_version_id` trỏ v1-rỗng còn Phần ở v2 (nợ track-split v41).

### Player lọc `material_role` (3 file)
- `teacher.session.$id.tsx` Bước 2: normalize tách `present`→player / còn-lại→khối "Tài liệu của cô" (cô đọc, KHÔNG chiếu trẻ) + badge nguồn (Dế Mèn/Trường/Giáo viên).
- `teacher.classroom.tsx` + `teacher.remote.tsx`: `.filter(m => (m.material_role ?? 'present') === 'present')` **đối xứng 2 file** (index đồng bộ BroadcastChannel — TV chỉ chiếu present).

### mig 070 — Registry (D124/D106)
- INSERT `curriculum-library` (group media-security · route `/admin/curriculum-library` · live · 11 keyword · icon FolderTree) + nối 2-chiều `media-vault` (+điền route media-vault).
- Verify: `symmetric_2way_ok=true` · row 57→58.

### Nghiệm thu login thật ĐẠT (3 mặt)
- **Admin** (super_admin `info@demenart.com`): cây xổ 5 Phần · gán chéo bài (badge "1 chưa dùng"→hết) · đổi vai · parent-toggle.
- **Bước 2** (GV Mỹ Linh `gv.linh.kidshouse@demo.demenart.com`/`Test@123`): P1 Khởi-động teacher_guide→player "không dùng học liệu" + cột "Tài liệu của cô: Chú Vịt Con" · P2/P4 present phát + badge Dế Mèn.
- **Classroom Trio** (cùng account): P1 TV chỉ tiêu-đề-Phần (teacher_guide KHÔNG chiếu) · P2/P4 present chiếu + watermark + blackout · Monitor↔Remote khớp 5 Phần.

---

## 2. TRẠNG THÁI DB (sau phiên)

**53 bảng · 72 hàm definer · 138 policy\* · mig 001→070 · seed 001→014 · 7 Edge · admin_modules 58 row · 3 tenant / 3 master.**

- Hàm: v44=69 → +3 (get_curriculum_library_tree/set_activity_media/unset_activity_media) = **72**. `get_lesson_guide` = replace-thân (không +1).
- Cột mới: media_assets.source · lesson_activity_media.{material_role,parent_visible,kid_visible} · schools.{curriculum_scope,master_sees_teacher_drive}. +3 CHECK.
- \* policy 138: drift mig057 (`notification_sounds_select_enabled`) có thể khiến thực-có 137 — CHƯA reconcile (D112).

**Data note phiên này:** session a0001 ("Tiếng mưa rơi") Phần **Khởi động** giờ có "Chú Vịt Con (demo CTAN)" `material_role=teacher_guide` (test data — có thể gỡ nếu muốn demo sạch).

---

## 3. LÁT TIẾP THEO — Kho Học Liệu

Sprint chia lát; LÁT 0 xong. Còn:

1. **LÁT 1 — Upload đa-loại + Drive nguồn:** nâng `upload_media` whitelist video/image (D119) + **video lớn đi Bunny Stream** (`bunny_stream_video_id` sẵn) + UI admin mở `accept`. Mở nạp **My Drive** (teacher) / **Drive School** (school). Player Bước 2/Classroom đã render đủ 3 MIME — chỉ chờ file trong kho.
2. **LÁT 2 — Quota:** `school_subscriptions.storage_base_mb` + `storage_addon_mb` sẵn. **Lọc theo `access_level` KHÔNG `source`** (dma_global gồm ảnh trẻ private). dma_global KHÔNG tính quota Org.
3. **LÁT 3 — Admin browser kho:** Finder duyệt toàn kho (list/grid, filter source/loại, "dùng ở đâu" = chiều ngược `lesson_activity_media`).
4. **LÁT 4 — Picker khi đứng lớp:** GV chọn media từ kho ngay trong buổi.

---

## 4. VIỆC TREO KHÁC (mang từ v44)

- 🟢 **3B Route Nhật ký** `/teacher/journal` (DB-first: `lesson_sessions.state` + RPC `get_teacher_journals` + mở-khoá sidebar).
- 🟢 **Remote V1.2** (điểm-danh/chụp/kết-thúc — StepRecord trên remote).
- 🟡 **Nâng BroadcastChannel → Supabase Realtime** (phone khác máy — chỉ đổi `createTransport()`, D122).
- 🟡 **Lưu repo mig 060–066** (dump từ live, D90) — CHƯA làm (nợ tích từ v39). Phiên này đã lưu 068/069/070.
- 🟡 **Drift mig057** — xác nhận policy count + chạy khôi phục read âm.
- 🟡 **`lesson_activity_media` grant-verify** (flag ⚠ mig065 dump v42).
- 🟡 **Admin** wire "Xử lý" Action Center + re-theme cosmic trang con + điền route ~50 module (D109/D111).
- 🟡 **3-tier privacy label** moments (cần field consent vào `get_school_moments`).
- Nợ cũ: dọn seed test/demo_seed · 2 PH email-null (Chi/Dung) · GV/PH pilot chưa login · file nhạc curriculum chưa nguồn lưu · Vercel dormant · lock 1 linh vật · pwa.theme_color · `cdn.demenart.com` Edge chưa dùng.

---

## 5. FILE GIAO PHIÊN NÀY (paste-over/repo)

| File | Loại | Ghi chú |
|---|---|---|
| `068_media_multisource_foundation.sql` | repo SQL | đã chạy+verify live |
| `069_curriculum_library_shared.sql` | repo SQL | 3 RPC engine kho |
| `070_registry_curriculum_library.sql` | repo SQL | registry, đã verify symmetric |
| `admin.curriculum-library.tsx` | route mới | Jean đã áp Lovable + nghiệm thu |
| `DMA_RULES.md` | library | +D125 + update v45, footer v45 |
| `DMA_SYSTEM_MAP.md` | library | v0.41 |
| `DMA_HANDOFF_v45.md` | library | file này |

**UI đã áp trực tiếp Lovable (không kèm file ở đây, có trong GitHub/Lovable):** `admin.tsx` (nav +FolderTree) · `teacher.session.$id.tsx` (Bước 2 lọc vai + "Tài liệu của cô") · `teacher.classroom.tsx` + `teacher.remote.tsx` (filter present).

---

## 6. NGUYÊN TẮC BẤT BIẾN (nhắc)

- **D1:** audit live trước mọi SQL. **D92:** 3-block CREATE→REVOKE/GRANT→VERIFY. **D15:** re-harden grant sau CREATE OR REPLACE.
- **D95:** giao file paste-over trọn, không diff. **D2/D3:** verify login thật, không chỉ SQL Editor.
- **D48:** admin không chạm PII trẻ. **D75:** GV không thay curriculum media (báo lỗi). **D118/D125:** giáo án↔media qua `lesson_activity_media` FK, Hướng B.
- **D124/D106:** route mới phải vào registry ngay. **KỶ LUẬT VÀNG:** tới đâu ghi tới đó.

**Demo accounts (luôn kèm khi nhờ Jean test):** super_admin `info@demenart.com` · GV Mỹ Linh `gv.linh.kidshouse@demo.demenart.com`/`Test@123`. Session demo "Tiếng mưa rơi" = `aaaa0000-0000-4000-8000-0000000a0001` (version `ac0a5c13-aad4-4c66-a7e0-d32ce1d749ab`).
