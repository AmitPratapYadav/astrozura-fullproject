import React, { useEffect, useMemo, useState } from "react";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { getPanchang, searchLocation } from "../api/prokeralaApi";
import { useAuth } from "../context/AuthContext";
import { ProviderSections } from "../components/report/ReportDataRenderer";

const formatDate = (value, options = { dateStyle: "medium" }) => {
  if (!value) return "-";
  try {
    return new Date(value).toLocaleString("en-IN", options);
  } catch {
    return value;
  }
};

const formatTime = (value) =>
  formatDate(value, { hour: "2-digit", minute: "2-digit", hour12: true });

const formatMonthLabel = (value) =>
  value.toLocaleString("en-IN", { month: "long", year: "numeric" });

const getTodayInIndia = () =>
  new Intl.DateTimeFormat("sv-SE", { timeZone: "Asia/Kolkata" }).format(new Date());

const getMonthStartFromDateString = (value) => {
  const [year, month] = value.split("-").map(Number);
  return new Date(year, month - 1, 1);
};

const getDateStringFromParts = (year, monthIndex, day) =>
  `${year}-${String(monthIndex + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`;

const getEntryStatus = (entry, referenceTime) => {
  if (!entry?.start || !entry?.end || !referenceTime) return "scheduled";

  const start = new Date(entry.start);
  const end = new Date(entry.end);
  if (referenceTime >= start && referenceTime <= end) return "current";
  if (referenceTime < start) return "upcoming";
  return "completed";
};

const getStatusClass = (status) => {
  if (status === "current") return "bg-emerald-50 text-emerald-700";
  if (status === "upcoming") return "bg-amber-50 text-amber-700";
  return "bg-slate-100 text-slate-500";
};

const getTimingStatus = (periods, referenceTime) => {
  if (!referenceTime) return "scheduled";
  for (const period of periods || []) {
    if (!period?.start || !period?.end) continue;
    const start = new Date(period.start);
    const end = new Date(period.end);
    if (referenceTime >= start && referenceTime <= end) return "current";
    if (referenceTime < start) return "upcoming";
  }
  return "completed";
};

const getNextEntryName = (entries, currentEntry) => {
  if (!entries?.length || !currentEntry?.end) return null;
  return entries.find((entry) => entry?.start && entry.start > currentEntry.end)?.name || null;
};

const buildTransitionCards = (summary, panchang) => {
  if (!summary || !panchang) return [];

  return [
    {
      label: "Tithi Transition",
      current: summary.current_tithi?.name,
      next: getNextEntryName(panchang.tithi, summary.current_tithi),
      time: summary.current_tithi?.end,
    },
    {
      label: "Nakshatra Transition",
      current: summary.current_nakshatra?.name,
      next: getNextEntryName(panchang.nakshatra, summary.current_nakshatra),
      time: summary.current_nakshatra?.end,
    },
    {
      label: "Karana Transition",
      current: summary.current_karana?.name,
      next: getNextEntryName(panchang.karana, summary.current_karana),
      time: summary.current_karana?.end,
    },
    {
      label: "Yoga Transition",
      current: summary.current_yoga?.name,
      next: getNextEntryName(panchang.yoga, summary.current_yoga),
      time: summary.current_yoga?.end,
    },
  ].filter((item) => item.current || item.next || item.time);
};

