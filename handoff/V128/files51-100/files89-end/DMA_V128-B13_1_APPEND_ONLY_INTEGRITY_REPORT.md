# DMA · V128-B13.1 · APPEND-ONLY INTEGRITY REPORT

**Milestone:** V128-B13.1 — Authority Vocabulary Registration (`class.assignment.lead.edit`)
**Mode:** DOCUMENTATION-ONLY · APPEND-ONLY · BYTE-SAFE. No SQL, no DB/registry/function mutation in this run.
**Date:** 2026-08-20

---

## 1 · DMA_RULES.md

| Field | Value |
|---|---|
| Base SHA256 | `1c5515df9a276df74a2c4e8790a225efe103ff02270bd0244ef0dfe1ffba344b` |
| Base bytes | 1,113,188 |
| Final SHA256 | `1df45c26bb6e514325940480272d0e56cc42426ada12537ec4aab4aabc08ddd3` |
| Final bytes | 1,122,596 |
| Appended bytes | 9,408 |
| Prefix proof | `sha256(final[0:1113188]) == sha256(base)` → **PASS** |
| Heading order | `## 🗂️ D375` ×1 → `## 🗂️ D376` ×1 (D376 strictly after D375) |
| Endpoint marker | `RULES D376` |
| Final newline | present |

## 2 · DMA_SYSTEM_MAP.md

| Field | Value |
|---|---|
| Base SHA256 | `bd9c56af2c0a608863a6f6024c1a9ffd1510e949894adc9057fd6454db1039e5` |
| Base bytes | 612,301 |
| Final SHA256 | `288dd22d572eb239953659bf7e4e882ea32e6b64a8e236a9c563e32144f95b6c` |
| Final bytes | 618,452 |
| Appended bytes | 6,151 |
| Prefix proof | `sha256(final[0:612301]) == sha256(base)` → **PASS** |
| Heading order | `## 🗂️ SYSTEM_MAP v1.63` ×1 → `## 🗂️ SYSTEM_MAP v1.64` ×1 (v1.64 strictly after v1.63) |
| Endpoint marker | `SYSTEM_MAP v1.64` |
| Final newline | present |

---

## 3 · Append-only guarantees

- Both files were assembled as `base_bytes ++ append_bytes`; the base is preserved byte-for-byte as an immutable prefix (prefix-SHA proofs above). No rewrite, no renumber, no historical edit.
- Only two new headings were introduced: RULES `D376`, SYSTEM_MAP `v1.64`. All prior D-rules and version blocks are unchanged.
- The B12 endpoint SHAs (`1c5515df…` RULES, `bd9c56af…` MAP) exactly matched the on-disk Project Knowledge base, confirming this closeout appends to the true post-B12 canonical.

## 4 · Documentation-only statement

This run is documentation only. No SQL was executed; no database, registry, function, or `set_distribution_lead` mutation occurred; no migration was applied; the backend tail remains `20260820070120`; the decision lifecycle remains 1 decision / 2 transitions. B13.2 is not implemented here.

## 5 · Endpoint

**RULES D376 · SYSTEM_MAP v1.64 · HANDOFF V128-B13.1-IMPLEMENTATION-CLOSEOUT · backend tail `20260820070120` · FE main pin `2.8.5`.**
**NEXT:** V128-B13.2 — `set_distribution_lead` resolver consumption.
