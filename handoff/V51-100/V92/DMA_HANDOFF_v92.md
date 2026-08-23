# DMA_HANDOFF_v92.md — V92: Immersive Art Journey Viewer / Art Memory Player + Memory Objects

> **ĐÓNG 2026-07-11 GMT+7** (gồm **V92B.2 — Stable Memory Player**, pass ổn định UX sau deploy đầu).
> Endpoint: RULES **D224** (+D224-B) · SYSTEM_MAP **v0.85** · Handoff **v92**.
> **Baseline cố định:** An **6/2/6** · Inventory **63 tables · 107 definer · 155 policies · 1 cron**.
> **⭐ Sprint FRONTEND-ONLY:** 0 migration · 0 RPC · 0 Edge · 0 policy · 0 cron · 0 data.

---

## 1. Mục tiêu

Thêm **chế độ xem thứ 2** trên `/parent/journal` — **"Dải hành trình"** (PRIMARY/default) — bên cạnh timeline dọc V74–V83 — **"Nhật ký"** (secondary, **KHÔNG thay thế, byte-stable**).

Framing nội bộ: **Art Memory Player + Memory Objects**.
Câu lõi: *"Mỗi mốc là một kỷ vật trong phòng triển lãm của con."*

**Tiêu chí thành công (CTO, không phải kỹ thuật):**
> "Phụ huynh không còn thấy mình đang lướt thẻ media. Họ đang mở và đi qua những kỷ vật tuổi thơ nghệ thuật của con."
> → **ĐẠT** (CTO xác nhận trên ảnh thật, 2026-07-11).

**KHÔNG làm trong V92:** Kid adaptation · Art Discovery Capsule engine · AI storytelling · autoplay/slideshow · fullscreen TV · export/photobook · favorite/bookmark · filter chips.

---

## 2. C1 — Canonical + Live audit (zero-drift)

- Endpoint vào: RULES **D223** · SYSTEM_MAP **v0.84** · Handoff **v91** — khớp, **KHÔNG drift**.
- Inventory vào (live): **63 / 107 / 155 / 1** — khớp.
- **⚠️ Bẫy audit:** `full_name ILIKE '%An%'` bắt nhầm **"Trần Thanh Bình"** (chữ "Th**an**h"). Bé An thật = **`d1000000-0000-4000-8000-000000000041`** (Nguyễn Hoàng An) → drawings **6** · recordings **2** · moments **6** = **6/2/6** ✓. *(Luôn dùng UUID này khi test.)*
- **⭐ Phát hiện quyết định:** `get_child_journal` **đã trả đủ dữ liệu từ V79** (`galleryItems` / `coverMediaId` / `mediaCount` / `hasGallery`) ⇒ viewer mới chỉ là **tầng đọc thêm** ⇒ **0 migration**.
- `media_assets` của An: drawing `image/png` · recording **`audio/webm`** · moment `image/jpeg` — tất cả zone `dma-private`, **`expires_policy_minutes = 10`**.
- **Phát hiện Phase 0 (khác giả định brief):** chrome "large app card" nằm ở **`ParentJourneyViewer.tsx`** (`rounded-2xl border bg-[#FBF7EE]`), KHÔNG phải `JourneyStage.tsx` → CTO chấp nhận mở rộng scope sang file cha.

---

## 3. C2 — Kiến trúc (CTO-approved)

- **Option A:** model chuẩn hoá **chung** + renderer/signing **riêng** cho Parent & Kid (Kid có `kid_gate`, không dùng chung signing — D220).
- **Parent-first** (Kid để sprint sau).
- **Đảo ngôi (CTO FINAL):** "Dải hành trình" = **primary/default**; "Nhật ký" = secondary.
- Model thuần tách ra module trung tính, **viewer KHÔNG import model từ route file**.

---

## 4. Files

### 4.1 Mới — `src/features/journey/` (7 file)

| File | Vai trò |
|---|---|
| `parentJourneyModel.ts` | **Pure model**: 0 React state · 0 Supabase · 0 signing · 0 signed URL. Trích từ route: types, `buildParentTimeline` (DESC; **badge KHÔNG lên trục** — D205), `groupTimelineByMonth`, `hcmYmd`/formatters, `getMomentWarmLine`/`getMomentConversationPrompt`, `cleanCaption`, `MOMENT_GALLERY_HINT`. |
| `useJourneySigning.ts` | `ensureSigned` · `getState` · **`resign`**. Cache **TTL 8′** + **`inflight` Set dedup**. Edge `get_signed_media_url`, per-media. |
| `JourneyViewToggle.tsx` | `[Dải hành trình][Nhật ký]`. |
| `ParentJourneyViewer.tsx` | Orchestrator: items **ASC cũ→mới**; mặc định chọn **mốc mới nhất**; keyboard ←/→/Home/End (guard input); **hook signing sống ở đây** (không bị `key` remount). |
| `JourneyStage.tsx` | 5 kỷ vật + reveal theo loại + ambient + vignette. |
| `JourneyRail.tsx` | **Kệ kỷ vật** + chỉ vàng + chapter tháng + viewport lazy-sign. |
| *(REEL_SPIN_CSS trong JourneyStage)* | `@keyframes dmaReelSpin` + `@media (prefers-reduced-motion) → animation: none`. |

