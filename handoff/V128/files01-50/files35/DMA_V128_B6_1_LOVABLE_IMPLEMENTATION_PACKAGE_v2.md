# DMA V128-B6.1 — LOVABLE IMPLEMENTATION PACKAGE (copy-ready) — **v2**

**Deliverable:** Production Class Workspace for Mission Control (read/projection + single `class.assign` action).
**Canonical authority:** `D359 / SYSTEM_MAP v1.47 / HANDOFF V128-B6.0.1`.
**Verdict source:** V128-B6.1 STEP 1 Engineering Implementation Plan → **READY FOR LOVABLE**.
**This package operationalizes STEP 1 with zero architecture changes.** If any instruction here appears to contradict STEP 1 architecture, STEP 1 wins and Lovable must STOP and report to Claude.

> **v2 supersedes v1. v1 is void — do not send v1 to Lovable.**

### v2 changelog (corrections vs v1)
1. Workspace RPC corrected: `get_object_workspace` → **`get_mission_control_workspace`** everywhere in production instructions.
2. Memory RPC **pinned** to `get_mission_control_memory` (no longer an unknown gap).
3. `get_object_workspace` added to **forbidden** production calls (alongside `_mission_control_workspace_core`).
4. Static audit adds a **zero-`get_object_workspace`** check on the new feature/routes.
5. Parser contradiction resolved: *additive-unknown* fields are stripped; *required/semantic/schema/control* violations fail closed (§2.2).
6. Memory `p_limit` bounded: **default/initial 50, hard ceiling 100** (§2, §2.5).
7. All other STEP 1 architecture and operating rules unchanged.

---

## 0. Baseline & scope (read-only header — do not modify)

| Anchor | Value |
|---|---|
| Repo | `demenart` · branch `main` |
| Baseline HEAD | `f6630bd0fd0517864a16128e63f1a3035bad5595` |
| Parent | `be04f4b486e277a260c594740d93cfd008d523db` |
| Working tree | clean |
| Generated types SHA-256 | `635eec14a708208c68b8d6cbff4803f9140e557d77e862116fb9ae7056a64dee` |

**Scope = B6.1 production frontend ONLY.** In scope: the `/admin/mission-control/class/$id` production workspace, Open Class by UUID, the five-band renderer, the `class.assign` action drawer, and the four typed adapter operations over existing authenticated RPCs.

**Absolutely out of scope — Lovable may NOT touch:**
- Backend / SQL / migrations / RPC bodies / permissions / ACLs.
- Generated `src/integrations/supabase/types.ts` (already committed at the SHA above).
- `routeTree.gen.ts` by hand (tooling regenerates it).
- Legacy demo isolation: `objectWorkspaceModel.ts`, `ObjectWorkspace.tsx`, `HealthBand`, `HistoryBand`, `fixtures/demoObjects.ts`, and the `/admin/object/$type/$id` demo route.
- Any other portal (`/school`, `/teacher`, `/parent`, `/kid`), global admin nav, auth, or RLS.

**Terminal action for Lovable:** build → self-verify → **submit diff to Claude. DO NOT merge. DO NOT deploy.** Owner QA precedes any merge.

---

## 1. Global hard constraints (fail-closed — every one is a review gate)

Forbidden anywhere under `src/features/mission-control/**` (and the two route files):

- ❌ A component importing the Supabase client.
- ❌ Any component **or hook** calling `.from(...)`.
- ❌ Direct call to `assign_class_distribution` (legacy low-level mutation).
- ❌ Direct call to **`get_object_workspace`** (legacy workspace wrapper — superseded). Production workspace reads use **`get_mission_control_workspace`** only.
- ❌ Direct call to `_mission_control_workspace_core` (internal-only; authenticated direct call → `42501`).
- ❌ Service-role key, secret key, or any non-publishable credential.
- ❌ Any front-end permission or tenant/membership resolution.
- ❌ UI-generated program or teacher options (options come only from the Actions DTO).
- ❌ Raw RPC payload (`Json`) passed into any renderer.
- ❌ Displaying raw backend errors, PostgREST text, SQL text, or JSON dumps.
- ❌ Inventing, aliasing, or renaming an RPC identifier or parameter.
- ❌ Importing anything from `fixtures/` into production code.

