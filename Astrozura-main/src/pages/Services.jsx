import { Link } from "react-router-dom";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { groupedServices, serviceCatalog } from "../data/serviceCatalog";

const sections = [
  {
    title: "Core Experiences",
    items: [
      {
        title: "Pooja Anusthan",
        summary: "Browse priest-coordinated rituals and book auspicious services.",
        to: "/rituals",
        accent: "from-[#C8842D] to-[#E1B04E]",
      },
      {
        title: "Matchmaking",
        summary: "Review compatibility, guna scoring, and chart-aligned relationship insights.",
        to: "/matching",
        accent: "from-[#A24563] to-[#D87C93]",
      },
      {
        title: "Kundali Report",
        summary: "Generate and explore your kundali, divisional charts, and chart-based insights.",
        to: "/services/kundali-report",
        accent: "from-[#254F7A] to-[#5A8EC9]",
      },
    ],
  },
  {
    title: "Premium Services",
    items: groupedServices.premium.map((item, index) => ({
      title: item.label,
      summary: "Dedicated service entry point with guided action and linked working flow.",
      to: item.to,
      accent: [
        "from-[#1E3557] to-[#486B9D]",
        "from-[#4B5D1E] to-[#7C9832]",
        "from-[#7A3425] to-[#BA7042]",
        "from-[#5C3A6E] to-[#9E6AC0]",
      ][index],
    })),
  },
  {
    title: "Reports & Calculators",
    items: serviceCatalog.map((item) => ({
      title: item.title,
      summary: item.summary,
      to: item.ctaTo === "/services" ? `/services/${item.slug}` : `/services/${item.slug}`,
      accent: item.accent,
    })),
  },
];

export default function Services() {
  return (
    <div className="min-h-screen bg-[#FBF7F0]">
      <Navbar />

      <section className="bg-[#1E3557] px-4 py-20 text-white md:px-10">
        <div className="mx-auto max-w-7xl">
          <span className="rounded-full border border-white/20 bg-white/10 px-4 py-1.5 text-[11px] font-bold uppercase tracking-[0.22em]">
            Astro Zura Services
          </span>
          <h1 className="mt-6 max-w-3xl text-4xl font-black leading-tight md:text-6xl">
            Explore Reports, Rituals, Consultations, and Spiritual Tools
          </h1>
          <p className="mt-6 max-w-2xl text-sm leading-7 text-slate-200 md:text-base">
            Every major Astro Zura service now has a dedicated entry point. Use this hub to browse rituals,
            matchmaking, horoscope flows, premium services, and specialist calculators.
          </p>
        </div>
      </section>

      <main className="mx-auto max-w-7xl px-4 py-12 md:px-10">
        <div className="space-y-12">
          {sections.map((section) => (
            <section key={section.title}>
              <div className="mb-6 flex items-center gap-4">
                <div className="h-10 w-1 rounded-full bg-[#D4A73C]" />
                <div>
                  <p className="text-xs font-semibold uppercase tracking-[0.22em] text-[#D4A73C]">Service Collection</p>
                  <h2 className="text-3xl font-black text-[#1E3557]">{section.title}</h2>
                </div>
              </div>

              <div className="grid gap-6 md:grid-cols-2 xl:grid-cols-3">
                {section.items.map((item) => (
                  <Link
                    key={`${section.title}-${item.title}`}
                    to={item.to}
                    className="group rounded-[2rem] border border-[#EFE3D1] bg-white p-7 shadow-sm transition hover:-translate-y-1.5 hover:shadow-xl"
                  >
                    <div className={`inline-flex rounded-2xl bg-gradient-to-r px-4 py-2 text-[11px] font-bold uppercase tracking-[0.18em] text-white ${item.accent}`}>
                      {section.title}
                    </div>
                    <h3 className="mt-6 text-2xl font-black text-[#1E3557]">{item.title}</h3>
                    <p className="mt-4 text-sm leading-7 text-gray-600">{item.summary}</p>
                    <div className="mt-8 flex items-center justify-between border-t border-gray-100 pt-5 text-sm font-semibold text-[#1E3557]">
                      <span>Open Service</span>
                      <span className="text-[#D4A73C] transition group-hover:translate-x-1">Go</span>
                    </div>
                  </Link>
                ))}
              </div>
            </section>
          ))}
        </div>
      </main>

      <Footer />
    </div>
  );
}