### 4.2 Edit — `src/routes/_authenticated/parent.journal.tsx`

Chỉ 4 việc: (1) đổi nguồn import sang model + **re-export shim** (importer cũ V79–V81 không gãy); (2) `viewMode` state + localStorage; (3) `<JourneyViewToggle/>` + title theo mode; (4) wrap ternary.
**Grid Nhật ký (Timeline + skills + badges) byte-stable.** `ParentJournalLightbox` / `CompactMomentLeaf` / `CompactCreationLeaf` / `ShareMomentButton` **ở lại route, không đụng**.

---

## 5. Memory Objects — mapping (CHỈ data thật)

| Loại | Stage | Rail |
|---|---|---|
| drawing | **Khung tranh treo tường** (khung gỗ + mat + đinh treo/dây; `object-contain`) | khung gỗ mini + cover |
| moment 1 ảnh | **Ảnh in / Polaroid** (viền đáy dày, caption viết tay trên ảnh, nghiêng) | ảnh in nghiêng |
| moment gallery | **Xấp ảnh chồng** + dots/counter — **VẪN 1 milestone** | xấp ảnh + badge số |
| recording | **Băng cassette** — nhãn viết tay = caption thật; **2 cuộn quay khi phát**; lõi trái nhả–phải cuốn theo progress; **waveform CSS deterministic = TRANG TRÍ** (không phải tín hiệu âm thật) | cassette mini |
| session | **Sách mở 2 trang** (gáy + mép lồi; trang trái = **`prevItem` thật**; teacher_note thật) | **sách đóng** + **⭐ sao** |
| text | **Trang thư viết tay** (giấy kẻ + lề đỏ + mép rách) | thiệp gập |
| video | **KHÔNG dựng** (0 data thật) | — |

**Ngôn ngữ vật thể thống nhất:** giấy ngà · gỗ ấm · kim loại ám vàng · ánh sáng chếch trên-trái · bóng đổ cùng hướng · **media LUÔN là hero**.
**Copy:** "Kệ kỷ vật của con" · "Hành trình nghệ thuật của An". **KHÔNG dùng "Blind Box"/"Hộp mù" trong UI.**

---

## 6. ⭐ Signing — CTO REVISED GUARD

> Guard cũ: *"preserve selected ±2 progressive signing"*
> **Guard mới: *"preserve progressive per-item VIEWPORT signing with cache"*** (CTO phân xử sau UX review thật).

- **IntersectionObserver**: `root` = container rail · `rootMargin "0px 240px"` · `threshold 0.01` · `data-idx` map → index · fallback ±2 nếu không có IO.
- **Bất biến:** no batch · no adapter-sign · no RPC `signed_url` · no raw Bunny URL · no duplicate sign · denied/error giữ placeholder theo loại · **remount/animation KHÔNG kích hoạt ký** · stage & gallery dùng **chung cache**.

### Nghiệm thu Network THẬT
| Bước | Filter `get_signed_media_url` |
|---|---|
| Mở journey (desktop rộng) | **24** = 12 fetch + 12 preflight = đúng **12 media có ảnh** (6 drawing + 6 moment cover). audio/session/text `cover=null` → **0 request** |
| Mở journey (mobile 390px) | **4** (2 fetch + 2 preflight) — ít kỷ vật lọt viewport |
| Đổi mốc | 24 → **24** (không tăng) |
| Quay lại mốc cũ | **0 re-sign** ✓ |

*Tổng request trang tăng (90→96) là do DevTools ☑️ **Disable cache** ép tải lại ảnh Bunny — KHÔNG phải signing.*

---

## 7. Bug đã đóng

| Bug | Gốc | Fix |
|---|---|---|
| Ảnh vỡ / giật / không cache | Bunny **TTL 10′** + cache "known" cứng → URL chết vẫn `ok` | **TTL 8′** + `resign()` on `<img onError>` + `inflight` dedup |
| Rail chỉ 3 card có ảnh | window ±2 | **viewport lazy-sign** (IO) |
| **Audio không phát trên iPhone** | **`audio/webm`** — iOS Safari không hỗ trợ (Chrome iOS cũng dùng engine Safari) | Lối A: báo nhẹ + **"Tải bản thu về máy"**; **KHÔNG sửa data** → 🔴 **ticket riêng** |
| Nhãn tháng bị cắt đầu kệ | offset âm sát mép | `LEAD = 20px` |

