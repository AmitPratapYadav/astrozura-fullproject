import { useEffect, useMemo, useState } from "react";
import { Calendar, Download, Filter, IndianRupee, Search, Star, Users } from "lucide-react";
import { exportToExcel } from "../utils/exportExcel";
import { apiRequest } from "../lib/api";

export default function Dashboard() {
  const [showFilter, setShowFilter] = useState(false);
  const [search, setSearch] = useState("");
  const [stats, setStats] = useState({
    total_users: "...",
    total_astrologers: "...",
    bookings: "...",
    revenue: "Rs 0.00",
  });
  const [bookings, setBookings] = useState([]);
  const [astrologers, setAstrologers] = useState([]);
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadDashboard = async () => {
      try {
        setLoading(true);
        const [statsResponse, bookingsResponse, astrologersResponse, usersResponse] = await Promise.all([
          apiRequest("/admin/dashboard-stats"),
          apiRequest("/admin/bookings"),
          apiRequest("/admin/astrologers"),
          apiRequest("/admin/users"),
        ]);

        if (statsResponse?.success) {
          setStats({
            total_users: statsResponse.stats.total_users.toLocaleString(),
            total_astrologers: statsResponse.stats.total_astrologers.toLocaleString(),
            bookings: statsResponse.stats.bookings.toLocaleString(),
            revenue: statsResponse.stats.revenue,
          });
        }

        setBookings(bookingsResponse?.bookings || []);
        setAstrologers(astrologersResponse?.astrologers || []);
        setUsers(usersResponse?.users || []);
      } catch (error) {
        console.error("Failed to fetch dashboard data", error);
      } finally {
        setLoading(false);
      }
    };

    void loadDashboard();
  }, []);

  const filteredBookings = useMemo(() => {
    const lower = search.toLowerCase();
    return bookings
      .filter((item) => Object.values(item).join(" ").toLowerCase().includes(lower))
      .slice(0, 6)
      .map((item) => ({
        id: item.booking_reference || `AST${item.id}`,
        user: item.user_name || "-",
        astrologer: item.astrologer_name || "-",
        date: item.scheduled_at
          ? new Date(item.scheduled_at).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" })
          : "-",
        status: item.status === "completed" ? "Completed" : "Pending",
        amount: `Rs ${Number(item.amount || 0).toLocaleString("en-IN")}`,
      }));
  }, [bookings, search]);

  const topAstrologers = useMemo(
    () =>
      [...astrologers]
        .sort(
          (a, b) =>
            (Number(b.astrologer_detail?.rating || 0) + (b.astrologer_detail?.is_featured ? 1 : 0)) -
            (Number(a.astrologer_detail?.rating || 0) + (a.astrologer_detail?.is_featured ? 1 : 0))
        )
        .slice(0, 3),
    [astrologers]
  );

  const recentUsers = useMemo(() => [...users].slice(0, 3), [users]);

  const recentPayments = useMemo(
    () =>
      [...bookings]
        .filter((booking) => booking.payment_status)
        .slice(0, 3),
    [bookings]
  );

  const dashboardStats = [
    { title: "Total Users", value: stats.total_users, icon: Users },
    { title: "Astrologers", value: stats.total_astrologers, icon: Star },
    { title: "Bookings", value: stats.bookings, icon: Calendar },
    { title: "Revenue", value: stats.revenue, icon: IndianRupee },
  ];

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
        <h1 className="text-2xl font-bold">Astrology Dashboard</h1>

        <div className="flex gap-2 flex-wrap">
          <button
            onClick={() => setShowFilter((current) => !current)}
            className="flex items-center gap-2 px-4 py-2 border rounded-lg bg-white hover:bg-yellow-500 hover:text-black transition"
          >
            <Filter size={18} />
            Filters
          </button>

          <button
            onClick={() => exportToExcel(filteredBookings, "dashboard_bookings")}
            className="flex items-center gap-2 px-4 py-2 border rounded-lg bg-white hover:bg-yellow-500 hover:text-black transition"
          >
            <Download size={18} />
            Export Excel
          </button>
        </div>
      </div>

      {showFilter && (
        <div className="bg-white p-4 rounded-xl shadow flex flex-wrap gap-3">
          <p className="text-sm text-gray-500">
            Filter controls can be added later. Search is active on the recent bookings table right now.
          </p>
        </div>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {dashboardStats.map((item) => {
          const Icon = item.icon;
          return (
            <div key={item.title} className="bg-white rounded-xl shadow p-5 flex items-center justify-between">
              <div>
                <p className="text-gray-500 text-sm">{item.title}</p>
                <h2 className="text-xl font-bold">{item.value}</h2>
              </div>
              <div className="bg-yellow-500 text-black p-3 rounded-lg">
                <Icon size={20} />
              </div>
            </div>
          );
        })}
      </div>

      <div className="bg-white rounded-xl shadow p-5 space-y-4">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
          <h2 className="text-lg font-semibold">Recent Bookings</h2>

          <div className="flex items-center bg-gray-100 px-3 py-2 rounded-lg w-full md:w-72">
            <Search size={18} />
            <input
              type="text"
              placeholder="Search booking..."
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              className="bg-transparent outline-none ml-2 w-full text-sm"
            />
          </div>
        </div>

        {loading ? (
          <p className="py-6 text-center text-gray-500">Loading dashboard data...</p>
        ) : filteredBookings.length ? (
          <div className="overflow-x-auto">
            <table className="min-w-[750px] w-full text-sm">
              <thead className="bg-gray-100">
                <tr>
                  {["Booking ID", "User", "Astrologer", "Date", "Status", "Amount"].map((label) => (
                    <th key={label} className="p-3 text-left whitespace-nowrap font-semibold">{label}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {filteredBookings.map((row) => (
                  <tr key={row.id} className="border-b hover:bg-gray-50">
                    <td className="p-3 whitespace-nowrap">{row.id}</td>
                    <td className="p-3 whitespace-nowrap">{row.user}</td>
                    <td className="p-3 whitespace-nowrap">{row.astrologer}</td>
                    <td className="p-3 whitespace-nowrap">{row.date}</td>
                    <td className="p-3 whitespace-nowrap">
                      <span className={`px-2 py-1 text-xs rounded ${row.status === "Completed" ? "bg-green-100 text-green-700" : "bg-yellow-100 text-yellow-700"}`}>
                        {row.status}
                      </span>
                    </td>
                    <td className="p-3 whitespace-nowrap">{row.amount}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <p className="py-6 text-center text-gray-500">No recent bookings available.</p>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="bg-white rounded-xl shadow p-5">
          <h3 className="font-semibold mb-3">Top Astrologers</h3>
          {topAstrologers.length ? (
            topAstrologers.map((astro) => (
              <div key={astro.id} className="flex justify-between border-b py-2 text-sm">
                <span>{astro.name}</span>
                <span className="text-gray-500">{astro.astrologer_detail?.specialities || "Astrology"}</span>
                <span className="text-yellow-500 font-semibold">{astro.astrologer_detail?.rating || "5.0"} star</span>
              </div>
            ))
          ) : (
            <p className="text-sm text-gray-500">No astrologers available.</p>
          )}
        </div>

        <div className="bg-white rounded-xl shadow p-5">
          <h3 className="font-semibold mb-3">Recent Users</h3>
          {recentUsers.length ? (
            recentUsers.map((user) => (
              <div key={user.id} className="flex justify-between border-b py-2 text-sm">
                <span>{user.name}</span>
                <span className="text-gray-500 truncate">{user.email}</span>
              </div>
            ))
          ) : (
            <p className="text-sm text-gray-500">No users available.</p>
          )}
        </div>

        <div className="bg-white rounded-xl shadow p-5">
          <h3 className="font-semibold mb-3">Recent Payments</h3>
          {recentPayments.length ? (
            recentPayments.map((payment) => (
              <div key={payment.id} className="flex justify-between border-b py-2 text-sm">
                <span>{payment.user_name}</span>
                <span>Rs {Number(payment.amount || 0).toLocaleString("en-IN")}</span>
                <span className={`text-xs px-2 py-1 rounded ${payment.payment_status === "paid" ? "bg-green-100 text-green-700" : "bg-yellow-100 text-yellow-700"}`}>
                  {payment.payment_status}
                </span>
              </div>
            ))
          ) : (
            <p className="text-sm text-gray-500">No payment records available.</p>
          )}
        </div>
      </div>
    </div>
  );
}
