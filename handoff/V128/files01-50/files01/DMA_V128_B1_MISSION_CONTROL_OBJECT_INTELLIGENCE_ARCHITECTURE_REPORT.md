# V128-B1 — MISSION CONTROL OBJECT INTELLIGENCE ARCHITECTURE REPORT

> **Loại:** DESIGN ONLY. Không code / JSX / SQL / migration / RPC / schema change / permission change.
> **Phiên:** V128-B1 · thiết kế nối tiếp V128-B0.1 (CLOSED).
> **Grounding (LIVE, verified trong phiên — KHÔNG từ memory):**
> - Frontend HEAD `be04f4b` (list_edits xác nhận; lineage `8c0ca0a0` V127-M4.2.5 → `a117bfd5` Mission Control OS skeleton → `8d70281d` B0.1 contract → `be04f4b` tooling recovery).
> - DB baseline **FROZEN**: **89 tables · 233 functions · 222 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron · migration tail `20260810074214`** — khớp chính xác endpoint D347 / SYSTEM_MAP v1.35. **V128-B0/B0.1 = 0 DB delta** (đúng như B0 tuyên bố).
> - Canonical files (RULES `D347`, SYSTEM_MAP `v1.35`, HANDOFF `V127-M4.2.5`) **chưa chứa khối V128** → xem §9 (governance note).

---

## 1. EXECUTIVE VERDICT

**Mission Control có đủ nền để scale SaaS — nhưng nền đó là "renderer sẵn sàng + backend đã biết nói object", KHÔNG phải "hệ đã object-centric".**

Ba trụ đã đứng, verified live:

1. **Renderer domain-agnostic** (B0 đã chứng minh): `ObjectWorkspaceModel` 5 dải (Identity/Context/Health/Actions/History) render bất kỳ object nào qua route `admin.object.$type.$id`, `type` là open string, fixture-only, 0 PII.
2. **Backend đã có projection dạng object-workspace**: `admin_lookup_child / admin_lookup_user / admin_lookup_media / admin_lookup_capsule`, `get_person_workspace`, `get_school_people`. Đây là bằng chứng backend đã suy nghĩ theo "workspace của một object", không chỉ CRUD hàng.
3. **Backend đã có resolver**: `admin_lookup_search(q)` — command input → typed candidates.

**Nhưng nền thiếu 2 thứ để thành OS:**

- **Coverage**: resolver chỉ biết 4 loại (person / child / media / capsule). Nó **mù** với chính các object admin vận hành ở scale: **School, Class, Subscription, Support Case**. Đây là nghịch lý — object trung tâm của product thesis lại chưa resolve được.
- **Contract thống nhất**: mỗi projection có shape riêng (ad-hoc jsonb), không map về một Object Contract chung → renderer B0 hiện chỉ ăn fixture, chưa ăn được backend thật.

**Kết luận verdict:** `FOUNDATION SUFFICIENT — REQUIRES CONTRACT UNIFICATION + OBJECT COVERAGE, NOT A REBUILD.` B1 phải thiết kế **cái seam** (contract v1 + object registry + capability model) chứ không xây lại renderer hay resolver. Rủi ro lớn nhất không phải kỹ thuật — mà là **để module-thinking rò rỉ ngược vào object layer** (mỗi object một RPC bespoke, mỗi type một privacy rule tự chế) khi scale.

---

## 2. CURRENT ADMIN REALITY AUDIT

### 2.1 Admin hiện quản lý bằng module nào (verified route + table)

Admin hôm nay là **module-centric thật**. Backbone = registry `admin_modules` + `admin_module_groups` + `admin_module_links` + `admin_playbooks` / `admin_playbook_steps`, mặt tiền là `admin.modules.tsx` (module grid) + ~18 route mục đích-đơn:

