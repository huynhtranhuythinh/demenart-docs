# A4 — CONTENT & EMOTIONAL HIERARCHY AUDIT
**V113A** · Objective evidence only (no "beautiful/ugly" verdicts). Ordering claims are **`OBSERVED_SOURCE`** (DOM order + reserved dimensions from the component tree); **runtime first-viewport not browser-confirmed** (browser branch unavailable — see A5). Where source intent and rendered behavior could diverge, that is flagged.

---

## 1. Parent Home (`/parent`) — first-30-seconds

`OBSERVED_SOURCE` DOM order: **A Hero → B Summary → C Recent → D Nhìn-lại → E Tips → F Kid-link**, six stacked full-width cards.

- **First visible content (source order):** Hero card — eyebrow "Cổng ba mẹ", h1 "Chào ba mẹ của {child} 💛", one-line subtitle, child-selector chips (**only if >1 child**), primary CTA, one text-link.
- **Dominant element:** the amber Hero card (`p-8 sm:p-10`, gradient). It is **text + control**, not child media.
- **Primary action:** "Ghi lại một điều về {child}" (amber, `h-12`, full-width mobile). **Competing action in same card:** "Xem toàn bộ hành trình" link. → two actions in hero (one strong, one secondary).
- **Child's actual media above the fold:** **absent.** Home shows no child image/artwork; the Recent list (card C) uses **emoji labels** (🎨/🎵/📸/🏡/🚌) + text, not thumbnails.
- **Metadata density:** Summary card B presents **four count tiles** (Tác phẩm / Âm thanh / Khoảnh khắc / Ba mẹ lưu lại) as large numerals, plus optional "Hạt giống nổi bật" + "{n} huy hiệu" chips. Objective: **numeric counts are a prominent block near the top**; this is the metric-forward pattern the product DNA warns against ("không chấm điểm/so sánh").
- **Child identity:** name in text only ("của {child}"); chips carry names. No photo/avatar.
- **Family identity:** absent on Home (Home is child-scoped, not family-scoped).

## 2. Journey (`/parent/journal`) — daily return

`OBSERVED_SOURCE`:
- First content: h1 "Hành trình của {child}" + subtitle + child chips + "+ Ghi lại" pill, then the viewer.
- Live body = `ParentJourneyViewer` (memory-object stage/rail — `CANONICAL` D224/D302). "What changed since last visit" is **not surfaced** as a distinct affordance; the viewer is a continuous timeline.
- **Same data as Home** (`get_child_journal`) → Home summary and Journey are two renderings of one payload; the semantic distinction between "Home recent" and "Journey" is thin (`INFERRED`).
- Dead legacy branch (unreachable) would show a left-border timeline with day nodes + skills(5-dot)/badges side rail — **not live**; do not treat as current.

## 3. Family archive (`/parent/family` and `/family`)

`OBSERVED_SOURCE`:
- On `/parent/family`, DOM order within the space view: space title + child chips → **Card { FamilyArchiveNavigation }** → standalone "Tạo kỷ niệm" button → **"Thành viên" card** → "Lời mời đang chờ" → privacy footnote. → **management UI (members/invites) shares the surface with the memory archive**; below the archive card, the surface becomes administrative.
- Archive newest-period (desktop): sticky 16rem "DÒNG THỜI GIAN" rail + period pane with heading + **"{n} ký ức" count line** + hairline + `space-y-10` `MemoryItem` list. Objective: a **count line precedes the memories**.
- **`MemoryItem` composition (media hero):** media-led cards put the lead medium in a reserved **`aspect-ratio 4/3`** frame first, then title, then excerpt, then a quiet footer (creator line → voices line → support note → date · source). This is a **media-first** hierarchy with metadata demoted to footer. Text-only → letter-paper card (title + excerpt). Audio-only → title/excerpt + player.
- **Creator/provenance:** present as a quiet footer line ("… đã thêm ký ức này" via `memoryActorLine`) + date·source.
- **Family identity:** the space name is the h1 of the space view (present above the archive).

## 4. Memory Room (`/family/memory/:cardId`)

`OBSERVED_SOURCE` `CardDetail` DOM order:
**h1 title → creator line → occurred date → source label → people line → media (tiles / letter-paper) → preserve → engagement (💛 + contributions) → governance buttons.**

- **Hierarchy inversion vs the stream card:** the Room is **metadata-first** (creator/date/source/people appear *before* the media), whereas the stream `MemoryItem` is **media-first** (metadata in footer). Same content, opposite emphasis across the two surfaces the user moves between. Objective, evidence-backed.
- **Media dimensions:** images in reserved **16:9 (`aspect-video`)** frame (stable, no shift on load — `img` swapped inside the reserved box); video in black-bordered frame at intrinsic height (**height not reserved** → possible shift when the `<video>` metadata loads); audio is a fixed-height control bar.
- **Metadata amount:** up to four lines (creator, date, source, people) before any media — metadata precedes memory content.
- **Governance controls:** right-aligned ghost buttons at the bottom (Sửa / Lưu trữ) — low-emphasis, appropriate.

## 5. Discovery (`/parent/discovery`)

`OBSERVED_SOURCE`: h1 "✨ Bản Khám Phá Nghệ Thuật" + subtitle → child chips → capsule cards (if any) → `ReadinessPanel` (generate controls) → bottom boundary. First content is a header + generator, not child media. Concept and label diverge from its nav entry ("Nhìn lại").

## 6. Empty / near-empty / error / denied presentation

`OBSERVED_SOURCE`:
- **Home** distinguishes four states: no-child (contact school + Support), other-only ("Hành trình đang bắt đầu"), near-empty, empty ("Bắt đầu hành trình…"). Warm, actor-correct copy.
- **Family** (both hosts) uses `classifyRpcOutcome`/`outcomeToLoadState` → **loading / denied / error / empty are distinct** (V111C F01 fix): a load error **never** collapses to "you have no family space" / "create space." Denied → `FamilyQuietNotice tone=denied`; error → quiet notice + retry; empty → create-space (guardian) or "nhờ người thân mời" (member).
- **Memory Room** aux layers fail **independently** (engagement/preserve errors → quiet notice + retry at that layer, never collapsing the primary memory — D298/D305 §4). Not-found and not-authorized return the **same** generic copy ("Không thể mở ký ức này…") — no enumeration (D305 §2).
- **Journey media denial** → warm per-reason copy ("Đang chờ ba mẹ đồng ý cho xem ảnh này") + "Vì sao?" popover → `/parent/consent`.
- Objective: **state grammar is a genuine strength** — truth-states are modelled, not faked; empty ≠ error ≠ denied everywhere in FMN and Home.

## 7. Objective cross-surface conclusions (evidence-backed)

1. On Home, **four numeric count tiles** occupy a prominent block; the **child's media does not appear above the fold** (emoji + numbers stand in).
2. The **same `get_child_journal` payload** drives both Home summary and Journey — semantic distinction between the two is thin.
3. **The same family content appears in two shells** (`/parent/family` vs `/family`) with different chrome, width, and member affordances.
4. **Metadata precedes memory content in the Memory Room** (title→creator→date→source→people→media), the inverse of the media-first stream card.
5. **`/parent/family` mixes archive + administration** on one surface; below the archive card the page is management UI.
6. **Two creation CTAs co-exist** on both family surfaces (archive `onCreate` + standalone "Tạo kỷ niệm").
7. **Retrospection is split across three labels/surfaces** (Journey / "Nhìn lại" / "Bản Khám Phá Nghệ Thuật").
8. **Truth-state presentation (loading/empty/error/denied)** is consistently modelled and actor-correct — a reuse asset, not debt.
