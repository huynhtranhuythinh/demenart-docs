# DMA_HANDOFF_v87.md
**Sprint:** V87 — Teacher Media Soft Delete
**Ngày:** 2026-07-10 14:16 GMT+7 (Asia/Ho_Chi_Minh)
**Vai trò:** ChatGPT = CTO Advisor · Claude = PM + Prompt Operator + Builder · Lovable = build
**Trạng thái:** ✅ ĐÓNG SỔ — **DB verify PASS + Teacher smoke PASS** · +1 hàm definer · UI frontend-only 1 file · 0 Parent code · CTO chốt.
**File code bị đụng:** **`src/routes/_authenticated/teacher.session.$id.tsx`** (duy nhất, chỉ `PhotoTab`).
**DB:** +1 hàm definer `remove_moment_media_service` (2 lần `apply_migration`). **Commits UI:** `8af1e05` → `dff8cb4` → `8532f52`. Deploy: `https://demenart.lovable.app`.

---

## 0. TL;DR

Cho **Giáo viên gỡ 1 ảnh khỏi khoảnh khắc còn NHÁP** một cách an toàn — soft-delete qua RPC SECURITY DEFINER, KHÔNG đụng Bunny, KHÔNG xoá moment, KHÔNG đổi Parent gallery.

- **RPC `remove_moment_media_service(p_media_id)`** (mig `create_...` → `fix_..._session_lead`): authz-TRƯỚC-lộ-state · reuse `check_media_upload_access` (same-school) + `is_school_admin OR is_session_lead OR is_session_teacher` · FOR UPDATE media+moment · guarded UPDATE ROW_COUNT=1 · `state='deleted'` + metadata audit · grants sạch (0 anon).
- **Verify DB PASS** qua JWT-claims impersonation (ma trận đầy đủ) + test moment tạo/test/dọn sạch. **An 6/2/5 giữ.**
- **UI PhotoTab** (agent-mode, 3 commit): delete draft-only, card 0-ảnh ẩn, chạm thumbnail đổi ảnh-lớn, × to-đỏ, newest-first. **Teacher smoke PASS.**
- **⭐ Endpoint sau V87:** RULES **D219** · SYSTEM_MAP **v0.80** · Handoff **v87**.

---

## 1. Canonical đã đọc — endpoint verify (đầu phiên)

Topic V87 mở mới. **KHÔNG dựa memory** — đọc canonical thật trên đĩa: `DMA_00_START_HERE.md` · `DMA_HANDOFF_v86.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md`.

**Endpoint đầu phiên (LIVE trên đĩa):** RULES **D218** · SYSTEM_MAP **v0.79** · Handoff **v86** — **khớp brief cả 3** ✔ · **0 drift đĩa**.

---

## 2. C1 — Audit LIVE (read-only)

**DB (`xcvhacymrbhdhohyylyq`):**
- Inventory **63 bảng · 105 definer · 155 policy · 1 cron** = y hệt V86 → **0 DB drift**.
- **An summary = 6/2/5** (dựng lại LIVE: creation drawing 6 · recording 2 · moment-approved-tagged-An-có-media-active 5).
- `c6fc98e8` = 3 media active/approved · `f51039be` = 2 media active/approved.
- `get_child_journal` SECURITY DEFINER `search_path=''` · gate parent-or-school · **0 signed_url** · grants authenticated+postgres+service_role (0 anon). Mọi nhánh media lọc `state='active'`.
- Schema: `media_assets.state` text default `active` (LIVE: active 39 · deleted 18 · trashed 2) · `metadata` jsonb · `linked_moment_id` nullable · **KHÔNG có `deleted_at`/`deleted_by`** (chỉ `trashed_*`/`restore_*` của Drive D169/D170). `learning_moments.state` enum {draft, pending_approval, needs_revision, approved, rejected, hidden, archived}; `class_id` NOT NULL.
- **`media_assets` RLS ON + 0 policy** → deny-by-default → frontend KHÔNG UPDATE trực tiếp → **bắt buộc RPC SECURITY DEFINER**. Hàm delete/remove sẵn = CHỈ `drive_trash_media_service` (Drive-scoped) → không moment-scoped → cần RPC mới.
- `get_session_moments` lọc `ma.state='active'` → soft-delete + `loadMoments()` = ảnh biến mất khỏi PhotoTab (cơ chế refresh, không hiding).
- `check_media_upload_access` = khuôn gate upload (same-school). Helper LIVE: `current_profile`/`moment_school_id`/`same_school`/`current_profile_role`/`is_school_admin`(=role∈{master_admin,sub_admin})/`is_session_lead`(=`class_distributions.lead_teacher_id`)/`is_session_teacher`(=bảng `session_teachers`).

