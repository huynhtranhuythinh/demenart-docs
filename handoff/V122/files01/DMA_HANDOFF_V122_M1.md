# 🎞️ DMA_HANDOFF_V122_M1.md — PARENT JOURNEY · M1

> **Sprint closeout** — Session-Bundle Regroup ở `/parent/journal` (một buổi học = một unit; moments gom vào bundle; "Buổi học"; deep-link `moment:<id>`→bundle + a11y). DB additive tối thiểu + frontend regroup.
> **Đọc boot:** `DMA_RULES.md` → `DMA_SYSTEM_MAP.md` → **file này** (mới nhất), rồi re-pin live DB inventory + `list_edits` trước khi làm.

---

## A. VERDICT

**`FINAL PASS — DMA V122-M1 CLOSED & CANONICALIZED`.** Owner Gate PASS trên production `demenart.com` (real-login, 24 ảnh, 08/08/2026). Một buổi học gom thành 1 unit chọn được; fan-out biến mất; badges/skills vẫn ẩn; deep-link + focus-move + announce hoạt động. Canonicalized (RULES **D340** · SYSTEM_MAP **v1.28**).

## B. ENDPOINT

- **RULES:** D340 · **SYSTEM_MAP:** v1.28 · **HANDOFF:** V122-M1
- **Frontend HEAD (accepted tip):** `2d33018b` ("Reverted sandbox to v2.8.5")
- **Registry:** 119 (bất biến) · **Route:** 52 convention (bất biến)
- **DB inventory (re-verified):** 89 tables · 215 functions · 204 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron · 16 Edge · migration mới nhất **`v122_m1_child_journal_session_id` (`20260807130914`)**
- **Tooling:** `@lovable.dev/vite-tanstack-config` **exact 2.8.5** (package.json == bun.lock, verified `read_file` L65 + L241 sha512) · Bun authority · `bun.lock` lockfile duy nhất

## C. PRODUCT OUTCOME (cái gì đổi cho người dùng)

`/parent/journal` từ "museum một-kỷ-vật-rời-rạc" → **artifact lookback có liên tục buổi-học**:

1. **Một buổi học = MỘT unit** — mọi moment approved/child-tagged cùng `session_id` gom vào bundle; moment KHÔNG còn là card riêng trên rail (fan-out collapse). An: 45 events → **38 units**; Bình: 7 → **2 bundles**.
2. **Session = "Buổi học"** (không auto "Mốc hành trình") + "📸 N khoảnh khắc trong buổi học này"; rail cover = ảnh moment đầu + ⭐ marker; session-no-media = book (teacher note vẫn valid).
3. **Media collection trong bundle** — moment-switcher "Khoảnh khắc x/N" + privacy badge; lazy sign chỉ moment đang xem.
4. **Standalone giữ nguyên** — parent_memory · family · creation · unlinked-moment (byte-untouched rendering).
5. **Deep-link** — `moment:<id>` mở đúng session bundle chứa nó; missing/wrong-child → banner honest; focus DOM nhảy vào detail (`preventScroll`) + `aria-live` announce "loại · ngày".
6. **Badges/skills VẪN ẨN** khỏi Journal (LINH HỒN). Interpretive lookback thuộc `/parent/discovery` = "Nhìn lại" — không tái dựng trong Journey.

## D. TECHNICAL SCOPE

### C1 — DB (additive, D340.1)
Migration **`v122_m1_child_journal_session_id`** (`20260807130914`): CREATE OR REPLACE `get_child_journal(uuid)` thêm `session_id` **2 phía** — journey[] `CASE WHEN entry_type='session' THEN ref_id ELSE NULL END` · moments[] `lm.session_id`. D92 3-block + D15 re-REVOKE/GRANT (ACL `{postgres,authenticated,service_role}`, 0 anon leak) + verify DO-block. Authz gate/`search_path=''`/guards/keys/signature **bất biến** → PostgREST reload không bắt buộc (jsonb-internal). **Expose 1 phía là không đủ** — cần khóa đối ứng cả moment.session_id VÀ session-entry ref_id.

