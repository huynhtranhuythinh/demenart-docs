# V128-B2.0 — OBJECT REGISTRY FOUNDATION & ADAPTER SEAM — DESIGN PACKAGE

> **Loại:** DESIGN ONLY (B2.0 + B2.1). Không UI · không migration execution · không production mutation · không code ship.
> **Vai:** Claude = PM + System Designer · ChatGPT = CTO/CPO reviewer.
> **Canonical:** D348 · SYSTEM_MAP v1.36 · HANDOFF V128-M0 · HEAD `be04f4b`.
> **Re-pin (LIVE, verified phiên này):** baseline FROZEN **89 tables · 233 functions · 222 SECURITY DEFINER · tail `20260810074214`**. 5 wrap-target RPC + `has_permission`/`is_admin`/`is_school_admin`/`admin_audit_investigation`/`admin_workspace_access_log` present.
> **Constraint tuân thủ:** KHÔNG redesign identity · KHÔNG redesign RLS · KHÔNG role mới · **Renderer B0 BẤT BIẾN**.

---

## 1. RE-PIN B1 CONTRACTS

Từ B1 DESIGN LOCKED (D348.2 contract v1):

- **ObjectWorkspaceModel** (B0-frozen, renderer đọc): `{ identity, contexts, health, actions, history }`.
  - `ObjectIdentity {type, id, title, subtitle?}`
  - `ObjectContext {kind, label, href?, meta:{label,value}[]}`
  - `HealthSignal {key, label, status:ok|watch|risk|unknown, detail?}`
  - `ObjectAction {key, label, intent:primary|default|danger, enabled, disabledReason?}` — descriptor thuần.
  - `HistoryEntry {id, at, actor?, summary, kind?}`
- **Pipeline:** Discovery (`resolve_object_candidates`) → Projection (`get_object_workspace` dispatch qua registry) → Render (B0).
- **Capability = permission-class × scope-predicate.** Discovery ≠ Access.

> ⚠️ **Renderer-immutability rule cho B2.1:** adapter phải emit **đúng field B0** (`status`/`detail`; `intent`/`enabled`/`disabledReason`; `id`/`at`/`actor`/`summary`/`kind`). Các mở rộng B1 (`severity`/`at` health, `required_capability`/`scope` action) là **optional, hoãn tới B2.3** — renderer B0 bỏ qua field lạ, nên KHÔNG cần sửa renderer. B2.1 render được ngay.

---

## 2. AUDIT — EXISTING DB PRIMITIVES (5 wrap-target, shape thật)

Tất cả `SECURITY DEFINER`, `search_path` set, gate `is_admin()` (trừ person). Denial: `{ok:false, error:'not_admin'|'not_found'|'not_authorized'}`.

| RPC | Gate | Output keys (thật) | Ghi chú privacy |
|---|---|---|---|
| `admin_lookup_user(uuid)` | is_admin | `profile{id,full_name,email,phone,role,state,school_id,school,has_login,permissions,created_at}` · `children[{id,full_name,link_role}]` · `teaching{lead_distributions,session_teacher_rows}` · `recent_audit[{action,entity_type,at}]` | permissions/role có mặt — dùng cho capability/context, KHÔNG render UI từ role (D347.4) |
| `get_person_workspace(school,person)` | is_admin OR profile-in-school | `identity{id,name,email,phone}` · `contexts[{type:school}]` · `responsibilities[{type:teaching,class_id,class_name,title}]` | **school-scoped** — dùng cho tenant-scope person |
| `admin_lookup_child(uuid)` | is_admin | `child{id,full_name,nickname,state,created_at}` · `parents[]` · `enrollments[]` · `consents[]` · `kid_devices{}` · `media_counts{}` · **`journal_summary{}` · `evidence{}` · `readiness{}` · `capsules[]` · `parent_memory{}` · `memory_conversation{}`** | **metadata/counts-only, KHÔNG nội dung (D244)**. Tầng in đậm = meaning/family domain → adapter DROP |
| `admin_lookup_media(uuid)` | is_admin | `media{...metadata, uploader, linked_child, linked_school}` · `moment{caption,state,tagged_children[]}` · `consent_state[]` · `diagnostic{all_required_consents_granted,...}` · `recent_audit[{action,actor,at,reason}]` | 0 bytes/URL (tốt) · recent_audit có actor+reason |
| `admin_lookup_capsule(uuid)` | is_admin | `capsule{id,child,child_id,scope,domain,window_*,policy_versions,payload_hash,created_at}` · **`items[{taxonomy_code,pattern_key,claim_strength,support}]`** · `item_count` | **`items` = meaning-content raw (no suppression)** → adapter DROP items, chỉ integrity metadata |

