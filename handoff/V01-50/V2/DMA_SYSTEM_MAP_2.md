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

---

## 3. BẢN ĐỒ BẢNG (theo Tài liệu C v2 — 44 bảng · ✅ ĐÃ THI CÔNG mig 001–007 · RLS bật · chi tiết §6)

| Cụm | Bảng chính | Ghi chú thép chờ / DMWS |
|---|---|---|
| **Identity/Org** | `profiles`(user_id nullable, permissions[]) · `schools`(master_profile_id, settings) · `classes`(**HOMEROOM** — không program_id) | profile trước activate; lớp = nhóm trẻ |
| **Children/Parents** | `children`(global_child_id, `identity_user_id` để ngỏ — D41) · `child_parents`(≤2) · **`enrollments`**(trẻ×homeroom, mã HS, state) · `child_transfers` · `child_duplicates` | THÉP CHỜ #2; trẻ tách ghi danh |
| **Curriculum** | `programs`(**TOÀN CỤC** — D40) · `age_groups` · `levels` · `themes` · `lessons` · `lesson_versions`(immutable) · **`program_distributions`**(roadmap/piece) · **`program_distribution_items`**(tiết XOR piece) | versioning bất biến D43; phân phối cây |
| **Idea** | `ideas`(GV đề xuất → chỉ dùng trong trường) | nhẹ hơn spec gốc |
| **Sessions** | **`class_distributions`**(rót môn vào homeroom + lead_teacher) · `lesson_sessions`(content_override) · **`session_teachers`**(lead/assistant theo tiết) · **`session_media`**(upload\|dma_library) · `session_reports` · `child_observations`(tap-first) | GV chỉnh instance, không đụng mẫu (D44) |
| **Moments** | `learning_moments`(approve+consent gate) · `moment_children`(multi-tag) · `albums` | clone event_photos DMWS |
| **Journey/Badge** | `child_journey`(**gốc child + source** — D40) · `child_skills` · `badges` · `child_badges`(suggested→confirmed) · `home_activities` | khử cạnh tranh D46 |
| **Privacy** | `consents`(8 loại) · `privacy_requests` · `share_links`(token nội bộ) | consent 2 tầng D47 |
| **Media** | `media_assets`(Bunny-aware, KHÔNG lưu URL) · `media_variants` | Tài liệu G — D60-D69 |
| **Business** | `school_subscriptions`(seat_count, storage) · `school_subject_entitlements`(môn trường thuê) · `pricing_config` | license tách bạch: (môn×giá)+(seat×giá)+storage (§5) |
| **Vận hành** | `notifications` · `support_requests` · `audit_logs`(media events) | audit nâng cao D67 |
| **Registry** | `admin_module_groups` · `admin_modules`(đủ 4 trường — D100) | Trung Tâm Tra Cứu (dựng cấu trúc; seed module khi build UI) |

**Edge Functions (server-side, giữ secret — CHƯA làm):** `get_signed_media_url` · `upload_media` · `create/resolve/revoke_private_share_link` · `request_sensitive_access`.

---

## 4. ⭐ BẢN ĐỒ TÁI DÙNG DMWS (3 nhóm)

**🟢 CLONE ĐẬM (DMWS đã cày, bê blueprint):**
Admin shell (modules/groups/permissions registry) + Trung Tâm Tra Cứu · permission **scoped** (← /b2b: thấy hết, thao tác theo phân công) · Xưởng/giáo án + **override per lớp** (← propose_override_to_workshop) · versioning bất biến (← proposal versioning) · buổi học+điểm danh+nhận xét (← workshop_events+readiness+task_report) · learning moments+tag+approve (← event_photos+community) · share token (← event_share_tokens) · org/contract (← organizations/contracts) · engine sao/badge (← Ngân hàng huy hiệu, **khử cạnh tranh**) · Trash registry · FAQ gating · **Kid Portal** (← Kid DMWS, V2).

**🟡 CLONE + SỬA:**
`schools`←organizations (thêm settings jsonb) · `children`+claim←children+claim (thêm Global ID, merge, để-ngỏ-auth) · curriculum hierarchy←catalog (thêm tầng level/age) · Child Art Profile←/toi (timeline+cột mốc trộn) · privacy_requests←claim/inquiry pipeline · Idea Library←override→Xưởng (nhẹ hơn).