### C2 — Frontend regroup (minimal-ripple, D340.2)
- `src/features/journey/parentJourneyModel.ts` — **S1:** `session_id` optional trên `JourneyEntry`/`MomentRow` + `JourneyUnit` types + `buildJourneyUnits` (anchor first-per-session, absorb same-session moments, standalone rest; sort occurredAt DESC + tie-break id ASC) + `findUnitIndexForFocus` (moment→bundle). `buildParentTimeline` **giữ nguyên** (Home).
- `src/features/journey/ParentJourneyViewer.tsx` — **S2:** `buildJourneyUnits`→units→collapsed `items` (one-event-per-unit) + `coverOverrides`/`kindOverrides` + `sessionMoments` xuống Detail/Stage; focus via `findUnitIndexForFocus`. **S4:** `deepLinkFocusRef` focus-move effect + `unitAnnounceLabel` live-region + focusable detail wrapper.
- `src/features/journey/JourneyRail.tsx` — **S2:** props `coverOverrides`/`kindOverrides` + `coverFor`(useCallback)/`kindFor`/`isSessionUnit`; `MemoryObject` nhận `kind`/`cover`; ⭐ marker cho mọi session unit.
- `src/features/journey/JourneyStage.tsx` — **S3:** `SessionBundleStage` (reuse `MomentMedia` + moment-switcher + `MomentPrivacyBadge`, chỉ media-bearing moments); session-no-media→`SessionCard`; relabel "Mốc hành trình"→"Buổi học".
- `src/features/journey/JourneyDetail.tsx` — **S3:** chip "Buổi học" + "📸 N khoảnh khắc"; prop `sessionMoments`.
- `routeTree.gen.ts` — forbidden (D339.3), không đụng.

**Backend khác/DB/routes:** 0 delta ngoài migration trên. Không Edge, không route mới, không dependency mới. Creations KHÔNG gán session.

## E. OWNER GATE — EVIDENCE (production `demenart.com`, real-login, 24 ảnh, 08/08/2026)

- **An** (`ph.hung.kidshouse@demo.demenart.com`) — 45 events → **38 units** (5 sess + 21 active pmem + 1 family + 10 creation + 1 unlinked moment; 6/7 moments absorbed vào 2 ref_id sessions, 1 standalone — **no moment lost**, reconciled live-DB); create-test → **38→39** + focus item mới; ⑩ malformed `journey:khong-ton-tai` + wrong-child `journey:265f30a4` → banner honest, không lộ data Bình; ⑭ Network 8/88 media req (lazy + dedup).
- **Bình** (`ph.toan.kidshouse@demo.demenart.com`) — 7 events → **2 session bundles** (cover = ảnh moment + ⭐; "1 khoảnh khắc"/switcher 4-moment "Khoảnh khắc 1/4→3/4"); deep-link `moment:093cc871…`→bundle 1/7, `journey:265f30a4…`→bundle 1/7 ✓.
- **Jenny** (`parent.demo@demenart.com`) — có confirmed badge + skill nhưng **Journal KHÔNG hiện panel badge/skill** (§7 ✓); session-no-media = book + ⭐.
- **Khang** (đổi từ An) — empty/thin trung thực; moment 26/6 blank = **seed 0-media** (`learning_moments d1000000-…-a2` approved, `media_assets`=0 rows — content gap, KHÔNG phải bug; standalone-moment path V122 không đụng).

**Scenario tally (15):** ①latest ②month ③fan-out+no-loss ④moment→session ⑤journey deep-link (URL) ⑥provenance ⑦create→refetch→focus ⑧archive ⑨rapid-switch ⑩focus-honesty ⑪session-no-media ⑬a11y ⑭lazy+dedup ⑮100-item(model test) — **PASS**. ⑫consent-denied = defer (no fixture). **Verdict: OWNER GATE PASS — V122-M1 CLOSED.**

