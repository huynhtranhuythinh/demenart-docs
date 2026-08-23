# DMA V114B-E3 · WP2 · S0A — MIGRATION REVIEW PACK

**Revision:** rev2 — Option C (full non-SELECT client lockdown)
**Artifact:** `107_v114b_e3_wp2_s0a_legacy_assignment_lockdown.sql`
**Status:** **AUTHORED — NOT APPLIED**
**Migration inventory:** **106** (unchanged; last version `20260721104516`)
**Awaiting:** CTO statement-by-statement review + apply authorization

---

## 1. ⚠️ S0A-FINDING-02 — NEW, DECISION REQUIRED

Direct ACL inspection (not `information_schema`) returned:

```
{postgres=arwdDxtm/postgres, anon=arwdDxtm/postgres,
 authenticated=arwdDxtm/postgres, service_role=arwdDxtm/postgres}
```

Decoding `arwdDxtm`:

| Char | Privilege |
|---|---|
| `a` | INSERT |
| `r` | SELECT |
| `w` | UPDATE |
| `d` | DELETE |
| `D` | TRUNCATE |
| `x` | REFERENCES |
| `t` | TRIGGER |
| **`m`** | **MAINTAIN** |

**There are eight privileges, not seven.** This server is **PostgreSQL 17.0.6**, which introduced `MAINTAIN`. My earlier report enumerated seven because `information_schema.role_table_grants` **does not expose MAINTAIN** — the exact class of blind spot D310-cand warns about, reproduced one layer up.

So "full non-SELECT client lockdown" as specified (six privileges) leaves **MAINTAIN** in place for `authenticated`, `anon`, and `service_role`.

**Risk assessment — deliberately not inflated.** MAINTAIN permits `VACUUM`, `ANALYZE`, `CLUSTER`, `REINDEX`, `REFRESH MATERIALIZED VIEW`. It does **not** permit reading or modifying logical row data, and it is not an integrity-bypass primitive. It is a resource/DoS surface (an `anon` caller could force repeated `REINDEX`), not an assignment-integrity surface. Materially less severe than the TRUNCATE finding.

I have **not** included it — it falls outside the approved statement, and the instruction was explicit about using the exact statement.

| | Action | Effect |
|---|---|---|
| **C** (approved) | Six privileges | MAINTAIN remains for all three client roles |
| **C+** | Add `MAINTAIN` → seven | Genuinely complete non-SELECT lockdown |

If **C+** is approved, the change is one token in BLOCK 2 and one array element in each of BLOCK 3 §3.4 and §3.7, plus the predicted ACL becomes `=r/postgres`.

> **Method note:** this finding exists only because §4 of your instruction forced `aclexplode` instead of `information_schema`. That requirement did real work.

---

## 2. EXACT STATEMENT DIFF (rev1 → rev2)

Full unified diff shipped as `S0A_rev1_to_rev2.diff` (558 lines). Semantic summary:

### 2.1 BLOCK 2 — the change itself

```diff
- REVOKE INSERT, UPDATE, DELETE
+ REVOKE INSERT, UPDATE, DELETE, TRUNCATE, TRIGGER, REFERENCES
      ON public.session_teachers
    FROM authenticated, anon, service_role;
```

### 2.2 BLOCK 1 — preconditions added

| # | rev1 | rev2 |
|---|---|---|
| 1.2 | row count only | row count **+ constraint count (5) + index count (2)** |
| 1.4 | `authenticated` INSERT present | **all 6 privileges × 3 roles** present (18 assertions) |
| 1.5 | *absent* | **NEW** — `pg_attribute.attacl` must be NULL on every user column, else a table REVOKE is insufficient → RAISE |

### 2.3 BLOCK 3 — verification rebuilt

| # | rev1 | rev2 |
|---|---|---|
| 3.1 | *absent* | **NEW** — `aclexplode` direct inspection, 3 roles × 6 privileges → **PRIMARY EVIDENCE** |
| 3.2 | *absent* | **NEW** — `aclexplode` PUBLIC pseudo-role check |
| 3.3 | *absent* | **NEW** — capture resulting `relacl` into the migration notice |
| 3.4 | 3 privileges × 3 roles = 9 | **6 × 3 = 18** |
| 3.5 | *absent* | **NEW** — column-level scan over `pg_attribute`: 5 columns × 3 roles × (INSERT, UPDATE, REFERENCES) = **45 assertions** |
| 3.7 | postgres I/U/D | postgres **all 6** |
| 3.8 | rows, policies | rows, policies, **SELECT policy by name, constraints (5), indexes (2)** |
| 3.10 | INSERT probe × 3 roles, claimed as proof | **rewritten — see §5** |
| 3.11 | *absent* | **NEW** — post-probe row-count re-check |

