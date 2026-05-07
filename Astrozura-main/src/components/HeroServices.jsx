import { useEffect, useRef, useState } from "react";
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";
import { useTranslation } from "react-i18next";
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
      setMessage("Complete all kundli details before generating the PDF.");
      return;
    }

    if (!form.coordinates) {
      setMessage("Choose the place of birth from the search dropdown.");
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
      setMessage("Kundli PDF downloaded successfully.");
    } catch (error) {
      const blob = error?.response?.data;
      if (blob instanceof Blob) {
        setMessage(await parseBlobError(blob));
      } else {
        setMessage(error?.response?.data?.message || "Unable to generate the kundli PDF.");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-[#FAF7F2] min-h-screen font-sans">
      {message && (
      <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-lg bg-[#d8ba4a] px-6 py-3 text-sm text-white shadow-lg">
          {message}
        </div>
      )}

      <div className="max-w-[1200px] mx-auto px-4 md:px-10">
        <section className="py-10 md:py-16">
          <div className="grid md:grid-cols-2 gap-10 md:gap-12 items-center">
            <div className="text-center md:text-left">
              <p className="text-xs md:text-sm text-[#D4A73C] font-semibold mb-3">
                {t("hero.tagline")}
              </p>

              <h1 className="text-3xl sm:text-4xl md:text-5xl font-extrabold text-[#1F2937] leading-tight">
                {t("hero.title_main")}{" "}
                <span className="bg-gradient-to-r from-[#d8b14a] to-[#c7926a] bg-clip-text text-transparent italic">
                  {t("hero.title_span")}
                </span>{" "}
                {t("hero.title_end")}
              </h1>

              <p className="text-[#6B7280] mt-4 md:mt-5 max-w-md mx-auto md:mx-0 text-sm md:text-base">
                {t("hero.desc")}
              </p>

              <div className="mt-6 max-w-md mx-auto md:mx-0 text-left bg-white/50 p-4 rounded-xl border border-white shadow-sm inline-block">
                <p className="text-[11px] font-black text-[#1E3557] uppercase tracking-widest mb-3">Free Kundli Includes:</p>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-y-2 gap-x-6 text-xs text-[#6B7280] font-medium">
                  <div className="flex items-center gap-2"><div className="w-1.5 h-1.5 rounded-full bg-[#d8b14a] shadow-sm"></div>General Birth Details (D1)</div>
                  <div className="flex items-center gap-2"><div className="w-1.5 h-1.5 rounded-full bg-[#d8b14a] shadow-sm"></div>Basic Astrological Details</div>
                  <div className="flex items-center gap-2"><div className="w-1.5 h-1.5 rounded-full bg-[#d8b14a] shadow-sm"></div>Rashiphal</div>
                  <div className="flex items-center gap-2"><div className="w-1.5 h-1.5 rounded-full bg-[#d8b14a] shadow-sm"></div>Nakshatraphal</div>
                  <div className="flex items-center gap-2 sm:col-span-2"><div className="w-1.5 h-1.5 rounded-full bg-[#d8b14a] shadow-sm"></div>Remedy (Past & Present)</div>
                </div>
              </div>

              <div className="flex flex-col sm:flex-row items-center gap-4 sm:gap-5 mt-6 justify-center md:justify-start">
                <button
                  onClick={handleFreeKundliClick}
                  className="bg-[#d8b14a] text-white px-6 py-3 rounded-full text-sm font-medium hover:bg-[#c79c3a] transition shadow-lg w-full sm:w-auto"
                >
                  {t("hero.cta")}
                </button>

                <div className="flex items-center gap-2">
                  <img
                    src={users}
                    alt="users"
                    className="w-9 h-9 rounded-full object-cover border-2 border-white shadow"
                  />
                  <p className="text-xs text-[#6B7280]">
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
                  className="border border-gray-200 p-3 w-full rounded-xl text-sm outline-none focus:ring-2 focus:ring-[#D4A73C]"
                />
              </div>

              <input
                type="time"
                value={form.timeOfBirth}
                onChange={(event) => handleFieldChange("timeOfBirth", event.target.value)}
                className="border border-gray-200 p-3 w-full mb-3 rounded-xl text-sm outline-none focus:ring-2 focus:ring-[#D4A73C]"
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
                <p className="text-[10px] md:text-xs font-bold opacity-70 tracking-wider">HOROSCOPE READS</p>
              </div>

              <div>
                <h2 className="text-xl md:text-2xl font-black">1.2k+</h2>
                <p className="text-[10px] md:text-xs font-bold opacity-70 tracking-wider">EXPERT ASTROLOGERS</p>
              </div>

              <div>
                <h2 className="text-xl md:text-2xl font-black">4.9/5</h2>
                <p className="text-[10px] md:text-xs font-bold opacity-70 tracking-wider">USER RATINGS</p>
              </div>

              <div>
                <h2 className="text-xl md:text-2xl font-black">150+</h2>
                <p className="text-[10px] md:text-xs font-bold opacity-70 tracking-wider">COUNTRIES SERVED</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
