-- =====================================================================
-- V128-B7 PHASE C — DECISION GATE EXECUTION INTEGRATION
-- MIGRATION ARTIFACT (ASSEMBLY ONLY — NOT APPLIED)
-- =====================================================================
-- CTO-approved: C-1 Option A (5 new decision codes) · C-2 Option b (same
-- execute/request_id resume + explicit original-actor guard) · C-3 Option B
-- (approval binds to opener, RLS-enforced) · C-4 Option A (decision
-- authoritative; ledger stays 'processing'; single execute replace).
--
-- Baseline (re-pinned live, tail 20260815151633):
--   execute md5 = 7a526354c820ab5f767ee7403c6e917d  (INVOKER, search_path='')
--   FROZEN helpers (unchanged by this migration):
--     _mc_begin_action   f47260ef3f06811ac2e83807989b26c7
--     _mc_commit_action  ce36c5fe109e99a919158a4482940c6a
--     _mc_lookup_action  5d940037687be0a398a232cf987bfcf6
--     _mc_open_decision  e5b12a9675093ad2d93a2c33943bea77
--   inventory 93·251·239·168·33·1 · mc_internal 5 · decisions 0 rows
--
-- Constraints honored: signature unchanged · SECURITY INVOKER unchanged ·
-- search_path='' unchanged · NO schema/helper/ledger/adapter/registry/FE change.
-- Expected inventory delta: NET ZERO (single CREATE OR REPLACE).
-- Rollback: restore execute to md5 7a526354c820ab5f767ee7403c6e917d (see rollback file).
-- =====================================================================


