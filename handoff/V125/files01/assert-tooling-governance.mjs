#!/usr/bin/env node
// scripts/assert-tooling-governance.mjs
// DMA V125-M0 — fail-closed tooling-integrity assertion (detection / containment).
//
// Runs before `vite build`. This guard does NOT fix Lovable's initializer and is
// NOT a prevention layer — safe-writer governance (paste-mode) remains prevention.
// It contains the four-times-proven `@lovable.dev/vite-tanstack-config` re-float
// (2.8.5 -> 2.9.1) and any competing lockfile by failing the build closed before
// a floated source can ship. Assertion-only: it never repairs and never mutates.

import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const ROOT = process.cwd();
const PKG = '@lovable.dev/vite-tanstack-config';
const CANONICAL = '2.8.5';
const FORBIDDEN = '2.9.1';

const violations = [];

// ---- G1 — exact direct dependency pin ------------------------------------
let pkgJson = null;
try {
  pkgJson = JSON.parse(readFileSync(resolve(ROOT, 'package.json'), 'utf8'));
} catch (err) {
  violations.push(`G1 package.json unreadable / invalid JSON: ${err.message}`);
}
if (pkgJson) {
  const pin = pkgJson.devDependencies?.[PKG];
  if (pin === undefined) {
    violations.push(`G1 ${PKG} missing from devDependencies (expected exact "${CANONICAL}")`);
  } else if (pin !== CANONICAL) {
    violations.push(
      `G1 ${PKG} pin is "${pin}", expected exact "${CANONICAL}" (no range / caret / tilde)`,
    );
  }
}

// ---- G2 — canonical Bun lock exists --------------------------------------
const lockPath = resolve(ROOT, 'bun.lock');
let lockText = null;
if (!existsSync(lockPath)) {
  violations.push('G2 root bun.lock is missing (Bun is the sole lockfile authority)');
} else {
  try {
    lockText = readFileSync(lockPath, 'utf8');
  } catch (err) {
    violations.push(`G2 bun.lock unreadable: ${err.message}`);
  }
}

// ---- G3 — canonical lock resolution --------------------------------------
// bun.lock is a text lockfile (trailing commas -> not strict JSON); scan as source
// text. Resolution ids appear as "<pkg>@<version>"; the manifest-mirror form
// ("<pkg>": "<ver>") has no "@<version>" and is intentionally not matched.
if (lockText !== null) {
  const idRe = new RegExp(
    PKG.replace(/[.*+?^${}()|[\]\\/]/g, '\\$&') + '@(\\d+\\.\\d+\\.\\d+[^"\\s\\]]*)',
    'g',
  );
  const resolved = new Set();
  let m;
  while ((m = idRe.exec(lockText)) !== null) resolved.add(m[1]);

  if (resolved.size === 0) {
    violations.push(`G3 no resolved ${PKG}@<version> found in bun.lock`);
  } else {
    if (resolved.has(FORBIDDEN)) {
      violations.push(`G3 forbidden resolution ${PKG}@${FORBIDDEN} present in bun.lock`);
    }
    if (!resolved.has(CANONICAL)) {
      violations.push(
        `G3 canonical resolution ${PKG}@${CANONICAL} absent (resolved: ${[...resolved].join(', ')})`,
      );
    }
  }
}

// ---- G4 — sole lockfile authority ----------------------------------------
for (const competing of [
  'package-lock.json',
  'npm-shrinkwrap.json',
  'yarn.lock',
  'pnpm-lock.yaml',
  'bun.lockb',
]) {
  if (existsSync(resolve(ROOT, competing))) {
    violations.push(`G4 competing lockfile present: ${competing} (bun.lock must be the sole lockfile)`);
  }
}

// ---- G5 — diagnostics -----------------------------------------------------
if (violations.length > 0) {
  console.error('\u2717 tooling-governance assertion FAILED:');
  for (const v of violations) console.error(`  - ${v}`);
  console.error(
    `Restore canonical: ${PKG} = exact "${CANONICAL}" in package.json AND bun.lock resolution; ` +
      `remove any competing lockfile. Do NOT run a non-frozen install to "fix" this.`,
  );
  process.exit(1);
}

console.log(
  `\u2713 tooling-governance OK \u2014 ${PKG}@${CANONICAL} pinned; bun.lock sole + consistent; no ${FORBIDDEN}.`,
);
