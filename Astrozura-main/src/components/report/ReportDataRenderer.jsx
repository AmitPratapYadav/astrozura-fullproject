import React from "react";
import { KeyValueTable, ReportPanel, ReportTable } from "./ReportTables";
import { displayCell, formatReportLabel } from "./reportUtils";
import maleAvatar from "../../assets/male_avatar.jpeg";
import femaleAvatar from "../../assets/female_avatar.jpeg";

const isPrimitive = (value) =>
  value === null || value === undefined || ["string", "number", "boolean"].includes(typeof value);

const compactText = (value) => {
  if (React.isValidElement(value)) return value;
  if (isPrimitive(value)) return displayCell(value);
  return displayCell(value);
};

const objectColumns = (items) =>
  Array.from(new Set(items.flatMap((item) => Object.keys(item || {})))).slice(0, 10);

export function ReportDataBlock({ title, data, depth = 0 }) {
  if (data === null || data === undefined || data === "") {
    return <p className="text-sm text-gray-500">No data returned.</p>;
  }

  if (typeof data === "string" && data.trim().startsWith("<svg")) {
    return (
      <div className="overflow-x-auto rounded-sm border border-gray-200 bg-white p-3">
        <div dangerouslySetInnerHTML={{ __html: data }} className="min-w-[280px]" />
      </div>
    );
  }

  if (data && typeof data === "object" && !Array.isArray(data) && typeof data.svg === "string" && data.svg.trim().startsWith("<svg")) {
    const { svg, ...rest } = data;
    return (
      <div className="space-y-4">
        <div className="overflow-x-auto rounded-sm border border-gray-200 bg-white p-3">
          <div dangerouslySetInnerHTML={{ __html: svg }} className="min-w-[280px]" />
        </div>
        {Object.keys(rest).length > 0 ? <ReportDataBlock title={title} data={rest} depth={depth + 1} /> : null}
      </div>
    );
  }

  if (isPrimitive(data)) {
    return (
      <KeyValueTable
        columns={1}
        rows={[[title || "Value", compactText(data)]]}
      />
    );
  }

  if (Array.isArray(data)) {
    if (data.length === 0) {
      return <p className="text-sm text-gray-500">No records returned.</p>;
    }

    if (data.every((item) => item && typeof item === "object" && !Array.isArray(item))) {
      const columns = objectColumns(data);
      return (
        <ReportTable
          compact
          columns={columns.map((key) => ({
            key,
            label: formatReportLabel(key),
            render: (row) => compactText(row[key]),
          }))}
          rows={data.map((item, index) => ({ id: item.id || index, ...item }))}
        />
      );
    }

    return (
      <ReportTable
        compact
        columns={[
          { key: "index", label: "S.N." },
          { key: "value", label: title || "Value" },
        ]}
        rows={data.map((item, index) => ({
          index: index + 1,
          value: compactText(item),
        }))}
      />
    );
  }

  const entries = Object.entries(data);
  if (entries.length === 0) {
    return <p className="text-sm text-gray-500">No fields returned.</p>;
  }

  const simpleEntries = entries.filter(([, value]) =>
    isPrimitive(value) || React.isValidElement(value) || (value && typeof value === "object" && ("name" in value || "full_name" in value))
  );
  const nestedEntries = entries.filter(([, value]) => !simpleEntries.some((entry) => entry[1] === value));

  return (
    <div className="space-y-4">
      {simpleEntries.length > 0 && (
        <KeyValueTable
          columns={depth > 1 ? 1 : 2}
          rows={simpleEntries.map(([key, value]) => [formatReportLabel(key), compactText(value)])}
        />
      )}
      {nestedEntries.length > 0 && (
        <div className="space-y-4">
          {nestedEntries.map(([key, value]) => {
            let label = formatReportLabel(key);
            if (title === "Match Birth Details") {
              if (label === "Male Astro Details") label = "Male Birthday Details";
              if (label === "Female Astro Details") label = "Female Birthday Details";
            }
            const isCalculator = typeof window !== "undefined" && (window.location.pathname.includes("/vedic-calculators") || window.location.pathname.includes("/lal-kitab-report") || window.location.pathname.includes("/detailed-matchmaking"));
            return (
              <section key={key} className={`overflow-hidden rounded-md border ${isCalculator ? "border-[#D7AF4B]" : "border-[#ead79d]"} bg-white shadow-sm h-full`}>
                <h3 className={`border-b ${isCalculator ? "border-[#D7AF4B] bg-[#D7AF4B] text-[#1E3557]" : "border-[#e7c76c] bg-[#fff3c7] text-[#6f4a04]"} px-4 py-3 text-sm font-bold flex items-center gap-2`}>
                  {label.toLowerCase().includes("male") && !label.toLowerCase().includes("female") && (
                    <img src={maleAvatar} className="w-6 h-6 rounded-full object-cover border border-white shadow-sm" alt="Male" />
                  )}
                  {label.toLowerCase().includes("female") && (
                    <img src={femaleAvatar} className="w-6 h-6 rounded-full object-cover border border-white shadow-sm" alt="Female" />
                  )}
                  <span>{label}</span>
                </h3>
                <div className="p-4 h-full">
                  <ReportDataBlock title={label} data={value} depth={depth + 1} />
                </div>
              </section>
            );
          })}
        </div>
      )}
    </div>
  );
}

export function ProviderSections({ sections = [], renderSectionExtra }) {
  if (!Array.isArray(sections) || sections.length === 0) return null;

  return (
    <div className="space-y-6">
      {sections.map((section, sectionIndex) => {
        const itemEntries = Object.entries(section.items || {}).filter(([key]) => formatReportLabel(key) !== "Match Making Report");
        const normalizedSectionTitle = String(section.title || "").replace(/[^a-z0-9]+/gi, "").toLowerCase();

        return (
          <ReportPanel key={section.id || sectionIndex} title={section.title} subtitle={section.summary}>
            <div className="space-y-5">
              {itemEntries.map(([key, item]) => {
              const label = formatReportLabel(key);
              const normalizedItemLabel = label.replace(/[^a-z0-9]+/gi, "").toLowerCase();
              const showItemLabel = itemEntries.length > 1 && normalizedItemLabel !== normalizedSectionTitle;

              if (label === "Match Birth Details") {
                return (
                  <div key={key} className="w-full space-y-3">
                    {showItemLabel ? <h4 className="text-sm font-black text-[#1E3557]">{label}</h4> : null}
                    {item?.status === "error" ? (
                      <KeyValueTable
                        columns={1}
                        rows={[
                          ["Status", "Unavailable"],
                          ["Message", item.message],
                        ]}
                      />
                    ) : (
                      <ReportDataBlock title={label} data={item?.data ?? item} />
                    )}
                  </div>
                );
              }

              return (
                <div key={key} className="space-y-3">
                  {showItemLabel ? <h4 className="text-sm font-black text-[#1E3557]">{label}</h4> : null}
                  {item?.status === "error" ? (
                    <KeyValueTable
                      columns={1}
                      rows={[
                        ["Status", "Unavailable"],
                        ["Message", item.message],
                      ]}
                    />
                  ) : (
                    <ReportDataBlock title={label} data={item?.data ?? item} />
                  )}
                </div>
              );
              })}
              {typeof renderSectionExtra === "function" ? renderSectionExtra(section) : null}
            </div>
          </ReportPanel>
        );
      })}
    </div>
  );
}
