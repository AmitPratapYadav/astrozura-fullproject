import { useEffect, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import axios from "axios";
import CatalogImage from "../components/CatalogImage";
import { assetUrl } from "../utils/assetUrl";

const apiUrl = import.meta.env.VITE_API_BASE_URL || "https://astrozura.com/apigateway/index.php/api";

export default function GuideBook() {
  const [searchParams] = useSearchParams();
  const [blogs, setBlogs] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const activeCategory = searchParams.get("category") || "";

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const [blogResponse, categoryResponse] = await Promise.all([
          axios.get(`${apiUrl}/blogs`, { params: { platform: "shop", category: activeCategory || undefined, per_page: 24 } }),
          axios.get(`${apiUrl}/blog-categories`, { params: { platform: "shop" } }),
        ]);
        setBlogs(blogResponse.data?.data?.data || []);
        setCategories(categoryResponse.data?.data || []);
      } finally {
        setLoading(false);
      }
    };
    void load();
  }, [activeCategory]);

  return (
    <main className="min-h-screen overflow-x-hidden bg-[#f8f9fc] px-4 py-12">
      <section className="mx-auto max-w-6xl">
        <div className="mb-8 flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.24em] text-[#D4A73C]">AstroZura Guide Book</p>
            <h1 className="mt-2 max-w-[340px] text-2xl font-black leading-tight text-[#1E3557] sm:max-w-none md:text-5xl">Shop with spiritual context</h1>
          </div>
          <Link to="/allproduct" className="w-fit rounded-full bg-[#1E3557] px-5 py-3 text-sm font-bold text-white">Explore Products</Link>
        </div>

        <div className="mb-8 flex gap-2 overflow-x-auto pb-2">
          <Link to="/guide-book" className={`whitespace-nowrap rounded-full px-4 py-2 text-sm font-bold ${!activeCategory ? "bg-[#1E3557] text-white" : "bg-white text-[#1E3557]"}`}>All Guides</Link>
          {categories.map((category) => (
            <Link key={category.id} to={`/guide-book?category=${category.slug}`} className={`whitespace-nowrap rounded-full px-4 py-2 text-sm font-bold ${activeCategory === category.slug ? "bg-[#1E3557] text-white" : "bg-white text-[#1E3557]"}`}>
              {category.name}
            </Link>
          ))}
        </div>

        {loading ? (
          <div className="rounded-2xl bg-white p-10 text-center text-gray-500">Loading guide book...</div>
        ) : blogs.length ? (
          <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {blogs.map((blog) => (
              <Link key={blog.id} to={`/guide-book/${blog.slug}`} className="overflow-hidden rounded-2xl bg-white shadow-sm transition hover:-translate-y-1 hover:shadow-lg">
                <CatalogImage src={assetUrl(blog.cover_image)} alt={blog.title} className="h-56 w-full object-cover" />
                <div className="p-5">
                  <p className="text-[10px] font-black uppercase tracking-[0.2em] text-[#D4A73C]">{blog.category?.name || "Guide"}</p>
                  <h2 className="mt-2 text-xl font-black text-[#1E3557]">{blog.title}</h2>
                  {blog.excerpt && <p className="mt-3 line-clamp-3 text-sm leading-6 text-gray-600">{blog.excerpt}</p>}
                </div>
              </Link>
            ))}
          </div>
        ) : (
          <div className="rounded-2xl bg-white p-10 text-center text-gray-500">No shop guides have been published yet.</div>
        )}
      </section>
    </main>
  );
}
