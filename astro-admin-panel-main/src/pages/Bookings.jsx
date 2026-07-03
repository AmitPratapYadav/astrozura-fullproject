import { Download, RefreshCw, Search } from "lucide-react";
import { useEffect, useState } from "react";
import { apiRequest } from "../lib/api";
import { exportToExcel } from "../utils/exportExcel";

const statuses = ["pending", "confirmed", "completed", "cancelled"];

export default function Bookings() {
  const [bookings, setBookings] = useState([]);
  const [astrologers, setAstrologers] = useState([]);
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState("");
  const [type, setType] = useState("");
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState("");

  const load = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ ...(search && { search }), ...(status && { status }), ...(type && { type }) });
      const [bookingData, astrologerData] = await Promise.all([
        apiRequest(`/admin/bookings?${params}`),
        apiRequest("/admin/astrologers"),
      ]);
      setBookings(bookingData.bookings || []);
      setAstrologers(astrologerData.astrologers || []);
    } catch (error) {
      setMessage(error.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { void load(); }, []);

  const updateStatus = async (id, nextStatus) => {
    try {
      await apiRequest(`/admin/bookings/${id}/status`, { method: "POST", body: { status: nextStatus } });
      await load();
    } catch (error) {
      setMessage(error.message);
    }
  };

  const reassign = async (booking, astrologerId) => {
    if (!astrologerId) return;
    const reason = window.prompt("Reason for reassignment:", "Current astrologer unavailable");
    if (reason === null) return;
    try {
      await apiRequest(`/admin/bookings/${booking.id}/reassign`, {
        method: "POST",
        body: { astrologer_id: Number(astrologerId), reason },
      });
      setMessage("Booking reassigned and both parties notified.");
      await load();
    } catch (error) {
      setMessage(error.message);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div><h1 className="text-2xl font-bold">Bookings</h1><p className="text-sm text-gray-500">Manage consultation status and assignments.</p></div>
        <button onClick={load} className="flex items-center gap-2 rounded-lg border bg-white px-4 py-2"><RefreshCw size={16} /> Refresh</button>
      </div>
      {message && <div className="rounded-lg bg-white p-4 text-sm shadow">{message}</div>}
      <div className="flex flex-wrap gap-3 rounded-xl bg-white p-4 shadow">
        <label className="flex min-w-64 flex-1 items-center gap-2 rounded-lg border px-3"><Search size={17} /><input value={search} onChange={(e) => setSearch(e.target.value)} onKeyDown={(e) => e.key === "Enter" && load()} placeholder="Search booking" className="w-full py-2 outline-none" /></label>
        <select value={status} onChange={(e) => setStatus(e.target.value)} className="rounded-lg border px-3 py-2"><option value="">All statuses</option>{statuses.map((item) => <option key={item}>{item}</option>)}</select>
        <select value={type} onChange={(e) => setType(e.target.value)} className="rounded-lg border px-3 py-2"><option value="">Chat and call</option><option value="chat">Chat</option><option value="call">Call</option></select>
        <button onClick={load} className="rounded-lg bg-yellow-500 px-4 py-2 font-semibold">Apply</button>
        <button onClick={() => exportToExcel(bookings, "bookings")} className="flex items-center gap-2 rounded-lg border px-4 py-2"><Download size={16} /> Export</button>
      </div>
      <div className="overflow-x-auto rounded-xl bg-white shadow">
        <table className="w-full min-w-[1120px] text-sm">
          <thead className="bg-gray-100"><tr><th className="p-3 text-left">Booking</th><th className="p-3 text-left">User</th><th className="p-3 text-left">Astrologer</th><th className="p-3 text-left">Mode</th><th className="p-3 text-left">Schedule</th><th className="p-3 text-left">Amount</th><th className="p-3 text-left">Status</th><th className="p-3 text-left">Reassign</th></tr></thead>
          <tbody>
            {loading ? <tr><td colSpan="8" className="p-8 text-center">Loading bookings...</td></tr> : bookings.map((item) => (
              <tr key={item.id} className="border-b align-top">
                <td className="p-3 font-semibold">#{item.id}</td>
                <td className="p-3"><p>{item.user_name || item.user?.name || "-"}</p><p className="text-xs text-gray-500">{item.user_email || item.user?.email}</p></td>
                <td className="p-3">{item.astrologer_name || item.astrologer?.name || "-"}</td>
                <td className="p-3 capitalize">{item.consultation_type}</td>
                <td className="p-3">{item.booking_date}<br /><span className="text-gray-500">{item.booking_time}</span></td>
                <td className="p-3 font-semibold">₹{Number(item.amount || 0).toLocaleString("en-IN")}</td>
                <td className="p-3"><select value={item.status} onChange={(e) => updateStatus(item.id, e.target.value)} className="rounded-lg border px-2 py-1 capitalize">{statuses.map((entry) => <option key={entry}>{entry}</option>)}</select></td>
                <td className="p-3"><select defaultValue="" onChange={(e) => reassign(item, e.target.value)} className="max-w-52 rounded-lg border px-2 py-1"><option value="">Select astrologer</option>{astrologers.filter((candidate) => candidate.id !== item.astrologer_id).map((candidate) => <option key={candidate.id} value={candidate.id}>{candidate.name}</option>)}</select></td>
              </tr>
            ))}
            {!loading && !bookings.length && <tr><td colSpan="8" className="p-8 text-center text-gray-500">No bookings found.</td></tr>}
          </tbody>
        </table>
      </div>
    </div>
  );
}
