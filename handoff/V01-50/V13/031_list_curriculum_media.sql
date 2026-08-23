-- ════════════════════════════════════════════════════════════
-- mig 031 — list_curriculum_media(): curated-read track học liệu
-- entitled cho GV (gương D73; KHÔNG nới RLS media_assets D58).
-- ════════════════════════════════════════════════════════════

-- ───── BLOCK 1: tạo RPC ─────
create or replace function public.list_curriculum_media()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $func$
declare
  v_school uuid;
  v_result jsonb;
begin
  -- caller's school (NULL nếu admin nền tảng / PH) → ngoài cuộc V1
  v_school := public.current_school_id();
  if v_school is null then
    return '[]'::jsonb;
  end if;

  select coalesce(jsonb_agg(item order by item->>'title'), '[]'::jsonb)
  into v_result
  from (
    select jsonb_build_object(
      'media_id',           m.id,
      'title',              coalesce(m.metadata->>'title', 'Học liệu'),
      'file_type',          m.file_type,
      'program_id',         l.program_id,
      'watermark_required', m.watermark_required,
      'stream_only',        m.stream_only,
      'download_allowed',   m.download_allowed
    ) as item
    from public.media_assets m
    join public.lesson_versions lv on lv.id = m.linked_lesson_version_id
    join public.lessons l on l.id = lv.lesson_id
    where m.access_level = 'private_curriculum'
      and m.state = 'active'
      and m.linked_lesson_version_id is not null
      and exists (
        select 1
        from public.school_subject_entitlements e
        join public.school_subscriptions s on s.id = e.subscription_id
        where e.school_id = v_school
          and e.program_id = l.program_id
          and s.state in ('active','trial')
          and (e.end_date is null or e.end_date >= current_date)
      )
  ) sub;

  return v_result;
end;
$func$;

-- ───── BLOCK 2: grant (D21) — read-only, GV gọi trực tiếp ─────
revoke all on function public.list_curriculum_media() from public, anon;
grant execute on function public.list_curriculum_media() to authenticated;

-- ───── BLOCK 3: verify (D4/D15) ─────
-- LƯU Ý D2: current_school_id() dựa auth.uid()=NULL trong SQL Editor
-- → gọi hàm trực tiếp ở đây trả [] là ĐÚNG. preview_as_demo_school
-- mô phỏng chuỗi join với school_id Trường Demo để chứng logic.
select jsonb_pretty(jsonb_build_object(
  'fn_exists', (
    select count(*) from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname='list_curriculum_media'
  ),
  'grant_leak_d15', (
    select coalesce(jsonb_agg(r.rolname),'[]'::jsonb)
    from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace and n.nspname='public'
    cross join lateral aclexplode(p.proacl) a
    join pg_roles r on r.oid=a.grantee
    where p.proname='list_curriculum_media'
      and r.rolname in ('public','anon')
      and a.privilege_type='EXECUTE' and p.prosecdef
  ),
  'grantees', (
    select coalesce(jsonb_agg(r.rolname order by r.rolname),'[]'::jsonb)
    from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace and n.nspname='public'
    cross join lateral aclexplode(p.proacl) a
    join pg_roles r on r.oid=a.grantee
    where p.proname='list_curriculum_media' and a.privilege_type='EXECUTE'
  ),
  'call_as_sql_editor_expect_empty', public.list_curriculum_media(),
  'preview_as_demo_school', (
    select coalesce(jsonb_agg(jsonb_build_object(
      'media_id', m.id, 'title', m.metadata->>'title', 'file_type', m.file_type
    )),'[]'::jsonb)
    from public.media_assets m
    join public.lesson_versions lv on lv.id=m.linked_lesson_version_id
    join public.lessons l on l.id=lv.lesson_id
    where m.access_level='private_curriculum' and m.state='active'
      and exists(
        select 1 from public.school_subject_entitlements e
        join public.school_subscriptions s on s.id=e.subscription_id
        where e.school_id='b6a4ac35-2e0a-4667-9eea-756f615c29eb'
          and e.program_id=l.program_id and s.state in ('active','trial')
          and (e.end_date is null or e.end_date>=current_date)
      )
  )
)) as verify_mig031;
