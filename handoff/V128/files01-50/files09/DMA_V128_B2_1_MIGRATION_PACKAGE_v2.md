# 🛰️ DMA V128-B2.1 — MISSION CONTROL WORKSPACE ADAPTER · MIGRATION PACKAGE **v2**

> **⚠️ DRAFT · DESIGN ONLY · DO NOT APPLY · DO NOT DEPLOY.** No `apply_migration`, no code, no deploy.
> **CTO review:** Architecture APPROVED · Migration NOT YET AUTHORIZED. v2 applies required fixes A/B/C.
> **Baseline:** post V128-B2.0 · tail `20260810150209` · FE HEAD `be04f4b` · registry live (17 rows).
> **Invariants kept:** static CASE dispatch · allowlist-first · registry non-executable · child reason gate.

---

## 0. CTO FIX RESOLUTION

### FIX A — capsule reason policy (do NOT silently weaken)

**Forensic finding (live body read):** `admin_workspace_access_log(p_entity_type,…)` rejects `p_entity_type NOT IN ('child','parent')` → returns `invalid_entity_type`, writes nothing. Its action-CASE only maps `child`/`parent`. **Consequence:** v1's `PERFORM admin_workspace_access_log('capsule',…)` discards the failure → capsule access unlogged despite `restricted` gate = silent weakening. **Rejected.**

**Resolution (two independent controls):**
1. **Fail-closed logging** (adapter): logging runs **before** the projector read; if it returns `ok=false`, the adapter returns `access_log_failed` and reads/returns nothing. No access without a committed audit intent.
2. **★ Extend the logger additively** to accept `capsule` → new action `ADMIN_OPEN_CAPSULE_WORKSPACE`, reason mandatory, `child`/`parent` behavior preserved byte-identical. Handles school-scope capsules (no `child_id` dependency); precise, auditable.

**Alternatives (documented, not chosen):**
- **A2 — route capsule log via `child_id`** (`admin_workspace_access_log('child', capsule.child_id, reason)`): no logger change, but **fails for school-scope capsules** (no child_id) and mislabels action as child-open. Rejected for correctness.
- **A3 — set capsule `privacy_policy='open'`** (registry data change, drops reason gate): an **overt** Owner tradeoff, not silent — offered only if Owner explicitly accepts reduced capsule privacy. **Not recommended.**

### FIX B — backend DTO ≠ frontend Model

Adapter returns **`WorkspaceProjectionDTO`** — a **UI-agnostic** contract: identity `fields` (allowlisted), registry semantics (`kind`/`scope`/`privacy_policy`/`projector_status`), authz `capabilities` (action→permission map), `reason_logged`. **Zero UI concepts** — no bands, sections, ordering, labels, i18n, or display hints. The frontend owns a separate mapping layer `WorkspaceProjectionDTO → ObjectWorkspaceModel` (bands/sections/labels). **Backend never knows UI bands.**

### FIX C — split verification

- **(I) Transactional (in-migration BLOCK 3):** deterministic structural/logic assertions runnable as `postgres` with null `auth.uid()` — existence, secdef, owner, pinned search_path, ACL (no anon/PUBLIC), no dynamic SQL, logger capsule-support + child/parent regression guard, wired-set matches CASE branches. RAISE → atomic rollback.
- **(II) Post-commit external:** functional/privacy tests needing admin impersonation + real pilot UUIDs (leak checks, reason gate, capsule-items, forbidden/registered/non-admin, capsule audit-row written). Run via `execute_sql` after commit, rollback-safe DO block. **Cannot** run in-migration (auth-gated).

---

## 1. SQL DRAFT (⚠️ DO NOT EXECUTE)

### BLOCK 1a — extend logger (additive; child/parent preserved)

