# F5 — RESPONSIVE, ACCESSIBILITY & MOTION SPEC
**V113F** · How the one system behaves across viewports, for assistive tech, and in motion. Mobile is **recomposed, not scaled-down desktop**.

---

## 1. Breakpoint behavior

### Desktop — 1440 (design), ≥1024 (applies)
- Fixed **ParentIdentityRail** left (target width ~260px; `⚠ CONFIRM` exact against L2). Content area to the right on ivory, centered with a max-width content column (~880–960px reading measure; `⚠ CONFIRM`) plus optional right sidebar (Journey reflection / Family saved rails / Room provenance+preserve).
- Two-column compositions (Home hero, Journey hero+reflection, Room media+meta) sit side-by-side.

### Tablet — 401–1023  ✅ LOCKED (V113F-C §3)
- **Top bar + navigation drawer.** The desktop identity **rail is removed**; do **not** use an icon rail.
- **Top bar** preserves family/child identity (family name + ChildSwitcher/child chips + logo).
- **Navigation drawer** (slide-in) holds the same **four primaries** (Hôm nay · Hành trình · Gia đình · Thế giới của con) **and** the utilities (Quyền riêng tư/Cài đặt/Thông báo/Hỗ trợ/Sign out).
- Two-column heroes reflow to single column; desktop **right sidebars move below** primary content, order preserved.
- Content column widens with generous gutters; **no dense tablet mode.**

### Mobile — 390–400 (design 390)
- **MobileParentHeader** (sticky top) + **ParentBottomNav** (4 items, fixed bottom).
- Everything single-scroll, single-column. Heroes = media-over-text. Right sidebars become **collapsible sections** in content order (e.g. Room: voices → preserve → provenance → admin).
- ChildSwitcher = chip row under header (Home/Kid) or in header profile (Journey/Room).

**Recompose rule:** never shrink a desktop 3-column grid to fit 390. Re-author the stack: identity → one memory → one action → supporting sections → nav.

## 2. Safe-area & bottom-nav reservation
- Respect `env(safe-area-inset-top/bottom/left/right)`.
- **ParentBottomNav** reserves its own height **plus** bottom inset; content bottom padding = navHeight + safe-inset so the last item is never occluded.
- Sticky header reserves top inset.
- No content, CTA, or toast may sit under the bottom nav; toasts anchor above it (`--z-toast` > `--z-bottom-nav`).

## 3. Rail collapse & nav continuity
- The 4 primaries + labels are identical across rail (desktop) and bottom nav (mobile); only chrome differs.
- Utilities (Quyền riêng tư/Cài đặt/Thông báo/Hỗ trợ/Sign out) live behind the account/identity menu on all sizes — never in the 4-slot bar.

## 4. Tab, sheet & accordion behavior
- **FamilySectionSwitch** (`?section=`): desktop = inline tabs; mobile = segmented control, direct-entry addressable; state survives back/return.
- **ArchivePeriodIndex:** desktop = persistent timeline rail; mobile = bottom **Sheet** (`--z-sheet`) + year chips.
- **Accordions** (Kid controls, Room mobile sections): one open at a time optional; chevrons; keyboard-operable; state not lost on scroll.

## 5. Content order changes (desktop → mobile)
| Surface | Desktop | Mobile order |
|---|---|---|
| Home | rail + hero(media/text side) + context row + strip | title → child chips → hero → CTA → context cards → recent strip |
| Journey | hero + reflection sidebar + timeline | hero chapter → reflection card → memory rail |
| Family | identity + tabs + archive + saved sidebar | identity chips → tabs → filter → period grid |
| Memory Room | media/story left + preserve/provenance/admin right | return → media → title/story → voices → preserve → provenance → admin |
| Kid | gateway media + status column + panels | gateway → primary action → status grid → collapsible controls |

**Invariant:** Memory Room order (return → media → title/story → provenance → voices → preserve → lifecycle) holds on both; mobile collapses later sections, never reorders past media.

