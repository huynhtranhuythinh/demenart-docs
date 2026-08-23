-- =====================================================================================
-- MIGRATION 107 : v114b_e3_wp2_s0a_legacy_assignment_lockdown
-- REVISION      : rev2 (Option C — full non-SELECT client lockdown)
-- =====================================================================================
-- Milestone : DMA V114B-E3 · WP2 · Stage S0A
-- Purpose   : Revoke all approved non-SELECT client privileges on the LEGACY
--             assignment table public.session_teachers. Grant revocation ONLY.
--
-- Authority : Readiness Pack rev2 §9 + Owner/CTO decision "OPTION C".
--             AUTHORED ONLY — NOT YET APPLIED.
--
-- Scope     : REVOKE INSERT, UPDATE, DELETE, TRUNCATE, TRIGGER, REFERENCES
--             ON public.session_teachers
--             FROM authenticated, anon, service_role;
--
-- RETAINED deliberately:
--   * SELECT for all three client roles (compatibility window, rev2 §6). Readers are
--     not cut over until S3; removing SELECT here breaks the schedule UI.
--   * The 4 RLS policies. Grants and policies are independent layers; removing both
--     at once destroys failure attribution. Policies -> S4.
--   * MAINTAIN — see S0A-FINDING-02 in the review pack. This server is PostgreSQL 17
--     and all three client roles additionally hold MAINTAIN, which is NOT covered by
--     the approved six-privilege statement. Deliberately left in place pending an
--     explicit Owner decision. Recorded, not silently absorbed.
--
-- NOT in scope: no DDL, no data mutation, no column touched, no policy dropped,
--               no function replaced, no trigger created.
--
-- Safety    : All five assignment RPCs are SECURITY DEFINER owned by `postgres` and
--             execute with the definer's privileges, so table-level revocation from
--             authenticated/anon/service_role does not affect them.
--             REFERENCES is only required to create FK constraints *referencing* this
--             table; TRIGGER only to create new triggers on it. Neither is used by any
--             DML path. Live user triggers on this table: 0.
--
-- Ops path  : MCP execute_sql runs as `postgres`, the table OWNER (rolsuper = false,
--             so ownership is the operative grant). BLOCK 3 asserts postgres retains
--             all six privileges.
--
-- Pattern   : D92 three-block. apply_migration wraps everything in one transaction,
--             so any RAISE in BLOCK 3 rolls BLOCK 2 back atomically.
--
-- Expected ACL transition (exact):
--     BEFORE  postgres=arwdDxtm/postgres, anon=arwdDxtm/postgres,
--             authenticated=arwdDxtm/postgres, service_role=arwdDxtm/postgres
--     AFTER   postgres=arwdDxtm/postgres, anon=rm/postgres,
--             authenticated=rm/postgres, service_role=rm/postgres
--     (r = SELECT retained by design; m = MAINTAIN retained per S0A-FINDING-02)
-- =====================================================================================


-- =====================================================================================
-- BLOCK 1 — PRECONDITION ASSERT
-- -------------------------------------------------------------------------------------
-- Re-prove the audited live state inside the same transaction that changes it.
-- We do not trust the audit note; we re-derive it. (D1)
-- =====================================================================================
do $block1$
declare
  v_owner        text;
  v_rls          boolean;
  v_rows         bigint;
  v_policies     int;
  v_defs         int;
  v_constraints  int;
  v_indexes      int;
  v_bad_defs     text;
  v_colacl       text;
  r              text;
  p              text;
