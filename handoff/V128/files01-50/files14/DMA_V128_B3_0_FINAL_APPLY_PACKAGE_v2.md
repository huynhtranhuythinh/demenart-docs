# V128-B3.0 FINAL APPLY PACKAGE v2
## Context Seam Foundation — Mission Control OS

> **Loại:** DESIGN REVISION ONLY · backend-only (foundation) · **KHÔNG apply.**
> **Disposition CTO:** PASS WITH REQUIRED REVISION → package này incorporate toàn bộ CTO resolved decisions.
> **Baseline (current tip, live B2.2):** RULES **D351** · SYSTEM_MAP **v1.39** · HANDOFF **V128-B2.2** · migration tail `20260811080037` · FE HEAD `be04f4b` (BẤT BIẾN).
> **DB inventory baseline:** 90 tables · 235 functions · 224 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron.
> **Boundary tuyệt đối:** không `apply_migration`, không `execute_sql`, không đụng Supabase live, không sửa FE / RLS / role / DTO contract, không canonicalize RULES/SYSTEM_MAP/HANDOFF, không gửi Lovable build. Mọi SQL trong file = **DESIGN PLACEHOLDER**.

---

## 1. CTO RESOLVED DECISIONS

Sáu quyết định đã chốt (khóa cho B3.0, không mở lại trong package này):

| # | Quyết định | Chốt |
|---|---|---|
| **D-1 · Adapter Strategy** | Giữ **Variant A** — legacy compatibility + shared enforcement core. Không chuyển Variant B. Kiến trúc: `legacy 3-arg → shared internal gate core → context-aware 4-arg`. Không cần giữ function body byte-identical; **phải** giữ RPC compatibility + DTO behavior + existing wired-object behavior + ACL behavior. | ✅ |
| **D-2 · Context Requirements Storage** | Không dùng `text[]`. Dùng **JSONB metadata**: `context_requirements jsonb NOT NULL`, default `{"version":1,"keys":{},"allow_unknown":false}`. Declarative-only: no executable metadata, no table names, no SQL predicate, no function names, no dynamic dispatch. Thêm **CHECK constraint** enforce schema safety. | ✅ |
| **D-3 · Context Validator Seam** | Tách validator riêng, **không** inline toàn bộ validation trong adapter: `validate_mission_control_object_context(p_object_type text, p_context jsonb)`. **Chỉ structural validation.** Được đọc registry + context_requirements + validate JSON shape/required-keys/primitive-types + reject unknown keys + normalize. **Cấm** đọc target object / classes / sessions / memberships / permissions / authorize user. **Context valid ≠ Authorized.** | ✅ |
| **D-4 · Security Ordering** | Freeze canonical order: `authenticate → registry/object metadata → validate context → context authorization slot → privacy/reason checks → touch object/projector`. B3.0: **context authorization slot = placeholder/no-op** nhưng phải giữ vị trí cho B3.1. **Cấm lookup-first** (touch → discover tenant → authorize). | ✅ |
| **D-5 · Adapter Overload** | Giữ overload path. Legacy `get_object_workspace(text,uuid,text)` giữ nguyên external signature. New `get_object_workspace(text,uuid,jsonb,text)` với **`p_context` required — KHÔNG DEFAULT** (tránh PostgREST overload ambiguity / PGRST203). Verify: named RPC resolution + positional resolution + no PGRST203. | ✅ |
| **D-6 · Foundation-only bar** | B3.0 chỉ tạo Context Contract Layer. Không wire object mới, không projector mới, không command/permission/audit-ledger system, không đụng RLS/role/FE/DTO. | ✅ |

---

## 2. FINAL ARCHITECTURE

### 2.1 Ba tầng Context Seam (mới) chồng lên chokepoint hiện có

