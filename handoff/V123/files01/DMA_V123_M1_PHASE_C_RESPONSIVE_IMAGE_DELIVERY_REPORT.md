# DMA V123-M1 · PHASE C — BOUNDED BUILD REPORT · RESPONSIVE PRIVATE IMAGE DELIVERY

**Architecture (LOCKED, Phase-B accepted):** delivery-time Bunny image transformation through the existing `get_signed_media_url` authority.
**Turn output:** source implementation + local signing proof + static scope. **No production mutation performed.**
**Evidence date:** 2026-08-08 (Asia/Saigon).
**Deliverables:** `get_signed_media_url_v24_index.ts` · `useJourneySigning.ts` · `frontend_edits.md` (C1 applied-ready, C2/C3 staged) · `sign_proof.mjs`.

---

## A. RE-PIN (before build)

| Item | Expected | Live | Drift |
|---|---|---|---|
| Frontend HEAD | `2d33018b` | **`2d33018bd8c84e3ef126c9f93dceefe8f9a245c9`** (`get_project.latest_commit_sha`; `list_edits` top = same, 2026-08-07T16:06Z) | **none** |
| Overlapping writer | — | No commit after baseline; no edit in signed-media / Journey / Home since 2d33018b | **none** |
| Latest migration | `20260807130914 v122_m1_child_journal_session_id` | identical (Phase-A `list_migrations`, no writer since) | **none** |
| DB inventory | 89t/215fn/204SD/166pol/33trig/1cron/16edge | identical (Phase-A live count) | **none** |
| `get_signed_media_url` | v23 signer | v23 re-read; matches Phase-A capture | **none** |
| `useJourneySigning` | V92B.1 hook | re-read; unchanged | **none** |
| Components to modify | rail/stage/fullscreen/home | identified exact paths (see §G) | — |

No drift intersects signer / authz / consent / media rendering. **Proceed.**

---

## B. BUNNY OPTIMIZER STATE — **BLOCKED (not activatable in this environment)**

- **Inspect:** not possible — no Bunny control-plane access (no Bunny API/MCP/dashboard, no keys) in this session. Optimizer on/off on the `dma-private` Pull Zone **cannot be read here.**
- **Enable:** not possible — no authorized Bunny control-plane mutation capability in this session.
- **Ruling per §1:** bounded source implementation continued (safe, additive, backward-compatible). **PRODUCTION ACTIVATION IS BLOCKED.** Optimizer is **not** asserted active.

**Owner dashboard action required before activation (exact):**
1. Bunny dashboard → **Pull Zones → `dma-private` → Optimizer → enable Bunny Optimizer (Image Processing).**
2. Enable Bunny's normal compatible **WebP** auto-optimization if offered; **do not force AVIF.**
3. Confirm **Token Authentication remains enabled** and that the zone validates the standard `token`+`expires` **plus** additional query parameters (query-parameter token method) — so co-signed `width`/`quality` are honored, not stripped.
4. Change **no other** Bunny setting.
5. Capture before/after config screenshots (no keys) for the Owner-Gate evidence pack.

Until this is done and confirmed, the deployed signer will still mint `variants`, but the CDN will serve **originals** for those URLs (token validates because params are co-signed; Optimizer simply not applied) — safe, no user-visible breakage, **no byte reduction yet.**

---

## C. EXACT IMPLEMENTATION DELTA (files + config only)

**Applied-now scope (foundation + C1):**
| File | Change |
|---|---|
| `supabase/functions/get_signed_media_url/index.ts` → **v24** | additive: `+ file_type` in media select; original signing refactored to `signBunny(...,null)` (byte-identical); `+ variants{thumb,card,stage,fullscreen}` for dma-private images; `+ IMAGE_VARIANTS`/`IMAGE_VARIANT_TYPES`/`signBunny`; audit metadata records variant roles. |
| `src/features/journey/useJourneySigning.ts` | additive: `SignState.ok.variants?`; store `data.variants`; `+ export pickVariant()` (variant→original fallback); `+ VariantRole`/`MediaVariants` types. |
| `src/features/journey/JourneyRail.tsx` (**C1**) | 2 hunks: import `pickVariant`; `MemoryObject` cover URL → `pickVariant(st,"thumb")`. No geometry/lazy change. |

**Staged scope (C2/C3 — apply only after C1 runtime QA passes):**
| File | Change |
|---|---|
| `src/features/journey/JourneyFullscreen.tsx` | `fullscreen` variant + one-shot original fallback. |
| `src/features/journey/JourneyStage.tsx` | still-image sites → `stage` variant + one-shot fallback; `<video>` untouched. |
| `src/routes/_authenticated/parent.index.tsx` | hero `mediaSrc` → `card`/`stage` variant. `ReservedMedia.tsx` unchanged. |

**Config:** Bunny Optimizer enablement on `dma-private` (Owner, §B). **No app config/env change in code.**

