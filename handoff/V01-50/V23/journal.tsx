import { createFileRoute, Link } from "@tanstack/react-router";
import { useEffect, useState, useCallback } from "react";
import { BookHeart, Music, BookOpen, Sparkles, Award, Share2, Copy, Check } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { supabase } from "@/integrations/supabase/client";
import { useCurrentProfile } from "@/hooks/use-current-profile";
import { cn } from "@/lib/utils";

export const Route = createFileRoute("/_authenticated/portal/journal")({
  component: JournalPage,
});

type ChildRow = {
  id: string;
  full_name: string | null;
  nickname: string | null;
};

type JourneyEntry = {
  id: string;
  entry_type: string;
  source: string | null;
  occurred_at: string;
  program_name: string | null;
  session_title: string | null;
};

type SkillRow = { skill: string; signal_count: number };
type BadgeRow = {
  title: string;
  description: string | null;
  status: string | null;
  created_at: string;
};

type MomentRow = {
  moment_id: string;
  caption: string | null;
  created_at: string;
  media_id: string | null;
};

type JournalPayload = {
  journey: JourneyEntry[];
  skills: SkillRow[];
  badges: BadgeRow[];
  moments: MomentRow[];
};

type DenialReason =
  | "consent_missing"
  | "school_blocks_download"
  | "school_blocks_share"
  | "not_authorized"
  | "no_profile"
  | "not_authenticated"
  | "unknown";

type SignedMedia =
  | { status: "loading" }
  | { status: "ok"; url: string }
  | { status: "denied"; reason: DenialReason }
  | { status: "hidden" };

function cleanCaption(c: string | null): string {
  if (!c) return "";
  return c.replace(/^\[seed\]\s*/i, "");
}

function denialMessage(reason: string): string {
  switch (reason) {
    case "consent_missing":
      return "Đang chờ ba mẹ đồng ý cho xem ảnh này";
    case "school_blocks_download":
    case "school_blocks_share":
      return "Trường chưa cho phép xem ảnh này";
    case "not_authorized":
    case "no_profile":
    case "not_authenticated":
      return "Bạn không có quyền xem ảnh này";
    default:
      return "Ảnh tạm thời chưa xem được";
  }
}

function formatViDate(iso: string): string {
  return new Intl.DateTimeFormat("vi-VN", {
    day: "numeric",
    month: "long",
    year: "numeric",
    timeZone: "Asia/Ho_Chi_Minh",
  }).format(new Date(iso));
}

function entryVisual(entry: JourneyEntry) {
  if (entry.entry_type === "badge") {
    return {
      icon: <Award className="h-4 w-4" />,
      title: "Nhận huy hiệu mới 🎖️",
    };
  }
  if (entry.entry_type === "session") {
    const isMusic = (entry.program_name ?? "").toLowerCase().includes("nhạc");
    return {
      icon: isMusic ? <Music className="h-4 w-4" /> : <BookOpen className="h-4 w-4" />,
      title: entry.session_title || "Buổi học",
    };
  }
  return {
    icon: <Sparkles className="h-4 w-4" />,
    title: "Hoạt động",
  };
}

function MomentImage({
  mediaId,
  onHidden,
}: {
  mediaId: string | null;
  onHidden?: () => void;
}) {
  const [state, setState] = useState<SignedMedia>({ status: "loading" });

  useEffect(() => {
    if (!mediaId) {
      setState({ status: "denied", reason: "unknown" });
      return;
    }
    let active = true;
    (async () => {
      const { data, error } = await (supabase as any).functions.invoke(
        "get_signed_media_url",
        { body: { media_id: mediaId } },
      );
      if (!active) return;

      let reason: string = data?.reason ?? "unknown";
      if (
        error &&
        (error as any).context &&
        typeof (error as any).context.json === "function"
      ) {
        try {
          const body = await (error as any).context.json();
          reason = body?.reason ?? reason;
        } catch {
          /* keep reason */
        }
      }

      if (!error && data?.allowed && data?.signed_url) {
        setState({ status: "ok", url: data.signed_url });
        return;
      }
      if (reason === "moment_not_approved") {
        onHidden?.();
        setState({ status: "hidden" });
        return;
      }
      setState({ status: "denied", reason: reason as DenialReason });
    })();
    return () => {
      active = false;
    };
  }, [mediaId, onHidden]);

  if (state.status === "loading") {
    return <Skeleton className="h-full w-full rounded-lg" />;
  }
  if (state.status === "ok") {
    return (
      <img
        src={state.url}
        alt=""
        className="h-full w-full rounded-lg object-cover"
        loading="lazy"
      />
    );
  }
  if (state.status === "hidden") {
    return null;
  }
  return (
    <div className="flex h-full w-full items-center justify-center rounded-lg border border-dashed border-amber-200 bg-amber-50/60 p-3 text-center text-xs text-muted-foreground">
      {denialMessage(state.reason)}
    </div>
  );
}

