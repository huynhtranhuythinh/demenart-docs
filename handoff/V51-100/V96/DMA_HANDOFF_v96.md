# DMA_HANDOFF_v96.md — V96: ART EVIDENCE READINESS ENGINE / "Khi nào dữ liệu đủ để bắt đầu Bản Khám Phá?"

> **ĐÓNG 2026-07-11 GMT+7.**
> Endpoint: RULES **D231** · SYSTEM_MAP **v0.89** · Handoff **v96**.
> **Baseline:** An **6/2/6** (summary không đổi) · An evidence **22/16** (DC 8 · OBS 8 · PART 6 · REF 0 · ACH 0) · Inventory **67 tables · 121 definer · 155 policies · 1 cron**.
> **⭐ V96 READINESS BASELINE (mới):** An = **`emerging` · `contemporaneous` · policy_version `v1`** — general current_3m NOT eligible, failed = `[too_short_duration, insufficient_longitudinal_spread]`.
> Sprint: **2 migration** (+3 function, REPLACE 1 → 118→121) · **0 bảng mới · 0 policy đổi · 0 Edge · 0 frontend · 0 deploy** (backend-only; V96D UI CHƯA duyệt).

---

## 1. Mục tiêu

Pipeline **Evidence (V95) → Readiness (V96) → Discovery Capsule (V97)**. V96 KHÔNG trả lời "con có năng khiếu gì?" — chỉ trả lời *"dữ liệu hiện tại đã đủ lâu, đủ rộng, đủ đa dạng và đủ độc lập để bắt đầu một Bản Khám Phá chưa?"*. **Readiness là thuộc tính của DATASET, không phải của trẻ (D230)** — guardrail tuyệt đối: không score/rank/so sánh/chẩn đoán/dự đoán/AI report/Capsule thật/unlock gamification/percent/dark pattern.

**Tiêu chí thành công (CTO):** engine tính readiness đúng policy đã duyệt, authorize đúng boundary, reproducible, anti-gaming chứng minh live → **ĐẠT** (acceptance PASS, Scenario B synthetic chứng minh).

---

## 2. V96A — Canonical + Live Audit (CTO PASS có điều kiện)

- Endpoint vào: RULES **D228** · SYSTEM_MAP **v0.88** · Handoff **v95** — **0 drift**. Inventory vào **67/118/155/1** · An 6/2/6 · An evidence recompute live khớp 22/16.
- ⚠️ Ghi chú nhỏ (không phải drift): group `session:a0001` = **7 rows** (1 part + 1 obs + 5 moments), handoff v95 ghi "6" — totals 22/16 khớp tuyệt đối, sai lệch mô tả thành phần; 2 moment created 10/7 gắn buổi 28/6.
- **Cohort 8 children:** An (22/16, rich, 4 prov, 4 domain) · Bình/Chi (**5 rows = 1 group** — bằng chứng sống raw-count phóng đại coverage, group basis bắt buộc) · Jenny (4, có badge) · Hà/Khang/Phúc (3, sparse school-only) · Jimmy (1). **Limitation khai báo:** cohort KHÔNG có shape parent-memory-heavy và KHÔNG có longitudinal thật (max span 21d) → threshold 6m/12m = product-policy assumption chưa validated.
- **Backfill live:** An pmem cả 3 active nhập cùng 1 ngày (11/7), backdate 3–5d — mini-case thật của vấn đề backdate; An tổng max lag 7d → retrospective_entry_ratio = 0.

## 3. V96B — Policy Design + CTO Decisions V96-01→11