```sql
CREATE OR REPLACE FUNCTION public.admin_workspace_access_log(
  p_entity_type text, p_entity_id uuid, p_reason text DEFAULT NULL::text
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
declare v_action text; v_actor uuid;
begin
  if not public.is_admin() then return jsonb_build_object('ok',false,'error','not_admin'); end if;
  if p_entity_type not in ('child','parent','capsule') then            -- +capsule
    return jsonb_build_object('ok',false,'error','invalid_entity_type'); end if;
  if p_entity_id is null then return jsonb_build_object('ok',false,'error','entity_id_required'); end if;
  if p_entity_type in ('child','capsule')                              -- +capsule reason-required
     and (p_reason is null or length(btrim(p_reason)) = 0) then
    return jsonb_build_object('ok',false,'error','reason_required'); end if;

  v_actor := public.current_profile();
  v_action := case p_entity_type
                when 'child'   then 'ADMIN_OPEN_CHILD_WORKSPACE'
                when 'parent'  then 'ADMIN_OPEN_PARENT_WORKSPACE'
                when 'capsule' then 'ADMIN_OPEN_CAPSULE_WORKSPACE'     -- +capsule
              end;
  perform public.write_audit_log(v_action, jsonb_build_object(
    'actor_id', v_actor, 'entity_type', p_entity_type, 'entity_id', p_entity_id,
    'child_id', case when p_entity_type='child' then p_entity_id else null end,
    'reason', nullif(btrim(p_reason),'')));
  return jsonb_build_object('ok', true, 'logged', v_action);
end;
$function$;
```
*Delta = 3 additive lines (capsule in allow-set, reason-required set, action map). `child`/`parent` paths unchanged. `CREATE OR REPLACE` preserves existing ACL; re-verified in BLOCK 3.*

### BLOCK 1b — adapter (returns WorkspaceProjectionDTO)

```sql
CREATE OR REPLACE FUNCTION public.get_object_workspace(
  p_object_type text, p_object_id uuid, p_reason text DEFAULT NULL
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  r_reg    public.mission_control_object_registry%ROWTYPE;
  v_raw    jsonb; v_source jsonb; v_fields jsonb; v_bad text;
  v_needs_reason boolean; v_log jsonb;
BEGIN
  ----------------------------------------------------------------- GATE 1
  IF NOT public.is_admin() THEN
    RETURN jsonb_build_object('ok',false,'error','not_authorized'); END IF;

  ------------------------------------------------- registry (declarative)
  SELECT * INTO r_reg FROM public.mission_control_object_registry
   WHERE object_type = p_object_type;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok',false,'error','unknown_object_type','object_type',p_object_type); END IF;

  ------------------------------------------------- forbidden / registered / scope
  IF r_reg.kind='forbidden' OR r_reg.projector_status='none' THEN
    RETURN jsonb_build_object('ok',false,'error','forbidden_object','object_type',p_object_type); END IF;
  IF r_reg.projector_status='registered' THEN
    RETURN jsonb_build_object('ok',false,'error','not_available',
             'object_type',p_object_type,'projector_status','registered'); END IF;
  IF r_reg.scope IS DISTINCT FROM 'platform' THEN
    RETURN jsonb_build_object('ok',false,'error','scope_not_wired',
             'object_type',p_object_type,'scope',r_reg.scope); END IF;

  ------------------------------------------------- GATE 2: reason
  v_needs_reason := r_reg.privacy_policy IN ('reason_required','restricted');
  IF v_needs_reason AND (p_reason IS NULL OR btrim(p_reason)='') THEN
    RETURN jsonb_build_object('ok',false,'error','reason_required',
             'object_type',p_object_type,'privacy_policy',r_reg.privacy_policy); END IF;

  ------------------------------------------------- FAIL-CLOSED LOG (before read)
  IF v_needs_reason THEN
    v_log := public.admin_workspace_access_log(p_object_type, p_object_id, p_reason);
    IF NOT COALESCE((v_log->>'ok')::boolean,false) THEN
      RETURN jsonb_build_object('ok',false,'error','access_log_failed',
               'detail',v_log->>'error','object_type',p_object_type); END IF;
  END IF;

  ------------------------------------------------- STATIC CASE DISPATCH
  CASE p_object_type
    WHEN 'person'  THEN v_raw:=public.admin_lookup_user(p_object_id);    v_source:=v_raw->'profile';
    WHEN 'child'   THEN v_raw:=public.admin_lookup_child(p_object_id);   v_source:=v_raw->'child';
    WHEN 'media'   THEN v_raw:=public.admin_lookup_media(p_object_id);   v_source:=v_raw->'media';
    WHEN 'capsule' THEN v_raw:=public.admin_lookup_capsule(p_object_id); v_source:=v_raw->'capsule';
    ELSE RETURN jsonb_build_object('ok',false,'error','dispatch_missing','object_type',p_object_type);
  END CASE;

  ------------------------------------------------- projector error passthrough
  IF v_raw IS NULL OR NOT COALESCE((v_raw->>'ok')::boolean,false) THEN
    RETURN jsonb_build_object('ok',false,'error',COALESCE(v_raw->>'error','projector_error'),
             'object_type',p_object_type); END IF;

  ------------------------------------------------- ALLOWLIST FILTER (registry-driven)
  v_fields := COALESCE((
    SELECT jsonb_object_agg(key,value)
    FROM jsonb_each(COALESCE(v_source,'{}'::jsonb))
    WHERE key = ANY (r_reg.discovery_fields)
  ), '{}'::jsonb);

  ------------------------------------------------- LEAK GUARD 1 (allowlist)
  SELECT string_agg(k,',') INTO v_bad
  FROM jsonb_object_keys(v_fields) AS k
  WHERE NOT (k = ANY (r_reg.discovery_fields));
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'ADAPTER_ALLOWLIST_VIOLATION: %', v_bad; END IF;

  ------------------------------------------------- LEAK GUARD 2 (forbidden groups)
  IF EXISTS (SELECT 1 FROM jsonb_object_keys(v_fields) AS k
             WHERE k = ANY (r_reg.forbidden_groups)) THEN
    RAISE EXCEPTION 'ADAPTER_FORBIDDEN_LEAK'; END IF;

  ------------------------------------------------- WorkspaceProjectionDTO (UI-agnostic)
  RETURN jsonb_build_object(
    'ok',              true,
    'dto',             'WorkspaceProjectionDTO/v1',
    'object_type',     p_object_type,
    'object_id',       p_object_id,
    'kind',            r_reg.kind,
    'scope',           r_reg.scope,
    'privacy_policy',  r_reg.privacy_policy,
    'projector_status',r_reg.projector_status,
    'fields',          v_fields,               -- allowlisted identity ONLY
    'capabilities',    r_reg.capability_vocab, -- authz map (action→permission)
    'reason_logged',   v_needs_reason
  );
END
$function$;
```

