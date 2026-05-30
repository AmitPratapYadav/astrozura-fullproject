import { useState } from "react";
import { Link } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { Globe, Instagram, Phone, Youtube } from "lucide-react";
import vedic from "../assets/vedic-astrology.png";
import { useAuth } from "../context/AuthContext";

export default function Footer() {
  const { t } = useTranslation();
  const [email, setEmail] = useState("");
  const [msg, setMsg] = useState("");
  const { user } = useAuth();
  const currentYear = new Date().getFullYear();
  
  const servicesLinks = [
    { label: "View All Services", to: "/services" },
    { label: "Pooja Anusthan", to: "/rituals" },
    { label: "Horoscope", to: "/rashifal" },
    { label: "Matchmaking", to: "/matching" },
    { label: "Kundali Report", to: "/services/kundali-report" },
    { label: "Astrologers", to: "/astrologers" },
  ];

  const companyLinks = [
    { label: t("footer.about"), to: "/about-us" },
    { label: t("footer.contact"), to: "/contact-support" },
    { label: t("footer.privacy"), to: "/privacy-policy" },
    { label: t("footer.terms"), to: "/terms-and-conditions" },
  ];

  const socialLinks = [Globe, Instagram, Phone, Youtube];

  const handleSend = () => {
    if (!email) {
      setMsg(t("footer.notif_email"));
    } else {
      setMsg(t("footer.notif_success"));
      setEmail("");
    }
    setTimeout(() => setMsg(""), 2000);
  };

  return (
    <footer className="mt-2 bg-[#1E3557] text-white">
      {msg && (
      <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-lg bg-[#D4A73C] px-6 py-3 text-sm shadow">
          {msg}
        </div>
      )}

      <div className="mx-auto grid max-w-7xl gap-10 px-6 py-14 md:grid-cols-4">
        <div className="flex flex-col items-center text-center">
          <div className="flex h-16 items-center justify-center rounded-2xl bg-white px-6 shadow-md md:h-20">
            <img src={vedic} alt="AstroZura Logo" className="h-[150%] w-full object-contain" />
          </div>

          <p className="mt-5 max-w-xs text-sm leading-relaxed text-gray-300">
            {t("footer.tagline")}
          </p>

          <div className="mt-5 flex gap-3">
            {socialLinks.map((Icon, index) => (
              <div
                key={index}
                className="flex h-9 w-9 cursor-pointer items-center justify-center rounded-full bg-[#2C4870] transition hover:bg-[#D4A73C]"
              >
                <Icon size={16} />
              </div>
            ))}
          </div>
        </div>

        <div>
          <h3 className="mb-4 text-lg font-semibold">{t("footer.services")}</h3>
          <ul className="space-y-2 text-sm text-gray-300">
            {servicesLinks.map((item, idx) => (
              <li key={idx}>
                <Link to={item.to} className="transition hover:text-[#D4A73C]">
                  {item.label}
                </Link>
              </li>
            ))}
          </ul>
        </div>

        <div>
          <h3 className="mb-4 text-lg font-semibold">{t("footer.company")}</h3>
          <ul className="space-y-2 text-sm text-gray-300">
            {companyLinks.map((item, idx) => (
              <li key={idx}>
                <Link to={item.to} className="transition hover:text-[#D4A73C]">
                  {item.label}
                </Link>
              </li>
            ))}
          </ul>
        </div>

        <div>
          <h3 className="mb-4 text-lg font-semibold">{t("footer.newsletter")}</h3>
          <p className="mb-4 text-sm text-gray-300">
            {t("footer.newsletter_desc")}
          </p>

          <input
            type="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            placeholder={t("footer.email_placeholder")}
            className="mb-3 w-full rounded-md bg-[#223E63] px-4 py-3 text-sm text-white outline-none placeholder-gray-400 focus:ring-2 focus:ring-[#D4A73C]"
          />

          <button
            onClick={handleSend}
            className="w-full rounded-md bg-[#d8ba4a] py-3 text-sm font-semibold transition hover:bg-[#d8ba4a]"
          >
            {t("footer.subscribe")}
          </button>
        </div>
      </div>

      <div className="border-t border-[#2C4870] py-6">
        <div className="mx-auto flex max-w-7xl flex-col items-center justify-between px-6 text-sm text-gray-300 md:flex-row">
          <p>(c) {currentYear} AstroZura Inc. All cosmic rights reserved.</p>

          <div className="mt-3 flex items-center gap-6 md:mt-0">
            {!user && (
              <Link to="/astrologer/login" className="text-gray-300 transition hover:text-[#D4A73C]">
                {t("footer.astrologer_login")}
              </Link>
            )}
            <Link to="/terms-and-conditions" className="transition hover:text-[#D4A73C]">
              {t("footer.disclaimer")}
            </Link>
            <Link to="/services" className="transition hover:text-[#D4A73C]">
              {t("footer.sitemap")}
            </Link>
          </div>
        </div>
      </div>
    </footer>
  );
}