export default function Panchang() {
  const { user } = useAuth();
  const today = useMemo(() => getTodayInIndia(), []);
  const [selectedDate, setSelectedDate] = useState(today);
  const [calendarMonth, setCalendarMonth] = useState(getMonthStartFromDateString(today));
  const [place, setPlace] = useState(user?.place_of_birth || "New Delhi, Delhi, India");
  const [coordinates, setCoordinates] = useState(
    user?.latitude != null && user?.longitude != null
      ? `${user.latitude},${user.longitude}`
      : "28.6139,77.2090"
  );
  const [results, setResults] = useState([]);
  const [loadingLocation, setLoadingLocation] = useState(false);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [data, setData] = useState(null);

  useEffect(() => {
    void fetchPanchang(selectedDate, coordinates);
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const showToast = (text) => {
    setMessage(text);
    window.clearTimeout(window.__astrozuraPanchangToast);
    window.__astrozuraPanchangToast = window.setTimeout(() => setMessage(""), 3500);
  };

  const fetchPanchang = async (date, coords) => {
    try {
      setLoading(true);
      const datetime = `${date}T06:00:00+05:30`;
      const response = await getPanchang(datetime, coords);
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

  const handleSearchLocation = async (value) => {
    setPlace(value);
    setCoordinates("");
    if (value.trim().length < 3) return setResults([]);
    try {
      setLoadingLocation(true);
      const response = await searchLocation(value.trim());
      setResults(response?.data || []);
    } finally {
      setLoadingLocation(false);
    }
  };

  const handleDateSelection = async (date) => {
    setSelectedDate(date);
    setCalendarMonth(getMonthStartFromDateString(date));
    if (coordinates) {
      await fetchPanchang(date, coordinates);
    }
  };

  const selectLocation = async (item) => {
    const nextCoordinates = `${item.coordinates.latitude},${item.coordinates.longitude}`;
    setPlace(item.name);
    setCoordinates(nextCoordinates);
    setResults([]);
    await fetchPanchang(selectedDate, nextCoordinates);
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    if (!coordinates) {
      showToast("Select a valid location from the dropdown.");
      return;
    }
    await fetchPanchang(selectedDate, coordinates);
  };

  const moveDate = async (offset) => {
    const nextDate = new Date(`${selectedDate}T00:00:00+05:30`);
    nextDate.setDate(nextDate.getDate() + offset);
    await handleDateSelection(new Intl.DateTimeFormat("sv-SE", { timeZone: "Asia/Kolkata" }).format(nextDate));
  };

  const calendarDays = useMemo(() => {
    const year = calendarMonth.getFullYear();
    const month = calendarMonth.getMonth();
    const startDay = calendarMonth.getDay();
    const daysInMonth = new Date(year, month + 1, 0).getDate();
    const cells = [];
    for (let i = 0; i < startDay; i += 1) cells.push(null);
    for (let day = 1; day <= daysInMonth; day += 1) cells.push(day);
    return cells;
  }, [calendarMonth]);

  const summary = data?.summary;
  const panchang = data?.panchang;
  const referenceTime = data?.requested_datetime ? new Date(data.requested_datetime) : null;
  const auspicious = panchang?.auspicious_period || [];
  const inauspicious = panchang?.inauspicious_period || [];
  const panchangGroups = [
    {
      title: "Tithi Flow",
      key: "tithi",
      current: summary?.current_tithi,
      items: panchang?.tithi || [],
      getExtra: (item) => item?.paksha,
    },
    {
      title: "Nakshatra Flow",
      key: "nakshatra",
      current: summary?.current_nakshatra,
      items: panchang?.nakshatra || [],
      getExtra: (item) => item?.lord?.name || item?.lord?.vedic_name,
    },
    {
      title: "Karana Flow",
      key: "karana",
      current: summary?.current_karana,
      items: panchang?.karana || [],
      getExtra: () => null,
    },
    {
      title: "Yoga Flow",
      key: "yoga",
      current: summary?.current_yoga,
      items: panchang?.yoga || [],
      getExtra: () => null,
    },
  ];

  const transitionCards = buildTransitionCards(summary, panchang);
  const selectedDateLabel = formatDate(`${selectedDate}T00:00:00+05:30`, { dateStyle: "full" });
  const selectedLongDate = formatDate(`${selectedDate}T00:00:00+05:30`, { dateStyle: "long" });
  const topDailyStats = [
    { label: "Sunrise", value: formatTime(summary?.sunrise) },
    { label: "Sunset", value: formatTime(summary?.sunset) },
    { label: "Moonrise", value: formatTime(summary?.moonrise) },
    { label: "Moonset", value: formatTime(summary?.moonset) },
    { label: "Vaara", value: summary?.vaara || "-" },
    { label: "Place", value: place || "-" },
  ];
  const panchangElementRows = [
    ["Tithi", `${summary?.current_tithi?.name || "-"}${summary?.current_tithi?.end ? ` until ${formatTime(summary.current_tithi.end)}` : ""}`],
    ["Nakshatra", `${summary?.current_nakshatra?.name || "-"}${summary?.current_nakshatra?.end ? ` until ${formatTime(summary.current_nakshatra.end)}` : ""}`],
    ["Yoga", `${summary?.current_yoga?.name || "-"}${summary?.current_yoga?.end ? ` until ${formatTime(summary.current_yoga.end)}` : ""}`],
    ["Karana", `${summary?.current_karana?.name || "-"}${summary?.current_karana?.end ? ` until ${formatTime(summary.current_karana.end)}` : ""}`],
  ];
  const systemRows = [
    ["Requested Datetime", formatDate(data?.requested_datetime, { dateStyle: "medium", timeStyle: "short" })],
    ["Selected Coordinates", coordinates || "Select from search"],
    ["Current Tithi Paksha", summary?.current_tithi?.paksha || "-"],
    ["Nakshatra Lord", summary?.current_nakshatra?.lord?.name || summary?.current_nakshatra?.lord?.vedic_name || "-"],
    ["Current Tithi Ends", formatDate(summary?.current_tithi?.end, { dateStyle: "medium", timeStyle: "short" })],
    ["Current Nakshatra Ends", formatDate(summary?.current_nakshatra?.end, { dateStyle: "medium", timeStyle: "short" })],
  ];
  const timingGridRows = (items) =>
    items.map((item) => ({
      key: item.id || `${item.name}-${item.type}`,
      name: item.name || item.type || "-",
      type: item.type || "-",
      periods: item.period?.map((period) => `${formatTime(period.start)} to ${formatTime(period.end)}`).join(", ") || "-",
      status: getTimingStatus(item.period, referenceTime),
    }));
  const auspiciousRows = timingGridRows(auspicious);
  const inauspiciousRows = timingGridRows(inauspicious);
  const flowRows = panchangGroups.flatMap((group) =>
    group.items.map((item, index) => ({
      id: `${group.key}-${index}`,
      type: group.title.replace(" Flow", ""),
      name: item.name || "-",
      extra: group.getExtra(item) || "-",
      start: formatDate(item.start, { dateStyle: "medium", timeStyle: "short" }),
      end: formatDate(item.end, { dateStyle: "medium", timeStyle: "short" }),
      status: getEntryStatus(item, referenceTime),
    }))
  );
  return (
    <div className="min-h-screen bg-[#f7f8fb] font-sans text-[#1E3557]">
      {message && (
        <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-xl bg-[#1E3557] px-6 py-3 text-sm font-medium text-white shadow-lg">
          {message}
        </div>
      )}
      <Navbar />

      <section className="bg-gradient-to-r from-[#2862df] via-[#6752df] to-[#a92fe5] text-white">
        <div className="mx-auto max-w-7xl px-4 py-8 md:px-8">
          <h1 className="text-3xl font-black leading-tight md:text-4xl">
            Astro Zura Panchang
          </h1>
          <p className="mt-2 text-sm font-semibold text-white/85">{selectedDateLabel}</p>
        </div>
      </section>

      <section className="border-b border-slate-200 bg-white">
        <form
          onSubmit={handleSubmit}
          className="mx-auto grid max-w-7xl gap-5 px-4 py-5 md:px-8 lg:grid-cols-[220px_minmax(260px,1fr)_290px]"
        >
          <div>
            <label className="mb-2 block text-sm font-bold text-slate-600">Select Date</label>
            <input
              type="date"
              value={selectedDate}
              onChange={(e) => void handleDateSelection(e.target.value)}
              className="h-14 w-full rounded-lg border border-slate-300 bg-white px-4 text-base text-[#1E3557] outline-none focus:border-[#2862df]"
            />
          </div>

          <div>
            <label className="mb-2 block text-sm font-bold text-slate-600">Select Panchang Place</label>
            <div className="relative">
              <input
                type="text"
                value={place}
                onChange={(e) => void handleSearchLocation(e.target.value)}
                placeholder="Search city"
                className="h-14 w-full rounded-lg border border-slate-300 bg-white px-4 text-base text-[#1E3557] outline-none focus:border-[#2862df]"
              />
              {loadingLocation && (
                <div className="absolute right-4 top-5 h-4 w-4 animate-spin rounded-full border-b-2 border-[#D4A73C]"></div>
              )}
              {results.length > 0 && (
                <div className="absolute z-50 mt-1 max-h-60 w-full overflow-y-auto rounded-xl border border-slate-200 bg-white text-[#1E3557] shadow-xl">
                  {results.map((item, index) => (
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
          </div>

          <div className="grid grid-cols-2 gap-3 self-end">
            <button
              type="button"
              onClick={() => void moveDate(-1)}
              className="h-14 rounded-lg bg-[#347df0] px-5 text-base font-bold text-white transition hover:bg-[#2862df]"
            >
              Previous
            </button>
            <button
              type="button"
              onClick={() => void moveDate(1)}
              className="h-14 rounded-lg bg-[#347df0] px-5 text-base font-bold text-white transition hover:bg-[#2862df]"
            >
              Next
            </button>
          </div>
        </form>
      </section>

      <section className="mx-auto max-w-7xl px-4 py-10 md:px-8">
        <div className="grid gap-8 lg:grid-cols-3">
          <section className="overflow-hidden rounded-lg border border-slate-200 bg-white">
            <div className="bg-[#f0b900] p-5 text-white">
              <div className="flex items-start justify-between gap-4">
                <div>
                  <h2 className="text-xl font-black">{selectedLongDate}</h2>
                  <p className="mt-2 text-sm font-semibold">{summary?.vaara || "Daily Panchang"}</p>
                  <p className="mt-1 text-sm text-white/90">{place}</p>
                </div>
                {loading && (
                  <span className="rounded-full border border-white/60 px-3 py-1 text-[11px] font-bold uppercase">
                    Refreshing
                  </span>
                )}
              </div>
            </div>
            <div className="grid grid-cols-2 border-t border-slate-200 sm:grid-cols-3">
              {topDailyStats.map((item) => (
                <div key={item.label} className="border-b border-r border-slate-200 p-4 even:border-r-0">
                  <p className="font-semibold text-slate-900">{item.label}</p>
                  <p className="mt-1 text-sm text-slate-500">{item.value}</p>
                </div>
              ))}
            </div>
          </section>

          <section className="overflow-hidden rounded-lg border border-slate-200 bg-white">
            <h2 className="border-b border-slate-200 px-5 py-5 text-center text-2xl font-black text-slate-900">
              Panchang Elements
            </h2>
            <div className="divide-y divide-slate-200">
              {panchangElementRows.map(([label, value]) => (
                <div key={label} className="grid grid-cols-[120px_1fr]">
                  <p className="border-r border-slate-200 p-4 font-semibold text-slate-900">{label}</p>
                  <p className="p-4 text-slate-700">{value || "-"}</p>
                </div>
              ))}
            </div>
          </section>

          <section className="overflow-hidden rounded-lg border border-slate-200 bg-white">
            <h2 className="border-b border-slate-200 px-5 py-5 text-center text-2xl font-black text-slate-900">
              System Data
            </h2>
            <div className="grid grid-cols-2">
              {systemRows.map(([label, value]) => (
                <div key={label} className="border-b border-r border-slate-200 p-4 even:border-r-0">
                  <p className="font-semibold text-slate-900">{label}</p>
                  <p className="mt-1 text-sm text-slate-500">{value}</p>
                </div>
              ))}
            </div>
          </section>
        </div>

        <section className="mt-8 overflow-hidden rounded-lg border border-slate-200 bg-white">
          <div className="grid md:grid-cols-[280px_1fr]">
            <div className="bg-[#ffcc1d] px-5 py-4 text-lg font-black text-white">
              Daily Summary
            </div>
            <div className="px-5 py-4 text-lg font-bold text-[#1E3557]">
              {summary?.current_tithi?.name || summary?.current_nakshatra?.name || "Daily Panchang"}
            </div>
          </div>
        </section>

        <div className="mt-8 grid gap-8 lg:grid-cols-[2fr_1fr]">
          <section className="overflow-hidden rounded-lg border border-rose-100 bg-[#fff8f8]">
            <h2 className="border-b border-rose-100 px-5 py-5 text-center text-2xl font-black text-slate-900">
              Avoid These Windows
            </h2>
            <div className="grid sm:grid-cols-2 xl:grid-cols-3">
              {(inauspiciousRows.length ? inauspiciousRows : [{ key: "empty", name: "No timing returned", type: "-", periods: "-", status: "scheduled" }]).map((item) => (
                <div key={item.key} className="border-b border-r border-rose-100 p-4">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-semibold text-slate-900">{item.name}</p>
                      <p className="mt-1 text-xs font-semibold uppercase tracking-wide text-rose-700">{item.type}</p>
                    </div>
                    <span className={`rounded-full px-2 py-1 text-[10px] font-semibold uppercase tracking-wide ${getStatusClass(item.status)}`}>
                      {item.status}
                    </span>
                  </div>
                  <p className="mt-3 text-sm text-slate-500">{item.periods}</p>
                </div>
              ))}
            </div>
          </section>

          <section className="overflow-hidden rounded-lg border border-emerald-100 bg-[#effdf5]">
            <h2 className="border-b border-emerald-100 px-5 py-5 text-center text-2xl font-black text-slate-900">
              Auspicious Timings
            </h2>
            <div className="grid sm:grid-cols-2 lg:grid-cols-1">
              {(auspiciousRows.length ? auspiciousRows : [{ key: "empty", name: "No timing returned", type: "-", periods: "-", status: "scheduled" }]).map((item) => (
                <div key={item.key} className="border-b border-r border-emerald-100 p-4">
                  <div className="flex items-start justify-between gap-3">
                    <div>
                      <p className="font-semibold text-slate-900">{item.name}</p>
                      <p className="mt-1 text-xs font-semibold uppercase tracking-wide text-emerald-700">{item.type}</p>
                    </div>
                    <span className={`rounded-full px-2 py-1 text-[10px] font-semibold uppercase tracking-wide ${getStatusClass(item.status)}`}>
                      {item.status}
                    </span>
                  </div>
                  <p className="mt-3 text-sm text-slate-500">{item.periods}</p>
                </div>
              ))}
            </div>
          </section>
        </div>

        <div className="mt-8 grid gap-8 lg:grid-cols-[0.85fr_1.15fr]">
          <section className="overflow-hidden rounded-lg border border-slate-200 bg-white">
            <h2 className="border-b border-slate-200 px-5 py-5 text-center text-2xl font-black text-slate-900">
              Calendar View
            </h2>
            <div className="p-5">
              <div className="mb-4 flex items-center justify-between gap-3">
                <button
                  type="button"
                  onClick={() =>
                    setCalendarMonth(
                      new Date(calendarMonth.getFullYear(), calendarMonth.getMonth() - 1, 1)
                    )
                  }
                  className="h-10 w-10 rounded-lg border border-slate-200 bg-white text-lg font-bold text-slate-600 transition hover:bg-slate-50"
                >
                  &lt;
                </button>
                <div className="text-center">
                  <p className="font-semibold">{formatMonthLabel(calendarMonth)}</p>
                  <p className="text-xs text-slate-500">{place}</p>
                </div>
                <button
                  type="button"
                  onClick={() =>
                    setCalendarMonth(
                      new Date(calendarMonth.getFullYear(), calendarMonth.getMonth() + 1, 1)
                    )
                  }
                  className="h-10 w-10 rounded-lg border border-slate-200 bg-white text-lg font-bold text-slate-600 transition hover:bg-slate-50"
                >
                  &gt;
                </button>
              </div>
              <div className="grid grid-cols-7 gap-2 text-center text-xs text-slate-400">
                {["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"].map((day) => (
                  <span key={day}>{day}</span>
                ))}
              </div>
              <div className="mt-3 grid grid-cols-7 gap-2 text-center text-sm">
                {calendarDays.map((day, index) => {
                  const dateValue = day
                    ? getDateStringFromParts(
                        calendarMonth.getFullYear(),
                        calendarMonth.getMonth(),
                        day
                      )
                    : null;
                  const isSelected = day && dateValue === selectedDate;

                  return (
                    <button
                      key={`${day}-${index}`}
                      type="button"
                      disabled={!day}
                      onClick={() => dateValue && void handleDateSelection(dateValue)}
                      className={`h-9 rounded-lg transition ${
                        isSelected
                          ? "bg-[#347df0] font-bold text-white"
                          : day
                            ? "text-slate-600 hover:bg-slate-100"
                            : "opacity-0"
                      }`}
                    >
                      {day || "."}
                    </button>
                  );
                })}
              </div>
            </div>
          </section>

          <section className="overflow-hidden rounded-lg border border-slate-200 bg-white">
            <h2 className="border-b border-slate-200 px-5 py-5 text-center text-2xl font-black text-slate-900">
              Panchang Transitions
            </h2>
            <div className="grid sm:grid-cols-2">
              {(transitionCards.length ? transitionCards : [{ label: "No transitions returned", current: "-", next: "-", time: null }]).map((item) => (
                <div key={item.label} className="border-b border-r border-slate-200 p-4 even:border-r-0">
                  <p className="font-semibold text-slate-900">{item.label}</p>
                  <p className="mt-2 text-sm text-slate-500">Current: {item.current || "-"}</p>
                  <p className="mt-1 text-sm text-slate-500">Next: {item.next || "-"}</p>
                  <p className="mt-3 text-xs text-slate-500">
                    Changes at {formatDate(item.time, { dateStyle: "medium", timeStyle: "short" })}
                  </p>
                </div>
              ))}
            </div>
          </section>
        </div>

        <section className="mt-8 overflow-hidden rounded-lg border border-slate-200 bg-white">
          <h2 className="border-b border-slate-200 px-5 py-5 text-center text-2xl font-black text-slate-900">
            Panchang Flow Table
          </h2>
          <div className="overflow-x-auto">
            <table className="w-full min-w-[760px] border-collapse text-left text-sm">
              <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-500">
                <tr>
                  {["Type", "Name", "Extra", "Start", "End", "Status"].map((heading) => (
                    <th key={heading} className="border-b border-r border-slate-200 px-4 py-3 font-bold last:border-r-0">
                      {heading}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {flowRows.map((row) => (
                  <tr key={row.id} className="border-b border-slate-200">
                    <td className="border-r border-slate-200 px-4 py-3 font-semibold text-slate-900">{row.type}</td>
                    <td className="border-r border-slate-200 px-4 py-3">{row.name}</td>
                    <td className="border-r border-slate-200 px-4 py-3">{row.extra}</td>
                    <td className="border-r border-slate-200 px-4 py-3">{row.start}</td>
                    <td className="border-r border-slate-200 px-4 py-3">{row.end}</td>
                    <td className="px-4 py-3">
                      <span className={`rounded-full px-3 py-1 text-[11px] font-semibold uppercase tracking-wide ${getStatusClass(row.status)}`}>
                        {row.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

        <ProviderSections sections={data?.provider_sections || []} />
      </section>

      <Footer />
    </div>
  );
}
