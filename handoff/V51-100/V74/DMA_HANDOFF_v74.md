# DMA_HANDOFF_v74.md
**Sprint:** Parent Journal Timeline Spine — "Cây ký ức nghệ thuật của con"
**Ngày:** 2026-07-09 (Asia/Ho_Chi_Minh)
**Vai trò:** ChatGPT = CTO Advisor · Claude = PM + Prompt Operator + Builder · Lovable = build
**Trạng thái:** ✅ ĐÓNG SỔ — deployed production
**File duy nhất bị đụng:** `src/routes/_authenticated/parent.journal.tsx`

---

## 0. TL;DR

Chuyển `/parent/journal` từ **section-based journal** (3 Card rời: Hành trình + Tác phẩm + Khoảnh khắc) sang **timeline-spine journal** — một trục dọc trung tâm, mỗi ký ức là một "chiếc lá" gắn theo tháng/ngày. Hướng **A-rich**: leaf reuse thẳng `CreationCard`/`MomentCard`, session dùng block riêng không media. **Frontend-only, 1 file, 0 DB/RPC/Edge/RLS/AI, 0 re-sign, summary 6/2/3 bất biến.**

Deployed: `https://demenart.lovable.app` · commit cuối `3aa591b`.

---

## 1. Commits (auto-áp qua Lovable agent, deploy 1 lần cuối)

| Commit | SHA | Nội dung |
|---|---|---|
| C1 | `1f41a67` | Adapter thuần metadata `buildParentTimeline` + `groupTimelineByMonth` + `formatTimelineMonthLabel/DayLabel` + `hcmYmd`. Types `ParentTimelineEvent` / `ParentTimelineMonth`. Dead-code an toàn tới C2. |
| C2 | `e7b38df` | Timeline spine UI: thay 3 section rời ở cột chính bằng 1 trục. Leaf render: `journey→TimelineSessionLeaf` (mới, không media) · `creation→CreationCard` · `moment→MomentCard`. Sidebar (Kỹ năng + Huy hiệu) giữ nguyên. |
| C3 | `3aa591b` | Polish: `timelineNode(ev)` icon/màu theo loại (🎨 rose · 🎵 teal · 📸 sky · 🚌 amber), micro-header ngày trong tháng, line mềm (border-l-2 amber-200/60), dọn import mồ côi `Palette`. |

Mỗi commit: `send_message` → `get_diff` (verify sạch đúng 1 file, không đụng `routeTree.gen.ts`) → typecheck pass. Deploy 1 lần cuối sau C3.

---

## 2. Kiến trúc chốt

**Adapter thuần metadata** (không ký, không chạm media):
- Merge `journey`(entry_type≠"badge") + `creations` + `moments` → `ParentTimelineEvent[]`, sort desc theo `occurredAt`, group tháng.
- Field ngày: journey→`occurred_at` · creation→`created_at` · moment→`created_at`.
- Badge **KHÔNG lên trục** (giữ dedup V73/D205; sidebar "Huy hiệu kỷ niệm" là nguồn chính).

**Leaf render (A-rich):** trục chỉ sắp xếp; mỗi leaf gọi lại đúng component sẵn có → **signing lẻ + consent gate + lightbox V71 + share + privacy badge tự sống, số lần ký không đổi so với V73**. Đây là lý do A-rich rủi ro thấp nhất: không lift signed_url lên tầng cha, không re-sign, không tự dựng cover.

**Điểm mấu chốt data:** payload parent chỉ mang `media_id` (KHÔNG signed_url — khác `/kid` ký batch tầng RPC). Mọi ký sống trong `MomentImage`/`CreationCard` qua Edge `get_signed_media_url`.

---

## 3. Nghiệm thu (An — live-verified)

An (`d1000000-…-0041`): **15 leaf** = 4 buổi học + 6 tranh + 2 âm thanh + 3 khoảnh khắc · **0 badge**.
- Tháng 7, 2026: 8/7 · 7/7 · 6/7 (8 tác phẩm)
- Tháng 6, 2026: 29/6 · 28/6 · 26/6 · 24/6 · 23/6 · 19/6 (3 khoảnh khắc + 4 buổi học)

QA 17 ảnh PASS: trục spine đúng · lightbox tranh mở · lightbox khoảnh khắc mở · recording audio chạy · share mở + consent-gate đúng · **consent-blocked KHÔNG rò "Xem lớn"** (tắt `group_moment_in_class` → 2 ảnh nhóm thành "Đang chờ… + Vì sao?") · **`/parent` summary giữ 6/2/3** (kể cả khi tắt consent) · badge dedup giữ.

Consent An hiện tại: `display_in_app` ✅. **`group_moment_in_class` đang TẮT sau QA** — bật lại ở `/parent/consent` nếu muốn 3 khoảnh khắc hiện đủ khi demo.

---

## 4. Local components mới trong `parent.journal.tsx`

- `buildParentTimeline(data)` · `groupTimelineByMonth(events)` · `formatTimelineMonthLabel/DayLabel(iso)` · `hcmYmd(iso)` — adapter + format (export).
- `timelineNode(ev)` → `{emoji, bg}` theo loại.
- `TimelineSessionLeaf({entry})` — leaf buổi học/hành trình không media (dùng `entryVisual` + `formatViDate` + teacher_note block).

Giữ nguyên byte-exact: `CreationCard`, `MomentCard`, `MomentImage`, `MomentPrivacyBadge`, `ParentJournalLightbox`, `ShareMomentButton`, `ConsentWaitingHint`, `entryVisual`.

---

## 5. Backlog (chưa làm ở V74)

- **B-compact** leaf (cover thumbnail + lightbox thay full card) — nén trục sau khi spine đã đứng; cần audit tách inner-sign để không phá consent/re-sign.
- **Badge trên trục** (compact/detail) — cần đọc từ `badges[]`, không từ `journey.entry_type='badge'`; QA bằng Jenny (An 0 badge).
- Multi-image moment (`coverMediaUrl`/`mediaCount`/`galleryItems[]`) — chờ backend hỗ trợ 1-n media; V74 chỉ để "thép chờ" ở tư duy, chưa build.
- Enrichment `child_journey` (creations/moments chảy vào spine) · coloring JSON schema · moment media taxonomy — như backlog cũ.
- GitHub backup commits & cập nhật living `DMA_RULES.md` (D206) + `DMA_SYSTEM_MAP.md` (v0.67): Jean thực hiện thủ công (delta ở dưới).

---

## 6. Guard đã giữ trọn (V74)

1 file · 0 DB/RPC/Edge/Auth/RLS/migration · 0 AI thật · không đổi `parent.index.tsx`/`kidJourneyModel.ts` · summary 6/2/3 bất biến · 0 re-sign · không media_id thô mở ảnh · 0 lift signed_url · không phá Lightbox V71 / consent V72 / dedup V73 · không hardcode data giả · badge không lên trục.
