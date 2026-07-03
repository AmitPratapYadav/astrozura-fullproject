const API_BASE = import.meta.env.VITE_API_BASE_URL || "https://astrozura.com/apigateway/index.php/api";
const APP_BASE = import.meta.env.VITE_BACKEND_URL || "https://astrozura.com";

export async function apiRequest(path, options = {}) {
  const {
    method = "GET",
    body,
    headers = {},
    requiresAuth = true,
  } = options;

  const requestHeaders = { ...headers };
  const config = { method, headers: requestHeaders };

  if (requiresAuth) {
    const token = localStorage.getItem("admin_token");
    if (token) {
      requestHeaders.Authorization = `Bearer ${token}`;
    }
  }

  if (body instanceof FormData) {
    config.body = body;
  } else if (body !== undefined) {
    requestHeaders["Content-Type"] = "application/json";
    config.body = JSON.stringify(body);
  }

  const response = await fetch(`${API_BASE}${path}`, config);
  const rawText = await response.text();
  let data = null;

  if (rawText) {
    try {
      data = JSON.parse(rawText);
    } catch {
      data = {
        message: rawText
          .replace(/<script[\s\S]*?<\/script>/gi, " ")
          .replace(/<style[\s\S]*?<\/style>/gi, " ")
          .replace(/<[^>]+>/g, " ")
          .replace(/\s+/g, " ")
          .trim()
          .slice(0, 240),
      };
    }
  }

  if (!response.ok) {
    throw new Error(data?.message || `Request failed with status ${response.status}.`);
  }

  return data;
}

export function assetUrl(path) {
  if (!path) {
    return "";
  }

  if (path.startsWith("http://") || path.startsWith("https://")) {
    return path;
  }

  return `${APP_BASE}${path.startsWith("/") ? path : `/${path}`}`;
}
