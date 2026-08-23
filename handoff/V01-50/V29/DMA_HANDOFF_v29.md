# 🤝 DMA_HANDOFF_v29.md — BÀN GIAO PHIÊN (THIẾT KẾ TEACHER PORTAL V1 TRỌN BỘ — CHỐT PRODUCTION DIRECTION — 2026-06-28 14:26 GMT+7)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v29. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

Phiên **THUẦN THIẾT KẾ** — bước đầu của pass NỘI THẤT V1 (Quyết A v28). KHÔNG SQL, KHÔNG Edge, KHÔNG route, KHÔNG seed. Output = **đặc tả thiết kế Teacher Portal V1 trọn bộ, đã Jean duyệt làm production direction.**

**(A) Chốt design direction (3 hướng → Jean chọn):**
- Dựng 3 hướng thẩm mỹ demo trên `/teacher` (màn dùng dày nhất): **1 Sổ tay giấy · 2 Tươi sáng · 3 Sách tranh** — đều neo `#149A76` + gu "album con / vui trẻ thơ", mỗi hướng gói 1 cách vẽ dế.
- **Jean chốt: Hướng 2 "Tươi sáng" làm NỀN production** + mượn hơi ấm Hướng 1 (nền ngà, thẻ mềm, microcopy thân thiện). **KHÔNG dùng Hướng 3** cho `/teacher` (cảm giác đó để dành `/kid` / Classroom View / illustration states).

**(B) Thiết kế Teacher Portal V1 Home — "Classroom Companion" (KHÔNG phải dashboard).** GV mở app là biết ngay: hôm nay dạy lớp nào · bài gì · cần chuẩn bị gì · bắt đầu ở đâu · còn việc gì sau giờ. 7 khối (xem §8a).

**(C) Polish production qua 4 vòng Jean phản ứng — chốt:**
- CTA **state-aware** + **4 trạng thái giáo án edge** (sẵn-sàng / thiếu-học-liệu / chưa-phân-lớp / cần-cập-nhật) + 3 tiến trình (đang-học / sau-giờ / đã-xong).
- Luồng buổi học **4 bước**: Chuẩn bị → Dạy học → Ghi nhận → Nhật ký (bước 3 có **3 tab con**: Điểm danh · Ghi nhận · Ảnh-gắn-bé).
- "Hoàn tất & gửi nhật ký" → **màn Xem lại Bước 4/4 TRƯỚC khi gửi** (không gửi thẳng).
- Empty state ngày trống; "Cần hỗ trợ?" 4 lỗi; chiều cao nén để 4 khối đầu trên-mép.

**(D) Copy neo đúng QUYỀN + LUẬT (audit tài liệu D1):**
- **"Báo thiếu học liệu"** (KHÔNG "Bổ sung"): GV **không có quyền thay học liệu** — học liệu = IP Dế Mèn, chỉ content admin upload (**D75** / `check_curriculum_upload_access`).
- **Riêng tư media (D71/D47 MIN):** ảnh **chưa gắn bé KHÔNG gửi PH** tới khi gắn bé hoặc "gửi cho cả lớp"; gửi **chỉ media đã duyệt + đã gắn bé + được phép**; ảnh có **bé chưa đồng ý → tạm giữ với gia đình bé đó**, các bé khác vẫn nhận bình thường.

> **D98 MỚI (RULES):** đặc tả Teacher Portal V1 chốt làm production direction (Classroom Companion; Hướng-2-nền + hơi-ấm-Hướng-1; tokens; CTA state-aware + readiness edge; luồng 4 bước + review-trước-gửi; riêng tư MIN trong UI; copy neo quyền D75). Mockup visualizer = tài liệu hướng thiết kế, KHÔNG code production (D97).

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc:** **46 bảng · 50 hàm SECURITY DEFINER · 125 RLS policy · mig 001→045 · seed 001→012.** SYSTEM_MAP **v0.26** (KHÔNG bump — phiên thiết kế, KHÔNG đụng schema/route/Edge).
- **Phiên này KHÔNG phát sinh:** SQL · migration · Edge Function · route · seed. KHÔNG đụng repo.
- **Edge Functions (6 — KHÔNG đổi):** `get_signed_media_url` · `upload_media` · `resolve_share_link` · `invite_master` · `invite_staff` · `invite_parent`.
- **Routes app KHÔNG đổi:** 5 cổng `/parent`(amber)·`/teacher`(sky)·`/school`(emerald)·`/admin`(slate) + `/portal` shell hạ-tầng + `/kid` reserved V2. `/share/$token` public.
- **3 tenant / 3 master** (DEMO-001 · KHM-DN · MNDM-DN).

