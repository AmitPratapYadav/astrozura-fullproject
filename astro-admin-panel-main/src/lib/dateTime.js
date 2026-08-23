const DEFAULT_TIME_ZONE = "Asia/Kolkata";

const partsToDateInput = (date, timeZone = DEFAULT_TIME_ZONE) => {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(date);

  const value = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return `${value.year}-${value.month}-${value.day}`;
};

export const toDateInputValue = (value, timeZone = DEFAULT_TIME_ZONE) => {
  if (!value) {
    return "";
  }

  const text = String(value).trim();
  const isoMatch = text.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (isoMatch) {
    return `${isoMatch[1]}-${isoMatch[2]}-${isoMatch[3]}`;
  }

  const dmyMatch = text.match(/^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$/);
  if (dmyMatch) {
    return `${dmyMatch[3]}-${dmyMatch[2].padStart(2, "0")}-${dmyMatch[1].padStart(2, "0")}`;
  }

  const date = new Date(text);
  return Number.isNaN(date.getTime()) ? "" : partsToDateInput(date, timeZone);
};

export const toTimeInputValue = (value) => {
  if (!value) {
    return "";
  }

  const text = String(value).trim();
  const twentyFourHourMatch = text.match(/(?:T|^)(\d{1,2}):(\d{2})/);
  if (twentyFourHourMatch) {
    return `${twentyFourHourMatch[1].padStart(2, "0")}:${twentyFourHourMatch[2]}`;
  }

  const amPmMatch = text.match(/^(\d{1,2}):(\d{2})\s*([ap]m)$/i);
  if (amPmMatch) {
    let hour = Number(amPmMatch[1]);
    const suffix = amPmMatch[3].toLowerCase();
    if (suffix === "pm" && hour < 12) hour += 12;
    if (suffix === "am" && hour === 12) hour = 0;
    return `${String(hour).padStart(2, "0")}:${amPmMatch[2]}`;
  }

  return "";
};

export const formatDate = (value, options = {}) => {
  const inputValue = toDateInputValue(value, options.timeZone);
  if (!inputValue) {
    return "-";
  }

  return new Date(`${inputValue}T00:00:00`).toLocaleDateString("en-IN", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    ...options,
  });
};

export const formatTime = (value) => {
  const inputValue = toTimeInputValue(value);
  if (!inputValue) {
    return "-";
  }

  const [hour, minute] = inputValue.split(":").map(Number);
  return new Date(2000, 0, 1, hour, minute).toLocaleTimeString("en-IN", {
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  });
};

export const formatDateTime = (value, timeZone = DEFAULT_TIME_ZONE) => {
  if (!value) {
    return "-";
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "-";
  }

  return date.toLocaleString("en-IN", {
    dateStyle: "medium",
    timeStyle: "short",
    timeZone,
  });
};
