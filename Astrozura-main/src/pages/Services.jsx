import { Link } from "react-router-dom";
import Navbar from "../components/Navbar";
import Footer from "../components/Footer";
import { groupedServices, serviceCatalog } from "../data/serviceCatalog";
import { getServiceIcon } from "../data/serviceIcons";

const serviceCardThemes = [
  {
    bg: "from-[#FFF4EA] to-[#FFEDE4]",
    orb: "bg-[#FDD2C2]",
    icon: "from-[#FFB05C] to-[#E65D2E]",
    text: "text-[#C2410C]",
    border: "border-[#F7D6BD]",
  },
  {
    bg: "from-[#F1FAE9] to-[#EAF7DF]",
    orb: "bg-[#CDECC1]",
    icon: "from-[#D5B33A] to-[#41983B]",
    text: "text-[#2F7D1C]",
    border: "border-[#D5EBC8]",
  },
  {
    bg: "from-[#EAF7FF] to-[#E8F2FF]",
    orb: "bg-[#C8E6FF]",
    icon: "from-[#58BAFF] to-[#2D65D9]",
    text: "text-[#1D4ED8]",
    border: "border-[#CBE2F7]",
  },
  {
    bg: "from-[#EAFBF8] to-[#E5F7F2]",
    orb: "bg-[#BEEBE4]",
    icon: "from-[#27C3C8] to-[#0A8F8C]",
    text: "text-[#087F7A]",
    border: "border-[#C8EAE4]",
  },
  {
    bg: "from-[#FAECFF] to-[#F5E6FF]",
    orb: "bg-[#E7C8F7]",
    icon: "from-[#C084FC] to-[#7C3AED]",
    text: "text-[#7E22CE]",
    border: "border-[#E8D1F5]",
  },
  {
    bg: "from-[#FFF9D9] to-[#FFF4C2]",
    orb: "bg-[#FFE3A0]",
    icon: "from-[#FFB000] to-[#F97316]",
    text: "text-[#C45A00]",
    border: "border-[#F5DFA3]",
  },
];

const sections = [
  {
    title: "Core Experiences",
    items: [
      {
        title: "Pooja Anusthan",
        summary: "Browse priest-coordinated rituals and book auspicious services.",
        to: "/rituals",
        accent: "from-[#C8842D] to-[#E1B04E]",
        icon: getServiceIcon("pooja-suggestion", "Pooja Suggestion"),
      },
      {
        title: "Matchmaking",
        summary: "Review compatibility, guna scoring, and chart-aligned relationship insights.",
        to: "/matching",
        accent: "from-[#A24563] to-[#D87C93]",
        icon: serviceCatalog.find((service) => service.slug === "kundli-matching")?.icon,
      },
      {
        title: "Detailed Kundali Analysis",
        summary: "Generate and explore premium kundali modules, divisional charts, doshas, and remedies.",
        to: "/services/detailed-kundali",
        accent: "from-[#254F7A] to-[#5A8EC9]",
        icon: serviceCatalog.find((service) => service.slug === "detailed-kundali")?.icon,
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
      icon: serviceCatalog.find((service) => service.ctaTo === item.to || service.title === item.label)?.icon,
    })),
  },
  {
    title: "Reports & Calculators",
    items: serviceCatalog
      .filter((item) => !["palm-reading", "premium-consultations"].includes(item.slug))
      .map((item) => ({
        title: item.title,
        summary: item.summary,
        to: item.ctaTo === "/services" ? `/services/${item.slug}` : `/services/${item.slug}`,
        accent: item.accent,
        icon: item.icon,
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
                {section.items.map((item, index) => {
                  const theme = serviceCardThemes[index % serviceCardThemes.length];

                  return (
                    <Link
                      key={`${section.title}-${item.title}`}
                      to={item.to}
                      className={`group relative min-h-[280px] overflow-hidden rounded-[1.6rem] border ${theme.border} bg-gradient-to-br ${theme.bg} p-6 shadow-sm transition duration-300 hover:-translate-y-1 hover:shadow-xl hover:shadow-black/10`}
                    >
                      <div className={`absolute -right-8 -top-10 h-28 w-28 rounded-full ${theme.orb} opacity-70 transition group-hover:scale-110`} />
                      <div className="relative z-10 flex h-full flex-col">
                        <div className="flex items-start justify-between gap-4">
                          <div className={`flex h-20 w-20 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br ${theme.icon} p-2 shadow-lg shadow-black/10 ring-4 ring-white/80 transition group-hover:scale-[1.04]`}>
                            <div className="flex h-full w-full items-center justify-center rounded-xl bg-white/90 p-2">
                              {item.icon ? (
                                <img src={item.icon} alt="" className="h-full w-full object-contain" />
                              ) : (
                                <span className="text-lg font-black text-[#1E3557]">AZ</span>
                              )}
                            </div>
                          </div>
                          <span className={`rounded-full bg-white/80 px-3 py-1 text-[10px] font-black uppercase tracking-[0.16em] ${theme.text} shadow-sm`}>
                            {section.title}
                          </span>
                        </div>
                        <h3 className="mt-6 text-2xl font-black leading-tight text-[#1E3557]">{item.title}</h3>
                        <p className="mt-3 line-clamp-3 text-sm leading-7 text-slate-600">{item.summary}</p>
                        <div className="mt-auto flex items-center justify-between border-t border-white/70 pt-5 text-sm font-black text-[#1E3557]">
                          <span>Open Service</span>
                          <span className={`flex h-9 w-9 items-center justify-center rounded-full bg-white ${theme.text} shadow-sm transition group-hover:translate-x-1`}>
                            →
                          </span>
                        </div>
                      </div>
                    </Link>
                  );
                })}
              </div>
            </section>
          ))}
        </div>
      </main>

      <Footer />
    </div>
  );
}
