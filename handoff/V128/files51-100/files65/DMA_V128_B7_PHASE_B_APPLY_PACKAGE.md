# V128-B7 PHASE B — APPLY PACKAGE (ASSEMBLY ONLY)

> **Mode:** APPLY PACKAGE ASSEMBLY. **NOT APPLIED. No functions created. No mutation.**
> execute / ledger / registry / FE / decision-table schema **untouched**. Canonical append deferred (Phase D).
> **Migration name:** `v128_b7_pb_decision_helpers`
> **Endpoint at assembly:** RULES D363 · SYSTEM_MAP v1.51 · backend tail `20260815124454` · FE pin `2.8.5`.

---

## STEP 0 — LIVE RE-PIN (read-only, observed)

| Item | Observed | Expected / Note |
|---|---|---|
| migration tail | `20260815124454` | = Phase A tail ✅ |
| public fns | **248** | → 251 (+3) on apply |
| public secdef | **236** | → 239 (+3) on apply |
| mc_internal fns | **3** `{_mc_begin_action, _mc_commit_action, _mc_lookup_action}` | → 5 (+2) on apply |
| public tables | **93** | +0 |
| public policies | **168** | +0 |
| `execute_mission_control_action` md5 | `7a526354c820ab5f767ee7403c6e917d` · INVOKER | frozen |
| `mc_internal._mc_begin_action` md5 | `f47260ef3f06811ac2e83807989b26c7` | frozen (PRESENT — see note) |
| `mc_internal._mc_commit_action` md5 | `ce36c5fe109e99a919158a4482940c6a` | frozen |
| `mc_internal._mc_lookup_action` md5 | `5d940037687be0a398a232cf987bfcf6` | frozen |
| 5 Phase-B helpers | **absent** | no residue ✅ |
| `mission_control_decisions` | exists · auth SELECT=✅ INSERT/UPDATE/DELETE=❌ | client SELECT-only ✅ |
| dependencies | `public.current_profile()` ✅ · `public.current_profile_role()` ✅ | required by helpers |
| ledger rows | **12** | baseline |
| `class.assign` risk | **MEDIUM** | registry baseline |

**Checklist correction:** the STEP-0 request said `_mc_begin_action absent`; live state has it **present** and frozen. Correct invariant = `mc_internal` holds exactly the 3 frozen functions and none of the 5 Phase-B helpers → **holds**.

---

## STEP 1 — MIGRATION ARTIFACT  `v128_b7_pb_decision_helpers`

> Recovered logic verbatim from the proven Phase-B rehearsal (chat `2e66332a`, turn 15, run 2, `all_pass=t`). Only deviation from the recovered form: `CREATE FUNCTION` → `CREATE OR REPLACE FUNCTION` (per STEP 1 instruction); **function bodies byte-identical, no redesign, no added behavior**.

### BLOCK 1 — CREATE OR REPLACE (2 `mc_internal` + 3 `public`)

