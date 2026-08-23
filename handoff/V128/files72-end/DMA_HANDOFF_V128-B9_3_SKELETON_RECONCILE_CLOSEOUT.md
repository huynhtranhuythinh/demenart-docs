# DMA HANDOFF — V128-B9.3 · AUTHORITY RESOLVER SKELETON — RECONCILE + CANONICALIZE

**Milestone:** V128-B9.3 — Authority Resolver Phase-1 skeleton, reconciliation of an out-of-canonical live layer + canonicalization + vocabulary mint.
**Mode:** AUDIT-FIRST · GOVERNANCE RECONCILE. **0 new migration · 0 DB mutation · 0 FE.** Read-only audit + read-only rehearsal + canonical append only.
**Date:** 2026-08-16
**Status:** ✅ **RECONCILED + CANONICAL.** Skeleton confirmed conformant to D366 · verify matrix 10/10 PASS · vocabulary minted.

---

## What happened (why this milestone exists)

Boot opened B9.3 believing it was greenfield. AUDIT-FIRST live re-pin (mandated, never memory) caught at STEP 1 that an **Authority Resolver skeleton was already applied to live** — migration `v128_b93_authority_resolver_skeleton`, backend tail `20260815201925`, **2026-08-15T20:19:25Z** — but its canonical closeout had been skipped (RULES stopped at D366, SYSTEM_MAP at v1.54, prior HANDOFF said "B9.3 NOT opened"). This was live↔canonical drift (D112). This milestone reconciles it.

---

## Boot verification (STEP 0 — pinned before work)

| Check | Required | Live / File | Status |
|---|---|---|---|
| `DMA_RULES.md` endpoint | D366 | D366 (block D366.1–.8) | ✅ |
| `DMA_SYSTEM_MAP.md` endpoint | v1.54 | v1.54 (B9.2 block) | ✅ |
| `DMA_HANDOFF_V128-B9.2_CANONICAL_RATIFICATION.md` | present | read directly | ✅ |
| Canonical backend tail (frozen) | `20260815182235` | recorded in D366/v1.54 | ✅ |
| **Live backend tail (measured)** | — | **`20260815201925`** (drift: +1 migration) | ⚠ **drift found** |

Note: top-of-file "CURRENT CANONICAL ENDPOINT" pointers are stale (`RULES D342/v1.30`, `SYSTEM_MAP D358/v1.46`) — pinned from latest appended block per boot protocol (D367.7).

---

## Provenance investigation (nhánh B)

- `schema_migrations.created_by = **huynhtranhuythinh@gmail.com**` — Owner account (matches GitHub `huynhtranhuythinh/demenart`). **Not rogue.**
- Migration is disciplined in-house: 3-block D92 (DDL → ACL → VERIFY), ACL harden D15/D231, `search_path=''`, `NOTIFY pgrst` (D289), fail-closed in-migration VERIFY incl. determinism smoke.
- Committed smoke: master **Nguyệt Thi** (`master_admin`, Kids House Montessori Đà Nẵng) probed own school `20:21:17Z` → `organization_role · authority_granted` (1 row `authority_probe_log`).
- Verdict: legitimate Owner-applied B9.3 skeleton; only the canonical closeout was skipped → reconciled here.

---

## What is live (audited directly, now canonical)

| Object | Detail | md5 |
|---|---|---|
| `mc_internal._resolve_authority(uuid,text,jsonb,jsonb)` | STABLE SECURITY DEFINER `search_path=''`, ACL EXECUTE `{postgres}`, returns `{eligible, authority_source, reason_codes}` | `56b5e3f5a14360990b51c080ff1da1cb` |
| `public.execute_authority_probe(uuid,uuid)` | SECURITY DEFINER `search_path=''`, ACL `{authenticated,postgres}`, isolated probe → `authority_probe_log` | `59e7c5d4a8d1dda25d9466500da82d13` |
| `mc_internal.authority_probe_log` | RLS on · 0 policy · grants `{postgres}` (DEFINER-write-only) · 1 row | — |
| registry `authority.probe` | object `authority` · LOW · active · adapter `authority.probe.v1` · required_context `{school_id}` | — |

**Zero legacy touch confirmed (live md5):** executor `execute_mission_control_action(text,uuid,jsonb,jsonb,uuid)` = `09ef5f48f3318bfb53e126f3bc81d40a` UNCHANGED · `_mc_transition_decision(uuid,text,uuid,text)` = `fe0eea599db711fb8472b37a72fa25e4` UNCHANGED. The skeleton is an isolated probe; it does not consume the main executor.

