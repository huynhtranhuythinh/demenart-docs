-- =====================================================================
-- V128-B6.2 · MIGRATION M3 (PRODUCTION DRAFT — NOT YET APPLIED)
-- Title (reframed per CTO Option 1):
--   GOVERNED EXECUTION FINALIZATION CORRECTION + GOVERNANCE EVIDENCE FOUNDATION
--
-- WHAT THIS MIGRATION ACTUALLY DOES (grounded on live audit 2026-08-14):
--   * Live fact: has_table_privilege('authenticated', ledger, 'UPDATE') = FALSE
--     (relacl = authenticated=ar/postgres → INSERT+SELECT only).
--   * Consequence 1: policy `finish_own` is UNREACHABLE (no base UPDATE priv) →
--     it was NOT an exploitable forge; dropping it is dead-policy hygiene.
--   * Consequence 2: `execute_mission_control_action` is INVOKER and finalizes
--     the ledger via UPDATE → under a REAL authenticated caller that UPDATE is
--     permission-denied → whole txn rolls back → class.assign cannot complete.
--     (The 5 completed / 3 failed rows were written under role=postgres testing.)
--   * FIX: move execution+finalization into a DEFINER commit-core owned by
--     postgres (has UPDATE). execute stays INVOKER and delegates. This makes
--     class.assign correct under real authenticated login for the first time.
--
-- FROZEN (unchanged): execute = SECURITY INVOKER · commit-core = SECURITY DEFINER
--                     · mc_internal schema (NOT PostgREST-exposed) · adapter untouched
--
-- ACCEPTANCE (replaces "byte-identical"):
--   (a) postgres-context compatibility PASS (structural + sim below)
--   (b) REAL AUTHENTICATED EXECUTION PASS (post-apply, real login — see regression plan)
--
-- D92 three-block · D231 ACL re-harden · single transaction (apply_migration) ·
-- RAISE in BLOCK-3 → full atomic rollback.
--
-- PREREQUISITE: M1 (governance tables + doc row) & M2 (evaluator) may precede,
--   but M3 is self-contained for the finalization fix (creates mc_internal if absent;
--   does NOT read policy tables — the governance seam is added in M4).
-- =====================================================================


-- =====================================================================
-- BLOCK-1 : DDL
-- =====================================================================

-- 1a. Internal governance schema (idempotent; NOT added to PGRST_DB_SCHEMAS)
CREATE SCHEMA IF NOT EXISTS mc_internal;


