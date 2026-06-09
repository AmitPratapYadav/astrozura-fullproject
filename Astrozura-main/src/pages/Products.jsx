import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { PackageSearch, SlidersHorizontal } from "lucide-react";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";

const API_BASE = import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000/api";
const BACKEND_BASE = import.meta.env.VITE_BACKEND_URL || "http://127.0.0.1:8000";

const imageUrl = (path) => {
  if (!path) return "https://placehold.co/600x600?text=AstroZura";
  if (path.startsWith("http")) return path;
  return `${BACKEND_BASE}${path.startsWith("/") ? "" : "/"}${path}`;
};

export default function Products() {
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [categoryId, setCategoryId] = useState("");
  const [sort, setSort] = useState("latest");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadCatalog = async () => {
      try {
        const [categoryResponse, productResponse] = await Promise.all([
          fetch(`${API_BASE}/ecomm/categories`),
          fetch(`${API_BASE}/ecomm/products`),
        ]);
        const [categoryData, productData] = await Promise.all([
          categoryResponse.json(),
          productResponse.json(),
        ]);
        setCategories(categoryData.data || []);
        setProducts(productData.data || []);
      } catch (error) {
        console.error("Failed to load product catalog", error);
      } finally {
        setLoading(false);
      }
    };

    void loadCatalog();
  }, []);

  const visibleProducts = useMemo(() => {
    const filtered = categoryId
      ? products.filter((product) => String(product.category_id) === String(categoryId))
      : products;

    return [...filtered].sort((a, b) => {
      if (sort === "price-low") return Number(a.price) - Number(b.price);
      if (sort === "price-high") return Number(b.price) - Number(a.price);
      return Number(b.id) - Number(a.id);
    });
  }, [categoryId, products, sort]);

  return (
    <div className="min-h-screen bg-[#f7f8fa] text-[#1E3557]">
      <Navbar />
      <main className="mx-auto max-w-7xl px-4 py-10 md:px-8">
        <div className="flex flex-col gap-5 border-b border-gray-200 pb-7 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-[#D4A73C]">Astral Shop</p>
            <h1 className="mt-2 text-4xl font-black">Spiritual Products</h1>
            <p className="mt-2 max-w-2xl text-sm text-gray-500">Products and categories are managed directly by AstroZura administrators.</p>
          </div>
          <div className="flex flex-wrap gap-3">
            <label className="flex items-center gap-2 rounded-lg border border-gray-200 bg-white px-3">
              <PackageSearch size={17} className="text-gray-400" />
              <select value={categoryId} onChange={(event) => setCategoryId(event.target.value)} className="bg-transparent py-3 text-sm outline-none">
                <option value="">All categories</option>
                {categories.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
              </select>
            </label>
            <label className="flex items-center gap-2 rounded-lg border border-gray-200 bg-white px-3">
              <SlidersHorizontal size={17} className="text-gray-400" />
              <select value={sort} onChange={(event) => setSort(event.target.value)} className="bg-transparent py-3 text-sm outline-none">
                <option value="latest">Latest</option>
                <option value="price-low">Price: low to high</option>
                <option value="price-high">Price: high to low</option>
              </select>
            </label>
          </div>
        </div>

        {loading ? (
          <div className="py-24 text-center text-gray-500">Loading products...</div>
        ) : (
          <div className="mt-8 grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-4">
            {visibleProducts.map((product) => (
              <Link key={product.id} to={`/product/${product.id}`} className="group overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm transition hover:-translate-y-1 hover:shadow-lg">
                <div className="aspect-square overflow-hidden bg-gray-50">
                  <img src={imageUrl(product.image)} alt={product.name} className="h-full w-full object-contain p-5 transition duration-300 group-hover:scale-105" />
                </div>
                <div className="p-4">
                  <p className="text-[10px] font-bold uppercase tracking-[0.16em] text-[#D4A73C]">{product.category?.name}</p>
                  <h2 className="mt-2 line-clamp-2 min-h-10 text-sm font-bold md:text-base">{product.name}</h2>
                  <div className="mt-4 flex items-end justify-between gap-2">
                    <p className="font-black">Rs {Number(product.price).toLocaleString("en-IN")}</p>
                    {product.active_variants?.length > 0 && <span className="text-[10px] text-gray-500">{product.active_variants.length} options</span>}
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}

        {!loading && !visibleProducts.length && (
          <div className="mt-8 rounded-lg border border-dashed border-gray-300 bg-white py-20 text-center text-gray-500">No active products are available in this category.</div>
        )}
      </main>
      <Footer />
    </div>
  );
}
