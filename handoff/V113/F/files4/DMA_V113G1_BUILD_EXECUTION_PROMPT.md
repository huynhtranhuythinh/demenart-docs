# DMA PARENT PORTAL — V113G.1
## SHARED FOUNDATION + HÔM NAY CANARY — BUILD EXECUTION

Bạn là Claude — PM / Builder của DMA.

Product Owner và ChatGPT/CTO đã duyệt:

- `V113G.0 PASS — REPOSITORY/CONTRACT AUDIT ACCEPTED`
- `V113G.0B PASS — PRODUCTION BASELINE CLOSED`
- được phép mở `V113G.1 — Shared Foundation + Hôm nay Canary`

Sprint này được phép code trong phạm vi giới hạn dưới đây.

Không deploy trước khi Product Owner duyệt evidence.

---

## 1. BASELINE OF RECORD

### Repository baseline

- HEAD trước G.1:
  `b28cd9b7844b4cb6ec7a019a8064c48f85b0a0c3`
- HEAD message:
  `Fixed useFamilyArchive signature`
- HEAD timestamp:
  `2026-07-16T11:38:43Z`
- Package manager:
  Bun
- Stack:
  Vite 8 · Tailwind 4 CSS-first · React 19 · TanStack Router 1.168
- Route inventory:
  raw fullPaths 57 · convention count 52
- Migrations:
  101
- Current production shell:
  amber, `Trang chủ / Hành trình / Gia đình / Cài đặt`, no tablet drawer
- G.0 and G.0B change proof:
  zero source/schema/package/route/deploy mutation

### Canonical design baseline

Use only:

1. `F1_VISUAL_SOURCE_OF_TRUTH.md`
2. `F2_DESIGN_TOKEN_SPEC.md`
3. `F3_SCREEN_CANONICAL_MATRIX.md`
4. `F4_COMPONENT_AND_PATTERN_SPEC.md`
5. `F5_RESPONSIVE_ACCESSIBILITY_MOTION_SPEC.md`
6. `F6_VISUAL_QA_ACCEPTANCE_GATES.md`
7. `F7_V113F_CLOSEOUT.md`
8. `DMA_Correction_Pack_1_Thanh_vien_gia_dinh.html`
9. `DMA_Correction_Pack_2_Quyen_rieng_tu.html`
10. `DMA_Correction_Pack_3_Cai_dat_Account_Utility.html`
11. `DMA_Correction_Pack_4_Create_Flows_States.html`

Also use these approved audit records:

- `DMA_V113G0_AUDIT_CLOSEOUT.md`
- `DMA_V113G0B_VISUAL_BASELINE.md`

V113G.0B addendum SHA-256:

`1a16ea49f512203b9db4ec90bae993158424472b4d7cbe7c38f9daac72a39b5b`

### Production baseline status

- 30 valid production captures exist.
- Desktop 1440 verified.
- Tablet 768 verified.
- Current mobile-layout capture is 500px because Chrome/macOS could not resize lower.
- This 500px qualification closes the historical production-baseline debt only.
- It does NOT satisfy G.1 implementation acceptance at 390px.
- G.1 must test the implemented build at true 390px, plus breakpoint boundaries.

---

## 2. MISSION

Implement the frozen shared Parent visual foundation and use `/parent` — Hôm nay — as the first canary route.

G.1 must:

1. replace the current amber Parent chrome with the frozen emerald/ivory system;
2. establish frozen tokens and typography;
3. implement the exact four-destination navigation model;
4. implement desktop, tablet and mobile chrome as three different compositions;
5. extract a shared semantic ChildSwitcher without breaking persisted child context;
6. introduce reserved-media and truthful state foundations;
7. rebuild `/parent` into the canonical Hôm nay composition;
8. preserve all existing routes, data contracts, auth wiring and backend behavior;
9. leave all non-Home route content functionally intact inside the new shell;
10. produce complete evidence for ChatGPT/Product Owner review;
11. stop without deployment.

