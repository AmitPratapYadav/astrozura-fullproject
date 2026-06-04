import React from "react";
import arrowIcon from "../assets/right-arrow.png";
import  Footer from "../components/Footer";

export default function Contact() {
  return (
    <>
    <div className="bg-[#f8f7f5] min-h-screen py-8 sm:py-12 px-4 sm:px-8 md:px-16">

      {/* Heading */}
      <div className="text-center mb-12">
        <p className="text-sm text-[#1E3557]">Contact Us – Astrozura</p>
        <h1 className="text-3xl md:text-5xl font-semibold text-[#2c2c54] mt-2">
          Get in Touch
        </h1>
        <p className="text-gray-500 mt-3 max-w-xl mx-auto text-sm md:text-base">
          We are always here to help you with your spiritual and shopping needs. If you have any questions regarding our products, orders, delivery, or services, feel free to contact us anytime.
        </p>
      </div>
      {/* Main Section */}
      <div className="grid md:grid-cols-2 gap-10 items-start">
        <div className="bg-white rounded-xl shadow-md p-6">

          <div className="grid md:grid-cols-2 gap-4">
            {/* Name */}
            <div>
              <label className="text-sm text-gray-600">Full Name</label>
              <input
                type="text"
                placeholder="Enter your name"
                className="border p-3 rounded-lg w-full mt-1 focus:outline-none focus:ring-2 focus:ring-[#1E3557]"
              />
            </div>
            {/* Email */}
            <div>
              <label className="text-sm text-gray-600">Email Address</label>
              <input
                type="email"
                placeholder="Enter your email"
                className="border p-3 rounded-lg w-full mt-1 focus:outline-none focus:ring-2 focus:ring-[#1E3557]"/>
            </div>
          </div>

          {/* Phone */}
          <div className="mt-4">
            <label className="text-sm text-gray-600">Phone Number</label>
            <input
              type="text"
              placeholder="Enter your phone number"
              className="border p-3 rounded-lg w-full mt-1 focus:outline-none focus:ring-2 focus:ring-[#1E3557]"
            />
          </div>

          {/* Message */}
          <div className="mt-4">
            <label className="text-sm text-gray-600">
              Need Assistance? (Queries, Feedback, Suggestions)
            </label>
            <textarea
              rows="4"
              placeholder="Write your message..."
              className="border p-3 rounded-lg w-full mt-1 focus:outline-none focus:ring-2 focus:ring-[#1E3557]"
            />
          </div>

          {/* Button */}
          <button
            onClick={() => alert("Message Sent!")}
            className="mt-5 w-full bg-[#1E3557] text-white py-3 rounded-lg flex items-center justify-center gap-2 hover:opacity-90 transition">
            Send Message
            <img src={arrowIcon} alt="arrow" className="w-4" />
          </button>
          <p className="text-xs text-gray-400 mt-3 text-center">
            * Our support team will respond as soon as possible.
          </p>
        </div>
        {/* RIGHT SIDE INFO */}
        <div className="space-y-8 max-w-md mx-auto">
          {/* Heading */}
          <div className="text-center">
            <h2 className="text-xl font-semibold text-[#1E3557]">
              Astrozura
            </h2>
            <div className="w-16 h-[2px] bg-[#1E3557] mx-auto mt-2"></div>
          </div>

          {/* Location */}
          <div className="flex gap-3 items-start">
            <div className="w-5 h-5 mt-1 flex items-center justify-center text-[#c7926a] font-bold text-lg">📍</div>
            <div>
              <p className="font-medium">Address</p>
              <p className="text-gray-500 text-sm">
                India <br />
                <span className="text-xs">(Dummy address, will modify later)</span>
              </p>
            </div>
          </div>

          {/* Phone */}
          <div className="flex gap-3 items-start">
            <div className="w-5 h-5 mt-1 flex items-center justify-center text-[#c7926a] font-bold text-lg">📞</div>
            <div>
              <p className="font-medium">Phone</p>
              <p className="text-gray-500 text-sm">
                +91 98765 43210 <br />
                <span className="text-xs">
                  Mon – Sat: 9:00 AM – 7:00 PM (Sun: Closed)
                </span>
              </p>
            </div>
          </div>

          {/* Email */}
          <div className="flex gap-3 items-start">
            <div className="w-5 h-5 mt-1 flex items-center justify-center text-[#c7926a] font-bold text-lg">✉️</div>
            <div>
              <p className="font-medium">Email</p>
              <p className="text-gray-500 text-sm">
                support@astrozura.com <br />
                <span className="text-xs">
                  Feel free to contact us anytime.
                </span>
              </p>
            </div>
          </div>

          {/* Social */}
          <div className="text-center">
            <p className="font-medium mb-3">Follow Us</p>
            <p className="text-xs text-gray-500 mb-4">
              Stay connected with Astrozura for the latest collections, spiritual products, offers, and updates.
            </p>
            <div className="flex justify-center gap-4">
              {['📸', '📘', '💬'].map(
                (icon, i) => (
                  <div
                    key={i}
                    className="w-9 h-9 flex items-center justify-center bg-white rounded-full shadow cursor-pointer hover:scale-110 transition"
                    title={["Instagram", "Facebook", "WhatsApp"][i]}
                  >
                    {icon}
                  </div>
                )
              )}
            </div>
          </div>

          {/* Quote */}
          <div className="bg-[#f3f0ff] p-5 rounded-xl text-sm text-gray-600 italic text-center shadow-sm">
            “You can also use the contact form available on our website to send your queries, feedback, or suggestions.”
            <p className="mt-3 text-xs">— Astrozura Support</p>
          </div>

        </div>
      </div>
    </div>
    <Footer/>
    </>
  );
}