# DMA V109A — CONTRIBUTION & PRESERVE DISCOVERY
## ⭐ Deliverable — Discovery only · 0 migration · 0 UI · 0 mutation (14/07/2026)

> Nguồn sự thật: HANDOFF v108 · RULES D282 · SYSTEM_MAP v1.01 · Foundation v3 · Master Build Plan v1 · **live DB audit 14/07** (read-only).

---

# 0. LIVE AUDIT — KẾT QUẢ

## 0.1 Canonical vs live: **KHỚP 100%**

| Chỉ số | Canonical v108 | Live 14/07 | |
|---|---|---|---|
| Bảng / definer / policy / cron | 83 / 166 / 164 / 1 | 83 / 166 / 164 / 1 | ✅ |
| Migrations (cuối) | 84 (`v108g`) | 84 (`v108g_space_children_for_members`) | ✅ |
| memory_cards | 12 provenance active + 2 native active + 2 native archived = 16 | 16, đúng phân phối | ✅ |
| card_media | 4 | 4 | ✅ |
| card_person_links | — | 17 (13 child/subject + 4 profile/creator) | ✅ |
| child_journey | 36 | 36 (demen/session 13 · demen/badge 1 · parent/parent_memory 22) | ✅ |
| consents / child_parents | 37 / 17 | 37 / 17 | ✅ |
| 9 thẻ chưa hoàn thiện của An | 9 | **9** (⚠️ bẫy đếm: "Múa nhảy mùa Hè" có 1 dòng `parent_memory_media` nhưng media `state='deleted'` — filter đúng phải đếm media **active**) | ✅ |

## 0.2 Consent baseline An: **AN TOÀN**
`family_space_display` của An: `granted=true, withdrawn_at=NULL` — anh đã bật lại đúng như nợ §8 HANDOFF v108 yêu cầu. Pilot baseline được khôi phục.

## 0.3 ⚠️ Phát hiện vận hành: **bà ngoại đang REMOVED**
- 2 member active của "Gia đình Hùng" = **Hùng (Ba) + Ngân (Phụ huynh)** — cả hai `bootstrap_guardian`, capabilities `{view_space, invite_member, create_card}` (đúng D278).
- "Bà Ngoại Test" có 2 membership đều `state='removed'` (bản V107 `{view_space}` và bản E2E V108 `{view_space, create_card}` — remove ở bước [13] E2E, **chưa mời lại**).
- **Hệ quả:** khuyến nghị đóng V108 ("để bà ngoại dùng thật vài ngày") hiện KHÔNG chạy được — không có non-guardian nào sống. Observation Program (mục A) cần mời lại bà ngoại trước khi bắt đầu. Đây là hành động của Jean/Hùng qua UI, không phải của Claude.

## 0.4 Primitive hiện có liên quan Contribution/Preserve

| Primitive | Live | Ý nghĩa cho V109 |
|---|---|---|
| `memory_threads` | 2 dòng, CHECK `num_nonnulls(moment_id, creation_id, journey_id)=1`, có `child_id` | Anchor pattern tồn tại; **authorization root = child_parents (guardian-scoped)**, KHÔNG phải membership |
| `memory_messages` | 3 dòng (author_type='parent'), body text, soft-delete, **0 media attach, 0 lifecycle state** | Chat-primitive thuần; thiếu state VISIBLE→PRESERVED→WITHDRAWN của Foundation §6 |
| `card_media` | (card_id, media_id, sort_order, deleted_at) | Junction pattern tái dùng được y hệt cho contribution_media |
| `child_journey` | (child_id, **source, entry_type, ref_id**, program_id, occurred_at) | **Spine đã là reference-based** — 22 dòng parent_memory là reference (ref_id → parent_memories.id), không copy content |
| `preserve_records` / `card_reactions` / bảng comment | **KHÔNG tồn tại** | Greenfield sạch |
| `kid_reactions` | 1 dòng, kid→moment | Domain kid riêng — KHÔNG nới (Build Plan A2.4③) |
| Capabilities | mảng text[] trong family_members, hardcode tại 2 RPC (D278) | Thêm capability mới = REPLACE 2 hàm, pattern v108c có sẵn |
| Consent gate | family_space_display MIN rule, re-check tại read (D276) + tại ký (D281) | Contribution thừa kế nguyên gate của Card — không cần consent surface mới |
| Telemetry | product_events 2 lớp whitelist (D256); family_card_detail_opened=22, family_stream_opened=16 | Đủ móc đo cho observation |