Required posture:
- ✅ Only `adapters/missionControlAdapter.ts` imports `supabase`.
- ✅ Only `execute_mission_control_action` performs mutation.
- ✅ Every raw RPC response crosses a strict runtime parser before reaching a model/renderer.
- ✅ Malformed / semantic-invalid / unsupported-schema envelopes fail closed (§2.2).
- ✅ UI copy is Vietnamese (DMA UX-writing register); no raw technical strings.

---

## 2. RPC contract (exact — B6.0.1 surface, pinned)

The adapter exposes **four** operations, bound to the exact generated declarations in
`src/integrations/supabase/types.ts → Database['public']['Functions']`.
**If a name/param below differs from the generated declaration, the generated declaration wins — STOP and report to Claude. Do not guess or rename.**

| Operation | RPC | Params (client-supplied) | Notes |
|---|---|---|---|
| Workspace read | **`get_mission_control_workspace`** | `p_object_type='class'`, `p_object_id=<uuid>` | Client does **not** supply `p_context`. |
| Actions | **`get_mission_control_actions`** | `p_object_type='class'`, `p_object_id=<uuid>` | Returns executable actions for the object. |
| Memory | **`get_mission_control_memory`** | `p_object_type='class'`, `p_object_id=<uuid>`, `p_limit` (**default 50, ≤100**), `p_before` (optional cursor) | `p_before` = returned `next_cursor` unchanged. |
| Execution | **`execute_mission_control_action`** | `p_action_key`, `p_object_id`, `p_context`, `p_input`, `p_request_id` | Sole mutation boundary. |

`get_object_workspace` and `_mission_control_workspace_core` are **not** part of the production surface and must not appear in B6.1 code (§1, §5).

### 2.1 DTO shapes (raw envelopes — parse, never cast)

**Workspace success** — returned by `get_mission_control_workspace`
```ts
{
  ok: true;
  object: { type: "class"; id: string; label: string; status?: string };
  context: Array<{ key: string; label: string; value: string }>;
  state:   Array<{ key: string; label: string; value: string }>;
  capabilities: { actions: boolean; memory: boolean };
}
```

**Actions success** — returned by `get_mission_control_actions`
```ts
{
  ok: true;
  items: Array<{
    key: "class.assign";
    label: string;
    description?: string;
    risk_level: "LOW" | "MEDIUM" | "HIGH";
    input_schema: {
      version: "MissionActionInputSchema/v1";
      fields: Array<{
        key: string;
        label: string;
        value_type: "uuid" | "string" | "boolean" | "number";
        control: "select" | "text" | "checkbox" | "number";
        required: boolean;
        nullable?: boolean;
        options?: Array<{ value: string; label: string }>;
      }>;
    };
  }>;
}
```
For B6.1 the parser accepts **only `class.assign`** as executable and **only schema version `MissionActionInputSchema/v1`**. Any other action/schema/control is retained as an *unsupported presentation state* or rejected fail-closed — never executed opportunistically.

**Memory success** — returned by `get_mission_control_memory`
```ts
{
  ok: true;
  items: Array<{
    id: string;
    actor: { id: string; name: string } | null;
    summary: string;
    kind: string;
    outcome: "success" | "failed" | "unknown";
    timestamp: string; // ISO
  }>;
  next_cursor: string | null;
}
```

**Execution** — returned by `execute_mission_control_action`, parsed to a discriminated result:
```
success            (replayed=false)
replayed success   (replayed=true)
known business failure
transport/contract uncertainty
```

### 2.2 Parser rules (`parseMissionControlDtos.ts`) — two disjoint tolerance rules

