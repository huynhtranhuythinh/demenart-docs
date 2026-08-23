# DMA_HANDOFF_v64.md — GIAO CA PHIÊN

> **Đọc kèm:** `DMA_00_START_HERE.md` → `DMA_RULES.md` (**bản SỐNG: D195 + 2 named rule**, sau phiên này **+ D196–D197 + DMA-KID-JOURNEY-001/002/003 + DMA-KID-AI-REVIEW-002/003** — xem §5) → `DMA_SYSTEM_MAP.md` (**v0.57**, sau phiên này bump **v0.58** — xem §5). Đây là handoff mới nhất.
> **Phiên này (v64):** SPRINT **KID JOURNEY** — dựng "**Hành trình nghệ thuật của Trẻ**" trong Cổng Kid: tầng gộp frontend `kidJourneyModel.ts` (C1) → Timeline scrapbook (C2) → polish trung thực (C2.1) → thẻ AI Growth Review placeholder an toàn (C3). Toàn bộ **thuần frontend**, **0 DB/Edge/Bunny/migration**. Kiến trúc chốt = **Option A (gộp phía frontend từ 5 mảng thật của `get_kid_album_service`)**. **Ngày:** 2026-07-08 11:23 GMT+7.
> **⚠️ SỔ SÁCH — CHƯA nối RULES/MAP phiên này:** file `DMA_RULES.md`/`DMA_SYSTEM_MAP.md` **trong thư viện project đang STALE** (đọc được = **D173 / v0.50**, thiếu trọn D174–D195 + 2 named rule của v56–v63). Bản SỐNG (D195 / v0.57) mà v63 xuất **KHÔNG nằm trong thư viện**. → Em **không nối V64 lên base cũ** (tránh làm mất D174–D195). §5 dưới đây liệt kê **nguyên văn** rule mới cần nối; khi Jean đưa bản sống đúng (Plan B), em splice + xuất 2 file hoàn chỉnh.
> **⚠️ DB:** phiên này KHÔNG chạm DB. Audit LIVE đầu phiên (D1) **có** — nhưng chỉ audit cụm bảng Journey (không đếm lại toàn bộ 63 bảng/policy/mig). Số tổng mang từ v63. Phiên sau vẫn nên audit đủ nếu cần con số tổng.

---

## 1. SHIPPED PHIÊN NÀY (agent-mode, `get_diff` từng lượt trước deploy — D134)

| Commit | Nội dung |
|---|---|
| `b38818d` | **C1** — `src/lib/kidJourneyModel.ts` MỚI: tầng gộp thuần TS. `buildJourneyFeed(album)` gộp 5 mảng thật → `JourneyEventViewModel[]` sorted desc; `SEED_CATALOG`; `seedsForSession()`. 0 DB, chưa import (an toàn tuyệt đối). |
| `cc648d7` | **C2** — `kid.tsx`: section "Hành trình" nâng từ timeline mềm → **scrapbook** (thẻ ảnh/audio/hạt giống/ngày, reuse `KidAudioCard`), filter mềm (Tất cả·Tác phẩm·Âm nhạc·Lớp học·Cột mốc, pill chỉ hiện khi có data), `journeyEmoji()`. Gỡ `journeyIcon` + `const journey` thừa. |
| `a368e3e` | **C2.1** — (1) bỏ "Hôm nay" → **3 mẫu câu trung tính xoay theo `creation_id`** (`DRAW_STORIES`+`hashIndex`, ổn định, không suy đoán chủ đề/màu/cảm xúc). (2) Đồng bộ badge "Khoảnh khắc" ở album → **"Khoảnh khắc ở lớp"**; xoá `MOMENT_SOURCES`+`sourceForMoment` (mock). |
| `47eddf6` | **C3** — `kid.tsx`: thẻ **AI Growth Review** đầu section Hành trình. `journeySpanDays()`+`topSeeds()`. Nhãn **"AI hỗ trợ quan sát"**. `reviewReady = span≥90 ngày && feed≥8 event`; chưa đủ → **insufficient-data state** ("DMA cần thêm một chút hành trình nữa…"). KHÔNG gọi AI, không chấm điểm/chẩn đoán/so sánh. |

Mỗi lượt: typecheck sạch + `get_diff` sạch (chỉ đúng file/vùng) + deploy production Cloudflare. **Auto-publish** (thuần frontend, không đụng DB/auth/playback). **Nghiệm thu thật:** 16 ảnh (8 trên `/kid` + 8 trên `/parent/kid`, child "An") — Timeline gộp đúng, sort đúng, 3 câu xoay hiện, badge đồng bộ, thẻ AI hiện insufficient-data.

---

## 2. KIẾN TRÚC CHỐT (Option A — frontend merge)

```
get_kid_album_service(token)  [RPC secdef qua kid_gate]
        │  1 call → 5 mảng THẬT
        ▼  journey · creations · moments · skills · badges
kidJourneyModel.ts  buildJourneyFeed()  [C1]
        │  gộp + sort desc + seedsFor + storyFor (template từ field thật)
        ▼
JourneyEventViewModel[]
        ▼
Kid Timeline "Hành trình của bé" (scrapbook + filter) [C2]  +  thẻ AI Growth Review [C3]
```

