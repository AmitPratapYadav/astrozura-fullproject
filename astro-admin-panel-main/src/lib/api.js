const API_BASE = import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000/api";
const APP_BASE = import.meta.env.VITE_BACKEND_URL || "http://127.0.0.1:8000";

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
  const data = await response.json();

  if (!response.ok) {
    throw new Error(data?.message || "Request failed.");
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
