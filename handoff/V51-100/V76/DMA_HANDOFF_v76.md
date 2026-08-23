# DMA_HANDOFF_v76.md
**Sprint:** Parent Journal Memory Detail Polish — "Bấm vào chiếc lá, mở ra một mốc ký ức"
**Ngày:** 2026-07-09 13:34 GMT+7 (Asia/Ho_Chi_Minh)
**Vai trò:** ChatGPT = CTO Advisor · Claude = PM + Prompt Operator + Builder · Lovable = build
**Trạng thái:** ✅ ĐÓNG SỔ — deployed production
**File duy nhất bị đụng:** `src/routes/_authenticated/parent.journal.tsx`

---

## 0. TL;DR

V75 nén trục thành compact spine ("trục là nhân vật chính"). V76 làm bước tiếp: khi PH **bấm vào một leaf ký ức**, detail phải giàu cảm xúc hơn — cảm giác "mốc ký ức nghệ thuật", không chỉ "xem ảnh lớn". Đây là **sprint polish TRẢI NGHIỆM detail, KHÔNG phải data-architecture.**

Phát hiện lõi: `ParentJournalLightbox` V71 **đã pure + consent-safe** (nhận `signedUrl` đã ký, KHÔNG fetch, KHÔNG biết `media_id`) và đã có media object-contain + title + date + caption + box Gợi ý trò chuyện. Nên V76 **nâng lightbox tại chỗ** (KHÔNG tạo dialog mới) + thêm 1 lớp cảm xúc mỏng.

Jean chốt **A/A/A/A**. Frontend-only, 1 file, 0 DB/RPC/Edge/Auth/RLS/AI, 0 re-sign, **gate mở dialog KHÔNG đổi** (chỉ mở khi media ok), share giữ ở leaf, summary 6/2/3 bất biến, compact spine V75 nguyên.

Deployed: `https://demenart.lovable.app` · deployment `63586147` · commit cuối `634802eb`.

---

## 1. Commits (agent auto-app, deploy 1 lần cuối sau khi Jean review preview)

| Commit | SHA | Nội dung |
|---|---|---|
| C1 | `b124e04c` | **Nâng `ParentJournalLightbox` tại chỗ.** Thêm props optional `emoji`/`accent`(rose\|sky\|amber)/`warmLine`/`taggedCount`. Footer mới: chip loại màu theo accent + emoji · privacy badge (reuse `MomentPrivacyBadge`) khi `type==="moment"` · caption · `warmLine` italic · box Gợi ý trò chuyện (giữ) · nút "Đóng" (`DialogClose`). `DialogTitle`→`sr-only` (chip mang nhãn hiển thị, giữ a11y). Mobile: `p-3 sm:p-4`, ảnh `max-h-[55vh] sm:max-h-[60vh]`, footer `px-4 sm:px-5`. Import thêm `DialogClose`. Props optional → C1 typecheck sạch một mình. |
| C2 | `792e721a` | **Wire props từ 2 compact leaf.** Moment lightbox: `emoji="📸"` `accent="sky"` `taggedCount={moment.tagged_count}` + warmLine "…nhìn lại khoảnh khắc này ở lớp." + prompt thêm "trong buổi hôm đó". Drawing lightbox: `emoji="🎨"` `accent="rose"` + warmLine "…nhìn lại tác phẩm và nghe con kể về nó.". Thuần prop, 0 fetch, 0 re-sign. |
| C3 | `634802eb` | **Recording + session micro-copy.** Recording: giữ `<audio controls preload="none">` inline + thêm 1 `<p>` italic teal "Ba mẹ có thể nghe lại cùng con và hỏi con thích đoạn nào nhất." (chỉ khi `ok && isRecording`). Session `TimelineSessionLeaf`: thêm kicker "MỐC HÀNH TRÌNH" (uppercase amber-500/80) trên tiêu đề; GIỮ non-clickable + curly-quotes teacher_note. |

