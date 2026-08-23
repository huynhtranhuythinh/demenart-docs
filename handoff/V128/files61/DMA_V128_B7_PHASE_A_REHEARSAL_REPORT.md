# V128-B7 PHASE A — REHEARSAL REPORT (Decision Foundation Table)

> **Mode:** EXECUTION PREPARATION. Rehearsal executed inside an aborted transaction (RAISE-to-rollback). **Nothing committed.** APPLY **NOT** performed — awaiting authorization.
> **Scope (authorized):** `mission_control_decisions` table + constraints + indexes + RLS + `authenticated` SELECT-only. No helpers · no execute wiring · no ledger/adapter/registry/FE/canonical.

---

## STEP 0 · Canonical + live re-pin — NO DRIFT

- Endpoint: RULES **D363** · SYSTEM_MAP **v1.51** · gate `DMA_V128_B7_CTO_DECISION_GATE_RESULT`.
- Migration tail `20260815101138`; inventory **92·248·236·167·33·1**; `mc_internal` 3/3.
- Frozen md5 (all match canonical): execute `7a526354…` (INVOKER) · begin `f47260ef…` · commit `ce36c5fe…` · lookup `5d940037…` · adapter `03a1510b…` · gaa `3596633c…`.
- G1/G2/G3/G4 unchanged. **No STOP.**

## STEP 1 · Baseline

- `mission_control_decisions` **does not exist** (clean create).
- Ledger `mission_control_action_requests`: `authenticated` = **SELECT only**; `request_id` **UNIQUE** (FK target valid).
- `profiles` = `{id, role, school_id, user_id}` (RLS predicate ground).

## STEP 2 · Migration rehearsal (BEGIN → 3 blocks → VERIFY → ROLLBACK)

Executed as one `DO` block that applies all three blocks, runs VERIFY, then `RAISE EXCEPTION` to force rollback (abort-with-evidence — commit is structurally impossible in the rehearsal).

**Column-count correction:** the Phase-2 report labeled the set "14 columns"; the actual designed set is **15** (`id, action_request_id, intent_fingerprint, intent_hash_version, action_key, object_type, object_id, risk_level, state, requested_by, decided_by, decision_reason, expires_at, created_at, updated_at`). Same designed columns — label corrected to 15.

### VERIFY assertions — ALL PASS (`all_pass=t`)

| Assertion | Result |
|---|---|
| table exists | ✅ true |
| column_count = 15 | ✅ 15 |
| RLS enabled | ✅ true |
| `authenticated` SELECT | ✅ true |
| `authenticated` INSERT / UPDATE / DELETE | ✅ false / false / false |
| `anon` SELECT | ✅ false |
| `intent_fingerprint` NOT NULL | ✅ true |
| `intent_fingerprint` UNIQUE | ✅ true |
| `state` CHECK present | ✅ true |
| `risk_level` CHECK present | ✅ true |
| FK `action_request_id` → ledger | ✅ true |
| index (state, expires_at) | ✅ true |
| index (object_type, object_id) | ✅ true |
| policy `…_select_own` (SELECT · authenticated) | ✅ true |
| public tables 92 → **93** (+1) | ✅ 93 |
| public policies 167 → **168** (+1) | ✅ 168 |
| public functions 248 (Δ0) | ✅ 248 |
| public SECURITY DEFINER 236 (Δ0) | ✅ 236 |
| public triggers 33 (Δ0) | ✅ 33 |
| `mc_internal` fns 3 (Δ0) | ✅ 3 |
| ledger `authenticated` grants = ["SELECT"] (unchanged) | ✅ |
| frozen MC md5 (execute/begin/commit/lookup/adapter/gaa) unchanged | ✅ true |

### Rollback confirmation (post-rehearsal read)

`decisions_table_exists=false` · public tables **92** · policies **167** · tail `20260815101138`. **Nothing persisted.**

## Expected delta on APPLY (and only this)

- tables **+1** (`mission_control_decisions`) · policies **+1** (`…_select_own`).
- functions 0 · secdef 0 · triggers 0 · cron 0 · `mc_internal` 0.
- ledger / adapter / registry / execute / FE / Edge / Bunny: **0**.
- No client mutation surface (authenticated SELECT-only). Dormant — governs nothing live (`class.assign` MEDIUM stays auto).

## APPLY-ready migration (three-block D92 · fail-closed VERIFY · NOT YET APPLIED)

