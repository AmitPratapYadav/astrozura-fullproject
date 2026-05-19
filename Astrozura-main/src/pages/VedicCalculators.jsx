import { useEffect, useMemo, useState } from "react";
import { Link, Navigate, useSearchParams } from "react-router-dom";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import InlineInfoPopover from "../components/InlineInfoPopover";
import { ProviderSections, ReportDataBlock } from "../components/report/ReportDataRenderer";
import { KeyValueTable, ReportPanel } from "../components/report/ReportTables";
import { getVedicCalculator, searchLocation } from "../api/prokeralaApi";
import { useAuth } from "../context/AuthContext";
import {
  AYANAMSA_OPTIONS,
  CHART_STYLE_OPTIONS,
  PLANET_OPTIONS,
  getVedicCalculatorTool,
  vedicCalculatorTools,
} from "../data/astrologyTools";

const initialForm = {
  date_of_birth: "",
  time_of_birth: "",
  place_of_birth: "",
  coordinates: "",
  ayanamsa: 1,
  language: "en",
  year: String(new Date().getFullYear()),
  planet: 0,
  chart_style: "north-indian",
  detailed_report: false,
  planets: "",
  mahadasha: "",
  antardasha: "",
  pratyantardasha: "",
  sookshma_dasha: "",
  dasha_cycle: "",
  dasha_name: "",
};

const buildKolkataDatetime = (date, time) => {
  const [hour = "12", minute = "00", second = "00"] = String(time || "12:00").split(":");
  return `${date}T${hour.padStart(2, "0")}:${minute.padStart(2, "0")}:${second.padStart(2, "0")}+05:30`;
};

