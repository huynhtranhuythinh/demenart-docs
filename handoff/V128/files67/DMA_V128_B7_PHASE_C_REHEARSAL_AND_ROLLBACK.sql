-- =====================================================================
-- V128-B7 PHASE C — ROLLBACK REHEARSAL PACKAGE  (PREPARATION ONLY)
-- =====================================================================
-- NOT EXECUTED in this session. To be run in the APPLY/REHEARSAL session.
-- Every rehearsal block is transaction-scoped BEGIN...ROLLBACK => zero residue.
-- The Supabase MCP runs autocommit + returns only the last statement's result,
-- so run each numbered block as ONE execute_sql call and read its RAISE NOTICE
-- via the returned notice/last-select. Do NOT concatenate blocks.
-- =====================================================================


-- =====================================================================
-- SECTION 0 — PRE-STATE SNAPSHOT (read-only; run first, record output)
-- =====================================================================
select jsonb_build_object(
  'execute_md5', md5(pg_get_functiondef('public.execute_mission_control_action'::regproc)),
  'tables', (select count(*) from pg_tables where schemaname='public'),
  'fns', (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.prokind='f'),
  'secdef', (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.prokind='f' and p.prosecdef),
  'policies', (select count(*) from pg_policies where schemaname='public'),
  'triggers', (select count(*) from pg_trigger t join pg_class c on c.oid=t.tgrelid join pg_namespace n on n.oid=c.relnamespace where not t.tgisinternal and n.nspname='public'),
  'mc_internal_fns', (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='mc_internal' and p.prokind='f'),
  'decisions', (select count(*) from public.mission_control_decisions),
  'ledger', (select count(*) from public.mission_control_action_requests),
  'distributions', (select count(*) from public.class_distributions),
  'begin_md5', md5(pg_get_functiondef('mc_internal._mc_begin_action'::regproc)),
  'commit_md5', md5(pg_get_functiondef('mc_internal._mc_commit_action'::regproc)),
  'lookup_md5', md5(pg_get_functiondef('mc_internal._mc_lookup_action'::regproc)),
  'open_md5', md5(pg_get_functiondef('mc_internal._mc_open_decision'::regproc))
) as pre_state;
-- EXPECTED baseline: execute_md5=7a526354c820ab5f767ee7403c6e917d ·
--   93·251·239·168·33·5 · decisions 0 · begin f47260ef.. · commit ce36c5fe.. ·
--   lookup 5d940037.. · open e5b12a96..


-- =====================================================================
-- SECTION A — STRUCTURAL REHEARSAL (apply + VERIFY + rollback, zero residue)
-- Run as ONE call. Proves the artifact compiles, VERIFY passes, and the
-- transaction rolls back to the exact pre-image md5.
-- =====================================================================
DO $rehearse$
DECLARE
  v_pre  text := '7a526354c820ab5f767ee7403c6e917d';
  v_post text;
BEGIN
  IF md5(pg_get_functiondef('public.execute_mission_control_action'::regproc)) <> v_pre THEN
    RAISE EXCEPTION 'PRE-DRIFT: execute md5 not at baseline; abort rehearsal';
  END IF;

  -- >>> paste BLOCK 1 (CREATE OR REPLACE) here, then BLOCK 2 (REVOKE/GRANT) here <<<
  -- (NOTIFY pgrst is a no-op inside DO; harmless. VERIFY BLOCK 3 body is inlined below.)

  -- Inline VERIFY assertions (mirror of BLOCK 3):
  IF (SELECT prosecdef FROM pg_proc WHERE oid='public.execute_mission_control_action'::regproc) THEN
    RAISE EXCEPTION 'REHEARSAL FAIL: execute became SECURITY DEFINER';
  END IF;
  IF md5(pg_get_functiondef('public.execute_mission_control_action'::regproc)) = v_pre THEN
    RAISE EXCEPTION 'REHEARSAL FAIL: execute body did not change (BLOCK 1 not pasted?)';
  END IF;
  v_post := md5(pg_get_functiondef('public.execute_mission_control_action'::regproc));
  RAISE NOTICE 'REHEARSAL: new execute md5 = %', v_post;
  -- frozen helpers unchanged
  IF md5(pg_get_functiondef('mc_internal._mc_open_decision'::regproc)) <> 'e5b12a9675093ad2d93a2c33943bea77' THEN RAISE EXCEPTION 'REHEARSAL FAIL: open drifted'; END IF;

  RAISE EXCEPTION 'REHEARSAL_ROLLBACK_OK';   -- force rollback => zero residue
