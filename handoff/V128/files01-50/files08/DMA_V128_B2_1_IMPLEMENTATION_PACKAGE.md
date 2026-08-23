# 🛰️ DMA V128-B2.1 — MISSION CONTROL WORKSPACE ADAPTER · IMPLEMENTATION PACKAGE

> **⚠️ DRAFT · DESIGN ONLY · DO NOT APPLY · DO NOT DEPLOY.** Không `apply_migration`, không code, không migration. Package thiết kế để Owner review/authorize.
> **Adapter:** `get_object_workspace(p_object_type text, p_object_id uuid, p_reason text)`
> **Scope B2.1:** wired objects `person`, `child`, `media`, `capsule` (tất cả scope=platform).
> **Baseline:** post V128-B2.0 · migration tail `20260810150209` · FE HEAD `be04f4b` · registry live (17 rows).
> **Pre-flight verdict kế thừa:** `READY — WITH BINDING ADAPTER CONTRACT`. Package này hiện thực hoá §5 contract.

---

## 1. ARCHITECTURE DECISION

**AD1 — Platform-scoped adapter (Mission Control = `/admin`).** Gate `public.is_admin()`. Cả 4 wired type đều `scope='platform'` → dispatch tới `admin_lookup_*`. Path tenant (`get_person_workspace`) **KHÔNG** dùng ở B2.1: adapter không có `school_id` param và không type tenant nào được wired ở B2.0. Tenant Mission Control = **B2.2** (khi `school` scope wired).

**AD2 — Static CASE dispatch, zero DB dispatch-string (D349.2).** `object_type → (projector name + identity sub-object path)` **hardcode trong CASE**. Registry KHÔNG lưu tên hàm/tên sub-object — chỉ giữ dữ liệu khai báo (`discovery_fields`, `forbidden_groups`, `capability_vocab`, `scope`, `privacy_policy`). Cấm `EXECUTE format`, cấm dynamic SQL.

**AD3 — Allowlist bằng cấu trúc + filter registry-driven.** Mỗi branch chọn **identity sub-object** của projector; rồi một biểu thức generic giữ **chỉ** key ∈ `discovery_fields`. Hai leak-guard (allowlist assertion + forbidden_groups check) = defense-in-depth. Projector output thô KHÔNG BAO GIỜ trả thẳng.

**AD4 — Reason gate registry-driven.** `v_needs_reason := privacy_policy IN ('reason_required','restricted')` → child (reason_required) + capsule (restricted). Reason bắt buộc + log qua `admin_workspace_access_log` **sau** khi gate pass, **trước** khi return (D345.2). ★ *Owner có thể hạ capsule xuống open nếu muốn — logic registry-driven nên chỉ cần đổi `privacy_policy` trong registry, không sửa code.*

**AD5 — Nested SECURITY DEFINER an toàn.** Adapter (owner postgres, DEFINER) gọi projector (owner postgres, DEFINER): `auth.uid()` (JWT sub) **được bảo toàn** qua nested DEFINER — chỉ execution-role đổi, không đổi identity. `is_admin()` bên trong projector thấy đúng caller thật. Adapter **tự re-gate** độc lập, KHÔNG tin projector gate hộ → 0 escalation.

**AD6 — Fail-closed toàn diện.** unknown type → `unknown_object_type` · forbidden/none → `forbidden_object` · registered → `not_available` · scope≠platform → `scope_not_wired` · wired-nhưng-thiếu-branch → `dispatch_missing` · projector `ok=false` → propagate. Không path nào "mở mặc định".

**AD7 — `capability_vocab` = khai báo, không thực thi.** Adapter surface `capability_vocab` (map action→permission string) để FE render nút có gate theo quyền caller. Adapter **không** thực thi action nào (read-only projector).

---

## 2. SQL DRAFT (⚠️ DO NOT EXECUTE)