| Nhóm | Route hiện có |
|---|---|
| Shell / home | `admin.tsx`, `admin.index.tsx` |
| Module grid (database-thinking) | `admin.modules.tsx` |
| Object-shaped (đã có mầm) | `admin.lookup.tsx` (resolver), `admin.object.$type.$id.tsx` (B0 renderer, fixture), `admin.mission-control.tsx` + `.index.tsx` (B0 shell) |
| Content | `admin.curriculum-admin.tsx`, `admin.curriculum-library.tsx`, `admin.kid-sound-game.tsx`, `admin.notification-sounds.tsx` |
| Ops / governance | `admin.pilot-funnel.tsx`, `admin.school-onboarding.tsx`, `admin.policies.tsx`, `admin.reference.tsx`, `admin.system-map.tsx`, `admin.settings.tsx` |
| Audit / privacy | `admin.audit-log.tsx`, `admin.sensitive-access.tsx`, `admin.notifications.tsx` |

**Đặc điểm thất bại:** admin phải biết TRƯỚC một năng lực nằm ở module nào rồi mới hành động được. Đây đúng là database-thinking mà thesis muốn loại.

### 2.2 Module thiếu khả năng vận hành / nghiệp vụ có trong DB nhưng KHÔNG có control surface

Verified: các bảng sau tồn tại nhưng **không có object workspace** để admin vận hành:

- **`school_subscriptions` + `school_subject_entitlements`** — Subscription/entitlement là commercial control surface, **hiện không có workspace admin**. Ở 100 trường đây là chỗ tiền chảy — mù ở đây là mù doanh thu.
- **`support_requests`** — Support Case object tồn tại, **không có bề mặt triage**.
- **`classes` + `class_distributions`** — Class chỉ với tới được *gián tiếp* qua person lookup; **không có Class workspace** (lead assignment, enrollment, session health).
- **`child_transfers` + `child_duplicates`** — nghiệp vụ lifecycle (chuyển trường, gộp trùng) tồn tại, không có surface.
- **`privacy_requests` + `consents`** — hàng đợi compliance, không có queue surface.
- **`product_events`** — sự kiện sản phẩm có, chưa được chiếu thành health/attention.

### 2.3 Điểm nghẽn scale 100 schools / 10k children (verified từ body resolver)

`admin_lookup_search` đọc live cho thấy các nghẽn cụ thể:

1. **Search = `ILIKE '%q%'` full-scan** trên `profiles` (email/full_name) và `children` (full_name/nickname). Ổn ở pilot; ở 10k children đây là seq-scan mỗi phím → cần FTS/trigram index (chưa verify có index — B2 pre-flight).
2. **Media & Capsule chỉ tìm bằng UUID** — không tìm được theo nội dung. Ở scale, support không thể "tìm media của bé X" — chỉ dán được UUID.
3. **`LIMIT 10` cứng, không ranking, không pagination** — không có relevance, không cuộn tiếp.
4. **Không có health aggregation xuyên object** — "trường nào / thuê bao nào / bé nào cần chú ý" phải mở từng cái. Attention không scale bằng mắt.
5. **Resolver gate `is_admin()` platform-only** — chưa có đường cho school-scoped operator; và khi mở ra sẽ là rủi ro cross-tenant (xem §7).

---

## 3. OBJECT UNIVERSE PROPOSAL

Phân loại theo mức admin **trực tiếp vận hành**, không theo số bảng. (Object ≠ table: một object gộp nhiều bảng.)

