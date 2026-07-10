import { useEffect, useMemo, useState } from "react";
import { useSearchParams } from "react-router-dom";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { getPanchang, getPanchangExtras, searchLocation } from "../api/prokeralaApi";
import { useAuth } from "../context/AuthContext";

const VIEW_CONFIG = {
  chaughadiya: {
    label: "Chaughadiya Muhurata",
    title: "Chaughadiya Muhurta",
    intro:
      "The following Chaughadiya periods are shown for the selected date and place. These windows are commonly used to judge auspicious, inauspicious and neutral activity timings.",
  },
  hora: {
    label: "Hora Muhurata",
    title: "Hora Muhurta",
    intro:
      "The following Hora Muhurta are shown for the selected date and place. Hora periods are calculated from sunrise and sunset to guide planetary hour selection.",
  },
  daily: {
    label: "Daily Panchang",
    title: "Panchang",
    intro:
      "Daily Panchang combines tithi, nakshatra, yoga, karana, sunrise, sunset and important timing windows for the selected date and place.",
  },
};

const LANGUAGE_OPTIONS = [
  { value: "en", label: "English" },
  { value: "hi", label: "Hindi" },
  { value: "ta", label: "Tamil" },
  { value: "te", label: "Telugu" },
  { value: "ml", label: "Malayalam" },
];

const getTodayInIndia = () =>
  new Intl.DateTimeFormat("sv-SE", { timeZone: "Asia/Kolkata" }).format(new Date());

const formatDate = (date, options = { dateStyle: "long" }) => {
  if (!date) return "-";
  try {
    return new Date(date).toLocaleString("en-IN", options);
  } catch {
    return String(date);
  }
};

const formatInputDateLabel = (date) =>
  formatDate(`${date}T00:00:00+05:30`, { day: "2-digit", month: "long", year: "numeric" });

const formatPageDate = (date) =>
  formatDate(`${date}T00:00:00+05:30`, {
    weekday: "long",
    day: "2-digit",
    month: "long",
    year: "numeric",
  });

const formatTime = (value) => {
  if (!value) return "-";
  if (typeof value === "string" && /^\d{1,2}:\d{2}/.test(value.trim())) return value.trim();
  return formatDate(value, { hour: "2-digit", minute: "2-digit", hour12: false });
};

const displayValue = (value) => {
  if (value === null || value === undefined || value === "") return "-";
  if (Array.isArray(value)) {
    if (!value.length) return "-";
    return value.map((item) => displayValue(item)).join(", ");
  }
  if (typeof value === "object") {
    const directValue = value.name || value.full_name || value.title || value.value;
    if (directValue) return displayValue(directValue);
    return Object.entries(value)
      .filter(([, item]) => item !== null && item !== undefined && item !== "")
      .map(([key, item]) => `${cleanLabel(key)}: ${displayValue(item)}`)
      .join(" | ") || "-";
  }
  return String(value);
};

const valueFrom = (...values) => {
  for (const value of values) {
    if (value !== null && value !== undefined && value !== "") return displayValue(value);
  }
  return "-";
};

const timeRange = (period) => {
  if (!period || typeof period !== "object") return null;
  if (!period.start || !period.end) return null;
  return `${formatTime(period.start)} - ${formatTime(period.end)}`;
};

const splitMuhurtaRows = (payload, keyCandidates) => {
  const source = payload || {};
  const normalise = (items = []) =>
    (Array.isArray(items) ? items : []).map((item, index) => ({
      id: `${item.muhurta || item.hora || item.planet || item.name || "period"}-${index}`,
      name: valueFrom(...keyCandidates.map((key) => item[key]), item.muhurta, item.hora, item.planet, item.name),
      time: valueFrom(item.time, item.period, item.duration),
    }));

  if (source.day || source.night) {
    return {
      day: normalise(source.day),
      night: normalise(source.night),
    };
  }

  if (source.chaughadiya) {
    return splitMuhurtaRows(source.chaughadiya, keyCandidates);
  }

  if (source.hora) {
    return splitMuhurtaRows(source.hora, keyCandidates);
  }

  if (Array.isArray(source)) {
    const midpoint = Math.ceil(source.length / 2);
    return {
      day: normalise(source.slice(0, midpoint)),
      night: normalise(source.slice(midpoint)),
    };
  }

  return { day: [], night: [] };
};

