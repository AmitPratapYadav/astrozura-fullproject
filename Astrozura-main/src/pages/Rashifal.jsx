import { useState } from "react";
import { useSearchParams } from "react-router-dom";
import { useTranslation } from "react-i18next";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { FaArrowRight, FaBriefcase, FaHeartbeat, FaHeart, FaMagic } from "react-icons/fa";
import { getDailyHoroscope } from "../api/prokeralaApi";
import { getZodiacIcon } from "../data/zodiacIcons";

const zodiacs = [
  { name: "Aries", key: "aries", date: "Mar 21 - Apr 19", element: "fire", ruler: "mars", tone: "from-[#f97316] to-[#dc2626]", surface: "bg-[#fff6ed]", accent: "text-[#c2410c]" },
  { name: "Taurus", key: "taurus", date: "Apr 20 - May 20", element: "earth", ruler: "venus", tone: "from-[#84cc16] to-[#15803d]", surface: "bg-[#f4fbec]", accent: "text-[#3f7a14]" },
  { name: "Gemini", key: "gemini", date: "May 21 - Jun 20", element: "air", ruler: "mercury", tone: "from-[#38bdf8] to-[#2563eb]", surface: "bg-[#eef8ff]", accent: "text-[#1d4ed8]" },
  { name: "Cancer", key: "cancer", date: "Jun 21 - Jul 22", element: "water", ruler: "moon", tone: "from-[#22d3ee] to-[#0f766e]", surface: "bg-[#eefdfb]", accent: "text-[#0f766e]" },
  { name: "Leo", key: "leo", date: "Jul 23 - Aug 22", element: "fire", ruler: "sun", tone: "from-[#facc15] to-[#ea580c]", surface: "bg-[#fff9db]", accent: "text-[#b45309]" },
  { name: "Virgo", key: "virgo", date: "Aug 23 - Sep 22", element: "earth", ruler: "mercury", tone: "from-[#a3a866] to-[#64748b]", surface: "bg-[#f8f7ee]", accent: "text-[#5b621f]" },
  { name: "Libra", key: "libra", date: "Sep 23 - Oct 22", element: "air", ruler: "venus", tone: "from-[#f0abfc] to-[#7c3aed]", surface: "bg-[#fdf2ff]", accent: "text-[#7e22ce]" },
  { name: "Scorpio", key: "scorpio", date: "Oct 23 - Nov 21", element: "water", ruler: "pluto", tone: "from-[#fb7185] to-[#7f1d1d]", surface: "bg-[#fff1f2]", accent: "text-[#be123c]" },
  { name: "Sagittarius", key: "sagittarius", date: "Nov 22 - Dec 21", element: "fire", ruler: "jupiter", tone: "from-[#f59e0b] to-[#a855f7]", surface: "bg-[#fff7ed]", accent: "text-[#9333ea]" },
  { name: "Capricorn", key: "capricorn", date: "Dec 22 - Jan 19", element: "earth", ruler: "saturn", tone: "from-[#94a3b8] to-[#334155]", surface: "bg-[#f8fafc]", accent: "text-[#334155]" },
  { name: "Aquarius", key: "aquarius", date: "Jan 20 - Feb 18", element: "air", ruler: "uranus", tone: "from-[#60a5fa] to-[#4338ca]", surface: "bg-[#eff6ff]", accent: "text-[#3730a3]" },
  { name: "Pisces", key: "pisces", date: "Feb 19 - Mar 20", element: "water", ruler: "neptune", tone: "from-[#2dd4bf] to-[#6366f1]", surface: "bg-[#f0fdfa]", accent: "text-[#0f766e]" },
];

