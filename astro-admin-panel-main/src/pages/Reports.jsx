import { useEffect, useState } from "react";
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { apiRequest } from "../lib/api";

export default function Reports() {
  const [period, setPeriod] = useState("month");
  const [report, setReport] = useState(null);
  useEffect(() => { apiRequest(`/admin/analytics?period=${period}`).then(setReport); }, [period]);
  const totals = report?.totals || {};
  const cards = [["Users", totals.users], ["Bookings", totals.bookings], ["Consultation revenue", totals.booking_revenue], ["Platform commission", totals.platform_commission], ["Orders", totals.orders], ["Order revenue", totals.order_revenue], ["Rituals", totals.rituals], ["Ritual revenue", totals.ritual_revenue]];
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-3"><div><h1 className="text-2xl font-bold">Reports</h1><p className="text-sm text-gray-500">Live business performance across every surface.</p></div><select value={period} onChange={(e) => setPeriod(e.target.value)} className="rounded-lg border bg-white px-4 py-2"><option value="week">Weekly</option><option value="month">Monthly</option><option value="year">Yearly</option></select></div>
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">{cards.map(([label, value]) => <div key={label} className="rounded-xl bg-white p-5 shadow"><p className="text-xs uppercase text-gray-500">{label}</p><p className="mt-2 text-2xl font-bold">{label.toLowerCase().includes("revenue") || label.includes("commission") ? `₹${Number(value || 0).toLocaleString("en-IN")}` : value || 0}</p></div>)}</div>
      {[["Consultations", report?.series?.bookings], ["Shop orders", report?.series?.orders], ["Pooja Anusthan", report?.series?.rituals]].map(([label, series]) => <section key={label} className="rounded-xl bg-white p-5 shadow"><h2 className="mb-4 font-semibold">{label}</h2><div className="h-72 w-full"><ResponsiveContainer><BarChart data={series || []}><CartesianGrid strokeDasharray="3 3" /><XAxis dataKey="label" /><YAxis /><Tooltip /><Bar dataKey="revenue" fill="#eab308" /><Bar dataKey="total" fill="#1e3a5f" /></BarChart></ResponsiveContainer></div></section>)}
    </div>
  );
}