-- 1b. DEFINER commit-core: execution + finalization (result server-derived; actor internal)
CREATE OR REPLACE FUNCTION mc_internal._mc_commit_action(
  p_request_id  uuid,
  p_action_key  text,
  p_object_type text,
  p_object_id   uuid,
  p_context     jsonb,
  p_input       jsonb
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $fn$
declare
  v_actor          uuid;
  v_row            public.mission_control_action_requests%rowtype;
  v_program_id     uuid;
  v_lead_teacher_id uuid;
  v_distribution_id uuid;
  v_result         jsonb;
  v_error_code     text;
  v_error_message  text;
begin
  -- Derive actor INTERNALLY from auth.uid() — never trust a caller-supplied actor.
  v_actor := public.current_profile();
  if v_actor is null then
    return jsonb_build_object(
      'ok', false, 'replayed', false, 'request_id', p_request_id,
      'action_key', p_action_key, 'object_type', p_object_type, 'object_id', p_object_id,
      'error', jsonb_build_object('code', 'MC_ACTION_PERMISSION_DENIED'));
  end if;

  -- Ownership + state guard: only finalize a processing row owned by this actor
  -- that matches the action/object. Blocks direct-call abuse on foreign/finalized rows.
  select * into v_row
    from public.mission_control_action_requests
   where request_id = p_request_id;

  if not found
     or v_row.actor_id is distinct from v_actor
     or v_row.status <> 'processing'
     or v_row.action_key is distinct from p_action_key
     or v_row.object_id is distinct from p_object_id
  then
    return jsonb_build_object(
      'ok', false, 'replayed', false, 'request_id', p_request_id,
      'action_key', p_action_key, 'object_type', p_object_type, 'object_id', p_object_id,
      'error', jsonb_build_object('code', 'MC_ACTION_REQUEST_CONFLICT'));
  end if;

  -- Parse inputs (adapter re-validates); result is NEVER accepted from caller.
  begin
    v_program_id      := nullif(p_input->>'program_id','')::uuid;
    v_lead_teacher_id := nullif(p_input->>'lead_teacher_id','')::uuid;
  exception when others then
    v_program_id := null;
  end;

  -- [M4 governance seam inserted here: evaluate_action_policy + evidence write + enforcing branch]

  begin
    v_distribution_id := public.assign_class_distribution(
      p_object_id, v_program_id, v_lead_teacher_id);  -- adapter self-authorizes (backstop)

    v_result := jsonb_build_object(
      'ok', true, 'replayed', false, 'request_id', p_request_id,
      'action_key', p_action_key, 'object_type', p_object_type, 'object_id', p_object_id,
      'result', jsonb_build_object('class_distribution_id', v_distribution_id),
      'audit', jsonb_build_object('event', 'CLASS_ASSIGNMENT_CREATED', 'recorded', true));

    update public.mission_control_action_requests
       set status = 'completed', result_payload = v_result, error_code = null, completed_at = now()
     where id = v_row.id;                    -- DEFINER(postgres): has UPDATE → finalize succeeds

    return v_result;
  exception
    when unique_violation then
      v_error_code := 'MC_ACTION_CONFLICT';
    when others then
      get stacked diagnostics v_error_message = message_text;
      v_error_code := case v_error_message
        when 'not_authorized_for_school' then 'MC_ACTION_PERMISSION_DENIED'
        when 'distribution_exists'       then 'MC_ACTION_CONFLICT'
        when 'class_not_found'           then 'MC_ACTION_OBJECT_NOT_FOUND'
        when 'subject_not_entitled'      then 'MC_ACTION_INPUT_INVALID'
        when 'lead_teacher_invalid'      then 'MC_ACTION_INPUT_INVALID'
        else 'MC_ACTION_EXECUTION_FAILED'
      end;
  end;

  v_result := jsonb_build_object(
    'ok', false, 'replayed', false, 'request_id', p_request_id,
    'action_key', p_action_key, 'object_type', p_object_type, 'object_id', p_object_id,
    'error', jsonb_build_object('code', v_error_code));

  update public.mission_control_action_requests
     set status = 'failed', result_payload = v_result, error_code = v_error_code, completed_at = now()
   where id = v_row.id;

  return v_result;
end
$fn$;


-- 1c. REPLACE execute — FULL body. Preserves INVOKER + signature + every gate + INSERT
--     + idempotency/replay. ONLY the fresh-execution tail is delegated to commit-core.
CREATE OR REPLACE FUNCTION public.execute_mission_control_action(
  p_action_key text,
  p_object_id  uuid,
  p_context    jsonb,
  p_input      jsonb,
  p_request_id uuid
) RETURNS jsonb
LANGUAGE plpgsql
SET search_path = ''                          -- NO 'SECURITY DEFINER' → stays INVOKER (frozen)
AS $fn$
declare
  v_actor_id uuid;
  v_request_pk uuid;
  v_existing public.mission_control_action_requests%rowtype;
  v_school_id uuid;
  v_context_school_id uuid;
  v_program_id uuid;
  v_lead_teacher_id uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'replayed', false,
      'error', jsonb_build_object('code', 'MC_ACTION_PERMISSION_DENIED'));
  end if;

  v_actor_id := public.current_profile();
  if v_actor_id is null then
    return jsonb_build_object('ok', false, 'replayed', false,
      'error', jsonb_build_object('code', 'MC_ACTION_PERMISSION_DENIED'));
  end if;

  if p_action_key is distinct from 'class.assign' then
    return jsonb_build_object('ok', false, 'replayed', false,
      'error', jsonb_build_object('code', 'MC_ACTION_NOT_FOUND'));
  end if;

  if p_object_id is null or p_request_id is null then
    return jsonb_build_object('ok', false, 'replayed', false,
      'error', jsonb_build_object('code', 'MC_ACTION_INPUT_INVALID'));
  end if;

  if jsonb_typeof(coalesce(p_context, 'null'::jsonb)) is distinct from 'object'
     or not (p_context ? 'school_id')
     or exists (select 1 from jsonb_object_keys(p_context) as k where k <> 'school_id')
  then
    return jsonb_build_object('ok', false, 'replayed', false,
      'error', jsonb_build_object('code', 'MC_ACTION_CONTEXT_DENIED'));
  end if;

  begin
    v_context_school_id := nullif(p_context->>'school_id','')::uuid;
  exception when others then
    return jsonb_build_object('ok', false, 'replayed', false,
      'error', jsonb_build_object('code', 'MC_ACTION_CONTEXT_DENIED'));
  end;

  if jsonb_typeof(coalesce(p_input, 'null'::jsonb)) is distinct from 'object'
     or not (p_input ? 'program_id')
     or exists (select 1 from jsonb_object_keys(p_input) as k where k not in ('program_id','lead_teacher_id'))
  then
    return jsonb_build_object('ok', false, 'replayed', false,
      'error', jsonb_build_object('code', 'MC_ACTION_INPUT_INVALID'));
  end if;

  begin
    v_program_id := nullif(p_input->>'program_id','')::uuid;
    v_lead_teacher_id := nullif(p_input->>'lead_teacher_id','')::uuid;
  exception when others then
    return jsonb_build_object('ok', false, 'replayed', false,
      'error', jsonb_build_object('code', 'MC_ACTION_INPUT_INVALID'));
  end;

  if v_program_id is null then
    return jsonb_build_object('ok', false, 'replayed', false,
      'error', jsonb_build_object('code', 'MC_ACTION_INPUT_INVALID'));
  end if;

  select c.school_id into v_school_id
    from public.classes c
   where c.id = p_object_id;

  if v_school_id is null then
    return jsonb_build_object('ok', false, 'replayed', false,
      'error', jsonb_build_object('code', 'MC_ACTION_OBJECT_NOT_FOUND'));
  end if;

  if v_context_school_id is distinct from v_school_id then
    return jsonb_build_object('ok', false, 'replayed', false,
      'error', jsonb_build_object('code', 'MC_ACTION_CONTEXT_DENIED'));
  end if;

  -- client-create the ledger row (authenticated has INSERT + insert_own_processing policy)
  insert into public.mission_control_action_requests (
    request_id, action_key, object_type, object_id, status, actor_id, started_at
  )
  values (
    p_request_id, 'class.assign', 'class', p_object_id, 'processing', v_actor_id, now()
  )
  on conflict (request_id) do nothing
  returning id into v_request_pk;

  -- replay handling (unchanged)
  if v_request_pk is null then
    select * into v_existing
      from public.mission_control_action_requests r
     where r.request_id = p_request_id;

    if not found then
      return jsonb_build_object('ok', false, 'replayed', false,
        'error', jsonb_build_object('code', 'MC_ACTION_REQUEST_CONFLICT'));
    end if;

    if v_existing.action_key is distinct from 'class.assign'
       or v_existing.object_type is distinct from 'class'
       or v_existing.object_id is distinct from p_object_id
    then
      return jsonb_build_object('ok', false, 'replayed', false,
        'error', jsonb_build_object('code', 'MC_ACTION_REQUEST_CONFLICT'));
    end if;

    if v_existing.status in ('received','processing') then
      return jsonb_build_object('ok', false, 'replayed', true, 'request_id', p_request_id,
        'error', jsonb_build_object('code', 'MC_ACTION_REQUEST_IN_PROGRESS'));
    end if;

    return jsonb_set(
      coalesce(v_existing.result_payload,
        jsonb_build_object('ok', false,
          'error', jsonb_build_object('code', coalesce(v_existing.error_code, 'MC_ACTION_EXECUTION_FAILED')))),
      '{replayed}', 'true'::jsonb, true);
  end if;

  -- ===== V128-B6.2 M3 CHANGE: delegate execution + finalization to DEFINER commit-core =====
  -- Rationale: finalize UPDATE requires table UPDATE privilege, which role 'authenticated'
  -- lacks. commit-core runs as postgres and finalizes; execute remains INVOKER. This
  -- corrects class.assign under real authenticated login (previously failed at finalize).
  return mc_internal._mc_commit_action(
    p_request_id, 'class.assign', 'class', p_object_id, p_context, p_input
  );
