# DMA V127-M2 — MISSION CONTROL: ADMIN OPERATING SYSTEM REDESIGN
**Design Audit — Claude (Technical Auditor / System Architect / SaaS Platform Architect)**
**Ngày:** 2026-08-09 · **Baseline:** D344 · SYSTEM_MAP v1.32 · HEAD `6b860338` · Supabase `xcvhacymrbhdhohyylyq`
**Trạng thái:** DESIGN ONLY — không code, không migration, không modify production. **Not canonicalized.**
**Live re-pin đã chạy:** `admin_modules` (75 module · 55 live / 3 building / 5 reserved / 12 planned) + 4 nhóm nghiệp-vụ (read-only SELECT).

---

## 1. EXECUTIVE VERDICT

**Nền tảng đúng. Bàn vận hành thiếu.**

DMA Admin hôm nay là một **CONTROL PLANE** hoàn chỉnh (giám sát) nhưng **KHÔNG có OPERATION WORKSPACE** (bàn xử lý việc). Đây không phải phán đoán — nó là kết luận cứng từ 2 bằng chứng độc lập:

**Bằng chứng A — Wave 0 FAIL/BLOCKED (V127-M1.5-PHASE2A).**
Một buổi ballet thật cho một bé thật không chạy được. Nhưng lý do **KHÔNG phải lỗi nền tảng**: engine teacher/parent/RLS/consent đã đúng. Nó chết ở **3 thao tác-người tầm thường** mà Admin không làm được in-app:
1. Đổi role cô Thuý Ngân `secondary_parent → lead_teacher` + gán `school_id=VNDM`.
2. Tạo + mời + link phụ huynh "Mẹ Trang Đoàn" (chưa có account).
3. Gỡ quan hệ rác (cô đang bị link "mother" vào 1 child seed `d1000000-…`).

Cả ba rơi về SQL → SQL **bị chặn** vì `guard_profiles_protected_cols` ghim `role/school_id/user_id/permissions` khi `auth.uid()` NULL (SQL Editor). Không có màn admin nào để làm việc này bằng admin-context. **Pilot đứng vì thiếu bàn vận hành, không vì thiếu engine.**

**Bằng chứng B — Registry audit (live).**
Mọi thực thể operator cần chạm đều **`route = null`**:

| Nhóm | Module `route=null` (không có màn admin) | Có màn ở đâu? |
|---|---|---|
| school-class | `schools · classes · enrollments · class-distribution · school-entitlements` | Chỉ `/school` (master-scoped) |
| parent-child | `child-profile · child-journey · child-transfer · consents · parent-child-link` | Chỉ `/school` + `/parent` |
| system | `permissions · app-config · theme` | rải rác / null |

Nghĩa là: **năng lực vận hành người ĐÃ TỒN TẠI trong engine `/school`** (D91 master self-manage: tạo lớp, rót môn+GV, provision PH, tạo trẻ) — nhưng **platform operator không với tới được**, và **không ai đổi được role** (kể cả master — đó là cột guard-protected).

**Verdict 3 dòng:**
- **KHÔNG đổi database model.** Engine đủ. (Nguyên tắc: "thay model nếu chưa chứng minh cần thiết" — chưa cần.)
- **Xây 1 lớp WORKSPACE** trên engine đã có, cộng **đúng 1 capability engine mới**: một RPC đổi-role có-audit, admin-context (P0 duy nhất thực sự chặn pilot).
- **Tái dùng, không xây lại:** `/admin/lookup` (Smart Lookup) → nâng thành Command Search; `/admin/audit-log` (Audit Intelligence, đã có deep-link actor/child) = workflow "review audit" xong sẵn; `/admin` Mission Control dashboard = tầng TODAY sẵn có.

---

## 2. CURRENT ADMIN DIAGNOSIS (Task 1 — Audit)

**Nguyên tắc đọc bảng:** "Existing capability" = màn thật đang live. "Problem" = khoảng cách giữa *record tồn tại* (shape) và *operator làm được việc* (substance).

