# DMA V113G.0 — REPOSITORY, CONTRACT & BASELINE AUDIT CLOSEOUT
**Date:** 2026-07-17 (GMT+7) · Auditor: Claude (PM/Builder) · AUDIT-ONLY, zero mutation.

---

## A. EXECUTIVE VERDICT

**V113G.0 PASS — READY FOR G.1**

No §20 stop condition was triggered. All §16 security & governance gates verified (see F). Two evidence classes are **environment-limited** (not blockers, logged honestly): (1) static QA commands cannot be executed — no command runner exists in the available tooling (Lovable MCP is read-only for files; running scripts is impossible without `send_message`, which is prohibited in G.0 because the agent can mutate source); (2) live visual baseline cannot be captured — platform rule forbids Claude entering passwords, and no authenticated session exists; evidence-debt item 1 remains OPEN as it was.

---

## B. REPOSITORY BASELINE

- **Repository:** Lovable project `d9d56000-3cf9-4c46-9890-651edc53d73f` (GitHub auto-sync), production `demenart.com` / `demenart.lovable.app`.
- **HEAD (revision evidence):** commit `b28cd9b7844b4cb6ec7a019a8064c48f85b0a0c3` — "Fixed useFamilyArchive signature" — `2026-07-16T11:38:43Z` (latest entry in `list_edits`; all reads in this audit used `ref=HEAD` and returned this revision).
- **Branch / git status / staged / modified / untracked / merge / rebase / stash:** Lovable's model commits every change (AI or Code Editor) directly — there is no persistent dirty working tree exposed. Direct `git status` is **not available through any granted tool**; classified TOOL-LIMITED, evidenced by the full 50-entry `list_edits` history (V103 → V112C, ends at HEAD above). No in-progress migration or backend change appears in history after `2026-07-16T11:38:43Z`.
- **Toolchain:** package manager **bun** (`bun.lock`, `bunfig.toml` present); Node version UNVERIFIED (no runner); TypeScript `^5.8.3`, Vite `^8.0.16`, Tailwind `^4.2.1` (via `@tailwindcss/vite` — CSS-first config, no tailwind.config file), React 19, TanStack Router/Start `^1.168/^1.167`, `@lovable.dev/vite-tanstack-config` 2.7.6, prettier + eslint 9 flat config.
- **Scripts (package.json, exact):** `dev`=vite dev · `build`=vite build · `build:dev` · `preview` · `lint`=eslint . · `format`=prettier --write . — **no `typecheck` and no `test` script exists in the repository.** Route generation is handled by `@tanstack/router-plugin` inside vite (no standalone script).
- **Dependency install state:** UNVERIFIED (no runner); `bun.lock` present at HEAD, unchanged by this audit.

## C. CANONICAL INPUT VERIFICATION — 11/11 CANONICAL

Verified by sha256sum against the frozen package (uploads vs frozen copies, prior turn — 4 packs byte-identical; F1–F7 authoritative copies retained from the freeze session):

| Artefact | SHA-256 | Verdict |
|---|---|---|
| F1_VISUAL_SOURCE_OF_TRUTH.md | 949a65452dc5b79d6e4c7df26edc21b46307cccdf2cd8e153d605b4ab650ad3c | CANONICAL |
| F2_DESIGN_TOKEN_SPEC.md | 50527be7a00976812fe29d69d933e166fcf30f93c7e6ddbf031ba04c2f4553f1 | CANONICAL |
| F3_SCREEN_CANONICAL_MATRIX.md | 26bce1ecd17c721eef18ee9009d69692de0a28537b7b033bb3c77cee85217e92 | CANONICAL |
| F4_COMPONENT_AND_PATTERN_SPEC.md | 2e41f8b681c307037a9e3fed7c557fdf9f347aa598f9e93ab8b0b5819719f370 | CANONICAL |
| F5_RESPONSIVE_ACCESSIBILITY_MOTION_SPEC.md | 1adddd8e9b8c764deda8069083f35b8923369602045ecf8a261e2d58a8efba6a | CANONICAL |
| F6_VISUAL_QA_ACCEPTANCE_GATES.md | 2fdd3ea77400ba5c980cce9897c41a2dcb1e69c02b408b9a52dd834f1e9e7b9c | CANONICAL |
| F7_V113F_CLOSEOUT.md | 51280bc34472db9f9307d925544749c5857c78be2c4414e6844686b51236c4f0 | CANONICAL |
| DMA_Correction_Pack_1_Thanh_vien_gia_dinh.html | 3ecac896d094b85edc0ff42eb4f53962a1247ababa79942c09d2864e0714e834 | CANONICAL |
| DMA_Correction_Pack_2_Quyen_rieng_tu.html | d81673631cfdeba4ad27888707f448ed27a36484f7f8c7a5af974fe8d4e2b389 | CANONICAL |
| DMA_Correction_Pack_3_Cai_dat_Account_Utility.html | 056ff016a9cf31de5bbe2bb17cf3e4927bb8eee1cc33070d8166b29dea2190a4 | CANONICAL |
| DMA_Correction_Pack_4_Create_Flows_States.html | 4d652c1c790953e9f7e659ab831d5da6c2812b36ab5f250f74593a63c4175399 | CANONICAL |

