-- =====================================================================
-- V128-B6.2 · MIGRATION M2 (PRODUCTION — NOT YET APPLIED)
-- GOVERNANCE EVALUATOR
-- Dormant: created but not yet called (execute wiring is M4).
-- Depends on M1 (mc_internal schema + policies table). D92 three-block.
-- =====================================================================

-- =====================================================================
-- BLOCK-1 : DDL
-- =====================================================================
CREATE OR REPLACE FUNCTION mc_internal.evaluate_action_policy(
  p_actor_id    uuid,
  p_action_key  text,
  p_object_type text,
  p_object_id   uuid,
  p_context     jsonb,
  p_input       jsonb
) RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $fn$
declare
  v_policy        public.mission_control_action_policies%rowtype;
  v_role          text;
  v_is_platform   boolean;
  v_actor_schools uuid[];
  v_school_id     uuid;
  v_ctx_school    uuid;
  v_risk          text;
  v_risk_req      text;
  v_role_ok       boolean := false;
  v_scope_ok      boolean := false;
  v_context_ok    boolean := false;
  v_reason        text := null;
begin
  -- 1. policy (fail-closed if absent)
  select * into v_policy from public.mission_control_action_policies where action_key = p_action_key;
  if not found then
    return jsonb_build_object('envelope','ActionPolicyDecision/v1','decision','deny',
      'reason_code','MC_POLICY_UNDEFINED','policy_version',null);
  end if;

  -- 2. risk from registry (single source)
  select risk_level into v_risk from public.mission_control_action_registry
   where action_key = p_action_key and status = 'active'
   limit 1;
  v_risk_req := case v_risk
                  when 'LOW' then 'audit_only'
                  when 'MEDIUM' then 'evidence_required'
                  else 'evidence_strict' end;  -- HIGH/CRITICAL declared-only

  -- 3. actor role/scope from p_actor_id (testable; commit-core passes current_profile())
  select role::text into v_role from public.profiles where id = p_actor_id;
  if v_role is null then
    return jsonb_build_object('envelope','ActionPolicyDecision/v1','decision','deny',
      'reason_code','MC_POLICY_ACTOR_UNKNOWN','policy_version',v_policy.policy_version,'risk_level',v_risk);
  end if;
  v_is_platform := v_role in ('super_admin','content_admin','senior_content_admin',
                              'operation_admin','sales_admin','support_admin');
  select coalesce(array_agg(school_id),'{}') into v_actor_schools
    from public.profiles where id = p_actor_id and school_id is not null;

  -- 4. object school (class-only in B6.2)
  if p_object_type = 'class' then
    select school_id into v_school_id from public.classes where id = p_object_id;
  end if;
  if v_school_id is null then
    return jsonb_build_object('envelope','ActionPolicyDecision/v1','decision','deny',
      'reason_code','MC_POLICY_OBJECT_NOT_FOUND','policy_version',v_policy.policy_version,'risk_level',v_risk);
  end if;

  -- 5. ROLE gate (platform admin satisfies role+scope)
  if v_is_platform then
    v_role_ok := true; v_scope_ok := true;
  else
    v_role_ok := v_role = any(v_policy.min_role_set);
    if not v_role_ok then v_reason := 'MC_POLICY_ROLE_DENIED'; end if;
    -- 6. SCOPE gate
    if v_role_ok then
      v_scope_ok := case v_policy.required_scope
        when 'tenant'     then v_school_id = any(v_actor_schools)
        when 'platform'   then false                 -- non-platform actor
        when 'assignment' then false                 -- reserved; no live action (fail-closed)
        else false end;
      if not v_scope_ok then v_reason := 'MC_POLICY_SCOPE_DENIED'; end if;
    end if;
  end if;

  -- 7. CONTEXT coherence (school match)
  if v_role_ok and v_scope_ok then
    begin
      v_ctx_school := nullif(p_context->>'school_id','')::uuid;
    exception when others then
      v_ctx_school := null;
    end;
    v_context_ok := (v_ctx_school is not null and v_ctx_school = v_school_id);
    if not v_context_ok then v_reason := 'MC_POLICY_CONTEXT_DENIED'; end if;
  end if;

  -- 8. capability: SKIPPED (frozen dormant — no gate)

  return jsonb_build_object(
    'envelope','ActionPolicyDecision/v1',
    'decision', case when v_role_ok and v_scope_ok and v_context_ok then 'allow' else 'deny' end,
    'reason_code', v_reason,
    'policy_version', v_policy.policy_version,
    'risk_level', v_risk,
    'risk_requirement', v_risk_req,
    'evaluated', jsonb_build_object('role_ok',v_role_ok,'scope_ok',v_scope_ok,
                                    'context_ok',v_context_ok,'platform_override',v_is_platform),
    'actor_id', p_actor_id
  );
end
$fn$;

-- =====================================================================
-- BLOCK-2 : ACL HARDEN (internal-only — D231)
-- =====================================================================
REVOKE ALL ON FUNCTION mc_internal.evaluate_action_policy(uuid,text,text,uuid,jsonb,jsonb)
  FROM PUBLIC, anon, authenticated;
-- No client grant: only owner (postgres) + commit-core (runs as postgres) may call.

-- =====================================================================
-- BLOCK-3 : VERIFY
-- =====================================================================
DO $verify$
declare v_secdef boolean; v_cfg text[]; v_owner text; v_bad int;
begin
  IF to_regprocedure('mc_internal.evaluate_action_policy(uuid,text,text,uuid,jsonb,jsonb)') IS NULL
     THEN RAISE EXCEPTION 'M2 FAIL: evaluate missing'; END IF;

  SELECT prosecdef, proconfig, pg_get_userbyid(proowner)
    INTO v_secdef, v_cfg, v_owner
    FROM pg_proc WHERE oid='mc_internal.evaluate_action_policy(uuid,text,text,uuid,jsonb,jsonb)'::regprocedure;

  IF NOT v_secdef THEN RAISE EXCEPTION 'M2 FAIL: must be SECURITY DEFINER'; END IF;
  IF v_owner <> 'postgres' THEN RAISE EXCEPTION 'M2 FAIL: owner must be postgres'; END IF;
  IF v_cfg IS DISTINCT FROM ARRAY['search_path=""']::text[] THEN RAISE EXCEPTION 'M2 FAIL: search_path not empty'; END IF;

  SELECT count(*) INTO v_bad FROM (
    SELECT (aclexplode(coalesce(p.proacl, acldefault('f',p.proowner)))).grantee AS g
    FROM pg_proc p WHERE p.oid='mc_internal.evaluate_action_policy(uuid,text,text,uuid,jsonb,jsonb)'::regprocedure
  ) x WHERE g::regrole::text IN ('anon','authenticated');
  IF v_bad <> 0 THEN RAISE EXCEPTION 'M2 FAIL: evaluate must be internal-only (no anon/authenticated EXECUTE)'; END IF;

  RAISE NOTICE 'M2 VERIFY PASS';
end $verify$;
-- ===================== END M2 (NOT APPLIED) ==========================
