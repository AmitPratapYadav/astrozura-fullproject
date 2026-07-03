import { useEffect, useState } from "react";
import { Bell, Clock3, Heart, Package } from "lucide-react";
import { useNavigate } from "react-router-dom";
import api from "../../api/axios";
import { useAuth } from "../../context/AuthContext";

export default function DashboardHome() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [stats, setStats] = useState({ total_orders: 0, pending_orders: 0, wishlist_items: 0 });
  const [notifications, setNotifications] = useState([]);

  const load = async () => {
    const [statsResponse, notificationResponse] = await Promise.all([
      api.get("/dashboard/stats"),
      api.get("/notifications", { params: { surface: "shop", per_page: 5 } }),
    ]);
    setStats(statsResponse.data?.data || stats);
    setNotifications(notificationResponse.data?.data?.data || []);
  };

  useEffect(() => {
    void load();
  }, []);

  const cards = [
    { label: "Total Orders", value: stats.total_orders, icon: Package, color: "bg-blue-500" },
    { label: "Pending Orders", value: stats.pending_orders, icon: Clock3, color: "bg-amber-500" },
    { label: "Wishlist Items", value: stats.wishlist_items, icon: Heart, color: "bg-red-500" },
  ];

  const openNotification = async (notification) => {
    if (!notification.read_at) await api.post(`/notifications/${notification.id}/read`);
    notification.action_url ? navigate(notification.action_url) : await load();
  };

  const markAllRead = async () => {
    await api.post("/notifications/read-all", { surface: "shop" });
    await load();
  };

  return (
    <div className="space-y-8">
      <div className="rounded-2xl border border-gray-100 bg-white p-6 shadow-sm md:p-8">
        <h2 className="text-2xl font-bold text-gray-900">Hello, {user?.name || "User"}</h2>
        <p className="mt-1 text-gray-500">Manage your orders, profile, wishlist, and updates.</p>
      </div>

      <div className="grid gap-6 sm:grid-cols-3">
        {cards.map(({ label, value, icon: Icon, color }) => (
          <div key={label} className="rounded-2xl border border-gray-100 bg-white p-6 shadow-sm">
            <div className="flex items-center justify-between">
              <span className={`flex h-10 w-10 items-center justify-center rounded-lg text-white ${color}`}>
                <Icon size={19} />
              </span>
              <strong className="text-3xl text-gray-900">{value || 0}</strong>
            </div>
            <p className="mt-5 text-xs font-bold uppercase tracking-wider text-gray-500">{label}</p>
          </div>
        ))}
      </div>

      <section className="overflow-hidden rounded-2xl border border-gray-100 bg-white shadow-sm">
        <div className="flex items-center justify-between border-b border-gray-100 px-6 py-4">
          <div>
            <h3 className="font-bold text-gray-900">Recent Notifications</h3>
            <p className="mt-1 text-xs text-gray-500">Order and offer updates</p>
          </div>
          <button type="button" onClick={() => void markAllRead()} className="text-xs font-bold text-[#c9a227] hover:underline">
            Mark all as read
          </button>
        </div>
        {notifications.length ? notifications.map((notification) => (
          <button
            key={notification.id}
            type="button"
            onClick={() => void openNotification(notification)}
            className={`flex w-full gap-4 border-b border-gray-50 p-5 text-left last:border-0 hover:bg-gray-50 ${
              notification.read_at ? "bg-white" : "bg-[#FFF9EA]"
            }`}
          >
            <Bell size={19} className="mt-0.5 shrink-0 text-[#c9a227]" />
            <span>
              <strong className="block text-sm text-gray-800">{notification.title}</strong>
              <span className="mt-1 block text-xs leading-5 text-gray-500">{notification.message}</span>
            </span>
          </button>
        )) : (
          <p className="p-10 text-center text-sm text-gray-500">No notifications yet.</p>
        )}
      </section>
    </div>
  );
}
