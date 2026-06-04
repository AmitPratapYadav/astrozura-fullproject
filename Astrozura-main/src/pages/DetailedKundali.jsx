import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { 
  generateKundli, 
  getDivisionalCharts, 
  getPredictions, 
  getVedicCalculator, 
  searchLocation 
} from "../api/prokeralaApi";
import { useAuth } from "../context/AuthContext";
import { FaBookOpen, FaStar, FaInfoCircle, FaSpinner } from "react-icons/fa";

const initialForm = {
  name: "",
  date_of_birth: "",
  time_of_birth: "",
  place_of_birth: "",
  coordinates: "",
  gender: "Male",
  chart_style: "north-indian",
  language: "en",
};

const divisionalChartOptions = [
  { value: "rasi", label: "D1 - Rasi Chart" },
  { value: "hora", label: "D2 - Hora Chart" },
  { value: "drekkana", label: "D3 - Drekkana Chart" },
  { value: "chaturthamsa", label: "D4 - Chaturthamsa Chart" },
  { value: "saptamsa", label: "D7 - Saptamsa Chart" },
  { value: "navamsa", label: "D9 - Navamsa Chart" },
  { value: "dasamsa", label: "D10 - Dasamsa Chart" },
  { value: "dwadasamsa", label: "D12 - Dwadasamsa Chart" },
  { value: "shodasamsa", label: "D16 - Shodasamsa Chart" },
];

