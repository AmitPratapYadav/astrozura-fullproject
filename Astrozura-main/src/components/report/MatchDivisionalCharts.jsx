import { useEffect, useMemo, useState } from "react";

export const MATCH_DIVISIONAL_CHART_OPTIONS = [
  { value: "chalit", chartId: "chalit", label: "Chalit - Chalit Chart" },
  { value: "gochar", chartId: "gochar", label: "Gochar / Transit Chart" },
  { value: "sun", chartId: "SUN", label: "Sun Chart" },
  { value: "moon", chartId: "MOON", label: "Moon Chart" },
  { value: "rasi", chartId: "D1", label: "D1 - Birth Chart" },
  { value: "hora", chartId: "D2", label: "D2 - Hora Chart" },
  { value: "drekkana", chartId: "D3", label: "D3 - Dreshkan Chart" },
  { value: "chaturthamsa", chartId: "D4", label: "D4 - Chathurthamasha Chart" },
  { value: "panchamsa", chartId: "D5", label: "D5 - Panchmamsha Chart" },
  { value: "saptamsa", chartId: "D7", label: "D7 - Saptamsa Chart" },
  { value: "ashtamsa", chartId: "D8", label: "D8 - Ashtamsa Chart" },
  { value: "navamsa", chartId: "D9", label: "D9 - Navamansha Chart" },
  { value: "dasamsa", chartId: "D10", label: "D10 - Dashamansha Chart" },
  { value: "dwadasamsa", chartId: "D12", label: "D12 - Dwadashamsha Chart" },
  { value: "shodasamsa", chartId: "D16", label: "D16 - Shodashamsha Chart" },
  { value: "vimsamsa", chartId: "D20", label: "D20 - Vishamansha Chart" },
  { value: "chaturvimsamsa", chartId: "D24", label: "D24 - Chaturvimshamsha Chart" },
  { value: "bhamsa", chartId: "D27", label: "D27 - Bhamsa Chart" },
  { value: "trimsamsa", chartId: "D30", label: "D30 - Trishamansha Chart" },
  { value: "khavedamsa", chartId: "D40", label: "D40 - Khavedamsha Chart" },
  { value: "akshavedamsa", chartId: "D45", label: "D45 - Akshvedansha Chart" },
  { value: "shastiamsa", chartId: "D60", label: "D60 - Shashtymsha Chart" },
];

export const MATCH_DIVISIONAL_CHART_TYPES = MATCH_DIVISIONAL_CHART_OPTIONS.map((chart) => chart.value);

const parseProviderMessage = (message) => {
  if (!message) return "";
  if (typeof message !== "string") return String(message);

  try {
    const parsed = JSON.parse(message);
    return parsed.msg || parsed.message || message;
  } catch {
    return message;
  }
};

const normalizeChartItem = (chart) => {
  if (!chart || typeof chart !== "object") return chart;
  const chartDataSvg =
    typeof chart.chart_data === "string" && chart.chart_data.trim().startsWith("<svg")
      ? chart.chart_data
      : chart.chart_data?.svg;

  return {
    ...chart,
    chart_svg: chart.chart_svg || chart.svg || chartDataSvg || null,
  };
};

export const normalizeMatchCharts = (response) => {
  const charts = response?.data?.charts || response?.charts || response?.data || response;
  return Array.isArray(charts) ? charts.map(normalizeChartItem) : [];
};

const chartKey = (value) => String(value || "").toLowerCase();

const findChart = (charts, option) =>
  option
    ? (Array.isArray(charts) ? charts : []).find((chart) => {
    const chartId = chartKey(chart?.chart_id);
    const chartType = chartKey(chart?.chart_type);
    return chartId === chartKey(option.chartId) || chartType === chartKey(option.value);
    })
    : null;