**Vì sao Option A:** demo cảm xúc ngay bằng dữ liệu thật, **0 migration, 0 rủi ro, không đụng `get_child_journal`/RLS/RPC**. Khi taxonomy seeds chốt + cần PH/Radar dùng chung, mới nâng logic gộp lên RPC (V65+) rồi cân nhắc canonical spine.

`JourneyEventViewModel` fields: `id · eventType(artifact|moment|session|badge) · category(tac_pham|am_nhac|lop_hoc|cot_moc) · title · storyText · occurredAt · sourceLabel · displayKind · seeds[] · media(image|audio|null) · artifact · reactionEmoji`.

---

## 3. HAI RÀO TRUNG THỰC (giữ đúng — DMA-KID-MEDIA-001 + linh hồn "không bịa")

1. `kid_creations.kind="drawing"` = **vẽ tay HOẶC tô màu** (schema không phân biệt) → Timeline + album dùng **nhãn chung "Tranh"**. KHÔNG tách "Tô màu" tới khi có Coloring schema (backlog).
2. Nguồn moment **chưa có taxonomy thật** → **"Khoảnh khắc ở lớp"** chung ở CẢ Timeline LẪN album (đã giết mock Workshop/Sân khấu/Lớp-học ở C2.1). KHÔNG bịa nhãn nguồn tới khi có moment-origin taxonomy (backlog).
3. **AI Review:** chỉ sinh từ seeds/events đếm được; chưa đủ 3 tháng → insufficient-data, KHÔNG bịa review; nhãn "AI hỗ trợ quan sát"; không gọi AI thật.
4. **storyText tranh:** 3 câu trung tính, **không thêm thông tin mới** (không suy chủ đề/màu/cảm xúc/kỹ thuật). Bỏ "Hôm nay" vì entry cũ thì sai sự thật (ngày đã hiện trên thẻ).

---

## 4. AUDIT LIVE ĐẦU PHIÊN (D1 — cụm Journey)

