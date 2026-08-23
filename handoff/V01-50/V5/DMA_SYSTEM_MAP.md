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

> ✅ **Đã chứng minh bằng login thật (v3 + v5):** parent thấy **0 trường/lớp nhưng 1 trẻ** (con mình) và **ĐỌC trọn nhật ký con** (2 entry + kỹ năng + huy hiệu); admin Dế Mèn thấy **0 trẻ** và **0 journey/skills/badges** (D48). Linh hồn sống trong RLS, không chỉ trong tài liệu.

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
| **Curriculum** | `programs`(**TOÀN CỤC** — D40) · `age_groups` · `levels` · `themes` · `lessons` · `lesson_versions`(immutable) · **`program_distributions`** · **`program_distribution_items`** | ✅ **RLS XONG** (mig 017 — member-read/admin-write; lesson_versions no-UPDATE. D52) |
| **Idea** | `ideas` | ✅ **RLS XONG** (mig 017 — scoped theo trường+proposer. D52) |
| **Sessions** | **`class_distributions`**(✅ READ mig 011) · `lesson_sessions` · **`session_teachers`** · **`session_media`** · `session_reports` · `child_observations` | ✅ **RLS XONG** (mig 018 — scope lead/assistant; admin-no-PII; school-admin step-in report. D53) |
| **Journey/Badge** | `child_journey`(**gốc child + source** — D40) · `child_skills` · `badges` · `child_badges` · `home_activities` | ✅ **RLS XONG** (mig 019 — nhóm A gắn-trẻ PH/trường read; nhóm B catalog. D54) |
| **Moments** | `learning_moments` · `moment_children` · `albums` | 🔒 chưa policy |
| **Privacy** | `consents`(8 loại) · `privacy_requests` · `share_links` | 🔒 chưa policy — D47 |
| **Media** | `media_assets`(Bunny-aware) · `media_variants` | 🔒 chưa policy — D60-D69 (Edge-gated) |
| **Business** | `school_subscriptions` · `school_subject_entitlements` · `pricing_config` | 🔒 chưa policy — D51 |
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
**Consent engine 2 tầng** · **Media security Bunny signed-URL + watermark động + audit per-view** (Tài liệu G) · sensitive access gating · `child_journey` xuyên-tổ-chức · `child_observations` tap-first · duplicate/merge wizard · `classes`/`enrollments` · School Portal · Parent Portal cảm xúc · **license seat×môn** · **trigger guard chống leo thang cột** (D28 — v3).

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

