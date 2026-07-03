import { Link, Navigate, useParams } from "react-router-dom";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { getServiceBySlug } from "../data/serviceCatalog";

export default function ServiceDetail() {
  const { slug } = useParams();
  const service = getServiceBySlug(slug || "");

  if (!service) {
    return <Navigate to="/services" replace />;
  }

  return (
    <div className="min-h-screen bg-[#FBF7F0]">
      <Navbar />

      <section className="px-4 py-16 md:px-10">
        <div className={`mx-auto grid max-w-7xl gap-8 overflow-hidden rounded-[2.4rem] bg-gradient-to-r px-8 py-14 text-white shadow-xl md:grid-cols-[1fr_auto] md:items-center ${service.accent}`}>
          <div>
            <p className="text-[11px] font-bold uppercase tracking-[0.22em] opacity-85">{service.category}</p>
            <h1 className="mt-4 max-w-3xl text-4xl font-black leading-tight md:text-6xl">{service.title}</h1>
            <p className="mt-6 max-w-2xl text-sm leading-7 text-white/85 md:text-base">{service.description}</p>
          </div>
          <div className="flex h-32 w-32 items-center justify-center rounded-[2rem] bg-white/95 p-4 shadow-2xl md:h-40 md:w-40">
            {service.icon ? (
              <img src={service.icon} alt="" className="h-full w-full object-contain" />
            ) : (
              <span className="text-4xl font-black text-[#1E3557]">AZ</span>
            )}
          </div>
          <div className="flex flex-wrap gap-4 md:col-span-2">
            <Link
              to={service.ctaTo}
              className="rounded-2xl bg-white px-6 py-3 text-sm font-bold text-[#1E3557] shadow"
            >
              {service.ctaLabel}
            </Link>
            <Link
              to="/services"
              className="rounded-2xl border border-white/30 bg-white/10 px-6 py-3 text-sm font-semibold text-white"
            >
              Back to All Services
            </Link>
          </div>
        </div>
      </section>

      <main className="mx-auto max-w-7xl px-4 pb-16 md:px-10">
        <div className="grid gap-8 lg:grid-cols-[1.15fr_0.85fr]">
          <section className="rounded-[2rem] border border-[#EFE3D1] bg-white p-8 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.22em] text-[#D4A73C]">Service Overview</p>
            <h2 className="mt-3 text-3xl font-black text-[#1E3557]">What this module covers</h2>
            <p className="mt-5 text-sm leading-8 text-gray-600">{service.summary}</p>

            <div className="mt-8 grid gap-4 md:grid-cols-2">
              {[
                "Dedicated entry point in navigation and service directory",
                "Ready for conversion into deeper report or calculator workflows",
                "Linked to the relevant active booking or astrology page",
                "Prepared for astrologer-led interpretation and consultation upsell",
              ].map((item) => (
                <div key={item} className="rounded-2xl bg-[#FBF7F0] px-5 py-4 text-sm font-medium text-[#1E3557]">
                  {item}
                </div>
              ))}
            </div>
          </section>

          <aside className="rounded-[2rem] border border-[#EFE3D1] bg-white p-8 shadow-sm">
            <p className="text-xs font-semibold uppercase tracking-[0.22em] text-[#D4A73C]">Next Action</p>
            <h3 className="mt-3 text-2xl font-black text-[#1E3557]">Continue into the working flow</h3>
            <p className="mt-4 text-sm leading-7 text-gray-600">
              This service page acts as the dedicated landing layer for the module and routes users into the existing
              working experience tied to this service.
            </p>
            <Link
              to={service.ctaTo}
              className="mt-8 inline-flex rounded-2xl bg-[#1E3557] px-6 py-3 text-sm font-bold text-white"
            >
              {service.ctaLabel}
            </Link>
          </aside>
        </div>
      </main>

      <Footer />
    </div>
  );
}
