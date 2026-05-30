import React from "react";
import { KeyValueTable, ReportPanel, ReportTable, SimpleTextTable } from "./ReportTables";
import { displayCell, formatReportLabel } from "./reportUtils";
import rudrakshaFallbackImage from "../../assets/rudraksha mala.png";

const isObject = (value) => value && typeof value === "object" && !Array.isArray(value);

const stripHtml = (value) =>
  String(value || "")
    .replace(/<\/p>\s*<p[^>]*>/gi, "\n")
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<[^>]*>/g, " ")
    .replace(/\s+/g, " ")
    .trim();

const parseMaybeJson = (value) => {
  if (typeof value !== "string") return value;
  const trimmed = value.trim();
  if (!trimmed || !/^[{[]/.test(trimmed)) return value;
  try {
    return JSON.parse(trimmed);
  } catch {
    return value;
  }
};

const paragraphsFromText = (value) => {
  if (!value) return [];
  return String(value)
    .replace(/<\/p>\s*<p[^>]*>/gi, "\n")
    .replace(/<p[^>]*>/gi, "")
    .replace(/<\/p>/gi, "\n")
    .replace(/<br\s*\/?>/gi, "\n")
    .split(/\n+/)
    .map(stripHtml)
    .filter(Boolean);
};

const renderCleanValue = (value) => {
  if (React.isValidElement(value)) return value;
  const parsed = parseMaybeJson(value);
  if (parsed === null || parsed === undefined || parsed === "") return "-";
  if (Array.isArray(parsed)) return parsed.map((item) => renderCleanValue(item)).join(", ");
  if (isObject(parsed)) {
    return Object.entries(parsed)
      .map(([key, item]) => `${formatReportLabel(key)}: ${renderCleanValue(item)}`)
      .join(" | ");
  }
  return stripHtml(displayCell(parsed));
};

const AttributeTable = ({ rows = [], emptyText = "No data returned." }) => (
  <div className="overflow-x-auto rounded-sm border border-gray-200 bg-white">
    <table className="min-w-full border-collapse text-sm">
      <tbody>
        {rows.length > 0 ? (
          rows.map(([label, value], index) => (
            <tr key={`${label}-${index}`} className={index % 2 === 0 ? "bg-white" : "bg-gray-50"}>
              <th className="w-[24%] min-w-36 border-b border-gray-200 px-4 py-3 text-left align-top font-bold text-gray-900">
                {label}
              </th>
              <td className="border-b border-gray-200 px-4 py-3 align-top leading-7 text-gray-800">
                {renderCleanValue(value)}
              </td>
            </tr>
          ))
        ) : (
          <tr>
            <td className="px-4 py-5 text-center text-gray-500">{emptyText}</td>
          </tr>
        )}
      </tbody>
    </table>
  </div>
);

const TextBlock = ({ value }) => {
  const paragraphs = paragraphsFromText(value);
  if (!paragraphs.length) return null;
  return (
    <div className="space-y-3 text-sm leading-7 text-gray-800">
      {paragraphs.map((paragraph, index) => (
        <p key={index}>{paragraph}</p>
      ))}
    </div>
  );
};

const StatusBadge = ({ value }) => {
  const positive = /yes|present|active|true/i.test(String(value));
  return (
    <span className={`inline-flex rounded-full px-3 py-1 text-xs font-black ${positive ? "bg-amber-100 text-amber-800" : "bg-emerald-100 text-emerald-800"}`}>
      {value}
    </span>
  );
};

const getSuccessData = (providerPayload = {}, key) => {
  const item = providerPayload?.[key];
  if (!item) return null;
  return item.status === "success" ? item.data : item.data || null;
};

const providerErrorRows = (providerPayload = {}) =>
  Object.entries(providerPayload || {})
    .filter(([, item]) => isObject(item) && item.status === "error")
    .map(([key, item], index) => ({
      id: index + 1,
      endpoint: item.endpoint || key,
      message: item.message || "Provider returned no data.",
    }));

export function ProviderErrorNotice({ providerPayload = {} }) {
  const rows = providerErrorRows(providerPayload);
  if (!rows.length) return null;

  return (
    <ReportPanel title="API Response Status" subtitle="The upstream Astrology API did not return data for these modules.">
      <ReportTable
        columns={[
          { key: "endpoint", label: "Endpoint", render: (row) => renderCleanValue(row.endpoint) },
          { key: "message", label: "Message", render: (row) => <span className="font-semibold text-red-700">{renderCleanValue(row.message)}</span> },
        ]}
        rows={rows}
        compact
      />
    </ReportPanel>
  );
}

const flattenEntries = (value, prefix = "") => {
  if (!isObject(value)) return [];

  return Object.entries(value).flatMap(([key, item]) => {
    const nextKey = prefix ? `${prefix}_${key}` : key;
    if (isObject(item)) return flattenEntries(item, nextKey);
    if (Array.isArray(item)) return [[nextKey, item]];
    return [[nextKey, item]];
  });
};

const findValue = (source, matchers = []) => {
  const entries = flattenEntries(source);
  const found = entries.find(([key]) => {
    const normalized = key.toLowerCase();
    return matchers.some((matcher) => normalized.includes(matcher));
  });
  return found?.[1];
};

const normalizeList = (value) => {
  if (!value) return [];
  const parsed = parseMaybeJson(value);
  if (parsed !== value) return normalizeList(parsed);
  if (Array.isArray(value)) {
    return value
      .flatMap((item) => {
        if (isObject(item)) return item.remedy || item.description || item.name || item.report || JSON.stringify(item);
        return item;
      })
      .map(stripHtml)
      .filter(Boolean);
  }
  if (typeof value === "string") {
    return stripHtml(value)
      .split(/\n|(?:\.\s+)/)
      .map((item) => item.trim())
      .filter((item) => item.length > 8)
      .slice(0, 12);
  }
  return [];
};

const normalizeNarrativeList = (value) => {
  if (!value) return [];
  const parsed = parseMaybeJson(value);
  if (Array.isArray(parsed)) {
    return parsed
      .flatMap((item) => {
        if (isObject(item)) {
          return item.report || item.description || item.details || item.detail || item.text || item.name || Object.values(item);
        }
        return item;
      })
      .flatMap(normalizeNarrativeList)
      .filter(Boolean);
  }
  if (isObject(parsed)) {
    const preferred = parsed.report || parsed.description || parsed.details || parsed.detail || parsed.text || parsed.name;
    if (preferred) return normalizeNarrativeList(preferred);
    return Object.entries(parsed)
      .filter(([, item]) => item !== null && item !== undefined && item !== "")
      .map(([key, item]) => `${formatReportLabel(key)}: ${renderCleanValue(item)}`);
  }
  return paragraphsFromText(parsed);
};

const splitIntroList = (items = []) => {
  const cleaned = items.map(stripHtml).filter(Boolean);
  if (!cleaned.length) return { intro: "", items: [] };
  const [first, ...rest] = cleaned;
  if (/^following are\b/i.test(first) || /^these are\b/i.test(first)) {
    return { intro: first, items: rest };
  }
  return { intro: "", items: cleaned };
};

const getStatusText = (data, positive = "Present", negative = "Not Present") => {
  const raw =
    findValue(data, ["is_pitra", "is_pitri", "pitri_dosha_present", "pitra_dosha_present", "has_dosha", "is_dosha", "is_sadhesati", "sadhesati", "status"]) ??
    data?.status;

  if (typeof raw === "boolean") return raw ? positive : negative;
  if (typeof raw === "number") return raw > 0 ? positive : negative;
  if (typeof raw === "string") {
    const lowered = raw.toLowerCase();
    if (["true", "yes", "present", "active", "1"].some((item) => lowered.includes(item))) return positive;
    if (["false", "no", "absent", "inactive", "0"].some((item) => lowered.includes(item))) return negative;
    return raw;
  }

  return "Generated";
};

const getPitraStatusText = (data) => {
  const raw =
    data?.is_pitri_dosha_present ??
    data?.is_pitra_dosha_present ??
    data?.is_pitri_dosha ??
    data?.is_pitra_dosha ??
    findValue(data, ["is_pitri", "is_pitra", "pitri_dosha_present", "pitra_dosha_present"]);

  if (typeof raw === "boolean") return raw ? "Yes" : "No";
  if (typeof raw === "number") return raw > 0 ? "Yes" : "No";
  if (typeof raw === "string") {
    const lowered = raw.toLowerCase();
    if (["yes", "true", "present", "having", "detected", "1"].some((item) => lowered.includes(item))) return "Yes";
    if (["no", "false", "absent", "not present", "0"].some((item) => lowered.includes(item))) return "No";
    return raw;
  }

  const narrative = getNarrative(data).toLowerCase();
  if (narrative.includes("not having") || narrative.includes("not present")) return "No";
  if (narrative.includes("having pitra") || narrative.includes("having pitri") || narrative.includes("pitra dosha")) return "Yes";
  return "Not clearly indicated";
};

const getNarrative = (data) =>
  stripHtml(
    data?.bot_response ||
      data?.report ||
      data?.description ||
      data?.summary ||
      findValue(data, ["bot_response", "report", "description", "summary", "prediction"])
  );

const compactRows = (data, omitKeys = []) =>
  flattenEntries(data)
    .filter(([, value]) => !Array.isArray(value) && !isObject(value) && value !== null && value !== undefined && value !== "")
    .filter(([key]) => !omitKeys.some((omit) => key.toLowerCase().includes(omit)))
    .slice(0, 12)
    .map(([key, value]) => [formatReportLabel(key), stripHtml(displayCell(value))]);

const objectRows = (value, omitKeys = []) => {
  const parsed = parseMaybeJson(value);
  if (!isObject(parsed)) return [];
  return Object.entries(parsed)
    .filter(([, item]) => item !== null && item !== undefined && item !== "")
    .filter(([key]) => !omitKeys.some((omit) => key.toLowerCase().includes(omit)))
    .map(([key, item]) => [formatReportLabel(key), item]);
};

const findFirstDataArray = (value) => {
  const parsed = parseMaybeJson(value);
  if (Array.isArray(parsed)) return parsed;
  if (!isObject(parsed)) return [];
  const directArray = Object.values(parsed).find((item) => Array.isArray(item));
  return directArray || [];
};

const buildRowsFromArray = (value) =>
  findFirstDataArray(value)
    .filter((item) => isObject(item))
    .map((item, index) => ({ id: index + 1, ...item }));

const buildColumnsFromRows = (rows, preferredKeys = []) => {
  const allKeys = [...new Set(rows.flatMap((row) => Object.keys(row).filter((key) => key !== "id")))];
  const ordered = [
    ...preferredKeys.filter((key) => allKeys.includes(key)),
    ...allKeys.filter((key) => !preferredKeys.includes(key)).slice(0, 6),
  ];
  return ordered.map((key) => ({ key, label: formatReportLabel(key), render: (row) => renderCleanValue(row[key]) }));
};

const pickObject = (source, matchers = []) => {
  if (!isObject(source)) return null;
  const found = Object.entries(source).find(([key, value]) => {
    const normalized = key.toLowerCase();
    return isObject(value) && matchers.some((matcher) => normalized.includes(matcher));
  });
  return found?.[1] || null;
};

const cleanDashaRows = (value, extraOmitKeys = []) =>
  objectRows(value, ["dasha_id", "id", "start_ms", "end_ms", ...extraOmitKeys]).map(([label, item]) => {
    if (/duration/i.test(label) && item !== null && item !== undefined && item !== "" && !/year/i.test(String(item))) {
      return [label, `${item} ${Number(item) === 1 ? "Year" : "Years"}`];
    }
    return [label, item];
  });

const humanizeRudrakshaKey = (value) => {
  if (!value) return value;
  const words = String(value).split(/_+/).filter(Boolean);
  const groups = [];
  for (let index = 0; index < words.length; index += 1) {
    if (words[index + 1] === "faced") {
      groups.push(`${words[index]} faced`);
      index += 1;
    } else {
      groups.push(words[index]);
    }
  }
  return groups
    .map((group) =>
      group
        .split(/\s+/)
        .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
        .join(" ")
    )
    .join(" + ");
};

const getAny = (source, keys = []) => {
  if (!isObject(source)) return undefined;
  const normalized = Object.entries(source).reduce((carry, [key, value]) => {
    carry[key.toLowerCase().replace(/[\s_-]/g, "")] = value;
    return carry;
  }, {});

  for (const key of keys) {
    const direct = source[key];
    if (direct !== undefined && direct !== null && direct !== "") return direct;
    const compact = String(key).toLowerCase().replace(/[\s_-]/g, "");
    if (normalized[compact] !== undefined && normalized[compact] !== null && normalized[compact] !== "") {
      return normalized[compact];
    }
  }

  return undefined;
};

const findNestedObject = (source, matchers = []) => {
  if (!isObject(source)) return null;
  const queue = [source];
  while (queue.length > 0) {
    const current = queue.shift();
    const found = Object.entries(current).find(([key, value]) => {
      const normalized = key.toLowerCase().replace(/[\s_-]/g, "");
      return isObject(value) && matchers.some((matcher) => normalized.includes(matcher.replace(/[\s_-]/g, "")));
    });
    if (found) return found[1];
    Object.values(current).forEach((value) => {
      if (isObject(value)) queue.push(value);
    });
  }
  return null;
};

const findNestedArray = (source, matchers = []) => {
  const parsed = parseMaybeJson(source);
  if (Array.isArray(parsed)) return parsed;
  if (!isObject(parsed)) return [];

  const direct = Object.entries(parsed).find(([key, value]) => {
    const normalized = key.toLowerCase().replace(/[\s_-]/g, "");
    return Array.isArray(value) && matchers.some((matcher) => normalized.includes(matcher.replace(/[\s_-]/g, "")));
  });
  if (direct) return direct[1];

  for (const value of Object.values(parsed)) {
    if (isObject(value)) {
      const nested = findNestedArray(value, matchers);
      if (nested.length > 0) return nested;
    }
  }

  return findFirstDataArray(parsed);
};

const getDashaName = (row) =>
  renderCleanValue(getAny(row, ["dasha_planet", "dasha_name", "dasha", "planet", "sign", "rashi", "name"]) || "-");

const getStartDate = (row) => renderCleanValue(getAny(row, ["start_date", "startDate", "start"]) || "-");
const getEndDate = (row) => renderCleanValue(getAny(row, ["end_date", "endDate", "end"]) || "-");

const normalizeDashaRows = (value) =>
  findNestedArray(value, ["dasha", "major", "maha", "period"])
    .filter((item) => isObject(item))
    .map((item, index) => ({ id: index + 1, ...item }));

const dashaTableColumns = [
  { key: "dasha", label: "Dasha Planet", render: (row) => getDashaName(row) },
  { key: "start", label: "Start Date", render: (row) => getStartDate(row) },
  { key: "end", label: "End Date", render: (row) => getEndDate(row) },
];

const DashaFlow = ({ title, items = [] }) => (
  <div className="rounded-sm border border-gray-200 bg-white p-5">
    <h4 className="text-center text-xl font-black text-[#1E3557]">{title}</h4>
    <div className="mt-4 space-y-4">
      {items
        .filter((item) => item?.name && item.name !== "-")
        .map((item, index, visibleItems) => (
          <div key={`${item.label}-${index}`} className="text-center">
            <p className="text-lg font-semibold text-gray-900">{item.label}</p>
            <p className="mt-2 text-sm leading-6 text-gray-600">
              <span className="font-semibold text-gray-800">{item.name}</span> {item.start} to {item.end}
            </p>
            {index < visibleItems.length - 1 && <div className="mx-auto mt-3 h-3 w-3 rotate-45 border-b-4 border-r-4 border-[#D4A73C]" />}
          </div>
        ))}
    </div>
  </div>
);

const currentDashaItems = (current, labels = []) => {
  const fallbackArray = Array.isArray(current) ? current : [];
  return labels.map((item, index) => {
    const source = findNestedObject(current, item.matchers) || fallbackArray[index] || {};
    return {
      label: item.label,
      name: getDashaName(source),
      start: getStartDate(source),
      end: getEndDate(source),
    };
  });
};

const normalizePujaSuggestions = (data) =>
  findNestedArray(data, ["suggestion", "puja"])
    .filter((item) => isObject(item))
    .map((item, index) => ({
      id: index + 1,
      status: getAny(item, ["status"]) || "-",
      priority: getAny(item, ["priority"]) || "-",
      title: getAny(item, ["title", "name"]) || "-",
      summary: getAny(item, ["summary", "description", "details"]) || "-",
      one_line: getAny(item, ["one_line", "oneLine", "report"]) || "-",
    }));

const guidanceRows = (value) => {
  const parsed = parseMaybeJson(value);
  if (!parsed) return [];
  if (Array.isArray(parsed)) {
    return parsed.flatMap((item, index) => {
      if (isObject(item)) {
        const title = getAny(item, ["title", "name", "day", "time", "key"]) || `Item ${index + 1}`;
        const description =
          getAny(item, ["description", "report", "value", "details", "detail"]) ||
          Object.entries(item)
            .filter(([key]) => !["title", "name", "day", "time", "key"].includes(key))
            .map(([key, child]) => `${formatReportLabel(key)}: ${renderCleanValue(child)}`)
            .join(" | ");
        return [{ id: index + 1, title, description }];
      }
      return [{ id: index + 1, title: `Item ${index + 1}`, description: item }];
    });
  }
  if (isObject(parsed)) {
    if (getAny(parsed, ["title"]) || getAny(parsed, ["description"])) {
      return [
        {
          id: 1,
          title: getAny(parsed, ["title", "name"]) || "Details",
          description: getAny(parsed, ["description", "report", "value", "details"]) || renderCleanValue(parsed),
        },
      ];
    }
    return Object.entries(parsed)
      .filter(([, item]) => item !== null && item !== undefined && item !== "")
      .map(([key, item], index) => ({ id: index + 1, title: formatReportLabel(key), description: item }));
  }
  return [{ id: 1, title: "Details", description: parsed }];
};

const normalizeAshtakRows = (value) => {
  const parsed = parseMaybeJson(value);
  const signs = ["aries", "taurus", "gemini", "cancer", "leo", "virgo", "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"];
  const candidateArray = findNestedArray(parsed, ["ashtak", "sarvashtak", "points", "table"]);

  if (candidateArray.length > 0) {
    return candidateArray
      .filter((item) => isObject(item))
      .map((item, index) => ({
        id: index + 1,
        sign: getAny(item, ["sign", "zodiac", "rashi", "planet_zodiac", "name"]) || signs[index]?.toUpperCase() || `Row ${index + 1}`,
        sun: getAny(item, ["sun"]),
        moon: getAny(item, ["moon"]),
        mars: getAny(item, ["mars"]),
        mercury: getAny(item, ["mercury"]),
        jupiter: getAny(item, ["jupiter"]),
        venus: getAny(item, ["venus"]),
        saturn: getAny(item, ["saturn"]),
        ascendant: getAny(item, ["ascendant", "lagna"]),
        total: getAny(item, ["total"]),
      }));
  }

  if (!isObject(parsed)) return [];

  const signRows = Object.entries(parsed).filter(([key, item]) => signs.includes(key.toLowerCase()) && (isObject(item) || Array.isArray(item)));
  return signRows.map(([sign, item], index) => {
    const values = Array.isArray(item) ? item : [];
    return {
      id: index + 1,
      sign: sign.toUpperCase(),
      sun: getAny(item, ["sun"]) ?? values[0],
      moon: getAny(item, ["moon"]) ?? values[1],
      mars: getAny(item, ["mars"]) ?? values[2],
      mercury: getAny(item, ["mercury"]) ?? values[3],
      jupiter: getAny(item, ["jupiter"]) ?? values[4],
      venus: getAny(item, ["venus"]) ?? values[5],
      saturn: getAny(item, ["saturn"]) ?? values[6],
      ascendant: getAny(item, ["ascendant", "lagna"]) ?? values[7],
      total: getAny(item, ["total"]) ?? values[8],
    };
  });
};

const ashtakColumns = (firstLabel = "Sign") => [
  { key: "sign", label: firstLabel, render: (row) => renderCleanValue(row.sign) },
  { key: "sun", label: "Sun", render: (row) => renderCleanValue(row.sun) },
  { key: "moon", label: "Moon", render: (row) => renderCleanValue(row.moon) },
  { key: "mars", label: "Mars", render: (row) => renderCleanValue(row.mars) },
  { key: "mercury", label: "Mercury", render: (row) => renderCleanValue(row.mercury) },
  { key: "jupiter", label: "Jupiter", render: (row) => renderCleanValue(row.jupiter) },
  { key: "venus", label: "Venus", render: (row) => renderCleanValue(row.venus) },
  { key: "saturn", label: "Saturn", render: (row) => renderCleanValue(row.saturn) },
  { key: "ascendant", label: "Ascendant", render: (row) => renderCleanValue(row.ascendant) },
  { key: "total", label: "Total", render: (row) => renderCleanValue(row.total) },
];

export function PitraDoshaReport({ result }) {
  const providerPayload = result?.data?.provider_payload || {};
  const data = getSuccessData(providerPayload, "pitra_dosha_report") || result?.data;
  const status = getPitraStatusText(data);
  const definition =
    data?.what_is_pitri_dosha ||
    data?.what_is_pitra_dosha ||
    findValue(data, ["what_is_pitri", "what_is_pitra", "what_is"]) ||
    "Pitra Dosha is a karmic debt connected with ancestors and reflected through planetary combinations in the horoscope.";
  const conclusion = stripHtml(data?.conclusion || getNarrative(data));
  const effectList = normalizeList(data?.effects || data?.effect || findValue(data, ["effects", "effect"]));
  const { intro: effectsIntro, items: effects } = splitIntroList(effectList);
  const rules = normalizeList(data?.rules_matched || data?.rules || data?.matched_rules || findValue(data, ["rules_matched", "matched_rules", "rules"]));
  const remedyList = normalizeList(data?.remedies || data?.remedy || data?.solution || data?.suggestions || findValue(data, ["remedy", "solution"]));
  const { intro: remediesIntro, items: remedies } = splitIntroList(remedyList);

  return (
    <div className="space-y-6">
      <ReportPanel title="Pitra Dosha Details">
        <div className="space-y-5">
          <AttributeTable
            rows={[
              ["What Is Pitra Dosha", definition],
              ["Is Pitra Dosha Present", <StatusBadge value={status} />],
              ...(conclusion ? [["Conclusion", conclusion]] : []),
            ]}
          />
          {rules.length > 0 && (
            <div>
              <h4 className="mb-3 text-sm font-black text-[#1E3557]">Rules Matched</h4>
              <ul className="list-disc space-y-2 pl-5 text-sm leading-7 text-gray-800">
                {rules.map((rule, index) => (
                  <li key={index}>{rule}</li>
                ))}
              </ul>
            </div>
          )}
        </div>
      </ReportPanel>

      {effects.length > 0 && (
        <ReportPanel title="Effects">
          {effectsIntro && <p className="mb-4 text-sm leading-7 text-gray-700">{effectsIntro}</p>}
          <SimpleTextTable title="Effect" items={effects} />
        </ReportPanel>
      )}

      {remedies.length > 0 && (
        <ReportPanel title="Recommended Remedies">
          {remediesIntro && <p className="mb-4 text-sm leading-7 text-gray-700">{remediesIntro}</p>}
          <SimpleTextTable title="Remedy" items={remedies} />
        </ReportPanel>
      )}
    </div>
  );
}

export function SadeSatiReport({ result }) {
  const providerPayload = result?.data?.provider_payload || {};
  const statusData = getSuccessData(providerPayload, "sadhesati_current_status") || {};
  const remediesData = getSuccessData(providerPayload, "sadhesati_remedies");
  const status = getStatusText(statusData, "You Are in Sade Sati", "Sade Sati Not Active");
  const active = /you are|active|present|yes|true/i.test(status);
  const definition =
    statusData?.what_is_sadhesati ||
    statusData?.what_is_sade_sati ||
    findValue(statusData, ["what_is_sadhesati", "what_is_sade", "what_is"]) ||
    "Sade Sati refers to the seven-and-a-half year period when Saturn moves through the moon sign, one sign before the moon, and one sign after it.";
  const statusRows = [
    ["What Is Sade Sati", definition],
    ...compactRows(statusData, ["what_is", "bot_response", "report", "remedy"]).filter(([label]) => !/status/i.test(label)),
    ["Sade Sati Status", status],
  ];
  const remedyList = normalizeList(remediesData?.remedies || remediesData?.remedy || remediesData?.report || remediesData);
  const { intro: remediesIntro, items: remedies } = splitIntroList(remedyList);

  return (
    <div className="space-y-6">
      <section className="rounded-3xl border border-slate-100 bg-white p-8 text-center shadow-sm">
        <p className={`text-3xl font-black ${active ? "text-[#c94e24]" : "text-emerald-700"}`}>{status}</p>
      </section>

      <ReportPanel title="Status">
        <AttributeTable rows={statusRows} />
      </ReportPanel>

      {remedies.length > 0 && (
        <ReportPanel title="Sade Sati Remedies">
          {remediesIntro && <p className="mb-4 text-sm leading-7 text-gray-700">{remediesIntro}</p>}
          <SimpleTextTable title="Remedy" items={remedies} />
        </ReportPanel>
      )}
    </div>
  );
}

export function KaalSarpDoshaReport({ result }) {
  const providerPayload = result?.data?.provider_payload || {};
  const data = getSuccessData(providerPayload, "kalsarpa_details") || result?.data;
  const report = data?.report || data?.bot_response || data?.description || findValue(data, ["report", "description"]);
  const reportParagraphs = normalizeNarrativeList(report);
  const detailRows = objectRows(data, ["report", "description", "bot_response"]);

  return (
    <div className="space-y-6">
      <ReportPanel title="Kalsarpa Details" subtitle="Kaal Sarp dosha presence, type and interpretation.">
        <AttributeTable rows={detailRows} />
      </ReportPanel>
      {reportParagraphs.length > 0 && (
        <ReportPanel title="Report">
          <div className="space-y-3 text-sm leading-7 text-gray-800">
            {reportParagraphs.map((paragraph, index) => (
              <p key={index}>{paragraph}</p>
            ))}
          </div>
        </ReportPanel>
      )}
    </div>
  );
}

export function GemstoneSuggestionReport({ result }) {
  const providerPayload = result?.data?.provider_payload || {};
  const data = getSuccessData(providerPayload, "basic_gem_suggestion") || result?.data;
  const life = parseMaybeJson(data?.LIFE || data?.life || data?.Life);
  const lucky = parseMaybeJson(data?.LUCKY || data?.lucky || data?.Lucky);
  const fallbackRows = objectRows(data);

  return (
    <ReportPanel title="Gemstone Suggestion" subtitle="Basic gemstone recommendations from the horoscope.">
      {isObject(life) || isObject(lucky) ? (
        <div className="grid gap-5 lg:grid-cols-2">
          {isObject(life) && (
            <div className="space-y-3">
              <h4 className="text-base font-black text-[#1E3557]">Life Gemstone</h4>
              <AttributeTable rows={objectRows(life)} />
            </div>
          )}
          {isObject(lucky) && (
            <div className="space-y-3">
              <h4 className="text-base font-black text-[#1E3557]">Lucky Gemstone</h4>
              <AttributeTable rows={objectRows(lucky)} />
            </div>
          )}
        </div>
      ) : (
        <AttributeTable rows={fallbackRows} />
      )}
    </ReportPanel>
  );
}

const resolveRudrakshaImageUrl = (value) => {
  if (!value) return "";
  const image = String(value).trim();
  if (/^https?:\/\//i.test(image)) return image;
  if (image.startsWith("/")) {
    const base = import.meta.env.VITE_ASTROLOGY_IMAGE_BASE_URL || "https://astrologyapi.com";
    return `${base}${image}`;
  }
  return image;
};

export function RudrakshaSuggestionReport({ result }) {
  const providerPayload = result?.data?.provider_payload || {};
  const data = getSuccessData(providerPayload, "rudraksha_suggestion") || result?.data;
  const imageUrl = resolveRudrakshaImageUrl(data?.img_url || data?.image_url || data?.image || data?.imgUrl);
  const rows = objectRows(data, ["img_url", "image_url", "image", "imgurl"]).map(([label, value]) =>
    label === "Rudraksha Key" ? [label, humanizeRudrakshaKey(value)] : [label, value]
  );

  return (
    <ReportPanel title="Rudraksha Suggestion" subtitle="Rudraksha recommendation based on birth details.">
      <div className="space-y-5">
        {imageUrl && (
          <div className="flex justify-center rounded-sm border border-gray-200 bg-white p-5">
            <img
              src={imageUrl}
              alt={stripHtml(data?.name || "Rudraksha suggestion")}
              className="max-h-52 max-w-full object-contain"
              loading="lazy"
              onError={(event) => {
                event.currentTarget.onerror = null;
                event.currentTarget.src = rudrakshaFallbackImage;
              }}
            />
          </div>
        )}
        <AttributeTable rows={rows} />
      </div>
    </ReportPanel>
  );
}

export function YoginiDashaReport({ result }) {
  const providerPayload = result?.data?.provider_payload || {};
  const current = getSuccessData(providerPayload, "current_yogini_dasha");
  const major = getSuccessData(providerPayload, "major_yogini_dasha");
  const currentMajor = pickObject(current, ["major"]) || current?.major_dasha || current?.majorDasha;
  const currentSub = pickObject(current, ["sub_dasha", "antar", "sub"]) || current?.sub_dasha || current?.subDasha;
  const currentSubSub = pickObject(current, ["sub_sub", "pratyantar"]) || current?.sub_sub_dasha || current?.subSubDasha;
  const majorRows = buildRowsFromArray(major);
  const majorColumns = buildColumnsFromRows(majorRows, ["dasha_name", "name", "start_date", "start", "end_date", "end", "duration"]).filter(
    (column) => !["dasha_id", "id", "start_ms", "end_ms"].includes(column.key)
  );

  return (
    <div className="space-y-6">
      <ReportPanel title="Current Yogini Dasha" subtitle="Current running Yogini period for the native.">
        <div className="space-y-5">
          {currentMajor && (
            <div className="space-y-3">
              <h4 className="text-base font-black text-[#1E3557]">Major Dasha</h4>
              <AttributeTable rows={cleanDashaRows(currentMajor)} />
            </div>
          )}
          {currentSub && (
            <div className="space-y-3">
              <h4 className="text-base font-black text-[#1E3557]">Sub Dasha</h4>
              <AttributeTable rows={cleanDashaRows(currentSub)} />
            </div>
          )}
          {currentSubSub && (
            <div className="space-y-3">
              <h4 className="text-base font-black text-[#1E3557]">Sub Sub Dasha</h4>
              <AttributeTable rows={cleanDashaRows(currentSubSub)} />
            </div>
          )}
          {!currentMajor && !currentSub && !currentSubSub && <AttributeTable rows={cleanDashaRows(current)} />}
        </div>
      </ReportPanel>

      <ReportPanel title="Major Yogini Dasha">
        <ReportTable
          columns={majorColumns.map((column) =>
            column.key === "duration"
              ? {
                  ...column,
                  render: (row) => {
                    const value = row.duration;
                    return value !== null && value !== undefined && value !== "" && !/year/i.test(String(value))
                      ? `${value} ${Number(value) === 1 ? "Year" : "Years"}`
                      : renderCleanValue(value);
                  },
                }
              : column
          )}
          rows={majorRows}
          compact
        />
      </ReportPanel>
    </div>
  );
}

export function PujaSuggestionReport({ result }) {
  const providerPayload = result?.data?.provider_payload || {};
  const data = getSuccessData(providerPayload, "puja_suggestion") || result?.data;
  const summary =
    getAny(data, ["summary", "description", "report"]) ||
    findValue(data, ["summary", "description", "report"]) ||
    "Puja suggestions generated from horoscope and planetary combinations.";
  const rows = normalizePujaSuggestions(data);

  return (
    <ReportPanel title="Puja Suggestion" subtitle="Recommended puja and spiritual remedies.">
      <div className="space-y-5">
        <div className="rounded-sm border border-[#e7c76c] bg-[#fff8df] px-5 py-4 text-sm font-semibold leading-7 text-[#5f4208]">
          {renderCleanValue(summary)}
        </div>
        <div>
          <h4 className="mb-3 text-base font-black text-[#1E3557]">Suggestions</h4>
          <ReportTable
            columns={[
              { key: "status", label: "Status", render: (row) => renderCleanValue(row.status) },
              { key: "priority", label: "Priority", render: (row) => renderCleanValue(row.priority) },
              { key: "title", label: "Title", render: (row) => renderCleanValue(row.title) },
              { key: "summary", label: "Summary", render: (row) => <div className="min-w-[260px] leading-7">{renderCleanValue(row.summary)}</div> },
              { key: "one_line", label: "One Line", render: (row) => <div className="min-w-[240px] leading-7">{renderCleanValue(row.one_line)}</div> },
            ]}
            rows={rows}
          />
        </div>
      </div>
    </ReportPanel>
  );
}

export function VimshottariDashaReport({ result }) {
  const providerPayload = result?.data?.provider_payload || {};
  const current = getSuccessData(providerPayload, "current_vdasha_all") || getSuccessData(providerPayload, "current_vdasha") || {};
  const major = getSuccessData(providerPayload, "major_vdasha") || {};
  const majorRows = normalizeDashaRows(major);
  const flowItems = currentDashaItems(current, [
    { label: "Major Dasha", matchers: ["major", "maha"] },
    { label: "Antar Dasha", matchers: ["antar", "sub"] },
    { label: "Prtyantar Dasha", matchers: ["pratyantar", "prtyantar", "subsub"] },
    { label: "Sookshm Dasha", matchers: ["sookshm", "sookshma"] },
    { label: "Pran Dasha", matchers: ["pran"] },
  ]);

  return (
    <div className="space-y-6">
      <section className="rounded-sm border border-gray-200 bg-white p-5 shadow-sm">
        <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(320px,0.9fr)]">
          <div>
            <h3 className="text-3xl font-black text-[#1E3557]">Vimshottari Dasha</h3>
            <p className="mt-5 text-sm leading-8 text-gray-700">
              Vimshottari Dasha is a Nakshatra-based planetary period system used to study the timing of important life events. The current
              hierarchy shows the running major, antar, pratyantar, sookshm and pran periods returned by the Astrology API.
            </p>
          </div>
          <DashaFlow title="Current Vimshottari Dasha" items={flowItems} />
        </div>
      </section>

      <ReportPanel title="Vimshottari Maha Dasha">
        <ReportTable columns={dashaTableColumns} rows={majorRows} compact />
      </ReportPanel>
    </div>
  );
}

export function CharDashaReport({ result }) {
  const providerPayload = result?.data?.provider_payload || {};
  const current = getSuccessData(providerPayload, "current_chardasha") || {};
  const major = getSuccessData(providerPayload, "major_chardasha") || {};
  const majorRows = normalizeDashaRows(major);
  const flowItems = currentDashaItems(current, [
    { label: "Major Dasha", matchers: ["major", "maha"] },
    { label: "Antar Dasha", matchers: ["antar", "sub"] },
    { label: "Prtyantar Dasha", matchers: ["pratyantar", "prtyantar", "subsub"] },
  ]);

  return (
    <div className="space-y-6">
      <section className="rounded-sm border border-gray-200 bg-white p-5 shadow-sm">
        <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(320px,0.9fr)]">
          <div>
            <h3 className="text-3xl font-black text-[#1E3557]">Char Dasha</h3>
            <p className="mt-5 text-sm leading-8 text-gray-700">
              Char Dasha is a sign-based Jaimini dasha system. The report below focuses on the current Char Dasha sequence and the complete
              major dasha timeline returned for the native.
            </p>
          </div>
          <DashaFlow title="Current Char Dasha" items={flowItems} />
        </div>
      </section>

      <ReportPanel title="Char Maha Dasha">
        <ReportTable columns={dashaTableColumns} rows={majorRows} compact />
      </ReportPanel>
    </div>
  );
}

export function AshtakavargaReport({ result, planetLabel = "Sun" }) {
  const providerPayload = result?.data?.provider_payload || {};
  const planetKey = Object.keys(providerPayload).find((key) => key.startsWith("planet_ashtak_"));
  const planetData = planetKey ? getSuccessData(providerPayload, planetKey) : null;
  const sarvaData = getSuccessData(providerPayload, "sarvashtak");
  const planetRows = normalizeAshtakRows(planetData);
  const sarvaRows = normalizeAshtakRows(sarvaData);

  return (
    <div className="space-y-6">
      <ReportPanel title="Planet Ashtak">
        <div className="space-y-6">
          <div className="rounded-sm border border-gray-200 bg-white p-6">
            <h3 className="text-2xl font-black text-[#1E3557]">What is Ashtakavarga (Bhinnashtak Varga)?</h3>
            <p className="mt-4 text-sm leading-8 text-gray-700">
              Bhinnashtak Varga shows the bindu contribution of a selected planet across zodiac signs. Use the Planet input selector to switch
              the API call and regenerate this table for another planet.
            </p>
          </div>
          <div className="text-center">
            <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[#D4A73C]">Selected Planet</p>
            <p className="mt-2 text-2xl font-black text-[#1E3557]">{planetLabel}</p>
          </div>
          <ReportTable columns={ashtakColumns("Planet Zodiac")} rows={planetRows} compact />
        </div>
      </ReportPanel>

      <ReportPanel title="Sarvashtak">
        <div className="space-y-6">
          <div className="rounded-sm border border-gray-200 bg-white p-6">
            <h3 className="text-2xl font-black text-[#1E3557]">What is Sarvashtak?</h3>
            <p className="mt-4 text-sm leading-8 text-gray-700">
              Sarvashtakavarga is the combined bindu strength for the horoscope. It adds the individual planetary Ashtakavarga scores and
              helps compare the relative strength of zodiac signs and houses.
            </p>
          </div>
          <ReportTable columns={ashtakColumns("Sign")} rows={sarvaRows} compact />
        </div>
      </ReportPanel>
    </div>
  );
}

const numberDefinitions = [
  { key: "destiny", label: "Destiny Number", matchers: ["destiny"], colors: "bg-[#e85fa9] text-white" },
  { key: "radical", label: "Radical Number", matchers: ["radical", "radix", "psychic"], colors: "bg-[#8722d4] text-white" },
  { key: "name", label: "Name Number", matchers: ["name_number", "namenumber"], colors: "bg-[#6a22a9] text-white" },
  { key: "evil", label: "Evil Number", matchers: ["evil"], colors: "bg-[#15883d] text-white" },
];

const extractNumber = (payload, matchers) => {
  const value = findValue(payload, matchers);
  if (Array.isArray(value)) return value.map((item) => displayCell(item)).join(", ");
  if (isObject(value)) return value.number || value.value || value.total || value.name || null;
  return value;
};

const numerologyField = (payload, matchers = []) => {
  const value = findValue(payload, matchers);
  if (Array.isArray(value)) return value.map(renderCleanValue).join(", ");
  if (isObject(value)) return getAny(value, ["value", "number", "name", "description"]) || renderCleanValue(value);
  return value;
};

export function NumerologyReportLayout({ result, fullName, birthDate, fallback = null }) {
  const providerPayload = result?.data?.provider_payload || {};
  const table = getSuccessData(providerPayload, "numero_table") || {};
  const report = getSuccessData(providerPayload, "numero_report") || {};
  const guide = {
    fav_time: getSuccessData(providerPayload, "numero_fav_time"),
    place_vastu: getSuccessData(providerPayload, "numero_place_vastu"),
    fasts: getSuccessData(providerPayload, "numero_fasts_report"),
    lord: getSuccessData(providerPayload, "numero_fav_lord"),
    mantra: getSuccessData(providerPayload, "numero_fav_mantra"),
  };
  const merged = { table, report };
  const coreNumbers = numberDefinitions
    .map((item) => ({ ...item, value: extractNumber(merged, item.matchers) }))
    .filter((item) => item.value !== null && item.value !== undefined && item.value !== "");
  const personalRows = [
    ["Your Name", result.data?.full_name || fullName],
    ["Today Date", result.data?.birth_date || birthDate],
    ["Radical Number", numerologyField(merged, ["radical", "radix", "psychic"])],
    ["Name Number", numerologyField(merged, ["name_number", "namenumber"])],
    ["Destiny Number", numerologyField(merged, ["destiny"])],
    ["Radical Ruler", numerologyField(merged, ["radical_ruler", "ruler"])],
    ["Friendly Number", numerologyField(merged, ["friendly"])],
    ["Evil Numbers", numerologyField(merged, ["evil"])],
    ["Neutral Number", numerologyField(merged, ["neutral"])],
  ].filter(([, value]) => value !== null && value !== undefined && value !== "");
  const favourableRows = [
    ["Favourable Days", numerologyField(merged, ["favourable_days", "favorable_days", "fav_days", "fav_day"])],
    ["Favourable Stone", numerologyField(merged, ["favourable_stone", "favorable_stone", "fav_stone", "stone"])],
    ["Favourable Sub Stone", numerologyField(merged, ["sub_stone", "semi_stone"])],
    ["Favourable God", numerologyField(merged, ["god", "deity"])],
    ["Favourable Metal", numerologyField(merged, ["metal"])],
    ["Favourable Color", numerologyField(merged, ["color", "colour"])],
    ["Favourable Mantra", numerologyField(merged, ["mantra"])],
  ].filter(([, value]) => value !== null && value !== undefined && value !== "");
  const narrative =
    (typeof report === "string" ? report : "") ||
    getAny(report, ["report", "description", "prediction", "summary"]) ||
    findValue(report, ["report", "description", "prediction", "summary"]) ||
    "";
  const narrativeParagraphs = paragraphsFromText(renderCleanValue(narrative));

  if (!coreNumbers.length && !Object.keys(report || {}).length) {
    return (
      <div className="space-y-6">
        <ProviderErrorNotice providerPayload={providerPayload} />
        {fallback}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <ProviderErrorNotice providerPayload={providerPayload} />
      <section className="rounded-sm border border-gray-200 bg-white shadow-sm">
        <div className="rounded-t-sm bg-[#1E63D8] px-5 py-4">
          <h2 className="text-2xl font-black text-white">Detailed Numerology For You</h2>
        </div>
        <div className="space-y-8 p-5">
          <div className="grid gap-6 sm:grid-cols-2 xl:grid-cols-4">
            {coreNumbers.map((item) => (
              <div key={item.key} className="text-center">
                <div className={`mx-auto flex h-32 w-32 items-center justify-center rounded-full text-5xl font-light ${item.colors}`}>
                  {displayCell(item.value)}
                </div>
                <p className="mt-5 text-xl font-black text-[#1E3557]">{item.label}</p>
              </div>
            ))}
          </div>

          <div className="grid gap-6 lg:grid-cols-2">
            <KeyValueTable columns={1} rows={personalRows} />
            <KeyValueTable columns={1} rows={favourableRows} />
          </div>

          {narrativeParagraphs.length > 0 && (
            <div>
              <h3 className="text-2xl font-black text-[#1E3557]">What the Number Says About You</h3>
              <div className="mt-4 space-y-3 text-sm leading-8 text-gray-700">
                {narrativeParagraphs.map((paragraph, index) => (
                  <p key={index}>{paragraph}</p>
                ))}
              </div>
            </div>
          )}
        </div>
      </section>

      <ReportPanel title="Favourable Guidance">
        <div className="space-y-5">
          {Object.entries(guide)
            .filter(([, value]) => value)
            .map(([key, value]) => (
              <div key={key} className="rounded-sm border border-gray-200 bg-white p-4">
                <h4 className="mb-3 text-base font-black text-[#1E3557]">{formatReportLabel(key)}</h4>
                <ReportTable
                  columns={[
                    { key: "title", label: "Title", render: (row) => renderCleanValue(row.title) },
                    { key: "description", label: "Description", render: (row) => <div className="min-w-[280px] leading-7">{renderCleanValue(row.description)}</div> },
                  ]}
                  rows={guidanceRows(value)}
                  compact
                />
              </div>
            ))}
        </div>
      </ReportPanel>
    </div>
  );
}
