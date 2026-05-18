import React, { useState } from "react";
import { useSearchParams } from "react-router-dom";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { FaArrowRight, FaBriefcase, FaHeartbeat, FaHeart, FaMagic } from "react-icons/fa";
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
import { getDailyHoroscope } from "../api/prokeralaApi";

const zodiacs = [
  { name: "Aries", Icon: TbZodiacAries, date: "Mar 21 - Apr 19", element: "Fire", ruler: "Mars", tone: "from-[#f97316] to-[#dc2626]", surface: "bg-[#fff6ed]", accent: "text-[#c2410c]" },
  { name: "Taurus", Icon: TbZodiacTaurus, date: "Apr 20 - May 20", element: "Earth", ruler: "Venus", tone: "from-[#84cc16] to-[#15803d]", surface: "bg-[#f4fbec]", accent: "text-[#3f7a14]" },
  { name: "Gemini", Icon: TbZodiacGemini, date: "May 21 - Jun 20", element: "Air", ruler: "Mercury", tone: "from-[#38bdf8] to-[#2563eb]", surface: "bg-[#eef8ff]", accent: "text-[#1d4ed8]" },
  { name: "Cancer", Icon: TbZodiacCancer, date: "Jun 21 - Jul 22", element: "Water", ruler: "Moon", tone: "from-[#22d3ee] to-[#0f766e]", surface: "bg-[#eefdfb]", accent: "text-[#0f766e]" },
  { name: "Leo", Icon: TbZodiacLeo, date: "Jul 23 - Aug 22", element: "Fire", ruler: "Sun", tone: "from-[#facc15] to-[#ea580c]", surface: "bg-[#fff9db]", accent: "text-[#b45309]" },
  { name: "Virgo", Icon: TbZodiacVirgo, date: "Aug 23 - Sep 22", element: "Earth", ruler: "Mercury", tone: "from-[#a3a866] to-[#64748b]", surface: "bg-[#f8f7ee]", accent: "text-[#5b621f]" },
  { name: "Libra", Icon: TbZodiacLibra, date: "Sep 23 - Oct 22", element: "Air", ruler: "Venus", tone: "from-[#f0abfc] to-[#7c3aed]", surface: "bg-[#fdf2ff]", accent: "text-[#7e22ce]" },
  { name: "Scorpio", Icon: TbZodiacScorpio, date: "Oct 23 - Nov 21", element: "Water", ruler: "Pluto", tone: "from-[#fb7185] to-[#7f1d1d]", surface: "bg-[#fff1f2]", accent: "text-[#be123c]" },
  { name: "Sagittarius", Icon: TbZodiacSagittarius, date: "Nov 22 - Dec 21", element: "Fire", ruler: "Jupiter", tone: "from-[#f59e0b] to-[#a855f7]", surface: "bg-[#fff7ed]", accent: "text-[#9333ea]" },
  { name: "Capricorn", Icon: TbZodiacCapricorn, date: "Dec 22 - Jan 19", element: "Earth", ruler: "Saturn", tone: "from-[#94a3b8] to-[#334155]", surface: "bg-[#f8fafc]", accent: "text-[#334155]" },
  { name: "Aquarius", Icon: TbZodiacAquarius, date: "Jan 20 - Feb 18", element: "Air", ruler: "Uranus", tone: "from-[#60a5fa] to-[#4338ca]", surface: "bg-[#eff6ff]", accent: "text-[#3730a3]" },
  { name: "Pisces", Icon: TbZodiacPisces, date: "Feb 19 - Mar 20", element: "Water", ruler: "Neptune", tone: "from-[#2dd4bf] to-[#6366f1]", surface: "bg-[#f0fdfa]", accent: "text-[#0f766e]" },
];

