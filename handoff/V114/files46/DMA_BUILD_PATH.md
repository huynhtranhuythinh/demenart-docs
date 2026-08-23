# 🛤️ DMA_BUILD_PATH.md — CON ĐƯỜNG BUILD (8 chặng)

> **Cách dùng:** Khi lên kế hoạch chặng kế tiếp, đọc mục tương ứng. Mỗi chặng ghi: mục tiêu · tái dùng DMWS · ⚠️ chỗ DMWS từng sa lầy · acceptance.
> **Nguồn:** Tài liệu E (8 phase) + kinh nghiệm DMWS v170. Build order: **demo-story-first, 4 portal từ đầu**.
> **Nguyên tắc xuyên suốt:** DB-first → RLS/Function → Edge → UI. Library + Trung Tâm Tra Cứu dựng NGAY Phase 1.

---

## 🎯 CHẶNG 0 — DỰNG NỀN TỰ-DUY-TRÌ (làm CÙNG Phase 1, đừng đợi)

Đây là điều DMA làm khác DMWS (DMWS đợi tới v162). **Trước/song song khi code Phase 1:**
1. Nạp bộ library (`00_START_HERE`, `RULES`, `SYSTEM_MAP`, file này) vào Project Knowledge.
2. Dựng **Trung Tâm Tra Cứu** ngay khi có Admin shell — registry-driven, mỗi module khai metadata đủ (D100).
3. Thiết lập quy trình handoff (mỗi phiên 1 file `DMA_HANDOFF_vX`).

---

## CHẶNG 1 — Foundation: auth, 4 portal shell, env/secret policy, schema fields

**Mục tiêu:** Skeleton + Supabase Auth + routing 4 role + chính sách env/secret + chuẩn bị field `media_assets` Bunny-aware (CHƯA serving media).
**Tái dùng DMWS:** Admin shell + role-aware routing + permission registry (clone đậm). Design tokens "ấm/nghệ thuật/cao cấp" (KHÁC DMWS — không bê tone DMWS).
**⚠️ DMWS sa lầy:**
- Secret rò ra client → **D63**: `VITE_*` CHỈ Supabase URL+anon; mọi key Bunny/service_role ở Edge Function secrets.
- `role` baseline = chọn 1 baseline, năng lực = permission cộng thêm (D45/← G473). Đừng flip role.
**Acceptance:** login 4 role vào đúng portal · không secret trong bundle/repo · `media_assets` field Bunny-aware sẵn (chưa serving) · vercel.json + deploy checklist · **Trung Tâm Tra Cứu khởi động**.

---

## CHẶNG 2 — Org & people: trường/lớp/GV/trẻ/PH + import + child-parent link

**Mục tiêu:** CRUD schools/**classes(HOMEROOM)**/teachers/children/parents + import Excel/CSV + global child ID + **`enrollments`(trẻ×homeroom, mã HS, state)** + link ≤2 PH.
**Tái dùng DMWS:** organizations/org_members/import (clone+sửa) · children+claim (clone, **thêm Global ID + để-ngỏ-auth D41**).
**⚠️ DMWS sa lầy:**
- `enforce_max_two_parents` qua trigger (D27) — test bằng UI thật (D2: auth.uid NULL trong SQL Editor).
- **THÉP CHỜ #2 (D41):** thiết kế `children` để ngỏ danh tính PIN tương lai — đừng khóa cứng.
**Acceptance:** demo trường/lớp/trẻ/PH · link ≤2 enforced · global child ID + school code · chưa media.

---

## CHẶNG 3 — Curriculum & sessions (chưa serving media)

**Mục tiêu:** programs(toàn cục)/age_groups/levels/themes/lessons/lesson_versions (immutable) + content workflow + **`program_distributions`(roadmap/piece)** + **`class_distributions`(rót môn vào homeroom + lead)** → bung `lesson_sessions` + **`session_media`(upload\|dma_library)** + reports + child_observations (tap-first) + GV chỉnh tiết (content_override).
**Tái dùng DMWS:** Xưởng/giáo án (clone đậm) · proposal-versioning → lesson_versions (clone pattern) · **override per lớp D44** (← propose_override_to_workshop) · workshop_events+task_report → sessions+reports (clone).
**⚠️ DMWS sa lầy:**
- Versioning: KHÔNG ghi đè, `lesson_version_autoincrement` immutable (D43). Version trẻ học ghi ở `lesson_sessions.lesson_version_id` (trong `class_distributions`).
- **THÉP CHỜ #1 (D40):** `programs` TOÀN CỤC (không gắn school_id); `child_journey` gắn child + cột `source`.
- Soạn ≠ vận hành: curriculum authoring tách session execution (← G511/D45).
**Acceptance:** lesson "Bé chuyển động cùng giai điệu" có version · session lifecycle · report+observations tap-first lưu · đúng `lesson_version_id`.

