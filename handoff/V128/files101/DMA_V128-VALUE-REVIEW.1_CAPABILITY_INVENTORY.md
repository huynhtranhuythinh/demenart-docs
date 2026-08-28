# 📊 V128-VALUE-REVIEW.1 — CURRENT CAPABILITY INVENTORY REPORT

> **Mode:** PRODUCT VALUE REVIEW · READ ONLY · Role = Product Architecture Analyst
> **Câu hỏi cốt lõi:** *"DMA hôm nay THẬT SỰ làm được gì cho người dùng?"*
> **Grounding:** SYSTEM_MAP v1.67 + HANDOFF V128-B14 (mới nhất) + chuỗi log "tới đâu ghi tới đó" V16→V128. Read-only, 0 mutation.
> **Endpoint audit tại:** RULES D379 · SYSTEM_MAP v1.67 · FE HEAD `6a0f3504` · backend tail `20260820122518`.

---

## ⭐ 0 · Phát hiện đầu tiên (headline cho một value review)

DMA **KHÔNG phải** "kiến trúc chưa có sản phẩm". Nó là **một sản phẩm đã chạy thật, nghiệm thu login-thật xuyên cả 5 cổng**, với vòng lõi Teacher→Parent khép kín.

Điểm cần chỉnh lại nhận thức: **Mission Control (B-series, tiêu điểm hiện tại) là lát MỎNG NHẤT & MỚI NHẤT của hệ**, không phải trái tim giá trị. Toàn bộ khung governed-action (registry + ledger + resolver + executor + lifecycle + audit→memory) đã dựng công phu, **nhưng chỉ 2 hành động thật sự wired end-to-end**: `class.assign` và `class.edit` (name-only). Trong khi đó, giá trị pilot thật đang nằm ở **Teacher session flow, Parent journal, School self-manage, Kid creative world** — đã sống từ V30→V110.

→ Nếu đo bằng "người dùng pilot mở app hôm nay bấm được gì có ích", thì **sản phẩm dày, Mission Control mỏng.**

---

## 1 · EXISTING CAPABILITIES — kiểm kê theo cổng

Ký hiệu giá trị: **A** = pilot dùng ngay · **B** = móng có, cần hoàn thiện UX/luồng · **C** = mới kiến trúc, chưa giá trị người dùng.

### 1.1 · PARENT `/parent` (amber) — cổng dày nhất, nghiệm thu thật nhiều nhất

