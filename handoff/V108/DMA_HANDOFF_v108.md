# 📦 DMA_HANDOFF_v108.md — V108 FAMILY CREATION (14/07/2026)

## 1. Canonical endpoint
RULES **D282** · SYSTEM_MAP **v1.01** · Handoff **v108**

**Inventory: 82 → 83 bảng / 158 → 166 definer / 164 policy (KHÔNG đổi — bảng mới deny-all) / 1 cron.** Migrations **77 → 84** (`v108a`–`v108g`; 2 lần fail đều **tự rollback sạch** nhờ guard D92 — 1 lỗi cast trong VERIFY, 1 lỗi enum của chính Claude).
Routes **51 — KHÔNG đổi** (composer = Sheet, không route mới). Edge **16 — KHÔNG đổi số lượng**, 2 bump version: `upload_media` **v18**, `get_signed_media_url` **v22**.
Frontend: 2 commit (V108 UI chính · fix reload D282) · 2 deploy · tự áp qua Lovable agent, `get_diff` verify 0 file ngoài phạm vi, `routeTree.gen.ts` không đụng.

**Baseline live (đo lúc đóng):**
- **4 native Memory Card** trong "Gia đình Hùng" (2 active: `Ảnh 1 (sửa lần 1)` **0-child** · `Ảnh 2 có bé An (sửa lần 2)` tag An · 2 archived) — tất cả do **bà ngoại**, một **non-guardian**, tạo bằng tay trên production
- **4 dòng `card_media`** (png 6.7MB · mp4 1.6MB · png 5.8MB · +1) — `source='family'`, zone `dma-private`, `pending_attach=false`
- 12 Memory Card provenance của V107 **nguyên vẹn**
- Regression: `child_journey` **36** · consents **37** · `child_parents` **17** · **9 thẻ chưa hoàn thiện của An = 9** · residue XTEST **0**

> ⚠️ **VIỆC CẦN LÀM NGAY (Jean):** consent `family_space_display` của **An** đang **TẮT** (`withdrawn_at 01:43:26Z` — anh tự tắt ở bước [11] và chưa bật lại sau khi kết thúc test). Vào Hùng → `/parent/consent` → bật lại. Hiện Family Space chỉ hiển thị **1 card**; đây **không** phải state pilot muốn giữ.

---

## 2. V108 là gì

**V-FMN-3 theo Master Build Plan v1:** người thân **tạo** ký ức, không chỉ xem. Native Memory Card (CHECK `title NOT NULL` đã chờ sẵn từ V107) sinh ra từ tay một active member — với capability, với consent gate, với vết audit.

**Invariant canonical mới (CTO):** *"Family members are contributors by default. Family membership permits memory creation only through explicit capabilities and does not grant guardianship."* (D278)

## 3. 3 chốt CTO (đầu Stage 2)

1. **Capability A** — `create_card` là **mặc định** của mọi member. Bootstrap-guardian `{view_space, invite_member, create_card}` · invited `{view_space, create_card}`. Không capability editor UI ở V108; revoke = remove member.
2. **Family-level Card (0 child) CHO PHÉP** — consent trẻ không áp khi Card thực sự không tag trẻ; composer **bắt buộc** nhắc gắn bé; guardian archive được; không đường vào Journey.
3. **Creator tự publish** sau consent gate — không approval queue.

**Blocker bắt buộc do CTO đặt ra ngay từ đầu:** vá media access cho non-guardian. *"Không đóng V108 nếu X10 chỉ PASS bằng guardian account."*

## 4. Kết quả thực thi

