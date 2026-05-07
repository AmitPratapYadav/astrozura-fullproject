import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { FcGoogle } from "react-icons/fc";
import { CheckCircle2 } from "lucide-react";
import vedic from "../assets/vedic-astrology.png";
import { buildGoogleAuthUrl } from "../utils/googleAuth";

const STARS = Array.from({ length: 60 }, (_, i) => ({
  id: i,
  size: Math.random() * 2.5 + 0.5,
  top: Math.random() * 100,
  left: Math.random() * 100,
  delay: Math.random() * 4,
}));

export default function Register() {
  const [formData, setFormData] = useState({ firstName: "", lastName: "", email: "", password: "" });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const { registerWithPassword } = useAuth();
  const navigate = useNavigate();

  const handleInputChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

  const handleRegister = async (e) => {
    e.preventDefault();
    if (!formData.email || !formData.password || !formData.firstName) {
      setError("Please fill required fields.");
      return;
    }
    setLoading(true);
    setError("");
    try {
      const response = await registerWithPassword(formData);
      if (response) navigate("/user-profile");
    } catch (err) {
      setError(err.message || "Failed to register. Try again.");
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleLogin = () => {
    window.location.href = buildGoogleAuthUrl("main");
  };

  const features = [
    "Create & Save Unlimited Kundli",
    "Get Your Varshphal Analysis",
    "KP Horoscopes and Significators",
    "Match Unlimited Kundli Profiles",
    "Free Lal Kitab Remedies",
  ];

  return (
    <div className="min-h-screen flex font-sans">

      {/* LEFT PANEL – Cosmic */}
      <div
        className="hidden lg:flex w-1/2 relative flex-col justify-between p-12 overflow-hidden"
        style={{ background: "linear-gradient(145deg, #0D1B3E 0%, #1a1060 50%, #0D1B3E 100%)" }}
      >
        {/* Stars */}
        {STARS.map((s) => (
          <div
            key={s.id}
            className="absolute rounded-full bg-white animate-pulse"
            style={{
              width: s.size, height: s.size,
              top: `${s.top}%`, left: `${s.left}%`,
              opacity: 0.4 + Math.random() * 0.6,
              animationDelay: `${s.delay}s`,
            }}
          />
        ))}

        {/* Glowing orb */}
        <div
          className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-72 h-72 rounded-full blur-3xl opacity-20"
          style={{ background: "radial-gradient(circle, #D4A73C, transparent)" }}
        />

        {/* Logo */}
        <Link to="/" className="relative z-10 flex items-center hover:opacity-90 transition w-fit bg-white px-5 py-2.5 rounded-2xl shadow-xl">
          <img src={vedic} alt="AstroZura" className="h-[60px] object-contain" />
        </Link>

        {/* Center content */}
        <div className="relative z-10 text-white space-y-6">
          <div className="text-6xl">🔮</div>
          <h2 className="text-3xl font-bold leading-snug">
            Start Your<br />
            <span className="text-[#D4A73C]">Cosmic Journey</span>
          </h2>
          <p className="text-blue-200 text-sm max-w-xs">Join over 1 million seekers who've unlocked their celestial destiny with AstroZura.</p>

          <div className="space-y-3">
            {features.map((f, i) => (
              <div key={i} className="flex items-center gap-3">
                <CheckCircle2 className="text-[#D4A73C] w-5 h-5 flex-shrink-0" />
                <span className="text-blue-100 text-sm">{f}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Social proof */}
        <div className="relative z-10 bg-white/5 border border-white/10 rounded-xl p-4">
          <p className="text-blue-100 text-xs italic leading-relaxed">
            "The best astrology app I've ever used. I'd give 10 stars if I could!"
          </p>
          <div className="flex items-center gap-2 mt-3">
            <div className="w-7 h-7 rounded-full bg-[#D4A73C] flex items-center justify-center text-xs font-bold text-[#0D1B3E]">K</div>
            <div>
              <p className="text-white text-xs font-semibold">Khushwant Singh</p>
              <p className="text-blue-300 text-xs">Delhi, IN</p>
            </div>
            <div className="ml-auto text-[#D4A73C] text-xs">★★★★★</div>
          </div>
        </div>
      </div>

      {/* RIGHT PANEL – Register form */}
      <div className="w-full lg:w-1/2 flex flex-col justify-center items-center bg-[#f7f8fc] px-6 py-12">

        {/* Mobile logo */}
        <Link to="/" className="lg:hidden flex justify-center mb-8">
          <img src={vedic} alt="AstroZura" className="h-16 object-contain" />
        </Link>

        <div className="w-full max-w-md">
          <div className="mb-8">
            <h1 className="text-3xl font-bold text-[#1E3557]">Create Account ✨</h1>
            <p className="text-gray-500 text-sm mt-2">Start your journey for free, no credit card needed</p>
          </div>

          {/* Google Login */}
          <button
            type="button"
            onClick={handleGoogleLogin}
            className="w-full flex items-center justify-center gap-3 bg-white border border-gray-200 rounded-xl py-3 text-sm font-medium text-gray-700 hover:bg-gray-50 hover:shadow-sm transition mb-6 shadow-sm"
          >
            <FcGoogle className="w-5 h-5" />
            Continue with Google
          </button>

          {/* Divider */}
          <div className="flex items-center gap-4 mb-6">
            <div className="flex-1 h-px bg-gray-200" />
            <span className="text-gray-400 text-xs uppercase tracking-wider">or register with email</span>
            <div className="flex-1 h-px bg-gray-200" />
          </div>

          {error && (
            <div className="bg-red-50 text-red-600 border border-red-100 rounded-xl p-3 text-xs text-center mb-4">
              ⚠️ {error}
            </div>
          )}

          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
            <form onSubmit={handleRegister} className="space-y-4">
              {/* Name Row */}
              <div className="flex gap-3">
                <div className="flex-1">
                  <label className="block text-xs font-semibold text-gray-600 mb-1.5">First Name *</label>
                  <input
                    type="text" name="firstName" value={formData.firstName} onChange={handleInputChange}
                    placeholder="Your first name"
                    className="w-full border border-gray-200 bg-gray-50 rounded-xl px-4 py-3 text-sm outline-none focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 transition"
                    required
                  />
                </div>
                <div className="flex-1">
                  <label className="block text-xs font-semibold text-gray-600 mb-1.5">Last Name</label>
                  <input
                    type="text" name="lastName" value={formData.lastName} onChange={handleInputChange}
                    placeholder="Optional"
                    className="w-full border border-gray-200 bg-gray-50 rounded-xl px-4 py-3 text-sm outline-none focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 transition"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1.5">Email Address *</label>
                <input
                  type="email" name="email" value={formData.email} onChange={handleInputChange}
                  placeholder="you@example.com"
                  className="w-full border border-gray-200 bg-gray-50 rounded-xl px-4 py-3 text-sm outline-none focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 transition"
                  required
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1.5">Password *</label>
                <input
                  type="password" name="password" value={formData.password} onChange={handleInputChange}
                  placeholder="Create a strong password"
                  className="w-full border border-gray-200 bg-gray-50 rounded-xl px-4 py-3 text-sm outline-none focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 transition"
                  required
                />
              </div>

              <button
                type="submit" disabled={loading}
                className="w-full bg-[#1E3557] text-white font-semibold py-3 rounded-xl hover:bg-[#162744] transition flex justify-center items-center gap-2 shadow mt-2"
              >
                {loading ? <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white" /> : "Create Account →"}
              </button>
            </form>

            <p className="text-center text-xs text-gray-400 mt-5">
              By signing up, you accept our{" "}
              <a href="#" className="text-[#D4A73C] hover:underline">Terms</a> &{" "}
              <a href="#" className="text-[#D4A73C] hover:underline">Privacy Policy</a>
            </p>
          </div>

          <p className="text-center text-sm text-gray-500 mt-6">
            Already have an account?{" "}
            <Link to="/login" className="text-[#D4A73C] font-semibold hover:underline">
              Sign In →
            </Link>
          </p>
        </div>
      </div>

    </div>
  );
}
