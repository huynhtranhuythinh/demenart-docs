-- ============================================================================
-- DMA V114B-E3 · WP4-S3 — SESSION RESPONSIBILITY AUTHORITY CUTOVER
-- Migration: v114b_e3_wp4_s3_authority_cutover   (registry 113 -> 114)
-- D92 three-block. apply_migration wraps in one transaction; any RAISE => atomic rollback.
-- ============================================================================
set local timezone = 'UTC';

-- ---------------------------------------------------------------------------
-- BLOCK 1 — PRECONDITIONS (fail-closed on drift)
-- ---------------------------------------------------------------------------
do $block1$
declare
  m_submit text; m_start text; m_detail text; m_lead text;
  n_tables int; n_func int; n_secdef int; n_pol int; n_trig int;
  n_sta int; n_planned int; n_resp int; n_resp_cur int; n_resp_closed int;
  n_backfill int; n_owner int; n_audit_bf int; n_audit_ss int; n_anon int;
begin
  select md5(prosrc) into m_submit from pg_proc p join pg_namespace ns on ns.oid=p.pronamespace
    where ns.nspname='public' and p.proname='submit_session_journal'
      and pg_get_function_identity_arguments(p.oid)='p_session_id uuid, p_summary text, p_follow_up text';
  select md5(prosrc) into m_start from pg_proc p join pg_namespace ns on ns.oid=p.pronamespace
    where ns.nspname='public' and p.proname='start_session' and pg_get_function_identity_arguments(p.oid)='p_session_id uuid';
  select md5(prosrc) into m_detail from pg_proc p join pg_namespace ns on ns.oid=p.pronamespace
    where ns.nspname='public' and p.proname='get_session_detail' and pg_get_function_identity_arguments(p.oid)='p_session_id uuid';
  select md5(prosrc) into m_lead from pg_proc p join pg_namespace ns on ns.oid=p.pronamespace
    where ns.nspname='public' and p.proname='is_session_lead' and pg_get_function_identity_arguments(p.oid)='p_session_id uuid';

  if m_submit is distinct from '8fc9ace1eafb13d28bcf61dc83e8e27d' then raise exception 'P10 drift submit md5=%', m_submit; end if;
  if m_start  is distinct from '9307a5d92ed07707963bad2f62d512f8' then raise exception 'P10 drift start md5=%', m_start; end if;
  if m_detail is distinct from '7f83cfce2c3e71755375efc6070924a2' then raise exception 'P10 drift detail md5=%', m_detail; end if;
  if m_lead   is distinct from '8b4f91dda7e45a3c2c801e70579f702d' then raise exception 'P09 drift is_session_lead md5=%', m_lead; end if;

  select count(*) into n_tables from pg_tables where schemaname='public';
  select count(*) into n_func from pg_proc p join pg_namespace ns on ns.oid=p.pronamespace where ns.nspname='public' and p.prokind='f';
  select count(*) into n_secdef from pg_proc p join pg_namespace ns on ns.oid=p.pronamespace where ns.nspname='public' and p.prokind='f' and p.prosecdef;
  select count(*) into n_pol from pg_policies where schemaname='public';
  select count(*) into n_trig from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace ns on ns.oid=c.relnamespace where ns.nspname='public' and not t.tgisinternal;
  if n_tables<>88 or n_func<>210 or n_secdef<>199 or n_pol<>166 or n_trig<>33
    then raise exception 'P03 inventory drift %/%/%/%/%', n_tables,n_func,n_secdef,n_pol,n_trig; end if;

  select count(*) filter (where true),
         count(*) filter (where assignment_type='planned'),
         count(*) filter (where assignment_type='responsible'),
         count(*) filter (where assignment_type='responsible' and is_current and valid_to is null),
         count(*) filter (where assignment_type='responsible' and (not is_current or valid_to is not null)),
         count(*) filter (where assignment_type='responsible' and assignment_source='migration_responsible_backfill'),
         count(*) filter (where assignment_type='responsible' and assignment_source='migration_owner_attested')
    into n_sta,n_planned,n_resp,n_resp_cur,n_resp_closed,n_backfill,n_owner
    from public.session_teacher_assignments;
  if n_sta<>13 or n_planned<>9 or n_resp<>4 or n_resp_cur<>4 or n_resp_closed<>0 or n_backfill<>3 or n_owner<>1
    then raise exception 'P04/P05 STA drift %/%/%/%/%/bf%/oa%', n_sta,n_planned,n_resp,n_resp_cur,n_resp_closed,n_backfill,n_owner; end if;

  select count(*) into n_audit_bf from public.audit_logs where action='session_responsibility_backfilled';
  select count(*) into n_audit_ss from public.audit_logs where action='session_started';
  if n_audit_bf<>4 then raise exception 'P06 audit backfilled=%', n_audit_bf; end if;
  if n_audit_ss<>3 then raise exception 'P17 malformed session_started=%', n_audit_ss; end if;

  select count(*) into n_anon from pg_proc p join pg_namespace ns on ns.oid=p.pronamespace
    cross join lateral aclexplode(coalesce(p.proacl, acldefault('f',p.proowner))) a
    join pg_roles g on g.oid=a.grantee
    where ns.nspname='public' and g.rolname='anon' and a.privilege_type='EXECUTE';
  if n_anon<>0 then raise exception 'P12 anon EXECUTE count=%', n_anon; end if;

  raise notice 'BLOCK 1 — preconditions PASS (P03/P04/P05/P06/P09/P10/P12/P17)';