⚠️ **DevTools device-emulation KHÔNG phát hiện lỗi codec iOS** (vẫn engine Chrome) → codec/media phải test **thiết bị thật**.

---

## 8. Commits (Lovable, typecheck pass + get_diff verify mỗi bước)

| Giai đoạn | Commit |
|---|---|
| C3.1 pure model | `8a6106bf` |
| C3.2 toggle + shell | `c3fd0965` |
| C3.3 stage renderers | `3e1cd9ef` |
| C3.4 rail + progressive | `92b38897` |
| C3.5 polish | `279dbd9f` |
| V92B.1 C4.1 TTL+resign | `6b9a7d9c` |
| C4.2 viewport lazy-sign | `f3395e3b` |
| C4.3 img retry + iOS audio | `4c8f08db` |
| C5 rail redesign | `5b411095` |
| C6 sách + transition + repeat | `65d755df` · `1fe57641` |
| V92B.2 gáy sách + header rail | `826e30e2` |
| V92C kỷ vật (cassette/khung/polaroid/thư) | `a7693930` · `a1b0bd45` · `2cd4ff0d` |
| Memory Objects A/B/C/A2 | `509adefe` · `48584209` · `afbc3632` · **`1659d4dd`** |

**Deploy prod:** `demenart.lovable.app` / `demenart.com` — deployment **`fc927714`**, commit **`1659d4dd`**.

---

## 8b. ⭐ V92B.2 — Stable Memory Player + Gallery / Fullscreen polish (D224-B)

CTO **không đóng V92** sau deploy đầu (`fc927714`); mở pass V92B.2 vì mobile review lộ 2 lỗi cấu trúc. Vẫn **FRONTEND-ONLY** (0 DB/RPC/Edge).

### Vấn đề → Fix
| Vấn đề | Gốc | Fix |
|---|---|---|
| **Kệ kỷ vật nhảy dọc** khi đổi loại kỷ vật | `STAGE_MEDIA` dùng **`min-h`** (chiều cao *tối thiểu*) → cassette / khung tranh cao hơn ⇒ stage phình ra khác nhau | **`h-[46vh] max-h-[46vh]` (mobile) / `h-[56vh]` (desktop)** CỐ ĐỊNH + mọi kỷ vật **co vừa khung** (tranh `30vh` · polaroid `26vh` · cassette thu gọn · sách/thư giảm padding) ⇒ **5 loại = cùng chiều cao pixel** ⇒ rail bất động |
| Story đẩy rail (mobile) | detail nằm **giữa** stage và rail | Tách **`JourneyDetail.tsx`**; DOM: **stage → rail → "Xem câu chuyện" (bottom Sheet)**; desktop = cột phải **bounded** `max-h-[52vh] overflow-y-auto` |
| Gallery khó khám phá (chỉ dots) | — | **‹ ›** non-cyclic 44px + **swipe ngang** (chỉ đổi ảnh trong moment) + **giữ dots/counter** |
| Chưa có "Xem lớn" | — | **`JourneyFullscreen.tsx`** — **KHÔNG** tái dùng `ParentJournalLightbox` (nó có **cache ký riêng** ⇒ sẽ ký lại). Dùng cache `useJourneySigning` ⇒ **0 request khi mở** |
| Kệ rơi khỏi màn đầu (mobile) | header ăn ~40% viewport | Nén: ẩn subtitle (journey-mode) · chip trẻ lên hàng tiêu đề · **toggle icon-only mobile** |
| Toggle rơi xuống dòng ở Nhật ký | `flex-wrap` + subtitle 2 dòng | Bỏ `flex-wrap`, cột trái `min-w-0 flex-1` ⇒ toggle **ghim phải-trên cả 2 chế độ** |

### Fullscreen — drag-to-close **pinch-safe**
**KHÔNG dùng Drawer/vaul** (drawer độc chiếm gesture ⇒ **giết pinch-zoom**). Tự viết trên Dialog: chỉ nhận **1 ngón** · **≥2 ngón (pinch) → nhả gesture ngay** · khoá **trục dọc** (không tranh swipe ngang) · thả >110px = đóng · grab handle mờ ở đỉnh. **Pinch/pan zoom = backlog** (đường đã chừa).

### Guard signing giữ nguyên
viewport lazy-sign (IO) · TTL 8′ + `resign` · gallery sign-on-demand · **no batch / no adapter-sign / no RPC signed_url / no raw Bunny** · cached media **0 re-sign** (kể cả khi mở fullscreen / bấm arrows / dots).

