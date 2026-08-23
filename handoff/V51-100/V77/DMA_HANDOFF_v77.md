# DMA_HANDOFF_v77.md
**Sprint:** Parent Home / Journey Overview Polish (V77A) + Multi-media Moment Gallery PLANNING (V77B)
**Ngày:** 2026-07-09 14:00 GMT+7 (Asia/Ho_Chi_Minh)
**Vai trò:** ChatGPT = CTO Advisor · Claude = PM + Prompt Operator + Builder · Lovable = build
**Trạng thái:** ✅ ĐÓNG SỔ — V77A deployed production · V77B audit-only (ghi backlog, KHÔNG code)
**File duy nhất bị đụng:** `src/routes/_authenticated/parent.index.tsx`

---

## 0. TL;DR

Sprint **kép**. **V77A** biến `/parent` từ "dashboard số liệu" thành **"cửa vào hành trình nghệ thuật của con"**: hero ấm hơn + summary 6/2/3 có diễn giải cảm xúc + 1 card "dòng thời gian" text-only dẫn vào `/parent/journal`. **Frontend-only, 1 file, 0 DB/RPC/Edge/Auth/RLS/migration/AI/signing.** Jean chốt **Q1=A** (preview text-only) · **Q2=agent mode**.

**V77B** chỉ **AUDIT + PLAN** cho hướng "1 moment có 1-n media → gallery". Kết luận trung thực: **schema đã sẵn 1-n** nhưng **RPC trả 1 media/moment** và **data thực chưa có moment nào ≥2 ảnh** → gallery CHƯA làm được, ghi backlog phân sprint rõ. KHÔNG code DB/Edge.

Deploy: `https://demenart.lovable.app` · deployment `1a3288fa` · commit cuối `05ec1209`.

---

## 1. Commits (agent auto-app, deploy 1 lần cuối sau khi Jean review 5 ảnh)

| Commit | SHA | Nội dung |
|---|---|---|
| C1 | — | **Audit-only (0 code).** Đọc code sống `parent.index.tsx` + `kidJourneyModel.ts`; đọc DB sống: `get_child_journal` body, schema `learning_moments`/`media_assets`/`moment_children`, phân bố media/moment. Báo Plan A/B. |
| C2 | `b41c10cc` | **Hero + summary copy polish.** Hero: thay `<p>` mô tả thành dòng 1 "Hành trình nghệ thuật của con đang lớn lên từng ngày." + dòng phụ (mt-1, text-xs, muted/80) "Mỗi tác phẩm, âm thanh và khoảnh khắc là một chiếc lá ký ức trên dòng thời gian của con.". `SummaryStat` thêm prop optional `hint?: string` (render `text-[11px] text-muted-foreground/70` dưới label). 3 stat: hint "Con tự tay làm nên."/"Giai điệu con đã thử."/"Được lưu lại ở lớp." + đổi nhãn **"Giọng hát"→"Âm thanh"**. KHÔNG đổi logic đếm. |
| C3 | `05ec1209` | **Memory highlight text-only.** Thêm type `PreviewLeaf` + helper thuần `formatDayMonth(iso)` (Intl `d/M`, TZ HCM) + `buildPreview(data)` (module scope) + state `preview`. `buildPreview` merge `journey`(entry_type≠"badge")/`creations`/`moments` từ payload `get_child_journal` ĐÃ fetch → sort desc → `slice(0,3)`. Card "Dòng thời gian nghệ thuật của {con}" liệt kê 2–3 lá (emoji+nhãn+caption ngắn+ngày) + CTA "Xem dòng thời gian của con" → `/parent/journal`. Chỉ render khi `hasData && preview.length>0`. |

Mỗi commit: `send_message` → `get_diff` (verify SẠCH đúng 1 file, KHÔNG đụng `routeTree.gen.ts`) → typecheck pass. Deploy 1 lần cuối sau C3. Tổng ~4.2 credit.

---

## 2. Kiến trúc chốt V77A — polish LỚP TRÌNH BÀY, đọc lại data đã fetch (D209)

