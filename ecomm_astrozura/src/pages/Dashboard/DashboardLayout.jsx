import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import { useState } from "react";
import { Bell, Heart, Home, LayoutDashboard, LogOut, Menu, Package, UserRound } from "lucide-react";
import logo from "../../assets/vedic-astrology.png";
import { assetUrl } from "../../utils/assetUrl";

export default function DashboardLayout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);
  const avatarImage = assetUrl(user?.profile_image);

  const menuItems = [
    { path: "/dashboard", name: "Overview", icon: LayoutDashboard, end: true },
    { path: "/dashboard/profile", name: "My Profile", icon: UserRound },
    { path: "/dashboard/orders", name: "My Orders", icon: Package },
    { path: "/dashboard/wishlist", name: "Wishlist", icon: Heart },
    { path: "/dashboard/notifications", name: "Notifications", icon: Bell },
  ];

  const handleLogout = async () => {
    await logout();
    navigate("/");
  };

  return (
    <div className="flex h-screen bg-[#f8f9fc]">
      {/* MOBILE SIDEBAR OVERLAY */}
      {isSidebarOpen && (
        <div 
          className="fixed inset-0 bg-black/50 z-40 lg:hidden" 
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      {/* SIDEBAR */}
      <aside className={`
        fixed inset-y-0 left-0 z-50 w-64 bg-[#1e1e2d] text-gray-300 transform transition-transform duration-300 ease-in-out lg:translate-x-0 lg:static lg:inset-0
        ${isSidebarOpen ? "translate-x-0" : "-translate-x-full"}
      `}>
        <div className="flex flex-col h-full">
          {/* SIDEBAR HEADER */}
          <div className="flex h-24 items-center gap-3 border-b border-gray-800 px-5">
            <img src={logo} alt="AstroZura" className="h-12 w-12 rounded-full bg-white object-contain" />
            <div>
              <h1 className="font-bold text-[#c9a227]">AstroZura</h1>
              <p className="text-[10px] font-bold uppercase tracking-[0.2em] text-gray-400">User Panel</p>
            </div>
          </div>

          {/* NAV LINKS */}
          <nav className="flex-1 overflow-y-auto py-6 px-4 space-y-2">
            {menuItems.map((item) => {
              const Icon = item.icon;
              return (
              <NavLink
                key={item.path}
                to={item.path}
                end={item.end}
                onClick={() => setIsSidebarOpen(false)}
                className={({ isActive }) => `
                  flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-200
                  ${isActive 
                    ? "bg-[#c9a227] text-white shadow-lg shadow-[#c9a227]/20" 
                    : "hover:bg-white/5 hover:text-white"}
                `}
              >
                <Icon size={18} />
                {item.name}
              </NavLink>
              );
            })}
          </nav>

          {/* SIDEBAR FOOTER */}
          <div className="p-4 border-t border-gray-800">
            <button
              type="button"
              onClick={() => navigate("/")}
              className="mb-2 flex w-full items-center gap-3 rounded-xl border border-gray-700 px-4 py-3 text-sm font-medium text-gray-300 transition hover:border-[#c9a227] hover:text-white"
            >
              <Home size={18} /> Back to Home
            </button>
            <button
              onClick={handleLogout}
              className="flex items-center gap-3 w-full px-4 py-3 text-sm font-medium text-red-400 hover:bg-red-500/10 rounded-xl transition-all duration-200"
            >
              <LogOut size={18} />
              Logout
            </button>
          </div>
        </div>
      </aside>

      {/* MAIN CONTENT */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* TOPNAV */}
        <header className="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-6 lg:px-8">
          <button 
            onClick={() => setIsSidebarOpen(true)}
            className="p-2 -ml-2 text-gray-600 lg:hidden"
          >
            <Menu size={22} />
          </button>
          
          <div className="flex items-center gap-4">
            <div className="text-right hidden sm:block">
              <p className="text-sm font-bold text-gray-900 leading-none">Welcome back,</p>
              <p className="text-xs text-gray-500 mt-1">{user?.name || "Guest"}</p>
            </div>
            <div className="flex h-10 w-10 items-center justify-center overflow-hidden rounded-full border border-[#c9a227]/20 bg-[#c9a227]/10">
              {avatarImage ? (
                <img src={avatarImage} alt={user?.name || "User"} className="h-full w-full object-cover" />
              ) : (
                <span className="font-bold text-[#c9a227]">{user?.name ? user.name[0].toUpperCase() : "U"}</span>
              )}
            </div>
          </div>
        </header>

        {/* MAIN AREA */}
        <main className="flex-1 overflow-y-auto bg-[#f8f9fc] p-6 lg:p-8">
          <div className="max-w-6xl mx-auto">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
}
