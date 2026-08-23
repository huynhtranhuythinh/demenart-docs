# DMA V113G.1 — FOUNDATION + HÔM NAY CANARY · CLOSEOUT (A–M)
2026-07-17 (GMT+7) · Claude PM/Builder · Amendment-governed run. **NO DEPLOY PERFORMED.**

## A. VERDICT
**V113G.1 PASS — READY FOR CTO/PO VISUAL REVIEW**
All amended static-QA gates PASS. Implementation complete in the working repository copy; delivery = byte-exact paste package (Jean's default workflow). Claude PASS ≠ PO PASS: visual acceptance across the frozen viewport matrix happens after paste, in the next review step.

## B. BASELINE OF RECORD (unchanged, re-verified AFTER)
HEAD `b28cd9b784…c48f85a0a2c3`-series commit `b28cd9b7844b4cb6ec7a019a8064c48f85b0a0c3` · lint baseline KNOWN-FAIL **4,945E/32W** (`lint_before.txt`) · build baseline exit 0 (`build_before.txt`) · protected fingerprints BEFORE = AFTER (byte-identical):
routeTree.gen.ts `b847dd43…c79f85` · package.json `c17c637b…2e08d5b` · bun.lock `f48ebf90…dcd69bdb` · types.ts `da30c469…4a3a6f17` · raw fullPaths **57** / convention **52** · migrations **101**. Zero backend calls that mutate; zero route-tree regeneration.

## C. FILES DELIVERED — exactly the approved scope (12)
**Changed (3):** `src/styles.css` · `src/routes/_authenticated/parent.tsx` · `src/routes/_authenticated/parent.index.tsx`
**New (9):** `src/features/parent/shell/{parentNav.ts, ParentIdentityRail.tsx, ParentTabletBar.tsx, MobileParentHeader.tsx, ParentBottomNav.tsx}` · `src/features/parent/ChildSwitcher.tsx` · `src/features/shared/{TruthState.tsx, ReservedMedia.tsx}` · `src/features/parent/home/MemoryHero.tsx`
Per-file SHA-256: `MANIFEST.sha256.txt` in the paste package. No other file touched.

## D. FOUNDATION (Phase 1)
Google Fonts `@import` (Be Vietnam Pro + Playfair Display) as line 1 of styles.css (no package change). Appended **V113G.1 DMA PARENT FOUNDATION LAYER**: all frozen F2 hexes as `--dma-*` custom properties; `@theme inline` registrations exposing `bg-dma-emerald`, `text-dma-ink`, `font-dma-serif`, etc.; frozen breakpoint grammar via `--breakpoint-dtab: 401px` → mobile = default ≤400, tablet = `dtab:` 401–1023, desktop = existing `lg:` ≥1024; activation scoped to `.dma-parent` (other portals + FMN layers untouched); champagne focus-visible ring grammar; reduced-motion hard gate; safe-area vars; `--dma-bottomnav-h`/`--dma-rail-w`.

## E. SHELL (Phases 2–5)
`parentNav.ts` freezes the four primaries (Hôm nay · Hành trình · Gia đình · Thế giới của con/„Của con") + utility set (Quyền riêng tư, Thông báo, Cài đặt, Hỗ trợ) — **utilities removed from primary navigation on every device class**. Desktop: emerald-identity rail (official logo-banner on ivory plate, aria-current page, champagne active indicator, utilities section, quiet account/Đăng xuất footer). Tablet: sticky top bar + Radix-Sheet drawer (labelled dialog, focus containment, Esc, backdrop close, focus restore). Mobile: sticky safe-area header (logo + bell) + fixed four-item bottom nav, item 4 = **„Của con"**, main content reserves bottom-nav height. `parent.tsx` preserves exactly: ParentChildProvider, auth/sign-out contract, notification polling + realtime, InAppBrowserNotice, Outlet. `as any` casts REMOVED (typed client calls — `notifications` table and `get_child_journal` exist in generated types).

## F. HÔM NAY (Phases 6–7)
Canonical order implemented: identity (serif „Hôm nay của {con}") → shared ChildSwitcher (aria-pressed, ≥44px, persisted context; G.1 adoption boundary respected — Journey/Discovery untouched) → **MemoryHero** (reserved 16:9 media, gold-ink kind eyebrow, serif title, ONE primary „Xem ký ức này" deep-linking `/parent/journal?focus={id}` with the exact timeline id scheme `journey:|creation:|moment:`) → contextual create (secondary when hero exists; sole primary inside truthful empty) → two quiet supporting areas (Hành trình link with counts ONLY as quiet metadata „Đã lưu N điều · P do ba mẹ ghi lại"; Cùng con hôm nay tips) → Recent strip (3 real items, each deep-linked) → quiet family signal from **preserved journal entries only** (no family RPC added) → Nhìn lại + Thế giới của con quiet links. **KPI tile grid and seed/badge chips removed.** Hero selection deterministic and documented: first `buildParentTimeline` event (occurredAt DESC, stable) carrying usable visual media (moment.media_id → drawing.media_id → first image of parent-memory/family-preserve gallery); media-less items are never selected over media-bearing ones. Hero signing via existing `get_signed_media_url` Edge with in-box failure + Thử lại (ReservedMedia — no collapse, no layout shift, no broken icon). Data contracts unchanged: `get_child_journal` + Edge signing; composer save→journal-focus flow preserved.

## G. TRUTH STATES (Phase 4 foundation)
`TruthState` (loading `role=status/aria-busy` · empty labelled/described, warm, ZERO-or-one action · error `role=alert`, dma-error left rule, retry) — error ≠ empty visually and semantically. Journal failure now renders the error variant with „Thử lại" (F01/E4 class fixed on Home). `ReservedMedia` reserves aspect before resolution for all four states. Full nine-variant system remains V113G.8 scope by design.

## H. REGRESSION SURFACE
All other `/parent/*` + `/family*` + portal routes render inside the new shell via unchanged `<Outlet/>`; their content files are untouched (mixed amber-on-ivory interiors are expected mid-migration and are G.2–G.8 scope). Full build passing (below) covers route-tree integrity; visual regression walk happens in the post-paste review.

## I. STATIC QA AMENDMENT EVIDENCE
- Baseline: `lint_before.txt` — **4,945 errors / 32 warnings**; build_before exit 0.
- Targeted Prettier: `prettier --write` then `--check` on exactly the 12 G.1 files → **All matched files use Prettier code style! (PASS 12/12)**.
- Targeted ESLint: `eslint` on the 11 TS/TSX G.1 files → **0 errors / 0 warnings** (styles.css is outside ESLint config by repository design; format-verified by Prettier).
- Full lint after: `lint_after.txt` — **4,937 errors / 32 warnings** → Δ **−8E / ±0W** (reduction sourced only from clean formatting of the two authorized changed files; ≤ baseline ✓).
- G.1-origin findings in full lint: **grep across all 12 G.1 paths → zero matches**.
- Rule-ID sets before vs after: **identical** (no new rule category).
- Full build after: **exit 0** (`build_after.txt`), no new build or route-generation error. Informational: `tsc --noEmit` exit 0.
- No lint/Prettier config changed; no repo-wide formatter/fixer run; no eslint-disable comments; no ignore patterns.

**KNOWN PRE-EXISTING LINT DEBT PRESERVED OR REDUCED; G.1 INTRODUCED ZERO NEW LINT DEBT.**

## J. CHANGE PROOF
route files changed beyond the 2 approved: 0 · package/lockfile: 0 · SQL/migrations: 0 · generated types: 0 · routeTree regenerated: NO (hash identical) · RPC/RLS/Edge/consent/Journey-Share/Discovery/Family governance: untouched · **deployment: NO**.

## K. FIXTURES & VISUAL MATRIX (next step, after paste)
Populated = **An** (hero expected: newest visual item, e.g. Tác phẩm 14/07) · near-empty = **Khang** (report actual) · true-empty = a real parent account with zero linked children (admin session is NOT a valid fixture — reconfirmed live in G.0B) · errors via devtools network blocking. Viewports per execution prompt: 1440/1024 (rail) · 1023/768/500/401 (tablet bar+drawer — NOTE: 500px switches from legacy mobile to tablet by frozen grammar) · 400/390 (mobile header+bottom nav). Capture via Chrome extension on production/preview after paste; 390 exact-width via the agreed iframe technique or honest environment note (Chrome/macOS min-width ≈500).

## L. ROLLBACK
Single paste-set: re-pasting the three prior file bodies and deleting the nine new files restores the amber shell exactly. No migration, no dependency, no route-tree, no data.

## M. OPEN ITEMS → NEXT ACTION
Open: (1) ParentChildProvider collapses child-fetch errors to `[]` (pre-existing; error-vs-no-children indistinguishable at shell level — G.2+ candidate); (2) favicon remains generic amber „D" (out of scope); (3) visual matrix + PO acceptance pending. **Next action:** Jean paste 12 files theo MANIFEST (full paste-over, D8 read-back sau mỗi file) → em chạy visual matrix trên preview → CTO/PO review. **KHÔNG deploy · KHÔNG bắt đầu V113G.2.**