**Không có primitive xung đột.** Điểm căng duy nhất — `memory_threads` vs Contribution — được xử lý ở mục F (ranh giới, không phải xung đột).

---

# A. OBSERVATION BRIEF

## A.1 Điều kiện tiên quyết (Jean/Hùng thực hiện, KHÔNG phải Claude)
1. Hùng mời lại **bà ngoại** vào "Gia đình Hùng" (đường invitation V108 đã chứng minh, account-existing).
2. Giữ nguyên baseline: consent An bật, 14 card trong stream (12 provenance + 2 native active).

## A.2 Người tham gia
| Ai | Vai trong quan sát |
|---|---|
| Bà ngoại (non-guardian thật) | **Nhân vật chính** — người "muốn để lại điều gì đó" trên ký ức của cháu |
| Hùng (guardian) | Người giữ cửa Journey — có muốn kiểm soát không, kiểm soát đến đâu |
| Ngân (guardian/QA) | Góc nhìn người mẹ + QA — phân biệt được 3 khái niệm không |

3 người thật > synthetic volume. Không cần analytics quy mô.

## A.3 Thời lượng & phương pháp
- **5–7 ngày dùng tự nhiên** (không kịch bản), sau đó **mỗi người 1 buổi hỏi 15 phút**.
- Trong tuần đó KHÔNG build gì — hệ hiện tại (xem + tạo Card) là công cụ quan sát đủ.

## A.4 Câu hỏi chính xác (hỏi sau khi họ tự dùng)

**Cho bà ngoại (contributor):**
1. Khi bà xem thẻ [ảnh An], bà muốn làm gì tiếp theo nhất? *(mở — KHÔNG gợi ý react/comment)*
2. Nếu bà muốn nói một câu cho An nghe sau này — bà muốn **viết**, **thu giọng nói**, hay **gửi ảnh của bà**?
3. Điều bà vừa nói/gửi đó — bà coi nó là "một lời nhắn cho bây giờ" hay "một thứ An nên giữ đến khi lớn"?
4. Nếu bà đổi ý, bà có muốn tự xoá được lời của mình không? Kể cả khi ba mẹ An đã "giữ" nó rồi?
5. Thay vì góp lời vào thẻ của người khác, bà có muốn **tự tạo một thẻ mới** kể chuyện của bà không? Cái nào tự nhiên hơn?

**Cho Hùng + Ngân (guardian/steward):**
6. Lời bà góp vào thẻ của An — anh/chị có muốn quyết định nó có vào Hành trình của An hay không? Hay để tự động?
7. Nếu cả hai vợ chồng — một người "giữ", một người không muốn — thì theo anh chị nên xử thế nào?
8. Anh chị có phân biệt được: ❤️ · một lời góp · "giữ vào Hành trình" không? Dùng từ của chính anh chị mô tả lại.

**Cho cả 3:**
9. Tưởng tượng An 25 tuổi mở lại thẻ này. Thứ gì trên thẻ đáng để còn ở đó? Thứ gì không cần?

## A.5 Bằng chứng cần bắt
- Ghi lại **động từ họ tự dùng** ("gửi lời", "nhắn", "kể", "giữ", "lưu"…) → quyết định copy UI.
- Đếm telemetry sẵn có: `family_card_detail_opened`, `family_stream_opened`, `family_create_completed` trước/sau tuần quan sát.
- Có ai **tự tạo Card mới để phản hồi một Card cũ** không (Model C tự phát)?
- Test 3 từ đề xuất: **"Gửi yêu thương"** (❤️) · **"Góp một ký ức"** · **"Giữ vào Hành trình của bé"** — họ hiểu đúng không cần giải thích?

## A.6 Tiêu chí "quan sát xong"
Trả lời được bằng bằng chứng thật: (1) voice hay text là bản năng đầu tiên; (2) guardian CÓ/KHÔNG muốn cầm quyền Preserve; (3) contributor CÓ/KHÔNG kỳ vọng quyền rút; (4) 3 khái niệm có phân biệt được bằng ngôn ngữ thường không.

