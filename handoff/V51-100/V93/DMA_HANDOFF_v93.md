# DMA_HANDOFF_v93.md — V93: Memory Conversation "Câu chuyện quanh kỷ vật" (V93A domain + V93B Parent MVP)

> **ĐÓNG 2026-07-11 GMT+7.**
> Endpoint: RULES **D225** · SYSTEM_MAP **v0.86** · Handoff **v93**.
> **Baseline:** An **6/2/6** · Inventory **65 tables · 111 definer · 155 policies · 1 cron** · memory_threads/messages **0/0**.
> Sprint: **1 migration** (+2 bảng, +4 RPC) + **2 file mới + 3 file edit** frontend (agent-mode, 3 commit).

---

## 1. Mục tiêu

Tầng cảm xúc kế tiếp trên Art Memory Player (V92): khi ba mẹ và con mở lại một kỷ vật, gia đình để lại **lời kể quanh ký ức đó** — lời kể trở thành một phần của kỷ vật. KHÔNG phải comment/social feed/chat/like/notification-heavy.

**Tiêu chí thành công (CTO):** nhiều năm sau, gia đình mở một kỷ vật và thấy không chỉ ảnh/tranh/bản thu mà cả **những lời họ từng nói quanh khoảnh khắc đó** → **ĐẠT** (nghiệm thu ảnh thật + DB cross-check 2026-07-11).

**KHÔNG làm trong V93B:** Kid write (V93C) · Teacher · nested replies · likes/reactions · attachments · voice · notifications/unread (V93D) · AI summarization · export.

---

## 2. C1 — Canonical + Live audit

- Endpoint vào: RULES **D224 (+D224-B)** · SYSTEM_MAP **v0.85** · Handoff **v92** — brief cảnh báo drift do V92 reopened, verify file thật: **KHÔNG drift** (V92B.2 ghi dạng D224-B addendum).
- Inventory vào: **63/107/155/1** ✓ · An **6/2/6** ✓ (UUID `d1000000-…041`, không ILIKE — bẫy D224).
- **⭐ Phát hiện quyết định:** KHÔNG có canonical journey entity — `child_journey` chỉ session(13)+badge(1); moment/creation không có row; timeline ID = concatenation frontend. ⇒ thread mapping table với **3 FK typed nullable**.
- Actor map: Parent `current_profile()`/`is_child_parent` · Kid = `kid_sessions.child_id` (0 auth.uid) · `child_parents.link_role` live chỉ có **'primary'** (không phải Ba/Mẹ).
- Notification system sẵn (10 slugs, chưa có conversation) — V93 KHÔNG đụng. Audit `write_audit_log` keys: actor_id/entity_type/entity_id/child_id/reason/metadata.

## 3. C2 — Quyết định CTO

1. **Schema Option B**: `memory_threads` + `memory_messages`, FK typed nullable, CHECK num_nonnulls=1.
2. **⭐ Correction: uniqueness CHILD-SCOPED** — `UNIQUE (moment_id, child_id) WHERE moment_id IS NOT NULL` (×3) — group moment N bé = N thread riêng tư; `child_id` derive+verify từ source, không trust client.
3. Parent-only V93B · Kid = V93C (kid_gate design) · Teacher KHÔNG.
4. Edit 30′ · body 1.500 · plain text · soft-delete ẩn hoàn toàn · author-only · delete được mọi lúc KHI còn quyền xem source.
5. **Lazy thread**: get KHÔNG INSERT; thread sinh ở message đầu.
6. **Archived/hidden source = strict**: mất quyền xem kỷ vật → mất cả get/post/edit/delete (generic `not_authorized`); KHÔNG delete-own bypass (use case "xoá mọi lời tôi viết" = domain Privacy riêng tương lai). Message VẪN lưu; access hồi phục → conversation hiện lại.
7. Reason codes: generic trước authz (`not_authenticated`/`not_authorized` — collapse not-found/wrong-child/wrong-family/wrong-state); chi tiết sau authz (`edit_window_closed`/`invalid_body`/`body_too_long`/`edit_conflict`/`delete_conflict`).
8. `author_link_role` = presentation metadata ONLY (không authorization); trả kèm `author_name`; `mine/editable/deletable` server-computed.

## 4. C2.6 — Security-parity (D225 invariant)