---

## D. SIGNER IMPLEMENTATION — canonicalization & signing

`signBunny(host, key, path, expires, params)`:
- `params === null` → **original** URL: `hashableBase = key + path + expires`; URL `?token=<t>&expires=<e>` — **byte-identical to v23** (proven §H).
- `params = {width, quality}` → **variant**: query params canonicalized per **Bunny Token Authentication query-parameter method** —
  - keys sorted **ascending** (`quality` before `width`), joined `k=v&k2=v2`, **excluding** `token`/`expires`, **not URL-encoded**;
  - `hashableBase = key + path + expires + "quality=<q>&width=<w>"`;
  - `token = b64url(SHA256_RAW(hashableBase))` (base64 → `+`→`-`, `/`→`_`, strip `=`);
  - URL: `https://<host><path>?token=<t>&quality=<q>&width=<w>&expires=<e>`.
- Bunny validates by recomputing from the URL's present params (sorted, excl. token/expires) → matches the co-signed token. Any change to `width`, `quality`, or `path`, or any injected param, changes the hash → **403**.
- **No client string ever enters the hash** — `width`/`quality` come only from the server-side `IMAGE_VARIANTS` constant. Request authority stays `{ media_id }`.
- Security key never leaves the Edge; TTL preserved (`expires` unchanged across original + variants of a given sign).

---

## E. VARIANT RESPONSE (backward compatible)

Success response (image, dma-private):
```json
{ "allowed": true, "is_stream": false,
  "signed_url": "https://media.demenart.com/<path>?token=…&expires=…",   // UNCHANGED contract
  "variants": {
    "thumb":      "…?token=…&quality=78&width=256&expires=…",
    "card":       "…?token=…&quality=80&width=768&expires=…",
    "stage":      "…?token=…&quality=82&width=1280&expires=…",
    "fullscreen": "…?token=…&quality=85&width=1920&expires=…"
  },
  "expires": 1786160000, "stream_only": false, "download_allowed": false, "watermark_required": false }
```
- `variants` is **omitted** for non-image / non-`dma-private` / stream media → legacy clients and untouched surfaces keep working on `signed_url`.
- Locked contract honored: exactly four variants; **width + quality only**; aspect preserved; **no** height/crop/aspect-crop/face-crop/sharpen/auto_optimize/AI/DPR/extra widths; AVIF not forced.

---

## F. SIGNING-COUNT PROOF (invariant preserved)

- **Before:** one Edge invocation per media_id (deduped, 8-min cached).
- **After:** **still one Edge invocation per media_id** — that single call returns the whole 4-variant bundle. No per-variant call, no per-srcset-candidate call, no per-role N+1.
- Hook preserved verbatim: in-flight `Set` dedupe keyed by `media_id`; 8-minute client cache (`TTL_MS`); `denied` fail-closed and never auto-retried; proactive re-sign > 8 min; `resign()` on error. `pickVariant()` is a pure selector over cached state — it triggers **zero** new requests.
- Fullscreen high tier is already in the same cached bundle → opening fullscreen = **0 extra request**; the `fullscreen` `<img>` only mounts when the dialog opens, so its bytes are fetched lazily on open.

---

## G. SURFACE WIRING (locked order: rail → stage/fullscreen → home)

- **C1 · Journey rail (applied-ready):** cover thumbnails use `thumb` (256/q78) via `pickVariant`. IntersectionObserver lazy-sign, `loading="lazy"`, and all geometry unchanged. Rail never chooses original under successful transform (original only if the Edge minted no variant). No redesign.
- **C2 · Stage + fullscreen (staged):** stage still-images use `stage` (1280/q82) with one-shot original fallback; fullscreen uses `fullscreen` (1920/q85), lazy on open, never original as normal path. `<video>` untouched.
- **C3 · Parent Home (staged):** Daily-Focus/Memory hero uses `card`/`stage`; `loading="lazy"` preserved; `ReservedMedia` unchanged. **School Drive + Family = out of scope, untouched.**

---

## H. STATIC / SECURITY TESTS

**Local signing proof (`sign_proof.mjs`, Node crypto — dummy key; algorithm self-consistency + tamper-sensitivity, not live acceptance):**

| Test | Result |
|---|---|
| Proposed original token **===** current v23 token (backward compat) | **PASS — identical** |
| Variant tokens mint with alpha-sorted `quality=…&width=…` in hash | PASS |
| Width tamper (1280→4096) recompute ≠ issued | **REJECT ✓** |
| Quality tamper (82→100) recompute ≠ issued | **REJECT ✓** |
| Path swap recompute ≠ issued | **REJECT ✓** |
| Injected `&crop=1,1` recompute ≠ issued | **REJECT ✓** |
| Client cannot request arbitrary param | Guaranteed — params are server constants; request is `{ media_id }` only |