export default function Rashifal() {
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

      setError(response?.message || "Unable to fetch horoscope right now.");
    } catch (fetchError) {
      console.error("Horoscope fetch error:", fetchError?.response?.data || fetchError.message);
      setError(fetchError?.response?.data?.message || "Unable to fetch horoscope right now.");
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
    <div className="bg-[#f8f9fa] min-h-screen flex flex-col font-sans">
      <Navbar />

      <section className="relative bg-[#1E3557] text-white py-20 px-4 md:px-8 text-center">
        <div className="absolute inset-0 opacity-10 border-b" style={{ backgroundImage: "radial-gradient(#D4A73C 1px, transparent 1px)", backgroundSize: "30px 30px" }}></div>
        <div className="relative max-w-4xl mx-auto">
          <span className="inline-block text-[#D4A73C] border border-[#D4A73C]/30 px-4 py-1.5 rounded-full font-bold uppercase mb-4 text-xs tracking-widest bg-[#D4A73C]/10">
            Daily Insights
          </span>
          <h1 className="text-3xl md:text-5xl font-extrabold mb-4">Daily Rashifal (Horoscope)</h1>
          <p className="text-gray-300 md:text-xl">Discover what the stars have aligned for you today. Select your zodiac sign below.</p>
        </div>
      </section>

      <div className="max-w-7xl mx-auto px-4 md:px-8 py-16 -mt-8 relative z-10 grid gap-8 flex-1 w-full">
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
                    {zodiac.element}
                  </span>
                  <span className="rounded-full bg-white/65 px-3 py-1 text-xs font-semibold text-slate-500 shadow-sm">
                    {zodiac.date}
                  </span>
                </div>

                <div className="relative mt-7 flex items-center gap-4">
                  <div className={`grid h-20 w-20 shrink-0 place-items-center rounded-2xl bg-gradient-to-br ${zodiac.tone} text-white shadow-lg shadow-slate-900/10 ring-4 ring-white/70`}>
                    {React.createElement(zodiac.Icon, { size: 54, strokeWidth: 1.6 })}
                  </div>
                  <div className="min-w-0">
                    <h3 className="text-2xl font-black text-[#1E3557]">{zodiac.name}</h3>
                    <p className={`mt-1 text-sm font-semibold ${zodiac.accent}`}>{zodiac.ruler}-ruled sign</p>
                  </div>
                </div>

                <div className="relative mt-7 flex items-center justify-between border-t border-white/70 pt-4">
                  <p className="text-sm font-medium text-slate-600">Open {activeTab} reading</p>
                  <span className={`grid h-9 w-9 place-items-center rounded-full bg-white ${zodiac.accent} shadow-sm transition group-hover:translate-x-1`}>
                    <FaArrowRight size={14} />
                  </span>
                </div>
              </button>
            ))}
          </div>
        ) : (
          <div className="bg-white rounded-3xl shadow-xl border border-gray-100 overflow-hidden max-w-5xl mx-auto w-full">
            <div className="bg-[#1E3557] p-8 text-center text-white relative">
              <button
                type="button"
                onClick={() => {
                  setSelectedSign(null);
                  setData(null);
                  setError("");
                }}
                className="absolute top-4 left-4 text-sm text-gray-300 hover:text-white px-3 py-1 border border-gray-500 rounded-lg"
              >
                Back
              </button>
              {React.createElement(selectedSign.Icon, { size: 72, strokeWidth: 1.4, className: "mx-auto mb-2 text-[#D4A73C]" })}
              <h2 className="text-3xl font-bold">{selectedSign.name} Horoscope</h2>
              <p className="text-gray-400 mt-1">{selectedSign.date}</p>
            </div>

            <div className="p-6 md:p-10">
              <div className="flex flex-wrap justify-center gap-2 mb-10 bg-gray-50 p-2 rounded-xl w-max mx-auto border">
                {["yesterday", "today", "tomorrow"].map((day) => (
                  <button
                    key={day}
                    type="button"
                    onClick={() => handleTabChange(day)}
                    className={`px-6 py-2 rounded-lg font-semibold capitalize transition ${activeTab === day ? "bg-[#1E3557] text-[#D4A73C] shadow-md" : "text-gray-600 hover:bg-gray-100"}`}
                  >
                    {day}
                  </button>
                ))}
              </div>

              {loading ? (
                <div className="flex flex-col items-center justify-center py-20">
                  <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#1E3557] mb-4"></div>
                  <p className="text-gray-500">Reading the stars...</p>
                </div>
              ) : error ? (
                <div className="text-center p-10 bg-red-50 rounded-2xl border border-red-100">
                  <p className="text-red-700">{error}</p>
                </div>
              ) : (
                <div className="space-y-8 animate-fadeIn">
                  {data?.daily_prediction ? (
                    <>
                      <div className="text-center text-sm text-gray-500">
                        Prediction date: {data.date || "Not provided"}
                      </div>
                      <div className="grid md:grid-cols-2 gap-6">
                        <div className="bg-indigo-50 p-6 rounded-2xl border border-indigo-100">
                          <h4 className="font-bold flex items-center gap-2 text-indigo-900 mb-2">
                            <FaMagic className="text-indigo-500" /> Personal Insights
                          </h4>
                          <p className="text-sm leading-relaxed text-indigo-800">{data.daily_prediction.personal || "No specific insights for this category."}</p>
                        </div>
                        <div className="bg-blue-50 p-6 rounded-2xl border border-blue-100">
                          <h4 className="font-bold flex items-center gap-2 text-blue-900 mb-2">
                            <FaBriefcase className="text-blue-500" /> Career & Professional
                          </h4>
                          <p className="text-sm leading-relaxed text-blue-800">{data.daily_prediction.profession || "No specific insights for this category."}</p>
                        </div>
                        <div className="bg-rose-50 p-6 rounded-2xl border border-rose-100">
                          <h4 className="font-bold flex items-center gap-2 text-rose-900 mb-2">
                            <FaHeartbeat className="text-rose-500" /> Health
                          </h4>
                          <p className="text-sm leading-relaxed text-rose-800">{data.daily_prediction.health || "No specific insights for this category."}</p>
                        </div>
                        <div className="bg-amber-50 p-6 rounded-2xl border border-amber-100">
                          <h4 className="font-bold flex items-center gap-2 text-amber-900 mb-2">
                            <FaHeart className="text-amber-500" /> Emotions & Luck
                          </h4>
                          <p className="text-sm leading-relaxed text-amber-800">{data.daily_prediction.emotions || "No specific insights for this category."}</p>
                        </div>
                      </div>
                    </>
                  ) : (
                    <div className="text-center p-10 bg-gray-50 rounded-2xl border">
                      <p className="text-gray-600">The stars are quiet today. Please try again later.</p>
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
