-- =====================================================================
-- V128-B6.2 · MIGRATION M3 FINAL (PRODUCTION — NOT YET APPLIED)
-- GOVERNED EXECUTION FINALIZATION CORRECTION (+ governance evidence foundation)
--
-- WHY (grounded, live 2026-08-14): authenticated has NO UPDATE on the ledger
-- (has_table_privilege=false; relacl authenticated=ar). execute is INVOKER, so its
-- inline finalize UPDATE is permission-denied under a real authenticated caller →
-- class.assign cannot complete under real login. This migration moves finalization
-- into a DEFINER commit-core (postgres, has UPDATE); execute stays INVOKER and
-- delegates. finish_own is dropped as DEAD-POLICY cleanup (it was unreachable —
-- NOT an exploitable forge).
--
-- ACCEPTANCE: (a) postgres-context compatibility PASS  AND
--             (b) REAL AUTHENTICATED EXECUTION PASS (post-apply hard gate)
--
-- FROZEN: execute INVOKER · commit-core DEFINER · mc_internal (not PGRST-exposed) · adapter untouched
-- D92 · single transaction · RAISE anywhere → atomic rollback.
-- Run in an ISOLATED apply session; real-login regression immediately after.
-- =====================================================================

-- =====================================================================
-- BLOCK-0 : PRECONDITION (mutation-blocking; RAISE → rollback before any change)
--   NOTE: precondition #4 (mc_internal NOT in pgrst.db_schemas) is NOT DB-readable
--   (platform-managed, not a role setting) → it is a MANUAL Owner-Gate STOP check
--   in the Apply Checklist, asserted here only as a NOTICE reminder.
-- =====================================================================
DO $precheck$
declare v_exec_secdef boolean; v_adapter_md5 text;
begin
  -- #1 execute is INVOKER
  select prosecdef into v_exec_secdef from pg_proc
   where oid='public.execute_mission_control_action(text,uuid,jsonb,jsonb,uuid)'::regprocedure;
  if v_exec_secdef is null then raise exception 'M3 PRECHECK FAIL: execute not found'; end if;
  if v_exec_secdef then raise exception 'M3 PRECHECK FAIL: execute is not INVOKER'; end if;

  -- #2 adapter unchanged fingerprint (captured M0)
  select md5(pg_get_functiondef(oid)) into v_adapter_md5 from pg_proc
   where oid='public.assign_class_distribution(uuid,uuid,uuid)'::regprocedure;
  if v_adapter_md5 is distinct from '03a1510bd827c03a650a3a88312fbe3a' then
    raise exception 'M3 PRECHECK FAIL: assign_class_distribution fingerprint drift (got %)', v_adapter_md5;
  end if;

  -- #3 authenticated cannot UPDATE ledger (the defect this migration corrects)
  if has_table_privilege('authenticated','public.mission_control_action_requests','UPDATE') then
    raise exception 'M3 PRECHECK FAIL: unexpected authenticated UPDATE on ledger (premise changed)';
  end if;

  -- #4 external gate reminder
  raise notice 'M3 PRECHECK: verify externally that mc_internal is NOT in pgrst.db_schemas before Apply.';
  raise notice 'M3 PRECHECK PASS (#1 INVOKER, #2 adapter md5, #3 no client UPDATE).';
end $precheck$;

-- =====================================================================
-- BLOCK-1 : DDL
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS mc_internal;   -- idempotent (created in M1)

-- DEFINER commit-core: execution + finalization. Result server-derived; actor internal.
-- Accepts NO actor / result_payload / status / completed_at from caller.
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
  v_actor           uuid;
  v_row             public.mission_control_action_requests%rowtype;
  v_program_id      uuid;
  v_lead_teacher_id uuid;
  v_distribution_id uuid;
  v_result          jsonb;
  v_error_code      text;
  v_error_message   text;
