import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import { getAstrologerBookings, markBookingCompleted } from "../../api/bookingApi";
import api from "../../api/axios";
import { assetUrl } from "../../utils/assetUrl";

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

const bookingCardTheme = {
  confirmed: "from-[#EDF5FF] to-white border-blue-100 border-l-blue-400",
  in_progress: "from-[#FFF7DE] to-white border-amber-100 border-l-[#D4A73C]",
  completed: "from-[#ECFDF5] to-white border-emerald-100 border-l-emerald-400",
  cancelled: "from-[#FFF1F2] to-white border-rose-100 border-l-rose-400",
  declined: "from-[#FFF1F2] to-white border-rose-100 border-l-rose-400",
};

const activityTheme = {
  confirmed: "bg-blue-50 text-blue-700",
  in_progress: "bg-amber-50 text-amber-700",
  completed: "bg-emerald-50 text-emerald-700",
  cancelled: "bg-rose-50 text-rose-700",
  declined: "bg-rose-50 text-rose-700",
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

const getConsultationLabel = (booking) => {
  if (booking.service_context === "ritual-consultation") return "Pooja Anusthan Consultation";
  return booking.consultation_type === "call" ? "Audio Call" : "Chat Consultation";
};

const getActivityTitle = (booking) => {
  const label = getConsultationLabel(booking);
  if (booking.status === "completed") return `Completed ${label}`;
  if (booking.status === "in_progress") return `Started ${label}`;
  if (["cancelled", "declined"].includes(booking.status)) return `${label} ${booking.status}`;
  return `New ${label} received`;
};

const buildRecentActivities = (bookingData) => {
  const bookings = [...(bookingData.upcoming || []), ...(bookingData.history || [])];
  return bookings
    .map((booking) => ({
      id: `${booking.id}-${booking.status}`,
      title: getActivityTitle(booking),
      client: booking.user_name || "Client",
      reference: booking.booking_reference,
      status: booking.status,
      timestamp: booking.updated_at || booking.created_at || booking.scheduled_at,
      schedule: booking.scheduled_at,
    }))
    .sort((a, b) => new Date(b.timestamp || 0) - new Date(a.timestamp || 0))
    .slice(0, 6);
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
  const backendBaseUrl = import.meta.env.VITE_BACKEND_URL || "https://astrozura.com";
  const astrologerDetail = user?.astrologer_detail || user?.astrologerDetail || {};

  const [formData, setFormData] = useState({
    firstName: nameParts.firstName,
    lastName: nameParts.lastName,
    email: user?.email || "",
    password: "",
    experience_years: astrologerDetail?.experience_years || "",
    languages: astrologerDetail?.languages || "",
    specialities: astrologerDetail?.specialities || "",
    about_bio: astrologerDetail?.about_bio || "",
    profile_image: null,
    is_featured: Boolean(astrologerDetail?.is_featured),
  });
  const [profilePreview, setProfilePreview] = useState(
    astrologerDetail?.profile_image
      ? resolveImageUrl(backendBaseUrl, astrologerDetail.profile_image)
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

      const response = await fetch(`${import.meta.env.VITE_API_BASE_URL || "https://astrozura.com/apigateway/index.php/api"}/astrologer/profile/update`, {
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

        const updatedDetail = data.user?.astrologer_detail || data.user?.astrologerDetail;
        if (updatedDetail?.profile_image) {
          setProfilePreview(resolveImageUrl(backendBaseUrl, updatedDetail.profile_image));
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

              <div className="rounded-2xl border border-[#F1E1B8] bg-[#FFF9EC] px-4 py-3 text-sm text-[#1E3557]">
                <p className="font-bold">Pricing is managed by AstroZura admin.</p>
                <p className="mt-1 text-gray-600">Chat and call rates are controlled centrally so client pricing stays consistent.</p>
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

function PerformancePanel() {
  const [range, setRange] = useState("month");
  const [data, setData] = useState(null);
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState("");

  const loadPerformance = async () => {
    setLoading(true);
    setMessage("");
    try {
      const [performanceResponse, reviewsResponse] = await Promise.all([
        api.get(`/astrologer/performance?range=${range}`),
        api.get("/astrologer/reviews?per_page=50"),
      ]);
      setData(performanceResponse.data);
      setReviews(reviewsResponse.data?.reviews?.data || reviewsResponse.data?.reviews || []);
    } catch (error) {
      console.error("Failed to load performance", error);
      setMessage(error?.response?.data?.message || "Unable to load performance data.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadPerformance();
  }, [range]);

  const updateReview = async (reviewId, action, body = {}) => {
    try {
      await api.post(`/astrologer/reviews/${reviewId}/${action}`, body);
      await loadPerformance();
      setMessage(action === "pin" ? "Review pin setting updated." : "Review flagged for admin review.");
    } catch (error) {
      setMessage(error?.response?.data?.message || "Unable to update review.");
    }
  };

  const stats = data?.stats || {};
  const series = data?.series || [];
  const maxIncome = Math.max(...series.map((item) => Number(item.income || 0)), 1);
  const statCards = [
    ["Bookings", stats.bookings_received ?? 0, "Total received", "from-[#EDF5FF] to-white border-blue-100"],
    ["Completed", stats.completed_bookings ?? 0, "Closed sessions", "from-[#ECFDF5] to-white border-emerald-100"],
    ["Earnings", `Rs ${stats.astrologer_earnings ?? 0}`, "Your share", "from-[#FFF7DE] to-white border-amber-100"],
    ["Rating", stats.average_rating ? `${stats.average_rating}/5` : "No rating", `${stats.reviews_count ?? 0} reviews`, "from-[#F4F1FF] to-white border-violet-100"],
  ];

  return (
    <div className="animate-fade-in flex max-w-full flex-col gap-6 overflow-hidden">
      <div className="flex min-w-0 flex-col gap-4 xl:flex-row xl:items-end xl:justify-between">
        <div className="min-w-0">
          <p className="text-[#D4A73C] font-medium text-sm tracking-wider uppercase mb-1">Performance</p>
          <h1 className="text-3xl font-bold text-[#1E3557]">Analytics & Reviews</h1>
        </div>
        <div className="flex w-full flex-wrap gap-2 rounded-2xl bg-white p-2 shadow-sm xl:w-auto">
          {[
            ["today", "Daily"],
            ["week", "Weekly"],
            ["month", "Monthly"],
            ["year", "Yearly"],
          ].map(([key, label]) => (
            <button
              key={key}
              type="button"
              onClick={() => setRange(key)}
              className={`rounded-xl px-4 py-2 text-sm font-bold transition ${
                range === key ? "bg-[#1E3557] text-white" : "text-[#1E3557] hover:bg-[#F8F9FC]"
              }`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {message && (
        <div className="rounded-2xl border border-[#F1E1B8] bg-[#FFF9EC] px-5 py-3 text-sm font-semibold text-[#1E3557]">
          {message}
        </div>
      )}

      {loading ? (
        <div className="flex items-center justify-center rounded-3xl bg-white py-16 shadow-sm">
          <div className="h-10 w-10 animate-spin rounded-full border-b-2 border-[#D4A73C]"></div>
        </div>
      ) : (
        <>
          <div className="grid max-w-full gap-4 sm:grid-cols-2 xl:grid-cols-4">
            {statCards.map(([title, value, caption, theme]) => (
              <div key={title} className={`rounded-3xl border bg-gradient-to-br ${theme} p-5 shadow-sm`}>
                <p className="text-xs font-black uppercase tracking-[0.18em] text-[#9B7A22]">{title}</p>
                <p className="mt-3 text-3xl font-black text-[#1E3557]">{value}</p>
                <p className="mt-1 text-sm text-gray-500">{caption}</p>
              </div>
            ))}
          </div>

          <div className="max-w-full overflow-hidden rounded-3xl border border-gray-100 bg-white p-5 shadow-sm">
            <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div className="min-w-0">
                <h2 className="text-xl font-black text-[#1E3557]">Income & Booking Trend</h2>
                <p className="mt-1 text-sm text-gray-500">Filtered by the selected period.</p>
              </div>
              <div className="shrink-0 rounded-full bg-[#FFF4D4] px-4 py-2 text-sm font-bold text-[#7A4C00]">
                Gross Rs {stats.gross_income ?? 0}
              </div>
            </div>
            <div className="mt-6 max-w-full overflow-x-auto rounded-2xl bg-[#F8F9FC] p-4">
              <div className="flex h-64 min-w-[560px] items-end gap-3">
                {series.map((item) => {
                  const height = Math.max(12, Math.round((Number(item.income || 0) / maxIncome) * 190));
                  return (
                    <div key={item.label} className="flex min-w-[46px] flex-1 flex-col items-center justify-end gap-2">
                      <div className="text-xs font-bold text-[#1E3557]">{item.bookings}</div>
                      <div
                        className="w-full max-w-[34px] rounded-t-xl bg-gradient-to-t from-[#1E3557] to-[#D4A73C]"
                        style={{ height }}
                        title={`Rs ${item.income}`}
                      />
                      <div className="max-w-[54px] truncate text-[11px] font-semibold text-gray-500" title={item.label}>{item.label}</div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>

          <div className="rounded-3xl border border-gray-100 bg-white p-6 shadow-sm">
            <h2 className="text-xl font-black text-[#1E3557]">Client Reviews</h2>
            <div className="mt-5 grid gap-4">
              {reviews.length ? reviews.map((review) => (
                <div key={review.id} className={`rounded-2xl border p-4 ${review.is_pinned ? "border-[#D4A73C] bg-[#FFF9EC]" : "border-gray-100 bg-[#F8F9FC]"}`}>
                  <div className="flex flex-wrap items-start justify-between gap-3">
                    <div>
                      <p className="font-black text-[#1E3557]">{review.user?.name || "Client"}</p>
                      <p className="mt-1 text-sm text-gray-500">{review.booking?.booking_reference || "Consultation"} · {review.rating}/5</p>
                    </div>
                    <div className="flex flex-wrap gap-2">
                      <button
                        type="button"
                        onClick={() => void updateReview(review.id, "pin", { is_pinned: !review.is_pinned })}
                        className="rounded-xl border border-[#D4A73C] px-3 py-2 text-xs font-bold text-[#1E3557] hover:bg-[#FFF1C9]"
                      >
                        {review.is_pinned ? "Unpin" : "Pin"}
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          const reason = window.prompt("Reason for flagging this review?", review.flag_reason || "");
                          if (reason !== null) void updateReview(review.id, "flag", { flag_reason: reason });
                        }}
                        className="rounded-xl border border-rose-200 px-3 py-2 text-xs font-bold text-rose-600 hover:bg-rose-50"
                      >
                        {review.is_flagged ? "Flagged" : "Flag"}
                      </button>
                    </div>
                  </div>
                  {review.review && <p className="mt-3 text-sm leading-6 text-gray-700">{review.review}</p>}
                </div>
              )) : (
                <div className="rounded-2xl border border-dashed border-gray-200 px-6 py-10 text-center text-sm text-gray-500">
                  Reviews from completed consultations will appear here.
                </div>
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
}

export default function AstrologerDashboard() {
  const { user, logout, setUser } = useAuth();
  const astrologerDetail = user?.astrologer_detail || user?.astrologerDetail || {};
  const canHostLive = Boolean(user?.role === "astrologer" && astrologerDetail?.is_featured);
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
  const [availabilitySaving, setAvailabilitySaving] = useState(false);
  const profileImage = assetUrl(user?.profile_image || astrologerDetail?.profile_image);
  const recentActivities = buildRecentActivities(bookingData);

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
      ? "block w-full px-5 py-3.5 bg-gradient-to-r from-[#1E3557] to-[#2c4b7c] text-white shadow-md border-l-4 border-[#D4A73C] rounded-xl font-bold text-[13px] text-left transition-all duration-200"
      : "block w-full px-5 py-3.5 bg-white hover:bg-[#FFF8E6] text-gray-700 hover:text-[#184070] border-l-4 border-transparent rounded-xl font-semibold text-[13px] text-left transition-all duration-200";
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

  const toggleAvailability = async () => {
    try {
      setAvailabilitySaving(true);
      const response = await api.post("/astrologer/availability", {
        is_online: !Boolean(astrologerDetail?.is_online),
      });
      if (response.data?.user) {
        setUser(response.data.user);
        setBanner(response.data.message || "Availability updated.");
      }
    } catch (error) {
      setBanner(error?.response?.data?.message || "Availability could not be updated.");
    } finally {
      setAvailabilitySaving(false);
    }
  };

  const renderBookingCard = (booking, allowComplete = false) => (
    <div
      key={booking.id}
      className={`rounded-2xl border border-l-4 bg-gradient-to-br p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md ${
        bookingCardTheme[booking.status] || "from-white to-[#F8F9FC] border-gray-100 border-l-[#D4A73C]"
      }`}
    >
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wide text-[#D4A73C]">
            {booking.booking_reference}
          </p>
          <h3 className="mt-2 text-lg font-bold text-[#1E3557]">{booking.user_name}</h3>
          <p className="mt-1 text-sm text-gray-500">
            {getConsultationLabel(booking)} for {booking.duration} minutes
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

      {(allowComplete || booking.service_context === "ritual-consultation" || !["completed", "cancelled", "declined"].includes(booking.status)) && (
        <div className="mt-5 flex flex-wrap justify-end gap-3">
          {booking.service_context === "ritual-consultation" && booking.status === "completed" && (
            <Link
              to={`/session/${booking.id}`}
              className="rounded-xl border border-[#D4A73C] bg-[#FFF9EC] px-5 py-2.5 text-sm font-bold text-[#1E3557] transition hover:bg-[#D4A73C]"
            >
              Send Ritual Response / Payment Request
            </Link>
          )}

          {!["completed", "cancelled", "declined"].includes(booking.status) && (
            <Link
              to={`/session/${booking.id}`}
              className="rounded-xl border border-[#1E3557] px-5 py-2.5 text-sm font-semibold text-[#1E3557] transition hover:bg-[#1E3557] hover:text-white"
            >
              {booking.service_context === "ritual-consultation"
                ? "Open Ritual Chat"
                : booking.consultation_type === "call"
                  ? "Open Consultation Room"
                  : "Open Chat Session & Kundali"}
            </Link>
          )}
          {!["completed", "cancelled", "declined"].includes(booking.status) && (
            <button
              type="button"
              disabled={actionBookingId === booking.id}
              onClick={() => void handleCompleteBooking(booking.id)}
              className="rounded-xl bg-[#D4A73C] px-5 py-2.5 text-sm font-bold text-[#1E3557] disabled:opacity-60"
            >
              {actionBookingId === booking.id ? "Updating..." : "Mark Service Completed"}
            </button>
          )}
        </div>
      )}
    </div>
  );

  return (
    <div className="bg-[#f8f9fa] min-h-screen flex flex-col font-sans">
      {banner && <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-full bg-[#1E3557] px-6 py-3 text-sm font-semibold text-white shadow-lg">{banner}</div>}
      <div className="flex-1 max-w-7xl w-full mx-auto p-4 lg:p-8 flex flex-col lg:flex-row gap-8">
        <aside className="w-full flex-shrink-0 lg:sticky lg:top-6 lg:max-h-[calc(100vh-3rem)] lg:w-[280px] lg:overflow-y-auto lg:overscroll-contain lg:pr-2">
          <div className="overflow-hidden rounded-2xl border border-gray-100 bg-white shadow-sm">
            <div className="relative pt-8 pb-6 px-6 text-center border-b border-gray-100">
              <div className="absolute top-0 left-0 w-full h-24 bg-gradient-to-br from-[#1E3557] to-[#0D1B3E] opacity-90 rounded-b-3xl"></div>

              <div className="relative mx-auto flex h-20 w-20 items-center justify-center overflow-hidden rounded-2xl border-4 border-white bg-[#D4A73C] text-3xl font-bold text-white shadow-lg">
                {profileImage ? (
                  <img src={profileImage} alt={user.name} className="h-full w-full object-cover" />
                ) : (
                  user.name.charAt(0).toUpperCase()
                )}
              </div>

              <div className="mt-4">
                <h3 className="font-bold text-[#1E3557] text-lg">{user.name}</h3>
                <p className="text-[11px] font-bold tracking-wider uppercase text-[#D4A73C] mt-1">Certified Astrologer</p>
                <button
                  type="button"
                  onClick={() => void toggleAvailability()}
                  disabled={availabilitySaving}
                  className={`mt-3 rounded-full px-4 py-2 text-xs font-bold ${
                    astrologerDetail?.is_online
                      ? "bg-emerald-100 text-emerald-700"
                      : "bg-red-100 text-red-700"
                  } disabled:opacity-60`}
                >
                  {availabilitySaving
                    ? "Updating..."
                    : astrologerDetail?.is_online
                      ? "Online - Go Offline"
                      : "Unavailable - Go Online"}
                </button>
              </div>
            </div>

            <nav className="flex flex-col space-y-1 bg-white p-3">
              <button onClick={() => setActiveTab("dashboard")} className={getTabClass("dashboard")}>
                Dashboard Overview
              </button>
              <button onClick={() => setActiveTab("incoming")} className={getTabClass("incoming")}>
                Incoming Bookings
              </button>
              <button onClick={() => setActiveTab("past")} className={getTabClass("past")}>
                Past Bookings
              </button>
              <button onClick={() => setActiveTab("performance")} className={getTabClass("performance")}>
                Performance
              </button>
              <button onClick={() => setActiveTab("profile")} className={getTabClass("profile")}>
                Manage Profile
              </button>
              {canHostLive && (
                <Link
                  to="/live"
                  className="rounded-xl px-4 py-3 text-left text-sm font-semibold text-[#1E3557] transition hover:bg-[#1E3557]/5 hover:text-[#D4A73C]"
                >
                  Live Studio
                </Link>
              )}
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

        <main className="flex min-w-0 flex-1 flex-col gap-6">
          {activeTab === "dashboard" && (
            <div className="animate-fade-in flex flex-col gap-6">
              <div className="flex justify-between items-end mb-2">
                <div>
                  <p className="text-[#D4A73C] font-medium text-sm tracking-wider uppercase mb-1">Overview</p>
                  <h1 className="text-3xl font-bold text-[#1E3557]">Dashboard</h1>
                </div>
                {canHostLive && (
                  <div className="flex flex-col items-end gap-2">
                    <span className="rounded-full bg-[#F6E8BF] px-3 py-1 text-[11px] font-bold uppercase tracking-[0.2em] text-[#8B6A16]">
                      Featured Astrologer
                    </span>
                    <Link
                      to="/live"
                      className="rounded-xl bg-[#1E3557] px-5 py-3 text-sm font-semibold text-white transition hover:bg-[#162744]"
                    >
                      Go Live Studio
                    </Link>
                  </div>
                )}
              </div>

              <div className="grid grid-cols-1 gap-6 md:grid-cols-3">
                <div className="group relative overflow-hidden rounded-2xl border border-blue-100 border-l-4 border-l-blue-500 bg-gradient-to-br from-[#EDF5FF] to-white p-6 shadow-sm transition-shadow hover:shadow-md md:p-8">
                  <div className="flex justify-between items-center mb-6">
                    <h3 className="text-gray-500 text-xs font-bold tracking-widest uppercase">Today's Bookings</h3>
                  </div>
                  <div className="flex items-baseline gap-2 mb-2">
                    <p className="text-5xl font-black text-[#1E3557]">{bookingData.stats.today_bookings}</p>
                  </div>
                </div>

                <div className="group relative overflow-hidden rounded-2xl border border-amber-100 border-l-4 border-l-[#D4A73C] bg-gradient-to-br from-[#FFF7DE] to-white p-6 shadow-sm transition-shadow hover:shadow-md md:p-8">
                  <div className="flex justify-between items-center mb-6">
                    <h3 className="text-gray-500 text-xs font-bold tracking-widest uppercase">Monthly Revenue</h3>
                  </div>
                  <div className="flex items-baseline gap-2 mb-2">
                    <p className="text-4xl font-black text-[#1E3557]">Rs {bookingData.stats.monthly_revenue}</p>
                  </div>
                </div>

                <div className="group relative overflow-hidden rounded-2xl border border-emerald-100 border-l-4 border-l-green-500 bg-gradient-to-br from-[#ECFDF5] to-white p-6 shadow-sm transition-shadow hover:shadow-md md:p-8">
                  <div className="flex justify-between items-center mb-6">
                    <h3 className="text-gray-500 text-xs font-bold tracking-widest uppercase">Active Sessions</h3>
                  </div>
                  <div className="flex items-baseline gap-2 mb-2">
                    <p className="text-4xl font-black text-[#1E3557]">{bookingData.stats.active_sessions}</p>
                    <span className="text-gray-400 font-medium text-sm">live</span>
                  </div>
                </div>
              </div>

              <div className="mt-2 rounded-2xl border border-gray-100 bg-white p-6 shadow-sm md:p-8">
                <div className="mb-6">
                  <h2 className="text-xl font-bold text-[#1E3557]">Recent Activity</h2>
                  <p className="mt-1 text-sm text-gray-500">Latest booking and consultation updates from your panel.</p>
                </div>

                {loadingBookings ? (
                  <div className="flex items-center justify-center py-12">
                    <div className="h-10 w-10 animate-spin rounded-full border-b-2 border-[#D4A73C]"></div>
                  </div>
                ) : recentActivities.length > 0 ? (
                  <div className="grid gap-3">
                    {recentActivities.map((activity) => (
                      <div
                        key={activity.id}
                        className="flex flex-col gap-3 rounded-2xl border border-[#EFE3D1] bg-gradient-to-br from-white to-[#FFFDF7] p-4 shadow-sm sm:flex-row sm:items-center sm:justify-between"
                      >
                        <div className="flex min-w-0 items-start gap-3">
                          <span className={`mt-1 h-3 w-3 shrink-0 rounded-full ${activityTheme[activity.status] || "bg-[#FFF4D4] text-[#7A4C00]"}`} />
                          <div className="min-w-0">
                            <p className="font-bold text-[#1E3557]">{activity.title}</p>
                            <p className="mt-1 text-sm text-gray-500">
                              {activity.client}
                              {activity.reference ? ` - ${activity.reference}` : ""}
                            </p>
                          </div>
                        </div>
                        <div className="shrink-0 rounded-full bg-[#F8F9FC] px-3 py-2 text-xs font-bold text-[#1E3557]">
                          {formatSchedule(activity.timestamp || activity.schedule)}
                        </div>
                      </div>
                    ))}
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

          {activeTab === "performance" && <PerformancePanel />}

          {activeTab === "profile" && <ProfileManagementForm user={user} />}
        </main>
      </div>

    </div>
  );
}
