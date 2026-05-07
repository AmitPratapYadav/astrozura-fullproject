import { useEffect, useMemo, useState } from "react";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import InlineInfoPopover from "../components/InlineInfoPopover";
import { getNumerologyReport } from "../api/prokeralaApi";
import { useAuth } from "../context/AuthContext";

const calculatorGroups = {
  pythagorean: [
    {
      value: "life-path-number",
      label: "Life Path Number",
      description: "Core destiny pattern derived from your birth date.",
      requiresDate: true,
    },
    {
      value: "birthday-number",
      label: "Birthday Number",
      description: "Natural talent and day-of-birth vibration.",
      requiresDate: true,
    },
    {
      value: "birth-month-number",
      label: "Birth Month Number",
      description: "Month-based temperament and instinct profile.",
      requiresDate: true,
    },
    {
      value: "expression-number",
      label: "Expression Number",
      description: "The full-name blueprint of your outward expression.",
      requiresName: true,
    },
    {
      value: "soul-urge-number",
      label: "Soul Urge Number",
      description: "Inner desires, emotional drives, and hidden motives.",
      requiresName: true,
      requiresAdditionalVowel: true,
    },
    {
      value: "personality-number",
      label: "Personality Number",
      description: "How the outer world experiences your energy.",
      requiresName: true,
      requiresAdditionalVowel: true,
    },
    {
      value: "maturity-number",
      label: "Maturity Number",
      description: "How your birth path and name energy mature together.",
      requiresDate: true,
      requiresName: true,
    },
    {
      value: "personal-year-number",
      label: "Personal Year Number",
      description: "Theme and lessons for the selected calendar year.",
      requiresDate: true,
      requiresReferenceYear: true,
    },
    {
      value: "personal-month-number",
      label: "Personal Month Number",
      description: "Monthly emphasis within the selected year cycle.",
      requiresDate: true,
      requiresReferenceYear: true,
    },
    {
      value: "personal-day-number",
      label: "Personal Day Number",
      description: "Daily energy flow within the selected year cycle.",
      requiresDate: true,
      requiresReferenceYear: true,
    },
  ],
  chaldean: [
    {
      value: "chaldean-life-path-number",
      label: "Chaldean Life Path Number",
      description: "Birth-date vibration through the Chaldean system.",
      requiresDate: true,
    },
    {
      value: "chaldean-birth-number",
      label: "Chaldean Birth Number",
      description: "Root personal vibration based on birth date.",
      requiresDate: true,
    },
    {
      value: "whole-name-number",
      label: "Whole Name Number",
      description: "Total Chaldean value of your full name.",
      requiresName: true,
    },
    {
      value: "daily-name-number",
      label: "Daily Name Number",
      description: "Daily-use name vibration under the Chaldean system.",
      requiresName: true,
    },
    {
      value: "identity-initial-code-number",
      label: "Identity Initial Code Number",
      description: "Identity pattern formed by your initials and full name.",
      requiresName: true,
    },
  ],
};

const flattenCalculators = Object.values(calculatorGroups).flat();

const initialForm = {
  system: "pythagorean",
  calculator: "life-path-number",
  first_name: "",
  middle_name: "",
  last_name: "",
  date_of_birth: "",
  reference_year: String(new Date().getFullYear()),
  additional_vowel: false,
};

const titleize = (value) =>
  String(value || "")
    .replace(/_/g, " ")
    .replace(/\b\w/g, (match) => match.toUpperCase());

const renderPrimitive = (value) => {
  if (typeof value === "boolean") return value ? "Yes" : "No";
  if (value === null || value === undefined || value === "") return "-";
  return String(value);
};

const formatNameParts = (parts) => {
  if (!parts || typeof parts !== "object") return "";

  return [parts.first_name, parts.middle_name, parts.last_name]
    .map((value) => String(value || "").trim())
    .filter(Boolean)
    .join(" ");
};

