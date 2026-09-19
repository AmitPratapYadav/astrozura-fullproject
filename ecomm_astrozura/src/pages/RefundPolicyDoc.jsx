import React from "react";
import { useNavigate } from "react-router-dom"; 
import verified from "../assets/verified.png";
import close from "../assets/close.png";
import exchange from "../assets/exchange.png";
import refund from "../assets/i2.png";
import undo from "../assets/undo (1).png";
import question from "../assets/question.png";
import gmail from "../assets/gmail.png";
import Footer from "../components/Footer";
const PolicyCard = ({ icon, title, children }) => {
  return (
    <div className="bg-white shadow-md rounded-xl p-5 flex gap-4 items-start hover:shadow-lg transition">
      <img src={icon} alt="" className="w-6 h-6 mt-1" />
      <div>
        <h3 className="font-semibold text-[#1E3557] mb-2">{title}</h3>
        <ul className="text-[#1E3557] text-sm space-y-1">{children}</ul>
      </div>
    </div>
  );
};
const RefundPolicy = () => {

  const navigate = useNavigate(); 

  const handleContactClick = () => {
    navigate("/contact");           
    window.scrollTo(0, 0);          
  };

  return (
    <>
      <div className="bg-[#f9f9f8] min-h-screen py-10 px-4">
        <div className="max-w-4xl mx-auto">

          {/* Heading */}
          <div className="text-center mb-10">
            <h1 className="text-2xl md:text-3xl font-bold text-gray-800">
              Refund & Exchange Policy
            </h1>
            <p className="text-[#1E3557] mt-2 text-sm md:text-base">
              We want you to have a smooth and satisfying experience with Astrozura.
              Our policy is designed to be fair and transparent.
            </p>
            <div className="w-16 h-1 bg-[#d8b14a] mx-auto mt-3 rounded"></div>
          </div>

          <div className="space-y-5">
            <PolicyCard icon={verified} title="Eligibility for Refund">
              <li>• Products must be unused and in original packaging.</li>
              <li>• Requests must be submitted within 7 days of delivery.</li>
            </PolicyCard>

            <PolicyCard icon={close} title="Non-Refundable Items">
              <li>• Personalized / custom products made for you.</li>
              <li>• Items showing signs of use or damage.</li>
            </PolicyCard>

            <PolicyCard icon={exchange} title="Exchange Policy">
              <li>• Exchanges allowed only for defective or wrong items.</li>
              <li>• Request must be made within 7 days.</li>
            </PolicyCard>

            <PolicyCard icon={refund} title="Refund Process">
              <li>• Refunds processed within 5-7 business days.</li>
              <li>• Amount credited to original payment method.</li>
            </PolicyCard>

            <PolicyCard icon={undo} title="Return Shipping">
              <li>
                • Customers may bear shipping charges unless item is defective or incorrect.
              </li>
            </PolicyCard>

            <div className="bg-white shadow-md rounded-xl p-5 flex flex-col md:flex-row md:items-center justify-between gap-4">
              
              <div className="flex gap-4 items-start">
                <img src={question} alt="" className="w-6 h-6 mt-1" />
                <div>
                  <h3 className="font-semibold text-[#1E3557]">
                    Need Further Assistance?
                  </h3>
                  <p className="text-sm text-[#1E3557] flex items-center gap-2 mt-1">
                    <img src={gmail} alt="" className="w-4 h-4" />
                    <a
                      href="mailto:support@astrozura.com"
                      className="text-[#1E3557] hover:underline">
                      support@astrozura.com
                    </a>
                  </p>
                </div>
              </div>

              <button
                onClick={handleContactClick}
                className="w-full md:w-auto bg-[#1E3557] text-white px-5 py-2 rounded-full hover:bg-[#1E3557] transition">
                Contact Support
              </button>
            </div>
          </div>
        </div>
      </div>
      <Footer />
    </>
  );
};
export default RefundPolicy;