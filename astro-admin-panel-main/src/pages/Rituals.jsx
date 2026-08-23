import { useEffect, useState } from "react";
import { Pencil, RotateCcw, Save, Trash2 } from "lucide-react";
import { Link } from "react-router-dom";
import { apiRequest, assetUrl } from "../lib/api";
import { formatDate, formatTime, toDateInputValue, toTimeInputValue } from "../lib/dateTime";

const initialForm = {
  name: "",
  service_type: "Pooja",
  category: "",
  short_description: "",
  description: "",
  benefits: "",
  materials_required: "",
  ideal_timing: "",
  duration_label: "",
  mode: "Online/Offline",
  assigned_astrologer_id: "",
  steps: "",
  materials: "",
  faqs: "",
  mantras: "",
  is_popular: false,
  status: true,
  image: null,
  name_hi: "",
  short_description_hi: "",
  description_hi: "",
};

const statusOptions = ["pending", "confirmed", "scheduled", "completed", "cancelled"];

const toMultiline = (value) => {
  if (!Array.isArray(value)) {
    return "";
  }

  return value.join("\n");
};

const toFaqMultiline = (value) => {
  if (!Array.isArray(value)) {
    return "";
  }

  return value
    .map((item) => `${item?.question || ""}|${item?.answer || ""}`.trim())
    .filter(Boolean)
    .join("\n");
};

const buildBookingDraft = (booking) => ({
  status: booking.status || "pending",
  admin_response: booking.admin_response || "",
  confirmed_date: toDateInputValue(booking.confirmed_date),
  confirmed_time: toTimeInputValue(booking.confirmed_time),
});

const formatVenue = (booking) =>
  ({
    temple: "Temple Arrangement",
    client_place: "At Client Location",
    online: "Online Guidance",
  }[booking.venue_type] || booking.venue_type || "Ritual");

