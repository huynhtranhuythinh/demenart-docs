# 🤝 DMA_HANDOFF_v23.md — BÀN GIAO PHIÊN (REVOKE SHARE LINK — ĐÓNG VÒNG ĐỜI D87 — 2026-06-27 20:22 GMT+7)

> **Cách dùng:** File này = ảnh chụp trạng thái cuối phiên v23. Boot phiên sau:
> `00_START_HERE` → `RULES` → file này. Rồi audit DB/code thật trước khi viết.
> **Naming:** DMA = nền tảng; CTAN = sản phẩm đầu. Không "DMMA".

---

## 1. LÀM GÌ PHIÊN NÀY

**Ngã A (đề xuất v22 §7) — `revoke_share_link` + UI.** Đóng nốt việc treo **D87 từ v17**: share link trước chỉ tự-chết qua expiry / rút-consent; **chưa có nút thu hồi tay**. Phiên này thêm nút thu hồi + vòng đời UI đầy đủ. **Cộng thêm 1 slice phát sinh:** vá khe UX consent↔share mà chính phép thử phơi ra.

- **A — RPC + UI thu hồi (mig 044, D94):** `revoke_share_link(p_token)` secdef creator-only + idempotent + audit; UI `journal.tsx` đọc-thẳng `share_links` (creator-only) hiện link active + nút **Thu hồi**.
- **B — Vá bug v17:** bản cũ tạo link MỖI lần bấm "Chia sẻ" → đẻ row `share_links` spam. Đổi **fetch-first, create-on-demand**.
- **C — Cầu UX consent↔share:** share bị chặn `consent_missing` → hiện Link **"Quản lý quyền đồng ý →"** trỏ `/portal/consent` (PH tự bật rồi quay lại); `school_blocks_share` → KHÔNG hiện (khung trường, PH không tự mở).

---

## 2. TRẠNG THÁI THẬT CUỐI PHIÊN

- **DB cấu trúc:** **46 bảng · 50 hàm SECURITY DEFINER · 125 RLS policy · mig 001→044 · seed 001→012.** SYSTEM_MAP **v0.23.**
  - +1 hàm v23: `revoke_share_link` (grant authenticated, creator-only, idempotent).
  - mig 044 **KHÔNG thêm bảng/cột/enum/policy** — chỉ 1 RPC. `share_links` đủ cột từ mig 006. 125 policy KHÔNG đổi.
- **Edge Functions (6 — KHÔNG đổi):** `get_signed_media_url` · `upload_media` · `resolve_share_link` · `invite_master` · `invite_staff` · `invite_parent`. (Edge `resolve_share_link` ĐÃ kiểm `revoked_at` từ D87 → KHÔNG đụng phiên này.)
- **Routes app:** `journal.tsx` (`/portal/journal`) cập nhật — `ShareMomentButton` vòng đời đầy đủ (đọc share_links creator-only → Copy/Thu hồi → cầu consent). **Auto-synced Lovable→GitHub** (không lưu tay).
- **3 tenant / 3 master sạch** (DEMO-001 · KHM-DN · MNDM-DN).

> ⚠️ **Data state ĐỔI phiên này** (bẫy cho phiên sau): consent An `private_share_link` (`d1…e1`) đổi từ **WITHDRAWN → GRANTED** (bật lại để test, để vậy) **+** download consent An cũng bật (toggle trong test cầu-consent). Có thể còn vài `share_links` test cho moment An (1 đã thu hồi `revoked_at`, 1 active từ ảnh 4) — vô hại (creator-only, consent-gated khi resolve, tự hết hạn 24h).

---

## 3. mig 044 — revoke_share_link (D94)

**`revoke_share_link(p_token text) → jsonb`** (secdef, grant authenticated):
- Gate **creator-only**: `created_by_profile_id = current_profile()` (gương Fork 3A D55). Sai chủ → audit `share_link_revoke_denied` + `{ok:false,reason:'not_authorized'}`.
- **Idempotent**: `revoked_at` đã set → no-op trả `{ok:true,reason:'already_revoked'}` (KHÔNG ghi đè).
- Set `revoked_at = now()` → audit `share_link_revoked` (actor=**profile-id** D88, qua `write_audit_log` D72).
- **KHÔNG trigger trên `share_links`** (audit D1) → secdef bypass RLS đủ, **KHÔNG cần replica** (khác D30/D85/D89).
- Trả verdict `{ok,reason,...}` **KHÔNG `raise`** → gọi ở SQL Editor cũng chỉ trả `not_authenticated`, KHÔNG kéo rollback (khác hàm-raise D92).

