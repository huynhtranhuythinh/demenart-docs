# F1 — VISUAL SOURCE OF TRUTH
**V113F · Design Consistency Freeze** · Planning/handoff only · ZERO code/backend/deploy.
**Role:** Design System Auditor. **Art Director / Product Design Lead:** ChatGPT. **Product Owner:** Jean Huỳnh.
**Purpose of this file:** fix one canonical visual precedence so no route can drift, and record every rejected input so it cannot contaminate implementation.

**V113F-C locked decisions (2026-07-16, do not reopen):** core color tokens + fonts CONFIRMED (see F2); tablet = top bar + drawer (F5); landing label = **"Hôm nay"** (never "Trang chủ"); mobile 4th primary = **"Của con"**, desktop 4th = **"Thế giới của con"**; user-facing role grammar in Vietnamese (Phụ huynh chính / Phụ huynh / Người thân + Ba/Mẹ/Ông/Bà/Cô/Chú; status Hoạt động / Đang chờ / Đã gỡ) — backend role/capability names unchanged; counts appear only as quiet metadata after identity/chapter labels, never as KPI cards, never before media, never replacing identity.

**V113F FINAL MERGE — 2026-07-17 GMT+7.** Product Owner approved all four correction packs (Thành viên gia đình · Quyền riêng tư · Cài đặt / Account Utility · Create Flows + System/Media/Consent states), including the final Pack 4 accessibility patch. The four packs are hereby promoted **L4 coverage → L3 approved matching surfaces**. They inherit the L2 Journey visual baseline, are L3-canonical for their own surfaces only, do not override L1/L2, and change no routes, authorization, consent or data contracts.

---

## 1. Source precedence (canonical)

| Level | Meaning | Wins over | Inputs at this level |
|---|---|---|---|
| **L1 — Official brand asset** | The official *Dế Mèn Art Garden* logo (green shield + cricket + "DẾ MÈN ART GARDEN") | everything | Uploaded official logo |
| **L2 — Master visual baseline** | The approved **"Hành trình của An"** Journey mockup (produced *after* the official logo) | L3, L4, rejected | Image 4 |
| **L3 — Approved matching surfaces** | Screens that already match L2 and are canonical for their own composition | L4, rejected | Image 2 (Home), Image 3 (Family Archive), Image 7 (Memory Room), Image 5 (Kid gateway), **Correction Packs 1–4 (§2b, final merge 2026-07-17)** |
| **L4 — Coverage references only** | Content/state **inventory** — tells us *what elements exist*, never *how they look* | rejected only | Image 1 (combined poster) — **COVERAGE-HISTORY ONLY** since the final merge; no longer canonical for any surface covered by Packs 1–4 |
| **REJECTED** | Must not be used as a design source under any circumstances | — | Image 6, plus recorded exclusions in §5 |

**Rule of precedence:** whenever two inputs disagree on logo, palette, typography, spacing, navigation, card style, or role framing, the **lower Level number wins**. L4 supplies *composition/coverage*; its tokens are always overridden by L1–L3.

---

## 2. Accepted visual sources (with confidence)

