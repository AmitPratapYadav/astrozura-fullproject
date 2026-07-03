import { useState } from "react";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import Dashboard from "./pages/Dashboard";
import Astrologers from "./pages/Astrologers";
import Users from "./pages/Users";
import UserDetails from "./pages/UserDetails";
import Bookings from "./pages/Bookings";
import Payments from "./pages/Payments";
import Reports from "./pages/Reports";
import Reviews from "./pages/Review";
import Profile from "./pages/Profile";
import AddAstrologer from "./pages/AddAstrologer";
import Categories from "./pages/Categories";
import AddCategory from "./pages/AddCategory";
import EditCategory from "./pages/EditCategory";
import Products from "./pages/Products";
import AddProduct from "./pages/AddProduct";
import EditProduct from "./pages/EditProduct";
import Orders from "./pages/Orders";
import Rituals from "./pages/Rituals";
import BlogCategories from "./pages/BlogCategories";
import Blogs from "./pages/Blogs";
import UserSubscriptions from "./pages/UserSubscriptions";
import OrderDetails from "./pages/OrderDetails";
import RitualBookings from "./pages/RitualBookings";
import Offers from "./pages/Offers";
import Sidebar from "./components/Sidebar";
import Topbar from "./components/Topbar";
import AdminLogin from "./pages/AdminLogin";
import ProtectedRoute from "./components/ProtectedRoute";
import { AppProvider } from "./context/AppContext";

function AdminShell() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div className="flex h-screen bg-gray-100 overflow-hidden">
      <Sidebar isOpen={isOpen} onClose={() => setIsOpen(false)} />

      <div className="flex flex-col flex-1 w-0">
        <Topbar toggleSidebar={() => setIsOpen(!isOpen)} />

        <main className="flex-1 overflow-y-auto p-4 md:p-6">
          <Routes>
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/astrologers" element={<Astrologers />} />
            <Route path="/add-astrologer" element={<AddAstrologer />} />
            <Route path="/categories" element={<Categories />} />
            <Route path="/add-category" element={<AddCategory />} />
            <Route path="/edit-category/:id" element={<EditCategory />} />
            <Route path="/products" element={<Products />} />
            <Route path="/add-product" element={<AddProduct />} />
            <Route path="/edit-product/:id" element={<EditProduct />} />
            <Route path="/orders" element={<Orders />} />
            <Route path="/orders/:id" element={<OrderDetails />} />
            <Route path="/rituals" element={<Rituals />} />
            <Route path="/ritual-bookings" element={<RitualBookings />} />
            <Route path="/offers" element={<Offers />} />
            <Route path="/blog-categories" element={<BlogCategories />} />
            <Route path="/blogs" element={<Blogs />} />
            <Route path="/users" element={<Users />} />
            <Route path="/users/:id" element={<UserDetails />} />
            <Route path="/consultations" element={<Navigate to="/bookings" replace />} />
            <Route path="/bookings" element={<Bookings />} />
            <Route path="/payments" element={<Payments />} />
            <Route path="/reports" element={<Reports />} />
            <Route path="/reviews" element={<Reviews />} />
            <Route path="/settings" element={<Navigate to="/dashboard" replace />} />
            <Route path="/subscription-plans" element={<Navigate to="/user-subscriptions" replace />} />
            <Route path="/user-subscriptions" element={<UserSubscriptions />} />
            <Route path="/profile" element={<Profile />} />
          </Routes>
        </main>
      </div>
    </div>
  );
}

function App() {
  return (
    <BrowserRouter>
      <AppProvider>
        <Routes>
            <Route path="/login" element={<AdminLogin />} />
            <Route
              path="/*"
              element={
                <ProtectedRoute>
                  <AdminShell />
                </ProtectedRoute>
              }
            />
        </Routes>
      </AppProvider>
    </BrowserRouter>
  );
}

export default App;