function ResultTree({ value, label }) {
  if (value === null || value === undefined) return null;

  if (Array.isArray(value)) {
    if (!value.length) return null;
    return (
      <div className="space-y-3">
        {label && <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">{titleize(label)}</p>}
        {value.map((item, index) => (
          <div key={`${label || "item"}-${index}`} className="rounded-2xl border border-slate-100 bg-white p-4">
            <ResultTree value={item} />
          </div>
        ))}
      </div>
    );
  }

  if (typeof value === "object") {
    const entries = Object.entries(value).filter(([, child]) => child !== null && child !== undefined && child !== "");
    if (!entries.length) return null;

    return (
      <div className="space-y-4">
        {label && <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">{titleize(label)}</p>}
        <div className="grid gap-4 md:grid-cols-2">
          {entries.map(([childKey, childValue]) => {
            const isNested = Array.isArray(childValue) || typeof childValue === "object";

            return (
              <div key={childKey} className="rounded-2xl border border-slate-100 bg-[#f8f9fc] p-4">
                {isNested ? (
                  <ResultTree value={childValue} label={childKey} />
                ) : (
                  <>
                    <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-500">{titleize(childKey)}</p>
                    <p className="mt-2 text-sm font-semibold text-[#1E3557]">{renderPrimitive(childValue)}</p>
                  </>
                )}
              </div>
            );
          })}
        </div>
      </div>
    );
  }

  return (
    <div className="rounded-2xl border border-slate-100 bg-[#f8f9fc] p-4">
      {label && <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-500">{titleize(label)}</p>}
      <p className="mt-2 text-sm font-semibold text-[#1E3557]">{renderPrimitive(value)}</p>
    </div>
  );
}

export default function Numerology() {
  const { user } = useAuth();
  const [form, setForm] = useState(initialForm);
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState("");
  const [result, setResult] = useState(null);

  const currentCalculator = useMemo(
    () => flattenCalculators.find((item) => item.value === form.calculator) || flattenCalculators[0],
    [form.calculator]
  );

  const calculatorsForSystem = useMemo(
    () => calculatorGroups[form.system] || [],
    [form.system]
  );

  useEffect(() => {
    if (!user) return;

    const nameParts = String(user.name || "").trim().split(/\s+/).filter(Boolean);
    const firstName = nameParts[0] || "";
    const lastName = nameParts.length > 1 ? nameParts[nameParts.length - 1] : "";
    const middleName = nameParts.length > 2 ? nameParts.slice(1, -1).join(" ") : "";

    setForm((current) => ({
      ...current,
      first_name: current.first_name || firstName,
      middle_name: current.middle_name || middleName,
      last_name: current.last_name || lastName,
      date_of_birth: current.date_of_birth || user?.date_of_birth || "",
    }));
  }, [user]);

  useEffect(() => {
    const available = calculatorGroups[form.system] || [];
    if (!available.some((item) => item.value === form.calculator)) {
      setForm((current) => ({
        ...current,
        calculator: available[0]?.value || "",
      }));
    }
  }, [form.system, form.calculator]);

  useEffect(() => {
    if (!toast) return undefined;
    const timer = window.setTimeout(() => setToast(""), 3000);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const handleChange = (event) => {
    const { name, value, type, checked } = event.target;
    setForm((current) => ({
      ...current,
      [name]: type === "checkbox" ? checked : value,
    }));
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (currentCalculator.requiresDate && !form.date_of_birth) {
      setToast("Date of birth is required for the selected numerology calculator.");
      return;
    }

    if (currentCalculator.requiresName && !form.first_name) {
      setToast("First name is required for the selected numerology calculator.");
      return;
    }

    try {
      setLoading(true);
      setResult(null);

      const response = await getNumerologyReport({
        system: form.system,
        calculator: form.calculator,
        first_name: form.first_name,
        middle_name: form.middle_name,
        last_name: form.last_name,
        date_of_birth: form.date_of_birth,
        reference_year: currentCalculator.requiresReferenceYear ? form.reference_year : undefined,
        additional_vowel: currentCalculator.requiresAdditionalVowel ? form.additional_vowel : undefined,
      });

      if (response?.status === "success") {
        setResult(response);
        setToast("Numerology report generated successfully.");
        return;
      }

      setToast(response?.message || "Unable to generate numerology report.");
    } catch (error) {
      setToast(error?.response?.data?.message || "Unable to generate numerology report.");
    } finally {
      setLoading(false);
    }
  };

  const primaryInsight = useMemo(() => {
    if (!result?.data || typeof result.data !== "object") return null;
    return Object.values(result.data).find(
      (item) => item && typeof item === "object" && "name" in item && ("number" in item || "description" in item)
    ) || null;
  }, [result]);

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
              Numerology
            </span>
            <h1 className="mt-6 text-4xl font-black md:text-5xl">Decode Your Number Pattern</h1>
            <p className="mt-5 text-sm leading-7 text-slate-200 md:text-base">
              Explore Pythagorean and Chaldean numerology with calculator-specific inputs. This module now uses the live Astrology API numerology route instead of the old placeholder wrapper.
            </p>
          </div>
        </div>
      </section>

      <section className="relative z-10 mx-auto -mt-14 max-w-7xl px-4 pb-16 md:-mt-16 md:px-8">
        <div className="grid gap-8 xl:grid-cols-[420px_minmax(0,1fr)]">
          <aside className="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm">
            <div>
              <h2 className="text-2xl font-bold">Numerology Inputs</h2>
              <p className="mt-2 text-sm text-slate-500">
                The selected calculator decides which fields are actually required.
              </p>
            </div>

            <form onSubmit={handleSubmit} className="mt-6 space-y-5">
              <div>
                <label className="mb-2 block text-sm font-semibold text-slate-600">System</label>
                <select
                  name="system"
                  value={form.system}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                >
                  <option value="pythagorean">Pythagorean</option>
                  <option value="chaldean">Chaldean</option>
                </select>
              </div>

              <div>
                <label className="mb-2 flex items-center gap-2 text-sm font-semibold text-slate-600">
                  <span>Calculator</span>
                  <InlineInfoPopover
                    title="How to choose a numerology report"
                    content="Pick the number or report you want to calculate. Birth-date reports use your date of birth, while name-based reports use your full name. If you are unsure, start with Life Path Number or Maturity Number."
                  />
                </label>
                <select
                  name="calculator"
                  value={form.calculator}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                >
                  {calculatorsForSystem.map((calculator) => (
                    <option key={calculator.value} value={calculator.value}>
                      {calculator.label}
                    </option>
                  ))}
                </select>
                <p className="mt-2 text-xs leading-5 text-slate-500">{currentCalculator?.description}</p>
              </div>

              {currentCalculator?.requiresName && (
                <>
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
                </>
              )}

              {currentCalculator?.requiresDate && (
                <div>
                  <label className="mb-2 block text-sm font-semibold text-slate-600">Date of Birth</label>
                  <input
                    type="date"
                    name="date_of_birth"
                    value={form.date_of_birth}
                    onChange={handleChange}
                    className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  />
                </div>
              )}

              {currentCalculator?.requiresReferenceYear && (
                <div>
                  <label className="mb-2 block text-sm font-semibold text-slate-600">Reference Year</label>
                  <input
                    type="number"
                    name="reference_year"
                    value={form.reference_year}
                    onChange={handleChange}
                    min="1900"
                    max="2100"
                    className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                  />
                </div>
              )}

              {currentCalculator?.requiresAdditionalVowel && (
                <label className="flex items-center gap-3 rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-4 text-sm font-medium text-slate-700">
                  <input
                    type="checkbox"
                    name="additional_vowel"
                    checked={form.additional_vowel}
                    onChange={handleChange}
                  />
                  Treat the letter Y as an additional vowel
                </label>
              )}

              <button
                type="submit"
                disabled={loading}
                className="w-full rounded-2xl bg-[#D4A73C] px-5 py-3 text-sm font-bold text-[#1E3557] transition hover:bg-[#e0b84f] disabled:opacity-60"
              >
                {loading ? "Calculating..." : "Generate Numerology"}
              </button>
            </form>
          </aside>

          <main className="space-y-6">
            {!result ? (
              <div className="rounded-3xl border border-slate-100 bg-white p-10 shadow-sm">
                <h2 className="text-2xl font-bold">Ready to Calculate</h2>
                <p className="mt-3 max-w-2xl text-sm leading-7 text-slate-500">
                  Choose your numerology system, pick a calculator, and submit the exact inputs it needs. The result panel will show the primary insight first, then the complete structured response from Astrology API.
                </p>
              </div>
            ) : (
              <>
                <div className="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm">
                  <div className="flex flex-wrap items-start justify-between gap-4">
                    <div>
                      <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[#D4A73C]">
                        {result.meta?.system} Numerology
                      </p>
                      <h2 className="mt-2 text-2xl font-bold">{result.meta?.calculator_label || "Numerology Result"}</h2>
                    </div>
                    {result.meta?.is_sandbox_demo && (
                      <span className="rounded-full bg-amber-50 px-4 py-2 text-xs font-semibold uppercase tracking-wide text-amber-700">
                        Sandbox
                      </span>
                    )}
                  </div>

                  {primaryInsight && (
                    <div className="mt-6 rounded-3xl bg-[#fff9ec] p-6">
                      <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">{primaryInsight.name}</p>
                      {"number" in primaryInsight && (
                        <p className="mt-3 text-5xl font-black text-[#1E3557]">{primaryInsight.number}</p>
                      )}
                      {primaryInsight.description && (
                        <p className="mt-4 max-w-3xl text-sm leading-7 text-slate-600">{primaryInsight.description}</p>
                      )}
                    </div>
                  )}

                  {result.meta?.warning && (
                    <div className="mt-5 rounded-2xl border border-amber-100 bg-amber-50 px-4 py-4 text-sm text-amber-900">
                      {result.meta.warning}
                    </div>
                  )}

                  <div className="mt-5 grid gap-4 md:grid-cols-2">
                    {result.meta?.requested_datetime && (
                      <div className="rounded-2xl border border-slate-100 bg-[#f8f9fc] p-4">
                        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-500">Requested Datetime</p>
                        <p className="mt-2 text-sm font-semibold">{result.meta.requested_datetime}</p>
                      </div>
                    )}
                    {result.meta?.effective_datetime && (
                      <div className="rounded-2xl border border-slate-100 bg-[#f8f9fc] p-4">
                        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-500">Effective Datetime</p>
                        <p className="mt-2 text-sm font-semibold">{result.meta.effective_datetime}</p>
                      </div>
                    )}
                    {formatNameParts(result.meta?.requested_names) && (
                      <div className="rounded-2xl border border-slate-100 bg-[#f8f9fc] p-4">
                        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-500">Requested Name</p>
                        <p className="mt-2 text-sm font-semibold">{formatNameParts(result.meta.requested_names)}</p>
                      </div>
                    )}
                    {formatNameParts(result.meta?.effective_names) && (
                      <div className="rounded-2xl border border-slate-100 bg-[#f8f9fc] p-4">
                        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-500">Effective Name</p>
                        <p className="mt-2 text-sm font-semibold">{formatNameParts(result.meta.effective_names)}</p>
                      </div>
                    )}
                  </div>
                </div>

                <div className="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm max-h-[72vh] overflow-y-auto">
                  <h3 className="text-xl font-bold">Detailed Result</h3>
                  <div className="mt-6">
                    <ResultTree value={result.data} />
                  </div>
                </div>
              </>
            )}
          </main>
        </div>
      </section>

      <Footer />
    </div>
  );
}
