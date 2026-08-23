# 🗺️ DMA_SYSTEM_MAP.md — BẢN ĐỒ KIẾN TRÚC (skeleton V1)

> **Cách dùng:** Toàn cảnh hệ thống + bản đồ tái dùng DMWS. Nuôi dần "tới đâu ghi tới đó".
> **Nguồn:** Tài liệu A–G (UPDATED) + tầm nhìn founder + kinh nghiệm DMWS v170.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. ⭐ TRUNG TÂM HỆ THỐNG = TRẺ + NHẬT KÝ (không phải trường)

```
                    ┌─────────────────────────┐
                    │   CHILD (đứa trẻ)        │  ← gốc của mọi thứ
                    │   + child_journey        │  ← nhật ký nghệ thuật, treo vào child_id
                    │   + source (THÉP CHỜ #1) │  ← V1='demen', sau thêm nguồn ngoài
                    └────────────┬────────────┘
                                 │ đóng góp vào
        ┌────────────────────────┼────────────────────────┐
        │                        │                         │
   [Dế Mèn/Trường]          [PH tự thêm]              [Nơi ngoài]
   qua buổi học V1          (THÉP CHỜ — V2)          (THÉP CHỜ — V2)
   programs = danh mục TOÀN CỤC (Piano ở đâu cũng là "Piano")
```

**Đọc bản đồ này:** Trường/Lớp/Giáo án/License là **tầng vận hành B2B** sinh ra nội dung đổ vào nhật ký — nhưng KHÔNG sở hữu nhật ký. Trẻ chuyển trường / trường hết license → nhật ký nguyên vẹn (D42).

> ✅ **Đã chứng minh bằng login thật (phiên v3):** parent thấy **0 trường/lớp nhưng vẫn 1 trẻ** (con mình); admin Dế Mèn thấy **0 trẻ** (D48). Linh hồn sống trong RLS, không chỉ trong tài liệu.

---

## 2. BỐN PORTAL (V1) + scope quyền

| Portal | Vai | Scope quyền |
|---|---|---|
| **Admin (Dế Mèn)** | nền tảng + kho giáo trình + license + data ẩn danh | toàn hệ; KHÔNG xem PII trẻ (D48) |
| **School (Trường)** | chủ trường quản lý Lớp + GV toàn trường | trong trường mình (`same_school`) |
| **Teacher (GV)** | tiết dạy / giáo án / nhận xét / moment | THẤY toàn trường, THAO TÁC môn-lớp mình lead / tiết mình assistant (D45) |
| **Parent (PH)** | giữ nhật ký con: xem/comment/consent | con mình liên kết (`is_child_parent`) |

**THÉP CHỜ — Cổng Kid (V2):** trẻ PIN, ba mẹ duyệt PIN+giờ. Clone Kid Portal DMWS, khử cạnh tranh.
**School ↔ Teacher:** 2 portal thông nhau (Lớp DMA ↔ Đợt DMWS); pattern scope = `/b2b` DMWS.

> **App thật V1:** hiện gộp **1 `/portal`** (chưa tách 4 portal — làm khi mỗi portal có nội dung). RLS scope 4 vai trò đã đúng ở tầng DB (nghiệm thu §7).

---

## 3. BẢN ĐỒ BẢNG (theo Tài liệu C v2 — 44 bảng · ✅ ĐÃ THI CÔNG mig 001–007 · RLS bật · chi tiết §6)

| Cụm | Bảng chính | Trạng thái RLS |
|---|---|---|
| **Identity/Org** | `profiles`(user_id nullable, permissions[]) · `schools`(master_profile_id, settings) · `classes`(**HOMEROOM**) | ✅ **READ+WRITE XONG** (mig 011/013/015) |
| **Children/Parents** | `children`(global_child_id, `identity_user_id` ngỏ — D41) · `child_parents`(≤2) · **`enrollments`**(trẻ×homeroom) · `child_transfers` · `child_duplicates` | ✅ XONG (mig 012/013/014) — ⏳ `child_duplicates` hoãn (admin-ops) |
| **Curriculum** | `programs`(**TOÀN CỤC** — D40) · `age_groups` · `levels` · `themes` · `lessons` · `lesson_versions`(immutable) · **`program_distributions`** · **`program_distribution_items`** | ✅ **RLS XONG** (mig 017 — member-read/admin-write; lesson_versions no-UPDATE = immutable. D52) |
| **Idea** | `ideas` | ✅ **RLS XONG** (mig 017 — scoped theo trường+proposer. D52) |
| **Sessions** | **`class_distributions`**(✅ READ mig 011) · `lesson_sessions` · **`session_teachers`** · **`session_media`** · `session_reports` · `child_observations` | 🔒 phần lớn chưa policy — **CỤM KẾ** |
| **Moments** | `learning_moments` · `moment_children` · `albums` | 🔒 chưa policy |
| **Journey/Badge** | `child_journey`(**gốc child + source** — D40) · `child_skills` · `badges` · `child_badges` · `home_activities` | 🔒 chưa policy |
| **Privacy** | `consents`(8 loại) · `privacy_requests` · `share_links` | 🔒 chưa policy |
| **Media** | `media_assets`(Bunny-aware) · `media_variants` | 🔒 chưa policy — D60-D69 |
| **Business** | `school_subscriptions` · `school_subject_entitlements` · `pricing_config` | 🔒 chưa policy |
| **Vận hành** | `notifications` · `support_requests` · `audit_logs` | 🔒 chưa policy |
| **Registry** | `admin_module_groups` · `admin_modules` | ✅ READ (mig 009) |