This is not a full Parent Portal redesign sprint.

Do not implement G.2–G.8 work early.

---

## 3. FROZEN INVARIANTS

Do not reopen:

- official DMA logo;
- L2 Journey visual baseline;
- palette emerald / ivory / champagne / sage;
- Playfair Display + Be Vietnam Pro;
- landing label = `Hôm nay`;
- desktop fourth primary = `Thế giới của con`;
- mobile fourth primary = `Của con`;
- exactly four primary Parent destinations;
- utilities are not primary navigation;
- tablet = top bar + navigation drawer;
- one primary action per surface;
- counts are quiet metadata only;
- Parent-facing, not Kid-dashboard;
- ChildSwitcher uses shared persisted ParentChildProvider context;
- semantic child buttons with `aria-pressed`;
- error ≠ denied ≠ empty;
- generic denied copy;
- reserved media boxes;
- no autoplay;
- minimum target 44×44;
- responsive = recomposition, not scale-down;
- separate governance predicates;
- no `canManage`;
- consent path unchanged;
- nine consent types unchanged;
- MIN-consent unchanged;
- `family_space_display` default-off;
- no public/social audience;
- no AI, Search, Circle, ranking or social feed.

---

## 4. AUTHORIZED FILE SCOPE

### Existing files allowed to change

Only:

- `src/routes/_authenticated/parent.tsx`
- `src/routes/_authenticated/parent.index.tsx`
- `src/styles.css`

### New files allowed

Only these proposed paths:

- `src/features/parent/shell/ParentIdentityRail.tsx`
- `src/features/parent/shell/MobileParentHeader.tsx`
- `src/features/parent/shell/ParentBottomNav.tsx`
- `src/features/parent/shell/ParentTabletBar.tsx`
- `src/features/parent/shell/parentNav.ts`
- `src/features/parent/ChildSwitcher.tsx`
- `src/features/shared/ReservedMedia.tsx`
- `src/features/shared/TruthState.tsx`
- `src/features/parent/home/MemoryHero.tsx`

### Scope expansion rule

Before the first write, inspect the exact logo and font-loading paths.

If correct implementation requires changing any file outside the authorized list:

1. do not change that file;
2. stop before the first write;
3. return `V113G.1 HOLD — SCOPE EXPANSION REQUIRED`;
4. identify the exact additional path;
5. explain why it is unavoidable;
6. propose the smallest expansion.

Do not silently expand scope.

---

## 5. PROHIBITED FILES AND SYSTEMS

Do not change:

- `package.json`
- `bun.lock`
- `bunfig.toml`
- `src/routeTree.gen.ts`
- `src/integrations/supabase/types.ts`
- any file under `supabase/**`
- any migration or SQL
- any RPC
- any RLS policy
- any Edge Function
- any generated database type
- any consent contract
- `src/routes/_authenticated/parent.journal.tsx`
- `src/routes/_authenticated/parent.discovery.tsx`
- `src/routes/_authenticated/parent.family.tsx`
- `src/routes/_authenticated/parent.kid.tsx`
- `src/routes/_authenticated/parent.consent.tsx`
- `src/routes/_authenticated/parent.settings.tsx`
- `src/routes/_authenticated/family.tsx`
- `src/routes/_authenticated/family_.memory.$cardId.tsx`
- `src/features/journey/**`
- `src/features/family/**`
- `src/features/discovery/**`
- Admin, School, Teacher, Portal, Kid, Share and public invite routes

Do not:

- create a route;
- remove a route;
- change route nesting;
- regenerate the route tree;
- install or upgrade dependencies;
- change auth redirects;
- change `homePathForRole`;
- move or delete Journey Share;
- modify Discovery;
- modify Family governance;
- modify Kid contracts;
- modify Privacy or Settings behavior;
- create production fixtures;
- mutate production data;
- deploy preview or production without PO approval.

---

## 6. PRE-WRITE GATES

