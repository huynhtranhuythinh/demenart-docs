# B3 — FAMILY EXPERIENCE COMPONENT MAP
**V113B** · "One Family Experience System, two entry contexts" 🔒 — unify at the **experience/component** level across `/parent/family`, `/family`, Memory Room; **do not merge routes or permissions.** `OBSERVED_SOURCE` unless noted.
**Class:** KEEP · REFINE · RECOMPOSE · EXTRACT · RETIRE.

---

## 1. Current reality (what diverges vs what's shared)

`OBSERVED_SOURCE`:
- **Already shared today:** `FamilyArchiveNavigation`, `FamilyArchiveIndex`, `FamilyMemoryPeriod`, `MemoryItem`, `ArchivedCardsSection`, `FamilyCardComposer`, `FamilyStateBlock`, `familyExperienceGrammar`, `memoryRoomShared` (Room content) — all imported by **both** `/parent/family` and `/family`.
- **Diverges per host:** the **shell** (amber `max-w-4xl` ParentLayout vs cream `max-w-3xl` standalone), the **member section** (full management vs read-only), the **empty state** copy, the **create affordance** (duplicated: archive `onCreate` + standalone button), and the **member-subtitle helper** (copy-pasted into both route files).

So the split is **mostly at the shell + member-admin + create-CTA level**, not the archive/card/room level (those are already shared). This makes unification tractable.

## 2. Component map

| Element | Current source | Class | Action (no route/permission merge) |
|---|---|---|---|
| **Shared shell primitive** | none — two hand-rolled shells (`parent.family` in ParentLayout; `family.tsx` own header) | **EXTRACT** | Extract a `FamilyExperienceShell` primitive that renders the V4 family visual language (forest identity, ivory reading surface) and takes a `context: 'guardian'\|'member'` prop. Guardian mounts it inside ParentLayout; member mounts it standalone. Routes/authz untouched. |
| **Family identity header** | `space.name` h1 + child chips (both hosts, slightly different markup) | **RECOMPOSE + EXTRACT** | One `FamilyIdentityHeader` (space name + child chips + V4 forest identity). Bold/asymmetric per V4. Replaces the two divergent title blocks. |
| **`Ký ức \| Thành viên` separation** | none — one continuous page (archive → create → members → invites) | **RECOMPOSE** | Introduce two clearly separated areas via **query-backed section state** (`?section=` — B1 §3). `Ký ức` = archive; `Thành viên` = members/invites. Member context shows `Thành viên` read-only by role. |
| **Archive navigation** | `FamilyArchiveNavigation` (desktop rail / mobile Sheet, `?y&m`, keyset window) | **KEEP** | Mature V112C spine; reuse verbatim. Only restyle to V4 tokens later (not V113B). |
| **Period view** | `FamilyMemoryPeriod` (heading + count + `space-y-10` `MemoryItem`) | **KEEP → REFINE** | Keep; REFINE the "{n} ký ức" count line so a metric doesn't precede the memories (V4 "not a dashboard"). |
| **Memory Card** | `MemoryItem` (composition-driven: text/audio/media, reserved 4:3, quiet footer) | **KEEP → REFINE** | Keep composition logic; REFINE to V4 "large child media" + editorial type; already media-first (good). |
| **One create CTA** | **two** affordances per host (archive `onCreate` + standalone "Tạo kỷ niệm") | **RECOMPOSE** | Collapse to **one** create entry within `Ký ức` (role-gated by `create_card` capability). Removes the double-CTA finding (F7). |
| **Member presentation** | guardian: full mgmt inline in `parent.family.tsx`; member: read-only list inline in `family.tsx` | **EXTRACT + RECOMPOSE** | Extract `FamilyMembers` component rendering the roster; **role-conditioned affordances** (invite/remove/pending only when `invite_member`/guardian). Same component, both contexts, affordances gated by capability — **authority unchanged**. |
| **Role-conditioned controls** | scattered inline gates (`canInvite`, `canCreate`, `canRemove`) | **EXTRACT** | Centralize capability→affordance mapping in one place fed by `get_family_space` / `get_family_space_role` (already the source of truth). UI mirrors backend branch-for-branch (D293) — no merge. |
| **Invite / remove / revoke** | `InviteDialog` + AlertDialogs inline in `parent.family.tsx` | **EXTRACT** | Pull dialogs into `FamilyMembers`; guardian-only by capability. One-time link + relationship labels kept. |
| **Member-subtitle helper** | `memberSubtitleFrom` **duplicated** call-sites in both route files | **EXTRACT** | Single shared helper usage (already in `familyExperienceGrammar`); remove duplication. |
| **Empty / denied / error states** | `FamilyStateBlock` + `classifyRpcOutcome`/`outcomeToLoadState` | **KEEP** | Strong; reuse. Ensure both contexts + both sections use it. |
| **Memory Room** | `FamilyMemoryRoom` route + `CardDetail` (`memoryRoomShared`) | **RECOMPOSE (presentation) + REFINE (split file)** | Reorder to content-first hierarchy (B5) **without** touching D284/D293/D305 branches; split the ~1k-line `memoryRoomShared` into content / engagement / preserve / media modules. |
| **Return context** | `navOriginHint` (`origin` whitelist) + back-to-`?y&m` (D306 M5) | **KEEP → RECOMPOSE (surface it)** | Keep the mechanism; RECOMPOSE so a visible "return context" element sits at the **top** of the Room (V4/PO hierarchy item #1). `origin` remains UX-only, never authz. |
| **Legacy stream body** | `FamilyMemoryStream` (unmounted; exports `MemoryItem`/`ArchivedCardsSection` still used) | **RETIRE (deferred)** | `EXTRACT` the two live exports into their own modules, then RETIRE the dead stream body. **Not deleted in V113B** (planning only). |

## 3. Guardian vs member — same system, gated affordances (no permission merge)

🔒 + 🔧: the unified components take role/capability and render affordances accordingly; the **two routes and two authorization contexts stay separate**:

| Affordance | Guardian (`/parent/family`) | Member (`/family`) | Source of truth |
|---|---|---|---|
| See archive / open Room | yes | yes | `get_family_space` / EA (D284) |
| Create memory | if `create_card` | if `create_card` | capability |
| Invite / remove / pending | yes (`invite_member`) | **no** (read-only roster) | capability |
| Contribute / react / preserve (in Room) | per Room gates | per Room gates | engagement payload (D293) |
| Shell chrome | inside ParentLayout (amber→V4) | standalone (V4) | route/context |

## 4. Extraction plan summary (for wireframes, not implementation)

`INFERRED` target module tree (names indicative only):
- `FamilyExperienceShell(context)` → `FamilyIdentityHeader` + `FamilySectionSwitch(?section)` → { `FamilyArchive` (KEEP `FamilyArchiveNavigation`) with one create CTA · `FamilyMembers(role)` }.
- `MemoryRoom` (RECOMPOSE content-first) reusing extracted `RoomHeader/return`, `RoomMedia`, `RoomStory`, `RoomProvenance`, `RoomVoices`, `PreserveControl`, `RoomLifecycle`.
- Shared: `familyExperienceGrammar`, `FamilyStateBlock`, tokens.

**No route merge. No permission merge. No authority change.** Every classification above is presentation/organization only.
