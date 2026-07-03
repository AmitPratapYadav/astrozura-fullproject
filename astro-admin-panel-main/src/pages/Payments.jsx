import { useEffect, useState } from "react";
import { apiRequest } from "../lib/api";

const tabs = [
  ["consultations", "Consultations"],
  ["astrologers", "Astrologer Earnings"],
  ["orders", "Shop Orders"],
  ["rituals", "Pooja Anusthan"],
];

export default function Payments() {
  const [active, setActive] = useState("consultations");
  const [period, setPeriod] = useState("month");
  const [data, setData] = useState({ consultations: [], astrologers: [], orders: [], rituals: [] });
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    try {
      const [payments, astrologers] = await Promise.all([
        apiRequest(`/admin/payments?period=${period}`),
        apiRequest(`/admin/payments/astrologers?period=${period}`),
      ]);
      setData({
        consultations: payments.consultations?.data || [],
        orders: payments.orders?.data || [],
        rituals: payments.rituals?.data || [],
        astrologers: astrologers.data || [],
      });
    } finally { setLoading(false); }
  };
  useEffect(() => { void load(); }, [period]);

  const rows = data[active] || [];
  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3"><div><h1 className="text-2xl font-bold">Payments</h1><p className="text-sm text-gray-500">Revenue, commission, and payout records.</p></div><select value={period} onChange={(e) => setPeriod(e.target.value)} className="rounded-lg border bg-white px-4 py-2"><option value="week">This week</option><option value="month">This month</option><option value="year">This year</option></select></div>
      <div className="flex gap-2 overflow-x-auto">{tabs.map(([key, label]) => <button key={key} onClick={() => setActive(key)} className={`whitespace-nowrap rounded-lg px-4 py-2 font-semibold ${active === key ? "bg-yellow-500 text-black" : "bg-white text-gray-600"}`}>{label}</button>)}</div>
      <div className="overflow-x-auto rounded-xl bg-white shadow">
        <table className="w-full min-w-[850px] text-sm">
          <thead className="bg-gray-100"><tr>{active === "astrologers" ? <><th className="p-3 text-left">Astrologer</th><th className="p-3 text-left">Paid bookings</th><th className="p-3 text-left">Gross</th><th className="p-3 text-left">Platform commission</th><th className="p-3 text-left">Earnings</th><th className="p-3 text-left">Rating</th></> : <><th className="p-3 text-left">Reference</th><th className="p-3 text-left">Customer</th><th className="p-3 text-left">Description</th><th className="p-3 text-left">Amount</th><th className="p-3 text-left">Date</th></>}</tr></thead>
          <tbody>
            {loading ? <tr><td colSpan="6" className="p-8 text-center">Loading payments...</td></tr> : rows.map((row) => active === "astrologers" ? (
              <tr key={row.id} className="border-b"><td className="p-3 font-semibold">{row.name}</td><td className="p-3">{row.paid_bookings_count || 0}</td><td className="p-3">₹{Number(row.gross_income || 0).toLocaleString("en-IN")}</td><td className="p-3">₹{Number(row.platform_commission || 0).toLocaleString("en-IN")}</td><td className="p-3 font-semibold text-green-700">₹{Number(row.astrologer_earnings || 0).toLocaleString("en-IN")}</td><td className="p-3">{row.average_rating || "-"}</td></tr>
            ) : (
              <tr key={row.id} className="border-b"><td className="p-3 font-semibold">#{row.order_number || row.id}</td><td className="p-3">{row.user?.name || row.user_name || "-"}</td><td className="p-3">{row.astrologer?.name || row.ritual?.name || active.slice(0, -1)}</td><td className="p-3 font-semibold">₹{Number(row.total_amount || row.amount || 0).toLocaleString("en-IN")}</td><td className="p-3">{new Date(row.created_at).toLocaleDateString()}</td></tr>
            ))}
            {!loading && !rows.length && <tr><td colSpan="6" className="p-8 text-center text-gray-500">No paid records in this period.</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  );
}
