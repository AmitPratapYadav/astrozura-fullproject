import React, { useState } from "react";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { FaExclamationTriangle, FaHeart, FaShieldAlt, FaStar } from "react-icons/fa";
import { downloadMatchMakingPdf, getMarriageMatching, searchLocation } from "../api/prokeralaApi";
import { KeyValueTable, ReportPanel, ReportTable, SimpleTextTable } from "../components/report/ReportTables";
import { ProviderSections } from "../components/report/ReportDataRenderer";

const emptyPerson = { name: "", dob: "", time: "", place: "", coordinates: "" };

const verdictStyles = {
  good: { box: "bg-emerald-50 border-emerald-100", text: "text-emerald-800", label: "Auspicious" },
  average: { box: "bg-amber-50 border-amber-100", text: "text-amber-800", label: "Mixed" },
  bad: { box: "bg-red-50 border-red-100", text: "text-red-800", label: "Needs Review" },
};

export default function Matching() {
  const [boyDetails, setBoyDetails] = useState(emptyPerson);
  const [girlDetails, setGirlDetails] = useState(emptyPerson);
  const [boySearchResults, setBoySearchResults] = useState([]);
  const [girlSearchResults, setGirlSearchResults] = useState([]);
  const [isBoySearching, setIsBoySearching] = useState(false);
  const [isGirlSearching, setIsGirlSearching] = useState(false);
  const [loading, setLoading] = useState(false);
  const [downloadingPdf, setDownloadingPdf] = useState(false);
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
      setError("");
      const boyDatetime = `${boyDetails.dob}T${boyDetails.time}:00+05:30`;
      const girlDatetime = `${girlDetails.dob}T${girlDetails.time}:00+05:30`;
      const response = await getMarriageMatching(girlDetails.coordinates, girlDatetime, boyDetails.coordinates, boyDatetime);
      if (response?.status === "success" && response?.data) {
        setResult(response.data);
        setMeta(response.meta || null);
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

  const renderPersonCard = (title, accent, personResult, personDetails, mangalDetails) => (
    <ReportPanel
      title={`${title} Birth Details`}
      subtitle={personDetails.place || "Birthplace selected above"}
      actions={<span className={`inline-flex h-8 w-8 items-center justify-center rounded-full ${accent} text-sm font-bold text-white`}>{title.charAt(0)}</span>}
    >
      <KeyValueTable
        rows={[
          ["Name", personDetails.name || title],
          ["Birth Date", personDetails.dob],
          ["Birth Time", personDetails.time],
          ["Birth Place", personDetails.place],
          ["Nakshatra", personResult?.nakshatra?.name],
          ["Pada", personResult?.nakshatra?.pada],
          ["Nakshatra Lord", personResult?.nakshatra?.lord?.name],
          ["Rashi", personResult?.rasi?.name],
          ["Rashi Lord", personResult?.rasi?.lord?.name],
          ["Varna", personResult?.koot?.varna],
          ["Gana", personResult?.koot?.gana],
          ["Nadi", personResult?.koot?.nadi],
        ]}
      />
      {mangalDetails && (
        <div className="mt-4">
          <KeyValueTable
            columns={1}
            rows={[
              ["Mangal Dosha", mangalDetails.has_dosha ? `${mangalDetails.dosha_type || "Manglik"} Manglik` : "No Mangal Dosha"],
              ["Description", mangalDetails.description],
            ]}
          />
        </div>
      )}
    </ReportPanel>
  );

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
        <section className="bg-[#f6f6f6] py-16 text-gray-800">
          <div className="mx-auto max-w-6xl space-y-6 px-4">
            <div className="rounded-sm border border-gray-200 bg-white shadow-sm">
              <div className="border-b border-gray-200 bg-white px-5 py-5">
                <h2 className="text-2xl font-bold text-gray-950">Match Making Report</h2>
                <p className="mt-1 text-sm text-gray-500">{boyDetails.name || "Boy"} and {girlDetails.name || "Girl"}</p>
              </div>
              <div className="p-4">
                {meta?.warning && <div className="mb-4 border border-amber-200 bg-amber-50 p-3 text-sm text-amber-900"><p className="font-semibold">Upstream sandbox restriction detected</p><p className="mt-1">{meta.warning}</p></div>}
                <ReportTable
                  columns={[
                    { key: "score", label: "Total Score" },
                    { key: "percentage", label: "Percentage" },
                    { key: "verdict", label: "Verdict" },
                    { key: "summary", label: "Summary" },
                  ]}
                  rows={[{
                    score: `${totalPoints} / ${maximumPoints}`,
                    percentage: `${Math.round(scorePercent)}%`,
                    verdict: verdict.label,
                    summary: compatibilityMessage,
                  }]}
                />
              </div>
            </div>

            <div className="grid gap-6 lg:grid-cols-2">
              {renderPersonCard("Boy", "bg-blue-500", result?.boy_info, boyDetails, result?.boy_mangal_dosha_details)}
              {renderPersonCard("Girl", "bg-pink-500", result?.girl_info, girlDetails, result?.girl_mangal_dosha_details)}
            </div>

            {Array.isArray(result?.exceptions) && result.exceptions.length > 0 && (
              <ReportPanel title="Compatibility Exceptions">
                <SimpleTextTable title="Exception" items={result.exceptions} />
              </ReportPanel>
            )}

            {Array.isArray(result?.guna_milan?.guna) && result.guna_milan.guna.length > 0 && (
              <ReportPanel title="Detailed Guna Breakdown" subtitle="Ashtakoota score table">
                <ReportTable
                  columns={[
                    { key: "name", label: "Guna" },
                    { key: "girl_koot", label: "Girl Koot" },
                    { key: "boy_koot", label: "Boy Koot" },
                    { key: "points", label: "Points" },
                    { key: "description", label: "Description" },
                  ]}
                  rows={result.guna_milan.guna.map((guna) => ({
                    ...guna,
                    points: `${guna.obtained_points ?? 0} / ${guna.maximum_points ?? 0}`,
                  }))}
                />
              </ReportPanel>
            )}

            <ProviderSections sections={result?.provider_sections || []} />
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
