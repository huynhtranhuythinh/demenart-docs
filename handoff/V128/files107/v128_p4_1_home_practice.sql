-- ============================================================================
-- MIGRATION ARTIFACT — V128-P4.1 HOME PRACTICE (Luyện ở nhà)
-- name (apply later): v128_p4_1_home_practice
-- Owner gate: A evolve-in-place · no author column · assigned_at = created_at
-- STATUS: ARTIFACT ONLY — NOT APPLIED TO PRODUCTION (Phase 1 stop gate)
-- Pattern: D92 three-block (DDL -> REVOKE/GRANT harden -> fail-closed VERIFY)
-- D15 grants reset on CREATE OR REPLACE -> explicit REVOKE/GRANT every function
-- D289 pgrst reload after functions/policies
-- Additive/nullable only (J): no backfill, no standalone homework table
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BLOCK 1 — DDL
-- ---------------------------------------------------------------------------

-- 1a. Additive Home Practice persistence on the existing 1-1 substrate.
alter table public.session_reports
  add column if not exists home_practice_title text,
  add column if not exists home_practice_body  text;

-- 1b. Server-side content contract (both-null OR both-present with bounds).
--     Existing rows are all-null -> satisfy the "both null" branch (no backfill).
alter table public.session_reports
  drop constraint if exists session_reports_home_practice_ck;
alter table public.session_reports
  add constraint session_reports_home_practice_ck check (
    (home_practice_title is null and home_practice_body is null)
    or (
      home_practice_title is not null
      and char_length(btrim(home_practice_title)) between 1 and 160
      and home_practice_body is not null
      and char_length(btrim(home_practice_body)) between 1 and 1000
    )
  );

-- 1c. Writer evolve-in-place. Signature changes (adds p_home_practice) ->
--     DROP the 3-arg then CREATE the 4-arg (default keeps 3-arg callers working;
--     single function -> no overload ambiguity).
drop function if exists public.submit_session_journal(uuid, text, text);

create or replace function public.submit_session_journal(
  p_session_id uuid,
  p_summary text default null::text,
  p_follow_up text default null::text,
  p_home_practice jsonb default null::jsonb
)
 returns jsonb
 language plpgsql
 security definer
 set search_path to ''
as $function$
declare
  v_state public.session_state; v_school uuid; v_program uuid; v_lv uuid; v_when timestamptz;
  v_actor uuid; v_responsible uuid; v_moments int := 0; v_journey int := 0; v_highlighted jsonb; v_to_observe jsonb;
  v_hp_title text; v_hp_body text; v_hp_present boolean := false;
