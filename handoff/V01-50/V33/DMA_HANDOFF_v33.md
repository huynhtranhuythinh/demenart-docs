# 🤝 DMA_HANDOFF_v33.md — BÀN GIAO PHIÊN (D104 A+C ẢNH-NHÓM-DEFAULT-ON + 2 UX FIX + TAB "LỚP" ĐÓNG GAP BUỔI-QUÁ-KHỨ — TEACHER V1 THẬT SỰ COMPLETE — 2026-06-29 10:40 GMT+7)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v33. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết (D1).
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

Đóng nốt việc treo từ v32 + lấp gap Teacher V1 cuối. 4 việc, đi đúng D1 (audit DB sống TRƯỚC) → engine 3-khối D92 → dịch Lovable → nghiệm thu login thật.

**(I) D104 (A)+(B) — ảnh nhóm consent MẶC-ĐỊNH-BẬT (mig 054):**
- Audit D1 lộ: hook đúng = RPC **`provision_parent_and_link`** (nơi `child_parents` link sinh ra), **KHÔNG đụng Edge `invite_parent`** (consent gắn theo cặp bé×PH lúc provision, không phải lúc invite-login — D97 nghi-vấn-rồi-xác-minh). `consents.source`=text (không enum), `consents` KHÔNG guard trigger → seed `'onboarding_default'` không cần migration enum, không cần replica.
- **Grain consent:** `media_consent_check` bước 6 kiểm theo `child_id` THUẦN (1 dòng granted/bé là đủ mở ảnh nhóm), nhưng UI `/parent/consent` keyed `parent_profile_id` → chốt seed **theo từng link (bé×PH)**: khớp engine + mỗi PH một công tắc opt-out riêng (giữ linh hồn).
- **(A)** CREATE OR REPLACE thêm 1 INSERT consent `group_moment_in_class` granted `source='onboarding_default'` trước `return`. **(B)** Backfill 12 link PH cũ thiếu (idempotent `NOT EXISTS`). 3 khối D92, leaky=[].

**(C) — nút "Vì sao?" ở journal PH (`parent.journal.tsx`):**
- Ảnh "đang chờ" (`consent_missing`) → nút "Vì sao?" → popover giải thích trung tính (đúng cả ảnh-1-bé `display_in_app` lẫn ảnh-nhóm `group_moment_in_class`) + link "Quản lý quyền đồng ý →" `/parent/consent`. **KHÔNG đụng Edge** (key theo `reason==='consent_missing'`, MVP).

**(a) — nút "Sửa ảnh & ghi nhận" Bước 4 (`teacher.session.$id.tsx`):**
- Đường-vào dễ thấy cho sửa-sau-gửi (D103 — cô Linh hỏi 2 lần). `SessionFlow` thêm `recordTab` state + helper `goToRecord(tab)`; `StepRecord` nhận `initialTab` → `useState(initialTab ?? "att")` (remount mỗi lần vào Bước 3 → tab đúng); `StepReview` nút mới → `goToRecord("photo")` mở thẳng Tab Ảnh. Stepper "3" trực tiếp vẫn mở Điểm danh mặc định (không hồi quy).

**(b) — dead-link `admin.modules.tsx`:** `to="/portal"`→`to="/admin"` (1 dòng).

**(A) Tab "Lớp" — đóng gap buổi-quá-khứ (mig 055):**
- Audit D1: GV "thuộc" lớp qua lead (`class_distributions.lead_teacher_id`) HOẶC assistant (`session_teachers`), grain = `class_distribution` (môn-trong-lớp D49); `lesson_sessions` nối qua `class_distribution_id`. Mirror khuôn `get_teacher_home` (search_path='public', union 2 đường D45).
- **1 RPC `get_teacher_classes()`** trả classes[] nested sessions[] (1-call, không N+1, hợp quy mô pilot). Route mới `teacher.classes.tsx` (card lớp · buổi tách đã/đang-dạy vs "Sắp tới" · pill trạng thái) + wire nav "Lớp" trong `teacher.tsx` (`to: null`→`to: "/teacher/classes"`, hết toast). Tap buổi → `/teacher/session/$id` → `stepForState` mở đúng bước → buổi `taught_report_pending`→Bước 4→"Sửa ảnh" sống. **Gap đóng.**

---

## 2. ⭐ NGHIỆM THU LOGIN THẬT (ĐẠT — cả 4 việc)

