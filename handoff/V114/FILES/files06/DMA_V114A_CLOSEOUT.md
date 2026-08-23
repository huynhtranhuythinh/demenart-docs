# DMA_V114A_CLOSEOUT.md

> **File 6/6** · Đóng sổ workstream audit V114A
> **Đây là phán quyết ĐỀ XUẤT để CTO/Owner duyệt. V114A CHƯA được tuyên bố đóng chính thức, CHƯA SEALED.**

---

## 1. PHÁN QUYẾT ĐIỀU HÀNH

> ## PROPOSED VERDICT: **V114A AUDIT COMPLETE — PASS WITH BLOCKERS**

Ba thứ dưới đây **khác nhau** và phải đọc tách bạch. Gộp chúng lại là cách một bản audit trung thực bị biến thành một tấm giấy thông hành.

| | Trạng thái | Nghĩa là gì |
|---|---|---|
| **Hoàn chỉnh về audit** | ✅ **ĐẠT** | Sáu file đã xuất đủ. 16/16 Edge Function có phán quyết, **0 UNVERIFIED**. Mọi phát hiện đều truy được về source thật hoặc DB sống. Không phát hiện nào bị âm thầm gỡ bỏ. |
| **Sẵn sàng về sản phẩm** | ⚠️ **MỘT PHẦN** | Teacher đã có nhịp làm việc thật; Principal **chưa có trục "hôm nay" trung thực**. Ba hợp đồng domain chưa tồn tại. Một hợp đồng route chưa chốt. |
| **Được phép phát hành** | ❌ **KHÔNG** | Không phần nào của trải nghiệm dual-view mang dữ liệu được phát hành cho tới khi qua các cổng ở §11. |

### Bốn phát biểu về chính V114A

1. **Không có dòng code dual-view nào được viết.** Không route mới, không component mới, không switch, không preference.
2. **Không có dữ liệu production nào bị thay đổi trong quá trình audit V114A.** Toàn bộ là đọc: `prosrc`, `pg_policies`, source Lovable đã commit, source Edge đã triển khai. Không migration, không INSERT/UPDATE/DELETE, không upload, không gửi mail, không đụng Auth.
3. **SEC0 và V114-H là hai can thiệp riêng, đã được phê duyệt riêng** — SEC0 ngăn chặn khẩn Remote, V114-H gỡ điểm sức khoẻ bịa. Chúng **không** thuộc phạm vi V114A; V114A chỉ **ghi nhận và kiểm chứng lại** kết quả của chúng.
4. **Bản thân V114A là công việc audit và đặc tả.** Không hơn.

---

## 2. BỘ SÁU FILE

| # | File | Mục đích | Trạng thái |
|---|---|---|---|
| 1 | `DMA_V114A_CURRENT_SYSTEM_AUDIT.md` | Kiểm kê route · tính trung thực nguồn dữ liệu · quyền & least-privilege | ✅ hoàn tất *(đã sửa diễn giải Audit 4)* |
| 2 | `DMA_V114A_SCHOOL_WORKSTYLE_MAP.md` | Journey Principal P1–P5 · content model Hôm nay · bảo tồn bề mặt School | ✅ hoàn tất *(đã áp 3 đính chính CTO)* |
| 3 | `DMA_V114A_TEACHER_WORKSTYLE_MAP.md` | Journey Teacher T1–T6 · ranh giới truy cập của GV | ✅ hoàn tất *(đã áp 5 đính chính CTO + 1 tự đính chính)* |
| 4 | `DMA_V114A_DUAL_VIEW_EXPERIENCE_ARCHITECTURE.md` | Bất biến sản phẩm · IA · ngữ pháp điều hướng · thứ tự build hai làn | ✅ hoàn tất *(đã áp 5 đính chính CTO)* |
| 5 | `DMA_V114A_GAP_REUSE_REMEDIATION_MATRIX.md` | Ma trận gap/tái dùng/khắc phục **+ Phụ lục A: Edge Inventory 16/16** | ✅ hoàn tất *(đã áp 5 đính chính CTO)* |
| 6 | `DMA_V114A_CLOSEOUT.md` | File này | ✅ hoàn tất |