const chaughadiyaClass = (name) => {
  const normalised = String(name || "").toLowerCase();
  if (["amrit", "shubh", "labh"].some((item) => normalised.includes(item))) {
    return "bg-emerald-50/70 border-l-4 border-l-emerald-500 text-emerald-900";
  }
  if (normalised.includes("char")) return "bg-sky-50/70 border-l-4 border-l-sky-400 text-sky-900";
  return "bg-rose-50/70 border-l-4 border-l-rose-400 text-rose-900";
};

function FieldShell({ label, children }) {
  return (
    <div>
      <label className="mb-2 block text-sm font-bold text-slate-600">{label}</label>
      {children}
    </div>
  );
}

function MuhurtaTable({ title, rows, rowClass = () => "bg-slate-50/50 border-l-4 border-l-[#D7AF4B] text-slate-700" }) {
  return (
    <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm transition hover:shadow-md">
      <h3 className="bg-[#D7AF4B] px-5 py-4 text-center text-lg font-bold text-[#1E3557] border-b border-[#D7AF4B]">{title}</h3>
      <div className="divide-y divide-slate-100">
        {(rows.length ? rows : [{ id: "empty", name: "No data returned", time: "-" }]).map((row) => (
          <div
            key={row.id}
            className={`grid grid-cols-[1fr_1.2fr] px-5 py-3.5 text-center text-sm md:text-base items-center ${rowClass(row.name)}`}
          >
            <strong className="font-bold">{row.name}</strong>
            <span className="font-mono text-xs md:text-sm font-semibold">{row.time}</span>
          </div>
        ))}
      </div>
    </section>
  );
}

function InfoTable({ title, rows }) {
  return (
    <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm transition hover:shadow-md">
      {title ? (
        <h2 className="bg-[#D7AF4B] border-b border-[#D7AF4B] px-5 py-4 text-center text-lg font-bold text-[#1E3557]">
          {title}
        </h2>
      ) : null}
      <div className="grid grid-cols-2 divide-x divide-y divide-slate-100">
        {rows.map(([label, value]) => (
          <div key={label} className="p-4 bg-white transition hover:bg-slate-50/60 border-t border-l border-slate-100 first:border-t-0 odd:border-l-0">
            <p className="text-xs font-bold uppercase tracking-wider text-slate-400">{label}</p>
            <p className="mt-1 text-sm font-semibold text-[#1E3557]">{value || "-"}</p>
          </div>
        ))}
      </div>
    </section>
  );
}

const cleanLabel = (label) =>
  String(label || "")
    .replace(/_/g, " ")
    .replace(/\b\w/g, (char) => char.toUpperCase());

const tableValue = (value) => {
  if (value === null || value === undefined || value === "") return "-";
  if (Array.isArray(value)) return value.map((item) => tableValue(item)).filter(Boolean).join(", ") || "-";
  if (typeof value === "object") {
    const preferred = value.name || value.full_name || value.title || value.value || value.sign || value.degree;
    if (preferred) return String(preferred);
    return Object.entries(value)
      .filter(([, nestedValue]) => nestedValue !== null && nestedValue !== undefined && nestedValue !== "")
      .map(([key, nestedValue]) => `${cleanLabel(key)}: ${tableValue(nestedValue)}`)
      .join(" | ") || "-";
  }
  return String(value);
};

const firstArrayFrom = (payload, keys = []) => {
  if (Array.isArray(payload)) return payload;
  if (!payload || typeof payload !== "object") return [];

  for (const key of keys) {
    if (Array.isArray(payload[key])) return payload[key];
  }

  const nestedArray = Object.values(payload).find(
    (value) => Array.isArray(value) && value.some((item) => item && typeof item === "object")
  );

  return nestedArray || [];
};

