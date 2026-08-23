# 📦 DMA_HANDOFF_v111G.md — FMN PHASE 2 EXPERIENCE REGRESSION CLOSEOUT (16/07/2026 · ĐÓNG · PHASE 2 CLOSED WITH MINOR FINDINGS)

> **Phiên trước:** V111F MOTION & SENSORY QA (đóng · SENSORY PASS).
> Boot chuẩn phiên sau: HANDOFF này → RULES tới **D307** → SYSTEM_MAP **v1.12** → **audit live DB**.
> Kỳ vọng live: **87 / 188 / 164 / 1** · migrations **100** · routes **52** · edge **16** · journey **37 = 36 non-family + 1 family** · preserve **5 = 1 active / 3 reversed / 1 orphaned** · threads/messages **2 / 3** · cards **16 = 15 active + 1 archived**.
> ⚠️ journey 37 / preserve 5 là human live-acceptance V111F — **KHÔNG drift**. non-family = **36** (D110 byte-locked), KHÔNG phải 37.

---

## 1. MỤC TIÊU V111G

Regression sprint thuần — **KHÔNG feature, KHÔNG polish, KHÔNG backend, KHÔNG migration, KHÔNG route, KHÔNG scope creep**. Nhiệm vụ duy nhất: chứng minh Phase 2 (V111A→V111F) ổn định, không hồi quy, đủ điều kiện đóng chính thức. Evidence-first, auto-run. Nếu không tìm thấy regression thì không bịa ra.

---

## 2. D1/D10 — LIVE BASELINE + INVENTORY (đo trực tiếp, không tin handoff)

| Trục | Live | Canonical V111F | Verdict |
|---|---|---|---|
| tables / secdef / policies / cron | 87 / 188 / 164 / 1 | 87 / 188 / 164 / 1 | ✅ |
| migrations | 100 | 100 | ✅ |
| edge (ACTIVE) | 16 | 16 | ✅ |
| routes (convention) | 52 | 52 | ✅ (§8 F-G2) |
| journey total / non-family / family | 37 / 36 / 1 | 37 · non-family khoá 36 | ✅ (§8 F-G1) |
| preserve = active/reversed/orphaned | 5 = 1/3/1 | 5 = 1/3/1 | ✅ |
| cards = active/archived | 16 = 15/1 | 16 = 15/1 | ✅ |
| threads / messages | 2 / 3 | 2/3 | ✅ |

Edge 16: get_signed_media_url · upload_media · resolve_share_link · invite_master/staff/parent · upload_notification_sound · delete_session_media · school_media_admin · capture_session_moment/media · purge_trash · kid_gate · upload_kid_game_sound · accept_parent/family_invitation.

**0 drift kết cấu.**

---

## 3. GOVERNANCE REPLAY (D293/D305 · LIVE JWT IMPERSONATION)

Actor resolve LIVE (space "Gia đình Hùng" `4806ff8d`) — không tin ID nhớ:
- Hùng guardian: profile `d1000000-…-051` · auth `eb94304a`
- Bà Ngoại Test non-guardian: profile `2965d4a0` · auth `d3d062f8`
- Outsider (admin non-member): profile `e86e45d1` · auth `446de75d`

Card test `5125a540` "Ảnh 2 có bé An" (creator = Bà ngoại):

| Actor | can_moderate | is_guardian | effective_access | Card Edit | Card Archive |
|---|---|---|---|---|---|
| Hùng (guardian, không creator) | true | true | true | ❌ | ✅ (guardian) |
| Bà ngoại (creator, non-guardian) | false | false | true | ✅ (own) | ✅ (own) |
| Outsider (admin non-member) | — | — | false | generic deny | generic deny |

- Engagement live: 3 lời (2 Hùng mine=true voice+text → Sửa/Rút lại; 1 Bà ngoại mine=false → chỉ Ẩn). ack count=2 names=[Bà ngoại, Ba].
- Generic deny boundary: outsider mở card THẬT + card KHÔNG tồn tại → **cả hai `not_found_or_not_authorized`, identical=true** (0 enumeration).
- UI mirror (`memoryRoomShared.tsx`): `isCreator`/`canEdit=isCreator`/`canArchive=native&&(isCreator||isGuardian)`/`canModerate` — 2 biến riêng, KHÔNG gộp canManage.

**PASS. 0 predicate thay đổi, 0 button leak, 0 authority regression.**

---

## 4. CODE AUDIT (read_file @HEAD · D1-compliant, 0 mutation)

Files FMN: `src/features/family/` = 9 file, **0 stale file**.