EXCEPTION
  WHEN OTHERS THEN
    IF SQLERRM = 'REHEARSAL_ROLLBACK_OK' THEN
      RAISE NOTICE 'STRUCTURAL REHEARSAL PASS — transaction will roll back (zero residue)';
    ELSE
      RAISE;   -- surface real failures
    END IF;
END
$rehearse$;
-- NOTE: because the whole DO raised and was caught, and DO runs in the calling
-- transaction (autocommit single statement), no changes persist. Re-run SECTION 0
-- afterward to confirm execute_md5 back to 7a526354... (zero-residue proof).


-- =====================================================================
-- SECTION B — BEHAVIORAL REHEARSAL (C-E1 … C-E18)
-- Pattern per test: ONE execute_sql call =
--   BEGIN;
--     <apply BLOCK 1 + BLOCK 2>;                     -- migration under test
--     <optional fixture: risk elevation / actors>;   -- governed tests only
--     <JWT impersonation>;
--     <call execute + assert envelope>;
--     <capture side-effect deltas>;
--   ROLLBACK;
-- All side effects (ledger · decisions · class_distributions · audit) are
-- enumerated per test and asserted to ROLLBACK to zero.
--
-- Actor/fixture resolution is LIVE at rehearsal time (D1 — never hardcode):
--   -- requester + same-school approver (2 admins, same school):
--   SELECT id, user_id, school_id, role FROM public.profiles
--     WHERE role IN ('master_admin','sub_admin') ORDER BY school_id;
--   -- a class in that school for object_id
--   SELECT id, school_id FROM public.classes WHERE school_id = :school;
--   -- an entitled program for valid input
--   SELECT program_id FROM public.program_distributions WHERE ... ;
--
-- JWT impersonation (D333):
--   SELECT set_config('request.jwt.claims',
--     json_build_object('sub', :profiles_user_id, 'role','authenticated')::text, true);
--   SET LOCAL ROLE authenticated;    -- auth.uid() := sub ; current_profile() := profiles.id
-- =====================================================================

-- ---- AUTO REGRESSION (PRE == POST; class.assign stays MEDIUM) ----
-- C-E1  MEDIUM success (fresh)      : {ok:true,replayed:false,...}      | ledger +1(completed), dist +1, audit +1, decisions +0
-- C-E2  identical replay            : stored payload {replayed:true}    | Δ=0 all
-- C-E3  conflict (dist exists,newRID): MC_ACTION_CONFLICT (β2)          | ledger 0, dist 0, audit 0, decisions 0
-- C-E4  precedence (bad ctx/input/action/object): identical codes+order | Δ=0
-- C-E5  get_mission_control_actions : byte-compatible envelope          | Δ=0
--   -> ASSERT: for MEDIUM, decisions table receives ZERO rows in every case.