Complete all gates before editing any file.

### 6.1 Pin repository truth

Record:

- current HEAD;
- latest edit/commit;
- current file states for all three allowed existing files;
- exact current route count;
- migration count.

HEAD must still be:

`b28cd9b7844b4cb6ec7a019a8064c48f85b0a0c3`

If HEAD differs:

- inspect the new changes;
- do not write;
- return `V113G.1 HOLD — BASELINE DRIFT`.

### 6.2 Protected-file fingerprints

Before write, calculate and record exact SHA-256 for:

- `src/routeTree.gen.ts`
- `package.json`
- `bun.lock`
- `src/integrations/supabase/types.ts`

Also record:

- migration file count;
- route raw fullPath count;
- route convention count.

These values must be rechecked after implementation.

### 6.3 Static baseline

Before write, run the existing commands:

- `bun run lint`
- `bun run build`

For each command record:

- exact command;
- exit code;
- output summary;
- warnings/errors.

If either command fails because of current source:

- do not code;
- return `V113G.1 HOLD — PRE-EXISTING STATIC QA FAILURE`;
- provide the exact failure;
- do not repair it in this sprint without a new prompt.

Do not install dependencies to make commands run.

If command execution is unavailable in the current environment:

- do not code;
- return `V113G.1 HOLD — COMMAND RUNNER UNAVAILABLE`.

### 6.4 Official logo audit

Find the exact existing official DMA logo asset.

Confirm:

- path;
- file type;
- existing usage;
- light treatment suitability on emerald;
- dark treatment suitability on ivory;
- no redraw required.

Do not use BookHeart, generic cricket, text-only DMA or botanical family wordmark.

If the official logo asset cannot be used without changing an out-of-scope loader/file:

- stop for scope expansion.

### 6.5 Font-loading audit

Determine exactly:

- where Playfair Display is loaded;
- where Be Vietnam Pro is loaded;
- whether font assets already exist locally;
- whether `src/styles.css` can activate them without another file change;
- current CSP/production restrictions if relevant.

Rules:

- reuse the existing correct loader where possible;
- do not add a package;
- do not add a third font;
- do not choose between “self-host” and “remote” by preference;
- do not add Google Fonts remotely if production policy/CSP does not allow it;
- if an out-of-scope file is required, stop for scope expansion.

### 6.6 Home data-contract audit

Before implementation, confirm the current `/parent` data shapes and exact source symbols for:

- children;
- selected child;
- persisted child context;
- journal payload;
- signed media;
- newest media-bearing item;
- parent memories;
- family-preserved entries;
- empty state;
- child-fetch error;
- journal-fetch error;
- existing create/open actions.

Do not add a new RPC.

Do not add `get_family_stream_presence` merely to construct the Home family signal.

The family signal must use preserved Journey entries from the existing journal payload where:

`source = 'family'`

If the current journal payload cannot provide the canonical Home composition without a new data contract:

- stop;
- report the exact missing field;
- do not invent or add backend work.

### 6.7 No-duplicate ChildSwitcher plan

Current route-local selectors exist in Journey and Discovery.

G.1 may not edit those routes.

Therefore:

- the new shared ChildSwitcher must be fully implemented;
- Home must adopt it in G.1;
- the new shell must not create a second active child selector on routes that still own a local selector;
- use a controlled route-aware shell policy for this canary sprint;
- do not hide existing local selectors through brittle CSS;
- do not rebind Discovery early;
- document the temporary adoption boundary;
- G.2 will migrate Journey and Discovery.

If duplicate selectors cannot be avoided inside the allowed scope:

- stop and request scope correction.

---

## 7. EXECUTION ORDER

Use this order exactly.

### Phase 1 — Frozen tokens and global foundations

In `src/styles.css`:

- add F2 semantic token variables;
- preserve Tailwind 4 CSS-first architecture;
- establish exactly the approved two font families;
- add focus-visible grammar;
- add reduced-motion guard;
- add safe-area variables;
- add layout variables only where needed;
- avoid global selectors that unintentionally restyle unrelated portals;
- namespace Parent-specific foundations where necessary.

