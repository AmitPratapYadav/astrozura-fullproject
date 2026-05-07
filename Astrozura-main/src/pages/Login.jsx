import { useState, useRef, useEffect } from "react";
import { Link, useNavigate, useLocation } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { FcGoogle } from "react-icons/fc";
import vedic from "../assets/vedic-astrology.png";

const STARS = Array.from({ length: 60 }, (_, i) => ({
  id: i,
  size: Math.random() * 2.5 + 0.5,
  top: Math.random() * 100,
  left: Math.random() * 100,
  delay: Math.random() * 4,
}));

export default function Login() {
  const [identifier, setIdentifier] = useState("");
  const [otpSent, setOtpSent] = useState(false);
  const [otp, setOtp] = useState("");
  const [loginMode, setLoginMode] = useState("otp");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [successMsg, setSuccessMsg] = useState("");

  const { sendOtp, loginWithOtp, loginWithPassword, user } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const otpInputRef = useRef(null);

  const from = location.state?.from?.pathname || "/";

  useEffect(() => {
    if (user) navigate(from, { replace: true });
  }, [user, navigate, from]);

  const handleSendOtp = async (e) => {
    e.preventDefault();
    if (!identifier) { setError("Please enter your mobile number"); return; }
    // Basic phone validation - must be 10 digits
    if (loginMode === "otp" && !/^[6-9]\d{9}$/.test(identifier)) {
      setError("Please enter a valid 10-digit Indian mobile number");
      return;
    }
    setLoading(true); setError(""); setSuccessMsg("");
    try {
      const response = await sendOtp(identifier);
      setOtpSent(true);
      setSuccessMsg(`OTP sent! (DEV OTP: ${response.dev_otp})`);
      setTimeout(() => { if (otpInputRef.current) otpInputRef.current.focus(); }, 100);
    } catch (err) { setError(err.message || "Failed to send OTP."); }
    finally { setLoading(false); }
  };

  const handleVerifyOtp = async (e) => {
    e.preventDefault();
    if (!otp) { setError("Please enter the OTP"); return; }
    setLoading(true); setError("");
    try {
      const response = await loginWithOtp(identifier, otp);
      if (response) navigate(response.is_new_user ? "/user-profile" : from, { replace: true });
    } catch (err) { setError(err.message || "Invalid or expired OTP."); }
    finally { setLoading(false); }
  };

  const handlePasswordLogin = async (e) => {
    e.preventDefault();
    if (!identifier || !password) { setError("Please enter your email and password."); return; }
    setLoading(true); setError("");
    try {
      const response = await loginWithPassword({ email: identifier, password });
      if (response) navigate(response.is_new_user ? "/user-profile" : from, { replace: true });
    } catch (err) { setError(err.message || "Invalid email or password."); }
    finally { setLoading(false); }
  };

  const handleGoogleLogin = () => {
    localStorage.setItem("redirect_after_login", from);
    window.location.href = `${import.meta.env.VITE_API_BASE_URL}/auth/google?frontend=main`;
  };

  return (
    <div className="min-h-screen flex font-sans">

      {/* LEFT PANEL – Cosmic background */}
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
              opacity: 0.5 + Math.random() * 0.5,
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
        <div className="relative z-10 text-center text-white">
          <div className="text-7xl mb-6">🌙</div>
          <h2 className="text-4xl font-bold leading-snug mb-4">
            Unlock the<br />
            <span className="text-[#D4A73C]">Cosmic Wisdom</span>
          </h2>
          <p className="text-blue-200 text-sm leading-relaxed max-w-xs mx-auto">
            Connect with expert astrologers, get personalized kundli readings, and discover your celestial destiny.
          </p>
        </div>

        {/* Features */}
        <div className="relative z-10 flex justify-around text-center text-white text-xs">
          {["1M+ Users", "500+ Astrologers", "Live Chat"].map((item) => (
            <div key={item}>
              <div className="text-[#D4A73C] font-bold text-lg">✦</div>
              <div className="text-blue-200 mt-1">{item}</div>
            </div>
          ))}
        </div>
      </div>

      {/* RIGHT PANEL – Login form */}
      <div className="w-full lg:w-1/2 flex flex-col justify-center items-center bg-[#f7f8fc] px-6 py-12">
        
        {/* Mobile logo */}
        <Link to="/" className="lg:hidden flex justify-center mb-8">
          <img src={vedic} alt="AstroZura" className="h-16 object-contain" />
        </Link>

        <div className="w-full max-w-md">
          <div className="mb-8">
            <h1 className="text-3xl font-bold text-[#1E3557]">Welcome Back 👋</h1>
            <p className="text-gray-500 text-sm mt-2">Sign in to continue your celestial journey</p>
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
            <span className="text-gray-400 text-xs uppercase tracking-wider">or sign in with</span>
            <div className="flex-1 h-px bg-gray-200" />
          </div>

          {/* Login mode tabs */}
          <div className="flex gap-2 mb-6 bg-gray-100 p-1 rounded-xl">
            <button
              onClick={() => { setLoginMode("otp"); setOtpSent(false); setError(""); setSuccessMsg(""); }}
              className={`flex-1 text-sm py-2 rounded-lg font-semibold transition ${loginMode === "otp" ? "bg-white text-[#1E3557] shadow-sm" : "text-gray-500 hover:text-gray-700"}`}
            >
              📱 OTP Login
            </button>
            <button
              onClick={() => { setLoginMode("password"); setError(""); setSuccessMsg(""); }}
              className={`flex-1 text-sm py-2 rounded-lg font-semibold transition ${loginMode === "password" ? "bg-white text-[#1E3557] shadow-sm" : "text-gray-500 hover:text-gray-700"}`}
            >
              🔒 Password
            </button>
          </div>

          {/* Alerts */}
          {error && (
            <div className="bg-red-50 text-red-600 border border-red-100 rounded-xl p-3 text-xs text-center mb-4">
              ⚠️ {error}
            </div>
          )}
          {successMsg && (
            <div className="bg-green-50 text-green-700 border border-green-100 rounded-xl p-3 text-xs text-center mb-4 font-medium">
              ✅ {successMsg}
            </div>
          )}

          {/* FORMS */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
            {loginMode === "password" ? (
              <form onSubmit={handlePasswordLogin} className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-600 mb-1.5">Email Address</label>
                  <input
                    type="email" value={identifier} onChange={(e) => setIdentifier(e.target.value)}
                    placeholder="you@example.com"
                    className="w-full border border-gray-200 bg-gray-50 rounded-xl px-4 py-3 text-sm outline-none focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 transition"
                    required
                  />
                </div>
                <div>
                  <div className="flex justify-between items-center mb-1.5">
                    <label className="text-xs font-semibold text-gray-600">Password</label>
                    <a href="#" className="text-xs text-[#D4A73C] hover:underline">Forgot?</a>
                  </div>
                  <input
                    type="password" value={password} onChange={(e) => setPassword(e.target.value)}
                    placeholder="Enter your password"
                    className="w-full border border-gray-200 bg-gray-50 rounded-xl px-4 py-3 text-sm outline-none focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 transition"
                    required
                  />
                </div>
                <button
                  type="submit" disabled={loading}
                  className="w-full bg-[#1E3557] text-white font-semibold py-3 rounded-xl hover:bg-[#162744] transition flex justify-center items-center gap-2 shadow mt-2"
                >
                  {loading ? <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white" /> : "Sign In →"}
                </button>
              </form>
            ) : !otpSent ? (
              <form onSubmit={handleSendOtp} className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-600 mb-1.5">Mobile Number</label>
                  <div className="relative">
                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 text-sm font-semibold">+91</span>
                    <input
                      type="tel" value={identifier} onChange={(e) => setIdentifier(e.target.value.replace(/\D/g, "").slice(0, 10))}
                      placeholder="89XXXXXXXX"
                      maxLength={10}
                      className="w-full border border-gray-200 bg-gray-50 rounded-xl pl-12 pr-4 py-3 text-sm outline-none focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 transition tracking-wider"
                      required
                    />
                  </div>
                  <p className="text-xs text-gray-400 mt-1">Enter 10-digit mobile number without country code</p>
                </div>
                <button
                  type="submit" disabled={loading}
                  className="w-full bg-[#D4A73C] text-[#1E3557] font-bold py-3 rounded-xl hover:bg-[#c49530] transition flex justify-center items-center gap-2 shadow"
                >
                  {loading ? <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-[#1E3557]" /> : "Send OTP →"}
                </button>
              </form>
            ) : (
              <form onSubmit={handleVerifyOtp} className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-600 mb-1.5">
                    OTP sent to <span className="text-[#1E3557]">{identifier}</span>
                  </label>
                  <input
                    type="text" ref={otpInputRef} value={otp} onChange={(e) => setOtp(e.target.value)}
                    placeholder="• • • • • •"
                    maxLength={6}
                    className="w-full border border-gray-200 bg-gray-50 rounded-xl px-4 py-3 text-sm outline-none focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 transition text-center tracking-[0.5em] text-xl font-bold"
                    required
                  />
                </div>
                <button
                  type="submit" disabled={loading}
                  className="w-full bg-[#1E3557] text-white font-semibold py-3 rounded-xl hover:bg-[#162744] transition flex justify-center items-center gap-2 shadow"
                >
                  {loading ? <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white" /> : "Verify OTP →"}
                </button>
                <button
                  type="button"
                  onClick={() => { setOtpSent(false); setOtp(""); setError(""); setSuccessMsg(""); }}
                  className="w-full text-xs text-gray-500 hover:text-[#1E3557] transition text-center"
                >
                  ← Use different number/email
                </button>
              </form>
            )}
          </div>

          <p className="text-center text-sm text-gray-500 mt-6">
            Don't have an account?{" "}
            <Link to="/register" className="text-[#D4A73C] font-semibold hover:underline">
              Create Account →
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
