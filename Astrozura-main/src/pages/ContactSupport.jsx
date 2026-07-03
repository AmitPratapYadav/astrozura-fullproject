import { useState } from "react";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import lamp from "../assets/lamp.png";

export default function ContactSupport() {
  const [message, setMessage] = useState("");

  const handleSubmit = (event) => {
    event.preventDefault();
    setMessage("Your inquiry has been submitted. Our team will get back to you shortly.");
    window.setTimeout(() => setMessage(""), 3000);
  };

  return (
    <div className="min-h-screen bg-[#faf8f3] text-[#1E3557]">
      <Navbar />

      <section className="bg-[#13294b] text-white">
        <div className="max-w-7xl mx-auto px-4 md:px-8 py-12 grid gap-8 lg:grid-cols-2 items-center">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[#D4A73C]">Help Center</p>
            <h1 className="mt-4 text-4xl md:text-5xl font-black">Contact Support</h1>
            <p className="mt-5 max-w-xl text-sm md:text-base leading-7 text-slate-200">
              Our dedicated Vedic consultants are here to guide you whether you have questions about rituals, bookings, or spiritual advice.
            </p>
          </div>
          <img src={lamp} alt="Support" className="h-[280px] w-full rounded-[28px] object-cover" />
        </div>
      </section>

      <section className="max-w-7xl mx-auto px-4 md:px-8 py-12">
        {message && <div className="mb-6 rounded-2xl bg-white p-4 shadow-sm text-sm">{message}</div>}

        <div className="grid gap-8 xl:grid-cols-[1.1fr_0.9fr]">
          <div className="rounded-3xl bg-white p-6 shadow-sm border border-[#efe4d2]">
            <h2 className="text-2xl font-bold">Send an Inquiry</h2>
            <form onSubmit={handleSubmit} className="mt-6 grid gap-4 md:grid-cols-2">
              <input className="rounded-2xl border px-4 py-3 outline-none focus:border-[#D4A73C]" placeholder="Full Name" />
              <input className="rounded-2xl border px-4 py-3 outline-none focus:border-[#D4A73C]" placeholder="Email Address" />
              <input className="rounded-2xl border px-4 py-3 outline-none focus:border-[#D4A73C]" placeholder="Subject" />
              <input className="rounded-2xl border px-4 py-3 outline-none focus:border-[#D4A73C]" placeholder="Booking ID (optional)" />
              <textarea className="md:col-span-2 rounded-2xl border px-4 py-3 outline-none focus:border-[#D4A73C]" rows="6" placeholder="Describe your support request" />
              <button type="submit" className="md:col-span-2 rounded-2xl bg-[#D4A73C] px-5 py-3 text-sm font-bold text-[#1E3557]">Submit Inquiry</button>
            </form>
          </div>

          <div className="space-y-6">
            <div className="rounded-3xl bg-white p-6 shadow-sm border border-[#efe4d2]">
              <h2 className="text-2xl font-bold">Office Location</h2>
              <p className="mt-4 text-sm leading-6 text-gray-600">
                Visit us in person for ritual coordination and administrative support.
              </p>
              <div className="mt-5 rounded-2xl bg-[#fffaf0] p-4 text-sm text-gray-600">
                <p className="font-semibold text-[#1E3557]">Astro Zura Support Desk</p>
                <p className="mt-2">AstroZura Tarsh Astrology Solutions Ujhani 243639 Division Bareilly Uttar Pradesh, India.</p>
                <p className="mt-1">Email: support@astrozura.com</p>
                <p className="mt-1">Call: +91 95480 46986</p>
              </div>
            </div>

            <div className="rounded-3xl bg-white p-6 shadow-sm border border-[#efe4d2]">
              <h2 className="text-2xl font-bold">Support Hours</h2>
              <div className="mt-5 space-y-3 text-sm text-gray-600">
                <div className="flex justify-between gap-4"><span>Monday - Saturday</span><span>10:00 AM - 06:00 PM</span></div>
                <div className="flex justify-between gap-4"><span>Sunday</span><span>Closed</span></div>
              </div>
            </div>
          </div>
        </div>

        <section className="mt-12 rounded-[32px] bg-[#13294b] px-6 py-10 text-white flex flex-col md:flex-row items-center justify-between gap-4">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[#D4A73C]">Priority Helpline</p>
            <h2 className="mt-2 text-3xl font-black">Have an Urgent Need?</h2>
            <p className="mt-3 text-sm text-slate-200">For time-sensitive ritual arrangements, call our priority line.</p>
          </div>
          <a href="tel:+919548046986" className="rounded-xl bg-[#D4A73C] px-5 py-3 text-sm font-bold text-[#1E3557]">Call Now</a>
        </section>
      </section>

      <Footer />
    </div>
  );
}
