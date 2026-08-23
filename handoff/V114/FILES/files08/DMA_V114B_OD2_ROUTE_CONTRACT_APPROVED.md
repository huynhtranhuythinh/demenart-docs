# DMA_V114B_OD2_ROUTE_CONTRACT_APPROVED.md

> **Artifact quyết định** · ghi nhận trong mốc **V114-R** · **KHÔNG triển khai trong mốc này**

---

## 1. Quyết định

| | |
|---|---|
| **Mã quyết định** | **OD-2** — Hợp đồng route gốc của Principal + thời điểm đổi view mặc định |
| **Ngày quyết định** | **20/07/2026** |
| **Người quyết định** | CTO / Owner |
| **Phương án được duyệt** | **PHƯƠNG ÁN A — gốc là Hôm nay** |
| **Baseline khi quyết định** | code HEAD `b87b576b` · 103 migrations · 52 routes · 16 edge functions |
| **Trạng thái triển khai** | ⛔ **CHƯA triển khai.** V114-R chỉ **ghi nhận** quyết định |

---

## 2. Nội dung Phương án A

1. **`/school` sẽ trở thành Principal Hôm nay.**
2. **Tổng quan Quản lý trường hiện tại dời sang `/school/manage`.**
3. **Route cấp thực thể** cho lớp · giáo viên · buổi học sẽ được thiết kế sau.
4. **View mặc định của Hiệu trưởng chỉ chuyển sang Hôm nay khi Principal Today đã qua các cổng trung thực và cổng hợp đồng domain** — không phải khi shell chạy được.

---

## 3. Yêu cầu tương thích — bắt buộc

URL đang dùng hiện nay **phải tiếp tục hoạt động**:

| URL hiện có | Cách xử lý bắt buộc |
|---|---|
| `/school?tab=classes` | giữ nguyên, **hoặc** redirect sang `/school/manage?tab=classes` |
| `/school?tab=teachers` | giữ nguyên, **hoặc** redirect sang `/school/manage?tab=teachers` |
| `/school?tab=children` | giữ nguyên, **hoặc** redirect sang `/school/manage?tab=children` |

Ba URL này **đã địa chỉ hoá được và đã chia sẻ được** ngày hôm nay — `school.tsx` khai báo `search: { tab }` và `navActive` so khớp đúng tab. **Không được làm gãy chúng.**

Ngoài ra, mọi điểm vào phải được rà lại khi triển khai: điều hướng sau đăng nhập · bấm logo về nhà · breadcrumb "Tổng quan" trong `ManagementView` · link brand ở sidebar và header mobile của `school.tsx`.

---

## 4. Hoãn lại cho V114B

Những việc sau **KHÔNG** làm trong V114-R:

- di trú route `/school`;
- tạo `/school/manage`;
- shell dual-view và bộ chuyển view;
- lưu preference theo profile;
- projection Principal Today;
- route cấp thực thể cho lớp · giáo viên · buổi;
- đổi view mặc định của Hiệu trưởng.

---

## 5. Ranh giới bắt buộc

> **Quyết định này chỉ ảnh hưởng tới định tuyến trình bày. Nó KHÔNG BAO GIỜ ảnh hưởng tới uỷ quyền.**

Route ánh xạ tới một ngữ cảnh trình bày để shell chọn đúng view. Ánh xạ đó **không tạo ra quyền**. Đã kiểm chứng ở V114A: rà 164 policy, **không predicate nào** tham chiếu view, preference hay chế độ hiển thị. Việc triển khai Phương án A **không được** thay đổi thực tế đó.

Cụ thể, khi triển khai:
- không được có tham số URL nào mang ý nghĩa uỷ quyền (`?scope=`, `?view=` …);
- preference hiển thị không được là đầu vào của bất kỳ policy hay RPC nào;
- `/school/manage` phải giữ **nguyên vẹn** ranh giới quyền của `/school` hiện tại — không rộng hơn một byte.

---

*Sinh trong V114-R. Không canonicalize. Không cập nhật RULES/SYSTEM_MAP.*
