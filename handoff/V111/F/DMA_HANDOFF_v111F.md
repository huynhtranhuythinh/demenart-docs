# 📦 DMA_HANDOFF_v111F.md — FMN MOTION & SENSORY QA (16/07/2026 · ĐÓNG · SENSORY PASS)

> **Phiên trước:** V111E MEMORY ROOM (đóng · EXPERIENCE PASS).
> Boot chuẩn phiên sau: HANDOFF này → RULES tới **D306** → SYSTEM_MAP **v1.11** → **audit live DB**.
> Kỳ vọng live: **87 / 188 / 164 / 1** · migrations **100** · routes **52** · edge **16** · journey **37** · preserve **5 = 1 active / 3 reversed / 1 orphaned** · threads/messages **2 / 3** · cards **16 = 15 active + 1 archived**.
> ⚠️ **journey 37 và preserve 5 KHÔNG phải drift** — là kết quả human live-acceptance action (xem §7). Nếu phiên sau thấy 37/5 thì ĐÚNG; đừng "sửa" về 36/4.

---

## 1. MỤC TIÊU V111F

Motion & Sensory QA — làm chuyển động **mang nghĩa semantic**, không trang trí. Người dùng cảm được: một ký ức xuất hiện · đi gần vào ký ức · giữ lại có chủ đích · cất đi · trả về · rời đi — mà KHÔNG cảm thấy gamification/social-feedback/noise/motion-sickness/demo-reel. Không thêm feature, không social, không backend.

---

## 2. D1/D2 — BASELINE + AUDIT

**D1:** live khớp v111E tuyệt đối (87/188/164/1 · mig 100 · routes 52 · edge 16 · journey 36 · preserve 4=0/3/1 · threads 2/3 · cards 16=15/1). Canonical D305/v1.10/v111E. 0 drift.

**D2 Motion audit — nền cực sạch:** 0 FMN motion token · 0 FMN keyframe · 0 `prefers-reduced-motion` · **không có Framer Motion** (deps) · motion library duy nhất `tw-animate-css` (shadcn) · **0 forbidden motion** tồn tại · Detail Dialog zoom đã xoá từ V111E · Stream card tĩnh. Motion hiện có đều functional (animate-spin loading, transition-[width] audio progress, shadcn dialog animate-in trên secondary surfaces) → GIỮ. Vấn đề = **thêm motion semantic có chủ đích + gate reduced-motion đang thiếu**, không phải gỡ motion thừa.

---

## 3. MOTION LAYER (frontend-only)

**Token (styles.css FMN):** `--fmn-motion-micro:140ms · --fmn-motion-nav:260ms · --fmn-motion-state:320ms · --fmn-ease-enter · --fmn-ease-settle`.

**5 họ semantic:**
- **M1 Appear:** `fmn-media-fade` (media opacity onLoad, không re-sign) + `fmn-appear` (contribution). Stream card GIỮ TĨNH.
- **M2 Approach:** `fmn-room-enter` (Stream→Room fade+translateY 260ms, Option B thuần CSS).
- **M3 Settle:** `fmn-settle` (preserve chip scale 140ms).
- **M4 Recede:** `fmn-recede` (archive opacity+max-height collapse 320ms SAU success). Archive từ Room → recede → navigate origin.
- **M5 Return:** `fmn-return` (restore quiet).

**Reduced-motion HARD GATE:** `@media (prefers-reduced-motion: reduce)` tắt 6 animation, media visible tức thời, recede→ẩn tức thời, scroll-behavior auto; GIỮ animate-spin + text/toast feedback; functionality/focus nguyên.

---

## 4. FILES

- `~styles.css` — V111F FMN MOTION LAYER (token + 6 class + reduced-motion gate).
- `~FamilyMemoryRoom.tsx` — `<article className="fmn-room-enter" tabIndex={-1}>`.
- `~memoryRoomShared.tsx` — MediaTile image fade (`fmn-media-fade`+data-loaded) · CardDetail creator line (`memoryActorLine`) + archive recede wrapper (receding sau `data?.ok`, delay 320/0ms theo reduced-motion) · PreserveControl settle (justSettled 200ms) · ContributionItem `fmn-appear`.
- `FamilyMemoryStream.tsx` — **KHÔNG đổi** (Stream card tĩnh, M1 locked).
- `~routeTree.gen.ts` / `~package.json` — toolchain, không sửa tay.

typecheck `tsgo --noEmit` PASS · 1 deploy production.

---

## 5. HARD GATES ĐÃ VERIFY

