// V113G.1 — Mobile bottom navigation (≤479px): exactly the four frozen
// primaries, item 4 label = "Của con". Fixed, safe-area aware, no utilities.
// V126-M1 (C3) — filters out rail/tablet-only primaries (railOnly, e.g. "Nhìn
// lại") so the bottom nav stays exactly four items; grid-cols-4 unchanged.
import { Link } from "@tanstack/react-router";
import { PARENT_PRIMARY_NAV } from "@/features/parent/shell/parentNav";

export function UnreadBadge({ unread }: { unread: number }) {
  if (unread <= 0) return null;
  return (
    <span
      aria-hidden="true"
      className="absolute -top-0.5 -right-0.5 flex h-4.5 min-w-4.5 items-center justify-center rounded-full bg-dma-emerald px-1 text-[10px] font-semibold text-dma-ivory"
    >
      {unread > 99 ? "99+" : unread}
    </span>
  );
}

export function ParentBottomNav() {
  return (
    <nav
      aria-label="Điều hướng chính"
      className="fixed inset-x-0 bottom-0 z-40 border-t border-dma-hairline bg-dma-ivory-raised/95 pb-(--dma-safe-bottom) backdrop-blur dtab:hidden"
    >
      <div className="grid h-(--dma-bottomnav-h) grid-cols-4">
        {PARENT_PRIMARY_NAV.filter((item) => !item.railOnly).map((item) => {
          const Icon = item.icon;
          return (
            <Link
              key={item.to}
              to={item.to}
              activeOptions={item.exact ? { exact: true } : undefined}
              activeProps={{ "aria-current": "page", className: "text-dma-emerald" }}
              inactiveProps={{ className: "text-dma-ink-meta" }}
              className="flex min-h-11 flex-col items-center justify-center gap-0.5 transition-colors"
            >
              <Icon className="h-5 w-5" aria-hidden="true" />
              <span className="text-[11px] font-medium">{item.labelMobile}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
