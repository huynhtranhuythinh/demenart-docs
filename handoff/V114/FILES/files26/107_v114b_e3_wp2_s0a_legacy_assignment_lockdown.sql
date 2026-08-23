-- =====================================================================================
-- MIGRATION 107 : v114b_e3_wp2_s0a_legacy_assignment_lockdown
-- =====================================================================================
-- Milestone : DMA V114B-E3 · WP2 · Stage S0A
-- Purpose   : Revoke client-facing write grants on the LEGACY assignment table
--             public.session_teachers. Grant revocation ONLY.
--
-- Authority : Readiness Pack rev2 §9 (S0A) — Owner/CTO authorised authoring only.
--             NOT YET APPLIED.
--
-- Scope     : REVOKE INSERT, UPDATE, DELETE ON public.session_teachers
--             FROM authenticated, anon, service_role.
--
-- NOT in scope (deliberately):
--   * SELECT is RETAINED for `authenticated` (compatibility window, rev2 §6 S2/S3).
--   * The 4 RLS policies are NOT dropped. Grants and policies are separate layers;
--     dropping both at once destroys failure attribution. Policies -> S4.
--   * No DDL. No data mutation. No column touched.
--   * TRUNCATE / TRIGGER / REFERENCES are NOT revoked here — see S0A-FINDING-01
--     in the review note. Requires an explicit Owner decision before apply.
--
-- Safety    : All five assignment RPCs are SECURITY DEFINER owned by `postgres`
--             and therefore execute with the definer's privileges. Revoking table
--             DML from authenticated/anon/service_role does NOT affect them.
--             Verified live 2026-07-21 (rev2 §9.2).
--
-- Ops path  : MCP execute_sql runs as `postgres` (table owner, rolbypassrls = true).
--             Emergency operator correction survives this revocation (rev2 §9.4).
--
-- Rollback  : Trivial and data-free —
--               GRANT INSERT, UPDATE, DELETE ON public.session_teachers
--                 TO authenticated, anon, service_role;
--             (See review note for the exact restore statement.)
--
-- Pattern   : D92 three-block. BLOCK 3 raises on any deviation, and because
--             apply_migration wraps the whole thing in one transaction, a RAISE
--             rolls back BLOCK 2 atomically. Nothing is left half-applied.
-- =====================================================================================


-- =====================================================================================
-- BLOCK 1 — PRECONDITION ASSERT (no DDL in this migration; this block replaces it)
-- -------------------------------------------------------------------------------------
-- Fail fast if the live database is not in the exact state that was audited.
-- This is the D1 guarantee expressed as code: we do not trust the audit note,
-- we re-prove it inside the same transaction that performs the change.
-- =====================================================================================
do $block1$
declare
  v_owner       text;
  v_rls         boolean;
  v_rows        bigint;
  v_policies    int;
  v_defs        int;
  v_bad_defs    text;
