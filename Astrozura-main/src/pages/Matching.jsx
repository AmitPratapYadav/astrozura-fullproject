import React, { useState } from "react";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { FaExclamationTriangle, FaFilePdf, FaHeart, FaPen, FaShieldAlt, FaStar } from "react-icons/fa";
import { downloadMatchMakingPdf, getDivisionalCharts, getMarriageMatching, searchLocation } from "../api/prokeralaApi";
import { ReportDataBlock } from "../components/report/ReportDataRenderer";

const emptyPerson = { name: "", dob: "", time: "", place: "", coordinates: "" };

const verdictStyles = {
  good: { color: "bg-emerald-600", text: "text-emerald-700", label: "Auspicious" },
  average: { color: "bg-[#D4A73C]", text: "text-[#7a5205]", label: "Mixed" },
  bad: { color: "bg-rose-700", text: "text-rose-700", label: "Needs Review" },
};

const chartTabs = [
  { key: "rasi", label: "Birth(Lagna) Chart" },
  { key: "moon", label: "Moon Chart" },
  { key: "navamsa", label: "Navamsha Chart" },
];

const ashtakootDescriptions = {
  varna: "Natural Refinement / Work",
  vashya: "Innate Giving / Attraction towards each other",
  tara: "Comfort - Prosperity - Health",
  yoni: "Intimate Physical",
  maitri: "Friendship",
  gan: "Temperament",
  bhakut: "Constructive Ability / Society Harmony",
  nadi: "Progeny / Excess",
};

const safeValue = (value, fallback = "-") => {
  if (value === null || value === undefined || value === "") return fallback;
  if (typeof value === "object") return value.name || value.full_name || value.value || fallback;
  return String(value);
};

const formatDate = (value) => {
  if (!value) return "-";
  const [year, month, day] = value.split("-");
  return year && month && day ? `${day}-${month}-${year}` : value;
};

const splitCoordinates = (coordinates) => {
  const [lat, lon] = String(coordinates || "").split(",").map((item) => item.trim());
  return { lat: lat || "-", lon: lon || "-" };
};

const getKoot = (info, key) => safeValue(info?.koot?.[key]);

const getNakshatraName = (info) => safeValue(info?.nakshatra?.name);

const getChart = (charts, key) => {
  const expectedId = key === "navamsa" ? "D9" : key === "moon" ? "MOON" : "D1";
  return charts?.find((chart) => chart.chart_type === key || chart.chart_id === expectedId) || null;
};

function SectionTitle({ children }) {
  return (
    <div className="mb-4 border-b-2 border-[#D4A73C] pb-2">
      <h3 className="text-2xl font-black text-slate-700">{children}</h3>
    </div>
  );
}

