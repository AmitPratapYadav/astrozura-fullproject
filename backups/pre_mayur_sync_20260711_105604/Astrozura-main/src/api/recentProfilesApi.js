import api from "./axios";

export const getRecentProfiles = async (params = {}) => {
  const response = await api.get("/dashboard/recent-profiles", { params });
  return response.data;
};

export const saveRecentProfile = async (payload) => {
  const response = await api.post("/dashboard/recent-profiles", payload);
  return response.data;
};

export const updateRecentProfile = async (id, payload) => {
  const response = await api.put(`/dashboard/recent-profiles/${id}`, payload);
  return response.data;
};

export const deleteRecentProfile = async (id) => {
  const response = await api.delete(`/dashboard/recent-profiles/${id}`);
  return response.data;
};
