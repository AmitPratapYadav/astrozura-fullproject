import React, { useEffect, useMemo, useState } from "react";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { getPanchang, searchLocation } from "../api/prokeralaApi";
import { useAuth } from "../context/AuthContext";
import { ProviderSections } from "../components/report/ReportDataRenderer";
import { KeyValueTable, ReportPanel, ReportTable } from "../components/report/ReportTables";

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
  const dailyStats = [
    { label: "Sunrise", value: summary?.sunrise },
    { label: "Sunset", value: summary?.sunset },
    { label: "Moonrise", value: summary?.moonrise },
    { label: "Moonset", value: summary?.moonset },
    { label: "Current Tithi Ends", value: summary?.current_tithi?.end },
  ];

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
  const summaryRows = [
    ["Vaara", summary?.vaara],
    ["Sunrise", formatTime(summary?.sunrise)],
    ["Sunset", formatTime(summary?.sunset)],
    ["Moonrise", formatTime(summary?.moonrise)],
    ["Moonset", formatTime(summary?.moonset)],
    ["Current Tithi", summary?.current_tithi?.name],
    ["Tithi Ends", formatDate(summary?.current_tithi?.end, { dateStyle: "medium", timeStyle: "short" })],
    ["Current Nakshatra", summary?.current_nakshatra?.name],
    ["Nakshatra Ends", formatDate(summary?.current_nakshatra?.end, { dateStyle: "medium", timeStyle: "short" })],
    ["Current Karana", summary?.current_karana?.name],
    ["Current Yoga", summary?.current_yoga?.name],
  ];
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
  const muhurtaRows = [
    ...auspicious.map((item) => ({ kind: "Auspicious", name: item.name, type: item.type, periods: item.period?.map((period) => `${formatTime(period.start)} to ${formatTime(period.end)}`).join(", ") })),
    ...inauspicious.map((item) => ({ kind: "Avoid", name: item.name, type: item.type, periods: item.period?.map((period) => `${formatTime(period.start)} to ${formatTime(period.end)}`).join(", ") })),
  ];

  return (
    <div className="min-h-screen bg-[#f7f8fb] font-sans text-[#1E3557]">
      {message && (
        <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-xl bg-[#1E3557] px-6 py-3 text-sm font-medium text-white shadow-lg">
          {message}
        </div>
      )}
      <Navbar />

      <section className="relative overflow-hidden bg-[#1e2f59] text-white">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(212,167,60,0.16),transparent_28%),linear-gradient(135deg,rgba(255,255,255,0.03),rgba(255,255,255,0))]"></div>
        <div className="relative max-w-7xl mx-auto px-4 md:px-8 py-20 md:py-24">
          <div className="max-w-2xl">
            <span className="inline-flex rounded-full border border-[#D4A73C]/30 bg-[#D4A73C]/15 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-[#D4A73C]">
              Auspicious Calendar
            </span>
            <h1 className="mt-6 text-4xl md:text-5xl font-black leading-tight">
              Astro Zura Panchang
            </h1>
            <p className="mt-5 max-w-xl text-sm md:text-base leading-7 text-slate-200">
              Unlock the power of Vedic time keeping. Discover daily Tithi, Nakshatra,
              Yoga, Karana, and sacred Muhurat windows to plan important goals with
              cosmic alignment.
            </p>

            <form
              onSubmit={handleSubmit}
              className="mt-8 grid gap-3 rounded-2xl bg-white/10 p-4 backdrop-blur md:grid-cols-[1fr_1.2fr_auto]"
            >
              <input
                type="date"
                value={selectedDate}
                onChange={(e) => void handleDateSelection(e.target.value)}
                className="rounded-xl border border-white/10 bg-[#32446f] px-4 py-3 text-sm text-white outline-none"
              />
              <div className="relative">
                <input
                  type="text"
                  value={place}
                  onChange={(e) => void handleSearchLocation(e.target.value)}
                  placeholder="Search birthplace or city"
                  className="w-full rounded-xl border border-white/10 bg-[#32446f] px-4 py-3 text-sm text-white outline-none"
                />
                {loadingLocation && (
                  <div className="absolute right-3 top-3.5 h-4 w-4 animate-spin rounded-full border-b-2 border-[#D4A73C]"></div>
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
              <button
                type="submit"
                disabled={loading}
                className="rounded-xl bg-[#D4A73C] px-5 py-3 text-sm font-bold text-[#1E3557] transition hover:bg-[#e0b84f] disabled:opacity-60"
              >
                {loading ? "Loading..." : "Calculate Panchang"}
              </button>
            </form>
          </div>
        </div>
      </section>

      <section className="max-w-7xl mx-auto px-4 md:px-8 py-10">
        <div className="grid gap-8 lg:grid-cols-[0.9fr_1.4fr]">
          <aside className="space-y-6">
            <div className="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm">
              <div className="flex items-start justify-between gap-4">
                <div>
                  <h2 className="text-lg font-bold">Calendar View</h2>
                  <p className="mt-1 text-sm text-slate-500">
                    Click any date to load that Panchang instantly
                  </p>
                </div>
                {loading && (
                  <span className="rounded-full bg-amber-50 px-3 py-1 text-[11px] font-semibold uppercase tracking-wide text-amber-700">
                    Refreshing
                  </span>
                )}
              </div>
              <div className="mt-5 rounded-2xl bg-[#f8f9fc] p-4">
                <div className="mb-4 flex items-center justify-between gap-3">
                  <button
                    type="button"
                    onClick={() =>
                      setCalendarMonth(
                        new Date(calendarMonth.getFullYear(), calendarMonth.getMonth() - 1, 1)
                      )
                    }
                    className="h-9 w-9 rounded-full bg-white text-lg font-bold text-slate-600 shadow-sm transition hover:bg-slate-100"
                  >
                    ‹
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
                    className="h-9 w-9 rounded-full bg-white text-lg font-bold text-slate-600 shadow-sm transition hover:bg-slate-100"
                  >
                    ›
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
                        className={`h-9 rounded-full transition ${
                          isSelected
                            ? "bg-[#D4A73C] font-bold text-[#1E3557]"
                            : day
                              ? "text-slate-600 hover:bg-slate-200"
                              : "opacity-0"
                        }`}
                      >
                        {day || "."}
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>

            <div className="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm">
              <h2 className="text-lg font-bold">System Data</h2>
              <div className="mt-4 space-y-4">
                <div className="rounded-2xl bg-[#f8f9fc] p-4">
                  <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                    Data Integration
                  </p>
                  <p className="mt-2 text-sm text-slate-600">
                    Accurate Panchang data generated from the live astrology integration
                    and real coordinates.
                  </p>
                </div>
                <div className="rounded-2xl bg-[#f8f9fc] p-4">
                  <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                    Requested Datetime
                  </p>
                  <p className="mt-2 text-sm font-semibold text-[#1E3557]">
                    {formatDate(data?.requested_datetime, {
                      dateStyle: "medium",
                      timeStyle: "short",
                    })}
                  </p>
                </div>
                <div className="rounded-2xl bg-[#f8f9fc] p-4">
                  <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                    Selected Coordinates
                  </p>
                  <p className="mt-2 text-sm font-semibold text-[#1E3557]">
                    {coordinates || "Select from search"}
                  </p>
                </div>
              </div>
            </div>
          </aside>

          <main className="space-y-6">
            <ReportPanel
              title="Daily Panchang Report"
              subtitle={`Compact Panchang table for ${formatDate(selectedDate, { dateStyle: "long" })}`}
            >
              <KeyValueTable rows={summaryRows} />
            </ReportPanel>

            <ReportPanel title="Panchang Transitions">
              <ReportTable
                compact
                columns={[
                  { key: "label", label: "Transition" },
                  { key: "current", label: "Current" },
                  { key: "next", label: "Next" },
                  { key: "time", label: "Changes At", render: (row) => formatDate(row.time, { dateStyle: "medium", timeStyle: "short" }) },
                ]}
                rows={transitionCards}
              />
            </ReportPanel>

            <ReportPanel title="Panchang Flow Table" subtitle="Tithi, Nakshatra, Karana and Yoga in one compact table">
              <ReportTable
                compact
                columns={[
                  { key: "type", label: "Type" },
                  { key: "name", label: "Name" },
                  { key: "extra", label: "Extra" },
                  { key: "start", label: "Start" },
                  { key: "end", label: "End" },
                  { key: "status", label: "Status" },
                ]}
                rows={flowRows}
              />
            </ReportPanel>

            <ReportPanel title="Muhurat Timing Table" subtitle="Auspicious, avoid, Hora and Chaughadiya summaries">
              <ReportTable
                compact
                columns={[
                  { key: "kind", label: "Kind" },
                  { key: "name", label: "Name" },
                  { key: "type", label: "Type" },
                  { key: "periods", label: "Periods" },
                ]}
                rows={muhurtaRows}
              />
            </ReportPanel>

            <div className="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm">
              <div className="flex items-start justify-between gap-4">
                <div>
                  <h2 className="text-lg font-bold">Daily Summary</h2>
                  <p className="mt-1 text-sm text-slate-500">
                    Panchang events for {formatDate(selectedDate, { dateStyle: "long" })}
                  </p>
                </div>
                <div className="rounded-2xl bg-[#f8f9fc] px-4 py-3 text-right">
                  <p className="text-xs uppercase tracking-wide text-slate-500">Vaara</p>
                  <p className="mt-1 font-bold">{summary?.vaara || "-"}</p>
                </div>
              </div>
              <div className="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
                {dailyStats.map((item) => (
                  <div key={item.label} className="rounded-2xl bg-[#f8f9fc] p-4">
                    <p className="text-[11px] font-semibold uppercase tracking-wide text-slate-500">
                      {item.label}
                    </p>
                    <p className="mt-3 text-base font-bold">{formatTime(item.value)}</p>
                  </div>
                ))}
              </div>
            </div>

            <div className="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm">
              <div className="flex items-center justify-between gap-4">
                <div>
                  <h2 className="text-lg font-bold">Change Watch</h2>
                  <p className="mt-1 text-sm text-slate-500">
                    See what is active and when the next Panchang transition occurs
                  </p>
                </div>
              </div>
              <div className="mt-5 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
                {transitionCards.map((item) => (
                  <div key={item.label} className="rounded-2xl border border-slate-100 bg-[#fffaf0] p-4">
                    <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                      {item.label}
                    </p>
                    <p className="mt-2 text-base font-bold">{item.current || "-"}</p>
                    <p className="mt-1 text-sm text-slate-500">
                      Next: {item.next || "No further shift available"}
                    </p>
                    <p className="mt-3 text-xs text-slate-500">
                      Changes at {formatDate(item.time, { dateStyle: "medium", timeStyle: "short" })}
                    </p>
                  </div>
                ))}
              </div>
            </div>

            <div className="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm">
              <div className="flex items-center justify-between gap-4">
                <div>
                  <h2 className="text-lg font-bold">Detailed Panchang</h2>
                  <p className="mt-1 text-sm text-slate-500">
                    Real Vedic parameters for your selected place and date
                  </p>
                </div>
              </div>
              <div className="mt-5 grid gap-4 md:grid-cols-2">
                {[
                  { label: "Tithi", item: summary?.current_tithi, extra: summary?.current_tithi?.paksha },
                  { label: "Nakshatra", item: summary?.current_nakshatra, extra: summary?.current_nakshatra?.lord?.name },
                  { label: "Karana", item: summary?.current_karana, extra: "" },
                  { label: "Yoga", item: summary?.current_yoga, extra: "" },
                ].map((row) => (
                  <div key={row.label} className="rounded-2xl border border-slate-100 bg-[#fffaf0] p-4">
                    <div className="flex items-center justify-between gap-3">
                      <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                        {row.label}
                      </p>
                      <span className="rounded-full bg-emerald-50 px-3 py-1 text-[11px] font-semibold uppercase tracking-wide text-emerald-700">
                        Active
                      </span>
                    </div>
                    <p className="mt-2 text-lg font-bold">{row.item?.name || "-"}</p>
                    <p className="mt-1 text-sm text-slate-500">{row.extra || "-"}</p>
                    <p className="mt-3 text-xs text-slate-500">
                      Until {formatDate(row.item?.end, { timeStyle: "short", dateStyle: "medium" })}
                    </p>
                  </div>
                ))}
              </div>
            </div>

            <div className="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm">
              <div className="flex items-center justify-between gap-4">
                <div>
                  <h2 className="text-lg font-bold">Panchang Timeline</h2>
                  <p className="mt-1 text-sm text-slate-500">
                    Full day flow for all segments returned for the selected day
                  </p>
                </div>
              </div>

              <div className="mt-6 grid gap-5 xl:grid-cols-2">
                {panchangGroups.map((group) => (
                  <div key={group.key} className="rounded-2xl border border-slate-100 bg-[#f8f9fc] p-5">
                    <div className="flex items-center justify-between gap-3">
                      <h3 className="text-base font-bold">{group.title}</h3>
                      <span className="rounded-full bg-white px-3 py-1 text-[11px] font-semibold uppercase tracking-wide text-slate-500">
                        {group.current?.name || "No active segment"}
                      </span>
                    </div>

                    <div className="mt-4 space-y-3">
                      {group.items.map((item, index) => {
                        const status = getEntryStatus(item, referenceTime);
                        return (
                          <div key={`${group.key}-${item.id || index}`} className="rounded-xl bg-white p-4 shadow-sm">
                            <div className="flex items-center justify-between gap-4">
                              <div>
                                <p className="font-semibold text-[#1E3557]">{item.name || "-"}</p>
                                {group.getExtra(item) && (
                                  <p className="mt-1 text-xs text-slate-500">{group.getExtra(item)}</p>
                                )}
                              </div>
                              <span className={`rounded-full px-3 py-1 text-[11px] font-semibold uppercase tracking-wide ${getStatusClass(status)}`}>
                                {status}
                              </span>
                            </div>
                            <div className="mt-3 flex flex-wrap gap-3 text-sm text-slate-600">
                              <span>Start: {formatDate(item.start, { dateStyle: "medium", timeStyle: "short" })}</span>
                              <span>End: {formatDate(item.end, { dateStyle: "medium", timeStyle: "short" })}</span>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm">
              <div className="flex items-center justify-between gap-4">
                <div>
                  <h2 className="text-lg font-bold">Today's Muhurat</h2>
                  <p className="mt-1 text-sm text-slate-500">
                    Auspicious and inauspicious timing windows
                  </p>
                </div>
              </div>

              <div className="mt-6 grid gap-6 xl:grid-cols-2">
                <div className="rounded-2xl border border-emerald-100 bg-[#f8fff7] p-5">
                  <p className="text-sm font-bold text-emerald-800">Auspicious Timings</p>
                  <div className="mt-4 space-y-3">
                    {auspicious.map((item) => {
                      const status = getTimingStatus(item.period, referenceTime);
                      return (
                        <div key={item.id} className="rounded-xl border border-emerald-100 bg-white p-4">
                          <div className="flex items-center justify-between gap-4">
                            <p className="font-semibold text-[#1E3557]">{item.name}</p>
                            <span className={`rounded-full px-3 py-1 text-[11px] font-semibold uppercase tracking-wide ${getStatusClass(status)}`}>
                              {status}
                            </span>
                          </div>
                          <p className="mt-2 text-xs font-semibold uppercase tracking-wide text-emerald-700">
                            {item.type}
                          </p>
                          <div className="mt-3 space-y-1 text-sm text-slate-600">
                            {item.period?.map((period, index) => (
                              <p key={`${item.id}-${index}`}>
                                {formatTime(period.start)} to {formatTime(period.end)}
                              </p>
                            ))}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>

                <div className="rounded-2xl border border-rose-100 bg-[#fff8f8] p-5">
                  <p className="text-sm font-bold text-rose-800">Avoid These Windows</p>
                  <div className="mt-4 space-y-3">
                    {inauspicious.map((item) => {
                      const status = getTimingStatus(item.period, referenceTime);
                      return (
                        <div key={item.id} className="rounded-xl border border-rose-100 bg-white p-4">
                          <div className="flex items-center justify-between gap-4">
                            <p className="font-semibold text-[#1E3557]">{item.name}</p>
                            <span className={`rounded-full px-3 py-1 text-[11px] font-semibold uppercase tracking-wide ${getStatusClass(status)}`}>
                              {status}
                            </span>
                          </div>
                          <p className="mt-2 text-xs font-semibold uppercase tracking-wide text-rose-700">
                            {item.type}
                          </p>
                          <div className="mt-3 space-y-1 text-sm text-slate-600">
                            {item.period?.map((period, index) => (
                              <p key={`${item.id}-${index}`}>
                                {formatTime(period.start)} to {formatTime(period.end)}
                              </p>
                            ))}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            </div>

            <ProviderSections sections={data?.provider_sections || []} />

            <div className="rounded-3xl bg-[#1e2f59] px-6 py-10 text-center text-white shadow-sm">
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#D4A73C]">
                Stay Updated
              </p>
              <h2 className="mt-3 text-3xl font-black">Never Miss an Auspicious Moment</h2>
              <p className="mt-3 max-w-2xl mx-auto text-sm text-slate-200">
                Subscribe to your daily Panchang notifications and sync auspicious Muhurat
                directly with your digital calendar.
              </p>
              <div className="mt-6 flex flex-wrap justify-center gap-3">
                <button
                  type="button"
                  className="rounded-xl bg-[#D4A73C] px-5 py-3 text-sm font-bold text-[#1E3557]"
                >
                  Subscribe for Daily Alerts
                </button>
                <button
                  type="button"
                  className="rounded-xl border border-white/20 px-5 py-3 text-sm font-semibold text-white"
                >
                  Save as Bookmark
                </button>
              </div>
            </div>
          </main>
        </div>
      </section>

      <Footer />
    </div>
  );
}
