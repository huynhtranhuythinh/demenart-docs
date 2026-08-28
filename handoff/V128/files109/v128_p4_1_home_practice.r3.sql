-- ============================================================================
-- MIGRATION ARTIFACT (CORRECTED R2) — V128-P4.1 HOME PRACTICE (Luyện ở nhà)
-- name (apply later): v128_p4_1_home_practice
-- Owner gate: A evolve-in-place · no author column · assigned_at = created_at
-- STATUS: ARTIFACT ONLY — NOT APPLIED · NOT YET REHEARSED (awaiting static review)
--
-- TRANSACTIONALITY (C8): applied via Supabase apply_migration, which runs this
--   ENTIRE file inside ONE transaction. Any failure — DDL, function creation,
--   ACL hardening, or the fail-closed VERIFY DO block (RAISE) — aborts and rolls
--   back the whole migration atomically; no partial schema state is possible.
--   `notify pgrst` becomes externally effective only after COMMIT. Raw
--   BEGIN/COMMIT is intentionally omitted: it would conflict with the
--   tool-managed transaction wrapper (nested BEGIN / premature COMMIT).
--
-- Discipline: D92 three-block · D15/C5 explicit REVOKE/GRANT as deliberate
--   hardening · D289 pgrst reload · additive/nullable only (no backfill,
--   no standalone homework table).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- BLOCK 1 — DDL
-- ---------------------------------------------------------------------------

-- 1a. Additive Home Practice persistence on the existing 1-1 substrate.
alter table public.session_reports
  add column if not exists home_practice_title text,
  add column if not exists home_practice_body  text;

-- 1b. Server-side content contract (both-null OR both-present with trimmed bounds).
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

-- 1c. Writer evolve-in-place (signature change: DROP 3-arg then CREATE 4-arg;
--     single function -> args 2/3/4 default -> 1/2/3/4-arg legacy calls resolve).
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
  v_hp_title text; v_hp_body text; v_hp_present boolean := false; v_keys int;
