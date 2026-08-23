# 🛠️ DMA_HANDOFF_V125_M0.md — TOOLING GOVERNANCE GUARD · M0

> **Sprint closeout** — Maintenance milestone **tooling-only** đóng nợ P2 tooling-governance (D342.5). Cài **guard fail-closed** kiểm tra tính toàn vẹn tooling TRƯỚC mỗi production Vite build, và chốt **safe-writer doctrine**. Trong quá trình làm, việc tạo file guard vô tình đi qua một `ai_update` đã **tái hiện** đúng cơ chế re-float `2.8.5→2.9.1`; đã recovery bằng manual writer về **byte-identical baseline**. **Zero product/dependency/DB/Edge/signer/Bunny/routes delta.** Net = 1 file governance + 1 dòng build-script.
> **Đọc boot:** `DMA_RULES.md` → `DMA_SYSTEM_MAP.md` → **file này** (mới nhất), rồi re-pin live DB inventory + `list_edits` + deployed signer version trước khi làm.

---

## A. VERDICT

**`FINAL PASS — DMA V125-M0 CLOSED & CANONICALIZED`.** Owner Gate PASS + Phase D FINAL PASS (ChatGPT Release Authority). Guard `scripts/assert-tooling-governance.mjs` (G1–G5, fail-closed, zero-dependency, assertion-only) giờ chạy trước Vite qua `bun run build`; Cloudflare production build từ `b3372e1c` PASS (frozen-install → guard ✓ → vite ✓); product smoke PASS. Tooling canonical **2.8.5** (bun.lock byte-identical baseline `5c5491e9`). Canonicalized (RULES **D343** · SYSTEM_MAP **v1.31**).

## B. ENDPOINT

- **RULES:** D343 · **SYSTEM_MAP:** v1.31 · **HANDOFF:** V125-M0
- **Frontend HEAD (accepted tip):** `b3372e1c977b72c485e4792075efbab4bbfb6148` (`b3372e1c`) — `manual_update`
- **Lineage:** `5c5491e9` → `383ad563` (**ai_update** guard-create — FLOAT reproduced) → `f6f69cef` (manual) → `2f9af126` (manual, floated tip) → `cce6c13b` (manual recovery) → **`b3372e1c`** (manual recovery, accepted tip). Verify authoritative `read_file`@SHA + `list_edits` (get_diff ẩn lockfile — D339.5).
- **Signer:** `get_signed_media_url` **deploy-25 = v24** — **BẤT BIẾN**, 0 delta
- **Bunny:** `dma-private`/`dma-learning`/`dma-public` — 0 change
- **Registry:** 119 · **Route:** 52 — bất biến
- **DB inventory (re-verified live):** 89 tables · 215 functions · 204 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron · 16 Edge · migration tail **`20260807130914`** — BẤT BIẾN (KHÔNG migration V125)
- **Tooling:** Bun sole PM · `bun.lock` sole lockfile (byte-identical baseline `5c5491e9`, sha256 `33cdc3cd…114a`) · `@lovable.dev/vite-tanstack-config` exact **2.8.5** · `2.9.1` count = 0 · `bunfig.toml` byte-unchanged

## C. PLATFORM OUTCOME (cái gì đổi)

Đây là milestone **tooling-only** — người dùng cuối KHÔNG thấy thay đổi UI/UX nào. Cái đổi là **kỷ luật build**:

1. **Guard fail-closed:** mỗi production build chạy `node scripts/assert-tooling-governance.mjs` trước `vite build`. Nếu tooling lệch canonical (pin ≠ 2.8.5, resolved set ≠ `{2.8.5}`, hoặc xuất hiện lockfile cạnh tranh) → build **dừng đỏ tại guard**, một tooling float KHÔNG thể ship im lặng ra production.
2. **Safe-writer doctrine:** prevention là paste-mode (`manual_update`); agent (`send_message`) là re-float path và bị cấm cho tooling-sensitive write. Guard KHÔNG sửa hành vi agent — chỉ chặn hậu quả.
3. **Kết quả ròng:** re-float tax (D342.5) giờ được containment hoá; mọi lần tái hiện sẽ bị guard bắt trước khi ra production thay vì phải phát hiện thủ công.

## D. TECHNICAL SCOPE (maintenance-only, 2-file envelope)

### File 1 — `scripts/assert-tooling-governance.mjs` (MỚI)
Node stdlib (`node:fs`, `node:path`), zero dependency, assertion-only (không auto-repair, không mutate). Năm invariant:
- **G1** — `devDependencies["@lovable.dev/vite-tanstack-config"] === "2.8.5"` (từ chối mọi range/caret/tilde).
- **G2** — root `bun.lock` bắt buộc tồn tại.
- **G3** — resolved set của config trong `bun.lock` phải **bằng đúng `{2.8.5}`** (MỌI version ≠ 2.8.5 fail; `2.9.1` có diagnostic đặc biệt nhưng không phải version cấm duy nhất). Regex target đúng resolution entry `[ "<pkg>@<ver>"` — bỏ qua manifest mirror + dependency spec; không parser, không dependency.
- **G4** — fail nếu có lockfile cạnh tranh: `package-lock.json` / `npm-shrinkwrap.json` / `yarn.lock` / `pnpm-lock.yaml` / `bun.lockb`.
- **G5** — PASS in 1 dòng; FAIL liệt kê invariant vi phạm + exit non-zero.

Test matrix cục bộ (disposable fixture) **T1–T11 PASS** đúng truth table: T1 PASS `{2.8.5}`; T2/T3 FAIL G1 (2.9.1 / ^2.8.5); T4–T9 FAIL G3 (`{2.9.1}`, `{2.9.2}`, `{3.0.0}`, `{2.8.5,2.9.1}`, `{2.8.5,2.9.2}`, `{}`); T10 FAIL G2; T11 FAIL G4.

