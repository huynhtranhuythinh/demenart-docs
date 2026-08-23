# DMA V114B-E3 · WP2 · S0A — APPLY REPORT & REAL-LOGIN QA RUNBOOK

**Verdict so far:** ✅ **S0A DATABASE ACL APPLY — PASS**
**Not yet claimable:** WP2 S0A FORMALLY PASS / CLOSED — blocked on real-login QA (§3)

---

## 1. MIGRATION IDENTITY

| Field | Value |
|---|---|
| Migration inventory | **106 → 107** |
| Version | `20260721122221` |
| Name | `v114b_e3_wp2_s0a_legacy_assignment_lockdown` |
| `md5(statements)` | `bb79229baad28348c30bcc171905be54` |
| Revision applied | rev3 — Option C+ (7 privileges) |
| Blocks | BLOCK 1 precondition PASS · BLOCK 2 revoke · BLOCK 3 verify PASS |
| RAISE fired | none |

---

## 2. POST-APPLY STRUCTURAL VERIFICATION

### 2.1 Final ACL — matches prediction exactly

```
{postgres=arwdDxtm/postgres, anon=r/postgres, authenticated=r/postgres, service_role=r/postgres}
```

Exploded:

| Grantee | Privileges |
|---|---|
| `authenticated` | **SELECT** |
| `anon` | **SELECT** |
| `service_role` | **SELECT** |
| `postgres` | DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE (`arwdDxtm`) |

**21 direct ACL entries removed** — 7 privileges × 3 client roles. Predicted `r` achieved for all three; no residual `m`.

### 2.2 Required checklist

| Item | Expected | Actual | |
|---|---|---|---|
| Migration inventory | 107 | **107** | ✅ |
| `authenticated` | SELECT only | SELECT only | ✅ |
| `anon` | SELECT only | SELECT only | ✅ |
| `service_role` | SELECT only | SELECT only | ✅ |
| `postgres` | `arwdDxtm` | `arwdDxtm` | ✅ |
| `session_teachers` row count | 2 | **2** | ✅ |
| Policy count | 4 | **4** | ✅ |
| Constraint count | 5 | **5** | ✅ |
| Index count | 2 | **2** | ✅ |
| Explicit column ACL | none | **0** | ✅ |
| Residual column privileges (5 cols × 3 roles × I/U/REF = 45) | 0 | **0** | ✅ |
| SECURITY DEFINER assignment RPCs, owner postgres | 5 | **5** | ✅ |
| Table columns | 5 | **5** | ✅ |

### 2.3 In-migration BLOCK 3 evidence

| Tier | Result |
|---|---|
| PRIMARY — `aclexplode`, 3 client roles × 7 privileges | 0 residual entries |
| PRIMARY — `aclexplode`, PUBLIC × 7 privileges | 0 entries |
| PRIMARY — column-level scan, 45 combinations | 0 residual |
| Corroborating — `has_table_privilege` 7 × 3 | all false |
| Supplementary — TRUNCATE probe (RLS-immune) | 3/3 → SQLSTATE 42501 |
| Supplementary — INSERT probe, `service_role` only (BYPASSRLS) | 42501 |
| Not run by design | INSERT probe on `authenticated`/`anon` (RLS makes 42501 ambiguous); MAINTAIN functional probe (side-effectful) |

MAINTAIN removal rests on **structural ACL evidence alone**. No functional claim is made for it.

### 2.4 No-delta regression (system-wide)

| Invariant | Baseline | Now | |
|---|---|---|---|
| Tables | 87 | **87** | ✅ |
| SECURITY DEFINER functions | 196 | **196** | ✅ |
| Policies (all schemas) | 165 | **165** | ✅ |
| Cron jobs | 1 | **1** | ✅ |
| `lesson_sessions` | 8 | **8** | ✅ |
| `session_teacher_assignments` | does not exist | **does not exist** | ✅ (S1 not opened) |

### 2.5 WP1 forensic invariants — no regression

| Invariant | Expected | Now | |
|---|---|---|---|
| `learning_moments` | 22 | **22** | ✅ |
| `approved` + `approved_by` NULL | 6 | **6** | ✅ |
| `child_observations` | 9 | **9** | ✅ |
| `learning_moments` table INSERT for `authenticated` | false | **false** | ✅ |
| **ANOMALY-1** `f51039be-…` | `approved` / NULL / `2026-07-09 07:31:01.160368+00` | **identical** | ✅ |

