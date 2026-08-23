// V121-M1 — Home-centric continuity (Phase C). Daily Focus (session outcome) is
// the primary Home content immediately after child context; MemoryHero is demoted
// below outcome + continuity and suppressed when it duplicates the featured
// outcome by stable moment/media identity. Removed from Home: the old "Gần đây"
// strip and the hardcoded "Cùng con hôm nay" card. The standalone "Hành trình"
// card is replaced by a light Journey continuation entry; the "Thế giới của con"
// card is dropped from Home (bottom nav covers it). Routes, features, and the
// /parent/discovery route are unchanged.
// Order: identity → ChildSwitcher → Daily Focus → Journey continuation →
// memory (demoted, deduped) + contextual create → quiet family signal → Nhìn lại.
// Data contracts unchanged: get_child_journal RPC + get_signed_media_url Edge +
// get_parent_session_outcomes (inside the outcome section). No new request added.
//
// V126-M1 (C1) — Meaning bridge. The quiet discovery entry is now a
// readiness-aware bridge to the EXISTING /parent/discovery ("Nhìn lại") layer,
// with three honest states (has-capsule / eligible / accumulating). Bridge ONLY:
// capsule items are never rendered inline. The records card is relabelled to
// "Nhật ký" so the boundary stays clean — Nhật ký = records, Hành trình = meaning.
// Reuses the shipped discovery engine read-only (list_discovery_capsules +
// get_child_evidence_readiness). No new RPC/DB/Edge/migration, no generation
// trigger (capsule generation stays parent-initiated on the discovery route),
// no AI, no scoring, no analytics. list-first (cheap) → readiness only when there
// is no capsule (avoids the heavier readiness compute on every Home load).
import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useCallback, useEffect, useRef, useState } from "react";
import { ArrowRight, ChevronRight, Plus, Sparkles } from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { useParentChild, childLabel } from "@/features/parent/parentChildContext";
import { ChildSwitcher } from "@/features/parent/ChildSwitcher";
import { MemoryHero } from "@/features/parent/home/MemoryHero";
import {
  ParentSessionOutcomeSection,
  type FeaturedOutcomeIdentity,
} from "@/features/parent/session-outcome/ParentSessionOutcomeSection";
import { TruthState } from "@/features/shared/TruthState";
import { type ReservedMediaStatus } from "@/features/shared/ReservedMedia";
import { ParentMemoryComposer } from "@/features/journey/ParentMemoryComposer";
import {
  buildParentTimeline,
  cleanCaption,
  formatViDate,
  isFamilyPreserve,
  isParentMemory,
  type JournalPayload,
  type ParentTimelineEvent,
} from "@/features/journey/parentJourneyModel";
import { logParentEvent } from "@/lib/parentTelemetry";
// V126-M1 (C1) — reuse discovery readiness types only (read-only, no new engine).
import { type ReadinessPayload, type EligibilityNode } from "@/features/discovery/discoveryModel";

export const Route = createFileRoute("/_authenticated/parent/")({
  component: ParentHome,
});

type HeroModel = {
  focusId: string;
  kindLabel: string;
  title: string;
  blurb: string | null;
  dateLabel: string;
  mediaId: string;
};

// "pending" = Daily Focus section has not reported the featured outcome identity
// yet. Kept short so the useState generic stays on one line (no line-ending "<").
type FeaturedIdentityState = FeaturedOutcomeIdentity | null | "pending";

/**
 * Deterministic hero selection: walk buildParentTimeline (already sorted
 * occurredAt DESC with stable input order) and take the FIRST event carrying
 * usable visual media. An item without usable media is never selected while a
 * media-bearing item exists.
 */
function pickHero(data: JournalPayload): HeroModel | null {
  const events = buildParentTimeline(data);
  for (const ev of events) {
    const model = heroFromEvent(ev);
    if (model) return model;
  }
  return null;
}

