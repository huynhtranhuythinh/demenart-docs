-- =====================================================================
-- DMA · MIGRATION 027 — RPC VẬN HÀNH (Ngã B)
-- create_notification + write_audit_log
--
-- ⭐ NGUYÊN TẮC: cả hai là "người ghi của HỆ THỐNG", KHÔNG cho client gọi.
--   notifications & audit_logs cố tình KHÔNG có INSERT policy (D57) →
--   noti/audit chỉ sinh qua secdef gọi bởi service_role (Edge) hoặc
--   hàm nội bộ DB (trigger/RPC khác, cùng owner).
--   → revoke public/anon/AUTHENTICATED; chỉ grant service_role.
--   (Khác các hàm secdef trước vốn grant authenticated.)
--
-- Chuẩn D20/D21: SECURITY DEFINER · search_path='' · schema-qualified ·
--   dollar-quote · revoke→grant · re-verify D15 (mở rộng: cấm cả authenticated).
-- Idempotent: CREATE OR REPLACE (cùng signature).
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. create_notification(slug, profile_id, payload) -> notification id
--    - slug chưa tồn tại  -> raise (FK cũng chặn, raise cho rõ lỗi)
--    - type enabled=false -> no-op, trả NULL (off-switch config D59)
--    - KHÔNG render body_template ở đây (client tự ghép khi hiển thị)
-- ---------------------------------------------------------------------
create or replace function public.create_notification(
  p_slug       text,
  p_profile_id uuid,
  p_payload    jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $func$
declare
  v_enabled boolean;
  v_id      uuid;
begin
  select nt.enabled into v_enabled
  from public.notification_types nt
  where nt.slug = p_slug;

  if v_enabled is null then
    raise exception 'create_notification: unknown slug %', p_slug
      using errcode = '23503';
  end if;

  if v_enabled = false then
    return null;                       -- type bị tắt -> bỏ qua êm
  end if;

  if not exists (select 1 from public.profiles p where p.id = p_profile_id) then
    raise exception 'create_notification: unknown profile %', p_profile_id
      using errcode = '23503';
  end if;

  insert into public.notifications(profile_id, type, payload)
  values (p_profile_id, p_slug, coalesce(p_payload, '{}'::jsonb))
  returning id into v_id;

  return v_id;
end;
$func$;

revoke all     on function public.create_notification(text, uuid, jsonb) from public, anon, authenticated;
grant  execute on function public.create_notification(text, uuid, jsonb) to service_role;


-- ---------------------------------------------------------------------
-- 2. write_audit_log(action, fields jsonb) -> audit id
--    - action bắt buộc.
--    - fields = jsonb gom mọi cột optional (linh hoạt, khớp bản chất audit):
--      actor_id, entity_type, entity_id, school_id, class_id, child_id,
--      media_id, reason, purpose, ip, device, user_agent, metadata
--    - key thiếu -> NULL (nullif(...,'')::uuid xử lý gọn).
--    - append-only: KHÔNG update/delete; chỉ thêm dòng.
-- ---------------------------------------------------------------------
create or replace function public.write_audit_log(
  p_action text,
  p_fields jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $func$
declare
  v_id uuid;
begin
  if p_action is null or length(btrim(p_action)) = 0 then
    raise exception 'write_audit_log: action required';
  end if;

  insert into public.audit_logs(
    action, actor_id, entity_type, entity_id,
    school_id, class_id, child_id, media_id,
    reason, purpose, ip, device, user_agent, metadata)
  values(
    p_action,
    nullif(p_fields->>'actor_id','')::uuid,
    p_fields->>'entity_type',
    nullif(p_fields->>'entity_id','')::uuid,
    nullif(p_fields->>'school_id','')::uuid,
    nullif(p_fields->>'class_id','')::uuid,
    nullif(p_fields->>'child_id','')::uuid,
    nullif(p_fields->>'media_id','')::uuid,
    p_fields->>'reason',
    p_fields->>'purpose',
    p_fields->>'ip',
    p_fields->>'device',
    p_fields->>'user_agent',
    p_fields->'metadata')
  returning id into v_id;

  return v_id;
end;
$func$;

revoke all     on function public.write_audit_log(text, jsonb) from public, anon, authenticated;
grant  execute on function public.write_audit_log(text, jsonb) to service_role;
