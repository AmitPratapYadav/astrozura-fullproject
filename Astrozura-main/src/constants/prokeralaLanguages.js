export const LANGUAGE_LABELS = {
  en: "English",
  hi: "Hindi",
  ta: "Tamil",
  te: "Telugu",
  ml: "Malayalam",
  gu: "Gujarati",
  bn: "Bengali",
};

export const LOCALE_BY_LANGUAGE = {
  en: "en-IN",
  hi: "hi-IN",
  ta: "ta-IN",
  te: "te-IN",
  ml: "ml-IN",
  gu: "gu-IN",
  bn: "bn-IN",
};

export const HOROSCOPE_LANGUAGE_OPTIONS = [{ value: "en", label: LANGUAGE_LABELS.en }];

export const KUNDLI_LANGUAGE_OPTIONS = [
  { value: "en", label: LANGUAGE_LABELS.en },
  { value: "hi", label: LANGUAGE_LABELS.hi },
  { value: "ta", label: LANGUAGE_LABELS.ta },
  { value: "te", label: LANGUAGE_LABELS.te },
  { value: "ml", label: LANGUAGE_LABELS.ml },
  { value: "gu", label: LANGUAGE_LABELS.gu },
  { value: "bn", label: LANGUAGE_LABELS.bn },
];

export const MATCHING_LANGUAGE_OPTIONS = [
  { value: "en", label: LANGUAGE_LABELS.en },
  { value: "hi", label: LANGUAGE_LABELS.hi },
  { value: "ta", label: LANGUAGE_LABELS.ta },
  { value: "te", label: LANGUAGE_LABELS.te },
  { value: "ml", label: LANGUAGE_LABELS.ml },
];

export const PANCHANG_LANGUAGE_OPTIONS = [
  { value: "en", label: LANGUAGE_LABELS.en },
  { value: "hi", label: LANGUAGE_LABELS.hi },
  { value: "ta", label: LANGUAGE_LABELS.ta },
  { value: "ml", label: LANGUAGE_LABELS.ml },
];

export const getLanguageLabel = (code) => LANGUAGE_LABELS[code] || LANGUAGE_LABELS.en;
export const getLocaleForLanguage = (code) => LOCALE_BY_LANGUAGE[code] || LOCALE_BY_LANGUAGE.en;
