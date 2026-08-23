# DMA PARENT PORTAL — V113G-M1 WORK PACKAGE G.3
## GIA ĐÌNH / FMN SURFACES TRONG PARENT SHELL

Bạn là Claude — PM / Builder của DMA.

## OWNER DECISION

`DUYỆT A — INTEGRATE, KHÔNG REDESIGN`

Kiến trúc chính thức:

`PARENT SHELL OUTSIDE — FMN DESIGN SYSTEM INSIDE — MINIMUM BRIDGE AT THE BOUNDARY`

Không retoken toàn bộ FMN. Không phá V111B–E. Không redesign ruột FMN.

Parent Portal sở hữu:
- route chrome;
- desktop rail;
- tablet top bar + drawer;
- mobile header + bottom nav;
- breakpoint grammar;
- shared ChildSwitcher;
- page title/eyebrow;
- outer spacing, safe-area và truthful states ở boundary.

FMN giữ nguyên:
- hệ token `--fmn-*`;
- Stream;
- MemoryItem;
- Memory Room;
- archive navigation;
- motion layer;
- creator attribution;
- voice/audio grammar;
- preserve/conversation behavior;
- emotional experience layer V111.

---

# 1. CURRENT BASELINE

Production baseline:
- G.1 Foundation + Hôm nay: CLOSED;
- Breakpoint 479 amendment: CLOSED;
- G.2 Journey + Discovery + Share re-home: CLOSED;
- expected lineage từ production HEAD `567d2cc4`;
- Cloudflare CI tự deploy mọi commit trên `main`;
- không canonicalize trong G.3.

Trước write:
1. re-pin current HEAD;
2. xác minh chỉ một active writer cho DMA G.3;
3. kiểm tra delayed commits từ session cũ;
4. audit exact live source;
5. ghi static baseline;
6. ghi protected fingerprints.

Nếu HEAD đã tiến thêm bởi session DMA cũ nhưng session đó không còn active:
- coi code là handed-off third-party code;
- re-audit exact diff;
- tiếp tục từ live HEAD;
- không revert chỉ vì provenance không rõ.

Nếu có active second writer đang sửa cùng file DMA/FMN:
- STOP concurrency gate và đưa bằng chứng cụ thể.

---

# 2. USER OUTCOME

Hoàn thành vertical slice:

`Parent mở Gia đình → giữ cùng selected child → xem đúng Family Space → dùng FMN Stream/Memory Room trong Parent shell → mở Memory Card → creator/voice/conversation/preserve đúng quyền → responsive desktop/tablet/mobile → quay lại Parent routes không mất context`

`/parent/family` phải thuộc Parent Portal nhưng vẫn giữ nguyên bản sắc FMN.

---

# 3. SCOPE

Primary route:
- `src/routes/_authenticated/parent.family.tsx`

Allowed supporting scope, chỉ khi cần:
- shared Parent shell/layout;
- `src/features/parent/ChildSwitcher.tsx`;
- route-boundary wrapper Parent + FMN;
- tối đa 1–2 entry/gate files liên quan trực tiếp;
- `src/styles.css` chỉ cho boundary bridge nếu không thể đặt cục bộ.

Có thể tạo tối đa một boundary helper nhỏ, ví dụ:
- `ParentFamilyBoundary.tsx`;
- hoặc một CSS module route-boundary.

Không tạo abstraction không có consumer.

Default forbidden core area:
- `src/features/family/**` core;
- Stream internals;
- Memory Room internals;
- archive navigation internals;
- `family.tsx`;
- `family_.memory.$cardId.tsx`;
- standalone `/family` namespace;
- RPC/RLS/consent;
- protected files.

Nếu audit chứng minh shared FMN consumer bắt buộc phải sửa:
- thay đổi tối thiểu;
- không đổi authorization semantics;
- regression `/family` bắt buộc;
- ghi rõ lý do;
- không mở rộng thành redesign.

---

# 4. TOKEN RECONCILIATION

Parent owns:
- shell navigation;
- route page boundary;
- outer background;
- content width;
- outer spacing;
- title/eyebrow;
- safe area;
- bottom-nav clearance;
- breakpoint behavior;
- global focus treatment;
- reduced-motion handoff.