```
                     PostgREST / SQL caller
                              │
             ┌────────────────┴────────────────┐
             │                                 │
   get_object_workspace(              get_object_workspace(
     text, uuid, text)                  text, uuid, jsonb, text)
   LEGACY 3-arg overload              NEW 4-arg overload
   (thin wrapper)                     (thin wrapper, p_context REQUIRED)
             │  context := '{}'                 │  context := p_context
             └────────────────┬────────────────┘
                              ▼
        ┌─────────────────────────────────────────────┐
        │   SHARED INTERNAL GATE CORE  (private)        │
        │   _mission_control_workspace_core(            │
        │     text, uuid, jsonb, text)                  │
        │   SECURITY DEFINER · search_path=''           │
        │   ACL: 0 client roles (internal-only)         │
        │                                               │
        │   canonical order:                            │
        │   1 authenticate (is_admin)                   │
        │   2 registry/object metadata                  │
        │        (unknown→forbidden→not_available       │
        │         →scope_not_wired)                     │
        │   3 VALIDATE CONTEXT  ───────────────┐        │
        │   4 CONTEXT AUTHORIZATION SLOT (no-op)│        │
        │   5 privacy/reason (reason_required,  │        │
        │        access-log)                    │        │
        │   6 touch object → static CASE →      │        │
        │        projector → allowlist →        │        │
        │        leak-guard → DTO               │        │
        └───────────────────────────────────────┼───────┘
                                                ▼
                     validate_mission_control_object_context(
                       text, jsonb)   ── structural only ──►
                       reads: registry.context_requirements
                       returns: {valid, errors, normalized_context}
                       NEVER touches target object / auth
```

### 2.2 Nguyên tắc kiến trúc

- **Single chokepoint được bảo tồn:** cả hai overload đều rỗng (thin), toàn bộ enforcement sống ở **một** core private. Không nhân đôi logic → không drift giữa 3-arg và 4-arg.
- **Declare-then-touch:** caller **khai báo** context up-front; core **validate shape** → (B3.1) **authorize** context → **chỉ sau đó** projector chạm object row. Object row **không bao giờ** là nguồn của quyết định authorization (chống lookup-first, D-4).
- **Context valid ≠ Authorized:** validator (tầng structural) và auth-slot (tầng B3.1) là hai seam tách rời. B3.0 chỉ đóng seam validator; auth-slot là lỗ chờ.
- **DTO bất biến:** core vẫn trả `WorkspaceProjectionDTO/v1` y hệt B2.2. Không bump.

---

## 3. FINAL MIGRATION BOUNDARY

### 3.1 IN SCOPE (B3.0 tạo/đổi)

1. **`ALTER TABLE mission_control_object_registry ADD COLUMN context_requirements jsonb NOT NULL DEFAULT '{...}'`** + **CHECK** `mc_context_requirements_shape_chk`. Backfill tự động qua column DEFAULT (17 rows nhận default).
2. **`CREATE FUNCTION validate_mission_control_object_context(text, jsonb)`** — structural validator (secdef, search_path='').
3. **`CREATE FUNCTION _mission_control_workspace_core(text, uuid, jsonb, text)`** — shared gate core (secdef, search_path='', internal-only ACL).
4. **`CREATE OR REPLACE FUNCTION get_object_workspace(text, uuid, text)`** — refactor legacy 3-arg → thin wrapper (body đổi, external contract giữ).
5. **`CREATE FUNCTION get_object_workspace(text, uuid, jsonb, text)`** — new 4-arg overload (thin wrapper, `p_context` no-default).
6. **ACL hardening** (D15/D231) cho cả 4 function trên + `NOTIFY pgrst, 'reload schema'` (D289).

**Δ ròng dự kiến:** +1 column · +1 CHECK · **+3 functions** (validator + core + 4-arg overload) · 1 function REPLACE (3-arg). **Projector +0.**

### 3.2 OUT OF SCOPE (B3.0 KHÔNG đụng — freeze)

- Không set `context_requirements` của **bất kỳ** object nào ≠ default → **không object nào đổi behavior** (proof §11).
- Không wire object registered→wired (class/session/subscription/support_case/program/privacy_request vẫn **registered**).
- Không tạo projector mới (`admin_lookup_*` / `get_*_workspace` count bất biến).
- Không tạo authorization function (auth-slot = inline no-op, **không** `authorize_*` — permission system chưa tồn tại).
- Không tạo command dispatch / audit ledger / permission table.
- Không đụng: DTO `WorkspaceProjectionDTO/v1` · logger `admin_workspace_access_log` · registry 12 cột + 7 CHECK cũ · RLS · roles · `profiles.permissions[]` · Bunny · routes · tooling · **FE `be04f4b`**.

---

## 4. DDL DESIGN — `context_requirements` (DESIGN PLACEHOLDER)