```sql
CREATE OR REPLACE FUNCTION mc_internal._mc_open_decision(p_request_id uuid) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $B1$
DECLARE L record; v_risk text; v_school uuid; v_cnt int; v_id uuid;
BEGIN
  SELECT action_key,object_type,object_id,actor_id,intent_fingerprint,intent_hash_version INTO L
    FROM public.mission_control_action_requests WHERE request_id=p_request_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'ledger_row_not_found'; END IF;
  IF L.intent_fingerprint IS NULL THEN RAISE EXCEPTION 'intent_not_forged'; END IF;
  v_risk := (SELECT risk_level FROM public.mission_control_action_registry WHERE action_key=L.action_key);
  IF v_risk NOT IN ('HIGH','CRITICAL') THEN RAISE EXCEPTION 'decision_not_required'; END IF;
  IF L.object_type='class' THEN SELECT school_id INTO v_school FROM public.classes WHERE id=L.object_id;
  ELSE RAISE EXCEPTION 'object_scope_unsupported'; END IF;
  SELECT count(*) INTO v_cnt FROM public.profiles WHERE role IN ('master_admin','sub_admin') AND school_id=v_school AND id<>L.actor_id;
  IF v_cnt=0 THEN RAISE EXCEPTION 'no_eligible_approver'; END IF;
  INSERT INTO public.mission_control_decisions (action_request_id,intent_fingerprint,intent_hash_version,action_key,object_type,object_id,risk_level,state,requested_by,expires_at)
  VALUES (p_request_id,L.intent_fingerprint,L.intent_hash_version,L.action_key,L.object_type,L.object_id,v_risk,'pending',L.actor_id,now()+interval '72 hours')
  ON CONFLICT (intent_fingerprint) DO NOTHING RETURNING id INTO v_id;
  IF v_id IS NULL THEN SELECT id INTO v_id FROM public.mission_control_decisions WHERE intent_fingerprint=L.intent_fingerprint;
    RETURN jsonb_build_object('opened',false,'decision_id',v_id); END IF;
  RETURN jsonb_build_object('opened',true,'decision_id',v_id,'state','pending');
END $B1$;

CREATE OR REPLACE FUNCTION public.resolve_mission_control_decision(p_decision_id uuid,p_verdict text,p_reason text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $B2$
DECLARE v_caller uuid; v_role text; v_cschool uuid; D record; v_school uuid; v_new text;
BEGIN
  v_caller := public.current_profile(); IF v_caller IS NULL THEN RAISE EXCEPTION 'actor_unresolved'; END IF;
  v_role := public.current_profile_role()::text;
  SELECT school_id INTO v_cschool FROM public.profiles WHERE id=v_caller;
  SELECT * INTO D FROM public.mission_control_decisions WHERE id=p_decision_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'decision_not_found'; END IF;
  IF D.state='pending' AND now()>D.expires_at THEN
    UPDATE public.mission_control_decisions SET state='expired',updated_at=now() WHERE id=D.id AND state='pending';
    RAISE EXCEPTION 'decision_expired'; END IF;
  IF D.state<>'pending' THEN RAISE EXCEPTION 'decision_not_pending'; END IF;
  IF D.object_type='class' THEN SELECT school_id INTO v_school FROM public.classes WHERE id=D.object_id;
  ELSE RAISE EXCEPTION 'object_scope_unsupported'; END IF;
  IF NOT (v_role IN ('master_admin','sub_admin') AND v_cschool=v_school) THEN RAISE EXCEPTION 'not_authorized_to_decide'; END IF;
  IF v_caller=D.requested_by THEN RAISE EXCEPTION 'self_decision_forbidden'; END IF;
  IF p_verdict='approve' THEN v_new:='approved'; ELSIF p_verdict='reject' THEN v_new:='rejected'; ELSE RAISE EXCEPTION 'invalid_verdict'; END IF;
  UPDATE public.mission_control_decisions SET state=v_new,decided_by=v_caller,decision_reason=p_reason,updated_at=now() WHERE id=D.id AND state='pending';
  RETURN jsonb_build_object('decision_id',D.id,'state',v_new,'decided_by',v_caller);
END $B2$;

CREATE OR REPLACE FUNCTION public.cancel_mission_control_decision(p_decision_id uuid,p_reason text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $B3$
DECLARE v_caller uuid; v_role text; v_cschool uuid; D record; v_school uuid;
BEGIN
  v_caller := public.current_profile(); IF v_caller IS NULL THEN RAISE EXCEPTION 'actor_unresolved'; END IF;
  v_role := public.current_profile_role()::text;
  SELECT school_id INTO v_cschool FROM public.profiles WHERE id=v_caller;
  SELECT * INTO D FROM public.mission_control_decisions WHERE id=p_decision_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'decision_not_found'; END IF;
  IF D.state='pending' AND now()>D.expires_at THEN
    UPDATE public.mission_control_decisions SET state='expired',updated_at=now() WHERE id=D.id AND state='pending';
    RAISE EXCEPTION 'decision_expired'; END IF;
  IF D.state<>'pending' THEN RAISE EXCEPTION 'decision_not_pending'; END IF;
  IF D.object_type='class' THEN SELECT school_id INTO v_school FROM public.classes WHERE id=D.object_id;
  ELSE RAISE EXCEPTION 'object_scope_unsupported'; END IF;
  IF NOT (v_caller=D.requested_by OR (v_role IN ('master_admin','sub_admin') AND v_cschool=v_school)) THEN RAISE EXCEPTION 'not_authorized_to_cancel'; END IF;
  UPDATE public.mission_control_decisions SET state='cancelled',decided_by=v_caller,decision_reason=p_reason,updated_at=now() WHERE id=D.id AND state='pending';
  RETURN jsonb_build_object('decision_id',D.id,'state','cancelled');
END $B3$;

CREATE OR REPLACE FUNCTION mc_internal._mc_expire_decisions() RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $B4$
DECLARE n int; BEGIN
  UPDATE public.mission_control_decisions SET state='expired',updated_at=now() WHERE state='pending' AND now()>expires_at;
  GET DIAGNOSTICS n = ROW_COUNT; RETURN n; END $B4$;

CREATE OR REPLACE FUNCTION public.get_mission_control_decision_inbox() RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $B5$
DECLARE v_caller uuid; v_role text; v_cschool uuid; res jsonb; BEGIN
  v_caller := public.current_profile(); v_role := public.current_profile_role()::text;
  IF v_caller IS NULL OR v_role NOT IN ('master_admin','sub_admin') THEN RETURN '[]'::jsonb; END IF;
  SELECT school_id INTO v_cschool FROM public.profiles WHERE id=v_caller;
  PERFORM mc_internal._mc_expire_decisions();
  SELECT coalesce(jsonb_agg(jsonb_build_object('decision_id',d.id,'requested_by',d.requested_by) ORDER BY d.created_at),'[]'::jsonb) INTO res
    FROM public.mission_control_decisions d JOIN public.classes c ON c.id=d.object_id
    WHERE d.state='pending' AND d.object_type='class' AND c.school_id=v_cschool AND d.requested_by<>v_caller;
  RETURN res; END $B5$;
```