**⑮ 100-item deterministic model test (§14):** `buildJourneyUnits` với 100 units (20 bundles hấp thụ 60 moments + 10 null-ref sessions + 15 unlinked moments + 20 pmem + 5 family + 30 creations + 5 badges) → 0 moment lost, bundle=distinct session_id, badges excluded, deterministic ordering+tie-break, moment→bundle focus, missing=−1; 2ms/100 · 11ms/600 units.

## F. TOOLING / RECOVERY NOTE (D340.4)

Sandbox Lovable non-frozen init **re-float** `@lovable.dev/vite-tanstack-config` 2.8.5→2.9.1 **mỗi agent-install** (S1 `6ef509af`, S2/S3 `4bec89f2`, S4 `c884ebbe`) — 3 lần, mỗi lần verify trực tiếp `read_file` (package.json + bun.lock L65/L241) rồi revert bằng restore 2 lockfile từ SHA canonical (KHÔNG chạy non-frozen install → không re-float). **Production KHÔNG chạm** (Cloudflare `SKIP_DEPENDENCY_INSTALL=1` + frozen-install → 2.8.5 deterministic). Agent envelope commit_sha nhiều lần diverge narrative (`8b7275d`/`ed24494`/`1e45c6f` sandbox-only) → authority = `list_edits` + `read_file`@SHA (D339.5).

**Lineage:** `ed9ca9e5` → [mig `20260807130914`] → `6ef509af`(S1) → `9f7d1926` → `4bec89f2`(S2/S3) → `0994b079` → `c884ebbe`(S4) → **`2d33018b`**.

**Gates `2d33018b`:** frozen-install → 2.8.5 · tsc 0 · build-green by composition · session_id two-sided live · S1–S4 verified `read_file`@tip.

## G. RESIDUAL DEBT (record-only — KHÔNG fix ở M1)

- **P2 (media pipeline, RIÊNG)** — **Bunny image optimization thiếu:** ảnh gốc served 2–7 MB/tấm (Network Owner Gate ⑭) → load nặng/chậm. Ngoài scope V122 (lazy+dedup PASS). Backlog: bật resize/transform/nén Bunny `dma-private`/`dma-learning`.
- **P3** — restore parent-memory chỉ qua toast "Hoàn tác" tạm (đúng §11 no archive browser); cân nhắc entry-point khôi phục bền.
- **P3** — moment không-media render khung xám (Khang 26/6) → nên empty-state "Khoảnh khắc này chưa có ảnh".
- **OWNER GATE OBLIGATION / defer** — consent-denied fixture (⑫ chưa observe deny-live; fail-closed source-proven; nợ CONSENT-NEGATIVE-FIXTURE).
- **Optional §7** — Home Daily-Focus → journal focus CTA chưa wire (data đủ: outcome trả `journey_id`).
- **P2 tooling-governance** — three-times-proven (D340.4): bỏ khỏi `minimumReleaseAgeExcludes` + hard-pin → maintenance milestone RIÊNG, cần CTO mở. Paste-mode sidestep hoàn toàn.

## H. NEXT (câu hỏi sản phẩm, KHÔNG milestone)

Journey giờ liên tục theo buổi. Mở cho phiên sau: (1) Bunny image optimization (P2 — ảnh hưởng cả Home/Journal/School drive) nên là milestone media-pipeline riêng; (2) tooling-governance maintenance milestone chấm dứt re-float; (3) có nên wire Daily-Focus→journal CTA (optional §7); (4) restore-entry-point bền cho archived memory. *(Ngoài ra: Kid Portal V2, Media Organization Sprint, /admin interior — chưa xếp.)*

---

**Trạng thái:** `FINAL PASS — DMA V122-M1 CLOSED & CANONICALIZED`. RULES D340 · SYSTEM_MAP v1.28 · HANDOFF V122-M1 · HEAD `2d33018b`.
