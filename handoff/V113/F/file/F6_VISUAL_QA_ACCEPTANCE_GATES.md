# F6 — VISUAL QA ACCEPTANCE GATES
**V113F** · Route-by-route, implementation-ready QA. A route passes only when **every** gate is ✅. Any ✗ = blocker.

**V113F FINAL MERGE — 2026-07-17 GMT+7:**
- **DESIGN SOURCE READY: PASS** — every route below now has an approved L2/L3 canonical source (Correction Packs 1–4 cover the formerly-L4 surfaces; the HISTORICAL "restyle to baseline" blocker for those surfaces (resolved by the pack approvals) is removed).
- **IMPLEMENTATION QA: NOT YET RUN** — this file remains the acceptance harness for the future V113G implementation. No checkbox below is marked PASS by mockup approval alone; all route-by-route build gates stay open until real routes are built and verified.

---

## 1. Global gates (apply to every route)
- [ ] **G1 Logo** — official Dế Mèn Art Garden mark, correct light/dark treatment, correct clear-space; no wordmark/cricket/"Gia đình Hùng" substitution.
- [ ] **G2 Palette** — emerald / ivory / champagne / sage + ink + semantic only. **No** teal, mint, neon, blue, or orange/amber-as-brand. UI emerald not sampled from bright logo green.
- [ ] **G3 Typography** — **Playfair Display** titles-only + **Be Vietnam Pro** everything else; fixed scale; Vietnamese diacritics (ổ/ữ/ằ/ị/ợ…) render correctly; no third font.
- [ ] **G4 Rail/Nav** — identical 4 primaries; **landing = "Hôm nay" (no "Trang chủ")**; **mobile 4th = "Của con"**, desktop 4th = "Thế giới của con"; utilities behind identity; **tablet = top bar + drawer (no icon rail)**; mobile bottom nav = 4 items.
- [ ] **G16 Confirmed tokens** — colors match F2 confirmed hexes (emerald `#053327`/`#0B513B`, ivory `#FCF7F0`, champagne `#C8AA6A` decorative-only, gold text `#806A35`, error/destructive `#A8473C`, denied `#776038`); no `⚠` core token in shipped UI.
- [ ] **G17 VN role grammar** — no English role words ("Guardian"); roster/status use Phụ huynh chính / Người thân / Hoạt động / Đang chờ / Đã gỡ.
- [ ] **G5 One primary action** — exactly one primary CTA; secondaries limited; lifecycle/admin in quiet zone; no duplicate CTAs.
- [ ] **G6 Media-first** — real child media large and dignified; no metric/count precedes memories.
- [ ] **G7 No dashboard** — no KPI tile block anywhere on Parent surfaces.
- [ ] **G8 No teal/mint drift** — explicit re-check.
- [ ] **G9 Role clarity** — Parent-facing, never Kid-facing; no dev-report framing.
- [ ] **G10 Governance controls** — actor-appropriate; `Sửa`/`Lưu trữ`/`Ẩn`/preserve **separate**, never a merged "Quản lý"/"canManage".
- [ ] **G11 State truthfulness** — error ≠ denied ≠ empty, visually distinct; no silent-empty (F01/E4); Room denied = generic string, no enumeration.
- [ ] **G12 A11y** — focus-visible, ≥44px targets, contrast ≥4.5:1 (gold text checked), SR labels, `aria-current`.
- [ ] **G13 Loading stability** — reserved media boxes; no layout shift on signed-URL resolve; placeholders same size.
- [ ] **G14 Mobile recomposition** — recomposed stack, not a shrunk desktop grid; safe-area + bottom-nav reservation.
- [ ] **G15 Botanical restraint** — sparse, low-contrast, non-interactive, not behind essential text, not on every card; no permanent mascot.

---

## 2. Route-by-route gates

### R1 · Hôm nay `/parent` (ref: Image 2 L3)
- [ ] Identity + one memory + one action; **no** KPI block.
- [ ] Hero uses real newest media-bearing item; family signal quiet (single, not grid).
- [ ] Child-fetch **error** distinct from empty (not silent).
- [ ] Mobile 4th nav label = **"Của con"**.
- [ ] **Reject-check:** none of Image 6's yellow CTA / orange floral / heart doodle / botanical wordmark present.

