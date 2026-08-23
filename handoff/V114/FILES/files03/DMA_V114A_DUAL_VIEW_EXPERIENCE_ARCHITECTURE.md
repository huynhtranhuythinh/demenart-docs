# DMA_V114A_DUAL_VIEW_EXPERIENCE_ARCHITECTURE.md

> **File 4/6** · Kiến trúc sản phẩm & IA cho dual-view · **đặc tả, KHÔNG code, KHÔNG migration**
> **Baseline:** code HEAD `b87b576b` · 103 migrations · 87 tables · 190 secdef · 164 policies · 52 routes · 16 edge functions
> **Đầu vào:** File 1 (audit hệ thống) · File 2 (School workstyle, đã vá 3 đính chính) · File 3 (Teacher workstyle, đã vá 5 đính chính) · rà source có giới hạn ở §0
> **Trạng thái:** V114A vẫn là audit-only. Không mở V114B/V114C/SEC1A/SEC1B.

---

## 0. RÀ SOURCE CÓ GIỚI HẠN — KẾT QUẢ

Đọc source thật: `teacher.curriculum` → `CurriculumView` · `teacher.media` · `teacher.moments` · `teacher.support` · `teacher.notifications` · `school.tsx` (shell + `NAV_GROUPS` + `navActive`).

| Bề mặt | Mục đích chính | Dữ liệu chính | Hành động chính | Trùng lặp | Deep-link hiện có | Trạng thái | Chạm dữ liệu trẻ / theo phân công? | Đích đúng |
|---|---|---|---|---|---|---|---|---|
| `/teacher/curriculum` | Nghe thử kho track CTAN của trường | `list_curriculum_media` (theo entitlement trường) | Phát 1 track, có watermark | **Trùng hoàn toàn `/school/curriculum`** — cùng component `CurriculumView` | route ổn định, không tham số | **Active** | ❌ không chạm dữ liệu trẻ; scope = **trường**, không theo phân công | **Toàn bộ** (thư viện) |
| `/teacher/media` | Ngăn kho riêng của cô trong Drive trường | `drive_my_zone(school_id)` → `DriveExplorer` | Duyệt / tải file trong ngăn của mình | Khác `/school/drive` (kho toàn trường) | route ổn định | **Active** | ⚠️ chứa **ảnh chụp tại lớp** tự xếp theo ngày → **có** dữ liệu trẻ; scope = ngăn cá nhân | **Toàn bộ** |
| `/teacher/moments` | — | — | — | — | — | **Redirect đã nghỉ hưu (V89)** → `/teacher` kèm toast | — | **Giữ nguyên redirect** |
| `/teacher/support` | Gửi yêu cầu hỗ trợ tới Dế Mèn | `support_requests` | Tạo yêu cầu | Wrapper mỏng D115, **một nguồn** với `/school/support`, `/portal/support` | route ổn định | **Active** | ❌ | **Tiện ích toàn cục** |
| `/teacher/notifications` | Đọc thông báo | `notifications` | Đánh dấu đã đọc | Wrapper mỏng D115, một nguồn với `/school/notifications` | route ổn định | **Active** | ❌ | **Tiện ích toàn cục** |
| `school.tsx` shell | Khung điều hướng Cổng Trường | — | — | Cấu trúc **gần như đối xứng** với `teacher.tsx` (cùng sidebar gradient, cùng top-nav mobile, cùng khối LOCKED) | nav **đã** dùng `search: { tab }` + `navActive` so khớp tab | **Active** | — | **Nền cho `Quản lý`** |

### 0.1 Năm câu CTO yêu cầu giải dứt điểm

**1. Teacher Media khác Teacher Moments thế nào?**
Không còn là hai thứ song song. `Media` = **kho file cá nhân của cô** trong Drive trường (`drive_my_zone`), nơi ảnh chụp tại lớp tự xếp theo ngày. `Moments` = **khoảnh khắc học tập gắn với buổi và gắn với bé**, và từ V89 nó **chỉ tồn tại bên trong luồng buổi học** (Bước 3 · Tab Ảnh · `learning_moments` + `moment_children`). Một bên là **tệp**, một bên là **bằng chứng phát triển có ngữ cảnh và có consent**. Việc tách chúng ra là **đúng**, không phải trùng lặp cần gộp.

**2. `/teacher/moments` nên độc lập, gộp hay redirect?**
**Giữ nguyên redirect.** Đã đúng. Không hồi sinh, không gộp. Đây là quyết định V89 đã được thi hành sạch sẽ; dựng lại một bề mặt moments cấp portal cho GV sẽ **tái tạo đúng lối tắt vòng qua ngữ cảnh buổi và consent** mà V89 đã đóng.

**3. Curriculum là thư viện thuần hay có tham gia chuẩn bị buổi?**
**Thư viện thuần.** `CurriculumView` gọi `list_curriculum_media` — danh sách track theo entitlement của **trường**, không nhận `session_id`, không biết lớp, không biết buổi. Giáo án thật (`objective` · `script` · `questions` · media gắn theo phần) đến từ **`get_lesson_guide` bên trong buổi học**, hoàn toàn tách biệt. → Curriculum **không** tham gia chuẩn bị buổi, và **nhãn nav "Giáo án" của Teacher là sai** (xem `V114A-P2-14`).