```sql
-- ⚠ DESIGN PLACEHOLDER — KHÔNG apply. Minh họa boundary, chưa hardened final.

-- BLOCK 1 — column + declarative CHECK
ALTER TABLE public.mission_control_object_registry
  ADD COLUMN context_requirements jsonb NOT NULL
  DEFAULT '{"version":1,"keys":{},"allow_unknown":false}'::jsonb;

-- Schema-safety CHECK — subquery-free (CHECK không cho phép subquery),
-- declarative-only: đúng 3 top-level key, đúng primitive types.
ALTER TABLE public.mission_control_object_registry
  ADD CONSTRAINT mc_context_requirements_shape_chk CHECK (
        jsonb_typeof(context_requirements)                    = 'object'
    AND jsonb_typeof(context_requirements -> 'version')       = 'number'
    AND jsonb_typeof(context_requirements -> 'keys')          = 'object'
    AND jsonb_typeof(context_requirements -> 'allow_unknown') = 'boolean'
    -- reject MỌI top-level key lạ (table name / sql / function name …):
    -- sau khi bỏ 3 key hợp lệ phải còn '{}'.
    AND (context_requirements - 'version' - 'keys' - 'allow_unknown') = '{}'::jsonb
  );
```

**Ghi chú thiết kế:**

- CHECK chỉ đảm bảo **skeleton hợp lệ** của descriptor (declarative-only, 3 key, đúng type). Việc validate **shape của từng entry trong `keys`** (mỗi entry là `{type, required}`) yêu cầu iterate → subquery → **không** đặt trong CHECK được; thuộc trách nhiệm **validator** (§5).
- `jsonb_typeof(col -> 'k')` trả `NULL` khi thiếu key → biểu thức không TRUE → CHECK fail → **presence** được enforce ngầm, không cần `? 'k'` riêng.
- Toán tử `- 'k'` (jsonb minus key) cho phép reject unknown top-level key **không cần subquery** — chống chèn `table`, `sql`, `fn` vào descriptor.
- Descriptor mẫu (B3.1+ mới set, B3.0 để default):
  ```json
  { "version": 1,
    "keys": { "school_id": {"type":"uuid","required":true} },
    "allow_unknown": false }
  ```
  `type ∈ {uuid, text, int, bool}` (primitive-only). **Không** field executable (no `table`, `sql`, `predicate`, `fn`).

---

## 5. CONTEXT VALIDATOR DESIGN (DESIGN PLACEHOLDER)

### 5.1 Signature & contract

```sql
-- ⚠ DESIGN PLACEHOLDER
CREATE FUNCTION public.validate_mission_control_object_context(
    p_object_type text,
    p_context     jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
-- Output shape (structural verdict only):
--   { "valid": boolean,
--     "errors": [ "<code>", ... ],
--     "normalized_context": { ... } }
-- KHÔNG bao giờ trả authorization verdict.
$$;
```

### 5.2 Responsibility — ONLY structural

**Được phép:**
- đọc `mission_control_object_registry` (chỉ để lấy `context_requirements` của `p_object_type`);
- validate `p_context` là `object` (null → coi như `{}`);
- với mỗi key khai báo trong `keys`: nếu `required=true` → phải hiện diện; validate primitive type khớp `type`;
- nếu `allow_unknown=false` → reject mọi key trong `p_context` không nằm trong `keys`;
- normalize: strip whitespace, giữ đúng declared keys, canonical form → trả `normalized_context`.

**Cấm tuyệt đối (fail-closed nếu vi phạm concept):**
- ❌ đọc target object table · ❌ đọc `classes`/`sessions` · ❌ đọc memberships · ❌ đọc permissions · ❌ authorize user · ❌ dynamic SQL · ❌ đọc bất kỳ bảng nào ngoài registry.

### 5.3 Error codes (structural)

`context_not_object` · `context_missing_required_key` · `context_type_mismatch` · `context_unknown_key` · `context_requirements_malformed`.

Tất cả → adapter core map thành một verdict công khai `context_invalid` (fail-closed, không leak chi tiết descriptor ra client). Chi tiết `errors[]` chỉ để log/debug nội bộ.

### 5.4 Behaviour trên baseline B3.0