begin
  select ls.state, cd.program_id, ls.lesson_version_id, coalesce(ls.scheduled_at, now())
    into v_state, v_program, v_lv, v_when
  from public.lesson_sessions ls join public.class_distributions cd on cd.id = ls.class_distribution_id
  where ls.id = p_session_id;
  if not found then return jsonb_build_object('ok', false, 'reason', 'session_not_found'); end if;

  v_actor := public.current_profile();
  v_school := public.session_school_id(p_session_id);
  if v_actor is null then return jsonb_build_object('ok', false, 'reason', 'forbidden'); end if;

  select sta.teacher_id into v_responsible
  from public.session_teacher_assignments sta
  where sta.session_id = p_session_id
    and sta.assignment_type = 'responsible'
    and sta.is_current = true
    and sta.valid_to is null;
  if not found then return jsonb_build_object('ok', false, 'reason', 'no_responsible_assignment'); end if;
  if v_responsible is distinct from v_actor then return jsonb_build_object('ok', false, 'reason', 'forbidden'); end if;
  if public.is_session_responsible(p_session_id) is distinct from true then
    raise exception 'submit_session_journal: responsibility assertion failed for %', p_session_id;
  end if;

  -- V128-P4.1 Home Practice: validate BEFORE any mutation. null = none; else bounded {title, body}.
  if p_home_practice is not null then
    if jsonb_typeof(p_home_practice) <> 'object' then
      return jsonb_build_object('ok', false, 'reason', 'home_practice_invalid');
    end if;
    v_hp_title := btrim(coalesce(p_home_practice->>'title', ''));
    v_hp_body  := btrim(coalesce(p_home_practice->>'body', ''));
    if v_hp_title = '' or v_hp_body = '' then
      return jsonb_build_object('ok', false, 'reason', 'home_practice_invalid');
    end if;
    if char_length(v_hp_title) > 160 then
      return jsonb_build_object('ok', false, 'reason', 'home_practice_title_too_long');
    end if;
    if char_length(v_hp_body) > 1000 then
      return jsonb_build_object('ok', false, 'reason', 'home_practice_body_too_long');
    end if;
    v_hp_present := true;
  end if;

  if v_state in ('taught_report_pending','report_pending_approval','completed') then
    -- immutable after closeout: reject any Home Practice change on the re-submit path
    if v_hp_present then
      return jsonb_build_object('ok', false, 'reason', 'home_practice_locked', 'state', v_state);
    end if;
    update public.learning_moments lm set state = 'approved', approved_by = v_actor
    where lm.session_id = p_session_id and lm.state in ('draft','pending_approval','needs_revision')
      and exists (select 1 from public.moment_children mc where mc.moment_id = lm.id)
      and exists (select 1 from public.media_assets ma where ma.linked_moment_id = lm.id and ma.state = 'active');
    get diagnostics v_moments = row_count;
    return jsonb_build_object('ok', true, 'already', true, 'moments_approved', v_moments, 'state', v_state);
  end if;
  if v_state <> 'in_progress' then return jsonb_build_object('ok', false, 'reason', 'bad_state', 'state', v_state); end if;

  update public.learning_moments lm set state = 'approved', approved_by = v_actor
  where lm.session_id = p_session_id and lm.state in ('draft','pending_approval','needs_revision')
    and exists (select 1 from public.moment_children mc where mc.moment_id = lm.id)
    and exists (select 1 from public.media_assets ma where ma.linked_moment_id = lm.id and ma.state = 'active');
  get diagnostics v_moments = row_count;

  insert into public.child_journey (child_id, source, entry_type, ref_id, lesson_version_id, program_id, occurred_at)
  select co.child_id, 'demen', 'session', p_session_id, v_lv, v_program, v_when
  from public.child_observations co
  where co.session_id = p_session_id and co.attendance in ('present','late')
    and not exists (select 1 from public.child_journey j where j.ref_id = p_session_id and j.child_id = co.child_id and j.entry_type = 'session');
  get diagnostics v_journey = row_count;

  insert into public.child_skills (child_id, skill, signal_count)
  select co.child_id, sc.label_vi, 1
  from public.child_observations co
  cross join lateral jsonb_array_elements_text(coalesce(co.skills_observed, '[]'::jsonb)) as code(val)
  join public.skill_catalog sc on sc.code = code.val
  where co.session_id = p_session_id and co.attendance in ('present','late')
  on conflict (child_id, skill) do update set signal_count = child_skills.signal_count + 1;

  v_highlighted := (select coalesce(jsonb_agg(child_id), '[]'::jsonb) from public.child_observations where session_id = p_session_id and is_highlight);
  v_to_observe := (select coalesce(jsonb_agg(child_id), '[]'::jsonb) from public.child_observations where session_id = p_session_id and (needs_support or follow_up_needed));

  -- Home Practice written only on this fresh path; NOT touched on ON CONFLICT (immutability).
  insert into public.session_reports (session_id, summary, highlighted_children, children_to_observe, follow_up, home_practice_title, home_practice_body, state)
  values (p_session_id, nullif(trim(coalesce(p_summary,'')),''), v_highlighted, v_to_observe, nullif(trim(coalesce(p_follow_up,'')),''),
    case when v_hp_present then v_hp_title else null end,
    case when v_hp_present then v_hp_body else null end,
    'submitted')
  on conflict (session_id) do update set summary = excluded.summary, highlighted_children = excluded.highlighted_children,
    children_to_observe = excluded.children_to_observe, follow_up = excluded.follow_up, state = 'submitted';

  update public.lesson_sessions set state = 'taught_report_pending' where id = p_session_id;
  begin
    perform public.write_audit_log('session_journal_submitted', jsonb_build_object(
      'actor_id', v_actor, 'entity_type','lesson_session', 'entity_id', p_session_id, 'school_id', v_school,
      'metadata', jsonb_build_object('moments_approved', v_moments, 'journey_created', v_journey, 'home_practice', v_hp_present)));
  exception when others then null; end;

  return jsonb_build_object('ok', true, 'moments_approved', v_moments, 'journey_created', v_journey, 'home_practice', v_hp_present, 'state', 'taught_report_pending');
