# DMA V114B-E3 — WP2 IMPLEMENTATION READINESS PACK

**Revision:** rev2 (supersedes rev1 in full)
**Status:** READY FOR S0A — no migration written, no DB mutated
**Scope:** Canonical session teacher participation model (planned dimension)
**Endpoint discipline:** RULES D309 · SYSTEM_MAP v1.14 · does NOT canonicalize RULES/SYSTEM_MAP
**E3-SG-01:** REMAINS OPEN (authority semantics deferred to WP4)

---

## 0. REVISION SUMMARY (rev1 → rev2)

| # | Change | Source |
|---|---|---|
| 1 | Residual Edge sweep **CLOSED** — 16/16 Edge Functions read in full | CTO §RESIDUAL EDGE SWEEP |
| 2 | GATE-1 / GATE-2 / GATE-3 **FROZEN** | CTO §OWNER GATES |
| 3 | Canonical `participation_role` corrected: `primary` · `co_teacher` · `assistant` (generic `supporting` **removed**) | CORRECTION 2 |
| 4 | S2 becomes **compatibility dual-write**; legacy writes do NOT stop at S2 | CORRECTION 3 |
| 5 | Supersession **actor hardening** + full immutability set | CORRECTION 4 |
| 6 | Stage dependency matrix revised — GATE-1 is **not** an S0A blocker | CORRECTION 1 |
| 7 | Rollback boundary moved from S2 → **S4** | CORRECTION 3 |
| 8 | S0A exact prerequisites + exact grant-revoke set stated | CTO §OUTPUT |
| 9 | Live cutover dataset re-audited (D1) — exact backfill row count pre-computed | D1 |

---

## 1. LIVE DATASET RE-AUDIT (D1 — verified this session, read-only)

**Schema facts corrected against live DB.** rev1 assumed `lesson_sessions.distribution_id`; the real column is **`lesson_sessions.class_distribution_id`**, and the distribution lead column is **`class_distributions.lead_teacher_id`** (not `lead_teacher_profile_id`). Any migration text carrying the rev1 names will fail.

### 1.1 Table shapes

| Table | Columns (relevant) |
|---|---|
| `lesson_sessions` | `id · class_distribution_id · lesson_version_id · distribution_item_id · title · scheduled_at · duration_min · content_override · state · taught_by · created_at · updated_at · remote_channel_key · remote_code · remote_code_rotated_at · cancel_reason` |
| `class_distributions` | `id · class_id · program_id · source_distribution_id · title · lead_teacher_id · state · applied_by · applied_at · created_at · updated_at` |
| `session_teachers` (legacy) | `id · session_id · profile_id · role (text) · created_at` |
| `session_teacher_assignments` (canonical) | **DOES NOT EXIST** — created by S1 |

### 1.2 Cutover population

| Metric | Value |
|---|---|
| `lesson_sessions` total | **8** |
| Sessions with a resolvable distribution lead | **8 / 8** (zero gaps) |
| Sessions with legacy `session_teachers` rows | **2** |
| Legacy rows total | **2** (`lead` × 1 · `assist` × 1) |
| Sessions with `taught_by` set | **3** |
| `taught_by` ≠ distribution lead | **0** (coincidental — see §1.4) |

### 1.3 Exact per-session cutover map (frozen input to S1)

| Session | State | Dist lead | Legacy row | Canonical result |
|---|---|---|---|---|
| `2fab0c56…3c20` | completed | `1810667b…9851` | `lead` = same profile | **1 × primary** (merge) |
| `aaaa0000…a0003` | in_progress | `d1000000…0011` | — | 1 × primary |
| `aaaa0000…a0001` | taught_report_pending | `d1000000…0011` | — | 1 × primary |
| `aaaa0000…a0002` | taught_report_pending | `d1000000…0011` | — | 1 × primary |
| `8dcf9f2e…7f30` | cancelled | `d1000000…0011` | `assist` = `d1000000…0014` | 1 × primary **+ 1 × assistant** |
| `91bc03d8…b821` | scheduled | `d1000000…0011` | — | 1 × primary |
| `3bfb9730…1404` | scheduled | `d1000000…0011` | — | 1 × primary |
| `ea85798a…2041` | cancelled | `d1000000…0011` | — | 1 × primary |

