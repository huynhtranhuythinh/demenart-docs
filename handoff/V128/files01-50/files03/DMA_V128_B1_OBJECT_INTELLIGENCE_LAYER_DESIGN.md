# V128-B1 — MISSION CONTROL OBJECT INTELLIGENCE LAYER — DESIGN REPORT

> **Loại:** DESIGN ONLY. Không code / SQL / migration / RPC / UI implementation / permission change.
> **Vai:** Claude = PM + Product/System Designer · ChatGPT = CTO/CPO reviewer.
> **Nối tiếp:** V128-M0 (D348) đã canonical hoá B0/B0.1 skeleton. Report này là **design pass implementation-ready** cho Object Intelligence Layer (mở rộng B1 verdict report trước bằng contract cụ thể).
> **Re-pin (LIVE, verified phiên này):** baseline FROZEN **89 tables · 233 functions · 222 SECURITY DEFINER · tail `20260810074214`**; HEAD `be04f4b`. 12 primitive reuse present: `admin_lookup_search`, `admin_lookup_{child,user,media,capsule}`, `get_person_workspace`, `get_school_people`, `has_permission`, `admin_audit_investigation`, `admin_workspace_access_log`, `is_admin`, `is_school_admin`.
> **Contract v1 (re-pin từ get_diff, canonical D348.2):** `ObjectWorkspaceModel { identity, contexts, health, actions, history }`.

---

## 1. CURRENT STATE

Ba tầng đã đứng, nhưng **rời rạc** — chưa hợp thành một layer:

**A. Renderer + Contract (B0/B0.1, shipped, fixture-only):**
`ObjectWorkspace` render 5 dải cố định (Identity·Context·Health·Actions·History), KHÔNG rẽ nhánh type. Route `admin.object.$type.$id`. Contract v1:
- `ObjectIdentity {type:string, id, title, subtitle?}`
- `ObjectContext {kind, label, href?, meta:{label,value}[]}` — href = navigation.
- `HealthSignal {key, label, status:ok|watch|risk|unknown, detail?}`
- `ObjectAction {key, label, intent:primary|default|danger, enabled, disabledReason?}` — descriptor thuần, KHÔNG handler.
- `HistoryEntry {id, at, actor?, summary, kind?}`

**B. Backend đã "biết nói object" (nhưng shape ad-hoc):**
- Resolver: `admin_lookup_search(q)` — gate `is_admin()`, trả `{profiles[], children[], media[], capsules[]}`.
- Projections: `admin_lookup_{child,user,media,capsule}(uuid)`, `get_person_workspace(school,person)`, `get_school_people(school,q,limit)`.

**C. Primitive governance:**
- Capability: `has_permission(perm)` = `perm = any(profiles.permissions[])` cho `auth.uid()`.
- Gates: `is_admin()` (platform), `is_school_admin()` (INVOKER), assignment predicates (`is_teacher_in_school`, `is_session_responsible`…).
- Audit spine: `audit_logs` + `admin_audit_investigation(...)` + `admin_audit_group_events(...)` + `admin_workspace_access_log(entity,id,reason)` (reason-mandatory child, D345.2).

**Kết:** đủ nguyên liệu, thiếu **layer nối** (contract chung + registry + capability binding + health).

---

## 2. GAPS

| # | Gap | Bằng chứng | Ảnh hưởng |
|---|---|---|---|
| **G1** | Resolver mù object vận hành | `admin_lookup_search` chỉ resolve profiles/children/media/capsules | Không tìm được School/Class/Subscription/Support — đúng object admin cần |
| **G2** | Projection shape ad-hoc, KHÔNG phải `ObjectWorkspaceModel` | `admin_lookup_*` trả jsonb riêng từng cái | Renderer B0 chưa ăn được backend thật (chỉ ăn fixture) |
| **G3** | Capability chưa bind vào action | `has_permission` tồn tại nhưng không ai map ra `ObjectAction.enabled` server-side; và nó **scope-less** | Không có action gating thật; nếu bind sai → cross-tenant |
| **G4** | Health = 0 | Không nơi nào tính signal; `product_events`/`audit_logs` chưa chiếu thành attention | Admin phải mở từng object — không scale 100 trường |
| **G5** | Resolver chất lượng thấp | `ILIKE '%q%'` full-scan; media/capsule uuid-only; `LIMIT 10` no rank/paging; `is_admin()`-only | Enumeration/DoS ở 10k children; không school-scope |
| **G6** | History chưa map per-object | audit spine giàu nhưng chưa map ra `HistoryEntry[]` theo object | History band trống dù nguồn đã có |
| **G7** | Không có Object Registry | type→projector/capability/privacy chưa được khai báo | Mỗi object thành RPC bespoke → module-thinking rò ngược |

