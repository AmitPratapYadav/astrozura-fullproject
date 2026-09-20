import { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import api from "../../api/axios";
import vedicLogo from "../../assets/vedic-astrology.png";
import { Sparkles, ArrowLeft } from "lucide-react";

export default function AstrologerLogin() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [mode, setMode] = useState("login");
  const [resetIdentifier, setResetIdentifier] = useState("");
  const [resetOtp, setResetOtp] = useState("");
  const [resetPassword, setResetPassword] = useState("");
  const [resetPasswordConfirmation, setResetPasswordConfirmation] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  
  const { user } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    window.scrollTo(0, 0);
    if (user && user.role === 'astrologer') {
      navigate("/astrologer/dashboard");
    }
  }, [user, navigate]);

  const handleLogin = async (e) => {
    e.preventDefault();
    if (!email || !password) {
      setError("Please enter your email and password.");
      return;
    }

    setLoading(true);
    setError("");
    setSuccess("");

    try {
      // Step 1: Call login API
      const response = await api.post("/astrologer/login", { email, password });

      if (response.data.success && response.data.token) {
        const newToken = response.data.token;

        // Step 2: Store token
        localStorage.setItem("auth_token", newToken);

        // Step 3: Fetch user details to confirm role
        try {
          const userRes = await api.get("/user", {
            headers: { Authorization: `Bearer ${newToken}` }
          });

          if (userRes.data.success && userRes.data.user?.role === "astrologer") {
            localStorage.setItem("user", JSON.stringify(userRes.data.user));
            // Force page reload to update AuthContext state
            window.location.href = "/astrologer/dashboard";
          } else {
            // Role mismatch — clear token and show error
            localStorage.removeItem("auth_token");
            localStorage.removeItem("user");
            setError("Access denied. This portal is only for registered Astrologers.");
          }
        } catch {
          localStorage.removeItem("auth_token");
          localStorage.removeItem("user");
          setError("Could not verify your account. Please try again.");
        }

      } else {
        setError(response.data.message || "Login failed. Please check your credentials.");
      }
    } catch (err) {
      setError(err.response?.data?.message || err.message || "Invalid credentials or unauthorized.");
    } finally {
      setLoading(false);
    }
  };

  const startReset = () => {
    setMode("forgot");
    setError("");
    setSuccess("");
    setResetIdentifier(email);
    setResetOtp("");
    setResetPassword("");
    setResetPasswordConfirmation("");
  };

  const backToLogin = () => {
    setMode("login");
    setError("");
    setSuccess("");
    setResetOtp("");
    setResetPassword("");
    setResetPasswordConfirmation("");
  };

  const handleSendResetOtp = async (e) => {
    e.preventDefault();
    if (!resetIdentifier.trim()) {
      setError("Please enter your registered email or mobile number.");
      return;
    }

    setLoading(true);
    setError("");
    setSuccess("");

    try {
      const response = await api.post("/astrologer/password/forgot", {
        identifier: resetIdentifier.trim(),
      });

      if (response.data.success) {
        setMode("reset");
        setSuccess(response.data.message || "Password reset OTP sent successfully.");
        if (response.data.dev_otp) setResetOtp(String(response.data.dev_otp));
      } else {
        setError(response.data.message || "Unable to send reset OTP.");
      }
    } catch (err) {
      setError(err.response?.data?.message || err.message || "Unable to send reset OTP.");
    } finally {
      setLoading(false);
    }
  };

  const handleResetPassword = async (e) => {
    e.preventDefault();
    if (!resetOtp || !resetPassword || !resetPasswordConfirmation) {
      setError("Please enter the OTP and your new password.");
      return;
    }
    if (resetPassword !== resetPasswordConfirmation) {
      setError("New password and confirmation do not match.");
      return;
    }

    setLoading(true);
    setError("");
    setSuccess("");

    try {
      const response = await api.post("/astrologer/password/reset", {
        identifier: resetIdentifier.trim(),
        otp: resetOtp,
        password: resetPassword,
        password_confirmation: resetPasswordConfirmation,
      });

      if (response.data.success) {
        setEmail(resetIdentifier.includes("@") ? resetIdentifier.trim() : email);
        setSuccess(response.data.message || "Password reset successfully. Please log in.");
        setMode("login");
        setPassword("");
        setResetOtp("");
        setResetPassword("");
        setResetPasswordConfirmation("");
      } else {
        setError(response.data.message || "Unable to reset password.");
      }
    } catch (err) {
      setError(err.response?.data?.message || err.message || "Unable to reset password.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex bg-white font-sans overflow-hidden">
      
      {/* LEFT PANEL - COSMIC THEME */}
      <div className="hidden lg:flex lg:w-5/12 relative bg-gradient-to-br from-[#0B1528] via-[#112240] to-[#0A192F] flex-col justify-between p-12 overflow-hidden shadow-2xl z-10">
        
        {/* Animated Background Elements */}
        <div className="absolute inset-0 z-0 opacity-20 bg-[url('https://www.transparenttextures.com/patterns/stardust.png')]"></div>
        <div className="absolute -top-32 -left-32 w-96 h-96 bg-[#D4A73C] rounded-full mix-blend-multiply filter blur-[128px] opacity-30 animate-pulse"></div>
        <div className="absolute -bottom-32 -right-32 w-96 h-96 bg-[#4A90E2] rounded-full mix-blend-multiply filter blur-[128px] opacity-20"></div>

        <div className="relative z-10">
          <Link to="/" className="inline-block bg-white p-3 rounded-2xl shadow-lg border border-white/20 hover:scale-105 transition-transform">
            <img src={vedicLogo} alt="AstroZura Logo" className="h-14 object-contain" />
          </Link>
        </div>

        <div className="relative z-10 text-white mt-12 mb-auto pb-20">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 border border-white/20 text-[#D4A73C] text-xs font-bold uppercase tracking-widest mb-6">
            <Sparkles size={14} /> Astrologer Portal
          </div>
          <h1 className="text-4xl lg:text-5xl font-bold leading-tight mb-6">
            Guide souls with your <span className="text-transparent bg-clip-text bg-gradient-to-r from-[#D4A73C] to-[#F1D570]">cosmic wisdom.</span>
          </h1>
          <p className="text-blue-100/70 text-lg max-w-md leading-relaxed">
            Access your dashboard to manage consultations, update your schedule, and connect with users seeking your guidance.
          </p>
        </div>

        <div className="relative z-10 flex items-center gap-4 text-white/50 text-sm">
          <span>&copy; {new Date().getFullYear()} AstroZura</span>
          <span>&bull;</span>
          <a href="#" className="hover:text-white transition">Privacy</a>
          <span>&bull;</span>
          <a href="#" className="hover:text-white transition">Terms</a>
        </div>
      </div>

      {/* RIGHT PANEL - FORM */}
      <div className="w-full lg:w-7/12 flex items-center justify-center p-6 sm:p-12 relative bg-[#FAFAFA]">
        
        <Link to="/" className="absolute top-6 left-6 sm:top-8 sm:left-8 flex items-center gap-2 text-sm font-semibold text-gray-500 hover:text-[#1E3557] transition">
          <ArrowLeft size={16} /> Back to home
        </Link>

        {/* Mobile Logo Logo */}
        <div className="absolute top-8 right-8 lg:hidden">
            <img src={vedicLogo} alt="AstroZura Logo" className="h-10 object-contain drop-shadow-md" />
        </div>

        <div className="w-full max-w-md">
          <div className="mb-10 text-center lg:text-left">
            <h2 className="text-3xl font-bold text-[#1E3557] mb-3">
              {mode === "login" ? "Astrologer Login" : mode === "forgot" ? "Reset Password" : "Verify OTP"}
            </h2>
            <p className="text-gray-500">
              {mode === "login"
                ? "Enter your credentials to access your portal"
                : mode === "forgot"
                  ? "Enter your registered email or mobile number to receive an OTP"
                  : "Enter the OTP sent to your registered mobile number"}
            </p>
          </div>

          {user && user.role !== 'astrologer' && (
            <div className="bg-blue-50/50 text-blue-800 p-4 rounded-2xl mb-6 text-sm border border-blue-100">
              You're currently logged in as a normal user <span className="font-bold">({user.name})</span>. Please log out first to switch to an Astrologer account.
            </div>
          )}

          {error && (
            <div className="bg-red-50/50 text-red-600 p-4 rounded-2xl mb-6 text-sm border border-red-100 flex items-center gap-2">
              <span className="text-lg">⚠</span> {error}
            </div>
          )}

          {success && (
            <div className="bg-emerald-50/80 text-emerald-700 p-4 rounded-2xl mb-6 text-sm border border-emerald-100">
              {success}
            </div>
          )}

          {mode === "login" && (
            <form onSubmit={handleLogin} className="space-y-5">
              <div>
                <label className="block text-xs font-bold tracking-wide text-gray-600 uppercase mb-2">Email Address</label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="astrologer@example.com"
                  className="w-full bg-white border border-gray-200 rounded-xl px-4 py-3.5 text-sm text-[#1E3557] focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 outline-none transition-all shadow-sm"
                  required
                />
              </div>

              <div>
                <div className="flex justify-between items-center mb-2">
                  <label className="block text-xs font-bold tracking-wide text-gray-600 uppercase">Password</label>
                  <button type="button" onClick={startReset} className="text-xs font-semibold text-[#D4A73C] hover:text-[#b88c29] transition">Forgot Password?</button>
                </div>
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Enter your secure password"
                  className="w-full bg-white border border-gray-200 rounded-xl px-4 py-3.5 text-sm text-[#1E3557] focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 outline-none transition-all shadow-sm"
                  required
                />
              </div>

              <button
                type="submit"
                disabled={loading}
                className="w-full bg-gradient-to-r from-[#1E3557] to-[#2c4b7c] text-white font-bold py-4 mt-2 rounded-xl hover:shadow-lg hover:-translate-y-0.5 transition-all duration-300 flex justify-center items-center relative overflow-hidden group"
              >
                <div className="absolute inset-0 w-full h-full bg-white/20 group-hover:bg-transparent transition-colors"></div>
                {loading ? (
                  <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                ) : (
                  "Access Portal"
                )}
              </button>
            </form>
          )}

          {mode === "forgot" && (
            <form onSubmit={handleSendResetOtp} className="space-y-5">
              <div>
                <label className="block text-xs font-bold tracking-wide text-gray-600 uppercase mb-2">Registered Email or Mobile</label>
                <input
                  type="text"
                  value={resetIdentifier}
                  onChange={(e) => setResetIdentifier(e.target.value)}
                  placeholder="email@example.com or 9876543210"
                  className="w-full bg-white border border-gray-200 rounded-xl px-4 py-3.5 text-sm text-[#1E3557] focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 outline-none transition-all shadow-sm"
                  required
                />
              </div>
              <button type="submit" disabled={loading} className="w-full bg-gradient-to-r from-[#1E3557] to-[#2c4b7c] text-white font-bold py-4 rounded-xl hover:shadow-lg transition-all flex justify-center items-center">
                {loading ? <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div> : "Send Reset OTP"}
              </button>
              <button type="button" onClick={backToLogin} className="w-full rounded-xl border border-gray-200 bg-white py-3 text-sm font-bold text-[#1E3557] hover:bg-gray-50 transition">
                Back to Login
              </button>
            </form>
          )}

          {mode === "reset" && (
            <form onSubmit={handleResetPassword} className="space-y-5">
              <div>
                <label className="block text-xs font-bold tracking-wide text-gray-600 uppercase mb-2">OTP</label>
                <input
                  type="text"
                  inputMode="numeric"
                  value={resetOtp}
                  onChange={(e) => setResetOtp(e.target.value)}
                  placeholder="Enter 6 digit OTP"
                  className="w-full bg-white border border-gray-200 rounded-xl px-4 py-3.5 text-sm text-[#1E3557] focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 outline-none transition-all shadow-sm"
                  required
                />
              </div>
              <div>
                <label className="block text-xs font-bold tracking-wide text-gray-600 uppercase mb-2">New Password</label>
                <input
                  type="password"
                  value={resetPassword}
                  onChange={(e) => setResetPassword(e.target.value)}
                  placeholder="Create a new password"
                  className="w-full bg-white border border-gray-200 rounded-xl px-4 py-3.5 text-sm text-[#1E3557] focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 outline-none transition-all shadow-sm"
                  required
                />
              </div>
              <div>
                <label className="block text-xs font-bold tracking-wide text-gray-600 uppercase mb-2">Confirm New Password</label>
                <input
                  type="password"
                  value={resetPasswordConfirmation}
                  onChange={(e) => setResetPasswordConfirmation(e.target.value)}
                  placeholder="Repeat the new password"
                  className="w-full bg-white border border-gray-200 rounded-xl px-4 py-3.5 text-sm text-[#1E3557] focus:border-[#D4A73C] focus:ring-2 focus:ring-[#D4A73C]/20 outline-none transition-all shadow-sm"
                  required
                />
              </div>
              <button type="submit" disabled={loading} className="w-full bg-gradient-to-r from-[#1E3557] to-[#2c4b7c] text-white font-bold py-4 rounded-xl hover:shadow-lg transition-all flex justify-center items-center">
                {loading ? <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div> : "Reset Password"}
              </button>
              <button type="button" onClick={startReset} className="w-full rounded-xl border border-gray-200 bg-white py-3 text-sm font-bold text-[#1E3557] hover:bg-gray-50 transition">
                Request New OTP
              </button>
            </form>
          )}

        </div>
      </div>

    </div>
  );
}