begin
  ---- 1.1 table identity ----------------------------------------------------------------
  if to_regclass('public.session_teachers') is null then
    raise exception 'S0A PRECONDITION FAIL: public.session_teachers does not exist';
  end if;

  select c.relowner::regrole::text, c.relrowsecurity
    into v_owner, v_rls
    from pg_class c
   where c.oid = 'public.session_teachers'::regclass;

  if v_owner is distinct from 'postgres' then
    raise exception 'S0A PRECONDITION FAIL: table owner = % (expected postgres)', v_owner;
  end if;

  if v_rls is not true then
    raise exception 'S0A PRECONDITION FAIL: RLS not enabled on session_teachers';
  end if;

  ---- 1.2 data + structure footprint -----------------------------------------------------
  select count(*) into v_rows from public.session_teachers;
  if v_rows <> 2 then
    raise exception 'S0A PRECONDITION FAIL: row count = % (expected 2). Table changed since audit.', v_rows;
  end if;

  select count(*) into v_constraints from pg_constraint where conrelid = 'public.session_teachers'::regclass;
  if v_constraints <> 5 then
    raise exception 'S0A PRECONDITION FAIL: constraint count = % (expected 5)', v_constraints;
  end if;

  select count(*) into v_indexes from pg_index where indrelid = 'public.session_teachers'::regclass;
  if v_indexes <> 2 then
    raise exception 'S0A PRECONDITION FAIL: index count = % (expected 2)', v_indexes;
  end if;

  ---- 1.3 policy set ----------------------------------------------------------------------
  select count(*) into v_policies
    from pg_policies where schemaname = 'public' and tablename = 'session_teachers';
  if v_policies <> 4 then
    raise exception 'S0A PRECONDITION FAIL: policy count = % (expected 4)', v_policies;
  end if;

  if not exists (select 1 from pg_policies where schemaname='public' and tablename='session_teachers' and policyname='session_teachers_select_school')
  or not exists (select 1 from pg_policies where schemaname='public' and tablename='session_teachers' and policyname='session_teachers_insert_lead_or_schooladmin')
  or not exists (select 1 from pg_policies where schemaname='public' and tablename='session_teachers' and policyname='session_teachers_update_lead_or_schooladmin')
  or not exists (select 1 from pg_policies where schemaname='public' and tablename='session_teachers' and policyname='session_teachers_delete_lead_or_schooladmin')
  then
    raise exception 'S0A PRECONDITION FAIL: expected policy names not all present';
  end if;

  ---- 1.4 confirm we are genuinely in the PRE state -----------------------------------------
  -- All six target privileges must currently be present for all three roles. If any is
  -- already absent, this is a partial/replay apply and must not be recorded as a change.
  foreach r in array array['authenticated','anon','service_role'] loop
    foreach p in array array['INSERT','UPDATE','DELETE','TRUNCATE','TRIGGER','REFERENCES'] loop
      if not has_table_privilege(r, 'public.session_teachers', p) then
        raise exception 'S0A PRECONDITION FAIL: role % already lacks % — S0A appears partially applied', r, p;
      end if;
    end loop;
  end loop;

  ---- 1.5 no pre-existing EXPLICIT column-level grants ---------------------------------------
  -- pg_attribute.attacl is the authoritative source. information_schema.column_privileges
  -- merely projects table-level grants onto every column and would mislead here (D310-cand).
  -- Audited: attacl IS NULL for all 5 user columns. If that has changed, a table-level
  -- REVOKE alone would NOT close the write path and this migration is insufficient.
  select string_agg(a.attname || ' => ' || a.attacl::text, ' · ' order by a.attnum)
    into v_colacl
    from pg_attribute a
   where a.attrelid = 'public.session_teachers'::regclass
     and a.attnum > 0 and not a.attisdropped
     and a.attacl is not null;

  if v_colacl is not null then
    raise exception 'S0A PRECONDITION FAIL: explicit column-level ACL present, table REVOKE would be insufficient: %', v_colacl;
  end if;

  ---- 1.6 definer writers intact --------------------------------------------------------------
  select count(*) into v_defs
    from pg_proc pr join pg_namespace n on n.oid = pr.pronamespace
   where n.nspname = 'public'
     and pr.proname in ('create_lesson_session','set_session_teachers',
                        'set_distribution_lead','assign_class_distribution','start_session')
     and pr.prosecdef = true
     and pr.proowner::regrole::text = 'postgres';

  if v_defs <> 5 then
    select coalesce(string_agg(pr.proname || ' (secdef=' || pr.prosecdef || ', owner=' || pr.proowner::regrole::text || ')', ', '), '<none>')
      into v_bad_defs
      from pg_proc pr join pg_namespace n on n.oid = pr.pronamespace
     where n.nspname = 'public'
       and pr.proname in ('create_lesson_session','set_session_teachers',
                          'set_distribution_lead','assign_class_distribution','start_session');
    raise exception 'S0A PRECONDITION FAIL: expected 5 SECURITY DEFINER/postgres-owned assignment RPCs, found %. Live: %', v_defs, v_bad_defs;
  end if;

  raise notice 'S0A BLOCK 1 OK — owner=% rls=% rows=% constraints=% indexes=% policies=% definer_rpcs=% explicit_col_acl=none',
               v_owner, v_rls, v_rows, v_constraints, v_indexes, v_policies, v_defs;
