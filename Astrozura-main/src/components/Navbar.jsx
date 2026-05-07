import { useEffect, useMemo, useRef, useState } from "react";
import { Link, NavLink } from "react-router-dom";
import { useTranslation } from "react-i18next";
import vedic from "../assets/vedic-astrology.png";
import { useAuth } from "../context/AuthContext";
import { groupedServices } from "../data/serviceCatalog";

export default function Navbar() {
  const { t, i18n } = useTranslation();
  const { user, logout } = useAuth();

  const [menuOpen, setMenuOpen] = useState(false);
  const [userDropdownOpen, setUserDropdownOpen] = useState(false);
  const [navDropdownOpen, setNavDropdownOpen] = useState("");
  const [langDropdownOpen, setLangDropdownOpen] = useState(false);

  const userDropdownRef = useRef(null);
  const navDropdownRef = useRef(null);
  const langRef = useRef(null);

  const avatarLetter = user?.name ? user.name.charAt(0).toUpperCase() : "U";
  const currentLang = i18n.language.split("-")[0];

  const navItems = useMemo(
    () => [
      { type: "link", label: t("navMenu.poojaAnusthan"), to: "/rituals" },
      { type: "link", label: t("navMenu.astroZuraPanchang"), to: "/panchang" },
      {
        type: "dropdown",
        label: t("navMenu.horoscope"),
        key: "horoscope",
        items: [
          { label: t("navMenu.horoscopeItems.today"), to: "/rashifal?period=today" },
          { label: t("navMenu.horoscopeItems.tomorrow"), to: "/rashifal?period=tomorrow" },
          { label: t("navMenu.horoscopeItems.yesterday"), to: "/rashifal?period=yesterday" },
        ],
      },
      {
        type: "dropdown",
        label: t("navMenu.reports"),
        key: "reports",
        items: [
          { label: t("navMenu.reportItems.lalKitab"), to: "/services/lal-kitab-report" },
          { label: t("navMenu.reportItems.kundliMatching"), to: "/matching" },
          { label: t("navMenu.reportItems.nakshatraPorutham"), to: "/matching-calculators?tool=nakshatra-porutham" },
          { label: t("navMenu.reportItems.thirumanaPorutham"), to: "/matching-calculators?tool=thirumana-porutham" },
          { label: t("navMenu.reportItems.porutham"), to: "/matching-calculators?tool=porutham" },
          { label: t("navMenu.reportItems.papasamyam"), to: "/matching-calculators?tool=papasamyam-check" },
          { label: t("navMenu.reportItems.detailedKundali"), to: "/services/detailed-kundali" },
        ],
      },
      {
        type: "dropdown",
        label: t("navMenu.calculators"),
        key: "calculators",
        items: [
          ...groupedServices.calculators.map((item) => {
            if (item.to === "/numerology") {
              return { ...item, label: t("navMenu.calculatorItems.numerology") };
            }

            if (item.to === "/services/tarot-reading") {
              return { ...item, label: t("navMenu.calculatorItems.tarotReading") };
            }

            if (item.to === "/services/palm-reading") {
              return { ...item, label: t("navMenu.calculatorItems.palmReading") };
            }

            return item;
          }),
        ],
      },
      { type: "link", label: t("nav.astrologers"), to: "/astrologers" },
    ],
    [t]
  );

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (userDropdownRef.current && !userDropdownRef.current.contains(event.target)) {
        setUserDropdownOpen(false);
      }

      if (navDropdownRef.current && !navDropdownRef.current.contains(event.target)) {
        setNavDropdownOpen("");
      }

      if (langRef.current && !langRef.current.contains(event.target)) {
        setLangDropdownOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const handleLogout = async () => {
    setUserDropdownOpen(false);
    await logout();
  };

  const changeLanguage = (lng) => {
    i18n.changeLanguage(lng);
    setLangDropdownOpen(false);
  };

  const desktopNavClass = ({ isActive }) =>
    `whitespace-nowrap rounded-xl px-2 py-2 transition ${
      isActive ? "bg-[#D4A73C] text-white" : "text-gray-700 hover:bg-[#FFF1CF]"
    }`;

  return (
    <nav className="sticky top-0 z-50 border-b border-gray-100/70 bg-white/90 px-4 py-1.5 shadow-[0_4px_30px_rgba(0,0,0,0.03)] backdrop-blur-lg md:px-8">
      <div className="flex items-center justify-between gap-3">
        <Link to="/" className="flex shrink-0 items-center transition hover:opacity-90">
          <img src={vedic} alt="Astro Zura" className="h-9 object-contain sm:h-10 md:h-11 lg:h-12" />
        </Link>

        <ul className="hidden min-w-0 flex-1 items-center justify-center gap-1 text-[13px] font-medium md:flex lg:gap-1.5 xl:text-sm" ref={navDropdownRef}>
          {navItems.map((item) => (
            <li key={item.label} className="relative flex-shrink-0">
              {item.type === "link" ? (
                <NavLink to={item.to} className={({ isActive }) =>
                  `rounded-xl px-1 py-1.5 transition md:px-1.5 lg:px-2 lg:py-2 ${
                    isActive ? "bg-[#D4A73C] text-white" : "text-gray-700 hover:bg-[#FFF1CF]"
                  }`
                }>
                  {item.label}
                </NavLink>
              ) : item.type === "external" ? (
                <a
                  href={item.to}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="rounded-xl px-1 py-1.5 transition text-gray-700 hover:bg-[#FFF1CF] md:px-1.5 lg:px-2 lg:py-2"
                >
                  {item.label}
                </a>
              ) : (
                <>
                  <button
                    type="button"
                    onClick={() => setNavDropdownOpen((current) => (current === item.key ? "" : item.key))}
                    className={`flex items-center gap-1 whitespace-nowrap rounded-xl px-2 py-2 transition ${
                      navDropdownOpen === item.key ? "bg-[#FFF1CF] text-[#1E3557]" : "text-gray-700 hover:bg-[#FFF1CF]"
                    }`}
                  >
                    <span className="whitespace-nowrap">{item.label}</span>
                    <span className={`text-[8px] transition lg:text-[10px] ${navDropdownOpen === item.key ? "rotate-180" : ""}`}>▼</span>
                  </button>

                  {navDropdownOpen === item.key && (
                    <div className="absolute left-0 top-full mt-3 max-h-[70vh] min-w-[220px] overflow-y-auto rounded-2xl border border-gray-100 bg-white p-2 shadow-2xl">
                      {item.items.map((subItem) => (
                        <Link
                          key={subItem.label}
                          to={subItem.to}
                          onClick={() => setNavDropdownOpen("")}
                          className="block rounded-xl px-4 py-3 text-sm font-medium text-[#1E3557] transition hover:bg-[#FBF7F0]"
                        >
                          {subItem.label}
                        </Link>
                      ))}
                    </div>
                  )}
                </>
              )}
            </li>
          ))}

          <li className="flex-shrink-0">
            <NavLink
              to="/subscription"
              className={({ isActive }) =>
                `whitespace-nowrap rounded-xl px-2.5 py-2 font-semibold transition ${
                  isActive ? "bg-[#D4A73C] text-white" : "bg-[#F6E6BB] text-[#1E3557] hover:bg-[#EFD694]"
                }`
              }
            >
              {t("navMenu.premiumPlans")}
            </NavLink>
          </li>
        </ul>

        <div className="flex shrink-0 items-center gap-1.5 lg:gap-2">
          <div className="relative" ref={langRef}>
            <button
              type="button"
              onClick={() => setLangDropdownOpen((current) => !current)}
              className="flex items-center gap-1 rounded-full border border-gray-200 bg-gray-50 px-2.5 py-1 text-[10px] font-bold uppercase text-gray-600 transition hover:bg-gray-100"
            >
              <span className="text-[11px] leading-none">🌐</span>
              {currentLang === "hi" ? "HI" : "EN"}
            </button>

            {langDropdownOpen && (
              <div className="absolute right-0 z-50 mt-2 w-32 overflow-hidden rounded-xl border border-gray-100 bg-white py-1 shadow-xl">
                <button
                  type="button"
                  onClick={() => changeLanguage("en")}
                  className={`block w-full px-4 py-2 text-left text-xs font-medium hover:bg-gray-50 ${currentLang === "en" ? "text-[#D4A73C]" : "text-gray-700"}`}
                >
                  English
                </button>
                <button
                  type="button"
                  onClick={() => changeLanguage("hi")}
                  className={`block w-full px-4 py-2 text-left text-xs font-medium hover:bg-gray-50 ${currentLang === "hi" ? "text-[#D4A73C]" : "text-gray-700"}`}
                >
                  Hindi
                </button>
              </div>
            )}
          </div>

          {user ? (
            <div className="relative" ref={userDropdownRef}>
              <button
                type="button"
                onClick={() => setUserDropdownOpen((current) => !current)}
                className="flex items-center gap-1 transition hover:opacity-80"
              >
                <div className="mr-0.5 hidden max-w-[150px] text-right 2xl:block">
                  <p className="truncate text-sm font-semibold leading-none text-[#184070]">{t("navMenu.userGreeting")} {user.name}</p>
                  <p className="mt-0.5 text-[11px] text-gray-500">{t("navMenu.memberTier")}</p>
                </div>
                <div className="flex h-9 w-9 items-center justify-center rounded-full border border-gray-300 bg-gray-200 text-sm font-bold text-gray-700 shadow-sm">
                  {avatarLetter}
                </div>
                <svg
                  className={`h-4 w-4 text-gray-500 transition-transform duration-200 ${userDropdownOpen ? "rotate-180" : ""}`}
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                </svg>
              </button>

              {userDropdownOpen && (
                <div className="absolute right-0 z-50 mt-2 w-52 overflow-hidden rounded-xl border border-gray-100 bg-white shadow-xl">
                  <div className="flex items-center gap-3 border-b border-gray-100 bg-gray-50 px-4 py-3">
                    <div className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full bg-[#D4A73C] text-sm font-bold text-white">
                      {avatarLetter}
                    </div>
                    <div className="overflow-hidden">
                      <p className="truncate text-sm font-semibold leading-tight text-gray-800">{user.name}</p>
                      <p className="text-xs text-gray-400">{t("navMenu.memberTier")}</p>
                    </div>
                  </div>

                  <div className="py-2">
                    {user.role === "astrologer" ? (
                      <Link
                        to="/astrologer/dashboard"
                        onClick={() => setUserDropdownOpen(false)}
                        className="block px-5 py-2.5 text-[13px] font-medium text-gray-700 transition hover:bg-gray-50 hover:text-[#184070]"
                      >
                        Astrologer Panel
                      </Link>
                    ) : (
                      <>
                        <Link
                          to="/dashboard"
                          onClick={() => setUserDropdownOpen(false)}
                          className="block px-5 py-2.5 text-[13px] font-medium text-gray-700 transition hover:bg-gray-50 hover:text-[#184070]"
                        >
                          {t("nav.dashboard")}
                        </Link>
                        <Link
                          to="/user-profile"
                          onClick={() => setUserDropdownOpen(false)}
                          className="block px-5 py-2.5 text-[13px] font-medium text-gray-700 transition hover:bg-gray-50 hover:text-[#184070]"
                        >
                          {t("nav.profile")}
                        </Link>
                      </>
                    )}

                    <div className="mt-2 border-t border-gray-100 pt-1">
                      <button
                        type="button"
                        onClick={handleLogout}
                        className="block w-full px-5 py-2.5 text-left text-[13px] font-semibold text-red-500 transition hover:bg-red-50"
                      >
                        {t("nav.logout")}
                      </button>
                    </div>
                  </div>
                </div>
              )}
            </div>
          ) : (
            <Link
              to="/login"
              className="rounded-full bg-[#184070] px-5 py-1.5 text-sm font-medium text-white shadow-sm transition hover:bg-[#161439] hover:shadow"
            >
              {t("nav.login")}
            </Link>
          )}

          <button
            type="button"
            onClick={() => setMenuOpen((current) => !current)}
            className="rounded-lg bg-gray-50 p-2 text-gray-500 transition-all active:scale-95 md:hidden"
          >
            <span className="text-xl">{menuOpen ? "✕" : "☰"}</span>
          </button>
        </div>
      </div>

      {menuOpen && (
        <div className="absolute left-0 right-0 top-full mt-0.5 border-t border-gray-100/50 bg-white/95 p-6 shadow-2xl backdrop-blur-md md:hidden">
          <ul className="flex flex-col gap-4 text-gray-700">
            {[
              { path: "/", name: t("nav.home") },
              { path: "/rituals", name: t("navMenu.poojaAnusthan") },
              { path: "/panchang", name: t("navMenu.astroZuraPanchang") },
              { path: "/astrologers", name: t("nav.astrologers") },
              { path: "/subscription", name: t("navMenu.premiumPlans") },
            ].map((item) => (
              <li key={item.path}>
                {item.isExternal ? (
                  <a
                    href={item.path}
                    target="_blank"
                    rel="noopener noreferrer"
                    onClick={() => setMenuOpen(false)}
                    className="block rounded-xl px-4 py-3 font-medium text-[#1E3557] transition-all hover:bg-[#FFF6E5]"
                  >
                    {item.name}
                  </a>
                ) : (
                  <NavLink
                    to={item.path}
                    onClick={() => setMenuOpen(false)}
                    className={({ isActive }) =>
                      `block rounded-xl px-4 py-3 font-medium transition-all ${
                        isActive ? "bg-[#D4A73C] text-white shadow-md" : "text-[#1E3557] hover:bg-[#FFF6E5]"
                      }`
                    }
                  >
                    {item.name}
                  </NavLink>
                )}
              </li>
            ))}

            {[
              {
                title: t("navMenu.horoscope"),
                items: [
                  { label: t("navMenu.horoscopeItems.today"), to: "/rashifal?period=today" },
                  { label: t("navMenu.horoscopeItems.tomorrow"), to: "/rashifal?period=tomorrow" },
                  { label: t("navMenu.horoscopeItems.yesterday"), to: "/rashifal?period=yesterday" },
                ],
              },
              {
                title: t("navMenu.reports"),
                items: [
                  { label: t("navMenu.reportItems.lalKitab"), to: "/services/lal-kitab-report" },
                  { label: t("navMenu.reportItems.kundliMatching"), to: "/matching" },
                  { label: t("navMenu.reportItems.nakshatraPorutham"), to: "/matching-calculators?tool=nakshatra-porutham" },
                  { label: t("navMenu.reportItems.thirumanaPorutham"), to: "/matching-calculators?tool=thirumana-porutham" },
                  { label: t("navMenu.reportItems.porutham"), to: "/matching-calculators?tool=porutham" },
                  { label: t("navMenu.reportItems.papasamyam"), to: "/matching-calculators?tool=papasamyam-check" },
                  { label: t("navMenu.reportItems.detailedKundali"), to: "/services/detailed-kundali" },
                ],
              },
              {
                title: t("navMenu.calculators"),
                items: [
                  ...groupedServices.calculators.map((item) => {
                    if (item.to === "/numerology") {
                      return { ...item, label: t("navMenu.calculatorItems.numerology") };
                    }

                    if (item.to === "/services/tarot-reading") {
                      return { ...item, label: t("navMenu.calculatorItems.tarotReading") };
                    }

                    if (item.to === "/services/palm-reading") {
                      return { ...item, label: t("navMenu.calculatorItems.palmReading") };
                    }

                    return item;
                  }),
                ],
              },
            ].map((group) => (
              <li key={group.title} className="rounded-2xl border border-gray-100 bg-[#FBF7F0] p-4">
                <p className="text-[11px] font-bold uppercase tracking-[0.18em] text-[#D4A73C]">{group.title}</p>
                <div className="mt-3 grid gap-2">
                  {group.items.map((subItem) => (
                    <Link
                      key={subItem.label}
                      to={subItem.to}
                      onClick={() => setMenuOpen(false)}
                      className="rounded-xl bg-white px-4 py-3 text-sm font-medium text-[#1E3557]"
                    >
                      {subItem.label}
                    </Link>
                  ))}
                </div>
              </li>
            ))}

            {user && (
              <li className="mt-4 grid gap-3 border-t border-gray-100 pt-6">
                <div className="mb-2 flex items-center gap-3 px-1">
                  <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gray-100 font-black text-[#184070]">
                    {avatarLetter}
                  </div>
                  <div>
                    <p className="text-sm font-bold leading-none text-gray-900">{user.name}</p>
                    <p className="mt-1 text-[11px] text-gray-400">{t("navMenu.memberTier")}</p>
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-2">
                  {user.role === "astrologer" ? (
                    <Link
                      to="/astrologer/dashboard"
                      onClick={() => setMenuOpen(false)}
                      className="block rounded-xl border border-gray-100 bg-gray-50 px-4 py-3 text-center text-sm font-bold text-[#183070]"
                    >
                      Panel
                    </Link>
                  ) : (
                    <>
                      <Link
                        to="/dashboard"
                        onClick={() => setMenuOpen(false)}
                        className="block rounded-xl border border-gray-100 bg-gray-50 px-4 py-3 text-center text-sm font-bold text-[#183070]"
                      >
                        Dashboard
                      </Link>
                      <Link
                        to="/user-profile"
                        onClick={() => setMenuOpen(false)}
                        className="block rounded-xl border border-gray-100 bg-gray-50 px-4 py-3 text-center text-sm font-bold text-[#183070]"
                      >
                        Profile
                      </Link>
                    </>
                  )}
                  <button
                    type="button"
                    onClick={() => {
                      setMenuOpen(false);
                      void handleLogout();
                    }}
                    className="block w-full rounded-xl bg-red-50 px-4 py-3 text-center text-sm font-bold text-red-600"
                  >
                    Logout
                  </button>
                </div>
              </li>
            )}
          </ul>
        </div>
      )}
    </nav>
  );
}