export default function Rituals() {
  const [rituals, setRituals] = useState([]);
  const [ritualBookings, setRitualBookings] = useState([]);
  const [bookingDrafts, setBookingDrafts] = useState({});
  const [astrologers, setAstrologers] = useState([]);
  const [form, setForm] = useState(initialForm);
  const [editingId, setEditingId] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState("");
  const [updatingBookingId, setUpdatingBookingId] = useState(null);

  const loadData = async () => {
    try {
      setLoading(true);
      const [ritualResponse, astrologerResponse, bookingsResponse] = await Promise.all([
        apiRequest("/admin/rituals"),
        apiRequest("/astrologers", { requiresAuth: false }),
        apiRequest("/admin/ritual-bookings"),
      ]);

      const bookings = bookingsResponse?.bookings || [];

      setRituals(ritualResponse?.rituals || []);
      setAstrologers(astrologerResponse?.astrologers || []);
      setRitualBookings(bookings);
      setBookingDrafts(
        Object.fromEntries(bookings.map((booking) => [booking.id, buildBookingDraft(booking)]))
      );
    } catch (error) {
      console.error("Failed to load rituals module", error);
      setMessage(error.message || "Unable to load rituals.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadData();
  }, []);

  useEffect(() => {
    if (!message) return undefined;
    const timer = window.setTimeout(() => setMessage(""), 2800);
    return () => window.clearTimeout(timer);
  }, [message]);

  const resetForm = () => {
    setForm(initialForm);
    setEditingId(null);
  };

  const handleChange = (event) => {
    const { name, value, type, checked, files } = event.target;

    if (name === "image") {
      setForm((current) => ({ ...current, image: files?.[0] || null }));
      return;
    }

    setForm((current) => ({
      ...current,
      [name]: type === "checkbox" ? checked : value,
    }));
  };

  const handleEdit = (ritual) => {
    setEditingId(ritual.id);
    setForm({
      name: ritual.name || "",
      service_type: ritual.service_type || "Pooja",
      category: ritual.category || "",
      short_description: ritual.short_description || "",
      description: ritual.description || "",
      benefits: ritual.benefits || "",
      materials_required: ritual.materials_required || "",
      ideal_timing: ritual.ideal_timing || "",
      duration_label: ritual.duration_label || "",
      mode: ritual.mode || "Online/Offline",
      assigned_astrologer_id: ritual.assigned_astrologer_id || "",
      steps: toMultiline(ritual.steps),
      materials: toMultiline(ritual.materials),
      faqs: toFaqMultiline(ritual.faqs),
      mantras: toMultiline(ritual.mantras),
      is_popular: Boolean(ritual.is_popular),
      status: Boolean(ritual.status),
      image: null,
      name_hi: ritual.translations?.hi?.name || "",
      short_description_hi: ritual.translations?.hi?.short_description || "",
      description_hi: ritual.translations?.hi?.description || "",
    });

    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    try {
      setSaving(true);
      const payload = new FormData();

      Object.entries(form).forEach(([key, value]) => {
        if (["name_hi", "short_description_hi", "description_hi"].includes(key)) {
          return;
        }
        if (key === "image") {
          if (value) {
            payload.append("image", value);
          }
          return;
        }

        if (value === "" || value === null) {
          return;
        }

        if (typeof value === "boolean") {
          payload.append(key, value ? "1" : "0");
          return;
        }

        payload.append(key, value);
      });
      payload.append("translations", JSON.stringify({ hi: {
        name: form.name_hi,
        short_description: form.short_description_hi,
        description: form.description_hi,
      } }));

      const endpoint = editingId ? `/admin/rituals/${editingId}` : "/admin/rituals";
      const response = await apiRequest(endpoint, {
        method: "POST",
        body: payload,
      });

      if (response?.success) {
        setMessage(editingId ? "Ritual updated successfully." : "Ritual created successfully.");
        resetForm();
        await loadData();
      }
    } catch (error) {
      setMessage(error.message || "Unable to save ritual.");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Delete this ritual?")) return;

    try {
      await apiRequest(`/admin/rituals/${id}`, {
        method: "DELETE",
      });

      if (editingId === id) {
        resetForm();
      }

      setMessage("Ritual deleted successfully.");
      await loadData();
    } catch (error) {
      setMessage(error.message || "Unable to delete ritual.");
    }
  };

  const updateBookingDraft = (bookingId, field, value) => {
    setBookingDrafts((current) => ({
      ...current,
      [bookingId]: {
        ...current[bookingId],
        [field]: value,
      },
    }));
  };

  const handleBookingUpdate = async (bookingId) => {
    try {
      setUpdatingBookingId(bookingId);
      const response = await apiRequest(`/admin/ritual-bookings/${bookingId}/status`, {
        method: "POST",
        body: bookingDrafts[bookingId],
      });

      if (response?.success) {
        setRitualBookings((current) =>
          current.map((booking) => (booking.id === bookingId ? response.booking : booking))
        );
        setBookingDrafts((current) => ({
          ...current,
          [bookingId]: buildBookingDraft(response.booking),
        }));
        setMessage("Ritual booking updated successfully.");
      }
    } catch (error) {
      setMessage(error.message || "Unable to update ritual booking.");
    } finally {
      setUpdatingBookingId(null);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Pooja / Anusthan Management</h1>
        <p className="mt-2 text-sm text-gray-500">
          Create and maintain the Pooja Anusthan service catalogue.
        </p>
        <Link to="/ritual-bookings" className="mt-4 inline-flex rounded-xl bg-yellow-500 px-4 py-2 text-sm font-semibold text-black">
          View Ritual Bookings
        </Link>
      </div>

      {message && <div className="rounded-2xl bg-white p-4 text-sm shadow">{message}</div>}

      <form onSubmit={handleSubmit} className="space-y-5 rounded-2xl bg-white p-6 shadow">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h2 className="text-xl font-bold">{editingId ? "Edit Ritual" : "Create Ritual"}</h2>
            <p className="mt-1 text-sm text-gray-500">
              {editingId ? "Update the selected ritual details and save changes." : "Add a new pooja or anusthan listing."}
            </p>
          </div>
          {editingId && (
            <button
              type="button"
              onClick={resetForm}
              className="inline-flex items-center gap-2 rounded-xl border border-gray-200 px-4 py-3 text-sm font-semibold text-[#1E3557]"
            >
              <RotateCcw size={16} />
              Cancel Edit
            </button>
          )}
        </div>

        <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
          <input name="name" value={form.name} onChange={handleChange} placeholder="Ritual Name" className="rounded-xl border px-4 py-3 outline-none focus:border-yellow-500" required />
          <input name="category" value={form.category} onChange={handleChange} placeholder="Category" className="rounded-xl border px-4 py-3 outline-none focus:border-yellow-500" required />
          <input name="service_type" value={form.service_type} onChange={handleChange} placeholder="Service Type" className="rounded-xl border px-4 py-3 outline-none focus:border-yellow-500" required />
          <input name="duration_label" value={form.duration_label} onChange={handleChange} placeholder="Duration" className="rounded-xl border px-4 py-3 outline-none focus:border-yellow-500" required />
          <input name="ideal_timing" value={form.ideal_timing} onChange={handleChange} placeholder="Ideal Timing" className="rounded-xl border px-4 py-3 outline-none focus:border-yellow-500" />
          <input name="mode" value={form.mode} onChange={handleChange} placeholder="Mode" className="rounded-xl border px-4 py-3 outline-none focus:border-yellow-500" />
          <select name="assigned_astrologer_id" value={form.assigned_astrologer_id} onChange={handleChange} className="rounded-xl border px-4 py-3 outline-none focus:border-yellow-500">
            <option value="">Assign Astrologer (Optional)</option>
            {astrologers.map((astrologer) => (
              <option key={astrologer.id} value={astrologer.id}>
                {astrologer.name}
              </option>
            ))}
          </select>
          <input type="file" name="image" accept="image/*" onChange={handleChange} className="rounded-xl border px-4 py-3 outline-none focus:border-yellow-500" />
        </div>

        <textarea name="short_description" value={form.short_description} onChange={handleChange} rows="3" placeholder="Short Description" className="w-full rounded-xl border px-4 py-3 outline-none focus:border-yellow-500" required />
        <textarea name="description" value={form.description} onChange={handleChange} rows="4" placeholder="Full Description" className="w-full rounded-xl border px-4 py-3 outline-none focus:border-yellow-500" />
        <textarea name="benefits" value={form.benefits} onChange={handleChange} rows="2" placeholder="Benefits Summary" className="w-full rounded-xl border px-4 py-3 outline-none focus:border-yellow-500" />
        <textarea name="materials_required" value={form.materials_required} onChange={handleChange} rows="2" placeholder="Materials Required" className="w-full rounded-xl border px-4 py-3 outline-none focus:border-yellow-500" />
        <div className="grid gap-3 rounded-xl border bg-gray-50 p-4 md:grid-cols-2">
          <input name="name_hi" value={form.name_hi} onChange={handleChange} placeholder="Ritual name in Hindi" className="rounded-xl border px-4 py-3" />
          <textarea name="short_description_hi" value={form.short_description_hi} onChange={handleChange} placeholder="Short description in Hindi" className="rounded-xl border px-4 py-3" />
          <textarea name="description_hi" value={form.description_hi} onChange={handleChange} rows="3" placeholder="Full description in Hindi" className="rounded-xl border px-4 py-3 md:col-span-2" />
        </div>

        <div className="grid gap-5 md:grid-cols-2">
          <textarea name="steps" value={form.steps} onChange={handleChange} rows="5" placeholder="Steps (one per line)" className="w-full rounded-xl border px-4 py-3 outline-none focus:border-yellow-500" />
          <textarea name="materials" value={form.materials} onChange={handleChange} rows="5" placeholder="Materials List (one per line)" className="w-full rounded-xl border px-4 py-3 outline-none focus:border-yellow-500" />
          <textarea name="mantras" value={form.mantras} onChange={handleChange} rows="4" placeholder="Mantras (one per line)" className="w-full rounded-xl border px-4 py-3 outline-none focus:border-yellow-500" />
          <textarea name="faqs" value={form.faqs} onChange={handleChange} rows="4" placeholder="FAQs (Question|Answer per line)" className="w-full rounded-xl border px-4 py-3 outline-none focus:border-yellow-500" />
        </div>

        <div className="flex flex-wrap items-center gap-6">
          <label className="flex items-center gap-2 text-sm font-medium text-gray-700">
            <input type="checkbox" name="is_popular" checked={form.is_popular} onChange={handleChange} />
            Mark as Popular
          </label>
          <label className="flex items-center gap-2 text-sm font-medium text-gray-700">
            <input type="checkbox" name="status" checked={form.status} onChange={handleChange} />
            Active
          </label>
          <button type="submit" disabled={saving} className="inline-flex items-center gap-2 rounded-xl bg-yellow-500 px-5 py-3 font-semibold text-black">
            <Save size={16} />
            {saving ? "Saving..." : editingId ? "Update Ritual" : "Create Ritual"}
          </button>
        </div>
      </form>

      <div className="rounded-2xl bg-white p-6 shadow">
        <div className="flex items-center justify-between gap-4">
          <div>
            <h2 className="text-xl font-bold">Existing Rituals</h2>
            <p className="mt-1 text-sm text-gray-500">The full ritual list is editable from here.</p>
          </div>
          <div className="rounded-full bg-[#FFF9EC] px-4 py-2 text-sm font-semibold text-[#D4A73C]">
            {rituals.length} total
          </div>
        </div>

        {loading ? (
          <p className="mt-4 text-sm text-gray-500">Loading rituals...</p>
        ) : (
          <div className="mt-6 grid gap-4">
            {rituals.map((ritual) => (
              <div key={ritual.id} className="flex flex-col gap-4 rounded-2xl border border-gray-100 p-4 md:flex-row md:items-center">
                {ritual.image ? (
                  <img src={assetUrl(ritual.image)} alt={ritual.name} className="h-24 w-24 rounded-2xl bg-gray-100 object-cover" />
                ) : (
                  <div className="flex h-24 w-24 items-center justify-center rounded-2xl bg-gray-100 text-xs font-semibold uppercase tracking-[0.16em] text-gray-500">
                    Ritual
                  </div>
                )}

                <div className="flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <p className="text-xs font-semibold uppercase tracking-[0.16em] text-yellow-600">{ritual.category}</p>
                    {ritual.is_popular && (
                      <span className="rounded-full bg-[#FFF9EC] px-2 py-1 text-[11px] font-semibold text-[#D4A73C]">
                        Popular
                      </span>
                    )}
                  </div>
                  <h3 className="mt-1 text-lg font-bold">{ritual.name}</h3>
                  <p className="mt-1 text-sm text-gray-500">{ritual.short_description}</p>
                  <p className="mt-2 text-xs text-gray-400">
                    Assigned astrologer: {ritual.assigned_astrologer?.name || "Not assigned"}
                  </p>
                </div>

                <div className="text-sm text-gray-500">
                  <p>{ritual.duration_label}</p>
                  <p className="mt-1 font-semibold text-[#1E3557]">Consultation-first pricing</p>
                </div>

                <div className="flex gap-3">
                  <button
                    type="button"
                    onClick={() => handleEdit(ritual)}
                    className="rounded-xl border border-blue-200 px-4 py-3 text-blue-600"
                  >
                    <Pencil size={18} />
                  </button>
                  <button
                    type="button"
                    onClick={() => void handleDelete(ritual.id)}
                    className="rounded-xl border border-red-200 px-4 py-3 text-red-500"
                  >
                    <Trash2 size={18} />
                  </button>
                </div>
              </div>
            ))}
            {!rituals.length && <p className="text-sm text-gray-500">No rituals available.</p>}
          </div>
        )}
      </div>

      {false && <div className="rounded-2xl bg-white p-6 shadow">
        <div className="flex items-center justify-between gap-4">
          <div>
            <h2 className="text-xl font-bold">Ritual Bookings</h2>
            <p className="mt-1 text-sm text-gray-500">
              Ritual requests from the dedicated booking page appear here for admin review and response.
            </p>
          </div>
          <div className="rounded-full bg-[#F8F9FC] px-4 py-2 text-sm font-semibold text-[#1E3557]">
            {ritualBookings.length} bookings
          </div>
        </div>

        <div className="mt-6 space-y-5">
          {ritualBookings.map((booking) => {
            const draft = bookingDrafts[booking.id] || buildBookingDraft(booking);

            return (
              <div key={booking.id} className="rounded-2xl border border-gray-100 p-5">
                <div className="grid gap-5 xl:grid-cols-[1.2fr_1fr]">
                  <div className="space-y-4">
                    <div className="flex flex-wrap items-center justify-between gap-3">
                      <div>
                        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-yellow-600">
                          {booking.booking_reference}
                        </p>
                        <h3 className="mt-1 text-lg font-bold text-[#1E3557]">
                          {booking.ritual?.name || "Ritual Booking"}
                        </h3>
                        <p className="mt-1 text-sm text-gray-500">
                          {formatVenue(booking)}
                          {booking.astrologer?.name ? ` - ${booking.astrologer.name}` : ""}
                        </p>
                      </div>
                      <div className="rounded-full bg-[#FFF9EC] px-3 py-1 text-xs font-semibold uppercase text-[#D4A73C]">
                        {booking.status}
                      </div>
                    </div>

                    <div className="grid gap-4 md:grid-cols-2">
                      <div className="rounded-2xl bg-[#F8F9FC] p-4">
                        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-gray-400">Devotee</p>
                        <p className="mt-2 font-semibold text-[#1E3557]">{booking.devotee_name}</p>
                        <p className="mt-1 text-sm text-gray-500">{booking.devotee_phone}</p>
                        <p className="mt-1 text-sm text-gray-500">{booking.devotee_email || "-"}</p>
                      </div>

                      <div className="rounded-2xl bg-[#F8F9FC] p-4">
                        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-gray-400">Requested Schedule</p>
                        <p className="mt-2 font-semibold text-[#1E3557]">{formatDate(booking.preferred_date)}</p>
                        <p className="mt-1 text-sm text-gray-500">{formatTime(booking.preferred_time)}</p>
                        <p className="mt-3 text-xs font-semibold uppercase tracking-[0.16em] text-gray-400">Amount</p>
                        <p className="mt-1 font-semibold text-[#1E3557]">Rs {Number(booking.amount || 0).toLocaleString("en-IN")}</p>
                      </div>
                    </div>

                    <div className="rounded-2xl border border-[#efe4d2] p-4 text-sm">
                      <p className="font-semibold text-[#1E3557]">Location Details</p>
                      <p className="mt-2 text-gray-600">{booking.location_address || "No address provided."}</p>
                      <p className="mt-2 text-gray-600">
                        {[booking.location_city, booking.location_state, booking.location_pincode].filter(Boolean).join(", ") || "-"}
                      </p>
                      {booking.venue_type === "client_place" && (
                        <p className="mt-3 text-xs font-medium text-[#b45309]">
                          Client agreed to bear priest travel and accommodation expenses: {booking.expense_acknowledged ? "Yes" : "No"}
                        </p>
                      )}
                    </div>

                    {booking.notes && (
                      <div className="rounded-2xl bg-[#F8F9FC] p-4 text-sm text-gray-600">
                        <p className="font-semibold text-[#1E3557]">Special Instructions</p>
                        <p className="mt-2 leading-6">{booking.notes}</p>
                      </div>
                    )}

                    {Object.keys(booking.birth_details || {}).length > 0 && (
                      <div className="rounded-2xl bg-[#FFF9EC] p-4 text-sm text-[#1E3557]">
                        <p className="font-semibold">Birth Details Shared</p>
                        <div className="mt-2 space-y-1 text-sm">
                          {booking.birth_details.date_of_birth && <p>DOB: {booking.birth_details.date_of_birth}</p>}
                          {booking.birth_details.time_of_birth && <p>Time: {booking.birth_details.time_of_birth}</p>}
                          {booking.birth_details.place_of_birth && <p>Place: {booking.birth_details.place_of_birth}</p>}
                        </div>
                      </div>
                    )}
                  </div>

                  <div className="space-y-4 rounded-2xl bg-[#fcfcfd] p-4">
                    <div>
                      <p className="text-sm font-semibold text-[#1E3557]">Admin Response Panel</p>
                      <p className="mt-1 text-xs text-gray-500">
                        Confirm the schedule, update the status, and send the response that the user will see on their bookings page.
                      </p>
                    </div>

                    <div className="space-y-3">
                      <label className="block">
                        <span className="mb-2 block text-xs font-semibold uppercase tracking-[0.16em] text-gray-400">Status</span>
                        <select
                          value={draft.status}
                          disabled={updatingBookingId === booking.id}
                          onChange={(event) => updateBookingDraft(booking.id, "status", event.target.value)}
                          className="w-full rounded-xl border px-3 py-2 outline-none focus:border-yellow-500"
                        >
                          {statusOptions.map((status) => (
                            <option key={status} value={status}>
                              {status}
                            </option>
                          ))}
                        </select>
                      </label>

                      <div className="grid gap-3 md:grid-cols-2">
                        <label className="block">
                          <span className="mb-2 block text-xs font-semibold uppercase tracking-[0.16em] text-gray-400">Confirmed Date</span>
                          <input
                            type="date"
                            value={draft.confirmed_date}
                            disabled={updatingBookingId === booking.id}
                            onChange={(event) => updateBookingDraft(booking.id, "confirmed_date", event.target.value)}
                            className="w-full rounded-xl border px-3 py-2 outline-none focus:border-yellow-500"
                          />
                        </label>

                        <label className="block">
                          <span className="mb-2 block text-xs font-semibold uppercase tracking-[0.16em] text-gray-400">Confirmed Time</span>
                          <input
                            type="time"
                            value={draft.confirmed_time}
                            disabled={updatingBookingId === booking.id}
                            onChange={(event) => updateBookingDraft(booking.id, "confirmed_time", event.target.value)}
                            className="w-full rounded-xl border px-3 py-2 outline-none focus:border-yellow-500"
                          />
                        </label>
                      </div>

                      <label className="block">
                        <span className="mb-2 block text-xs font-semibold uppercase tracking-[0.16em] text-gray-400">Response to User</span>
                        <textarea
                          value={draft.admin_response}
                          disabled={updatingBookingId === booking.id}
                          onChange={(event) => updateBookingDraft(booking.id, "admin_response", event.target.value)}
                          rows="6"
                          className="w-full rounded-xl border px-3 py-3 outline-none focus:border-yellow-500"
                          placeholder="Write the admin confirmation, required preparations, or scheduling response here."
                        />
                      </label>
                    </div>

                    <button
                      type="button"
                      disabled={updatingBookingId === booking.id}
                      onClick={() => void handleBookingUpdate(booking.id)}
                      className="inline-flex items-center gap-2 rounded-xl bg-yellow-500 px-5 py-3 font-semibold text-black disabled:opacity-60"
                    >
                      <Save size={16} />
                      {updatingBookingId === booking.id ? "Saving..." : "Save Booking Update"}
                    </button>
                  </div>
                </div>
              </div>
            );
          })}

          {!ritualBookings.length && !loading && (
            <p className="text-sm text-gray-500">No ritual bookings yet.</p>
          )}
        </div>
      </div>}
    </div>
  );
}
