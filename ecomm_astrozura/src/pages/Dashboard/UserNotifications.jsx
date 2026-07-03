import { useEffect, useState } from "react";
import { Bell, CheckCheck } from "lucide-react";
import { useNavigate } from "react-router-dom";
import api from "../../api/axios";

export default function UserNotifications() {
  const navigate = useNavigate();
  const [items, setItems] = useState([]);
  const [unread, setUnread] = useState(0);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    try {
      setLoading(true);
      const response = await api.get("/notifications", { params: { surface: "shop", per_page: 50 } });
      setItems(response.data?.data?.data || []);
      setUnread(response.data?.unread_count || 0);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void load();
  }, []);

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">Notifications</h2>
          <p className="mt-1 text-sm text-gray-500">{unread} unread update{unread === 1 ? "" : "s"}</p>
        </div>
        <button
          type="button"
          onClick={async () => {
            await api.post("/notifications/read-all", { surface: "shop" });
            await load();
          }}
          className="inline-flex items-center gap-2 rounded-xl bg-[#1E3557] px-4 py-2 text-sm font-bold text-white"
        >
          <CheckCheck size={17} /> Mark all read
        </button>
      </div>
      <div className="overflow-hidden rounded-2xl border border-gray-100 bg-white shadow-sm">
        {loading ? (
          <p className="p-12 text-center text-sm text-gray-500">Loading notifications...</p>
        ) : items.length ? items.map((item) => (
          <button
            key={item.id}
            type="button"
            onClick={async () => {
              if (!item.read_at) await api.post(`/notifications/${item.id}/read`);
              item.action_url ? navigate(item.action_url) : await load();
            }}
            className={`flex w-full gap-4 border-b border-gray-100 p-5 text-left last:border-0 hover:bg-gray-50 ${
              item.read_at ? "bg-white" : "bg-[#FFF9EA]"
            }`}
          >
            <Bell size={19} className="mt-0.5 shrink-0 text-[#c9a227]" />
            <span className="min-w-0">
              <strong className="block text-sm text-gray-900">{item.title}</strong>
              <span className="mt-1 block text-sm leading-6 text-gray-500">{item.message}</span>
              <span className="mt-2 block text-xs text-gray-400">{new Date(item.created_at).toLocaleString()}</span>
            </span>
          </button>
        )) : (
          <p className="p-12 text-center text-sm text-gray-500">No notifications yet.</p>
        )}
      </div>
    </div>
  );
}
