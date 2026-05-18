import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { createRitualBooking } from "../api/bookingApi";
import poojaRitual from "../assets/pooja ritual.png";
import bhagwat from "../assets/bhagwat.png";
import lamp from "../assets/lamp.png";

const API_BASE = import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000/api";
const BACKEND_BASE = import.meta.env.VITE_BACKEND_URL || "http://127.0.0.1:8000";
const ritualFallbacks = [poojaRitual, bhagwat, lamp];

const getImageUrl = (path, fallback) => {
  if (!path) return fallback;
  if (path.startsWith("http")) return path;
  return `${BACKEND_BASE}${path.startsWith("/") ? path : `/${path}`}`;
};

const initialForm = {
  devotee_name: "",
  devotee_email: "",
  devotee_phone: "",
  venue_type: "temple",
  preferred_date: "",
  preferred_time: "",
  location_address: "",
  location_city: "",
  location_state: "",
  location_pincode: "",
  notes: "",
  expense_acknowledged: false,
  birth_details: {
    date_of_birth: "",
    time_of_birth: "",
    place_of_birth: "",
  },
};

const venueOptions = [
  {
    value: "temple",
    title: "Temple Arrangement",
    description: "We coordinate the ritual at a partnered temple or ritual venue in your preferred city.",
  },
  {
    value: "client_place",
    title: "At Your Location",
    description: "Priests visit your home or venue and perform the ritual offline at your place.",
  },
  {
    value: "online",
    title: "Online Guidance",
    description: "Remote sankalp, guidance, and ritual coordination for devotees who cannot attend physically.",
  },
];

