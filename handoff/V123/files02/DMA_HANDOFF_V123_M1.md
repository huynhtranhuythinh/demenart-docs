# 🖼️ DMA_HANDOFF_V123_M1.md — RESPONSIVE PRIVATE IMAGE DELIVERY · M1

> **Sprint closeout** — Delivery-time Bunny image transformation through the existing `get_signed_media_url` authority. Parent surfaces (Journey rail/stage/fullscreen + Home Memory) now receive right-sized WebP variants instead of 2–7 MB originals. Signer-only backend change; frontend variant wiring; **zero DB/migration/upload/video/audio delta.**
> **Đọc boot:** `DMA_RULES.md` → `DMA_SYSTEM_MAP.md` → **file này** (mới nhất), rồi re-pin live DB inventory + `list_edits` + deployed signer version trước khi làm.

---

## A. VERDICT

**`FINAL PASS — DMA V123-M1 CLOSED & CANONICALIZED`.** ChatGPT Release Authority = **OWNER GATE PASS**. Bunny Optimizer VERIFIED ENABLED on `dma-private` (WebP + Dynamic Image API). Signer v24 deployed (Supabase Edge deploy-version **25**) proves one authorized `{media_id}` invocation returns backward-compatible `signed_url` + `variants{thumb,card,stage,fullscreen}` with no per-variant call; transform-tamper is fail-closed (403). All four Parent roles measured under locked byte budgets in production. Canonicalized (RULES **D341** · SYSTEM_MAP **v1.29**).

## B. ENDPOINT

- **RULES:** D341 · **SYSTEM_MAP:** v1.29 · **HANDOFF:** V123-M1
- **Frontend HEAD (accepted tip):** `069756542740fd924b492d41043ac3bb7579c842` (`06975654`) — 5 `manual_update` commits since `2d33018b` via Lovable Code Editor (no ai_update → no tooling re-float path触发)
- **Signer:** `get_signed_media_url` **deploy-version 25** = accepted **v24** source (byte-verified live via `get_edge_function`)
- **Bunny:** `dma-private` Optimizer ENABLED · WebP compression ON · Dynamic Image API ON
- **Registry:** 119 (bất biến) · **Route:** 52 convention (bất biến)
- **DB inventory (re-verified live):** 89 tables · 215 functions · 204 SECURITY DEFINER · 166 policies · 33 triggers · 1 cron · 16 Edge · migration mới nhất **`20260807130914 v122_m1_child_journal_session_id`** (KHÔNG thêm migration ở V123-M1)
- **Tooling:** Bun sole PM authority · `bun.lock` sole lockfile · `@lovable.dev/vite-tanstack-config` exact **2.8.5** (không xuất hiện trong diff → bất biến)

## C. PRODUCT OUTCOME (cái gì đổi cho người dùng)

Ảnh riêng tư của con giờ tải **nhẹ và nhanh** trên mọi surface Phụ huynh, giữ nguyên UX/bố cục:

1. **Journey rail** — thumbnail 66px giờ dùng variant `thumb` **256px/q78 WebP** (~4–24 KB) thay vì bản gốc 2–7 MB → **giảm >90%** byte, cuộn kệ kỷ vật mượt.
2. **Journey stage** — ảnh buổi/khoảnh khắc dùng `stage` **1280px/q82 WebP** (~12–206 KB).
3. **Journey fullscreen** — chỉ khi mở mới tải `fullscreen` **1920px/q85 WebP** (~13.6 KB mẫu), lazy-on-open, **0 request thừa** (cùng bundle đã ký).
4. **Parent Home (Ký ức)** — hero Daily-Focus/Memory dùng `card` **768px/q80 WebP** (~11.7 KB).
5. **Backward-compatible** — `signed_url` gốc giữ nguyên byte-for-byte; là đường fallback tương thích/lỗi, KHÔNG phải đường render thường.

## D. TECHNICAL SCOPE

### Signer (D341.1 — additive, security-critical)
`get_signed_media_url` **v24** (deploy 25): `+ file_type` vào media select; original signing refactor sang `signBunny(...,null)` (**byte-identical v23**, chứng minh local); `+ variants{thumb,card,stage,fullscreen}` CHỈ cho `dma-private` still-image (jpeg/png/webp); `+ IMAGE_VARIANTS`/`IMAGE_VARIANT_TYPES`/`signBunny`. Transform params là **SERVER CONSTANT** (locked table) — không chuỗi client nào vào hash. Bunny Token-Auth query-param canonicalization: `hashableBase = key + path + expires + sortedParams` (ascending; loại token/expires; không url-encode) → co-sign width+quality. Client authority vẫn `{media_id}`. Audit log ghi tên role variant.