- **V96-01:** two-layer APPROVED — `dataset_maturity` + `collection_profile` + `eligibility` (general/domain-specific × current windows) + `gaps`.
- **V96-02:** tách historical coverage (occurred_at) ≠ collection continuity (created_at) ≠ maturity; created_at = integrity signal, không phủ nhận giá trị archive.
- **V96-03:** current windows kết thúc tại `as_of` — KHÔNG best-rolling-window (chống cherry-pick); historical Capsule tương lai phải dùng explicit window_start/window_end.
- **V96-04:** Option C approved — internal compute + public RPC.
- **V96-05:** gap codes context-aware (not_applicable/info/blocking theo scope).
- **V96-06:** retrospective ratio = descriptor, KHÔNG global veto cho longitudinal_observed — thay bằng **near-time stream** `near_time_active_created_months ≥4` (rows lag ≤7d; metric MONOTONIC → archive không phá stream thật).
- **V96-07:** terminology `retrospective_entry_count/ratio` + `high_retrospective_concentration` (không "backfill").
- **V96-08:** `largest_group_share` = diagnostic, không gate.
- **V96-09:** **8 gap codes v1:** too_short_duration · too_few_independent_events · low_direct_evidence · **low_evidence_class_diversity** · single_source_bias · narrow_domain_coverage · high_retrospective_concentration · insufficient_longitudinal_spread.
- **V96-10:** reproducibility `created_at <= as_of AND occurred_at < as_of`.
- **V96-11:** elapsed-span floors bắt buộc bên cạnh active-months: **45/100/210d** cho 3m/6m/12m (boundary 31/1+1/2 = 2 months nhưng span 1d phải fail — sanity pass live xác nhận An span 21d fail 3m đúng trực giác).
- **near_time = lag ≤7d** đúc từ hành vi live: system ingestion 1d · teacher 0–2d · parent An 3–5d (sự kiện cuối tuần upload tuần sau) — delayed ingestion hợp pháp không phải gaming.
- **Threshold general** (span/months/weeks/groups/DC-groups/core/prov/domains/continuity): 3m = 45d/2/5/8/3/2/2/2/2 · 6m = 100d/4/8/14/5/2/2/2/3 · 12m = 210d/7/14/24/8/3(=3/3 core)/3/2/5. **Domain-specific:** groups 6/10/18 · DC∪PART 3/5/8 · core ≥2 · KHÔNG provenance/breadth gate (single_source_bias chỉ info; narrow_domain_coverage not_applicable). Maturity: insufficient <6g · emerging ≥6g/≥1m · established ≥12g/≥3m/span≥60d · longitudinal_observed ≥20g/≥6m/span≥150d/nt≥4.
- Versioning: `policy_version='v1'` hằng trong function; đổi policy = migration mới + bump; KHÔNG config table mutable, KHÔNG versioned function names.

## 4. DB — 2 migration (đã apply, D92 3-block)

- **`v96c1_shared_evidence_derivation` (C-1):** CREATE `derive_child_evidence_internal(p_child_id)` — canonical UNION 7 nhánh V95 nguyên vẹn, SECURITY DEFINER `search_path=''`, RETURNS TABLE, KHÔNG authorize, **service_role only** (D229) + CREATE OR REPLACE `get_child_evidence` thành authorize→derive, contract V95 giữ nguyên. **STOP GATE PASS:** payload An **md5 byte-identical pre/post** (`5af5…a8c0`) · 22/16 · DC8/OBS8/PART6 · An 6/2/6 · cross-family PH Hùng→bé Hà (MNDM) `not_authorized` dòng 5 · grants get_child_evidence unchanged (authenticated+service_role+postgres) · PUBLIC/anon leak = 0 · inventory 67/119/155/1.
- **`v96c2_readiness_engine` (C-2):** CREATE `compute_child_evidence_readiness(p_child_id, p_as_of DEFAULT now())` — policy v1 toàn bộ trong 1 function (metrics HCM-tz bucketing, 3 windows VALUES-driven, general + per-domain eval, 8 gap codes, info gaps dataset-level), service_role only + CREATE `get_child_evidence_readiness(p_child_id, p_as_of DEFAULT NULL)` — mirror gate `is_child_parent` → generic `not_authorized`, grants authenticated+service_role. VERIFY: 121 definer · leak 0 · smoke An emerging/22/16/v1. Inventory **67/121/155/1**.
- **⭐ Phát hiện D231:** lần apply c1 đầu tiên bị VERIFY guard chặn — **Supabase `ALTER DEFAULT PRIVILEGES` tự grant EXECUTE cho anon+authenticated+service_role trên mọi function MỚI**, `REVOKE FROM PUBLIC` không gỡ được (explicit grants). Fix: `REVOKE ALL ... FROM PUBLIC, anon, authenticated` tường minh + VERIFY audit cả anon/authenticated. Transaction rollback sạch — D92 chứng minh giá trị lần nữa. Debug pattern: DO-block tạo hàm tạm + RAISE EXCEPTION mang acl trong message → tự rollback, zero footprint.

## 5. ⭐ V96 READINESS BASELINE + ACCEPTANCE (live)