Frozen core tokens:

- emerald identity `#053327`
- emerald primary `#0B513B`
- emerald hover `#083E2E`
- ivory `#FCF7F0`
- raised ivory `#FFFDF9`
- champagne `#C8AA6A` decorative only
- champagne soft `#DED0AA`
- sage `#A5B19A`
- sage tint `#EDF0E8`
- primary ink `#17382C`
- secondary ink `#46584F`
- metadata ink `#6D716B`
- gold text `#806A35`
- error/destructive `#A8473C`
- denied `#776038`

Do not use champagne as small body text.

Do not introduce teal, mint, SaaS blue, neon or orange-as-brand.

### Phase 2 — Navigation model

Create `parentNav.ts`.

Exactly four primaries, in this order:

1. Hôm nay → `/parent`
2. Hành trình → `/parent/journal`
3. Gia đình → `/parent/family`
4. Thế giới của con / Của con → `/parent/kid`

Rules:

- desktop/tablet label for item 4: `Thế giới của con`;
- mobile label for item 4: `Của con`;
- utility routes are not primary:
  - Quyền riêng tư
  - Cài đặt
  - Thông báo
  - Hỗ trợ
  - Đăng xuất
- utility surfaces show no false active primary destination;
- use `aria-current="page"` only on the true active primary route.

### Phase 3 — Shared semantic ChildSwitcher

Create `ChildSwitcher.tsx`.

Requirements:

- reads/writes through existing `ParentChildProvider`;
- preserves persisted `selectedChildId`;
- uses semantic `<button type="button">`;
- selected child uses `aria-pressed="true"`;
- unselected uses `aria-pressed="false"`;
- accessible name includes child name and available age;
- effective target ≥44×44;
- no schema or avatar-field invention;
- monogram/text fallback only;
- variants may support rail, compact and chip-row through presentation props;
- no route-local state.

Home must use this component.

Other route-local selectors remain untouched until G.2.

### Phase 4 — Shared state and media primitives

Create `TruthState.tsx`.

G.1 foundation scope:

- loading;
- empty;
- error.

Requirements:

- loading uses `role="status"`, `aria-live="polite"`, `aria-busy="true"`;
- error uses `role="alert"`;
- empty has labelled title/description, no unnecessary live region;
- zero or one action;
- error and empty are visually distinct;
- do not claim the full Pack-4 nine-state system is complete;
- full extension remains G.8.

Create `ReservedMedia.tsx`.

Requirements:

- reserves final aspect ratio before signed URL resolves;
- supports 16:9 and 4:3;
- same-size loading placeholder;
- failure stays inside the same box;
- no layout collapse;
- no autoplay;
- image/video semantics preserved;
- no broken-image icon.

### Phase 5 — Responsive Parent shell

Refine `parent.tsx` while preserving:

- ParentChildProvider wiring;
- authenticated layout behavior;
- notification wiring;
- sign-out behavior;
- outlet rendering;
- role/auth contracts.

#### Desktop: 1024px and above

Use `ParentIdentityRail`.

Required anatomy:

- official logo;
- family/parent identity available from current contract;
- controlled ChildSwitcher adoption boundary;
- four primary destinations;
- utilities separated from primaries;
- quiet account/footer zone;
- restrained botanical decoration only if it can be implemented without inventing assets or obscuring content.

No top horizontal primary nav.

#### Tablet: 401px–1023px

Use `ParentTabletBar`.

Required:

- top bar;
- official logo/identity;
- drawer trigger ≥44×44;
- navigation drawer containing four primaries and utilities;
- keyboard operable;
- focus moves into drawer and restores on close;
- Esc closes drawer;
- backdrop closes non-destructively;
- no desktop rail;
- no mobile bottom nav;
- no icon rail.