> Lưu ý: accent `/teacher` LIVE hiện vẫn **sky** (từ v25). Thiết kế V1 mới re-anchor sang hệ ngà/xanh-rừng/mật-ong — **chỉ áp khi BUILD** (chưa đụng code).

---

## 3. FILE PHIÊN NÀY

**KHÔNG file repo/SQL/Edge phiên này** (thuần thiết kế).

**Artifact thiết kế (visualizer mockup — KHÔNG phải code production, D97):** Home V1 (production) · Xem-lại-trước-gửi (có luật riêng tư) · 6 màn luồng (Chuẩn bị · Lesson Player · Điểm danh · Ghi nhận · Media tagging · Sent confirmation). Là **tài liệu hướng thiết kế**; đặc tả văn bản đầy đủ ở §8.

**3 file library xuất kèm (Jean lưu tay):**
- `DMA_HANDOFF_v29.md` (file này).
- `DMA_RULES.md` (thêm **D98** + footer v29).
- `DMA_SYSTEM_MAP.md` (footer v29 — **KHÔNG bump v0.26**).

**START_HERE: KHÔNG đổi. Tài liệu A–G, BUILD_PATH, DMWS_REFERENCE: KHÔNG đổi.**

---

## 4. NGHIỆM THU

**Phiên thiết kế — chưa engine để nghiệm thu login thật (D2/D3 áp khi BUILD).** Chốt look qua Jean duyệt từng vòng:
- ✅ Chọn Hướng 2 nền + hơi ấm Hướng 1, loại Hướng 3 khỏi `/teacher`.
- ✅ Home V1 + Review Bước 4/4 = production direction.
- ✅ Polish: state-aware CTA (4 trạng thái giáo án + 3 tiến trình), luồng 4 bước, empty state, support, mật-ong-không-đỏ.
- ✅ Khung luồng (header · "Bước x/4" · dots · 3 tab con bước 3) — Jean duyệt "ổn".
- ✅ 6 màn luồng dựng xong.
- ✅ Copy neo quyền/luật xác nhận từ tài liệu (D75 báo-thiếu-học-liệu; D71/D47 MIN riêng tư).

---

## 5. ⭐ BẢNG TÀI KHOẢN TEST (mỗi lần nhờ test PHẢI ghi email kèm)

> Tất cả `@demo.demenart.com`, password **`Test@123`** (auto-confirm), trừ super_admin (password của Jean) + 2 login giữ-từ-v22 dùng password tạm.

| Vai | Email | Người / Trường | Land sau login |
|---|---|---|---|
| **Admin nền tảng** | `info@demenart.com` | Quản trị viên Test · super_admin | **`/admin`** |
| **Master KHM** | `hieutruong.kidshouse@demo.demenart.com` | Huỳnh Trần Nguyệt Thi · KHM | `/school` |
| **GV KHM** | `gv.linh.kidshouse@demo.demenart.com` | Đặng Mỹ Linh · KHM | `/teacher/curriculum` |
| **PH KHM** (2-con An+Khang) | `ph.hung.kidshouse@demo.demenart.com` | Nguyễn Văn Hùng · school NULL | `/parent/journal` |
| **Master MNDM** | `hieutruong.demen@demo.demenart.com` | Mai Phương Dung · MNDM | `/school` |
| **GV MNDM** | `gv.han.demen@demo.demenart.com` | Bùi Ngọc Hân · MNDM | `/teacher/curriculum` |
| **PH MNDM** (2-con Hà+Phúc) | `ph.thanh.demen@demo.demenart.com` | Đặng Văn Thành · school NULL | `/parent/journal` |
| GV KHM (giữ v22, password tạm) | `gv.my.kidshouse@demo.demenart.com` | Lê Thảo My · KHM | `/teacher/curriculum` |
| PH KHM (giữ v22, password tạm) | `ph.toan.kidshouse@demo.demenart.com` | Trần Quốc Toản · KHM | `/parent/journal` |

