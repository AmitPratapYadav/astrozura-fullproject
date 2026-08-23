import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { Download, Filter, Pencil, Search, Trash2 } from "lucide-react";
import { exportToExcel } from "../utils/exportExcel";
import { apiRequest, assetUrl } from "../lib/api";

const initialForm = {
  firstName: "",
  lastName: "",
  email: "",
  password: "",
  experience_years: "",
  languages: "",
  specialities: "",
  chat_price: "",
  call_price: "",
  about_bio: "",
  profile_image: null,
  is_featured: false,
  supports_chat: true,
  supports_call: true,
  is_online: true,
  supports_palm_reading: false,
  supports_ritual_booking: false,
  chat_commission_percentage: "20",
  call_commission_percentage: "20",
  chat_price_10: "", chat_price_15: "", chat_price_20: "", chat_price_30: "",
  call_price_10: "", call_price_15: "", call_price_20: "", call_price_30: "",
  languages_hi: "",
  specialities_hi: "",
  about_bio_hi: "",
};

function splitName(name = "") {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  return {
    firstName: parts[0] || "",
    lastName: parts.slice(1).join(" "),
  };
}

export default function Astrologers() {
  const [search, setSearch] = useState("");
  const [showFilter, setShowFilter] = useState(false);
  const [activeBtn, setActiveBtn] = useState("");
  const [astrologersData, setAstrologersData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editingAstrologer, setEditingAstrologer] = useState(null);
  const [form, setForm] = useState(initialForm);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState("");

  const loadAstrologers = async () => {
    try {
      setLoading(true);
      const response = await apiRequest("/admin/astrologers");
      if (response.success) {
        setAstrologersData(response.astrologers || []);
      }
    } catch (error) {
      console.error("Error fetching astrologers:", error);
      setMessage(error.message || "Unable to load astrologers.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadAstrologers();
  }, []);

  useEffect(() => {
    if (!message) return undefined;
    const timer = window.setTimeout(() => setMessage(""), 2500);
    return () => window.clearTimeout(timer);
  }, [message]);

  const filtered = useMemo(
    () =>
      astrologersData.filter((item) =>
        JSON.stringify(item).toLowerCase().includes(search.toLowerCase())
      ),
    [astrologersData, search]
  );

  const handleClick = (type) => {
    setActiveBtn(type);
    if (type === "filter") {
      setShowFilter((current) => !current);
    }
  };

  const openEditModal = async (astrologerId) => {
    try {
      const response = await apiRequest(`/admin/astrologers/${astrologerId}`);
      const astrologer = response.astrologer;
      const name = splitName(astrologer.name);

      setEditingAstrologer(astrologer);
      setForm({
        firstName: name.firstName,
        lastName: name.lastName,
        email: astrologer.email || "",
        password: "",
        experience_years: astrologer.astrologer_detail?.experience_years || "",
        languages: astrologer.astrologer_detail?.languages || "",
        specialities: astrologer.astrologer_detail?.specialities || "",
        chat_price: astrologer.astrologer_detail?.chat_price || "",
        call_price: astrologer.astrologer_detail?.call_price || "",
        about_bio: astrologer.astrologer_detail?.about_bio || "",
        profile_image: null,
        is_featured: Boolean(astrologer.astrologer_detail?.is_featured),
        supports_chat: Boolean(astrologer.astrologer_detail?.supports_chat),
        supports_call: Boolean(astrologer.astrologer_detail?.supports_call),
        is_online: Boolean(astrologer.astrologer_detail?.is_online),
        supports_palm_reading: Boolean(astrologer.astrologer_detail?.supports_palm_reading),
        supports_ritual_booking: Boolean(astrologer.astrologer_detail?.supports_ritual_booking),
        chat_commission_percentage: astrologer.astrologer_detail?.chat_commission_percentage ?? "20",
        call_commission_percentage: astrologer.astrologer_detail?.call_commission_percentage ?? "20",
        ...Object.fromEntries([10, 15, 20, 30].flatMap((duration) => [
          [`chat_price_${duration}`, astrologer.astrologer_detail?.chat_duration_prices?.[duration] ?? ""],
          [`call_price_${duration}`, astrologer.astrologer_detail?.call_duration_prices?.[duration] ?? ""],
        ])),
        languages_hi: astrologer.astrologer_detail?.translations?.hi?.languages || "",
        specialities_hi: astrologer.astrologer_detail?.translations?.hi?.specialities || "",
        about_bio_hi: astrologer.astrologer_detail?.translations?.hi?.about_bio || "",
      });
    } catch (error) {
      setMessage(error.message || "Unable to load astrologer details.");
    }
  };

  const closeEditModal = () => {
    setEditingAstrologer(null);
    setForm(initialForm);
  };

  const handleChange = (event) => {
    const { name, value, type, checked, files } = event.target;

    if (name === "profile_image") {
      setForm((current) => ({ ...current, profile_image: files?.[0] || null }));
      return;
    }

    setForm((current) => ({
      ...current,
      [name]: type === "checkbox" ? checked : value,
    }));
  };

  const handleUpdate = async (event) => {
    event.preventDefault();
    if (!editingAstrologer) return;

    try {
      setSaving(true);
      const payload = new FormData();

      Object.entries(form).forEach(([key, value]) => {
        if (["languages_hi", "specialities_hi", "about_bio_hi"].includes(key) || /^(chat|call)_price_(10|15|20|30)$/.test(key)) {
          return;
        }
        if (key === "profile_image") {
          if (value) payload.append(key, value);
          return;
        }

        if (key === "password" && !value) {
          return;
        }

        if (typeof value === "boolean") {
          payload.append(key, value ? "1" : "0");
          return;
        }

        payload.append(key, value ?? "");
      });
      payload.append("translations", JSON.stringify({
        hi: {
          languages: form.languages_hi,
          specialities: form.specialities_hi,
          about_bio: form.about_bio_hi,
        },
      }));
      payload.append("chat_duration_prices", JSON.stringify(Object.fromEntries([10, 15, 20, 30].map((duration) => [duration, form[`chat_price_${duration}`]]).filter(([, value]) => value !== ""))));
      payload.append("call_duration_prices", JSON.stringify(Object.fromEntries([10, 15, 20, 30].map((duration) => [duration, form[`call_price_${duration}`]]).filter(([, value]) => value !== ""))));

      const response = await apiRequest(`/admin/astrologers/${editingAstrologer.id}`, {
        method: "POST",
        body: payload,
      });

      if (response.success) {
        setMessage("Astrologer updated successfully.");
        closeEditModal();
        await loadAstrologers();
      }
    } catch (error) {
      setMessage(error.message || "Unable to update astrologer.");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (astrologerId) => {
    if (!window.confirm("Delete this astrologer?")) {
      return;
    }

    try {
      await apiRequest(`/admin/astrologers/${astrologerId}`, {
        method: "DELETE",
      });
      setMessage("Astrologer deleted successfully.");
      await loadAstrologers();
    } catch (error) {
      setMessage(error.message || "Unable to delete astrologer.");
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-2xl font-bold">Astrologers</h1>
          <p className="text-sm text-gray-500">Manage astrologer profiles, pricing, and visibility.</p>
        </div>

        <Link
          to="/add-astrologer"
          className="w-full rounded-lg bg-yellow-500 px-4 py-2 text-center text-black transition hover:bg-yellow-600 md:w-auto"
        >
          + Add Astrologer
        </Link>
      </div>

      {message && <div className="rounded-xl bg-white p-4 text-sm shadow">{message}</div>}

      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div className="flex w-full items-center rounded-lg bg-gray-100 px-3 py-2 md:w-80">
          <Search size={18} />
          <input
            type="text"
            placeholder="Search astrologer..."
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            className="ml-2 w-full bg-transparent outline-none"
          />
        </div>

        <div className="flex w-full gap-2 md:w-auto">
          <button
            type="button"
            onClick={() => handleClick("filter")}
            className={`flex w-full items-center justify-center gap-2 rounded-lg border px-4 py-2 transition md:w-auto ${
              activeBtn === "filter"
                ? "border-yellow-500 bg-yellow-500 text-black"
                : "bg-white hover:bg-yellow-500 hover:text-black"
            }`}
          >
            <Filter size={16} />
            Filter
          </button>

          <button
            type="button"
            onClick={() => {
              setActiveBtn("export");
              exportToExcel(filtered, "astrologers");
            }}
            className={`flex w-full items-center justify-center gap-2 rounded-lg border px-4 py-2 transition md:w-auto ${
              activeBtn === "export"
                ? "border-yellow-500 bg-yellow-500 text-black"
                : "bg-white hover:bg-yellow-500 hover:text-black"
            }`}
          >
            <Download size={16} />
            Export Excel
          </button>
        </div>
      </div>

      {showFilter && (
        <div className="rounded-xl bg-white p-4 shadow">
          <p className="text-sm text-gray-500">Search is active. Additional filters can be layered on top of this table later.</p>
        </div>
      )}

      <div className="overflow-x-auto rounded-xl bg-white shadow">
        <table className="min-w-[920px] w-full text-sm">
          <thead className="bg-gray-100">
            <tr>
              <th className="p-3 text-left">Profile</th>
              <th className="p-3 text-left">Contact</th>
              <th className="p-3 text-left">Experience</th>
              <th className="p-3 text-left">Specialities</th>
              <th className="p-3 text-left">Pricing</th>
              <th className="p-3 text-left">Status</th>
              <th className="p-3 text-left">Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan="7" className="p-6 text-center text-gray-500">Loading astrologers...</td>
              </tr>
            ) : filtered.length === 0 ? (
              <tr>
                <td colSpan="7" className="p-6 text-center text-gray-500">No astrologers found.</td>
              </tr>
            ) : (
              filtered.map((item) => (
                <tr key={item.id} className="border-b hover:bg-gray-50">
                  <td className="p-3">
                    <div className="flex items-center gap-3">
                      <img
                        src={assetUrl(item.profile_image || item.astrologer_detail?.profile_image)}
                        alt={item.name}
                        className="h-12 w-12 rounded-full bg-gray-100 object-cover"
                      />
                      <div>
                        <p className="font-semibold text-gray-900">{item.name}</p>
                        <p className="text-xs text-gray-500">{item.astrologer_detail?.languages || "-"}</p>
                      </div>
                    </div>
                  </td>
                  <td className="p-3">
                    <p>{item.email}</p>
                    <p className="text-xs text-gray-500">{item.phone || "-"}</p>
                  </td>
                  <td className="p-3">{item.astrologer_detail?.experience_years ? `${item.astrologer_detail.experience_years} Years` : "N/A"}</td>
                  <td className="p-3 max-w-[240px] text-gray-600">{item.astrologer_detail?.specialities || "-"}</td>
                  <td className="p-3">
                    <p>Chat: ₹{item.astrologer_detail?.chat_price || 0}/min ({item.astrologer_detail?.chat_commission_percentage || 0}%)</p>
                    <p className="text-xs text-gray-500">Call: ₹{item.astrologer_detail?.call_price || 0}/min ({item.astrologer_detail?.call_commission_percentage || 0}%)</p>
                  </td>
                  <td className="p-3">
                    <div className="flex flex-wrap gap-1">
                      <span className={`rounded-full px-2 py-1 text-xs font-semibold ${item.astrologer_detail?.is_online ? "bg-green-100 text-green-700" : "bg-red-100 text-red-700"}`}>
                        {item.astrologer_detail?.is_online ? "Online" : "Unavailable"}
                      </span>
                      {item.astrologer_detail?.supports_chat && <span className="rounded-full bg-blue-100 px-2 py-1 text-xs text-blue-700">Chat</span>}
                      {item.astrologer_detail?.supports_call && <span className="rounded-full bg-purple-100 px-2 py-1 text-xs text-purple-700">Call</span>}
                      {item.astrologer_detail?.supports_palm_reading && <span className="rounded-full bg-amber-100 px-2 py-1 text-xs text-amber-700">Palm Reading</span>}
                      {item.astrologer_detail?.supports_ritual_booking && <span className="rounded-full bg-yellow-100 px-2 py-1 text-xs text-yellow-700">Ritual Expert</span>}
                    </div>
                  </td>
                  <td className="p-3">
                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        onClick={() => void openEditModal(item.id)}
                        className="rounded-lg border border-blue-200 px-3 py-2 text-blue-600 transition hover:bg-blue-50"
                      >
                        <Pencil size={16} />
                      </button>
                      <button
                        type="button"
                        onClick={() => void handleDelete(item.id)}
                        className="rounded-lg border border-red-200 px-3 py-2 text-red-600 transition hover:bg-red-50"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {editingAstrologer && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="max-h-[90vh] w-full max-w-4xl overflow-y-auto rounded-2xl bg-white p-6 shadow-2xl">
            <div className="mb-6 flex items-center justify-between">
              <div>
                <h2 className="text-2xl font-bold">Edit Astrologer</h2>
                <p className="text-sm text-gray-500">Update profile, expertise, pricing, and visibility.</p>
              </div>
              <button type="button" onClick={closeEditModal} className="rounded-lg border px-4 py-2 text-sm">
                Close
              </button>
            </div>

            <form onSubmit={handleUpdate} className="space-y-6">
              <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
                <div className="space-y-4">
                  <h3 className="border-b pb-2 text-lg font-semibold">Account Details</h3>
                  <input name="firstName" value={form.firstName} onChange={handleChange} placeholder="First Name" required className="w-full rounded-lg border px-4 py-2 outline-none focus:border-yellow-500" />
                  <input name="lastName" value={form.lastName} onChange={handleChange} placeholder="Last Name" className="w-full rounded-lg border px-4 py-2 outline-none focus:border-yellow-500" />
                  <input type="email" name="email" value={form.email} onChange={handleChange} placeholder="Email Address" required className="w-full rounded-lg border px-4 py-2 outline-none focus:border-yellow-500" />
                  <input type="password" name="password" value={form.password} onChange={handleChange} placeholder="Leave blank to keep current password" className="w-full rounded-lg border px-4 py-2 outline-none focus:border-yellow-500" />
                </div>

                <div className="space-y-4">
                  <h3 className="border-b pb-2 text-lg font-semibold">Professional Profile</h3>
                  <input type="number" name="experience_years" value={form.experience_years} onChange={handleChange} placeholder="Experience" required className="w-full rounded-lg border px-4 py-2 outline-none focus:border-yellow-500" />
                  <input name="languages" value={form.languages} onChange={handleChange} placeholder="Languages" className="w-full rounded-lg border px-4 py-2 outline-none focus:border-yellow-500" />
                  <input name="specialities" value={form.specialities} onChange={handleChange} placeholder="Specialities" className="w-full rounded-lg border px-4 py-2 outline-none focus:border-yellow-500" />
                  <div className="grid grid-cols-2 gap-4">
                    <input type="number" name="chat_price" value={form.chat_price} onChange={handleChange} placeholder="Chat price" required className="w-full rounded-lg border px-4 py-2 outline-none focus:border-yellow-500" />
                    <input type="number" name="call_price" value={form.call_price} onChange={handleChange} placeholder="Call price" required className="w-full rounded-lg border px-4 py-2 outline-none focus:border-yellow-500" />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <input type="number" min="0" max="100" step="0.01" name="chat_commission_percentage" value={form.chat_commission_percentage} onChange={handleChange} placeholder="Chat commission %" className="w-full rounded-lg border px-4 py-2 outline-none focus:border-yellow-500" />
                    <input type="number" min="0" max="100" step="0.01" name="call_commission_percentage" value={form.call_commission_percentage} onChange={handleChange} placeholder="Call commission %" className="w-full rounded-lg border px-4 py-2 outline-none focus:border-yellow-500" />
                  </div>
                  <div className="grid grid-cols-2 gap-3 text-sm md:grid-cols-4">
                    <label className="flex items-center gap-2"><input type="checkbox" name="supports_chat" checked={form.supports_chat} onChange={handleChange} /> Chat</label>
                    <label className="flex items-center gap-2"><input type="checkbox" name="supports_call" checked={form.supports_call} onChange={handleChange} /> Call</label>
                    <label className="flex items-center gap-2"><input type="checkbox" name="supports_palm_reading" checked={form.supports_palm_reading} onChange={handleChange} /> Palm Reading</label>
                    <label className="flex items-center gap-2"><input type="checkbox" name="supports_ritual_booking" checked={form.supports_ritual_booking} onChange={handleChange} /> Ritual Expert</label>
                    <label className="flex items-center gap-2"><input type="checkbox" name="is_online" checked={form.is_online} onChange={handleChange} /> Online</label>
                  </div>
                  <div className="rounded-xl border bg-gray-50 p-3">
                    <p className="mb-1 text-sm font-semibold">Duration Pricing</p>
                    <p className="mb-3 text-xs text-gray-500">Optional total session prices; blank values use per-minute pricing.</p>
                    <div className="grid gap-4 md:grid-cols-2">
                      {["chat", "call"].map((mode) => <div key={mode}><p className="mb-2 text-xs font-bold uppercase text-gray-500">{mode}</p><div className="grid grid-cols-2 gap-2">{[10, 15, 20, 30].map((duration) => <label key={duration} className="text-xs text-gray-500">{duration} min<input type="number" min="0" step="0.01" name={`${mode}_price_${duration}`} value={form[`${mode}_price_${duration}`]} onChange={handleChange} className="mt-1 w-full rounded-lg border bg-white px-3 py-2" /></label>)}</div></div>)}
                    </div>
                  </div>
                </div>
              </div>

              <div className="space-y-4 border-t pt-4">
                <input type="file" name="profile_image" accept="image/*" onChange={handleChange} className="w-full rounded-lg border px-4 py-2 outline-none focus:border-yellow-500" />
                <textarea name="about_bio" value={form.about_bio} onChange={handleChange} rows="4" placeholder="About / Bio" className="w-full rounded-lg border px-4 py-2 outline-none focus:border-yellow-500" />
                <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
                  <input name="languages_hi" value={form.languages_hi} onChange={handleChange} placeholder="Languages in Hindi" className="w-full rounded-lg border px-4 py-2" />
                  <input name="specialities_hi" value={form.specialities_hi} onChange={handleChange} placeholder="Specialities in Hindi" className="w-full rounded-lg border px-4 py-2" />
                </div>
                <textarea name="about_bio_hi" value={form.about_bio_hi} onChange={handleChange} rows="3" placeholder="Bio in Hindi" className="w-full rounded-lg border px-4 py-2" />
                <label className="flex items-center gap-2 text-sm font-medium text-gray-700">
                  <input type="checkbox" name="is_featured" checked={form.is_featured} onChange={handleChange} />
                  Mark as featured astrologer
                </label>
              </div>

              <div className="flex justify-end gap-3">
                <button type="button" onClick={closeEditModal} className="rounded-lg border px-5 py-2.5 text-sm font-semibold">
                  Cancel
                </button>
                <button type="submit" disabled={saving} className="rounded-lg bg-yellow-500 px-5 py-2.5 text-sm font-semibold text-black disabled:opacity-50">
                  {saving ? "Saving..." : "Save Changes"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
