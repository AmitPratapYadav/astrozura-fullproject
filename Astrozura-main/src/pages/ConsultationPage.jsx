import React, { useCallback, useEffect, useMemo, useState } from "react";
import { useLocation, useNavigate, useParams } from "react-router-dom";
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import avatar from "../assets/astrologer-avatar.jpg";
import api from "../api/axios";
import { createBooking, getBookingAvailability } from "../api/bookingApi";
import { searchLocation } from "../api/prokeralaApi";

const formatDateValue = (date) => {
  if (!date) return "";
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
};

const formatDisplayDate = (date) =>
  date
    ? date.toLocaleDateString("en-IN", { month: "short", day: "numeric", year: "numeric" })
    : "Select date";

const getImageUrl = (path) => {
  if (!path) return avatar;
  if (path.startsWith("http")) return path;
  const baseUrl = import.meta.env.VITE_BACKEND_URL || "http://localhost:8000";
  return `${baseUrl}${path}`;
};

export default function ConsultationPage() {
  const location = useLocation();
  const navigate = useNavigate();
  const { astrologerId } = useParams();
  const [toast, setToast] = useState(null);
  const [astrologer, setAstrologer] = useState(location.state?.astrologer || null);
  const [loadingAstrologer, setLoadingAstrologer] = useState(!location.state?.astrologer);
  const [consultationType, setConsultationType] = useState(location.state?.type || "chat");
  const [duration, setDuration] = useState(location.state?.duration || 15);
  const [selectedDate, setSelectedDate] = useState(new Date());
  const [selectedSlot, setSelectedSlot] = useState("");
  const [availability, setAvailability] = useState([]);
  const [notes, setNotes] = useState("");
  const [birthDetails, setBirthDetails] = useState({
    date_of_birth: "",
    time_of_birth: "",
    place_of_birth: "",
    latitude: "",
    longitude: "",
    coordinates: "",
    gender: "",
  });
  const [birthPlaceResults, setBirthPlaceResults] = useState([]);
  const [loadingBirthPlaces, setLoadingBirthPlaces] = useState(false);
  const [loadingSlots, setLoadingSlots] = useState(false);
  const [step, setStep] = useState("details");
  const [paymentMethod, setPaymentMethod] = useState("upi");
  const [submitting, setSubmitting] = useState(false);
  const [confirmedBooking, setConfirmedBooking] = useState(null);

  const showToast = (message, type = "success") => {
    setToast({ message, type });
    window.clearTimeout(window.__astrozuraBookingToast);
    window.__astrozuraBookingToast = window.setTimeout(() => setToast(null), 3200);
  };

  const loadAvailability = useCallback(async () => {
    if (!astrologer?.id) return;
    try {
      setLoadingSlots(true);
      const response = await getBookingAvailability({
        astrologer_id: astrologer.id,
        consultation_type: consultationType,
        duration,
        booking_date: formatDateValue(selectedDate),
      });
      setAvailability(response?.slots || []);
    } catch (error) {
      console.error("Failed to fetch slots", error);
      setAvailability([]);
      showToast(error?.response?.data?.message || "Unable to load slots.", "error");
    } finally {
      setLoadingSlots(false);
    }
  }, [astrologer?.id, consultationType, duration, selectedDate]);

  useEffect(() => {
    const loadAstrologer = async () => {
      if (astrologer || !astrologerId) {
        setLoadingAstrologer(false);
        return;
      }
      try {
        const response = await api.get(`/astrologer/${astrologerId}`);
        setAstrologer(response.data?.success ? response.data.astrologer : null);
      } catch (error) {
        console.error("Failed to fetch astrologer", error);
        setAstrologer(null);
      } finally {
        setLoadingAstrologer(false);
      }
    };
    void loadAstrologer();
  }, [astrologer, astrologerId]);

  useEffect(() => {
    setSelectedSlot("");
    void loadAvailability();
  }, [loadAvailability]);

  useEffect(() => {
    const rawUser = localStorage.getItem("user");
    if (!rawUser) {
      return;
    }

    try {
      const parsed = JSON.parse(rawUser);
      setBirthDetails((current) => ({
        date_of_birth: current.date_of_birth || parsed?.date_of_birth || "",
        time_of_birth: current.time_of_birth || parsed?.time_of_birth || "",
        place_of_birth: current.place_of_birth || parsed?.place_of_birth || "",
        latitude: current.latitude || parsed?.latitude || "",
        longitude: current.longitude || parsed?.longitude || "",
        coordinates:
          current.coordinates ||
          (parsed?.latitude != null && parsed?.longitude != null ? `${parsed.latitude},${parsed.longitude}` : ""),
        gender: current.gender || parsed?.gender || "",
      }));
    } catch (error) {
      console.error("Failed to prefill consultation birth details", error);
    }
  }, []);

  const details = astrologer?.astrologer_detail || {};
  const rate = consultationType === "chat" ? Number(details.chat_price || 0) : Number(details.call_price || 0);
  const plans = useMemo(() => [10, 15, 20, 30].map((item) => ({ value: item, amount: rate * item })), [rate]);
  const payableAmount = plans.find((item) => item.value === duration)?.amount || 0;

  const validateSelection = () => {
    if (!astrologer?.id) return showToast("Select an astrologer first.", "error"), false;
    if (!selectedSlot) return showToast("Select an available time slot.", "error"), false;
    return true;
  };

  const handleBirthDetailChange = (event) => {
    const { name, value } = event.target;
    setBirthDetails((current) => ({
      ...current,
      [name]: value,
    }));
  };

  const handleBirthPlaceSearch = async (event) => {
    const value = event.target.value;
    setBirthDetails((current) => ({
      ...current,
      place_of_birth: value,
      latitude: "",
      longitude: "",
      coordinates: "",
    }));

    if (value.trim().length < 3) {
      setBirthPlaceResults([]);
      return;
    }

    try {
      setLoadingBirthPlaces(true);
      const response = await searchLocation(value.trim());
      setBirthPlaceResults(response?.data || []);
    } catch (error) {
      console.error("Failed to search birth place", error);
      setBirthPlaceResults([]);
    } finally {
      setLoadingBirthPlaces(false);
    }
  };

  const selectBirthPlace = (place) => {
    const latitude = place.coordinates?.latitude ?? "";
    const longitude = place.coordinates?.longitude ?? "";
    setBirthDetails((current) => ({
      ...current,
      place_of_birth: place.name,
      latitude,
      longitude,
      coordinates: latitude !== "" && longitude !== "" ? `${latitude},${longitude}` : "",
    }));
    setBirthPlaceResults([]);
  };

  const confirmBooking = async () => {
    if (!validateSelection()) {
      setStep("details");
      return;
    }
    try {
      setSubmitting(true);
      const response = await createBooking({
        astrologer_id: astrologer.id,
        consultation_type: consultationType,
        duration,
        booking_date: formatDateValue(selectedDate),
        booking_time: selectedSlot,
        notes,
        birth_details: birthDetails,
      });
      if (!response?.success) throw new Error(response?.message || "Booking failed.");
      setConfirmedBooking(response.booking);
      setStep("success");
      showToast("Booking confirmed successfully.");
      window.setTimeout(() => navigate("/my-bookings", { state: { message: "Booking confirmed successfully." } }), 1800);
    } catch (error) {
      console.error(error);
      if (error?.response?.status === 422) {
        setSelectedSlot("");
        await loadAvailability();
      }
      showToast(error?.response?.data?.message || error.message || "Booking failed.", "error");
      setStep("details");
    } finally {
      setSubmitting(false);
    }
  };

  if (loadingAstrologer) {
    return <div className="min-h-screen bg-[#FFFBF3]"><Navbar /><div className="flex h-[70vh] items-center justify-center"><div className="h-12 w-12 animate-spin rounded-full border-b-2 border-[#D4A73C]"></div></div><Footer /></div>;
  }

  if (!astrologer) {
    return <div className="min-h-screen bg-[#FFFBF3]"><Navbar /><div className="mx-auto flex h-[70vh] max-w-xl items-center justify-center px-4"><div className="rounded-3xl bg-white p-8 text-center shadow-sm"><h1 className="text-2xl font-bold text-[#1E3557]">Astrologer not found</h1><p className="mt-3 text-sm text-gray-500">Open this flow from an astrologer card or profile page.</p><button type="button" onClick={() => navigate("/astrologers")} className="mt-6 rounded-xl bg-[#D4A73C] px-6 py-3 text-sm font-bold text-[#1E3557]">Browse Astrologers</button></div></div><Footer /></div>;
  }

  return (
    <>
      <Navbar />
      {toast && <div className={`fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-full px-6 py-3 text-sm font-semibold text-white shadow-lg ${toast.type === "error" ? "bg-red-500" : "bg-[#1E3557]"}`}>{toast.message}</div>}
      <div className="min-h-screen bg-[#FFFBF3] px-4 py-8 md:px-10">
        <div className="mx-auto max-w-[1100px]">
          <h1 className="text-3xl font-bold text-[#1E3557]">Book Your Consultation</h1>
          <p className="mt-2 text-sm text-gray-500">{step === "details" ? "Step 1 of 3: Personalize your session and share birth details." : step === "payment" ? "Step 2 of 3: Mock payment." : "Step 3 of 3: Booking confirmed."}</p>
          <div className="mt-4 h-2 rounded-full bg-[#F3E4BF]"><div className={`h-2 rounded-full bg-[#D4A73C] ${step === "details" ? "w-1/3" : step === "payment" ? "w-2/3" : "w-full"}`}></div></div>

          {step === "details" && (
            <div className="mt-8 grid gap-8 lg:grid-cols-[1.15fr_0.85fr]">
              <div className="space-y-8">
                <section>
                  <h2 className="mb-4 text-lg font-semibold text-[#1E3557]">1. Choose Consultation Type</h2>
                  <div className="grid gap-4 md:grid-cols-2">
                    {["chat", "call"].map((item) => <button key={item} type="button" onClick={() => setConsultationType(item)} className={`rounded-2xl border p-6 text-left ${consultationType === item ? "border-[#D4A73C] bg-[#FFF7E8]" : "border-gray-200 bg-white"}`}><p className="text-base font-bold text-[#1E3557]">{item === "chat" ? "Chat" : "Audio Call"}</p><p className="mt-2 text-sm text-gray-500">{item === "chat" ? "Instant real-time messaging with your guide" : "Deep voice conversation for clarity"}</p></button>)}
                  </div>
                </section>

                <section>
                  <h2 className="mb-4 text-lg font-semibold text-[#1E3557]">2. Select Duration</h2>
                  <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
                    {plans.map((plan) => <button key={plan.value} type="button" onClick={() => setDuration(plan.value)} className={`rounded-2xl border px-4 py-5 text-center ${duration === plan.value ? "border-[#D4A73C] bg-[#FFF7E8]" : "border-gray-200 bg-white"}`}><p className="font-semibold text-[#1E3557]">{plan.value} Mins</p><p className="mt-1 font-bold text-[#D4A73C]">Rs {plan.amount}</p></button>)}
                  </div>
                </section>

                <section className="grid gap-8 lg:grid-cols-2">
                  <div>
                    <h2 className="mb-4 text-lg font-semibold text-[#1E3557]">3. Select Date</h2>
                    <div className="rounded-3xl border border-gray-100 bg-white p-4 shadow-sm"><DatePicker selected={selectedDate} onChange={(date) => date && setSelectedDate(date)} minDate={new Date()} inline /></div>
                  </div>
                  <div>
                    <div className="mb-4 flex items-center justify-between"><h2 className="text-lg font-semibold text-[#1E3557]">4. Select Time Slot</h2>{loadingSlots && <span className="text-xs font-semibold uppercase text-[#D4A73C]">Loading</span>}</div>
                    <div className="rounded-3xl border border-gray-100 bg-white p-4 shadow-sm">
                      <div className="grid grid-cols-2 gap-3">
                        {availability.map((slot) => <button key={slot.label} type="button" disabled={!slot.is_available} onClick={() => setSelectedSlot(slot.label)} className={`rounded-xl border px-3 py-3 text-sm font-semibold ${selectedSlot === slot.label ? "border-[#D4A73C] bg-[#D4A73C] text-white" : slot.is_available ? "border-gray-200 bg-white text-[#1E3557]" : "cursor-not-allowed border-gray-100 bg-[#F4F4F4] text-gray-300"}`}>{slot.label}</button>)}
                      </div>
                      {!loadingSlots && availability.length === 0 && <p className="mt-3 text-sm text-gray-500">No slots available for this date and duration.</p>}
                    </div>
                  </div>
                </section>

                <section>
                  <h2 className="mb-4 text-lg font-semibold text-[#1E3557]">5. Birth Details for the Astrologer</h2>
                  <div className="rounded-3xl border border-gray-100 bg-white p-5 shadow-sm">
                    <div className="grid gap-4 md:grid-cols-2">
                      <div>
                        <label className="mb-2 block text-sm font-medium text-gray-600">Date of Birth</label>
                        <input
                          type="date"
                          name="date_of_birth"
                          value={birthDetails.date_of_birth}
                          onChange={handleBirthDetailChange}
                          className="w-full rounded-2xl border border-gray-200 bg-white px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                        />
                      </div>
                      <div>
                        <label className="mb-2 block text-sm font-medium text-gray-600">Time of Birth</label>
                        <input
                          type="time"
                          name="time_of_birth"
                          value={birthDetails.time_of_birth}
                          onChange={handleBirthDetailChange}
                          className="w-full rounded-2xl border border-gray-200 bg-white px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                        />
                      </div>
                      <div>
                        <label className="mb-2 block text-sm font-medium text-gray-600">Place of Birth</label>
                        <div className="relative">
                          <input
                            type="text"
                            name="place_of_birth"
                            value={birthDetails.place_of_birth}
                            onChange={handleBirthPlaceSearch}
                            placeholder="Search city and select from dropdown"
                            autoComplete="off"
                            className="w-full rounded-2xl border border-gray-200 bg-white px-4 py-3 pr-10 text-sm outline-none focus:border-[#D4A73C]"
                          />
                          {loadingBirthPlaces && <div className="absolute right-4 top-3.5 h-4 w-4 animate-spin rounded-full border-b-2 border-[#D4A73C]" />}
                          {birthPlaceResults.length > 0 && (
                            <div className="absolute z-30 mt-1 max-h-60 w-full overflow-y-auto rounded-2xl border border-gray-200 bg-white shadow-xl">
                              {birthPlaceResults.map((place, index) => (
                                <button
                                  key={`${place.name}-${index}`}
                                  type="button"
                                  onClick={() => selectBirthPlace(place)}
                                  className="block w-full border-b border-gray-50 px-4 py-3 text-left text-sm hover:bg-gray-50 last:border-0"
                                >
                                  {place.name}
                                </button>
                              ))}
                            </div>
                          )}
                        </div>
                        {birthDetails.coordinates && <p className="mt-2 text-xs text-gray-500">Coordinates: {birthDetails.coordinates}</p>}
                      </div>
                      <div>
                        <label className="mb-2 block text-sm font-medium text-gray-600">Gender</label>
                        <select
                          name="gender"
                          value={birthDetails.gender}
                          onChange={handleBirthDetailChange}
                          className="w-full rounded-2xl border border-gray-200 bg-white px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                        >
                          <option value="">Select gender</option>
                          <option value="male">Male</option>
                          <option value="female">Female</option>
                          <option value="other">Other</option>
                        </select>
                      </div>
                    </div>
                    <p className="mt-4 text-xs leading-5 text-gray-500">
                      These details are shared with the astrologer and can be used during kundali, birth-chart, matchmaking, tarot, or palmistry guidance.
                    </p>
                  </div>
                </section>

                <section>
                  <h2 className="mb-4 text-lg font-semibold text-[#1E3557]">6. Session Notes</h2>
                  <textarea value={notes} onChange={(event) => setNotes(event.target.value)} rows={4} placeholder="Share what you want guidance on. This is optional." className="w-full rounded-2xl border border-gray-200 bg-white px-4 py-4 text-sm outline-none focus:border-[#D4A73C]" />
                </section>
              </div>

              <aside className="rounded-3xl border border-gray-100 bg-white p-6 shadow-sm">
                <h2 className="text-lg font-semibold text-[#1E3557]">Booking Summary</h2>
                <div className="mt-6 flex items-center gap-4"><img src={getImageUrl(details.profile_image)} alt={astrologer.name} className="h-16 w-16 rounded-full object-cover bg-gray-50" /><div><p className="text-xs font-semibold uppercase tracking-wide text-[#D4A73C]">Your Astrologer</p><p className="text-lg font-bold text-[#1E3557]">{astrologer.name}</p><p className="text-sm text-gray-500">{details.specialities || "Vedic Astrology Specialist"}</p></div></div>
                <div className="mt-6 grid grid-cols-2 gap-5 border-t border-gray-100 pt-6">
                  <div><p className="text-xs uppercase text-gray-400">Session</p><p className="mt-1 font-semibold text-[#1E3557]">{consultationType === "chat" ? "Chat" : "Audio Call"}</p></div>
                  <div><p className="text-xs uppercase text-gray-400">Duration</p><p className="mt-1 font-semibold text-[#1E3557]">{duration} Minutes</p></div>
                  <div><p className="text-xs uppercase text-gray-400">Date</p><p className="mt-1 font-semibold text-[#1E3557]">{formatDisplayDate(selectedDate)}</p></div>
                  <div><p className="text-xs uppercase text-gray-400">Time</p><p className="mt-1 font-semibold text-[#1E3557]">{selectedSlot || "Select slot"}</p></div>
                </div>
                {(birthDetails.date_of_birth || birthDetails.time_of_birth || birthDetails.place_of_birth || birthDetails.gender) && (
                  <div className="mt-6 rounded-2xl bg-[#F8F9FC] p-4">
                    <p className="text-xs uppercase text-gray-400">Birth Details Shared</p>
                    <div className="mt-3 grid gap-3 text-sm text-[#1E3557]">
                      {birthDetails.date_of_birth && <p><span className="font-semibold">DOB:</span> {birthDetails.date_of_birth}</p>}
                      {birthDetails.time_of_birth && <p><span className="font-semibold">Time:</span> {birthDetails.time_of_birth}</p>}
                      {birthDetails.place_of_birth && <p><span className="font-semibold">Place:</span> {birthDetails.place_of_birth}</p>}
                      {birthDetails.coordinates && <p><span className="font-semibold">Coordinates:</span> {birthDetails.coordinates}</p>}
                      {birthDetails.gender && <p><span className="font-semibold">Gender:</span> {birthDetails.gender}</p>}
                    </div>
                  </div>
                )}
                <div className="mt-6 border-t border-gray-100 pt-6">
                  <p className="text-xs uppercase text-gray-400">Total Amount Payable</p>
                  <p className="mt-2 text-3xl font-bold text-[#1E3557]">Rs {payableAmount}</p>
                  <button type="button" onClick={() => validateSelection() && setStep("payment")} className="mt-6 w-full rounded-2xl bg-[#D4A73C] px-6 py-4 text-sm font-bold text-[#1E3557]">Proceed to Payment</button>
                </div>
              </aside>
            </div>
          )}

          {step === "payment" && (
            <div className="mt-8 grid gap-8 lg:grid-cols-[1fr_0.9fr]">
              <section className="rounded-3xl border border-gray-100 bg-white p-8 shadow-sm">
                <div className="flex items-center justify-between gap-4"><div><h2 className="text-2xl font-bold text-[#1E3557]">Mock Payment Gateway</h2><p className="mt-2 text-sm text-gray-500">This phase always succeeds and creates a paid booking immediately.</p></div><span className="rounded-full bg-[#FFF7E8] px-4 py-1.5 text-xs font-semibold uppercase text-[#D4A73C]">Always Success</span></div>
                <div className="mt-8 grid gap-4 md:grid-cols-3">{["upi", "card", "wallet"].map((method) => <button key={method} type="button" onClick={() => setPaymentMethod(method)} className={`rounded-2xl border p-5 text-left ${paymentMethod === method ? "border-[#D4A73C] bg-[#FFF7E8]" : "border-gray-200 bg-white"}`}><p className="font-semibold text-[#1E3557]">{method.toUpperCase()}</p><p className="mt-1 text-sm text-gray-500">Mock authorization</p></button>)}</div>
                <div className="mt-8 rounded-3xl bg-[#F8F9FC] p-6">
                  <div className="grid gap-4 md:grid-cols-2">
                    <div><p className="text-xs uppercase text-gray-400">Astrologer</p><p className="mt-1 font-semibold text-[#1E3557]">{astrologer.name}</p></div>
                    <div><p className="text-xs uppercase text-gray-400">Session</p><p className="mt-1 font-semibold text-[#1E3557]">{consultationType === "chat" ? "Chat Consultation" : "Audio Call Consultation"}</p></div>
                    <div><p className="text-xs uppercase text-gray-400">Scheduled For</p><p className="mt-1 font-semibold text-[#1E3557]">{formatDisplayDate(selectedDate)} at {selectedSlot}</p></div>
                    <div><p className="text-xs uppercase text-gray-400">Amount</p><p className="mt-1 font-semibold text-[#1E3557]">Rs {payableAmount}</p></div>
                  </div>
                </div>
                <div className="mt-8 flex flex-wrap gap-3"><button type="button" onClick={() => setStep("details")} className="rounded-2xl border border-gray-200 px-6 py-3 text-sm font-semibold text-[#1E3557]">Back</button><button type="button" onClick={confirmBooking} disabled={submitting} className="rounded-2xl bg-[#D4A73C] px-6 py-3 text-sm font-bold text-[#1E3557] disabled:opacity-60">{submitting ? "Confirming..." : "Pay Now and Confirm"}</button></div>
              </section>
              <aside className="rounded-3xl border border-gray-100 bg-white p-8 shadow-sm">
                <h2 className="text-lg font-semibold text-[#1E3557]">Order Snapshot</h2>
                <div className="mt-6 flex items-center gap-4"><img src={getImageUrl(details.profile_image)} alt={astrologer.name} className="h-16 w-16 rounded-full object-cover bg-gray-50" /><div><p className="font-bold text-[#1E3557]">{astrologer.name}</p><p className="text-sm text-gray-500">{details.languages || "English, Hindi"}</p></div></div>
                <div className="mt-6 space-y-4 text-sm"><div className="flex justify-between"><span className="text-gray-500">Date</span><span className="font-semibold text-[#1E3557]">{formatDisplayDate(selectedDate)}</span></div><div className="flex justify-between"><span className="text-gray-500">Time</span><span className="font-semibold text-[#1E3557]">{selectedSlot}</span></div><div className="flex justify-between"><span className="text-gray-500">Duration</span><span className="font-semibold text-[#1E3557]">{duration} min</span></div><div className="flex justify-between"><span className="text-gray-500">Method</span><span className="font-semibold uppercase text-[#1E3557]">{paymentMethod}</span></div></div>
                {notes && <div className="mt-6 rounded-2xl border border-gray-200 bg-[#F8F9FC] p-4"><p className="text-xs uppercase text-gray-400">Notes</p><p className="mt-2 text-sm text-gray-600">{notes}</p></div>}
              </aside>
            </div>
          )}

          {step === "success" && (
            <div className="mx-auto mt-8 max-w-2xl rounded-3xl border border-gray-100 bg-white p-8 text-center shadow-sm md:p-12">
              <h2 className="text-3xl font-bold text-[#1E3557]">Booking Confirmed</h2>
              <p className="mt-3 text-sm leading-7 text-gray-500">Your booking is scheduled and visible on the astrologer dashboard. You will be redirected to My Bookings shortly.</p>
              <div className="mt-8 rounded-3xl bg-[#F8F9FC] p-6 text-left"><div className="grid gap-4 md:grid-cols-2"><div><p className="text-xs uppercase text-gray-400">Booking Ref</p><p className="mt-1 font-semibold text-[#1E3557]">{confirmedBooking?.booking_reference || "-"}</p></div><div><p className="text-xs uppercase text-gray-400">Astrologer</p><p className="mt-1 font-semibold text-[#1E3557]">{astrologer.name}</p></div><div><p className="text-xs uppercase text-gray-400">Session</p><p className="mt-1 font-semibold text-[#1E3557]">{consultationType === "chat" ? "Chat" : "Audio Call"}</p></div><div><p className="text-xs uppercase text-gray-400">When</p><p className="mt-1 font-semibold text-[#1E3557]">{formatDisplayDate(selectedDate)} at {selectedSlot}</p></div></div></div>
              <button type="button" onClick={() => navigate("/my-bookings")} className="mt-8 rounded-2xl bg-[#D4A73C] px-6 py-3 text-sm font-bold text-[#1E3557]">Go to My Bookings</button>
            </div>
          )}
        </div>
      </div>
      <Footer />
    </>
  );
}
