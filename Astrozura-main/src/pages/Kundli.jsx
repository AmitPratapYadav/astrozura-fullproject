import React, { useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { FaCheckCircle, FaExclamationTriangle, FaInfoCircle, FaMoon, FaStar, FaSun } from "react-icons/fa";
import { 
  generateKundli, 
  searchLocation, 
  getDivisionalCharts, 
  getPredictions, 
  getNumerologyReport, 
  getSadesatiReport, 
  getLalKitabReport 
} from "../api/prokeralaApi";
import { useAuth } from "../context/AuthContext";
import {
  KUNDLI_LANGUAGE_OPTIONS,
  getLanguageLabel,
  getLocaleForLanguage,
} from "../constants/prokeralaLanguages";

const chartTypeOptions = [
  { value: "rasi", label: "D1 - Rasi Chart" },
  { value: "hora", label: "D2 - Hora Chart" },
  { value: "drekkana", label: "D3 - Drekkana Chart" },
  { value: "chaturthamsa", label: "D4 - Chaturthamsa Chart" },
  { value: "saptamsa", label: "D7 - Saptamsa Chart" },
  { value: "navamsa", label: "D9 - Navamsa Chart" },
  { value: "dasamsa", label: "D10 - Dasamsa Chart" },
  { value: "dwadasamsa", label: "D12 - Dwadasamsa Chart" },
  { value: "shodasamsa", label: "D16 - Shodasamsa Chart" },
  { value: "vimsamsa", label: "D20 - Vimsamsa Chart" },
  { value: "chaturvimsamsa", label: "D24 - Chaturvimsamsa Chart" },
  { value: "bhamsa", label: "D27 - Bhamsa Chart" },
  { value: "trimsamsa", label: "D30 - Trimsamsa Chart" },
  { value: "khavedamsa", label: "D40 - Khavedamsa Chart" },
  { value: "akshavedamsa", label: "D45 - Akshavedamsa Chart" },
  { value: "shastiamsa", label: "D60 - Shastiamsa Chart" },
];

const predictionTypes = [
  { value: "career", label: "Career & Business", icon: "💼" },
  { value: "love-and-relationship", label: "Love & Relationship", icon: "❤️" },
  { value: "health", label: "Health & Well-being", icon: "💊" },
  { value: "finance", label: "Money & Finance", icon: "💰" },
  { value: "education", label: "Education & Learning", icon: "🎓" },
];

const initialDetails = {
  name: "",
  dob: "",
  time: "",
  place: "",
  coordinates: "",
  gender: "Male",
  chartType: "rasi",
  chartStyle: "north-indian",
  language: "en",
};

const formatDateTime = (value, language = "en") => {
  if (!value) return "-";
  try {
    return new Date(value).toLocaleString(getLocaleForLanguage(language), {
      dateStyle: "medium",
      timeStyle: "short",
    });
  } catch {
    return value;
  }
};

const getRelevantSadesatiTransits = (transits) => {
  if (!Array.isArray(transits)) return [];

  const sorted = [...transits]
    .filter((item) => item?.start)
    .sort((left, right) => new Date(left.start).getTime() - new Date(right.start).getTime());

  const now = Date.now();
  const firstUpcomingIndex = sorted.findIndex((item) => new Date(item.start).getTime() >= now);

  if (firstUpcomingIndex === -1) {
    return sorted.slice(-8);
  }

  const startIndex = Math.max(0, firstUpcomingIndex - 2);
  return sorted.slice(startIndex, startIndex + 8);
};

export default function Kundli() {
  const { user } = useAuth();
  const [searchParams] = useSearchParams();
  const [details, setDetails] = useState(initialDetails);
  const [showMsg, setShowMsg] = useState("");
  const [locationResults, setLocationResults] = useState([]);
  const [loadingKundli, setLoadingKundli] = useState(false);
  const [loadingLocation, setLoadingLocation] = useState(false);
  const [kundliData, setKundliData] = useState(null);
  const [chartData, setChartData] = useState(null);
  const [apiMeta, setApiMeta] = useState(null);

  // Premium Features States
  const [activeTab, setActiveTab] = useState("free"); // free, premium
  const [premiumTab, setPremiumTab] = useState("charts"); // charts, predictions, numerology, etc.
  const [loadingPremium, setLoadingPremium] = useState(false);
  const [premiumData, setPremiumData] = useState({});
  const [activeChartType, setActiveChartType] = useState("rasi");
  const [activePredictionType, setActivePredictionType] = useState("career");

  const isPaid = user?.subscription_status === "active" || user?.plan_name?.toLowerCase().includes("premium");
  const requestedPremiumTab = searchParams.get("premiumTab");

  useEffect(() => {
    if (!user) return;
    const coordinates = user.latitude != null && user.longitude != null ? `${user.latitude},${user.longitude}` : "";
    setDetails((prev) => ({
      ...prev,
      name: user.name || prev.name,
      dob: user.date_of_birth || prev.dob,
      time: user.time_of_birth || prev.time,
      place: user.place_of_birth || prev.place,
      coordinates: coordinates || prev.coordinates,
      gender: user.gender || prev.gender,
    }));
  }, [user]);

  useEffect(() => {
    const allowedPremiumTabs = new Set(["charts", "predictions", "numerology", "sadesati", "lalkitab"]);
    if (!requestedPremiumTab || !allowedPremiumTabs.has(requestedPremiumTab)) {
      return;
    }

    setActiveTab("premium");
    setPremiumTab(requestedPremiumTab);
  }, [requestedPremiumTab]);

  const showToast = (text) => {
    setShowMsg(text);
    window.clearTimeout(window.__astrozuraKundliToast);
    window.__astrozuraKundliToast = window.setTimeout(() => setShowMsg(""), 3500);
  };

  const updateDetails = (field, value) => setDetails((prev) => ({ ...prev, [field]: value }));

  const handleLocationChange = async (event) => {
    const query = event.target.value;
    setDetails((prev) => ({ ...prev, place: query, coordinates: "" }));
    if (query.trim().length < 3) return setLocationResults([]);
    try {
      setLoadingLocation(true);
      const response = await searchLocation(query.trim(), details.language);
      setLocationResults(response?.data || []);
    } catch {
      setLocationResults([]);
    } finally {
      setLoadingLocation(false);
    }
  };

  const selectLocation = (place) => {
    setDetails((prev) => ({ ...prev, place: place.name, coordinates: `${place.coordinates.latitude},${place.coordinates.longitude}` }));
    setLocationResults([]);
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    if (!details.coordinates) return showToast("Select a valid birthplace from the dropdown.");
    try {
      setLoadingKundli(true);
      setApiMeta(null);
      setKundliData(null);
      setChartData(null);
      showToast("Generating your kundli...");
      const datetime = `${details.dob}T${details.time}:00+05:30`;
      const response = await generateKundli(datetime, details.coordinates, 1, {
        chart_type: details.chartType,
        chart_style: details.chartStyle,
        la: details.language,
      });
      if (response?.status === "success" && response?.data?.kundli) {
        setKundliData(response.data.kundli);
        setChartData(response.data.chart || null);
        setApiMeta({
          requestedDatetime: response.data.requested_datetime,
          effectiveDatetime: response.data.effective_datetime,
          warning: response.data.warning,
          chartMeta: response.data.chart_meta,
          dashaSummary: response.data.dasha_summary || {},
          language: response.data.language || details.language,
          supportedLanguages: response.data.supported_languages || [],
        });
        setPremiumData({}); // Reset premium data on new search
        setActiveTab("free"); // Default to free view
        return showToast("Kundli generated successfully.");
      }
      showToast(response?.message || "Failed to generate kundli.");
    } catch (error) {
      showToast(error?.response?.data?.message || "Failed to connect to API.");
    } finally {
      setLoadingKundli(false);
    }
  };

  const loadPremiumFeature = async (type, force = false) => {
    if (!isPaid) return;
    if (premiumData[type] && !force) return;

    try {
      setLoadingPremium(true);
      const datetime = `${details.dob}T${details.time}:00+05:30`;
      let res;
      
      switch (type) {
        case "charts":
          res = await getDivisionalCharts(datetime, details.coordinates, activeChartType, details.chartStyle);
          break;
        case "predictions":
          res = await getPredictions(datetime, details.coordinates, activePredictionType);
          break;
        case "numerology":
          {
            const nameParts = String(details.name || "").trim().split(/\s+/).filter(Boolean);
            const firstName = nameParts[0] || "";
            const lastName = nameParts.length > 1 ? nameParts[nameParts.length - 1] : "";
            const middleName = nameParts.length > 2 ? nameParts.slice(1, -1).join(" ") : "";

            res = await getNumerologyReport({
              calculator: "maturity-number",
              system: "pythagorean",
              date_of_birth: details.dob,
              first_name: firstName,
              middle_name: middleName,
              last_name: lastName,
            });
          }
          break;
        case "sadesati":
          res = await getSadesatiReport(datetime, details.coordinates);
          break;
        case "lalkitab":
          res = await getLalKitabReport(datetime, details.coordinates);
          break;
        default: break;
      }

      if (res?.status === "success") {
        setPremiumData(prev => ({ ...prev, [type]: res.data }));
      }
    } catch (error) {
      showToast("Failed to load premium data.");
    } finally {
      setLoadingPremium(false);
    }
  };

  useEffect(() => {
    if (activeTab === "premium" && kundliData) {
      loadPremiumFeature(premiumTab);
    }
  }, [activeTab, premiumTab, activeChartType, activePredictionType]);

  const birth = kundliData?.nakshatra_details;
  const info = birth?.additional_info || {};
  const dosha = kundliData?.mangal_dosha;
  const dasha = apiMeta?.dashaSummary || {};
  const activeLanguage = apiMeta?.language || details.language;
  const yogas = Array.isArray(kundliData?.yoga_details) ? kundliData.yoga_details : [];
  const activeYogas = yogas.flatMap((group) => (group.yoga_list || []).filter((item) => item.has_yoga).map((item) => ({ ...item, group: group.name })));
  const visibleSadesatiTransits = getRelevantSadesatiTransits(premiumData.sadesati?.transits || []);
  const profileItems = [
    ["Nakshatra", birth?.nakshatra?.name], ["Pada", birth?.nakshatra?.pada], ["Nakshatra Lord", birth?.nakshatra?.lord?.name],
    ["Moon Sign", birth?.chandra_rasi?.name], ["Sun Sign", birth?.soorya_rasi?.name], ["Zodiac", birth?.zodiac?.name],
    ["Birth Stone", info.birth_stone], ["Ganam", info.ganam], ["Nadi", info.nadi], ["Animal Sign", info.animal_sign], ["Syllables", info.syllables], ["Best Direction", info.best_direction],
  ];

  return (
    <div className="bg-[#f8f9fa] min-h-screen flex flex-col font-sans">
      {showMsg && <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-xl bg-[#1E3557] px-6 py-3 text-sm font-medium text-white shadow-lg">{showMsg}</div>}
      <Navbar />
      <section className="relative bg-[#1E3557] text-white overflow-hidden py-24 md:py-32">
        <div className="absolute inset-0 opacity-10" style={{ backgroundImage: "radial-gradient(#D4A73C 1px, transparent 1px)", backgroundSize: "30px 30px" }}></div>
        <div className="relative max-w-7xl mx-auto px-4 md:px-8 text-center">
          <span className="inline-block text-xs bg-[#D4A73C]/20 text-[#D4A73C] border border-[#D4A73C]/30 px-4 py-1.5 rounded-full font-bold tracking-widest uppercase mb-6 shadow-sm">Free Janam Kundali</span>
          <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-extrabold mb-6 leading-tight">Create Your <span className="text-[#D4A73C]">Free Kundli</span></h1>
          <p className="text-gray-300 max-w-2xl mx-auto text-lg md:text-xl leading-relaxed">Build your Vedic birth chart, then review yogas, dosha details, and dasha timing.</p>
        </div>
      </section>

      <section className="max-w-5xl mx-auto px-4 md:px-8 py-12 -mt-10 sm:-mt-16 z-10 relative">
        <form onSubmit={handleSubmit} className="bg-white rounded-3xl shadow-xl border border-gray-100 p-6 sm:p-8 md:p-12">
          <div className="text-center mb-10">
            <h2 className="text-2xl sm:text-3xl font-bold text-[#1E3557]">Birth Chart Details</h2>
            <p className="text-gray-500 mt-2 text-sm">The advanced view includes detailed yogas, dosha notes, and dasha timing.</p>
            <p className="mt-3 text-xs font-medium text-gray-500">Result language: {getLanguageLabel(details.language)}</p>
          </div>
          <div className="grid md:grid-cols-2 gap-6">
            <input required type="text" value={details.name} onChange={(e) => updateDetails("name", e.target.value)} placeholder="Full Name" className="w-full bg-gray-50 border border-gray-200 px-4 py-3 rounded-xl" />
            <select value={details.gender} onChange={(e) => updateDetails("gender", e.target.value)} className="w-full bg-gray-50 border border-gray-200 px-4 py-3 rounded-xl"><option value="Male">Male</option><option value="Female">Female</option><option value="Other">Other</option></select>
            <input required type="date" value={details.dob} onChange={(e) => updateDetails("dob", e.target.value)} className="w-full bg-gray-50 border border-gray-200 px-4 py-3 rounded-xl" />
            <input required type="time" value={details.time} onChange={(e) => updateDetails("time", e.target.value)} className="w-full bg-gray-50 border border-gray-200 px-4 py-3 rounded-xl" />
            <select value={details.language} onChange={(e) => updateDetails("language", e.target.value)} className="w-full bg-gray-50 border border-gray-200 px-4 py-3 rounded-xl">
              {KUNDLI_LANGUAGE_OPTIONS.map((item) => <option key={item.value} value={item.value}>{item.label}</option>)}
            </select>
            <div className="rounded-xl border border-dashed border-gray-200 bg-gray-50 px-4 py-3 text-sm text-gray-500">
              Kundli translations depend on the modules returned by Astrology API for the selected locale.
            </div>
            <div className="relative md:col-span-2">
              <input required type="text" value={details.place} onChange={handleLocationChange} placeholder="Birth Place (select from dropdown)" className="w-full bg-gray-50 border border-gray-200 px-4 py-3 rounded-xl pr-10" />
              {loadingLocation && <div className="absolute right-3 top-3.5 h-4 w-4 animate-spin rounded-full border-b-2 border-orange-500"></div>}
              {locationResults.length > 0 && (
                <div className="absolute z-50 w-full mt-1 bg-white border border-gray-200 rounded-xl shadow-xl max-h-60 overflow-y-auto">
                  {locationResults.map((place, index) => (
                    <button key={`${place.name}-${index}`} type="button" className="block w-full border-b border-gray-50 px-4 py-2 text-left text-sm hover:bg-gray-100 last:border-0" onClick={() => selectLocation(place)}>
                      {place.name}
                    </button>
                  ))}
                </div>
              )}
              {details.coordinates && <p className="mt-2 text-xs text-gray-500">Coordinates: {details.coordinates}</p>}
            </div>
            <select value={details.chartType} onChange={(e) => updateDetails("chartType", e.target.value)} className="w-full bg-gray-50 border border-gray-200 px-4 py-3 rounded-xl">{chartTypeOptions.slice(0, 3).map((item) => <option key={item.value} value={item.value}>{item.label}</option>)}</select>
            <select value={details.chartStyle} onChange={(e) => updateDetails("chartStyle", e.target.value)} className="w-full bg-gray-50 border border-gray-200 px-4 py-3 rounded-xl">
              <option value="north-indian">North Indian</option>
              <option value="south-indian">South Indian</option>
              <option value="east-indian">East Indian</option>
            </select>
          </div>
          <div className="mt-12 text-center pt-8 border-t border-gray-100">
            <button disabled={loadingKundli} type="submit" className="bg-[#1E3557] text-white px-12 py-4 rounded-xl font-bold text-lg hover:bg-[#162744] transition-all w-full md:w-auto disabled:opacity-50">{loadingKundli ? "Generating..." : "Generate Kundli"}</button>
          </div>

          <div className="mt-16 pt-10 border-t border-gray-100">
            <h3 className="text-xl sm:text-2xl font-bold text-center text-[#1E3557] mb-8">What You Will Discover Inside Your Kundali</h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-y-4 gap-x-6 max-w-4xl mx-auto px-4">
                {[ 
                    "Birth Details", "Astro Details", "All charts / Lagna", "Planetary Positions", "Up grah", 
                    "Jaimini Details", "Dasham Bhava Madhya", "Astak varga", "Sarvastak", "Friendship table for Planet", 
                    "Numerology / Favourable points", "Vimshottari Dasha", "Char Dasha", "Yogini Dasha", "All Dosha (Kaalsarpa, Mangal, Pitra)", 
                    "Sade Sati Report", "Rashiphal", "Remedy", "Gemstone", "Shadbala" 
                ].map((ft, i) => (
                    <div key={i} className="flex items-center gap-3">
                        <div className="w-5 h-5 rounded-full bg-[#FAF7F2] flex items-center justify-center text-[#D4A73C] shrink-0 border border-[#EEE7D6] text-xs">✓</div>
                        <span className="text-sm font-medium text-gray-600">{ft}</span>
                    </div>
                ))}
            </div>
          </div>

          {kundliData && (
            <div className="mt-12 pt-12 border-t border-gray-100 space-y-8">
              {apiMeta?.warning && <div className="rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900"><div className="flex gap-3"><FaInfoCircle className="mt-0.5" /><div><p className="font-semibold">Upstream sandbox restriction detected</p><p className="mt-1">{apiMeta.warning}</p><p className="mt-2 text-xs">Requested datetime: {apiMeta.requestedDatetime}</p><p className="text-xs">Effective datetime: {apiMeta.effectiveDatetime}</p></div></div></div>}

              <div className="flex justify-center mb-8 bg-gray-100 p-1.5 rounded-2xl w-fit mx-auto shadow-sm">
                <button type="button" onClick={() => setActiveTab("free")} className={`px-8 py-2.5 rounded-xl font-bold transition-all ${activeTab === "free" ? "bg-white text-[#1E3557] shadow-md" : "text-gray-500 hover:text-[#1E3557]"}`}>Free Report</button>
                <button type="button" onClick={() => setActiveTab("premium")} className={`px-8 py-2.5 rounded-xl font-bold transition-all flex items-center gap-2 ${activeTab === "premium" ? "bg-white text-[#D4A73C] shadow-md" : "text-gray-500 hover:text-[#D4A73C]"}`}>
                  <FaStar className={activeTab === "premium" ? "text-[#D4A73C]" : "text-gray-300"} /> Premium Report
                </button>
              </div>

              {activeTab === "free" ? (
                <>
                  <div className="text-center">
                    <h3 className="text-2xl font-bold text-[#1E3557]">Your Kundli Results</h3>
                    <p className="mt-2 text-sm text-gray-500">Chart: {apiMeta?.chartMeta?.chart_type || details.chartType} in {apiMeta?.chartMeta?.chart_style || details.chartStyle} style</p>
                    <p className="mt-1 text-xs font-medium uppercase tracking-wide text-gray-400">Locale: {getLanguageLabel(activeLanguage)}</p>
                  </div>

                  <div className="grid xl:grid-cols-[1.1fr_0.9fr] gap-8">
                    <div className="rounded-2xl border border-gray-100 bg-[#f8f9fa] p-4">
                      <div className="mb-4"><p className="text-lg font-bold text-[#1E3557]">Birth Chart</p></div>
                      <div className="flex min-h-[340px] items-center justify-center overflow-x-auto rounded-2xl border border-gray-200 bg-white p-4">
                        {chartData ? <div dangerouslySetInnerHTML={{ __html: chartData }} className="max-w-full" style={{ minWidth: "300px", minHeight: "300px" }} /> : <p className="text-sm text-gray-500 text-center">Chart image is not available for this response.</p>}
                      </div>
                    </div>

                    <div className="space-y-4">
                      <div className="grid sm:grid-cols-2 gap-4">
                        <div className="rounded-2xl border border-gray-100 bg-white p-5"><p className="text-xs font-semibold uppercase tracking-wide text-gray-500">Moon Sign</p><p className="mt-2 text-xl font-bold text-[#1E3557]">{birth?.chandra_rasi?.name || "-"}</p><p className="mt-1 text-sm text-gray-500">Lord: {birth?.chandra_rasi?.lord?.name || "-"}</p></div>
                        <div className="rounded-2xl border border-gray-100 bg-white p-5"><p className="text-xs font-semibold uppercase tracking-wide text-gray-500">Sun Sign</p><p className="mt-2 text-xl font-bold text-[#1E3557]">{birth?.soorya_rasi?.name || "-"}</p><p className="mt-1 text-sm text-gray-500">Zodiac: {birth?.zodiac?.name || "-"}</p></div>
                        <div className="rounded-2xl border border-gray-100 bg-white p-5"><p className="text-xs font-semibold uppercase tracking-wide text-gray-500">Current Maha Dasha</p><p className="mt-2 text-xl font-bold text-[#1E3557]">{dasha.current_mahadasha?.name || kundliData?.dasha_balance?.lord?.name || "-"}</p><p className="mt-1 text-sm text-gray-500">{kundliData?.dasha_balance?.description || "Dasha balance not available."}</p></div>
                        <div className="rounded-2xl border border-gray-100 bg-white p-5"><p className="text-xs font-semibold uppercase tracking-wide text-gray-500">Active Yogas</p><p className="mt-2 text-xl font-bold text-[#1E3557]">{activeYogas.length}</p><p className="mt-1 text-sm text-gray-500">Detailed list shown below</p></div>
                      </div>
                      <div className="rounded-2xl border border-gray-100 bg-white p-5">
                        <div className="flex items-center gap-2">{dosha?.has_dosha ? <FaExclamationTriangle className="text-orange-500" /> : <FaCheckCircle className="text-emerald-500" />}<h4 className="font-bold text-[#1E3557] text-lg">Mangal Dosha Summary</h4></div>
                        <p className={`mt-3 text-sm font-semibold ${dosha?.has_dosha ? "text-orange-700" : "text-emerald-700"}`}>{dosha?.type ? `${dosha.type} Manglik` : dosha?.has_dosha ? "Manglik" : "No Mangal Dosha"}</p>
                        <p className="mt-2 text-sm text-gray-600">{dosha?.description || "No dosha details returned."}</p>
                        {Array.isArray(dosha?.exceptions) && dosha.exceptions.length > 0 && <div className="mt-4 rounded-xl bg-orange-50 p-4"><p className="font-semibold text-orange-900">Dosha Exceptions</p><ul className="mt-2 space-y-2 text-sm text-orange-800">{dosha.exceptions.slice(0, 3).map((item, index) => <li key={`${item}-${index}`}>{item}</li>)}</ul></div>}
                      </div>
                    </div>
                  </div>

                  <div className="rounded-3xl border border-gray-100 bg-white p-6 shadow-sm">
                    <h4 className="text-xl font-bold text-[#1E3557] mb-5">Birth Profile Snapshot</h4>
                    <div className="grid md:grid-cols-2 xl:grid-cols-3 gap-4">{profileItems.map(([label, value]) => <div key={label} className="rounded-2xl border border-gray-100 bg-[#f8f9fa] p-4"><p className="text-xs font-semibold uppercase tracking-wide text-gray-500">{label}</p><p className="mt-2 text-base font-semibold text-[#1E3557]">{value || "-"}</p></div>)}</div>
                  </div>

                  <div className="grid lg:grid-cols-2 gap-8">
                    <div className="rounded-3xl border border-gray-100 bg-white p-6 shadow-sm">
                      <h4 className="text-xl font-bold text-[#1E3557] mb-5">Yoga Details</h4>
                      <div className="space-y-4">{yogas.map((group) => { const active = (group.yoga_list || []).filter((item) => item.has_yoga); return <div key={group.name} className="rounded-2xl border border-gray-100 bg-[#f8f9fa] p-4"><div className="flex items-start justify-between gap-4"><div><p className="font-semibold text-[#1E3557]">{group.name}</p><p className="mt-1 text-sm text-gray-500">{group.description}</p></div><span className="rounded-full bg-white px-3 py-1 text-xs font-semibold text-[#1E3557] shadow-sm">{active.length} active</span></div><div className="mt-4 space-y-3">{active.length > 0 ? active.map((item) => <div key={`${group.name}-${item.name}`} className="rounded-xl bg-white p-3 border border-gray-100"><p className="font-semibold text-[#1E3557]">{item.name}</p><p className="mt-1 text-sm text-gray-600">{item.description}</p></div>) : <p className="text-sm text-gray-500">No active yoga from this category in the current response.</p>}</div></div>; })}</div>
                    </div>

                    <div className="space-y-8">
                      <div className="rounded-3xl border border-gray-100 bg-white p-6 shadow-sm">
                        <h4 className="text-xl font-bold text-[#1E3557] mb-5">Dasha Timing</h4>
                        <div className="space-y-4">
                          {[["Current Maha Dasha", dasha.current_mahadasha], ["Current Antar Dasha", dasha.current_antardasha], ["Current Pratyantar Dasha", dasha.current_pratyantardasha]].map(([label, value]) => <div key={label} className="rounded-2xl bg-[#f8f9fa] p-4 border border-gray-100"><p className="text-xs font-semibold uppercase tracking-wide text-gray-500">{label}</p><p className="mt-2 text-lg font-bold text-[#1E3557]">{value?.name || "-"}</p><p className="mt-1 text-sm text-gray-500">{formatDateTime(value?.start, activeLanguage)} to {formatDateTime(value?.end, activeLanguage)}</p></div>)}
                        </div>
                        {Array.isArray(dasha.next_mahadasha) && dasha.next_mahadasha.length > 0 && <div className="mt-6"><p className="font-semibold text-[#1E3557] mb-3">Upcoming Maha Dashas</p><div className="space-y-3">{dasha.next_mahadasha.map((period) => <div key={`${period.name}-${period.start}`} className="rounded-xl border border-gray-100 bg-[#f8f9fa] p-3"><div className="flex items-center justify-between gap-4"><p className="font-semibold text-[#1E3557]">{period.name}</p><p className="text-xs text-gray-500">{formatDateTime(period.start, activeLanguage)}</p></div></div>)}</div></div>}
                      </div>
                      {Array.isArray(dosha?.remedies) && dosha.remedies.length > 0 && <div className="rounded-3xl border border-gray-100 bg-white p-6 shadow-sm"><h4 className="text-xl font-bold text-[#1E3557] mb-5">Suggested Remedies</h4><ul className="space-y-3 text-sm text-gray-600">{dosha.remedies.slice(0, 6).map((item, index) => <li key={`${item}-${index}`} className="rounded-xl bg-[#f8f9fa] p-4 border border-gray-100">{item}</li>)}</ul></div>}
                    </div>
                  </div>
                </>
              ) : (
                <div className="space-y-8 animate-fadeIn">
                  {!isPaid ? (
                    <div className="rounded-3xl border-2 border-dashed border-gray-200 bg-gray-50 p-12 text-center pointer-events-none opacity-80">
                      <div className="w-20 h-20 bg-white rounded-2xl shadow-sm flex items-center justify-center mb-6 mx-auto border border-gray-100">
                        <FaStar className="text-[#D4A73C] text-4xl animate-pulse" />
                      </div>
                      <h3 className="text-2xl font-bold text-[#1E3557]">Premium Reports are Locked</h3>
                      <p className="text-gray-500 mt-4 max-w-md mx-auto">Get full access to D1-D60 charts, detailed life predictions, Sadesati reports, and Vedic remedies.</p>
                      <button type="button" onClick={() => window.location.href='/subscriptions'} className="mt-8 bg-[#D4A73C] text-white px-10 py-3.5 rounded-xl font-bold shadow-lg shadow-[#D4A73C]/20 pointer-events-auto hover:scale-105 transition-transform">Unlock All Premium Features</button>
                    </div>
                  ) : (
                    <>
                      {/* Premium Tabs Secondary */}
                      <div className="flex flex-wrap gap-2 justify-center border-b border-gray-100 pb-4">
                        {[
                          { id: "charts", label: "Divisional Charts", icon: "📊" },
                          { id: "predictions", label: "Detailed Predictions", icon: "✨" },
                          { id: "numerology", label: "Numerology", icon: "🔢" },
                          { id: "sadesati", label: "Sadesati Report", icon: "🪐" },
                          { id: "lalkitab", label: "Lal Kitab", icon: "📕" },
                        ].map((t) => (
                          <button key={t.id} type="button" onClick={() => setPremiumTab(t.id)} className={`px-5 py-2 rounded-xl text-sm font-bold transition-all ${premiumTab === t.id ? "bg-[#1E3557] text-white shadow-md" : "bg-white text-gray-500 hover:bg-gray-50 border border-gray-100"}`}>
                            <span className="mr-2">{t.icon}</span> {t.label}
                          </button>
                        ))}
                      </div>

                      {loadingPremium ? (
                        <div className="py-20 text-center"><div className="h-10 w-10 animate-spin rounded-full border-b-2 border-[#1E3557] mx-auto"></div><p className="mt-4 text-gray-500 font-medium">Fetching premium astrological data...</p></div>
                      ) : (
                        <div className="min-h-[400px]">
                          {premiumTab === "charts" && (
                            <div className="space-y-6">
                              <div className="flex items-center justify-between gap-4 flex-wrap">
                                <h4 className="text-xl font-bold text-[#1E3557]">Divisional Charts (Varga)</h4>
                                <select value={activeChartType} onChange={(e) => setActiveChartType(e.target.value)} className="bg-gray-50 border border-gray-200 px-4 py-2 rounded-xl text-sm font-bold">
                                  {chartTypeOptions.map(opt => <option key={opt.value} value={opt.value}>{opt.label}</option>)}
                                </select>
                              </div>
                              <div className="flex items-center justify-center p-8 bg-white rounded-3xl border border-gray-100 shadow-sm min-h-[400px]">
                                {premiumData.charts ? <div dangerouslySetInnerHTML={{ __html: premiumData.charts }} className="max-w-full" /> : <p className="text-gray-400">Select a chart type to display.</p>}
                              </div>
                            </div>
                          )}

                          {premiumTab === "predictions" && (
                            <div className="space-y-6">
                              <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
                                {predictionTypes.map(p => (
                                  <button key={p.value} type="button" onClick={() => setActivePredictionType(p.value)} className={`p-4 rounded-2xl text-center border transition-all ${activePredictionType === p.value ? "bg-[#1E3557] border-[#1E3557] text-white shadow-lg" : "bg-white border-gray-100 text-gray-600 hover:border-gray-200"}`}>
                                    <div className="text-2xl mb-2">{p.icon}</div>
                                    <div className="text-xs font-bold leading-tight">{p.label.split(' ')[0]}</div>
                                  </button>
                                ))}
                              </div>
                              <div className="bg-white rounded-3xl border border-gray-100 p-8 shadow-sm">
                                <h4 className="text-xl font-bold text-[#1E3557] mb-4">{predictionTypes.find(p => p.value === activePredictionType)?.label} Prediction</h4>
                                {premiumData.predictions ? (
                                  <div className="space-y-4">
                                    {Array.isArray(premiumData.predictions) ? premiumData.predictions.map((item, i) => (
                                      <div key={i} className="p-4 rounded-2xl bg-gray-50 border border-gray-100">
                                        <p className="font-bold text-[#1E3557]">{item.title || "Observation"}</p>
                                        <p className="mt-2 text-gray-600 leading-relaxed text-sm">{item.description || item}</p>
                                      </div>
                                    )) : <p className="text-gray-600 leading-relaxed">{String(premiumData.predictions)}</p>}
                                  </div>
                                ) : <p className="text-gray-400">No prediction data available.</p>}
                              </div>
                            </div>
                          )}

                          {premiumTab === "numerology" && (
                            <div className="bg-white rounded-3xl border border-gray-100 p-8 shadow-sm space-y-6">
                              <h4 className="text-xl font-bold text-[#1E3557]">Numerology Report for {details.name}</h4>
                              {premiumData.numerology ? (
                                <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
                                  {Object.entries(premiumData.numerology).map(([key, value]) => (
                                    <div key={key} className="p-5 rounded-2xl bg-gray-50 border border-gray-100 hover:shadow-md transition-shadow">
                                      <p className="text-xs font-bold uppercase tracking-wider text-gray-400">{key.replace(/_/g, ' ')}</p>
                                      <p className="mt-2 text-2xl font-black text-[#1E3557]">{typeof value === 'object' ? value.value || value.name : value}</p>
                                      {typeof value === 'object' && value.description && <p className="mt-3 text-xs text-gray-500 leading-relaxed">{value.description}</p>}
                                    </div>
                                  ))}
                                </div>
                              ) : <p className="text-gray-400">No numerology data available.</p>}
                            </div>
                          )}

                          {premiumTab === "sadesati" && (
                            <div className="bg-white rounded-3xl border border-gray-100 p-8 shadow-sm space-y-6">
                              <div className="flex items-center gap-3"><FaMoon className="text-[#1E3557] text-xl" /><h4 className="text-xl font-bold text-[#1E3557]">Shani Sadesati Analysis</h4></div>
                              {premiumData.sadesati ? (
                                <div className="space-y-6">
                                  <div className={`p-6 rounded-2xl border ${premiumData.sadesati.is_sadesati_active ? "bg-orange-50 border-orange-100" : "bg-emerald-50 border-emerald-100"}`}>
                                    <p className={`font-bold text-lg ${premiumData.sadesati.is_sadesati_active ? "text-orange-900" : "text-emerald-900"}`}>{premiumData.sadesati.is_sadesati_active ? "Sadesati is currently Active" : "No Sadesati Active at present"}</p>
                                    <p className="mt-2 text-sm text-gray-600">{premiumData.sadesati.description}</p>
                                  </div>
                                  {premiumData.sadesati.transits && (
                                    <div className="space-y-3">
                                      <p className="font-bold text-[#1E3557]">Relevant Sadesati Phase Changes</p>
                                      <p className="text-sm text-gray-500">Showing the most relevant recent and upcoming phase changes instead of the full lifetime transit log.</p>
                                      <div className="grid gap-3 max-h-[32rem] overflow-y-auto pr-1">
                                        {visibleSadesatiTransits.map((t, i) => (
                                          <div key={i} className="p-4 rounded-xl border border-gray-100 flex justify-between items-center text-sm">
                                            <span className="font-bold text-[#1E3557]">{t.phase || t.name}</span>
                                            <span className="text-gray-500">{formatDateTime(t.start, activeLanguage)} to {formatDateTime(t.end, activeLanguage)}</span>
                                          </div>
                                        ))}
                                      </div>
                                    </div>
                                  )}
                                </div>
                              ) : <p className="text-gray-400">No sadesati data available.</p>}
                            </div>
                          )}

                          {premiumTab === "lalkitab" && (
                            <div className="bg-white rounded-3xl border border-gray-100 p-8 shadow-sm space-y-6">
                              <div className="flex items-center gap-3"><FaStar className="text-[#D4A73C] text-xl" /><h4 className="text-xl font-bold text-[#1E3557]">Lal Kitab Remedies</h4></div>
                              {premiumData.lalkitab ? (
                                <div className="space-y-4">
                                  {Array.isArray(premiumData.lalkitab.remedies) ? premiumData.lalkitab.remedies.map((r, i) => (
                                    <div key={i} className="p-5 rounded-2xl bg-gray-50 border border-gray-100 flex gap-4">
                                      <div className="w-8 h-8 bg-white rounded-lg flex items-center justify-center shrink-0 shadow-sm font-bold text-[#D4A73C]">{i + 1}</div>
                                      <p className="text-gray-600 text-sm leading-relaxed">{r}</p>
                                    </div>
                                  )) : <p className="text-gray-400">No Lal Kitab remedies available.</p>}

                                  {Array.isArray(premiumData.lalkitab.planets) && premiumData.lalkitab.planets.length > 0 && (
                                    <div className="rounded-2xl border border-gray-100 bg-[#f8f9fa] p-5">
                                      <h5 className="text-lg font-bold text-[#1E3557]">Planet Positions</h5>
                                      <div className="mt-4 grid gap-3 md:grid-cols-2">
                                        {premiumData.lalkitab.planets.map((planet) => (
                                          <div key={planet.planet} className="rounded-xl border border-gray-100 bg-white p-4">
                                            <p className="font-bold text-[#1E3557]">{planet.planet}</p>
                                            <p className="mt-2 text-sm text-gray-600">Rashi: {planet.rashi || "-"}</p>
                                            <p className="mt-1 text-sm text-gray-600">Nature: {planet.nature || "-"}</p>
                                            <p className="mt-1 text-sm text-gray-600">Position: {planet.position || "-"}</p>
                                          </div>
                                        ))}
                                      </div>
                                    </div>
                                  )}

                                  {Array.isArray(premiumData.lalkitab.houses) && premiumData.lalkitab.houses.length > 0 && (
                                    <div className="rounded-2xl border border-gray-100 bg-[#f8f9fa] p-5">
                                      <h5 className="text-lg font-bold text-[#1E3557]">House Summary</h5>
                                      <div className="mt-4 grid gap-3 md:grid-cols-2">
                                        {premiumData.lalkitab.houses.map((house) => (
                                          <div key={house.khana_number} className="rounded-xl border border-gray-100 bg-white p-4">
                                            <p className="font-bold text-[#1E3557]">House {house.khana_number}</p>
                                            <p className="mt-2 text-sm text-gray-600">Maalik: {house.maalik || "-"}</p>
                                            <p className="mt-1 text-sm text-gray-600">Pakka Ghar: {house.pakka_ghar || "-"}</p>
                                            <p className="mt-1 text-sm text-gray-600">Kismat: {house.kismat || "-"}</p>
                                            <p className="mt-1 text-sm text-gray-600">Soya: {house.soya ? "Yes" : "No"}</p>
                                          </div>
                                        ))}
                                      </div>
                                    </div>
                                  )}
                                </div>
                              ) : <p className="text-gray-400">No Lal Kitab data available.</p>}
                            </div>
                          )}
                        </div>
                      )}
                    </>
                  )}
                </div>
              )}
            </div>
          )}
        </form>
      </section>

      <section className="bg-white py-20 border-t border-gray-100">
        <div className="max-w-7xl mx-auto px-4 md:px-8">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <span className="text-[#D4A73C] font-bold tracking-widest uppercase text-sm mb-2 block">Premium Features</span>
            <h2 className="text-3xl md:text-4xl font-bold text-[#1E3557]">Why Choose AstroZura Kundli?</h2>
            <p className="text-gray-500 mt-4 leading-relaxed">We provide highly accurate kundli predictions powered by advanced astrological calculations.</p>
          </div>
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            {[{ title: "Accurate Predictions", icon: <FaSun className="text-[#D4A73C] text-2xl" />, desc: "Get precise astrological predictions tailored to your exact birth time and location." }, { title: "Detailed Dashas", icon: <FaMoon className="text-[#D4A73C] text-2xl" />, desc: "Analyze Vimshottari dashas and their timing with much richer detail." }, { title: "Dosha Analysis", icon: <FaExclamationTriangle className="text-[#D4A73C] text-2xl" />, desc: "Identify dosha strength, exceptions, and remedies from the live response." }, { title: "Expert Astrologers", icon: <FaStar className="text-[#D4A73C] text-2xl" />, desc: "Use this structured chart output as a base for later consultation features." }].map((card, index) => <div key={index} className="bg-[#f8f9fa] p-8 rounded-2xl hover:shadow-lg transition-all duration-300 hover:-translate-y-2 border border-gray-100 group"><div className="w-14 h-14 bg-white rounded-xl shadow-sm flex items-center justify-center mb-6 border border-gray-100 group-hover:bg-[#1E3557] group-hover:border-[#1E3557] transition-colors">{React.cloneElement(card.icon, { className: "text-[#D4A73C] text-2xl group-hover:scale-110 transition-transform" })}</div><h3 className="text-xl font-bold text-[#1E3557] mb-3">{card.title}</h3><p className="text-gray-500 text-sm leading-relaxed">{card.desc}</p></div>)}
          </div>
        </div>
      </section>

      <Footer />
    </div>
  );
}