function MomentCard({ moment }: { moment: MomentRow }) {
  const [hidden, setHidden] = useState(false);

  const handleHidden = useCallback(() => {
    setHidden(true);
  }, []);

  if (hidden) {
    return null;
  }

  return (
    <div className="overflow-hidden rounded-xl bg-white/80 p-3 shadow-sm">
      <div className="aspect-[4/3] w-full overflow-hidden rounded-lg bg-amber-50/60">
        <MomentImage mediaId={moment.media_id} onHidden={handleHidden} />
      </div>
      {cleanCaption(moment.caption) && (
        <p className="mt-3 text-sm font-medium text-foreground">
          {cleanCaption(moment.caption)}
        </p>
      )}
      <p className="mt-1 text-xs text-muted-foreground">
        {formatViDate(moment.created_at)}
      </p>
      <div className="mt-2">
        <ShareMomentButton momentId={moment.moment_id} />
      </div>
    </div>
  );
}

type ActiveLink = {
  id: string;
  token: string;
  expires_at: string | null;
};

function shareErrorMessage(reason: string | undefined, blockingChildren?: unknown): string {
  const blocking = Array.isArray(blockingChildren) ? blockingChildren.length : 0;

  switch (reason) {
    case "school_blocks_share":
      return "Trường chưa bật tính năng chia sẻ ảnh ra ngoài.";
    case "consent_missing":
      return blocking > 1
        ? "Bạn cần đồng ý cho phép chia sẻ ảnh này trước (một số bé trong ảnh chưa được đồng ý)."
        : "Bạn cần đồng ý cho phép chia sẻ ảnh này trước.";
    case "not_authorized":
      return "Bạn không có quyền chia sẻ khoảnh khắc này.";
    case "moment_not_approved":
      return "Khoảnh khắc này chưa được duyệt.";
    case "not_authenticated":
      return "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.";
    default:
      return "Chưa thể tạo link chia sẻ.";
  }
}

function isShareVerdict(value: unknown): value is {
  allowed?: boolean;
  token?: string;
  reason?: string;
  blocking_children?: unknown;
} {
  return typeof value === "object" && value !== null;
}