**4. Support và Notifications nằm trong Toàn bộ hay là tiện ích toàn cục?**
**Tiện ích toàn cục.** Cả hai là wrapper mỏng D115 quanh một component dùng chung cho cả ba portal. Nhét chúng vào `Toàn bộ`/`Quản lý` sẽ ngụ ý sai rằng chúng thuộc phạm vi nghiệp vụ của một view. Đúng hơn: **chúng sống ở tầng shell**, truy cập được từ **cả hai view**, không bao giờ là lý do để chuyển view.

**5. Bề mặt quản lý nào của School nhận được deep link ổn định thay cho điều hướng chỉ-bằng-query-param?**
Đính chính một giả định trong bản audit trước: `?tab=` **không phải** là điều hướng "không địa chỉ hoá được". `school.tsx` **đã** khai báo `search: { tab: "classes" | "teachers" | "children" }` và `navActive` so khớp đúng tab — nên `/school?tab=teachers` **là** một URL chia sẻ được và bookmark được ngay hôm nay.

Vấn đề thật **hẹp hơn và sâu hơn**: cái thiếu không phải deep link cấp **tab**, mà là deep link cấp **thực thể**.
- Không có `/school/classes/<id>` — nên `ClassProgress` bấm lớp nào cũng về `?tab=classes` (**`V114A-P1-7`**);
- không có `/school/teachers/<id>`;
- không có `/school/sessions/<id>` để Hiệu trưởng đi từ một ô lịch tuần tới một buổi cụ thể (**`V114A-P2-4`**).

→ Ứng viên deep link ổn định: **lớp · giáo viên · buổi học**. Ba route tab hiện tại **giữ nguyên `?tab=`**, không cần đập đi.

---

## 1. BẤT BIẾN SẢN PHẨM

Mười ba bất biến dưới đây ràng buộc mọi quyết định trong file này. Chúng là **ràng buộc**, không phải nguyện vọng.

1. **Một sản phẩm, một hệ thống bên dưới.** Dual-view là hai *ống kính*, không phải hai ứng dụng.
2. **Không nhân bản logic nghiệp vụ.** "Buổi quá hạn" phải có **một** định nghĩa, dùng chung cho Principal và Teacher.
3. **Preference hiển thị KHÔNG BAO GIỜ đổi quyền.** Đã kiểm chứng ở File 1 §3.7: rà 164 policy, **không predicate nào** tham chiếu view/preference/chế độ hiển thị.
4. **Server suy ra persona và phạm vi dữ liệu.** Từ JWT, không từ tham số client.
5. **Client không thể xin phạm vi rộng hơn qua tham số view.** Không có `?scope=school`, không có `?view=all` mang ý nghĩa uỷ quyền.
6. **Principal Hôm nay là exception-first.** Không KPI-first, không dashboard-first.
7. **Teacher Hôm nay là action-first.** Mỗi khối phải trả lời "giờ tôi làm gì".
8. **Teacher `Toàn bộ` = toàn bộ công cụ được uỷ quyền, KHÔNG phải toàn bộ dữ liệu trường.**
9. **Principal quan sát · điều tra · phân công lại / uỷ quyền.**
10. **Principal KHÔNG làm thay cô.** RLS chặn admin ở `session_marks`, `session_media`, `child_observations`, `prep_items`. Đặt CTA đó = vi phạm **D290**.
11. **Uỷ quyền tạm thời phải có mốc bắt đầu, mốc hết hạn, và ghi nhận đúng người thực hiện.**
12. **Bề mặt hữu ích hiện có được re-home, không bị vứt bỏ tuỳ tiện.**
13. **Không tái tạo điểm số và phán xét không có cơ sở.** Điểm sức khoẻ trường đã bị gỡ ở V114-H; badge `Cần hỗ trợ` cấp lớp phải được gỡ hoặc thay. **Không dựng lại dưới tên khác.**

> **Bất biến bổ sung rút ra từ File 3 (§4.3):** **UI không được suy ra quyền hành động từ việc đọc được dữ liệu.** Ở DMA hiện tại, phạm vi *đọc* rộng hơn phạm vi *ghi* rất nhiều — nên "hiện nút vì tải được dữ liệu" là một lỗi có hệ thống, không phải sơ suất lẻ.

---

## 2. GIẢI PHẪU SHELL

Cả hai portal đã dùng chung một khung: sidebar gradient rừng (desktop, `lg:`) · top-nav trượt ngang (mobile) · header có chuông + tên + đăng xuất · khối `Sắp ra mắt` khoá. **Dual-view không thay khung này** — nó thêm **một tầng đúng một cấp** phía trên nav.

