import { useEffect, useState } from "react";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { ProviderSections } from "../components/report/ReportDataRenderer";
import { getLalKitabReport, searchLocation } from "../api/prokeralaApi";
import { useAuth } from "../context/AuthContext";

const initialForm = {
  date_of_birth: "",
  time_of_birth: "",
  place_of_birth: "",
  coordinates: "",
  language: "en",
};

const formatDateTime = (value) => {
  if (!value) return "-";
  try {
    return new Date(value).toLocaleString("en-IN", {
      dateStyle: "medium",
      timeStyle: "short",
    });
  } catch {
    return value;
  }
};

export default function LalKitabReport() {
  const { user } = useAuth();
  const [form, setForm] = useState(initialForm);
  const [searchResults, setSearchResults] = useState([]);
  const [loadingPlaces, setLoadingPlaces] = useState(false);
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState("");
  const [report, setReport] = useState(null);

  useEffect(() => {
    if (!user) return;

    const coordinates =
      user.latitude != null && user.longitude != null
        ? `${user.latitude},${user.longitude}`
        : "";

    setForm((current) => ({
      ...current,
      date_of_birth: current.date_of_birth || user.date_of_birth || "",
      time_of_birth: current.time_of_birth || user.time_of_birth || "",
      place_of_birth: current.place_of_birth || user.place_of_birth || "",
      coordinates: current.coordinates || coordinates,
    }));
  }, [user]);

  useEffect(() => {
    if (!toast) return undefined;
    const timer = window.setTimeout(() => setToast(""), 3500);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const handleChange = (event) => {
    const { name, value } = event.target;
    setForm((current) => ({
      ...current,
      [name]: value,
    }));
  };

  const handleLocationSearch = async (value) => {
    setForm((current) => ({
      ...current,
      place_of_birth: value,
      coordinates: "",
    }));

    if (value.trim().length < 3) {
      setSearchResults([]);
      return;
    }

    try {
      setLoadingPlaces(true);
      const response = await searchLocation(value.trim(), form.language);
      setSearchResults(response?.data || []);
    } catch {
      setSearchResults([]);
    } finally {
      setLoadingPlaces(false);
    }
  };

  const selectLocation = (place) => {
    setForm((current) => ({
      ...current,
      place_of_birth: place.name,
      coordinates: `${place.coordinates.latitude},${place.coordinates.longitude}`,
    }));
    setSearchResults([]);
  };

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (!form.date_of_birth || !form.time_of_birth) {
      setToast("Date and time of birth are required.");
      return;
    }

    if (!form.coordinates) {
      setToast("Select a valid birthplace from the dropdown.");
      return;
    }

    try {
      setLoading(true);
      setReport(null);

      const datetime = `${form.date_of_birth}T${form.time_of_birth}:00+05:30`;
      const response = await getLalKitabReport(datetime, form.coordinates, { la: form.language });

      if (response?.status === "success") {
        setReport({
          ...response.data,
          requested_datetime: datetime,
        });
        setToast("Lal Kitab report generated successfully.");
        return;
      }

      setToast(response?.message || "Unable to generate Lal Kitab report.");
    } catch (error) {
      setToast(error?.response?.data?.message || "Unable to generate Lal Kitab report.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#FBF7F0] text-[#1E3557]">
      {toast && (
        <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-xl bg-[#1E3557] px-6 py-3 text-sm font-medium text-white shadow-lg">
          {toast}
        </div>
      )}

      <Navbar />

      <section className="bg-gradient-to-r from-[#8C3B3B] to-[#C86B3C] px-4 py-20 text-white md:px-10">
        <div className="mx-auto max-w-7xl">
          <span className="rounded-full border border-white/20 bg-white/10 px-4 py-1.5 text-[11px] font-bold uppercase tracking-[0.22em]">
            Lal Kitab Reports
          </span>
          <h1 className="mt-6 max-w-4xl text-4xl font-black leading-tight md:text-6xl">
            Generate Your Lal Kitab Guidance
          </h1>
          <p className="mt-6 max-w-3xl text-sm leading-7 text-white/85 md:text-base">
            Review planetary tendencies, house-level observations, and practical Lal Kitab-style remedial guidance from your birth details.
          </p>
        </div>
      </section>

      <section className="relative z-10 mx-auto -mt-12 max-w-7xl px-4 pb-16 md:px-10">
        <div className="grid gap-8 xl:grid-cols-[420px_minmax(0,1fr)]">
          <aside className="rounded-[2rem] border border-[#EFE3D1] bg-white p-6 shadow-sm">
            <h2 className="text-2xl font-bold">Birth Inputs</h2>
            <p className="mt-2 text-sm text-slate-500">
              Lal Kitab requires the exact birth date, birth time, and a verified birthplace selection.
            </p>

            <form onSubmit={handleSubmit} className="mt-6 space-y-5">
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

              <div>
                <label className="mb-2 block text-sm font-semibold text-slate-600">Time of Birth</label>
                <input
                  type="time"
                  name="time_of_birth"
                  value={form.time_of_birth}
                  onChange={handleChange}
                  className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                />
              </div>

              <div className="relative">
                <label className="mb-2 block text-sm font-semibold text-slate-600">Birth Place</label>
                <input
                  type="text"
                  value={form.place_of_birth}
                  onChange={(event) => handleLocationSearch(event.target.value)}
                  placeholder="Search birthplace"
                  className="w-full rounded-2xl border border-slate-200 bg-[#f8f9fc] px-4 py-3 pr-10 text-sm outline-none focus:border-[#D4A73C]"
                />
                {loadingPlaces && <div className="absolute right-4 top-[50px] h-4 w-4 animate-spin rounded-full border-b-2 border-[#D4A73C]" />}
                {searchResults.length > 0 && (
                  <div className="absolute z-20 mt-1 max-h-60 w-full overflow-y-auto rounded-2xl border border-slate-200 bg-white shadow-xl">
                    {searchResults.map((place, index) => (
                      <button
                        key={`${place.name}-${index}`}
                        type="button"
                        onClick={() => selectLocation(place)}
                        className="block w-full border-b border-slate-50 px-4 py-3 text-left text-sm hover:bg-slate-50 last:border-0"
                      >
                        {place.name}
                      </button>
                    ))}
                  </div>
                )}
              </div>

              {form.coordinates && (
                <div className="rounded-2xl border border-slate-100 bg-[#f8f9fc] px-4 py-3 text-xs text-slate-500">
                  Coordinates: {form.coordinates}
                </div>
              )}

              <button
                type="submit"
                disabled={loading}
                className="w-full rounded-2xl bg-[#1E3557] px-5 py-3 text-sm font-bold text-white transition hover:bg-[#162744] disabled:opacity-60"
              >
                {loading ? "Generating..." : "Generate Lal Kitab Report"}
              </button>
            </form>
          </aside>

          <main className="space-y-6">
            {!report ? (
              <div className="rounded-[2rem] border border-[#EFE3D1] bg-white p-10 shadow-sm">
                <h2 className="text-2xl font-bold">Ready to Generate</h2>
                <p className="mt-3 max-w-2xl text-sm leading-7 text-slate-500">
                  This standalone Lal Kitab page uses the working Astrology API route directly. Submit birth details to view remedies, planet observations, house patterns, and sign occupancy.
                </p>
              </div>
            ) : (
              <>
                <div className="rounded-[2rem] border border-[#EFE3D1] bg-white p-6 shadow-sm">
                  <div className="flex flex-wrap items-start justify-between gap-4">
                    <div>
                      <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[#D4A73C]">Lal Kitab Report</p>
                      <h2 className="mt-2 text-2xl font-bold">Generated Analysis</h2>
                    </div>
                    <div className="rounded-2xl border border-slate-100 bg-[#f8f9fc] px-4 py-3 text-sm text-slate-600">
                      {formatDateTime(report.requested_datetime)}
                    </div>
                  </div>
                </div>

                <ProviderSections sections={report.provider_sections || []} />
              </>
            )}
          </main>
        </div>
      </section>

      <Footer />
    </div>
  );
}
