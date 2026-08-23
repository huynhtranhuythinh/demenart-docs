-- =====================================================================
-- migration 043 — invite_parent (A2: master/sub mời PH có con trong trường mình)
-- Phiên v22 (2026-06-27). Đối xứng invite_staff (A1).
-- 1 RPC: link_parent_user (ghi, service_role). KHÔNG cần list riêng —
--   ParentsPanel đọc PH qua get_child_parents (mig 041) đã trả has_login.
-- Gate same-school cho PH (school_id=NULL) nằm Ở EDGE invite_parent
--   (đường vòng child_parents→enrollments→classes.school_id), KHÔNG ở RPC này.
-- Chạy SAU 042. Idempotent.
-- =====================================================================

-- ---------------------------------------------------------------------
-- link_parent_user — gắn user_id cho PH (primary/secondary_parent); D89 replica.
--   service_role only (Edge invite_parent gọi).
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.link_parent_user(p_profile_id uuid, p_user_id uuid)
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
  if v_role not in ('primary_parent','secondary_parent') then
    return jsonb_build_object('ok', false, 'error', 'not_a_parent');
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
-- HARDEN — REVOKE/GRANT chạy SAU CREATE (D92).
-- ---------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.link_parent_user(uuid, uuid)        FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.link_parent_user(uuid, uuid)    TO service_role;

-- Verify (soi proacl, KHÔNG gọi hàm):
--   link_parent_user  = [postgres, service_role]
--   leaky_anon_public = []
