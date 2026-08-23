# 🖼️ DMA_HANDOFF_V124_M1.md — BOUNDED SCHOOL DRIVE & FAMILY VARIANT WIRING · M1

> **Sprint closeout** — Tiêu thụ V123 signer bundle trên School Drive + Family bằng **consumer wiring thuần frontend** (Candidate 1). Ảnh riêng tư trên Kho trường + Không gian gia đình giờ tải variant WebP right-sized thay vì bản gốc multi-MB. **Zero signer/Edge/DB/migration/Bunny/routes/tooling delta.** 2-file envelope.
> **Đọc boot:** `DMA_RULES.md` → `DMA_SYSTEM_MAP.md` → **file này** (mới nhất), rồi re-pin live DB inventory + `list_edits` + deployed signer version trước khi làm.

---

## A. VERDICT

**`FINAL PASS — DMA V124-M1 CLOSED & CANONICALIZED`.** ChatGPT Release Authority = **OWNER GATE PASS** (4 Network screenshot production, real-login `demenart.com`). School Drive grid tile giờ request `thumb` (256) và preview request `stage` (1280); Family stream cover/detail dùng `card` (768), glimpse 64px dùng `thumb` (256) — tất cả qua V123 signer bundle đã có sẵn, KHÔNG đổi signing/authz architecture. Signer BẤT BIẾN (deploy-25 v24). Δ signer calls = 0. Tooling re-float 2.9.1 (lần 4) đã bắt + revert về **2.8.5**. Canonicalized (RULES **D342** · SYSTEM_MAP **v1.30**).

## B. ENDPOINT

- **RULES:** D342 · **SYSTEM_MAP:** v1.30 · **HANDOFF:** V124-M1
- **Frontend HEAD (accepted tip):** `5c5491e952382d5017af5dab077d8fb9a976ecaf` (`5c5491e9`)
- **Lineage:** `06975654` → `a3adc133` (Family memoryRoomShared) → `44e51fa8` (School DriveExplorer) → **`5c5491e9`** (tooling revert 2.8.5). 3 `ai_update`, verify authoritative `read_file`@SHA + `list_edits` (get_diff ẩn lockfile — D339.5; envelope/narrative SHA diverge từ sandbox, không tin).
- **Signer:** `get_signed_media_url` **deploy-25 = v24** — **BẤT BIẾN**, 0 delta (chỉ tiêu thụ bundle sẵn có)
- **Bunny:** `dma-private` Optimizer ON · WebP · Dynamic Image API — 0 change
- **Registry:** 119 · **Route:** 52 — bất biến
- **DB inventory (re-verified live):** 89 tables · 215 functions · 204 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron · 16 Edge · migration tail **`20260807130914`** — BẤT BIẾN (KHÔNG migration V124)
- **Tooling:** Bun sole PM · `bun.lock` sole lockfile · `@lovable.dev/vite-tanstack-config` exact **2.8.5** (re-float 2.9.1 bắt + revert; `2.9.1` count=0 trong lockfile)

## C. PRODUCT OUTCOME (cái gì đổi cho người dùng)

Ảnh riêng tư trên hai surface còn lại giờ tải **nhẹ + nhanh**, giữ nguyên UX/bố cục:

1. **Kho của trường — grid tile** (`/school/drive`): thumbnail ~200px dùng `thumb` **256px WebP** (~9–21 KB) thay bản gốc 0.03–2.98 MB → **giảm >90%**, cuộn kho mượt.
2. **Kho của trường — preview/lightbox**: mở ảnh lớn dùng `stage` **1280px WebP** (~35 KB); 1 request/lần mở, KHÔNG preload original.
3. **Không gian gia đình — cover/detail** (`/family`, `/family/memory/:id`): ảnh dẫn + gallery dùng `card` **768px WebP** (~11–12 KB).
4. **Không gian gia đình — glimpse 64×64**: thumbnail nhỏ dùng `thumb` **256px WebP** — xoá lãng phí lớn nhất (trước đây multi-MB gốc render ở 64px).
5. **Video/audio KHÔNG đổi**; list view Kho vẫn icon-only (0 image request); original chỉ là fallback tương thích.

## D. TECHNICAL SCOPE (Candidate 1 — frontend wiring only)

### File 1 — `src/features/family/memoryRoomShared.tsx` (Family)
- Import `pickVariant` + `VariantRole` từ `useJourneySigning`.
- `MediaTile`: thêm `imgFellBack` state + effect reset ladder theo `item.mediaId`; nhánh `image` dùng **implicit role dispatch** `role = coverOnly && !contain ? "thumb" : "card"`, `imgSrc = imgFellBack ? state.url : (pickVariant(state,role)?.url ?? state.url)`; `onError` mirror V123 (resign 1 lần → `imgFellBack` chỉ khi `!picked?.isOriginalFallback`). Video/audio branch KHÔNG đụng. `FamilyMemoryStream/Room/Period` KHÔNG mở (đều reuse `MediaTile`/`MemoryItem`/`CardDetail`).