## D. ROUTE & SHELL INVENTORY

**Source:** `src/routeTree.gen.ts` read in full at `ref=HEAD` (b28cd9b7…). **Raw `fullPaths` union = 57 entries** (includes 4 trailing-slash index aliases `/admin/ /parent/ /school/ /teacher/` and `/` root); **convention count = 52** (per established D-count method). No regeneration performed; file untouched (Change Proof, N).

**All 14 required routes present:**

| Route | Source file | Parent layout | Gate | Query params | Deep link | Nav exposure (current) |
|---|---|---|---|---|---|---|
| /parent | parent.tsx + parent.index.tsx | _authenticated | auth (parent shell) | — | yes | landing "Trang chủ" |
| /parent/journal | parent.journal.tsx | parent.tsx | auth+child link | ?focus | yes | nav "Hành trình" |
| /parent/discovery | parent.discovery.tsx | parent.tsx | auth + is_child_parent (RPC-side) | ?capsule | yes | NOT in nav (linked from Settings card "Nhìn lại") |
| /parent/family | parent.family.tsx | parent.tsx | auth + family membership (RPC-side) | (per V111D/E: section/year/month) | yes | nav "Gia đình" |
| /parent/kid | parent.kid.tsx | parent.tsx | auth (guardian contracts RPC-side) | — | yes | NOT in nav (linked from Settings) |
| /parent/consent | parent.consent.tsx | parent.tsx | auth + is_child_parent (RLS) | — | yes | NOT in nav (Settings card + "Vì sao?" links) |
| /parent/settings | parent.settings.tsx | parent.tsx | auth | — | yes | **IN primary nav (drift)** |
| /family | family.tsx | _authenticated | auth + member (RPC-side) | — | yes | standalone member shell |
| /family/memory/$cardId | family_.memory.$cardId.tsx | **_authenticated root (flat, underscore-suffix)** | auth + get_family_card generic gate | navOriginHint/year/month (search) | yes — direct entry authorized server-side | from Stream/Archive |
| /family-invite | family-invite.tsx | root (public) | token peek | token | yes | — |
| /portal/notifications | portal.notifications.tsx | portal.tsx | auth | — | yes | bell icon |
| /portal/support | portal.support.tsx | portal.tsx | auth | — | yes | links |
| /share/$token | share/$token.tsx | root (public) | token verdict | $token | yes | — |
| /kid | kid.tsx | root | PIN/device (kid contracts) | — | yes | reserved V2 |

Other portals unchanged: admin(15+index), school(6+index), teacher(8+index+session/$id), portal, auth, invite, remote, reset-password, index.

**Shell verifications (§7):**
- Guardian vs member routes **still separate**: `/parent/family` (Parent shell) vs `/family` (standalone, no Parent nav) vs shared Memory Room at root level. ✓
- Utilities in primary nav? **YES — current drift:** `Cài đặt` occupies the 4th slot in BOTH desktop header links and mobile bottom nav (`parent.tsx`). ✗ vs frozen IA (expected pre-G.1).
- Mobile nav item count: **4** (Trang chủ · Hành trình · Gia đình · Cài đặt). Count OK, composition drifted (no "Của con"; landing labeled "Trang chủ" not "Hôm nay").
- Tablet shell: **none** — current shell is a single responsive header + `sm:hidden` bottom nav; no top-bar+drawer tablet strategy exists yet (to be built in G.1).
- Shell theme: **amber** hard-coded utility classes (bg-amber-*, text-amber-*) with BookHeart icon logo — VISUAL DRIFT vs frozen emerald/ivory + official logo. `ParentChildProvider` wraps at shell level ✓ (shared persisted child context exists).

