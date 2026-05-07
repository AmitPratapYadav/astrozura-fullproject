import { useEffect, useState } from "react";
import { Link, useLocation } from "react-router-dom";
import { FaStar } from "react-icons/fa";
import Navbar from "../../components/Navbar";
import Footer from "../../components/Footer";
import { useAuth } from "../../context/AuthContext";
import { getMyBookings, getMyRitualBookings, submitBookingReview } from "../../api/bookingApi";

const formatSchedule = (value) =>
  value
    ? new Date(value).toLocaleString("en-IN", {
        dateStyle: "medium",
        timeStyle: "short",
        timeZone: "Asia/Kolkata",
      })
    : "-";

const statusClass = {
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

export default function MyBookings() {
  const { user } = useAuth();
  const location = useLocation();
  const [bookings, setBookings] = useState({ upcoming: [], history: [] });
  const [ritualBookings, setRitualBookings] = useState({ upcoming: [], history: [] });
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState(location.state?.message || "");
  const [reviewForms, setReviewForms] = useState({});
  const [submittingReviewFor, setSubmittingReviewFor] = useState(null);

  useEffect(() => {
    const loadBookings = async () => {
      try {
        setLoading(true);
        const [consultationResponse, ritualResponse] = await Promise.all([
          getMyBookings(),
          getMyRitualBookings(),
        ]);

        setBookings({
          upcoming: consultationResponse?.upcoming || [],
          history: consultationResponse?.history || [],
        });
        setRitualBookings({
          upcoming: ritualResponse?.upcoming || [],
          history: ritualResponse?.history || [],
        });
      } catch (error) {
        console.error("Failed to load bookings", error);
      } finally {
        setLoading(false);
      }
    };

    if (message) {
      window.setTimeout(() => setMessage(""), 2800);
    }

    void loadBookings();
  }, [message]);

  const getTabClass = (path) =>
    location.pathname === path
      ? "bg-gradient-to-r from-[#1E3557] to-[#2c4b7c] text-white shadow-md border-l-4 border-[#D4A73C]"
      : "bg-transparent text-gray-600 hover:bg-gray-50 hover:text-[#1E3557] border-l-4 border-transparent";

  const updateReviewForm = (bookingId, patch) => {
    setReviewForms((current) => ({
      ...current,
      [bookingId]: {
        rating: current[bookingId]?.rating || 0,
        review: current[bookingId]?.review || "",
        open: true,
        ...current[bookingId],
        ...patch,
      },
    }));
  };

  const saveReview = async (bookingId) => {
    const form = reviewForms[bookingId];

    if (!form?.rating) {
      setMessage("Please select a rating before submitting.");
      return;
    }

    try {
      setSubmittingReviewFor(bookingId);
      const response = await submitBookingReview(bookingId, {
        rating: form.rating,
        review: form.review,
      });

      if (response?.success) {
        setBookings((current) => ({
          ...current,
          history: current.history.map((booking) =>
            booking.id === bookingId
              ? {
                  ...booking,
                  review: response.review,
                  astrologer: booking.astrologer
                    ? {
                        ...booking.astrologer,
                        astrologer_detail: booking.astrologer.astrologer_detail
                          ? {
                              ...booking.astrologer.astrologer_detail,
                              rating: response.summary?.rating ?? booking.astrologer.astrologer_detail.rating,
                              total_reviews: response.summary?.total_reviews ?? booking.astrologer.astrologer_detail.total_reviews,
                            }
                          : booking.astrologer.astrologer_detail,
                      }
                    : booking.astrologer,
                }
              : booking
          ),
        }));
        setReviewForms((current) => ({
          ...current,
          [bookingId]: {
            ...(current[bookingId] || {}),
            open: false,
          },
        }));
        setMessage("Rating submitted successfully.");
      }
    } catch (error) {
      setMessage(error?.response?.data?.message || "Failed to submit rating.");
    } finally {
      setSubmittingReviewFor(null);
    }
  };

  const renderBookingCard = (booking) => (
    <div key={booking.id} className="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wide text-[#D4A73C]">
            {booking.booking_reference}
          </p>
          <h3 className="mt-2 text-lg font-bold text-[#1E3557]">{booking.astrologer_name}</h3>
          <p className="mt-1 text-sm text-gray-500">
            {booking.consultation_type === "chat" ? "Chat Consultation" : "Audio Call"} for{" "}
            {booking.duration} minutes
          </p>
        </div>
        <span className={`rounded-full border px-3 py-1 text-xs font-semibold uppercase ${statusClass[booking.status] || "bg-slate-100 text-slate-600 border-slate-200"}`}>
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
          <p className="text-xs uppercase text-gray-400">Payment</p>
          <p className="mt-1 font-semibold text-[#1E3557]">{booking.payment_status}</p>
        </div>
      </div>
      {!!formatBirthDetails(booking.birth_details).length && (
        <div className="mt-4 rounded-xl border border-[#F1E1B8] bg-[#FFF9EC] px-4 py-3">
          <p className="text-xs font-semibold uppercase tracking-wide text-[#D4A73C]">Birth Details Shared</p>
          <div className="mt-2 grid gap-2 text-sm text-[#1E3557]">
            {formatBirthDetails(booking.birth_details).map((item) => (
              <p key={item}>{item}</p>
            ))}
          </div>
        </div>
      )}
      {booking.notes && <p className="mt-4 rounded-xl bg-[#F8F9FC] px-4 py-3 text-sm text-gray-600">{booking.notes}</p>}
      {!["completed", "cancelled", "declined"].includes(booking.status) && (
        <div className="mt-5 flex justify-end">
          <Link
            to={`/session/${booking.id}`}
            className="inline-flex items-center rounded-xl bg-[#1E3557] px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-[#162744]"
          >
            {booking.consultation_type === "call" ? "Open Consultation Room" : "Open Chat Session"}
          </Link>
        </div>
      )}
      {booking.status === "completed" && (
        <div className="mt-5 rounded-2xl border border-[#F1E1B8] bg-[#FFF9EC] p-4">
          {booking.review ? (
            <>
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <p className="text-xs font-semibold uppercase tracking-wide text-[#D4A73C]">Your Rating</p>
                  <div className="mt-2 flex items-center gap-1">
                    {Array.from({ length: 5 }, (_, index) => (
                      <FaStar
                        key={`${booking.id}-saved-${index}`}
                        className={index < booking.review.rating ? "text-[#D4A73C]" : "text-gray-300"}
                      />
                    ))}
                    <span className="ml-2 text-sm font-semibold text-[#1E3557]">{booking.review.rating}/5</span>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() =>
                    updateReviewForm(booking.id, {
                      open: true,
                      rating: booking.review.rating,
                      review: booking.review.review || "",
                    })
                  }
                  className="rounded-xl border border-[#D4A73C]/30 bg-white px-4 py-2 text-xs font-semibold text-[#1E3557] transition hover:bg-[#FFF4DC]"
                >
                  Edit Rating
                </button>
              </div>
              {booking.review.review && (
                <p className="mt-3 text-sm leading-6 text-gray-600">{booking.review.review}</p>
              )}
            </>
          ) : (
            <>
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <p className="text-sm font-bold text-[#1E3557]">Rate {booking.astrologer_name}</p>
                  <p className="mt-1 text-xs text-gray-500">Share your chat or call experience after a completed session.</p>
                </div>
                {!reviewForms[booking.id]?.open && (
                  <button
                    type="button"
                    onClick={() => updateReviewForm(booking.id, { open: true })}
                    className="rounded-xl bg-[#1E3557] px-4 py-2 text-xs font-semibold text-white transition hover:bg-[#162744]"
                  >
                    Rate Astrologer
                  </button>
                )}
              </div>
            </>
          )}

          {reviewForms[booking.id]?.open && (
            <div className="mt-4 border-t border-[#F1E1B8] pt-4">
              <div className="flex items-center gap-2">
                {Array.from({ length: 5 }, (_, index) => {
                  const starValue = index + 1;
                  const isActive = starValue <= (reviewForms[booking.id]?.rating || 0);
                  return (
                    <button
                      key={`${booking.id}-star-${starValue}`}
                      type="button"
                      onClick={() => updateReviewForm(booking.id, { rating: starValue })}
                      className="transition hover:scale-110"
                    >
                      <FaStar className={`text-lg ${isActive ? "text-[#D4A73C]" : "text-gray-300"}`} />
                    </button>
                  );
                })}
              </div>

              <textarea
                value={reviewForms[booking.id]?.review || ""}
                onChange={(event) => updateReviewForm(booking.id, { review: event.target.value })}
                rows={4}
                placeholder="Write a short review about the astrologer, response quality, clarity, and overall experience."
                className="mt-4 w-full rounded-2xl border border-gray-200 bg-white px-4 py-3 text-sm text-gray-700 outline-none transition focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20"
              />

              <div className="mt-4 flex flex-wrap justify-end gap-3">
                <button
                  type="button"
                  onClick={() => updateReviewForm(booking.id, { open: false })}
                  className="rounded-xl border border-gray-200 bg-white px-4 py-2 text-xs font-semibold text-gray-600 transition hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  disabled={submittingReviewFor === booking.id}
                  onClick={() => saveReview(booking.id)}
                  className="rounded-xl bg-[#D4A73C] px-4 py-2 text-xs font-semibold text-[#1E3557] transition hover:bg-[#c49530] disabled:cursor-not-allowed disabled:opacity-60"
                >
                  {submittingReviewFor === booking.id ? "Submitting..." : booking.review ? "Update Rating" : "Submit Rating"}
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );

  const renderRitualBookingCard = (booking) => {
    const scheduleDate = booking.confirmed_date || booking.preferred_date;
    const scheduleTime = booking.confirmed_time || booking.preferred_time || "-";
    const venueLabel = {
      online: "Online Guidance",
      temple: "Temple Arrangement",
      client_place: "At Client Location",
    }[booking.venue_type] || booking.venue_type || "Ritual";

    return (
      <div key={`ritual-${booking.id}`} className="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-[#D4A73C]">
              {booking.booking_reference}
            </p>
            <h3 className="mt-2 text-lg font-bold text-[#1E3557]">{booking.ritual?.name || "Ritual Booking"}</h3>
            <p className="mt-1 text-sm text-gray-500">
              {venueLabel}
              {booking.astrologer?.name ? ` with ${booking.astrologer.name}` : ""}
            </p>
          </div>
          <span className={`rounded-full border px-3 py-1 text-xs font-semibold uppercase ${statusClass[booking.status] || "bg-slate-100 text-slate-600 border-slate-200"}`}>
            {booking.status}
          </span>
        </div>

        <div className="mt-5 grid gap-3 md:grid-cols-3 text-sm">
          <div>
            <p className="text-xs uppercase text-gray-400">Preferred Schedule</p>
            <p className="mt-1 font-semibold text-[#1E3557]">{scheduleDate || "-"}</p>
            <p className="mt-1 text-gray-500">{scheduleTime}</p>
          </div>
          <div>
            <p className="text-xs uppercase text-gray-400">Location</p>
            <p className="mt-1 font-semibold text-[#1E3557]">
              {[booking.location_city, booking.location_state].filter(Boolean).join(", ") || "-"}
            </p>
            {booking.location_pincode && <p className="mt-1 text-gray-500">{booking.location_pincode}</p>}
          </div>
          <div>
            <p className="text-xs uppercase text-gray-400">Amount</p>
            <p className="mt-1 font-semibold text-[#1E3557]">Rs {booking.amount}</p>
          </div>
        </div>

        {booking.location_address && (
          <div className="mt-4 rounded-xl bg-[#F8F9FC] px-4 py-3 text-sm text-gray-600">
            {booking.location_address}
          </div>
        )}

        {booking.admin_response && (
          <div className="mt-4 rounded-xl border border-[#F1E1B8] bg-[#FFF9EC] px-4 py-3">
            <p className="text-xs font-semibold uppercase tracking-wide text-[#D4A73C]">Admin Response</p>
            <p className="mt-2 text-sm leading-6 text-[#1E3557]">{booking.admin_response}</p>
          </div>
        )}

        {booking.notes && (
          <div className="mt-4 rounded-xl bg-[#F8F9FC] px-4 py-3 text-sm text-gray-600">
            {booking.notes}
          </div>
        )}
      </div>
    );
  };

  return (
    <div className="bg-[#f8f9fa] min-h-screen flex flex-col font-sans">
      <Navbar />
      {message && <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-full bg-[#1E3557] px-6 py-3 text-sm font-semibold text-white shadow-lg">{message}</div>}

      <div className="flex-1 max-w-7xl w-full mx-auto p-4 lg:p-8 flex flex-col lg:flex-row gap-8">
        <aside className="w-full lg:w-[280px] flex-shrink-0">
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden sticky top-24">
            <div className="relative pt-8 pb-6 px-6 text-center">
              <div className="absolute top-0 left-0 w-full h-24 bg-gradient-to-br from-[#1E3557] to-[#0D1B3E] opacity-90 rounded-b-3xl"></div>
              <div className="relative w-20 h-20 mx-auto bg-gradient-to-br from-[#D4A73C] to-[#b88c29] text-white text-3xl font-bold rounded-2xl flex items-center justify-center shadow-lg border-4 border-white rotate-3">
                <span className="-rotate-3">{user?.name ? user.name.charAt(0).toUpperCase() : "U"}</span>
              </div>
              <div className="mt-4">
                <h3 className="font-bold text-[#1E3557] text-lg">{user?.name || "Celestial User"}</h3>
                <p className="text-xs font-medium text-gray-500 mt-0.5">{user?.email || user?.phone || "Free Member"}</p>
              </div>
            </div>
            <nav className="flex flex-col p-3 space-y-1 bg-white">
              <Link to="/dashboard" className={`px-5 py-3.5 rounded-xl transition-all duration-200 font-medium text-sm ${getTabClass("/dashboard")}`}>Dashboard Overview</Link>
              <Link to="/user-profile" className={`px-5 py-3.5 rounded-xl transition-all duration-200 font-medium text-sm ${getTabClass("/user-profile")}`}>My Profile</Link>
              <Link to="/my-bookings" className={`px-5 py-3.5 rounded-xl transition-all duration-200 font-medium text-sm ${getTabClass("/my-bookings")}`}>My Bookings</Link>
            </nav>
          </div>
        </aside>

        <main className="flex-1 flex flex-col gap-6">
          <div>
            <p className="text-[#D4A73C] font-medium text-sm tracking-wider uppercase mb-1">Appointments</p>
            <h1 className="text-3xl font-bold text-[#1E3557]">My Bookings</h1>
          </div>

          {loading ? (
            <div className="flex min-h-[300px] items-center justify-center rounded-2xl border border-gray-100 bg-white">
              <div className="h-12 w-12 animate-spin rounded-full border-b-2 border-[#D4A73C]"></div>
            </div>
          ) : (
            <>
              <section className="rounded-2xl border border-gray-100 bg-white p-6 md:p-8">
                <div className="mb-6 border-b border-gray-100 pb-5">
                  <h2 className="text-xl font-bold text-[#1E3557]">Upcoming Consultations</h2>
                  <p className="text-sm text-gray-500 mt-1">Your confirmed and scheduled astrologer bookings.</p>
                </div>
                <div className="space-y-4">
                  {bookings.upcoming.length > 0 ? bookings.upcoming.map(renderBookingCard) : (
                    <div className="rounded-xl border border-dashed border-gray-200 bg-[#f8f9fa] px-6 py-12 text-center">
                      <h4 className="text-lg font-bold text-[#1E3557]">No active bookings</h4>
                      <p className="mt-2 text-sm text-gray-500">Book an astrologer to see your upcoming consultations here.</p>
                      <Link to="/astrologers" className="mt-5 inline-block rounded-xl bg-[#1E3557] px-6 py-3 text-sm font-semibold text-white">Explore Astrologers</Link>
                    </div>
                  )}
                </div>
              </section>

              <section className="rounded-2xl border border-gray-100 bg-white p-6 md:p-8">
                <div className="mb-6 border-b border-gray-100 pb-5">
                  <h2 className="text-xl font-bold text-[#1E3557]">Upcoming Ritual Bookings</h2>
                  <p className="text-sm text-gray-500 mt-1">Pooja and anusthan requests submitted for admin confirmation.</p>
                </div>
                <div className="space-y-4">
                  {ritualBookings.upcoming.length > 0 ? ritualBookings.upcoming.map(renderRitualBookingCard) : (
                    <div className="rounded-xl border border-dashed border-gray-200 bg-[#f8f9fa] px-6 py-12 text-center">
                      <h4 className="text-lg font-bold text-[#1E3557]">No active ritual bookings</h4>
                      <p className="mt-2 text-sm text-gray-500">Book a pooja or anusthan to see its scheduling status here.</p>
                      <Link to="/rituals" className="mt-5 inline-block rounded-xl bg-[#1E3557] px-6 py-3 text-sm font-semibold text-white">Explore Rituals</Link>
                    </div>
                  )}
                </div>
              </section>

              <section className="rounded-2xl border border-gray-100 bg-white p-6 md:p-8">
                <div className="mb-6 border-b border-gray-100 pb-5">
                  <h2 className="text-xl font-bold text-[#1E3557]">Booking History</h2>
                  <p className="text-sm text-gray-500 mt-1">Completed and past sessions remain listed for reference.</p>
                </div>
                <div className="space-y-4">
                  {bookings.history.length > 0 ? bookings.history.map(renderBookingCard) : (
                    <p className="text-sm text-gray-500">No completed or past consultations yet.</p>
                  )}
                </div>
              </section>

              <section className="rounded-2xl border border-gray-100 bg-white p-6 md:p-8">
                <div className="mb-6 border-b border-gray-100 pb-5">
                  <h2 className="text-xl font-bold text-[#1E3557]">Ritual Booking History</h2>
                  <p className="text-sm text-gray-500 mt-1">Past ritual requests and completed arrangements remain visible here.</p>
                </div>
                <div className="space-y-4">
                  {ritualBookings.history.length > 0 ? ritualBookings.history.map(renderRitualBookingCard) : (
                    <p className="text-sm text-gray-500">No completed or past ritual bookings yet.</p>
                  )}
                </div>
              </section>
            </>
          )}
        </main>
      </div>

      <Footer />
    </div>
  );
}
