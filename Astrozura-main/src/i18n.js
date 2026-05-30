import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';

import translationEN from './locales/en.json';
import translationHI from './locales/hi.json';

const enOverrides = {
  navMenu: {
    poojaAnusthan: "Pooja Anusthan",
    astroZuraPanchang: "Astro Zura Panchang",
    horoscope: "Horoscope",
    reports: "Reports",
    calculators: "Calculators",
    premiumPlans: "Premium Plans",
    userGreeting: "Hi!",
    memberTier: "Free Member",
    horoscopeItems: {
      today: "Today's Horoscope",
      tomorrow: "Tomorrow's Horoscope",
      yesterday: "Yesterday's Horoscope",
    },
    reportItems: {
      lalKitab: "Lal Kitab Reports",
      kundliMatching: "Matchmaking Report",
      nakshatraPorutham: "Nakshatra Porutham",
      thirumanaPorutham: "Thirumana Porutham",
      porutham: "Porutham",
      papasamyam: "Papasamyam Check",
      detailedKundali: "Kundali Report",
    },
    calculatorItems: {
      numerology: "Detailed Numerology",
      tarotReading: "Tarot Reading",
      palmReading: "Palm Reading",
    },
  },
};

const hiOverrides = {
  nav: {
    home: "होम",
    panchang: "एस्ट्रो ज़ुरा पंचांग",
    kundli: "जन्म कुंडली",
    rashifal: "राशिफल",
    matching: "मिलान",
    astrologers: "हमारे ज्योतिषी",
    subscription: "प्रीमियम प्लान",
    login: "लॉग इन",
    dashboard: "डैशबोर्ड",
    profile: "प्रोफ़ाइल",
    logout: "लॉगआउट",
  },
  navMenu: {
    poojaAnusthan: "पूजा अनुष्ठान",
    astroZuraPanchang: "एस्ट्रो ज़ुरा पंचांग",
    horoscope: "राशिफल",
    reports: "रिपोर्ट्स",
    calculators: "कैलकुलेटर्स",
    premiumPlans: "प्रीमियम प्लान",
    userGreeting: "नमस्ते!",
    memberTier: "फ्री मेंबर",
    horoscopeItems: {
      today: "आज का राशिफल",
      tomorrow: "कल का राशिफल",
      yesterday: "बीते दिन का राशिफल",
    },
    reportItems: {
      lalKitab: "लाल किताब रिपोर्ट",
      kundliMatching: "मैचमेकिंग रिपोर्ट",
      nakshatraPorutham: "नक्षत्र पोरुथम",
      thirumanaPorutham: "थिरुमना पोरुथम",
      porutham: "पोरुथम",
      papasamyam: "पापसाम्यम जांच",
      detailedKundali: "कुंडली रिपोर्ट",
    },
    calculatorItems: {
      numerology: "विस्तृत अंक ज्योतिष",
      tarotReading: "टैरो रीडिंग",
      palmReading: "हस्तरेखा",
    },
  },
};

const resources = {
  en: {
    translation: {
      ...translationEN,
      ...enOverrides,
    }
  },
  hi: {
    translation: {
      ...translationHI,
      ...hiOverrides,
    }
  }
};

i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources,
    supportedLngs: ['en', 'hi'],
    fallbackLng: 'en',
    load: 'languageOnly',
    detection: {
      order: ['localStorage', 'navigator'],
      caches: ['localStorage'],
    },
    interpolation: {
      escapeValue: false 
    }
  });

export default i18n;
