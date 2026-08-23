# B4 — JOURNEY ↔ DISCOVERY INTEGRATION MAP
**V113B** · How `/parent/discovery` becomes **"Nhìn lại một chặng"** inside Journey — **without deleting code/route or any backend change** 🔒. `OBSERVED_SOURCE` unless noted.

---

## 1. Current Discovery contracts (preserve as-is 🔒)

`OBSERVED_SOURCE` `parent.discovery.tsx` + `features/discovery/*`:
- **Reads:** `get_child_evidence_readiness(p_child_id)` → `ReadinessPayload`; `list_discovery_capsules(p_child_id)` → `capsules[]`; `get_discovery_capsule(p_capsule_id)` → `{ok, capsule}`.
- **Write:** `generate_discovery_capsule(p_child_id, p_scope, p_window_code, p_domain)` → `{ok, capsule}` | `{ok:false, reason:'not_eligible', failed:[...]}`.
- **UI:** `ReadinessPanel` (window select `current_3m` etc. + generate), `CapsuleCard` (grouped latest-per-key), `CapsuleDetail`. Page H1 **"✨ Bản Khám Phá Nghệ Thuật"** (V98C).
- **Product framing (fixed):** future role = contextual **"Nhìn lại một chặng"** inside Journey + optional Home preview; **not** a 5th primary 🔒.

## 2. Current route / query behavior

`OBSERVED_SOURCE`:
- Route `/parent/discovery`, search param **`?capsule={id}`** (validated) drives detail vs list.
- Detail fetch keyed on `?capsule`; `clearCapsuleParam` → `?capsule=undefined` + `scrollTo(0)`.
- Generate success → `navigate({search:{capsule:id}})` + scroll top.
- Reachable today from: Settings CardLink ("Nhìn lại") + Home card D ("Mở phần Nhìn lại", only when `hasData`).

## 3. Child-selector divergence (the one real integration blocker to reconcile)

`OBSERVED_SOURCE` — Discovery **re-implements** child fetching: its own `child_parents` query + local `selectedChildId` (default `list[0]`, **not persisted**, ignores `ParentChildProvider` and its `localStorage`). Every other parent surface uses the persisted context.

🔧 **Consequence:** if "Nhìn lại một chặng" is entered from Journey (which uses the shared context), Discovery could show a **different child** than the one selected in Journey.
🔧 **Fix (no backend):** bind Discovery to the shared `useParentChild` context (the same `child_parents` shape it already fetches). Pure client refactor; contracts unchanged. This is the single most important compatibility step for integration.

## 4. Future ChildSwitcher behavior

🔒 + 🔧: one shared `<ChildSwitcher/>` writing through `ParentChildProvider` (persisted). Journey, Home, and the reflection surface all read the same `selectedChildId`. Discovery drops its private selector. No schema/RPC change.

## 5. Possible Journey placements (grounded in the live viewer)

`OBSERVED_SOURCE` `ParentJourneyViewer` = `JourneyDetail` (story) → `JourneyStage` (media) → `JourneyRail` (kệ kỷ vật) + `MemoryConversation` Sheet; content-first; keyboard-navigable single-item stage.

| Placement | Mechanism | Pros | Cons | Verdict |
|---|---|---|---|---|
| **A. Journey header affordance** ("Nhìn lại {window}") | button in the Journey header opening the existing Discovery surface (route kept) scoped to current child | discoverable; no viewer surgery; route/contracts intact | a navigation, not inline | ★ **Recommended primary** — lowest risk, no backend, no route change. |
| **B. Rail chapter marker** | insert a "Nhìn lại một chặng" affordance into `JourneyRail` at window boundaries | contextual within the timeline | touches rail composition; needs window→timeline mapping | secondary (later refinement) |
| **C. Home preview card** 🔒 | small preview module on Home linking into A | matches PO "preview on Home" | must stay quiet (not a KPI/module-grid tile — B2) | ✅ complement, gated to when a capsule exists |
| **D. Inline in Journey viewer** | render `CapsuleDetail` inside the stage | fully inline | invasive to the stable stage/rail contract (D224-B); risk | avoid for V113B |