**Static scope:**
- Only the 3 applied files + 3 staged files listed in §C. No unrelated routes/components.
- **No** DB column / migration / RLS / trigger / enum change. **No** new Edge Function (existing signer modified — allowed by §7). **No** upload-pipeline / video / audio change. **No** width/height backfill, **no** derivative table.
- **No** package upgrade; **no** `bun.lock` change; **`@lovable.dev/vite-tanstack-config` not re-floated** (edits are paste-mode; no Lovable non-frozen install is run — this is the exact mechanism that avoids the V122 re-float hazard).
- No secret/key printed anywhere; signed URLs redacted in evidence.

**Live acceptance (Bunny actually honoring the token+params) is NOT proven** — requires the live zone + Optimizer (blocked). This is the single deferred security check for the Owner Gate.

---

## I. BUILD / RUNTIME CHECKS

- **Static:** passes as above (scope, tooling, DB-null-delta, signing self-consistency).
- **Type/lint:** hook + rail edits are additive and type-safe by construction (`variants?` optional; `pickVariant` returns `null` while not-ok, matching existing null-guards). Full `tsc`/build not run in this environment (frontend builds on Cloudflare from GitHub; Edge deploys via Supabase) — to be confirmed at apply time.
- **Runtime QA (C1 "rail passes" gate): BLOCKED** — needs Optimizer live + an authenticated parent session on `demenart.com`. Cannot be executed here. **C2/C3 remain staged behind this gate per §5.**

---

## J. PERFORMANCE PRE-EVIDENCE

No live transformed bytes measurable (Optimizer blocked; no authenticated session). Projection from Phase-A DB byte reality against the locked widths (INFERRED, to be confirmed at Owner Gate against §9 gates):

| Role | Width/q | Today (original) | Expected transformed | Target / hard gate |
|---|---|---|---|---|
| thumb (rail 66px) | 256/78 | 2–7 MB | ~15–40 KB | ≤80 KB / ≤150 KB |
| card (home hero) | 768/80 | 1.2–2.7 MB | ~60–150 KB | ≤250 KB / ≤400 KB |
| stage | 1280/82 | 1.2–2.7 MB | ~150–350 KB | ≤400 KB / ≤650 KB |
| fullscreen | 1920/85 | 2–7 MB | ~350–800 KB | ≤700 KB / ≤1.0 MB |

Expected rail median reduction **≥95%**, sample median **≥85%** — meets §9 (≥90% rail, ≥80% sample). **Not asserted as measured.** Per §9, if any live sample exceeds a **hard gate**, I will report the exact object and **STOP for Product review** rather than add a 5th variant or lower quality ad hoc.

---

## K. ACTUAL FINAL HEAD

**No new commit was created this turn.** Baseline HEAD remains `2d33018bd8c84e3ef126c9f93dceefe8f9a245c9`. Rationale: (1) production activation is BLOCKED on Optimizer (§B); (2) the crown-jewel signer must not be blind-deployed without live CDN verification; (3) driving the frontend through the Lovable AI agent risks the documented `@lovable.dev/vite-tanstack-config` re-float (violates §8) — DMA paste-mode avoids it. Implementation is delivered as **paste-ready artifacts**; the new HEAD/Edge version will be produced by the Owner-applied paste + Supabase Edge deploy at the Owner Gate.

---

## L. EXPLICIT SCOPE CONFIRMATION

This build introduces: **no** DB column · **no** migration · **no** width/height backfill · **no** derivative table · **no** upload-pipeline change · **no** new Edge Function (existing signer modified only) · **no** image preprocessing at upload · **no** video/audio change · **no** School Drive or Family UI change · **no** package upgrade · **no** `bun.lock` change · **no** tooling re-float · **no** route/tree change. Client request authority stays `{ media_id }`.

---

## STOP — PHASE C SOURCE COMPLETE · PRODUCTION ACTIVATION BLOCKED

**Owner Gate — required to activate (in order):**
1. **Enable Bunny Optimizer on `dma-private`** + confirm token query-param mode (§B). *(Owner — I cannot.)*
2. **Deploy signer v24** (`get_signed_media_url_v24_index.ts`) via Supabase. *(Owner paste from dashboard, per DMA Edge workflow — or authorize me to deploy it via the Supabase Edge tool.)*
3. **Apply hook + C1 rail edits** (`useJourneySigning.ts` full file + `JourneyRail.tsx` 2 hunks). *(Owner paste — or tell me how you want the frontend applied.)*
4. **Run C1 runtime QA** (rail thumbnails transformed, byte reduction, no original under success). Only after C1 passes → apply **C2** then **C3**.
5. **Owner-Gate performance sampling** against §9 gates.

**Tell me which of steps 2–3 you want me to execute directly** (I can deploy the Edge via the Supabase tool and, if you accept the re-float risk mitigations, drive the frontend) **vs. apply yourself in paste-mode.** I will not mutate production or canonicalize without your go.

**Do not canonicalize V123.**
