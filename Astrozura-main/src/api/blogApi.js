import api from "./axios";

export const getBlogCategories = async () => {
  const response = await api.get("/blog-categories", { params: { _: Date.now() } });
  return response.data;
};

export const getBlogs = async (params = {}) => {
  const response = await api.get("/blogs", { params: { ...params, _: Date.now() } });
  return response.data;
};

export const getBlog = async (slug) => {
  const response = await api.get(`/blogs/${slug}`, { params: { _: Date.now() } });
  return response.data;
};