Vì **mọi** registry row ở B3.0 có `context_requirements = default` (`keys={}`, `allow_unknown=false`):
- context `{}` → **valid** (không required key, không unknown key) → **mọi wired object hiện tại pass y hệt trước** (regression-safe).
- context có key thừa (vd `{"x":1}`) → **invalid** (`context_unknown_key`) → fail-closed đúng thiết kế.

ACL: `{authenticated, postgres, service_role}` · 0 anon/0 PUBLIC. Validator an toàn để grant `authenticated` (chỉ trả verdict shape, registry là catalog phi-PII, không leak row data).

---

## 6. ADAPTER DESIGN (DESIGN PLACEHOLDER)

### 6.1 Shared internal gate core

```sql
-- ⚠ DESIGN PLACEHOLDER
CREATE FUNCTION public._mission_control_workspace_core(
    p_object_type text,
    p_object_id   uuid,
    p_context     jsonb,
    p_reason      text
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_ctx  jsonb;
  v_vres jsonb;
BEGIN
  -- 1 · AUTHENTICATE ------------------------------------------------
  --     is_admin gate  →  not_authorized (giữ nguyên B2.x)

  -- 2 · REGISTRY / OBJECT METADATA ---------------------------------
  --     load registry row (metadata-only, KHÔNG touch object)
  --     unknown_object_type → forbidden_object
  --     → not_available (registered) → scope_not_wired

  -- 3 · VALIDATE CONTEXT -------------------------------------------
  v_vres := public.validate_mission_control_object_context(
              p_object_type, coalesce(p_context, '{}'::jsonb));
  IF NOT (v_vres->>'valid')::boolean THEN
     RETURN jsonb_build_object('ok', false, 'error', 'context_invalid');
  END IF;
  v_ctx := v_vres->'normalized_context';

  -- 4 · CONTEXT AUTHORIZATION SLOT ─── B3.0 = NO-OP placeholder ─────
  --   ┌──────────────────────────────────────────────────────────┐
  --   │ B3.1 sẽ cắm: tenant authorization / class membership /     │
  --   │ assignment authorization — thao tác CHỈ trên v_ctx (đã     │
  --   │ validated + normalized ở bước 3) + registry metadata.      │
  --   │ CẤM: touch target object table để "discover then authorize"│
  --   │ B3.0: pass-through — không authorize, không deny.          │
  --   └──────────────────────────────────────────────────────────┘
  --   (B3.0 KHÔNG tạo authorize_* function — permission system
  --    chưa tồn tại.)

  -- 5 · PRIVACY / REASON -------------------------------------------
  --     reason_required gate  →  access-log write
  --     (thứ tự tương đối giữ nguyên B2.x: sau context, trước touch)

  -- 6 · TOUCH OBJECT / PROJECTOR -----------------------------------
  --     static CASE dispatch (KHÔNG dynamic SQL) → projector RPC
  --     → allowlist filter (discovery_fields)
  --     → forbidden-leak RAISE (forbidden_groups)
  --     → WorkspaceProjectionDTO/v1
END;
$$;
```

**Core ACL:** `{postgres, service_role}` · **0 anon · 0 authenticated · 0 PUBLIC** → core **không reachable trực tiếp qua PostgREST**; chỉ tới được qua 2 public overload (mỗi overload là secdef owner `postgres`, gọi core với quyền owner). Đây là security win phụ (§7.4).

### 6.2 Legacy 3-arg overload (thin wrapper)

```sql
-- ⚠ DESIGN PLACEHOLDER — external signature giữ nguyên B2.2
CREATE OR REPLACE FUNCTION public.get_object_workspace(
    p_object_type text,
    p_object_id   uuid,
    p_reason      text DEFAULT NULL
) RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT public._mission_control_workspace_core(
           p_object_type, p_object_id, '{}'::jsonb, p_reason);
$$;
```

Body đổi (monolith → wrapper) nhưng external contract bất biến: cùng tên, cùng arg names/types/defaults, cùng DTO. Legacy caller build context rỗng `{}` → hành vi platform-scope + school **y hệt** B2.2.

### 6.3 New 4-arg overload (thin wrapper, `p_context` REQUIRED)

```sql
-- ⚠ DESIGN PLACEHOLDER
CREATE FUNCTION public.get_object_workspace(
    p_object_type text,
    p_object_id   uuid,
    p_context     jsonb,            -- REQUIRED, KHÔNG DEFAULT (D-5)
    p_reason      text DEFAULT NULL
) RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT public._mission_control_workspace_core(
           p_object_type, p_object_id, p_context, p_reason);
$$;
```

