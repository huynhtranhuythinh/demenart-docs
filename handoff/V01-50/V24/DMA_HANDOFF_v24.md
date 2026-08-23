# 🤝 DMA_HANDOFF_v24.md — BÀN GIAO PHIÊN (NGÃ A — TÁCH CỔNG PHỤ HUYNH `/parent` + ROUTING THEO VAI — 2026-06-27 22:22 GMT+7)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v24. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

**Ngã A (đề xuất v23 §8) — bắt đầu TÁCH 5 CỔNG, slice đầu = cổng Phụ Huynh `/parent`.** Trước nay mọi vai gộp 1 shell `/portal/*` (nav icon kiểu SaaS chìa cho cả PH — thấy Music/Camera/School vô nghĩa). Phiên này **carve PH ra không gian album ấm riêng**, slice nhỏ-đúng (push back big-bang 4-namespace). Staff + Admin tạm giữ `/portal`, tách phiên sau.

- **⭐ Quyết B (incremental, KHÔNG big-bang):** tách **PH trước** vì giá-trị-linh-hồn cao nhất + rủi ro thấp nhất; còn lại chừa namespace.
- **A — Shell PH ấm:** `_authenticated/parent.tsx` (nền amber, header "Nhật ký của con", nav gọn Album·Quyền riêng tư·Hỗ trợ·🔔; BỎ Music/Camera/School của staff).
- **B — Dời 2 page PH-thuần:** rename file-based `portal.journal`→`parent.journal`, `portal.consent`→`parent.consent` (đổi route-id + sửa cầu consent D94 `/portal/consent`→`/parent/consent`).
- **C — Routing theo vai:** `lib/home-path.ts` (`homePathForRole`) — PH→`/parent/journal`, còn lại→`/portal`; wire vào `auth.tsx` (2 chỗ) + `index.tsx`.
- **⭐ Quyết sửa sai (Jean bắt):** notifications/support **KHÔNG** ép vào `/parent` — chúng là **hạ-tầng-toàn-App** (mọi vai gửi/nhận) → giữ `/portal/notifications` + `/portal/support`, shell PH chỉ **link tới**, KHÔNG nhân đôi component.

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc — KHÔNG ĐỔI:** **46 bảng · 50 hàm SECURITY DEFINER · 125 RLS policy · mig 001→044 · seed 001→012.** SYSTEM_MAP **v0.24** (bump vì IA/route đổi, schema KHÔNG đổi). **Phiên thuần UI/IA — KHÔNG mig, KHÔNG Edge.**
- **Edge Functions (6 — KHÔNG đổi):** `get_signed_media_url` · `upload_media` · `resolve_share_link` · `invite_master` · `invite_staff` · `invite_parent`.
- **3 tenant / 3 master** (DEMO-001 · KHM-DN · MNDM-DN).

### Routes app — sau phiên này
- **CỔNG PH `/parent` (MỚI):** shell `_authenticated/parent.tsx` + `parent.index` (redirect→`/parent/journal`) + `parent.journal` + `parent.consent`. Nav: Album(`/parent/journal`)·Quyền riêng tư(`/parent/consent`)·Hỗ trợ(`/portal/support`)·🔔(`/portal/notifications`).
- **CỔNG STAFF/ADMIN `/portal/*` (GIỮ NGUYÊN):** shell `_authenticated/portal.tsx` (nav 4-vai cũ). Pages còn lại: `curriculum`·`moments`·`school`·`notifications`·`support`·`school-onboarding`·`sensitive-access`·`curriculum-admin`·`modules`·`index`.
- **Public ngoài shell:** `/share/$token` (KHÔNG đụng).
- **Routing vào app:** `index.tsx` nút "Vào hệ thống" + `auth.tsx` sau login → `homePathForRole(role)`: `primary_parent`/`secondary_parent`→`/parent/journal`, còn lại→`/portal`.

> **Auto-synced Lovable→GitHub** (không lưu tay). Migration/Edge KHÔNG phát sinh phiên này.

---

## 3. FILE UI PHIÊN NÀY (Lovable editor, áp tay — KHÔNG nhờ AI Lovable, D5/D14)

**TẠO mới:**
- `_authenticated/parent.tsx` — shell PH ấm (FULL paste-over).
- `_authenticated/parent.index.tsx` — `beforeLoad` redirect→`/parent/journal`.
- `lib/home-path.ts` — `homePathForRole(role)` một-nguồn routing theo vai.