🔧 **Recommendation:** **A + C** — a Journey header entry ("Nhìn lại một chặng") + an optional quiet Home preview, both opening the **existing** Discovery route/contracts scoped by the shared ChildSwitcher. No route change, no backend.

## 6. Compatibility route strategy (no route change 🔒)

🔧 Options, all preserving `/parent/discovery` + `?capsule`:
- **Keep the route, change only entry points** (from Settings/Home-only → also Journey header/Home preview). ★ Recommended — zero route work; satisfies "do not delete or redirect."
- Later (not V113B): a nested `/parent/journal` sub-view could host the reflection, but that is a route change and is **out of scope**.
- Label reconciliation: present it everywhere as **"Nhìn lại một chặng"**; the page H1 "✨ Bản Khám Phá Nghệ Thuật" becomes a subordinate title or is aligned (copy-only, no contract change).

## 7. Generated / eligibility & empty/error/denied states

`OBSERVED_SOURCE` (preserve semantics):
- **Eligibility:** `generate_discovery_capsule` may return `{ok:false, reason:'not_eligible', failed:[domains]}` → surface as "chưa đủ dữ liệu cho chặng này" (existing `ReadinessPanel` handling).
- **Empty:** no capsules → readiness/generate panel only (no fabricated insight).
- **Error:** `loadError`/`detailError` → quiet retry (existing).
- **Denied:** child not linked → "Chưa có hồ sơ con nào được liên kết" (existing).
- 🔧 Integration must **not** hide these — the reflection entry from Journey should route into the same state grammar.

## 8. No-AI / no-ranking compliance check 🔒

🔧 `OBSERVED_SOURCE`-based reading: Discovery capsule generation is gated by **deterministic evidence readiness** (`readiness`, `not_eligible`, `failed` domains) and windows (`current_3m`), not by a relevance/LLM engine. `INFERRED`: this is aggregation over recorded evidence, **not** AI generation or ranking — consistent with the no-AI/no-Search/no-ranking boundary. `UNKNOWN`: the internal composition of a "capsule" (templated summary vs any generative step) was not inspected at the SQL level this pass → **evidence gap**; flagged for confirmation before any "reflection" copy implies analysis. **No backend change is proposed regardless.**

## 9. Dead Journey branch & Share implications

`OBSERVED_SOURCE`:
- The legacy `parent.journal.tsx` timeline branch (unreachable; `viewMode` hardcoded) contains `ShareMomentButton` (`create_private_share_link`/`revoke_share_link`) — the **only** wiring of moment share in the parent journal file.
- `ParentJourneyViewer` (the live viewer) exposes **no** share affordance in its prop surface (`OBSERVED_SOURCE`); `JourneyDetail` internals **not read** → its own share = `UNKNOWN` (evidence gap).
- **Implication:** integrating Discovery into Journey does **not** depend on the dead branch. Retiring the dead branch later is functionally safe for Discovery. **But** if moment **Share** is a desired product feature, it is currently (at best) not surfaced in the live viewer and would need **re-homing** — a **product decision**, explicitly **not** an implementation action in V113B. Recorded as an open item.

## 10. Feasibility verdict (Discovery integration)

🔧 **Feasible with zero backend change.** Contracts (`*_discovery_capsule`, readiness) preserved; route `/parent/discovery` + `?capsule` preserved; integration = **entry points (Journey header + optional Home preview) + binding Discovery to the shared ChildSwitcher**. The only substantive refactor is the child-selector reconciliation (client-only). No STOP condition (§8 gap is a confirmation item, not a backend requirement). Two open items carried forward: (a) capsule-composition no-AI confirmation; (b) Share re-homing product decision.
