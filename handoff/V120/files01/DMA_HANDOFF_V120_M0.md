# 🔧 DMA_HANDOFF_V120_M0.md — PLATFORM TOOLING GOVERNANCE · BUILD REPRODUCIBILITY & LOCKFILE AUTHORITY

> **CANONICAL ENDPOINT (đọc đầu mỗi phiên):** RULES **D338** · SYSTEM_MAP **v1.26** · HANDOFF **V120-M0** · frontend HEAD **`9a49e415`** (bất biến) · registry **119**.
> Boot protocol: đọc HANDOFF → RULES → SYSTEM_MAP từ đĩa/Jean-provided TRƯỚC mọi việc; re-pin repo + DB read-only; D1 audit live trước khi viết code.

---

## A. Executive verdict

**`V120-M0 FINAL PASS — BUILD REPRODUCIBILITY & LOCKFILE AUTHORITY GOVERNANCE CLOSED`**

Milestone **tooling-governance thuần**, không product work: **repository delta 0 · database delta 0 · product delta 0**. Toàn bộ correction ở **Cloudflare dashboard config**. Đóng dứt điểm mâu thuẫn authority phơi ra ở V119 (D337.5): repo tuyên bố Bun nhưng Cloudflare CI thực chạy **npm fresh-resolve KHÔNG lockfile** (vì `package-lock.json` đã xóa) — non-deterministic. Nay Cloudflare bị ép **Bun frozen-install**; Bun trở thành package-manager authority DUY NHẤT với `bun.lock` là lockfile authoritative DUY NHẤT.

- repository delta: **ZERO**
- database delta: **ZERO**
- product delta: **ZERO**
- Cloudflare dashboard/config delta only: `SKIP_DEPENDENCY_INSTALL=1` · `BUN_VERSION=1.2.15` · build cmd `bun install --frozen-lockfile && bun run build`
- Bun canonical · `bun.lock` sole authority · automatic npm install disabled · Bun pinned 1.2.15 tại Cloudflare · frozen install `bun install --frozen-lockfile`
- production deployed successfully từ `9a49e415` (deployment `6c5eeef4-7dcb-4c34-97f6-9014f8f9df0b`) · Owner production smoke **PASS**

---

## B. Baseline (accepted input trước V120)

- RULES **D337** · SYSTEM_MAP **v1.25** · HANDOFF **V119-M1**
- Accepted repository tip: **`9a49e4159b88a95dd8a68ebd98f63a610834ecd8`**
- Mainline parent: **`b93639af`** · `9a49e415` là **merge commit** với second parent **`d2759bc`**
- Lineage: `78b75e59` (V118-M2) → `b93639af` (V119-M1 impl) → `9a49e415` (V119 tooling correction, merge)
- Live structural inventory (re-pinned read-only Phase D — **zero drift**): **89 tables · 215 functions · 204 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron · registry 119 · route convention 52 · 16 Edge Functions**; latest migration `20260727115750 · v118_m2_appreciation_acknowledgement` (V119/V120 KHÔNG thêm migration).

*(KHÔNG mở lại route-count ambiguity; KHÔNG so migration registry với `admin_modules` row count — CTO đã khóa.)*

---

## C. Live audit findings (Phase A/D — read-only)

**Manifest & lock authority tại tip `9a49e415`:**
- 1 manifest (`package.json`), 1 lockfile (`bun.lock`, `lockfileVersion 1` Bun text). `package-lock.json` = **404 (đã xóa)**; không `pnpm-lock.yaml`/`yarn.lock`/`npm-shrinkwrap.json`/`.npmrc`.
- `@lovable.dev/vite-tanstack-config` = **exact `2.8.5`** ở CẢ `package.json` và `bun.lock` (resolve từ private registry Lovable GCP). `@hookform/resolvers` exact `5.2.2`.
- **KHÔNG** `packageManager` field, **KHÔNG** `engines`, **KHÔNG** `.github/workflows`, **KHÔNG** `wrangler.toml` → Cloudflare cấu hình dashboard-side.
- `vite.config.ts`: toàn bộ build toolchain (tanstackStart + viteReact + tailwind + tsConfigPaths + **nitro `cloudflare-pages`** + componentTagger + VITE_* + alias + dedupe) nằm TRONG devDep `@lovable.dev/vite-tanstack-config` (build-only nhưng là TOÀN BỘ build + route generation).
- `bunfig.toml`: `minimumReleaseAge=86400` + `minimumReleaseAgeExcludes` **4 gói** `@lovable.dev/*` (tooling + 3 transitive `mcp-js`/`dev-server-bridge`/`hmr-gate`).
- routeTree.gen.ts self-consistent, kết thúc `export const routeTree` + Register block **type-only** (`declare module '@tanstack/react-start'`); route membership bất biến (V119/V120 route delta = 0).
- DB/Edge inventory re-pinned Phase D = khớp canonical tuyệt đối (zero delta).

