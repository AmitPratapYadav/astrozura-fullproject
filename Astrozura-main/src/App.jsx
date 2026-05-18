import { Suspense, lazy } from "react";
import { BrowserRouter, Routes, Route } from "react-router-dom";

import Home from "./pages/Home";
import Astrologers from "./pages/Astrologers";
import AstrologerProfile from "./pages/AstrologerProfile";
import ConsultationPage from "./pages/ConsultationPage";
import Products from "./pages/Products";
import ProductDetail from "./pages/ProductDetail";
import Subscription from "./pages/Subscription";
import Rituals from "./pages/Rituals";
import RitualDetail from "./pages/RitualDetail";
import RitualBooking from "./pages/RitualBooking";
import Matching from "./pages/Matching";
import Kundli from "./pages/Kundli";
import Numerology from "./pages/Numerology";
import Rashifal from "./pages/Rashifal";
import Panchang from "./pages/Panchang";
import Services from "./pages/Services";
import ServiceDetail from "./pages/ServiceDetail";
import LalKitabReport from "./pages/LalKitabReport";
import TarotReading from "./pages/TarotReading";
import VedicCalculators from "./pages/VedicCalculators";
import MatchingCalculators from "./pages/MatchingCalculators";
import AboutUs from "./pages/AboutUs";
import ContactSupport from "./pages/ContactSupport";
import PrivacyPolicy from "./pages/PrivacyPolicy";
import TermsConditions from "./pages/TermsConditions";
import Login from "./pages/Login";
import Register from "./pages/Register";
import OAuthCallback from "./pages/OAuthCallback";
import GoogleOAuthBridge from "./pages/GoogleOAuthBridge";
import AstrologerLogin from "./pages/astrologer/AstrologerLogin";
import AstrologerDashboard from "./pages/astrologer/Dashboard";
import UserDashboard from "./pages/user/UserDashboard";
import UserProfile from "./pages/user/UserProfile";
import MyBookings from "./pages/user/MyBookings";
import { AuthProvider } from "./context/AuthContext";
import { PushNotificationsProvider } from "./context/PushNotificationsContext";
import ProtectedRoute from "./components/ProtectedRoute";
import ScrollToTop from "./components/ScrollToTop";
import TestingAccessGate from "./components/TestingAccessGate";

const ChatPage = lazy(() => import("./pages/ChatPage"));
const LiveSessions = lazy(() => import("./pages/LiveSessions"));

const RouteLoader = () => (
  <div className="flex min-h-screen items-center justify-center bg-[#FBF7F0]">
    <div className="h-12 w-12 animate-spin rounded-full border-b-2 border-[#D4A73C]" />
  </div>
);

function App() {
  return (
    <TestingAccessGate>
      <AuthProvider>
        <PushNotificationsProvider>
          <BrowserRouter>
            <ScrollToTop />
            <Suspense fallback={<RouteLoader />}>
          <Routes>
          {/* Public Routes */}
          <Route path="/login" element={<Login />} />
          <Route path="/register" element={<Register />} />
          <Route path="/oauth/callback" element={<OAuthCallback />} />
          <Route path="/api/auth/google/callback" element={<GoogleOAuthBridge />} />
          <Route path="/" element={<Home />} />
          <Route path="/astrologers" element={<Astrologers />} />
          <Route path="/profile/:id" element={<AstrologerProfile />} />
          <Route path="/products" element={<Products />} />
          <Route path="/product/:id" element={<ProductDetail />} />
          <Route path="/rituals" element={<Rituals />} />
          <Route path="/rituals/:slug" element={<RitualDetail />} />
          <Route path="/rituals/:slug/book" element={
            <ProtectedRoute>
              <RitualBooking />
            </ProtectedRoute>
          } />
          <Route path="/services" element={<Services />} />
          <Route path="/services/lal-kitab-report" element={<LalKitabReport />} />
          <Route path="/services/tarot-reading" element={<TarotReading />} />
          <Route path="/services/:slug" element={<ServiceDetail />} />
          <Route path="/vedic-calculators" element={<VedicCalculators />} />
          <Route path="/matching-calculators" element={<MatchingCalculators />} />
          <Route path="/subscription" element={<Subscription />} />
          <Route path="/matching" element={<Matching />} />
          <Route path="/kundli" element={<Kundli />} />
          <Route path="/numerology" element={<Numerology />} />
          <Route path="/rashifal" element={<Rashifal />} />
          <Route path="/panchang" element={<Panchang />} />
          <Route path="/about-us" element={<AboutUs />} />
          <Route path="/contact-support" element={<ContactSupport />} />
          <Route path="/privacy-policy" element={<PrivacyPolicy />} />
          <Route path="/terms-and-conditions" element={<TermsConditions />} />
          <Route path="/live" element={<LiveSessions />} />

          {/* Astrologer Routes */}
          <Route path="/astrologer/login" element={<AstrologerLogin />} />
          <Route path="/astrologer-login" element={<AstrologerLogin />} />
          <Route path="/astrologer/dashboard" element={<AstrologerDashboard />} />

          {/* Protected Routes */}
          <Route path="/dashboard" element={
            <ProtectedRoute>
              <UserDashboard />
            </ProtectedRoute>
          } />
          <Route path="/user-profile" element={
            <ProtectedRoute>
              <UserProfile />
            </ProtectedRoute>
          } />
          <Route path="/profile-setup" element={
            <ProtectedRoute>
              <UserProfile />
            </ProtectedRoute>
          } />
          <Route path="/my-bookings" element={
            <ProtectedRoute>
              <MyBookings />
            </ProtectedRoute>
          } />
          <Route path="/consultation/:astrologerId" element={
            <ProtectedRoute>
              <ConsultationPage />
            </ProtectedRoute>
          } />
          <Route path="/consultation" element={
            <ProtectedRoute>
              <ConsultationPage />
            </ProtectedRoute>
          } />
          <Route path="/chat" element={
            <ProtectedRoute>
              <ChatPage />
            </ProtectedRoute>
          } />
          <Route path="/chat/:bookingId" element={
            <ProtectedRoute>
              <ChatPage />
            </ProtectedRoute>
          } />
          <Route path="/session/:bookingId" element={
            <ProtectedRoute>
              <ChatPage />
            </ProtectedRoute>
          } />
          </Routes>
            </Suspense>
          </BrowserRouter>
        </PushNotificationsProvider>
      </AuthProvider>
    </TestingAccessGate>
  );
}

export default App;
