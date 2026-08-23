-- ============================================================================
-- MIGRATION ARTIFACT — V128-B20.9 PRE-APPLY CHECKPOINT
-- Name (apply_migration): v128_b20_class_edit_full_field_projection
-- Scope:  B20 Option C · S1 (school-entitlement scoped options) · clear-to-null DEFERRED
-- Effect: complete class.edit projection (name + age_group_id + level_id).
--         Additive projection ONLY. No resolver/executor/authority/adapter/registry change.
--
-- Baseline pin (must hold at apply time):
--   backend tail 20260820122518 · D379 / SYSTEM_MAP v1.67 · FE HEAD 6a0f3504
--
-- Frozen anchors (VERIFY asserts byte-identity — migration fails closed on drift):
--   mc_internal._resolve_authority          56b5e3f5a14360990b51c080ff1da1cb
--   mc_internal._mc_authority_gate          bc5ea1a2b1c090f6e4ec62da0a6dee0e
--   mc_internal._mc_begin_action            54b5af575f1a0aa8217e6eac979d6014
--   mc_internal._mc_commit_action           ce36c5fe109e99a919158a4482940c6a
--   public.execute_mission_control_action   954bcc4087ea0646c60c01cc28717e79
--   public.class_edit_v1                    63f3ab5a56f787f229a607ca30c48c99
--
-- Rollback anchors (target bodies to restore on revert):
--   public.get_mission_control_workspace    87244bafc918007ecdf7c1b8f51e37f0
--   public.get_mission_control_actions      fba330c7a2d6d36171086d9761a0bf23
--
-- STATUS: NOT EXECUTED. Awaiting explicit "APPROVE APPLY V128-B20.8".
-- Apply via apply_migration (single atomic transaction). Any VERIFY assertion
-- RAISE EXCEPTION rolls back the entire migration.
-- ============================================================================

-- ---- BLOCK 1: DDL (CREATE OR REPLACE) --------------------------------------

