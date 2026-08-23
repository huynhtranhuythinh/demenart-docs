# 📦 DMA_HANDOFF_v104.md — V104 REAL PILOT FRICTION REMOVAL (12/07/2026)

## 1. Canonical endpoint
RULES **D268** · SYSTEM_MAP **v0.97** · Handoff **v104**

**Inventory: 75 / 143 / 160 / 1** — **0 migration ở toàn bộ V104.**
Registry: modules **75** · routes **47** · playbooks **12**.
Edge đổi: `upload_media` **v16** · `accept_parent_invitation` **v2**. Không đụng schema/policy/consent.

**Baseline live (đo, không giả định):**
- An: **6 Tác phẩm · 2 Âm thanh · 6 Khoảnh khắc** · **20 kỷ vật gia đình**
- Evidence: **40 events · 33 groups** · DC11 / OBS22 / PART6
- Readiness: **v2 · emerging · contemporaneous**
- `product_events`: **205** (đầu ngày: 9) · consents **35** · dup `user_id` **0**

> ⚠️ Số của An đã dịch mạnh so với v103 (5 → 20 kỷ vật, evidence 24/18 → 40/33). **Đây không phải drift — đây là dấu chân người dùng thật.** Phụ huynh pilot đầu tiên đã dùng sản phẩm suốt buổi tối.

---

## 2. V104 là gì

**Sprint đầu tiên trong lịch sử DMA không có một dòng nào đến từ giả định nội bộ.**

Mọi thay đổi đều truy được về **một câu một người mẹ nói**, hoặc **một hàng dữ liệu chị ấy để lại**.

---

## 3. Người dùng thật đầu tiên — và điều chị ấy lộ ra

19:12 → 19:36 HCM. iPhone. Tài khoản `@gmail.com` thật, không phải demo. **9 kỷ vật trong 24 phút.**

| Giờ | Kỷ vật | Media |
|---|---|---|
| 19:12 | Tranh đậu | **3 ảnh** ✅ |
| 19:18 | Bé đi học trường mới | **1 ảnh** ✅ |
| 19:20 | Bé học múa ở Dế Mèn | **1 ảnh** ✅ |
| 19:24 | Hôm nay con được điểm 10 | 0 *(note, cố ý)* |
| **19:25** | **Con đọc TVC** *(audio)* | **0** 🔴 |
| *19:25→19:31* | ***6 PHÚT IM LẶNG TUYỆT ĐỐI*** | |
| **19:31** | Con học đàn | **0** 🔴 |
| **19:33** | Học đàn ← *tạo lại* | **0** 🔴 |
| **19:34** | Làm sổ | **0** 🔴 |
| **19:36** | Làm sổ mầu hồng ← *tạo lại* | **0** 🔴 |

Chị **biết** dùng bộ chọn tệp — 3 lần đầu upload ảnh ngon lành. Cái đổi là **loại tệp**: ghi âm `.m4a` và video `.mov`.

`preValidateFile()` chặn cả hai **ngay trên máy chị**. Tệp **chưa bao giờ rời khỏi iPhone**.

Và chị **tạo lại kỷ vật hai lần**, vì tưởng **mình** làm sai.

---

## 4. 🔴 Phát hiện quan trọng nhất — cái không ai nói ra

Trong suốt 24 phút đó, `/admin/pilot-funnel` báo:

> **9/9 kỷ vật lưu thành công · 0 upload failure**

Vì `preValidateFile()` chặn ở client ⇒ **không gọi Edge** (`media_upload_denied = 0`) ⇒ **không ghi telemetry** (`upload_start` vắng mặt).

**Cửa ải mà người dùng thật sự chết ở đó — bộ lọc client — hoàn toàn mù.**

V102 dựng funnel để *"thấy họ mắc ở đâu"*. Nhưng nó chỉ đo được thất bại **sau khi tệp rời khỏi máy**.

> **Nếu chị Ngân im lặng bỏ đi, số liệu vẫn xanh, và chúng ta vẫn tin là ổn.**

⇒ **D264.** Commit đầu tiên của V104 không sửa được gì cho người dùng. Nó chỉ khiến chúng ta **không thể tự lừa mình theo cách đó nữa.**

---

## 5. 8 thứ đã sửa

| # | Phụ huynh nói | Sự thật tìm ra |
|---|---|---|
| 1 | "thu âm iPhone không lên" | `accept` thiếu **đuôi tệp** + iOS trả `file.type` **rỗng** ⇒ rơi vào `"other"` |
| 2 | "video không lên" | `PARENT_VIDEO_TYPES` **chỉ MP4** — chặn cứng mọi iPhone. Nhánh GV **vốn đã** nhận quicktime |
| 3 | "không tìm ra chỗ upload" | Composer **tạo kỷ vật TRƯỚC** khi hiện nút upload ⇒ **5 thẻ rỗng** |
| 4 | "mật khẩu 8 khó" | **Supabase Auth vốn đã cho 6.** Rào 8 do **chính code của mình** dựng |
| 5 | "nội dung nằm dưới ảnh" | — |
| 6 | "không thấy nút sửa" | **Có** — nhưng là chữ 12px nằm dưới media |
| 7 | "phóng to không vuốt được" | Trục ngang **được nhận diện rồi vứt đi** |
| **8** | *(không ai nói)* | 🔴 **Funnel mù với mọi thất bại client-side** |