**RENAME (đổi tên file + sửa anchor TÌM/THAY độc lập):**
- `portal.journal.tsx` → `parent.journal.tsx`: route-id `/_authenticated/portal/journal`→`/_authenticated/parent/journal` + cầu consent `<Link to="/portal/consent">`→`/parent/consent`.
- `portal.consent.tsx` → `parent.consent.tsx`: route-id `/_authenticated/portal/consent`→`/_authenticated/parent/consent`.

**SỬA (FULL paste-over — vì sửa nhiều chỗ):**
- `routes/index.tsx` — import `homePathForRole`, state `home`, set sau getSession, nút `<Link to={home as any}>`.
- `routes/auth.tsx` — import `homePathForRole`, helper `resolveHome(userId)`, wire vào getSession-effect + handleSubmit (thay 2 `navigate({to:"/portal"})`).

> **⭐ BÀI HỌC PHIÊN NÀY (D95 — D5/D6 sống lại):** lần đầu em hướng dẫn `index.tsx`/`auth.tsx` kiểu **prose mơ hồ** ("thêm vào đầu file", "set sau getSession") → Lovable dán `import` LẪN comment vào **giữa khối JSX** → **build vỡ**. Jean bắt đúng: "sandbox TÌM và THAY phải độc lập". → **Sửa nhiều-chỗ = FULL paste-over** (bôi đen Cmd+A, dán đè), KHÔNG bao giờ prose vị-trí-tương-đối. TÌM/THAY chỉ dùng khi 1 khối OLD-exact ↔ 1 khối NEW-exact tự-đứng-được (như route-id + link consent).

---

## 4. NGHIỆM THU LOGIN THẬT (D2/D3) — ĐẠT