---

# B. PRODUCT DECISION MATRIX

| Tiêu chí | A — Comment | B — Contribution first-class | C — Memory Branch | D — Hybrid (❤️ + Contribution [+ đường lên Card]) |
|---|---|---|---|---|
| Đúng DNA "Contribution over engagement" | ❌ trôi về FB | ✅ | ✅ mạnh nhất về triết lý | ✅ |
| Bài test 20 năm | ❌ comment chết theo thời sự | ✅ voice/text có lifecycle | ✅ nhưng nặng nghi thức | ✅ |
| Ngăn ❤️ trộn với ký ức | ❌ mọi thứ là comment | ⚠️ cần tách riêng ack | ✅ (không có comment) | ✅ tách bằng cấu trúc |
| Authorization | ⚠️ nếu reuse memory_threads: trộn 2 gốc quyền (child_parents vs membership) — rủi ro lớp D281 | ✅ một gốc: membership × capability × consent của Card | ✅ tái dùng nguyên gate V108 | ✅ như B |
| Nguy cơ nhân bản sự thật Card | Thấp | Thấp (nếu cấm ảnh/video trong contribution) | **Zero** — mọi thứ là Card | Thấp, có van xả lên Card |
| Chi phí build | Thấp | Trung bình | **Thấp nhất** (V108 đã có 90%) | Trung bình |
| Rào với người già | Thấp | Thấp (1 nút, 1 giọng nói) | **Cao** — "tạo thẻ" là nghi thức nặng cho một câu chúc | Thấp |
| Rủi ro sản phẩm chính | Thành Facebook | Overbuild lifecycle | Stream ngập card vụn "Hay quá!" → loãng chính khái niệm Card | Phức tạp khái niệm nếu lộ cả 3 cùng lúc |

**Phân tích thẳng:**
- **A loại.** Không phải vì "comment xấu" mà vì comment không có chỗ đứng trong mô hình permanence — và vì đường reuse `memory_threads` rẻ nhất về schema lại đắt nhất về an ninh (trộn hai gốc authorization, xem F.2).
- **C loại làm mô hình duy nhất** nhưng **giữ làm van xả**: một contribution đủ nặng xứng đáng được nâng thành Card liên quan. Không build card-to-card link ở V109; ghi làm Horizon B.
- **★ Chốt đề xuất: Model D, nhưng lộ ra theo lớp** — V109B chỉ lộ ❤️ + Góp một ký ức; đường "nâng thành Card" là tiến hoá sau, không phải scope bây giờ. Hypothesis §12 của anh **đứng vững sau audit**, với một chỉnh quan trọng: Contribution KHÔNG extend `memory_threads` (lý do ở F.2 — đây là điểm em nói thẳng khác với Master Build Plan v1).

---

# C. CONTRIBUTION DEFINITION (đề xuất)

## C.1 Ngữ nghĩa
> **Contribution = một mảnh ký ức của MỘT người thật, gắn vào Card của người khác, có chủ thể sở hữu, có vòng đời, và có thể — nhưng không tự động — trở thành một phần Hành trình.**

Ba câu phân biệt:
- ❤️ nói *"tôi đã thấy và tôi thương"* → **KHÔNG phải Contribution** (acknowledgement, không lifecycle, không preserve path).
- Contribution nói *"tôi để lại một phần trí nhớ của tôi ở đây"*.
- Card nói *"đây là một ký ức đứng được một mình"*.

## C.2 Loại được phép ở Horizon A
| Loại | Quyết | Lý do |
|---|---|---|
| **Text** | ✅ V109B | Nền tối thiểu |
| **Voice** | ✅ V109B | **Chính là câu trả lời cho bài test 20 năm** — giọng bà ngoại là thứ không thay được; pipeline audio đã production-proven (D277 AudioPlayer, upload parent path) |
| Photo/video | ❌ | Ảnh/video là **chất liệu Card** — cho vào contribution = Card mọc bản sao thứ hai trong phần bình luận (vi phạm một-sự-thật-một-nơi). Composer nudge: *"Ảnh này xứng đáng có Thẻ ký ức riêng — tạo Thẻ mới?"* |
| Memory correction / "tôi cũng nhớ ngày đó" / lời chúc | = text hoặc voice | Không cần loại riêng — đừng phát minh taxonomy trước khi quan sát |

