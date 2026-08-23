# DMA_HANDOFF_v75.md
**Sprint:** Parent Journal Compact Timeline Spine — "Từ album ảnh dọc thành trục ký ức nghệ thuật"
**Ngày:** 2026-07-09 12:52 GMT+7 (Asia/Ho_Chi_Minh)
**Vai trò:** ChatGPT = CTO Advisor · Claude = PM + Prompt Operator + Builder · Lovable = build
**Trạng thái:** ✅ ĐÓNG SỔ — deployed production
**File duy nhất bị đụng:** `src/routes/_authenticated/parent.journal.tsx`

---

## 0. TL;DR

V74 dựng được **timeline spine** nhưng leaf reuse thẳng full `CreationCard`/`MomentCard` → ảnh 500–700px, một màn chỉ thấy 1–2 mốc → cảm giác **"album ảnh dọc"**, trục bị chìm. V75 **nén**: thay full card bằng **compact leaf** (horizontal card: rail thumbnail ~96px + cột chữ), trục là nhân vật chính, bấm leaf mới mở lightbox lớn.

**Zero-touch engine ký/consent:** moment leaf reuse `MomentImage` nguyên xi; creation leaf replicate đúng 1 useEffect ký. **Số lần ký media KHÔNG đổi so V74.** Frontend-only, 1 file, 0 DB/RPC/Edge/Auth/RLS/AI, 0 re-sign, summary 6/2/3 bất biến, badge KHÔNG lên trục.

Deployed: `https://demenart.lovable.app` · commit cuối `7b8b9f46`.

---

## 1. Commits (agent auto-app, deploy 1 lần cuối)

| Commit | SHA | Nội dung |
|---|---|---|
| C1 | — | **Audit-only, 0 code.** Đọc code sống `parent.journal.tsx`. Chốt: signing/consent sống trong `MomentImage`/`CreationCard`, mỗi media ký 1 lần; compact an toàn nếu reuse engine + tái dùng URL đã ký, KHÔNG mount thêm signer. Chốt 1A + 2A với Jean. |
| C2 | `21df44db` | Thêm `CompactMomentLeaf` + `CompactCreationLeaf` (export, dead-code an toàn tới C3). Moment reuse `MomentImage` nguyên xi; creation replicate 1 useEffect ký. Không đụng render/adapter/session. |
| C3 | `26d8ebf9` | Swap render `creation→CompactCreationLeaf` / `moment→CompactMomentLeaf` (session giữ `TimelineSessionLeaf`); xoá `MomentCard`/`CreationCard` mồ côi (−156 dòng); siết trục (`space-y-6→space-y-4`, line `amber-200/60→amber-300/50`); session `p-4→p-3.5`. |
| C4 | `7b8b9f46` | Polish nhỏ: node `top-1.5→top-2` (canh giữa leaf header) + day micro-header `mb-3→mb-2`. Không import mồ côi. |

Mỗi commit: `send_message` → `get_diff` (verify sạch đúng 1 file, KHÔNG đụng `routeTree.gen.ts`) → typecheck pass. Deploy 1 lần cuối sau C4 (sau khi Jean review preview compact).

---

## 2. Kiến trúc chốt — Compact = zero-touch engine

**Moment leaf (`CompactMomentLeaf`)** reuse `MomentImage` **nguyên xi** (không sửa) trong rail:
```
flex + min-h-[96px] + w-24 + self-start + relative + overflow-hidden
```
CSS flex `items-stretch` tự lo 3 state của MomentImage:
- `ok` → img `h-full w-full object-cover` thành **thumbnail 96×96**.
- `denied` → hộp thông báo tự **nở cao** (content > min-h) hiện "Đang chờ… + Vì sao?" (ConsentWaitingHint sống nguyên).
- `loading` → Skeleton stretch 96px.

`onReady(url)` → `signedUrl`; overlay "Xem" `absolute inset-0` **CHỈ render khi `canOpen`** → giữ D203/D204: denied không click xuyên mở ảnh, không che nút "Vì sao?".

**Creation leaf (`CompactCreationLeaf`)** replicate **đúng 1 useEffect ký** của CreationCard cũ (cùng Edge `get_signed_media_url`, cùng `media_id`, cùng state machine `loading/ok/denied`):
- drawing → thumbnail 96×96 click mở `ParentJournalLightbox` bằng `state.url`.
- recording → 🎤 ở rail + `<audio controls preload="none">` compact ở cột chữ (audio giữ nguyên hành vi).

**Lightbox** tái dùng URL đã ký (moment qua `onReady`→`signedUrl`; creation qua `state.url`) — **KHÔNG re-sign, KHÔNG media_id thô**.

**Số lần ký/media = V73/V74:** moment 1 · creation 1 · session 0 · lightbox 0 thêm.