**S1 expected canonical row count = 9** (8 × `primary` + 1 × `assistant` + 0 × `co_teacher`).
This exact number is the S1 BLOCK 3 `RAISE` guard. Any other count → rollback.

The single legacy `lead` row is on the same profile as its distribution lead → **merge**, per CORRECTION 2. It does **not** produce a second row.

### 1.4 Explicit non-inference

`taught_by` currently never diverges from the distribution lead. This is a **property of the current 8-row demo dataset, not an invariant**. WP2 must not:
- derive planned primary from `taught_by`;
- assert primary = `taught_by` in any CHECK, trigger, or view;
- treat the two as interchangeable in QA.

`taught_by` is *actual/responsible* evidence. The canonical planned dimension is a **separate axis** (§4). Conflating them is precisely the E3-SG-01 error and is forbidden in WP2.

---

## 2. OWNER GATES — FROZEN

### GATE-1 — Legacy backfill provenance · **Option A: snapshot primary for all 8 sessions**

Binding constraints:

| Constraint | Value |
|---|---|
| `source` | `legacy_cutover_snapshot` |
| `valid_from` | migration timestamp (`now()` at apply) |
| `assigned_by` | `NULL` |
| Backdating | **FORBIDDEN** |
| Semantic label | *current-lead snapshot at cutover* — **NOT** "original planned assignment" |
| `reason` text | must state explicitly that this is a cutover snapshot of the then-current distribution lead, with unknown original intent |
| `actual` / `responsible` dimension rows | **MUST NOT be created** |

The reason string is part of the data contract, not commentary. Required literal semantic (Vietnamese, exact wording to be fixed at S1 authoring):

> Ảnh chụp giáo viên phụ trách hiện hành tại thời điểm cutover V114B-E3-WP2. Không phải phân công gốc. Ý định phân công ban đầu không xác định.

### GATE-2 — RPC naming · **Option B: canonical + deprecated alias**

| RPC | Status in WP2 |
|---|---|
| `set_session_supporting_teachers` | **NEW canonical** |
| `set_session_teachers` | **KEPT** as deprecated compatibility alias |
| Drop of alias | **FORBIDDEN in WP2** — earliest S4, formally scheduled WP3+ |

The alias must delegate to the canonical RPC — not duplicate its body. One authorization implementation, one writer path.

### GATE-3 — QA fixture · **APPROVED, isolated fixture profile**

| Rule | Value |
|---|---|
| Target | dedicated inactive fixture profile for Q10 / Q11 / Q12 |
| Demo teacher profiles | **MUST NOT be mutated** (`gv.linh.kidshouse`, `gv.han.demen`, `gv.my.kidshouse` untouched) |
| Naming | name and email must self-identify as QA fixture (e.g. `qa.fixture.inactive@demo.demenart.com`, full name `QA FIXTURE — Inactive Teacher (V114B-E3-WP2)`) |
| Lifetime | created at S5, destroyed at S5 close |
| Closeout requirement | must report **residue = 0** (profile deleted, assignments deleted, audit rows retained) |

**Mutation authorization note:** GATE-3 approves the *fixture design*. Actual creation is a DB mutation and still requires Jean's explicit go at S5 execution time. Approval of the plan ≠ approval of the write.

---

## 3. RESIDUAL EDGE SWEEP — **CLOSED**

**Verdict: CLOSED — NO direct service-role writer on legacy assignment tables. S0A is unblocked.**

All **16 / 16** Edge Functions have now been read in full source. rev1 covered 4; this revision reads the remaining 12.

### 3.1 Per-function findings (12 residual)

Questions per CTO: **(1)** service-role client? **(2)** direct read/write of `session_teachers` · `session_teacher_assignments` · `lesson_sessions` · `class_distributions` · `profiles.state` · `profiles.role`? **(3)** assignment/capability RPC? **(4)** writer or bypass path requiring migration before S0A?

