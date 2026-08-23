import { formatReportLabel } from "./reportUtils";

const hiddenKeys = new Set([
  "status",
  "endpoint",
  "api",
  "url",
  "provider_payload",
  "provider_sections",
  "raw",
  "data",
  "message",
]);

const moduleKeys = [
  { key: "biorhythm", title: "Biorhythm" },
  { key: "moon_biorhythm", title: "Moon Biorhythm" },
];

const isPrimitive = (value) =>
  value === null ||
  value === undefined ||
  ["string", "number", "boolean"].includes(typeof value);

const stripHtml = (value) =>
  String(value || "")
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/p>/gi, "\n")
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+/g, " ")
    .trim();

const formatValue = (value) => {
  if (value === null || value === undefined || value === "") return "-";
  if (typeof value === "boolean") return value ? "Yes" : "No";
  if (Array.isArray(value)) return value.map(formatValue).filter(Boolean).join(", ") || "-";
  if (typeof value === "object") {
    return cleanEntries(value)
      .map(([key, item]) => `${formatReportLabel(key)}: ${formatValue(item)}`)
      .join(" | ") || "-";
  }
  return stripHtml(value) || "-";
};

const unwrap = (value) => {
  let current = value?.data !== undefined ? value.data : value;
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

const cleanEntries = (value) => {
  if (!value || typeof value !== "object" || Array.isArray(value)) return [];
  return Object.entries(value).filter(
    ([key, item]) =>
      !hiddenKeys.has(String(key).toLowerCase()) &&
      item !== null &&
      item !== undefined &&
      item !== ""
  );
};

const scalarEntries = (value) => cleanEntries(value).filter(([, item]) => isPrimitive(item));

const complexEntries = (value) =>
  cleanEntries(value).filter(([, item]) => item && typeof item === "object");

const extractPayload = ({ kundli, result }) => {
  const resultData = result?.data || result || {};
  if (moduleKeys.some((module) => resultData?.[module.key])) return resultData;

  const providerPayload =
    resultData.provider_payload ||
    result?.provider_payload ||
    kundli?.provider_payload ||
    {};

  return providerPayload;
};

const hasData = (entry) => {
  const data = unwrap(entry);
  if (!entry || entry.status === "error" || entry.status === "pending") return false;
  if (data === null || data === undefined || data === "") return false;
  if (Array.isArray(data)) return data.length > 0;
  if (typeof data === "object") return Object.keys(data).length > 0;
  return true;
};

const ValueCardGrid = ({ entries }) => {
  if (!entries.length) return null;

  return (
    <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
      {entries.map(([key, value]) => (
        <div
          key={key}
          className="rounded-2xl border border-[#E6D7BA] bg-white px-4 py-3 shadow-sm transition-colors hover:bg-[#FFF7DF] active:bg-[#FCE9AE]"
        >
          <span className="block text-[11px] font-black uppercase tracking-[0.16em] text-slate-500">
            {formatReportLabel(key)}
          </span>
          <span className="mt-1 block break-words text-sm font-black leading-6 text-[#1E3557]">
            {formatValue(value)}
          </span>
        </div>
      ))}
    </div>
  );
};

const primitiveArrayItems = (rows) =>
  rows.map((item, index) => ({
    sn: index + 1,
    value: formatValue(item),
  }));

const objectArrayItems = (rows) =>
  rows
    .filter((row) => row && typeof row === "object" && !Array.isArray(row))
    .map((row, index) => ({
      sn: index + 1,
      entries: cleanEntries(row).filter(([, value]) => isPrimitive(value) || Array.isArray(value)),
      row,
    }));

const ArrayCards = ({ rows }) => {
  const objectRows = objectArrayItems(rows);
  const primitiveRows = primitiveArrayItems(rows.filter((row) => !row || typeof row !== "object" || Array.isArray(row)));
  const cards = objectRows.length
    ? objectRows.map((item) => ({
        sn: item.sn,
        entries: item.entries.length ? item.entries : [["Value", item.row]],
      }))
    : primitiveRows.map((item) => ({
        sn: item.sn,
        entries: [["Value", item.value]],
      }));

  if (!cards.length) return null;

  return (
    <div className="grid gap-3 md:hidden">
      {cards.map((card) => (
        <div key={card.sn} className="rounded-2xl border border-[#E6D7BA] bg-white p-4 shadow-sm">
          <div className="mb-3 inline-flex rounded-full bg-[#FFF3C4] px-3 py-1 text-xs font-black text-[#8A6200]">
            S.N. {card.sn}
          </div>
          <ValueCardGrid entries={card.entries} />
        </div>
      ))}
    </div>
  );
};

const ArrayTable = ({ rows }) => {
  if (!Array.isArray(rows) || !rows.length) return null;
  const objectRows = rows.filter((row) => row && typeof row === "object" && !Array.isArray(row));
  const primitiveRows = rows.filter((row) => !row || typeof row !== "object" || Array.isArray(row));
  const headers = objectRows.length
    ? Array.from(
        objectRows.reduce((set, row) => {
          cleanEntries(row).forEach(([key, value]) => {
            if (isPrimitive(value) || Array.isArray(value)) set.add(key);
          });
          return set;
        }, new Set())
      )
    : ["value"];

  return (
    <div className="hidden md:block">
      <div className="overflow-hidden rounded-2xl border border-[#E6D7BA] bg-white shadow-sm">
        <div data-horizontal-scroll="true" className="overflow-x-auto">
          <table className="w-full min-w-[560px] border-collapse text-left text-xs">
            <thead>
              <tr className="bg-[#D7AF4B] text-[#1E3557]">
                <th className="border border-[#D7AF4B] px-3 py-3 font-black">S.N.</th>
                {headers.map((heading) => (
                  <th key={heading} className="border border-[#D7AF4B] px-3 py-3 font-black">
                    {formatReportLabel(heading)}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {objectRows.map((row, index) => (
                <tr
                  key={index}
                  className="border-b border-gray-100 transition-colors odd:bg-white even:bg-[#F8FAFC] hover:bg-[#FFF7DF] active:bg-[#FCE9AE]"
                >
                  <td className="border border-gray-200 px-3 py-3 align-top text-slate-700">{index + 1}</td>
                  {headers.map((heading) => (
                    <td key={heading} className="border border-gray-200 px-3 py-3 align-top text-slate-700">
                      {formatValue(row?.[heading])}
                    </td>
                  ))}
                </tr>
              ))}
              {primitiveRows.map((row, index) => (
                <tr
                  key={`primitive-${index}`}
                  className="border-b border-gray-100 transition-colors odd:bg-white even:bg-[#F8FAFC] hover:bg-[#FFF7DF] active:bg-[#FCE9AE]"
                >
                  <td className="border border-gray-200 px-3 py-3 align-top text-slate-700">
                    {objectRows.length + index + 1}
                  </td>
                  <td className="border border-gray-200 px-3 py-3 align-top text-slate-700">{formatValue(row)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

const ArraySection = ({ title, rows }) => {
  if (!Array.isArray(rows) || !rows.length) return null;

  return (
    <section className="space-y-3">
      <h5 className="text-sm font-black text-[#1E3557]">{formatReportLabel(title)}</h5>
      <ArrayCards rows={rows} />
      <ArrayTable rows={rows} />
    </section>
  );
};

const ObjectSection = ({ title, value, level = 0 }) => {
  const data = unwrap(value);

  if (!data || typeof data !== "object" || Array.isArray(data)) {
    return (
      <div className="rounded-2xl border border-[#E6D7BA] bg-white px-4 py-3 shadow-sm">
        <span className="text-[11px] font-black uppercase tracking-[0.16em] text-slate-500">
          {formatReportLabel(title)}
        </span>
        <span className="mt-1 block text-sm font-black text-[#1E3557]">{formatValue(data)}</span>
      </div>
    );
  }

  const scalars = scalarEntries(data);
  const children = complexEntries(data);

  return (
    <section className={`space-y-4 ${level === 0 ? "" : "rounded-2xl border border-[#E6D7BA] bg-[#FFFDF7] p-4"}`}>
      {title ? <h5 className="text-sm font-black text-[#1E3557]">{formatReportLabel(title)}</h5> : null}
      <ValueCardGrid entries={scalars} />
      {children.map(([key, item]) =>
        Array.isArray(item) ? (
          <ArraySection key={key} title={key} rows={item} />
        ) : (
          <ObjectSection key={key} title={key} value={item} level={level + 1} />
        )
      )}
    </section>
  );
};

export default function BiorhythmReport({ kundli, result }) {
  const providerPayload = extractPayload({ kundli, result });
  const visibleModules = moduleKeys
    .map((module) => ({ ...module, entry: providerPayload?.[module.key] }))
    .filter((module) => hasData(module.entry));

  if (!visibleModules.length) {
    return (
      <p className="rounded-2xl border border-gray-100 bg-slate-50 p-4 text-sm text-slate-500">
        No biorhythm data was returned for this profile.
      </p>
    );
  }

  return (
    <div className="space-y-6">
      {visibleModules.map((module) => {
        const data = unwrap(module.entry);
        const scalars = scalarEntries(data);
        const children = complexEntries(data);

        return (
          <section key={module.key} className="overflow-hidden rounded-[2rem] border border-[#E6D7BA] bg-white shadow-sm">
            <div className="bg-[#D7AF4B] px-5 py-4">
              <h4 className="text-lg font-black text-[#1E3557]">{module.title}</h4>
            </div>
            <div className="space-y-5 p-5">
              <ValueCardGrid entries={scalars} />
              {Array.isArray(data) ? (
                <ArraySection title={module.title} rows={data} />
              ) : (
                children.map(([key, item]) =>
                  Array.isArray(item) ? (
                    <ArraySection key={key} title={key} rows={item} />
                  ) : (
                    <ObjectSection key={key} title={key} value={item} />
                  )
                )
              )}
            </div>
          </section>
        );
      })}
    </div>
  );
}
