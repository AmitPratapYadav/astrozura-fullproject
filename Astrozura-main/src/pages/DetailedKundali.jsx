import { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import RecentProfilePicker from "../components/RecentProfilePicker";
import { RelatedToolTabs, ToolInputPanel } from "../components/tool/ToolLayout";
import { 
  generateKundli, 
  getDivisionalCharts, 
  getPredictions, 
  searchLocation 
} from "../api/prokeralaApi";
import { useAuth } from "../context/AuthContext";
import { FaBookOpen, FaStar, FaInfoCircle, FaSpinner } from "react-icons/fa";
import {
  GemstoneSuggestionReport,
  KaalSarpDoshaReport,
  MangalDoshaReport,
  PitraDoshaReport,
  RudrakshaSuggestionReport,
} from "../components/report/SpecializedVedicReports";
import { ReportDataBlock } from "../components/report/ReportDataRenderer";
import { ReportPanel } from "../components/report/ReportTables";
import BiorhythmReport from "../components/report/BiorhythmReport";
import { serviceCatalog } from "../data/serviceCatalog";
import { getServiceIcon } from "../data/serviceIcons";
import { saveRecentProfile } from "../api/recentProfilesApi";
import { buildRecentProfilePayload, profileTime } from "../utils/recentProfile";

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
  { value: "chalit", label: "Chalit - Chalit Chart" },
  { value: "gochar", label: "Gochar / Transit Chart" },
  { value: "sun", label: "Sun Chart" },
  { value: "moon", label: "Moon Chart" },
  { value: "rasi", label: "D1 - Birth Chart" },
  { value: "hora", label: "D2 - Hora Chart" },
  { value: "drekkana", label: "D3 - Dreshkan Chart" },
  { value: "chaturthamsa", label: "D4 - Chathurthamasha Chart" },
  { value: "panchamsa", label: "D5 - Panchmamsha Chart" },
  { value: "saptamsa", label: "D7 - Saptamsa Chart" },
  { value: "ashtamsa", label: "D8 - Ashtamsa Chart" },
  { value: "navamsa", label: "D9 - Navamansha Chart" },
  { value: "dasamsa", label: "D10 - Dashamansha Chart" },
  { value: "dwadasamsa", label: "D12 - Dwadashamsha Chart" },
  { value: "shodasamsa", label: "D16 - Shodashamsha Chart" },
  { value: "vimsamsa", label: "D20 - Vishamansha Chart" },
  { value: "chaturvimsamsa", label: "D24 - Chaturvimshamsha Chart" },
  { value: "bhamsa", label: "D27 - Bhamsa Chart" },
  { value: "trimsamsa", label: "D30 - Trishamansha Chart" },
  { value: "khavedamsa", label: "D40 - Khavedamsha Chart" },
  { value: "akshavedamsa", label: "D45 - Akshvedansha Chart" },
  { value: "shastiamsa", label: "D60 - Shashtymsha Chart" },
];

const dossierTabs = [
  { id: "birth", label: "Birth Details" },
  { id: "astro", label: "Astro Details" },
  { id: "charts", label: "Divisional Charts" },
  { id: "predictions", label: "Life Predictions" },
  { id: "biorhythm", label: "Biorhythm" },
  { id: "dashas", label: "Vimshottari Dasha" },
  { id: "remedies", label: "Gem & Rudraksha" },
  { id: "mangal", label: "Mangal Dosha" },
  { id: "pitra", label: "Pitra Dosha" },
  { id: "kaal", label: "Kaal Sarp Dosha" },
];

const predictionTabs = [
  { id: "health", label: "Health", tone: "from-[#DCFCE7] to-[#F0FDF4]", accent: "text-[#15803D]" },
  { id: "emotions", label: "Emotions", tone: "from-[#FFE4E6] to-[#FFF1F2]", accent: "text-[#BE123C]" },
  { id: "profession", label: "Profession", tone: "from-[#DBEAFE] to-[#EFF6FF]", accent: "text-[#1D4ED8]" },
  { id: "luck", label: "Luck", tone: "from-[#FEF3C7] to-[#FFFBEB]", accent: "text-[#B45309]" },
  { id: "personal_life", label: "Personal Life", tone: "from-[#F3E8FF] to-[#FAF5FF]", accent: "text-[#7E22CE]" },
  { id: "travel", label: "Travel", tone: "from-[#CCFBF1] to-[#F0FDFA]", accent: "text-[#0F766E]" },
];

const reportTabs = serviceCatalog
  .filter((item) => item.category === "Reports")
  .map((item) => ({
    label: item.title,
    to: item.ctaTo,
    icon: item.icon,
    isActive: item.slug === "detailed-kundali",
  }));

const cleanLabel = (value) =>
  String(value || "")
    .replace(/[_-]+/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .replace(/\b\w/g, (letter) => letter.toUpperCase());

const stripHtml = (value) =>
  String(value || "")
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/p>/gi, "\n")
    .replace(/<[^>]+>/g, "")
    .replace(/\n{3,}/g, "\n\n")
    .trim();

const displayValue = (value) => {
  if (value === null || value === undefined || value === "") return "-";
  if (typeof value === "boolean") return value ? "Yes" : "No";
  if (typeof value === "number") return Number.isFinite(value) ? String(value) : "-";
  if (typeof value === "string") return stripHtml(value) || "-";
  if (Array.isArray(value)) {
    const text = value
      .map((item) => displayValue(item))
      .filter((item) => item && item !== "-")
      .join(", ");
    return text || "-";
  }
  if (typeof value === "object") {
    const name = value.name || value.full_name || value.value || value.title || value.description || value.report;
    if (name && typeof name !== "object") return stripHtml(name);
    const entries = Object.entries(value)
      .filter(([, item]) => item !== null && item !== undefined && item !== "")
      .map(([key, item]) => `${cleanLabel(key)}: ${displayValue(item)}`);
    return entries.join(" | ") || "-";
  }
  return String(value);
};

