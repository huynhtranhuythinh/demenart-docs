-- ============================================================
-- DMA · migration 040 — MASTER TỰ QUẢN TRƯỜNG (2 RPC)
-- D91 · dump trung thực từ live (D90) · idempotent (CREATE OR REPLACE)
-- ------------------------------------------------------------
-- Bối cảnh: audit Org/People (D1) lộ master_admin ∈ is_school_admin()
--   → phần lớn self-manage RLS đã phục vụ sẵn (tạo lớp / provision GV /
--     create_child_and_enroll). CHỈ 2 lỗ ghi cần RPC:
--   (1) assign_class_distribution  — rót môn, LICENSE-GATED
--   (2) provision_parent_and_link  — tạo PH + link (vá D29 RETURNING-câm)
-- 2 bảng đụng KHÔNG có guard trigger trên INSERT → secdef đủ, KHÔNG replica.
-- Mirror create_child_and_enroll: KHÔNG audit (đồng cấp self-provision).
-- ============================================================

-- ── BLOCK 1: assign_class_distribution ─────────────────────
-- Gate: is_admin() OR (master/sub same_school).
-- ⭐ LICENSE-GATE has_subject_entitlement (D51/D56) — chỉ rót môn đã mua
--   active/trial còn hạn (MNDM không mua Ballet → subject_not_entitled).
-- Lead-teacher (nếu có) phải đúng trường + vai dạy được.
-- Chống trùng: bảng KHÔNG có unique(class,program) → tự kiểm distribution_exists.
CREATE OR REPLACE FUNCTION public.assign_class_distribution(p_class_id uuid, p_program_id uuid, p_lead_teacher_id uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_school_id uuid; v_dist_id uuid;
begin
  select c.school_id into v_school_id from public.classes c where c.id = p_class_id;
  if v_school_id is null then raise exception 'class_not_found'; end if;

  -- gate: admin nền tảng HOẶC master/sub đúng trường (gương create_child_and_enroll)
  if not ( public.is_admin()
        or ( public.current_profile_role() in ('master_admin','sub_admin')
             and v_school_id = any(public.user_school_ids()) ) )
  then raise exception 'not_authorized_for_school'; end if;

  -- ⭐ LICENSE-GATE (D51/D56): chỉ rót MÔN ĐÃ MUA (active/trial còn hạn)
  if not public.has_subject_entitlement(v_school_id, p_program_id) then
    raise exception 'subject_not_entitled'; end if;

  -- GV chính (nếu có) phải ĐÚNG trường + vai dạy được
  if p_lead_teacher_id is not null then
    if not exists (
      select 1 from public.profiles pr
      where pr.id = p_lead_teacher_id
        and pr.school_id = v_school_id
        and pr.role in ('lead_teacher','assistant_teacher','sub_admin','master_admin')
    ) then raise exception 'lead_teacher_invalid'; end if;
  end if;

  -- chống trùng: 1 môn active / 1 lớp (bảng KHÔNG có unique)
  if exists (
    select 1 from public.class_distributions d
    where d.class_id = p_class_id and d.program_id = p_program_id and d.state = 'active'
  ) then raise exception 'distribution_exists'; end if;

  insert into public.class_distributions
    (class_id, program_id, lead_teacher_id, applied_by, applied_at)
  values
    (p_class_id, p_program_id, p_lead_teacher_id, public.current_profile(), now())
  returning id into v_dist_id;

  return v_dist_id;
end;
$function$;

REVOKE ALL ON FUNCTION public.assign_class_distribution(p_class_id uuid, p_program_id uuid, p_lead_teacher_id uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.assign_class_distribution(p_class_id uuid, p_program_id uuid, p_lead_teacher_id uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.assign_class_distribution(p_class_id uuid, p_program_id uuid, p_lead_teacher_id uuid) TO service_role;

-- ── BLOCK 2: provision_parent_and_link ─────────────────────
-- Vá D29 RETURNING-câm: PH có school_id=NULL (D40) → raw INSERT thì 3 SELECT
--   policy profiles đều false → RETURNING rỗng → RPC atomic.
-- Gate: master + child_in_my_school (đi vòng enrollment — D40).
-- max-2-parent: đếm trước, raise max_parents_reached; primary (con #0) / secondary.
CREATE OR REPLACE FUNCTION public.provision_parent_and_link(p_child_id uuid, p_full_name text, p_email text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_link_role text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_school_id uuid; v_parent_role public.profile_role; v_count int; v_parent_id uuid;
begin
  -- trẻ phải thuộc trường của caller (D40 — children không có school_id, đi vòng enrollment)
  select c.school_id into v_school_id
  from public.enrollments e join public.classes c on c.id = e.class_id
  where e.child_id = p_child_id limit 1;
  if v_school_id is null then raise exception 'child_not_enrolled'; end if;

  if not ( public.is_admin()
        or ( public.current_profile_role() in ('master_admin','sub_admin')
             and v_school_id = any(public.user_school_ids()) ) )
  then raise exception 'not_authorized_for_school'; end if;

  select count(*) into v_count from public.child_parents cp where cp.child_id = p_child_id;
  if v_count >= 2 then raise exception 'max_parents_reached'; end if;

  v_parent_role := case when v_count = 0
                        then 'primary_parent'::public.profile_role
                        else 'secondary_parent'::public.profile_role end;

  -- PH: school_id NULL (D40 thấy-con-không-thấy-trường) · user_id NULL (login gắn sau qua invite)
  insert into public.profiles (role, full_name, email, phone, school_id, user_id)
  values (v_parent_role, p_full_name, nullif(p_email,''), nullif(p_phone,''), null, null)
  returning id into v_parent_id;

  insert into public.child_parents (child_id, parent_profile_id, link_role)
  values (p_child_id, v_parent_id, nullif(p_link_role,''));

  return v_parent_id;
end;
$function$;

REVOKE ALL ON FUNCTION public.provision_parent_and_link(p_child_id uuid, p_full_name text, p_email text, p_phone text, p_link_role text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.provision_parent_and_link(p_child_id uuid, p_full_name text, p_email text, p_phone text, p_link_role text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.provision_parent_and_link(p_child_id uuid, p_full_name text, p_email text, p_phone text, p_link_role text) TO service_role;

-- ── BLOCK 3: VERIFY (D15 — re-verify public/anon EXECUTE) ───
-- Kỳ vọng leaky_grants = [] (không hàm nào lộ public/anon EXECUTE).
SELECT jsonb_pretty(jsonb_build_object(
  'leaky_grants', coalesce((
    SELECT jsonb_agg(p.proname)
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    JOIN aclexplode(p.proacl) a ON true
    JOIN pg_roles r ON r.oid = a.grantee
    WHERE n.nspname='public'
      AND p.prosecdef
      AND a.privilege_type='EXECUTE'
      AND r.rolname IN ('public','anon')
      AND p.proname IN ('assign_class_distribution','provision_parent_and_link')
  ), '[]'::jsonb)
));