export default function RitualBooking() {
  const { slug } = useParams();
  const navigate = useNavigate();
  const [ritual, setRitual] = useState(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState("");
  const [form, setForm] = useState(initialForm);

  useEffect(() => {
    const loadRitual = async () => {
      try {
        const response = await fetch(`${API_BASE}/rituals/${slug}`);
        const data = await response.json();

        if (data.success) {
          setRitual(data.ritual);
        }
      } catch (error) {
        console.error("Failed to load ritual booking page", error);
      } finally {
        setLoading(false);
      }
    };

    void loadRitual();
  }, [slug]);

  useEffect(() => {
    const rawUser = localStorage.getItem("user");
    if (!rawUser) {
      return;
    }

    try {
      const user = JSON.parse(rawUser);
      setForm((current) => ({
        ...current,
        devotee_name: current.devotee_name || user?.name || "",
        devotee_email: current.devotee_email || user?.email || "",
        devotee_phone: current.devotee_phone || user?.phone || "",
        birth_details: {
          date_of_birth: current.birth_details.date_of_birth || user?.date_of_birth || "",
          time_of_birth: current.birth_details.time_of_birth || user?.time_of_birth || "",
          place_of_birth: current.birth_details.place_of_birth || user?.place_of_birth || "",
        },
      }));
    } catch (error) {
      console.error("Failed to prefill ritual booking form", error);
    }
  }, []);

  const selectedVenue = useMemo(
    () => venueOptions.find((item) => item.value === form.venue_type) || venueOptions[0],
    [form.venue_type]
  );

  const handleChange = (event) => {
    const { name, value, type, checked } = event.target;

    if (name.startsWith("birth_details.")) {
      const key = name.split(".")[1];
      setForm((current) => ({
        ...current,
        birth_details: {
          ...current.birth_details,
          [key]: value,
        },
      }));
      return;
    }

    setForm((current) => ({
      ...current,
      [name]: type === "checkbox" ? checked : value,
    }));
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (!ritual) {
      return;
    }

    if (!form.devotee_name || !form.devotee_phone || !form.preferred_date || !form.preferred_time) {
      setMessage("Please complete the devotee details and preferred ritual schedule.");
      return;
    }

    if (!form.location_city || !form.location_state) {
      setMessage("Please enter the city and state for this ritual booking.");
      return;
    }

    if ((form.venue_type === "temple" || form.venue_type === "client_place") && !form.location_address.trim()) {
      setMessage("Please enter the address or locality where you want the ritual arranged.");
      return;
    }

    if (form.venue_type === "client_place" && !form.expense_acknowledged) {
      setMessage("Please confirm the travel and accommodation expense responsibility for offline rituals at your location.");
      return;
    }

    try {
      setSubmitting(true);
      setMessage("");

      const response = await createRitualBooking(ritual.id, form);

      if (response?.success) {
        navigate("/my-bookings", {
          state: {
            message: `Ritual booking ${response.booking.booking_reference} submitted successfully.`,
          },
        });
      }
    } catch (error) {
      console.error("Failed to submit ritual booking", error);
      setMessage(error?.response?.data?.message || "Unable to submit ritual booking.");
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-[#faf8f3]">
        <Navbar />
        <div className="flex items-center justify-center py-32">
          <div className="h-12 w-12 animate-spin rounded-full border-b-2 border-[#D4A73C]"></div>
        </div>
      </div>
    );
  }

  if (!ritual) {
    return (
      <div className="min-h-screen bg-[#faf8f3]">
        <Navbar />
        <div className="mx-auto max-w-4xl px-4 py-24 text-center">
          <h1 className="text-4xl font-black text-[#1E3557]">Ritual not found</h1>
          <p className="mt-4 text-gray-500">The requested ritual booking page could not be loaded.</p>
          <Link to="/rituals" className="mt-6 inline-flex rounded-xl bg-[#1E3557] px-5 py-3 text-white">
            Back to Ritual Catalog
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#faf8f3] text-[#1E3557]">
      <Navbar />

      <section className="relative overflow-hidden bg-[#13294b] text-white">
        <div className="absolute inset-0 bg-gradient-to-r from-[#13294b] via-[#13294b]/90 to-[#13294b]/65"></div>
        <img
          src={getImageUrl(ritual.image, ritualFallbacks[0])}
          alt={ritual.name}
          className="absolute inset-0 h-full w-full object-cover opacity-25"
        />
        <div className="relative mx-auto max-w-7xl px-4 py-16 md:px-8">
          <p className="text-xs font-semibold uppercase tracking-[0.22em] text-[#D4A73C]">Dedicated Ritual Booking</p>
          <h1 className="mt-4 max-w-3xl text-4xl font-black md:text-5xl">{ritual.name}</h1>
          <p className="mt-4 max-w-2xl text-sm leading-7 text-slate-200 md:text-base">
            Share your preferred date, time, and location so our team can review the ritual request and confirm the arrangement from the admin desk.
          </p>
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-4 py-10 md:px-8">
        <div className="grid gap-8 xl:grid-cols-[1fr_340px]">
          <form onSubmit={handleSubmit} className="space-y-8 rounded-3xl border border-[#efe4d2] bg-white p-6 shadow-sm md:p-8">
            <div className="border-b border-[#efe4d2] pb-6">
              <h2 className="text-3xl font-black">Book This Ritual</h2>
              <p className="mt-2 text-sm leading-6 text-gray-500">
                Submit your ritual preference here. The booking will be visible in the admin panel, and the admin team will respond with confirmation, scheduling updates, or special instructions.
              </p>
            </div>

            <div className="grid gap-5 md:grid-cols-2">
              <label className="space-y-2">
                <span className="text-sm font-semibold">Devotee Name</span>
                <input
                  type="text"
                  name="devotee_name"
                  value={form.devotee_name}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-[#eadac2] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  placeholder="Full name"
                />
              </label>
              <label className="space-y-2">
                <span className="text-sm font-semibold">Phone Number</span>
                <input
                  type="text"
                  name="devotee_phone"
                  value={form.devotee_phone}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-[#eadac2] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  placeholder="Mobile number"
                />
              </label>
              <label className="space-y-2">
                <span className="text-sm font-semibold">Email Address</span>
                <input
                  type="email"
                  name="devotee_email"
                  value={form.devotee_email}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-[#eadac2] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  placeholder="Email address"
                />
              </label>
              <label className="space-y-2">
                <span className="text-sm font-semibold">Preferred Date</span>
                <input
                  type="date"
                  name="preferred_date"
                  value={form.preferred_date}
                  onChange={handleChange}
                  min={new Date().toISOString().split("T")[0]}
                  className="w-full rounded-2xl border border-[#eadac2] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                />
              </label>
              <label className="space-y-2">
                <span className="text-sm font-semibold">Preferred Time</span>
                <input
                  type="time"
                  name="preferred_time"
                  value={form.preferred_time}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-[#eadac2] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                />
              </label>
            </div>

            <div className="space-y-4">
              <div>
                <h3 className="text-xl font-bold">Ritual Mode</h3>
                <p className="mt-1 text-sm text-gray-500">Choose how you want the pooja or anusthan to be arranged.</p>
              </div>
              <div className="grid gap-4 md:grid-cols-3">
                {venueOptions.map((option) => {
                  const isActive = form.venue_type === option.value;

                  return (
                    <label
                      key={option.value}
                      className={`cursor-pointer rounded-2xl border p-4 transition ${
                        isActive ? "border-[#D4A73C] bg-[#fff9ef] shadow-sm" : "border-[#efe4d2] bg-white"
                      }`}
                    >
                      <input
                        type="radio"
                        name="venue_type"
                        value={option.value}
                        checked={isActive}
                        onChange={handleChange}
                        className="sr-only"
                      />
                      <p className="font-semibold">{option.title}</p>
                      <p className="mt-2 text-sm leading-6 text-gray-500">{option.description}</p>
                    </label>
                  );
                })}
              </div>
            </div>

            <div className="rounded-3xl border border-[#F1E1B8] bg-[#FFF9EC] p-5">
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[#D4A73C]">Important Booking Note</p>
              <p className="mt-3 text-sm leading-6 text-[#1E3557]">
                If the ritual is performed offline at the client&apos;s location, the priests required for the ritual along with their travel and accommodation expenses will be borne by the client.
              </p>
            </div>

            <div className="grid gap-5 md:grid-cols-2">
              <label className="space-y-2 md:col-span-2">
                <span className="text-sm font-semibold">Location / Address</span>
                <textarea
                  name="location_address"
                  value={form.location_address}
                  onChange={handleChange}
                  rows="3"
                  className="w-full rounded-2xl border border-[#eadac2] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  placeholder="House number, street, locality, temple area, or detailed venue address"
                />
              </label>
              <label className="space-y-2">
                <span className="text-sm font-semibold">City</span>
                <input
                  type="text"
                  name="location_city"
                  value={form.location_city}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-[#eadac2] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  placeholder="City"
                />
              </label>
              <label className="space-y-2">
                <span className="text-sm font-semibold">State</span>
                <input
                  type="text"
                  name="location_state"
                  value={form.location_state}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-[#eadac2] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  placeholder="State"
                />
              </label>
              <label className="space-y-2">
                <span className="text-sm font-semibold">Pincode</span>
                <input
                  type="text"
                  name="location_pincode"
                  value={form.location_pincode}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-[#eadac2] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  placeholder="Postal code"
                />
              </label>
            </div>

            {form.venue_type === "client_place" && (
              <label className="flex items-start gap-3 rounded-2xl border border-[#F1E1B8] bg-[#FFF9EC] p-4">
                <input
                  type="checkbox"
                  name="expense_acknowledged"
                  checked={form.expense_acknowledged}
                  onChange={handleChange}
                  className="mt-1 h-4 w-4 rounded border-gray-300 text-[#D4A73C]"
                />
                <span className="text-sm leading-6 text-[#1E3557]">
                  I confirm that priest travel and accommodation costs for this offline ritual at my location will be borne by me.
                </span>
              </label>
            )}

            <div className="grid gap-5 md:grid-cols-2">
              <label className="space-y-2">
                <span className="text-sm font-semibold">Date of Birth</span>
                <input
                  type="date"
                  name="birth_details.date_of_birth"
                  value={form.birth_details.date_of_birth}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-[#eadac2] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                />
              </label>
              <label className="space-y-2">
                <span className="text-sm font-semibold">Time of Birth</span>
                <input
                  type="time"
                  name="birth_details.time_of_birth"
                  value={form.birth_details.time_of_birth}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-[#eadac2] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                />
              </label>
              <label className="space-y-2 md:col-span-2">
                <span className="text-sm font-semibold">Place of Birth</span>
                <input
                  type="text"
                  name="birth_details.place_of_birth"
                  value={form.birth_details.place_of_birth}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-[#eadac2] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  placeholder="Birth place if the ritual needs horoscope-based sankalp"
                />
              </label>
              <label className="space-y-2 md:col-span-2">
                <span className="text-sm font-semibold">Special Instructions</span>
                <textarea
                  name="notes"
                  value={form.notes}
                  onChange={handleChange}
                  rows="4"
                  className="w-full rounded-2xl border border-[#eadac2] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  placeholder="Mention sankalp intent, family event, gotra notes, or any preferred arrangements"
                />
              </label>
            </div>

            {message && <p className="text-sm font-medium text-[#b45309]">{message}</p>}

            <div className="flex flex-wrap gap-3">
              <button
                type="submit"
                disabled={submitting}
                className="rounded-2xl bg-[#D4A73C] px-6 py-3 text-sm font-bold text-[#1E3557] disabled:opacity-60"
              >
                {submitting ? "Submitting..." : "Submit Ritual Booking"}
              </button>
              <Link
                to={`/rituals/${ritual.slug}`}
                className="rounded-2xl border border-[#1E3557] px-6 py-3 text-sm font-semibold text-[#1E3557]"
              >
                Back to Ritual Details
              </Link>
            </div>
          </form>

          <aside className="space-y-6">
            <div className="sticky top-24 rounded-3xl border border-[#efe4d2] bg-white p-5 shadow-sm">
              <img
                src={getImageUrl(ritual.image, ritualFallbacks[1])}
                alt={ritual.name}
                className="h-48 w-full rounded-2xl object-cover"
              />
              <div className="mt-5">
                <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[#D4A73C]">{ritual.category}</p>
                <h2 className="mt-2 text-2xl font-black">{ritual.name}</h2>
                <p className="mt-3 text-sm leading-6 text-gray-500">{ritual.short_description}</p>
              </div>

              <div className="mt-5 space-y-3 rounded-2xl bg-[#fffaf0] p-4 text-sm text-gray-600">
                <div className="flex justify-between gap-3">
                  <span>Mode Selected</span>
                  <span className="font-semibold text-[#1E3557]">{selectedVenue.title}</span>
                </div>
                <div className="flex justify-between gap-3">
                  <span>Ritual Duration</span>
                  <span className="font-semibold text-[#1E3557]">{ritual.duration_label}</span>
                </div>
                <div className="flex justify-between gap-3">
                  <span>Ideal Timing</span>
                  <span className="text-right font-semibold text-[#1E3557]">{ritual.ideal_timing || "-"}</span>
                </div>
                <div className="flex justify-between gap-3">
                  <span>Base Ritual Amount</span>
                  <span className="font-bold text-[#1E3557]">Rs {Number(ritual.price || 0).toLocaleString("en-IN")}</span>
                </div>
              </div>

              <div className="mt-5 rounded-2xl border border-[#efe4d2] p-4">
                <p className="text-sm font-semibold">What happens next</p>
                <div className="mt-3 space-y-2 text-sm leading-6 text-gray-500">
                  <p>1. Your ritual booking is recorded in the admin panel.</p>
                  <p>2. Admin reviews the request and replies with confirmation or clarifications.</p>
                  <p>3. The final ritual schedule appears under your bookings page.</p>
                </div>
              </div>
            </div>
          </aside>
        </div>
      </section>

      <Footer />
    </div>
  );
}
