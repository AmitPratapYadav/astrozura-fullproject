import { useEffect, useState } from "react";
import { Link, useLocation } from "react-router-dom";
import Navbar from "../../components/Navbar";
import Footer from "../../components/Footer";
import api from "../../api/axios";
import { searchLocation } from "../../api/prokeralaApi";
import { useAuth } from "../../context/AuthContext";

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

export default function UserProfile() {
  const { user, setUser } = useAuth();
  const location = useLocation();
  const [form, setForm] = useState(emptyForm);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState("");
  const [messageType, setMessageType] = useState("success");
  const [locationResults, setLocationResults] = useState([]);
  const [locationLoading, setLocationLoading] = useState(false);

  useEffect(() => {
    if (!user) {
      return;
    }

    setForm({
      name: user.name || "",
      email: user.email || "",
      phone: user.phone || "",
      gender: user.gender || "Male",
      date_of_birth: user.date_of_birth || "",
      time_of_birth: user.time_of_birth || "",
      place_of_birth: user.place_of_birth || "",
      latitude: user.latitude ?? "",
      longitude: user.longitude ?? "",
    });
  }, [user]);

  const setFeedback = (text, type = "success") => {
    setMessage(text);
    setMessageType(type);
    window.clearTimeout(window.__astrozuraProfileToast);
    window.__astrozuraProfileToast = window.setTimeout(() => {
      setMessage("");
    }, 3500);
  };

  const getTabClass = (path) => {
    return location.pathname === path
      ? "bg-gradient-to-r from-[#1E3557] to-[#2c4b7c] text-white shadow-md border-l-4 border-[#D4A73C]"
      : "bg-transparent text-gray-600 hover:bg-gray-50 hover:text-[#1E3557] border-l-4 border-transparent";
  };

  const updateField = (field, value) => {
    setForm((prev) => ({
      ...prev,
      [field]: value,
    }));
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
      const payload = {
        name: form.name.trim(),
        email: form.email.trim() || null,
        phone: form.phone.trim() || null,
        gender: form.gender || null,
        date_of_birth: form.date_of_birth || null,
        time_of_birth: form.time_of_birth || null,
        place_of_birth: form.place_of_birth.trim() || null,
        latitude: form.latitude === "" ? null : Number(form.latitude),
        longitude: form.longitude === "" ? null : Number(form.longitude),
      };

      const response = await api.post("/dashboard/profile/update", payload);
      const updatedUser = response?.data?.data;

      if (response?.data?.status === "success" && updatedUser) {
        setUser(updatedUser);
        localStorage.setItem("user", JSON.stringify(updatedUser));
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
        <aside className="w-full lg:w-[280px] flex-shrink-0">
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden sticky top-24">
            <div className="relative pt-8 pb-6 px-6 text-center">
              <div className="absolute top-0 left-0 w-full h-24 bg-gradient-to-br from-[#1E3557] to-[#0D1B3E] opacity-90 rounded-b-3xl"></div>

              <div className="relative w-20 h-20 mx-auto bg-gradient-to-br from-[#D4A73C] to-[#b88c29] text-white text-3xl font-bold rounded-2xl flex items-center justify-center shadow-lg border-4 border-white rotate-3 hover:rotate-0 transition-transform duration-300">
                <span className="-rotate-3">{user?.name ? user.name.charAt(0).toUpperCase() : "U"}</span>
              </div>

              <div className="mt-4">
                <h3 className="font-bold text-[#1E3557] text-lg">{user?.name || "Celestial User"}</h3>
                <p className="text-xs font-medium text-gray-500 mt-0.5">{user?.email || user?.phone || "Free Member"}</p>
              </div>
            </div>

            <nav className="flex flex-col p-3 space-y-1 bg-white">
              <Link to="/dashboard" className={`px-5 py-3.5 rounded-xl transition-all duration-200 font-medium text-sm ${getTabClass("/dashboard")}`}>
                Dashboard Overview
              </Link>
              <Link to="/user-profile" className={`px-5 py-3.5 rounded-xl transition-all duration-200 font-medium text-sm ${getTabClass("/user-profile")}`}>
                My Profile
              </Link>
              <Link to="/my-bookings" className={`px-5 py-3.5 rounded-xl transition-all duration-200 font-medium text-sm ${getTabClass("/my-bookings")}`}>
                My Bookings
              </Link>
            </nav>
          </div>
        </aside>

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
