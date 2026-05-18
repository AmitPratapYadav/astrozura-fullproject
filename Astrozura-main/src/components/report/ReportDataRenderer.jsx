import React from "react";
import { KeyValueTable, ReportPanel, ReportTable } from "./ReportTables";
import { displayCell, formatReportLabel } from "./reportUtils";

const isPrimitive = (value) =>
  value === null || value === undefined || ["string", "number", "boolean"].includes(typeof value);

const compactText = (value) => {
  if (React.isValidElement(value)) return value;
  if (isPrimitive(value)) return displayCell(value);
  return JSON.stringify(value);
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
            render: (row) =>
              isPrimitive(row[key]) || React.isValidElement(row[key])
                ? compactText(row[key])
                : JSON.stringify(row[key]),
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
      {nestedEntries.map(([key, value]) => (
        <details key={key} open={depth < 1} className="rounded-sm border border-gray-200 bg-white">
          <summary className="cursor-pointer border-b border-[#e7c76c] bg-[#fff8df] px-3 py-2 text-sm font-bold text-[#7a5205]">
            {formatReportLabel(key)}
          </summary>
          <div className="p-3">
            <ReportDataBlock title={formatReportLabel(key)} data={value} depth={depth + 1} />
          </div>
        </details>
      ))}
    </div>
  );
}

export function ProviderSections({ sections = [] }) {
  if (!Array.isArray(sections) || sections.length === 0) return null;

  return (
    <div className="space-y-6">
      {sections.map((section, sectionIndex) => (
        <ReportPanel key={section.id || sectionIndex} title={section.title} subtitle={section.summary}>
          <div className="space-y-4">
            {Object.entries(section.items || {}).map(([key, item]) => (
              <details key={key} open className="rounded-sm border border-gray-200 bg-white">
                <summary className="cursor-pointer border-b border-[#e7c76c] bg-[#fff8df] px-3 py-2 text-sm font-bold text-[#7a5205]">
                  {formatReportLabel(key)}
                  {item?.endpoint ? <span className="ml-2 text-xs font-medium text-gray-500">({item.endpoint})</span> : null}
                </summary>
                <div className="p-3">
                  {item?.status === "error" ? (
                    <KeyValueTable
                      columns={1}
                      rows={[
                        ["Status", "Unavailable"],
                        ["Message", item.message],
                      ]}
                    />
                  ) : (
                    <ReportDataBlock title={formatReportLabel(key)} data={item?.data ?? item} />
                  )}
                </div>
              </details>
            ))}
          </div>
        </ReportPanel>
      ))}
    </div>
  );
}
