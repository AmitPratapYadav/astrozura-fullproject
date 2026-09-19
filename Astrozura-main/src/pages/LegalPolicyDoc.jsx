import Navbar from "../components/Navbar";
import Footer from "../components/Footer";

export default function PrivacyPolicy() {
  return (
    <div className="min-h-screen bg-[#faf8f3] text-[#1E3557]">
      <Navbar />
      <section className="bg-[#13294b] py-16 text-white text-center">
        <div className="max-w-4xl mx-auto px-4">
          <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[#D4A73C]">Policy Overview</p>
          <h1 className="mt-4 text-4xl font-black">Privacy Policy</h1>
          <p className="mt-4 text-sm leading-6 text-slate-200">
            Your trust matters to us. This policy explains how Astro Zura collects, stores, and uses personal information across astrology, ritual, and ecommerce services.
          </p>
        </div>
      </section>

      <section className="max-w-5xl mx-auto px-4 md:px-8 py-12 space-y-8">
        {[
          ["Information We Collect", "We collect profile details, contact details, birth information, booking preferences, and order data required to deliver consultations, rituals, and purchases."],
          ["How We Use Data", "Your information is used for service delivery, order updates, account security, personalized astrological reports, and support communication."],
          ["Cookies & Tracking", "We may use basic analytics, session storage, and preference cookies to improve user experience and retain login/session context."],
          ["Astrology & Ritual Data Imports", "Birth details, coordinates, and ritual preferences are processed only to generate requested astrological calculations or coordinate related services."],
          ["Sharing & Third Parties", "We only share data when required for payment processing, priest coordination, verified delivery operations, or legal compliance."],
          ["Data Security", "Access controls, server-side validation, and managed infrastructure are used to protect stored personal information."],
          ["Your Rights", "You may request correction of your personal details, update your account profile, or contact support for data-related concerns."],
          ["Data Retention", "We retain essential records for service continuity, support handling, and compliance, and we minimize storage where no longer needed."],
        ].map(([title, text], index) => (
          <div key={title} className="rounded-3xl bg-white p-6 shadow-sm border border-[#efe4d2]">
            <p className="text-sm font-semibold text-[#D4A73C]">Section {index + 1}</p>
            <h2 className="mt-2 text-2xl font-bold">{title}</h2>
            <p className="mt-4 text-sm leading-7 text-gray-600">{text}</p>
          </div>
        ))}

        <div className="rounded-3xl bg-[#13294b] p-6 text-white">
          <h2 className="text-2xl font-bold">Contact for Privacy Questions</h2>
          <p className="mt-3 text-sm leading-6 text-slate-200">
            For privacy-related concerns, please contact our support team at help@astrozura.com or use the contact support page.
          </p>
        </div>
      </section>
      <Footer />
    </div>
  );
}
