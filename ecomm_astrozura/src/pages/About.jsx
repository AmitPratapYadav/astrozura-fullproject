import { useState } from "react";
import icon4 from "../assets/icon4.png";
import Footer from "../components/Footer";

export default function AboutAstrozura() {
  const [activeBtn, setActiveBtn] = useState("explore");
  const [active, setActive] = useState("consult");

  return (
    <>
    <div className="w-full">

      {/* HERO */}
      <div
        className="text-center py-20 px-4 text-white"
        style={{ background: "#1E3557" }}>
        <div className="flex justify-center mb-4">
          <img src={icon4} className="w-12 h-12" />
        </div>
        <h1 className="text-3xl sm:text-4xl font-bold mb-3 text-[#f3d38d]">
          About Us – Astrozura
        </h1>
        <p className="text-sm max-w-xl mx-auto text-gray-200 mb-6">
          Welcome to Astrozura, your trusted online destination for authentic spiritual, religious, and astrology-related products. We are dedicated to bringing positivity, peace, and spiritual well-being into your life through carefully selected and high-quality products.
        </p>
        <div className="flex justify-center gap-4 flex-wrap">
          <button
            onClick={() => setActiveBtn("explore")}
            className="px-6 py-2 rounded-full font-medium transition"
            style={{
              background: activeBtn === "explore" ? "#1E3557" : "#fff",
              color: activeBtn === "explore" ? "#fff" : "#000",
            }} >
            Explore Your Card
          </button>
          <button
            onClick={() => setActiveBtn("learn")}
            className="px-6 py-2 rounded-full font-medium transition"
            style={{
              background: activeBtn === "learn" ? "#1E3557" : "#fff",
              color: activeBtn === "learn" ? "#fff" : "#000",}} >
            Learn More
          </button>
        </div>
      </div>
      {/* ABOUT */}
      <div className="grid md:grid-cols-2 gap-10 px-6 sm:px-10 md:px-20 py-10 sm:py-16 items-center bg-[#f8f7fb]">
        <div>
          <p className="text-xs text-[#1E3557] font-semibold mb-2">
            OUR OBJECTIVE
          </p>

          <h2 className="text-2xl md:text-3xl font-bold mb-4 text-[#1E3557]">
            Fulfilling Your Spiritual Requirements
          </h2>

          <p className="text-[#1E3557] text-sm mb-4">
            Astrozura offers you high-quality products that cater to your religious and spiritual needs.
          </p>

          <p className="text-[#1E3557] text-sm mb-6">
            Our objective is to provide you with authentic products that bring happiness into your life and fulfill your spiritual requirements.
          </p>

          <div className="flex flex-wrap gap-6 sm:gap-10">
            <div>
              <h3 className="text-[#1E3557] font-bold text-lg sm:text-xl">15K+</h3>
              <p className="text-[10px] sm:text-xs text-[#1E3557]">Readings Completed</p>
            </div>

            <div>
              <h3 className="text-[#1E3557] font-bold text-lg sm:text-xl">98%</h3>
              <p className="text-[10px] sm:text-xs text-[#1E3557]">Accuracy Rate</p>
            </div>

            <div>
              <h3 className="text-[#1E3557] font-bold text-lg sm:text-xl">24/7</h3>
              <p className="text-[10px] sm:text-xs text-[#1E3557]">Support</p>
            </div>
          </div>
        </div>

        <div>
          <div className="w-full h-[300px] bg-[#d8b14a] rounded-2xl flex items-center justify-center text-[#1E3557] font-bold shadow-lg">
              AstroZura Vision
          </div>
        </div>
      </div>

      {/* PRINCIPLES */}
      <div className="py-12 sm:py-16 px-6 sm:px-10 md:px-20 text-center bg-[#f8f7fb]">
        <p className="text-xs text-[#d8b14a] font-semibold mb-2">
          MISSION & VALUES
        </p>

        <h2 className="text-2xl md:text-3xl font-bold mb-10 text-[#1E3557]">
          At Astrozura, we believe spirituality is a way of life that creates balance, confidence, and inner peace.
        </h2>

        <div className="grid md:grid-cols-3 gap-6">
          <div className="bg-[#e9e6f8] p-6 rounded-xl">
            <div className="w-10 h-10 mx-auto mb-3 bg-[#c7926a] flex items-center justify-center rounded-full text-white text-xl">🎯</div>
            <h3 className="font-semibold mb-2">Our Mission</h3>
            <p className="text-sm text-[#1E3557]">
              To provide genuine and trusted products that support your spiritual journey with authenticity and care.
            </p>
          </div>

          <div className="bg-[#e9e6f8] p-6 rounded-xl">
            <div className="w-10 h-10 mx-auto mb-3 bg-[#c7926a] flex items-center justify-center rounded-full text-white text-xl">🛍️</div>
            <h3 className="font-semibold mb-2">Wide Range of Products</h3>
            <p className="text-sm text-[#1E3557]">
              Offering Bracelets, Rudraksha, Gemstones, Healing Crystals, Yantras, Puja Items, Malas, and more.
            </p>
          </div>

          <div className="bg-[#e9e6f8] p-6 rounded-xl">
            <div className="w-10 h-10 mx-auto mb-3 bg-[#c7926a] flex items-center justify-center rounded-full text-white text-xl">✨</div>
            <h3 className="font-semibold mb-2">Quality & Purity</h3>
            <p className="text-sm text-[#1E3557]">
              Every product is selected with attention to quality, purity, and customer satisfaction for a reliable experience.
            </p>
          </div>
        </div>
      </div>

      {/* WHY TRUST */}
      <div className="bg-[#1a1446] text-white py-12 sm:py-16 px-6 sm:px-10 md:px-20">
  
  {/* HEADING */}
  <h2 className="text-2xl md:text-3xl font-bold mb-4 text-[#c7926a]">
    Why Choose Astrozura?
  </h2>

  <p className="text-sm text-white max-w-xl mb-10">
    Our goal is to create a trusted platform where customers can easily explore spiritual products while enjoying a smooth and secure online shopping experience.
  </p>

  <div className="grid md:grid-cols-2 gap-10 items-start">
    <div className="space-y-4">

      <div className="flex items-start gap-3 bg-[#1E3557] p-4 rounded-xl border border-[#1E3557]">
        <div className="w-6 h-6 mt-1 flex items-center justify-center bg-[#c7926a] rounded-full text-xs text-white">✓</div>
        <div>
          <p className="text-sm font-semibold">
            Authentic & Premium Quality
          </p>
          <p className="text-xs text-white">
            Carefully selected spiritual products ensuring authenticity.
          </p>
        </div>
      </div>

      {/* PRIVACY */}
      <div className="flex items-start gap-3 bg-[#1E3557] p-4 rounded-xl border border-[#1E3557]">
        <div className="w-6 h-6 mt-1 flex items-center justify-center bg-[#c7926a] rounded-full text-xs text-white">💎</div>
        <div>
          <p className="text-sm font-semibold">
            Trusted Collections
          </p>
          <p className="text-xs text-white">
            Genuine gemstones and Rudraksha collections for your spiritual needs.
          </p>
        </div>
      </div>
    </div>
    {/* RIGHT SIDE */}
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
      <div className="flex gap-3 items-start">
        <div className="w-5 h-5 mt-1 flex items-center justify-center text-[#c7926a] font-bold text-lg">🔒</div>
        <div>
          <p className="text-sm font-semibold">Secure Shopping</p>
          <p className="text-xs text-white">
            Secure and user-friendly online shopping experience.
          </p>
        </div>
      </div>

      <div className="flex gap-3 items-start">
        <div className="w-5 h-5 mt-1 flex items-center justify-center text-[#c7926a] font-bold text-lg">🏷️</div>
        <div>
          <p className="text-sm font-semibold">Affordable Pricing</p>
          <p className="text-xs text-white">
            Best prices for authentic and high-quality products.
          </p>
        </div>
      </div>
      <div className="flex gap-3 items-start">
        <div className="w-5 h-5 mt-1 flex items-center justify-center text-[#c7926a] font-bold text-lg">🤝</div>
        <div>
          <p className="text-sm font-semibold">Reliable Service</p>
          <p className="text-xs text-white">
            Trustworthy delivery and excellent product care.
          </p>
        </div>
      </div>

      <div className="flex gap-3 items-start">
        <div className="w-5 h-5 mt-1 flex items-center justify-center text-[#c7926a] font-bold text-lg">🎧</div>
        <div>
          <p className="text-sm font-semibold">Dedicated Support</p>
          <p className="text-xs text-white">
            Dedicated customer support team at your service.
          </p>
        </div>
      </div>
    </div>
  </div>
</div>
      <div className="bg-[#f8f7fb] py-12 sm:py-16 px-6 sm:px-10 md:px-20 text-center">
        <p className="text-xs text-[#1E3557] mb-2">OUR EXPERTS</p>
        <h2 className="text-2xl md:text-3xl font-bold mb-12 text-[#1E3557]">
          The Team Dedicated to Your Spiritual Journey
        </h2>
        <div className="grid sm:grid-cols-2 md:grid-cols-4 gap-6">
          {[ 
            { name: "Seraphina Moon" },
            { name: "Caelum Thorne" },
            { name: "Lyra Vance" },
            { name: "Orion Frost" }
          ].map((item, i) => (
            <div key={i} className="bg-white p-6 rounded-xl shadow-sm">
              <div className="w-16 h-16 mx-auto rounded-full mb-3 bg-[#c7926a] flex items-center justify-center text-white text-2xl font-bold">
                {item.name.charAt(0)}
              </div>
              <h3 className="font-semibold">{item.name}</h3>
              <p className="text-xs text-[#d8b14a] mb-2">ASTRO EXPERT</p>
              <p className="text-xs text-[#1E3557]">
                Guiding you through your cosmic journey with deep insight.
              </p>
            </div>
          ))}
        </div>
      </div>
      <div className="bg-[#f8f7fb] px-6 md:px-20 pb-20">
        <div className="bg-gradient-to-r from-[#1E3557] to-[#1E3557] text-white rounded-2xl py-12 text-center">
          <img src={icon4} className="w-8 mx-auto mb-4" />
          <h2 className="text-2xl md:text-3xl font-bold mb-3">
            Thank you for choosing Astrozura
          </h2>
          <p className="text-sm mb-6">
            We are honored to be a part of your spiritual journey.
          </p>
          <div className="flex justify-center gap-4">
            <button onClick={() => setActive("consult")}
     className="px-6 py-2 rounded-full transition"
         style={{
        background: active === "consult" ? "#D4A73C" : "#fff",
          color: "#000", }}>
        Get Consultation
        </button>
      <button onClick={() => setActive("services")}
       className="px-6 py-2 rounded-full transition"
         style={{
    background: active === "services" ? "#D4A73C" : "#fff",
    color: "#000",
            }}>
      View Services
          </button>
          </div>
        </div>
      </div>

    </div>
    <Footer/>
    </>
  );
}