const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL || "https://astrozura.com/apigateway/index.php/api").replace(/\/+$/, "");

const FRONTEND_ORIGINS = {
  main: "https://astrozura.com",
  ecomm: "https://shop.astrozura.com",
};
const STALE_PREVIEW_HOST = ["astrozura", "cloud"].join(".");

const isLocalOrigin = (origin = "") => {
  try {
    const { hostname } = new URL(origin);
    return hostname === "localhost" || hostname === "127.0.0.1" || hostname === "::1" || hostname.endsWith(".local");
  } catch {
    return false;
  }
};

export function resolveFrontendOrigin(frontend = "main") {
  const productionOrigin = FRONTEND_ORIGINS[frontend] || FRONTEND_ORIGINS.main;
  const configuredOrigin = frontend === "ecomm"
    ? import.meta.env.VITE_ECOMM_FRONTEND_URL
    : import.meta.env.VITE_FRONTEND_PUBLIC_URL;
  const candidate = (configuredOrigin || (typeof window !== "undefined" ? window.location.origin : productionOrigin)).replace(/\/+$/, "");

  if (import.meta.env.PROD && (isLocalOrigin(candidate) || candidate.includes(STALE_PREVIEW_HOST))) {
    return productionOrigin;
  }

  return candidate || productionOrigin;
}

export function buildGoogleAuthUrl(frontend = "main") {
  const url = new URL(`${API_BASE_URL}/auth/google`);
  url.searchParams.set("frontend", frontend);
  url.searchParams.set("frontend_url", resolveFrontendOrigin(frontend));
  return url.toString();
}