> **Order note (audit integrity):** reason-log fires **before** the projector read — no sensitive read occurs without a committed audit row. If logging fails → `access_log_failed`, projector never called.

**`WorkspaceProjectionDTO/v1` schema (backend contract):**
```
{ ok, dto, object_type, object_id, kind, scope, privacy_policy, projector_status,
  fields:{<discovery_field>:value}, capabilities:{<action>:<permission|null>}, reason_logged }
error: { ok:false, error, [detail|scope|privacy_policy|projector_status], object_type }
```
Frontend maps this → `ObjectWorkspaceModel` (bands/sections/labels) in a **separate FE layer**. Backend emits no display structure.

---

## 2. ACL PLAN (D15 / D231)

```sql
-- BLOCK 2 (future migration)
-- adapter (new function)
REVOKE ALL ON FUNCTION public.get_object_workspace(text, uuid, text)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT  EXECUTE ON FUNCTION public.get_object_workspace(text, uuid, text)
  TO authenticated, service_role;
-- logger (CREATE OR REPLACE keeps prior ACL; re-assert defensively)
REVOKE ALL ON FUNCTION public.admin_workspace_access_log(text, uuid, text)
  FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.admin_workspace_access_log(text, uuid, text)
  TO authenticated, service_role;
NOTIFY pgrst, 'reload schema';                                  -- D289
```
Target ACL both fns: `{authenticated, postgres, service_role}` EXECUTE · **0 anon · 0 PUBLIC**.

---

## 3. VERIFICATION

### (I) Transactional — in-migration BLOCK 3 (runs as `postgres`, deterministic)

```sql
DO $verify$
DECLARE d text; wired text[];
BEGIN
  -- adapter structure
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND p.proname='get_object_workspace'
      AND p.prosecdef AND pg_get_userbyid(p.proowner)='postgres'
      AND 'search_path=""' = ANY(p.proconfig)
  ) THEN RAISE EXCEPTION 'ADAPTER_STRUCT_FAIL'; END IF;

  -- adapter: zero dynamic SQL
  SELECT lower(pg_get_functiondef(p.oid)) INTO d FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND p.proname='get_object_workspace';
  IF position('execute' in d) > 0 THEN RAISE EXCEPTION 'ADAPTER_DYNSQL_FAIL'; END IF;

  -- adapter ACL: no anon / PUBLIC
  IF EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace,
      LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
    WHERE n.nspname='public' AND p.proname='get_object_workspace'
      AND (a.grantee=0 OR pg_get_userbyid(a.grantee)='anon')
  ) THEN RAISE EXCEPTION 'ADAPTER_ACL_LEAK'; END IF;

  -- logger: capsule supported + child/parent regression guard
  SELECT lower(pg_get_functiondef(p.oid)) INTO d FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND p.proname='admin_workspace_access_log';
  IF position('capsule' in d)=0 OR position('admin_open_capsule_workspace' in d)=0
     THEN RAISE EXCEPTION 'LOGGER_CAPSULE_FAIL'; END IF;
  IF position('admin_open_child_workspace' in d)=0 OR position('admin_open_parent_workspace' in d)=0
     THEN RAISE EXCEPTION 'LOGGER_REGRESSION'; END IF;

  -- CASE branches must equal wired registry set
  SELECT array_agg(object_type ORDER BY object_type) INTO wired
    FROM public.mission_control_object_registry WHERE projector_status='wired';
  IF wired IS DISTINCT FROM ARRAY['capsule','child','media','person'] THEN
    RAISE EXCEPTION 'WIRED_SET_DRIFT: %', wired; END IF;

  RAISE NOTICE 'V128-B2.1 IN-MIGRATION VERIFY OK';
END $verify$;
```
*Any RAISE → whole migration rolls back atomically, no `schema_migrations` row.*
*Note: gate/leak behavior is NOT tested here — `auth.uid()` is null under `postgres`, so `is_admin()` gating can only be exercised post-commit.*

