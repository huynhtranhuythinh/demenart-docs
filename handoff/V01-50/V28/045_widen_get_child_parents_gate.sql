-- ============================================================================
-- 045_widen_get_child_parents_gate.sql
-- ----------------------------------------------------------------------------
-- MỤC ĐÍCH (D94/D45/D92): Nới gate RPC curated `get_child_parents` để
--   GV (lead_teacher / assistant_teacher) CÙNG TRƯỜNG đọc được nhãn phụ huynh
--   ở chế độ CHỈ-ĐỌC — đóng "rough edge GV read-only" tồn từ v25.
--
-- BẢN CHẤT: trước mig 045, gate chỉ master/sub_admin → GV ở /school bấm 1 bé
--   → ParentsPanel gọi get_child_parents → raise not_authorized_for_school
--   → GV thấy toast "không có quyền" + panel PH rỗng.
--
-- VÁ = thêm 'lead_teacher','assistant_teacher' vào danh sách role, GIỮ NGUYÊN
--   điều kiện same-school `v_school_id = any(public.user_school_ids())`.
--   `user_school_ids()` build từ profiles.school_id của caller (KHÔNG lọc role)
--   → GV (có school_id thẳng, D93 A1) nằm sẵn trong mảng; GV trường khác → mảng
--   không chứa → vẫn chặn. Phần trả nhãn KHÔNG đổi → GV read-only thật.
--
-- D92 (3 KHỐI TÁCH): chạy lần lượt — CREATE / HARDEN / VERIFY-soi-proacl.
--   KHÔNG gọi hàm trong cùng migration (gate dùng auth.uid()=NULL ở SQL Editor
--   → raise kéo rollback). Verify nhánh gate bằng LOGIN THẬT (D2/D3).
--
-- DB cấu trúc KHÔNG đổi (CREATE OR REPLACE 1 hàm sẵn có): 46 bảng · 50 hàm
--   definer · 125 policy. Chỉ mig number 044→045.
--
-- NGHIỆM THU LOGIN THẬT (v28 ĐẠT): GV KHM Đặng Mỹ Linh
--   (gv.linh.kidshouse@demo.demenart.com / Test@123) → /school tab Trẻ&PH
--   → bấm bé An → panel PH hiện "Nguyễn Văn Hùng" + email read-only,
--   banner "chế độ chỉ đọc" còn (Quyết B sống), HẾT toast "không có quyền".
-- ============================================================================


-- ─────────────────────────────────────────────────────────────────────────
-- KHỐI 1/3 — CREATE (nới gate cho GV same-school read-only)
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_child_parents(p_child_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_school_id uuid; v_result jsonb;
begin
  select c.school_id into v_school_id
  from public.enrollments e join public.classes c on c.id = e.class_id
  where e.child_id = p_child_id limit 1;
  if v_school_id is null then raise exception 'child_not_enrolled'; end if;

  if not ( public.is_admin()
        or ( public.current_profile_role() in ('master_admin','sub_admin','lead_teacher','assistant_teacher')
             and v_school_id = any(public.user_school_ids()) ) )
  then raise exception 'not_authorized_for_school'; end if;

  select coalesce(jsonb_agg(jsonb_build_object(
           'parent_profile_id', p.id,
           'full_name',  p.full_name,
           'email',      p.email,
           'phone',      p.phone,
           'link_role',  cp.link_role,
           'has_login',  (p.user_id is not null)
         ) order by cp.created_at), '[]'::jsonb)
  into v_result
  from public.child_parents cp
  join public.profiles p on p.id = cp.parent_profile_id
  where cp.child_id = p_child_id;

  return v_result;
end;
$function$;


-- ─────────────────────────────────────────────────────────────────────────
-- KHỐI 2/3 — HARDEN (REVOKE PUBLIC+anon, GRANT lại)
--   CREATE OR REPLACE reset grant về PUBLIC execute (D15/D20/D90) → harden
--   ở KHỐI RIÊNG sau CREATE đã commit.
-- ─────────────────────────────────────────────────────────────────────────
REVOKE ALL ON FUNCTION public.get_child_parents(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_child_parents(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_child_parents(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_child_parents(uuid) TO service_role;


-- ─────────────────────────────────────────────────────────────────────────
-- KHỐI 3/3 — VERIFY (soi proacl, KHÔNG execute — tránh raise kéo rollback)
--   Kỳ vọng: grantees=[authenticated,postgres,service_role] · leaky=[] ·
--            gate_has_teacher=true.   (v28 ĐẠT.)
-- ─────────────────────────────────────────────────────────────────────────
SELECT jsonb_pretty(jsonb_build_object(
  'grantees', (
    SELECT coalesce(jsonb_agg(DISTINCT g.grantee::regrole::text ORDER BY g.grantee::regrole::text), '[]'::jsonb)
    FROM pg_proc p2, aclexplode(p2.proacl) g
    WHERE p2.oid = 'public.get_child_parents(uuid)'::regprocedure
  ),
  'leaky', (
    SELECT coalesce(jsonb_agg(DISTINCT g.grantee::regrole::text), '[]'::jsonb)
    FROM pg_proc p2, aclexplode(p2.proacl) g
    WHERE p2.oid = 'public.get_child_parents(uuid)'::regprocedure
      AND g.grantee::regrole::text IN ('public','anon')
  ),
  'gate_has_teacher', (
    pg_get_functiondef('public.get_child_parents(uuid)'::regprocedure) LIKE '%lead_teacher%'
  )
));