- **FamilyMemoryStream.tsx** — `openDetail`→navigate route (0 Dialog-detail, 0 `setDetail`); Stream card TĨNH; composition D302; chapters lọc rỗng; request stream×1+role×1+presence×1+archived×1, 0 per-card RPC.
- **memoryRoomShared.tsx** — CardDetail = `<div>`+`<h1>` (KHÔNG modal); `Dialog` chỉ secondary (edit/composer/preserve `max-w-md/sm`); governance split; motion sau success (`if(data?.ok)`→recede; `if(ok)`→settle); truth states.
- **FamilyMemoryRoom.tsx** — direct entry `get_family_card(cardId)` on mount; generic denied 1-copy; navOriginHint `__TSR_index>0` (không history.length); aux independence fail-closed; `fmn-room-enter`; request card×1+role×1+engagement×1+preserve×1.
- **familyExperienceGrammar.ts** — ICT Monday-first; truth-state classifier; presence people-not-counts; composition; actor language (không bịa tên).
- **styles.css** — 6 motion class + token + **reduced-motion hard gate** đầy đủ (animate-spin giữ).

**Dead code SAFE REMOVE: NONE. Stale modal: NONE.**

---

## 5. REPLAY VERDICTS

- Experience replay (Stream/Room/timeline/truth-state): ✅
- Governance replay (full matrix live): ✅
- Motion replay (semantic · recede≠delete · settle≠Like · reduced-motion): ✅
- Truth-state replay (no empty↔error masquerade): ✅
- Request discipline (0 duplicate, 0 N+1): ✅
- Accessibility (reduced-motion/focus/keyboard/h1/semantic feedback): ✅
- Dead code / stale modal: ✅ (nothing to remove)
- Mobile/Desktop smoke: ✅ **inherited** (V111E 8 ảnh + V111F 11 ảnh CTO production; V111G zero-delta code) — fresh in-session browser smoke KHÔNG khả dụng, ghi trung thực (tiền lệ V111C `NOT VISUALLY REACHABLE SAFELY`).
- Performance (0 dependency mới, 0 Framer Motion, 0 duplicate signing/RPC): ✅
- Inventory + canonical consistency: ✅

---

## 6. FINDINGS (cấp tài liệu, KHÔNG phải system regression)

- **F-G1 (spec journey triple):** Spec V111G ghi "journey 37/37/1"; live + canonical thật = **37/36/1** (non-family=36, D110 byte-locked; family 0→1 do preserve V111F đẩy total 36→37). Spec parenthetical tự mâu thuẫn. Hệ thống + docs (v111F) ĐÚNG. **Không sửa DB.**
- **F-G2 (route convention):** raw `fullPaths` = 57 (5 layout-parent + 4 index trailing-slash); convention "52" nhất quán mọi handoff, pre-existing. `/family/memory/$cardId` đúng 1 route.
- **Nợ deferred (backend, ngoài scope):** S-level creator/subject dedup-theo-`profile_id` (D306 §22 Phương án A) vẫn treo.

---

## 7. INVARIANTS SAU V111G

87 / 188 / 164 / 1 · migrations **100** · routes **52** · edge **16** · journey **37 = 36 non-family + 1 family** · preserve **5 = 1 active / 3 reversed / 1 orphaned** · threads/messages **2 / 3** · cards **16** (15 active / 1 archived).

**Backend: NONE. Route: NONE (52). Migration: NONE (100). Edge: NONE (16). Dependency: NONE. Files changed: NONE. Deploy: NONE.**

---

## 8. CANONICAL CLOSEOUT

- **RULES:** D306 → **D307** (marker đóng Phase 2 — xem RULES).
- **SYSTEM_MAP:** v1.11 → **v1.12** (mục Phase 2 CLOSED; inventory không đổi).
- **HANDOFF:** **v111G** (file này).

---

## 9. FINAL VERDICT

**✅ PHASE 2 CLOSED WITH MINOR FINDINGS.**

Mọi replay PASS, 0 system regression. "Minor findings" = 2 quan sát cấp tài liệu (F-G1 journey spec-wording, F-G2 route convention) + 1 nợ deferred S-level (creator/subject dedup, cần backend). Cả ba không chặn đóng Phase 2.

---

## 10. ON THE HORIZON (Phase 3+ · ngoài regression sprint)

- (nếu mở backend) creator/subject dedup-theo-`profile_id` — cần `profile_id` trong `people` payload.
- Media Compatibility Pipeline (MOV/HEVC/WebM normalization).
- Nightly sweep orphaned pending attachments.
- Kid Portal V2 (`/kid` PIN-based) — namespace reserved.
- Pending repo backup: commit backup packages to GitHub (Jean manual task).

---

*Endpoint: RULES **D307** · SYSTEM_MAP **v1.12** · HANDOFF **v111G**. Kỷ luật vàng: audit live trước khi tin số; journey 37=36+1 (non-family khoá 36); resolve actor live trước QA; không có browser thì kế thừa live-acceptance + zero-delta, KHÔNG bịa ảnh; regression sprint không sinh feature.*
