import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import { getAstrologerBookings, markBookingCompleted } from "../../api/bookingApi";

const formatSchedule = (value) =>
  value
    ? new Date(value).toLocaleString("en-IN", {
        dateStyle: "medium",
        timeStyle: "short",
        timeZone: "Asia/Kolkata",
      })
    : "-";

const bookingStatusClass = {
  confirmed: "bg-blue-50 text-blue-700 border-blue-200",
  in_progress: "bg-amber-50 text-amber-700 border-amber-200",
  completed: "bg-emerald-50 text-emerald-700 border-emerald-200",
  cancelled: "bg-rose-50 text-rose-700 border-rose-200",
  declined: "bg-rose-50 text-rose-700 border-rose-200",
};

const formatBirthDetails = (birthDetails) => {
  if (!birthDetails) return [];

  return [
    birthDetails.date_of_birth ? `DOB: ${birthDetails.date_of_birth}` : null,
    birthDetails.time_of_birth ? `Time: ${birthDetails.time_of_birth}` : null,
    birthDetails.place_of_birth ? `Place: ${birthDetails.place_of_birth}` : null,
    birthDetails.gender ? `Gender: ${birthDetails.gender}` : null,
  ].filter(Boolean);
};

function getNameParts(fullName = "") {
  const parts = fullName.trim().split(/\s+/).filter(Boolean);
  return {
    firstName: parts[0] || "",
    lastName: parts.slice(1).join(" "),
  };
}

function resolveImageUrl(baseUrl, path) {
  if (!path) return "";
  if (path.startsWith("http")) return path;
  return `${baseUrl}${path.startsWith("/") ? path : `/${path}`}`;
}

