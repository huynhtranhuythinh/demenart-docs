# 📦 DMA_HANDOFF_v111E.md — FMN MEMORY ROOM (16/07/2026 · ĐÓNG · EXPERIENCE PASS)

> **Phiên trước:** V111D STREAM RHYTHM (đóng) + HOTFIX Teacher Remote (ngoài sprint).
> **⚠️ Anomaly ghi rõ:** file `DMA_HANDOFF_v111D.md` **KHÔNG có trên đĩa** khi khởi động V111E. Không chặn build vì endpoint canonical (RULES **D304** · SYSTEM_MAP **v1.09**) + live baseline khớp tuyệt đối. HANDOFF v111E này là **full replacement dựng từ canonical truth + live DB hiện tại**, **KHÔNG append từ v111D stale**.

Boot chuẩn phiên sau: HANDOFF này → RULES tới **D305** → SYSTEM_MAP **v1.10** → **audit live DB** (kỳ vọng: **87 / 188 / 164 / 1** · migrations **100** · routes **52** · edge **16** · journey **36/36/0** · preserve **4** = 0/3/1 · threads **2/3** · cards **16** = 15 active/1 archived).

---

## 1. MỤC TIÊU V111E

Thay **Memory Detail** (shadcn `Dialog` `max-w-lg max-h-[90vh]` + scrim + X, mất ký ức khi F5, Back đóng cả trang) bằng **route-backed Memory Room** `/family/memory/:cardId`: có địa chỉ, deep-link, F5, Back/Forward, direct entry. Một memory trở thành **một nơi để ở lại**, không phải một record để soi. Detail Experience redesign đã duyệt ở V111 DD4.

---

## 2. QUYẾT ĐỊNH CHỐT (CTO duyệt 2 checkpoint)

**Backend — NARROW (mig 100):** `get_family_card(p_card_id)` đã tồn tại sẵn (SECURITY DEFINER, D284 = single access truth, generic `not_found_or_not_authorized`, grant `authenticated`, trả card/media/people/provenance/story/space_id). Thiếu **đúng 1 field**: `creator_name`. Mig 100 = `CREATE OR REPLACE` thêm **một** field nullable qua canonical `family_display_name(v_space, mc.creator_profile_id)`. **0 function mới · 0 schema/index/column · 0 data mutation · 0 governance.** Engagement/preserve/role KHÔNG gộp vào — vẫn RPC độc lập.

**Route:** `src/routes/_authenticated/family_.memory.$cardId.tsx` → `/family/memory/:cardId`. Suffix `_` giữ leaf (không biến `family.tsx` thành layout). **Một** Room dùng chung `/family` + `/parent/family`; quyền do backend, không do URL. Routes **51 → 52**.

**Back UX (correction CTO):** KHÔNG dùng `history.length` làm bằng chứng in-app origin. `__TSR_index>0` → `router.history.back()`; direct/F5 → fallback `navOriginHint ∈ {/family,/parent/family}` else `/family`. **navOriginHint tuyệt đối không tham gia authorization** — chỉ UX. Non-parent không bị đẩy vào `/parent/family`.

---

## 3. MIGRATION 100 (áp một lần · D291 gate)

`v105f_v111e_get_family_card_creator_name` — ba khối D92:
- **Block 1:** `CREATE OR REPLACE get_family_card` — thêm `'creator_name', public.family_display_name(v_space, mc.creator_profile_id)`. Thân còn lại byte-for-byte (D284 `family_card_effective_access(mc.id, v_actor)` + generic `not_found_or_not_authorized` nguyên).
- **Block 2:** `REVOKE ALL … FROM PUBLIC, anon, authenticated, service_role` → `GRANT EXECUTE … TO authenticated` (khôi phục đúng grant surface trước, D15).
- **Block 3 VERIFY:** creator_name wired · D284 còn trong body · generic string còn · grant surface = `{authenticated}`. RAISE ⇒ rollback nguyên tử. **PASS ⇒ không rollback.**

**BEFORE/AFTER:** grants trước = sau = `{authenticated, postgres}` (0 leak anon/service_role). migrations 99 → **100**. def hash đổi (đã có creator_name).