-- =====================================================================
-- BLOCK 1 — DDL (CREATE OR REPLACE, single object)
-- =====================================================================
CREATE OR REPLACE FUNCTION public.execute_mission_control_action(p_action_key text, p_object_id uuid, p_context jsonb, p_input jsonb, p_request_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  v_actor_id uuid; v_existing public.mission_control_action_requests%rowtype;
  v_school_id uuid; v_context_school_id uuid; v_program_id uuid; v_lead_teacher_id uuid;
  v_distribution_id uuid; v_result jsonb; v_error_code text; v_error_message text; v_failed boolean := false;
  v_verdict jsonb; v_action jsonb; v_adapter_key text; v_required_context jsonb; v_input_schema jsonb;
  v_begin jsonb; v_inserted boolean := false; v_fp text;
  -- B7 Phase C additions (governed decision gate)
  v_risk text; v_open jsonb; v_governed jsonb := null;
  v_dec_id uuid; v_dec_state text; v_dec_expires timestamptz; v_dec_reason text; v_eff_state text;
begin
  if auth.uid() is null then
    return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_PERMISSION_DENIED'));
  end if;
  v_actor_id := public.current_profile();
  if v_actor_id is null then
    return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_PERMISSION_DENIED'));
  end if;

  v_verdict := mc_internal._mc_lookup_action('class', p_action_key);
  if not coalesce((v_verdict->>'found')::boolean,false) or not coalesce((v_verdict->>'dispatchable')::boolean,false) then
    return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_NOT_FOUND'));
  end if;
  v_action := v_verdict->'action';
  v_adapter_key := v_action->>'adapter_key';
  v_required_context := v_action->'required_context';
  v_input_schema := v_action->'input_schema';
  v_risk := v_action->>'risk_level';   -- B7-C: read risk from whitelisted lookup field (no lookup change)

  if p_object_id is null or p_request_id is null then
    return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_INPUT_INVALID'));
  end if;

  if jsonb_typeof(coalesce(p_context,'null'::jsonb)) is distinct from 'object' then
    return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_CONTEXT_DENIED'));
  end if;
  if exists (select 1 from jsonb_array_elements_text(v_required_context->'keys') rk where not (p_context ? rk)) then
    return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_CONTEXT_DENIED'));
  end if;
  if coalesce((v_required_context->>'exclusive')::boolean,false)
     and exists (select 1 from jsonb_object_keys(p_context) k where not ((v_required_context->'keys') @> to_jsonb(k))) then
    return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_CONTEXT_DENIED'));
  end if;
  if exists (select 1 from jsonb_each_text(coalesce(v_required_context->'types','{}'::jsonb)) t where t.value <> 'uuid') then
    return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_EXECUTION_FAILED'));
  end if;
  begin v_context_school_id := nullif(p_context->>'school_id','')::uuid;
  exception when others then
    return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_CONTEXT_DENIED'));
  end;

  if v_input_schema->>'version' is distinct from 'MissionActionInputSchema/v1' then
    return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_EXECUTION_FAILED'));
  end if;
  if jsonb_typeof(coalesce(p_input,'null'::jsonb)) is distinct from 'object' then
    return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_INPUT_INVALID'));
  end if;
  if exists (select 1 from jsonb_object_keys(p_input) k where not exists (select 1 from jsonb_array_elements(v_input_schema->'fields') f where f->>'key' = k)) then
    return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_INPUT_INVALID'));
  end if;
  if exists (select 1 from jsonb_array_elements(v_input_schema->'fields') f where (f->>'required')::boolean and not (p_input ? (f->>'key'))) then
    return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_INPUT_INVALID'));
  end if;
  begin
    v_program_id := nullif(p_input->>'program_id','')::uuid;
    v_lead_teacher_id := nullif(p_input->>'lead_teacher_id','')::uuid;
  exception when others then
    return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_INPUT_INVALID'));
  end;
  if v_program_id is null then
    return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_INPUT_INVALID'));
  end if;

  select c.school_id into v_school_id from public.classes c where c.id = p_object_id;
  if v_school_id is null then
    return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_OBJECT_NOT_FOUND'));
  end if;
  if v_context_school_id is distinct from v_school_id then
    return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_CONTEXT_DENIED'));
  end if;

  v_result := null; v_error_code := null; v_failed := false; v_inserted := false;

  begin
    v_begin := mc_internal._mc_begin_action(p_request_id, p_action_key, 'class', p_object_id, v_context_school_id, v_program_id, v_lead_teacher_id);
    v_fp := v_begin->>'intent_fingerprint';
    v_inserted := (v_begin->>'inserted')::boolean;
    if v_inserted then
      -- ============================================================
      -- B7-C DECISION GATE (fresh path): after _mc_begin_action, before adapter.
      -- ============================================================
      if v_risk in ('HIGH','CRITICAL') then
        v_open := mc_internal._mc_open_decision(p_request_id);   -- SECDEF; may RAISE no_eligible_approver
        -- Read decision state (INVOKER SELECT, RLS select_own => caller-readable only).
        select d.id, d.state, d.expires_at, d.decision_reason
          into v_dec_id, v_dec_state, v_dec_expires, v_dec_reason
          from public.mission_control_decisions d
          where d.intent_fingerprint = v_fp;
        if not found then
          -- C-3 Option B: decision opened by a different requester on same fingerprint
          -- (RLS-hidden). Fail-closed: do not execute; park.
          v_governed := jsonb_build_object('ok',false,'replayed',false,'request_id',p_request_id,
            'action_key',p_action_key,'object_type','class','object_id',p_object_id,
            'error',jsonb_build_object('code','MC_ACTION_DECISION_REQUIRED'),
            'decision',jsonb_build_object('id',(v_open->>'decision_id')));
        else
          -- effective expiry (execute is INVOKER + SELECT-only on decisions: read-only, no flip)
          if v_dec_state = 'pending' and now() > v_dec_expires then v_eff_state := 'expired'; else v_eff_state := v_dec_state; end if;
          if v_eff_state = 'approved' then
            v_governed := null;   -- resume: fall through to adapter below
          elsif v_eff_state = 'pending' then
            v_governed := jsonb_build_object('ok',false,'replayed',false,'request_id',p_request_id,
              'action_key',p_action_key,'object_type','class','object_id',p_object_id,
              'error',jsonb_build_object('code','MC_ACTION_DECISION_REQUIRED'),
              'decision',jsonb_build_object('id',v_dec_id,'state','pending','expires_at',v_dec_expires));
          elsif v_eff_state = 'rejected' then
            v_governed := jsonb_build_object('ok',false,'replayed',false,'request_id',p_request_id,
              'action_key',p_action_key,'object_type','class','object_id',p_object_id,
              'error',jsonb_build_object('code','MC_ACTION_DECISION_REJECTED'),
              'decision',jsonb_build_object('id',v_dec_id,'state','rejected','expires_at',v_dec_expires,'reason',v_dec_reason));
          elsif v_eff_state = 'expired' then
            v_governed := jsonb_build_object('ok',false,'replayed',false,'request_id',p_request_id,
              'action_key',p_action_key,'object_type','class','object_id',p_object_id,
              'error',jsonb_build_object('code','MC_ACTION_DECISION_EXPIRED'),
              'decision',jsonb_build_object('id',v_dec_id,'state','expired','expires_at',v_dec_expires));
          elsif v_eff_state = 'cancelled' then
            v_governed := jsonb_build_object('ok',false,'replayed',false,'request_id',p_request_id,
              'action_key',p_action_key,'object_type','class','object_id',p_object_id,
              'error',jsonb_build_object('code','MC_ACTION_DECISION_CANCELLED'),
              'decision',jsonb_build_object('id',v_dec_id,'state','cancelled','expires_at',v_dec_expires,'reason',v_dec_reason));
          else
            raise exception 'decision_state_unsupported';   -- control-plane guard (unreachable; state CHECK-bounded)
          end if;
        end if;
        if v_governed is not null then
          return v_governed;   -- NORMAL return: retains ledger 'processing' + decision rows (C-4 Option A)
        end if;
        -- else v_eff_state='approved' -> fall through to adapter (resume within fresh call)
      end if;
      -- ============================================================
      -- AUTO path (LOW/MEDIUM) OR approved-resume: unchanged adapter + commit.
      -- ============================================================
      case v_adapter_key
        when 'class.assign.v1' then
          v_distribution_id := public.assign_class_distribution(p_object_id, v_program_id, v_lead_teacher_id);
        else
          raise exception 'adapter_unresolved';
      end case;
      v_result := jsonb_build_object(
        'ok',true,'replayed',false,'request_id',p_request_id,
        'action_key',p_action_key,'object_type','class','object_id',p_object_id,
        'result',jsonb_build_object('class_distribution_id',v_distribution_id),
        'audit',jsonb_build_object('event','CLASS_ASSIGNMENT_CREATED','recorded',true));
      perform mc_internal._mc_commit_action(p_request_id, v_result);
    end if;
  exception
    when unique_violation then v_error_code := 'MC_ACTION_CONFLICT'; v_failed := true;
    when others then
      get stacked diagnostics v_error_message = message_text;
      v_error_code := case v_error_message
        when 'not_authorized_for_school' then 'MC_ACTION_PERMISSION_DENIED'
        when 'distribution_exists' then 'MC_ACTION_CONFLICT'
        when 'class_not_found' then 'MC_ACTION_OBJECT_NOT_FOUND'
        when 'subject_not_entitled' then 'MC_ACTION_INPUT_INVALID'
        when 'lead_teacher_invalid' then 'MC_ACTION_INPUT_INVALID'
        when 'no_eligible_approver' then 'MC_ACTION_NO_ELIGIBLE_APPROVER'   -- B7-C: fail-closed governance
        else 'MC_ACTION_EXECUTION_FAILED' end;
      v_failed := true;
  end;

  if v_failed then
    return jsonb_build_object('ok',false,'replayed',false,'request_id',p_request_id,
      'action_key',p_action_key,'object_type','class','object_id',p_object_id,
      'error',jsonb_build_object('code',v_error_code));
  end if;

  if not v_inserted then
    select * into v_existing from public.mission_control_action_requests r where r.request_id = p_request_id;
    if not found then
      return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_REQUEST_CONFLICT'));
    end if;
    if v_existing.action_key is distinct from p_action_key
       or v_existing.object_type is distinct from 'class'
       or v_existing.object_id is distinct from p_object_id then
      return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_REQUEST_CONFLICT'));
    end if;
    if v_existing.intent_fingerprint is null then
      return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_REQUEST_CONFLICT'));
    end if;
    if v_existing.intent_hash_version is distinct from 1 then
      return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_REQUEST_CONFLICT'));
    end if;
    if v_existing.intent_fingerprint is distinct from v_fp then
      return jsonb_build_object('ok',false,'replayed',false,'error',jsonb_build_object('code','MC_ACTION_REQUEST_CONFLICT'));
    end if;

    -- ============================================================
    -- B7-C DECISION GATE (replay/park path): fp matched -> inspect decision
    -- BEFORE generic in-progress/terminal handling. Replay is owner-only
    -- (ledger RLS select_own), so decision is caller-readable when present.
    -- ============================================================
    if v_risk in ('HIGH','CRITICAL') then
      select d.id, d.state, d.expires_at, d.decision_reason
        into v_dec_id, v_dec_state, v_dec_expires, v_dec_reason
        from public.mission_control_decisions d
        where d.intent_fingerprint = v_fp;
      if found then
        if v_dec_state = 'pending' and now() > v_dec_expires then v_eff_state := 'expired'; else v_eff_state := v_dec_state; end if;
        if v_eff_state = 'pending' then
          return jsonb_build_object('ok',false,'replayed',true,'request_id',p_request_id,
            'action_key',p_action_key,'object_type','class','object_id',p_object_id,
            'error',jsonb_build_object('code','MC_ACTION_DECISION_REQUIRED'),
            'decision',jsonb_build_object('id',v_dec_id,'state','pending','expires_at',v_dec_expires));
        elsif v_eff_state = 'rejected' then
          return jsonb_build_object('ok',false,'replayed',true,'request_id',p_request_id,
            'action_key',p_action_key,'object_type','class','object_id',p_object_id,
            'error',jsonb_build_object('code','MC_ACTION_DECISION_REJECTED'),
            'decision',jsonb_build_object('id',v_dec_id,'state','rejected','expires_at',v_dec_expires,'reason',v_dec_reason));
        elsif v_eff_state = 'expired' then
          return jsonb_build_object('ok',false,'replayed',true,'request_id',p_request_id,
            'action_key',p_action_key,'object_type','class','object_id',p_object_id,
            'error',jsonb_build_object('code','MC_ACTION_DECISION_EXPIRED'),
            'decision',jsonb_build_object('id',v_dec_id,'state','expired','expires_at',v_dec_expires));
        elsif v_eff_state = 'cancelled' then
          return jsonb_build_object('ok',false,'replayed',true,'request_id',p_request_id,
            'action_key',p_action_key,'object_type','class','object_id',p_object_id,
            'error',jsonb_build_object('code','MC_ACTION_DECISION_CANCELLED'),
            'decision',jsonb_build_object('id',v_dec_id,'state','cancelled','expires_at',v_dec_expires,'reason',v_dec_reason));
        elsif v_eff_state = 'approved' then
          -- C-2: explicit original-actor guard (only original requester resumes)
          if v_existing.actor_id is distinct from v_actor_id then
            return jsonb_build_object('ok',false,'replayed',true,'request_id',p_request_id,
              'action_key',p_action_key,'object_type','class','object_id',p_object_id,
              'error',jsonb_build_object('code','MC_ACTION_REQUEST_CONFLICT'));
          end if;
          -- RESUME: adapter + commit under original actor, wrapped for β2 rollback safety.
          begin
            case v_adapter_key
              when 'class.assign.v1' then
                v_distribution_id := public.assign_class_distribution(p_object_id, v_program_id, v_lead_teacher_id);
              else
                raise exception 'adapter_unresolved';
            end case;
            v_result := jsonb_build_object(
              'ok',true,'replayed',true,'request_id',p_request_id,
              'action_key',p_action_key,'object_type','class','object_id',p_object_id,
              'result',jsonb_build_object('class_distribution_id',v_distribution_id),
              'audit',jsonb_build_object('event','CLASS_ASSIGNMENT_CREATED','recorded',true));
            perform mc_internal._mc_commit_action(p_request_id, v_result);   -- commit re-checks actor ownership
          exception
            when unique_violation then
              return jsonb_build_object('ok',false,'replayed',true,'request_id',p_request_id,
                'action_key',p_action_key,'object_type','class','object_id',p_object_id,
                'error',jsonb_build_object('code','MC_ACTION_CONFLICT'));
            when others then
              get stacked diagnostics v_error_message = message_text;
              v_error_code := case v_error_message
                when 'not_authorized_for_school' then 'MC_ACTION_PERMISSION_DENIED'
                when 'distribution_exists' then 'MC_ACTION_CONFLICT'
                when 'class_not_found' then 'MC_ACTION_OBJECT_NOT_FOUND'
                when 'subject_not_entitled' then 'MC_ACTION_INPUT_INVALID'
                when 'lead_teacher_invalid' then 'MC_ACTION_INPUT_INVALID'
                else 'MC_ACTION_EXECUTION_FAILED' end;
              return jsonb_build_object('ok',false,'replayed',true,'request_id',p_request_id,
                'action_key',p_action_key,'object_type','class','object_id',p_object_id,
                'error',jsonb_build_object('code',v_error_code));
          end;
          return v_result;
        else
          return jsonb_build_object('ok',false,'replayed',true,'request_id',p_request_id,'error',jsonb_build_object('code','MC_ACTION_EXECUTION_FAILED'));
        end if;
      end if;
      -- not found: no caller-readable decision -> fall through to generic handling (LOW/MEDIUM-equivalent)
    end if;

    if v_existing.status in ('received','processing') then
      return jsonb_build_object('ok',false,'replayed',true,'request_id',p_request_id,'error',jsonb_build_object('code','MC_ACTION_REQUEST_IN_PROGRESS'));
    end if;
    return jsonb_set(coalesce(v_existing.result_payload,
      jsonb_build_object('ok',false,'error',jsonb_build_object('code',coalesce(v_existing.error_code,'MC_ACTION_EXECUTION_FAILED')))),
      '{replayed}','true'::jsonb,true);
  end if;

  return v_result;
end;
$function$;


-- =====================================================================
-- BLOCK 2 — REVOKE/GRANT re-harden (D15: proacl resets on REPLACE)
-- =====================================================================
REVOKE ALL ON FUNCTION public.execute_mission_control_action(text, uuid, jsonb, jsonb, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.execute_mission_control_action(text, uuid, jsonb, jsonb, uuid) FROM anon;
REVOKE ALL ON FUNCTION public.execute_mission_control_action(text, uuid, jsonb, jsonb, uuid) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.execute_mission_control_action(text, uuid, jsonb, jsonb, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.execute_mission_control_action(text, uuid, jsonb, jsonb, uuid) TO postgres;
-- Signature unchanged => PostgREST schema reload not strictly required; issued per D289 habit.
NOTIFY pgrst, 'reload schema';


-- =====================================================================
-- BLOCK 3 — VERIFY (fail-closed; structural only; never calls gated fn — D92)
-- =====================================================================
DO $verify$
DECLARE
  v_def text;
  v_cnt int;
BEGIN
  -- (1) execute posture: INVOKER + search_path=''
  IF (SELECT prosecdef FROM pg_proc WHERE oid='public.execute_mission_control_action'::regproc) IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'VERIFY FAIL: execute must remain SECURITY INVOKER';
  END IF;
  IF (SELECT option_value FROM pg_proc p, pg_options_to_table(p.proconfig)
        WHERE p.oid='public.execute_mission_control_action'::regproc AND option_name='search_path') IS DISTINCT FROM '""' THEN
    RAISE EXCEPTION 'VERIFY FAIL: execute search_path must be empty';
  END IF;

  -- (2) execute ACL: authenticated=EXECUTE; NO anon; NO PUBLIC
  IF NOT EXISTS (SELECT 1 FROM pg_proc p CROSS JOIN LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
      WHERE p.oid='public.execute_mission_control_action'::regproc AND a.grantee='authenticated'::regrole AND a.privilege_type='EXECUTE') THEN
    RAISE EXCEPTION 'VERIFY FAIL: authenticated missing EXECUTE';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc p CROSS JOIN LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
      WHERE p.oid='public.execute_mission_control_action'::regproc AND a.grantee='anon'::regrole) THEN
    RAISE EXCEPTION 'VERIFY FAIL: anon has grant on execute';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc p CROSS JOIN LATERAL aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
      WHERE p.oid='public.execute_mission_control_action'::regproc AND a.grantee=0) THEN
    RAISE EXCEPTION 'VERIFY FAIL: PUBLIC has grant on execute';
  END IF;

  v_def := pg_get_functiondef('public.execute_mission_control_action'::regproc);

  -- (3) new decision codes present (C-1 Option A)
  IF v_def NOT LIKE '%MC_ACTION_DECISION_REQUIRED%'  THEN RAISE EXCEPTION 'VERIFY FAIL: missing MC_ACTION_DECISION_REQUIRED';  END IF;
  IF v_def NOT LIKE '%MC_ACTION_DECISION_REJECTED%'  THEN RAISE EXCEPTION 'VERIFY FAIL: missing MC_ACTION_DECISION_REJECTED';  END IF;
  IF v_def NOT LIKE '%MC_ACTION_DECISION_EXPIRED%'   THEN RAISE EXCEPTION 'VERIFY FAIL: missing MC_ACTION_DECISION_EXPIRED';   END IF;
  IF v_def NOT LIKE '%MC_ACTION_DECISION_CANCELLED%' THEN RAISE EXCEPTION 'VERIFY FAIL: missing MC_ACTION_DECISION_CANCELLED'; END IF;
  IF v_def NOT LIKE '%MC_ACTION_NO_ELIGIBLE_APPROVER%' THEN RAISE EXCEPTION 'VERIFY FAIL: missing MC_ACTION_NO_ELIGIBLE_APPROVER'; END IF;

  -- (4) gate wiring: opens decision via helper; original-actor guard present
  IF v_def NOT LIKE '%mc_internal._mc_open_decision(p_request_id)%' THEN RAISE EXCEPTION 'VERIFY FAIL: decision open helper not wired'; END IF;
  IF v_def NOT LIKE '%v_existing.actor_id is distinct from v_actor_id%' THEN RAISE EXCEPTION 'VERIFY FAIL: original-actor resume guard missing'; END IF;

  -- (5) execute must NOT write decisions (INVOKER + SELECT-only grant); read-only only
  IF v_def ILIKE '%insert into public.mission_control_decisions%'
     OR v_def ILIKE '%update public.mission_control_decisions%'
     OR v_def ILIKE '%delete from public.mission_control_decisions%' THEN
    RAISE EXCEPTION 'VERIFY FAIL: execute must not write mission_control_decisions';
  END IF;

  -- (6) FROZEN helpers unchanged (md5 of full functiondef)
  IF md5(pg_get_functiondef('mc_internal._mc_begin_action'::regproc))  <> 'f47260ef3f06811ac2e83807989b26c7' THEN RAISE EXCEPTION 'VERIFY FAIL: _mc_begin_action drifted';  END IF;
  IF md5(pg_get_functiondef('mc_internal._mc_commit_action'::regproc)) <> 'ce36c5fe109e99a919158a4482940c6a' THEN RAISE EXCEPTION 'VERIFY FAIL: _mc_commit_action drifted'; END IF;
  IF md5(pg_get_functiondef('mc_internal._mc_lookup_action'::regproc)) <> '5d940037687be0a398a232cf987bfcf6' THEN RAISE EXCEPTION 'VERIFY FAIL: _mc_lookup_action drifted'; END IF;
  IF md5(pg_get_functiondef('mc_internal._mc_open_decision'::regproc)) <> 'e5b12a9675093ad2d93a2c33943bea77' THEN RAISE EXCEPTION 'VERIFY FAIL: _mc_open_decision drifted'; END IF;

  -- (7) registry unchanged (risk levels / status)
  IF (SELECT risk_level||'/'||status FROM public.mission_control_action_registry WHERE action_key='class.assign') <> 'MEDIUM/active' THEN RAISE EXCEPTION 'VERIFY FAIL: class.assign registry drifted'; END IF;
  IF (SELECT risk_level||'/'||status FROM public.mission_control_action_registry WHERE action_key='class.edit')  <> 'LOW/disabled'  THEN RAISE EXCEPTION 'VERIFY FAIL: class.edit registry drifted';  END IF;

  -- (8) inventory net-zero vs baseline
  SELECT count(*) INTO v_cnt FROM pg_tables WHERE schemaname='public';
  IF v_cnt <> 93 THEN RAISE EXCEPTION 'VERIFY FAIL: tables % <> 93', v_cnt; END IF;
  SELECT count(*) INTO v_cnt FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.prokind='f';
  IF v_cnt <> 251 THEN RAISE EXCEPTION 'VERIFY FAIL: public fns % <> 251', v_cnt; END IF;
  SELECT count(*) INTO v_cnt FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.prokind='f' AND p.prosecdef;
  IF v_cnt <> 239 THEN RAISE EXCEPTION 'VERIFY FAIL: public secdef % <> 239', v_cnt; END IF;
  SELECT count(*) INTO v_cnt FROM pg_policies WHERE schemaname='public';
  IF v_cnt <> 168 THEN RAISE EXCEPTION 'VERIFY FAIL: policies % <> 168', v_cnt; END IF;
  SELECT count(*) INTO v_cnt FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE NOT t.tgisinternal AND n.nspname='public';
  IF v_cnt <> 33 THEN RAISE EXCEPTION 'VERIFY FAIL: triggers % <> 33', v_cnt; END IF;
  SELECT count(*) INTO v_cnt FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='mc_internal' AND p.prokind='f';
  IF v_cnt <> 5 THEN RAISE EXCEPTION 'VERIFY FAIL: mc_internal fns % <> 5', v_cnt; END IF;

  -- (9) ledger unchanged: no awaiting_decision status; intent + terminal check intact
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.mission_control_action_requests'::regclass
             AND contype='c' AND pg_get_constraintdef(oid) ILIKE '%awaiting_decision%') THEN
    RAISE EXCEPTION 'VERIFY FAIL: awaiting_decision status introduced (G-C violation)';
  END IF;

  RAISE NOTICE 'V128-B7 PHASE C VERIFY: PASS';
END
$verify$;
