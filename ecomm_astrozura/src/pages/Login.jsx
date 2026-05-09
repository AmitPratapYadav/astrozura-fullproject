import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export default function Login() {
  const { loginWithPassword, sendOtp, loginWithOtp } = useAuth();
  const navigate = useNavigate();

  const [loginMethod, setLoginMethod] = useState("phone"); // 'phone' or 'email'
  const [step, setStep] = useState("identifier"); // 'identifier' or 'otp'
  const [identifier, setIdentifier] = useState("");
  const [otp, setOtp] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [devOtp, setDevOtp] = useState("");

  const handleSendOtp = async (e) => {
    e.preventDefault();
    if (!identifier) {
      setError("Please enter your phone number or email.");
      return;
    }

    setLoading(true);
    setError("");
    try {
      const response = await sendOtp(identifier);
      if (response.success) {
        setStep("otp");
        if (response.dev_otp) {
          setDevOtp(response.dev_otp);
        }
      } else {
        setError(response.message || "Failed to send OTP.");
      }
    } catch (err) {
      setError(err.message || "Something went wrong.");
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOtp = async (e) => {
    e.preventDefault();
    if (!otp) {
      setError("Please enter the OTP.");
      return;
    }

    setLoading(true);
    setError("");
    try {
      const response = await loginWithOtp(identifier, otp);
      if (response.success) {
        navigate("/");
      } else {
        setError("Invalid OTP. Please try again.");
      }
    } catch (err) {
      setError(err.message || "Login failed.");
    } finally {
      setLoading(false);
    }
  };

  const handleEmailLogin = async (e) => {
    e.preventDefault();
    if (!identifier || !password) {
      setError("Email and password are required.");
      return;
    }

    setLoading(true);
    setError("");
    try {
      const response = await loginWithPassword({ email: identifier, password });
      if (response) {
        navigate("/");
      } else {
        setError("Invalid email or password.");
      }
    } catch (err) {
      setError(err.message || "Login failed.");
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleLogin = () => {
    window.location.href = `${import.meta.env.VITE_API_BASE_URL}/auth/google?frontend=ecomm`;
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0f1b2d] via-[#1a2e4a] to-[#0f1b2d] flex items-center justify-center px-4 py-12">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-white">
            Astro<span className="text-[#c9a227]">Zura</span>
          </h1>
          <p className="text-gray-400 mt-2 text-sm">Login to your account to continue</p>
        </div>

        <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl p-8 shadow-2xl">
          <div className="flex bg-white/5 p-1 rounded-xl mb-8">
            <button
              onClick={() => { setLoginMethod("phone"); setStep("identifier"); setError(""); }}
              className={`flex-1 py-2 text-sm font-semibold rounded-lg transition-all ${
                loginMethod === "phone" ? "bg-[#c9a227] text-white shadow-lg" : "text-gray-400 hover:text-white"
              }`}
            >
              Phone / OTP
            </button>
            <button
              onClick={() => { setLoginMethod("email"); setStep("identifier"); setError(""); }}
              className={`flex-1 py-2 text-sm font-semibold rounded-lg transition-all ${
                loginMethod === "email" ? "bg-[#c9a227] text-white shadow-lg" : "text-gray-400 hover:text-white"
              }`}
            >
              Email & Password
            </button>
          </div>

          {error && (
            <div className="bg-red-500/20 border border-red-500/40 text-red-300 text-xs px-4 py-3 rounded-lg mb-6">
              {error}
            </div>
          )}

          {devOtp && step === "otp" && (
            <div className="bg-green-500/20 border border-green-500/40 text-green-300 text-xs px-4 py-3 rounded-lg mb-6 text-center">
              Dev OTP: <span className="font-bold tracking-widest">{devOtp}</span>
            </div>
          )}

          {loginMethod === "phone" ? (
            step === "identifier" ? (
              <form onSubmit={handleSendOtp} className="space-y-5">
                <div>
                  <label className="block text-gray-300 text-sm mb-1.5 font-medium">Phone Number</label>
                  <input
                    type="text"
                    value={identifier}
                    onChange={(e) => setIdentifier(e.target.value)}
                    placeholder="Enter phone number"
                    className="w-full bg-white/10 border border-white/20 text-white placeholder-gray-500 rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-[#c9a227] transition-all"
                  />
                </div>
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full bg-[#c9a227] hover:bg-[#b8911f] text-white font-bold py-3.5 rounded-lg transition-all duration-200 disabled:opacity-60 active:scale-[0.98]"
                >
                  {loading ? "Sending..." : "Send OTP"}
                </button>
              </form>
            ) : (
              <form onSubmit={handleVerifyOtp} className="space-y-5">
                <div>
                  <label className="block text-gray-300 text-sm mb-1.5 font-medium">Enter 6-Digit OTP</label>
                  <input
                    type="text"
                    maxLength={6}
                    value={otp}
                    onChange={(e) => setOtp(e.target.value)}
                    placeholder="000000"
                    className="w-full bg-white/10 border border-white/20 text-white text-center tracking-[1em] placeholder-gray-500 rounded-lg px-4 py-3 text-lg font-bold focus:outline-none focus:border-[#c9a227] transition-all"
                  />
                  <p className="text-[10px] text-gray-500 mt-2 text-center">OTP sent to {identifier}</p>
                </div>
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full bg-[#c9a227] hover:bg-[#b8911f] text-white font-bold py-3.5 rounded-lg transition-all duration-200 disabled:opacity-60 active:scale-[0.98]"
                >
                  {loading ? "Verifying..." : "Verify & Login"}
                </button>
                <button 
                  type="button" 
                  onClick={() => setStep("identifier")}
                  className="w-full text-gray-400 text-xs hover:text-white transition"
                >
                  Change Phone Number
                </button>
              </form>
            )
          ) : (
            <form onSubmit={handleEmailLogin} className="space-y-5">
              <div>
                <label className="block text-gray-300 text-sm mb-1.5 font-medium">Email Address</label>
                <input
                  type="email"
                  value={identifier}
                  onChange={(e) => setIdentifier(e.target.value)}
                  placeholder="you@example.com"
                  className="w-full bg-white/10 border border-white/20 text-white placeholder-gray-500 rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-[#c9a227] transition-all"
                />
              </div>
              <div>
                <label className="block text-gray-300 text-sm mb-1.5 font-medium">Password</label>
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Enter your password"
                  className="w-full bg-white/10 border border-white/20 text-white placeholder-gray-500 rounded-lg px-4 py-3 text-sm focus:outline-none focus:border-[#c9a227] transition-all"
                />
              </div>
              <button
                type="submit"
                disabled={loading}
                className="w-full bg-[#c9a227] hover:bg-[#b8911f] text-white font-bold py-3.5 rounded-lg transition-all duration-200 disabled:opacity-60 active:scale-[0.98]"
              >
                {loading ? "Logging in..." : "Login"}
              </button>
            </form>
          )}

          <div className="flex items-center gap-3 my-8">
            <div className="h-px flex-1 bg-white/10"></div>
            <span className="text-[10px] uppercase tracking-[0.3em] text-gray-500 font-bold">or continue with</span>
            <div className="h-px flex-1 bg-white/10"></div>
          </div>

          <button
            type="button"
            onClick={handleGoogleLogin}
            className="w-full bg-white/5 border border-white/10 text-white font-bold py-3 rounded-lg transition-all duration-200 hover:bg-white/10 flex items-center justify-center gap-3 active:scale-[0.98]"
          >
            <svg className="w-5 h-5" viewBox="0 0 24 24">
              <path fill="#EA4335" d="M12 5.04c1.94 0 3.51.68 4.75 1.81l3.5-3.5C18.16 1.42 15.31 0 12 0 7.31 0 3.32 2.67 1.38 6.57l4.13 3.2C6.47 7.21 9 5.04 12 5.04z" />
              <path fill="#4285F4" d="M23.49 12.27c0-.79-.07-1.54-.19-2.27H12v4.51h6.47c-.29 1.48-1.14 2.73-2.4 3.58l3.86 3C22.14 18.59 23.49 15.72 23.49 12.27z" />
              <path fill="#FBBC05" d="M5.51 14.77c-.28-.84-.44-1.74-.44-2.77s.16-1.93.44-2.77l-4.13-3.2C.51 7.74 0 9.8 0 12s.51 4.26 1.38 5.97l4.13-3.2z" />
              <path fill="#34A853" d="M12 24c3.24 0 5.97-1.07 7.96-2.91l-3.86-3c-1.08.73-2.48 1.18-4.1 1.18-3.14 0-5.8-2.12-6.75-4.96l-4.13 3.2C3.32 21.33 7.31 24 12 24z" />
            </svg>
            Google
          </button>

          <p className="text-gray-500 text-sm text-center mt-8">
            Don't have an account?{" "}
            <Link to="/register" className="text-[#c9a227] hover:underline font-bold">
              Register here
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