**D291 PRODUCTION-CLIENT GATE (JWT impersonation, `sub`=`profiles.user_id`, đọc như UI thật):**
| Actor | Card | Kết quả |
|---|---|---|
| Hùng (guardian, `…051`/`eb94304a`) | img+vid `5125a540` | `ok:true`, `creator_name:"Bà ngoại"` (privacy-projected) |
| Bà ngoại (creator, `2965d4a0`/`d3d062f8`) | own card | `ok:true` |
| Admin (outsider, non-member) | real card | `not_found_or_not_authorized` |
| Hùng | non-existent `0000…` | `not_found_or_not_authorized` (cùng generic) |

---

## 4. FRONTEND (auto-apply qua Lovable agent · scope guard)

**Files:**
- `+src/features/family/FamilyMemoryRoom.tsx` — page shell. Back affordance "Quay lại". Tự `get_family_card(cardId)` khi mount (direct entry độc lập, KHÔNG nhận card từ Stream state). `get_family_space_role(space_id)` cho isGuardian (fail-closed). States: loading / ready / denied+error → MỘT copy generic *"Không thể mở ký ức này. / Ký ức có thể không còn khả dụng hoặc bạn không có quyền xem."* (anti-existence-leak §29). Render `<CardDetail>` trong page container.
- `+src/features/family/memoryRoomShared.tsx` — **MOVE verbatim** từ Stream: CardDetail, MediaTile, AudioPlayer, Video/AudioPlaceholder, EngagementSection, ContributionItem, Write/Edit/RecordContributionDialog, PreserveControl, pickAudioMime, relativeVi, fireLog, SigningApi + preserve/engagement types. **Đổi DUY NHẤT:** CardDetail heading `<h1>` thay `DialogHeader/DialogTitle`. Governance byte-for-byte.
- `+src/routes/_authenticated/family_.memory.$cardId.tsx` — `ssr:false`, `validateSearch` chỉ nhận `origin ∈ {/family,/parent/family}`, render `<FamilyMemoryRoom cardId navOriginHint={origin} />`.
- `~src/features/family/FamilyMemoryStream.tsx` — bỏ Detail Dialog + state `detail`/`setDetail`; `openDetail(card)` → `navigate({to:'/family/memory/$cardId', params:{cardId}, search:{origin}})` (origin = pathname). Import từ shared. Stream KHÔNG redesign.
- `~src/routeTree.gen.ts` (toolchain tự sinh — không sửa tay) · `~package.json` (bump vite-config bởi toolchain).

**QA:** `tsgo --noEmit` PASS · 1 deploy production (`demenart.com` / `demenart.lovable.app`). Detail-modal debt: **0** `max-w-lg max-h-[90vh]` Detail còn lại. Các `max-w-md/sm` còn lại = composer/edit/record/preserve picker — surface KHÁC, GIỮ.

---

## 5. GOVERNANCE MATRIX (§42 — resolve actor LIVE trước)

Actor resolve từ DB (bài học V111D: Hùng = `…051`, KHÔNG phải `…011`):
- **Hùng** guardian: profile `d1000000-…-051`, user_id `eb94304a-8451-44d7-88a7-fe9e26ab0b1c`
- **Bà Ngoại Test** creator các QA card: profile `2965d4a0-…`, user_id `d3d062f8-…`
- **Admin** outsider (non-member): profile `e86e45d1-…`, user_id `446de75d-…`

Card `5125a540` (Ảnh 2 có bé An), 3 active contrib (Ba voice, Ba text, Bà ngoại text — "Ba" = Hùng privacy-projected). `get_family_card_engagement` impersonation:

| Actor | can_moderate | Ba voice | Ba text | Bà ngoại text |
|---|---|---|---|---|
| Hùng | true | mine → Sửa/Rút lại | mine → Sửa/Rút lại | !mine + moderate → **chỉ Ẩn** |
| Bà ngoại | false | !mine, !moderate → **0 nút** | !mine → 0 nút | mine → Sửa/Rút lại |

Card-level: Hùng !isCreator ⇒ **KHÔNG** "Sửa card"; isGuardian ⇒ có **"Lưu trữ"**. Khớp backend + ảnh nghiệm thu.

---

## 6. EXPERIENCE ACCEPTANCE — ✅ PASS (16/07, CTO test mắt, 8 ảnh)

