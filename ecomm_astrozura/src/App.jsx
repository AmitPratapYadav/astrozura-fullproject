import { BrowserRouter, Routes, Route, useLocation } from "react-router-dom";
import Navbar from "./components/Navbar";
import Home from "./pages/Home";
import ProductPage from "./pages/ProductPage";
import Category from "./pages/Category";
import Cart from "./pages/Cart";
import Checkout from "./pages/Checkout";
import Allproduct from "./pages/Allproduct";
import Contact from "./pages/Contact";
import About from "./pages/About";
import SR from "./pages/SR";
import PrivacyPolicy from "./pages/PrivacyPolicy";
import SupportPage from "./pages/SupportPage";
import RefundPolicy from "./pages/RefundPolicy";
import Login from "./pages/Login";
import Register from "./pages/Register";
import OAuthCallback from "./pages/OAuthCallback";
import DashboardLayout from "./pages/Dashboard/DashboardLayout";
import DashboardHome from "./pages/Dashboard/DashboardHome";
import UserProfile from "./pages/Dashboard/UserProfile";
import UserOrders from "./pages/Dashboard/UserOrders";
import UserWishlist from "./pages/Dashboard/UserWishlist";
import { AuthProvider } from "./context/AuthContext";
import { CartProvider } from "./context/CartContext";
import TestingAccessGate from "./components/TestingAccessGate";

function AppContent() {
  const location = useLocation();
  const hideNavbarPaths = ["/dashboard"];
  const shouldHideNavbar = hideNavbarPaths.some(path => location.pathname.startsWith(path));

  return (
    <>
      {!shouldHideNavbar && <Navbar />}
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/product/:id" element={<ProductPage />} />
        <Route path="/category" element={<Category />} />
        <Route path="/cart" element={<Cart />} />
        <Route path="/checkout" element={<Checkout />} />
        <Route path="/allproduct" element={<Allproduct />} />
        <Route path="/contact" element={<Contact />} />
        <Route path="/about" element={<About />} />
        <Route path="/shipping-return" element={<SR />} />
        <Route path="/privacy-policy" element={<PrivacyPolicy />} />
        <Route path="/support" element={<SupportPage />} />
        <Route path="/refund-policy" element={<RefundPolicy />} />
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/oauth/callback" element={<OAuthCallback />} />

        {/* USER DASHBOARD ROUTES */}
        <Route path="/dashboard" element={<DashboardLayout />}>
          <Route index element={<DashboardHome />} />
          <Route path="profile" element={<UserProfile />} />
          <Route path="orders" element={<UserOrders />} />
          <Route path="wishlist" element={<UserWishlist />} />
        </Route>
      </Routes>
    </>
  );
}

function App() {
  return (
    <TestingAccessGate>
      <BrowserRouter>
        <AuthProvider>
          <CartProvider>
            <AppContent />
          </CartProvider>
        </AuthProvider>
      </BrowserRouter>
    </TestingAccessGate>
  );
}

export default App;
