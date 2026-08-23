# DMA V127-M3-P0A TECHNICAL IMPLEMENTATION DESIGN

> Audit-first, design-only package. No code, no migration, no DB change, no apply.
> Prepared by Claude (Technical Auditor / Architecture Reviewer). Owner decision authority: ChatGPT.

---

## 1. Executive Verdict

**Core finding confirmed by live audit:** `admin.lookup.tsx` is already a working Workspace Shell. It renders five of the six mission-control panels (Identity, Current State, Relationships, Issues, Activity). The only missing primitive is **Actions**. We extend — we do not rebuild.

**P0 action feasibility is a SPLIT verdict — this is the pivotal result of this audit:**

| P0 Action | Existing backend | Platform-admin callable from Mission Control? | P0A status |
|---|---|---|---|
| **Assign Class** | RPC `set_distribution_lead` | ✅ **YES** — auth gate has an `is_admin()` branch | **Buildable now, zero backend change** |
| **Activate Teacher** | Edge `invite_staff` | ❌ **NO** — hard-rejects platform admin (`not_authorized` / `caller_no_school` / `different_school`) | **BLOCKED under the "no new backend" constraint** |

**Why Assign Class is clean:** `set_distribution_lead`, the candidate reads (`class_distributions`, `classes`, `profiles`), and the teacher validator (`dma_assignable_teacher_reason`) all grant platform admins access via `is_admin()`. The picker can be populated with direct `.from()` reads — **no new read RPC** (honors Gate A). This maps exactly onto the VNDM pilot blocker: two ballet `class_distributions` with `NULL lead_teacher`.

**Why Activate Teacher is blocked:** `invite_staff` is school-master-scoped by design. It requires `caller.role ∈ {master_admin, sub_admin}`, a non-null `caller.school_id`, and `staff.school_id === caller.school_id`. A platform super-admin has none of these. There is **no platform-scoped staff-invite backend** (only `invite_master` exists, for masters). Shipping Activate Teacher from Mission Control would require a NEW edge function — which violates this milestone's hard constraint.

**Recommended path (★):** Ship **Assign Class only** in P0A. Render Activate Teacher as a *diagnosed, non-actionable Issue* with a clear operator instruction. Route the "new platform staff-invite backend" question to a separate Owner Gate (P0B). This delivers the real pilot value (binding real teachers to ballet distributions) with zero backend risk, and keeps a truthful boundary.

**The one decision this package needs from the Owner:** choose the Activate-Teacher disposition — **A★ defer + diagnose**, **B authorize a new platform edge fn now (breaks the no-backend constraint)**, or **C permanent handoff-to-Master framing**. Everything else is unblocked.

---

## 2. Live Frontend Audit

Re-pinned read-only against Lovable at the true main tip.

- **HEAD:** `6b860338125a63e8b74815d549db5be723ad732a` (= `6b860338`) — confirmed via `list_edits` (authoritative lineage). Matches canonical baseline **RULES D344 · SYSTEM_MAP v1.32**.
- **Admin routing:** file-based under `src/routes/_authenticated/`. The lookup route is `admin.lookup.tsx` → `createFileRoute("/_authenticated/admin/lookup")`. Shell is `admin.tsx` (`createFileRoute("/_authenticated/admin")`), a sidebar + `<Outlet/>` layout on the slate Mission Control theme. Sidebar already exposes **"Tra cứu" → `/admin/lookup`**.
- **Lookup implementation:** single file, ~750 lines. Debounced (350 ms) search → `admin_lookup_search`. Four entity panels: `UserPanel`, `ChildPanel`, `MediaPanel`, `CapsulePanel`.
- **Read RPCs already wired (no new ones needed for read):** `admin_lookup_search`, `admin_lookup_user`, `admin_lookup_child`, `admin_lookup_media`, `admin_lookup_capsule`.
- **RPC access pattern:** local thin wrapper `rpc<T>(name, params)` over `supabase.rpc`; a `useRpcOnce(name, params, depKey)` hook implements fetch-once-per-selection with `{data, loading, error}`.
- **Presentation layer** (`adminLookupPresentation.ts`): pure, null-safe label registries (`roleLabel`, `stateLabel`, `consentTypeLabel`, `evidenceClassLabel`, …), readiness builders (`buildReadinessSummary`, `buildReadinessMatrix`), and time/audit helpers (`fmtDateTime`, `fmtTime`, `groupAuditTimeline`). No UI coupling — fully reusable.
- **Audit taxonomy** (`auditTaxonomy.ts`): category/action label registries, tone map, and integrity-preserving headline/actor helpers. Re-exports from the presentation layer.