```sql
-- ═══════════════════════════════════════════════════════════════════
-- V128-B2.1 · get_object_workspace — Mission Control workspace adapter
-- DRAFT — DO NOT APPLY. Platform-scoped, wired: person/child/media/capsule.
-- ═══════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.get_object_workspace(
  p_object_type text,
  p_object_id   uuid,
  p_reason      text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''                                   -- strict pin (D-canonical)
AS $function$
DECLARE
  r_reg    public.mission_control_object_registry%ROWTYPE;
  v_raw    jsonb;                                       -- full projector output
  v_source jsonb;                                       -- identity sub-object
  v_fields jsonb;                                       -- allowlisted output
  v_bad    text;
  v_needs_reason boolean;
BEGIN
  ------------------------------------------------------------------ GATE 1
  IF NOT public.is_admin() THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_authorized');
  END IF;

  ------------------------------------------------------ registry (declarative)
  SELECT * INTO r_reg
  FROM public.mission_control_object_registry
  WHERE object_type = p_object_type;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'unknown_object_type',
                              'object_type', p_object_type);
  END IF;

  ------------------------------------------------------ forbidden / registered
  IF r_reg.kind = 'forbidden' OR r_reg.projector_status = 'none' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'forbidden_object',
                              'object_type', p_object_type);
  END IF;

  IF r_reg.projector_status = 'registered' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_available',
             'object_type', p_object_type, 'projector_status', 'registered');
  END IF;

  ------------------------------------------------------ scope guard (B2.1)
  IF r_reg.scope IS DISTINCT FROM 'platform' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'scope_not_wired',
             'object_type', p_object_type, 'scope', r_reg.scope);
  END IF;

  ------------------------------------------------------ GATE 2: reason
  v_needs_reason := r_reg.privacy_policy IN ('reason_required','restricted');
  IF v_needs_reason AND (p_reason IS NULL OR btrim(p_reason) = '') THEN
    RETURN jsonb_build_object('ok', false, 'error', 'reason_required',
             'object_type', p_object_type, 'privacy_policy', r_reg.privacy_policy);
  END IF;

  ------------------------------------------------------ STATIC CASE DISPATCH
  CASE p_object_type
    WHEN 'person' THEN
      v_raw := public.admin_lookup_user(p_object_id);    v_source := v_raw -> 'profile';
    WHEN 'child' THEN
      v_raw := public.admin_lookup_child(p_object_id);   v_source := v_raw -> 'child';
    WHEN 'media' THEN
      v_raw := public.admin_lookup_media(p_object_id);   v_source := v_raw -> 'media';
    WHEN 'capsule' THEN
      v_raw := public.admin_lookup_capsule(p_object_id); v_source := v_raw -> 'capsule';
    ELSE
      RETURN jsonb_build_object('ok', false, 'error', 'dispatch_missing',
                                'object_type', p_object_type);
  END CASE;

  ------------------------------------------------------ projector error passthrough
  IF v_raw IS NULL OR NOT COALESCE((v_raw->>'ok')::boolean, false) THEN
    RETURN jsonb_build_object('ok', false,
             'error', COALESCE(v_raw->>'error','projector_error'),
             'object_type', p_object_type);
  END IF;

  ------------------------------------------------------ ALLOWLIST FILTER
  --  keep ONLY keys ∈ discovery_fields (registry-driven, generic)
  v_fields := COALESCE((
    SELECT jsonb_object_agg(key, value)
    FROM jsonb_each(COALESCE(v_source, '{}'::jsonb))
    WHERE key = ANY (r_reg.discovery_fields)
  ), '{}'::jsonb);

  ------------------------------------------------------ LEAK GUARD 1 (allowlist)
  SELECT string_agg(k, ',') INTO v_bad
  FROM jsonb_object_keys(v_fields) AS k
  WHERE NOT (k = ANY (r_reg.discovery_fields));
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'ADAPTER_ALLOWLIST_VIOLATION: % not in discovery_fields', v_bad;
  END IF;

  ------------------------------------------------------ LEAK GUARD 2 (forbidden)
  IF EXISTS (SELECT 1 FROM jsonb_object_keys(v_fields) AS k
             WHERE k = ANY (r_reg.forbidden_groups)) THEN
    RAISE EXCEPTION 'ADAPTER_FORBIDDEN_LEAK: forbidden group surfaced';
  END IF;

  ------------------------------------------------------ reason-log (D345.2)
  IF v_needs_reason THEN
    PERFORM public.admin_workspace_access_log(p_object_type, p_object_id, p_reason);
  END IF;

  ------------------------------------------------------ ObjectWorkspaceModel
  RETURN jsonb_build_object(
    'ok',            true,
    'object_type',   p_object_type,
    'object_id',     p_object_id,
    'kind',          r_reg.kind,
    'scope',         r_reg.scope,
    'privacy_policy',r_reg.privacy_policy,
    'fields',        v_fields,                 -- allowlisted identity ONLY
    'capabilities',  r_reg.capability_vocab,   -- declarative action→permission
    'reason_logged', v_needs_reason
  );
END
$function$;
```

