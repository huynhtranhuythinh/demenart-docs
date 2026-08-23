# 🗂️ DMA_HANDOFF_V128-B6.3-PHASE-3_CLOSEOUT.md — ACTION CONTROL PLANE · INTENT INTEGRITY

> **Ngày:** 2026-08-15 (GMT+7) · **Loại:** Phase 3 apply + canonical closeout (1 migration; intent fingerprint + Option-C forge closure; 0 FE change).
> **Boot phiên sau:** file này → `DMA_RULES.md` (tip **D363**) → `DMA_SYSTEM_MAP.md` (**v1.51**) → audit live DB (D1) → re-pin.
> **Endpoint:** RULES **D363** · SYSTEM_MAP **v1.51** · HANDOFF **V128-B6.3-PHASE-3** · backend tail **`20260815101138`** (`v128_b6_3_p3_intent_integrity`) · FE main pin `2.8.5`.

---

## 1. STATUS
**PHASE 3 CLOSED.** All four architectural gaps **G1·G2·G3·G4 = CLOSED**. B6.3 technical scope (design → P1 → P2 → P3) complete. **Overall B6.3 milestone closeout = Owner decision** (this record canonicalizes Phase-3 runtime; it does not itself stamp the milestone closed).

## 2. OBJECTIVE
Close **G3 (Intent Integrity)**: bind each `request_id` to a **server-computed** intent fingerprint so same-id+same-intent replays, same-id+different-intent conflicts. No change to action/adapter/registry/FE/ledger-terminal-ownership.

## 3. LIVE STATE
- **migration:** `20260815101138` (`v128_b6_3_p3_intent_integrity`) — D92 3-block, VERIFY fail-closed PASS, `NOTIFY pgrst`.
- **public inventory:** tables 92 · functions 248 · secdef 236 · **policies 167** · triggers 33 · cron 1.
- **mc_internal:** **3 fn / 3 secdef** (`_mc_lookup_action`, `_mc_commit_action`, **`_mc_begin_action`**).
- **ledger:** **14 columns** (+`intent_hash_version smallint`, +`intent_fingerprint text`) + pair-integrity CHECK; 12 legacy rows fingerprint NULL (no backfill); authenticated **SELECT-only**; policy `select_own` only.

## 4. DELIVERED
- **Server-computed intent fingerprint** (SHA-256 hex, version 1) via `extensions.digest`, from **parsed typed values** post-validation.
- **`mc_internal._mc_begin_action`** (DEFINER) — sole processing-writer; derives actor + computes fingerprint **internally**; atomic INSERT ON CONFLICT DO NOTHING.
- **Replay fingerprint comparison** in execute: legacy NULL / version≠1 / fingerprint-mismatch → `MC_ACTION_REQUEST_CONFLICT`; equal → in-progress/cached (reuses existing code, no new public error).
- **Option-C forge closure:** authenticated ledger INSERT **REVOKED**, `insert_own_processing` **DROPPED**; both write boundaries DEFINER-owned (begin + commit); authenticated SELECT-only.
- Additive 2 columns + pair CHECK; **legacy fail-closed, no backfill**.
- PRE/POST **P3-E1–E12 + regression** equivalence proof.

## 5. CURRENT EXECUTION PIPELINE
```
auth → profile → registry lookup → action verdict → object/request null
→ context validation → input validation → object lookup → context/object match
→ mc_internal._mc_begin_action(typed values)  [DEFINER: derive actor + compute fingerprint + atomic INSERT]
    fresh  → static adapter CASE (class.assign.v1 → assign_class_distribution) → _mc_commit_action
    exists → replay: not-found/triple-mismatch/legacy-NULL/version≠1/fingerprint-mismatch → REQUEST_CONFLICT
             ; equal + processing → REQUEST_IN_PROGRESS ; equal + completed → cached replay
```

## 6. FROZEN / UNCHANGED (md5 proven)
`get_mission_control_actions` `3596633c6f7f1b7ecdc81822691475d4` · `_mc_lookup_action` `5d940037687be0a398a232cf987bfcf6` · `get_available_actions` `fd874243a90e20d171058f3ddb648356` · **`_mc_commit_action` `ce36c5fe109e99a919158a4482940c6a`** (terminal ownership untouched) · `assign_class_distribution` `03a1510bd827c03a650a3a88312fbe3a` · registry rows/schema · FE (pin `2.8.5`).
**Changed:** execute `cf446902…` → **`7a526354c820ab5f767ee7403c6e917d`** (INVOKER, sig BẤT BIẾN) · new `_mc_begin_action` **`f47260ef3f06811ac2e83807989b26c7`** (DEFINER, owner postgres, `search_path=''`).

