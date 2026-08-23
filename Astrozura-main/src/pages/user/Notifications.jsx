import { useEffect, useState } from "react";
import { Bell, CheckCheck } from "lucide-react";
import { useNavigate } from "react-router-dom";
import api from "../../api/axios";
import Navbar from "../../components/Navbar";
import Footer from "../../components/Footer";
import UserDashboardSidebar from "../../components/UserDashboardSidebar";
import { ensureRazorpayConfigured, payWithRazorpay } from "../../api/paymentApi";

export default function Notifications() {
  const navigate = useNavigate();
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [unreadOnly, setUnreadOnly] = useState(false);
  const [message, setMessage] = useState("");
  const [payingNotificationId, setPayingNotificationId] = useState(null);

  const loadNotifications = async () => {
    try {
      setLoading(true);
      const response = await api.get("/notifications", {
        params: { surface: "main", unread: unreadOnly ? 1 : 0, per_page: 50 },
      });
      setNotifications(response.data?.data?.data || []);
      setUnreadCount(response.data?.unread_count || 0);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadNotifications();
  }, [unreadOnly]);

  const openNotification = async (notification) => {
    if (!notification.read_at) {
      await api.post(`/notifications/${notification.id}/read`);
    }
    notification.action_url ? navigate(notification.action_url) : await loadNotifications();
  };

  const payRitualFromNotification = async (event, notification) => {
    event.stopPropagation();

    const ritualBookingId = notification.data?.ritual_booking_id;
    if (!ritualBookingId) {
      setMessage("Ritual booking details are missing for this payment request.");
      return;
    }

    try {
      setPayingNotificationId(notification.id);
      setMessage("");
      if (!notification.read_at) {
        await api.post(`/notifications/${notification.id}/read`);
      }
      await ensureRazorpayConfigured();
      await payWithRazorpay({
        purpose: "ritual",
        recordId: ritualBookingId,
        description: "Pooja Anusthan",
      });
      navigate("/my-bookings", {
        state: { message: "Ritual payment completed successfully." },
      });
    } catch (error) {
      setMessage(error?.response?.data?.message || error?.message || "Unable to complete ritual payment.");
    } finally {
      setPayingNotificationId(null);
    }
  };

  const markAllRead = async () => {
    await api.post("/notifications/read-all", { surface: "main" });
    await loadNotifications();
  };

  return (
    <div className="flex min-h-screen flex-col bg-[#f8f9fa]">
      <Navbar />
      {message && (
        <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-full bg-[#1E3557] px-6 py-3 text-sm font-semibold text-white shadow-lg">
          {message}
        </div>
      )}
      <div className="mx-auto flex w-full max-w-7xl flex-1 flex-col gap-8 p-4 lg:flex-row lg:p-8">
        <UserDashboardSidebar />
        <main className="min-w-0 flex-1">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
            <div>
              <p className="text-sm font-medium uppercase tracking-wider text-[#D4A73C]">Account Updates</p>
              <h1 className="mt-1 text-3xl font-bold text-[#1E3557]">Notifications</h1>
              <p className="mt-2 text-sm text-gray-500">{unreadCount} unread notification{unreadCount === 1 ? "" : "s"}</p>
            </div>
            <div className="flex flex-wrap gap-2">
              <label className="flex items-center gap-2 rounded-xl border bg-white px-4 py-2 text-sm font-semibold text-gray-600">
                <input type="checkbox" checked={unreadOnly} onChange={(event) => setUnreadOnly(event.target.checked)} />
                Unread only
              </label>
              <button type="button" onClick={markAllRead} className="inline-flex items-center gap-2 rounded-xl bg-[#1E3557] px-4 py-2 text-sm font-semibold text-white">
                <CheckCheck size={17} /> Mark all read
              </button>
            </div>
          </div>

          <section className="mt-6 overflow-hidden rounded-2xl border border-gray-100 bg-white shadow-sm">
            {loading ? (
              <div className="p-12 text-center text-sm text-gray-500">Loading notifications...</div>
            ) : notifications.length ? (
              notifications.map((notification) => {
                const isRitualPaymentRequest =
                  notification.type === "ritual_payment_request" &&
                  notification.data?.ritual_booking_id &&
                  Number(notification.data?.amount || 0) > 0;

                return (
                  <div
                    key={notification.id}
                    className={`flex w-full gap-4 border-b border-gray-100 p-5 text-left transition last:border-0 hover:bg-gray-50 ${
                      notification.read_at ? "bg-white" : "bg-[#FFF9EA]"
                    }`}
                  >
                    <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[#F6E8BF] text-[#1E3557]">
                      <Bell size={18} />
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="flex items-start justify-between gap-4">
                        <strong className="text-sm text-[#1E3557]">{notification.title}</strong>
                        {!notification.read_at && <span className="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-[#D4A73C]" />}
                      </span>
                      <span className="mt-1 block text-sm leading-6 text-gray-600">{notification.message}</span>
                      {isRitualPaymentRequest && (
                        <span className="mt-3 flex flex-wrap items-center gap-3">
                          <span className="rounded-full bg-white px-3 py-1 text-xs font-bold text-[#1E3557]">
                            Rs {Number(notification.data.amount).toLocaleString("en-IN")}
                          </span>
                          <button
                            type="button"
                            disabled={payingNotificationId === notification.id}
                            onClick={(event) => void payRitualFromNotification(event, notification)}
                            className="rounded-xl bg-[#D4A73C] px-4 py-2 text-xs font-bold text-[#1E3557] transition hover:bg-[#c49530] disabled:opacity-60"
                          >
                            {payingNotificationId === notification.id ? "Opening Payment..." : "Pay Now"}
                          </button>
                        </span>
                      )}
                      <span className="mt-3 flex flex-wrap items-center gap-3">
                        <span className="block text-xs text-gray-400">{new Date(notification.created_at).toLocaleString()}</span>
                        <button
                          type="button"
                          onClick={() => void openNotification(notification)}
                          className="text-xs font-semibold text-[#1E3557] underline-offset-4 hover:underline"
                        >
                          View details
                        </button>
                      </span>
                    </span>
                  </div>
                );
              })
            ) : (
              <div className="p-12 text-center">
                <Bell className="mx-auto text-gray-300" size={34} />
                <h2 className="mt-4 font-bold text-[#1E3557]">No notifications yet</h2>
                <p className="mt-2 text-sm text-gray-500">Booking and account updates will appear here.</p>
              </div>
            )}
          </section>
        </main>
      </div>
      <Footer />
    </div>
  );
}