end
$block1$;


-- =====================================================================================
-- BLOCK 2 — REVOKE (the entire change)
-- -------------------------------------------------------------------------------------
-- Table-level revocation of all six approved privileges. Per D310-cand, table-level
-- grants must be removed at the table level; a column-level REVOKE cannot negate a
-- surviving table-level grant.
--
-- service_role is included: the Edge sweep (rev2 §3, 16/16 CLOSED) proved no Edge
-- Function reads or writes this table directly. The two capability consumers
-- (upload_media branch C, delete_session_media) both route through the SECURITY
-- DEFINER RPC check_session_media_upload_access.
-- =====================================================================================

REVOKE INSERT, UPDATE, DELETE, TRUNCATE, TRIGGER, REFERENCES
    ON public.session_teachers
  FROM authenticated, anon, service_role;


-- =====================================================================================
-- BLOCK 3 — VERIFY (RAISE = rollback guard)
-- -------------------------------------------------------------------------------------
-- Evidence hierarchy, in order of authority:
--   3.1-3.3   DIRECT ACL INSPECTION via aclexplode         <- PRIMARY EVIDENCE
--   3.4       table-level has_table_privilege              <- corroborating
--   3.5       column-level has_column_privilege             <- corroborating (D310-cand)
--   3.6-3.9   preservation assertions
--   3.10      functional probes                             <- SUPPLEMENTARY ONLY
--
-- Ordering is deliberate: structural checks run and RAISE first, so the destructive
-- TRUNCATE probe in 3.10 executes only once we already believe the privilege is gone.
-- =====================================================================================
do $block3$
declare
  r              text;
  p              text;
  v_leftover     text;
  v_rows         bigint;
  v_policies     int;
  v_defs         int;
  v_constraints  int;
  v_indexes      int;
  v_exec_bad     text;
  v_colbad       text;
  v_acl_after    text;
  v_sqlstate     text;
  v_probe_ok     boolean;
