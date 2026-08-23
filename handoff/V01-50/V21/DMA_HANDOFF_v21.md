# 🤝 DMA_HANDOFF_v21.md — BÀN GIAO PHIÊN (ĐÓNG NGÃ A + PHÁT SINH — 2026-06-27 16:21 GMT+7)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v21. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

**Ngã A (dọn data test + lưu repo) — mở phiên ngắn, hóa ra phát sinh 1 mig + IA polish.** Bắt đầu là phiên trả nợ; kết thúc đóng trọn cả nợ repo, IA portal, và 1 bug đọc thật.

- **Dọn data test KHM** (§5 của v20): xóa Lớp Test Sáng · Cô Test · Bé Test · Mẹ/Bố Test → về **3 tenant sạch** (5 lớp / 16 trẻ).
- **Lưu repo:** `040_master_self_manage.sql` (dump trung thực live, D90) + xác nhận `school.tsx` đã auto-synced GitHub.
- **IA polish:** hợp nhất **3 màn admin** (`sensitive-access` · `curriculum-admin` · `school-onboarding`) từ `portal/` vào `_authenticated/portal.*` → có guard redirect `/auth`, URL giữ nguyên. Xóa dev panel `portal.rls-test.tsx`.
- **⭐ Bug thật phát sinh (D92):** master `/portal/school` thấy PH = **"—"** → mig 041 RPC `get_child_parents` vá. Cosmetic v20 (tên PH + email + dropdown vai + toast) đóng theo.

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc:** **46 bảng · 46 hàm SECURITY DEFINER · 125 RLS policy · mig 001→041 · seed 001→012.** SYSTEM_MAP **v0.21.**
  - +1 hàm v21: `get_child_parents` (grant authenticated+service_role, secdef, KHÔNG audit — curated read, gương D73).
  - mig 041 **KHÔNG thêm bảng/cột/enum/policy** — chỉ 1 RPC. 125 policy KHÔNG đổi.
- **Edge Functions (4 — không đổi):** `get_signed_media_url` · `upload_media` · `resolve_share_link` · `invite_master`.
- **Routes app:** 3 màn admin chuyển về `_authenticated/portal.{sensitive-access,curriculum-admin,school-onboarding}.tsx` (URL giữ nguyên); **xóa** `portal.rls-test.tsx`.
- **3 tenant / 3 master:** `DEMO-001` · `KHM-DN` · `MNDM-DN` — **sạch** (đã dọn data test).
- **Data state (giữ từ v17):** KHM-DN `sharing_mode=private_share_link`; consent An `private_share_link` (`d1…e1`) **WITHDRAWN**.

> ⚠️ **KHÔNG còn data test rác** — audit 8/8 = 0 (xác nhận panel `rls-test` chưa từng để lại row). Nợ "caption/row test rác" gạch khỏi danh sách.

---

## 3. mig 041 — `get_child_parents` (D92, vá D29 chiều ĐỌC)

### `get_child_parents(p_child_id) → jsonb`
- **Vấn đề:** master `/portal/school` tab Trẻ&PH đọc PH qua embed `profiles!parent_profile_id` → trả null vì PH `school_id=NULL` (D40) trượt cả 3 SELECT policy `profiles` (`is_admin` false · `same_school` chết ở `school_id IS NOT NULL` · `self` không phải master) → UI hiện "—" / "Chưa có email". *Bằng chứng không-phải-data: PH seed Hùng (có login) cũng "—".*
- **Fix = RPC curated secdef (gương D73), KHÔNG nới policy:** gate `is_admin() OR (master/sub same_school qua user_school_ids())` → bypass RLS CỐ Ý → trả CHỈ nhãn an toàn `[{parent_profile_id, full_name, email, phone, link_role, has_login}]`.
- **TUYỆT ĐỐI KHÔNG** nới `profiles_select_same_school` cho `school_id IS NULL` → lộ PH mọi trường (convention load-bearing D52/D56).

### ⭐ Bài học hạ tầng (D92) — REVOKE/GRANT secdef chạy TÁCH BLOCK
- Gói `CREATE + REVOKE + SELECT-gọi-hàm-verify` trong 1 khối → SELECT **raise `not_authorized`** (gate đúng, `auth.uid()`=NULL ở SQL Editor — D2) → **abort transaction → CREATE rollback** (`fn_exists=0` đánh lừa "chưa tạo" — họ hàng D88).
- Chạy lại verify-KHÔNG-gọi-hàm → CREATE commit, NHƯNG REVOKE cùng-block **không phủ hết** default PUBLIC của `CREATE OR REPLACE` → `leaky_grants=['get_child_parents']` + `anon` execute (D15 sống).
- **FIX:** `REVOKE ALL FROM PUBLIC + FROM anon` chạy **KHỐI RIÊNG**, verify grant riêng (soi `proacl`, KHÔNG gọi hàm). → sạch: `grantees=[authenticated,postgres,service_role]` · `leaky_grants=[]`.
- **Quy tắc:** verify hàm secdef-có-gate **đừng GỌI hàm trong cùng migration**; nghiệm thu nhánh gate bằng **login thật**.

---

## 4. IA POLISH + nghiệm thu

