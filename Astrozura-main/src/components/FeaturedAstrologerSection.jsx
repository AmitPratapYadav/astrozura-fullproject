import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { API_BASE_URL } from "../utils/apiBase";

const getImageUrl = (path, fallback) => {
  if (!path) return fallback;
  if (path.startsWith("http")) return path;
  const baseUrl = import.meta.env.VITE_BACKEND_URL || "https://astrozura.com";
  return `${baseUrl}${path.startsWith("/") ? path : `/${path}`}`;
};

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

const FOUNDER_TAGLINE = "Align Your Stars. Engineer Your Destiny.";
const FOUNDER_DISPLAY_NAME = "Meet Ananya Gupta (Astrotarsh)";
const FOUNDER_QUOTE =
  "Astrology is not just about predicting the future; it's about decoding the blueprint of your soul.";

export default function FeaturedAstrologerSection() {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const [featured, setFeatured] = useState(null);
  const [loadingFeatured, setLoadingFeatured] = useState(true);
  const [msg, setMsg] = useState("");

  useEffect(() => {
    const fetchFeaturedAstrologer = async () => {
      try {
        const response = await fetch(`${API_BASE_URL}/astrologers?la=${i18n.language === "hi" ? "hi" : "en"}`);
        const data = await response.json();

        const list = data.astrologers || data.data?.data || data.data || [];
        if (!Array.isArray(list)) return;
        const sorted = [...list].sort(
          (left, right) =>
            parseFloat(right.astrologer_detail?.rating || 0) -
            parseFloat(left.astrologer_detail?.rating || 0)
        );

        setFeatured(list.find((item) => item.astrologer_detail?.is_featured) || sorted[0] || null);
      } catch (error) {
        console.error("Failed to load featured astrologer", error);
      } finally {
        setLoadingFeatured(false);
      }
    };

    void fetchFeaturedAstrologer();
  }, [i18n.language]);

  const notify = (text) => {
    setMsg(text);
    window.setTimeout(() => setMsg(""), 2000);
  };

  const featuredDetails = featured?.astrologer_detail || {};
  const featuredImage = getImageUrl(featured?.profile_image || featuredDetails.profile_image, "");
  const featuredHighlights = useMemo(() => {
    const merged = [
      ...(featuredDetails.specialities?.split(",").map((item) => item.trim()).filter(Boolean) || []),
      ...(featuredDetails.languages?.split(",").map((item) => item.trim()).filter(Boolean) || []),
    ];

    return merged.slice(0, 4);
  }, [featuredDetails.languages, featuredDetails.specialities]);

  return (
    <section className="bg-gradient-to-b from-[#FAF7F2] to-[#F8F5EF] px-4 py-10 md:px-10 md:py-14">
      {msg && (
        <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-md bg-[#d8b14a] px-5 py-2 text-xs text-white shadow">
          {msg}
        </div>
      )}

      <div className="mx-auto max-w-[1200px]">
        {loadingFeatured ? (
          <div className="grid items-center gap-10 overflow-hidden rounded-[2rem] border border-[#EEE7D6] bg-white p-8 shadow-[0_20px_50px_rgba(0,0,0,0.04)] md:grid-cols-2 md:p-12 lg:p-14">
            <div className="h-[300px] animate-pulse rounded-3xl bg-[#EFE7D8] sm:h-[350px] md:h-[450px]" />
            <div className="space-y-5">
              <div className="h-8 w-40 animate-pulse rounded-full bg-[#F0E6D2]" />
              <div className="h-14 w-3/4 animate-pulse rounded-2xl bg-[#EFE7D8]" />
              <div className="h-5 w-1/2 animate-pulse rounded-full bg-[#F0E6D2]" />
              <div className="h-28 w-full animate-pulse rounded-2xl bg-[#F7F1E7]" />
            </div>
          </div>
        ) : featured ? (
        <div className="group relative grid items-center gap-10 overflow-hidden rounded-[2rem] border border-[#EEE7D6] bg-gradient-to-r from-[#FDFCFB] via-[#F9F6F0] to-[#FDFCFB] p-8 shadow-[0_20px_50px_rgba(0,0,0,0.04)] md:grid-cols-2 md:gap-16 md:p-12 lg:p-14">
          <div className="absolute -right-16 -top-16 h-32 w-32 rounded-full bg-[#D4A73C]/5 blur-3xl" />

          <div className="relative">
            {featuredImage ? (
              <img
                src={featuredImage}
                className="h-[300px] w-full rounded-3xl border-2 border-white bg-white object-cover object-top shadow-2xl ring-1 ring-[#D4A73C]/20 transition-transform duration-500 group-hover:scale-[1.02] sm:h-[350px] md:h-[450px]"
                alt={featured.name || "Featured astrologer"}
              />
            ) : (
              <div className="flex h-[300px] w-full items-center justify-center rounded-3xl border-2 border-white bg-[#1E3557] text-7xl font-black text-[#D4A73C] shadow-2xl ring-1 ring-[#D4A73C]/20 sm:h-[350px] md:h-[450px]">
                {featured.name?.charAt(0)?.toUpperCase() || "AZ"}
              </div>
            )}
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
              Meet Ananya Gupta <br />
              <span className="text-[#D4A73C] drop-shadow-sm">(Astrotarsh)</span>
            </h2>

            <p className="mb-2 text-xs font-black uppercase tracking-[0.24em] text-[#D4A73C]">{FOUNDER_TAGLINE}</p>
            <p className="mb-3 text-lg font-bold text-[#b8860b]">
              {(featured?.name || "").toLowerCase().includes("ananya")
                ? "Ananya Gupta"
                : featured?.name || "Featured Astrologer"}
            </p>
            <p className="mb-6 text-sm font-semibold text-gray-500">{formatRatingText(featuredDetails)}</p>

            <div className="relative">
              <div className="absolute bottom-0 left-0 top-0 w-1 rounded-full bg-[#D4A73C]" />
              <p className="pl-6 text-sm font-medium italic leading-loose text-gray-500 md:text-base">
                "{featuredDetails.about_bio || FOUNDER_QUOTE}"
              </p>
              {featuredDetails.about_bio ? (
                <p className="mt-4 pl-6 text-sm font-black leading-6 text-[#1E3557] md:text-base">
                  "{FOUNDER_QUOTE}"
                </p>
              ) : null}
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
        ) : null}
      </div>
    </section>
  );
}