### BLOCK 2 — ACL (D15/D231: REVOKE PUBLIC/anon → GRANT authenticated only; DEFINER boundary preserved)

```sql
REVOKE ALL ON FUNCTION mc_internal._mc_open_decision(uuid)                             FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION mc_internal._mc_open_decision(uuid)                          TO authenticated;
REVOKE ALL ON FUNCTION mc_internal._mc_expire_decisions()                              FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION mc_internal._mc_expire_decisions()                           TO authenticated;
REVOKE ALL ON FUNCTION public.resolve_mission_control_decision(uuid,text,text)         FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.resolve_mission_control_decision(uuid,text,text)      TO authenticated;
REVOKE ALL ON FUNCTION public.cancel_mission_control_decision(uuid,text)               FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.cancel_mission_control_decision(uuid,text)            TO authenticated;
REVOKE ALL ON FUNCTION public.get_mission_control_decision_inbox()                     FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.get_mission_control_decision_inbox()                  TO authenticated;
```

### BLOCK 3 — VERIFY (fail-closed; migration commits only if every assertion holds), then PostgREST reload

```sql
DO $VERIFY$
DECLARE v jsonb; ok boolean;
BEGIN
  v := jsonb_build_object(
    'open_exists',    to_regprocedure('mc_internal._mc_open_decision(uuid)') is not null,
    'expire_exists',  to_regprocedure('mc_internal._mc_expire_decisions()') is not null,
    'resolve_exists', to_regprocedure('public.resolve_mission_control_decision(uuid,text,text)') is not null,
    'cancel_exists',  to_regprocedure('public.cancel_mission_control_decision(uuid,text)') is not null,
    'inbox_exists',   to_regprocedure('public.get_mission_control_decision_inbox()') is not null,
    'all_secdef', (select bool_and(p.prosecdef)
        from pg_proc p join pg_namespace n on n.oid=p.pronamespace
        where (n.nspname='mc_internal' and p.proname in ('_mc_open_decision','_mc_expire_decisions'))
           or (n.nspname='public' and p.proname in ('resolve_mission_control_decision','cancel_mission_control_decision','get_mission_control_decision_inbox'))),
    'all_search_path_empty', (select bool_and('search_path=""' = ANY(coalesce(p.proconfig,'{}'::text[])))
        from pg_proc p join pg_namespace n on n.oid=p.pronamespace
        where (n.nspname='mc_internal' and p.proname in ('_mc_open_decision','_mc_expire_decisions'))
           or (n.nspname='public' and p.proname in ('resolve_mission_control_decision','cancel_mission_control_decision','get_mission_control_decision_inbox'))),
    'anon_none', not (
           has_function_privilege('anon','mc_internal._mc_open_decision(uuid)','EXECUTE')
        or has_function_privilege('anon','mc_internal._mc_expire_decisions()','EXECUTE')
        or has_function_privilege('anon','public.resolve_mission_control_decision(uuid,text,text)','EXECUTE')
        or has_function_privilege('anon','public.cancel_mission_control_decision(uuid,text)','EXECUTE')
        or has_function_privilege('anon','public.get_mission_control_decision_inbox()','EXECUTE')),
    'auth_exec_all', (
           has_function_privilege('authenticated','mc_internal._mc_open_decision(uuid)','EXECUTE')
       and has_function_privilege('authenticated','mc_internal._mc_expire_decisions()','EXECUTE')
       and has_function_privilege('authenticated','public.resolve_mission_control_decision(uuid,text,text)','EXECUTE')
       and has_function_privilege('authenticated','public.cancel_mission_control_decision(uuid,text)','EXECUTE')
       and has_function_privilege('authenticated','public.get_mission_control_decision_inbox()','EXECUTE')),
    'execute_md5_unchanged', md5(pg_get_functiondef((select p.oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname='execute_mission_control_action' and p.prokind='f')))='7a526354c820ab5f767ee7403c6e917d',
    'execute_invoker', not (select p.prosecdef from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname='execute_mission_control_action' and p.prokind='f'),
    'commit_md5_unchanged', md5(pg_get_functiondef((select p.oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='mc_internal' and p.proname='_mc_commit_action' and p.prokind='f')))='ce36c5fe109e99a919158a4482940c6a',
    'begin_md5_unchanged',  md5(pg_get_functiondef((select p.oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='mc_internal' and p.proname='_mc_begin_action' and p.prokind='f')))='f47260ef3f06811ac2e83807989b26c7',
    'lookup_md5_unchanged', md5(pg_get_functiondef((select p.oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='mc_internal' and p.proname='_mc_lookup_action' and p.prokind='f')))='5d940037687be0a398a232cf987bfcf6',
    'decisions_select_only', (
           has_table_privilege('authenticated','public.mission_control_decisions','SELECT')
       and not has_table_privilege('authenticated','public.mission_control_decisions','INSERT')
       and not has_table_privilege('authenticated','public.mission_control_decisions','UPDATE')
       and not has_table_privilege('authenticated','public.mission_control_decisions','DELETE')),
    'public_fns',      (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public'),
    'public_secdef',   (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.prosecdef),
    'mc_internal_fns', (select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='mc_internal'),
    'public_tables',   (select count(*) from pg_tables where schemaname='public'),
    'public_policies', (select count(*) from pg_policies where schemaname='public'),
    'ledger_rows',     (select count(*) from public.mission_control_action_requests),
    'class_assign_risk',(select risk_level from public.mission_control_action_registry where action_key='class.assign')
  );

  ok := (
        (v->>'open_exists')::boolean and (v->>'expire_exists')::boolean and (v->>'resolve_exists')::boolean
    and (v->>'cancel_exists')::boolean and (v->>'inbox_exists')::boolean
    and (v->>'all_secdef')::boolean and (v->>'all_search_path_empty')::boolean
    and (v->>'anon_none')::boolean and (v->>'auth_exec_all')::boolean
    and (v->>'execute_md5_unchanged')::boolean and (v->>'execute_invoker')::boolean
    and (v->>'commit_md5_unchanged')::boolean and (v->>'begin_md5_unchanged')::boolean and (v->>'lookup_md5_unchanged')::boolean
    and (v->>'decisions_select_only')::boolean
    and (v->>'public_fns')::int      = 251
    and (v->>'public_secdef')::int   = 239
    and (v->>'mc_internal_fns')::int = 5
    and (v->>'public_tables')::int   = 93
    and (v->>'public_policies')::int = 168
    and (v->>'ledger_rows')::int     = 12
    and (v->>'class_assign_risk')    = 'MEDIUM'
  );

  IF NOT ok THEN
    RAISE EXCEPTION 'V128_B7_PB_VERIFY_FAILED | %', v::text;
  END IF;
END
$VERIFY$;

NOTIFY pgrst, 'reload schema';
```

