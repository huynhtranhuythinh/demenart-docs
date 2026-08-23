# 🤝 DMA_HANDOFF_v17.md — BÀN GIAO PHIÊN (3 NGÃ: DATA ĐA-MÔN · SENSITIVE-ACCESS · SHARE LINK)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v17. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

Phiên **3 ngã liên tiếp** (B + C đụng function/Edge, A data thuần). Tất cả nghiệm thu **login thật trên LIVE `demenart.com`** (D3).

- **🅰️ NGÃ A — Data hoạt động đa-môn 2 tenant (seed_012):**
  - MNDM (S2) Hà/Phúc: journey + moment approved giống An/Khang → journal S2 hết rỗng.
  - **Ballet moment cho An (KHM)** → An có **CTAN + Ballet trong CÙNG một cuốn nhật ký** = bằng chứng mạnh nhất cho thép chờ #1 (nhật ký đa-môn thuộc về đứa trẻ).
  - Đóng nốt **chiều GHI cho tenant S2** (GV Hân upload ảnh thật — điểm v16 còn thiếu).
- **🅱️ NGÃ B — `request_sensitive_access` (mig 035, D86):** cửa-có-kiểm-soát cho admin nền tảng xem PII trẻ (D48 carve-out) — nêu lý do + mục đích → **ghi audit TRƯỚC khi trả**.
- **🅲 NGÃ C — `create/resolve_private_share_link` (mig 036/036b + Edge, D87):** PH khoe ảnh khoảnh khắc con cho ông bà **ngoài app** — token nội bộ + expiry + re-check consent → **link tự chết khi PH rút consent**.

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc:** **46 bảng** · **40 hàm SECURITY DEFINER** (+`request_sensitive_access` +`create_private_share_link`) · **125 RLS policy** · mig **001→036**. SYSTEM_MAP v0.18.
- **Seed:** **001→012** (mới: **seed_012** = data hoạt động MNDM Hà/Phúc + Ballet moment KHM An).
- **Edge Functions:** `get_signed_media_url` · `upload_media` · **`resolve_share_link`** (mới — PUBLIC, Verify JWT OFF).
- **RPC mới:** `request_sensitive_access` (D86) · `create_private_share_link` (D87). Cả 2 grant `authenticated`, verify D15 `[]`.
- **Routes UI mới:** `/portal/sensitive-access` · `/share/$token` (public, không Portal shell) · **nút "Chia sẻ"** trên card moment `/portal/journal`.
- **3 tenant LIVE:** `DEMO-001` · `KHM-DN` · `MNDM-DN` (không đổi).

**⚠️ Data state cần nhớ (phiên này thay đổi):**
- **`KHM-DN.sharing_mode` đã đổi `no_external_sharing` → `private_share_link`** (để nghiệm thu share). MNDM + DEMO vẫn `no_external_sharing`.
- **Consent An `private_share_link` (`d1000000-0000-4000-8000-0000000000e1`) hiện `withdrawn_at IS NOT NULL`** (rút để nghiệm thu link-tự-chết; Jean OK để vậy). Muốn pilot share lại: `UPDATE public.consents SET withdrawn_at=NULL WHERE id='d1000000-0000-4000-8000-0000000000e1';`

---

## 3. CÁCH LÀM — CHI TIẾT (nguồn sự thật cho phiên sau)

### 3.1 Ngã A — seed_012 (data hoạt động, KHÔNG guard → KHÔNG replica)
- Activity tables (`child_journey`/`learning_moments`/`moment_children`) KHÔNG guard trigger → seed thẳng, không cần `session_replication_role`.
- `moment_school_id()` resolve qua `class_id` (`class_school_id`) → chỉ cần `class_id` đúng tenant là moment tự về đúng trường. `uploaded_by` = lead GV của dist môn-lớp đó.
- **An đa-môn:** journey Ballet (`…c5`) + moment Ballet (`…a3`, lead Vũ Hoàng Nam `d1…012`) tag An → journal An hiện Hành trình **3 dòng** (CTAN + Ballet icon khác) + Khoảnh khắc card Ballet.
- **KHÔNG seed media** — ảnh để GV upload thật (đúng linh hồn).