**Edge Functions (server-side, giữ secret — CHƯA làm):** `get_signed_media_url` · `upload_media` · `create/resolve/revoke_private_share_link` · `request_sensitive_access`.

---

## 4. ⭐ BẢN ĐỒ TÁI DÙNG DMWS (3 nhóm)

**🟢 CLONE ĐẬM (DMWS đã cày, bê blueprint):**
Admin shell (modules/groups/permissions registry) + Trung Tâm Tra Cứu · permission **scoped** (← /b2b: thấy hết, thao tác theo phân công) · Xưởng/giáo án + **override per lớp** · versioning bất biến · buổi học+điểm danh+nhận xét · learning moments+tag+approve · share token · org/contract · engine sao/badge (**khử cạnh tranh**) · Trash registry · FAQ gating · **Kid Portal** (V2).

**🟡 CLONE + SỬA:**
`schools`←organizations · `children`+claim←children+claim · curriculum hierarchy←catalog · Child Art Profile←/toi · privacy_requests←claim/inquiry · Idea Library←override→Xưởng.

**🔴 LÀM MỚI (DMA đặc thù):**
**Consent engine 2 tầng** · **Media security Bunny signed-URL + watermark động + audit per-view** (Tài liệu G) · sensitive access gating · `child_journey` xuyên-tổ-chức · `child_observations` tap-first · duplicate/merge wizard · `classes`/`enrollments` · School Portal · Parent Portal cảm xúc · **license seat×môn** · **trigger guard chống leo thang cột** (D28 — phiên v3).

**⛔ KHÔNG BÊ (DMA chặn cứng):** ví/economy/ledger · shop/rewards/affiliate · gamification cạnh tranh · social feed/community · Zalo ZNS · B2C booking · online payment.

---

## 5. ĐÃ ĐỒNG BỘ TẦM NHÌN (chốt qua phiên hỏi-đáp)

- `child_journey` có cột `source` (V1='demen'); `programs` **TOÀN CỤC** (không `school_id`); `children` để ngỏ `identity_user_id` (Kid V2).
- **Lớp = HOMEROOM đa môn (Cách Y)**: môn rót vào lớp qua `class_distributions`, mỗi môn có **GV chính riêng**. `enrollments` = trẻ × homeroom.
- **Phân phối chương trình**: mẫu `program_distributions` (roadmap/piece); GV chỉnh **instance của lớp**, không đụng mẫu gốc (D44).
- **License (CHỐT):** `Tổng = (số Môn × giá) + (số tk GV × giá) + storage`. Môn ⟂ seat (subject-agnostic). Master bundled (không seat). Gate dạy = seat active AND entitlement môn active; license-gate **tách** journey (D42).
- **profile_role (12 giá trị — audit thật v3):** Admin Dế Mèn (6): `super_admin · content_admin · senior_content_admin · operation_admin · sales_admin · support_admin`. Nhà trường&GV (4): `master_admin · sub_admin · lead_teacher · assistant_teacher`. PH (2): `primary_parent · secondary_parent`. → `is_admin()` = phe 6 admin; `is_school_admin()` = master/sub.

---

## 6. ⭐ SỔ MIGRATION + TRẠNG THÁI THI CÔNG DB

> **DB tầng cấu trúc = XONG** (44 bảng mig 001–007). **RLS helpers XONG** (008). **RLS cụm Org/People XONG** (mig 011–016) **+ Curriculum XONG** (mig 017), đều nghiệm thu login thật §7. **~28 bảng còn lại CHƯA policy → khóa kín** — viết theo cụm là việc chính.

**Sổ migration (boot phiên sau dựa vào đây, đừng audit mò):**

