# DMA V114B-E3 · WP2 · S0A — MIGRATION REVIEW NOTE

**Artifact:** `107_v114b_e3_wp2_s0a_legacy_assignment_lockdown.sql`
**Status:** **AUTHORED — NOT APPLIED**
**Authorization held:** author + review only
**Migration inventory:** 106 (unchanged) → would become 107 on apply

---

## 1. WHAT THIS MIGRATION DOES

Exactly one change:

```sql
REVOKE INSERT, UPDATE, DELETE
    ON public.session_teachers
  FROM authenticated, anon, service_role;
```

No DDL. No data mutation. No column referenced. No policy dropped. No function replaced.

Wrapped in the D92 three-block pattern:

| Block | Role |
|---|---|
| **1** | Precondition assert — re-proves the audited live state inside the same transaction |
| **2** | The REVOKE |
| **3** | Verify + live negative probes, `RAISE` on any deviation → atomic rollback |

---

## 2. ⚠️ S0A-FINDING-01 — DECISION REQUIRED BEFORE APPLY

Live ACL audit of `public.session_teachers` returned **seven** privileges per client role, not three:

| Role | Granted |
|---|---|
| `anon` | SELECT · INSERT · UPDATE · DELETE · **TRUNCATE** · **REFERENCES** · **TRIGGER** |
| `authenticated` | SELECT · INSERT · UPDATE · DELETE · **TRUNCATE** · **REFERENCES** · **TRIGGER** |
| `service_role` | SELECT · INSERT · UPDATE · DELETE · **TRUNCATE** · **REFERENCES** · **TRIGGER** |

The approved revoke set covers INSERT/UPDATE/DELETE. That leaves **TRUNCATE** in place.

**Why this matters more than it looks:** `TRUNCATE` is a write path that **RLS does not filter**. Every protection currently relied upon for `session_teachers` — all four policies — is row-level, and TRUNCATE is not a row operation. A role holding TRUNCATE can empty the table wholesale without any policy evaluating. After S0A as scoped, TRUNCATE would be the *only remaining* client-reachable write path on the table, and it is strictly more destructive than the three being removed.

`TRIGGER` is a second-order concern: it permits attaching triggers to the table, which is an invariant-bypass primitive. It requires additional privileges to be exploitable, so it is lower urgency — but it is exactly the class of escape hatch rev2 §7.6 forbids for the canonical table, and the same reasoning applies to the legacy one.

**This is not scope creep.** It is the same operation (grant revocation), on the same table, in the same migration class, closing the same hole. But it is not what was authorized, so I have **not** included it.

### Options

| | Action | Effect |
|---|---|---|
| **A** | Apply as authored (I/U/D only) | TRUNCATE remains reachable by `anon`. Hole partially open. |
| **B** ★ | Extend BLOCK 2 to `REVOKE INSERT, UPDATE, DELETE, TRUNCATE` | Closes the RLS-blind write path. One-word change. |
| **C** | Extend to `... , TRUNCATE, TRIGGER, REFERENCES` | Full client-write lockdown; SELECT still retained. |

I recommend **B** at minimum. **C** is defensible and costs nothing functionally — nothing in the sweep uses TRIGGER or REFERENCES on this table — but B is the change that removes an actual destructive capability.

If **B** or **C** is approved, the edit is confined to BLOCK 2 and the BLOCK 3 privilege loop; both are parameterised by a privilege array and take a one-line change each. Say the word and I will revise before apply.

---

## 3. WHY REVOKING FROM `service_role` IS SAFE

Verified live, not assumed:

| Check | Result |
|---|---|
| Edge Functions reading/writing `session_teachers` directly | **0 / 16** (sweep CLOSED) |
| Assignment capability consumers | 2 — `upload_media` (branch C), `delete_session_media` — both via SECURITY DEFINER RPC `check_session_media_upload_access` |
| Frontend direct writes | 0 |

All five assignment RPCs are SECURITY DEFINER owned by `postgres`, so they execute with the definer's privileges and are unaffected:

| RPC | secdef | owner | `authenticated` EXECUTE | `anon` EXECUTE |
|---|---|---|---|---|
| `create_lesson_session(p_class_distribution_id, …)` | ✅ | postgres | ✅ | ✗ |
| `set_session_teachers(p_session_id, p_teacher_ids)` | ✅ | postgres | ✅ | ✗ |
| `set_distribution_lead(p_class_distribution_id, p_lead_teacher_id)` | ✅ | postgres | ✅ | ✗ |
| `assign_class_distribution(p_class_id, p_program_id, p_lead_teacher_id)` | ✅ | postgres | ✅ | ✗ |
| `start_session(p_session_id)` | ✅ | postgres | ✅ | ✗ |