**⭐ Bài học hạ tầng lặp lại (D92 sống tiếp):** dù hàm KHÔNG raise (an toàn rollback), **vẫn chạy 3 khối RIÊNG** — CREATE / HARDEN (`REVOKE … FROM public; REVOKE … FROM anon; GRANT … authenticated`) / VERIFY (soi `proacl`, KHÔNG gọi hàm) — để né bẫy leaky-grant của `CREATE OR REPLACE`. Verify ĐẠT: `fn_exists=true · grantees=[authenticated,postgres,service_role] · leaky=[]`.

---

## 4. UI vòng đời `journal.tsx` (D94)

**`ShareMomentButton` viết lại** (vẫn full paste-over D5):
- **Đọc THẲNG `share_links`** — SELECT policy creator-only (D55) → client PH `from('share_links').select('id,token,expires_at').eq('scope_type','moment').eq('scope_ref_id',momentId).is('revoked_at',null).gt('expires_at',now)` lấy link active của chính mình. **KHÔNG cần RPC list** (khác `get_child_parents` D92: `share_links` CÓ SELECT cho creator; `profiles` KHÔNG có cho PH).
- Mở popover → fetch active → mỗi link **Copy + Thu hồi**; revoke gọi RPC → refetch. Chưa có link → nút "Tạo link chia sẻ"; đã có → "Tạo link mới".
- **⭐ Vá bug v17:** bản cũ gọi `create_private_share_link` MỖI lần bấm → đẻ row spam → đổi **fetch-first, create-on-demand**.
- **⭐ Cầu UX consent↔share:** lưu `errorReason`; nếu `consent_missing` → hiện `<Link to="/portal/consent">` "Quản lý quyền đồng ý →" (nav client-side, không reload); `school_blocks_share` → KHÔNG hiện (PH không tự mở khung trường).

---

## 5. NGHIỆM THU LOGIN THẬT (D2/D3) — PH Nguyễn Văn Hùng (KHM, `ph.hung.kidshouse@demo.demenart.com`)

**Trọn vòng share link (ĐẠT):**
1. **Tạo** — popover empty → "Tạo link chia sẻ" → link `/share/{token}` + Copy + Thu hồi hiện. ✅
2. **Resolve** — tab ẩn danh `/share/e577…` → ảnh hiện, caption trung tính "Khoảnh khắc được chia sẻ riêng tư từ DMA", **KHÔNG tên/caption/trường** (data-minimization). ✅
3. **Thu hồi** — bấm "Thu hồi" → link biến khỏi danh sách. ✅
4. **⭐ Tự chết** — reload tab ẩn danh → **`403 "Link chia sẻ đã bị thu hồi"`** (Edge re-check `revoked_at`) — *link chết dù chưa hết hạn; PH cầm quyền tắt.* ✅

**Cầu UX consent↔share (ĐẠT):**
1. Tắt consent share An → "Chia sẻ" → "Tạo link chia sẻ" → **"Bạn cần đồng ý…" + Link "Quản lý quyền đồng ý →"**. ✅
2. Bấm Link → nhảy `/portal/consent` **không reload**. ✅
3. Bật toggle "Cho phép tạo liên kết chia sẻ riêng tư" → toast **"Đã cập nhật"**. ✅
4. Quay lại journal → tạo link → ảnh hiện ở tab ẩn danh. ✅

> **Engine v3–v14 + 8 cụm RLS KHÔNG sửa 1 dòng.** `share_links` KHÔNG mig cột.

---

## 6. FILE REPO PHIÊN NÀY (đặt cạnh 001–043)

- `044_revoke_share_link.sql` — 1 RPC (gồm 3 khối CREATE/HARDEN/VERIFY + ghi chú D92). **CHƯA lưu repo** (nợ mới — lưu tay).
- `journal.tsx` — **auto-synced** Lovable→GitHub (không lưu tay).