| # | File | Sinh ra |
|---|---|---|
| 001 | `001_foundation` | 14 enums · `set_updated_at()` · programs · age_groups · levels · schools · profiles · classes |
| 002 | `002_children_enrollment` | children · child_parents · enrollments · child_transfers · child_duplicates · trigger `enforce_max_two_parents` |
| 003 | `003_curriculum` | themes · lessons · lesson_versions · program_distributions · program_distribution_items · ideas · trigger `lesson_version_autoincrement` |
| 004 | `004_sessions` | class_distributions · lesson_sessions · session_teachers · session_reports · child_observations |
| 005 | `005_media_moments` | media_assets · media_variants · session_media · albums · learning_moments · moment_children |
| 006 | `006_journey_privacy_license` | child_journey · child_skills · badges · child_badges · home_activities · consents · privacy_requests · share_links · pricing_config · school_subscriptions · school_subject_entitlements |
| 007 | `007_ops_registry` | notifications · support_requests · audit_logs · admin_module_groups · admin_modules |
| 008 | `008_rls_helpers` | 12 helper RLS (current_profile · current_profile_role · is_admin · has_permission · user_school_ids · same_school · is_distribution_lead · is_session_teacher · user_class_ids · is_child_parent · has_subject_entitlement · has_active_seat) — SECURITY DEFINER |
| 009 | `009_rls_batch1_test_login` | POLICY batch 1: profiles(select self+admin) · admin_modules/groups(select auth) + seed super_admin `info@demenart.com` |
| 010 | `010_harden_function_grants` | Gỡ EXECUTE public/anon khỏi 12 helper |
| **011** | `011_rls_org_backbone_read` | **READ**: schools(2) · classes(2) · profiles(+same_school) · class_distributions(2) + helper `class_school_id(uuid)` |
| **012** | `012_rls_children_people_read` | **READ**: children(parent+school, KHÔNG admin — D48) · enrollments(2) · child_parents(2) · child_transfers(2) + helper `child_in_my_school(uuid)` |
| **013** | `013_rls_org_write` | **WRITE**: classes(insert+update) · enrollments(insert+update) — master/sub-admin scoped + `is_school_admin()` (**non-definer**) |
| **014** | `014_rls_roster_write` | RPC `create_child_and_enroll(...)` (atomic, né RETURNING-câm — D29) · children UPDATE · `guard_children_protected_cols` trigger (D28) · child_parents insert/delete |
| **015** | `015_rls_escalation_safe_write` | profiles(update+insert provision) · schools(insert admin + update) · `guard_profiles_protected_cols` + `guard_schools_protected_cols` (D28 — ghim role/permissions/school_id/user_id, master_profile_id…) |
| **016** | `016_harden_guard_function_grants` | revoke public/anon EXECUTE khỏi 3 guard function (tạo sau mig 010 nên dính `anon` — D15) |
| **017** | `017_rls_curriculum` | **RLS cụm Curriculum (26 policy)**: 7 bảng catalog (programs/age_groups/levels/themes/lessons/program_distributions/program_distribution_items) × {select member · insert/update admin} · `lesson_versions` {select member · insert admin — KHÔNG update = immutable} · `ideas` {select scoped · insert member · update admin} + helper `current_school_id()` (secdef, re-verify grant D15). D52 |
| seed | `seed_001_org_people_fixture` | 1 trường DEMO-001 + lớp Mầm A + master/teacher/parent + bé Jenny + enrollment + link PH (dùng `session_replication_role=replica` — D30) |
| seed | `seed_002_curriculum_fixture` | 2 program (CTAN+Ballet) + age_groups/levels/themes/lessons + 2 lesson_versions (trigger set version_no=1) + 2 program_distributions + 2 items + 1 idea. Idempotent NOT EXISTS; KHÔNG cần replica (cụm không có guard) |

**Hàm SECURITY DEFINER = 23:** 16 cũ (3 trigger nền + 12 helper + `rls_auto_enable` benign) + 6 (`class_school_id`, `child_in_my_school`, `create_child_and_enroll`, 3 guard) + 1 mới v4 (`current_school_id`). **Non-definer:** `is_school_admin()`.
**RLS policy = 56** (4 mig 009 + 26 mig 011–015 + 26 mig 017).

