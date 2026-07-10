import React, { useState, useEffect } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { Upload, ArrowLeft } from "lucide-react";
import { apiRequest, assetUrl } from "../lib/api";
import VariantEditor from "../components/VariantEditor";

export default function EditProduct() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [initialLoading, setInitialLoading] = useState(true);
  const [categories, setCategories] = useState([]);
  const [blogs, setBlogs] = useState([]);

  const [formData, setFormData] = useState({
    name: "",
    category_id: "",
    price: "",
    unit: "",
    description: "",
    benefits: "",
    specifications: "",
    warnings_precautions: "",
    bead_count: "",
    bead_size: "",
    seed_type: "",
    thread_type: "",
    origin: "",
    is_trending: false,
    is_new_arrival: false,
    guide_blog_id: "",
    status: true,
    name_hi: "",
    description_hi: "",
    benefits_hi: "",
  });
  const [imageFile, setImageFile] = useState(null);
  const [preview, setPreview] = useState(null);
  const [optionNames, setOptionNames] = useState([]);
  const [variants, setVariants] = useState([]);

  useEffect(() => {
    fetchCategories();
    fetchBlogs();
    fetchProduct();
  }, [id]);

  const fetchCategories = async () => {
    try {
      const result = await apiRequest("/admin/ecomm/categories");
      if (result.status === "success") {
        setCategories(result.data);
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

  const fetchProduct = async () => {
    try {
      const result = await apiRequest(`/admin/ecomm/products/${id}`);
      if (result.status === "success") {
        const product = result.data;
        setFormData({
          name: product.name,
          category_id: product.category_id,
          price: product.price,
          unit: product.unit || "",
          description: product.description || "",
          benefits: product.benefits || "",
          specifications: product.specifications || "",
          warnings_precautions: product.warnings_precautions || "",
          bead_count: product.bead_count || "",
          bead_size: product.bead_size || "",
          seed_type: product.seed_type || "",
          thread_type: product.thread_type || "",
          origin: product.origin || "",
          is_trending: Boolean(product.is_trending),
          is_new_arrival: Boolean(product.is_new_arrival),
          guide_blog_id: product.guide_blog_id || "",
          status: Boolean(product.status),
          name_hi: product.translations?.hi?.name || "",
          description_hi: product.translations?.hi?.description || "",
          benefits_hi: product.translations?.hi?.benefits || "",
        });
        if (product.image) {
          setPreview(assetUrl(product.image));
        }
        setOptionNames(product.option_names || []);
        setVariants(product.variants || []);
      } else {
        alert(result.message || "Product not found");
        navigate("/products");
      }
    } catch (error) {
      console.error("Error fetching product:", error);
    } finally {
      setInitialLoading(false);
    }
  };

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData({
      ...formData,
      [name]: type === "checkbox" ? checked : value,
    });
  };

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setImageFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setPreview(reader.result);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.name || !formData.category_id || !formData.price) {
      alert("Name, Category, and Price are required!");
      return;
    }

    setLoading(true);
    try {
      const data = new FormData();
      data.append("name", formData.name);
      data.append("category_id", formData.category_id);
      if (formData.guide_blog_id) data.append("guide_blog_id", formData.guide_blog_id);
      data.append("price", formData.price);
      data.append("unit", formData.unit);
      data.append("description", formData.description);
      data.append("benefits", formData.benefits);
      data.append("specifications", formData.specifications);
      data.append("warnings_precautions", formData.warnings_precautions);
      data.append("bead_count", formData.bead_count);
      data.append("bead_size", formData.bead_size);
      data.append("seed_type", formData.seed_type);
      data.append("thread_type", formData.thread_type);
      data.append("origin", formData.origin);
      data.append("is_trending", formData.is_trending ? 1 : 0);
      data.append("is_new_arrival", formData.is_new_arrival ? 1 : 0);
      data.append("status", formData.status ? 1 : 0);
      data.append("option_names", JSON.stringify(optionNames));
      data.append("variants", JSON.stringify(variants));
      data.append("translations", JSON.stringify({ hi: {
        name: formData.name_hi,
        description: formData.description_hi,
        benefits: formData.benefits_hi,
      } }));
      
      if (imageFile) {
        data.append("image", imageFile);
      }

      const result = await apiRequest(`/admin/ecomm/products/update/${id}`, {
        method: "POST",
        body: data,
      });
      if (result.status === "success") {
        alert("Product updated successfully!");
        navigate("/products");
      } else {
        alert(result.message || "Failed to update product.");
      }
    } catch (error) {
      console.error("Error updating product:", error);
      alert("An error occurred. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  if (initialLoading) {
    return <div className="p-6">Loading product details...</div>;
  }

  return (
    <div className="bg-white p-6 rounded-lg shadow-sm font-sans mx-auto max-w-3xl">
      <div className="flex items-center gap-4 mb-6">
        <Link to="/products" className="text-gray-500 hover:text-black">
          <ArrowLeft size={24} />
        </Link>
        <h1 className="text-2xl font-bold">Edit Product</h1>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="grid md:grid-cols-2 gap-6">
          {/* Product Name */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Product Name *
            </label>
            <input
              type="text"
              name="name"
              value={formData.name}
              onChange={handleInputChange}
              className="w-full border border-gray-300 rounded-lg p-3 focus:outline-none focus:ring-2 focus:ring-yellow-500"
              placeholder="Enter product name"
              required
            />
          </div>

          {/* Category Selection */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Select Category *
            </label>
            <select
              name="category_id"
              value={formData.category_id}
              onChange={handleInputChange}
              className="w-full border border-gray-300 rounded-lg p-3 focus:outline-none focus:ring-2 focus:ring-yellow-500 bg-white"
              required
            >
              <option value="">-- Choose a Category --</option>
              {categories.map((cat) => (
                <option key={cat.id} value={cat.id}>
                  {cat.name}
                </option>
              ))}
            </select>
          </div>

          {/* Price */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Price (INR) *
            </label>
            <input
              type="number"
              name="price"
              step="0.01"
              value={formData.price}
              onChange={handleInputChange}
              className="w-full border border-gray-300 rounded-lg p-3 focus:outline-none focus:ring-2 focus:ring-yellow-500"
              placeholder="0.00"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Selling Unit
            </label>
            <input
              type="text"
              name="unit"
              value={formData.unit}
              onChange={handleInputChange}
              className="w-full border border-gray-300 rounded-lg p-3 focus:outline-none focus:ring-2 focus:ring-yellow-500"
              placeholder="e.g. per piece or per kg"
            />
          </div>
          <div className="md:col-span-2">
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Product Guide Blog
            </label>
            <select
              name="guide_blog_id"
              value={formData.guide_blog_id}
              onChange={handleInputChange}
              className="w-full border border-gray-300 rounded-lg p-3 focus:outline-none focus:ring-2 focus:ring-yellow-500 bg-white"
            >
              <option value="">No guide blog</option>
              {blogs.map((blog) => (
                <option key={blog.id} value={blog.id}>{blog.title}</option>
              ))}
            </select>
          </div>
        </div>

        <div className="grid md:grid-cols-2 gap-6">
          {/* Description */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Short Description
            </label>
            <textarea
              name="description"
              value={formData.description}
              onChange={handleInputChange}
              rows="5"
              className="w-full border border-gray-300 rounded-lg p-3 focus:outline-none focus:ring-2 focus:ring-yellow-500"
              placeholder="Write a brief description..."
            ></textarea>
          </div>
          {/* Benefits */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Who Should Use / Benefits
            </label>
            <textarea
              name="benefits"
              value={formData.benefits}
              onChange={handleInputChange}
              rows="5"
              className="w-full border border-gray-300 rounded-lg p-3 focus:outline-none focus:ring-2 focus:ring-yellow-500"
              placeholder="Product benefits..."
            ></textarea>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Product Specifications
            </label>
            <textarea
              name="specifications"
              value={formData.specifications}
              onChange={handleInputChange}
              rows="5"
              className="w-full border border-gray-300 rounded-lg p-3 focus:outline-none focus:ring-2 focus:ring-yellow-500"
              placeholder="Material, size, chakra, origin, and other details..."
            ></textarea>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Warnings & Precautions
            </label>
            <textarea
              name="warnings_precautions"
              value={formData.warnings_precautions}
              onChange={handleInputChange}
              rows="5"
              className="w-full border border-gray-300 rounded-lg p-3 focus:outline-none focus:ring-2 focus:ring-yellow-500"
              placeholder="Care instructions and safety information..."
            ></textarea>
          </div>
        </div>
        <div className="rounded-xl border bg-gray-50 p-4">
          <h2 className="mb-3 font-semibold">Hindi Content</h2>
          <div className="grid gap-4 md:grid-cols-2"><input name="name_hi" value={formData.name_hi} onChange={handleInputChange} placeholder="Product name in Hindi" className="rounded-lg border p-3" /><textarea name="description_hi" value={formData.description_hi} onChange={handleInputChange} placeholder="Description in Hindi" className="rounded-lg border p-3" /><textarea name="benefits_hi" value={formData.benefits_hi} onChange={handleInputChange} placeholder="Benefits in Hindi" className="rounded-lg border p-3 md:col-span-2" /></div>
        </div>

        <div className="border-t pt-4">
          <h3 className="text-lg font-bold mb-4">Rudraksha Details (Optional)</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Bead Count</label>
              <input
                type="text"
                name="bead_count"
                className="w-full border px-4 py-2 rounded-lg"
                placeholder="e.g. 108 + 1"
                value={formData.bead_count}
                onChange={handleInputChange}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Bead Size</label>
              <input
                type="text"
                name="bead_size"
                className="w-full border px-4 py-2 rounded-lg"
                placeholder="e.g. 8mm"
                value={formData.bead_size}
                onChange={handleInputChange}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Seed Type</label>
              <input
                type="text"
                name="seed_type"
                className="w-full border px-4 py-2 rounded-lg"
                placeholder="e.g. 5 Mukhi"
                value={formData.seed_type}
                onChange={handleInputChange}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Thread Type</label>
              <input
                type="text"
                name="thread_type"
                className="w-full border px-4 py-2 rounded-lg"
                placeholder="e.g. Nylon"
                value={formData.thread_type}
                onChange={handleInputChange}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Origin</label>
              <input
                type="text"
                name="origin"
                className="w-full border px-4 py-2 rounded-lg"
                placeholder="e.g. Nepal"
                value={formData.origin}
                onChange={handleInputChange}
              />
            </div>
          </div>
        </div>

        {/* Product Image Upload */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Product Image
          </label>
          <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 flex flex-col items-center justify-center relative bg-gray-50 hover:bg-gray-100 transition">
            {preview ? (
              <div className="flex flex-col items-center">
                <img src={preview} alt="Preview" className="h-32 object-contain mb-3 rounded-md shadow-sm" />
                <span className="text-sm text-gray-500">Click to change image</span>
              </div>
            ) : (
              <div className="flex flex-col items-center">
                <Upload size={32} className="text-gray-400 mb-2" />
                <span className="text-sm font-medium text-gray-600">Upload Image</span>
                <span className="text-xs text-gray-400 mt-1">PNG, JPG up to 2MB</span>
              </div>
            )}
            <input
              type="file"
              accept="image/*"
              onChange={handleImageChange}
              className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
            />
          </div>
        </div>

        {/* Toggles */}
        <div className="flex flex-wrap gap-6 pt-2">
          {/* Trending Toggle */}
          <div className="flex items-center gap-3">
            <input
              type="checkbox"
              id="is_trending"
              name="is_trending"
              checked={formData.is_trending}
              onChange={handleInputChange}
              className="w-5 h-5 text-yellow-500 bg-gray-100 border-gray-300 rounded focus:ring-yellow-500 focus:ring-2 cursor-pointer"
            />
            <label htmlFor="is_trending" className="text-sm font-medium text-gray-700 cursor-pointer">
              Mark as Trending
            </label>
          </div>

          <div className="flex items-center gap-3">
            <input
              type="checkbox"
              id="is_new_arrival"
              name="is_new_arrival"
              checked={formData.is_new_arrival}
              onChange={handleInputChange}
              className="w-5 h-5 text-yellow-500 bg-gray-100 border-gray-300 rounded focus:ring-yellow-500 focus:ring-2 cursor-pointer"
            />
            <label htmlFor="is_new_arrival" className="text-sm font-medium text-gray-700 cursor-pointer">
              Mark as New Arrival
            </label>
          </div>

          {/* Status Toggle */}
          <div className="flex items-center gap-3">
            <input
              type="checkbox"
              id="status"
              name="status"
              checked={formData.status}
              onChange={handleInputChange}
              className="w-5 h-5 text-yellow-500 bg-gray-100 border-gray-300 rounded focus:ring-yellow-500 focus:ring-2 cursor-pointer"
            />
            <label htmlFor="status" className="text-sm font-medium text-gray-700 cursor-pointer">
              Active Status
            </label>
          </div>
        </div>

        <VariantEditor
          optionNames={optionNames}
          variants={variants}
          onChange={(names, nextVariants) => {
            setOptionNames(names);
            setVariants(nextVariants);
          }}
        />

        {/* Action Buttons */}
        <div className="flex gap-4 pt-6 border-t">
          <Link
            to="/products"
            className="px-6 py-2 border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50 transition"
          >
            Cancel
          </Link>
          <button
            type="submit"
            disabled={loading}
            className="px-6 py-2 bg-yellow-500 rounded-lg font-medium text-black hover:bg-yellow-600 transition disabled:opacity-50"
          >
            {loading ? "Updating..." : "Update Product"}
          </button>
        </div>
      </form>
    </div>
  );
}