> ⚠️ **File 1–5 KHÔNG phải bản thay thế canonical cho `DMA_RULES.md` hay `DMA_SYSTEM_MAP.md`.** Chúng là tài liệu làm việc của V114A. Việc canonicalize là một hành động riêng, cần Owner cho phép riêng, và **chưa xảy ra**.

---

## 3. BASELINE ĐÃ KIỂM CHỨNG

**Ngày chốt baseline: 20/07/2026.** Mọi con số dưới đây đọc trực tiếp từ hệ sống trong phiên này, không trích tài liệu lịch sử.

| Hạng mục | Giá trị |
|---|---|
| Code HEAD | `b87b576b` (`b87b576b40ab14e5e065e0cb10a9fb14a34704d1`) |
| Migrations | **103** |
| Tables | **87** |
| SECURITY DEFINER functions | **190** |
| RLS policies | **164** |
| Cron jobs | **1** |
| Routes | **52** |
| Edge Functions | **16** |
| **Độ phủ rà Edge** | **16/16** |

Đã đối chiếu với baseline bàn giao đầu phiên: **không có delta**.

---

## 4. PHÁT HIỆN SẢN PHẨM CHÍNH

| # | Phát hiện |
|---|---|
| 1 | **Principal không có trục "hôm nay" trung thực.** `get_school_overview` không có `now()`, không có `Asia/Ho_Chi_Minh` — thuần luỹ kế. Nguồn duy nhất có trục thời gian là lịch **tuần**, với `p_week_start` do client truyền. |
| 2 | **Teacher đã có luồng làm việc hàng ngày thật, nhưng hai đầu bị gãy.** T2→T3→T4→T6 gần như liền mạch. Gãy ở **đầu vào** (Hôm nay) và **đường quay lại** (Việc cần làm). Đây là bài toán **hoàn thiện**, không phải xây mới — đảo lại thứ tự sprint trong brief V114 gốc. |
| 3 | **`get_teacher_home` có `limit 1`.** Home báo `today_count = N` nhưng chỉ dựng **một** thẻ; `next_session` lọc `>= today_end` nên **không bao giờ** là tiết thứ hai trong ngày. GV nhiều tiết/ngày không có đường nào tới các tiết còn lại. |
| 4 | **Đếm việc cần làm không dẫn tới hành động.** `TodoSection` render `<div>`, `get_teacher_todo_counts` không trả `session_id`. Cô thấy còn việc nhưng phải tự nhớ lớp nào. |
| 5 | **Điều hướng theo lớp là ảo giác.** Mọi hàng trong `ClassProgress` gọi chung một `onView` → luôn về `?tab=classes`, không mở đúng lớp vừa bấm. |
| 6 | **Khoảng trống năng lực về tín hiệu vắng mặt.** Hệ biết **phân công**, không biết **sự có mặt**. Không suy ra được, và không có chỗ nào để biết. |
| 7 | **Thiếu hợp đồng domain cho quá hạn / bỏ ngỏ / fixture.** Không có ba quy tắc này thì mọi projection "Hôm nay" đều có nguy cơ tái tạo lỗi V114-H dưới tên khác. |
| 8 | **Preference hiển thị không được ảnh hưởng uỷ quyền.** Đã kiểm chứng: rà 164 policy, **không predicate nào** tham chiếu view/preference/chế độ hiển thị. Đây là fact, không phải niềm tin. |
| 9 | **Teacher `Toàn bộ` = toàn bộ công cụ được uỷ quyền, KHÔNG phải toàn bộ dữ liệu trường.** |
| 10 | **Luồng buổi học là ngữ cảnh làm việc trung lập với view, có nhận thức về nơi xuất phát.** Nó phải nhớ nơi được mở ra, thay vì `BackLink` cứng về `/teacher`. |
| 11 | **Hiệu trưởng phải phân công lại / uỷ quyền, KHÔNG làm thay cô.** RLS chặn admin ở `session_marks`, `session_media`, `child_observations`, `prep_items`. Đặt CTA "làm thay" = vi phạm **D290**. |

---

## 5. PHÁT HIỆN VỀ TÍNH TRUNG THỰC

