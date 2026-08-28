# V128-P5.0 — TEACHER ASSIGNMENT CONTINUITY PACKAGE

This package closes the P4→P5 continuity transition and establishes the canonical semantic boundary for **Teacher Assignment (phân công giáo viên)**.

## Canonical GitHub Location

Repository: `huynhtranhuythinh/demenart`

Directory:

`docs/evidence/`

## Files

1. `V128-P5.0_TEACHER_ASSIGNMENT_SEMANTIC_CANON.md`
   - Canonical product semantics and invariants.

2. `V128-P5.0_CONTINUITY_HANDOFF.md`
   - Accepted P3/P4 continuity and scope handed into P5.

3. `V128-P5.0_CONTINUITY_HANDOFF_EVIDENCE.md`
   - Governance/evidence record proving P5.0 is an audit-first gate, not an implementation.

4. `V128-P5.1_TEACHER_ASSIGNMENT_RUNTIME_TRUTH_AUDIT_BOOT.md`
   - Ready-to-send boot prompt for the next audit phase.

## Repository Workflow

Canonical direction is:

**ChatGPT artifact → GitHub → local sync**

Do not treat a manually downloaded copy as the canonical source when the GitHub artifact exists.

## Local Target

Local documentation workspace:

`~/dev/dma-docs/`

Before syncing, verify the local remote mapping with:

```bash
cd ~/dev/dma-docs
git remote -v
git status --short --branch
```

If this workspace is the local clone/worktree for `huynhtranhuythinh/demenart`, sync with:

```bash
git pull --ff-only origin main
```

Then verify:

```bash
git log -1 --oneline
ls -la docs/evidence/V128-P5.0*
ls -la docs/evidence/V128-P5.1*
git status --short
```

## Canonical Next Phase

**V128-P5.1 — TEACHER ASSIGNMENT RUNTIME TRUTH & SEMANTIC GAP AUDIT**

Mode: **READ-ONLY / AUDIT-FIRST / NO IMPLEMENTATION**