const pageIcon = getServiceIcon("detailed-kundali");

const detailCellClass =
  "rounded-2xl border border-[#E6D7BA] bg-white px-4 py-3 shadow-sm transition-colors hover:bg-[#FFF7DF] active:bg-[#FCE9AE]";
const detailLabelClass = "text-[11px] font-black uppercase tracking-[0.16em] text-slate-500";
const detailValueClass = "mt-1 text-sm font-black text-[#1E3557]";
const tableWrapClass = "overflow-x-auto rounded-2xl border border-[#E6D7BA] bg-white shadow-sm";
const tableHeadCellClass = "border border-[#D7AF4B] px-3 py-3 font-black";
const tableBodyRowClass = "border-b border-gray-100 transition-colors hover:bg-[#FFF7DF] active:bg-[#FCE9AE] odd:bg-white even:bg-[#F8FAFC]";
const tableBodyCellClass = "border border-gray-200 px-3 py-3 align-top text-slate-700";

const objectTableRows = (value, skip = []) => {
  if (!value || typeof value !== "object" || Array.isArray(value)) return [];
  const skipSet = new Set(skip.map((item) => String(item).toLowerCase()));
  return Object.entries(value)
    .filter(([key, item]) => !skipSet.has(String(key).toLowerCase()) && item !== null && item !== undefined && item !== "")
    .map(([key, item]) => [cleanLabel(key), displayValue(item)]);
};

const findFirstArray = (...values) => {
  for (const value of values) {
    if (Array.isArray(value) && value.length) return value;
    if (value && typeof value === "object") {
      for (const nested of Object.values(value)) {
        if (Array.isArray(nested) && nested.length) return nested;
      }
    }
  }
  return [];
};

const planetRowsFromPayload = (kundli) => {
  const payload = kundli?.provider_payload || {};
  const planetPayload =
    payload?.planets?.data ||
    payload?.planets ||
    kundli?.planets ||
    kundli?.planetary_positions ||
    kundli?.planet_details ||
    [];
  const rows = findFirstArray(planetPayload, planetPayload?.data, planetPayload?.planets);

  return rows.map((planet) => ({
    planetId: displayValue(planet?.id ?? planet?.planet_id ?? planet?.planetId),
    planet: displayValue(planet?.name || planet?.planet || planet?.full_name),
    sign: displayValue(planet?.sign || planet?.zodiac || planet?.rasi || planet?.house_sign),
    signLord: displayValue(planet?.sign_lord || planet?.lord || planet?.rasi_lord || planet?.signLord),
    fullDegree: displayValue(planet?.fullDegree ?? planet?.full_degree),
    normDegree: displayValue(planet?.normDegree ?? planet?.norm_degree ?? planet?.degree ?? planet?.local_degree),
    speed: displayValue(planet?.speed),
    retrograde: displayValue(planet?.isRetro ?? planet?.is_retro),
    nakshatra: displayValue(planet?.nakshatra || planet?.nakshatra_name),
    nakshatraLord: displayValue(planet?.nakshatra_lord || planet?.nakshatraLord),
    nakshatraPad: displayValue(planet?.nakshatra_pad || planet?.nakshatraPad || planet?.pada),
    house: displayValue(planet?.house || planet?.house_number),
    motion: displayValue(planet?.is_retro === true ? "Retrograde" : planet?.is_retro === false ? "Direct" : planet?.motion),
    isPlanetSet: displayValue(planet?.is_planet_set ?? planet?.isPlanetSet),
    planetAwastha: displayValue(planet?.planet_awastha || planet?.planetAwastha || planet?.awastha),
  }));
};

const providerData = (kundli, key) => {
  const raw = kundli?.provider_payload?.[key];
  return raw?.data || raw || kundli?.[key] || {};
};

const providerEntry = (kundli, key) => kundli?.provider_payload?.[key] || kundli?.[key] || null;

const providerEntryData = (entry) => (entry?.data !== undefined ? entry.data : entry);

const providerEntryHasData = (entry) => {
  const data = providerEntryData(entry);
  if (!entry || entry.status === "error" || entry.status === "pending") return false;
  if (data === null || data === undefined || data === "") return false;
  if (Array.isArray(data)) return data.length > 0;
  if (typeof data === "object") return Object.keys(data).length > 0;
  return true;
};

const astroDetailModules = [
  { key: "bhav_madhya", title: "Bhav Madhya" },
  { key: "bhavabala", title: "Bhavabala" },
  { key: "shadbala", title: "Shadbala" },
  { key: "ayanamsha", title: "Ayanamsha" },
  { key: "ghat_chakra", title: "Ghat Chakra" },
];

const biorhythmModules = [
  { key: "biorhythm", title: "Biorhythm" },
  { key: "moon_biorhythm", title: "Moon Biorhythm" },
];

const ProviderModulePanels = ({ kundli, modules, emptyText }) => {
  const visibleModules = modules
    .map((module) => ({ ...module, entry: providerEntry(kundli, module.key) }))
    .filter((module) => providerEntryHasData(module.entry));

  if (!visibleModules.length) {
    return (
      <p className="rounded-2xl border border-gray-100 bg-slate-50 p-4 text-sm text-slate-500">
        {emptyText || "No data returned for this section."}
      </p>
    );
  }

  return (
    <div className="space-y-5">
      {visibleModules.map((module) => (
        <ReportPanel
          key={module.key}
          title={module.title}
        >
          <ReportDataBlock title={module.title} data={providerEntryData(module.entry)} />
        </ReportPanel>
      ))}
    </div>
  );
};