| # | Phát hiện | Trạng thái |
|---|---|---|
| 1 | Điểm sức khoẻ trường bịa ở client — trung bình của ba bản sao cùng một phân số, mẫu số tính cả `in_progress` | ✅ **ĐÃ GỠ ở V114-H** (`b87b576b`) |
| 2 | **Nợ bằng chứng trực quan trạng thái zero-data** | ❌ **VẪN MỞ** — V114-H **chưa SEALED** |
| 3 | **Badge `Cần hỗ trợ` cấp LỚP** — verdict ngưỡng một chiều trên `journal_pct`, n=3, 2/3 là fixture chết | ❌ **MỞ · P1** |
| 4 | **Fixture bỏ dở không được trở thành cảnh báo vận hành.** Hai buổi KHM kẹt `in_progress` từ 03/07 và 14/07 là **dữ liệu thử nghiệm**, không phải buổi quá hạn | ❌ **MỞ · cần DC-3** |
| 5 | **Thông điệp trạng thái tắt của Remote đang nói dối.** `mint_session_remote_code` là thân hàm rỗng trả `remote_temporarily_disabled`; `mapRemoteReason` không có nhánh đó nên hiện *"kiểm tra mạng rồi thử lại"* kèm nút **Thử lại**. Hệ đổ lỗi cho mạng của trường và mời cô bấm lại một việc chắc chắn hỏng | ❌ **MỞ · P1 · phải khắc phục trước lần QA / pilot / demo Teacher kế tiếp** |

---

## 6. PHÁT HIỆN BẢO MẬT & QUYỀN RIÊNG TƯ

| # | Hạng mục | Trạng thái |
|---|---|---|
| 6.1 | **SEC0 — ngăn chặn Remote** | ✅ **PASS và được chấp nhận.** `capture_session_media` `verify_jwt:true`, trả 503, không parse body, không side effect. `capture_session_moment` stub 410. Bề mặt ghi ẩn danh đã đóng |
| 6.2 | **`V114-SEC1A-R` — Remote của Giáo viên** | ❌ **MỞ.** Mang nguyên vẹn **4 residual risk của SEC0** |
| 6.3 | **`V114-SEC1A-K` — siết ghép thiết bị Cổng Kid** | ❌ **MỞ · GÓI P1 MỚI** *(phát hiện trong Edge inventory)* |
| 6.4 | **`V114-SEC1B` — least-privilege · uỷ quyền · offboarding** | ❌ **MỞ** |
| 6.5 | **Phơi nhiễm ngang liên-lớp ở trạng thái đã xác thực, đang tồn tại** | GV đọc được bản ghi buổi toàn trường → `session_id` **không phải bí mật uỷ quyền** → bốn RPC vào-buổi nhận chính những ID đó và trả dữ liệu trẻ của lớp khác. **Lọc ở UI không làm giảm quyền hiệu lực** |
| 6.6 | **Bốn RPC vào-buổi rộng** | `get_session_detail` · `get_session_roster` · `get_session_moments` · `get_lesson_guide` — chỉ gate `same_school`, trong khi bốn RPC danh-sách gate đúng phân công. **Danh sách thì đúng, cửa vào thì rộng** |
| 6.7 | **Nhánh signed-media same-school** | **1 trong 6 nhánh** của `get_signed_media_url` mang P1. Năm nhánh còn lại PASS |
| 6.8 | **Không tìm thấy năng lực offboarding ở tầng ứng dụng** | Rà 190 secdef + 16 Edge: có đủ chuỗi *kết nạp*, **không có hàm đối xứng để gỡ**. Không guard nào đọc `profiles.state` |
| 6.9 | **Nợ tối thiểu hoá consent thô và liên hệ PH** | GV đọc 20 bản ghi consent thô; `email`/`phone` mở toàn trường qua `profiles` |
| 6.10 | **Moment nháp lộ toàn trường** | Nhánh trường **không** đòi `state='approved'` (nhánh PH thì có) |

### 6.11 Phân biệt bắt buộc — phơi nhiễm nội bộ ≠ rò rỉ liên trường

**Toàn bộ các phát hiện 6.5–6.10 là PHƠI NHIỄM NỘI BỘ TRONG MỘT TRƯỜNG.**

Cơ sở đã kiểm chứng: `user_school_ids()` khoá theo `profiles.school_id` → **không rò rỉ liên trường**; **không** có ghi ẩn danh mới (đã đóng ở SEC0); **không** phụ huynh nào đọc được dữ liệu trường; Edge inventory xác nhận **0 hàm nào cho phép đọc/ghi liên trường**.