**Pinned-literal note:** `ledger_rows = 12` and `class_assign_risk = 'MEDIUM'` are assembly-time baselines used to prove this migration mutates neither table (the migration body contains **no DML** against ledger or registry). If legitimate pilot activity changes the ledger count before apply, the immediately-preceding apply-time re-pin (see STEP 2) catches it and the literal is refreshed — fail-closed, so worst case is a spurious rollback with zero side effects.

---

## VERIFY MATRIX (what BLOCK 3 enforces)

| # | Assertion | Expected | Guards |
|---|---|---|---|
| 1 | 5 helpers exist (`to_regprocedure` ≠ null) | true ×5 | creation |
| 2 | all 5 `prosecdef=true` | true | DEFINER posture |
| 3 | all 5 `proconfig` ∋ `search_path=""` | true | search_path='' |
| 4 | `anon` EXECUTE on any of the 5 | none | ACL — anon sealed |
| 5 | `authenticated` EXECUTE on all 5 | true | ACL — auth only |
| 6 | `execute_mission_control_action` md5 | `7a526354…917d` | execute frozen (no wiring) |
| 7 | `execute_mission_control_action` INVOKER | `prosecdef=false` | INVOKER invariant |
| 8 | `_mc_commit_action` md5 | `ce36c5fe…0c6a` | commit-core frozen |
| 9 | `_mc_begin_action` md5 | `f47260ef…26c7` | begin frozen |
| 10 | `_mc_lookup_action` md5 | `5d940037…fcf6` | lookup frozen |
| 11 | `mission_control_decisions` client access | SELECT-only | table schema/ACL unchanged |
| 12 | public fns | **251** (248+3) | delta +3 |
| 13 | public secdef | **239** (236+3) | delta +3 |
| 14 | `mc_internal` fns | **5** (3+2) | delta +2 |
| 15 | public tables | **93** | +0 |
| 16 | public policies | **168** | +0 |
| 17 | ledger rows | **12** | no ledger mutation |
| 18 | `class.assign` risk | **MEDIUM** | no registry mutation |

