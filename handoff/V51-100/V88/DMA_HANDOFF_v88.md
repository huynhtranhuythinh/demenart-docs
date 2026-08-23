# DMA_HANDOFF_v88.md
**Sprint:** V88 — Shared Gallery Component & Kid Gallery Fix (→ Kid-only gallery pipeline)
**Ngày:** 2026-07-10 17:00 GMT+7 (Asia/Ho_Chi_Minh)
**Vai trò:** ChatGPT = CTO Advisor · Claude = PM + Prompt Operator + Builder · Lovable = build
**Trạng thái:** ✅ ĐÓNG SỔ — **DB verify PASS + Edge gate verify PASS + Kid/Parent/Teacher smoke PASS** · +0 hàm definer (CREATE OR REPLACE) · +0 bảng/policy/cron · UI frontend-only 1 file · 0 Parent/Teacher code · CTO chốt (Lối 1, có 3 chỉnh sửa).
**File code bị đụng:** **`src/routes/kid.tsx`** (duy nhất).
**DB:** `get_kid_album_service` CREATE OR REPLACE (1 `apply_migration`, additive). **Edge:** `kid_gate` v6→v8 (+action `sign_moment_media` + album consent-filter). **Commit UI:** `1a5af516`. Deploy: `demenart.com` (production, auto qua Lovable→GitHub→Cloudflare).

---

## 0. TL;DR

Bug user-visible: `/kid` moment nhiều-ảnh chỉ hiện **cover**, ảnh 2/3 không xem được. **Audit thật lật ngược mô tả brief:** Kid **KHÔNG có gallery ở BẤT KỲ tầng nào** (RPC trả 1 media_id/moment · Edge ký 1 cover · UI 1 `<img>` không dots). "Chạm chấm 2 fail" = ảo, vì chưa từng có dots. Lỗ = enrichment V79 chỉ vá `get_child_journal` (Parent), **chưa bao giờ** chạm `get_kid_album_service` (Kid). Vì Kid **không có `auth.uid()`** (D174) → không ký client như Parent → fix buộc chạm RPC+Edge → CTO gỡ chốt "no DB/Edge" cho **pipeline Kid tối thiểu, additive**.

- **A — RPC `get_kid_album_service`** (mig `v88_enrich_kid_album_gallery_metadata`, D92): mỗi moment thêm `coverMediaId`/`mediaCount`/`hasGallery`/`galleryItems[{mediaId,fileType,createdAt}]` (metadata-only, **0 signed_url**), active-only, `created_at ASC, id ASC`; `media_id` (cover) backward-compat; `coverMediaId === media_id === galleryItems[0].mediaId`. Grants service_role-only (leaky=false).
- **B — Edge `kid_gate` v8:** (1) album **consent-filter per-moment** (`media_consent_check(moment, PH-của-bé, 'view')`; fail → strip metadata + không ký cover → UI tự rớt); (2) action mới **`sign_moment_media`**: session → kid_access → authz(moment approved+tag) → media active+linked → **consent** → `signAsset`. Reason generic (`not_authorized`/`not_found`), **0 rò state**. Contract `{ok, signed_url|reason}`.
- **C — UI `kid.tsx`:** component Kid-only **`KidMomentLightbox`** (cover seed từ signed_url; `selectItem` ký on-demand qua `sign_moment_media` + cache theo mediaId + `knownRef` chống re-sign; dots/counter aria-live; soft loading/error). **Cả 2 entry point** (`openMoment` grid + timeline moment `openItem`) route chung component. `galleryItems<=1` → y cũ.
- **⭐ BASELINE re-baseline: An 6/2/5 → 6/2/6** (nguồn `c7fe22f4` "Bé làm workshop", gallery thứ 3, tạo 07-10 13:48) — **KHÔNG regression, KHÔNG xoá** (CTO chốt).
- **⭐ Endpoint sau V88:** RULES **D220** · SYSTEM_MAP **v0.81** · Handoff **v88**.

---

## 1. Canonical đã đọc — endpoint verify (đầu phiên)