## C.3 Ai được góp
- **Active member của đúng space** có capability **`contribute`** (capability MỚI, mặc định cấp cho mọi member theo pattern D278 — hardcode tại `create_family_space` + `_accept_family_invitation_core`, revoke = remove member, KHÔNG capability editor).
- Chỉ trên Card **published** (draft = xưởng riêng của creator).
- Card phải **nhìn thấy được** dưới Effective Access của người góp — tức consent gate của Card tự động là consent gate của Contribution. **Không tạo consent surface mới.**
- Ngoài space (teacher, người lạ): ❌ Horizon A. Kiến trúc không cần nới — gate membership đã chặn bằng cấu trúc.

## C.4 Sở hữu & quyền
| Quyền | Ai | Ghi chú |
|---|---|---|
| Tạo | member active có `contribute` | |
| Sửa text / thu lại voice | **chỉ contributor** | Creator của Card KHÔNG sửa được lời người khác (gương D278) |
| Withdraw (rút) | **chỉ contributor**, bất kỳ lúc nào, **kể cả sau Preserve** | Quyền hiến định Foundation §5 "contributor giữ quyền kiểm soát có ý nghĩa" |
| Ẩn (hide) trên Card | **guardian** (governance, gương quyền archive D279) | Card creator non-guardian KHÔNG có quyền ẩn lời người khác ở V109B — quan sát rồi tính |
| Xem | mọi member thấy được Card | Thừa kế 100% gate Card: consent An rút → Card biến → contributions biến theo (không cần cơ chế riêng) |

## C.5 Vòng đời
```text
visible ──(contributor)──▶ withdrawn        (rút — nội dung không đọc được nữa, vết audit giữ)
visible ──(guardian)────▶ hidden            (ẩn khỏi Card — đảo ngược được)
visible ──(steward Preserve)▶ visible+preserved   (KHÔNG phải state riêng — xem D)
```
Mọi chuyển trạng thái để vết (D264): `contribution_created / withdrawn / hidden / unhidden` — deny RETURN không RAISE.

## C.6 Hình dạng kỹ thuật (định hướng — CHƯA phải migration)
- Bảng mới `card_contributions`: id · card_id · contributor_profile_id · kind {text, voice} · body (text, NULL nếu voice) · state {visible, hidden, withdrawn} · state_changed_by/at · created_at/updated_at. Deny-all RLS, đường ghi duy nhất = secdef RPC (khuôn card_media).
- `contribution_media`: junction gương `card_media` (contribution_id, media_id, deleted_at) — voice qua Edge `upload_media` nhánh mới, zone dma-private, quota per-space hiện có.
- **D281 trả lời cả 2 câu trong CÙNG sprint:** ai thấy contribution tồn tại (stream/detail RPC) VÀ ai ký được bytes voice (nhánh mới trong `check_family_card_media_access` + Edge v23) — consent re-check tại thời điểm ký.

---

# D. PRESERVE DEFINITION (đề xuất)

## D.1 Ngữ nghĩa
> **Preserve = hành động có chủ đích của steward, đưa một Card hoặc một Contribution vào Hành trình dài hạn của MỘT đứa trẻ — bằng tham chiếu, có vết, và đảo ngược được.**

Preserve KHÔNG phải Like. Preserve KHÔNG phải bookmark. Preserve là **lifecycle transition hạng nhất** (Foundation invariant 7).

## D.2 Trả lời từng câu hỏi của đề bài