**Kết luận audit:** 5 RPC đủ để wrap; authz đã nằm sẵn trong RPC (adapter KHÔNG re-implement). 2 RPC (child/capsule) phát tầng meaning/family → adapter phải áp **privacy policy riêng** (DROP), không pass-through.

---

## 3. OBJECT REGISTRY v1

### 3.1 Storage choice (★ recommendation)

| Option | Mô tả | Trade-off |
|---|---|---|
| **A ★ DB table `mission_control_object_registry` (declarative catalog) + dispatch CASE in adapter** | Registry = **data** (type, kind, scope, privacy_policy, forbidden_field_groups, capability_vocab, discovery_fields). Dispatch (type→projector RPC) = **explicit CASE trong `get_object_workspace`** | Consistent với DMA registry DNA (route/policy/edge_function_registry, principle #7) · config-driven (#6) · one-truth-one-place (#5) · **KHÔNG dynamic function-name execution từ string** (không injection surface) · schema thuộc migration (D11). +1 table ở B2.0 build |
| B | Code constant (TS + SQL mirror) | Zero DB nhưng **two-source-of-truth** (vi phạm #5) — FE và backend lệch |
| C | Hybrid: SQL function trả registry + FE đọc | Không table nhưng logic-as-data khó version |

**★ Chọn A.** Registry là **catalog khai báo** (data); **dispatch là CASE tường minh** (code, auditable). Ranh giới quan trọng: *"projector nào cho type nào" là code review được, KHÔNG phải string trong bảng chạy động* → chặn EXECUTE injection.

### 3.2 Registry v1 — schema (declarative, B2.0 seed; 0 behavior)

```
mission_control_object_registry (
  object_type       text PRIMARY KEY,          -- CLOSED set
  kind              text,   -- 'core'|'supporting'|'future'|'forbidden'
  scope             text,   -- 'platform'|'tenant'|'assignment'
  privacy_policy    text,   -- 'open'|'reason_required'|'restricted'
  discovery_fields  text[], -- field identity an toàn phát trong candidate
  forbidden_groups  text[], -- nhóm field KHÔNG BAO GIỜ project
  capability_vocab  jsonb,  -- { view,edit,assign,archive,export : perm-string|null }
  projector_status  text    -- 'wired'|'registered'|'none'  (B2.1 wire 4; còn lại registered)
)
```

### 3.3 Registry v1 — seed content (design-locked)

| object_type | kind | scope | privacy_policy | projector (B2.1) | forbidden_groups |
|---|---|---|---|---|---|
| `person` | core | platform (+tenant) | open | `admin_lookup_user` (platform) / `get_person_workspace` (tenant) — **wired** | — |
| `child` | core | platform | **reason_required** | `admin_lookup_child` — **wired** | journal_summary · evidence · readiness · capsules · parent_memory · memory_conversation |
| `media` | supporting | platform | open | `admin_lookup_media` — **wired** | raw_bytes · signed_url |
| `capsule` | supporting | platform | **restricted** | `admin_lookup_capsule` — **wired** | items (meaning-content) |
| `school` | core | tenant | open | — registered (B2.2) | — |
| `subscription` | core | platform | open | — registered (B2.2) | — |
| `support_case` | core | platform | open | — registered (B2.2) | — |
| `class` | core | tenant | open | — registered (B2.2/P2) | — |
| `session` · `program` · `privacy_request` | supporting | mixed | open | — registered (P3) | — |
| `child_journey`·`journal`·`skills`·`badges`·`family_memory`·`raw_media` | **forbidden** | — | **restricted** | **none — projector CẤM tồn tại** | * (toàn bộ) |

> **Defense-in-depth:** forbidden types được **khai báo tường minh** (không chỉ vắng mặt). `get_object_workspace` reject ngay nếu `kind='forbidden'` → không thể vô tình build projector cho chúng.

### 3.4 Capability vocabulary (B2.0 khóa từ, KHÔNG grant — 0 permission change)

- Verb: `view · edit · assign · archive · export`.
- Perm-string convention: `<object_type>.<verb>` (vd `person.edit`, `subscription.export`).
- **B2.0 chỉ KHÓA từ vựng** (đăng ký vào `capability_vocab`); KHÔNG thêm/sửa `profiles.permissions[]`, KHÔNG grant. Enforcement = B2.1 (`has_permission(perm) AND scope_predicate`).

### 3.5 Privacy & scope vocabulary

- privacy_policy: `open` (project tự do trong is_admin) · `reason_required` (child — `admin_workspace_access_log` bắt buộc, D345.2) · `restricted` (capsule/forbidden — chỉ integrity metadata hoặc reject).
- scope: `platform` (`is_admin`) · `tenant` (`is_school_admin` OR profile-in-school) · `assignment` (teacher predicates).

---

## 4. ADAPTER SEAM (B2.1)

### 4.1 Projector interface

```
get_object_workspace(p_type text, p_id uuid, p_reason text DEFAULT NULL)
  → jsonb  (ObjectWorkspaceModel | {ok:false, error})
```

Luồng nội bộ (thin, authz ở RPC được wrap):
1. Lookup `p_type` trong registry. Không có → `{ok:false,error:'unknown_type'}`.
2. `kind='forbidden'` → `{ok:false,error:'forbidden_type'}`. `projector_status≠'wired'` → `{ok:false,error:'not_available'}`.
3. `privacy_policy='reason_required'` (child) và `p_reason` rỗng → gọi `admin_workspace_access_log('child',p_id,p_reason)` (nó trả `reason_required` nếu rỗng) → **KHÔNG project**. Reason hợp lệ → log rồi tiếp.
4. **Dispatch CASE** (tường minh, KHÔNG dynamic) → gọi RPC được wrap → nhận jsonb thật.
5. RPC trả `not_admin`/`not_authorized`/`not_found` → **propagate nguyên trạng** (adapter KHÔNG nới authz).
6. **Map** jsonb thật → `ObjectWorkspaceModel` theo §4.3 (áp `forbidden_groups`: DROP).
7. Return.

### 4.2 Resolver adapter boundary (B2.1)

```
resolve_object_candidates(p_q text, p_limit int DEFAULT 20)
  → { ok:true, candidates: [{type,id,title,subtitle?,status?}] }
```
- B2.1 = **pure shape-map** của `admin_lookup_search(p_q)`: 4 mảng (`profiles/children/media/capsules`) → 1 mảng phẳng `candidates[]` gắn `type`.
- **KHÔNG** thêm fragment school/subscription/support (đó là B2.2). **KHÔNG** đổi ranking/paging/ILIKE (đó là B2.4). Chỉ chứng minh seam shape.
- Gate `is_admin()` giữ nguyên (từ `admin_lookup_search`).
- `type` gắn: profiles→`person`, children→`child`, media→`media`, capsules→`capsule`. Candidate chỉ phát `discovery_fields` (registry).

### 4.3 Field mapping (RPC output → ObjectWorkspaceModel) — design-locked

**PERSON** (`admin_lookup_user`, platform):
| Band | Nguồn | Map |
|---|---|---|
| identity | profile | `{type:'person', id, title:full_name, subtitle:stateLabel(state)}` |
| contexts | profile.school / children / teaching | `{kind:'school',label:'Trường',href:/admin/object/school/<school_id>,meta:[{Trường,school}]}` · `{kind:'account',meta:[{Vai trò,roleLabel(role)},{Đăng nhập,has_login}]}` · children→`{kind:'child',meta:names}` (**no href** — child reason-gated) · teaching→`{kind:'teaching',meta:[lead_distributions,session_teacher_rows]}` |
| health | derive | has_login=false→`{status:'watch',detail:'Chưa kích hoạt đăng nhập'}` · state≠active→`{status:'watch'}` |
| actions | capability | `view` · `edit`(person.edit) · `assign_teacher`→`admin_activate_teacher`(teacher.activate, hardened) · `archive`(person.archive) |
| history | recent_audit[] | `{id:synth, at, actor:full_name, summary:auditActionLabel(action), kind:entity_type}` |

**PERSON (tenant)** (`get_person_workspace`, school operator — registered, wired ở B2.4 khi school-op vào): identity/contexts/responsibilities map thẳng; scope=tenant.

**CHILD** (`admin_lookup_child`, reason_required):
| Band | Nguồn | Map |
|---|---|---|
| identity | child | `{type:'child', id, title:full_name, subtitle:stateLabel(state)}` |
| contexts | parents/enrollments/kid_devices/media_counts | parents→`{kind:'parent',href:/admin/object/person/<profile_id>,meta:names+link_role}` · enrollments→`{kind:'enrollment',meta:class+school+state}` (no href tới B2.2 class) · devices→`{kind:'device',meta:active/revoked}` · media_counts→`{kind:'media',meta:by-state}` (operational) |
| health | consents/enrollments/media_counts | consent thiếu/withdrawn→`risk/watch` · no enrollment→`watch` · media pending→`watch` |
| actions | capability | `view`(reason-gated) · `edit`(child.edit) · `archive`(child.archive) |
| history | `admin_audit_investigation(entity_type='children',entity_id=id)` | (child RPC không có recent_audit → adapter enrich từ audit spine) |
| **DROP** | journal_summary · evidence · readiness · capsules · parent_memory · memory_conversation | **LINH HỒN + D347.3** — meaning/family domain KHÔNG project vào Mission Control |

**MEDIA** (`admin_lookup_media`):
| Band | Map |
|---|---|
| identity | `{type:'media', id, title:file_type+'·'+media_group, subtitle:stateLabel(state)+'·'+approval_status}` |
| contexts | linkage→`{kind:'linkage',meta:uploader,linked_child,linked_school}` · moment→`{kind:'moment',meta:caption,state,tagged_count}` · storage→`{kind:'storage',meta:zone,access_level,size}` |
| health | `diagnostic.all_required_consents_granted=false`→`risk/high` · moment not approved→`watch` · not active/trashed→`watch` |
| actions | `view` · `archive`(media.archive) — B2.1 tối thiểu |
| history | recent_audit[]→`{id,at,actor,summary:auditActionLabel(action),kind:'media', /*reason in summary*/}` (đã có actor+reason) |
| DROP | (RPC vốn 0 bytes/URL — không cần drop) |

**CAPSULE** (`admin_lookup_capsule`, restricted):
| Band | Map |
|---|---|
| identity | `{type:'capsule', id, title:'Capsule · '+scope+'/'+domain, subtitle:window_code}` |
| contexts | `{kind:'child',meta:child}` (no href — child reason-gated) · `{kind:'integrity',meta:policy_versions,payload_hash,item_count}` |
| health | discovery_version stale→`watch` · item_count=0→`unknown` |
| actions | `view` (integrity only) |
| history | (sparse; audit spine sau) |
| **DROP** | `items[]` (taxonomy/pattern/claim = meaning-content) — admin thấy capsule **tồn tại + toàn vẹn**, KHÔNG đọc pattern con |

---

## 5. SECURITY GATES (B2.1)

1. **Authz không nới.** Adapter gọi RPC đã gate (`is_admin`/person: is_admin OR profile-in-school); denial propagate. Adapter KHÔNG tự check quyền → không có đường vòng.
2. **Reason-required (child).** Adapter gọi `admin_workspace_access_log('child',id,reason)` TRƯỚC khi project; rỗng → `reason_required`, dừng. (D345.2 self-auditing: xem-để-lại-vết.)
3. **Forbidden reject.** `kind='forbidden'` → reject tại adapter (defense-in-depth, §3.3).
4. **No dynamic dispatch.** Dispatch = CASE tường minh; KHÔNG execute function-name từ registry string → 0 injection surface.
5. **Privacy DROP tại map.** `forbidden_groups` không được map ra output → UI không thể leak thứ không projected (privacy-by-source, D347.3).
6. **ACL (D15/D231).** 2 RPC mới + registry table: `REVOKE ALL FROM public, anon`; `GRANT authenticated/service_role`; verify `aclexplode` no-anon. `notify pgrst` (D289).
7. **Renderer immutable.** Adapter emit đúng field B0 → renderer B0 không đổi.

---

## 6. ROLLBACK PLAN

**B2.1 = additive backend, DB-only.** Rollback độc lập, sạch:
- `DROP FUNCTION get_object_workspace`, `resolve_object_candidates`.
- `DROP TABLE mission_control_object_registry` (nếu B2.0 đã tạo).
- Revoke grants; `notify pgrst`.
- **FE không đụng** (B2.1 backend-only) · **Renderer B0 bất biến** · **5 RPC wrap-target không sửa** (chỉ được gọi).
- DB baseline về `be04f4b`/tail `20260810074214`. Zero residue.

---

## 7. VERIFICATION PLAN

| Loại | Cách | Kỳ vọng |
|---|---|---|
| **Structural** | count registry seed rows = |types|; adapter CASE branches = types `projector_status='wired'` (không orphan/thừa) | khớp |
| **Shape** | impersonate platform admin (D2/D333: `set_config request.jwt.claims` + `SET LOCAL ROLE authenticated`, dùng `profiles.user_id`); gọi `get_object_workspace` cho 1 person/child/media/capsule thật (DEMO-001) | mỗi output có đủ 5 band, field B0 đúng type; renderer-parse được |
| **Privacy DROP** | child output | KHÔNG chứa journal_summary/evidence/readiness/capsules/parent_memory keys; capsule output KHÔNG chứa items |
| **Reason gate** | `get_object_workspace('child',id, NULL)` | `reason_required`, KHÔNG project; và access-log ghi khi reason hợp lệ (verify trong DO block, `RAISE 'ROLLBACK_OK:'||...` — rollback sạch, 0 residue) |
| **Authz** | impersonate non-admin | `not_admin`/`not_authorized`; forbidden type → `forbidden_type` |
| **Resolver shape** | `resolve_object_candidates('<demo>')` | `candidates[]` phẳng, mỗi item có `type` đúng 4 loại |
| **ACL** | `aclexplode` 2 RPC mới | authenticated/postgres/service_role only; anon/PUBLIC denied |
| **Renderer** | B0 `ObjectWorkspace` với output thật (fixture→real swap ở B3) | render 5 band không lỗi |

> **Real-login (D2/D3) HOÃN sang B3.** B2.1 là backend adapter; verify ở tầng RPC qua impersonation. Wiring FE (`admin.object.$type.$id` fixture→real) + real-login QA = **B3**. B2.1 KHÔNG tự tuyên PASS end-to-end.

---

## 8. B2.0/B2.1 RECOMMENDATION & SEQUENCE

```
B2.0  Registry Foundation      → mission_control_object_registry (schema + seed, 0 behavior)
                                  + capability/privacy/scope vocab khóa
        ↓  (Owner review)
B2.1  Adapter Seam Proof        → get_object_workspace (dispatch 4 wired type)
                                  + resolve_object_candidates (shape-map)
                                  wrap admin_lookup_* / get_person_workspace → ObjectWorkspaceModel
                                  KHÔNG thêm School. Nếu fail → lỗi ở SEAM, không lẫn domain.
        ↓  (seam PASS)
B2.2  First Operational Objects → School → Subscription → Support (projector mới)
```

- **STOP trước B2.4/B3:** resolver school-scoping phải thiết kế trước khi non-platform operator chạm Mission Control.
- **Owner Gate đã chốt (từ CTO review):** coverage order P0 person/child → P1 school/subscription/support → P2 class/media/capsule; child-search policy platform-admin(full identity+reason-log) vs school-operator(school-scope + assigned only).

**Chờ authorize để chuyển B2.0 → build (migration).** Design pass này KHÔNG tạo table/RPC/migration.

---

### PHỤ LỤC — Constraint compliance

| Constraint | Tuân thủ |
|---|---|
| KHÔNG redesign identity | ✓ wrap identity từ RPC có sẵn, không đổi `profiles`/`children` |
| KHÔNG redesign RLS | ✓ authz nằm trong RPC được wrap; adapter không thêm/sửa policy |
| KHÔNG role mới | ✓ capability qua `permissions[]` sẵn có; 0 grant ở B2.0 |
| Renderer B0 immutable | ✓ emit đúng field B0; mở rộng optional hoãn B2.3 |
| Reuse primitives | ✓ 5 RPC + `has_permission` + `audit_logs` + `admin_workspace_access_log` + renderer |

**END V128-B2.0 DESIGN PACKAGE — 0 CODE / 0 SQL / 0 MIGRATION / 0 UI / 0 MUTATION.**
