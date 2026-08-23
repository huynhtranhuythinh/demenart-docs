-- =====================================================================
-- MIGRATION: v128_b3_0_context_seam_foundation
-- Milestone: V128-B3.0 — Context Seam Foundation (Mission Control OS)
-- Baseline: tail 20260811080037 · RULES D351 · SYSTEM_MAP v1.39 · FE be04f4b
-- Design source: FINAL APPLY PACKAGE v2 + v2.1 SECURITY DELTA (locked, OG-passed)
-- Grounding: core steps 1/2/5/6 ported BYTE-FAITHFUL from LIVE B2.2
--            public.get_object_workspace(text,uuid,text) captured in STEP 1 precheck.
-- D92 three-block · atomic (apply_migration wraps in tx) · RAISE-on-fail rollback guard.
-- =====================================================================


-- =====================================================================
-- BLOCK 1 — DDL (column + CHECK + 3 CREATE + 1 REPLACE)
-- =====================================================================

-- 1a · registry column + declarative shape CHECK (D-2) ----------------
ALTER TABLE public.mission_control_object_registry
  ADD COLUMN context_requirements jsonb NOT NULL
  DEFAULT '{"version":1,"keys":{},"allow_unknown":false}'::jsonb;

ALTER TABLE public.mission_control_object_registry
  ADD CONSTRAINT mc_context_requirements_shape_chk CHECK (
        jsonb_typeof(context_requirements)                    = 'object'
    AND jsonb_typeof(context_requirements -> 'version')       = 'number'
    AND jsonb_typeof(context_requirements -> 'keys')          = 'object'
    AND jsonb_typeof(context_requirements -> 'allow_unknown') = 'boolean'
    AND (context_requirements - 'version' - 'keys' - 'allow_unknown') = '{}'::jsonb
  );