function heroFromEvent(ev: ParentTimelineEvent): HeroModel | null {
  if (ev.source === "moment") {
    if (!ev.moment.media_id) return null;
    return {
      focusId: ev.id,
      kindLabel: "Khoảnh khắc ở lớp",
      title: cleanCaption(ev.moment.caption) || "Một khoảnh khắc ở lớp",
      blurb: null,
      dateLabel: formatViDate(ev.moment.created_at),
      mediaId: ev.moment.media_id,
    };
  }
  if (ev.source === "creation") {
    if (ev.creation.kind !== "drawing" || !ev.creation.media_id) return null;
    return {
      focusId: ev.id,
      kindLabel: "Tác phẩm của con",
      title: cleanCaption(ev.creation.caption) || "Tác phẩm mới của con",
      blurb: null,
      dateLabel: formatViDate(ev.creation.created_at),
      mediaId: ev.creation.media_id,
    };
  }
  if (isParentMemory(ev.entry) && ev.entry.parent_memory) {
    const pm = ev.entry.parent_memory;
    const firstImage = (pm.galleryItems ?? [])
      .filter((it) => (it.fileType ?? "").startsWith("image/"))
      .slice()
      .sort((a, b) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0))[0];
    if (!firstImage) return null;
    return {
      focusId: ev.id,
      kindLabel: "Ba mẹ lưu lại",
      title: pm.title,
      blurb: pm.story,
      dateLabel: formatViDate(ev.entry.occurred_at),
      mediaId: firstImage.mediaId,
    };
  }
  if (isFamilyPreserve(ev.entry) && ev.entry.family_preserve) {
    const fp = ev.entry.family_preserve;
    const firstImage = (fp.galleryItems ?? [])
      .filter((it) => (it.fileType ?? "").startsWith("image/"))
      .slice()
      .sort((a, b) => (a.sortOrder ?? 0) - (b.sortOrder ?? 0))[0];
    if (!firstImage) return null;
    return {
      focusId: ev.id,
      kindLabel: "Từ Không gian gia đình",
      title: fp.card_title || "Kỷ niệm gia đình",
      blurb: fp.card_story,
      dateLabel: formatViDate(ev.entry.occurred_at),
      mediaId: firstImage.mediaId,
    };
  }
  return null;
}