| Capability | Route | Behavior hiện tại | Giá trị người dùng | Score |
|---|---|---|---|---|
| **Nhật ký nghệ thuật của con** (TRÁI TIM) | `/parent/journal` | Timeline dọc "Cây ký ức" — buổi học / tác phẩm / âm thanh / khoảnh khắc gộp theo ngày-tháng; leaf compact → lightbox chi tiết (gallery đa-ảnh, ký on-demand); recording audio phát inline; "Cô nhận xét"; kỹ năng ("Hát theo") | Ba mẹ **thấy hành trình con qua nghệ thuật** — đúng linh hồn sản phẩm | **A** |
| **Home / Cửa vào hành trình** | `/parent` | Hero ấm "Chào ba mẹ của {tên}", child-selector đa-con, summary (N tác phẩm / N âm thanh / N khoảnh khắc), memory highlights 2–3 lá gần nhất, "Hạt giống nổi bật" | Điểm chạm đầu tiên, dẫn vào journal | **A** |
| **Nhìn lại / Bản Khám Phá** | `/parent/discovery` | Art Discovery Capsule (evidence→readiness→capsule, **deterministic KHÔNG AI**); 3 cửa sổ 3/6/12 tháng; "Điều dữ liệu đang dần cho thấy" / "Những dấu vết đã ghi nhận"; gợi ý trò chuyện; MeaningBridge 3-state ở home | Ý nghĩa > số liệu; cho ba mẹ chiều sâu — nhưng **cần đủ evidence mới hiện** (nhiều bé chưa đủ) | **B** |
| **Quyền riêng tư của con (Consent)** | `/parent/consent` | 4 nhóm toggle; tắt/bật quyết định ảnh hiện downstream tức thì; "Vì sao?" hint | Chủ quyền dữ liệu trẻ nằm tay ba mẹ — bán hàng được | **A** |
| **Chia sẻ ảnh ra ngoài (Share link)** | `/parent/journal` | Vòng đời đầy đủ: tạo → copy → thu hồi; consent-gated; link tự chết khi rút consent | Khoe con an toàn, kiểm soát được | **A** |
| **Sau buổi học (Outcome loop)** | `/parent` | Card "buổi học vừa xong" từ GV; featured + lịch sử compact; deep-link vào journal | Khép vòng GV→PH, ba mẹ biết hôm nay con học gì | **A** |
| **Lời cảm ơn (Appreciation)** | `/parent` | Gửi tim + preset tới cô; cô "đã đọc"; ≠ chat/rating | Kết nối cảm xúc PH↔GV, nhẹ nhàng | **A** |
| **Thêm kỷ vật ngoài DMA** | journey viewer | PH tự thêm ký ức (thép chờ "nhật ký treo vào TRẺ") | Mở nhật ký xuyên-nguồn — móng V2 | **B** |
| **Family Memory Network (FMN)** | `/parent` (family space) | Không gian gia đình riêng tư; mời ông bà/người thân; đóng góp text/voice; living archive chaptered stream; membership ≠ guardianship | Biến nhật ký thành nơi cả gia đình quay lại — **khác biệt cạnh tranh lớn** | **B** |
| **Cổng của bé (quản lý)** | `/parent/kid` | Bật/tắt, khung giờ, PIN, ghép/thu hồi thiết bị | Ba mẹ kiểm soát quyền vào của con (V2) | **B** |
| **Cài đặt** | `/parent/settings` | Thiết lập cá nhân | Phụ trợ | **B** |

### 1.2 · TEACHER `/teacher` (ivory/forest/honey) — cổng "làm việc" hoàn chỉnh nhất

| Capability | Route | Behavior | Giá trị | Score |
|---|---|---|---|---|
| **Home Classroom Companion** | `/teacher` | Dashboard: buổi hôm nay + readiness (4 trạng thái), việc-cần-làm (điểm danh/nhật ký/ảnh chờ), quick actions, lớp tiếp theo | GV mở app biết ngay "hôm nay dạy gì, còn thiếu gì" | **A** |
| **Luồng dạy 4 bước** | `/teacher/session/$id` | Chuẩn bị (checklist + báo thiếu học liệu) → Trong giờ (Lesson Player + Teaching Guide) → Ghi nhận (điểm danh + tap-first observation + ảnh-gắn-bé) → Hoàn tất (review + gửi nhật ký tới PH) | **Vòng lõi vận hành** — 1 buổi dạy trọn vẹn, khép tới PH | **A** |
| **Lesson Player / Classroom** | trong Bước 2 | Audio/video (HLS qua hls.js), watermark trôi, signed URL on-demand, teaching guide (hoạt động/mục tiêu/script/câu hỏi), học liệu bổ trợ chiếu-chèn | GV chiếu học liệu đúng bản quyền, có kịch bản dạy | **A** |
| **Classroom Trio (TV + Remote)** | `/teacher/classroom` · `/remote` | Màn TV chiếu lớp + điều khiển từ điện thoại (Broadcast/Realtime); slideshow nền Phần 0; screen-lock chống trẻ chạm; chụp/quay tức thì từ remote | Biến laptop+phone thành bộ đôi dạy học tại lớp | **A** |
| **Nhật ký GV** | `/teacher/journal` | 3 nhóm: cần ghi nhận / sắp tới / đã gửi & lịch sử | Quản lý buổi đã/chưa gửi | **A** |
| **Danh sách Lớp** | `/teacher/classes` | Card lớp + buổi (đã/đang dạy vs sắp tới), tap vào buổi | Đường vào MỌI buổi | **A** |
| **Học liệu CTAN** | `/teacher/curriculum` | Player nhạc + watermark | Tra học liệu môn | **A** |
| **Học liệu của tôi (Drive)** | `/teacher/media` | Cây thư mục cá nhân, upload, thùng rác | GV tự trữ media | **B** |
| **Bức Tường Yêu Thương** | `/teacher` | Nhận thiệp cảm ơn từ PH, ghim | Động lực GV | **A** |

