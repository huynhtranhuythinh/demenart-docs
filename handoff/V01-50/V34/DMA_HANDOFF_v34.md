# 🤝 DMA_HANDOFF_v34.md — BÀN GIAO PHIÊN (MÓNG TRA CỨU 3 LỚP [Module + Sơ đồ + Quy trình] + THƯ VIỆN ÂM — TỪ DMWS BLUEPRINT — 2026-06-29 16:05 GMT+7)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v34. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết (D1).
> **Naming:** DMA = nền tảng (`demenart.com`); CTAN = sản phẩm đầu. DMWS = business workshop riêng (`demenworkshop.vn`) — chỉ là blueprint pattern, KHÔNG cùng hệ. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

Phiên này **đổi hướng có chủ đích**: thay vì vào pass Nội thất (kế v33), Jean cho xem **Admin DMWS đã build thật** (`demenworkshop.vn`) → chốt một nguyên tắc kiến trúc: **"tài nguyên trước-sau-gì-cũng-dùng thì build-shared-trong-Admin TRƯỚC"** (thông báo/âm/template/Tra Cứu) rồi các cổng khác *gọi ra*. Đây là **móng dùng-chung**, làm trước nội thất.

**(0) Sửa sai của Claude (ghi để nhớ):** Claude suýt đề xuất lại 3 hướng thẩm mỹ MỚI từ số 0 — Jean nhắc design direction ĐÃ CHỐT từ v28/v29 (D98: Teacher = Hướng-2-Tươi-sáng + ấm Hướng-1, tokens `#FBF8F1`/`#149A76`/`#EFA63A`, 6-mockup-KTS north-star). Claude rút, không redo. **Bài học:** đọc memory/handoff kỹ trước khi "đề xuất lại" thứ đã chốt.

**(1) Audit DMA live (D1) — đối chiếu DMWS:** lộ DMA **đã có ~60% Tầng 1**:
- `admin_modules` (13 cột: slug/route/`usage_note`/`search_keywords`/`related_slugs`/`is_enabled` — **giàu, rỗng 0 dòng**) + `admin_module_groups` (rỗng).
- `notification_types` (12 cột: sẵn `body_template`+`sound`+`audience`+`position`+`enabled`, **10 seed**) + `notifications` + RPC `create_notification(slug,profile_id,payload)` — tầng thông báo + gán-âm-theo-loại ĐÃ CÓ ở DB.
- `app_settings` (8 cột: group_name/label/is_public/sort, **12 seed**) — config hub có sẵn.
- **THIẾU (dựng mới):** Sơ đồ cạnh có-hướng · Quy trình SOP · thư viện âm · cột status.

**(2) Cấu trúc Trung Tâm Tra Cứu DMA = 3 lớp** (chốt với Jean, mở rộng SOP-2-lớp DMWS thành sản-phẩm-tra-được):
- **Module** (`admin_modules`) — từng nơi/màn + quyền + `status` 4 mức.
- **Sơ đồ** (`admin_module_links`) — ràng buộc CÓ-HƯỚNG + LOẠI ("đụng X hỏng gì").
- **Quy trình** (`admin_playbooks`+`_steps`) — công thức từng-bước xuyên-module ("làm Y theo bước nào"); mỗi bước trỏ module/RPC/bảng.

**(3) mig 056 (3-khối D92):** `notification_sounds` + `admin_module_links` + `admin_playbooks` + `admin_playbook_steps` + cột `status` 4 mức (admin_modules/groups/playbooks) + 5 FK + RLS admin-only `is_admin()` + thu hồi anon rõ. Tái dùng `set_updated_at()`/`is_admin()` đã có → **KHÔNG +hàm definer**.

**(4) seed 013 (idempotent ON CONFLICT):** **13 nhóm** (bản đồ tiến độ: 6 live · 2 building · 1 reserved · 3 planned · interaction building) · **55 module** map bảng/RPC THẬT — gồm Kid (reserved-V2), **Miu Nắng (nhóm 🤖 AI riêng, planned-V3 — KHÔNG nhét vào Kid)**, License-PH + Referral + Mission-Control (nhóm 💰 Kinh-doanh, planned) · **9 cạnh** (gồm cạnh-chờ `parent-license`→requires→`consents`) · **1 Quy trình "Thêm GV cho trường"** 5 bước (`link_school_user`/`assign_class_distribution`).

