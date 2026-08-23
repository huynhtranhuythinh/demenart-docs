# A5 — MOBILE EXPERIENCE AUDIT
**V113A** · Target viewport 390–400px.

> **Evidence status:** The production browser-evidence branch is **BLOCKED** — the connected-browser MCP was unresponsive (4-minute timeout, flagged likely to repeat). Per the B+ STOP rules ("browser instability prevents trustworthy evidence"), only this evidence branch is stopped. **No runtime mobile capture exists.** Everything below is **`OBSERVED_SOURCE`** (layout intent from the component tree). Per the audit's own rule, mobile runtime behavior must **not** be asserted from Tailwind classes alone — so each item is marked *intent* and paired with the exact capture needed to confirm. Runtime verdicts (layout shift, sheet height, safe-area, keyboard) are **UNKNOWN — NOT TESTABLE (browser unavailable)**.

---

## 1. Global mobile chrome (`OBSERVED_SOURCE` `parent.tsx`)

- **Bottom-nav:** fixed `inset-x-0 bottom-0 z-40`, `sm:hidden`, `grid-cols-4`, each item `min-h-[56px]` (≥44px target intent — good). `backdrop-blur`. Labels `text-[11px]`.
- `main` uses `pb-28 sm:pb-8` — reserves ~112px for the bottom-nav on mobile (intent: content not occluded).
- **Header** stays visible (not sticky in source; scrolls with page). On mobile the name is `hidden md:block`; the header row = logo + 4 hidden-on-mobile desktop links (`hidden sm:inline-flex`) + Bell + Đăng xuất. → on mobile the top row is logo + Bell + Đăng xuất only (desktop nav hidden), primary nav lives in the bottom bar.
- **Runtime UNKNOWN:** whether the fixed bottom-nav collides with iOS Safari bottom bars / safe-area; whether `z-40` sits correctly under Sheets (`z-50`). Must be captured.

## 2. Per-surface mobile intent + required capture

| Surface | Source intent (mobile) | Runtime risk (must capture) | Required screenshot |
|---|---|---|---|
| `/parent` Home | single column; Hero `p-8`; CTA `w-full sm:w-auto`; count tiles `grid-cols-2 sm:grid-cols-4`; child chips `flex-wrap` | Hero height vs fold; count-tile block pushing media further down | `V113A_guardian_parent-home_an_mobile390.png`, `..._khang_mobile390.png` |
| `/parent/journal` | h1+chips+"Ghi lại"; then `ParentJourneyViewer` (fixed-height stage per D224-B `h-[46vh] max-h-[46vh]`, story in bottom Sheet) | stage fits without header eating fold (D224-B note: header nén on mobile); Sheet `max-h-[80vh]` | `V113A_guardian_journey_an_mobile390.png` |
| `/parent/family` | archive `lg:grid` collapses to single column; "Dòng thời gian" button opens **left Sheet** `w-[85vw] max-w-sm`; members/invites stack below | archive **inside a Card** inside `max-w-4xl` — card padding on 390px; Sheet height; dense member action rows (X buttons) | `V113A_guardian_family-newest_mobile390.png`, `V113A_guardian_family-members_mobile390.png` |
| `/family` (member) | own shell `max-w-3xl`; member list read-only; same archive collapse | different width/shell vs `/parent/family` at 390px | `V113A_member_family-home_mobile390.png` (**NOT TESTABLE — no safe member session**) |
| `/family/memory/:cardId` Room | cream full-screen, **no bottom-nav**; media tiles stacked; dialogs for edit/contribute | video intrinsic-height shift; audio bar; contribution dialogs on 390px; recorder mic button | `V113A_guardian_memory-room-image_mobile390.png`, `..._text_mobile390.png`, `..._audio_mobile390.png` |
| composer (`ParentMemoryComposer` / `FamilyCardComposer`) | shadcn Dialog | Dialog height + on-screen keyboard behavior with Textarea; file input | `V113A_guardian_composer_mobile390.png` (open only, **no submit**) |
| `/parent/consent` | grouped Switch cards, `divide-y` rows | tap target of `Switch`; long helper text wrap | `V113A_guardian_consent_mobile390.png` |
| `/parent/kid` | cards; `InputOTP` 4 slots; `type=time` inputs `w-32`; pairing code `text-4xl` | native time picker on mobile; OTP focus; device rows | `V113A_guardian_kid_mobile390.png` |
| `/parent/settings` | `grid sm:grid-cols-2` → single col; password `grid sm:grid-cols-2` | password fields stack; `autoComplete=new-password` | `V113A_guardian_settings_mobile390.png` |
| `/parent/discovery` | header + chips + capsule cards + ReadinessPanel | generate controls density; capsule detail scroll | `V113A_guardian_discovery_mobile390.png` |

## 3. Scroll ownership (source intent)

`OBSERVED_SOURCE`:
- **Family archive:** single-page vertical scroll (V111D removed nested scroll / snap / dual view). Desktop rail is `sticky top-4`; mobile index is inside an `overflow-y-auto` Sheet. → **no nested scroll in the main content** (good intent).
- **Journey viewer:** fixed-height stage (D224-B `h-[46vh]`) with story in a bottom Sheet, specifically to stop the rail from shifting — **intent is a stable, non-nested-scroll stage**; runtime confirmation needed.
- **Memory Room:** normal page scroll on a bare cream surface.
- `UNKNOWN`: whether any surface exhibits real nested/inner scroll at 390px, or layout shift during signed-media load (video height, image swap). Only browser capture resolves this.

## 4. Tap-target / accessibility intent

`OBSERVED_SOURCE`:
- Bottom-nav `min-h-[56px]`; several CTAs `min-h-[44px]` (Home empty/support, journal "Ghi lại"). Good intent.
- **Small targets to verify at 390px:** member-remove `X` (`size=sm` ghost), contribution row action buttons (`h-7 px-2`), archive glimpse thumbnails (64px), preserve "Bỏ giữ" underline text link, consent `Switch`. These are `< 44px` in source and need runtime tap-target confirmation.
- Reduced-motion: FMN motion is gated behind `prefers-reduced-motion` (`CANONICAL` D306); archive recede honors it (`memoryRoomShared` checks `matchMedia`).
- `aria`: archive index `aria-expanded`/`aria-current`; period `aria-labelledby`; loaders `role=status aria-live`. Generally present.

## 5. Mobile verdict

**VISUAL/MOBILE VERDICT: INCOMPLETE — browser evidence unavailable.** Source intent is coherent (single-scroll archive, Sheet-based timeline index, reserved image frames, 56px bottom-nav, reduced-motion gating). The following **cannot be asserted without capture** and are the mobile audit's open items: fixed bottom-nav vs iOS safe-area/Safari bars; Journey stage fit within first viewport after header; family archive legibility inside a Card at 390px; video-height layout shift in the Room; sheet/dialog/keyboard behavior; sub-44px tap targets. The capture map in §2 is the exact, deterministic set required to close this branch.