**A. Additive tolerance (forward-compatibility).**
Unknown **additive** fields on an otherwise valid envelope are **stripped** so they cannot reach the UI. The mere presence of extra/unknown fields does **not** fail the parse.

**B. Fail-closed integrity.**
The parse **fails closed** when any of the following holds:
- a **required** field is missing or malformed;
- a value violates its declared **semantics** — invalid UUID, invalid ISO timestamp, out-of-enum value, or a **duplicate** `context` / `state` / `field` key;
- the action **schema version** is not `MissionActionInputSchema/v1`;
- an action **control/value_type combination** is unsupported.

Consequences of a fail-closed result:
- Workspace fail-closed → **contract/compatibility error** page state (not "empty workspace"). Missing identity on an `ok:true` workspace is a contract failure.
- Action fail-closed → execution **disabled** for that action (unsupported presentation state); never executed opportunistically.

General:
- Never cast raw `Json` directly to a DTO.
- Convert known `MC_*` failures to an allowlisted UI category set; preserve raw errors for internal diagnostics only — never display them.

### 2.3 Execution context (immutable)

The **workspace parser** converts validated `context[]` into an internal immutable execution-context record. For `class.assign` it must contain authoritative `school_id`. Components cannot create or edit `p_context`. The execution hook closes over the parsed snapshot and sends exactly:

```ts
{
  p_action_key: "class.assign",
  p_object_id: classId,
  p_context: authoritativeContext,   // from parsed workspace context — never caller-built
  p_input: validatedFormInput,
  p_request_id: submissionRequestId
}
```

### 2.4 Query keys (`missionControlQueryKeys.ts`)

```ts
["mission-control"]
["mission-control", "object", objectType, objectId]
["mission-control", "object", objectType, objectId, "workspace"]
["mission-control", "object", objectType, objectId, "actions"]
["mission-control", "object", objectType, objectId, "memory"]
```
`pageParam` is **not** added to the memory key manually; React Query manages pages under the object-scoped infinite query.

### 2.5 Query lifecycle

1. Validate route UUID (before any query is enabled).
2. Fetch workspace via `get_mission_control_workspace`.
3. Enable actions **only** when workspace succeeds and `capabilities.actions === true`.
4. Enable memory **only** when workspace succeeds and `capabilities.memory === true`.
5. Workspace failure controls the page state.
6. Actions/memory failure stays **band-local** — it must not discard a valid workspace.
7. Memory first page sends `p_limit = 50` (bounded; the hook must **never** send `p_limit > 100`). "Load more" sends `p_before = next_cursor` **unchanged** with the same bounded limit.
8. Pages stay in backend order; deduplicate by memory `id` only — **no client re-sort**.

### 2.6 Mutation & `request_id` lifecycle

1. User opens `class.assign`.
2. Form uses **only** backend-projected options.
3. First valid submit creates an **immutable submission** with `crypto.randomUUID()`.
4. Double-submit blocked while pending.
5. React Query automatic mutation retry **disabled**.
6. Transport-uncertain "Retry same request" reuses the **complete immutable submission and the same `request_id`**.
7. A new user intent (edit + submit again after a terminal result) gets a **new `request_id`**.
8. A replay response renders as **"Đã xử lý trước đó"** — not as a second assignment.

**Invalidation:**
- Success or replay → invalidate `workspace` + `actions` + `memory` for that **exact** class; await refetch before showing "fully refreshed".
- Known business failure → invalidate `memory` only if the response is terminal and auditable.
- Transport/parser failure → **no** speculative invalidation.
- A late mutation must never overwrite another class's UI state (invalidate only the object captured by that submission).

---

## 3. File manifest & structure