---

## 3. TARGET ARCHITECTURE — OBJECT INTELLIGENCE LAYER

**Ba plane, một pipeline, adapter-first (reuse primitive, KHÔNG rebuild):**

```
Command input (free text | uuid)
        │
 ┌──────▼─────────────────────────────── DISCOVERY PLANE
 │  resolve_object_candidates(q, scope?, limit?, cursor?)
 │    = adapter over admin_lookup_search + fragments MỚI (school/class/subscription/support)
 │  → ObjectCandidate[] { type, id, title, subtitle?, status?, score? }   (identity-only, rẻ, rank/page)
 │
 └──────┬──────────────────────────────
        │ (Admin chọn 1 candidate)
 ┌──────▼─────────────────────────────── PROJECTION PLANE
 │  get_object_workspace(type, id, reason?)
 │    = dispatch qua Object Registry → per-type projector
 │       person → wrap get_person_workspace · child → wrap admin_lookup_child (+reason-log)
 │       media → wrap admin_lookup_media · capsule → wrap admin_lookup_capsule
 │       school/class/subscription/support → projector MỚI
 │  → ObjectWorkspaceModel { identity, contexts, health, actions, history }
 │
 └──────┬──────────────────────────────
        │
 ┌──────▼─────────────────────────────── RENDER
 │  ObjectWorkspace (B0, unchanged) — 5 dải, KHÔNG rẽ nhánh type
 └─────────────────────────────────────

 GOVERNANCE PLANE (xuyên suốt):
   Object Registry (type → projector, capability_set, scope, privacy, forbidden_columns)
   Capability resolver (has_permission × scope predicate)
   Audit integration (admin_audit_investigation → history; admin_workspace_access_log → access)
```

**Nguyên tắc nền:** mọi thứ **map về contract v1 đã đóng băng**; thêm object = thêm entry registry + 1 projector, KHÔNG đụng renderer/command-bar; resolver/projector trả **business object**, KHÔNG trả database rows.

---

## 4. CONTRACTS

### 4.1 Object Registry (governance config — design-locked)

Nguồn sự thật ánh xạ type → cách vận hành. Mỗi entry:

```
ObjectTypeEntry {
  type:            'school'|'person'|'child'|'class'|'subscription'|'support_case'|'media'|'session'|'capsule'   // CLOSED set
  kind:            'core'|'supporting'|'future'|'forbidden'
  projector:       RPC name dựng workspace (vd get_object_workspace dispatch target)
  resolver_fields: string[]     // field identity an toàn phát trong candidate (discovery scope)
  capability_set:  { view, edit, assign, archive, export : perm-string | null }
  scope:           'platform'|'tenant'|'assignment'
  privacy_policy:  'open'|'reason_required'|'restricted'
  forbidden_cols:  string[]     // KHÔNG BAO GIỜ select (privacy-by-source)
}
```