**PH Nguyễn Văn Hùng** (KHM, **`ph.hung.kidshouse@demo.demenart.com`** / `Test@123`):
1. Login → đáp thẳng **`demenart.com/parent/journal`** — shell amber, header "Nhật ký của con / Dế Mèn Art", nav PH sạch (Album·Quyền riêng tư·Hỗ trợ·🔔·tên), **KHÔNG** còn Music/Camera/School. ✅
2. Hành trình hiện đa-môn (CTAN 24/6 + Ballet 23/6 + CTAN 19/6 — thép chờ #1 v17 sống) + Khoảnh khắc có ảnh nhóm. ✅
3. (Ngụ ý) cầu consent D94 đã trỏ `/parent/consent` (sửa anchor). ✅

**Master Huỳnh Trần Nguyệt Thi** (KHM, **`hieutruong.kidshouse@demo.demenart.com`** / `Test@123`):
1. Login → vẫn về **`demenart.com/portal`** shell staff cũ (Quản lý Trường + icon row), KHÔNG vỡ. `role=master_admin`, `school_id=d1…001`. ✅

> **Routing theo vai sống**: PH→`/parent`, staff→`/portal`. Engine v3–v14 + 8 cụm RLS + 50 hàm definer KHÔNG sửa 1 dòng — đây là phiên thuần IA.

---

## 5. ⭐ BẢNG TÀI KHOẢN TEST (Jean yêu cầu đưa vào thư viện — mỗi lần nhờ test PHẢI ghi email kèm)

> Tất cả `@demo.demenart.com`, password **`Test@123`** (auto-confirm), trừ 2 login giữ-từ-v22 dùng password tạm.

| Vai | Email | Người / Trường |
|---|---|---|
| **Master KHM** | `hieutruong.kidshouse@demo.demenart.com` | Huỳnh Trần Nguyệt Thi · KHM |
| **GV KHM** | `gv.linh.kidshouse@demo.demenart.com` | Đặng Mỹ Linh · KHM |
| **PH KHM** (2-con An+Khang) | `ph.hung.kidshouse@demo.demenart.com` | Nguyễn Văn Hùng · school NULL |
| **Master MNDM** | `hieutruong.demen@demo.demenart.com` | Mai Phương Dung · MNDM |
| **GV MNDM** | `gv.han.demen@demo.demenart.com` | Bùi Ngọc Hân · MNDM |
| **PH MNDM** (2-con Hà+Phúc) | `ph.thanh.demen@demo.demenart.com` | Đặng Văn Thành · school NULL |
| GV KHM (giữ v22, password tạm) | `gv.my.kidshouse@demo.demenart.com` | Lê Thảo My · KHM |
| PH KHM (giữ v22, password tạm) | `ph.toan.kidshouse@demo.demenart.com` | Trần Quốc Toản · KHM |

---

## 6. VIỆC TREO (ưu tiên giảm dần)

1. 🔴 **Lưu repo (nợ dồn):** Edge `invite_staff.ts` + `invite_parent.ts` (nợ v22) **+** `044_revoke_share_link.sql` (nợ v23). Dump trung thực từ live (D90). *Phiên v24 KHÔNG phát sinh file SQL/Edge mới — UI auto-synced.*
2. **Tách nốt 4 cổng còn lại** (Ngã A tiếp): `/teacher` (curriculum·moments) · `/school` · `/admin` (school-onboarding·sensitive-access·curriculum-admin·modules) · `/kid` reserved. Mẫu PH (`parent.tsx` + `home-path.ts`) đã là khuôn.
3. 🧹 **Gỡ nút "Bảng Test RLS"** trong `portal.index.tsx` — route `portal.rls-test` đã xóa v21, nút còn trỏ → bấm ra **Not Found** (xác nhận live v24). Cosmetic, dọn khi làm cổng staff.
4. **GV/PH pilot còn lại chưa login** (4 GV + 9 PH) → mời nốt qua app khi cần (engine D93 đủ).
5. **2 file curriculum media chưa có nguồn lưu** (`media_curric`=2) · **Vercel project dormant** xóa được · **`seed_007` repo** body_template "Bé " thừa (đã UPDATE live, chỉ lệch file repo).

> ✅ **Đã gạch:** tách cổng PH `/parent` (shell ấm + 2 page PH-thuần) · routing theo vai `homePathForRole` · sửa phân loại notifications/support (giữ `/portal` toàn-App).

---

## 7. NGÃ KẾ — ĐỀ XUẤT

- **⭐ A — Tách cổng Teacher `/teacher`** (curriculum player + moments upload) theo khuôn `parent.tsx`: shell GV (đọc-học-liệu + upload ảnh lớp), routing `lead_teacher`/`assistant_teacher`→`/teacher`. Slice kế tự nhiên của Ngã A.
- **B — Tách cổng School `/school`** (3 tab quản trường hiện ở `/portal/school`) + chốt quan hệ School↔Teacher "2 portal thông nhau" ở tầng IA (GV vào `/school` read-only Quyết B).
- **C — Tách cổng Admin `/admin`** (gom school-onboarding·sensitive-access·curriculum-admin·modules) + dọn nút rls-test.
- **D — Dọn nợ repo** (2 Edge v22 + `044` v23) — phiên hạ tầng thuần, dump trung thực D90.

**Boot phiên sau:** đọc HANDOFF v24 → audit live route tree (D1) thật trước khi viết.

---

## 8. DATA STATE CẦN NHỚ (bẫy cho phiên sau — GIỮ từ v23)

- **KHM-DN `sharing_mode=private_share_link`** (KHÔNG phải `no_external_sharing`).
- **Consent An `private_share_link` (`d1…e1`) = GRANTED** (đổi WITHDRAWN→GRANTED ở v23 để test, để vậy) **+ download consent An bật.**
- **3 tenant / 3 master** (DEMO-001 1lớp/2trẻ · KHM 2/8 · MNDM 2/6 = 5 lớp/16 trẻ).
- **PH 051 mỗi trường = 2-con-xuyên-lớp** (persona multi-child, CÙNG-trường, KHÔNG xuyên-trường).
- **Role PH thật trong DB = `primary_parent`** (13 dòng; KHÔNG có `secondary_parent` hiện tại — nhưng `homePathForRole` để ngỏ cả hai).
- **2 login giữ từ v22:** GV Lê Thảo My + PH Trần Quốc Toản.
- **`link_role` lưu CODE** `mother`/`father`/`guardian`; legacy seed = `primary`/`secondary` (UI render cả hai).
- **`master_admin` ∈ `is_school_admin()`**; PH `school_id=NULL` cần RPC curated cho ghi (D29) lẫn đọc (D92).
- **Engine media-nhạy-cảm = 5 gate secdef nhận-tham-số:** consent ảnh trẻ (D71) · entitlement học liệu (D75) · upload (D77) · share (D87) · revoke (D94).

---

> **KỶ LUẬT VÀNG:** đã cập nhật **RULES** (+D95 tách-portal-theo-vai & bài-học-FULL-paste-over, footer v24) + **SYSTEM_MAP** (bump v0.24, dòng nghiệm thu v24, route map `/parent` vs `/portal`, +bảng TK test, +5-cổng) + **START_HERE** (§2 "Bốn cổng"→"Năm cổng", thêm dòng Kid `/kid` reserved) trong phiên này. **4 file xuất kèm:** `DMA_HANDOFF_v24.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md` · `DMA_00_START_HERE.md`. **KHÔNG file SQL/Edge mới** (phiên thuần UI, auto-synced). **Tài liệu A–G, BUILD_PATH, DMWS_REFERENCE: KHÔNG đổi.**
