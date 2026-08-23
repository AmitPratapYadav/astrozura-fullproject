import React from "react";
import { displayCell } from "./reportUtils";

export function ReportTable({ columns = [], rows = [], emptyText = "No data returned.", compact = false }) {
  const isCalculator = typeof window !== "undefined" && (window.location.pathname.includes("/vedic-calculators") || window.location.pathname.includes("/lal-kitab-report") || window.location.pathname.includes("/detailed-matchmaking") || window.location.pathname.includes("/detailed-kundali"));
  const theadBgClass = isCalculator ? "bg-[#D7AF4B]" : "bg-[#fff8df]";
  const theadTextClass = isCalculator ? "text-[#1E3C72]" : "text-[#7a5205]";
  const borderClass = isCalculator ? "border-[#D7AF4B]" : "border-[#e7c76c]";

  return (
    <div className="overflow-x-auto rounded-2xl border border-[#E6D7BA] bg-white shadow-sm">
      <table className="min-w-full border-collapse text-left text-sm">
        <thead className={`${theadBgClass} ${theadTextClass}`}>
          <tr>
            {columns.map((column) => (
              <th key={column.key || column.label} className={`border ${borderClass} px-3 py-3 font-bold`}>
                {column.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.length > 0 ? (
            rows.map((row, rowIndex) => (
              <tr key={row.id || rowIndex} className={`${rowIndex % 2 === 0 ? "bg-white" : "bg-[#F8FAFC]"} transition-colors hover:bg-[#FFF7DF] active:bg-[#FCE9AE]`}>
                {columns.map((column) => (
                  <td key={column.key || column.label} className={`border border-gray-200 px-3 ${compact ? "py-2" : "py-3"} align-top text-gray-800 transition-colors`}>
                    {column.render ? column.render(row, rowIndex) : displayCell(row[column.key])}
                  </td>
                ))}
              </tr>
            ))
          ) : (
            <tr>
              <td className="px-3 py-5 text-center text-gray-500" colSpan={Math.max(columns.length, 1)}>
                {emptyText}
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

export function KeyValueTable({ rows = [], label = "Field", value = "Value", columns = 2 }) {
  const normalizedRows = rows
    .filter(Boolean)
    .map(([key, item]) => ({ key, value: item }));

  const tableRows = [];
  for (let index = 0; index < normalizedRows.length; index += columns) {
    tableRows.push(normalizedRows.slice(index, index + columns));
  }

  return (
    <div className="overflow-x-auto rounded-2xl border border-[#E6D7BA] bg-white shadow-sm">
      <table className="min-w-full border-collapse text-sm">
        <tbody>
          {tableRows.length > 0 ? (
            tableRows.map((row, rowIndex) => (
              <tr key={rowIndex} className={`${rowIndex % 2 === 0 ? "bg-white" : "bg-[#F8FAFC]"} transition-colors hover:bg-[#FFF7DF] active:bg-[#FCE9AE]`}>
                {Array.from({ length: columns }).map((_, cellIndex) => {
                  const item = row[cellIndex];
                  return (
                    <React.Fragment key={cellIndex}>
                      <th className="w-[20%] border border-gray-200 px-3 py-3 text-left font-bold text-[#1E3C72]">
                        {item ? item.key : ""}
                      </th>
                      <td className="w-[30%] border border-gray-200 px-3 py-3 text-gray-800">
                        {item ? displayCell(item.value) : ""}
                      </td>
                    </React.Fragment>
                  );
                })}
              </tr>
            ))
          ) : (
            <tr>
              <th className="border border-gray-200 px-3 py-3 text-left font-bold text-[#1E3C72]">{label}</th>
              <td className="border border-gray-200 px-3 py-3 text-gray-500">{value}</td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

export function ReportPanel({ title, subtitle, children, actions = null }) {
  const isCalculator = typeof window !== "undefined" && (window.location.pathname.includes("/vedic-calculators") || window.location.pathname.includes("/lal-kitab-report") || window.location.pathname.includes("/detailed-matchmaking") || window.location.pathname.includes("/detailed-kundali"));
  const bgClass = isCalculator ? "bg-[#D7AF4B]" : "bg-[#fff8df]";
  const borderClass = isCalculator ? "border-[#D7AF4B]" : "border-[#e7c76c]";
  const textClass = isCalculator ? "text-[#1E3C72]" : "text-[#7a5205]";
  const subtextClass = isCalculator ? "text-[#1E3C72]/80" : "text-gray-600";

  return (
    <section className="flow-root overflow-hidden rounded-2xl border border-[#E6D7BA] bg-white shadow-sm">
      <div className={`flex flex-col gap-2 border-b ${borderClass} ${bgClass} px-4 py-3 sm:flex-row sm:items-center sm:justify-between`}>
        <div>
          <h3 className={`text-base font-bold ${textClass}`}>{title}</h3>
          {subtitle ? <p className={`mt-1 text-xs ${subtextClass}`}>{subtitle}</p> : null}
        </div>
        {actions}
      </div>
      <div className="p-4">{children}</div>
    </section>
  );
}

export function SimpleTextTable({ title = "Details", items = [] }) {
  return (
    <ReportTable
      columns={[
        { key: "index", label: "S.N." },
        { key: "description", label: title },
      ]}
      rows={items.map((description, index) => ({ index: index + 1, description }))}
    />
  );
}