| Object | Class | Priority | Nguồn bảng (verified) | Lý do |
|---|---|---|---|---|
| **School** | Core | **P0** | `schools` (+ `school_settings`) | Tenant root; mọi thứ treo vào; chưa có workspace |
| **Person** | Core | **P0** | `profiles` (+ `child_parents`, `class_distributions`) | Identity teacher/parent/admin; **đã có** `admin_lookup_user` + `get_person_workspace` |
| **Child** | Core | **P0** | `children` (+ `enrollments`, `child_parents`) | Trung tâm LINH HỒN; **đã có** `admin_lookup_child`; access = reason-logged (D345.2) |
| **Class** | Core | **P1** | `classes` + `class_distributions` (+ `enrollments`, `lesson_sessions`) | Đơn vị vận hành + authority phân công; **chưa có** workspace |
| **Subscription** | Core | **P1** | `school_subscriptions` + `school_subject_entitlements` | Commercial control surface; **chưa có** — mù doanh thu |
| **Support Case** | Core | **P1** | `support_requests` | Ops triage; **chưa có** |
| **Media Asset** | Supporting | **P2** | `media_assets` + `media_variants` | Tới từ child/session; **đã có** `admin_lookup_media` (UUID-only); access Edge-signed + logged |
| **Session** | Supporting | **P2** | `lesson_sessions` (+ `session_reports/marks/media/appreciations/teachers`) | Đơn vị buổi học; reachable từ Class/Child |
| **Discovery Capsule** | Supporting | **P2** | `discovery_capsules` (+ `discovery_capsule_items`) | Meaning artifact của trẻ; **đã có** `admin_lookup_capsule` |
| **Program / Curriculum** | Supporting | **P2** | `programs`, `lessons`, `lesson_versions`, `program_distributions` | Content authoring; đã có route riêng |
| **Privacy Request** | Supporting | **P2** | `privacy_requests` + `consents` | Compliance queue |
| **Enrollment / Distribution** | Supporting | **P3** | `enrollments`, `class_distributions`, `program_distribution_items` | Chủ yếu là *edge* — hiển thị, ít navigate |
| **Family Space** | Future | — | `family_spaces` + memory network | Parent-owned; admin **KHÔNG** được chiếu nội dung (xem Forbidden) |
| **Kid Device / Session** | Future | — | `kid_*` | `/kid` V2 namespace PIN-based — reserved |
| **Billing Invoice / Payment** | Future | — | *chưa có bảng* | Khi thương mại hoá sâu |
| **Pilot Lead** | Future | — | `product_events` (derived) | Funnel object suy ra từ event |

### Forbidden Objects (KHÔNG BAO GIỜ là Mission Control object — ranh giới LINH HỒN)

| "Object" | Vì sao cấm |
|---|---|
| **Child Journey / Journal / Skills / Badges** (`child_journey`, `child_skills`, `child_badges`) | Thuộc TRẺ + gia đình. Admin thấy **zero** nghệ thuật/PII của trẻ (nguyên tắc LINH HỒN; v5 chứng minh admin thấy 0 journey/skills/badges). |
| **Parent Memory / Family memory card content** (`parent_memories`, `memory_cards`, `card_media`, `memory_messages`) | Family-owned. Không phải object của platform. |
| **Raw media bytes / signed URL at rest** | Truy cập media = Edge ký ngắn hạn + log, KHÔNG BAO GIỜ là object browsable. Media Asset workspace chỉ chiếu *metadata + trạng thái*, không phát nội dung. |

**Nguyên tắc phân loại:** một type chỉ lên **Core** nếu admin *khởi phát hành động* trên nó ở scale. Object mà admin chỉ *đi ngang qua* (edge) là **Supporting** và render như Context, không cần resolver riêng.

---

## 4. OBJECT CONTRACT v1

**Nguyên tắc nền:** MỞ RỘNG contract B0 đã đóng băng (`ObjectWorkspaceModel`), KHÔNG thay thế. Renderer B0 đã ship — đổi shape = phá B0.

### 4.1 Identity (giữ nguyên B0 + 1 ràng buộc registry)

B0 hiện: `{ type: string; id: string; title: string; subtitle?: string|null }`.

- Renderer giữ `type` open-string (không phá B0), **nhưng registry (§6) chốt một tập `ObjectType` đóng** (`school | person | child | class | subscription | support_case | media | session | capsule | ...`). Open ở renderer, closed ở registry.
- Thêm ở tầng contract v1 (không phá field cũ): `status` chuẩn hoá (map qua `stateLabel` đã có: active/pending/archived/...) để Identity band hiển thị pill trạng thái nhất quán.

### 4.2 Context (giữ B0 — đã mã hoá đúng navigation vs informational)

B0 hiện: `{ kind, label, href?, meta? }`. **Điểm hay: `href` present = navigable; absent = informational.** Contract đã tự phân biệt.

