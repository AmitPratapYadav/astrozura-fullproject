import api from "./axios";

export const getBookingSession = async (bookingId) => {
  const response = await api.get(`/bookings/${bookingId}/session`);
  return response.data;
};

export const startBookingSession = async (bookingId) => {
  const response = await api.post(`/bookings/${bookingId}/session/start`);
  return response.data;
};

export const endBookingSession = async (bookingId) => {
  const response = await api.post(`/bookings/${bookingId}/session/end`);
  return response.data;
};

export const pingBookingSession = async (bookingId) => {
  const response = await api.post(`/bookings/${bookingId}/session/ping`);
  return response.data;
};

export const extendBookingSession = async (bookingId, payload) => {
  const response = await api.post(`/bookings/${bookingId}/session/extend`, payload);
  return response.data;
};
