# 🧭 V128-VALUE-ROADMAP.2 — OWNER PRIORITY DECISION REPORT

> **Mode:** PRODUCT STRATEGY REVIEW · OWNER DECISION SUPPORT · READ ONLY
> **Role:** Architecture Coordinator / Product Strategy Continuity — **KHÔNG phải người quyết**. Báo cáo này chuẩn bị để **anh Jean quyết "build gì tiếp"**, không quyết thay.
> **Kế thừa:** V128-VALUE-REVIEW.1 (Capability Inventory) + DMA_RULES + DMA_SYSTEM_MAP v1.67.
> **Grounding mới:** ⭐ **live DB audit read-only** (Supabase `xcvhacymrbhdhohyylyq`, 0 mutation) — chỉnh lại feasibility bằng bằng chứng schema/RPC/RLS THẬT, không đoán.
> **Câu hỏi:** *"DMA nên build gì tiếp để tạo giá trị người dùng nhìn thấy được?"*

---

## ⭐ 0 · Đính chính then-chốt từ live audit (thay đổi cục diện roadmap)

REVIEW.1 nêu giả thuyết: *"Không có đường tạo `lesson_sessions` → phải seed thủ công."*
**Live audit chỉnh lại:**

| Câu hỏi feasibility | Bằng chứng DB thật | Kết luận |
|---|---|---|
| Có RPC tạo buổi học? | **`create_lesson_session` TỒN TẠI** (insert `lesson_sessions`) + INSERT RLS `lesson_sessions_insert_lead_or_schooladmin` (lead ∨ school_admin same-school) + cột `scheduled_at`/`duration_min`/`state`/`cancel_reason` | ✅ **Backend scheduling ĐÃ CÓ** — blocker là **UI**, không phải móng |
| Có gửi thông báo? | **`create_notification` có** (insert `notifications`) — nhưng bảng chỉ `id/profile_id/type/payload/read/created_at` | ⚠️ Atom có; **broadcast fan-out + delivery push/email = chưa có** (in-app only) |
| Điểm danh có data? | **`child_observations.attendance` TỒN TẠI** (ghi mỗi bé/buổi) | ✅ Chỉ cần **tầng đọc** |
| Home practice có schema? | `material_role` CHECK gồm **`home_practice`** + cột `parent_visible`/`kid_visible` | ✅ Schema đủ; **thiếu luồng** |

**Hệ quả chiến lược:** Blocker vận hành số 1 (scheduling) **rẻ hơn nhiều** so với REVIEW.1 tưởng — thuần presentation-layer trên RPC+RLS đã sống. Điều này **đẩy A lên rõ ràng #1** (giá trị cao × chi phí thấp × rủi ro kiến trúc = 0), chứ không phải một sprint móng lớn.

*(Ghi chú builder-gate: cần audit FE xác nhận `create_lesson_session` hiện đã wired ở đâu chưa trước khi ước lượng scope — xem Owner Decision Gates §6.)*

---

## 1 · CURRENT PRODUCT MATURITY ASSESSMENT

| Cổng | Độ chín | Trạng thái thực |
|---|---|---|
| **Parent** | 🟢 Chín (production, pilot-verified) | Nhật ký + Discovery + FMN + consent + outcome/appreciation loop — vòng cảm xúc đầy đủ |
| **Teacher** | 🟢 Chín | Luồng dạy 4 bước trọn vẹn + Classroom Trio + journal — vòng vận hành lõi khép kín |
| **School** | 🟡 Chín-một-nửa | Self-manage (Lớp/GV/Trẻ/PH) + Drive + overview chín; **thiếu UI xếp lịch** (backend sẵn) + thiếu comms |
| **Admin** | 🟡 Chín ops, mỏng governance | Onboarding + Kho Học Liệu + dashboard chín; **Mission Control mới 2 action** |
| **Kid** | ⚪ Dựng xong, ngủ đông | 8 hoạt động + engine thật nhưng **0 user pilot** (V2 reserved) |