Audit `get_child_journal` body live + viewer → **2 patch bắt buộc** trước apply:
- **Creation**: chỉ surface khi media `state='active'` → RPC +EXISTS(media active).
- **Journey badge**: RPC trả nhưng frontend skip (D205) → RPC reject `entry_type='badge'`.
- Moment `tagged + approved` = parity chính xác (moment 0-media vẫn là keepsake — KHÔNG thêm media predicate).
- KHÔNG có resolver pattern sẵn → 4 inline gates; **parity = security invariant** (ghi header migration), enforce bằng matrix.

## 5. DB — migration `v93_memory_conversation_domain` (đã apply)

- `memory_threads`: id · child_id NOT NULL→children · moment_id/creation_id/journey_id (NO ACTION) · CHECK num_nonnulls=1 · partial UNIQUE ×3 child-scoped.
- `memory_messages`: thread_id (NO ACTION) · author_type parent|kid + CHECK identity (**chỗ chừa V93C**: kid ⇒ author_child_id) · body CHECK 1–1500 · created/updated/deleted_at · index (thread_id, created_at) WHERE deleted_at IS NULL.
- RLS bật + **0 policy** (deny-all, mirror media_assets) + REVOKE table privileges anon/authenticated.
- 4 RPC SECURITY DEFINER `search_path=''`: `get_memory_conversation` / `post_memory_message` / `edit_memory_message` / `delete_memory_message` — grants authenticated+service_role, 0 anon/PUBLIC (KHỐI 2 REVOKE/GRANT, KHỐI 3 verify aclexplode PASS).
- Edit/delete: lock `FOR UPDATE OF m` + **re-run authz core trên source** + author-only + guarded UPDATE.

## 6. Matrix — 18/20 PASS · 2 not-testable

| Nhóm | Kết quả |
|---|---|
| Lazy get (0 INSERT) · post lazy-create · payload flags | PASS |
| Cross-family · child_id giả · UUID lạ (không phân biệt được) · draft moment · **badge journey** (PH Jenny, sanity is_parent=true) | PASS `not_authorized` |
| Edit 30′ OK · quá 30′ (backdate exact-row, KHÔNG replica — CTO §7) → `edit_window_closed` + `editable:false` | PASS |
| Delete soft (row giữ) · re-delete → `not_authorized` · edit/delete message người khác | PASS |
| Unauth → `not_authenticated` · direct table → `permission denied` · invalid source_type | PASS |
| **#20 group isolation** (`c7fe22f4` An+Chi): thread An `≠` thread Chi cùng moment_id · Hùng không thấy/sửa/xoá message Chi · context Chi → not_authorized | PASS chiều then chốt |
| **#19 2-parents-cùng-bé** · chiều "PH Chi tự đọc RPC" (profile Hạnh `user_id=NULL`) · creation-media-deleted | ⚠️ **NOT TESTABLE — fixture thiếu, KHÔNG fabricate** (backlog) |

Bài học kỹ thuật: 1 SELECT nhiều volatile RPC + subquery thường → subquery đọc snapshot đầu statement (kiểm tra hệ quả mutation tách call riêng).

## 7. Frontend (agent-mode, typecheck + get_diff mỗi commit)

| Commit | Nội dung |
|---|---|
| `5e0ee9b4` | **`useMemoryConversation.ts`** (mới) — 4 RPC, lazy `enabled`, refetch-after-mutation, stale-guard, 0 signing |
| `29efcca8` | **`MemoryConversation.tsx`** (mới) — warm paper, không bubble/avatar/online; empty state 2 dòng chuẩn; composer "Viết một điều mình muốn giữ lại..." + counter 1500; edit inline / delete `window.confirm("Xoá lời này khỏi kỷ vật?")`; server flags only; **link_role whitelist** father/mother/guardian → Ba/Mẹ/Người giám hộ, lạ ('primary')/null → author_name → "Người thân" |
| `7553eb29` | Integration: `JourneyDetail` +nút "💬 Câu chuyện quanh kỷ vật · N" (cuối, sau Gợi ý trò chuyện; N sau fetch đầu — cache `convCounts`) · `ParentJourneyViewer` +`childId?` prop + conversation Sheet **sibling portal** (desktop `side="right"` max-w-md / mobile `side="bottom"` 85vh, matchMedia 1023px) + **story Sheet đổi title → "Xem câu chuyện"** (naming correction CTO) · `parent.journal.tsx` **đúng 1 dòng** truyền `selectedChildId` |

**Deploy prod:** `demenart.com` / `demenart.lovable.app` — deployment **`d383af02`**, commit `7553eb29`.