**Role LIVE (`profile_role`):** nhân sự trường (school_id SET) = lead_teacher(6) · assistant_teacher(2) · master_admin(3); parent(13)+super_admin(1) school_id NULL. INSERT/UPDATE moment policy = `same_school(...)` **thuần, KHÔNG role gate** → đây là lỗ CTO chỉ "same-school alone chưa đủ".

**Code (`teacher.session.$id.tsx`):** `createFileRoute("/_authenticated/teacher/session/$id")` khớp (D117). `PhotoTab`+`MomentCover` inline. `MomentItem={moment_id,state,caption,media:{media_id}[],tagged_child_ids}`. `loadMoments`→`get_session_moments`; ký từng media qua Edge.

---

## 3. C2 — Safety plan + hardening CTO

CTO duyệt kiến trúc + 5 lựa chọn (apply_migration D92 · metadata JSONB audit · `not_active` minh bạch · authenticated+service_role grants · `p_media_id` đơn) và yêu cầu:
1. **FOR UPDATE** media + moment + re-check draft sau lock (chống đua delete/publish).
2. **Authorization mirror upload + siết staff-in-context** (same-school-alone chưa đủ; parent/unrelated/wrong-school/same-school-disallowed đều chặn).
3. **Guarded UPDATE** + `GET DIAGNOSTICS ROW_COUNT=1`.
4. ⭐ **AUTHORIZE TRƯỚC KHI TRẢ state nhạy cảm** (`not_active`/`moment_not_draft`/`delete_conflict` chỉ sau khi actor được cấp quyền) — chống enumerate active/deleted/draft/approved qua UUID.

**Audit sửa do D1:** CTO nêu `is_session_teacher(session)`, nhưng LIVE lead KHÔNG ở `session_teachers` (ở `class_distributions.lead_teacher_id`) → thêm `is_session_lead` để không chặn nhầm GV lead. Giữ INTENT "người-trong-phòng" (D53). Bất đối xứng có chủ đích: delete chặt hơn upload — CTO chốt giữ.

---

## 4. C3 — Migration (đã áp)

`apply_migration` 2 lần (D92 3-block: DDL → REVOKE/GRANT tách khối → verify proacl):
1. `create_remove_moment_media_service`
2. `fix_remove_moment_media_service_session_lead` (thêm `is_session_lead`)

`remove_moment_media_service(p_media_id uuid)` SECURITY DEFINER `search_path=''`, thứ tự: authenticated → lock media (FOR UPDATE)/`media_not_found` → `linked_moment_id IS NULL`/`not_moment_media` → lock moment (FOR UPDATE)/`moment_not_found` → **AUTHORIZE** (`check_media_upload_access` + `is_school_admin OR is_session_lead OR is_session_teacher`) → `not_active` → `moment_not_draft` → guarded `UPDATE state='deleted', metadata||{deleted_at,deleted_by,delete_reason}` WHERE id+active+moment + ROW_COUNT=1/`delete_conflict`. KHÔNG Bunny/row/moment delete.

**Grants:** REVOKE PUBLIC,anon → GRANT authenticated,service_role → proacl = authenticated/service_role/postgres (anon/PUBLIC vắng). Inventory 105→**106 definer**; bảng/policy/cron KHÔNG đổi. Chữ ký `(p_media_id)` đơn (đề xuất v86 ghi 2-tham-số; chốt 1 vì `linked_moment_id` có trong row — reconcile D112).

---

## 5. Verify DB — PASS (JWT-claims impersonation)

`set_config('request.jwt.claims','{"sub":"<user_id>"}',false)` để test as-user:
- **lead (Mỹ Linh) own-school draft** → `ok:true` (1 active→deleted); gọi lại → `not_active` (minh bạch, sau authz).
- same-school KHÁC buổi (GV My) → `not_authorized_role` · wrong-school (Hân MNDM) → `wrong_school` · parent (Hùng)/super → `not_school_member`.
- approved `c6fc98e8` → `moment_not_draft` (**KHÔNG mutate**) · already-deleted → `not_active` · non-moment (Drive) → `not_moment_media` · bogus uuid → `media_not_found`.
- Structural: exists · secdef=true · `search_path=""` · grants sạch · 106 definer.
- Effect: `get_session_moments` ẩn media deleted (2→1, moment giữ draft + caption) · `get_child_journal` vẫn lọc active/0 signed_url · media_a `state=deleted`+metadata audit đủ · media_b active nguyên · **An 6/2/5 giữ** · inventory 63/155/1.
- Test data: moment `759bfdb8` + media `49e81109`/`40d0538d` tạo (replica) → test → **hard-delete sạch** (0/0 remain; active total về 39).

---

## 6. C4 — UI PhotoTab (frontend-only, 3 commit, agent-mode)

1 file `teacher.session.$id.tsx`/`PhotoTab`. `8af1e05` (delete icon draft-only + placeholder) → `dff8cb4` (feedback Jean: card 0-ảnh ẩn; chạm thumbnail đổi ảnh-lớn `selected[moment_id]`; × to-đỏ CLAY viền trắng; card 1-ảnh × trên cover) → `8532f52` (newest-first `.reverse()`). Mỗi lượt get_diff = 1 file (routeTree.gen.ts vắng), typecheck sạch, deploy 1 lần.

