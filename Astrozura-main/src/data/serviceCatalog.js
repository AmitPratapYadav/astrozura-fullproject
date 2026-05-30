import { matchingCalculatorTools, vedicCalculatorTools } from "./astrologyTools";

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
    slug: "kundali-report",
    title: "Kundali Report",
    category: "Reports",
    summary: "Expanded kundali reading with divisional chart context, yogas, and predictive layers.",
    description:
      "Use the full kundali module to review graha placements, divisional charts, doshas, yogas, and timing-based observations in one place.",
    ctaLabel: "Open Kundali Report",
    ctaTo: "/kundli",
    accent: "from-[#204A72] to-[#3D78A7]",
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
    summary: "Live Tarot API readings for love, career, finance, and yes/no questions.",
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
    ctaTo: "/astrologers",
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
}));

export const serviceCatalog = [
  ...staticServices,
  ...vedicServiceEntries,
  ...matchingServiceEntries,
];

export const groupedServices = {
  horoscope: [
    { label: "Rashifal", to: "/rashifal" },
  ],
  reports: [
    { label: "Lal Kitab Reports", to: "/services/lal-kitab-report" },
    { label: "Matchmaking Report", to: "/matching" },
    { label: "Kundali Report", to: "/services/kundali-report" },
  ],
  calculators: [
    ...vedicCalculatorTools
      .filter((tool) => !tool.hideFromCalculators)
      .map((tool) => ({
        label: tool.title,
        to: tool.route,
      })),
    { label: "Detailed Numerology", to: "/detailed-numerology" },
    { label: "Tarot Reading", to: "/services/tarot-reading" },
    { label: "Palm Reading", to: "/services/palm-reading" },
  ],
  premium: [
    { label: "Vedic Astrology", to: "/astrologers" },
    { label: "Muhurat Guidance", to: "/panchang" },
    { label: "Lal Kitab", to: "/services/lal-kitab-report" },
    { label: "Palmistry", to: "/services/palm-reading" },
  ],
};

export function getServiceBySlug(slug) {
  return serviceCatalog.find((item) => item.slug === slug) || null;
}
