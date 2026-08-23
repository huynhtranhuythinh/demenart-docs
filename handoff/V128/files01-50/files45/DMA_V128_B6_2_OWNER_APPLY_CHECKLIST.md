# DMA_V128_B6_2 — OWNER APPLY CHECKLIST

> **Status:** preparation only — **NO APPLY yet.** Owner opens the Apply Gate; Builder executes only after every STOP-gate below passes.
> **Reframe:** M3 = Governed execution finalization correction + governance evidence foundation.

---

## A. BEFORE APPLY (STOP-gates — any fail ⇒ STOP)

- [ ] **Canonical HEAD verified** — HANDOFF/RULES/SYSTEM_MAP reflect B6.1.5 endpoint (D358/v1.46). No uncommitted governance drift.
- [ ] **Live tail verified** = `20260813113400`; inventory 92 tables / 248 fn / 236 secdef / 169 policies / 33 triggers / 1 cron.
- [ ] **Backup verified** — fresh logical dump from live DB (D90; dumped, not reconstructed). Restore path confirmed.
- [ ] **PGRST schema check (external, manual — not DB-readable)** — confirm `mc_internal` is **NOT** in `pgrst.db_schemas` (Supabase API settings → Exposed schemas = `public, graphql_public` only). ⛔ If `mc_internal` is exposed → STOP (commit-core would become a public RPC).
- [ ] **authenticated UPDATE ledger = false** — re-confirm `has_table_privilege('authenticated','public.mission_control_action_requests','UPDATE') = false`. ⛔ If true → premise changed → STOP.
- [ ] **execute is INVOKER** (`prosecdef=false`) and **adapter md5** = `03a1510bd827c03a650a3a88312fbe3a`. ⛔ Drift → STOP.
- [ ] **REAL LOGIN BASELINE captured** — perform the pre-M3 real-login run (see §C “Before”) and record the expected FAILURE as evidence. This is the “before” half of the acceptance proof.

---

## B. APPLY ORDER (exact)

```
M1  (governance schema foundation)
 └─ VERIFY (in-migration BLOCK-3 PASS)
M2  (governance evaluator)
 └─ VERIFY
M3  (finalization correction)  ← ISOLATED apply session
 └─ VERIFY (structural)
 └─ REAL LOGIN TEST  ← hard gate (§C)  ← acceptance decided here
```
- M1 & M2 are additive/dormant → low risk; may be applied together-then-verified or one-by-one.
- **M3 runs in its own session**, nothing else batched, so rollback boundary is clean.
- **M4 (shadow) and M5 (enforcing) are NOT in this package** — separate Owner Gate after M3 real-login PASS + shadow divergence window.

---

## C. M3 REAL LOGIN EVIDENCE (the acceptance gate)

Account: `hieutruong.kidshouse@demo.demenart.com` / `Test@123` (master_admin, Kids House). Fresh `request_id`.

**Before M3 (baseline):**
- Expected: **FAIL** — finalize UPDATE permission-denied under authenticated → txn rollback → `ok:false`/500, **no** `class_distributions` row, ledger row not completed.

**After M3:**
- Expected: **SUCCESS** — `ok:true`; **class_distribution created**; **audit `CLASS_ASSIGNMENT_CREATED`**; **ledger status=completed** (completed_at + result set).

**M3 is accepted only when this flips Before→After (FAIL→SUCCESS)** and the full A–G matrix (Real Login Test Sheet) passes.

---

## D. CHANGED ASSUMPTIONS (record)

1. Forge via `finish_own` was **not exploitable** (authenticated lacks base UPDATE). `finish_own` = dead policy; drop = hygiene.
2. `execute` finalize was **broken under real authenticated** (INVOKER + no UPDATE). Prior “runtime-verified” was postgres-context only.
3. Acceptance is **not** “byte-identical”: postgres-context compatibility + **real-authenticated PASS (fix)**.
4. `min_role_set` = `text[]` (enum `profile_role` confirmed to contain master_admin + sub_admin; text[] chosen for robustness).
5. `policies.action_key` is a **soft reference** (registry UNIQUE is on `(object_type, action_key)`, not action_key alone → no FK).

---

## E. REMAINING RISKS

- **M3 (HIGH):** replaces a frozen function + drops a policy on a live table. Mitigation: precondition block + structural verify + isolated session + real-login gate + captured rollback body.
- **PGRST exposure (external):** not DB-verifiable → relies on manual settings check. Mitigation: STOP-gate in §A.
- **commit-core granted `authenticated`:** required for INVOKER delegation; forge-proof by construction (actor internal, result server-derived, ownership guard). Reachability limited by mc_internal not being PGRST-exposed.
- **Shadow parameters undefined:** N/T divergence window for M5 not set (out of this package).

---

## F. OWNER GATE BLOCKERS (must clear before Apply)

- [ ] Owner issues explicit **APPLY authorization** for M1→M2→M3 (this package).
- [ ] External PGRST exposed-schemas check done (mc_internal absent).
- [ ] Real-login baseline “Before” evidence captured.
- [ ] Rollback body for `execute` (pre-M3, md5 `41c86f12091355049779fc97f69db2d9`) staged from M0 capture.
- [ ] Confirm M4/M5 remain deferred to a later Gate.

**Until all cleared: NO apply. NO mutation. NO canonical update. NO version bump.**
