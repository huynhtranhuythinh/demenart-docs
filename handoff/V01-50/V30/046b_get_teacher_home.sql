-- ============================================================================
-- 046b_get_teacher_home.sql
-- RPC get_teacher_home() — 1-call cho Teacher Home (D99): tìm tiết-hôm-nay của GV
-- (lead class_distributions HOẶC session_teachers) + tiết-kế-tiếp + today_count,
-- gói sẵn readiness mỗi buổi (gọi get_session_readiness bên trong → tránh N+1).
-- 3 khối D92. Nghiệm thu login thật v30 (GV Mỹ Linh): 200, shape đúng.
-- ============================================================================

-- ---------- BLOCK 1: CREATE ----------
create or replace function public.get_teacher_home()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile uuid := public.current_profile();
  v_today_start timestamptz := date_trunc('day', now());
  v_today_end   timestamptz := date_trunc('day', now()) + interval '1 day';
  v_today jsonb;
  v_next  jsonb;
  v_count int;
begin
  if v_profile is null then
    return jsonb_build_object('ok', false, 'reason', 'not_authenticated');
  end if;

  with my_sessions as (
    select ls.id, ls.title, ls.scheduled_at, ls.state,
           cd.id as cd_id, cl.name as class_name, pr.name as program_name,
           (select count(*) from public.enrollments en
             where en.class_id = cl.id and en.state = 'active') as child_count
    from public.lesson_sessions ls
    join public.class_distributions cd on cd.id = ls.class_distribution_id
    join public.classes cl on cl.id = cd.class_id
    left join public.programs pr on pr.id = cd.program_id
    where (cd.lead_teacher_id = v_profile
           or exists (select 1 from public.session_teachers st
                      where st.session_id = ls.id and st.profile_id = v_profile))
      and ls.state not in ('cancelled')
  ),
  today_pick as (
    select * from my_sessions
    where scheduled_at >= v_today_start and scheduled_at < v_today_end
    order by scheduled_at asc nulls last limit 1
  ),
  next_pick as (
    select * from my_sessions
    where scheduled_at >= v_today_end
    order by scheduled_at asc nulls last limit 1
  )
  select
    (select count(*) from my_sessions
      where scheduled_at >= v_today_start and scheduled_at < v_today_end),
    (select to_jsonb(t) || jsonb_build_object(
        'readiness', public.get_session_readiness(t.id)) from today_pick t),
    (select to_jsonb(n) from next_pick n)
  into v_count, v_today, v_next;

  return jsonb_build_object(
    'ok', true,
    'teacher_profile', v_profile,
    'today_count', coalesce(v_count, 0),
    'today_session', v_today,
    'next_session', v_next
  );
end;
$$;

-- ---------- BLOCK 2: REVOKE/GRANT (D15 + D99 gỡ anon) ----------
revoke all on function public.get_teacher_home() from public;
revoke all on function public.get_teacher_home() from anon;
grant execute on function public.get_teacher_home() to authenticated;

-- ---------- BLOCK 3: VERIFY ----------
-- SELECT jsonb_pretty(jsonb_build_object(
--   'fn_exists', (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
--                 where n.nspname='public' and p.proname='get_teacher_home'),
--   'fn_grants', (select jsonb_object_agg(grantee, privilege_type)
--                 from information_schema.role_routine_grants
--                 where routine_schema='public' and routine_name='get_teacher_home')
-- ));
-- Kỳ vọng: fn_exists=1 · grants chỉ postgres·service_role·authenticated