```sql
-- name: v128_b7_pa_decision_foundation_table
-- ===== BLOCK 1 — DDL =====
CREATE TABLE public.mission_control_decisions (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  action_request_id   uuid NOT NULL REFERENCES public.mission_control_action_requests(request_id),
  intent_fingerprint  text NOT NULL,
  intent_hash_version smallint NOT NULL,
  action_key          text NOT NULL,
  object_type         text NOT NULL,
  object_id           uuid NOT NULL,
  risk_level          text NOT NULL CHECK (risk_level IN ('LOW','MEDIUM','HIGH','CRITICAL')),
  state               text NOT NULL DEFAULT 'pending'
                        CHECK (state IN ('pending','approved','rejected','expired','cancelled')),
  requested_by        uuid NOT NULL,
  decided_by          uuid,
  decision_reason     text,
  expires_at          timestamptz NOT NULL,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT mission_control_decisions_intent_fingerprint_key UNIQUE (intent_fingerprint)
);
CREATE INDEX mission_control_decisions_state_expires_idx ON public.mission_control_decisions (state, expires_at);
CREATE INDEX mission_control_decisions_object_idx        ON public.mission_control_decisions (object_type, object_id);
ALTER TABLE public.mission_control_decisions ENABLE ROW LEVEL SECURITY;
CREATE POLICY mission_control_decisions_select_own ON public.mission_control_decisions
  FOR SELECT TO authenticated
  USING (requested_by IN (SELECT p.id FROM public.profiles p WHERE p.user_id = auth.uid()));

-- ===== BLOCK 2 — REVOKE/GRANT (D15) =====
REVOKE ALL ON public.mission_control_decisions FROM PUBLIC;
REVOKE ALL ON public.mission_control_decisions FROM anon;
REVOKE ALL ON public.mission_control_decisions FROM authenticated;
GRANT SELECT ON public.mission_control_decisions TO authenticated;

-- ===== BLOCK 3 — VERIFY (fail-closed rollback guard) =====
DO $$
BEGIN
  IF NOT (
        to_regclass('public.mission_control_decisions') IS NOT NULL
    AND (SELECT relrowsecurity FROM pg_class WHERE oid='public.mission_control_decisions'::regclass)
    AND     has_table_privilege('authenticated','public.mission_control_decisions','SELECT')
    AND NOT has_table_privilege('authenticated','public.mission_control_decisions','INSERT')
    AND NOT has_table_privilege('authenticated','public.mission_control_decisions','UPDATE')
    AND NOT has_table_privilege('authenticated','public.mission_control_decisions','DELETE')
    AND NOT has_table_privilege('anon','public.mission_control_decisions','SELECT')
    AND (SELECT attnotnull FROM pg_attribute WHERE attrelid='public.mission_control_decisions'::regclass AND attname='intent_fingerprint')
    AND EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.mission_control_decisions'::regclass AND contype='u' AND pg_get_constraintdef(oid) ~ 'intent_fingerprint')
    AND EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.mission_control_decisions'::regclass AND contype='c' AND pg_get_constraintdef(oid) ~ 'state')
    AND EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.mission_control_decisions'::regclass AND contype='c' AND pg_get_constraintdef(oid) ~ 'risk_level')
    AND EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.mission_control_decisions'::regclass AND contype='f' AND confrelid='public.mission_control_action_requests'::regclass)
    AND EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='public' AND tablename='mission_control_decisions' AND policyname='mission_control_decisions_select_own' AND cmd='SELECT' AND 'authenticated'=ANY(roles))
    AND (SELECT count(*) FROM pg_tables WHERE schemaname='public') = 93
    AND (SELECT jsonb_agg(privilege_type ORDER BY privilege_type) FROM information_schema.role_table_grants WHERE table_schema='public' AND table_name='mission_control_action_requests' AND grantee='authenticated') = '["SELECT"]'::jsonb
  ) THEN
    RAISE EXCEPTION 'V128-B7-PA VERIFY FAILED — rolling back';
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';  -- D289
```

**Rollback strategy (if ever needed post-APPLY):** `DROP TABLE public.mission_control_decisions;` (0 data-repair — dormant, no rows, no dependents) + `NOTIFY pgrst, 'reload schema';`.

---

## STATUS — STOP

**REHEARSAL PASS · ROLLBACK PROVEN · NOTHING APPLIED.**
Requesting authorization to **APPLY** the migration above (table + read boundary only, dormant). Per gate discipline I will **not** apply automatically.

**Awaiting explicit APPLY authorization.** On "y"/"apply", I run the three-block migration once, re-verify live (expect tables 93 · policies 168 · new tail), and report — still no helpers, no execute wiring, no canonical append.

*Endpoint: RULES **D363** · SYSTEM_MAP **v1.51** · backend tail `20260815101138` · FE pin `2.8.5`.*