| # | Mục | Bằng chứng |
|---|---|---|
| 1 | Image Room desktop | Kỷ niệm 03, URL `/family/memory/c77eaddf…?origin=/parent/family`, ảnh full không crop, "Quay lại", empty-state đúng §24 |
| 2 | Mixed Room + Voices | Ảnh 2 có bé An: ảnh dẫn + video 0:08 không autoplay; 3 lời |
| 3 | Governance | Lời Bà ngoại → Hùng chỉ "Ẩn"; lời Hùng → Sửa/Rút lại/Ẩn; card → Lưu trữ, không Sửa |
| 4 | F5 / deep link | PASS |
| 5 | Back → /parent/family | PASS |
| 6 | Mobile 390 | Room + Stream ở 400px, cuộn trang, 0 overflow, "Quay lại" chạm được |
| 7 | Denied (outsider) | Deep link không-origin, profile ngoài space → 🔒 generic, 0 leak nội dung/tên/media/voices |

**Request discipline Room (ảnh Network):** 1 `get_family_card` + 1 `get_family_card_engagement` + 1 `get_card_preserve_context` + 1 `get_family_space_role` + `get_signed_media_url` on-demand. 0 N+1 theo lời góp.

---

## 7. QUAN SÁT TRUNG THỰC (không chặn PASS)

Room hiện hiển thị provenance bằng `peopleLine` (*"Kỷ niệm của: …"*, hành vi CardDetail cũ reuse verbatim), **chưa** surface dòng creator *"… đã thêm ký ức này"* (`memoryActorLine`, §21). `creator_name` (mig 100) **có trong payload**, resolve đúng (D291 + Stream ảnh 3) nhưng hiện **chỉ Stream** dùng để hiển thị; Room chưa. Provenance vẫn đầy đủ + quiet ⇒ CTO accept. Muốn dòng creator trong Room ⇒ 1-dòng polish (V111F).

---

## 8. ANOMALY BASELINE (ghi để phiên sau không hoảng)

QA cards spec V111E reference — `Con nói hay` (audio-only), `Test khoảnh khắc 2` (mixed), `Hôm nay con được điểm 10`/text-first (V111D) — **KHÔNG còn tồn tại**. Space DUY NHẤT "Gia đình Hùng": 15 active = 3 native + 12 parent_memory; **0 audio-only, 0 text-only**. Card total vẫn 16 (không mất data) ⇒ card V111D acceptance đã đổi title/archive hoặc chưa persist đúng tên. **Text Room & Audio Room §41 chưa nghiệm thu được** (không tạo synthetic — §14/§18 cấm). Outsider dùng admin non-member (§42). Nếu cần accept đủ 2 loại ⇒ CTO tạo tay 1 text-only + 1 audio-only rồi test lại.

---

## 9. INVARIANTS SAU V111E

87 / **188** / 164 / 1 · migrations **100** · routes **52** · edge **16** · journey **36/36/0** · preserve **4 = 0 active / 3 reversed / 1 orphaned** (orphan KHÔNG bị dọn, §48) · threads/messages **2/3** · cards **16** (15 active / 1 archived). Không drift ngoài mig 100 chủ đích.

---

## 10. CANONICAL CLOSEOUT

- **RULES:** D304 → **D305** (Memory Room · direct-entry độc lập · auxiliary fail không xoá primary · presentation ≠ permission · navOriginHint không authorization · anomaly baseline).
- **SYSTEM_MAP:** v1.09 → **v1.10** (section V111E Memory Room).
- **HANDOFF:** **v111E** (file này).

---

## 11. DEFERRED → V111F (Motion & Sensory QA)

- Stream → Room semantic transition (shared-element / View Transitions)
- card enter motion · preserve motion · archive motion · restore motion
- reduced-motion full audit
- dòng creator *"… đã thêm ký ức này"* trong Room (surface `creator_name` mig 100)
- (nếu cần) tạo QA card text-only + audio-only mới cho §41 acceptance

---

## 12. KHUYẾN NGHỊ BƯỚC TIẾP

V111E **technical + experience PASS** ⇒ đủ điều kiện mở **V111F — Motion & Sensory QA**. Trước V111F, nếu CTO muốn §41 đầy đủ: tạo tay 1 card text-only + 1 audio-only trên production, rồi joint-accept Text/Audio Room.

---

*Endpoint: RULES **D305** · SYSTEM_MAP **v1.10** · HANDOFF **v111E**. Kỷ luật vàng: cập nhật tới đâu ghi tới đó; audit live trước khi tin số; resolve actor identity live trước QA; D284 single access truth; D293 exact.*