### (II) Post-commit external — impersonation, rollback-safe (run via `execute_sql` after commit)

```sql
DO $t$
DECLARE v_admin uuid := '<ADMIN_user_id>';         -- profiles.user_id of an admin
        v_child uuid := '<CHILD_id>'; v_caps uuid := '<CAPSULE_id>';
        v_media uuid := '<MEDIA_id>'; v_person uuid := '<PROFILE_id>';
        r jsonb; n_before bigint; n_after bigint; msg text := '';
BEGIN
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_admin,'role','authenticated')::text, true);
  SET LOCAL ROLE authenticated;

  -- child: fields ⊆ {full_name,nickname,state}; no forbidden groups; reason_logged
  r := public.get_object_workspace('child', v_child, 'B2.1 verify');
  IF (SELECT bool_or(k NOT IN ('full_name','nickname','state'))
      FROM jsonb_object_keys(r->'fields') k) THEN RAISE EXCEPTION 'CHILD_LEAK: %', r->'fields'; END IF;
  IF (r->'fields') ?| ARRAY['journal_summary','evidence','capsules','parent_memory','memory_conversation','readiness']
     THEN RAISE EXCEPTION 'CHILD_FORBIDDEN_LEAK'; END IF;
  IF COALESCE((r->>'reason_logged')::boolean,false) IS NOT TRUE THEN RAISE EXCEPTION 'CHILD_LOG_FLAG'; END IF;
  msg := msg||'child_ok ';

  -- child without reason → reason_required (no read)
  r := public.get_object_workspace('child', v_child, NULL);
  IF r->>'error' <> 'reason_required' THEN RAISE EXCEPTION 'CHILD_REASON_GATE_FAIL'; END IF;

  -- capsule: fields ⊆ {scope,domain,window_code}; NEVER items; writes audit row
  SELECT count(*) INTO n_before FROM public.audit_logs
    WHERE action='ADMIN_OPEN_CAPSULE_WORKSPACE';
  r := public.get_object_workspace('capsule', v_caps, 'verify');
  IF (r->'fields') ? 'items' OR r ? 'items' THEN RAISE EXCEPTION 'CAPSULE_ITEMS_LEAK'; END IF;
  SELECT count(*) INTO n_after FROM public.audit_logs
    WHERE action='ADMIN_OPEN_CAPSULE_WORKSPACE';
  IF n_after <= n_before THEN RAISE EXCEPTION 'CAPSULE_AUDIT_NOT_WRITTEN'; END IF;
  msg := msg||'capsule_ok ';

  -- media: no linked_child; person: no permissions
  r := public.get_object_workspace('media', v_media, NULL);
  IF (r->'fields') ? 'linked_child' THEN RAISE EXCEPTION 'MEDIA_LEAK'; END IF;
  r := public.get_object_workspace('person', v_person, NULL);
  IF (r->'fields') ? 'permissions' THEN RAISE EXCEPTION 'PERSON_PERMS_LEAK'; END IF;
  msg := msg||'media_ok person_ok ';

  -- forbidden → forbidden_object · registered → not_available
  IF (public.get_object_workspace('journal', v_child, 'x'))->>'error' <> 'forbidden_object'
     THEN RAISE EXCEPTION 'FORBIDDEN_FAIL'; END IF;
  IF (public.get_object_workspace('school', v_person, NULL))->>'error' <> 'not_available'
     THEN RAISE EXCEPTION 'REGISTERED_FAIL'; END IF;

  RAISE EXCEPTION 'ROLLBACK_OK: %', msg;   -- rollback clean, surface evidence
END $t$;
-- Expect: ROLLBACK_OK: child_ok capsule_ok media_ok person_ok
```
**Non-admin test (separate):** impersonate a non-admin profile → any call returns `not_authorized`.
*Note: capsule test writes a real audit row inside the DO block; the final RAISE rolls it back — zero residue.*

