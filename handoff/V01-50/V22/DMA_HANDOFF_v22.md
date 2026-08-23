# 🤝 DMA_HANDOFF_v22.md — BÀN GIAO PHIÊN (ĐÓNG NGÃ A TRỌN: ONBOARD STAFF/PH QUA APP — 2026-06-27 19:07 GMT+7)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v22. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

**Ngã A — onboard staff/PH qua app (master mời login).** Đóng nốt vòng "trường tự vận hành KHÔNG cần Jean": v20 master tự thêm lớp/GV/trẻ/PH; v22 master **tự mời họ đăng nhập**. Nhân pattern `invite_master` (v18) ra cho GV và PH.

- **A1 — Mời GV (lead/assistant):** mig 042 (`list_school_invitees` + `link_school_user`) + Edge `invite_staff` + nút "Mời đăng nhập" tab Giáo viên. Gate caller master/sub + target **same_school** (GV có `school_id` → so thẳng).
- **A2 — Mời PH (primary/secondary_parent):** mig 043 (`link_parent_user`) + Edge `invite_parent` + nút "Mời đăng nhập" trong `ParentsPanel`. Gate caller master/sub + **PH có ≥1 con trong trường caller** (PH `school_id=NULL` → đi vòng `child_parents→enrollments→classes.school_id`).
- Cả hai: `createUser` auto-confirm + **password tạm dùng-một-lần** (dialog hiện 1 lần + copy, KHÔNG vào audit/console) → link `user_id` qua RPC secdef+replica (D89) → audit actor=caller.id (D88).

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc:** **46 bảng · 49 hàm SECURITY DEFINER · 125 RLS policy · mig 001→043 · seed 001→012.** SYSTEM_MAP **v0.22.**
  - +3 hàm v22: `list_school_invitees` (auth+svc, curated read), `link_school_user` (**service_role only**, secdef+replica), `link_parent_user` (**service_role only**, secdef+replica).
  - mig 042+043 **KHÔNG thêm bảng/cột/enum/policy** — chỉ 3 RPC. 125 policy KHÔNG đổi.
- **Edge Functions (6 — +2):** `get_signed_media_url` · `upload_media` · `resolve_share_link` · `invite_master` · **`invite_staff`** · **`invite_parent`** (cả 2 mới Verify JWT OFF).
- **Routes app:** `school.tsx` (`/portal/school`) cập nhật — tab Giáo viên + `ParentsPanel` thêm badge "Đã đăng nhập" / nút "Mời đăng nhập" + `InviteResultDialog` (dùng chung GV/PH).
- **3 tenant / 3 master sạch** (DEMO-001 · KHM-DN · MNDM-DN).
- **Login mới phiên này (nghiệm thu, dùng password tạm):** GV KHM Lê Thảo My (`gv.my.kidshouse@…`, `assistant_teacher`) · PH KHM Trần Quốc Toản (`ph.toan.kidshouse@…`, `primary_parent`). **2 login mới này GIỮ trong DB** (đã đổi `user_id`, không xóa).
- **Data state (giữ từ v17):** KHM-DN `sharing_mode=private_share_link`; consent An `private_share_link` (`d1…e1`) **WITHDRAWN**.

> ⚠️ Sau phiên: GV/PH chưa login còn lại = **4 GV** (KHM 2, MNDM 2) + **9 PH** (đã mời 1/10). Có thể mời nốt qua app khi cần.

---

## 3. mig 042 + 043 — invite_staff/invite_parent (D93)

### A1 — mig 042 (2 RPC)
- **`list_school_invitees() → jsonb`** (auth+svc, curated): master/sub đọc GV `user_id IS NULL` cùng `school_id`. *(UI hiện KHÔNG dùng hàm này — TeachersTab query `profiles` + `user_id` trực tiếp, RLS same_school lọc sẵn; hàm giữ cho API/dùng sau.)*
- **`link_school_user(p_profile_id, p_user_id) → jsonb`** (**service_role only**, secdef+replica D89): gate target role ∈ lead/assistant + `user_id IS NULL`; `set local session_replication_role = replica` bỏ qua guard.

### A2 — mig 043 (1 RPC)
- **`link_parent_user(p_profile_id, p_user_id) → jsonb`** (**service_role only**, secdef+replica): gate target role ∈ primary/secondary_parent + `user_id IS NULL`. Đối xứng `link_school_user`.

### ⭐ Gate same-school: GV vs PH (điểm khác cốt lõi A1↔A2)
- **GV** có `school_id` → Edge `invite_staff` so thẳng `staff.school_id === caller.school_id`.
- **PH `school_id=NULL`** (D40) → Edge `invite_parent` đi vòng: `child_parents(parent)→child_id` → `enrollments(child)→class_id` → `classes.school_id`; kiểm có ≥1 con trong trường caller. *(Gương D40/D92 — "PH của trường mình" phải qua trẻ.)*

### Bài học hạ tầng lặp lại (D92 sống tiếp)
- mig 042 lần đầu: chạy cả CREATE+harden+verify một lần → verify query lệch trả `null grants` (proacl NULL đánh lừa); chạy lại tách CREATE riêng → OK; harden khối riêng → sạch `leaky=[]`. **Quy tắc D92 đứng:** CREATE riêng, REVOKE/GRANT khối riêng, verify soi `proacl` KHÔNG gọi hàm.

---

## 4. NGHIỆM THU LOGIN THẬT (D2/D3)