Column names in these signatures are the **live** ones (`p_class_distribution_id`). No rev1 stale identifiers appear anywhere in the migration.

**Operator escape hatch preserved:** MCP `execute_sql` runs as `current_user = postgres` (table owner, `rolbypassrls = true`). BLOCK 3 asserts postgres retains I/U/D explicitly — if the revoke ever leaked onto the owner, the migration rolls back rather than locking everyone out.

---

## 4. WHAT IS DELIBERATELY *NOT* DONE

| Item | Why | Scheduled |
|---|---|---|
| `SELECT` retained for `authenticated` | Readers are not cut over until S3. Removing SELECT now breaks the schedule UI's direct read. | S4 |
| 4 RLS policies kept | Grants and policies are independent layers. Removing both simultaneously destroys the ability to attribute a future failure to the right layer. | S4 |
| `TRUNCATE` / `TRIGGER` / `REFERENCES` | Outside authorized scope — see §2. | pending decision |
| Any DDL, trigger, or function change | S0A is grant revocation only. | S0B onward |

---

## 5. VERIFICATION DESIGN

BLOCK 3 does not rely solely on catalog views. It runs **live negative probes**:

For each of `authenticated`, `anon`, `service_role`: `SET LOCAL ROLE`, attempt an INSERT, and require **SQLSTATE 42501 (`insufficient_privilege`)**.

The discrimination matters. If the probe returned an FK violation (`23503`) instead, that would mean execution got *past* the privilege check — i.e. the grant is still effective and the catalog view lied. Only 42501 counts as PASS.

**Zero residue either way.** If a probe unexpectedly succeeded, the subsequent `RAISE` rolls the whole transaction back, including the probe row. Nothing can be left behind.

Full BLOCK 3 assertion set:

1. I/U/D absent for all three client roles (9 assertions)
2. SELECT still present for `authenticated`
3. I/U/D still present for `postgres`
4. row count still exactly **2**
5. policy count still exactly **4**
6. 5 definer RPCs still secdef + postgres-owned
7. `authenticated` retains EXECUTE on all 5; `anon` holds EXECUTE on none
8. 3/3 negative probes hit 42501

---

## 6. ROLLBACK

Data-free, immediate:

```sql
GRANT INSERT, UPDATE, DELETE
   ON public.session_teachers
   TO authenticated, anon, service_role;
```

Because BLOCK 3 raises inside the transaction, a *failed* apply needs no rollback at all — `apply_migration` unwinds it atomically. The statement above is only for reverting a **successful** apply.

Note the asymmetry: rolling back S0A restores the P0 hole (rev2 §9). It should only be done if S0A demonstrably breaks a legitimate path — which the sweep says cannot happen, but which real-login QA is what actually proves.

---

## 7. POST-APPLY VERIFICATION (not in the migration — requires real login, D2/D3)

The migration proves the grant state. It cannot prove the product still works. After apply:

| # | Check | Account | Expected |
|---|---|---|---|
| 1 | Create a session with teachers | `hieutruong.kidshouse@demo.demenart.com` / `Test@123` | succeeds — `create_lesson_session` writes via definer |
| 2 | Edit session teachers | same | succeeds — `set_session_teachers` writes via definer |
| 3 | Schedule detail panel renders teacher list | same | succeeds — SELECT retained |
| 4 | Direct PostgREST write from browser console | any authenticated | **403 permission denied** |
| 5 | Teacher workspace loads | `gv.linh.kidshouse@demo.demenart.com` / `Test@123` | unchanged |
| 6 | Session media upload | `gv.linh.kidshouse@demo.demenart.com` / `Test@123` | succeeds — `upload_media` branch C via definer RPC |
| 7 | `session_teachers` row count | ops query | still **2** |

Checks 1, 2 and 6 are the ones that would expose a wrong assumption about definer privilege. Check 4 is the point of the whole migration.

---

## 8. STOP LINE

Authored only. **Not applied. Not deployed. No frontend change. S0B/S1 not opened.**

Two things are needed before apply:

1. **Decision on S0A-FINDING-01** (§2) — A, B, or C.
2. **Explicit Owner go to apply**, since this is a DB mutation.

If **B** or **C**: I revise BLOCK 2 and the BLOCK 3 privilege array, re-present, then wait for the apply instruction.