| # | Function | v | Q1 svc | Q2 assignment tables | Q2 `profiles` cols | Q3 capability RPC | Q4 migrate before S0A |
|---|---|---|---|---|---|---|---|
| 1 | `get_signed_media_url` | 23 | ✅ | **none** | `id`, `school_id` | ✗ (media gates only) | **NO** |
| 2 | `school_media_admin` | 2 | ✅ | **none** | `id`, `school_id`, **`role`** | ✗ | **NO** |
| 3 | `kid_gate` | 8 | ✅ | **none** | **none** | ✗ | **NO** |
| 4 | `purge_trash` | 2 | ✅ (cron) | **none** | **none** | ✗ | **NO** |
| 5 | `resolve_share_link` | 8 | ✅ (public) | **none** | **none** | ✗ | **NO** |
| 6 | `invite_master` | 8 | ✅ | **none** | `id`, **`role`**, `email`, `full_name`, `school_id`, `user_id` | ✗ | **NO** |
| 7 | `invite_staff` | 7 | ✅ | **none** | `id`, **`role`**, `email`, `full_name`, `school_id`, `user_id` | ✗ | **NO** |
| 8 | `invite_parent` | 8 | ✗ | **none** | **none** | ✗ | **NO** — retired stub, HTTP 410 |
| 9 | `accept_parent_invitation` | 2 | ✅ | **none** | `id` (existence probe) | ✗ | **NO** |
| 10 | `accept_family_invitation` | 1 | ✅ | **none** | `id` (existence probe) | ✗ | **NO** |
| 11 | `upload_notification_sound` | 6 | ✅ | **none** | **none** | ✗ | **NO** |
| 12 | `upload_kid_game_sound` | 1 | ✅ | **none** | **none** | ✗ | **NO** |

### 3.2 Aggregate result across all 16

| Question | Result |
|---|---|
| Direct INSERT/UPDATE/DELETE on `session_teachers` from any Edge | **0** |
| Direct read of `session_teachers` from any Edge | **0** |
| Any reference to `session_teacher_assignments` | **0** (table does not exist) |
| Direct write to `lesson_sessions` or `class_distributions` from any Edge | **0** |
| Any Edge reading `profiles.state` | **0** |
| Edge functions reading `profiles.role` | **3** (`school_media_admin`, `invite_master`, `invite_staff`) — identity/media gates only, no session authority |
| Assignment-capability consumers | **2** — `upload_media` (branch C) and `delete_session_media`, both **via SECURITY DEFINER RPC `check_session_media_upload_access`**, neither touching the tables directly |

**Consequence:** every assignment-relevant path already routes through a SECURITY DEFINER RPC. The `session_teachers` table grants to `authenticated` / `anon` / `service_role` are pure attack surface with **zero live consumer**.

### 3.3 Two out-of-scope findings recorded (NOT fixed in WP2)

| ID | Finding | Disposition |
|---|---|---|
| **E3-P2-EDGE-01** | `invite_staff` gates on `staff.role ∈ {lead_teacher, assistant_teacher}` but **never checks `staff.state`**. An offboarded teacher profile can still be granted a fresh login. | Same family as V114A P1-6 / P1-11 (offboarding not enforced at gate). **Not a WP2 concern** — no assignment semantics. Log to P2 backlog. |
| **E3-P2-EDGE-02** | `school_media_admin` gates on `role ∈ {super_admin, master_admin}` without `state`. Offboarded master retains school media delete/purge. | Same family. P2 backlog. |

Neither blocks S0A. Both are recorded so WP2 closeout cannot be read as having cleared them.

### 3.4 Load-bearing architectural confirmation

`invite_master` v8 carries an empirically-earned comment confirming a fact WP2's entire trigger design depends on:

> service_role bypasses RLS but does **NOT** bypass triggers.

This is the mechanism that makes §7 supersession hardening enforceable against every client class. It also surfaces a hazard: `link_master_user` is a SECURITY DEFINER RPC that **deliberately disables a protection guard inside its transaction** (D85 pattern). WP2 must ensure **no equivalent escape hatch exists for assignment invariants** — see §7.6.

---

