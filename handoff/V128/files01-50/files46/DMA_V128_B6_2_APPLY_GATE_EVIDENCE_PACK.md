# DMA_V128_B6_2 — APPLY GATE EVIDENCE PACK

> **Milestone:** V128-B6.2 · Governed execution finalization correction + governance evidence foundation
> **Status:** ⏳ Apply Gate **NOT open** — this is the final evidence artifact for Owner to tick before authorizing.
> **Boundary:** preparation only — **NO apply · NO SQL execution · NO `apply_migration` · NO mutation · NO canonical/RULES/SYSTEM_MAP update · NO version bump.**
> **Prepared:** 2026-08-14 (GMT+7) · Builder: Claude

---

## 1. PURPOSE

This document collects the evidence Owner needs to authorize the M1→M2→M3 apply, in one place, so the decision is made against verified facts rather than assumptions.

**In scope:** evidence collection · pre-apply verification · Owner authorization preparation.
**Out of scope:** migration execution · acceptance sign-off (that happens *after* apply, via the Real Login Test Sheet) · M4/M5.

**Frozen architecture (unchanged):** execute = SECURITY INVOKER · adapter untouched · commit-core = SECURITY DEFINER · `mc_internal` not PostgREST-exposed · M4 (shadow) / M5 (enforcing) deferred to a later Gate.

---

## 2. PRE-APPLY EVIDENCE CHECKLIST

### 2.1 Canonical
Verify current canonical HEAD before touching live:

- [ ] `DMA_RULES.md` endpoint = **D358**
- [ ] `DMA_SYSTEM_MAP.md` = **v1.46**
- [ ] `DMA_HANDOFF` V128-**B6.1.5** = CLOSED

```
HEAD:          ______________________
Date:          ______________________
Verified by:   ______________________
```

### 2.2 Live Runtime Baseline
Expected (from M0 capture, live 2026-08-14):

```
Migration tail:  20260813113400
Inventory:       92 tables
                 248 functions
                 236 SECURITY DEFINER
                 169 policies
                 33 triggers
                 1 cron
```

Record at apply time:
```
Actual tail:        ______________________
Actual inventory:   ______________________
Result (match?):    ______________________
Evidence:           ______________________
```
⛔ Any mismatch → STOP, reconcile drift before proceeding.

---

## 3. M3 ROLLBACK ARTIFACT VERIFICATION

Before M3 apply, the exact pre-M3 `execute` body must be staged for restore.

### Existing execute fingerprint (captured M0)
```
public.execute_mission_control_action(text,uuid,jsonb,jsonb,uuid)
MD5:        41c86f12091355049779fc97f69db2d9
body_len:   7076
security:   INVOKER (prosecdef=false)
search_path: ''
ACL:        postgres=EXECUTE, authenticated=EXECUTE  (no service_role)
```

Verify the rollback body (pre-M3) preserves, versus the M3 replacement — the ONLY allowed delta is finalization delegation:

- [ ] signature unchanged (`p_action_key, p_object_id, p_context, p_input, p_request_id`)
- [ ] SECURITY INVOKER unchanged
- [ ] auth gate unchanged (`auth.uid()` null → PERMISSION_DENIED; `current_profile()` null → PERMISSION_DENIED)
- [ ] context validation unchanged (`{school_id}`-only shape + cross-tenant match)
- [ ] input validation + idempotency (INSERT on-conflict + replay) unchanged
- [ ] adapter call unchanged (`assign_class_distribution`)
- [ ] **Only delta:** inline finalize block → `mc_internal._mc_commit_action(...)` delegation

```
Rollback execute body staged (md5 41c86f12…):  [ ] yes
Staged by:  ______________________
```

Adapter fingerprint to hold constant:
```
public.assign_class_distribution(uuid,uuid,uuid)  MD5: 03a1510bd827c03a650a3a88312fbe3a
```
(M3 precondition + verify assert this md5 both before and after — adapter must be byte-identical.)

---

## 4. REAL LOGIN BASELINE EVIDENCE (critical)

Capture the **pre-M3** real-login run to prove the defect exists. This is the "Before" half of M3 acceptance.

```
Account:  hieutruong.kidshouse@demo.demenart.com  /  Test@123   (master_admin, Kids House)
Test:     class.assign on an own Kids House class, valid program_id, context.school_id = Kids House
```

**Expected pre-M3:** FAIL — finalize UPDATE permission-denied under real authenticated → transaction rollback → no distribution, ledger not completed.

