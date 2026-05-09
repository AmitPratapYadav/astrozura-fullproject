import { useState, useEffect } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import axios from "axios";
import vedic from "../assets/vedic-astrology.png";
import menuIcon from "../assets/menu-icon.png";
import cart from "../assets/carts.png";
import { useAuth } from "../context/AuthContext";
import { useCart } from "../context/CartContext";

export default function Navbar() {
  const [menuOpen, setMenuOpen] = useState(false);
  const { user, logout } = useAuth();
  const { cartItems } = useCart();
  const navigate = useNavigate();

  const [categories, setCategories] = useState([]);
  const [catMenuOpen, setCatMenuOpen] = useState(false);

  const menuItems = [
    { path: "/allproduct", name: "Allproduct" },
    { path: "/Contact", name: "Contact us" },
    { path: "/About", name: "About us" }
  ];

  const apiUrl = import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000/api";

  useEffect(() => {
    fetchCategories();
  }, []);

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
      <nav className="bg-white shadow-sm px-4 md:px-10 py-6.5 sticky top-0 z-50">
        <div className="flex justify-between items-center">

          {/* LOGO */}
          <NavLink to="/">
            <img src={vedic} alt="logo" className="h-12 md:h-16 object-contain cursor-pointer" />
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
              <li key={i}>
                <NavLink
                  to={item.path}
                  className={({ isActive }) =>
                    `px-3 py-1.5 rounded-md transition ${isActive
                      ? "bg-[#d8b14a] text-white"
                      : "text-gray-700 hover:bg-[#D4A73C]"
                    }`
                  }>
                  {item.name}
                </NavLink>
              </li>
            ))}
          </ul>

          {/* RIGHT SIDE */}
          <div className="flex items-center gap-6">

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
                <div className="flex items-center gap-2 px-3 py-1.5 bg-gray-50 rounded-full border border-gray-100 cursor-pointer transition hover:bg-gray-100">
                  <span className="text-sm font-semibold text-gray-700">
                    {user.name?.split(" ")[0] || "User"}
                  </span>
                  <div className="w-6 h-6 bg-[#d8b14a] rounded-full flex items-center justify-center text-[10px] text-white font-bold">
                    {user.name ? user.name[0].toUpperCase() : "U"}
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
                <button className="bg-[#1E3557] text-white px-5 py-1.5 rounded-full text-sm font-bold hover:bg-[#162744] shadow-sm hover:shadow-md transition-all duration-200">
                  Sign In
                </button>
              </NavLink>
            )}

            {/* MOBILE MENU TOGGLE */}
            <button
              onClick={() => setMenuOpen(!menuOpen)}
              className="md:hidden">
              <img src={menuIcon} alt="menu" className="h-7 w-7" />
            </button>
          </div>
        </div>

        {/* MOBILE MENU DRAWER */}
        <div className={`fixed inset-0 z-[60] md:hidden transition-all duration-300 ${menuOpen ? "visible" : "invisible"}`}>
          {/* Backdrop */}
          <div 
            className={`absolute inset-0 bg-black/40 backdrop-blur-sm transition-opacity duration-300 ${menuOpen ? "opacity-100" : "opacity-0"}`}
            onClick={() => setMenuOpen(false)}
          ></div>
          
          {/* Drawer Content */}
          <div className={`absolute right-0 top-0 h-full w-[280px] bg-white shadow-2xl transition-transform duration-300 transform ${menuOpen ? "translate-x-0" : "translate-x-full"}`}>
            <div className="p-6 flex flex-col h-full">
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
                    <NavLink
                      to={item.path}
                      onClick={() => setMenuOpen(false)}
                      className={({ isActive }) =>
                        `flex items-center px-4 py-3 rounded-xl font-semibold transition-all ${isActive
                          ? "bg-[#d8b14a] text-white shadow-md shadow-[#d8b14a]/20"
                          : "hover:bg-gray-50 text-gray-600"
                        }`
                      }>
                      {item.name}
                    </NavLink>
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