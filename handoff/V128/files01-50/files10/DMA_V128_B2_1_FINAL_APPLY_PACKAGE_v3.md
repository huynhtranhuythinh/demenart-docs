# 🛰️ DMA V128-B2.1 — MISSION CONTROL WORKSPACE ADAPTER · **FINAL APPLY PACKAGE v3**

> **⚠️ DESIGN ONLY · READY FOR APPLY · NOT APPLIED.** No `apply_migration`, no `execute_sql`, no code, no deploy.
> **Baseline:** post V128-B2.0 · tail `20260810150209` · FE HEAD `be04f4b` · registry live (17 rows).
> **v3 change vs v2:** ACL block only — logger REVOKE made fully deterministic. Everything else byte-identical.

---

## 1. V128-B2.1 FINAL APPLY PACKAGE v3

### 1.1 Executive summary

v3 finalizes the Mission Control workspace adapter `get_object_workspace(text, uuid, text)` and the additive `capsule` extension to `admin_workspace_access_log`. The **only** difference from the already-reviewed v2 is an **ACL hardening**: the logger's `REVOKE` now lists all four grantee classes (`PUBLIC, anon, authenticated, service_role`) so the post-migration ACL is **deterministic and independent of any pre-migration grants** — closing the residual `CREATE OR REPLACE`-preserves-historical-ACL dependency CTO flagged. Adapter ACL was already deterministic in v2 and is unchanged. Architecture, SQL logic, registry, DTO, and both verification layers are preserved exactly.

### 1.2 Exact delta from v2

**Single edit — logger REVOKE grantee list:**

```diff
  -- logger ACL
- REVOKE ALL ON FUNCTION public.admin_workspace_access_log(text, uuid, text)
-   FROM PUBLIC, anon;                                     -- v2: relied on prior ACL for authenticated/service_role
+ REVOKE ALL ON FUNCTION public.admin_workspace_access_log(text, uuid, text)
+   FROM PUBLIC, anon, authenticated, service_role;        -- v3: deterministic, no historical dependence
  GRANT  EXECUTE ON FUNCTION public.admin_workspace_access_log(text, uuid, text)
    TO authenticated, service_role;                        -- unchanged
```

Nothing else changes. Adapter ACL, BLOCK 1a/1b DDL, transactional VERIFY, post-commit verification, and rollback are identical to v2. (Per scope-lock "Không thay đổi verification," the VERIFY blocks are **not** modified — see §1.6 note.)

### 1.3 Final migration SQL draft (⚠️ DO NOT EXECUTE)

**BLOCK 1a — logger extension (additive; child/parent byte-preserved):**

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

**BLOCK 1b — adapter (returns WorkspaceProjectionDTO/v1):**

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

  ------------------------------------------------- WorkspaceProjectionDTO/v1 (UI-agnostic)
  RETURN jsonb_build_object(
    'ok',              true,
    'dto',             'WorkspaceProjectionDTO/v1',
    'object_type',     p_object_type,
    'object_id',       p_object_id,
    'kind',            r_reg.kind,
    'scope',           r_reg.scope,
    'privacy_policy',  r_reg.privacy_policy,
    'projector_status',r_reg.projector_status,
    'fields',          v_fields,
    'capabilities',    r_reg.capability_vocab,
    'reason_logged',   v_needs_reason
  );
END
$function$;
```

### 1.4 ACL section — **hardened (v3)**

```sql
-- BLOCK 2 — ACL · deterministic, independent of pre-migration grants (D15 / D231)
-- adapter
REVOKE ALL ON FUNCTION public.get_object_workspace(text, uuid, text)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT  EXECUTE ON FUNCTION public.get_object_workspace(text, uuid, text)
  TO authenticated, service_role;
-- logger  (v3: full 4-class REVOKE — no historical-ACL dependence)
REVOKE ALL ON FUNCTION public.admin_workspace_access_log(text, uuid, text)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT  EXECUTE ON FUNCTION public.admin_workspace_access_log(text, uuid, text)
  TO authenticated, service_role;
