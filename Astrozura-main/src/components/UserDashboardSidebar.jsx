import { Bell, CalendarDays, LayoutDashboard, UserRound } from "lucide-react";
import { NavLink } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { assetUrl } from "../utils/assetUrl";

const links = [
  { to: "/dashboard", label: "Dashboard Overview", icon: LayoutDashboard, end: true },
  { to: "/user-profile", label: "My Profile", icon: UserRound },
  { to: "/my-bookings", label: "My Bookings", icon: CalendarDays },
  { to: "/notifications", label: "Notifications", icon: Bell },
];

export default function UserDashboardSidebar() {
  const { user } = useAuth();
  const image = assetUrl(user?.profile_image);

  return (
    <aside className="w-full flex-shrink-0 lg:w-[280px]">
      <div className="overflow-hidden rounded-2xl border border-gray-100 bg-white shadow-sm lg:sticky lg:top-24">
        <div className="relative px-6 pb-6 pt-8 text-center">
          <div className="absolute left-0 top-0 h-24 w-full rounded-b-3xl bg-gradient-to-br from-[#1E3557] to-[#0D1B3E] opacity-90" />
          <div className="relative mx-auto flex h-20 w-20 items-center justify-center overflow-hidden rounded-2xl border-4 border-white bg-[#D4A73C] text-3xl font-bold text-white shadow-lg">
            {image ? (
              <img src={image} alt={user?.name || "User"} className="h-full w-full object-cover" />
            ) : (
              user?.name?.charAt(0)?.toUpperCase() || "U"
            )}
          </div>
          <div className="mt-4">
            <h3 className="text-lg font-bold text-[#1E3557]">{user?.name || "Celestial User"}</h3>
            <p className="mt-0.5 break-all text-xs font-medium text-gray-500">
              {user?.email || user?.phone || "Free Member"}
            </p>
          </div>
        </div>

        <nav className="flex flex-col space-y-1 p-3">
          {links.map(({ to, label, icon: Icon, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-xl border-l-4 px-4 py-3 text-sm font-medium transition ${
                  isActive
                    ? "border-[#D4A73C] bg-gradient-to-r from-[#1E3557] to-[#2c4b7c] text-white shadow-md"
                    : "border-transparent text-gray-600 hover:bg-gray-50 hover:text-[#1E3557]"
                }`
              }
            >
              <Icon size={17} />
              {label}
            </NavLink>
          ))}
        </nav>
      </div>
    </aside>
  );
}
