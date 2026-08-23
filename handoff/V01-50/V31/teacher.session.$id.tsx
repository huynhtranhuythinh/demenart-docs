import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useEffect, useMemo, useState } from "react";
import {
  Loader2,
  Play,
  Flag,
  Check,
  ListChecks,
  Clock,
  Users,
  ChevronLeft,
  ChevronRight,
  Sparkles,
  CheckCircle2,
  Circle,
  Music,
} from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { useCurrentProfile } from "@/hooks/use-current-profile";

export const Route = createFileRoute("/_authenticated/teacher/session/$id")({
  component: SessionFlow,
});

// ===== màu hệ (D98) =====
const INK = "#0F6E56";
const FOREST = "#149A76";
const HONEY = "#EFA63A";
const HONEY_BG = "#FCEFD6";
const HONEY_TEXT = "#8A5410";
const CARD = "#FFFFFF";
const MUTED = "#6B6357";
const FAINT = "#9A9183";
const LINE = "#EFE7D6";

type PrepItem = { id: string; label: string; is_ready: boolean; sort_order: number };
type Readiness = { ok: boolean; status: string; state: string; prep?: { ready: number; total: number } };
type SessionInfo = {
  id: string;
  title: string | null;
  state: string;
  scheduled_at: string | null;
  duration_min: number | null;
  class_name: string | null;
  program_name: string | null;
  child_count: number;
  readiness?: Readiness;
};
type Detail = { ok: boolean; reason?: string; session: SessionInfo; prep_items: PrepItem[] };

const STEPS = ["Chuẩn bị", "Dạy học", "Ghi nhận", "Nhật ký"];

function stepForState(state: string): number {
  if (state === "in_progress") return 2;
  if (state === "taught_report_pending" || state === "report_pending_approval") return 4;
  if (state === "completed") return 4;
  return 1; // scheduled / prep_ready / makeup / cancelled
}

function fmtTime(iso: string | null) {
  if (!iso) return "—";
  try {
    return new Date(iso).toLocaleTimeString("vi-VN", { hour: "2-digit", minute: "2-digit" });
  } catch {
    return "—";
  }
}