> **DEMO-001 (sandbox, login chưa gắn — `user_id` NULL trong seed):** master `master.demo@demenart.com` · GV `teacher.demo@demenart.com` · PH `parent.demo@demenart.com` (Bé Jenny/Jimmy).

---

## 6. VIỆC TREO (ưu tiên giảm dần)

1. 🟢 **BUILD Teacher V1** (ngã kế — §7): D1 audit → `prep_items`+RPC readiness → RPC đếm "Việc cần làm" → (reaction "Lời cảm ơn") → dịch component Lovable.
2. 🟡 **Chốt chính thức 1 linh vật:** đã thu hẹp — **chrome = mark hình học gọn** (Hướng 2), **illustration/empty/sent = dế tròn-cute**. Cần Jean lock dứt khoát (vs dế-sắc-cạnh logo gốc · Miu Nắng V3).
3. **GV/PH pilot còn lại chưa login** (4 GV + 9 PH) → mời nốt qua app khi cần (engine D93 đủ).
4. **2 file nhạc curriculum gốc chưa nguồn lưu** (`.mp3` thật, KHÔNG phải SQL) · **Vercel project dormant** xóa được.

> ✅ **Đã gạch phiên này:** chốt design direction Teacher V1 (Hướng 2 + hơi ấm Hướng 1) · Home V1 production · Review-trước-gửi có luật riêng tư · 6 màn luồng · copy neo quyền/luật · D98.
> ✅ **Đóng từ trước:** Ngã A 4/5 cổng tách (v24–26) · giỏ nợ repo SẠCH (v27) · mig 045 vá rough edge GV (v28) · chốt north-star + lộ trình V1/V2/V3 + khoá V1 scope (v28).

---

## 7. NGÃ KẾ — ĐỀ XUẤT

**Vào BUILD Teacher Portal V1 (dịch thiết kế §8 thành app thật).** Trình tự đúng D1: **audit DB/route sống TRƯỚC**, rồi viết engine, cuối cùng dịch Lovable.

- **⭐ Bước 1 — Audit D1:** soạn bộ SQL audit cho Jean chạy (dán JSON về): (a) schema thật `child_observations` (cột attendance/skills_observed/is_highlight/needs_support/linked_moment_ids); (b) đường moment→consent→media (`learning_moments`/`moment_children`/`media_assets` + engine `media_consent_check` D71); (c) chỗ móc bảng MỚI `prep_items` (gắn vào `lesson_versions`? `class_distributions`? `lesson_sessions`?); (d) route `/teacher` hiện có + component.
- **Bước 2 — Engine mới (3 khối D92 mỗi hàm):** `prep_items` (bảng + RLS) + RPC readiness (trả 4 trạng thái giáo án) · RPC đếm Dashboard-LITE (4 số "Việc cần làm") · (reaction "Lời cảm ơn" — flex, Quyết C).
- **Bước 3 — Dịch Lovable:** Home V1 + 6 màn luồng theo đặc tả §8, áp hệ token mới (ngà/xanh-rừng/mật-ong), bottom nav 5 tab (vá luôn mobile-nav).

**Boot phiên sau:** đọc HANDOFF v29 → audit live DB/route thật (D1) trước khi viết. Đóng BUILD bằng HANDOFF v30.

---

## 8. ⭐ ĐẶC TẢ TEACHER PORTAL V1 (nguồn sự thật cho BUILD)

### 8a. Home — "Classroom Companion" (7 khối, theo thứ tự dọc)