function newestFamilySignal(data: JournalPayload) {
  for (const ev of buildParentTimeline(data)) {
    if (ev.source === "journey" && isFamilyPreserve(ev.entry) && ev.entry.family_preserve) {
      return { ev, fp: ev.entry.family_preserve };
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// V126-M1 (C1) — Meaning bridge (Home → /parent/discovery). Bridge only.
// Never renders capsule items inline. Reuses the shipped discovery engine
// read-only; no new RPC/DB, no generation trigger, no scoring, no AI.
// ---------------------------------------------------------------------------

// Some discovery RPCs are not present in the generated Supabase types (mirrors
// the pattern in parent.discovery.tsx). Cast through unknown — never `any`.
type DiscoveryRpc = (
  fn: string,
  args: Record<string, unknown>,
) => Promise<{ data: unknown; error: { message: string } | null }>;

// Three content states + a hold (loading) and a quiet fallback (read error).
type BridgeState = "hold" | "has_capsule" | "eligible" | "insufficient" | "fallback";

/** True if ANY window (general or domain-specific) is currently eligible. */
function anyEligible(readiness: ReadinessPayload | null): boolean {
  if (!readiness) return false;
  const gen = readiness.eligibility?.general ?? {};
  for (const k of Object.keys(gen)) {
    if ((gen as Record<string, EligibilityNode | undefined>)[k]?.eligible) return true;
  }
  const dom = readiness.eligibility?.domain_specific ?? {};
  for (const d of Object.keys(dom)) {
    const wins = dom[d] ?? {};
    for (const w of Object.keys(wins)) {
      if ((wins as Record<string, EligibilityNode | undefined>)[w]?.eligible) return true;
    }
  }
  return false;
}

function MeaningBridge({ childId }: { childId: string | null }) {
  const [state, setState] = useState<BridgeState>("hold");
  // Child-scoped sequencing (Correction-A): a late response from a previous
  // child must never commit state for the currently selected child.
  const seqRef = useRef(0);

  useEffect(() => {
    if (typeof window === "undefined" || !childId) {
      setState("hold");
      return;
    }
    const seq = ++seqRef.current;
    const requestChildId = childId;
    setState("hold");
    const rpc = supabase.rpc.bind(supabase) as unknown as DiscoveryRpc;

    (async () => {
      // 1) list-first (cheap): does a capsule already exist for this child?
      const listRes = await rpc("list_discovery_capsules", { p_child_id: requestChildId });
      if (seq !== seqRef.current || requestChildId !== childId) return;
      if (listRes.error) {
        // Never block Home on a discovery read error — quiet generic entry.
        setState("fallback");
        return;
      }
      const caps = ((listRes.data as { capsules?: unknown } | null)?.capsules ?? []) as unknown[];
      if (caps.length > 0) {
        setState("has_capsule");
        return;
      }

      // 2) No capsule → readiness (heavier) to tell eligible vs still accumulating.
      const rdRes = await rpc("get_child_evidence_readiness", { p_child_id: requestChildId });
      if (seq !== seqRef.current || requestChildId !== childId) return;
      if (rdRes.error) {
        setState("fallback");
        return;
      }
      setState(anyEligible(rdRes.data as ReadinessPayload) ? "eligible" : "insufficient");
    })();
  }, [childId]);

  // Loading — render nothing (no layout flash), consistent with the memory hero hold.
  if (state === "hold") return null;

  const linkBase = "group block rounded-3xl border p-6 transition-colors";
  const chevron = (
    <ChevronRight
      className="ml-auto h-4 w-4 text-dma-ink-meta transition-transform group-hover:translate-x-0.5"
      aria-hidden="true"
    />
  );

  // State 1 — a capsule exists: warm invitation to revisit.
  if (state === "has_capsule") {
    return (
      <Link
        to="/parent/discovery"
        className={`${linkBase} border-dma-champagne-soft bg-dma-ivory-raised hover:bg-dma-sage-tint/50`}
      >
        <div className="flex items-center gap-2">
          <Sparkles className="h-4.5 w-4.5 text-dma-ink-gold" aria-hidden="true" />
          <h2 className="font-dma-serif text-lg text-dma-ink">Nhìn lại</h2>
          {chevron}
        </div>
        <p className="mt-1.5 text-sm leading-relaxed text-dma-ink-2">
          Có một bản khám phá đang chờ — cùng nhìn lại những gì hành trình của con đang dần cho thấy.
        </p>
      </Link>
    );
  }

  // State 2 — eligible but no capsule yet: gentle invite. Never auto-generates;
  // the parent creates the capsule themselves on the discovery route.
  if (state === "eligible") {
    return (
      <Link
        to="/parent/discovery"
        className={`${linkBase} border-dma-hairline bg-dma-ivory-raised hover:bg-dma-sage-tint/60`}
      >
        <div className="flex items-center gap-2">
          <Sparkles className="h-4.5 w-4.5 text-dma-ink-gold" aria-hidden="true" />
          <h2 className="font-dma-serif text-lg text-dma-ink">Nhìn lại</h2>
          {chevron}
        </div>
        <p className="mt-1.5 text-sm leading-relaxed text-dma-ink-2">
          Hành trình của con đã có đủ dấu vết để cùng nhìn lại — ba mẹ ghé xem khi có một chút thời
          gian nhé.
        </p>
      </Link>
    );
  }

  // State 3 — insufficient: honest accumulation, no pressure. Soft link so the
  // parent can see (on the discovery route) what is gently accumulating.
  if (state === "insufficient") {
    return (
      <Link
        to="/parent/discovery"
        className={`${linkBase} border-dma-hairline bg-dma-ivory-raised hover:bg-dma-sage-tint/50`}
      >
        <div className="flex items-center gap-2">
          <Sparkles className="h-4.5 w-4.5 text-dma-ink-meta" aria-hidden="true" />
          <h2 className="font-dma-serif text-lg text-dma-ink">Nhìn lại</h2>
          {chevron}
        </div>
        <p className="mt-1.5 text-sm leading-relaxed text-dma-ink-2">
          Mỗi trải nghiệm của con đang góp thêm một phần vào câu chuyện riêng. Khi hành trình đủ đầy
          hơn, ba mẹ có thể cùng nhìn lại những điều đang dần hình thành.
        </p>
      </Link>
    );
  }

  // Fallback — read error: preserve the prior quiet generic entry (never block Home).
  return (
    <Link
      to="/parent/discovery"
      className={`${linkBase} border-dma-hairline bg-dma-ivory-raised hover:bg-dma-sage-tint/60`}
    >
      <div className="flex items-center gap-2">
        <Sparkles className="h-4.5 w-4.5 text-dma-ink-gold" aria-hidden="true" />
        <h2 className="font-dma-serif text-lg text-dma-ink">Nhìn lại</h2>
        {chevron}
      </div>
      <p className="mt-1.5 text-sm leading-relaxed text-dma-ink-2">
        Nhìn lại những gì hành trình của con đang dần cho thấy, từ dữ liệu đã được ghi nhận.
      </p>
    </Link>
  );
}

function ParentHome() {
  const navigate = useNavigate();
  const { children, loadingChildren, selectedChildId } = useParentChild();

  const [data, setData] = useState<JournalPayload | null>(null);
  const [journalError, setJournalError] = useState(false);
  const [composerOpen, setComposerOpen] = useState(false);
  const [heroMedia, setHeroMedia] = useState<{ status: ReservedMediaStatus; src: string | null }>({
    status: "loading",
    src: null,
  });
  // V121-M1 — featured outcome identity reported up by the Daily Focus section,
  // used to suppress a MemoryHero that duplicates the featured session's moment.
  // "pending" = section has not settled yet (hold hero to avoid a flash-then-hide).
  const [featuredIdentity, setFeaturedIdentity] = useState<FeaturedIdentityState>("pending");

  // V113G.1 Correction A — child-scoped request sequencing. A late response
  // from a previous child (journal or signed media) must NEVER commit state
  // for the currently selected child.
  const journalSeqRef = useRef(0);
  const mediaSeqRef = useRef(0);

  // Reset featured-outcome identity whenever the selected child changes, so the
  // memory area holds (never shows a previous child's hero) until the Daily
  // Focus section reports the new child's featured identity.
  useEffect(() => {
    setFeaturedIdentity("pending");
  }, [selectedChildId]);

  const handleFeaturedIdentity = useCallback((identity: FeaturedOutcomeIdentity | null) => {
    setFeaturedIdentity(identity);
  }, []);

  const loadJournal = useCallback(async () => {
    if (typeof window === "undefined" || !selectedChildId) return;
    const seq = ++journalSeqRef.current;
    const requestChildId = selectedChildId;
    // Clear the previous child's journal immediately: no hero/family signal may
    // render under the new child's heading while loading.
    setData(null);
    setJournalError(false);
    setComposerOpen(false);
    const { data: rpcData, error } = await supabase.rpc("get_child_journal", {
      p_child_id: requestChildId,
    });
    // Stale-response guard: only the latest request for the still-selected
    // child may commit state.
    if (seq !== journalSeqRef.current || requestChildId !== selectedChildId) return;
    if (error) {
      setData(null);
      setJournalError(true);
    } else {
      const payload = (rpcData ?? {}) as Partial<JournalPayload>;
      setData({
        journey: payload.journey ?? [],
        skills: payload.skills ?? [],
        badges: payload.badges ?? [],
        moments: payload.moments ?? [],
        creations: payload.creations ?? [],
      });
    }
  }, [selectedChildId]);

  useEffect(() => {
    loadJournal();
  }, [loadJournal]);

  const firedHomeView = useRef<string | null>(null);
  useEffect(() => {
    if (!selectedChildId) return;
    if (firedHomeView.current === selectedChildId) return;
    firedHomeView.current = selectedChildId;
    logParentEvent("parent_home_view", { route: "/parent" });
  }, [selectedChildId]);

  const hero = data ? pickHero(data) : null;

  // V121-M1 — MemoryHero dedupe vs featured outcome by STABLE identity only
  // (moment_id / media_id from the outcome payload). Never a heuristic
  // (title / date / caption / media URL). The memory area holds while the
  // section is "pending" so the hero never flashes then hides.
  const heroMomentId = hero && hero.focusId.startsWith("moment:") ? hero.focusId.slice("moment:".length) : null;
  const heroDuplicatesFeatured =
    !!hero &&
    featuredIdentity !== "pending" &&
    featuredIdentity !== null &&
    ((heroMomentId !== null && featuredIdentity.momentIds.includes(heroMomentId)) ||
      featuredIdentity.mediaIds.includes(hero.mediaId));
  const heroSettled = featuredIdentity !== "pending";

  // V121-M1 (C1.2) — hero media is signed ONLY when the hero will actually
  // render: a hero exists, the featured identity has settled, and the hero is
  // not a duplicate of the featured outcome. While pending or duplicate, the
  // sign target is null → no signed-media request is issued.
  const shouldSignHero = !!hero && heroSettled && !heroDuplicatesFeatured;
  const heroSignMediaId = shouldSignHero ? hero.mediaId : null;

  const signHeroMedia = useCallback(async () => {
    if (typeof window === "undefined") return;
    const seq = ++mediaSeqRef.current;
    // Reset in-box state whenever the sign target changes (or vanishes) so a
    // previous child's — or a now-suppressed hero's — signed image can never linger.
    setHeroMedia({ status: "loading", src: null });
    if (!heroSignMediaId) return;
    const requestMediaId = heroSignMediaId;
    const { data: signed, error } = await supabase.functions.invoke("get_signed_media_url", {
      body: { media_id: requestMediaId },
    });
    // Stale-response guard: only the latest signing request for the current
    // sign target may commit state.
    if (seq !== mediaSeqRef.current || requestMediaId !== heroSignMediaId) return;
    if (!error && signed?.allowed && signed?.signed_url) {
      const cardSrc = typeof signed?.variants?.card === "string" ? signed.variants.card : (signed.signed_url as string);

      setHeroMedia({ status: "ok", src: cardSrc });
    } else {
      setHeroMedia({ status: "failed", src: null });
    }
  }, [heroSignMediaId]);

  useEffect(() => {
    signHeroMedia();
  }, [signHeroMedia]);

  const selectedChild = children?.find((c) => c.id === selectedChildId) ?? null;
  const childName = selectedChild ? childLabel(selectedChild) : null;
  const familySignal = data ? newestFamilySignal(data) : null;
  const savedTotal = data
    ? data.creations.length +
      data.moments.filter((m) => m.media_id).length +
      data.journey.filter((e) => e.entry_type !== "badge").length
    : 0;
  const parentSaved = data ? data.journey.filter((e) => isParentMemory(e)).length : 0;
  const hasAnyItem = savedTotal > 0;
  const createLabel = `Ghi lại một điều về ${childName ?? "con"}`;

  const openComposer = () => {
    logParentEvent("parent_create_start", { route: "/parent" });
    setComposerOpen(true);
  };

  const bootLoading = loadingChildren || (!!children && children.length > 0 && !selectedChildId);

  return (
    <div className="space-y-6">
      {/* 1 · Identity */}
      <div>
        <p className="text-xs font-semibold tracking-wide text-dma-ink-gold uppercase">Cổng ba mẹ</p>
        <h1 className="mt-1.5 font-dma-serif text-3xl leading-tight text-dma-ink sm:text-4xl">
          {childName ? `Hôm nay của ${childName}` : "Hôm nay"}
        </h1>
        <p className="mt-2 max-w-xl text-sm leading-relaxed text-dma-ink-2">
          Nơi lưu lại hành trình lớn lên và sáng tạo của con — để ba mẹ cùng con nhìn lại.
        </p>
      </div>

      {/* 2 · ChildSwitcher (shared, persisted context) */}
      <ChildSwitcher />

      {bootLoading ? (
        <TruthState state="loading" title="Đang mở hành trình của con…" />
      ) : children && children.length === 0 ? (
        <TruthState
          state="empty"
          title="Chưa có hồ sơ con nào được liên kết với tài khoản này."
          description="Hồ sơ con do nhà trường tạo và liên kết. Ba mẹ vui lòng liên hệ nhà trường, hoặc gửi yêu cầu qua Hỗ trợ."
        >
          <div className="mt-5">
            <Link
              to="/portal/support"
              className="inline-flex min-h-11 items-center rounded-full bg-dma-emerald px-6 text-sm font-medium text-dma-ivory transition-colors hover:bg-dma-emerald-hover"
            >
              Mở Hỗ trợ →
            </Link>
          </div>
        </TruthState>
      ) : (
        <>
          {/* 3 · Daily Focus — primary Home content (own loading/empty/error) */}
          <ParentSessionOutcomeSection childId={selectedChildId} onFeaturedIdentity={handleFeaturedIdentity} />

          {/* 4 · Records continuation — the journal (records). Relabelled to
              "Nhật ký" (V126-M1) so the boundary stays clean vs the meaning
              bridge below: Nhật ký = records, Hành trình = meaning. */}
          <Link
            to="/parent/journal"
            className="group flex items-center gap-3 rounded-3xl border border-dma-hairline bg-dma-ivory-raised px-6 py-5 transition-colors hover:bg-dma-sage-tint/60"
          >
            <span className="min-w-0 flex-1">
              <span className="block font-dma-serif text-lg text-dma-ink">Nhật ký của {childName ?? "con"}</span>
              {hasAnyItem && (
                <span className="mt-1 block text-xs text-dma-ink-meta">
                  Đã lưu {savedTotal} điều
                  {parentSaved > 0 ? ` · ${parentSaved} do ba mẹ ghi lại` : ""}
                </span>
              )}
            </span>
            <ArrowRight
              className="h-4 w-4 shrink-0 text-dma-ink-meta transition-transform group-hover:translate-x-0.5"
              aria-hidden="true"
            />
          </Link>

          {/* 5 · Memory (demoted + deduped) + contextual create */}
          {journalError ? (
            <div
              role="status"
              aria-live="polite"
              className="rounded-3xl border border-dma-hairline bg-dma-ivory-raised p-6"
            >
              <p className="text-sm leading-relaxed text-dma-ink-2">Chưa mở được phần ký ức của con.</p>
              <button
                type="button"
                onClick={() => loadJournal()}
                className="mt-3 inline-flex min-h-11 items-center rounded-full border border-dma-hairline bg-dma-ivory-raised px-5 text-sm font-medium text-dma-ink-2 transition-colors hover:bg-dma-sage-tint"
              >
                Thử lại
              </button>
            </div>
          ) : !data || !heroSettled ? null : hero && !heroDuplicatesFeatured ? (
            <>
              <MemoryHero
                kindLabel={hero.kindLabel}
                title={hero.title}
                blurb={hero.blurb}
                dateLabel={hero.dateLabel}
                mediaStatus={heroMedia.status}
                mediaSrc={heroMedia.src}
                focusId={hero.focusId}
                onRetryMedia={signHeroMedia}
              />
              <div>
                <button
                  type="button"
                  onClick={openComposer}
                  disabled={!selectedChildId}
                  className="inline-flex min-h-11 items-center gap-2 rounded-full border border-dma-hairline bg-dma-ivory-raised px-5 text-sm font-medium text-dma-ink-2 transition-colors hover:bg-dma-sage-tint"
                >
                  <Plus className="h-4 w-4" aria-hidden="true" />
                  {createLabel}
                </button>
              </div>
            </>
          ) : (
            <div className="rounded-3xl border border-dma-hairline bg-dma-ivory-raised p-6">
              <p className="font-dma-serif text-lg text-dma-ink">
                {hasAnyItem
                  ? `Ghi thêm một điều về ${childName ?? "con"}`
                  : `Bắt đầu hành trình của ${childName ?? "con"}`}
              </p>
              <p className="mt-1.5 text-sm leading-relaxed text-dma-ink-2">
                {hasAnyItem
                  ? "Mỗi bức tranh, câu nói hay khoảnh khắc nhỏ đều có thể trở thành một phần trong hành trình của con."
                  : "Mỗi bức tranh, câu nói, đoạn ghi âm hay khoảnh khắc nhỏ đều có thể trở thành một phần trong hành trình lớn lên của con."}
              </p>
              {selectedChildId && (
                <div className="mt-4">
                  <button
                    type="button"
                    onClick={openComposer}
                    className="inline-flex min-h-11 items-center gap-2 rounded-full border border-dma-hairline bg-dma-ivory-raised px-5 text-sm font-medium text-dma-ink-2 transition-colors hover:bg-dma-sage-tint"
                  >
                    <Plus className="h-4 w-4" aria-hidden="true" />
                    {createLabel}
                  </button>
                </div>
              )}
            </div>
          )}

          {/* 6 · Quiet family signal — preserved journal entries only */}
          {familySignal && (
            <Link
              to="/parent/journal"
              search={{ focus: familySignal.ev.id }}
              className="group block rounded-3xl border border-dma-champagne-soft bg-dma-ivory-raised p-6 transition-colors hover:bg-dma-sage-tint/50"
            >
              <p className="text-xs font-semibold tracking-wide text-dma-ink-gold uppercase">Từ Không gian gia đình</p>
              <p className="mt-2 font-dma-serif text-lg text-dma-ink">
                {familySignal.fp.card_title || familySignal.fp.contribution_body || "Một kỷ niệm được gia đình giữ lại"}
              </p>
              <p className="mt-1.5 text-xs text-dma-ink-meta">
                Được {familySignal.fp.preserved_by_name || "người thân"} giữ vào Hành trình ·{" "}
                {formatViDate(familySignal.ev.occurredAt)}
              </p>
            </Link>
          )}

          {/* 7 · Hành trình của con — readiness-aware meaning bridge (V126-M1).
              Bridge only → /parent/discovery ("Nhìn lại"). Capsule items are
              never rendered inline. */}
          <MeaningBridge childId={selectedChildId} />
        </>
      )}

      {selectedChildId && (
        <ParentMemoryComposer
          open={composerOpen}
          onOpenChange={setComposerOpen}
          childId={selectedChildId}
          childName={childName ?? "con"}
          onSaved={(_memoryId, journeyId) => {
            loadJournal();
            navigate({
              to: "/parent/journal",
              search: journeyId ? { focus: `journey:${journeyId}` } : {},
            });
          }}
        />
      )}
    </div>
  );
}
