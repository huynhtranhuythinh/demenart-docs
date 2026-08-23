// V113G.1 — Frozen Parent navigation model (F1/F3/F5, V113F PASS).
// V126-M1 (C3) — IA alignment: records primary "Hành trình" → "Nhật ký"; the
// meaning route "Nhìn lại" (/parent/discovery) is added as a rail + tablet-only
// primary (railOnly) so the mobile bottom nav stays frozen at exactly four
// items. Routes unchanged. Mobile reaches "Nhìn lại" via the Home meaning bridge.
import {
  Bell,
  BookHeart,
  LifeBuoy,
  Settings,
  ShieldCheck,
  Sparkles,
  Sun,
  Telescope,
  Users,
  type LucideIcon,
} from "lucide-react";

export type ParentPrimaryNavItem = {
  to: string;
  /** Desktop + tablet label. */
  labelDesktop: string;
  /** Mobile bottom-nav label (frozen: item 4 = "Của con"). */
  labelMobile: string;
  icon: LucideIcon;
  exact?: boolean;
  /**
   * Rail + tablet drawer only. Excluded from the mobile bottom nav so it stays
   * exactly four items (V126-M1 C3). Mobile reaches this destination via the
   * Home meaning bridge.
   */
  railOnly?: boolean;
};

// Rail/tablet order: Hôm nay · Nhật ký · Nhìn lại · Gia đình · Thế giới của con.
// Mobile bottom nav renders the four non-railOnly items only.
export const PARENT_PRIMARY_NAV: readonly ParentPrimaryNavItem[] = [
  { to: "/parent", labelDesktop: "Hôm nay", labelMobile: "Hôm nay", icon: Sun, exact: true },
  { to: "/parent/journal", labelDesktop: "Nhật ký", labelMobile: "Nhật ký", icon: BookHeart },
  {
    to: "/parent/discovery",
    labelDesktop: "Nhìn lại",
    labelMobile: "Nhìn lại",
    icon: Telescope,
    railOnly: true,
  },
  { to: "/parent/family", labelDesktop: "Gia đình", labelMobile: "Gia đình", icon: Users },
  {
    to: "/parent/kid",
    labelDesktop: "Thế giới của con",
    labelMobile: "Của con",
    icon: Sparkles,
  },
] as const;

export type ParentUtilityNavItem = {
  to: string;
  label: string;
  icon: LucideIcon;
  /** Marks the notifications entry so shells can attach the unread badge. */
  isNotifications?: boolean;
};

export const PARENT_UTILITY_NAV: readonly ParentUtilityNavItem[] = [
  { to: "/parent/consent", label: "Quyền riêng tư", icon: ShieldCheck },
  { to: "/portal/notifications", label: "Thông báo", icon: Bell, isNotifications: true },
  { to: "/parent/settings", label: "Cài đặt", icon: Settings },
  { to: "/portal/support", label: "Hỗ trợ", icon: LifeBuoy },
] as const;