end;
$block1$;

-- ---------------------------------------------------------------------------
-- BLOCK 2 — DDL: three CREATE OR REPLACE + ACL hygiene (D15)
-- ---------------------------------------------------------------------------

-- CHANGE A ---------------------------------------------------------------
create or replace function public.submit_session_journal(p_session_id uuid, p_summary text default null::text, p_follow_up text default null::text)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $fn$
declare
  v_state       public.session_state;
  v_school      uuid;
  v_program     uuid;
  v_lv          uuid;
  v_when        timestamptz;
  v_actor       uuid;
  v_responsible uuid;
  v_moments     int := 0;
  v_journey     int := 0;
  v_highlighted jsonb;
  v_to_observe  jsonb;
begin
  -- (S3.1) session existence + gather
  select ls.state, cd.program_id, ls.lesson_version_id, coalesce(ls.scheduled_at, now())
    into v_state, v_program, v_lv, v_when
  from public.lesson_sessions ls
  join public.class_distributions cd on cd.id = ls.class_distribution_id
  where ls.id = p_session_id;
  if not found then
    return jsonb_build_object('ok', false, 'reason', 'session_not_found');
  end if;

  -- (S3.2) caller identity + same-school boundary
  v_actor  := public.current_profile();
  v_school := public.session_school_id(p_session_id);
  if v_actor is null or not public.same_school(v_school) then
    return jsonb_build_object('ok', false, 'reason', 'forbidden');
  end if;

  -- (S3.3) the one current responsible assignment
  select sta.teacher_id into v_responsible
  from public.session_teacher_assignments sta
  where sta.session_id = p_session_id
    and sta.assignment_type = 'responsible'
    and sta.is_current = true
    and sta.valid_to is null;
  if not found then
    return jsonb_build_object('ok', false, 'reason', 'no_responsible_assignment');
  end if;

  -- (S3.4) caller must BE the responsible teacher
  if v_responsible is distinct from v_actor then
    return jsonb_build_object('ok', false, 'reason', 'forbidden');
  end if;

  -- one-source authority established; secondary consistency assertion
  if public.is_session_responsible(p_session_id) is distinct from true then
    raise exception 'submit_session_journal: responsibility assertion failed for %', p_session_id;
  end if;

  -- (S3.5) idempotent branch — still gated by current responsibility above
  if v_state in ('taught_report_pending','report_pending_approval','completed') then
    update public.learning_moments lm set state = 'approved', approved_by = v_actor
    where lm.session_id = p_session_id
      and lm.state in ('draft','pending_approval','needs_revision')
      and exists (select 1 from public.moment_children mc where mc.moment_id = lm.id)
      and exists (select 1 from public.media_assets ma where ma.linked_moment_id = lm.id and ma.state = 'active');
    get diagnostics v_moments = row_count;
    return jsonb_build_object('ok', true, 'already', true, 'moments_approved', v_moments, 'state', v_state);
  end if;

  if v_state <> 'in_progress' then
    return jsonb_build_object('ok', false, 'reason', 'bad_state', 'state', v_state);
  end if;

  -- (1) duyệt moment
  update public.learning_moments lm set state = 'approved', approved_by = v_actor
  where lm.session_id = p_session_id
    and lm.state in ('draft','pending_approval','needs_revision')
    and exists (select 1 from public.moment_children mc where mc.moment_id = lm.id)
    and exists (select 1 from public.media_assets ma where ma.linked_moment_id = lm.id and ma.state = 'active');
  get diagnostics v_moments = row_count;

  -- (2) child_journey (idempotent theo ref_id)
  insert into public.child_journey (child_id, source, entry_type, ref_id, lesson_version_id, program_id, occurred_at)
  select co.child_id, 'demen', 'session', p_session_id, v_lv, v_program, v_when
  from public.child_observations co
  where co.session_id = p_session_id
    and co.attendance in ('present','late')
    and not exists (
      select 1 from public.child_journey j
      where j.ref_id = p_session_id and j.child_id = co.child_id and j.entry_type = 'session'
    );
  get diagnostics v_journey = row_count;

  -- (3) child_skills
  insert into public.child_skills (child_id, skill, signal_count)
  select co.child_id, sc.label_vi, 1
  from public.child_observations co
  cross join lateral jsonb_array_elements_text(coalesce(co.skills_observed, '[]'::jsonb)) as code(val)
  join public.skill_catalog sc on sc.code = code.val
  where co.session_id = p_session_id and co.attendance in ('present','late')
  on conflict (child_id, skill) do update set signal_count = child_skills.signal_count + 1;

  -- (4) session_reports
  v_highlighted := (select coalesce(jsonb_agg(child_id), '[]'::jsonb)
                    from public.child_observations where session_id = p_session_id and is_highlight);
  v_to_observe  := (select coalesce(jsonb_agg(child_id), '[]'::jsonb)
                    from public.child_observations where session_id = p_session_id and (needs_support or follow_up_needed));

  insert into public.session_reports (session_id, summary, highlighted_children, children_to_observe, follow_up, state)
  values (p_session_id, nullif(trim(coalesce(p_summary,'')),''), v_highlighted, v_to_observe,
          nullif(trim(coalesce(p_follow_up,'')),''), 'submitted')
  on conflict (session_id) do update set
    summary = excluded.summary,
    highlighted_children = excluded.highlighted_children,
    children_to_observe = excluded.children_to_observe,
    follow_up = excluded.follow_up,
    state = 'submitted';

  -- (5) chuyển trạng thái buổi
  update public.lesson_sessions set state = 'taught_report_pending' where id = p_session_id;

  -- audit (non-blocking wrap giữ nguyên — D67/D72)
  begin
    perform public.write_audit_log('session_journal_submitted', jsonb_build_object(
      'actor_id', v_actor, 'entity_type','lesson_session', 'entity_id', p_session_id,
      'school_id', v_school,
      'metadata', jsonb_build_object('moments_approved', v_moments, 'journey_created', v_journey)
    ));
  exception when others then null;
  end;

  return jsonb_build_object('ok', true, 'moments_approved', v_moments, 'journey_created', v_journey, 'state', 'taught_report_pending');
