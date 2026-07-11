import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import RecentProfilePicker from "../components/RecentProfilePicker";
import { getVedicCalculator, searchLocation } from "../api/prokeralaApi";
import { saveRecentProfile } from "../api/recentProfilesApi";
import { useAuth } from "../context/AuthContext";
import { FaShieldAlt, FaStar, FaExclamationTriangle, FaCheckCircle, FaSpinner } from "react-icons/fa";
import { getServiceIcon } from "../data/serviceIcons";
import { buildRecentProfilePayload, profileTime } from "../utils/recentProfile";

const initialForm = {
  date_of_birth: "",
  time_of_birth: "",
  place_of_birth: "",
  coordinates: "",
  ayanamsa: 1,
  language: "en",
};

const pageIcon = getServiceIcon("detailed-dosha");

export default function DetailedDosha() {
  const { user } = useAuth();
  const [form, setForm] = useState(initialForm);
  const [searchResults, setSearchResults] = useState([]);
  const [loadingPlaces, setLoadingPlaces] = useState(false);
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState("");
  const [results, setResults] = useState(null);

  const isPaid = Boolean(user);

  useEffect(() => {
    if (!user) return;
    const lat = user.latitude || user.lat || user.birth_latitude;
    const lon = user.longitude || user.lon || user.birth_longitude;
    const coordinates = lat && lon ? `${lat},${lon}` : "";

    setForm((current) => ({
      ...current,
      date_of_birth: current.date_of_birth || user.date_of_birth || user.dob || "",
      time_of_birth: current.time_of_birth || user.time_of_birth || user.birth_time || "",
      place_of_birth: current.place_of_birth || user.place_of_birth || user.birth_place || user.city || "",
      coordinates: current.coordinates || coordinates,
    }));
  }, [user]);

  useEffect(() => {
    if (!toast) return undefined;
    const timer = window.setTimeout(() => setToast(""), 3500);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const handleChange = (event) => {
    const { name, value } = event.target;
    setForm((current) => ({ ...current, [name]: value }));
  };

  const handleLocationSearch = async (value) => {
    setForm((current) => ({ ...current, place_of_birth: value, coordinates: "" }));
    if (value.trim().length < 3) {
      setSearchResults([]);
      return;
    }
    try {
      setLoadingPlaces(true);
      const response = await searchLocation(value.trim(), form.language);
      setSearchResults(response?.data || []);
    } catch {
      setSearchResults([]);
    } finally {
      setLoadingPlaces(false);
    }
  };

  const selectLocation = (place) => {
    setForm((current) => ({
      ...current,
      place_of_birth: place.name,
      coordinates: `${place.coordinates.latitude},${place.coordinates.longitude}`,
    }));
    setSearchResults([]);
  };

  const applyRecentProfile = (profile) => {
    setForm((current) => ({
      ...current,
      date_of_birth: profile.date_of_birth || current.date_of_birth,
      time_of_birth: profileTime(profile.time_of_birth) || current.time_of_birth,
      place_of_birth: profile.place_of_birth || current.place_of_birth,
      coordinates: profile.coordinates || current.coordinates,
    }));
  };

  const rememberCurrentProfile = async () => {
    if (!user || !form.date_of_birth) return;
    try {
      await saveRecentProfile(buildRecentProfilePayload({
        name: user.name,
        gender: user.gender,
        date: form.date_of_birth,
        time: form.time_of_birth,
        place: form.place_of_birth,
        coordinates: form.coordinates,
        sourceModule: "detailed-dosha",
        relationRole: "self",
      }));
    } catch {
      // Do not block the report if helper storage fails.
    }
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    if (!form.date_of_birth || !form.time_of_birth) {
      setToast("Date and time of birth are required.");
      return;
    }
    if (!form.coordinates) {
      setToast("Select a valid birthplace from the dropdown.");
      return;
    }

    try {
      setLoading(true);
      setResults(null);
      const datetime = `${form.date_of_birth}T${form.time_of_birth}:00+05:30`;
      
      const payload = {
        datetime,
        coordinates: form.coordinates,
        ayanamsa: Number(form.ayanamsa),
        la: form.language,
        detailed_report: true,
      };

      // Fetch all doshas concurrently
      const [mangal, kaalsarp, sadesati, pitra] = await Promise.allSettled([
        getVedicCalculator("mangal-dosha", payload),
        getVedicCalculator("kaal-sarp-dosha", payload),
        getVedicCalculator("sade-sati", payload),
        getVedicCalculator("pitra-dosha", payload),
      ]);

      setResults({
        mangal: mangal.status === "fulfilled" ? mangal.value.data : null,
        kaalsarp: kaalsarp.status === "fulfilled" ? kaalsarp.value.data : null,
        sadesati: sadesati.status === "fulfilled" ? sadesati.value.data : null,
        pitra: pitra.status === "fulfilled" ? pitra.value.data : null,
      });

      void rememberCurrentProfile();
      setToast("Detailed Dosha report generated successfully.");
    } catch (error) {
      setToast("Failed to fetch all dosha modules.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#FBF7F0] text-[#1E3557] font-sans">
      {toast && (
        <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-xl bg-[#1E3557] px-6 py-3 text-sm font-medium text-white shadow-lg">
          {toast}
        </div>
      )}

      <Navbar />

      <section className="bg-gradient-to-r from-[#B05B35] to-[#D4A373] px-4 py-20 text-white md:px-10">
        <div className="mx-auto grid max-w-7xl gap-8 text-center md:grid-cols-[1fr_auto] md:items-center md:text-left">
          <div>
            <span className="rounded-full border border-white/20 bg-white/10 px-4 py-1.5 text-[11px] font-bold uppercase tracking-[0.22em]">
              Premium Vedic Reports
            </span>
            <h1 className="mt-6 max-w-4xl text-4xl font-black leading-tight md:text-6xl">
              Detailed Dosha Analysis
            </h1>
            <p className="mt-6 max-w-3xl text-sm leading-7 text-white/85 md:text-base">
              In-depth checks for Manglik dosha, Kaalsarpa combinations, Pitra effects, and Shani Sade Sati cycles with tailored Vedic remedies.
            </p>
          </div>
          <div className="mx-auto flex h-28 w-28 items-center justify-center rounded-[1.75rem] bg-white p-3 shadow-2xl md:h-36 md:w-36">
            <img src={pageIcon} alt="" className="h-full w-full object-contain" />
          </div>
        </div>
      </section>

      {/* Paywall Container */}
      {!isPaid ? (
        <section className="mx-auto max-w-5xl px-4 py-16 md:px-8">
          <div className="rounded-[2.5rem] border-2 border-dashed border-[#E5C497] bg-white p-8 md:p-14 text-center shadow-xl">
            <div className="mx-auto flex h-24 w-24 items-center justify-center rounded-3xl bg-[#FFF6E9] border border-[#F6E6BB] text-[#B05B35] shadow-inner mb-8">
              <FaShieldAlt className="text-5xl animate-bounce" />
            </div>
            
            <h2 className="text-3xl font-black tracking-tight text-[#1E3557] md:text-4xl">
              Lock in Deep Astrological Peace
            </h2>
            <p className="mt-4 mx-auto max-w-2xl text-sm leading-7 text-gray-500 md:text-base">
              Get an absolute understanding of Manglik, Kaalsarpa, and Pitra doshas including cancelation conditions, upcoming sade sati transit dates, and clear remedies designed by master astrologers.
            </p>

            {/* Price Box */}
            <div className="mx-auto my-10 max-w-md rounded-3xl border border-[#F1E0C6] bg-gradient-to-tr from-[#FFFDF9] to-[#FFF7EC] p-6 shadow-sm">
              <span className="rounded-full bg-[#B05B35]/15 px-3 py-1 text-xs font-bold text-[#B05B35] uppercase tracking-wider">
                Special Offer Today
              </span>
              <p className="mt-4 text-sm font-semibold text-emerald-700">
                Sign in to generate this report without a service charge.
              </p>
              
              <Link
                to="/login"
                className="mt-6 block w-full rounded-2xl bg-[#B05B35] py-3.5 text-center text-sm font-bold text-white shadow-md shadow-[#B05B35]/25 hover:bg-[#974A25] transition"
              >
                Unlock Detailed Dosha Report Now
              </Link>
              <p className="mt-3 text-[11px] text-gray-400">Includes lifetime access to generated digital report</p>
            </div>

            {/* Highlights Grid */}
            <div className="mt-12 border-t border-gray-100 pt-10">
              <h3 className="text-lg font-bold text-[#1E3557]">What is Covered In This Premium Report?</h3>
              <div className="mt-6 grid gap-6 sm:grid-cols-2 md:grid-cols-4 text-left">
                {[
                  { title: "Mangal DoshaExceptions", desc: "Detailed checks on whether your Manglik placement is cancelled out by special planetary alignments." },
                  { title: "Kaalsarpa Variations", desc: "Checks all 12 types of Kaalsarpa configurations to pinpoint correct gemstone or puja suggestions." },
                  { title: "Pitra Dosha Diagnostics", desc: "Traces lineage-related combinations in the 9th house with specific remedies to restore balance." },
                  { title: "Sade Sati Calendars", desc: "Exact transition timeline cycles for Shani Sade Sati to prepare ahead of time." },
                ].map((item, i) => (
                  <div key={i} className="rounded-2xl border border-gray-100 bg-[#FCFAF7] p-5">
                    <div className="flex items-center gap-2 mb-2 font-bold text-[#B05B35]">
                      <span className="text-sm font-bold text-[#D4A373]">★</span>
                      <h4 className="text-sm font-bold text-[#1E3557]">{item.title}</h4>
                    </div>
                    <p className="text-xs leading-5 text-gray-500">{item.desc}</p>
                  </div>
                ))}
              </div>
            </div>

            {/* Testimonials */}
            <div className="mt-12 bg-[#FAF7F2] rounded-3xl p-6 md:p-8 text-left border border-[#EFE9DD]">
              <p className="text-xs font-semibold uppercase tracking-wider text-[#B05B35]">Success Stories</p>
              <h4 className="text-lg font-bold text-[#1E3557] mt-1">What our premium readers say:</h4>
              <div className="mt-4 grid gap-6 md:grid-cols-2">
                <blockquote className="border-l-2 border-[#D4A373] pl-4 text-xs italic text-gray-600 leading-6">
                  "I was always told I had severe Pitra dosha. This detailed analysis explained exactly how it gets modified in my chart and gave me extremely simple remedies to do at home. Feeling much lighter now!"
                  <cite className="block mt-2 font-bold text-[#1E3557] not-italic">— Rohan Mehra, Mumbai</cite>
                </blockquote>
                <blockquote className="border-l-2 border-[#D4A373] pl-4 text-xs italic text-gray-600 leading-6">
                  "The Sade Sati calendar matches my career cycles precisely. Knowing the active phases in advance is helping me plan my investments prudently."
                  <cite className="block mt-2 font-bold text-[#1E3557] not-italic">— Preeti Singh, Delhi</cite>
                </blockquote>
              </div>
            </div>
          </div>
        </section>
      ) : (
        <section className="relative z-10 mx-auto -mt-12 max-w-7xl px-4 pb-16 md:px-10">
          <div className="grid gap-8 xl:grid-cols-[400px_minmax(0,1fr)]">
            <aside className="rounded-[2.2rem] border border-[#EFE3D1] bg-white p-6 shadow-sm self-start">
              <h2 className="text-2xl font-bold">Horoscope Details</h2>
              <p className="mt-2 text-sm text-slate-500">
                Input your birth specifics to fetch all active dosha states simultaneously.
              </p>
              <div className="mt-4">
                <RecentProfilePicker onSelect={applyRecentProfile} />
              </div>

              <form onSubmit={handleSubmit} className="mt-6 space-y-5">
                <div>
                  <label className="mb-2 block text-sm font-semibold text-slate-600">Date of Birth</label>
                  <input
                    type="date"
                    name="date_of_birth"
                    value={form.date_of_birth}
                    max={new Date().toISOString().slice(0, 10)}
                    onChange={handleChange}
                    className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  />
                </div>

                <div>
                  <label className="mb-2 block text-sm font-semibold text-slate-600">Time of Birth</label>
                  <input
                    type="time"
                    name="time_of_birth"
                    value={form.time_of_birth}
                    onChange={handleChange}
                    className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  />
                </div>

                <div className="relative">
                  <label className="mb-2 block text-sm font-semibold text-slate-600">Birth Place</label>
                  <input
                    type="text"
                    value={form.place_of_birth}
                    onChange={(event) => handleLocationSearch(event.target.value)}
                    placeholder="Search birthplace"
                    className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 pr-10 text-sm outline-none focus:border-[#D4A73C]"
                  />
                  {loadingPlaces && <div className="absolute right-4 top-[50px] h-4 w-4 animate-spin rounded-full border-b-2 border-[#D4A73C]" />}
                  {searchResults.length > 0 && (
                    <div className="absolute z-20 mt-1 max-h-60 w-full overflow-y-auto rounded-2xl border border-slate-200 bg-white shadow-xl">
                      {searchResults.map((place, index) => (
                        <button
                          key={`${place.name}-${index}`}
                          type="button"
                          onClick={() => selectLocation(place)}
                          className="block w-full border-b border-slate-50 px-4 py-3 text-left text-sm hover:bg-slate-50 last:border-0"
                        >
                          {place.name}
                        </button>
                      ))}
                    </div>
                  )}
                </div>

                {form.coordinates && (
                  <div className="rounded-2xl border border-slate-100 bg-[#f8f9fc] px-4 py-3 text-xs text-slate-500">
                    Coordinates: {form.coordinates}
                  </div>
                )}

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full rounded-2xl bg-[#B05B35] px-5 py-3.5 text-sm font-bold text-white transition hover:bg-[#974A25] disabled:opacity-60 flex items-center justify-center gap-2"
                >
                  {loading ? (
                    <>
                      <FaSpinner className="animate-spin" />
                      Analyzing Doshas...
                    </>
                  ) : (
                    "Fetch Full Dosha Analysis"
                  )}
                </button>
              </form>
            </aside>

            <main className="space-y-8">
              {!results ? (
                <div className="rounded-[2.2rem] border border-[#EFE3D1] bg-white p-10 text-center shadow-sm">
                  <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-[#FBF7F0] border border-gray-100 text-[#B05B35] mb-4">
                    <FaStar />
                  </div>
                  <h2 className="text-xl font-bold">Generate Dosha Assessment</h2>
                  <p className="mt-2 text-sm text-slate-500 max-w-md mx-auto leading-6">
                    Enter birth details in the sidebar panel. Our engine will fetch, calculate, and format all four major dosha classes in a comprehensive visual layout.
                  </p>
                </div>
              ) : (
                <div className="space-y-8 animate-fadeIn">
                  {/* Mangal Dosha Card */}
                  <div className="rounded-[2.2rem] border border-[#EFE3D1] bg-white p-6 shadow-sm">
                    <div className="flex items-center justify-between border-b border-gray-100 pb-4 mb-4">
                      <div className="flex items-center gap-3">
                        <span className="text-2xl">🔥</span>
                        <div>
                          <h3 className="font-bold text-lg text-[#1E3557]">Mangal Dosha Assessment</h3>
                          <p className="text-xs text-gray-400">Mars Placement & Auspicious Cancelation Checks</p>
                        </div>
                      </div>
                      <span className={`px-4 py-1.5 rounded-full text-xs font-extrabold uppercase tracking-wide ${results.mangal?.mangal_dosha?.has_dosha ? 'bg-red-50 text-red-600' : 'bg-emerald-50 text-emerald-600'}`}>
                        {results.mangal?.mangal_dosha?.type ? `${results.mangal.mangal_dosha.type} Manglik` : results.mangal?.mangal_dosha?.has_dosha ? "Manglik" : "No Dosha Detected"}
                      </span>
                    </div>
                    <p className="text-sm leading-6 text-gray-600">{results.mangal?.mangal_dosha?.description || "No dosha description was returned."}</p>
                    
                    {/* Exceptions List */}
                    {results.mangal?.mangal_dosha?.exceptions && results.mangal.mangal_dosha.exceptions.length > 0 && (
                      <div className="mt-4 bg-[#FBF7F0] rounded-2xl p-4 border border-[#F2ECE1]">
                        <h4 className="text-xs font-bold uppercase tracking-wider text-[#B05B35] mb-2">Cancelation Exceptions Active:</h4>
                        <ul className="list-disc pl-4 text-xs text-gray-600 space-y-1">
                          {results.mangal.mangal_dosha.exceptions.map((ex, index) => (
                            <li key={index}>{ex}</li>
                          ))}
                        </ul>
                      </div>
                    )}

                    {/* Remedies */}
                    {results.mangal?.mangal_dosha?.remedies && results.mangal.mangal_dosha.remedies.length > 0 && (
                      <div className="mt-4 border-t border-gray-100 pt-4">
                        <h4 className="text-sm font-bold text-[#1E3557] mb-2">Recommended Remedies:</h4>
                        <div className="grid gap-2 sm:grid-cols-2">
                          {results.mangal.mangal_dosha.remedies.slice(0, 4).map((rem, i) => (
                            <div key={i} className="flex gap-2.5 items-start rounded-xl bg-slate-50 p-3 text-xs text-gray-600">
                              <span className="text-[#D4A373] mt-0.5">✓</span>
                              <span>{rem}</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>

                  {/* Kaalsarpa Card */}
                  <div className="rounded-[2.2rem] border border-[#EFE3D1] bg-white p-6 shadow-sm">
                    <div className="flex items-center justify-between border-b border-gray-100 pb-4 mb-4">
                      <div className="flex items-center gap-3">
                        <span className="text-2xl">🐍</span>
                        <div>
                          <h3 className="font-bold text-lg text-[#1E3557]">Kaal Sarp Dosha Assessment</h3>
                          <p className="text-xs text-gray-400">Rahu-Ketu Axis Containment Check</p>
                        </div>
                      </div>
                      <span className={`px-4 py-1.5 rounded-full text-xs font-extrabold uppercase tracking-wide ${results.kaalsarp?.kaal_sarp_dosha?.has_dosha ? 'bg-amber-50 text-amber-700' : 'bg-emerald-50 text-emerald-600'}`}>
                        {results.kaalsarp?.kaal_sarp_dosha?.has_dosha ? "Present" : "Not Present"}
                      </span>
                    </div>
                    <p className="text-sm leading-6 text-gray-600">{results.kaalsarp?.kaal_sarp_dosha?.description || "No Kaal Sarp Dosha detected in the natal chart. The planetary configuration does not fall entirely within the Rahu-Ketu containment axis."}</p>
                    
                    {/* Details if present */}
                    {results.kaalsarp?.kaal_sarp_dosha?.type && (
                      <div className="mt-4 rounded-2xl bg-[#FFF6E9] p-4 text-xs border border-[#F6E6BB]">
                        <p className="font-bold text-[#B05B35]">Dosha Configuration Type:</p>
                        <p className="mt-1 text-gray-600">{results.kaalsarp.kaal_sarp_dosha.type}</p>
                      </div>
                    )}
                  </div>

                  {/* Pitra Dosha Card */}
                  <div className="rounded-[2.2rem] border border-[#EFE3D1] bg-white p-6 shadow-sm">
                    <div className="flex items-center justify-between border-b border-gray-100 pb-4 mb-4">
                      <div className="flex items-center gap-3">
                        <span className="text-2xl">🪔</span>
                        <div>
                          <h3 className="font-bold text-lg text-[#1E3557]">Pitra Dosha Assessment</h3>
                          <p className="text-xs text-gray-400">9th House Lineage Indicators</p>
                        </div>
                      </div>
                      <span className={`px-4 py-1.5 rounded-full text-xs font-extrabold uppercase tracking-wide ${results.pitra?.pitra_dosha?.has_dosha ? 'bg-orange-50 text-orange-700' : 'bg-emerald-50 text-emerald-600'}`}>
                        {results.pitra?.pitra_dosha?.has_dosha ? "Detected" : "Clean Chart"}
                      </span>
                    </div>
                    <p className="text-sm leading-6 text-gray-600">{results.pitra?.pitra_dosha?.description || "No major lineage-related modifications found. Your 9th house placements are stable and free of severe malefic conjunctions."}</p>
                  </div>

                  {/* Sade Sati Card */}
                  <div className="rounded-[2.2rem] border border-[#EFE3D1] bg-white p-6 shadow-sm">
                    <div className="flex items-center justify-between border-b border-gray-100 pb-4 mb-4">
                      <div className="flex items-center gap-3">
                        <span className="text-2xl">🪐</span>
                        <div>
                          <h3 className="font-bold text-lg text-[#1E3557]">Shani Sade Sati Cycle</h3>
                          <p className="text-xs text-gray-400">Saturn's 7.5 Year Transit Cycle</p>
                        </div>
                      </div>
                      <span className={`px-4 py-1.5 rounded-full text-xs font-extrabold uppercase tracking-wide ${results.sadesati?.sade_sati?.is_active ? 'bg-[#1E3557] text-[#FFF1CF]' : 'bg-emerald-50 text-emerald-600'}`}>
                        {results.sadesati?.sade_sati?.is_active ? "Currently Active" : "Inactive"}
                      </span>
                    </div>
                    <p className="text-sm leading-6 text-gray-600">{results.sadesati?.sade_sati?.description || "Saturn is not currently transiting the 12th, 1st, or 2nd houses from your natal Moon sign. Sade Sati is not active at this time."}</p>

                    {/* Transits list */}
                    {results.sadesati?.transits && results.sadesati.transits.length > 0 && (
                      <div className="mt-5">
                        <h4 className="text-sm font-bold text-[#1E3557] mb-3">Transit Timeline Details:</h4>
                        <div className="overflow-x-auto rounded-2xl border border-gray-100">
                          <table className="w-full text-left text-xs border-collapse">
                            <thead>
                              <tr className="bg-slate-50 font-bold text-slate-700">
                                <th className="p-3 border-b border-gray-100">Phase</th>
                                <th className="p-3 border-b border-gray-100">Start Date</th>
                                <th className="p-3 border-b border-gray-100">End Date</th>
                              </tr>
                            </thead>
                            <tbody>
                              {results.sadesati.transits.slice(0, 5).map((transit, index) => (
                                <tr key={index} className="hover:bg-slate-50 border-b border-gray-50 last:border-b-0 text-gray-600 font-medium">
                                  <td className="p-3 font-semibold text-[#1E3557]">{transit.phase || `Phase ${index + 1}`}</td>
                                  <td className="p-3">{transit.start ? new Date(transit.start).toLocaleDateString() : "-"}</td>
                                  <td className="p-3">{transit.end ? new Date(transit.end).toLocaleDateString() : "-"}</td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              )}
            </main>
          </div>
        </section>
      )}

      <Footer />
    </div>
  );
}
