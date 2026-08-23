# V128-B7 CTO DECISION GATE RESULT

> **Mode:** REVIEW/AUTHORIZATION ONLY. No SQL · no migration · no DB mutation · no FE · no canonical append. No implementation.
> **Basis:** Phase-2 Design Report read directly (`DMA_V128_B7_PHASE_2_DECISION_FOUNDATION_DESIGN_REPORT.md`), not reconstructed.

---

## 1 · Canonical basis

- **Endpoint:** RULES **D363** · SYSTEM_MAP **v1.51** · HANDOFF **V128-B6.3-PHASE-3-CLOSEOUT**.
- **Live runtime:** migration tail `20260815101138`; G1/G2/G3/G4 CLOSED; inventory 92·248·236·167·33·1; `mc_internal` 3/3. Zero drift (re-pinned this session).
- **B7 progression:** Phase-1 audit CLOSED (Q1–Q6 approved); Phase-2 Decision Foundation Design under review here.
- **Substrate:** greenfield — no Mission Control decision object exists (verified three sweeps). `mission_control_decisions` introduces no collision.

## 2 · Decision table

| Gate | Decision | Rationale |
|---|---|---|
| **G-A — Fingerprint uniqueness** | **APPROVE** — `intent_fingerprint` NOT NULL + UNIQUE | Q3 is locked (1 fp = 1 decision); UNIQUE is its literal enforcement. Divergence from the ledger (which deliberately does *not* dedup fp, D363.5) is *correct*: the ledger records execution **attempts** (per request_id), a decision records a governance **verdict** on an intent. Governance attaches to the intent, not each attempt — two identical intents rightly share one verdict. **Refinement:** pair UNIQUE with NOT NULL (a forged HIGH/CRITICAL intent always carries a fp; NULL fp must never enter the decision table, and Postgres UNIQUE permits multiple NULLs). |
| **G-B — Approver eligibility** | **APPROVE** — role ∈ {`master_admin`,`sub_admin`} AND same `school_id` AND approver ≠ requester | Grounded in live schema (`classes.school_id`, `profiles.school_id`, `is_school_admin() = current_profile_role() in ('master_admin','sub_admin')`). Reuses the platform's own authority definition; consistent with Q6 + D48 privacy moat. Teachers (`lead_teacher`/`assistant_teacher`) request but never approve. **Scope note:** eligibility is enforced in the `_mc_resolve_decision` helper = **Phase B**, not Phase A. |
| **G-C — Park vs ledger state** | **APPROVE** — keep ledger unchanged; decision state takes precedence in gate/replay; no `awaiting_decision` ledger status | Preserves the G4 ledger invariant (no schema change to the sealed ledger). The decision table is the single source of truth for "why parked." **Scope note:** enforced at execute integration = **Phase C**, not Phase A. |
| **G-D — Expiry** | **APPROVE** — lazy-expire-on-read + optional cron sweep | TTL handles deadlock without a mandatory scheduler; lazy transition covers the common path, cron is housekeeping only. **Scope note:** `_mc_expire_decisions` helper = **Phase B**. |
| **G-E — Cancel authority** | **MODIFY** — cancel = requester (self) **OR school authority** (`master_admin`/`sub_admin`, same school). **Remove platform-admin silent cancel.** | A class-scoped decision is a **school-domain governance artifact**. Allowing a platform admin to cancel it lets the platform *silently override school governance* — a direct violation of the school-sovereignty / D48 privacy-moat principle. Stuck decisions are already handled by **expiry (G-D)**, not platform intervention, so platform cancel is not operationally necessary. Requester self-cancel = abandoning one's own request (not an override) → allowed. School authority cancel = legitimate in-domain oversight (a master clearing a mistaken request) → allowed (cancel ≠ approve, so the SoD ≠-requester constraint does not apply to cancel). Any platform-level intervention (legal/safety) must be an **explicit, audited, non-silent** mechanism — **deferred out of v1 scope**. **Scope note:** `_mc_cancel_decision` helper = **Phase B**; the table's `state` CHECK still includes `cancelled` regardless of *who* cancels, so this modification does not alter the Phase-A table. |