begin
  v_actor := public.current_profile();                    -- derive actor internally (no caller actor)
  if v_actor is null then
    return jsonb_build_object('ok',false,'replayed',false,'request_id',p_request_id,
      'action_key',p_action_key,'object_type',p_object_type,'object_id',p_object_id,
      'error',jsonb_build_object('code','MC_ACTION_PERMISSION_DENIED'));
  end if;

  select * into v_row from public.mission_control_action_requests where request_id = p_request_id;
  if not found
     or v_row.actor_id is distinct from v_actor
     or v_row.status <> 'processing'
     or v_row.action_key is distinct from p_action_key
     or v_row.object_id is distinct from p_object_id
  then
    return jsonb_build_object('ok',false,'replayed',false,'request_id',p_request_id,
      'action_key',p_action_key,'object_type',p_object_type,'object_id',p_object_id,
      'error',jsonb_build_object('code','MC_ACTION_REQUEST_CONFLICT'));
  end if;

  begin
    v_program_id      := nullif(p_input->>'program_id','')::uuid;
    v_lead_teacher_id := nullif(p_input->>'lead_teacher_id','')::uuid;
  exception when others then
    v_program_id := null;
  end;

  -- [M4 governance seam inserted here: evaluate_action_policy + evidence write + enforcing branch]

  begin
    v_distribution_id := public.assign_class_distribution(p_object_id, v_program_id, v_lead_teacher_id);

    v_result := jsonb_build_object(
      'ok',true,'replayed',false,'request_id',p_request_id,
      'action_key',p_action_key,'object_type',p_object_type,'object_id',p_object_id,
      'result',jsonb_build_object('class_distribution_id',v_distribution_id),
      'audit',jsonb_build_object('event','CLASS_ASSIGNMENT_CREATED','recorded',true));

    update public.mission_control_action_requests
       set status='completed', result_payload=v_result, error_code=null, completed_at=now()
     where id = v_row.id;                                 -- DEFINER(postgres): finalize succeeds

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
    'ok',false,'replayed',false,'request_id',p_request_id,
    'action_key',p_action_key,'object_type',p_object_type,'object_id',p_object_id,
    'error',jsonb_build_object('code',v_error_code));

  update public.mission_control_action_requests
     set status='failed', result_payload=v_result, error_code=v_error_code, completed_at=now()
   where id = v_row.id;

  return v_result;
end
$fn$;

