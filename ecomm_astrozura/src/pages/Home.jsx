import { useState, useEffect } from "react";
import axios from "axios";
import { useNavigate } from "react-router-dom";
import { useCart } from "../context/CartContext";
import heroImg from "../assets/1.jpg";
import arrow from "../assets/right-arrow.png";
import icon1 from "../assets/icon3.png";
import icon2 from "../assets/icon2.png";
import icon3 from "../assets/solar-energy.png";
import icon4 from "../assets/christmas-star.png";
import u1 from "../assets/u1.webp";
import u2 from "../assets/u2.jpg";
import u3 from "../assets/u3.avif";
import Footer from "../components/Footer";
import p1 from "../assets/p1.webp";
import p2 from "../assets/p2.webp";
import p3 from "../assets/pro1.jpg";
import p4 from "../assets/p4.webp";
import c1 from "../assets/c1.webp";
import moon1 from "../assets/moon1.webp";
import vedic from "../assets/k3.webp";
import rudraksha from "../assets/4.webp";
export default function Home() {
  const navigate = useNavigate();
  const { addToCart } = useCart();
  const [activeBtn, setActiveBtn] = useState("shop");
  const [clickedBtn, setClickedBtn] = useState({}); 
  const [categories, setCategories] = useState([]);
  const [trendingProducts, setTrendingProducts] = useState([]);
  const [msg, setMsg] = useState("");

  useEffect(() => {
    fetchCategories();
    fetchTrendingProducts();
  }, []);

  const backendUrl = import.meta.env.VITE_BACKEND_URL || "http://127.0.0.1:8000";
  const apiUrl = import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000/api";

  const fetchCategories = async () => {
    try {
      const { data } = await axios.get(`${apiUrl}/ecomm/categories`);
      if (data.status === "success") {
        setCategories(data.data);
      }
    } catch (error) {
      console.error("Error fetching categories", error);
    }
  };

  const fetchTrendingProducts = async () => {
    try {
      const { data } = await axios.get(`${apiUrl}/ecomm/products/trending`);
      if (data.status === "success") {
        setTrendingProducts(data.data);
      }
    } catch (error) {
      console.error("Error fetching products", error);
    }
  };

  const handleAddToCart = (item) => {
    if (item.active_variants?.length) {
      navigate(`/product/${item.id}`);
      return;
    }
    addToCart({
      id: item.id,
      name: item.name,
      price: item.price,
      image: `${backendUrl}/${item.image}`,
      category: item.category?.name || "Spiritual",
      qty: 1
    });
    setMsg(`${item.name} added to cart 🛒`);
    setTimeout(() => setMsg(""), 3000);
  };
  return (
    <div>
      {/* TOAST PANEL */}
      {msg && (
        <div className="fixed top-24 left-1/2 -translate-x-1/2 bg-[#23205b] text-white px-6 py-2 rounded-full shadow-2xl z-[999] text-sm font-medium border-2 border-[#d8ba4a] animate-bounce">
          {msg}
        </div>
      )}
      {/* HERO SECTION */}
      <div
        className="relative h-[420px] md:h-[520px] flex items-center"
        style={{
          backgroundImage: `url(${heroImg})`,
          backgroundSize: "cover",
          backgroundPosition: "center",
        }} >
        <div className="absolute inset-0 bg-gradient-to-r from-[#2c4c7c]/80 to-transparent"></div>
        <div className="relative z-10 px-6 sm:px-12 md:px-16 lg:px-24 w-full text-white">
          <div className="max-w-2xl">
            <p className="text-[10px] md:text-xs tracking-[0.2em] text-[#d8ba4a] mb-3 font-bold uppercase animate-pulse">
              SPIRITUAL COLLECTION
            </p>
            <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-extrabold leading-[1.1] mb-6 drop-shadow-lg">
              Discover Inner Peace <br />
              <span className="text-[#d8ba4a] italic font-serif">Through Sacred Energy</span>
            </h1>
            <p className="text-[13px] md:text-base text-gray-100 max-w-lg leading-relaxed opacity-90 mb-8 border-l-2 border-[#d8ba4a]/30 pl-4">
              Explore powerful crystals, authentic rudraksha, and spiritual tools
              designed to balance your energy and elevate your lifestyle.
            </p>
            <div className="flex flex-col sm:flex-row gap-4">
              <button
                onClick={() => navigate("/allproduct")}
                className="px-8 py-3.5 rounded-full font-bold transition-all bg-[#d8ba4a] text-black hover:bg-[#c4a441] hover:scale-105 active:scale-95 shadow-xl shadow-[#d8ba4a]/20" >
                Shop Now
              </button>
              <button
                onClick={() => setActiveBtn("view")}
                className={`px-8 py-3.5 rounded-full font-bold transition-all border-2 border-white/50 hover:border-white hover:bg-white/10 ${
                  activeBtn === "view" ? "bg-white text-black" : "text-white"
                }`} >
                View Lookbook
              </button>
            </div>
          </div>
        </div>
      </div>
     {/* CATEGORY SECTION */}
<div className="bg-gray-50 py-14 text-center">
  <p className="text-xs text-[#161439] tracking-widest">
    CURATED COLLECTIONS
  </p>

  <h2 className="text-2xl md:text-3xl font-bold mt-2 text-[#23205b]">
    Shop by Category
  </h2>

  <div className="max-w-6xl mx-auto mt-12 px-4 grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4 sm:gap-10">
    
    {categories.length > 0 ? (
      categories.map((cat) => (
        <div
          key={cat.id}
          onClick={() => navigate(`/all-products?category=${cat.id}`)}
          className="cursor-pointer hover:scale-110 transition text-center" >
          {cat.image ? (
            <img
              src={`${backendUrl}/${cat.image}`}
              alt={cat.name}
              className="w-24 h-24 sm:w-32 sm:h-32 rounded-full mx-auto object-cover shadow-md"  />
          ) : (
            <div className="w-24 h-24 sm:w-32 sm:h-32 rounded-full mx-auto bg-gray-200 border-2 border-dashed border-gray-300 flex items-center justify-center text-gray-400 text-xs shadow-md">
              No Image
            </div>
          )}
          <p className="mt-4 text-sm text-[#161439] font-medium">
            {cat.name}
          </p>
        </div>
      ))
    ) : (
      <p className="col-span-full text-gray-500 font-medium">No curated collections found right now.</p>
    )}
  </div>
</div>
     {/* TRENDING SECTION */}
<div className="py-16 px-6 md:px-16 bg-[#f8f9fc]">
  <div className="max-w-6xl mx-auto">
    <div className="flex justify-between items-center mb-10">
      <div>
        <p className="text-xs text-[#d8b14a] tracking-widest font-semibold">
          MOST LOVED
        </p>
        <h2 className="text-2xl md:text-3xl font-bold text-[#5e6bcd]">
          Trending This Week
        </h2>
      </div>
      <div
        onClick={() => alert("Redirecting ")}
        className="flex items-center gap-2 text-[#5e6bcd] cursor-pointer hover:underline" >
        <span className="text-sm font-medium">View All Arrivals</span>
        <img src={arrow} className="w-4 h-4" />
      </div>
    </div>
    {/* PRODUCTS */}
<div className="grid grid-cols-2 md:grid-cols-4 gap-3 sm:gap-6">
  {trendingProducts.length > 0 ? (
    trendingProducts.map((item) => (
      <div
        key={item.id}
        className="bg-white rounded-2xl p-4 shadow-sm hover:shadow-md transition" >
        {item.image ? (
          <img
            src={`${backendUrl}/${item.image}`}
            className="rounded-xl h-40 sm:h-52 w-full object-cover bg-gray-100" />
        ) : (
          <div className="rounded-xl h-40 sm:h-52 w-full bg-gray-200 border border-gray-100 flex items-center justify-center text-gray-400 text-xs">
            No Image
          </div>
        )}

        <p className="text-[10px] mt-4 text-[#161439] tracking-widest uppercase truncate">
          {item.category?.name || "Uncategorized"}
        </p>
        <h3 
          onClick={() => navigate(`/product/${item.id}`)}
          className="text-sm font-semibold text-[#5e6bcd] mt-1 truncate cursor-pointer hover:underline">
          {item.name}
        </h3>

        <p className="text-[#d8b14a] font-bold mt-1 text-sm sm:text-base">
          ₹{item.price}
        </p>
        <div className="flex gap-3 mt-4">
          <button
            onClick={() => {
              setClickedBtn({ ...clickedBtn, [item.id]: "cart" });
              handleAddToCart(item);
            }}
            className={`flex-1 py-2 rounded-lg text-xs sm:text-sm font-medium transition ${
              (clickedBtn[item.id] || "cart") === "cart"
                ? "bg-[#23205b] text-white"
                : "bg-white text-black border"
            }`} >
            Add to Cart
          </button>
          <button
            onClick={() => {
              setClickedBtn({ ...clickedBtn, [item.id]: "buy" });
              if (item.active_variants?.length) {
                navigate(`/product/${item.id}`);
                return;
              }
              addToCart({
                id: item.id,
                name: item.name,
                price: item.price,
                image: `${backendUrl}/${item.image}`,
                category: item.category?.name || "Spiritual",
                qty: 1
              });
              navigate("/checkout");
            }}
            className={`flex-1 py-2 rounded-lg text-xs sm:text-sm font-medium transition ${
              (clickedBtn[item.id] || "cart") === "buy"
                ? "bg-[#23205b] text-white"
                : "bg-white text-black border"
            }`} >
            Buy Now
          </button>
        </div>
      </div>
    ))
  ) : (
    <p className="col-span-full text-gray-500 font-medium my-10 text-center">New arrivals are currently being updated.</p>
  )}
</div>
  </div>
</div>
      {/* FEATURE SECTION */}
      <div className="bg-[#4974a4] py-10 px-6 md:px-16 text-center text-white">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
          {[
            {
              icon: icon1,
              title: "Ethically Sourced",
              desc: "Supporting local artisans globally.",
            },
            {
              icon: icon2,
              title: "Fast Delivery",
              desc: "Quick & safe shipping worldwide.",
            },
            {
              icon: icon3,
              title: "Energy Cleansed",
              desc: "All items purified before shipping.",
            },
            {
              icon: icon4,
              title: "Trusted by 15k+",
              desc: "Loved by our spiritual community.",
            },
          ].map((item, i) => (
            <div key={i} className="hover:scale-105 transition">
              <img src={item.icon} className="w-10 mx-auto mb-3" />
              <h3 className="font-semibold">{item.title}</h3>
              <p className="text-sm opacity-80 mt-1">{item.desc}</p>
            </div>
          ))}
        </div>
      </div>

      {/* TESTIMONIAL */}
<div className="bg-gray-50 py-14 px-6 md:px-16 text-center">
  <p className="text-xs text-[#23205b] tracking-widest">
    CUSTOMER STORIES
  </p>

  <h2 className="text-2xl md:text-3xl font-bold mt-2 text-[#184070]">
    What Our Tribe Says
  </h2>

  <div className="grid md:grid-cols-3 gap-8 mt-10">
    {[
      {
        img: u1,
        text: `"The citrine point I received is absolutely breathtaking. You can feel the energy radiating from it. Truly the best crystal shop I've found."`,
        name: "Sienna Grace",
        role: "Yoga Instructor",
      },
      {
        img: u2,
        text: `"Finding authentic rudraksha is difficult, but Aura & Earth is my trusted source. The quality is unmatched and the packaging is beautiful."`,
        name: "Marcus Thorne",
        role: "Meditation Practitioner",
      },
      {
        img: u3,
        text: `"The ritual kits make the perfect gift for loved ones. They are curated with such intention and care. I buy one for every housewarming!"`,
        name: "Elena Rossi",
        role: "Wellness Advocate",
      },
    ].map((item, i) => (
      <div
        key={i}
        className="bg-white p-6 rounded-xl shadow hover:shadow-lg transition"
      >
                {/*STARS (IMAGE ICON) */}
<div className="flex justify-center gap-1 mb-3">
  {[...Array(5)].map((_, i) => (
    <img key={i} src={icon4} className="w-4 h-4" />
  ))}
</div>
        {/* TEXT */}
        <p className="text-sm text-[#4974a4] italic leading-relaxed">
          {item.text}
        </p>
        {/* IMAGE */}
        <img
          src={item.img}
          className="w-14 h-14 rounded-full mx-auto mt-4 object-cover"
        />
        {/* NAME */}
        <h4 className="mt-3 font-semibold text-[#5e6bcd]">
          {item.name}
        </h4>
        {/* ROLE */}
        <p className="text-xs text-gray-500">{item.role}</p>
      </div>
    ))}
  </div>
</div>
      <Footer />
    </div>
  );
}
