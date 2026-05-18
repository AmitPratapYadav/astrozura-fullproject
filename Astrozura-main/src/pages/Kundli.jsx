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
  getLalKitabReport,
  getKundliDetailSection,
} from "../api/prokeralaApi";
import { useAuth } from "../context/AuthContext";
import {
  KUNDLI_LANGUAGE_OPTIONS,
  getLanguageLabel,
  getLocaleForLanguage,
} from "../constants/prokeralaLanguages";
import { KeyValueTable, ReportPanel, ReportTable, SimpleTextTable } from "../components/report/ReportTables";
import { ProviderSections } from "../components/report/ReportDataRenderer";
import { displayCell, formatReportLabel } from "../components/report/reportUtils";

const chartTypeOptions = [
  { value: "rasi", label: "D1 - Rasi Chart" },
  { value: "hora", label: "D2 - Hora Chart" },
  { value: "drekkana", label: "D3 - Drekkana Chart" },
  { value: "chaturthamsa", label: "D4 - Chaturthamsa Chart" },
  { value: "panchamsa", label: "D5 - Panchamsa Chart" },
  { value: "shashtamsa", label: "D6 - Shashtamsa Chart" },
  { value: "saptamsa", label: "D7 - Saptamsa Chart" },
  { value: "ashtamsa", label: "D8 - Ashtamsa Chart" },
  { value: "navamsa", label: "D9 - Navamsa Chart" },
  { value: "dasamsa", label: "D10 - Dasamsa Chart" },
  { value: "rudramsa", label: "D11 - Rudramsa Chart" },
  { value: "dwadasamsa", label: "D12 - Dwadasamsa Chart" },
  { value: "trayodashamsa", label: "D13 - Trayodashamsa Chart" },
  { value: "chaturdashamsa", label: "D14 - Chaturdashamsa Chart" },
  { value: "panchdashamsa", label: "D15 - Panchdashamsa Chart" },
  { value: "shodasamsa", label: "D16 - Shodasamsa Chart" },
  { value: "vimsamsa", label: "D20 - Vimsamsa Chart" },
  { value: "chaturvimsamsa", label: "D24 - Chaturvimsamsa Chart" },
  { value: "bhamsa", label: "D27 - Bhamsa Chart" },
  { value: "trimsamsa", label: "D30 - Trimsamsa Chart" },
  { value: "khavedamsa", label: "D40 - Khavedamsa Chart" },
  { value: "akshavedamsa", label: "D45 - Akshavedamsa Chart" },
  { value: "shastiamsa", label: "D60 - Shastiamsa Chart" },
];

const d1ToD16ChartOptions = chartTypeOptions.filter((item) =>
  ["rasi", "hora", "drekkana", "chaturthamsa", "panchamsa", "shashtamsa", "saptamsa", "ashtamsa", "navamsa", "dasamsa", "rudramsa", "dwadasamsa", "trayodashamsa", "chaturdashamsa", "panchdashamsa", "shodasamsa"].includes(item.value)
);

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

const formatReportKey = (key = "") =>
  String(key)
    .replace(/_/g, " ")
    .replace(/\b\w/g, (char) => char.toUpperCase());

const isPrimitive = (value) =>
  value === null || ["string", "number", "boolean"].includes(typeof value);