-- REPLACE execute — FULL body; INVOKER + signature + gates + INSERT + replay preserved;
-- ONLY the fresh-execution tail delegates to commit-core.
CREATE OR REPLACE FUNCTION public.execute_mission_control_action(
  p_action_key text, p_object_id uuid, p_context jsonb, p_input jsonb, p_request_id uuid
) RETURNS jsonb
LANGUAGE plpgsql
SET search_path = ''                                       -- NO SECURITY DEFINER → stays INVOKER
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
    return jsonb_build_object('ok',false,'replayed',false,
      'error',jsonb_build_object('code','MC_ACTION_PERMISSION_DENIED'));
  end if;

  v_actor_id := public.current_profile();
  if v_actor_id is null then
    return jsonb_build_object('ok',false,'replayed',false,
      'error',jsonb_build_object('code','MC_ACTION_PERMISSION_DENIED'));
  end if;

  if p_action_key is distinct from 'class.assign' then
    return jsonb_build_object('ok',false,'replayed',false,
      'error',jsonb_build_object('code','MC_ACTION_NOT_FOUND'));
  end if;

  if p_object_id is null or p_request_id is null then
    return jsonb_build_object('ok',false,'replayed',false,
      'error',jsonb_build_object('code','MC_ACTION_INPUT_INVALID'));
  end if;

  if jsonb_typeof(coalesce(p_context,'null'::jsonb)) is distinct from 'object'
     or not (p_context ? 'school_id')
     or exists (select 1 from jsonb_object_keys(p_context) as k where k <> 'school_id')
  then
    return jsonb_build_object('ok',false,'replayed',false,
      'error',jsonb_build_object('code','MC_ACTION_CONTEXT_DENIED'));
  end if;

  begin
    v_context_school_id := nullif(p_context->>'school_id','')::uuid;
  exception when others then
    return jsonb_build_object('ok',false,'replayed',false,
      'error',jsonb_build_object('code','MC_ACTION_CONTEXT_DENIED'));
  end;

  if jsonb_typeof(coalesce(p_input,'null'::jsonb)) is distinct from 'object'
     or not (p_input ? 'program_id')
     or exists (select 1 from jsonb_object_keys(p_input) as k where k not in ('program_id','lead_teacher_id'))
  then
    return jsonb_build_object('ok',false,'replayed',false,
      'error',jsonb_build_object('code','MC_ACTION_INPUT_INVALID'));
  end if;

  begin
    v_program_id := nullif(p_input->>'program_id','')::uuid;
    v_lead_teacher_id := nullif(p_input->>'lead_teacher_id','')::uuid;
  exception when others then
    return jsonb_build_object('ok',false,'replayed',false,
      'error',jsonb_build_object('code','MC_ACTION_INPUT_INVALID'));
  end;

  if v_program_id is null then
    return jsonb_build_object('ok',false,'replayed',false,
      'error',jsonb_build_object('code','MC_ACTION_INPUT_INVALID'));
  end if;

  select c.school_id into v_school_id from public.classes c where c.id = p_object_id;

  if v_school_id is null then
    return jsonb_build_object('ok',false,'replayed',false,
      'error',jsonb_build_object('code','MC_ACTION_OBJECT_NOT_FOUND'));
  end if;

  if v_context_school_id is distinct from v_school_id then
    return jsonb_build_object('ok',false,'replayed',false,
      'error',jsonb_build_object('code','MC_ACTION_CONTEXT_DENIED'));
  end if;

  insert into public.mission_control_action_requests (
    request_id, action_key, object_type, object_id, status, actor_id, started_at
  )
  values (
    p_request_id, 'class.assign', 'class', p_object_id, 'processing', v_actor_id, now()
  )
  on conflict (request_id) do nothing
  returning id into v_request_pk;

  if v_request_pk is null then
    select * into v_existing from public.mission_control_action_requests r where r.request_id = p_request_id;

    if not found then
      return jsonb_build_object('ok',false,'replayed',false,
        'error',jsonb_build_object('code','MC_ACTION_REQUEST_CONFLICT'));
    end if;

    if v_existing.action_key is distinct from 'class.assign'
       or v_existing.object_type is distinct from 'class'
       or v_existing.object_id is distinct from p_object_id
    then
      return jsonb_build_object('ok',false,'replayed',false,
        'error',jsonb_build_object('code','MC_ACTION_REQUEST_CONFLICT'));
    end if;

    if v_existing.status in ('received','processing') then
      return jsonb_build_object('ok',false,'replayed',true,'request_id',p_request_id,
        'error',jsonb_build_object('code','MC_ACTION_REQUEST_IN_PROGRESS'));
    end if;

    return jsonb_set(
      coalesce(v_existing.result_payload,
        jsonb_build_object('ok',false,
          'error',jsonb_build_object('code',coalesce(v_existing.error_code,'MC_ACTION_EXECUTION_FAILED')))),
      '{replayed}','true'::jsonb,true);
  end if;

  -- ===== M3 CHANGE: delegate execution + finalization to DEFINER commit-core =====
  -- finalize UPDATE needs table UPDATE priv (authenticated lacks it); commit-core runs
  -- as postgres and finalizes. execute remains INVOKER. Corrects real-authenticated path.
  return mc_internal._mc_commit_action(
    p_request_id, 'class.assign', 'class', p_object_id, p_context, p_input
  );
end
$fn$;

-- Drop the unreachable (dead) finalize policy — hygiene, NOT forge closure.
DROP POLICY IF EXISTS mission_control_action_requests_finish_own
  ON public.mission_control_action_requests;

-- =====================================================================
-- BLOCK-2 : ACL HARDEN (D231)
-- =====================================================================
REVOKE ALL ON SCHEMA mc_internal FROM PUBLIC;
GRANT  USAGE ON SCHEMA mc_internal TO authenticated;