function ShareMomentButton({ momentId }: { momentId: string }) {
  const [open, setOpen] = useState(false);
  const [links, setLinks] = useState<ActiveLink[] | null>(null); // null = chưa tải lần nào
  const [loadingLinks, setLoadingLinks] = useState(false);
  const [creating, setCreating] = useState(false);
  const [revokingId, setRevokingId] = useState<string | null>(null);
  const [copiedId, setCopiedId] = useState<string | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [errorReason, setErrorReason] = useState<string | null>(null);

  // Đọc thẳng share_links (SELECT creator-only → chỉ trả link của chính PH)
  const loadLinks = useCallback(async () => {
    setLoadingLinks(true);
    setErrorMsg(null);
    setErrorReason(null);
    const nowIso = new Date().toISOString();
    const { data, error } = await (supabase as any)
      .from("share_links")
      .select("id, token, expires_at")
      .eq("scope_type", "moment")
      .eq("scope_ref_id", momentId)
      .is("revoked_at", null)
      .gt("expires_at", nowIso)
      .order("created_at", { ascending: false });
    if (error) {
      console.error("load share_links error:", error);
      setLinks([]);
    } else {
      setLinks((data ?? []) as ActiveLink[]);
    }
    setLoadingLinks(false);
  }, [momentId]);

  const handleOpenChange = (next: boolean) => {
    setOpen(next);
    if (next) {
      setCopiedId(null);
      void loadLinks();
    }
  };

  const createLink = async () => {
    setCreating(true);
    setErrorMsg(null);
    setErrorReason(null);
    const { data, error } = await (supabase as any).rpc("create_private_share_link", {
      p_moment_id: momentId,
      p_ttl_minutes: 1440,
    });
    setCreating(false);
    if (error) {
      console.error("share rpc error:", error);
      setErrorMsg(shareErrorMessage(undefined));
      return;
    }
    // RPC trả 1 jsonb object trực tiếp — KHÔNG .single(), KHÔNG data[0].
    const verdict = isShareVerdict(data) ? data : undefined;
    if (verdict?.allowed === true && verdict?.token) {
      await loadLinks();
      return;
    }
    console.warn("share denied verdict:", verdict);
    setErrorMsg(shareErrorMessage(verdict?.reason, verdict?.blocking_children));
    setErrorReason(verdict?.reason ?? null);
  };

  const revokeLink = async (link: ActiveLink) => {
    setRevokingId(link.id);
    setErrorMsg(null);
    setErrorReason(null);
    const { data, error } = await (supabase as any).rpc("revoke_share_link", {
      p_token: link.token,
    });
    setRevokingId(null);
    if (error) {
      console.error("revoke rpc error:", error);
      setErrorMsg("Chưa thể thu hồi link. Vui lòng thử lại.");
      return;
    }
    // RPC trả verdict {ok, reason, ...} — KHÔNG throw cho verdict.
    const ok = typeof data === "object" && data !== null && (data as any).ok === true;
    if (ok) {
      await loadLinks();
    } else {
      setErrorMsg("Chưa thể thu hồi link. Vui lòng thử lại.");
    }
  };

  const copy = async (link: ActiveLink) => {
    const url = `${window.location.origin}/share/${link.token}`;
    try {
      await navigator.clipboard.writeText(url);
      setCopiedId(link.id);
      setTimeout(() => setCopiedId(null), 1800);
    } catch {
      /* ignore */
    }
  };

  const hasLinks = !!links && links.length > 0;

  return (
    <Popover open={open} onOpenChange={handleOpenChange}>
      <PopoverTrigger asChild>
        <button
          type="button"
          className="inline-flex items-center gap-1 text-xs text-muted-foreground transition-colors hover:text-amber-600"
        >
          <Share2 className="h-3.5 w-3.5" />
          Chia sẻ
        </button>
      </PopoverTrigger>
      <PopoverContent className="w-80" align="start">
        {loadingLinks && links === null ? (
          <p className="text-sm text-muted-foreground">Đang tải…</p>
        ) : (
          <div className="space-y-3">
            {hasLinks && (
              <div className="space-y-3">
                <p className="text-xs font-medium text-foreground">
                  Liên kết đang chia sẻ
                </p>
                {links!.map((link) => {
                  const url = `${window.location.origin}/share/${link.token}`;
                  return (
                    <div
                      key={link.id}
                      className="space-y-1.5 rounded-lg border border-amber-100 bg-amber-50/40 p-2"
                    >
                      <div className="flex items-center gap-2">
                        <Input readOnly value={url} className="h-8 text-xs" />
                        <Button
                          type="button"
                          size="sm"
                          variant="outline"
                          className="h-8 px-2"
                          onClick={() => copy(link)}
                        >
                          {copiedId === link.id ? (
                            <Check className="h-4 w-4" />
                          ) : (
                            <Copy className="h-4 w-4" />
                          )}
                        </Button>
                      </div>
                      <Button
                        type="button"
                        size="sm"
                        variant="ghost"
                        className="h-7 px-2 text-xs text-red-600 hover:bg-red-50 hover:text-red-700"
                        disabled={revokingId === link.id}
                        onClick={() => revokeLink(link)}
                      >
                        {revokingId === link.id ? "Đang thu hồi…" : "Thu hồi"}
                      </Button>
                    </div>
                  );
                })}
              </div>
            )}

            {!hasLinks && !errorMsg && (
              <p className="text-xs text-muted-foreground">
                Chưa có liên kết nào. Tạo link để chia sẻ khoảnh khắc này với người thân.
              </p>
            )}

            {errorMsg && (
              <div className="space-y-1.5">
                <p className="text-sm text-muted-foreground">{errorMsg}</p>
                {errorReason === "consent_missing" && (
                  <Link
                    to="/portal/consent"
                    className="inline-block text-xs font-medium text-amber-600 transition-colors hover:text-amber-700"
                  >
                    Quản lý quyền đồng ý →
                  </Link>
                )}
              </div>
            )}

            <Button
              type="button"
              size="sm"
              className="w-full"
              disabled={creating}
              onClick={createLink}
            >
              {creating ? "Đang tạo…" : hasLinks ? "Tạo link mới" : "Tạo link chia sẻ"}
            </Button>

            <p className="text-xs text-muted-foreground">
              Link hết hạn sau 24 giờ. Bạn có thể thu hồi bất cứ lúc nào.
            </p>
          </div>
        )}
      </PopoverContent>
    </Popover>
  );
}