end;
$fn$;

-- CHANGE B ---------------------------------------------------------------
create or replace function public.start_session(p_session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $fn$
declare
  v_state         text;
  v_me            uuid := public.current_profile();
  v_school        uuid;
  v_now           timestamptz := now();
  v_assignment_id uuid;
begin
  if v_me is null then
    return jsonb_build_object('ok', false, 'reason', 'not_authenticated');
  end if;

  select ls.state::text into v_state
  from public.lesson_sessions ls where ls.id = p_session_id;
  if not found then
    return jsonb_build_object('ok', false, 'reason', 'not_found');
  end if;

  -- người trong phòng: lead HOẶC teacher của session (gương prep_items write) — giữ nguyên
  if not (public.is_session_lead(p_session_id) or public.is_session_teacher(p_session_id)) then
    return jsonb_build_object('ok', false, 'reason', 'forbidden');
  end if;

  if v_state = 'in_progress' then
    return jsonb_build_object('ok', true, 'already', true, 'state', 'in_progress');
  end if;
  if v_state not in ('scheduled','prep_ready','makeup') then
    return jsonb_build_object('ok', false, 'reason', 'bad_state', 'state', v_state);
  end if;

  -- ĐƯỜNG SINH trách nhiệm (không phải transfer): không được đã tồn tại responsible hiện hành
  if exists (
    select 1 from public.session_teacher_assignments sta
    where sta.session_id = p_session_id
      and sta.assignment_type = 'responsible'
      and sta.is_current = true
      and sta.valid_to is null
  ) then
    return jsonb_build_object('ok', false, 'reason', 'responsibility_conflict');
  end if;

  v_school := public.session_school_id(p_session_id);

  update public.lesson_sessions
    set state = 'in_progress', taught_by = v_me
  where id = p_session_id;

  insert into public.session_teacher_assignments
    (session_id, teacher_id, assignment_type, is_current, valid_from, valid_to,
     assigned_by, assignment_source, superseded_by)
  values
    (p_session_id, v_me, 'responsible', true, v_now, null,
     v_me, 'runtime_start_session', null)
  returning id into v_assignment_id;

  -- audit CHẶN (hành động sinh-thẩm-quyền — KHÔNG nuốt lỗi; S3 atomicity)
  perform public.write_audit_log('session_started', jsonb_build_object(
    'actor_id',    v_me,
    'entity_type', 'lesson_session',
    'entity_id',   p_session_id,
    'school_id',   v_school,
    'metadata',    jsonb_build_object(
      'responsible_assignment_id', v_assignment_id,
      'teacher_id',                v_me,
      'assignment_source',         'runtime_start_session'
    )
  ));

  return jsonb_build_object('ok', true, 'state', 'in_progress');
end;
$fn$;

-- CHANGE C ---------------------------------------------------------------
create or replace function public.get_session_detail(p_session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $fn$
declare
  v_title text; v_state text; v_sched timestamptz; v_dur int;
  v_class_id uuid; v_class_name text; v_program_name text;
  v_school uuid; v_child_count int; v_rd jsonb;
  v_actor uuid;
  v_resp_teacher uuid; v_resp_source text; v_resp_valid_from timestamptz; v_resp_name text;
  v_can_submit boolean; v_block_reason text; v_responsible_teacher jsonb;
begin
  select ls.title, ls.state::text, ls.scheduled_at, ls.duration_min,
         cd.class_id, cl.name, pr.name
    into v_title, v_state, v_sched, v_dur, v_class_id, v_class_name, v_program_name
  from public.lesson_sessions ls
  join public.class_distributions cd on cd.id = ls.class_distribution_id
  join public.classes cl on cl.id = cd.class_id
  left join public.programs pr on pr.id = cd.program_id
  where ls.id = p_session_id;

  if not found then
    return jsonb_build_object('ok', false, 'reason', 'not_found');
  end if;

  v_school := public.session_school_id(p_session_id);
  if not (public.is_admin() or public.same_school(v_school)) then
    return jsonb_build_object('ok', false, 'reason', 'forbidden');
  end if;

  select count(*) into v_child_count
  from public.enrollments en where en.class_id = v_class_id and en.state = 'active';

  v_rd := public.get_session_readiness(p_session_id);

  -- S3: current responsible assignment (only) + evidence grade via canonical mapping
  select sta.teacher_id, sta.assignment_source, sta.valid_from, prf.full_name
    into v_resp_teacher, v_resp_source, v_resp_valid_from, v_resp_name
  from public.session_teacher_assignments sta
  join public.profiles prf on prf.id = sta.teacher_id
  where sta.session_id = p_session_id
    and sta.assignment_type = 'responsible'
    and sta.is_current = true
    and sta.valid_to is null;

  if found then
    v_responsible_teacher := jsonb_build_object(
      'profile_id',        v_resp_teacher,
      'display_name',      v_resp_name,
      'assignment_source', v_resp_source,
      'evidence_grade',    public.dma_assignment_evidence_grade(v_resp_source),
      'valid_from',        v_resp_valid_from
    );
  else
    v_responsible_teacher := null;
  end if;

  -- S3: capability — MIRROR submit_session_journal authority + state gate exactly
  v_actor := public.current_profile();
  if v_actor is null or not public.same_school(v_school) then
    v_can_submit := false; v_block_reason := 'forbidden';
  elsif v_resp_teacher is null then
    v_can_submit := false; v_block_reason := 'no_responsible_assignment';
  elsif v_resp_teacher is distinct from v_actor then
    v_can_submit := false; v_block_reason := 'forbidden';
  elsif v_state not in ('in_progress','taught_report_pending','report_pending_approval','completed') then
    v_can_submit := false; v_block_reason := 'bad_state';
  else
    v_can_submit := true; v_block_reason := null;
  end if;

  return jsonb_build_object(
    'ok', true,
    'can_submit_journal', v_can_submit,
    'submit_block_reason', v_block_reason,
    'responsible_teacher', v_responsible_teacher,
    'session', jsonb_build_object(
      'id', p_session_id, 'title', v_title, 'state', v_state,
      'scheduled_at', v_sched, 'duration_min', v_dur,
      'class_name', v_class_name, 'program_name', v_program_name,
      'child_count', coalesce(v_child_count,0), 'readiness', v_rd
    ),
    'prep_items', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', pi.id, 'label', pi.label, 'is_ready', pi.is_ready, 'sort_order', pi.sort_order
      ) order by pi.sort_order, pi.created_at), '[]'::jsonb)
      from public.prep_items pi where pi.session_id = p_session_id
    )
  );
