# F2 — DESIGN TOKEN SPEC
**V113F** · Implementation-ready semantic tokens derived from the L2 master ("Hành trình của An") and L3 matching surfaces. Planning only — no CSS is applied here.

**Reading rules**
- Token **names** are canonical and take precedence over raw color names. Build against the semantic token, not the hex.
- Hex/px values are **extracted estimates** from compressed mockups. Any value that cannot be pixel-confirmed is marked `⚠ CONFIRM` (= `REQUIRES ART-DIRECTOR CONFIRMATION`). Confirm against the source design file / official logo swatches before freeze.
- Do **not** invent an unrelated palette. Every value below traces to L1–L3. Rejected inputs (Image 6 orange/yellow) contributed **nothing**.

---

## 1. Brand & surface colors

| Token | Role | Estimate | Confidence |
|---|---|---|---|
| `--color-emerald-identity` | Deep forest green — rail, identity headers, dark surfaces | `#103D2C` | ⚠ CONFIRM (hue high, value estimate) |
| `--color-emerald-primary` | Primary action green (buttons, active nav) | `#1A5138` | ⚠ CONFIRM |
| `--color-emerald-primary-hover` | Primary hover | `#164A32` | ⚠ CONFIRM |
| `--color-surface-ivory` | Default reading surface (page background) | `#F6F1E4` | ⚠ CONFIRM |
| `--color-surface-ivory-raised` | Cards on ivory (slightly lifted) | `#FBF8F0` | ⚠ CONFIRM |
| `--color-surface-emerald-raised` | Cards on emerald (slightly lifted) | `#17472F` | ⚠ CONFIRM |
| `--color-accent-champagne` | Antique gold / champagne accent (pills, small metrics, botanical) | `#C4A662` | ⚠ CONFIRM |
| `--color-accent-champagne-soft` | Muted gold for fine borders/underlays | `#D8C48F` | ⚠ CONFIRM |
| `--color-sage-secondary` | Muted sage — secondary support, quiet chips | `#93A98F` | ⚠ CONFIRM |
| `--color-sage-tint` | Sage wash for quiet zones | `#E7EAE0` | ⚠ CONFIRM |

**Guardrail:** `--color-emerald-*` must **not** be sampled from the bright logo green (F1 §3). Prohibited: any teal, mint, neon green, SaaS blue, or orange/amber as a *brand/surface* token.

## 2. Text (ink) colors

| Token | Role | Estimate | Confidence |
|---|---|---|---|
| `--color-ink-primary` | Primary text on ivory (dark green ink) | `#1D3A2E` | ⚠ CONFIRM |
| `--color-ink-secondary` | Secondary text / supporting copy | `#3E5348` | ⚠ CONFIRM |
| `--color-ink-metadata` | Metadata / timestamps (warm neutral gray) | `#8C8676` | ⚠ CONFIRM |
| `--color-ink-on-emerald` | Text on emerald surfaces (ivory) | `#F4EFE2` | ⚠ CONFIRM |
| `--color-ink-on-emerald-muted` | Muted text on emerald (nav inactive) | `#A9C0B0` | ⚠ CONFIRM |
| `--color-ink-gold` | Gold emphasis text (metrics, provenance) | `#B79149` | ⚠ CONFIRM |

## 3. Borders

| Token | Role | Estimate |
|---|---|---|
| `--border-hairline` | Default fine border on ivory | `1px solid rgba(29,58,46,0.10)` ⚠ CONFIRM |
| `--border-gold-hairline` | Warm accent divider | `1px solid rgba(196,166,98,0.35)` ⚠ CONFIRM |
| `--border-on-emerald` | Divider on emerald | `1px solid rgba(244,239,226,0.12)` ⚠ CONFIRM |
| `--border-focus` | Focus ring color | `--color-accent-champagne` @ 2px (see §12) |

## 4. Semantic status colors