```
┌─ Shell (giữ nguyên: brand · chuông · hồ sơ · đăng xuất) ─────────┐
│                                                                  │
│   ┌─ VIEW SWITCH ─────────────────────┐   ← MỚI, chỉ ở đây      │
│   │  [ Hôm nay ] [ Quản lý / Toàn bộ ] │                          │
│   └────────────────────────────────────┘                          │
│                                                                  │
│   ┌─ Nav của view đang chọn ───────────┐                          │
│   │  Hôm nay  → không nav con          │                          │
│   │  Quản lý  → NAV_GROUPS hiện tại    │                          │
│   │  Toàn bộ  → NAV_GROUPS hiện tại    │                          │
│   └────────────────────────────────────┘                          │
│                                                                  │
│   ┌─ Outlet ───────────────────────────┐                          │
│   └────────────────────────────────────┘                          │
│                                                                  │
│   Tiện ích toàn cục: 🔔 Thông báo · 🛟 Hỗ trợ  ← luôn hiện,       │
│                                                  không thuộc view │
└──────────────────────────────────────────────────────────────────┘
```

**Nguyên tắc:** `Hôm nay` **không có nav con**. Nó là **một bề mặt**, không phải một khu vực. Ngay khi `Hôm nay` mọc ra menu con, nó đã thành một portal thứ hai và bất biến 1 gãy.

### 2.1 Nhãn

| Persona | View 1 | View 2 | Lý do |
|---|---|---|---|
| Hiệu trưởng | **Hôm nay** | **Quản lý** | "Quản lý" khớp nhóm nav đã có `Quản lý trường` |
| Giáo viên | **Hôm nay** | **Toàn bộ** | "Toàn bộ" = toàn bộ **công cụ của cô**. Nếu nhãn này về sau bị hiểu là "toàn bộ dữ liệu trường" thì **đổi nhãn**, đừng mở dữ liệu |

Không dùng "Dashboard", "Tổng quan" cho view — `Tổng quan` **đã** là một mục nav trong `Quản lý`, tái dùng sẽ gây va chạm.

---

## 3. HÀNH VI CHUYỂN VIEW

| Hạng mục | Quyết định |
|---|---|
| **Vị trí** | Desktop: đầu sidebar, **ngay dưới brand, trên nhóm nav đầu tiên**. Mobile: hàng riêng **trên** thanh nav trượt ngang — **không** nhét vào chính thanh đó (nếu nằm cùng hàng, nó sẽ trôi khỏi màn hình cùng các mục khác) |
| **Kiểu điều khiển** | Segmented control 2 nhánh. **Không** dropdown (giấu mất trạng thái), **không** toggle switch (không nói được nhánh nào đang bật) |
| **View mặc định — Hiệu trưởng** | **Hôm nay** *(sau khi Principal Today đạt ngưỡng trung thực; trước đó mặc định vẫn là `Quản lý`)* |
| **View mặc định — Giáo viên** | **Hôm nay** — đây đã là hành vi hiện tại của `/teacher` |
| **Lưu preference** | Theo **profile**, không theo thiết bị. Cô dạy trên laptop lớp rồi mở điện thoại phải thấy cùng một thứ. **Preference là dữ liệu trình bày thuần tuý — không bao giờ là đầu vào uỷ quyền** |
| **Ưu tiên khi mâu thuẫn** | Deep link tường minh **thắng** preference đã lưu. Mở link tới một bề mặt `Quản lý` thì vào `Quản lý`, dù preference là `Hôm nay`. Việc này **không** ghi đè preference đã lưu |
| **Chuyển view có reset cuộn?** | Có. Đây là chuyển ngữ cảnh, không phải điều hướng trong ngữ cảnh |
| **Chuyển view có mất việc đang làm?** | **Không được phép.** Nếu đang có nội dung chưa lưu (ghi chú, chú thích), phải hỏi trước. Luồng buổi học đã tự-lưu nên không bị ảnh hưởng |

### 3.1 Ngữ pháp điều hướng theo thiết bị

| | Điện thoại (< `sm`) | Tablet (`sm`–`lg`) | Desktop (≥ `lg`) |
|---|---|---|---|
| Switch | hàng riêng, dính trên | hàng riêng, dính trên | đầu sidebar |
| Nav của view | thanh trượt ngang | thanh trượt ngang | sidebar dọc |
| `Hôm nay` | một cột, xếp dọc | một cột rộng | hai cột (chính/phụ) — như `teacher.index` hiện nay |
| Màn chiếu | không áp dụng | không áp dụng | cửa sổ thứ hai |

**Điện thoại là thiết bị thật của cô giáo trong lớp.** `Hôm nay` phải dùng được bằng một ngón tay, một tay còn lại đang giữ trẻ. `Toàn bộ`/`Quản lý` được phép nặng hơn.

---

## 4. DEEP LINK, NGỮ CẢNH QUAY LẠI, VÀ BÀN GIAO HAI CHIỀU

### 4.1 Sở hữu route

**View KHÔNG sở hữu route.** Mỗi route thuộc về đúng một view theo bảng, và shell suy ra view từ route. **Không** đưa view vào URL dưới dạng tham số uỷ quyền.