> **DB tầng cấu trúc = XONG** (44 bảng mig 001–007). **RLS helpers XONG** (008). **RLS cụm Org/People XONG** (mig 011–016) **+ Curriculum** (017) **+ Sessions** (018) **+ Journey** (019), đều nghiệm thu login thật §7. **~26 bảng còn lại CHƯA policy → khóa kín** (Moments/Privacy/Media/Business/Ops) — viết theo cụm là việc chính.

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
| 011 | `011_rls_org_backbone_read` | **READ**: schools(2) · classes(2) · profiles(+same_school) · class_distributions(2) + helper `class_school_id(uuid)` |
| 012 | `012_rls_children_people_read` | **READ**: children(parent+school, KHÔNG admin — D48) · enrollments(2) · child_parents(2) · child_transfers(2) + helper `child_in_my_school(uuid)` |
| 013 | `013_rls_org_write` | **WRITE**: classes(insert+update) · enrollments(insert+update) — master/sub-admin scoped + `is_school_admin()` (**non-definer**) |
| 014 | `014_rls_roster_write` | RPC `create_child_and_enroll(...)` (atomic, né RETURNING-câm — D29) · children UPDATE · `guard_children_protected_cols` trigger (D28) · child_parents insert/delete |
| 015 | `015_rls_escalation_safe_write` | profiles(update+insert provision) · schools(insert admin + update) · `guard_profiles_protected_cols` + `guard_schools_protected_cols` (D28) |
| 016 | `016_harden_guard_function_grants` | revoke public/anon EXECUTE khỏi 3 guard function (D15) |
| 017 | `017_rls_curriculum` | **RLS Curriculum (26 policy)**: 7 catalog × {select member · insert/update admin} · `lesson_versions` {select · insert admin — KHÔNG update = immutable} · `ideas` {select scoped · insert member · update admin} + helper `current_school_id()`. D52 |
| **018** | `018_rls_sessions` | **RLS cụm Sessions (15 policy)**: 5 bảng (`lesson_sessions`/`session_teachers`/`session_media`/`session_reports`/`child_observations`) — READ `same_school(session_school_id)` (admin+PH loại); WRITE lead/assistant/school-admin theo bảng (D45/D48; report có school-admin step-in). + 3 helper `cd_school_id`/`session_school_id`/`is_session_lead` (secdef, re-verify D15). D53 |
| **019** | `019_rls_journey` | **RLS cụm Journey (15 policy)**: nhóm A gắn-trẻ (`child_journey`/`child_skills`/`child_badges`) READ `is_child_parent OR child_in_my_school` (admin loại — D48), WRITE `child_in_my_school`; nhóm B catalog (`badges`/`home_activities`) READ mọi vai, WRITE admin. D46 (PH không tự trao badge) + D54 |
| seed | `seed_001_org_people_fixture` | 1 trường DEMO-001 + lớp Mầm A + master/teacher/parent + bé Jenny + enrollment + link PH (dùng `session_replication_role=replica` — D30) |
| seed | `seed_002_curriculum_fixture` | 2 program (CTAN+Ballet) + age_groups/levels/themes/lessons + 2 lesson_versions + 2 program_distributions + 2 items + 1 idea. Idempotent NOT EXISTS |
| seed | `seed_003_sessions_fixture` | 1 chuỗi: class_distribution(CTAN, lead=Cô Thúy Ngân) → lesson_session(completed) → session_teacher → child_observation(bé Jenny) → session_report. Idempotent, không cần replica (cụm không guard) |
| seed | `seed_004_journey_fixture` | bé Jenny: 1 badge def + 2 child_journey(source 'demen') + 1 child_skills + 1 child_badges(confirmed) + 1 home_activities. Idempotent |

**Hàm SECURITY DEFINER = 26:** 16 cũ (3 trigger nền + 12 helper + `rls_auto_enable` benign) + 6 v3 (`class_school_id`, `child_in_my_school`, `create_child_and_enroll`, 3 guard) + 1 v4 (`current_school_id`) + 3 v5 (`cd_school_id`, `session_school_id`, `is_session_lead`). **Non-definer:** `is_school_admin()`.
**RLS policy = 86** (4 mig 009 + 26 mig 011–015 + 26 mig 017 + 15 mig 018 + 15 mig 019).

**Chốt thi công (cụ thể hơn móng C, ĐỪNG "sửa lại"):**
- RLS bật ngay lúc tạo bảng, **deny-by-default**; chưa policy = đọc rỗng.
- `children` KHÔNG có `school_id` → "trẻ thuộc trường nào" đi vòng `enrollments→classes.school_id`, **gói trong helper definer** (`child_in_my_school`) tránh đệ quy.
- **D48 sống trong policy:** `children`/`enrollments`/`child_parents`/`child_transfers` + `child_observations`/`session_reports` + `child_journey`/`child_skills`/`child_badges` KHÔNG mở cho `is_admin()`. Admin xem định danh → `request_sensitive_access` (Edge, sau).
- **Escalation guard (D28):** RLS gác ROW; trigger `BEFORE UPDATE` ghim CỘT leo thang.
- **RETURNING-câm (D29):** raw INSERT không lấy được id khi SELECT policy hẹp → RPC atomic.
- **Helper định tuyến Sessions (v5):** `cd_school_id`/`session_school_id`/`is_session_lead` — secdef bypass RLS, đường đi `session→class_distribution→class→school`.
- **`current_role()`** → đã đổi tên **`current_profile_role()`** (keyword).
- **`has_active_seat(profile_id)` V1** = trường có subscription active + seat_count>0.
- **Seed cụm không-guard** (Sessions/Journey) KHÔNG cần `session_replication_role` — chỉ cụm có guard trigger (Org/People) mới cần (D30).

