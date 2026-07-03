import { useEffect, useState } from "react";
import { apiRequest } from "../lib/api";

const statusOptions = ["pending", "confirmed", "scheduled", "completed", "cancelled"];

export default function RitualBookings() {
  const [bookings, setBookings] = useState([]);
  const [drafts, setDrafts] = useState({});
  const [message, setMessage] = useState("");
  const load = async () => {
    const response = await apiRequest("/admin/ritual-bookings");
    const rows = response.bookings || [];
    setBookings(rows);
    setDrafts(Object.fromEntries(rows.map((row) => [row.id, { status: row.status, admin_response: row.admin_response || "", confirmed_date: row.confirmed_date || "", confirmed_time: row.confirmed_time || "" }])));
  };
  useEffect(() => {
    const timer = window.setTimeout(() => { void load(); }, 0);
    return () => window.clearTimeout(timer);
  }, []);
  const change = (id, key, value) => setDrafts((current) => ({ ...current, [id]: { ...current[id], [key]: value } }));
  const save = async (id) => {
    try {
      await apiRequest(`/admin/ritual-bookings/${id}/status`, { method: "POST", body: drafts[id] });
      setMessage("Booking updated and the main-site user was notified.");
      await load();
    } catch (error) { setMessage(error.message); }
  };
  return <div className="space-y-6"><div><h1 className="text-2xl font-bold">Ritual Bookings</h1><p className="text-sm text-gray-500">Confirm schedules and respond to Pooja Anusthan requests.</p></div>{message && <div className="rounded-xl bg-white p-4 shadow">{message}</div>}<div className="space-y-4">{bookings.map((row) => <section key={row.id} className="rounded-xl bg-white p-5 shadow"><div className="mb-4 flex flex-wrap justify-between gap-3"><div><h2 className="font-bold">#{row.id} · {row.ritual?.name || row.ritual_name || "Ritual booking"}</h2><p className="text-sm text-gray-500">{row.user?.name || row.user_name} · {row.user?.email || row.user_email}</p></div><select value={drafts[row.id]?.status || "pending"} onChange={(e) => change(row.id, "status", e.target.value)} className="rounded-lg border px-3 py-2">{statusOptions.map((status) => <option key={status}>{status}</option>)}</select></div><div className="grid gap-3 md:grid-cols-2"><input type="date" value={drafts[row.id]?.confirmed_date || ""} onChange={(e) => change(row.id, "confirmed_date", e.target.value)} className="rounded-lg border p-3" /><input type="time" value={drafts[row.id]?.confirmed_time || ""} onChange={(e) => change(row.id, "confirmed_time", e.target.value)} className="rounded-lg border p-3" /></div><textarea rows="3" value={drafts[row.id]?.admin_response || ""} onChange={(e) => change(row.id, "admin_response", e.target.value)} placeholder="Response to customer" className="mt-3 w-full rounded-lg border p-3" /><button onClick={() => save(row.id)} className="mt-3 rounded-lg bg-yellow-500 px-4 py-2 font-semibold">Save and Notify</button></section>)}{!bookings.length && <div className="rounded-xl bg-white p-8 text-center text-gray-500">No ritual bookings.</div>}</div></div>;
}