| Area | Existing capability (route) | User intent thật | Problem | Future direction |
|---|---|---|---|---|
| **Health / Today** | Mission Control dashboard `/admin` (health score 4 trụ, vitals, action center, school health, media/privacy) | "Hôm nay có gì cần tôi?" | Chỉ **đọc/giám sát**; action center chưa nối tới bàn xử lý; không có "pilot Wave 0 còn thiếu gì" | Giữ làm **TODAY**; nối mỗi cảnh báo → workflow tương ứng |
| **Lookup** | Smart Lookup `/admin/lookup` (tra cứu thực thể) | "Tìm người/bé/lớp để xử lý" | Là **tra cứu**, chưa phải **command surface**: kết quả không kèm quick-action, chưa gate D48 tường minh | Nâng thành **Command Search** (§5) — search → action |
| **School onboarding** | `onboard_school` RPC + form (tạo tenant + sub + entitlement + master) | "Mở trường mới" | Chỉ **tạo shell**; không có màn quản-lý-sau-tạo per-tenant từ phía admin | Cửa vào **OPERATIONS › School workspace** |
| **People ops (Trường/Lớp/Ghi danh/Phân lớp)** | `route=null` — engine: `assign_class_distribution`, `create_child_and_enroll`, raw INSERT classes/enrollments (master-scoped `/school`) | "Gán GV vào lớp, ghi danh bé" | **Không có màn admin.** Platform operator không với tới; chỉ master làm được trong tenant mình | **OPERATIONS** workspace (§6) bắc cầu engine `/school` cho operator |
| **Child / Parent ops** | `route=null` — engine: `provision_parent_and_link`, `get_child_parents`, `child_parents` (≤2), consent default-on | "Tạo bé, mời & link phụ huynh" | Không màn admin; **Wave 0 chết ở đây** | **OPERATIONS › Child/Parent workspace** (§6) |
| **Role / Account activation** | ❌ **KHÔNG TỒN TẠI** (không RPC, không màn) | "Kích hoạt tài khoản GV, sửa role sai" | `guard_profiles_protected_cols` chặn SQL; không có admin write-path → **hard blocker** | 🔴 **P0 engine gap** — RPC `admin_set_profile_role` có audit (§7/§8) |
| **Consent / Privacy** | `consents` engine (2 tầng, default-on), `request_sensitive_access` (đọc PII **có audit**, gate is_admin) | "Xem consent bé, giải trình truy cập PII" | Đọc PII đã có cửa audit; **nhưng không có view operator gom consent theo bé/gia đình** | **TRUST & SAFETY** workspace (đọc, không sửa hộ PH) |
| **Audit** | Audit Intelligence `/admin/audit-log` (7 nhóm, burst-compress, deep-link actor & child, Raw forensic) | "Ai làm gì với ai, khi nào" | **Đã tốt.** Workflow #10 xong sẵn | Giữ; nối deep-link 2 chiều từ mọi workspace |
| **Curriculum / Media** | Kho Học Liệu `/admin/curriculum-library` + notification-sounds | "Quản trị nội dung + tài sản học" | Đủ cho V1; tách bạch khỏi people-ops | **CONTENT** nhánh (ít đụng pilot) |
| **Pilot funnel** | `/admin/pilot-funnel` (quan sát first-value/return-value PH, read-only) | "Pilot đang chạy thế nào" | Read-only observation; tách rời khỏi provisioning | Nối vào **TODAY** như KPI pilot |
| **System / Policy / Config** | `/admin/policies`, `/admin/system-map`, `/admin/reference` (building), `/admin/settings`, permissions(null) | "Hiến pháp hệ thống" | Là **SYSTEM plane** đúng nghĩa; permissions chưa có màn | Gom thành **SYSTEM** (ít dùng hằng ngày) |

**Chẩn đoán một câu:** Admin có đủ **đồng hồ** (control plane) nhưng thiếu **vô-lăng + cần số** cho nghiệp vụ người; và có đúng **một dây điện bị đứt** (đổi role) khiến xe không nổ máy được cho pilot.

