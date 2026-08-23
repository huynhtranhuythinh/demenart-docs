# F1 — VISUAL SOURCE OF TRUTH
**V113F · Design Consistency Freeze** · Planning/handoff only · ZERO code/backend/deploy.
**Role:** Design System Auditor. **Art Director / Product Design Lead:** ChatGPT. **Product Owner:** Jean Huỳnh.
**Purpose of this file:** fix one canonical visual precedence so no route can drift, and record every rejected input so it cannot contaminate implementation.

**V113F-C locked decisions (2026-07-16, do not reopen):** core color tokens + fonts CONFIRMED (see F2); tablet = top bar + drawer (F5); landing label = **"Hôm nay"** (never "Trang chủ"); mobile 4th primary = **"Của con"**, desktop 4th = **"Thế giới của con"**; user-facing role grammar in Vietnamese (Phụ huynh chính / Phụ huynh / Người thân + Ba/Mẹ/Ông/Bà/Cô/Chú; status Hoạt động / Đang chờ / Đã gỡ) — backend role/capability names unchanged; counts appear only as quiet metadata after identity/chapter labels, never as KPI cards, never before media, never replacing identity.

---

## 1. Source precedence (canonical)

| Level | Meaning | Wins over | Inputs at this level |
|---|---|---|---|
| **L1 — Official brand asset** | The official *Dế Mèn Art Garden* logo (green shield + cricket + "DẾ MÈN ART GARDEN") | everything | Uploaded official logo |
| **L2 — Master visual baseline** | The approved **"Hành trình của An"** Journey mockup (produced *after* the official logo) | L3, L4, rejected | Image 4 |
| **L3 — Approved matching surfaces** | Screens that already match L2 and are canonical for their own composition | L4, rejected | Image 2 (Home), Image 3 (Family Archive), Image 7 (Memory Room), Image 5 (Kid gateway) |
| **L4 — Coverage references only** | Content/state **inventory** — tells us *what elements exist*, never *how they look* | rejected only | Image 1 (combined poster) |
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
| 6 | Image 1 | **Coverage poster** (Thế giới, Thành viên, Quyền riêng tư, Cài đặt, Create flows, System states, Media/consent states) | **L4** | Medium | Inventory only. On-brand *in spirit* but its nav model, labels and role framing are **stale** (see §4). |

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
| **Thành viên** (Family internal section) | Image 1 §2 (**L4 only**) | Roster + roles + invites (guardian: manage; member: read-only) | **Low** | No L2/L3 mockup exists. Restyle table to baseline tokens; replace English role words ("Guardian") with VN grammar; keep invite/remove/pending **guardian-only**. |
| **Quyền riêng tư** `/parent/consent` | Image 1 §3 (**L4 only**) | Per-child consent toggles | **Low** | Restyle to baseline tokens; consent **write path unchanged** (F9 parked 🔒). |
| **Cài đặt** `/parent/settings` | Image 1 §4 (**L4 only**) | Account hub (password, roster, links); **utility, not primary nav** | **Low** | Restyle; demote from bottom-nav; destructive controls to a quiet zone. |
| **Parent create** (text/media composer) | Image 1 §5 (**L4 only**) | "Ghi lại một điều về {child}" | **Low** | Restyle; one primary action; audience selector present. |
| **Family create / contributions** (media picker, text, voice, audience) | Image 1 §5 (**L4 only**) | Family card composer + contribution kinds | **Low** | Restyle; single create CTA within "Ký ức". |
| **System states** (loading/empty/error/denied/archived/consent-waiting) | Image 1 §6 (**L4 only**) | TruthStateBlock variants | **Low** | Restyle to L2 truth-state grammar; each state visually distinct (D298). |
| **Media & consent states** (unavailable/needed/granted) | Image 1 §7 (**L4 only**) | Signed-media + consent overlays | **Low** | Restyle; "Vì sao?" → `/parent/consent`. |

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
7. **Unresolved > invented:** where L1–L3 evidence is absent (Thành viên, Privacy, Settings, create flows, states), mark the gap; do **not** invent a new visual direction to fill it.