### 1.3 · SCHOOL `/school` (emerald) — master tự vận hành trường

| Capability | Route | Behavior | Giá trị | Score |
|---|---|---|---|---|
| **Tổng quan trường 3 zone** | `/school` | Sức khỏe trường (score lite từ chỉ-số THẬT), bức tranh thành công, hỗ trợ & vận hành; lịch tuần; khoảnh khắc "🛡 nội bộ" | Hiệu trưởng thấy toàn cảnh trường | **A** |
| **Quản lý Lớp & Môn** | `/school` (tab) | Thêm lớp, rót môn (**license-gated** `has_subject_entitlement`), gán GV chính, chống trùng | Master tự mở lớp không cần Jean | **A** |
| **Quản lý Giáo viên** | `/school` (tab) | Thêm GV, mời đăng nhập (password tạm), gán quyền | Tự tuyển & cấp login GV | **A** |
| **Quản lý Trẻ & Phụ huynh** | `/school` (tab) | Tạo trẻ + ghi danh, tạo PH + link (max 2), mời PH đăng nhập | Tự onboard trẻ/PH | **A** |
| **Kho của trường (Org Drive)** | `/school/drive` | Cây thư mục 3 cấp, thùng rác + purge đêm, quota | Trữ media chung của trường | **B** |
| **Cài đặt trường** | `/school/settings` | Âm/chữ/giai điệu TV cue per-school | Cá nhân hoá tín hiệu TV | **B** |
| **Học liệu/Khoảnh khắc/Hỗ trợ/Thông báo** | `/school/*` | Shared views (single-source đa cổng) | Xem chung trong shell trường | **A** |

### 1.4 · ADMIN `/admin` (slate/cosmic) — nền tảng Dế Mèn

| Capability | Route | Behavior | Giá trị | Score |
|---|---|---|---|---|
| **Mission Control Dashboard** | `/admin` | Health score 4 trụ, vitals, action center (SLA/owner/CTA), school health, media-privacy — **chỉ-số ẩn danh D48** | Điều hành nền tảng | **A** |
| **Onboard trường mới** | `/admin/school-onboarding` | Form + **bảng tính tiền realtime** (môn×giá + seat×giá + addon) → tạo trọn tenant | Bán license, mở khách hàng mới | **A** |
| **Kho Học Liệu** | `/admin/curriculum-library` | Cây Program→Bài→Version→Phần; gán media 4-vai (present/teacher_guide/home_practice/reference); chéo-bài | Vận hành curriculum đa-nguồn | **A** |
| **Upload học liệu** | `/admin/curriculum-admin` | Upload media curriculum | Nạp nội dung | **A** |
| **Xem PII có kiểm soát** | `/admin/sensitive-access` | Ghi audit TRƯỚC khi trả; gate is_admin; data-min | Tuân thủ dữ liệu trẻ | **B** |
| **Trung Tâm Tra Cứu** | `/admin/reference` | Registry 3 lớp (Module / Sơ đồ / Quy trình SOP) | Tự-ghi-tài-liệu, chống tụt hậu | **B** |
| **Trò chơi âm Kid (admin)** | `/admin/kid-sound-game` | Nội dung game cảm thụ | Nạp nội dung Kid | **B** |
| **⭐ Mission Control — Governed Actions** | `/admin/mission-control` | Class Workspace: bands (context/actions/memory/audit); **`class.assign`** (rót môn) + **`class.edit`** (đổi tên lớp, name-only) qua transport action-agnostic + resolver authority + lifecycle 1-decision/2-transitions | **Chỉ 2 action wired**; khung để mở rộng | **B/C** |

### 1.5 · KID `/kid` (V2 reserved — đã build nhưng chưa có user pilot thật)