function PersonChartPanel({ label, chart }) {
  const message = parseProviderMessage(chart?.message);

  return (
    <div className="overflow-hidden rounded-2xl border border-[#E5D3A8] bg-white shadow-sm">
      <div className="flex items-center justify-between gap-3 border-b border-[#EAD79D] bg-[#FFF8E6] px-4 py-3">
        <h5 className="text-sm font-black text-[#1E3557]">{label}</h5>
        {chart?.status === "error" && (
          <span className="rounded-full bg-red-50 px-3 py-1 text-[11px] font-black text-red-700">Unavailable</span>
        )}
      </div>

      {chart?.chart_svg ? (
        <div className="p-4">
          <div
            className="mx-auto w-full max-w-[520px] overflow-x-auto rounded-xl bg-white p-3 [&_svg]:mx-auto [&_svg]:block [&_svg]:h-auto [&_svg]:max-w-full"
            dangerouslySetInnerHTML={{ __html: chart.chart_svg }}
          />
        </div>
      ) : (
        <div className="p-4">
          <p className="rounded-2xl bg-slate-50 px-4 py-3 text-sm font-semibold leading-6 text-slate-600">
            {message || "This chart was not returned for this profile."}
          </p>
        </div>
      )}
    </div>
  );
}

export default function MatchDivisionalCharts({ charts, title = "Match Divisional Charts" }) {
  const [selectedChartId, setSelectedChartId] = useState("D1");

  const availableOptions = useMemo(() => {
    const maleCharts = Array.isArray(charts?.male) ? charts.male : [];
    const femaleCharts = Array.isArray(charts?.female) ? charts.female : [];
    const both = [...maleCharts, ...femaleCharts];

    if (!both.length) return MATCH_DIVISIONAL_CHART_OPTIONS;

    return MATCH_DIVISIONAL_CHART_OPTIONS.filter((option) => findChart(both, option));
  }, [charts]);

  useEffect(() => {
    if (!availableOptions.some((option) => option.chartId === selectedChartId)) {
      setSelectedChartId(availableOptions[0]?.chartId || "D1");
    }
  }, [availableOptions, selectedChartId]);

  const selectedOption =
    availableOptions.find((option) => option.chartId === selectedChartId) || availableOptions[0];

  if ((!charts?.male?.length && !charts?.female?.length) || !availableOptions.length) {
    return (
      <div className="rounded-2xl border border-[#EAD79D] bg-[#FFFDF7] p-4">
        <h4 className="text-sm font-black text-[#1E3557]">{title}</h4>
        <p className="mt-2 text-sm font-semibold text-slate-500">Charts are unavailable for this report.</p>
      </div>
    );
  }

  const maleChart = findChart(charts?.male, selectedOption);
  const femaleChart = findChart(charts?.female, selectedOption);

  return (
    <section className="mt-5 rounded-2xl border border-[#EAD79D] bg-[#FFFDF7] p-4">
      <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
        <div>
          <h4 className="text-base font-black text-[#1E3557]">{title}</h4>
          <p className="mt-1 text-xs font-semibold text-[#7A6B4A]">
            Select a chart to compare male and female placements side by side.
          </p>
        </div>
        <div className="flex flex-col gap-1 md:min-w-[280px]">
          <label className="text-[11px] font-black uppercase tracking-[0.16em] text-[#8A98AE]">Select Chart</label>
          <select
            value={selectedOption?.chartId || ""}
            onChange={(event) => setSelectedChartId(event.target.value)}
            className="rounded-2xl border border-[#D9C695] bg-white px-4 py-3 text-sm font-bold text-[#1E3557] outline-none focus:border-[#D4A73C]"
          >
            {availableOptions.map((option) => (
              <option key={option.chartId} value={option.chartId}>
                {option.label}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="mt-4 grid gap-4 xl:grid-cols-2">
        <PersonChartPanel label="Male Chart" chart={maleChart} />
        <PersonChartPanel label="Female Chart" chart={femaleChart} />
      </div>
    </section>
  );
}