| Câu hỏi | Đề xuất | Căn cứ |
|---|---|---|
| Preserve Card? Contribution? | **Cả hai** — hai target hợp lệ của cùng một hành động | Card của bà về An và giọng bà chúc An đều có thể xứng đáng vào Journey |
| Reference / Copy / Snapshot? | **★ Reference (Option 2)** | Spine `child_journey` ĐÃ là reference-based (source+entry_type+ref_id — 22 dòng parent_memory sống bằng đúng mô hình này). Copy = dual truth, vi phạm meta-nguyên-tắc 5 + DNA 12. Snapshot = hoãn — chỉ cân nhắc lại nếu quan sát cho thấy nhu cầu "đóng băng phiên bản" thật |
| Nguồn bị archive? | Journey entry đọc-xuyên → tự ẩn nội dung (tiền lệ D275 "content truth thắng"); `preserve_records.state='orphaned'`, vết event, KHÔNG xoá record | Một sự thật; audit không mất |
| Contributor rút sau Preserve? | **Được.** Reference semantics thực thi bằng cấu trúc: nội dung biến khỏi Journey view; preserve_record → orphaned; guardian nhận notification | "Durable ≠ irrevocable" (Foundation §6). Không cần xin phép contributor TRƯỚC khi Preserve — vì quyền rút của họ sống sót QUA Preserve. Đây là câu trả lời sạch nhất cho cặp ownership↔permanence |
| Ai Preserve cho trẻ? | **Guardian trong `child_parents`** của ĐÚNG đứa trẻ đó — một guardian đủ (cả hai đều có quyền độc lập) | Gương publish V108 nhưng hẹp hơn: preserve vào Journey của MỘT bé chỉ cần steward của bé đó; Journey bé khác không bị đụng |
| Hai guardian mâu thuẫn? | Guardian kia có quyền **reverse** — fail toward least exposure: trạng thái cuối khi tranh chấp là KHÔNG preserve | Foundation §5 guardian conflict |
| Đảo ngược? | **Có** — steward un-preserve bất kỳ lúc nào; journey entry gỡ, preserve_record `state='reversed'`, vết audit | |
| Adult tự Preserve vào Journey mình? | **❌ KHÔNG — [C3] ranh giới cứng Horizon A.** Ontology future-capable, không build | Master Build Plan V-FMN-4 |
| Child maturity đổi quyền? | Móc `children.identity_user_id` chờ sẵn (0 dùng) — Horizon C, không đụng | |
| Teacher-origin content? | Không có teacher trong space ở Horizon A → câu hỏi chưa tồn tại. Ghi chỗ: khi có, provenance đã truy vết được nguồn institutional (D275) — governance riêng quyết lúc đó | |

## D.3 Invariant cứng (đưa thành D-rule khi build)
> **Family member KHÔNG BAO GIỜ có quyền ghi Journey chỉ vì có quyền create/contribute. Đường ghi `child_journey` từ thế giới FMN đi qua ĐÚNG MỘT cổng: RPC preserve steward-only, gate `child_parents`. Tag/Relate ≠ Preserve. Publish ≠ Preserve. Mọi preserve không qua steward cho minor = STOP.**

## D.4 Hình dạng kỹ thuật (định hướng)
- `preserve_records`: id · target CHECK đúng-một (card_id XOR contribution_id) · child_id · journey_entry_id · actor_profile_id · basis ('steward_approved') · state {active, reversed, orphaned} · timestamps. Deny-all RLS, secdef-only.
- `child_journey`: +source `'family'`, +entry_type `'memory_card'` / `'card_contribution'` (⚠️ D280 — audit **hình dạng ràng buộc** của 2 cột này trước khi viết migration: CHECK hay ENUM quyết định loại migration).
- Đọc Journey: nhánh đọc-xuyên mới trong `get_child_journal` (re-check state nguồn + state preserve_record) — regression anchor: **36 dòng hiện tại + X6 bất biến** (create/contribute KHÔNG đổi count; chỉ preserve mới +1).

---

# E. UX CONCEPT (mô tả — KHÔNG build)

