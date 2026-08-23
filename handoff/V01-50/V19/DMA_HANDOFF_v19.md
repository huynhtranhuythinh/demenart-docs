# 🤝 DMA_HANDOFF_v19.md — BÀN GIAO PHIÊN (NGÃ B: TRẢ NỢ REPO + SPF — 2026-06-26 23:54 GMT+7)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v19. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

**Ngã B — trả nợ hạ tầng (KHÔNG đụng schema/feature).** Đóng nốt món nợ repo dồn từ v12 + dọn DNS. Triết lý xuyên suốt: **dump trung thực từ DB sống (D1/D90), KHÔNG chép tay từ trí nhớ chat** — sai 1 ký tự = backup hỏng câm.

- **Lưu repo (nợ dồn v12):** 14 hàm SECURITY DEFINER mig 026–039 + grant + cột mig 030 + 4 Edge + seed pilot 010–012 → đóng gói thành file đặt repo trên máy.
- **SPF kép → gộp 1 record.**
- **`bunny-sign-test`:** xác nhận đã xoá (mục library cũ còn lag → gỡ).

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc — KHÔNG ĐỔI:** **46 bảng · 43 hàm SECURITY DEFINER · 125 RLS policy · mig 001→039 · seed 001→012.** SYSTEM_MAP **v0.19 (không bump — phiên hạ tầng thuần).**
- **Edge Functions:** `get_signed_media_url` · `upload_media` · `resolve_share_link` · `invite_master` (4 — không đổi).
- **3 tenant / 3 master:** `DEMO-001` · `KHM-DN` · `MNDM-DN`.
- **DNS (Cloudflare live):** **14 records**, **1 SPF** duy nhất `"v=spf1 include:secureserver.net -all"` (bản kép hỏng `"TXT value:…flockmail/hostinger/mailchannels"` đã xoá). Email GoDaddy `info@demenart.com` nguyên vẹn.
- **`bunny-sign-test`:** không còn (đã xoá).

---

## 3. TÀI SẢN PHIÊN NÀY → ĐÃ CÓ BẢN LƯU REPO

Mỗi file = **1 ô dump-cell từ live**, zero chép tay (D90). Cấu trúc `/migrations` + `/functions` + `/seeds`:

| File | Nội dung | Cách lấy |
|---|---|---|
| `/migrations/026_039_functions.sql` | 14 hàm definer 026–039 (đã gồm fix inline 030/036b/037b/039), idempotent CREATE OR REPLACE | `pg_get_functiondef` |
| `/migrations/026_039_grants_and_column.sql` | GRANT/REVOKE 14 hàm theo `proacl` LIVE + cột mig 030 `linked_moment_id`+FK. **Chạy SAU file functions** (CREATE OR REPLACE reset grant về PUBLIC) | `aclexplode(proacl)` + `format_type`/`pg_get_constraintdef` |
| `/functions/get_signed_media_url.ts` · `upload_media.ts` · `resolve_share_link.ts` · `invite_master.ts` | 4 Edge (Verify JWT OFF) | copy Dashboard |
| `/seeds/seed_010_012_pilots.sql` | seed pilot KHM-DN + MNDM-DN (KHÔNG gồm DEMO-001 đã ở repo 001–009), idempotent | `to_jsonb`+`jsonb_populate_record`+`ON CONFLICT DO NOTHING` |
| `MANIFEST.md` | mô tả gói + thứ tự phục hồi | Claude |

**Grant đã soi đúng ranh giới:** `link_master_user` · `write_audit_log` · `create_notification` = **service_role only** ✓ (D72/D89). Còn lại authenticated+service_role.

**Seed đối chiếu KHỚP audit từng bảng:** schools 2 · school_subscriptions 2 · entitlements 3 · profiles 21 · classes 4 · children 14 · enrollments 14 · child_parents 14 · consents 13 · child_journey 9 · learning_moments 5 · moment_children 5 · media_assets 2. Phần dư global đều quy đúng DEMO-001 (không sót/không trộn).

**2 quyết định an-toàn-phục-hồi trong seed:** (a) `profiles.user_id` ép NULL (DB trắng auth.users rỗng → seed cứng = FK-fail; phục hồi xong re-invite); (b) `schools.master_profile_id` seed NULL → UPDATE cuối (vòng chicken-egg school↔master).

> **Động tác tay còn lại của anh:** bỏ 6 file vào repo trên máy. App đang chạy KHÔNG phụ thuộc các file này (hàm sống ở DB, Edge sống ở Supabase) — đây thuần backup-dự-phòng.

---

## 4. VIỆC TREO (ưu tiên giảm dần) — đã GỠ repo-debt + SPF + bunny-sign-test

1. **`revoke_share_link` + UI** (D87 — share link hiện chỉ tự-chết qua expiry/rút-consent; chưa có nút thu hồi tay).
2. **Profile GV/PH còn lại chưa có login** (chỉ master + vài vai đã invite).
3. **2 file curriculum media chưa có nguồn lưu** (`media_curric`=2; re-upload là tạo lại — KHÔNG nằm trong seed pilot).
4. **Vercel project dormant** xóa được (tách khỏi Cloudflare Pages).
5. **Vụn cũ:** sửa `seed_007` repo (body_template "Bé " thừa — đã UPDATE live) · caption "[seed]"/row test rác trong DB (UI đã strip client).

---

## 5. NGÃ KẾ — ANH ĐÃ CHỌN **A**

- **⭐ A — Master tự quản trường (mở phiên mới):** master login được rồi → màn master tự thêm **lớp / GV / trẻ** (mở rộng portal Trường). Mảnh logic tiếp của onboarding: trường mới tự vận hành KHÔNG cần Jean seed tay. *(Nền tảng đã sẵn: `profiles_insert_provision` cho school_admin tạo lead_teacher/parent; chỉ cần RPC + UI cho master.)*
- D-next.2 — `revoke_share_link` + UI (đóng nốt vòng đời share link).
- F — Onboard staff/PH qua app (RPC + UI tạo GV/PH).

**Boot phiên A:** đọc HANDOFF v19 → audit live (D1) màn/portal Trường hiện có + RLS write cụm Org/People (D58 same_school) trước khi viết RPC master-self-manage.

---

## 6. DATA STATE CẦN NHỚ (bẫy cho phiên sau — giữ từ v17/v18)

- **KHM-DN `sharing_mode=private_share_link`** (KHÔNG phải `no_external_sharing`).
- **Consent An `private_share_link` (`d1…e1`) đang WITHDRAWN** (`withdrawn_at` 2026-06-26 04:22). Muốn test share lại phải `UPDATE … SET withdrawn_at=NULL`. *(seed_010_012 đã giữ trung thực trạng thái WITHDRAWN này — D90: snapshot không "dọn đẹp".)*
- **3 tenant / 3 master** sạch.
- **PH 051 mỗi trường = 2-con-xuyên-lớp** (persona test multi-child cross-class).

---

> **KỶ LUẬT VÀNG:** cập nhật RULES (+D90, footer v19) + SYSTEM_MAP (bullet v19 + dọn việc-treo, KHÔNG bump version) trước khi đóng — patch kèm phiên này (`DMA_v19_library_patches.md`).