NOTIFY pgrst, 'reload schema';                                   -- D289
```

Target end-state ACL (both functions, deterministic): `{authenticated, postgres, service_role}` EXECUTE · **0 PUBLIC · 0 anon** · `authenticated` explicit · `service_role` explicit. Owner `postgres` implicit.

### 1.5 Transaction verification — in-migration BLOCK 3 (unchanged from v2)

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

> **§1.6 Scope note:** per lock "Không thay đổi verification," BLOCK 3 is preserved exactly from v2 and still asserts the *adapter* ACL only. Because v3's logger REVOKE is deterministic, a logger-ACL spot-check is *advisable* at post-commit but is **not added here** (out of the ACL-only change scope). Operators may run the standalone ACL check in §1.6b manually.

**§1.6b (optional, manual — not part of migration):**
```sql
SELECT p.proname,
  (SELECT array_agg((CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE pg_get_userbyid(a.grantee) END)||':'||a.privilege_type)
   FROM aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a) AS acl
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public' AND p.proname IN ('get_object_workspace','admin_workspace_access_log');
-- PASS: neither contains PUBLIC or anon; both contain authenticated + service_role.
```

### 1.7 Post-commit verification (unchanged from v2)

```sql
DO $t$
DECLARE v_admin uuid := '<ADMIN_user_id>';
        v_child uuid := '<CHILD_id>'; v_caps uuid := '<CAPSULE_id>';
        v_media uuid := '<MEDIA_id>'; v_person uuid := '<PROFILE_id>';
        r jsonb; n_before bigint; n_after bigint; msg text := '';
BEGIN
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub',v_admin,'role','authenticated')::text, true);
  SET LOCAL ROLE authenticated;

  r := public.get_object_workspace('child', v_child, 'B2.1 verify');
  IF (SELECT bool_or(k NOT IN ('full_name','nickname','state'))
      FROM jsonb_object_keys(r->'fields') k) THEN RAISE EXCEPTION 'CHILD_LEAK: %', r->'fields'; END IF;
  IF (r->'fields') ?| ARRAY['journal_summary','evidence','capsules','parent_memory','memory_conversation','readiness']
     THEN RAISE EXCEPTION 'CHILD_FORBIDDEN_LEAK'; END IF;
  IF COALESCE((r->>'reason_logged')::boolean,false) IS NOT TRUE THEN RAISE EXCEPTION 'CHILD_LOG_FLAG'; END IF;
  msg := msg||'child_ok ';

  r := public.get_object_workspace('child', v_child, NULL);
  IF r->>'error' <> 'reason_required' THEN RAISE EXCEPTION 'CHILD_REASON_GATE_FAIL'; END IF;

  SELECT count(*) INTO n_before FROM public.audit_logs WHERE action='ADMIN_OPEN_CAPSULE_WORKSPACE';
  r := public.get_object_workspace('capsule', v_caps, 'verify');
  IF (r->'fields') ? 'items' OR r ? 'items' THEN RAISE EXCEPTION 'CAPSULE_ITEMS_LEAK'; END IF;
  SELECT count(*) INTO n_after FROM public.audit_logs WHERE action='ADMIN_OPEN_CAPSULE_WORKSPACE';
  IF n_after <= n_before THEN RAISE EXCEPTION 'CAPSULE_AUDIT_NOT_WRITTEN'; END IF;
  msg := msg||'capsule_ok ';

  r := public.get_object_workspace('media', v_media, NULL);
  IF (r->'fields') ? 'linked_child' THEN RAISE EXCEPTION 'MEDIA_LEAK'; END IF;
  r := public.get_object_workspace('person', v_person, NULL);
  IF (r->'fields') ? 'permissions' THEN RAISE EXCEPTION 'PERSON_PERMS_LEAK'; END IF;
  msg := msg||'media_ok person_ok ';

  IF (public.get_object_workspace('journal', v_child, 'x'))->>'error' <> 'forbidden_object'
     THEN RAISE EXCEPTION 'FORBIDDEN_FAIL'; END IF;
  IF (public.get_object_workspace('school', v_person, NULL))->>'error' <> 'not_available'
     THEN RAISE EXCEPTION 'REGISTERED_FAIL'; END IF;

  RAISE EXCEPTION 'ROLLBACK_OK: %', msg;