| Test | Kết quả |
|---|---|
| **An** (JWT PH Hùng) | `emerging` · `contemporaneous` · v1 · 22/16 · retrospective_entry_ratio **0** · nt_cre_months 2 · largest_group_share 0.318 · occ HCM 10d/4w/2m · gen current_3m ✗ `[too_short_duration, insufficient_longitudinal_spread]` · 6m/12m ✗ (+groups/continuity) · domain music/visual_art/dance/theatre đều ✗ đúng floors |
| **as_of = 25/6** | 0 evidence → `insufficient`. **Semantics quan trọng:** có event occurred trước 25/6 (min occurred 19/6) NHƯNG 0 evidence thỏa `created_at <= as_of` (min created 26/6) — **hệ thống CHƯA BIẾT các evidence đó tại thời điểm evaluation**; đây là hành vi ĐÚNG của V96-10, không phải bug |
| **Bình** | `insufficient` + `too_few_independent_events` (5 rows/1 group — group basis chứng minh) = Scenario D live |
| **Jenny** | `insufficient` |
| **Cross-family** (cả 2 RPC) | generic `not_authorized`, zero payload — không leak child existence |
| **Scenario B synthetic** (Jimmy + 20 memories backdate 12 tháng, replica seed) | 21 groups · 13 occ-months · 363d span → **`established` + `retrospective` (ratio 0.952), KHÔNG `longitudinal_observed`** (nt_cre_months 1<4) · gen 12m ✗ high_retrospective_concentration — anti-gaming V96-06 chứng minh live. Cleanup: 0 test rows sót · Jimmy về baseline (1, insufficient) · An 22/16 nguyên vẹn |

## 6. Rollback

`DROP FUNCTION public.get_child_evidence_readiness(uuid,timestamptz);` + `DROP FUNCTION public.compute_child_evidence_readiness(uuid,timestamptz);` → CREATE OR REPLACE `get_child_evidence` body V95 (repo migration v95 — dump trung thực D90) + re-grant D15 → `DROP FUNCTION public.derive_child_evidence_internal(uuid);` → **67/118/155/1**. Không Edge/frontend để revert.

## 7. 🔴 VALIDATION DEBT GATE (bắt buộc trước V97)

Fixture synthetic **A / C / E / F / G** chưa chạy (B + D đã chứng minh live):
- A — 80 evidence/10 ngày · C — 20 school sessions thật/6 tháng · E — 12 artworks upload 1 ngày occurred 4 tháng · F — 6 tháng music sâu đều · G — 4 domains × 1 event.
- **GATE:** hoàn tất TRƯỚC khi V97 mở production Capsule generation.
- **Riêng fixture F BẮT BUỘC trước domain-specific Capsule thật** (chứng minh trẻ chuyên sâu 1 domain qualify domain-specific dù fail general).

## 8. Backlog sau V96

- 🟡 **(mới) V96D Parent UI** "Hành trình đang dần rõ hơn" — CHƯA duyệt; nếu làm: cấm unlock meter/countdown/percent, copy chỉ nói dataset/coverage/time (language guard D230)
- 🟡 **(mới) V97 Art Discovery Capsule** — chỉ sau VALIDATION DEBT GATE mục 7
- 🟡 V95E "Dữ liệu hành trình của con" (optional, chưa duyệt)
- 🟡 Badge Journey Provenance Alignment · 🟡 Spine Session ref_id Backfill (3 row legacy) · 🟡 child_skills refactor code-based (D227)
- Nợ V94 giữ: 🟠 re-sync library (nay D231+v0.89+v96) · 🟠 lưu repo V94+V95+**V96 (2 mig v96c1/v96c2)** · 🔴 Media Compatibility Pipeline · 🟡 sweep pending_attach>24h · Archived Memories UI · video poster server-side · V93C Kid reply · V93D notification · Unified Journey Summary · fixture nợ V93
- Nợ cũ: Portal header chung · Kid adaptation · Context Navigator · pinch/pan fullscreen · Bunny orphan b2ce6685 · lifecycle purge · upload_media source mig068 · consent-filter Kid · filter/month-nav · cover_media_id/sort_order · Parent Dashboard/Radar/AI Review · Coloring schema · Moment media taxonomy

## 9. Boot phiên sau (V96D hoặc V97 hoặc fixture sprint)

1. Đọc `DMA_HANDOFF_v96.md` → `DMA_RULES.md` (tới **D231**) → `DMA_SYSTEM_MAP.md` (**v0.89**) từ disk.
2. C1: verify **67/121/155/1** · An 6/2/6 · An evidence 22/16 (JWT PH Hùng `eb94304a-8451-44d7-88a7-fe9e26ab0b1c`) · **An readiness `emerging`/`contemporaneous`/v1** (gọi `get_child_evidence_readiness`) · grants derive/compute KHÔNG authenticated/anon.
3. Nếu V97: KIỂM TRA VALIDATION DEBT GATE mục 7 trước — chưa xong fixture thì chạy fixture sprint trước, KHÔNG viết Capsule generation.