begin
  -- C2: lock the authoritative lesson_session row BEFORE evaluating mutable
  --     closeout state, so two concurrent submits serialize; the second resumes
  --     only after the first commits and then observes taught_report_pending.
  select ls.state, cd.program_id, ls.lesson_version_id, coalesce(ls.scheduled_at, now())
    into v_state, v_program, v_lv, v_when
  from public.lesson_sessions ls join public.class_distributions cd on cd.id = ls.class_distribution_id
  where ls.id = p_session_id
  for update of ls;
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

  -- C3: strict Home Practice JSON contract — validate BEFORE any mutation.
  --     null = none; else object with EXACTLY {title,body}, both json strings.
  if p_home_practice is not null then
    if jsonb_typeof(p_home_practice) <> 'object' then
      return jsonb_build_object('ok', false, 'reason', 'home_practice_invalid'); end if;
    if not (p_home_practice ? 'title') or not (p_home_practice ? 'body') then
      return jsonb_build_object('ok', false, 'reason', 'home_practice_invalid'); end if;
    select count(*) into v_keys from jsonb_object_keys(p_home_practice);
    if v_keys <> 2 then
      return jsonb_build_object('ok', false, 'reason', 'home_practice_invalid'); end if;
    if jsonb_typeof(p_home_practice->'title') <> 'string'
       or jsonb_typeof(p_home_practice->'body') <> 'string' then
      return jsonb_build_object('ok', false, 'reason', 'home_practice_invalid'); end if;
    v_hp_title := btrim(p_home_practice->>'title');
    v_hp_body  := btrim(p_home_practice->>'body');
    if v_hp_title = '' or v_hp_body = '' then
      return jsonb_build_object('ok', false, 'reason', 'home_practice_invalid'); end if;
    if char_length(v_hp_title) > 160 then
      return jsonb_build_object('ok', false, 'reason', 'home_practice_title_too_long'); end if;
    if char_length(v_hp_body) > 1000 then
      return jsonb_build_object('ok', false, 'reason', 'home_practice_body_too_long'); end if;
    v_hp_present := true;
  end if;

  if v_state in ('taught_report_pending','report_pending_approval','completed') then
    -- immutable after closeout: never modify Home Practice on the re-submit path
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

  -- C7: Home Practice is written ONLY here, at report row creation (fresh path).
  --     Invariant (proved from live catalog): submit_session_journal is the sole
  --     inserter of session_reports; the fresh path atomically sets state ->
  --     taught_report_pending; no path reverts a report-bearing session to
  --     in_progress. Therefore a report row implies state<>in_progress, the
  --     ON CONFLICT below never fires in practice, and created_at == the moment
  --     Home Practice was assigned. The defensive DO UPDATE deliberately does
  --     NOT touch home_practice_* (immutability guarantee at the writer layer).
  insert into public.session_reports (session_id, summary, highlighted_children, children_to_observe, follow_up, home_practice_title, home_practice_body, state)
  values (p_session_id, nullif(trim(coalesce(p_summary,'')),''), v_highlighted, v_to_observe, nullif(trim(coalesce(p_follow_up,'')),''),
    case when v_hp_present then v_hp_title else null end,
    case when v_hp_present then v_hp_body else null end,
    'submitted')
  on conflict (session_id) do update set summary = excluded.summary, highlighted_children = excluded.highlighted_children,
    children_to_observe = excluded.children_to_observe, follow_up = excluded.follow_up, state = 'submitted';

  update public.lesson_sessions set state = 'taught_report_pending' where id = p_session_id;

  -- C1: fail-closed attribution. The audit write is in the SAME transaction as
  --     the closeout and is NO LONGER wrapped in exception-swallowing. If
  --     write_audit_log raises, the entire submit (report, journey, session
  --     state, skills, moments) rolls back atomically. session_journal_submitted
  --     is the sole attribution source (actor_id = responsible teacher).
  perform public.write_audit_log('session_journal_submitted', jsonb_build_object(
    'actor_id', v_actor, 'entity_type','lesson_session', 'entity_id', p_session_id, 'school_id', v_school,
    'metadata', jsonb_build_object('moments_approved', v_moments, 'journey_created', v_journey, 'home_practice', v_hp_present)));

  return jsonb_build_object('ok', true, 'moments_approved', v_moments, 'journey_created', v_journey, 'home_practice', v_hp_present, 'state', 'taught_report_pending');
end;
$function$;