const renderDetailValue = (value, depth = 0) => {
  if (value === null || value === undefined || value === "") {
    return <span className="text-gray-400">-</span>;
  }

  if (typeof value === "string" && value.trim().startsWith("<svg")) {
    return <span className="text-gray-500">SVG chart image available in chart section.</span>;
  }

  if (isPrimitive(value)) {
    return <span className="break-words text-gray-700">{String(value)}</span>;
  }

  if (Array.isArray(value)) {
    if (value.length === 0) return <span className="text-gray-400">No data returned.</span>;

    if (value.every((item) => item && typeof item === "object" && !Array.isArray(item))) {
      const keys = Array.from(new Set(value.flatMap((item) => Object.keys(item)))).slice(0, 8);
      return (
        <ReportTable
          columns={keys.map((key) => ({ key, label: formatReportKey(key) }))}
          rows={value.slice(0, 30)}
          compact
        />
      );
    }

    return (
      <div className="space-y-2">
        {value.slice(0, 30).map((item, index) => (
          <div key={index} className="border border-gray-200 bg-white p-3">
            {isPrimitive(item) ? renderDetailValue(item, depth + 1) : renderDetailValue(item, depth + 1)}
          </div>
        ))}
        {value.length > 30 && <p className="text-xs font-medium text-gray-400">Showing first 30 of {value.length} records.</p>}
      </div>
    );
  }

  const entries = Object.entries(value);
  if (entries.length === 0) return <span className="text-gray-400">No data returned.</span>;

  if (entries.every(([, item]) => isPrimitive(item) || (item && typeof item === "object" && "name" in item))) {
    return <KeyValueTable columns={depth < 2 ? 2 : 1} rows={entries.map(([key, item]) => [formatReportKey(key), displayCell(item)])} />;
  }

  return <KeyValueTable columns={1} rows={entries.map(([key, item]) => [formatReportKey(key), renderDetailValue(item, depth + 1)])} />;
};