### 2.4 Header

Scope, notice text, expected ACL transition and rollback all rewritten for six privileges. The rev1 claim *"3/3 INSERT probes prove grant removal"* is **removed from the SQL notices entirely** and does not appear in this pack.

---

## 3. EXACT ACL BEFORE → AFTER

### 3.1 Table ACL (`pg_class.relacl`)

| | Value |
|---|---|
| **BEFORE** | `{postgres=arwdDxtm/postgres, anon=arwdDxtm/postgres, authenticated=arwdDxtm/postgres, service_role=arwdDxtm/postgres}` |
| **AFTER (predicted)** | `{postgres=arwdDxtm/postgres, anon=rm/postgres, authenticated=rm/postgres, service_role=rm/postgres}` |

### 3.2 Per-role privilege diff

| Privilege | authenticated | anon | service_role | postgres |
|---|---|---|---|---|
| SELECT `r` | keep ✅ | keep ✅ | keep ✅ | keep |
| INSERT `a` | **REVOKE** | **REVOKE** | **REVOKE** | keep |
| UPDATE `w` | **REVOKE** | **REVOKE** | **REVOKE** | keep |
| DELETE `d` | **REVOKE** | **REVOKE** | **REVOKE** | keep |
| TRUNCATE `D` | **REVOKE** | **REVOKE** | **REVOKE** | keep |
| REFERENCES `x` | **REVOKE** | **REVOKE** | **REVOKE** | keep |
| TRIGGER `t` | **REVOKE** | **REVOKE** | **REVOKE** | keep |
| MAINTAIN `m` | *retained* ⚠️ | *retained* ⚠️ | *retained* ⚠️ | keep |

18 ACL entries removed. `postgres` (table owner, `rolsuper = false`) untouched.

### 3.3 Column ACL (`pg_attribute.attacl`)

| Column | BEFORE | AFTER (predicted) |
|---|---|---|
| `id` · `session_id` · `profile_id` · `role` · `created_at` | **NULL** (all five) | **NULL** (unchanged) |

**This is what the column-level requirement exposes.** `information_schema.column_privileges` currently reports 60 rows for these three roles (5 columns × 3 roles × 4 privileges), which *looks* like explicit column grants but is not. `attacl IS NULL` everywhere; the view merely projects the table-level grant onto every column. Exactly D310-cand.

Consequence: the table-level REVOKE **is** sufficient here, and `has_column_privilege` must flip to `false` on its own. BLOCK 3 §3.5 asserts that across all 45 combinations rather than assuming it. BLOCK 1 §1.5 independently refuses to run if a real `attacl` ever appears.

---

## 4. UPDATED ROLLBACK SQL

Restores exactly the six revoked privileges. **No `GRANT ALL`** — that would also grant SELECT and MAINTAIN in a way that misrepresents the pre-state and silently widens the surface.

```sql
-- ROLLBACK for migration 107 (S0A) — restores the exact pre-S0A privilege set.
-- Does NOT use GRANT ALL: SELECT and MAINTAIN were never revoked, and re-granting
-- them would misrepresent the restored state.
GRANT INSERT, UPDATE, DELETE, TRUNCATE, TRIGGER, REFERENCES
   ON public.session_teachers
   TO authenticated, anon, service_role;
```

Post-rollback the ACL must return to `arwdDxtm` for all three roles. Verify with:

```sql
select coalesce(relacl::text,'<null>')
  from pg_class where oid = 'public.session_teachers'::regclass;
```

**A failed apply needs no rollback.** BLOCK 3 raises inside the transaction and `apply_migration` unwinds atomically. The statement above is only for reverting a *successful* apply — and doing so restores the P0 hole.

---

## 5. UPDATED PROBE INTERPRETATION

### 5.1 The rev1 error, stated plainly

rev1 ran an INSERT probe as each of the three roles and treated `SQLSTATE 42501` as proof the table grant was gone. **That inference was invalid.** PostgreSQL raises `42501` for an RLS policy denial as well as for a missing privilege; the two are indistinguishable from the SQLSTATE alone.

Confirmed live: `authenticated` and `anon` both have `rolbypassrls = false`. `authenticated` is subject to `session_teachers_insert_lead_or_schooladmin`, whose `WITH CHECK` would fail anyway under `SET LOCAL ROLE` with no JWT claims. `anon` has no permissive INSERT policy at all, so RLS denies it unconditionally.