> Migration SQL chạy tay → phải lưu tay. Code Lovable auto-publish. Edge Function phải copy `.ts` lưu tay.

---

## 7. VIỆC TREO (ưu tiên giảm dần)

1. 🔴 **Lưu repo:** Edge `invite_staff.ts` + `invite_parent.ts` (nợ v22) **+** `044_revoke_share_link.sql` (nợ v23). Dump trung thực từ live (D90).
2. **GV/PH còn lại chưa login** (4 GV + 9 PH) → mời nốt qua app khi cần (engine D93 đủ).
3. **2 file curriculum media chưa có nguồn lưu** (`media_curric`=2).
4. **Vercel project dormant** xóa được.
5. **`seed_007` repo** — body_template "Bé " thừa (đã UPDATE live, chỉ lệch file repo).
6. (Tuỳ chọn) dọn `share_links` test của moment An + reset consent An về baseline nếu muốn — KHÔNG bắt buộc (vô hại, tự hết hạn).

> ✅ **Đã gạch:** `revoke_share_link` + UI vòng đời (đóng D87 v17) · vá bug đẻ-row-mỗi-lần-bấm · cầu UX consent↔share.

---

## 8. NGÃ KẾ — ĐỀ XUẤT

- **⭐ A — Tách 4 portal** (Admin · School · Teacher · Parent). Hiện gộp 1 `/portal`; RLS scope đã đúng tầng DB → thuần UI/IA (đã dọn 1 nửa ở v21 khi gom 3 màn admin về `_authenticated`). Slice lớn hơn nhưng là bước IA còn lại lớn nhất.
- **B — Dọn nợ repo** (lưu 2 Edge `.ts` v22 + `044` v23 + nợ cũ; phiên hạ tầng thuần, dump trung thực D90).
- **C — Mời nốt GV/PH pilot** qua app (engine D93 đủ) — chỉ thao tác vận hành, ít code.

**Boot phiên sau:** đọc HANDOFF v23 → audit live (D1) thật trước khi viết.

---

## 9. DATA STATE CẦN NHỚ (bẫy cho phiên sau)

- **KHM-DN `sharing_mode=private_share_link`** (KHÔNG phải `no_external_sharing`).
- **⚠️ Consent An `private_share_link` (`d1…e1`) phiên này đổi WITHDRAWN→GRANTED** (`withdrawn_at=null`). + **download consent An bật** (toggle test cầu-consent). *(Khác snapshot v22 ghi WITHDRAWN.)*
- **3 tenant / 3 master** (DEMO-001 1lớp/2trẻ · KHM 2/8 · MNDM 2/6 = 5 lớp/16 trẻ).
- **PH 051 mỗi trường = 2-con-xuyên-lớp** (persona multi-child, xuyên-lớp CÙNG-trường — KHÔNG xuyên-trường).
- **2 login giữ từ v22:** GV Lê Thảo My + PH Trần Quốc Toản.
- **`link_role` lưu CODE** `mother`/`father`/`guardian`; legacy seed = `primary`/`secondary` (UI render cả hai).
- **`master_admin` ∈ `is_school_admin()`**; PH `school_id=NULL` cần RPC curated cho ghi (D29) lẫn đọc (D92).
- **Engine media-nhạy-cảm = 5 gate secdef nhận-tham-số:** consent ảnh trẻ (D71) · entitlement học liệu (D75) · upload (D77) · share (D87) · **revoke (D94)**. Edge điều phối+ký+audit; re-check tại-thời-điểm-xem cho thứ thu hồi được.

---

> **KỶ LUẬT VÀNG:** đã cập nhật RULES (+D94, footer v23) + SYSTEM_MAP (dòng nghiệm thu v23, bump v0.23, hàm 49→50, mig→044, +mig 044 sổ migration, +revoke note cụm Privacy + route journal) trong phiên này. 3 file xuất kèm: `DMA_HANDOFF_v23.md` · `DMA_RULES.md` · `DMA_SYSTEM_MAP.md`. **File SQL repo:** `044_revoke_share_link.sql`. **Tài liệu A–G, START_HERE, BUILD_PATH, DMWS_REFERENCE: KHÔNG đổi.**