---

## CHẶNG 4 — Media foundation (Bunny + Edge Functions) — ⭐ BẮT ĐẦU BẢO MẬT MEDIA

**Mục tiêu:** migration delta `media_assets`/`audit_logs` (Bunny fields) + Edge Functions `upload_media` + `get_signed_media_url` + Media Library (path/metadata only).
**Tái dùng DMWS:** Bunny upload core (← G556 whitelist prefix, G558 cropper) — NHƯNG **nâng tầng**: DMA private zone + signed URL per-view (DMWS chỉ CDN công khai).
**⚠️ Đây là phần DMWS KHÔNG giúp nhiều — đọc kỹ Tài liệu G + D60-D69:**
- DB KHÔNG lưu URL dùng được (D62). Client KHÔNG fetch trực tiếp Bunny private (D64).
- Mọi lượt xem qua Edge Function ký URL ngắn hạn + audit (D61/D67).
**Acceptance:** upload qua Edge Function (không client key) · DB không URL dùng được · preview signed URL ngắn hạn · audit media_upload/media_view.

---

## CHẶNG 5 — Curriculum media (stream-only + watermark động)

**Mục tiêu:** serve video/audio học liệu CTAN stream-only (signed_url/signed_stream) + watermark động di chuyển + wire content workflow ↔ media approval.
**Tái dùng DMWS:** ít — phần lớn MỚI (Tài liệu G).
**⚠️ Trọng tâm:**
- Học liệu KHÔNG download, KHÔNG permanent URL (D65). Watermark di chuyển vị trí (chống crop).
- UI KHÔNG tuyên bố chống quay màn hình 100% (D68). DRM = V2/V3.
**Acceptance:** học liệu view-only · watermark chạy+di chuyển · không permanent URL · audit curriculum_media_view.

---

## CHẶNG 6 — Learning moments + consent gating + parent view + private share

**Mục tiêu:** GV upload moment (lớp/buổi được gán) → approval → parent xem (approved+consent+MIN) + private share (create/resolve/revoke) + download có watermark.
**Tái dùng DMWS:** event_photos+tag+community approve (clone+sửa) · share token (← event_share_tokens) · Parent /toi (clone+sửa → Child Art Profile timeline+cột mốc).
**⚠️ DMWS sa lầy + DMA mới:**
- **Consent 2 tầng D47:** quyền = min(trường, PH); multi-child = MIN consent. Đây là LÀM MỚI, nặng — test kỹ CASE 2 (Tài liệu F).
- Parent KHÔNG upload moment V1 (D64). PH comment chỉ khi `parent_comment_mode` bật.
- Share link token nội bộ, KHÔNG map Bunny URL (D66); revoke → 403 + audit.
**Acceptance:** parent chỉ xem approved+consent+MIN · share expiry/revoke → 403 · download watermark+audit.

---

## CHẶNG 7 — Sensitive access + full audit + business + support

**Mục tiêu:** `request_sensitive_access` (reason+purpose, audit TRƯỚC khi trả) + đủ audit events + packages/contracts/payments thủ công + revenue + notifications + support + privacy requests.
**Tái dùng DMWS:** contract/proposal/cổng B2B (clone) · audit (DMWS nhẹ → nâng).
**⚠️ Làm rõ TRƯỚC khi build business (SYSTEM_MAP §5):**
- **License tách bạch** (chốt): `Tổng = (số môn × giá môn) + (số tk GV × giá GV) + storage add-on`. Môn (`school_subject_entitlements`) và seat (`school_subscriptions.seat_count`) độc lập; seat subject-agnostic; Master bundled (không seat); storage cấp trường + add-on. KHÁC `packages` tier v1 — dùng `school_subscriptions`+`school_subject_entitlements`+`pricing_config`.
- License-gate tách journey-ownership (D42): trường hết hạn → trẻ/PH vẫn xem nhật ký.
- Admin xem PII trẻ phải qua request_sensitive_access + audit trước (D48).
**Acceptance:** sensitive access chặn nếu thiếu reason/purpose + audit trước · đủ media audit events · business + requests chạy.