**Điểm mấu chốt (D207):** khi engine ký/consent đã đúng, cách an toàn nhất để nén UI là **bọc lại lớp trình bày quanh engine**, KHÔNG chọc vào engine. Chọn 2A (rail nở cao lo denied) thắng phương án thêm prop `onDenied` vào `MomentImage`.

---

## 3. Quyết định thiết kế (Jean chốt)

- **1A — Share giữ ở leaf:** `ShareMomentButton` nhỏ nằm ở cột chữ compact moment leaf. Share KHÔNG mất, không đưa vào lightbox, không đụng `ParentJournalLightbox`.
- **2A — Denied zero-touch:** KHÔNG thêm prop `onDenied` vào `MomentImage`. Rail `min-h` nở cao khi consent-blocked. **Ưu tiên tuyệt đối:** "Vì sao?" sống + không bị overlay che > đồng đều chiều cao leaf. Leaf denied cao hơn leaf ok là đánh đổi chấp nhận.

---

## 4. Nghiệm thu

- **Jean review preview compact** (không lỗi visual lớn) → duyệt C4 + deploy production.
- **An live-verified state:** `display_in_app` ON; `group_moment_in_class` **TẮT** (từ QA V74) → 2 ảnh nhóm 28/6·29/6 hiện dạng compact leaf **"Đang chờ… + Vì sao?"** (đúng để soi 2A), ảnh 1-bé 26/6 ra thumbnail ok. Bật lại `group_moment_in_class` ở `/parent/consent` nếu muốn đủ 3 khoảnh khắc khi demo.
- **Sign count / summary:** adapter + RPC nguyên xi → An giữ 15 leaf (4 buổi + 6 tranh + 2 âm + 3 khoảnh khắc), 0 badge; `/parent` summary 6/2/3 bất biến (`parent.index.tsx` không đụng).

**Login test (An):** `ph.hung.kidshouse@demo.demenart.com` · mật khẩu `Test@123`.

---

## 5. Local components trong `parent.journal.tsx` (sau V75)

**Mới V75:**
- `CompactMomentLeaf({ moment })` — reuse `MomentImage` + overlay canOpen + share nhỏ + lightbox.
- `CompactCreationLeaf({ creation })` — replicate useEffect ký; drawing thumbnail / recording audio compact.

**Giữ byte-exact (KHÔNG đụng):** `MomentImage`, `MomentPrivacyBadge`, `ShareMomentButton`, `ParentJournalLightbox`, `ConsentWaitingHint`, `entryVisual`, `TimelineSessionLeaf` (chỉ đổi `p-4→p-3.5`), adapter V74 (`buildParentTimeline`/`groupTimelineByMonth`/`timelineNode`/`formatTimelineMonthLabel`/`formatTimelineDayLabel`/`hcmYmd`).

**Đã xoá (mồ côi sau swap render):** `MomentCard`, `CreationCard`.

---

## 6. Backlog (chưa làm ở V75)

- **Nghiệm thu ẢNH THẬT compact** — thumbnail ok · drawing/moment lightbox mở · recording audio chạy · consent-blocked leaf denied nở cao + "Vì sao?" sống. (V75 nghiệm thu bằng preview Jean + cấu trúc, chưa gói ảnh như V74.)
- **Lưu repo/backup** `parent.journal.tsx` V75 (Jean thủ công).
- **Badge trên trục** (compact/detail) — đọc từ `badges[]`, KHÔNG từ `journey.entry_type='badge'`; QA bằng Jenny (An 0 badge).
- Multi-image moment (`coverMediaUrl`/`mediaCount`/`galleryItems[]`) — chờ backend trả 1-n media.
- Enrichment `child_journey` (creations/moments chảy vào spine) · Phương án B RPC canonical `get_child_journey_service` · rename `kidJourneyModel.ts` · Parent Dashboard đầy đủ/Radar/AI Review THẬT · Coloring JSON schema · Moment media taxonomy — như backlog cũ.
- Cập nhật GitHub backup commits (migrations cũ) + living `DMA_RULES.md` (endpoint **D207**) + `DMA_SYSTEM_MAP.md` (**v0.68**): Jean thực hiện thủ công (delta đã kèm dưới).

---

## 7. Guard đã giữ trọn (V75)

1 file · 0 DB/RPC/Edge/Auth/RLS/migration · 0 AI thật · 0 npm · 0 import mồ côi · không đụng `parent.index.tsx`/`kidJourneyModel.ts`/`routeTree.gen.ts`/adapter V74/sidebar/summary · **số lần ký media KHÔNG đổi** · 0 re-sign · không media_id thô mở ảnh · 0 lift signed_url lên adapter · không phá `MomentImage`/`ConsentWaitingHint`/`ShareMomentButton`/`ParentJournalLightbox` · summary 6/2/3 bất biến · không phá Lightbox V71 / consent V72 / dedup V73 / spine V74 · không hardcode data giả · badge không lên trục.

**Endpoint sau V75:** RULES **D207** · SYSTEM_MAP **v0.68** · Handoff **v75**.