### Admin Persona (Task 2)

| Persona | Là ai | Cần gì (job-to-be-done) | Bàn làm việc |
|---|---|---|---|
| **Platform Operator** | super_admin / operation_admin (Jean, ops) | Health toàn hệ · sự cố · mở trường · **giải quyết permission/role sai** · unblock pilot | TODAY + OPERATIONS + TRUST |
| **School Operator** | master_admin / sub_admin (hiệu trưởng) | GV · lớp · trẻ · phụ huynh trong **tenant mình** | `/school` (đã có) — Mission Control **không thay**, chỉ cho platform operator "step-in" khi được phép |
| **Content Operator** | content/senior_content_admin | Giáo trình · học liệu · version | CONTENT (`/admin/curriculum-library`) |

> **Ranh giới thép:** Mission Control phục vụ **Platform Operator**. Nó KHÔNG nuốt cổng `/school` của hiệu trưởng — nó cho platform operator một **cửa step-in có kiểm soát** vào tenant khi cần unblock, mọi bước để lại audit. Đây là điểm phân biệt sống-còn với việc "admin thấy hết trẻ" (vi phạm D48).

---

## 3. MISSION CONTROL ARCHITECTURE

Nguyên lý gốc (mượn Dế Mèn Workshop, **không copy UI**): operator mở Admin **không nghĩ "tôi cần sửa entity nào"** mà nghĩ **"tôi cần xử lý việc gì"**. Kiến trúc vì thế tổ chức theo **việc**, không theo **bảng**.

```
MISSION CONTROL  (/admin — Platform Operator cockpit)
│
├── TODAY                     ⟵ reuse: Mission Control dashboard + pilot-funnel
│   Health · Action Center (nối workflow) · Pilot Wave status · Sự cố
│
├── OPERATIONS                ⟵ NEW workspace layer (bắc cầu engine /school + admin RPC)
│   ├─ School     (onboard_school ✓ · quản-lý-sau-tạo NEW view)
│   ├─ Teacher    (provision ✓ · 🔴 role activation NEW RPC · assign class ✓)
│   ├─ Child      (create_child_and_enroll ✓ · transfer ✓ · journey read)
│   ├─ Parent     (invite ✓ · provision_parent_and_link ✓ · link ≤2 ✓)
│   └─ Class      (classes ✓ · assign_class_distribution ✓ · enroll ✓)
│
├── CONTENT                   ⟵ reuse: Kho Học Liệu + curriculum + sounds
│   Curriculum · Learning Material · Media
│
├── TRUST & SAFETY            ⟵ reuse: request_sensitive_access + consents + audit-log
│   Consent (read) · Privacy request · Audit Intelligence · Sensitive-access (audited)
│
└── SYSTEM                    ⟵ reuse: policies + system-map + reference + settings + permissions
    Policy · Config · Architecture (System Map) · Permissions
```

**Nguyên tắc lắp ghép:**
1. **TODAY / CONTENT / TRUST / SYSTEM = phần lớn ĐÃ CÓ** → tổ chức lại + đặt dưới một mái nav, không xây lại.
2. **OPERATIONS = lớp workspace MỚI** — nhưng **99% là UI trên engine cũ**. Chỉ **1 mảnh engine mới**: `admin_set_profile_role`.
3. **Command Search** cắt ngang toàn bộ (§5) — cửa vào mọi workspace từ 1 ô tìm.

---

## 4. NAVIGATION PROPOSAL (Task 3 — IA, không phải UI)

**Cây điều hướng + logic gom nhóm + user intent + chủ sở hữu workflow:**