| Route | View sở hữu |
|---|---|
| `/school/today` *(mới)* | Quản lý → Hôm nay |
| `/school`, `/school?tab=…`, `/school/settings`, `/school/curriculum`, `/school/drive`, `/school/moments` | Quản lý |
| `/teacher` | Teacher → Hôm nay |
| `/teacher/classes`, `/teacher/journal`, `/teacher/curriculum`, `/teacher/media` | Toàn bộ |
| `/teacher/session/$id`, `/teacher/classroom` | **Không thuộc view nào — ngữ cảnh làm việc toàn màn** |
| `/teacher/support`, `/teacher/notifications`, `/school/support`, `/school/notifications` | Tiện ích toàn cục |

> **Quyết định quan trọng:** luồng buổi học **không thuộc `Hôm nay` cũng không thuộc `Toàn bộ`**. Nó là một **ngữ cảnh làm việc** mở ra từ cả hai. Vì vậy nó phải **nhớ nơi mình được mở ra từ đó**, chứ không quay về một điểm cố định.

### 4.2 Ngữ cảnh quay lại

Hiện tại `BackLink` trong `teacher.session.$id` **cứng** thành `<Link to="/teacher">Hôm nay</Link>`. Cô vào buổi từ `/teacher/journal` rồi bấm quay lại sẽ **bị ném sang Hôm nay**, mất luôn danh sách đang xem.

**Quy tắc:** ngữ cảnh quay lại được **mang theo, không đoán**.

| Vào buổi từ | Quay lại về | Nhãn |
|---|---|---|
| `Hôm nay` | `Hôm nay` | `← Hôm nay` |
| `/teacher/journal` | `/teacher/journal` | `← Nhật ký` |
| `/teacher/classes` | `/teacher/classes` | `← Lớp của cô` |
| Deep link từ ngoài (không có ngữ cảnh) | view mặc định của persona | `← Hôm nay` |
| Principal điều tra một buổi | bề mặt Principal đã mở nó | `← Hôm nay` / `← Lớp & Môn` |

Sau khi **gửi nhật ký xong**, quay về **`Hôm nay`** bất kể vào từ đâu — đây là **hoàn tất một việc**, không phải quay lui một bước. Hành vi hiện tại đã đúng.

### 4.3 Bàn giao Hôm nay → Toàn bộ/Quản lý

Mỗi khối trong `Hôm nay` **phải** có một đường đi tiếp hợp lệ. Một khối không đi đâu được là **trình bày lại dữ liệu**, đúng thứ File 2 kết luận là bệnh gốc của DMA hiện tại.

| Khối `Hôm nay` | Đi tiếp tới | Mang theo |
|---|---|---|
| Buổi hôm nay (Teacher) | luồng buổi | `session_id` + ngữ cảnh quay lại |
| Việc còn tồn (Teacher) | luồng buổi ở **đúng bước** | `session_id` + bước đích |
| Buổi cần chú ý (Principal) | chi tiết buổi (chỉ đọc) | `session_id` |
| Lớp có vấn đề (Principal) | `/school/classes/<id>` *(cần route mới)* | `class_id` |
| Buổi chưa phân công (Principal) | bề mặt phân công | `session_id` |

### 4.4 Bàn giao Toàn bộ/Quản lý → Hôm nay

Một chiều, không mang trạng thái. `Hôm nay` **luôn tự tính lại từ server**. Không truyền bộ lọc từ `Toàn bộ` vào `Hôm nay` — nếu làm vậy, `Hôm nay` không còn là **sự thật của hôm nay** mà thành **một khung nhìn đã lọc**, và hai người nhìn cùng một trường sẽ thấy hai sự thật.

---

## 5. PRINCIPAL HÔM NAY

Exception-first. Hiệu trưởng **không cần thấy mọi thứ** — cần biết trường **bình thường** hay **có gì cần can thiệp**.

### 5.1 Tám tình huống buổi học phải phân biệt được

Đây là phần **quan trọng nhất** của Principal Today. Gộp bất kỳ hai dòng nào là tái tạo lại đúng khiếm khuyết đã gỡ ở V114-H.

| # | Tình huống | Suy ra được từ hệ hiện tại? | Có phải cảnh báo? | Hành động đúng của Hiệu trưởng |
|---|---|---|---|---|
| 1 | **Buổi chưa phân công / phân công thiếu** | ✅ (`lead_teacher_id` NULL, `session_teachers` rỗng) | **Có** | Phân công |
| 2 | **GV đã phân công, được báo là không có mặt** | ❌ **KHÔNG — không có tín hiệu nào** | Có, *khi đã có tín hiệu* | Phân công lại / uỷ quyền tạm thời |
| 3 | **Đã bố trí người thay tạm thời** | ❌ chưa có mô hình | Không — đây là **trạng thái đã giải quyết** | Theo dõi tới khi hết hạn |
| 4 | **Đang dạy hợp lệ** | ✅ | **Không** | Không làm gì |
| 5 | **Quá hạn** (qua giờ kết thúc dự kiến + ân hạn) | ⚠️ cần quy tắc + đánh giá thời gian phía server | Có | Liên hệ / điều tra |
| 6 | **Bỏ ngỏ do quên đóng** (quá hạn rất xa, không hoạt động kèm) | ⚠️ cần quy tắc stale-state | Có — nhưng **khác loại**: nhắc dọn, không phải sự cố dạy học | Nhắc GV đóng |
| 7 | **Huỷ / dời lịch** | ✅ (`cancelled`) | **Không** | Không làm gì |
| 8 | **Fixture / demo bỏ dở** | ⚠️ cần quy tắc loại trừ | **Không bao giờ** | Không bao giờ hiện |

