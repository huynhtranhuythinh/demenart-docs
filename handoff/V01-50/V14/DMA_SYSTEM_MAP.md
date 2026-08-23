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

## 3. BẢN ĐỒ BẢNG (theo Tài liệu C v2 — 46 bảng · ✅ ĐÃ THI CÔNG mig 001–032 · RLS bật · chi tiết §6)

| Cụm | Bảng chính | Trạng thái RLS |
|---|---|---|
| **Identity/Org** | `profiles`(user_id nullable, permissions[]) · `schools`(master_profile_id, settings) · `classes`(**HOMEROOM**) | ✅ **READ+WRITE XONG** (mig 011/013/015) |
| **Children/Parents** | `children`(global_child_id, `identity_user_id` ngỏ — D41) · `child_parents`(≤2) · **`enrollments`**(trẻ×homeroom) · `child_transfers` · `child_duplicates` | ✅ XONG (mig 012/013/014) — ⏳ `child_duplicates` hoãn (admin-ops) |
| **Curriculum** | `programs`(**TOÀN CỤC** — D40) · `age_groups` · `levels` · `themes` · `lessons` · `lesson_versions`(immutable) · **`program_distributions`** · **`program_distribution_items`** | ✅ **RLS XONG** (mig 017 — member-read/admin-write; lesson_versions no-UPDATE. D52) |
| **Idea** | `ideas` | ✅ **RLS XONG** (mig 017 — scoped theo trường+proposer. D52) |
| **Sessions** | **`class_distributions`**(✅ READ mig 011) · `lesson_sessions` · **`session_teachers`** · **`session_media`** · `session_reports` · `child_observations` | ✅ **RLS XONG** (mig 018 — scope lead/assistant; admin-no-PII; school-admin step-in report. D53) |
| **Journey/Badge** | `child_journey`(**gốc child + source** — D40) · `child_skills` · `badges` · `child_badges` · `home_activities` | ✅ **RLS XONG** (mig 019 — nhóm A gắn-trẻ PH/trường read; nhóm B catalog. D54) |
| **Moments** | `learning_moments` · `moment_children` · `albums` | ✅ **RLS XONG** (mig 024–025 — cụm #8; admin-no-PII; PH-không-tạo-content; gate `approved` 2 tầng moment+tag. D58) |
| **Privacy** | `consents`(8 loại) · `privacy_requests` · `share_links` | ✅ **RLS XONG** (mig 020 — Fork 1A/2A/3A; engine min ở Edge. D55) |
| **Media** | `media_assets`(Bunny-aware) · `media_variants` | 🔒 deny-by-default (Edge-only) · ⭐ **MEDIA SERVING 2 NHÁNH SỐNG:** học liệu (gate `check_curriculum_media_access` mig 029, D75 + RPC list `list_curriculum_media` mig 031) + ảnh trẻ (`media_consent_check` mig 026, D71) qua Edge `get_signed_media_url` route-theo-cột-link · ⭐ **UPLOAD SỐNG (ảnh trẻ, v13):** gate `check_media_upload_access` (mig 032, D77) + Edge `upload_media` PUT Bunny Storage. **Topology 3-zone** + storage-key≠token-key per-zone (D74/D77) |
| **Business** | `school_subscriptions` · `school_subject_entitlements` · `pricing_config` | ✅ **RLS XONG** (mig 021 — subscription chủ-trường-read che tiền · entitlement+pricing member-read · WRITE admin-only. D56) |
| **Vận hành/Ops** | `notifications` · `support_requests` · `audit_logs` | ✅ **RLS XONG** (mig 023 — noti self-scope · support self/admin · audit admin-read+append-only. D57) |
| **Config (móng)** | `notification_types`(registry template) · `app_settings`(key-value) | ✅ **MỚI mig 022 + RLS 023** — notification_types READ mọi-vai/WRITE admin · app_settings READ is_public-or-admin/WRITE admin. D59 |
| **Registry** | `admin_module_groups` · `admin_modules` | ✅ READ (mig 009) |

**Edge Functions (server-side, giữ secret):** ✅ **`get_signed_media_url`** (2 nhánh SỐNG v11+v12 — học liệu D75 + ảnh trẻ D71, route-theo-cột-link) · ✅ **`upload_media`** (ảnh trẻ SỐNG v13 — D77; PUT Bunny Storage, Verify JWT OFF) · ⬜ `create/resolve/revoke_private_share_link` · ⬜ `request_sensitive_access`. **Throwaway chờ xóa:** `bunny-sign-test` (smoke-test ký không gate).

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

> **DB tầng cấu trúc = XONG** (46 bảng mig 001–007 + 022 móng config). **RLS helpers XONG** (008). **RLS cụm Org/People** (011–016) **+ Curriculum** (017) **+ Sessions** (018) **+ Journey** (019) **+ Privacy/Consent** (020) **+ Business/License** (021) **+ Ops/Config** (023) **+ Moments** (024–025), đều nghiệm thu login thật §7. **✅ 8/8 cụm RLS XONG.** ⭐ **Media serving BẮT ĐẦU (v11): slice học liệu sống** (engine gate mig 029 D75 + Edge `get_signed_media_url` + topology 3-zone D74); nhánh ảnh trẻ (consent) chờ slice sau.

**Sổ migration (boot phiên sau dựa vào đây, đừng audit mò):**

| # | File | Sinh ra |
|---|---|---|
| 001 | `001_foundation` | 14 enums · `set_updated_at()` · programs · age_groups · levels · schools · profiles · classes |
| 002 | `002_children_enrollment` | children · child_parents · enrollments · child_transfers · child_duplicates · trigger `enforce_max_two_parents` |
| 003 | `003_curriculum` | themes · lessons · lesson_versions · program_distributions · program_distribution_items · ideas · trigger `lesson_version_autoincrement` |
| **022** | `022_config_foundation` | **CẤU TRÚC (móng config — D59):** tạo `notification_types`(registry template: slug+title+body_template+audience+icon+sound+position+enabled) + `app_settings`(key-value, is_public) + FK `notifications.type→notification_types(slug)` NOT NULL. RLS bật, chưa policy. KHÔNG helper/guard mới |
| **023** | `023_rls_ops_config` | **RLS cụm Ops/Config (12 policy)**: notifications {select/update self} · support_requests {select self+admin · insert self · update admin} · audit_logs {**select admin only** — carve-out, append-only no-insert} · notification_types {select mọi-vai · insert/update admin} · app_settings {select is_public-or-admin · insert/update admin}. KHÔNG helper mới. D57 |
| **024** | `024_rls_moments` | **RLS cụm Moments (9 policy + 2 helper)**: learning_moments {select nhân-sự-trường OR PH-approved · insert/update school} · moment_children {select PH OR school · write school} · albums {select 2-nhánh · write school}. + helper `moment_school_id`/`is_moment_parent` (secdef, re-verify D15). Media giữ Edge-only. D58 |
| **025** | `025_fix_moment_children_approved_gate` | **VÁ (login thật bắt):** siết moment_children SELECT thêm gate `approved` (PH không suy ra được bản nháp con qua đếm tag). + helper `moment_is_approved` (secdef). Policy count KHÔNG đổi (drop+create 1 policy). D58 |
| **026** | `026_fn_media_consent_check` | **CONSENT ENGINE (D71)** — secdef `media_consent_check(moment_id, viewer_profile, action)` → jsonb verdict. MIN-multi-child · school-staff bypass · gate approved · cổng khung-trường min(trường,PH). KHÔNG schema mới (audit A1: `media_assets` đã đủ field từ mig 005). Grant `authenticated`. Test thẳng SQL Editor (nhận tham số). 6 verdict ĐẠT |
| **027** | `027_fn_operational_rpc` | **RPC VẬN HÀNH (D72)** — secdef `create_notification(slug,profile_id,payload)` (validate slug+enabled, không render template) + `write_audit_log(action,fields jsonb)` (append-only). **"system-only writer": REVOKE public/anon/`authenticated`, grant CHỈ `service_role`** (chống spam noti + forge audit). KHÔNG schema mới. Verify grantee = postgres+service_role |
| **028** | `028_fn_get_child_journal` | **RPC ĐỌC CURATED (D73)** — secdef `get_child_journal(child_id)` → jsonb `{journey[],skills[],badges[]}`. Gate `is_child_parent OR child_in_my_school` (gương D54) rồi JOIN `programs`/`lesson_sessions`/`badges` (bypass RLS cố ý) trả **CHỈ nhãn an toàn** (program_name + session_title + badge title/desc), KHÔNG lộ giáo trình. Lọc badge `confirmed` (D46). Grant `authenticated`. KHÔNG schema mới. Verify D15 grant `[]`; nhãn resolve đẹp. Gate test login thật |
| **030** | `030_child_media_branch` | **NHÁNH ẢNH TRẺ (D75 mở rộng/D76)** — cột `media_assets.linked_moment_id` (FK→learning_moments) + `get_child_journal` (CREATE OR REPLACE) trả thêm `moments[]` (chỉ approved, kèm media_id). + seed inline 1 ảnh trẻ (`/jenny_buoi1.jpg`, `private_child_media`, zone `dma-private`) móc moment approved Jenny. KHÔNG hàm definer mới (chỉ +cột + replace RPC). Verify D71 nhận-tham-số: approved→ok, draft→moment_not_approved, D15 `[]` |
| **031** | `031_list_curriculum_media` | **RPC CURATED đọc track học liệu (D73 reapply/D75)** — secdef `list_curriculum_media()` trả track entitled của trường caller (media_id+title+flags); gate `current_school_id() IS NOT NULL` (PH/admin→`[]`); JOIN media→lesson_version→lesson + EXISTS entitlement active. Grant `authenticated`, verify D15 `[]`. KHÔNG schema mới. Vì `media_assets` Edge-only nên client không query trực tiếp → cần RPC này cho player liệt kê |
| **032** | `032_check_media_upload_access` | **GATE UPLOAD ảnh moment (D77)** — secdef `check_media_upload_access(moment_id, viewer_profile)` → verdict: nhân-sự-ĐÚNG-trường-moment (gương D58 same_school); PH/admin school NULL → `not_school_member`. Trả target_zone/access_level/class_id. Grant `authenticated`+`service_role`, verify D15 `[]`. Ráp Edge `upload_media`. KHÔNG schema mới. test_staff allowed / test_parent blocked ĐẠT |
| **033** | `033_check_curriculum_upload_access` | **GATE UPLOAD học liệu (D77 mở rộng — chiều GHI zone `dma-learning`)** — secdef `check_curriculum_upload_access(lesson_version_id, viewer_profile)` → verdict: chỉ **admin nội dung Dế Mèn** (`role IN super_admin/content_admin/senior_content_admin`); GV/master/PH → `not_curriculum_admin`. Resolve lesson_version→lesson→program_id. Trả target_zone=`dma-learning`/access_level=`private_curriculum`/program_id. Grant `authenticated`+`service_role`, verify D15 `[]`. Ráp Edge `upload_media` nhánh học liệu. KHÔNG schema mới. **(v14 ĐẠT verify SQL:** super_admin→ok / master+teacher+parent→not_curriculum_admin / bad→not_found.) |
| **034** | `034_list_lesson_versions_for_admin` | **RPC CURATED chọn bài (D73 reapply)** — secdef `list_lesson_versions_for_admin()` trả `{items:[{id,label:"Tên — vN",program_id}]}` cho dropdown màn upload học liệu; gate `role IN admin nội dung` (else `error:not_curriculum_admin`/`not_authenticated`). **Sinh ra vì** query Lovable embed `lesson:lessons(...)` lỗi **PGRST201 ambiguous** (lesson_versions có 2 FK tới lessons: `lesson_id` + `current_version_id`) → RPC JOIN tường minh `lesson_id`. Grant `authenticated`+`service_role`, verify D15 `[]`. KHÔNG schema mới |
| seed | `seed_009_group_moment` | **MIN-multi-child LIVE.** +Bé Jimmy (`children`, dùng `session_replication_role=replica` — D30 vì children có guard) + enroll lớp Mầm A (HS-002) + link PH chung `parent.demo` + 1 moment NHÓM approved tag Jenny&Jimmy + consent Jimmy CỐ Ý chỉ `privacy_ack` (thiếu `group_moment_in_class`). Verify engine D71 nhận-tham-số: child=2→required `group_moment_in_class`, Jimmy thiếu→`blocking=[Jimmy]`; staff bypass. +1 dòng positive cấp Jimmy `group_moment_in_class` → `ok`. Idempotent id cố định |
| seed | `seed_007_ops_config` | catalog 10 `notification_types` (moment_new/child_lesson_done/consent_request/...) + 12 `app_settings` (footer/contact/social/pwa/i18n + 1 internal is_public=false) + demo: 4 noti (parent 2/teacher 1/master 1) · 2 support_request · 2 audit_log (admin). Idempotent ON CONFLICT/NOT EXISTS, không replica. **⚠️ v9: sửa `body_template` bỏ "Bé " thừa (`'Bé {child}...'`→`'{child}...'`) — đã UPDATE live; PHẢI sửa file seed_007 trong repo để re-seed không tái lặp "Bé Bé Jenny"** |
| seed | `seed_008_moments` | bé Jenny: 2 learning_moments (1 approved + 1 draft, lớp Mầm A, uploaded_by teacher) + 2 moment_children (tag bé cả 2) + 1 album. Idempotent guard caption/title, không replica |
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
| **020** | `020_privacy_consent_rls` | **RLS cụm Privacy/Consent (9 policy)**: `consents` READ `is_child_parent OR child_in_my_school` / WRITE **chỉ PH** (Fork 1A); `privacy_requests` READ admin(**carve-out D48**)+self+school-admin / triage admin+school-admin (Fork 2A); `share_links` creator-only (Fork 3A). Engine min(trường,PH) = Edge (D47), KHÔNG ở RLS. KHÔNG helper mới. D55 |
| **021** | `021_rls_business_license` | **RLS cụm Business/License (9 policy)**: `pricing_config` {select member · insert/update admin} · `school_subscriptions` {select **chủ-trường** (`is_school_admin AND same_school`) — che cột tiền · insert/update admin} · `school_subject_entitlements` {select **mọi thành viên** (`same_school`) · insert/update admin}. WRITE admin-only cả 3 (trường không tự cấp license). KHÔNG DELETE, KHÔNG helper mới. D56 |
| seed | `seed_006_business_license` | trường demo: `pricing_config` 4 key (subject 5tr/seat 500k/storage) + 1 `school_subscriptions`(active, 4 seat, total 12tr, paid) + 2 `school_subject_entitlements`(CTAN+Ballet). Công thức D51 (2 môn×5tr)+(4 seat×500k)=12tr verify khớp. Idempotent, không guard → không replica |
| seed | `seed_005_privacy_consent` | bé Jenny: 4 consent (3 grant + `demen_marketing` false) + 1 `privacy_request`(data_access, có child, status new). Tự-khám-phá id qua `child_parents`. Idempotent, không cần replica (cụm không guard) |
| seed | `seed_001_org_people_fixture` | 1 trường DEMO-001 + lớp Mầm A + master/teacher/parent + bé Jenny + enrollment + link PH (dùng `session_replication_role=replica` — D30) |
| seed | `seed_002_curriculum_fixture` | 2 program (CTAN+Ballet) + age_groups/levels/themes/lessons + 2 lesson_versions + 2 program_distributions + 2 items + 1 idea. Idempotent NOT EXISTS |
| seed | `seed_003_sessions_fixture` | 1 chuỗi: class_distribution(CTAN, lead=Cô Thúy Ngân) → lesson_session(completed) → session_teacher → child_observation(bé Jenny) → session_report. Idempotent, không cần replica (cụm không guard) |
| seed | `seed_004_journey_fixture` | bé Jenny: 1 badge def + 2 child_journey(source 'demen') + 1 child_skills + 1 child_badges(confirmed) + 1 home_activities. Idempotent |

**Hàm SECURITY DEFINER = 38:** 16 cũ (3 trigger nền + 12 helper + `rls_auto_enable` benign) + 6 v3 (`class_school_id`, `child_in_my_school`, `create_child_and_enroll`, 3 guard) + 1 v4 (`current_school_id`) + 3 v5 (`cd_school_id`, `session_school_id`, `is_session_lead`) + 3 v8 (`moment_school_id`, `is_moment_parent`, `moment_is_approved`) + 3 v9 (`media_consent_check` — grant authenticated; `create_notification`, `write_audit_log` — grant CHỈ service_role) + 1 v10 (`get_child_journal` — grant authenticated; D73) + 1 v11 (`check_curriculum_media_access` — grant authenticated+service_role; D75) + **2 v13 (`list_curriculum_media` — grant authenticated, RPC đọc track entitled D75; `check_media_upload_access` — grant authenticated+service_role, gate upload D77)** + **2 v14 (`check_curriculum_upload_access` — grant authenticated+service_role, gate upload học liệu D77; `list_lesson_versions_for_admin` — grant authenticated, RPC chọn bài né embed PGRST201)**. *(mig 030 KHÔNG thêm hàm — chỉ +cột `linked_moment_id` + CREATE OR REPLACE `get_child_journal`.)* **Non-definer:** `is_school_admin()`. **Edge Functions (KHÔNG phải hàm Postgres):** `get_signed_media_url` (2 nhánh: học liệu + ảnh trẻ) · `upload_media` (**2 nhánh: ảnh trẻ → `dma-private` · học liệu → `dma-learning`**, route theo `moment_id` vs `lesson_version_id`, v14).
**RLS policy = 125** (4 mig 009 + 26 mig 011–015 + 26 mig 017 + 15 mig 018 + 15 mig 019 + 9 mig 020 + 9 mig 021 + 12 mig 023 + 9 mig 024). *(mig 025 thay nội dung 1 policy, không đổi count.)*

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

**Bước kế (DB-first, §14 C):** ✅ **8/8 CỤM RLS XONG**. ✅ Consent engine (mig 026, D71) + RPC vận hành (mig 027, D72) + RPC đọc curated (mig 028, D73). ✅ **UI Chặng 2 ĐÓNG 4/4** (notifications · consent · support · journal). ⭐ **MEDIA ĐỐI XỨNG XONG (v11–v13):** ĐỌC — học liệu (mig 029 D75 + player Portal GV mig 031) + ảnh trẻ (mig 030 D71, journal có ảnh thật) qua `get_signed_media_url`; GHI — ảnh trẻ upload (mig 032 D77 + Edge `upload_media`). Cả 2 zone, cả 2 chiều, nghiệm thu login thật. **Kế tiếp:** B2 upload học liệu zone `dma-learning` (người upload = admin, cùng Edge) → group-moment ≥2 trẻ (MIN-multi-child LIVE) → tách 4 portal → deploy demenart.com. **Hoãn có theo dõi:** anti-fraud device/GPS (D70) · DRM (V2/V3) · parent community (V2). **Dọn:** xóa `bunny-sign-test` · lưu mig 026–032 repo · ảnh test DMWS móc nhầm moment Jenny.

---

## 7. ⭐ TẦNG APP (Lovable + TanStack Start)

> **Stack thật (chốt):** **TanStack Start** (file-routing `src/routes/`, SSR; KHÔNG Vite SPA + React Router; KHÔNG cần `vercel.json`). SSR loader **không có JWT** → fetch auth-gated **client-side** sau hydrate (D13/D82). Deploy: chốt Chặng 8.

- **Lovable project** nối **native Supabase integration** vào `dma` (đúng org "Dế Mèn Art"). Client `VITE_*` (URL + anon); types auto-gen (không sửa tay). Domain preview hiện: `demenart.lovable.app`.
- **Routes chạy thật:** `/` landing · `/auth` (signInWithPassword, no self-signup) · `_authenticated` gate · **`/portal`** · **`/portal/modules`** Trung Tâm Tra Cứu · **`/portal/rls-test`** panel test internal · **`/portal/notifications`** (màn thật ĐẦU TIÊN Chặng 2, v9) · **`/portal/consent`** ⭐ v10 (Quyền riêng tư của con — 4 nhóm toggle, consents R/W) · **`/portal/support`** ⭐ v10 (Trợ giúp — category select + message, self-scope) · **`/portal/journal`** ⭐ v10 (Nhật ký của con — TRÁI TIM DMA, gọi RPC `get_child_journal`) · **`/portal/curriculum`** ⭐ v13 (Học liệu CTAN — player nhạc + watermark động, RPC `list_curriculum_media` + Edge `get_signed_media_url`) · **`/portal/moments`** ⭐ v13 (Khoảnh khắc của lớp — upload ảnh qua Edge `upload_media` + preview ngay).
- **⭐ 4 MÀN CHẶNG 2 (Bunny-độc-lập) — cùng khuôn pattern:** auth → fetch/RPC **client-side** sau hydrate (D13) → render Vietnamese ấm (album, không dashboard lạnh) → ghi ngược (consent/support). Nav header: chuông (noti) · ShieldCheck (consent) · LifeBuoy (support) · BookHeart (journal). Media trong journal = **placeholder "Hình ảnh sẽ sớm có"** (hook chờ Edge Ngã A).
- **⭐ `/portal/rls-test` (panel nghiệm thu RLS) — 10 mục:** user hiện tại · count Org/People · nút escalation · count Curriculum + write-block · count Sessions + write-block observation · count Journey + write-block entry · count Privacy + write-block consent · count License + write-block subscription · **count Vận hành (noti/support/audit/app_settings/internal-flag) + nút forge audit** · **count Moments (khoảnh khắc/tag/album) + nút tạo khoảnh khắc**. Fetch client-side `useEffect`. **Dùng để chấm ma trận scope bằng login thật.**
- **✅ NGHIỆM THU v3 (4 login thật):** ma trận Org/People + 3 banner escalation xanh. D48 admin-0-trẻ, D40 parent-0-trường-1-trẻ ĐẠT.
- **✅ NGHIỆM THU v4 (Curriculum):** parent 0 program; teacher/master/admin 2/2/2; `ideas` scoped; teacher ghi program → DB chặn.
- **✅ NGHIỆM THU v5 (Sessions):** READ — parent 0 toàn bộ, super_admin 0 (lesson_sessions/observations/reports), thành viên trường 1/1/0/1/1. WRITE — master ĐỌC observation nhưng GHI bị chặn (`violates RLS policy for child_observations`); teacher-lead ghi observation THÀNH CÔNG. (D45 "thấy mà không thao tác" + D48.)
- **✅ NGHIỆM THU v5 (Journey — trái tim DMA):** parent ĐỌC trọn nhật ký con (2 entry + 1 kỹ năng + 1 huy hiệu); super_admin 0 ở journey/skills/badges nhưng đọc được catalog (badges/home_activities 1/1); parent bấm thêm entry → DB chặn (`violates RLS policy for child_journey`). 3 phép thử linh hồn ĐẠT.
- **✅ NGHIỆM THU v6 (Privacy/Consent):** consents READ — admin 0 (D48), master/teacher/parent 5/5/4; privacy_requests READ — **teacher 0 vs master 1** (nhánh `is_school_admin()`) + admin 1 (carve-out 2A); WRITE — parent ghi consent THÀNH CÔNG, master & teacher ghi → DB chặn (`violates RLS policy for consents`, Fork 1A); admin nút → "không child_id khả kiến" (D48). 2 bằng chứng vàng ĐẠT.
- **✅ NGHIỆM THU v7 (Business/License):** pricing_config — admin/master/teacher 4/4/4, **parent 0** (no school_id); school_subscriptions READ — admin/master 1/1, **teacher 0** (che tiền), parent 0; school_subject_entitlements — admin/master/teacher 2/2/2, parent 0. WRITE — **master bấm thêm subscription → DB chặn** (`violates RLS policy for school_subscriptions`, admin-only). 3 bằng chứng vàng ĐẠT (teacher-0-vs-master-1 che tiền · parent-0-cả-3 · master-write-block).
- **✅ NGHIỆM THU v8 (Ops/Config — 4 vai):** notifications — info@ 0/master 1/teacher 1/parent 2; support_requests — **master 0 vs parent/teacher 1 vs admin 2** (tách người gửi); audit_logs — **non-admin 0 vs admin 2** (carve-out D48 append-only); app_settings — admin 12+CÓ vs non-admin 11+KHÔNG (cổng is_public); **forge audit chặn KỂ CẢ admin** (`violates RLS policy for audit_logs`). 4 bằng chứng vàng ĐẠT.
- **✅ NGHIỆM THU v8 (Moments — cụm #8, đóng 8/8):** admin 0/0/0 (D48); trường (master/teacher) 2/2/1; **parent 1/1/1** (gate approved 2 tầng — chỉ moment+tag đã duyệt); WRITE — parent & admin tạo moment → DB chặn (`violates RLS policy for learning_moments`, D64), teacher/master ghi được. *(Login thật bắt lỗi tag=2 ban đầu → vá mig 025 `moment_is_approved` → tag về 1.)* 3 bằng chứng vàng ĐẠT.
- **✅ NGHIỆM THU v9 (UI Chặng 2 — màn thật đầu tiên):** login `Ba/Mẹ Bé Jenny Demo` (parent) → `/portal/notifications` thấy **2 noti của chính mình** (RLS self-scope D57); render **config-driven** (icon từ `notification_types.icon` map lucide · title · body ghép `body_template`↔payload · thời gian VN); phân biệt đọc/chưa-đọc (card kem + chấm cam, không badge đỏ chói — đúng tone ấm); nav chuông + badge "1" + nút "Đánh dấu tất cả đã đọc". **Khuôn pattern** (auth→fetch client-side→render qua catalog→ghi ngược) đã đứng cho các màn sau. *(Lovable tự thêm poll-30s vô hại; KHÔNG bấm "Try to fix all" với 9 scanner issue.)*
- **✅ NGHIỆM THU v10 (3 màn Chặng 2 còn lại — đóng 4/4 Bunny-độc-lập):** **Consent** — PH thấy baseline đúng (display_in_app+group ON, share/marketing OFF, privacy_ack ✓); rút `group_moment_in_class` → toggle OFF sau re-fetch (ghi DB thấm). **Support** — PH thấy **đúng 1 ticket seed của mình**, KHÔNG thấy ticket profile khác (self-scope D57); gửi yêu cầu mới (category+message) → list refresh, status default 'new'→"Mới tiếp nhận" (INSERT self qua). **Journal (trái tim)** — timeline 2 entry ("Buổi 1 — Làm quen âm thanh" gắn "Cảm Thụ Âm Nhạc Dế Mèn" + "Nhận huy hiệu mới 🎖️"), kỹ năng "Cảm thụ nhịp điệu" (chấm mềm, **không điểm/xếp hạng** D46), huy hiệu "Lần đầu giữ nhịp"; mỗi entry placeholder "Hình ảnh sẽ sớm có"; gọi RPC `get_child_journal` client-side. *(Bản nháp Support chạy nhầm tên cột → dòng NOTE "REPLACE entire screen" ở prompt khóa quét sạch, KHÔNG double route.)*
- **✅ NGHIỆM THU v11 (Media — slice học liệu, Edge):** Bunny vào lại → ký URL THẬT. **Smoke-test:** signed URL phát được `Chu_Vit_Con.mp3` (1:11), file trần `dma-learning.b-cdn.net/...` = **403** (token auth chặn đúng) → thuật toán Standard SHA256 (D74) khớp. **Gate (verify029 SQL):** member→`entitled` allowed · parent→`not_school_member` denied · D15 grant `[]` · seed media gắn lesson_version đúng. **Edge:** `get_signed_media_url` deploy chạy, tester anon → **401 `not_authenticated`** (auth gác đúng — placeholder media_id vô hại vì auth check trước). 3/3 lớp bằng chứng qua (gate logic · ký token · Edge+auth). Lớp 4 (GV login thật nghe nhạc / PH không) + watermark = slice player Portal GV sau. **`bunny-sign-test` chờ xóa** (ký không gate).
- **Security scanner Lovable:** 6–13 issue → nhiễu đúng thiết kế (no-policy=deny-by-default; signed-in execute definer=expected — D14) + Leaked Password toggle. **KHÔNG "Try to fix all".**
- **✅ NGHIỆM THU v13 (Media ĐỐI XỨNG — player học liệu + upload ảnh trẻ):** **(A — player Portal GV)** mig 031 `list_curriculum_media` verify: grant `[]`, preview-demo 1 track; login thật GV Cô Thúy Ngân `/portal/curriculum` → card "Chú Vịt Con" + badge AUDIO/MPEG → **phát nhạc thật** (0:03/1:11) + **watermark trôi** "DMA·CTAN·Trường Demo Dế Mèn·teacher.demo@…"; PH Bé Jenny → **rỗng** ("Chưa có học liệu… kích hoạt") vì school NULL. **(B1 — upload ảnh trẻ)** mig 032 verify: `test_staff_uploader`→`ok` (zone dma-private), `test_parent_blocked`→`not_school_member`, D15 `[]`; login thật GV → `/portal/moments` thấy 2 moment (approved+draft) → chọn file → **"✓ Đã tải" + ảnh hiện ngay** (upload→Bunny Storage→media_assets→ký URL→render, vòng GHI↔ĐỌC khép một màn); PH → thử tải → **"Chỉ giáo viên của trường mới tải được ảnh"** (gate chặn). Gate 2 tầng D58 vẫn sống (PH 1 moment / GV 2). **⭐ Bài học hạ tầng (D77):** Bunny Storage "Password" (read-write AccessKey, PUT) ≠ CDN token-key (ký URL) → secret riêng per-zone; endpoint region `sg.storage.bunnycdn.com`.
- **✅ NGHIỆM THU v12 (Media — nhánh ẢNH TRẺ, journal có ảnh thật — trái tim DMA):** login thật PH `parent.demo` → `/portal/journal` section **"Khoảnh khắc"**. (1) Provision zone `dma-private` (token bật) + secret `BUNNY_PRIVATE_*` + ảnh `jenny_buoi1.jpg`; file trần `dma-private.b-cdn.net/jenny_buoi1.jpg`=**403**. (2) **mig 030:** cột `media_assets.linked_moment_id` (FK→learning_moments) + `get_child_journal` trả `moments[]` (chỉ approved, kèm media_id) + seed ảnh móc moment approved của Jenny; verify pre-login (D71 nhận-tham-số): approved→`allowed:ok,display_in_app`, draft→`moment_not_approved`, D15 `[]`. (3) **Edge `get_signed_media_url` route theo cột link** — `linked_moment_id`→`media_consent_check` (D71)→ký zone `dma-private`. (4) **Bằng chứng vàng:** consent `display_in_app` ON → **ảnh thật hiện** qua signed URL; tắt consent → Edge **403 `consent_missing`**, card vẫn hiện nhưng ảnh đổi **"Đang chờ ba mẹ đồng ý cho xem ảnh này"** (negative MIN-consent LIVE — *PH thấy có khoảnh khắc của con nhưng tự cầm quyền tắt/bật*); draft không hiện. (5) **Sửa dọc đường:** **D76** CORS `x-client-info` (preflight chặn invoke — lệch SQL-pass↔live-fail) + đọc `error.context.json()` lấy reason cho UX mềm. Watermark off (ảnh con-mình, ấm như album) · download off.
- **CHƯA làm:** tách 4 portal · publish URL công khai (deploy `dma.vercel.app`→`demenart.com`) · `request_sensitive_access` (admin xem PII có audit — D48 carve) · share link ảnh cho PH ngoài (D55/D66); **dọn:** **xóa Edge `bunny-sign-test`** (smoke-test ký không gate) · **ảnh test DMWS "Gia đình Vịt Con" móc nhầm moment "vẽ tranh mùa xuân" Jenny** (xóa media_assets row + object Bunny — GV upload screenshot test) · caption "[seed]" còn ở moment thật trong DB (UI đã strip client) · row test treo (`child_observations.note`/`child_journey.entry_type`='WRITE-BLOCK TEST (panel)' + License nếu admin từng bấm + `learning_moments.caption='[panel] write-block test'`; xác nhận `drop function public._neg_test()`) · sửa file seed_007 repo (body_template bỏ "Bé " thừa — đã UPDATE live) · **lưu mig 026–034 vào repo** cùng 001–025.
- **✅ ĐÃ làm (v14):** **B2 upload học liệu** zone `dma-learning` (admin nội dung, Edge `upload_media` nhánh học liệu + mig 033 gate + mig 034 RPC chọn bài + route `/portal/curriculum-admin`) → **ma trận media FULL 2 zone × 2 chiều**. **group-moment ≥2 trẻ MIN-multi-child LIVE** (seed_009: +Bé Jimmy + moment nhóm; PH negative "đang chờ"→cấp Jimmy→ảnh hiện).

---

*Skeleton v0.15 — **✅ 8/8 CỤM RLS XONG** + ✅ Consent engine (mig 026, D71) + RPC vận hành (mig 027, D72) + RPC đọc curated (mig 028, D73) + ⭐ **MEDIA ĐỐI XỨNG HOÀN CHỈNH 2 ZONE × 2 CHIỀU:** ĐỌC — học liệu (mig 029 D75 + player Portal GV mig 031) + ẢNH TRẺ (mig 030 D71, journal có ảnh thật) qua Edge `get_signed_media_url`; GHI — ẢNH TRẺ→`dma-private` (mig 032 D77) + **HỌC LIỆU→`dma-learning` (mig 033/034 D77, admin nội dung, route `/portal/curriculum-admin`)** qua Edge `upload_media` 2 nhánh. Topology 3-zone D74; storage-key≠token-key per-zone D77 — đều nghiệm thu login thật. + ⭐ **MIN-multi-child LIVE** (seed_009: moment nhóm Jenny+Jimmy, PH chặn-vì-Jimmy→cấp→mở). + móng config mig 022. **47 bảng? KHÔNG — vẫn 46 bảng · 38 hàm definer · 125 policy · mig 001→034 · seed 001→009.** Bunny: file trần=403 cả 2 zone; signed URL phát nhạc học liệu+watermark (admin upload→GV nghe) + ảnh trẻ; upload GV/admin→Storage→preview; PH gác đúng (player rỗng / upload chặn / ảnh nhóm chờ-consent). **UI Chặng 2 + Media UI:** `/portal/{notifications,consent,support,journal,curriculum,curriculum-admin,moments}`. Kế: tách 4 portal · deploy · `request_sensitive_access` · share link PH ngoài. Nguồn: Tài liệu A–G UPDATED + tầm nhìn founder + DMWS v170. Cập nhật "tới đâu ghi tới đó". Khi thêm bảng/module/Edge/policy mới → thêm dòng + cập nhật Trung Tâm Tra Cứu cùng nhịp (KỶ LUẬT VÀNG).*