| Nhóm nav | Mục con | Grouping logic (vì sao ở cùng chỗ) | User intent | Workflow ownership |
|---|---|---|---|---|
| **TODAY** | Health · Action Center · Pilot Status | "Cái gì cần tôi *bây giờ*" — mọi thứ time-sensitive | Mở app là thấy việc | Platform Operator |
| **OPERATIONS** | School · Teacher · Child · Parent · Class | Gom theo **actor của việc vận hành**, không theo bảng DB | "Xử lý một người/lớp cụ thể" | Platform + step-in vào School Operator |
| **CONTENT** | Curriculum · Material · Media | Nội dung ít đụng people-ops; nhịp thay đổi khác | "Quản trị bài & tài sản học" | Content Operator |
| **TRUST & SAFETY** | Consent · Privacy · Audit · Sensitive-access | Gom theo **ranh giới quyền riêng tư** — nơi D48/consent sống | "Giải trình & bảo vệ trẻ" | Platform Operator (audited) |
| **SYSTEM** | Policy · Config · System Map · Permissions · Reference | "Hiến pháp" — hiếm khi chạm, thay đổi hệ trọng | "Cấu hình nền tảng" | super_admin |

**Ba quyết định IA quan trọng:**
- **OPERATIONS gom theo actor, không theo table.** Operator tìm "cô Ngân" rồi làm mọi thứ về cô ở **một chỗ** — không nhảy giữa `profiles`, `session_teachers`, `class_distributions`.
- **TRUST & SAFETY tách riêng khỏi OPERATIONS.** Việc "tạo bé" (ops) khác bản chất với "đọc PII bé / giải trình consent" (trust, phải audit). Tách để mọi thao tác nhạy cảm đi qua một cổng có kiểm soát → không rò rỉ D48.
- **Thứ tự nav = tần suất giảm dần:** TODAY (mỗi phiên) → OPERATIONS (hằng ngày pilot) → CONTENT/TRUST (định kỳ) → SYSTEM (hiếm). Đây là "business operation first" ở tầng IA.

---

## 5. COMMAND SEARCH MODEL (Task 4)

**Không xây từ 0 — nâng `/admin/lookup` (Smart Lookup, đã live) thành command surface.** Khác biệt: Lookup hiện *trả record*; Command Search *trả record + việc làm được ngay*.

**Một ô tìm. Gõ tên/mã → ra thực thể + quick actions gated.**

### Search entities & nguồn
| Entity | Nguồn (đã có) | Khóa tìm |
|---|---|---|
| Person (GV/PH/admin) | `profiles` | full_name · email · role |
| Child | `children` | full_name · nickname (⚠️ gated D48) |
| School | `schools` | name · code (VNDM-DN) |
| Class | `classes` / `class_distributions` | name · program |
| Media | `media_assets` (metadata.title) | title |
| Workflow | `admin_modules` (registry) | keyword ("mời phụ huynh") |

### Ranking
1. **Exact code/email** (VNDM-DN, ngan.pepu@gmail.com) — cao nhất.
2. **Người & trẻ đang trong pilot active** (VNDM cohort) trước — vì operator đang làm pilot.
3. **Actor gần đây trong audit** (đã đụng tay gần đây) boost nhẹ.
4. Prefix-match tên > substring.
5. **Workflow entity** luôn hiện cuối nếu keyword khớp (không lẫn với người).

### Quick actions (ví dụ brief)
```
"Tuệ Linh"  → Child: Trần Tuệ Linh (Happy) · VNDM · Ballet Hạt Nắng
   [Xem hồ sơ] [Đổi/Gán lớp] [Link phụ huynh] [Xem hành trình*] [Chuyển trường]
      *hành trình = shape (có/không entry); nội dung PII gated

"Cô Ngân"   → Person: Tạ Thị Thuý Ngân · role=secondary_parent ⚠️ · school=NULL
   [🔴 Kích hoạt vai Giáo viên] [Gán trường] [Gán lớp] [Gỡ link rác] [Xem audit]
```
> Quick action **map thẳng vào workflow §7** — search là cửa nhanh nhất tới bàn vận hành. Cảnh báo trạng-thái-sai (⚠️ role mismatch, school=NULL, link rác) hiện ngay trên kết quả → operator thấy vấn đề trước khi bấm.