> 🔴 **Hai buổi KHM kẹt `in_progress` từ 03/07 và 14/07 là dòng 8, KHÔNG phải dòng 5.** Chính việc gộp hai dòng này đã tạo ra điểm sức khoẻ giả. **Principal Today không được phát hành cho tới khi quy tắc phân biệt 4/5/6/8 tồn tại và được kiểm chứng.**

**Về dòng 2 — nói thẳng:** hệ thống **không thể phát hiện GV vắng mặt** nếu không có một tín hiệu vận hành mới (`V114A-P1-8`). Không được suy ra vắng mặt từ dữ liệu phân công. Không được suy ra từ việc buổi chưa bắt đầu. Nếu Principal Today nói "GV vắng" mà không có tín hiệu thật, nó **bịa** — và đó chính là hạng lỗi V114-H đã phải gỡ. Cho tới khi có tín hiệu, Hiệu trưởng nhận **buổi quá hạn chưa bắt đầu**, kèm câu hỏi trung thực *"buổi này đã có người phụ trách chưa?"* — chứ không phải một phán quyết.

### 5.2 Nội dung Principal Hôm nay

| Khối | Trạng thái | Ghi chú |
|---|---|---|
| Dải trạng thái hôm nay (một câu, trung thực) | **NEEDS DOMAIN DEFINITION + SERVER PROJECTION** | "Hôm nay 6 buổi · 4 xong · 1 đang dạy · 1 cần chú ý" |
| **Cần chú ý** (exception list, dòng 1/5/6 ở trên) | **NEEDS DOMAIN RULE + SERVER PROJECTION** | Khối **đầu tiên và quan trọng nhất** |
| Buổi hôm nay (dòng thời gian) | **REUSABLE SOURCE — FINAL TODAY PROJECTION STILL NEEDED** | Từ `get_school_week_schedule`, lọc 1 ngày ở server |
| Việc đã hoàn thành hôm nay | **REUSABLE STATE, NEEDS SESSION-LEVEL PROJECTION** | Ngắn, không phô trương |
| Khoảnh khắc gần đây | **READY NOW** | `get_school_moments` — bề mặt trung thực nhất hiện có |
| Trạng thái cuối ngày | **NEEDS DOMAIN DEFINITION + SERVER PROJECTION** | Trả lời P5 — khoảng trống lớn nhất của Principal |
| ~~Điểm sức khoẻ~~ · ~~Tương tác PH %~~ · ~~"GV nào cần giúp đỡ"~~ | **DO NOT BUILD** | — |

### 5.3 Hành động cho phép ở Principal Hôm nay

| Mức | Cho phép? | Cơ sở |
|---|---|---|
| Quan sát | ✅ | — |
| Điều tra (mở buổi/lớp cụ thể, chỉ đọc) | ✅ | RLS cho phép đọc |
| Phân công lại / uỷ quyền | ✅ | `session_teachers` cho phép `is_school_admin` |
| **Làm thay GV** (điểm danh, media, nhận xét trẻ, prep) | ❌ **CẤM** | RLS chặn admin ở cả bốn. Đặt CTA = **D290** |

Vắng GV → **phân công lại hoặc uỷ quyền tạm thời có ghi nhận đúng người thực hiện.** Không bao giờ là "Hiệu trưởng điểm danh hộ".

---

## 6. TEACHER HÔM NAY

Action-first. Mười vấn đề CTO giao, giải ở mức khái niệm — **không viết RPC**.