export default function DetailedKundali() {
  const { user } = useAuth();
  const [form, setForm] = useState(initialForm);
  const [searchResults, setSearchResults] = useState([]);
  const [loadingPlaces, setLoadingPlaces] = useState(false);
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState("");
  const [reportData, setReportData] = useState(null);
  
  // Tab states
  const [activeDossierTab, setActiveDossierTab] = useState("birth");
  const [selectedChartType, setSelectedChartType] = useState("rasi");
  const [activePredictionArea, setActivePredictionArea] = useState("career");
  const [loadingChart, setLoadingChart] = useState(false);
  const [loadedCharts, setLoadedCharts] = useState({});

  // Check premium status
  const isPaid = user?.subscription_status === "active" || user?.plan_name?.toLowerCase().includes("premium");

  useEffect(() => {
    if (!user) return;
    const lat = user.latitude || user.lat || user.birth_latitude;
    const lon = user.longitude || user.lon || user.birth_longitude;
    const coordinates = lat && lon ? `${lat},${lon}` : "";

    setForm((current) => ({
      ...current,
      name: current.name || user.name || "",
      date_of_birth: current.date_of_birth || user.date_of_birth || user.dob || "",
      time_of_birth: current.time_of_birth || user.time_of_birth || user.birth_time || "",
      place_of_birth: current.place_of_birth || user.place_of_birth || user.birth_place || user.city || "",
      coordinates: current.coordinates || coordinates,
      gender: current.gender || user.gender || "Male",
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
      setReportData(null);
      setLoadedCharts({});
      const datetime = `${form.date_of_birth}T${form.time_of_birth}:00+05:30`;

      // Fetch primary Kundli core calculations, predictions, and suggestions
      const [kundliRes, predictionsRes, gemstoneRes, rudrakshaRes] = await Promise.allSettled([
        generateKundli(datetime, form.coordinates, 1, {
          chart_style: form.chart_style,
          la: form.language,
        }),
        getPredictions(datetime, form.coordinates, activePredictionArea, { la: form.language }),
        getVedicCalculator("basic-gem-suggestion", { datetime, coordinates: form.coordinates, la: form.language }),
        getVedicCalculator("rudraksha-suggestion", { datetime, coordinates: form.coordinates, la: form.language }),
      ]);

      const mainKundli = kundliRes.status === "fulfilled" ? kundliRes.value.data : null;
      
      if (kundliRes.status === "fulfilled" && kundliRes.value.status === "error") {
        let errMsg = kundliRes.value.message || "Failed to compile full premium Kundli.";
        try {
          const parsed = JSON.parse(errMsg);
          if (parsed.msg) errMsg = parsed.msg;
        } catch (e) {}
        setToast(`Error: ${errMsg}`);
        return;
      }

      // Extract D1 chart if generated by default
      const defaultCharts = {};
      if (mainKundli?.chart) {
        defaultCharts["rasi"] = mainKundli.chart;
      }

      setReportData({
        kundli: mainKundli,
        predictions: {
          [activePredictionArea]: predictionsRes.status === "fulfilled" ? predictionsRes.value.data : null,
        },
        gemstones: gemstoneRes.status === "fulfilled" ? gemstoneRes.value.data : null,
        rudraksha: rudrakshaRes.status === "fulfilled" ? rudrakshaRes.value.data : null,
        datetime,
      });

      setLoadedCharts(defaultCharts);
      setToast("Premium Kundli generated successfully.");
    } catch (error) {
      setToast(error?.response?.data?.message || "Failed to compile full premium Kundli.");
    } finally {
      setLoading(false);
    }
  };

  // Fetch individual divisional chart on click/select
  const loadDivisionalChart = async (type) => {
    if (loadedCharts[type] || loadingChart || !reportData) return;
    
    try {
      setLoadingChart(true);
      const res = await getDivisionalCharts(
        reportData.datetime,
        form.coordinates,
        type,
        form.chart_style,
        { la: form.language }
      );
      
      if (res?.status === "success" && res.data) {
        // Prokerala returns either standard SVG block or charts list
        const svg = res.data.chart_svg || res.data.chart || (Array.isArray(res.data) && res.data[0]?.chart_svg) || res.data.chart_data?.svg;
        if (svg) {
          setLoadedCharts(prev => ({ ...prev, [type]: svg }));
        }
      } else if (res?.status === "error") {
        let errMsg = res.message || "Failed to load chart.";
        try {
          const parsed = JSON.parse(errMsg);
          if (parsed.msg) errMsg = parsed.msg;
        } catch (e) {}
        setLoadedCharts(prev => ({ ...prev, [type]: `<div class="text-red-500 font-bold p-4 text-center text-sm border border-red-200 bg-red-50 rounded-xl">${errMsg}</div>` }));
      }
    } catch {
      setLoadedCharts(prev => ({ ...prev, [type]: `<div class="text-red-500 font-bold p-4 text-center text-sm border border-red-200 bg-red-50 rounded-xl">Error loading chart</div>` }));
    } finally {
      setLoadingChart(false);
    }
  };

  useEffect(() => {
    if (activeDossierTab === "charts" && selectedChartType) {
      loadDivisionalChart(selectedChartType);
    }
  }, [activeDossierTab, selectedChartType]);

  // Load predictions for other sections dynamically
  const loadPredictionArea = async (area) => {
    if (reportData?.predictions?.[area] || loading || !reportData) return;
    try {
      const res = await getPredictions(reportData.datetime, form.coordinates, area, { la: form.language });
      if (res?.status === "success") {
        setReportData(prev => ({
          ...prev,
          predictions: {
            ...prev.predictions,
            [area]: res.data
          }
        }));
      } else if (res?.status === "error") {
        let errMsg = res.message || "Failed to load predictions.";
        try {
          const parsed = JSON.parse(errMsg);
          if (parsed.msg) errMsg = parsed.msg;
        } catch (e) {}
        setReportData(prev => ({
          ...prev,
          predictions: {
            ...prev.predictions,
            [area]: [{ title: "Error", description: errMsg }]
          }
        }));
      }
    } catch {
      setToast(`Failed to fetch predictions for ${area}.`);
    }
  };

  useEffect(() => {
    if (activeDossierTab === "predictions" && activePredictionArea) {
      loadPredictionArea(activePredictionArea);
    }
  }, [activeDossierTab, activePredictionArea]);

  return (
    <div className="min-h-screen bg-[#FBF7F0] text-[#1E3557] font-sans">
      {toast && (
        <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-xl bg-[#1E3557] px-6 py-3 text-sm font-medium text-white shadow-lg">
          {toast}
        </div>
      )}

      <Navbar />

      <section className="bg-gradient-to-r from-[#1E3C72] to-[#2A5298] px-4 py-20 text-white md:px-10">
        <div className="mx-auto max-w-7xl text-center md:text-left">
          <span className="rounded-full border border-white/20 bg-white/10 px-4 py-1.5 text-[11px] font-bold uppercase tracking-[0.22em]">
            Elite Kundali Suite
          </span>
          <h1 className="mt-6 max-w-4xl text-4xl font-black leading-tight md:text-6xl">
            Detailed Kundali Analysis
          </h1>
          <p className="mt-6 max-w-3xl text-sm leading-7 text-white/85 md:text-base">
            Premium interactive digital natal dossier modeled after the 145+ page manual PDF, complete with divisional charts D1-D16, core yogas, Vimshottari dashas, and life predictions.
          </p>
        </div>
      </section>

      {/* Paywall Container */}
      {!isPaid ? (
        <section className="mx-auto max-w-5xl px-4 py-16 md:px-8">
          <div className="rounded-[2.5rem] border-2 border-dashed border-[#A0BCE5] bg-white p-8 md:p-14 text-center shadow-xl">
            <div className="mx-auto flex h-24 w-24 items-center justify-center rounded-3xl bg-[#EEF4FC] border border-[#BACFEA] text-[#1E3C72] shadow-inner mb-8">
              <FaBookOpen className="text-5xl animate-pulse" />
            </div>
            
            <h2 className="text-3xl font-black tracking-tight text-[#1E3557] md:text-4xl">
              Unlock Your Ultimate Birth Blueprint
            </h2>
            <p className="mt-4 mx-auto max-w-2xl text-sm leading-7 text-gray-500 md:text-base">
              Say goodbye to generic single-page horoscopes. Get a deeply comprehensive natal analysis containing 16 divisional charts, vimshottari Maha & Antardasha cycles, and expert predictions regarding wealth, relationships, and health.
            </p>

            {/* Price Box */}
            <div className="mx-auto my-10 max-w-md rounded-3xl border border-[#D5E1F2] bg-gradient-to-tr from-[#FAFBFC] to-[#F1F5FA] p-6 shadow-sm">
              <span className="rounded-full bg-[#1E3C72]/10 px-3 py-1 text-xs font-bold text-[#1E3C72] uppercase tracking-wider">
                Full Digital Dossier
              </span>
              <div className="mt-4 flex items-center justify-center gap-3">
                <span className="text-lg text-gray-400 line-through">₹4,999</span>
                <span className="text-4xl font-black text-[#1E3557]">₹2,100<span className="text-base font-normal">/-</span></span>
              </div>
              <p className="mt-2 text-xs font-bold text-emerald-600">You Save ₹2,899 (58% OFF)</p>
              
              <Link
                to="/subscription"
                className="mt-6 block w-full rounded-2xl bg-[#1E3C72] py-3.5 text-center text-sm font-bold text-white shadow-md shadow-[#1E3C72]/25 hover:bg-[#162C54] transition"
              >
                Get Premium Kundali Now
              </Link>
              <p className="mt-3 text-[11px] text-gray-400">Includes lifetime access & immediate calculation results</p>
            </div>

            {/* Highlights Grid */}
            <div className="mt-12 border-t border-gray-100 pt-10">
              <h3 className="text-lg font-bold text-[#1E3557]">What is Inside the Personalised Kundali Analysis?</h3>
              <div className="mt-6 grid gap-6 sm:grid-cols-2 md:grid-cols-4 text-left">
                {[
                  { title: "D1-D16 Divisional Charts", desc: "Interactive D1 Rasi, D9 Navamsa, D10 Career charts and more with dynamic north/south style conversions." },
                  { title: "Vimshottari Dasha Nested Cycles", desc: "Detailed transition calendars spanning Mahadasha, Antardasha, and Pratyantardashas down to dates." },
                  { title: "Multi-Life Predictions", desc: "Tailored descriptions for career trajectory, business opportunities, relationship strength, and wellness cycles." },
                  { title: "Yoga Explanations", desc: "Examines 100+ standard yogas (such as Budhaditya or Gajakesari) present in your chart with active effects." },
                ].map((item, i) => (
                  <div key={i} className="rounded-2xl border border-gray-100 bg-[#FAFBFD] p-5">
                    <div className="flex items-center gap-2 mb-2 font-bold text-[#1E3C72]">
                      <span className="text-sm font-bold text-[#2A5298]">★</span>
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
          <div className="grid gap-8 xl:grid-cols-[400px_minmax(0,1fr)]">
            <aside className="rounded-[2.2rem] border border-[#EFE3D1] bg-white p-6 shadow-sm self-start">
              <h2 className="text-2xl font-bold">Birth Particulars</h2>
              <p className="mt-2 text-sm text-slate-500">
                Lal Kitab and detailed natal models require precise time and location details.
              </p>

              <form onSubmit={handleSubmit} className="mt-6 space-y-5">
                <div>
                  <label className="mb-2 block text-sm font-semibold text-slate-600">Full Name</label>
                  <input
                    type="text"
                    name="name"
                    value={form.name}
                    onChange={handleChange}
                    placeholder="Enter full name"
                    className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="mb-2 block text-sm font-semibold text-slate-600">Gender</label>
                    <select
                      name="gender"
                      value={form.gender}
                      onChange={handleChange}
                      className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                    >
                      <option value="Male">Male</option>
                      <option value="Female">Female</option>
                      <option value="Other">Other</option>
                    </select>
                  </div>
                  <div>
                    <label className="mb-2 block text-sm font-semibold text-slate-600">Chart Style</label>
                    <select
                      name="chart_style"
                      value={form.chart_style}
                      onChange={handleChange}
                      className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                    >
                      <option value="north-indian">North Indian</option>
                      <option value="south-indian">South Indian</option>
                      <option value="east-indian">East Indian</option>
                    </select>
                  </div>
                </div>

                <div>
                  <label className="mb-2 block text-sm font-semibold text-slate-600">Date of Birth</label>
                  <input
                    type="date"
                    name="date_of_birth"
                    value={form.date_of_birth}
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
                  className="w-full rounded-2xl bg-[#1E3C72] px-5 py-3.5 text-sm font-bold text-white transition hover:bg-[#162C54] disabled:opacity-60 flex items-center justify-center gap-2"
                >
                  {loading ? (
                    <>
                      <FaSpinner className="animate-spin" />
                      Generating Dossier...
                    </>
                  ) : (
                    "Compile Detailed Kundali"
                  )}
                </button>
              </form>
            </aside>

            <main className="space-y-6">
              {!reportData ? (
                <div className="rounded-[2.2rem] border border-[#EFE3D1] bg-white p-10 text-center shadow-sm">
                  <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-[#EEF4FC] border border-gray-100 text-[#1E3C72] mb-4">
                    <FaBookOpen />
                  </div>
                  <h2 className="text-xl font-bold">Ready to Generate Blueprint</h2>
                  <p className="mt-2 text-sm text-slate-500 max-w-md mx-auto leading-6">
                    Enter birth specifics and submit form. Our engine will fetch divisional chart blueprints, yogas, predictions, gemstones, and rudrakshas.
                  </p>
                </div>
              ) : (
                <div className="space-y-6 animate-fadeIn">
                  {/* Digital Dossier Tabs */}
                  <div className="flex flex-wrap gap-2 justify-start border-b border-slate-200 pb-3">
                    {[
                      { id: "birth", label: "Birth details", icon: "📝" },
                      { id: "charts", label: "Divisional Charts", icon: "📊" },
                      { id: "predictions", label: "Life Predictions", icon: "✨" },
                      { id: "dashas", label: "Vimshottari Dasha", icon: "🪐" },
                      { id: "remedies", label: "Gem & Rudraksha Suggestions", icon: "💎" },
                    ].map((t) => (
                      <button
                        key={t.id}
                        type="button"
                        onClick={() => setActiveDossierTab(t.id)}
                        className={`px-4 py-2 rounded-xl text-xs font-bold transition ${activeDossierTab === t.id ? "bg-[#1E3C72] text-white shadow-sm" : "bg-white text-gray-500 hover:bg-gray-100 border border-gray-200"}`}
                      >
                        <span className="mr-1.5">{t.icon}</span> {t.label}
                      </button>
                    ))}
                  </div>

                  {/* Birth Details Tab Content */}
                  {activeDossierTab === "birth" && (
                    <div className="rounded-[2.2rem] border border-[#EFE3D1] bg-white p-6 shadow-sm space-y-6">
                      <h3 className="text-lg font-bold text-[#1E3557]">Natal Coordinates & Planetary Positions</h3>
                      <div className="grid gap-4 sm:grid-cols-2">
                        {[
                          ["Native Name", form.name],
                          ["Birth Time", form.time_of_birth],
                          ["Birth Place", form.place_of_birth],
                          ["Astro Nakshatra", reportData.kundli?.nakshatra_details?.nakshatra?.name || "-"],
                          ["Rashi Lord", reportData.kundli?.nakshatra_details?.chandra_rasi?.lord?.name || "-"],
                          ["Sun Sign", reportData.kundli?.nakshatra_details?.soorya_rasi?.name || "-"],
                          ["Lagna / Ascendant", reportData.kundli?.nakshatra_details?.additional_info?.ascendant || "-"],
                        ].map(([k, v], i) => (
                          <div key={i} className="flex justify-between border-b border-gray-100 pb-2 text-xs">
                            <span className="font-semibold text-slate-500">{k}</span>
                            <span className="font-bold text-[#1E3557]">{v}</span>
                          </div>
                        ))}
                      </div>

                      {/* Positive Yogas present */}
                      {reportData.kundli?.yoga_details && reportData.kundli.yoga_details.length > 0 && (
                        <div className="mt-6 border-t border-gray-100 pt-6">
                          <h4 className="font-bold text-sm text-[#1E3557] mb-3">Positive Yogas Present In Chart:</h4>
                          <div className="grid gap-3">
                            {reportData.kundli.yoga_details.flatMap(g => g.yoga_list || []).filter(y => y.has_yoga).slice(0, 4).map((y, index) => (
                              <div key={index} className="rounded-xl bg-[#FAF9F6] border border-[#EFECE6] p-4 text-xs">
                                <p className="font-bold text-[#B05B35]">{y.name}</p>
                                <p className="mt-1 leading-5 text-gray-500">{y.description}</p>
                              </div>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>
                  )}

                  {/* Divisional Charts Tab Content */}
                  {activeDossierTab === "charts" && (
                    <div className="rounded-[2.2rem] border border-[#EFE3D1] bg-white p-6 shadow-sm space-y-6">
                      <div className="flex items-center justify-between gap-4 flex-wrap">
                        <h3 className="text-lg font-bold text-[#1E3557]">Divisional Charts Selector</h3>
                        <select
                          value={selectedChartType}
                          onChange={(e) => setSelectedChartType(e.target.value)}
                          className="rounded-xl border border-slate-200 bg-[#f8f9fc] px-4 py-2 text-xs outline-none font-bold"
                        >
                          {divisionalChartOptions.map((opt) => (
                            <option key={opt.value} value={opt.value}>{opt.label}</option>
                          ))}
                        </select>
                      </div>

                      <div className="flex min-h-[300px] items-center justify-center overflow-x-auto border border-gray-200 bg-[#fffbf0] rounded-2xl p-4 shadow-inner relative">
                        {loadingChart ? (
                          <div className="text-center"><FaSpinner className="animate-spin text-2xl text-[#1E3C72] mx-auto" /><p className="mt-2 text-xs text-gray-500 font-semibold">Generating Chart Layout...</p></div>
                        ) : loadedCharts[selectedChartType] ? (
                          <div dangerouslySetInnerHTML={{ __html: loadedCharts[selectedChartType] }} className="max-w-full" style={{ minWidth: "300px", minHeight: "300px" }} />
                        ) : (
                          <p className="text-xs text-gray-400">Loading Divisional chart...</p>
                        )}
                      </div>
                    </div>
                  )}

                  {/* Predictions Tab Content */}
                  {activeDossierTab === "predictions" && (
                    <div className="rounded-[2.2rem] border border-[#EFE3D1] bg-white p-6 shadow-sm space-y-6">
                      <div className="flex flex-wrap gap-2">
                        {[
                          { id: "career", label: "💼 Career" },
                          { id: "love-and-relationship", label: "❤️ Relationships" },
                          { id: "health", label: "💊 Health" },
                          { id: "finance", label: "💰 Wealth & Finance" },
                        ].map((area) => (
                          <button
                            key={area.id}
                            type="button"
                            onClick={() => setActivePredictionArea(area.id)}
                            className={`px-4 py-2 rounded-xl text-xs font-bold transition ${activePredictionArea === area.id ? "bg-[#1E3557] text-white" : "bg-[#f8f9fc] text-gray-500 hover:bg-gray-100"}`}
                          >
                            {area.label}
                          </button>
                        ))}
                      </div>

                      <div className="border-t border-gray-100 pt-4">
                        {reportData.predictions[activePredictionArea] ? (
                          <div className="space-y-4">
                            {reportData.predictions[activePredictionArea].provider_sections ? (
                              reportData.predictions[activePredictionArea].provider_sections.map((sect, sIndex) => (
                                <div key={sIndex} className="space-y-2">
                                  <h4 className="font-bold text-[#1E3557] text-sm">{sect.title}</h4>
                                  {Object.entries(sect.items || {}).map(([key, item], kIndex) => (
                                    <div key={kIndex} className="text-xs leading-6 text-gray-600 bg-slate-50 rounded-xl p-4 border border-gray-100">
                                      {item?.data ? String(item.data) : JSON.stringify(item)}
                                    </div>
                                  ))}
                                </div>
                              ))
                            ) : Array.isArray(reportData.predictions[activePredictionArea]) ? (
                               reportData.predictions[activePredictionArea].map((sect, sIndex) => (
                                 <div key={sIndex} className="space-y-2">
                                   <h4 className="font-bold text-[#1E3557] text-sm">{sect.title}</h4>
                                   <div className="text-xs leading-6 text-gray-600 bg-slate-50 rounded-xl p-4 border border-gray-100">
                                      {sect.description || "No description available."}
                                   </div>
                                 </div>
                               ))
                            ) : (
                              <p className="text-xs leading-6 text-gray-600">{JSON.stringify(reportData.predictions[activePredictionArea])}</p>
                            )}
                          </div>
                        ) : (
                          <div className="text-center py-6"><FaSpinner className="animate-spin text-[#1E3C72] mx-auto text-xl" /><p className="mt-2 text-xs text-gray-400">Loading Predictions...</p></div>
                        )}
                      </div>
                    </div>
                  )}

                  {/* Dashas Tab Content */}
                  {activeDossierTab === "dashas" && (
                    <div className="rounded-[2.2rem] border border-[#EFE3D1] bg-white p-6 shadow-sm space-y-6">
                      <h3 className="text-lg font-bold text-[#1E3557]">Maha Dasha & Transit Timelines</h3>
                      <p className="text-xs text-gray-400">The planetary timeline cycles active in your natal chart:</p>

                      <div className="overflow-x-auto rounded-2xl border border-gray-100">
                        <table className="w-full text-left text-xs border-collapse">
                          <thead>
                            <tr className="bg-slate-50 font-bold text-slate-700">
                              <th className="p-3 border-b border-gray-100">Lord / Planet</th>
                              <th className="p-3 border-b border-gray-100">Active Stage</th>
                              <th className="p-3 border-b border-gray-100">Start Date</th>
                              <th className="p-3 border-b border-gray-100">End Date</th>
                            </tr>
                          </thead>
                          <tbody>
                            {reportData.kundli?.dasha_summary?.current_mahadasha && (
                              <tr className="hover:bg-slate-50 border-b border-gray-50 text-gray-600 font-semibold">
                                <td className="p-3 font-extrabold text-[#1E3C72]">{reportData.kundli.dasha_summary.current_mahadasha.name}</td>
                                <td className="p-3 text-amber-600 font-bold">Current Maha Dasha</td>
                                <td className="p-3">{reportData.kundli.dasha_summary.current_mahadasha.start || "-"}</td>
                                <td className="p-3">{reportData.kundli.dasha_summary.current_mahadasha.end || "-"}</td>
                              </tr>
                            )}
                            {reportData.kundli?.dasha_summary?.current_antardasha && (
                              <tr className="hover:bg-slate-50 border-b border-gray-50 text-gray-600 font-semibold">
                                <td className="p-3 font-extrabold text-[#1E3C72]">{reportData.kundli.dasha_summary.current_antardasha.name}</td>
                                <td className="p-3 text-emerald-600 font-bold">Current Antar Dasha</td>
                                <td className="p-3">{reportData.kundli.dasha_summary.current_antardasha.start || "-"}</td>
                                <td className="p-3">{reportData.kundli.dasha_summary.current_antardasha.end || "-"}</td>
                              </tr>
                            )}
                            {reportData.kundli?.dasha_summary?.current_pratyantardasha && (
                              <tr className="hover:bg-slate-50 border-b border-gray-50 text-gray-600 font-semibold">
                                <td className="p-3 font-extrabold text-[#1E3C72]">{reportData.kundli.dasha_summary.current_pratyantardasha.name}</td>
                                <td className="p-3 text-blue-600 font-bold">Current Pratyantar Dasha</td>
                                <td className="p-3">{reportData.kundli.dasha_summary.current_pratyantardasha.start || "-"}</td>
                                <td className="p-3">{reportData.kundli.dasha_summary.current_pratyantardasha.end || "-"}</td>
                              </tr>
                            )}
                            {reportData.kundli?.dasha_summary?.next_mahadasha?.map((dasha, idx) => (
                              <tr key={idx} className="hover:bg-slate-50 border-b border-gray-50 text-gray-500">
                                <td className="p-3 font-semibold">{dasha.name}</td>
                                <td className="p-3">Upcoming Maha Dasha</td>
                                <td className="p-3">{dasha.start || "-"}</td>
                                <td className="p-3">{dasha.end || "-"}</td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    </div>
                  )}

                  {/* Gemstone / Rudraksha Tab Content */}
                  {activeDossierTab === "remedies" && (
                    <div className="space-y-6">
                      {/* Gemstone */}
                      <div className="rounded-[2.2rem] border border-[#EFE3D1] bg-white p-6 shadow-sm space-y-4">
                        <h3 className="text-lg font-bold text-[#1E3557]">✨ Gemstone Suggestions</h3>
                        <p className="text-xs text-gray-400">Wearing suitable gemstones strengthens beneficial planets in your horoscope:</p>

                        <div className="grid gap-4 md:grid-cols-2">
                          {reportData.gemstones?.provider_sections ? (
                            reportData.gemstones.provider_sections.slice(0, 3).map((sect, index) => (
                              <div key={index} className="rounded-2xl bg-slate-50 border border-gray-100 p-4 text-xs space-y-2">
                                <p className="font-bold text-[#1E3C72]">{sect.title}</p>
                                {Object.entries(sect.items || {}).map(([key, item], i) => (
                                  <div key={i} className="text-gray-500 leading-5 mt-2">
                                    <span className="font-bold uppercase text-[10px] text-[#B05B35] mr-1 border-b border-gray-100 block pb-1 mb-1">{key}:</span>
                                    {item?.data ? (
                                      typeof item.data === 'object' ? (
                                        <div className="grid gap-2 grid-cols-1">
                                          {Array.isArray(item.data) ? item.data.map((el, eIdx) => (
                                            <div key={eIdx} className="bg-white p-2 rounded-lg border border-gray-50">
                                              {typeof el === 'object' ? Object.entries(el).map(([k, v]) => <div key={k}><span className="font-semibold">{k}:</span> {String(v)}</div>) : String(el)}
                                            </div>
                                          )) : Object.entries(item.data).map(([k, v]) => (
                                            <div key={k} className="bg-white p-2 rounded-lg border border-gray-50 shadow-sm text-xs">
                                              <span className="font-bold text-gray-700 block mb-1">{k}</span>
                                              <div className="text-gray-600">{typeof v === 'object' ? Object.entries(v).map(([sk, sv]) => <div key={sk}><span className="font-medium text-gray-500">{sk}:</span> {String(sv)}</div>) : String(v)}</div>
                                            </div>
                                          ))}
                                        </div>
                                      ) : <span>{String(item.data)}</span>
                                    ) : <span>{JSON.stringify(item)}</span>}
                                  </div>
                                ))}
                              </div>
                            ))
                          ) : (
                            <p className="text-xs text-gray-500">Gemstone recommendations compiled successfully. Reach out to an astrologer for customized ring/pendant sizes.</p>
                          )}
                        </div>
                      </div>

                      {/* Rudraksha */}
                      <div className="rounded-[2.2rem] border border-[#EFE3D1] bg-white p-6 shadow-sm space-y-4">
                        <h3 className="text-lg font-bold text-[#1E3557]">📿 Rudraksha Suggestions</h3>
                        <p className="text-xs text-gray-400">Suitable Rudraksha beads counteract malefic energies and bring peace:</p>

                        {reportData.rudraksha?.provider_sections ? (
                          reportData.rudraksha.provider_sections.slice(0, 2).map((sect, index) => (
                            <div key={index} className="rounded-2xl bg-slate-50 border border-gray-100 p-4 text-xs space-y-2">
                              <p className="font-bold text-[#1E3C72]">{sect.title}</p>
                              {Object.entries(sect.items || {}).map(([key, item], i) => (
                                <div key={i} className="text-gray-500 leading-5 mt-2">
                                  <span className="font-bold uppercase text-[10px] text-[#B05B35] mr-1 border-b border-gray-100 block pb-1 mb-1">{key}:</span>
                                  {item?.data ? (
                                    typeof item.data === 'object' ? (
                                      <div className="grid gap-2 grid-cols-1">
                                        {Array.isArray(item.data) ? item.data.map((el, eIdx) => (
                                          <div key={eIdx} className="bg-white p-2 rounded-lg border border-gray-50">
                                            {typeof el === 'object' ? Object.entries(el).map(([k, v]) => <div key={k}><span className="font-semibold">{k}:</span> {String(v)}</div>) : String(el)}
                                          </div>
                                        )) : Object.entries(item.data).map(([k, v]) => (
                                          <div key={k} className="bg-white p-2 rounded-lg border border-gray-50 shadow-sm text-xs">
                                            <span className="font-bold text-gray-700 block mb-1">{k}</span>
                                            <div className="text-gray-600">{typeof v === 'object' ? Object.entries(v).map(([sk, sv]) => <div key={sk}><span className="font-medium text-gray-500">{sk}:</span> {String(sv)}</div>) : String(v)}</div>
                                          </div>
                                        ))}
                                      </div>
                                    ) : <span>{String(item.data)}</span>
                                  ) : <span>{JSON.stringify(item)}</span>}
                                </div>
                              ))}
                            </div>
                          ))
                        ) : (
                          <p className="text-xs text-gray-500">Rudraksha details derived. Counteracts negative planetary transits and enhances concentration.</p>
                        )}
                      </div>
                    </div>
                  )}
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