-- ---- GOVERNED PATH (require ROLLBACK-scoped risk elevation) ----
--   Fixture (inside the txn, rolled back):
--     UPDATE public.mission_control_action_registry SET risk_level='HIGH' WHERE action_key='class.assign';
--   Cleanup happens automatically at ROLLBACK.
--
-- C-E6  HIGH fresh intent            : MC_ACTION_DECISION_REQUIRED + decision{id,state:pending,expires_at}
--        adapter NOT called          | ledger +1(processing), decisions +1(pending), dist 0, audit 0
-- C-E7  HIGH pending replay (same RID): DECISION_REQUIRED {replayed:true}, SAME decision
--                                      | decisions +0 (UNIQUE fp), dist 0
-- C-E8  approve (resolve by 2nd admin) then original requester replays:
--        success ONCE {replayed:true} | ledger->completed, dist +1, audit +1, decision->approved
-- C-E9  rejected -> replay            : MC_ACTION_DECISION_REJECTED, adapter never called | ledger stays processing, dist 0
-- C-E10 expired  -> replay            : MC_ACTION_DECISION_EXPIRED,  adapter never called | ledger stays processing, dist 0
--        (force: UPDATE decisions SET expires_at=now()-interval '1s' WHERE ...; then replay -> effective expiry)
-- C-E11 cancelled -> replay           : MC_ACTION_DECISION_CANCELLED, adapter never called | ledger stays processing, dist 0
-- C-E12 self-approval blocked         : resolve() by requester -> 'self_decision_forbidden' (helper invariant; execute uninvolved)
-- C-E13 different-school approver      : resolve() by other-school admin -> 'not_authorized_to_decide'
-- C-E14 platform cancel blocked       : cancel() by platform admin (no school / not requester) -> 'not_authorized_to_cancel'
-- C-E15 no eligible approver          : school with ONLY the requester as admin -> MC_ACTION_NO_ELIGIBLE_APPROVER
--        FAIL-CLOSED                  | ledger 0 (rolled back by subtxn), decisions 0
-- C-E16 approval + changed intent     : replay with different program_id -> fp mismatch -> MC_ACTION_REQUEST_CONFLICT
--        no approval reuse            | Δ=0
-- C-E17 concurrent same fp/diff RID   : R1(actor A) opens+parks; R2(actor B) same fp fresh ->
--        Option B: B fail-closed MC_ACTION_DECISION_REQUIRED, adapter NOT reached;
--        approve; A replays -> success; B replays -> still DECISION_REQUIRED / cannot resume (RLS)
--                                      | 1 decision, 2 ledger processing rows, dist <=1, audit <=1
-- C-E18 terminal decision + ledger    : after reject/expire/cancel, ledger row stays 'processing';
--        replay returns governance-terminal deterministically; monitoring query surfaces orphan;
--        NO completion, NO commit boundary call.

--   Every governed test MUST end by asserting, post-ROLLBACK, that
--   decisions/ledger/class_distributions/audit counts equal the SECTION 0 baseline.


-- =====================================================================
-- SECTION C — ZERO-RESIDUE PROOF (run after Sections A/B; must equal SECTION 0)
-- =====================================================================
select
  (md5(pg_get_functiondef('public.execute_mission_control_action'::regproc)) = '7a526354c820ab5f767ee7403c6e917d') as execute_restored,
  (select count(*) from public.mission_control_decisions) as decisions_rows,           -- must be 0
  (select count(*) from public.mission_control_action_requests) as ledger_rows,         -- must equal SECTION 0
  (select count(*) from public.class_distributions) as dist_rows,                       -- must equal SECTION 0
  md5(pg_get_functiondef('mc_internal._mc_open_decision'::regproc)) as open_md5;         -- must be e5b12a96..


-- =====================================================================
-- SECTION D — ROLLBACK (production revert, if APPLY has occurred)
-- =====================================================================
-- Restore execute to the pinned pre-migration md5 7a526354c820ab5f767ee7403c6e917d.
-- Mechanism: CREATE OR REPLACE with the pre-image body (captured at apply time via
--   SELECT pg_get_functiondef('public.execute_mission_control_action'::regproc)
-- BEFORE BLOCK 1), then re-harden ACL, then NOTIFY.
--
--   CREATE OR REPLACE FUNCTION public.execute_mission_control_action(...) ...  -- pre-image body
--   REVOKE ALL ON FUNCTION public.execute_mission_control_action(text,uuid,jsonb,jsonb,uuid) FROM PUBLIC, anon, authenticated;
--   GRANT EXECUTE ON FUNCTION public.execute_mission_control_action(text,uuid,jsonb,jsonb,uuid) TO authenticated, postgres;
--   NOTIFY pgrst, 'reload schema';
--   -- VERIFY: md5 == 7a526354c820ab5f767ee7403c6e917d
-- Zero data repair: this phase creates no schema/ledger/decision changes, so no
-- data cleanup is required. Any decision rows produced by governed traffic before
-- rollback become inert (restored literal auto-path never reads them).