#### Mobile: 400px and below

Use:

- `MobileParentHeader`;
- `ParentBottomNav`.

Required:

- exactly four bottom items;
- label item 4 = `Của con`;
- fixed bottom nav;
- content reserves nav height plus safe-area inset;
- no utility in bottom nav;
- no content or toast beneath nav;
- sticky top header respects safe-area;
- all targets ≥44×44.

#### Breakpoint rule

Implement the frozen boundaries exactly:

- mobile: `max-width: 400px`;
- tablet: `401px–1023px`;
- desktop: `min-width: 1024px`.

Do not reuse the old Tailwind `sm=640` behavior as the product breakpoint.

At 500px after G.1, the app must show tablet top bar + drawer, not mobile bottom navigation.

### Phase 6 — Home MemoryHero

Create `MemoryHero.tsx`.

Canonical behavior:

- large reserved media;
- real newest media-bearing item;
- serif memory title/blurb;
- exactly one primary CTA when a hero exists:
  `Xem ký ức này`
- CTA opens the hero item in the existing Hành trình flow;
- optional quiet secondary action;
- no KPI tiles;
- no count before media;
- no invented ranking;
- no new route.

Create actions such as:

- `Ghi lại giọng kể`;
- `Ghi lại một điều về {child}`;
- `Tạo mới`;

must remain secondary/contextual when a hero exists.

In a true empty state, one record-first action may become the sole primary action.

### Phase 7 — Rebuild `/parent`

Refine `parent.index.tsx`.

Canonical order:

1. identity/title: `Hôm nay của {child}`;
2. Home ChildSwitcher where appropriate;
3. hero memory;
4. primary `Xem ký ức này`;
5. two quiet contextual/supporting areas using existing data only;
6. recent-memory strip if real items exist;
7. quiet family signal from preserved journal entries with `source='family'`;
8. contextual create action;
9. truthful empty/error handling.

Rules:

- one primary action;
- no KPI block;
- no 7/2/6/21 dashboard tiles;
- counts only as quiet metadata;
- no fake upcoming event;
- no fake recommendation;
- no ranking;
- no AI copy;
- no new read contract;
- use existing signed-media path;
- latest hero selection must be deterministic;
- do not select an item without usable media when a media-bearing item exists;
- preserve direct links and current composer/open behavior.

### Phase 8 — Regression containment

Before closeout, verify unchanged child-route content still mounts under the new shell:

- `/parent/journal`
- `/parent/discovery`
- `/parent/family`
- `/parent/kid`
- `/parent/consent`
- `/parent/settings`
- `/portal/notifications`
- `/portal/support`

Do not repair those route compositions in G.1.

Only fix a regression caused directly by the new shell and only within the authorized files.

If a route requires editing its own source to survive the shell:

- stop;
- report exact conflict;
- do not expand scope silently.

---

## 8. DATA FIXTURES

Use existing safe actors/data only.

### Populated fixture

- PH Hùng
- selected child An
- real populated journey/media data

### Near-empty fixture

- selected child Khang
- report the actual existing state;
- do not label Khang empty if real records exist.

### Empty state

Valid evidence requires either:

- an authenticated Parent actor with zero linked children; or
- a non-production local/network-state harness that does not alter production data and is labelled accurately.

Do not use a Teacher or other role as a fake Parent no-child fixture.

Do not mutate production to manufacture empty data.

### Error states

May be tested through safe network blocking/devtools:

- child-fetch error;
- journal-fetch error;
- signed-media failure.

Do not alter production data.

---

## 9. ACCESSIBILITY GATES

Verify:

- all interactive targets ≥44×44;
- keyboard-only navigation;
- visible `:focus-visible`;
- logical tab order;
- `aria-current` on active primary nav;
- `aria-pressed` on ChildSwitcher;
- drawer labelled and keyboard operable;
- focus trap/containment appropriate for drawer;
- focus restored after drawer close;
- icon-only buttons have accessible names;
- contrast:
  - body/metadata ≥4.5:1;
  - large titles ≥3:1;
  - gold text uses `#806A35`, not champagne;
