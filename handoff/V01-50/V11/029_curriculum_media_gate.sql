-- =====================================================================
-- DMA mig 029 — curriculum media entitlement gate + seed file học liệu test
-- Nguồn: RULES D75 (gate học liệu) + D74 (topology 3-zone). Tài liệu G §12.
-- Idempotent: create-or-replace + NOT EXISTS guard. KHÔNG bảng/policy mới.
-- Verify (đã chạy v11): member→entitled allowed · parent→not_school_member denied · D15 grant [].
-- =====================================================================

-- BLOCK 1 — engine gate (SECURITY DEFINER, nhận tham số tường minh → test thẳng SQL Editor, D71/D75)
create or replace function public.check_curriculum_media_access(
  p_media_id uuid, p_viewer_profile uuid
) returns jsonb language plpgsql security definer set search_path = '' as $func$
declare
  v_media   public.media_assets%rowtype;
  v_program uuid;
  v_school  uuid;
  v_ok      boolean := false;
begin
  select * into v_media from public.media_assets where id = p_media_id and state = 'active';
  if not found then
    return jsonb_build_object('allowed', false, 'reason', 'media_not_found');
  end if;

  -- engine này CHỈ cho học liệu; ảnh trẻ đi media_consent_check (D71)
  if v_media.access_level <> 'private_curriculum' then
    return jsonb_build_object('allowed', false, 'reason', 'wrong_engine',
      'access_level', v_media.access_level::text);
  end if;

  -- media → lesson_version → lesson → program
  if v_media.linked_lesson_version_id is not null then
    select l.program_id into v_program
      from public.lesson_versions lv
      join public.lessons l on l.id = lv.lesson_id
     where lv.id = v_media.linked_lesson_version_id;
  end if;
  if v_program is null then
    return jsonb_build_object('allowed', false, 'reason', 'media_not_linked_to_program');
  end if;

  -- viewer phải là thành viên trường (PH school_id NULL + admin nền tảng → loại ở V1)
  select school_id into v_school from public.profiles where id = p_viewer_profile;
  if v_school is null then
    return jsonb_build_object('allowed', false, 'reason', 'not_school_member', 'program_id', v_program);
  end if;

  -- entitlement môn + subscription còn hiệu lực (D51/D56)
  select exists(
    select 1
      from public.school_subject_entitlements e
      join public.school_subscriptions s on s.id = e.subscription_id
     where e.school_id = v_school
       and e.program_id = v_program
       and s.state in ('active','trial')
       and (e.end_date is null or e.end_date >= current_date)
  ) into v_ok;

  if not v_ok then
    return jsonb_build_object('allowed', false, 'reason', 'no_active_entitlement',
      'school_id', v_school, 'program_id', v_program);
  end if;

  return jsonb_build_object(
    'allowed', true, 'reason', 'entitled',
    'school_id', v_school, 'program_id', v_program, 'media_id', v_media.id,
    'bunny_path', v_media.bunny_path, 'cdn_pull_zone', v_media.cdn_pull_zone,
    'download_allowed', v_media.download_allowed,
    'watermark_required', v_media.watermark_required,
    'stream_only', v_media.stream_only,
    'expires_policy_minutes', v_media.expires_policy_minutes);
end; $func$;

revoke all on function public.check_curriculum_media_access(uuid,uuid) from public, anon;
grant execute on function public.check_curriculum_media_access(uuid,uuid) to authenticated, service_role;

-- BLOCK 2 — seed media học liệu test (Chu_Vit_Con.mp3 trong zone dma-learning)
-- gắn 1 lesson_version của môn mà CÓ trường đang entitled (để gate member trả allowed)
insert into public.media_assets(
  storage_provider, storage_zone, bunny_storage_zone, bunny_path, cdn_pull_zone,
  access_level, protection_mode, watermark_required, download_allowed, stream_only,
  expires_policy_minutes, file_type, linked_lesson_version_id, state, metadata)
select 'bunny','dma-learning','dma-learning','/Chu_Vit_Con.mp3','dma-learning',
  'private_curriculum','signed_url', true, false, true, 10, 'audio/mpeg',
  lv.id, 'active',
  jsonb_build_object('title','Chú Vịt Con (demo CTAN)','seed','mig029')
from public.lesson_versions lv
join public.lessons l on l.id = lv.lesson_id
where l.program_id in (select program_id from public.school_subject_entitlements)
  and not exists (select 1 from public.media_assets where bunny_path = '/Chu_Vit_Con.mp3')
order by l.created_at nulls last
limit 1;

-- =====================================================================
-- DIAGNOSTIC (read-only, KHÔNG thuộc migration — chạy tay để nghiệm thu):
-- Kỳ vọng: seeded_media 1 row · grant_leak_check []
--          MEMBER → allowed:true,"entitled" · PARENT → allowed:false,"not_school_member"
-- =====================================================================
-- select jsonb_pretty(jsonb_build_object(
--   'seeded_media', (select to_jsonb(m) from public.media_assets m where m.bunny_path='/Chu_Vit_Con.mp3'),
--   'grant_leak_check_D15', (select coalesce(jsonb_agg(rolname),'[]'::jsonb) from (
--      select r.rolname from pg_proc p join pg_namespace n on n.oid=p.pronamespace
--        cross join lateral aclexplode(p.proacl) a join pg_roles r on r.oid=a.grantee
--       where n.nspname='public' and p.proname='check_curriculum_media_access'
--         and p.prosecdef and a.privilege_type='EXECUTE' and r.rolname in ('public','anon')) q),
--   'gate_test_MEMBER_expect_allowed', (
--      select public.check_curriculum_media_access(
--        (select id from public.media_assets where bunny_path='/Chu_Vit_Con.mp3'),
--        (select pr.id from public.profiles pr
--           join public.media_assets m on m.bunny_path='/Chu_Vit_Con.mp3'
--           join public.lesson_versions lv on lv.id=m.linked_lesson_version_id
--           join public.lessons l on l.id=lv.lesson_id
--           join public.school_subject_entitlements e on e.school_id=pr.school_id and e.program_id=l.program_id
--          where pr.school_id is not null limit 1))),
--   'gate_test_PARENT_expect_denied', (
--      select public.check_curriculum_media_access(
--        (select id from public.media_assets where bunny_path='/Chu_Vit_Con.mp3'),
--        (select id from public.profiles where school_id is null limit 1)))
-- )) as verify029;
