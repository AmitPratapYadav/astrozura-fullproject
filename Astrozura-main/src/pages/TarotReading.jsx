import React, { useState } from "react";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { getTarotReading } from "../api/prokeralaApi";

const sections = [
  { key: "love", title: "Love" },
  { key: "career", title: "Career" },
  { key: "finance", title: "Finance" },
];

export default function TarotReading() {
  const [mode, setMode] = useState("general");
  const [question, setQuestion] = useState("");
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState("");
  const [result, setResult] = useState(null);

  const showToast = (message) => {
    setToast(message);
    window.clearTimeout(window.__astrozuraTarotToast);
    window.__astrozuraTarotToast = window.setTimeout(() => setToast(""), 3200);
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    try {
      setLoading(true);
      setResult(null);

      const response = await getTarotReading({
        type: mode,
        question: question.trim() || undefined,
      });

      if (response?.status === "success") {
        setResult(response.data);
        showToast("Tarot reading generated.");
        return;
      }

      showToast(response?.message || "Unable to generate tarot reading.");
    } catch (error) {
      showToast(error?.response?.data?.message || "Unable to connect to tarot API.");
    } finally {
      setLoading(false);
    }
  };

  const reading = result?.reading || {};

  return (
    <div className="min-h-screen bg-[#F8F6F1] text-[#1E3557]">
      {toast && <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-xl bg-[#1E3557] px-6 py-3 text-sm font-medium text-white shadow-lg">{toast}</div>}
      <Navbar />

      <section className="bg-[#1E3557] px-4 py-20 text-white md:px-8">
        <div className="mx-auto max-w-6xl">
          <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[#D4A73C]">Premium Calculator</p>
          <h1 className="mt-4 max-w-3xl text-4xl font-black md:text-5xl">Tarot Reading</h1>
          <p className="mt-5 max-w-2xl text-sm leading-7 text-white/80 md:text-base">
            Draw live Tarot API readings for love, career, finance, or a yes/no question.
          </p>
        </div>
      </section>

      <main className="mx-auto grid max-w-6xl gap-8 px-4 py-12 md:px-8 lg:grid-cols-[380px_minmax(0,1fr)]">
        <aside className="rounded-3xl border border-[#EFE3D1] bg-white p-6 shadow-sm">
          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label className="mb-2 block text-sm font-semibold text-slate-600">Reading Type</label>
              <div className="grid grid-cols-2 gap-2 rounded-2xl bg-[#F8F6F1] p-1.5">
                {[
                  { value: "general", label: "General" },
                  { value: "yes-no", label: "Yes / No" },
                ].map((item) => (
                  <button
                    key={item.value}
                    type="button"
                    onClick={() => {
                      setMode(item.value);
                      setResult(null);
                    }}
                    className={`rounded-xl px-4 py-3 text-sm font-bold transition ${mode === item.value ? "bg-white text-[#1E3557] shadow-sm" : "text-slate-500"}`}
                  >
                    {item.label}
                  </button>
                ))}
              </div>
            </div>

            {mode === "yes-no" && (
              <div>
                <label className="mb-2 block text-sm font-semibold text-slate-600">Question</label>
                <textarea
                  value={question}
                  onChange={(event) => setQuestion(event.target.value)}
                  rows={4}
                  placeholder="Ask a focused question"
                  className="w-full rounded-2xl border border-slate-200 bg-[#F8F9FC] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                />
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full rounded-2xl bg-[#D4A73C] px-5 py-3 text-sm font-bold text-[#1E3557] transition hover:bg-[#e0b84f] disabled:opacity-60"
            >
              {loading ? "Drawing..." : "Draw Reading"}
            </button>
          </form>
        </aside>

        <section className="rounded-3xl border border-[#EFE3D1] bg-white p-6 shadow-sm md:p-8">
          {!result ? (
            <div className="flex min-h-[360px] items-center justify-center rounded-3xl border border-dashed border-[#EFE3D1] bg-[#FFFBF3] p-8 text-center">
              <div>
                <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#D4A73C]">Ready</p>
                <h2 className="mt-3 text-2xl font-bold">Your reading will appear here</h2>
              </div>
            </div>
          ) : result.type === "yes-no" ? (
            <div className="space-y-6">
              <div className="rounded-3xl bg-[#FFFBF3] p-6">
                <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[#D4A73C]">Answer</p>
                <h2 className="mt-3 text-4xl font-black">{reading.value || "-"}</h2>
                <p className="mt-2 text-lg font-bold">{reading.name || "Tarot Card"}</p>
              </div>
              <p className="text-sm leading-7 text-slate-600">{reading.description || "-"}</p>
            </div>
          ) : (
            <div className="grid gap-5">
              {sections.map((section) => (
                <article key={section.key} className="rounded-3xl border border-slate-100 bg-[#FFFBF3] p-6">
                  <div className="flex flex-wrap items-center justify-between gap-3">
                    <h2 className="text-xl font-bold">{section.title}</h2>
                    <span className="rounded-full bg-white px-3 py-1 text-xs font-semibold text-slate-500 shadow-sm">Card #{result.cards?.[section.key] || "-"}</span>
                  </div>
                  <p className="mt-4 whitespace-pre-line text-sm leading-7 text-slate-600">{reading[section.key] || "-"}</p>
                </article>
              ))}
            </div>
          )}
        </section>
      </main>

      <Footer />
    </div>
  );
}
