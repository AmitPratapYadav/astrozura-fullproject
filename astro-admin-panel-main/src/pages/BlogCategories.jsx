import { useEffect, useState } from "react";
import { apiRequest, assetUrl } from "../lib/api";

const emptyForm = {
  name: "",
  status: "1",
  sort_order: 0,
  show_on_main: true,
  show_on_shop: false,
  image: null,
};

export default function BlogCategories() {
  const [categories, setCategories] = useState([]);
  const [form, setForm] = useState(emptyForm);
  const [editingId, setEditingId] = useState(null);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");

  const loadCategories = async () => {
    const response = await apiRequest("/admin/blog-categories");
    setCategories(response.data || []);
  };

  useEffect(() => {
    loadCategories().catch((error) => setMessage(error.message));
  }, []);

  const resetForm = () => {
    setForm(emptyForm);
    setEditingId(null);
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    setLoading(true);
    setMessage("");

    try {
      const payload = new FormData();
      payload.append("name", form.name);
      payload.append("status", form.status);
      payload.append("sort_order", String(form.sort_order || 0));
      payload.append("show_on_main", form.show_on_main ? "1" : "0");
      payload.append("show_on_shop", form.show_on_shop ? "1" : "0");
      if (form.image) payload.append("image", form.image);

      await apiRequest(editingId ? `/admin/blog-categories/${editingId}` : "/admin/blog-categories", {
        method: "POST",
        body: payload,
      });

      setMessage(editingId ? "Blog category updated." : "Blog category created.");
      resetForm();
      await loadCategories();
    } catch (error) {
      setMessage(error.message);
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (category) => {
    setEditingId(category.id);
    setForm({
      name: category.name || "",
      status: category.status ? "1" : "0",
      sort_order: category.sort_order || 0,
      show_on_main: category.show_on_main !== false,
      show_on_shop: Boolean(category.show_on_shop),
      image: null,
    });
  };

  const handleDelete = async (category) => {
    if (!window.confirm(`Delete category "${category.name}"?`)) return;
    try {
      await apiRequest(`/admin/blog-categories/${category.id}`, { method: "DELETE" });
      await loadCategories();
      setMessage("Blog category deleted.");
    } catch (error) {
      setMessage(error.message);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Blog Categories</h1>
        <p className="mt-1 text-sm text-gray-500">Create the public blog category filters and category images.</p>
      </div>

      {message && (
        <div className="rounded-lg border border-yellow-200 bg-yellow-50 px-4 py-3 text-sm font-medium text-yellow-800">
          {message}
        </div>
      )}

      <form onSubmit={handleSubmit} className="rounded-xl bg-white p-5 shadow-sm">
        <div className="grid gap-4 md:grid-cols-4">
          <label className="md:col-span-2">
            <span className="text-sm font-semibold text-gray-700">Name</span>
            <input
              value={form.name}
              onChange={(event) => setForm((current) => ({ ...current, name: event.target.value }))}
              className="mt-2 w-full rounded-lg border border-gray-200 px-3 py-2 outline-none focus:border-yellow-500"
              required
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
            <span className="text-sm font-semibold text-gray-700">Sort Order</span>
            <input
              type="number"
              value={form.sort_order}
              onChange={(event) => setForm((current) => ({ ...current, sort_order: event.target.value }))}
              className="mt-2 w-full rounded-lg border border-gray-200 px-3 py-2 outline-none focus:border-yellow-500"
            />
          </label>
          <div className="md:col-span-4 flex flex-wrap gap-5 rounded-lg bg-gray-50 px-4 py-3">
            <label className="flex items-center gap-2 text-sm font-semibold text-gray-700">
              <input type="checkbox" checked={form.show_on_main} onChange={(event) => setForm((current) => ({ ...current, show_on_main: event.target.checked }))} />
              Show on Main Website
            </label>
            <label className="flex items-center gap-2 text-sm font-semibold text-gray-700">
              <input type="checkbox" checked={form.show_on_shop} onChange={(event) => setForm((current) => ({ ...current, show_on_shop: event.target.checked }))} />
              Show on Shop Guide Book
            </label>
          </div>
          <label className="md:col-span-4">
            <span className="text-sm font-semibold text-gray-700">Image</span>
            <input
              type="file"
              accept="image/*"
              onChange={(event) => setForm((current) => ({ ...current, image: event.target.files?.[0] || null }))}
              className="mt-2 w-full rounded-lg border border-gray-200 px-3 py-2"
            />
          </label>
        </div>
        <div className="mt-5 flex gap-3">
          <button
            type="submit"
            disabled={loading}
            className="rounded-lg bg-yellow-500 px-5 py-2 text-sm font-bold text-black disabled:opacity-60"
          >
            {loading ? "Saving..." : editingId ? "Update Category" : "Create Category"}
          </button>
          {editingId && (
            <button type="button" onClick={resetForm} className="rounded-lg border border-gray-200 px-5 py-2 text-sm font-semibold">
              Cancel
            </button>
          )}
        </div>
      </form>

      <div className="overflow-hidden rounded-xl bg-white shadow-sm">
        <table className="w-full text-left text-sm">
          <thead className="bg-gray-50 text-xs uppercase text-gray-500">
            <tr>
              <th className="px-4 py-3">Image</th>
              <th className="px-4 py-3">Name</th>
              <th className="px-4 py-3">Slug</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3">Platforms</th>
              <th className="px-4 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {categories.map((category) => (
              <tr key={category.id} className="border-t border-gray-100">
                <td className="px-4 py-3">
                  {category.image ? (
                    <img src={assetUrl(category.image)} alt={category.name} className="h-12 w-16 rounded-lg object-cover" />
                  ) : (
                    <span className="text-gray-400">No image</span>
                  )}
                </td>
                <td className="px-4 py-3 font-semibold text-gray-900">{category.name}</td>
                <td className="px-4 py-3 text-gray-500">{category.slug}</td>
                <td className="px-4 py-3">{category.status ? "Published" : "Draft"}</td>
                <td className="px-4 py-3 text-xs text-gray-500">
                  {[category.show_on_main && "Main", category.show_on_shop && "Shop"].filter(Boolean).join(", ") || "-"}
                </td>
                <td className="px-4 py-3 text-right">
                  <button onClick={() => handleEdit(category)} className="mr-3 font-semibold text-blue-600">Edit</button>
                  <button onClick={() => handleDelete(category)} className="font-semibold text-red-600">Delete</button>
                </td>
              </tr>
            ))}
            {!categories.length && (
              <tr>
                <td colSpan="6" className="px-4 py-8 text-center text-gray-500">No blog categories yet.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