FMN owns:
- `--fmn-*`;
- internal palette;
- card radius;
- Stream spacing;
- Memory Room grammar;
- card/media treatment;
- chapter rhythm;
- voice presentation;
- archive/preserve/conversation states.

Minimum bridge only:
- Parent outer background → FMN canvas boundary;
- Parent inset → FMN container;
- Parent safe area → FMN mobile padding;
- Parent reduced motion → FMN motion settings;
- Parent focus ring → FMN actionable elements nếu cần;
- shared child context → route gate.

Không rename hàng loạt token. Không duplicate design system. Không thay palette. Không retoken FMN.

---

# 5. SHARED CHILD CONTEXT

`/parent/family` phải dùng cùng persisted selected child với:
- `/parent`;
- `/parent/journal`;
- `/parent/discovery`.

Requirements:
- dùng `ParentChildProvider`;
- dùng shared `ChildSwitcher`;
- gỡ selector local nếu còn;
- clear data cũ ngay khi đổi child;
- chống stale async response;
- close detail/dialog nếu item thuộc child trước;
- không hiển thị Family Space child A dưới child B;
- giữ selected child xuyên route;
- không duplicate selector.

Nếu Family Space là family-level nhưng route vào theo child:
- resolve bằng backend truth hiện có;
- không invent relationship mới;
- child chưa có Family Space phù hợp → truthful state.

---

# 6. PARENT SHELL INTEGRATION

Breakpoint grammar giữ nguyên:
- desktop ≥1024;
- tablet 480–1023;
- mobile ≤479.

Expected:
- desktop rail;
- tablet top bar + drawer;
- mobile header + bottom nav;
- `Gia đình` active;
- không duplicate internal nav;
- không second mobile header;
- không content dưới bottom nav;
- không dùng standalone `/family` width assumptions sai trong Parent shell.

---

# 7. FMN EXPERIENCE PRESERVATION

Giữ nguyên:
- Stream emotional rhythm;
- immersive mode nếu approved;
- overview mode nếu approved;
- Memory Room;
- voice/audio visibility;
- creator attribution;
- archive semantics;
- preserve semantics;
- conversation;
- detail dialog;
- chapter/time grammar;
- motion language.

Chỉ sửa:
- route chrome;
- Parent shell boundary;
- child context;
- truthful states;
- responsive conflict;
- accessibility defect;
- nested-scroll issue;
- stale data;
- shell overlap.

Không biến FMN thành generic Parent dashboard.

---

# 8. AUTHORIZATION / GOVERNANCE

Không đổi:
- guardian capabilities;
- invited family member capabilities;
- creator-only rules;
- preserve guardian-only;
- archive lifecycle;
- invitation contracts;
- family membership;
- relationship labels;
- consent logic;
- family ownership;
- removal semantics.

Không tạo `canManage`.

UI chỉ phản ánh backend truth, không thay authorization.

---

# 9. TRUTHFUL STATES

Phân biệt rõ:
1. loading child;
2. loading Family Space;
3. loading Stream;
4. selected child chưa có Family Space;
5. Family Space có nhưng chưa có cards;
6. cards có nhưng engagement rỗng;
7. network error;
8. denied/not authorized;
9. archived card;
10. reversed/orphaned preserve;
11. media sign failure;
12. voice unavailable;
13. conversation unavailable;
14. removed membership nếu liên quan.

Không collapse empty/error/denied/not-configured.
Không để voice, preserve hoặc engagement biến mất im lặng.

---

# 10. RESPONSIVE MATRIX

Test exact widths:
- 1440
- 1024
- 1023
- 768
- 500
- 480
- 479
- 430
- 390

Expected shell:
- 1440/1024 → desktop rail;
- 1023/768/500/480 → tablet top bar + drawer;
- 479/430/390 → mobile header + bottom nav.

Verify:
- no horizontal overflow;
- no nested-scroll trap;
- immersive stream không đè shell;
- snap-scroll không giấu header/bottom nav;
- overview collapse đúng;
- detail dialog fit viewport;
- close button reachable;
- creator visible;
- voice usable;
- preserve/conversation reachable;
- safe-area đúng;
- media không layout shift;
- không tablet drawer ở 430px.

Nếu immersive mode xung đột Parent shell mobile:
- chỉ adapt boundary behavior;
- không xóa immersive mode toàn cục;
- không phá standalone `/family`.

---

# 11. QA MATRIX