const hiddenRendererKeys = new Set([
  "status",
  "endpoint",
  "api",
  "url",
  "provider_payload",
  "provider_sections",
  "raw",
  "data",
]);

const unwrapProviderData = (value) => {
  let current = providerEntryData(value);
  while (
    current &&
    typeof current === "object" &&
    !Array.isArray(current) &&
    current.data &&
    current.data !== current &&
    Object.keys(current).filter((key) => !["status", "message", "data"].includes(key)).length === 0
  ) {
    current = current.data;
  }
  return current;
};

const isScalarValue = (value) =>
  value === null ||
  value === undefined ||
  ["string", "number", "boolean"].includes(typeof value);

const cleanEntries = (value) => {
  if (!value || typeof value !== "object" || Array.isArray(value)) return [];
  return Object.entries(value).filter(
    ([key, item]) =>
      !hiddenRendererKeys.has(String(key).toLowerCase()) &&
      item !== null &&
      item !== undefined &&
      item !== ""
  );
};

const scalarEntries = (value) => cleanEntries(value).filter(([, item]) => isScalarValue(item));

const complexEntries = (value) =>
  cleanEntries(value).filter(([, item]) => item && typeof item === "object");

const BiorhythmValueGrid = ({ entries }) => {
  if (!entries.length) return null;
  return (
    <div className="grid gap-3 sm:grid-cols-2">
      {entries.map(([key, value]) => (
        <div key={key} className={detailCellClass}>
          <span className={detailLabelClass}>{cleanLabel(key)}</span>
          <span className={`block ${detailValueClass}`}>{displayValue(value)}</span>
        </div>
      ))}
    </div>
  );
};