### R2 · Hành trình `/parent/journal` (ref: Image 4 L2)
- [ ] Chapter hero + gold pill + 3 micro-metrics; content-first timeline.
- [ ] "Nhìn lại một chặng" = header/side entry (not a 5th primary, not inline in the stage).
- [ ] Edit/archive shown only if `parent_memory && mine`.
- [ ] Media-denial → warm per-reason copy + "Vì sao?".

### R3 · Gia đình `/parent/family` + `/family` (ref: Image 3 L3)
- [ ] "Ký ức | Thành viên" separated via `?section=`; not one continuous page.
- [ ] One create CTA within Ký ức (no double-CTA).
- [ ] Guardian shell vs member standalone shell; **member roster read-only**.
- [ ] "{n} ký ức" count does not precede memories.
- [ ] Empty/error/denied/archived distinct in both contexts + both sections.

### R4 · Thế giới của con `/parent/kid` (ref: Image 5 L3)
- [ ] Gateway preview + **one** "Mở thế giới của {child}"; safety status visible; controls at secondary depth.
- [ ] **Not** a Kid dashboard / dev report.
- [ ] Mobile 4th nav label = **"Của con"** (fix Image 5 mobile long label).

### R5 · Memory Room `/family/memory/:cardId` (ref: Image 7 L3)
- [ ] Order: return → media → title/story → provenance → voices → preserve → lifecycle.
- [ ] `Sửa`(creator) / `Lưu trữ`(creator|guardian) / `Ẩn`(guardian) **separate**; own-contribution Sửa/Rút lại = author.
- [ ] Preserve zone renders even on aux error (present-not-hidden).
- [ ] Denied/not-found = one generic string; return-context leaks no existence pre-auth.

### R6 · Thành viên section (ref: **Correction Pack 1 — L3** ✅ design source)
- [ ] Matches Pack 1 editorial roster (warm rows, not an admin table); counts as quiet metadata "5 thành viên · 1 lời mời đang chờ" (pending never counted as member).
- [ ] VN role grammar (no English role words).
- [ ] Invite/remove/pending guardian-only; member read-only; `guardian_member_protected`; protected guardian row exposes no invalid remove action.
- [ ] One primary CTA "Mời thành viên"; InviteRow dashed "Đang chờ" + Gửi lại / Thu hồi.

### R7 · Quyền riêng tư `/parent/consent` (ref: **Correction Pack 2 — L3** ✅ design source)
- [ ] Matches Pack 2: all **9 existing consent types** in 4 editorial groups; no internal keys; no new audience/consent type.
- [ ] Per-toggle inline save with in-row "Đã lưu" / "Chưa lưu thay đổi · Thử lại"; **no page-level Save**; failed write shows last persisted value.
- [ ] MIN-consent note present; `family_space_display` default-off semantics; sensitive rows champagne/sage (never red); privacy_ack rendered as confirmation, not marketing consent.
- [ ] Consent **write path unchanged**; "Vì sao?" entry present; semantic ChildSwitcher (`aria-pressed`).

### R8 · Cài đặt `/parent/settings` (ref: **Correction Pack 3 — L3** ✅ design source)
- [ ] Matches Pack 3: **utility, not in bottom nav**; account identity + child roster read-only; utility links to existing surfaces only.
- [ ] PasswordCard = Mật khẩu mới + Xác nhận only (no current-password field), `autocomplete="new-password"`, no prefilled values, show/hide with accessible name; exactly one filled CTA "Cập nhật mật khẩu".
- [ ] Quiet session zone "Đăng xuất" (restrained destructive, never primary); **no** 2FA / sign-out-all / export / delete-account / billing / notification-preferences UI.
- [ ] App never enters credentials on user's behalf.

