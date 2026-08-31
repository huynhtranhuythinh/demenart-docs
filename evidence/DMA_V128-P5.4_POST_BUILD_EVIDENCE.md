# DMA · V128-P5.4 — Assignment Governance Hardening
## POST-BUILD EVIDENCE (backend, LIVE via Supabase MCP)

- **Project:** `xcvhacymrbhdhohyylyq` (production, `demenart.com`)
- **Scope:** backend only — SQL migrations + live-DB verify + JWT-impersonated rolled-back rehearsal
- **Status:** WP1 · WP2 · WP3 = **APPLIED + VERIFIED + REHEARSED**, zero unintended residue
- **Deployment:** **NOT DEPLOYED** — no FE deploy, no Lovable, no Cloudflare
- **This is evidence only — NOT a PASS declaration.** ChatGPT/Owner perform independent
  repo/git/typecheck/build verification before P5.5.
- Frozen contract = §2 of the P5.4 boot directive. Docs (`RULES`/`SYSTEM_MAP`/`HANDOFF`)
  live in the separate `demenart-docs` repo and were **not** mutated by this build.

---

## 1. Migrations applied (this session)

| Version | Name |
|---|---|
| `20260828144320` | `v128_p5_4_wp1_set_distribution_lead_fail_closed_audit` |
| `20260828144953` | `v128_p5_4_wp2_teacher_visibility_session_scoped` |
| `20260828145844` | `v128_p5_4_wp3a_taught_attribution_ledger_substrate` |
| `20260828150205` | `v128_p5_4_wp3b_taught_attribution_runtime_and_correction` |

Contiguous tail after the pre-P5.4 baseline (`…074837 → …102507`). No drift.
Every migration used the D92 three-block pattern (DDL → REVOKE/GRANT → VERIFY fail-closed),
wrapped atomically by `apply_migration`; each ran `NOTIFY pgrst,'reload schema'` (D289).

> **Fail-closed proof (incidental):** WP3b's first apply raised in its own VERIFY block
> (a false-positive on the migration's inner comments containing the literals `is_admin`/
> `session_reports`) and the **entire migration rolled back atomically** — confirming the
> VERIFY guard aborts and reverts. Comments were reworded (logic unchanged) and re-applied.

---

## 2. Object evidence lock (final live read)

### 2.1 Touched functions — md5(pg_get_functiondef) + EXECUTE ACL
All ACLs = `{authenticated, postgres(owner), service_role}`; `anon`/PUBLIC revoked.

| Function | md5 |
|---|---|
| `set_distribution_lead` | `19376e2ae5807a48ffd28b1d27e810dd` |
| `get_teacher_classes` | `16146fa13e18d2fd436dcaf415a4ed52` |
| `get_teacher_classes_in_school` | `e62724738c8d85b7578898e2ad872c48` |
| `start_session` | `257f81ab15216634bf75604784d3464e` |
| `correct_session_taught_teacher` | `c44bb21aa1be6ed922abbb42e2b3e6f7` |

### 2.2 Frozen surfaces — UNCHANGED (not present in any P5.4 migration)
| Function | md5 (baseline == current) |
|---|---|
| `set_session_responsible_teacher` | `c15b26ec32008ff4254f2ad527629189` |
| `submit_session_journal` | `09f6b7a3bbc1dddf457832e74fc7da12` |
| `get_teacher_session_workspace` | `396598bf44176ef94c5516c42663fd9b` |

Report actor (`session_journal_submitted`) and the session-scoped workspace reference model
are byte-identical to their pre-P5.4 state.

### 2.3 New ledger table `session_teacher_attributions`
- RLS: **enabled**
- Constraints: **13**
- Indexes: **5**
- Append-only trigger: `trg_sta_attr_append_only` (BEFORE UPDATE OR DELETE)
- API-role grants (`anon`/`authenticated`/`service_role`): **0** (RPC-only; RLS-locked)

### 2.4 Sibling ledger untouched
`session_teacher_assignments` guard `trg_sta_append_only` still present (count = 1).

### 2.5 Persistent data change (the only one)
`session_teacher_attributions`: **5 rows**, all `attribution_source = 'legacy_taught_by_bootstrap'`
= exactly the 5 sessions in the DB with a known `taught_by`. Sessions with `taught_by IS NULL`
received **no** row (unknown remains unknown; no inference from Lead/assignment).

---

## 3. WP1 — Distribution-Lead fail-closed audit

**Change:** removed the `begin … exception when others then null; end;` wrapper around the
audit call in `set_distribution_lead`, leaving a bare
`perform public.write_audit_log('distribution_lead_changed', …)`. Authority
(`mc_internal._resolve_authority(…, 'class.assignment.lead.edit', …)`), no-op short-circuit,
and payload were byte-preserved.

**Rehearsal (JWT-impersonated, rolled back):**
- current-lead no-op → `{ok, already:true}`
- clear lead → `{ok:true, lead:null}`, `lead_after_in_txn = null` — `ok:true` **after** the
  un-swallowed audit ⟹ the audit write succeeded ⟹ audit is now fail-closed
- non-master actor → `not_authorized_for_school`
- cross-school master → `not_authorized_for_school`
- residue: current lead unchanged

**Deferred to Owner/ChatGPT:** live audit-fault-injection (§14.1.F) — proven by construction
(no exception handler ⇒ any audit failure aborts the txn), not yet fault-injected live.

---

## 4. WP2 — Teacher visibility, session-scoped

**Change:** rewrote both `get_teacher_classes()` and `get_teacher_classes_in_school(uuid)` to a
shared predicate:
- a **distribution** appears iff `is_lead OR (≥1 visible session)`
- a **session** is visible iff `is_lead OR current session_teacher_assignments(planned|responsible,
  is_current, valid_to IS NULL) for THIS session OR session_teachers for THIS session`