Child context:
1. An selected;
2. Khang selected;
3. rapid An → Khang;
4. rapid Khang → An;
5. persisted child across Parent routes;
6. child without Family Space;
7. child with Family Space;
8. no stale cross-child data.

Stream:
9. populated;
10. empty;
11. loading;
12. error;
13. immersive;
14. overview;
15. mode persistence nếu có;
16. chapter boundaries;
17. deterministic ordering;
18. archived chip;
19. image card;
20. video card;
21. text card;
22. audio/voice card;
23. fallback media;
24. layout shift.

Detail:
25. open Memory Card;
26. close and restore context;
27. Escape;
28. focus trap;
29. focus restoration;
30. creator visible;
31. time grammar;
32. archived state;
33. unsupported media;
34. signed-media failure.

Engagement:
35. fetch on-open;
36. empty reactions;
37. existing reactions;
38. conversation open;
39. message list;
40. failure;
41. no contribute capability;
42. no silent disappearance.

Preserve:
43. guardian sees eligible action;
44. non-guardian does not;
45. active preserve nếu fixture có;
46. reversed;
47. orphaned truthful state;
48. no unauthorized lifecycle mutation.

Creation/contribution:
49. existing CTA visibility;
50. guardian capability;
51. invited member capability;
52. no unauthorized action leakage;
53. route return after create nếu hiện có.

---

# 12. CROSS-ROUTE REGRESSION

Verify:
- `/parent`;
- `/parent/journal`;
- `/parent/discovery`;
- `/parent/kid`;
- `/parent/consent`;
- `/parent/settings`;
- `/family`;
- `/family-invite`;
- `/share/$token`;
- notifications/support;
- Parent shell at 430px and 500px.

Specific proof:
- selected child consistent;
- Gia đình active state correct;
- no FMN token leakage into Home/Journey/Discovery;
- no Parent token reset breaking `/family`;
- no auth regression;
- no consent regression.

---

# 13. SECURITY STOP-GATES

Stop only if:
1. child switching exposes another child’s Family Space;
2. removed/non-member sees family content;
3. guardian/member authorization conflated;
4. preserve exposed to unauthorized actor;
5. archived/removed data reactivated;
6. signed media becomes public/cross-family;
7. fix requires RPC/RLS/schema/consent change;
8. production data mutation required without approval;
9. shared FMN change breaks `/family` authorization;
10. active second writer confirmed on same DMA/FMN files.

On STOP:
- provide exact evidence;
- do not patch around security;
- propose one minimum safe correction.

---

# 14. OWNER GATES

Only stop when:
1. two materially different visual outcomes remain valid;
2. production mutation required;
3. authenticated production session unavailable;
4. non-canonical family business rule cannot be inferred;
5. preserving FMN identity conflicts materially with approved Parent shell.

Do not stop for CSS, responsive defects, TS errors, stale state, loading/error bugs, lint failures hoặc component regressions. Self-fix those.

---

# 15. FORBIDDEN CHANGES

Do not change:
- package.json;
- bun.lock;
- generated route tree;
- Supabase generated types;
- SQL/migrations;
- RPC;
- RLS;
- Edge Functions;
- consent types;
- Family governance;
- invitation semantics;
- Family Member capabilities;
- Preserve lifecycle;
- archive contract;
- Kid Portal;
- Home/Journey/Discovery product logic;
- breakpoint grammar;
- FMN data model;
- standalone `/family` route contract.

Do not add social ranking, public profiles, followers/friends, notification expansion, search, AI, schema, generic authorization hoặc design-system rewrite.

---

# 16. STATIC QA

Changed/new files:
- Prettier PASS;
- ESLint 0E/0W;
- no new eslint-disable.

Run:
- targeted Prettier;
- targeted ESLint;
- `tsc --noEmit`;
- local build;
- Lovable build nếu có;
- full lint before/after.

Acceptance:
- errors ≤ current live baseline;
- warnings ≤ current live baseline;
- no new rule IDs;
- 0 findings from G.3 files.

Record exact numbers.

---

# 17. PRODUCTION-AFFECTING MODE

Work on `main`.

Every commit may deploy through Cloudflare CI.

Requirements:
- contiguous commit range;
- no unrelated files;
- record every commit;
- inspect CI after commit group;
- production smoke immediately;
- auto-fix P1;
- report indirect deployment truth.