```
src/features/mission-control/
├── adapters/missionControlAdapter.ts          CREATE  — sole supabase import; 4 typed ops
├── actions/
│   ├── MissionActionDrawer.tsx                 CREATE  — desktop Sheet / mobile Drawer
│   ├── ClassAssignForm.tsx                     CREATE  — exact class.assign v1 form
│   └── ActionResult.tsx                        CREATE  — success/replay/failure/transport states
├── components/ClassWorkspaceScreen.tsx         CREATE  — coordinates queries/drawer; no RPC
├── contract/
│   ├── missionControlDtos.ts                   CREATE  — Zod raw-envelope schemas
│   ├── missionControlModels.ts                 CREATE  — stable renderer models + error categories
│   └── parseMissionControlDtos.ts              CREATE  — parse → validate → map to models
├── hooks/
│   ├── missionControlQueryKeys.ts              CREATE  — object-scoped key factory
│   ├── useMissionControlWorkspace.ts           CREATE  — workspace query
│   ├── useMissionControlActions.ts             CREATE  — actions query (capability-gated)
│   ├── useMissionControlMemory.ts              CREATE  — infinite memory (bounded p_limit + next_cursor)
│   └── useExecuteMissionControlAction.ts       CREATE  — mutation + request_id + replay + invalidation
├── renderer/
│   ├── MissionWorkspaceRenderer.tsx            CREATE  — fixed 5-band composition
│   └── bands/
│       ├── MissionIdentityBand.tsx             CREATE
│       ├── MissionContextBand.tsx              CREATE
│       ├── StateBand.tsx                        CREATE
│       ├── MissionActionsBand.tsx              CREATE
│       └── MemoryBand.tsx                       CREATE
└── shell/
    ├── MissionControlShell.tsx                 CHANGE  — remove demo nav + "chưa nối dữ liệu"; mount UUID open + outlet
    ├── ClassOpenForm.tsx                        CREATE  — UUID input + validation + navigation
    └── CommandBarPlaceholder.tsx                RETIRE  — delete ONLY after all imports removed

src/routes/_authenticated/
├── admin.mission-control.index.tsx             CHANGE  — landing + Open Class by UUID entry state
└── admin.mission-control.class.$id.tsx         CREATE  — thin route: read $id → ClassWorkspaceScreen

routeTree.gen.ts                                GENERATED — tooling only; never hand-edit
```

### Dependency direction (downward only)
```
route/component → React Query hook → adapter → authenticated RPC → strict parser → stable model → renderer
renderer/actions → models
hooks           → adapter + models + query keys
adapter         → supabase client + parsers
parsers         → DTO schemas + models
```

### State ownership
| State | Owner |
|---|---|
| Class UUID | Route URL |
| Workspace / actions / memory | React Query cache |
| Memory pagination cursor | Infinite-query `pageParam` |
| Drawer open / selected action | `ClassWorkspaceScreen` |
| Form draft + validation | React Hook Form in `ClassAssignForm` |
| Immutable execution submission | `useExecuteMissionControlAction` |
| Active `request_id` | Execution hook (retained through retries) |
| Result / replay state | Execution mutation result |
| Authorization | Backend/RPC only |

Changing the route UUID remounts/resets class-scoped UI state.

---

## 4. Build tasks (execute in order; each has an acceptance gate)

**Task 1 — Preflight gate**
Confirm generated `types.ts` is committed at the SHA above, tree clean, starting HEAD recorded. Make no generated-type edits.
*Accept:* baseline matches header; no type edits.

**Task 2 — Contract foundation**
Create `missionControlDtos.ts`, `missionControlModels.ts`, `parseMissionControlDtos.ts`. Pin `MissionActionInputSchema/v1`. Implement the two-rule parser (§2.2) and safe error normalization.
*Accept:* pure TypeScript; **no React and no Supabase imports** in these three files.

**Task 3 — Adapter boundary**
Implement the four operations in `missionControlAdapter.ts` bound to the exact B6.0.1 generated RPCs (§2): `get_mission_control_workspace`, `get_mission_control_actions`, `get_mission_control_memory`, `execute_mission_control_action`.
*Accept:* only Mission Control file importing `supabase`; no `get_object_workspace` / `_mission_control_workspace_core`; memory limit bounded (≤100, default 50).

