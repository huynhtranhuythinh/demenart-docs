-- ============================================================================
-- 046_prep_items_and_readiness.sql
-- Bảng prep_items (checklist dụng cụ mỗi BUỔI — grain lesson_sessions, D53/D99)
-- + RPC get_session_readiness (trả status: tiến-trình-state TRƯỚC → readiness-4-cạnh)
-- Triển khai 3 khối D92: CREATE → REVOKE/GRANT (+2b gỡ anon, D99) → VERIFY
-- Nghiệm thu login thật v30 (GV Mỹ Linh): READY/MISSING/IN_PROGRESS → REST 200 đúng status
-- ============================================================================

-- ---------- BLOCK 1: CREATE ----------
create table if not exists public.prep_items (
  id          uuid primary key default gen_random_uuid(),
  session_id  uuid not null references public.lesson_sessions(id) on delete cascade,
  label       text not null,
  is_ready    boolean not null default false,
  sort_order  int not null default 0,
  created_by  uuid references public.profiles(id) default public.current_profile(),
  created_at  timestamptz not null default now()
);
create index if not exists idx_prep_items_session on public.prep_items(session_id);

alter table public.prep_items enable row level security;

-- RLS gương session_media (D53): READ admin|same-school; WRITE lead|assistant
create policy prep_items_select on public.prep_items
  for select using (
    public.is_admin() or public.same_school(public.session_school_id(session_id))
  );
create policy prep_items_insert on public.prep_items
  for insert with check (
    public.is_session_lead(session_id) or public.is_session_teacher(session_id)
  );
create policy prep_items_update on public.prep_items
  for update using (
    public.is_session_lead(session_id) or public.is_session_teacher(session_id)
  ) with check (
    public.is_session_lead(session_id) or public.is_session_teacher(session_id)
  );
create policy prep_items_delete on public.prep_items
  for delete using (
    public.is_session_lead(session_id) or public.is_session_teacher(session_id)
  );

create or replace function public.get_session_readiness(p_session_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_school uuid; v_state text; v_cd_id uuid; v_lv_id uuid;
  v_lesson_id uuid; v_version_no int; v_lead uuid; v_status text;
  v_media_count int; v_has_newer boolean; v_total int; v_ready int;
begin
  select ls.state::text, ls.class_distribution_id, ls.lesson_version_id
    into v_state, v_cd_id, v_lv_id
  from public.lesson_sessions ls where ls.id = p_session_id;

  if not found then
    return jsonb_build_object('ok', false, 'status', 'not_found');
  end if;

  -- gate: same-school member or admin (RPC không chứa PII trẻ → gương D53 READ)
  v_school := public.session_school_id(p_session_id);
  if not (public.is_admin() or public.same_school(v_school)) then
    return jsonb_build_object('ok', false, 'status', 'forbidden');
  end if;

  select cd.lead_teacher_id into v_lead
  from public.class_distributions cd where cd.id = v_cd_id;

  select count(*), count(*) filter (where is_ready) into v_total, v_ready
  from public.prep_items where session_id = p_session_id;

  -- precedence: tiến trình (state) TRƯỚC, rồi mới tới readiness 4-cạnh
  if v_state in ('cancelled','rescheduled') then
    v_status := 'cancelled';
  elsif v_state = 'completed' then
    v_status := 'completed';
  elsif v_state in ('taught_report_pending','report_pending_approval') then
    v_status := 'report_pending';
  elsif v_state = 'in_progress' then
    v_status := 'in_progress';
  else
    -- nhóm sắp tới: scheduled / prep_ready / makeup
    if v_lead is null then
      v_status := 'unassigned';
    elsif v_lv_id is null then
      v_status := 'missing_materials';
    else
      select count(*) into v_media_count
      from public.media_assets m
      where m.linked_lesson_version_id = v_lv_id and m.state = 'active';

      if v_media_count = 0 then
        v_status := 'missing_materials';
      else
        select lv.lesson_id, lv.version_no into v_lesson_id, v_version_no
        from public.lesson_versions lv where lv.id = v_lv_id;

        select exists(
          select 1 from public.lesson_versions lv2
          where lv2.lesson_id = v_lesson_id
            and lv2.state = 'published'
            and lv2.version_no > v_version_no
        ) into v_has_newer;

        v_status := case when v_has_newer then 'needs_update' else 'ready' end;
      end if;
    end if;
  end if;

  return jsonb_build_object(
    'ok', true,
    'session_id', p_session_id,
    'state', v_state,
    'status', v_status,
    'lead_teacher_id', v_lead,
    'prep', jsonb_build_object('ready', coalesce(v_ready,0), 'total', coalesce(v_total,0))
  );
end;
$$;

-- ---------- BLOCK 2: REVOKE/GRANT (D15) ----------
revoke all on function public.get_session_readiness(uuid) from public;
grant execute on function public.get_session_readiness(uuid) to authenticated;

revoke all on table public.prep_items from anon;
grant select, insert, update, delete on table public.prep_items to authenticated;

-- ---------- BLOCK 2b: gỡ anon execute (D99 — revoke-from-public KHÔNG phủ anon) ----------
revoke all on function public.get_session_readiness(uuid) from anon;

-- ---------- BLOCK 3: VERIFY (KHÔNG gọi hàm — D92) ----------
-- SELECT jsonb_pretty(jsonb_build_object(
--   'table_exists', (select count(*) from information_schema.tables
--                    where table_schema='public' and table_name='prep_items'),
--   'rls_enabled',  (select relrowsecurity from pg_class where oid='public.prep_items'::regclass),
--   'policies',     (select jsonb_agg(policyname order by policyname) from pg_policies
--                    where schemaname='public' and tablename='prep_items'),
--   'fn_exists',    (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace
--                    where n.nspname='public' and p.proname='get_session_readiness'),
--   'fn_grants',    (select jsonb_object_agg(grantee, privilege_type)
--                    from information_schema.role_routine_grants
--                    where routine_schema='public' and routine_name='get_session_readiness')
-- ));
-- Kỳ vọng: table_exists=1 · rls_enabled=true · 4 policies · fn_exists=1 · grants chỉ postgres·service_role·authenticated