**Kết luận maturity:** DMA đã vượt "MVP" — vòng lõi **Teacher→Parent chạy thật, bán được**. Điều còn thiếu **không phải feature lõi mới**, mà là **các mảnh vận hành-hàng-ngày** nối sản phẩm đã chín thành một hệ **trường tự chạy** (self-operating). Mission Control là tầng điều phối, **không phải sản phẩm chính** (đúng kết luận anh nêu).

---

## 2 · BIGGEST OPERATIONAL BLOCKERS (xếp hạng)

1. **🗓️ Không có UI xếp lịch buổi học** → `lesson_sessions` phải seed (chỉ 9 row live, toàn demo). **Toàn bộ khối A dày nhất (luồng dạy 4 bước) không tự nuôi dữ liệu.** Backend (RPC+RLS+schema) **đã sẵn** → đây là blocker **giá trị-cao / chi-phí-thấp nhất**.
2. **📢 Trường không truyền đạt vận hành tới PH** → không broadcast được (nghỉ lễ/sự kiện/nhắc). `create_notification` là atom per-profile; thiếu fan-out + UI + delivery.
3. **📊 Điểm danh ghi mà không đọc** → `child_observations.attendance` có data nhưng 0 báo cáo cấp trường, 0 thông báo vắng. Insight bị bỏ phí.
4. **🏛️ Đầu tư Mission Control chưa quy đổi giá trị** → khung governed-action công phu, 2 action. Rủi ro "kiến trúc đẹp không ai dùng" (D97).

---

## 3 · TOP CAPABILITY PRIORITIES

### ⭐ P1 — Session Scheduling UI (Lịch buổi học tạo/sửa được)
- **User:** Master (xếp lịch trường) + GV lead (buổi của mình).
- **Problem:** Không tạo được buổi trong app → cả luồng dạy phụ thuộc seed → pilot không tự chạy.
- **Expected value:** Mở khoá **self-operating** — trường tự xếp lịch → GV có buổi → dạy → gửi nhật ký → PH xem. Kích hoạt vòng lõi đã chín.
- **Build scope:** **Presentation-layer** — UI lịch tuần editable ở `/school` (+ `/teacher`) wire vào **`create_lesson_session` đã tồn tại**; form (lớp/môn/version/giờ/thời lượng); (tùy) sửa/huỷ dùng `state`+`cancel_reason` sẵn có.
- **Dependencies:** `create_lesson_session` ✅ · INSERT RLS ✅ · `lesson_sessions` schema ✅ · lịch tuần read-only ✅ (nâng thành editable). **Builder phải audit FE trước:** RPC đã wired chưa.
- **Risk:** 🟢 **THẤP NHẤT** — 0 authority mới, 0 RPC mới, 0 permission mới, 0 migration. Thuần UI trên nền đã proven.

### ⭐ P2 — Attendance Rollup (Điểm danh thành insight)
- **User:** Master (báo cáo trường) + PH (thông báo vắng, giai đoạn 2).
- **Problem:** Data điểm danh bị "ghi mà không đọc".
- **Expected value:** Hiệu trưởng có số liệu vận hành THẬT; đi kèm P1 rất tự nhiên (cùng domain buổi học).
- **Build scope:** RPC **read-only** aggregate trên `child_observations.attendance` (scope school) + widget ở `/school`. (Thông báo vắng tới PH = giai đoạn sau, gắn P3.)
- **Dependencies:** `child_observations.attendance` ✅. Chỉ thêm 1 read RPC + UI.
- **Risk:** 🟢 Rất thấp — read-only, additive.

### ⭐ P3 — School Announcement / Broadcast (Trường → Phụ huynh)
- **User:** Master (gửi) → tất cả PH của trường (nhận).
- **Problem:** Không có kênh truyền đạt vận hành hàng loạt.
- **Expected value:** Hiệu trưởng có "công cụ điều hành" hữu hình; tăng độ dính PH.
- **Build scope:** **Giai đoạn A (khả thi ngay):** broadcast **in-app** — RPC fan-out per-parent dựa trên `create_notification` sẵn + UI soạn ở `/school` + hiện ở `/parent`. **Giai đoạn B (defer):** delivery push/email thật (hạ tầng mới).
- **Dependencies:** `create_notification` ✅ (per-profile) · notification hub trình bày ✅. Cần: 1 broadcast RPC (fan-out scope-school) + compose UI.
- **Risk:** 🟡 Trung bình — broadcast RPC additive (thấp); **delivery ngoài in-app = dependency mới** → tách giai đoạn B, đừng gộp.

