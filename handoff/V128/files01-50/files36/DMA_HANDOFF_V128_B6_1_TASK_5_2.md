# 🗂️ DMA_HANDOFF_V128_B6_1_TASK_5_2.md — MISSION CONTROL · request_id INTENT LIFECYCLE (FE) — APPLIED · QA PASS · DEPLOYED · CANONICALIZED

> **Ngày:** 2026-08-14 (GMT+7) · **Loại:** FE-only (1 file hook) + tooling-pin restore (incident) · **Verdict: V128-B6.1 Task 5.2 — CLOSED — ALL PASS (QA 4/4).** Deploy `demenart.lovable.app` LIVE tại `e1c2ea8f`.
> **Boot phiên sau:** file này → `DMA_RULES.md` (tip **D357**) → `DMA_SYSTEM_MAP.md` (**v1.45**) → audit live DB (D1) → **re-pin FE HEAD `list_edits` = `e1c2ea8f`** (KHÔNG phải `b2ec6ad3`).
> *(Đánh số D357/v1.45 = kế tiếp tip on-disk D356/v1.44. Nếu bản live đã vượt, renumber theo tip thật.)*

---

## A. CANONICAL ENDPOINT

- **HANDOFF:** V128-B6.1-Task-5.2 · **RULES:** **D357** · **SYSTEM_MAP:** **v1.45**
- **FE HEAD:** **`e1c2ea8f017bb3d56954eb6447bdd4ac54ffca59`**
  - `b2ec6ad3` = hook fix (Task 5.2) **+ re-float ngoài ý muốn** `@lovable.dev/vite-tanstack-config 2.8.5→2.12.0`
  - `e1c2ea8f` = **pin restored** `2.8.5` (package.json + bun.lock manifest + resolution) — **deploy candidate**
- **Backend:** BẤT BIẾN (0 migration / 0 RPC / 0 Edge / 0 schema). Task 5.2 = FE-only. Migration tail `20260812190653` (B3.3).
- **Deploy:** `is_published=true`, `publish_visibility=public`, published commit `e1c2ea8f`, URL `https://demenart.lovable.app`.
- **Verdict:** `V128-B6.1 Task 5.2 — CLOSED — ALL PASS`. Owner deploy authorization CONSUMED cho `e1c2ea8f`.

## B. SCOPE & DESIGN (đã APPLIED)

**Bug gốc:** `useAssignClassAction` tái dùng `request_id` sau khi user đổi business intent → backend hiểu là replay → intent mới bị bỏ (VD: submit A fail → đổi B submit → id A tái dùng → replay lỗi A, B bị ignore).

**Fix (1 file):** `src/features/mission-control/class/hooks/useAssignClassAction.ts`
- Thêm `lastIntentRef = useRef<string|null>(null)` cạnh `requestIdRef`.
- `submit`: build payload TRƯỚC → `intentKey = JSON.stringify(built.payload)` → mint id mới khi `requestIdRef.current === null` **HOẶC** `lastIntentRef.current !== intentKey`; else reuse. Lưu id + key cùng nhau.
- `onSuccess(parsed.ok)` → clear **cả hai** ref.
- `onError` + business-failure (`ok===false`) → **giữ** cả hai ref (idempotent retry).
- `resetRequest` (nút Đóng drawer) → clear cả hai ref.
- Không import/type mới; không đụng adapter/RPC/contract/generated types. `JSON.stringify` (minimal, theo Gate approve).

## C. QA VERDICT — 4/4 PASS (evidence request_id thật)

| Test | Kỳ vọng | Evidence `p_request_id` | KQ |
|---|---|---|---|
| **A** same intent retry | id₂ = id₁ | `0ecac41d-9ceb-460e-b129-f76af26526c1` ×2 (cùng CTAN) | ✅ |
| **B** new intent | id₃ ≠ id₁ | `c035d931-7d08-4bd1-891a-c42f2027e669` (đổi Ballet) ≠ id₁ | ✅ |
| **C** success → lại | id mới | ledger: `bc1f2b36-…-6a749246395a` ≠ `d20dc916-…-6cf5acaa44f5` | ✅ |
| **D** drawer reset | id mới sau Đóng | X=`0bb20e70-e386-41f3-a499-9b0e76e2d14e` ≠ Y=`1a41fc63-fa83-4afd-8561-d41c86ef233b` | ✅ |