> **Không gọi phơi nhiễm nội bộ là P0.** Mức đúng: **P1 — Current Internal Exposure**, *build-blocking cho các trải nghiệm Teacher có dữ liệu, nhưng không đòi hỏi dừng khẩn production.* Thổi phồng lên P0 làm hỏng thang đo cho lần thực sự cần nó.

---

## 7. TÓM TẮT EDGE AUTHORIZATION BOUNDARY

**16/16 rà xong. 0 UNVERIFIED.** `verify_jwt:false` ở 15/16 hàm **không phải khiếm khuyết** — đây là phân bố cơ chế xác thực đã kiểm chứng:

| Cơ chế | Số | Hàm |
|---|---|---|
| `auth.getUser()` nội bộ | **8** | `get_signed_media_url` · `upload_media` · `invite_staff` · `invite_master` · `delete_session_media` · `school_media_admin` · `upload_notification_sound` · `upload_kid_game_sound` |
| Luồng public có chủ đích, credential chuyên dụng | **4** | `accept_parent_invitation` · `accept_family_invitation` · `resolve_share_link` · `kid_gate` |
| Stub đã nghỉ hưu, từ chối vô điều kiện | **2** | `invite_parent` (410) · `capture_session_moment` (410) |
| Bí mật cron phía server | **1** | `purge_trash` |
| `verify_jwt:true`, hiện fail-closed 503 | **1** | `capture_session_media` |

| Phán quyết | Số |
|---|---|
| PASS | **6** |
| PASS WITH P2 DEBT | **8** |
| P1 — SEC1A-K | **1** |
| P1 — SEC1B | **1** |
| **P0** | **0** |
| **UNVERIFIED** | **0** |

> **Phán quyết nhạy theo nhánh khi cần.** `get_signed_media_url` mang P1 **chỉ ở nhánh `private_school_resource` same-school**; các nhánh entitlement · guardian · family · suy-từ-consent · moment School đã duyệt đều **PASS**. Không được xếp mọi consumer của hàm này là bị chặn. Tương tự, SEC1B phải định nghĩa quyền **theo lớp tài nguyên** — và **không được gỡ máy móc quyền same-school khỏi tài nguyên thể chế chính đáng** như thư viện giáo trình hay kho trường.

Về ghi công và audit, phát biểu đúng phạm vi bằng chứng: **các mutation của nhân sự đã xác thực được rà trong inventory này đều suy ra danh tính người thực hiện từ người gọi đã được server xác minh, và không tin định danh actor do client gửi**; luồng public, luồng thiết bị và luồng hệ thống dùng mô hình quy kết khác hoặc không có người thực hiện là con người. **Quan sát thấy audit trên các nhánh nhạy cảm về bảo mật đã ghi trong inventory từng hàm** — không suy rộng thành audit phủ kín toàn hệ.

---

## 8. SỔ ĐĂNG KÝ KHIẾM KHUYẾT

### 8.1 P0

| ID | Mô tả | Trạng thái | Chủ | Chặn phát hành? |
|---|---|---|---|---|
| `V114A-P0-1` | `/remote` — điều khiển & upload ẩn danh, mã 4 số, không TTL/rate-limit/audit | ✅ **ĐÓNG (SEC0)** | — | — |
| `V114A-P0-2` | Upload từ Remote ghi danh nghĩa cô giáo → bằng chứng audit sai | ✅ **ĐÓNG (SEC0)**; provenance thuộc SEC1A-R | SEC1A-R | — |

**Không có P0 nào đang mở.**

### 8.2 P1 đang mở

