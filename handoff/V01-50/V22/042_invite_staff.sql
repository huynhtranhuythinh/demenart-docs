-- =====================================================================
-- migration 042 — invite_staff (A1: master/sub tự mời GV của trường mình)
-- Phiên v22 (2026-06-27). Đối xứng pattern invite_master (v18).
-- 2 RPC: list_school_invitees (đọc, curated) + link_school_user (ghi, service_role).
-- Chạy SAU 041. Idempotent (CREATE OR REPLACE + REVOKE/GRANT tách block).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1) list_school_invitees — master/sub liệt GV chưa login của TRƯỜNG MÌNH
--    (curated read, gương D92/D73). Gate same_school qua profiles.school_id.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.list_school_invitees()
RETURNS jsonb
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO ''
AS $function$
declare
  v_role   public.profile_role;
  v_school uuid;
begin
  select role, school_id into v_role, v_school
  from public.profiles where user_id = auth.uid() limit 1;

  if v_role is null then
    return jsonb_build_object('ok', false, 'error', 'no_profile');
  end if;
  if v_role not in ('master_admin','sub_admin') then
    return jsonb_build_object('ok', false, 'error', 'not_authorized');
  end if;
  if v_school is null then
    return jsonb_build_object('ok', false, 'error', 'no_school');
  end if;

  return jsonb_build_object('ok', true, 'invitees', coalesce((
    select jsonb_agg(jsonb_build_object(
      'profile_id', p.id,
      'full_name',  p.full_name,
      'email',      p.email,
      'role',       p.role,
      'has_email',  (p.email is not null and length(trim(p.email)) > 0))
      order by p.role, p.full_name)
    from public.profiles p
    where p.school_id = v_school
      and p.user_id is null
      and p.role in ('lead_teacher','assistant_teacher')
  ), '[]'::jsonb));
end;
$function$;

-- ---------------------------------------------------------------------
-- 2) link_school_user — gắn user_id cho GV (lead/assistant); D89 replica.
--    service_role only (Edge invite_staff gọi).
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.link_school_user(p_profile_id uuid, p_user_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
declare
  v_role public.profile_role;
  v_cur  uuid;
  v_n    integer;
begin
  select role, user_id into v_role, v_cur
  from public.profiles where id = p_profile_id;

  if v_role is null then
    return jsonb_build_object('ok', false, 'error', 'profile_not_found');
  end if;
  if v_role not in ('lead_teacher','assistant_teacher') then
    return jsonb_build_object('ok', false, 'error', 'not_a_staff');
  end if;
  if v_cur is not null then
    if v_cur = p_user_id then
      return jsonb_build_object('ok', true, 'already_linked', true);
    end if;
    return jsonb_build_object('ok', false, 'error', 'already_linked_other');
  end if;

  set local session_replication_role = replica;   -- D89: bỏ qua guard trigger

  update public.profiles
    set user_id = p_user_id
    where id = p_profile_id and user_id is null;
  get diagnostics v_n = row_count;

  if v_n = 0 then
    return jsonb_build_object('ok', false, 'error', 'update_affected_zero');
  end if;
  return jsonb_build_object('ok', true, 'linked', true);
end;
$function$;

-- ---------------------------------------------------------------------
-- 3) HARDEN — REVOKE/GRANT chạy SAU CREATE (D92: tách block tránh leaky).
-- ---------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.list_school_invitees()              FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.list_school_invitees()          TO authenticated, service_role;

REVOKE ALL ON FUNCTION public.link_school_user(uuid, uuid)        FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.link_school_user(uuid, uuid)    TO service_role;

-- Verify (soi proacl, KHÔNG gọi hàm):
--   list_school_invitees = [authenticated, postgres, service_role]
--   link_school_user      = [postgres, service_role]
--   leaky_anon_public     = []