begin
  -- 1.1 table identity ---------------------------------------------------------------
  if to_regclass('public.session_teachers') is null then
    raise exception 'S0A PRECONDITION FAIL: public.session_teachers does not exist';
  end if;

  select c.relowner::regrole::text, c.relrowsecurity
    into v_owner, v_rls
    from pg_class c
   where c.oid = 'public.session_teachers'::regclass;

  if v_owner is distinct from 'postgres' then
    raise exception 'S0A PRECONDITION FAIL: unexpected table owner % (expected postgres)', v_owner;
  end if;

  if v_rls is not true then
    raise exception 'S0A PRECONDITION FAIL: RLS is not enabled on session_teachers';
  end if;

  -- 1.2 data footprint ---------------------------------------------------------------
  -- Legacy table holds exactly 2 rows at audit time. If this changed, someone wrote
  -- to the table between audit and apply, and the lockdown must be re-reasoned.
  select count(*) into v_rows from public.session_teachers;
  if v_rows <> 2 then
    raise exception 'S0A PRECONDITION FAIL: session_teachers row count = % (expected 2). Table changed since audit.', v_rows;
  end if;

  -- 1.3 policy set -------------------------------------------------------------------
  select count(*) into v_policies
    from pg_policies
   where schemaname = 'public' and tablename = 'session_teachers';
  if v_policies <> 4 then
    raise exception 'S0A PRECONDITION FAIL: expected 4 RLS policies on session_teachers, found %', v_policies;
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='session_teachers' and policyname='session_teachers_select_school')
  or not exists (select 1 from pg_policies where schemaname='public' and tablename='session_teachers' and policyname='session_teachers_insert_lead_or_schooladmin')
  or not exists (select 1 from pg_policies where schemaname='public' and tablename='session_teachers' and policyname='session_teachers_update_lead_or_schooladmin')
  or not exists (select 1 from pg_policies where schemaname='public' and tablename='session_teachers' and policyname='session_teachers_delete_lead_or_schooladmin')
  then
    raise exception 'S0A PRECONDITION FAIL: expected policy names not all present';
  end if;

  -- 1.4 we are genuinely in the PRE state --------------------------------------------
  -- If the grants are already gone, this migration is a no-op replay. Refuse, so the
  -- migration ledger never records a change that did not happen.
  if not has_table_privilege('authenticated', 'public.session_teachers', 'INSERT') then
    raise exception 'S0A PRECONDITION FAIL: authenticated already lacks INSERT — S0A appears already applied';
  end if;

  -- 1.5 definer writers intact --------------------------------------------------------
  -- These five must remain the only write path. If any is not SECURITY DEFINER owned
  -- by postgres, revoking table grants would break a legitimate path.
  select count(*) into v_defs
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
     and p.proname in ('create_lesson_session','set_session_teachers',
                       'set_distribution_lead','assign_class_distribution','start_session')
     and p.prosecdef = true
     and p.proowner::regrole::text = 'postgres';

  if v_defs <> 5 then
    select coalesce(string_agg(p.proname || ' (secdef=' || p.prosecdef || ', owner=' || p.proowner::regrole::text || ')', ', '), '<none found>')
      into v_bad_defs
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public'
       and p.proname in ('create_lesson_session','set_session_teachers',
                         'set_distribution_lead','assign_class_distribution','start_session');
    raise exception 'S0A PRECONDITION FAIL: expected 5 SECURITY DEFINER/postgres-owned assignment RPCs, found %. Live: %', v_defs, v_bad_defs;
  end if;

  raise notice 'S0A BLOCK 1 OK — owner=%, rls=%, rows=%, policies=%, definer_rpcs=%', v_owner, v_rls, v_rows, v_policies, v_defs;
end
$block1$;


-- =====================================================================================
-- BLOCK 2 — REVOKE (the entire change)
-- -------------------------------------------------------------------------------------
-- Table-level revocation. Per D310-cand: table-level grants must be removed at the
-- table level; column-level REVOKE cannot negate a surviving table-level grant.
--
-- service_role is included. The Edge sweep (rev2 §3, 16/16 CLOSED) proved that no
-- Edge Function reads or writes this table directly; the two capability consumers
-- (upload_media branch C, delete_session_media) both go through the SECURITY DEFINER
-- RPC check_session_media_upload_access.
-- =====================================================================================

REVOKE INSERT, UPDATE, DELETE
    ON public.session_teachers
  FROM authenticated, anon, service_role;


-- =====================================================================================
-- BLOCK 3 — VERIFY (RAISE = rollback guard)
-- -------------------------------------------------------------------------------------
-- Structural assertions + live negative probes. Any deviation raises, which rolls
-- back BLOCK 2 atomically.
-- =====================================================================================
do $block3$
declare
  r             text;
  p             text;
  v_rows        bigint;
  v_policies    int;
  v_defs        int;
  v_exec_bad    text;
  v_sqlstate    text;
  v_probe_ok    boolean;