| ID | Mô tả | Chủ | Chặn phát hành | Nguồn bằng chứng |
|---|---|---|---|---|
| `P1-2` | Verdict `Cần hỗ trợ` cấp **lớp** — server-side, một chiều, n nhỏ | **Gói R** | **School Today / demo đối ngoại kế** | `get_school_overview` `prosrc` |
| `P1-3` | Todo counts không actionable (không trả `session_id`) | E4 | Teacher Today | `get_teacher_todo_counts` `prosrc` |
| `P1-5` | Đọc rộng toàn trường cho GV; `user_class_ids()` không dùng ở policy nào | **SEC1B** | **Teacher Today** | 27 policy SELECT · `pg_policies` |
| `P1-6` | Quyền không co lại sau đổi phân công / nghỉ việc; không có năng lực gỡ quyền ở tầng ứng dụng | **SEC1B** | **Teacher Today** | rà 190 secdef + 16 Edge |
| `P1-7` | `ClassProgress` — điều hướng theo lớp là ảo giác | E3 | — | `school.index.tsx` |
| `P1-8` | Không có tín hiệu khả dụng/vắng mặt nhân sự | **OD-1** | Principal Today | không nguồn nào |
| `P1-9` | Cụm Remote nói dối và mời thử lại vô hạn (**D290**) | **Gói R** → SEC1A-R | **QA/pilot/demo Teacher kế** | `mint_session_remote_code` `prosrc` + `teacher.session.$id.tsx` |
| `P1-10` | `get_teacher_home` `limit 1`; nhãn "Lớp tiếp theo" sai | E4 | Teacher Today | `get_teacher_home` `prosrc` |
| `P1-11` | Todo dùng khung thời gian không nhất quán; thiếu quy tắc điểm danh quá hạn | **DC-1** | Teacher Today | `get_teacher_todo_counts` `prosrc` |
| `P1-12` | Bước 4 dựng CTA gửi nhật ký cho **trợ giảng** (**D290 · D293**) | **Gói R** / E4 | — | `submit_session_journal` `prosrc` |
| `EDGE-P1-A` | `kid_gate` `pair` — mã 6 số, không đếm lần thử, không khoá, không chặn gọi song song | **SEC1A-K** | **phát hành ghép thiết bị Kid** | Edge #8 + `kid_pair_device_service` |
| `EDGE-P1-B` | Nhánh `private_school_resource` của `get_signed_media_url` | **SEC1B** | media buổi/trẻ | Edge #1 |

### 8.3 Mục đính chính audit — **không phải khiếm khuyết đang mở**

| ID rút | Nội dung | Vì sao rút |
|---|---|---|
| ~~`V114A-P2-7`~~ | "`/teacher/moments` là route mồ côi" | **SAI.** Đọc source thật cho thấy đây là **redirect có chủ đích từ V89**: toast + `navigate('/teacher', replace: true)`, xử lý bookmark cũ đúng chuẩn. Kết luận ban đầu suy từ việc vắng mặt trong nav — đúng thứ suy-đoán-từ-tên-route đã bị cấm. **Ghi lại ở đây, không xoá lặng.** |

Một giả định nữa của bản audit trước cũng được rút: `?tab=` **không** phải điều hướng không-địa-chỉ-hoá-được — `school.tsx` đã khai báo `search: { tab }` đúng chuẩn. Thiếu hụt thật hẹp hơn: **deep link cấp thực thể** (lớp · giáo viên · buổi).

---

## 9. QUYẾT ĐỊNH VÀ HỢP ĐỒNG CÒN MỞ

### 9.1 Owner Decisions — chỉ Owner quyết được

| # | Quyết định | Chặn |
|---|---|---|
| **OD-1** | Nguồn tín hiệu vắng mặt / không khả dụng của nhân sự | Principal Today (tình huống 2 & 3) |
| **OD-2** | **Hợp đồng route gốc của Principal + thời điểm đổi view mặc định** — Phương án A (gốc là Hôm nay, dời Quản lý sang `/school/manage`) hay Phương án B (gốc vẫn là Quản lý, thêm bộ giải preference ở mọi điểm vào) | **build V114B** |
| **OD-3** | Còn cho gửi nhật ký khi điểm danh chưa đủ không? *(hành vi hiện tại: cho phép, có cảnh báo)* | Teacher T6 |

### 9.2 Domain Contracts — đội ngũ soạn, Owner duyệt

| # | Hợp đồng | Chặn |
|---|---|---|
| **DC-1** | Quy tắc quá hạn + biên độ ân hạn | Principal Today · khối "Còn tồn" của Teacher |
| **DC-2** | Phân loại buổi bỏ ngỏ (stale) | Principal Today |
| **DC-3** | Loại trừ fixture/demo khỏi mọi projection | **Principal Today — chặn cứng** |

*Ba hợp đồng dùng chung cho cả hai persona. Một định nghĩa, hai ống kính.*

### 9.3 Operational Validation — đầu vào cho SEC1B, **không phải cổng độc lập**

