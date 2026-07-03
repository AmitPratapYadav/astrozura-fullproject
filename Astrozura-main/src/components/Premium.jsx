import React, { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { getDailyHoroscope, getMonthlyHoroscope } from "../api/prokeralaApi";
import { serviceCatalog } from "../data/serviceCatalog";
import { getZodiacIcon } from "../data/zodiacIcons";

const zodiac = [
  { sign: "aries", id: "Aries", range: "March 21 - April 19", luckyColor: "Gold", luckyNumber: "08" },
  { sign: "taurus", id: "Taurus", range: "April 20 - May 20", luckyColor: "Forest Green", luckyNumber: "06" },
  { sign: "gemini", id: "Gemini", range: "May 21 - June 20", luckyColor: "Sky Blue", luckyNumber: "05" },
  { sign: "cancer", id: "Cancer", range: "June 21 - July 22", luckyColor: "Silver", luckyNumber: "02" },
  { sign: "leo", id: "Leo", range: "July 23 - August 22", luckyColor: "Amber", luckyNumber: "01" },
  { sign: "virgo", id: "Virgo", range: "August 23 - September 22", luckyColor: "Olive", luckyNumber: "07" },
  { sign: "libra", id: "Libra", range: "September 23 - October 22", luckyColor: "Blush Pink", luckyNumber: "09" },
  { sign: "scorpio", id: "Scorpio", range: "October 23 - November 21", luckyColor: "Crimson", luckyNumber: "04" },
  { sign: "sagittarius", id: "Sagittarius", range: "November 22 - December 21", luckyColor: "Royal Purple", luckyNumber: "03" },
  { sign: "capricorn", id: "Capricorn", range: "December 22 - January 19", luckyColor: "Steel Blue", luckyNumber: "10" },
  { sign: "aquarius", id: "Aquarius", range: "January 20 - February 18", luckyColor: "Electric Blue", luckyNumber: "11" },
  { sign: "pisces", id: "Pisces", range: "February 19 - March 20", luckyColor: "Sea Green", luckyNumber: "12" },
];

const readableApiError = (value, fallback) => {
  if (typeof value !== "string" || !value.trim() || value.trim().startsWith("{")) {
    return fallback;
  }
  return value;
};

const readablePrediction = (value, fallback) =>
  typeof value === "string" && value.trim() && !value.trim().startsWith("{")
    ? value
    : fallback;

export default function Premium() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [message, setMessage] = useState("");
  const [activeSign, setActiveSign] = useState("aries");
  const [activePeriod, setActivePeriod] = useState("daily");
  const [horoscope, setHoroscope] = useState(null);
  const [loadingHoroscope, setLoadingHoroscope] = useState(false);
  const [horoscopeError, setHoroscopeError] = useState("");

  const premiumServices = useMemo(() => {
    const eligibleCategories = new Set(["Reports", "Calculators", "Marriage Matching"]);
    return serviceCatalog
      .filter((item) => eligibleCategories.has(item.category) && !["palm-reading", "premium-consultations"].includes(item.slug))
      .slice(0, 8)
      .map((item) => ({
        title: item.title,
        summary: item.summary,
        to: item.ctaTo,
        icon: item.icon,
      }));
  }, []);

  useEffect(() => {
    if (!message) {
      return undefined;
    }

    const timeoutId = window.setTimeout(() => setMessage(""), 2500);
    return () => window.clearTimeout(timeoutId);
  }, [message]);

  useEffect(() => {
    const loadHoroscope = async () => {
      try {
        setLoadingHoroscope(true);
        setHoroscopeError("");
        
        let response;
        if (activePeriod === "monthly") {
          response = await getMonthlyHoroscope(activeSign);
        } else {
          response = await getDailyHoroscope(activeSign, "today");
        }

        if (response?.status === "success") {
          setHoroscope(response.data);
        } else {
          setHoroscope(null);
          setHoroscopeError(readableApiError(response?.message, t("premium.loading_error")));
        }
      } catch (error) {
        setHoroscope(null);
        setHoroscopeError(readableApiError(error?.response?.data?.message, t("premium.loading_error")));
      } finally {
        setLoadingHoroscope(false);
      }
    };

    void loadHoroscope();
  }, [activeSign, activePeriod, t]);

  const activeSignMeta = useMemo(
    () => zodiac.find((item) => item.sign === activeSign) || zodiac[0],
    [activeSign]
  );

  const notify = (text) => {
    setMessage(text);
  };

  const scoreRows = [
    { label: t("premium.love_relationship"), value: horoscope?.scores?.love ?? 0 },
    { label: t("premium.career_wealth"), value: horoscope?.scores?.career ?? 0 },
    { label: t("premium.health_wellness"), value: horoscope?.scores?.health ?? 0 },
  ];

  return (
    <section className="bg-[#FAF7F2] pt-4 pb-16 px-4 md:px-10">
      {message && (
      <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-md bg-[#c7926a] px-5 py-2 text-xs text-white shadow">
          {message}
        </div>
      )}

      <div className="w-full max-w-[1200px] mx-auto">
        <div>
          <h2 className="text-2xl md:text-3xl font-bold text-center text-[#2B2B2B] mb-2">
            {t("premium.forecast_title")}
          </h2>
          <div className="flex justify-center items-center gap-4 text-sm font-bold mb-8">
            <button
              onClick={() => setActivePeriod("daily")}
              className={`transition-colors ${activePeriod === "daily" ? "text-[#D4A73C] underline underline-offset-8" : "text-gray-400 hover:text-[#2B2B2B]"}`}
            >
              {t("premium.daily")}
            </button>
            <div className="w-1 h-1 bg-gray-300 rounded-full"></div>
            <button
              onClick={() => setActivePeriod("monthly")}
              className={`transition-colors ${activePeriod === "monthly" ? "text-[#D4A73C] underline underline-offset-8" : "text-gray-400 hover:text-[#2B2B2B]"}`}
            >
              {t("premium.monthly")}
            </button>
          </div>

          <div className="flex w-full justify-start md:justify-center gap-3 overflow-x-auto pb-6 hide-scrollbar max-w-6xl mx-auto px-2">
            {zodiac.map((z) => (
              <div
                key={z.sign}
                onClick={() => setActiveSign(z.sign)}
                className="cursor-pointer text-center group min-w-[70px] md:min-w-[80px]"
              >
                <div
                  className={`w-[60px] h-[60px] md:w-[72px] md:h-[72px] mx-auto flex items-center justify-center rounded-[18px] transition-all duration-300 ${
                    activeSign === z.sign
                      ? "bg-gradient-to-br from-[#D4A73C] to-[#C29630] shadow-xl text-white"
                      : "bg-white border border-gray-100 text-[#1E3557] group-hover:border-[#D4A73C]/50"
                  }`}
                >
                  <img src={getZodiacIcon(z.sign)} alt="" className="h-11 w-11 object-contain md:h-14 md:w-14" />
                </div>
                <p className={`mt-2 font-bold text-[11px] md:text-xs capitalize transition-colors ${activeSign === z.sign ? 'text-[#C05D17]' : 'text-[#2B2B2B]'}`}>
                  {t(`horoscope.signs.${z.sign}`)}
                </p>
              </div>
            ))}
          </div>

          <div className="bg-white rounded-[2rem] shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-[#F0F0F0] mt-4 p-4 md:p-6 flex flex-col lg:flex-row gap-6 md:gap-10 w-full max-w-6xl mx-auto">
            
            {/* Left Card */}
            <div className="bg-[#FCF9F2] rounded-2xl p-6 lg:p-8 w-full lg:w-[280px] text-center border border-[#F6EFE2] shrink-0">
              <div className="w-[100px] h-[100px] mx-auto bg-[#F1DEBE] rounded-full flex items-center justify-center text-[#B58C36] mb-5 border border-[#E9D1A7]">
                <img src={getZodiacIcon(activeSignMeta.sign)} alt="" className="h-20 w-20 object-contain" />
              </div>

              <h3 className="font-bold text-[#2B2B2B] text-xl mb-1 capitalize">
                {t(`horoscope.signs.${activeSignMeta.sign}`)}
              </h3>
              <p className="text-[11px] text-gray-400 mb-8 font-medium">
                {activeSignMeta.range}
              </p>

              <div className="grid gap-3 mb-8 text-xs">
                <div className="flex justify-between items-center text-gray-500">
                  <span>{t("premium.lucky_color")}</span>
                  <span className="font-bold text-[#2B2B2B]">{activeSignMeta.luckyColor}</span>
                </div>
                <div className="flex justify-between items-center text-gray-500">
                  <span>{t("premium.lucky_number")}</span>
                  <span className="font-bold text-[#2B2B2B]">{activeSignMeta.luckyNumber}</span>
                </div>
              </div>

              <div className="bg-white rounded-[1rem] px-4 py-3 text-left border border-[#F2EFE8]">
                <p className="text-[9px] uppercase text-gray-300 font-bold tracking-widest mb-1.5">
                  {t("premium.horoscope_date")}
                </p>
                <p className="text-xs font-bold text-[#1E3557]">
                  {loadingHoroscope ? t("premium.loading_short") : (horoscope?.display_date || t("horoscope.today"))}
                </p>
              </div>
            </div>

            {/* Right Card / Forecast */}
            <div className="flex-1 lg:py-6 relative">
              <div className="flex items-center justify-between border-b border-gray-100 pb-4 mb-6">
                <h3 className="text-lg font-bold text-[#2B2B2B]">
                  {t("premium.forecast")}
                </h3>
                <span className="bg-[#FAEED6] text-[#D4A73C] text-[11px] font-bold px-3 py-1.5 rounded-md">
                  {activePeriod === "monthly" ? t("premium.monthly_reading") : t("premium.daily_reading")}
                </span>
              </div>

              {loadingHoroscope ? (
                <div className="space-y-4">
                  <div className="h-4 bg-gray-100 rounded-full animate-pulse w-3/4"></div>
                  <div className="h-4 bg-gray-100 rounded-full animate-pulse w-1/2"></div>
                </div>
              ) : horoscopeError ? (
                <p className="text-[#FF4D4D] text-sm">{horoscopeError}</p>
              ) : (
                <>
                  <p className="text-sm md:text-base text-gray-600 leading-relaxed">
                    {readablePrediction(horoscope?.daily_prediction?.personal, t("premium.default_personal"))}
                  </p>

                  <div className="grid gap-8">
                    {scoreRows.map((item) => (
                      <div key={item.label} className="group/bar">
                        <div className="flex justify-between items-center mb-3">
                          <span className="text-[10px] font-black text-[#1E3557] uppercase tracking-widest">{item.label}</span>
                          <span className="text-xs font-black text-[#D4A73C]">{item.value}%</span>
                        </div>

                        <div className="w-full bg-white h-3 rounded-full border border-gray-100 overflow-hidden p-0.5">
                          <div
                            className="bg-gradient-to-r from-[#D4A73C] to-[#b8860b] h-full rounded-full transition-all duration-1000 ease-out"
                            style={{ width: `${item.value}%` }}
                          ></div>
                        </div>
                      </div>
                    ))}
                  </div>

                  <div className="mt-12 grid gap-6 md:grid-cols-2">
                    <div className="rounded-[1.5rem] bg-white p-6 shadow-sm border border-[#EEE7D6] hover:border-[#D4A73C]/30 transition-colors">
                      <div className="flex items-center gap-2 mb-4">
                        <span className="text-lg">💼</span>
                        <p className="text-[10px] uppercase tracking-widest text-gray-400 font-black">
                          {t("premium.career_insight")}
                        </p>
                      </div>
                      <p className="text-sm text-[#1E3557] leading-relaxed font-medium">
                        {readablePrediction(horoscope?.daily_prediction?.profession, t("premium.default_profession"))}
                      </p>
                    </div>

                    <div className="rounded-[1.5rem] bg-white p-6 shadow-sm border border-[#EEE7D6] hover:border-[#D4A73C]/30 transition-colors">
                      <div className="flex items-center gap-2 mb-4">
                        <span className="text-lg">🎭</span>
                        <p className="text-[10px] uppercase tracking-widest text-gray-400 font-black">
                          {t("premium.emotional_insight")}
                        </p>
                      </div>
                      <p className="text-sm text-[#1E3557] leading-relaxed font-medium">
                        {readablePrediction(horoscope?.daily_prediction?.emotions, t("premium.default_emotions"))}
                      </p>
                    </div>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>

        <div className="mt-14 rounded-3xl bg-[#1E3557] px-4 py-10 sm:px-6 md:mt-20 md:px-8">
          <div className="mb-8 flex flex-wrap items-end justify-between gap-3">
            <div>
              <h2 className="text-xl font-bold text-white md:text-2xl">
                {t("premium.home_title")}
              </h2>
              <p className="mt-1 text-xs text-white/65">
                {t("premium.home_subtitle")}
              </p>
            </div>

            <button
              onClick={() => navigate("/services")}
              className="text-xs font-semibold text-white hover:underline"
            >
              {t("premium.view_all")}
            </button>
          </div>

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
            {premiumServices.map((item) => (
              <div
                key={item.title}
                className="group flex min-h-[260px] flex-col rounded-2xl border border-[#EEE7D6] bg-white p-5 text-center shadow-sm transition hover:-translate-y-1 hover:border-[#D4A73C]/45 hover:shadow-xl"
              >
                <div className="mx-auto mb-4 flex h-24 w-24 items-center justify-center rounded-2xl bg-[#FBF7F0] p-3 ring-1 ring-[#EFE5D4] transition group-hover:scale-[1.03] sm:h-28 sm:w-28">
                  {item.icon ? (
                    <img src={item.icon} alt="" className="h-full w-full object-contain" />
                  ) : (
                    <span className="text-xl font-black text-[#1E3557]">AZ</span>
                  )}
                </div>

                <h3 className="text-base font-black leading-6 text-[#1E3557]">
                  {item.title}
                </h3>

                <p className="mt-3 line-clamp-3 text-sm leading-6 text-gray-500">
                  {item.summary}
                </p>

                <div className="mt-auto flex justify-center pt-5">
                  <button
                    onClick={() => {
                      notify(`${item.title} selected`);
                      navigate(item.to);
                    }}
                    className="w-full rounded-xl border border-[#1E3557] px-4 py-3 text-xs font-black text-[#1E3557] transition hover:bg-[#1E3557] hover:text-white"
                  >
                    {t("premium.open")}
                  </button>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-6 flex justify-center md:hidden">
            <button
              onClick={() => navigate("/services")}
              className="inline-flex items-center justify-center rounded-full border border-white/35 bg-transparent px-6 py-3 text-xs font-black uppercase tracking-[0.16em] text-white shadow-sm transition hover:bg-white hover:text-[#1E3557]"
            >
              {t("premium.view_all")}
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}