| Item | Value |
|---|---|
| request_id | ______________________ |
| timestamp | ______________________ |
| response (ok / error code / HTTP) | ______________________ |
| ledger state (status / completed_at) | ______________________ |
| class_distributions delta | ______________________ (expected: 0) |
| audit `CLASS_ASSIGNMENT_CREATED` delta | ______________________ (expected: 0) |

> This "Before = FAIL" is what M3 must flip to "After = SUCCESS" (see Real Login Test Sheet).

---

## 5. PGRST EXPOSURE CHECK (manual — SQL cannot assert this)

`pgrst.db_schemas` is platform-managed (not a DB role setting) → verified by hand in Supabase.

**Supabase → Project Settings → API → Exposed schemas:**

Allowed:
```
public
graphql_public
```
Forbidden:
```
mc_internal
```

- [ ] Confirmed `mc_internal` is **NOT** exposed. ⛔ If present → **STOP** (commit-core would become a public RPC).

```
Checked by:  ______________________   Date:  ______________________
```

---

## 6. MIGRATION ARTIFACT INTEGRITY (SHA-256)

| Artifact | SHA-256 | Reviewed |
|---|---|---|
| M1 SQL | `02a0fa9df9ef6feae745e120bfdda2668d89c799f9faab18c89aa218beab2e88` | [ ] |
| M2 SQL | `7efc40bce62670d551da7b858933556c3d5082b99ed0b5ff5c83404fd5f06d7d` | [ ] |
| M3 SQL | `637b09b88cf6d28220a70d73f4aba7f9c3869ae08dae01bd2e7007bb6d373d59` | [ ] |
| Owner Apply Checklist | `646cbf7aad20b4ced5a2cdf7adc6a2e5ed84a652cd07bef52e89fe1d440b67d1` | [ ] |
| Real Login Test Sheet | `aad2f52fa9008d2d65ed46ef9ff4a82bfe0bd4e23199923f92c5d149d3cff912` | [ ] |

Confirm the SQL you apply matches these hashes byte-for-byte (recompute `sha256sum` at apply time).

---

## 7. APPLY ORDER CONFIRMATION (frozen)

```
Capture BEFORE evidence (§4 real-login FAIL)
      ↓
M1  (governance schema foundation)
      ↓  VERIFY (in-migration BLOCK-3)
M2  (governance evaluator)
      ↓  VERIFY
M3  (finalization correction)  ← ISOLATED apply session
      ↓  STRUCTURAL VERIFY (in-migration)
      ↓  REAL LOGIN TEST (A–G)  ← acceptance decided here
Owner acceptance
```
- M3 in its own session (nothing batched) → clean rollback boundary.
- **M4/M5 excluded** from this Gate.

---

## 8. OWNER APPLY AUTHORIZATION

```
OWNER APPLY AUTHORIZATION — V128-B6.2 (M1, M2, M3)

I confirm:
[ ] Backup verified (fresh logical dump from live DB)
[ ] Canonical verified (RULES D358 · SYSTEM_MAP v1.46 · B6.1.5 CLOSED)
[ ] PGRST exposure checked (mc_internal NOT exposed)
[ ] Before evidence captured (real-login pre-M3 = FAIL)
[ ] Rollback artifact ready (execute pre-M3 md5 41c86f12…)
[ ] Artifact SHA-256 match (§6)

I authorize apply of:
    M1  [ ]
    M2  [ ]
    M3  [ ]   (isolated session + immediate real-login regression)

M4 / M5:  remain DEFERRED (separate Gate).

Owner:      ______________________
Date:       ______________________
Signature:  ______________________
```

---

## 9. REMAINING RISKS

**M3 — HIGH.** Replaces a frozen function (`execute`) + introduces `_mc_commit_action` + drops `finish_own` on a live table. Mitigation: precondition block (RAISE→rollback) · structural verify · isolated session · real-login gate · staged rollback body.

**mc_internal exposure.** Not DB-verifiable → depends on the manual §5 check. Misconfiguration would turn commit-core into a public RPC. Mitigation: §5 STOP-gate + Owner tick.

**Real-login divergence.** Behavior differs from postgres-context (postgres-context always "worked"; real authenticated was broken). The fix is only observable via real login — hence the hard gate. Structural/postgres-context PASS alone is insufficient.

**M4/M5 deferred.** No shadow evaluation, no enforcement yet. After M1–M3, governance tables + evaluator exist but are **not wired** into the execution path (wiring is M4). Enforcement (deny blocking) does not exist until M5. This Gate ships the finalization correction + dormant foundation only.

---

**Reminder:** NO apply · NO database mutation · NO canonical update · NO version bump. Builder proceeds to `apply_migration` only after this pack is fully ticked and Owner signs §8.
