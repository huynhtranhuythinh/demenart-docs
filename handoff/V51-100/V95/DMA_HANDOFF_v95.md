# DMA_HANDOFF_v95.md — V95: ART EVIDENCE FRAMEWORK / "Khung Bằng Chứng Phát Triển Nghệ Thuật"

> **ĐÓNG 2026-07-11 GMT+7.**
> Endpoint: RULES **D228** · SYSTEM_MAP **v0.88** · Handoff **v95**.
> **Baseline:** An **6/2/6** (summary không đổi) · Inventory **67 tables · 118 definer · 155 policies · 1 cron**.
> **⭐ V95 EVIDENCE BASELINE (mới):** An **22 events · 16 group** — direct_creation 8 · observation 8 · participation 6 · reflection 0 · achievement 0.
> Sprint: **2 migration** (+1 cột, +1 RPC, link 4 rows skill_catalog, patch NULL-ref) · **0 bảng mới · 0 policy đổi · 0 Edge · 0 frontend · 0 deploy** (backend-only).

---

## 1. Mục tiêu

Xây tầng **EVIDENCE trước JUDGMENT**: hệ thống trả lời được *"Có bằng chứng THẬT nào về hành trình nghệ thuật của bé?"* trước khi (V96/V97) hỏi *"Bằng chứng gợi ý gì?"*. Mọi insight tương lai (Art Discovery Capsule) phải truy vết được về event/creation/observation/memory thật — no black-box, no fake certainty.

**Tiêu chí thành công (CTO):** thiết lập V95 evidence baseline từ dữ liệu live → **ĐẠT** (RPC chạy thật JWT PH Hùng, acceptance 9/9).

**KHÔNG làm trong V95 (ranh giới cứng):** score/rank/so sánh/chẩn đoán trẻ · IQ-like number · "gifted" label · dự đoán career · AI conclusion · báo cáo 3/6/12 tháng · Capsule mechanics · unlock gamification · billing · dark pattern. Cho phép duy nhất: mô tả **DATA COVERAGE** ("hiện có bằng chứng ở 4 lĩnh vực") — không bao giờ mô tả năng lực ("bé yếu về múa" = CẤM).

---

## 2. C1 — Canonical + Live audit (V95A)

- Endpoint vào: RULES **D226** · SYSTEM_MAP **v0.87** · Handoff **v94** — 0 drift. Inventory vào **67/117/155/1** · An 6/2/6.
- ⚠️ **UUID An chính xác:** `d1000000-0000-4000-8000-000000000041` (dạng v4 — handoff cũ ghi tắt `d1000000-…041` dễ đoán sai thành zero-fill; đã verify bằng tên).
- **Bản đồ 9 entity sinh-bằng-chứng:** kid_creations (hẹp: không occurred_at/domain/session-link/state) · learning_moments 7-state · spine session (**đã attendance-gated present/late tại nguồn** `submit_session_journal`) · parent_memories 6 type · child_observations (cấu trúc tốt: skills_observed=code catalog, visibility parent_visible|private_internal — live 1/4) · session_reports (class-level, tín hiệu yếu) · child_badges (1 confirmed, thuộc Bé Jenny) · memory_threads/messages (0/0) · media_assets (**0 row có duration metadata**).
- **Phán quyết `child_skills`:** counter dẫn xuất từ `submit_session_journal` nhưng key theo **`label_vi`** — live có rogue value "Cảm thụ nhịp điệu" ngoài catalog ⇒ **LOẠI khỏi nguồn evidence**, đọc thẳng `child_observations.skills_observed` (code). Không refactor trong V95 (→ D227 + backlog).
- **Phát hiện khung có sẵn nhưng rỗng:** `lesson_versions` có cột `objectives` (live có data VN) + `development_objectives`/`observation_criteria`/`guiding_questions` (**NULL toàn bộ**); `age_groups` band theo tháng per-program. ⇒ DMA không trắng tay framework, nhưng chưa populated — V96 cần research sprint trước khi Capsule scoring, không blind-map framework ngoài thành talent score.
- Nợ phát hiện: spine badge `ref_id=NULL` (provenance đứt) · `skill_catalog.program_id` NULL cả 4 (đã fix trong sprint) · 3 spine session legacy `ref_id=NULL`.