- Vietnamese diacritics render correctly:
  - ổ
  - ữ
  - ằ
  - ị
  - ợ
  - ẽ
- reduced-motion removes slide/scale animation;
- no autoplay;
- no content under mobile bottom nav.

---

## 10. RESPONSIVE ACCEPTANCE

Mandatory implementation viewports:

- 1440px
- 1024px
- 1023px
- 768px
- 500px
- 401px
- 400px
- 390px

Expected shell:

| Width | Expected |
|---|---|
| 1440 | desktop identity rail |
| 1024 | desktop identity rail |
| 1023 | tablet top bar + drawer |
| 768 | tablet top bar + drawer |
| 500 | tablet top bar + drawer |
| 401 | tablet top bar + drawer |
| 400 | mobile header + bottom nav |
| 390 | mobile header + bottom nav |

No desktop layout scaled down.

Home must recompose:

- desktop: media/text composition with supporting areas;
- tablet: single-column content under top bar;
- mobile: title → child chips → media → CTA → support → recent/family signal.

---

## 11. SECURITY AND GOVERNANCE GATES

G.1 must not alter:

- guardian/member route separation;
- `canEdit`;
- `canArchive`;
- `can_moderate`;
- `create_card`;
- `invite_member`;
- generic Memory Room denial;
- consent write path;
- nine consent types;
- MIN-consent;
- `family_space_display`;
- Kid contracts;
- Discovery contracts;
- Journey Share;
- auth redirects;
- route list.

Search changed code for:

- `canManage`;
- new Supabase calls;
- new RPC names;
- new audience values;
- new route strings.

Expected result:

- no `canManage`;
- no new backend contract;
- no public/social audience;
- no route creation.

---

## 12. STATIC QA

After implementation run:

- `bun run lint`
- `bun run build`

Compare with the pre-write baseline.

Record:

- command;
- exit code;
- warnings;
- errors;
- before/after difference.

Also run:

- protected-file SHA-256 comparison;
- route count comparison;
- migration-count comparison;
- changed-file inventory;
- diff check for prohibited files.

No PASS if lint or build regresses.

---

## 13. VISUAL EVIDENCE PACKAGE

Capture the implemented environment, clearly labelled as local/preview and not production unless explicitly deployed later.

### Home matrix

Capture `/parent` with An at:

- 1440
- 768
- 390

Also capture breakpoint proof:

- 1024
- 1023
- 401
- 400

### Fixture/state evidence

Capture where testable:

- An populated;
- Khang near-empty;
- Home empty;
- child-fetch error;
- journal-fetch error;
- signed-media loading/failure.

If a fixture is not safely testable, mark it `NOT TESTABLE` with reason.

Do not fake PASS.

### Shell regression evidence

Capture representative routes:

- `/parent/journal`
- `/parent/family`
- `/parent/kid`
- `/parent/consent`
- `/parent/settings`

At minimum:

- one desktop;
- one tablet;
- one mobile;

across the set, enough to prove all three shell compositions and unchanged route mounting.

### Evidence details

For each screenshot record:

- environment;
- route;
- actor;
- child;
- viewport;
- filename/evidence ID;
- console errors;
- failed requests;
- acceptance verdict.

---

## 14. STOP CONDITIONS

Stop immediately if:

1. HEAD differs from the approved baseline;
2. pre-write lint fails;
3. pre-write build fails;
4. command runner is unavailable;
5. official logo cannot be used within scope;
6. correct fonts require an out-of-scope file;
7. Home requires a new RPC/data contract;
8. family signal cannot be derived from existing journal data;
9. duplicate ChildSwitchers cannot be avoided within scope;
10. ParentChildProvider or auth wiring must change semantically;
11. a route source outside scope must be edited;
12. routeTree changes;
13. package or lockfile changes;
14. migration/SQL/generated types change;
15. any backend or consent change appears necessary;
16. `canManage` or merged governance is introduced;
17. static QA regresses;
18. responsive boundaries cannot be implemented exactly;
19. official design would require redesigning an approved mockup;
20. a production deploy is required to validate the sprint.