### R9 · Create flows (ref: **Correction Pack 4 — L3** ✅ design source)
- [ ] One primary per step (Parent "Tiếp tục" · Family "Gửi ký ức" · Review "Gửi giọng nói"); content kinds are quiet selection chips, not competing primaries.
- [ ] Audience = existing private contexts only (Chỉ phụ huynh / Gia đình được mời); no public/social audience.
- [ ] VoiceRecorder covers Idle/Recording/Review; **2-minute cap** shown; no autoplay; recorder controls ≥44px with accessible names.
- [ ] MediaPicker: selection = border + check + `aria-pressed`; unavailable thumbnail present + retryable (≥44px, accessible name); reserved aspect ratios; no fake percentage.
- [ ] Member contribution entry in standalone Family shell (no Parent bottom nav); create controls only when `create_card` allowed.

### R10 · System & media states (ref: **Correction Pack 4 — L3** ✅ design source)
- [ ] Each of loading/empty/error/denied/archived/consent-waiting/media-unavailable/consent-needed/consent-granted visually distinct per Pack 4, with correct zero-or-one action.
- [ ] A11y semantics per the final Pack 4 patch: titles/descriptions wired via `aria-labelledby`/`aria-describedby`; loading = status/polite/`aria-busy`; error, denied, media-unavailable = `role="alert"`; consent waiting/needed/granted = status/polite; no redundant alert+live on one panel.
- [ ] Denied copy generic (no enumeration); consent-granted never promises universal display; empty shows create action only in create-authorized context.

---

## 3. Required screenshots (evidence set)

Capture at **1440px desktop** and **390px mobile** for every route below, matching the axis table in §4.

| # | Route | Child fixture | Actor | States to capture |
|---|---|---|---|---|
| 1 | Hôm nay | **An (populated)** | guardian | default; child-fetch error; no-data empty |
| 2 | Hôm nay | **Khang (near-empty)** | guardian | empty/first-run |
| 3 | Hành trình | An | guardian | default; media-denied/consent-waiting |
| 4 | Gia đình · Ký ức | An | guardian | default; empty; archived rail |
| 5 | Gia đình · Thành viên (ref Pack 1 L3) | — | guardian | roster + pending invite; (expired/revoked if reachable — still evidence debt) |
| 6 | Gia đình (member) | — | **non-guardian member** *(where safely available)* | read-only roster; archive |
| 7 | Memory Room | An | guardian | media card; **denied/generic**; aux-error preserve; (audio-only & text-only *once a card is hand-created*) |
| 8 | Thế giới của con | An | guardian | enabled+PIN; disabled |
| 9 | Quyền riêng tư (ref Pack 2 L3) | An | guardian | default; not-linked empty; inline saved + write-error rows |
| 10 | Cài đặt (ref Pack 3 L3) | — | guardian | account; password success; quiet Đăng xuất zone |
| 11 | Create flows (ref Pack 4 L3) | An | guardian | text; media picker (selected + unavailable); voice idle/recording/review; audience |
| 12 | States (ref Pack 4 L3) | — | — | all 9 TruthState variants (incl. both empty variants) |

**Notes / evidence debt:** member session = *NOT TESTABLE — no safe member session* (carry from B6); audio-only/text-only Room = hand-create a card, **do not synthesize**; production live-UI baseline still open.

## 4. Visual checksum axes (run per screenshot vs L2 master)

| Axis | Pass condition |
|---|---|
| Logo | official asset + correct treatment |
| Palette | emerald / ivory / champagne / sage |
| Typography | same serif/sans roles + scale |
| Navigation | same labels + hierarchy (Của con on mobile) |
| ChildSwitcher | same structure + persisted selection |
| Radius | same family |
| Border | same weight + warmth |
| Shadow | same restraint |
| Media | large + dignified, reserved box |
| CTA | one primary |
| Illustration | restrained botanical, no mascot |
| Role | Parent-facing |
| Mobile | recomposed, not scaled |
| Governance | controls match actor authority; predicates separate |

Every mismatch classified **ACCEPT · CORRECT BEFORE BUILD · DEFER · REJECT** (no silent normalization).