function SessionFlow() {
  const { id } = Route.useParams();
  const { profile } = useCurrentProfile();
  const [detail, setDetail] = useState<Detail | null>(null);
  const [err, setErr] = useState<string | null>(null);
  const [step, setStep] = useState<number>(1);

  async function loadDetail(setStepFromState = false) {
    const { data, error } = await supabase.rpc("get_session_detail" as never, { p_session_id: id } as never);
    if (error || !(data as any)?.ok) {
      setErr(((data as any)?.reason as string) || "load_error");
      return;
    }
    const d = data as unknown as Detail;
    setDetail(d);
    if (setStepFromState) setStep(stepForState(d.session.state));
  }

  useEffect(() => {
    if (typeof window === "undefined") return;
    loadDetail(true);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  if (err) {
    return (
      <div className="space-y-4">
        <BackLink />
        <div className="rounded-xl px-4 py-3 text-sm" style={{ backgroundColor: HONEY_BG, color: HONEY_TEXT }}>
          {err === "forbidden"
            ? "Cô không có quyền xem buổi học này."
            : err === "not_found"
            ? "Không tìm thấy buổi học."
            : "Không tải được buổi học. Cô thử lại nhé."}
        </div>
      </div>
    );
  }

  if (!detail) {
    return (
      <div className="space-y-4">
        <BackLink />
        <div className="flex items-center gap-2 text-sm" style={{ color: MUTED }}>
          <Loader2 className="h-4 w-4 animate-spin" /> Đang mở buổi học…
        </div>
      </div>
    );
  }

  const s = detail.session;

  return (
    <div className="space-y-5">
      <BackLink />

      {/* tiêu đề buổi */}
      <header className="space-y-1">
        <div className="flex items-center gap-2">
          <span
            className="inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium"
            style={{ backgroundColor: "#E3F3EC", color: INK }}
          >
            ♪ {s.program_name ?? "CTAN"}
          </span>
        </div>
        <h1 className="text-xl font-semibold" style={{ color: "#1F2421" }}>
          {s.class_name ?? "Lớp"}
        </h1>
        <p className="text-sm" style={{ color: MUTED }}>
          {s.title ?? "Buổi học"}
        </p>
        <div className="flex items-center gap-3 text-xs" style={{ color: FAINT }}>
          <span className="inline-flex items-center gap-1">
            <Clock className="h-3.5 w-3.5" /> {fmtTime(s.scheduled_at)}
          </span>
          <span className="inline-flex items-center gap-1">
            <Users className="h-3.5 w-3.5" /> {s.child_count} bé
          </span>
        </div>
      </header>

      {/* stepper */}
      <Stepper current={step} maxState={s.state} onJump={setStep} />

      {/* nội dung bước */}
      {step === 1 && <StepPrep detail={detail} profileId={profile?.id ?? null} onChanged={loadDetail} onStart={() => setStep(2)} />}
      {step === 2 && <StepTeach session={s} onBack={() => setStep(1)} onNext={() => setStep(3)} />}
      {step === 3 && <StepPlaceholder title="Ghi nhận" desc="Điểm danh · Ghi nhận · Ảnh gắn bé — sẽ có ở bản cập nhật tới." onBack={() => setStep(2)} />}
      {step === 4 && <StepPlaceholder title="Nhật ký" desc="Xem lại & gửi nhật ký cho ba mẹ — sẽ có ở bản cập nhật tới." onBack={() => setStep(3)} />}
    </div>
  );
}

function BackLink() {
  return (
    <Link to="/teacher" className="inline-flex items-center gap-1 text-sm" style={{ color: MUTED }}>
      <ChevronLeft className="h-4 w-4" /> Hôm nay
    </Link>
  );
}

function Stepper({ current, maxState, onJump }: { current: number; maxState: string; onJump: (n: number) => void }) {
  const reached = stepForState(maxState); // bước cao nhất đã mở theo state thật
  return (
    <div className="flex items-center">
      {STEPS.map((label, i) => {
        const n = i + 1;
        const done = n < current;
        const active = n === current;
        const unlocked = n <= Math.max(reached, current); // chỉ cho nhảy tới bước đã mở
        const color = active ? FOREST : done ? INK : FAINT;
        return (
          <div key={label} className="flex items-center" style={{ flex: i < STEPS.length - 1 ? 1 : "0 0 auto" }}>
            <button
              type="button"
              disabled={!unlocked}
              onClick={() => unlocked && onJump(n)}
              className="flex flex-col items-center gap-1 disabled:opacity-50"
            >
              <span
                className="inline-flex h-7 w-7 items-center justify-center rounded-full text-xs font-semibold"
                style={{
                  backgroundColor: active ? FOREST : done ? "#E3F3EC" : "#EEE9DF",
                  color: active ? "#fff" : color,
                }}
              >
                {done ? <Check className="h-4 w-4" /> : n}
              </span>
              <span className="text-[10px]" style={{ color }}>
                {label}
              </span>
            </button>
            {i < STEPS.length - 1 && (
              <span className="mx-1 h-[2px] flex-1 rounded-full" style={{ backgroundColor: n < current ? INK : "#EEE9DF" }} />
            )}
          </div>
        );
      })}
    </div>
  );
}

// ===== Bước 1: Chuẩn bị =====
function StepPrep({
  detail,
  profileId,
  onChanged,
  onStart,
}: {
  detail: Detail;
  profileId: string | null;
  onChanged: () => void;
  onStart: () => void;
}) {
  const items = detail.prep_items;
  const ready = items.filter((i) => i.is_ready).length;
  const total = items.length;
  const [busyId, setBusyId] = useState<string | null>(null);
  const [starting, setStarting] = useState(false);
  const [reporting, setReporting] = useState(false);
  const [reported, setReported] = useState(false);
  const sid = detail.session.id;
  const alreadyInProgress = detail.session.state === "in_progress";

  async function toggle(it: PrepItem) {
    setBusyId(it.id);
    const { error } = await (supabase as any)
      .from("prep_items")
      .update({ is_ready: !it.is_ready })
      .eq("id", it.id);
    setBusyId(null);
    if (!error) onChanged();
  }

  async function start() {
    setStarting(true);
    const { data, error } = await supabase.rpc("start_session" as never, { p_session_id: sid } as never);
    setStarting(false);
    if (!error && (data as any)?.ok) {
      onStart();
    }
  }

  async function reportMissing() {
    if (!profileId) return;
    setReporting(true);
    const { error } = await (supabase as any).from("support_requests").insert({
      requester_profile_id: profileId,
      category: "curriculum",
      message: `[Báo thiếu học liệu] Buổi "${detail.session.title ?? ""}" — lớp ${
        detail.session.class_name ?? ""
      } (session ${sid}).`,
    });
    setReporting(false);
    if (!error) setReported(true);
  }

  return (
    <div className="space-y-4">
      {/* checklist chuẩn bị */}
      <section className="rounded-2xl p-4 shadow-sm" style={{ backgroundColor: CARD, border: `1px solid ${LINE}` }}>
        <div className="flex items-center justify-between">
          <span className="inline-flex items-center gap-2 text-sm font-semibold" style={{ color: "#1F2421" }}>
            <ListChecks className="h-4 w-4" style={{ color: FOREST }} />
            Chuẩn bị ({ready}/{total})
          </span>
        </div>
        <div className="mt-3 h-1.5 w-full rounded-full" style={{ backgroundColor: "#EEE9DF" }}>
          <div
            className="h-1.5 rounded-full transition-all"
            style={{ width: `${total ? (ready / total) * 100 : 0}%`, backgroundColor: HONEY }}
          />
        </div>

        <div className="mt-3 divide-y" style={{ borderColor: LINE }}>
          {items.length === 0 && (
            <p className="py-3 text-sm" style={{ color: FAINT }}>
              Buổi này chưa có mục chuẩn bị. Cô có thể vào dạy luôn.
            </p>
          )}
          {items.map((it) => (
            <button
              key={it.id}
              type="button"
              onClick={() => toggle(it)}
              disabled={busyId === it.id}
              className="flex w-full items-center gap-3 py-3 text-left disabled:opacity-60"
            >
              {it.is_ready ? (
                <CheckCircle2 className="h-5 w-5 shrink-0" style={{ color: FOREST }} />
              ) : (
                <Circle className="h-5 w-5 shrink-0" style={{ color: FAINT }} />
              )}
              <span className="text-sm" style={{ color: it.is_ready ? FAINT : "#1F2421", textDecoration: it.is_ready ? "line-through" : "none" }}>
                {it.label}
              </span>
            </button>
          ))}
        </div>
      </section>

      {/* báo thiếu học liệu (D75 — GV KHÔNG thay học liệu, chỉ báo) */}
      <section className="rounded-2xl p-4" style={{ backgroundColor: HONEY_BG, border: `1px solid #F0DDB6` }}>
        <p className="text-sm font-medium" style={{ color: HONEY_TEXT }}>
          Học liệu có vấn đề?
        </p>
        <p className="mt-0.5 text-xs" style={{ color: HONEY_TEXT, opacity: 0.85 }}>
          Cô báo để đội ngũ Dế Mèn xử lý — học liệu do Dế Mèn biên soạn.
        </p>
        {reported ? (
          <p className="mt-3 inline-flex items-center gap-1.5 text-sm font-medium" style={{ color: INK }}>
            <Check className="h-4 w-4" /> Đã gửi báo cáo. Cảm ơn cô!
          </p>
        ) : (
          <button
            type="button"
            onClick={reportMissing}
            disabled={reporting || !profileId}
            className="mt-3 inline-flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-semibold disabled:opacity-60"
            style={{ backgroundColor: HONEY, color: "#3D2606" }}
          >
            {reporting ? <Loader2 className="h-4 w-4 animate-spin" /> : <Flag className="h-4 w-4" />}
            Báo thiếu học liệu
          </button>
        )}
      </section>

      {/* CTA vào dạy */}
      <button
        type="button"
        onClick={start}
        disabled={starting}
        className="w-full inline-flex items-center justify-center gap-2 rounded-xl py-3.5 text-sm font-semibold disabled:opacity-70"
        style={{ backgroundColor: FOREST, color: "#fff" }}
      >
        {starting ? <Loader2 className="h-4 w-4 animate-spin" /> : <Play className="h-4 w-4" />}
        {alreadyInProgress ? "Tiếp tục buổi học" : "Vào dạy"}
        <ChevronRight className="h-4 w-4" />
      </button>
    </div>
  );
}

// ===== Bước 2: Dạy học (Lesson Player — mượn pattern D75/v13) =====
type Track = {
  media_id: string;
  title: string;
  file_type: string | null;
  watermark_required: boolean;
  stream_only: boolean;
  download_allowed: boolean;
};
type ActiveTrack = { mediaId: string; url: string; watermark: boolean; startedAt: string };

function mapMediaReason(reason: string): string {
  switch (reason) {
    case "not_authenticated":
      return "Phiên đăng nhập đã hết hạn — cô đăng nhập lại nhé.";
    case "not_school_member":
    case "no_active_entitlement":
      return "Trường chưa kích hoạt môn học này.";
    case "media_not_found":
      return "Không tìm thấy học liệu.";
    default:
      return "Không phát được học liệu lúc này.";
  }
}

function StepTeach({ session, onBack, onNext }: { session: SessionInfo; onBack: () => void; onNext: () => void }) {
  const { user, profile } = useCurrentProfile();
  const [tracks, setTracks] = useState<Track[] | null>(null);
  const [listErr, setListErr] = useState<string | null>(null);
  const [loadingId, setLoadingId] = useState<string | null>(null);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [active, setActive] = useState<ActiveTrack | null>(null);
  const [schoolLabel, setSchoolLabel] = useState<string>("");

  useEffect(() => {
    if (typeof window === "undefined") return;
    let alive = true;
    (async () => {
      const { data, error } = await supabase.rpc("get_session_curriculum" as never, {
        p_session_id: session.id,
      } as never);
      if (!alive) return;
      if (error || !(data as any)?.ok) {
        setListErr("Không tải được học liệu của buổi.");
        setTracks([]);
        return;
      }
      setTracks(((data as any).tracks as Track[]) ?? []);
    })();
    return () => {
      alive = false;
    };
  }, [session.id]);

  useEffect(() => {
    if (!profile?.school_id) return;
    let alive = true;
    (async () => {
      const { data } = await (supabase as any)
        .from("schools")
        .select("name")
        .eq("id", profile.school_id)
        .maybeSingle();
      if (alive && data?.name) setSchoolLabel(data.name);
    })();
    return () => {
      alive = false;
    };
  }, [profile?.school_id]);

  async function playTrack(mediaId: string) {
    setLoadingId(mediaId);
    setErrors((e) => {
      const n = { ...e };
      delete n[mediaId];
      return n;
    });
    const { data, error } = await supabase.functions.invoke("get_signed_media_url", {
      body: { media_id: mediaId },
    });
    if (error) {
      let reason = "unknown";
      try {
        const ctx = await (error as any).context?.json?.();
        reason = ctx?.reason || ctx?.error || reason;
      } catch {
        /* noop */
      }
      setErrors((e) => ({ ...e, [mediaId]: mapMediaReason(reason) }));
      setLoadingId(null);
      return;
    }
    setActive({
      mediaId,
      url: (data as any).signed_url,
      watermark: !!(data as any).watermark_required,
      startedAt: new Date().toLocaleString("vi-VN"),
    });
    setLoadingId(null);
  }

  return (
    <div className="space-y-4">
      <section className="rounded-2xl p-4 shadow-sm" style={{ backgroundColor: CARD, border: `1px solid ${LINE}` }}>
        <h3 className="mb-3 inline-flex items-center gap-2 text-sm font-semibold" style={{ color: "#1F2421" }}>
          <Music className="h-4 w-4" style={{ color: FOREST }} /> Học liệu buổi học
        </h3>

        {listErr && (
          <p className="text-sm" style={{ color: HONEY_TEXT }}>
            {listErr}
          </p>
        )}

        {tracks === null && (
          <div className="flex items-center gap-2 text-sm" style={{ color: MUTED }}>
            <Loader2 className="h-4 w-4 animate-spin" /> Đang tải học liệu…
          </div>
        )}

        {tracks && tracks.length === 0 && !listErr && (
          <p className="text-sm" style={{ color: FAINT }}>
            Buổi này chưa có học liệu đính kèm.
          </p>
        )}

        {tracks && tracks.length > 0 && (
          <div className="space-y-3">
            {tracks.map((t) => {
              const isActive = active?.mediaId === t.media_id;
              return (
                <div key={t.media_id} className="rounded-xl" style={{ border: `1px solid ${LINE}` }}>
                  <div className="flex items-center justify-between gap-3 px-4 py-3">
                    <span className="text-sm font-medium" style={{ color: "#1F2421" }}>
                      {t.title}
                    </span>
                    <button
                      type="button"
                      onClick={() => playTrack(t.media_id)}
                      disabled={loadingId === t.media_id}
                      className="inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-sm font-semibold disabled:opacity-60"
                      style={{ backgroundColor: FOREST, color: "#fff" }}
                    >
                      {loadingId === t.media_id ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <Play className="h-4 w-4" />
                      )}
                      {isActive ? "Phát lại" : "Phát"}
                    </button>
                  </div>
                  {errors[t.media_id] && (
                    <p className="px-4 pb-3 text-xs" style={{ color: HONEY_TEXT }}>
                      {errors[t.media_id]}
                    </p>
                  )}
                  {isActive && active && (
                    <PlayerPanel
                      active={active}
                      userEmail={user?.email ?? ""}
                      schoolLabel={schoolLabel}
                      onExpired={() =>
                        setErrors((e) => ({ ...e, [t.media_id]: "Liên kết đã hết hạn — bấm Phát lại." }))
                      }
                    />
                  )}
                </div>
              );
            })}
          </div>
        )}
      </section>

      <div className="flex items-center gap-2.5">
        <button
          type="button"
          onClick={onBack}
          className="inline-flex items-center gap-1.5 rounded-xl px-4 py-3 text-sm font-medium"
          style={{ backgroundColor: "#fff", color: INK, border: `1.5px solid ${FOREST}` }}
        >
          <ChevronLeft className="h-4 w-4" /> Quay lại
        </button>
        <button
          type="button"
          onClick={onNext}
          className="flex-1 inline-flex items-center justify-center gap-2 rounded-xl py-3 text-sm font-semibold"
          style={{ backgroundColor: FOREST, color: "#fff" }}
        >
          Tiếp tục — Ghi nhận <ChevronRight className="h-4 w-4" />
        </button>
      </div>
    </div>
  );
}

function PlayerPanel({
  active,
  userEmail,
  schoolLabel,
  onExpired,
}: {
  active: ActiveTrack;
  userEmail: string;
  schoolLabel: string;
  onExpired: () => void;
}) {
  const watermarkText = useMemo(() => {
    const parts = ["DMA", "CTAN"];
    if (schoolLabel) parts.push(schoolLabel);
    if (userEmail) parts.push(userEmail);
    parts.push(active.startedAt);
    return parts.join(" · ");
  }, [schoolLabel, userEmail, active.startedAt]);

  return (
    <div
      className="relative border-t p-4"
      style={{ borderColor: LINE, backgroundColor: "#FBF8F1" }}
      onContextMenu={(e) => e.preventDefault()}
    >
      <audio
        src={active.url}
        controls
        controlsList="nodownload noplaybackrate"
        onContextMenu={(e) => e.preventDefault()}
        onError={onExpired}
        className="w-full"
      />
      {active.watermark && (
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 overflow-hidden select-none"
          style={{ userSelect: "none" }}
        >
          <div
            className="absolute whitespace-nowrap text-xs font-medium"
            style={{ top: "50%", left: 0, color: "#0F6E56", opacity: 0.18, animation: "wm-drift 12s linear infinite" }}
          >
            {watermarkText}
          </div>
        </div>
      )}
      <style>{`@keyframes wm-drift { 0% { transform: translate(-30%, -20px);} 50% { transform: translate(40%, 20px);} 100% { transform: translate(-30%, -20px);} }`}</style>
    </div>
  );
}

// ===== Bước 3-4: placeholder (Cụm sau) =====
function StepPlaceholder({ title, desc, onBack }: { title: string; desc: string; onBack: () => void }) {
  return (
    <section className="rounded-2xl p-8 text-center shadow-sm" style={{ backgroundColor: CARD, border: `1px solid ${LINE}` }}>
      <span
        className="mx-auto mb-3 inline-flex h-14 w-14 items-center justify-center rounded-full"
        style={{ backgroundColor: HONEY_BG }}
      >
        <Sparkles className="h-7 w-7" style={{ color: HONEY }} />
      </span>
      <h2 className="text-lg font-semibold" style={{ color: INK }}>
        {title}
      </h2>
      <p className="mx-auto mt-1 max-w-xs text-sm" style={{ color: MUTED }}>
        {desc}
      </p>
      <button
        type="button"
        onClick={onBack}
        className="mt-4 inline-flex items-center gap-1.5 rounded-xl px-4 py-2.5 text-sm font-medium"
        style={{ backgroundColor: "#fff", color: INK, border: `1.5px solid ${FOREST}` }}
      >
        <ChevronLeft className="h-4 w-4" /> Quay lại
      </button>
    </section>
  );
}