end
$fn$;


-- 1d. Drop the unreachable (dead) finalize policy — hygiene, NOT a forge fix.
--     Kept: insert_own_processing (client-create) · select_own (client read).
DROP POLICY IF EXISTS mission_control_action_requests_finish_own
  ON public.mission_control_action_requests;


-- =====================================================================
-- BLOCK-2 : ACL HARDEN (D231)
-- =====================================================================

-- schema usage: authenticated needs USAGE so INVOKER execute can call commit-core
REVOKE ALL ON SCHEMA mc_internal FROM PUBLIC;
GRANT  USAGE ON SCHEMA mc_internal TO authenticated;

-- commit-core: internal governance engine; authenticated EXECUTE required for delegation.
-- Forge-proof by construction (actor internal, result server-derived). Not PGRST-exposed.
REVOKE ALL ON FUNCTION mc_internal._mc_commit_action(uuid,text,text,uuid,jsonb,jsonb) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION mc_internal._mc_commit_action(uuid,text,text,uuid,jsonb,jsonb) TO authenticated;

-- execute: re-assert EXACT prior ACL (captured M0: postgres + authenticated; NO service_role)
REVOKE ALL ON FUNCTION public.execute_mission_control_action(text,uuid,jsonb,jsonb,uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.execute_mission_control_action(text,uuid,jsonb,jsonb,uuid) TO authenticated;


-- =====================================================================
-- BLOCK-3 : VERIFY (structural + postgres-context; RAISE → atomic rollback)
--   NOTE: real-authenticated execution PASS is a POST-APPLY manual gate (regression plan).
-- =====================================================================
DO $verify$
declare
  v_exec_secdef boolean;
  v_core_secdef boolean;
  v_core_owner  text;
  v_core_cfg    text[];
  v_bad_grants  int;
begin
  -- execute remains INVOKER, correct signature
  select prosecdef into v_exec_secdef from pg_proc
   where oid = 'public.execute_mission_control_action(text,uuid,jsonb,jsonb,uuid)'::regprocedure;
  if v_exec_secdef then raise exception 'M3 FAIL: execute must remain INVOKER (prosecdef=false)'; end if;

  -- commit-core exists, DEFINER, owner postgres, empty search_path
  if to_regprocedure('mc_internal._mc_commit_action(uuid,text,text,uuid,jsonb,jsonb)') is null then
    raise exception 'M3 FAIL: commit-core missing';
  end if;
  select prosecdef, pg_get_userbyid(proowner), proconfig
    into v_core_secdef, v_core_owner, v_core_cfg
    from pg_proc where oid = 'mc_internal._mc_commit_action(uuid,text,text,uuid,jsonb,jsonb)'::regprocedure;
  if not v_core_secdef then raise exception 'M3 FAIL: commit-core must be DEFINER'; end if;
  if v_core_owner <> 'postgres' then raise exception 'M3 FAIL: commit-core owner must be postgres'; end if;
  if v_core_cfg is distinct from array['search_path=""']::text[] then
    raise exception 'M3 FAIL: commit-core search_path must be empty';
  end if;

  -- commit-core not reachable by anon; authenticated may execute (needed for delegation)
  select count(*) into v_bad_grants from (
    select (aclexplode(coalesce(p.proacl, acldefault('f',p.proowner)))).grantee as g
    from pg_proc p where p.oid = 'mc_internal._mc_commit_action(uuid,text,text,uuid,jsonb,jsonb)'::regprocedure
  ) x where g::regrole::text = 'anon';
  if v_bad_grants <> 0 then raise exception 'M3 FAIL: commit-core must not grant anon'; end if;

  -- finish_own dropped; insert/select kept
  if exists (select 1 from pg_policies where tablename='mission_control_action_requests'
             and policyname='mission_control_action_requests_finish_own') then
    raise exception 'M3 FAIL: finish_own must be dropped';
  end if;
  if not exists (select 1 from pg_policies where tablename='mission_control_action_requests'
                 and policyname='mission_control_action_requests_insert_own_processing')
     or not exists (select 1 from pg_policies where tablename='mission_control_action_requests'
                 and policyname='mission_control_action_requests_select_own') then
    raise exception 'M3 FAIL: insert_own_processing and select_own must remain';
  end if;

  -- client still cannot UPDATE ledger (finalization stays server-side)
  if has_table_privilege('authenticated','public.mission_control_action_requests','UPDATE') then
    raise exception 'M3 FAIL: authenticated must NOT have ledger UPDATE';
  end if;

  raise notice 'M3 structural verify PASS (real-authenticated execution PASS is a post-apply gate)';
end
$verify$;

-- =====================================================================
-- END M3 PRODUCTION DRAFT — NOT APPLIED. Awaiting Owner Gate.
-- =====================================================================
