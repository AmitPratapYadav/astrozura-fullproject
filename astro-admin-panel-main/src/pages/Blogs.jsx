import { useEffect, useMemo, useRef, useState } from "react";
import { apiRequest, assetUrl } from "../lib/api";

const emptyBlock = { type: "paragraph", text: "", html: "" };
const emptyForm = {
  blog_category_id: "",
  title: "",
  slug: "",
  excerpt: "",
  author_name: "AstroZura Team",
  status: "1",
  show_on_main: true,
  show_on_shop: false,
  published_at: "",
  seo_title: "",
  seo_description: "",
  seo_keywords: "",
  cover_image: null,
  content_blocks: [{ ...emptyBlock }],
  block_images: {},
};

const normalizeBlogs = (payload) => {
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload?.data)) return payload.data;
  return [];
};

const blockHtml = (block) => block?.html || (block?.text ? String(block.text).replace(/\n/g, "<br>") : "");

function RichTextEditor({ block, onChange }) {
  const editorRef = useRef(null);
  const value = blockHtml(block);

  useEffect(() => {
    if (!editorRef.current || document.activeElement === editorRef.current) return;
    editorRef.current.innerHTML = value;
  }, [value]);

  const sync = () => {
    const html = editorRef.current?.innerHTML || "";
    onChange({ html, text: editorRef.current?.innerText || "" });
  };

  const command = (name, commandValue = null) => {
    editorRef.current?.focus();
    document.execCommand(name, false, commandValue);
    sync();
  };

  const escapeHtml = (text) =>
    text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");

  const convertToList = (tagName) => {
    const editor = editorRef.current;
    if (!editor) return;

    editor.focus();
    const selection = window.getSelection();
    const selectedText = selection && selection.rangeCount ? selection.toString().trim() : "";
    const sourceText = selectedText || editor.innerText || "";
    const items = sourceText
      .split(/\n+/)
      .map((item) => item.trim())
      .filter(Boolean);
    const listItems = (items.length ? items : ["List item"])
      .map((item) => `<li>${escapeHtml(item)}</li>`)
      .join("");
    const listHtml = `<${tagName}>${listItems}</${tagName}>`;

    if (selection && selection.rangeCount && selectedText) {
      const range = selection.getRangeAt(0);
      range.deleteContents();
      const wrapper = document.createElement("div");
      wrapper.innerHTML = listHtml;
      range.insertNode(wrapper.firstElementChild);
    } else {
      editor.innerHTML = listHtml;
    }

    sync();
  };

  const toolbarAction = (event, name, commandValue = null) => {
    event.preventDefault();
    command(name, commandValue);
  };

  return (
    <div className="rounded-lg border border-gray-200 bg-white">
      <div className="flex flex-wrap items-center gap-1 border-b border-gray-200 bg-gray-50 px-2 py-2">
        <button type="button" onMouseDown={(event) => toolbarAction(event, "bold")} className="rounded border bg-white px-2 py-1 text-xs font-black">B</button>
        <button type="button" onMouseDown={(event) => toolbarAction(event, "italic")} className="rounded border bg-white px-2 py-1 text-xs italic">I</button>
        <button type="button" onMouseDown={(event) => toolbarAction(event, "underline")} className="rounded border bg-white px-2 py-1 text-xs underline">U</button>
        <button type="button" onMouseDown={(event) => { event.preventDefault(); convertToList("ul"); }} className="rounded border bg-white px-2 py-1 text-xs font-semibold">Bullets</button>
        <button type="button" onMouseDown={(event) => { event.preventDefault(); convertToList("ol"); }} className="rounded border bg-white px-2 py-1 text-xs font-semibold">Numbers</button>
        <select onMouseDown={(event) => event.stopPropagation()} onChange={(event) => command("fontName", event.target.value)} className="rounded border bg-white px-2 py-1 text-xs" defaultValue="">
          <option value="" disabled>Font</option>
          <option value="Arial">Arial</option>
          <option value="Georgia">Georgia</option>
          <option value="Times New Roman">Times</option>
          <option value="Verdana">Verdana</option>
        </select>
        <select onMouseDown={(event) => event.stopPropagation()} onChange={(event) => command("fontSize", event.target.value)} className="rounded border bg-white px-2 py-1 text-xs" defaultValue="">
          <option value="" disabled>Size</option>
          <option value="2">Small</option>
          <option value="3">Normal</option>
          <option value="5">Large</option>
          <option value="6">XL</option>
        </select>
        <label className="flex items-center gap-1 rounded border bg-white px-2 py-1 text-xs">
          Color
          <input type="color" onMouseDown={(event) => event.stopPropagation()} onChange={(event) => command("foreColor", event.target.value)} className="h-5 w-7 border-0 bg-transparent p-0" />
        </label>
      </div>
      <div
        ref={editorRef}
        contentEditable
        suppressContentEditableWarning
        onInput={sync}
        onBlur={sync}
        className={`${block.type === "heading" ? "min-h-[70px]" : "min-h-[150px]"} w-full px-3 py-2 text-sm leading-7 outline-none focus:ring-2 focus:ring-yellow-200 [&_ol]:list-decimal [&_ol]:pl-6 [&_ul]:list-disc [&_ul]:pl-6 [&_li]:my-1`}
      />
    </div>
  );
}