**Both would have returned 42501 before the revoke.** The rev1 probe would have "passed" against an unmodified database. It was not merely weak evidence — it was capable of producing a false PASS.

### 5.2 Corrected evidence hierarchy

| Tier | Check | Roles | Status |
|---|---|---|---|
| **PRIMARY** | `aclexplode` direct ACL inspection | all 3 | authoritative |
| **PRIMARY** | column-level `has_column_privilege` scan | all 3 | authoritative |
| Corroborating | `has_table_privilege` | all 3 | catalog-derived |
| **Supplementary** | **TRUNCATE probe** | all 3 | valid — TRUNCATE is not subject to RLS for any role, so `42501` is attributable to the privilege check alone |
| **Supplementary** | **INSERT probe** | **service_role only** | valid — `rolbypassrls = true`, so RLS cannot be the cause |
| ~~Invalid~~ | ~~INSERT probe~~ | ~~authenticated, anon~~ | **removed — not run, not claimed** |
| **Mandatory, separate** | real-login direct-write QA | — | §7, post-apply |

### 5.3 Discrimination retained

For the probes still run, any non-`42501` outcome is FAIL — including `23503` (FK violation), which would mean execution got *past* the privilege check and the grant is still effective. Only `42501` counts as PASS.

### 5.4 Residue

None possible. If a probe unexpectedly succeeded, the subsequent `RAISE` unwinds the entire transaction. `TRUNCATE` is transactional in PostgreSQL, so even a successful truncate of the 2 legacy rows is rolled back. §3.11 re-asserts `count = 2` after the probe phase as a belt-and-braces check.

---

## 6. PRESERVATION GUARANTEES ASSERTED IN BLOCK 3

| Item | Expected | Asserted |
|---|---|---|
| Row count | **2** | §3.8 and again §3.11 |
| Policy count | **4** | §3.8 |
| SELECT policy `session_teachers_select_school` | present | §3.8 by name |
| Constraints | **5** (`_pkey`, `_profile_id_fkey`, `_role_chk`, `_session_id_fkey`, `_session_id_profile_id_key`) | §3.8 |
| Indexes | **2** (`session_teachers_pkey`, `session_teachers_session_id_profile_id_key`) | §3.8 |
| Definer assignment RPCs | **5**, secdef, postgres-owned | §3.9 |
| `authenticated` EXECUTE on those 5 | present | §3.9 |
| `anon` EXECUTE on those 5 | absent | §3.9 |
| `authenticated` SELECT on table | present | §3.6 |
| `postgres` all 6 privileges | present | §3.7 |
| Data | untouched — no DML in this migration | by construction |

Migration inventory remains **106** until apply.

---

## 7. POST-APPLY QA — MANDATORY, REAL LOGIN (D2/D3)

The migration proves privilege state. It cannot prove the product still works.

| # | Check | Account | Expected |
|---|---|---|---|
| 1 | Create session with teachers | `hieutruong.kidshouse@demo.demenart.com` / `Test@123` | succeeds (definer path) |
| 2 | Edit session teachers | same | succeeds (definer path) |
| 3 | Schedule detail renders teacher list | same | succeeds (SELECT retained) |
| 4 | **Direct PostgREST write from browser console** | any authenticated | **403 permission denied** |
| 5 | Teacher workspace loads | `gv.linh.kidshouse@demo.demenart.com` / `Test@123` | unchanged |
| 6 | Session media upload | `gv.linh.kidshouse@demo.demenart.com` / `Test@123` | succeeds (`upload_media` branch C via definer RPC) |
| 7 | Session media delete | same | succeeds (`delete_session_media` via definer RPC) |
| 8 | `session_teachers` row count | ops query | still **2** |
| 9 | ACL re-read | ops query | matches §3.1 AFTER |

Checks 1, 2, 6, 7 would expose a wrong assumption about definer privilege. **Check 4 is the purpose of the entire migration**, and is the one piece of evidence the in-migration probes cannot supply for `authenticated`.

---

## 8. STOP LINE

**Not applied. DB not mutated. No code or frontend change. S0B/S1 not opened.**

Two things needed before apply:

1. **Decision on S0A-FINDING-02** (§1) — keep six, or extend to seven with `MAINTAIN`.
2. **Explicit apply authorization.**

If MAINTAIN is added I revise BLOCK 2, the two privilege arrays in BLOCK 3, and the predicted ACL, then re-present for review before any apply.
