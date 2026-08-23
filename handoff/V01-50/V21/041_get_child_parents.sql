-- ============================================================
-- DMA · migration 041 — get_child_parents (RPC curated đọc PH)
-- D92 · vá D29 chiều ĐỌC · gương D73 · KHÔNG nới policy profiles
-- ------------------------------------------------------------
-- Bối cảnh: master /portal/school tab Trẻ&PH đọc PH qua embed
--   profiles!parent_profile_id → trả null vì PH có school_id=NULL (D40)
--   → trượt cả 3 SELECT policy profiles → UI hiện "—".
-- FIX: RPC secdef curated bypass RLS CỐ Ý, trả CHỈ nhãn an toàn.
--   TUYỆT ĐỐI KHÔNG nới profiles_select_same_school cho school_id IS NULL
--   (sẽ lộ PH mọi trường — convention school_id-NULL load-bearing D52/D56).
-- ⚠️ REVOKE/GRANT chạy TÁCH BLOCK + verify KHÔNG gọi hàm (D92):
--   verify-gọi-hàm raise (auth.uid()=NULL gate) → rollback CREATE;
--   REVOKE cùng-block không phủ default PUBLIC của CREATE OR REPLACE.
-- ============================================================

-- ── BLOCK 1: tạo hàm ───────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_child_parents(p_child_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $func$
declare v_school_id uuid; v_result jsonb;
begin
  -- trẻ thuộc trường nào (D40 — đi vòng enrollment, children không có school_id)
  select c.school_id into v_school_id
  from public.enrollments e join public.classes c on c.id = e.class_id
  where e.child_id = p_child_id limit 1;
  if v_school_id is null then raise exception 'child_not_enrolled'; end if;

  -- gate: admin nền tảng HOẶC master/sub đúng trường (gương assign_class_distribution)
  if not ( public.is_admin()
        or ( public.current_profile_role() in ('master_admin','sub_admin')
             and v_school_id = any(public.user_school_ids()) ) )
  then raise exception 'not_authorized_for_school'; end if;

  -- curated: bypass RLS CỐ Ý, trả CHỈ nhãn an toàn của PH
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
$func$;

-- ── BLOCK 2: harden grant (TÁCH khỏi BLOCK 1 — D92) ────────
-- CREATE OR REPLACE đẻ default PUBLIC execute → phải REVOKE khối riêng.
REVOKE ALL ON FUNCTION public.get_child_parents(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_child_parents(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_child_parents(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_child_parents(uuid) TO service_role;

-- ── BLOCK 3: verify (KHÔNG gọi hàm → không raise → không rollback) ──
-- Kỳ vọng: grantees = [authenticated, postgres, service_role] · leaky_grants = []
SELECT jsonb_pretty(jsonb_build_object(
  'grantees', (SELECT jsonb_agg(r.rolname ORDER BY r.rolname)
               FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
               JOIN aclexplode(p.proacl) a ON true JOIN pg_roles r ON r.oid=a.grantee
               WHERE n.nspname='public' AND p.proname='get_child_parents'
                 AND a.privilege_type='EXECUTE'),
  'leaky_grants', coalesce((
    SELECT jsonb_agg(p.proname) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    JOIN aclexplode(p.proacl) a ON true JOIN pg_roles r ON r.oid=a.grantee
    WHERE n.nspname='public' AND p.prosecdef AND a.privilege_type='EXECUTE'
      AND r.rolname IN ('public','anon') AND p.proname='get_child_parents'), '[]'::jsonb)
));