`p_context` **không** có DEFAULT là ràng buộc cứng để loại overload ambiguity (§7.1).

---

## 7. SECURITY REVIEW

### 7.1 Overload ambiguity / PGRST203 — phân tích

Hai overload cùng tên: `(text,uuid,text)` và `(text,uuid,jsonb,text)`.

**Nguồn rủi ro nếu `p_context` CÓ default:** một named/positional call 3-tham-số `{type,id,reason}` sẽ khớp **cả hai** (4-arg với `p_context` defaulted) → Postgres "function is not unique" / PostgREST **PGRST203**.

**Vì `p_context` KHÔNG default (D-5):**

| Call shape | 3-arg match? | 4-arg match? | Resolve |
|---|---|---|---|
| named `{type,id,reason}` | ✅ | ❌ (thiếu `p_context` required) | **3-arg** |
| named `{type,id,context,reason}` | ❌ | ✅ | **4-arg** |
| named `{type,id,context}` | ❌ | ✅ (`p_reason` default) | **4-arg** |
| named `{type,id}` | ✅ (`p_reason` default) | ❌ (thiếu `p_context`) | **3-arg** |
| positional, arg3 = `text` | ✅ | ❌ | **3-arg** |
| positional, arg3 = `jsonb` | ❌ | ✅ | **4-arg** |

**Cảnh báo còn lại (raw SQL, không phải PostgREST):** positional với **untyped literal** ở arg3 (vd `get_object_workspace('x', uuid, 'y')` không cast) có thể coi `'y'` là text **hoặc** jsonb → ambiguous ở SQL level. **Không** ảnh hưởng PostgREST (params đến kèm tên + type từ JSON body). Mitigation: verification plan (§8) bắt buộc test cả named path (PostgREST) **và** positional-typed; tài liệu callsite yêu cầu cast tường minh (`::text` / `::jsonb`) nếu gọi raw SQL.

### 7.2 Lookup-first prohibition (D-4)

Object row chỉ bị chạm ở **bước 6** (projector) — **sau** validate (3) và auth-slot (4). B3.1 authorize từ `v_ctx` (caller khai báo, đã validate), **không** từ dữ liệu discover bằng cách touch object. Pattern cấm `touch → discover tenant → authorize` **không thể phát sinh** vì auth-slot đứng trước touch và bị hợp đồng cấm đọc object table.

### 7.3 Declarative-only metadata

`context_requirements` bị CHECK khóa xuống đúng 3 top-level key primitive → **không** thể chèn table name / SQL predicate / function name / dynamic dispatch. Dispatch vẫn sống ở **adapter CASE tĩnh** (như D349 COMMENT chốt), không di trú vào data.

### 7.4 Blast-radius & ACL

- Core `_mission_control_workspace_core` internal-only (0 client role) → giảm attack surface: client chỉ thấy 2 overload đã kiểm soát.
- Validator secdef nhưng chỉ trả verdict shape → không leak registry row / object data.
- Mọi function mới: `search_path=''` (chống search-path hijack), no dynamic SQL, ACL re-hardened sau CREATE/REPLACE (D15: `proacl` reset khi REPLACE) + `REVOKE ... FROM PUBLIC, anon, authenticated` (D231 auto-grant guard) + `NOTIFY pgrst` (D289).
- **Privacy moat B2.x bất biến:** allowlist theo `discovery_fields` + forbidden-leak guard theo `forbidden_groups` vẫn ở bước 6, không đổi.

### 7.5 Fail-closed posture

- Context invalid → `context_invalid`, **không** touch object.
- `validate_...` lỗi bất ngờ → core coi như invalid (fail-closed), không fall-through sang dispatch.
- Auth-slot no-op **pass-through** (không cấp quyền mới, không chặn) → B3.0 không nới rộng quyền so với B2.2.

---

## 8. VERIFICATION PLAN (DESIGN — thực thi khi Owner authorize apply)

### 8.1 In-transaction structural VERIFY (BLOCK 3, RAISE-on-fail, atomic rollback — D92)

