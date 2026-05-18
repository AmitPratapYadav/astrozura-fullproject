import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
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

export default function Rituals() {
  const navigate = useNavigate();
  const [rituals, setRituals] = useState([]);
  const [pagination, setPagination] = useState(null);
  const [categories, setCategories] = useState([]);
  const [search, setSearch] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("");
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true);
  const [searching, setSearching] = useState(false);
  const [experts, setExperts] = useState([]);

  useEffect(() => {
    const fetchExperts = async () => {
      try {
        const response = await fetch(`${API_BASE}/astrologers`);
        const data = await response.json();
        if (data.success) setExperts((data.astrologers || []).slice(0, 3));
      } catch (error) {
        console.error("Failed to load astrologers for rituals page", error);
      }
    };

    void fetchExperts();
  }, []);

  useEffect(() => {
    const timeoutId = window.setTimeout(async () => {
      try {
        setSearching(true);
        const params = new URLSearchParams();
        if (search.trim()) params.set("q", search.trim());
        if (selectedCategory) params.set("category", selectedCategory);
        params.set("per_page", "12");
        params.set("page", String(page));
        const response = await fetch(`${API_BASE}/rituals?${params.toString()}`);
        const data = await response.json();
        if (data.success) {
          setRituals(data.rituals.data || []);
          setPagination(data.rituals);
          setCategories(data.categories || []);
        }
      } catch (error) {
        console.error("Failed to load rituals", error);
      } finally {
        setLoading(false);
        setSearching(false);
      }
    }, 250);

    return () => window.clearTimeout(timeoutId);
  }, [search, selectedCategory, page]);

  const ritualCountLabel = useMemo(() => {
    if (!pagination) return "Services Available";
    return `${pagination.total} Services Available`;
  }, [pagination]);

  return (
    <div className="min-h-screen bg-[#faf8f3] text-[#1E3557]">
      <Navbar />

      <section className="max-w-7xl mx-auto px-4 md:px-8 py-10">
        <div className="grid gap-8 lg:grid-cols-[280px_1fr]">
          <aside className="space-y-5">
            <div className="rounded-3xl bg-white p-5 shadow-sm border border-[#efe4d2]">
              <p className="text-[11px] font-semibold uppercase tracking-[0.2em] text-[#D4A73C]">Ask the Experts</p>
              <div className="mt-5 space-y-3">
                {experts.map((astro, index) => (
                  <button
                    key={astro.id}
                    type="button"
                    onClick={() => navigate(`/profile/${astro.id}`)}
                    className="flex w-full items-center gap-3 rounded-2xl border border-gray-100 px-3 py-3 text-left hover:border-[#D4A73C] hover:bg-[#fffaf0] transition"
                  >
                    <img
                      src={getImageUrl(astro.astrologer_detail?.profile_image, astrologerFallbacks[index % astrologerFallbacks.length])}
                      alt={astro.name}
                      className="h-12 w-12 rounded-full object-cover"
                    />
                    <div className="flex-1 min-w-0">
                      <p className="font-semibold truncate">{astro.name}</p>
                      <p className="text-xs text-gray-500 truncate">
                        {astro.astrologer_detail?.specialities || "Astrology Specialist"}
                      </p>
                    </div>
                    <span className="text-sm text-[#D4A73C]">{">"}</span>
                  </button>
                ))}
              </div>
            </div>

            <div className="rounded-3xl bg-[#223764] p-5 text-white shadow-sm">
              <p className="text-lg font-bold">Custom Rituals</p>
              <p className="mt-3 text-sm leading-6 text-slate-200">
                Need a specific pooja or priest-guided sankalp? Our team can design a suitable ritual plan for your family, house, or remedies.
              </p>
              <Link to="/contact-support" className="mt-5 inline-flex rounded-xl bg-[#D4A73C] px-4 py-3 text-sm font-bold text-[#1E3557]">
                Inquire Now
              </Link>
            </div>

            <div className="rounded-3xl bg-white p-5 shadow-sm border border-[#efe4d2]">
              <p className="text-sm font-semibold">Temple Verified</p>
              <p className="mt-2 text-sm text-gray-500 leading-6">
                All rituals are coordinated with certified priests and verified delivery processes following traditional Vedic guidelines.
              </p>
            </div>
          </aside>

          <main>
            <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
              <div>
                <p className="text-[11px] font-semibold uppercase tracking-[0.2em] text-[#D4A73C]">Rituals Catalog</p>
                <h1 className="mt-2 text-4xl font-black text-[#1E3557]">Pooja Anusthan</h1>
              </div>
              <span className="rounded-full border border-[#e7dcc8] bg-white px-4 py-2 text-sm text-gray-500">
                {ritualCountLabel}
              </span>
            </div>

            <div className="mt-6 rounded-3xl bg-white p-4 shadow-sm border border-[#efe4d2]">
              <div className="grid gap-3 md:grid-cols-[1.3fr_220px]">
                <input
                  value={search}
                  onChange={(event) => {
                    setSearch(event.target.value);
                    setPage(1);
                  }}
                  placeholder="Search by ritual name or category"
                  className="rounded-2xl border border-gray-200 px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                />
                <select
                  value={selectedCategory}
                  onChange={(event) => {
                    setSelectedCategory(event.target.value);
                    setPage(1);
                  }}
                  className="rounded-2xl border border-gray-200 px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                >
                  <option value="">All Rituals</option>
                  {categories.map((category) => (
                    <option key={category} value={category}>{category}</option>
                  ))}
                </select>
              </div>
            </div>

            {loading ? (
              <div className="flex items-center justify-center py-20">
                <div className="h-12 w-12 animate-spin rounded-full border-b-2 border-[#D4A73C]"></div>
              </div>
            ) : (
              <>
                {searching && <p className="mt-4 text-sm text-gray-500">Updating rituals...</p>}

                <div className="mt-8 grid gap-6 md:grid-cols-2 xl:grid-cols-3">
                  {rituals.map((ritual, index) => (
                    <div key={ritual.id} className="rounded-3xl border border-[#efe4d2] bg-white shadow-sm overflow-hidden">
                      <Link to={`/rituals/${ritual.slug}`} className="block">
                        <img src={getImageUrl(ritual.image, ritualFallbacks[index % ritualFallbacks.length])} alt={ritual.name} className="h-44 w-full object-cover transition duration-300 hover:scale-[1.02]" />
                      </Link>
                      <div className="p-5">
                        <div className="flex items-center justify-between gap-3">
                          <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-[#D4A73C]">{ritual.category}</p>
                          {ritual.is_popular && <span className="rounded-full bg-[#fff3da] px-2.5 py-1 text-[10px] font-bold uppercase text-[#c38a11]">Popular</span>}
                        </div>
                        <Link to={`/rituals/${ritual.slug}`} className="mt-3 block text-2xl font-bold leading-tight text-[#1E3557] transition hover:text-[#D4A73C]">
                          {ritual.name}
                        </Link>
                        <p className="mt-3 text-sm leading-6 text-gray-500">{ritual.short_description}</p>
                        <div className="mt-4 flex items-center justify-between text-sm text-gray-500">
                          <span>{ritual.duration_label}</span>
                          <span className="font-semibold text-[#1E3557]">Rs {Number(ritual.price || 0).toLocaleString("en-IN")}</span>
                        </div>
                        <div className="mt-5 grid grid-cols-2 gap-3">
                          <Link to={`/rituals/${ritual.slug}`} className="rounded-xl border border-[#1E3557] px-4 py-2.5 text-center text-sm font-semibold text-[#1E3557] hover:bg-[#1E3557] hover:text-white transition">
                            View Details
                          </Link>
                          <button type="button" onClick={() => navigate(`/rituals/${ritual.slug}/book`)} className="rounded-xl bg-[#1E3557] px-4 py-2.5 text-sm font-bold text-white">
                            Book Now
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>

                {!rituals.length && (
                  <div className="mt-10 rounded-3xl border border-dashed border-gray-300 bg-white px-6 py-16 text-center">
                    <p className="text-xl font-bold text-[#1E3557]">No rituals found</p>
                    <p className="mt-2 text-sm text-gray-500">Try a different search term or clear the category filter.</p>
                  </div>
                )}

                <div className="mt-12 rounded-3xl bg-[#fff9ef] p-6 shadow-sm border border-[#efe4d2]">
                  <h3 className="text-xl font-bold">Secure Your Spiritual Journey</h3>
                  <p className="mt-3 max-w-3xl text-sm leading-6 text-gray-600">
                    All bookings are end-to-end coordinated with local temple administrators or verified priests so your ritual is performed according to strict Vedic guidelines.
                  </p>
                </div>

                {pagination?.last_page > 1 && (
                  <div className="mt-8 flex items-center justify-center gap-3">
                    <button
                      type="button"
                      disabled={page <= 1}
                      onClick={() => setPage((current) => Math.max(1, current - 1))}
                      className="rounded-xl border border-gray-200 px-4 py-2 text-sm disabled:opacity-40"
                    >
                      Previous
                    </button>
                    <span className="text-sm text-gray-500">
                      Page {pagination.current_page} of {pagination.last_page}
                    </span>
                    <button
                      type="button"
                      disabled={page >= pagination.last_page}
                      onClick={() => setPage((current) => Math.min(pagination.last_page, current + 1))}
                      className="rounded-xl border border-gray-200 px-4 py-2 text-sm disabled:opacity-40"
                    >
                      Next
                    </button>
                  </div>
                )}
              </>
            )}
          </main>
        </div>
      </section>

      <Footer />
    </div>
  );
}