end;
$function$;

-- 1d. Parent read contract — expose bounded Home Practice only (never summary/follow_up).
create or replace function public.get_parent_session_outcomes(p_child_id uuid, p_limit integer default 10)
 returns jsonb
 language plpgsql
 stable security definer
 set search_path to ''
as $function$
declare
  v_limit integer := least(greatest(coalesce(p_limit, 10), 1), 20);
  v_rows jsonb;
  v_has_more boolean := false;
  v_profile uuid := public.current_profile();
begin
  if not public.is_child_parent(p_child_id) then
    raise exception 'not_authorized';
  end if;

  with sess0 as (
    select distinct on (j.ref_id)
           j.id as journey_id,
           j.ref_id as session_id,
           coalesce(j.occurred_at, j.created_at) as occurred_at,
           ls.title as session_title,
           pg.name as program_name
    from public.child_journey j
    join public.lesson_sessions ls on ls.id = j.ref_id
    left join public.programs pg on pg.id = j.program_id
    where j.child_id = p_child_id
      and j.entry_type = 'session'
      and j.source = 'demen'
      and j.ref_id is not null
    order by j.ref_id, coalesce(j.occurred_at, j.created_at) desc, j.id desc
  ),
  sess as (
    select s.*,
           row_number() over (order by s.occurred_at desc, s.journey_id desc) as rn
    from sess0 s
    order by s.occurred_at desc, s.journey_id desc
    limit v_limit + 1
  )
  select
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'journey_id', n.journey_id,
          'session_id', n.session_id,
          'occurred_at', n.occurred_at,
          'session_title', n.session_title,
          'program_name', n.program_name,
          'home_practice', (
            select case when sr.home_practice_title is not null
              then jsonb_build_object(
                'title', sr.home_practice_title,
                'body', sr.home_practice_body,
                'assigned_at', sr.created_at)
              else null end
            from public.session_reports sr
            where sr.session_id = n.session_id
            limit 1
          ),
          'skill_labels', coalesce((
            select jsonb_agg(t.label_vi order by t.sort_order asc, t.label_vi asc)
            from (
              select distinct sc.label_vi, sc.sort_order
              from public.child_observations co
              cross join lateral jsonb_array_elements_text(coalesce(co.skills_observed, '[]'::jsonb)) as code(val)
              join public.skill_catalog sc on sc.code = code.val and sc.enabled
              where co.session_id = n.session_id
                and co.child_id = p_child_id
            ) t
          ), '[]'::jsonb),
          'moments', coalesce((
            select jsonb_agg(
              jsonb_build_object(
                'moment_id', lm.id,
                'media_id', (
                  select ma.id from public.media_assets ma
                  where ma.linked_moment_id = lm.id and ma.state = 'active'
                  order by ma.created_at asc, ma.id asc
                  limit 1
                ),
                'caption', lm.caption,
                'occurred_at', lm.created_at
              ) order by lm.created_at desc, lm.id desc)
            from public.learning_moments lm
            where lm.session_id = n.session_id
              and lm.state = 'approved'
              and exists (
                select 1 from public.moment_children mc
                where mc.moment_id = lm.id and mc.child_id = p_child_id
              )
              and exists (
                select 1 from public.media_assets ma
                where ma.linked_moment_id = lm.id and ma.state = 'active'
              )
          ), '[]'::jsonb),
          'appreciation', coalesce(
            (
              select jsonb_build_object(
                'status', 'sent',
                'recipient_teacher_name', (
                  select pr.full_name from public.profiles pr
                  where pr.id = sa.recipient_teacher_profile_id
                ),
                'sent_at', sa.created_at,
                'acknowledged', (sa.acknowledged_at is not null))
              from public.session_appreciations sa
              where sa.sender_parent_profile_id = v_profile
                and sa.child_id = p_child_id
                and sa.session_id = n.session_id
            ),
            (
              select jsonb_build_object(
                'status', 'available',
                'recipient_teacher_name', (
                  select pr.full_name from public.profiles pr
                  where pr.id = sta.teacher_id
                ),
                'sent_at', null)
              from public.session_teacher_assignments sta
              where sta.session_id = n.session_id
                and sta.assignment_type = 'responsible'
                and sta.is_current = true
                and sta.valid_to is null
            ),
            jsonb_build_object(
              'status', 'unavailable',
              'recipient_teacher_name', null,
              'sent_at', null)
          )
        ) order by n.occurred_at desc, n.journey_id desc
      ) filter (where n.rn <= v_limit),
      '[]'::jsonb
    ),
    coalesce(max(n.rn) > v_limit, false)
  into v_rows, v_has_more
  from sess n;

  return jsonb_build_object(
    'outcomes', coalesce(v_rows, '[]'::jsonb),
    'has_more', coalesce(v_has_more, false)
  );
