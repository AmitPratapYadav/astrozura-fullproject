import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import poojaRitual from "../assets/pooja ritual.png";
import bhagwat from "../assets/bhagwat.png";
import lamp from "../assets/lamp.png";
import astro1 from "../assets/astro1.png";
import astro2 from "../assets/astro2.png";
import astro3 from "../assets/astro3.png";
import { usePushNotifications } from "../context/PushNotificationsContext";
import { subscribeToLiveStatusChanges } from "../lib/liveStatusBroadcast";
import { API_BASE_URL } from "../utils/apiBase";
import AstrologerStatusBadge from "./AstrologerStatusBadge";

export default function MainSections() {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();

  const [msg, setMsg] = useState("");
  const [activeBtn, setActiveBtn] = useState({});
  const [astrologers, setAstrologers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [liveSession, setLiveSession] = useState(null);
  const [rituals, setRituals] = useState([]);
  const [blogPosts, setBlogPosts] = useState([]);
  const {
    isSupported: pushSupported,
    isSubscribed: pushSubscribed,
    isLoading: pushLoading,
    permission: pushPermission,
    subscribeToLiveNotifications,
    unsubscribeFromLiveNotifications,
  } = usePushNotifications();

  useEffect(() => {
    const fetchAstrologers = async () => {
      const controller = new AbortController();
      const timeoutId = window.setTimeout(() => controller.abort(), 8000);

      try {
        const response = await fetch(`${API_BASE_URL}/astrologers?la=${i18n.language === "hi" ? "hi" : "en"}`, { signal: controller.signal });
        const data = await response.json();

        const list = data.astrologers || data.data?.data || data.data || [];
        if (!Array.isArray(list)) {
          return;
        }

        const sorted = [...list].sort(
          (left, right) =>
            parseFloat(right.astrologer_detail?.rating || 0) -
            parseFloat(left.astrologer_detail?.rating || 0)
        );

        setAstrologers(sorted.slice(0, 3));
      } catch (error) {
        if (error?.name !== "AbortError") {
          console.error("Failed to load top astrologers", error);
        }
      } finally {
        window.clearTimeout(timeoutId);
        setLoading(false);
      }
    };

    void fetchAstrologers();
  }, [i18n.language]);

  useEffect(() => {
    const fetchRituals = async () => {
      try {
        const params = new URLSearchParams({ per_page: "4", page: "1", la: i18n.language === "hi" ? "hi" : "en" });
        const response = await fetch(`${API_BASE_URL}/rituals?${params.toString()}`);
        const data = await response.json();

        if (data.success) {
          setRituals(data.rituals?.data || []);
        }
      } catch (error) {
        console.error("Failed to load rituals for homepage", error);
      }
    };

    void fetchRituals();
  }, [i18n.language]);

  useEffect(() => {
    const fetchBlogPosts = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/blogs?per_page=4&la=${i18n.language === "hi" ? "hi" : "en"}&_=${Date.now()}`, {
          cache: "no-store",
        });
        const data = await response.json();
        if (data?.status === "success") {
          setBlogPosts(data.data?.data || data.data || []);
        }
      } catch (error) {
        console.error("Failed to load homepage blogs", error);
      }
    };

    void fetchBlogPosts();
  }, [i18n.language]);

  useEffect(() => {
    let cancelled = false;

    const fetchLiveSession = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/live-sessions/current`);
        const data = await response.json();
        if (!cancelled && data?.success) {
          setLiveSession(data.session || null);
        }
      } catch (error) {
        console.error("Failed to load current live session", error);
      }
    };

    void fetchLiveSession();

    const refreshTimer = window.setInterval(() => {
      void fetchLiveSession();
    }, 5000);

    const handleLiveStatusChanged = () => {
      void fetchLiveSession();
    };

    const unsubscribeLiveStatus = subscribeToLiveStatusChanges(handleLiveStatusChanged);
    window.addEventListener("astrozura:push-message", handleLiveStatusChanged);

    return () => {
      cancelled = true;
      window.clearInterval(refreshTimer);
      unsubscribeLiveStatus();
      window.removeEventListener("astrozura:push-message", handleLiveStatusChanged);
    };
  }, []);

  const notify = (text) => {
    setMsg(text);
    window.setTimeout(() => setMsg(""), 2000);
  };

  const handleLiveNotificationToggle = async () => {
    try {
      const result = pushSubscribed
        ? await unsubscribeFromLiveNotifications()
        : await subscribeToLiveNotifications();

      notify(result.message);
    } catch (error) {
      console.error("Failed to update live notification subscription", error);
      notify(error?.message || "Live notification subscription could not be updated.");
    }
  };

  const getImageUrl = (path, fallback) => {
    if (!path) return fallback;
    if (path.startsWith("http")) return path;
    const baseUrl = import.meta.env.VITE_BACKEND_URL || "https://astrozura.com";
    return `${baseUrl}${path.startsWith("/") ? path : `/${path}`}`;
  };

  const ritualFallbacks = [poojaRitual, bhagwat, lamp];
  const pathStepThemes = [
    {
      bg: "from-[#FFF4EA] to-[#FFEDE4]",
      orb: "bg-[#FDD2C2]",
      icon: "from-[#FFB05C] to-[#E65D2E]",
      border: "border-[#F7D6BD]",
    },
    {
      bg: "from-[#F1FAE9] to-[#EAF7DF]",
      orb: "bg-[#CDECC1]",
      icon: "from-[#D5B33A] to-[#41983B]",
      border: "border-[#D5EBC8]",
    },
    {
      bg: "from-[#EAF7FF] to-[#E8F2FF]",
      orb: "bg-[#C8E6FF]",
      icon: "from-[#58BAFF] to-[#2D65D9]",
      border: "border-[#CBE2F7]",
    },
    {
      bg: "from-[#FAECFF] to-[#F5E6FF]",
      orb: "bg-[#E7C8F7]",
      icon: "from-[#C084FC] to-[#7C3AED]",
      border: "border-[#E8D1F5]",
    },
  ];

  const formatRatingText = (details) => {
    const ratingValue =
      details?.rating !== null && details?.rating !== undefined && details?.rating !== ""
        ? Number(details.rating)
        : null;
    const totalReviews = Number(details?.total_reviews || 0);

    if (!ratingValue || totalReviews === 0) {
      return "Not Rated Yet";
    }

    return `${ratingValue.toFixed(1)} (${totalReviews} review${totalReviews === 1 ? "" : "s"})`;
  };

  const hasRealRating = (details) => {
    const ratingValue =
      details?.rating !== null && details?.rating !== undefined && details?.rating !== ""
        ? Number(details.rating)
        : null;
    const totalReviews = Number(details?.total_reviews || 0);

    return Boolean(ratingValue) && totalReviews > 0;
  };

  const formatRatingBadge = (details) => {
    const ratingValue =
      details?.rating !== null && details?.rating !== undefined && details?.rating !== ""
        ? Number(details.rating)
        : null;
    const totalReviews = Number(details?.total_reviews || 0);

    if (!ratingValue || totalReviews === 0) {
      return "Not Rated Yet";
    }

    return `★ ${ratingValue.toFixed(1)}`;
  };

  return (
    <section className="bg-gradient-to-b from-[#FAF7F2] via-[#F8F5EF] to-[#F8F5EF] px-4 py-14 md:px-10 sm:py-20">
      {msg && (
      <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-md bg-[#d8b14a] px-5 py-2 text-xs text-white shadow">
          {msg}
        </div>
      )}

      <div className="mx-auto w-full max-w-[1200px] space-y-20">
        <div className="overflow-hidden rounded-[2rem] border border-[#EEE7D6] bg-white p-7 shadow-sm md:p-10">
          <div className="mx-auto max-w-3xl text-center">
            <p className="text-[11px] font-black uppercase tracking-[0.24em] text-[#D4A73C]">{t("home_sections.how_eyebrow")}</p>
            <h2 className="mt-3 text-3xl font-black tracking-tight text-[#1E3557] md:text-4xl">
              {t("home_sections.how_title")}
            </h2>
            <p className="mt-4 text-sm leading-7 text-gray-500">
              {t("home_sections.how_subtitle")}
            </p>
          </div>

          <div className="relative mt-10 grid gap-5 md:grid-cols-4">
            <div className="absolute left-[12%] right-[12%] top-12 hidden border-t border-dashed border-[#D4A73C]/40 md:block" />
            {[
              ["1", t("home_sections.steps.birth_title"), t("home_sections.steps.birth_copy")],
              ["2", t("home_sections.steps.service_title"), t("home_sections.steps.service_copy")],
              ["3", t("home_sections.steps.connect_title"), t("home_sections.steps.connect_copy")],
              ["4", t("home_sections.steps.guidance_title"), t("home_sections.steps.guidance_copy")],
            ].map(([number, title, copy], index) => {
              const theme = pathStepThemes[index % pathStepThemes.length];

              return (
                <div
                  key={number}
                  className={`group relative min-h-[230px] overflow-hidden rounded-[1.35rem] border ${theme.border} bg-gradient-to-br ${theme.bg} p-6 text-center shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-xl hover:shadow-black/10`}
                >
                  <div className={`absolute -right-8 -top-10 h-28 w-28 rounded-full ${theme.orb} opacity-70 transition group-hover:scale-110`} />
                  <div className="relative z-10">
                    <div className={`mx-auto flex h-20 w-20 items-center justify-center rounded-full bg-gradient-to-br ${theme.icon} p-1 shadow-lg shadow-black/15 ring-4 ring-white/90 transition group-hover:scale-[1.04]`}>
                      <span className="flex h-full w-full items-center justify-center rounded-full bg-[#D7AF4B] text-3xl font-black text-[#1E3557]">
                        {number}
                      </span>
                    </div>
                    <h3 className="mt-6 text-base font-black text-[#1E3557]">{title}</h3>
                    <p className="mx-auto mt-3 max-w-[230px] text-sm leading-6 text-slate-600">{copy}</p>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {blogPosts.length > 0 && (
          <div className="overflow-hidden rounded-[2rem] bg-[#101722] p-7 text-white shadow-xl md:p-10">
            <div className="mb-8 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
              <div>
                <p className="text-[11px] font-black uppercase tracking-[0.26em] text-[#D4A73C]">{t("home_sections.blog_eyebrow")}</p>
                <h2 className="mt-3 text-3xl font-black tracking-tight md:text-5xl">{t("home_sections.blog_title")}</h2>
              </div>
              <Link
                to="/blogs"
                className="inline-flex items-center justify-center rounded-full border border-white/15 px-6 py-3 text-sm font-black text-white transition hover:border-[#D4A73C] hover:text-[#D4A73C]"
              >
                {t("home_sections.all_blogs")} &rarr;
              </Link>
            </div>

            <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-4">
              {blogPosts.slice(0, 4).map((blog) => (
                <Link
                  key={blog.id}
                  to={`/blogs/${blog.slug}`}
                  className="group overflow-hidden rounded-3xl border border-white/10 bg-white/5 transition hover:-translate-y-1 hover:border-[#D4A73C]/60"
                >
                  <div className="aspect-[16/11] bg-[#1E3557]">
                    {blog.cover_image ? (
                      <img
                        src={getImageUrl(blog.cover_image, "")}
                        alt={blog.title}
                        className="h-full w-full object-cover opacity-90 transition duration-300 group-hover:scale-[1.03] group-hover:opacity-100"
                      />
                    ) : (
                      <div className="flex h-full items-center justify-center text-5xl font-black text-[#D4A73C]">AZ</div>
                    )}
                  </div>
                  <div className="p-5">
                    <p className="text-[10px] font-black uppercase tracking-[0.18em] text-[#D4A73C]">
                      {blog.category?.name || t("main.astrology")}
                    </p>
                    <h3 className="mt-3 line-clamp-2 text-lg font-black leading-snug text-white">{blog.title}</h3>
                    <p className="mt-3 text-sm font-semibold text-white/55">{Number(blog.views_count || 0).toLocaleString("en-IN")} views</p>
                  </div>
                </Link>
              ))}
            </div>
          </div>
        )}

        {rituals.length > 0 && (
          <div>
            <div className="mb-8 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
              <div>
                <p className="text-[11px] font-black uppercase tracking-[0.22em] text-[#D4A73C]">{t("home_sections.ritual_eyebrow")}</p>
                <h2 className="mt-2 text-3xl font-black tracking-tight text-[#1E3557]">{t("home_sections.ritual_title")}</h2>
                <p className="mt-2 max-w-2xl text-sm leading-6 text-gray-500">
                  {t("home_sections.ritual_subtitle")}
                </p>
              </div>

              <Link
                to="/rituals"
                className="inline-flex items-center justify-center rounded-xl border border-[#D4A73C]/25 px-5 py-3 text-[11px] font-black uppercase tracking-[0.2em] text-[#D4A73C] transition hover:bg-[#D4A73C]/10 hover:text-[#b8860b]"
              >
                {t("home_sections.view_all")}
              </Link>
            </div>

            <div className="grid gap-5 sm:grid-cols-2 xl:grid-cols-4">
              {rituals.slice(0, 4).map((ritual, index) => (
                <div key={ritual.id} className="overflow-hidden rounded-3xl border border-[#efe4d2] bg-white shadow-sm transition hover:-translate-y-1 hover:shadow-lg">
                  <Link to={`/rituals/${ritual.slug}`} className="block overflow-hidden">
                    <img
                      src={getImageUrl(ritual.image, ritualFallbacks[index % ritualFallbacks.length])}
                      alt={ritual.name}
                      className="h-40 w-full object-cover transition duration-300 hover:scale-[1.03]"
                    />
                  </Link>
                  <div className="p-5">
                    <div className="flex items-center justify-between gap-3">
                      <p className="text-[10px] font-black uppercase tracking-[0.18em] text-[#D4A73C]">{ritual.category}</p>
                      {ritual.is_popular && (
                        <span className="rounded-full bg-[#fff3da] px-2.5 py-1 text-[10px] font-bold uppercase text-[#c38a11]">
                          {t("home_sections.popular")}
                        </span>
                      )}
                    </div>
                    <Link to={`/rituals/${ritual.slug}`} className="mt-3 block text-xl font-black leading-tight text-[#1E3557] transition hover:text-[#D4A73C]">
                      {ritual.name}
                    </Link>
                    <p className="mt-3 line-clamp-2 text-sm leading-6 text-gray-500">{ritual.short_description}</p>
                    <div className="mt-4 flex items-center justify-between text-sm text-gray-500">
                      <span>{ritual.duration_label}</span>
                      <span className="font-bold text-[#1E3557]">Consultation first</span>
                    </div>
                    <div className="mt-5 grid grid-cols-2 gap-3">
                      <Link
                        to={`/rituals/${ritual.slug}`}
                        className="rounded-xl border border-[#1E3557] px-3 py-2.5 text-center text-xs font-bold text-[#1E3557] transition hover:bg-[#1E3557] hover:text-white"
                      >
                        {t("home_sections.view_details")}
                      </Link>
                      <button
                        type="button"
                        onClick={() => navigate(`/rituals/${ritual.slug}/book`)}
                        className="rounded-xl bg-[#1E3557] px-3 py-2.5 text-xs font-black text-white transition hover:bg-[#162a45]"
                      >
                        {t("premium.book_now")}
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            <div className="mt-6 flex justify-center sm:hidden">
              <Link
                to="/rituals"
                className="inline-flex items-center justify-center rounded-xl border border-[#D4A73C]/25 bg-white px-5 py-3 text-[11px] font-black uppercase tracking-[0.2em] text-[#D4A73C] shadow-sm transition hover:bg-[#D4A73C]/10 hover:text-[#b8860b]"
              >
                {t("home_sections.view_all")}
              </Link>
            </div>
          </div>
        )}

        <div className="overflow-hidden rounded-[2rem] border border-[#EEE7D6] bg-white shadow-sm">
          <div className="grid gap-0 lg:grid-cols-[1.25fr_0.75fr]">
            <div className="bg-gradient-to-br from-[#162744] via-[#1E3557] to-[#223C63] p-8 text-white md:p-10">
              <p className="inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/10 px-4 py-1.5 text-[11px] font-bold uppercase tracking-[0.22em]">
                <span className={`h-2 w-2 rounded-full ${liveSession ? "animate-pulse bg-red-400" : "bg-[#D4A73C]"}`} />
                {liveSession ? t("home_sections.live_now") : t("home_sections.live_sessions")}
              </p>
              <h2 className="mt-5 text-3xl font-black md:text-4xl">
                {liveSession ? liveSession.title : t("home_sections.no_live_title")}
              </h2>
              <p className="mt-4 max-w-3xl text-sm leading-7 text-slate-200">
                {liveSession
                  ? liveSession.description
                  : "Join live spiritual guidance sessions with featured astrologers. When no one is live, you can subscribe for notifications and return as soon as the next session starts."}
              </p>
              <div className="mt-6 flex flex-wrap gap-3 text-sm font-semibold">
                <span className="rounded-2xl bg-white/10 px-4 py-2 text-slate-100">
                  {liveSession ? `Hosted by ${liveSession.astrologer?.name || "Featured Astrologer"}` : "Featured astrologers only"}
                </span>
                <span className="rounded-2xl bg-white/10 px-4 py-2 text-slate-100">
                  {liveSession ? "Live comments enabled" : "Push alerts coming next"}
                </span>
              </div>
            </div>

            <div className="flex flex-col justify-center gap-4 p-8 md:p-10">
              <div className="rounded-3xl border border-[#EEE7D6] bg-[#FBF7F0] p-6">
                <p className="text-xs font-bold uppercase tracking-[0.22em] text-[#D4A73C]">
                  {liveSession ? "Streaming Status" : "Stay Updated"}
                </p>
                <p className="mt-3 text-2xl font-black text-[#1E3557]">
                  {liveSession ? "A featured astrologer is live now" : "Get notified when the next session starts"}
                </p>
                <p className="mt-3 text-sm leading-7 text-gray-600">
                  {liveSession
                    ? t("home_sections.live_open_copy")
                    : t("home_sections.live_notify_copy")}
                </p>
              </div>

              <div className="flex flex-col gap-3 sm:flex-row">
                <button
                  type="button"
                  onClick={() => navigate("/live")}
                  className="inline-flex items-center justify-center rounded-2xl bg-[#1E3557] px-8 py-4 text-sm font-black text-white shadow-xl shadow-[#1E3557]/20 transition hover:-translate-y-1 hover:bg-[#162a45]"
                >
                  {liveSession ? t("home_sections.join_live") : t("home_sections.open_live")}
                </button>
                <button
                  type="button"
                  onClick={() => void handleLiveNotificationToggle()}
                  disabled={!pushSupported || pushLoading}
                  className="inline-flex items-center justify-center rounded-2xl border border-[#D4A73C]/30 px-8 py-4 text-sm font-bold text-[#D4A73C] transition hover:bg-[#FFF7E5] disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {!pushSupported
                    ? t("home_sections.notifications_unsupported")
                    : pushLoading
                      ? t("home_sections.please_wait")
                      : pushSubscribed
                        ? t("home_sections.disable_alerts")
                        : t("home_sections.notify_me")}
                </button>
              </div>
              {pushSupported && !liveSession && (
                <p className="text-xs leading-6 text-gray-500">
                  {pushPermission === "denied"
                    ? "Browser notifications are blocked. Enable them in browser settings to receive live alerts."
                    : "This browser can subscribe to live-start alerts and open the live room directly from the notification."}
                </p>
              )}
            </div>
          </div>
        </div>

        {loading ? (
          <div className="flex items-center justify-center py-20">
            <div className="h-12 w-12 animate-spin rounded-full border-b-2 border-[#D4A73C]" />
          </div>
        ) : astrologers.length > 0 ? (
          <div>
            <div className="mb-10 mt-10 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
              <div className="flex items-center gap-4">
                <div className="h-8 w-1 rounded-full bg-[#D4A73C]" />
                <div>
                  <p className="text-[11px] font-black uppercase tracking-[0.22em] text-[#D4A73C]">{t("home_sections.astrologer_eyebrow")}</p>
                  <h2 className="mt-2 text-2xl font-black tracking-tight text-[#1E3557]">{t("home_sections.astrologer_title")}</h2>
                </div>
              </div>

              <button
                type="button"
                onClick={() => {
                  notify(t("main.notif_all_astrologers"));
                  navigate("/astrologers");
                }}
                className="rounded-xl border border-[#D4A73C]/20 px-4 py-2 text-[11px] font-black uppercase tracking-[0.2em] text-[#D4A73C] transition hover:bg-[#D4A73C]/5 hover:text-[#b8860b]"
              >
                {t("main.show_all")}
              </button>
            </div>

            <div className="grid grid-cols-1 gap-8 sm:grid-cols-2 md:grid-cols-3">
              {astrologers.map((astro, index) => {
                const current = activeBtn[index] || "book";
                const details = astro.astrologer_detail || {};

                return (
                  <div key={astro.id} className="rounded-2xl border border-[#EEE7D6] bg-white p-5 shadow-sm transition hover:shadow-md">
                    <div className="flex items-center gap-3">
                      <img
                        src={getImageUrl(details.profile_image, index === 0 ? astro1 : index === 1 ? astro2 : astro3)}
                        className="h-14 w-14 rounded-full bg-gray-50 object-cover"
                        alt={astro.name}
                      />

                      <div className="min-w-0 flex-1">
                        <h3 className="flex items-center gap-2 truncate text-sm font-medium text-[#2B2B2B]">
                          {astro.name}
                          {liveSession?.astrologer?.id === astro.id && (
                            <span className="animate-pulse rounded-sm bg-red-500 px-1.5 py-0.5 text-[8px] uppercase tracking-wider text-white">
                              Live
                            </span>
                          )}
                        </h3>
                        <p className="truncate text-[11px] text-[#9A9A9A]">
                          {details.specialities || t("main.astrology")}
                        </p>
                        <p className="text-[11px] text-[#9A9A9A]">
                          {details.experience_years || 0} {t("main.years_exp")}
                        </p>
                        <p className="mt-1 text-[11px] text-[#9A9A9A]">{formatRatingText(details)}</p>
                        <AstrologerStatusBadge status={astro.availability_status} className="mt-2" />
                      </div>

                      <span className={`ml-auto flex-shrink-0 text-xs font-medium ${hasRealRating(details) ? "text-[#D4A73C]" : "text-gray-400"}`}>
                        {formatRatingBadge(details)}
                      </span>
                    </div>

                    <div className="mt-5 flex justify-between text-[10px] text-[#9A9A9A]">
                      <span>{t("main.chat_price")}</span>
                      <span>{t("main.call_price")}</span>
                    </div>

                    <div className="mt-1 flex justify-between text-[14px] font-semibold text-[#2B2B2B]">
                      <span>Rs {details.chat_price || 0}/min</span>
                      <span>Rs {details.call_price || 0}/min</span>
                    </div>

                    <div className="mt-5 flex flex-col justify-between gap-2 sm:flex-row">
                      <button
                        type="button"
                        onClick={() => {
                          notify(t("main.notif_profile"));
                          setActiveBtn({ ...activeBtn, [index]: "view" });
                          navigate(`/profile/${astro.id}`, { state: { msg: "Viewing Profile..." } });
                        }}
                        className={`flex-1 rounded-lg py-2.5 text-xs font-medium transition ${
                          current === "view" ? "bg-[#d8ba4a] text-white shadow-sm" : "bg-[#F8F6F1] text-[#d8ba4a]"
                        }`}
                      >
                        {t("main.view_profile")}
                      </button>

                      <button
                        type="button"
                        onClick={() => {
                          notify(t("main.notif_consultation"));
                          setActiveBtn({ ...activeBtn, [index]: "book" });
                          navigate(`/consultation/${astro.id}`, { state: { type: "chat", astrologer: astro } });
                        }}
                        className={`flex-1 rounded-lg py-2.5 text-xs font-medium transition ${
                          current === "book" ? "bg-[#d8ba4a] text-black shadow-sm" : "bg-[#F8F6F1] text-[#2C2C2C]"
                        }`}
                      >
                        {t("main.book_consultation")}
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        ) : null}
      </div>
    </section>
  );
}
