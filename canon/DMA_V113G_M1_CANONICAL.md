# DMA V113G-M1 — CANONICAL MILESTONE RECORD (docs-only)
Verdict CTO/PO: V113G-M1 PASS. Production HEAD chấp nhận: 4014427d. Canonical endpoint: RULES D309 · SYSTEM_MAP v1.14 · HANDOFF v113G-M1 (bản đầy đủ trong project knowledge của Product Owner).

## Milestone
- G.1 Foundation + Hôm nay: shell 3-composition (mobile ≤479 header+bottom nav "Của con" · tablet 480–1023 top bar+drawer · desktop ≥1024 rail), DMA token layer .dma-parent, fonts qua head links (Lightning-CSS không nhận remote @import), Hôm nay canonical + deep-link ?focus.
- Breakpoint Amendment: --breakpoint-dtab 480px (iPhone ~430 = mobile).
- G.2: Journey mounted composition (dead branch V74/75 gỡ), Share re-home Option B vào JourneyDetail (moment-only, contract nguyên: create_private_share_link TTL 1440 · revoke_share_link · /share/{token} private-only, token không log), Discovery rebind provider, prevChildRef hydrate guard, deep-link focus/capsule truthful.
- G.3: Gia đình Option A — PARENT SHELL OUTSIDE, FMN DESIGN SYSTEM INSIDE, MINIMUM BRIDGE. FMN core byte-untouched; /family standalone zero token leakage; Memory Room round-trip giữ ?y&m.

## Production truth
demenart.com = GitHub main → Cloudflare Pages CI (mọi commit main = production-affecting). Lovable hosting không phải production source. Wording bắt buộc khi CI deploy: "deploy_project was not called; production was updated indirectly through Cloudflare CI".

## Operating mode (Owner-approved)
Direct-main operating mode is currently approved because the platform has no active external users. Before every work package: re-pin HEAD, inspect delayed edits, verify a single active writer for the same DMA scope, keep a contiguous commit range, and treat every commit as production-affecting through Cloudflare CI. Branch isolation is a future option, not a current gate.

## Commit range M1 (contiguous)
8b5e6252 → 9385345c → 31ef2932 → c6d90054 → 8021c940 → 12917e93 → 4f577a3c → 789564b7 → 1cf65494 → ccd955e0 → e610434c → 567d2cc4 → 4014427d.

## Inventory (đo sống 18/07/2026)
87 tables · 190 secdef · 164 policies · 1 cron · 101 migrations · routes 52 (raw 57) · 16 edge functions · journey 37 (36+1) · preserve 5=1/3/1 · threads 2/3 · cards 16 (15/1). Backend delta so V112C: 0.

## Open debt carry-forward
Fixture-backed FMN E2E (voice/video/engagement/preserve/invited-member) · favicon · Incognito console verify · media retry-backoff nếu tái diễn · import-order cosmetic parent.family.tsx · repo lint debt 4.762E/25W (M1 giảm 175E/7W).

## Consistency patch (2026-07-18, docs-only)
- Stack line hiện hành đã được đính chính trong DMA_RULES.md: production = Lovable → GitHub main → Cloudflare Pages CI → demenart.com; Vercel chỉ còn là nhãn historical/dormant.
- DMA_SYSTEM_MAP.md nhận khối "CURRENT CANONICAL ENDPOINT — D309 / SYSTEM_MAP v1.14 / HANDOFF v113G-M1" gần đầu tài liệu + 6 nhãn "HISTORICAL SNAPSHOT — KHÔNG PHẢI CURRENT SYSTEM TRUTH / NEXT ACTION" trên các section lịch sử (Bước kế/CHƯA làm/deploy Vercel/inventory cũ) — lịch sử giữ nguyên, chỉ ngăn đọc nhầm thành chỉ thị hiện hành.
- Bản đầy đủ DMA_RULES.md + DMA_SYSTEM_MAP.md sống trong project knowledge của Product Owner (không nằm trong repo này); exact diff của patch được lưu kèm closeout phiên.
- D309, HANDOFF v113G-M1, canonical inventory, product code, decision ledger (ABSORBED): KHÔNG thay đổi.
