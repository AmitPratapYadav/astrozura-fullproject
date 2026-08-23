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

const premiumCardThemes = [
  {
    bg: "from-[#FFF4EA] to-[#FFEDE4]",
    orb: "bg-[#FDD2C2]",
    icon: "from-[#FF6B2C] to-[#E63C2E]",
    text: "text-[#C2410C]",
    border: "border-[#F7D6BD]",
  },
  {
    bg: "from-[#F1FAE9] to-[#EAF7DF]",
    orb: "bg-[#CDECC1]",
    icon: "from-[#68C927] to-[#1E8C35]",
    text: "text-[#2F7D1C]",
    border: "border-[#D5EBC8]",
  },
  {
    bg: "from-[#EAF7FF] to-[#E8F2FF]",
    orb: "bg-[#C8E6FF]",
    icon: "from-[#2EB4FF] to-[#2768F0]",
    text: "text-[#1D4ED8]",
    border: "border-[#CBE2F7]",
  },
  {
    bg: "from-[#EAFBF8] to-[#E5F7F2]",
    orb: "bg-[#BEEBE4]",
    icon: "from-[#27C3C8] to-[#0A8F8C]",
    text: "text-[#087F7A]",
    border: "border-[#C8EAE4]",
  },
  {
    bg: "from-[#FFF9D9] to-[#FFF4C2]",
    orb: "bg-[#FFE3A0]",
    icon: "from-[#FFB000] to-[#F97316]",
    text: "text-[#C45A00]",
    border: "border-[#F5DFA3]",
  },
  {
    bg: "from-[#F7F2EA] to-[#F1F3EA]",
    orb: "bg-[#DCE4D5]",
    icon: "from-[#9CAD79] to-[#65756A]",
    text: "text-[#556B2F]",
    border: "border-[#E1E5D5]",
  },
  {
    bg: "from-[#FAECFF] to-[#F5E6FF]",
    orb: "bg-[#E7C8F7]",
    icon: "from-[#B45CFF] to-[#7C3AED]",
    text: "text-[#7E22CE]",
    border: "border-[#E8D1F5]",
  },
  {
    bg: "from-[#FFECEC] to-[#FFE5E9]",
    orb: "bg-[#F4C2C8]",
    icon: "from-[#EF5968] to-[#9F2B37]",
    text: "text-[#BE123C]",
    border: "border-[#F0CDD1]",
  },
];

