# 🤝 DMA_HANDOFF_v16.md — BÀN GIAO PHIÊN (ONBOARD 2 TRƯỜNG PILOT → MULTI-TENANT LIVE)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v16. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

Phiên **data/onboarding** (không đụng schema) — đi **Ngã A** từ v15 §6: **đưa trường thật vào để biến pilot thành thật**, validate kiến trúc multi-tenant trên LIVE `demenart.com`.

- **🎯 Onboard 2 trường pilot (cơ chế 1A — seed SQL idempotent Claude viết, Jean chạy SQL Editor):**
  - **S1 = Kids House Montessori Đà Nẵng** (`KHM-DN`) — license **CTAN + Ballet** · 4 seat · trial 90 ngày · HT **Huỳnh Trần Nguyệt Thi** · 2 lớp (Hoa Hồng, Hướng Dương) · 8 trẻ · 7 PH.
  - **S2 = Trường Mầm Non Dế Mèn** (`MNDM-DN`) — license **CTAN only** · 3 seat · trial 90 ngày · HT **Mai Phương Dung** · 2 lớp (Búp Măng, Tuổi Thơ) · 6 trẻ · 5 PH.
  - **Khác biệt cố ý để chứng minh:** isolation 2 tenant · **license theo-thành-phần** (S1 có Ballet, S2 KHÔNG → GV S2 chỉ thấy CTAN) · **multi-child xuyên lớp** (mỗi trường 1 PH có 2 con ở 2 lớp khác nhau) · **consent pending** (mỗi trường 1 bé chưa `display_in_app` → để sẵn phép thử linh hồn).
- **🎯 Gắn tài khoản login** (6 vai: mỗi trường master + 1 GV CTAN + 1 PH 2-con) để nghiệm thu đăng nhập thật cross-tenant.
- **🎯 Seed data hoạt động** cho trường pilot (KHM): journey + moment approved cho Bé An & Khang → journal hết rỗng. Ảnh thật = **GV login upload** (đúng linh hồn, không mượn ảnh trẻ khác).
- **🎯 Nghiệm thu vòng đời đầy đủ** trên tenant mới: login → isolation → license → journal có nội dung → **GV upload ảnh thật** (chiều GHI cho tenant mới).

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc:** **46 bảng** · **38 hàm SECURITY DEFINER** · **125 RLS policy** · mig **001→034** — **KHÔNG đổi** (phiên data thuần). SYSTEM_MAP v0.17.
- **Seed:** **001→011** (mới: **seed_010** = 2 trường pilot + license + lớp + GV + trẻ + PH + consent; **seed_011** = journey + moment hoạt động cho An & Khang).
- **Tenant LIVE:** giờ có **3 trường** trong DB:
  - `DEMO-001` Trường Demo Dế Mèn (cũ, tenant gốc)
  - `KHM-DN` Kids House Montessori Đà Nẵng (mới — CTAN+Ballet)
  - `MNDM-DN` Trường Mầm Non Dế Mèn (mới — CTAN only)
- **6 tài khoản login mới** (tất cả `@demo.demenart.com`, password `Test@123`, auto-confirm):

| Vai | Email | Người | Trường |
|---|---|---|---|
| master | `hieutruong.kidshouse@demo.demenart.com` | Huỳnh Trần Nguyệt Thi | KHM |
| GV CTAN | `gv.linh.kidshouse@demo.demenart.com` | Đặng Mỹ Linh | KHM |
| PH 2-con | `ph.hung.kidshouse@demo.demenart.com` | Nguyễn Văn Hùng (An+Khang) | — (school NULL) |
| master | `hieutruong.demen@demo.demenart.com` | Mai Phương Dung | MNDM |
| GV CTAN | `gv.han.demen@demo.demenart.com` | Bùi Ngọc Hân | MNDM |
| PH 2-con | `ph.thanh.demen@demo.demenart.com` | Đặng Văn Thành (Hà+Phúc) | — (school NULL) |

> Các profile khác (GV/PH còn lại của 2 trường) đã seed nhưng `user_id=NULL` (chưa cần login để nghiệm thu). Tạo login sau khi cần = lặp lại pattern §3.2.

---

## 3. CÁCH LÀM — CHI TIẾT (nguồn sự thật cho phiên sau)