end;
$function$;

-- 1e. Journal history contract — same bounded Home Practice object on session entries.
create or replace function public.get_child_journal(p_child_id uuid)
 returns jsonb
 language plpgsql
 security definer
 set search_path to ''
as $function$
DECLARE v_result jsonb;
BEGIN
  IF NOT (public.is_child_parent(p_child_id) OR public.child_in_my_school(p_child_id)) THEN
    RAISE EXCEPTION 'not_authorized';
  END IF;

  SELECT jsonb_build_object(
    'journey', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', j.id, 'entry_type', j.entry_type, 'source', j.source,
        'session_id', CASE WHEN j.entry_type = 'session' THEN j.ref_id ELSE NULL END,
        'occurred_at', j.occurred_at,
        'program_name', p.name,
        'session_title', s.title,
        'teacher_note', (
          SELECT co.note FROM public.child_observations co
          WHERE co.session_id = j.ref_id
            AND co.child_id = j.child_id
            AND j.entry_type = 'session'
            AND co.visibility = 'parent_visible'
            AND nullif(trim(co.note), '') IS NOT NULL
          LIMIT 1
        ),
        'home_practice', CASE WHEN j.entry_type = 'session' THEN (
          SELECT CASE WHEN sr.home_practice_title IS NOT NULL
            THEN jsonb_build_object('title', sr.home_practice_title, 'body', sr.home_practice_body, 'assigned_at', sr.created_at)
            ELSE NULL END
          FROM public.session_reports sr WHERE sr.session_id = j.ref_id LIMIT 1
        ) ELSE NULL END,
        'parent_memory', CASE WHEN j.source = 'parent' AND j.entry_type = 'parent_memory' THEN (
          SELECT jsonb_build_object(
            'memory_id', pm.id, 'memory_type', pm.memory_type,
            'artistic_domain', pm.artistic_domain, 'title', pm.title, 'story', pm.story,
            'mine', (pm.created_by = public.current_profile()),
            'galleryItems', COALESCE((
              SELECT jsonb_agg(jsonb_build_object(
                'mediaId', ma.id, 'fileType', ma.file_type,
                'createdAt', ma.created_at, 'sortOrder', pmm.sort_order,
                'label', ma.metadata->>'label')
                ORDER BY pmm.sort_order ASC, ma.created_at ASC, ma.id ASC)
              FROM public.parent_memory_media pmm
              JOIN public.media_assets ma ON ma.id = pmm.media_id AND ma.state = 'active'
              WHERE pmm.memory_id = pm.id AND pmm.deleted_at IS NULL), '[]'::jsonb)
          ) FROM public.parent_memories pm
          WHERE pm.id = j.ref_id AND pm.child_id = j.child_id
        ) ELSE NULL END,
        'family_preserve', CASE WHEN j.source = 'family' THEN (
          SELECT jsonb_build_object(
            'preserve_id', pr.id,
            'target_type', pr.target_type,
            'card_id', mc.id,
            'card_title', COALESCE(mc.title, pm2.title),
            'card_story', COALESCE(mc.story, pm2.story),
            'card_creator_name', crp.full_name,
            'contribution_id', cc.id,
            'contribution_kind', cc.kind,
            'contribution_body', cc.body,
            'contributor_name', ctp.full_name,
            'contributed_at', cc.created_at,
            'preserved_by_name', apr.full_name,
            'preserved_at', pr.created_at,
            'voiceMediaId', (
              SELECT cm.media_id FROM public.contribution_media cm
              JOIN public.media_assets ma ON ma.id = cm.media_id AND ma.state = 'active'
              WHERE cm.contribution_id = cc.id),
            'galleryItems', CASE WHEN pr.target_type = 'memory_card' THEN
              CASE WHEN mc.provenance_source = 'native' THEN COALESCE((
                SELECT jsonb_agg(jsonb_build_object(
                  'mediaId', ma.id, 'fileType', ma.file_type,
                  'createdAt', ma.created_at, 'sortOrder', cmd.sort_order,
                  'label', ma.metadata->>'label')
                  ORDER BY cmd.sort_order ASC, ma.created_at ASC, ma.id ASC)
                FROM public.card_media cmd
                JOIN public.media_assets ma ON ma.id = cmd.media_id AND ma.state = 'active'
                WHERE cmd.card_id = mc.id AND cmd.deleted_at IS NULL), '[]'::jsonb)
              ELSE COALESCE((
                SELECT jsonb_agg(jsonb_build_object(
                  'mediaId', ma.id, 'fileType', ma.file_type,
                  'createdAt', ma.created_at, 'sortOrder', pmm.sort_order,
                  'label', ma.metadata->>'label')
                  ORDER BY pmm.sort_order ASC, ma.created_at ASC, ma.id ASC)
                FROM public.parent_memory_media pmm
                JOIN public.media_assets ma ON ma.id = pmm.media_id AND ma.state = 'active'
                WHERE pmm.memory_id = pm2.id AND pmm.deleted_at IS NULL), '[]'::jsonb)
              END
            ELSE '[]'::jsonb END
          )
          FROM public.preserve_records pr
          LEFT JOIN public.card_contributions cc
            ON pr.target_type = 'card_contribution' AND cc.id = pr.target_contribution_id
          JOIN public.memory_cards mc ON mc.id = COALESCE(pr.target_card_id, cc.card_id)
          LEFT JOIN public.parent_memories pm2
            ON mc.provenance_source = 'parent_memory' AND pm2.id = mc.provenance_ref_id
          LEFT JOIN public.profiles crp ON crp.id = mc.creator_profile_id
          LEFT JOIN public.profiles ctp ON ctp.id = cc.contributor_profile_id
          LEFT JOIN public.profiles apr ON apr.id = pr.actor_profile_id
          WHERE pr.id = j.ref_id
        ) ELSE NULL END
      ) ORDER BY COALESCE(j.occurred_at, j.created_at) DESC)
      FROM public.child_journey j
      LEFT JOIN public.programs p ON p.id = j.program_id
      LEFT JOIN public.lesson_sessions s ON s.id = j.ref_id AND j.entry_type = 'session'
      WHERE j.child_id = p_child_id
        AND (
          (j.source = 'parent' AND j.entry_type = 'parent_memory'
           AND public.is_child_parent(p_child_id)
           AND EXISTS (SELECT 1 FROM public.parent_memories pm
                       WHERE pm.id = j.ref_id AND pm.child_id = j.child_id
                         AND pm.state = 'active'))
          OR
          (j.source = 'family' AND j.entry_type IN ('memory_card','card_contribution')
           AND public.is_child_parent(p_child_id)
           AND EXISTS (SELECT 1 FROM public.preserve_records pr
                       WHERE pr.id = j.ref_id AND pr.child_id = j.child_id)
           AND public.preserve_source_live(j.ref_id))
          OR
          (j.source = 'demen' AND j.entry_type IN ('session','badge'))
        )
    ), '[]'::jsonb),
    'skills', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'skill', sk.skill, 'signal_count', sk.signal_count
      ) ORDER BY sk.signal_count DESC)
      FROM public.child_skills sk WHERE sk.child_id = p_child_id
    ), '[]'::jsonb),
    'badges', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'title', b.title, 'description', b.description,
        'status', cb.status, 'created_at', cb.created_at
      ) ORDER BY cb.created_at DESC)
      FROM public.child_badges cb
      JOIN public.badges b ON b.id = cb.badge_id
      WHERE cb.child_id = p_child_id AND cb.status = 'confirmed'
    ), '[]'::jsonb),
    'moments', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'moment_id', lm.id,
        'session_id', lm.session_id,
        'caption',   lm.caption,
        'created_at',lm.created_at,
        'media_id',  (SELECT ma.id FROM public.media_assets ma
                       WHERE ma.linked_moment_id = lm.id AND ma.state = 'active'
                       ORDER BY ma.created_at LIMIT 1),
        'tagged_count', (SELECT count(*) FROM public.moment_children mc2
                          WHERE mc2.moment_id = lm.id),
        'coverMediaId', (SELECT ma.id FROM public.media_assets ma
                          WHERE ma.linked_moment_id = lm.id AND ma.state = 'active'
                          ORDER BY ma.created_at LIMIT 1),
        'mediaCount', (SELECT count(*) FROM public.media_assets ma
                        WHERE ma.linked_moment_id = lm.id AND ma.state = 'active'),
        'hasGallery', ((SELECT count(*) FROM public.media_assets ma
                         WHERE ma.linked_moment_id = lm.id AND ma.state = 'active') > 1),
        'galleryItems', COALESCE((
          SELECT jsonb_agg(jsonb_build_object(
            'mediaId',   ma.id,
            'fileType',  ma.file_type,
            'createdAt', ma.created_at,
            'caption',   ma.metadata->>'caption',
            'sortOrder', NULL
          ) ORDER BY ma.created_at ASC)
          FROM public.media_assets ma
          WHERE ma.linked_moment_id = lm.id AND ma.state = 'active'
        ), '[]'::jsonb)
      ) ORDER BY lm.created_at DESC)
      FROM public.learning_moments lm
      JOIN public.moment_children mc ON mc.moment_id = lm.id
      WHERE mc.child_id = p_child_id AND lm.state = 'approved'
    ), '[]'::jsonb),
    'creations', CASE WHEN public.is_child_parent(p_child_id) THEN COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'creation_id', kc.id, 'kind', kc.kind, 'caption', kc.caption,
        'created_at', kc.created_at, 'media_id', kc.media_id
      ) ORDER BY kc.created_at DESC)
      FROM public.kid_creations kc
      JOIN public.media_assets ma ON ma.id = kc.media_id AND ma.state = 'active'
      WHERE kc.child_id = p_child_id
    ), '[]'::jsonb) ELSE '[]'::jsonb END
  ) INTO v_result;

  RETURN v_result;