begin
  ---- 3.1 PRIMARY: direct ACL inspection — no entry for any of the six privileges ----------
  select string_agg(distinct pg_get_userbyid(acl.grantee) || ':' || acl.privilege_type, ' · '
                    order by pg_get_userbyid(acl.grantee) || ':' || acl.privilege_type)
    into v_leftover
    from pg_class c,
         aclexplode(coalesce(c.relacl, acldefault('r', c.relowner))) acl
   where c.oid = 'public.session_teachers'::regclass
     and acl.grantee <> 0                                        -- exclude PUBLIC pseudo-role
     and pg_get_userbyid(acl.grantee) in ('authenticated','anon','service_role')
     and acl.privilege_type in ('INSERT','UPDATE','DELETE','TRUNCATE','TRIGGER','REFERENCES');

  if v_leftover is not null then
    raise exception 'S0A VERIFY FAIL (ACL): direct ACL entries still present: %', v_leftover;
  end if;

  ---- 3.2 PRIMARY: PUBLIC must hold none of the six ------------------------------------------
  select string_agg(distinct acl.privilege_type, ' · ' order by acl.privilege_type)
    into v_leftover
    from pg_class c,
         aclexplode(coalesce(c.relacl, acldefault('r', c.relowner))) acl
   where c.oid = 'public.session_teachers'::regclass
     and acl.grantee = 0
     and acl.privilege_type in ('INSERT','UPDATE','DELETE','TRUNCATE','TRIGGER','REFERENCES');

  if v_leftover is not null then
    raise exception 'S0A VERIFY FAIL (ACL): PUBLIC holds: %', v_leftover;
  end if;

  ---- 3.3 capture resulting ACL for the migration log ------------------------------------------
  select coalesce(c.relacl::text, '<null>') into v_acl_after
    from pg_class c where c.oid = 'public.session_teachers'::regclass;

  ---- 3.4 corroborating: table-level checks, six privileges x three roles -----------------------
  foreach r in array array['authenticated','anon','service_role'] loop
    foreach p in array array['INSERT','UPDATE','DELETE','TRUNCATE','TRIGGER','REFERENCES'] loop
      if has_table_privilege(r, 'public.session_teachers', p) then
        raise exception 'S0A VERIFY FAIL: role % still holds % on session_teachers', r, p;
      end if;
    end loop;
  end loop;

  ---- 3.5 corroborating: column-level residue scan (D310-cand) ----------------------------------
  -- Scans every live user column from pg_attribute. INSERT and UPDATE are required by the
  -- decision; REFERENCES is additionally checked because it is column-capable and is one
  -- of the six privileges being revoked.
  select string_agg(x.role_name || '/' || x.attname || '/' || x.priv, ' · ')
    into v_colbad
    from (
      select rr.role_name, a.attname, pp.priv
        from pg_attribute a
        cross join (values ('authenticated'),('anon'),('service_role')) as rr(role_name)
        cross join (values ('INSERT'),('UPDATE'),('REFERENCES')) as pp(priv)
       where a.attrelid = 'public.session_teachers'::regclass
         and a.attnum > 0
         and not a.attisdropped
         and has_column_privilege(rr.role_name, a.attrelid, a.attname, pp.priv)
    ) x;

  if v_colbad is not null then
    raise exception 'S0A VERIFY FAIL (column-level): residual column privileges: %', v_colbad;
  end if;

  ---- 3.6 SELECT deliberately retained ------------------------------------------------------------
  if not has_table_privilege('authenticated', 'public.session_teachers', 'SELECT') then
    raise exception 'S0A VERIFY FAIL: authenticated lost SELECT — compatibility window broken';
  end if;

  ---- 3.7 owner path preserved (ops escape hatch) ---------------------------------------------------
  foreach p in array array['INSERT','UPDATE','DELETE','TRUNCATE','TRIGGER','REFERENCES'] loop
    if not has_table_privilege('postgres', 'public.session_teachers', p) then
      raise exception 'S0A VERIFY FAIL: postgres lost % — operator escape hatch destroyed', p;
    end if;
  end loop;

  ---- 3.8 nothing structural or data-bearing changed --------------------------------------------------
  select count(*) into v_rows from public.session_teachers;
  if v_rows <> 2 then
    raise exception 'S0A VERIFY FAIL: row count changed to % (expected 2)', v_rows;
  end if;

  select count(*) into v_policies
    from pg_policies where schemaname='public' and tablename='session_teachers';
  if v_policies <> 4 then
    raise exception 'S0A VERIFY FAIL: policy count changed to % (expected 4)', v_policies;
  end if;

  if not exists (select 1 from pg_policies
                  where schemaname='public' and tablename='session_teachers'
                    and policyname='session_teachers_select_school') then
    raise exception 'S0A VERIFY FAIL: SELECT policy session_teachers_select_school missing';
  end if;

  select count(*) into v_constraints from pg_constraint where conrelid='public.session_teachers'::regclass;
  if v_constraints <> 5 then
    raise exception 'S0A VERIFY FAIL: constraint count changed to % (expected 5)', v_constraints;
  end if;

  select count(*) into v_indexes from pg_index where indrelid='public.session_teachers'::regclass;
  if v_indexes <> 2 then
    raise exception 'S0A VERIFY FAIL: index count changed to % (expected 2)', v_indexes;
  end if;

  ---- 3.9 definer writers + their EXECUTE grants unchanged ------------------------------------------------
  select count(*) into v_defs
    from pg_proc pr join pg_namespace n on n.oid = pr.pronamespace
   where n.nspname='public'
     and pr.proname in ('create_lesson_session','set_session_teachers',
                        'set_distribution_lead','assign_class_distribution','start_session')
     and pr.prosecdef = true
     and pr.proowner::regrole::text = 'postgres';
  if v_defs <> 5 then
    raise exception 'S0A VERIFY FAIL: definer assignment RPC count = % (expected 5)', v_defs;
  end if;

  select string_agg(pr.proname, ', ')
    into v_exec_bad
    from pg_proc pr join pg_namespace n on n.oid = pr.pronamespace
   where n.nspname='public'
     and pr.proname in ('create_lesson_session','set_session_teachers',
                        'set_distribution_lead','assign_class_distribution','start_session')
     and not has_function_privilege('authenticated', pr.oid, 'EXECUTE');
  if v_exec_bad is not null then
    raise exception 'S0A VERIFY FAIL: authenticated lost EXECUTE on: %', v_exec_bad;
  end if;

  select string_agg(pr.proname, ', ')
    into v_exec_bad
    from pg_proc pr join pg_namespace n on n.oid = pr.pronamespace
   where n.nspname='public'
     and pr.proname in ('create_lesson_session','set_session_teachers',
                        'set_distribution_lead','assign_class_distribution','start_session')
     and has_function_privilege('anon', pr.oid, 'EXECUTE');
  if v_exec_bad is not null then
    raise exception 'S0A VERIFY FAIL: anon unexpectedly holds EXECUTE on: %', v_exec_bad;
  end if;

  ---- 3.10 SUPPLEMENTARY FUNCTIONAL PROBES -------------------------------------------------------------------
  -- INTERPRETATION LIMITS — read before trusting these:
  --
  --   * An INSERT denial raises SQLSTATE 42501 for BOTH a missing table grant AND an
  --     RLS policy denial. authenticated and anon have rolbypassrls = false and are
  --     subject to RLS, so an INSERT probe on those roles CANNOT distinguish the two.
  --     It is therefore NOT evidence of grant removal, and is NOT run for them.
  --
  --   * service_role has rolbypassrls = true, so RLS cannot be the cause of its denial.
  --     An INSERT probe on service_role IS meaningful supplementary evidence.
  --
  --   * TRUNCATE is not subject to RLS for any role. A TRUNCATE denial is attributable
  --     to the privilege check alone, and is meaningful for all three roles.
  --
  --   * Structural checks 3.1-3.5 remain the PRIMARY evidence. These probes corroborate
  --     only. No claim of the form "N/N INSERT probes prove grant removal" is made.
  --
  --   * Real-login post-apply direct-write QA remains mandatory regardless of this block.
  --
  -- Residue: none. Had a probe succeeded, the RAISE below unwinds the whole transaction,
  -- and TRUNCATE is transactional in PostgreSQL.

  -- 3.10a TRUNCATE probe — RLS-immune, valid for all three roles
  foreach r in array array['authenticated','anon','service_role'] loop
    v_probe_ok := false;
    v_sqlstate := null;
    begin
      execute format('set local role %I', r);
      begin
        truncate table public.session_teachers;
        v_sqlstate := '00000';                    -- reached only if privilege check passed
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
      raise exception 'S0A VERIFY FAIL (TRUNCATE probe, role %): expected 42501, got %. TRUNCATE path still reachable.', r, v_sqlstate;
    end if;
  end loop;

  -- 3.10b INSERT probe — service_role ONLY (BYPASSRLS makes the result attributable)
  v_probe_ok := false;
  v_sqlstate := null;
  begin
    set local role service_role;
    begin
      insert into public.session_teachers (session_id, profile_id, role)
      values (gen_random_uuid(), gen_random_uuid(), 'assist');
      v_sqlstate := '00000';
    exception
      when insufficient_privilege then
        v_probe_ok := true;
        v_sqlstate := '42501';
      when others then
        v_sqlstate := SQLSTATE;                   -- e.g. 23503 FK => privilege check PASSED
    end;
    reset role;
  exception when others then
    reset role;
    raise;
  end;

  if not v_probe_ok then
    raise exception 'S0A VERIFY FAIL (INSERT probe, service_role): expected 42501, got %. Grant still effective.', v_sqlstate;
  end if;

  ---- 3.11 post-probe integrity re-check -------------------------------------------------------------------------
  select count(*) into v_rows from public.session_teachers;
  if v_rows <> 2 then
    raise exception 'S0A VERIFY FAIL: row count = % after probes (expected 2)', v_rows;
  end if;

  raise notice 'S0A BLOCK 3 OK — ACL after: %', v_acl_after;
  raise notice 'S0A BLOCK 3 OK — 6 privileges revoked for authenticated+anon+service_role (ACL-verified, PRIMARY evidence)';
  raise notice 'S0A BLOCK 3 OK — column-level residue: none across 5 user columns x 3 roles x (INSERT,UPDATE,REFERENCES)';
  raise notice 'S0A BLOCK 3 OK — supplementary probes: TRUNCATE 3/3 = 42501; INSERT service_role = 42501. INSERT probe NOT run for authenticated/anon (RLS makes 42501 ambiguous)';
  raise notice 'S0A BLOCK 3 OK — preserved: rows=2 policies=4 constraints=5 indexes=2 definer_rpcs=5; SELECT retained';
  raise notice 'S0A BLOCK 3 OK — MAINTAIN deliberately NOT revoked (S0A-FINDING-02, pending Owner decision)';
end
$block3$;
