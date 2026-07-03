import { useEffect, useState } from "react";
import Navbar from "../../components/Navbar";
import Footer from "../../components/Footer";
import api from "../../api/axios";
import { searchLocation } from "../../api/prokeralaApi";
import { useAuth } from "../../context/AuthContext";
import { assetUrl } from "../../utils/assetUrl";
import UserDashboardSidebar from "../../components/UserDashboardSidebar";

const emptyForm = {
  name: "",
  email: "",
  phone: "",
  gender: "Male",
  date_of_birth: "",
  time_of_birth: "",
  place_of_birth: "",
  latitude: "",
  longitude: "",
};

const normalizeProfileDate = (value = "") => {
  if (!value) return "";
  return String(value).slice(0, 10);
};

const normalizeProfileTime = (value = "") => {
  if (!value) return "";
  return String(value).slice(0, 5);
};

const appendIfPresent = (payload, key, value) => {
  const normalized = typeof value === "string" ? value.trim() : value;
  if (normalized !== "" && normalized !== null && normalized !== undefined) {
    payload.append(key, normalized);
  }
};

export default function UserProfile() {
  const { user, setUser } = useAuth();
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState("");
  const [messageType, setMessageType] = useState("success");
  const [locationResults, setLocationResults] = useState([]);
  const [locationLoading, setLocationLoading] = useState(false);
  const [profileFile, setProfileFile] = useState(null);
  const [profilePreview, setProfilePreview] = useState("");
  const today = new Date().toISOString().slice(0, 10);

  useEffect(() => {
    if (!user) {
      return;
    }

    setForm({
      name: user.name || "",
      email: user.email || "",
      phone: user.phone || "",
      gender: user.gender || "Male",
      date_of_birth: normalizeProfileDate(user.date_of_birth),
      time_of_birth: normalizeProfileTime(user.time_of_birth),
      place_of_birth: user.place_of_birth || "",
      latitude: user.latitude ?? "",
      longitude: user.longitude ?? "",
    });
    setProfilePreview(assetUrl(user.profile_image));
  }, [user]);

  const setFeedback = (text, type = "success") => {
    setMessage(text);
    setMessageType(type);
    window.clearTimeout(window.__astrozuraProfileToast);
    window.__astrozuraProfileToast = window.setTimeout(() => {
      setMessage("");
    }, 3500);
  };

  const updateField = (field, value) => {
    setForm((prev) => ({
      ...prev,
      [field]: value,
    }));
  };

  const handleProfileImageChange = (event) => {
    const file = event.target.files?.[0];
    if (!file) return;
    setProfileFile(file);
    setProfilePreview((current) => {
      if (current?.startsWith("blob:")) URL.revokeObjectURL(current);
      return URL.createObjectURL(file);
    });
  };

  const handleLocationChange = async (event) => {
    const query = event.target.value;

    setForm((prev) => ({
      ...prev,
      place_of_birth: query,
      latitude: "",
      longitude: "",
    }));

    if (query.trim().length < 3) {
      setLocationResults([]);
      return;
    }

    try {
      setLocationLoading(true);
      const response = await searchLocation(query.trim());
      setLocationResults(response?.data || []);
    } catch (error) {
      console.error("Birthplace search failed:", error);
      setLocationResults([]);
    } finally {
      setLocationLoading(false);
    }
  };

  const selectLocation = (place) => {
    setForm((prev) => ({
      ...prev,
      place_of_birth: place.name,
      latitude: place.coordinates?.latitude ?? "",
      longitude: place.coordinates?.longitude ?? "",
    }));
    setLocationResults([]);
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (form.place_of_birth && (form.latitude === "" || form.longitude === "")) {
      setFeedback("Select the birthplace from the dropdown so latitude and longitude are saved correctly.", "error");
      return;
    }

    try {
      setSaving(true);
      const payload = new FormData();
      payload.append("name", form.name.trim());
      appendIfPresent(payload, "email", form.email);
      appendIfPresent(payload, "phone", form.phone);
      appendIfPresent(payload, "gender", form.gender);
      appendIfPresent(payload, "date_of_birth", normalizeProfileDate(form.date_of_birth));
      appendIfPresent(payload, "time_of_birth", normalizeProfileTime(form.time_of_birth));
      appendIfPresent(payload, "place_of_birth", form.place_of_birth);
      appendIfPresent(payload, "latitude", form.latitude === "" ? "" : String(form.latitude));
      appendIfPresent(payload, "longitude", form.longitude === "" ? "" : String(form.longitude));
      if (profileFile) {
        payload.append("profile_image", profileFile);
      }

      const response = await api.post("/dashboard/profile/update", payload);
      const updatedUser = response?.data?.data;

      if (response?.data?.status === "success" && updatedUser) {
        setUser(updatedUser);
        localStorage.setItem("user", JSON.stringify(updatedUser));
        setProfileFile(null);
        setProfilePreview(assetUrl(updatedUser.profile_image));
        setFeedback("Profile updated successfully.");
        return;
      }

      setFeedback("Profile could not be updated.", "error");
    } catch (error) {
      console.error("Profile update failed:", error);
      setFeedback(error?.response?.data?.message || "Profile update failed.", "error");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="bg-[#f8f9fa] min-h-screen flex flex-col font-sans">
      {message && (
        <div
                  className={`fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-xl px-6 py-3 text-sm font-medium text-white shadow-lg ${
            messageType === "error" ? "bg-red-600" : "bg-[#1E3557]"
          }`}
        >
          {message}
        </div>
      )}

      <Navbar />

      <div className="flex-1 max-w-7xl w-full mx-auto p-4 lg:p-8 flex flex-col lg:flex-row gap-8">
        <UserDashboardSidebar />

        <main className="flex-1 flex flex-col gap-6">
          <div className="flex justify-between items-end mb-2">
            <div>
              <p className="text-[#D4A73C] font-medium text-sm tracking-wider uppercase mb-1">Account & Settings</p>
              <h1 className="text-3xl font-bold text-[#1E3557]">My Profile</h1>
            </div>
          </div>

          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 md:p-8">
            <div className="mb-8">
              <h2 className="text-xl font-bold text-[#1E3557]">Profile & Astrology Details</h2>
              <p className="text-sm text-gray-500 mt-1">
                Keep your account and birth details accurate so horoscope, kundli, and compatibility calculations use the correct data.
              </p>
            </div>

            <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-6">
              <div className="md:col-span-2 rounded-2xl border border-dashed border-[#D4A73C]/40 bg-[#FFF9EA] p-5">
                <div className="flex flex-col gap-5 sm:flex-row sm:items-center">
                  <div className="flex h-24 w-24 items-center justify-center overflow-hidden rounded-2xl bg-white text-3xl font-black text-[#1E3557] shadow-sm ring-1 ring-[#F0E1C4]">
                    {profilePreview ? (
                      <img src={profilePreview} alt={form.name || "User"} className="h-full w-full object-cover" />
                    ) : (
                      form.name?.charAt(0)?.toUpperCase() || "U"
                    )}
                  </div>
                  <div className="flex-1">
                    <label className="block text-xs font-bold uppercase tracking-wide text-gray-600">Profile Picture</label>
                    <p className="mt-1 text-sm text-gray-500">Upload a clear JPG, PNG, GIF, or WebP image up to 4 MB.</p>
                    <input
                      type="file"
                      accept="image/jpeg,image/png,image/jpg,image/gif,image/webp"
                      onChange={handleProfileImageChange}
                      className="mt-4 block w-full text-sm text-[#1E3557] file:mr-4 file:rounded-xl file:border-0 file:bg-[#1E3557] file:px-5 file:py-2.5 file:text-sm file:font-bold file:text-white hover:file:bg-[#162744]"
                    />
                  </div>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold tracking-wide text-gray-600 uppercase mb-2">Full Name</label>
                <input
                  type="text"
                  value={form.name}
                  onChange={(event) => updateField("name", event.target.value)}
                  placeholder="Enter your full name"
                  className="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3.5 text-sm text-[#1E3557] focus:bg-white focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 outline-none transition-all"
                />
              </div>

              <div>
                <label className="block text-xs font-bold tracking-wide text-gray-600 uppercase mb-2">Gender</label>
                <select
                  value={form.gender}
                  onChange={(event) => updateField("gender", event.target.value)}
                  className="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3.5 text-sm text-[#1E3557] focus:bg-white focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 outline-none transition-all"
                >
                  <option value="Male">Male</option>
                  <option value="Female">Female</option>
                  <option value="Other">Other</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold tracking-wide text-gray-600 uppercase mb-2">Email</label>
                <input
                  type="email"
                  value={form.email}
                  onChange={(event) => updateField("email", event.target.value)}
                  placeholder="Enter your email"
                  className="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3.5 text-sm text-[#1E3557] focus:bg-white focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 outline-none transition-all"
                />
              </div>

              <div>
                <label className="block text-xs font-bold tracking-wide text-gray-600 uppercase mb-2">Phone</label>
                <input
                  type="text"
                  value={form.phone}
                  onChange={(event) => updateField("phone", event.target.value)}
                  placeholder="Enter your phone number"
                  className="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3.5 text-sm text-[#1E3557] focus:bg-white focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 outline-none transition-all"
                />
              </div>

              <div>
                <label className="block text-xs font-bold tracking-wide text-gray-600 uppercase mb-2">Date of Birth</label>
                <input
                  type="date"
                  value={form.date_of_birth}
                  max={today}
                  onChange={(event) => updateField("date_of_birth", event.target.value)}
                  className="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3.5 text-sm text-[#1E3557] focus:bg-white focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 outline-none transition-all"
                />
              </div>

              <div>
                <label className="block text-xs font-bold tracking-wide text-gray-600 uppercase mb-2">Time of Birth</label>
                <input
                  type="time"
                  value={form.time_of_birth}
                  onChange={(event) => updateField("time_of_birth", event.target.value)}
                  className="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3.5 text-sm text-[#1E3557] focus:bg-white focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 outline-none transition-all"
                />
              </div>

              <div className="md:col-span-2 relative">
                <label className="block text-xs font-bold tracking-wide text-gray-600 uppercase mb-2">Place of Birth</label>
                <div className="relative">
                  <input
                    type="text"
                    value={form.place_of_birth}
                    onChange={handleLocationChange}
                    placeholder="Search city and select from the dropdown"
                    className="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3.5 pr-10 text-sm text-[#1E3557] focus:bg-white focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 outline-none transition-all"
                  />
                  {locationLoading && (
                    <div className="absolute right-3 top-3.5">
                      <div className="h-4 w-4 animate-spin rounded-full border-b-2 border-[#D4A73C]"></div>
                    </div>
                  )}
                </div>

                {locationResults.length > 0 && (
                  <div className="absolute z-20 mt-1 max-h-60 w-full overflow-y-auto rounded-xl border border-gray-200 bg-white shadow-xl">
                    {locationResults.map((place, index) => (
                      <button
                        key={`${place.name}-${index}`}
                        type="button"
                        onClick={() => selectLocation(place)}
                        className="block w-full border-b border-gray-50 px-4 py-3 text-left text-sm text-gray-700 hover:bg-gray-50 last:border-0"
                      >
                        {place.name}
                      </button>
                    ))}
                  </div>
                )}

                {form.latitude !== "" && form.longitude !== "" && (
                  <p className="mt-2 text-xs text-gray-500">
                    Coordinates saved: {form.latitude}, {form.longitude}
                  </p>
                )}
              </div>

              <div className="md:col-span-2 mt-4 pt-6 border-t border-gray-100 flex justify-end">
                <button
                  type="submit"
                  disabled={saving}
                  className="bg-[#D4A73C] text-[#1E3557] font-bold px-8 py-3.5 rounded-xl hover:bg-[#c49530] transition shadow-md hover:shadow-lg w-full md:w-auto disabled:opacity-60"
                >
                  {saving ? "Saving..." : "Save Profile Changes"}
                </button>
              </div>
            </form>
          </div>
        </main>
      </div>

      <Footer />
    </div>
  );
}
