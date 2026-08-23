# DMA_HANDOFF_v97.md — ART DISCOVERY CAPSULE d1 (ENGINE ĐÓNG)

> **Đọc cùng:** DMA_RULES.md (tới **D234**) · DMA_SYSTEM_MAP.md (**v0.90**). Boot phiên sau: đọc 3 file này từ disk, KHÔNG từ trí nhớ (D1/D112/D116).

## 1. Canonical endpoint sau V97
- RULES **D234** · SYSTEM_MAP **v0.90** · Handoff **v97**
- Inventory live: **69 tables · 125 SECURITY DEFINER · 155 policies · 1 cron**
- Baselines: An **6/2/6** · evidence **22/16** (DC8/OBS8/PART6/REF0/ACH0) · readiness **policy v2** · emerging · contemporaneous · gen 3m ✗ [too_short_duration, insufficient_longitudinal_spread] · Jimmy 1/insufficient · `discovery_capsules` **0 rows**
- Leak grants (PUBLIC/anon/authenticated trên derive/compute/builder): **0**

## 2. V97 đã làm (theo thứ tự, tất cả live-verified)
1. **V97A C1:** canonical 0-drift · live khớp expected từng số.
2. **Validation debt gate 5/5 PASS** (fixture A/C/E/F/G, synthetic child riêng `f9…`, cleanup scope-guard 0 residue):
   - **A** phát hiện semantic mismatch → STOP 1 lần → CTO chốt tách code → migration **`v97a1_gap_code_insufficient_collection_continuity_policy_v2`** (gap code thứ 9, **policy_version v1→v2**, threshold không đổi, An codes không đổi) → rerun A PASS.
   - **C** longitudinal_observed nhưng không mở gì (attendance ≠ depth) · **E** anti-backdate qua DC, 2 code đúng tầng · **F** music 3m+6m eligible / gen chỉ ✗ narrow_domain · **G** insufficient.
3. **V97B + addendum (CTO duyệt đủ):** taxonomy d1 · exact pattern key domain×family · convergence ≥2 HUMAN prov same-key (system = supporting only) · claim strength 4 codes · Option C snapshot · Parent-only · window_code stable client-side, as_of server-side · daily idempotency expression-index · candidate≠item, precedence + trần 6/2 · overlay = full re-validation qua CHUNG builder (tier-compare) · canonical payload hash loại uuid/timestamps/request metadata.
4. **Preflight consent → Case B (D233):** derive KHÔNG phản ánh consent (test atomic An 6→6→6, restore verified). Filter MIN-consent cho learning_moment đặt trong builder; V95/V96 semantics/counts KHÔNG đổi.
5. **Migration `v97c_discovery_capsule_engine_d1`** (D92 3-block, apply pass lần đầu, VERIFY 8 guards): 2 bảng deny-all + 4 functions + hardening D15/D231.
6. **Acceptance 10/10** (chi tiết SYSTEM_MAP §V97): not_eligible codes · cross-family generic · fixture H convergence thật `{parent:3, teacher:2}` · idempotent · hash reproducible · Consent Support Test suppressed↔valid · degradation suppressed (không silently downgrade) · cleanup 0 residue · regression full.

## 3. RPC contracts (cho V97D)
- `generate_discovery_capsule(p_child_id, p_scope 'general'|'domain', p_window_code, p_domain?)` → `{ok:false, reason:'not_eligible', failed:[codes]}` hoặc `{ok:true, capsule:{…items[]}}`. Lỗi authorize → exception `not_authorized` generic. Cùng ngày → trả capsule cũ.
- `get_discovery_capsule(p_capsule_id)` → capsule + items; mỗi item `{status:'valid', taxonomy_code, pattern_key, claim_strength, support}` hoặc `{status:'suppressed'}` (KHÔNG kèm gì khác — UI render copy trung tính cố định).
- `list_discovery_capsules(p_child_id)` → headers desc created_at.
- Render notes: convergence copy liệt kê human prov từ `support.human_prov_groups` (không hard-code) · claim budget copy theo claim_strength (descriptive="đã ghi nhận" · repeated="xuất hiện ở nhiều thời điểm/một mẫu đang dần hiện rõ" · multi_source="cả {provs} đều đã ghi nhận") · pattern_key `domain×family` · language guard D234/§17 prompt V97 bake vào template.

## 4. Lệnh CTO còn hiệu lực / ranh giới
- **CHƯA làm UI** (V97D cần GO riêng) · KHÔNG AI/LLM ở d1 · KHÔNG teacher/admin/kid access · KHÔNG score/rank/talent/percentile · suppression không leak source history.
- Đổi taxonomy/floor/precedence = migration + bump `discovery_version` d2 (mirror D230).

## 5. Nợ mở (ưu tiên đầu phiên sau)
- 🟠 **V97D Parent UX** "Bản Khám Phá Nghệ Thuật" (chờ GO + thiết kế content/claim-budget copy).
- 🟠 **Lưu repo** migrations v97a1 + v97c (D90 — dump từ live).
- 🟠 Re-sync library: RULES D232–D234 · SYSTEM_MAP v0.90 · Handoff v97.
- 🟡 V97.2: change_over_time (chờ longitudinal data thật) · sparse/NULL-domain coverage section · AI language polish (quyết định riêng) · multi-domain "cùng ghi nhận về domain" = taxonomy code mới nếu product cần, KHÔNG nới convergence.
- 🟡 Nợ V96: V96D UI readiness · fixture nợ cũ. Nợ V95: Badge Provenance · Spine ref_id Backfill · child_skills refactor. Nợ V94/cũ: giữ nguyên danh sách Handoff v96.

## 6. Rollback V97
- Engine: `DROP FUNCTION generate/get/list_discovery_capsules, build_discovery_candidates_internal; DROP TABLE discovery_capsule_items, discovery_capsules;` → 67/121/155/1.
- Policy v2 GIỮ (semantic fix độc lập, đã có fixture chứng minh); nếu buộc về v1: re-apply body v96c2 từ repo (sau khi lưu D90).