**🔴 LÀM MỚI (DMWS không có / DMA đặc thù):**
**Consent engine 2 tầng** (nặng nhất) · **Media security Bunny signed-URL + watermark động + audit per-view** (Tài liệu G — DMWS chỉ có Bunny CDN công khai) · sensitive access gating · `child_journey` xuyên-tổ-chức (thép chờ) · `child_observations` tap-first · duplicate/merge wizard · `classes`/`enrollments` · School Portal · Parent Portal cảm xúc · **license seat×môn**.

**⛔ KHÔNG BÊ (DMA chặn cứng):** ví/economy/ledger · shop/rewards/redemptions/affiliate · gamification cạnh tranh (leaderboard, đua) · social feed/community · Zalo ZNS · B2C booking/promotions · online payment.

---

## 5. ĐÃ ĐỒNG BỘ TẦM NHÌN (chốt qua phiên hỏi-đáp)

Các điểm trước đây lệch giữa tài liệu V1 và tầm nhìn full — **đã chốt và đưa vào móng C v2**:
- `child_journey` có cột `source` (V1='demen'); `programs` **TOÀN CỤC** (không `school_id`); `children` để ngỏ `identity_user_id` (Kid V2).
- **Lớp = HOMEROOM đa môn (Cách Y)**: lớp KHÔNG gắn 1 môn; môn rót vào lớp qua `class_distributions`, mỗi môn có **GV chính riêng**. `enrollments` = trẻ × homeroom (1 bé nhiều phiếu).
- **Phân phối chương trình**: mẫu `program_distributions` kiểu `roadmap` (trộn tiết lẻ +/hoặc piece con) / `piece` (chuỗi tiết → giáo án); GV chỉnh trên **instance của lớp** (`lesson_sessions.content_override` + `session_media`), không đụng mẫu gốc (D44).
- **License (CHỐT — thay câu cũ "MÔN × ghế-GV"):**
  ```
  Tổng = (số Môn × giá môn) + (số tk GV × giá GV) + storage add-on
  ```
  Môn và seat **tách bạch, cộng lại**. Tk GV **subject-agnostic** (1 GV dạy mọi môn trường thuê). **Master Admin bundled** 1/trường (không dạy, không seat). **Sub-Admin** do Master tạo (permission scope). **Trợ giảng** gán theo *tiết*, seat tùy `assistant_consumes_seat`. **Storage** cấp trường + add-on. **Gate dạy** = seat active AND entitlement môn active; license-gate **tách** journey (D42).

---

## 6. ⭐ SỔ MIGRATION + TRẠNG THÁI THI CÔNG DB

> **DB tầng cấu trúc = XONG.** 44 bảng (migration 001–007) + RLS helpers (008) + harden grants (010), chạy sạch trên Supabase project **`dma`** (region Singapore). Toàn bộ **idempotent**.
> **⚠️ RLS POLICY MỚI BẮT ĐẦU (batch 1 — mig 009):** chỉ `profiles` (self + admin read) + `admin_modules`/`admin_module_groups` (authenticated read). **~40 bảng còn lại VẪN chưa policy** → khóa kín. **RLS CHƯA xong — viết policy theo cụm là việc chính phía trước.**

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
| 008 | `008_rls_helpers` | 12 helper RLS (current_profile · current_profile_role · is_admin · has_permission · user_school_ids · same_school · is_distribution_lead · is_session_teacher · user_class_ids · is_child_parent · has_subject_entitlement · has_active_seat) — SECURITY DEFINER, grant authenticated |
| 009 | `009_rls_batch1_test_login` | POLICY batch 1: profiles (select self + admin) · admin_modules/groups (select authenticated). + TEST SEED: nối profile super_admin vào user `info@demenart.com` |
| 010 | `010_harden_function_grants` | Gỡ EXECUTE public/anon khỏi mọi hàm SECURITY DEFINER (đóng finding "Public can execute"); giữ authenticated cho 12 helper |

**Triggers nền đã cài:** `set_updated_at` (15 bảng có `updated_at`) · `enforce_max_two_parents` (child_parents, BEFORE INSERT) · `lesson_version_autoincrement` (lesson_versions, BEFORE INSERT).

