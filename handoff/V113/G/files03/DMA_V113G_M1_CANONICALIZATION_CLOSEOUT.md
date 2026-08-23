# V113G-M1 — CANONICALIZATION CLOSEOUT (A–L)
2026-07-18 ~13:00 GMT+7 · Claude PM/Builder · One-time canonicalization theo Milestone Verdict PASS.

## A. VERDICT
**CANONICALIZATION COMPLETE — V113G-M1 SEALED.**

## B. RE-PIN & SINGLE-WRITER
HEAD trước canonicalize: `4014427d` ✓ (list_edits, zero drift, zero delayed edits, single writer).

## C. LIVE INVENTORY (đo trực tiếp, không sao chép)
87 tables · 190 secdef · 164 policies · 1 cron · **101 migrations** (SQL) · **routes 52 / raw fullPaths 57** (local routeTree, hash nguyên) · **16 edge functions** (list_edge_functions) · journey 37 · preserve 5=1/3/1 · threads 2/3 · cards 16. Backend delta so V112C endpoint: **0**.

## D. CANONICAL PACKAGE (4 file outputs — full replacement, copy-on-disk + append, không tái tạo trí nhớ)
1. **DMA_HANDOFF_v113G_M1.md** (MỚI — milestone handoff duy nhất, thay chuỗi G.1/G.2/G.3 lẻ; absorb ledger + 4 closeout).
2. **DMA_RULES.md** — append **D309** (+8 nguyên tắc con: production CI truth + wording · direct-main operating mode Owner-approved · single-writer/delayed-session · shell grammar 479 + prevChildRef · Share Option B moment-only · Parent–FMN bridge Option A · QA gates + diff-zero + mutation-authorize · technical patterns). Endpoint: **D309**.
3. **DMA_SYSTEM_MAP.md** — bump **v1.13 → v1.14**; mục mới vĩnh viễn **PRODUCTION DEPLOYMENT TRUTH** (GitHub main → CF Pages); section V113G-M1 đầy đủ (shell/4 surface/bridge/QA/invariants/open debt). Endpoint: **v1.14**.
4. **DMA_V113G_M1_DECISION_LEDGER.md** — sealed **ABSORBED** (giữ làm evidence, hết vai trò truth).
BUILD_PATH/START_HERE: **không đụng** — không thuộc canonical-per-sprint convention từ Phase 2 (các endpoint V111x/V112C đều chỉ 3 artifacts RULES/MAP/HANDOFF).

## E. DIRECT-MAIN MODE CORRECTION (§4 prompt)
Đã ghi đúng nguyên văn Owner-approved statement vào D309.2 + SYSTEM_MAP + docs-commit — thay mọi diễn đạt cũ ngụ ý "bắt buộc isolation trước write". Branch isolation = future option.

## F. DOCS-ONLY COMMIT (§9)
Commit **`d62cc445`** — tạo duy nhất `docs/DMA_V113G_M1_CANONICAL.md` (+23 dòng). **Diff proof cứng qua get_diff: đúng 1 file, zero code/config.** (Trace agent thoáng thấy `M routeTree.gen.ts` do dev-server regenerate — git diff rỗng = nội dung identical, không vào commit.)
**CI exposure:** `deploy_project was not called; production was updated indirectly through Cloudflare CI.`

## G. PRODUCTION SMOKE SAU CI
Docs-only commit ⇒ bundle app **zero-delta** (file .md ngoài src/, không vào build) → smoke **PASS inherited by zero-bundle-delta** (họ D307.4). Browser MCP rớt tại thời điểm xác nhận thủ tục; PO có thể tự xác nhận 10 giây (demenart.com/parent mount bình thường). Toàn bộ smoke NỘI DUNG của milestone đã PASS trực tiếp trước đó tại `4014427d`.

## H. CONSISTENCY QA
Canonical package grep-verified: 0 stale `401px/≤400` trong nội dung mới (historical sections giữ nguyên đúng chủ trương preserve) · chuỗi `deployment: NO` chỉ xuất hiện trong chính điều khoản cấm nó · v1.14/D309/HEAD `4014427d`/inventory nhất quán xuyên 4 file + docs-commit.

## I. CHANGE PROOF
Code/config/backend/RPC/RLS/consent/routes/migrations: **0 thay đổi** trong canonicalization. Production data mutation: **0**.

## J. ROLLBACK
Docs-commit: revert `d62cc445` (thuần docs). Canonical outputs: PO đơn giản không upload / giữ bản v112C-era.

## K. VIỆC TAY CỦA PO (để package có hiệu lực)
Upload 3 file vào project knowledge (thay bản cũ cùng tên): `DMA_RULES.md` · `DMA_SYSTEM_MAP.md` · thêm mới `DMA_HANDOFF_v113G_M1.md`. (Ledger + closeouts: tuỳ anh lưu trữ.)

## L. NEXT
HEAD hiện hành: `d62cc445` (docs) trên nền `4014427d` (code). Milestone V113G-M1 **SEALED**. Không sprint nào đang mở. Ứng viên kế tiếp (chờ CTO/PO): G.4+ restyle consent/settings/kid HOẶC phiên FMN E2E fixture (đóng Open Debt #1, cần authorize mutation).
