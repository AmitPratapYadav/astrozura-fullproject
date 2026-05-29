import { useEffect, useMemo, useState } from "react";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { getPanchang, searchLocation } from "../api/prokeralaApi";
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
    return value.name || value.full_name || value.title || value.value || JSON.stringify(value);
  }
  return String(value);
};

const valueFrom = (...values) => {
  for (const value of values) {
    if (value !== null && value !== undefined && value !== "") return displayValue(value);
  }
  return "-";
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
    return "bg-emerald-100 text-slate-800";
  }
  if (normalised.includes("char")) return "bg-sky-100 text-slate-800";
  return "bg-rose-100 text-slate-800";
};

function FieldShell({ label, children }) {
  return (
    <div>
      <label className="mb-2 block text-sm font-bold text-slate-600">{label}</label>
      {children}
    </div>
  );
}

function MuhurtaTable({ title, rows, rowClass = () => "bg-[#e9f5fb]" }) {
  return (
    <section className="overflow-hidden rounded-md border border-slate-200 bg-white">
      <h3 className="bg-slate-100 px-5 py-4 text-center text-xl font-black text-slate-900">{title}</h3>
      <div>
        {(rows.length ? rows : [{ id: "empty", name: "No data returned", time: "-" }]).map((row) => (
          <div
            key={row.id}
            className={`grid grid-cols-[1fr_1.2fr] border-t border-slate-200 px-5 py-4 text-center text-base ${rowClass(row.name)}`}
          >
            <strong>{row.name}</strong>
            <span className="font-mono text-sm">{row.time}</span>
          </div>
        ))}
      </div>
    </section>
  );
}