**(I) D104 A+C** (PH Hùng `ph.hung.kidshouse@demo.demenart.com`/`Test@123`, bé An):
- `/parent/consent` TẮT "ảnh chung trong lớp" → `/parent/journal` 2 ảnh nhóm chuyển "Đang chờ ba mẹ đồng ý" + nút **"Vì sao?"** → popover giải thích + link "Quản lý quyền đồng ý →" → bấm về `/parent/consent` (nav client-side) → BẬT lại (toast "Đã cập nhật") → journal **ảnh nhóm hiện thật**. Vòng tắt→chờ→"Vì sao?"→bật→hiện khép kín = đúng linh hồn.

**(a)+(A)** (GV Mỹ Linh `gv.linh.kidshouse@demo.demenart.com`/`Test@123`):
- **Tab "Lớp"** (mobile/`<640px`): card "Hoa Hồng · CTAN · 4 bé" + 3 buổi đúng trạng thái (Đang diễn ra · Chờ gửi nhật ký · nhóm Sắp tới). Console "No Issues".
- Tap buổi **"Chờ gửi nhật ký"** (a0001) → vào `/teacher/session/...` mở **thẳng Bước 4** → nút **"Sửa ảnh & ghi nhận"** → Bước 3 **Tab Ảnh** (không phải Điểm danh) → gắn/bỏ bé (`moment_children` 200/201/204) → "Tiếp tục — Nhật ký" về Bước 4 → "Gửi lại nhật ký" → 🎉 "Đã gửi nhật ký tới gia đình" (idempotent D103).
- Không hồi quy: stepper "3" trực tiếp → Tab Điểm danh; tab Nhật ký/Hồ sơ vẫn toast "Sắp ra mắt".

> **Bẫy đã vấp (D84 nhắc lại):** sau áp 2 file teacher, cả `/teacher` LẪN `/parent` báo "This page didn't load". Console = **404 chunk JS** (`assets/route-Mgdvz-Xl.js` + `Failed to fetch dynamically imported module`) → **deploy-lag Cloudflare Pages** (index.html bản mới trỏ chunk chưa build xong), KHÔNG phải bug code. Đợi build + hard reload → sạch ("No Issues"). Phân biệt: 404-asset-tĩnh + cả-2-cổng-cùng-vỡ + REST-200 = deploy-lag, KHÔNG bấm Try-to-fix (D5/D14).

---

## 3. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc (CÓ ĐỔI nhẹ phiên này):** **48 bảng** (KHÔNG đổi) · **60 hàm SECURITY DEFINER** (+`get_teacher_classes`; `provision_parent_and_link` đổi THÂN không +hàm) · **132 RLS policy** (KHÔNG đổi) · constraint KHÔNG đổi · **mig 001→055** · seed 001→012. SYSTEM_MAP **v0.30** (bump — +1 hàm + route mới).
- **Edge Functions (6 — KHÔNG đổi):** `get_signed_media_url` · `upload_media` · `resolve_share_link` · `invite_master` · `invite_staff` · `invite_parent`.
- **Routes app:** 5 cổng + `/portal` shell + `/kid` reserved. **Teacher V1:** `teacher.tsx` (nav "Lớp" giờ trỏ `/teacher/classes`) · `teacher.index.tsx` Home · `teacher.session.$id.tsx` luồng 4 bước (+nút "Sửa ảnh & ghi nhận" Bước 4) · **MỚI `teacher.classes.tsx`** (tab Lớp). `parent.journal.tsx` (+nút "Vì sao?"). `admin.modules.tsx` (dead-link vá).
- **3 tenant / 3 master** (DEMO-001 · KHM-DN · MNDM-DN).

> **Data state phiên này:** (1) **`consents` +12 dòng `onboarding_default`** (backfill PH cũ) → `group_granted_total = 16/16` link (mọi link giờ có group consent BẬT). 4 link cũ giữ nguyên (An/Chi `demo_seed` + Jenny/Jimmy demo). (2) a0001 vẫn `taught_report_pending` (gửi-lại trong nghiệm thu = idempotent, không nhân đôi journey). (3) PH Hùng bé An: trong nghiệm thu (C) đã TẮT rồi BẬT lại `group_moment_in_class` → cuối phiên ở trạng thái GRANTED.

---

## 4. FILE PHIÊN NÀY