**Hợp nhất 3 màn admin vào `_authenticated`:** `_authenticated` là layout route **pathless** (`_` không thêm segment) có `beforeLoad` gọi `getUser()` → không user thì `redirect({to:"/auth"})`. 3 màn admin trước nằm thẳng `portal/` (ngoài guard) → chuyển vào `_authenticated/portal.*`.
- **Nghiệm thu login thật (2 tiêu chí):** ① đăng nhập admin → 3 URL `/portal/{sensitive-access,curriculum-admin,school-onboarding}` mở đúng (URL byte-identical); ② **đăng xuất → mở 1 trong 3 → đá về `/auth`** ✅ guard ăn.

**Xóa `portal.rls-test.tsx`:** dev panel test RLS (họ hàng `bunny-sign-test`), có UUID demo hardcode + nút insert test. Xóa → `/portal/rls-test` 404. **Audit trước xóa: 8/8 = 0** → không để lại row test rác.

**Cosmetic v20 (xác nhận sau deploy + vá UI):**
- Tên PH + email hiện đúng (qua RPC `get_child_parents`, hết "—").
- Dropdown vai đủ 3 (Mẹ·Bố·Người giám hộ); lưu **CODE** `mother`/`father`/`guardian` (trước lưu nhãn VN "Mẹ"), render map ngược, legacy `primary`/`secondary` giữ nguyên.
- Toast xanh/đỏ chạy (`<Toaster richColors>` mount root); max-2-parent hiện inline "Bé đã có đủ 2 phụ huynh."

---

## 5. FILE REPO PHIÊN NÀY (đặt cạnh 001–040)

- `040_master_self_manage.sql` — 2 RPC mig 040 (dump trung thực D90; lưu phiên này vì v20 chạy tay chưa lưu).
- `041_get_child_parents.sql` — mig 041 (gồm BLOCK harden anon + verify-không-gọi-hàm).
- `school.tsx` — **đã auto-synced** qua Lovable→GitHub (không cần lưu tay).

> Migration SQL chạy tay trong SQL Editor → KHÔNG tự sync GitHub → phải lưu tay. Code Lovable thì auto-publish.

---

## 6. VIỆC TREO (ưu tiên giảm dần)

1. **`revoke_share_link` + UI** (D87 — share link chỉ tự-chết qua expiry/rút-consent; chưa có nút thu hồi tay).
2. **Profile GV/PH còn lại chưa có login** (chỉ master + vài vai đã invite). → onboard staff/PH qua app (master mời login, nhân pattern `invite_master` v18).
3. **2 file curriculum media chưa có nguồn lưu** (`media_curric`=2; re-upload là tạo lại).
4. **Vercel project dormant** xóa được.
5. **`seed_007` repo** — body_template "Bé " thừa (đã UPDATE live, chỉ lệch file repo).

> ✅ **Đã gạch khỏi việc treo:** dọn data test KHM · lưu repo mig 040+school.tsx · cosmetic v20 · SPF kép (v19) · caption/row test rác (audit xác nhận không tồn tại).

---

## 7. NGÃ KẾ — ĐỀ XUẤT

- **⭐ A — Onboard staff/PH qua app (master mời login):** master tạo GV/PH rồi **mời đăng nhập** — mở rộng Edge `invite_master` cho `lead_teacher`/`parent` (pattern v18 đã có, nhân ra). Đóng vòng "trường tự vận hành KHÔNG cần Jean" trọn vẹn.
- **B — `revoke_share_link` + UI** (đóng nốt vòng đời share link D87 — nút thu hồi tay).
- **C — Tách 4 portal** (hiện gộp 1 `/portal`; RLS scope đã đúng tầng DB — chỉ UI/IA). IA portal vừa được dọn 1 nửa (3 màn admin vào guard) → tách trọn dễ hơn.

**Boot phiên sau:** đọc HANDOFF v21 → audit live (D1) thật trước khi viết.

---

## 8. DATA STATE CẦN NHỚ (bẫy cho phiên sau)

- **KHM-DN `sharing_mode=private_share_link`** (KHÔNG phải `no_external_sharing`).
- **Consent An `private_share_link` (`d1…e1`) đang WITHDRAWN** (`withdrawn_at` 2026-06-26 04:22). Muốn test share lại phải `UPDATE … SET withdrawn_at=NULL`.
- **3 tenant / 3 master** sạch (DEMO-001 1lớp/2trẻ · KHM 2/8 · MNDM 2/6 = 5 lớp/16 trẻ).
- **PH 051 mỗi trường = 2-con-xuyên-lớp** (persona test multi-child cross-class).
- **`master_admin` ∈ `is_school_admin()`** → master tự được mọi RLS write same_school; PH `school_id=NULL` cần RPC curated cho cả ghi (D29) lẫn đọc (D92).
- **`link_role` mới lưu CODE** `mother`/`father`/`guardian`; legacy seed = `primary`/`secondary` (UI render cả hai).

---

> **KỶ LUẬT VÀNG:** đã cập nhật RULES (+D92, footer v21) + SYSTEM_MAP (dòng nghiệm thu v21, bump v0.21, hàm 45→46, mig→041, route 3 màn admin về `_authenticated` bỏ `rls-test`) trong phiên này. 3 file xuất kèm: `DMA_HANDOFF_v21.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md`. **File SQL repo:** `040_master_self_manage.sql` · `041_get_child_parents.sql`. **Tài liệu A–G, START_HERE, BUILD_PATH, DMWS_REFERENCE: KHÔNG đổi.**