Topic V88 mở mới. **KHÔNG dựa memory** — đọc canonical thật trên đĩa: `DMA_HANDOFF_v87.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md`.

**Endpoint đầu phiên (LIVE trên đĩa):** RULES **D219** · SYSTEM_MAP **v0.80** · Handoff **v87** — **khớp brief cả 3** ✔ · **0 drift đĩa**.

---

## 2. C1 — Audit LIVE (read-only) — phát hiện lõi

**DB (`xcvhacymrbhdhohyylyq`):**
- Inventory **63 · 106 · 155 · 1** = khớp V87 → 0 drift.
- `c6fc98e8` = 3 media · `f51039be` (`…48e8-42c5-9900-b03f3472cd1f`) = 2 · `get_child_journal` có galleryItems, `signed_url` = **comment-only** (0 field output) · grants authenticated/postgres/service_role (0 anon).
- **⚠️ Drift D112 — An summary LIVE = 6/2/6 (không phải 6/2/5):** `summarizeChildJournal` đếm "Khoảnh khắc" = moment có `media_id`; An có **6** moment media-active (thêm `c7fe22f4` "Bé làm workshop", 2 media, tạo 07-10 13:48). works 6 (drawing) · voice 2 (recording) · moments 6.
- **⭐ Kid KHÔNG có gallery (3 tầng):** `get_kid_album_service` trả **1 `media_id`/moment** (subselect cover), 0 galleryItems · `kid_gate album` ký 1 cover/moment · `kid.tsx` `Moment` type chỉ `{moment_id,caption,created_at,signed_url,my_reaction}`, dialog render 1 `<img>` + reaction, **0 dots/counter**. Symptom brief ("chạm chấm fail") KHÔNG tồn tại. Lỗ = V79 chỉ enrich `get_child_journal`.
- **Kid ký khác Parent:** Parent ký client qua `get_signed_media_url` (có `auth.uid()`); Kid **không `auth.uid()`** (D174) → ký service-side qua Edge → shared-hook (Option A) moot.
- `media_consent_check(p_moment_id, p_viewer_profile, p_action)` = **moment-level** (staff same-school bypass; else PH-của-≥1-bé-tag + approved + MIN-consent view: 1 bé→display_in_app, ≥2 bé→group_moment_in_class). Grants authenticated/postgres/service_role. **Album/cover Kid hiện KHÔNG gọi consent** → "match existing" = thêm mới.
- Kid consent viewer = **PH của chính bé** (`child_parents.parent_profile_id`) → ra đúng quyền hiển-thị-in-app của gia đình. 6/6 moment An pass consent(view) → thêm gate = **0 delta hiển thị**.

---

## 3. C2 — Kiến trúc (CTO chốt Lối 1 + 3 chỉnh sửa)

Brief giả định Kid có galleryItems sẵn, chỉ thiếu wire sign-on-navigate → sai. Fix buộc chạm RPC+Edge. CTO **gỡ chốt "no DB/Edge"** cho pipeline Kid tối thiểu, additive (A+B+C). **3 chỉnh sửa bắt buộc:**
1. **Consent/displayability BẮT BUỘC** — cả album (filter galleryItems/mediaCount theo consent, không lộ ID/đếm media không xem được, không "1/3" giả) và `sign_moment_media` (consent trước signAsset, fail → generic). Vì consent moment-level → cả moment pass hoặc cả fail → không bao giờ "1/3 với item ẩn".
2. **Cả 2 entry point** Kid (`openMoment` + timeline moment) dùng chung `KidMomentLightbox`. Creation/audio giữ riêng.
3. **Xác nhận contract callGate thật:** action+session_token trong **body**; mọi action kid_gate dùng **`ok`** (không `allowed`) → action mới + UI dùng `ok`.

---

## 4. A — Migration (đã áp)

