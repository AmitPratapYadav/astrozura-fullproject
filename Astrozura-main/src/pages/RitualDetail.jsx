import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import poojaRitual from "../assets/pooja ritual.png";
import bhagwat from "../assets/bhagwat.png";
import lamp from "../assets/lamp.png";
import astro1 from "../assets/astro1.png";
import astro2 from "../assets/astro2.png";
import astro3 from "../assets/astro3.png";

const API_BASE = import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000/api";
const BACKEND_BASE = import.meta.env.VITE_BACKEND_URL || "http://127.0.0.1:8000";
const ritualFallbacks = [poojaRitual, bhagwat, lamp];
const astrologerFallbacks = [astro1, astro2, astro3];

const getImageUrl = (path, fallback) => {
  if (!path) return fallback;
  if (path.startsWith("http")) return path;
  return `${BACKEND_BASE}${path.startsWith("/") ? path : `/${path}`}`;
};

export default function RitualDetail() {
  const { slug } = useParams();
  const navigate = useNavigate();
  const [ritual, setRitual] = useState(null);
  const [recommendedAstrologers, setRecommendedAstrologers] = useState([]);
  const [similarRituals, setSimilarRituals] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadDetails = async () => {
      try {
        const response = await fetch(`${API_BASE}/rituals/${slug}`);
        const data = await response.json();
        if (data.success) {
          setRitual(data.ritual);
          setRecommendedAstrologers(data.recommended_astrologers || []);
          setSimilarRituals(data.similar_rituals || []);
        }
      } catch (error) {
        console.error("Failed to load ritual details", error);
      } finally {
        setLoading(false);
      }
    };

    void loadDetails();
  }, [slug]);

  const primaryAstrologer = ritual?.assigned_astrologer || recommendedAstrologers[0] || null;

  if (loading) {
    return (
      <div className="min-h-screen bg-[#faf8f3]">
        <Navbar />
        <div className="flex items-center justify-center py-32">
          <div className="h-12 w-12 animate-spin rounded-full border-b-2 border-[#D4A73C]"></div>
        </div>
      </div>
    );
  }

  if (!ritual) {
    return (
      <div className="min-h-screen bg-[#faf8f3]">
        <Navbar />
        <div className="mx-auto max-w-4xl px-4 py-24 text-center">
          <h1 className="text-4xl font-black text-[#1E3557]">Ritual not found</h1>
          <p className="mt-4 text-gray-500">The requested pooja or anusthan could not be loaded.</p>
          <Link to="/rituals" className="mt-6 inline-flex rounded-xl bg-[#1E3557] px-5 py-3 text-white">
            Back to Ritual Catalog
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#faf8f3] text-[#1E3557]">
      <Navbar />

      <section className="relative overflow-hidden bg-[#13294b] text-white">
        <div className="absolute inset-0 bg-gradient-to-r from-[#13294b] via-[#13294b]/90 to-[#13294b]/65"></div>
        <img
          src={getImageUrl(ritual.image, ritualFallbacks[0])}
          alt={ritual.name}
          className="absolute inset-0 h-full w-full object-cover opacity-25"
        />
        <div className="relative mx-auto max-w-7xl px-4 py-16 md:px-8">
          <p className="text-xs font-semibold uppercase tracking-[0.22em] text-[#D4A73C]">{ritual.category}</p>
          <h1 className="mt-4 max-w-3xl text-4xl font-black md:text-5xl">{ritual.name}</h1>
          <p className="mt-4 max-w-2xl text-sm leading-7 text-slate-200 md:text-base">{ritual.short_description}</p>
          <div className="mt-6 flex flex-wrap gap-4 text-sm">
            <span className="rounded-full bg-white/10 px-4 py-2">{ritual.mode}</span>
            <span className="rounded-full bg-white/10 px-4 py-2">{ritual.duration_label}</span>
            <span className="rounded-full bg-[#D4A73C] px-4 py-2 font-bold text-[#1E3557]">
              Rs {Number(ritual.price || 0).toLocaleString("en-IN")}
            </span>
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-4 py-10 md:px-8">
        <div className="grid gap-8 xl:grid-cols-[1fr_320px]">
          <main className="space-y-8">
            <div className="rounded-3xl border border-[#efe4d2] bg-white p-6 shadow-sm">
              <h2 className="text-2xl font-bold">About the Ritual</h2>
              <p className="mt-4 text-sm leading-7 text-gray-600">{ritual.description}</p>
            </div>

            <div className="rounded-3xl border border-[#efe4d2] bg-white p-6 shadow-sm">
              <h2 className="text-2xl font-bold">Ritual Steps</h2>
              <div className="mt-5 space-y-4">
                {(ritual.steps || []).map((step, index) => (
                  <div key={`${step}-${index}`} className="rounded-2xl bg-[#fffaf0] px-4 py-4">
                    <p className="text-sm font-semibold text-[#D4A73C]">Step {index + 1}</p>
                    <p className="mt-2 text-sm leading-6 text-gray-600">{step}</p>
                  </div>
                ))}
              </div>
            </div>

            <div className="grid gap-6 md:grid-cols-2">
              <div className="rounded-3xl border border-[#efe4d2] bg-white p-6 shadow-sm">
                <h2 className="text-2xl font-bold">Materials & Forms</h2>
                <p className="mt-3 text-sm leading-6 text-gray-600">{ritual.materials_required}</p>
                <div className="mt-4 space-y-2 text-sm text-gray-600">
                  {(ritual.materials || []).map((item, index) => (
                    <p key={`${item}-${index}`}>- {item}</p>
                  ))}
                </div>
              </div>

              <div className="rounded-3xl border border-[#efe4d2] bg-white p-6 shadow-sm">
                <h2 className="text-2xl font-bold">Sacred Mantras</h2>
                <div className="mt-4 space-y-3">
                  {(ritual.mantras || []).map((item, index) => (
                    <div
                      key={`${item}-${index}`}
                      className="rounded-2xl bg-[#fffaf0] px-4 py-3 text-sm leading-6 text-gray-600"
                    >
                      {item}
                    </div>
                  ))}
                </div>
              </div>
            </div>

            <div className="rounded-3xl border border-[#efe4d2] bg-white p-6 shadow-sm">
              <h2 className="text-2xl font-bold">Frequently Asked Questions</h2>
              <div className="mt-5 space-y-3">
                {(ritual.faqs || []).map((faq, index) => (
                  <details key={`${faq.question}-${index}`} className="rounded-2xl border border-gray-100 px-4 py-4">
                    <summary className="cursor-pointer text-sm font-semibold text-[#1E3557]">{faq.question}</summary>
                    <p className="mt-3 text-sm leading-6 text-gray-600">{faq.answer}</p>
                  </details>
                ))}
              </div>
            </div>

            {!!similarRituals.length && (
              <div className="rounded-3xl border border-[#efe4d2] bg-white p-6 shadow-sm">
                <div className="flex items-center justify-between gap-4">
                  <h2 className="text-2xl font-bold">Similar Auspicious Rituals</h2>
                  <Link to="/rituals" className="text-sm font-semibold text-[#D4A73C]">
                    View all rituals
                  </Link>
                </div>
                <div className="mt-6 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
                  {similarRituals.map((item, index) => (
                    <Link key={item.id} to={`/rituals/${item.slug}`} className="overflow-hidden rounded-2xl border border-gray-100">
                      <img
                        src={getImageUrl(item.image, ritualFallbacks[index % ritualFallbacks.length])}
                        alt={item.name}
                        className="h-28 w-full object-cover"
                      />
                      <div className="p-3">
                        <p className="text-sm font-semibold leading-5">{item.name}</p>
                        <p className="mt-1 text-xs text-[#D4A73C]">
                          Rs {Number(item.price || 0).toLocaleString("en-IN")}
                        </p>
                      </div>
                    </Link>
                  ))}
                </div>
              </div>
            )}
          </main>

          <aside className="space-y-6">
            <div className="sticky top-24 rounded-3xl border border-[#efe4d2] bg-white p-5 shadow-sm">
              {primaryAstrologer && (
                <div className="rounded-2xl border border-gray-100 p-4">
                  <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[#D4A73C]">Ritual Guide</p>
                  <div className="mt-4 flex items-center gap-3">
                    <img
                      src={getImageUrl(primaryAstrologer.astrologer_detail?.profile_image, astrologerFallbacks[0])}
                      alt={primaryAstrologer.name}
                      className="h-14 w-14 rounded-full object-cover"
                    />
                    <div>
                      <p className="font-semibold">{primaryAstrologer.name}</p>
                      <p className="text-xs text-gray-500">
                        {primaryAstrologer.astrologer_detail?.specialities || "Vedic Ritual Specialist"}
                      </p>
                    </div>
                  </div>
                </div>
              )}

              <div className="mt-5 rounded-2xl bg-[#fffaf0] p-4">
                <p className="text-xs font-semibold uppercase tracking-[0.18em] text-gray-400">Reserve Ritual Slot</p>
                <div className="mt-4 space-y-3 text-sm text-gray-600">
                  <div className="flex justify-between">
                    <span>Duration</span>
                    <span className="font-semibold text-[#1E3557]">{ritual.duration_label}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Mode</span>
                    <span className="font-semibold text-[#1E3557]">{ritual.mode}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Ideal Timing</span>
                    <span className="text-right font-semibold text-[#1E3557]">{ritual.ideal_timing}</span>
                  </div>
                  <div className="flex justify-between">
                    <span>Total Amount</span>
                    <span className="font-bold text-[#1E3557]">Rs {Number(ritual.price || 0).toLocaleString("en-IN")}</span>
                  </div>
                </div>

                <div className="mt-5 rounded-2xl border border-[#F1E1B8] bg-white p-4">
                  <p className="text-xs font-semibold uppercase tracking-[0.18em] text-[#D4A73C]">Offline Ritual Note</p>
                  <p className="mt-3 text-sm leading-6 text-gray-600">
                    If the ritual is performed offline at the client&apos;s location, priest travel and accommodation expenses will be borne by the client.
                  </p>
                </div>

                <Link
                  to={`/rituals/${ritual.slug}/book`}
                  className="mt-5 inline-flex w-full items-center justify-center rounded-xl bg-[#D4A73C] px-4 py-3 text-sm font-bold text-[#1E3557]"
                >
                  Continue to Ritual Booking
                </Link>
              </div>

              {!!recommendedAstrologers.length && (
                <div className="mt-5">
                  <p className="text-sm font-semibold">Recommended Astrologers</p>
                  <div className="mt-3 space-y-3">
                    {recommendedAstrologers.map((astro, index) => (
                      <button
                        key={astro.id}
                        type="button"
                        onClick={() => navigate(`/profile/${astro.id}`)}
                        className="flex w-full items-center gap-3 rounded-2xl border border-gray-100 px-3 py-3 text-left transition hover:border-[#D4A73C]"
                      >
                        <img
                          src={getImageUrl(
                            astro.astrologer_detail?.profile_image,
                            astrologerFallbacks[index % astrologerFallbacks.length]
                          )}
                          alt={astro.name}
                          className="h-11 w-11 rounded-full object-cover"
                        />
                        <div className="min-w-0">
                          <p className="truncate font-semibold">{astro.name}</p>
                          <p className="truncate text-xs text-gray-500">
                            {astro.astrologer_detail?.specialities || "Astrology Specialist"}
                          </p>
                        </div>
                      </button>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </aside>
        </div>
      </section>

      <Footer />
    </div>
  );
}