| # | Cần kiểm chứng |
|---|---|
| **OV-1** | Quy trình offboarding nhân sự thực tế của trường — `UNVERIFIED` |
| **OV-2** | Nhu cầu xem nhận xét phát triển xuyên lớp |
| **OV-3** | Bản ghi consent thô hay chỉ kết quả quyền mức hành động |

---

## 10. ĐƯỢC PHÉP TIẾN HÀNH

| Việc | Điều kiện |
|---|---|
| **V114B — shell · switch · preference** | **chỉ sau khi chốt OD-2**, và **chỉ khi không đưa vào bất kỳ projection dữ liệu rộng hơn nào** |
| **Re-home School Management + thiết kế deep link cấp thực thể** | tiến hành được ngay |
| **Đặc tả DC-1 · DC-2 · DC-3** | tiến hành được ngay — quy tắc domain không phụ thuộc bảo mật |
| **Gói remediation tính trung thực tiền-build (Gói R)** | tiến hành được ngay — cả ba việc đều là **gỡ bỏ**, không mở rộng: gỡ thông điệp Remote sai · gỡ/thay badge lớp · tắt CTA gửi nhật ký cho trợ giảng |

---

## 11. VẪN BỊ CHẶN

| Bị chặn | Bởi |
|---|---|
| **Phát hành Principal Today** | DC-1 · DC-2 · DC-3 **và** kiểm chứng projection trung thực |
| **Phát hành dữ liệu Teacher Today** | **SEC1B + controlled validation** |
| **Remote** | **SEC1A-R** |
| **Phát hành ghép thiết bị Cổng Kid** | **SEC1A-K** |
| **Uỷ quyền tạm thời / dạy thay** | **SEC1B** |
| **V114C** | vẫn bị chặn theo cách đặt tên mốc hiện hành |

> ⚠️ **`SEC1A-K` chỉ chặn phát hành ghép thiết bị Cổng Kid.** Nó **không** chặn nền dual-view, không chặn Principal Today, không chặn phần IA Teacher không liên quan Remote. Đừng để một gói bảo mật hẹp bị dùng làm cớ đóng băng những việc không liên quan.

---

## 12. THỨ TỰ MỐC KHUYẾN NGHỊ

```
LÀN TRẢI NGHIỆM                        LÀN BẢO MẬT
──────────────────                     ────────────────
R   Remediation tính trung thực        S1-R  SEC1A-R  Remote
    tiền-build (gỡ 3 thứ nói dối)            (mang 4 residual SEC0)
        │                                        │
OD-2  Owner chốt hợp đồng route        S1-K  SEC1A-K  Ghép thiết bị Kid
        │                                        │
E1  V114B shell · switch ·             S2    SEC1B  least-privilege ·
    preference                                uỷ quyền · offboarding
        │                                        │
E2  Đặc tả + kiểm chứng DC-1/2/3        S3    Controlled validation
        │                                     (PASS/FAIL riêng từng gói)
E2' Principal Today —                            │
    projection trung thực                        │
        │                                        │
E3  Re-home School Management                    │
        │                                        │
        └────────► 🚧 CỔNG CỨNG ◄───────────────┘
                        │
              E4  Hoàn thiện Teacher Today
```

### 12.1 Chạy song song được

| Song song | Vì sao |
|---|---|
| `R ∥ S1-R ∥ S1-K ∥ S2` | Gói R chỉ **gỡ bỏ**, không thêm bề mặt |
| `E1 ∥ S1-R ∥ S1-K ∥ S2` | E1 chỉ chạm shell và preference; view không tham gia uỷ quyền |
| `E2 ∥ E3 ∥ S2` | Bề mặt Principal không đụng ranh giới quyền của GV |
| `S1-R ∥ S1-K` | Hai mô hình mối đe doạ khác nhau, **QA và rollback riêng** |

### 12.2 Cổng cứng — không được song song

| Không được | Vì sao |
|---|---|
| **E4 trước S2** | Teacher Today mang dữ liệu trẻ. Xây trên quyền đọc rộng hiện tại = **đưa phơi nhiễm đang tồn tại ra mặt tiền** |
| **E4 trước S3** | Kiểm chứng phải xong **trước** phát hành |
| **E1 trước OD-2** | Hợp đồng route chưa chốt thì shell không có nơi để đứng |
| **E2' phát hành trước DC-3** | Fixture sẽ lên báo cáo của Hiệu trưởng — tái tạo lỗi V114-H dưới tên khác |
| **Khôi phục Remote trước S1-R** | 4 residual risk của SEC0 vẫn mở |
| **Phát hành ghép Kid trước S1-K** | `EDGE-P1-A` |