**Bước kế (DB-first, §14 C):** ✅ Curriculum/Sessions/Journey XONG → **cụm còn lại theo độ độc lập:** Privacy/Consent (D47, engine 2 tầng) · Business/License (D51) · Moments · Ops · **Media** (mỏng ở RLS, phần thịt = Edge Functions — gộp với Phase 4 Edge). → test login thật → Edge Functions media → UI Chặng 2 (rời panel-test).

---

## 7. ⭐ TẦNG APP (Lovable + TanStack Start)

> **Stack thật (chốt):** **TanStack Start** (file-routing `src/routes/`, SSR; KHÔNG Vite SPA + React Router; KHÔNG cần `vercel.json`). SSR loader **không có JWT** → fetch auth-gated **client-side** sau hydrate (D13/D82). Deploy: chốt Chặng 8.

- **Lovable project** nối **native Supabase integration** vào `dma` (đúng org "Dế Mèn Art"). Client `VITE_*` (URL + anon); types auto-gen (không sửa tay). Domain preview hiện: `demenart.lovable.app`.
- **Routes chạy thật:** `/` landing · `/auth` (signInWithPassword, no self-signup) · `_authenticated` gate · **`/portal`** · **`/portal/modules`** Trung Tâm Tra Cứu · **`/portal/rls-test`** panel test internal.
- **⭐ `/portal/rls-test` (panel nghiệm thu RLS) — 7 mục:** user hiện tại · count Org/People · nút escalation (xanh=guard giữ) · count Curriculum + nút write-block program · **count Sessions (buổi/GV/media/báo cáo/ghi chú PII) + nút write-block observation** · **count Journey (nhật ký/kỹ năng/huy hiệu/ĐN huy hiệu/HĐ ở nhà) + nút write-block entry nhật ký**. Fetch client-side `useEffect`. **Dùng để chấm ma trận scope bằng login thật.**
- **✅ NGHIỆM THU v3 (4 login thật):** ma trận Org/People + 3 banner escalation xanh. D48 admin-0-trẻ, D40 parent-0-trường-1-trẻ ĐẠT.
- **✅ NGHIỆM THU v4 (Curriculum):** parent 0 program; teacher/master/admin 2/2/2; `ideas` scoped; teacher ghi program → DB chặn.
- **✅ NGHIỆM THU v5 (Sessions):** READ — parent 0 toàn bộ, super_admin 0 (lesson_sessions/observations/reports), thành viên trường 1/1/0/1/1. WRITE — master ĐỌC observation nhưng GHI bị chặn (`violates RLS policy for child_observations`); teacher-lead ghi observation THÀNH CÔNG. (D45 "thấy mà không thao tác" + D48.)
- **✅ NGHIỆM THU v5 (Journey — trái tim DMA):** parent ĐỌC trọn nhật ký con (2 entry + 1 kỹ năng + 1 huy hiệu); super_admin 0 ở journey/skills/badges nhưng đọc được catalog (badges/home_activities 1/1); parent bấm thêm entry → DB chặn (`violates RLS policy for child_journey`). 3 phép thử linh hồn ĐẠT.
- **Security scanner Lovable:** 7–13 issue → nhiễu đúng thiết kế (no-policy = deny-by-default; signed-in execute definer = expected — D14) + 1 thật (Leaked Password = toggle Supabase). **KHÔNG "Try to fix all".**
- **CHƯA làm:** tách 4 portal riêng; màn CRUD vận hành (rời panel-test); publish URL công khai; dọn row test (`note`/`entry_type` = 'WRITE-BLOCK TEST (panel)').

---

*Skeleton v0.6 — **RLS cụm Org/People (011–016) + Curriculum (017) + Sessions (018) + Journey (019) XONG, nghiệm thu login thật 4 vai trò.** 26 hàm definer · 86 policy. Nguồn: Tài liệu A–G UPDATED + tầm nhìn founder + DMWS v170. Cập nhật "tới đâu ghi tới đó". Khi thêm bảng/module/Edge/policy mới → thêm dòng + cập nhật Trung Tâm Tra Cứu cùng nhịp (KỶ LUẬT VÀNG).*
