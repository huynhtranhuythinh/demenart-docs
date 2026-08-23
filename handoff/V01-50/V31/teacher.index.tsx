import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import {
  Loader2,
  Play,
  Flag,
  Pencil,
  Eye,
  Lock,
  Send,
  ListChecks,
  Clock,
  Users,
  ClipboardList,
  Camera,
  NotebookPen,
  LifeBuoy,
  ChevronRight,
  Coffee,
  PartyPopper,
} from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { useCurrentProfile } from "@/hooks/use-current-profile";

export const Route = createFileRoute("/_authenticated/teacher/")({
  component: TeacherHome,
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

type Readiness = {
  ok: boolean;
  status: string;
  state: string;
  prep?: { ready: number; total: number };
};
type Sess = {
  id: string;
  title: string | null;
  state: string;
  class_name: string | null;
  program_name: string | null;
  child_count: number;
  scheduled_at: string | null;
  readiness?: Readiness;
};
type HomeData = {
  ok: boolean;
  today_count: number;
  today_session: Sess | null;
  next_session: Sess | null;
};

// counts "Việc cần làm" (mig 047 — Dashboard-LITE, D99)
type TodoCounts = {
  ok: boolean;
  total: number;
  counts: {
    attendance_pending: number;
    journal_pending: number;
    photos_untagged: number;
    parent_replies: number;
  };
};

// map status → pill + CTA (§8b)
type StatusMeta = {
  pill: string;
  tone: "ready" | "honey" | "muted";
  cta: string | null;
  ctaIcon: any;
  ctaStyle: "primary" | "honey" | "ghost" | "outline" | null;
};

const STATUS_MAP: Record<string, StatusMeta> = {
  ready: { pill: "Giáo án sẵn sàng", tone: "ready", cta: "Bắt đầu buổi học", ctaIcon: Play, ctaStyle: "primary" },
  missing_materials: {
    pill: "Thiếu học liệu",
    tone: "honey",
    cta: "Báo thiếu học liệu",
    ctaIcon: Flag,
    ctaStyle: "honey",
  },
  needs_update: {
    pill: "Cần cập nhật bài học",
    tone: "honey",
    cta: "Cập nhật bài học",
    ctaIcon: Pencil,
    ctaStyle: "honey",
  },
  unassigned: {
    pill: "Chưa phân công lớp",
    tone: "muted",
    cta: "Chưa có lớp để bắt đầu",
    ctaIcon: Lock,
    ctaStyle: "ghost",
  },
  in_progress: { pill: "Đang diễn ra", tone: "honey", cta: "Tiếp tục buổi học", ctaIcon: Play, ctaStyle: "primary" },
  report_pending: {
    pill: "Chờ gửi nhật ký",
    tone: "honey",
    cta: "Hoàn tất & gửi nhật ký",
    ctaIcon: Send,
    ctaStyle: "honey",
  },
  completed: { pill: "Đã hoàn tất", tone: "ready", cta: "Xem lại buổi học", ctaIcon: Eye, ctaStyle: "outline" },
  cancelled: { pill: "Đã huỷ / dời", tone: "muted", cta: null, ctaIcon: Lock, ctaStyle: null },
};

function pillStyle(tone: "ready" | "honey" | "muted") {
  if (tone === "ready") return { backgroundColor: "#E3F3EC", color: INK };
  if (tone === "honey") return { backgroundColor: HONEY_BG, color: HONEY_TEXT };
  return { backgroundColor: "#EEE9DF", color: FAINT };
}

function fmtTime(iso: string | null) {
  if (!iso) return "—";
  try {
    return new Date(iso).toLocaleTimeString("vi-VN", { hour: "2-digit", minute: "2-digit" });
  } catch {
    return "—";
  }
}

function TeacherHome() {
  const { profile, user } = useCurrentProfile();
  const [data, setData] = useState<HomeData | null>(null);
  const [counts, setCounts] = useState<TodoCounts | null>(null);
  const [err, setErr] = useState(false);

  useEffect(() => {
    if (typeof window === "undefined") return;
    let alive = true;
    (async () => {
      // gọi song song: Home (chặn) + counts (không chặn — lỗi counts vẫn render Home)
      const [homeRes, todoRes] = await Promise.all([
        supabase.rpc("get_teacher_home" as never),
        supabase.rpc("get_teacher_todo_counts" as never),
      ]);
      if (!alive) return;

      const d = homeRes.data;
      if (homeRes.error || !(d as any)?.ok) {
        setErr(true);
        return;
      }
      setData(d as unknown as HomeData);

      const t = todoRes.data;
      if (!todoRes.error && (t as any)?.ok) {
        setCounts(t as unknown as TodoCounts);
      }
    })();
    return () => {
      alive = false;
    };
  }, []);

  const firstName = (profile?.full_name ?? "").split(" ").slice(-1)[0] || "";
  const today = new Date();
  const dateLabel = today.toLocaleDateString("vi-VN", { weekday: "long", day: "numeric", month: "numeric" });

  return (
    <div className="space-y-5">
      {/* 1. Greeting */}
      <header className="space-y-0.5">
        <h1 className="text-2xl" style={{ fontFamily: "Georgia, serif", color: INK }}>
          Chào cô {firstName || (user?.email ?? "")}
        </h1>
        <p className="text-sm" style={{ color: MUTED }}>
          {dateLabel}
          {data ? (
            <>
              {" "}
              · <span style={{ fontWeight: 600 }}>{data.today_count} tiết</span> hôm nay
            </>
          ) : null}
        </p>
      </header>

      {err && (
        <div className="rounded-xl px-4 py-3 text-sm" style={{ backgroundColor: HONEY_BG, color: HONEY_TEXT }}>
          Không tải được thông tin hôm nay. Cô thử tải lại trang nhé.
        </div>
      )}

      {!data && !err && (
        <div className="flex items-center gap-2 text-sm" style={{ color: MUTED }}>
          <Loader2 className="h-4 w-4 animate-spin" /> Đang chuẩn bị phòng giáo viên…
        </div>
      )}

      {data && !data.today_session && <EmptyToday next={data.next_session} />}

      {data && data.today_session && (
        <>
          <HeroCard s={data.today_session} />
          <PrepPreview s={data.today_session} />
          <TodoSection counts={counts} />
          <QuickActions />
          {data.next_session && <NextClass s={data.next_session} />}
          <SupportSection />
        </>
      )}
    </div>
  );
}

// ===== 2. Hero teaching card =====
function HeroCard({ s }: { s: Sess }) {
  const navigate = useNavigate();
  const r = s.readiness;
  const map = (r?.status && STATUS_MAP[r.status]) || STATUS_MAP.ready;
  const CtaIcon = map.ctaIcon;

  function ctaStyle(): React.CSSProperties {
    switch (map.ctaStyle) {
      case "primary":
        return { backgroundColor: FOREST, color: "#fff" };
      case "honey":
        return { backgroundColor: HONEY, color: "#3D2606" };
      case "outline":
        return { backgroundColor: "#fff", color: INK, border: `1.5px solid ${FOREST}` };
      case "ghost":
        return { backgroundColor: "#EEE9DF", color: FAINT };
      default:
        return { backgroundColor: "#EEE9DF", color: FAINT };
    }
  }
  const locked = map.ctaStyle === "ghost" || map.ctaStyle === null;

  function onCta() {
    if (locked) return;
    navigate({ to: "/teacher/session/$id", params: { id: s.id } });
  }

  return (
    <section className="rounded-2xl p-5 shadow-sm" style={{ backgroundColor: CARD, border: `1px solid ${LINE}` }}>
      <div className="flex items-start justify-between gap-3">
        <span
          className="inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium"
          style={{ backgroundColor: "#E3F3EC", color: INK }}
        >
          ♪ {s.program_name ?? "CTAN"}
        </span>
        <span
          className="inline-flex items-center rounded-full px-2.5 py-1 text-xs font-semibold"
          style={pillStyle(map.tone)}
        >
          {map.pill}
        </span>
      </div>

      <h2 className="mt-3 text-xl font-semibold" style={{ color: "#1F2421" }}>
        {s.class_name ?? "Lớp"}
      </h2>
      <p className="text-sm" style={{ color: MUTED }}>
        {s.title ?? "Buổi học"}
      </p>

      <div className="mt-2 flex items-center gap-3 text-xs" style={{ color: FAINT }}>
        <span className="inline-flex items-center gap-1">
          <Clock className="h-3.5 w-3.5" /> {fmtTime(s.scheduled_at)}
        </span>
        <span className="inline-flex items-center gap-1">
          <Users className="h-3.5 w-3.5" /> {s.child_count} bé
        </span>
      </div>

      <div className="mt-3 flex items-center gap-1.5 text-[11px]" style={{ color: FAINT }}>
        <span>Chuẩn bị</span>
        <ChevronRight className="h-3 w-3" />
        <span>Dạy học</span>
        <ChevronRight className="h-3 w-3" />
        <span>Ghi nhận</span>
        <ChevronRight className="h-3 w-3" />
        <span>Nhật ký</span>
      </div>

      {map.cta && (
        <button
          type="button"
          disabled={locked}
          onClick={onCta}
          className="mt-4 w-full inline-flex items-center justify-center gap-2 rounded-xl py-3 text-sm font-semibold transition-opacity disabled:opacity-70"
          style={ctaStyle()}
        >
          <CtaIcon className="h-4 w-4" /> {map.cta}
        </button>
      )}
    </section>
  );
}

// ===== 3. Prep preview =====
function PrepPreview({ s }: { s: Sess }) {
  const p = s.readiness?.prep ?? { ready: 0, total: 0 };
  if (p.total === 0) return null;
  return (
    <Link
      to="/teacher/session/$id"
      params={{ id: s.id }}
      className="block rounded-2xl p-4 shadow-sm"
      style={{ backgroundColor: CARD, border: `1px solid ${LINE}` }}
    >
      <div className="flex items-center justify-between">
        <span className="inline-flex items-center gap-2 text-sm font-medium" style={{ color: "#1F2421" }}>
          <ListChecks className="h-4 w-4" style={{ color: FOREST }} />
          Chuẩn bị ({p.ready}/{p.total})
        </span>
        <span className="inline-flex items-center text-xs" style={{ color: FOREST }}>
          Xem chuẩn bị <ChevronRight className="h-3.5 w-3.5" />
        </span>
      </div>
      <div className="mt-3 h-1.5 w-full rounded-full" style={{ backgroundColor: "#EEE9DF" }}>
        <div
          className="h-1.5 rounded-full"
          style={{ width: `${p.total ? (p.ready / p.total) * 100 : 0}%`, backgroundColor: HONEY }}
        />
      </div>
    </Link>
  );
}

// ===== 4. Việc cần làm (wire mig 047 — get_teacher_todo_counts) =====
function TodoSection({ counts }: { counts: TodoCounts | null }) {
  const c = counts?.counts;
  const items = [
    { label: "Lớp chưa điểm danh", icon: ClipboardList, count: c?.attendance_pending ?? 0, parent: false },
    { label: "Nhật ký chờ gửi", icon: Send, count: c?.journal_pending ?? 0, parent: false },
    { label: "Ảnh/video chưa gắn bé", icon: Camera, count: c?.photos_untagged ?? 0, parent: false },
    { label: "Phản hồi phụ huynh mới", icon: NotebookPen, count: c?.parent_replies ?? 0, parent: true },
  ];
  const total = counts?.total ?? 0;

  return (
    <section>
      <h3 className="mb-2 text-sm font-semibold" style={{ color: "#1F2421" }}>
        Việc cần làm hôm nay
      </h3>

      {total === 0 ? (
        <div
          className="rounded-2xl px-4 py-4 flex items-center gap-2.5 text-sm"
          style={{ backgroundColor: CARD, border: `1px solid ${LINE}`, color: MUTED }}
        >
          <span
            className="inline-flex h-7 w-7 items-center justify-center rounded-full"
            style={{ backgroundColor: "#E3F3EC" }}
          >
            <PartyPopper className="h-4 w-4" style={{ color: FOREST }} />
          </span>
          Mọi việc đã xong — cô thật tuyệt!
        </div>
      ) : (
        <div
          className="rounded-2xl divide-y"
          style={{ backgroundColor: CARD, border: `1px solid ${LINE}`, borderColor: LINE }}
        >
          {items.map((it) => {
            const Icon = it.icon;
            const active = it.count > 0;
            return (
              <div
                key={it.label}
                className="flex items-center justify-between px-4 py-3"
                style={{ opacity: active ? 1 : 0.55 }}
              >
                <span className="inline-flex items-center gap-2.5 text-sm" style={{ color: MUTED }}>
                  <Icon
                    className="h-4 w-4"
                    style={{ color: active ? (it.parent ? FOREST : HONEY_TEXT) : FAINT }}
                  />{" "}
                  {it.label}
                </span>
                {active ? (
                  <span
                    className="min-w-[20px] h-5 px-1.5 rounded-full text-[11px] font-semibold flex items-center justify-center text-white"
                    style={{ backgroundColor: it.parent ? FOREST : HONEY }}
                  >
                    {it.count}
                  </span>
                ) : (
                  <span className="text-xs" style={{ color: FAINT }}>
                    —
                  </span>
                )}
              </div>
            );
          })}
        </div>
      )}
    </section>
  );
}

// ===== 5. Quick actions =====
function QuickActions() {
  const acts = [
    { label: "Chuẩn bị", icon: ListChecks },
    { label: "Điểm danh", icon: ClipboardList },
    { label: "Ghi nhận", icon: NotebookPen },
    { label: "Khoảnh khắc", icon: Camera },
  ];
  return (
    <section className="grid grid-cols-4 gap-2.5">
      {acts.map((a) => {
        const Icon = a.icon;
        return (
          <button
            key={a.label}
            type="button"
            className="flex flex-col items-center justify-center gap-1.5 rounded-2xl py-3 min-h-[64px]"
            style={{ backgroundColor: CARD, border: `1px solid ${LINE}` }}
          >
            <Icon className="h-5 w-5" style={{ color: FOREST }} />
            <span className="text-[11px]" style={{ color: MUTED }}>
              {a.label}
            </span>
          </button>
        );
      })}
    </section>
  );
}

// ===== 6. Lớp tiếp theo =====
function NextClass({ s }: { s: Sess }) {
  return (
    <section>
      <h3 className="mb-2 text-sm font-semibold" style={{ color: "#1F2421" }}>
        Lớp tiếp theo
      </h3>
      <div
        className="rounded-2xl p-4 flex items-center justify-between"
        style={{ backgroundColor: CARD, border: `1px solid ${LINE}` }}
      >
        <div>
          <p className="text-sm font-medium" style={{ color: "#1F2421" }}>
            {s.class_name ?? "Lớp"}
          </p>
          <p className="text-xs" style={{ color: FAINT }}>
            {s.title ?? "Buổi học"} · {s.child_count} bé
          </p>
        </div>
        <span className="inline-flex items-center gap-1 text-xs" style={{ color: MUTED }}>
          <Clock className="h-3.5 w-3.5" /> {fmtTime(s.scheduled_at)}
        </span>
      </div>
    </section>
  );
}

// ===== 7. Cần hỗ trợ =====
function SupportSection() {
  const rows = ["Học liệu bị lỗi", "Không thấy lớp của mình", "Không gửi được nhật ký", "Hỗ trợ kỹ thuật khác"];
  return (
    <section>
      <h3 className="mb-2 text-sm font-semibold" style={{ color: "#1F2421" }}>
        Cần hỗ trợ?
      </h3>
      <div
        className="rounded-2xl divide-y"
        style={{ backgroundColor: CARD, border: `1px solid ${LINE}`, borderColor: LINE }}
      >
        {rows.map((r) => (
          <Link key={r} to="/portal/support" className="flex items-center justify-between px-4 py-3">
            <span className="inline-flex items-center gap-2.5 text-sm" style={{ color: MUTED }}>
              <LifeBuoy className="h-4 w-4" style={{ color: FAINT }} /> {r}
            </span>
            <ChevronRight className="h-4 w-4" style={{ color: FAINT }} />
          </Link>
        ))}
      </div>
    </section>
  );
}

// ===== Empty state ngày trống =====
function EmptyToday({ next }: { next: Sess | null }) {
  return (
    <section
      className="rounded-2xl p-8 text-center shadow-sm"
      style={{ backgroundColor: CARD, border: `1px solid ${LINE}` }}
    >
      <span
        className="mx-auto mb-3 inline-flex h-14 w-14 items-center justify-center rounded-full"
        style={{ backgroundColor: "#E3F3EC" }}
      >
        <Coffee className="h-7 w-7" style={{ color: FOREST }} />
      </span>
      <h2 className="text-lg font-semibold" style={{ color: INK }}>
        Hôm nay cô không có lớp
      </h2>
      <p className="mt-1 text-sm" style={{ color: MUTED }}>
        Cô nghỉ ngơi một chút nhé. Hẹn gặp các bé buổi tới!
      </p>
      <div className="mt-4 flex justify-center gap-2.5">
        <Link
          to="/teacher/curriculum"
          className="rounded-xl px-4 py-2.5 text-sm font-medium"
          style={{ backgroundColor: FOREST, color: "#fff" }}
        >
          Xem giáo án
        </Link>
        <Link
          to="/teacher/moments"
          className="rounded-xl px-4 py-2.5 text-sm font-medium"
          style={{ backgroundColor: "#fff", color: INK, border: `1.5px solid ${FOREST}` }}
        >
          Nhật ký bé
        </Link>
      </div>
      {next && (
        <div className="mt-5 rounded-xl px-4 py-3 text-left" style={{ backgroundColor: "#FBF8F1" }}>
          <p className="text-xs" style={{ color: FAINT }}>
            Lớp gần nhất sắp tới
          </p>
          <p className="text-sm font-medium" style={{ color: "#1F2421" }}>
            {next.class_name ?? "Lớp"} · {fmtTime(next.scheduled_at)}
          </p>
        </div>
      )}
    </section>
  );
}
