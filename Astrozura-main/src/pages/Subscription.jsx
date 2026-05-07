import React, { useEffect, useRef, useState } from "react";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";

import { Calendar, FileText, Star, BadgePercent } from "lucide-react";

import sub from "../assets/sub.png";
import sub1 from "../assets/sub1.png";
import sub2 from "../assets/sub2.png";
import sub3 from "../assets/sub3.png";
import sub4 from "../assets/sub4.png";
import a1 from "../assets/a1.png";
import a2 from "../assets/a2.png";
import a3 from "../assets/a3.png";

const API_BASE = import.meta.env.VITE_API_BASE_URL || "http://localhost:8000/api";

export default function CosmicSection() {
  const pricingRef = useRef(null);
  const benefitsRef = useRef(null);
  const [msg, setMsg] = useState({ text: "", isError: false });
  const [activeBtn, setActiveBtn] = useState("pricing");
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [subscribing, setSubscribing] = useState(null); // plan id being subscribed

  // Fetch plans from API
  useEffect(() => {
    fetch(`${API_BASE}/subscriptions/plans`)
      .then((r) => r.json())
      .then((data) => {
        if (data.success && data.plans) setPlans(data.plans);
      })
      .catch(() => {
        // If API fails, use fallback plans
        setPlans([
          { id: 1, name: "Scholar",  price: 19,  is_popular: false, features: ["Daily Horoscopes", "Basic Birth Chart", "Weekly Transit Alerts", "Email Support"] },
          { id: 2, name: "Mystic",   price: 49,  is_popular: true,  features: ["Everything in Scholar", "Detailed Reports", "Monthly Predictions", "Priority Email Support", "Exclusive Content Access"] },
          { id: 3, name: "Sage",     price: 149, is_popular: false, features: ["Everything in Mystic", "1-on-1 Consultation", "Astrologer Guidance", "Annual Forecast Reports", "VIP Early Access"] },
        ]);
      })
      .finally(() => setLoading(false));
  }, []);

  const showToast = (text, isError = false) => {
    setMsg({ text, isError });
    setTimeout(() => setMsg({ text: "", isError: false }), 3000);
  };

  const handleSubscribe = async (plan) => {
    setSubscribing(plan.id);
    try {
      const token = localStorage.getItem("auth_token");
      const user  = JSON.parse(localStorage.getItem("user") || "{}");

      const res = await fetch(`${API_BASE}/subscriptions/subscribe`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: JSON.stringify({
          plan_id:    plan.id,
          user_name:  user.name  || null,
          user_email: user.email || null,
        }),
      });

      const data = await res.json();
      if (res.ok && data.success) {
        showToast(`Subscribed to ${plan.name} plan.`);
      } else {
        showToast(data.message || "Subscription failed. Try again.", true);
      }
    } catch {
      showToast("Network error. Please check connection.", true);
    } finally {
      setSubscribing(null);
    }
  };

  const handleClick = (type) => {
    setActiveBtn(type);
    const targetRef = type === "pricing" ? pricingRef : benefitsRef;
    targetRef.current?.scrollIntoView({ behavior: "smooth", block: "start" });
  };

  return (
    <>
      <Navbar />

      {/* Toast */}
      {msg.text && (
      <div className={`fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-full px-6 py-3 text-center font-medium text-white shadow-xl animate-bounce
          ${msg.isError ? "bg-red-500" : "bg-[#c79926]"}`}>
          {msg.text}
        </div>
      )}

      {/* HERO SECTION */}
      <div className="bg-[#f8fafc] px-4 py-16">
        <div className="max-w-7xl mx-auto grid md:grid-cols-2 gap-10 items-center">

          <div className="text-center md:text-left">
            <p className="text-xs bg-[#f7f6c7] text-[#184070] inline-block px-3 py-1 rounded-full mb-4">
              Cosmic Membership
            </p>

            <h1 className="text-3xl sm:text-4xl md:text-5xl font-extrabold leading-tight">
              Subscribe to <br />
              <span className="text-[#23205b]">Cosmic Wisdom</span>
            </h1>

            <p className="text-[#4974a4] mt-4 max-w-md mx-auto md:mx-0">
              Gain exclusive access to personalized celestial insights,
              deep-dive reports, and priority consultations with our master astrologers.
            </p>

            <div className="flex flex-col sm:flex-row gap-3 mt-6 justify-center md:justify-start">
              <button
                onClick={() => handleClick("pricing")}
                className={`px-6 py-2 rounded-full font-semibold transition shadow-md
                ${activeBtn === "pricing" ? "bg-[#d8b14a] text-white" : "bg-white border"}`}
              >
                View Pricing Plans
              </button>
              <button
                onClick={() => handleClick("benefits")}
                className={`px-6 py-2 rounded-full font-semibold transition shadow-md
                ${activeBtn === "benefits" ? "bg-[#c79926] text-white" : "bg-white border"}`}
              >
                Learn Benefits
              </button>
            </div>

            <div className="flex items-center gap-3 mt-6 justify-center md:justify-start">
              <div className="flex -space-x-2">
                {[sub1, sub2, sub3, sub4].map((img, i) => (
                  <img key={i} src={img} alt="user" className="w-8 h-8 rounded-full border-2 border-white" />
                ))}
              </div>
              <p className="text-xs text-gray-500">joined by 1,200+ cosmic seekers</p>
            </div>
          </div>

          <div className="flex justify-center">
            <div className="bg-white p-4 rounded-2xl shadow-lg w-full max-w-sm">
              <img src={sub} alt="banner" className="rounded-xl h-56 w-full object-cover" />
              <div className="bg-gray-50 mt-4 p-3 rounded-xl">
                <p className="text-xs text-[#4974a4]">Next Major Transit</p>
                <p className="text-sm font-semibold">Jupiter enters Gemini - May 25, 2025</p>
              </div>
            </div>
          </div>

        </div>
      </div>

      {/* PRICING PLANS (Dynamic from API) */}
      <div ref={pricingRef} className="bg-[#f8fafc] py-12 md:py-16 px-4 text-center border-t border-gray-50">
        <h2 className="text-2xl md:text-3xl font-black text-[#184070]">Choose Your Path to Insight</h2>
        <p className="text-[#5e6bcd] text-sm mt-2">
          Select the tier that aligns with your spiritual journey. No hidden fees, cancel anytime.
        </p>

        {loading ? (
          <p className="text-gray-400 mt-10">Loading plans...</p>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6 mt-10 max-w-6xl mx-auto">
            {plans.map((plan) => {
              const features = Array.isArray(plan.features)
                ? plan.features
                : JSON.parse(plan.features || "[]");

              return (
                <div
                  key={plan.id}
                  className={`bg-white p-6 sm:p-8 rounded-3xl shadow-xl transition-all duration-300 hover:-translate-y-2 border border-gray-100
                    ${plan.is_popular ? "ring-4 ring-[#f7f6c7] ring-offset-4 ring-offset-[#f8fafc] relative z-10" : ""}`}
                >
                  {plan.is_popular && (
                    <p className="text-xs bg-[#23205b] text-white inline-block px-3 py-1 rounded-full mb-2">Most Popular</p>
                  )}
                  <h3 className="text-lg font-semibold">{plan.name}</h3>
                  <p className="text-3xl font-bold my-4">Rs {plan.price}/month</p>

                  <ul className="text-sm text-gray-600 space-y-2 mb-6">
                    {features.map((f, idx) => (
                      <li key={idx}>- {f}</li>
                    ))}
                  </ul>

                  <button
                    onClick={() => handleSubscribe(plan)}
                    disabled={subscribing === plan.id}
                    className={`w-full py-2 rounded-full font-semibold transition
                      ${subscribing === plan.id
                        ? "bg-gray-300 cursor-not-allowed text-gray-500"
                        : "bg-[#d8b14a] text-white hover:opacity-90"}`}
                  >
                    {subscribing === plan.id ? "Processing..." : "Subscribe Now"}
                  </button>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* BENEFITS */}
      <div ref={benefitsRef} className="bg-[#f8fafc] py-16 px-4 text-center">
        <h2 className="text-2xl md:text-3xl font-bold">The Wisdom You Gain</h2>
        <p className="text-[#184070] text-sm mt-2">
          Beyond predictions, we provide the tools for self-discovery and spiritual growth.
        </p>
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-6 mt-10 max-w-6xl mx-auto">
          {[
            { title: "Daily Horoscopes",        icon: <Calendar      size={28} className="text-[#4974a4] mx-auto mb-3" /> },
            { title: "Exclusive Reports",        icon: <FileText      size={28} className="text-[#4974a4] mx-auto mb-3" /> },
            { title: "Priority Consultations",  icon: <Star          size={28} className="text-[#4974a4] mx-auto mb-3" /> },
            { title: "Member Discounts",         icon: <BadgePercent  size={28} className="text-[#4974a4] mx-auto mb-3" /> },
          ].map((item, i) => (
            <div key={i} className="bg-white p-6 rounded-xl shadow-md hover:shadow-lg transition text-center hover:scale-105">
              {item.icon}
              <p className="font-semibold">{item.title}</p>
              <p className="text-xs text-[#5e6bcd] mt-2">Personalized insights to guide your journey.</p>
            </div>
          ))}
        </div>
      </div>

      {/* PAID FEATURES GRID */}
      <div className="bg-[#f8fafc] py-16 px-4 text-center">
        <h2 className="text-2xl md:text-3xl font-bold mb-4">Paid Features Included</h2>
        <p className="text-[#5e6bcd] text-sm mb-10">
          A comprehensive list of everything you unlock with our premium reports.
        </p>
        <div className="max-w-5xl mx-auto grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-y-4 gap-x-8 text-left">
           {[ 
             "General Birth Details", 
             "D1 to D16 Chart", 
             "Rashiphal + Nakshatraphal", 
             "Strength / Weakness", 
             "Career", 
             "Love & Relationship", 
             "All Mahadasha Detailed Prediction", 
             "All Planetary Position Detailed Prediction", 
             "All yoga or Dosh", 
             "Numerology Details", 
             "Vedic Remedy", 
             "Sadesati Report", 
             "Lal Kitab Remedy" 
           ].map((feat, i) => (
             <div key={i} className="flex items-center gap-3 bg-white p-3.5 rounded-xl shadow-sm border border-gray-100/80 hover:border-[#D4A73C]/30 hover:shadow-md transition">
                <div className="w-6 h-6 rounded-full bg-[#fdfaf2] flex items-center justify-center text-[#D4A73C] shrink-0 border border-[#f3e7d3]">✓</div>
                <span className="text-sm font-semibold text-[#2B2B2B]">{feat}</span>
             </div>
           ))}
        </div>

        {/* TESTIMONIALS */}
        <h2 className="text-2xl md:text-3xl font-bold mt-16 mb-4">Voices of the Stars</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-6xl mx-auto mt-6 text-left">
          {[
            { img: a1, name: "Elena Rodriguez", role: "Astrology Enthusiast",  msg: "The Sage plan changed how I plan my business launches. The transit reports are really accurate and helped me navigate a rough Q3 with grace." },
            { img: a2, name: "Marcus Chen",     role: "Freelance Designer",     msg: "I've used many apps, but Cosmic Wisdom is different! It's presented in a real astrological framework but explained for modern life. Worth every penny!" },
            { img: a3, name: "Sarah Jenkins",   role: "Teacher of Astrology",   msg: "The monthly workshops included in the Mystic plan are incredible. I've learned more in three months than from years of self-study." },
          ].map((user, i) => (
            <div key={i} className="bg-white p-6 rounded-xl shadow-md">
              <p className="text-sm text-gray-700 mb-4">"{user.msg}"</p>
              <div className="flex items-center gap-3 mt-2">
                <img src={user.img} alt={user.name} className="w-10 h-10 rounded-full object-cover" />
                <div>
                  <p className="font-semibold">{user.name}</p>
                  <p className="text-xs text-gray-400">{user.role}</p>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* FAQ */}
        <h2 className="text-2xl md:text-3xl font-bold mt-16 mb-4">Frequently Asked Questions</h2>
        <div className="max-w-3xl mx-auto mt-6 text-left space-y-4">
          {[
            { q: "Can I cancel my subscription anytime?",           a: "Yes, you can cancel your subscription at any time through your account settings. You will continue to have access to your features until the end of your current billing cycle." },
            { q: "What's the difference between Mystic and Sage?", a: "Mystic offers detailed reports and priority support, while Sage includes 1-on-1 consultations and full annual forecast reports." },
            { q: "Are the horoscopes generic or personal?",          a: "All horoscopes and reports are personalized based on your birth chart and current planetary transits." },
          ].map((item, i) => (
            <details key={i} className="bg-white p-4 rounded-xl shadow-md cursor-pointer">
              <summary className="font-semibold">{item.q}</summary>
              <p className="text-sm text-gray-600 mt-2">{item.a}</p>
            </details>
          ))}
        </div>
      </div>

      <Footer />
    </>
  );
}
