import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { apiRequest } from "../lib/api";

export default function AddCategory() {
  const [name, setName] = useState("");
  const [image, setImage] = useState(null);
  const [status, setStatus] = useState(true);
  const [shippingCharge, setShippingCharge] = useState("0");
  const [hindiName, setHindiName] = useState("");
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    const formData = new FormData();
    formData.append("name", name);
    formData.append("status", status ? 1 : 0);
    formData.append("shipping_charge", shippingCharge || 0);
    formData.append("translations", JSON.stringify({ hi: { name: hindiName } }));
    if (image) {
      formData.append("image", image);
    }

    try {
      const result = await apiRequest("/admin/ecomm/categories/create", {
        method: "POST",
        body: formData,
      });

      if (result.status === "success") {
        alert("Category Added Successfully!");
        navigate("/categories");
      } else {
        alert("Error adding category");
      }
    } catch (error) {
      console.error("Submit Error:", error);
      alert("Failed to submit");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white p-8 rounded-lg shadow-sm font-sans max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">Add New Category</h1>
      
      <form onSubmit={handleSubmit} className="space-y-5">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Category Name</label>
          <input
            type="text"
            required
            className="w-full border px-4 py-2 rounded-lg"
            placeholder="e.g. Ritual Kits"
            value={name}
            onChange={(e) => setName(e.target.value)}
          />
        </div>
        <div className="grid gap-4 md:grid-cols-2">
          <div><label className="mb-1 block text-sm font-medium text-gray-700">Hindi Name</label><input value={hindiName} onChange={(e) => setHindiName(e.target.value)} className="w-full rounded-lg border px-4 py-2" /></div>
          <div><label className="mb-1 block text-sm font-medium text-gray-700">Shipping Charge (₹)</label><input type="number" min="0" step="0.01" value={shippingCharge} onChange={(e) => setShippingCharge(e.target.value)} className="w-full rounded-lg border px-4 py-2" /></div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Category Image</label>
          <input
            type="file"
            accept="image/*"
            className="w-full border px-4 py-2 rounded-lg"
            onChange={(e) => setImage(e.target.files[0])}
          />
        </div>

        <div className="flex items-center gap-2">
          <input
            type="checkbox"
            id="status"
            checked={status}
            onChange={(e) => setStatus(e.target.checked)}
            className="w-4 h-4 cursor-pointer"
          />
          <label htmlFor="status" className="font-medium cursor-pointer text-gray-700">Active (Visible correctly on homepage)</label>
        </div>

        <button 
          type="submit" 
          disabled={loading}
          className="w-full bg-yellow-500 text-black py-3 rounded-lg font-bold hover:bg-yellow-600 transition disabled:opacity-50"
        >
          {loading ? "Adding..." : "Add Category"}
        </button>
      </form>
    </div>
  );
}