function ProfileManagementForm({ user }) {
  const { setUser } = useAuth();
  const nameParts = getNameParts(user?.name);
  const backendBaseUrl = (import.meta.env.VITE_API_BASE_URL || "http://localhost:8000/api").replace(/\/index\.php\/api$|\/api$/, "");

  const [formData, setFormData] = useState({
    firstName: nameParts.firstName,
    lastName: nameParts.lastName,
    email: user?.email || "",
    password: "",
    experience_years: user?.astrologer_detail?.experience_years || "",
    languages: user?.astrologer_detail?.languages || "",
    specialities: user?.astrologer_detail?.specialities || "",
    chat_price: user?.astrologer_detail?.chat_price || "",
    call_price: user?.astrologer_detail?.call_price || "",
    about_bio: user?.astrologer_detail?.about_bio || "",
    profile_image: null,
    is_featured: Boolean(user?.astrologer_detail?.is_featured),
  });
  const [profilePreview, setProfilePreview] = useState(
    user?.astrologer_detail?.profile_image
      ? resolveImageUrl(backendBaseUrl, user.astrologer_detail.profile_image)
      : ""
  );
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState(null);

  const handleChange = (e) => {
    const { name, type, value, checked, files } = e.target;

    if (name === "profile_image") {
      const file = files?.[0] || null;
      setFormData((prev) => ({ ...prev, profile_image: file }));
      if (file) {
        setProfilePreview(URL.createObjectURL(file));
      }
      return;
    }

    setFormData((prev) => ({
      ...prev,
      [name]: type === "checkbox" ? checked : value,
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage(null);

    try {
      const payload = new FormData();

      Object.entries(formData).forEach(([key, value]) => {
        if (key === "profile_image") {
          if (value) payload.append(key, value);
          return;
        }

        if (key === "password" && !value) {
          return;
        }

        if (key === "is_featured") {
          payload.append(key, value ? "1" : "0");
          return;
        }

        payload.append(key, value ?? "");
      });

      const response = await fetch(`${import.meta.env.VITE_API_BASE_URL || "http://localhost:8000/api"}/astrologer/profile/update`, {
        method: "POST",
        headers: {
          Accept: "application/json",
          Authorization: `Bearer ${localStorage.getItem("auth_token")}`,
        },
        body: payload,
      });

      const data = await response.json();

      if (data.success) {
        localStorage.setItem("user", JSON.stringify(data.user));
        setUser(data.user);
        setFormData((prev) => ({
          ...prev,
          password: "",
          profile_image: null,
        }));

        if (data.user?.astrologer_detail?.profile_image) {
          setProfilePreview(resolveImageUrl(backendBaseUrl, data.user.astrologer_detail.profile_image));
        }

        setMessage({ type: "success", text: "Profile updated successfully." });
      } else {
        setMessage({ type: "error", text: data.message || "Failed to update profile." });
      }
    } catch (error) {
      console.error(error);
      setMessage({ type: "error", text: "Something went wrong. Check console." });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="animate-fade-in flex flex-col gap-6">
      <div className="flex justify-between items-end mb-2">
        <div>
          <p className="text-[#D4A73C] font-medium text-sm tracking-wider uppercase mb-1">Account & Settings</p>
          <h1 className="text-3xl font-bold text-[#1E3557]">Manage Profile</h1>
        </div>
      </div>

      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 md:p-8">
        <div className="mb-8">
          <h2 className="text-xl font-bold text-[#1E3557]">Astrologer Information</h2>
          <p className="text-sm text-gray-500 mt-1">Update your account and professional details from one place.</p>
        </div>

        {message && (
          <div className={`p-4 mb-6 rounded-lg text-sm font-semibold ${message.type === "success" ? "bg-green-100 text-green-800" : "bg-red-100 text-red-800"}`}>
            {message.text}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4">
              <h3 className="text-lg font-semibold border-b pb-2">Account Details</h3>

              <div>
                <label className="block text-sm text-gray-600 mb-1">First Name *</label>
                <input type="text" name="firstName" value={formData.firstName} onChange={handleChange} required className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
              </div>

              <div>
                <label className="block text-sm text-gray-600 mb-1">Last Name</label>
                <input type="text" name="lastName" value={formData.lastName} onChange={handleChange} className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
              </div>

              <div>
                <label className="block text-sm text-gray-600 mb-1">Email Address *</label>
                <input type="email" name="email" value={formData.email} onChange={handleChange} required className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
              </div>

              <div>
                <label className="block text-sm text-gray-600 mb-1">New Password</label>
                <input type="password" name="password" value={formData.password} onChange={handleChange} minLength={6} placeholder="Leave blank to keep current password" className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
              </div>
            </div>

            <div className="space-y-4">
              <h3 className="text-lg font-semibold border-b pb-2">Professional Profile</h3>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm text-gray-600 mb-1">Experience (Years) *</label>
                  <input type="number" name="experience_years" value={formData.experience_years} onChange={handleChange} required className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
                </div>

                <div>
                  <label className="block text-sm text-gray-600 mb-1">Languages (comma separated)</label>
                  <input type="text" name="languages" value={formData.languages} onChange={handleChange} placeholder="English, Hindi" className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
                </div>
              </div>

              <div>
                <label className="block text-sm text-gray-600 mb-1">Specialities (comma separated)</label>
                <input type="text" name="specialities" value={formData.specialities} onChange={handleChange} placeholder="Vedic Astrology, Tarot" className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm text-gray-600 mb-1">Chat Price per min *</label>
                  <input type="number" name="chat_price" value={formData.chat_price} onChange={handleChange} required className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
                </div>

                <div>
                  <label className="block text-sm text-gray-600 mb-1">Call Price per min *</label>
                  <input type="number" name="call_price" value={formData.call_price} onChange={handleChange} required className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
                </div>
              </div>
            </div>
          </div>

          <div className="space-y-4 pt-4 border-t">
            <div>
              <label className="block text-sm text-gray-600 mb-1">Profile Image</label>
              <input type="file" name="profile_image" accept="image/*" onChange={handleChange} className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500 bg-white" />
              {profilePreview && (
                <img src={profilePreview} alt="Astrologer profile preview" className="mt-3 h-24 w-24 rounded-xl object-cover border border-gray-200" />
              )}
            </div>

            <div>
              <label className="block text-sm text-gray-600 mb-1">About / Bio</label>
              <textarea name="about_bio" value={formData.about_bio} onChange={handleChange} rows="4" className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" placeholder="Write a detailed description about your experience and guidance style..." />
            </div>

            <div className="flex items-center gap-2 mt-2">
              <input type="checkbox" id="is_featured" name="is_featured" checked={formData.is_featured} onChange={handleChange} className="w-4 h-4 text-yellow-500 rounded border-gray-300 focus:ring-yellow-500" />
              <label htmlFor="is_featured" className="text-sm font-medium text-gray-700">Display as Featured Expert on Homepage and Main Profiles</label>
            </div>
          </div>

          <div className="flex justify-end pt-4">
            <button disabled={loading} type="submit" className="bg-[#D4A73C] text-[#1E3557] font-bold px-8 py-3.5 rounded-xl hover:bg-[#c49530] transition shadow-md hover:shadow-lg w-full md:w-auto disabled:opacity-50">
              {loading ? "Saving..." : "Save Profile Changes"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default function AstrologerDashboard() {
  const { user, logout } = useAuth();
  const [activeTab, setActiveTab] = useState("dashboard");
  const [bookingData, setBookingData] = useState({
    upcoming: [],
    history: [],
    stats: {
      today_bookings: 0,
      active_sessions: 0,
      completed_sessions: 0,
      monthly_revenue: 0,
    },
  });
  const [loadingBookings, setLoadingBookings] = useState(true);
  const [actionBookingId, setActionBookingId] = useState(null);
  const [banner, setBanner] = useState("");

  if (!user || user.role !== "astrologer") {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#f8f9fa] flex-col gap-4 font-sans">
        <div className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100 text-center max-w-sm">
          <p className="text-xl text-red-600 font-bold mb-4">Unauthorized Access</p>
          <p className="text-gray-500 mb-6 text-sm">You must be logged in as an Astrologer to view this page.</p>
          <Link to="/astrologer/login" className="bg-[#1E3557] text-white px-6 py-3 rounded-xl hover:bg-[#162744] transition shadow block font-medium">
            Head to Astrologer Portal
          </Link>
        </div>
      </div>
    );
  }

  useEffect(() => {
    let intervalId;

    const loadBookings = async () => {
      try {
        setLoadingBookings(true);
        const response = await getAstrologerBookings();
        setBookingData({
          upcoming: response?.upcoming || [],
          history: response?.history || [],
          stats: response?.stats || {
            today_bookings: 0,
            active_sessions: 0,
            completed_sessions: 0,
            monthly_revenue: 0,
          },
        });
      } catch (error) {
        console.error("Failed to load astrologer bookings", error);
      } finally {
        setLoadingBookings(false);
      }
    };

    void loadBookings();
    intervalId = window.setInterval(() => void loadBookings(), 30000);
    return () => window.clearInterval(intervalId);
  }, []);

  useEffect(() => {
    if (!banner) return undefined;
    const timeoutId = window.setTimeout(() => setBanner(""), 2800);
    return () => window.clearTimeout(timeoutId);
  }, [banner]);

  const getTabClass = (tabName) => {
    return activeTab === tabName
      ? "block px-5 py-3.5 bg-gradient-to-r from-[#1E3557] to-[#2c4b7c] text-white shadow-md border-l-4 border-[#D4A73C] rounded-xl font-medium text-[13px] text-left transition-all duration-200"
      : "block px-5 py-3.5 hover:bg-gray-50 text-gray-700 hover:text-[#184070] border-l-4 border-transparent rounded-xl font-medium text-[13px] text-left transition-all duration-200";
  };

  const refreshBookings = async () => {
    const response = await getAstrologerBookings();
    setBookingData({
      upcoming: response?.upcoming || [],
      history: response?.history || [],
      stats: response?.stats || bookingData.stats,
    });
  };

  const handleCompleteBooking = async (bookingId) => {
    try {
      setActionBookingId(bookingId);
      const response = await markBookingCompleted(bookingId);
      if (response?.success) {
        setBanner("Booking marked as completed.");
        await refreshBookings();
      }
    } catch (error) {
      console.error("Failed to complete booking", error);
      setBanner(error?.response?.data?.message || "Unable to update booking.");
    } finally {
      setActionBookingId(null);
    }
  };

  const renderBookingCard = (booking, allowComplete = false) => (
    <div key={booking.id} className="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wide text-[#D4A73C]">
            {booking.booking_reference}
          </p>
          <h3 className="mt-2 text-lg font-bold text-[#1E3557]">{booking.user_name}</h3>
          <p className="mt-1 text-sm text-gray-500">
            {booking.consultation_type === "chat" ? "Chat Consultation" : "Audio Call"} for{" "}
            {booking.duration} minutes
          </p>
        </div>
        <span className={`rounded-full border px-3 py-1 text-xs font-semibold uppercase ${bookingStatusClass[booking.status] || "bg-slate-100 text-slate-600 border-slate-200"}`}>
          {booking.status}
        </span>
      </div>

      <div className="mt-5 grid gap-3 md:grid-cols-3 text-sm">
        <div>
          <p className="text-xs uppercase text-gray-400">Scheduled For</p>
          <p className="mt-1 font-semibold text-[#1E3557]">{formatSchedule(booking.scheduled_at)}</p>
        </div>
        <div>
          <p className="text-xs uppercase text-gray-400">Amount</p>
          <p className="mt-1 font-semibold text-[#1E3557]">Rs {booking.amount}</p>
        </div>
        <div>
          <p className="text-xs uppercase text-gray-400">Client Email</p>
          <p className="mt-1 font-semibold text-[#1E3557] break-all">{booking.user_email || "-"}</p>
        </div>
      </div>

      {!!formatBirthDetails(booking.birth_details).length && (
        <div className="mt-4 rounded-xl border border-[#F1E1B8] bg-[#FFF9EC] px-4 py-3">
          <p className="text-xs font-semibold uppercase tracking-wide text-[#D4A73C]">
            Client Birth Details
          </p>
          <div className="mt-2 grid gap-2 text-sm text-[#1E3557]">
            {formatBirthDetails(booking.birth_details).map((item) => (
              <p key={item}>{item}</p>
            ))}
          </div>
        </div>
      )}

      {booking.notes && <p className="mt-4 rounded-xl bg-[#F8F9FC] px-4 py-3 text-sm text-gray-600">{booking.notes}</p>}

      {(allowComplete || !["completed", "cancelled", "declined"].includes(booking.status)) && (
        <div className="mt-5 flex flex-wrap justify-end gap-3">
          <a
            href="/kundli"
            target="_blank"
            rel="noreferrer"
            className="rounded-xl border border-gray-200 px-5 py-2.5 text-sm font-semibold text-[#1E3557] transition hover:border-[#D4A73C] hover:text-[#D4A73C]"
          >
            Kundli Tool
          </a>
          <a
            href="/birth-chart"
            target="_blank"
            rel="noreferrer"
            className="rounded-xl border border-gray-200 px-5 py-2.5 text-sm font-semibold text-[#1E3557] transition hover:border-[#D4A73C] hover:text-[#D4A73C]"
          >
            Birth Chart
          </a>
          <a
            href="/matching"
            target="_blank"
            rel="noreferrer"
            className="rounded-xl border border-gray-200 px-5 py-2.5 text-sm font-semibold text-[#1E3557] transition hover:border-[#D4A73C] hover:text-[#D4A73C]"
          >
            Matchmaking
          </a>
          {!["completed", "cancelled", "declined"].includes(booking.status) && (
            <Link
              to={`/session/${booking.id}`}
              className="rounded-xl border border-[#1E3557] px-5 py-2.5 text-sm font-semibold text-[#1E3557] transition hover:bg-[#1E3557] hover:text-white"
            >
              {booking.consultation_type === "call" ? "Open Consultation Room" : "Open Chat Session"}
            </Link>
          )}
          <button
            type="button"
            disabled={actionBookingId === booking.id}
            onClick={() => void handleCompleteBooking(booking.id)}
            className="rounded-xl bg-[#D4A73C] px-5 py-2.5 text-sm font-bold text-[#1E3557] disabled:opacity-60"
          >
            {actionBookingId === booking.id ? "Updating..." : "Mark Service Completed"}
          </button>
        </div>
      )}
    </div>
  );

  return (
    <div className="bg-[#f8f9fa] min-h-screen flex flex-col font-sans">
      {banner && <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-full bg-[#1E3557] px-6 py-3 text-sm font-semibold text-white shadow-lg">{banner}</div>}
      <div className="flex-1 max-w-7xl w-full mx-auto p-4 lg:p-8 flex flex-col lg:flex-row gap-8">
        <aside className="w-full lg:w-[280px] flex-shrink-0">
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden sticky top-24">
            <div className="relative pt-8 pb-6 px-6 text-center border-b border-gray-100">
              <div className="absolute top-0 left-0 w-full h-24 bg-gradient-to-br from-[#1E3557] to-[#0D1B3E] opacity-90 rounded-b-3xl"></div>

              <div className="relative w-20 h-20 mx-auto bg-gradient-to-br from-[#D4A73C] to-[#b88c29] text-white text-3xl font-bold rounded-2xl flex items-center justify-center shadow-lg border-4 border-white rotate-3 hover:rotate-0 transition-transform duration-300">
                <span className="-rotate-3">{user.name.charAt(0).toUpperCase()}</span>
              </div>

              <div className="mt-4">
                <h3 className="font-bold text-[#1E3557] text-lg">{user.name}</h3>
                <p className="text-[11px] font-bold tracking-wider uppercase text-[#D4A73C] mt-1">Certified Astrologer</p>
              </div>
            </div>

            <nav className="flex flex-col p-3 space-y-1 bg-white">
              <button onClick={() => setActiveTab("dashboard")} className={getTabClass("dashboard")}>
                Dashboard Overview
              </button>
              <button onClick={() => setActiveTab("incoming")} className={getTabClass("incoming")}>
                Incoming Bookings
              </button>
              <button onClick={() => setActiveTab("past")} className={getTabClass("past")}>
                Past Bookings
              </button>
              <button onClick={() => setActiveTab("profile")} className={getTabClass("profile")}>
                Manage Profile
              </button>
            </nav>

            <div className="p-4 border-t border-gray-100 bg-gray-50/50">
              <Link to="/" className="block text-center text-sm font-semibold text-[#D4A73C] hover:text-[#b88c29] mb-4 transition">
                Return to Main Website
              </Link>
              <button onClick={logout} className="w-full text-center px-4 py-2.5 bg-red-50 text-red-500 hover:bg-red-100 rounded-xl transition font-semibold text-sm">
                Logout
              </button>
            </div>
          </div>
        </aside>

        <main className="flex-1 flex flex-col gap-6">
          {activeTab === "dashboard" && (
            <div className="animate-fade-in flex flex-col gap-6">
              <div className="flex justify-between items-end mb-2">
                <div>
                  <p className="text-[#D4A73C] font-medium text-sm tracking-wider uppercase mb-1">Overview</p>
                  <h1 className="text-3xl font-bold text-[#1E3557]">Dashboard</h1>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-white p-6 md:p-8 rounded-2xl shadow-sm border border-gray-100 border-l-4 border-l-blue-500 relative overflow-hidden group hover:shadow-md transition-shadow">
                  <div className="flex justify-between items-center mb-6">
                    <h3 className="text-gray-500 text-xs font-bold tracking-widest uppercase">Today's Bookings</h3>
                  </div>
                  <div className="flex items-baseline gap-2 mb-2">
                    <p className="text-5xl font-black text-[#1E3557]">{bookingData.stats.today_bookings}</p>
                  </div>
                </div>

                <div className="bg-white p-6 md:p-8 rounded-2xl shadow-sm border border-gray-100 border-l-4 border-l-[#D4A73C] relative overflow-hidden group hover:shadow-md transition-shadow">
                  <div className="flex justify-between items-center mb-6">
                    <h3 className="text-gray-500 text-xs font-bold tracking-widest uppercase">Monthly Revenue</h3>
                  </div>
                  <div className="flex items-baseline gap-2 mb-2">
                    <p className="text-4xl font-black text-[#1E3557]">Rs {bookingData.stats.monthly_revenue}</p>
                  </div>
                </div>

                <div className="bg-white p-6 md:p-8 rounded-2xl shadow-sm border border-gray-100 border-l-4 border-l-green-500 relative overflow-hidden group hover:shadow-md transition-shadow">
                  <div className="flex justify-between items-center mb-6">
                    <h3 className="text-gray-500 text-xs font-bold tracking-widest uppercase">Active Sessions</h3>
                  </div>
                  <div className="flex items-baseline gap-2 mb-2">
                    <p className="text-4xl font-black text-[#1E3557]">{bookingData.stats.active_sessions}</p>
                    <span className="text-gray-400 font-medium text-sm">live</span>
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 md:p-8 mt-2">
                <div className="mb-6">
                  <h2 className="text-xl font-bold text-[#1E3557]">Recent Activity</h2>
                </div>

                {loadingBookings ? (
                  <div className="flex items-center justify-center py-12">
                    <div className="h-10 w-10 animate-spin rounded-full border-b-2 border-[#D4A73C]"></div>
                  </div>
                ) : bookingData.upcoming.length > 0 ? (
                  <div className="space-y-4">
                    {bookingData.upcoming.slice(0, 2).map((booking) => renderBookingCard(booking, true))}
                  </div>
                ) : (
                  <div className="flex flex-col items-center justify-center py-12 px-4 text-center bg-[#f8f9fa] rounded-xl border border-dashed border-gray-200">
                    <h4 className="text-[#1E3557] text-lg font-bold mb-2">No new updates</h4>
                    <p className="text-sm text-gray-500 max-w-sm leading-relaxed">
                      Your schedule is clear right now. New client bookings will appear here automatically.
                    </p>
                  </div>
                )}
              </div>
            </div>
          )}

          {activeTab === "incoming" && (
            <div className="animate-fade-in flex flex-col gap-6">
              <div className="flex justify-between items-end mb-2">
                <div>
                  <p className="text-[#D4A73C] font-medium text-sm tracking-wider uppercase mb-1">Manage Requests</p>
                  <h1 className="text-3xl font-bold text-[#1E3557]">Incoming Bookings</h1>
                </div>
              </div>

              <div className="space-y-4">
                {loadingBookings ? (
                  <div className="flex items-center justify-center rounded-2xl border border-gray-100 bg-white py-12">
                    <div className="h-10 w-10 animate-spin rounded-full border-b-2 border-[#D4A73C]"></div>
                  </div>
                ) : bookingData.upcoming.length > 0 ? (
                  bookingData.upcoming.map((booking) => renderBookingCard(booking, true))
                ) : (
                  <div className="rounded-2xl border border-dashed border-gray-200 bg-white px-6 py-12 text-center">
                    <h4 className="text-lg font-bold text-[#1E3557]">No upcoming bookings</h4>
                    <p className="mt-2 text-sm text-gray-500">New consultation bookings will appear here and update automatically.</p>
                  </div>
                )}
              </div>
            </div>
          )}

          {activeTab === "past" && (
            <div className="animate-fade-in flex flex-col gap-6">
              <div className="flex justify-between items-end mb-2">
                <div>
                  <p className="text-[#D4A73C] font-medium text-sm tracking-wider uppercase mb-1">History</p>
                  <h1 className="text-3xl font-bold text-[#1E3557]">Past Bookings</h1>
                </div>
              </div>

              <div className="space-y-4">
                {loadingBookings ? (
                  <div className="flex items-center justify-center rounded-2xl border border-gray-100 bg-white py-12">
                    <div className="h-10 w-10 animate-spin rounded-full border-b-2 border-[#D4A73C]"></div>
                  </div>
                ) : bookingData.history.length > 0 ? (
                  bookingData.history.map((booking) => renderBookingCard(booking, false))
                ) : (
                  <div className="rounded-2xl border border-dashed border-gray-200 bg-white px-6 py-12 text-center">
                    <h4 className="text-lg font-bold text-[#1E3557]">No past bookings</h4>
                    <p className="mt-2 text-sm text-gray-500">Completed and past consultations will appear here.</p>
                  </div>
                )}
              </div>
            </div>
          )}

          {activeTab === "profile" && <ProfileManagementForm user={user} />}
        </main>
      </div>

    </div>
  );
}
