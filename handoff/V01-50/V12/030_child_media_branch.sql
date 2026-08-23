-- ════════════════════════════════════════════════════════════════
-- mig 030 — NHÁNH ẢNH TRẺ (private_child_media) cho media serving
-- D71 (consent engine) + D74 (zone dma-private) + thép chờ linh hồn
-- Idempotent. SQL Editor chỉ trả statement cuối → verify ở BLOCK 4.
-- ════════════════════════════════════════════════════════════════

-- ── BLOCK 1: thêm cột móc media ↔ moment (delta D1 bắt được) ──────
ALTER TABLE public.media_assets
  ADD COLUMN IF NOT EXISTS linked_moment_id uuid
  REFERENCES public.learning_moments(id);

CREATE INDEX IF NOT EXISTS idx_media_assets_linked_moment
  ON public.media_assets(linked_moment_id);

-- ── BLOCK 2: get_child_journal trả thêm `moments` (ảnh đã duyệt) ──
--    Chỉ moment state='approved' tag trẻ này → an toàn cho PH.
--    media_id = ảnh active đầu tiên móc vào moment (UI sẽ ký qua Edge).
CREATE OR REPLACE FUNCTION public.get_child_journal(p_child_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_result jsonb;
BEGIN
  IF NOT (public.is_child_parent(p_child_id) OR public.child_in_my_school(p_child_id)) THEN
    RAISE EXCEPTION 'not_authorized';
  END IF;

  SELECT jsonb_build_object(
    'journey', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'id', j.id, 'entry_type', j.entry_type, 'source', j.source,
        'occurred_at', j.occurred_at,
        'program_name', p.name,
        'session_title', s.title
      ) ORDER BY COALESCE(j.occurred_at, j.created_at) DESC)
      FROM public.child_journey j
      LEFT JOIN public.programs p ON p.id = j.program_id
      LEFT JOIN public.lesson_sessions s ON s.id = j.ref_id AND j.entry_type = 'session'
      WHERE j.child_id = p_child_id
    ), '[]'::jsonb),
    'skills', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'skill', sk.skill, 'signal_count', sk.signal_count
      ) ORDER BY sk.signal_count DESC)
      FROM public.child_skills sk WHERE sk.child_id = p_child_id
    ), '[]'::jsonb),
    'badges', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'title', b.title, 'description', b.description,
        'status', cb.status, 'created_at', cb.created_at
      ) ORDER BY cb.created_at DESC)
      FROM public.child_badges cb
      JOIN public.badges b ON b.id = cb.badge_id
      WHERE cb.child_id = p_child_id AND cb.status = 'confirmed'
    ), '[]'::jsonb),
    -- ⭐ MỚI: khoảnh khắc có ảnh (chỉ moment ĐÃ DUYỆT)
    'moments', COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'moment_id', lm.id,
        'caption',   lm.caption,
        'created_at',lm.created_at,
        'media_id',  (SELECT ma.id FROM public.media_assets ma
                       WHERE ma.linked_moment_id = lm.id AND ma.state = 'active'
                       ORDER BY ma.created_at LIMIT 1)
      ) ORDER BY lm.created_at DESC)
      FROM public.learning_moments lm
      JOIN public.moment_children mc ON mc.moment_id = lm.id
      WHERE mc.child_id = p_child_id AND lm.state = 'approved'
    ), '[]'::jsonb)
  ) INTO v_result;

  RETURN v_result;
END;
$function$;

REVOKE ALL ON FUNCTION public.get_child_journal(uuid) FROM public, anon;
GRANT EXECUTE ON FUNCTION public.get_child_journal(uuid) TO authenticated;

-- ── BLOCK 3: seed 1 ảnh trẻ test, móc vào moment approved của Jenny ─
--    Resolve nhãn enum chứa 'child' (KHÔNG đoán chuỗi — fail loud nếu thiếu).
DELETE FROM public.media_assets WHERE metadata->>'seed' = 'mig030';

DO $seed$
DECLARE
  v_lbl    text;
  v_moment uuid := 'ee2f63fd-8794-4275-a84d-a89c439d9875'; -- approved: Jenny vẽ tranh mùa xuân