-- 1b · structural validator seam (D-3) — STRUCTURAL ONLY, no auth, no target-object read
CREATE FUNCTION public.validate_mission_control_object_context(
    p_object_type text,
    p_context     jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $validator$
DECLARE
  v_req           jsonb;
  v_keys          jsonb;
  v_allow_unknown boolean;
  v_ctx           jsonb;
  v_errors        text[] := ARRAY[]::text[];
  v_norm          jsonb  := '{}'::jsonb;
  v_key           text;
  v_spec          jsonb;
  v_type          text;
  v_required      boolean;
  v_val           jsonb;
  v_ck            text;
BEGIN
  -- registry-only read (metadata catalog; NEVER target object / classes / sessions / perms)
  SELECT context_requirements INTO v_req
    FROM public.mission_control_object_registry
   WHERE object_type = p_object_type;

  IF NOT FOUND OR v_req IS NULL THEN
    RETURN jsonb_build_object('valid', false,
             'errors', jsonb_build_array('context_requirements_malformed'),
             'normalized_context', '{}'::jsonb);
  END IF;

  -- defense-in-depth skeleton sanity (CHECK already enforces at write-time)
  IF jsonb_typeof(v_req)                  IS DISTINCT FROM 'object'
     OR jsonb_typeof(v_req->'keys')       IS DISTINCT FROM 'object'
     OR jsonb_typeof(v_req->'allow_unknown') IS DISTINCT FROM 'boolean' THEN
    RETURN jsonb_build_object('valid', false,
             'errors', jsonb_build_array('context_requirements_malformed'),
             'normalized_context', '{}'::jsonb);
  END IF;

  v_keys          := v_req->'keys';
  v_allow_unknown := (v_req->>'allow_unknown')::boolean;

  -- context must be object; NULL → {}
  v_ctx := coalesce(p_context, '{}'::jsonb);
  IF jsonb_typeof(v_ctx) IS DISTINCT FROM 'object' THEN
    RETURN jsonb_build_object('valid', false,
             'errors', jsonb_build_array('context_not_object'),
             'normalized_context', '{}'::jsonb);
  END IF;

  -- (1) declared keys: required-presence + primitive type check + normalize
  FOR v_key, v_spec IN SELECT key, value FROM jsonb_each(v_keys) LOOP
    v_type     := v_spec->>'type';
    v_required := coalesce((v_spec->>'required')::boolean, false);

    IF NOT (v_ctx ? v_key) THEN
      IF v_required THEN
        v_errors := v_errors || 'context_missing_required_key';
      END IF;
      CONTINUE;                          -- optional & absent → skip
    END IF;

    v_val := v_ctx -> v_key;

    IF v_type = 'uuid' THEN
      IF jsonb_typeof(v_val) IS DISTINCT FROM 'string'
         OR (v_ctx->>v_key) !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
        v_errors := v_errors || 'context_type_mismatch'; CONTINUE;
      END IF;
      v_norm := v_norm || jsonb_build_object(v_key, to_jsonb(btrim(v_ctx->>v_key)));
    ELSIF v_type = 'text' THEN
      IF jsonb_typeof(v_val) IS DISTINCT FROM 'string' THEN
        v_errors := v_errors || 'context_type_mismatch'; CONTINUE;
      END IF;
      v_norm := v_norm || jsonb_build_object(v_key, to_jsonb(btrim(v_ctx->>v_key)));
    ELSIF v_type = 'int' THEN
      IF jsonb_typeof(v_val) IS DISTINCT FROM 'number'
         OR (v_ctx->>v_key) !~ '^-?[0-9]+$' THEN
        v_errors := v_errors || 'context_type_mismatch'; CONTINUE;
      END IF;
      v_norm := v_norm || jsonb_build_object(v_key, v_val);
    ELSIF v_type = 'bool' THEN
      IF jsonb_typeof(v_val) IS DISTINCT FROM 'boolean' THEN
        v_errors := v_errors || 'context_type_mismatch'; CONTINUE;
      END IF;
      v_norm := v_norm || jsonb_build_object(v_key, v_val);
    ELSE
      v_errors := v_errors || 'context_requirements_malformed'; CONTINUE;
    END IF;
  END LOOP;

  -- (2) unknown-key rejection when allow_unknown=false
  --     (allow_unknown=true → not rejected; normalized stays declared-keys-only [AUTHORING NOTE #1])
  IF NOT v_allow_unknown THEN
    FOR v_ck IN SELECT k FROM jsonb_object_keys(v_ctx) AS k LOOP
      IF NOT (v_keys ? v_ck) THEN
        v_errors := v_errors || 'context_unknown_key';
      END IF;
    END LOOP;
  END IF;

  RETURN jsonb_build_object(
    'valid',              (array_length(v_errors,1) IS NULL),
    'errors',             to_jsonb(v_errors),
    'normalized_context', v_norm
  );
END
$validator$;

-- 1c · shared internal gate core (D-1) — canonical order (D-4); internal-only ACL
--       Steps 1/2/5/6 = BYTE-FAITHFUL port of LIVE B2.2 get_object_workspace(text,uuid,text).
--       Steps 3 (validate) + 4 (auth-slot no-op) = NEW seam.
CREATE FUNCTION public._mission_control_workspace_core(
    p_object_type text,
    p_object_id   uuid,
    p_context     jsonb,
    p_reason      text
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $core$
DECLARE
  r_reg          public.mission_control_object_registry%ROWTYPE;
  v_raw          jsonb; v_source jsonb; v_fields jsonb; v_bad text;
  v_needs_reason boolean; v_log jsonb;
  v_vres         jsonb; v_ctx jsonb;
BEGIN
  -- 1 · AUTHENTICATE (is_admin gate — unchanged B2.x) -----------------
  IF NOT public.is_admin() THEN
    RETURN jsonb_build_object('ok',false,'error','not_authorized'); END IF;

  -- 2 · REGISTRY / OBJECT METADATA (metadata-only; no object touch) ---
  SELECT * INTO r_reg FROM public.mission_control_object_registry
   WHERE object_type = p_object_type;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok',false,'error','unknown_object_type','object_type',p_object_type); END IF;
  IF r_reg.kind='forbidden' OR r_reg.projector_status='none' THEN
    RETURN jsonb_build_object('ok',false,'error','forbidden_object','object_type',p_object_type); END IF;
  IF r_reg.projector_status='registered' THEN
    RETURN jsonb_build_object('ok',false,'error','not_available',
             'object_type',p_object_type,'projector_status','registered'); END IF;
  IF r_reg.scope IS DISTINCT FROM 'platform'
     AND r_reg.scope IS DISTINCT FROM 'tenant' THEN
    RETURN jsonb_build_object('ok',false,'error','scope_not_wired',
             'object_type',p_object_type,'scope',r_reg.scope); END IF;

  -- 3 · VALIDATE CONTEXT (structural seam; fail-closed) ---------------
  BEGIN
    v_vres := public.validate_mission_control_object_context(
                p_object_type, coalesce(p_context, '{}'::jsonb));
  EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('ok',false,'error','context_invalid','object_type',p_object_type);
  END;
  IF NOT COALESCE((v_vres->>'valid')::boolean, false) THEN
    RETURN jsonb_build_object('ok',false,'error','context_invalid','object_type',p_object_type);
  END IF;
  v_ctx := v_vres->'normalized_context';

  -- 4 · CONTEXT AUTHORIZATION SLOT — B3.0 NO-OP placeholder -----------
  --     B3.1 hook: authorize on v_ctx (validated+normalized) + registry
  --     metadata ONLY. Forbidden: touch target object to discover→authorize.
  --     B3.0: pass-through (no authorize, no deny). No authorize_* created.
  PERFORM v_ctx;  -- reserve slot; keeps v_ctx live for B3.1 (no-op)

  -- 5 · PRIVACY / REASON (after context; before touch — unchanged B2.x)
  v_needs_reason := r_reg.privacy_policy IN ('reason_required','restricted');
  IF v_needs_reason AND (p_reason IS NULL OR btrim(p_reason)='') THEN
    RETURN jsonb_build_object('ok',false,'error','reason_required',
             'object_type',p_object_type,'privacy_policy',r_reg.privacy_policy); END IF;
  IF v_needs_reason THEN
    v_log := public.admin_workspace_access_log(p_object_type, p_object_id, p_reason);
    IF NOT COALESCE((v_log->>'ok')::boolean,false) THEN
      RETURN jsonb_build_object('ok',false,'error','access_log_failed',
               'detail',v_log->>'error','object_type',p_object_type); END IF;
  END IF;

  -- 6 · TOUCH OBJECT / PROJECTOR (static CASE — unchanged B2.x) -------
  CASE p_object_type
    WHEN 'person'  THEN v_raw:=public.admin_lookup_user(p_object_id);    v_source:=v_raw->'profile';
    WHEN 'child'   THEN v_raw:=public.admin_lookup_child(p_object_id);   v_source:=v_raw->'child';
    WHEN 'media'   THEN v_raw:=public.admin_lookup_media(p_object_id);   v_source:=v_raw->'media';
    WHEN 'capsule' THEN v_raw:=public.admin_lookup_capsule(p_object_id); v_source:=v_raw->'capsule';
    WHEN 'school'  THEN v_raw:=public.admin_lookup_school(p_object_id);  v_source:=v_raw->'school';
    ELSE RETURN jsonb_build_object('ok',false,'error','dispatch_missing','object_type',p_object_type);
  END CASE;

  IF v_raw IS NULL OR NOT COALESCE((v_raw->>'ok')::boolean,false) THEN
    RETURN jsonb_build_object('ok',false,'error',COALESCE(v_raw->>'error','projector_error'),
             'object_type',p_object_type); END IF;

  v_fields := COALESCE((
    SELECT jsonb_object_agg(key,value)
    FROM jsonb_each(COALESCE(v_source,'{}'::jsonb))
    WHERE key = ANY (r_reg.discovery_fields)
  ), '{}'::jsonb);

  SELECT string_agg(k,',') INTO v_bad
  FROM jsonb_object_keys(v_fields) AS k
  WHERE NOT (k = ANY (r_reg.discovery_fields));
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'ADAPTER_ALLOWLIST_VIOLATION: %', v_bad; END IF;

  IF EXISTS (SELECT 1 FROM jsonb_object_keys(v_fields) AS k
             WHERE k = ANY (r_reg.forbidden_groups)) THEN
    RAISE EXCEPTION 'ADAPTER_FORBIDDEN_LEAK'; END IF;

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
$core$;

-- 1d · legacy 3-arg overload → thin wrapper (D-1/D-5; external contract unchanged)
CREATE OR REPLACE FUNCTION public.get_object_workspace(
    p_object_type text,
    p_object_id   uuid,
    p_reason      text DEFAULT NULL
) RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $legacy$
  SELECT public._mission_control_workspace_core(
           p_object_type, p_object_id, '{}'::jsonb, p_reason);
$legacy$;

-- 1e · new 4-arg overload → thin wrapper (D-5; p_context REQUIRED, NO DEFAULT)
CREATE FUNCTION public.get_object_workspace(
    p_object_type text,
    p_object_id   uuid,
    p_context     jsonb,
    p_reason      text DEFAULT NULL
) RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $ctxaware$
  SELECT public._mission_control_workspace_core(
           p_object_type, p_object_id, p_context, p_reason);
$ctxaware$;


-- =====================================================================
-- BLOCK 2 — ACL HARDENING (D15 replace-reset · D231 auto-grant guard · D289)
--   validator + core = internal-only {postgres, service_role}  (v2.1 C-1)
--   both overloads    = {authenticated, postgres, service_role}
--   ALL four          = 0 anon · 0 PUBLIC
-- =====================================================================

-- validator: internal-only (0 authenticated — v2.1 C-1 SECURITY DELTA)
REVOKE ALL ON FUNCTION public.validate_mission_control_object_context(text, jsonb)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.validate_mission_control_object_context(text, jsonb)
  TO service_role;

-- core: internal-only (symmetric with validator)
REVOKE ALL ON FUNCTION public._mission_control_workspace_core(text, uuid, jsonb, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public._mission_control_workspace_core(text, uuid, jsonb, text)
  TO service_role;

-- legacy 3-arg overload: re-harden after REPLACE (D15)
REVOKE ALL ON FUNCTION public.get_object_workspace(text, uuid, text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_object_workspace(text, uuid, text)
  TO authenticated, service_role;

-- new 4-arg overload
REVOKE ALL ON FUNCTION public.get_object_workspace(text, uuid, jsonb, text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_object_workspace(text, uuid, jsonb, text)
  TO authenticated, service_role;

NOTIFY pgrst, 'reload schema';   -- D289


-- =====================================================================
-- BLOCK 3 — IN-TX STRUCTURAL VERIFY (RAISE-on-fail → atomic rollback, D92)
--   Trigger-safe: no INSERT/UPDATE on registry (avoids guard-trigger swallow
--   + other 7 CHECKs). CHECK-rejection logic tested via expression + constraintdef.
-- =====================================================================
DO $verify$
DECLARE
  v int; v_txt text; v_def text; v_cdef text; v_ndefaults int;
BEGIN
  -- 1 · column exists · jsonb · NOT NULL
  PERFORM 1 FROM information_schema.columns
   WHERE table_schema='public' AND table_name='mission_control_object_registry'
     AND column_name='context_requirements' AND data_type='jsonb' AND is_nullable='NO';
  IF NOT FOUND THEN RAISE EXCEPTION 'VERIFY_FAIL: context_requirements column missing/wrong'; END IF;

  -- 2 · CHECK present + definition contains minus-chain + logic rejects extra top-level key
  SELECT pg_get_constraintdef(oid) INTO v_cdef FROM pg_constraint
   WHERE conname='mc_context_requirements_shape_chk'
     AND conrelid='public.mission_control_object_registry'::regclass;
  IF v_cdef IS NULL THEN RAISE EXCEPTION 'VERIFY_FAIL: shape CHECK missing'; END IF;
  IF position('- ''version'' - ''keys'' - ''allow_unknown''' in v_cdef) = 0 THEN
    RAISE EXCEPTION 'VERIFY_FAIL: shape CHECK missing unknown-key rejection clause: %', v_cdef; END IF;
  IF ('{"version":1,"keys":{},"allow_unknown":false,"table":"x"}'::jsonb
        - 'version' - 'keys' - 'allow_unknown') = '{}'::jsonb THEN
    RAISE EXCEPTION 'VERIFY_FAIL: shape expr wrongly accepts extra top-level key'; END IF;

  -- 3 · backfill: all 17 rows = default descriptor
  SELECT count(*) INTO v FROM public.mission_control_object_registry
   WHERE context_requirements = '{"version":1,"keys":{},"allow_unknown":false}'::jsonb;
  IF v <> 17 THEN RAISE EXCEPTION 'VERIFY_FAIL: backfill expected 17 default, got %', v; END IF;

  -- 4 · validator: exists · secdef · search_path='' · no dynamic SQL
  SELECT pg_get_functiondef('public.validate_mission_control_object_context(text,jsonb)'::regprocedure) INTO v_def;
  IF v_def IS NULL THEN RAISE EXCEPTION 'VERIFY_FAIL: validator missing'; END IF;
  IF position('SET search_path TO ''''' in v_def) = 0
     AND position('search_path='''''  in v_def) = 0 THEN
    RAISE EXCEPTION 'VERIFY_FAIL: validator search_path not empty'; END IF;
  IF position('execute' in lower(v_def)) > 0 THEN
    RAISE EXCEPTION 'VERIFY_FAIL: validator contains dynamic EXECUTE'; END IF;

  -- 5 · core: exists · ACL 0 anon/0 authenticated/0 PUBLIC · has service_role
  SELECT string_agg(distinct case when a.grantee=0 then 'PUBLIC' else pg_get_userbyid(a.grantee) end, ',') INTO v_txt
    FROM pg_proc p, lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
   WHERE p.oid='public._mission_control_workspace_core(text,uuid,jsonb,text)'::regprocedure
     AND a.privilege_type='EXECUTE';
  IF v_txt IS NULL THEN RAISE EXCEPTION 'VERIFY_FAIL: core has no EXECUTE grantees'; END IF;
  IF v_txt ~ 'anon' OR v_txt ~ 'authenticated' OR v_txt ~ 'PUBLIC' THEN
    RAISE EXCEPTION 'VERIFY_FAIL: core ACL leaks client role: %', v_txt; END IF;
  IF v_txt !~ 'service_role' THEN RAISE EXCEPTION 'VERIFY_FAIL: core missing service_role: %', v_txt; END IF;

  -- 5b · validator ACL 0 anon/0 authenticated/0 PUBLIC (v2.1 C-1)
  SELECT string_agg(distinct case when a.grantee=0 then 'PUBLIC' else pg_get_userbyid(a.grantee) end, ',') INTO v_txt
    FROM pg_proc p, lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
   WHERE p.oid='public.validate_mission_control_object_context(text,jsonb)'::regprocedure
     AND a.privilege_type='EXECUTE';
  IF v_txt ~ 'anon' OR v_txt ~ 'authenticated' OR v_txt ~ 'PUBLIC' THEN
    RAISE EXCEPTION 'VERIFY_FAIL: validator ACL leaks client role: %', v_txt; END IF;

  -- 6 · both overloads: exist · ACL 0 anon/0 PUBLIC · has authenticated+service_role
  FOREACH v_txt IN ARRAY ARRAY[
      'public.get_object_workspace(text,uuid,text)',
      'public.get_object_workspace(text,uuid,jsonb,text)'] LOOP
    DECLARE v_acl text;
    BEGIN
      SELECT string_agg(distinct case when a.grantee=0 then 'PUBLIC' else pg_get_userbyid(a.grantee) end, ',') INTO v_acl
        FROM pg_proc p, lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
       WHERE p.oid=v_txt::regprocedure AND a.privilege_type='EXECUTE';
      IF v_acl IS NULL THEN RAISE EXCEPTION 'VERIFY_FAIL: % has no grantees', v_txt; END IF;
      IF v_acl ~ 'anon' OR v_acl ~ 'PUBLIC' THEN RAISE EXCEPTION 'VERIFY_FAIL: % ACL leaks anon/PUBLIC: %', v_txt, v_acl; END IF;
      IF v_acl !~ 'authenticated' OR v_acl !~ 'service_role' THEN
        RAISE EXCEPTION 'VERIFY_FAIL: % missing authenticated/service_role: %', v_txt, v_acl; END IF;
    END;
  END LOOP;

  -- 7 · 4-arg p_context NO DEFAULT (only p_reason defaulted → pronargdefaults=1)
  SELECT pronargdefaults INTO v_ndefaults FROM pg_proc
   WHERE oid='public.get_object_workspace(text,uuid,jsonb,text)'::regprocedure;
  IF v_ndefaults <> 1 THEN RAISE EXCEPTION 'VERIFY_FAIL: 4-arg default count = % (expected 1; p_context must be no-default)', v_ndefaults; END IF;

  -- 8 · DTO contract marker present in core
  SELECT pg_get_functiondef('public._mission_control_workspace_core(text,uuid,jsonb,text)'::regprocedure) INTO v_def;
  IF position('WorkspaceProjectionDTO/v1' in v_def) = 0 THEN
    RAISE EXCEPTION 'VERIFY_FAIL: core DTO marker missing'; END IF;

  -- 9 · registry state unchanged: wired=5 · registered=6 · none=6 · class+session registered
  SELECT count(*) INTO v FROM public.mission_control_object_registry WHERE projector_status='wired';
  IF v <> 5 THEN RAISE EXCEPTION 'VERIFY_FAIL: wired=% (expected 5)', v; END IF;
  SELECT count(*) INTO v FROM public.mission_control_object_registry WHERE projector_status='registered';
  IF v <> 6 THEN RAISE EXCEPTION 'VERIFY_FAIL: registered=% (expected 6)', v; END IF;
  SELECT count(*) INTO v FROM public.mission_control_object_registry WHERE projector_status='none';
  IF v <> 6 THEN RAISE EXCEPTION 'VERIFY_FAIL: none=% (expected 6)', v; END IF;
  SELECT count(*) INTO v FROM public.mission_control_object_registry
   WHERE object_type IN ('class','session') AND projector_status='registered';
  IF v <> 2 THEN RAISE EXCEPTION 'VERIFY_FAIL: class/session not both registered (got %)', v; END IF;

  -- 10 · projector count unchanged (no new admin_lookup_*)
  SELECT count(*) INTO v FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname='public' AND p.proname LIKE 'admin_lookup_%';
  IF v <> 6 THEN RAISE EXCEPTION 'VERIFY_FAIL: admin_lookup_* count=% (expected 6, projector+0)', v; END IF;

  RAISE NOTICE 'V128-B3.0 STRUCTURAL VERIFY: ALL PASS';
END
$verify$;