function CompactTable({ columns, rows, footerRow }) {
  return (
    <div className="overflow-x-auto rounded-sm border border-slate-200 bg-white">
      <table className="min-w-full border-collapse text-sm">
        <thead className="bg-slate-100 text-slate-700">
          <tr>
            {columns.map((column) => (
              <th key={column.key} className="border-b border-slate-200 px-4 py-3 text-left font-black">
                {column.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, index) => (
            <tr key={row.id || index} className={index % 2 === 0 ? "bg-white" : "bg-slate-50"}>
              {columns.map((column) => (
                <td key={column.key} className="border-b border-slate-200 px-4 py-3 align-top text-slate-600">
                  {column.render ? column.render(row) : safeValue(row[column.key])}
                </td>
              ))}
            </tr>
          ))}
          {footerRow ? (
            <tr className="bg-[#1E3557] font-black text-white">
              {columns.map((column) => (
                <td key={column.key} className="px-4 py-3">
                  {safeValue(footerRow[column.key])}
                </td>
              ))}
            </tr>
          ) : null}
        </tbody>
      </table>
    </div>
  );
}

function ScoreCircle({ label, value, color = "bg-[#1E3557]" }) {
  return (
    <div className="flex flex-col items-center gap-3">
      <div className={`flex h-24 w-24 items-center justify-center rounded-full ${color} text-center text-xl font-black text-white shadow-sm`}>
        {value}
      </div>
      <p className="text-center text-sm font-black text-slate-900">{label}</p>
    </div>
  );
}

function ChartPair({ label, boyName, girlName, boyChart, girlChart, loading }) {
  return (
    <div>
      <div className="mb-6 text-center text-sm font-semibold text-slate-500">{label}</div>
      <div className="grid gap-8 md:grid-cols-2">
        {[
          { name: boyName || "Boy", chart: boyChart },
          { name: girlName || "Girl", chart: girlChart },
        ].map((item) => (
          <div key={item.name} className="text-center">
            <p className="mb-3 text-lg font-black text-[#1E3557]">{item.name}</p>
            <div className="mx-auto flex aspect-square w-full max-w-[340px] items-center justify-center overflow-hidden border border-slate-300 bg-white p-3">
              {item.chart?.chart_svg ? (
                <div
                  className="flex h-full w-full items-center justify-center [&_svg]:block [&_svg]:h-auto [&_svg]:max-h-full [&_svg]:max-w-full"
                  dangerouslySetInnerHTML={{ __html: item.chart.chart_svg }}
                />
              ) : (
                <p className="px-6 text-sm text-slate-500">
                  {loading ? "Loading chart..." : item.chart?.message || "Chart image is not available in the current response."}
                </p>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default function Matching() {
  const [boyDetails, setBoyDetails] = useState(emptyPerson);
  const [girlDetails, setGirlDetails] = useState(emptyPerson);
  const [boySearchResults, setBoySearchResults] = useState([]);
  const [girlSearchResults, setGirlSearchResults] = useState([]);
  const [isBoySearching, setIsBoySearching] = useState(false);
  const [isGirlSearching, setIsGirlSearching] = useState(false);
  const [loading, setLoading] = useState(false);
  const [downloadingPdf, setDownloadingPdf] = useState(false);
  const [chartsLoading, setChartsLoading] = useState(false);
  const [activeChart, setActiveChart] = useState("rasi");
  const [matchingCharts, setMatchingCharts] = useState({ boy: [], girl: [] });
  const [result, setResult] = useState(null);
  const [meta, setMeta] = useState(null);
  const [error, setError] = useState("");

  const showError = (text) => {
    setError(text);
    window.clearTimeout(window.__astrozuraMatchingToast);
    window.__astrozuraMatchingToast = window.setTimeout(() => setError(""), 3500);
  };

  const searchBirthPlace = async (value, setPerson, setResults, setSearching) => {
    setPerson((prev) => ({ ...prev, place: value, coordinates: "" }));
    if (value.trim().length < 3) return setResults([]);
    try {
      setSearching(true);
      const response = await searchLocation(value.trim());
      setResults(response?.data || []);
    } catch {
      setResults([]);
    } finally {
      setSearching(false);
    }
  };

  const selectLocation = (place, setPerson, setResults) => {
    setPerson((prev) => ({ ...prev, place: place.name, coordinates: `${place.coordinates.latitude},${place.coordinates.longitude}` }));
    setResults([]);
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    if (!boyDetails.coordinates || !girlDetails.coordinates) return showError("Select valid birthplaces from the dropdown suggestions for both entries.");
    try {
      setLoading(true);
      setResult(null);
      setMeta(null);
      setMatchingCharts({ boy: [], girl: [] });
      setError("");
      const boyDatetime = `${boyDetails.dob}T${boyDetails.time}:00+05:30`;
      const girlDatetime = `${girlDetails.dob}T${girlDetails.time}:00+05:30`;
      const response = await getMarriageMatching(girlDetails.coordinates, girlDatetime, boyDetails.coordinates, boyDatetime, {
        boy_name: boyDetails.name,
        girl_name: girlDetails.name,
        boy_place: boyDetails.place,
        girl_place: girlDetails.place,
      });
      if (response?.status === "success" && response?.data) {
        setResult(response.data);
        setMeta(response.meta || null);
        setChartsLoading(true);
        Promise.allSettled([
          getDivisionalCharts(boyDatetime, boyDetails.coordinates, ["rasi", "moon", "navamsa"], "north-indian"),
          getDivisionalCharts(girlDatetime, girlDetails.coordinates, ["rasi", "moon", "navamsa"], "north-indian"),
        ]).then(([boyChartResult, girlChartResult]) => {
          setMatchingCharts({
            boy: boyChartResult.status === "fulfilled" ? boyChartResult.value?.data?.charts || [] : [],
            girl: girlChartResult.status === "fulfilled" ? girlChartResult.value?.data?.charts || [] : [],
          });
        }).finally(() => setChartsLoading(false));
      } else {
        showError(response?.message || "Failed to fetch matching data.");
      }
    } catch (matchError) {
      showError(matchError?.response?.data?.message || "An error occurred while fetching kundli matching.");
    } finally {
      setLoading(false);
    }
  };

  const parsePdfError = async (blob) => {
    try {
      const text = await blob.text();
      const json = JSON.parse(text);
      return json.message || json.msg || "Failed to generate PDF report.";
    } catch {
      return "Failed to generate PDF report.";
    }
  };

  const handleDownloadPdf = async () => {
    if (!boyDetails.coordinates || !girlDetails.coordinates) return showError("Select valid birthplaces from the dropdown suggestions for both entries.");
    if (!boyDetails.name || !boyDetails.dob || !boyDetails.time || !girlDetails.name || !girlDetails.dob || !girlDetails.time) {
      return showError("Enter complete birth details for both entries before downloading the PDF.");
    }

    try {
      setDownloadingPdf(true);
      setError("");
      const boyDatetime = `${boyDetails.dob}T${boyDetails.time}:00+05:30`;
      const girlDatetime = `${girlDetails.dob}T${girlDetails.time}:00+05:30`;
      const response = await downloadMatchMakingPdf({
        boy_name: boyDetails.name,
        boy_coordinates: boyDetails.coordinates,
        boy_dob: boyDatetime,
        boy_place: boyDetails.place,
        girl_name: girlDetails.name,
        girl_coordinates: girlDetails.coordinates,
        girl_dob: girlDatetime,
        girl_place: girlDetails.place,
        la: "en",
      });

      const contentType = response.headers?.["content-type"] || "";
      if (!contentType.includes("application/pdf")) {
        return showError(await parsePdfError(response.data));
      }

      const blobUrl = window.URL.createObjectURL(response.data);
      const link = document.createElement("a");
      const filename = `${boyDetails.name}-${girlDetails.name}-match-report.pdf`.replace(/[^a-z0-9.-]+/gi, "-").toLowerCase();
      link.href = blobUrl;
      link.download = filename;
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(blobUrl);
    } catch (pdfError) {
      showError(pdfError?.response?.data ? await parsePdfError(pdfError.response.data) : "Failed to generate PDF report.");
    } finally {
      setDownloadingPdf(false);
    }
  };

  const verdict = verdictStyles[result?.message?.type] || verdictStyles.average;
  const totalPoints = result?.guna_milan?.total_points || 0;
  const maximumPoints = result?.guna_milan?.maximum_points || 36;
  const scorePercent = Math.max(0, Math.min(100, (totalPoints / maximumPoints) * 100));
  const compatibilityMessage = result?.message?.description || "Compatibility details are available in the guna breakdown below.";
  const boyCoordinates = splitCoordinates(boyDetails.coordinates);
  const girlCoordinates = splitCoordinates(girlDetails.coordinates);
  const boyInfo = result?.boy_info || {};
  const girlInfo = result?.girl_info || {};
  const activeChartConfig = chartTabs.find((item) => item.key === activeChart) || chartTabs[0];
  const boyActiveChart = getChart(matchingCharts.boy, activeChart);
  const girlActiveChart = getChart(matchingCharts.girl, activeChart);
  const matchPercentage = meta?.provider_payload?.match_percentage?.percentage
    ?? meta?.provider_payload?.match_percentage?.match_percentage
    ?? Math.round(scorePercent);

  const birthRows = [
    { id: "dob", male: formatDate(boyDetails.dob), label: "Date of Birth", female: formatDate(girlDetails.dob) },
    { id: "time", male: safeValue(boyDetails.time), label: "Birth Time", female: safeValue(girlDetails.time) },
    { id: "lat", male: boyCoordinates.lat, label: "Latitude", female: girlCoordinates.lat },
    { id: "lon", male: boyCoordinates.lon, label: "Longitude", female: girlCoordinates.lon },
    { id: "tz", male: "5.5", label: "Time Zone", female: "5.5" },
    { id: "sunrise", male: safeValue(boyInfo?.birth?.sunrise), label: "Sunrise", female: safeValue(girlInfo?.birth?.sunrise) },
    { id: "sunset", male: safeValue(boyInfo?.birth?.sunset), label: "Sunset", female: safeValue(girlInfo?.birth?.sunset) },
    { id: "ayanamsha", male: safeValue(boyInfo?.birth?.ayanamsha), label: "Ayanamsha", female: safeValue(girlInfo?.birth?.ayanamsha) },
    { id: "varna", male: getKoot(boyInfo, "varna"), label: "Varna", female: getKoot(girlInfo, "varna") },
    { id: "vashya", male: getKoot(boyInfo, "vashya"), label: "Vashya", female: getKoot(girlInfo, "vashya") },
    { id: "yoni", male: getKoot(boyInfo, "yoni"), label: "Yoni", female: getKoot(girlInfo, "yoni") },
    { id: "gan", male: getKoot(boyInfo, "gana"), label: "Gan", female: getKoot(girlInfo, "gana") },
  ];

  const ashtakootRows = (result?.guna_milan?.guna || []).map((guna) => ({
    id: guna.id || guna.name,
    attribute: guna.name,
    description: guna.description || ashtakootDescriptions[guna.id] || "-",
    male: guna.boy_koot,
    female: guna.girl_koot,
    outof: guna.maximum_points,
    received: guna.obtained_points,
  }));

  return (
    <div className="bg-[#f8f9fa] min-h-screen flex flex-col font-sans">
      {error && <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-xl bg-red-600 px-6 py-3 text-sm font-medium text-white shadow-lg">{error}</div>}
      <Navbar />

      <section className="relative bg-[#1E3557] text-white overflow-hidden py-24 md:py-32">
        <div className="absolute inset-0 opacity-10" style={{ backgroundImage: "radial-gradient(#D4A73C 1px, transparent 1px)", backgroundSize: "30px 30px" }}></div>
        <div className="relative max-w-7xl mx-auto px-4 md:px-8 text-center">
          <span className="inline-block text-xs bg-[#D4A73C]/20 text-[#D4A73C] border border-[#D4A73C]/30 px-4 py-1.5 rounded-full font-bold tracking-widest uppercase mb-6 shadow-sm">Horoscope Milan</span>
          <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-extrabold mb-6 leading-tight">Premium <span className="text-[#D4A73C]">Kundli Matching</span></h1>
          <p className="text-gray-300 max-w-2xl mx-auto text-lg md:text-xl leading-relaxed">Advanced compatibility now includes per-guna scoring, mangal details, and exception notes.</p>
        </div>
      </section>

      <section className="max-w-7xl mx-auto px-4 md:px-8 py-12 -mt-10 sm:-mt-16 z-10 relative">
        <form onSubmit={handleSubmit} className="bg-white rounded-3xl shadow-xl border border-gray-100 p-6 sm:p-8 md:p-12">
          <div className="text-center mb-10">
            <h2 className="text-3xl font-bold text-[#1E3557]">Enter Birth Details</h2>
            <p className="text-gray-500 mt-2">Provide accurate birth date, time, and location for precise Ashtakoota matching.</p>
          </div>
          <div className="grid md:grid-cols-2 gap-12 md:gap-16">
            {[{ title: "Boy's Details", state: boyDetails, setState: setBoyDetails, results: boySearchResults, setResults: setBoySearchResults, loading: isBoySearching, setLoading: setIsBoySearching, accent: "bg-blue-500" }, { title: "Girl's Details", state: girlDetails, setState: setGirlDetails, results: girlSearchResults, setResults: setGirlSearchResults, loading: isGirlSearching, setLoading: setIsGirlSearching, accent: "bg-pink-500" }].map((section) => (
              <div key={section.title} className="space-y-6">
                <div className="flex items-center gap-3 border-b-2 border-gray-100 pb-3 mb-6"><div className={`w-8 h-8 rounded-full ${section.accent} text-white flex items-center justify-center font-bold`}>{section.title.charAt(0)}</div><h3 className="text-xl font-bold text-[#1E3557]">{section.title}</h3></div>
                <input required type="text" value={section.state.name} onChange={(e) => section.setState((prev) => ({ ...prev, name: e.target.value }))} placeholder={`Enter ${section.title.toLowerCase().replace(" details", "")}`} className="w-full bg-gray-50 border border-gray-200 px-4 py-3 rounded-xl" />
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <input required type="date" value={section.state.dob} onChange={(e) => section.setState((prev) => ({ ...prev, dob: e.target.value }))} className="w-full bg-gray-50 border border-gray-200 px-4 py-3 rounded-xl" />
                  <input required type="time" value={section.state.time} onChange={(e) => section.setState((prev) => ({ ...prev, time: e.target.value }))} className="w-full bg-gray-50 border border-gray-200 px-4 py-3 rounded-xl" />
                </div>
                <div className="relative">
                  <input required type="text" value={section.state.place} onChange={(e) => searchBirthPlace(e.target.value, section.setState, section.setResults, section.setLoading)} placeholder="Birth Place (select from dropdown)" autoComplete="off" className="w-full bg-gray-50 border border-gray-200 px-4 py-3 rounded-xl pr-10" />
                  {section.loading && <div className="absolute right-3 top-3.5 h-4 w-4 animate-spin rounded-full border-b-2 border-orange-500"></div>}
                  {section.results.length > 0 && (
                    <div className="absolute z-50 w-full mt-1 bg-white border border-gray-200 rounded-xl shadow-xl max-h-60 overflow-y-auto">
                      {section.results.map((place, index) => <button key={`${place.name}-${index}`} type="button" onClick={() => selectLocation(place, section.setState, section.setResults)} className="block w-full border-b border-gray-50 px-4 py-2 text-left text-sm hover:bg-gray-100 last:border-0">{place.name}</button>)}
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
          <div className="mt-12 text-center pt-8 border-t border-gray-100">
            <div className="flex flex-col items-center justify-center gap-3 sm:flex-row">
              <button disabled={loading} type="submit" className="bg-[#1E3557] text-white px-12 py-4 rounded-xl font-bold text-lg hover:bg-[#162744] transition-all disabled:opacity-75">{loading ? "Matching Planets..." : "Match Horoscope Now"}</button>
              <button disabled={downloadingPdf} type="button" onClick={handleDownloadPdf} className="border border-[#1E3557] text-[#1E3557] px-12 py-4 rounded-xl font-bold text-lg hover:bg-[#1E3557] hover:text-white transition-all disabled:opacity-75">{downloadingPdf ? "Preparing PDF..." : "Get PDF Report"}</button>
            </div>
            <p className="text-sm text-gray-400 mt-4">Exact coordinates are used from the selected birthplaces.</p>
          </div>
        </form>
      </section>

      {result && (
        <section className="bg-[#f3f4f6] py-14 text-slate-700">
          <div className="mx-auto max-w-7xl px-4">
            <div className="mb-8 flex flex-col gap-4 border-b border-slate-200 bg-white px-5 py-6 shadow-sm md:flex-row md:items-center md:justify-between">
              <div>
                <h2 className="text-3xl font-black text-slate-700">
                  {girlDetails.name || "Girl"} with {boyDetails.name || "Boy"}
                </h2>
                <p className="mt-2 text-base text-slate-500">
                  {formatDate(girlDetails.dob)}, {girlDetails.time}, {girlDetails.place || "Girl birth place"}
                </p>
                <p className="mt-1 text-base text-slate-500">
                  {formatDate(boyDetails.dob)}, {boyDetails.time}, {boyDetails.place || "Boy birth place"}
                </p>
              </div>
              <button
                type="button"
                onClick={() => {
                  setResult(null);
                  setMeta(null);
                  setMatchingCharts({ boy: [], girl: [] });
                  window.scrollTo({ top: 0, behavior: "smooth" });
                }}
                className="inline-flex items-center gap-2 rounded-md border border-slate-200 bg-white px-4 py-3 text-sm font-semibold text-slate-700 shadow-sm transition hover:border-[#D4A73C] hover:text-[#1E3557]"
              >
                <FaPen /> Create New
              </button>
            </div>

            {meta?.warning && (
              <div className="mb-6 border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900">
                <p className="font-semibold">Upstream sandbox restriction detected</p>
                <p className="mt-1">{meta.warning}</p>
              </div>
            )}

            <div className="grid gap-8 lg:grid-cols-[220px_1fr]">
              <aside className="h-fit overflow-hidden rounded-sm border border-slate-200 bg-white">
                <button className="flex w-full items-center justify-between bg-slate-100 px-4 py-4 text-left text-sm font-black text-slate-900">
                  MATCH MAKING <span>⌄</span>
                </button>
                {["Basic Details", "Horoscope Chart", "Ashtakoot", "Matching Report"].map((item) => (
                  <a key={item} href={`#${item.toLowerCase().replace(/\s+/g, "-")}`} className="block border-t border-slate-200 px-4 py-4 text-sm font-medium text-slate-600 hover:bg-[#fff8df] hover:text-[#1E3557]">
                    {item}
                  </a>
                ))}
              </aside>

              <main className="space-y-8">
                <section id="basic-details">
                  <SectionTitle>Birth Details</SectionTitle>
                  <div className="grid gap-6 lg:grid-cols-[1fr_300px]">
                    <CompactTable
                      columns={[
                        { key: "male", label: "Male" },
                        { key: "label", label: "Birth Details" },
                        { key: "female", label: "Female" },
                      ]}
                      rows={birthRows}
                    />

                    <div className="border border-slate-200 bg-white">
                      <h4 className="bg-[#1E3557] px-4 py-4 text-sm font-black uppercase tracking-wide text-white">Match Summary</h4>
                      <div className="space-y-5 p-4">
                        <div>
                          <p className="font-black text-slate-900">Male Nakshatra</p>
                          <p className="text-slate-500">{getNakshatraName(boyInfo)}</p>
                        </div>
                        <div className="border-t border-slate-200 pt-4">
                          <p className="font-black text-slate-900">Female Nakshatra</p>
                          <p className="text-slate-500">{getNakshatraName(girlInfo)}</p>
                        </div>
                        <div className="border-t border-slate-200 pt-4">
                          <p className="font-black text-slate-900">Match Making Percentage</p>
                          <div className="mt-3 h-5 overflow-hidden rounded-full bg-slate-200">
                            <div className="flex h-full items-center justify-center rounded-full bg-[#1E3557] text-xs font-black text-white" style={{ width: `${Math.max(8, Math.round(Number(matchPercentage) || scorePercent))}%` }}>
                              {Math.round(Number(matchPercentage) || scorePercent)}%
                            </div>
                          </div>
                        </div>
                        <div className="border-t border-slate-200 pt-4">
                          <p className="font-black text-slate-900">Match Points</p>
                          <div className="mx-auto mt-4 flex h-24 w-24 items-center justify-center rounded-full bg-rose-700 text-2xl font-black text-white">
                            {totalPoints}/{maximumPoints}
                          </div>
                        </div>
                        <a href="#matching-report" className="block bg-[#D4A73C] px-5 py-4 text-center font-black text-[#1E3557] transition hover:bg-[#c5982d]">
                          See Detailed Report
                        </a>
                      </div>
                    </div>
                  </div>
                </section>

                <section id="horoscope-chart">
                  <SectionTitle>Birth & Divisional Charts</SectionTitle>
                  <div className="mb-8 flex justify-center">
                    <div className="inline-grid overflow-hidden rounded-sm border border-slate-200 bg-white sm:grid-cols-3">
                      {chartTabs.map((tab) => (
                        <button
                          key={tab.key}
                          type="button"
                          onClick={() => setActiveChart(tab.key)}
                          className={`border-b border-slate-200 px-8 py-4 text-sm font-semibold sm:border-b-0 sm:border-r sm:last:border-r-0 ${activeChart === tab.key ? "bg-[#fff8df] text-[#1E3557]" : "text-slate-500 hover:bg-slate-50"}`}
                        >
                          {tab.label}
                        </button>
                      ))}
                    </div>
                  </div>
                  <ChartPair
                    label={activeChartConfig.label}
                    boyName={boyDetails.name}
                    girlName={girlDetails.name}
                    boyChart={boyActiveChart}
                    girlChart={girlActiveChart}
                    loading={chartsLoading}
                  />
                </section>

                <section id="ashtakoot">
                  <SectionTitle>Ashtakoot Points</SectionTitle>
                  <CompactTable
                    columns={[
                      { key: "attribute", label: "Attribute" },
                      { key: "description", label: "Description" },
                      { key: "male", label: "Male" },
                      { key: "female", label: "Female" },
                      { key: "outof", label: "Outof" },
                      { key: "received", label: "Received" },
                    ]}
                    rows={ashtakootRows}
                    footerRow={{
                      attribute: "Total",
                      description: "-",
                      male: "-",
                      female: "-",
                      outof: maximumPoints,
                      received: totalPoints,
                    }}
                  />
                </section>

                <section id="matching-report">
                  <SectionTitle>Matching Report</SectionTitle>
                  <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-5">
                    <ScoreCircle label="Ashtakoot" value={`${totalPoints}/${maximumPoints}`} color={verdict.color} />
                    <ScoreCircle label="Male Manglik" value={result?.boy_mangal_dosha_details?.description?.replace("Manglik influence score: ", "") || "0%"} color="bg-[#1E3557]" />
                    <ScoreCircle label="Female Manglik" value={result?.girl_mangal_dosha_details?.description?.replace("Manglik influence score: ", "") || "0%"} color="bg-[#D4A73C]" />
                    <ScoreCircle label="Rajju Dosha" value={result?.exceptions?.some((item) => item.toLowerCase().includes("rajju")) ? "YES" : "NO"} color="bg-rose-500" />
                    <ScoreCircle label="Vedha Dosha" value={result?.exceptions?.some((item) => item.toLowerCase().includes("vedha")) ? "YES" : "NO"} color="bg-emerald-600" />
                  </div>

                  <div className="mt-10 rounded-sm bg-[#fff8df] p-8">
                    <h4 className={`text-3xl font-black ${verdict.text}`}>Match Conclusion</h4>
                    <p className="mt-5 max-w-4xl text-base leading-7 text-slate-700">{compatibilityMessage}</p>
                  </div>
                </section>

                <section className="rounded-sm bg-[#fff6bf] p-8 text-center">
                  <FaFilePdf className="mx-auto mb-4 text-4xl text-[#D4A73C]" />
                  <h3 className="text-3xl font-black text-[#b87b00]">Get 25 Pages Detailed Kundli Matching Report</h3>
                  <p className="mx-auto mt-5 max-w-3xl text-base leading-7 text-slate-800">
                    Kundli Horoscope Matching with ashtakoot or dashkoot milan. Detailed interpretation of each ashtakoot milan point, Manglik matching with Vedha and Rajju Dosha.
                  </p>
                  <div className="mt-5 flex flex-wrap justify-center gap-4 text-sm font-black text-[#1E3557]">
                    <span className="underline decoration-[#D4A73C] decoration-2">See Sample PDF in English</span>
                    <span className="underline decoration-[#D4A73C] decoration-2">सैंपल PDF हिंदी में देखें</span>
                  </div>
                  <button
                    type="button"
                    onClick={handleDownloadPdf}
                    disabled={downloadingPdf}
                    className="mt-8 rounded-md bg-[#1E3557] px-8 py-4 font-black text-white transition hover:bg-[#162744] disabled:opacity-60"
                  >
                    {downloadingPdf ? "Preparing PDF..." : "Get your Personalised Matching Pdf"}
                  </button>
                </section>

                <div className="grid gap-4 sm:grid-cols-2">
                  <a href="/kundli" className="rounded-md bg-[#1E3557] px-6 py-4 text-center font-black text-white transition hover:bg-[#162744]">
                    See {boyDetails.name || "Boy"} Detailed Kundli
                  </a>
                  <a href="/kundli" className="rounded-md bg-[#D4A73C] px-6 py-4 text-center font-black text-[#1E3557] transition hover:bg-[#c5982d]">
                    See {girlDetails.name || "Girl"} Detailed Kundli
                  </a>
                </div>

                <details className="rounded-sm border border-slate-200 bg-white">
                  <summary className="cursor-pointer bg-slate-100 px-4 py-4 text-sm font-black text-slate-700">
                    Additional API Details
                  </summary>
                  <div className="space-y-4 p-4">
                    {(result?.provider_sections || []).map((section) => (
                      <details key={section.id} className="rounded-sm border border-slate-200 bg-white">
                        <summary className="cursor-pointer border-b border-slate-200 px-4 py-3 font-black text-[#1E3557]">
                          {section.title}
                        </summary>
                        <div className="space-y-4 p-4">
                          {Object.entries(section.items || {}).map(([key, item]) => (
                            <details key={key} className="rounded-sm border border-slate-200 bg-white">
                              <summary className="cursor-pointer bg-[#fff8df] px-4 py-3 text-sm font-bold text-[#7a5205]">{key}</summary>
                              <div className="p-4">
                                <ReportDataBlock title={key} data={item?.data ?? item} />
                              </div>
                            </details>
                          ))}
                        </div>
                      </details>
                    ))}
                  </div>
                </details>
              </main>
            </div>
          </div>
        </section>
      )}

      <section className="bg-white py-20 border-t border-gray-100">
        <div className="max-w-7xl mx-auto px-4 md:px-8">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <span className="text-[#D4A73C] font-bold tracking-widest uppercase text-sm mb-2 block">The Importance</span>
            <h2 className="text-3xl md:text-4xl font-bold text-[#1E3557]">Why Kundli Matching?</h2>
            <p className="text-gray-500 mt-4 leading-relaxed">Janam kundli milan evaluates compatibility using birth details and the age-old Ashtakoota method.</p>
          </div>
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            {[{ title: "Compatibility", icon: <FaHeart className="text-[#D4A73C] text-2xl" />, desc: "Evaluates the couple across the traditional 36 guna score." }, { title: "Stability", icon: <FaShieldAlt className="text-[#D4A73C] text-2xl" />, desc: "Checks harmony indicators influenced by both charts." }, { title: "Expert Guidance", icon: <FaStar className="text-[#D4A73C] text-2xl" />, desc: "Surfaces strengths and risks for later astrologer review." }, { title: "Doshas", icon: <FaExclamationTriangle className="text-[#D4A73C] text-2xl" />, desc: "Shows mangal status and compatibility exceptions." }].map((card, index) => <div key={index} className="bg-[#f8f9fa] p-8 rounded-2xl hover:shadow-lg transition-all duration-300 hover:-translate-y-2 border border-gray-100 group"><div className="w-14 h-14 bg-white rounded-xl shadow-sm flex items-center justify-center mb-6 border border-gray-100 group-hover:bg-[#1E3557] group-hover:border-[#1E3557] transition-colors">{React.cloneElement(card.icon, { className: "text-[#D4A73C] text-2xl group-hover:scale-110 transition-transform" })}</div><h3 className="text-xl font-bold text-[#1E3557] mb-3">{card.title}</h3><p className="text-gray-500 text-sm leading-relaxed">{card.desc}</p></div>)}
          </div>
        </div>
      </section>

      <Footer />
    </div>
  );
}