| Token | Role | Estimate | Confidence |
|---|---|---|---|
| `--color-success` | Confirmed/positive (e.g. "Đã lưu vào Hành trình" check) | `#2F7A54` | ⚠ CONFIRM |
| `--color-warning` | Waiting/attention (e.g. consent waiting) | `#C4A662` (champagne, reused) | ⚠ CONFIRM |
| `--color-error` | Error state (system error block) | `#B24A3E` | ⚠ CONFIRM |
| `--color-denied` | Denied/blocked (distinct from error) | `#8C6D3F` (muted amber-brown, non-alarming) | ⚠ CONFIRM |
| `--color-destructive` | Destructive actions only ("Xóa", "Gỡ") | `#B24A3E` | ⚠ CONFIRM |
| `--color-destructive-bg` | Destructive control background wash | `rgba(178,74,62,0.08)` | ⚠ CONFIRM |

**Rule:** `--color-destructive` is used **only** for irreversible/destructive controls. Never for primary CTAs, never decoratively. `--color-error` and `--color-denied` must be visually distinguishable so error ≠ denied ≠ empty (D298/D305).

## 5. Typography families

| Token | Role | Value | Confidence |
|---|---|---|---|
| `--font-serif` | Page titles, chapter titles, memory titles | High-contrast editorial serif — candidate: **Playfair Display** (has full Vietnamese diacritics) | ⚠ CONFIRM exact family; **must** ship Vietnamese coverage |
| `--font-sans` | Nav, body, metadata, controls, forms | Humanist sans with strong Vietnamese support — candidate: **Be Vietnam Pro** or **Inter** (VN) | ⚠ CONFIRM exact family |

**Rules:** exactly one serif + one sans across the whole product. No per-route font changes. No decorative/script font in product UI. Vietnamese diacritic rendering (ổ, ữ, ằ, ị…) must be verified in **both** families before freeze.

## 6. Type scale (fixed)

| Token | Use | Size / line-height | Family |
|---|---|---|---|
| `--type-display` | Page title ("Hôm nay của An", "Hành trình của An") | 40 / 48 (desktop) · 28 / 34 (mobile) | serif |
| `--type-h1` | Family/space name, chapter title | 32 / 40 · 24 / 30 | serif |
| `--type-h2` | Memory title, section title | 24 / 32 · 20 / 26 | serif |
| `--type-h3` | Card title / sub-section | 18 / 26 | sans (semibold) |
| `--type-body` | Story / body copy | 16 / 26 | sans |
| `--type-body-sm` | Secondary copy | 14 / 22 | sans |
| `--type-meta` | Metadata / timestamps | 13 / 18 | sans |
| `--type-label` | Nav labels, chips, buttons | 14 / 16 (medium) | sans |
| `--type-eyebrow` | Small caps pills ("CHƯƠNG MỚI BẮT ĐẦU") | 12 / 16, letter-spacing 0.08em | sans |

All exact px `⚠ CONFIRM` against source; ratios/roles are fixed.

## 7. Font weights

| Token | Value |
|---|---|
| `--weight-serif-regular` | 400 |
| `--weight-serif-medium` | 500 |
| `--weight-sans-regular` | 400 |
| `--weight-sans-medium` | 500 |
| `--weight-sans-semibold` | 600 |
| `--weight-sans-bold` | 700 (sparing — CTAs, active nav) |

## 8. Line-heights
Baked into §6. Global default body line-height `1.6`; headings `1.2–1.35`.

## 9. Spacing scale (4px base)

| Token | px |
|---|---|
| `--space-1` | 4 |
| `--space-2` | 8 |
| `--space-3` | 12 |
| `--space-4` | 16 |
| `--space-5` | 20 |
| `--space-6` | 24 |
| `--space-8` | 32 |
| `--space-10` | 40 |
| `--space-12` | 48 |
| `--space-16` | 64 |

**Density model:** one model across the product — generous (memory-first). Card inner padding `--space-6`; section gaps `--space-10`; period-to-period gap `--space-12`. No compact/dense per-route variant.

## 10. Radii