export default function VedicCalculators() {
  const { user } = useAuth();
  const [searchParams] = useSearchParams();
  const toolKey = searchParams.get("tool") || "mangal-dosha";
  const tool = getVedicCalculatorTool(toolKey);

  const [form, setForm] = useState(initialForm);
  const [searchResults, setSearchResults] = useState([]);
  const [loadingPlaces, setLoadingPlaces] = useState(false);
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState("");
  const [result, setResult] = useState(null);

  const suggestedTools = useMemo(
    () => vedicCalculatorTools.filter((item) => item.key !== toolKey && !item.hideFromCalculators).slice(0, 6),
    [toolKey]
  );

  useEffect(() => {
    setResult(null);
    setToast("");
    setSearchResults([]);
  }, [toolKey]);

  useEffect(() => {
    if (!toast) return undefined;

    window.clearTimeout(window.__astrozuraVedicCalculatorToast);
    window.__astrozuraVedicCalculatorToast = window.setTimeout(() => setToast(""), 3200);

    return () => window.clearTimeout(window.__astrozuraVedicCalculatorToast);
  }, [toast]);

  useEffect(() => {
    if (!user) return;

    const latitude = user.latitude || user.lat || user.birth_latitude;
    const longitude = user.longitude || user.lon || user.birth_longitude;
    const coordinates = latitude && longitude ? `${latitude},${longitude}` : "";

    setForm((current) => ({
      ...current,
      date_of_birth: current.date_of_birth || user.date_of_birth || user.dob || "",
      time_of_birth: current.time_of_birth || user.time_of_birth || user.birth_time || "",
      place_of_birth: current.place_of_birth || user.place_of_birth || user.birth_place || user.city || "",
      coordinates: current.coordinates || coordinates,
    }));
  }, [user]);

  if (!tool) {
    return <Navigate to="/services" replace />;
  }

  if (tool.externalFlow) {
    return <Navigate to={tool.route} replace />;
  }

  const handleChange = (event) => {
    const { name, value, type, checked } = event.target;
    setForm((current) => ({
      ...current,
      [name]: type === "checkbox" ? checked : value,
    }));
  };

  const searchBirthPlace = async (value) => {
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

    if (tool.requiresDate && !form.date_of_birth) {
      setToast("Date of birth is required.");
      return;
    }

    if (tool.requiresLocation && !form.coordinates) {
      setToast("Select a valid birthplace from the dropdown.");
      return;
    }

    try {
      setLoading(true);
      setToast("");
      setResult(null);

      const datetime =
        tool.requiresDate && form.date_of_birth
          ? buildKolkataDatetime(form.date_of_birth, form.time_of_birth)
          : undefined;

      const payload = {
        datetime,
        coordinates: form.coordinates || undefined,
        ayanamsa: Number(form.ayanamsa),
        la: form.language,
        year: tool.requiresYear ? Number(form.year) : undefined,
        planet: tool.requiresPlanet ? Number(form.planet) : undefined,
        chart_style: tool.requiresChartStyle || tool.hasCompanionChart || tool.key === "planet-position" ? form.chart_style : undefined,
        detailed_report: tool.supportsAdvanced ? form.detailed_report : undefined,
        planets: tool.key === "planet-position" && form.planets.trim() ? form.planets.trim() : undefined,
        mahadasha: form.mahadasha.trim() || undefined,
        antardasha: form.antardasha.trim() || undefined,
        pratyantardasha: form.pratyantardasha.trim() || undefined,
        sookshma_dasha: form.sookshma_dasha.trim() || undefined,
        dasha_cycle: form.dasha_cycle.trim() || undefined,
        dasha_name: form.dasha_name.trim() || undefined,
      };

      const response = await getVedicCalculator(tool.key, payload);
      if (response?.status === "success") {
        setResult(response);
        setToast("Calculator result generated successfully.");
        return;
      }

      setToast(response?.message || "Unable to generate calculator result.");
    } catch (error) {
      setToast(error?.response?.data?.message || "Unable to generate calculator result.");
    } finally {
      setLoading(false);
    }
  };

  const providerSections = result?.data?.provider_sections || result?.provider_sections || [];
  const providerPayload = result?.data?.provider_payload || {};

  return (
    <div className="min-h-screen bg-[#f7f8fb] text-[#1E3557]">
      {toast && (
        <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-xl bg-[#1E3557] px-6 py-3 text-sm font-medium text-white shadow-lg">
          {toast}
        </div>
      )}

      <Navbar />

      <section className={`relative overflow-hidden bg-gradient-to-r pb-28 pt-20 text-white md:pb-32 ${tool.accent}`}>
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(255,255,255,0.16),transparent_24%),linear-gradient(135deg,rgba(255,255,255,0.06),rgba(255,255,255,0))]" />
        <div className="relative mx-auto max-w-7xl px-4 md:px-8">
          <span className="inline-flex rounded-full border border-white/25 bg-white/10 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.18em]">
            Vedic Calculator
          </span>
          <h1 className="mt-6 max-w-4xl text-4xl font-black md:text-5xl">{tool.title}</h1>
          <p className="mt-5 max-w-3xl text-sm leading-7 text-white/85 md:text-base">{tool.description}</p>
        </div>
      </section>

      <section className="relative z-10 mx-auto -mt-14 max-w-7xl px-4 pb-16 md:-mt-16 md:px-8">
        <div className="grid gap-8 xl:grid-cols-[420px_minmax(0,1fr)]">
          <aside className="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm">
            <h2 className="text-2xl font-bold">Calculator Inputs</h2>
            <p className="mt-2 text-sm text-slate-500">This tool uses the exact parameter contract from the active Astrology API calculator mapping.</p>

            <form onSubmit={handleSubmit} className="mt-6 space-y-5">
              {tool.requiresDate && (
                <>
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
                </>
              )}

              {tool.requiresLocation && (
                <div className="relative">
                  <label className="mb-2 block text-sm font-semibold text-slate-600">Birth Place</label>
                  <input
                    type="text"
                    value={form.place_of_birth}
                    onChange={(event) => searchBirthPlace(event.target.value)}
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
              )}

              <div>
                <label className="mb-2 flex items-center gap-2 text-sm font-semibold text-slate-600">
                  <span>Ayanamsa</span>
                  <InlineInfoPopover
                    title="Which Ayanamsa should I use?"
                    content="Use Lahiri unless an astrologer specifically asks for Raman or Krishnamurti. Ayanamsa is the sidereal reference system used for chart calculations."
                  />
                </label>
                <select
                  name="ayanamsa"
                  value={form.ayanamsa}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                >
                  {AYANAMSA_OPTIONS.map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="mb-2 block text-sm font-semibold text-slate-600">Language</label>
                <select
                  name="language"
                  value={form.language}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                >
                  <option value="en">English</option>
                  <option value="hi">Hindi</option>
                  <option value="ta">Tamil</option>
                  <option value="ml">Malayalam</option>
                  <option value="te">Telugu</option>
                </select>
              </div>

              {tool.requiresYear && (
                <div>
                  <label className="mb-2 block text-sm font-semibold text-slate-600">Reference Year</label>
                  <input
                    type="number"
                    name="year"
                    value={form.year}
                    onChange={handleChange}
                    min="1900"
                    max="2100"
                    className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  />
                </div>
              )}

              {tool.requiresPlanet && (
                <div>
                  <label className="mb-2 block text-sm font-semibold text-slate-600">Planet</label>
                  <select
                    name="planet"
                    value={form.planet}
                    onChange={handleChange}
                    className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  >
                    {PLANET_OPTIONS.map((option) => (
                      <option key={option.value} value={option.value}>
                        {option.label}
                      </option>
                    ))}
                  </select>
                </div>
              )}

              {(tool.requiresChartStyle || tool.hasCompanionChart) && (
                <div>
                  <label className="mb-2 block text-sm font-semibold text-slate-600">Chart Style</label>
                  <select
                    name="chart_style"
                    value={form.chart_style}
                    onChange={handleChange}
                    className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  >
                    {CHART_STYLE_OPTIONS.map((option) => (
                      <option key={option.value} value={option.value}>
                        {option.label}
                      </option>
                    ))}
                  </select>
                </div>
              )}

              {tool.key === "planet-position" && (
                <div>
                  <label className="mb-2 block text-sm font-semibold text-slate-600">Specific Planets</label>
                  <input
                    type="text"
                    name="planets"
                    value={form.planets}
                    onChange={handleChange}
                    placeholder="Optional comma separated list"
                    className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  />
                </div>
              )}

              {tool.supportsDashaParams && (
                <div className="rounded-2xl border border-slate-200 bg-[#f8f9fc] p-4">
                  <p className="text-sm font-bold text-slate-700">Optional Dasha Sub-period Inputs</p>
                  <p className="mt-1 text-xs leading-5 text-slate-500">
                    Leave blank to generate the core dasha report. Fill these when you want the parameterized sub-period APIs.
                  </p>
                  <div className="mt-4 space-y-3">
                    <input
                      type="text"
                      name="mahadasha"
                      value={form.mahadasha}
                      onChange={handleChange}
                      placeholder="Mahadasha, e.g. Mars"
                      className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                    />
                    <input
                      type="text"
                      name="antardasha"
                      value={form.antardasha}
                      onChange={handleChange}
                      placeholder="Antardasha, e.g. Rahu"
                      className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                    />
                    <input
                      type="text"
                      name="pratyantardasha"
                      value={form.pratyantardasha}
                      onChange={handleChange}
                      placeholder="Pratyantardasha"
                      className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                    />
                    <input
                      type="text"
                      name="sookshma_dasha"
                      value={form.sookshma_dasha}
                      onChange={handleChange}
                      placeholder="Sookshma Dasha"
                      className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                    />
                  </div>
                </div>
              )}

              {tool.supportsYoginiParams && (
                <div className="rounded-2xl border border-slate-200 bg-[#f8f9fc] p-4">
                  <p className="text-sm font-bold text-slate-700">Optional Yogini Sub-period Inputs</p>
                  <div className="mt-4 space-y-3">
                    <input
                      type="text"
                      name="dasha_cycle"
                      value={form.dasha_cycle}
                      onChange={handleChange}
                      placeholder="Dasha cycle"
                      className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                    />
                    <input
                      type="text"
                      name="dasha_name"
                      value={form.dasha_name}
                      onChange={handleChange}
                      placeholder="Dasha name"
                      className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                    />
                  </div>
                </div>
              )}

              {tool.supportsAdvanced && (
                <label className="flex items-center gap-3 rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-4 text-sm font-medium text-slate-700">
                  <input
                    type="checkbox"
                    name="detailed_report"
                    checked={form.detailed_report}
                    onChange={handleChange}
                  />
                  Use advanced detailed report
                </label>
              )}

              <button
                type="submit"
                disabled={loading}
                className="w-full rounded-2xl bg-[#D4A73C] px-5 py-3 text-sm font-bold text-[#1E3557] transition hover:bg-[#e0b84f] disabled:opacity-60"
              >
                {loading ? "Calculating..." : `Run ${tool.title}`}
              </button>
            </form>
          </aside>

          <main className="space-y-6">
            {!result ? (
              <div className="rounded-3xl border border-slate-100 bg-white p-10 shadow-sm">
                <h2 className="text-2xl font-bold">Ready to Calculate</h2>
                <p className="mt-3 max-w-2xl text-sm leading-7 text-slate-500">
                  Use this page to run live Astrology API-backed Vedic calculators with the inputs required by the selected tool.
                </p>
              </div>
            ) : (
              <>
                <div className="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm">
                  <div className="flex flex-wrap items-start justify-between gap-4">
                    <div>
                      <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[#D4A73C]">Vedic Astrology</p>
                      <h2 className="mt-2 text-2xl font-bold">{tool.title}</h2>
                    </div>
                    {result.meta?.is_sandbox_demo && (
                      <span className="rounded-full bg-amber-50 px-4 py-2 text-xs font-semibold uppercase tracking-wide text-amber-700">
                        Sandbox
                      </span>
                    )}
                  </div>

                  {result.meta?.warning && (
                    <div className="mt-5 rounded-2xl border border-amber-100 bg-amber-50 px-4 py-4 text-sm text-amber-900">
                      {result.meta.warning}
                    </div>
                  )}

                  <div className="mt-6">
                    <KeyValueTable
                      rows={[
                        ["Calculator", tool.title],
                        ["Language", form.language],
                        ["Birth Place", form.place_of_birth || "-"],
                        ["Coordinates", form.coordinates || "-"],
                      ]}
                    />
                  </div>
                </div>

                {providerSections.length > 0 ? (
                  <ProviderSections sections={providerSections} />
                ) : (
                  <ReportPanel title="Detailed Result" subtitle="Complete response returned by the backend.">
                    <ReportDataBlock title="Result" data={result?.data} />
                  </ReportPanel>
                )}

                {Object.keys(providerPayload || {}).length > 0 && providerSections.length === 0 && (
                  <ReportPanel title="Provider Payload">
                    <ReportDataBlock title="Provider Payload" data={providerPayload} />
                  </ReportPanel>
                )}

                {suggestedTools.length > 0 && (
                  <div className="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm">
                    <h3 className="text-xl font-bold">More Vedic Calculators</h3>
                    <div className="mt-5 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
                      {suggestedTools.map((item) => (
                        <Link
                          key={item.key}
                          to={item.route}
                          className="rounded-2xl border border-slate-100 bg-[#f8f9fc] p-4 transition hover:-translate-y-1 hover:shadow-md"
                        >
                          <p className="font-semibold text-[#1E3557]">{item.title}</p>
                          <p className="mt-2 text-sm text-slate-500">{item.summary}</p>
                        </Link>
                      ))}
                    </div>
                  </div>
                )}
              </>
            )}
          </main>
        </div>
      </section>

      <Footer />
    </div>
  );
}