---

## CHẶNG 8 — Demo polish & acceptance

**Mục tiêu:** seed demo story (Trường MN Dế Mèn, Lớp Chồi, Cô Nguyệt Thi/Thúy Ngân/Phương Dung, Bé Jenny/Jimmy) + visual ấm/nghệ thuật/cao cấp + regression bảo mật media + deploy + domain.
**⚠️ Demo data: 1 trường NHIỀU MÔN** (founder chốt — không phải nhiều trường), để bán câu chuyện "kho giáo án mở rộng". Multi-program phải THẬT trong demo.
**Acceptance:** demo end-to-end 4 portal · regression bảo mật pass (Tài liệu F §5) · UI không claim chống quay màn hình 100%.

---

## 📌 BẢN ĐỒ PHASE ↔ DEMO STORY (← Tài liệu E)

| Phase | Vai demo story | Tái dùng DMWS |
|---|---|---|
| 1 | Khung + đăng nhập role | 🟢 đậm |
| 2 | Admin dựng trường/lớp/trẻ/PH | 🟢🟡 |
| 3 | Admin tạo giáo trình CTAN + versioning | 🟢 đậm |
| 4 | **Teacher dạy & báo cáo** (Cô Thúy Ngân) | 🟢 đậm + 🔴 media |
| 5 | Học liệu stream-only | 🔴 mới |
| 6 | **Parent xem Child Art Profile** (Jenny/Jimmy) | 🟡 + 🔴 consent |
| 7 | Sensitive access + business | 🟢🔴 |
| 8 | Polish demo | — |

> **Lưu ý vàng:** Mỗi chặng xong → cập nhật `RULES` (luật mới phát sinh) + `SYSTEM_MAP` (bảng/module mới) + Trung Tâm Tra Cứu CÙNG NHỊP. Đừng để tài liệu tụt sau code (bài học V162 DMWS).

---

*Khởi tạo cho DMA. Nguồn: Tài liệu E (8 phase) + kinh nghiệm DMWS v170. Cập nhật khi lộ trình điều chỉnh.*

---

## 🧭 V114B-E3 EXECUTION STATE — MILESTONE CLOSEOUT (25/07/2026 · FINAL)

> **Khối này SUPERSEDE mọi khối "V114B-E3 EXECUTION STATE" trước đó** (kể cả bản WP4-S3A SEALED nếu tồn tại trong bản local).

**Track E3 (Chặng 4/6 hardening + authority) — ĐÓNG TOÀN BỘ:**
- **WP1** — attribution containment (mig 105–106) · **WP2 S0A/S0B/S1/S2** — writer harmonization, STA foundation, planned-teacher read (mig 107–110) · **WP3** — `lesson_sessions` write revoke (mig 111) · **WP4 S3/S3A/S4** — authority cutover D324 (mig 114) + frontend alignment D325 (`5d28ee67`) · **RM1** — `session_reports` write revoke (mig 115).
- **E3 MILESTONE CLOSEOUT 25/07:** canonicalized **D310–D323 + D-A2-1** vào RULES (13 PROMOTE + 2 PROMOTE WITH CORRECTION; D314–D322 từ recovered conversational source SHA `dc1494b0…aa49` với provenance qualifier). Documentation-only — 0 code/migration/deploy.
- **Gates chốt:** E3-SG-01 `CLOSED BY CTO DECISION` · E3-SG-02 `CONTAINED — NOT CLOSED` · `session_reports` `CONTAINED FOR USER-JWT MUTATION PATHS` (+P3 dead-door debt) · **R21 `OPEN RESIDUAL MONITORING — NON-BLOCKING; VERIFY AT FIRST RELEVANT OWNER/ORGANIC MUTATION`**.
- **Endpoint:** RULES D325 + E3 canon · SYSTEM_MAP **v1.18** · HANDOFF **V114B-E3-MILESTONE-CLOSEOUT** · registry **115** · inventory 88/210/199/166/33 · routes 52 · 16 Edge.

**Kế (chưa mở, chờ Owner):** ứng viên — `pg_default_acl` remediation milestone (ALTER DEFAULT PRIVILEGES 2 grantor + rule-enforcement) · responsibility-transfer RPC (trước ca transfer thật) · fixture milestone (sub_admin + Nam/Vy + CONSENT-NEGATIVE-FIXTURE + FMN E2E) · G.4+ restyle.