function InfoTable({ title, rows }) {
  return (
    <section className="overflow-hidden rounded-sm border border-slate-200 bg-white">
      {title ? <h2 className="border-b border-slate-200 px-5 py-5 text-center text-2xl font-black text-slate-900">{title}</h2> : null}
      <div className="grid grid-cols-2">
        {rows.map(([label, value]) => (
          <div key={label} className="border-b border-r border-slate-200 p-4 even:border-r-0">
            <p className="font-semibold text-slate-900">{label}</p>
            <p className="mt-1 text-sm leading-6 text-slate-500">{value || "-"}</p>
          </div>
        ))}
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
  const today = useMemo(() => getTodayInIndia(), []);
  const [activeView, setActiveView] = useState("daily");
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
      const response = await getPanchang(datetime, coords, 1, { mode, la: nextLanguage });
      if (response?.status === "success") {
        setData(response.data);
      } else {
        showToast(response?.message || "Unable to fetch Panchang.");
      }
    } catch (error) {
      showToast(error?.response?.data?.message || "Unable to fetch Panchang.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchPanchang(selectedDate, coordinates, activeView, language);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

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
  const horaRows = splitMuhurtaRows(panchang.hora, ["hora", "planet", "name"]);
  const chaughadiyaRows = splitMuhurtaRows(panchang.chaughadiya, ["muhurta", "name"]);

  const dailyCardRows = [
    ["Sunrise", formatTime(summary.sunrise || advanced.sunrise || basic.sunrise)],
    ["Sunset", formatTime(summary.sunset || advanced.sunset || basic.sunset)],
    ["Moonrise", formatTime(summary.moonrise || advanced.moonrise || basic.moonrise)],
    ["Moonset", formatTime(summary.moonset || advanced.moonset || basic.moonset)],
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
    ["Vikram Samvat", valueFrom(advanced.vikram_samvat, basic.vikram_samvat, advanced.vikram_samvat_name)],
    ["Shaka Samvat", valueFrom(advanced.shaka_samvat, basic.shaka_samvat, advanced.shaka_samvat_name)],
    ["Paksha", valueFrom(summary.current_tithi?.paksha, advanced.tithi?.details?.paksha)],
    ["Ayana", valueFrom(advanced.ayan, advanced.ayana, basic.ayana)],
    ["Purnimanta", valueFrom(advanced.purnimanta, basic.purnimanta)],
    ["Amanta", valueFrom(advanced.amanta, basic.amanta)],
    ["Sun Sign", valueFrom(advanced.sun_sign, basic.sun_sign)],
    ["Moon Sign", valueFrom(advanced.moon_sign, basic.moon_sign)],
  ];

  const inauspiciousRows = [
    ["Rahu Kalam", valueFrom(advanced.rahukaal?.start && advanced.rahukaal?.end ? `${advanced.rahukaal.start}-${advanced.rahukaal.end}` : null)],
    ["Yamghant Kalam", valueFrom(advanced.yamghant_kaal?.start && advanced.yamghant_kaal?.end ? `${advanced.yamghant_kaal.start}-${advanced.yamghant_kaal.end}` : null)],
    ["Gulika Kalam", valueFrom(advanced.guliKaal?.start && advanced.guliKaal?.end ? `${advanced.guliKaal.start}-${advanced.guliKaal.end}` : null)],
    ["Dur Muhurtam", valueFrom(advanced.dur_muhurat?.start && advanced.dur_muhurat?.end ? `${advanced.dur_muhurat.start}-${advanced.dur_muhurat.end}` : null)],
    ["Varjyam", valueFrom(advanced.varjyam?.start && advanced.varjyam?.end ? `${advanced.varjyam.start}-${advanced.varjyam.end}` : null)],
  ];

  const auspiciousRows = [
    ["Abhijit Muhurta", valueFrom(advanced.abhijit_muhurta?.start && advanced.abhijit_muhurta?.end ? `${advanced.abhijit_muhurta.start}-${advanced.abhijit_muhurta.end}` : null)],
    ["Amrit Kalam", valueFrom(advanced.amrit_kalam?.start && advanced.amrit_kalam?.end ? `${advanced.amrit_kalam.start}-${advanced.amrit_kalam.end}` : null)],
  ];

  return (
    <div className="min-h-screen bg-white font-sans text-[#1E3557]">
      {message && (
        <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-xl bg-[#1E3557] px-6 py-3 text-sm font-medium text-white shadow-lg">
          {message}
        </div>
      )}
      <Navbar />

      <section className="bg-gradient-to-r from-[#1E3557] via-[#315f9d] to-[#D4A73C] text-white">
        <div className="mx-auto max-w-6xl px-4 py-5 md:px-8">
          <h1 className="text-2xl font-black md:text-4xl">
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

          <FieldShell label=" ">
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

          <div className="grid grid-cols-2 gap-3 self-end">
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
              <section className="overflow-hidden rounded-sm border border-slate-200 bg-white">
                <div className="bg-[#D4A73C] p-5 text-white">
                  <h2 className="text-xl font-black">{selectedInputLabel}</h2>
                  <p className="mt-2 text-sm font-semibold">Ayana - {valueFrom(advanced.ayan, advanced.ayana)}</p>
                  <p className="mt-1 text-sm font-semibold">{valueFrom(summary.vaara, advanced.day)}</p>
                </div>
                <div className="grid grid-cols-2">
                  {dailyCardRows.map(([label, value]) => (
                    <div key={label} className="border-b border-r border-slate-200 p-4 even:border-r-0">
                      <p className="font-semibold text-slate-900">{label}</p>
                      <p className="mt-1 text-sm text-slate-500">{value}</p>
                    </div>
                  ))}
                </div>
              </section>

              <section className="overflow-hidden rounded-sm border border-slate-200 bg-white">
                <h2 className="border-b border-slate-200 px-5 py-5 text-center text-2xl font-black text-slate-900">Panchang Elements</h2>
                <div className="divide-y divide-slate-200">
                  {elementRows.map(([label, value]) => (
                    <div key={label} className="grid grid-cols-[118px_1fr]">
                      <p className="border-r border-slate-200 p-4 font-semibold text-slate-900">{label}</p>
                      <p className="p-4 text-slate-700">{value}</p>
                    </div>
                  ))}
                </div>
              </section>

              <InfoTable title="Hindu Month & Year" rows={monthYearRows} />
            </div>

            <section className="overflow-hidden rounded-sm border border-slate-200 bg-white">
              <div className="grid md:grid-cols-[290px_1fr]">
                <div className="bg-[#D4A73C] px-5 py-4 text-lg font-black text-white">Today's Festival & Vratas</div>
                <div className="px-5 py-4 text-lg font-bold text-[#1E3557]">{valueFrom(advanced.festivals, advanced.vrat, basic.festivals, "No festival returned")}</div>
              </div>
            </section>

            <div className="grid gap-8 lg:grid-cols-[2fr_1fr]">
              <InfoTable title="Inauspicious Timing" rows={inauspiciousRows} />
              <InfoTable title="Auspicious Timing" rows={auspiciousRows} />
            </div>

            <section className="max-w-md overflow-hidden rounded-sm border border-slate-200 bg-white">
              <h2 className="border-b border-slate-200 px-5 py-5 text-center text-2xl font-black text-slate-900">Other Yoga</h2>
              <div className="grid grid-cols-[120px_1fr] border-b border-slate-200">
                <p className="border-r border-slate-200 p-4 font-semibold text-slate-900">Anandadi Yog</p>
                <p className="p-4 text-slate-700">{valueFrom(advanced.anandadi_yog, advanced.anandadi_yoga)}</p>
              </div>
              <h3 className="border-b border-slate-200 p-4 text-center font-black text-slate-900">Shool & Nivas</h3>
              <div className="grid grid-cols-2">
                {[
                  ["Disha Shool", valueFrom(advanced.disha_shool)],
                  ["Nakshatra Shool", valueFrom(advanced.nakshatra_shool)],
                  ["Moon Nivash", valueFrom(advanced.moon_nivas, advanced.moon_nivash)],
                ].map(([label, value]) => (
                  <div key={label} className="border-b border-r border-slate-200 p-4 even:border-r-0">
                    <p className="font-semibold text-slate-900">{label}</p>
                    <p className="mt-1 text-sm uppercase text-slate-500">{value}</p>
                  </div>
                ))}
              </div>
            </section>
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