### A1 — GV (4 phép thử + bonus, ĐẠT)
1. **Master KHM mời GV chưa login** → dialog password tạm `Dma#xRbTflkLnEmpyM` + copy + cảnh báo một-lần + toast xanh; badge đổi "Đã đăng nhập". ✅
2. **GV Lê Thảo My login bằng password tạm** → portal "Xin chào… assistant_teacher" KHÔNG kẹt "chưa kích hoạt" (**D89 sống** — `link_school_user` gắn user_id qua guard). ✅
3. **GV read-only (Quyết B)** → cả 3 tab: banner "chỉ đọc", KHÔNG form ghi, KHÔNG nút Mời. ✅
4. **Isolation** → danh sách chỉ 4 GV KHM, KHÔNG GV MNDM. ✅
5. **Bonus:** GV chọn bé → `get_child_parents` toast đỏ "không có quyền" (D92 gate master/sub-only chặn GV). ✅

### A2 — PH (3 phép thử + same-school CỨNG, ĐẠT)
1. **Master KHM mời PH Trần Quốc Toản** (con Bình) → dialog `Dma#9bdi64BPONqIoU`; badge đổi xanh. ✅
2. **PH login bằng password tạm** → portal "primary_parent" KHÔNG kẹt; vào `/portal/journal` thấy **"Nhật ký của con — thuộc về con và gia đình"** (**linh hồn DMA ở giao diện thật**). ✅
3. **⭐ Same-school CỨNG (fetch JWT thật, KHÔNG qua UI):** master KHM gọi thẳng Edge `invite_parent` với ID PH Hoàng Văn Nam (MNDM) → **`403 {ok:false, error:"different_school"}`**. Gate đường-vòng `child_parents` đứng vững dù né UI. ✅

> **Cách test gate cứng cho hàm gọi-từ-Edge:** app KHÔNG expose client ra `window` → dùng `fetch` thẳng tới Edge endpoint với access_token lấy từ `localStorage` (key `sb-<ref>-auth-token`), project ref parse từ tên key. JWT thật → gate chạy đúng (khác SQL Editor `auth.uid()=NULL` — D2).

---

## 5. FILE REPO PHIÊN NÀY (đặt cạnh 001–041)

- `042_invite_staff.sql` — 2 RPC A1 (gồm block harden + ghi chú verify).
- `043_invite_parent.sql` — 1 RPC A2.
- `school.tsx` — **đã auto-synced** qua Lovable→GitHub (không cần lưu tay).
- Edge `invite_staff.ts` + `invite_parent.ts` — **CHƯA lưu repo** (nợ Edge, xem §6).

> Migration SQL chạy tay → phải lưu tay. Code Lovable auto-publish. Edge Function phải copy `.ts` lưu tay (không auto-sync repo).

---

## 6. VIỆC TREO (ưu tiên giảm dần)

1. **Lưu repo Edge `invite_staff.ts` + `invite_parent.ts`** (nợ mới — 2 Edge phiên này chưa có `.ts` trong repo).
2. **`revoke_share_link` + UI** (D87 — share link chỉ tự-chết qua expiry/rút-consent; chưa có nút thu hồi tay).
3. **GV/PH còn lại chưa login** (4 GV + 9 PH) → mời nốt qua app khi cần (engine đã đủ).
4. **2 file curriculum media chưa có nguồn lưu** (`media_curric`=2).
5. **Vercel project dormant** xóa được.
6. **`seed_007` repo** — body_template "Bé " thừa (đã UPDATE live, chỉ lệch file repo).

> ✅ **Đã gạch:** onboard staff/PH qua app (A1+A2) · same-school gate nghiệm thu cứng.

---

## 7. NGÃ KẾ — ĐỀ XUẤT

- **⭐ A — `revoke_share_link` + UI** (đóng nốt vòng đời share link D87 — nút thu hồi tay; slice nhỏ gọn).
- **B — Tách 4 portal** (hiện gộp 1 `/portal`; RLS scope đã đúng tầng DB — chỉ UI/IA; IA đã dọn 1 nửa ở v21).
- **C — Dọn nợ repo** (lưu 2 Edge `.ts` v22 + nợ cũ; phiên hạ tầng thuần).

**Boot phiên sau:** đọc HANDOFF v22 → audit live (D1) thật trước khi viết.

---

## 8. DATA STATE CẦN NHỚ (bẫy cho phiên sau)

- **KHM-DN `sharing_mode=private_share_link`** (KHÔNG phải `no_external_sharing`).
- **Consent An `private_share_link` (`d1…e1`) đang WITHDRAWN** (`withdrawn_at` 2026-06-26 04:22). Test share lại phải `UPDATE … SET withdrawn_at=NULL`.
- **3 tenant / 3 master** (DEMO-001 1lớp/2trẻ · KHM 2/8 · MNDM 2/6 = 5 lớp/16 trẻ).
- **PH 051 mỗi trường = 2-con-xuyên-lớp** (persona multi-child, xuyên-lớp CÙNG-trường — KHÔNG xuyên-trường).
- **2 login mới v22:** GV Lê Thảo My + PH Trần Quốc Toản (giữ trong DB).
- **`link_role` lưu CODE** `mother`/`father`/`guardian`; legacy seed = `primary`/`secondary` (UI render cả hai).
- **`master_admin` ∈ `is_school_admin()`**; PH `school_id=NULL` cần RPC curated cho cả ghi (D29) lẫn đọc (D92); gate same-school PH đi vòng `child_parents` (D93).

---

> **KỶ LUẬT VÀNG:** đã cập nhật RULES (+D93, footer v22) + SYSTEM_MAP (dòng nghiệm thu v22, bump v0.22, hàm 46→49, mig→043, +2 Edge invite_staff/invite_parent) trong phiên này. 3 file xuất kèm: `DMA_HANDOFF_v22.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md`. **File SQL repo:** `042_invite_staff.sql` · `043_invite_parent.sql`. **Tài liệu A–G, START_HERE, BUILD_PATH, DMWS_REFERENCE: KHÔNG đổi.**