### 3.2 Ngã B — `request_sensitive_access` (mig 035, D86)
- **Gate `is_admin()` only** (6 role nền tảng). Master/GV/PH → `not_platform_admin` (họ đã được RLS phục vụ PII; không cần carve-out).
- **Ghi vết = `audit_logs` qua `write_audit_log` (D72)** — bảng CÓ SẴN cột `reason`/`purpose`. **KHÔNG đụng `privacy_requests`** (workflow yêu-cầu-đến Fork 2A, khác bản chất).
- **Audit TRƯỚC khi trả; nhánh denied cũng ghi** (`sensitive_access_denied`) → kẻ chưa-login (actor NULL) lẫn sai-vai (actor=PH) đều để dấu.
- **scope:** `identity` (tên/nickname/dob/giới tính/global_id/state) · `full` (+phụ huynh contact +ghi danh) — data-minimization.
- Bypass RLS `children` CỐ Ý qua secdef (gương D73). Resolve school qua enrollment (D40).
- **Nghiệm thu (D2):** nhánh denied test thẳng SQL Editor (nhận tham số); nhánh **granted cần login admin thật** (auth.uid).

### 3.3 Ngã C — share link (mig 036/036b + Edge `resolve_share_link`, D87)
- **`share_links` ĐỦ CỘT** từ mig 006 (token/scope_type/scope_ref_id/expires_at/revoked_at/created_by_profile_id) + RLS Fork 3A creator-only → **KHÔNG mig cột.**
- **Tạo (RPC):** gate = `media_consent_check(moment, current_profile(), 'share')` (D71 nhánh share đã có sẵn). Token `encode(extensions.gen_random_bytes(24),'hex')`, TTL clamp 5'..30 ngày, audit `share_link_created`/`_denied`.
- **Resolve (Edge PUBLIC, Verify JWT OFF, KHÔNG getUser):** token valid + chưa-revoked + chưa-expired → **RE-CHECK consent (viewer=creator) tại thời điểm xem** → tự chết nếu rút → ký Bunny `dma-private` 5' → trả CHỈ `signed_url` (KHÔNG PII).
- **Phép thử linh hồn:** trường `no_external_sharing` → `school_blocks_share` (PH đồng ý cũng không share); rút consent → link 403 dù chưa hết hạn (PH cầm quyền tắt).

### 3.4 ⭐ 3 LỖI LOGIN-THẬT BẮT (SQL-pass che hết — D2/D3) → 3 luật
1. **D20 mở rộng** — `search_path=''` thì phải qualify cả **hàm extension**: `extensions.gen_random_bytes()`. SQL Editor (search_path mặc định) che lỗi → verify `ok`; RPC secdef chạy → `42883 function does not exist` → `.rpc` throw → UI else.
2. **D63 mở rộng** — Edge service-key = tên built-in **`SUPABASE_SERVICE_ROLE_KEY`** (default secret tự inject), KHÔNG tự chế `SERVICE_ROLE_KEY` → `undefined` → `createClient` throw `Error: supabaseKey is required`. (Copy tên từ Edge đang chạy tốt.)
3. **D2 mở rộng** — câu verify side-effect đừng đọc lại bảng trong **cùng statement** (snapshot trước → thấy 0) + đừng window thời gian hẹp. `denied_audit_written=0` làm tưởng engine lỗi — thực ra vết đã ghi; câu kiểm sai, engine không sai.

---

## 4. NGHIỆM THU v17 (bằng chứng thật — login `demenart.com`)