**BLOCK 2 — ACL (§6)** và **BLOCK 3 — VERIFY** ở mục 6 & 7. `search_path=''` an toàn: mọi ref schema-qualified; built-in (`jsonb_*`, `btrim`, `coalesce`, `string_agg`) ở `pg_catalog` luôn implicit. Projector gọi qua `public.*` chạy với `search_path` riêng của chúng (`public`) nên unqualified nội bộ vẫn resolve.

---

## 3. CASE DISPATCH DESIGN

```
p_object_type ──► CASE (static, code-owned) ──► projector RPC + identity sub-object path
```

- **Không** bảng dispatch trong DB · **không** `EXECUTE format` · **không** tên hàm lưu registry.
- Dispatch string (tên projector + sub-object key) sống **duy nhất** trong CASE literal → code-review được, injection-free (D349.2).
- Wired-trong-registry nhưng thiếu branch code → `dispatch_missing` (fail-closed, không im lặng).
- Thêm object mới = thêm 1 WHEN branch (code review) + set `projector_status='wired'` trong registry (migration). Hai lớp phải khớp.

---

## 4. ADAPTER MAPPING

| object_type | scope | privacy_policy | projector (platform) | identity sub-object | output `fields` (= discovery_fields) | reason? | dropped by allowlist (ví dụ) |
|---|---|---|---|---|---|---|---|
| `person` | platform | open | `admin_lookup_user` | `profile` | `full_name, email, role, state` | no | **permissions**, phone, school_id, children, teaching, recent_audit |
| `child` | platform | reason_required | `admin_lookup_child` | `child` | `full_name, nickname, state` | **YES** | journal_summary, evidence, readiness, capsules, parent_memory, memory_conversation, parents, consents, media_counts |
| `media` | platform | open | `admin_lookup_media` | `media` | `file_type, state` | no | linked_child(name), moment/caption, consent_state, storage_zone, uploader |
| `capsule` | platform | restricted | `admin_lookup_capsule` | `capsule` | `scope, domain, window_code` | **YES** | **items[]**, child(name), payload_hash, discovery_version, readiness_policy_version |

> Mọi field "dropped" bị loại **bằng allowlist** (không có trong `discovery_fields`), không phải blacklist. `child memory / journal / capsule.items / raw media / signed URL / bytes / family memory` không nằm trong bất kỳ identity sub-object nào → không bao giờ chạm tới.

---

## 5. SECURITY REVIEW (đối chiếu yêu cầu)

