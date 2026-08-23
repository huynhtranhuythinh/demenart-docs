# 🤝 DMA_HANDOFF_v18.md — BÀN GIAO PHIÊN (NGÃ D: ADMIN ONBOARDING UI — 2 LỚP)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v18. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

**Ngã D — biến "onboard trường = viết SQL tay" thành SẢN PHẨM.** Trọn **2 lớp**, nghiệm thu **login thật trên LIVE `demenart.com`** (D3).

- **🔹 LỚP 1 — Onboard trường qua app (mig 037/037b + UI):** super_admin điền form → 1 RPC `onboard_school` tạo TRỌN tenant: school + subscription (tự tính total từ `pricing_config`) + N entitlements + master profile (`user_id=NULL`) + audit. Màn `/portal/school-onboarding` (form + bảng tính tiền realtime + card kết quả).
- **🔹 LỚP 2 — Mời master đăng nhập (mig 038/039 + Edge `invite_master` + UI):** super_admin bấm "Mời đăng nhập" → Edge tạo `auth.users` auto-confirm + password tạm DÙNG-MỘT-LẦN + link `profiles.user_id` → master login thật vào portal. Section "Mời chủ trường" thêm vào cuối màn onboarding.

**Vòng đời khép kín 100% qua app:** điền form → tạo tenant → mời master → master nhận password → **login thật vào portal đúng trường đúng vai**. Không viết SQL tay, không vào Dashboard.

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc:** **46 bảng** · **43 hàm SECURITY DEFINER** (+`onboard_school` +`list_masters_without_login` +`link_master_user`) · **125 RLS policy** · mig **001→039**. SYSTEM_MAP v0.19.
- **Seed:** **001→012** (KHÔNG thêm — phiên này là chức năng, không seed).
- **Edge Functions:** `get_signed_media_url` · `upload_media` · `resolve_share_link` · **`invite_master`** (mới — Verify JWT OFF, tự gác).
- **RPC mới:** `onboard_school` (grant authenticated) · `list_masters_without_login` (grant authenticated) · `link_master_user` (grant **service_role only** — Edge gọi).
- **Routes UI:** `/portal/school-onboarding` (onboard trường + section mời master).
- **3 tenant LIVE:** `DEMO-001` · `KHM-DN` · `MNDM-DN` (Sao Mai test đã tạo-rồi-xoá sạch gồm cả auth.users — DB về đúng 3 tenant / 3 master).

---

## 3. 4 LỖI LOGIN-THẬT BẮT ĐƯỢC (D2/D3 đúng tuyệt đối — SQL-pass che hết)

Onboarding chạm tới auth.admin + guard → lộ 4 lớp lỗi mà verify SQL Editor KHÔNG thấy:

1. **Preview sandbox Lovable lỗi ≠ deploy thật.** "We couldn't start the live preview" chỉ là sandbox Lovable; bản LIVE `demenart.com` vẫn chạy. Đừng nhầm → đừng bấm "Try to fix all" (D5).
2. **409 PostgREST → thực ra 23503 FK.** Banner "lỗi kỹ thuật" mơ hồ; mở Network Response mới thấy `code:23503`.
3. **⭐ D88 — `audit_logs.actor_id` FK→`profiles.id`, KHÔNG `auth.uid()`.** RPC truyền `auth.uid()` (=auth.users.id) → FK gãy → rollback CẢ giao dịch → DB rỗng (audit=NULL đánh lừa "chưa chạy"). SQL Editor che vì `auth.uid()=NULL`→audit nhận NULL (nullable)→không chạm FK.
4. **⭐ D89 — Service_role bypass RLS NHƯNG KHÔNG bypass trigger.** Edge `.update({user_id})` không throw nhưng guard `trg_guard_profiles_protected` NUỐT lại (`auth.uid()=NULL` trong Edge → `is_admin()=false` → ghim `user_id:=old`=NULL). Auth tạo được (login pass) nhưng profile chưa gắn → portal "chưa kích hoạt". Lỗi CÂM.

→ 2 luật mới **D88 + D89** (xem RULES).

---

## 4. NGHIỆM THU LOGIN THẬT (bằng chứng vàng)