const normalizePlanetRows = (payload) =>
  firstArrayFrom(payload, ["planets", "planet_details", "planetary_positions", "planet_panchang", "data"]).map((item, index) => ({
    id: `${item.name || item.planet || item.full_name || "planet"}-${index}`,
    planet: tableValue(item.name || item.planet || item.full_name),
    sign: tableValue(item.sign || item.zodiac || item.rashi),
    degree: tableValue(item.degree || item.normDegree || item.full_degree || item.longitude),
    nakshatra: tableValue(item.nakshatra || item.nakshatra_name || item.nak_name),
    house: tableValue(item.house || item.house_id),
    motion: tableValue(item.isRetro === true || item.is_retro === true ? "Retrograde" : item.isRetro === false || item.is_retro === false ? "Direct" : item.motion),
  }));

const objectRows = (payload) => {
  if (!payload || typeof payload !== "object" || Array.isArray(payload)) return [];
  return Object.entries(payload)
    .filter(([, value]) => value !== null && value !== undefined && value !== "")
    .map(([key, value]) => [cleanLabel(key), tableValue(value)]);
};

function PanchangDataTable({ title, rows, columns }) {
  return (
    <section className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm transition hover:shadow-md">
      <h3 className="border-b border-[#D7AF4B] bg-[#D7AF4B] px-5 py-4 text-base font-bold text-[#1E3557]">{title}</h3>
      <div className="overflow-x-auto">
        <table className="min-w-full border-collapse text-left text-sm">
          <thead className="bg-[#1E3557] text-white">
            <tr>
              {columns.map((column) => (
                <th key={column.key} className="px-4 py-3 font-semibold uppercase tracking-wider text-xs">
                  {column.label}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {(rows.length ? rows : [{ id: "empty" }]).map((row, index) => (
              <tr key={row.id || index} className="hover:bg-slate-50/80 transition odd:bg-white even:bg-slate-50/40">
                {columns.map((column) => (
                  <td key={column.key} className="px-4 py-3.5 text-slate-700 font-medium">
                    {row[column.key] || "-"}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

function PanchangExtraBlocks({ extrasData, extrasLoading, extrasError }) {
  const planetaryRows = normalizePlanetRows(extrasData?.planetary_positions);
  const sunriseRows = normalizePlanetRows(extrasData?.sunrise_planetary_positions);
  const chartPayload = extrasData?.panchang_chart;
  const chartSvg = chartPayload?.svg || chartPayload?.chart_svg || chartPayload?.chart;
  const chartRows = objectRows(chartPayload);
  const planetColumns = [
    { key: "planet", label: "Planet" },
    { key: "sign", label: "Sign" },
    { key: "degree", label: "Degree" },
    { key: "nakshatra", label: "Nakshatra" },
    { key: "house", label: "House" },
    { key: "motion", label: "Motion" },
  ];

  return (
    <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm transition hover:shadow-md">
      <h2 className="bg-[#D7AF4B] px-5 py-4 text-lg font-bold text-[#1E3557]">
        Planetary Positions & Panchang Chart
      </h2>
      <div className="space-y-6 p-5">
          {extrasLoading ? <p className="rounded-md bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-600">Loading planetary details...</p> : null}
          {extrasError ? <p className="rounded-md bg-rose-50 px-4 py-3 text-sm font-semibold text-rose-700">{extrasError}</p> : null}
          {!extrasLoading && !extrasError ? (
            <>
              <PanchangDataTable title="Planetary Positions" rows={planetaryRows} columns={planetColumns} />
              <PanchangDataTable title="Sunrise Planetary Positions" rows={sunriseRows} columns={planetColumns} />
              {chartSvg && String(chartSvg).includes("<svg") ? (
                <section className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm transition hover:shadow-md">
                  <h3 className="border-b border-[#D7AF4B] bg-[#D7AF4B] px-5 py-4 text-base font-bold text-[#1E3557]">Panchang Chart</h3>
                  <div className="mx-auto max-w-xl p-5 [&_svg]:h-auto [&_svg]:w-full" dangerouslySetInnerHTML={{ __html: chartSvg }} />
                </section>
              ) : (
                <PanchangDataTable
                  title="Panchang Chart"
                  rows={chartRows.map(([label, value]) => ({ id: label, label, value }))}
                  columns={[
                    { key: "label", label: "Attribute" },
                    { key: "value", label: "Value" },
                  ]}
                />
              )}
            </>
          ) : null}
      </div>
    </section>
  );
}

function ViewButtons({ activeView, onChange }) {
  return (
    <div className="mx-auto mt-14 grid max-w-5xl gap-6 md:grid-cols-3">
      {Object.entries(VIEW_CONFIG).map(([key, view]) => (
        <button
          key={key}
          type="button"
          onClick={() => onChange(key)}
          className={`min-h-[118px] rounded-md px-8 py-5 text-2xl font-black leading-tight text-white shadow-sm transition hover:-translate-y-0.5 ${
            activeView === key
              ? "bg-gradient-to-br from-[#1E3557] to-[#D4A73C]"
              : "bg-gradient-to-br from-[#315f9d] to-[#8a6de8]"
          }`}
        >
          {view.label}
        </button>
      ))}
    </div>
  );
}

export default function Panchang() {
  const { user } = useAuth();
  const [searchParams, setSearchParams] = useSearchParams();
  const today = useMemo(() => getTodayInIndia(), []);
  const [activeView, setActiveView] = useState(() => {
    const requestedView = searchParams.get("view");
    return VIEW_CONFIG[requestedView] ? requestedView : "daily";
  });
  const [selectedDate, setSelectedDate] = useState(today);
  const [language, setLanguage] = useState("en");
  const [place, setPlace] = useState(user?.place_of_birth || "New Delhi, Delhi, India");
  const [coordinates, setCoordinates] = useState(
    user?.latitude != null && user?.longitude != null
      ? `${user.latitude},${user.longitude}`
      : "28.6139,77.2090"
  );
  const [locationResults, setLocationResults] = useState([]);
  const [loadingLocation, setLoadingLocation] = useState(false);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [data, setData] = useState(null);
  const [extrasData, setExtrasData] = useState(null);
  const [extrasLoading, setExtrasLoading] = useState(false);
  const [extrasError, setExtrasError] = useState("");

  const selectedDateLabel = formatPageDate(selectedDate);
  const selectedInputLabel = formatInputDateLabel(selectedDate);
  const currentView = VIEW_CONFIG[activeView];

  const showToast = (text) => {
    setMessage(text);
    window.clearTimeout(window.__astrozuraPanchangToast);
    window.__astrozuraPanchangToast = window.setTimeout(() => setMessage(""), 3500);
  };

  const fetchPanchang = async (date, coords, mode = activeView, nextLanguage = language) => {
    if (!coords) {
      showToast("Select a valid location from the dropdown.");
      return;
    }

    try {
      setLoading(true);
      const datetime = `${date}T06:00:00+05:30`;
      if (mode === "daily") {
        setExtrasLoading(true);
        setExtrasError("");
      }
      const [response, extrasResponse] = await Promise.all([
        getPanchang(datetime, coords, 1, { mode, la: nextLanguage }),
        mode === "daily"
          ? getPanchangExtras(datetime, coords, 1, {
              la: nextLanguage,
              extras: ["planetary_positions", "sunrise_planetary_positions", "panchang_chart"],
            }).catch((error) => ({
              status: "error",
              message: error?.response?.data?.message || "Unable to load planetary details.",
            }))
          : Promise.resolve(null),
      ]);
      if (response?.status === "success") {
        setData(response.data);
        if (mode === "daily") {
          if (extrasResponse?.status === "success") {
            setExtrasData(extrasResponse.data);
          } else {
            setExtrasData(null);
            setExtrasError(extrasResponse?.message || "Unable to load planetary details.");
          }
        } else {
          setExtrasData(null);
          setExtrasError("");
        }
      } else {
        showToast(response?.message || "Unable to fetch Panchang.");
      }
    } catch (error) {
      showToast(error?.response?.data?.message || "Unable to fetch Panchang.");
    } finally {
      setLoading(false);
      setExtrasLoading(false);
    }
  };

  useEffect(() => {
    void fetchPanchang(selectedDate, coordinates, activeView, language);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    const requestedView = searchParams.get("view");
    const nextView = VIEW_CONFIG[requestedView] ? requestedView : "daily";
    if (nextView === activeView) return;
    setActiveView(nextView);
    void fetchPanchang(selectedDate, coordinates, nextView, language);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchParams]);

  const handleSearchLocation = async (value) => {
    setPlace(value);
    setCoordinates("");
    if (value.trim().length < 3) {
      setLocationResults([]);
      return;
    }

    try {
      setLoadingLocation(true);
      const response = await searchLocation(value.trim(), language);
      setLocationResults(response?.data || []);
    } finally {
      setLoadingLocation(false);
    }
  };

  const selectLocation = async (item) => {
    const nextCoordinates = `${item.coordinates.latitude},${item.coordinates.longitude}`;
    setPlace(item.name);
    setCoordinates(nextCoordinates);
    setLocationResults([]);
    await fetchPanchang(selectedDate, nextCoordinates);
  };

  const handleDateChange = async (nextDate) => {
    setSelectedDate(nextDate);
    await fetchPanchang(nextDate, coordinates);
  };

  const moveDate = async (offset) => {
    const date = new Date(`${selectedDate}T00:00:00+05:30`);
    date.setDate(date.getDate() + offset);
    const nextDate = new Intl.DateTimeFormat("sv-SE", { timeZone: "Asia/Kolkata" }).format(date);
    await handleDateChange(nextDate);
  };

  const handleLanguageChange = async (event) => {
    const nextLanguage = event.target.value;
    setLanguage(nextLanguage);
    await fetchPanchang(selectedDate, coordinates, activeView, nextLanguage);
  };

  const handleViewChange = async (view) => {
    setActiveView(view);
    setSearchParams(view === "daily" ? {} : { view });
    await fetchPanchang(selectedDate, coordinates, view, language);
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    await fetchPanchang(selectedDate, coordinates);
  };

  const summary = data?.summary || {};
  const panchang = data?.panchang || {};
  const basic = panchang.basic || {};
  const advanced = panchang.advanced || {};
  const hinduMaah = advanced.hindu_maah || {};
  const horaRows = splitMuhurtaRows(panchang.hora, ["hora", "planet", "name"]);
  const chaughadiyaRows = splitMuhurtaRows(panchang.chaughadiya, ["muhurta", "name"]);

  const dailyCardRows = [
    ["Sunrise", formatTime(summary.sunrise || advanced.sunrise || basic.sunrise)],
    ["Sunset", formatTime(summary.sunset || advanced.sunset || basic.sunset)],
    ["Moonrise", formatTime(summary.moonrise || advanced.moonrise || basic.moonrise)],
    ["Moonset", formatTime(summary.moonset || advanced.moonset || basic.moonset)],
    ["Vedic Sunrise", formatTime(advanced.vedic_sunrise || basic.vedic_sunrise)],
    ["Vedic Sunset", formatTime(advanced.vedic_sunset || basic.vedic_sunset)],
    ["Sun Sign", valueFrom(advanced.sun_sign, basic.sun_sign, advanced.sunSign)],
    ["Moon Sign", valueFrom(advanced.moon_sign, basic.moon_sign, advanced.moonSign)],
  ];

  const elementRows = [
    ["Tithi", `${valueFrom(summary.current_tithi?.name, advanced.tithi?.details?.tithi_name)}${summary.current_tithi?.end ? ` upto ${formatTime(summary.current_tithi.end)}` : ""}`],
    ["Nakshatra", `${valueFrom(summary.current_nakshatra?.name, advanced.nakshatra?.details?.nak_name)}${summary.current_nakshatra?.end ? ` upto ${formatTime(summary.current_nakshatra.end)}` : ""}`],
    ["Yog", `${valueFrom(summary.current_yoga?.name, advanced.yog?.details?.yog_name)}${summary.current_yoga?.end ? ` upto ${formatTime(summary.current_yoga.end)}` : ""}`],
    ["Karan", `${valueFrom(summary.current_karana?.name, advanced.karan?.details?.karan_name)}${summary.current_karana?.end ? ` upto ${formatTime(summary.current_karana.end)}` : ""}`],
  ];

  const monthYearRows = [
    ["Vikram Samvat", valueFrom(advanced.vikram_samvat, basic.vikram_samvat)],
    ["Vikram Samvat Name", valueFrom(advanced.vkram_samvat_name, advanced.vikram_samvat_name, basic.vikram_samvat_name)],
    ["Shaka Samvat", valueFrom(advanced.shaka_samvat, basic.shaka_samvat, advanced.shaka_samvat_name)],
    ["Shaka Samvat Name", valueFrom(advanced.shaka_samvat_name, basic.shaka_samvat_name)],
    ["Paksha", valueFrom(advanced.paksha, summary.current_tithi?.paksha, advanced.tithi?.details?.paksha)],
    ["Ritu", valueFrom(advanced.ritu, basic.ritu)],
    ["Ayana", valueFrom(advanced.ayana, advanced.ayan, basic.ayana)],
    ["Purnimanta", valueFrom(hinduMaah.purnimanta, advanced.purnimanta, basic.purnimanta)],
    ["Amanta", valueFrom(hinduMaah.amanta, advanced.amanta, basic.amanta)],
    ["Adhik Maas", hinduMaah.adhik_status === true ? "Yes" : hinduMaah.adhik_status === false ? "No" : "-"],
    ["Sun Sign", valueFrom(advanced.sun_sign, basic.sun_sign)],
    ["Moon Sign", valueFrom(advanced.moon_sign, basic.moon_sign)],
  ];

  const inauspiciousRows = [
    ["Rahu Kaal", valueFrom(timeRange(advanced.rahukaal))],
    ["Yamghant Kaal", valueFrom(timeRange(advanced.yamghant_kaal))],
    ["Gulika Kaal", valueFrom(timeRange(advanced.guliKaal), timeRange(advanced.gulikaal), timeRange(advanced.gulika_kaal))],
    ["Dur Muhurtam", valueFrom(timeRange(advanced.dur_muhurat), timeRange(advanced.durmuhurat))],
    ["Varjyam", valueFrom(timeRange(advanced.varjyam))],
  ];

  const auspiciousRows = [
    ["Abhijit Muhurta", valueFrom(timeRange(advanced.abhijit_muhurta))],
    ["Amrit Kalam", valueFrom(timeRange(advanced.amrit_kalam))],
    ["Panchang Yog", valueFrom(advanced.panchang_yog)],
  ];

  const directionalRows = [
    ["Disha Shool", valueFrom(advanced.disha_shool)],
    ["Disha Shool Remedies", valueFrom(advanced.disha_shool_remedies)],
    ["Nakshatra Shool", valueFrom(advanced.nak_shool?.direction, advanced.nakshatra_shool)],
    ["Nakshatra Shool Remedies", valueFrom(advanced.nak_shool?.remedies)],
    ["Moon Nivas", valueFrom(advanced.moon_nivas, advanced.moon_nivash)],
  ];

  return (
    <div className="min-h-screen overflow-x-hidden bg-white font-sans text-[#1E3557]">
      {message && (
        <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-xl bg-[#1E3557] px-6 py-3 text-sm font-medium text-white shadow-lg">
          {message}
        </div>
      )}
      <Navbar />

      <section className="bg-gradient-to-r from-[#1E3557] via-[#315f9d] to-[#D4A73C] text-white">
        <div className="mx-auto max-w-6xl px-4 py-5 md:px-8">
          <h1 className="max-w-[340px] text-xl font-black leading-tight sm:max-w-none sm:text-2xl md:text-4xl">
            {currentView.title} For {selectedDateLabel}
          </h1>
        </div>
      </section>

      <section className="border-b border-slate-200 bg-white">
        <form
          onSubmit={handleSubmit}
          className="mx-auto grid max-w-6xl gap-5 px-4 py-5 md:px-8 lg:grid-cols-[180px_170px_minmax(260px,1fr)_170px_250px]"
        >
          <FieldShell label="Select Date">
            <input
              type="date"
              value={selectedDate}
              onChange={(event) => void handleDateChange(event.target.value)}
              className="h-12 w-full rounded-md border border-slate-300 bg-white px-3 text-sm text-slate-700 outline-none focus:border-[#D4A73C]"
            />
          </FieldShell>

          <FieldShell label="Select Panchang Place">
            <select
              value="India"
              disabled
              className="h-12 w-full rounded-md border border-slate-300 bg-white px-3 text-sm text-slate-700"
            >
              <option>India</option>
            </select>
          </FieldShell>

          <FieldShell label="Location">
            <div className="relative">
              <input
                type="text"
                value={place}
                onChange={(event) => void handleSearchLocation(event.target.value)}
                placeholder="Search city"
                className="h-12 w-full rounded-md border border-slate-300 bg-white px-4 text-base text-slate-900 outline-none focus:border-[#D4A73C]"
              />
              {loadingLocation && <div className="absolute right-4 top-4 h-4 w-4 animate-spin rounded-full border-b-2 border-[#D4A73C]" />}
              {locationResults.length > 0 && (
                <div className="absolute z-50 mt-1 max-h-60 w-full overflow-y-auto rounded-xl border border-slate-200 bg-white shadow-xl">
                  {locationResults.map((item, index) => (
                    <button
                      key={`${item.name}-${index}`}
                      type="button"
                      onClick={() => void selectLocation(item)}
                      className="block w-full border-b border-slate-100 px-4 py-3 text-left text-sm hover:bg-slate-50 last:border-0"
                    >
                      {item.name}
                    </button>
                  ))}
                </div>
              )}
            </div>
          </FieldShell>

          <FieldShell label="Select Language">
            <select
              value={language}
              onChange={(event) => void handleLanguageChange(event)}
              className="h-12 w-full rounded-md border border-slate-300 bg-white px-3 text-sm text-slate-700 outline-none focus:border-[#D4A73C]"
            >
              {LANGUAGE_OPTIONS.map((option) => (
                <option key={option.value} value={option.value}>
                  {option.label}
                </option>
              ))}
            </select>
          </FieldShell>

          <div className="grid grid-cols-2 gap-2 self-end">
            <button type="button" onClick={() => void moveDate(-1)} className="h-12 rounded-md bg-[#1E3557] px-4 text-sm font-bold text-white hover:bg-[#172a46]">
              Previous
            </button>
            <button type="button" onClick={() => void moveDate(1)} className="h-12 rounded-md bg-[#1E3557] px-4 text-sm font-bold text-white hover:bg-[#172a46]">
              Next
            </button>
          </div>
        </form>
      </section>

      <main className="mx-auto max-w-6xl px-4 py-12 md:px-8">
        {loading ? <div className="mb-6 rounded-md bg-[#fff8df] px-4 py-3 text-sm font-semibold text-[#7a5205]">Loading selected Panchang module...</div> : null}

        {activeView === "daily" ? (
          <div className="space-y-8">
            <div className="grid gap-8 lg:grid-cols-3">
              <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm transition hover:shadow-md">
                <div className="bg-[#D7AF4B] p-5 text-[#1E3557]">
                  <h2 className="text-xl font-bold">{selectedInputLabel}</h2>
                  <p className="mt-2 text-xs font-bold uppercase tracking-wide opacity-80">Ayana - {valueFrom(advanced.ayan, advanced.ayana)}</p>
                  <p className="mt-1 text-sm font-semibold">{valueFrom(summary.vaara, advanced.day)}</p>
                </div>
                <div className="grid grid-cols-2 divide-x divide-y divide-slate-100 border-t border-[#D7AF4B]">
                  {dailyCardRows.map(([label, value]) => (
                    <div key={label} className="p-4 bg-white transition hover:bg-slate-50/60 border-t border-l border-slate-100 first:border-t-0 odd:border-l-0">
                      <p className="text-xs font-bold uppercase tracking-wider text-slate-400">{label}</p>
                      <p className="mt-1 text-sm font-semibold text-[#1E3557]">{value}</p>
                    </div>
                  ))}
                </div>
              </section>

              <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm transition hover:shadow-md">
                <h2 className="bg-[#D7AF4B] border-b border-[#D7AF4B] px-5 py-4 text-center text-lg font-bold text-[#1E3557]">Panchang Elements</h2>
                <div className="divide-y divide-slate-100">
                  {elementRows.map(([label, value]) => (
                    <div key={label} className="grid grid-cols-[118px_1fr] bg-white transition hover:bg-slate-50/60 items-center">
                      <p className="border-r border-slate-100 p-4 text-xs font-bold uppercase tracking-wider text-slate-400">{label}</p>
                      <p className="p-4 text-sm font-semibold text-[#1E3557]">{value}</p>
                    </div>
                  ))}
                </div>
              </section>

              <InfoTable title="Hindu Month & Year" rows={monthYearRows} />
            </div>

            <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm transition hover:shadow-md">
              <div className="grid md:grid-cols-[290px_1fr] items-center">
                <div className="bg-[#D7AF4B] px-5 py-4 text-base font-bold text-[#1E3557] h-full flex items-center">Today's Festival & Vratas</div>
                <div className="px-5 py-4 text-base font-semibold text-[#1E3557]">{valueFrom(advanced.festivals, advanced.vrat, basic.festivals, "No festival returned")}</div>
              </div>
            </section>

            <div className="grid gap-8 lg:grid-cols-[2fr_1fr]">
              <InfoTable title="Inauspicious Timing" rows={inauspiciousRows} />
              <InfoTable title="Auspicious Timing" rows={auspiciousRows} />
            </div>

            <div className="grid gap-8 lg:grid-cols-[1fr_2fr]">
              <InfoTable
                title="Other Yoga"
                rows={[
                  ["Anandadi Yog", valueFrom(advanced.anandadi_yog, advanced.anandadi_yoga)],
                  ["Panchang Yog", valueFrom(advanced.panchang_yog)],
                ]}
              />
              <InfoTable title="Shool & Nivas" rows={directionalRows} />
            </div>

            <PanchangExtraBlocks
              extrasData={extrasData}
              extrasLoading={extrasLoading}
              extrasError={extrasError}
            />
          </div>
        ) : (
          <div>
            <section className="mx-auto max-w-4xl">
              <h2 className="text-3xl font-black text-slate-950">
                {activeView === "hora" ? "Hora" : "Chaughadiya"} for {selectedInputLabel}
              </h2>
              <p className="mt-2 text-base font-medium text-[#315f9d]">{place}</p>
              <p className="mt-7 max-w-4xl text-lg leading-8 text-slate-600">{currentView.intro}</p>
            </section>

            <div className="mx-auto mt-14 grid max-w-4xl gap-16 md:grid-cols-2">
              {activeView === "hora" ? (
                <>
                  <MuhurtaTable title="Day Hora" rows={horaRows.day} />
                  <MuhurtaTable title="Night Hora" rows={horaRows.night} />
                </>
              ) : (
                <>
                  <MuhurtaTable title="Day Chaughadiya" rows={chaughadiyaRows.day} rowClass={chaughadiyaClass} />
                  <MuhurtaTable title="Night Chaughadiya" rows={chaughadiyaRows.night} rowClass={chaughadiyaClass} />
                </>
              )}
            </div>

            {activeView === "chaughadiya" ? (
              <section className="mx-auto mt-20 max-w-4xl">
                <h2 className="text-3xl font-black text-slate-950">About Chaughadiya</h2>
                <p className="mt-8 text-lg leading-8 text-slate-600">
                  Ghadi is an ancient measure for calculations of time in India. Chaughadiya divides the day and night into practical muhurta windows used for planning routine and auspicious work.
                </p>
                <p className="mt-8 text-lg font-black text-slate-950">There are generally seven types of Chaughadiya.</p>
                <div className="mt-6 space-y-4 text-lg text-slate-600">
                  <p><span className="mr-3 inline-block h-7 w-7 rounded-md bg-emerald-100 align-middle" /> Amrit, Shubh and Labh are considered auspicious Chaughadiyas.</p>
                  <p><span className="mr-3 inline-block h-7 w-7 rounded-md bg-rose-100 align-middle" /> Udveg, Kaal and Rog are considered inauspicious Chaughadiyas.</p>
                  <p><span className="mr-3 inline-block h-7 w-7 rounded-md bg-sky-100 align-middle" /> Char is considered a good Chaughadiya.</p>
                </div>
              </section>
            ) : null}
          </div>
        )}

        <ViewButtons activeView={activeView} onChange={handleViewChange} />
      </main>

      <Footer />
    </div>
  );
}