export default function Rashifal() {
  const { t } = useTranslation();
  const [searchParams, setSearchParams] = useSearchParams();
  const [selectedSign, setSelectedSign] = useState(null);
  const initialPeriod = searchParams.get("period");
  const [activeTab, setActiveTab] = useState(
    ["yesterday", "today", "tomorrow"].includes(initialPeriod) ? initialPeriod : "today"
  );
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const fetchHoroscope = async (sign, day) => {
    try {
      setLoading(true);
      setError("");
      setData(null);

      const response = await getDailyHoroscope(sign.toLowerCase(), day);
      if (response?.status === "success" && response?.data) {
        setData(response.data);
        return;
      }

      setError(response?.message || t("horoscope.fetch_error"));
    } catch (fetchError) {
      console.error("Horoscope fetch error:", fetchError?.response?.data || fetchError.message);
      setError(fetchError?.response?.data?.message || t("horoscope.fetch_error"));
    } finally {
      setLoading(false);
    }
  };

  const handleSelect = (zodiac) => {
    setSelectedSign(zodiac);
    fetchHoroscope(zodiac.name, activeTab);
  };

  const handleTabChange = (day) => {
    setActiveTab(day);
    setSearchParams({ period: day });
    if (selectedSign) {
      fetchHoroscope(selectedSign.name, day);
    }
  };

  return (
    <div className="flex min-h-screen flex-col bg-[#f8f9fa] font-sans">
      <Navbar />

      <section className="relative bg-[#1E3557] px-4 py-20 text-center text-white md:px-8">
        <div className="absolute inset-0 border-b opacity-10" style={{ backgroundImage: "radial-gradient(#D4A73C 1px, transparent 1px)", backgroundSize: "30px 30px" }} />
        <div className="relative mx-auto max-w-4xl">
          <span className="mb-4 inline-block rounded-full border border-[#D4A73C]/30 bg-[#D4A73C]/10 px-4 py-1.5 text-xs font-bold uppercase tracking-widest text-[#D4A73C]">
            {t("horoscope.eyebrow")}
          </span>
          <h1 className="mb-4 text-3xl font-extrabold md:text-5xl">{t("horoscope.page_title")}</h1>
          <p className="text-gray-300 md:text-xl">{t("horoscope.page_subtitle")}</p>
        </div>
      </section>

      <div className="relative z-10 mx-auto grid w-full max-w-7xl flex-1 gap-8 px-4 py-16 -mt-8 md:px-8">
        {!selectedSign ? (
          <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            {zodiacs.map((zodiac) => (
              <button
                key={zodiac.name}
                type="button"
                onClick={() => handleSelect(zodiac)}
                className={`group relative min-h-[230px] overflow-hidden rounded-[1.35rem] border border-white/80 ${zodiac.surface} p-5 text-left shadow-[0_18px_45px_rgba(15,23,42,0.08)] transition duration-300 hover:-translate-y-1 hover:shadow-[0_24px_60px_rgba(15,23,42,0.14)] focus:outline-none focus:ring-2 focus:ring-[#D4A73C]`}
              >
                <div className={`absolute -right-8 -top-10 h-32 w-32 rounded-full bg-gradient-to-br ${zodiac.tone} opacity-20 transition group-hover:scale-125`} />
                <div className="absolute inset-x-5 top-0 h-1 rounded-b-full bg-gradient-to-r from-transparent via-white/70 to-transparent" />

                <div className="relative flex items-start justify-between gap-4">
                  <span className="rounded-full border border-white/70 bg-white/70 px-3 py-1 text-[11px] font-bold uppercase tracking-[0.16em] text-slate-600 shadow-sm">
                    {t(`horoscope.elements.${zodiac.element}`)}
                  </span>
                  <span className="rounded-full bg-white/65 px-3 py-1 text-xs font-semibold text-slate-500 shadow-sm">
                    {zodiac.date}
                  </span>
                </div>

                <div className="relative mt-7 flex items-center gap-4">
                  <div className={`grid h-20 w-20 shrink-0 place-items-center rounded-2xl bg-gradient-to-br ${zodiac.tone} shadow-lg shadow-slate-900/10 ring-4 ring-white/70`}>
                    <img src={getZodiacIcon(zodiac.key)} alt="" className="h-14 w-14 object-contain" />
                  </div>
                  <div className="min-w-0">
                    <h3 className="text-2xl font-black text-[#1E3557]">{t(`horoscope.signs.${zodiac.key}`)}</h3>
                    <p className={`mt-1 text-sm font-semibold ${zodiac.accent}`}>
                      {t("horoscope.ruled_by", { ruler: t(`horoscope.rulers.${zodiac.ruler}`) })}
                    </p>
                  </div>
                </div>

                <div className="relative mt-7 flex items-center justify-between border-t border-white/70 pt-4">
                  <p className="text-sm font-medium text-slate-600">
                    {t("horoscope.open_reading", { period: t(`horoscope.${activeTab}`) })}
                  </p>
                  <span className={`grid h-9 w-9 place-items-center rounded-full bg-white ${zodiac.accent} shadow-sm transition group-hover:translate-x-1`}>
                    <FaArrowRight size={14} />
                  </span>
                </div>
              </button>
            ))}
          </div>
        ) : (
          <div className="mx-auto w-full max-w-5xl overflow-hidden rounded-3xl border border-gray-100 bg-white shadow-xl">
            <div className="relative bg-[#1E3557] p-8 text-center text-white">
              <button
                type="button"
                onClick={() => {
                  setSelectedSign(null);
                  setData(null);
                  setError("");
                }}
                className="absolute left-4 top-4 rounded-lg border border-gray-500 px-3 py-1 text-sm text-gray-300 hover:text-white"
              >
                {t("horoscope.back")}
              </button>
              <img src={getZodiacIcon(selectedSign.key)} alt="" className="mx-auto mb-2 h-20 w-20 object-contain" />
              <h2 className="text-3xl font-bold">{t("horoscope.sign_heading", { sign: t(`horoscope.signs.${selectedSign.key}`) })}</h2>
              <p className="mt-1 text-gray-400">{selectedSign.date}</p>
            </div>

            <div className="p-6 md:p-10">
              <div className="mx-auto mb-10 flex w-max flex-wrap justify-center gap-2 rounded-xl border bg-gray-50 p-2">
                {["yesterday", "today", "tomorrow"].map((day) => (
                  <button
                    key={day}
                    type="button"
                    onClick={() => handleTabChange(day)}
                    className={`rounded-lg px-6 py-2 font-semibold capitalize transition ${activeTab === day ? "bg-[#1E3557] text-[#D4A73C] shadow-md" : "text-gray-600 hover:bg-gray-100"}`}
                  >
                    {t(`horoscope.${day}`)}
                  </button>
                ))}
              </div>

              {loading ? (
                <div className="flex flex-col items-center justify-center py-20">
                  <div className="mb-4 h-12 w-12 animate-spin rounded-full border-b-2 border-[#1E3557]" />
                  <p className="text-gray-500">{t("horoscope.reading")}</p>
                </div>
              ) : error ? (
                <div className="rounded-2xl border border-red-100 bg-red-50 p-10 text-center">
                  <p className="text-red-700">{error}</p>
                </div>
              ) : (
                <div className="space-y-8 animate-fadeIn">
                  {data?.daily_prediction ? (
                    <>
                      <div className="text-center text-sm text-gray-500">
                        {t("horoscope.prediction_date")}: {data.date || t("horoscope.not_provided")}
                      </div>
                      <div className="grid gap-6 md:grid-cols-2">
                        <div className="rounded-2xl border border-indigo-100 bg-indigo-50 p-6">
                          <h4 className="mb-2 flex items-center gap-2 font-bold text-indigo-900">
                            <FaMagic className="text-indigo-500" /> {t("horoscope.personal_insights")}
                          </h4>
                          <p className="text-sm leading-relaxed text-indigo-800">{data.daily_prediction.personal || t("horoscope.no_insights")}</p>
                        </div>
                        <div className="rounded-2xl border border-blue-100 bg-blue-50 p-6">
                          <h4 className="mb-2 flex items-center gap-2 font-bold text-blue-900">
                            <FaBriefcase className="text-blue-500" /> {t("horoscope.career_professional")}
                          </h4>
                          <p className="text-sm leading-relaxed text-blue-800">{data.daily_prediction.profession || t("horoscope.no_insights")}</p>
                        </div>
                        <div className="rounded-2xl border border-rose-100 bg-rose-50 p-6">
                          <h4 className="mb-2 flex items-center gap-2 font-bold text-rose-900">
                            <FaHeartbeat className="text-rose-500" /> {t("horoscope.health")}
                          </h4>
                          <p className="text-sm leading-relaxed text-rose-800">{data.daily_prediction.health || t("horoscope.no_insights")}</p>
                        </div>
                        <div className="rounded-2xl border border-amber-100 bg-amber-50 p-6">
                          <h4 className="mb-2 flex items-center gap-2 font-bold text-amber-900">
                            <FaHeart className="text-amber-500" /> {t("horoscope.emotions_luck")}
                          </h4>
                          <p className="text-sm leading-relaxed text-amber-800">{data.daily_prediction.emotions || t("horoscope.no_insights")}</p>
                        </div>
                      </div>
                    </>
                  ) : (
                    <div className="rounded-2xl border bg-gray-50 p-10 text-center">
                      <p className="text-gray-600">{t("horoscope.quiet")}</p>
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        )}
      </div>

      <Footer />
    </div>
  );
}
