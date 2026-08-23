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

const resolveRudrakshaImageUrl = (value) => {
  const imageValue = Array.isArray(value) ? value.find(Boolean) : value;
  if (!imageValue || typeof imageValue !== "string") return rudrakshaFallbackImage;
  const trimmed = imageValue.trim();
  if (!trimmed) return rudrakshaFallbackImage;
  if (/^https?:\/\//i.test(trimmed)) return trimmed;
  if (trimmed.startsWith("//")) return `https:${trimmed}`;
  if (trimmed.startsWith("/")) return trimmed;
  return trimmed;
};

const AttributeTable = ({ rows = [], emptyText = "No data returned." }) => (
  <div className="overflow-x-auto rounded-2xl border border-[#E6D7BA] bg-white shadow-sm">
    <table className="w-full min-w-0 table-auto border-collapse text-sm">
      <tbody>
        {rows.length > 0 ? (
          rows.map(([label, value], index) => (
            <tr key={`${label}-${index}`} className={`${index % 2 === 0 ? "bg-white" : "bg-[#F8FAFC]"} transition-colors hover:bg-[#FFF7DF] active:bg-[#FCE9AE]`}>
              <th className="w-[34%] min-w-0 break-words border border-gray-200 px-3 py-2.5 text-left align-top text-xs font-bold text-[#1E3C72] sm:text-sm">
                {label}
              </th>
              <td className="min-w-0 break-words border border-gray-200 px-3 py-2.5 align-top leading-6 text-gray-800">
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

export function ProviderErrorNotice() {
  return null;
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
        if (isObject(item)) return item.remedy || item.description || item.name || item.report || renderCleanValue(item);
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
  renderCleanValue(getAny(row, ["dasha_planet", "dasha_name", "dasha", "planet", "sign_name", "sign", "rashi", "name"]) || "-");

const getStartDate = (row) => renderCleanValue(getAny(row, ["start_date", "startDate", "start"]) || "-");
const getEndDate = (row) => renderCleanValue(getAny(row, ["end_date", "endDate", "end"]) || "-");

const normalizeDashaRows = (value) =>
  findNestedArray(value, ["dasha", "major", "maha", "period"])
    .filter((item) => isObject(item))
    .map((item, index) => ({ id: index + 1, ...item }));

const zodiacNames = [
  "Aries",
  "Taurus",
  "Gemini",
  "Cancer",
  "Leo",
  "Virgo",
  "Libra",
  "Scorpio",
  "Sagittarius",
  "Capricorn",
  "Aquarius",
  "Pisces",
];

const normalizeChartSignRows = (value) => {
  const parsed = parseMaybeJson(value);
  const source = Array.isArray(parsed)
    ? parsed
    : Array.isArray(parsed?.chart)
      ? parsed.chart
      : Array.isArray(parsed?.data)
        ? parsed.data
        : findNestedArray(parsed, ["chart", "sign"]);

  return source
    .filter((item) => isObject(item))
    .map((item, index) => {
      const signNumber = Number(getAny(item, ["sign", "sign_id", "rashi_id"])) || index + 1;
      return {
        id: index + 1,
        sign: signNumber,
        signName: getAny(item, ["sign_name", "rashi", "zodiac", "name"]) || zodiacNames[(signNumber - 1 + 12) % 12] || `Sign ${signNumber}`,
        planet: getAny(item, ["planet", "planets", "graha"]) || "-",
        planetSmall: getAny(item, ["planet_small", "planet_short", "short"]) || "-",
        degree: getAny(item, ["planet_degree", "degree", "degrees"]) || "-",
      };
    });
};

const chartColumns = [
  { key: "sign", label: "Sign", render: (row) => renderCleanValue(row.sign) },
  { key: "signName", label: "Sign Name", render: (row) => renderCleanValue(row.signName) },
  { key: "planet", label: "Planet", render: (row) => renderCleanValue(row.planet) },
  { key: "planetSmall", label: "Short", render: (row) => renderCleanValue(row.planetSmall) },
  { key: "degree", label: "Degree", render: (row) => renderCleanValue(row.degree) },
];

const signNameToId = (value) => {
  const index = zodiacNames.findIndex((name) => name.toLowerCase() === String(value || "").toLowerCase());
  return index >= 0 ? index + 1 : null;
};

const planetShortName = (name = "") => {
  const map = {
    Sun: "Su",
    Moon: "Mo",
    Mars: "Ma",
    Mercury: "Me",
    Jupiter: "Ju",
    Venus: "Ve",
    Saturn: "Sa",
    Rahu: "Ra",
    Ketu: "Ke",
    Ascendant: "Asc",
  };
  return map[name] || String(name).slice(0, 2);
};

const formatDmsDegree = (value) => {
  const number = Number(value);
  if (!Number.isFinite(number)) return renderCleanValue(value);
  const normalized = ((number % 30) + 30) % 30;
  const degrees = Math.floor(normalized);
  const minutesFloat = (normalized - degrees) * 60;
  const minutes = Math.floor(minutesFloat);
  return `${degrees}° ${String(minutes).padStart(2, "0")}'`;
};

const normalizeKpCusps = (value) =>
  findNestedArray(value, ["cusp", "house"])
    .filter((item) => isObject(item))
    .map((item, index) => {
      const signId = Number(getAny(item, ["sign_id", "signId"])) || signNameToId(getAny(item, ["sign"])) || null;
      const fullDegree = getAny(item, ["cusp_full_degree", "full_degree", "degree"]);
      return {
        id: index + 1,
        houseId: Number(getAny(item, ["house_id", "houseId", "house"])) || index + 1,
        signId,
        sign: getAny(item, ["sign", "sign_name"]) || zodiacNames[(signId || 1) - 1] || "-",
        cuspFullDegree: fullDegree,
        formattedDegree: getAny(item, ["formatted_degree", "degree_text"]) || renderCleanValue(fullDegree),
        localDegree: formatDmsDegree(fullDegree),
        signLord: getAny(item, ["sign_lord"]),
        nakshatra: getAny(item, ["nakshatra"]),
        subLord: getAny(item, ["sub_lord"]),
      };
    })
    .sort((a, b) => a.houseId - b.houseId);

const birthChartPlanetsBySign = (birthChart) => {
  const rows = Array.isArray(birthChart) ? birthChart : findNestedArray(birthChart, ["chart", "birth"]);
  const planets = [];
  rows.forEach((row) => {
    const names = Array.isArray(row?.planets) ? row.planets : [];
    const shorts = Array.isArray(row?.planets_small) ? row.planets_small : [];
    const signs = Array.isArray(row?.planet_signs) ? row.planet_signs : [];
    names.forEach((name, index) => {
      planets.push({
        name,
        shortName: String(shorts[index] || planetShortName(name)).trim(),
        signId: Number(signs[index]) || null,
      });
    });
  });
  return planets;
};

const normalizeKpPlanets = (value) =>
  findNestedArray(value, ["planet"])
    .filter((item) => isObject(item))
    .map((item) => ({
      name: getAny(item, ["planet_name", "name", "planet"]) || "-",
      shortName: planetShortName(getAny(item, ["planet_name", "name", "planet"]) || ""),
      houseId: Number(getAny(item, ["house", "house_id", "houseId"])) || null,
      signId: signNameToId(getAny(item, ["sign"])) || null,
      degree: getAny(item, ["formatted_norm_degree", "norm_degree", "formatted_degree", "degree"]),
      isRetro: getAny(item, ["is_retro"]) === true,
    }));

const buildKpHouseChartRows = ({ birthChart, cusps, planets }) => {
  const cuspRows = normalizeKpCusps(cusps);
  const kpPlanetRows = normalizeKpPlanets(planets);
  const birthPlanets = birthChartPlanetsBySign(birthChart);

  return cuspRows.map((cusp) => {
    const byHouse = kpPlanetRows.filter((planet) => planet.houseId === cusp.houseId);
    const byBirthSign = birthPlanets
      .filter((planet) => planet.signId === cusp.signId)
      .map((planet) => {
        const detailed = kpPlanetRows.find((item) => String(item.name).toLowerCase() === String(planet.name).toLowerCase());
        return { ...planet, ...detailed, signId: planet.signId };
      });

    const merged = [...byHouse, ...byBirthSign].reduce((items, planet) => {
      if (!planet?.name || items.some((item) => String(item.name).toLowerCase() === String(planet.name).toLowerCase())) {
        return items;
      }
      return [...items, planet];
    }, []);

    return {
      ...cusp,
      planets: merged,
    };
  });
};

const romanHouse = (value) =>
  ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"][Number(value)] || String(value);

const kpHousePositions = {
  1: { left: "50%", top: "26%" },
  2: { left: "28%", top: "11%" },
  3: { left: "17%", top: "28%" },
  4: { left: "28%", top: "50%" },
  5: { left: "17%", top: "72%" },
  6: { left: "28%", top: "89%" },
  7: { left: "50%", top: "74%" },
  8: { left: "72%", top: "89%" },
  9: { left: "83%", top: "72%" },
  10: { left: "72%", top: "50%" },
  11: { left: "83%", top: "28%" },
  12: { left: "72%", top: "11%" },
};

const KpCuspBhavChart = ({ rows = [] }) => {
  const houses = Array.from({ length: 12 }, (_, index) => {
    const houseId = index + 1;
    return rows.find((row) => row.houseId === houseId) || { houseId, planets: [] };
  });

  return (
    <div className="space-y-4">
      <div className="mx-auto w-full max-w-lg">
        <div className="relative aspect-square border border-gray-900 bg-white">
          <svg className="absolute inset-0 h-full w-full" viewBox="0 0 100 100" aria-hidden="true">
            <line x1="0" y1="0" x2="100" y2="100" stroke="currentColor" strokeWidth="0.35" />
            <line x1="100" y1="0" x2="0" y2="100" stroke="currentColor" strokeWidth="0.35" />
            <line x1="50" y1="0" x2="100" y2="50" stroke="currentColor" strokeWidth="0.35" />
            <line x1="100" y1="50" x2="50" y2="100" stroke="currentColor" strokeWidth="0.35" />
            <line x1="50" y1="100" x2="0" y2="50" stroke="currentColor" strokeWidth="0.35" />
            <line x1="0" y1="50" x2="50" y2="0" stroke="currentColor" strokeWidth="0.35" />
            <line x1="50" y1="0" x2="50" y2="100" stroke="currentColor" strokeWidth="0.25" opacity="0.25" />
            <line x1="0" y1="50" x2="100" y2="50" stroke="currentColor" strokeWidth="0.25" opacity="0.25" />
          </svg>
          {houses.map((house) => {
            const position = kpHousePositions[house.houseId] || { left: "50%", top: "50%" };
            const planetText = house.planets?.length
              ? house.planets.map((planet) => `${planet.shortName || planetShortName(planet.name)}${planet.isRetro ? "R" : ""}${planet.degree ? ` ${formatDmsDegree(planet.degree)}` : ""}`).join("  ")
              : "-";
            return (
              <div
                key={house.houseId}
                className="absolute w-[22%] -translate-x-1/2 -translate-y-1/2 text-center text-[9px] font-semibold leading-tight text-[#001f4d] sm:text-xs"
                style={position}
              >
                <p className="font-black text-slate-900">{planetText}</p>
                <p className="mt-1 text-[9px] text-slate-700 sm:text-[11px]">
                  {romanHouse(house.houseId)} {house.signId ? `| Sign ${house.signId}` : ""}
                </p>
                <p className="text-[9px] text-slate-600 sm:text-[11px]">{house.localDegree || house.formattedDegree || "-"}</p>
              </div>
            );
          })}
        </div>
        <h4 className="mt-3 text-center text-lg font-black text-[#1E3557]">KP Cusp Bhav Chart</h4>
      </div>
      <ReportTable
        columns={[
          { key: "houseId", label: "House Id", render: (row) => renderCleanValue(row.houseId) },
          { key: "signId", label: "Sign Id", render: (row) => renderCleanValue(row.signId) },
          { key: "sign", label: "Sign", render: (row) => renderCleanValue(row.sign) },
          { key: "localDegree", label: "Cusp Degree", render: (row) => renderCleanValue(row.localDegree) },
          { key: "planets", label: "Planets", render: (row) => row.planets?.length ? row.planets.map((planet) => `${planet.name}${planet.degree ? ` (${formatDmsDegree(planet.degree)})` : ""}`).join(", ") : "-" },
        ]}
        rows={rows}
        compact
      />
    </div>
  );
};

const kpPlanetColumns = [
  { key: "planet_id", label: "Planet ID", render: (row) => renderCleanValue(row.planet_id) },
  { key: "planet_name", label: "Planet", render: (row) => renderCleanValue(row.planet_name) },
  { key: "degree", label: "Degree", render: (row) => renderCleanValue(row.degree) },
  { key: "formatted_degree", label: "Formatted Degree", render: (row) => renderCleanValue(row.formatted_degree) },
  { key: "is_retro", label: "Retrograde", render: (row) => (row.is_retro === true || row.is_retro === "true" ? "Yes" : "No") },
  { key: "norm_degree", label: "Norm Degree", render: (row) => renderCleanValue(row.norm_degree) },
  { key: "formatted_norm_degree", label: "Formatted Norm Degree", render: (row) => renderCleanValue(row.formatted_norm_degree) },
  { key: "house", label: "House", render: (row) => renderCleanValue(row.house) },
  { key: "sign", label: "Sign", render: (row) => renderCleanValue(row.sign) },
  { key: "sign_lord", label: "Sign Lord", render: (row) => renderCleanValue(row.sign_lord) },
  { key: "nakshatra", label: "Nakshatra", render: (row) => renderCleanValue(row.nakshatra) },
  { key: "nakshatra_lord", label: "Nakshatra Lord", render: (row) => renderCleanValue(row.nakshatra_lord) },
  { key: "charan", label: "Charan", render: (row) => renderCleanValue(row.charan) },
  { key: "sub_lord", label: "Sub Lord", render: (row) => renderCleanValue(row.sub_lord) },
  { key: "sub_sub_lord", label: "Sub Sub Lord", render: (row) => renderCleanValue(row.sub_sub_lord) },
];

const kpHouseCuspColumns = [
  { key: "house_id", label: "House ID", render: (row) => renderCleanValue(row.house_id) },
  { key: "cusp_full_degree", label: "Cusp Full Degree", render: (row) => renderCleanValue(row.cusp_full_degree) },
  { key: "formatted_degree", label: "Formatted Degree", render: (row) => renderCleanValue(row.formatted_degree) },
  { key: "sign_id", label: "Sign ID", render: (row) => renderCleanValue(row.sign_id) },
  { key: "sign", label: "Sign", render: (row) => renderCleanValue(row.sign) },
  { key: "sign_lord", label: "Sign Lord", render: (row) => renderCleanValue(row.sign_lord) },
  { key: "nakshatra", label: "Nakshatra", render: (row) => renderCleanValue(row.nakshatra) },
  { key: "nakshatra_lord", label: "Nakshatra Lord", render: (row) => renderCleanValue(row.nakshatra_lord) },
  { key: "sub_lord", label: "Sub Lord", render: (row) => renderCleanValue(row.sub_lord) },
  { key: "sub_sub_lord", label: "Sub Sub Lord", render: (row) => renderCleanValue(row.sub_sub_lord) },
];

const ChartLikeGrid = ({ rows = [], title = "Chart" }) => {
  const cells = Array.from({ length: 12 }, (_, index) => {
    const signNumber = index + 1;
    return rows.find((row) => Number(row.sign) === signNumber) || {
      id: signNumber,
      sign: signNumber,
      signName: zodiacNames[index],
      planet: "-",
      planetSmall: "-",
      degree: "-",
    };
  });

  return (
    <div className="space-y-4">
      <div className="grid overflow-hidden rounded-sm border border-[#D7AF4B] bg-white sm:grid-cols-3 lg:grid-cols-4">
        {cells.map((cell) => (
          <div key={`${title}-${cell.sign}`} className="min-h-[126px] border-b border-r border-[#ead79d] p-4 last:border-r-0">
            <div className="flex items-center justify-between gap-2">
              <span className="rounded-full bg-[#D7AF4B] px-2.5 py-1 text-xs font-black text-[#1E3557]">{cell.sign}</span>
              <span className="text-xs font-black uppercase tracking-wider text-slate-400">{renderCleanValue(cell.signName)}</span>
            </div>
            <p className="mt-4 text-sm font-black text-[#1E3557]">{renderCleanValue(cell.planet)}</p>
            <p className="mt-2 text-xs font-semibold text-slate-500">{renderCleanValue(cell.planetSmall)}</p>
            <p className="mt-1 text-xs text-slate-400">Degree: {renderCleanValue(cell.degree)}</p>
          </div>
        ))}
      </div>
      <ReportTable columns={chartColumns} rows={rows} compact />
    </div>
  );
};

const payloadPanel = (title, payload, omitKeys = []) => {
  const rows = buildRowsFromArray(payload);
  if (rows.length > 0) {
    return (
      <ReportPanel title={title}>
        <ReportTable columns={buildColumnsFromRows(rows)} rows={rows} compact />
      </ReportPanel>
    );
  }

  return (
    <ReportPanel title={title}>
      <AttributeTable rows={objectRows(payload, omitKeys)} />
    </ReportPanel>
  );
};

const monthChartEntries = (payload) => {
  const parsed = parseMaybeJson(payload);
  const source = Array.isArray(parsed)
    ? parsed
    : Array.isArray(parsed?.months)
      ? parsed.months
      : Array.isArray(parsed?.month_chart)
        ? parsed.month_chart
        : Array.isArray(parsed?.data)
          ? parsed.data
          : findNestedArray(parsed, ["month"]);

  return source
    .filter((item) => isObject(item))
    .map((item, index) => ({
      id: getAny(item, ["month_id", "monthId", "month", "id"]) || index + 1,
      chart: normalizeChartSignRows(getAny(item, ["chart", "month_chart"]) || item.chart || item),
    }));
};

const hasRenderablePayload = (payload) => {
  if (payload === null || payload === undefined || payload === "") return false;
  const parsed = parseMaybeJson(payload);
  if (Array.isArray(parsed)) return parsed.length > 0;
  if (isObject(parsed)) {
    return Object.values(parsed).some((value) => {
      if (value === null || value === undefined || value === "") return false;
      if (Array.isArray(value)) return value.length > 0;
      if (isObject(value)) return hasRenderablePayload(value);
      return true;
    });
  }
  return true;
};

const varshaphalPlanetColumns = [
  { key: "name", label: "Planet", render: (row) => renderCleanValue(row.name) },
  { key: "sign", label: "Sign", render: (row) => renderCleanValue(row.sign) },
  { key: "signLord", label: "Sign Lord", render: (row) => renderCleanValue(row.signLord) },
  { key: "house", label: "House", render: (row) => renderCleanValue(row.house) },
  { key: "nakshatra", label: "Nakshatra", render: (row) => renderCleanValue(row.nakshatra) },
  { key: "nakshatraLord", label: "Nakshatra Lord", render: (row) => renderCleanValue(row.nakshatraLord) },
  { key: "nakshatra_pad", label: "Nakshatra Pada", render: (row) => renderCleanValue(row.nakshatra_pad) },
  { key: "planet_awastha", label: "Planet Awastha", render: (row) => renderCleanValue(row.planet_awastha) },
  { key: "is_planet_set", label: "Planet Set", render: (row) => (row.is_planet_set === true || row.is_planet_set === "true" ? "Yes" : "No") },
  { key: "fullDegree", label: "Full Degree", render: (row) => renderCleanValue(row.fullDegree) },
  { key: "normDegree", label: "Norm Degree", render: (row) => renderCleanValue(row.normDegree) },
  { key: "speed", label: "Speed", render: (row) => renderCleanValue(row.speed) },
  { key: "isRetro", label: "Retrograde", render: (row) => (row.isRetro === true || row.isRetro === "true" ? "Yes" : "No") },
];

const hasValues = (value) => {
  const parsed = parseMaybeJson(value);
  if (!Array.isArray(parsed)) return parsed !== null && parsed !== undefined && parsed !== "";
  return parsed.some((item) => {
    if (Array.isArray(item)) return item.some((nested) => nested !== null && nested !== undefined && nested !== "");
    return item !== null && item !== undefined && item !== "";
  });
};

const formatPlanetGroups = (value, scalarArrayAsGroup = false) => {
  const parsed = parseMaybeJson(value);
  if (!Array.isArray(parsed) || parsed.length === 0) return "-";
  const groups = scalarArrayAsGroup && parsed.every((item) => !Array.isArray(item)) ? [parsed] : parsed;

  return groups
    .map((group) => {
      const planets = Array.isArray(group) ? group : [group];
      return planets
        .filter((planet) => planet !== null && planet !== undefined && planet !== "")
        .map((planet) => renderCleanValue(planet))
        .join(" + ");
    })
    .filter(Boolean)
    .join(" | ") || "-";
};

const yogaTypeItems = (value) => {
  const types = parseMaybeJson(value);
  return Array.isArray(types) ? types.filter(isObject) : [];
};

const getVarshaphalYogaPlanets = (row, key) => {
  if (hasValues(row[key])) return formatPlanetGroups(row[key]);

  const groups = yogaTypeItems(row.yog_type)
    .map((type) => type[key])
    .filter(hasValues);

  return groups.length ? groups.map((group) => formatPlanetGroups(group, true)).join(" | ") : "-";
};

const formatVarshaphalYogTypes = (value) => {
  const types = yogaTypeItems(value);
  if (types.length === 0) return "-";

  return types
    .map((type) => {
      const name = renderCleanValue(type.yog_name || type.name);
      return name !== "-" ? name : "";
    })
    .filter(Boolean)
    .join("\n") || "-";
};

const varshaphalYogaColumns = [
  { key: "yog_name", label: "Yog", render: (row) => renderCleanValue(row.yog_name) },
  { key: "is_yog_happening", label: "Happening", render: (row) => (row.is_yog_happening === true || row.is_yog_happening === "true" ? "Yes" : "No") },
  { key: "yog_type", label: "Yog Type", render: (row) => <span className="whitespace-pre-line">{formatVarshaphalYogTypes(row.yog_type)}</span> },
  { key: "planets", label: "Planets", render: (row) => <span className="whitespace-pre-line">{getVarshaphalYogaPlanets(row, "planets").replace(/\s\|\s/g, "\n")}</span> },
  { key: "planets_id", label: "Planet IDs", render: (row) => <span className="whitespace-pre-line">{getVarshaphalYogaPlanets(row, "planets_id").replace(/\s\|\s/g, "\n")}</span> },
  { key: "powerfullness_percentage", label: "Powerfulness", render: (row) => renderCleanValue(row.powerfullness_percentage) },
  { key: "yog_description", label: "Description", render: (row) => renderCleanValue(row.yog_description) },
  { key: "yog_prediction", label: "Prediction", render: (row) => renderCleanValue(row.yog_prediction) },
];

const dashaTableColumns = [
  { key: "dasha", label: "Dasha", render: (row) => getDashaName(row) },
  {
    key: "planet_id",
    label: "ID",
    render: (row) => {
      const value = getAny(row, ["planet_id", "planetId", "sign_id", "signId", "dasha_id", "dashaId", "id"]);
      return renderCleanValue(value ?? "-");
    },
  },
  { key: "start", label: "Start Date", render: (row) => getStartDate(row) },
  { key: "end", label: "End Date", render: (row) => getEndDate(row) },
  { key: "duration", label: "Duration", render: (row) => renderCleanValue(getAny(row, ["duration", "years"]) || "-") },
];

const dashaColumnsForRows = (rows = []) => {
  const hasDuration = rows.some((row) => {
    const value = getAny(row, ["duration", "years"]);
    return value !== null && value !== undefined && value !== "" && value !== "-";
  });
  return hasDuration ? dashaTableColumns : dashaTableColumns.filter((column) => column.key !== "duration");
};

const vimshottariHierarchySections = [
  { key: "major", title: "Major Dasha" },
  { key: "minor", title: "Antar Dasha" },
  { key: "sub_minor", title: "Pratyantar Dasha" },
  { key: "sub_sub_minor", title: "Sookshma Dasha" },
  { key: "sub_sub_sub_minor", title: "Pran Dasha" },
];

const CurrentVimshottariHierarchy = ({ data }) => {
  if (!isObject(data)) return null;
  const sections = vimshottariHierarchySections
    .map((section) => ({
      ...section,
      rows: normalizeDashaRows(data[section.key]),
      planet: data[section.key]?.planet,
    }))
    .filter((section) => section.rows.length > 0 || hasRenderablePayload(section.planet));

  if (!sections.length) return payloadPanel("Complete Current Dasha", data);

  return (
    <ReportPanel title="Complete Current Dasha">
      <div className="space-y-6">
        {sections.map((section) => (
          <div key={section.key} className="space-y-3">
            <div className="flex flex-wrap items-center justify-between gap-3 rounded-sm border border-[#D7AF4B] bg-[#fff8df] px-4 py-3">
              <h4 className="text-base font-black text-[#1E3557]">{section.title}</h4>
              {hasRenderablePayload(section.planet) ? (
                <span className="text-xs font-bold uppercase tracking-wider text-[#8a650d]">
                  Current: {renderCleanValue(section.planet)}
                </span>
              ) : null}
            </div>
            {section.rows.length > 0 ? (
              <ReportTable columns={dashaColumnsForRows(section.rows)} rows={section.rows} compact />
            ) : (
              <AttributeTable rows={objectRows(section.planet)} />
            )}
          </div>
        ))}
      </div>
    </ReportPanel>
  );
};

const charDashaRowsFromCurrent = (data) => {
  if (!isObject(data)) return [];
  return [
    ["major_dasha", "Major Dasha"],
    ["sub_dasha", "Sub Dasha"],
    ["sub_sub_dasha", "Sub Sub Dasha"],
  ]
    .map(([key, label]) => {
      const row = data[key];
      return isObject(row) ? { id: key, level: label, ...row } : null;
    })
    .filter(Boolean);
};

const charCurrentColumns = [
  { key: "level", label: "Level", render: (row) => renderCleanValue(row.level) },
  ...dashaColumnsForRows([
    { sign_id: 1, sign_name: "Sample", start_date: "start", end_date: "end", duration: "duration" },
  ]),
];

const CharDashaPeriodPanel = ({ title, data, periodKey }) => {
  const contextRows = [
    ["Major Dasha", data?.major_dasha],
    ["Sub Dasha", data?.sub_dasha && !Array.isArray(data.sub_dasha) ? data.sub_dasha : null],
  ].filter(([, value]) => isObject(value));
  const rows = normalizeDashaRows(data?.[periodKey] || data);
  const tableTitle =
    periodKey === "sub_sub_dasha"
      ? "Sub Sub Dasha"
      : periodKey === "sub_dasha"
        ? "Sub Dasha"
        : "Dasha Periods";

  if (!hasRenderablePayload(data)) return null;

  return (
    <ReportPanel title={title}>
      <div className="space-y-5">
        {contextRows.length ? (
          <div className="grid gap-4 md:grid-cols-2">
            {contextRows.map(([label, value]) => (
              <div key={label} className="rounded-sm border border-[#D7AF4B] bg-[#fff8df] p-4">
                <p className="text-sm font-black text-[#1E3557]">{label}</p>
                <div className="mt-3">
                  <AttributeTable rows={cleanDashaRows(value)} />
                </div>
              </div>
            ))}
          </div>
        ) : null}
        {rows.length ? (
          <div className="space-y-3">
            <div className="rounded-sm border border-[#D7AF4B] bg-[#fff8df] px-4 py-3">
              <h4 className="text-base font-black text-[#1E3557]">{tableTitle}</h4>
            </div>
            <ReportTable columns={dashaColumnsForRows(rows)} rows={rows} compact />
          </div>
        ) : (
          <AttributeTable rows={objectRows(data)} />
        )}
      </div>
    </ReportPanel>
  );
};

const YoginiSubDashaPanel = ({ title, data }) => {
  if (!hasRenderablePayload(data)) return null;
  const groups = Array.isArray(data) ? data : [data];
  const renderableGroups = groups
    .filter((group) => isObject(group))
    .map((group, index) => ({
      id: index + 1,
      major: group.major_dasha || group.majorDasha || null,
      rows: normalizeDashaRows(group.sub_dasha || group.subDasha || group),
    }))
    .filter((group) => hasRenderablePayload(group.major) || group.rows.length > 0);

  if (!renderableGroups.length) return payloadPanel(title, data);

  return (
    <ReportPanel title={title}>
      <div className="space-y-6">
        {renderableGroups.map((group) => (
          <div key={group.id} className="space-y-4 rounded-sm border border-[#D7AF4B] bg-[#fffdf2] p-4">
            {hasRenderablePayload(group.major) ? (
              <div className="space-y-3">
                <h4 className="text-base font-black text-[#1E3557]">Major Dasha</h4>
                <AttributeTable rows={cleanDashaRows(group.major)} />
              </div>
            ) : null}
            {group.rows.length ? (
              <div className="space-y-3">
                <div className="rounded-sm border border-[#D7AF4B] bg-[#fff8df] px-4 py-3">
                  <h4 className="text-base font-black text-[#1E3557]">Sub Dasha</h4>
                </div>
                <ReportTable columns={dashaColumnsForRows(group.rows)} rows={group.rows} compact />
              </div>
            ) : null}
          </div>
        ))}
      </div>
    </ReportPanel>
  );
};

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

const parseProviderDashaDate = (value) => {
  const match = String(value || "")
    .trim()
    .match(/^(\d{1,2})-(\d{1,2})-(\d{4})\s+(\d{1,2}):(\d{1,2})$/);

  if (!match) return null;

  const [, day, month, year, hour, minute] = match;
  return new Date(Number(year), Number(month) - 1, Number(day), Number(hour), Number(minute));
};

const findDashaPeriod = (node, planetName, referenceDate = new Date()) => {
  const periods = Array.isArray(node?.dasha_period) ? node.dasha_period : [];
  const normalizedName = String(planetName || "").toLowerCase();
  const namedPeriod = periods.find((period) => String(period?.planet || "").toLowerCase() === normalizedName);

  if (namedPeriod) return namedPeriod;

  return (
    periods.find((period) => {
      const start = parseProviderDashaDate(period?.start);
      const end = parseProviderDashaDate(period?.end);
      return start && end && referenceDate >= start && referenceDate <= end;
    }) || {}
  );
};

const vimshottariDashaItems = (current) => {
  if (!isObject(current)) return [];

  const majorNode = current.major || {};
  const minorNode = current.minor || {};
  const subMinorNode = current.sub_minor || {};
  const subSubMinorNode = current.sub_sub_minor || {};
  const pranNode = current.sub_sub_sub_minor || {};
  const hierarchy = pranNode.planet || subSubMinorNode.planet || subMinorNode.planet || minorNode.planet || {};
  const referenceDate = new Date();

  const definitions = [
    { label: "Major Dasha", node: majorNode, name: hierarchy.major },
    { label: "Antar Dasha", node: minorNode, name: hierarchy.minor },
    { label: "Prtyantar Dasha", node: subMinorNode, name: hierarchy.sub_minor },
    { label: "Sookshm Dasha", node: subSubMinorNode, name: hierarchy.sub_sub_minor },
    { label: "Pran Dasha", node: pranNode },
  ];

  return definitions.map(({ label, node, name }) => {
    const period = findDashaPeriod(node, name, referenceDate);
    return {
      label,
      name: renderCleanValue(name || period?.planet || "-"),
      start: getStartDate(period),
      end: getEndDate(period),
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

  const points = parsed.ashtak_points || findNestedObject(parsed, ["ashtak_points", "points"]) || parsed;
  const signRows = Object.entries(points).filter(([key, item]) => signs.includes(key.toLowerCase()) && (isObject(item) || Array.isArray(item)));
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

const ashtakVargaRows = (value) => {
  const parsed = parseMaybeJson(value);
  if (!isObject(parsed?.ashtak_varga)) return [];
  const details = parsed.ashtak_varga;
  return [
    ["Type", details.type],
    ["Planet", details.planet],
    ["Sign", details.sign],
    ["Sign ID", details.sign_id],
  ].filter(([, item]) => item !== null && item !== undefined && item !== "");
};

const ashtakVargaDetails = (value) => {
  const parsed = parseMaybeJson(value);
  return isObject(parsed?.ashtak_varga) ? parsed.ashtak_varga : null;
};

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

export function MangalDoshaReport({ result }) {
  const data = getSuccessData(result?.data?.provider_payload, "manglik") || result?.data?.manglik || result?.data || {};
  const report = data?.manglik_report || data?.report || data?.msg || data?.description;
  const status =
    data?.is_present !== undefined
      ? data.is_present ? "Yes" : "No"
      : data?.manglik_status || data?.status || "Not clearly indicated";
  const statusRows = [
    ["Is Mangal Dosha Present", <StatusBadge value={status} />],
    ["Mangal Dosha Status", data?.manglik_status || data?.status || "-"],
    ["Percentage Present", data?.percentage_manglik_present ?? data?.percentage ?? "-"],
    ["After Cancellation", data?.percentage_manglik_after_cancellation ?? data?.percentage_after_cancellation ?? "-"],
    ["Is Cancelled", data?.is_mars_manglik_cancelled ?? data?.is_cancelled ?? "-"],
  ];
  const ruleRows = normalizeList(data?.manglik_present_rule || data?.rules || data?.based_on_aspect || data?.based_on_house);

  return (
    <div className="space-y-6">
      <ReportPanel title="Mangal Dosha Status">
        <AttributeTable rows={statusRows} />
        {report ? (
          <div className="mt-5 rounded-sm border border-amber-200 bg-amber-50 p-4">
            <TextBlock value={report} />
          </div>
        ) : null}
      </ReportPanel>

      {ruleRows.length ? (
        <ReportPanel title="Rules Matched">
          <SimpleTextTable heading="Rule" items={ruleRows} />
        </ReportPanel>
      ) : null}

    </div>
  );
}

export function GemstoneSuggestionReport({ result }) {
  const providerPayload = result?.data?.provider_payload || {};
  const data = getSuccessData(providerPayload, "basic_gem_suggestion") || result?.data;
  const life = parseMaybeJson(data?.LIFE || data?.life || data?.Life);
  const benefic = parseMaybeJson(data?.BENEFIC || data?.benefic || data?.Benefic);
  const lucky = parseMaybeJson(data?.LUCKY || data?.lucky || data?.Lucky);
  const fallbackRows = objectRows(data, ["gem_key"]);
  const additionalRows = objectRows(data, ["life", "benefic", "lucky"]);

  return (
    <ReportPanel title="Gemstone Suggestion" subtitle="Basic gemstone recommendations from the horoscope.">
      {isObject(life) || isObject(benefic) || isObject(lucky) ? (
        <div className="grid gap-5 xl:grid-cols-3">
          {isObject(life) && (
            <div className="space-y-3">
              <h4 className="text-base font-black text-[#1E3557]">Life Gemstone</h4>
              <AttributeTable rows={objectRows(life, ["gem_key"])} />
            </div>
          )}
          {isObject(benefic) && (
            <div className="space-y-3">
              <h4 className="text-base font-black text-[#1E3557]">Benefic Gemstone</h4>
              <AttributeTable rows={objectRows(benefic, ["gem_key"])} />
            </div>
          )}
          {isObject(lucky) && (
            <div className="space-y-3">
              <h4 className="text-base font-black text-[#1E3557]">Lucky Gemstone</h4>
              <AttributeTable rows={objectRows(lucky, ["gem_key"])} />
            </div>
          )}
        </div>
      ) : (
        <AttributeTable rows={fallbackRows} />
      )}
      {additionalRows.length > 0 && (
        <div className="mt-5">
          <h4 className="mb-3 text-base font-black text-[#1E3557]">Additional Gemstone Response</h4>
          <AttributeTable rows={additionalRows} />
        </div>
      )}
    </ReportPanel>
  );
}

export function RudrakshaSuggestionReport({ result }) {
  const providerPayload = result?.data?.provider_payload || {};
  const data = getSuccessData(providerPayload, "rudraksha_suggestion") || result?.data;
  const imageUrl = resolveRudrakshaImageUrl(data?.img_url || data?.image_url || data?.image || data?.imgUrl || data?.imgurl);
  const rows = objectRows(data, ["img_url", "image_url", "image", "imgUrl", "imgurl"]);

  return (
    <ReportPanel title="Rudraksha Suggestion" subtitle="Rudraksha recommendation based on birth details.">
      <div className="grid gap-5 lg:grid-cols-[220px_minmax(0,1fr)]">
        <div className="flex items-center justify-center rounded-2xl border border-[#E6D7BA] bg-[#FFFBF0] p-4 shadow-sm">
          <img
            src={imageUrl}
            alt="Recommended Rudraksha"
            className="max-h-52 w-full max-w-[180px] object-contain"
            onError={(event) => {
              event.currentTarget.onerror = null;
              event.currentTarget.src = rudrakshaFallbackImage;
            }}
          />
        </div>
        <AttributeTable rows={rows} />
      </div>
    </ReportPanel>
  );
}

export function YoginiDashaReport({ result }) {
  const providerPayload = result?.data?.provider_payload || {};
  const current = getSuccessData(providerPayload, "current_yogini_dasha");
  const major = getSuccessData(providerPayload, "major_yogini_dasha");
  const sub = getSuccessData(providerPayload, "sub_yogini_dasha");
  const subByCycle = getSuccessData(providerPayload, "sub_yogini_dasha_by_cycle");
  const currentMajor = pickObject(current, ["major"]) || current?.major_dasha || current?.majorDasha;
  const currentSub = pickObject(current, ["sub_dasha", "antar", "sub"]) || current?.sub_dasha || current?.subDasha;
  const currentSubSub = pickObject(current, ["sub_sub", "pratyantar"]) || current?.sub_sub_dasha || current?.subSubDasha;
  const majorRows = buildRowsFromArray(major);

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
        {majorRows.length ? (
          <ReportTable columns={dashaColumnsForRows(majorRows)} rows={majorRows} compact />
        ) : (
          <AttributeTable rows={objectRows(major)} />
        )}
      </ReportPanel>

      <YoginiSubDashaPanel title="Sub Yogini Dasha" data={sub} />

      <YoginiSubDashaPanel title="Sub Yogini Dasha By Dasha Cycle" data={subByCycle} />
    </div>
  );
}

export function VarshaphalReport({ result }) {
  const providerPayload = result?.data?.provider_payload || {};
  const yearChart = getSuccessData(providerPayload, "varshaphal_year_chart");
  const monthChart = getSuccessData(providerPayload, "varshaphal_month_chart");
  const varshaphalPlanets = getSuccessData(providerPayload, "varshaphal_planets");
  const varshaphalYoga = getSuccessData(providerPayload, "varshaphal_yoga");
  const yearChartRows = normalizeChartSignRows(yearChart);
  const monthEntries = monthChartEntries(monthChart);
  const varshaphalPlanetRows = buildRowsFromArray(varshaphalPlanets);
  const varshaphalYogaRows = buildRowsFromArray(varshaphalYoga);
  const detailEntries = [
    ["varshaphal_details", "Varshaphal Details"],
    ["varshaphal_muntha", "Muntha"],
    ["varshaphal_mudda_dasha", "Mudda Dasha"],
    ["varshaphal_panchavargeeya_bala", "Panchavargeeya Bala"],
    ["varshaphal_harsha_bala", "Harsha Bala"],
    ["varshaphal_saham_points", "Saham Points"],
  ]
    .map(([key, title]) => ({ key, title, data: getSuccessData(providerPayload, key) }))
    .filter((item) => hasRenderablePayload(item.data));

  return (
    <div className="space-y-6">
      <ReportPanel title="Varshaphal Year Chart" subtitle="Annual sign and planet placement for the selected reference year.">
        <ChartLikeGrid rows={yearChartRows} title="Varshaphal Year Chart" />
      </ReportPanel>

      <ReportPanel title="Varshaphal Month Chart" subtitle="Month-wise chart values organized sign by sign.">
        <div className="space-y-6">
          {monthEntries.length > 0 ? (
            monthEntries.map((entry) => (
              <section key={entry.id} className="overflow-hidden rounded-sm border border-[#D7AF4B] bg-white">
                <h4 className="bg-[#D7AF4B] px-4 py-3 text-sm font-black text-[#1E3557]">Month {entry.id}</h4>
                <div className="p-4">
                  <ChartLikeGrid rows={entry.chart} title={`Varshaphal Month ${entry.id}`} />
                </div>
              </section>
            ))
          ) : (
            <p className="text-sm text-gray-500">No month chart data returned.</p>
          )}
        </div>
      </ReportPanel>

      {varshaphalPlanets ? (
        <ReportPanel title="Varshaphal Planets">
          <ReportTable columns={varshaphalPlanetColumns} rows={varshaphalPlanetRows} compact />
        </ReportPanel>
      ) : null}

      {varshaphalYoga ? (
        <ReportPanel title="Varshaphal Yoga">
          <ReportTable columns={varshaphalYogaColumns} rows={varshaphalYogaRows} compact />
        </ReportPanel>
      ) : null}

      {detailEntries.map((entry) => (
        <React.Fragment key={entry.key}>{payloadPanel(entry.title, entry.data)}</React.Fragment>
      ))}
    </div>
  );
}

export function KrishnamurtiPaddhatiReport({ result }) {
  const providerPayload = result?.data?.provider_payload || {};
  const birthChart = getSuccessData(providerPayload, "kp_birth_chart");
  const houseCusps = getSuccessData(providerPayload, "kp_house_cusps");
  const kpPlanets = getSuccessData(providerPayload, "kp_planets");
  const chartRows = buildKpHouseChartRows({ birthChart, cusps: houseCusps, planets: kpPlanets });
  const kpPlanetRows = buildRowsFromArray(kpPlanets);
  const kpHouseCuspRows = buildRowsFromArray(houseCusps);
  const detailEntries = [
    ["kp_house_significator", "KP House Significator"],
    ["kp_planet_significator", "KP Planet Significator"],
  ]
    .map(([key, title]) => ({ key, title, data: getSuccessData(providerPayload, key) }))
    .filter((item) => item.data);

  return (
    <div className="space-y-6">
      <ReportPanel title="KP Birth Chart" subtitle="House cusp chart matched by house id, sign id, cusp degree and KP planet placements.">
        <KpCuspBhavChart rows={chartRows} />
      </ReportPanel>

      <ReportPanel title="KP Planets">
        {kpPlanetRows.length ? (
          <ReportTable columns={kpPlanetColumns} rows={kpPlanetRows} compact />
        ) : (
          <AttributeTable rows={objectRows(kpPlanets)} />
        )}
      </ReportPanel>

      <ReportPanel title="KP House Cusps">
        {kpHouseCuspRows.length ? (
          <ReportTable columns={kpHouseCuspColumns} rows={kpHouseCuspRows} compact />
        ) : (
          <AttributeTable rows={objectRows(houseCusps)} />
        )}
      </ReportPanel>

      {detailEntries.map((entry) => (
        <React.Fragment key={entry.key}>{payloadPanel(entry.title, entry.data)}</React.Fragment>
      ))}
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
        <div className="rounded-sm border border-[#D7AF4B] bg-[#D7AF4B] px-5 py-4 text-sm font-semibold leading-7 text-[#1E3557]">
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
  const currentAll = getSuccessData(providerPayload, "current_vdasha_all");
  const current = currentAll || getSuccessData(providerPayload, "current_vdasha") || {};
  const major = getSuccessData(providerPayload, "major_vdasha") || {};
  const currentDasha = getSuccessData(providerPayload, "current_vdasha");
  const currentDashaDate = getSuccessData(providerPayload, "current_vdasha_date");
  const antarDasha = getSuccessData(providerPayload, "sub_vdasha");
  const pratyantarDasha = getSuccessData(providerPayload, "sub_sub_vdasha");
  const sookshmaDasha = getSuccessData(providerPayload, "sub_sub_sub_vdasha");
  const pranDasha = getSuccessData(providerPayload, "sub_sub_sub_sub_vdasha");
  const majorRows = normalizeDashaRows(major);
  const flowItems = vimshottariDashaItems(current);
  const currentDashaPanel = currentDasha ? ["current_vdasha", "Current Vimshottari Dasha", currentDasha] : null;
  const detailPanels = [
    ["current_vdasha_date", "Current Vimshottari Dasha By Given Date", currentDashaDate],
    ["sub_vdasha", "Antar Vimshottari Dasha", antarDasha],
    ["sub_sub_vdasha", "Pratyantar Vimshottari Dasha", pratyantarDasha],
    ["sub_sub_sub_vdasha", "Sookshma Vimshottari Dasha", sookshmaDasha],
    ["sub_sub_sub_sub_vdasha", "Pran Vimshottari Dasha", pranDasha],
  ].filter(([, , data]) => data);

  return (
    <div className="space-y-6">
      <section className="rounded-sm border border-gray-200 bg-white p-5 shadow-sm">
        <div className="grid gap-8 lg:grid-cols-[minmax(0,1fr)_minmax(320px,0.9fr)]">
          <div>
            <h3 className="text-3xl font-black text-[#1E3557]">Vimshottari Dasha</h3>
            <p className="mt-5 text-sm leading-8 text-gray-700">
              Vimshottari Dasha is a Nakshatra-based planetary period system used to study the timing of important life events. The current
              hierarchy shows the running major, antar, pratyantar, sookshm and pran periods for the native.
            </p>
          </div>
          <DashaFlow title="Current Vimshottari Dasha" items={flowItems} />
        </div>
      </section>

      {currentDashaPanel ? (
        <React.Fragment key={currentDashaPanel[0]}>{payloadPanel(currentDashaPanel[1], currentDashaPanel[2])}</React.Fragment>
      ) : null}

      {currentAll ? <CurrentVimshottariHierarchy data={currentAll} /> : null}

      <ReportPanel title="Vimshottari Maha Dasha">
        <ReportTable columns={dashaColumnsForRows(majorRows)} rows={majorRows} compact />
      </ReportPanel>

      {detailPanels.map(([key, title, data]) => (
        <React.Fragment key={key}>{payloadPanel(title, data)}</React.Fragment>
      ))}
    </div>
  );
}

export function CharDashaReport({ result }) {
  const providerPayload = result?.data?.provider_payload || {};
  const current = getSuccessData(providerPayload, "current_chardasha") || {};
  const major = getSuccessData(providerPayload, "major_chardasha") || {};
  const sub = getSuccessData(providerPayload, "sub_chardasha");
  const subSub = getSuccessData(providerPayload, "sub_sub_chardasha");
  const majorRows = normalizeDashaRows(major);
  const currentRows = charDashaRowsFromCurrent(current);
  const flowItems = currentDashaItems(current, [
    { label: "Major Dasha", matchers: ["major", "maha"] },
    { label: "Antar Dasha", matchers: ["antar", "sub"] },
    { label: "Prtyantar Dasha", matchers: ["pratyantar", "prtyantar", "subsub"] },
  ]);

  return (
    <div className="space-y-6">
      <section className="rounded-sm border border-gray-200 bg-white p-5 shadow-sm">
        <div>
          <h3 className="text-3xl font-black text-[#1E3557]">Char Dasha</h3>
          <p className="mt-5 text-sm leading-8 text-gray-700">
            Char Dasha is a sign-based Jaimini dasha system. The report below focuses on the current Char Dasha sequence and the complete
            major dasha timeline returned for the native.
          </p>
        </div>
      </section>

      <ReportPanel title="Current Char Dasha">
        {currentRows.length ? (
          <ReportTable columns={charCurrentColumns} rows={currentRows} compact />
        ) : (
          <DashaFlow title="" items={flowItems} />
        )}
      </ReportPanel>

      <ReportPanel title="Major Char Dasha">
        <ReportTable columns={dashaColumnsForRows(majorRows)} rows={majorRows} compact />
      </ReportPanel>

      {sub ? <CharDashaPeriodPanel title="Sub Char Dasha" data={sub} periodKey="sub_dasha" /> : null}
      {subSub ? <CharDashaPeriodPanel title="Sub Sub Char Dasha" data={subSub} periodKey="sub_sub_dasha" /> : null}
    </div>
  );
}

export function AshtakavargaReport({ result, planetLabel = "Sun" }) {
  const providerPayload = result?.data?.provider_payload || {};
  const planetKey = Object.keys(providerPayload).find((key) => key.startsWith("planet_ashtak_"));
  const planetData = planetKey ? getSuccessData(providerPayload, planetKey) : null;
  const sarvaData = getSuccessData(providerPayload, "sarvashtak");
  const planetRows = normalizeAshtakRows(planetData);
  const planetDetailRows = ashtakVargaRows(planetData);
  const planetDetails = ashtakVargaDetails(planetData);
  const sarvaRows = normalizeAshtakRows(sarvaData);
  const sarvaDetailRows = ashtakVargaRows(sarvaData);
  const selectedPlanet = planetDetails?.planet || planetLabel;

  return (
    <div className="space-y-6">
      <ReportPanel title="Planet Ashtak">
        <div className="space-y-6">
          <div className="rounded-sm border border-gray-200 bg-white p-6">
            <h3 className="text-2xl font-black text-[#1E3557]">What is Ashtakavarga (Bhinnashtak Varga)?</h3>
            <p className="mt-4 text-sm leading-8 text-gray-700">
              Bhinnashtak Varga shows the bindu contribution of a selected planet across zodiac signs. Use the Planet input selector to switch
              the selected planet and regenerate this table for another view.
            </p>
          </div>
          <div className="text-center">
            <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[#D4A73C]">Selected Planet</p>
            <p className="mt-2 text-2xl font-black text-[#1E3557]">{selectedPlanet}</p>
          </div>
          {planetDetailRows.length > 0 ? (
            <KeyValueTable rows={planetDetailRows} columns={2} />
          ) : null}
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
          {sarvaDetailRows.length > 0 ? (
            <KeyValueTable rows={sarvaDetailRows} columns={2} />
          ) : null}
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