- `type` **mở ở renderer** (open string) nhưng **đóng ở registry** — registry là gatekeeper.
- Thêm object = thêm 1 entry + 1 projector. Renderer & command-bar bất động (registry-driven, nguyên tắc #7).

### 4.2 Object Contract v1 (MỞ RỘNG B0.1, additive — KHÔNG phá renderer)

Giữ nguyên 5 field gốc. Bổ sung **chỉ field optional** để không phá `ObjectWorkspace`/bands đã ship:

- **Identity** — giữ `{type,id,title,subtitle?}`. Quy ước: `status` chuẩn hoá render trong subtitle/pill (map qua `stateLabel` đã có).
- **Context** — giữ `{kind,label,href?,meta}`. Quy ước boundary:
  - navigable → `href = /admin/object/<type>/<id>` (chung không gian địa chỉ resolver↔renderer).
  - permission-gated (vd School→Children) → KHÔNG href (informational count), mở phải qua reason-log.
  - forbidden → KHÔNG emit.
- **Health** — `HealthSignal v2` (additive): `{key, label, status, severity?, reason?, at?}`. `detail`(B0) ≡ `reason`. Health = *attention*, KHÔNG analytics.
- **Actions** — `ObjectAction v1` (additive metadata): `{key, label, intent, enabled, disabledReason?, required_capability?, scope?}`. `enabled`/`disabledReason` **server tính**; client mù.
- **History** — giữ `{id, at, actor?, summary, kind?}`. `summary`/`kind` mang "why" khi có (reason).

### 4.3 Resolver contract

```
resolve_object_candidates(q text, scope? , limit? int, cursor? text)
  → { ok:true, candidates: ObjectCandidate[], next_cursor? }
ObjectCandidate { type, id, title, subtitle?, status?, score? }   // identity-only; KHÔNG context/health/actions
```
- Adapter: gộp `admin_lookup_search` (person/child/media/capsule) + fragment MỚI (school/class/subscription/support).
- Mỗi type chỉ phát `resolver_fields` khai trong registry (discovery scope).
- Ranking (`score`) + paging (`cursor`) thay `LIMIT 10` cứng.
- `scope` = caller scope (platform admin → all; school operator → **filter theo school**, xem §7).

### 4.4 Workspace projection model

```
get_object_workspace(type text, id uuid, reason? text)
  → ObjectWorkspaceModel | { ok:false, error:'not_authorized'|'not_found'|'reason_required' }
```
- Dispatch qua registry.projector.
- **Reuse (wrap, KHÔNG viết lại):** person→`get_person_workspace`, child→`admin_lookup_child` (+ `admin_workspace_access_log` reason-mandatory, D345.2), media→`admin_lookup_media`, capsule→`admin_lookup_capsule`. Wrapper = map jsonb ad-hoc → `ObjectWorkspaceModel`.
- **New projector:** school/class/subscription/support — mỗi cái tự chịu authz + privacy của type (forbidden_cols không select).
- Hydrate đầy 5 dải; lazy (chỉ khi chọn candidate).

### 4.5 Capability × Scope model

**Công thức:** `can(verb, object) = has_permission(perm(verb,object)) AND scope_predicate(object)`.

- `perm(verb,object)` = `<obj>.<verb>` (vd `school.edit`, `subscription.export`) — đọc từ `profiles.permissions[]` qua `has_permission` (additive, nguyên tắc #4).
- `scope_predicate` theo registry.scope:
  - `platform` → `is_admin()`
  - `tenant` → `is_school_admin() OR profile-in-school(object.school_id)`
  - `assignment` → `is_teacher_in_school(...)` / `is_session_responsible(...)` (D346/D324)
- ⚠️ **`has_permission` là membership TOÀN CỤC, KHÔNG scope.** Một capability có scope = permission-class **AND** object-predicate. Permission trả lời *"được làm loại việc này"*; predicate trả lời *"trên object/scope nào"*. **Cấm** để permission toàn cục tự mở một object cụ thể.
- Server là authority: projector tính `ObjectAction.enabled` + `disabledReason` (mirror D290/D293). Không dùng `role===admin`.

### 4.6 Action descriptor model

- `ObjectAction` = descriptor thuần (B0), thêm `required_capability` + `scope` (audit/tra-cứu; client KHÔNG tự tính enable).
- **Action registry (design-locked):** `action.key → hardened RPC` an toàn. Client dispatch `key` → RPC đã harden (vd `assign_teacher` → `admin_activate_teacher` với role-integrity guard D345.3), **KHÔNG ghi thẳng bảng** (D346.3).
- Discovery ≠ execution: `enabled` ở workspace là gợi ý; RPC **tái kiểm** capability lúc chạy.
- Verb chuẩn: `can_view · can_edit · can_assign · can_archive · can_export`.

### 4.7 Health Signal model

`HealthSignal v2 {key,label,status,severity?,reason?,at?}`. Rule per-type (design-locked ví dụ):

| Object | Signal ví dụ | status/severity | Nguồn |
|---|---|---|---|
| School | Subscription sắp hết/hết hạn | risk/high | `school_subscriptions` |
| School | Lớp không có lead | watch/medium | `class_distributions` null lead |
| School | 0 session 30 ngày | watch/low | `lesson_sessions` recency |
| Child | Chưa enroll / thiếu consent | watch / risk | `enrollments`, `consents` |
| Subscription | Quá hạn thanh toán | risk/high | `school_subscriptions` |
| Support Case | Chưa gán + tồn đọng | watch→risk theo tuổi | `support_requests` |

- Health = *"admin có cần chú ý object này không?"* — KHÔNG biểu đồ, KHÔNG KPI, **KHÔNG chấm điểm/xếp hạng trẻ** (LINH HỒN).
- Nguồn: trạng thái quan hệ + `product_events`. **KHÔNG bảng analytics mới.**

### 4.8 Audit / Historical integration

- **HistoryBand** per object = `admin_audit_investigation(entity_type=<type>, entity_id=<id>, ...)` → map `HistoryEntry[]`; burst gộp qua `admin_audit_group_events`.
- **"Why"** = `admin_workspace_access_log.reason` (D345.2) + audit summary.
- **Self-auditing:** mở workspace của child/parent **tự ghi** access log (reason-mandatory child). Tầng intelligence tự nó auditable — xem-cũng-để-lại-vết.

---

## 5. OBJECT PRIORITY

| Object | Kind | Priority | Reuse (đã có) | Build-new |
|---|---|---|---|---|
| **Person** | Core | **P0** | `get_person_workspace` (wrap) | wrapper→contract |
| **Child** | Core | **P0** | `admin_lookup_child` (+reason gate) | wrapper + access-log |
| **School** | Core | **P1 ★** | — | projector + health + capability (gap lớn nhất) |
| **Subscription** | Core | **P1 ★** | — | projector (commercial) |
| **Support Case** | Core | **P1 ★** | — | projector (ops triage) |
| **Class** | Core | **P2** | — | projector |
| **Media** | Supporting | **P2** | `admin_lookup_media` (wrap) | wrapper |
| **Capsule** | Supporting | **P2** | `admin_lookup_capsule` (wrap) | wrapper |
| **Session / Program / Privacy Req** | Supporting | **P3** | partial | projector sau |
| **Family / Kid / Billing** | Future | — | — | registry-ready, chưa build |
| **Child journey/journal/skills/badges · Family memory · Raw media bytes** | **Forbidden** | — | — | **KHÔNG BAO GIỜ** (LINH HỒN + D347.3) |

★ = ưu tiên B2 (Person/Child/Media/Capsule đã resolve; School/Subscription/Support là gap vận hành + doanh thu lớn nhất).

---

## 6. BUILD SEQUENCE (B2 →, chờ Owner authorize)

| Pha | Nội dung | Delta | Rollback |
|---|---|---|---|
| **B1** (report này) | Registry + Contract v1 + Capability/Health/Action/Audit model — **DESIGN ONLY** | 0 | — |
| **B2.0** | Object Registry schema + Contract v1 header additions (spec, chưa behavior) | DB additive (config) | drop registry |
| **B2.1** | **Adapter seam:** `resolve_object_candidates` + `get_object_workspace` wrap `admin_lookup_*`/`get_person_workspace` → contract v1. **0 object type mới** (chứng minh seam). secdef, D15/D231 harden, D289 reload. | DB additive | DROP 2 adapter RPC |
| **B2.2** ★ | New core projector: **School → Subscription → Support**. Mỗi cái = projector RPC + registry entry + health rule + capability binding. | DB additive | DROP projector + registry entry |
| **B2.3** | Health computation per-type (relational + product_events) | DB additive | DROP health fn |
| **B2.4** | Resolver quality: FTS/trigram, paging, ranking; fragment school/class/subscription/support; **school-scoping** | DB additive | revert resolver |
| **B3** | FE: nối command bar + `admin.object.$type.$id` → resolver/projector thật. Module grid GIỮ fallback. | FE additive | FE revert |
| **B4** | Gấp module route → object action/context. Retire `admin.modules` **chỉ khi** mọi năng lực có object home. | FE trừ dần | un-retire |

Mỗi pha rollback-độc-lập; DB additive; module grid là lưới an toàn tới B4.

---

## 7. SECURITY CONSIDERATIONS

1. **Discovery ≠ Access** (định đề). Resolver phát identity; mỗi band/action **tái authorize**. Child workspace = reason-mandatory + logged (D345.2).
2. **Cross-school leakage (rủi ro CAO):** resolver `is_admin()`-only hôm nay chưa rò. **STOP-condition:** khi (a) thêm School/Subscription vào resolver và (b) cho school operator (`is_school_admin`) dùng Mission Control — resolver **BẮT BUỘC school-scope** candidate theo caller. School operator KHÔNG resolve object trường khác. Phải thiết kế **TRƯỚC** khi expose.
3. **Child privacy:** `forbidden_cols` KHÔNG BAO GIỜ select (privacy-by-source D347.3); Forbidden objects không project. `admin_lookup_search` hiện phát `children.full_name/nickname` cho **platform admin** (identity only, KHÔNG journey/media) → cần **Owner ruling**: giữ cho platform-admin + reason-log (đã có), hay mask khi school-operator vào.
4. **Privilege escalation:** capability từ `permissions[]` **server-verify**; action đi qua hardened RPC (role-integrity guard D345.3: `cannot_downgrade_admin`, `has_active_parent_link`), KHÔNG ghi thẳng bảng.
5. **Search boundary:** `ILIKE '%q%'` = enumeration/DoS ở scale → FTS/trigram + rate/paging. **Giữ media/capsule uuid-only** (chặn enumeration nội dung).
6. **Audit completeness:** mọi workspace-open + action ghi log; tầng intelligence tự auditable.

**Constraints tuân thủ:** KHÔNG redesign identity · KHÔNG redesign RLS · KHÔNG role model mới · reuse `admin_lookup_search` / `admin_lookup_*` / `has_permission` / `audit_logs` / renderer B0.

---

## 8. B1 RECOMMENDATION

- **Design duyệt = B1 done.** Trước B2, Owner chốt 2 quyết định: (1) thứ tự coverage (★ School → Subscription → Support); (2) child-in-search policy (§7.3).
- **STOP trước build:** resolver school-scoping PHẢI có trước khi non-platform operator chạm Mission Control.
- **Pre-flight B2 (audit ngắn, không phải blocker B1):** verify index strategy (trigram/FTS?) + column-shape `school_subscriptions`/`support_requests` cho projector + RLS cross-school khi platform admin project.

---

### PHỤ LỤC — Reuse map (verified present, this session)

| Contract piece | Reuse primitive | Vai trò |
|---|---|---|
| Resolver | `admin_lookup_search` | discovery base (person/child/media/capsule) |
| Projection person/child/media/capsule | `admin_lookup_{user,child,media,capsule}`, `get_person_workspace`, `get_school_people` | wrap → contract v1 |
| Capability | `has_permission` | permission-class (× scope predicate) |
| Scope | `is_admin`, `is_school_admin`, assignment predicates | scope binding |
| History | `admin_audit_investigation`, `admin_audit_group_events` | HistoryEntry[] source |
| Access log | `admin_workspace_access_log` | reason-mandatory child (D345.2) |
| Render | `ObjectWorkspace` (B0) | 5-band, unchanged |

**END V128-B1 DESIGN — 0 CODE / 0 SQL / 0 MIGRATION / 0 UI IMPL.**