### ⭐ P4 — Home Practice Loop (Lớp → Nhà → Lớp)
- **User:** GV (giao) → PH (cùng con làm) → GV (thấy phản hồi).
- **Problem:** `home_practice` có trong schema nhưng 0 luồng.
- **Expected value:** **Khác biệt hoá** — DMA không chỉ "xem con học" mà "cùng con làm ở nhà"; đúng linh hồn nhật-ký-xuyên-nguồn.
- **Build scope:** Hiện media `material_role='home_practice'`+`parent_visible` ở `/parent/journal`; PH đánh dấu "đã cùng con làm" → GV thấy.
- **Dependencies:** schema ✅ (`material_role`/`parent_visible`/`kid_visible`). Cần: read surface + 1 write ack nhỏ.
- **Risk:** 🟢 Thấp — additive. *(Không phải blocker vận hành → xếp sau P1–P3.)*

### ⭐ P5 — Mission Control Action Expansion (Quy đổi kiến trúc → giá trị operator)
- **User:** Admin operator + (mở rộng) Master.
- **Problem:** Khung governed-action mới 2 action → đầu tư chưa sinh lời.
- **Expected value:** Biến B/C → A; operator làm nhiều việc hàng ngày trong 1 khung có audit/authority nhất quán.
- **Build scope:** Wire thêm action **theo pattern B14 đã proven** (transport action-agnostic + resolver + lifecycle + registry): vd đổi trạng thái license, gán/gỡ GV, xử lý support. **Mỗi action = 1 adapter + registry row + gate.**
- **Dependencies:** transport/resolver/lifecycle/registry ✅ (B6–B14). Backend adapter cho mỗi action mới.
- **Risk:** 🟡 Trung bình — **trong** authority model hiện có (không mở model mới); nhưng mỗi action chạm backend → cần CTO-authorize từng cái (invariant "no new backend without authorization").

---

## 4 · CAPABILITIES TO DEFER (và vì sao)

| Defer | Lý do |
|---|---|
| **Push/email delivery thật** | Hạ tầng mới (provider, deliverability, consent). Ship in-app broadcast trước; đo nhu cầu rồi mới đầu tư. |
| **Parent↔Teacher chat 2 chiều** | Cố ý V2. Nặng moderation/notification/quyền; outcome+appreciation loop đã che nhu cầu tối thiểu. |
| **Billing / hoá đơn định kỳ** | Chưa chặn vận hành pilot (license set lúc onboard). Cần khi scale thương mại, không phải để pilot chạy. |
| **Parent tự đăng ký con** | Master-created hiện đủ cho pilot; self-registration mở bề mặt bảo mật trẻ → cần policy kỹ. |
| **Workshop / sự kiện** | Chưa phải nhịp hàng ngày của pilot; feature mở rộng doanh thu sau. |
| **Kid pilot activation** | `/kid` V2 reserved; kích hoạt cần PIN-flow + parent-approval hoàn thiện + policy trẻ đăng nhập. Giá trị pilot hiện đi qua PH. |
| **Curriculum authoring cho GV/trường** | Admin-only đủ cho pilot (nội dung CTAN tập trung). Phân quyền authoring = bề mặt lớn. |

---

## 5 · RECOMMENDED 90-DAY ROADMAP

> Sắp theo **giá trị × khả-thi × rủi-ro-thấp**. Không bịa số giờ (D: không tự suy "sprint mất X giờ"); phase = trình tự, nhịp thật do feasibility quyết.

