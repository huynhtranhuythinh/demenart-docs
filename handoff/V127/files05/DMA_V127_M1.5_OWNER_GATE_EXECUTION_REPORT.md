# 🩰 DMA V127-M1.5 — OWNER GATE EXECUTION REPORT
### MP-1 Ballet Skill Seed + MP-2 Pilot Approval Config

> **Owner Gate:** PASS · Thực thi **chỉ** MP-1 + MP-2 (data-only). **0 schema · 0 migration · 0 deploy · 0 permission change.**
> **Target:** Vườn Nghệ Thuật Dế Mèn (`VNDM-DN`, `064dd53e-7aec-4085-9158-02bcd0945af3`) · program ballet (`f7bbf38a-0447-4bf2-8992-e84c791c7348`).
> **Baseline (khớp, giữ nguyên):** RULES **D344** · SYSTEM_MAP **v1.32** · HEAD **`6b860338`** · inventory **89/215/166 · tail `20260807130914`** — bất biến trước & sau.

---

## 1. MUTATION SUMMARY

| Mutation | Nội dung | Kết quả |
|---|---|---|
| **MP-1** | Seed 5 skill ballet vào `skill_catalog` (program-scoped, idempotent) | ✅ **PASS** |
| **MP-2** | Tắt `moment_approval_mode` + `report_approval_mode` cho VNDM | ✅ **PASS** |

Ngoài 2 mutation trên: **không thao tác gì khác** (đúng scope Owner Gate).

---

## 2. BEFORE / AFTER EVIDENCE

### MP-1 — skill_catalog (ballet)
**Before:** 0 skill ballet · ctan 4 · total 5 · không code `ballet_*` nào tồn tại.
**After:** 5 skill ballet (program_id đúng `f7bbf38a…` cả 5) · ctan vẫn 4 (nguyên) · total 9.

| code | label_vi | sort | enabled | program_ok |
|---|---|---|---|---|
| `ballet_technique` | Kỹ thuật & Tư thế | 10 | true | ✅ |
| `ballet_discipline` | Tập trung & Kỷ luật | 20 | true | ✅ |
| `ballet_musicality` | Cảm nhạc & Nhịp điệu | 30 | true | ✅ |
| `ballet_group` | Tương tác & Tự tin nhóm | 40 | true | ✅ |
| `ballet_expression` | Biểu cảm Nghệ thuật | 50 | true | ✅ |

### MP-2 — VNDM approval config
| Cột | Before | After |
|---|---|---|
| `moment_approval_mode` | `true` | **`false`** |
| `report_approval_mode` | `true` | **`false`** |
| `master_profile_id` | `null` | `null` (không đụng) |
| `sharing_mode` | `no_external_sharing` | `no_external_sharing` (không đụng) |
| `watermark_mode` | `null` | `null` (không đụng) |

**Isolation — 3 trường khác không đổi:**
| School | Before (m/r) | After (m/r) |
|---|---|---|
| KHM-DN | true / true | true / true |
| MNDM-DN | true / true | true / true |
| DEMO-001 | true / true | true / true |

---

## 3. SECURITY CHECK
- **Schema change:** KHÔNG — tables 89 (bất biến).
- **Migration:** KHÔNG — tail `20260807130914` (bất biến); dùng `execute_sql` cho data, không `apply_migration`.
- **Function/policy:** KHÔNG — functions 215 · policies 166 (bất biến).
- **Deployment:** KHÔNG — không đụng Edge/frontend/Cloudflare.
- **Permission change:** KHÔNG — không REVOKE/GRANT, không đụng RLS. MP-1 = INSERT catalog; MP-2 = 2 boolean toggle (guard `guard_schools_protected_cols` cho phép *_mode, đã ghim đúng name/code/master/state).
- **Blast radius:** đúng VNDM + program ballet; ctan + 3 trường khác nguyên vẹn.

---

## 4. REMAINING BLOCKERS (giữ nguyên — NGOÀI scope phiên này)
- 🔴 **Account Cô Thuý Ngân** thật (hiện chỉ Demo @ DEMO-001).
- 🔴 **Teacher assignment** — set `lead_teacher_id` 2 distribution (MP-3, chờ profile-id cô).
- 🔴 **Video test** — iPhone HEVC/.MOV cross-device (khoá P1 "Most Compatible").
- 🔴 **Wave 0 cohort** — children + enrollment (MP-5) + mời phụ huynh qua app.
- 🟡 **Master VNDM** — gán qua admin in-app (KHÔNG qua SQL — guard ghim).
- 🔴 **Owner Gate real-login** — 1 buổi ballet end-to-end thật.

---

## 5. CANONICAL STATUS
**"Not canonicalized. Waiting for milestone close."**
Giữ D344 / v1.32 / V126-M1 / HEAD `6b860338`. Delta phiên này = **+5 dòng `skill_catalog` + 2 toggle VNDM** (data-only). Rollback: `DELETE FROM skill_catalog WHERE code LIKE 'ballet_%';` + đặt lại 2 mode = `true`.

---

**Kết:** MP-1 ✅ PASS · MP-2 ✅ PASS. Không tiến sang teacher assignment / cohort import (đúng FINAL RULE). Chờ Owner cho bước kế.