---

## 13. NỢ CÒN LẠI

Ghi lại đầy đủ. **Không mục nào được biến mất chỉ vì nó không chặn File 6.**

| # | Nợ | Loại |
|---|---|---|
| 1 | **Ảnh chụp trạng thái zero-data của V114-H** — V114-H **chưa SEALED** | bằng chứng QA |
| 2 | Không rate-limit trên endpoint public *(Edge #6·7·8·9)* | P2 Edge |
| 3 | `listUsers` trần phân trang 200 / 2000 user *(Edge #3·4·6·7)* | P2 Edge |
| 4 | Không kiểm magic-byte, chỉ tin MIME + đuôi tệp *(Edge #2·15·16)* | P2 Edge |
| 5 | Token share lưu **plaintext** khi nghỉ, trong khi token lời mời lưu sha256 *(Edge #9)* | P2 Edge |
| 6 | Xoá vĩnh viễn không có cửa sổ hoàn tác, lệch mô hình thùng rác *(Edge #13)* | P2 Edge |
| 7 | So sánh bí mật không hằng thời gian; bí mật cron tĩnh, chưa thấy cơ chế xoay vòng *(Edge #14)* | P2 Edge |
| 8 | **Nhập nhằng consent trong album Kid** — `child_parents ... limit(1)` chọn **một người giám hộ bất kỳ** làm căn cứ; khi hai người giám hộ có trạng thái consent khác nhau, hệ chọn tuỳ tiện. Trái tinh thần MIN-consent áp ở mọi nơi khác | P2 → SEC1B + OV-3 |
| 9 | Nhãn nav Teacher "Giáo án" trỏ tới thư viện track; `/teacher/media` mang nhãn "Học liệu" — **hai nhãn hoán đổi** | P2 đặt tên |
| 10 | `/school/moments` không có trong nav shell School | P2 điều hướng |
| 11 | Ô lịch tuần không click được; ảnh khoảnh khắc không mở lớn | P2 điều hướng |
| 12 | Nhãn KPI "trên buổi đã dạy" không tiết lộ rằng "đã dạy" gồm cả `in_progress` | P2 trung thực |
| 13 | Badge `👶 N bé đã điểm danh` sai nghĩa — `obs_count` đếm mọi `child_observations` kể cả khi `attendance IS NULL` | P2 trung thực |
| 14 | Dòng "Phản hồi phụ huynh mới" là affordance chết (`v_parent_replies` hardcode 0) | P2 |
| 15 | Checklist chuẩn bị đọc một nơi / tick một nơi; `PrepCard` tự ẩn khi `total === 0`, không phân biệt được với đang tải | P2 |
| 16 | **Hiệu năng: N lần invoke Edge ký ảnh** ngay lần sơn đầu của `school.index` và Tab Ảnh | P2 hiệu năng |
| 17 | `learning_moments` / `prep_items` gán policy cho role `{public}` thay vì `{authenticated}` | P2 hygiene |
| 18 | **Quy trình vận hành thủ công vẫn `UNVERIFIED`** — offboarding qua Supabase Dashboard / Auth Admin / ngoài ứng dụng | vận hành |

---

## 14. KHUYẾN NGHỊ CUỐI

> **Khuyến nghị hành động cho CTO/Owner:** chấp nhận V114A là **AUDIT COMPLETE — PASS WITH BLOCKERS**, và **chỉ phê duyệt mốc có giới hạn tiếp theo sau khi đã xem xét các Owner Decision còn mở và việc tách gói bảo mật.**

Khuyến nghị này **chưa được phê duyệt**. Phán quyết chính thức thuộc về CTO/Owner sau khi duyệt File 6.

**Không có P0 nào đang mở. Production đang ổn định** — không cần dừng khẩn; các phơi nhiễm đã ghi đều nằm trong nội bộ một trường và là build-blocking, không phải incident-blocking.

---

*Sinh trong V114A. Không canonicalize. Không cập nhật RULES/SYSTEM_MAP. Không code. Không mutate production. Không mở V114B, SEC1A-R, SEC1A-K hay SEC1B.*
