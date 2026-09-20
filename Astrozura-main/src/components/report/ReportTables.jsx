import React from "react";
import { displayCell } from "./reportUtils";

export function ReportTable({ columns = [], rows = [], emptyText = "No data returned.", compact = false }) {
  const isCalculator = typeof window !== "undefined" && (window.location.pathname.includes("/vedic-calculators") || window.location.pathname.includes("/lal-kitab-report") || window.location.pathname.includes("/detailed-matchmaking") || window.location.pathname.includes("/detailed-kundali"));
  const theadBgClass = isCalculator ? "bg-[#D7AF4B]" : "bg-[#fff8df]";
  const theadTextClass = isCalculator ? "text-[#1E3C72]" : "text-[#7a5205]";
  const borderClass = isCalculator ? "border-[#D7AF4B]" : "border-[#e7c76c]";

  return (
    <div data-horizontal-scroll="true" className="overflow-x-auto rounded-2xl border border-[#E6D7BA] bg-white shadow-sm">
      <table className="min-w-full border-collapse text-left text-xs sm:text-sm">
        <thead className={`${theadBgClass} ${theadTextClass}`}>
          <tr>
            {columns.map((column) => (
              <th key={column.key || column.label} className={`border ${borderClass} px-2 py-2 font-bold sm:px-3 ${compact ? "sm:py-2" : "sm:py-3"}`}>
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
                  <td key={column.key || column.label} className={`border border-gray-200 px-2 ${compact ? "py-1.5 sm:py-2" : "py-2 sm:py-3"} align-top leading-5 text-gray-800 transition-colors sm:px-3`}>
                    {column.render ? column.render(row, rowIndex) : displayCell(row[column.key])}
                  </td>
                ))}
              </tr>
            ))
          ) : (
            <tr>
              <td className="px-3 py-4 text-center text-gray-500" colSpan={Math.max(columns.length, 1)}>
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
    <div data-horizontal-scroll="true" className="overflow-x-auto rounded-2xl border border-[#E6D7BA] bg-white shadow-sm">
      <table className="min-w-full border-collapse text-xs sm:text-sm">
        <tbody>
          {tableRows.length > 0 ? (
            tableRows.map((row, rowIndex) => (
              <tr key={rowIndex} className={`${rowIndex % 2 === 0 ? "bg-white" : "bg-[#F8FAFC]"} transition-colors hover:bg-[#FFF7DF] active:bg-[#FCE9AE]`}>
                {Array.from({ length: columns }).map((_, cellIndex) => {
                  const item = row[cellIndex];
                  return (
                    <React.Fragment key={cellIndex}>
                      <th className="w-[20%] border border-gray-200 px-2 py-2 text-left font-bold text-[#1E3C72] sm:px-3 sm:py-2.5">
                        {item ? item.key : ""}
                      </th>
                      <td className="w-[30%] border border-gray-200 px-2 py-2 leading-5 text-gray-800 sm:px-3 sm:py-2.5">
                        {item ? displayCell(item.value) : ""}
                      </td>
                    </React.Fragment>
                  );
                })}
              </tr>
            ))
          ) : (
            <tr>
              <th className="border border-gray-200 px-2 py-2 text-left font-bold text-[#1E3C72] sm:px-3 sm:py-2.5">{label}</th>
              <td className="border border-gray-200 px-2 py-2 text-gray-500 sm:px-3 sm:py-2.5">{value}</td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

export function ReportPanel({ title, subtitle, children, actions = null, hideHeader = false }) {
  const isCalculator = typeof window !== "undefined" && (window.location.pathname.includes("/vedic-calculators") || window.location.pathname.includes("/lal-kitab-report") || window.location.pathname.includes("/detailed-matchmaking") || window.location.pathname.includes("/detailed-kundali"));
  const bgClass = isCalculator ? "bg-[#D7AF4B]" : "bg-[#fff8df]";
  const borderClass = isCalculator ? "border-[#D7AF4B]" : "border-[#e7c76c]";
  const textClass = isCalculator ? "text-[#1E3C72]" : "text-[#7a5205]";
  const subtextClass = isCalculator ? "text-[#1E3C72]/80" : "text-gray-600";

  return (
    <section className="flow-root overflow-hidden rounded-2xl border border-[#E6D7BA] bg-white shadow-sm">
      {!hideHeader && (
        <div className={`flex flex-col gap-2 border-b ${borderClass} ${bgClass} px-4 py-3 sm:flex-row sm:items-center sm:justify-between`}>
          <div>
            <h3 className={`text-base font-bold ${textClass}`}>{title}</h3>
            {subtitle ? <p className={`mt-1 text-xs ${subtextClass}`}>{subtitle}</p> : null}
          </div>
          {actions}
        </div>
      )}
      <div className={hideHeader ? "p-0" : "p-3 sm:p-4"}>{children}</div>
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
