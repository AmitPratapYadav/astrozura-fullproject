import { useState } from "react";
import {
  TEST_ACCESS_ENABLED,
  TEST_ACCESS_PASSWORD,
  TEST_ACCESS_STORAGE_KEY,
  hasTestingAccess,
} from "../lib/testingAccess";

function TestingAccessGate({ children }) {
  const [password, setPassword] = useState("");
  const [granted, setGranted] = useState(hasTestingAccess);
  const [error, setError] = useState("");

  if (!TEST_ACCESS_ENABLED || granted) {
    return children;
  }

  const handleSubmit = (event) => {
    event.preventDefault();

    if (password === TEST_ACCESS_PASSWORD) {
      localStorage.setItem(TEST_ACCESS_STORAGE_KEY, password);
      setGranted(true);
      setError("");
      return;
    }

    setError("Incorrect password.");
  };

  return (
    <main className="flex min-h-screen items-center justify-center bg-[#f7f4ed] px-4">
      <section className="w-full max-w-sm rounded-lg border border-[#e1d5bf] bg-white p-6 shadow-sm">
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-semibold text-[#271b12]">Astrozura Testing</h1>
          <p className="mt-2 text-sm text-[#6d5d45]">Enter the access password to continue.</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <input
            className="w-full rounded-md border border-[#d3c4aa] px-4 py-3 text-base outline-none focus:border-[#b5832e] focus:ring-2 focus:ring-[#ead1a3]"
            type="password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            placeholder="Password"
            autoComplete="current-password"
            autoFocus
          />
          {error ? <p className="text-sm text-red-600">{error}</p> : null}
          <button
            type="submit"
            className="w-full rounded-md bg-[#b5832e] px-4 py-3 font-semibold text-white transition hover:bg-[#94691f]"
          >
            Continue
          </button>
        </form>
      </section>
    </main>
  );
}

export default TestingAccessGate;
