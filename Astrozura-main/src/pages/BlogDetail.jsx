import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { getBlog } from "../api/blogApi";

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
      month: "long",
      year: "numeric",
    });
  } catch {
    return "";
  }
};

function ContentBlock({ block, index }) {
  if (!block || !block.type) return null;

  if (block.type === "heading") {
    return <h2 className="mt-10 text-3xl font-black text-slate-950">{block.text}</h2>;
  }

  if (block.type === "image") {
    return (
      <figure className="my-8 overflow-hidden rounded-2xl border border-slate-200 bg-slate-50">
        <img src={assetUrl(block.url)} alt={block.alt || `Blog image ${index + 1}`} className="max-h-[520px] w-full object-cover" />
        {block.caption ? <figcaption className="px-5 py-3 text-sm text-slate-500">{block.caption}</figcaption> : null}
      </figure>
    );
  }

  return <p className="mt-5 text-lg leading-9 text-slate-600">{block.text}</p>;
}

export default function BlogDetail() {
  const { slug } = useParams();
  const [blog, setBlog] = useState(null);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState("");

  useEffect(() => {
    let mounted = true;
    setLoading(true);
    getBlog(slug)
      .then((response) => {
        if (!mounted) return;
        setBlog(response?.data || null);
        setMessage("");
      })
      .catch(() => {
        if (!mounted) return;
        setMessage("Unable to load this blog.");
      })
      .finally(() => {
        if (mounted) setLoading(false);
      });

    return () => {
      mounted = false;
    };
  }, [slug]);

  return (
    <div className="min-h-screen bg-[#FBF7F0] text-[#1E3557]">
      <Navbar />

      <main className="mx-auto max-w-4xl px-6 py-12">
        <Link to="/blogs" className="text-sm font-bold text-[#D4A73C] hover:text-[#1E3557]">
          Back to Blogs
        </Link>

        {loading ? <div className="mt-6 rounded-xl bg-white px-5 py-6 text-sm font-semibold text-slate-500">Loading blog...</div> : null}
        {message ? <div className="mt-6 rounded-xl bg-rose-50 px-5 py-4 text-sm font-semibold text-rose-700">{message}</div> : null}

        {blog ? (
          <article className="mt-6 overflow-hidden rounded-3xl bg-white shadow-sm">
            {blog.cover_image ? (
              <img src={assetUrl(blog.cover_image)} alt={blog.title} className="max-h-[520px] w-full object-cover" />
            ) : null}
            <div className="p-6 md:p-10">
              <p className="text-xs font-black uppercase tracking-[0.22em] text-[#D4A73C]">{blog.category?.name || "Astrology"}</p>
              <h1 className="mt-3 text-4xl font-black leading-tight text-slate-950 md:text-6xl">{blog.title}</h1>
              <div className="mt-5 flex flex-wrap gap-3 text-sm text-slate-500">
                <span>{blog.author_name || "AstroZura Team"}</span>
                <span>|</span>
                <span>{formatDate(blog.published_at)}</span>
                <span>|</span>
                <span>{blog.views_count || 0} views</span>
              </div>
              {blog.excerpt ? <p className="mt-7 rounded-2xl bg-[#fff8df] p-5 text-lg leading-8 text-[#7a5205]">{blog.excerpt}</p> : null}
              <div className="mt-8">
                {(blog.content_blocks || []).map((block, index) => (
                  <ContentBlock key={`${block.type}-${index}`} block={block} index={index} />
                ))}
              </div>
            </div>
          </article>
        ) : null}
      </main>

      <Footer />
    </div>
  );
}