**Mutation surfaces audited elsewhere (source of the existing action RPCs):**
- `school.manage.tsx` → `TeachersTab` calls Edge `invite_staff`; `ClassSubjectsPanel` calls RPC `assign_class_distribution` (create) and `set_distribution_lead` (update lead).
- `admin.school-onboarding.tsx` → RPC `onboard_school`, RPC `list_masters_without_login`, Edge `invite_master` (platform-scoped precedent).

---

## 3. Current Lookup Architecture

The lookup already *is* the workspace grammar. Mapping the live `UserPanel` to the six primitives:

| Current live element (in `admin.lookup.tsx`) | Workspace primitive | Notes |
|---|---|---|
| `PanelHeader` + chips (role, state, has-login, school) | **Identity** | Uses initials-friendly header; no avatar (Gate C already satisfied). |
| state/has-login chips + `Group "Chẩn đoán nhanh"` (`Check` rows) | **Current State** | State is read-only today. |
| `Group "Gia đình"` (children/parents), `Group "Giảng dạy"` (counters), `Group "Lớp / Trường"` | **Relationships** | |
| `Group "Chẩn đoán nhanh"` (`Check` list) | **Issues** | Informational only — **not yet actionable**. |
| `Group "Hoạt động gần đây"` (`TimelineView`) + link to `/admin/audit-log` | **Activity** | |
| — | **Actions** | **ABSENT — the entire P0 delta.** |

**Reusable primitives already defined inline** (extraction candidates): `PanelHeader`, `SectionHeading`, `Group` (tone `default|warn`), `Chip` (tone `default|good|warn|bad`), `Check`, `Field`, `StatTile`, `TimelineView`, `TechDetails`, `RawJson`, `Accordion`, `ConsentTable`, `Skel`, `ErrorBox`, plus the `useRpcOnce` hook.

**Extraction table (Current → Purpose → Move To → Reason):**

| Current component | Purpose | Move to | Reason |
|---|---|---|---|
| `Group`, `SectionHeading`, `Chip`, `Field`, `Check`, `StatTile` | Layout/label atoms | `features/admin/workspace/primitives/` | Shared by every panel; zero logic. |
| `PanelHeader` | Identity header | `features/admin/workspace/IdentityPanel` | Becomes the Identity primitive. |
| `TimelineView` | Activity render | `features/admin/workspace/ActivityPanel` | Pure over `AuditEvent[]`. |
| `useRpcOnce`, `rpc` | Fetch-once + RPC wrapper | `features/admin/workspace/useWorkspaceResource.ts` | Reused by every panel + the action layer. |
| `ErrorBox`, `Skel` | Loading/error states | `features/admin/workspace/primitives/` | Needed by empty/loading/failure states. |
| `TechDetails`, `RawJson`, `Accordion` | Diagnostics | `features/admin/workspace/diagnostics/` | Keep verbatim; no behavior change. |

> **Risk note (informs §10):** these primitives live inside a 750-line working file that is central to live ops. Physically ripping them out is the largest blast-radius step. See §10 for the recommended phasing that defers this.

---

## 4. Workspace Primitive Extraction Plan

Target namespace: `src/features/admin/workspace/`. Six primitives, each a thin presentational shell fed by already-available data.