**Migration (Jean lưu repo từ live — dump trung thực D90):**
- `054_group_consent_default.sql` — `provision_parent_and_link` +default-consent (3 khối) + backfill 12 link.
- `055_get_teacher_classes.sql` — RPC `get_teacher_classes` (3 khối).

**UI (Jean áp Lovable tay):**
- `src/routes/_authenticated/parent.journal.tsx` (full paste-over — +nút "Vì sao?" `ConsentWaitingHint`).
- `src/routes/_authenticated/teacher.session.$id.tsx` (full paste-over — +nút "Sửa ảnh & ghi nhận" Bước 4, `goToRecord`/`initialTab`).
- `src/routes/_authenticated/teacher.classes.tsx` (**file MỚI** — tab Lớp).
- `src/routes/_authenticated/teacher.tsx` (find/replace 1 dòng nav "Lớp" → `/teacher/classes`).
- `src/routes/_authenticated/admin.modules.tsx` (find/replace 1 dòng dead-link → `/admin`).

---

## 5. VIỆC TREO (ghi rõ để pilot không bất ngờ)

**🟢 Teacher V1 — cửa khoá đúng-chủ-đích (QUYẾT PRODUCT, KHÔNG phải nợ):**
- Tab **Nhật ký** · **Hồ sơ** còn toast "Sắp ra mắt" — build cho V1 hay giữ khoá qua pilot = quyết product.
- Reaction **"Lời cảm ơn"** (PH→GV, `parent_replies` hook=0) — D98 đánh **flex**, thay chat PH↔GV ở V1.
- **Desktop nav cho `/teacher/classes`:** bottom nav 5 tab chỉ hiện mobile (`sm:hidden`). Desktop chưa có lối vào tab Lớp từ nav → việc pass **mobile/desktop nav** (Nội thất).

**🟡 D104 còn lại (V2):**
- **Blur mặt bé-chưa-đồng-ý** (ảnh hiện cho mọi PH, chỉ che bé chưa cấp) = V2 (cần crop/blur, nặng).

**🟡 Nợ cũ (mang theo):**
- Dọn seed `[v29-test]` (3 buổi lớp Hoa Hồng) + consent `demo_seed` (An/Chi) khi xong demo. **Rác `[v29-test]` lộ rõ ở journal PH** (card "Ảnh tạm thời chưa xem được" = media_id null/moment chưa gắn media — reason khác `consent_missing` nên KHÔNG có nút "Vì sao?", đúng thiết kế).
- `/teacher/moments` (trang cũ) chưa ký signed URL → không preview. Tab Ảnh reload-moments sau mỗi tag (tối ưu sau).
- 2 PH email-null (Lê Thị Hạnh / Phạm Văn Đức) chưa gắn auth.
- Lưu repo: `045` (nợ v28) + `051/052/053` (nợ v32) + `054/055` (mới) + 2 Edge `invite_staff.ts`/`invite_parent.ts` (nợ v22).
- Land GV `/teacher/curriculum`→`/teacher`.
- Reaction "Lời cảm ơn" (parent_replies hook = 0).
- GV/PH pilot còn lại chưa login (4 GV + nhiều PH) · 2 file nhạc curriculum chưa nguồn lưu · Vercel dormant · lock 1 linh vật.

---

## 6. KẾ HOẠCH PHIÊN SAU

Boot sạch → audit D1 → **pass NỘI THẤT V1 (D98 design — việc lớn còn lại):**
- Jean thích: Claude **đề xuất 3 hướng thẩm mỹ TRƯỚC**, Jean react + layer ý lặp — KHÔNG brainstorm mở từ số 0.
- Áp design 5 cổng: accent nội-thân + **mobile nav + desktop nav** (gồm lối vào `/teacher/classes`) + cửa `/kid` khoá "Sắp ra mắt" ở `/parent` + lock 1 linh vật (dế-sắc-cạnh/dế-tròn/Miu-Nắng).
- Quyết product song song: tab Nhật ký/Hồ sơ (build V1 hay giữ khoá) + reaction "Lời cảm ơn" (flex).

Đóng = HANDOFF v34.

---

*Teacher V1 THẬT SỰ COMPLETE — vòng dạy trọn (Chuẩn bị→Player→Ghi nhận→Review&gửi) + engine submit + consent gated default-on + đường vào MỌI buổi (hôm nay/quá khứ/sắp tới qua tab Lớp), nghiệm thu trọn vòng GV→PH. Nguồn: Tài liệu A–G UPDATED + tầm nhìn founder + DMWS v170.*
