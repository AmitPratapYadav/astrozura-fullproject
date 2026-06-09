import { useState, useEffect } from "react";
import Navbar from "../components/Navbar";
import { useNavigate, useParams, useSearchParams } from "react-router-dom";
import Footer from "../components/Footer";
import axios from "axios";
import { useCart } from "../context/CartContext";
import arrow from "../assets/right-arrow.png";
import icon1 from "../assets/icon1.png";
import icon2 from "../assets/icon2.png";
import icon3 from "../assets/icon3.png";
import icon4 from "../assets/icon4.png";
import heart from "../assets/heart.png";
import plus from "../assets/plus.png";
import minus from "../assets/minus.png";

const splitDetails = (value) =>
  String(value || "")
    .split(/\s*\|\s*|\r?\n/)
    .map((item) => item.trim())
    .filter(Boolean);

export default function ProductPage() {
  const { id } = useParams();
  const [product, setProduct] = useState(null);
  const [loading, setLoading] = useState(true);
  const [quantity, setQuantity] = useState(1);
  const [activeTab, setActiveTab] = useState("description");
  const [selectedVariantId, setSelectedVariantId] = useState("");
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { addToCart } = useCart();

  const baseUrl = import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000/api";
  const backendUrl = import.meta.env.VITE_BACKEND_URL || "http://127.0.0.1:8000";

  useEffect(() => {
    const fetchProduct = async () => {
      try {
        const { data } = await axios.get(`${baseUrl}/ecomm/products/${id}`);
        if (data.status === "success") {
          setProduct(data.data);
          const requestedVariant = searchParams.get("variant");
          const variants = data.data.active_variants || [];
          const initialVariant = variants.find((variant) => String(variant.id) === requestedVariant)
            || variants.find((variant) => Number(variant.stock_quantity) > 0)
            || variants[0];
          setSelectedVariantId(initialVariant ? String(initialVariant.id) : "");
        }
      } catch (error) {
        console.error("Error fetching product details", error);
      } finally {
        setLoading(false);
      }
    };
    fetchProduct();
  }, [id, baseUrl, searchParams]);

  if (loading) {
    return (
      <div className="flex justify-center items-center h-screen">
        <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-[#d8b14a]"></div>
      </div>
    );
  }

  if (!product) {
    return (
      <div className="flex justify-center items-center h-screen text-xl font-semibold text-gray-600">
        Product not found
      </div>
    );
  }

  const productImage = product.image
    ? product.image.startsWith("http://") || product.image.startsWith("https://")
      ? product.image
      : `${backendUrl}${product.image.startsWith("/") ? "" : "/"}${product.image}`
    : "https://placehold.co/400x400?text=No+Image";
  const selectedVariant = product.active_variants?.find((variant) => String(variant.id) === selectedVariantId);
  const selectedImage = selectedVariant?.image
    ? selectedVariant.image.startsWith("http")
      ? selectedVariant.image
      : `${backendUrl}${selectedVariant.image.startsWith("/") ? "" : "/"}${selectedVariant.image}`
    : productImage;
  const selectedPrice = selectedVariant?.price ?? product.price;
  const isOutOfStock = selectedVariant ? Number(selectedVariant.stock_quantity) < 1 : false;

  const detailTabs = [
    { id: "description", label: "Description" },
    { id: "benefits", label: "Benefits" },
    { id: "specifications", label: "Specifications" },
    { id: "warnings", label: "Care & Safety" },
  ];

  return (
    <>
      <div className="bg-[#fcfcff] min-h-screen">
        <div className="max-w-6xl mx-auto px-4 py-6">
          <div className="flex items-center gap-2 text-[10px] md:text-xs font-bold uppercase tracking-[0.1em] text-gray-400">
            <span className="hover:text-[#184070] cursor-pointer transition" onClick={() => navigate("/")}>Home</span>
            <span className="opacity-30">/</span>
            <span className="hover:text-[#184070] cursor-pointer transition" onClick={() => navigate("/allproduct")}>Shop</span>
            <span className="opacity-30">/</span>
            <span className="text-[#184070] truncate">{product.name}</span>
          </div>
        </div>

        {/* MAIN PRODUCT SECTION */}
        <div className="max-w-6xl mx-auto px-4 lg:px-0">
          <div className="bg-white rounded-2xl sm:rounded-[2rem] p-4 sm:p-8 lg:p-12 border border-gray-100 shadow-sm overflow-hidden mb-8 sm:mb-12">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-16">
              
              {/* LEFT: IMAGE AREA */}
              <div className="space-y-4">
                <div className="aspect-[4/5] md:aspect-square bg-[#f8f8fa] rounded-2xl sm:rounded-[2rem] overflow-hidden relative group border border-gray-50">
                  <img
                    src={selectedImage}
                    className="w-full h-full object-contain p-8 md:p-12 group-hover:scale-110 transition-transform duration-700"
                    alt={product.name}
                  />

                  <div className="absolute top-6 right-6 flex flex-col gap-3 transform translate-x-12 group-hover:translate-x-0 transition-transform duration-500">
                    <button className="bg-white p-3 rounded-2xl shadow-xl shadow-black/5 text-gray-400 hover:text-red-500 transition-all active:scale-95">
                      <img src={heart} className="w-5 h-5" alt="Favorite" />
                    </button>
                    <button className="bg-white p-3 rounded-2xl shadow-xl shadow-black/5 text-gray-400 hover:text-[#184070] transition-all active:scale-95">
                      <img src={icon2} className="w-5 h-5" alt="Share" />
                    </button>
                  </div>

                  <div className="absolute bottom-6 left-6">
                    <div className="px-4 py-2 bg-white/90 backdrop-blur-sm rounded-xl border border-white/20 shadow-lg flex items-center gap-2">
                       <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
                       <span className="text-[10px] font-bold text-gray-800 uppercase tracking-widest">{isOutOfStock ? "Out of Stock" : "In Stock"}</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* RIGHT: INFO AREA */}
              <div className="flex flex-col">
                <div className="mb-6">
                  <div className="inline-flex px-3 py-1 bg-[#d8b14a]/10 rounded-lg text-[#b89531] text-[10px] font-black uppercase tracking-[0.2em] mb-4">
                    {product.category?.name || "Spiritual Art"}
                  </div>

                  <h1 className="text-xl sm:text-2xl md:text-4xl font-black text-[#1e1b4b] leading-tight mb-4">
                    {product.name}
                  </h1>

                  <div className="flex items-center gap-4 py-4 border-y border-gray-50 mb-6">
                    <div className="flex items-center gap-1">
                      {[...Array(5)].map((_, i) => (
                        <img key={i} src={icon4} className="w-3.5 h-3.5" alt="Star" />
                      ))}
                    </div>
                    <span className="text-xs font-bold text-gray-400 border-l pl-4 tracking-widest uppercase">
                      4.9 (128 Reviews)
                    </span>
                  </div>

                  <div className="flex flex-wrap items-baseline gap-2 mb-6">
                    <span className="text-2xl sm:text-3xl md:text-4xl font-black text-[#184070]">Rs {selectedPrice}</span>
                    {selectedVariant?.compare_at_price && (
                      <span className="text-xs sm:text-sm text-gray-400 font-medium line-through decoration-red-400/30">Rs {selectedVariant.compare_at_price}</span>
                    )}
                    {product.unit && (
                      <span className="text-xs font-bold uppercase tracking-wider text-gray-400">
                        {product.unit}
                      </span>
                    )}
                  </div>

                  <p className="text-gray-500 text-sm leading-relaxed mb-8 border-l-4 border-[#d8b14a] pl-5 italic">
                    {product.description?.split('\n')[0] || `Authentic ${product.name} crafted with the finest spiritual traditions to invite peace and prosperity into your space.`}
                  </p>
                </div>

                {/* CONTROLS */}
                <div className="space-y-8 mt-auto">
                  {product.active_variants?.length > 0 && (
                    <div>
                      <p className="text-[10px] font-black uppercase tracking-widest text-[#1e1b4b]/40 mb-3">Choose Option</p>
                      <div className="flex flex-wrap gap-2">
                        {product.active_variants.map((variant) => (
                          <button
                            key={variant.id}
                            type="button"
                            onClick={() => setSelectedVariantId(String(variant.id))}
                            disabled={Number(variant.stock_quantity) < 1}
                            className={`rounded-xl border px-4 py-2 text-xs font-bold transition ${
                              String(variant.id) === selectedVariantId
                                ? "border-[#184070] bg-[#184070] text-white"
                                : "border-gray-200 bg-white text-gray-700"
                            } disabled:cursor-not-allowed disabled:opacity-40`}
                          >
                            {variant.title}
                          </button>
                        ))}
                      </div>
                    </div>
                  )}
                  <div className="flex flex-wrap items-center gap-6">
                    <div>
                      <p className="text-[10px] font-black uppercase tracking-widest text-[#1e1b4b]/40 mb-3">Select Quantity</p>
                      <div className="inline-flex items-center gap-4 bg-gray-50 p-2 rounded-2xl border border-gray-100">
                        <button
                          onClick={() => setQuantity(Math.max(1, quantity - 1))}
                          className="w-10 h-10 flex items-center justify-center bg-white rounded-xl shadow-sm hover:text-[#184070] transition active:scale-90" >
                          <img src={minus} className="w-3 h-3" alt="Decrease" />
                        </button>
                        <span className="font-bold text-lg min-w-[30px] text-center text-[#1e1b4b]">{quantity}</span>
                        <button
                          onClick={() => setQuantity(quantity + 1)}
                          className="w-10 h-10 flex items-center justify-center bg-white rounded-xl shadow-sm hover:text-[#184070] transition active:scale-90">
                          <img src={plus} className="w-3 h-3" alt="Increase" />
                        </button>
                      </div>
                    </div>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <button 
                      disabled={isOutOfStock}
                      onClick={() => {
                        addToCart({
                          id: product.id,
                          variant_id: selectedVariant?.id || null,
                          variant_title: selectedVariant?.title || null,
                          name: product.name,
                          price: selectedPrice,
                          image: selectedImage,
                          category: product.category?.name || "Spiritual Tool",
                          qty: quantity
                        });
                      }}
                      className="group flex-1 h-14 bg-white border-2 border-[#184070] text-[#184070] font-black text-xs uppercase tracking-widest rounded-2xl flex items-center justify-center gap-3 hover:bg-[#184070] hover:text-white transition-all duration-300 disabled:cursor-not-allowed disabled:opacity-40">
                      Add to Cart
                      <div className="w-6 h-6 rounded-lg bg-[#184070]/10 group-hover:bg-white/20 flex items-center justify-center">
                        <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M12 4v16m8-8H4"/></svg>
                      </div>
                    </button>

                    <button 
                      disabled={isOutOfStock}
                      onClick={() => {
                        addToCart({
                          id: product.id,
                          variant_id: selectedVariant?.id || null,
                          variant_title: selectedVariant?.title || null,
                          name: product.name,
                          price: selectedPrice,
                          image: selectedImage,
                          category: product.category?.name || "Spiritual Tool",
                          qty: quantity
                        });
                        navigate("/checkout");
                      }}
                      className="flex-1 h-14 bg-[#184070] text-white font-black text-xs uppercase tracking-widest rounded-2xl flex items-center justify-center gap-3 hover:bg-[#23205b] shadow-xl shadow-[#184070]/20 transition-all duration-300 active:scale-95">
                      Buy Now
                      <img src={arrow} className="w-4 h-4 brightness-0 invert" alt="Proceed" />
                    </button>
                  </div>
                </div>

                {/* TRUST BADGES */}
                <div className="grid grid-cols-3 gap-2 sm:gap-4 mt-8 sm:mt-12 py-6 border-t border-gray-50">
                  <div className="flex flex-col items-center text-center group cursor-help">
                    <div className="w-10 h-10 rounded-xl bg-gray-50 flex items-center justify-center mb-2 group-hover:bg-[#d8b14a]/10 transition-colors">
                      <img src={icon1} className="w-5 h-5 opacity-60 group-hover:opacity-100" alt="Returns" />
                    </div>
                    <span className="text-[9px] font-bold uppercase tracking-wider text-gray-400 group-hover:text-gray-600">30 Day Returns</span>
                  </div>
                  <div className="flex flex-col items-center text-center group cursor-help">
                    <div className="w-10 h-10 rounded-xl bg-gray-50 flex items-center justify-center mb-2 group-hover:bg-[#d8b14a]/10 transition-colors">
                      <img src={icon2} className="w-5 h-5 opacity-60 group-hover:opacity-100" alt="Shipping" />
                    </div>
                    <span className="text-[9px] font-bold uppercase tracking-wider text-gray-400 group-hover:text-gray-600">Free Shipping</span>
                  </div>
                  <div className="flex flex-col items-center text-center group cursor-help">
                    <div className="w-10 h-10 rounded-xl bg-gray-50 flex items-center justify-center mb-2 group-hover:bg-[#d8b14a]/10 transition-colors">
                      <img src={icon3} className="w-5 h-5 opacity-60 group-hover:opacity-100" alt="Authentic" />
                    </div>
                    <span className="text-[9px] font-bold uppercase tracking-wider text-gray-400 group-hover:text-gray-600">100% Authentic</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        {/* TABS & DETAILS SECTION */}
        <div className="max-w-6xl mx-auto px-4 mb-20">
          <div className="flex gap-4 sm:gap-8 border-b border-gray-100 mb-8 sm:mb-10 overflow-x-auto no-scrollbar">
            {detailTabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`pb-4 text-[10px] sm:text-xs font-black uppercase tracking-[0.2em] transition-all relative whitespace-nowrap ${
                  activeTab === tab.id ? "text-[#184070]" : "text-gray-300 hover:text-gray-400"
                }`}
              >
                {tab.label}
                {activeTab === tab.id && (
                  <div className="absolute bottom-0 left-0 w-full h-0.5 bg-[#d8b14a] rounded-full"></div>
                )}
              </button>
            ))}
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12">
            {/* LEFT CONTENT */}
            <div className="lg:col-span-7">
              <div className="prose prose-sm max-w-none text-gray-500 leading-loose">
                {activeTab === "description" && (
                  <div className="animate-fadeIn">
                    <h3 className="text-xl font-black text-[#1e1b4b] mb-6">Product Description</h3>
                    <p className="whitespace-pre-wrap">{product.description || "Divine energy and artistic excellence combined in this masterpiece."}</p>
                  </div>
                )}
                {activeTab === "benefits" && (
                  <div className="animate-fadeIn">
                    <h3 className="text-xl font-black text-[#1e1b4b] mb-6">Who Should Use It & Benefits</h3>
                    <p className="whitespace-pre-wrap">{product.benefits || "Invite clarity, peace, and positive vibrations into your surroundings."}</p>
                  </div>
                )}
                {activeTab === "specifications" && (
                  <div className="animate-fadeIn">
                    <h3 className="text-xl font-black text-[#1e1b4b] mb-6">Product Specifications</h3>
                    {splitDetails(product.specifications).length ? (
                      <dl className="border border-gray-100 rounded-md overflow-hidden">
                        {splitDetails(product.specifications).map((item, index) => {
                          const separator = item.indexOf(":");
                          const label = separator > 0 ? item.slice(0, separator) : `Detail ${index + 1}`;
                          const value = separator > 0 ? item.slice(separator + 1) : item;

                          return (
                            <div key={`${label}-${index}`} className="grid grid-cols-[minmax(110px,0.35fr)_1fr] gap-4 px-4 py-3 even:bg-gray-50">
                              <dt className="font-bold text-[#1e1b4b]">{label.trim()}</dt>
                              <dd>{value.trim()}</dd>
                            </div>
                          );
                        })}
                      </dl>
                    ) : (
                      <p>No additional specifications have been provided.</p>
                    )}
                  </div>
                )}
                {activeTab === "warnings" && (
                  <div className="animate-fadeIn">
                    <h3 className="text-xl font-black text-[#1e1b4b] mb-6">Warnings & Precautions</h3>
                    <div className="border-l-4 border-amber-400 bg-amber-50 px-5 py-4 text-amber-950 rounded-r-md whitespace-pre-wrap">
                      {product.warnings_precautions || "Follow the care instructions supplied with the product and keep it away from young children."}
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* RIGHT SPEC BOX */}
            <div className="lg:col-span-5">
              <div className="bg-[#184070] rounded-2xl sm:rounded-[2rem] p-5 sm:p-8 text-white relative overflow-hidden shadow-2xl shadow-[#184070]/20">
                {/* Decorative Pattern */}
                <div className="absolute top-0 right-0 w-32 h-32 bg-white/5 rounded-full -mr-16 -mt-16 blur-3xl"></div>
                
                <h4 className="text-sm font-black uppercase tracking-[0.2em] text-[#d8b14a] mb-8">Specifications</h4>
                
                <div className="space-y-5">
                  {[
                    { label: "Bead Count", value: product.bead_count },
                    { label: "Bead Size", value: product.bead_size },
                    { label: "Seed Type", value: product.seed_type },
                    { label: "Thread", value: product.thread_type },
                    { label: "Origin", value: product.origin },
                    { label: "Unit", value: product.unit },
                    { label: "Category", value: product.category?.name },
                  ].map((spec, i) => spec.value && (
                    <div key={i} className="flex justify-between items-center py-3 border-b border-white/10 last:border-0 hover:bg-white/5 px-2 rounded-xl transition-colors">
                      <span className="text-[10px] font-bold uppercase tracking-widest text-white/50">{spec.label}</span>
                      <span className="text-xs font-bold">{spec.value}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* CONSULT BANNER */}
        <div className="max-w-6xl mx-auto px-4 mb-20">
          <div className="bg-[#f2f2f7] rounded-3xl sm:rounded-[2.5rem] p-6 sm:p-8 md:p-12 relative overflow-hidden border border-white">
            <div className="relative z-10 flex flex-col md:flex-row items-center justify-between gap-8">
              <div className="text-center md:text-left">
                <div className="inline-flex px-3 py-1 bg-white rounded-full text-[9px] sm:text-[10px] font-black uppercase tracking-[0.2em] text-[#184070] mb-4">Expert Guidance</div>
                <h2 className="text-xl sm:text-2xl md:text-4xl font-black text-[#1b1c31] leading-tight max-w-md">
                  Seeking Divine Clarity in your Life?
                </h2>
                <p className="text-gray-500 text-sm mt-4 max-w-sm font-medium leading-relaxed">
                  Book a private session with our senior astrologers for personalized cosmic insights.
                </p>
              </div>

              <div className="flex flex-col sm:flex-row items-center gap-4">
                 <div className="flex -space-x-3">
                   {[1,2,3].map(i => (
                     <div key={i} className="w-10 h-10 rounded-full border-2 border-white bg-gray-200">
                       <img src={`https://i.pravatar.cc/100?img=${i+10}`} className="w-full h-full rounded-full" />
                     </div>
                   ))}
                 </div>
                 <div className="text-xs font-bold text-[#184070]/60 uppercase tracking-widest">50+ Expert Astrologers</div>
                 <button className="bg-[#184070] text-white px-10 py-5 rounded-2xl font-black text-[10px] uppercase tracking-widest hover:bg-[#23205b] hover:translate-y-[-2px] transition-all shadow-xl shadow-[#184070]/20">
                    Book Consult
                 </button>
              </div>
            </div>

            {/* Background elements */}
            <div className="absolute top-0 right-0 w-64 h-64 bg-[#d8b14a]/10 rounded-full -mr-32 -mt-32 blur-3xl"></div>
            <div className="absolute bottom-0 left-0 w-64 h-64 bg-[#184070]/5 rounded-full -ml-32 -mb-32 blur-3xl"></div>
          </div>
        </div>
      </div>
      <Footer />
    </>
  );
}