| # | Vấn đề | Giải pháp kiến trúc |
|---|---|---|
| 1 | **Tất cả buổi hôm nay, không `limit 1`** | `Hôm nay` nhận **một mảng buổi hôm nay** từ server, đã sắp xếp theo thời gian. `today_count` và số thẻ hiển thị **phải luôn khớp nhau** — chênh lệch giữa hai con số này là một lỗi trình bày, không phải một lựa chọn thiết kế |
| 2 | **Phân biệt hiện tại / kế tiếp / muộn hơn trong ngày** | Ba vùng trong **một** dòng thời gian: **Đang / Sắp tới** (buổi kế trong ngày) / **Còn lại hôm nay** (thu gọn). Nhãn "Lớp tiếp theo" hiện tại **phải đổi tên** — nó đang chỉ buổi của **ngày khác** |
| 3 | **Lịch đổi và phân công dạy thay** | Nếu lịch hôm nay thay đổi sau khi cô mở máy, `Hôm nay` phải **nói ra** ("Lịch hôm nay vừa thay đổi"), không âm thầm đổi nội dung. Buổi dạy thay hiển thị **kèm nhãn tạm thời và mốc hết hạn** |
| 4 | **Todo có danh tính buổi** | Mỗi việc mang `session_id` **và bước đích**. "Lớp chưa điểm danh" đi thẳng tới Bước 3 · Tab Điểm danh, không phải tới trang chủ của buổi |
| 5 | **Khung thời gian nhất quán** | Toàn bộ khối `Việc cần làm hôm nay` chạy trên **một** khung thời gian ở server. Việc tồn từ ngày khác đi vào một khối riêng, có nhãn riêng — **không trộn im lặng** (`V114A-P1-11`) |
| 6 | **Việc quá hạn** | Khối riêng **"Còn tồn từ trước"**, tách khỏi "Hôm nay". Dùng đúng quy tắc quá hạn/stale ở §5.1 — **một định nghĩa, hai persona** (bất biến 2) |
| 7 | **Hành động theo vai trò lead vs trợ giảng** | Khả dụng của hành động suy ra từ **vai trò hiệu lực do server uỷ quyền**. Trợ giảng **không** thấy CTA gửi nhật ký ở trạng thái bật; thấy trạng thái **đã tắt kèm lý do thật** (`V114A-P1-12`) |
| 8 | **Trạng thái Remote trung thực** | Khi năng lực bị vô hiệu: **không dựng nút**, hoặc dựng ở trạng thái tắt kèm câu nói thật. **Không đổ lỗi cho mạng. Không mời thử lại.** Thông điệp ở Home và trong buổi phải **khớp nhau** (`V114A-P1-9`) |
| 9 | **Kết quả consent ở mức hành động** | Tại điểm gắn bé, cô thấy **kết quả quyền cho hành động này với bé này** — không phải bản ghi consent thô. Đúng mặc định riêng tư ở File 1 §3.5 |
| 10 | **Quay lại ngữ cảnh buổi** | Theo §4.2 — mang theo, không đoán |

### 6.1 Cái gì KHÔNG thuộc Teacher Hôm nay

Thư viện học liệu · kho Drive cá nhân · lịch sử lớp · nhật ký 60 ngày · giáo án tra cứu. Tất cả thuộc **`Toàn bộ`**. `Hôm nay` chỉ chứa thứ **hôm nay cô cần chạm tới**.

---

## 7. QUẢN LÝ (PRINCIPAL) VÀ TOÀN BỘ (TEACHER)

### 7.1 Principal · Quản lý

Giữ nguyên `NAV_GROUPS` hiện có. Bổ sung:

| Nhóm | Mục | Ghi chú |
|---|---|---|
| Quản lý trường | Tổng quan · Lớp & Môn · Giáo viên · Trẻ & Phụ huynh · Cài đặt | 6 thẻ KPI luỹ kế **về đây**, rời khỏi Hôm nay |
| Chương trình & Media | Học liệu · Kho của trường · **Khoảnh khắc** | `/school/moments` **hiện chưa có trong nav** (`V114A-P2-13`) → thêm vào đây |
| — | **Lịch triển khai tuần** | Đang là card trong `school.index`; ô lưới **phải click được** (`V114A-P2-4`) |

**Deep link cấp thực thể cần thêm:** `/school/classes/<id>` · `/school/teachers/<id>` · `/school/sessions/<id>`. Ba route tab hiện tại **giữ `?tab=`** — chúng đã địa chỉ hoá được.

### 7.2 Teacher · Toàn bộ

| Nhóm | Mục | Ghi chú |
|---|---|---|
| Lớp học | Lớp của tôi · Nhật ký | `Hôm nay` rời khỏi nhóm này, lên thành view |
| Chương trình & Media | **Thư viện CTAN** *(đổi từ "Giáo án")* · Học liệu của tôi | Đổi nhãn theo `V114A-P2-14` |

> **`Toàn bộ` KHÔNG mở thêm một byte dữ liệu nào.** Nó chỉ tập hợp lại các công cụ cô **đã** có quyền dùng. Nếu một màn hình trong `Toàn bộ` cần dữ liệu ngoài phân công, nó **không được** vào `Toàn bộ` — nó vào hàng đợi SEC1B.

---

## 8. TRẠNG THÁI BỀ MẶT

Sáu trạng thái, áp cho mọi khối ở cả hai view. Ba trạng thái giữa hiện đang bị gộp hoặc bị thiếu trong sản phẩm.

| Trạng thái | Quy tắc | Sai lầm phải tránh |
|---|---|---|
| **Đang tải** | Skeleton giữ chỗ đúng hình dạng thật | `PrepCard` hiện **tự ẩn khi `total === 0`** → không phân biệt được với đang tải (`V114A-P2-11`) |
| **Rỗng thật** | Nói rõ và bình thường hoá: *"Hôm nay cô không có lớp"* | Hiện tại đã làm tốt ở `EmptyToday` |
| **Không đủ dữ liệu để kết luận** | **Nói ra là chưa kết luận được.** Không dựng ngưỡng trên mẫu nhỏ | Đây chính là bệnh gốc của badge `Cần hỗ trợ` (n=3, 2/3 là fixture) |
| **Bị vô hiệu** | Hiện trạng thái tắt + **lý do thật** + việc cô có thể làm được | Không đổ lỗi cho mạng khi nguyên nhân là quyết định của Dế Mèn (`V114A-P1-9`) |
| **Ngoại lệ** | Phân biệt bằng loại, không bằng màu | Xem 8 tình huống ở §5.1 |
| **Không có quyền** | **Không dựng cửa.** Nếu buộc phải hiện, hiện ở trạng thái tắt kèm lý do | `D290` — cửa chắc chắn dẫn tới `not_authorized` là bug |

