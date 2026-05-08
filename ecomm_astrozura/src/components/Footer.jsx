import { useState } from "react";
import { Link } from "react-router-dom";
import vedic from "../assets/vedic-astrology.png";
import youtube from "../assets/youtube.png";
import instagram from "../assets/instagram.png";
import earth from "../assets/earth.png";
import phone from "../assets/phone-call.png";

export default function Footer() {
  const [email, setEmail] = useState("");
  const [msg, setMsg] = useState("");
  const currentYear = new Date().getFullYear();

  const handleSend = () => {
    if (!email) {
      setMsg("Please enter email");
    } else {
      setMsg("Subscribed successfully!");
      setEmail("");
    }

    setTimeout(() => setMsg(""), 2000);
  };

  return (
    <footer className="mt-2 bg-[#1E3557] text-white">
      {msg && (
        <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-lg bg-[#d8b14a] px-6 py-3 text-sm shadow">
          {msg}
        </div>
      )}

      <div className="mx-auto grid max-w-7xl grid-cols-1 gap-10 px-6 py-14 sm:grid-cols-2 sm:gap-14 lg:grid-cols-4">
        <div className="flex flex-col items-center text-center sm:items-start sm:text-left">
          <div className="flex h-16 w-fit items-center justify-center rounded-2xl bg-white px-6 shadow-md md:h-20">
            <img src={vedic} alt="AstroZura Logo" className="h-full w-auto object-contain p-2" />
          </div>

          <p className="mx-auto mt-5 max-w-xs text-sm leading-relaxed text-gray-300 sm:mx-0">
            Bringing celestial wisdom to your fingertips. AstroZura connects you with the world's most gifted astrologers.
          </p>

          <div className="mt-5 flex justify-center gap-3 sm:justify-start">
            {[earth, instagram, phone, youtube].map((icon, index) => (
              <div
                key={index}
                className="flex h-9 w-9 cursor-pointer items-center justify-center rounded-full bg-[#1E3557] transition hover:scale-110 hover:bg-[#D4A73C]"
              >
                <img src={icon} alt="icon" className="h-5 w-5 object-contain" />
              </div>
            ))}
          </div>
        </div>

        <div>
          <h3 className="mb-4 text-lg font-semibold">Company</h3>
          <ul className="space-y-2 text-sm text-gray-300">
            <li><Link to="/about" className="transition hover:text-[#D4A73C]">About Us</Link></li>
            <li><Link to="/contact" className="transition hover:text-[#D4A73C]">Contact Support</Link></li>
            <li><Link to="/shipping-return" className="transition hover:text-[#D4A73C]">Shipping & Return Policy</Link></li>
            <li><Link to="/privacy-policy" className="transition hover:text-[#D4A73C]">Privacy Policy</Link></li>
            <li><Link to="/support" className="transition hover:text-[#D4A73C]">Support</Link></li>
            <li><Link to="/refund-policy" className="transition hover:text-[#D4A73C]">Refund & Exchange Policy</Link></li>
          </ul>
        </div>

        <div>
          <h3 className="mb-4 text-lg font-semibold">Newsletter</h3>
          <p className="mb-4 text-sm text-gray-300">Get daily cosmic insights delivered to your inbox.</p>

          <input
            type="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            placeholder="Your email address"
            className="mb-3 w-full rounded-md bg-[#1E3557] px-4 py-3 text-sm text-white outline-none placeholder-gray-400 focus:ring-2 focus:ring-[#D4A73C]"
          />

          <button
            onClick={handleSend}
            className="w-full rounded-md bg-[#D4A73C] py-3 text-sm font-semibold transition hover:bg-[#D4A73C]"
          >
            Subscribe
          </button>
        </div>
      </div>

      <div className="border-t border-[#2C4870] py-6">
        <div className="mx-auto flex max-w-7xl flex-col items-center justify-between px-6 text-sm text-gray-300 md:flex-row">
          <p>© {currentYear} AstroZura Inc. All rights reserved.</p>

          <div className="mt-3 flex gap-6 md:mt-0">
            <span className="cursor-pointer transition hover:text-[#D4A73C]">Disclaimer</span>
            <span className="cursor-pointer transition hover:text-[#D4A73C]">Sitemap</span>
          </div>
        </div>
      </div>
    </footer>
  );
}