---

## Verify matrix (read-only rehearsal — 10/10 PASS, zero residue)

Resolver called directly against live fixtures (STABLE → no writes); `authority_probe_log` count unchanged.

| # | Case | Verdict | Pass |
|---|---|---|---|
| C1 | nil actor | `none · [actor_unresolved]` | ✅ |
| C2 | requester=actor ∧ phase=approve | `none · [self_decision_forbidden]` | ✅ |
| C3 | platform admin | `platform_role · [authority_granted]` eligible | ✅ |
| C4 | master ∩ own school | `organization_role · [authority_granted]` eligible | ✅ |
| C5 | master × other school | `none · [organization_scope_mismatch]` | ✅ |
| C6 | school_id null | `none · [object_context_mismatch]` | ✅ |
| C7 | non-org role (GV) + valid school | `none · [role_not_eligible]` | ✅ |
| C8 | ACL not leaked anon/authenticated | `true` | ✅ |
| C9 | STABLE + SECURITY DEFINER | `true` | ✅ |
| C10 | zero residue (log unchanged) | `true` | ✅ |

Not over-claimed as "production-proven": positive governed path = 1 committed smoke + full matrix on read-only rehearsal; `child.transfer` (real governed action) not built.

---

## Decisions ratified this milestone

1. **Proceed A** — reconcile-first (vs C rollback; provenance clean, work conformant).
2. **iii-A** — vocabulary minted as **documented string-set (text, not PG enum)**. Closes D366.6 deferral. `authority_source` {platform_role, organization_role, none} + reserved {explicit_permission, assignment, delegation}; `reason_codes` {authority_granted, actor_unresolved, self_decision_forbidden, object_context_mismatch, organization_scope_mismatch, role_not_eligible} + reserved {capability_not_granted}.

---

## Canonical output (this session)

- `DMA_RULES.md` → **D367** (D367.1–.8) appended. Append-only integrity verified (original bytes preserved as exact prefix).
- `DMA_SYSTEM_MAP.md` → **v1.55** appended. Append-only integrity verified.
- This HANDOFF (fresh).

---

## Live inventory (reconciled — v1.55)

Backend tail **`20260815201925`**. Public: tables **94** · fns **252** · secdef **240** · policies **169** · triggers **34** · cron **1**; `mc_internal` {**8** fn / **7** secdef} + table `authority_probe_log`. Registry rows **3**. `mission_control_decisions` 0 · `mission_control_decision_transitions` 0 · `authority_probe_log` 1. FE main pin `2.8.5`, 0 change.

---

## Deferred / NOT authorized (each needs explicit CTO open + APPLY)

- **⭐ `child.transfer`** — first REAL governed business action wired through `execute_mission_control_action` (skeleton→production, Strangler Phase 1→2). Target selected (locked) but build NOT opened.
- Resolver consumption by decision paths (open/inbox/resolve/cancel).
- `UNIQUE(user_id)` constraint decision — live has partial unique index `profiles_user_id_uq WHERE user_id IS NOT NULL`; duplicates=0 verified; table-constraint-vs-index open.
- Delegation · object-scope expansion (session/school) · multi-approver/quorum · notification · inbox UI · HIGH/CRITICAL activation.

---

## Governance lesson (D367.7)

Every `apply_migration` MUST be paired with a **same-session canonical closeout** (RULES + SYSTEM_MAP + HANDOFF). An un-closed apply desyncs canonical from live and mis-pins the next boot; only direct live audit (never memory) catches it. Refresh the stale top-of-file endpoint pointers at next governance touch.

---

## Boot pointer (next session)

Read canonical directly (never memory): `DMA_RULES.md` (→ **D367**) · `DMA_SYSTEM_MAP.md` (→ **v1.55**) · this handoff. Endpoint to re-pin: RULES **D367** · SYSTEM_MAP **v1.55** · HANDOFF **V128-B9.3-SKELETON-RECONCILE** · backend tail **`20260815201925`** · FE main pin `2.8.5`. Authority Resolver primitive = **LIVE + verify-matrix-proven, isolated probe scope**. `child.transfer` build NOT opened — await CTO authorization + APPLY. Block D366/v1.54 (B9.2) = HISTORICAL SNAPSHOT (BẤT BIẾN).