| Yêu cầu | Cách thoả trong draft |
|---|---|
| 1. SECURITY DEFINER | `SECURITY DEFINER`, owner sẽ là `postgres` (như projector) |
| 2. pinned search_path | `SET search_path = ''` (strict nhất), mọi ref qualified |
| 3. internal authorization gate | GATE 1 `public.is_admin()` → `not_authorized`; adapter tự re-gate độc lập (AD5) |
| 4. scope routing | Đọc `r_reg.scope`; B2.1 chỉ dispatch `scope='platform'`; khác → `scope_not_wired` (hook tenant B2.2) |
| 5. child reason gate | GATE 2 `privacy_policy IN (reason_required,restricted)` → reason bắt buộc, else `reason_required` |
| 6. `admin_workspace_access_log` integration | `PERFORM public.admin_workspace_access_log(type,id,reason)` sau gate, trước return, chỉ khi `v_needs_reason` |
| **Privacy: projector→allowlist→Model** | Allowlist filter registry-driven (`key = ANY(discovery_fields)`) + 2 leak-guard; identity sub-object per-branch; **never passthrough** |
| No dynamic SQL / EXECUTE / registry exec-string | Static CASE; 0 `EXECUTE`; registry chỉ dữ liệu khai báo |

**Nested DEFINER + is_admin:** `auth.uid()` bảo toàn → projector `is_admin()` thấy caller thật; adapter đã gate nên inner luôn pass cho admin; non-admin bị chặn tại GATE 1 (không tới projector). **0 privilege escalation.**

**Leak matrix (chứng minh không rò):**
- `child`: `v_source=v_raw->'child'` chỉ có {id,full_name,nickname,state,created_at}; forbidden groups (journal_summary…) ở **top-level** `v_raw`, adapter **không đọc** top-level → 0 rò. Allowlist giữ {full_name,nickname,state}.
- `capsule`: `items` ở top-level `v_raw`, `v_source=v_raw->'capsule'` **không chứa** items → allowlist giữ {scope,domain,window_code}, items **bất khả đạt**.
- `media`: không projector nào emit signed_url/bytes (audit B2.1 §2); allowlist giữ {file_type,state}.
- `person`: `permissions` bị allowlist loại (không ∈ discovery_fields) → quyền không rò ra object view.

---

## 6. ACL PLAN (§ D15 / D231 — cho migration tương lai)

```sql
-- BLOCK 2 (trong migration tương lai)
REVOKE ALL ON FUNCTION public.get_object_workspace(text, uuid, text)
  FROM PUBLIC, anon, authenticated, service_role;         -- xoá auto-grant D231
GRANT EXECUTE ON FUNCTION public.get_object_workspace(text, uuid, text)
  TO authenticated, service_role;                          -- KHÔNG anon
NOTIFY pgrst, 'reload schema';                             -- D289
```
ACL đích: `{authenticated, postgres, service_role}` EXECUTE · **0 anon · 0 PUBLIC** — khớp posture projector. Verify bằng `aclexplode`.

---

## 7. VERIFICATION QUERIES (design — chạy trong VERIFY block / post-apply, rollback-safe)

**Structural (read-only):**
```sql
SELECT p.prosecdef,                              -- true
       pg_get_userbyid(p.proowner),              -- postgres
       p.proconfig,                              -- {search_path=""}
       (SELECT array_agg((CASE WHEN a.grantee=0 THEN 'PUBLIC'
              ELSE pg_get_userbyid(a.grantee) END)||':'||a.privilege_type)
        FROM aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a) AS acl
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public' AND p.proname='get_object_workspace';
-- PASS: secdef=true · owner=postgres · search_path='' · acl không chứa anon/PUBLIC
```

