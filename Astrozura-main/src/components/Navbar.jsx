import { useEffect, useMemo, useRef, useState } from "react";
import { Link, NavLink, useLocation } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { ChevronDown, Globe2, Menu, X } from "lucide-react";
import vedic from "../assets/vedic-astrology.png";
import { useAuth } from "../context/AuthContext";
import { groupedServices } from "../data/serviceCatalog";
import { API_BASE_URL } from "../utils/apiBase";
import { assetUrl } from "../utils/assetUrl";

export default function Navbar() {
  const { t, i18n } = useTranslation();
  const { user, logout } = useAuth();
  const location = useLocation();

  const [menuOpen, setMenuOpen] = useState(false);
  const [userDropdownOpen, setUserDropdownOpen] = useState(false);
  const [navDropdownOpen, setNavDropdownOpen] = useState("");
  const [langDropdownOpen, setLangDropdownOpen] = useState(false);
  const [mobileGroupOpen, setMobileGroupOpen] = useState("");
  const [ritualCategories, setRitualCategories] = useState([]);
  const [headerVisible, setHeaderVisible] = useState(true);

  const userDropdownRef = useRef(null);
  const navDropdownRef = useRef(null);
  const langRef = useRef(null);
  const desktopNavButtonRefs = useRef({});

  const avatarLetter = user?.name ? user.name.charAt(0).toUpperCase() : "U";
  const avatarImage = assetUrl(
    user?.profile_image || user?.astrologer_detail?.profile_image || user?.astrologerDetail?.profile_image
  );
  const currentLang = i18n.language.split("-")[0];
  const apiBase = API_BASE_URL;

  useEffect(() => {
    const loadRitualCategories = async () => {
      try {
        const response = await fetch(`${apiBase}/rituals?per_page=100`);
        const data = await response.json();
        const categoriesFromList = (data.rituals?.data || [])
          .map((ritual) => ritual.category)
          .filter(Boolean);
        const categories = [...new Set([...(data.categories || []), ...categoriesFromList])];
        if (data.success) setRitualCategories(categories);
      } catch (error) {
        console.error("Failed to load ritual navigation categories", error);
      }
    };

    void loadRitualCategories();
  }, [apiBase]);

  const navItems = useMemo(
    () => [
      {
        type: "dropdown",
        label: t("navMenu.panchang"),
        key: "panchang",
        items: [
          { label: t("navMenu.panchangItems.daily"), to: "/panchang?view=daily" },
          { label: t("navMenu.panchangItems.chaughadiya"), to: "/panchang?view=chaughadiya" },
          { label: t("navMenu.panchangItems.hora"), to: "/panchang?view=hora" },
        ],
      },
      { type: "link", label: t("navMenu.horoscope"), to: "/rashifal" },
      {
        type: "dropdown",
        label: t("navMenu.consultations"),
        key: "consultations",
        items: [
          { label: t("navMenu.consultationItems.chat"), to: "/astrologers?type=chat" },
          { label: t("navMenu.consultationItems.call"), to: "/astrologers?type=call" },
        ],
      },
      {
        type: "dropdown",
        label: t("navMenu.kundali"),
        key: "kundali",
        items: [
          { label: t("navMenu.kundaliItems.detailed"), to: "/services/detailed-kundali" },
        ],
      },
      {
        type: "dropdown",
        label: t("navMenu.calculators"),
        key: "calculators",
        items: [
          ...groupedServices.calculators.map((item) => {
            if (item.to === "/detailed-numerology") {
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
      { type: "link", label: t("navMenu.matchmaking"), key: "matchmaking", to: "/services/detailed-matchmaking" },
      { type: "link", label: t("navMenu.numerology"), key: "numerology", to: "/detailed-numerology" },
      { type: "link", label: t("navMenu.tarot"), key: "tarot", to: "/services/tarot-reading" },
      { type: "link", label: t("navMenu.palmReading"), key: "palm-reading", to: "/services/palm-reading" },
      { type: "external", label: t("navMenu.shop"), key: "shop", to: "https://shop.astrozura.com" },
      {
        type: "dropdown",
        label: t("navMenu.poojaAnusthan"),
        key: "rituals",
        items: [
          { label: "View All Anusthan", to: "/rituals" },
          ...ritualCategories.map((category) => ({
            label: category,
            to: `/rituals?category=${encodeURIComponent(category)}`,
          })),
        ],
      },
      {
        type: "dropdown",
        label: t("navMenu.reports"),
        key: "reports",
        items: groupedServices.reports.map((item) => {
          if (item.to === "/services/lal-kitab-report") {
            return { ...item, label: t("navMenu.reportItems.lalKitab") };
          }

          return item;
        }),
      },
      { type: "link", label: t("navMenu.blogs"), key: "blogs", to: "/blogs" },
    ],
    [ritualCategories, t]
  );

  const topDesktopNavKeys = useMemo(
    () => new Set(["panchang", "consultations", "calculators", "rituals", "reports", "blogs"]),
    []
  );
  const topDesktopNavItems = useMemo(
    () => navItems.filter((item) => topDesktopNavKeys.has(item.key)),
    [navItems, topDesktopNavKeys]
  );
  const secondaryDesktopNavItems = useMemo(
    () => navItems.filter((item) => !topDesktopNavKeys.has(item.key)),
    [navItems, topDesktopNavKeys]
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

  useEffect(() => {
    const closeDesktopDropdown = () => setNavDropdownOpen("");
    window.addEventListener("resize", closeDesktopDropdown);
    return () => window.removeEventListener("resize", closeDesktopDropdown);
  }, []);

  useEffect(() => {
    setMenuOpen(false);
    setMobileGroupOpen("");
    setNavDropdownOpen("");
  }, [location.pathname, location.search]);

  useEffect(() => {
    if (!menuOpen) {
      document.body.style.removeProperty("overflow");
      return undefined;
    }

    document.body.style.overflow = "hidden";
    return () => document.body.style.removeProperty("overflow");
  }, [menuOpen]);

  useEffect(() => {
    let lastScrollY = window.scrollY;

    const handleScroll = () => {
      const currentScrollY = window.scrollY;
      if (currentScrollY < 24 || currentScrollY < lastScrollY - 6) {
        setHeaderVisible(true);
      } else if (currentScrollY > lastScrollY + 8 && currentScrollY > 120) {
        setHeaderVisible(false);
        setNavDropdownOpen("");
        setLangDropdownOpen(false);
        setUserDropdownOpen(false);
      }
      lastScrollY = currentScrollY;
    };

    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const handleLogout = async () => {
    setUserDropdownOpen(false);
    await logout();
  };

  const changeLanguage = (lng) => {
    i18n.changeLanguage(lng);
    setLangDropdownOpen(false);
  };

  const getDropdownStyle = (item) => {
    const trigger = desktopNavButtonRefs.current[item.key];
    if (!trigger || typeof window === "undefined") return {};

    const rect = trigger.getBoundingClientRect();
    const width = item.items.length > 5 ? Math.min(720, window.innerWidth - 32) : 288;
    const left = Math.max(16, Math.min(rect.left + rect.width / 2 - width / 2, window.innerWidth - width - 16));

    return {
      left: `${left}px`,
      top: `${rect.bottom + 8}px`,
      width: `${width}px`,
    };
  };

  const renderDesktopNavItem = (item, variant = "top") => {
    const isGoldRow = variant === "gold";
    const linkBase = isGoldRow
      ? "block whitespace-nowrap rounded-full px-3 py-2 text-[13px] font-black transition"
      : "block whitespace-nowrap rounded-full px-2 py-2 text-[12px] font-semibold text-[#184070] transition hover:bg-[#FFF6E5] hover:text-[#D4A73C] xl:px-3 xl:text-sm";
    const dropdownButtonBase = isGoldRow
      ? "flex items-center gap-1 whitespace-nowrap rounded-full px-3 py-2 text-[13px] font-black transition"
      : "flex items-center gap-1 whitespace-nowrap rounded-full px-2 py-2 text-[12px] font-semibold text-[#184070] transition hover:bg-[#FFF6E5] hover:text-[#D4A73C] xl:px-3 xl:text-sm";

    if (item.type === "link") {
      return (
        <NavLink
          to={item.to}
          className={({ isActive }) =>
            `${linkBase} ${
              isGoldRow
                ? isActive
                  ? "bg-[#1E3557] text-white"
                  : "text-[#1E3557] hover:bg-white/35"
                : isActive
                  ? "bg-[#FFF6E5] text-[#D4A73C]"
                  : ""
            }`
          }
        >
          {item.label}
        </NavLink>
      );
    }

    if (item.type === "external") {
      return (
        <a
          href={item.to}
          target="_blank"
          rel="noopener noreferrer"
          className={`${linkBase} ${isGoldRow ? "text-[#1E3557] hover:bg-white/35" : ""}`}
        >
          {item.label}
        </a>
      );
    }

    const isOpen = navDropdownOpen === item.key;
    const panelWidth = item.items.length > 5 ? "w-[min(720px,calc(100vw-2rem))]" : "w-72";
    const showSubIcons = item.key === "calculators" || item.key === "reports";

    return (
      <>
        <button
          ref={(node) => {
            if (node) desktopNavButtonRefs.current[item.key] = node;
          }}
          type="button"
          onClick={() => setNavDropdownOpen((current) => (current === item.key ? "" : item.key))}
          className={`${dropdownButtonBase} ${
            isGoldRow
              ? isOpen
                ? "bg-white text-[#1E3557]"
                : "text-[#1E3557] hover:bg-white/35"
              : isOpen
                ? "bg-[#FFF6E5] text-[#D4A73C]"
                : ""
          }`}
        >
          <span>{item.label}</span>
          <ChevronDown size={14} className={`transition ${isOpen ? "rotate-180" : ""}`} />
        </button>

        {isOpen && (
          <div
            style={getDropdownStyle(item)}
            className={`fixed z-[999] max-h-[72vh] overflow-y-auto rounded-2xl border border-gray-100 bg-white p-3 text-[#1E3557] shadow-2xl ${panelWidth}`}
          >
            <div className={item.items.length > 5 ? "grid grid-cols-2 gap-1" : "grid gap-1"}>
              {item.items.map((subItem) => (
                <Link
                  key={subItem.label}
                  to={subItem.to}
                  onClick={() => setNavDropdownOpen("")}
                  className={`rounded-xl px-4 py-3 text-sm font-medium transition hover:bg-[#FBF7F0] ${
                    showSubIcons ? "flex items-center gap-3" : "block"
                  }`}
                >
                  {showSubIcons && subItem.icon && (
                    <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[#FBF7F0] p-1.5 ring-1 ring-[#EFE5D4]">
                      <img src={subItem.icon} alt="" className="h-full w-full object-contain" />
                    </span>
                  )}
                  {subItem.label}
                </Link>
              ))}
            </div>
          </div>
        )}
      </>
    );
  };

  return (
    <>
    <header ref={navDropdownRef} className={`sticky top-0 z-50 transition-transform duration-300 ${headerVisible || menuOpen ? "translate-y-0" : "-translate-y-full"}`}>
    <nav className="relative z-[150] overflow-visible border-b border-gray-100/70 bg-white/95 px-4 py-1.5 shadow-[0_4px_30px_rgba(0,0,0,0.03)] backdrop-blur-lg md:px-8">
      <div className="mx-auto flex max-w-7xl items-center justify-between gap-3 lg:grid lg:grid-cols-[230px_minmax(0,1fr)_230px] xl:grid-cols-[260px_minmax(0,1fr)_260px]">
        <Link to="/" className="flex shrink-0 items-center transition hover:opacity-90">
          <img src={vedic} alt="Astro Zura" className="h-9 object-contain sm:h-10 md:h-11 lg:h-12" />
        </Link>

        <div className="hidden min-w-0 flex-1 items-center justify-center gap-0.5 lg:flex">
          {topDesktopNavItems.map((item) => (
            <div key={item.key || item.label} className="relative flex-shrink-0">
              {renderDesktopNavItem(item)}
            </div>
          ))}
        </div>

        <div className="flex shrink-0 items-center justify-end gap-1.5 lg:gap-2">
          <Link
            to="/live"
            className="hidden items-center rounded-full bg-red-50 px-3 py-1.5 text-xs font-bold uppercase tracking-[0.16em] text-red-600 transition hover:bg-red-100 md:inline-flex"
          >
            {t("navMenu.live")}
          </Link>

          <div className="relative" ref={langRef}>
            <button
              type="button"
              onClick={() => setLangDropdownOpen((current) => !current)}
              className="flex items-center gap-1 rounded-full border border-gray-200 bg-gray-50 px-2.5 py-1 text-[10px] font-bold uppercase text-gray-600 transition hover:bg-gray-100"
            >
              <Globe2 size={13} />
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
                <div className="flex h-9 w-9 items-center justify-center overflow-hidden rounded-full border border-gray-300 bg-gray-200 text-sm font-bold text-gray-700 shadow-sm">
                  {avatarImage ? (
                    <img src={avatarImage} alt={user.name || "User"} className="h-full w-full object-cover" />
                  ) : (
                    avatarLetter
                  )}
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
                    <div className="flex h-9 w-9 flex-shrink-0 items-center justify-center overflow-hidden rounded-full bg-[#D4A73C] text-sm font-bold text-white">
                      {avatarImage ? (
                        <img src={avatarImage} alt={user.name || "User"} className="h-full w-full object-cover" />
                      ) : (
                        avatarLetter
                      )}
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
            aria-label={menuOpen ? "Close menu" : "Open menu"}
            onClick={() => setMenuOpen((current) => !current)}
            className="rounded-lg bg-gray-50 p-2 text-gray-500 transition-all active:scale-95 lg:hidden"
          >
            {menuOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>
      </div>

    </nav>
    <nav className="relative z-[20] hidden border-t border-[#c49a37] bg-[#D8B04B] px-4 shadow-sm lg:block md:px-8">
      <div className="mx-auto grid max-w-7xl grid-cols-[230px_minmax(0,1fr)_230px] items-center xl:grid-cols-[260px_minmax(0,1fr)_260px]">
        <div aria-hidden="true" />
        <div className="flex flex-wrap items-center justify-center gap-1 overflow-visible py-2">
          {secondaryDesktopNavItems.map((item) => (
            <div key={item.key || item.label} className="relative flex-shrink-0">
              {renderDesktopNavItem(item, "gold")}
            </div>
          ))}
        </div>
        <div aria-hidden="true" />
      </div>
    </nav>
    </header>

      {menuOpen && (
        <>
        <button
          type="button"
          aria-label="Close navigation"
          onClick={() => setMenuOpen(false)}
          className="fixed inset-0 z-[998] bg-black/35 lg:hidden"
        />
        <div className="fixed bottom-0 right-0 top-0 z-[999] w-[min(88vw,360px)] overflow-y-auto border-l border-gray-100 bg-white p-5 shadow-2xl lg:hidden">
          <div className="mb-5 flex items-center justify-between border-b border-gray-100 pb-4">
            <img src={vedic} alt="Astro Zura" className="h-10 object-contain" />
            <button
              type="button"
              aria-label="Close menu"
              onClick={() => setMenuOpen(false)}
              className="rounded-lg bg-gray-100 p-2 text-gray-600"
            >
              <X size={20} />
            </button>
          </div>
          <ul className="flex flex-col gap-4 text-gray-700">
            {[
              { path: "/", name: t("nav.home") },
              { path: "/live", name: t("navMenu.live") },
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

            {navItems.map((group) => (
              <li key={group.key || group.label} className={group.type === "dropdown" ? "overflow-hidden rounded-xl border border-gray-100 bg-[#FBF7F0]" : ""}>
                {group.type === "link" ? (
                  <NavLink
                    to={group.to}
                    onClick={() => setMenuOpen(false)}
                    className={({ isActive }) =>
                      `block rounded-xl px-4 py-3 font-medium transition-all ${
                        isActive ? "bg-[#D4A73C] text-white shadow-md" : "text-[#1E3557] hover:bg-[#FFF6E5]"
                      }`
                    }
                  >
                    {group.label}
                  </NavLink>
                ) : group.type === "external" ? (
                  <a
                    href={group.to}
                    target="_blank"
                    rel="noopener noreferrer"
                    onClick={() => setMenuOpen(false)}
                    className="block rounded-xl px-4 py-3 font-medium text-[#1E3557] transition-all hover:bg-[#FFF6E5]"
                  >
                    {group.label}
                  </a>
                ) : (
                  <>
                <button
                  type="button"
                  onClick={() => setMobileGroupOpen((current) => current === group.key ? "" : group.key)}
                  className="flex w-full items-center justify-between px-4 py-4 text-left text-sm font-bold text-[#1E3557]"
                >
                  {group.label}
                  <ChevronDown size={18} className={`transition ${mobileGroupOpen === group.key ? "rotate-180" : ""}`} />
                </button>
                {mobileGroupOpen === group.key && (
                <div className="grid gap-2 border-t border-gray-100 p-3">
                  {group.items.map((subItem) => (
                    <Link
                      key={subItem.label}
                      to={subItem.to}
                      onClick={() => {
                        setMenuOpen(false);
                        setMobileGroupOpen("");
                      }}
                      className="rounded-xl bg-white px-4 py-3 text-sm font-medium text-[#1E3557]"
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

            {user && (
              <li className="mt-4 grid gap-3 border-t border-gray-100 pt-6">
                <div className="mb-2 flex items-center gap-3 px-1">
                  <div className="flex h-10 w-10 items-center justify-center overflow-hidden rounded-xl bg-gray-100 font-black text-[#184070]">
                    {avatarImage ? (
                      <img src={avatarImage} alt={user.name || "User"} className="h-full w-full object-cover" />
                    ) : (
                      avatarLetter
                    )}
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
                        {t("nav.dashboard")}
                      </Link>
                      <Link
                        to="/user-profile"
                        onClick={() => setMenuOpen(false)}
                        className="block rounded-xl border border-gray-100 bg-gray-50 px-4 py-3 text-center text-sm font-bold text-[#183070]"
                      >
                        {t("nav.profile")}
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
                    {t("nav.logout")}
                  </button>
                </div>
              </li>
            )}
          </ul>
        </div>
        </>
      )}
    </>
  );
}