| # | Image | Surface | Level | Confidence | Notes |
|---|---|---|---|---|---|
| 1 | Image 4 | **Journey — "Hành trình của An"** | **L2 MASTER** | High | Defines the entire token/typography/layout baseline. Title matches brief verbatim. |
| 2 | Image 2 | **Home — "Hôm nay của An"** (emerald rail, deep-green CTA, official logo) | L3 | High | The *canonical* Home. Supersedes Image 6. |
| 3 | Image 3 | **Family Archive — "Gia đình Hùng"** | L3 | High | Timeline archive, "Ký ức \| Thành viên" tabs, saved/archived rails. |
| 4 | Image 7 | **Memory Room** | L3 | High | Content-first order already correct: return → media → title/story → provenance → voices → Preserve → lifecycle. |
| 5 | Image 5 | **Kid gateway — "Thế giới của An"** (Parent-facing) | L3 | High | Corrected standalone gateway; preview + one "Mở thế giới của {child}" + safety status + controls-at-depth. |
| 6 | Image 1 | **Coverage poster** (Thế giới, Thành viên, Quyền riêng tư, Cài đặt, Create flows, System states, Media/consent states) | **L4 COVERAGE-HISTORY ONLY** | Medium | HISTORICAL inventory. Its nav model, labels and role framing are stale; every surface it covered is now L3-canonical via Packs 1–4 (§2b). Useful only as a historical element inventory. |
| 7 | Correction Pack 1 | **Thành viên gia đình** — `DMA_Correction_Pack_1_Thanh_vien_gia_dinh.html` (desktop 1440 + mobile 390) | **L3** | High | Editorial roster, VN role grammar, guardian-only invite controls, 1 pending invite, one primary CTA "Mời thành viên". |
| 8 | Correction Pack 2 | **Quyền riêng tư** — `DMA_Correction_Pack_2_Quyen_rieng_tu.html` (desktop 1440 + mobile 390) | **L3** | High | 9 consent types in 4 editorial groups, per-toggle inline save (no page-level Save), MIN-consent note, family_space_display shown off, sensitive rows champagne (non-red), semantic ChildSwitcher. |
| 9 | Correction Pack 3 | **Cài đặt / Account Utility** — `DMA_Correction_Pack_3_Cai_dat_Account_Utility.html` (desktop 1440 + mobile 390) | **L3** | High | Utility-only settings: read-only account identity, PasswordCard (new + confirm only), read-only child roster, existing utility links, quiet Đăng xuất; one filled CTA "Cập nhật mật khẩu". |
| 10 | Correction Pack 4 | **Create Flows + States** — `DMA_Correction_Pack_4_Create_Flows_States.html` | **L3** | High | ParentMemoryComposer · FamilyCardComposer · family contribution entry · VoiceRecorder Idle/Recording/Review (2-min cap, no autoplay) · MediaPicker desktop/mobile · all 9 TruthState visual variants incl. status/alert semantics. |


## 2b. Final-merge promotion (2026-07-17)

Canonical filenames (browser suffixes such as "(1)" are never part of the canonical name):

1. `DMA_Correction_Pack_1_Thanh_vien_gia_dinh.html` — Family Members / Thành viên gia đình · desktop 1440 + mobile 390.
2. `DMA_Correction_Pack_2_Quyen_rieng_tu.html` — Privacy / Quyền riêng tư · desktop 1440 + mobile 390.
3. `DMA_Correction_Pack_3_Cai_dat_Account_Utility.html` — Settings / Account Utility · desktop 1440 + mobile 390.
4. `DMA_Correction_Pack_4_Create_Flows_States.html` — ParentMemoryComposer · FamilyCardComposer · family contribution entry · VoiceRecorder Idle/Recording/Review · MediaPicker desktop/mobile · TruthState visual variants.

Statements of record:

- All four packs **inherit the L2 Journey visual baseline** (palette, typography, rail, mobile navigation, logo treatment, border/radius/spacing, botanical restraint).
- Their content and composition are now **L3 canonical for their own surfaces**.
- They **do not override L1 or L2**.
- They **do not change routes, authorization, consent or data contracts**.
- The old combined poster (Image 1) is retained as **L4 COVERAGE-HISTORY ONLY** — a historical inventory, never again the canonical visual source for any surface now covered by Packs 1–4.
- **Not promoted** (remain evidence debt / lower confidence): Notification list, Support list, invitation expired/revoked treatments, audio-only Memory Room composition, text-only Memory Room composition.

---

## 3. Canonical logo treatment (L1)

Rules, non-negotiable:

- **Asset:** the official *Dế Mèn Art Garden* mark (green shield, cricket, "DẾ MÈN ART GARDEN" lockup) is canonical. Do not redraw, do not substitute a generic cricket icon, do not substitute a "DMA" wordmark, do not substitute the "Gia đình Hùng" botanical wordmark seen in Image 6.
- **Light/dark variants:** on the **deep-emerald rail** use the light/ivory logo treatment (as in Images 2/4/7). On **ivory surfaces** (e.g. a light header) use the dark/green treatment. Never place the emerald-on-emerald or ivory-on-ivory low-contrast combination.
- **Proportions & clear-space:** preserve original proportions; reserve clear-space ≥ the height of the shield on all sides. Exact clear-space ratio → `REQUIRES ART-DIRECTOR CONFIRMATION`.
- **Green discipline:** the bright logo green is a *logo* color, **not** the UI green. Do **not** derive the interface background or primary emerald from the bright logo green. UI emerald is the darker forest tone extracted from the L2 rail (see F2).
- **Family/child identity grammar:** "Gia đình {name}" as family identity; "{Child} · {Child}" chip row; child age subtitle ("3 tuổi 2 tháng"). Identity is textual (no child avatar field exists — B2 §1); monogram/initial or newest child media may stand in, no schema change.

---

## 4. Surface-by-surface canonical reference (required table)

| Surface | Canonical visual source | Product purpose | Confidence | Required correction |
|---|---|---|---|---|
| **Hôm nay** `/parent` | Image 2 (L3) | De-dashboarded landing: identity + one real memory + one action | High | None on tokens. Confirm mobile 4th nav label reads **"Của con"** (not the long label). |
| **Hành trình** `/parent/journal` | Image 4 (L2 MASTER) | Content-first child art journal; hosts "Nhìn lại một chặng" | High | None — this *is* the baseline. |
| **Gia đình / Family Archive** `/parent/family` (guardian) · `/family` (member) | Image 3 (L3) | Timeline archive with "Ký ức \| Thành viên" split | High | Restyle "{n} ký ức" count so a metric never precedes memories. Member context = read-only affordances. |
| **Memory Room** `/family/memory/:cardId` | Image 7 (L3) | Single memory, content-first | High | None on order. Keep generic denial + return-context; keep `Sửa`/`Lưu trữ`/`Ẩn` **separate**. |
| **Thế giới của con** `/parent/kid` | Image 5 (L3) | Parent→child gateway (preview + one action + safety status + controls at depth) | High | Align **mobile** bottom-nav 4th label to **"Của con"** (Image 5 mobile currently shows long label). Not a Kid dashboard. |
| **Thành viên** (Family internal section) | **Correction Pack 1 (L3)** | Roster + roles + invites (guardian: manage; member: read-only) | High | RESOLVED (final merge). VN role grammar; editorial roster; invite/remove/pending **guardian-only**. |
| **Quyền riêng tư** `/parent/consent` | **Correction Pack 2 (L3)** | Per-child consent toggles (9 existing types, 4 editorial groups) | High | RESOLVED (final merge). Consent **write path unchanged** (F9 parked 🔒); per-toggle inline save; no page-level Save. |
| **Cài đặt** `/parent/settings` | **Correction Pack 3 (L3)** | Account hub (password, roster, links); **utility, not primary nav** | High | RESOLVED (final merge). Utility-only; quiet Đăng xuất zone; one filled CTA (Cập nhật mật khẩu). |
| **Parent create** (text/media composer) | **Correction Pack 4 (L3)** | "Ghi lại một điều về {child}" | High | RESOLVED (final merge). One primary ("Tiếp tục"); private-context audience selector. |
| **Family create / contributions** (media picker, text, voice, audience) | **Correction Pack 4 (L3)** | Family card composer + contribution kinds | High | RESOLVED (final merge). Single create CTA ("Gửi ký ức"); member contribution entry stays secondary to the memory. |
| **System states** (loading/empty/error/denied/archived/consent-waiting) | **Correction Pack 4 (L3)** | TruthStateBlock variants | High | RESOLVED (final merge). Each state visually + semantically distinct (D298); status/alert semantics per final Pack 4 patch. |
| **Media & consent states** (unavailable/needed/granted) | **Correction Pack 4 (L3)** | Signed-media + consent overlays | High | RESOLVED (final merge). Reserved media frame + retry; "Vì sao?" → `/parent/consent`. |

---