BEGIN
  SELECT e.enumlabel INTO v_lbl
  FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
  WHERE t.typname = (SELECT udt_name FROM information_schema.columns
                     WHERE table_schema='public' AND table_name='media_assets'
                       AND column_name='access_level')
    AND e.enumlabel ILIKE '%child%';

  IF v_lbl IS NULL THEN
    RAISE EXCEPTION 'mig030: khong tim thay nhan access_level chua "child" — gui em danh sach enum o BLOCK 4';
  END IF;

  EXECUTE format($f$
    INSERT INTO public.media_assets
      (storage_provider, storage_zone, bunny_storage_zone, cdn_pull_zone, bunny_path,
       access_level, protection_mode, watermark_required, download_allowed, stream_only,
       expires_policy_minutes, file_type, state,
       linked_school_id, linked_class_id, linked_child_id, linked_moment_id, metadata)
    VALUES
      ('bunny','dma-private','dma-private','dma-private','/jenny_buoi1.jpg',
       %L, 'signed_url', false, false, false,
       10, 'image/jpeg', 'active',
       'b6a4ac35-2e0a-4667-9eea-756f615c29eb',
       '2405fed8-1e9f-4414-b41e-b5eb5f3d8ea7',
       '429d4fb7-67f0-4166-8ec3-fee7ad1a3666',
       %L,
       jsonb_build_object('seed','mig030','title','Bé Jenny vẽ tranh mùa xuân (ảnh thật)'))
  $f$, v_lbl, v_moment);
END
$seed$;

-- ── BLOCK 4: VERIFY (statement cuối — copy blob này về cho em) ─────
SELECT jsonb_pretty(jsonb_build_object(

  'access_level_enum', (SELECT jsonb_agg(e.enumlabel ORDER BY e.enumsortorder)
    FROM pg_enum e JOIN pg_type t ON t.oid=e.enumtypid
    WHERE t.typname=(SELECT udt_name FROM information_schema.columns
      WHERE table_schema='public' AND table_name='media_assets' AND column_name='access_level')),

  'protection_mode_enum', (SELECT jsonb_agg(e.enumlabel ORDER BY e.enumsortorder)
    FROM pg_enum e JOIN pg_type t ON t.oid=e.enumtypid
    WHERE t.typname=(SELECT udt_name FROM information_schema.columns
      WHERE table_schema='public' AND table_name='media_assets' AND column_name='protection_mode')),

  'linked_moment_id_added', (SELECT count(*)=1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='media_assets' AND column_name='linked_moment_id'),

  'seeded_child_media', (SELECT to_jsonb(m) FROM public.media_assets m WHERE m.metadata->>'seed'='mig030'),

  -- khoảnh khắc Jenny mà get_child_journal sẽ trả (test inline, né auth.uid NULL D2)
  'jenny_approved_moments', (
    SELECT jsonb_agg(jsonb_build_object(
      'moment_id', lm.id, 'caption', lm.caption,
      'media_id', (SELECT ma.id FROM public.media_assets ma
                   WHERE ma.linked_moment_id=lm.id AND ma.state='active' ORDER BY ma.created_at LIMIT 1)))
    FROM public.learning_moments lm
    JOIN public.moment_children mc ON mc.moment_id=lm.id
    WHERE mc.child_id='429d4fb7-67f0-4166-8ec3-fee7ad1a3666' AND lm.state='approved'),

  -- ⭐ GATE PRE-LOGIN (D71 nhận-tham-số → chạy thẳng SQL Editor):
  'consent_view_approved', public.media_consent_check(
    'ee2f63fd-8794-4275-a84d-a89c439d9875','60081ef9-f1f9-4291-a391-69418cf44c80','view'),
  'consent_view_draft', public.media_consent_check(
    'e1761056-2c37-4e5a-b936-ed7c42b7c0b4','60081ef9-f1f9-4291-a391-69418cf44c80','view'),

  -- D15: get_child_journal không lọt public/anon
  'grant_leak_check_D15', (
    SELECT coalesce(jsonb_agg(r.rolname),'[]'::jsonb)
    FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    CROSS JOIN LATERAL aclexplode(p.proacl) a
    JOIN pg_roles r ON r.oid=a.grantee
    WHERE n.nspname='public' AND p.proname='get_child_journal'
      AND r.rolname IN ('public','anon') AND a.privilege_type='EXECUTE' AND p.prosecdef)

)) AS verify_mig030;