-- 1a. Workspace projection: expose current age_group_id / level_id (+ labels) to seed edit.
CREATE OR REPLACE FUNCTION public.get_mission_control_workspace(p_object_type text, p_object_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_class public.classes%rowtype;
  v_school_name text;
  v_state jsonb := '[]'::jsonb;
  v_age_group_label text;   -- B20.8 additive
  v_level_label text;       -- B20.8 additive
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', jsonb_build_object('code', 'MC_WORKSPACE_ACCESS_DENIED'));
  end if;

  if p_object_type is distinct from 'class' then
    return jsonb_build_object('ok', false, 'error', jsonb_build_object('code', 'MC_WORKSPACE_UNSUPPORTED'));
  end if;

  if p_object_id is null then
    return jsonb_build_object('ok', false, 'error', jsonb_build_object('code', 'MC_WORKSPACE_NOT_FOUND'));
  end if;

  select c.* into v_class from public.classes c where c.id = p_object_id;
  if not found then
    return jsonb_build_object('ok', false, 'error', jsonb_build_object('code', 'MC_WORKSPACE_NOT_FOUND'));
  end if;

  if not (
    public.is_admin()
    or (public.current_profile_role() in ('master_admin', 'sub_admin') and v_class.school_id = any(public.user_school_ids()))
  ) then
    return jsonb_build_object('ok', false, 'error', jsonb_build_object('code', 'MC_WORKSPACE_ACCESS_DENIED'));
  end if;

  select s.name into v_school_name from public.schools s where s.id = v_class.school_id;
  if v_school_name is null then
    return jsonb_build_object('ok', false, 'error', jsonb_build_object('code', 'MC_WORKSPACE_PROJECTION_FAILED'));
  end if;

  select coalesce(
    (
      select jsonb_build_array(jsonb_build_object('key','program','label','Chương trình','value', x.program_names))
      from (
        select string_agg(distinct p.name, ', ' order by p.name) as program_names
        from public.class_distributions d
        join public.programs p on p.id = d.program_id
        where d.class_id = v_class.id and d.state = 'active'
      ) x
      where x.program_names is not null
    ),
    '[]'::jsonb
  ) into v_state;

  -- B20.8 additive: current-value labels (NULL-safe; SET NULL on delete keeps these consistent)
  select a.label into v_age_group_label from public.age_groups a where a.id = v_class.age_group_id;
  select l.label into v_level_label   from public.levels     l where l.id = v_class.level_id;

  return jsonb_build_object(
    'ok', true,
    'object', jsonb_build_object(
      'type', 'class',
      'id', v_class.id,
      'label', v_class.name,
      'status', v_class.state,
      'age_group_id', v_class.age_group_id,     -- B20.8 additive
      'level_id', v_class.level_id,             -- B20.8 additive
      'age_group_label', v_age_group_label,     -- B20.8 additive
      'level_label', v_level_label              -- B20.8 additive
    ),
    'context', jsonb_build_array(
      jsonb_build_object('key','school_id','label', v_school_name,'value', v_class.school_id)
    ),
    'state', v_state,
    'capabilities', jsonb_build_object('actions', true, 'memory', true)
  );
exception
  when others then
    return jsonb_build_object('ok', false, 'error', jsonb_build_object('code', 'MC_WORKSPACE_PROJECTION_FAILED'));
end;
$function$;

-- 1b. Actions projection: class.edit gains age_group_id + level_id selects (S1 scope).
--     class.assign block is BYTE-PRESERVED.
CREATE OR REPLACE FUNCTION public.get_mission_control_actions(p_object_type text, p_object_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_class public.classes%rowtype;
  v_discovered jsonb;
  v_program_options jsonb := '[]'::jsonb;
  v_teacher_options jsonb := '[]'::jsonb;
  v_items jsonb := '[]'::jsonb;
  v_verdict jsonb; v_action jsonb; v_fields jsonb := '[]'::jsonb; v_field jsonb; v_reg_field jsonb;
  v_edit_verdict jsonb; v_edit_action jsonb;
  v_age_group_options jsonb := '[]'::jsonb;   -- B20.8 additive
  v_level_options jsonb := '[]'::jsonb;       -- B20.8 additive
begin
  if auth.uid() is null then
    return jsonb_build_object('ok', false, 'error', jsonb_build_object('code', 'MC_ACTIONS_ACCESS_DENIED'));
  end if;
  if p_object_type is distinct from 'class' then
    return jsonb_build_object('ok', false, 'error', jsonb_build_object('code', 'MC_ACTIONS_UNSUPPORTED'));
  end if;
  if p_object_id is null then
    return jsonb_build_object('ok', false, 'error', jsonb_build_object('code', 'MC_ACTIONS_NOT_FOUND'));
  end if;
  select c.* into v_class from public.classes c where c.id = p_object_id;
  if not found then
    return jsonb_build_object('ok', false, 'error', jsonb_build_object('code', 'MC_ACTIONS_NOT_FOUND'));
  end if;
  if not (
    public.is_admin()
    or (public.current_profile_role() in ('master_admin','sub_admin') and v_class.school_id = any(public.user_school_ids()))
  ) then
    return jsonb_build_object('ok', false, 'error', jsonb_build_object('code', 'MC_ACTIONS_ACCESS_DENIED'));
  end if;

  v_discovered := public.get_available_actions('class', v_class.id, jsonb_build_object('school_id', v_class.school_id));

  -- class.assign projection (BYTE-PRESERVED)
  if exists (select 1 from jsonb_array_elements(coalesce(v_discovered,'[]'::jsonb)) item where item->>'action_key' = 'class.assign') then
    v_verdict := mc_internal._mc_lookup_action('class', 'class.assign');
    v_action := v_verdict->'action';
    select coalesce(jsonb_agg(jsonb_build_object('value', x.id, 'label', x.name) order by x.name, x.id), '[]'::jsonb)
      into v_program_options
      from (select distinct p.id, p.name from public.programs p
             where public.has_subject_entitlement(v_class.school_id, p.id)
               and not exists (select 1 from public.class_distributions d where d.class_id = v_class.id and d.program_id = p.id and d.state = 'active')) x;
    select coalesce(jsonb_agg(jsonb_build_object('value', x.id, 'label', x.full_name) order by x.full_name, x.id), '[]'::jsonb)
      into v_teacher_options
      from (select p.id, coalesce(nullif(btrim(p.full_name), ''), p.email, p.id::text) as full_name
              from public.profiles p where public.dma_assignable_teacher_reason(p.id, v_class.school_id) is null) x;
    v_fields := '[]'::jsonb;
    for v_reg_field in select value from jsonb_array_elements(v_action->'input_schema'->'fields')
    loop
      v_field := jsonb_build_object(
        'key', v_reg_field->>'key',
        'label', case v_reg_field->>'key' when 'program_id' then 'Program' when 'lead_teacher_id' then 'Lead teacher' else v_reg_field->>'key' end,
        'value_type', v_reg_field->>'value_type',
        'control', v_reg_field->>'control',
        'required', (v_reg_field->>'required')::boolean,
        'options', case v_reg_field->>'key' when 'program_id' then v_program_options when 'lead_teacher_id' then v_teacher_options else '[]'::jsonb end
      );
      if v_reg_field ? 'nullable' then
        v_field := v_field || jsonb_build_object('nullable', (v_reg_field->>'nullable')::boolean);
      end if;
      v_fields := v_fields || jsonb_build_array(v_field);
    end loop;
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'key', v_action->>'action_key',
      'label', 'Assign Program',
      'description', 'Create a class-program distribution',
      'risk_level', v_action->>'risk_level',
      'input_schema', jsonb_build_object('version', v_action->'input_schema'->>'version', 'fields', v_fields)
    ));
  end if;

  -- class.edit projection (name + age_group_id + level_id) — B20.8
  if exists (select 1 from jsonb_array_elements(coalesce(v_discovered,'[]'::jsonb)) item where item->>'action_key' = 'class.edit') then
    v_edit_verdict := mc_internal._mc_lookup_action('class', 'class.edit');
    v_edit_action := v_edit_verdict->'action';

    -- S1: options scoped to programs the SCHOOL is entitled to, UNION the class's current value
    -- (so a seeded value is always selectable), program-qualified labels, ordered program->sort.
    select coalesce(jsonb_agg(jsonb_build_object('value', x.id, 'label', x.label) order by x.program_name, x.sort_key, x.id), '[]'::jsonb)
      into v_age_group_options
      from (
        select a.id, (a.label || ' · ' || p.name) as label, p.name as program_name, a.sort as sort_key
          from public.age_groups a
          join public.programs p on p.id = a.program_id
         where public.has_subject_entitlement(v_class.school_id, a.program_id)
            or a.id = v_class.age_group_id
      ) x;

    select coalesce(jsonb_agg(jsonb_build_object('value', x.id, 'label', x.label) order by x.program_name, x.sort_key, x.id), '[]'::jsonb)
      into v_level_options
      from (
        select l.id, (l.label || ' · ' || p.name) as label, p.name as program_name, l.sort as sort_key
          from public.levels l
          join public.programs p on p.id = l.program_id
         where public.has_subject_entitlement(v_class.school_id, l.program_id)
            or l.id = v_class.level_id
      ) x;

    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'key', v_edit_action->>'action_key',
      'label', 'Edit Class',
      'description', 'Cập nhật thông tin lớp',
      'risk_level', v_edit_action->>'risk_level',
      'input_schema', jsonb_build_object(
        'version', v_edit_action->'input_schema'->>'version',
        'fields', jsonb_build_array(
          jsonb_build_object('key','name','label','Tên lớp','value_type','text','control','text','required',false),
          jsonb_build_object('key','age_group_id','label','Nhóm tuổi','value_type','uuid','control','select','required',false,'nullable',true,'options', v_age_group_options),
          jsonb_build_object('key','level_id','label','Cấp độ','value_type','uuid','control','select','required',false,'nullable',true,'options', v_level_options)
        )
      )
    ));
  end if;

  return jsonb_build_object('ok', true, 'items', v_items);