-- 1d. Parent read contract — bounded Home Practice, fail-closed recipient (C4).
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
          -- C4: fail-closed recipient eligibility — project Home Practice only
          --     when an authoritative present|late attendance record exists for
          --     THIS child on THIS session, independent of journey provenance.
          'home_practice', (
            case when exists (
                   select 1 from public.child_observations co
                   where co.session_id = n.session_id
                     and co.child_id = p_child_id
                     and co.attendance in ('present','late'))
            then (
              select case when sr.home_practice_title is not null
                then jsonb_build_object(
                  'title', sr.home_practice_title,
                  'body', sr.home_practice_body,
                  'assigned_at', sr.created_at)
                else null end
              from public.session_reports sr
              where sr.session_id = n.session_id
              limit 1)
            else null end
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

-- 1e. Journal history contract — bounded Home Practice, fail-closed recipient (C4).
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
        -- C4: fail-closed recipient eligibility — Home Practice only when an
        --     authoritative present|late attendance record exists for this child
        --     on this session. Journey content itself is unaffected.
        'home_practice', CASE WHEN j.entry_type = 'session' AND EXISTS (
            SELECT 1 FROM public.child_observations co
            WHERE co.session_id = j.ref_id
              AND co.child_id = j.child_id
              AND co.attendance IN ('present','late')
          ) THEN (
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

-- 1f. Teacher readback — session-level Home Practice on the session-detail contract.
--     (Teacher-facing; not per-child, so C4 recipient gate does not apply here.)
create or replace function public.get_session_detail(p_session_id uuid)
 returns jsonb
 language plpgsql
 security definer
 set search_path to ''
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
-- BLOCK 2 — EXACT allowlist hardening (C5 + R2). Deliberate security control,
--   not a reaction to any "CREATE resets ACL" side-effect. Because CREATE OR
--   REPLACE preserves prior ACL, a static REVOKE public/anon cannot guarantee
--   exactness. This block deterministically forces each RPC to end with the
--   intended posture: revoke PUBLIC, strip EVERY non-owner grantee that is not
--   in {authenticated, service_role}, then grant exactly those two. Proven in
--   BLOCK 3 (both required-present and forbidden-absent).
-- ---------------------------------------------------------------------------
do $harden$
declare
  fn text;
  g record;
  approved_oids oid[] := array[
    (select oid from pg_roles where rolname='authenticated'),
    (select oid from pg_roles where rolname='service_role')];
begin
  foreach fn in array array[
    'public.submit_session_journal(uuid, text, text, jsonb)',
    'public.get_parent_session_outcomes(uuid, integer)',
    'public.get_child_journal(uuid)',
    'public.get_session_detail(uuid)']
  loop
    -- remove PUBLIC grant explicitly
    execute format('revoke all on function %s from public', fn);
    -- strip any explicit non-owner grantee outside the approved set (incl. anon
    -- and any unexpected custom role)
    for g in
      select distinct pg_get_userbyid(a.grantee) as rolname
      from pg_proc p
      cross join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
      where p.oid = fn::regprocedure
        and a.privilege_type = 'EXECUTE'
        and a.grantee <> 0
        and a.grantee <> p.proowner
        and a.grantee <> all(approved_oids)
    loop
      execute format('revoke all on function %s from %I', fn, g.rolname);
    end loop;
    -- grant exactly the approved application roles
    execute format('grant execute on function %s to authenticated, service_role', fn);
  end loop;
end;
$harden$;

-- ---------------------------------------------------------------------------
-- BLOCK 3 — fail-closed VERIFY (C5/C6/C9). Any failure RAISEs -> whole
--   migration rolls back atomically. Then notify PostgREST to reload (D289).
-- ---------------------------------------------------------------------------
do $verify$
declare
  r record;
  v int;
  v_txt text;
  expected_search text;
begin
  ----------------------------------------------------------------------------
  -- C6: Home Practice columns exact contract (type/nullable/default/table).
  ----------------------------------------------------------------------------
  for r in select column_name, data_type, is_nullable, column_default
           from information_schema.columns
           where table_schema='public' and table_name='session_reports'
             and column_name in ('home_practice_title','home_practice_body')
  loop
    if r.data_type <> 'text' then raise exception 'VERIFY C6: % type=% (want text)', r.column_name, r.data_type; end if;
    if r.is_nullable <> 'YES' then raise exception 'VERIFY C6: % not nullable', r.column_name; end if;
    if r.column_default is not null then raise exception 'VERIFY C6: % unexpected default %', r.column_name, r.column_default; end if;
  end loop;
  select count(*) into v from information_schema.columns
   where table_schema='public' and table_name='session_reports' and column_name in ('home_practice_title','home_practice_body');
  if v <> 2 then raise exception 'VERIFY C6: home_practice columns = % (want 2 on session_reports)', v; end if;

  ----------------------------------------------------------------------------
  -- C6: CHECK constraint exact contract (exists, validated, right columns, bounds).
  ----------------------------------------------------------------------------
  select pg_get_constraintdef(c.oid) into v_txt
  from pg_constraint c
  where c.conrelid='public.session_reports'::regclass and c.conname='session_reports_home_practice_ck';
  if v_txt is null then raise exception 'VERIFY C6: home_practice check constraint missing'; end if;
  if position('160' in v_txt)=0 or position('1000' in v_txt)=0 or position('btrim' in v_txt)=0 then
    raise exception 'VERIFY C6: check constraint bounds/trim not intact: %', v_txt; end if;
  select count(*) into v
  from pg_constraint c
  where c.conrelid='public.session_reports'::regclass and c.conname='session_reports_home_practice_ck'
    and c.contype='c' and c.convalidated=true
    and c.conkey @> array[
      (select attnum from pg_attribute where attrelid='public.session_reports'::regclass and attname='home_practice_title'),
      (select attnum from pg_attribute where attrelid='public.session_reports'::regclass and attname='home_practice_body')
    ]::smallint[];
  if v <> 1 then raise exception 'VERIFY C6: check constraint not validated or does not reference both home_practice columns'; end if;

  ----------------------------------------------------------------------------
  -- C5: per-function posture (definer, owner, search_path, exact EXECUTE allowlist).
  ----------------------------------------------------------------------------
  for r in
    select p.oid, p.proname, p.prosecdef, p.proconfig, p.proacl, p.proowner
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public'
      and p.proname in ('submit_session_journal','get_parent_session_outcomes','get_child_journal','get_session_detail')
  loop
    if not r.prosecdef then raise exception 'VERIFY C5: % not SECURITY DEFINER', r.proname; end if;
    if pg_get_userbyid(r.proowner) <> 'postgres' then raise exception 'VERIFY C5: % owner=% (want postgres)', r.proname, pg_get_userbyid(r.proowner); end if;
    -- R1: ALL four RPCs must use the hardened empty search_path
    expected_search := 'search_path=""';
    if r.proconfig is null or not (expected_search = any(r.proconfig)) then
      raise exception 'VERIFY R1: % search_path not hardened to empty -> %', r.proname, r.proconfig; end if;
    -- R2.A: required grants present
    select count(*) into v from aclexplode(coalesce(r.proacl, acldefault('f', r.proowner))) a
     where a.privilege_type='EXECUTE' and a.grantee=(select oid from pg_roles where rolname='authenticated');
    if v <> 1 then raise exception 'VERIFY R2.A: % missing authenticated EXECUTE', r.proname; end if;
    select count(*) into v from aclexplode(coalesce(r.proacl, acldefault('f', r.proowner))) a
     where a.privilege_type='EXECUTE' and a.grantee=(select oid from pg_roles where rolname='service_role');
    if v <> 1 then raise exception 'VERIFY R2.A: % missing service_role EXECUTE', r.proname; end if;
    -- R2.B: exact allowlist — NO EXECUTE grantee outside {owner, authenticated,
    -- service_role}. grantee 0 = PUBLIC; anon and any unexpected custom role are
    -- likewise caught here. Any such entry fails the migration.
    select count(*) into v from aclexplode(coalesce(r.proacl, acldefault('f', r.proowner))) a
     where a.privilege_type='EXECUTE'
       and a.grantee <> r.proowner
       and a.grantee <> (select oid from pg_roles where rolname='authenticated')
       and a.grantee <> (select oid from pg_roles where rolname='service_role');
    if v <> 0 then raise exception 'VERIFY R2.B: % has % unexpected EXECUTE grantee(s) (PUBLIC/anon/custom)', r.proname, v; end if;
  end loop;

  ----------------------------------------------------------------------------
  -- C9: writer signature + defaults (legacy 1/2/3-arg resolvability) & no legacy overload.
  ----------------------------------------------------------------------------
  select count(*) into v from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.proname='submit_session_journal'
     and pg_get_function_identity_arguments(p.oid)='p_session_id uuid, p_summary text, p_follow_up text, p_home_practice jsonb'
     and p.pronargs=4 and p.pronargdefaults=3;
  if v <> 1 then raise exception 'VERIFY C9: 4-arg writer with 3 defaults not present'; end if;
  select count(*) into v from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.proname='submit_session_journal'
     and pg_get_function_identity_arguments(p.oid)='p_session_id uuid, p_summary text, p_follow_up text';
  if v <> 0 then raise exception 'VERIFY C9: legacy 3-arg overload still present'; end if;

  -- three read/readback functions present
  select count(*) into v from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.proname in ('get_parent_session_outcomes','get_child_journal','get_session_detail');
  if v <> 3 then raise exception 'VERIFY: read contract functions = % (want 3)', v; end if;

  raise notice 'VERIFY passed: V128-P4.1 corrected home practice contract intact.';
end;
$verify$;

notify pgrst, 'reload schema';
