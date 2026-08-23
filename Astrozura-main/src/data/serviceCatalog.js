import { matchingCalculatorTools, vedicCalculatorTools } from "./astrologyTools";
import { getServiceIcon } from "./serviceIcons";

const staticServices = [
  {
    slug: "lal-kitab-report",
    title: "Lal Kitab Reports",
    category: "Reports",
    summary: "Actionable remedial guidance based on Lal Kitab principles and chart-derived observations.",
    description:
      "Review planetary imbalances, remedial suggestions, and practical spiritual actions with a Lal Kitab oriented consultation flow.",
    ctaLabel: "Open Service",
    ctaTo: "/services/lal-kitab-report",
    accent: "from-[#8C3B3B] to-[#C86B3C]",
  },
  {
    slug: "detailed-kundali",
    title: "Detailed Kundali Analysis",
    category: "Reports",
    summary: "A Premium digital dossier modeled after the 145+ page manual report. Includes extensive planet-house readings, divisional charts, dasha details, and remedies.",
    description:
      "A Premium digital dossier modeled after the 145+ page manual report. Includes extensive planet-house readings, divisional charts, dasha details, and remedies.",
    ctaLabel: "Open Premium Kundali",
    ctaTo: "/services/detailed-kundali",
    accent: "from-[#1E3C72] to-[#2A5298]",
  },
  {
    slug: "detailed-dosha",
    title: "Detailed Dosha Analysis",
    category: "Reports",
    summary: "In-depth checks for Manglik, Kaalsarpa, Pitra doshas, and Sade Sati periods.",
    description:
      "Explore major astrological doshas, exceptions, cancellations, and personalized Vedic remedies to bring balance and peace.",
    ctaLabel: "Open Dosha Report",
    ctaTo: "/services/detailed-dosha",
    accent: "from-[#B05B35] to-[#D4A373]",
  },
  {
    slug: "detailed-matchmaking",
    title: "Detailed Matchmaking Report",
    category: "Reports",
    summary: "Deep marital compatibility report going beyond 36-point Guna Milan to analyze personality, emotional bond, chemistry, and Manglik cancels.",
    description:
      "Vedic relationship analysis looking into 10+ crucial factors: romantic chemistry, mental wavelength, health prospects, future dasha alignment, and couple remedies.",
    ctaLabel: "Open Matchmaking Report",
    ctaTo: "/services/detailed-matchmaking",
    accent: "from-[#8E2DE2] to-[#4A00E0]",
  },
  {
    slug: "detailed-numerology",
    title: "Detailed Numerology",
    category: "Calculators",
    summary: "Numerology insights for destiny number, life path, strengths, and alignment patterns.",
    description:
      "Generate numerology-based interpretations using your birth details and name inputs, then connect with an astrologer for guided explanation.",
    ctaLabel: "Open Detailed Numerology",
    ctaTo: "/detailed-numerology",
    accent: "from-[#3A2A78] to-[#6E55C7]",
  },
  {
    slug: "tarot-reading",
    title: "Tarot Reading",
    category: "Calculators",
    summary: "Tarot readings for love, career, finance, and yes/no questions.",
    description:
      "Use the active tarot reading workflow for card-based predictions, then continue to an astrologer consultation when deeper interpretation is needed.",
    ctaLabel: "Open Tarot Reading",
    ctaTo: "/services/tarot-reading",
    accent: "from-[#5F3150] to-[#B56D8C]",
  },
  {
    slug: "palm-reading",
    title: "Palm Reading",
    category: "Calculators",
    summary: "Dedicated palm reading entry point for consultations and future image-assisted analysis.",
    description:
      "This page routes users into the palm reading service path and is ready for chat image uploads and astrologer-side interpretation support.",
    ctaLabel: "Book Palm Reading",
    ctaTo: "/astrologers?specialty=palm-reading&type=chat",
    accent: "from-[#6B4E2E] to-[#D49B53]",
  },
  {
    slug: "premium-consultations",
    title: "Premium Services",
    category: "Services",
    summary: "One place to explore all premium spiritual consultations, reports, and ritual assistance.",
    description:
      "Browse premium astrology services, ritual experiences, calculator-based tools, and expert consultation entry points curated for Astro Zura.",
    ctaLabel: "View All Services",
    ctaTo: "/services",
    accent: "from-[#1E3557] to-[#486B9D]",
  },
];

const vedicServiceEntries = vedicCalculatorTools.map((tool) => ({
  slug: tool.slug,
  title: tool.title,
  category: tool.category || "Calculators",
  summary: tool.summary,
  description: tool.description,
  ctaLabel: tool.externalFlow ? "Open Calculator" : "Run Calculator",
  ctaTo: tool.route,
  accent: tool.accent,
  icon: getServiceIcon(tool.key, tool.slug, tool.title),
}));

const matchingServiceEntries = matchingCalculatorTools.map((tool) => ({
  slug: tool.slug,
  title: tool.title,
  category: "Marriage Matching",
  summary: tool.summary,
  description: tool.description,
  ctaLabel: tool.externalFlow ? "Open Matching Flow" : "Run Matching Tool",
  ctaTo: tool.route,
  accent: tool.accent,
  icon: getServiceIcon(tool.key, tool.slug, tool.title),
}));

export const serviceCatalog = [
  ...staticServices.map((service) => ({
    ...service,
    icon: getServiceIcon(service.slug, service.title),
  })),
  ...vedicServiceEntries,
  ...matchingServiceEntries,
];

export const groupedServices = {
  horoscope: [
    { label: "Rashifal", to: "/rashifal" },
  ],
  reports: [
    { label: "Lal Kitab Reports", to: "/services/lal-kitab-report", icon: getServiceIcon("lal-kitab-report", "Lal Kitab Reports") },
    { label: "Detailed Dosha Analysis", to: "/services/detailed-dosha", icon: getServiceIcon("detailed-dosha", "Detailed Dosha Analysis") },
  ],
  calculators: [
    ...vedicCalculatorTools
      .filter((tool) => !tool.hideFromCalculators)
      .map((tool) => ({
        label: tool.title,
        to: tool.route,
        icon: getServiceIcon(tool.key, tool.slug, tool.title),
      })),
  ],
  premium: [
    { label: "Vedic Astrology", to: "/astrologers" },
    { label: "Muhurat Guidance", to: "/panchang" },
    { label: "Lal Kitab", to: "/services/lal-kitab-report" },
  ],
};

export function getServiceBySlug(slug) {
  return serviceCatalog.find((item) => item.slug === slug) || null;
}