REVOKE ALL ON FUNCTION mc_internal._mc_commit_action(uuid,text,text,uuid,jsonb,jsonb) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION mc_internal._mc_commit_action(uuid,text,text,uuid,jsonb,jsonb) TO authenticated;

REVOKE ALL ON FUNCTION public.execute_mission_control_action(text,uuid,jsonb,jsonb,uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.execute_mission_control_action(text,uuid,jsonb,jsonb,uuid) TO authenticated;
-- (prior ACL had no service_role on execute; we do not add it.)

-- =====================================================================
-- BLOCK-3 : VERIFY (structural + postgres-context; RAISE → rollback)
-- =====================================================================
DO $verify$
declare v_exec_secdef boolean; v_core_secdef boolean; v_core_owner text; v_core_cfg text[];
        v_adapter_md5 text; v_anon int;
begin
  select prosecdef into v_exec_secdef from pg_proc
   where oid='public.execute_mission_control_action(text,uuid,jsonb,jsonb,uuid)'::regprocedure;
  if v_exec_secdef then raise exception 'M3 FAIL: execute must remain INVOKER'; end if;

  if to_regprocedure('mc_internal._mc_commit_action(uuid,text,text,uuid,jsonb,jsonb)') is null
     then raise exception 'M3 FAIL: commit-core missing'; end if;
  select prosecdef, pg_get_userbyid(proowner), proconfig
    into v_core_secdef, v_core_owner, v_core_cfg
    from pg_proc where oid='mc_internal._mc_commit_action(uuid,text,text,uuid,jsonb,jsonb)'::regprocedure;
  if not v_core_secdef then raise exception 'M3 FAIL: commit-core must be DEFINER'; end if;
  if v_core_owner <> 'postgres' then raise exception 'M3 FAIL: commit-core owner must be postgres'; end if;
  if v_core_cfg is distinct from array['search_path=""']::text[] then raise exception 'M3 FAIL: commit-core search_path'; end if;

  -- adapter unchanged
  select md5(pg_get_functiondef(oid)) into v_adapter_md5 from pg_proc
   where oid='public.assign_class_distribution(uuid,uuid,uuid)'::regprocedure;
  if v_adapter_md5 is distinct from '03a1510bd827c03a650a3a88312fbe3a' then
    raise exception 'M3 FAIL: adapter changed'; end if;

  -- commit-core not granted to anon
  select count(*) into v_anon from (
    select (aclexplode(coalesce(p.proacl,acldefault('f',p.proowner)))).grantee as g
    from pg_proc p where p.oid='mc_internal._mc_commit_action(uuid,text,text,uuid,jsonb,jsonb)'::regprocedure
  ) x where g::regrole::text='anon';
  if v_anon <> 0 then raise exception 'M3 FAIL: commit-core must not grant anon'; end if;

  -- finish_own removed; insert/select kept
  if exists (select 1 from pg_policies where tablename='mission_control_action_requests'
             and policyname='mission_control_action_requests_finish_own')
     then raise exception 'M3 FAIL: finish_own must be dropped'; end if;
  if not exists (select 1 from pg_policies where tablename='mission_control_action_requests'
                 and policyname='mission_control_action_requests_insert_own_processing')
     or not exists (select 1 from pg_policies where tablename='mission_control_action_requests'
                 and policyname='mission_control_action_requests_select_own')
     then raise exception 'M3 FAIL: insert/select policies must remain'; end if;

  -- client UPDATE on ledger remains false (finalization stays server-side)
  if has_table_privilege('authenticated','public.mission_control_action_requests','UPDATE')
     then raise exception 'M3 FAIL: authenticated must not have ledger UPDATE'; end if;

  -- lifecycle constraint still present (finalize writes conform)
  if not exists (select 1 from pg_constraint
                 where conrelid='public.mission_control_action_requests'::regclass
                   and conname='mission_control_action_requests_lifecycle_check')
     then raise exception 'M3 FAIL: lifecycle_check constraint missing'; end if;

  raise notice 'M3 structural VERIFY PASS — real-authenticated execution PASS is a POST-APPLY gate.';
end $verify$;
-- ===================== END M3 FINAL (NOT APPLIED) ====================
