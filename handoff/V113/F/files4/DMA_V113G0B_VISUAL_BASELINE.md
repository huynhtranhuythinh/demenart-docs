# DMA V113G.0B — PRODUCTION VISUAL BASELINE ADDENDUM
**Date:** 2026-07-17 (GMT+7) · capture window ≈ 12:10–12:31 GMT+7 (JS timestamps 2026-07-17T05:28:43Z & 05:30:31Z recorded in-page) · AUDIT-ONLY, zero mutation.

## 1. Environment truth
- **Environment: PRODUCTION** — `https://demenart.com` (no preview/local used).
- **Actor:** PH Nguyễn Văn Hùng (`ph.hung.kidshouse@demo.demenart.com`) — **login performed by the Product Owner himself** in the connected Chrome profile; Claude entered no credentials at any point. Actor verified on-page: header "Nguyễn Văn Hùng", hero "Chào ba mẹ của An 💛", child chips **An / Khang**, populated data (7 tác phẩm · 2 âm thanh · 6 khoảnh khắc · 21 ba mẹ lưu lại).
- **Selected child:** An (default) on all Parent captures.
- **Browser:** Chrome (macOS), extension "Browser 1", tab 1445491490, devicePixelRatio 2.
- **Viewport verification:** `window.innerWidth` measured via in-page JS before/after each pass — 1440 ✓ · 768 ✓ (verified start and end) · **mobile pass = 500px actual** (Chrome-on-macOS minimum window width is 500; 390 is unattainable by window resize and no DevTools device emulation is available through the extension — recorded as an environment limitation, NOT relabeled as 390. Mobile layout is fully active at 500 since the app's mobile breakpoint is `sm`=640).
- **Discarded invalid captures (viewport mismatch during window-manager lag):** ss_2675uqb21, ss_3458meowd, ss_46977j8ic (~1232px), ss_6443fzn85 (606px probe). Pre-login admin-session probes (not baseline): ss_16374h6yt, ss_88949fnfd, ss_1681srnbj, ss_8840i0qx2.
- **Incident:** browser MCP connection dropped once after a 21-action batch; PO reopened Chrome; resumed with ≤8-action batches. No data mutated at any point.

## 2. Screenshot index (30 valid captures — evidence ID = capture filename)

| Route | Desktop 1440 | Tablet 768 | Mobile-layout 500* |
|---|---|---|---|
| /parent | ss_4198lp4nu | ss_8652sfpxw | ss_1536dfjmb |
| /parent/journal | ss_9890x30tc | ss_8921xaoxr | ss_1831z3cnr |
| /parent/discovery | ss_06978sg33 | ss_9208lqg6u | ss_268316xea |
| /parent/family (→ ?y=2026&m=7) | ss_1588ajtf7 | ss_0010p1y9s | ss_2981oejqe |
| /parent/kid | ss_6815otv7k | ss_8356juosy | ss_3265vna01 |
| /parent/consent | ss_8681r6a2f | ss_9124z6dzk | ss_3549egdel |
| /parent/settings | ss_951685s14 | ss_9941zxyx5 | ss_0585wqv1k |
| /family | ss_0396pqozu | ss_9557qm6tk | ss_0869r0cju |
| /family/memory/c77eaddf-8085-4ea4-98c9-bf65c2dc911b ("Kỷ niệm 03", authorized) | ss_1198yq406 | ss_03225sx2f | ss_1184fncad |
| /family/memory/00000000-0000-0000-0000-000000000000 (denied probe) | ss_1997oeedh | ss_060988xtm | ss_14664id4y |

\* 500px = Chrome minimum; environment limitation recorded above.

## 3. Governance spot-verifications on production
- **Denied Memory Room (non-existent UUID):** renders generic panel — "Không thể mở ký ức này. Ký ức có thể không còn khả dụng hoặc bạn không có quyền xem." + "Quay lại". **No existence enumeration** — D305 confirmed live. Same treatment across all three viewports.
- **Authorized Memory Room:** direct deep-entry to an active card succeeded for a family guardian — server-side authorization path working.
- **Current production shell (drift, as expected pre-G.1):** amber theme; desktop top-nav Trang chủ/Hành trình/Gia đình/Cài đặt + bell + name + Đăng xuất; matches the G.0 source-audit findings exactly.

## 4. Console & network
- **Console errors:** 0 across the session (caveat: extension console tracking starts at first read-call; a post-tracking full reload of /parent also produced 0 errors).
- **Network:** 161 requests observed on the final /parent full load; the 80 inspected were **all HTTP 200** (page, hashed asset chunks, Cloudflare beacon). No failed/4xx/5xx requests observed in any tracked window.

## 5. Route-tree & repository fingerprint (before/after)
- **HEAD before captures = HEAD after captures = `b28cd9b7844b4cb6ec7a019a8064c48f85b0a0c3`** ("Fixed useFamilyArchive signature", 2026-07-16T11:38:43Z) — re-confirmed via `list_edits` at session end; no new commit exists.
- Fingerprint method: Lovable commits every change; `routeTree.gen.ts` is content-addressed by that commit. Zero write-capable tool calls were made this session ⇒ route tree byte-identical to the V113G.0 read.

## 6. Change proof
source files changed: 0 · route files changed: 0 · package/lockfile changed: 0 · SQL/migrations changed: 0 · generated types changed: 0 · production data mutated: 0 (all page visits read-only GET; no form submitted, no button with side effects clicked) · deployment performed: NO.

## 7. Evidence-debt ledger impact
- **Item 1 (production live visual baseline): CLOSED WITH EVIDENCE** — this addendum (30 captures, production, verified actor/viewports), with two recorded qualifications: mobile captured at 500px (environment minimum), and per-screenshot binaries live in the capture session under the ss_* IDs listed.
- Items 2, 3, 4 remain OPEN (unchanged); item 5 CLOSED (G.0); item 6 PARTIALLY EVIDENCED (G.0).

## 8. Next action
Return this addendum together with DMA_V113G0_AUDIT_CLOSEOUT.md to ChatGPT and the Product Owner. Do not begin V113G.1 until a new execution prompt is explicitly approved.