export default function Blogs() {
  const [blogs, setBlogs] = useState([]);
  const [categories, setCategories] = useState([]);
  const [form, setForm] = useState(emptyForm);
  const [editingId, setEditingId] = useState(null);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");

  const selectedBlog = useMemo(() => blogs.find((blog) => Number(blog.id) === Number(editingId)), [blogs, editingId]);

  const loadData = async () => {
    const [blogResponse, categoryResponse] = await Promise.all([
      apiRequest("/admin/blogs?per_page=50"),
      apiRequest("/admin/blog-categories"),
    ]);
    setBlogs(normalizeBlogs(blogResponse.data));
    setCategories(categoryResponse.data || []);
  };

  useEffect(() => {
    loadData().catch((error) => setMessage(error.message));
  }, []);

  const resetForm = () => {
    setForm(emptyForm);
    setEditingId(null);
  };

  const updateBlock = (index, updates) => {
    setForm((current) => ({
      ...current,
      content_blocks: current.content_blocks.map((block, blockIndex) =>
        blockIndex === index ? { ...block, ...updates } : block
      ),
    }));
  };

  const addBlock = (type) => {
    setForm((current) => ({
      ...current,
      content_blocks: [
        ...current.content_blocks,
        type === "image" ? { type: "image", url: "", alt: "", caption: "" } : { type, text: "", html: "" },
      ],
    }));
  };

  const removeBlock = (index) => {
    setForm((current) => ({
      ...current,
      content_blocks: current.content_blocks.filter((_, blockIndex) => blockIndex !== index),
    }));
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    setLoading(true);
    setMessage("");

    try {
      const payload = new FormData();
      [
        "blog_category_id",
        "title",
        "slug",
        "excerpt",
        "author_name",
        "status",
        "published_at",
        "seo_title",
        "seo_description",
        "seo_keywords",
      ].forEach((key) => {
        if (form[key] !== null && form[key] !== undefined) payload.append(key, form[key]);
      });
      payload.append("show_on_main", form.show_on_main ? "1" : "0");
      payload.append("show_on_shop", form.show_on_shop ? "1" : "0");
      if (form.cover_image) payload.append("cover_image", form.cover_image);
      payload.append("content_blocks", JSON.stringify(form.content_blocks));
      Object.entries(form.block_images || {}).forEach(([index, file]) => {
        if (file) payload.append(`block_images[${index}]`, file);
      });

      await apiRequest(editingId ? `/admin/blogs/${editingId}` : "/admin/blogs", {
        method: "POST",
        body: payload,
      });

      setMessage(editingId ? "Blog updated." : "Blog created.");
      resetForm();
      await loadData();
    } catch (error) {
      setMessage(error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = async (blog) => {
    setMessage("");
    try {
      const response = await apiRequest(`/admin/blogs/${blog.id}`);
      const record = response.data || blog;
      setEditingId(record.id);
      setForm({
        blog_category_id: record.blog_category_id || record.category?.id || "",
        title: record.title || "",
        slug: record.slug || "",
        excerpt: record.excerpt || "",
        author_name: record.author_name || "AstroZura Team",
        status: record.status ? "1" : "0",
        show_on_main: record.show_on_main !== false,
        show_on_shop: Boolean(record.show_on_shop),
        published_at: record.published_at ? String(record.published_at).slice(0, 16) : "",
        seo_title: record.seo_title || "",
        seo_description: record.seo_description || "",
        seo_keywords: record.seo_keywords || "",
        cover_image: null,
        content_blocks: Array.isArray(record.content_blocks) && record.content_blocks.length
          ? record.content_blocks
          : [{ ...emptyBlock }],
        block_images: {},
      });
    } catch (error) {
      setMessage(error.message);
    }
  };

  const handleDelete = async (blog) => {
    if (!window.confirm(`Delete blog "${blog.title}"?`)) return;
    try {
      await apiRequest(`/admin/blogs/${blog.id}`, { method: "DELETE" });
      await loadData();
      if (editingId === blog.id) resetForm();
      setMessage("Blog deleted.");
    } catch (error) {
      setMessage(error.message);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Blogs</h1>
        <p className="mt-1 text-sm text-gray-500">Create public blog posts using heading, paragraph, and image blocks.</p>
      </div>

      {message && (
        <div className="rounded-lg border border-yellow-200 bg-yellow-50 px-4 py-3 text-sm font-medium text-yellow-800">
          {message}
        </div>
      )}

      <form onSubmit={handleSubmit} className="rounded-xl bg-white p-5 shadow-sm">
        <div className="grid gap-4 lg:grid-cols-2">
          <label>
            <span className="text-sm font-semibold text-gray-700">Title</span>
            <input
              value={form.title}
              onChange={(event) => setForm((current) => ({ ...current, title: event.target.value }))}
              className="mt-2 w-full rounded-lg border border-gray-200 px-3 py-2 outline-none focus:border-yellow-500"
              required
            />
          </label>
          <label>
            <span className="text-sm font-semibold text-gray-700">Category</span>
            <select
              value={form.blog_category_id}
              onChange={(event) => setForm((current) => ({ ...current, blog_category_id: event.target.value }))}
              className="mt-2 w-full rounded-lg border border-gray-200 px-3 py-2 outline-none focus:border-yellow-500"
            >
              <option value="">Uncategorized</option>
              {categories.map((category) => (
                <option key={category.id} value={category.id}>{category.name}</option>
              ))}
            </select>
          </label>
          <label>
            <span className="text-sm font-semibold text-gray-700">Slug</span>
            <input
              value={form.slug}
              onChange={(event) => setForm((current) => ({ ...current, slug: event.target.value }))}
              className="mt-2 w-full rounded-lg border border-gray-200 px-3 py-2 outline-none focus:border-yellow-500"
              placeholder="Auto generated when empty"
            />
          </label>
          <label>
            <span className="text-sm font-semibold text-gray-700">Author</span>
            <input
              value={form.author_name}
              onChange={(event) => setForm((current) => ({ ...current, author_name: event.target.value }))}
              className="mt-2 w-full rounded-lg border border-gray-200 px-3 py-2 outline-none focus:border-yellow-500"
            />
          </label>
          <label>
            <span className="text-sm font-semibold text-gray-700">Status</span>
            <select
              value={form.status}
              onChange={(event) => setForm((current) => ({ ...current, status: event.target.value }))}
              className="mt-2 w-full rounded-lg border border-gray-200 px-3 py-2 outline-none focus:border-yellow-500"
            >
              <option value="1">Published</option>
              <option value="0">Draft</option>
            </select>
          </label>
          <label>
            <span className="text-sm font-semibold text-gray-700">Published At</span>
            <input
              type="datetime-local"
              value={form.published_at}
              onChange={(event) => setForm((current) => ({ ...current, published_at: event.target.value }))}
              className="mt-2 w-full rounded-lg border border-gray-200 px-3 py-2 outline-none focus:border-yellow-500"
            />
          </label>
          <div className="lg:col-span-2 flex flex-wrap gap-5 rounded-lg bg-gray-50 px-4 py-3">
            <label className="flex items-center gap-2 text-sm font-semibold text-gray-700">
              <input type="checkbox" checked={form.show_on_main} onChange={(event) => setForm((current) => ({ ...current, show_on_main: event.target.checked }))} />
              Show on Main Website
            </label>
            <label className="flex items-center gap-2 text-sm font-semibold text-gray-700">
              <input type="checkbox" checked={form.show_on_shop} onChange={(event) => setForm((current) => ({ ...current, show_on_shop: event.target.checked }))} />
              Show on Shop Guide Book
            </label>
          </div>
          <label className="lg:col-span-2">
            <span className="text-sm font-semibold text-gray-700">Excerpt</span>
            <textarea
              value={form.excerpt}
              onChange={(event) => setForm((current) => ({ ...current, excerpt: event.target.value }))}
              rows={3}
              className="mt-2 w-full rounded-lg border border-gray-200 px-3 py-2 outline-none focus:border-yellow-500"
            />
          </label>
          <label className="lg:col-span-2">
            <span className="text-sm font-semibold text-gray-700">Cover Image</span>
            <input
              type="file"
              accept="image/*"
              onChange={(event) => setForm((current) => ({ ...current, cover_image: event.target.files?.[0] || null }))}
              className="mt-2 w-full rounded-lg border border-gray-200 px-3 py-2"
            />
            {selectedBlog?.cover_image && <img src={assetUrl(selectedBlog.cover_image)} alt="" className="mt-3 h-24 w-40 rounded-lg object-cover" />}
          </label>
        </div>

        <div className="mt-6 rounded-xl border border-gray-200 p-4">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <h2 className="text-lg font-bold text-gray-900">Content Blocks</h2>
            <div className="flex gap-2">
              <button type="button" onClick={() => addBlock("heading")} className="rounded-lg border px-3 py-2 text-sm font-semibold">Heading</button>
              <button type="button" onClick={() => addBlock("paragraph")} className="rounded-lg border px-3 py-2 text-sm font-semibold">Paragraph</button>
              <button type="button" onClick={() => addBlock("image")} className="rounded-lg border px-3 py-2 text-sm font-semibold">Image</button>
            </div>
          </div>

          <div className="mt-4 space-y-4">
            {form.content_blocks.map((block, index) => (
              <div key={index} className="rounded-lg border border-gray-100 bg-gray-50 p-4">
                <div className="mb-3 flex items-center justify-between">
                  <select
                    value={block.type}
                    onChange={(event) => updateBlock(index, { type: event.target.value })}
                    className="rounded-lg border border-gray-200 px-3 py-2 text-sm"
                  >
                    <option value="heading">Heading</option>
                    <option value="paragraph">Paragraph</option>
                    <option value="image">Image</option>
                  </select>
                  <button type="button" onClick={() => removeBlock(index)} className="text-sm font-semibold text-red-600">Remove</button>
                </div>

                {block.type === "image" ? (
                  <div className="grid gap-3 md:grid-cols-2">
                    <input
                      type="file"
                      accept="image/*"
                      onChange={(event) =>
                        setForm((current) => ({
                          ...current,
                          block_images: { ...current.block_images, [index]: event.target.files?.[0] || null },
                        }))
                      }
                      className="rounded-lg border border-gray-200 px-3 py-2"
                    />
                    <input
                      value={block.alt || ""}
                      onChange={(event) => updateBlock(index, { alt: event.target.value })}
                      placeholder="Alt text"
                      className="rounded-lg border border-gray-200 px-3 py-2"
                    />
                    <input
                      value={block.caption || ""}
                      onChange={(event) => updateBlock(index, { caption: event.target.value })}
                      placeholder="Caption"
                      className="rounded-lg border border-gray-200 px-3 py-2 md:col-span-2"
                    />
                    {block.url && <img src={assetUrl(block.url)} alt={block.alt || ""} className="h-24 w-40 rounded-lg object-cover" />}
                  </div>
                ) : (
                  <RichTextEditor block={block} onChange={(updates) => updateBlock(index, updates)} />
                )}
              </div>
            ))}
          </div>
        </div>

        <div className="mt-6 grid gap-4 lg:grid-cols-3">
          <input
            value={form.seo_title}
            onChange={(event) => setForm((current) => ({ ...current, seo_title: event.target.value }))}
            placeholder="SEO title"
            className="rounded-lg border border-gray-200 px-3 py-2"
          />
          <input
            value={form.seo_keywords}
            onChange={(event) => setForm((current) => ({ ...current, seo_keywords: event.target.value }))}
            placeholder="SEO keywords"
            className="rounded-lg border border-gray-200 px-3 py-2"
          />
          <input
            value={form.seo_description}
            onChange={(event) => setForm((current) => ({ ...current, seo_description: event.target.value }))}
            placeholder="SEO description"
            className="rounded-lg border border-gray-200 px-3 py-2"
          />
        </div>

        <div className="mt-5 flex gap-3">
          <button type="submit" disabled={loading} className="rounded-lg bg-yellow-500 px-5 py-2 text-sm font-bold text-black disabled:opacity-60">
            {loading ? "Saving..." : editingId ? "Update Blog" : "Create Blog"}
          </button>
          {editingId && <button type="button" onClick={resetForm} className="rounded-lg border border-gray-200 px-5 py-2 text-sm font-semibold">Cancel</button>}
        </div>
      </form>

      <div className="overflow-hidden rounded-xl bg-white shadow-sm">
        <table className="w-full text-left text-sm">
          <thead className="bg-gray-50 text-xs uppercase text-gray-500">
            <tr>
              <th className="px-4 py-3">Cover</th>
              <th className="px-4 py-3">Title</th>
              <th className="px-4 py-3">Category</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3">Platforms</th>
              <th className="px-4 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {blogs.map((blog) => (
              <tr key={blog.id} className="border-t border-gray-100">
                <td className="px-4 py-3">
                  {blog.cover_image ? (
                    <img src={assetUrl(blog.cover_image)} alt={blog.title} className="h-12 w-20 rounded-lg object-cover" />
                  ) : (
                    <span className="text-gray-400">No image</span>
                  )}
                </td>
                <td className="px-4 py-3">
                  <p className="font-semibold text-gray-900">{blog.title}</p>
                  <p className="text-xs text-gray-500">{blog.slug}</p>
                </td>
                <td className="px-4 py-3">{blog.category?.name || "-"}</td>
                <td className="px-4 py-3">{blog.status ? "Published" : "Draft"}</td>
                <td className="px-4 py-3 text-xs text-gray-500">
                  {[blog.show_on_main && "Main", blog.show_on_shop && "Shop"].filter(Boolean).join(", ") || "-"}
                </td>
                <td className="px-4 py-3 text-right">
                  <button onClick={() => handleEdit(blog)} className="mr-3 font-semibold text-blue-600">Edit</button>
                  <button onClick={() => handleDelete(blog)} className="font-semibold text-red-600">Delete</button>
                </td>
              </tr>
            ))}
            {!blogs.length && (
              <tr>
                <td colSpan="6" className="px-4 py-8 text-center text-gray-500">No blogs yet.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