### File 2 — `package.json` (build-script 1 dòng)
`"build": "vite build"` → `"build": "node scripts/assert-tooling-governance.mjs && vite build"`. Guard chạy trước Vite; Cloudflare authority `bun install --frozen-lockfile && bun run build` **KHÔNG đổi dashboard**. Không pre/postinstall, không đụng `dev`, không thêm package-manager command.

**Backend/DB/routes/dependency/bunfig:** 0 delta. Không migration, Edge, signer, Bunny, upload, route, dependency version.

## E. OWNER GATE — PRODUCTION EVIDENCE (ChatGPT Release Authority PASS — owner_attested)

| Gate | Evidence |
|---|---|
| Frozen install | `bun install --frozen-lockfile` PASS · không mutate `bun.lock` · không 2.9.1 |
| Guard-in-build | `bun run build` chạy `node scripts/assert-tooling-governance.mjs` TRƯỚC Vite · output `✓ tooling-governance OK — @lovable.dev/vite-tanstack-config@2.8.5 …` · exit 0 |
| Vite build | `vite build` PASS sau guard |
| Deploy | Cloudflare production build từ `b3372e1c` PASS |
| Product smoke | landing/auth · Parent · Teacher/School · School Drive mở · Family reachable — không route break / blank |

## F. RE-PIN (final, read-only — PASS)

- HEAD `b3372e1c` = tip (`list_edits`, no commit sau nó). Content tại fixed SHA bất biến.
- package.json@tip: build = `node scripts/assert-tooling-governance.mjs && vite build`; config = exact **`2.8.5`**; không `packageManager`, không install hook; deps khác nguyên.
- guard@tip = byte/semantic-identical artifact CTO-approved (G1–G5).
- bun.lock@tip = **byte-identical baseline `5c5491e9`** (size 185203, sha256 `33cdc3cd…114a`, `cmp` IDENTICAL); L66 mirror `2.8.5` · L242 resolution `@2.8.5` · resolved set `{2.8.5}` · **`2.9.1` count = 0**.
- bunfig.toml@tip = byte-unchanged. Lockfile inventory = chỉ `bun.lock` (no competing).
- signer live = deploy-25 v24 (BẤT BIẾN); DB inventory `89/215/204/166/33/1`, 16 Edge, migration tail `20260807130914`.

## G. ROOT-CAUSE & GOVERNANCE (khép nợ D342.5)

- **Prevention.** Recovery chạy hoàn toàn qua manual writer (2× `manual_update`, không `ai_update` mới) → restore + giữ tooling canonical, không drift mới. **KHÔNG nghĩa là hành vi AI-agent đã được sửa** — agent path vẫn unsafe; prevention dựa vào safe writer.
- **Detection/containment.** Guard fail-closed trên mọi tooling non-canonical, chạy trước mỗi production Vite build. Chứng minh hai chiều: fail đúng trên state đã-float `2f9af126` (G1+G3), pass trên canonical `b3372e1c`.
- **Reproduction fact.** Phase C: tạo file guard vô tình qua `ai_update` (`383ad563`) tái hiện đúng cơ chế re-float (package.json + bun.lock 2.8.5→2.9.1). Ghi làm **corroborating evidence**.
- **Count framing.** Canonical vẫn **D342.5 — FOUR-times-proven recurring mechanism**. V125 reproduction corroborate; **KHÔNG** viết lại count.
- **Causal restraint.** KHÔNG claim `minimumReleaseAgeExcludes` gây/kích hoạt float — vai trò nhân quả **NOT PROVEN**.

## H. RESIDUAL DEBT (record-only)

- **Bài học D343.5 — NEW-FILE CREATION PHẢI VERIFY WRITER-TYPE:** thêm file mới có thể route qua `ai_update` ngay cả khi ý định là paste-mode → PHẢI check `list_edits` mỗi lần thêm file; nếu `ai_update`, revert tooling ngay (hoặc tạo qua manual path đã verify) trước mọi build.
- **P3 (tùy chọn, Phase D+) — hardening bổ sung:** cân nhắc bỏ `@lovable.dev/vite-tanstack-config` khỏi `minimumReleaseAgeExcludes` + giữ hard-pin (partial hardening; **không** phải fix bảo đảm vì rewrite ghi đè cả pin đã cứng — cần CTO cân nhắc riêng, causal role vẫn NOT PROVEN).
- **P2 (inherited) — School Drive eager-sign / lazy (Candidate 2)**; media compatibility MOV/HEVC/WebM; consent-negative-fixture.
- **Build runner (nice-to-have):** guard chạy qua `node`; có thể đổi sang `bun` (one-token) nếu CTO muốn Bun-runner purity.

## I. NEXT (câu hỏi sản phẩm, KHÔNG milestone)

Nợ tooling-governance đã đóng. Mở cho phiên sau: (1) School Drive eager-sign/lazy + hook consolidation (Candidate 2, cần production evidence); (2) video/audio delivery optimization; (3) `/kid` Portal V2 (PIN-based); (4) optional excludes-hardening milestone. *(Không tự mở nếu CTO chưa lock.)*

---

**Trạng thái:** `FINAL PASS — DMA V125-M0 CLOSED & CANONICALIZED`. RULES D343 · SYSTEM_MAP v1.31 · HANDOFF V125-M0 · HEAD `b3372e1c` · signer deploy-25 (v24, BẤT BIẾN) · tooling 2.8.5 (bun.lock byte-identical baseline) · guard fail-closed trước mỗi production build. Agent re-float NOT fixed · `minimumReleaseAgeExcludes` causal role NOT PROVEN · D342.5 FOUR-times-proven.