1. **Greeting** — dế mark nhỏ + "Phòng Giáo viên"/tên trường · "Chào cô [tên]" · "Thứ …, [ngày] · **X tiết** hôm nay" (dùng **"tiết"** trừ khi thật sự X lớp khác nhau) · chuông + chấm mật-ong khi có noti.
2. **Hero Teaching Card** (thẻ lõi) — pill môn (CTAN · Cảm Thụ Âm Nhạc) + **pill trạng thái giáo án** (góc phải) · tên lớp · tên bài · chip [giờ · số bé] · dòng luồng "Chuẩn bị → Dạy học → Ghi nhận → Nhật ký" · **CTA state-aware**.
3. **Prep preview** — "Chuẩn bị (2/5)" + 3 mục đầu (tick) + "**+N mục nữa · Xem chuẩn bị**" → màn chi tiết.
4. **Việc cần làm hôm nay** — **khẩn lên trước**: Lớp chưa điểm danh ["Bây giờ"] · Nhật ký chờ gửi · Ảnh/video chưa gắn bé · Phản hồi PH mới. Số đếm badge **mật-ong** (việc cần làm) / **xanh** (phản hồi PH). **KHÔNG đỏ gắt.**
5. **Quick actions (4, ≥44px):** Chuẩn bị · Điểm danh · Ghi nhận · Khoảnh khắc.
6. **Lớp tiếp theo** — thẻ gọn (giờ · tên bài · lớp · môn · số bé).
7. **Cần hỗ trợ?** — 4 lỗi: học-liệu-lỗi · không-thấy-lớp · không-gửi-được-nhật-ký · hỗ-trợ-kỹ-thuật (→ `/portal/support`).

**Bottom nav 5 tab:** Hôm nay · Lớp · Giáo án · Nhật ký · Hồ sơ.
**Empty state ngày trống:** dế tròn + "Hôm nay cô không có lớp" + "Cô nghỉ ngơi nhé…" + nút [Xem giáo án] / [Nhật ký bé] + "Lớp gần nhất sắp tới" + "Cần hỗ trợ?".

### 8b. CTA state-aware + 4 trạng thái giáo án (pill góc phải + CTA đổi theo)

| Trạng thái | Pill | CTA | Màu CTA |
|---|---|---|---|
| Sẵn sàng | "Giáo án sẵn sàng" (xanh ✓) | Bắt đầu buổi học (play) | xanh |
| Thiếu học liệu | "Thiếu học liệu" (mật ong) | **Báo thiếu học liệu** (cờ) — GV KHÔNG thay học liệu (D75) | mật ong |
| Chưa phân lớp | "Chưa phân công lớp" (xám) | Chưa có lớp để bắt đầu (khoá) | xám-ghost |
| Cần cập nhật | "Cần cập nhật bài học" (mật ong) | Cập nhật bài học (edit) | mật ong |
| Đang học | "Đang diễn ra" (mật ong) | Tiếp tục buổi học (play) | xanh |
| Sau giờ | "Chờ gửi nhật ký" (mật ong) | Hoàn tất & gửi nhật ký (send) → **Review** | mật ong |
| Đã xong | "Đã hoàn tất" (xanh ✓) | Xem lại buổi học (eye) | trắng-viền-xanh |

### 8c. Luồng 4 bước (vào từ "Bắt đầu buổi học")

- **Bước 1/4 — Chuẩn bị:** checklist dụng cụ tích-được + tiến độ + lối "**Báo thiếu học liệu**" → "Đã sẵn sàng · Vào bài học".
- **Bước 2/4 — Dạy học (Lesson Player):** player audio lớp (nút lớn, playlist) + 5 phần hoạt động tích-hoàn-thành + câu hỏi gợi mở → "Kết thúc · Ghi nhận lớp".
- **Bước 3/4 — Ghi nhận lớp** (3 tab con):
  - **Điểm danh:** roster gạt Có mặt/Vắng từng bé + tổng kết + "đánh dấu cả lớp có mặt".
  - **Ghi nhận:** **tap-first** — chọn bé (strip) → trạng thái tham gia (single) + kỹ năng quan sát được (multi, chạm chọn) + nổi-bật/theo-dõi toggle + ghi chú ngắn (phụ) + gắn khoảnh khắc → "Bé tiếp theo".
  - **Ảnh (Media tagging):** lưới ảnh → gắn bé / "**gửi cho cả lớp**"; **cảnh báo MIN consent** khi có bé chưa đồng ý (tạm giữ với gia đình bé đó) → "Xong · Xem lại buổi học".
