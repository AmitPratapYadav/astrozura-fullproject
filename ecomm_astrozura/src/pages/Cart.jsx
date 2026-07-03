import { useNavigate } from "react-router-dom";
import { useCart } from "../context/CartContext";
import plus from "../assets/w1.png";
import minus from "../assets/w2.png";
import del from "../assets/w3.png";
import ship from "../assets/icon2.png";
import secure from "../assets/icon3.png";
import undo from "../assets/undo.png";
import arrow from "../assets/right-arrow.png";
import Footer from "../components/Footer";
import { useShippingQuote } from "../hooks/useShippingQuote";

export default function Cart() {
  const { cartItems, increaseQty, decreaseQty, removeFromCart } = useCart();
  const { quote, loading: quoteLoading } = useShippingQuote(cartItems);
  const subtotal = Number(quote.subtotal_amount || 0);
  const shipping = Number(quote.shipping_amount || 0);
  const tax = Number(quote.tax_amount || 0);
  const total = Number(quote.total_amount || 0);
  const navigate = useNavigate();

  return (
    <>
      <div className="min-h-screen bg-[#FDFCFB] p-4 sm:p-6 md:p-10 lg:p-14 font-sans selection:bg-orange-100">
        <div className="max-w-7xl mx-auto">
          {/* HEADER */}
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-end mb-10 gap-4">
            <div>
              <nav className="text-[10px] uppercase tracking-[0.2em] text-gray-400 mb-2 font-bold">
                Store / Shopping Selection
              </nav>
              <h1 className="text-4xl sm:text-5xl font-black text-[#0F172A] tracking-tight">
                Your <span className="text-[#C5A021]">Cart</span>
              </h1>
              <p className="text-gray-400 text-sm mt-2 font-medium">
                {cartItems.length} extraordinary items awaiting your confirmation.
              </p>
            </div>
            <button
              onClick={() => navigate("/allproduct")}
              className="group flex items-center gap-3 bg-white px-6 py-3 rounded-2xl shadow-sm border border-gray-100 hover:border-[#C5A021] transition-all duration-300 active:scale-95"
            >
              <span className="text-sm font-bold text-gray-600 group-hover:text-[#C5A021]">Continue Shopping</span>
              <img src={arrow} className="w-4 group-hover:translate-x-1 transition-transform" />
            </button>
          </div>

          <div className="grid lg:grid-cols-12 gap-10">
            {/* LEFT - PRODUCT LIST */}
            <div className="lg:col-span-8 space-y-6">
              {cartItems.length > 0 ? (
                <div className="space-y-4">
                  {cartItems.map((item) => (
                    <div
                      key={item.cartKey}
                      className="group relative bg-white/60 backdrop-blur-xl p-4 sm:p-6 rounded-[2rem] flex flex-col sm:flex-row items-center justify-between border border-white shadow-[0_8px_30px_rgb(0,0,0,0.04)] hover:shadow-[0_20px_40px_rgb(0,0,0,0.08)] transition-all duration-500 overflow-hidden"
                    >
                      {/* Background Decoration */}
                      <div className="absolute top-0 right-0 w-32 h-32 bg-gradient-to-br from-[#C5A021]/5 to-transparent rounded-full -mr-16 -mt-16 group-hover:scale-110 transition-transform duration-700"></div>

                      <div className="flex gap-6 items-center w-full sm:w-[60%] relative z-10">
                        <div className="w-24 h-24 sm:w-32 sm:h-32 bg-gray-50 rounded-3xl overflow-hidden flex-shrink-0 border border-white shadow-inner group-hover:scale-[1.02] transition-transform duration-500">
                          <img
                            src={item.image}
                            className="w-full h-full object-cover"
                            alt={item.name}
                          />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="inline-block px-3 py-1 bg-[#C5A021]/10 rounded-full mb-2">
                            <p className="text-[10px] text-[#C5A021] font-black uppercase tracking-widest">
                              {item.category}
                            </p>
                          </div>
                          <h2 className="font-bold text-[#1E293B] text-lg sm:text-xl truncate mb-1">
                            {item.name}
                          </h2>
                          {item.variant_title && <p className="text-xs font-semibold text-gray-500">{item.variant_title}</p>}
                          <div className="flex items-center gap-4 mt-2">
                            <p className="text-lg font-black text-[#0F172A]">₹{item.price}</p>
                            <span className="text-xs text-gray-400 font-medium px-2 py-0.5 border border-gray-100 rounded-md">Original Item</span>
                          </div>
                        </div>
                      </div>

                      <div className="flex items-center justify-between w-full sm:w-auto mt-6 sm:mt-0 gap-6 relative z-10">
                        {/* QTY CONTROLLER */}
                        <div className="flex items-center gap-4 bg-[#F8FAFC] p-2 rounded-2xl border border-gray-100 shadow-sm">
                          <button
                            onClick={() => decreaseQty(item.cartKey)}
                            className="w-8 h-8 flex items-center justify-center bg-white rounded-xl shadow-sm hover:text-red-500 transition-colors active:scale-90"
                          >
                            <img src={minus} className="w-3" />
                          </button>
                          <span className="font-black text-sm text-[#0F172A] min-w-[20px] text-center">
                            {item.qty}
                          </span>
                          <button
                            onClick={() => increaseQty(item.cartKey)}
                            className="w-8 h-8 flex items-center justify-center bg-white rounded-xl shadow-sm hover:text-[#C5A021] transition-colors active:scale-90"
                          >
                            <img src={plus} className="w-3" />
                          </button>
                        </div>

                        <div className="text-right flex flex-col items-end">
                          <p className="text-[10px] text-gray-400 font-bold uppercase tracking-tighter mb-1">Subtotal</p>
                          <p className="text-xl font-black text-[#0F172A]">
                            ₹{(item.price * item.qty).toFixed(0)}
                          </p>
                          <button
                            onClick={() => removeFromCart(item.cartKey)}
                            className="mt-2 p-2 text-gray-300 hover:text-red-500 hover:bg-red-50 rounded-xl transition-all duration-300"
                            title="Remove item"
                          >
                            <img src={del} className="w-4 h-4 opacity-50 hover:opacity-100" />
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="bg-white/50 backdrop-blur-md p-16 rounded-[3rem] text-center border border-white shadow-xl">
                  <div className="w-24 h-24 mx-auto mb-6 bg-gray-50 rounded-[2rem] flex items-center justify-center border border-gray-100 shadow-inner">
                    <img src={undo} className="w-10 opacity-20" />
                  </div>
                  <h2 className="text-2xl font-black text-gray-800 tracking-tight">Your cart is empty</h2>
                  <p className="text-gray-400 mb-8 mt-2 font-medium max-w-xs mx-auto">Discover our collection of premium spiritual items curated just for you.</p>
                  <button
                    onClick={() => navigate("/allproduct")}
                    className="bg-[#0F172A] text-white px-10 py-4 rounded-2xl font-bold shadow-2xl hover:bg-black transition-all duration-300 active:scale-95"
                  >
                    Explore Collections
                  </button>
                </div>
              )}

              {/* TRUST BADGES */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mt-8">
                {[
                  { icon: ship, title: "Swift Delivery", desc: "Express shipping on all orders" },
                  { icon: secure, title: "Secure Vault", desc: "100% Protected transactions" },
                  { icon: undo, title: "Assurance", desc: "30-day spiritual guarantee" }
                ].map((badge, idx) => (
                  <div key={idx} className="bg-white/40 backdrop-blur-sm p-4 rounded-2xl border border-white flex items-center gap-4 shadow-sm">
                    <div className="w-12 h-12 bg-white rounded-xl flex items-center justify-center shadow-sm border border-gray-50">
                      <img src={badge.icon} className="w-6 opacity-70" />
                    </div>
                    <div>
                      <p className="text-xs font-black text-[#0F172A] uppercase">{badge.title}</p>
                      <p className="text-[10px] text-gray-400 font-medium">{badge.desc}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* RIGHT - SUMMARY */}
            <div className="lg:col-span-4 lg:sticky lg:top-10 h-fit">
              <div className="bg-[#0F172A] p-8 rounded-[2.5rem] shadow-2xl shadow-navy-100 text-white relative overflow-hidden">
                {/* Decorative gradients */}
                <div className="absolute top-0 right-0 w-64 h-64 bg-white/5 rounded-full -mr-32 -mt-32 blur-3xl"></div>
                <div className="absolute bottom-0 left-0 w-48 h-48 bg-[#C5A021]/10 rounded-full -ml-24 -mb-24 blur-3xl"></div>

                <h2 className="text-xl font-black mb-8 border-b border-white/10 pb-4">Order Summary</h2>

                <div className="space-y-4 mb-8">
                  <div className="flex justify-between items-center">
                    <span className="text-white/60 text-sm font-medium">Cart Subtotal</span>
                    <span className="font-bold">₹{subtotal.toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-white/60 text-sm font-medium">Category Shipping</span>
                    <span className={shipping === 0 ? "text-green-400 font-bold" : "font-bold"}>
                      {quoteLoading ? "Calculating..." : shipping === 0 ? "FREE" : `₹${shipping.toFixed(2)}`}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-white/60 text-sm font-medium">Estimated Taxes</span>
                    <span className="font-bold">₹{tax.toFixed(2)}</span>
                  </div>
                  {(quote.shipping_breakdown || []).map((item) => (
                    <div key={item.category_id} className="flex justify-between rounded-xl bg-white/5 px-3 py-2 text-[10px]">
                      <span className="text-white/50">{item.category_name}</span>
                      <span>{Number(item.amount) === 0 ? "Free" : `₹${Number(item.amount).toFixed(2)}`}</span>
                    </div>
                  ))}
                </div>

                <div className="pt-6 mb-8 border-t border-white/10">
                  <div className="flex justify-between items-end">
                    <div>
                      <p className="text-[10px] font-black text-[#C5A021] tracking-[0.2em] mb-1 uppercase">Final Amount</p>
                      <h2 className="text-4xl font-black tracking-tight">₹{total.toFixed(0)}</h2>
                    </div>
                    <p className="text-[10px] text-white/40 font-medium mb-1">Inc. All Taxes</p>
                  </div>
                </div>

                <button
                  onClick={() => navigate("/checkout")}
                  disabled={cartItems.length === 0}
                  className={`group relative w-full py-5 rounded-2xl font-black text-sm tracking-widest uppercase transition-all duration-500 overflow-hidden ${
                    cartItems.length > 0
                      ? "bg-gradient-to-r from-[#C5A021] to-[#E2C259] text-[#0F172A] shadow-xl shadow-[#C5A021]/20 hover:scale-[1.02] active:scale-95"
                      : "bg-white/10 text-white/20 cursor-not-allowed"
                  }`}
                >
                  <span className="relative z-10 flex items-center justify-center gap-3">
                    Secure Checkout
                    <img src={arrow} className="w-4 group-hover:translate-x-1 transition-transform invert" />
                  </span>
                  {/* Hover effect highlight */}
                  <div className="absolute inset-0 bg-white/20 translate-x-[-100%] group-hover:translate-x-[100%] transition-transform duration-1000"></div>
                </button>

                <p className="text-[10px] text-white/30 mt-6 text-center font-medium">
                  By clicking checkout you agree to our spiritual commerce terms and return policies.
                </p>

                {/* Promo Section */}
                <div className="mt-8 pt-8 border-t border-white/10">
                  <div className="flex gap-2">
                    <input
                      placeholder="PROMO CODE"
                      className="flex-1 bg-white/5 border border-white/10 px-4 py-3 rounded-xl text-white text-xs font-bold focus:outline-none focus:border-[#C5A021] transition-colors"
                    />
                    <button
                      onClick={() => alert("Verification code applied")}
                      className="bg-white/10 px-6 rounded-xl text-[10px] font-black hover:bg-white/20 transition-all border border-white/5"
                    >
                      APPLY
                    </button>
                  </div>
                </div>
              </div>

              {/* DISCOUT AD */}
              <div className="mt-6 bg-[#C5A021]/10 p-6 rounded-[2rem] border border-[#C5A021]/20 group cursor-pointer hover:bg-[#C5A021]/20 transition-all duration-500">
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 bg-[#0F172A] text-[#C5A021] rounded-2xl flex items-center justify-center font-black text-xs shadow-lg group-hover:scale-110 transition-transform">
                    10%
                  </div>
                  <div>
                    <h3 className="font-black text-[#0F172A] text-sm">Join Spiritual Club</h3>
                    <p className="text-[10px] text-gray-500 font-medium">Unlock exclusive rewards & early access.</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <Footer />
    </>
  );
}
