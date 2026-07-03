import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import Navbar from "../../components/Navbar";
import Footer from "../../components/Footer";
import { useAuth } from "../../context/AuthContext";
import UserDashboardSidebar from "../../components/UserDashboardSidebar";

export default function UserDashboard() {
  const { user } = useAuth();
  const currentHour = new Date().getHours();
  const greeting = currentHour < 12 ? "Good Morning" : currentHour < 18 ? "Good Afternoon" : "Good Evening";

  return (
    <div className="bg-[#f8f9fa] min-h-screen flex flex-col font-sans">
      <Navbar />

      <div className="flex-1 max-w-7xl w-full mx-auto p-4 lg:p-8 flex flex-col lg:flex-row gap-8">
        
        <UserDashboardSidebar />

        {/* MAIN CONTENT AREA */}
        <main className="flex-1 flex flex-col gap-6">
          
          {/* Header */}
          <div className="flex justify-between items-end mb-2">
            <div>
              <p className="text-[#D4A73C] font-medium text-sm tracking-wider uppercase mb-1">{greeting}</p>
              <h1 className="text-3xl font-bold text-[#1E3557]">
                Welcome back, {user?.name?.split(' ')[0] || "User"} 👋
              </h1>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
             
             {/* Stats Card: Upcoming Bookings */}
             <div className="bg-white p-6 md:p-8 rounded-2xl shadow-sm border border-gray-100 relative overflow-hidden group hover:shadow-md transition-shadow">
                <div className="absolute top-0 right-0 w-32 h-32 bg-[#D4A73C] opacity-5 rounded-bl-full -mr-8 -mt-8 transition-transform group-hover:scale-110"></div>
                
                <div className="flex justify-between items-center mb-6">
                  <h3 className="text-gray-500 text-xs font-bold tracking-widest uppercase">Upcoming Bookings</h3>
                </div>
                
                <div className="flex items-baseline gap-2 mb-6">
                  <p className="text-5xl font-black text-[#1E3557]">0</p>
                  <span className="text-gray-400 font-medium text-sm">Consultations</span>
                </div>
                
                <Link to="/astrologers" className="inline-block text-sm font-semibold text-[#D4A73C] hover:text-[#b88c29] transition group">
                  Book a consultation →
                </Link>
             </div>
             
             {/* CTA Card: Profile Setup */}
             <div className="bg-gradient-to-br from-[#1E3557] to-[#14233a] p-6 md:p-8 rounded-2xl shadow-md text-white relative flex flex-col justify-center">
                
                <div className="relative z-10">
                  <div className="inline-block px-3 py-1 bg-white/10 rounded-full text-[10px] font-bold tracking-wider uppercase mb-3 border border-white/20">
                    Action Required
                  </div>
                  <h3 className="text-xl font-bold mb-2">Complete Your Birth Details</h3>
                  <p className="text-blue-200 text-sm mb-6 leading-relaxed max-w-[90%]">
                    Accurate predictions require precise birth time and location. Set up your kundli profile now.
                  </p>
                  <Link to="/user-profile" className="inline-block bg-[#D4A73C] text-[#1E3557] text-center text-sm font-bold px-6 py-3 rounded-xl hover:bg-[#c49530] transition shadow-lg w-fit">
                     Setup Profile
                  </Link>
                </div>
             </div>
          </div>

          {/* Recent Activity Section */}
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 md:p-8 mt-2">
             <div className="mb-6">
               <h2 className="text-xl font-bold text-[#1E3557]">Recent Activity</h2>
             </div>
             
             <div className="flex flex-col items-center justify-center py-12 px-4 text-center bg-[#f8f9fa] rounded-xl border border-dashed border-gray-200">
                <h4 className="text-gray-800 font-bold mb-1">It's quiet here</h4>
                <p className="text-sm text-gray-500 max-w-sm mb-5">
                  You haven't had any astrological consultations or recent activity on your dashboard.
                </p>
                <Link to="/astrologers" className="bg-white border border-gray-200 text-[#1E3557] text-sm font-semibold px-5 py-2.5 rounded-lg hover:border-[#D4A73C] hover:text-[#D4A73C] transition shadow-sm">
                  Explore Astrologers
                </Link>
             </div>
          </div>

        </main>

      </div>

      <Footer />
    </div>
  );
}