## 4. CANONICAL PARTICIPATION ROLE — CORRECTED

Generic `supporting` is **removed from the model entirely**. It survives only inside the RPC *name* (`set_session_supporting_teachers`), which describes the operation, not the stored value.

### 4.1 Canonical CHECK constraint

```
participation_role ∈ { 'primary', 'co_teacher', 'assistant' }
```

### 4.2 WP2 mapping (exhaustive — no other mapping permitted)

| Input | → Canonical role | Notes |
|---|---|---|
| `class_distributions.lead_teacher_id` snapshot | **`primary`** | GATE-1, `source='legacy_cutover_snapshot'` |
| Teacher IDs currently selected as extras via UI | **`assistant`** | conservative default |
| Legacy `session_teachers.role = 'assist'` | **`assistant`** | 1 row in live data |
| Legacy `session_teachers.role = 'lead'`, same profile as cutover primary | **merge into `primary`** | do not emit a second row — 1 row in live data |
| Legacy `session_teachers.role = 'lead'`, different profile from cutover primary | **BLOCK — escalate** | 0 rows in live data; if this ever appears, S1 must halt, not guess |
| — | **`co_teacher`** | **NOT CREATED IN WP2.** No product action currently expresses co-teaching. Reserved value only. |

### 4.3 Prohibition

Legacy `role` text must **not** be repurposed as canonical evidence beyond the four mappings above. In particular, legacy `lead` is **not** proof of planned primary intent — it is one weak signal that happens to agree with the distribution lead in the only live instance. The canonical primary derives from `class_distributions.lead_teacher_id`, always.

### 4.4 Cardinality

- Exactly **one** `active` `primary` per (`session_id`, `dimension='planned'`) — partial unique index.
- `co_teacher` / `assistant`: unbounded, but unique per (`session_id`, `profile_id`, `dimension`) among `active` rows.
- A profile must not hold two distinct active roles on the same session/dimension.

---

## 5. REVISED STAGE DEPENDENCY MATRIX (CORRECTION 1)

| Stage | Depends on | Blocked by |
|---|---|---|
| **S0A** — legacy table lockdown | Residual Edge sweep **PASS** (§3, CLOSED) | *nothing else* |
| **S1** — canonical table + backfill | S0A · **GATE-1** | — |
| **S2** — canonical writer + compat dual-write | S1 · **GATE-2** · **Journal audit prerequisite (§8)** | — |
| **S3** — readers + frontend cutover | S2 | — |
| **S4** — stop legacy mirror, harden | S3 | — |
| **S5** — QA matrix incl. Q10/Q11/Q12 | S4 · **GATE-3** | — |

**Explicitly corrected:** GATE-1 is **not** a blocker of S0A. rev1 stated otherwise; that was wrong. S0A is a pure grant revocation and depends only on the Edge sweep, which is now closed.

---

## 6. S2 — COMPATIBILITY DUAL-WRITE (CORRECTION 3)

rev1 stopped legacy writes at S2 while S3 readers were still on legacy. That created a data gap. Corrected sequence:

### S2 — canonical becomes source of truth, legacy mirrored

| Rule | Requirement |
|---|---|
| Source of truth | canonical `session_teacher_assignments` |
| Writer | writes canonical **first** |
| Legacy mirror | supporting assignments mirrored to `session_teachers` **in the same transaction** |
| Mirror purpose | compatibility for not-yet-cutover readers/frontend **only** |
| Mirror history | **no additional history created in legacy** — mirror is a projection, replace-in-place, never append |
| Atomicity | dual-write must be atomic; partial write is a hard failure, not a warning |
| Drift verification | every writer path must verify **drift = 0** post-write |
| `set_session_planned_primary` | **NOT exposed and NOT granted to frontend before S3** |

Mirror is write-only downward: canonical → legacy. Nothing reads legacy back into canonical.

### S3 — readers and frontend cutover

| Rule | Requirement |
|---|---|
| Readers | all cutover to canonical |
| Capability consumers | must filter `dimension='planned'` **AND** `state='active'` — both, always |
| Verification | production QA confirms canonical-sourced results |

### S4 — mirror stop and hardening

