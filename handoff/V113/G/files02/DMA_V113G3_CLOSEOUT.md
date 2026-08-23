# DMA V113G-M1 G.3 — GIA ĐÌNH / FMN SURFACES · CLOSEOUT A–Q
2026-07-18 ~12:05 GMT+7 · Claude PM/Builder.

## A. VERDICT
**PASS — FAMILY / FMN SURFACES IN PARENT SHELL COMPLETE. PRODUCTION-VERIFIED LIVE.**

## B. USER OUTCOME (verified sống trên demenart.com)
Parent mở Gia đình trong shell mới (rail/tablet/mobile đúng grammar) → identity DMA "Cổng ba mẹ / Gia đình" serif → shared persisted ChildSwitcher (An↔Khang, notice truthful khi con không thuộc space — với data hiện tại cả 2 con đều thuộc "Gia đình Hùng" nên notice đúng là KHÔNG hiện) → FMN Stream nguyên bản V111D/V112C (chapter 2026·Tháng 7·15 ký ức, archived chip (1), creator "Bà ngoại đã thêm") → click card → **Memory Room route-backed V111E** mở đúng với `origin=/parent/family` hint → "Quay lại" → **về đúng `/parent/family?y=2026&m=7`, switcher + tháng + space giữ nguyên** — vòng khép kín không mất context.

## C. BASELINE
HEAD vào: `567d2cc4` (re-pin verified, single-writer verified — zero commit lạ, workspace yên tĩnh sau 03:10Z) · static baseline 4.774E/26W · fingerprints 4/4 · migrations 101/secdef 190.

## D. TOKEN RECONCILIATION (Owner: PARENT OUTSIDE — FMN INSIDE — MINIMUM BRIDGE)
Parent owns (đã thi công): route chrome, identity/eyebrow serif, switcher, TruthState loading, outer spacing/cards quản trị (members/pending/invite/create-form/dialogs → DMA tokens), khung stream `rounded-3xl border-dma-hairline bg-dma-ivory-raised` (bridge inset). FMN giữ nguyên 100%: 15 file core mtime nguyên ZIP, `--fmn-*` sống trong stream, **nút "Tạo kỷ niệm" giữ `var(--fmn-living)`** (bản sắc), FamilyQuietNotice V111C cho denied/error (grammar FMN đúng chỗ). **Leakage proof 2 chiều:** `/parent/family` chạy trong `.dma-parent`; `/family` standalone đo trực tiếp: h1 KHÔNG serif, `.dma-parent` ABSENT, stream chạy nguyên — zero Parent token chạm member route.

## E. IMPLEMENTATION
1 file duy nhất: `src/routes/_authenticated/parent.family.tsx` (754→810 dòng). Commit: **`4014427d`** (tsgo pass, byte-exact qua code--write trace). Nội dung: header V113G.3 · shared context (`children/loadingChildren/selectedChildId`) · `orderedSpaces` sort (space chứa selected child trước) · notice truthful child-without-space · TruthState loading · DMA tokens toàn bộ chrome quản trị · bridge khung stream · rpcUntyped pattern (gỡ 5×any + 1 deps-warning pre-existing) · `"ready"` vocab đúng grammar V111B.

## F. AUTHORIZATION PROOF
Capabilities-driven UI **không đổi một dòng logic**: `invite_member`/`create_card` từ backend, guardian badge, `guardian_member_protected`, remove/revoke/mint contracts + error maps giữ nguyên verbatim (diff = style-only quanh các khối này). Không canManage. Backend/RPC/RLS/consent: 0 thay đổi (fingerprints + migrations nguyên). `/family` member route verified sống.

## G. CHILD CONTEXT PROOF
Shared ChildSwitcher persisted xuyên /parent↔journal↔discovery↔family (đo sống: An giữ nguyên khi quay từ Memory Room). Race: data là family-level (1 RPC không nhận child param — backend truth) nên đổi con không refetch → **không tồn tại stale-cross-child surface theo thiết kế**; đổi con chỉ đổi sort + notice, đo 600ms chuẩn. Cross-child detail: Memory Room là route riêng ngoài scope switcher — không áp dụng.

