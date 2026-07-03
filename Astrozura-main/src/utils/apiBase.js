const PRODUCTION_API_BASE = "https://astrozura.com/apigateway/index.php/api";
const LOCAL_HOSTNAME = ["local", "host"].join("");
const LOCAL_IPV4 = ["127", "0", "0", "1"].join(".");
const LOCAL_IPV6 = "::1";

const isLocalHost = (hostname = "") =>
  hostname === LOCAL_HOSTNAME || hostname === LOCAL_IPV4 || hostname === LOCAL_IPV6 || hostname.endsWith(".local");

const isLocalApiBase = (url = "") => {
  try {
    const parsed = new URL(url);
    return isLocalHost(parsed.hostname);
  } catch {
    return false;
  }
};

export function resolveApiBase(configuredBase = import.meta.env.VITE_API_BASE_URL) {
  const normalized = String(configuredBase || "").replace(/\/+$/, "");
  if (!normalized) return PRODUCTION_API_BASE;

  if (typeof window !== "undefined" && !isLocalHost(window.location.hostname) && isLocalApiBase(normalized)) {
    return PRODUCTION_API_BASE;
  }

  return normalized;
}

export const API_BASE_URL = resolveApiBase();
