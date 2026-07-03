const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL || "https://astrozura.com/apigateway/index.php/api").replace(/\/+$/, "");

export function buildGoogleAuthUrl(frontend = "main") {
  const url = new URL(`${API_BASE_URL}/auth/google`);
  url.searchParams.set("frontend", frontend);
  url.searchParams.set("frontend_url", window.location.origin);
  return url.toString();
}
