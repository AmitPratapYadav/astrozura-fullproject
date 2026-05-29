import React, { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Calculator, HeartHandshake, ScrollText, Star } from "lucide-react";
import {
  TbZodiacAquarius,
  TbZodiacAries,
  TbZodiacCancer,
  TbZodiacCapricorn,
  TbZodiacGemini,
  TbZodiacLeo,
  TbZodiacLibra,
  TbZodiacPisces,
  TbZodiacSagittarius,
  TbZodiacScorpio,
  TbZodiacTaurus,
  TbZodiacVirgo,
} from "react-icons/tb";
import { getDailyHoroscope, getMonthlyHoroscope } from "../api/prokeralaApi";
import { serviceCatalog } from "../data/serviceCatalog";

const zodiac = [
  { sign: "aries", id: "Aries", range: "March 21 - April 19", luckyColor: "Gold", luckyNumber: "08", icon: <TbZodiacAries size={28} strokeWidth={1.5} className="text-current" /> },
  { sign: "taurus", id: "Taurus", range: "April 20 - May 20", luckyColor: "Forest Green", luckyNumber: "06", icon: <TbZodiacTaurus size={28} strokeWidth={1.5} className="text-current" /> },
  { sign: "gemini", id: "Gemini", range: "May 21 - June 20", luckyColor: "Sky Blue", luckyNumber: "05", icon: <TbZodiacGemini size={28} strokeWidth={1.5} className="text-current" /> },
  { sign: "cancer", id: "Cancer", range: "June 21 - July 22", luckyColor: "Silver", luckyNumber: "02", icon: <TbZodiacCancer size={28} strokeWidth={1.5} className="text-current" /> },
  { sign: "leo", id: "Leo", range: "July 23 - August 22", luckyColor: "Amber", luckyNumber: "01", icon: <TbZodiacLeo size={28} strokeWidth={1.5} className="text-current" /> },
  { sign: "virgo", id: "Virgo", range: "August 23 - September 22", luckyColor: "Olive", luckyNumber: "07", icon: <TbZodiacVirgo size={28} strokeWidth={1.5} className="text-current" /> },
  { sign: "libra", id: "Libra", range: "September 23 - October 22", luckyColor: "Blush Pink", luckyNumber: "09", icon: <TbZodiacLibra size={28} strokeWidth={1.5} className="text-current" /> },
  { sign: "scorpio", id: "Scorpio", range: "October 23 - November 21", luckyColor: "Crimson", luckyNumber: "04", icon: <TbZodiacScorpio size={28} strokeWidth={1.5} className="text-current" /> },
  { sign: "sagittarius", id: "Sagittarius", range: "November 22 - December 21", luckyColor: "Royal Purple", luckyNumber: "03", icon: <TbZodiacSagittarius size={28} strokeWidth={1.5} className="text-current" /> },
  { sign: "capricorn", id: "Capricorn", range: "December 22 - January 19", luckyColor: "Steel Blue", luckyNumber: "10", icon: <TbZodiacCapricorn size={28} strokeWidth={1.5} className="text-current" /> },
  { sign: "aquarius", id: "Aquarius", range: "January 20 - February 18", luckyColor: "Electric Blue", luckyNumber: "11", icon: <TbZodiacAquarius size={28} strokeWidth={1.5} className="text-current" /> },
  { sign: "pisces", id: "Pisces", range: "February 19 - March 20", luckyColor: "Sea Green", luckyNumber: "12", icon: <TbZodiacPisces size={28} strokeWidth={1.5} className="text-current" /> },
];

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
    const iconMap = {
      Reports: <ScrollText size={22} strokeWidth={1.7} className="text-white" />,
      Calculators: <Calculator size={22} strokeWidth={1.7} className="text-white" />,
      "Marriage Matching": <HeartHandshake size={22} strokeWidth={1.7} className="text-white" />,
    };
    const priceMap = {
      "Marriage Matching": "Rs 29.99",
      Reports: "Rs 34.99",
      Calculators: "Rs 24.99",
    };

    return serviceCatalog
      .filter((item) => eligibleCategories.has(item.category))
      .slice(0, 8)
      .map((item) => ({
        title: item.title,
        summary: item.summary,
        to: item.ctaTo,
        price: priceMap[item.category] || "Rs 24.99",
        icon: iconMap[item.category] || <Star size={22} strokeWidth={1.7} className="text-white" />,
        badge: item.category,
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
          setHoroscopeError(response?.message || t("premium.loading_error"));
        }
      } catch (error) {
        setHoroscope(null);
        setHoroscopeError(error?.response?.data?.message || t("premium.loading_error"));
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
    { label: "Love & Relationship", value: horoscope?.scores?.love ?? 0 },
    { label: "Career & Wealth", value: horoscope?.scores?.career ?? 0 },
    { label: "Health & Wellness", value: horoscope?.scores?.health ?? 0 },
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
            Astrology Forecast
          </h2>
          <div className="flex justify-center items-center gap-4 text-sm font-bold mb-8">
            <button
              onClick={() => setActivePeriod("daily")}
              className={`transition-colors ${activePeriod === "daily" ? "text-[#D4A73C] underline underline-offset-8" : "text-gray-400 hover:text-[#2B2B2B]"}`}
            >
              Daily
            </button>
            <div className="w-1 h-1 bg-gray-300 rounded-full"></div>
            <button
              onClick={() => setActivePeriod("monthly")}
              className={`transition-colors ${activePeriod === "monthly" ? "text-[#D4A73C] underline underline-offset-8" : "text-gray-400 hover:text-[#2B2B2B]"}`}
            >
              Monthly
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
                  <span className="text-[28px]">
                    {activeSign === z.sign ? React.cloneElement(z.icon, { color: 'white' }) : z.icon}
                  </span>
                </div>
                <p className={`mt-2 font-bold text-[11px] md:text-xs capitalize transition-colors ${activeSign === z.sign ? 'text-[#C05D17]' : 'text-[#2B2B2B]'}`}>
                  {z.id}
                </p>
              </div>
            ))}
          </div>

          <div className="bg-white rounded-[2rem] shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-[#F0F0F0] mt-4 p-4 md:p-6 flex flex-col lg:flex-row gap-6 md:gap-10 w-full max-w-6xl mx-auto">
            
            {/* Left Card */}
            <div className="bg-[#FCF9F2] rounded-2xl p-6 lg:p-8 w-full lg:w-[280px] text-center border border-[#F6EFE2] shrink-0">
              <div className="w-[100px] h-[100px] mx-auto bg-[#F1DEBE] rounded-full flex items-center justify-center text-[#B58C36] mb-5 border border-[#E9D1A7]">
                {React.cloneElement(activeSignMeta.icon, { size: 50, strokeWidth: 1.5 })}
              </div>

              <h3 className="font-bold text-[#2B2B2B] text-xl mb-1 capitalize">
                {activeSignMeta.id}
              </h3>
              <p className="text-[11px] text-gray-400 mb-8 font-medium">
                {activeSignMeta.range}
              </p>

              <div className="grid gap-3 mb-8 text-xs">
                <div className="flex justify-between items-center text-gray-500">
                  <span>Lucky Color</span>
                  <span className="font-bold text-[#2B2B2B]">{activeSignMeta.luckyColor}</span>
                </div>
                <div className="flex justify-between items-center text-gray-500">
                  <span>Lucky Number</span>
                  <span className="font-bold text-[#2B2B2B]">{activeSignMeta.luckyNumber}</span>
                </div>
              </div>

              <div className="bg-white rounded-[1rem] px-4 py-3 text-left border border-[#F2EFE8]">
                <p className="text-[9px] uppercase text-gray-300 font-bold tracking-widest mb-1.5">
                  HOROSCOPE DATE
                </p>
                <p className="text-xs font-bold text-[#1E3557]">
                  {loadingHoroscope ? "Loading..." : (horoscope?.display_date || "Today")}
                </p>
              </div>
            </div>

            {/* Right Card / Forecast */}
            <div className="flex-1 lg:py-6 relative">
              <div className="flex items-center justify-between border-b border-gray-100 pb-4 mb-6">
                <h3 className="text-lg font-bold text-[#2B2B2B]">
                  Today's Forecast
                </h3>
                <span className="bg-[#FAEED6] text-[#D4A73C] text-[11px] font-bold px-3 py-1.5 rounded-md">
                  Daily Reading
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
                    {horoscope?.daily_prediction?.personal || "Your cosmic path is aligning for a day of discovery. Use this positive energy to seek new opportunities."}
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
                        {horoscope?.daily_prediction?.profession || "Dynamic shifts in work environment are expected."}
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
                        {horoscope?.daily_prediction?.emotions || "A day to focus on inner peace and clarity."}
                      </p>
                    </div>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>

        <div className="mt-14 md:mt-20">
          <div className="mb-8 flex flex-wrap items-end justify-between gap-3">
            <div>
              <h2 className="text-xl font-bold text-[#1A1A1A] md:text-2xl">
                Premium Services
              </h2>
              <p className="mt-1 text-xs text-gray-400">
                Explore paid-ready reports and calculators from Astro Zura's core service stack.
              </p>
            </div>

            <button
              onClick={() => navigate("/services")}
              className="text-xs font-semibold text-[#c7926a] hover:underline"
            >
              {t("premium.view_all")}
            </button>
          </div>

          <div className="grid grid-cols-2 gap-3 sm:gap-4 md:grid-cols-3 lg:grid-cols-4">
            {premiumServices.map((item) => (
              <div
                key={item.title}
                className="rounded-xl border border-[#F3E7D3] bg-[#FFF8ED] p-3 text-center shadow-sm transition hover:-translate-y-0.5 hover:shadow-md sm:p-4"
              >
                <div className="mx-auto mb-3 inline-flex max-w-full rounded-full bg-[#F3E7D3] px-2 py-1 text-[8px] font-bold uppercase tracking-[0.14em] text-[#B88332] sm:text-[9px]">
                  <span className="truncate">{item.badge}</span>
                </div>

                <div className="mx-auto mb-3 flex h-11 w-11 items-center justify-center rounded-xl bg-[#1E3557] shadow-sm sm:h-12 sm:w-12">
                  {item.icon}
                </div>

                <h3 className="min-h-[40px] text-sm font-bold leading-5 text-[#1E3557] sm:text-base">
                  {item.title}
                </h3>

                <p className="mt-2 hidden min-h-[48px] text-[11px] leading-4 text-gray-500 sm:block">
                  {item.summary}
                </p>

                <div className="mt-4 flex flex-col items-center gap-2 sm:flex-row sm:justify-between">
                  <p className="text-xs font-bold text-[#1E3557] sm:text-sm">
                    {item.price}
                  </p>

                  <button
                    onClick={() => {
                      notify(`${item.title} selected`);
                      navigate(item.to);
                    }}
                    className="w-full rounded-full border border-[#1E3557] px-3 py-1.5 text-[10px] font-medium text-[#1E3557] transition hover:bg-[#1E3557] hover:text-white sm:w-auto sm:text-[11px]"
                  >
                    {t("premium.book_now")}
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