END;
$function$;

-- 1f. Teacher readback — expose submitted Home Practice on the session detail contract.
create or replace function public.get_session_detail(p_session_id uuid)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
      declare
        v_title text; v_state text; v_sched timestamptz; v_dur int; v_class_id uuid; v_class_name text; v_program_name text;
        v_school uuid; v_child_count int; v_rd jsonb; v_actor uuid;
        v_resp_teacher uuid; v_resp_source text; v_resp_valid_from timestamptz; v_resp_name text;
        v_can_submit boolean; v_block_reason text; v_responsible_teacher jsonb;
      begin
        select ls.title, ls.state::text, ls.scheduled_at, ls.duration_min, cd.class_id, cl.name, pr.name
          into v_title, v_state, v_sched, v_dur, v_class_id, v_class_name, v_program_name
        from public.lesson_sessions ls join public.class_distributions cd on cd.id = ls.class_distribution_id
        join public.classes cl on cl.id = cd.class_id left join public.programs pr on pr.id = cd.program_id
        where ls.id = p_session_id;
        if not found then return jsonb_build_object('ok', false, 'reason', 'not_found'); end if;
        v_school := public.session_school_id(p_session_id);
        if not (public.is_admin() or public.same_school(v_school)) then return jsonb_build_object('ok', false, 'reason', 'forbidden'); end if;
        select count(*) into v_child_count from public.enrollments en where en.class_id = v_class_id and en.state = 'active';
        v_rd := public.get_session_readiness(p_session_id);
        select sta.teacher_id, sta.assignment_source, sta.valid_from, prf.full_name into v_resp_teacher, v_resp_source, v_resp_valid_from, v_resp_name
        from public.session_teacher_assignments sta join public.profiles prf on prf.id = sta.teacher_id
        where sta.session_id = p_session_id and sta.assignment_type = 'responsible' and sta.is_current = true and sta.valid_to is null;
        if found then v_responsible_teacher := jsonb_build_object('profile_id', v_resp_teacher, 'display_name', v_resp_name, 'assignment_source', v_resp_source, 'evidence_grade', public.dma_assignment_evidence_grade(v_resp_source), 'valid_from', v_resp_valid_from);
        else v_responsible_teacher := null; end if;
        v_actor := public.current_profile();
        if v_actor is null or not public.same_school(v_school) then v_can_submit := false; v_block_reason := 'forbidden';
        elsif v_resp_teacher is null then v_can_submit := false; v_block_reason := 'no_responsible_assignment';
        elsif v_resp_teacher is distinct from v_actor then v_can_submit := false; v_block_reason := 'forbidden';
        elsif v_state not in ('in_progress','taught_report_pending','report_pending_approval','completed') then v_can_submit := false; v_block_reason := 'bad_state';
        else v_can_submit := true; v_block_reason := null; end if;
        return jsonb_build_object('ok', true, 'can_submit_journal', v_can_submit, 'submit_block_reason', v_block_reason, 'responsible_teacher', v_responsible_teacher,
          'session', jsonb_build_object('id', p_session_id, 'title', v_title, 'state', v_state, 'scheduled_at', v_sched, 'duration_min', v_dur, 'class_name', v_class_name, 'program_name', v_program_name, 'child_count', coalesce(v_child_count,0), 'readiness', v_rd,
            'home_practice', (select case when sr.home_practice_title is not null then jsonb_build_object('title', sr.home_practice_title, 'body', sr.home_practice_body, 'assigned_at', sr.created_at) else null end from public.session_reports sr where sr.session_id = p_session_id limit 1)),
          'prep_items', (select coalesce(jsonb_agg(jsonb_build_object('id', pi.id, 'label', pi.label, 'is_ready', pi.is_ready, 'sort_order', pi.sort_order) order by pi.sort_order, pi.created_at), '[]'::jsonb) from public.prep_items pi where pi.session_id = p_session_id));
      end; $function$;