- **`child_journey` = xương sống JourneyEvent đã có sẵn** (thép chờ #1): cột `id·child_id·source·entry_type·ref_id·lesson_version_id·program_id·occurred_at·created_at`. Thiếu tầng trình bày (title/story/seeds/visibility/ai_*). **Data:** 14 entry, tất cả `source='demen'`, `entry_type` = session(13)+badge(1). **Chưa chứa** creations/moments.
- **`get_kid_album_service(token)`** đã trả **5 mảng thật trong 1 call**: `journey`(session/badge) · `creations`(kid_creations, đã kèm `signed_url`) · `moments`(learning_moments approved + `my_reaction`) · `skills`(child_skills) · `badges`(child_badges confirmed).
- **Hai đường đọc journey TÁCH RỜI:** PH → `get_child_journal(child_id)` → `child_journey`; Kid → `get_kid_album_service` → 5 mảng. Creations/moments **không** nằm trong `child_journey`.
- **kid_creations:** 6 drawing + 2 recording. **learning_moments:** 8 approved + 3 draft. **child_skills** thật: Cảm nhịp/Cảm thụ nhịp điệu/Hát theo/Lắng nghe/Vận động theo nhạc.
- **DB tổng (mang từ v63, CHƯA đếm lại live):** 63 bảng · 105 secdef · 155 policy · mig 001→104 · Edge 14 · cron 1 · 3 zone Bunny. V64 = **0 thay đổi DB**.

---

## 5. RULES/MAP MỚI CẦN NỐI (nguyên văn — splice khi có bản sống D195/v0.57)

**D196 MỚI [kid · Journey feed = gộp frontend read-time, 0 DB]:** "Hành trình của bé" build bằng thư viện thuần TS `src/lib/kidJourneyModel.ts` — `buildJourneyFeed(album)` gộp 5 mảng của `get_kid_album_service` (journey/creations/moments/badges; skills dùng suy seed) thành `JourneyEventViewModel[]` sorted desc theo `occurredAt`, KHÔNG migration, KHÔNG đụng `get_child_journal`. Badge trùng: bỏ `journey` entry_type='badge', lấy từ mảng `badges[]` cho đủ title. `storyText` = **template từ field thật**, KHÔNG suy đoán (không "Hôm nay" trên entry cũ; tranh không caption → xoay 3 câu trung tính deterministic theo `creation_id`). Seeds suy từ `kind` (drawing→Sáng tạo/Đường nét/Sắc màu · recording→Giọng hát/Tự tin) và tên chương trình/buổi học (regex nhạc/vẽ/hát/vận động). Nâng lên RPC/canonical spine để lâu dài (PH+Radar dùng chung) là việc V65+.

**D197 MỚI [kid · AI Growth Review = placeholder an toàn, insufficient-data-first]:** Thẻ "Nhìn lại hành trình" ở đầu Timeline: nhãn cứng **"AI hỗ trợ quan sát"**, **KHÔNG gọi AI thật**. `reviewReady = span(feed) ≥ 90 ngày && feed.length ≥ 8`. Chưa đủ → **insufficient-data state** ("DMA cần thêm một chút hành trình nữa để quan sát rõ hơn các hạt giống nghệ thuật của con."). Đủ → chỉ **liệt kê tần suất top-seed đếm được** + disclaimer "không phải đánh giá năng lực" — TUYỆT ĐỐI không chẩn đoán/chấm điểm/so sánh/kết luận năng khiếu. Copy về trẻ chỉ deploy sau khi Jean duyệt.

**Named rule — DMA-KID-JOURNEY-001 [Journey = art journey]:** Cổng Kid trình bày sự lớn lên của trẻ như một **hành trình nghệ thuật có cảm xúc**, không phải game/file/gallery rời. Mỗi artifact/moment đủ điều kiện thành Journey Event có story + nguồn + thời gian + hạt giống.

**Named rule — DMA-KID-JOURNEY-002 [Artifact là vật thể, Journey Event là câu chuyện]:** UI không chỉ hiện trẻ tạo GÌ, mà cả VÌ SAO khoảnh khắc đó là một phần hành trình — nhưng chỉ bằng câu chuyện dựng từ dữ liệu thật, không bịa.

**Named rule — DMA-KID-JOURNEY-003 [scrapbook, không phải activity log/social feed]:** Timeline phải cho cảm giác cuốn sổ ký ức nghệ thuật ấm áp, không phải productivity log hay mạng xã hội.

**Named rule — DMA-KID-AI-REVIEW-002 [chỉ từ data thật / insufficient-data]:** AI Growth Review chỉ sinh từ dữ liệu journey thật; thiếu dữ liệu thì nói rõ "chưa đủ hành trình", không bịa kết luận.

**Named rule — DMA-KID-AI-REVIEW-003 [milestone nhẹ + nhãn AI + PH kiểm soát]:** AI Review xuất hiện như một mốc dừng chân nhẹ trên timeline, ghi rõ là quan sát-hỗ-trợ-bởi-AI; (tương lai) có control ẩn/hiện cho PH.

**SYSTEM_MAP bump v0.57 → v0.58:** thêm `src/lib/kidJourneyModel.ts` (tầng gộp frontend) + mô tả Kid Timeline scrapbook + thẻ AI Growth Review placeholder trong `kid.tsx`. KHÔNG đổi bảng/route/RPC.

**TREO (chưa canonize — chưa build):** DMA-KID-AI-REVIEW-001 (ngôn ngữ non-diagnostic đầy đủ cho AI THẬT) · DMA-KID-ART-RADAR-001/002/003 (Radar) — ghi khi build V66/V67.

---

## 6. BACKLOG / ON THE HORIZON

1. 🟠 **C3 → AI Growth Review THẬT** (V66): sau khi có policy/consent + copy Jean duyệt. Hiện chỉ placeholder.
2. 🟠 **Nâng gộp lên RPC** `get_kid_journey_service` (V65) → PH + Radar dùng chung 1 taxonomy seed.
3. 🟠 **Parent Art Growth Radar** (V67): tính từ Journey Events + Growth Seeds; 30/90/180/365 ngày; insufficient-data state.
4. 🟠 **Canonical spine** (sau): ghi creations/moments vào `child_journey` (migration + đụng `get_child_journal`) — đích cuối, làm sau khi taxonomy chốt.
5. 🔴 **Coloring JSON schema** (backlog cũ): phân biệt drawing vs coloring → mở rào #1.
6. 🔴 **Moment media source taxonomy** (backlog cũ): bỏ nhãn generic → mở rào #2.
7. 🟡 Companion chính thức thay 🐱 · official SVG coloring templates.
8. 🟡 (mang từ v61/v62) backup commits GitHub · content Kid · nghiệm thu `/auth`.

---

## 7. TRẠNG THÁI SỔ SÁCH (đọc kỹ)

- **HANDOFF_v64** = file này (xuất phiên này).
- **`DMA_RULES.md` / `DMA_SYSTEM_MAP.md`:** **CHƯA nối V64** — vì bản trong thư viện project đang STALE (D173/v0.50). Cần Jean đưa **bản SỐNG D195/v0.57** (bản v63 đã xuất, Jean giữ local) → em splice §5 vào rồi xuất 2 file hoàn chỉnh (D195→+D196/D197+named; v0.57→v0.58). **Plan B** (Jean đưa file thật) ưu tiên; Plan A (reconstruct từ chuỗi handoff v56–v63, có nhãn) chỉ khi Jean chọn.

---

## 8. VIỆC KẾ

1. **Chốt sổ RULES/MAP** — Jean đưa bản sống D195/v0.57 → em nối §5, xuất 2 file.
2. **C3 thật hoặc V65 (gộp lên RPC)** hoặc **Coloring schema** — Jean chọn hướng sprint sau.

*Handoff v64 — 2026-07-08 11:23 GMT+7. Nguồn: audit live cụm Journey (D1) + get_diff từng lượt + deploy production + nghiệm thu 16 ảnh (An trên /kid và /parent/kid). DB tổng mang từ v63 (chưa đếm lại live). Cập nhật "tới đâu ghi tới đó" (KỶ LUẬT VÀNG).*