| Primitive | Responsibility | Data / props (shape, not code) | Dependencies | Reuse scope |
|---|---|---|---|---|
| `WorkspaceShell` | Compose the panel stack for a selected entity; own no fetching itself | `{ entity: WorkspaceEntity }` | all panels | Any entity (teacher first) |
| `IdentityPanel` | Name + initials + role/state/school chips | `{ identity, chips }` | `PanelHeader`, `Chip` | All entities |
| `StatePanel` | Operational state at a glance (active / has-login / assignable) | `{ state: OperationalState }` | `Chip`, `Check` | All entities |
| `RelationshipPanel` | School, class distributions, teaching counters | `{ relationships }` | `Group`, `Field`, `Chip` | All entities |
| `IssuePanel` | Render `Issue[]` with severity + recommended action hook | `{ issues, onAction }` | `Group`, `Check` | All entities |
| `ActionPanel` | Render `AvailableAction[]`; own confirm + call + result + refresh | `{ actions, onDone }` | `Group`, `Button`, `Dialog` | **New — the P0 delta** |
| `ActivityPanel` | Grouped audit timeline + deep link | `{ events }` | `TimelineView` | All entities |

Gate B is honored: all of this mounts **inside the existing lookup panel area** — **no `/admin/workspace` route is created**.

---

## 5. Teacher Workspace State Model

Frontend-only UI state. Derived from data already returned by `admin_lookup_user` plus small admin-readable `.from()` reads (all `is_admin()`-permitted; no new read RPC).

**Shape (design schema — descriptive, not implementation):**

```
TeacherEntity
├─ identity        : { profileId, fullName, email, phone, initials }
├─ operationalState: { role, state('active'|…), hasLogin(bool), schoolId, schoolName }
├─ relationships   : { classDistributions: [{ id, className, programName, leadTeacherId, state }],
│                        teachingCounters: { leadDistributions, sessionTeacherRows } }
├─ issues          : Issue[]            // derived (see §7)
├─ availableActions: AvailableAction[]  // derived from state+issues (see §6)
└─ activity        : AuditEvent[]       // recent_audit from admin_lookup_user
```

**Data-flow (Search → Selection → Workspace State → Action Availability):**

```
admin_lookup_search (q)                → result groups (existing)
        ↓ admin clicks a "Người dùng" row of role teacher
useWorkspaceResource("admin_lookup_user", { profile_id })  → identity, counters, recent_audit
        ↓ (Assign-Class only) supplemental admin reads, is_admin()-gated:
   .from('classes').select(id,name).eq('school_id', schoolId)
   .from('class_distributions').select(id,program_id,lead_teacher_id,state,programs(name)).eq('class_id', …).eq('state','active')
   .from('profiles').select(id,full_name,email,role,state).eq('school_id', schoolId).in('role', assignableRoles)
        ↓ derive
   OperationalState  → StatePanel
   Issue[]           → IssuePanel
   AvailableAction[] → ActionPanel   // visibility computed here; authority stays server-side
```

**Availability rule (frontend gating is convenience only, never authority):**
- `Assign Class` visible when: entity is a teacher **and** at least one active `class_distribution` exists in the teacher's school. Enabled when `dma_assignable_teacher_reason` (surfaced from the server on attempt, or precomputed read-side) returns null.
- `Activate Teacher` visible when: `hasLogin === false`. **Enabled state depends on the Owner's §11 decision** (A★: rendered but non-actionable with explanation; B: actionable once a platform backend exists).

---

## 6. Action Panel Design

> Hard rule honored: **no new backend functions.** Only the two existing surfaces below.

### 6.1 Assign Class  — RPC `set_distribution_lead`  ✅ P0A

