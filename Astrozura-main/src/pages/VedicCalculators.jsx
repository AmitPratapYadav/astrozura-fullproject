import { useEffect, useMemo, useState } from "react";
import { Link, Navigate, useSearchParams } from "react-router-dom";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import InlineInfoPopover from "../components/InlineInfoPopover";
import { getVedicCalculator, searchLocation } from "../api/prokeralaApi";
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
};

const titleize = (value) =>
  String(value || "")
    .replace(/_/g, " ")
    .replace(/\b\w/g, (match) => match.toUpperCase());

const renderPrimitive = (value) => {
  if (typeof value === "boolean") return value ? "Yes" : "No";
  if (value === null || value === undefined || value === "") return "-";
  return String(value);
};

const formatIsoTime = (value) => {
  if (!value) return Number.POSITIVE_INFINITY;
  const stamp = Date.parse(value);
  return Number.isNaN(stamp) ? Number.POSITIVE_INFINITY : stamp;
};

const getRelevantSadesatiTransits = (transits) => {
  if (!Array.isArray(transits)) return [];

  const unique = [];
  const seen = new Set();
  for (const item of transits) {
    const key = `${item?.phase || item?.name || "phase"}|${item?.start || ""}|${item?.end || ""}`;
    if (seen.has(key)) continue;
    seen.add(key);
    unique.push(item);
  }

  const sorted = [...unique].sort((left, right) => formatIsoTime(left?.start) - formatIsoTime(right?.start));
  const now = Date.now();
  const pivotIndex = sorted.findIndex((item) => formatIsoTime(item?.start) >= now);

  if (pivotIndex === -1) {
    return sorted.slice(-8);
  }

  const start = Math.max(0, pivotIndex - 2);
  return sorted.slice(start, start + 8);
};

function ResultTree({ value, label }) {
  if (value === null || value === undefined) return null;

  if (Array.isArray(value)) {
    if (!value.length) return null;
    return (
      <div className="space-y-3">
        {label && <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">{titleize(label)}</p>}
        {value.map((item, index) => (
          <div key={`${label || "item"}-${index}`} className="rounded-2xl border border-slate-100 bg-white p-4">
            <ResultTree value={item} />
          </div>
        ))}
      </div>
    );
  }

  if (typeof value === "object") {
    const entries = Object.entries(value).filter(([, child]) => child !== null && child !== undefined && child !== "");
    if (!entries.length) return null;

    return (
      <div className="space-y-4">
        {label && <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">{titleize(label)}</p>}
        <div className="grid gap-4 md:grid-cols-2">
          {entries.map(([childKey, childValue]) => {
            const isNested = Array.isArray(childValue) || typeof childValue === "object";
            return (
              <div key={childKey} className="rounded-2xl border border-slate-100 bg-[#f8f9fc] p-4">
                {isNested ? (
                  <ResultTree value={childValue} label={childKey} />
                ) : (
                  <>
                    <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-500">{titleize(childKey)}</p>
                    <p className="mt-2 text-sm font-semibold text-[#1E3557]">{renderPrimitive(childValue)}</p>
                  </>
                )}
              </div>
            );
          })}
        </div>
      </div>
    );
  }

  return (
    <div className="rounded-2xl border border-slate-100 bg-[#f8f9fc] p-4">
      {label && <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-500">{titleize(label)}</p>}
      <p className="mt-2 text-sm font-semibold text-[#1E3557]">{renderPrimitive(value)}</p>
    </div>
  );
}

export default function VedicCalculators() {
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
    () => vedicCalculatorTools.filter((item) => item.key !== toolKey).slice(0, 6),
    [toolKey]
  );

  useEffect(() => {
    setResult(null);
    setToast("");
    setSearchResults([]);
  }, [toolKey]);

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
          ? `${form.date_of_birth}T${form.time_of_birth || "12:00"}:00+05:30`
          : undefined;

      const payload = {
        datetime,
        coordinates: form.coordinates || undefined,
        ayanamsa: Number(form.ayanamsa),
        la: form.language,
        year: tool.requiresYear ? Number(form.year) : undefined,
        planet: tool.requiresPlanet ? Number(form.planet) : undefined,
        chart_style: tool.requiresChartStyle || tool.hasCompanionChart ? form.chart_style : undefined,
        detailed_report: tool.supportsAdvanced ? form.detailed_report : undefined,
        planets: tool.key === "planet-position" && form.planets.trim() ? form.planets.trim() : undefined,
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

  const primaryResult = useMemo(() => {
    if (tool.hasCompanionChart && result?.data?.chart_data) return result.data.chart_data;
    return result?.data || null;
  }, [result, tool.hasCompanionChart]);

  const svgMarkup = useMemo(() => {
    const raw = result?.data?.svg || result?.data?.chart_svg || result?.data;
    return typeof raw === "string" && raw.trim().startsWith("<svg") ? raw : null;
  }, [result]);

  const displayResult = useMemo(() => {
    if (!result?.data || tool.key !== "sade-sati") return result?.data;
    const relevantTransits = getRelevantSadesatiTransits(result.data.transits);
    return {
      ...result.data,
      transits: relevantTransits,
      hidden_transit_count: Math.max((result.data.transits?.length || 0) - relevantTransits.length, 0),
    };
  }, [result, tool.key]);

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

                  {svgMarkup && (
                    <div className="mt-6 rounded-3xl border border-slate-100 bg-[#f8f9fc] p-4">
                      <div dangerouslySetInnerHTML={{ __html: svgMarkup }} />
                    </div>
                  )}

                  {tool.hasCompanionChart && result?.data?.chart_svg && (
                    <div className="mt-6 rounded-3xl border border-slate-100 bg-[#f8f9fc] p-4">
                      <p className="mb-4 text-xs font-semibold uppercase tracking-[0.16em] text-slate-500">Chart Output</p>
                      <div dangerouslySetInnerHTML={{ __html: result.data.chart_svg }} />
                    </div>
                  )}

                  {tool.hasCompanionChart && primaryResult && (
                    <div className="mt-6">
                      <ResultTree value={primaryResult} />
                    </div>
                  )}

                  {tool.key === "sade-sati" && displayResult?.hidden_transit_count > 0 && (
                    <div className="mt-5 rounded-2xl border border-slate-100 bg-[#f8f9fc] px-4 py-3 text-sm text-slate-600">
                      Showing the most relevant recent and upcoming Sade Sati phase changes. {displayResult.hidden_transit_count} older transit entries were hidden to keep the report readable.
                    </div>
                  )}

                  {!svgMarkup && !tool.hasCompanionChart && (
                    <div className="mt-6 max-h-[72vh] overflow-y-auto pr-1">
                      <ResultTree value={displayResult} />
                    </div>
                  )}
                </div>

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
