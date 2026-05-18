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
    <main className="flex min-h-screen items-center justify-center bg-slate-100 px-4">
      <section className="w-full max-w-sm rounded-lg border border-slate-200 bg-white p-6 shadow-sm">
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-semibold text-slate-900">Astrozura Testing</h1>
          <p className="mt-2 text-sm text-slate-600">Enter the access password to continue.</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <input
            className="w-full rounded-md border border-slate-300 px-4 py-3 text-base outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-100"
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
            className="w-full rounded-md bg-slate-900 px-4 py-3 font-semibold text-white transition hover:bg-slate-700"
          >
            Continue
          </button>
        </form>
      </section>
    </main>
  );
}

export default TestingAccessGate;
