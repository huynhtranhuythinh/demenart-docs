# 🤝 DMA_HANDOFF_v1.md

> **Phiên:** v1 (khởi tạo library + đồng bộ A–G quanh móng C)
> **Đóng phiên:** 2026-06-24 16:30 (GMT+7)
> **Naming:** DMA = nền tảng; CTAN = module đầu. Không "DMMA".

---

## 0. MỤC LỤC PHIÊN (đã làm gì)
1. Tái dựng bộ A–G từ nguồn (01 Scope Lock + 02 Handoff + prompt media security).
2. Nạp 5 file library DMWS-reference (00/RULES/SYSTEM_MAP/BUILD_PATH/05) → đối chiếu A–G.
3. Hỏi-đáp chốt 6 quyết định móng (xem §2).
4. Ra **móng C v2** (~43 bảng) → anh duyệt.
5. **Cascade trọn A–G** cho khớp móng + cập nhật 4 file library → xuất **11 file tên chuẩn**.
6. Hướng dẫn khởi động (DB-first). Đóng phiên để qua phiên mới cho sạch.

---

## 1. TRẠNG THÁI FILE — ⚠️ VIỆC ĐẦU PHIÊN SAU: anh LƯU 11 file vào Project Knowledge (thay bản cũ)

**A–G (final, đã sync):** `DMA_A_PRD_Foundation` · `DMA_B_IA_UserFlows` · `DMA_C_DataModel_Supabase` (móng) · `DMA_D_PageSpec` · `DMA_E_LovableBuildPlan` · `DMA_F_DemoData_UXWriting_Checklist` · `DMA_G_Media_Security_Architecture`.
**Library (đã cập nhật):** `DMA_00_START_HERE` · `DMA_RULES` (thêm D49/D50/D51, sửa D43/D45) · `DMA_SYSTEM_MAP` (§3 bản đồ bảng, §5 license) · `DMA_BUILD_PATH` (Chặng 2/3/7).
**Không đổi:** `DMA_05_DMWS_REFERENCE` (giữ bản gốc).
> Đã kiểm: không còn "DMMA" (ngoài câu cấm), không sót `class_teachers`/`class_lesson_assignments`/`ghế-GV`/`packages` tier.

---

## 2. ⭐ 6 CHỐT MÓNG (đã khóa — đừng mở lại trừ khi có lý do)

1. **Cập nhật trọn A–G khớp library trước khi build** — ĐÃ XONG.
2. **License tách bạch:** `Tổng = (số môn × giá môn) + (số tk GV × giá GV) + storage add-on`. Seat GV subject-agnostic (dạy mọi môn trường thuê). **Master Admin** bundled 1/trường (không dạy/không seat). **Sub-Admin** do Master tạo (permission scope). **GV chính** theo môn-trong-lớp; **Trợ giảng** theo tiết (sau `prep_ready`), seat tùy `assistant_consumes_seat`. Gate dạy = seat active AND entitlement môn active; tách journey (D42). → `school_subscriptions`+`school_subject_entitlements`+`pricing_config`. (D51)
3. **Tách trẻ ⟂ ghi danh:** `children` (danh tính + nhật ký, không school/class cứng, `identity_user_id` để ngỏ) ⟂ `enrollments` (trẻ × homeroom × giai đoạn). 1 bé nhiều phiếu. Mã HS + trạng thái học ở enrollment. (D49)
4. **Demo:** 1 trường nhiều môn — **CTAN đầy đủ + Ballet vài bài thật**.
5. **Trung Tâm Tra Cứu:** chỉ index chức năng quản trị, đủ 4 trường metadata, tìm không dấu — dựng từ Chặng 1. (D100)
6. **Lớp = HOMEROOM đa môn (Cách Y):** lớp = nhóm trẻ; môn rót vào qua `class_distributions` (GV chính riêng/môn). **Phân phối** = cây `roadmap` (item = tiết lẻ và/hoặc piece con) → `piece` (item = tiết → giáo án); GV chỉnh INSTANCE của lớp (`content_override` + `session_media`), không đụng mẫu gốc. (D49/D50)

> **Giá 5tr/môn·500k/seat = ví dụ (khá sát thực tế), CHƯA phải số thật** → để config trong `pricing_config`.

---

## 3. OPEN ITEMS (chốt đúng chặng, không chặn khởi động)
- Giá thật cho `pricing_config` (đang dùng ví dụ).
- Default `assistant_consumes_seat` (trợ giảng có tính seat không).
- Danh mục quyền cụ thể của **Sub-Admin** (permission catalog).
- Chi tiết cơ chế **consent 2 tầng** (D47) — chốt ở Chặng 6.
- Bộ SQL 001–004 cũ (nếu còn) theo móng CŨ → **BỎ, không tái dùng**.

---

## 4. ⭐ NEXT ACTION (đầu phiên sau)
**Bắt đầu Chặng 0+1 (DB-first):**
1. Anh lưu 11 file vào Project Knowledge.
2. **Bước 1:** tạo Supabase project (name `dma`, region Singapore, lưu DB password; lấy Project URL + anon key; service_role GIỮ BÍ MẬT — D63).
3. **Bước 2:** Claude viết **migration 001** = enums + bảng nền (identity/org: profiles, schools, classes-homeroom…), chia khối nhỏ đánh số, SELECT verify cuối (D4). Anh dán vào SQL Editor, verify bằng kết quả thật.
4. Tiếp: GitHub → Lovable (shell + registry) → Vercel. Bunny ở Chặng 4, GoDaddy ở Chặng 8.
> Song song Chặng 1: dựng **Trung Tâm Tra Cứu** + giữ KỶ LUẬT VÀNG (làm tới đâu ghi RULES/SYSTEM_MAP tới đó).

---

## 5. BOOT phiên sau
1. Đọc `DMA_00_START_HERE` → `DMA_RULES` → file này.
2. Xác nhận 11 file đã ở Project Knowledge (audit thật, đừng tin mô tả — D1).
3. Vào Next Action §4. DB-first: DB → RLS/Function → Edge → UI.

---

## 6. TỰ ĐÁNH GIÁ
- **Được:** chốt sạch 6 quyết định móng dễ-sai-nhất (license, homeroom, phân phối, tách trẻ/ghi danh) TRƯỚC khi viết SQL → tránh đập móng; A–G + library đồng bộ một sự thật; giữ đúng linh hồn + 2 thép chờ + media security + trung thực giới hạn quay màn hình.
- **Cần giữ ở phiên sau:** hỏi từng câu một (anh thích vậy); chia SQL khối nhỏ; verify bằng ảnh/kết quả thật; không over-engineer (anh hỏi "có phức tạp không?" = reset MVP).
- **Lưu ý:** A–G là LỚP THIẾT KẾ; artifact chạy được (SQL/RLS/Edge/UI) mới bắt đầu từ phiên sau.
