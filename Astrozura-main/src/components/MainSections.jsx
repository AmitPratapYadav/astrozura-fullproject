import { useEffect, useMemo, useState } from "react";
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

export default function MainSections() {
  const { t } = useTranslation();
  const navigate = useNavigate();

  const [msg, setMsg] = useState("");
  const [activeBtn, setActiveBtn] = useState({});
  const [astrologers, setAstrologers] = useState([]);
  const [featured, setFeatured] = useState(null);
  const [loading, setLoading] = useState(true);
  const [liveSession, setLiveSession] = useState(null);
  const [rituals, setRituals] = useState([]);
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
      try {
        const apiUrl = import.meta.env.VITE_API_BASE_URL || "http://localhost:8000/api";
        const response = await fetch(`${apiUrl}/astrologers`);
        const data = await response.json();

        if (!data.success) {
          return;
        }

        const list = data.astrologers || [];
        const sorted = [...list].sort(
          (left, right) =>
            parseFloat(right.astrologer_detail?.rating || 0) -
            parseFloat(left.astrologer_detail?.rating || 0)
        );

        setAstrologers(sorted.slice(0, 3));
        setFeatured(list.find((item) => item.astrologer_detail?.is_featured) || sorted[0] || null);
      } catch (error) {
        console.error("Failed to load top astrologers", error);
      } finally {
        setLoading(false);
      }
    };

    void fetchAstrologers();
  }, []);

  useEffect(() => {
    const fetchRituals = async () => {
      try {
        const apiUrl = import.meta.env.VITE_API_BASE_URL || "http://localhost:8000/api";
        const params = new URLSearchParams({ per_page: "4", page: "1" });
        const response = await fetch(`${apiUrl}/rituals?${params.toString()}`);
        const data = await response.json();

        if (data.success) {
          setRituals(data.rituals?.data || []);
        }
      } catch (error) {
        console.error("Failed to load rituals for homepage", error);
      }
    };

    void fetchRituals();
  }, []);

  useEffect(() => {
    let cancelled = false;

    const fetchLiveSession = async () => {
      try {
        const apiUrl = import.meta.env.VITE_API_BASE_URL || "http://localhost:8000/api";
        const response = await fetch(`${apiUrl}/live-sessions/current`);
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
    const baseUrl = import.meta.env.VITE_BACKEND_URL || "http://localhost:8000";
    return `${baseUrl}${path.startsWith("/") ? path : `/${path}`}`;
  };

  const ritualFallbacks = [poojaRitual, bhagwat, lamp];

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

  const featuredDetails = featured?.astrologer_detail || {};
  const featuredHighlights = useMemo(() => {
    const merged = [
      ...(featuredDetails.specialities?.split(",").map((item) => item.trim()).filter(Boolean) || []),
      ...(featuredDetails.languages?.split(",").map((item) => item.trim()).filter(Boolean) || []),
    ];

    return merged.slice(0, 4);
  }, [featuredDetails.languages, featuredDetails.specialities]);

  return (
    <section className="bg-gradient-to-b from-[#FAF7F2] via-[#F8F5EF] to-[#F8F5EF] px-4 py-14 md:px-10 sm:py-20">
      {msg && (
      <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-md bg-[#d8b14a] px-5 py-2 text-xs text-white shadow">
          {msg}
        </div>
      )}

      <div className="mx-auto w-full max-w-[1200px] space-y-20">
        <div className="group relative grid items-center gap-10 overflow-hidden rounded-[2rem] border border-[#EEE7D6] bg-gradient-to-r from-[#FDFCFB] via-[#F9F6F0] to-[#FDFCFB] p-8 shadow-[0_20px_50px_rgba(0,0,0,0.04)] md:grid-cols-2 md:gap-16 md:p-12 lg:p-14">
          <div className="absolute -right-16 -top-16 h-32 w-32 rounded-full bg-[#D4A73C]/5 blur-3xl" />

          <div className="relative">
            <img
              src={getImageUrl(featuredDetails.profile_image, astro1)}
              className="h-[300px] w-full rounded-3xl border-2 border-white bg-white object-cover object-top shadow-2xl ring-1 ring-[#D4A73C]/20 transition-transform duration-500 group-hover:scale-[1.02] sm:h-[350px] md:h-[450px]"
              alt={featured?.name || "Featured astrologer"}
            />
            <div className="absolute -bottom-6 -right-6 hidden rounded-2xl border border-gray-100 bg-white p-4 shadow-xl sm:block">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#1E3557] font-bold text-white">
                  {featuredDetails.experience_years || "5"}+
                </div>
                <div>
                  <p className="text-[10px] font-bold uppercase leading-none tracking-wider text-gray-400">Years of</p>
                  <p className="mt-1 text-xs font-bold text-[#1E3557]">Experience</p>
                </div>
              </div>
            </div>
          </div>

          <div className="relative">
            <span className="mb-6 inline-flex items-center gap-2 rounded-full border border-[#f3d38d]/50 bg-[#fdf2d9] px-4 py-1.5 text-[10px] font-bold uppercase tracking-widest text-[#b8860b] shadow-sm">
              <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-[#D4A73C]" />
              {t("main.the_mastermind")}
            </span>

            <h2 className="mb-2 text-3xl font-black leading-[1.1] text-[#1E3557] md:text-5xl">
              {t("main.founder_title_start")} <br />
              <span className="text-[#D4A73C] drop-shadow-sm">{t("main.founder_title_end")}</span>
            </h2>

            <p className="mb-3 text-lg font-bold text-[#b8860b]">{featured?.name || "Featured Astrologer"}</p>
            <p className="mb-6 text-sm font-semibold text-gray-500">{formatRatingText(featuredDetails)}</p>

            <div className="relative">
              <div className="absolute bottom-0 left-0 top-0 w-1 rounded-full bg-[#D4A73C]" />
              <p className="pl-6 text-sm font-medium italic leading-loose text-gray-500 md:text-base">
                "{featuredDetails.about_bio || t("main.founder_quote")}"
              </p>
            </div>

            <div className="mt-10 grid grid-cols-2 gap-x-8 gap-y-6">
              {(featuredHighlights.length
                ? featuredHighlights
                : [t("main.vedic_astrology"), t("main.lal_kitab_rem"), t("main.numerology"), t("main.palmistry")]
              ).map((label, index) => (
                <div key={`${label}-${index}`} className="flex items-center gap-3">
                  <div className="flex h-8 w-8 items-center justify-center rounded-lg border border-[#EEE7D6] bg-[#FAF7F2] text-sm shadow-sm">
                    {["*", "O", "+", "~"][index % 4]}
                  </div>
                  <span className="text-xs font-bold text-[#1E3557] opacity-80">{label}</span>
                </div>
              ))}
            </div>

            <div className="mt-10">
              <button
                type="button"
                onClick={() => {
                  notify(t("main.notif_booking"));
                  if (featured?.id) {
                    navigate(`/consultation/${featured.id}`, { state: { astrologer: featured } });
                    return;
                  }

                  navigate("/astrologers");
                }}
                className="flex items-center gap-3 rounded-2xl bg-[#1E3557] px-10 py-4 text-sm font-black text-white shadow-2xl shadow-[#1E3557]/20 transition-all hover:-translate-y-1 hover:bg-[#162a45] active:scale-95"
              >
                Book a Consultation
                <span className="text-xs opacity-50">-&gt;</span>
              </button>
            </div>
          </div>
        </div>

        {rituals.length > 0 && (
          <div>
            <div className="mb-8 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
              <div>
                <p className="text-[11px] font-black uppercase tracking-[0.22em] text-[#D4A73C]">Sacred Rituals</p>
                <h2 className="mt-2 text-3xl font-black tracking-tight text-[#1E3557]">Pooja Anusthan</h2>
                <p className="mt-2 max-w-2xl text-sm leading-6 text-gray-500">
                  Book priest-guided pooja and anusthan services for remedies, family wellbeing, and auspicious occasions.
                </p>
              </div>

              <Link
                to="/rituals"
                className="inline-flex items-center justify-center rounded-xl border border-[#D4A73C]/25 px-5 py-3 text-[11px] font-black uppercase tracking-[0.2em] text-[#D4A73C] transition hover:bg-[#D4A73C]/10 hover:text-[#b8860b]"
              >
                View All
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
                          Popular
                        </span>
                      )}
                    </div>
                    <Link to={`/rituals/${ritual.slug}`} className="mt-3 block text-xl font-black leading-tight text-[#1E3557] transition hover:text-[#D4A73C]">
                      {ritual.name}
                    </Link>
                    <p className="mt-3 line-clamp-2 text-sm leading-6 text-gray-500">{ritual.short_description}</p>
                    <div className="mt-4 flex items-center justify-between text-sm text-gray-500">
                      <span>{ritual.duration_label}</span>
                      <span className="font-bold text-[#1E3557]">Rs {Number(ritual.price || 0).toLocaleString("en-IN")}</span>
                    </div>
                    <div className="mt-5 grid grid-cols-2 gap-3">
                      <Link
                        to={`/rituals/${ritual.slug}`}
                        className="rounded-xl border border-[#1E3557] px-3 py-2.5 text-center text-xs font-bold text-[#1E3557] transition hover:bg-[#1E3557] hover:text-white"
                      >
                        View Details
                      </Link>
                      <button
                        type="button"
                        onClick={() => navigate(`/rituals/${ritual.slug}/book`)}
                        className="rounded-xl bg-[#1E3557] px-3 py-2.5 text-xs font-black text-white transition hover:bg-[#162a45]"
                      >
                        Book Now
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="overflow-hidden rounded-[2rem] border border-[#EEE7D6] bg-white shadow-sm">
          <div className="grid gap-0 lg:grid-cols-[1.25fr_0.75fr]">
            <div className="bg-gradient-to-br from-[#162744] via-[#1E3557] to-[#223C63] p-8 text-white md:p-10">
              <p className="inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/10 px-4 py-1.5 text-[11px] font-bold uppercase tracking-[0.22em]">
                <span className={`h-2 w-2 rounded-full ${liveSession ? "animate-pulse bg-red-400" : "bg-[#D4A73C]"}`} />
                {liveSession ? "Astro Zura Live" : "Live Sessions"}
              </p>
              <h2 className="mt-5 text-3xl font-black md:text-4xl">
                {liveSession ? liveSession.title : "No astrologer is live right now"}
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
                    ? "Open the live room to watch, comment, and interact in real time."
                    : "We will connect this block to Firebase web push notifications so visitors can subscribe and receive live-start alerts directly in the browser."}
                </p>
              </div>

              <div className="flex flex-col gap-3 sm:flex-row">
                <button
                  type="button"
                  onClick={() => navigate("/live")}
                  className="inline-flex items-center justify-center rounded-2xl bg-[#1E3557] px-8 py-4 text-sm font-black text-white shadow-xl shadow-[#1E3557]/20 transition hover:-translate-y-1 hover:bg-[#162a45]"
                >
                  {liveSession ? "Join Live Session" : "Open Live Page"}
                </button>
                <button
                  type="button"
                  onClick={() => void handleLiveNotificationToggle()}
                  disabled={!pushSupported || pushLoading}
                  className="inline-flex items-center justify-center rounded-2xl border border-[#D4A73C]/30 px-8 py-4 text-sm font-bold text-[#D4A73C] transition hover:bg-[#FFF7E5] disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {!pushSupported
                    ? "Notifications Unsupported"
                    : pushLoading
                      ? "Please Wait..."
                      : pushSubscribed
                        ? "Disable Alerts"
                        : "Notify Me"}
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
                <h2 className="text-2xl font-black tracking-tight text-[#1E3557]">{t("main.top_rated")}</h2>
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