- **When visible:** teacher entity + ≥1 active `class_distribution` in the teacher's school.
- **Prerequisite:** a target `class_distribution` is chosen (picker) and the teacher passes `dma_assignable_teacher_reason` (null). Note: assignability does **not** require the teacher to have a login — an un-activated teacher can be set as lead. (Operationally they still can't teach until activated — see the paired Issue in §7.)
- **Confirmation:** explicit confirm dialog naming the class, program, and the from→to lead. Mutating action → confirm required (irreversible-control discipline).
- **RPC boundary:** `set_distribution_lead(p_class_distribution_id, p_lead_teacher_id)`. Returns JSONB: `{ ok:true, lead_teacher_id }` or `{ ok:true, already:true }` or `{ ok:false, reason }`.
- **Reason → human copy (UI must translate):** `not_authenticated`, `distribution_not_found`, `distribution_orphaned`, `distribution_not_active`, `not_authorized_for_school`, `lead_teacher_invalid`.
- **Success handling:** toast; optimistic-safe re-read of the teacher's distributions + counters.
- **Audit refresh:** the RPC writes `distribution_lead_changed`; after success, re-fetch `admin_lookup_user` so `ActivityPanel` shows the new event.

### 6.2 Activate Teacher  — Edge `invite_staff`  ❌ blocked at platform scope

- **When visible:** `hasLogin === false`.
- **Backend reality:** `invite_staff` enforces caller ∈ {master_admin, sub_admin} + same-school. A Mission Control platform admin is rejected (`not_authorized` / `caller_no_school` / `different_school`). **No platform-scoped staff-invite backend exists.**
- **P0A disposition (A★):** render as a **non-actionable diagnosed Issue**, not a live button — copy: "Giáo viên chưa có tài khoản đăng nhập. Việc cấp login do **Chủ trường** thực hiện trong Cổng Trường (Quản lý → Giáo viên → Mời đăng nhập). Mission Control chưa có đường cấp login xuyên trường." This keeps the boundary truthful and avoids a button that can only fail.
- **If Owner picks B:** a new platform-scoped edge fn (e.g. `admin_invite_staff`, mirroring `invite_master`'s gate) is required — a separate backend Owner Gate, out of P0A scope.

---

## 7. Issue Model

Frontend-only concept (no DB schema). An `Issue` interprets already-available state into an operator-legible problem with a severity and a recommended action.

```
Issue { code, severity('blocking'|'attention'|'info'), title, explanation, recommendedAction? }
```

For the Teacher Workspace, three orthogonal issue sources:

| Issue code | Severity | Explanation (source) | Recommended action |
|---|---|---|---|
| `teacher_not_activated` | attention | `hasLogin === false` | Activate Teacher — **A★: instruction only** (see §6.2) |
| `teacher_unassigned` | attention | teacher is lead of 0 active distributions (counter `leadDistributions === 0`) | **Assign Class** (actionable ✅) |
| `teacher_not_assignable` | blocking (for assign) | `dma_assignable_teacher_reason` ≠ null → one of `school_unresolved / profile_not_found / cross_school / inactive / role_not_assignable` | resolve upstream (fix role/state/school); disables Assign Class |

Design intent: **Issue → Recommended Action** is the connective tissue that turns the existing (informational) "Chẩn đoán nhanh" block into an actionable surface — this is the smallest possible bridge from today's shell to a workspace. `teacher_not_activated` and `teacher_unassigned` are independent; both can be present at once.

---

## 8. UX Flow

```
Admin searches teacher  (existing debounced search)
        ↓
Selects teacher row     (existing ResultsPanel → onOpen 'user')
        ↓
Identity appears        (existing PanelHeader + chips)
        ↓
State + Issues derived  (StatePanel + IssuePanel)
        ↓
Action available        (ActionPanel: Assign Class enabled; Activate = instruction)
        ↓
Confirm                 (dialog names class/program/lead change)
        ↓
Mutation                (set_distribution_lead)
        ↓
Audit timeline updated  (re-fetch admin_lookup_user → ActivityPanel)
```

**State coverage:**
- **Empty:** teacher has no school / no distributions → ActionPanel shows a calm "no assignable class yet" note, not a dead button.
- **Loading:** reuse `Skel` for panel bodies; action buttons disabled while a mutation is in flight.
- **Failure:** reuse `ErrorBox`; map every `reason` to human copy (§6.1); never surface a raw reason string.
- **Success:** toast + targeted re-fetch; the changed lead is reflected in Relationships and a new event appears in Activity.

---

## 9. Security Review

**Privacy boundary — unchanged.** The Teacher Workspace shows only operational data already exposed by `admin_lookup_user`:

- ✅ Allowed: identity, role, school, class/assignment, operational status (login/active), audit.
- ❌ Never: child memories, media content, family data. (No child/media/capsule reads are added by P0A.)

**Authority — server remains the sole gate.**
- Frontend action visibility is convenience only. Every mutation re-checks on the server: `set_distribution_lead` enforces `is_admin() OR (master/sub + own school)` and re-runs `dma_assignable_teacher_reason`. A spoofed/enabled button cannot bypass it.
- Reads for the picker are RLS-gated by `class_distributions_select_admin` / `classes_select_admin` / `profiles_select_admin`, all `is_admin()`. No cross-school leakage for non-admins.
- Activate Teacher's block is itself a security property: `invite_staff` correctly refuses cross-school login minting. P0A does **not** attempt to weaken it.

**No RLS change, no policy redesign, no new grants.** All paths use existing `SECURITY DEFINER` RPCs / existing RLS-permitted selects.

---

## 10. Implementation Sequence

Design-only here; this is the plan for a later build session (paste-mode per Gate E — byte-exact blocks for Jean, no autonomous agent apply).

**Recommended phasing (★ minimizes blast radius; honors "extend, don't rebuild"):**

- **Step 1 — ActionPanel as a new sibling, in place.** Add `ActionPanel` + a small `useWorkspaceActions` next to `UserPanel` inside `admin.lookup.tsx`, reusing the existing inline `Group/Chip/Button/Dialog`. **Do not extract primitives yet.** Lowest risk.
- **Step 2 — Wire Teacher read state.** From the selected user, derive `OperationalState` + `Issue[]`; add the three `is_admin()`-gated `.from()` reads for classes/distributions/candidate teachers. No new RPC.
- **Step 3 — Render Issues as actionable.** Turn "Chẩn đoán nhanh" into `IssuePanel` with recommended-action hooks (`teacher_unassigned`, `teacher_not_activated`, `teacher_not_assignable`).
- **Step 4 — Connect Assign Class.** Confirm dialog → `set_distribution_lead` → reason mapping → success re-fetch → audit refresh. ✅ ships the pilot value.
- **Step 5 — Activate Teacher disposition.** Per Owner §11 decision (A★ instruction-only Issue by default).
- **Step 6 — QA.** VNDM dry-run: assign a real teacher to each of the two NULL-lead ballet distributions; verify `distribution_lead_changed` in Activity; verify non-admin cannot see cross-school picker; verify all reason-code copies.
- **Step 7 (optional, later) — Physical extraction** of primitives to `features/admin/workspace/` once ActionPanel is proven. Deferred precisely because the 750-line file is live-ops critical.

---

## 11. Owner Approval Gates

Confirmed decisions already honored: **A** (no new read RPC — verified: picker uses `is_admin()` `.from()` reads), **B** (panel-first, no workspace route), **C** (initials, no avatar), **D** (assign-school folds into teacher provisioning; moot for existing teachers since `school_id` is set at profile creation), **E** (paste mode, no autonomous apply).

**Decision required — Activate Teacher disposition (the only open item):**

- **★ Option A — Defer + diagnose (recommended).** P0A ships **Assign Class only**. Activate Teacher becomes a non-actionable Issue with an operator instruction pointing to the school Master's own invite flow. Zero backend change. Delivers the VNDM pilot blocker resolution.
- **Option B — Authorize a new platform edge fn now.** Create `admin_invite_staff` (mirror `invite_master`'s platform gate). Delivers a live Activate button in Mission Control, but **breaks the P0A "no new backend" constraint** — it becomes a separate migration/edge Owner Gate, not P0A.
- **Option C — Permanent handoff framing.** Activate Teacher is by-design a Master responsibility; Mission Control never mints staff logins. Simplest boundary; no backend ever added for this.

**Secondary confirmations (default = as written):**
1. Assign-Class picker shape — **teacher-centric** (search teacher → pick which class distribution they lead). Confirm vs distribution-centric.
2. Whether `teacher_not_activated` copy should link out to the Cổng Trường path explicitly (A★ assumes yes).

**No engineering blockers remain for Assign Class.** On the Owner's §11 choice, the build session can proceed in paste-mode per the Step 1–6 sequence.
