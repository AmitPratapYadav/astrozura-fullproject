import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { Search } from "lucide-react";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { getBlogCategories, getBlogs } from "../api/blogApi";

const API_ORIGIN = import.meta.env.VITE_API_BASE_URL
  ? import.meta.env.VITE_API_BASE_URL.replace(/\/api\/?$/, "")
  : "";

const assetUrl = (path) => {
  if (!path) return "";
  if (/^https?:\/\//i.test(path)) return path;
  return `${API_ORIGIN}${path.startsWith("/") ? path : `/${path}`}`;
};

const formatDate = (value) => {
  if (!value) return "";
  try {
    return new Date(value).toLocaleDateString("en-IN", {
      day: "2-digit",
      month: "short",
      year: "numeric",
    });
  } catch {
    return "";
  }
};

export default function Blogs() {
  const [categories, setCategories] = useState([]);
  const [blogs, setBlogs] = useState([]);
  const [selectedCategory, setSelectedCategory] = useState("");
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState("");

  const activeCategoryName = useMemo(() => {
    if (!selectedCategory) return "All Topics";
    return categories.find((category) => category.slug === selectedCategory)?.name || "Selected Topic";
  }, [categories, selectedCategory]);

  useEffect(() => {
    let mounted = true;
    getBlogCategories()
      .then((response) => {
        if (mounted) setCategories(response?.data || []);
      })
      .catch(() => {
        if (mounted) setCategories([]);
      });
    return () => {
      mounted = false;
    };
  }, []);

  useEffect(() => {
    let mounted = true;
    setLoading(true);
    getBlogs({
      category: selectedCategory || undefined,
      search: search || undefined,
      per_page: 12,
    })
      .then((response) => {
        if (!mounted) return;
        setBlogs(response?.data?.data || response?.data || []);
        setMessage("");
      })
      .catch(() => {
        if (!mounted) return;
        setBlogs([]);
        setMessage("Unable to load blogs right now.");
      })
      .finally(() => {
        if (mounted) setLoading(false);
      });
    return () => {
      mounted = false;
    };
  }, [selectedCategory, search]);

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-[#1E3557]">
      <Navbar />

      <section className="bg-[#1E3557] px-6 py-14 text-white">
        <div className="mx-auto max-w-7xl">
          <p className="text-sm font-black uppercase tracking-[0.32em] text-[#D4A73C]">AstroZura Journal</p>
          <h1 className="mt-3 text-4xl font-black md:text-6xl">Blogs</h1>
          <p className="mt-4 max-w-2xl text-lg leading-8 text-white/80">
            Read practical astrology guides, Panchang explainers, rituals, remedies, and cosmic lifestyle notes.
          </p>
        </div>
      </section>

      <main className="mx-auto grid max-w-7xl gap-8 px-6 py-10 lg:grid-cols-[280px_1fr]">
        <aside className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="mb-6">
            <h2 className="text-2xl font-black text-slate-950">Categories</h2>
            <p className="mt-1 text-sm text-slate-500">Select Topic</p>
          </div>
          <div className="space-y-2">
            <button
              type="button"
              onClick={() => setSelectedCategory("")}
              className={`w-full rounded-xl px-4 py-3 text-left font-semibold transition ${
                selectedCategory === "" ? "bg-[#D4A73C] text-[#1E3557]" : "hover:bg-slate-50"
              }`}
            >
              Home
            </button>
            {categories.map((category) => (
              <button
                key={category.id}
                type="button"
                onClick={() => setSelectedCategory(category.slug)}
                className={`w-full rounded-xl px-4 py-3 text-left font-semibold transition ${
                  selectedCategory === category.slug ? "bg-[#D4A73C] text-[#1E3557]" : "hover:bg-slate-50"
                }`}
              >
                {category.name}
              </button>
            ))}
          </div>
        </aside>

        <section>
          <div className="mb-7 flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div>
              <p className="text-sm font-bold uppercase tracking-[0.24em] text-[#D4A73C]">{activeCategoryName}</p>
              <h2 className="mt-1 text-3xl font-black text-slate-950">Latest Articles</h2>
            </div>
            <label className="flex h-12 min-w-[280px] items-center rounded-xl border border-slate-200 bg-white px-4 shadow-sm">
              <Search size={18} className="mr-3 text-slate-400" />
              <input
                value={search}
                onChange={(event) => setSearch(event.target.value)}
                placeholder="Find what you're looking for..."
                className="w-full bg-transparent text-sm outline-none"
              />
            </label>
          </div>

          {message ? <div className="mb-5 rounded-xl bg-rose-50 px-4 py-3 text-sm font-semibold text-rose-700">{message}</div> : null}
          {loading ? <div className="rounded-xl bg-white px-4 py-6 text-sm font-semibold text-slate-500">Loading blogs...</div> : null}

          <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
            {blogs.map((blog) => (
              <Link
                key={blog.id}
                to={`/blogs/${blog.slug}`}
                className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm transition hover:-translate-y-1 hover:shadow-lg"
              >
                <div className="aspect-[16/10] bg-slate-100">
                  {blog.cover_image ? (
                    <img src={assetUrl(blog.cover_image)} alt={blog.title} className="h-full w-full object-cover" />
                  ) : (
                    <div className="flex h-full items-center justify-center bg-[#1E3557] text-5xl font-black text-[#D4A73C]">AZ</div>
                  )}
                </div>
                <div className="p-5">
                  <p className="text-xs font-black uppercase tracking-[0.18em] text-[#D4A73C]">{blog.category?.name || "Astrology"}</p>
                  <h3 className="mt-2 line-clamp-2 text-xl font-black text-[#1E3557]">{blog.title}</h3>
                  <p className="mt-3 line-clamp-2 text-sm leading-6 text-slate-500">{blog.excerpt}</p>
                  <div className="mt-5 flex items-center justify-between text-sm text-slate-500">
                    <span>{blog.author_name || "AstroZura Team"}</span>
                    <span>{formatDate(blog.published_at)}</span>
                  </div>
                </div>
              </Link>
            ))}
          </div>

          {!loading && blogs.length === 0 ? (
            <div className="rounded-2xl bg-white px-6 py-12 text-center text-slate-500">No blogs found for this selection.</div>
          ) : null}
        </section>
      </main>

      <Footer />
    </div>
  );
}