**Chốt thi công — cụ thể hơn móng C, ĐỪNG "sửa lại" ở phiên sau:**
- **RLS bật ngay lúc tạo bảng, deny-by-default**, chưa policy → đọc rỗng cho tới khi cấp policy.
- **Vòng FK** giải bằng: tạo bảng (cột không-FK) → `ALTER ADD CONSTRAINT` sau → `schools.master_profile_id`→profiles; `lessons.current_version_id`→lesson_versions.
- **`global_child_id`** default `gen_random_uuid()::text` (ID mờ, ổn định); format thân-thiện-người để sau, không phá dữ liệu.
- **Ref đa hình CỐ Ý không FK:** `child_journey.ref_id` · `child_badges.source_ref` · `share_links.scope_ref_id` · `audit_logs.entity_id`. KHÔNG thêm FK.
- **`learning_moments.class_id` = ON DELETE RESTRICT** (ký ức trẻ không mất theo lớp — D40/D42). Quan hệ vận hành khác phần lớn cascade / set null.
- **`media_assets` mặc định AN TOÀN:** `access_level=private_child_media` · `protection_mode=signed_url` · `stream_only=true` · `download_allowed=false` · `expires_policy_minutes=10` (D60–62). Chỉ lưu path/zone/video_id — KHÔNG URL/token/secret.
- **`version_no` tự tăng ở INSERT** (lesson_versions); **bất biến NỘI DUNG sau publish = để tầng RLS/app lo** (cần biết state mới khóa đúng — D43).
- **`state` của profiles/schools/classes/class_distributions/media = `text` default 'active'** (móng C không định nghĩa enum riêng — dùng text, không bịa enum).
- **⭐ `rls_auto_enable`** = hàm event-trigger của Supabase (do bật **"Enable automatic RLS"** lúc tạo project) — tự bật RLS cho bảng mới. **BENIGN, GIỮ** (cùng phe D23). → đếm hàm SECURITY DEFINER ra **16** (15 của mình + 1 cái này), đừng giật mình.
- **⭐ Rename helper:** `current_role()` (theo C §14) → đổi thành **`current_profile_role()`** vì `current_role` là từ khóa Postgres. Mọi policy/code dùng tên mới.
- **`has_active_seat(profile_id)` V1 =** GV thuộc trường có `school_subscriptions.state='active'` AND `seat_count>0` (schema chỉ có *đếm* seat, chưa gán ghế-từng-GV; gán chi tiết để sau).

**Bước kế (DB-first, §14 C):** tiếp **RLS policies theo cụm** (org/people → curriculum → sessions → media → journey/privacy/license → ops) + test bằng login thật → Edge Functions media → mở rộng UI.

---

## 7. ⭐ TẦNG APP (Lovable + TanStack Start) — Chặng 1 XONG

> **Stack thật (chốt):** **TanStack Start** (file-routing `src/routes/`, SSR; KHÔNG phải Vite SPA + React Router; KHÔNG cần `vercel.json`). SSR loader chạy **không có JWT** → mọi fetch auth-gated **client-side** (D82). Deploy: Lovable hosting/Cloudflare hoặc Vercel qua preset (chốt ở Chặng 8).

- **Lovable project** nối **native Supabase integration** vào project **`dma`** (đúng org "Dế Mèn Art", KHÔNG đụng "Dế Mèn Workshop" = DMWS cũ). Client dùng `import.meta.env.VITE_*` (URL + anon); types auto-gen từ schema (không sửa tay).
- **Chặng 1 đã build & TEST CHẠY THẬT:** landing `/` · `/auth` login (signInWithPassword, **no self-signup**) · `_authenticated` gate (ssr:false, getUser→redirect) · **1 `/portal`** hiện full_name+role+school_id (nếu chưa có profile → "Tài khoản chưa được kích hoạt") · **Trung Tâm Tra Cứu** `/portal/modules` đọc `admin_modules` join groups, search không dấu, empty-state (chưa seed).
- **✅ Đã chứng minh end-to-end:** login `info@demenart.com` → đọc `profiles` (RLS `profiles_select_self`) → role `super_admin` → routing `/portal` hiển thị đúng.
- **Crash đã sửa:** thiếu package `@supabase/supabase-js` → Lovable cài lại (code-only, không đụng DB).
- **CHƯA làm:** tách 4 portal riêng (`/admin /school /teacher /parent`) — hiện gộp 1 `/portal`; làm khi mỗi portal có nội dung (Chặng 2+). Publish ra URL công khai (để sau, khi app ổn + siết quyền).

---

*Skeleton v0.3 — **DB cấu trúc + RLS helpers XONG (mig 001–010); RLS policy mới batch 1; Chặng 1 app (TanStack) chạy thật.** Nguồn: Tài liệu A–G UPDATED + tầm nhìn founder + DMWS v170. Cập nhật "tới đâu ghi tới đó". Khi thêm bảng/module/Edge Function/policy mới → thêm dòng + cập nhật Trung Tâm Tra Cứu cùng nhịp (KỶ LUẬT VÀNG).*
