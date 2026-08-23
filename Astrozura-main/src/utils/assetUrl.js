export function assetUrl(path, fallback = "") {
  if (!path) return fallback;
  if (path.startsWith("http://") || path.startsWith("https://") || path.startsWith("blob:")) {
    return path;
  }

  const apiBase = String(import.meta.env.VITE_API_BASE_URL || "").replace(/\/+$/, "");
  const derivedBackendUrl = apiBase.replace(/\/api$/, "");
  const baseUrl = import.meta.env.VITE_BACKEND_URL || derivedBackendUrl || "https://astrozura.com";
  return `${baseUrl}${path.startsWith("/") ? path : `/${path}`}`;
}