### Ngã A (4 mục)
| # | Vai / màn | Bằng chứng | Kết luận |
|---|---|---|---|
| ① | PH Đặng Văn Thành `/portal/journal` | toggle **Hà↔Phúc** (Búp Măng↔Tuổi Thơ), mỗi bé Hành trình 2 CTAN + Khoảnh khắc card | 2-con xuyên lớp S2 |
| ② | PH Nguyễn Văn Hùng tab **An** | Hành trình **3 dòng**: CTAN(24/6) · **Ballet(23/6 icon khác)** · CTAN(19/6) + card Ballet | **đa-môn 1 nhật ký** (thép chờ #1) |
| ③ | GV Bùi Ngọc Hân `/portal/moments` | thấy 2 moment "Hà…"/"Phúc…" (Đã duyệt) lớp mình + upload | gate đọc đúng tenant S2 |
| ④ | GV Hân upload ảnh moment Hà | **"✓ Đã tải" + ảnh hiện** | **chiều GHI tenant S2 sống** (điểm v16 còn thiếu — nay đóng cả 2 tenant) |

### Ngã B (mig 035)
| # | Vai / màn | Bằng chứng | Kết luận |
|---|---|---|---|
| ① | Admin "Quản trị viên Test" `/portal/sensitive-access` scope identity | card "Hồ sơ định danh" Nguyễn Hoàng An + **mã audit** | **granted sống** — audit trước, PII sau |
| ② | Admin scope full | thêm **Phụ huynh** (Nguyễn Văn Hùng primary) + **Ghi danh** (KHM Hoa Hồng KH-HH-01) | data-minimization mở rộng |
| ③ | PH Hùng mở màn → tra An | banner **"Tài khoản không có quyền…"** | non-admin chặn UI + vết denied kèm actor PH |
| ④ | server-side | `granted_total=2` actor≠NULL school=`d1…001`; `denied_with_actor=1` | mọi đường để dấu |

### Ngã C (mig 036/036b + Edge)
| # | Vai / màn | Bằng chứng | Kết luận |
|---|---|---|---|
| ① | SQL gate | KHM `no_external`→`school_blocks_share`; mở→`ok` | min trường-PH (phép thử linh hồn) |
| ② | PH Hùng card CTAN An "Chia sẻ" | dialog `/share/{token}` + "hết hạn 24h" · RPC 200 | tạo link sống |
| ③ | **tab ẩn danh** (chưa login) mở link | **ảnh An hiện** qua signed `dma-private`, KHÔNG tên/caption/trường | resolve public + data-min |
| ④ ⭐ | rút consent An → reload link ẩn danh | 403 **"Ảnh này hiện không còn được chia sẻ"** | **link tự chết** dù chưa hết hạn (PH cầm quyền tắt) |

**⭐ BÀI HỌC VÀNG v17:** (1) An có **CTAN+Ballet trong một nhật ký** — linh hồn "album đa-môn thuộc về trẻ" sống ở UI thật. (2) Hai engine media-nhạy-cảm mới (sensitive-access + share link) đều theo **cùng pattern** đã chứng minh: gate secdef nhận-tham-số (test thẳng SQL nhánh từ chối) + Edge/UI điều phối (login thật nhánh thành công) + **ghi vết/re-check để moat & linh hồn không vỡ**. (3) **3 lỗi login-thật bắt** (qualify extension · tên service-key · verify side-effect) — lại một lần nữa SQL-pass ≠ live-pass (D2/D3).

---

## 5. VIỆC TREO (gộp nợ cũ + mới)

1. **(NỢ DỒN — ưu tiên) Lưu vào repo:** **mig 026–036** (`.sql`) + **seed 010, 011, 012** + Edge `get_signed_media_url`/`upload_media`/**`resolve_share_link`**`/index.ts` — cùng 001–025. Nợ tích từ v12.
2. **(MỚI) Nút THU HỒI share link tay** — UI hiện chưa có (`share_links.revoked_at` set tay/RPC). Link chỉ tự-chết qua expiry hoặc rút-consent. PH muốn chủ động hủy link đã chia → cần `revoke_share_link` + nút trên màn.
3. **(NỢ v15) SPF KÉP** — `demenart.com` 2 record TXT SPF (sai sẵn từ GoDaddy). Gộp 1 dòng hợp lệ. Test kỹ.
4. **(NỢ v12) Sửa `seed_007_ops_config` repo:** `body_template` bỏ "Bé " thừa (đã UPDATE live).
5. **(NỢ v12) Xác nhận `drop function public._neg_test();`** (helper tạm test consent v9).
6. **(NỢ) Caption "[seed]"** + row WRITE-BLOCK TEST còn trong DB (UI strip client). Cosmetic.
7. **(NỢ v15) Vercel project `demenart` dormant** — xóa cho gọn.
8. **(NỢ v16) Profile GV/PH còn lại** của 2 trường pilot `user_id=NULL` — tạo login khi cần (pattern §3.2 v16/D85).
9. **(MỚI — tuỳ) Cấp lại consent An** nếu muốn pilot share tiếp: `UPDATE public.consents SET withdrawn_at=NULL WHERE id='d1000000-0000-4000-8000-0000000000e1';`

---

## 6. NGÃ KẾ (chọn đầu phiên sau)

- **D. Build màn admin onboarding (1B)** — giờ đã onboard tay 2 trường + có data hoạt động thật làm khuôn → super_admin tạo trường+license+master qua app; master tự nhập lớp/GV/trẻ. **Thời điểm tốt nhất** (trước hoãn vì sợ build trên giả định — nay có khuôn thật).
- **E. Dọn repo + nợ hạ tầng** — lưu mig 026–036 + seed 010–012 + 3 Edge vào GitHub (§5 mục 1) + SPF kép. Trả nợ kỹ thuật trước khi đống lớn hơn.
- **F. `revoke_share_link` + UI thu hồi** — hoàn thiện vòng đời share link (§5 mục 2). Engine nhỏ.
- **G. Tách 4 portal** — hiện gộp 1 `/portal`; tách khi mỗi portal đủ nội dung.
- **Parent community / social layer** — vẫn hoãn (V2).

> **Gợi ý nhịp:** **D (admin onboarding UI)** là bước biến "onboard-tay" thành sản phẩm — giá trị cao nhất, đã đủ khuôn. **E (dọn repo)** là nợ kỹ thuật nên xen kẽ sớm (mig chưa lưu = rủi ro mất). **F** nhỏ, làm khi tiện. Multi-tenant + 4 engine media-nhạy-cảm đã proven LIVE → nền đã vững cho tooling.

---

## 7. KỶ LUẬT GIỮ NGUYÊN (nhắc nhanh)

- **Audit thật trước khi viết (D1):** phiên này audit 3 lần (activity tables · privacy_requests/audit_logs/children · share_links/consent engine) trước mỗi mig.
- **SQL-pass ≠ live-pass (D2/D3):** 3 lỗi login-thật bắt được phiên này — qualify hàm extension (D20), tên service-key (D63), verify side-effect (D2). Luôn nghiệm thu login thật cho nhánh dùng `auth.uid()`.
- **Linh hồn đứng trên tiện lợi:** admin 0-PII mặc định (carve-out có audit); share link tự chết khi PH rút consent; KHÔNG trả PII trong link công khai; không mượn ảnh trẻ khác.
- **Schema do migration Claude sở hữu (D5/D11):** phiên này +2 RPC +1 Edge, KHÔNG đụng bảng/cột/enum/policy (share_links + privacy_requests + consents + audit_logs đều có sẵn cột cần).
- **Library & Tra Cứu update cùng nhịp (KỶ LUẬT VÀNG):** RULES +D86/D87, mở rộng D2/D20/D63; SYSTEM_MAP v0.18; HANDOFF v17.

---

*Handoff v17 — 2026-06-26 11:24 GMT+7. ✅ 3 NGÃ ĐÓNG. **(A)** seed_012 data đa-môn 2 tenant — An có CTAN+Ballet CÙNG nhật ký + chiều GHI tenant S2 nghiệm thu. **(B)** mig 035 `request_sensitive_access` (D86) — cửa-có-kiểm-soát admin xem PII trẻ, ghi `audit_logs` TRƯỚC khi trả, gate is_admin, scope identity/full data-min, mọi đường ghi vết kèm actor; granted+denied login admin thật. **(C)** mig 036/036b `create_private_share_link` + Edge public `resolve_share_link` (D87) — PH share ảnh ngoài app, gate consent 'share' min trường-PH, re-check tại-thời-điểm-xem → link tự chết khi rút consent, KHÔNG trả PII; nghiệm thu tab ẩn danh trọn vòng. **3 lỗi login-thật → 3 luật:** D20 qualify hàm extension · D63 tên `SUPABASE_SERVICE_ROLE_KEY` built-in · D2 verify side-effect. **DB cấu trúc KHÔNG đổi: 46 bảng · 40 hàm definer · 125 policy · mig 001→036. Seed 001→012.** +1 Edge `resolve_share_link`. SYSTEM_MAP v0.18; RULES +D86/D87 + mở rộng D2/D20/D63. **Data state:** KHM-DN `sharing_mode=private_share_link`; consent An `d1…e1` WITHDRAWN. Việc treo: lưu mig 026–036+seed 010–012 repo (nợ dồn), nút thu hồi share link, SPF kép, profile GV/PH còn lại chưa login. Kế: admin onboarding UI (1B) · dọn repo · revoke-share-link UI. Nguồn: A–G + RULES + SYSTEM_MAP v0.18.*