end;
$fn$;

-- ACL HYGIENE (D15) — reassert intended callers, strip PUBLIC/anon --------
revoke all on function public.submit_session_journal(uuid, text, text) from public;
revoke all on function public.submit_session_journal(uuid, text, text) from anon;
grant  execute on function public.submit_session_journal(uuid, text, text) to authenticated;
grant  execute on function public.submit_session_journal(uuid, text, text) to service_role;

revoke all on function public.start_session(uuid) from public;
revoke all on function public.start_session(uuid) from anon;
grant  execute on function public.start_session(uuid) to authenticated;
grant  execute on function public.start_session(uuid) to service_role;

revoke all on function public.get_session_detail(uuid) from public;
revoke all on function public.get_session_detail(uuid) from anon;
grant  execute on function public.get_session_detail(uuid) to authenticated;
grant  execute on function public.get_session_detail(uuid) to service_role;

-- ---------------------------------------------------------------------------
-- BLOCK 3 — POSTCONDITIONS (fail-closed)
-- ---------------------------------------------------------------------------
do $block3$
declare
  src_submit text; src_start text; cfg_submit text; cfg_start text; cfg_detail text;
  n_sta int; n_planned int; n_resp int; n_anon int; m_lead text;
  n_audit_bf int; n_audit_ss int;
  acl_bad int;