On STOP:

- do not continue;
- do not deploy;
- do not broaden scope;
- return `V113G.1 HOLD`;
- state the exact blocker;
- provide evidence;
- propose one minimum corrective action.

---

## 15. ROLLBACK DISCIPLINE

Keep G.1 isolated.

Preferred:

- one isolated G.1 commit.

If Lovable auto-commits multiple edits:

- keep all G.1 changes in one contiguous commit range;
- do not mix unrelated changes;
- record first and last commit;
- provide exact revert order;
- verify revert would restore the amber shell and prior Home without touching backend or routes.

Do not squash unrelated history.

---

## 16. CLOSEOUT FORMAT

Return exactly:

# V113G.1 CLOSEOUT

## A. EXECUTIVE VERDICT

Choose one:

- `V113G.1 PASS — READY FOR CTO/PO VISUAL REVIEW`
- `V113G.1 HOLD — BLOCKER FOUND`
- `V113G.1 FAIL — REGRESSION OR CONTRACT BREACH`

## B. BASELINE AND PREFLIGHT

- HEAD before
- protected hashes before
- route counts before
- migration count before
- lint before
- build before
- logo path
- font-loading path and strategy
- Home data-contract evidence

## C. IMPLEMENTATION SUMMARY

- exact changed files
- exact new files
- purpose per file
- commit or commit range

## D. SHELL IMPLEMENTATION

- desktop
- tablet
- mobile
- navigation labels
- utility placement
- breakpoint behavior
- temporary ChildSwitcher adoption boundary

## E. HOME IMPLEMENTATION

- hero selection logic
- primary CTA
- secondary actions
- family signal source
- empty/error logic
- no-KPI proof

## F. RESPONSIVE EVIDENCE

Table:

| Route/state | 1440 | 1024 | 1023 | 768 | 500 | 401 | 400 | 390 | Verdict |

## G. ACCESSIBILITY EVIDENCE

- targets
- focus
- keyboard
- aria-current
- aria-pressed
- drawer behavior
- contrast
- diacritics
- reduced motion
- safe-area

## H. REGRESSION MATRIX

At minimum:

- `/parent/journal`
- `/parent/discovery`
- `/parent/family`
- `/parent/kid`
- `/parent/consent`
- `/parent/settings`
- `/portal/notifications`
- `/portal/support`

For each:

- mounts;
- navigation;
- actor/child context;
- console;
- network;
- regression verdict.

## I. STATIC QA AFTER

- lint command and exit code
- build command and exit code
- before/after comparison

## J. CONTRACT AND CHANGE PROOF

State:

- routeTree before/after SHA-256;
- route raw count before/after;
- route convention count before/after;
- package.json before/after SHA-256;
- bun.lock before/after SHA-256;
- generated types before/after SHA-256;
- migration count before/after;
- backend changes: 0;
- consent changes: 0;
- governance merge: 0;
- production data mutation: 0;
- deployment: NO.

## K. OPEN ITEMS

List only honest remaining gaps.

Do not close G.2–G.8 work.

## L. ROLLBACK

- commit or range;
- exact revert method;
- expected restored state.

## M. NEXT ACTION

If PASS:

`Return evidence to ChatGPT and Product Owner. Do not deploy and do not start V113G.2 until explicitly approved.`

If HOLD/FAIL:

State one minimum corrective next action.

---

## 17. FINAL DISCIPLINE

- Build only G.1.
- Do not redesign frozen mockups.
- Do not touch backend.
- Do not touch Journey Share.
- Do not touch Discovery.
- Do not deploy.
- Claude PASS is not Product Owner PASS.
- Stop after closeout and evidence delivery.