## E. COMPONENT READINESS MATRIX (34 canonical components)

Repository searched via full file listing (2 pages, complete) + targeted source reads. "CREATE NEW" issued only after the full listing showed no candidate file/symbol.

| Canonical component | Current symbol · file | Consumers | Verdict | Risk |
|---|---|---|---|---|
| Parent shell/layout | ParentLayout · routes/parent.tsx | all /parent/* | **KEEP → REFINE** (rebuild to emerald shell, keep provider/auth wiring) | med |
| ParentIdentityRail | — (header links inline in parent.tsx) | — | **CREATE NEW** (G.1) | low |
| MobileParentHeader | — (inline header) | — | **CREATE NEW** (G.1) | low |
| ParentBottomNav | BottomNavLink inline · parent.tsx | shell | **EXTRACT** → new component w/ frozen labels | low |
| FamilyExperienceShell | family.tsx route shell | /family | **KEEP → REFINE** (G.3) | med |
| FamilyIdentityHeader | in FamilyMemoryStream/family route | /family, /parent/family | **KEEP → REFINE** | low |
| ChildSwitcher | chip buttons inline ×3 (journal, discovery, index) | 3 routes | **EXTRACT** → single semantic aria-pressed component | med (Discovery local-state divergence §2.9) |
| PageTitle | inline h1 patterns | all | **EXTRACT** (serif Playfair) | low |
| MemoryHero | — (Home hero not built) | — | **CREATE NEW** (G.1 Home) | low |
| MemoryCard/MemoryItem | MemoryItem · FamilyMemoryStream.tsx (V111D composition-driven) | stream | **KEEP → REFINE** | low |
| JourneyChapter | month grouping · parentJourneyModel + JourneyRail | journal | **KEEP** | low |
| JourneyMemoryRail | JourneyRail.tsx | ParentJourneyViewer | **KEEP** | low |
| FamilySectionSwitch (Ký ức|Thành viên) | tabs in family routes (?section=) | family routes | **KEEP → REFINE** (Pack 1 styling, G.3) | low |
| ArchivePeriodIndex / FamilyArchiveNavigation | FamilyArchiveNavigation.tsx + FamilyArchiveIndex.tsx + FamilyMemoryPeriod.tsx (V112C) | archive | **KEEP** | low |
| FamilyMembers | roster section in family routes | family | **KEEP → REFINE** to Pack 1 editorial roster | med (governance affordances) |
| MemberRow / InviteRow | inline rows | roster | **EXTRACT** (Pack 1 grammar) | low |
| MemoryRoomMedia / MemoryProvenance / FamilyVoices / PreservePanel / LifecycleMenu | memoryRoomShared.tsx + FamilyMemoryRoom.tsx (V111E) | Memory Room | **KEEP → REFINE** (order per frozen dual-viewport spec, G.4) | med |
| KidGatewayHero / KidSafetyStatus | parent.kid.tsx sections | /parent/kid | **KEEP → REFINE** (G.5) | low |
| PrivacyGroup | parent.consent.tsx sections | /parent/consent | **KEEP → REFINE** to Pack 2 (9 types / 4 groups presentation; write path untouched) | high (consent surface) |
| SettingsGroup | parent.settings.tsx CardLink grid | /parent/settings | **KEEP → REFINE** to Pack 3 | low |
| PasswordCard | PasswordCard · parent.settings.tsx | settings | **KEEP** — already new+confirm only, autocomplete=new-password, no current-password, no prefill (matches Pack 3 contract; visual refine only) | low |
| ParentMemoryComposer | ParentMemoryComposer.tsx + useParentMemoryComposer | journal | **KEEP → REFINE** (Pack 4, G.7) | med |
| FamilyCardComposer | FamilyCardComposer.tsx + useFamilyCardComposer | family | **KEEP → REFINE** (Pack 4, G.7) | med |
| Family contribution entry | in Memory Room voices/composer | Memory Room | **KEEP → REFINE** (Pack 4 frame) | med |
| VoiceRecorder | recorder inside composers | composers | **VERIFY-IN-G.7** — symbol location UNVERIFIED at file level (inside composer files, not standalone); likely **EXTRACT** | med |
| MediaPicker | media selection inside composers | composers | same as above — **EXTRACT** in G.7 | med |
| TruthStateBlock | **FamilyStateBlock.tsx** + familyExperienceGrammar.ts (V111B/C) | family surfaces | **KEEP → REFINE** (extend to 9 Pack-4 visual variants + a11y roles, G.8; reuse across Parent) | med |
| reserved-media primitive | ad-hoc (skeleton + fixed boxes per surface) | various | **EXTRACT** → single primitive (G.1 foundation) | low |

**CONFLICT: none found. NOT FOUND (no symbol anywhere): ParentIdentityRail, MobileParentHeader, MemoryHero → CREATE NEW.**

## F. CONTRACT & GOVERNANCE MATRIX (verified live)

**DB inventory (execute_sql):** 87 tables · **190 secdef** · 164 policies · 1 cron · **101 migrations** — matches v112F canonical. Data: memory_cards 16 = 15 active/1 archived · child_journey 37 · preserve_records 5 = 1 active/3 reversed/1 orphaned · consents 37 rows.

| Surface | Reads | Writes | Contract path | Predicate | Protected behavior | Verification |
|---|---|---|---|---|---|---|
| Parent/Journey | get_child_journal RPC; get_signed_media_url Edge (per-media) | archive_parent_memory / restore_parent_memory RPC | RPC+Edge | is_child_parent; pm.mine for edit/archive | consent_missing → "Đang chờ ba mẹ đồng ý" + Vì sao?→/parent/consent; moment_not_approved → hidden; distinct child-fetch vs journal-fetch errors | VERIFIED (source read) |
| ParentChildProvider | child_parents → children | — | shell-level provider, persisted selection | is_child_parent (RLS) | — | VERIFIED (parent.tsx) |
| Discovery | get_child_evidence_readiness, list/get_discovery_capsules | generate_discovery_capsule | RPC-only | is_child_parent (in-fn) | idempotent per evaluation_date | VERIFIED (see G) |
| Family Archive | get_family_space, get_family_stream_presence, get_family_memory_window, get_family_archive_index, get_family_archived_cards | create_family_card, mint/revoke invitation, remove_family_member, archive/restore | RPC | is_family_space_guardian / is_family_space_member / has_family_capability(create_card, invite_member) | guardian_member_protected in remove path; member read-only | VERIFIED (secdef list; frontend mount per V111D–V112C commits — frontend line-level read deferred to G.3 prep, marked PARTIALLY EVIDENCED) |
| Memory Room | get_family_card (+engagement, preserve-context) | contribute/react/preserve/reverse_preserve, lifecycle RPCs | RPC | family_card_effective_access (membership+active+child-link consent, source read); per-capability flags in payload | **generic `not_found_or_not_authorized` string PRESENT in get_family_card prosrc** — outsider ≡ non-existent, no enumeration | VERIFIED (SQL) |
| Kid | kid_access/kid_devices | kid_update_access, kid_set_pin, kid_create_pairing_code, kid_revoke_device (+ kid_*_service) | RPC | guardian-side contracts | reason/verdict grammar server-side | VERIFIED (secdef list) — UI wording read deferred |
| **Consent** | consents (SELECT: is_child_parent OR child_in_my_school) | **DIRECT TABLE RLS** — INSERT `consents_insert_parent`; UPDATE `consents_update_parent` = is_child_parent(child_id) AND parent_profile_id = current_profile() | direct write, **no RPC** (F9 parked 🔒 — unchanged) | is_child_parent + own-row | MIN-consent enforced downstream in media gates (media_consent_check, get_signed_media_url) | VERIFIED (pg_policy read) |
| Consent types | **exact 9 in enum** (SQL enum_range): display_in_app, group_moment_in_class, download, private_share_link, school_internal_comm, school_external_marketing, demen_marketing, privacy_ack, family_space_display | — | — | — | family_space_display default-off = absence-of-row semantics (7/9 types present in data; school_internal_comm & school_external_marketing have no rows yet) | VERIFIED |
| Settings | profile (read-only roster via provider) | supabase.auth.updateUser({password}) | supabase-js auth | authenticated user | new+confirm only; **no 2FA/export/delete/billing anywhere in repo** — confirmed absent | VERIFIED (full source read) |
| Create flows | composer hooks | create_family_card / create_card_contribution / parent memory RPCs; finalize_family_card_media_attachment | RPC | create_card capability gate | audiences = existing private contexts only | secdef VERIFIED; composer internals deferred to G.7 prep (PARTIALLY EVIDENCED) |
| No merged predicate | — | — | — | **no `canManage` exists** (function list exhaustively searched: none) | — | VERIFIED |

## G. DISCOVERY VERDICT — **DETERMINISTIC CONFIRMED** (evidence-debt item 5 → CLOSED WITH EVIDENCE)

- **Exact source:** RPC `generate_discovery_capsule` (prosrc read in full): pure SQL — `is_child_parent` guard → window (current_3m/6m/12m) → `compute_child_evidence_readiness` eligibility → `build_discovery_candidates_internal` candidates ordered **deterministically** (claim_strength tier → group_count → pattern_key), limit 6 general / 2 domain → canonical jsonb → **md5 payload_hash** → per-day **idempotency** (same semantic key + evaluation_date returns existing capsule; ON CONFLICT DO NOTHING race-safe). `readiness_policy_version='v2'`, `discovery_version='d1'`.
- **AI/model/http call:** **NONE.** Same input on the same evaluation_date → same capsule (stable).
- **Frontend:** parent.discovery.tsx is RPC-only (generate/get/list + readiness); `?capsule=` param contract.
- **Child selector:** **route-local** — local `useState(selectedChildId)`, loads `child_parents` itself ("mirrors parent.index.tsx"), **NOT bound to ParentChildProvider**. Issue §2.9 confirmed → G.2 must rebind to shared context (client-only).
- **Copy safety:** current "Bản Khám Phá Nghệ Thuật" + "Nhìn lại những gì hành trình của con đang dần cho thấy — từ chính các hoạt động và khoảnh khắc đã được ghi nhận" is evidence-anchored — SAFE. **G.2 reflection language boundary:** may describe observed patterns and their evidence; must NOT imply analysis, judgment, assessment, or AI insight.

## H. JOURNEY SHARE VERDICT — **DEAD-BRANCH DEPENDENCY** (evidence-debt item 6 → CLOSED WITH EVIDENCE for location; re-homing remains a product decision)

- **Symbol:** `ShareMomentButton` defined **inside `src/routes/_authenticated/parent.journal.tsx`** (moment scope). Contract: reads `share_links` (creator-only SELECT), RPC `create_private_share_link` (p_ttl_minutes=1440), RPC `revoke_share_link`, copies `/share/{token}`.
- **Sole consumer:** `CompactMomentLeaf` (same file) — rendered **only** in the timeline else-branch. That branch is **DEAD**: `const [viewMode] = useState("journey")` has no setter; `JourneyViewToggle` is imported type-only; the mounted branch is always `ParentJourneyViewer`.
- **Mounted branch renders Share?** **NO** — ParentJourneyViewer mounts JourneyDetail + JourneyStage + JourneyRail + MemoryConversation only (all imports read); JourneyDetail (read in full) has Sửa/Lưu trữ/Bỏ giữ/conversation, no Share.
- **Duplicates:** none (single implementation).
- **If dead branch is deleted:** moment-scope Share UI is lost entirely (backend RPCs remain). → **PRESERVE now; re-home decision belongs to PO before/within G.2.** G.1 must not touch parent.journal.tsx.

## I. VISUAL BASELINE — ENVIRONMENT-LIMITED

No screenshots captured. **Environment truth:** capturing authenticated production routes requires login; the platform rule prohibits Claude from entering passwords/credentials, and no pre-authenticated browser session was available in this audit session. No production data was mutated; no unauthorized account used. **Evidence-debt item 1 remains OPEN.** Recommended minimal corrective path (for the human, outside G.0): Jean logs `ph.hung.kidshouse@demo.demenart.com` / `Test@123` into a Chrome tab with the Claude extension, then a follow-up capture session records the 1440/768/390 matrix per §14 with environment=production labels.

## J. STATIC QA BASELINE — ENVIRONMENT-LIMITED, NOT EXECUTED

- No command runner exists in the granted tooling (Lovable MCP exposes file read/list/edit-history only; `send_message` is the only execution path and is prohibited in G.0 as mutation-capable). Failure classification for all four checks (typecheck/lint/test/build): **environment**.
- Repository facts: **no `typecheck` script and no test runner/test files exist** (script list in B); `lint` and `build` exist but were not run. Tracked-file integrity was never at risk: **zero write-capable tool calls were made** (see N).

## K. RISK MAP G.1–G.8 (sequence: KEEP as approved — no dependency contradicts it)

| Sprint | Deps | Likely files | Top risks | Rollback boundary | Evidence prereq |
|---|---|---|---|---|---|
| **G.1 Foundation + Hôm nay** | none | parent.tsx, parent.index.tsx, styles.css, new shell components | authority: none; responsive: tablet drawer new; a11y: focus/target foundation | 1 isolated commit; revert restores amber shell | this audit |
| **G.2 Hành trình + Discovery** | G.1 shell | parent.journal.tsx, journey/*, parent.discovery.tsx | **Share dead-branch (H)** — re-home or explicit defer BEFORE deleting timeline branch; Discovery child-selector rebind (G); data-contract: get_child_journal untouched | 1 commit | PO decision on Share |
| **G.3 Gia đình + Thành viên** | G.1 | parent.family.tsx, family.tsx, FamilyMemoryStream, roster | authority: guardian-only controls (Pack 1); duplicate guardian/member components audit at file level | 1 commit | member-session debt (item 2) still open — member view verified by code review + guardian session |
| **G.4 Memory Room** | G.1, G.3 | FamilyMemoryRoom, memoryRoomShared | dual-viewport frozen order; generic denial preserved; navOriginHint stays UX-only | 1 commit | audio/text-only card capture (item 3) |
| **G.5 Thế giới của con** | G.1 | parent.kid.tsx | kid contracts untouched; reason grammar | 1 commit | — |
| **G.6 Quyền riêng tư + Cài đặt** | G.1 | parent.consent.tsx, parent.settings.tsx | **consent surface = highest authority risk**: presentation-only, write path (direct RLS) unchanged, 9 types, no page Save, failed-write shows persisted value | 1 commit | — |
| **G.7 Composers + Recorder + Picker** | G.1, G.4 | composers, extract VoiceRecorder/MediaPicker | create_card gate rendering; 2-min cap; no autoplay; aria-pressed | 1 commit | — |
| **G.8 Truth States + a11y + regression** | all | FamilyStateBlock→TruthStateBlock, all routes | 9 distinct variants + roles; full F6 harness run; regression across 14 routes | 1 commit | F6 gates |

## L. V113G.1 RECOMMENDED EXACT SCOPE — Foundation + Hôm nay canary

**Existing files allowed to change (exact):**
`src/routes/_authenticated/parent.tsx` · `src/routes/_authenticated/parent.index.tsx` · `src/styles.css`

**New files allowed (exact proposed paths):**
`src/features/parent/shell/ParentIdentityRail.tsx` · `src/features/parent/shell/MobileParentHeader.tsx` · `src/features/parent/shell/ParentBottomNav.tsx` · `src/features/parent/shell/ParentTabletBar.tsx` (top bar + drawer) · `src/features/parent/shell/parentNav.ts` (frozen 4-destination model) · `src/features/parent/ChildSwitcher.tsx` (semantic button group, consumed by Home in G.1; adopted by journal/discovery in G.2) · `src/features/shared/ReservedMedia.tsx` · `src/features/shared/TruthState.tsx` (foundation grammar only; full 9-variant completion in G.8) · `src/features/parent/home/MemoryHero.tsx`

**Prohibited (must not change):** `package.json` · `bun.lock` · `src/routeTree.gen.ts` · `supabase/**` (migrations/SQL) · `src/integrations/supabase/types.ts` · any RPC/RLS/Edge · consent contracts & `parent.consent.tsx` · `parent.journal.tsx` (Share dead branch inside) · `parent.discovery.tsx`, `parent.family.tsx`, `parent.kid.tsx`, `parent.settings.tsx`, `family*.tsx`, all admin/school/teacher/portal/kid/share routes · `src/features/journey/**`, `src/features/family/**`, `src/features/discovery/**`.

**Foundation strategy:** F2 tokens as CSS variables in `styles.css` `@theme` layer (emerald/ivory/champagne/sage + ink set); Playfair Display + Be Vietnam Pro font loading (self-host or fonts pipeline — no package change, so CSS `@font-face`/link in root); Parent shell boundary = ParentLayout keeps ParentChildProvider + auth/sign-out/notification wiring intact, swaps chrome only; desktop rail per L2; tablet = top bar + navigation drawer (frozen); mobile = MobileParentHeader + ParentBottomNav with labels **Hôm nay · Hành trình · Gia đình · Của con** (desktop 4th = "Thế giới của con"); utilities (Cài đặt, Quyền riêng tư, Thông báo, Hỗ trợ) move to rail-utilities/header affordances — **route surface unchanged, only nav exposure**; ChildSwitcher aria-pressed; TruthState + ReservedMedia primitives; focus-visible ring, reduced-motion guards, safe-area padding var, ≥44px targets.

**Home composition plan (parent.index.tsx):** identity ("Hôm nay của {child}") + **one real newest media-bearing item** (from existing journal payload — newest of creations/moments/parent-memories with media) + **one primary action** (Ghi lại → journal composer path) + quiet supporting cards (Hành trình, Gia đình signal via get_family_stream_presence if space exists) + **no KPI block**; error state distinct from empty (TruthState foundation).

**Fixtures (existing, no production fixtures created):** populated child = **An** (22+ source memories, journey 37 entries); near-empty child = **Khang**; no-data = account with zero linked children (available: gv/other roles — or Hùng with child filter, PO to confirm); child-fetch error & journal error = simulated via devtools offline/network block during validation (no data mutation).

**Validation:** `bun run lint` + `bun run build` (exit codes recorded); screenshot matrix Home+shell at 1440/768/390 × populated/near-empty/empty/error; governance checks = routes unchanged (`routeTree.gen.ts` hash identical), no consent/journal contract calls added/removed; regression routes = /parent/journal, /parent/family, /parent/consent, /parent/settings, /portal/notifications still render inside new shell; console/network clean.

**Rollback:** single isolated commit; reverting it restores the current amber shell exactly; no migration, no dependency, no route-tree delta.

## M. EVIDENCE-DEBT LEDGER (six items)

| # | Item | Status | Evidence |
|---|---|---|---|
| 1 | Production live visual baseline | **OPEN** | blocked: credential-entry prohibited + no live session (I) |
| 2 | Safe non-guardian member live session | **OPEN** | no safe member account exercised |
| 3 | Audio-only & text-only family-card capture | **OPEN** | live DB re-confirms 0 such cards among 16 |
| 4 | Invitation expired/revoked visual treatments | **OPEN** | no source at any level |
| 5 | Discovery deterministic/generative | **CLOSED WITH EVIDENCE** | full prosrc of generate_discovery_capsule (G): SQL-only, idempotent, no AI |
| 6 | JourneyDetail Share re-homing | **PARTIALLY EVIDENCED** | location/consumers fully proven (H: DEAD-BRANCH DEPENDENCY); the re-homing *decision* remains with PO |

## N. CHANGE PROOF

- source files changed: **0**
- route files changed: **0**
- package or lockfile changed: **0**
- SQL or migrations changed: **0**
- generated types changed: **0**
- deployment performed: **NO**

Method proof: every repository access used read-only tools (`list_edits`, `list_files`, `read_file` at ref=HEAD) and every database access used read-only `execute_sql` SELECTs; no write-capable tool (`send_message`, `apply_migration`, `deploy_*`, INSERT/UPDATE/DELETE) was invoked at any point. `routeTree.gen.ts` therefore cannot have changed: proof = zero write calls + all reads pinned to the same HEAD `b28cd9b7…`. Migration count before/after audit: 101 = 101.

## O. NEXT ACTION

Return this audit to ChatGPT and Product Owner for review. Do not begin V113G.1 until a new execution prompt is explicitly approved.