| Capability | Route | Behavior | Giá trị | Score |
|---|---|---|---|---|
| **Cổng bé PIN/QR** | `/kid` | State machine pair→PIN→album; ba mẹ duyệt | Trẻ tự vào (V2) | **C** |
| **Thế giới sáng tạo** | `/kid` | 8 hoạt động / 3 vùng: Góc vẽ (canvas→png), Nghe & chạm (game cảm thụ), v.v. → `kid_creations` → album + journey timeline; **khử điểm/xếp hạng/so sánh** | Trẻ sáng tạo, tự làm; không thấy trường | **C** |
| **Kid Journey Timeline** | `/kid` | Dòng thời gian tác phẩm bé; parent preview 💛 | Trẻ + PH cùng xem | **C** |

*Kid score C vì `/kid` là V2 reserved — **đã dựng engine + UI thật** nhưng pilot children CHƯA có tài khoản đăng nhập → chưa tạo giá trị người dùng THẬT ở giai đoạn pilot hiện tại.*

### 1.6 · Hạ tầng dùng chung

`/` landing (5 card cổng + status badge) · `/auth` (login, no self-signup) · `/portal` (shell trung tính: notifications + support) · `/share/$token` (public share consent-safe) · `/remote` (public teacher remote). Media: **3 zone Bunny** (public/learning/private) + signed URL qua Edge + watermark + consent-gate.

---

## 2 · USER ROLE MAPPING — "hôm nay người này làm được gì?"

### 👑 School Owner / Principal (master_admin)
**Làm được ngay:** mở lớp, rót môn (đúng license), tuyển & mời GV đăng nhập, tạo trẻ + ghi danh, tạo & mời PH, xem tổng quan sức khỏe trường + lịch tuần + khoảnh khắc nội bộ, quản Kho của trường, chỉnh cài đặt trường. **Tự vận hành trường KHÔNG cần Jean** (D91+D93 khép kín).
**Chưa làm được:** tự tạo/xếp lịch buổi học qua UI, xem hoá đơn/thanh toán định kỳ, gửi thông báo hàng loạt tới PH, báo cáo điểm danh cấp trường, quản workshop/sự kiện.

### 🎨 Teacher (lead / assistant)
**Làm được ngay:** xem buổi hôm nay + độ sẵn sàng, chạy trọn 1 buổi dạy 4 bước (chuẩn bị→player→ghi nhận→gửi nhật ký), chiếu TV + điều khiển remote + chụp/quay tại lớp, điểm danh, ghi nhận kỹ năng tap-first, gắn ảnh cho bé (consent-gated), gửi nhật ký tới PH, nhận lời cảm ơn. **Read-only** phần quản trị trường (Quyết B/D45).
**Chưa làm được:** tự soạn giáo án/nội dung bài (curriculum authoring là admin-only), nhắn tin trực tiếp với PH, tự tạo lịch buổi.

### 🛠️ Admin Operator (nền tảng Dế Mèn)
**Làm được ngay:** onboard trường mới (kèm tính tiền), quản Kho Học Liệu + gán vai media, upload curriculum, xem Mission Control health/vitals/action-center, xem PII có kiểm soát (audit), tra cứu registry. Trong Mission Control: rót môn (`class.assign`) + đổi tên lớp (`class.edit`).
**Chưa làm được:** đa số hành động vận hành khác trong Mission Control (chỉ 2 action); billing/hoá đơn định kỳ; hỗ trợ ticket workflow đầy đủ.

### 💛 Parent
**Làm được ngay:** xem nhật ký nghệ thuật của con (đa-con), xem "sau buổi học", quản consent 4 nhóm, chia sẻ ảnh có thu hồi, gửi lời cảm ơn cô, xem Bản Khám Phá (nếu đủ evidence), quản Cổng của bé, dùng Family Memory Network (mời người thân, đóng góp ký ức).
**Chưa làm được:** nhắn tin trực tiếp GV, tự đăng ký con vào lớp, xem hoá đơn học phí, nhận thông báo push/email thật khi có nhật ký mới.

### 🧒 Student / Kid
**Làm được (V2, chưa có tài khoản pilot):** vào bằng PIN → thế giới sáng tạo 8 hoạt động, vẽ, chơi game cảm thụ, xem timeline của mình.
**Thực tế pilot hôm nay:** **CHƯA có giá trị** — trẻ chưa đăng nhập; toàn bộ trải nghiệm trẻ đi qua ba mẹ.

---