- **Bước 4/4 — Xem lại trước khi gửi (Review):** tóm tắt (điểm danh · ghi nhận · ảnh đã gắn) + **cảnh báo ảnh chưa gắn bé** ("…sẽ không gửi cho phụ huynh cho đến khi được gắn bé hoặc đánh dấu gửi cho cả lớp") + "Gắn bé ngay" + bảo chứng riêng tư ("Chỉ gửi ảnh đã gắn bé và được phép theo cài đặt riêng tư của từng bé") + [Sửa lại] / [Gửi nhật ký].
- **Sent confirmation:** dế reo mừng + "Đã gửi nhật ký!" + tóm tắt (ghi nhận/ảnh đã gửi) + "2 ảnh chưa gắn bé lưu nháp" + [Về Hôm nay] / [Xem nhật ký lớp].

### 8d. Design tokens `/teacher` V1
- Nền **ngà ấm `#FBF8F1`** · thẻ trắng `#FFFFFF` bo 16–18px mềm · chữ sans dễ đọc.
- Primary = **xanh rừng `#149A76`** (brand + nút chính, chữ trắng) · darker text `#0F6E56`.
- Accent = **mật ong `#EFA63A`** = "chỗ cần để mắt" (badge/tiến độ/việc tồn/chấm noti/CTA cần-xử) · text mật-đậm `#5E3A08`/`#8A5410` · bg mật-nhạt `#FCEFD6`.
- Trung tính xám cho trạng thái "khoá/chưa-phân-lớp".
- **Dế = mark nhỏ hỗ trợ** (KHÔNG lấn): chrome dùng mark hình-học gọn; empty/sent/illustration dùng dế tròn-cute.

### 8e. Engine ↔ thiết kế (map khi BUILD)
- ✅ **Điểm danh · Ghi nhận** = `child_observations` (attendance + skills_observed + is_highlight + needs_support + linked_moment_ids) — có sẵn.
- ✅ **Ảnh + gắn bé + consent** = moments D58 + `media_consent_check` D71 (MIN) + D47 + Edge `upload_media`/`get_signed_media_url`.
- ✅ **Gửi nhật ký → PH thấy** = approval (nếu trường bật) + parent view (approved+consent+MIN) — engine có, cần wire.
- ❌ **Chuẩn bị + 4 trạng thái giáo án** = bảng **`prep_items` (MỚI)** + RPC readiness.
- ❌ **"Việc cần làm" (4 số)** = **RPC đếm** (Dashboard-LITE, Quyết B v28).
- ❌ **"Phản hồi phụ huynh" V1** = reaction **"Lời cảm ơn"** (flex, Quyết C — thay chat PH↔GV; chat thật = V2).

### 8f. Data state (bẫy — GIỮ từ v23/v28)
- **KHM-DN `sharing_mode=private_share_link`** · **DEMO-001 `no_external_sharing`**.
- **Consent An `private_share_link` (`d1…e1`) = GRANTED** + download consent An bật.
- **DEMO-001 trung thực D90:** 1 moment `draft` · consent `demen_marketing granted=false` · 2 media `bunny_path`; **UUID NGẪU NHIÊN** (`b6a4ac35…`) → lọc tenant FK-ngược (D96).
- **PH 051 mỗi trường = 2-con-xuyên-lớp.** Role PH thật = `primary_parent`.
- `master_admin` ∈ `is_school_admin()`; PH `school_id=NULL` → RPC curated cả ghi (D29) lẫn đọc (D92 nới GV same-school read-only, mig 045).
- `school.index` giữ `ssr:false`; shell `{admin,school,teacher,parent}.tsx` KHÔNG đặt ssr:false. `/portal` = shell hạ-tầng (notifications+support).
- Engine media-nhạy-cảm = 5 gate secdef: consent (D71) · entitlement (D75) · upload (D77) · share (D87) · revoke (D94).

---

> **KỶ LUẬT VÀNG:** đã cập nhật **RULES** (thêm **D98** — đặc tả Teacher Portal V1 production direction; footer v29) + **SYSTEM_MAP** (footer v29 — **KHÔNG bump v0.26**, phiên thiết kế) trong phiên này. **3 file xuất kèm:** `DMA_HANDOFF_v29.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md`. **KHÔNG file repo/SQL/Edge phiên này.** **START_HERE: KHÔNG đổi.** **Tài liệu A–G, BUILD_PATH, DMWS_REFERENCE: KHÔNG đổi.** **Mockup visualizer = tài liệu hướng thiết kế, KHÔNG phải code production (D97).**
