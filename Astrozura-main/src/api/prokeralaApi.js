import api from "./axios";

export const getDailyHoroscope = async (sign, day = "today", la = "en") => {
  try {
    const response = await api.get(`/prokerala/horoscope/${sign}`, {
      params: { day, la }
    });
    return response.data;
  } catch (error) {
    console.error("Error fetching daily horoscope:", error);
    throw error;
  }
};

export const getWeeklyHoroscope = async (sign) => {
  try {
    const response = await api.get(`/prokerala/horoscope-weekly/${sign}`);
    return response.data;
  } catch (error) {
    console.error("Error fetching weekly horoscope:", error);
    throw error;
  }
};

export const getMonthlyHoroscope = async (sign) => {
  try {
    const response = await api.get(`/prokerala/horoscope-monthly/${sign}`);
    return response.data;
  } catch (error) {
    console.error("Error fetching monthly horoscope:", error);
    throw error;
  }
};

export const generateKundli = async (datetime, coordinates, ayanamsa = 1, options = {}) => {
  try {
    const response = await api.post(`/prokerala/kundli`, {
      datetime,
      coordinates,
      ayanamsa,
      ...options,
    });
    return response.data;
  } catch (error) {
    console.error("Error generating kundli:", error);
    throw error;
  }
};

export const searchLocation = async (query, language = "en") => {
  try {
    const response = await api.get(`/prokerala/location/search`, {
      params: { q: query, language }
    });
    return response.data;
  } catch (error) {
    console.error("Error searching location:", error);
    throw error;
  }
};

export const getMarriageMatching = async (
  girl_coordinates,
  girl_dob,
  boy_coordinates,
  boy_dob,
  options = {}
) => {
  try {
    const response = await api.post(`/prokerala/matching`, {
      girl_coordinates,
      girl_dob,
      boy_coordinates,
      boy_dob,
      ...options,
    });
    return response.data;
  } catch (error) {
    console.error("Error generating marriage matching:", error);
    throw error;
  }
};

export const downloadMatchMakingPdf = async (payload) => {
  try {
    const response = await api.post('/prokerala/matching/pdf', payload, {
      responseType: 'blob',
    });
    return response;
  } catch (error) {
    console.error("Error downloading match-making PDF:", error);
    throw error;
  }
};

export const getPanchang = async (datetime, coordinates, ayanamsa = 1, options = {}) => {
  try {
    const response = await api.post(`/prokerala/panchang`, {
      datetime,
      coordinates,
      ayanamsa,
      ...options,
    });
    return response.data;
  } catch (error) {
    console.error("Error fetching panchang:", error);
    throw error;
  }
};

export const downloadFreeKundliPdf = async (payload) => {
  try {
    const response = await api.post('/prokerala/kundli/free-pdf', payload, {
      responseType: 'blob'
    });
    return response;
  } catch (error) {
    console.error("Error downloading free kundli PDF:", error);
    throw error;
  }
};

export const getDivisionalCharts = async (datetime, coordinates, chartTypeOrTypes, chartStyle = 'north-indian', options = {}) => {
  try {
    const chartPayload = Array.isArray(chartTypeOrTypes)
      ? { chart_types: chartTypeOrTypes }
      : { chart_type: chartTypeOrTypes };

    const response = await api.post('/prokerala/divisional-charts', {
      datetime,
      coordinates,
      ...chartPayload,
      chart_style: chartStyle,
      ...options,
    });
    return response.data;
  } catch (error) {
    console.error("Error fetching divisional charts:", error);
    throw error;
  }
};

export const getPredictions = async (datetime, coordinates, type, options = {}) => {
  try {
    const response = await api.post('/prokerala/predictions', { datetime, coordinates, type, ...options });
    return response.data;
  } catch (error) {
    console.error("Error fetching predictions:", error);
    throw error;
  }
};

export const getNumerologyReport = async (payloadOrDatetime, legacyName = "") => {
  try {
    const payload =
      typeof payloadOrDatetime === "object" && payloadOrDatetime !== null
        ? payloadOrDatetime
        : { datetime: payloadOrDatetime, name: legacyName };

    const response = await api.post('/prokerala/numerology', payload);
    return response.data;
  } catch (error) {
    console.error("Error fetching numerology report:", error);
    throw error;
  }
};

export const getSadesatiReport = async (datetime, coordinates, options = {}) => {
  try {
    const response = await api.post('/prokerala/sadesati', { datetime, coordinates, ...options });
    return response.data;
  } catch (error) {
    console.error("Error fetching sadesati report:", error);
    throw error;
  }
};

export const getLalKitabReport = async (datetime, coordinates, options = {}) => {
  try {
    const response = await api.post('/prokerala/lal-kitab', { datetime, coordinates, ...options });
    return response.data;
  } catch (error) {
    console.error("Error fetching lal kitab report:", error);
    throw error;
  }
};

export const getVedicCalculator = async (calculator, payload) => {
  try {
    const response = await api.post(`/prokerala/vedic-calculators/${calculator}`, payload);
    return response.data;
  } catch (error) {
    console.error(`Error fetching Vedic calculator ${calculator}:`, error);
    throw error;
  }
};

export const getMatchingCalculator = async (calculator, payload) => {
  try {
    const response = await api.post(`/prokerala/matching-calculators/${calculator}`, payload);
    return response.data;
  } catch (error) {
    console.error(`Error fetching matching calculator ${calculator}:`, error);
    throw error;
  }
};

export const getTarotReading = async (payload) => {
  try {
    const response = await api.post('/prokerala/tarot', payload);
    return response.data;
  } catch (error) {
    console.error("Error fetching tarot reading:", error);
    throw error;
  }
};

export const getKundliDetailSection = async (section, payload) => {
  try {
    const response = await api.post(`/prokerala/kundli/detail-section/${section}`, payload);
    return response.data;
  } catch (error) {
    console.error(`Error fetching Kundli detail section ${section}:`, error);
    throw error;
  }
};
