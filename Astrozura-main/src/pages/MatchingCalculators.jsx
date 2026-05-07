import { useEffect, useMemo, useState } from "react";
import { Link, Navigate, useSearchParams } from "react-router-dom";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { getMatchingCalculator, searchLocation } from "../api/prokeralaApi";
import {
  AYANAMSA_OPTIONS,
  NAKSHATRA_OPTIONS,
  getMatchingCalculatorTool,
  matchingCalculatorTools,
} from "../data/astrologyTools";

const emptyPerson = {
  name: "",
  dob: "",
  time: "",
  place: "",
  coordinates: "",
  nakshatra: 0,
  nakshatra_pada: 1,
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

export default function MatchingCalculators() {
  const [searchParams] = useSearchParams();
  const toolKey = searchParams.get("tool") || "nakshatra-porutham";
  const tool = getMatchingCalculatorTool(toolKey);

  const [girl, setGirl] = useState(emptyPerson);
  const [boy, setBoy] = useState(emptyPerson);
  const [girlResults, setGirlResults] = useState([]);
  const [boyResults, setBoyResults] = useState([]);
  const [loadingGirlPlaces, setLoadingGirlPlaces] = useState(false);
  const [loadingBoyPlaces, setLoadingBoyPlaces] = useState(false);
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState("");
  const [result, setResult] = useState(null);
  const [settings, setSettings] = useState({
    ayanamsa: 1,
    language: "en",
    detailed_report: false,
    system: "tamil",
  });

  const suggestedTools = useMemo(
    () => matchingCalculatorTools.filter((item) => item.key !== toolKey).slice(0, 4),
    [toolKey]
  );

  useEffect(() => {
    setResult(null);
    setToast("");
    setGirlResults([]);
    setBoyResults([]);
  }, [toolKey]);

  if (!tool) {
    return <Navigate to="/services" replace />;
  }

  if (tool.externalFlow) {
    return <Navigate to={tool.route} replace />;
  }

  const searchBirthPlace = async (value, setPerson, setResults, setLoadingPlaces) => {
    setPerson((prev) => ({ ...prev, place: value, coordinates: "" }));
    if (value.trim().length < 3) {
      setResults([]);
      return;
    }

    try {
      setLoadingPlaces(true);
      const response = await searchLocation(value.trim(), settings.language);
      setResults(response?.data || []);
    } catch {
      setResults([]);
    } finally {
      setLoadingPlaces(false);
    }
  };

  const selectLocation = (place, setPerson, setResults) => {
    setPerson((prev) => ({
      ...prev,
      place: place.name,
      coordinates: `${place.coordinates.latitude},${place.coordinates.longitude}`,
    }));
    setResults([]);
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (tool.usesNakshatraInputs) {
      if (!Number.isInteger(Number(girl.nakshatra_pada)) || !Number.isInteger(Number(boy.nakshatra_pada))) {
        setToast("Valid nakshatra pada values are required.");
        return;
      }
    }

    if (tool.usesBirthProfiles && (!girl.coordinates || !boy.coordinates)) {
      setToast("Select valid birthplaces from the dropdown for both profiles.");
      return;
    }

    try {
      setLoading(true);
      setResult(null);
      setToast("");

      const payload = tool.usesNakshatraInputs
        ? {
            girl_nakshatra: Number(girl.nakshatra),
            girl_nakshatra_pada: Number(girl.nakshatra_pada),
            boy_nakshatra: Number(boy.nakshatra),
            boy_nakshatra_pada: Number(boy.nakshatra_pada),
            detailed_report: tool.supportsAdvanced ? settings.detailed_report : undefined,
            la: settings.language,
          }
        : {
            girl_coordinates: girl.coordinates,
            girl_dob: `${girl.dob}T${girl.time || "12:00"}:00+05:30`,
            boy_coordinates: boy.coordinates,
            boy_dob: `${boy.dob}T${boy.time || "12:00"}:00+05:30`,
            ayanamsa: Number(settings.ayanamsa),
            system: tool.requiresSystem ? settings.system : undefined,
            detailed_report: tool.supportsAdvanced ? settings.detailed_report : undefined,
            la: settings.language,
          };

      const response = await getMatchingCalculator(tool.key, payload);
      if (response?.status === "success") {
        setResult(response);
        setToast("Matching calculator result generated successfully.");
        return;
      }

      setToast(response?.message || "Unable to generate matching result.");
    } catch (error) {
      setToast(error?.response?.data?.message || "Unable to generate matching result.");
    } finally {
      setLoading(false);
    }
  };

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
            Marriage Calculator
          </span>
          <h1 className="mt-6 max-w-4xl text-4xl font-black md:text-5xl">{tool.title}</h1>
          <p className="mt-5 max-w-3xl text-sm leading-7 text-white/85 md:text-base">{tool.description}</p>
        </div>
      </section>

      <section className="relative z-10 mx-auto -mt-14 max-w-7xl px-4 pb-16 md:-mt-16 md:px-8">
        <div className="grid gap-8 xl:grid-cols-[440px_minmax(0,1fr)]">
          <aside className="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm">
            <h2 className="text-2xl font-bold">Matching Inputs</h2>
            <p className="mt-2 text-sm text-slate-500">Use the exact input pattern required by the selected Astrology API matching service.</p>

            <form onSubmit={handleSubmit} className="mt-6 space-y-6">
              <div className="grid gap-4 sm:grid-cols-2">
                <div>
                  <label className="mb-2 block text-sm font-semibold text-slate-600">Language</label>
                  <select
                    value={settings.language}
                    onChange={(event) => setSettings((current) => ({ ...current, language: event.target.value }))}
                    className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  >
                    <option value="en">English</option>
                    <option value="hi">Hindi</option>
                    <option value="ta">Tamil</option>
                    <option value="ml">Malayalam</option>
                  </select>
                </div>

                {tool.usesBirthProfiles && (
                  <div>
                    <label className="mb-2 block text-sm font-semibold text-slate-600">Ayanamsa</label>
                    <select
                      value={settings.ayanamsa}
                      onChange={(event) => setSettings((current) => ({ ...current, ayanamsa: event.target.value }))}
                      className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                    >
                      {AYANAMSA_OPTIONS.map((option) => (
                        <option key={option.value} value={option.value}>
                          {option.label}
                        </option>
                      ))}
                    </select>
                  </div>
                )}
              </div>

              {tool.requiresSystem && (
                <div>
                  <label className="mb-2 block text-sm font-semibold text-slate-600">Porutham System</label>
                  <select
                    value={settings.system}
                    onChange={(event) => setSettings((current) => ({ ...current, system: event.target.value }))}
                    className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  >
                    <option value="tamil">Tamil</option>
                    <option value="kerala">Kerala</option>
                  </select>
                </div>
              )}

              {tool.supportsAdvanced && (
                <label className="flex items-center gap-3 rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-4 text-sm font-medium text-slate-700">
                  <input
                    type="checkbox"
                    checked={settings.detailed_report}
                    onChange={(event) => setSettings((current) => ({ ...current, detailed_report: event.target.checked }))}
                  />
                  Use advanced detailed report
                </label>
              )}

              {[{ label: "Girl", person: girl, setPerson: setGirl, results: girlResults, setResults: setGirlResults, setLoadingPlaces: setLoadingGirlPlaces, loadingPlaces: loadingGirlPlaces }, { label: "Boy", person: boy, setPerson: setBoy, results: boyResults, setResults: setBoyResults, setLoadingPlaces: setLoadingBoyPlaces, loadingPlaces: loadingBoyPlaces }].map((section) => (
                <div key={section.label} className="space-y-4 rounded-3xl border border-slate-100 bg-[#fbfcfe] p-5">
                  <h3 className="text-lg font-bold">{section.label} Profile</h3>

                  {tool.usesNakshatraInputs ? (
                    <>
                      <div>
                        <label className="mb-2 block text-sm font-semibold text-slate-600">Nakshatra</label>
                        <select
                          value={section.person.nakshatra}
                          onChange={(event) => section.setPerson((current) => ({ ...current, nakshatra: event.target.value }))}
                          className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                        >
                          {NAKSHATRA_OPTIONS.map((option) => (
                            <option key={option.value} value={option.value}>
                              {option.label}
                            </option>
                          ))}
                        </select>
                      </div>
                      <div>
                        <label className="mb-2 block text-sm font-semibold text-slate-600">Pada</label>
                        <select
                          value={section.person.nakshatra_pada}
                          onChange={(event) => section.setPerson((current) => ({ ...current, nakshatra_pada: event.target.value }))}
                          className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                        >
                          {[1, 2, 3, 4].map((pada) => (
                            <option key={pada} value={pada}>
                              Pada {pada}
                            </option>
                          ))}
                        </select>
                      </div>
                    </>
                  ) : (
                    <>
                      <input
                        type="text"
                        value={section.person.name}
                        onChange={(event) => section.setPerson((current) => ({ ...current, name: event.target.value }))}
                        placeholder={`${section.label} name`}
                        className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                      />
                      <div className="grid gap-4 sm:grid-cols-2">
                        <input
                          type="date"
                          value={section.person.dob}
                          onChange={(event) => section.setPerson((current) => ({ ...current, dob: event.target.value }))}
                          className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                        />
                        <input
                          type="time"
                          value={section.person.time}
                          onChange={(event) => section.setPerson((current) => ({ ...current, time: event.target.value }))}
                          className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                        />
                      </div>
                      <div className="relative">
                        <input
                          type="text"
                          value={section.person.place}
                          onChange={(event) =>
                            searchBirthPlace(
                              event.target.value,
                              section.setPerson,
                              section.setResults,
                              section.setLoadingPlaces
                            )
                          }
                          placeholder={`${section.label} birthplace`}
                          className="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 pr-10 text-sm outline-none focus:border-[#D4A73C]"
                        />
                        {section.loadingPlaces && <div className="absolute right-4 top-4 h-4 w-4 animate-spin rounded-full border-b-2 border-[#D4A73C]" />}
                        {section.results.length > 0 && (
                          <div className="absolute z-20 mt-1 max-h-60 w-full overflow-y-auto rounded-2xl border border-slate-200 bg-white shadow-xl">
                            {section.results.map((place, index) => (
                              <button
                                key={`${place.name}-${index}`}
                                type="button"
                                onClick={() => selectLocation(place, section.setPerson, section.setResults)}
                                className="block w-full border-b border-slate-50 px-4 py-3 text-left text-sm hover:bg-slate-50 last:border-0"
                              >
                                {place.name}
                              </button>
                            ))}
                          </div>
                        )}
                      </div>
                    </>
                  )}
                </div>
              ))}

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
                <h2 className="text-2xl font-bold">Ready to Match</h2>
                <p className="mt-3 max-w-2xl text-sm leading-7 text-slate-500">
                  This page runs the dedicated Astrology API matching calculator selected from the Reports menu or All Services page.
                </p>
              </div>
            ) : (
              <div className="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm">
                <div className="flex flex-wrap items-start justify-between gap-4">
                  <div>
                    <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[#D4A73C]">Marriage Matching</p>
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
                  <ResultTree value={result.data} />
                </div>
              </div>
            )}

            {suggestedTools.length > 0 && (
              <div className="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm">
                <h3 className="text-xl font-bold">More Marriage Calculators</h3>
                <div className="mt-5 grid gap-4 md:grid-cols-2">
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
          </main>
        </div>
      </section>

      <Footer />
    </div>
  );
}