### File 2 — `src/components/portal/DriveExplorer.tsx` (School Drive)
- `type DriveSigned = { url; thumb?; stage? }`; `urls` → `Record<string, DriveSigned>`; thêm `origFallback` set.
- `load()` capture `variants.{thumb,stage}` từ CÙNG `get_signed_media_url` response (KHÔNG thêm invocation). Grid tile → `sig.thumb ?? sig.url` + one-shot original `onError`; preview `<img>` → `sig.stage ?? sig.url` + one-shot fallback; preview `<video>` giữ `sig.url`. Inline local signer owner GIỮ NGUYÊN (KHÔNG migrate hook — deferred).

### Role matrix (LOCKED, bất biến)
`School tile → thumb · School preview → stage · Family cover → card · Family glimpse → thumb · Family detail → card`. `fullscreen` KHÔNG dùng; KHÔNG srcset/custom width-quality.

**Backend/DB/routes/tooling:** 0 delta. Không migration, không Edge, không signer, không Bunny, không upload, không video/audio, không route, không dependency (2.8.5 giữ nguyên sau revert).

## E. OWNER GATE — PRODUCTION EVIDENCE (ChatGPT Release Authority PASS)

| Surface | Role | Production evidence (Network, redacted URL) |
|---|---|---|
| School Drive grid tile | `thumb` | filter `width=256` → 13 WebP 200 · **9.5–21.2 KB** (original 0.03–2.98 MB · giảm >90%) · video tile riêng · 0 original |
| School Drive preview | `stage` | `03-Parent.png` (0.60 MB) filter `width=1280` → **1** WebP 200 · **35.5 KB** · 1 request/open · no original preload |
| Family / card | `card` | filter `width=768` → WebP 200 · **11.7 KB** |
| Family / thumb | `thumb` | filter `width=256` → 7 WebP 200 · **3.0–11.1 KB** |

**Ceilings:** thumb ≤150 · card ≤400 · stage ≤650 KB — tất cả PASS. **Δ signer calls = 0** (chọn role KHÔNG gọi lại signer). **Security:** School same-school + Family membership/consent fail-closed tại signer (BẤT BIẾN; không mutate consent để test). **0 original request trên normal success path.**

## F. RE-PIN (final, read-only — PASS)

- HEAD `06975654` → **`5c5491e9`**; 3 `ai_update` (`a3adc133` Family · `44e51fa8` School · `5c5491e9` tooling revert).
- Family: tsc 0 + agent verbatim `line_replace` trace + import verified. School: full `read_file`@`44e51fa8` — 6 khối byte-exact, **zero collateral** (list view / video branch / dialogs byte-nguyên).
- Tooling: package.json @tip = `2.8.5`; bun.lock @tip L66 `2.8.5` + L242 resolved `2.8.5`; **`2.9.1` count = 0** toàn lockfile (grep-proven); manifest↔lockfile consistent → Cloudflare frozen-install deterministic 2.8.5.
- signer live = deploy-25 v24 (BẤT BIẾN); DB inventory `89/215/204/166/33/1`, 16 Edge, migration tail `20260807130914`.

## G. RESIDUAL DEBT (record-only — KHÔNG fix ở M1)

- **P2 — School Drive eager-sign + no-lazy architecture** (Candidate 2): `DriveExplorer.load()` vẫn ký + tải mọi file khi mở folder; V124 chỉ đổi bytes/tile (thumb thay original), KHÔNG giảm signer count. Deferred milestone (hook consolidation / lazy-sign) — §6 chỉ cấm TĂNG, không bắt giảm.
- **P2 — tooling-governance (D342.5, nay FOUR-times-proven)**: agent non-frozen init float 2.8.5→2.9.1 mỗi run. **Mạnh mẽ khuyến nghị maintenance milestone RIÊNG**: hard-pin + bỏ khỏi `minimumReleaseAgeExcludes`. Paste-mode sidestep hoàn toàn.
- **P3 — Family fullscreen surface không tồn tại** → `fullscreen` role chưa dùng (không tạo surface mới chỉ để dùng nó).
- **P3 — srcset/DPR** chưa mở (fixed role đủ; thêm nếu có measured need).
- **Inherited** — animated image không transform (whitelist jpeg/png/webp); video/audio delivery (parent `.mov`, curriculum stream); consent-negative-fixture (deny-live source-proven).

## H. NEXT (câu hỏi sản phẩm, KHÔNG milestone)

Toàn bộ still-image `dma-private` (Parent + School Drive + Family) giờ right-sized. Mở cho phiên sau: (1) **tooling-governance maintenance milestone** (chấm dứt re-float tax — ưu tiên); (2) School Drive eager-sign/lazy + hook consolidation (Candidate 2, cần production evidence chứng minh đáng làm); (3) video/audio delivery optimization (Bunny Stream tiers / parent `.mov`); (4) animated-image handling nếu có corpus. *(Kid Portal V2, /admin interior — chưa xếp.)*

---

**Trạng thái:** `FINAL PASS — DMA V124-M1 CLOSED & CANONICALIZED`. RULES D342 · SYSTEM_MAP v1.30 · HANDOFF V124-M1 · HEAD `5c5491e9` · signer deploy-25 (v24, BẤT BIẾN) · tooling 2.8.5 · Bunny Optimizer ON (`dma-private`).
