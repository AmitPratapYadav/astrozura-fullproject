import { useEffect } from "react";

const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000/api").replace(/\/+$/, "");

export default function GoogleOAuthBridge() {
  useEffect(() => {
    window.location.replace(`${API_BASE_URL}/auth/google/callback${window.location.search}`);
  }, []);

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50">
      <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-[#3b82f6]" />
      <span className="ml-3 font-medium tracking-wide text-gray-600">Completing Google login...</span>
    </div>
  );
}
