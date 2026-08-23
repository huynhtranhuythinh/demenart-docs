# DMA_HANDOFF_v98.md — ART DISCOVERY CAPSULE · PARENT EXPERIENCE (ĐÓNG)

> **Đọc cùng:** DMA_RULES.md (tới **D237**) · DMA_SYSTEM_MAP.md (**v0.91**). Boot phiên sau: đọc 3 file này từ disk, KHÔNG từ trí nhớ (D1/D112/D116).

## 1. Canonical endpoint sau V98
- RULES **D237** · SYSTEM_MAP **v0.91** · Handoff **v98**
- Inventory live: **69 tables · 125 SECURITY DEFINER · 155 policies · 1 cron** (KHÔNG đổi so V97)
- Baselines: An **6/2/6** · evidence **22/16** (DC8/OBS8/PART6/REF0/ACH0) · readiness **v2**/emerging/contemporaneous · gen 3m ✗ [too_short_duration, insufficient_longitudinal_spread] · `discovery_capsules`/`items` **0/0** · PH Hùng đúng 2 con An/Khang
- Leak grants pipeline (derive/compute/builder/3 RPC capsule): **0**
- Frontend live: commit `104c184` + hotfix `91c4222`, deploy demenart.com + demenart.lovable.app

## 2. V98 đã làm (tất cả live-verified)
1. **V98A:** canonical 0-drift · **phát hiện + dọn 1 row `discovery_capsule_items` mồ côi** (residue fixture H V97 — replica tắt RI trigger nên CASCADE không chạy, D236) · regression 3 tầng Evidence/Readiness/Capsule khớp từng số · gap registry 9/9 khớp copy matrix · Parent IA audit (nav mobile ẩn `hidden sm:` → cần Home card; journal 2-mode byte-stable → không đụng) · 2 contract gap surface (list không item-count → card không hiện; capsule không coverage → coverage sống ở readiness layer).
2. **V98B PASS có điều kiện + 6 corrections:** not-eligible = exact gap copies max 2 + "…và một vài yếu tố khác trong dữ liệu hiện tại." + anti-pressure (BỎ câu generic thời-gian) · creation_pattern "Những sản phẩm {D} con trực tiếp tạo ra" · convergence support không breakdown nguồn · prompts domain-aware 4 domain · coverage semantics an toàn · language QA theo claim-pattern ("tiềm năng" chỉ trong boundary) · **`discoveryModel.ts` = single frontend source of truth**.
3. **V98C (agent auto-app, get_diff verify scope từng commit):** 5 file MỚI `features/discovery/{discoveryModel.ts,ReadinessPanel.tsx,CapsuleCard.tsx,CapsuleDetail.tsx}` + `routes/_authenticated/parent.discovery.tsx` (`?capsule=` param, D101) · 2 chèn `parent.index.tsx` (Home card static, 0 RPC thêm) + `parent.tsx` (nav Sparkles) · **hotfix qua diff-review:** `human_prov_groups` là OBJECT `{prov:count}` — agent khai `string[]` sẽ crash convergence; `joinProvenances` normalize cả 2 dạng.
4. **V98D fixture (synthetic `f8…` link PH Hùng, thiết kế từ threshold live):** F = 11 parent_memories music (5 `audio`+media→DC · 6 `experience`→participation; 1 human prov → 0 convergence) · H = 3 exp parent + 1 audio + 2 `learning_moments` teacher KHÔNG session (group_key riêng) + consent `display_in_app`. Server 12/12: F 3m+6m eligible `failed=[]` · F capsule đúng 2 items · idempotent same-id · H 1 item convergence `{parent:3,teacher:2}` · degradation ↔ restore · consent withdraw ↔ restore.
5. **UI QA trọn (production demenart.com):** An not-eligible states + anti-pressure + coverage · F list/detail copy byte-đúng · **E2E Generate qua UI** (F 6m) · H convergence "Cả gia đình và giáo viên đều đã ghi nhận hoạt động Âm nhạc…" + support "5 lần ghi nhận độc lập từ nhiều góc nhìn, trải qua 4 tháng" · **all-suppressed shell live** (1 khối, 0 heading rỗng, không downgrade) → restore valid trên UI · mobile 400px. Bug "không bấm được detail" KHÔNG tái hiện trên tab sạch → deploy-lag giữa 2 deploy (D237); verify bằng Claude-in-Chrome.
6. **Cleanup 10/10 scope-guard (D236)** + full regression: f8 residue 0 trên 8 bảng · mọi baseline nguyên.

## 3. Sự cố vận hành trong phiên (đã đóng)
- **D235 — Bunny balance âm (−$2.69)** → toàn bộ `media.demenart.com` chết `ERR_CERT_COMMON_NAME_INVALID` dù panel config xanh. Chuỗi loại trừ: DNS đúng → config đúng → **BILLING**. Nạp tiền → edge resume, 0 code/cert/DNS đổi. Auto-recharge $10 @ $2 đã bật (Visa …4362). Backlog: nâng ngưỡng $5 + review **Bunny Optimizer** ($6.49/$6.78 bill tháng 7 ≈ 96%).

## 4. Footnote backend (KHÔNG vá, chỉ ghi nhận)
- `generate_discovery_capsule` dùng `CREATE TEMP TABLE _sel ON COMMIT DROP` → không gọi 2 lần trong cùng transaction. Production PostgREST (1 call/txn) không ảnh hưởng; chỉ ảnh hưởng test harness gộp câu.

## 5. Render contract tóm tắt (cho phiên sau đụng Discovery UI)
- Mọi label/copy/mapping SỐNG TRONG `src/features/discovery/discoveryModel.ts` — sửa copy = sửa đúng 1 file, cấm duplicate trong components.
- `list_discovery_capsules` KHÔNG trả item-count/suppression → card không được hiện 2 thứ này nếu chưa mở rộng RPC (quyết định CTO #3 V98A).
- Coverage/"vùng dữ liệu còn ít" thuộc readiness layer (màn list), KHÔNG nằm trong capsule detail (immutable snapshot).
- Suppressed: đúng 1 khối bất kể số item; all-suppressed giữ shell.

## 6. Nợ mở (ưu tiên đầu phiên sau)
- 🟠 Lưu repo migrations **v97a1 + v97c** (D90 — dump từ live, nợ kéo từ V97).
- 🟠 Re-sync library: RULES D232–D237 · SYSTEM_MAP v0.90–v0.91 · Handoff v97–v98.
- 🟡 **V98.1:** pill con sync khi vào detail bằng URL trực tiếp · evidence drill-down Option C ("Dựa trên những gì?" mở evidence cards — cần visibility-parity + consent re-check) · auto-generate khi eligible (chờ notification infra V93).
- 🟡 Bunny Optimizer cost review + nâng ngưỡng auto-recharge $5.
- 🟡 Nợ V96/V97: V96D readiness UI · V97.2 (change_over_time · sparse coverage · AI language polish · multi-domain convergence taxonomy riêng).
- 🟡 Nợ V95/cũ: Badge Provenance · Spine ref_id Backfill · child_skills refactor · danh sách Handoff v96 giữ nguyên.

## 7. Rollback V98
- Frontend thuần: xóa 5 file `features/discovery/*` + `parent.discovery.tsx`, gỡ Home card khỏi `parent.index.tsx` + nav link khỏi `parent.tsx` → deploy. DB: KHÔNG có gì để rollback (0 schema change; data hygiene V97-orphan là fix độc lập, giữ).