## 5. Rejected / discarded sources (record so they cannot contaminate build)

| Rejected input | What it is | Why rejected | Enforcement |
|---|---|---|---|
| **Image 6** — orange-heavy "Hôm nay của An" | Alternate Home: **yellow/amber CTAs**, coral/orange floral illustration, red heart doodle, **"Gia đình Hùng" botanical wordmark instead of the official logo**, mascot-like child art | Matches the brief's rejected "earlier orange-heavy V4 board as literal layout" **and** "generic wordmark substitution". Palette + logo + action-color all violate L1–L2. | Image 2 is the only canonical Home. Image 6 must not seed any Home token, CTA color, or logo. |
| Orange-heavy **V4 presentation board** (literal layout) | Earlier concept board | Not a production layout source | Excluded |
| **Teal / mint UI variants** | Any teal/mint palette experiments | Off-palette (no teal/mint/neon/blue) | Excluded (none present in this attachment set; exclusion recorded pre-emptively) |
| **Generic "DMA" wordmark substitutions** | Text wordmark in place of the shield mark | Violates L1 | Excluded |
| **Rejected Kid-*dashboard* "Thế giới của con"** | A Kid-facing dashboard / development-report version | Role confusion: parent gateway ≠ kid dashboard ≠ dev report | Excluded; Image 5 is the only Kid gateway source |
| **Any poster mixing unrelated layout systems** | Mixed-system posters | Cross-system drift | Excluded |

---

## 6. Visual principles (derived from L2/L3)

1. **Two-surface world.** Deep-emerald **identity** surfaces (rail, headers) vs warm-ivory **reading** surfaces (content). Never invert.
2. **Editorial serif for meaning, humanist sans for mechanics.** Page/chapter/memory titles = serif; nav/body/metadata/controls/forms = sans. No per-route font swaps.
3. **Champagne/gold is an accent, not a fill.** Gold marks provenance, chapter pills, small metrics, and sparse botanical sprigs — never a large surface.
4. **Media is large and dignified.** One real child memory dominates; counts never precede memories.
5. **One primary action per surface.** Lifecycle/admin controls move to a quiet zone.
6. **Botanical restraint.** Low-contrast, sparse, non-interactive, never behind essential text, never on every card. No permanent mascot on Parent surfaces.
7. **Quiet governance.** Permission-specific controls are present but understated; error states are truthful and distinct, never silent-empty.
8. **Parent-facing, never Kid-facing.** Parent surfaces speak to the guardian about the child; they are not the child's play space.

---

## 7. Conflict-resolution rules (apply verbatim during build & QA)

1. **Two Home mockups exist** → Image 2 (L3) is canonical; Image 6 is rejected. No blend.
2. **Nav model:** L2/L3 4-primary model (**Hôm nay · Hành trình · Gia đình · Của con**) + utilities-behind-identity **overrides** the L4 poster's stale rail ("Trang chủ", 7 rail items, 5-item bottom nav incl. "Cài đặt").
3. **Labels:** landing = **"Hôm nay"** (not "Trang chủ"); desktop 4th = **"Thế giới của con"**, mobile 4th = **"Của con"**.
4. **Role words:** Vietnamese grammar (e.g. "Phụ huynh chính") overrides English poster words ("Guardian").
5. **Tokens vs coverage:** take *what exists* from L4, take *how it looks* from L1–L3. Never the reverse.
6. **Governance never bends to visuals:** any reorder that would change audience or authorization is out of scope; keep `canEdit`/`canArchive`/`can_moderate` separate (D293); keep Memory Room generic denial (D305); keep fail-closed-and-present aux (D298).
7. **Unresolved > invented:** where L1–L3 evidence is absent, mark the gap; do **not** invent a new visual direction to fill it. *(HISTORICAL: this rule originally listed Thành viên, Privacy, Settings, create flows and states as absent — RESOLVED by the 2026-07-17 final merge via Correction Packs 1–4. It still applies to the remaining evidence debt: Notifications/Support, invitation expired/revoked, audio-only/text-only Room compositions.)*
