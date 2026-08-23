import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { apiRequest } from "../lib/api";
import { formatDateTime, toDateInputValue, toTimeInputValue } from "../lib/dateTime";

const statusOptions = ["consultation_scheduled", "payment_requested", "confirmed", "completed", "cancelled"];

const badgeClass = (status = "") =>
  ({
    consultation_scheduled: "bg-blue-50 text-blue-700",
    payment_requested: "bg-amber-50 text-amber-700",
    confirmed: "bg-emerald-50 text-emerald-700",
    completed: "bg-emerald-50 text-emerald-700",
    cancelled: "bg-rose-50 text-rose-700",
  }[status] || "bg-gray-100 text-gray-600");

export default function RitualBookings() {
  const [bookings, setBookings] = useState([]);
  const [drafts, setDrafts] = useState({});
  const [message, setMessage] = useState("");

  const load = async () => {
    const response = await apiRequest("/admin/ritual-bookings");
    const rows = response.bookings || [];
    setBookings(rows);
    setDrafts(Object.fromEntries(rows.map((row) => [row.id, {
      status: row.status || "consultation_scheduled",
      admin_response: row.admin_response || "",
      confirmed_date: toDateInputValue(row.confirmed_date),
      confirmed_time: toTimeInputValue(row.confirmed_time),
    }])));
  };

  useEffect(() => {
    void load();
  }, []);

  const change = (id, key, value) => setDrafts((current) => ({ ...current, [id]: { ...current[id], [key]: value } }));

  const save = async (id) => {
    try {
      await apiRequest(`/admin/ritual-bookings/${id}/status`, { method: "POST", body: drafts[id] });
      setMessage("Booking updated and the main-site user was notified.");
      await load();
    } catch (error) {
      setMessage(error.message);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold">Ritual Bookings</h1>
          <p className="text-sm text-gray-500">Track consultation-first Pooja Anusthan bookings, payment requests, and user details.</p>
        </div>
        <Link to="/rituals" className="rounded-xl bg-yellow-500 px-4 py-2 text-sm font-semibold text-black">
          Manage Rituals
        </Link>
      </div>

      {message && <div className="rounded-xl bg-white p-4 shadow">{message}</div>}

      <div className="space-y-4">
        {bookings.map((row) => (
          <section key={row.id} className="rounded-xl bg-white p-5 shadow">
            <div className="flex flex-wrap items-start justify-between gap-4">
              <div>
                <p className="text-xs font-semibold uppercase tracking-wide text-yellow-600">{row.booking_reference}</p>
                <h2 className="mt-1 text-lg font-bold">{row.ritual?.name || row.ritual_name || "Ritual booking"}</h2>
                <p className="mt-1 text-sm text-gray-500">
                  {row.user?.name || row.devotee_name} · {row.devotee_phone || row.user?.phone || "-"}
                </p>
              </div>
              <span className={`rounded-full px-3 py-1 text-xs font-bold uppercase ${badgeClass(row.status)}`}>
                {row.status}
              </span>
            </div>

            <div className="mt-5 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
              <Info label="Ritual Expert" value={row.astrologer?.name || "Not assigned"} />
              <Info label="Consultation Booking" value={row.consultation_booking?.booking_reference || "-"} />
              <Info label="Scheduled" value={formatDateTime(row.consultation_booking?.scheduled_at)} />
              <Info label="Payment" value={row.payment_status === "paid" ? `Paid Rs ${Number(row.amount || 0).toLocaleString("en-IN")}` : row.payment_status || "not_requested"} />
            </div>

            <div className="mt-5 grid gap-4 lg:grid-cols-[1.2fr_0.8fr]">
              <div className="rounded-xl border border-gray-100 bg-gray-50 p-4 text-sm">
                <p className="font-semibold text-gray-900">Devotee Details</p>
                <div className="mt-3 grid gap-2 md:grid-cols-2">
                  <p>Name: {row.devotee_name}</p>
                  <p>Email: {row.devotee_email || row.user?.email || "-"}</p>
                  <p>Mode: {row.venue_type || "-"}</p>
                  <p>Location: {[row.location_city, row.location_state, row.location_pincode].filter(Boolean).join(", ") || "-"}</p>
                </div>
                {row.location_address && <p className="mt-3">Address: {row.location_address}</p>}
                {row.notes && <p className="mt-3">Notes: {row.notes}</p>}
              </div>

              <div className="rounded-xl border border-gray-100 bg-gray-50 p-4">
                <p className="font-semibold text-gray-900">Admin Update</p>
                <select value={drafts[row.id]?.status || row.status} onChange={(e) => change(row.id, "status", e.target.value)} className="mt-3 w-full rounded-lg border px-3 py-2">
                  {statusOptions.map((status) => <option key={status} value={status}>{status}</option>)}
                </select>
                <div className="mt-3 grid gap-3 md:grid-cols-2">
                  <input type="date" value={drafts[row.id]?.confirmed_date || ""} onChange={(e) => change(row.id, "confirmed_date", e.target.value)} className="rounded-lg border p-3" />
                  <input type="time" value={drafts[row.id]?.confirmed_time || ""} onChange={(e) => change(row.id, "confirmed_time", e.target.value)} className="rounded-lg border p-3" />
                </div>
                <textarea rows="3" value={drafts[row.id]?.admin_response || ""} onChange={(e) => change(row.id, "admin_response", e.target.value)} placeholder="Response to customer" className="mt-3 w-full rounded-lg border p-3" />
                <button onClick={() => save(row.id)} className="mt-3 rounded-lg bg-yellow-500 px-4 py-2 font-semibold">Save and Notify</button>
              </div>
            </div>

            {!!row.updates?.length && (
              <div className="mt-5 rounded-xl border border-yellow-100 bg-yellow-50 p-4">
                <p className="font-semibold">Astrologer Response History</p>
                <div className="mt-3 space-y-3">
                  {row.updates.map((update) => (
                    <div key={update.id} className="rounded-lg bg-white p-3 text-sm">
                      <div className="flex justify-between gap-3">
                        <span className="font-semibold">{update.type}</span>
                        {Number(update.amount || 0) > 0 && <span>Rs {Number(update.amount).toLocaleString("en-IN")}</span>}
                      </div>
                      {update.message && <p className="mt-2 text-gray-600">{update.message}</p>}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </section>
        ))}
        {!bookings.length && <div className="rounded-xl bg-white p-8 text-center text-gray-500">No ritual bookings.</div>}
      </div>
    </div>
  );
}

function Info({ label, value }) {
  return (
    <div className="rounded-xl border border-gray-100 bg-gray-50 p-4">
      <p className="text-xs font-semibold uppercase tracking-wide text-gray-400">{label}</p>
      <p className="mt-2 font-semibold text-gray-900">{value}</p>
    </div>
  );
}
