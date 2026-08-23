# DMA_V128_B6_2 — ROLLBACK PLAN

> **Principle:** every rollback non-destructive · business data preserved · reversible · no `class_distributions` / `audit_logs` / existing ledger rows touched.
> **Captured baseline for restore:** M0 fingerprints — `execute` md5 `41c86f12091355049779fc97f69db2d9` (INVOKER); `finish_own` predicate (below). 0 apply until Owner Gate.

---

## M1 — Governance Schema Foundation
**Rollback:**
```sql
DROP TABLE IF EXISTS public.mission_control_action_authorizations;
DROP TABLE IF EXISTS public.mission_control_action_policies;
DELETE FROM public.policy_registry WHERE code = 'mission_control_action_governance';
-- drop schema only if empty (commit-core/evaluator not yet present)
DROP SCHEMA IF EXISTS mc_internal;
```
**Preserved:** all (no business data written). **Risk:** LOW.

---

## M2 — Governance Evaluator
**Rollback:**
```sql
DROP FUNCTION IF EXISTS mc_internal.evaluate_action_policy(uuid,text,text,uuid,jsonb,jsonb);
```
**Preserved:** all (dormant, no caller pre-M4). **Risk:** LOW.

---

## M3 — Governed Execution Finalization Correction (CRITICAL)
Restores the pre-M3 state exactly: execute self-finalizing (INVOKER) + `finish_own` policy + prior ACL + drop commit-core.

**Rollback:**
```sql
-- 1. restore execute to the M0-captured pre-B6.2 body (INVOKER, self-finalizing)
--    FULL paste-over of the exact prior definition (md5 41c86f12091355049779fc97f69db2d9).
CREATE OR REPLACE FUNCTION public.execute_mission_control_action(
  p_action_key text, p_object_id uuid, p_context jsonb, p_input jsonb, p_request_id uuid
) RETURNS jsonb LANGUAGE plpgsql SET search_path = '' AS $fn$
  -- << exact pre-M3 body from M0 capture: gates + INSERT + replay + inline
  --    adapter-call + inline UPDATE completed/failed + return >>
$fn$;

-- 2. restore the (dead) finish_own policy to its exact prior predicate
CREATE POLICY mission_control_action_requests_finish_own
  ON public.mission_control_action_requests
  FOR UPDATE TO authenticated
  USING (actor_id = (SELECT current_profile()) AND status = 'processing')
  WITH CHECK (
    actor_id = (SELECT current_profile())
    AND status = ANY (ARRAY['completed','failed'])
    AND completed_at IS NOT NULL AND result_payload IS NOT NULL
    AND ((status='completed' AND error_code IS NULL) OR (status='failed' AND error_code IS NOT NULL))
  );

-- 3. drop commit-core
DROP FUNCTION IF EXISTS mc_internal._mc_commit_action(uuid,text,text,uuid,jsonb,jsonb);

-- 4. re-assert execute prior ACL (postgres + authenticated; no service_role)
REVOKE ALL ON FUNCTION public.execute_mission_control_action(text,uuid,jsonb,jsonb,uuid) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.execute_mission_control_action(text,uuid,jsonb,jsonb,uuid) TO authenticated;
```
**Important caveat:** restoring M3 **re-introduces the known defect** (finalize broken under real authenticated). Rollback returns to pre-B6.2 *state*, not to a working real-authenticated path — that path was never working. Document this if M3 is rolled back: the system returns to postgres-context-only completion.

**Preserved:** business + ledger rows intact. `finish_own` restored is still a dead policy (authenticated still lacks UPDATE). **Risk:** HIGH (touches frozen fn + live path) — requires captured prior body + real-login re-verify after rollback.

---

## M4 — Shadow Governance
**Rollback (either):**
```sql
-- (a) REPLACE commit-core back to the M3 body (remove governance seam), OR
-- (b) kill-switch, data-only:
UPDATE public.mission_control_action_policies SET lifecycle = 'disabled', updated_at = now()
 WHERE action_key = 'class.assign';
```
**Preserved:** evidence rows kept (audit sink, harmless). **Risk:** LOW–MEDIUM.

---

## M5 — Enforcement Flip
**Rollback (data-only, instant):**
```sql
UPDATE public.mission_control_action_policies SET lifecycle = 'shadow', updated_at = now()
 WHERE action_key = 'class.assign';
```
**Preserved:** all. **Risk:** LOW.

---

## FULL TEARDOWN (pre-B6.2)
Order: **M3-restore → drop M2 → drop M1**. After teardown: inventory back to 92/248/236/**169** policies (finish_own restored), `mc_internal` gone, governance tables gone. `class_distributions` / `audit_logs` / ledger business rows untouched throughout.

## GLOBAL RULES
- Never `DROP`/`TRUNCATE`/`DELETE` business data.
- Each rollback is its own transaction; later-phase rollback never breaks an earlier phase.
- After any M3 rollback: **real-login re-verify** (D2/D3) to confirm state, since postgres-context testing hides the finalize behavior.