## E.1 Card Detail — khu tương tác (dưới content, trên provenance)
```text
┌─ Card content (như V108) ─────────────────────┐
│ …ảnh/story…                                    │
├────────────────────────────────────────────────┤
│ 💛 Gửi yêu thương          [Bà ngoại, Mẹ đã    │
│                             gửi yêu thương]     │  ← TÊN, không số đếm
├────────────────────────────────────────────────┤
│ ✎ Góp một ký ức                                │
│   ┌──────────────────────────────────────┐     │
│   │ [Aa Viết một lời]  [🎙 Thu giọng nói] │     │
│   └──────────────────────────────────────┘     │
│                                                 │
│ 🎙 Bà ngoại · hôm qua            ▶ 0:00/0:32   │
│    "…"                    [Giữ vào Hành trình]  │  ← nút CHỈ hiện với guardian
│ ✎ Mẹ · 3 ngày trước                            │
│    "Hôm đó con về kể mãi…"    [đã giữ ✓]       │
└────────────────────────────────────────────────┘
```
- **❤️ = 1 loại duy nhất "Gửi yêu thương"** — không palette 6 cảm xúc kiểu FB. Toggle được. Names-over-counts (Foundation §7).
- **"Góp một ký ức"** — voice ngang hàng text ngay từ nút đầu tiên (không giấu voice sau menu). AudioPlayer custom D277.
- **Contributor thấy trên lời của mình:** Sửa · Rút lại. **Guardian thấy trên lời người khác:** Ẩn. **Guardian thấy trên card/contribution:** Giữ vào Hành trình / Bỏ giữ.
- Sắp xếp **thời gian thuận** (cũ → mới, như đọc một lá thư nối dài) — KHÔNG sort theo engagement. Đây là chỗ khác Facebook bằng cấu trúc.
- Copy giọng DMA: không "Bình luận…", mà *"Bà/Mẹ muốn giữ lại điều gì về khoảnh khắc này?"* (kỷ luật ngôn ngữ Foundation §7).

## E.2 Preserve flow (guardian)
1 tap "Giữ vào Hành trình" → sheet xác nhận: *"Giữ [giọng nói của Bà ngoại] vào Hành trình của **An**. Sau này An lớn lên sẽ thấy nó trong nhật ký của mình."* → chọn bé (nếu card tag >1 bé) → xong, badge "đã giữ ✓". Reverse = cùng chỗ.

## E.3 Chỗ nudge Model C (van xả, chưa build)
Khi contribution text > ~300 ký tự: dòng gợi ý mềm *"Câu chuyện này có thể xứng đáng là một Thẻ ký ức riêng"* → mở composer V108 có sẵn. Không ép, không tự động.

---

# F. ARCHITECTURE READINESS

## F.1 Tái dùng nguyên vẹn
Gate Effective Access của Card (D276) · consent re-check tại ký (D281) · `has_family_capability` (D278) · junction pattern `card_media` · Edge `upload_media`/`get_signed_media_url` nhánh-hoá · telemetry 2 lớp (D256) · audit RETURN-không-RAISE (D264) · spine reference `child_journey` (source/entry_type/ref_id) · AudioPlayer iOS (D277) · reload hạng nhất (D282).

## F.2 ⭐ Điểm em nói thẳng — KHÁC Master Build Plan v1
Build Plan V-FMN-4 ghi: *"Contribution: extend `memory_threads` +anchor card_id"*. **Sau audit live, em đề xuất KHÔNG làm vậy — dựng `card_contributions` first-class riêng.** Lý do:
1. **Hai gốc authorization khác nhau.** `memory_threads`/`memory_messages` sống trong thế giới guardian-scoped (child_parents, anchor journey/moment/creation — ghi chú riêng tư của phụ huynh quanh nhật ký). Contribution sống trong thế giới membership × capability × consent. Trộn vào một bảng = mọi read path phải branch theo anchor → đúng lớp rủi ro D281 (quyền-một-nửa) đã trả giá ở V107.
2. **`memory_messages` thiếu lifecycle** (visible/hidden/withdrawn) và thiếu media attach — retrofit state machine lên một bảng đang sống phục vụ ngữ cảnh khác là sửa-câm hành vi cũ.
3. Foundation v3 nói Contribution *"tiến hoá từ memory_threads"* — em đọc là tiến hoá **khái niệm**, không bắt buộc cùng bảng. CHECK một-anchor của threads nghĩa là mỗi anchor mới = 1 migration anyway — không tiết kiệm gì.
4. **Ranh giới tuyên bố tường minh để không thành hai-sự-thật:** `memory_threads` = ghi chú riêng tư quanh Journal (guardian-scoped), KHÔNG BAO GIỜ hiện trong Family Space; `card_contributions` = tiếng nói gia đình quanh Card (membership-scoped), KHÔNG BAO GIỜ hiện trong Journal trừ khi qua Preserve. Hai domain, hai bảng, không giao nhau.

→ Nếu anh chốt, đây là một **correction chính thức lên Master Build Plan v1** (ghi vào canonicalize V109A).