begin
  -- 3.1 write grants are gone for all three client roles -------------------------------
  foreach r in array array['authenticated','anon','service_role'] loop
    foreach p in array array['INSERT','UPDATE','DELETE'] loop
      if has_table_privilege(r, 'public.session_teachers', p) then
        raise exception 'S0A VERIFY FAIL: role % still holds % on session_teachers', r, p;
      end if;
    end loop;
  end loop;

  -- 3.2 SELECT deliberately retained for authenticated ---------------------------------
  -- Readers are not cut over until S3. Losing SELECT here would break the schedule UI.
  if not has_table_privilege('authenticated', 'public.session_teachers', 'SELECT') then
    raise exception 'S0A VERIFY FAIL: authenticated lost SELECT — compatibility window broken';
  end if;

  -- 3.3 owner path preserved (emergency ops) -------------------------------------------
  if not has_table_privilege('postgres', 'public.session_teachers', 'INSERT')
  or not has_table_privilege('postgres', 'public.session_teachers', 'UPDATE')
  or not has_table_privilege('postgres', 'public.session_teachers', 'DELETE') then
    raise exception 'S0A VERIFY FAIL: postgres lost write access — operator escape hatch destroyed';
  end if;

  -- 3.4 no data was touched -------------------------------------------------------------
  select count(*) into v_rows from public.session_teachers;
  if v_rows <> 2 then
    raise exception 'S0A VERIFY FAIL: session_teachers row count changed to % (expected 2)', v_rows;
  end if;

  -- 3.5 policies untouched --------------------------------------------------------------
  select count(*) into v_policies
    from pg_policies where schemaname='public' and tablename='session_teachers';
  if v_policies <> 4 then
    raise exception 'S0A VERIFY FAIL: policy count changed to % (expected 4)', v_policies;
  end if;

  -- 3.6 definer writers unchanged --------------------------------------------------------
  select count(*) into v_defs
    from pg_proc p2 join pg_namespace n on n.oid = p2.pronamespace
   where n.nspname='public'
     and p2.proname in ('create_lesson_session','set_session_teachers',
                        'set_distribution_lead','assign_class_distribution','start_session')
     and p2.prosecdef = true
     and p2.proowner::regrole::text = 'postgres';
  if v_defs <> 5 then
    raise exception 'S0A VERIFY FAIL: definer assignment RPC count = % (expected 5)', v_defs;
  end if;

  -- 3.7 EXECUTE grants on those RPCs unchanged --------------------------------------------
  -- A table REVOKE must not have disturbed function ACLs. Asserted explicitly rather
  -- than assumed (D15 discipline).
  select string_agg(p2.proname, ', ')
    into v_exec_bad
    from pg_proc p2 join pg_namespace n on n.oid = p2.pronamespace
   where n.nspname='public'
     and p2.proname in ('create_lesson_session','set_session_teachers',
                        'set_distribution_lead','assign_class_distribution','start_session')
     and not has_function_privilege('authenticated', p2.oid, 'EXECUTE');
  if v_exec_bad is not null then
    raise exception 'S0A VERIFY FAIL: authenticated lost EXECUTE on: %', v_exec_bad;
  end if;

  -- anon must NOT have EXECUTE on any of them (pre-existing invariant, re-asserted)
  select string_agg(p2.proname, ', ')
    into v_exec_bad
    from pg_proc p2 join pg_namespace n on n.oid = p2.pronamespace
   where n.nspname='public'
     and p2.proname in ('create_lesson_session','set_session_teachers',
                        'set_distribution_lead','assign_class_distribution','start_session')
     and has_function_privilege('anon', p2.oid, 'EXECUTE');
  if v_exec_bad is not null then
    raise exception 'S0A VERIFY FAIL: anon unexpectedly holds EXECUTE on: %', v_exec_bad;
  end if;

  -- 3.8 LIVE NEGATIVE PROBES --------------------------------------------------------------
  -- Prove the revocation actually bites, not merely that a catalog view says so.
  -- A permission failure (SQLSTATE 42501) is the PASS condition. Any other outcome —
  -- including success, or an FK/constraint error — means execution got PAST the
  -- privilege check, i.e. the grant is still effective. Zero residue either way:
  -- a successful insert would be rolled back by the RAISE below.
  foreach r in array array['authenticated','anon','service_role'] loop
    v_probe_ok := false;
    begin
      execute format('set local role %I', r);
      begin
        insert into public.session_teachers (session_id, profile_id, role)
        values (gen_random_uuid(), gen_random_uuid(), 'assist');
        -- reached only if the privilege check passed
        v_sqlstate := '00000';
      exception
        when insufficient_privilege then
          v_probe_ok := true;
          v_sqlstate := '42501';
        when others then
          v_sqlstate := SQLSTATE;
      end;
      reset role;
    exception when others then
      reset role;
      raise;
    end;

    if not v_probe_ok then
      raise exception 'S0A VERIFY FAIL: INSERT probe as % did not hit insufficient_privilege (sqlstate=%). Write path still reachable.', r, v_sqlstate;
    end if;
  end loop;

  raise notice 'S0A BLOCK 3 OK — I/U/D revoked for authenticated+anon+service_role; SELECT retained; 3/3 negative probes hit 42501; rows=2; policies=4; definer_rpcs=5';
end
$block3$;
