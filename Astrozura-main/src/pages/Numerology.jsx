import { useEffect, useMemo, useState } from "react";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import InlineInfoPopover from "../components/InlineInfoPopover";
import { ProviderSections, ReportDataBlock } from "../components/report/ReportDataRenderer";
import { ReportPanel } from "../components/report/ReportTables";
import { NumerologyReportLayout } from "../components/report/SpecializedVedicReports";
import { getNumerologyReport } from "../api/prokeralaApi";
import { useAuth } from "../context/AuthContext";

const initialForm = {
  first_name: "",
  middle_name: "",
  last_name: "",
  date_of_birth: "",
  language: "en",
};

const splitUserName = (name = "") => {
  const parts = String(name).trim().split(/\s+/).filter(Boolean);
  return {
    first_name: parts[0] || "",
    middle_name: parts.length > 2 ? parts.slice(1, -1).join(" ") : "",
    last_name: parts.length > 1 ? parts[parts.length - 1] : "",
  };
};

const fullNameFromForm = (form) =>
  [form.first_name, form.middle_name, form.last_name]
    .map((value) => String(value || "").trim())
    .filter(Boolean)
    .join(" ");

export default function Numerology() {
  const { user } = useAuth();
  const [form, setForm] = useState(initialForm);
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState("");
  const [result, setResult] = useState(null);

  const fullName = useMemo(() => fullNameFromForm(form), [form]);
  const providerSections = result?.data?.provider_sections || [];

  useEffect(() => {
    if (!user) return;
    const names = splitUserName(user.name);
    setForm((current) => ({
      ...current,
      first_name: current.first_name || user.first_name || names.first_name,
      middle_name: current.middle_name || user.middle_name || names.middle_name,
      last_name: current.last_name || user.last_name || names.last_name,
      date_of_birth: current.date_of_birth || user.date_of_birth || user.dob || "",
    }));
  }, [user]);

  useEffect(() => {
    if (!toast) return undefined;
    const timer = window.setTimeout(() => setToast(""), 3000);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const handleChange = (event) => {
    const { name, value } = event.target;
    setForm((current) => ({
      ...current,
      [name]: value,
    }));
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (!form.date_of_birth) {
      setToast("Date of birth is required.");
      return;
    }

    if (!fullName) {
      setToast("Name is required.");
      return;
    }

    try {
      setLoading(true);
      setResult(null);

      const response = await getNumerologyReport({
        first_name: form.first_name,
        middle_name: form.middle_name,
        last_name: form.last_name,
        name: fullName,
        date_of_birth: form.date_of_birth,
        la: form.language,
      });

      if (response?.status === "success") {
        setResult(response);
        setToast("Detailed numerology report generated successfully.");
        return;
      }

      setToast(response?.message || "Unable to generate numerology report.");
    } catch (error) {
      setToast(error?.response?.data?.message || "Unable to generate numerology report.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#f7f8fb] text-[#1E3557]">
      {toast && (
        <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-xl bg-[#1E3557] px-6 py-3 text-sm font-medium text-white shadow-lg">
          {toast}
        </div>
      )}

      <Navbar />

      <section className="relative overflow-hidden bg-[#1E3557] pb-28 pt-20 text-white md:pb-32">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(212,167,60,0.18),transparent_24%),linear-gradient(135deg,rgba(255,255,255,0.03),rgba(255,255,255,0))]"></div>
        <div className="relative mx-auto max-w-7xl px-4 md:px-8">
          <div className="max-w-3xl">
            <span className="inline-flex rounded-full border border-[#D4A73C]/30 bg-[#D4A73C]/15 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-[#D4A73C]">
              Detailed Numerology
            </span>
            <h1 className="mt-6 text-4xl font-black md:text-5xl">Detailed Numerology Report</h1>
            <p className="mt-5 text-sm leading-7 text-slate-200 md:text-base">
              Generate every subscribed numerology module from Astrology API in one compact report.
            </p>
          </div>
        </div>
      </section>

      <section className="relative z-10 mx-auto -mt-14 max-w-7xl px-4 pb-16 md:-mt-16 md:px-8">
        <div className="grid gap-8 xl:grid-cols-[420px_minmax(0,1fr)]">
          <aside className="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm">
            <div>
              <h2 className="text-2xl font-bold">Detailed Numerology Inputs</h2>
              <p className="mt-2 text-sm text-slate-500">
                These fields match the Astrology API numerology parameter contract: day, month, year, and name.
              </p>
            </div>

            <form onSubmit={handleSubmit} className="mt-6 space-y-5">
              <div>
                <label className="mb-2 block text-sm font-semibold text-slate-600">First Name</label>
                <input
                  type="text"
                  name="first_name"
                  value={form.first_name}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                />
              </div>
              <div>
                <label className="mb-2 block text-sm font-semibold text-slate-600">Middle Name</label>
                <input
                  type="text"
                  name="middle_name"
                  value={form.middle_name}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                />
              </div>
              <div>
                <label className="mb-2 block text-sm font-semibold text-slate-600">Last Name</label>
                <input
                  type="text"
                  name="last_name"
                  value={form.last_name}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                />
              </div>
              <div>
                <label className="mb-2 flex items-center gap-2 text-sm font-semibold text-slate-600">
                  <span>Date of Birth</span>
                  <InlineInfoPopover
                    title="Numerology date"
                    content="The subscribed numerology APIs accept date of birth as day, month, and year. Time and location are not required for these modules."
                  />
                </label>
                <input
                  type="date"
                  name="date_of_birth"
                  value={form.date_of_birth}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                />
              </div>
              <div>
                <label className="mb-2 block text-sm font-semibold text-slate-600">Language</label>
                <select
                  name="language"
                  value={form.language}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                >
                  <option value="en">English</option>
                </select>
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full rounded-2xl bg-[#D4A73C] px-5 py-3 text-sm font-bold text-[#1E3557] transition hover:bg-[#e0b84f] disabled:opacity-60"
              >
                {loading ? "Calculating..." : "Generate Detailed Numerology"}
              </button>
            </form>
          </aside>

          <main className="space-y-6">
            {!result ? (
              <div className="rounded-3xl border border-slate-100 bg-white p-10 shadow-sm">
                <h2 className="text-2xl font-bold">Ready to Calculate</h2>
                <p className="mt-3 max-w-2xl text-sm leading-7 text-slate-500">
                  Submit the form to run number table, full report, favourable timing, vastu, fasts, lord, mantra, and daily prediction modules together.
                </p>
              </div>
            ) : (
              <NumerologyReportLayout
                result={result}
                fullName={fullName}
                birthDate={form.date_of_birth}
                fallback={
                  providerSections.length > 0 ? (
                    <ProviderSections sections={providerSections} />
                  ) : (
                    <ReportPanel title="Detailed Result">
                      <ReportDataBlock title="Detailed Numerology" data={result.data} />
                    </ReportPanel>
                  )
                }
              />
            )}
          </main>
        </div>
      </section>

      <Footer />
    </div>
  );
}