## H. RESPONSIVE MATRIX — 9/9 + ZERO OVERFLOW
| Mốc | 1440 | 1024 | 1023 | 768 | 500 | 480 | 479 | 430 | 390 |
|---|---|---|---|---|---|---|---|---|---|
| Shell | rail | rail | tablet | tablet | tablet | tablet | **bot** | **bot** | **bot** |
| Overflow | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
Visual: ss_2473fiboh (desktop) · ss_9676epnym (390 mobile). Stream/archive nav recompose sạch trong khung mới.

## I. FMN QA (matrix §11 — trạng thái trung thực)
PASS đo sống: context 1–5,7–8 ✓ (6 = notice-path verified về logic, không kích hoạt tự nhiên vì cả 2 con đều thuộc space — data truth) · stream 9,11,16,17,18,19,23 ✓ (chapter/ordering/archived-chip/image/fallback) · detail 25,26,30,31 ✓ (Room + creator + time + return) · **NOT-TESTED read-only (honest):** voice/video card (space hiện không có card loại này trong tháng hiển thị), engagement/conversation mở (fetch-on-open giữ nguyên code V111E — không đụng), preserve actions (guardian-only giữ nguyên code — không mutation), create/invite flows (mutation cấm — contracts verbatim-preserved). Các mục này thuộc lớp FMN KHÔNG bị sửa (mtime nguyên) nên rủi ro hồi quy = diff-zero.

## J. REGRESSION
6/6 parent routes mount đúng h1 (home hero ✓) · `/family` standalone ✓ · `/share/$token` + `/family-invite` route contracts không đụng (diff-zero) · network 0 failed request · console: 0 error mới ghi nhận trong phiên (buffer mới; hydration-extension đã có hồ sơ 2 lần từ G.1/G.2).

## K. STATIC QA
Prettier PASS · eslint targeted **0E/0W** · tsc 0 · build local 0 · Lovable tsgo pass · **full lint 4.762E/25W** (baseline vào 4.774/26 → **−12E/−1W**, tổng M1 = **−175E/−7W** so đầu milestone) · 0 finding từ file G.3 · no new rule IDs · fingerprints 4/4 byte-identical.

## L. PRODUCTION CI EXPOSURE
Commit `4014427d` — **deploy_project was not called; production was updated indirectly through Cloudflare CI.** Production smoke PASS trực tiếp trên demenart.com (mục B/H/J).

## M. CHANGE PROOF
package/lock/routeTree/types: 4/4 hash nguyên · SQL/migrations 101 · RPC/RLS/Edge/consent/governance: 0 · FMN core 15 file: mtime nguyên ZIP · unrelated files: 0 · **production data mutation: 0** (mọi test read-only; không create/invite/remove/preserve nào được thực hiện).

## N. ROLLBACK
Revert `4014427d` → về `567d2cc4` (G.2 nguyên vẹn). CF tự deploy bản revert. Không backend/data cần đảo.

## O. OPEN DEBT
(1) FMN QA các mục mutation/fixture (voice/video/engagement-open/preserve-fixture/invited-member-login) — thuộc lớp không-bị-sửa, khuyến nghị 1 phiên E2E fixture riêng có PO authorize trước closeout M1 nếu muốn phủ 53/53. (2) Import-order thẩm mỹ trong parent.family.tsx (rpcUntyped const giữa imports — hợp lệ, không đẹp). (3) Các Open Items cũ chuyển tiếp (favicon G.8, Incognito console, retry-backoff media).

## P. MILESTONE STATUS
| Slice | Trạng thái |
|---|---|
| G.1 Foundation + Hôm nay | ✅ CLOSED |
| Breakpoint 479 amendment | ✅ CLOSED |
| G.2 Journey + Discovery + Share | ✅ CLOSED |
| **G.3 Gia đình / FMN in shell** | ✅ **CLOSED — PRODUCTION-VERIFIED** |

## Q. NEXT ACTION
STOP tại Milestone Review. Trả về ChatGPT/Product Owner. **Không canonicalize** (ledger tạm đã cập nhật — canonicalize MỘT LẦN tại M1 verdict). **Không mở G.4** (consent/settings/kid restyle candidates) trước targeted CTO review.