**PHASE 1 (≈ 30 ngày đầu) — LÀM TRƯỜNG TỰ CHẠY**
- **P1 Session Scheduling UI** — mảnh mở khoá tất cả. Backend sẵn → tập trung UI + nghiệm thu login-thật (master xếp → GV thấy → dạy).
- **P2 Attendance Rollup** — bám ngay sau P1 (cùng domain), read-only, cheap win cho hiệu trưởng.
- *Kết Phase 1:* pilot **chạy được vòng dạy-học không cần Jean seed** — cột mốc "self-operating".

**PHASE 2 (≈ 30–60 ngày) — KẾT NỐI TRƯỜNG ↔ GIA ĐÌNH**
- **P3 Announcement (in-app, giai đoạn A)** — trường truyền đạt vận hành; tận dụng `create_notification`.
- **P4 Home Practice Loop** — khác biệt hoá; schema sẵn.
- *Kết Phase 2:* trường ↔ gia đình có kênh 2 chiều nhẹ + học vượt khỏi lớp.

**PHASE 3 (≈ 60–90 ngày) — QUY ĐỔI KIẾN TRÚC & CHỐT ĐỘ BỀN**
- **P5 Mission Control Action Expansion** — biến đầu tư governance thành giá trị operator (2–3 action operator-cần-nhất).
- **Dọn nợ nền** song song: repo backup migrations/Edge (nợ D90 tồn lâu), pilot GV/PH chưa login (4 GV + 9 PH), fixture data.
- *(Ứng viên chờ cổng:* Announcement delivery giai đoạn B *nếu* Phase 2 chứng minh nhu cầu.)

---

## 6 · OWNER DECISION GATES (anh Jean chốt TRƯỚC khi builder chạy)

| Gate | Quyết định cần anh Jean | Vì sao là gate |
|---|---|---|
| **G1 — Xác nhận ưu tiên** | Đồng ý trình tự P1→P2→P3→P4→P5? Hay đảo (vd đưa P5 lên vì lý do chiến lược governance)? | Toàn roadmap treo vào đây |
| **G2 — Scope P1** | Cho builder **audit FE trước** (create_lesson_session đã wired chưa) → chốt scope UI-only. Cho master **và** GV lead cùng tạo, hay chỉ master? | Quyết bề rộng UI + tránh đoán scope |
| **G3 — Delivery Announcement** | P3 ship **in-app-only trước** (khuyến nghị) hay chờ push/email? | Chặn scope-creep hạ tầng |
| **G4 — Attendance → PH** | Rollup có kèm **thông báo vắng tới PH** ngay (Phase 1) hay tách Phase 2? | Đụng consent/notification |
| **G5 — Mission Control set** | 2–3 action operator nào được authorize (invariant: no new backend without CTO-auth)? | Mỗi action chạm backend |
| **G6 — Kid & billing** | Xác nhận **defer** Kid activation + billing trong 90 ngày này? | Khoá scope, chống lan |

---

## 📌 SUCCESS CONDITION — anh Jean trả lời được "vì sao build cái này tiếp?"

- **P1 (Scheduling):** *"Vì không có nó, sản phẩm đã chín không tự nuôi được dữ liệu — và backend đã sẵn nên rẻ nhất."*
- **P2 (Attendance):** *"Vì data đã ghi sẵn, chỉ cần đọc lên thành insight — cheap win đi kèm P1."*
- **P3 (Announcement):** *"Vì trường cần truyền đạt vận hành hàng ngày, hiện hoàn toàn trống."*
- **P4 (Home Practice):** *"Vì nó khác biệt hoá DMA thành 'cùng con làm', schema đã có."*
- **P5 (Mission Control):** *"Vì đầu tư governance lớn cần quy đổi ra giá trị operator thật."*

> ⚠️ Báo cáo này **quyết WHAT, không quyết HOW**. Feasibility đã verify bằng live DB read-only (RPC/RLS/schema thật), nhưng **build scope chính xác cần builder audit FE wiring** (Gate G2) trước khi ước lượng. Không migration/RPC/permission nào được đề xuất ở phase này.

**Endpoint: V128-VALUE-ROADMAP.2 · OWNER DECISION SUPPORT · READ ONLY · 0 mutation · live audit 94/253/171 · grounded SYSTEM_MAP v1.67 + REVIEW.1.**
