# 🧭 DMA_HANDOFF — V128-B13.1 · AUTHORITY VOCABULARY REGISTRATION · IMPLEMENTATION CLOSEOUT

> **Milestone:** V128-B13.1 (`class.assignment.lead.edit` — vocabulary-only, non-dispatch authority key registered)
> **Status:** ✅ **PASS** — one registry row committed; no function change; resolver/executor/adapters byte-frozen; class discovery unchanged; lifecycle 1/2 unchanged. Vocabulary provenance only — **not** a behaviour change.
> **Date:** 2026-08-20
> **Supersedes endpoint:** V128-B12-IMPLEMENTATION-CLOSEOUT (D375/v1.63) → now **D376 / v1.64**.
> **Canonical:** RULES **D376** · SYSTEM_MAP **v1.64** · backend tail **`20260820070120`** (UNCHANGED — registry DML, not migration) · FE main pin **`2.8.5`**.

---

## 0 · Boot pin (verify at next session start — hard-stop on mismatch)

| Marker | Value |
|---|---|
| RULES endpoint | **D376** |
| SYSTEM_MAP | **v1.64** |
| HANDOFF | **V128-B13.1-IMPLEMENTATION-CLOSEOUT** (this) |
| Backend migration tail | **`20260820070120`** (UNCHANGED — B13.1 used registry DML, no migration) |
| Registry rows | **4** (class.assign · class.edit · authority.probe · **class.assignment.lead.edit** ⭐ new) |
| Decision lifecycle | **1 decision / 2 transitions** (permanent; unchanged) |
| FE main pin | `2.8.5` |

**Frozen anchors (must match):** resolver `56b5e3f5a14360990b51c080ff1da1cb` · executor `954bcc4087ea0646c60c01cc28717e79` · assign_class_distribution `069cb93c0f7de2e5a933662b8cb9e644` · **set_distribution_lead `1dcc700fb007e25d740129190e221d54`** (legacy WHO — deferred to B13.2) · class_edit_v1 `63f3ab5a…`.

---

## 1 · What this milestone did

Registered the CTO-ratified authority vocabulary key **`class.assignment.lead.edit`** as a **vocabulary-only, non-dispatch** row in `public.mission_control_action_registry`. No function body changed; no adapter created. Because `_resolve_authority` does not branch on `action_key` and never reads the registry, and because `set_distribution_lead` is a direct RPC (not executor-dispatched), the row changes **no authority verdict and no runtime behaviour today**. It records vocabulary provenance for **B13.2** (`set_distribution_lead` resolver consumption) to consume.

---

## 2 · Committed registry row

```
id               6ad88885-7b1a-49be-9da4-6d032e222adb
object_type      class_assignment
action_key       class.assignment.lead.edit
label            Change Class Assignment Lead Teacher
capability       class.assignment.lead.edit
risk_level       MEDIUM
audit_event      distribution_lead_changed
status           active            authority_gated  false
adapter_key      NULL   execution_mode NULL   input_schema NULL   required_context NULL
metadata         {"non_dispatch":true,"authority_vocabulary_only":true,
                  "consumed_by":"public.set_distribution_lead","gate":"V128-B13.1"}
```
Registry total **3 → 4**. No fake adapter field populated.

---

## 3 · Non-dispatch proof

- `_mc_lookup_action('class','class.assignment.lead.edit')` → `{found:false, dispatchable:false}` (executor hardcodes object_type `class`).
- `_mc_lookup_action('class_assignment','class.assignment.lead.edit')` → `{found:true, status:active, dispatchable:false}` (dispatchable requires `status='active' AND adapter_key IS NOT NULL`).
- `get_available_actions('class',…)` still exposes exactly **class.assign, class.edit**.
- `class_assignment` absent from `mission_control_object_registry` (orphaned object_type — accepted OD-01 pattern, as with `authority`).
- Resolver never reads the registry → B13.2's verdict is unaffected by this row.

---

## 4 · Frozen hashes & lifecycle

Resolver `56b5e3f5…` · executor `954bcc40…` · assign_class_distribution `069cb93c…` · set_distribution_lead `1dcc700f…` · class_edit_v1 `63f3ab5a…` — ALL UNCHANGED. Existing three registry rows unchanged. Lifecycle **1 / 2**; no decision opened, no ledger row, no arming. B11.2-B2 evidence intact: decision `5d3b8897…` `approved` · request `b112b2b2-…-f1` · decided_by `…0002`.

---

## 5 · Method (fail-closed, two-phase; not a migration)

Pre-audit (read-only) → rolled-back rehearsal (INSERT + 19 assertions, forced rollback, zero residue) → guarded atomic apply (`DO` block commits only when all 19 assertions pass) → independent post-apply evidence read. Executed via `execute_sql` registry DML; backend tail unchanged (`20260820070120`).

---

## 6 · OD-02 disposition — PARTIALLY CLOSED

**Closed:** ≥2-exercised-action timing threshold satisfied; authority action taxonomy established (`<object>.<operation>[.<qualifier>.<verb>]`); `class.assignment.lead.edit` registered. **Still deferred:** pg-enum materialization (action_key remains documented free-text string-set; no enum minted). Full closure NOT claimed.

---

## 7 · Rollback model (recorded; NOT performed)

```sql
DELETE FROM public.mission_control_action_registry
WHERE object_type='class_assignment' AND action_key='class.assignment.lead.edit';
```
Zero residue — nothing references the row (no FK, no ledger, no decision; resolver/executor ignore it).

---

## 8 · Next

**➡ V128-B13.2 — `set_distribution_lead` resolver consumption.** Frozen contract:
```sql
mc_internal._resolve_authority(public.current_profile(),
  'class.assignment.lead.edit', jsonb_build_object('school_id', v_school), NULL)
```
Ineligible → `not_authorized_for_school` (unchanged legacy string); reason_codes NOT surfaced; domain safety stays local; ordering preserved. B13.2 is a function-body migration (D92 three-block) that will advance the backend tail and change `set_distribution_lead`'s md5.

---

## 9 · Canonical integrity (this closeout)
- `DMA_RULES.md` — base (D375) + **D376**. Prefix-SHA proof PASS (`1c5515df…` == final[0:1113188]); final `1df45c26bb6e514325940480272d0e56cc42426ada12537ec4aab4aabc08ddd3`.
- `DMA_SYSTEM_MAP.md` — base (v1.63) + **v1.64**. Prefix-SHA proof PASS (`bd9c56af…` == final[0:612301]); final `288dd22d572eb239953659bf7e4e882ea32e6b64a8e236a9c563e32144f95b6c`.

See `DMA_V128-B13_1_APPEND_ONLY_INTEGRITY_REPORT.md`.