Mỗi commit: `send_message` → `get_diff` (verify sạch đúng 1 file, KHÔNG đụng `routeTree.gen.ts`) → typecheck pass. Deploy 1 lần cuối sau C3 (sau khi Jean review 8 ảnh preview). Tổng ~5.3 credit.

---

## 2. Kiến trúc chốt — nâng engine trình bày, KHÔNG dựng surface mới (D208)

**Chọn A (nâng `ParentJournalLightbox`) thay vì tạo `ParentMemoryDetailDialog`:**
- Lightbox V71 đã **pure presentational + consent-safe**: nhận `signedUrl` đã ký, KHÔNG gọi network, KHÔNG biết `media_id`. Cả 2 compact leaf (moment + drawing) đã dùng chung.
- Tạo dialog mới = **nhân đôi bề mặt consent + rủi ro** → thừa. Nối tiếp bài học D207/D203: thêm cảm xúc = **thêm lớp trình bày quanh engine**, KHÔNG chọc engine, KHÔNG dựng surface song song.

**Detail giàu cảm xúc = props thuần từ data leaf sẵn có** (`caption`, `created_at`, `moment.tagged_count`, `creation.kind`) → 0 re-sign, 0 fetch trong dialog, 0 media_id thô. Privacy badge dialog reuse `MomentPrivacyBadge` (thuần) — render khi `type==="moment"`, khớp hành vi leaf. `MomentPrivacyBadge` khai báo `function` (hoisted) → gọi được trong lightbox dù định nghĩa sau (an toàn TDZ).

**Gate mở dialog KHÔNG ĐỔI (giữ trọn D203/D204):**
- Moment mở CHỈ khi `canOpen (=!!signedUrl)` (từ `MomentImage`→`onReady` nhánh ok).
- Creation mở CHỈ khi `status==="ok" && kind==="drawing"`.
- consent-blocked / recording / denied / loading → **KHÔNG mở**.

**Recording:** KHÔNG có dialog (giữ audio inline), chỉ thêm 1 câu khích lệ. **Share:** GIỮ ở leaf (1A V75 — tránh popover-trong-dialog focus/z-index). **Session:** non-clickable, chỉ kicker chữ.

---

## 3. Quyết định thiết kế (Jean chốt A/A/A/A)

- **Q1=A** — Nâng `ParentJournalLightbox` tại chỗ (chip loại + warmLine + privacy moment + nút Đóng + mobile). KHÔNG dialog mới, KHÔNG nhân đôi surface consent.
- **Q2=A** — Recording giữ audio inline, chỉ polish copy. KHÔNG recording dialog, KHÔNG player mới.
- **Q3=A** — Share chỉ ở leaf. KHÔNG vào dialog.
- **Q4=A** — Session non-clickable + kicker "MỐC HÀNH TRÌNH". KHÔNG RPC/data.

---

## 4. Nghiệm thu — PASS bằng 8 ảnh (PH Hùng, con An)

- **Tranh (drawing):** dialog chip 🎨 "Tác phẩm của con" (hồng) + warmLine italic + box Gợi ý trò chuyện + nút Đóng + ảnh object-contain không crop.
- **Moment nhóm 29/6:** dialog chip 📸 "Khoảnh khắc ở lớp" (xanh) + privacy **"Ảnh chung nhiều bé"** + caption "Bé chăm chú xem" + warmLine + prompt + ảnh lớn.
- **Recording:** 🎵 "Âm thanh của con" + audio chạy (0:01/0:10) + câu italic teal khích lệ.
- **Session:** "Tiếng mưa rơi"/"Buổi học" có kicker **"MỐC HÀNH TRÌNH"** + "Cô nhận xét" nguyên vẹn (curly-quotes).
- **Privacy leaf:** nhóm 29/6·28/6 → "Ảnh chung nhiều bé"; 1-bé 26/6 → "🔒 Riêng gia đình".
- **Share:** ở leaf + popover consent-gate sống ("một số bé trong ảnh chưa được đồng ý" + Tạo link + hết hạn 24h).
- **Compact spine V75** giữ (thumbnail 96px + "Xem", nhiều leaf/màn). `/parent` summary 6/2/3 không đụng.

