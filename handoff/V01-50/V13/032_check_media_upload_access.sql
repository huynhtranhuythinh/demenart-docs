-- ════════════════════════════════════════════════════════════
-- mig 032 — check_media_upload_access(): gate UPLOAD ảnh moment (B1, D64/D77)
-- engine-per-media-type (write-side); nhận tham số → test thẳng SQL Editor.
-- ════════════════════════════════════════════════════════════

-- ───── BLOCK 1: gate ─────
create or replace function public.check_media_upload_access(
  p_moment_id      uuid,
  p_viewer_profile uuid
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $func$
declare
  v_moment  public.learning_moments%rowtype;
  v_mschool uuid;
  v_vschool uuid;
begin
  select * into v_moment from public.learning_moments where id = p_moment_id;
  if not found then
    return jsonb_build_object('allowed', false, 'reason', 'moment_not_found');
  end if;

  v_mschool := public.moment_school_id(p_moment_id);
  select school_id into v_vschool from public.profiles where id = p_viewer_profile;

  -- PH + admin nền tảng (school_id NULL) → không phải nhân sự trường → chặn (D48/D64)
  if v_vschool is null then
    return jsonb_build_object('allowed', false, 'reason', 'not_school_member');
  end if;

  -- chỉ nhân sự ĐÚNG trường của moment (gương D58 same_school write)
  if v_vschool <> v_mschool then
    return jsonb_build_object('allowed', false, 'reason', 'wrong_school',
      'viewer_school', v_vschool, 'moment_school', v_mschool);
  end if;

  return jsonb_build_object(
    'allowed', true, 'reason', 'ok',
    'moment_school_id', v_mschool,
    'moment_state', v_moment.state,
    'class_id', v_moment.class_id,
    'target_zone', 'dma-private',
    'access_level', 'private_child_media'
  );
end;
$func$;

-- ───── BLOCK 2: grant (D21) ─────
revoke all on function public.check_media_upload_access(uuid, uuid) from public, anon;
grant execute on function public.check_media_upload_access(uuid, uuid) to authenticated, service_role;

-- ───── BLOCK 3: verify (D4/D15) — nhận-tham-số → test cả 2 nhánh không cần login ─────
select jsonb_pretty(jsonb_build_object(
  'fn_exists', (
    select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname='check_media_upload_access'
  ),
  'grant_leak_d15', (
    select coalesce(jsonb_agg(r.rolname),'[]'::jsonb)
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace and n.nspname='public'
    cross join lateral aclexplode(p.proacl) a join pg_roles r on r.oid=a.grantee
    where p.proname='check_media_upload_access'
      and r.rolname in ('public','anon') and a.privilege_type='EXECUTE' and p.prosecdef
  ),
  'test_staff_uploader', public.check_media_upload_access(
     'ee2f63fd-8794-4275-a84d-a89c439d9875',
     '1810667b-75a0-4b83-a940-cc267b239851'),
  'test_parent_blocked', (
     select public.check_media_upload_access('ee2f63fd-8794-4275-a84d-a89c439d9875', p.id)
     from public.profiles p where p.school_id is null limit 1
  )
)) as verify_mig032;
