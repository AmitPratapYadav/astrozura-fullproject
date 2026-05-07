import api from "./axios";

export const getBookingAvailability = async (params) => {
  const response = await api.get("/bookings/availability", { params });
  return response.data;
};

export const createBooking = async (payload) => {
  const response = await api.post("/bookings", payload);
  return response.data;
};

export const createRitualBooking = async (ritualId, payload) => {
  const response = await api.post(`/rituals/${ritualId}/book`, payload);
  return response.data;
};

export const getMyBookings = async () => {
  const response = await api.get("/my-bookings");
  return response.data;
};

export const getMyRitualBookings = async () => {
  const response = await api.get("/my-ritual-bookings");
  return response.data;
};

export const getAstrologerBookings = async () => {
  const response = await api.get("/astrologer/bookings");
  return response.data;
};

export const markBookingCompleted = async (bookingId) => {
  const response = await api.post(`/astrologer/bookings/${bookingId}/complete`);
  return response.data;
};

export const submitBookingReview = async (bookingId, payload) => {
  const response = await api.post(`/bookings/${bookingId}/review`, payload);
  return response.data;
};