| Rule | Requirement |
|---|---|
| Legacy mirror | **STOPPED** |
| Compatibility alias | no longer used by frontend |
| `session_teachers` | read-only / deprecated |
| Hardening | final ACL + trigger enforcement |

---

## 7. SUPERSESSION ACTOR HARDENING (CORRECTION 4)

Enforced by trigger, not convention. `service_role` bypasses RLS but **not** triggers (§3.4) — so the trigger is the true boundary for every client class.

### 7.1 State machine

| Transition | Allowed |
|---|---|
| `active` → `superseded` | ✅ only legal transition |
| `superseded` → `active` | ❌ **FORBIDDEN** |
| `superseded` → `superseded` (any field change) | ❌ **FORBIDDEN** — rows fully immutable |
| `active` → `active` (mutable fields only) | ✅ per §7.3 |

### 7.2 Server-derived fields — client input rejected

| Field | Rule |
|---|---|
| `superseded_at` | set by server (`now()`). Client-supplied value → **reject**, not overwrite. |
| `superseded_by` | derived server-side from the **real actor**. Never client-supplied. |
| `assigned_by` | derived server-side for all non-legacy INSERTs. Legacy backfill uses `NULL` (GATE-1). |
| `reason` | **MANDATORY**, and non-empty after `trim()`. `''`, `'   '`, and `NULL` all rejected. |

Actor derivation must resolve to a real profile. When `auth.uid()` is NULL (Edge/service context) and no explicit server-side actor is established, supersession must **fail**, not record NULL. An unattributable supersession is not evidence.

### 7.3 Immutable column set

Immutable on every UPDATE of an `active` row:

`session_id` · `profile_id` · `school_id` · `dimension` · `source` · `assigned_by` · `valid_from` · `created_at`

Mutable only via the `active → superseded` transition: `state` · `superseded_at` · `superseded_by` · `reason`.

Correcting a mistake = supersede + insert new row. **Never** edit in place. That is the entire point of the dimension model.

### 7.4 No role bypass

`service_role` does **not** bypass these invariants. The trigger is unconditional on role. There is no `IF current_user = 'service_role' THEN RETURN NEW` escape.

### 7.5 Guard function properties

| Property | Required value |
|---|---|
| Security | `SECURITY INVOKER` |
| `prosecdef` | must verify `= false` in BLOCK 3 |
| Grants | per D15 — `CREATE OR REPLACE` resets to PUBLIC; explicit REVOKE/GRANT in a separate block, verified via `aclexplode` |

### 7.6 No D85-style escape hatch

`link_master_user` sets a precedent of a SECURITY DEFINER RPC disabling a guard within its transaction. **WP2 must not create any equivalent for assignment invariants.** No session-local flag, no `set_config` guard toggle, no owner-only bypass RPC. If a legitimate future need arises, it is a designed exception with its own gate — not a WP2 convenience.

---

## 8. JOURNAL AUDIT PREREQUISITE (before S2 — currently OPEN)

Mandatory full read before S2 authoring:
- `submit_session_journal`
- `get_session_detail`

Requirements:

| Rule | Statement |
|---|---|
| `can_submit_journal` | must use a **shared authorization helper**, or mirror **every** authorization branch of the real writer — not a subset |
| `is_session_lead` | **must not** be the sole check |
| Journal authority semantics | **must not change** in WP2 |
| Planned primary as responsible teacher | **FORBIDDEN** — planned ≠ responsible (see §1.4) |
| E3-SG-01 | **MUST NOT be closed** in WP2 |

Per D293: the UI gate must mirror every authorization branch of its RPC, not just the ownership branch. This audit is what makes that possible; it is not optional and not deferrable past S2.

---

## 9. S0A — EXACT PREREQUISITES AND CONTENT

### 9.1 Prerequisites — final

| # | Prerequisite | Status |
|---|---|---|
| 1 | Residual Edge sweep CLOSED, zero direct service-role writer on legacy assignment | ✅ **MET** (§3) |
| 2 | All assignment RPCs confirmed `SECURITY DEFINER`, owner `postgres` | ✅ **MET** (§9.2) |
| 3 | Ops escape hatch survives revocation | ✅ **MET** (§9.4) |
| 4 | GATE-1 | ❌ **NOT a prerequisite** (CORRECTION 1) |

