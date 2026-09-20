export const MATCH_DIVISIONAL_CHART_OPTIONS = [
  { value: "rasi", chartId: "D1", label: "D1 - Birth Chart" },
  { value: "moon", chartId: "MOON", label: "Moon Chart" },
  { value: "chalit", chartId: "chalit", label: "Chalit - Chalit Chart" },
  { value: "gochar", chartId: "gochar", label: "Gochar / Transit Chart" },
  { value: "sun", chartId: "SUN", label: "Sun Chart" },
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

const normalizeChartItem = (chart) => {
  if (!chart || typeof chart !== "object") return chart;
  const chartDataSvg =
    typeof chart.chart_data === "string" && chart.chart_data.trim().startsWith("<svg")
      ? chart.chart_data.trim()
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