### 8.1 Uỷ quyền hết hạn

Chưa tồn tại trong hệ, nhưng kiến trúc phải chừa chỗ ngay từ bây giờ:

- **Trong thời hạn:** buổi hiện trong `Hôm nay` của người dạy thay, có nhãn tạm thời **và mốc hết hạn nhìn thấy được**;
- **Khi hết hạn:** buổi **rời khỏi** `Hôm nay` của người đó; dữ liệu trẻ **thu lại**; các bản ghi **do chính người đó soạn vẫn được ghi công đúng tên**;
- **Không bao giờ** để hết hạn im lặng biến thành `not_authorized` giữa lúc cô đang gõ dở.

---

## 9. XỬ LÝ BỀ MẶT HIỆN CÓ

| Bề mặt | Xử lý | Đích |
|---|---|---|
| 6 thẻ KPI luỹ kế | **PRESERVE UNCHANGED** | Quản lý |
| Lịch triển khai tuần | **PRESERVE + làm ô click được** | Quản lý *(link từ Hôm nay)* |
| Tiến độ theo lớp | **PRESERVE + sửa điều hướng ảo giác** (`P1-7`) | Quản lý |
| Khoảnh khắc nổi bật | **LINK FROM TODAY** | Quản lý |
| Card dữ liệu triển khai | **PRESERVE UNCHANGED** | Quản lý |
| Tab Lớp / GV / Trẻ | **PRESERVE `?tab=` + thêm deep link cấp thực thể** | Quản lý |
| `/school/moments` | **PRESERVE + đưa vào nav** (`P2-13`) | Quản lý |
| Gợi ý cho trường | **PRESERVE, POLISH LATER** | Quản lý |
| Tương tác phụ huynh (placeholder khoá) | **HIDE UNTIL REAL** | — |
| Badge lớp `Cần hỗ trợ` | **REMOVE OR REPLACE BEFORE SCHOOL TODAY / NEXT EXTERNAL DEMO** | — |
| `teacher.index` (nhịp ngày) | **EVOLVE IN PLACE** → Teacher Hôm nay | Hôm nay |
| `TodoSection` | **REBUILD ON TRUTHFUL SOURCE** | Hôm nay |
| Dòng "Phản hồi phụ huynh mới" | **HIDE UNTIL REAL** (`P2-8`) | — |
| `LockedAction` "Sắp ra mắt V1.1" ×2 | **RESOLVE CONTRADICTION** — Home và session phải nói cùng một điều | — |
| `/teacher/classes`, `/teacher/journal` | **PRESERVE + RE-HOME** | Toàn bộ |
| `/teacher/curriculum` | **PRESERVE + ĐỔI NHÃN** thành "Thư viện CTAN" | Toàn bộ |
| `/teacher/media` | **PRESERVE + RE-HOME** | Toàn bộ |
| `/teacher/moments` | **PRESERVE REDIRECT** | — |
| `/teacher/session/$id`, `/teacher/classroom` | **PRESERVE** — ngữ cảnh làm việc, không thuộc view | — |
| Support · Notifications (cả 3 portal) | **PRESERVE AS GLOBAL UTILITY** | Shell |
| Điểm sức khoẻ trường | **DO NOT RECREATE** | — |

**Không bề mặt nào bị gỡ chỉ vì không thuộc `Hôm nay`.**

---

## 10. THỨ TỰ TRIỂN KHAI — HAI LÀN SONG SONG

Trải nghiệm Teacher trưởng thành hơn **không** phải lý do để build Teacher trước. Lý do thật để **không** build Teacher Today trước là: **mọi trải nghiệm Teacher có mang dữ liệu đều đang bị chặn bởi SEC1B.** Ngược lại, Principal Today bị chặn bởi **quy tắc nghiệp vụ**, mà quy tắc thì viết được **ngay bây giờ, không cần chờ bảo mật**.

```
LÀN TRẢI NGHIỆM                          LÀN BẢO MẬT
─────────────────────                    ─────────────────
E1  V114B: shell · switch ·              S1  SEC1A — Remote capability
    preference · ngữ pháp nav                (pairing · TTL · rate-limit ·
    ⚠️ KHÔNG mở rộng projection              capability token · audit ·
                                             kill switch)
        │                                        │
E2  Hợp đồng domain Principal            S2  SEC1B — least-privilege ·
    Today + projection trung thực            uỷ quyền có thời hạn ·
    (8 tình huống · stale-state ·            offboarding · thu hồi session
    loại trừ fixture)                         │
        │                                        │
E3  Re-home School Management            S3  Controlled validation
    (deep link cấp thực thể ·                (negative test xuyên lớp ·
    sửa P1-7, P2-4)                          test hết hạn uỷ quyền ·
        │                                     test nhân sự cũ, dùng fixture
        │                                     được duyệt)
        │                                        │
        └──────────────► 🚧 CỔNG CỨNG ◄─────────┘
                              │
                    E4  Hoàn thiện Teacher Today
                        (tất cả buổi · todo có danh tính ·
                        vai trò lead/trợ giảng · consent
                        mức hành động)
```

