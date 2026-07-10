import { useState, useEffect } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import axios from "axios";
import vedic from "../assets/vedic-astrology.png";
import cart from "../assets/carts.png";
import { useAuth } from "../context/AuthContext";
import { useCart } from "../context/CartContext";
import { assetUrl } from "../utils/assetUrl";
import api from "../api/axios";
import { Heart, MoreVertical, Search, X } from "lucide-react";
import CatalogImage from "./CatalogImage";

export default function Navbar() {
  const [menuOpen, setMenuOpen] = useState(false);
  const { user, logout } = useAuth();
  const { cartItems } = useCart();
  const navigate = useNavigate();
  const avatarImage = assetUrl(user?.profile_image);

  const [categories, setCategories] = useState([]);
  const [catMenuOpen, setCatMenuOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState([]);
  const [searching, setSearching] = useState(false);
  const [wishlistCount, setWishlistCount] = useState(0);

  const menuItems = [
    { path: "/allproduct?new_arrivals=1", name: "New Arrival", mega: "new-arrivals" },
    { path: "/allproduct?category_name=Gems", name: "Gems", mega: "gems" },
    { path: "/guide-book", name: "Guide Book" },
    { path: "https://astrozura.com", name: "Follow Your Stars", external: true },
  ];
  const gemsCategory = categories.find((category) => /gems?|gemstones?|crystals?/i.test(category.name || ""));

  const apiUrl = import.meta.env.VITE_API_BASE_URL || "https://astrozura.com/apigateway/index.php/api";

  useEffect(() => {
    fetchCategories();
  }, []);

  useEffect(() => {
    if (!user) {
      setWishlistCount(0);
      return;
    }
    api.get("/dashboard/wishlist")
      .then((response) => setWishlistCount(response.data?.data?.length || 0))
      .catch(() => setWishlistCount(0));
  }, [user]);

  useEffect(() => {
    if (!searchOpen || searchQuery.trim().length < 2) {
      setSearchResults([]);
      return undefined;
    }

    const timer = window.setTimeout(async () => {
      try {
        setSearching(true);
        const response = await axios.get(`${apiUrl}/ecomm/products`, {
          params: { q: searchQuery.trim() },
        });
        setSearchResults((response.data?.data || []).slice(0, 8));
      } finally {
        setSearching(false);
      }
    }, 250);
    return () => window.clearTimeout(timer);
  }, [searchOpen, searchQuery, apiUrl]);

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

  const handleLogout = async () => {
    await logout();
    navigate("/");
  };

  return (
    <>
      <nav className="relative sticky top-0 z-50 bg-white px-3 py-3 shadow-sm md:px-10 md:py-6">
        <div className="flex justify-between items-center">

          {/* LOGO */}
          <NavLink to="/">
            <img src={vedic} alt="logo" className="h-10 w-auto max-w-[128px] cursor-pointer object-contain md:h-16 md:max-w-none" />
          </NavLink>

          {/* DESKTOP MENU */}
          <ul className="hidden md:flex gap-6 text-sm items-center font-medium">
            {/* SHOP BY CATEGORIES DROPDOWN */}
            <li 
              className="relative group"
              onMouseEnter={() => setCatMenuOpen(true)}
              onMouseLeave={() => setCatMenuOpen(false)}
            >
              <button className="flex items-center gap-1 px-3 py-1.5 rounded-md text-gray-700 hover:bg-[#D4A73C] transition">
                Shop by Categories
                <svg className={`w-4 h-4 transition-transform ${catMenuOpen ? 'rotate-180' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7" />
                </svg>
              </button>

              {catMenuOpen && (
                <div className="absolute left-0 top-full w-56 bg-white rounded-xl shadow-xl border border-gray-100 py-2 z-[60] animate-in fade-in slide-in-from-top-2 duration-200">
                  {categories.length > 0 ? (
                    categories.map((cat) => (
                      <NavLink
                        key={cat.id}
                        to={`/allproduct?category=${cat.id}`}
                        onClick={() => setCatMenuOpen(false)}
                        className="block px-4 py-2.5 text-sm text-gray-600 hover:bg-[#d8b14a]/10 hover:text-[#d8b14a] transition"
                      >
                        {cat.name}
                      </NavLink>
                    ))
                  ) : (
                    <p className="px-4 py-2 text-xs text-gray-400">Loading categories...</p>
                  )}
                </div>
              )}
            </li>

            {menuItems.map((item, i) => (
              <li key={i} className={item.mega ? "group relative" : ""}>
                {item.external ? (
                  <a
                    href={item.path}
                    className="rounded-md px-3 py-1.5 text-gray-700 transition hover:bg-[#D4A73C]"
                  >
                    {item.name}
                  </a>
                ) : <NavLink
                  to={item.path}
                  className={({ isActive }) =>
                    `px-3 py-1.5 rounded-md transition ${isActive
                      ? "bg-[#d8b14a] text-white"
                      : "text-gray-700 hover:bg-[#D4A73C]"
                    }`
                  }>
                  {item.name}
                </NavLink>}
                {item.mega && (
                  <div className="invisible absolute left-0 top-full z-[65] mt-2 w-[360px] rounded-2xl border border-gray-100 bg-white p-4 opacity-0 shadow-2xl transition-all duration-200 group-hover:visible group-hover:translate-y-0 group-hover:opacity-100">
                    <div className="grid gap-3">
                      <NavLink to={item.path} className="rounded-xl bg-[#1E3557] px-4 py-3 text-sm font-bold text-white">
                        {item.mega === "new-arrivals" ? "Explore New Arrival Products" : "Explore Gems Collection"}
                      </NavLink>
                      {item.mega === "gems" && gemsCategory && (
                        <NavLink to={`/allproduct?category=${gemsCategory.id}`} className="rounded-xl bg-[#fff8df] px-4 py-3 text-sm font-bold text-[#1E3557]">
                          {gemsCategory.name}
                        </NavLink>
                      )}
                      <NavLink to={`/guide-book${item.mega === "gems" ? "?category=gems" : ""}`} className="rounded-xl border border-gray-100 px-4 py-3 text-sm font-bold text-[#1E3557] hover:bg-gray-50">
                        Guide Book
                      </NavLink>
                    </div>
                  </div>
                )}
              </li>
            ))}
          </ul>

          {/* RIGHT SIDE */}
          <div className="flex min-w-0 items-center gap-1 sm:gap-2 md:gap-5">
            <button
              type="button"
              onClick={() => setSearchOpen((current) => !current)}
              className="rounded-full p-2 text-[#1E3557] transition hover:bg-[#FFF6D8]"
              aria-label="Search products"
            >
              {searchOpen ? <X size={21} /> : <Search size={21} />}
            </button>

            {user && (
              <NavLink to="/dashboard/wishlist" className="relative rounded-full p-2 text-[#1E3557] transition hover:bg-[#FFF6D8]" aria-label="Wishlist">
                <Heart size={21} />
                {wishlistCount > 0 && (
                  <span className="absolute -right-1 -top-1 flex min-w-4 items-center justify-center rounded-full bg-red-500 px-1 text-[9px] font-bold text-white">
                    {wishlistCount > 99 ? "99+" : wishlistCount}
                  </span>
                )}
              </NavLink>
            )}

            {/* CART */}
            <NavLink to="/cart" className="relative flex items-center group">
              <img
                src={cart}
                alt="cart"
                className="h-6 w-6 cursor-pointer group-hover:scale-110 transition duration-200"
              />
              {cartItems.length > 0 && (
                <span className="absolute -top-2 -right-2 bg-red-500 text-white text-[10px] font-bold w-5 h-5 rounded-full flex items-center justify-center border-2 border-white shadow-sm leading-none">
                  {cartItems.reduce((acc, item) => acc + item.qty, 0)}
                </span>
              )}
            </NavLink>

            {/* AUTH BUTTONS */}
            {user ? (
              <div className="relative group pl-2 border-l border-gray-200">
                {/* Profile Toggle */}
                <div className="flex h-9 w-9 cursor-pointer items-center justify-center overflow-hidden rounded-full border border-gray-100 bg-gray-50 transition hover:bg-gray-100">
                  <div className="flex h-8 w-8 items-center justify-center overflow-hidden rounded-full bg-[#d8b14a] text-xs font-bold text-white">
                    {avatarImage ? (
                      <img src={avatarImage} alt={user.name || "User"} className="h-full w-full object-cover" />
                    ) : (
                      user.name ? user.name[0].toUpperCase() : "U"
                    )}
                  </div>
                </div>

                {/* Dropdown Menu */}
                <div className="absolute left-1/2 -translate-x-1/2 top-full mt-3 w-40 bg-white rounded-xl shadow-xl border border-gray-100 opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-300 transform translate-y-2 group-hover:translate-y-0 z-[60]">
                  <div className="p-1">
                    <NavLink 
                      to="/dashboard" 
                      className="block px-4 py-2 text-xs font-semibold text-gray-700 hover:bg-[#d8b14a]/10 hover:text-[#d8b14a] rounded-lg transition">
                      Dashboard
                    </NavLink>
                    <button
                      onClick={handleLogout}
                      className="w-full text-left px-4 py-2 text-xs font-semibold text-red-500 hover:bg-red-50 rounded-lg transition mt-1 border-t border-gray-50 pt-2">
                      Logout
                    </button>
                  </div>
                </div>
              </div>
            ) : (
              <NavLink to="/login">
                <button className="whitespace-nowrap rounded-full bg-[#1E3557] px-3 py-2 text-xs font-bold text-white shadow-sm transition-all duration-200 hover:bg-[#162744] hover:shadow-md sm:px-5 sm:text-sm">
                  Sign In
                </button>
              </NavLink>
            )}

            {/* MOBILE MENU TOGGLE */}
            <button
              onClick={() => setMenuOpen(!menuOpen)}
              className="md:hidden">
              <MoreVertical className="h-7 w-7 text-[#D4A73C]" aria-label="menu" />
            </button>
          </div>
        </div>

        {searchOpen && (
          <div className="absolute left-1/2 top-full z-[70] w-[min(94vw,680px)] -translate-x-1/2 rounded-b-2xl border border-gray-100 bg-white p-4 shadow-2xl">
            <div className="flex items-center gap-3 rounded-xl border border-gray-200 px-4 py-3">
              <Search size={18} className="text-gray-400" />
              <input
                autoFocus
                value={searchQuery}
                onChange={(event) => setSearchQuery(event.target.value)}
                placeholder="Search products..."
                className="min-w-0 flex-1 bg-transparent text-sm outline-none"
              />
            </div>
            <div className="mt-3 max-h-[55vh] overflow-y-auto">
              {searching ? (
                <p className="px-3 py-6 text-center text-sm text-gray-500">Searching...</p>
              ) : searchQuery.trim().length >= 2 && !searchResults.length ? (
                <p className="px-3 py-6 text-center text-sm text-gray-500">No products found.</p>
              ) : (
                searchResults.map((product) => (
                  <button
                    key={product.id}
                    type="button"
                    onClick={() => {
                      setSearchOpen(false);
                      setSearchQuery("");
                      navigate(`/product/${product.id}`);
                    }}
                    className="flex w-full items-center gap-3 rounded-xl p-3 text-left transition hover:bg-gray-50"
                  >
                    <CatalogImage src={product.image} alt={product.name} className="h-12 w-12 rounded-lg object-cover" />
                    <span className="min-w-0 flex-1">
                      <strong className="block truncate text-sm text-[#1E3557]">{product.name}</strong>
                      <span className="text-xs text-gray-500">Rs {product.price}</span>
                    </span>
                  </button>
                ))
              )}
            </div>
          </div>
        )}

        {/* MOBILE MENU DRAWER */}
        <div className={`fixed inset-0 z-[60] md:hidden transition-all duration-300 ${menuOpen ? "visible" : "invisible"}`}>
          {/* Backdrop */}
          <div 
            className={`absolute inset-0 bg-black/40 backdrop-blur-sm transition-opacity duration-300 ${menuOpen ? "opacity-100" : "opacity-0"}`}
            onClick={() => setMenuOpen(false)}
          ></div>
          
          {/* Drawer Content */}
          <div className={`absolute right-0 top-0 h-full w-[280px] bg-white shadow-2xl transition-transform duration-300 transform ${menuOpen ? "translate-x-0" : "translate-x-full"}`}>
            <div className="p-6 flex flex-col h-full overflow-y-auto">
              <div className="flex justify-between items-center mb-10">
                <NavLink to="/" onClick={() => setMenuOpen(false)}>
                  <img src={vedic} alt="logo" className="h-10 object-contain" />
                </NavLink>
                <button onClick={() => setMenuOpen(false)} className="p-2 -mr-2 text-gray-400 hover:text-[#1E3557] bg-gray-50 rounded-xl transition-all active:scale-90">
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              <ul className="flex flex-col gap-1 text-gray-700">
                {/* MOBILE CATEGORIES ACCORDION/LIST */}
                <li className="mb-2">
                  <button 
                    onClick={() => setCatMenuOpen(!catMenuOpen)}
                    className="flex items-center justify-between w-full px-4 py-3 rounded-xl font-semibold text-gray-600 hover:bg-gray-50 transition-all"
                  >
                    <span>Shop by Categories</span>
                    <svg className={`w-5 h-5 transition-transform ${catMenuOpen ? 'rotate-180' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7" />
                    </svg>
                  </button>
                  
                  {catMenuOpen && (
                    <div className="pl-4 mt-1 flex flex-col gap-1 animate-in slide-in-from-top-2 duration-200">
                      {categories.map((cat) => (
                        <NavLink
                          key={cat.id}
                          to={`/allproduct?category=${cat.id}`}
                          onClick={() => { setMenuOpen(false); setCatMenuOpen(false); }}
                          className="block px-4 py-2.5 text-sm text-gray-500 hover:text-[#d8b14a] transition"
                        >
                          {cat.name}
                        </NavLink>
                      ))}
                    </div>
                  )}
                </li>

                {menuItems.map((item, i) => (
                  <li key={i}>
                    {item.external ? (
                      <a
                        href={item.path}
                        onClick={() => setMenuOpen(false)}
                        className="flex items-center rounded-xl px-4 py-3 font-semibold text-gray-600 transition hover:bg-gray-50"
                      >
                        {item.name}
                      </a>
                    ) : <NavLink
                      to={item.path}
                      onClick={() => setMenuOpen(false)}
                      className={({ isActive }) =>
                        `flex items-center px-4 py-3 rounded-xl font-semibold transition-all ${isActive
                          ? "bg-[#d8b14a] text-white shadow-md shadow-[#d8b14a]/20"
                          : "hover:bg-gray-50 text-gray-600"
                        }`
                      }>
                      {item.name}
                    </NavLink>}
                  </li>
                ))}

                <li className="mt-4 pt-4 border-t border-gray-100">
                  <NavLink
                    to="/cart"
                    onClick={() => setMenuOpen(false)}
                    className="flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-gray-50 text-gray-600 font-semibold">
                    <div className="relative">
                      <img src={cart} alt="cart" className="h-5 w-5" />
                      {cartItems.length > 0 && (
                        <span className="absolute -top-1.5 -right-1.5 bg-red-500 text-white text-[8px] font-bold w-4 h-4 rounded-full flex items-center justify-center border border-white">
                          {cartItems.reduce((acc, item) => acc + item.qty, 0)}
                        </span>
                      )}
                    </div>
                    Cart
                  </NavLink>
                </li>

                {user ? (
                  <>
                    <li>
                      <NavLink
                        to="/dashboard/wishlist"
                        onClick={() => setMenuOpen(false)}
                        className="flex items-center gap-3 rounded-xl px-4 py-3 font-semibold text-gray-600 hover:bg-gray-50"
                      >
                        <Heart size={18} /> Wishlist ({wishlistCount})
                      </NavLink>
                    </li>
                    <li className="mt-1">
                      <NavLink
                        to="/dashboard"
                        onClick={() => setMenuOpen(false)}
                        className="flex items-center px-4 py-3 rounded-xl hover:bg-gray-50 text-gray-600 font-semibold">
                        Dashboard
                      </NavLink>
                    </li>
                    <li className="mt-auto pb-4">
                      <button
                        onClick={() => { handleLogout(); setMenuOpen(false); }}
                        className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-red-500 bg-red-50 font-semibold hover:bg-red-100 transition">
                        Logout
                      </button>
                    </li>
                  </>
                ) : (
                  <li className="mt-4">
                    <NavLink
                      to="/login"
                      onClick={() => setMenuOpen(false)}
                      className="block px-4 py-3 rounded-xl bg-[#1E3557] text-white text-center font-bold shadow-lg shadow-[#1E3557]/20 active:scale-95 transition">
                      Sign In
                    </NavLink>
                  </li>
                )}
              </ul>

              <div className="mt-auto text-center pb-6">
                <p className="text-[10px] text-gray-400 uppercase tracking-widest font-bold">AstroZura Spiritual Collects</p>
              </div>
            </div>
          </div>
        </div>
      </nav>
    </>
  );
}
