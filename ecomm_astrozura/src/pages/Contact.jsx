import { Facebook, Instagram, Mail, MapPin, MessageCircle, Phone, Send } from "lucide-react";
import Footer from "../components/Footer";

export default function Contact() {
  return (
    <>
      <main className="min-h-screen bg-[#f8f7f5] px-4 py-10 sm:px-8 md:px-16">
        <div className="mb-12 text-center">
          <p className="text-sm text-[#1E3557]">Contact Us - AstroZura</p>
          <h1 className="mt-2 text-3xl font-semibold text-[#2c2c54] md:text-5xl">Get in Touch</h1>
          <p className="mx-auto mt-3 max-w-xl text-sm text-gray-500 md:text-base">
            We are here to help with products, orders, delivery, consultations, and spiritual services.
          </p>
        </div>

        <div className="mx-auto grid max-w-6xl items-start gap-10 md:grid-cols-2">
          <form className="rounded-xl bg-white p-6 shadow-md" onSubmit={(event) => event.preventDefault()}>
            <div className="grid gap-4 md:grid-cols-2">
              <label className="text-sm text-gray-600">Full Name<input required className="mt-1 w-full rounded-lg border p-3 outline-none focus:ring-2 focus:ring-[#1E3557]" /></label>
              <label className="text-sm text-gray-600">Email Address<input required type="email" className="mt-1 w-full rounded-lg border p-3 outline-none focus:ring-2 focus:ring-[#1E3557]" /></label>
            </div>
            <label className="mt-4 block text-sm text-gray-600">Phone Number<input className="mt-1 w-full rounded-lg border p-3 outline-none focus:ring-2 focus:ring-[#1E3557]" /></label>
            <label className="mt-4 block text-sm text-gray-600">Message<textarea required rows="5" className="mt-1 w-full rounded-lg border p-3 outline-none focus:ring-2 focus:ring-[#1E3557]" /></label>
            <button className="mt-5 flex w-full items-center justify-center gap-2 rounded-lg bg-[#1E3557] py-3 text-white"><Send size={17} /> Send Message</button>
          </form>

          <section className="mx-auto w-full max-w-md space-y-7">
            <div className="text-center"><h2 className="text-xl font-semibold text-[#1E3557]">AstroZura</h2><div className="mx-auto mt-2 h-0.5 w-16 bg-[#1E3557]" /></div>
            <ContactItem icon={MapPin} title="Address">AstroZura Tarsh Astrology Solutions Ujhani 243639 Division Bareilly Uttar Pradesh, India.</ContactItem>
            <ContactItem icon={Phone} title="Phone"><a href="tel:+919548046986">+91 95480 46986</a><br /><span className="text-xs">10 AM to 6 PM (Monday - Saturday)</span></ContactItem>
            <ContactItem icon={Mail} title="Email"><a href="mailto:support@astrozura.com">support@astrozura.com</a></ContactItem>
            <div className="text-center">
              <p className="mb-3 font-medium">Follow Us</p>
              <div className="flex justify-center gap-4">
                <SocialLink href="https://www.instagram.com/astrozura__?utm_source=qr" label="Instagram" icon={Instagram} />
                <SocialLink href="https://www.facebook.com/share/1BE7DqPJb4/?mibextid=wwXIfr" label="Facebook" icon={Facebook} />
                <SocialLink href="https://wa.me/919548046986" label="WhatsApp" icon={MessageCircle} />
              </div>
            </div>
          </section>
        </div>
      </main>
      <Footer />
    </>
  );
}

function ContactItem({ icon: Icon, title, children }) {
  return <div className="flex items-start gap-3"><Icon className="mt-1 h-5 w-5 shrink-0 text-[#c7926a]" /><div><p className="font-medium">{title}</p><div className="text-sm leading-6 text-gray-500">{children}</div></div></div>;
}

function SocialLink({ href, label, icon: Icon }) {
  return <a href={href} target="_blank" rel="noreferrer" aria-label={label} title={label} className="flex h-10 w-10 items-center justify-center rounded-full bg-white text-[#1E3557] shadow transition hover:scale-110"><Icon size={19} /></a>;
}