### Commits V92B.2
`cf955ee4` (A shell) · `998637bd` (B gallery) · `4fefb769` (C fullscreen) · `ffe56219` (E multi-year) · `a9d304a9` (F mobile density) · `5e256663` (H **fixed height**) · `d5537aee` (I icon toggle + tranh to hơn) · `48c6ed4c` (J toggle pin).

**Deploy prod:** `demenart.com` — deployment **`d392fad7`**, commit **`48c6ed4c`**.
**CTO verdict: ĐẠT** — nghiệm thu iPhone thật: rail bất động · kệ lộ màn đầu · kéo-xuống-đóng mượt · pinch không bị nuốt · Nhật ký nguyên vẹn.

---

## 9. Regression — PASS

- **An 6/2/6** ✓ · **Inventory 63/107/155/1** ✓ (0 backend đụng)
- **Nhật ký** (V74–V83) byte-stable ✓ · gallery V79–V81 ✓ · lightbox ✓ · privacy badge ✓ · warm copy ✓ · conversation prompt ✓ · consent V72 ✓ · badge dedup V73 ✓
- **Kid** không đụng ✓ · **Teacher** không đụng ✓
- `get_child_journal` · `kid_gate` · `upload_media` · `remove_moment_media_service` · `archive_empty_draft_moment_service` — **KHÔNG đụng** ✓
- Keyboard ←/→/Home/End ✓ *(Mac: Home = `Fn+←`, End = `Fn+→`)* · mobile snap ✓ · reduced-motion ✓ (cuộn cassette đứng yên) · console sạch (chỉ noise preview: favicon 404 / postMessage / hydration tiền-tồn ở `/parent` home)

---

## 10. Rollback

Xoá `src/features/journey/` + revert `parent.journal.tsx` về sha trước **`8a6106bf`** (Lovable History) → về **V91 chính xác**.
**0 DB đụng ⇒ rollback tuyệt đối sạch, không mất data.**

---

## 11. Backlog

- 🟠 re-sync project library (**D224** + **v0.85** + **v92**) · 🟠 lưu repo V92 (7 file mới + 1 edit)
- 🔴 **(mới, ưu tiên) Audio pipeline** — Kid ghi âm ra **`audio/webm`** → **KHÔNG phát được iOS Safari**. Chuẩn hoá `.mp4/aac` khi ghi **HOẶC** transcode server-side. Sprint riêng (đụng Kid upload / Edge / storage).
- 🟡 **(mới) Art Discovery Capsule** (Hộp Khám Phá 3/6/12 tháng) — **extension point ĐÃ CHỪA** (rail-object switch + `JourneyViewerItem`). V92 **KHÔNG build**: 0 fake data · 0 hardcoded capsule · 0 locked box · 0 threshold · 0 scoring · 0 AI insight · 0 DB change. **Không loot-box · không randomization · không rarity · không khoá ký ức của trẻ.** Cần policy + CTO duyệt.
- 🟡 **(mới) Kid adaptation** — "Nhật ký của con" / "Cùng xem hành trình ✨" (V92C gốc, Parent-first theo CTO). Bắt buộc giữ `kid_gate` (không tái dùng signing Parent).
- 🟡 **(mới) Portal header/logo chung 4 portal** (Parent/Teacher/School/Admin) — CTO chốt **sprint riêng V93**.
- 🟡 **(mới) Memory Conversation / "Câu chuyện quanh kỷ vật"** — extension point đã chừa trong `JourneyDetail`. V92 **KHÔNG build**: 0 comment/reply/notification/unread/social reaction.
- 🟡 **(mới) Context Navigator: Year → Month → Keepsakes** — nhãn year-aware đã sẵn (`Tháng 7 · 2026`), navigator chưa build.
- 🟡 **(mới) Pinch/pan zoom trong fullscreen** — đường đã chừa (drag-to-close nhả gesture khi ≥2 ngón).
- 🟠 Bunny orphan `/moments/b2ce6685/*` (3 object) · 🟢 lifecycle purge THẬT
- Nợ cũ: `upload_media` source mig068 · consent-filter Kid · filter/month-nav · timeline "X ảnh" · `cover_media_id`/`sort_order` · **KHÔNG Edge batch-sign** · Parent Dashboard/Radar/AI Review THẬT · Phương án B RPC · rename `kidJourneyModel.ts` · enrichment `child_journey` · Coloring schema · Moment media taxonomy.

---

## 12. Tài khoản test

| Vai | Email | Mật khẩu |
|---|---|---|
| PH bé An (KHM) | `ph.hung.kidshouse@demo.demenart.com` | `Test@123` |

Bé **An** = `d1000000-0000-4000-8000-000000000041` (KHÔNG phải `…042` = Trần Thanh Bình).