-- ---------------------------------------------------------------------------
-- BLOCK 2 — REVOKE / GRANT hardening (D15). CREATE OR REPLACE resets proacl to
-- PUBLIC + Supabase default_acl re-grants anon/authenticated -> revoke then
-- re-grant to match the pre-migration posture exactly: {authenticated, service_role}.
-- ---------------------------------------------------------------------------

revoke all on function public.submit_session_journal(uuid, text, text, jsonb) from public, anon;
grant execute on function public.submit_session_journal(uuid, text, text, jsonb) to authenticated, service_role;

revoke all on function public.get_parent_session_outcomes(uuid, integer) from public, anon;
grant execute on function public.get_parent_session_outcomes(uuid, integer) to authenticated, service_role;

revoke all on function public.get_child_journal(uuid) from public, anon;
grant execute on function public.get_child_journal(uuid) to authenticated, service_role;

revoke all on function public.get_session_detail(uuid) from public, anon;
grant execute on function public.get_session_detail(uuid) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- BLOCK 3 — fail-closed VERIFY (D92). Any failure RAISEs -> whole migration
-- rolls back atomically. Then notify PostgREST to reload (D289).
-- ---------------------------------------------------------------------------
do $verify$
declare
  v_cols int;
  v_ck int;
  v_submit4 int;
  v_submit3 int;
  v_reads int;
  v_bad_grants int;