- **Motion sau mutation success:** archive `setReceding(true)` bên trong `if(data?.ok)`; fail → card đứng nguyên. (STOP #5/#6 pass)
- **Archive recede ≠ Delete:** opacity+collapse, không fly/fall/trash/đỏ/xoay. Room archive → navigate origin (`navOriginHint`, else `/family`; không `history.length`).
- **Preserve settle ≠ Like:** scale nhỏ, không burst/flash/counter.
- **Reduced-motion:** đầy đủ, functionality nguyên, animate-spin giữ.
- **Route motion ≠ access/data truth:** Option B CSS, không mount đôi, không duplicate request.
- **Request discipline (ảnh Network):** Stream get_family_memory_stream×1 + presence×1; preserve dialog chỉ 1 log_family_event, 0 duplicate fetch; Room card×1+role×1+engagement×1+preserve×1+signed-media on-demand.
- **Governance D293:** 0 predicate thay đổi. Re-verify backend (impersonation): Hùng can_moderate=true, Bà ngoại can_moderate=false — identical v111E.

---

## 6. SENSORY ACCEPTANCE — ✅ PASS (16/07, CTO 11 ảnh, production)

| Mục | Bằng chứng |
|---|---|
| Stream → Room (M2) | ảnh 1→2, fade+trượt, không modal-zoom/scrim |
| Media fade (M1) | ảnh 2,4,7 mượt |
| Creator line (§9) | ảnh 2 "Bà ngoại đã thêm ký ức này" hiện — S-level finding §8 |
| Archive recede→origin (M4) | ảnh 3→4, confirm→về /parent/family, "Đã lưu trữ" +1 |
| Archive list + Restore (M5) | ảnh 5,6,7, "Đã khôi phục"→card về Stream |
| Mixed Room + video + voices + governance | ảnh 8, video 0:08 không autoplay, Ba×2+Bà ngoại, đúng nút |
| **Preserve settle + live preserve THẬT** | ảnh 10, dialog An → Giữ → active preserve tạo (**PASS, không còn PENDING**) |
| Mobile 400px Room + Stream | ảnh 9,11 không overflow |
| Request discipline | ảnh 10,11, 0 duplicate fetch |

---

## 7. LIVE-ACCEPTANCE LIFECYCLE (human action hợp lệ — KHÔNG DRIFT)

Trong buổi nghiệm thu CTO thực hiện thao tác thật qua UI:
- **Archive → Restore** (Kỷ niệm 03): cards về đúng baseline **15 active / 1 archived**, Kỷ niệm 03 = `active`.
- **Preserve** card `5125a540` (Ảnh 2 có bé An) → bé **Nguyễn Hoàng An** (`d1000000-…-041`), basis **`guardian_steward`**, actor **Hùng guardian** (`…051`), có **journey_entry** (`b424b5c3-…`).

**Hệ quả (ghi rõ, KHÔNG treat drift, §18/§36):**
- preserve **4 → 5** (0/3/1 → **1 active** / 3 reversed / 1 orphaned)
- journey **36 → 37**
- **orphaned vẫn 1** — KHÔNG bị dọn.

---

## 8. S-LEVEL FINDING — CREATOR LINE (PHƯƠNG ÁN A, KHÔNG CHẶN)

Room card "Kỷ niệm 03" hiện cả "Bà ngoại đã thêm ký ức này" (creator, display-name projected) và "Kỷ niệm của: Bà Ngoại Test" (subject, full_name raw). Cùng người, hai dạng tên ⇒ dedup so-string không bắt. **CTO chốt PHƯƠNG ÁN A — giữ nguyên:** creator truth vs subject/people truth là hai semantics khác nhau; payload không có identity key đủ chắc để dedup theo người; KHÔNG heuristic frontend; KHÔNG bỏ subject truth; KHÔNG mở backend trong V111F. **S-level, không chặn PASS.** Dedup-theo-danh-tính (cần `profile_id` trong `people`) là việc backend — xét V111G+.

---

## 9. INVARIANTS SAU V111F

87 / **188** / 164 / 1 · migrations **100** · routes **52** · edge **16** · journey **37** · preserve **5 = 1 active / 3 reversed / 1 orphaned** · threads/messages **2 / 3** · cards **16** (15 active / 1 archived).

**Backend: NONE. Route: NONE (52). Migration: NONE (100). Edge: NONE (16). Dependency: NONE.**

---

## 10. CANONICAL CLOSEOUT

- **RULES:** D305 → **D306** (motion semantic · reduced-motion mandatory · archive recede ≠ delete · preserve settle ≠ like · route motion ≠ access truth · motion không duplicate request · creator line phương án A · live preserve/journey không drift).
- **SYSTEM_MAP:** v1.10 → **v1.11** (section V111F Motion).
- **HANDOFF:** **v111F** (file này).

---

## 11. DEFERRED → V111G (Experience Regression Closeout)

- full Phase 2 regression suite
- governance replay (đầy đủ actor matrix)
- dead-code / stale-modal audit
- mobile/desktop final smoke
- journey/preserve invariants (lưu ý baseline mới: journey 37, preserve 5=1/3/1)
- canonical inventory audit
- Phase 2 closeout
- (cân nhắc, nếu mở backend) creator/subject dedup-theo-`profile_id`

---

## 12. KHUYẾN NGHỊ BƯỚC TIẾP

V111F **technical + sensory PASS** ⇒ **V111G — Experience Regression Closeout**.

---

*Endpoint: RULES **D306** · SYSTEM_MAP **v1.11** · HANDOFF **v111F**. Kỷ luật vàng: audit live trước khi tin số; journey 37 / preserve 5 là human live action, không drift; resolve actor identity live trước QA; D284 single access truth; D293 exact; motion sau sự thật.*