**Task 4 — React Query layer**
Add `missionControlQueryKeys.ts` + the three read hooks; cursor-based infinite memory using `next_cursor`→`p_before` with the bounded limit (§2.4–2.5).
*Accept:* object-scoped keys; capability gating works; memory never requests `p_limit > 100`.

**Task 5 — Production routing**
Create `admin.mission-control.class.$id.tsx` (thin), add Open Class by UUID + invalid-UUID local state; update `admin.mission-control.index.tsx` landing.
*Accept:* route stays inside the Mission Control shell; **invalid UUID triggers no RPC**; no name search.

**Task 6 — Workspace renderer**
Build `MissionWorkspaceRenderer` (Identity → Context → State → Actions → Memory) + loading/empty/error states.
*Accept:* no fixtures; no raw DTO in any renderer; State is **not** rendered via `HealthBand`; empty state is distinct from projection/contract failure.

**Task 7 — Action presentation**
Build `MissionActionsBand`, `MissionActionDrawer` (desktop Sheet / mobile Drawer), and the exact `class.assign` form. All labels/options/requiredness come from the action DTO.
*Accept:* program/teacher options **originate only** from the Actions RPC; required select with zero options is disabled with a clear explanation; unsupported schema/control disables execution fail-closed.

**Task 8 — Execution integration**
Implement immutable submission, stable `request_id`, double-submit guard, disabled auto-retry, and the four result states (§2.6).
*Accept:* only `execute_mission_control_action` mutates; no caller-built `p_context`.

**Task 9 — Refresh / replay**
Exact cache invalidation + replay presentation ("Đã xử lý trước đó").
*Accept:* success/replay refresh `workspace` + `actions` + `memory` for the exact class; replay is a distinct parsed state.

**Task 10 — Responsive / accessibility pass**
Verify keyboard-only completion, focus enter/return, labels, mobile Drawer, desktop Sheet, long UUIDs/labels wrap, empty option sets, and that a pending execution cannot be accidentally dismissed or duplicated.

**Task 11 — Verification evidence**
Build → scoped lint → static forbidden-pattern audit → authenticated & denial smoke matrix (§5). Then submit the diff to Claude. **Do not merge. Do not deploy.**

---

## 5. Verification Lovable must self-run before submitting the diff

**Build (Bun authority — D338):**
```
bun install --frozen-lockfile && bun run build
```
Build/TypeScript failure → STOP, do not proceed, report to Claude.

**Scoped lint:** lint the touched Mission Control files and the two route files; zero new errors.

**Static forbidden-pattern audit — expect ZERO matches:**
```bash
# 1. no .from() anywhere in the feature
grep -rnE "\.from\(" src/features/mission-control

# 2. supabase imported ONLY by the adapter (this must be the only hit)
grep -rnE "from ['\"].*supabase" src/features/mission-control

# 3. legacy low-level mutation never called directly
grep -rn "assign_class_distribution" src/features/mission-control

# 4. legacy workspace wrapper never called in production (feature + routes)
grep -rn "get_object_workspace" src/features/mission-control src/routes/_authenticated/admin.mission-control.class.\$id.tsx src/routes/_authenticated/admin.mission-control.index.tsx

# 5. internal core never called directly
grep -rn "_mission_control_workspace_core" src/features/mission-control

# 6. no service-role / secret usage
grep -rniE "service_role|secret" src/features/mission-control

# 7. no fixture imports in production code
grep -rn "fixtures/demoObjects" src/features/mission-control
```
(Check 2 may return only `adapters/missionControlAdapter.ts`. Checks 3–7 must return nothing.)

**Smoke matrix:**
- Authenticated same-school admin opens a valid class UUID → Identity/Context/State/Actions/Memory render; `class.assign` completes; workspace refreshes; memory "Load more" pages without duplicates/reorder.
- Replay: re-submit same request → "Đã xử lý trước đó".
- Invalid UUID → local validation state, **no RPC**.
- Not-found / denied → generic safe states, workspace-level.
- Anonymous / non-admin → fails safely; no data leak; no FE authorization added.