- the returned `sessions[]` is filtered by the same rule
- per-RPC cancelled-display preserved (legacy `<> 'cancelled'`; in-school surfaces cancelled +
  `cancel_reason` per P1_0b); `is_teacher_in_school` gate retained on the in-school RPC

**Rehearsal (constructed, rolled back — seed distribution `d1…031`, school `d1…0001`):**
- **Lead A** → 8/8 sessions (all, incl. cancelled surfaced by in-school) ✅
- **Supporting teacher on "Vương quốc âm thanh" (`aaaa…a0002`) only → `[aaaa…a0002]` and
  NOTHING else** ✅ **(headline §14.2.C: support on one session ⇏ the other sessions)**
- same via legacy no-school RPC → `[aaaa…a0002]` (both RPCs consistent, §5.5) ✅
- unrelated teacher → distribution absent (no phantom visibility) ✅
- residue: none

**Deferred to Owner/ChatGPT:** live single-session **assignment-path** proof — every seed session
already holds a current planned+responsible (one-current unique index), so no free slot existed
for a synthetic single-session assignment. The assignment `EXISTS` clause is structurally identical
to the support `EXISTS` clause proven above.

---

## 5. WP3 — Historical taught-teacher attribution

### 5.1 Substrate (WP3a)
`public.session_teacher_attributions` mirrors the `session_teacher_assignments` temporal-ledger
posture for the `taught` dimension:
- one-current partial-unique `(session_id, attribution_type) WHERE is_current`
- validity / self-supersede / source / actor / reason CHECKs; composite lineage UNIQUE; supersede
  FK `DEFERRABLE INITIALLY DEFERRED`
- append-only guard: DELETE blocked; UPDATE only the privileged controlled-close shape
  (`is_current true→false`, `valid_to null→set(>valid_from)`, `superseded_by null→set≠id`), every
  other column immutable
- **RLS-locked, RPC-only** — intentionally **tighter than STA** (no school SELECT policy yet)
- sources: `runtime_start` · `legacy_taught_by_bootstrap` · `historical_correction`

**Bootstrap:** one current attribution per session with `taught_by IS NOT NULL`
(`recorded_by = null`, `valid_from = least(coalesce(updated_at, scheduled_at, now()), now())`).
`taught_by NULL` ⇒ no row. Result: **5** rows.

**Guard rehearsal (rolled back):** DELETE blocked · arbitrary UPDATE blocked · bad-close UPDATE
blocked · target row intact.

### 5.2 Runtime + correction (WP3b)
**`start_session`** — on the real `scheduled|prep_ready|makeup → in_progress` transition, appends a
current `runtime_start` attribution (`recorded_by = the responsible teacher`), **conditional on
no existing current attribution** so an idempotent restart never duplicates. `taught_by` and the
attribution agree. Fail-closed. Auth / idempotency / `session_started` audit byte-preserved.

**`correct_session_taught_teacher(p_session_id, p_teacher_id, p_reason)`** — controlled superseding
attribution:
- authority mirrors `set_session_responsible_teacher`: same-school `master_admin`/`sub_admin`
  (`current_profile_role()` + `user_school_ids()`); **not** platform `is_admin()`
- reason required (reject empty/whitespace; max 500)
- allowed states: `taught_report_pending` · `report_pending_approval` · `completed`
- target validation: same-school, active, `lead_teacher`/`assistant_teacher`
- no-op → `already:true`; else close old + insert new current (`historical_correction`) + sync
  `lesson_sessions.taught_by`; fail-closed audit `session_taught_teacher_corrected`
  (`taught_from` / `taught_to` / `reason`)
- establishes an attribution when none existed (explicit, audited, `taught_from = null`)
- **does not** touch `session_reports`, journal history, or the `session_started` audit

**Acceptance rehearsal (rolled back):**
- `start` → `{ok, in_progress}`, `taught_by = d1…014`, 1 current attr `{runtime_start, 014}`
- `start` again → `already:true`, count still 1 (no duplicate, §6.4)
- correction (master) → `{ok, taught_from:011→012}`; old `{is_current:false, valid_to set,
  superseded}`; new `{historical_correction, 012, reason set, is_current}`; count 1;
  `taught_by` synced → 012
- no-op → `already:true`
- non-master → `not_authorized_for_school`
- cross-school master → `not_authorized_for_school`
- non-existent target → `teacher_invalid`
- blank reason → `reason_required`
- scheduled-state session → `bad_state`
- residue: fully reverted

---

## 6. Reconciliation (PHASE A) summary
Live definitions of all governed surfaces were read before any change. The only mismatches found
were the two `get_teacher_classes*` visibility defects that the frozen contract explicitly
prescribes fixing (WP2). No competing taught-attribution ledger pre-existed
(`session_teacher_attributions` was absent). Report/journal actor semantics intact. → PHASE A PASS,
no STOP.

---

## 7. Remaining gaps / deferred (for Owner)
1. `session_teacher_attributions` RLS is deliberately **tighter than STA** — no school SELECT
   policy yet; the read surface (read RPC + FE) is deferred to a later WP.
2. WP2 assignment-path single-session live proof — deferred (no free assignment slot in seed).
3. WP1 live audit-fault-injection (§14.1.F) — deferred (proven by construction).
4. No FE / read RPC wired for the attribution ledger this session.

---

## 8. Deployment status
**NOT DEPLOYED.** Backend migrations are live in the database; no frontend deploy, no
`deploy_project`, no Cloudflare go-live, no Lovable agent run were performed. Independent
verification (repo/git/typecheck/build) is required before P5.5.