Zero data delta. Zero policy delta. Zero function delta. Zero schema delta.

---

## 3. REAL-LOGIN QA — REQUIRED, NOT YET RUN

S0A cannot be declared closed on structural evidence alone. In particular, **Test 4 is the only proof that `authenticated` genuinely cannot write via PostgREST** — the in-migration probe could not establish that, because RLS and a missing grant both raise 42501.

Production: **demenart.com**

### Test 1 — Master creates a QA session with a teacher
Login `hieutruong.kidshouse@demo.demenart.com` / `Test@123`
→ `/school/schedule` → create a session on a Kids House class, **name it `QA S0A — DO NOT USE`**, assign at least one teacher.
**Expected:** saves successfully (`create_lesson_session`, definer path).

### Test 2 — Master edits the assignment
Open that session's detail panel, add/remove a teacher, save.
**Expected:** saves successfully (`set_session_teachers`, definer path).

### Test 3 — Teacher list still readable
Reopen the detail panel.
**Expected:** teacher list renders (SELECT retained).

### Test 4 ⭐ — Direct PostgREST write must be rejected
While still logged in on demenart.com:
1. DevTools → **Network** tab → find any request to `…/rest/v1/…`
2. Right-click → **Copy → Copy as fetch**
3. Paste into **Console**, then edit before running:
   - URL → `https://xcvhacymrbhdhohyylyq.supabase.co/rest/v1/session_teachers`
   - `method` → `"POST"`
   - add `body: JSON.stringify({ session_id: "00000000-0000-0000-0000-000000000000", profile_id: "00000000-0000-0000-0000-000000000000", role: "assist" })`
   - keep the existing `apikey` and `Authorization` headers exactly as copied
4. Run it.

**Expected: HTTP 401/403 with `permission denied for table session_teachers`.**
❌ If it returns 200/201, or a foreign-key error (`23503`), **stop and report** — an FK error would mean the write got past the privilege check.

Repeat with `method: "PATCH"` and `method: "DELETE"` (append `?id=eq.00000000-0000-0000-0000-000000000000`). Both must be denied.

### Test 5 — Teacher workspace
Login `gv.linh.kidshouse@demo.demenart.com` / `Test@123` → `/teacher` and `/teacher/classes`.
**Expected:** loads normally, classes and sessions listed.

### Test 6 — Upload session media
Same teacher account → open a session → Step 2 → add a supplementary resource.
**Expected:** upload succeeds (`upload_media` branch C via definer RPC).

### Test 7 — Delete session media
Delete the resource just uploaded.
**Expected:** succeeds (`delete_session_media` via definer RPC).

### Test 8 — Restore baseline
Back on the master account, remove **all** teachers from the QA session so legacy `session_teachers` returns to **2** rows.

### Test 9 — Cancel the QA session
Cancel `QA S0A — DO NOT USE`. Report residue transparently: the session row will remain in `lesson_sessions` with `state='cancelled'`, taking the count from 8 → 9. That is expected and must be **declared, not hidden**.

---

## 4. ROLLBACK (if real-login QA fails)

```sql
GRANT INSERT,
      UPDATE,
      DELETE,
      TRUNCATE,
      TRIGGER,
      REFERENCES,
      MAINTAIN
   ON public.session_teachers
   TO authenticated, anon, service_role;
```

No `GRANT ALL`. SELECT is neither granted nor revoked. Post-rollback the ACL must return to `arwdDxtm` for all three client roles.

---

## 5. VERDICT

| Gate | Status |
|---|---|
| **S0A DATABASE ACL APPLY** | ✅ **PASS** |
| Real-login QA (§3) | ⏳ **PENDING** |
| **WP2 S0A FORMALLY PASS / CLOSED** | ⏳ blocked on the above |

S0A closes the **client grant surface** of WP2-P0-1…P0-4 on the legacy assignment table.

**Explicitly NOT claimed:**
- WP2 is not closed
- canonical assignment model not created (`session_teacher_assignments` still does not exist)
- E3-SG-01 not closed
- RLS policies not yet removed (S4)
- SELECT surface not yet closed (S4)

---

## 6. STOP LINE

S0B not opened · migration 108 not written · `session_teacher_assignments` not created · no frontend change · no deploy · RULES/SYSTEM_MAP not canonicalized.

Next action requires Owner: run §3, report results.
