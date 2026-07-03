import React, { useState, useEffect } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { Upload, ArrowLeft } from "lucide-react";
import { apiRequest, assetUrl } from "../lib/api";

export default function EditCategory() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [initialLoading, setInitialLoading] = useState(true);

  const [formData, setFormData] = useState({
    name: "",
    status: true,
    shipping_charge: "0",
    hindi_name: "",
  });
  const [imageFile, setImageFile] = useState(null);
  const [preview, setPreview] = useState(null);

  useEffect(() => {
    const fetchCategory = async () => {
      try {
        const result = await apiRequest(`/admin/ecomm/categories/${id}`);
        if (result.status === "success") {
          const category = result.data;
          setFormData({
            name: category.name,
            status: Boolean(category.status),
            shipping_charge: category.shipping_charge || "0",
            hindi_name: category.translations?.hi?.name || "",
          });
          if (category.image) {
            setPreview(assetUrl(category.image));
          }
        } else {
          alert(result.message || "Category not found");
          navigate("/categories");
        }
      } catch (error) {
        console.error("Error fetching category:", error);
      } finally {
        setInitialLoading(false);
      }
    };
    fetchCategory();
  }, [id, navigate]);

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
    if (!formData.name) {
      alert("Name is required!");
      return;
    }

    setLoading(true);
    try {
      const data = new FormData();
      data.append("name", formData.name);
      data.append("status", formData.status ? 1 : 0);
      data.append("shipping_charge", formData.shipping_charge || 0);
      data.append("translations", JSON.stringify({ hi: { name: formData.hindi_name } }));
      
      if (imageFile) {
        data.append("image", imageFile);
      }

      const result = await apiRequest(`/admin/ecomm/categories/update/${id}`, {
        method: "POST",
        body: data,
      });
      if (result.status === "success") {
        alert("Category updated successfully!");
        navigate("/categories");
      } else {
        alert(result.message || "Failed to update category.");
      }
    } catch (error) {
      console.error("Error updating category:", error);
      alert("An error occurred. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  if (initialLoading) {
    return <div className="p-6">Loading category details...</div>;
  }

  return (
    <div className="bg-white p-6 rounded-lg shadow-sm font-sans mx-auto max-w-2xl">
      <div className="flex items-center gap-4 mb-6">
        <Link to="/categories" className="text-gray-500 hover:text-black">
          <ArrowLeft size={24} />
        </Link>
        <h1 className="text-2xl font-bold">Edit Category</h1>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Category Name */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Category Name *
          </label>
          <input
            type="text"
            name="name"
            value={formData.name}
            onChange={handleInputChange}
            className="w-full border border-gray-300 rounded-lg p-3 focus:outline-none focus:ring-2 focus:ring-yellow-500"
            placeholder="Enter category name"
            required
          />
        </div>
        <div className="grid gap-4 md:grid-cols-2">
          <div><label className="mb-1 block text-sm font-medium text-gray-700">Hindi Name</label><input name="hindi_name" value={formData.hindi_name} onChange={handleInputChange} className="w-full rounded-lg border p-3" /></div>
          <div><label className="mb-1 block text-sm font-medium text-gray-700">Shipping Charge (₹)</label><input type="number" min="0" step="0.01" name="shipping_charge" value={formData.shipping_charge} onChange={handleInputChange} className="w-full rounded-lg border p-3" /></div>
        </div>

        {/* Category Image Upload */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Category Image
          </label>
          <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 flex flex-col items-center justify-center relative bg-gray-50 hover:bg-gray-100 transition">
            {preview ? (
              <div className="flex flex-col items-center">
                <img src={preview} alt="Preview" className="h-32 object-contain mb-3 rounded-md" />
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
            Active Status (Visible to users)
          </label>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-4 pt-4 border-t">
          <Link
            to="/categories"
            className="px-6 py-2 border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50 transition"
          >
            Cancel
          </Link>
          <button
            type="submit"
            disabled={loading}
            className="px-6 py-2 bg-yellow-500 rounded-lg font-medium text-black hover:bg-yellow-600 transition disabled:opacity-50"
          >
            {loading ? "Updating..." : "Update Category"}
          </button>
        </div>
      </form>
    </div>
  );
}