---

## 4. ROLLBACK

```sql
DROP FUNCTION IF EXISTS public.get_object_workspace(text, uuid, text);
-- revert logger to child/parent-only (restore pre-B2.1 body)
CREATE OR REPLACE FUNCTION public.admin_workspace_access_log(p_entity_type text, p_entity_id uuid, p_reason text DEFAULT NULL::text)
  RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
declare v_action text; v_actor uuid;
begin
  if not public.is_admin() then return jsonb_build_object('ok',false,'error','not_admin'); end if;
  if p_entity_type not in ('child','parent') then return jsonb_build_object('ok',false,'error','invalid_entity_type'); end if;
  if p_entity_id is null then return jsonb_build_object('ok',false,'error','entity_id_required'); end if;
  if p_entity_type = 'child' and (p_reason is null or length(btrim(p_reason)) = 0) then
    return jsonb_build_object('ok',false,'error','reason_required'); end if;
  v_actor := public.current_profile();
  v_action := case p_entity_type when 'child' then 'ADMIN_OPEN_CHILD_WORKSPACE' when 'parent' then 'ADMIN_OPEN_PARENT_WORKSPACE' end;
  perform public.write_audit_log(v_action, jsonb_build_object(
    'actor_id', v_actor, 'entity_type', p_entity_type, 'entity_id', p_entity_id,
    'child_id', case when p_entity_type='child' then p_entity_id else null end,
    'reason', nullif(btrim(p_reason),'')));
  return jsonb_build_object('ok', true, 'logged', v_action);
end; $function$;
NOTIFY pgrst, 'reload schema';
```
*Adapter drop = additive undo. Logger revert = exact pre-B2.1 body (captured live this session). Baseline → tail `20260810150209`. Migration transactional: RAISE in BLOCK 3 → atomic rollback, no residue.*

---

## 5. SECURITY REVIEW (v2)

| Requirement | v2 status |
|---|---|
| SECURITY DEFINER · pinned search_path | ✅ both fns `SECURITY DEFINER`, `search_path=''`, owner postgres |
| Internal auth gate + self re-gate | ✅ GATE 1 `is_admin()`; nested DEFINER preserves `auth.uid()`; adapter re-gates independently |
| Scope routing | ✅ `scope='platform'` only in B2.1; else `scope_not_wired` (tenant hook → B2.2) |
| Child reason gate | ✅ `privacy_policy ∈ {reason_required,restricted}`; **fail-closed** log before read |
| `admin_workspace_access_log` integration | ✅ extended for `capsule`; adapter checks `ok`, blocks on failure — **no silent weakening** |
| Allowlist-first / never passthrough | ✅ identity sub-object per branch + `key = ANY(discovery_fields)` + 2 guards; child memory/journal/`items`/media bytes/URL unreachable |
| No dynamic SQL / registry non-executable | ✅ static CASE, `position('execute')=0` asserted; registry data-only |
| **Backend DTO ≠ UI Model (Fix B)** | ✅ `WorkspaceProjectionDTO/v1` carries no bands/sections/labels; FE owns mapping |
| **Fail-closed audit (Fix A)** | ✅ reason-gated read blocked unless audit row committed first |
| **Split verification (Fix C)** | ✅ transactional structural + post-commit functional separated |

**Blast radius:** +1 new function (`get_object_workspace`) · 1 existing function extended additively (`admin_workspace_access_log`, child/parent preserved). 0 table/RLS/policy/role change. Inventory delta: functions **233→234**, secdef **222→223**, tables/policies/triggers unchanged.

---

## 6. OWNER DECISIONS before authorize

1. **Capsule policy:** approve **★ FIX A option (extend logger, keep `restricted`+reason)** — recommended — or explicitly choose A3 (`open`, reduced privacy). *Registry-driven either way.*
2. **Logger extension in scope:** confirm B2.1 migration may `CREATE OR REPLACE admin_workspace_access_log` (additive).
3. **B2.0 canonicalization** (D349/v1.37) still open — close before D350/B2.1 canonical.
4. On authorize: assemble 3-block migration (BLOCK 1a+1b DDL → BLOCK 2 ACL → BLOCK 3 transactional VERIFY); run post-commit external verification with real pilot UUIDs; auto-publish gated per rules (schema change → STOP-and-confirm already satisfied by this package).

*Endpoint after build+canonicalize: RULES **D350** · SYSTEM_MAP **v1.38** · HANDOFF **V128-B2.1**.*

**STOP — v2 design package only. Do not apply. Do not deploy.**