**(5) UI `/admin/reference`** (`admin.reference.tsx`): route đổi từ `tra-cuu`→`reference` cho khớp convention repo tiếng-Anh (`curriculum-admin`/`school-onboarding`…); **tên hiển thị giữ "Trung Tâm Tra Cứu"**. 3 tab Module/Sơ đồ/Quy trình; search unaccent; Sơ đồ bản-gọn-V1 (list cạnh + focus "bị ảnh hưởng nếu đổi", SVG graph để pass sau); gác RLS `is_admin()` data-driven (KHÔNG hardcode role-list). Bám convention repo thật (`@/integrations/supabase/client`·`createFileRoute`·`ssr:false`·useEffect alive-guard·shadcn Card/Input/Button).

---

## 2. ⭐ NGHIỆM THU (catalog + login thật — ĐẠT)

**Catalog (mig 056 + seed 013):**
- mig 056: RLS 4/4 bảng · policy admin_all 4 · anon thu-hồi=0 · authenticated 16 grant · **5 FK** (verify `::regclass` trực tiếp — D107, sau khi câu so-chuỗi `'public.'` ra "0 ❌" giả).
- seed 013: nhóm **13** · module **55** · cạnh **9** · playbook **1** · step **5** · Quy trình "Thêm GV" resolve **5/5 step trỏ module thật** (không bước mồ côi).

**Login thật (super_admin `demenart.com/admin/reference`):**
- Header "Bản đồ **55 module · 13 nhóm · 9 ràng buộc · 1 quy trình** — cập nhật trực tiếp từ hệ thống".
- **Tab Module:** 13 nhóm, badge 4 trạng thái (Đang chạy/Đang làm/Đã chừa/Dự kiến) đúng màu; thẻ có slug+usage_note; "🔗 1 liên kết" ở Ghi-danh/Đăng-ký-môn.
- **Tab Sơ đồ:** 9 cạnh đọc-thành-câu ("Gửi nhật ký →kích hoạt→ Thông báo →đọc từ→ Thư viện âm"); cạnh-chờ License-PH→Consent hiện.
- **Tab Quy trình:** "Thêm giáo viên cho trường" mở 5 bước, mỗi bước có chip module + RPC tím (`link_school_user()`/`assign_class_distribution()`) + bảng (`profiles`/`session_teachers`).
- Route `/admin/reference` đồng bộ (chạy `UPDATE admin_modules SET route='/admin/reference' WHERE slug='reference-center'`).

---

## 3. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc (CÓ ĐỔI):** **52 bảng** (+4: `notification_sounds`/`admin_module_links`/`admin_playbooks`/`admin_playbook_steps`) · **60 hàm SECURITY DEFINER** (KHÔNG đổi — tái dùng `is_admin`/`set_updated_at`) · **136 RLS policy** (+4 admin_all) · **+5 FK** · cột `status` 4 mức (admin_modules/groups/playbooks) · **mig 001→056** · **seed 001→013** · 6 Edge · 3 tenant/3 master. SYSTEM_MAP **v0.31** (bump — +4 bảng + route + registry layer).
- **Edge Functions (6 — KHÔNG đổi):** `get_signed_media_url` · `upload_media` · `resolve_share_link` · `invite_master` · `invite_staff` · `invite_parent`.
- **Routes app:** 5 cổng + `/portal` shell + `/kid` reserved. **MỚI `admin.reference.tsx`** (`/admin/reference` — Trung Tâm Tra Cứu).
- **Teacher V1 vẫn COMPLETE** (không đụng phiên này).

> **Data state:** registry seed (13 nhóm·55 module·9 cạnh·1 playbook·5 step). `notification_sounds` RỖNG (chưa upload âm). `notification_types`/`app_settings` GIỮ NGUYÊN (không đụng 10+12 seed cũ). Mọi consent/journal data từ v33 không đổi.

---

## 4. FILE PHIÊN NÀY

**Migration + seed (Jean lưu repo — dump trung thực D90):**
- `056_admin_registry_layer.sql` — 4 bảng + status + FK + RLS (3 khối D92).
- `seed_013_admin_registry.sql` — 13 nhóm·55 module·9 cạnh·1 quy trình (idempotent ON CONFLICT, 2 khối seed+verify).

