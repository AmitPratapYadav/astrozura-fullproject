import { useState } from "react";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import Dashboard from "./pages/Dashboard";
import Astrologers from "./pages/Astrologers";
import Users from "./pages/Users";
import Consultations from "./pages/Consultations";
import Bookings from "./pages/Bookings";
import Payments from "./pages/Payments";
import Reports from "./pages/Reports";
import Reviews from "./pages/Review";
import Settings from "./pages/Settings";
import Profile from "./pages/Profile";
import AddAstrologer from "./pages/AddAstrologer";
import Categories from "./pages/Categories";
import AddCategory from "./pages/AddCategory";
import EditCategory from "./pages/EditCategory";
import Products from "./pages/Products";
import AddProduct from "./pages/AddProduct";
import EditProduct from "./pages/EditProduct";
import Rituals from "./pages/Rituals";
import SubscriptionPlans from "./pages/SubscriptionPlans";
import UserSubscriptions from "./pages/UserSubscriptions";
import Sidebar from "./components/Sidebar";
import Topbar from "./components/Topbar";
import AdminLogin from "./pages/AdminLogin";
import ProtectedRoute from "./components/ProtectedRoute";
import { AppProvider } from "./context/AppContext";
import TestingAccessGate from "./components/TestingAccessGate";

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
            <Route path="/rituals" element={<Rituals />} />
            <Route path="/users" element={<Users />} />
            <Route path="/consultations" element={<Consultations />} />
            <Route path="/bookings" element={<Bookings />} />
            <Route path="/payments" element={<Payments />} />
            <Route path="/reports" element={<Reports />} />
            <Route path="/reviews" element={<Reviews />} />
            <Route path="/settings" element={<Settings />} />
            <Route path="/subscription-plans" element={<SubscriptionPlans />} />
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
    <TestingAccessGate>
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
    </TestingAccessGate>
  );
}

export default App;
