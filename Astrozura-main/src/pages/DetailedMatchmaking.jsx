import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import RecentProfilePicker from "../components/RecentProfilePicker";
import { RelatedToolTabs, ToolInputPanel } from "../components/tool/ToolLayout";
import { getDivisionalCharts, getMarriageMatching, searchLocation } from "../api/prokeralaApi";
import { saveRecentProfile } from "../api/recentProfilesApi";
import { useAuth } from "../context/AuthContext";
import { FaHeart, FaStar, FaInfoCircle, FaSpinner, FaExchangeAlt, FaMars, FaVenus } from "react-icons/fa";
import { serviceCatalog } from "../data/serviceCatalog";
import { getServiceIcon } from "../data/serviceIcons";
import { ProviderSections } from "../components/report/ReportDataRenderer";
import MatchDivisionalCharts, {
  MATCH_DIVISIONAL_CHART_TYPES,
  normalizeMatchCharts,
} from "../components/report/MatchDivisionalCharts";
import { buildRecentProfilePayload, profileTime } from "../utils/recentProfile";

const initialForm = {
  boy_name: "",
  boy_dob: "",
  boy_time: "",
  boy_place: "",
  boy_coordinates: "",

  girl_name: "",
  girl_dob: "",
  girl_time: "",
  girl_place: "",
  girl_coordinates: "",

  language: "en",
};

const pageIcon = getServiceIcon("detailed-matchmaking");
const reportTabs = serviceCatalog
  .filter((item) => item.category === "Reports")
  .map((item) => ({
    label: item.title,
    to: item.ctaTo,
    icon: item.icon,
    isActive: item.slug === "detailed-matchmaking",
  }));

const normalizeMatchData = (data) => data?.match || data || {};

const withMatchCharts = (data, charts) => {
  if (data?.match) {
    return {
      ...data,
      match: {
        ...data.match,
        match_charts: charts,
      },
    };
  }

  return {
    ...data,
    match_charts: charts,
  };
};

const formatProfileDate = (value) => {
  if (!value) return "-";
  const [year, month, day] = value.split("-");
  if (!year || !month || !day) return value;
  return `${day}-${month}-${year}`;
};

