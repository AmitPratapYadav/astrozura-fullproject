import { Download, Search } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { apiRequest } from "../lib/api";
import { exportToExcel } from "../utils/exportExcel";

export default function Users() {
  const [search, setSearch] = useState("");
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    apiRequest("/admin/users")
      .then((response) => setUsers(response.users || []))
      .catch((requestError) => setError(requestError.message))
      .finally(() => setLoading(false));
  }, []);

  const filtered = useMemo(() => users.filter((user) =>
    [user.name, user.email, user.phone].filter(Boolean).join(" ").toLowerCase().includes(search.toLowerCase())
  ), [users, search]);

  return <div className="space-y-6">
    <div><h1 className="text-2xl font-bold">Users</h1><p className="text-sm text-gray-500">Customer accounts across AstroZura and the shop.</p></div>
    {error && <div className="rounded-xl bg-red-50 p-4 text-red-700">{error}</div>}
    <div className="flex flex-wrap gap-3">
      <label className="flex min-w-64 flex-1 items-center rounded-lg bg-white px-3 shadow-sm"><Search size={18} /><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search users" className="w-full bg-transparent p-3 outline-none" /></label>
      <button onClick={() => exportToExcel(filtered, "users")} className="flex items-center gap-2 rounded-lg border bg-white px-4 py-2"><Download size={16} /> Export</button>
    </div>
    <div className="overflow-x-auto rounded-xl bg-white shadow"><table className="w-full min-w-[760px] text-sm"><thead className="bg-gray-100"><tr><th className="p-3 text-left">Name</th><th className="p-3 text-left">Email</th><th className="p-3 text-left">Phone</th><th className="p-3 text-left">Joined</th><th className="p-3 text-left">Activity</th></tr></thead><tbody>{loading ? <tr><td colSpan="5" className="p-8 text-center">Loading users...</td></tr> : filtered.map((user) => <tr key={user.id} className="border-b hover:bg-gray-50"><td className="p-3 font-semibold">{user.name || "N/A"}</td><td className="p-3">{user.email || "-"}</td><td className="p-3">{user.phone || "-"}</td><td className="p-3">{new Date(user.created_at).toLocaleDateString()}</td><td className="p-3"><Link to={`/users/${user.id}`} className="rounded-lg border px-3 py-2 font-semibold text-blue-700">View Details</Link></td></tr>)}{!loading && !filtered.length && <tr><td colSpan="5" className="p-8 text-center text-gray-500">No users found.</td></tr>}</tbody></table></div>
  </div>;
}