## 3 · PRODUCT VALUE SCORE — tổng hợp

| Score | Ý nghĩa | Capabilities |
|---|---|---|
| **A — pilot dùng ngay** (17) | Có người dùng thật + nghiệm thu login-thật | Parent journal · Parent home · Consent · Share link · Outcome loop · Appreciation · Teacher home · Teacher 4-step flow · Lesson Player · Classroom Trio · Teacher journal · Teacher classes · Curriculum player · Appreciation wall · School overview · School self-manage (Lớp/GV/Trẻ&PH) · School shared views · Admin dashboard · Admin onboarding · Kho Học Liệu |
| **B — móng có, cần hoàn thiện** (11) | Engine sống nhưng UX/luồng/dữ liệu chưa đủ để dùng rộng | Discovery Capsule · FMN · Parent adds memories · Kid gate mgmt · Parent settings · Teacher Drive · Org Drive · School settings · Sensitive access · Reference center · **Mission Control action layer** |
| **C — kiến trúc, chưa giá trị pilot** (3) | Đã build nhưng chưa có user thật | Kid PIN gate · Kid creative world · Kid journey timeline |

**Đọc kết quả:** khối A rất dày và **đã bán được** (trọn vòng dạy-học + nhật ký con). Mission Control — tiêu điểm build hiện tại — nằm ở **B/C**, tức đầu tư kiến trúc lớn nhưng **giá trị người dùng hiện thấp** (2 action).

---

## 4 · CURRENT GAPS — vận hành trường HÀNG NGÀY chưa được hỗ trợ

Đây là các nghiệp vụ mà một trường mầm non cần *mỗi ngày* nhưng DMA **chưa có luồng**:

1. **🗓️ Xếp lịch buổi học (scheduling)** — Master **không có UI tạo/sửa `lesson_sessions`**. Lịch tuần `/school` chỉ **read-only hiển thị**. GV chỉ thấy buổi đã có sẵn (seed/tạo qua đâu?). → **Gap vận hành lớn nhất**: không ai xếp lịch được trong app.
2. **📢 Thông báo hàng loạt (announcements/broadcast)** — Trường không gửi được thông báo tới tất cả PH (nghỉ lễ, sự kiện). Notification hub là **tầng trình bày**; chưa có luồng phát + delivery push/email thật.
3. **💬 Nhắn tin trực tiếp PH↔GV** — chỉ có Outcome loop + Appreciation (một chiều/nhẹ). Chat 2 chiều **cố ý defer V2** — nhưng là nhu cầu hàng ngày.
4. **📋 Điểm danh cấp trường** — GV điểm danh trong buổi, nhưng **không có báo cáo điểm danh rollup** cho hiệu trưởng, không thông báo vắng tới PH.
5. **💰 Học phí / hoá đơn** — pricing chỉ ở lúc onboard. Master **không xem được subscription/hoá đơn định kỳ**; không có luồng thanh toán. PH không thấy học phí.
6. **📝 Đăng ký/ghi danh do PH** — chỉ master tạo trẻ. PH **không tự đăng ký con** vào lớp/khoá.
7. **🎪 Workshop / sự kiện** — không có quản lý sự kiện, buổi ngoại khoá, đăng ký tham gia.
8. **🏠 Bài tập về nhà (home practice)** — `material_role='home_practice'` **có trong schema nhưng chưa có luồng** giao→PH→phản hồi.
9. **✍️ Soạn giáo án cho GV/trường** — `lesson_versions.activities/guiding_questions` là jsonb nhưng **authoring là admin-only**; teaching guide demo còn là const. GV/trường không tự soạn.
10. **🔔 Delivery thông báo thật** — `notifications` bảng có, nhưng chưa rõ có push/email engine thật hay chỉ in-app list.

---

## 5 · RECOMMENDED BUILD PRIORITIES — Top 5 tạo giá trị NHÌN THẤY

Tiêu chí: hữu ích pilot × tần suất dùng × tác động doanh thu × khả thi (móng đã có bao nhiêu).