**Preview text-only = đọc lại payload đã có, KHÔNG ký lại:**
- `/parent` đã gọi `get_child_journal(p_child_id)` để tính summary qua `summarizeChildJournal`. Card "dòng thời gian" **tái dùng đúng payload đó** qua `buildPreview(data)` — 0 RPC/Edge thêm, 0 `signed_url`, 0 thumbnail.
- ⭐ **Rào trung thực:** moment CHỈ vào preview khi **có `media_id`** (`if (!m.media_id) continue`) → khớp `hasDisplayableMedia` (rule đếm 6/2/3) VÀ khớp đúng cái `/parent/journal` thật hiện → preview KHÔNG lệch số, KHÔNG hứa lá mà journal không có.
- `buildJourneyFeed` (V64, `/kid`) **KHÔNG tái dùng được** cho parent: nó `if (!signed_url) continue`, mà parent payload chỉ có `media_id` (không `signed_url`). → merge text-only TẠI CHỖ trong `parent.index.tsx`, KHÔNG chọc `kidJourneyModel.ts`.
- Empty/thiếu data → card không render, empty-state cũ giữ copy ấm, 0 lỗi.

**Summary 6/2/3 GIỮ nguyên logic:** vẫn `summarizeChildJournal(data)`; C2 chỉ đổi CHỮ (label + hint). Đổi "Giọng hát"→"Âm thanh" là đổi hiển thị (trung thực hơn: recording không chỉ là hát; khớp chip journal "Âm thanh của con").

---

## 3. Quyết định (Jean chốt)

- **Q1 = A** — memory highlight = preview text-only 2–3 lá mới nhất (emoji+ngày+title/caption), KHÔNG ký media/thumbnail. (B = chỉ copy+CTA, không chọn.)
- **Q2 = agent mode** — Claude tự áp qua Lovable agent (`send_message`→`get_diff`→`deploy_project`).

---

## 4. Nghiệm thu — PASS bằng 5 ảnh (PH Hùng, con An)

- **`/parent` hero:** "Chào ba mẹ của An 💛" + "Hành trình nghệ thuật của con đang lớn lên từng ngày." + dòng phụ "…một chiếc lá ký ức trên dòng thời gian của con.". 2 CTA giữ.
- **Summary card "Hành trình của An tới nay":** **6 Tác phẩm** "Con tự tay làm nên." · **2 Âm thanh** "Giai điệu con đã thử." · **3 Khoảnh khắc** "Được lưu lại ở lớp." → **6/2/3 GIỮ**, nhãn "Âm thanh" đúng, hint hiện. "Hạt giống nổi bật: Hát theo".
- **Child selector:** An / Khang (2 con → hiện selector, hoạt động).
- **`/parent/journal` (ảnh 2–5) nguyên vẹn V74–76:** Tháng 7 (8/7·7/7·6/7 tranh + âm thanh), Tháng 6 (29/6·28/6 khoảnh khắc, 26/6 "Riêng gia đình", 24/6·23/6·19/6 buổi học); lightbox "Xem"; privacy "Ảnh chung nhiều bé"/"Riêng gia đình"; "Cô nhận xét" curly-quotes ("Tiếng mưa rơi"); kỹ năng "Hát theo".
- Data An khớp → preview `/parent` dẫn đúng lá tháng 7 mới nhất.

**Login test (An):** `ph.hung.kidshouse@demo.demenart.com` · mật khẩu `Test@123`.

---

## 5. V77B — Multi-media Moment Gallery (AUDIT-ONLY, backlog)