Bổ sung v1:
- `boundary?: 'open' | 'permission' | 'forbidden'` trên mỗi context edge. Ví dụ School→Children là edge tồn tại nhưng **permission-gated** (mở phải qua reason-log); School→Subscription là `open`; Child→Journey là `forbidden` (không render href, chỉ có thể là informational count hoặc bị loại hẳn).
- Quy ước: **navigation edge phải trỏ tới một ObjectType hợp lệ** (href = `/admin/object/<type>/<id>`), để renderer và resolver dùng chung không gian địa chỉ.

### 4.3 Health (MỞ RỘNG — B0 thiếu severity + timestamp)

B0 hiện: `{ key, label, status: ok|watch|risk|unknown, detail? }`. B1 yêu cầu `{ status, severity, reason, timestamp }`.

**Đề xuất `HealthSignal v2` (additive, backward-compat):**

```
{
  key: string
  label: string
  status: "ok" | "watch" | "risk" | "unknown"   // giữ B0
  severity?: "info" | "low" | "medium" | "high"  // MỚI — cho phép sort/triage
  reason?: string | null                          // MỚI — thay/bổ sung 'detail'
  at?: string | null                              // MỚI — timestamp nguồn tín hiệu
}
```

- `detail` (B0) map thẳng vào `reason` — không cần đổi renderer band, chỉ thêm 2 field optional.
- **Health = attention, KHÔNG phải analytics.** Health chỉ trả lời đúng một câu: *"admin có cần chú ý object này không?"*. Ví dụ School: subscription hết hạn (`risk/high`), lớp không có lead (`watch/medium`), 0 session 30 ngày (`watch/low`). KHÔNG đưa biểu đồ, KHÔNG KPI, KHÔNG chấm điểm.
- Nguồn health: suy ra server-side từ trạng thái quan hệ (subscription state, distribution lead null, session recency) + `product_events` — **không dựng bảng analytics mới**.

### 4.4 Actions (giữ descriptor-only B0 + bind capability)

B0 hiện: `{ key, label, intent, enabled, disabledReason? }` — **descriptor thuần, KHÔNG handler**. Đây đã đúng.

Bổ sung v1 (metadata, vẫn không handler ở client):
- `required_capability: string` — permission-string mà server đã dùng để tính `enabled` (audit/tra cứu; client KHÔNG tự tính).
- `scope: 'platform' | 'school' | 'assignment'` — mức phạm vi đã kiểm.
- **Authority = server.** RPC workspace tính `enabled` + `disabledReason` (mirror D290/D293: UI đóng đúng cửa backend đóng; UI phản chiếu MỌI nhánh authz, không chỉ nhánh sở hữu). Client **không bao giờ** suy `enabled` từ `role`.
- Verb chuẩn (map §5): `can_view · can_edit · can_assign · can_archive · can_export`.

### 4.5 History (giữ B0 — nguồn = audit đã có)

B0 hiện: `{ id, at, actor?, summary, kind? }` → trả lời **What (summary/kind) · Who (actor) · When (at)**.

- **Why** = `reason` — đã có nguồn: `admin_workspace_access_log.reason` (D345.2) + `audit_logs`. Map vào `summary` hoặc thêm `reason?` optional.
- Nguồn timeline: **`admin_audit_investigation(...)`** (đã tồn tại, filter đủ actor/category/action/entity/child/time/paging) + `admin_audit_group_events` để gộp burst. History band **không cần backend mới** — chỉ cần adapter map ra `HistoryEntry[]`.

---

## 5. CAPABILITY ARCHITECTURE

**Công thức trung tâm:** `capability = (permission-class) × (object-scope-predicate)`. Không dùng `role === admin`, không hardcode.

### 5.1 Hai thành phần (đều đã có primitive live)