### Migrations (D92 3-block từng bản)
- **`v108a_native_card_media`** — `card_media` (deny-all RLS, 0 policy, 0 grant client) · `media_assets.linked_space_id` · source `+family` · quota per-space 500MB. D275 giữ nguyên: native dùng `card_media`, provenance-backed vẫn read-through nguồn, **không copy**.
- **`v108b_card_creation_rpcs`** — 7 secdef. `create_family_card` theo PHASE resolve→gate→mutate (D263), deny **RETURN** + audit (D264/D276). `finalize_family_card_media_attachment` service-only, attach **chỉ pre-publish**, lock space cho quota. `check_family_card_media_access` service-only, 2 nhánh (native · provenance).
- **`v108c_capability_default`** — REPLACE `create_family_space` + `_accept_family_invitation_core` (hardcode capability mới; body V106 giữ nguyên từng chữ).
- **`v108d_stream_native_readthrough`** — stream/detail đọc `card_media` cho native + `creator_profile_id`; **mọi gate consent/membership của V107 giữ TỪNG CHỮ**; VERIFY 0 dấu vết signing.
- **`v108e_telemetry_registry`** — +3 product event (2 lớp whitelist D256) · `card_media` SELECT cho service_role (Edge pre-check; ghi vẫn RPC-only) · registry đồng bộ (D238).
- **`v108f_access_level_family`** — `ALTER TYPE access_level ADD VALUE 'private_family_media'` — **D280**, bắt được nhờ X-test insert media **thật** sau khi Edge đã deploy.
- **`v108g_space_children_for_members`** — `get_family_space_children` cho member active (exposure decision khai báo tường minh).

### Edge
- **`upload_media` v18** — nhánh F `card_id`: gate creator × membership × `create_card` × card journal_only · path `/family-space/{space}/` zone dma-private · quota per-space · finalize atomic + compensating delete.
- **`get_signed_media_url` v22** — nhánh family; guardian path **giữ nguyên**, non-guardian → fallback đường family ⇒ **vá dứt điểm nợ V107**.

### X1–X10 + L1–L4 — PASS toàn bộ
X1 no-capability · X2 cross-space · X3 bé ngoài space · X4 consent_missing · X5 **MIN-consent** · X6 **`child_journey`=36 không đổi sau create VÀ publish** · X7 metadata mismatch / foreign media · X8 removed member · X9 **0-child publish OK, consents không đổi** · **X10 (blocker): draft chỉ creator · published mọi member · non-member chặn · provenance non-guardian ALLOWED · withdraw chặn tại tầng ký** · L1–L4 lifecycle. Residue 0, audit trace giữ (D247).

### E2E production thật — **14/14 PASS**
**Người thật:** guardian Hùng (demo) + **bà ngoại = active non-guardian THẬT** (mint invitation mới → accept qua đường **account-existing**: đăng nhập bằng mật khẩu cũ + RPC `accept_family_invitation` → **0 identity trùng, 0 đổi mật khẩu**).

- Ký & phát **ảnh · video · audio** provenance → `family_card_media_view` **×31** ⇒ **X6 của V107 nay có bằng chứng người thật** (nợ đã đóng)
- Tạo Card **0-child** · tạo Card **tag An** · upload **media thật** qua Edge v18 · publish · sửa · lưu trữ
- Không đọc được `/parent/journal` (0 PII của An)
- **[11] — bằng chứng sắc nhất phiên:** rút consent An → stream bà ngoại **14 → 1**. 12 kỷ vật provenance **và** Card native tag An biến mất; **Card native 0-child nguyên vẹn, ảnh vẫn ký được.** → chốt CTO #2 đúng bằng hành vi, không chỉ bằng spec.
- **[12]** re-grant → về đủ · **[13]** remove → mất sạch (stream RAISE, 5 nhánh `not_authorized`) · **[14]** cross-space `space_not_found`

### 1 bug UI — **CTO bắt, không phải X-test** (D282)
Stream fetch dep `[spaceId]` ⇒ mutation không refetch ⇒ tạo/sửa/lưu trữ "thành công" mà màn hình không đổi. Backend PASS 100% vẫn không cứu được. Fix: `reloadKey` + `selfReload` + overlay tự đóng. 3 file, `get_diff` verify, deploy.

## 5. Security evidence
- Authorization = **membership active × capability** — không role, không relationship label (D272e/D273a re-verify).
- Consent re-check **tại thời điểm ký**, không chỉ tại read (D281). Withdraw/removal chặn ngay ở Edge.
- `card_media` deny-all; service_role chỉ SELECT — đường GHI duy nhất là secdef.
- Mọi nhánh deny create/publish để lại vết audit (RETURN không RAISE).
- 0 signed URL trong payload RPC; D224 nguyên vẹn.
- Grants verify từng grantee bằng `aclexplode` — 0 leak trên 8 function mới.