### 3.1 Seed onboarding — chuỗi phụ thuộc (seed_010)
Thứ tự BLOCK đúng FK: `schools` → `profiles` (staff school_id=trường · **PH school_id=NULL**) → `school_subscriptions` → `school_subject_entitlements` → `classes` → `class_distributions` (rót môn + GV lead) → `children` → `enrollments` → `child_parents` → `consents`.
- **Guard trigger:** Org/People (`schools`/`profiles`/`children`/`class_distributions`...) có `trg_guard_*` → seed bọc **`SET session_replication_role = replica;` … `= DEFAULT;`** (D30). `auth.uid()` NULL trong SQL Editor (D2) nên guard chặn nếu không bypass.
- **Idempotent:** mọi INSERT `ON CONFLICT (id) DO NOTHING`; UUID đặt tay theo prefix tenant (`d1…`=KHM, `d2…`=MNDM) để chạy lại an toàn + phân biệt tenant bằng id, KHÔNG bằng tên (S2 "Trường Mầm Non Dế Mèn" gần giống tenant cũ "Trường Demo Dế Mèn" → tránh lẫn).
- **Verify** = 1 `SELECT jsonb_pretty(...)` cuối: schools/master · subscriptions · entitlements · distributions · counts (GV/trẻ/PH mỗi trường) · multi_child_parents · pending_consent_children · `ballet_in_s2=0`. **Khớp 100%.**

### 3.2 ⭐ Gắn login — link `auth.users` ↔ `profiles` (→ D85)
- **KHÔNG insert thẳng `auth.users` bằng SQL** (schema auth nội bộ Supabase, đổi theo version — đoán = hỏng). Cách sạch: **Jean tạo tay** trên Dashboard → Authentication → Users → Add user (email khớp `profiles.email` + password + **tick Auto Confirm User** vì email giả không nhận mail xác nhận).
- **Link bằng UPDATE join theo email** (không cần dán UUID):
  ```sql
  SET session_replication_role = replica;   -- ⭐ BẮT BUỘC: profiles có guard trigger
  UPDATE public.profiles p SET user_id = u.id
  FROM auth.users u
  WHERE lower(trim(p.email)) = lower(trim(u.email))
    AND p.user_id IS NULL AND p.email LIKE '%@demo.demenart.com';
  SET session_replication_role = DEFAULT;
  ```
- **⚠️ BẪY THEN-CHỐT phiên này (→ D85):** lần đầu chạy UPDATE **không** set replica → `linked_count=0`, **không lỗi, không đổi dòng nào** (guard trigger `trg_guard_profiles_protected` nuốt UPDATE âm thầm vì `auth.uid()`=NULL). Thêm `replica` → link 6/6 ngay. **Guard trigger chặn cả UPDATE, không chỉ INSERT** — D30 mở rộng.

### 3.3 Seed data hoạt động (seed_011) — journal hết rỗng
- Bảng activity (`learning_moments`/`moment_children`/`child_journey`) **KHÔNG guard trigger** (chỉ `updated_at`) → **không cần replica**; SQL Editor bypass RLS → insert thẳng.
- **journal UI đọc qua RPC `get_child_journal(child_id)`** (secdef): `journey[]` từ `child_journey` (program_name qua `program_id`); `moments[]` = `learning_moments` **state=`approved`** ⨝ `moment_children`, ảnh = `media_assets.linked_moment_id` (active, đầu tiên). → Seed: journey 4 dòng (An×2, Khang×2, entry_type=`session`, program CTAN) + 2 moment **approved** (An "lắng nghe tiếng đàn" lớp Hoa Hồng / Khang "gõ nhịp" lớp Hướng Dương) + tag moment_children. **KHÔNG seed media** — ảnh thật để GV upload.
- **Verify KHÔNG gọi `get_child_journal`** trong SQL Editor (auth.uid()=NULL, RPC raise `not_authorized`) → đọc thẳng bảng (D2).

### 3.4 Ảnh = GV upload thật (KHÔNG mượn ảnh, KHÔNG seed media)
- Quyết **linh hồn:** gắn ảnh Bé Jenny vào moment Bé An = mượn ảnh trẻ khác → sai "nhật ký thuộc chính đứa trẻ" dù chỉ demo. Vậy ảnh thật do **GV Đặng Mỹ Linh login `/portal/moments`** upload (đúng luồng `upload_media`) → vừa đúng linh hồn vừa **nghiệm thu chiều GHI cho tenant mới**.

---