1. Column `context_requirements` tồn tại · type `jsonb` · NOT NULL · default khớp byte.
2. CHECK `mc_context_requirements_shape_chk` present; savepoint-insert một descriptor xấu (vd `{"version":1,"keys":{},"allow_unknown":false,"table":"x"}`) → **phải** raise (rồi rollback savepoint).
3. Cả **17** registry row có `context_requirements = default` (backfill toàn vẹn).
4. `validate_mission_control_object_context` exists · secdef · `search_path=''` · **no dynamic SQL** (`pg_get_functiondef` không chứa `EXECUTE`).
5. `_mission_control_workspace_core` exists · secdef · `search_path=''` · ACL: **0 anon · 0 authenticated · 0 PUBLIC** (internal-only) — `aclexplode(coalesce(proacl, acldefault('f', proowner)))`.
6. Cả 2 overload exist (arg3 `text` vs `jsonb`) · secdef · `search_path=''` · ACL 0 anon/0 PUBLIC.
7. 4-arg `p_context` **NO default** — kiểm `pg_proc.proargdefaults` / `pg_get_function_arguments` (không có `DEFAULT` ở `p_context`).
8. DTO marker `WorkspaceProjectionDTO/v1` xuất hiện trong core (contract unchanged).
9. Registry state bất biến: **5 wired / 6 registered / 6 forbidden**; `class` + `session` vẫn `registered`; **không** row nào registered→wired.
10. Projector count bất biến (không `admin_lookup_*` / `get_*_workspace` mới).

### 8.2 Overload resolution VERIFY (must be NO PGRST203)

- `NOTIFY pgrst, 'reload schema'` → probe schema cache.
- Named: `{type,id,reason}`→3-arg · `{type,id,context,reason}`→4-arg · `{type,id,context}`→4-arg · `{type,id}`→3-arg. **Kỳ vọng: không "function is not unique" / không PGRST203.**
- Positional-typed: arg3 `::text`→3-arg · arg3 `::jsonb`→4-arg.

### 8.3 Post-commit functional VERIFY (impersonation, rollback-safe — JWT `sub` + `SET LOCAL ROLE authenticated`)

- **Regression legacy 3-arg** trên từng wired object (child/media/person/capsule/school) → DTO **byte-identical** so với B2.2 (fields ⊆ discovery, capabilities, reason_logged, forbidden-groups guard giữ nguyên).
- **4-arg `{}`** trên các wired object → **identical** với legacy 3-arg (empty context pass).
- **4-arg extra-key** (vd `{"x":1}`) trên object `keys={}`+`allow_unknown=false` → `context_invalid` (validator reject, object **không** bị touch).
- **Validator trực tiếp:** `{}` + empty keys → valid · `{"x":1}` + `allow_unknown=false` → invalid(`context_unknown_key`) · (future-shape) required key thiếu → invalid · type sai → invalid.
- **Auth-slot no-op:** context hợp lệ **không** cấp thêm quyền, **không** chặn (chỉ pass-through) — verdict cuối do các gate hiện có quyết định.
- **Non-admin** (unknown `sub`) → `not_authorized` (cả 2 overload).
- **Reason/access-log** child/capsule: `reason_required` vẫn fire; access-log ghi **sau** validate-context (thứ tự mới), zero residue sau rollback.
- **Inventory delta:** functions **235 → 238** (+3), secdef **224 → 227** (+3), tables 90 (unchanged), policies 166 (unchanged), triggers 33 (unchanged), cron 1 (unchanged). Column +1 trên registry, CHECK +1.

---

## 9. ROLLBACK PLAN (DESIGN PLACEHOLDER)

```sql
-- ⚠ DESIGN PLACEHOLDER — additive undo về đúng tip B2.2 (tail 20260811080037)
DROP FUNCTION IF EXISTS public.get_object_workspace(text, uuid, jsonb, text);   -- new 4-arg
DROP FUNCTION IF EXISTS public._mission_control_workspace_core(text, uuid, jsonb, text);
DROP FUNCTION IF EXISTS public.validate_mission_control_object_context(text, jsonb);

-- restore legacy get_object_workspace(text,uuid,text) về monolith body B2.2
--   (nguồn: HANDOFF V128-B2.2 §C BLOCK 1b — scope gate tenant-widen + CASE school)
CREATE OR REPLACE FUNCTION public.get_object_workspace(text, uuid, text) ...;   -- B2.2 body

ALTER TABLE public.mission_control_object_registry
  DROP CONSTRAINT IF EXISTS mc_context_requirements_shape_chk;
ALTER TABLE public.mission_control_object_registry
  DROP COLUMN IF EXISTS context_requirements;

NOTIFY pgrst, 'reload schema';
```