exception
  when others then
    return jsonb_build_object('ok', false, 'error', jsonb_build_object('code', 'MC_ACTIONS_PROJECTION_FAILED'));
end;
$function$;

-- ---- BLOCK 2: D15 grant restoration (proacl resets silently on REPLACE) -----
REVOKE ALL ON FUNCTION public.get_mission_control_workspace(text, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_mission_control_workspace(text, uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.get_mission_control_actions(text, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_mission_control_actions(text, uuid) TO authenticated;

-- ---- BLOCK 3: VERIFY (fail-closed; any assertion -> whole migration rolls back)
DO $verify$
declare v_md5 text; v_cnt int; v_schema jsonb;
begin
  -- Frozen anchors (must be byte-identical to D379 baseline)
  select md5(pg_get_functiondef('mc_internal._resolve_authority(uuid,text,jsonb,jsonb)'::regprocedure)) into v_md5;
  if v_md5 <> '56b5e3f5a14360990b51c080ff1da1cb' then raise exception 'ANCHOR DRIFT _resolve_authority=%', v_md5; end if;
  select md5(pg_get_functiondef('mc_internal._mc_authority_gate(uuid,text,jsonb,jsonb)'::regprocedure)) into v_md5;
  if v_md5 <> 'bc5ea1a2b1c090f6e4ec62da0a6dee0e' then raise exception 'ANCHOR DRIFT _mc_authority_gate=%', v_md5; end if;
  select md5(pg_get_functiondef('mc_internal._mc_begin_action(uuid,text,text,uuid,uuid,uuid,uuid,jsonb)'::regprocedure)) into v_md5;
  if v_md5 <> '54b5af575f1a0aa8217e6eac979d6014' then raise exception 'ANCHOR DRIFT _mc_begin_action=%', v_md5; end if;
  select md5(pg_get_functiondef('mc_internal._mc_commit_action(uuid,jsonb)'::regprocedure)) into v_md5;
  if v_md5 <> 'ce36c5fe109e99a919158a4482940c6a' then raise exception 'ANCHOR DRIFT _mc_commit_action=%', v_md5; end if;
  select md5(pg_get_functiondef('public.execute_mission_control_action(text,uuid,jsonb,jsonb,uuid)'::regprocedure)) into v_md5;
  if v_md5 <> '954bcc4087ea0646c60c01cc28717e79' then raise exception 'ANCHOR DRIFT execute_mission_control_action=%', v_md5; end if;
  select md5(pg_get_functiondef('public.class_edit_v1(uuid,jsonb)'::regprocedure)) into v_md5;
  if v_md5 <> '63f3ab5a56f787f229a607ca30c48c99' then raise exception 'ANCHOR DRIFT class_edit_v1=%', v_md5; end if;

  -- Registry integrity (no registry mutation in this migration)
  select count(*) into v_cnt from public.mission_control_action_registry;
  if v_cnt <> 4 then raise exception 'REGISTRY COUNT DRIFT=%', v_cnt; end if;
  select input_schema into v_schema from public.mission_control_action_registry where action_key='class.edit';
  if v_schema->>'version' <> 'MissionActionInputSchema/v1' then raise exception 'class.edit schema version drift'; end if;
  if (select count(*) from jsonb_array_elements(v_schema->'fields')) <> 3 then raise exception 'class.edit schema field-count drift'; end if;

  -- Signatures / attributes unchanged on the two replaced functions
  perform 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname='get_mission_control_workspace'
      and pg_get_function_identity_arguments(p.oid)='p_object_type text, p_object_id uuid'
      and p.prosecdef and p.provolatile='s';
  if not found then raise exception 'workspace signature/attrs drift'; end if;
  perform 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname='get_mission_control_actions'
      and pg_get_function_identity_arguments(p.oid)='p_object_type text, p_object_id uuid'
      and p.prosecdef and p.provolatile='s';
  if not found then raise exception 'actions signature/attrs drift'; end if;

  -- Intended new bodies actually installed
  if pg_get_functiondef('public.get_mission_control_workspace(text,uuid)'::regprocedure) not like '%age_group_label%'
    then raise exception 'workspace body missing age_group_label'; end if;
  if pg_get_functiondef('public.get_mission_control_actions(text,uuid)'::regprocedure) not like '%v_age_group_options%'
    then raise exception 'actions body missing age-group options'; end if;

  -- D15 grant integrity (authenticated EXECUTE present on both)
  perform 1 from aclexplode((select coalesce(proacl, acldefault('f',proowner)) from pg_proc where oid='public.get_mission_control_workspace(text,uuid)'::regprocedure)) a
    join pg_roles r on r.oid=a.grantee where r.rolname='authenticated' and a.privilege_type='EXECUTE';
  if not found then raise exception 'workspace missing authenticated EXECUTE'; end if;
  perform 1 from aclexplode((select coalesce(proacl, acldefault('f',proowner)) from pg_proc where oid='public.get_mission_control_actions(text,uuid)'::regprocedure)) a
    join pg_roles r on r.oid=a.grantee where r.rolname='authenticated' and a.privilege_type='EXECUTE';
  if not found then raise exception 'actions missing authenticated EXECUTE'; end if;

  raise notice 'V128-B20.8 VERIFY PASS';
end
$verify$;

NOTIFY pgrst, 'reload schema';   -- D289 (signatures unchanged; included for discipline)

-- ============================================================================
-- END MIGRATION ARTIFACT — NOT EXECUTED (V128-B20.9 checkpoint)
-- ============================================================================