## 4. NGHIỆM THU v16 (bằng chứng thật — login `demenart.com`)

| # | Vai / màn | Bằng chứng | Kết luận |
|---|---|---|---|
| ① | Nguyệt Thi `/portal` | master_admin · School ID **d1**…001 | tenant 1 |
| ② | Mai Phương Dung `/portal` | master_admin · School ID **d2**…001 | **2 master cạnh nhau, school_id khác → ISOLATION rõ** |
| ③ | Bùi Ngọc Hân `/portal/curriculum` | **2 track CTAN** (Chú Vịt Con + demo), **KHÔNG Ballet** | **LICENSE THEO-THÀNH-PHẦN sống ở UI** (MNDM không mua Ballet) |
| ④ | PH Nguyễn Văn Hùng `/portal/journal` | toggle **An + Khang** (xuyên lớp Hoa Hồng↔Hướng Dương) | parent-child link đúng, không lộ con nhà khác |
| ⑤ | journal An/Khang | **Hành trình** 2 dòng *Buổi học · CTAN* + **Khoảnh khắc** card caption | **`journey[]` ĐÃ wire ra UI** (cả 2 section sống); ảnh placeholder "Ảnh tạm thời chưa xem được" (chưa upload — đúng) |
| ⑥ | GV Đặng Mỹ Linh `/portal/moments` | thấy đúng 2 moment "Đã duyệt" của lớp mình + nút upload | gate đọc đúng tenant |
| ⑦ | GV Linh upload ảnh moment An | **"✓ Đã tải" + ảnh hiện ngay** | **CHIỀU GHI `upload_media` sống cho TENANT MỚI** (`check_media_upload_access` cho GV KHM PUT zone `dma-private`); vòng GHI↔ĐỌC khép kín |

**⭐ BÀI HỌC VÀNG v16:** Tenant pilot mới chạy **trọn vòng đời** — onboard → isolation → license-theo-thành-phần → data hoạt động → GV upload ảnh thật → PH xem nhật ký con — **KHÔNG sửa một dòng code nào**. Toàn bộ engine v3–v14 (RLS 8 cụm, entitlement, consent, upload gate, journal RPC) tự phục vụ tenant mới. Đây là bằng chứng nền tảng **production-ready cho multi-tenant** mạnh nhất từ trước tới nay.

---

## 5. VIỆC TREO (gộp nợ cũ + mới)

1. **(NỢ v15) SPF KÉP** — `demenart.com` có **2 record TXT SPF** (sai sẵn từ GoDaddy, migrate y nguyên sang Cloudflare). Chuẩn DNS chỉ 1 SPF/domain → gộp 1 dòng hợp lệ (cần xác định domain gửi mail thật qua provider nào rồi merge include). Làm khi rảnh, test kỹ.
2. **(NỢ v12–v15) Lưu migration vào repo:** mig **026–034** (`.sql`) + Edge `get_signed_media_url/index.ts` + `upload_media/index.ts` cùng 001–025. **+ Lưu thêm seed_010 + seed_011** (phiên này sinh).
3. **(NỢ v12) Sửa `seed_007_ops_config` repo:** `body_template` bỏ "Bé " thừa (đã UPDATE live).
4. **(NỢ v12) Xác nhận `drop function public._neg_test();`** (helper tạm test consent v9).
5. **(NỢ) Caption "[seed]"** còn ở moment demo gốc trong DB (UI strip client). Cosmetic. *(Moment pilot mới KHÔNG có "[seed]" — caption ấm sạch.)*
6. **(NỢ) Row WRITE-BLOCK TEST treo** (`child_observations.note`/`child_journey.entry_type`='WRITE-BLOCK TEST (panel)' + `learning_moments.caption='[panel] write-block test'`). Không gấp.
7. **(NỢ v15) Vercel project `demenart` dormant** — xóa được cho gọn.
8. **(MỚI) Profile GV/PH còn lại của 2 trường pilot** `user_id=NULL` (chưa tạo login). Tạo khi cần nghiệm thu thêm vai — lặp pattern §3.2.
9. **(MỚI — tuỳ chọn) Vòng PH-sau-upload chưa chụp:** PH Hùng reload `/journal` tab An **sau** GV upload → ảnh thật thay placeholder. Ảnh đã hiện phía GV ngay sau upload (đủ bằng chứng GHI); vòng phía PH để xác nhận thêm khi tiện.