begin
  -- columns present
  select count(*) into v_cols from information_schema.columns
   where table_schema='public' and table_name='session_reports'
     and column_name in ('home_practice_title','home_practice_body');
  if v_cols <> 2 then raise exception 'VERIFY failed: home_practice columns = %', v_cols; end if;

  -- CHECK constraint present
  select count(*) into v_ck from pg_constraint
   where conrelid='public.session_reports'::regclass and conname='session_reports_home_practice_ck';
  if v_ck <> 1 then raise exception 'VERIFY failed: check constraint missing'; end if;

  -- 4-arg writer exists, 3-arg gone
  select count(*) into v_submit4 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.proname='submit_session_journal'
     and pg_get_function_identity_arguments(p.oid)='p_session_id uuid, p_summary text, p_follow_up text, p_home_practice jsonb';
  if v_submit4 <> 1 then raise exception 'VERIFY failed: 4-arg submit_session_journal missing'; end if;
  select count(*) into v_submit3 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.proname='submit_session_journal'
     and pg_get_function_identity_arguments(p.oid)='p_session_id uuid, p_summary text, p_follow_up text';
  if v_submit3 <> 0 then raise exception 'VERIFY failed: legacy 3-arg submit_session_journal still present'; end if;

  -- three read/readback functions present
  select count(*) into v_reads from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.proname in ('get_parent_session_outcomes','get_child_journal','get_session_detail');
  if v_reads <> 3 then raise exception 'VERIFY failed: read contract functions = %', v_reads; end if;

  -- no anon / PUBLIC EXECUTE on any of the four
  select count(*) into v_bad_grants
  from pg_proc p
  join pg_namespace n on n.oid=p.pronamespace
  cross join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
  where n.nspname='public'
    and p.proname in ('submit_session_journal','get_parent_session_outcomes','get_child_journal','get_session_detail')
    and a.privilege_type='EXECUTE'
    and a.grantee in (0, (select oid from pg_roles where rolname='anon'));  -- 0 = PUBLIC
  if v_bad_grants <> 0 then raise exception 'VERIFY failed: anon/PUBLIC EXECUTE present (% grants)', v_bad_grants; end if;

  raise notice 'VERIFY passed: V128-P4.1 home practice contract intact.';
end;
$verify$;

notify pgrst, 'reload schema';
