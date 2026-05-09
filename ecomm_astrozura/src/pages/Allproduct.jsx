import { useState, useEffect } from "react";
import icon4 from "../assets/icon4.png";
import Footer from "../components/Footer";
import { useNavigate, useLocation } from "react-router-dom";
import axios from "axios";
import { useCart } from "../context/CartContext";

export default function ShopLayout() {
  const [price, setPrice] = useState(150);
  const [open, setOpen] = useState(false);
  const [sortOpen, setSortOpen] = useState(false);
  const [selected, setSelected] = useState("Featured");
  const [msg, setMsg] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedCatId, setSelectedCatId] = useState(null);
  
  const navigate = useNavigate();
  const location = useLocation();
  const { addToCart } = useCart();

  const [loading, setLoading] = useState(true);
  const [categories, setCategories] = useState([]);
  const [products, setProducts] = useState([]);

  const options = [
    "Featured",
    "Latest",
    "Price Low to High",
    "Price High to Low",
  ];

  const handleClearFilters = () => {
    setPrice(500);
    setSelected("Featured");
    setSelectedCatId(null);
    navigate("/allproduct", { replace: true });
    setMsg("Filters Cleared");
  };

  useEffect(() => {
    fetchData();
  }, []);

  useEffect(() => {
    const params = new URLSearchParams(location.search);
    const catId = params.get("category");
    if (catId) {
      setSelectedCatId(parseInt(catId));
    } else {
      setSelectedCatId(null);
    }
  }, [location.search]);

  const fetchData = async () => {
    try {
      setLoading(true);
      // VITE_API_BASE_URL already contains /api, so we don't add it again
      const baseUrl = import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000/api";
      
      const [catRes, prodRes] = await Promise.all([
        axios.get(`${baseUrl}/ecomm/categories`),
        axios.get(`${baseUrl}/ecomm/products`)
      ]);

      if (catRes.data.status === "success") {
        setCategories(catRes.data.data);
      }
      if (prodRes.data.status === "success") {
        setProducts(prodRes.data.data);
      }
    } catch (error) {
      console.error("Error fetching data:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (msg) {
      const timer = setTimeout(() => setMsg(""), 2000);
      return () => clearTimeout(timer);
    }
  }, [msg]);

  const getImage = (img) => {
    if (!img) return "https://placehold.co/400x400?text=No+Image";
    if (img.startsWith("http")) return img;
    const host = import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000";
    return `${host}/${img}`;
  };

  return (
    <>
      <div className="bg-[#f5f5f7] min-h-screen px-4 sm:px-6 lg:px-10 py-6">
        {/* TOAST */}
        {msg && (
          <div className="fixed top-20 left-1/2 -translate-x-1/2 bg-[#184070] text-white px-6 py-2 rounded-lg shadow-lg z-50 text-sm">
            {msg}
          </div>
        )}

        {/* MOBILE SIDEBAR */}
        {open && (
          <div className="fixed inset-0 z-50 flex">
            <div
              className="absolute inset-0 bg-black/40"
              onClick={() => setOpen(false)}
            ></div>

                <div className="relative w-[300px] bg-white h-full p-6 overflow-y-auto shadow-2xl flex flex-col">
                  <div className="flex justify-between items-center mb-8">
                    <h2 className="text-xl font-bold text-[#184070]">Filters</h2>
                    <button onClick={() => setOpen(false)} className="p-2 hover:bg-gray-100 rounded-full">
                      <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </div>

                  <h3 className="font-bold text-sm uppercase tracking-widest text-gray-400 mb-4">Categories</h3>
                  <ul className="space-y-1 text-sm mb-8">
                    {categories.length > 0 ? categories.map((cat, i) => (
                      <li 
                        key={i} 
                        onClick={() => {
                          setSelectedCatId(cat.id);
                          setOpen(false);
                          navigate(`/allproduct?category=${cat.id}`, { replace: true });
                        }}
                        className={`cursor-pointer py-2.5 px-4 rounded-xl transition-all ${
                          selectedCatId === cat.id ? "bg-[#184070] text-white shadow-lg shadow-[#184070]/20" : "hover:bg-gray-50 text-gray-600"
                        }`}
                      >
                        {cat.name}
                      </li>
                    )) : <p className="text-gray-400 px-4">No categories found</p>}
                  </ul>

                  <h3 className="font-bold text-sm uppercase tracking-widest text-gray-400 mb-4">Price Range</h3>
                  <div className="px-2">
                    <input
                      type="range"
                      min="10"
                      max="500"
                      value={price}
                      onChange={(e) => setPrice(e.target.value)}
                      className="w-full h-1.5 bg-gray-200 rounded-lg appearance-none cursor-pointer accent-[#184070]"
                    />
                    <div className="flex justify-between text-xs font-bold text-gray-500 mt-4">
                      <span className="bg-gray-100 px-3 py-1 rounded-full border">₹10</span>
                      <span className="bg-[#184070]/5 text-[#184070] px-3 py-1 rounded-full border border-[#184070]/20">Max: ₹{price}</span>
                    </div>
                  </div>

                  <div className="mt-auto pt-8 flex flex-col gap-3">
                    <button
                      onClick={() => {
                        handleClearFilters();
                        setOpen(false);
                      }}
                      className="w-full py-3.5 text-gray-600 font-bold rounded-xl border-2 border-gray-100 hover:bg-gray-50 active:scale-95 transition"
                    >
                      Clear All
                    </button>
                    <button
                      onClick={() => setOpen(false)}
                      className="w-full py-3.5 bg-[#184070] text-white font-bold rounded-xl shadow-lg shadow-[#184070]/20 active:scale-95 transition"
                    >
                      Apply Filters
                    </button>
                  </div>
                </div>
          </div>
        )}

        {/* HEADER */}
        <div className="mb-6">
          <p className="text-xs text-gray-600">Home & Shop</p>
          <h1 className="text-2xl sm:text-3xl lg:text-4xl font-semibold">
            {selectedCatId ? categories.find(c => c.id === selectedCatId)?.name : "Spiritual Store"}
          </h1>
          <p className="text-sm mt-2 max-w-xl">
            {selectedCatId ? `Explore our collection of ${categories.find(c => c.id === selectedCatId)?.name}` : "Ethically sourced treasures to inspire mindfulness."}
          </p>
        </div>

        {/* MOBILE BUTTON */}
        <button
          onClick={() => setOpen(true)}
          className="lg:hidden mb-4 w-full py-2 bg-[#184070] text-white rounded-lg"
        >
          Filters
        </button>

        <div className="flex flex-col lg:flex-row gap-6 lg:gap-10">
          
          {/* DESKTOP SIDEBAR */}
          <div className="hidden lg:block w-[260px] bg-white rounded-xl p-5 border h-fit">
            <h2 className="font-semibold mb-4">Categories</h2>

            <ul className="space-y-3 text-sm">
              {categories.length > 0 ? categories.map((cat, i) => (
                <li 
                  key={i} 
                  onClick={() => {
                    setSelectedCatId(cat.id);
                    navigate(`/allproduct?category=${cat.id}`, { replace: true });
                  }}
                  className={`flex justify-between cursor-pointer py-1 px-2 rounded transition ${
                    selectedCatId === cat.id ? "bg-[#184070] text-white" : "hover:text-[#184070]"
                  }`}
                >
                  {cat.name}
                </li>
              )) : <p>Loading categories...</p>}
            </ul>

            <div className="border-t my-5"></div>

            <h2 className="font-semibold mb-2">Price Range</h2>

            <input
              type="range"
              min="10"
              max="500"
              value={price}
              onChange={(e) => setPrice(e.target.value)}
              className="w-full"
            />

            <div className="flex justify-between text-sm mt-2">
              <span className="border px-2 py-1 rounded">₹10</span>
              <span className="border px-2 py-1 rounded">₹{price}</span>
            </div>

            <button
              onClick={handleClearFilters}
              className="mt-4 w-full py-2 text-white rounded-lg bg-[#184070]"
            >
              Clear All Filters
            </button>
          </div>

          {/* RIGHT SIDE */}
          <div className="flex-1">
            {/* SORT BAR */}
            <div className="bg-white border rounded-xl px-4 py-3 flex justify-between items-center">
              <p className="text-sm text-gray-500">
                Showing {products.length} results
              </p>

              <div className="flex items-center gap-2 text-sm">
                Sort by:
                <div className="relative">
                  <div
                    onClick={() => setSortOpen(!sortOpen)}
                    className="cursor-pointer text-[#2c4c7c] font-medium"
                  >
                    {selected} ▼
                  </div>

                  {sortOpen && (
                    <div className="absolute right-0 mt-2 w-48 bg-white border rounded shadow">
                      {options.map((item, i) => (
                        <div
                          key={i}
                          onClick={() => {
                            setSelected(item);
                            setSortOpen(false);
                          }}
                          className={`px-3 py-2 cursor-pointer ${
                            selected === item
                              ? "bg-[#2c4c7c] text-white"
                              : ""
                          }`}
                        >
                          {item}
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>

            {loading ? (
              <div className="flex justify-center items-center py-20 w-full">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#184070]"></div>
              </div>
            ) : (
              <div className="grid grid-cols-2 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3 sm:gap-6 mt-6">
                {products.length > 0 ? (
                  products
                    .filter(p => !selectedCatId || p.category_id === selectedCatId)
                    .filter(p => p.price <= price)
                    .map((product, i) => (
                      <div
                        key={i}
                        className="group bg-white rounded-2xl border border-gray-100 hover:border-[#184070]/20 hover:shadow-xl hover:shadow-[#184070]/5 transition-all duration-300 flex flex-col overflow-hidden"
                      >
                        <div className="relative w-full aspect-square bg-gray-50 flex items-center justify-center overflow-hidden">
                          <img
                            src={getImage(product.image)}
                            className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
                            alt={product.name}
                          />
                          <div className="absolute top-2 right-2 flex flex-col gap-2 transform translate-x-12 group-hover:translate-x-0 transition-transform duration-300">
                            <button className="p-2 bg-white rounded-full shadow-md text-gray-400 hover:text-red-500 transition">
                              <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                                <path d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" />
                              </svg>
                            </button>
                          </div>
                        </div>

                        <div className="p-3 sm:p-4 flex flex-col flex-1">
                          <p className="text-[10px] font-bold text-[#d8b14a] uppercase tracking-widest mb-1 opacity-80">
                            {product.category?.name || "Spiritual"}
                          </p>

                          <h3
                            onClick={() => navigate(`/product/${product.id}`)}
                            className="text-[12px] sm:text-sm font-bold text-[#1e1b4b] line-clamp-2 cursor-pointer hover:text-[#184070] transition min-h-[32px] sm:min-h-[40px]"
                          >
                            {product.name}
                          </h3>

                          <div className="flex items-center gap-1 mt-2 mb-4">
                            {[...Array(5)].map((_, idx) => (
                              <img key={idx} src={icon4} className="w-3 h-3 grayscale opacity-30" alt="star" />
                            ))}
                            <span className="text-[10px] text-gray-400 font-medium ml-1">(0)</span>
                          </div>

                          <div className="mt-auto flex items-center justify-between gap-2 pt-4 border-t border-gray-50">
                            <p className="font-bold text-[#184070] text-base sm:text-lg">₹{product.price}</p>
                            <button
                              onClick={() => {
                                addToCart({
                                  id: product.id,
                                  name: product.name,
                                  price: product.price,
                                  image: getImage(product.image),
                                  category: product.category?.name || "Spiritual Tool",
                                  qty: 1,
                                });
                                setMsg(`${product.name} added to cart 🛒`);
                              }}
                              className="p-2 sm:p-2.5 rounded-xl bg-[#184070] text-white hover:bg-[#2c4c7c] active:scale-95 transition shadow-lg shadow-[#184070]/10"
                            >
                              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 4v16m8-8H4" />
                              </svg>
                            </button>
                          </div>
                        </div>
                      </div>
                    ))
                ) : (
                  <div className="col-span-full text-center py-20 bg-white rounded-3xl border-2 border-dashed border-gray-100">
                    <p className="font-bold text-gray-300 text-lg uppercase tracking-widest">No products found</p>
                  </div>
                )}
              </div>
            )}

            {/* PAGINATION */}
            <div className="flex justify-center mt-8 gap-2">
              {[1, 2, 3, 4].map((num) => (
                <button
                  key={num}
                  onClick={() => setCurrentPage(num)}
                  className={`w-8 h-8 rounded-full ${
                    currentPage === num
                      ? "bg-[#184070] text-white"
                      : "bg-white border"
                  }`}
                >
                  {num}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>

      <Footer />
    </>
  );
}