Any single failure → `RAISE` → whole migration rolls back (atomic, no `schema_migrations` row written).

---

## STEP 2 — REHEARSAL PLAN (to run at apply-time authorization; nothing commits)

The `apply_migration` tool wraps the whole payload in one transaction, so a terminal `RAISE` aborts it atomically. Rehearsal = execute the full payload inside a single `DO` harness with an always-`RAISE` terminal, exactly as the recovered turn-15 harness already proved these bodies.

**R1 · Re-pin (read-only)** — reconfirm STEP-0 baselines immediately before rehearsal (tail `20260815124454`, fns 248/secdef 236/mc_internal 3, tables 93, policies 168, ledger 12, class.assign MEDIUM, 5 helpers absent, frozen md5s). STOP on any drift.

**R2 · Rollback-safety probe** — `DO $p$ BEGIN CREATE TABLE public._reh_probe(x int); RAISE EXCEPTION 'PROBE'; END $p$;` then confirm `to_regclass('public._reh_probe') is null` → proves DDL inside a RAISE-aborted block leaves no residue.

**R3 · Full rehearsal (one aborted transaction)** — single `DO` block:
1. `EXECUTE` the 5 `CREATE OR REPLACE` statements (BLOCK 1, via dynamic `EXECUTE $Q$…$Q$`).
2. `EXECUTE` the 10 REVOKE/GRANT statements (BLOCK 2).
3. Compute the BLOCK-3 `v` jsonb + `ok` boolean.
4. `RAISE EXCEPTION 'PHASEB_APPLY_REH|ok=%|v=%', ok, v::text;` → forces rollback while surfacing the full assertion payload.
   - **PASS criterion:** `ok=t` and every matrix row green (fns 251 · secdef 239 · mc_internal 5 · tables 93 · policies 168 · execute/commit/begin/lookup md5 unchanged · decisions SELECT-only · anon none · auth all).

**R4 · Rollback proof (separate read-only query)** — after R3, confirm zero residue:
- 5 helpers **absent** (`to_regprocedure` null ×5)
- public fns **248**, public secdef **236**, mc_internal **3**
- `execute` md5 **unchanged** `7a526354…917d`
- `mission_control_decisions` rows **unchanged** (0), ledger **12**
- `class.assign` risk **MEDIUM**, tail **`20260815124454`**

Only on R3 `ok=t` **and** R4 zero-residue does APPLY proceed.

---

## STEP 3 — STOP

**Package assembled. NOT APPLIED.** No functions created; execute / ledger / registry / FE / decision-table schema untouched; no canonical append.

**On explicit APPLY authorization**, the sequence is:
1. Re-pin (R1) → STOP on drift.
2. Run rehearsal (R2–R4) → require `ok=t` + zero residue.
3. Swap the rehearsal's always-`RAISE` for the fail-closed `IF NOT ok THEN RAISE` guard (BLOCK 3 as written) and `apply_migration` name `v128_b7_pb_decision_helpers` **once**.
4. Re-verify live: fns 251 · mc_internal 5 · execute md5 `7a526354…` unchanged · decisions SELECT-only · class.assign MEDIUM.
5. Report. (Phase C execute-wiring and Phase D canonicalization remain out of scope.)

**Expected APPLY delta (and only this):** public functions **+3** · `mc_internal` **+2** (total functions +5, secdef +5) · tables **+0** · policies **+0** · execute/ledger/registry/adapter/FE **unchanged**. Dormant: `_mc_open_decision` is called only by execute, which Phase B does not modify → no decision rows producible → no live behavior change.

**WAITING FOR APPLY AUTHORIZATION.**