function JournalPage() {
  const { profile } = useCurrentProfile();
  const parentProfileId = profile?.id ?? null;

  const [children, setChildren] = useState<ChildRow[] | null>(null);
  const [selectedChildId, setSelectedChildId] = useState<string | null>(null);
  const [data, setData] = useState<JournalPayload | null>(null);
  const [loadingChildren, setLoadingChildren] = useState(true);
  const [loadingJournal, setLoadingJournal] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  // Load children linked to this parent
  useEffect(() => {
    if (typeof window === "undefined" || !parentProfileId) return;
    let active = true;
    (async () => {
      setLoadingChildren(true);
      const { data: rows, error } = await (supabase as any)
        .from("child_parents")
        .select("child_id, children:child_id(id, full_name, nickname)")
        .eq("parent_profile_id", parentProfileId);
      if (!active) return;
      if (error) {
        setChildren([]);
      } else {
        const list: ChildRow[] = (rows ?? [])
          .map((r: any) => r.children)
          .filter(Boolean);
        setChildren(list);
        if (list.length > 0) setSelectedChildId((cur) => cur ?? list[0].id);
      }
      setLoadingChildren(false);
    })();
    return () => {
      active = false;
    };
  }, [parentProfileId]);

  const loadJournal = useCallback(async () => {
    if (typeof window === "undefined" || !selectedChildId) return;
    setLoadingJournal(true);
    setErrorMsg(null);
    const { data: rpcData, error } = await (supabase as any).rpc("get_child_journal", {
      p_child_id: selectedChildId,
    });
    if (error) {
      setData(null);
      setErrorMsg("Không thể tải nhật ký của bé này.");
    } else {
      const payload = (rpcData ?? {}) as Partial<JournalPayload>;
      setData({
        journey: payload.journey ?? [],
        skills: payload.skills ?? [],
        badges: payload.badges ?? [],
        moments: payload.moments ?? [],
      });
    }
    setLoadingJournal(false);
  }, [selectedChildId]);

  useEffect(() => {
    loadJournal();
  }, [loadJournal]);

  const loading = loadingChildren || (!!selectedChildId && loadingJournal && data === null);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Nhật ký của con</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Hành trình lớn lên qua nghệ thuật của con — thuộc về con và gia đình.
        </p>
      </div>

      {loadingChildren && (
        <div className="space-y-3">
          <Skeleton className="h-10 w-64 rounded-full" />
          <Skeleton className="h-40 w-full rounded-2xl" />
        </div>
      )}

      {!loadingChildren && children && children.length === 0 && (
        <Card className="rounded-2xl border-dashed bg-muted/30">
          <CardContent className="p-10 text-center">
            <BookHeart className="mx-auto h-8 w-8 text-muted-foreground/60" />
            <p className="mt-3 text-sm text-muted-foreground">
              Chưa có hồ sơ con nào được liên kết.
            </p>
          </CardContent>
        </Card>
      )}

      {!loadingChildren && children && children.length > 0 && (
        <>
          {children.length > 1 && (
            <div className="flex flex-wrap gap-2">
              {children.map((c) => {
                const active = c.id === selectedChildId;
                const label = c.nickname || c.full_name || "Bé";
                return (
                  <button
                    key={c.id}
                    type="button"
                    onClick={() => setSelectedChildId(c.id)}
                    className={cn(
                      "rounded-full px-4 py-1.5 text-sm transition-colors",
                      active
                        ? "bg-amber-500 text-white shadow-sm"
                        : "bg-muted text-muted-foreground hover:bg-muted/80",
                    )}
                  >
                    {label}
                  </button>
                );
              })}
            </div>
          )}

          {loading && (
            <div className="space-y-3">
              <Skeleton className="h-48 w-full rounded-2xl" />
              <Skeleton className="h-32 w-full rounded-2xl" />
            </div>
          )}

          {!loading && errorMsg && (
            <Card className="rounded-2xl border-dashed bg-muted/30">
              <CardContent className="p-10 text-center">
                <p className="text-sm text-muted-foreground">{errorMsg}</p>
              </CardContent>
            </Card>
          )}

          {!loading && !errorMsg && data && (
            <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
              {/* Timeline */}
              <div className="lg:col-span-2">
                <Card className="rounded-2xl border-amber-100/60 bg-amber-50/30">
                  <CardContent className="p-6">
                    <h2 className="text-base font-semibold">Hành trình</h2>
                    {data.journey.length === 0 ? (
                      <p className="mt-6 text-sm text-muted-foreground">
                        Nhật ký của con sẽ được cập nhật sau mỗi buổi học.
                      </p>
                    ) : (
                      <ol className="relative mt-6 space-y-6 border-l-2 border-amber-200/70 pl-6">
                        {data.journey
                          .slice()
                          .sort(
                            (a, b) =>
                              new Date(b.occurred_at).getTime() -
                              new Date(a.occurred_at).getTime(),
                          )
                          .map((entry) => {
                            const v = entryVisual(entry);
                            return (
                              <li key={entry.id} className="relative">
                                <span className="absolute -left-[33px] top-1 flex h-6 w-6 items-center justify-center rounded-full bg-amber-500 text-white shadow-sm">
                                  {v.icon}
                                </span>
                                <div className="rounded-xl bg-white/70 p-4 shadow-sm">
                                  <p className="text-xs text-muted-foreground">
                                    {formatViDate(entry.occurred_at)}
                                  </p>
                                  <p className="mt-1 text-sm font-semibold text-foreground">
                                    {v.title}
                                  </p>
                                  {entry.program_name && (
                                    <p className="mt-0.5 text-xs text-muted-foreground">
                                      {entry.program_name}
                                    </p>
                                  )}
                                </div>
                              </li>
                            );
                          })}
                      </ol>
                    )}
                  </CardContent>
                </Card>

                {/* Khoảnh khắc */}
                <Card className="mt-6 rounded-2xl border-amber-100/60 bg-amber-50/30">
                  <CardContent className="p-6">
                    <h2 className="text-base font-semibold">Khoảnh khắc</h2>
                    <p className="mt-1 text-xs text-muted-foreground">
                      Những hình ảnh đáng nhớ của con ở lớp.
                    </p>
                    {data.moments.length === 0 ? (
                      <p className="mt-6 text-sm text-muted-foreground">
                        Chưa có khoảnh khắc nào.
                      </p>
                    ) : (
                      <div className="mt-5 grid grid-cols-1 gap-4 sm:grid-cols-2">
                        {data.moments
                          .slice()
                          .sort(
                            (a, b) =>
                              new Date(b.created_at).getTime() -
                              new Date(a.created_at).getTime(),
                          )
                          .map((m) => (
                            <MomentCard key={m.moment_id} moment={m} />
                          ))}
                      </div>
                    )}
                  </CardContent>
                </Card>
              </div>

              {/* Side: skills + badges */}
              <div className="space-y-6">
                {data.skills.length > 0 && (
                  <Card className="rounded-2xl border-amber-100/60 bg-amber-50/30">
                    <CardContent className="p-6">
                      <h2 className="text-base font-semibold">Kỹ năng đang phát triển</h2>
                      <ul className="mt-4 space-y-3">
                        {data.skills.map((s) => {
                          const dots = Math.max(1, Math.min(5, s.signal_count));
                          return (
                            <li
                              key={s.skill}
                              className="flex items-center justify-between gap-3"
                            >
                              <span className="text-sm font-medium">{s.skill}</span>
                              <span className="flex gap-1">
                                {Array.from({ length: 5 }).map((_, i) => (
                                  <span
                                    key={i}
                                    className={cn(
                                      "h-2 w-2 rounded-full",
                                      i < dots ? "bg-amber-500" : "bg-amber-200/70",
                                    )}
                                  />
                                ))}
                              </span>
                            </li>
                          );
                        })}
                      </ul>
                    </CardContent>
                  </Card>
                )}

                {data.badges.length > 0 && (
                  <Card className="rounded-2xl border-amber-100/60 bg-amber-50/30">
                    <CardContent className="p-6">
                      <h2 className="text-base font-semibold">Huy hiệu kỷ niệm</h2>
                      <div className="mt-4 flex flex-wrap gap-3">
                        {data.badges.map((b, idx) => (
                          <div
                            key={`${b.title}-${idx}`}
                            title={b.description ?? ""}
                            className="flex items-center gap-2 rounded-full border border-amber-200 bg-white/80 px-3 py-1.5 shadow-sm"
                          >
                            <Award className="h-4 w-4 text-amber-500" />
                            <span className="text-sm font-medium">{b.title}</span>
                          </div>
                        ))}
                      </div>
                    </CardContent>
                  </Card>
                )}
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}