**S0A is unblocked.**

### 9.2 Why revocation is safe — verified live

| RPC | Owner | `prosecdef` |
|---|---|---|
| `create_lesson_session` | `postgres` | `true` |
| `set_session_teachers` | `postgres` | `true` |
| `set_distribution_lead` | `postgres` | `true` |
| `assign_class_distribution` | `postgres` | `true` |
| `start_session` | `postgres` | `true` |

All five execute with the **definer's** privileges (`postgres`). Revoking table-level DML from `authenticated` / `anon` / `service_role` does **not** affect them.

### 9.3 Exact revoke set

```
REVOKE INSERT, UPDATE, DELETE ON public.session_teachers
  FROM authenticated, anon, service_role;
```

- `SELECT` is **retained** for `authenticated` during the compatibility window (§6, S2/S3 readers). Removed at S4.
- The 4 existing RLS policies on `session_teachers` are **not** dropped in S0A. Grants and policies are separate layers; removing both at once destroys the ability to attribute a failure. Policies are handled at S4.

### 9.4 Ops escape hatch — preserved

Verified live: MCP `execute_sql` runs as **`current_user = 'postgres'`** (table owner, `rolbypassrls = true`). Owner-side emergency correction remains available after revocation. The revocation closes client surface, not operator surface.

### 9.5 S0A verification (BLOCK 3, `RAISE` guard)

Must assert all of:
1. `has_table_privilege` for INSERT/UPDATE/DELETE on `session_teachers` = `false` for each of `authenticated`, `anon`, `service_role`;
2. `SELECT` for `authenticated` = `true`;
3. all five RPCs in §9.2 still `prosecdef = true`, owner `postgres`;
4. `session_teachers` row count unchanged = **2**;
5. ACL re-verified via `aclexplode(coalesce(relacl, acldefault('r', relowner)))` per D15/D92.

Any failure → `RAISE EXCEPTION` → atomic rollback.

---

## 10. REVISED ROLLBACK BOUNDARY (CORRECTION 3)

| Stage | Rollback capability |
|---|---|
| **S0A** | Trivial — re-`GRANT`. No data touched. |
| **S1** | Clean — drop canonical table. Legacy untouched and authoritative. |
| **S2** | **Clean** — legacy mirror is maintained in-transaction, so legacy remains a complete projection of canonical supporting assignments. Reconstruct from either side. |
| **S3** | **Clean** — mirror still running; readers can be reverted to legacy. |
| **S4** | **BOUNDARY** — mirror stops. After S4, legacy diverges permanently. Rollback requires forward-fix, not revert. |

**Corrected from rev1:** rev1 placed the boundary immediately after S2 and accepted a data gap. With the compatibility mirror, **there is no data gap after S2**, and the true point of no return is **S4**.

---

## 11. NON-GOALS — HARD STOPS FOR WP2

| Not done in WP2 |
|---|
| Closing E3-SG-01 |
| Changing journal authority semantics |
| Creating `actual` or `responsible` dimension rows |
| Creating any `co_teacher` row |
| Dropping `set_session_teachers` |
| Dropping `session_teachers` |
| Fixing E3-P2-EDGE-01 / E3-P2-EDGE-02 (offboarding `state` gaps) |
| Mutating demo teacher profiles |
| Canonicalizing RULES / SYSTEM_MAP |
| Opening WP3 / WP4 |

---

## 12. STOP LINE

Per CTO instruction, this revision stops here.

**Not done:** no migration written · no DB modified · no frontend modified · nothing applied · nothing deployed · RULES/SYSTEM_MAP not canonicalized · WP3/WP4 not opened.

**Next action requires Owner go:** author S0A migration (grant revocation only, §9.3), submit for approval before apply.

---

*DMA V114B-E3 · WP2 Implementation Readiness Pack rev2 · Edge sweep CLOSED · GATE-1/2/3 FROZEN · E3-SG-01 OPEN*
