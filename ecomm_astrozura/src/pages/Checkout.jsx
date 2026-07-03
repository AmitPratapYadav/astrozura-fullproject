import { useState, useEffect, useRef } from "react";
import Footer from "../components/Footer";
import { useNavigate } from "react-router-dom";
import { useCart } from "../context/CartContext";
import { useAuth } from "../context/AuthContext";
import api from "../api/axios";
import { ensureRazorpayConfigured, payForOrder } from "../api/paymentApi";
import locationIcon from "../assets/location.png";
import cardIcon from "../assets/carti.png";
import upiIcon from "../assets/upi.png";
import deliveryIcon from "../assets/delivery.png";
import arrow from "../assets/right-arrow.png";
import secure from "../assets/verified.png";
import { useShippingQuote } from "../hooks/useShippingQuote";

export default function CheckoutPage() {
  const [method, setMethod] = useState("razorpay");
  const { cartItems, clearCart } = useCart();
  const { user } = useAuth();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [savedAddresses, setSavedAddresses] = useState([]);

  // Location Search State
  const [showLocationList, setShowLocationList] = useState(false);
  const [locations, setLocations] = useState([]);
  const [isSearchingLocation, setIsSearchingLocation] = useState(false);
  const locationRef = useRef(null);

  useEffect(() => {
    if (!user) {
      alert("Please login to proceed with checkout.");
      navigate("/login?redirect=/checkout");
    }

    const handleClickOutside = (event) => {
      if (locationRef.current && !locationRef.current.contains(event.target)) {
        setShowLocationList(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [user, navigate]);

  const [formData, setFormData] = useState({
    fullName: user?.name || "",
    phone: user?.phone || "",
    address: "",
    city: "",
    state: "",
    zip: "",
  });

  useEffect(() => {
    if (!user) return;
    api.get("/dashboard/addresses")
      .then((response) => {
        const addresses = response.data?.data || [];
        const recent = (response.data?.recent_order_addresses || []).map((item, index) => ({
          id: `recent-${index}`,
          label: "Previous Order",
          ...item,
        }));
        setSavedAddresses([...addresses, ...recent]);
        const preferred = addresses.find((item) => item.is_default);
        if (preferred) {
          setFormData({
            fullName: preferred.recipient_name || user.name || "",
            phone: preferred.phone || user.phone || "",
            address: preferred.address_line || "",
            city: preferred.city || "",
            state: preferred.state || "",
            zip: preferred.postal_code || "",
          });
        }
      })
      .catch(() => setSavedAddresses([]));
  }, [user]);

  const [paymentDetails, setPaymentDetails] = useState({
    cardName: "",
    cardNumber: "",
    expiry: "",
    cvv: "",
    upiId: "",
  });
  const [errors, setErrors] = useState({});

  const { quote, loading: quoteLoading } = useShippingQuote(cartItems);
  const subtotal = Number(quote.subtotal_amount || 0);
  const shipping = Number(quote.shipping_amount || 0);
  const tax = Number(quote.tax_amount || 0);
  const total = Number(quote.total_amount || 0);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    
    // Trigger location search if city field changes
    if (name === "city" && value.length > 2) {
      searchLocation(value);
    } else if (name === "city") {
      setLocations([]);
      setShowLocationList(false);
    }
  };

  const searchLocation = async (query) => {
    setIsSearchingLocation(true);
    try {
      const response = await api.get("/prokerala/location/search", { params: { q: query } });
      // Assuming response.data.data is the list of locations from ProKerala
      const results = response.data?.data || [];
      setLocations(results);
      setShowLocationList(results.length > 0);
    } catch (err) {
      console.error("Location search failed", err);
    } finally {
      setIsSearchingLocation(false);
    }
  };

  const selectLocation = (loc) => {
    setFormData((prev) => ({
      ...prev,
      city: loc.name,
      state: loc.state || loc.region || prev.state,
    }));
    setShowLocationList(false);
  };

  const handlePaymentChange = (e) => {
    const { name, value } = e.target;
    if (name === "cardNumber") {
      const v = value.replace(/\s+/g, "").replace(/[^0-9]/gi, "");
      const matches = v.match(/\d{4,16}/g);
      const match = (matches && matches[0]) || "";
      const parts = [];
      for (let i = 0, len = match.length; i < len; i += 4) {
        parts.push(match.substring(i, i + 4));
      }
      setPaymentDetails((prev) => ({
        ...prev,
        [name]: parts.length ? parts.join(" ") : v,
      }));
      return;
    }
    setPaymentDetails((prev) => ({ ...prev, [name]: value }));
  };

  const setUpiHandle = (handle) => {
    const currentId = paymentDetails.upiId.split("@")[0] || "";
    setPaymentDetails((prev) => ({ ...prev, upiId: `${currentId}@${handle}` }));
  };

  const validateForm = () => {
    let newErrors = {};
    if (!formData.fullName.trim()) newErrors.fullName = "Full name is required";
    else if (formData.fullName.length < 3)
      newErrors.fullName = "Minimum 3 characters required";

    const cleanPhone = formData.phone.toString().replace(/\D/g, "");
    if (!cleanPhone) newErrors.phone = "Phone number is required";
    else if (cleanPhone.length !== 10)
      newErrors.phone = "Enter a valid 10-digit number";

    if (!formData.address.trim()) newErrors.address = "Address is required";
    if (!formData.city.trim()) newErrors.city = "City is required";
    if (!formData.state.trim()) newErrors.state = "State is required";
    if (!formData.zip.trim()) newErrors.zip = "Postal code is required";

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handlePlaceOrder = async () => {
    if (cartItems.length === 0) {
      alert("Your cart is empty!");
      return;
    }

    if (!validateForm()) {
      return;
    }

    setLoading(true);
    try {
      if (method === "razorpay") {
        await ensureRazorpayConfigured();
      }
      const response = await api.post("/dashboard/orders/store", {
        total_amount: total.toFixed(2),
        payment_method: method,
        shipping_address: `${formData.address}, ${formData.city}, ${formData.zip}`,
        shipping_details: {
          recipient_name: formData.fullName,
          phone: formData.phone,
          address_line: formData.address,
          city: formData.city,
          state: formData.state,
          postal_code: formData.zip,
          country: "India",
        },
        phone: formData.phone,
        items: cartItems.map((item) => ({
          id: item.id,
          variant_id: item.variant_id || null,
          qty: item.qty,
        })),
        notes: "Order placed from premium checkout.",
      });

      if (response.data.status === "success") {
        if (method === "razorpay") {
          await payForOrder({
            order: response.data.order,
            user,
            contact: formData.phone,
          });
        }
        alert(
          `Order placed successfully! Order ID: ${response.data.order.order_number}`
        );
        clearCart();
        navigate("/dashboard/orders");
      }
    } catch (error) {
      console.error("Failed to place order:", error);
      alert(
        error.response?.data?.message ||
          "Something went wrong. Please try again."
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <div className="bg-[#F8F9FC] min-h-screen p-4 md:p-10 lg:p-14 selection:bg-orange-100">
        <div className="max-w-7xl mx-auto">
          {/* PROGRESS HEADER */}
          <div className="mb-10">
            <nav className="flex items-center gap-2 text-[10px] uppercase font-black tracking-widest text-gray-400 mb-2">
              <span onClick={() => navigate("/cart")} className="cursor-pointer hover:text-[#C5A021]">Inventory</span>
              <img src={arrow} className="w-2 opacity-30" />
              <span className="text-[#0F172A]">Safe Checkout</span>
            </nav>
            <h1 className="text-4xl font-black text-[#0F172A] tracking-tight">Complete <span className="text-[#C5A021]">Purchase</span></h1>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 items-start">
            {/* LEFT SIDE - FORMS */}
            <div className="lg:col-span-8 space-y-6">
              
              {/* SHIPPING CARD */}
              <div className="bg-white p-6 md:p-10 rounded-[2.5rem] border border-white shadow-[0_8px_30px_rgb(0,0,0,0.04)] relative overflow-hidden">
                <div className="absolute top-0 right-0 w-32 h-32 bg-gray-50 rounded-full -mr-16 -mt-16 opacity-50"></div>
                
                <div className="flex items-center gap-4 mb-8 relative z-10">
                  <div className="w-12 h-12 bg-[#F8F1E6] rounded-2xl flex items-center justify-center border border-[#F8F1E6]">
                    <img src={locationIcon} className="w-5 h-5 opacity-70" alt="Shipping" />
                  </div>
                  <div>
                    <h2 className="text-xl font-black text-[#0F172A] leading-none">Destination Details</h2>
                    <p className="text-xs text-gray-400 mt-1 font-medium italic">Standard delivery usually takes 3-5 business days.</p>
                  </div>
                </div>

                {savedAddresses.length > 0 && (
                  <div className="relative z-10 mb-6">
                    <label className="mb-2 block px-2 text-[10px] font-black uppercase tracking-widest text-gray-400">Use a saved or previous address</label>
                    <select
                      defaultValue=""
                      onChange={(event) => {
                        const address = savedAddresses.find((item) => String(item.id) === event.target.value);
                        if (!address) return;
                        setFormData({
                          fullName: address.recipient_name || user?.name || "",
                          phone: address.phone || user?.phone || "",
                          address: address.address_line || "",
                          city: address.city || "",
                          state: address.state || "",
                          zip: address.postal_code || "",
                        });
                      }}
                      className="w-full rounded-2xl border border-gray-100 bg-[#F8FAFC] px-5 py-3.5 text-sm font-bold text-[#0F172A] outline-none focus:border-[#C5A021]"
                    >
                      <option value="">Enter a new address</option>
                      {savedAddresses.map((address) => (
                        <option key={address.id} value={address.id}>
                          {address.label || "Address"} - {address.address_line}, {address.city}
                        </option>
                      ))}
                    </select>
                  </div>
                )}

                <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-6 relative z-10">
                  <div className="space-y-1.5">
                    <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest px-2">Recipient Name</label>
                    <input 
                      className={`w-full px-5 py-3.5 rounded-2xl bg-[#F8FAFC] border-[1.5px] ${errors.fullName ? "border-red-400" : "border-gray-100"} focus:border-[#C5A021] focus:bg-white outline-none transition-all duration-300 font-bold text-[#0F172A] text-sm`} 
                      name="fullName" 
                      value={formData.fullName} 
                      onChange={handleInputChange} 
                      placeholder="e.g. Rahul Sharma" 
                    />
                    {errors.fullName && <p className="text-[10px] text-red-500 font-bold px-4">{errors.fullName}</p>}
                  </div>
                  <div className="space-y-1.5">
                    <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest px-2">Primary Contact</label>
                    <input 
                      className={`w-full px-5 py-3.5 rounded-2xl bg-[#F8FAFC] border-[1.5px] ${errors.phone ? "border-red-400" : "border-gray-100"} focus:border-[#C5A021] focus:bg-white outline-none transition-all duration-300 font-bold text-[#0F172A] text-sm`} 
                      name="phone" 
                      value={formData.phone} 
                      onChange={handleInputChange} 
                      placeholder="+91 00000 00000" 
                    />
                    {errors.phone && <p className="text-[10px] text-red-500 font-bold px-4">{errors.phone}</p>}
                  </div>
                  <div className="md:col-span-2 space-y-1.5">
                    <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest px-2">Full Street Address</label>
                    <input 
                      className={`w-full px-5 py-3.5 rounded-2xl bg-[#F8FAFC] border-[1.5px] ${errors.address ? "border-red-400" : "border-gray-100"} focus:border-[#C5A021] focus:bg-white outline-none transition-all duration-300 font-bold text-[#0F172A] text-sm`} 
                      name="address" 
                      value={formData.address} 
                      onChange={handleInputChange} 
                      placeholder="Building, Street name, Landmark..." 
                    />
                    {errors.address && <p className="text-[10px] text-red-500 font-bold px-4">{errors.address}</p>}
                  </div>
                  <div className="relative space-y-1.5" ref={locationRef}>
                    <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest px-2">City Area</label>
                    <div className="relative">
                      <input 
                        className={`w-full px-5 py-3.5 rounded-2xl bg-[#F8FAFC] border-[1.5px] ${errors.city ? "border-red-400" : "border-gray-100"} focus:border-[#C5A021] focus:bg-white outline-none transition-all duration-300 font-bold text-[#0F172A] text-sm`} 
                        name="city" 
                        value={formData.city} 
                        onChange={handleInputChange} 
                        placeholder="Search for city..." 
                      />
                      {isSearchingLocation && <div className="absolute right-4 top-1/2 -translate-y-1/2 w-4 h-4 border-2 border-[#C5A021] border-t-transparent rounded-full animate-spin"></div>}
                    </div>
                    {/* AUTOCOMPLETE LIST */}
                    {showLocationList && (
                      <div className="absolute z-[100] top-full mt-2 w-full bg-white rounded-2xl shadow-2xl border border-gray-100 overflow-hidden animate-in fade-in slide-in-from-top-2">
                        {locations.map((loc, idx) => (
                          <div 
                            key={idx} 
                            onClick={() => selectLocation(loc)}
                            className="px-5 py-3 hover:bg-gray-50 cursor-pointer font-bold text-xs text-[#0F172A] flex justify-between items-center border-b border-gray-100 last:border-0"
                          >
                            <span>{loc.name}</span>
                            <span className="text-[10px] text-gray-400 uppercase">{loc.state || "India"}</span>
                          </div>
                        ))}
                      </div>
                    )}
                    {errors.city && <p className="text-[10px] text-red-500 font-bold px-4">{errors.city}</p>}
                  </div>
                  <div className="space-y-1.5">
                    <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest px-2">State</label>
                    <input
                      className={`w-full px-5 py-3.5 rounded-2xl bg-[#F8FAFC] border-[1.5px] ${errors.state ? "border-red-400" : "border-gray-100"} focus:border-[#C5A021] focus:bg-white outline-none transition-all duration-300 font-bold text-[#0F172A] text-sm`}
                      name="state"
                      value={formData.state}
                      onChange={handleInputChange}
                      placeholder="Uttar Pradesh"
                    />
                    {errors.state && <p className="text-[10px] text-red-500 font-bold px-4">{errors.state}</p>}
                  </div>
                  <div className="space-y-1.5">
                    <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest px-2">Postal Code</label>
                    <input 
                      className="w-full px-5 py-3.5 rounded-2xl bg-[#F8FAFC] border-[1.5px] border-gray-100 focus:border-[#C5A021] focus:bg-white outline-none transition-all duration-300 font-bold text-[#0F172A] text-sm" 
                      name="zip" 
                      value={formData.zip} 
                      onChange={handleInputChange} 
                      placeholder="000 000" 
                    />
                    {errors.zip && <p className="text-[10px] text-red-500 font-bold px-4">{errors.zip}</p>}
                  </div>
                </div>
              </div>

              {/* PAYMENT CARD */}
              <div className="bg-white p-6 md:p-10 rounded-[2.5rem] border border-white shadow-[0_8px_30px_rgb(0,0,0,0.04)]">
                <div className="flex items-center gap-4 mb-8">
                  <div className="w-12 h-12 bg-[#EEF2F8] rounded-2xl flex items-center justify-center border border-[#EEF2F8]">
                    <img src={cardIcon} className="w-5 h-5 opacity-70" alt="Payment" />
                  </div>
                  <div>
                    <h2 className="text-xl font-black text-[#0F172A] leading-none">Settlement Choice</h2>
                    <p className="text-xs text-gray-400 mt-1 font-medium">All financial paths are end-to-end encrypted.</p>
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-10">
                  {[
                    { id: "razorpay", label: "Pay securely", icon: upiIcon },
                    { id: "cod", label: "Cash on delivery", icon: deliveryIcon }
                  ].map((it) => (
                    <button
                      key={it.id}
                      onClick={() => setMethod(it.id)}
                      className={`flex flex-col items-center gap-3 p-6 rounded-[2rem] border-[1.5px] transition-all duration-500 ${method === it.id ? "bg-[#F8FAFC] border-[#C5A021] shadow-lg shadow-[#C5A021]/10 scale-[1.02]" : "bg-white border-gray-50 hover:border-gray-200"}`}
                    >
                      <div className={`w-14 h-14 rounded-2xl flex items-center justify-center transition-all duration-500 ${method === it.id ? "bg-[#C5A021] text-white shadow-xl shadow-[#C5A021]/30 rotate-3" : "bg-gray-50 opacity-60 group-hover:opacity-100"}`}>
                        <img src={it.icon} className={`w-8 h-8 ${method === it.id ? "brightness-0 invert" : ""}`} />
                      </div>
                      <span className={`text-[10px] font-black uppercase tracking-widest ${method === it.id ? "text-[#0F172A]" : "text-gray-400"}`}>{it.label}</span>
                    </button>
                  ))}
                </div>

                <div className="bg-[#F8FAFC]/50 p-6 md:p-8 rounded-[2rem] border border-gray-100">
                  {method === "razorpay" && (
                    <div className="animate-fadeIn py-4">
                      <div className="flex items-start gap-6 bg-white p-6 rounded-3xl border border-white">
                        <div className="w-16 h-16 bg-[#F8F1E6] rounded-2xl flex-shrink-0 flex items-center justify-center">
                          <img src={upiIcon} className="w-8 opacity-70" alt="Razorpay" />
                        </div>
                        <div>
                          <h3 className="text-lg font-black text-[#0F172A] mb-1">Razorpay Checkout</h3>
                          <p className="text-sm text-gray-400 font-medium leading-relaxed max-w-sm">Choose UPI, card, net banking, or a supported wallet inside Razorpay's secure payment window.</p>
                        </div>
                      </div>
                    </div>
                  )}
                  {method === "card" && (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-6 animate-fadeIn">
                       <div className="md:col-span-2 space-y-1.5">
                        <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest px-2">Holders Name</label>
                        <input className="w-full px-5 py-3.5 rounded-2xl bg-white border border-gray-100 focus:border-[#C5A021] outline-none transition-all font-bold text-[#0F172A] text-sm" name="cardName" value={paymentDetails.cardName} onChange={handlePaymentChange} placeholder="Johnathan Doe" />
                      </div>
                      <div className="md:col-span-2 space-y-1.5">
                        <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest px-2">Card Credentials</label>
                        <div className="relative">
                          <input className="w-full px-5 py-10 rounded-2xl bg-[#0F172A] text-white border-none outline-none font-black text-xl tracking-[0.2em] placeholder:text-white/10" name="cardNumber" value={paymentDetails.cardNumber} onChange={handlePaymentChange} placeholder="0000 0000 0000 0000" maxLength="19" />
                          <div className="absolute right-6 bottom-6 flex gap-2">
                             <div className="w-8 h-5 bg-white/10 rounded-sm"></div>
                             <div className="w-8 h-5 bg-white/20 rounded-sm"></div>
                          </div>
                          <div className="absolute left-6 top-6">
                             <div className="w-10 h-10 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-full blur-[20px] opacity-40 animate-pulse"></div>
                          </div>
                        </div>
                      </div>
                      <div className="space-y-1.5">
                        <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest px-2">Valid Thru</label>
                        <input className="w-full px-5 py-3.5 rounded-2xl bg-white border border-gray-100 focus:border-[#C5A021] outline-none transition-all font-bold text-[#0F172A] text-sm" name="expiry" value={paymentDetails.expiry} onChange={handlePaymentChange} placeholder="MM/YY" maxLength="5" />
                      </div>
                      <div className="space-y-1.5">
                        <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest px-2">CCV / CVV</label>
                        <input className="w-full px-5 py-3.5 rounded-2xl bg-white border border-gray-100 focus:border-[#C5A021] outline-none transition-all font-bold text-[#0F172A] text-sm" name="cvv" value={paymentDetails.cvv} onChange={handlePaymentChange} type="password" placeholder="***" maxLength="3" />
                      </div>
                    </div>
                  )}

                  {method === "upi" && (
                    <div className="space-y-6 animate-fadeIn">
                       <div className="space-y-1.5">
                        <label className="text-[10px] font-black text-gray-400 uppercase tracking-widest px-2">Identifier (VPA)</label>
                        <div className="flex flex-col sm:flex-row gap-4">
                          <input className="flex-1 px-5 py-3.5 rounded-2xl bg-white border border-gray-100 focus:border-[#C5A021] outline-none transition-all font-bold text-[#0F172A] text-sm" name="upiId" value={paymentDetails.upiId} onChange={handlePaymentChange} placeholder="username@bank" />
                          <div className="flex gap-2">
                            {["ybl", "okaxis", "paytm"].map(h => (
                              <button key={h} onClick={() => setUpiHandle(h)} className="px-4 py-2 bg-white border border-gray-100 rounded-xl text-[10px] font-black text-gray-400 hover:text-[#C5A021] hover:border-[#C5A021] transition-all">@{h}</button>
                            ))}
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center gap-4 p-4 bg-white/50 rounded-2xl border border-white">
                         <div className="w-8 h-8 bg-blue-50 text-blue-600 rounded-lg flex items-center justify-center font-bold text-xs italic">i</div>
                         <p className="text-[10px] text-gray-400 font-medium leading-relaxed">A notification will be pushed to your UPI app. Please authenticate the transaction within 5 minutes.</p>
                      </div>
                    </div>
                  )}

                  {method === "cod" && (
                    <div className="animate-fadeIn py-4">
                      <div className="flex items-start gap-6 bg-white p-6 rounded-3xl border border-white">
                        <div className="w-16 h-16 bg-yellow-50 rounded-2xl flex-shrink-0 flex items-center justify-center">
                          <img src={deliveryIcon} className="w-8 opacity-60" alt="COD" />
                        </div>
                        <div>
                          <h3 className="text-lg font-black text-[#0F172A] mb-1">Pay on Discovery</h3>
                          <p className="text-sm text-gray-400 font-medium leading-relaxed max-w-sm">Please keep the exact amount (₹{total.toFixed(0)}) ready or be prepared to scan a dynamic UPI QR code upon arrival.</p>
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* RIGHT SIDE - SUMMARY */}
            <div className="lg:col-span-4 lg:sticky lg:top-10">
              <div className="bg-[#0F172A] text-white p-8 rounded-[3rem] shadow-2xl shadow-[#0F172A]/20 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-[#C5A021] to-transparent opacity-20"></div>
                
                <h2 className="text-xl font-black mb-8 border-b border-white/5 pb-4 tracking-tight">Final Summary</h2>
                
                <div className="max-h-[35vh] overflow-y-auto pr-2 space-y-6 custom-scrollbar mb-10">
                  {cartItems.map((item, i) => (
                    <div key={i} className="flex gap-4 items-center group">
                      <div className="w-14 h-14 rounded-2xl bg-white/5 border border-white/5 overflow-hidden flex-shrink-0">
                        <img src={item.image} className="w-full h-full object-cover opacity-80 group-hover:scale-110 group-hover:opacity-100 transition duration-700" alt={item.name} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-[11px] font-black tracking-tight truncate group-hover:text-[#C5A021] transition-colors">{item.name}</p>
                        <p className="text-[9px] text-white/30 font-bold uppercase mt-1 tracking-widest">{item.qty} UNIT · {item.category}</p>
                      </div>
                      <p className="text-xs font-black text-white/90">₹{(item.price * item.qty).toFixed(0)}</p>
                    </div>
                  ))}
                </div>

                <div className="space-y-4 pt-8 border-t border-white/5 font-medium">
                  <div className="flex justify-between text-xs text-white/40">
                    <span>Valuation subtotal</span>
                    <span className="text-white">₹{subtotal.toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between text-xs text-white/40">
                    <span>Category shipping</span>
                    <span className={shipping === 0 ? "text-[#4ADE80] font-black" : "text-white"}>
                      {quoteLoading ? "Calculating..." : shipping === 0 ? "FREE" : `₹${shipping.toFixed(2)}`}
                    </span>
                  </div>
                  {(quote.shipping_breakdown || []).map((item) => (
                    <div key={item.category_id} className="flex justify-between text-[10px] text-white/40">
                      <span>{item.category_name}</span>
                      <span className="text-white">{Number(item.amount) === 0 ? "Free" : `₹${Number(item.amount).toFixed(2)}`}</span>
                    </div>
                  ))}
                  <div className="flex justify-between text-xs text-white/40">
                    <span>GST (12%)</span>
                    <span className="text-white">₹{tax.toFixed(2)}</span>
                  </div>
                  
                  <div className="pt-6 mt-4 border-t-2 border-dashed border-white/10">
                    <div className="flex justify-between items-end">
                      <div>
                        <p className="text-[9px] font-black text-[#C5A021] tracking-[0.3em] mb-2 uppercase">Amount to Settle</p>
                        <h2 className="text-4xl font-black tracking-tighter">₹{total.toFixed(0)}</h2>
                      </div>
                      <div className="w-10 h-10 bg-white/5 rounded-full flex items-center justify-center p-2">
                         <img src={secure} className="w-full opacity-30" />
                      </div>
                    </div>
                  </div>
                </div>

                <button
                  onClick={handlePlaceOrder}
                  disabled={loading || cartItems.length === 0}
                  className={`mt-10 w-full py-5 rounded-2xl flex items-center justify-center gap-3 font-black text-sm tracking-[0.2em] uppercase transition-all duration-500 overflow-hidden relative group ${
                    cartItems.length > 0 
                    ? "bg-[#C5A021] text-[#0F172A] shadow-xl shadow-[#C5A021]/10 hover:scale-[1.02] active:scale-95" 
                    : "bg-white/5 text-white/10 cursor-not-allowed border border-white/5"
                  }`}
                >
                  <span className="relative z-10">{loading ? "Processing Path..." : "Finalize Order"}</span>
                  {!loading && <img src={arrow} className="w-4 h-4 relative z-10 group-hover:translate-x-1 transition-transform" />}
                  <div className="absolute inset-0 bg-white/20 translate-x-[-100%] group-hover:translate-x-[100%] transition-transform duration-1000"></div>
                </button>

                <div className="mt-8 flex items-center justify-center gap-3 py-3 border border-white/5 rounded-2xl bg-white/[0.02]">
                  <img src={secure} className="w-3.5 opacity-40" alt="Secure" />
                  <span className="text-[9px] font-bold tracking-widest text-white/30 uppercase">AES-256 Cloud Security</span>
                </div>
              </div>

              {/* ADDITIONAL TRUST */}
              <div className="mt-6 p-6 bg-white rounded-[2rem] border border-gray-100 flex items-center gap-4">
                 <div className="p-3 bg-gray-50 rounded-xl">
                    <img src={secure} className="w-5 grayscale opacity-50" />
                 </div>
                 <p className="text-[10px] text-gray-400 font-bold leading-relaxed uppercase tracking-widest">Global Spiritual Standard Compliance <br/><span className="text-[#C5A021]">Secure Protocol</span></p>
              </div>
            </div>
          </div>
        </div>

        {/* CUSTOM SCROLLBAR CSS */}
        <style dangerouslySetInnerHTML={{ __html: `
          .custom-scrollbar::-webkit-scrollbar { width: 4px; }
          .custom-scrollbar::-webkit-scrollbar-track { background: rgba(255,255,255,0.02); }
          .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(197, 160, 33, 0.2); border-radius: 10px; }
          @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
          .animate-fadeIn { animation: fadeIn 0.5s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
        ` }} />
      </div>

      <Footer />
    </>
  );
}