**Functional (impersonate admin; mutation-safe DO block):**
```sql
-- Cần: v_admin = profiles.user_id của 1 admin; các UUID object thật từ pilot.
DO $t$
DECLARE v_admin uuid := '<ADMIN_user_id>';
        v_child uuid := '<CHILD_id>'; v_caps uuid := '<CAPSULE_id>';
        v_media uuid := '<MEDIA_id>'; v_person uuid := '<PROFILE_id>';
        r jsonb; msg text := '';
BEGIN
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_admin,'role','authenticated')::text, true);
  SET LOCAL ROLE authenticated;

  -- child: chỉ {full_name,nickname,state}; reason_logged=true; KHÔNG forbidden key
  r := public.get_object_workspace('child', v_child, 'B2.1 verify');
  IF (SELECT bool_or(k NOT IN ('full_name','nickname','state'))
      FROM jsonb_object_keys(r->'fields') k) THEN
    RAISE EXCEPTION 'CHILD_LEAK: %', r->'fields'; END IF;
  IF r ? 'journal_summary' OR (r->'fields') ?| ARRAY['evidence','capsules','parent_memory']
     THEN RAISE EXCEPTION 'CHILD_FORBIDDEN_LEAK'; END IF;
  msg := msg || 'child_ok ';

  -- child KHÔNG reason → reason_required
  r := public.get_object_workspace('child', v_child, NULL);
  IF r->>'error' <> 'reason_required' THEN RAISE EXCEPTION 'CHILD_REASON_GATE_FAIL'; END IF;

  -- capsule: {scope,domain,window_code}; KHÔNG items
  r := public.get_object_workspace('capsule', v_caps, 'verify');
  IF (r->'fields') ? 'items' OR r ? 'items' THEN RAISE EXCEPTION 'CAPSULE_ITEMS_LEAK'; END IF;
  msg := msg || 'capsule_ok ';

  -- media: {file_type,state}; KHÔNG linked_child
  r := public.get_object_workspace('media', v_media, NULL);
  IF (r->'fields') ? 'linked_child' THEN RAISE EXCEPTION 'MEDIA_LEAK'; END IF;
  msg := msg || 'media_ok ';

  -- person: KHÔNG permissions
  r := public.get_object_workspace('person', v_person, NULL);
  IF (r->'fields') ? 'permissions' THEN RAISE EXCEPTION 'PERSON_PERMS_LEAK'; END IF;
  msg := msg || 'person_ok ';

  -- forbidden → forbidden_object
  r := public.get_object_workspace('journal', v_child, 'x');
  IF r->>'error' <> 'forbidden_object' THEN RAISE EXCEPTION 'FORBIDDEN_FAIL'; END IF;

  -- registered → not_available
  r := public.get_object_workspace('school', v_person, NULL);
  IF r->>'error' <> 'not_available' THEN RAISE EXCEPTION 'REGISTERED_FAIL'; END IF;

  RAISE EXCEPTION 'ROLLBACK_OK: %', msg;   -- rollback sạch, surface evidence
END $t$;
-- Kỳ vọng: ROLLBACK_OK: child_ok capsule_ok media_ok person_ok
```

**Non-admin test:** impersonate 1 profile không phải admin → `get_object_workspace('person',…)` phải trả `not_authorized`.

**Verify item bổ sung:** xác nhận `admin_workspace_access_log` chấp nhận `entity_type='capsule'` (writer có thể validate entity_type — nếu chỉ nhận 'child', capsule reason-log cần điều chỉnh hoặc capsule set về `open`).

---

## 8. ROLLBACK PLAN

```sql
DROP FUNCTION IF EXISTS public.get_object_workspace(text, uuid, text);
NOTIFY pgrst, 'reload schema';
```
Additive tuyệt đối (hàm mới) · 0 sửa object hiện hữu · 0 registry change · 0 projector change. Baseline về `be04f4b` / tail `20260810150209`. Migration tương lai transactional: RAISE trong VERIFY → rollback nguyên tử, không ghi `schema_migrations`.

---

## 9. OPEN ITEMS trước khi authorize apply

1. **`admin_workspace_access_log` entity_type='capsule'** — verify writer chấp nhận (hoặc set capsule `open`).
2. **capsule reason policy** — Owner quyết: giữ `restricted`(reason bắt buộc) hay hạ `open`. Registry-driven, đổi data không đổi code.
3. **B2.0 canonicalization** (D349/v1.37) vẫn treo — nên đóng trước khi mở D350/B2.1 canonical.
4. **Migration tương lai** = 3-block (DDL adapter → ACL → VERIFY), tự-áp CHỈ khi Owner authorize.

*Endpoint dự kiến sau khi build+canonicalize B2.1: RULES **D350** · SYSTEM_MAP **v1.38** · HANDOFF **V128-B2.1**.*

**STOP — design package only. Không apply, không code, không deploy.**