- **Permission-class** — từ `has_permission(perm)` đọc `profiles.permissions[]` (verified body: `perm = any(permissions)` cho `auth.uid()`). Đây là mô hình **permission cộng thêm** (Meta principle #4).
- **Scope-predicate** — từ object context, dùng predicate đã có:
  - `is_admin()` → platform scope.
  - `is_school_admin()` / profile-in-school → tenant scope.
  - `is_teacher_in_school()` / `is_session_responsible()` → assignment scope (D346/D324).

> ⚠️ **Nuance phải thiết kế đúng:** `has_permission` hiện là **membership toàn cục** (chỉ hỏi "có perm này trong mảng không"), KHÔNG mang scope. Nên **một capability có scope** (vd `can_edit` *trường này*) = `has_permission('school.edit')` **AND** `object-predicate(school_id)`. Permission trả lời *"được làm loại việc này"*; predicate trả lời *"trên object/scope nào"*. Thiết kế phải luôn nhân đôi hai vế — không được để permission toàn cục tự nó mở cửa một object cụ thể.

### 5.2 Ma trận verb → (permission, predicate) — mẫu cho Core objects

| Verb | Ý nghĩa | Permission (ví dụ) | Predicate scope |
|---|---|---|---|
| `can_view` | Mở workspace | `<obj>.view` | platform hoặc profile-in-school |
| `can_edit` | Sửa thuộc tính | `<obj>.edit` | + `is_school_admin`/is_admin |
| `can_assign` | Gán quan hệ (lead, enroll) | `<obj>.assign` | + assignment-aware RPC (D346.3) |
| `can_archive` | Vòng đời | `<obj>.archive` | + role-integrity guard (D345.3) |
| `can_export` | Xuất dữ liệu | `<obj>.export` | + privacy gate (child = reason-log) |

### 5.3 Nguyên tắc thực thi

- **Discovery ≠ execution.** Resolver có thể *liệt kê* object (discovery); mỗi action **tái kiểm** capability tại thời điểm chạy. Mở workspace của `child` = reason bắt buộc + log (D345.2).
- **Action route qua hardened RPC, KHÔNG ghi thẳng bảng** (D346.3). Ví dụ `can_assign` teacher đi qua `admin_activate_teacher` (đã có role-integrity guard: `cannot_downgrade_admin`, `has_active_parent_link`).
- **Client mù enablement logic.** `ObjectAction.enabled` là dữ liệu server trả; client chỉ render + disable + hiện `disabledReason`.

---

## 6. COMMAND CENTER FLOW

### 6.1 Conceptual pipeline

```
Command Input (free text | uuid)
        ↓
Resolver  →  resolve_object_candidates(q, scope)      [mở rộng admin_lookup_search]
        ↓
Object Candidates : { type, id, title, subtitle, status }[]   ← identity-only, rankable, paginated
        ↓  (chọn 1)
Object Workspace  →  get_object_workspace(type, id)   [dispatch theo type → per-type projector]
        ↓
ObjectWorkspaceModel { identity, contexts, health, actions, history }   → renderer B0
```

### 6.2 Quy tắc contract

- **Resolver trả business object candidate, KHÔNG trả database rows.** Candidate = `{type, id, title, subtitle, status}` — rẻ, rank được, phân trang được. **Không** kèm context/health/actions ở bước resolve (lazy, tránh N+1).
- **Workspace hydrate đầy 5 dải khi chọn** (một RPC per object, dispatch theo `type`).
- **Per-type projector.** Registry map `ObjectType → { resolver_fragment, projector_fn, capability_set, privacy_policy, forbidden_columns }`. Mỗi projector tự chịu authz + privacy của type đó. Thêm object mới = thêm entry registry + 1 projector, **không đụng renderer, không đụng command bar** (principle #7 registry-driven).
- **Một không gian địa chỉ.** Mọi navigable context/candidate trỏ `/admin/object/<type>/<id>` — thống nhất resolver ↔ renderer ↔ context edge.

### 6.3 Tái dùng cái đã có (không xây lại)

- `resolve_object_candidates` = **thin wrapper** gộp `admin_lookup_search` (person/child/media/capsule) + fragment MỚI cho school/class/subscription/support.
- `get_object_workspace` dispatch: `person → get_person_workspace` (đã có), `child → admin_lookup_child` (đã có, + reason-log), `media → admin_lookup_media`, `capsule → admin_lookup_capsule`; MỚI: `school/class/subscription/support_case` projector.

---

## 7. SECURITY BOUNDARY

> **Định đề bắt buộc:** `Object discovery KHÔNG đồng nghĩa Object access.`

### 7.1 Cross-school leakage (rủi ro CAO khi mở scale)

- `admin_lookup_search` hôm nay gate `is_admin()` **platform-only** → chưa rò. **Nhưng** khi (a) thêm School/Subscription vào resolver, và (b) cho **school-scoped operator** (`is_school_admin`) dùng Mission Control, resolver **BẮT BUỘC filter candidate theo school của caller**. School operator **không được** resolve object của trường khác.
- **STOP-condition:** không expose Mission Control cho non-platform operator TRƯỚC khi resolver có school-scoping. (Xem §9.)

### 7.2 Child privacy

- **Forbidden objects không bao giờ được project** (§3). Pattern = *privacy-by-source* (D347.3): projector **đơn giản không SELECT** cột journey/journal/skills/badges/memory. UI không thể rò cái không được chiếu.
- **Child object workspace = reason bắt buộc + log** (D345.2, `admin_workspace_access_log`).
- ⚠️ **Điểm cần Owner phán:** `admin_lookup_search` **hiện phát `children.full_name` + `nickname`** cho platform admin trong kết quả search (verified body). Đây là *discovery* (identity), KHÔNG kèm journey/media/skills (verified — search chỉ trả identity fields). Cần Owner ruling rõ: **giữ** (admin triage cần định danh bé) với điều kiện *mở workspace vẫn phải reason-log — vốn đã có*, HAY siết tiếp. Khuyến nghị: **giữ cho platform admin**, nhưng nếu school operator vào resolver thì child-name discovery phải scope theo trường + cân nhắc masking.

### 7.3 Privilege escalation

- Capability suy từ `permissions[]` **phải server-verify** — client không tự nâng quyền.
- Action lifecycle đi qua RPC đã hardened (vd `admin_activate_teacher`: `cannot_downgrade_admin`, `has_active_parent_link`, idempotent noop). Mission Control **route qua các RPC này**, không ghi thẳng bảng.

### 7.4 Search boundary

- `ILIKE '%q%'` full-scan = vector DoS + enumeration ở scale → cần FTS/trigram + paging aware. **Media/Capsule UUID-only là *tốt*** (chặn enumeration nội dung) — **giữ**, không mở tìm-theo-nội-dung cho hai type này.

---

## 8. MIGRATION STRATEGY — Module-centric → Object-centric

Phi phá huỷ, phân pha. Module grid **không gỡ** cho tới khi mọi năng lực có nhà object.

| Pha | Nội dung | Delta | Rollback |
|---|---|---|---|
| **B0** ✅ | Renderer + contract + fixtures + shell + route `admin.object.$type.$id` | FE-only, 0 DB | (đã đóng) |
| **B1** (report này) | Contract v1 + Object Registry + Capability model — **DESIGN ONLY** | 0 | — |
| **B2** (build kế) | Backend: `resolve_object_candidates` + `get_object_workspace` như **ADAPTER** over `admin_lookup_*` / `get_person_workspace` + projector MỚI (School/Class/Subscription/Support). Additive, secdef, D15/D231 harden, D289 reload. | DB additive | DROP adapter RPC |
| **B3** | FE: nối `admin.object.$type.$id` + command bar vào resolver thật. Module grid GIỮ làm fallback. | FE additive | FE revert |
| **B4** | Gấp từng module route thành object action/context. Retire `admin.modules` **chỉ khi** mọi năng lực đã có object home. Registry-driven. | FE trừ dần | Un-retire route |

**Nguyên tắc:** mỗi pha rollback-độc-lập; module grid là lưới an toàn tới tận B4; không big-bang.

---

## 9. B1 RECOMMENDATION

### Build next?
**CÓ — nhưng chỉ tầng design của B1 là "done" khi report này được duyệt.** Trước khi vào **B2 (backend adapter)**, cần Owner chốt 2 quyết định:
1. **Object coverage thứ tự nào trước?** Khuyến nghị ★ **School → Subscription → Support Case** (Person/Child/Media/Capsule đã resolve rồi; ba cái này là commercial + ops gap lớn nhất).
2. **Resolver school-scoping** phải thiết kế **TRƯỚC** khi bất kỳ non-platform operator chạm Mission Control (rủi ro cross-tenant).

### Need more audit?
**Một audit ngắn làm pre-flight B2** (không phải blocker B1):
- Verify chiến lược index search (có trigram/FTS trên `profiles`/`children` chưa?).
- Verify column-shape `school_subscriptions` + `school_subject_entitlements` + `support_requests` để thiết kế projector.
- Verify RLS không hở khi platform admin project cross-school qua projector mới.

### Blockers
- **Design:** không có hard blocker.
- **Build STOP-conditions (2):**
  1. `resolver school-scoping` PHẢI có trước khi mở cho school operator.
  2. `child-in-search policy` cần Owner ruling (giữ name-discovery cho platform admin + reason-log, hay siết) — §7.2.

### ⚠️ Governance note (bắt buộc surface)
Canonical files hiện **chưa chứa V128**: RULES dừng `D347`, SYSTEM_MAP `v1.35`, HANDOFF `V127-M4.2.5`. **B0 và B0.1 chưa được forensic-reconstruct vào canonical** (dù đã CLOSED tại HEAD `be04f4b`). Đây là **debt riêng, KHÔNG thuộc phạm vi report design này**. Đề xuất: một pha canonicalization B0/B0.1 (đọc 3 commit `a117bfd5`/`8d70281d`/`be04f4b` + `get_diff`, dựng D-rule + SYSTEM_MAP block + HANDOFF) **trước hoặc song song** với việc canonical hoá B1 design. Em không tự ghi canonical trong phiên design-only này (đúng governance "chỉ design").

---

### PHỤ LỤC — Evidence pins (verified this session, không từ memory)

- **FE lineage:** `8c0ca0a0` (V127-M4.2.5) → `a117bfd5` "Added Mission Control OS skeleton" → `8d70281d` "Applied V128-B0.1 contract" → **`be04f4b`** "V128-B0.1 tooling recovery: restore bun.lock canonical 2.8.5" (`developer_update`) = HEAD.
- **DB baseline (frozen):** 89 · 233 · 222 · 166 · 33 · 1 · tail `20260810074214` — khớp D347/v1.35, 0 delta từ V128.
- **B0 contract frozen:** `ObjectWorkspaceModel { identity, contexts, health, actions, history }`; `HealthSignal { key,label,status,detail }`; `ObjectAction { key,label,intent,enabled,disabledReason }` (descriptor-only, no handler); route `admin.object.$type.$id.tsx`; fixtures neutral 0-PII.
- **Resolver live:** `admin_lookup_search(text)` — gate `is_admin()`; resolves `profiles`(email/name/uuid) · `children`(name/nickname/uuid) · `media_assets`(uuid) · `discovery_capsules`(uuid); `LIMIT 10`, no ranking/paging.
- **Object-workspace projections live:** `admin_lookup_child/user/media/capsule`, `get_person_workspace(school,person)`, `get_school_people(school,query,limit)`.
- **Capability primitive live:** `has_permission(perm)` = `perm = any(profiles.permissions)` cho `auth.uid()` (STABLE secdef, search_path='').
- **Gates live:** `is_admin()` (platform, secdef) · `is_school_admin()` (INVOKER) · `is_teacher_in_school` · `is_session_responsible/teacher/lead` · `is_moment_teacher/parent` · `current_school_id`.
- **Audit/History source live:** `audit_logs` (table) · `admin_audit_investigation(...)` · `admin_audit_group_events(...)` · `admin_workspace_access_log(entity_type,entity_id,reason)` (D345.2 reason-mandatory).
- **Module backbone live:** `admin_modules` · `admin_module_groups` · `admin_module_links` · `admin_playbooks` · `admin.modules.tsx`.

**END V128-B1 REPORT — DESIGN ONLY, 0 CODE / 0 SQL / 0 MIGRATION.**