**Net:** G-A ✅ · G-B ✅ · G-C ✅ · G-D ✅ · G-E ✅ (modified). All gates resolved; none rejected. The G-E modification lands entirely in Phase-B helper design and does **not** change the Phase-A table.

## 3 · Phase A authorization

**AUTHORIZED.**

Phase A = **Decision Foundation Table (Dormant Only)**. All five gates are resolved (G-E modified, not rejected), and none of the resolutions block the table itself. Phase A is a purely additive, dormant, zero-runtime-effect change.

## 4 · Constraints

### Phase A MAY change (table + boundary only)
- Create the `mission_control_decisions` table with the Phase-2 column set (14 columns as designed).
- Constraints: `intent_fingerprint` **NOT NULL + UNIQUE** (G-A); `state` CHECK ∈ {pending, approved, rejected, expired, cancelled}; `risk_level` CHECK ∈ {LOW, MEDIUM, HIGH, CRITICAL}; FK `action_request_id` → `mission_control_action_requests(request_id)`.
- Indexes: (`state`,`expires_at`) and (`object_type`,`object_id`) as designed.
- **Read boundary only:** RLS enabled + a single `…_select_own` SELECT policy (requester reads own rows, mirroring `mission_control_action_requests_select_own`) + `authenticated` **SELECT-only** grant.
- Apply D92 3-block discipline (DDL → REVOKE/GRANT → VERIFY) and `NOTIFY pgrst` when the build phase is later executed under its own authorization.

### Phase A MUST NOT touch
- **No DEFINER helpers** — `_mc_open_decision`, `_mc_resolve_decision`, `_mc_cancel_decision`, `_mc_expire_decisions`, and the approver-inbox read RPC are **Phase B**, not authorized here.
- **No execute integration** — `execute_mission_control_action` body unchanged (INVOKER, md5 `7a526354…` frozen). Phase C.
- **No risk enforcement / no gate** — no tier→approval wiring; risk_level stays metadata.
- **No ledger change** — `mission_control_action_requests` schema, grants, policies untouched (G4 sealed).
- **No adapter change** — `assign_class_distribution` frozen (md5 `03a1510b…`).
- **No registry change** — `mission_control_action_registry` and `mission_control_object_registry` untouched.
- **No FE change** — pin `2.8.5` unchanged.
- **No canonical append** — RULES/SYSTEM_MAP/HANDOFF unchanged until the Phase-D closeout under separate authorization.
- **No client mutation surface** — `authenticated` gets SELECT only; no INSERT/UPDATE/DELETE grant or policy.

## 5 · Stop conditions

- This is an **authorization gate only.** No migration written · no SQL designed · no implementation performed in this turn.
- Phase A implementation, when it proceeds, is **table + read boundary only** — the moment any helper, execute wiring, or risk enforcement is touched, that is **out of Phase A** and requires its own gate (Phase B / Phase C).
- The **dormancy invariant** must hold post-Phase-A: the only live dispatchable action (`class.assign`, MEDIUM) remains on the auto path; the table governs nothing live (no gate exists yet). If any live behavior changes, STOP.
- Any drift from the pinned endpoint (RULES D363 / v1.51 / tail `20260815101138`) discovered at Phase-A build time → STOP and re-audit before applying.

---

## STATUS

**PHASE A — AUTHORIZED (table + read boundary, dormant only).**
G-A/G-B/G-C/G-D approved · G-E modified (school-owned cancel; no platform silent override). Helpers (Phase B), execute integration (Phase C), and canonicalization (Phase D) remain **NOT authorized**.

*Authorization is design-level; no SQL/migration produced. Endpoint at gate time: RULES **D363** · SYSTEM_MAP **v1.51** · backend tail `20260815101138` · FE pin `2.8.5`.*