## 8. ⭐ Nghiệm thu LIVE (Jean, PH Hùng, ảnh thật 15:10–15:13 GMT+7) + DB cross-check

- Mở panel empty (moment 26/6) → đóng → **DB: 0 thread** (lazy proven trên UI thật).
- Post trên moment `8e2c5c7e` (**group moment 3 bé**) → thread `child_id=An` — **child-scoped proven đời thật**; timestamps audit khớp ảnh **từng giây** (post 15:11:30 · edit 15:11:50 · delete 15:12:09).
- Edit "(Sửa lần 1)" OK · delete confirm đúng copy → ẩn hoàn toàn, row soft-delete giữ provenance.
- Author hiện "Nguyễn Văn Hùng" — KHÔNG lộ 'primary'.
- **Network `get_signed_media_url` = 0 request** khi mở/đóng panel · rail/mốc/gallery giữ · Nhật ký + Kid + Teacher y cũ.
- **Acceptance 14/14 PASS.**

## 9. Debris & regression

- Debris smoke: message + thread **hard-delete guarded** (RAISE nếu lệch scope) → memory **0/0**; **8 audit rows GIỮ làm proof** (5 matrix + 3 UI).
- An **6/2/6** ✓ · Inventory **65/111/155/1** ✓ · 0 bảng cũ ALTER · 0 RPC/Edge cũ đụng.
- Non-negotiable giữ: `get_child_journal` · `kid_gate` · `upload_media` · `remove_moment_media_service` · `archive_empty_draft_moment_service` · consent V72 · badge V73 · signing viewport-lazy D224 · Parent/Kid/Teacher UI.

## 10. Rollback

DB: `DROP FUNCTION` ×4 + `DROP TABLE memory_messages, memory_threads` → về 63/107/155/1 (bảng mới hoàn toàn, 0 data cũ đụng). Frontend: revert về sha trước `5e0ee9b4` (Lovable History).

## 11. Backlog

- 🟠 re-sync project library (**D225 + v0.86 + v93**) · 🟠 lưu repo V93 (1 mig + 2 file mới + 3 edit)
- 🟡 **V93C — Kid reply** qua `kid_gate` action mới; schema ĐÃ CHỪA (`author_type='kid'` + `author_child_id` + CHECK) → 0 migration đổi bảng; cần thiết kế author model Kid-session + scope "memory của CHÍNH bé"
- 🟡 **V93D — notification/unread**: hệ notification sẵn (create_notification + notification_types), chưa có slug conversation — cần CTO duyệt riêng
- 🟡 **Fixture nợ test**: (a) 2 parents cùng bé (#19); (b) profile Lê Thị Hạnh `user_id=NULL` → link auth để test chiều PH-Chi-đọc của #20; (c) creation-media-deleted parity
- 🟡 link_role enrichment (father/mother/guardian thật thay 'primary') · 🟡 Privacy/"My Contributions" domain (xoá mọi lời tôi viết — KHÔNG làm yếu authz thread) · 🟡 AlertDialog thay window.confirm (polish)
- Nợ cũ: 🔴 audio pipeline `webm`→iOS · 🟡 Portal header/logo chung 4 portal · 🟡 Art Discovery Capsule (Memory Conversation = 1 evidence source tương lai; extension point ghi nhận, 0 build) · 🟡 Kid adaptation · 🟡 Context Navigator Year→Month · 🟡 pinch/pan fullscreen · 🟠 Bunny orphan `/moments/b2ce6685/*` · 🟢 lifecycle purge THẬT · upload_media source mig068 · consent-filter Kid · filter/month-nav · timeline "X ảnh" · cover_media_id/sort_order · KHÔNG Edge batch-sign · Parent Dashboard/Radar/AI Review THẬT · Phương án B RPC · rename kidJourneyModel.ts · enrichment child_journey · Coloring schema · Moment media taxonomy

## 12. Tài khoản test

| Vai | Email | Mật khẩu |
|---|---|---|
| PH bé An (KHM) | `ph.hung.kidshouse@demo.demenart.com` | `Test@123` |

Bé **An** = `d1000000-0000-4000-8000-000000000041` · Group moment fixture: `c7fe22f4` (An+Chi) · `8e2c5c7e` (An+Bình+Chi) · PH Bảo Chi (Lê Thị Hạnh) profile `…053`, **user_id NULL** (chưa link auth).