Use exact wording:

`deploy_project was not called; production was updated indirectly through Cloudflare CI`

Do not report `deployment: NO` if CI deployed.
Maintain exact rollback order.

---

# 18. DOCUMENTATION

Do not canonicalize in G.3.

Do not:
- create final HANDOFF;
- bump SYSTEM_MAP;
- append final Rules;
- regenerate canonical inventory;
- reconcile historical docs.

Update only temporary V113G-M1 execution ledger if needed.
Canonicalize once after complete V113G-M1 Milestone Review.

---

# 19. EXECUTION SEQUENCE

Phase 1 — Audit:
- re-pin HEAD;
- verify single writer;
- inspect route/component graph;
- inspect token ownership;
- inspect child context;
- inspect authorization;
- capture baseline.

Phase 2 — Boundary bridge:
- minimum bridge only;
- remove duplicate chrome;
- keep `--fmn-*`;
- adapt safe-area/inset;
- prevent token leakage.

Phase 3 — Child context:
- migrate `/parent/family`;
- clear stale data;
- close cross-child detail;
- resolve Family Space truthfully.

Phase 4 — Responsive integration:
- desktop/tablet/mobile;
- immersive/overview;
- detail;
- voice;
- creator;
- preserve;
- conversation.

Phase 5 — Truthful states:
- loading;
- empty;
- denied;
- error;
- archive;
- preserve anomaly;
- media failure.

Phase 6 — QA + self-correction:
- full matrix;
- `/family` regression;
- Parent regression;
- production smoke;
- self-fix all P1.

Phase 7 — Closeout:
- return one consolidated A–Q report only.

---

# 20. CLOSEOUT FORMAT

# V113G-M1 G.3 WORK PACKAGE CLOSEOUT

## A. VERDICT
`PASS — FAMILY / FMN SURFACES IN PARENT SHELL COMPLETE`
or true blocker.

## B. USER OUTCOME
Complete Parent Family experience.

## C. BASELINE
- starting HEAD;
- static baseline;
- protected fingerprints;
- single-writer verification.

## D. TOKEN RECONCILIATION
- Parent-owned;
- FMN-owned;
- bridge;
- no token leakage;
- standalone `/family` proof.

## E. IMPLEMENTATION
- files;
- commit range;
- shell;
- child context;
- responsive;
- truthful states.

## F. AUTHORIZATION PROOF
- guardian;
- invited member;
- creator;
- preserve;
- archive;
- conversation;
- no `canManage`;
- no backend drift.

## G. CHILD CONTEXT PROOF
- shared ChildSwitcher;
- persistence;
- race guard;
- cross-child detail closure;
- Family Space resolution.

## H. RESPONSIVE MATRIX
| Route/state | 1440 | 1024 | 1023 | 768 | 500 | 480 | 479 | 430 | 390 | Verdict |

## I. FMN QA
Full QA matrix.

## J. REGRESSION
Parent + `/family` + invite/share/support.

## K. STATIC QA
Prettier, ESLint, TS, build, full lint.

## L. PRODUCTION CI EXPOSURE
Commits, Cloudflare truth, production smoke, deploy_project truth.

## M. CHANGE PROOF
Confirm unchanged:
- package/lock;
- route tree;
- schema/migrations/types;
- RPC/RLS/Edge;
- consent;
- governance;
- unrelated files.

List any authorized production mutation.

## N. ROLLBACK
Exact reverse commit order.

## O. OPEN DEBT
Only real debt.

## P. MILESTONE STATUS
- G.1
- Breakpoint amendment
- G.2
- G.3

## Q. NEXT ACTION
If PASS:
- stop at Milestone Review;
- return to ChatGPT/Product Owner;
- do not canonicalize;
- do not start G.4 before targeted CTO review.

---

# FINAL COMMAND

Owner decision is approved:

`A — INTEGRATE, KHÔNG REDESIGN`

Re-pin production HEAD and verify single active DMA writer.

Execute G.3 as one complete vertical work package.

Use Parent Shell outside. Preserve FMN Design System inside. Implement only the minimum bridge at the boundary.

Auto-fix all P1.

Do not canonicalize.

Return only after production smoke and complete A–Q closeout, unless a true Security Stop-Gate or Owner Gate occurs.
