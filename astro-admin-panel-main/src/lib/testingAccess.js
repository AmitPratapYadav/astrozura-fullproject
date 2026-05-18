export const TEST_ACCESS_ENABLED = import.meta.env.VITE_TEST_ACCESS_ENABLED === "true";
export const TEST_ACCESS_PASSWORD =
  import.meta.env.VITE_TEST_ACCESS_PASSWORD || "AstroZuraTest@2026";
export const TEST_ACCESS_STORAGE_KEY = "astrozura:test-access-password";
export const TEST_ACCESS_HEADER = "X-Astrozura-Test-Password";

export function getTestingAccessPassword() {
  if (typeof window === "undefined") return "";
  return window.localStorage.getItem(TEST_ACCESS_STORAGE_KEY) || "";
}

export function hasTestingAccess() {
  return !TEST_ACCESS_ENABLED || getTestingAccessPassword() === TEST_ACCESS_PASSWORD;
}

export function installTestingAccessHeader() {
  if (!TEST_ACCESS_ENABLED || typeof window === "undefined") return;

  if (window.__astrozuraTestingFetchPatched || typeof window.fetch !== "function") return;

  const originalFetch = window.fetch.bind(window);

  window.fetch = (input, init = {}) => {
    const password = getTestingAccessPassword();
    const headers = new Headers(
      init.headers || (input instanceof Request ? input.headers : undefined)
    );

    if (password) {
      headers.set(TEST_ACCESS_HEADER, password);
    }

    return originalFetch(input, { ...init, headers });
  };

  window.__astrozuraTestingFetchPatched = true;
}