**Hành vi:** card **draft** mỗi ảnh có × (confirm "Xoá ảnh này khỏi khoảnh khắc?" → RPC → loadMoments, map reason→thông báo); card **approved** ("Đã gửi") **KHÔNG có ×**; card **0 active media → ẩn** (moment nháp-rỗng inert nằm DB); thumbnail click đổi ảnh lớn; newest lên đầu.

**Teacher smoke PASS** (GV Mỹ Linh `gv.linh.kidshouse@demo.demenart.com` / `Test@123`): xoá 3→2 ảnh · confirm dialog · chọn thumbnail đổi cover · card 0-ảnh ẩn · newest-first · card "Đã gửi" không có ×.

---

## 7. Non-negotiable giữ nguyên

Parent/Kid/DB downstream KHÔNG đụng · `get_child_journal` lọc active + 0 signed_url · **Parent baseline An 6/2/5** · consent V72 + badge V73 · 0 signed_url RPC/adapter/batch-sign/raw Bunny · Guard chuỗi V69→V86 · /kid namespace reserved (5 portal /admin·/school·/teacher·/parent·/kid) · ảnh **approved KHÔNG xoá được** (cố ý — bảo vệ thứ PH đã thấy + consent).

---

## 8. Endpoint & backlog sau V87

**Endpoint:** RULES **D219** · SYSTEM_MAP **v0.80** · Handoff **v87**.

**Backlog:**
- 🟠 re-sync project library (RULES D219 + SYSTEM_MAP v0.80 + HANDOFF v87).
- 🟠 lưu repo V87 (2 migration `remove_moment_media_service` + `PhotoTab`, dump trung thực D90).
- 🟢 **Kid gallery ảnh-thứ-2:** lightbox `/kid` chỉ hiện ảnh cover; ảnh `galleryItems[1]` không hiện khi chạm chấm (nghi chưa ký URL on-navigate). Sửa: audit `/kid` + lightbox, ký-từng-item — **KHÔNG đụng Parent** (non-negotiable). Ngoài scope V87.
- 🟢 **Retire `/teacher/moments` + `/school/moments`:** `MomentsView` (component `@/components/portal/MomentsView`) là màn legacy v13 (D77) — liệt kê phẳng mọi moment + gắn 1 ảnh/moment, thiếu ngữ cảnh buổi/bé/tag, chồng chéo Bước 3 "Ảnh gắn bé". ⚠️ **Governance gap:** cho gắn ảnh vào moment **đã duyệt** (không guard draft-only) — cửa hông lách workflow, ngược tinh thần V87. Gỡ nav "Khoảnh khắc" (Teacher) + redirect/xoá route sau khi audit ai còn link tới.
- 🟡 **Purge orphan draft moment:** xoá ảnh cuối → `learning_moments` nháp-0-ảnh còn nằm DB (inert: không publish, không hiện PH/Kid). Lát cleanup: purge draft + 0 active media + 0 tag.
- 🟠 (nợ taxonomy) `upload_media` nhánh A KHÔNG set cột `source` (mig068).
- 🟠 (hoãn) filter chip / month-jump nav khi đạt ngưỡng revisit (D216).
- 🟠 (hoãn) timeline affordance "X ảnh" khi n≥2 moment gallery / user-testing.
- 🟠 (tùy) migration `cover_media_id`/`sort_order` · Edge batch-sign nếu waterfall.
- Nợ cũ: Parent Dashboard/Radar/AI Review THẬT · Phương án B RPC `get_child_journey_service` · rename `kidJourneyModel.ts` · enrichment `child_journey` · Coloring schema · Moment media taxonomy.

---

## 9. Rollback plan (V87)

- **DB:** `UPDATE public.media_assets SET state='active', metadata = metadata - 'deleted_at' - 'deleted_by' - 'delete_reason' WHERE id=…` (khôi phục ảnh); hoặc `DROP FUNCTION public.remove_moment_media_service(uuid)` (gỡ hàm). Byte Bunny nguyên vẹn (chưa từng xoá).
- **UI:** revert từng commit `8532f52` → `dff8cb4` → `8af1e05` trên 1 file.

---

## 10. Demo accounts

(`@demo.demenart.com` · `Test@123`): PH KHM `ph.hung.kidshouse` · Master KHM `hieutruong.kidshouse` · **GV KHM `gv.linh.kidshouse`** (lead lớp Hoa Hồng) · GV KHM `gv.my.kidshouse` (assistant, temp) · PH KHM `ph.toan.kidshouse` (temp) · Master MNDM `hieutruong.demen` · GV MNDM `gv.han.demen` · PH MNDM `ph.thanh.demen`.
