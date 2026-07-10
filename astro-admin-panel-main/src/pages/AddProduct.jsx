import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { apiRequest } from "../lib/api";
import VariantEditor from "../components/VariantEditor";

export default function AddProduct() {
  const [categories, setCategories] = useState([]);
  const [blogs, setBlogs] = useState([]);
  
  const [formData, setFormData] = useState({
    name: "",
    categoryId: "",
    price: "",
    unit: "",
    description: "",
    benefits: "",
    specifications: "",
    warningsPrecautions: "",
    beadCount: "",
    beadSize: "",
    seedType: "",
    threadType: "",
    origin: "",
    isTrending: false,
    isNewArrival: false,
    guideBlogId: "",
    status: true
  });
  const [hindi, setHindi] = useState({ name: "", description: "", benefits: "" });
  const [image, setImage] = useState(null);
  const [optionNames, setOptionNames] = useState([]);
  const [variants, setVariants] = useState([]);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    fetchCategories();
    fetchBlogs();
  }, []);

  const fetchCategories = async () => {
    try {
      const result = await apiRequest("/admin/ecomm/categories");
      if (result.status === "success") {
        setCategories(result.data.filter(cat => cat.status === 1));
      }
    } catch (error) {
      console.error("Error fetching categories:", error);
    }
  };

  const fetchBlogs = async () => {
    try {
      const result = await apiRequest("/admin/blogs?per_page=200");
      const rows = Array.isArray(result.data?.data) ? result.data.data : (result.data || []);
      setBlogs(rows.filter((blog) => blog.status));
    } catch (error) {
      console.error("Error fetching blogs:", error);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    const payload = new FormData();
    payload.append("name", formData.name);
    payload.append("category_id", formData.categoryId);
    if (formData.guideBlogId) payload.append("guide_blog_id", formData.guideBlogId);
    payload.append("price", formData.price);
    payload.append("unit", formData.unit);
    payload.append("description", formData.description);
    payload.append("benefits", formData.benefits);
    payload.append("specifications", formData.specifications);
    payload.append("warnings_precautions", formData.warningsPrecautions);
    payload.append("bead_count", formData.beadCount);
    payload.append("bead_size", formData.beadSize);
    payload.append("seed_type", formData.seedType);
    payload.append("thread_type", formData.threadType);
    payload.append("origin", formData.origin);
    payload.append("is_trending", formData.isTrending ? 1 : 0);
    payload.append("is_new_arrival", formData.isNewArrival ? 1 : 0);
    payload.append("status", formData.status ? 1 : 0);
    payload.append("option_names", JSON.stringify(optionNames));
    payload.append("variants", JSON.stringify(variants));
    payload.append("translations", JSON.stringify({ hi: hindi }));
    if (image) {
      payload.append("image", image);
    }

    try {
      const result = await apiRequest("/admin/ecomm/products/create", {
        method: "POST",
        body: payload,
      });

      if (result.status === "success") {
        alert("Product Added Successfully!");
        navigate("/products");
      } else {
        alert("Error adding product");
      }
    } catch (error) {
      console.error("Submit Error:", error);
      alert("Failed to submit");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white p-8 rounded-lg shadow-sm font-sans max-w-3xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">Add New Product</h1>
      
      <form onSubmit={handleSubmit} className="space-y-6">
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Product Name</label>
            <input
              type="text"
              required
              className="w-full border px-4 py-2 rounded-lg"
              placeholder="e.g. Citrine Energy Point"
              value={formData.name}
              onChange={(e) => setFormData({...formData, name: e.target.value})}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Select Category</label>
            <select
              required
              className="w-full border px-4 py-2 rounded-lg bg-white"
              value={formData.categoryId}
              onChange={(e) => setFormData({...formData, categoryId: e.target.value})}
            >
              <option value="">-- Choose Category --</option>
              {categories.map(cat => (
                <option key={cat.id} value={cat.id}>{cat.name}</option>
              ))}
            </select>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Price (INR)</label>
            <input
              type="number"
              step="0.01"
              required
              className="w-full border px-4 py-2 rounded-lg"
              placeholder="0.00"
              value={formData.price}
              onChange={(e) => setFormData({...formData, price: e.target.value})}
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Selling Unit</label>
            <input
              type="text"
              className="w-full border px-4 py-2 rounded-lg"
              placeholder="e.g. per piece or per kg"
              value={formData.unit}
              onChange={(e) => setFormData({...formData, unit: e.target.value})}
            />
          </div>
        </div>
        <div className="rounded-xl border bg-gray-50 p-4">
          <h2 className="mb-3 font-semibold">Hindi Content</h2>
          <div className="grid gap-4 md:grid-cols-2"><input value={hindi.name} onChange={(e) => setHindi({ ...hindi, name: e.target.value })} placeholder="Product name in Hindi" className="rounded-lg border px-4 py-2" /><textarea value={hindi.description} onChange={(e) => setHindi({ ...hindi, description: e.target.value })} placeholder="Description in Hindi" className="rounded-lg border px-4 py-2" /><textarea value={hindi.benefits} onChange={(e) => setHindi({ ...hindi, benefits: e.target.value })} placeholder="Benefits in Hindi" className="rounded-lg border px-4 py-2 md:col-span-2" /></div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Product Image</label>
          <input
            type="file"
            accept="image/*"
            className="w-full border px-4 py-2 rounded-lg"
            onChange={(e) => setImage(e.target.files[0])}
          />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Description (Optional)</label>
            <textarea
              rows="5"
              className="w-full border px-4 py-2 rounded-lg"
              placeholder="Product details..."
              value={formData.description}
              onChange={(e) => setFormData({...formData, description: e.target.value})}
            ></textarea>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Who Should Use / Benefits</label>
            <textarea
              rows="5"
              className="w-full border px-4 py-2 rounded-lg"
              placeholder="Benefits and intended users..."
              value={formData.benefits}
              onChange={(e) => setFormData({...formData, benefits: e.target.value})}
            ></textarea>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Product Specifications</label>
            <textarea
              rows="5"
              className="w-full border px-4 py-2 rounded-lg"
              placeholder="Material, size, chakra, origin, and other details..."
              value={formData.specifications}
              onChange={(e) => setFormData({...formData, specifications: e.target.value})}
            ></textarea>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Warnings & Precautions</label>
            <textarea
              rows="5"
              className="w-full border px-4 py-2 rounded-lg"
              placeholder="Care instructions and safety information..."
              value={formData.warningsPrecautions}
              onChange={(e) => setFormData({...formData, warningsPrecautions: e.target.value})}
            ></textarea>
          </div>
        </div>

        <div className="border-t pt-4">
          <h3 className="text-lg font-bold mb-4">Rudraksha Details (Optional)</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Bead Count</label>
              <input
                type="text"
                className="w-full border px-4 py-2 rounded-lg"
                placeholder="e.g. 108 + 1"
                value={formData.beadCount}
                onChange={(e) => setFormData({...formData, beadCount: e.target.value})}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Bead Size</label>
              <input
                type="text"
                className="w-full border px-4 py-2 rounded-lg"
                placeholder="e.g. 8mm"
                value={formData.beadSize}
                onChange={(e) => setFormData({...formData, beadSize: e.target.value})}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Seed Type</label>
              <input
                type="text"
                className="w-full border px-4 py-2 rounded-lg"
                placeholder="e.g. 5 Mukhi"
                value={formData.seedType}
                onChange={(e) => setFormData({...formData, seedType: e.target.value})}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Thread Type</label>
              <input
                type="text"
                className="w-full border px-4 py-2 rounded-lg"
                placeholder="e.g. Nylon"
                value={formData.threadType}
                onChange={(e) => setFormData({...formData, threadType: e.target.value})}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Origin</label>
              <input
                type="text"
                className="w-full border px-4 py-2 rounded-lg"
                placeholder="e.g. Nepal"
                value={formData.origin}
                onChange={(e) => setFormData({...formData, origin: e.target.value})}
              />
            </div>
          </div>
        </div>

        <div className="flex gap-6">
          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="isTrending"
              checked={formData.isTrending}
              onChange={(e) => setFormData({...formData, isTrending: e.target.checked})}
              className="w-4 h-4 cursor-pointer"
            />
            <label htmlFor="isTrending" className="font-medium cursor-pointer text-gray-700">Trending (Show on Homepage)</label>
          </div>
          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="isNewArrival"
              checked={formData.isNewArrival}
              onChange={(e) => setFormData({...formData, isNewArrival: e.target.checked})}
              className="w-4 h-4 cursor-pointer"
            />
            <label htmlFor="isNewArrival" className="font-medium cursor-pointer text-gray-700">New Arrival</label>
          </div>
          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="status"
              checked={formData.status}
              onChange={(e) => setFormData({...formData, status: e.target.checked})}
              className="w-4 h-4 cursor-pointer"
            />
            <label htmlFor="status" className="font-medium cursor-pointer text-gray-700">Active Status</label>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Product Guide Blog</label>
          <select
            className="w-full border px-4 py-2 rounded-lg bg-white"
            value={formData.guideBlogId}
            onChange={(e) => setFormData({...formData, guideBlogId: e.target.value})}
          >
            <option value="">No guide blog</option>
            {blogs.map((blog) => (
              <option key={blog.id} value={blog.id}>{blog.title}</option>
            ))}
          </select>
        </div>

        <VariantEditor
          optionNames={optionNames}
          variants={variants}
          onChange={(names, nextVariants) => {
            setOptionNames(names);
            setVariants(nextVariants);
          }}
        />

        <button 
          type="submit" 
          disabled={loading}
          className="w-full bg-yellow-500 text-black py-3 rounded-lg font-bold hover:bg-yellow-600 transition disabled:opacity-50"
        >
          {loading ? "Adding..." : "Add Product"}
        </button>
      </form>
    </div>
  );
}