### 10.1 Chạy song song được / không được

| Có thể song song | Lý do |
|---|---|
| **E1 ∥ S1 ∥ S2** | E1 chỉ động vào shell và preference, **không mở rộng projection** nào |
| **E2 ∥ S1 ∥ S2** | Viết quy tắc nghiệp vụ và projection Principal không phụ thuộc least-privilege của GV |
| **E3 ∥ S2** | Sửa deep link và điều hướng School không đụng ranh giới quyền của GV |
| **E2 ∥ E3** | Hai bề mặt Principal khác nhau |

| **KHÔNG được song song** | Lý do |
|---|---|
| **E4 trước S2** | Teacher Today mang dữ liệu trẻ. Xây trên quyền đọc rộng hiện tại = **đưa `V114A-P1-5` ra mặt tiền**, biến phơi nhiễm đang tồn tại thành luồng dùng hàng ngày |
| **E4 trước S3** | Kiểm chứng phải xong trước khi phát hành, không phải sau |
| **Bất kỳ khôi phục Remote nào trước S1** | SEC0 vô hiệu Remote là có lý do; 4 residual risk vẫn mở |
| **E2 phát hành trước khi có quy tắc stale-state** | Sẽ tái tạo lỗi V114-H dưới một cái tên khác |

### 10.2 Việc phải làm ngoài mọi làn — gói remediation tiền-build

Ba việc **không** chờ V114B, **không** chờ SEC1A/SEC1B, **không** làm trong V114A:

1. **`V114A-P1-9`** — gỡ / ẩn / thay bằng trạng thái tắt trung thực cho cụm Remote. **Trước lần QA phiên dạy, pilot hoặc demo đối ngoại kế tiếp.**
2. **`V114A-P1-2`** — gỡ hoặc thay badge `Cần hỗ trợ` cấp lớp. **Trước School Hôm nay hoặc demo đối ngoại kế tiếp.**
3. **`V114-H`** — thu thập bằng chứng zero-data. Món nợ này **vẫn mở**; V114-H **chưa SEALED**.

---

## 11. CỔNG CÒN HIỆU LỰC

| Cổng | Trạng thái |
|---|---|
| V114B shell/switch/preference | ✅ **được tiến hành** — **chỉ khi** không mở rộng projection dữ liệu |
| Principal Today | 🚧 **cần** quy tắc trung thực + quy tắc stale-state trước khi phát hành |
| Teacher Today (phát hành) | 🚧 **BỊ CHẶN** bởi **SEC1A** và **SEC1B** |
| Thông điệp sai của Remote | 🔴 **phải gỡ trước lần QA/demo Teacher kế tiếp** |
| Badge `Cần hỗ trợ` cấp lớp | 🔴 **phải gỡ hoặc thay trước School Today / demo đối ngoại kế tiếp** |
| Edge Authorization Boundary Inventory | 🚧 **bắt buộc trước khi V114A closeout** — 16/16 hàm phải có phán quyết |
| V114C · SEC1A · SEC1B | ⛔ **không mở trong V114A** |

---

## 12. CỔNG CẦN OWNER QUYẾT — CÒN MỞ

| # | Câu hỏi | Chặn cái gì |
|---|---|---|
| **OG-1** | Tín hiệu khả dụng/vắng mặt nhân sự lấy từ đâu? (`V114A-P1-8`) | Principal Today dòng 2 & 3 ở §5.1 |
| **OG-2** | Định nghĩa vận hành của "quá hạn": biên độ ân hạn bao nhiêu? | E2, và khối "Còn tồn" của Teacher |
| **OG-3** | Fixture/demo được nhận diện bằng cách nào để loại khỏi mọi projection? | E2 — **chặn cứng** |
| **OG-4** | Mặc định riêng tư cho `child_observations` xuyên lớp (câu hỏi cho Cô Ngân) | SEC1B |
| **OG-5** | Quy trình offboarding thực tế của trường — vẫn `UNVERIFIED` | SEC1B |
| **OG-6** | GV nào cần bản ghi consent thô, hay chỉ cần kết quả quyền mức hành động? | Teacher Today #9 |
| **OG-7** | View mặc định của Hiệu trưởng chuyển sang `Hôm nay` ở thời điểm nào? | E2 phát hành |
| **OG-8** | Cho gửi nhật ký khi còn bé chưa điểm danh — giữ hay chặn? (hành vi hiện tại: **cho phép, có cảnh báo**) | Teacher T6 |

---

*Sinh trong V114A. Không canonicalize. Không cập nhật RULES/SYSTEM_MAP. Không code dual-view. Không mutate production.*
