import React from "react";
import { displayCell } from "./reportUtils";

export function ReportTable({ columns = [], rows = [], emptyText = "No data returned.", compact = false }) {
  return (
    <div className="overflow-x-auto rounded-sm border border-gray-200 bg-white">
      <table className="min-w-full border-collapse text-left text-sm">
        <thead className="bg-[#fff8df] text-[#7a5205]">
          <tr>
            {columns.map((column) => (
              <th key={column.key || column.label} className="border-b border-[#e7c76c] px-3 py-3 font-bold">
                {column.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.length > 0 ? (
            rows.map((row, rowIndex) => (
              <tr key={row.id || rowIndex} className={rowIndex % 2 === 0 ? "bg-white" : "bg-gray-50"}>
                {columns.map((column) => (
                  <td key={column.key || column.label} className={`border-b border-gray-200 px-3 ${compact ? "py-2" : "py-3"} align-top text-gray-800`}>
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
    <div className="overflow-x-auto rounded-sm border border-gray-200 bg-white">
      <table className="min-w-full border-collapse text-sm">
        <tbody>
          {tableRows.length > 0 ? (
            tableRows.map((row, rowIndex) => (
              <tr key={rowIndex} className={rowIndex % 2 === 0 ? "bg-white" : "bg-gray-50"}>
                {Array.from({ length: columns }).map((_, cellIndex) => {
                  const item = row[cellIndex];
                  return (
                    <React.Fragment key={cellIndex}>
                      <th className="w-[20%] border-b border-gray-200 px-3 py-3 text-left font-bold text-gray-800">
                        {item ? item.key : ""}
                      </th>
                      <td className="w-[30%] border-b border-gray-200 px-3 py-3 text-gray-800">
                        {item ? displayCell(item.value) : ""}
                      </td>
                    </React.Fragment>
                  );
                })}
              </tr>
            ))
          ) : (
            <tr>
              <th className="border-b border-gray-200 px-3 py-3 text-left font-bold text-gray-800">{label}</th>
              <td className="border-b border-gray-200 px-3 py-3 text-gray-500">{value}</td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

export function ReportPanel({ title, subtitle, children, actions = null }) {
  return (
    <section className="rounded-sm border border-gray-200 bg-white shadow-sm">
      <div className="flex flex-col gap-2 border-b border-[#e7c76c] bg-[#fff8df] px-4 py-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h3 className="text-base font-bold text-[#7a5205]">{title}</h3>
          {subtitle ? <p className="mt-1 text-xs text-gray-600">{subtitle}</p> : null}
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
