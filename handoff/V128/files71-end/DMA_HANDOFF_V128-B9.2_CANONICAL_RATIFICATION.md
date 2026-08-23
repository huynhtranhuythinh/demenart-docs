# DMA HANDOFF — V128-B9.2 · AUTHORITY CONTRACT CANONICAL RATIFICATION

**Milestone:** V128-B9.2 — Authority Resolver Foundation Contract, canonical ratification of the B9.1 design freeze.
**Mode:** GOVERNANCE CANONICALIZATION ONLY. 0 implementation · 0 SQL · 0 migration · 0 DB mutation · 0 FE · 0 UI.
**Date:** 2026-08-16
**Status:** ✅ **RATIFIED (governance).** Canonical append complete + append-only integrity proven.

---

## Boot verification (STEP 0 — zero drift)

| Check | Required | Live / Artifact | Status |
|---|---|---|---|
| `DMA_RULES.md` endpoint | D365 | D365 (block D365.1–.6) | ✅ |
| `DMA_SYSTEM_MAP.md` endpoint | v1.53 | v1.53 (B8-I1 block) | ✅ |
| `DMA_HANDOFF_V128-B8_CLOSEOUT.md` | V128-B8 CLOSEOUT | present, read directly | ✅ |
| Backend tail | `20260815182235` | `v128_b8_i1_decision_lifecycle_foundation` | ✅ |
| B9.1 artifact | present + read directly | `DMA_V128-B9.1_AUTHORITY_CONTRACT_DESIGN_FREEZE.md` (21,715 B) | ✅ |
| **Artifact lineage** | freeze declares D365 / v1.53 / B8 / tail `20260815182235` | B9.1 STEP-0 self-declaration = identical to live | ✅ **match** |

Endpoint + artifact lineage matched → ratification proceeded. Read from real files, not memory.

---

## What was canonicalized

**`DMA_RULES.md` → D366** (new rule series D366.1–D366.8), **`DMA_SYSTEM_MAP.md` → v1.54** (Authority Resolver architectural position). No standalone rule mints an executable invariant, enum, constraint, function, trigger, policy, or migration.

### Accepted decisions (frozen → ratified)

1. **Authority Resolver = policy-decision primitive** (D366.1). Read-only · deterministic · explainable · consumed-not-embedded. Explicit rejections: NOT role checker / permission replacement / RLS replacement / adapter replacement / lifecycle-controller replacement.
2. **Authority model** (D366.2): `WHO + WHAT + WHERE + OBJECT CONTEXT + DECISION CONTEXT` → contextual verdict, not classification/entitlement. Role ≠ Permission ≠ Capability ≠ Authority.
3. **capability/action_key = PRIMARY input; decision_type = secondary** (D366.3). Path-symmetry rationale: capability is the only anchor present across direct-execute (MEDIUM) and decision-gated (HIGH+) paths.
4. **Single-source authority POLICY VERDICT** (D366.4 · CTO Correction 1): explicitly NOT "single source of authorization." RLS + adapter domain-safety + lifecycle controller still enforce. Resolver owns verdict/eligibility/source/reasons only.
5. **Identity Option A** (D366.5): one user → one authority-bearing profile; delegation = authority source on single identity. `UNIQUE(user_id)` **NOT** enforced — reconciliation precondition recorded.
6. **Vocabulary DRAFT only** (D366.6 · CTO Correction 2): `authority_source` + `reason_codes` = reserved candidates, **NOT minted**. Final taxonomy post-B9.3 evidence. **B9.1 §8.7 (mint-at-B9.2) explicitly SUPERSEDED** and recorded as such.
7. **Strangler adoption, 4 phases** (D366.7): new governed actions → decision paths → adapter policy → legacy admin RPCs. Contract frozen before Phase 3. Big-bang rejected.

### CTO review corrections applied

- **Correction 1** — "single source of authority **policy verdict**" (not "authorization"). Applied verbatim in D366.4 and v1.54 invariant #1. (B9.1 Part 4 already used verdict-language natively.)
- **Correction 2** — no final enum mint; draft/reserved vocabulary only. Applied in D366.6 and v1.54 vocabulary block. Divergence vs B9.1 §8.7 recorded as supersession (not silent).

---

## Integrity proof (STEP 3)

- **Append-only VERIFIED.** Original bytes preserved exactly as a prefix of the new files (prefix md5 == original md5):
  - `DMA_RULES.md`: `1015939 → 1025834` B (+9,895), original prefix md5 `dc656c17e73e8081919abc4a93cd0b4e` intact.
  - `DMA_SYSTEM_MAP.md`: `560441 → 566625` B (+6,184), original prefix md5 `4da054c4d475f8ab0b8771459f360ab4` intact.
  - No deletion, no modification of prior bytes — tail additions only.
- **No executable content.** Zero DDL/DML/tool-exec statements in the appended blocks; SQL/migration/constraint tokens appear only in negation/deferred context ("0 SQL", "0 migration", "`UNIQUE(user_id)` deferred", "NOT minted").
- **No minted invariant beyond ratified conceptual scope.** No enum, constraint, function, or migration created.

---

## Live state (UNCHANGED — no mutation this milestone)

Backend tail `20260815182235`. Public: tables **94** · fns **251** · secdef **239** · policies **169** · triggers **34** · cron **1**; `mc_internal` {**7** fn / **6** secdef}. `mission_control_decisions` 0 rows · `mission_control_decision_transitions` 0 rows. Governed path dormant (class.assign MEDIUM → auto; no HIGH/CRITICAL registered). FE main pin `2.8.5`, 0 change.

---

## Deferred (NOT authorized by B9.2 — each requires explicit CTO authorization)

- **B9.3 — Phase-1 resolver skeleton** (first implementation; one *new* governed action authorized end-to-end via resolver; verify matrix; zero legacy touch).
- Final `authority_source` enum + `reason_code` taxonomy mint (post-B9.3 evidence).
- `UNIQUE(user_id)` enforcement (post reconciliation: re-verify duplicates=0 + D93 invite/link non-breakage).
- Delegation · object-scope expansion (`child.transfer`, session/school) · multi-approver/quorum · notification · inbox UI · workflow builder · AI recommendation · HIGH/CRITICAL activation.
- Legacy authority-site migration (≈51 `is_admin` / ≈29 hardcoded `master/sub_admin` / ≈18 `same_school`) — Strangler Phases 3–4.

---

## Next milestone

**B9.3 — Phase-1 Authority Resolver skeleton (first implementation).** NOT opened. Standing discipline: hard STOP at authorized scope boundary; await explicit CTO authorization before any B9.3 implementation, SQL, migration, or FE work.

---

## Boot pointer (next session)

Read canonical directly (never memory): `DMA_RULES.md` (→ **D366**) · `DMA_SYSTEM_MAP.md` (→ **v1.54**) · this handoff · B9.1 freeze artifact. Endpoint to re-pin: RULES **D366** · SYSTEM_MAP **v1.54** · HANDOFF **V128-B9.2-CANONICAL-RATIFICATION** · backend tail `20260815182235` · FE main pin `2.8.5`. Authority Resolver = design-frozen, **not built**. **Do not open B9.3 / any implementation** — await CTO decision. Block D365/v1.53 (B8-I1) = HISTORICAL SNAPSHOT (BẤT BIẾN).
