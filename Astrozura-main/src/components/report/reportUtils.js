import React from "react";

export const formatReportLabel = (value = "") =>
  String(value)
    .replace(/_/g, " ")
    .replace(/\b\w/g, (char) => char.toUpperCase());

export const displayCell = (value) => {
  if (React.isValidElement(value)) return value;
  if (value === null || value === undefined || value === "") return "-";
  if (typeof value === "boolean") return value ? "Yes" : "No";
  if (typeof value === "object") {
    if (value.name) return value.name;
    if (value.full_name) return value.full_name;
    return JSON.stringify(value);
  }
  return String(value);
};