**Chốt thi công (cụ thể hơn móng C, ĐỪNG "sửa lại"):**
- RLS bật ngay lúc tạo bảng, **deny-by-default**; chưa policy = đọc rỗng.
- `children` KHÔNG có `school_id` → "trẻ thuộc trường nào" đi vòng `enrollments→classes.school_id`, **gói trong helper definer** (`child_in_my_school`) tránh đệ quy.
- **D48 sống trong policy:** `children`/`enrollments`/`child_parents`/`child_transfers` KHÔNG mở cho `is_admin()`. Admin xem định danh → qua `request_sensitive_access` (Edge, sau).
- **Escalation guard (D28):** RLS gác ROW; trigger `BEFORE UPDATE` ghim CỘT leo thang (role/permissions/school_id/user_id; master_profile_id/name/code/state). `if is_admin() return new; else new.col := old.col`.
- **RETURNING-câm (D29):** `children` chưa enrollment → SELECT policy fail → INSERT raw không lấy được id. Phải qua RPC `create_child_and_enroll` (tạo trẻ+enroll nguyên tử, trả id).
- **`rls_auto_enable`** = Supabase event-trigger benign (đếm definer = 22, không phải 21).
- **`current_role()`** → đã đổi tên **`current_profile_role()`** (current_role là keyword).
- **`has_active_seat(profile_id)` V1** = trường có subscription active + seat_count>0.

**Bước kế (DB-first, §14 C):** ✅ Curriculum XONG → **RLS cụm Sessions** (`lesson_sessions`/`session_teachers`/`session_media`/`session_reports`/`child_observations` — scope lead/assistant D45, phức tạp hơn Curriculum) → Media → Journey/Privacy → Business → Ops + test login thật → Edge Functions media → UI Chặng 2.

---

## 7. ⭐ TẦNG APP (Lovable + TanStack Start)

> **Stack thật (chốt):** **TanStack Start** (file-routing `src/routes/`, SSR; KHÔNG Vite SPA + React Router; KHÔNG cần `vercel.json`). SSR loader **không có JWT** → fetch auth-gated **client-side** sau hydrate (D13/D82). Deploy: chốt Chặng 8.

- **Lovable project** nối **native Supabase integration** vào `dma` (đúng org "Dế Mèn Art"). Client `VITE_*` (URL + anon); types auto-gen (không sửa tay).
- **Routes chạy thật:** `/` landing · `/auth` (signInWithPassword, no self-signup) · `_authenticated` gate · **`/portal`** (full_name+role+school_id; chưa profile → "Tài khoản chưa kích hoạt") · **`/portal/modules`** Trung Tâm Tra Cứu (search không dấu) · **`/portal/rls-test`** panel test internal.
- **⭐ `/portal/rls-test` (panel nghiệm thu RLS):** 5 mục — user hiện tại · count Org/People (schools/classes/children/enrollments/profiles/child_parents) · nút "tự nâng quyền lên super_admin" (xanh=guard giữ / đỏ=lỗ) · **count Curriculum (programs/lessons/program_distributions/ideas)** · **nút "Thử thêm 1 program" (test WRITE chặn — xanh=RLS chặn / đỏ=lỗ; admin thấy note bỏ qua)**. Fetch client-side `useEffect`. **Dùng để chấm ma trận scope bằng login thật.**
- **✅ NGHIỆM THU phiên v3 (4 login thật):** ma trận scope Org/People đúng từng ô (HANDOFF_v3 §2) + 3 banner escalation xanh. 2 phép thử linh hồn (D48 admin-0-trẻ, D40 parent-0-trường-1-trẻ) ĐẠT.
- **✅ NGHIỆM THU phiên v4 (4 login thật — Curriculum):** READ — parent **0** program (D52/D65 ⭐), teacher/master/admin **2/2/2** + `ideas` scoped (member 1, parent 0). WRITE — teacher bấm thêm program → DB chặn `new row violates RLS policy for table "programs"` (banner xanh). Cụm Curriculum nghiệm thu trọn READ+WRITE.
- **Security scanner Lovable:** 6 issue → 5 nhiễu đúng thiết kế (no-policy = deny-by-default; signed-in execute definer = expected — D14) + 1 thật (Leaked Password = toggle Supabase, không phải code). **KHÔNG "Try to fix all".**
- **CHƯA làm:** tách 4 portal riêng; màn CRUD vận hành (rời panel-test); publish URL công khai (để sau).

---

*Skeleton v0.5 — **RLS cụm Org/People (mig 011–016) + Curriculum (mig 017) XONG, nghiệm thu login thật 4 vai trò.** Nguồn: Tài liệu A–G UPDATED + tầm nhìn founder + DMWS v170. Cập nhật "tới đâu ghi tới đó". Khi thêm bảng/module/Edge/policy mới → thêm dòng + cập nhật Trung Tâm Tra Cứu cùng nhịp (KỶ LUẬT VÀNG).*