END $t$;
-- Expect: ROLLBACK_OK: child_ok capsule_ok media_ok person_ok
```
**Non-admin test (separate):** impersonate non-admin → every call returns `not_authorized`.

### 1.8 Rollback plan (unchanged from v2)

```sql
DROP FUNCTION IF EXISTS public.get_object_workspace(text, uuid, text);
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
*Adapter drop = additive undo. Logger revert = exact pre-B2.1 body (captured live). Baseline → tail `20260810150209`. Migration transactional: RAISE in BLOCK 3 → atomic rollback, no residue.*

### 1.9 Security review (v3)

Identical posture to v2, plus deterministic logger ACL:

| Property | Status |
|---|---|
| SECURITY DEFINER · owner postgres · `search_path=''` (both fns) | ✅ |
| Internal `is_admin()` gate + independent re-gate (nested DEFINER preserves `auth.uid()`) | ✅ |
| Scope routing (`platform` only; `scope_not_wired` otherwise) | ✅ |
| Child + capsule reason gate; **fail-closed** log **before** projector read | ✅ |
| Capsule audit: `ADMIN_OPEN_CAPSULE_WORKSPACE`, reason required, no silent weakening | ✅ |
| Allowlist-first (`discovery_fields`) + 2 leak guards; child memory/journal/`items`/media bytes·URL unreachable | ✅ |
| No dynamic SQL (`position('execute')=0` asserted); registry non-executable | ✅ |
| Backend `WorkspaceProjectionDTO/v1` carries no UI bands | ✅ |
| **ACL deterministic — 0 PUBLIC · 0 anon · explicit authenticated + service_role, independent of prior grants (v3)** | ✅ |

**Blast radius:** +1 new function · 1 existing function extended additively (child/parent byte-preserved). Inventory delta: functions **233→234**, secdef **222→223**. **0** table · **0** column · **0** policy · **0** RLS · **0** role · **0** permission-model · **0** registry · **0** frontend change.

---

## 2. EXPLICIT COMPARISON

| Component | v2 | v3 |
|---|---|---|
| Architecture | unchanged | **unchanged** |
| Adapter (`get_object_workspace`) | unchanged | **unchanged** |
| Logger (`admin_workspace_access_log`) | additive capsule | **unchanged** (same additive body) |
| Adapter ACL | already deterministic (4-class REVOKE) | **unchanged** |
| Logger ACL | `REVOKE FROM PUBLIC, anon` (relied on prior ACL) | **hardened** → `REVOKE FROM PUBLIC, anon, authenticated, service_role` |
| Registry | unchanged | **unchanged** |
| DTO (`WorkspaceProjectionDTO/v1`) | unchanged | **unchanged** |
| Scope | platform-only | **unchanged** |
| Transaction verification | BLOCK 3 | **unchanged** |
| Post-commit verification | impersonation suite | **unchanged** |
| Rollback | additive undo + logger revert | **unchanged** |

**Net v3 delta = 1 line** (logger REVOKE grantee list).

---

## 3. FINAL EXECUTION GATE

- **DESIGN APPROVED** ✅ — architecture, privacy, capsule audit, DTO separation, static CASE, verification all PASS; v3 ACL hardening applied.
- **READY FOR APPLY** ✅ — migration = BLOCK 1a + 1b (DDL) → BLOCK 2 (deterministic ACL) → BLOCK 3 (transactional VERIFY); post-commit external verification defined; rollback defined.
- **NOT APPLIED** 🚫 — no `apply_migration`, no `execute_sql`, no code, no deploy performed. Awaiting explicit Owner authorization to execute.

**Governance compliance:** v3 adds **no** table, column, policy, RLS change, role, permission model, registry change, or frontend change. **ACL hardening only**, exactly as specified.

**Outstanding (unchanged):** B2.0 canonicalization (D349 / SYSTEM_MAP v1.37) remains open pending real `DMA_RULES.md` / `DMA_SYSTEM_MAP.md` upload — recommend closing before B2.1 canonical (D350 / v1.38 / HANDOFF V128-B2.1).

**STOP — final design package. Apply only on explicit Owner authorization.**