---

## 6. NGÃ KẾ (chọn đầu phiên sau)

- **A. Onboard data hoạt động trường S2 (MNDM)** — làm cho Hà/Phúc giống An/Khang (journey + moment) để cả 2 tenant đều có nhật ký sống; +seed thêm Ballet moment cho S1 (chứng môn thứ 2).
- **B. `request_sensitive_access`** (admin xem PII trẻ CÓ AUDIT — D48 carve-out). Engine vừa phải; "cửa có kiểm soát".
- **C. `create/resolve_private_share_link`** (share ảnh khoảnh khắc cho PH/ông bà ngoài app — D55/D66). Token nội bộ + expiry + scope; resolve = Edge public bypass RLS.
- **D. Build màn admin onboarding (1B)** — giờ đã onboard tay 2 trường, yêu cầu UI đã rõ hơn → super_admin tạo trường+license+master qua app; master tự nhập lớp/GV/trẻ. (Trước đây hoãn vì sợ build trên giả định — nay có data thật làm chuẩn.)
- **E. Dọn nhẹ:** lưu mig+seed vào repo (§5 mục 2) + SPF kép (§5 mục 1).

> **Gợi ý nhịp:** Multi-tenant đã proven trên LIVE. **C (share link)** tăng giá trị cảm nhận PH nhanh nhất (khoe ảnh con). **D (admin onboarding UI)** biến onboard-tay-thành-sản-phẩm — giờ là thời điểm tốt vì đã có 2 trường thật làm khuôn. **B** là admin tooling. Dọn (E) xen kẽ.

---

## 7. KỶ LUẬT GIỮ NGUYÊN (nhắc nhanh — phiên data)

- **Audit thật trước khi viết (D1):** phiên này audit 2 lần (onboarding chain + activity tables) trước mỗi seed; bắt được `consents` (không phải `media_consents`), `file_type` (không `mime_type`), `learning_moments.session_id→lesson_sessions`.
- **Guard trigger = replica cho cả INSERT lẫn UPDATE (D30→D85):** bài học then-chốt phiên này.
- **Linh hồn đứng trên tiện lợi:** không mượn ảnh trẻ khác cho demo; ảnh do GV upload đúng luồng.
- **Schema do migration Claude sở hữu (D5/D11):** phiên này CHỈ thêm DATA (seed 010/011), KHÔNG đụng bảng/cột/policy. Lovable 2-way sync vẫn ON.
- **Verify bằng login thật 4+ vai (D3):** 7 mục nghiệm thu cross-tenant, không tin "seed OK".

---

*Handoff v16 — 2026-06-26 09:54 GMT+7. ✅ ONBOARD 2 TRƯỜNG PILOT → MULTI-TENANT VALIDATED LIVE. seed_010 (KHM-DN: CTAN+Ballet·4seat·8trẻ·7PH · MNDM-DN: CTAN-only·3seat·6trẻ·5PH; mỗi trường 1 PH 2-con xuyên lớp + 1 bé consent-pending) + seed_011 (journey+moment hoạt động An/Khang). 6 login mới (master/GV/PH × 2 trường, `Test@123`). Nghiệm thu login thật 7 mục: 2 master isolation (school_id khác) · GV MNDM chỉ thấy CTAN không Ballet (license theo-thành-phần) · PH toggle 2 con xuyên lớp · journal Hành trình+Khoảnh khắc sống (journey[] đã wire) · GV KHM upload ảnh thật → "✓ Đã tải" (chiều GHI tenant mới). **Bài học vàng: tenant mới chạy trọn vòng đời KHÔNG sửa 1 dòng code — engine v3–v14 tự phục vụ.** **⭐ D85 mới: guard trigger chặn cả UPDATE (link auth.users↔profiles lần đầu linked_count=0 vì quên replica) → SET session_replication_role=replica cho cả UPDATE.** **DB cấu trúc KHÔNG đổi: 46 bảng · 38 hàm definer · 125 policy · mig 001→034. Seed 001→011 (3 tenant trong DB).** SYSTEM_MAP v0.17; RULES +D85. Việc treo: SPF kép, lưu mig 026–034+seed 010/011 repo, profile GV/PH còn lại chưa có login. Kế: onboard hoạt động S2 · admin onboarding UI (1B) · request_sensitive_access · share link. Nguồn: A–G + RULES + SYSTEM_MAP v0.17.*
