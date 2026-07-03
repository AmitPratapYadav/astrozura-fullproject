import { useEffect, useMemo, useState } from "react";
import { Link, useParams } from "react-router-dom";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";

const API_BASE = import.meta.env.VITE_API_BASE_URL || "https://astrozura.com/apigateway/index.php/api";
const BACKEND_BASE = import.meta.env.VITE_BACKEND_URL || "https://astrozura.com";
const SHOP_BASE = import.meta.env.VITE_SHOP_URL || "https://shop.astrozura.com";

const imageUrl = (path) => {
  if (!path) return "https://placehold.co/700x700?text=AstroZura";
  if (path.startsWith("http")) return path;
  return `${BACKEND_BASE}${path.startsWith("/") ? "" : "/"}${path}`;
};

export default function ProductDetail() {
  const { id } = useParams();
  const [product, setProduct] = useState(null);
  const [selectedVariantId, setSelectedVariantId] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadProduct = async () => {
      try {
        const response = await fetch(`${API_BASE}/ecomm/products/${id}`);
        const data = await response.json();
        if (data.status === "success") {
          setProduct(data.data);
          setSelectedVariantId(String(data.data.active_variants?.[0]?.id || ""));
        }
      } catch (error) {
        console.error("Failed to load product", error);
      } finally {
        setLoading(false);
      }
    };
    void loadProduct();
  }, [id]);

  const selectedVariant = useMemo(
    () => product?.active_variants?.find((variant) => String(variant.id) === selectedVariantId),
    [product, selectedVariantId]
  );

  if (loading) return <div className="min-h-screen bg-[#f7f8fa]"><Navbar /><p className="py-32 text-center">Loading product...</p></div>;
  if (!product) return <div className="min-h-screen bg-[#f7f8fa]"><Navbar /><p className="py-32 text-center">Product not found.</p></div>;

  const price = selectedVariant?.price ?? product.price;
  const shopLink = `${SHOP_BASE}/product/${product.id}${selectedVariant ? `?variant=${selectedVariant.id}` : ""}`;

  return (
    <div className="min-h-screen bg-[#f7f8fa] text-[#1E3557]">
      <Navbar />
      <main className="mx-auto max-w-6xl px-4 py-10 md:px-8">
        <Link to="/products" className="text-sm font-semibold text-[#D4A73C]">Back to products</Link>
        <div className="mt-5 grid gap-10 rounded-lg border border-gray-200 bg-white p-5 shadow-sm md:grid-cols-2 md:p-9">
          <div className="aspect-square overflow-hidden rounded-lg bg-gray-50">
            <img src={imageUrl(selectedVariant?.image || product.image)} alt={product.name} className="h-full w-full object-contain p-8" />
          </div>
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.18em] text-[#D4A73C]">{product.category?.name}</p>
            <h1 className="mt-3 text-3xl font-black md:text-4xl">{product.name}</h1>
            <p className="mt-5 text-3xl font-black">Rs {Number(price).toLocaleString("en-IN")}</p>
            <p className="mt-5 whitespace-pre-wrap leading-7 text-gray-600">{product.description}</p>

            {product.active_variants?.length > 0 && (
              <div className="mt-7">
                <label className="mb-2 block text-sm font-bold">Choose an option</label>
                <select value={selectedVariantId} onChange={(event) => setSelectedVariantId(event.target.value)} className="w-full rounded-lg border border-gray-300 bg-white px-4 py-3">
                  {product.active_variants.map((variant) => (
                    <option key={variant.id} value={variant.id} disabled={variant.stock_quantity < 1}>
                      {variant.title} - Rs {Number(variant.price).toLocaleString("en-IN")} {variant.stock_quantity < 1 ? "(Out of stock)" : ""}
                    </option>
                  ))}
                </select>
              </div>
            )}

            <a href={shopLink} className="mt-8 inline-flex rounded-lg bg-[#184070] px-6 py-3 font-bold text-white transition hover:bg-[#102d50]">
              Buy on Astral Shop
            </a>
          </div>
        </div>

        <div className="mt-8 grid gap-6 md:grid-cols-2">
          {product.benefits && <section className="rounded-lg border border-gray-200 bg-white p-6"><h2 className="text-xl font-bold">Benefits</h2><p className="mt-3 whitespace-pre-wrap leading-7 text-gray-600">{product.benefits}</p></section>}
          {product.specifications && <section className="rounded-lg border border-gray-200 bg-white p-6"><h2 className="text-xl font-bold">Specifications</h2><p className="mt-3 whitespace-pre-wrap leading-7 text-gray-600">{product.specifications}</p></section>}
        </div>
      </main>
      <Footer />
    </div>
  );
}