`apply_migration` `v88_enrich_kid_album_gallery_metadata` (D92 3-block: CREATE OR REPLACE → REVOKE PUBLIC/anon/authenticated + GRANT service_role → verify). Chỉ đổi nhánh `'moments'` (mọi nhánh khác byte-identical): `cross join lateral` gom `array_agg(id ORDER BY created_at, id)` + `jsonb_agg({mediaId,fileType,createdAt} ORDER BY created_at, id)`; `media_id`/`coverMediaId` = `arr[1]`, `mediaCount` = `array_length`, `hasGallery` = >1, `galleryItems` metadata-only. **Verify PASS:** hàm deployed (mint session tạm→gọi→dọn): c6=3/f51=2/c7=2/đơn=1, keys `mediaId,fileType,createdAt`, 0 signed_url, cover=item0. Grants service_role/postgres, leaky=false, secdef + search_path='' giữ. **106 definer không đổi** (CREATE OR REPLACE).

---

## 5. B — Edge `kid_gate` v8 (deployed)

**Album consent-filter:** lấy `viewerProfile = child_parents.parent_profile_id` (bé hiện tại); mỗi moment `media_consent_check(moment, viewerProfile, 'view')`; fail → `media_id=null; coverMediaId=null; mediaCount=0; hasGallery=false; galleryItems=[]` (không lộ). Ký cover: moment PASS + tất cả creations (D178 no-consent). **`sign_moment_media(session_token, moment_id, media_id)`:** thứ tự (D219) session → kid_access.enabled → authz moment approved + bé tag (`not_authorized`) → media active + linked_moment_id=moment (`not_found`) → consent (`not_authorized` generic) → `signAsset` → `{ok:true, signed_url}`. **Verify gate PASS** (dựng lại chuỗi SQL cho An): allowed→SIGN (cover + item3) · cross-moment→not_found · deleted→not_found · untagged→not_authorized · draft→not_authorized · random-uuid→not_authorized. Mọi reason generic, 0 rò. `verify_jwt=false` giữ (hàm tự gate). Helper `signAsset`/`sha256hex`/`json` + mọi action khác (pair/login/ping/save_creation/game_items/react/logout) byte-identical.

---

## 6. C — UI `kid.tsx` (frontend-only, 1 file, agent-mode)

Commit `1a5af516`, 4 edit find/replace, get_diff = 1 file (`routeTree.gen.ts` vắng), typecheck pass. (1) `Moment` type +`coverMediaId?/mediaCount?/hasGallery?/galleryItems?` (additive); (2) component Kid-only **`KidMomentLightbox`** (cover seed `signed_url`; `selectItem` ký on-demand `callGate sign_moment_media` + cache theo mediaId + `knownRef` chống re-sign; `safeSelected` clamp; counter `{i+1}/{n}` aria-live + dots; soft loading/error; `galleryItems<=1` → 1 img cover + reactions y cũ); (3) `openMoment` dialog dùng component; (4) timeline moment click → recover Moment từ `album.moments` theo `moment:${moment_id}` → `onOpenMoment` (cùng lightbox); creation/session/badge giữ `openItem` cũ.

**Kid smoke PASS** (PH Hùng `ph.hung.kidshouse@demo.demenart.com`/`Test@123` ghép thiết bị + PIN → `/kid`): album 6 moment (consent pass hết) · **c7fe22f4** 2 ảnh 1→2 (thấy "Đang mở ảnh…" sign-on-navigate → ảnh 2 hiện) · c6fc98e8 3 ảnh cùng path · moment đơn 1 ảnh không dots (y cũ) · creation "Tác phẩm" mở dialog cũ + "Gợi ý trò chuyện" · Network media qua `media.demenart.com`, **0 raw `.b-cdn.net`** · console lỗi = **favicon** (không phải app).

---

## 7. Parent + Teacher regression — PASS

- **Parent** (PH Hùng → `/parent`): summary **6 / 2 / 6** (Tác phẩm 6 · Âm thanh 2 · Khoảnh khắc 6) đúng baseline mới · `/parent/journal` gallery không đổi (ParentJournalLightbox không sửa) · warm copy y cũ. **0 Parent code đụng.**
- **Teacher** (GV Mỹ Linh): PhotoTab grid 2-up + xoá ảnh draft y cũ. **0 Teacher code đụng.**

