import { useEffect, useState } from "react";
import { Bell, CheckCheck, Menu, Search, User } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useAppContext } from "../context/AppContext";
import { apiRequest } from "../lib/api";

function Topbar({ toggleSidebar }) {
  const navigate = useNavigate();
  const { adminUser, logout } = useAppContext();
  const [query, setQuery] = useState("");
  const [results, setResults] = useState([]);
  const [searching, setSearching] = useState(false);
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [notificationsOpen, setNotificationsOpen] = useState(false);

  const loadNotifications = async () => {
    try {
      const response = await apiRequest("/admin/notifications");
      setNotifications(response.notifications || []);
      setUnreadCount(response.unread_count || 0);
    } catch (error) {
      console.error("Admin notification load failed", error);
    }
  };

  useEffect(() => {
    void loadNotifications();
    const intervalId = window.setInterval(loadNotifications, 30000);
    return () => window.clearInterval(intervalId);
  }, []);

  useEffect(() => {
    if (query.trim().length < 2) {
      setResults([]);
      return undefined;
    }

    const timeoutId = window.setTimeout(async () => {
      try {
        setSearching(true);
        const response = await apiRequest(`/admin/search?q=${encodeURIComponent(query.trim())}`, {
          requiresAuth: false,
        });
        setResults(response?.results || []);
      } catch (error) {
        console.error("Admin search failed", error);
        setResults([]);
      } finally {
        setSearching(false);
      }
    }, 250);

    return () => window.clearTimeout(timeoutId);
  }, [query]);

  const handleSelectResult = (route) => {
    setQuery("");
    setResults([]);
    navigate(route || "/dashboard");
  };

  const openNotification = async (notification) => {
    if (!notification.read_at) {
      await apiRequest(`/admin/notifications/${notification.id}/read`, { method: "POST" });
    }
    setNotificationsOpen(false);
    await loadNotifications();
    navigate(notification.route || "/dashboard");
  };

  const markAllRead = async () => {
    await apiRequest("/admin/notifications/read-all", { method: "POST" });
    await loadNotifications();
  };

  return (
    <div className="flex items-center justify-between bg-black px-4 py-3 text-yellow-500 shadow">
      <div className="flex items-center gap-3">
        <button
          className="md:hidden hover:text-yellow-400 transition"
          onClick={toggleSidebar}
        >
          <Menu size={24} />
        </button>

        <h1 className="text-base md:text-xl font-semibold">
          Welcome, {adminUser?.name || "Astrology Platform"}
        </h1>
      </div>

      <div className="flex items-center gap-4">
        <div className="hidden md:block relative">
          <div className="flex items-center bg-gray-800 px-3 py-2 rounded-lg min-w-[320px]">
            <Search size={18} className="text-gray-400" />
            <input
              type="text"
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search bookings, users, astrologers..."
              className="bg-transparent outline-none ml-2 text-white text-sm w-full"
            />
          </div>

          {(searching || results.length > 0) && (
            <div className="absolute right-0 mt-2 w-full overflow-hidden rounded-2xl border border-gray-200 bg-white text-black shadow-2xl z-50">
              {searching ? (
                <div className="px-4 py-3 text-sm text-gray-500">Searching...</div>
              ) : (
                results.map((result, index) => (
                  <button
                    key={`${result.type}-${index}`}
                    type="button"
                    onClick={() => handleSelectResult(result.route)}
                    className="block w-full border-b border-gray-100 px-4 py-3 text-left hover:bg-gray-50 last:border-b-0"
                  >
                    <p className="text-sm font-semibold text-gray-900">{result.title}</p>
                    <p className="mt-1 text-xs text-gray-500">{result.subtitle}</p>
                  </button>
                ))
              )}
            </div>
          )}
        </div>

        <div className="relative">
          <button
            type="button"
            onClick={() => setNotificationsOpen((current) => !current)}
            className="relative hover:text-yellow-400 transition cursor-pointer"
            aria-label="Admin notifications"
          >
            <Bell size={22} />
            {unreadCount > 0 && (
              <span className="absolute -right-2 -top-2 flex min-w-5 items-center justify-center rounded-full bg-red-500 px-1 text-[10px] font-bold text-white">
                {unreadCount > 99 ? "99+" : unreadCount}
              </span>
            )}
          </button>

          {notificationsOpen && (
            <div className="absolute right-0 z-50 mt-3 w-[min(92vw,380px)] overflow-hidden rounded-xl border border-gray-200 bg-white text-gray-900 shadow-2xl">
              <div className="flex items-center justify-between border-b border-gray-100 px-4 py-3">
                <div>
                  <p className="font-bold">Notifications</p>
                  <p className="text-xs text-gray-500">{unreadCount} unread</p>
                </div>
                <button type="button" onClick={markAllRead} className="flex items-center gap-1 text-xs font-semibold text-blue-700">
                  <CheckCheck size={15} /> Mark all read
                </button>
              </div>
              <div className="max-h-[420px] overflow-y-auto">
                {notifications.length ? notifications.map((notification) => (
                  <button
                    key={notification.id}
                    type="button"
                    onClick={() => openNotification(notification)}
                    className={`block w-full border-b border-gray-100 px-4 py-3 text-left last:border-0 hover:bg-gray-50 ${
                      notification.read_at ? "bg-white" : "bg-yellow-50"
                    }`}
                  >
                    <div className="flex items-start justify-between gap-3">
                      <p className="text-sm font-bold">{notification.title}</p>
                      {!notification.read_at && <span className="mt-1 h-2 w-2 shrink-0 rounded-full bg-yellow-500" />}
                    </div>
                    <p className="mt-1 text-xs leading-5 text-gray-600">{notification.message}</p>
                    <p className="mt-1 text-[10px] text-gray-400">{new Date(notification.created_at).toLocaleString()}</p>
                  </button>
                )) : (
                  <p className="px-4 py-10 text-center text-sm text-gray-500">No notifications yet.</p>
                )}
              </div>
            </div>
          )}
        </div>

        <button
          onClick={() => navigate("/profile")}
          className="w-9 h-9 rounded-full bg-yellow-500 flex items-center justify-center text-black hover:bg-yellow-400 transition"
          title="Admin Profile"
        >
          <User size={18} />
        </button>

        <button
          onClick={logout}
          className="hidden md:inline-flex rounded-full border border-yellow-500 px-4 py-2 text-xs font-semibold text-yellow-500 hover:bg-yellow-500 hover:text-black transition"
        >
          Logout
        </button>
      </div>
    </div>
  );
}

export default Topbar;
