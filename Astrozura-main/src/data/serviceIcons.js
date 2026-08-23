import ashtakavargaIcon from "../assets/service-icons/new-ashtakavarga-sarvashta-varga.png";
import biorhythmIcon from "../assets/service-icons/new-biorhythm.png";
import charDashaIcon from "../assets/service-icons/new-char-dasha.png";
import dailyNakshatraIcon from "../assets/service-icons/new-daily-nakshatra-predictions.png";
import detailedNumerologyIcon from "../assets/service-icons/new-detailed-numerology.png";
import gemstoneIcon from "../assets/service-icons/new-gemstone-suggestion.png";
import kaalsarpIcon from "../assets/service-icons/new-kal-sarp-dosha.png";
import kpIcon from "../assets/service-icons/new-krishnamurti-paddhati.png";
import mangalIcon from "../assets/service-icons/new-mangal-dosha.png";
import palmIcon from "../assets/service-icons/palm-reading.png";
import pitraIcon from "../assets/service-icons/new-pitra-dosha.png";
import pujaIcon from "../assets/service-icons/new-pooja-suggestion.png";
import rudrakshaIcon from "../assets/service-icons/new-rudraksha-suggestion.png";
import sadeSatiIcon from "../assets/service-icons/new-sade-sati.png";
import tarotIcon from "../assets/service-icons/new-tarot-reading.png";
import varshaphalIcon from "../assets/service-icons/new-varshaphal.png";
import vimshottariIcon from "../assets/service-icons/new-vimshottari-dasha.png";
import yoginiIcon from "../assets/service-icons/new-yogini-dasha.png";
import reportDailyNakshatraIcon from "../assets/service-icons/new-daily-nakshatra-predictions.png";
import reportDoshaIcon from "../assets/service-icons/new-detailed-dosha-analysis.png";
import reportKundaliIcon from "../assets/service-icons/new-detailed-kundali-analysis.png";
import reportMatchmakingIcon from "../assets/service-icons/new-match-making.png";
import lalKitabIcon from "../assets/service-icons/new-lal-kitab.png";
import premiumMatchmakingIcon from "../assets/service-icons/new-match-making.png";

export const serviceIconMap = {
  "ashtakavarga-and-sarvashta-varga-chart": ashtakavargaIcon,
  "sarvashtakavarga": ashtakavargaIcon,
  "sarvashtakavarga-chart": ashtakavargaIcon,
  "biorhythm": biorhythmIcon,
  "char-dasha": charDashaIcon,
  "daily-nakshatra-predictions": dailyNakshatraIcon,
  "report-daily-nakshatra-predictions": reportDailyNakshatraIcon,
  "detailed-numerology": detailedNumerologyIcon,
  "detailed-numerology-report": detailedNumerologyIcon,
  "gemstone-suggestion": gemstoneIcon,
  "basic-gem-suggestion": gemstoneIcon,
  "kaal-sarp-dosha": kaalsarpIcon,
  "kaalsarp-dosha": kaalsarpIcon,
  "krishnamurti-paddhati": kpIcon,
  "kp": kpIcon,
  "mangal-dosha": mangalIcon,
  "palm-reading": palmIcon,
  "pitra-dosha": pitraIcon,
  "puja-suggestion": pujaIcon,
  "rudraksha-suggestion": rudrakshaIcon,
  "sade-sati": sadeSatiIcon,
  "tarot-reading": tarotIcon,
  "varshaphal": varshaphalIcon,
  "vimshottari-dasha": vimshottariIcon,
  "yogini-dasha": yoginiIcon,
  "detailed-dosha": reportDoshaIcon,
  "detailed-dosha-analysis": reportDoshaIcon,
  "detailed-kundali": reportKundaliIcon,
  "detailed-kundali-analysis": reportKundaliIcon,
  "detailed-matchmaking": reportMatchmakingIcon,
  "detailed-matchmaking-report": reportMatchmakingIcon,
  "lal-kitab-report": lalKitabIcon,
  "lal-kitab-reports": lalKitabIcon,
  "lal-kitab-reportsreading": lalKitabIcon,
  "premium-matchmaking-report": premiumMatchmakingIcon,
  "kundli-matching": premiumMatchmakingIcon,
  "matchmaking-report": premiumMatchmakingIcon,
};

const slugify = (value = "") =>
  String(value)
    .toLowerCase()
    .replace(/&/g, "and")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");

export function getServiceIcon(...candidates) {
  for (const candidate of candidates) {
    if (!candidate) continue;
    const direct = serviceIconMap[candidate];
    if (direct) return direct;
    const normalized = slugify(candidate);
    if (serviceIconMap[normalized]) return serviceIconMap[normalized];
  }

  return null;
}
