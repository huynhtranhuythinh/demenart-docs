# V123-M1 · Frontend edits (paste-ready)

Foundation (`useJourneySigning.ts`) is delivered as a full file. Renderer edits below are
minimal hunks. **Apply order is LOCKED:** signer + hook + C1 first; C2/C3 only after C1 passes
runtime QA (see report §I — runtime QA is currently BLOCKED on Bunny Optimizer).

---

## C1 — `src/features/journey/JourneyRail.tsx`  (APPLY NOW after signer+hook)

**Hunk 1 — import (value + type):**
```diff
-import type { JourneySigning } from "@/features/journey/useJourneySigning";
+import { pickVariant, type JourneySigning } from "@/features/journey/useJourneySigning";
```

**Hunk 2 — `MemoryObject` cover URL (the ONLY logic change; geometry/lazy-sign untouched):**
```diff
 function MemoryObject({ ev, signing, kind, cover }: {...}) {
-  const st = signing.getState(cover);
-  const url = st.status === "ok" ? st.url : null;
+  const st = signing.getState(cover);
+  // V123-M1 · C1 — rail cover uses the 256/q78 `thumb` variant; falls back to the
+  // original ONLY when the Edge did not mint variants (Optimizer off / non-image).
+  const url = pickVariant(st, "thumb")?.url ?? null;
```
No change to IntersectionObserver lazy-sign, `loading="lazy"`, ITEM_W/BOX/LANE geometry, or object shapes.

---

## C2 — `src/features/journey/JourneyFullscreen.tsx`  (STAGED — after C1 QA)

**Hunk 1 — import:**
```diff
-import type { JourneySigning } from "@/features/journey/useJourneySigning";
+import { pickVariant, type JourneySigning } from "@/features/journey/useJourneySigning";
```

**Hunk 2 — variant selection + one-shot original fallback (place after `const st = signing.getState(mediaId);`):**
```tsx
  const st = signing.getState(mediaId);
  const [retried, setRetried] = useState(false);
  const [fellBack, setFellBack] = useState(false);
  useEffect(() => { setRetried(false); setFellBack(false); }, [mediaId]);
  const picked = pickVariant(st, "fullscreen"); // 1920/q85 high tier
  const imgSrc = fellBack
    ? (st.status === "ok" ? st.url : null)      // §6: fall back ONCE to already-authorized original
    : (picked?.url ?? null);
```

**Hunk 3 — the `<img>` (uses `fullscreen` variant, lazy: only mounts when dialog open):**
```diff
-          {st.status === "ok" ? (
-            <img src={st.url} alt={title} className="max-h-full max-w-full object-contain" />
-          ) : st.status === "denied" || st.status === "error" ? (
+          {st.status === "ok" && imgSrc ? (
+            <img
+              src={imgSrc}
+              alt={title}
+              className="max-h-full max-w-full object-contain"
+              onError={() => {
+                if (!retried) { setRetried(true); signing.resign(mediaId); }        // fresh transformed re-sign
+                else if (!fellBack && !picked?.isOriginalFallback) setFellBack(true); // then original ONCE
+              }}
+            />
+          ) : st.status === "denied" || st.status === "error" ? (
```
Denied media never falls back (denied → error branch, not the `<img>`). Fullscreen never uses original as the normal path; only after a fresh-transformed retry fails.

---

## C2 — `src/features/journey/JourneyStage.tsx`  (STAGED — after C1 QA)

Add `pickVariant` to the existing `useJourneySigning` import. For each **still-image** `<img src={st.url}>`
site (creation image, `MomentMedia`, parent-memory polaroid — NOT the `<video>` site) apply the same
pattern, using the **`stage`** role (1280/q82):

```tsx
// once per image component:
const [fellBack, setFellBack] = useState(false);
useEffect(() => { setFellBack(false); }, [/* currentMediaId | mediaId */]);
const picked = pickVariant(st, "stage");
const imgSrc = fellBack ? (st.status === "ok" ? st.url : null) : (picked?.url ?? null);
// <img src={imgSrc} ... onError append:
//   else if (!fellBack && !picked?.isOriginalFallback) setFellBack(true);
```
Keep every existing `onError` `resign()` retry; only ADD the second-failure `setFellBack(true)`.
Do NOT introduce any width other than `stage` (a bounded `srcset="{card} 768w, {stage} 1280w"` +
`sizes` is permitted if the component's real CSS width justifies it — both are locked widths).
The `<video>` site is unchanged (video is not transformed in M1).

Image sites (from source, HEAD 2d33018b) for reference: creation image (~L116), `MomentMedia` (~L248),
parent-memory polaroid (~L1081). `<video>` (~L949) — leave as-is.

---

## C3 — Parent Home  (STAGED — after C1/C2 QA)

`ReservedMedia.tsx` needs **no change** (it already renders `<img loading="lazy">` from `src`).
In `src/routes/_authenticated/parent.index.tsx`, where the hero's `mediaSrc`/`mediaStatus` is
computed from the signing state, pass the **`card`** (or `stage` on wide layouts) variant instead of
the original:

```tsx
// where mediaSrc is derived from the signed state for the hero media_id:
const picked = pickVariant(signing.getState(heroMediaId), "card");
const mediaSrc = picked?.url ?? null;        // fallback to original handled inside pickVariant
```
Preserve existing lazy/eager semantics (`loading="lazy"` stays). A bounded `srcset="{card} 768w,
{stage} 1280w"` may be added on `ReservedMedia` if warranted by hero width. No Home redesign.
School Drive and Family UI are OUT OF SCOPE — do not touch.