const BiorhythmArrayTable = ({ title, rows }) => {
  if (!Array.isArray(rows) || !rows.length) return null;
  const objectRows = rows.filter((row) => row && typeof row === "object" && !Array.isArray(row));
  const primitiveRows = rows.filter((row) => !row || typeof row !== "object" || Array.isArray(row));
  const headers = objectRows.length
    ? Array.from(
        objectRows.reduce((set, row) => {
          cleanEntries(row).forEach(([key, value]) => {
            if (isScalarValue(value) || Array.isArray(value)) set.add(key);
          });
          return set;
        }, new Set())
      )
    : ["Value"];

  return (
    <div className="rounded-2xl border border-[#E6D7BA] bg-white shadow-sm">
      {title && (
        <h5 className="border-b border-[#E6D7BA] bg-[#FFF3C4] px-4 py-3 text-sm font-black text-[#1E3557]">
          {cleanLabel(title)}
        </h5>
      )}
      <div data-horizontal-scroll="true" className="overflow-x-auto">
        <table className="w-full min-w-[520px] border-collapse text-left text-xs">
          <thead>
            <tr className="bg-[#D7AF4B] text-[#1E3557]">
              <th className={tableHeadCellClass}>S.N.</th>
              {headers.map((heading) => (
                <th key={heading} className={tableHeadCellClass}>
                  {cleanLabel(heading)}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {objectRows.map((row, index) => (
              <tr key={index} className={tableBodyRowClass}>
                <td className={tableBodyCellClass}>{index + 1}</td>
                {headers.map((heading) => (
                  <td key={heading} className={tableBodyCellClass}>
                    {displayValue(row?.[heading])}
                  </td>
                ))}
              </tr>
            ))}
            {primitiveRows.map((row, index) => (
              <tr key={`primitive-${index}`} className={tableBodyRowClass}>
                <td className={tableBodyCellClass}>{objectRows.length + index + 1}</td>
                <td className={tableBodyCellClass}>{displayValue(row)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

const BiorhythmObjectCard = ({ title, value }) => {
  const data = unwrapProviderData(value);
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    return (
      <div className={detailCellClass}>
        <span className={detailLabelClass}>{cleanLabel(title)}</span>
        <span className={`block ${detailValueClass}`}>{displayValue(data)}</span>
      </div>
    );
  }

  const scalars = scalarEntries(data);
  const children = complexEntries(data);

  return (
    <div className="rounded-2xl border border-[#E6D7BA] bg-[#FFFDF7] p-4 shadow-sm">
      {title && <h5 className="mb-4 text-base font-black text-[#1E3557]">{cleanLabel(title)}</h5>}
      <BiorhythmValueGrid entries={scalars} />
      {children.length > 0 && (
        <div className="mt-4 space-y-4">
          {children.map(([key, item]) =>
            Array.isArray(item) ? (
              <BiorhythmArrayTable key={key} title={key} rows={item} />
            ) : (
              <BiorhythmObjectCard key={key} title={key} value={item} />
            )
          )}
        </div>
      )}
    </div>
  );
};

const BiorhythmPanels = ({ kundli }) => {
  const visibleModules = biorhythmModules
    .map((module) => ({ ...module, entry: providerEntry(kundli, module.key) }))
    .filter((module) => providerEntryHasData(module.entry));

  if (!visibleModules.length) {
    return (
      <p className="rounded-2xl border border-gray-100 bg-slate-50 p-4 text-sm text-slate-500">
        No biorhythm data was returned for this profile.
      </p>
    );
  }

  return (
    <div className="space-y-5">
      {visibleModules.map((module) => {
        const data = unwrapProviderData(module.entry);
        const moduleScalars = scalarEntries(data);
        const moduleChildren = complexEntries(data);

        return (
          <section key={module.key} className="overflow-hidden rounded-3xl border border-[#E6D7BA] bg-white shadow-sm">
            <div className="border-b border-[#E6D7BA] bg-[#D7AF4B] px-5 py-4">
              <h4 className="text-lg font-black text-[#1E3557]">{module.title}</h4>
            </div>
            <div className="space-y-4 p-4">
              <BiorhythmValueGrid entries={moduleScalars} />
              {Array.isArray(data) ? (
                <BiorhythmArrayTable rows={data} />
              ) : moduleChildren.length ? (
                moduleChildren.map(([key, item]) =>
                  Array.isArray(item) ? (
                    <BiorhythmArrayTable key={key} title={key} rows={item} />
                  ) : (
                    <BiorhythmObjectCard key={key} title={key} value={item} />
                  )
                )
              ) : null}
            </div>
          </section>
        );
      })}
    </div>
  );
};

const splitCoordinates = (coordinates = "") => {
  const [latitude, longitude] = String(coordinates).split(",").map((item) => item.trim());
  return { latitude, longitude };
};

const kundliSummaryRows = (kundli, form) => {
  const astro = providerData(kundli, "astro_details");
  const birth = providerData(kundli, "birth_details");
  const coords = splitCoordinates(form.coordinates);
  const nakshatra = kundli?.nakshatra_details?.nakshatra || {};
  const moonRashi = kundli?.nakshatra_details?.chandra_rasi || {};
  const sunRashi = kundli?.nakshatra_details?.soorya_rasi || {};
  const additional = kundli?.nakshatra_details?.additional_info || {};

  return [
    ["Native Name", form.name],
    ["Date of Birth", form.date_of_birth || birth?.birth_date || birth?.date],
    ["Birth Time", form.time_of_birth || birth?.birth_time || birth?.time],
    ["Birth Place", form.place_of_birth],
    ["Latitude", birth?.latitude || birth?.lat || coords.latitude],
    ["Longitude", birth?.longitude || birth?.lon || birth?.lng || coords.longitude],
    ["Timezone", birth?.timezone || birth?.tz || birth?.time_zone],
    ["Sunrise", birth?.sunrise],
    ["Sunset", birth?.sunset],
    ["Ayanamsha", birth?.ayanamsha || birth?.ayanamsa],
    ["Astro Nakshatra", nakshatra?.name || astro?.Naksahtra || astro?.Nakshatra || astro?.nakshatra],
    ["Nakshatra Pada", nakshatra?.pada || astro?.Charan || astro?.charan || astro?.pada],
    ["Moon Sign", moonRashi?.name || astro?.sign || astro?.MoonSign || astro?.moon_sign],
    ["Rashi Lord", moonRashi?.lord?.name || astro?.SignLord || astro?.rashi_lord || astro?.sign_lord],
    ["Sun Sign", sunRashi?.name || astro?.sun_sign || astro?.SunSign],
    ["Lagna / Ascendant", additional?.ascendant || astro?.ascendant || astro?.Ascendant || birth?.ascendant],
    ["Gan", additional?.ganam || astro?.Gan || astro?.gan],
    ["Nadi", additional?.nadi || astro?.Nadi || astro?.nadi],
  ];
};

const predictionBlocks = (payload) => {
  if (!payload) return [];
  if (payload?.provider_payload && typeof payload.provider_payload === "object") {
    return Object.entries(payload.provider_payload).flatMap(([key, item]) =>
      predictionBlocks(item?.data || item).map((block) => ({
        ...block,
        title: block.title === "Prediction" ? cleanLabel(key) : block.title,
      }))
    );
  }
  if (payload?.data && payload.data !== payload) {
    return predictionBlocks(payload.data);
  }
  if (Array.isArray(payload)) {
    return payload
      .map((item, index) => ({
        title: displayValue(item?.title || item?.name || `Prediction ${index + 1}`),
        body: displayValue(item?.description || item?.prediction || item?.report || item),
      }))
      .filter((item) => item.body && item.body !== "-");
  }
  if (payload.provider_sections) {
    return payload.provider_sections.flatMap((section) =>
      Object.entries(section.items || {}).map(([key, item]) => ({
        title: displayValue(item?.label || item?.title || key || section.title),
        body: displayValue(item?.data || item?.description || item),
      }))
    ).filter((item) => item.body && item.body !== "-");
  }
  if (typeof payload === "object") {
    return objectTableRows(payload).map(([title, body]) => ({ title, body }));
  }
  return [{ title: "Prediction", body: displayValue(payload) }];
};

const firstArrayFromObject = (value) => {
  if (Array.isArray(value)) return value;
  if (!value || typeof value !== "object") return [];
  for (const key of ["dasha_period", "periods", "major", "data", "dashas", "dasha"]) {
    if (Array.isArray(value[key])) return value[key];
  }
  return Object.values(value).find((item) => Array.isArray(item)) || [];
};

const dashaPeriodRows = (payload) =>
  firstArrayFromObject(payload)
    .filter((item) => item && typeof item === "object")
    .map((item, index) => {
      const knownKeys = new Set(["planet", "dasha_name", "name", "lord", "planet_id", "id", "start", "start_date", "end", "end_date", "duration", "dasha_year", "years"]);
      const extraDetails = Object.entries(item)
        .filter(([key, value]) => !knownKeys.has(key) && value !== null && value !== undefined && value !== "")
        .map(([key, value]) => `${cleanLabel(key)}: ${displayValue(value)}`)
        .join(" | ");

      return {
        id: index,
        planet: displayValue(item.planet || item.dasha_name || item.name || item.lord),
        planetId: displayValue(item.planet_id ?? item.id),
        start: displayValue(item.start || item.start_date),
        end: displayValue(item.end || item.end_date),
        duration: displayValue(item.duration || item.dasha_year || item.years),
        extraDetails,
      };
    });

const currentDashaRows = (payload) => {
  if (!payload || typeof payload !== "object") return [];
  return objectTableRows(payload);
};

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
  const [activePredictionArea, setActivePredictionArea] = useState("health");
  const [loadingChart, setLoadingChart] = useState(false);
  const [loadedCharts, setLoadedCharts] = useState({});
  const resultAreaRef = useRef(null);
  const tabButtonRefs = useRef({});
  const touchStartRef = useRef(null);

  const isPaid = Boolean(user);

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

  useEffect(() => {
    const activeButton = tabButtonRefs.current[activeDossierTab];
    activeButton?.scrollIntoView({ behavior: "smooth", inline: "center", block: "nearest" });
  }, [activeDossierTab]);

  useEffect(() => {
    if (!reportData?.datetime) return undefined;
    const timer = window.setTimeout(() => {
      resultAreaRef.current?.scrollIntoView({ behavior: "smooth", block: "start" });
    }, 120);
    return () => window.clearTimeout(timer);
  }, [reportData?.datetime]);

  const selectDossierTab = (tabId) => {
    setActiveDossierTab(tabId);
  };

  const shouldIgnoreSwipe = (target) => {
    if (!target || typeof target.closest !== "function") return false;
    return Boolean(
      target.closest(
        "button, a, input, select, textarea, [data-horizontal-scroll='true'], [data-dossier-tabs='true']"
      )
    );
  };

  const handleResultTouchStart = (event) => {
    if (shouldIgnoreSwipe(event.target)) {
      touchStartRef.current = null;
      return;
    }
    const touch = event.touches?.[0];
    if (!touch) return;
    touchStartRef.current = { x: touch.clientX, y: touch.clientY };
  };

  const handleResultTouchEnd = (event) => {
    if (!touchStartRef.current) return;
    const touch = event.changedTouches?.[0];
    if (!touch) return;

    const deltaX = touch.clientX - touchStartRef.current.x;
    const deltaY = touch.clientY - touchStartRef.current.y;
    touchStartRef.current = null;

    if (Math.abs(deltaX) < 70 || Math.abs(deltaY) > 60) return;

    const currentIndex = dossierTabs.findIndex((tab) => tab.id === activeDossierTab);
    const nextIndex = deltaX < 0 ? currentIndex + 1 : currentIndex - 1;
    const nextTab = dossierTabs[nextIndex];
    if (nextTab) selectDossierTab(nextTab.id);
  };

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

  const applyRecentProfile = (profile) => {
    setForm((current) => ({
      ...current,
      name: profile.person_name || current.name,
      gender: profile.gender || current.gender,
      date_of_birth: profile.date_of_birth || current.date_of_birth,
      time_of_birth: profileTime(profile.time_of_birth) || current.time_of_birth,
      place_of_birth: profile.place_of_birth || current.place_of_birth,
      coordinates: profile.coordinates || current.coordinates,
    }));
  };

  const rememberCurrentProfile = async () => {
    if (!user || !form.date_of_birth) return;
    try {
      await saveRecentProfile(buildRecentProfilePayload({
        name: form.name,
        gender: form.gender,
        date: form.date_of_birth,
        time: form.time_of_birth,
        place: form.place_of_birth,
        coordinates: form.coordinates,
        sourceModule: "detailed-kundali",
        relationRole: "self",
      }));
    } catch {
      // Recent-profile persistence must not block report rendering.
    }
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
      setActiveDossierTab("birth");
      const datetime = `${form.date_of_birth}T${form.time_of_birth}:00+05:30`;

      // Fetch the approved detailed Kundli bundle and the selected daily nakshatra prediction only.
      const [kundliRes, predictionsRes] = await Promise.allSettled([
        generateKundli(datetime, form.coordinates, 1, {
          chart_type: selectedChartType,
          chart_style: form.chart_style,
          la: form.language,
        }),
        getPredictions(datetime, form.coordinates, activePredictionArea, { la: form.language }),
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
        defaultCharts[selectedChartType] = mainKundli.chart;
      }
      const providerPayload = mainKundli?.provider_payload || {};

      setReportData({
        kundli: mainKundli,
        predictions: {
          [activePredictionArea]: predictionsRes.status === "fulfilled" ? predictionsRes.value.data : null,
        },
        gemstones: providerPayload.basic_gem_suggestion || null,
        rudraksha: providerPayload.rudraksha_suggestion || null,
        doshas: {
          mangal: providerPayload.manglik || null,
          pitra: providerPayload.pitra_dosha_report || null,
          kaal: providerPayload.kalsarpa_details || null,
        },
        datetime,
      });

      setLoadedCharts(defaultCharts);
      void rememberCurrentProfile();
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
      setReportData(prev => ({
        ...prev,
        predictions: {
          ...prev.predictions,
          [area]: [{ title: "No Data", description: "No prediction text was returned for this section." }]
        }
      }));
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
        <div className="mx-auto grid max-w-7xl gap-8 text-center md:grid-cols-[1fr_auto] md:items-center md:text-left">
          <div>
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
          <div className="mx-auto flex h-28 w-28 items-center justify-center rounded-[1.75rem] bg-white p-3 shadow-2xl md:h-36 md:w-36">
            <img src={pageIcon} alt="" className="h-full w-full object-contain" />
          </div>
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
                Free Member Report
              </span>
              <p className="mt-4 text-sm font-semibold text-emerald-700">
                Sign in to generate this report without a service charge.
              </p>
              
              <Link
                to="/login"
                className="mt-6 block w-full rounded-2xl bg-[#1E3C72] py-3.5 text-center text-sm font-bold text-white shadow-md shadow-[#1E3C72]/25 hover:bg-[#162C54] transition"
              >
                Sign In to Generate Report
              </Link>
              <p className="mt-3 text-[11px] text-gray-400">Saved profile details are filled automatically.</p>
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
          <div className="space-y-8">
            <ToolInputPanel
              title="Birth Particulars"
              description="Detailed Kundali Analysis requires precise time and location details."
              action={<RecentProfilePicker onSelect={applyRecentProfile} />}
            >
              <form onSubmit={handleSubmit} className="mt-6 grid gap-5 md:grid-cols-2 xl:grid-cols-4">
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
                    max={new Date().toISOString().slice(0, 10)}
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
                  <div className="rounded-2xl border border-slate-100 bg-[#f8f9fc] px-4 py-3 text-xs text-slate-500 md:col-span-2 xl:col-span-4">
                    Coordinates: {form.coordinates}
                  </div>
                )}

                <button
                  type="submit"
                  disabled={loading}
                  className="flex w-full items-center justify-center gap-2 rounded-2xl bg-[#1E3C72] px-5 py-3.5 text-sm font-bold text-white transition hover:bg-[#162C54] disabled:opacity-60 md:col-span-2 xl:col-span-4"
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
            </ToolInputPanel>

            <RelatedToolTabs title="Reports" items={reportTabs} />

            <main ref={resultAreaRef} className="space-y-6 scroll-mt-28">
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
                <div
                  className="space-y-6 animate-fadeIn"
                  onTouchStart={handleResultTouchStart}
                  onTouchEnd={handleResultTouchEnd}
                >
                  {/* Digital Dossier Tabs */}
                  <div data-dossier-tabs="true" className="-mx-1 overflow-x-auto border-b border-slate-200 px-1 pb-4 [scrollbar-width:thin]">
                    <div className="flex min-w-max gap-3">
                      {dossierTabs.map((t) => (
                        <button
                          key={t.id}
                          ref={(node) => {
                            if (node) tabButtonRefs.current[t.id] = node;
                          }}
                          type="button"
                          onClick={() => selectDossierTab(t.id)}
                          className={`min-h-[42px] min-w-[9rem] rounded-full px-4 py-2.5 text-sm font-extrabold transition md:min-w-[10rem] ${
                            activeDossierTab === t.id
                              ? "bg-[#1E3C72] text-white shadow-sm"
                              : "border border-gray-200 bg-white text-gray-600 hover:bg-gray-100"
                          }`}
                        >
                          {t.label}
                        </button>
                      ))}
                    </div>
                    {false && [
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
                    <div className="overflow-hidden rounded-[2.2rem] border border-[#EFE3D1] bg-white shadow-sm space-y-6">
                      <h3 className="bg-[#D7AF4B] px-6 py-5 text-2xl font-black text-[#1E3557]">Birth Details</h3>
                      <div className="p-6 mt-0 pt-0 space-y-6">
                        <div className="grid gap-4 sm:grid-cols-2">
                          {kundliSummaryRows(reportData.kundli, form).map(([k, v], i) => (
                            <div key={i} className={detailCellClass}>
                              <span className={detailLabelClass}>{k}</span>
                              <span className={`block ${detailValueClass}`}>{displayValue(v)}</span>
                            </div>
                          ))}
                        </div>

                      </div>
                    </div>
                  )}

                  {/* Astro Details Tab Content */}
                  {activeDossierTab === "astro" && (
                    <div className="overflow-hidden rounded-[2.2rem] border border-[#EFE3D1] bg-white shadow-sm space-y-6">
                      <h3 className="bg-[#D7AF4B] px-6 py-5 text-2xl font-black text-[#1E3557]">Astro Details</h3>
                      <div className="p-6 mt-0 pt-0 space-y-6">
                        {objectTableRows(providerData(reportData.kundli, "astro_details")).length > 0 && (
                          <div className="grid gap-4 sm:grid-cols-2">
                            {objectTableRows(providerData(reportData.kundli, "astro_details")).map(([k, v], i) => (
                              <div key={`${k}-${i}`} className={detailCellClass}>
                                <span className={detailLabelClass}>{k}</span>
                                <span className={`block ${detailValueClass}`}>{displayValue(v)}</span>
                              </div>
                            ))}
                          </div>
                        )}

                        {planetRowsFromPayload(reportData.kundli).length > 0 && (
                          <div className={tableWrapClass}>
                            <table className="w-full min-w-[760px] border-collapse text-left text-xs">
                              <thead>
                                <tr className="bg-[#D7AF4B] text-[#1E3557]">
                                  {["Planet ID", "Planet", "Sign", "Sign Lord", "Full Degree", "Norm Degree", "Speed", "Retrograde", "Nakshatra", "Nakshatra Lord", "Nakshatra Pad", "House", "Motion", "Is Planet Set", "Planet Awastha"].map((heading) => (
                                    <th key={heading} className={tableHeadCellClass}>
                                      {heading}
                                    </th>
                                  ))}
                                </tr>
                              </thead>
                              <tbody>
                                {planetRowsFromPayload(reportData.kundli).map((planet, index) => (
                                  <tr key={`${planet.planet}-${index}`} className={tableBodyRowClass}>
                                    <td className={tableBodyCellClass}>{planet.planetId}</td>
                                    <td className={`${tableBodyCellClass} font-bold text-[#1E3557]`}>{planet.planet}</td>
                                    <td className={tableBodyCellClass}>{planet.sign}</td>
                                    <td className={tableBodyCellClass}>{planet.signLord}</td>
                                    <td className={tableBodyCellClass}>{planet.fullDegree}</td>
                                    <td className={tableBodyCellClass}>{planet.normDegree}</td>
                                    <td className={tableBodyCellClass}>{planet.speed}</td>
                                    <td className={tableBodyCellClass}>{planet.retrograde}</td>
                                    <td className={tableBodyCellClass}>{planet.nakshatra}</td>
                                    <td className={tableBodyCellClass}>{planet.nakshatraLord}</td>
                                    <td className={tableBodyCellClass}>{planet.nakshatraPad}</td>
                                    <td className={tableBodyCellClass}>{planet.house}</td>
                                    <td className={tableBodyCellClass}>{planet.motion}</td>
                                    <td className={tableBodyCellClass}>{planet.isPlanetSet}</td>
                                    <td className={tableBodyCellClass}>{planet.planetAwastha}</td>
                                  </tr>
                                ))}
                              </tbody>
                            </table>
                          </div>
                        )}

                        {/* Positive Yogas present */}
                        {reportData.kundli?.yoga_details && reportData.kundli.yoga_details.length > 0 && (
                          <div className="mt-6 border-t border-gray-100 pt-6">
                            <h4 className="font-bold text-sm text-[#1E3557] mb-3">Positive Yogas Present In Chart:</h4>
                            <div className="grid gap-3">
                              {reportData.kundli.yoga_details.flatMap(g => g.yoga_list || []).filter(y => y.has_yoga).slice(0, 4).map((y, index) => (
                                <div key={index} className="rounded-2xl bg-[#FAF9F6] border border-[#E6D7BA] p-4 text-xs transition-colors hover:bg-[#FFF7DF] active:bg-[#FCE9AE]">
                                  <p className="font-bold text-[#B05B35]">{y.name}</p>
                                  <p className="mt-1 leading-5 text-gray-500">{y.description}</p>
                                </div>
                              ))}
                            </div>
                          </div>
                        )}

                        <div className="border-t border-gray-100 pt-6">
                          <ProviderModulePanels
                            kundli={reportData.kundli}
                            modules={astroDetailModules}
                            emptyText="No additional astro details were returned for this profile."
                          />
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Divisional Charts Tab Content */}
                  {activeDossierTab === "charts" && (
                    <div className="overflow-hidden rounded-[2.2rem] border border-[#EFE3D1] bg-white shadow-sm space-y-6">
                      <div className="flex items-center justify-between gap-4 flex-wrap bg-[#D7AF4B] px-6 py-5">
                        <h3 className="text-2xl font-black text-[#1E3557]">Divisional Charts</h3>
                        <select
                          value={selectedChartType}
                          onChange={(e) => setSelectedChartType(e.target.value)}
                          className="rounded-xl border border-slate-200 bg-[#f8f9fc] px-4 py-2 text-xs outline-none font-bold text-[#1E3557]"
                        >
                          {divisionalChartOptions.map((opt) => (
                            <option key={opt.value} value={opt.value}>{opt.label}</option>
                          ))}
                        </select>
                      </div>

                      <div className="p-6 mt-0 pt-0">
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
                    </div>
                  )}

                  {/* Predictions Tab Content */}
                  {activeDossierTab === "predictions" && (
                    <div className="overflow-hidden rounded-[2.2rem] border border-[#EFE3D1] bg-white shadow-sm space-y-6">
                      <h3 className="bg-[#D7AF4B] px-6 py-5 text-2xl font-black text-[#1E3557]">Life Predictions</h3>
                      <div className="p-6 mt-0 pt-0 space-y-6">
                        <div className="flex flex-wrap gap-2">
                          {predictionTabs.map((area) => (
                            <button
                              key={area.id}
                              type="button"
                              onClick={() => setActivePredictionArea(area.id)}
                              className={`rounded-2xl border px-4 py-3 text-xs font-black transition ${
                                activePredictionArea === area.id
                                  ? `border-transparent bg-gradient-to-br ${area.tone} ${area.accent} shadow-sm`
                                  : "border-[#E6D7BA] bg-white text-gray-600 hover:bg-[#FFF7DF]"
                              }`}
                            >
                              {area.label}
                            </button>
                          ))}
                        </div>

                        <div className="border-t border-gray-100 pt-4">
                          {reportData.predictions[activePredictionArea] ? (
                            predictionBlocks(reportData.predictions[activePredictionArea]).length ? (
                              <div className="space-y-4">
                                {predictionBlocks(reportData.predictions[activePredictionArea]).map((block, index) => (
                                  <div
                                    key={`${block.title}-${index}`}
                                    className={`rounded-3xl border border-[#E6D7BA] bg-gradient-to-br ${predictionTabs.find((area) => area.id === activePredictionArea)?.tone || "from-[#F8FAFC] to-white"} p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md active:translate-y-0`}
                                  >
                                    <h4 className={`text-sm font-black ${predictionTabs.find((area) => area.id === activePredictionArea)?.accent || "text-[#1E3557]"}`}>{block.title}</h4>
                                    <p className="mt-2 whitespace-pre-line text-sm leading-7 text-slate-600">{block.body}</p>
                                  </div>
                                ))}
                              </div>
                            ) : (
                              <p className="rounded-2xl border border-gray-100 bg-slate-50 p-4 text-sm text-slate-500">
                                No prediction text was returned for this section.
                              </p>
                            )
                          ) : (
                            <p className="rounded-2xl border border-gray-100 bg-slate-50 p-4 text-sm text-slate-500">
                              No prediction text was returned for this section.
                            </p>
                          )}
                        </div>
                      </div>
                    </div>
                  )}

                  {activeDossierTab === "biorhythm" && (
                    <div className="overflow-hidden rounded-[2.2rem] border border-[#EFE3D1] bg-white shadow-sm">
                      <h3 className="bg-[#D7AF4B] px-6 py-5 text-2xl font-black text-[#1E3557]">Biorhythm</h3>
                      <div className="p-6">
                        <BiorhythmReport kundli={reportData.kundli} />
                      </div>
                    </div>
                  )}

                  {/* Dashas Tab Content */}
                  {activeDossierTab === "dashas" && (
                    (() => {
                      const currentVdasha = providerData(reportData.kundli, "current_vdasha");
                      const majorVdasha = providerData(reportData.kundli, "major_vdasha");
                      const currentRows = currentDashaRows(currentVdasha);
                      const majorRows = dashaPeriodRows(majorVdasha);

                      return (
                        <div className="space-y-6">
                          <div className="overflow-hidden rounded-[2.2rem] border border-[#EFE3D1] bg-white shadow-sm">
                            <h3 className="bg-[#D7AF4B] px-6 py-5 text-2xl font-black text-[#1E3C72]">Current Vimshottari Dasha</h3>
                            <div className="p-6">
                              {currentRows.length ? (
                                <div className={tableWrapClass}>
                                  <table className="w-full text-left text-sm border-collapse">
                                    <tbody>
                                      {currentRows.map(([label, value], index) => (
                                        <tr key={label} className={`${index % 2 === 0 ? "bg-white" : "bg-[#F8FAFC]"} transition-colors hover:bg-[#FFF7DF] active:bg-[#FCE9AE]`}>
                                          <th className="w-1/3 border border-gray-200 p-3 font-extrabold text-[#1E3C72]">{label}</th>
                                          <td className="border border-gray-200 p-3 text-gray-700">{value}</td>
                                        </tr>
                                      ))}
                                    </tbody>
                                  </table>
                                </div>
                              ) : (
                                <p className="rounded-2xl border border-gray-100 bg-slate-50 p-4 text-sm text-slate-500">No current dasha data returned.</p>
                              )}
                            </div>
                          </div>

                          <div className="overflow-hidden rounded-[2.2rem] border border-[#EFE3D1] bg-white shadow-sm">
                            <h3 className="bg-[#D7AF4B] px-6 py-5 text-2xl font-black text-[#1E3C72]">Vimshottari Maha Dasha</h3>
                            <div className="p-6">
                              <p className="mb-4 text-xs font-semibold uppercase tracking-[0.18em] text-gray-400">Major planetary periods</p>
                              <div className={tableWrapClass}>
                                <table className="w-full text-left text-xs border-collapse">
                                  <thead>
                                    <tr className="bg-[#D7AF4B] font-bold text-[#1E3C72]">
                                      <th className={tableHeadCellClass}>Planet</th>
                                      <th className={tableHeadCellClass}>Planet ID</th>
                                      <th className={tableHeadCellClass}>Start Date</th>
                                      <th className={tableHeadCellClass}>End Date</th>
                                      {majorRows.some((row) => row.duration && row.duration !== "-") && (
                                        <th className={tableHeadCellClass}>Duration</th>
                                      )}
                                      {majorRows.some((row) => row.extraDetails) && (
                                        <th className={tableHeadCellClass}>Other Details</th>
                                      )}
                                    </tr>
                                  </thead>
                                  <tbody>
                                    {majorRows.length ? majorRows.map((row) => (
                                      <tr key={row.id} className={`${tableBodyRowClass} font-semibold`}>
                                        <td className={`${tableBodyCellClass} font-extrabold text-[#1E3C72]`}>{row.planet}</td>
                                        <td className={tableBodyCellClass}>{row.planetId}</td>
                                        <td className={tableBodyCellClass}>{row.start}</td>
                                        <td className={tableBodyCellClass}>{row.end}</td>
                                        {majorRows.some((item) => item.duration && item.duration !== "-") && (
                                          <td className={tableBodyCellClass}>{row.duration}</td>
                                        )}
                                        {majorRows.some((item) => item.extraDetails) && (
                                          <td className={tableBodyCellClass}>{row.extraDetails || "-"}</td>
                                        )}
                                      </tr>
                                    )) : (
                                      <tr>
                                        <td className="p-4 text-center text-gray-500" colSpan={5}>No major dasha data returned.</td>
                                      </tr>
                                    )}
                                  </tbody>
                                </table>
                              </div>
                            </div>
                          </div>
                        </div>
                      );
                    })()
                  )}

                  {/* Gemstone / Rudraksha Tab Content */}
                  {activeDossierTab === "remedies" && (
                    <div className="space-y-6">
                      <GemstoneSuggestionReport result={{ data: reportData.gemstones }} />
                      <RudrakshaSuggestionReport result={{ data: reportData.rudraksha }} />
                    </div>
                  )}

                  {false && activeDossierTab === "remedies" && (
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
                                    ) : <span>{displayValue(item)}</span>}
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
                                  ) : <span>{displayValue(item)}</span>}
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

                  {activeDossierTab === "mangal" && (
                    <MangalDoshaReport result={{ data: reportData.doshas?.mangal }} />
                  )}

                  {activeDossierTab === "pitra" && (
                    <PitraDoshaReport result={{ data: reportData.doshas?.pitra }} />
                  )}

                  {activeDossierTab === "kaal" && (
                    <KaalSarpDoshaReport result={{ data: reportData.doshas?.kaal }} />
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