Ledger: `public.mission_control_action_requests(request_id, action_key, object_type, object_id, status, result_payload, error_code, actor_id, …)`.

## D. QA INFRASTRUCTURE (seed + rollback — HOÀN NGUYÊN)

- Seed lớp QA `eeeeeeee-0000-4000-8000-000000000001` ("ZZ_QA_V128_B6.1_T5.2") @ Trường Demo Dế Mèn (`b6a4ac35-2e0a-4667-9eea-756f615c29eb`, entitled cả 2 program) — Owner-authorized.
- **Rollback đã chạy:** xoá class + distributions + lesson_sessions + 2 ledger rows QA. Verify live: `qa_class_remaining=0`, `qa_ledger_remaining=0`, `qa_dist_remaining=0`, `total_classes=7`. **DB sạch, 0 dấu vết QA.**

## E. INCIDENT — AGENT-MODE DEPENDENCY RE-FLOAT (caught pre-deploy)

- Agent (`send_message` "tự áp") → Lovable re-float `@lovable.dev/vite-tanstack-config 2.8.5→2.12.0` ở package.json + bun.lock (manifest dòng 65 + resolution dòng 241). `get_diff` chỉ hiện package.json, **giấu lockfile** (D338).
- `scripts/assert-tooling-governance.mjs` fail-closed: **G1** (package.json pin) + **G3** (bun.lock resolution) đòi `2.8.5`. Build prod = `node scripts/assert-tooling-governance.mjs && vite build` → 2.12.0 làm G1+G3 fail → **gãy** (Lovable preview KHÔNG chạy gate; Cloudflare/`demenart.com` CÓ).
- **Bắt tại pre-deploy verify** (đọc script + package.json + bun.lock trực tiếp) — KHÔNG deploy mù.
- **Fix (`e1c2ea8f`):** restore literal 3 chỗ về canonical `2.8.5` từ commit sạch `d1d5b774` (gồm URL region `europe-west1` + sha `qPNxE…` + hmr-gate `^1.3.4`) — agent literal edit, KHÔNG non-frozen install. Verify: `get_diff` (chỉ package.json) + `read_file bun.lock` (dòng 66=2.8.5, dòng 242=@2.8.5, 0 residual 2.12.0). Gate G1–G4 PASS. → **Rule mới D357.3.**

## F. QA METHOD LEARNINGS

- **DevTools "Offline" KHÔNG dùng được:** request `execute` treo pending (không reject) → hook không nhận `onError` → nút kẹt. Chuyển No throttling thì chính request treo hoàn tất → success. Không có 2 submit để so id.
- **Dùng DevTools "Request blocking"** (fail nhanh → `onError` → nút mở lại; request block KHÔNG tới backend → không tạo distribution → dropdown giữ nguyên → chạy A/B/D lặp; đọc `p_request_id` ở Payload). Pattern URLPattern hợp lệ: `https://<ref>.supabase.co/rest/v1/rpc/execute_mission_control_action*` (đủ URL + `*` cuối, KHÔNG `*` đầu).
- **Backlog (ngoài scope):** mutation `execute` thiếu client-side timeout/abort → treo vô hạn không báo lỗi. Ticket milestone sau (→ D357.5).

## G. STATE FOR NEXT SESSION

- FE HEAD `e1c2ea8f` (fix + pin 2.8.5). Backend BẤT BIẾN.
- Deploy Lovable LIVE; Cloudflare/`demenart.com` build từ main qua gate — pin xanh.
- QA seed rollback sạch (7 classes).
- Owner reminder: **tắt DevTools Request blocking** ở máy Owner.
- Next: **Task 5.3 CHỜ Architecture Gate** (không mở trong session này).