---

## 8. Non-negotiable giữ nguyên

Parent gallery/home/summary/timeline/warm-copy/badge KHÔNG đụng · `get_child_journal` không đổi (0 signed_url) · consent V72 + badge V73 giữ · `upload_media`/`remove_moment_media_service` không đổi · 0 signed_url RPC/adapter · **0 pre-sign-all, 0 batch-sign** (ký 1 item/lần khi mở/chọn) · 0 raw Bunny URL · 0 hardcode moment ID · /kid namespace reserved (5 portal) · legacy `/teacher/moments`+`/school/moments` chưa retire (V88 không đụng) · orphan draft cleanup không gộp.

---

## 9. Endpoint & backlog sau V88

**Endpoint:** RULES **D220** · SYSTEM_MAP **v0.81** · Handoff **v88**.

**Backlog:**
- 🟠 re-sync project library (RULES D220 + SYSTEM_MAP v0.81 + HANDOFF v88).
- 🟠 lưu repo V88 (1 mig `get_kid_album_service` + Edge `kid_gate` v8 + `kid.tsx`, dump trung thực D90).
- ✅ **Kid gallery ảnh-thứ-2 — ĐÓNG** (đã fix qua pipeline Kid: RPC enrich + Edge sign-on-navigate + UI lightbox).
- 🟢 **Kid/Parent shared gallery** (deferred có chủ đích V88): hai bề mặt khác mô hình ký (Parent client / Kid Edge) → chưa trích hook chung; chỉ trích nếu tương lai có logic thật trùng.
- 🟢 **retire `/teacher/moments`+`/school/moments`** (MomentsView legacy v13; governance gap gắn ảnh vào moment approved không guard; gỡ nav+redirect/xoá sau audit link).
- 🟡 **purge orphan draft moment** (0 active media + 0 tag sau xoá ảnh cuối; inert).
- 🟠 (theo dõi) **consent-filter album Kid** giờ ẩn moment fail consent — với data khác An có thể giảm số moment Kid thấy (đúng, privacy-correct); document khi pilot mở rộng.
- 🟠 (nợ taxonomy) `upload_media` nhánh A không set `source` (mig068).
- 🟠 (hoãn) filter chip / month-jump nav (D216) · timeline affordance "X ảnh" · migration `cover_media_id`/`sort_order` (giờ có `galleryItems` ASC deterministic, ít cần hơn) · Edge batch-sign (KHÔNG, vi phạm ký-on-demand).
- Nợ cũ: Parent Dashboard/Radar/AI Review THẬT · Phương án B RPC `get_child_journey_service` · rename `kidJourneyModel.ts` · enrichment `child_journey` · Coloring schema · Moment media taxonomy.

---

## 10. Rollback plan (V88)

- **A (DB):** `apply_migration` REVERT = CREATE OR REPLACE `get_kid_album_service` về thân cũ (dump verbatim đã lưu ở audit — nhánh moments trả 1 `media_id` scalar, không galleryItems) + re-grant service_role. Data 0 đụng.
- **B (Edge):** deploy lại `kid_gate` v6 (source cũ dump verbatim) — bỏ action + bỏ consent-filter. Action mới additive → client cũ không vỡ dù lệch pha.
- **C (UI):** revert commit `1a5af516` (Lovable History/`get_diff`) — single-media path = hành vi cũ.

---

## 11. Demo accounts

(`@demo.demenart.com` · `Test@123`): **PH KHM `ph.hung.kidshouse`** (bé An — ghép thiết bị `/parent/kid` + PIN để vào `/kid`) · Master KHM `hieutruong.kidshouse` · **GV KHM `gv.linh.kidshouse`** · GV KHM `gv.my.kidshouse` (temp) · PH KHM `ph.toan.kidshouse` (temp) · Master MNDM `hieutruong.demen` · GV MNDM `gv.han.demen` · PH MNDM `ph.thanh.demen`.