## 6. Media aspect ratios & layout-shift prevention
- Reserved frames: hero 16:9 (or 4:3 for portrait child media), MemoryCard 4:3, Room player 16:9. Height reserved **before** the signed URL resolves.
- Use intrinsic aspect-ratio boxes so signed-media latency never reflows the page.
- Skeleton/placeholder occupies the exact final box (see §11).

## 7. Dialog & keyboard handling
- Dialogs (invite, confirm-remove, delete-confirm) trap focus, restore focus on close, close on Esc + backdrop (non-destructive), `aria-modal`, labelled by title.
- Destructive dialogs require explicit confirm; default focus on the **safe** (cancel) action.
- On-screen keyboard (mobile composer): inputs scroll into view above the keyboard; bottom nav yields to keyboard; submit remains reachable.

## 8. Minimum tap targets
- ≥ 44×44px for all interactive controls (nav items, kebab, chips, toggles, player controls). Icon-only controls carry visible focus + accessible label.

## 9. Focus states
- `:focus-visible` = 2px champagne ring, 2px offset, on both emerald and ivory (contrast-verified). Never remove focus outlines. Logical tab order follows visual reading order (mobile content order above).

## 10. Contrast requirements (WCAG)
- Body/metadata text ≥ **4.5:1**; large titles ≥ **3:1**.
- Check the risk pairs: `--color-ink-metadata` `#6D716B` on ivory; `--color-ink-on-emerald-muted` `#B7C6BB` on emerald. **Gold text on ivory is resolved (V113F-C):** always use `--color-ink-gold` `#806A35` for gold text; the decorative champagne `#C8AA6A` is never used as text. Verify `#806A35` on `#FCF7F0` ≥ 4.5:1 in the diacritic QA pass.
- Status colors must not rely on hue alone (add icon/label): error/denied/consent distinguishable for color-vision deficiency.

## 11. Signed-media loading placeholders
- Every signed-media slot shows a same-size placeholder (soft ivory/sage block + quiet spinner) until resolved.
- On failure → **media-unavailable** TruthState in the same box (retry), never a broken-image icon, never collapse to zero height.
- Consent-gated media → **consent-needed** overlay in the box + "Vì sao?" → consent; never silent blank.

## 12. Reduced motion
- `prefers-reduced-motion: reduce` → opacity-only transitions, no slides/scale, no botanical animation, no recorder pulsing; instant tab/section changes; media never autoplays regardless.

## 13. Screen-reader labels (representative)
- Rail/bottom nav items: role `link`, `aria-current="page"` on active.
- ChildSwitcher: `role="listbox"`/options, selected child announced ("An, 3 tuổi 2 tháng, đang chọn").
- MemoryCard: title as accessible name; media type + date in label; kebab = "Tùy chọn cho {title}".
- Player: standard media labels (play/pause, seek, time, fullscreen).
- Preserve toggle: state announced ("Đã giữ vào Hành trình của An" / "Chưa giữ").
- TruthStateBlock: `role="status"` for loading/consent-waiting; `role="alert"` for error; denied announced without leaking existence (generic).
- Provenance "mã ký ức": readable but not focus-trapping.

## 14. Responsive readiness

| Area | Status |
|---|---|
| Desktop 1440 composition | ✅ specified (rail widths `⚠ CONFIRM`) |
| Mobile 390 recomposition | ✅ specified for all primaries + Room |
| Tablet | ✅ **LOCKED (V113F-C)** — top bar + navigation drawer, no icon rail |
| Safe-area / bottom-nav reservation | ✅ |
| A11y (contrast/focus/SR/tap) | ✅ specified; **gold text uses `--color-ink-gold` `#806A35`** (resolves gold-on-ivory contrast); decorative champagne `#C8AA6A` never used as text |
| Motion / reduced-motion | ✅ |
| Signed-media / layout-shift | ✅ |