**An live-verified:** `group_moment_in_class` **BẬT** (khác V75) → moment nhóm mở được → **soi được badge "Ảnh chung nhiều bé" trong dialog** = nghiệm thu bù cho backlog V75.

**Login test (An):** `ph.hung.kidshouse@demo.demenart.com` · mật khẩu `Test@123`.

---

## 5. Local components trong `parent.journal.tsx` (sau V76)

**Sửa V76:**
- `ParentJournalLightbox` — thêm props `emoji`/`accent`/`warmLine`/`taggedCount`; footer chip + privacy + warmLine + nút Đóng; DialogTitle sr-only; mobile padding.
- `CompactMomentLeaf` / `CompactCreationLeaf` — CHỈ đổi props truyền vào lightbox (C2) + thêm 1 câu recording (C3). Logic ký/gate/overlay KHÔNG đổi.
- `TimelineSessionLeaf` — thêm kicker "MỐC HÀNH TRÌNH".

**Giữ byte-exact (KHÔNG đụng):** `MomentImage`, `MomentPrivacyBadge`, `ShareMomentButton`, `ConsentWaitingHint`, `entryVisual`, adapter V74 (`buildParentTimeline`/`groupTimelineByMonth`/`timelineNode`/`formatTimelineMonthLabel`/`formatTimelineDayLabel`/`hcmYmd`). Sidebar (Kỹ năng + Huy hiệu) + summary logic KHÔNG đụng.

---

## 6. Backlog (chưa làm ở V76)

- **Lưu repo/backup** `parent.journal.tsx` V76 (Jean thủ công).
- **Multi-media moment gallery** — detail hiện 1 ảnh đại diện; khi backend trả `galleryItems[]`/`coverMediaId`/`mediaCount` (1-n media/moment) mới dựng gallery trong dialog. V76 KHÔNG fake.
- **Recording detail dialog** (nếu sau muốn) — chờ nhu cầu; hiện audio inline đủ.
- Enrichment `child_journey` (creations/moments chảy vào spine) · Phương án B RPC canonical `get_child_journey_service` · rename `kidJourneyModel.ts` · Parent Dashboard đầy đủ/Radar/AI Review THẬT · Coloring JSON schema · Moment media taxonomy — như backlog cũ.
- Cập nhật GitHub backup commits (migrations cũ) + living `DMA_RULES.md` (endpoint **D208**) + `DMA_SYSTEM_MAP.md` (**v0.69**): Jean thực hiện thủ công (đã kèm bản replacement đầy đủ dưới).

---

## 7. Guard đã giữ trọn (V76)

1 file · 0 DB/RPC/Edge/Auth/RLS/migration · 0 AI thật · 0 npm · 0 import mồ côi · không đụng `parent.index.tsx`/`kidJourneyModel.ts`/`routeTree.gen.ts`/adapter V74/sidebar/summary · **0 re-sign** · **0 fetch trong dialog** · **0 media_id thô vào dialog** · 0 lift signed_url lên adapter · **gate mở dialog KHÔNG đổi** (chỉ mở khi media ok) · không phá `MomentImage`/`ConsentWaitingHint`/`ShareMomentButton` · share giữ ở leaf (1A) · summary 6/2/3 bất biến · không phá Lightbox V71 / consent V72 (D204) / dedup V73 / spine V74 / compact V75 · không hardcode data giả · không fake gallery/multi-image · session non-clickable.

**Endpoint sau V76:** RULES **D208** · SYSTEM_MAP **v0.69** · Handoff **v76**.