export default function DetailedMatchmaking() {
  const { user } = useAuth();
  const [form, setForm] = useState(initialForm);
  const [searchResults, setSearchResults] = useState([]);
  const [activeSearchField, setActiveSearchField] = useState(""); // "boy" or "girl"
  const [loadingPlaces, setLoadingPlaces] = useState(false);
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState("");
  const [matchData, setMatchData] = useState(null);

  const isPaid = Boolean(user);

  useEffect(() => {
    if (!user) return;
    const lat = user.latitude || user.lat || user.birth_latitude;
    const lon = user.longitude || user.lon || user.birth_longitude;
    const coordinates = lat && lon ? `${lat},${lon}` : "";

    setForm((current) => {
      if (user.gender === "Female") {
        return {
          ...current,
          girl_name: current.girl_name || user.name || "",
          girl_dob: current.girl_dob || user.date_of_birth || user.dob || "",
          girl_time: current.girl_time || user.time_of_birth || user.birth_time || "",
          girl_place: current.girl_place || user.place_of_birth || user.birth_place || user.city || "",
          girl_coordinates: current.girl_coordinates || coordinates,
        };
      } else {
        return {
          ...current,
          boy_name: current.boy_name || user.name || "",
          boy_dob: current.boy_dob || user.date_of_birth || user.dob || "",
          boy_time: current.boy_time || user.time_of_birth || user.birth_time || "",
          boy_place: current.boy_place || user.place_of_birth || user.birth_place || user.city || "",
          boy_coordinates: current.boy_coordinates || coordinates,
        };
      }
    });
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

  const handleLocationSearch = async (field, value) => {
    setActiveSearchField(field);
    setForm((current) => ({
      ...current,
      [`${field}_place`]: value,
      [`${field}_coordinates`]: "",
    }));

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

  const selectLocation = (field, place) => {
    setForm((current) => ({
      ...current,
      [`${field}_place`]: place.name,
      [`${field}_coordinates`]: `${place.coordinates.latitude},${place.coordinates.longitude}`,
    }));
    setSearchResults([]);
    setActiveSearchField("");
  };

  const applyRecentProfile = (field, profile) => {
    setForm((current) => ({
      ...current,
      [`${field}_name`]: profile.person_name || current[`${field}_name`],
      [`${field}_dob`]: profile.date_of_birth || current[`${field}_dob`],
      [`${field}_time`]: profileTime(profile.time_of_birth) || current[`${field}_time`],
      [`${field}_place`]: profile.place_of_birth || current[`${field}_place`],
      [`${field}_coordinates`]: profile.coordinates || current[`${field}_coordinates`],
    }));
  };

  const rememberProfile = async (field, relationRole) => {
    if (!user || !form[`${field}_dob`]) return;
    try {
      await saveRecentProfile(buildRecentProfilePayload({
        name: form[`${field}_name`],
        gender: relationRole === "girl" ? "Female" : "Male",
        date: form[`${field}_dob`],
        time: form[`${field}_time`],
        place: form[`${field}_place`],
        coordinates: form[`${field}_coordinates`],
        sourceModule: "detailed-matchmaking",
        relationRole,
      }));
    } catch {
      // Keep report generation independent from saved-profile storage.
    }
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    if (!form.boy_dob || !form.boy_time || !form.boy_coordinates) {
      setToast("Complete male birth details and birthplace selection.");
      return;
    }
    if (!form.girl_dob || !form.girl_time || !form.girl_coordinates) {
      setToast("Complete female birth details and birthplace selection.");
      return;
    }

    try {
      setLoading(true);
      setMatchData(null);

      const girl_dob_formatted = `${form.girl_dob}T${form.girl_time}:00+05:30`;
      const boy_dob_formatted = `${form.boy_dob}T${form.boy_time}:00+05:30`;

      const response = await getMarriageMatching(
        form.girl_coordinates,
        girl_dob_formatted,
        form.boy_coordinates,
        boy_dob_formatted,
        {
          girl_timezone: "+05:30",
          boy_timezone: "+05:30",
          la: form.language,
          detailed_report: true,
        }
      );

      if (response?.status === "success" && response.data) {
        const [maleChartsResult, femaleChartsResult] = await Promise.allSettled([
          getDivisionalCharts(
            boy_dob_formatted,
            form.boy_coordinates,
            MATCH_DIVISIONAL_CHART_TYPES,
            "north-indian",
            { la: form.language },
          ),
          getDivisionalCharts(
            girl_dob_formatted,
            form.girl_coordinates,
            MATCH_DIVISIONAL_CHART_TYPES,
            "north-indian",
            { la: form.language },
          ),
        ]);

        const matchCharts = {
          male: maleChartsResult.status === "fulfilled" ? normalizeMatchCharts(maleChartsResult.value) : [],
          female: femaleChartsResult.status === "fulfilled" ? normalizeMatchCharts(femaleChartsResult.value) : [],
        };

        setMatchData(withMatchCharts(response.data, matchCharts));
        void rememberProfile("boy", "boy");
        void rememberProfile("girl", "girl");
        setToast("Premium matchmaking report generated successfully.");
        return;
      }
      setToast(response?.message || "Failed to generate report.");
    } catch (error) {
      setToast(error?.response?.data?.message || "Unable to fetch matchmaking data.");
    } finally {
      setLoading(false);
    }
  };

  const matchInfo = normalizeMatchData(matchData);
  const gunaDetails = matchInfo.guna_milan || {};
  const totalScore = gunaDetails.total_points != null ? gunaDetails.total_points : matchInfo.total_points || 0;
  const maxScore = gunaDetails.maximum_points || 36;
  const percentage = Math.round((totalScore / maxScore) * 100);
  const verdictText = matchInfo.message?.description || matchInfo.message || "Compatibility report generated successfully.";
  const getBasicMatchmakingReport = () => {
    if (!matchInfo.provider_sections) return null;
    for (const section of matchInfo.provider_sections) {
      if (section.items) {
        if (section.items.match_ashtakoot_points) {
          const dataObj = section.items.match_ashtakoot_points.data || section.items.match_ashtakoot_points;
          if (dataObj && dataObj.conclusion) {
            return dataObj.conclusion.report || dataObj.conclusion.description || null;
          }
        }
      }
    }
    return null;
  };

  const basicReport = getBasicMatchmakingReport();
  const displayDescription = basicReport || verdictText;

  return (
    <div className="min-h-screen bg-[#FBF7F0] text-[#1E3557] font-sans">
      {toast && (
        <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-xl bg-[#1E3557] px-6 py-3 text-sm font-medium text-white shadow-lg">
          {toast}
        </div>
      )}

      <Navbar />

      <section className="bg-gradient-to-r from-[#8E2DE2] to-[#4A00E0] px-4 py-20 text-white md:px-10">
        <div className="mx-auto grid max-w-7xl gap-8 text-center md:grid-cols-[1fr_auto] md:items-center md:text-left">
          <div>
            <span className="rounded-full border border-white/20 bg-white/10 px-4 py-1.5 text-[11px] font-bold uppercase tracking-[0.22em]">
              Premium Relationship Reports
            </span>
            <h1 className="mt-6 max-w-4xl text-4xl font-black leading-tight md:text-6xl">
              Detailed Matchmaking Report
            </h1>
            <p className="mt-6 max-w-3xl text-sm leading-7 text-white/85 md:text-base">
              Relationship compatibility report going far beyond standard 36-point Gun Milan. We analyze mutual wavelengths, emotional chemistry, romantic bonds, Manglik matching, and future timelines.
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
          <div className="rounded-[2.5rem] border-2 border-dashed border-[#CCA8FA] bg-white p-8 md:p-14 text-center shadow-xl">
            <div className="mx-auto flex h-24 w-24 items-center justify-center rounded-3xl bg-[#F5ECFE] border border-[#DCBEFB] text-[#8E2DE2] shadow-inner mb-8">
              <FaHeart className="text-5xl text-[#8E2DE2] animate-pulse" />
            </div>

            <h2 className="text-3xl font-black tracking-tight text-[#1E3557] md:text-4xl">
              Don't Let A Guna Score Limit Your Love
            </h2>
            <p className="mt-4 mx-auto max-w-2xl text-sm leading-7 text-gray-500 md:text-base">
              Vedic astrology says that marriages are built on chemistry, support, and mutual growth. If traditional Gun Milan returns less than 18 points, our detailed matchmaking explores 10+ factors beyond Ashtakoota to find cancellation exceptions and custom relationship suggestions.
            </p>

            {/* Price Box */}
            <div className="mx-auto my-10 max-w-md rounded-3xl border border-[#E3CEFB] bg-gradient-to-tr from-[#FAF8FE] to-[#F3EBFE] p-6 shadow-sm">
              <span className="rounded-full bg-[#8E2DE2]/10 px-3 py-1 text-xs font-bold text-[#8E2DE2] uppercase tracking-wider">
                Beyond 36 Points Milan
              </span>
              <p className="mt-4 text-sm font-semibold text-emerald-700">
                Sign in to generate this report without a service charge.
              </p>

              <Link
                to="/login"
                className="mt-6 block w-full rounded-2xl bg-[#8E2DE2] py-3.5 text-center text-sm font-bold text-white shadow-md shadow-[#8E2DE2]/25 hover:bg-[#7724C3] transition"
              >
                Sign In to Generate Report
              </Link>
              <p className="mt-3 text-[11px] text-gray-400">Includes complete compatibility dashboard & mutual remedies</p>
            </div>

            {/* Highlights Grid */}
            <div className="mt-12 border-t border-gray-100 pt-10">
              <h3 className="text-lg font-bold text-[#1E3557]">How does this report go beyond traditional Guna Milan?</h3>
              <div className="mt-6 grid gap-6 sm:grid-cols-2 md:grid-cols-4 text-left">
                {[
                  { title: "Physical & Romantic chemistry", desc: "Venus alignments, Mars chemistry, and Yoni matching observations to analyze relationship longevity." },
                  { title: "Mental & Emotional Bond", desc: "Moon sign and Gana wavelength checking to ensure both of you communicate seamlessly." },
                  { title: "Mutual Manglik Harmony", desc: "Analyses whether male & female Manglik doshas cancel each other out harmoniously." },
                  { title: "Joint Remedial Advice", desc: "Practical suggestions, puja recommendations, and gemstones to overcome compatibility blockages." },
                ].map((item, i) => (
                  <div key={i} className="rounded-2xl border border-gray-100 bg-[#FCFAF7] p-5">
                    <div className="flex items-center gap-2 mb-2 font-bold text-[#8E2DE2]">
                      <span className="text-sm font-bold text-[#A24AFA]">★</span>
                      <h4 className="text-sm font-bold text-[#1E3557]">{item.title}</h4>
                    </div>
                    <p className="text-xs leading-5 text-gray-500">{item.desc}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>
      ) : (
        <section className="relative z-10 mx-auto -mt-12 max-w-7xl px-4 pb-16 md:px-10">
          <div className="space-y-8">
            <ToolInputPanel
              title="Relationship Details"
              description="Input male and female parameters to fetch in-depth matching outcomes."
            >

              <form onSubmit={handleSubmit} className="mt-6 space-y-6">
                <div className="grid gap-5 lg:grid-cols-2">
                {/* Male Form */}
                <div className="rounded-2xl border border-slate-100 bg-slate-50 p-4 space-y-4">
                  <h3 className="text-sm font-bold uppercase tracking-wider text-slate-700 flex items-center gap-2">
                    <span className="text-xs">♂</span> Male Profile
                  </h3>
                  <RecentProfilePicker
                    buttonLabel="Choose recent male profile"
                    onSelect={(profile) => applyRecentProfile("boy", profile)}
                  />
                  <div>
                    <input
                      type="text"
                      name="boy_name"
                      value={form.boy_name}
                      onChange={handleChange}
                      placeholder="Male Full Name"
                      className="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-xs outline-none focus:border-[#D4A73C]"
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <input
                      type="date"
                      name="boy_dob"
                      value={form.boy_dob}
                      max={new Date().toISOString().slice(0, 10)}
                      onChange={handleChange}
                      className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-xs outline-none focus:border-[#D4A73C]"
                    />
                    <input
                      type="time"
                      name="boy_time"
                      value={form.boy_time}
                      onChange={handleChange}
                      className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-xs outline-none focus:border-[#D4A73C]"
                    />
                  </div>
                  <div className="relative">
                    <input
                      type="text"
                      value={form.boy_place}
                      onChange={(event) => handleLocationSearch("boy", event.target.value)}
                      placeholder="Search male birthplace"
                      className="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-xs outline-none focus:border-[#D4A73C]"
                    />
                    {loadingPlaces && activeSearchField === "boy" && <div className="absolute right-3 top-3 h-3.5 w-3.5 animate-spin rounded-full border-b-2 border-[#D4A73C]" />}
                    {searchResults.length > 0 && activeSearchField === "boy" && (
                      <div className="absolute z-20 mt-1 max-h-40 w-full overflow-y-auto rounded-xl border border-slate-200 bg-white shadow-xl">
                        {searchResults.map((place, index) => (
                          <button
                            key={`${place.name}-${index}`}
                            type="button"
                            onClick={() => selectLocation("boy", place)}
                            className="block w-full border-b border-slate-50 px-3 py-2 text-left text-[11px] hover:bg-slate-50 last:border-0"
                          >
                            {place.name}
                          </button>
                        ))}
                      </div>
                    )}
                  </div>
                  {form.boy_coordinates && <p className="text-[10px] text-gray-400">Coordinates: {form.boy_coordinates}</p>}
                </div>

                {/* Female Form */}
                <div className="rounded-2xl border border-slate-100 bg-slate-50 p-4 space-y-4">
                  <h3 className="text-sm font-bold uppercase tracking-wider text-slate-700 flex items-center gap-2">
                    <span className="text-xs">♀</span> Female Profile
                  </h3>
                  <RecentProfilePicker
                    buttonLabel="Choose recent female profile"
                    onSelect={(profile) => applyRecentProfile("girl", profile)}
                  />
                  <div>
                    <input
                      type="text"
                      name="girl_name"
                      value={form.girl_name}
                      onChange={handleChange}
                      placeholder="Female Full Name"
                      className="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-xs outline-none focus:border-[#D4A73C]"
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <input
                      type="date"
                      name="girl_dob"
                      value={form.girl_dob}
                      max={new Date().toISOString().slice(0, 10)}
                      onChange={handleChange}
                      className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-xs outline-none focus:border-[#D4A73C]"
                    />
                    <input
                      type="time"
                      name="girl_time"
                      value={form.girl_time}
                      onChange={handleChange}
                      className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-xs outline-none focus:border-[#D4A73C]"
                    />
                  </div>
                  <div className="relative">
                    <input
                      type="text"
                      value={form.girl_place}
                      onChange={(event) => handleLocationSearch("girl", event.target.value)}
                      placeholder="Search female birthplace"
                      className="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-xs outline-none focus:border-[#D4A73C]"
                    />
                    {loadingPlaces && activeSearchField === "girl" && <div className="absolute right-3 top-3 h-3.5 w-3.5 animate-spin rounded-full border-b-2 border-[#D4A73C]" />}
                    {searchResults.length > 0 && activeSearchField === "girl" && (
                      <div className="absolute z-20 mt-1 max-h-40 w-full overflow-y-auto rounded-xl border border-slate-200 bg-white shadow-xl">
                        {searchResults.map((place, index) => (
                          <button
                            key={`${place.name}-${index}`}
                            type="button"
                            onClick={() => selectLocation("girl", place)}
                            className="block w-full border-b border-slate-50 px-3 py-2 text-left text-[11px] hover:bg-slate-50 last:border-0"
                          >
                            {place.name}
                          </button>
                        ))}
                      </div>
                    )}
                  </div>
                  {form.girl_coordinates && <p className="text-[10px] text-gray-400">Coordinates: {form.girl_coordinates}</p>}
                </div>
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full rounded-2xl bg-[#8E2DE2] px-5 py-3.5 text-sm font-bold text-white transition hover:bg-[#7724C3] disabled:opacity-60 flex items-center justify-center gap-2"
                >
                  {loading ? (
                    <>
                      <FaSpinner className="animate-spin" />
                      Analyzing Compatibility...
                    </>
                  ) : (
                    "Compute Detailed Matchmaking"
                  )}
                </button>
              </form>
            </ToolInputPanel>

            <RelatedToolTabs title="Reports" items={reportTabs} />

            <main className="space-y-6">
              {!matchData ? (
                <div className="rounded-[2.2rem] border border-[#EFE3D1] bg-white p-10 text-center shadow-sm">
                  <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-[#F5ECFE] border border-gray-100 text-[#8E2DE2] mb-4">
                    <FaHeart />
                  </div>
                  <h2 className="text-xl font-bold">Ready to Compare Compatibility</h2>
                  <p className="mt-2 text-sm text-slate-500 max-w-md mx-auto leading-6">
                    Enter both male & female particulars and trigger analysis. Our engine compiles deep emotional, romantic, physical, and Manglik cancellation values.
                  </p>
                </div>
              ) : (
                <div className="space-y-6 animate-fadeIn">
                  {/* Matching score banner */}
                  <div className="rounded-[2.2rem] border border-[#EFE3D1] bg-gradient-to-tr from-[#FAF8FE] to-[#F5ECFE] p-6 shadow-sm flex flex-col md:flex-row items-center justify-between gap-6">
                    <div className="flex items-center gap-4">
                      {/* Circular Progress Ring */}
                      <div className="relative flex h-24 w-24 shrink-0 items-center justify-center rounded-full bg-white shadow-inner">
                        <svg className="h-full w-full -rotate-90">
                          <circle cx="48" cy="48" r="40" stroke="#f1f5f9" strokeWidth="6" fill="transparent" />
                          <circle cx="48" cy="48" r="40" stroke="#8E2DE2" strokeWidth="6" fill="transparent" strokeDasharray="251" strokeDashoffset={251 - (251 * percentage) / 100} strokeLinecap="round" />
                        </svg>
                        <span className="absolute text-lg font-black text-[#1E3557]">{totalScore}<span className="text-[10px] text-gray-400">/36</span></span>
                      </div>

                      <div>
                        <h3 className="font-bold text-lg text-[#1E3557]">Guna Milan Score</h3>
                        <p className="text-xs text-gray-400">Ashtakoota traditional points matched</p>
                        <p className="text-sm font-extrabold text-[#8E2DE2] mt-1">Verdict: {matchInfo.message?.type || "Generated"}</p>
                        <p className="mt-2 max-w-2xl text-xs leading-5 text-slate-500">{displayDescription}</p>
                      </div>
                    </div>

                    <div className="text-center md:text-right bg-white rounded-2xl px-5 py-3 border border-purple-100 shadow-sm shrink-0">
                      <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400 block">Mutual Manglik Cancellation</span>
                      <span className="text-xs font-bold text-emerald-600 mt-1 block">
                        {matchInfo.exceptions?.length ? `${matchInfo.exceptions.length} exception note(s)` : "No major exception returned"}
                      </span>
                    </div>
                  </div>
                  <div className="grid gap-4 md:grid-cols-[1fr_auto_1fr] md:items-stretch">
                    <div className="rounded-[2rem] border border-[#DDE7F4] bg-gradient-to-br from-[#F8FBFF] to-[#EDF5FF] p-5 shadow-sm">
                      <div className="flex items-start gap-4">
                        <div className="flex h-16 w-16 shrink-0 items-center justify-center rounded-2xl border border-[#B7D3F4] bg-white text-3xl text-[#1E63A6] shadow-sm">
                          <FaMars />
                        </div>
                        <div className="min-w-0">
                          <p className="text-[11px] font-black uppercase tracking-[0.22em] text-[#5C7FA6]">Male</p>
                          <h3 className="mt-1 truncate text-xl font-black text-[#1E3557]">{form.boy_name || "Male Profile"}</h3>
                          <div className="mt-3 grid gap-2 text-sm text-slate-600 sm:grid-cols-2">
                            <span><strong className="text-[#1E3557]">Birth:</strong> {formatProfileDate(form.boy_dob)} {form.boy_time || ""}</span>
                            <span><strong className="text-[#1E3557]">Place:</strong> {form.boy_place || "-"}</span>
                          </div>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center justify-center">
                      <div className="flex h-14 w-14 items-center justify-center rounded-full border border-[#EAD8A5] bg-white text-[#D7AF4B] shadow-sm">
                        <FaExchangeAlt />
                      </div>
                    </div>

                    <div className="rounded-[2rem] border border-[#F2D8E6] bg-gradient-to-br from-[#FFF9FC] to-[#FFEFF7] p-5 shadow-sm">
                      <div className="flex items-start gap-4">
                        <div className="flex h-16 w-16 shrink-0 items-center justify-center rounded-2xl border border-[#F2BFD7] bg-white text-3xl text-[#C0417D] shadow-sm">
                          <FaVenus />
                        </div>
                        <div className="min-w-0">
                          <p className="text-[11px] font-black uppercase tracking-[0.22em] text-[#A65C82]">Female</p>
                          <h3 className="mt-1 truncate text-xl font-black text-[#1E3557]">{form.girl_name || "Female Profile"}</h3>
                          <div className="mt-3 grid gap-2 text-sm text-slate-600 sm:grid-cols-2">
                            <span><strong className="text-[#1E3557]">Birth:</strong> {formatProfileDate(form.girl_dob)} {form.girl_time || ""}</span>
                            <span><strong className="text-[#1E3557]">Place:</strong> {form.girl_place || "-"}</span>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                  <ProviderSections
                    sections={matchInfo.provider_sections || []}
                    renderSectionExtra={(section) =>
                      section?.id === "match-astro-details" ? (
                        <MatchDivisionalCharts charts={matchInfo.match_charts} />
                      ) : null
                    }
                  />
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