---

## 6. Review bar (what Claude will check on the diff)

**Architecture:** production route nested under `/admin/mission-control`; no Supabase in components; adapter is the sole RPC boundary; parser separates raw JSON from models; query keys carry object type+id; no fixtures in production imports; `routeTree.gen.ts` has generated changes only.

**Security:** publishable client + user JWT only; no service-role; no `.from()`; no actor/profile ID passed to RPCs; no FE permission/tenant resolver; `school_id` only from parsed workspace context; **no `assign_class_distribution`, no `get_object_workspace`, no `_mission_control_workspace_core`**; raw errors never rendered; backend denial stays authoritative.

**Contract:** exact B6.0.1 RPC names/params (`get_mission_control_workspace` / `_actions` / `_memory` / `execute_mission_control_action`); `p_request_id` always present; memory `p_limit` bounded (≤100, default 50) and `next_cursor` used unchanged; actions only from the Actions RPC; only `MissionActionInputSchema/v1` executes; program/teacher options never synthesized; additive unknowns stripped; required/semantic/schema violations fail closed; replay is distinct.

**Mutation:** one submission owns one immutable `request_id`; explicit retry reuses same id+payload; new intent → new id; double-submit blocked; success/replay invalidates exact class caches; a late mutation cannot cross-write another class's UI.

**UX / A11y:** loading, empty, invalid-id, not-found, denied, projection/contract-failure are distinct; actions/memory failures are band-local; required/optional announced; required select with no options can't submit; success/replay/known-failure/transport-uncertainty use different copy; no raw JSON/errors; desktop Sheet + mobile Drawer both work; focus enters/returns; keyboard-only completion; pending execution can't be duplicated/dismissed; long IDs/labels wrap.

---

## 7. Lovable operating rules (DMA)

- Full-file creation for every new file (no partial patches).
- Never hand-edit `routeTree.gen.ts` — let TanStack tooling regenerate it.
- Retire `CommandBarPlaceholder.tsx` **only after** every import of it is removed.
- Do not touch the isolated legacy demo (`ObjectWorkspace`, `HealthBand`, `HistoryBand`, `objectWorkspaceModel`, fixtures, `/admin/object/$type/$id`).
- Do not alter architecture, backend, migrations, generated types, permissions, or any out-of-scope portal.
- Terminal step: **submit diff to Claude — no merge, no deploy.** Owner QA gates the merge.

---

## 8. Definition of Done

- [ ] Baseline confirmed at header SHA/HEAD; tree clean at start.
- [ ] No backend/migration/table/permission/generated-type mutation.
- [ ] Production class route works inside the Mission Control shell.
- [ ] UUID validation prevents invalid requests.
- [ ] Workspace renders Identity/Context/State/Actions/Memory from production DTOs via `get_mission_control_workspace`.
- [ ] All raw RPC responses cross strict runtime parsers; additive stripped, semantic/schema violations fail closed.
- [ ] Only the adapter imports the Supabase client.
- [ ] Adapter binds exactly to `get_mission_control_workspace` / `_actions` / `_memory` / `execute_mission_control_action`; no `get_object_workspace` / core / legacy mutation.
- [ ] `class.assign` uses backend schema/options and the executor RPC only.
- [ ] Memory uses bounded `p_limit` (≤100, default 50) and unchanged `next_cursor`; no duplicates/reorder.
- [ ] Stable request-id, retry, and replay behavior demonstrated.
- [ ] Success/replay refreshes workspace, actions, and memory.
- [ ] Loading/empty/denial/not-found/partial-error/result states complete.
- [ ] Desktop/tablet/mobile QA passes; keyboard/focus QA passes.
- [ ] Build passes; scoped lint passes; static audit finds no forbidden patterns (incl. zero `get_object_workspace`).
- [ ] Authenticated same-school admin journey passes; anon/non-admin fails safely.
- [ ] Diff submitted to Claude; Owner QA passed before merge.
```
End of package — v2.
```