### Permission filtering (RÀNG BUỘC BẤT BIẾN)
- **Gate `is_admin()`** cho toàn bộ search — non-admin không có surface này.
- **D48 tường minh:** kết quả Child trả **shape** (tên hiển thị tối thiểu để định danh thao tác, lớp, trạng thái) — **KHÔNG** dob/PII/nội-dung-journey. Muốn xem PII → nút [Xem hồ sơ định danh] gọi `request_sensitive_access` → **ghi audit TRƯỚC khi trả** (đã có).
- **Không existence-leak:** một operator content_admin không thấy được child ngoài phạm vi qua search (generic empty, không "tồn tại nhưng bị chặn").
- **Mọi quick-action side-effect** đi qua workflow có audit (§7) — search không phải cửa hậu bỏ qua audit.

---

## 6. ENTITY WORKSPACE MODEL (Task 5)

**Cockpit vận hành cho từng thực thể.** Mỗi workspace trả lời đúng một câu: **"Operator làm được gì ở đây?"** — và phơi bày trạng-thái-sai để sửa.

### 6.1 Child Workspace (ví dụ chuẩn — nhạy cảm nhất, phải đúng D48)

| Panel | Nội dung | Ranh giới |
|---|---|---|
| **Identity** | Tên hiển thị · nickname · trạng thái · mã bé | dob/PII **ẩn**; nút [Xem định danh] → `request_sensitive_access` (audited) |
| **School** | Trường hiện tại + lịch sử chuyển | link → School workspace |
| **Class** | Lớp/môn đang học · GV chính mỗi môn | [Gán lớp] [Đổi lớp] → `assign`/enroll |
| **Teacher** | GV chính theo môn (từ distribution) | read; đổi qua Class |
| **Parents** | ≤2 PH đã link (tên+email qua `get_child_parents`) · slot trống | [Mời PH] [Link PH] [Gỡ link] — max-2 enforced |
| **Journey** | **Shape**: có/không entry, số buổi, môn — KHÔNG nội dung | Nội dung journey thuộc TRẺ+PH, **admin không đọc** (LINH HỒN) |
| **Permissions** | Consent trạng thái (media/share) — **đọc** | Admin **không sửa hộ PH** (Fork 1A: chỉ PH ghi consent) |
| **Activity** | Deep-link audit theo child_id | → Audit Intelligence |
| **Actions** | Gán lớp · Link PH · Chuyển trường · Xem định danh (audited) | Mỗi cái = workflow §7 |

> **Điểm sống-còn:** Child Workspace **không hiển thị con như data object**. Nó cho operator *đủ để vận hành* (lớp, PH, chuyển trường) mà **không mở nhật ký nghệ thuật của bé** — đúng nguyên tắc "nhật ký thuộc về trẻ + gia đình, không thuộc trường/nền tảng". Muốn chạm PII → một cửa duy nhất, có audit.

### 6.2 Teacher Workspace (bàn unblock Wave 0)
Identity + **role hiện tại (cảnh báo nếu mismatch)** · School · Classes phụ trách · Seat/entitlement · Account state (invited/active) · **Actions: 🔴 Kích hoạt vai GV · Gán trường · Gán lớp · Gỡ link rác · Xem audit**. Đây là màn giải quyết đúng blocker B1 của Wave 0.

### 6.3 School Workspace
KPI tenant (đọc `get_school_overview`) · Classes · Teachers · Children count · Entitlements/seats · Storage · **Actions: Onboard-sau (sửa sub) · Step-in provision (audited) · Xem audit tenant**. Platform operator "step-in" — KHÔNG thay cổng `/school` của master.

### 6.4 Parent Workspace
Identity + account state · Children đã link (≤2) · Invitation status · **Actions: Mời lại · Link thêm bé · Gỡ link**. Consent **chỉ đọc** (PH tự cầm quyền).

---

## 7. WORKFLOW MAP — FIRST 10 PILOT WORKFLOWS (Task 6)