**UI (Jean áp Lovable tay):**
- `src/routes/_authenticated/admin.reference.tsx` (**file MỚI** — Trung Tâm Tra Cứu 3 tab; route `/admin/reference`).

**SQL lẻ (đã chạy):** `UPDATE admin_modules SET route='/admin/reference' WHERE slug='reference-center'`.

**3 file library (phiên này):** `DMA_HANDOFF_v34.md` · `DMA_RULES.md` (+D106/+D107+footer) · `DMA_SYSTEM_MAP.md` (v0.31+footer).

---

## 5. VIỆC TREO

**🟢 Hoàn thiện Tra Cứu (làm dần, không chặn):**
- Điền `route` thật cho ~50 module còn "chưa gắn route" (sửa trong DB hoặc thêm UI sửa registry).
- **Thư viện âm `notification_sounds` rỗng** — upload âm (Bunny) + UI gán âm-theo-loại (đọc/ghi `notification_types.sound`).
- **SVG graph cho tab Sơ đồ** (bản gọn V1 dùng list — nâng lên đồ thị kéo-thả sau).
- UI sửa registry trong app (để cập-nhật-khi-đóng-phiên D106 không phải chạy SQL tay).

**🟢 Móng-chung còn lại (Tầng 1, nếu làm tiếp trước nội thất):**
- UI quản lý **Thông báo** (template + gán âm) — engine đã đủ, chỉ thiếu màn admin.
- **Ngôn ngữ** (vi/en/song ngữ) + **Giao diện** (logo/slogan/PWA) — đọc/ghi `app_settings`.

**🟡 Nợ cũ (mang theo từ v33):**
- Lưu repo: `056`+`seed_013` (mới) + `045`(nợ v28) + `051/052/053`(nợ v32) + `054/055`(nợ v33) + 2 Edge `invite_staff.ts`/`invite_parent.ts`(nợ v22).
- Teacher: tab Nhật ký/Hồ sơ (build hay giữ khoá) · reaction "Lời cảm ơn" (flex) · desktop nav `/teacher/classes` · land GV `/teacher`.
- Dọn seed `[v29-test]`+`demo_seed`. 2 PH email-null. GV/PH pilot chưa login. 2 file nhạc curriculum. Vercel dormant. **Lock 1 linh vật** (3 phân vai đã rõ: dế-sắc-cạnh=wordmark · dế-tròn=linh vật chrome/empty · Miu-Nắng=AI companion V3 — không cần "chọn 1 bỏ 2", chừa node reserved).

---

## 6. KẾ HOẠCH PHIÊN SAU

Boot sạch → audit D1 → chọn 1 nhánh:

- **(A) Tiếp móng-chung** — UI Thông báo (template+âm) + thư viện âm upload + Ngôn ngữ/Giao diện (đọc `app_settings`). *Hoàn tất Tầng 1 trước khi tô đẹp — đúng tinh thần "móng dùng-chung trước".*
- **(B) Vào NỘI THẤT V1** — **Parent trước** (linh hồn + engine `get_child_journal` sẵn nhất, khớp mockup ảnh-2), rồi School. **KHÔNG chọn lại thẩm mỹ** (đã chốt D98: mở rộng ngôn ngữ Teacher đã build sang Parent/School: kem ấm + xanh-rừng `#149A76` + honey; mỗi cổng accent-tint riêng). Cửa `/kid` khoá "Sắp ra mắt" ở `/parent`.

> **D106 nhắc:** phiên sau nếu thêm/sửa module hay flow → cập nhật registry (`admin_modules`/`admin_module_links`/`admin_playbooks`) TRƯỚC khi đóng. Quên = phiên chưa đóng.

Đóng = HANDOFF v35.

---

*Móng Tra Cứu 3 lớp (Module + Sơ đồ + Quy trình) sống — bộ-não-ghi-nhớ tự-ghi-tài-liệu của DMA, né gốc rễ "tài liệu tụt hậu" 162-phiên của DMWS. Port PATTERN từ DMWS blueprint, KHÔNG bê module business. Nguồn: Tài liệu A–G UPDATED + DMWS v170 (DMA_05) + Admin DMWS thật Jean cho xem. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
