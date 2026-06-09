import React, { useRef, useState, useEffect } from "react";
import { Link } from "react-router-dom";
import { Plus, Trash2, Edit, Upload, LoaderCircle } from "lucide-react";
import * as XLSX from "xlsx";
import { apiRequest, assetUrl } from "../lib/api";

export default function Products() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [importing, setImporting] = useState(false);
  const [importStatus, setImportStatus] = useState("");
  const fileInputRef = useRef(null);

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    try {
      const result = await apiRequest("/admin/ecomm/products");
      if (result.status === "success") {
        setProducts(result.data);
      }
    } catch (error) {
      console.error("Error fetching products:", error);
    } finally {
      setLoading(false);
    }
  };

  const deleteProduct = async (id) => {
    if (window.confirm("Are you sure you want to delete this product?")) {
      try {
        const result = await apiRequest(`/admin/ecomm/products/${id}`, {
          method: "DELETE",
        });
        if (result.status === "success") {
          fetchProducts();
        }
      } catch (error) {
        console.error("Error deleting product:", error);
      }
    }
  };

  const importCatalog = async (event) => {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) return;

    setImporting(true);
    setImportStatus("");

    try {
      const workbook = XLSX.read(await file.arrayBuffer(), { type: "array" });
      const sheet =
        workbook.Sheets["Product Catalog"] ||
        workbook.Sheets[workbook.SheetNames[0]];

      if (!sheet) {
        throw new Error("The workbook does not contain a product sheet.");
      }

      const rows = XLSX.utils.sheet_to_json(sheet, {
        range: 2,
        defval: "",
        raw: false,
      });

      const catalog = rows
        .map((row) => ({
          category: String(row.Category || "").trim(),
          name: String(row["Product Name"] || "").trim(),
          price: Number(
            String(row["Price (INR)"] || "")
              .replace(/[^\d.-]/g, "")
          ),
          unit: String(row.Unit || "").trim(),
          description: String(row["Product Description"] || "").trim(),
          specifications: String(row["Product Specifications"] || "").trim(),
          benefits: String(row["Who Should Use / Benefits"] || "").trim(),
          warnings_precautions: String(
            row["Warnings & Precautions"] || ""
          ).trim(),
        }))
        .filter(
          (row) =>
            row.category &&
            row.name &&
            Number.isFinite(row.price) &&
            row.price >= 0
        );

      if (!catalog.length) {
        throw new Error(
          "No valid product rows were found. Use the Product Catalog column format."
        );
      }

      const result = await apiRequest("/admin/ecomm/products/import", {
        method: "POST",
        body: { products: catalog },
      });

      setImportStatus(result.message);
      await fetchProducts();
    } catch (error) {
      console.error("Product import failed:", error);
      setImportStatus(error.message || "Product import failed.");
    } finally {
      setImporting(false);
    }
  };

  return (
    <div className="bg-white p-6 rounded-lg shadow-sm font-sans">
      <div className="flex flex-wrap justify-between items-center gap-4 mb-6">
        <h1 className="text-2xl font-bold">Products</h1>
        <div className="flex flex-wrap gap-3">
          <input
            ref={fileInputRef}
            type="file"
            accept=".xlsx,.xls"
            className="hidden"
            onChange={importCatalog}
          />
          <button
            type="button"
            disabled={importing}
            onClick={() => fileInputRef.current?.click()}
            className="border border-yellow-500 text-gray-800 px-4 py-2 rounded-lg font-medium flex items-center gap-2 hover:bg-yellow-50 transition disabled:opacity-50"
          >
            {importing ? (
              <LoaderCircle size={18} className="animate-spin" />
            ) : (
              <Upload size={18} />
            )}
            {importing ? "Importing..." : "Import Excel"}
          </button>
          <Link to="/add-product" className="bg-yellow-500 text-black px-4 py-2 rounded-lg font-medium flex items-center gap-2 hover:bg-yellow-600 transition">
            <Plus size={18} /> Add New Product
          </Link>
        </div>
      </div>

      {importStatus && (
        <div className="mb-5 border border-yellow-200 bg-yellow-50 px-4 py-3 text-sm text-gray-700 rounded-md">
          {importStatus}
        </div>
      )}

      {loading ? (
        <p>Loading...</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-100 text-gray-700">
                <th className="p-3 border-b">ID</th>
                <th className="p-3 border-b">Image</th>
                <th className="p-3 border-b">Name</th>
                <th className="p-3 border-b">Category</th>
                <th className="p-3 border-b">Price</th>
                <th className="p-3 border-b">Variants</th>
                <th className="p-3 border-b">Trending</th>
                <th className="p-3 border-b">Actions</th>
              </tr>
            </thead>
            <tbody>
              {products.length > 0 ? (
                products.map((prod) => (
                  <tr key={prod.id} className="border-b hover:bg-gray-50">
                    <td className="p-3">#{prod.id}</td>
                    <td className="p-3">
                      {prod.image ? (
                        <img src={assetUrl(prod.image)} alt={prod.name} className="w-12 h-12 object-cover rounded-md" />
                      ) : (
                        <span className="text-gray-400">No Image</span>
                      )}
                    </td>
                    <td className="p-3 font-medium">{prod.name}</td>
                    <td className="p-3 text-sm">{prod.category?.name}</td>
                    <td className="p-3 font-bold">
                      ₹{prod.price}
                      {prod.unit && (
                        <span className="block text-xs font-normal text-gray-500">
                          {prod.unit}
                        </span>
                      )}
                    </td>
                    <td className="p-3">{prod.variants?.length || 0}</td>
                    <td className="p-3">
                      <span className={`px-2 py-1 rounded-full text-xs ${prod.is_trending ? "bg-amber-100 text-amber-700" : "bg-gray-100 text-gray-600"}`}>
                        {prod.is_trending ? "Yes" : "No"}
                      </span>
                    </td>
                    <td className="p-3">
                      <div className="flex gap-3">
                        <Link to={`/edit-product/${prod.id}`} className="text-blue-500 hover:text-blue-700">
                          <Edit size={18} />
                        </Link>
                        <button onClick={() => deleteProduct(prod.id)} className="text-red-500 hover:text-red-700">
                          <Trash2 size={18} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan="8" className="p-3 text-center text-gray-500">No products found.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