### Frontend (D341.2 — variant wiring, 5 files)
- `src/features/journey/useJourneySigning.ts` — `SignState.ok.variants?`; lưu `data.variants`; `+ export pickVariant()` (variant→original fallback); type `VariantRole`/`MediaVariants`. Dedupe/8-min cache/denied-fail-closed/expiry-resign **bất biến**; 1 invocation/media trả cả bundle (0 per-variant call).
- `src/features/journey/JourneyRail.tsx` (**C1**) — cover dùng `pickVariant(st,"thumb")`. IntersectionObserver lazy-sign + geometry bất biến.
- `src/features/journey/JourneyStage.tsx` (**C2B**) — still-image sites dùng `stage` + one-shot original fallback; `<video>` KHÔNG đụng.
- `src/features/journey/JourneyFullscreen.tsx` (**C2A**) — `fullscreen` tier + fallback; lazy-on-open.
- `src/routes/_authenticated/parent.index.tsx` (**C3**) — hero `mediaSrc` dùng `card`.

**Backend khác/DB/routes:** 0 delta. Không migration, không Edge mới, không upload-pipeline, không backfill width/height, không đụng School Drive/Family/video/audio/tooling/lockfile/route tree.

## E. OWNER GATE — PRODUCTION EVIDENCE (ChatGPT Release Authority PASS)

| Role | Variant | Production evidence |
|---|---|---|
| Rail | 256/q78 | WebP · **~4–24 KB** (target ≤80 · gate ≤150) · no mass 38/38 pre-sign · lazy+dedup preserved |
| Stage | 1280/q82 | WebP · **~12.6 / 27.2 / 35.5 KB … up to ~206 KB** (target ≤400 · gate ≤650) · video/audio untouched |
| Fullscreen | 1920/q85 | WebP · **~13.6 KB** · no `width=1920` before open · 1 request on open · no original preload |
| Parent Home | 768/q80 | WebP · **~11.7 KB** · Home renders correctly |

**Security PASS:** authz/consent server-side before URLs minted · client authority `{media_id}` · no arbitrary client width/quality · transform mutation → 403 · expired/stale → fail-closed, fresh sign restores · no unsigned storage origin · no secret exposed. **Signing-count invariant:** one media_id invocation → whole bundle; no per-variant Edge call. **Rail median reduction materially >90%** vs 2–7 MB originals.

## F. RE-PIN (final, read-only — PASS)

- HEAD `2d33018b` → **`06975654`**; 5 `manual_update` commits (`ab77cbf` `cb406058` `f534347f` `d3d08bc2` `06975654`); no ai_update; no unrelated writer.
- Diff = exactly **5 frontend files** (Fullscreen/Rail/Stage/useJourneySigning/parent.index) + signer deployed separately. `get_diff` scan: **0** occurrences of `width=`/`height=`/`crop`/`aspect_ratio`/`sharpen`/`auto_optimize`/`srcset`/`<video`/`avif` in added lines; only `pickVariant` + locked roles.
- No `package.json`/`bun.lock`/`vite-tanstack-config`/`routeTree`/tailwind/tsconfig/Drive/Family/upload touched.
- DB inventory identical **89/215/204/166/33/1**, 16 Edge, migration tail `20260807130914`. Signer live source = accepted v24 (byte-verified).

## G. RESIDUAL DEBT (record-only — KHÔNG fix ở M1)

- **P2 — School Drive + Family surface image optimization**: signer already mints variants for all `dma-private` images, but Drive/Family renderers are **not yet wired** (out of V123-M1 scope). Future milestone: wire `thumb`/`card`/`stage` on DriveExplorer + family card/stream.
- **P3 — Animated images**: not transformed in M1 (whitelist jpeg/png/webp only); gif/animated retain original delivery. Revisit if animated content appears.
- **P3 — Bounded `srcset`/DPR precision**: current wiring uses one variant per role (no `srcset`); intrinsic width/height still ABSENT (no backfill). Add `srcset` only if measured need.
- **Inherited** — CONSENT-NEGATIVE-FIXTURE (deny-live still source-proven only); optional Daily-Focus→journal CTA; P2 tooling-governance (three-times-proven, re-float maintenance milestone).
- **Non-image originals** — parent `.mov` 11–15 MB, curriculum 246 MB stream video, 9 MB mp3 — video/audio pipeline, out of scope.

## H. NEXT (câu hỏi sản phẩm, KHÔNG milestone)

Parent image delivery giờ right-sized. Mở cho phiên sau: (1) **School Drive + Family image optimization** (wire existing variants — smallest next win, signer already ready); (2) tooling-governance maintenance milestone (chấm dứt re-float); (3) video/audio delivery optimization (Bunny Stream tiers / parent `.mov`); (4) inherited Journey debts (restore-entry-point, consent-negative fixture). *(Kid Portal V2, /admin interior — chưa xếp.)*

---

**Trạng thái:** `FINAL PASS — DMA V123-M1 CLOSED & CANONICALIZED`. RULES D341 · SYSTEM_MAP v1.29 · HANDOFF V123-M1 · HEAD `06975654` · signer deploy-25 (v24) · Bunny Optimizer ON (`dma-private`).