**Lớp 1:** super_admin `info@demenart.com` `/portal/school-onboarding` → onboard "Trung Tâm Nghệ Thuật Sao Mai" (SAO-MAI-HN, CTAN, 3 seat) → **card xanh** "✓ Đã tạo trường" + total **6.500.000** (1 môn×5tr + 3 GV×500k). Verify server-side: school+sub(trial,total đúng)+1 entitlement(CTAN trial)+master(user_id NULL)+audit `school_onboarded` (**actor_is_profile=true** chứng minh fix 037b) đủ; tenant_count=4.

**Lớp 2:** bấm "Mời đăng nhập" → card xanh + password tạm `Dma#...` hiện 1 lần + nút copy → tab ẩn danh login master email+password → ban đầu "chưa kích hoạt" (bắt được D89) → vá mig 039 + fix link → refresh → **"Xin chào, Cô Nguyệt Minh · master_admin · School ID ..."** vào portal thật.

**Bài học vàng:** onboarding đụng auth.admin + guard = 4 tầng lỗi login-thật. Engine đọc/ghi (v3–v14) + RLS (8 cụm) KHÔNG sửa gì — tenant tạo qua app tự được mọi engine phục vụ.

---

## 5. VIỆC TREO (ưu tiên giảm dần)

1. **🔴 Lưu repo — NỢ DỒN TỪ v12:** mig **026–039** + seed **010–012** + **4 Edge** (`get_signed_media_url`/`upload_media`/`resolve_share_link`/`invite_master`) chưa lưu GitHub. Rủi ro mất = dựng lại. **Ưu tiên cao nhất** — phần lớn là việc tay Jean trên GitHub.
2. **SPF kép** (sai sẵn từ GoDaddy, chuẩn DNS chỉ 1 SPF/domain) — gộp 1 record.
3. **Nút thu hồi share link tay** (D87 — UI chưa có `revoke_share_link`).
4. **Vercel project dormant** xóa được (tách khỏi Cloudflare Pages).
5. Profile GV/PH còn lại chưa có login (chỉ master + vài vai có).

---

## 6. NGÃ KẾ (đề xuất)

- **D-next.1 — Master tự quản trường:** master login được rồi → mở màn master tự thêm lớp/GV/trẻ (mở rộng portal Trường). Đây là mảnh logic tiếp của onboarding: trường mới tự vận hành KHÔNG cần Jean seed tay.
- **D-next.2 — `revoke_share_link` + UI** (đóng nốt vòng đời share link D87).
- **E — Dọn repo + SPF** (trả nợ hạ tầng — nên xen kẽ SỚM vì nợ dồn 14 mig).
- **F — Onboard staff/PH qua app** (RPC tạo lead_teacher/parent — `profiles_insert_provision` đã cho school_admin tạo các vai này, chỉ cần UI).

**Khuyến nghị:** **D-next.1 (master tự quản)** — vì onboarding giờ dừng ở "trường có master login", bước tự nhiên kế là master tự dựng lớp/người. Nhưng **E (lưu repo)** là rủi ro thật, nên trả trước hoặc xen kẽ.

---

## 7. DATA STATE CẦN NHỚ (bẫy cho phiên sau)

- **KHM-DN `sharing_mode=private_share_link`** (từ v17 — KHÔNG phải `no_external_sharing`).
- **Consent An `private_share_link` (`d1…e1`) đang WITHDRAWN** (để vậy sau nghiệm thu v17 — muốn test share lại phải `UPDATE … SET withdrawn_at=NULL`).
- **3 tenant / 3 master** sạch (Sao Mai đã xoá hoàn toàn gồm auth.users).

---

## 8. TÀI SẢN PHIÊN NÀY (file output)

- `037_onboard_school.sql` (bản đầu — có bug actor) · `037b_onboard_school_fix_actor.sql` (FIX D88)
- `038_list_masters_without_login.sql`
- `039_link_master_user.sql` (FIX D89) · `fix_link_sao_mai.sql` (vá tay đã chạy)
- `invite_master_index.ts` (Edge — bản cuối gọi `link_master_user`)
- `delete_sao_mai_full.sql` (xoá test, đã chạy)
- Lovable prompt: onboard form + section mời master

> **KỶ LUẬT VÀNG:** cập nhật RULES (+D88/D89) + SYSTEM_MAP (v0.19) trước khi đóng — ĐÃ làm trong phiên này.