## 3. C2 — Quyết định CTO

1. **Option B:** minimal migration + **pure derived RPC** — KHÔNG bảng `art_evidence`. Evidence layer = INDEX/interpretation, không bao giờ source of truth (D228).
2. **Ontology 5 class:** direct_creation · participation · observation · reflection · achievement + trực giao: provenance (kid|parent|teacher|system) · media_documented · artistic_domain · occurred_at≠created_at · source_type/source_id · group_key.
3. **Evidence identity deterministic** `source_type:<uuid>` — code không label (D227).
4. **Độc lập:** 1 source event = 1 evidence event; **media KHÔNG nhân số** (5 ảnh trong 1 memory = 1 event).
5. **PM direct chỉ khi media KHỚP LOẠI artifact** (correction #3): artwork+image · audio+audio · performance+video → direct_creation; performance không video/experience → participation; photo_moment/note/artwork-audio thiếu artifact khớp → observation.
6. **Reflection visibility-parity V93 (BLOCKER, correction #2):** message chỉ surface khi keepsake gốc còn visible — moment approved+tagged · creation active-media · journey non-badge của bé · pm exact-pair + active.
7. **Badge:** đọc thẳng `child_badges` confirmed, KHÔNG fabricate spine ref_id → backlog Badge Journey Provenance Alignment.
8. **Domain derivation deterministic, không đoán:** pm→cột riêng · session/obs/moment→program→`programs.artistic_domain` (seed chỉ ctan→music, ballet→dance_movement) · **kid drawing→visual_art** (2a — phân loại chất liệu artifact, không phải suy diễn năng lực) · recording/badge/message→NULL.
9. **Temporal:** occurred_at = cửa sổ lịch sử · created_at = provenance; V96 đo trải theo cả created_at chống fake-longitudinal.
10. **group_key** tương quan tự nhiên qua `session_id`; V95 chỉ emit, dedupe = V96.
11. `memory_messages.author_type` (không phải author_role — correction #1) · VERIFY baseline theo semantics thật: creations+media active, moments approved+≥1 media active (correction #4, pre-check vẫn 6/2/6).

## 4. DB — 2 migration (đã apply, D92 3-block)

- **`v95_art_evidence_foundation`:** +cột `programs.artistic_domain` (CHECK 6 domain) + seed 2 · UPDATE 4 rows skill_catalog→CTAN · CREATE `get_child_evidence(p_child_id, p_from?, p_to?)` SECURITY DEFINER `search_path=''`, **parent-scope ONLY** (`is_child_parent` → generic `not_authorized` dòng 5, authorize-trước-lộ-state), UNION ALL 7 nhánh, filter `[from,to)` occurred_at, payload nhẹ `{counts_by_class, evidence[{evidence_id, evidence_class, provenance, artistic_domain, occurred_at, created_at, source_type, source_id, group_key, media_documented, metadata}]}` — không copy story/media. Grants authenticated+service_role (D182). VERIFY: 67/118/155/1 · seed · skill_catalog link · grants aclexplode + PUBLIC-leak=0 · An 6/2/6 semantics thật.
- **`v95_patch_session_null_ref`:** bug live 3 spine session legacy ref_id NULL → `'session:'||NULL` = NULL id ⇒ `COALESCE(j.ref_id, j.id)` + `metadata.ref_source ∈ {lesson_session, journey_row}` (cả nhánh reflection journey). CREATE OR REPLACE + re-grant (D15). VERIFY strpos prosrc 2 chuỗi + grants.
- Privacy pass trong smoke: 4 obs `private_internal` không lộ · pm archived không surface · cross-family PH Hùng→bé Lam `not_authorized`.

## 5. ⭐ V95 EVIDENCE BASELINE (An, live, JWT PH Hùng `eb94304a-8451-44d7-88a7-fe9e26ab0b1c`)

**22 events · 16 group độc lập · 0 NULL id**

| Class | N | Ghi chú |
|---|---|---|
| direct_creation | 8 | 6 drawing + 2 recording (chưa có pm nào đạt direct — performance thiếu video) |
| observation | 8 | 6 learning_moment + 1 obs parent_visible + 1 pm photo_moment |
| participation | 6 | 4 session (1 lesson_session + 3 `ref_source:'journey_row'`) + 2 pm performance |
| reflection | 0 | threads/messages 0 — đúng |
| achievement | 0 | badge duy nhất thuộc Bé Jenny — đúng chủ, không phải bug |

Domain coverage (DATA, không phải năng lực): music 10 · visual_art 6 · theatre_performance 2 · dance_movement 1 · null 3. Span **19/6→10/7/2026**. Provenance: kid 8 · teacher 7 · system 4 · parent 3. Source: kid_creation 8 · learning_moment 6 · session 4 · parent_memory 3 · observation 1. Session grouping chứng minh: 6 evidence chung `session:aaaa…a0001` = 1 buổi học thật.

**Acceptance CTO 9/9 PASS:** mapping đúng class · media không nhân · private_internal không lộ · archived không surface · badge đúng chủ · session grouping · cross-family denied · summary 6/2/6 giữ · inventory 67/118/155/1.

## 6. Rollback

`DROP FUNCTION public.get_child_evidence(uuid,timestamptz,timestamptz)` + `ALTER TABLE public.programs DROP COLUMN artistic_domain` + `UPDATE public.skill_catalog SET program_id=NULL WHERE code IN ('ctan_rhythm','ctan_sing_along','ctan_move','ctan_listen')` → **67/117/155/1**. Không có Edge/frontend để revert.

## 7. Backlog sau V95

- 🟡 **(mới) V95E "Dữ liệu hành trình của con"** — surface Parent-only đếm trung thực (RPC sẵn; optional, CHƯA duyệt; nếu làm: obs chỉ đếm parent_visible; cấm score/percent/unlock)
- 🟡 **(mới) V96 Readiness Engine** — duration/quantity/diversity/independence/coverage-gap; **tiền đề: research sprint framework phát triển** (UNESCO/arts standards/curriculum nội bộ — `development_objectives`/`observation_criteria` đang rỗng); không single-framework→talent-score
- 🟡 **(mới) Badge Journey Provenance Alignment** (spine badge ref_id NULL — không fabricate)
- 🟡 **(mới) Spine Session ref_id Backfill** (3 row legacy — fallback ref_source đã an toàn)
- 🟡 **(mới) child_skills refactor code-based** (D227 — key label_vi + rogue value)
- Nợ V94 giữ: 🟠 re-sync library (nay D228+v0.88+v95) · 🟠 lưu repo V94+V95 (nay +2 mig V95) · 🔴 Media Compatibility Pipeline · 🟡 sweep pending_attach>24h · Archived Memories UI · video poster server-side · V93C Kid reply · V93D notification · Unified Journey Summary · fixture nợ V93
- Nợ cũ: Portal header chung · **Art Discovery Capsule (nay = V97, sau V96)** · Kid adaptation · Context Navigator · pinch/pan fullscreen · Bunny orphan b2ce6685 · lifecycle purge · upload_media source mig068 · consent-filter Kid · filter/month-nav · cover_media_id/sort_order · Parent Dashboard/Radar/AI Review · Coloring schema · Moment media taxonomy

## 8. Boot phiên sau (V96 hoặc V95E)

1. Đọc `DMA_HANDOFF_v95.md` → `DMA_RULES.md` (tới D228) → `DMA_SYSTEM_MAP.md` (v0.88) từ disk.
2. C1: verify 67/118/155/1 · An 6/2/6 · **V95 evidence baseline 22 events** (gọi `get_child_evidence` JWT PH Hùng — user_id `eb94304a-8451-44d7-88a7-fe9e26ab0b1c`) · seed domain 2 rows · skill_catalog 4 rows linked.
3. Nếu V96: bắt đầu bằng research sprint framework, KHÔNG viết scoring trước khi CTO duyệt khung tham chiếu.