| # | Workflow | Actor | Trigger | Steps | Permission | Audit event |
|---|---|---|---|---|---|---|
| 1 | **Create school** | Platform Op | Mở tenant mới | Form → `onboard_school` (school+sub+entitlement+master, total từ pricing_config) | super/operation/sales_admin | `school_onboarded` ✓ (đã có) |
| 2 | **Add teacher** | Platform/School Op | Cần GV cho lớp | Tạo profile GV (user_id NULL) + gán school → invite | is_admin \| is_school_admin same-school | `teacher_provisioned` *(thêm)* |
| 3 | **🔴 Activate teacher account** | Platform Op | Role sai / kích hoạt | **`admin_set_profile_role`** (secdef, gate is_admin, guard-aware) role→lead_teacher + school_id + revoke link rác | **is_admin ONLY** | `profile_role_changed` *(NEW, bắt buộc)* |
| 4 | **Create child** | School Op / Platform step-in | Ghi danh bé | `create_child_and_enroll` (child + enrollment atomic) | is_school_admin same-school \| admin step-in | `child_created` *(thêm)* |
| 5 | **Link parent** | School/Platform Op | Gắn PH vào bé | `invite_parent` (Edge) → PH tự đặt mật khẩu → `link_parent_user` (≤2) + consent default-on | same-school (đi vòng child_parents) | `parent_invited` / `parent_linked` |
| 6 | **Assign child → class** | School Op | Xếp lớp/môn | `assign_class_distribution` (license-gate `has_subject_entitlement` + chống trùng) + enroll | is_school_admin same-school | *(thêm)* `distribution_assigned` |
| 7 | **Change teacher** | School Op | Đổi GV chính môn | Update `class_distributions.lead_teacher_id` (session responsibility = D324) | is_school_admin same-school | *(thêm)* `lead_teacher_changed` |
| 8 | **Move child → school** | Platform Op | Chuyển trường | `child_transfers` (giữ nguyên journey — treo vào bé, D40/D41) | is_admin | `child_transferred` *(thêm)* |
| 9 | **Resolve permission issue** | Platform Op | Role/scope sai (Wave 0) | Command Search → Teacher Workspace → #3 + gỡ link rác + xác minh | **is_admin ONLY** | `profile_role_changed` + `link_revoked` |
| 10 | **Review audit history** | Platform Op | Giải trình | `/admin/audit-log` deep-link actor/child (Investigation → Raw) | is_admin (carve-out D57) | *(đọc — không phát event)* |

**Ghi chú engine (trung thực):**
- ✅ **Đã có RPC:** #1, #4, #5, #6, #7 (partial), #10. Chỉ cần UI workspace bọc lại.
- 🔴 **Thiếu engine — P0 duy nhất chặn pilot:** #3/#9 cần **RPC `admin_set_profile_role`** (đổi role/school có audit, admin-context, đi qua guard đúng cách như `link_master_user` dùng `session_replication_role=replica`). Đây là dây điện đứt của Wave 0.
- 🟡 **Audit event thiếu** ở #2/#4/#6/#7/#8: nhiều RPC self-manage hiện **KHÔNG ghi audit** (D91 ghi rõ "KHÔNG audit"). Với pilot thật cần **thêm audit-write** vào các RPC ghi (nguyên tắc: Auditability mandatory). Không đổi model — chỉ thêm `write_audit_log` trong thân RPC.

---

## 8. P0 IMPLEMENTATION ROADMAP (Task 7 — Priority)

### P0 — PILOT BLOCKING (làm trước, không có = pilot không chạy)