### ⭐ #1 — Session Scheduling UI (Master/GV tạo & xếp buổi học)
**Vì sao #1:** đây là **lỗ hổng vận hành nền tảng** — không xếp lịch được thì cả luồng dạy 4 bước (khối A dày nhất) **không tự nuôi dữ liệu**; hiện phụ thuộc seed. Đã có `lesson_sessions` + RPC readiness + class_distributions. Cần: RPC `create/update_lesson_session` (gate master/lead same-school) + UI lịch tuần **editable** ở `/school` + `/teacher`.
**Giá trị:** mở khoá tự-vận-hành THẬT; tần suất = mỗi tuần; khả thi cao (schema sẵn). **Đây là mảnh khiến pilot chạy được mà không cần Jean seed.**

### ⭐ #2 — Announcement / Broadcast trường → phụ huynh
**Vì sao:** nhu cầu mỗi tuần (nghỉ lễ, nhắc nhở, sự kiện); hiện **hoàn toàn trống**. Có `notifications` + `notification_types` + notification hub trình bày. Cần: RPC phát broadcast (gate master, scope school) + UI soạn ở `/school` + hiện ở `/parent`.
**Giá trị:** hiệu trưởng thấy "công cụ điều hành" ngay; tăng độ dính PH; khả thi trung bình.

### ⭐ #3 — Home Practice loop (giao bài về nhà → PH → phản hồi)
**Vì sao:** `material_role='home_practice'` + `parent_visible` **đã có trong schema** (mig 068), chỉ thiếu luồng. Khép vòng lớp→nhà→lớp — đúng linh hồn "nhật ký xuyên nguồn". Cần: hiện home_practice ở `/parent/journal` + PH đánh dấu "đã cùng con làm" → GV thấy.
**Giá trị:** khác biệt hoá sản phẩm (không chỉ "xem", mà "cùng làm"); tận dụng móng sẵn → khả thi cao.

### ⭐ #4 — Attendance rollup + thông báo vắng
**Vì sao:** GV **đã điểm danh** trong Bước 3; dữ liệu `child_observations` present/late/absent đã có. Chỉ cần **đọc lên**: báo cáo điểm danh `/school` + (tùy) thông báo PH khi con vắng. Tận dụng data đang bị "ghi mà không đọc".
**Giá trị:** hiệu trưởng có số liệu vận hành thật; khả thi rất cao (chỉ tầng đọc).

### ⭐ #5 — Mở rộng Mission Control action set (chuyển đầu tư kiến trúc thành giá trị)
**Vì sao:** đã đổ **rất nhiều công** vào khung governed-action mà mới wired 2 action. Để đầu tư đó **sinh giá trị**, nên wired thêm các action **admin thật cần hàng ngày**: đổi trạng thái license, gán/gỡ GV, xử lý support ticket — dùng đúng transport action-agnostic vừa dựng ở B14.
**Giá trị:** biến B/C → A; tránh "kiến trúc đẹp không ai dùng" (đúng cảnh báo D97); khả thi cao vì transport + resolver + lifecycle đã sống.

---

## 📌 Tổng kết cho anh Jean

- **Sản phẩm dày, đã bán được** ở Parent + Teacher + School (khối A 17 mục, nghiệm thu login-thật).
- **Mission Control (tiêu điểm hiện tại) mỏng về giá trị** — 2 action; là đầu tư kiến trúc chưa quy đổi ra giá trị người dùng.
- **Lỗ hổng vận hành cấp bách nhất = Xếp lịch buổi học** (không có thì luồng dạy không tự nuôi data).
- **5 ưu tiên** đều tận dụng móng đã có → khả thi cao, giá trị nhìn thấy nhanh.

> ⚠️ Đây là review đọc từ SYSTEM_MAP + handoff (source of truth theo kỷ luật DMA). Một vài mục "score" là đánh giá sản phẩm, không phải bằng chứng DB. Nếu anh muốn **verify live** một khối cụ thể (vd: thật sự có RPC tạo session chưa, delivery notification có thật không), em audit thẳng repo/DB read-only trước khi anh quyết ưu tiên #1.

**Endpoint review: V128-VALUE-REVIEW.1 · READ ONLY · 0 mutation · grounded SYSTEM_MAP v1.67 / HANDOFF V128-B14.**