**Đảm bảo:** rollback đưa về **chính xác** B2.2 tip. Không đụng: DTO, registry 17 rows (giá trị business), 5 projector, logger, RLS, roles, FE. Registry table + 12 cột cũ + 7 CHECK cũ nguyên vẹn (chỉ bỏ cột/CHECK mới thêm).

---

## 10. OWNER GATE CHECKLIST

Cần Owner (CPO/CTO release authority) ratify **từng** mục trước khi B3.0 chuyển sang APPLY:

- [ ] **OG-1 · Adapter refactor:** đồng ý `get_object_workspace(text,uuid,text)` đổi body monolith → thin wrapper (không byte-identical), external contract + DTO + ACL giữ nguyên.
- [ ] **OG-2 · New public RPC surface:** đồng ý thêm overload `get_object_workspace(text,uuid,jsonb,text)`, `p_context` required no-default.
- [ ] **OG-3 · Registry schema change:** đồng ý `+context_requirements jsonb NOT NULL` + CHECK `mc_context_requirements_shape_chk` trên bảng MC core; backfill 17 rows = default.
- [ ] **OG-4 · New functions:** đồng ý +validator +core (Δ functions +3, projector +0); core internal-only ACL.
- [ ] **OG-5 · Security ordering freeze:** đồng ý canonical order `authenticate → metadata → validate context → auth-slot(no-op) → privacy/reason → touch`; auth-slot là lỗ chờ B3.1, **không** tạo `authorize_*` ở B3.0.
- [ ] **OG-6 · Foundation-only guarantee:** xác nhận B3.0 **không** set `context_requirements` của bất kỳ object ≠ default, **không** wire object, class/session vẫn `registered`, DTO/RLS/role/FE/logger bất biến.

Sau khi cả 6 mục ratify → mới mở phiên APPLY riêng (precheck D1 → migration D92 3-block → verify §8 → canonicalize D352+/SYSTEM_MAP v1.40+/HANDOFF V128-B3.0).

---

## 11. FOUNDATION-ONLY PROOF

Chứng minh B3.0 vẫn **foundation-only** theo Final Quality Bar:

| Bar | Trạng thái B3.0 | Bằng chứng |
|---|---|---|
| B3.0 foundation-only | ✅ | Chỉ tạo Context Contract Layer (§3.1); không set requirements ≠ default → 0 object đổi behavior. |
| `class` vẫn registered | ✅ | §3.2 freeze; VERIFY §8.1-9; không wire. |
| `session` vẫn registered | ✅ | §3.2 freeze; VERIFY §8.1-9; không wire. |
| projector không tăng | ✅ | §3.1 Δ = +validator +core +overload; **0** projector; VERIFY §8.1-10. |
| command system chưa tồn tại | ✅ | Không command dispatch trong scope (§3.2). |
| permission system chưa tồn tại | ✅ | Auth-slot = inline no-op; **không** `authorize_*`, **không** permission table (§6.1, OG-5). |
| audit ledger chưa tồn tại | ✅ | Không tạo ledger; logger `admin_workspace_access_log` không đụng (§3.2). |
| RLS unchanged | ✅ | Không policy nào thêm/sửa; policies 166 bất biến (§8.3 inventory). |
| role unchanged | ✅ | Không đụng roles / `profiles.permissions[]` (§3.2). |
| frontend unchanged | ✅ | FE HEAD `be04f4b` BẤT BIẾN; backend-only; DTO `WorkspaceProjectionDTO/v1` không bump. |

**Regression-safety:** vì mọi registry row = default `keys={}`, legacy 3-arg (context `{}`) + 4-arg `{}` cho **mọi wired object hiện tại** trả DTO byte-identical B2.2 → seam trong suốt với hành vi đang chạy.

---

# V128-B3.0 FINAL APPLY PACKAGE v2

**Status:**
**DESIGN READY FOR OWNER AUTHORIZATION**

Không tự động chuyển sang build. Chờ ratify OG-1…OG-6 (§10) → mở phiên APPLY riêng.
