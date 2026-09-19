import infoIcon from "../assets/information.png";
import fileIcon from "../assets/file.png";
import settingsIcon from "../assets/settings.png";
import cookieIcon from "../assets/cookie.png";
import insuranceIcon from "../assets/insurance.png";
import shareIcon from "../assets/share.png";
import userIcon from "../assets/user.png";
import emailIcon from "../assets/emailicon.png";
import globalIcon from "../assets/global.png";
import Footer from "../components/Footer";
export default function PrivacyPolicy() {
  return (
    <>
    <div className="bg-[#f6f7fb] py-10 px-4 flex justify-center">
      <div className="w-full max-w-[900px]">
        {/* HEADER */}
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-[#1E3557]">
            Privacy Policy
          </h1>
          <p className="text-[#1E3557] text-sm mt-2 max-w-[600px] mx-auto">
            At GuardianLane, we take your privacy seriously. This policy explains how we collect, use, and protect your personal data when you use our services.
          </p>
        </div>
        {/* CARD COMPONENT */}
        {[
          {
            icon: infoIcon,
            title: "Introduction",
            content:"Welcome to GuardianLane. We are committed to protecting your personal information and your right to privacy."
          },
          {
            icon: fileIcon,
            title: "Information We Collect",
            content: "Personal identifiers, usage data, billing information, and communications you provide."
          },
          {
            icon: settingsIcon,
            title: "How We Use Your Information",
            content: "We use your data to provide services, improve user experience, and ensure security."
          },
          {
            icon: cookieIcon,
            title: "Cookies Policy",
            content: "We use cookies to enhance browsing experience and analyze traffic."
          },
          {
            icon: insuranceIcon,
            title: "Data Protection",
            content: "We implement strong security measures including encryption and monitoring."
          },
          {
            icon: shareIcon,
            title: "Third-Party Services",
            content: "We may share data with trusted partners for payment and analytics."
          },
          {
            icon: userIcon,
            title: "User Rights",
            content:  "You can access, update, or delete your personal information anytime."
          }
        ].map((item, index) => (
          <div key={index}
            className="bg-white p-5 rounded-xl border border-gray-200 mb-5 shadow-sm">
            <div className="flex items-center gap-3 mb-2">
              <img src={item.icon} className="w-5 h-5" alt="" />
              <h2 className="font-semibold text-[#1E3557]">
                {item.title}
              </h2>
            </div>
            <p className="text- text-sm leading-relaxed">
              {item.content}
            </p>
          </div>
        ))}
  
        {/* CONTACT SECTION */}
        <div className="bg-[#eef0ff] p-5 rounded-xl border border-[#d6d9ff]">
          <h2 className="font-semibold text-[#1E3557] mb-4">
            Contact Information
          </h2>

          <div className="flex items-center gap-3 mb-3">
            <img src={emailIcon} className="w-5 h-5" alt="" />
            <p className="text-sm text-[#1E3557]">
              support@guardianlane.io
            </p>
          </div>

          <div className="flex items-center gap-3">
            <img src={globalIcon} className="w-5 h-5" alt="" />
            <p className="text-sm text-[#1E3557]">
              123 Legal Plaza, San Francisco, CA
            </p>
          </div>
        </div>
      </div>
    </div>
    <Footer/>
    </>
  );
}