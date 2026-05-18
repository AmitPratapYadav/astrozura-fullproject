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
    <main className="flex min-h-screen items-center justify-center bg-[#fbf7f0] px-4">
      <section className="w-full max-w-sm rounded-lg border border-[#e7d9bd] bg-white p-6 shadow-sm">
        <div className="mb-6 text-center">
          <h1 className="text-2xl font-semibold text-[#3b2614]">Astrozura Testing</h1>
          <p className="mt-2 text-sm text-[#725b3b]">Enter the access password to continue.</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <input
            className="w-full rounded-md border border-[#d7c7aa] px-4 py-3 text-base outline-none focus:border-[#c8942f] focus:ring-2 focus:ring-[#f2d799]"
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
            className="w-full rounded-md bg-[#c8942f] px-4 py-3 font-semibold text-white transition hover:bg-[#a9771f]"
          >
            Continue
          </button>
        </form>
      </section>
    </main>
  );
}

export default TestingAccessGate;
