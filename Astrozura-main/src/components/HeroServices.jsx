import { useEffect, useRef, useState } from "react";
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";
import { useTranslation } from "react-i18next";
import { Download } from "lucide-react";
import ComingSoonPopover from "./ComingSoonPopover";
import users from "../assets/avatar-users.jpg";
import { downloadFreeKundliPdf, searchLocation } from "../api/prokeralaApi";

const formatDateForApi = (value) => {
  if (!(value instanceof Date) || Number.isNaN(value.getTime())) {
    return "";
  }

  const year = value.getFullYear();
  const month = String(value.getMonth() + 1).padStart(2, "0");
  const day = String(value.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
};

const parseBlobError = async (blob) => {
  try {
    const text = await blob.text();
    const parsed = JSON.parse(text);
    return parsed?.message || "Unable to generate the kundli PDF.";
  } catch {
    return "Unable to generate the kundli PDF.";
  }
};

export default function HeroServices() {
  const { t } = useTranslation();
  const sectionRef = useRef(null);
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const [searchingLocation, setSearchingLocation] = useState(false);
  const [locationResults, setLocationResults] = useState([]);
  const [form, setForm] = useState({
    name: "",
    gender: "",
    birthDate: null,
    timeOfBirth: "",
    placeOfBirth: "",
    coordinates: "",
  });

  useEffect(() => {
    if (!message) {
      return undefined;
    }

    const timeoutId = window.setTimeout(() => setMessage(""), 3200);
    return () => window.clearTimeout(timeoutId);
  }, [message]);

  const handleFreeKundliClick = () => {
    sectionRef.current?.scrollIntoView({ behavior: "smooth", block: "center" });
  };

  const handleFieldChange = (field, value) => {
    setForm((current) => ({
      ...current,
      [field]: value,
    }));
  };

  const handlePlaceChange = async (value) => {
    setForm((current) => ({
      ...current,
      placeOfBirth: value,
      coordinates: "",
    }));

    if (value.trim().length < 3) {
      setLocationResults([]);
      return;
    }

    try {
      setSearchingLocation(true);
      const response = await searchLocation(value.trim());
      setLocationResults(response?.data || []);
    } catch (error) {
      console.error("Location search failed", error);
      setLocationResults([]);
    } finally {
      setSearchingLocation(false);
    }
  };

  const handleLocationSelect = (item) => {
    setForm((current) => ({
      ...current,
      placeOfBirth: item.name,
      coordinates: `${item.coordinates.latitude},${item.coordinates.longitude}`,
    }));
    setLocationResults([]);
  };

  const handleCreateKundli = async () => {
    if (!form.name || !form.gender || !form.birthDate || !form.timeOfBirth || !form.placeOfBirth) {
      setMessage(t("hero.complete_details"));
      return;
    }

    if (!form.coordinates) {
      setMessage(t("hero.choose_birth_place"));
      return;
    }

    try {
      setLoading(true);
      setMessage(t("hero.generating"));

      const response = await downloadFreeKundliPdf({
        name: form.name,
        gender: form.gender,
        date_of_birth: formatDateForApi(form.birthDate),
        time_of_birth: form.timeOfBirth,
        place_of_birth: form.placeOfBirth,
        coordinates: form.coordinates,
      });

      if ((response.headers["content-type"] || "").includes("application/json")) {
        setMessage(await parseBlobError(response.data));
        return;
      }

      const downloadUrl = window.URL.createObjectURL(response.data);
      const link = document.createElement("a");
      link.href = downloadUrl;
      link.download = `${form.name.trim().replace(/\s+/g, "-").toLowerCase() || "free-kundli"}-kundli.pdf`;
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(downloadUrl);
      setMessage(t("hero.downloaded"));
    } catch (error) {
      const blob = error?.response?.data;
      if (blob instanceof Blob) {
        setMessage(await parseBlobError(blob));
      } else {
        setMessage(error?.response?.data?.message || t("hero.unable_generate"));
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-r from-[#5206E1] to-[#8B2BE2] font-sans">
      {message && (
      <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-lg bg-[#d8ba4a] px-6 py-3 text-sm text-white shadow-lg">
          {message}
        </div>
      )}

      <div className="max-w-[1200px] mx-auto px-4 md:px-10">
        <section className="py-10 md:py-16">
          <div className="grid md:grid-cols-2 gap-10 md:gap-12 items-center">
            <div className="text-center md:text-left">
              <p className="mb-3 text-xs font-semibold text-[#F2D36B] md:text-sm">
                {t("hero.tagline")}
              </p>

              <h1 className="text-3xl font-extrabold leading-tight text-white sm:text-4xl md:text-5xl">
                {t("hero.title_main")}{" "}
                <span className="bg-gradient-to-r from-[#d8b14a] to-[#c7926a] bg-clip-text text-transparent italic">
                  {t("hero.title_span")}
                </span>{" "}
                {t("hero.title_end")}
              </h1>

              <p className="mx-auto mt-4 max-w-md text-sm text-white/80 md:mx-0 md:mt-5 md:text-base">
                {t("hero.desc")}
              </p>

              <div className="mx-auto mt-6 inline-block max-w-md rounded-xl border border-white/20 bg-white/10 p-4 text-left shadow-sm backdrop-blur-sm md:mx-0">
                <p className="mb-3 text-[11px] font-black uppercase tracking-widest text-white">{t("hero.free_kundli_includes")}</p>
                <div className="grid grid-cols-1 gap-x-6 gap-y-2 text-xs font-medium text-white/80 sm:grid-cols-2">
                  <div className="flex items-center gap-2"><div className="w-1.5 h-1.5 rounded-full bg-[#d8b14a] shadow-sm"></div>{t("hero.birth_details")}</div>
                  <div className="flex items-center gap-2"><div className="w-1.5 h-1.5 rounded-full bg-[#d8b14a] shadow-sm"></div>{t("hero.basic_astrological_details")}</div>
                  <div className="flex items-center gap-2"><div className="w-1.5 h-1.5 rounded-full bg-[#d8b14a] shadow-sm"></div>{t("hero.rashiphal")}</div>
                  <div className="flex items-center gap-2"><div className="w-1.5 h-1.5 rounded-full bg-[#d8b14a] shadow-sm"></div>{t("hero.nakshatraphal")}</div>
                  <div className="flex items-center gap-2 sm:col-span-2"><div className="w-1.5 h-1.5 rounded-full bg-[#d8b14a] shadow-sm"></div>{t("hero.remedy")}</div>
                </div>
              </div>

              <div className="mt-6 flex flex-col items-center gap-4 md:items-start">
                <div className="flex w-full flex-col items-center gap-3 sm:w-auto sm:flex-row">
                  <button
                    onClick={handleFreeKundliClick}
                    className="group relative w-full overflow-hidden rounded-full bg-gradient-to-r from-[#D4A73C] via-[#e2bd58] to-[#c7924e] px-7 py-3.5 text-sm font-black text-white shadow-[0_16px_30px_rgba(212,167,60,0.28)] transition duration-300 hover:-translate-y-0.5 hover:shadow-[0_20px_38px_rgba(212,167,60,0.36)] active:translate-y-0 sm:w-auto"
                  >
                    <span className="absolute inset-y-0 -left-10 w-8 skew-x-[-18deg] bg-white/30 transition duration-500 group-hover:left-[115%]" />
                    <span className="relative">{t("hero.cta")}</span>
                  </button>

                  <ComingSoonPopover className="w-full sm:w-auto">
                    <span className="group inline-flex w-full items-center justify-center gap-2 rounded-full border border-[#1E3557]/15 bg-white px-7 py-3.5 text-sm font-black text-[#1E3557] shadow-[0_14px_26px_rgba(30,53,87,0.08)] transition duration-300 hover:-translate-y-0.5 hover:border-[#D4A73C] hover:bg-[#1E3557] hover:text-white sm:w-auto">
                      <span className="flex h-7 w-7 items-center justify-center rounded-full bg-[#F8E7B8] text-[#1E3557] transition group-hover:bg-white group-hover:text-[#D4A73C]">
                        <Download size={16} />
                      </span>
                      {t("hero.download_app")}
                    </span>
                  </ComingSoonPopover>
                </div>

                <div className="flex items-center gap-2">
                  <img
                    src={users}
                    alt="users"
                    className="w-9 h-9 rounded-full object-cover border-2 border-white shadow"
                  />
                  <p className="text-xs text-white/80">
                    {t("hero.users_count")}
                  </p>
                </div>
              </div>
            </div>

            <div
              id="kundliForm"
              ref={sectionRef}
              className="bg-white p-6 md:p-8 rounded-3xl shadow-[0_10px_40px_rgba(0,0,0,0.1)] border border-gray-100 w-full max-w-md mx-auto"
            >
              <h3 className="font-semibold text-[#1F2937] mb-5 text-center md:text-left">
                {t("hero.form_title")}
              </h3>

              <input
                value={form.name}
                onChange={(event) => handleFieldChange("name", event.target.value)}
                className="border border-gray-200 p-3 w-full mb-3 rounded-xl text-sm outline-none focus:ring-2 focus:ring-[#D4A73C]"
                placeholder={t("hero.form_name")}
              />

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 mb-3">
                <select
                  value={form.gender}
                  onChange={(event) => handleFieldChange("gender", event.target.value)}
                  className="border border-gray-200 p-3 rounded-xl text-sm bg-white outline-none focus:ring-2 focus:ring-[#D4A73C]"
                >
                  <option value="">{t("hero.form_gender")}</option>
                  <option value="Male">Male</option>
                  <option value="Female">Female</option>
                  <option value="Other">Other</option>
                </select>

                <DatePicker
                  selected={form.birthDate}
                  onChange={(date) => handleFieldChange("birthDate", date)}
                  placeholderText={t("hero.form_dob")}
                  dateFormat="dd/MM/yyyy"
                  maxDate={new Date()}
                  showMonthDropdown
                  showYearDropdown
                  dropdownMode="select"
                  yearDropdownItemNumber={100}
                  scrollableYearDropdown
                  wrapperClassName="w-full min-w-0"
                  className="border border-gray-200 p-3 w-full rounded-xl text-sm outline-none focus:ring-2 focus:ring-[#D4A73C]"
                />
              </div>

              <input
                type="time"
                value={form.timeOfBirth}
                onChange={(event) => handleFieldChange("timeOfBirth", event.target.value)}
                className="min-w-0 border border-gray-200 p-3 w-full mb-3 rounded-xl text-sm outline-none focus:ring-2 focus:ring-[#D4A73C]"
              />

              <div className="relative mb-2">
                <input
                  value={form.placeOfBirth}
                  onChange={(event) => void handlePlaceChange(event.target.value)}
                  className="border border-gray-200 p-3 w-full rounded-xl text-sm outline-none focus:ring-2 focus:ring-[#D4A73C]"
                  placeholder={t("hero.form_pob")}
                />

                {searchingLocation && (
                  <div className="absolute right-3 top-3.5 h-4 w-4 animate-spin rounded-full border-b-2 border-[#D4A73C]"></div>
                )}

                {locationResults.length > 0 && (
                  <div className="absolute z-20 mt-2 max-h-56 w-full overflow-y-auto rounded-2xl border border-gray-100 bg-white shadow-xl">
                    {locationResults.map((item, index) => (
                      <button
                        key={`${item.name}-${index}`}
                        type="button"
                        onClick={() => handleLocationSelect(item)}
                        className="block w-full border-b border-gray-100 px-4 py-3 text-left text-sm text-[#1F2937] hover:bg-[#FAF7F2] last:border-b-0"
                      >
                        {item.name}
                      </button>
                    ))}
                  </div>
                )}
              </div>

              <p className="mb-4 text-xs text-gray-500">
                {t("hero.form_pob_note")}
              </p>

              <button
                type="button"
                disabled={loading}
                onClick={() => void handleCreateKundli()}
                className="bg-[#d8b14a] text-white w-full py-3 rounded-xl hover:bg-[#c7926a] transition font-medium shadow-md disabled:opacity-60"
              >
                {loading ? t("hero.generating") : t("hero.form_submit")}
              </button>
            </div>
          </div>
        </section>

        <div className="pb-10">
          <div className="bg-gradient-to-r from-[#c7926a] to-[#e0b95a] text-black py-7 rounded-3xl shadow-xl">
            <div className="grid grid-cols-2 md:grid-cols-4 text-center gap-y-8 gap-x-4">
              <div>
                <h2 className="text-xl md:text-2xl font-black">25M+</h2>
                <p className="text-[10px] md:text-xs font-bold opacity-70 tracking-wider">{t("hero.stats.horoscope_reads")}</p>
              </div>

              <div>
                <h2 className="text-xl md:text-2xl font-black">1.2k+</h2>
                <p className="text-[10px] md:text-xs font-bold opacity-70 tracking-wider">{t("hero.stats.expert_astrologers")}</p>
              </div>

              <div>
                <h2 className="text-xl md:text-2xl font-black">4.9/5</h2>
                <p className="text-[10px] md:text-xs font-bold opacity-70 tracking-wider">{t("hero.stats.user_ratings")}</p>
              </div>

              <div>
                <h2 className="text-xl md:text-2xl font-black">150+</h2>
                <p className="text-[10px] md:text-xs font-bold opacity-70 tracking-wider">{t("hero.stats.countries_served")}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