**Vòng 2 (V104-B.1→B.5):** upload above-the-fold + 3 nút loại + nút Lưu dính đáy · **OG preview** (gốc: `og:image` = ảnh app trống của Lovable) · **radio Telefunken ngang** · **banner Zalo in-app** · **kỷ vật nhiều loại media chỉ hiện 1 loại** (D268) → carousel: **Polaroid / TV cổ ăng-ten râu / Radio**.

---

## 6. Bằng chứng thắng lợi — đo live

| | Đầu ngày | Cuối ngày |
|---|---|---|
| `video/quicktime` đã lưu | **0** | **2** |
| `audio/*` đã lưu | **0** | **2** |
| `product_events` | 9 | **205** |
| Kỷ vật client-reject bị bỏ sót | *không đếm được* | **0 (và giờ đếm được)** |

**19:55 — "Vui 2" — `video/quicktime`. Video đầu tiên trong lịch sử DMA.**
**19:59 — "Con nói hay" — `audio/x-m4a`. Giọng con, thu từ iPhone, lần đầu tiên.**

Đúng hai thứ mà 40 phút trước hệ thống chặn sạch.

---

## 7. Nợ V105

- 🔴 **Share từ card — DEFER có chủ đích.** `create_private_share_link` **chỉ nhận `moment_id`**; không có đường share `parent_memories`. Nhưng blocker thật **không phải hạ tầng**: ảnh nhóm ≥2 bé → share = **phơi con nhà khác** (MIN-consent D71/D104); *"chia sẻ lên TikTok"* = đưa **mặt một đứa trẻ** lên nền tảng công khai **vĩnh viễn**, trong khi signed URL của DMA sống **10 phút**. **Không làm nút share giả.**
- 🟡 **Password reset tự phục vụ.** Hotline sống được với **1** phụ huynh. **Không** sống được với 30 — anh sẽ nhận điện thoại lúc 10 giờ đêm.
- 🟡 Nhãn media theo **từng tệp** thay vì theo kỷ vật (thẻ 3 tệp không biết radio đang phát tệp nào).
- 🟡 **5 kỷ vật rỗng của bé An** (19:25–19:36). Nút Sửa giờ dễ thấy — phụ huynh tự thêm tệp được. **Claude KHÔNG tự đụng vào dữ liệu gia đình.** Chờ CTO quyết.
- 🟡 P1 operator self-invite (V103, governance debt) · P3 copy `/auth` · repo chưa lưu.
- ⚪ TV cổ: nền kem thừa hai bên video dọc — polish tuỳ chọn.

---

## 8. Trạng thái

# V104 — REAL PILOT FRICTION REMOVAL: **CLOSED** · **PILOT CONTINUES**

---

## 9. Bài học

1. **Một lần từ chối không được ghi lại là một lần từ chối không hề tồn tại.** Đây là bài học đắt nhất của cả sprint, và nó không đến từ phản hồi nào — nó đến từ việc **đối chiếu lời chị Ngân với số liệu của chính mình** và thấy hai thứ đó **mâu thuẫn**.

2. **Định dạng của người dùng, không phải định dạng của mình.** `PARENT_VIDEO_TYPES = ["video/mp4"]` được viết như một lựa chọn kỹ thuật hợp lý. Thực tế nó là câu: *"phụ huynh dùng iPhone không được đăng video."* Không ai cố ý viết ra câu đó. Nhưng code thì đã nói.

3. **`return` không phải `rollback`** (V103) và **URL cũng là một khẳng định** (V104). Hai lần trong một ngày, Claude đoán ở đúng chỗ tưởng là an toàn nhất — một câu lệnh, một chuỗi ký tự — và cả hai lần đều sai. **D1 không có ngoại lệ.**

4. **Rào cản khắc nghiệt nhất thường là do chính mình dựng lên và quên mất.** Mật khẩu 8 ký tự: Supabase **vốn đã cho 6**. Không ai quyết định làm khó phụ huynh. Chỉ là một con số ai đó gõ đại, rồi không ai hỏi lại.

5. **Người dùng thật kiên nhẫn hơn ta tưởng, và điều đó nguy hiểm.** Chị Ngân thất bại 5 lần, ngồi im 6 phút, tạo lại kỷ vật hai lần — **và vẫn tiếp tục thử**. Nếu chị bỏ cuộc lặng lẽ, chúng ta sẽ không bao giờ biết. **Sự kiên nhẫn của người dùng là thứ ta không có quyền tiêu xài.**