## 6. Regression — PASS
12 card V107 · `child_journey` **36** (Card của bà ngoại về An **KHÔNG** vào Journey) · consents **37** (0 row sinh ra) · `child_parents` **17** · **9 thẻ chưa hoàn thiện = 9** · Parent Journal · media playback · `/auth` `/invite` `/reset-password` · family invitation/member flows V106–V107.

## 7. Non-actions — xác nhận
❌ Contribution · ❌ Preserve · ❌ Adult/Life Journey · ❌ Events/Circles · ❌ Relevance Engine · ❌ reactions · ❌ capability editor UI · ❌ V109.

## 8. Nợ mang sang
- 🔴 **Bật lại consent `family_space_display` của An** (xem cảnh báo §1).
- 🟡 UI empty-state cho `family_member` không-guardian ở `/parent/family` — hiện mời "Tạo không gian gia đình"; bấm sẽ `not_authorized` (an toàn ở tầng RPC, **sai ngữ nghĩa** ở tầng UI).
- 🟡 Restore UI cho Card archived (dữ liệu đảo ngược được; UI chưa mở).
- 🟡 Gỡ / sắp xếp media **sau** khi Card đã publish (V108 chỉ attach pre-publish có chủ đích).
- 🟡 Media Compatibility Pipeline (MOV/HEVC/WebM normalization).
- 🟡 Nightly sweep `pending_attach` mồ côi.
- (Giữ từ trước) 🟡 Việt hoá email template · 🟡 repo GitHub sync UNVERIFIED · 🟡 caption-edit sau upload · 🟡 Khang 0 consent (không chặn gì) · 🔴 Share từ card — DEFER.

## 9. Trạng thái

# V108 — FAMILY CREATION: **CLOSED** · **PILOT CONTINUES** · **NGƯỜI THÂN ĐÃ TẠO KÝ ỨC ĐẦU TIÊN BẰNG TAY MÌNH**

## 10. Bài học
1. **Đọc được ≠ xem được.** V107 mở Stream cho non-guardian nhưng quên tầng ký ⇒ feature chết đúng với nhóm người nó sinh ra để phục vụ. Không ai báo lỗi vì **chưa có non-guardian nào sống**. Mỗi đối tượng hiển thị phải trả lời **hai** câu hỏi — ai thấy nó tồn tại, ai ký bytes của nó — trong **cùng một sprint** (D281).
2. **D1 áp cả lên *hình dạng* của ràng buộc.** `source` là CHECK, `access_level` là ENUM — hai cột trông y hệt nhau, cần hai loại migration khác nhau. Edge đã sống trên production với một enum label chưa tồn tại; nếu X-test không insert media **thật**, người phát hiện sẽ là phụ huynh đầu tiên (D280).
3. **Backend PASS 100% không cứu được một màn hình không tự làm mới.** X1–X10 xanh, DB đúng từng dòng — và người dùng vẫn phải F5. **CTO là người bắt lỗi này, không phải test suite.** Người dùng thật sẽ không F5; họ sẽ bấm lại — đúng cơ chế đã đẻ ra 5 thẻ rỗng ở D266 (D282).
4. **Consent đúng là consent chặn *chính xác* — không hơn, không kém.** Bằng chứng đẹp nhất của V108 không phải "card bị chặn", mà là **card 0-child KHÔNG bị vạ lây** khi consent của An bị rút. Một hệ chặn quá tay cũng sai như một hệ chặn thiếu.
5. **Guard D92 tự rollback 2 lần trong phiên** — một lỗi cast `name[]` vs `text[]`, một lỗi enum. Cả hai đều là lỗi **của Claude**, và cả hai đều **không để lại một dòng rác nào**. Migration có VERIFY là migration biết tự nhận sai.

## 11. Recommended next action
> **V109 chưa mở.** Trước khi mở: (a) bật lại consent An · (b) để bà ngoại (hoặc một người thân thật khác) **dùng thật vài ngày** — Family Creation vừa sinh ra, dữ liệu hành vi thật sẽ nói cho ta biết Contribution/Preserve nên có hình dạng nào, thay vì ta đoán trước. Ứng viên V109 theo Master Build Plan: **V-FMN-4 Contribution** (người thân đóng góp vào Card của người khác) hoặc **Preserve**. **KHÔNG tự mở.**