| Token | px | Use |
|---|---|---|
| `--radius-sm` | 8 | chips, small controls |
| `--radius-md` | 12 | buttons, inputs, small cards |
| `--radius-lg` | 16 | cards, media frames |
| `--radius-xl` | 20 | hero media, large panels |
| `--radius-pill` | 999 | primary CTA pills, nav pills, avatars |

One radius family; ⚠ CONFIRM exact corner sizes (16/20 hero) against source.

## 11. Shadows (restrained)

| Token | Value | Use |
|---|---|---|
| `--shadow-none` | none | default (fine borders do the work) |
| `--shadow-sm` | `0 1px 2px rgba(29,58,46,0.06)` ⚠ | raised cards on ivory |
| `--shadow-md` | `0 4px 16px rgba(29,58,46,0.08)` ⚠ | hero media, dialogs |
| `--shadow-emerald` | `0 6px 20px rgba(16,61,44,0.25)` ⚠ | floating elements over ivory near rail |

Shadows stay soft and rare; borders are the primary separation device.

## 12. Interactive states

| State | Treatment |
|---|---|
| Hover (primary) | `--color-emerald-primary-hover`, no scale |
| Hover (quiet/link) | ink darkens one step; gold underline for links |
| Active/pressed | −2% brightness, no motion overshoot |
| Focus-visible | 2px `--color-accent-champagne` ring, 2px offset, on both emerald and ivory (contrast-checked) |
| Disabled | 40% opacity, no pointer |
| Selected nav | ivory pill on emerald + gold left-marker (desktop rail) / gold underline + fill (mobile) |
| Selected child (ChildSwitcher) | gold ring on avatar + emerald raised chip |

## 13. Breakpoints

| Token | Range | Design width |
|---|---|---|
| `--bp-mobile` | ≤ 400px | 390px |
| `--bp-tablet` | 401–1023px | ~768px |
| `--bp-desktop` | ≥ 1024px | 1440px |

Mobile is **recomposed**, not scaled (see F5).

## 14. Z-index layers

| Token | z | Use |
|---|---|---|
| `--z-base` | 0 | content |
| `--z-rail` | 10 | desktop identity rail |
| `--z-sticky-header` | 20 | mobile header |
| `--z-bottom-nav` | 30 | mobile bottom nav (above content, respects safe-area) |
| `--z-sheet` | 40 | bottom sheets / archive nav sheet |
| `--z-dialog` | 50 | dialogs (invite, confirm) |
| `--z-toast` | 60 | toasts / quiet notices |

## 15. Motion

| Token | Value |
|---|---|
| `--motion-fast` | 120ms |
| `--motion-base` | 200ms |
| `--motion-slow` | 320ms |
| `--ease-standard` | `cubic-bezier(0.2, 0, 0, 1)` |
| `--ease-emphasized` | `cubic-bezier(0.2, 0, 0, 1)` (enter) / `cubic-bezier(0.3, 0, 1, 1)` (exit) |

Motion is quiet: fades and short slides only; no bounce/overshoot; no parallax on botanical elements.

## 16. Reduced motion

`@media (prefers-reduced-motion: reduce)`: disable all non-essential transitions and any botanical/decorative animation; replace slide/scale with instant or opacity-only; retain focus-visible; audio/video controls stay manual (no autoplay).

---

## 17. Token confidence summary

| Group | Structure frozen? | Values frozen? |
|---|---|---|
| Semantic names (all groups) | ✅ Yes | — |
| Type scale / weights / spacing / radii / z-index / motion structure | ✅ Yes | ✅ high (px/ratios) |
| Brand/surface/ink **hex values** | ✅ Yes | ⚠ **CONFIRM** — needs art-director swatches or source-file extraction |
| Font families (exact) | ✅ roles fixed | ⚠ **CONFIRM** family + Vietnamese coverage |

**Net:** the token *system* is complete and one-world; the **exact color hex values and the two font families require art-director confirmation** before the freeze can be declared final. This is the primary reason V113F is a *conditional* pass (see F7).
