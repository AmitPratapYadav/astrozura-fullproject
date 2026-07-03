export function assetUrl(path, fallback = "") {
  if (!path) return fallback;
  if (path.startsWith("http://") || path.startsWith("https://") || path.startsWith("blob:")) {
    return path;
  }

  const baseUrl = import.meta.env.VITE_BACKEND_URL || "https://astrozura.com";
  return `${baseUrl}${path.startsWith("/") ? path : `/${path}`}`;
}