## F.3 Primitive mới cần (khi V109B/C được duyệt)
| Mới | Sprint | Ghi chú |
|---|---|---|
| `card_acknowledgements` (card_id, profile_id, UNIQUE) | V109B | Nhỏ nhất có thể; 1 loại |
| `card_contributions` + `contribution_media` | V109B | Deny-all, secdef-only |
| Capability `contribute` (hardcode 2 RPC) | V109B | Pattern v108c |
| Edge `upload_media` nhánh contribution + signing nhánh mới | V109B | D281: 2 câu cùng sprint |
| `preserve_records` + `child_journey` +source/+entry_type + RPC steward + đọc-xuyên journal | **V109C** | Đụng bảng thiêng nhất — biên giới migration riêng |

## F.4 Rủi ro chính
1. **`child_journey` là bảng linh hồn** (D40, anchor "36") — mọi đụng chạm dồn vào V109C với X-test riêng, không trộn với contribution.
2. **D280 lặp lại:** trước khi viết migration V109C, audit **cơ chế ràng buộc** của `child_journey.source` và `entry_type` (CHECK vs ENUM) — không đoán.
3. **Voice trên iOS** — đã có công thức D277 nhưng ghi âm (MediaRecorder) là bề mặt mới chưa từng test trên Safari iOS của người già → cần 1 phép thử thiết bị thật của bà ngoại trong observation week.
4. **Journal read-through V109C** phải giữ get_child_journal authorization path nguyên vẹn (Build Plan A2.4⑤ — KHÔNG an toàn để tổng quát hoá).

---

# G. RECOMMENDATION — SCOPE V109B ★

> **V109B = "CONTRIBUTION CORE" — KHÔNG Preserve.**

**Scope (hẹp, build an toàn được):**
1. `card_acknowledgements` — 💛 "Gửi yêu thương", 1 loại, names-over-counts, toggle.
2. `card_contributions` (text + voice) + `contribution_media` + capability `contribute` mặc định + Edge nhánh upload/sign voice (D281 đủ 2 câu).
3. Quyền: contributor sửa/rút · guardian ẩn · mọi member thấy theo gate Card.
4. Card Detail khu tương tác (E.1, KHÔNG nút Preserve) + reload hạng nhất D282.
5. **X-test bất biến vàng:** `child_journey` = 36 TRƯỚC và SAU mọi contribute/ack/withdraw/hide — contribution KHÔNG có đường vào Journey. Consent An rút → contributions biến theo Card ở cả tầng đọc lẫn tầng ký.

**V109C = "PRESERVE"** (mở riêng sau khi V109B sống): preserve_records · child_journey +vocabulary · RPC steward-only · reverse · orphan-on-withdraw · đọc-xuyên journal.

**Vì sao tách:** Preserve đụng `child_journey` — bảng có regression anchor thiêng nhất hệ thống; contribution thì zero-contact với Journey. Hai blast radius sạch, hai bộ X-test sạch. Và tuần observation + vài tuần contribution thật sẽ cho biết **cái gì đáng Preserve** trước khi ta xây nút Preserve — đúng tinh thần "để dữ liệu hành vi thật nói" của chính anh ở closeout V108.

**Thứ tự đề xuất:** Mời lại bà ngoại → chạy Observation (A) 5–7 ngày → chốt/chỉnh mô hình theo bằng chứng → mở V109B. KHÔNG tự mở.

---

# NON-ACTIONS V109A — XÁC NHẬN
❌ 0 migration · 0 bảng comment/reaction · 0 UI · 0 mutation child_journey · 0 media flow mới · 0 public sharing · 0 Relevance Engine · 0 AI ranking · 0 V109B tự mở. Toàn bộ phiên: read-only audit + tài liệu này.

# TRẢ LỜI 2 CÂU CLOSEOUT
> **"Bà ngoại nên để lại được gì trên một Memory Card hôm nay mà 20 năm sau cháu bà vẫn quý?"**
> → **Giọng nói của bà** (và một dòng chữ) — thuộc về bà, rút được, gắn vào ký ức nhưng không nhân bản ký ức.

> **"Ai quyết định đóng góp đó trở thành một phần Hành trình vĩnh viễn của đứa trẻ?"**
> → **Steward — guardian trong `child_parents` — bằng một hành động tường minh, có vết, đảo ngược được. Không ai khác, không tự động, không AI.**