**Audit DB sống (2026-07-09), 9 câu trả lời:**
1. Moment nhiều media? → **CÓ về schema**: `media_assets.linked_moment_id` là FK **1-n**. Nhưng **data thực: 0 moment ≥2 ảnh** (toàn hệ 6 moment×1 ảnh, 2 moment×0 ảnh).
2. RPC trả 1 hay nhiều? → **1** (`WHERE linked_moment_id=lm.id AND state='active' ORDER BY created_at LIMIT 1`).
3. RPC mới hay chỉnh? → chỉ **chỉnh `get_child_journal`** (bỏ LIMIT 1 → `jsonb_agg`). `get_child_journey_service` (Phương án B) vẫn chưa tồn tại.
4. Cover field? → **CHƯA** (`learning_moments` không có `cover_media_id`; RPC dùng "ảnh đầu theo created_at" ngầm).
5. Sort/order? → **CHƯA** cột `sort_order`; chỉ `ORDER BY created_at`. `media_assets.metadata` jsonb có thể nhét order để né migration.
6. mediaCount? → **CHƯA.**
7. Shape gallery? → `coverMediaId`/`mediaCount`/`galleryItems[]`; `galleryItems[].kind` map từ `media_assets.file_type`.
8. Consent multi-child? → consent gate ở tầng leaf (per-media qua Edge, check `moment_children`); gallery n ảnh phải ký TỪNG media (Edge tự áp consent), KHÔNG lift signed_url lên RPC.
9. Signed URL Edge? → n ảnh = n lần ký (waterfall) hoặc Edge batch-sign (sprint riêng); giữ pattern RPC trả `media_id` thô, UI ký khi mở, 0 re-sign.

**Kết luận trung thực:** Gallery thật **KHÔNG làm được frontend-only** ở V77 (thiếu data 1-n). Enrich RPC bây giờ chỉ ra gallery-1-item → vô nghĩa tới khi có data.

**Thứ tự sprint sau (đề xuất):**
1. **DATA** — seed/upload nhiều ảnh trên một moment *(bắt buộc trước tiên)*.
2. **RPC enrich (Option 1)** — `get_child_journal` trả `galleryItems[]`+`mediaCount`+`coverMediaId`. **0 migration** nếu cover = ảnh đầu theo created_at.
3. **UI gallery** — dựng trong `ParentJournalLightbox`, ký TỪNG item khi mở (consent per-media, 0 lift signed_url, 0 re-sign — giữ D203/D204/D206).
4. *(tùy)* **migration cover/sort (Option 2)** — chỉ khi cần chọn cover thủ công/sắp thứ tự.
5. *(tùy)* **Edge batch-sign (Option 3)** — chỉ khi gallery nhiều ảnh gây waterfall.

---

## 6. Backlog (chưa làm ở V77)

- **Lưu repo/backup** `parent.index.tsx` V77 (Jean thủ công).
- **Multi-media moment gallery** — thứ tự sprint như §5 (DATA → RPC enrich → UI ký từng item → tùy migration/batch-sign). V77 KHÔNG fake.
- Enrichment `child_journey` (creations/moments chảy vào spine) · Phương án B RPC canonical `get_child_journey_service` · rename `kidJourneyModel.ts` · Parent Dashboard đầy đủ/Radar/AI Review THẬT · Coloring JSON schema · Moment media taxonomy — như backlog cũ.
- Cập nhật GitHub backup commits (migrations cũ) — Jean thủ công.
- Living `DMA_RULES.md` (endpoint **D209**) + `DMA_SYSTEM_MAP.md` (**v0.70**): bản replacement đầy đủ kèm phiên này.

---

## 7. Guard đã giữ trọn (V77)

1 file (`parent.index.tsx`) · 0 DB/RPC/Edge/Auth/RLS/migration · 0 AI thật · 0 signing/signed_url · 0 render ảnh/thumbnail · 0 fetch thêm · 0 npm · 0 import mới · KHÔNG đụng `kidJourneyModel.ts`/`parent.journal.tsx`/`kid.tsx`/`routeTree.gen.ts` · **summary 6/2/3 logic KHÔNG đổi** (`summarizeChildJournal` nguyên) · child selector nguyên · empty/loading state nguyên · preview moment CHỈ lấy có `media_id` (khớp count & journal thật) · KHÔNG hardcode data giả · KHÔNG fake gallery/multi-image · KHÔNG phá `/parent/journal` V74–76 / `/kid` / consent V72 / badge dedup V73 · get_diff SẠCH cả 2 lượt (đúng 1 file) · deploy sau khi Jean review 5 ảnh.

**Lưu ý nhỏ:** C3 để lại 1 dòng trống cosmetic trước card tips "Ba mẹ có thể cùng con…" — vô hại render/typecheck; dọn sau nếu muốn (không đáng tốn credit riêng).

**Endpoint sau V77:** RULES **D209** · SYSTEM_MAP **v0.70** · Handoff **v77**.