## 7. EQUIVALENCE (PRE vs POST)
**Allowed intentional delta (only one):** same request_id + same structural triple + **different semantic intent** → `MC_ACTION_REQUEST_CONFLICT` (PRE incorrectly returned `replayed:true` cached result). Everything else preserved.

| Case | Result |
|---|---|
| P3-E1 identical intent | replayed:true, same dist ✓ |
| P3-E2 diff program | REQUEST_CONFLICT ✓ |
| P3-E3 diff teacher | REQUEST_CONFLICT ✓ |
| P3-E5 key order | replay (fingerprint from parsed values) ✓ |
| P3-E6 absent/null/"" | same fingerprint → replay ✓ |
| P3-E7 UUID uppercase | same fingerprint → replay ✓ |
| P3-E8 race | same→IN_PROGRESS, diff→CONFLICT ✓ |
| P3-E9 legacy NULL | REQUEST_CONFLICT (fail-closed) ✓ |
| P3-E10a direct INSERT | denied ✓ |
| P3-E10b helper introspection | actor=caller-derived, fp server-computed ✓ |
| P3-E11 completed cached | exact stored result ✓ |
| P3-E12 domain conflict | CONFLICT, orphan=0 ✓ |
| Regression R1–R10 | PERMISSION_DENIED / NOT_FOUND / CONTEXT/INPUT / OBJECT_NOT_FOUND / **E2b OBJECT_NOT_FOUND** / success / get_mc_actions byte-identical ✓ |

## 8. CANONICALIZATION RULES (fingerprint identity)
- UUID → `::uuid::text` canonical (case/lexical collapse).
- `lead_teacher_id` **absent ≡ null ≡ ""** → JSON `null` (proven live: Phase-2 accepts "" via `nullif(...,'')::uuid`).
- JSON key order irrelevant (fingerprint computed from parsed typed values, not raw text).
- Canonical intent: `{v:1, action_key, object_type, object_id, context:{school_id}, input:{program_id, lead_teacher_id}}` — **actor_id EXCLUDED** (ownership = actor_id column + `select_own` RLS).

## 9. FORGE CLOSURE (Option C)
`_mc_begin_action` (DEFINER) does NOT accept actor_id/intent_fingerprint/status/terminal args — derives `actor := current_profile()` and computes fingerprint internally. authenticated has **no INSERT/UPDATE/DELETE** on ledger (SELECT-only); all writes via DEFINER (`_mc_begin_action` begin, `_mc_commit_action` terminal). Direct-INSERT attempt → `insufficient_privilege` (verified). Legacy rows fingerprint NULL → non-replayable, fail-closed.

## 10. GAP DISPOSITION
G1 CLOSED · G2 CLOSED · **G3 CLOSED** · G4 CLOSED.

## 11. STRUCTURAL DELTA (Phase 3)
ledger **12 → 14 columns** (+2, +pair CHECK) · mc_internal **2/2 → 3/3** (+`_mc_begin_action`) · policies **168 → 167** (dropped `insert_own_processing`) · authenticated ledger grants **INSERT+SELECT → SELECT-only** · execute REPLACE (md5 change) · tables 92 / functions 248 / secdef 236 / triggers 33 unchanged · no index delta (3) · FE/Edge/Bunny 0. Migration tail `20260815085223` → **`20260815101138`**.

## 12. ROLLBACK
Restore execute → `cf446902587cd6d0dea9d578d645bf71` · DROP `mc_internal._mc_begin_action` · restore authenticated INSERT grant + recreate `insert_own_processing` policy · DROP columns `intent_hash_version`+`intent_fingerprint` + pair CHECK · re-harden execute ACL · keep `select_own` · NOTIFY pgrst. No ledger-data repair beyond dropping Phase-3 columns; historical rows preserved. Frozen objects need no repair.

## 13. NEXT GATE
**Owner closeout of B6.3 milestone.** No Phase 4 / no new action / no generic engine authorized. On-horizon (separate milestones): FMN lifecycle, `/kid` portal V2, Media Organization sprint.

**Canonical Endpoint:** RULES **D363** · SYSTEM_MAP **v1.51** · HANDOFF **V128-B6.3-PHASE-3** · backend tail `20260815101138` · FE main pin `2.8.5`. Khối D361/v1.49 (P1) & D362/v1.50 (P2) = HISTORICAL SNAPSHOTS (BẤT BIẾN).