**`get_diff` blindness (LIVE-confirmed):** `get_diff(sha=9a49e415)` chỉ hiện **1 dòng** `package.json` (tooling `2.8.3→2.8.5`) và **ẩn hoàn toàn** việc xóa `package-lock.json` + thay đổi `bun.lock`. ⟹ `get_diff` **KHÔNG phải** lockfile authority.

---

## D. D326 ↔ D337 conflict (đã phân giải)

| Nguồn | Khẳng định |
|---|---|
| **D84** (v15) | Pages build cmd `bun run build` · output `dist` |
| **D326** (V116) | "Cloudflare CI build bằng **`npm install`**… repo bắt buộc mang `package-lock.json`… dual-lock" |
| **D337** (V119) | XÓA `package-lock.json`, "Bun authoritative" |

Mâu thuẫn: nếu D326 đúng (CI = npm) thì xóa `package-lock.json` = npm fresh-resolve no-lock → **non-deterministic** (latent P1). Cloudflare live evidence (Phase B/C) **chứng minh D326 ĐÚNG về đường-install npm** ⟹ D337 vô tình mở lại rủi ro. **D338 phân giải:** ép Cloudflare Bun frozen-install + Bun/`bun.lock` sole authority; **supersede D326** ở phần yêu cầu npm/dual-lock (D326 giữ như bằng chứng lịch sử).

---

## E. Governance decisions (CTO-locked, KHÔNG reopen)

1. Bun = package-manager canonical DUY NHẤT; `bun.lock` = lockfile authoritative DUY NHẤT; **KHÔNG dual-lock**.
2. Lockfile thứ hai (`package-lock.json`/`yarn.lock`/`pnpm-lock.yaml`/`bun.lockb`/…) tái xuất = **STOP**.
3. Cloudflare = explicit install authority (auto-detect vô hiệu qua `SKIP_DEPENDENCY_INSTALL=1`).
4. `@lovable.dev/vite-tanstack-config` giữ **exact pin `2.8.5`**; **KHÔNG** thêm `packageManager` field trong V120-M0.
5. Bounded maintenance cadence; planned tooling update = **maintenance commit RIÊNG**; KHÔNG chase moving latest trong product milestone; giữ 4 `minimumReleaseAgeExcludes`.
6. Conditional patch auto-accept (chỉ khi manifest==lock + route/runtime semantics bất biến + không lockfile thứ hai + không runtime dep mới).
7. Lockfile verify bằng direct `read_file`/hash tại GitHub SHA — `get_diff` KHÔNG phải authority.
8. Lineage authority: **GitHub `main` commit object** > Lovable `list_edits` > agent sandbox/narrative (SUPPORTING).
9. RouteTree phân loại bằng semantic set (import/path/`id` union), KHÔNG chỉ byte diff.
10. Tooling-only correction KHÔNG lặp lại toàn bộ Parent Outcome QA nếu route/runtime semantics không đổi.

---

## F. Cloudflare evidence

**Pre-correction (CF-C mismatch confirmed — Owner-provided):**
- project `demenart` · repo `huynhtranhuythinh/demenart` · branch `main` · auto-deploy enabled · build system **Version 3** · original build cmd `bun run build` · output `dist` · root = repo root · build cache **disabled**.
- Successful deploy `2d69ce9e-edb2-40e1-b0b9-f1d5709ab938` từ `9a49e415`: Cloudflare detected **`npm@10.9.2` / `nodejs@22.16.0`**, auto-install `npm install --progress=false`, user build `bun run build` → **PASS nhưng npm-installed** (repo chỉ có `bun.lock`) ⟹ **CF-C PACKAGE-MANAGER AUTHORITY MISMATCH**.

**Post-correction (Phase C, Owner — dashboard-only, repo delta 0):**
- `SKIP_DEPENDENCY_INSTALL=1` · `BUN_VERSION=1.2.15` · build cmd **`bun install --frozen-lockfile && bun run build`**; giữ output `dist` · root repo · build system V3 · cache disabled · branch `main`.

---

## G. Failed `bun ci` attempt (KHÔNG phải lỗi repo/product)

Retry đầu dùng `bun ci && bun run build` **thất bại**: Bun 1.2.15 hiểu `ci` là **package script**, không phải builtin → `error: Script not found "ci"`. Bun KHÔNG có lệnh `ci` kiểu npm; frozen-install đúng cú pháp = **`bun install --frozen-lockfile`**. Sửa build command, **KHÔNG đụng repository**. Đây là lỗi cú pháp dashboard command, KHÔNG phải product/repo failure.