begin
  select prosrc, array_to_string(proconfig,',') into src_submit, cfg_submit
    from pg_proc p join pg_namespace ns on ns.oid=p.pronamespace
    where ns.nspname='public' and p.proname='submit_session_journal'
      and pg_get_function_identity_arguments(p.oid)='p_session_id uuid, p_summary text, p_follow_up text';
  select prosrc, array_to_string(proconfig,',') into src_start, cfg_start
    from pg_proc p join pg_namespace ns on ns.oid=p.pronamespace
    where ns.nspname='public' and p.proname='start_session' and pg_get_function_identity_arguments(p.oid)='p_session_id uuid';
  select array_to_string(proconfig,',') into cfg_detail
    from pg_proc p join pg_namespace ns on ns.oid=p.pronamespace
    where ns.nspname='public' and p.proname='get_session_detail' and pg_get_function_identity_arguments(p.oid)='p_session_id uuid';

  -- V04/V05 search_path
  if cfg_submit is distinct from 'search_path=""' then raise exception 'V04 submit search_path=%', cfg_submit; end if;
  if cfg_start  is distinct from 'search_path=""' then raise exception 'V05 start search_path=%', cfg_start; end if;

  -- V10/V11 prosrc content (submit)
  if position('is_session_responsible' in src_submit)=0 then raise exception 'V10 submit missing is_session_responsible'; end if;
  if position('is_session_lead' in src_submit)<>0 then raise exception 'V11 submit still references is_session_lead'; end if;
  if position('no_responsible_assignment' in src_submit)=0 then raise exception 'V13 submit missing no_responsible_assignment'; end if;

  -- V14 start inserts runtime_start_session responsible
  if position('runtime_start_session' in src_start)=0 then raise exception 'V14 start missing runtime_start_session'; end if;
  if position('session_teacher_assignments' in src_start)=0 then raise exception 'V14 start missing STA insert'; end if;

  -- V07/V08/V09 ACL normalized: no PUBLIC, no anon across the 3 targets
  select count(*) into acl_bad
  from pg_proc p join pg_namespace ns on ns.oid=p.pronamespace
    cross join lateral aclexplode(coalesce(p.proacl, acldefault('f',p.proowner))) a
    left join pg_roles g on g.oid=a.grantee
  where ns.nspname='public'
    and ( (p.proname='submit_session_journal' and pg_get_function_identity_arguments(p.oid)='p_session_id uuid, p_summary text, p_follow_up text')
       or (p.proname='start_session' and pg_get_function_identity_arguments(p.oid)='p_session_id uuid')
       or (p.proname='get_session_detail' and pg_get_function_identity_arguments(p.oid)='p_session_id uuid') )
    and a.privilege_type='EXECUTE'
    and (g.rolname is null or g.rolname='anon');
  if acl_bad<>0 then raise exception 'V08/V09 PUBLIC/anon EXECUTE present on target (n=%)', acl_bad; end if;

  -- V30 global anon EXECUTE count still 0
  select count(*) into n_anon from pg_proc p join pg_namespace ns on ns.oid=p.pronamespace
    cross join lateral aclexplode(coalesce(p.proacl, acldefault('f',p.proowner))) a
    join pg_roles g on g.oid=a.grantee
    where ns.nspname='public' and g.rolname='anon' and a.privilege_type='EXECUTE';
  if n_anon<>0 then raise exception 'V30 anon EXECUTE count=%', n_anon; end if;

  -- V26 is_session_lead untouched
  select md5(prosrc) into m_lead from pg_proc p join pg_namespace ns on ns.oid=p.pronamespace
    where ns.nspname='public' and p.proname='is_session_lead' and pg_get_function_identity_arguments(p.oid)='p_session_id uuid';
  if m_lead is distinct from '8b4f91dda7e45a3c2c801e70579f702d' then raise exception 'V26 is_session_lead md5=%', m_lead; end if;

  -- V21/V22/V23 STA unchanged (non-probe state)
  select count(*), count(*) filter (where assignment_type='planned'), count(*) filter (where assignment_type='responsible')
    into n_sta,n_planned,n_resp from public.session_teacher_assignments;
  if n_sta<>13 or n_planned<>9 or n_resp<>4 then raise exception 'V21-23 STA drift %/%/%', n_sta,n_planned,n_resp; end if;

  -- V24/V25 audit unchanged
  select count(*) into n_audit_bf from public.audit_logs where action='session_responsibility_backfilled';
  select count(*) into n_audit_ss from public.audit_logs where action='session_started';
  if n_audit_bf<>4 then raise exception 'V24 audit backfilled=%', n_audit_bf; end if;
  if n_audit_ss<>3 then raise exception 'V25 malformed session_started=%', n_audit_ss; end if;

  raise notice 'BLOCK 3 — postconditions PASS (V04..V30 load-bearing)';
end;
$block3$;
