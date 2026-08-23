-- =====================================================================
-- DMA · MIGRATION 026 — media_consent_check  ("người soát vé" consent)
-- Ngã A / lát A2 — consent engine (D47/D55: engine sống Ở ĐÂY, không RLS).
-- Không đụng schema (media_assets đã đủ field từ mig 005, audit A1).
--
-- Nhận: moment_id + id người xem + hành động ('view'|'download'|'share')
-- Trả jsonb: { allowed, reason, required_consent_type,
--              school_sharing_mode, moment_state, blocking_children[] }
--
-- LUẬT: MIN-multi-child — một trẻ tag thiếu consent ⇒ chặn CẢ moment,
--       liệt kê trẻ chặn (blocking_children) để UI báo "vì bé X chưa đồng ý".
-- Nhân sự cùng trường: BỎ QUA consent (người trong cuộc) — vẫn audit/watermark
--       ở tầng Edge. Consent chỉ gác phụ huynh / bên ngoài.
-- Chuẩn D20/D21: SECURITY DEFINER · search_path='' · schema-qualified ·
--       REVOKE public/anon → GRANT authenticated · re-verify D15.
-- Idempotent: CREATE OR REPLACE (cùng signature).
-- =====================================================================

create or replace function public.media_consent_check(
  p_moment_id      uuid,
  p_viewer_profile uuid,
  p_action         text default 'view'
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $func$
declare
  v_action        text := lower(coalesce(p_action, 'view'));
  v_moment_state  text;
  v_school        uuid;
  v_viewer_school uuid;
  v_school_share  text;
  v_child_count   int;
  v_required_type text;
  v_blocking      jsonb;
begin
  -- 0. action hợp lệ?
  if v_action not in ('view', 'download', 'share') then
    return jsonb_build_object('allowed', false, 'reason', 'invalid_action');
  end if;

  -- 1. moment tồn tại?
  select lm.state::text into v_moment_state
  from public.learning_moments lm
  where lm.id = p_moment_id;

  if v_moment_state is null then
    return jsonb_build_object('allowed', false, 'reason', 'moment_not_found');
  end if;

  v_school := public.moment_school_id(p_moment_id);

  -- 2. Người xem là NHÂN SỰ cùng trường? -> bỏ qua consent (người trong cuộc).
  select p.school_id into v_viewer_school
  from public.profiles p
  where p.id = p_viewer_profile;

  if v_viewer_school is not null and v_viewer_school = v_school then
    return jsonb_build_object(
      'allowed', true,
      'reason', 'school_staff',
      'moment_state', v_moment_state,
      'blocking_children', '[]'::jsonb
    );
  end if;

  -- 3. Nhánh PHỤ HUYNH / ngoài: moment phải đã DUYỆT.
  if v_moment_state <> 'approved' then
    return jsonb_build_object(
      'allowed', false,
      'reason', 'moment_not_approved',
      'moment_state', v_moment_state,
      'blocking_children', '[]'::jsonb
    );
  end if;

  -- 3b. Người xem phải là PH của ≥1 trẻ được tag (phòng thủ tầng sâu).
  if not exists (
    select 1
    from public.moment_children mc
    join public.child_parents cp on cp.child_id = mc.child_id
    where mc.moment_id = p_moment_id
      and cp.parent_profile_id = p_viewer_profile
  ) then
    return jsonb_build_object(
      'allowed', false,
      'reason', 'not_authorized',
      'moment_state', v_moment_state,
      'blocking_children', '[]'::jsonb
    );
  end if;

  -- 4. Số trẻ tag -> loại consent cần (cho 'view'); download/share cố định.
  select count(*) into v_child_count
  from public.moment_children mc
  where mc.moment_id = p_moment_id;

  if v_action = 'view' then
    if v_child_count = 0 then
      return jsonb_build_object(
        'allowed', true, 'reason', 'no_tagged_children',
        'moment_state', v_moment_state, 'blocking_children', '[]'::jsonb
      );
    elsif v_child_count >= 2 then
      v_required_type := 'group_moment_in_class';   -- ảnh nhiều trẻ
    else
      v_required_type := 'display_in_app';          -- ảnh một trẻ
    end if;
  elsif v_action = 'download' then
    v_required_type := 'download';
  else
    v_required_type := 'private_share_link';
  end if;

  -- 5. Cổng KHUNG TRƯỜNG (chỉ download/share). Trường đặt no_external -> cấm.
  select s.sharing_mode::text into v_school_share
  from public.schools s
  where s.id = v_school;

  if v_action = 'download'
     and v_school_share not in ('download_only', 'private_share_link') then
    return jsonb_build_object(
      'allowed', false, 'reason', 'school_blocks_download',
      'required_consent_type', v_required_type,
      'school_sharing_mode', v_school_share,
      'moment_state', v_moment_state, 'blocking_children', '[]'::jsonb
    );
  end if;

  if v_action = 'share'
     and v_school_share <> 'private_share_link' then
    return jsonb_build_object(
      'allowed', false, 'reason', 'school_blocks_share',
      'required_consent_type', v_required_type,
      'school_sharing_mode', v_school_share,
      'moment_state', v_moment_state, 'blocking_children', '[]'::jsonb
    );
  end if;

  -- 6. MIN consent: gom MỌI trẻ tag THIẾU consent loại cần.
  select coalesce(jsonb_agg(jsonb_build_object('child_id', mc.child_id)), '[]'::jsonb)
  into v_blocking
  from public.moment_children mc
  where mc.moment_id = p_moment_id
    and not exists (
      select 1
      from public.consents c
      where c.child_id = mc.child_id
        and c.consent_type::text = v_required_type
        and c.granted = true
        and c.withdrawn_at is null
    );

  if v_blocking <> '[]'::jsonb then
    return jsonb_build_object(
      'allowed', false,
      'reason', 'consent_missing',
      'required_consent_type', v_required_type,
      'school_sharing_mode', v_school_share,
      'moment_state', v_moment_state,
      'blocking_children', v_blocking          -- để UI báo "vì bé X chưa đồng ý"
    );
  end if;

  -- 7. Hợp lệ.
  return jsonb_build_object(
    'allowed', true,
    'reason', 'ok',
    'required_consent_type', v_required_type,
    'school_sharing_mode', v_school_share,
    'moment_state', v_moment_state,
    'blocking_children', '[]'::jsonb
  );
end;
$func$;

-- D21: khóa execute khỏi client công khai, chỉ cho authenticated.
revoke all     on function public.media_consent_check(uuid, uuid, text) from public, anon;
grant  execute on function public.media_consent_check(uuid, uuid, text) to authenticated;
