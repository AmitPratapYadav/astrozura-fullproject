import { Download, RefreshCw, Search } from "lucide-react";
import { useEffect, useState } from "react";
import { apiRequest } from "../lib/api";
import { exportToExcel } from "../utils/exportExcel";

export default function UserSubscriptions() {
  const [rows, setRows] = useState([]);
  const [stats, setStats] = useState({});
  const [q, setQ] = useState("");
  const [source, setSource] = useState("");
  const [loading, setLoading] = useState(true);
  const load = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ ...(q && { q }), ...(source && { source }) });
      const response = await apiRequest(`/admin/newsletter-subscribers?${params}`);
      setRows(response.data?.data || []);
      setStats(response.stats || {});
    } finally { setLoading(false); }
  };
  useEffect(() => { void load(); }, []);
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between"><div><h1 className="text-2xl font-bold">Newsletter Subscribers</h1><p className="text-sm text-gray-500">Subscribers from the main and shop websites.</p></div><button onClick={load} className="flex items-center gap-2 rounded-lg border bg-white px-4 py-2"><RefreshCw size={16} /> Refresh</button></div>
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">{[["Total", stats.total], ["Main website", stats.main], ["Shop", stats.shop], ["Active", stats.active]].map(([label, value]) => <div key={label} className="rounded-xl bg-white p-5 shadow"><p className="text-sm text-gray-500">{label}</p><p className="mt-2 text-3xl font-bold">{value || 0}</p></div>)}</div>
      <div className="flex flex-wrap gap-3 rounded-xl bg-white p-4 shadow"><label className="flex min-w-64 flex-1 items-center gap-2 rounded-lg border px-3"><Search size={17} /><input value={q} onChange={(e) => setQ(e.target.value)} onKeyDown={(e) => e.key === "Enter" && load()} placeholder="Search email" className="w-full py-2 outline-none" /></label><select value={source} onChange={(e) => setSource(e.target.value)} className="rounded-lg border px-3"><option value="">All sources</option><option value="main">Main</option><option value="shop">Shop</option></select><button onClick={load} className="rounded-lg bg-yellow-500 px-4 py-2 font-semibold">Apply</button><button onClick={() => exportToExcel(rows, "newsletter_subscribers")} className="flex items-center gap-2 rounded-lg border px-4 py-2"><Download size={16} /> Export</button></div>
      <div className="overflow-x-auto rounded-xl bg-white shadow"><table className="w-full min-w-[700px] text-sm"><thead className="bg-gray-100"><tr><th className="p-3 text-left">Email</th><th className="p-3 text-left">Source</th><th className="p-3 text-left">Status</th><th className="p-3 text-left">Subscribed</th></tr></thead><tbody>{loading ? <tr><td colSpan="4" className="p-8 text-center">Loading subscribers...</td></tr> : rows.map((row) => <tr key={row.id} className="border-b"><td className="p-3 font-medium">{row.email}</td><td className="p-3 capitalize">{row.source}</td><td className="p-3">{row.is_active ? "Active" : "Inactive"}</td><td className="p-3">{new Date(row.created_at).toLocaleString()}</td></tr>)}</tbody></table></div>
    </div>
  );
}