---

## H. Final deployment evidence

- commit `9a49e4159b88a95dd8a68ebd98f63a610834ecd8`
- deployment **`6c5eeef4-7dcb-4c34-97f6-9014f8f9df0b`**
- stages: initialize PASS · clone PASS · build PASS · deploy PASS
- build-log proof (Owner-provided): Bun **1.2.15** detected · auto-install **skipped** · command `bun install --frozen-lockfile && bun run build` · frozen install **PASS** · application build **PASS** · deploy **PASS**
- **Owner production smoke: PASS**

*(CI/deploy evidence là Owner/dashboard-provided — Claude không có Cloudflare read access. Claude verify độc lập read-only: lineage tip via Lovable `list_edits` (không commit sau `9a49e415`), repo files via `read_file` @ SHA, DB/Edge inventory via Supabase SELECT, routeTree semantic. GitHub API độc lập bị rate-limit — GitHub-main authority dựa Owner/CTO evidence + Lovable corroboration.)*

---

## I. No-mutation statements

Toàn bộ 4 phase V120 = **read-only + dashboard-only**:
- ✅ zero repository mutation (không create/edit/delete file repo; không agent/send_message)
- ✅ zero database mutation (Supabase chỉ SELECT read-only + list_edge_functions)
- ✅ zero product/route/migration/Edge change
- ✅ zero commit / push / deploy trigger từ Claude
- ✅ zero canonicalization ngoài 3 file output phiên này (RULES append D338, SYSTEM_MAP v1.26, HANDOFF mới) — Owner tự upload Project Knowledge
- Cloudflare correction do **Owner** áp (dashboard-only); Claude KHÔNG thao tác Cloudflare.

---

## J. STOP-gates (mang theo phiên sau)

STOP nếu xuất hiện: (1) lockfile thứ hai tái xuất; (2) package-manager ambiguity ở CI; (3) runtime dependency mới ngoài dự kiến; (4) route membership delta (id-union); (5) migration/Edge delta ngoài dự kiến; (6) build/typecheck fail; (7) production revision ≠ tip đã duyệt; (8) generated file chưa phân loại; (9) product file contamination; (10) tooling major/minor upgrade; (11) lockfile bị ẩn khỏi verification; (12) second writer; (13) platform rewrite pin exact→range. Auto-accept-with-note: Register-block type-only regen; tooling patch trong pin exact thỏa conditional gates.

---

## K. Rollback contract

Correction là **dashboard-only** → rollback = revert 3 Cloudflare field (`SKIP_DEPENDENCY_INSTALL` / `BUN_VERSION` / build command) về trạng thái trước; **repository KHÔNG cần đụng** (đã ZERO). Repo rollback chỉ cần khi lockfile thứ hai tái xuất (STOP-gate). KHÔNG revert D338 canonical trừ khi CTO chỉ định.

---

## L. Remaining debt (P2/P3)

- **P2 (mở, non-blocking) — GitHub-main independent verification:** phiên này GitHub API rate-limit (không token) → GitHub-main HEAD/merge-parents dựa Owner/CTO + Lovable corroboration. Phiên có token nên xác nhận `9a49e415` parents `[b93639af, d2759bc]` trực tiếp.
- **P3 — `.env` tracked** (chỉ anon/publishable key public-safe, D63-compliant) — informational.
- **P3 — không pin Node/Bun version trong repo** (`engines`/`.tool-versions` vắng); Bun nay pin ở Cloudflare dashboard (`BUN_VERSION=1.2.15`), không ở repo (theo quyết định #4 KHÔNG thêm `packageManager` V120-M0).
- Nợ cũ V119 giữ nguyên: P3 placeholder ảnh xám `/parent/journal` (Khang) · V117-M3 · G.4+ restyle · V114-SEC1 · FMN E2E fixture · Day-state semantics v2 · Secondary-parent fixture · live-data gap "Xem thêm những buổi trước" (≤2 outcome/bé).

---

## M. Exact next-safe action

V120-M0 đóng. **Next-safe action = chờ CTO chọn milestone kế** (chưa mở): candidate product = **V117-M3 Parent outcome mở rộng** / **G.4+ restyle** / **V114-SEC1** / **FMN E2E fixture** / **Day-state semantics v2** / **Secondary-parent fixture**. Bất kỳ tooling update kế = **maintenance commit RIÊNG** theo D338 (không trộn product). Boot phiên sau: đọc HANDOFF (file này) → RULES (D338) → SYSTEM_MAP (v1.26) → re-pin `list_edits` (tip `9a49e415`) + DB inventory → D1 audit live.

*Endpoint: RULES **D338** · SYSTEM_MAP **v1.26** · HANDOFF **V120-M0** · code HEAD **`9a49e415`**. Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