const DetailedReportSection = ({ section, defaultOpen = false, loading = false, onOpen }) => {
  const items = section?.items || {};
  const entries = Object.entries(items);
  const successCount = entries.filter(([, item]) => item?.status === "success").length;
  const pendingCount = entries.filter(([, item]) => item?.status === "pending").length;
  const errorCount = entries.length - successCount - pendingCount;

  useEffect(() => {
    if (defaultOpen) onOpen?.();
  }, []);

  return (
    <details open={defaultOpen} onToggle={(event) => event.currentTarget.open && onOpen?.()} className="group rounded-3xl border border-gray-100 bg-white shadow-sm">
      <summary className="flex cursor-pointer list-none items-start justify-between gap-4 p-5 md:p-6">
        <div>
          <h4 className="text-lg font-bold text-[#1E3557]">{section.title}</h4>
          {section.summary && <p className="mt-1 text-sm text-gray-500">{section.summary}</p>}
          <div className="mt-3 flex flex-wrap gap-2 text-xs font-semibold">
            <span className="rounded-full bg-emerald-50 px-3 py-1 text-emerald-700">{successCount} loaded</span>
            {pendingCount > 0 && <span className="rounded-full bg-blue-50 px-3 py-1 text-blue-700">{pendingCount} loads on open</span>}
            {errorCount > 0 && <span className="rounded-full bg-amber-50 px-3 py-1 text-amber-700">{errorCount} unavailable</span>}
            {loading && <span className="rounded-full bg-gray-100 px-3 py-1 text-gray-600">Loading...</span>}
          </div>
        </div>
        <span className="rounded-full border border-gray-200 px-3 py-1 text-sm font-bold text-gray-500 transition group-open:rotate-180">⌄</span>
      </summary>

      <div className="border-t border-gray-100 p-5 md:p-6">
        <div className="grid gap-4 xl:grid-cols-2">
          {entries.map(([key, item]) => (
            <div key={key} className="rounded-2xl border border-gray-100 bg-[#fbfcfd] p-4">
              <div className="mb-3 flex items-start justify-between gap-3">
                <div>
                  <p className="font-bold text-[#1E3557]">{formatReportKey(key)}</p>
                  {item?.endpoint && <p className="mt-1 text-xs text-gray-400">{item.endpoint}</p>}
                </div>
                <span className={`rounded-full px-3 py-1 text-xs font-semibold ${item?.status === "success" ? "bg-emerald-50 text-emerald-700" : "bg-amber-50 text-amber-700"}`}>
                  {item?.status === "success" ? "Loaded" : "Unavailable"}
                </span>
              </div>

              {item?.status === "success" ? (
                renderDetailValue(item.data)
              ) : item?.status === "pending" ? (
                <p className="rounded-xl bg-blue-50 p-3 text-sm text-blue-800">{loading ? "Loading this module..." : item?.message || "Open this section to load this module."}</p>
              ) : (
                <p className="rounded-xl bg-amber-50 p-3 text-sm text-amber-800">{item?.message || "This module is not available in the current response."}</p>
              )}
            </div>
          ))}
        </div>
      </div>
    </details>
  );
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
  const [detailedSections, setDetailedSections] = useState([]);
  const [loadingDetailedSections, setLoadingDetailedSections] = useState({});

  // Premium Features States
  const [activeTab, setActiveTab] = useState("free"); // free, premium
  const [premiumTab, setPremiumTab] = useState("charts"); // charts, predictions, numerology, etc.
  const [loadingPremium, setLoadingPremium] = useState(false);
  const [premiumData, setPremiumData] = useState({});
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
      setDetailedSections([]);
      setLoadingDetailedSections({});
      showToast("Generating your kundli...");
      const datetime = `${details.dob}T${details.time}:00+05:30`;
      const response = await generateKundli(datetime, details.coordinates, 1, {
        chart_types: d1ToD16ChartOptions.map((item) => item.value),
        chart_style: details.chartStyle,
        la: details.language,
      });
      if (response?.status === "success" && response?.data?.kundli) {
        setKundliData(response.data.kundli);
        setChartData(response.data.charts || (response.data.chart ? [{
          status: "success",
          chart_id: response.data.chart_meta?.chart_type || "D1",
          label: "D1 - Rasi Chart",
          chart_svg: response.data.chart,
        }] : []));
        setApiMeta({
          requestedDatetime: response.data.requested_datetime,
          effectiveDatetime: response.data.effective_datetime,
          warning: response.data.warning,
          chartMeta: response.data.chart_meta,
          dashaSummary: response.data.dasha_summary || {},
          language: response.data.language || details.language,
          supportedLanguages: response.data.supported_languages || [],
          providerPayload: response.data.provider_payload || {},
        });
        setDetailedSections(response.data.detailed_report || []);
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

  const loadDetailedSection = async (sectionId) => {
    const currentSection = detailedSections.find((section) => section.id === sectionId);
    if (!currentSection || loadingDetailedSections[sectionId]) return;

    const entries = Object.values(currentSection.items || {});
    const hasPendingItems = entries.some((item) => item?.status === "pending");
    if (!hasPendingItems) return;

    try {
      setLoadingDetailedSections((prev) => ({ ...prev, [sectionId]: true }));
      const datetime = `${details.dob}T${details.time}:00+05:30`;
      const response = await getKundliDetailSection(sectionId, {
        datetime,
        coordinates: details.coordinates,
        ayanamsa: 1,
        chart_style: details.chartStyle,
        la: details.language,
      });

      if (response?.status === "success" && response.data) {
        setDetailedSections((prev) =>
          prev.map((section) => (section.id === sectionId ? response.data : section))
        );
      }
    } catch (error) {
      showToast(error?.response?.data?.message || "Failed to load this Kundli section.");
    } finally {
      setLoadingDetailedSections((prev) => ({ ...prev, [sectionId]: false }));
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
          res = await getDivisionalCharts(
            datetime,
            details.coordinates,
            d1ToD16ChartOptions.map((item) => item.value),
            details.chartStyle,
            { la: details.language }
          );
          break;
        case "predictions":
          res = await getPredictions(datetime, details.coordinates, activePredictionType, { la: details.language });
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
            res = await getSadesatiReport(datetime, details.coordinates, { la: details.language });
          break;
        case "lalkitab":
          res = await getLalKitabReport(datetime, details.coordinates, { la: details.language });
          break;
        default: break;
      }

      if (res?.status === "success") {
        setPremiumData(prev => ({ ...prev, [type]: res.data }));
      }
    } catch {
      showToast("Failed to load premium data.");
    } finally {
      setLoadingPremium(false);
    }
  };

  useEffect(() => {
    if (activeTab === "premium" && kundliData) {
      loadPremiumFeature(premiumTab);
    }
  }, [activeTab, premiumTab, activePredictionType]);

  const birth = kundliData?.nakshatra_details;
  const info = birth?.additional_info || {};
  const dosha = kundliData?.mangal_dosha;
  const dasha = apiMeta?.dashaSummary || {};
  const detailedReport = Array.isArray(detailedSections) ? detailedSections : [];
  const activeLanguage = apiMeta?.language || details.language;
  const yogas = Array.isArray(kundliData?.yoga_details) ? kundliData.yoga_details : [];
  const visibleSadesatiTransits = getRelevantSadesatiTransits(premiumData.sadesati?.transits || []);
  const profileItems = [
    ["Nakshatra", birth?.nakshatra?.name], ["Pada", birth?.nakshatra?.pada], ["Nakshatra Lord", birth?.nakshatra?.lord?.name],
    ["Moon Sign", birth?.chandra_rasi?.name], ["Sun Sign", birth?.soorya_rasi?.name], ["Zodiac", birth?.zodiac?.name],
    ["Birth Stone", info.birth_stone], ["Ganam", info.ganam], ["Nadi", info.nadi], ["Animal Sign", info.animal_sign], ["Syllables", info.syllables], ["Best Direction", info.best_direction],
  ];
  const providerPayload = apiMeta?.providerPayload || {};
  const planetRows = Array.isArray(providerPayload.planets)
    ? providerPayload.planets.map((planet, index) => ({
        id: `${planet.name || planet.planet || "planet"}-${index}`,
        planet: planet.name || planet.planet,
        sign: planet.sign,
        sign_lord: planet.signLord || planet.sign_lord,
        nakshatra: planet.nakshatra || planet.nakshatra_name,
        nakshatra_lord: planet.nakshatraLord || planet.nakshatra_lord,
        degree: planet.normDegree || planet.fullDegree || planet.degree,
        house: planet.house,
        retro: planet.isRetro || planet.retro || planet.is_retro,
        combust: planet.is_planet_set || planet.combust,
        status: planet.planet_awastha || planet.awastha,
      }))
    : [];
  const astroRows = Object.entries(providerPayload.astro_details || {}).map(([key, value]) => ({
    field: formatReportLabel(key),
    value: displayCell(value),
  }));
  const chartRows = Array.isArray(chartData)
    ? chartData.map((chart, index) => ({
        sn: index + 1,
        chart: chart.label || chart.chart_id,
        style: apiMeta?.chartMeta?.chart_style || details.chartStyle,
        status: chart.status === "error" ? "Unavailable" : "Available",
        note: chart.message || "-",
      }))
    : [];
  const dashaRows = [
    ["Maha Dasha", dasha.current_mahadasha],
    ["Antar Dasha", dasha.current_antardasha],
    ["Pratyantar Dasha", dasha.current_pratyantardasha],
  ].map(([period, value]) => ({
    period,
    planet: value?.name,
    start: formatDateTime(value?.start, activeLanguage),
    end: formatDateTime(value?.end, activeLanguage),
  }));
  const upcomingDashaRows = Array.isArray(dasha.next_mahadasha)
    ? dasha.next_mahadasha.map((period, index) => ({
        sn: index + 1,
        planet: period.name,
        start: formatDateTime(period.start, activeLanguage),
        end: formatDateTime(period.end, activeLanguage),
      }))
    : [];
  const yogaRows = yogas.flatMap((group) =>
    (group.yoga_list || []).map((item) => ({
      group: group.name,
      yoga: item.name,
      status: item.has_yoga ? "Present" : "Not present",
      description: item.description,
    }))
  );

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
            <div className="rounded-xl border border-dashed border-gray-200 bg-gray-50 px-4 py-3 text-sm text-gray-500">
              Charts included: D1 through D16.
            </div>
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
                  <div className="rounded-sm border border-gray-200 bg-white shadow-sm">
                    <div className="border-b border-gray-200 bg-white px-5 py-5">
                      <h3 className="text-2xl font-bold text-gray-950">{details.name || "Birth"}'s Birth/Natal Report</h3>
                      <p className="mt-1 text-sm text-gray-500">Locale: {getLanguageLabel(activeLanguage)} | Chart style: {apiMeta?.chartMeta?.chart_style || details.chartStyle}</p>
                    </div>
                    <div className="space-y-5 p-4">
                      <ReportPanel title="Birth Details">
                        <KeyValueTable
                          rows={[
                            ["Name", details.name],
                            ["Gender", details.gender],
                            ["Birth Date", details.dob],
                            ["Birth Time", details.time],
                            ["Place of Birth", details.place],
                            ["Coordinates", details.coordinates],
                            ["Nakshatra", birth?.nakshatra?.name],
                            ["Rashi", birth?.chandra_rasi?.name],
                            ["Sun Sign", birth?.soorya_rasi?.name],
                            ["Current Maha Dasha", dasha.current_mahadasha?.name || kundliData?.dasha_balance?.lord?.name],
                          ]}
                        />
                      </ReportPanel>

                      <ReportPanel title="Charts Summary">
                        <ReportTable
                          columns={[
                            { key: "sn", label: "S.N." },
                            { key: "chart", label: "Chart" },
                            { key: "style", label: "Style" },
                            { key: "status", label: "Status" },
                            { key: "note", label: "Note" },
                          ]}
                          rows={chartRows}
                          compact
                        />
                      </ReportPanel>

                      <div className="grid gap-5 lg:grid-cols-2">
                        {Array.isArray(chartData) && chartData.length > 0 ? chartData.map((chart, index) => (
                          <ReportPanel key={chart.chart_id || chart.label || index} title={chart.label || chart.chart_id || `Chart ${index + 1}`}>
                            <div className="flex min-h-[300px] items-center justify-center overflow-x-auto border border-gray-200 bg-[#fff8df] p-3">
                              {chart.chart_svg ? <div dangerouslySetInnerHTML={{ __html: chart.chart_svg }} className="max-w-full" style={{ minWidth: "280px", minHeight: "280px" }} /> : <p className="text-center text-sm text-gray-500">{chart.message || "Chart image is not available for this response."}</p>}
                            </div>
                            <div className="mt-3">
                              <KeyValueTable
                                columns={1}
                                rows={[
                                  ["Chart", chart.label || chart.chart_id],
                                  ["Style", apiMeta?.chartMeta?.chart_style || details.chartStyle],
                                  ["Status", chart.status === "error" ? "Unavailable" : "Available"],
                                ]}
                              />
                            </div>
                          </ReportPanel>
                        )) : (
                          <ReportPanel title="Charts">
                            <p className="text-sm text-gray-500">Chart images are not available for this response.</p>
                          </ReportPanel>
                        )}
                      </div>

                      <ReportPanel title="Planets">
                        <ReportTable
                          columns={[
                            { key: "planet", label: "Planet" },
                            { key: "sign", label: "Sign" },
                            { key: "sign_lord", label: "Sign Lord" },
                            { key: "nakshatra", label: "Nakshatra" },
                            { key: "nakshatra_lord", label: "Nakshatra Lord" },
                            { key: "degree", label: "Degree" },
                            { key: "house", label: "House" },
                            { key: "retro", label: "Retro" },
                            { key: "combust", label: "Combust" },
                            { key: "status", label: "Avastha" },
                          ]}
                          rows={planetRows}
                          compact
                        />
                      </ReportPanel>

                      <ReportPanel title="Astro Details">
                        <ReportTable
                          columns={[
                            { key: "field", label: "Field" },
                            { key: "value", label: "Value" },
                          ]}
                          rows={astroRows}
                          compact
                        />
                      </ReportPanel>

                      <ReportPanel title="Birth Profile Snapshot">
                        <KeyValueTable rows={profileItems} />
                      </ReportPanel>

                      <ReportPanel title="Mangal Dosha Summary">
                        <KeyValueTable
                          rows={[
                            ["Status", dosha?.type ? `${dosha.type} Manglik` : dosha?.has_dosha ? "Manglik" : "No Mangal Dosha"],
                            ["Description", dosha?.description || "No dosha details returned."],
                          ]}
                          columns={1}
                        />
                        {Array.isArray(dosha?.exceptions) && dosha.exceptions.length > 0 && <div className="mt-4"><SimpleTextTable title="Exception" items={dosha.exceptions} /></div>}
                      </ReportPanel>

                      <ReportPanel title="Dasha Timing">
                        <ReportTable
                          columns={[
                            { key: "period", label: "Period" },
                            { key: "planet", label: "Planet" },
                            { key: "start", label: "Start Date" },
                            { key: "end", label: "End Date" },
                          ]}
                          rows={dashaRows}
                        />
                        {upcomingDashaRows.length > 0 && (
                          <div className="mt-5">
                            <ReportTable
                              columns={[
                                { key: "sn", label: "S.N." },
                                { key: "planet", label: "Upcoming Maha Dasha" },
                                { key: "start", label: "Start Date" },
                                { key: "end", label: "End Date" },
                              ]}
                              rows={upcomingDashaRows}
                            />
                          </div>
                        )}
                      </ReportPanel>
                    </div>
                  </div>

                  {detailedReport.length > 0 && (
                    <div className="space-y-4">
                      <div className="rounded-3xl border border-gray-100 bg-white p-6 shadow-sm">
                        <h4 className="text-xl font-bold text-[#1E3557]">Detailed Kundli Modules</h4>
                        <p className="mt-2 text-sm text-gray-500">Each section can be opened as needed, so the full Kundli stays readable without a long forced scroll.</p>
                      </div>
                      {detailedReport.map((section, index) => (
                        <DetailedReportSection
                          key={section.id || section.title}
                          section={section}
                          defaultOpen={index < 2}
                          loading={!!loadingDetailedSections[section.id]}
                          onOpen={() => loadDetailedSection(section.id)}
                        />
                      ))}
                    </div>
                  )}

                  <ReportPanel title="Yoga Details">
                    <ReportTable
                      columns={[
                        { key: "group", label: "Group" },
                        { key: "yoga", label: "Yoga" },
                        { key: "status", label: "Status" },
                        { key: "description", label: "Description" },
                      ]}
                      rows={yogaRows}
                    />
                  </ReportPanel>

                  {Array.isArray(dosha?.remedies) && dosha.remedies.length > 0 && (
                    <ReportPanel title="Suggested Remedies">
                      <SimpleTextTable title="Remedy" items={dosha.remedies.slice(0, 6)} />
                    </ReportPanel>
                  )}
                </>
              ) : (
                <div className="space-y-8 animate-fadeIn">
                  {!isPaid ? (
                    <div className="rounded-3xl border-2 border-dashed border-gray-200 bg-gray-50 p-12 text-center pointer-events-none opacity-80">
                      <div className="w-20 h-20 bg-white rounded-2xl shadow-sm flex items-center justify-center mb-6 mx-auto border border-gray-100">
                        <FaStar className="text-[#D4A73C] text-4xl animate-pulse" />
                      </div>
                      <h3 className="text-2xl font-bold text-[#1E3557]">Premium Reports are Locked</h3>
                      <p className="text-gray-500 mt-4 max-w-md mx-auto">Get full access to D1-D16 charts, detailed life predictions, Sadesati reports, and Vedic remedies.</p>
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
                                <span className="rounded-full bg-gray-50 px-4 py-2 text-sm font-bold text-gray-500">D1-D16 included</span>
                              </div>
                              <div className="grid gap-6 lg:grid-cols-2">
                                {Array.isArray(premiumData.charts?.charts) && premiumData.charts.charts.length > 0 ? premiumData.charts.charts.map((chart) => (
                                  <div key={chart.chart_id || chart.label} className="rounded-3xl border border-gray-100 bg-white p-6 shadow-sm">
                                    <div className="mb-4 flex items-center justify-between gap-3">
                                      <h5 className="font-bold text-[#1E3557]">{chart.label || chart.chart_id}</h5>
                                      {chart.status === "error" && <span className="rounded-full bg-amber-100 px-3 py-1 text-xs font-semibold text-amber-800">Unavailable</span>}
                                    </div>
                                    <div className="flex min-h-[320px] items-center justify-center overflow-x-auto rounded-2xl bg-gray-50 p-4">
                                      {chart.chart_svg ? <div dangerouslySetInnerHTML={{ __html: chart.chart_svg }} className="max-w-full" /> : <p className="text-sm text-gray-400">{chart.message || "Chart image is not available."}</p>}
                                    </div>
                                  </div>
                                )) : <div className="rounded-3xl border border-gray-100 bg-white p-8 text-center text-gray-400 shadow-sm">No divisional charts available.</div>}
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
                              <div className="flex items-center gap-3"><FaStar className="text-[#D4A73C] text-xl" /><h4 className="text-xl font-bold text-[#1E3557]">Lal Kitab Report</h4></div>
                              {premiumData.lalkitab ? (
                                <ProviderSections sections={premiumData.lalkitab.provider_sections || []} />
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