const themeForService = (item, index) => {
  if (item.accent?.includes("#")) {
    return premiumCardThemes[index % premiumCardThemes.length];
  }
  return premiumCardThemes[index % premiumCardThemes.length];
};

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
        slug: item.slug,
        category: item.category,
        accent: item.accent,
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
      if (activePeriod === "yearly") {
        setHoroscope(null);
        setHoroscopeError("");
        setLoadingHoroscope(false);
        return;
      }

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

  const fallbackScore = (metric) => 58 + (Math.abs(Array.from(`${activeSign}-${activePeriod}-${metric}`).reduce((sum, char) => sum + char.charCodeAt(0), 0)) % 33);
  const scoreRows = [
    { label: t("premium.love_relationship"), value: horoscope?.scores?.love ?? fallbackScore("love") },
    { label: t("premium.career_wealth"), value: horoscope?.scores?.career ?? fallbackScore("career") },
    { label: t("premium.health_wellness"), value: horoscope?.scores?.health ?? fallbackScore("health") },
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
              {t("premium.monthly")} <span className="ml-1 text-[10px] font-black text-[#C05D17]">Rs 10</span>
            </button>
            <div className="w-1 h-1 bg-gray-300 rounded-full"></div>
            <button
              onClick={() => setActivePeriod("yearly")}
              className={`transition-colors ${activePeriod === "yearly" ? "text-[#D4A73C] underline underline-offset-8" : "text-gray-400 hover:text-[#2B2B2B]"}`}
            >
              {t("horoscope.yearly")} <span className="ml-1 text-[10px] font-black text-[#C05D17]">Rs 25</span>
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
                      ? "bg-white border-2 border-[#D4A73C] shadow-lg shadow-[#D4A73C]/20"
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
              <div className="w-[100px] h-[100px] mx-auto bg-white rounded-full flex items-center justify-center text-[#B58C36] mb-5 border-2 border-[#E9D1A7] shadow-sm">
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
                  {activePeriod === "yearly" ? "Yearly Reading" : activePeriod === "monthly" ? t("premium.monthly_reading") : t("premium.daily_reading")}
                </span>
              </div>

              {activePeriod === "yearly" ? (
                <div className="rounded-[1.5rem] border border-[#EEE7D6] bg-[#FCF9F2] p-6">
                  <p className="text-sm leading-7 text-gray-600">
                    Unlock a zodiac-based yearly horoscope for {activeSignMeta.id}. The reading opens on the horoscope page after payment.
                  </p>
                  <div className="mt-5 flex flex-wrap items-center gap-3">
                    <span className="rounded-full bg-white px-4 py-2 text-sm font-black text-[#1E3557] shadow-sm">
                      <span className="mr-2 text-gray-400 line-through">Rs 50</span> Rs 25
                    </span>
                    <span className="rounded-full bg-[#D4A73C] px-4 py-2 text-xs font-black uppercase tracking-wider text-[#1E3557]">
                      50% Off
                    </span>
                  </div>
                  <button
                    type="button"
                    onClick={() => navigate("/rashifal?period=yearly")}
                    className="mt-6 rounded-xl bg-[#1E3557] px-5 py-3 text-xs font-black uppercase tracking-wider text-white transition hover:bg-[#162943]"
                  >
                    Unlock Yearly Horoscope
                  </button>
                </div>
              ) : loadingHoroscope ? (
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

                  {activePeriod === "monthly" && (
                    <div className="my-5 flex flex-wrap items-center gap-3 rounded-2xl border border-[#EEE7D6] bg-[#FCF9F2] px-4 py-3">
                      <span className="text-xs font-black uppercase tracking-wider text-[#1E3557]">Monthly Offer</span>
                      <span className="rounded-full bg-white px-3 py-1 text-xs font-black text-[#1E3557]">
                        <span className="mr-2 text-gray-400 line-through">Rs 20</span> Rs 10
                      </span>
                      <span className="rounded-full bg-[#D4A73C] px-3 py-1 text-[10px] font-black uppercase text-[#1E3557]">50% Off</span>
                    </div>
                  )}

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

          <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
            {premiumServices.map((item, index) => {
              const theme = themeForService(item, index);

              return (
                <div
                  key={item.title}
                  className={`group relative flex min-h-[290px] overflow-hidden rounded-[1.4rem] border ${theme.border} bg-gradient-to-br ${theme.bg} p-5 text-left shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-2xl hover:shadow-black/20`}
                >
                  <div className={`absolute -right-8 -top-10 h-28 w-28 rounded-full ${theme.orb} opacity-70 transition group-hover:scale-110`} />
                  <div className="relative z-10 flex h-full w-full flex-col">
                    <div className="flex items-start justify-between gap-4">
                      <div className={`flex h-24 w-24 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br ${theme.icon} p-2.5 shadow-lg shadow-black/10 ring-4 ring-white/80 transition group-hover:scale-[1.04]`}>
                        <div className="flex h-full w-full items-center justify-center rounded-xl bg-white/90 p-2">
                          {item.icon ? (
                            <img src={item.icon} alt="" className="h-full w-full object-contain" />
                          ) : (
                            <span className="text-xl font-black text-[#1E3557]">AZ</span>
                          )}
                        </div>
                      </div>
                      <span className={`rounded-full bg-white/80 px-3 py-1 text-[10px] font-black uppercase tracking-[0.18em] ${theme.text} shadow-sm`}>
                        {item.category || "Vedic"}
                      </span>
                    </div>

                    <h3 className="mt-6 text-lg font-black leading-6 text-[#1E3557]">
                      {item.title}
                    </h3>

                    <p className="mt-3 line-clamp-3 text-sm leading-6 text-slate-600">
                      {item.summary}
                    </p>

                    <div className="mt-auto flex justify-center pt-6">
                      <button
                        onClick={() => {
                          notify(`${item.title} selected`);
                          navigate(item.to);
                        }}
                        className={`group/btn flex w-full items-center justify-between rounded-full border border-white/80 bg-white/85 px-4 py-3 text-xs font-black ${theme.text} shadow-sm transition hover:bg-[#1E3557] hover:text-white`}
                      >
                        <span>{t("premium.open")}</span>
                        <span className="flex h-8 w-8 items-center justify-center rounded-full bg-white text-[#1E3557] shadow-sm transition group-hover/btn:translate-x-0.5">
                          →
                        </span>
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
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
