import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import axios from "axios";
import CatalogImage from "../components/CatalogImage";
import { assetUrl } from "../utils/assetUrl";

const apiUrl = import.meta.env.VITE_API_BASE_URL || "https://astrozura.com/apigateway/index.php/api";

export default function GuideBookDetail() {
  const { slug } = useParams();
  const [blog, setBlog] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const { data } = await axios.get(`${apiUrl}/blogs/${slug}`, { params: { platform: "shop" } });
        setBlog(data?.data || null);
      } finally {
        setLoading(false);
      }
    };
    void load();
  }, [slug]);

  if (loading) {
    return <div className="min-h-screen bg-[#f8f9fc] p-10 text-center text-gray-500">Loading guide...</div>;
  }

  if (!blog) {
    return <div className="min-h-screen bg-[#f8f9fc] p-10 text-center text-gray-500">Guide not found.</div>;
  }

  return (
    <main className="min-h-screen bg-[#f8f9fc] px-4 py-10">
      <article className="mx-auto max-w-4xl overflow-hidden rounded-3xl bg-white shadow-sm">
        <CatalogImage src={assetUrl(blog.cover_image)} alt={blog.title} className="h-72 w-full object-cover" />
        <div className="p-6 md:p-10">
          <Link to="/guide-book" className="text-sm font-bold text-[#D4A73C]">Back to Guide Book</Link>
          <p className="mt-6 text-xs font-black uppercase tracking-[0.24em] text-[#D4A73C]">{blog.category?.name || "Guide"}</p>
          <h1 className="mt-3 text-3xl font-black text-[#1E3557] md:text-5xl">{blog.title}</h1>
          {blog.excerpt && <p className="mt-4 text-lg leading-8 text-gray-600">{blog.excerpt}</p>}

          <div className="mt-10 space-y-6 text-gray-700">
            {(blog.content_blocks || []).map((block, index) => {
              const richHtml = block.html || "";
              if (block.type === "heading") {
                if (richHtml) {
                  return <div key={index} className="text-2xl font-black text-[#1E3557] [&_*]:font-inherit" dangerouslySetInnerHTML={{ __html: richHtml }} />;
                }
                return <h2 key={index} className="text-2xl font-black text-[#1E3557]">{block.text}</h2>;
              }
              if (block.type === "image") {
                return (
                  <figure key={index}>
                    <CatalogImage src={assetUrl(block.url)} alt={block.alt || ""} className="max-h-[480px] w-full rounded-2xl object-cover" />
                    {block.caption && <figcaption className="mt-2 text-center text-xs text-gray-400">{block.caption}</figcaption>}
                  </figure>
                );
              }
              if (richHtml) {
                return (
                  <div
                    key={index}
                    className="text-base leading-8 [&_a]:font-bold [&_a]:text-[#D4A73C] [&_li]:my-1 [&_ol]:ml-6 [&_ol]:list-decimal [&_strong]:text-gray-900 [&_ul]:ml-6 [&_ul]:list-disc"
                    dangerouslySetInnerHTML={{ __html: richHtml }}
                  />
                );
              }
              return <p key={index} className="whitespace-pre-wrap text-base leading-8">{block.text}</p>;
            })}
          </div>
        </div>
      </article>
    </main>
  );
}