| Hạng mục | Vì sao P0 | Loại |
|---|---|---|
| **P0-1 · RPC `admin_set_profile_role`** (đổi role+school có audit, gate is_admin, guard-aware) | Wave 0 chết ở đây. Không có = mọi GV kẹt role vẫn phải SQL (bị guard chặn) = pilot không nổ máy | 🔴 Engine (1 migration, 3-block D92) |
| **P0-2 · Teacher Workspace** (màn kích hoạt vai + gán trường/lớp + gỡ link rác) | Bàn để chạy P0-1; giải quyết trực tiếp B1 Wave 0 | UI trên engine |
| **P0-3 · Parent provisioning surface** (mời + link ≤2 trong workspace) | B2 Wave 0 (Mẹ Trang Đoàn chưa có account) | UI trên `invite_parent`/`link_parent_user` (đã có) |
| **P0-4 · Command Search nâng cấp** (search → quick action + cảnh báo trạng-thái-sai) | Cửa nhanh nhất tới 3 workspace trên; nâng `/admin/lookup` sẵn có | UI trên Lookup + D48 gate |
| **P0-5 · Audit-write vào RPC ghi** (#2/#4/#6/#7/#8) | "Auditability mandatory" cho pilot thật; hiện nhiều RPC không để vết | 🟡 Engine (thêm `write_audit_log` trong thân, không đổi model) |

**Vì sao chỉ chừng này là P0:** Pilot Wave 0 cần đúng **một chuỗi**: tìm cô → sửa role → gán lớp → tạo bé → mời+link PH → (GV+PH login thật). P0-1..P0-4 phủ trọn chuỗi; P0-5 làm nó giải-trình-được. Mọi thứ khác **không chặn** buổi ballet đầu tiên.

### P1 — DAILY OPERATION (sau khi pilot nổ máy, để vận hành êm)
- School Workspace (step-in provision + KPI tenant) · Child Workspace đầy đủ · Class change workflow (#7 UI) · Child transfer workflow (#8 UI) · TODAY action-center **nối** tới workflow (bấm cảnh báo → nhảy vào bàn xử lý) · Pilot Status card trong TODAY.
- **Vì sao P1:** cần cho vận hành nhiều-trường bền vững, nhưng buổi pilot đầu chạy được không cần chúng.

### P2 — SCALE (khi >5 trường / commercial)
- Consent/Trust workspace gom theo gia đình · Permissions màn (permission scoped) · Bulk cohort import (thay 1-1) · Observability/alerting (từ V127-M1 audit: Supabase chỉ log 24h ephemeral, 0 alerting) · Reference-center hoàn thiện (building) · System Map data-driven.
- **Vì sao P2:** chỉ đau ở quy mô; pilot 1 trường không chạm tới.

---

## RÀNG BUỘC BẤT BIẾN (self-check — mọi đề xuất trên đã tuân thủ)
- ✅ **Không phá RLS / không bypass permission** — mọi workspace gọi RPC gated đã có; search gate is_admin + D48.
- ✅ **Không CRUD admin không audit** — P0-5 bắt buộc audit-write; #3 phát `profile_role_changed`.
- ✅ **Không đổi database model khi chưa chứng minh cần** — chỉ +1 RPC (role) + audit-write; 0 bảng mới, 0 đổi schema.
- ✅ **Privacy boundary immutable / Parent-Child security immutable** — Child Workspace không mở journey; PII chỉ qua `request_sensitive_access` audited; consent chỉ PH ghi.
- ✅ **Memory > Metric · không biến trẻ thành data object** — workspace cho operator *vận hành* bé, không *đọc* nhật ký nghệ thuật của bé.

---

## NEXT ACTION (đề xuất — anh chọn 1)
- **★ A · Khởi động P0-1** — em soạn spec RPC `admin_set_profile_role` (signature, gate, guard-path, audit event, 3-block D92) để anh + ChatGPT review trước khi có Owner Gate cho migration.
- **B · Khởi động P0-2/P0-4** — em audit file route `/admin/lookup` + `admin.tsx` shell thật (Lovable `read_file`) rồi ra paste-spec Teacher Workspace + Command Search (UI-only, 0 engine).
- **C · Chốt IA trước** — anh + ChatGPT phản hồi cây nav §4 / workspace §6, em chỉnh design rồi mới xuống P0.

*Design only — chưa canonicalize. Giữ D344 / v1.32 / V126-M1. Không code, không migration trong phiên này.*
