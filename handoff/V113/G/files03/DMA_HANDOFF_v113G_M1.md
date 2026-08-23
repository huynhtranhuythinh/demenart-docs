# 📦 DMA_HANDOFF_v113G_M1.md — PARENT PORTAL EXPERIENCE SHELL MILESTONE (17–18/07/2026)
> **Verdict CTO/PO: `V113G-M1 — PASS` · Production HEAD chấp nhận: `4014427d` · Canonicalized một lần (RULES D309 · SYSTEM_MAP v1.14).**
> Thay thế chuỗi handoff lẻ: KHÔNG có handoff riêng cho G.1/G.2/G.3 — đây là milestone handoff duy nhất. Handoff canonical trước đó: v112F.

---

## 1. MILESTONE OUTCOME (đÃ PASS — không future tense)

Cổng ba mẹ đã được tái sinh trong một shell thống nhất, PRODUCTION-VERIFIED trên demenart.com (desktop + iPhone thật của PO):

| Work package | Kết quả |
|---|---|
| **G.1** Foundation + Hôm nay | Shell 3-composition (rail ≥1024 · tablet bar+drawer 480–1023 · mobile header+bottom nav ≤479, item 4 `Của con`) · DMA token layer `.dma-parent` · fonts Playfair/Be Vietnam Pro qua head links · Hôm nay canonical (MemoryHero deterministic + deep-link `?focus`) · Correction-A sequencing |
| **Amendment 479** | `--breakpoint-dtab: 480px` — iPhone ~430px về đúng mobile bottom nav; 500px vẫn tablet |
| **G.2** Hành trình + Nhìn lại + Share | Journal mounted composition (dead branch V74/75 GỠ, −163 lint) · Share re-home **Option B** vào JourneyDetail (moment-only, contract nguyên TTL 1440 / `/share/{token}` / private) · Discovery rebind provider + shared switcher · `prevChildRef` hydrate guard (P1 fix `567d2cc4`) · deep-link focus/capsule truthful 3 lớp |
| **G.3** Gia đình / FMN | **Option A: PARENT SHELL OUTSIDE — FMN INSIDE — MINIMUM BRIDGE.** Route chrome DMA; 15 file FMN core byte-untouched; `/family` standalone zero-leakage (đo trực tiếp); Memory Room round-trip giữ `?y&m` + switcher |

**Commit range (main, contiguous):** `8b5e6252 → 9385345c → 31ef2932 → c6d90054(out-of-band, audited) → 8021c940 → [12917e93 → 4f577a3c → 789564b7 → 1cf65494 → ccd955e0](phiên-treo G.2, audited third-party) → e610434c → 567d2cc4 → 4014427d`.
**CI exposure:** `deploy_project was not called; production was updated indirectly through Cloudflare CI` — áp cho TOÀN BỘ range.

## 2. PROTECTED TRUTHS (không được vi phạm ở sprint sau)

- **Production truth:** GitHub `main` → Cloudflare Pages = demenart.com; mọi commit main = production-affecting (D309.1). Operating mode hiện hành: **direct-main approved** + re-pin + single-writer + contiguous range (D309.2–3); branch isolation = future option, KHÔNG phải gate.
- **Shell grammar 479/480/1024** + shared `ParentChildProvider`/`ChildSwitcher` + `prevChildRef` guard (D309.4).
- **Share:** moment-only, private-only, contract cũ nguyên vẹn; không public/social audience; token không log (D309.5).
- **Parent–FMN boundary:** không retoken FMN; không token leakage sang `/family`; authorization/governance/preserve/archive/consent 0 đổi (D309.6, kế thừa D284/D293/D305).
- **Backend 0 đổi trong toàn milestone:** mig 101 · secdef 190 · routes 52 · edge 16 · consent 9 types — mọi thay đổi là frontend route-chrome/shell.
- **QA gates:** matrix 9 mốc · 0E/0W changed files · full lint ≤ baseline · production smoke · diff-zero rationale cho core untouched · mutation cần Owner authorize (D309.7).

## 3. INVENTORY (đo sống 18/07/2026, không sao chép)
**87 tables · 190 secdef · 164 policies · 1 cron · 101 migrations · routes 52 (raw fullPaths 57) · 16 edge functions · journey 37 (36 non-family + 1 family) · preserve 5 = 1/3/1 · threads 2/3 · cards 16 (15/1).** Delta so V112C: 0 (mọi số backend nguyên — milestone thuần frontend).

## 4. OPEN DEBT (carry-forward, không blocker)
1. **Fixture-backed FMN E2E** (voice/video card · engagement-open · preserve action · invited-member login Bà Ngoại Test) — cần phiên riêng có PO authorize mutation/fixture.
2. Favicon generic (polish G.8-era).
3. Incognito console verify (hydration = extension-inject, hồ sơ 2 lần).
4. Media retry-backoff — CHỈ nếu sự cố carrier/CDN 17/07 tái diễn (đã CLOSED AS TRANSIENT).
5. Import-order cosmetic `parent.family.tsx` (rpcUntyped const giữa imports — hợp lệ).
6. Repo-wide lint debt: **4.762E/25W** (đầu milestone 4.937/32 — M1 GIẢM 175E/7W).
7. (Kế thừa Phase 2/3 FMN) S-level creator/subject dedup theo `profile_id`; window-scoped presence; Recall/Chapters/Search/AI deferred.

## 5. NEXT SAFE STARTING POINT
- HEAD: `4014427d` (hoặc doc-only commit sau đó). Trước MỌI work package: re-pin + `list_edits` + single-writer check (D309.3).
- Ứng viên kế tiếp (chưa mở, chờ CTO/PO): **G.4+ restyle phần còn lại của Parent** (consent / settings / kid vẫn amber-nguyên trong shell mới — hoạt động đúng, chỉ chưa đồng bộ ngôn ngữ thị giác) HOẶC phiên **FMN E2E fixture** đóng nợ #1.
- Tài khoản test + hạ tầng: xem SYSTEM_MAP v1.14 (không đổi).

*⭐ Handoff này absorb toàn bộ `DMA_V113G_M1_DECISION_LEDGER.md` (ledger tạm — đã seal ABSORBED) + 4 closeout G.1/Amendment/G.2/G.3.*
