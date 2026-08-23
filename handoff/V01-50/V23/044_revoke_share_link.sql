-- ============================================================================
-- 044_revoke_share_link.sql  (DMA — Ngã A v23)
-- ----------------------------------------------------------------------------
-- Mục đích: PH (creator) thu hồi TAY một private share link trước khi hết hạn.
--   Đối xứng create_private_share_link (D87). Edge resolve_share_link ĐÃ kiểm
--   revoked_at sẵn → KHÔNG đụng Edge.
-- Gate: creator-only (gương Fork 3A D55). Idempotent (đã revoke → no-op).
-- Audit: share_link_revoked / share_link_revoke_denied; actor = PROFILE id (D88),
--   qua write_audit_log (service_role-only writer D72).
-- KHÔNG trigger trên share_links → secdef bypass RLS đủ, KHÔNG cần replica.
-- ⚠️ CHẠY 3 KHỐI RIÊNG (D92): CREATE riêng · HARDEN riêng · VERIFY riêng
--    (verify KHÔNG gọi hàm — soi proacl).
-- ============================================================================


-- ─────────────────────────────────────────────────────────────────────────
-- BLOCK 1 — CREATE (chạy RIÊNG)
-- ─────────────────────────────────────────────────────────────────────────
create or replace function public.revoke_share_link(p_token text)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $func$
declare
  v_actor uuid;
  v_link  public.share_links%rowtype;
begin
  v_actor := public.current_profile();
  if v_actor is null then
    return jsonb_build_object('ok', false, 'reason', 'not_authenticated');
  end if;

  -- secdef bypass RLS CỐ Ý: tra theo token để kiểm chủ sở hữu (gương resolve)
  select * into v_link
  from public.share_links
  where token = p_token;

  if not found then
    return jsonb_build_object('ok', false, 'reason', 'not_found');
  end if;

  -- creator-only (Fork 3A D55)
  if v_link.created_by_profile_id is distinct from v_actor then
    perform public.write_audit_log('share_link_revoke_denied', jsonb_build_object(
      'actor_id',    v_actor,
      'entity_type', 'share_link',
      'entity_id',   v_link.id,
      'metadata',    jsonb_build_object('reason','not_creator')));
    return jsonb_build_object('ok', false, 'reason', 'not_authorized');
  end if;

  -- idempotent: đã revoke rồi → trả trạng thái, KHÔNG ghi đè revoked_at
  if v_link.revoked_at is not null then
    return jsonb_build_object('ok', true, 'reason', 'already_revoked',
      'revoked_at', v_link.revoked_at, 'share_link_id', v_link.id);
  end if;

  update public.share_links
  set revoked_at = now()
  where id = v_link.id;

  perform public.write_audit_log('share_link_revoked', jsonb_build_object(
    'actor_id',    v_actor,
    'entity_type', 'share_link',
    'entity_id',   v_link.id,
    'metadata',    jsonb_build_object(
      'scope_type',   v_link.scope_type,
      'scope_ref_id', v_link.scope_ref_id,
      'token_tail',   right(p_token, 6))));

  return jsonb_build_object('ok', true, 'reason', 'revoked',
    'revoked_at', now(), 'share_link_id', v_link.id);
end;
$func$;


-- ─────────────────────────────────────────────────────────────────────────
-- BLOCK 2 — HARDEN (chạy RIÊNG; REVOKE PUBLIC + anon RỜI nhau — D15/D92)
-- ─────────────────────────────────────────────────────────────────────────
revoke all on function public.revoke_share_link(text) from public;
revoke all on function public.revoke_share_link(text) from anon;
grant execute on function public.revoke_share_link(text) to authenticated;


-- ─────────────────────────────────────────────────────────────────────────
-- BLOCK 3 — VERIFY (chạy RIÊNG; soi proacl, KHÔNG gọi hàm — D92)
-- ─────────────────────────────────────────────────────────────────────────
select jsonb_pretty(jsonb_build_object(
  'fn_exists', exists(
    select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname='revoke_share_link'),
  'grantees', (
    select coalesce(jsonb_agg(distinct r.rolname order by r.rolname), '[]'::jsonb)
    from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace
    cross join lateral aclexplode(p.proacl) a
    join pg_roles r on r.oid=a.grantee
    where n.nspname='public' and p.proname='revoke_share_link'
      and a.privilege_type='EXECUTE'),
  'leaky', (
    select coalesce(jsonb_agg(distinct r.rolname), '[]'::jsonb)
    from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace
    cross join lateral aclexplode(p.proacl) a
    join pg_roles r on r.oid=a.grantee
    where n.nspname='public' and p.proname='revoke_share_link'
      and a.privilege_type='EXECUTE'
      and r.rolname in ('public','anon')
      and p.prosecdef)
));
-- Kỳ vọng: fn_exists=true · grantees=[authenticated,postgres,service_role] · leaky=[]
