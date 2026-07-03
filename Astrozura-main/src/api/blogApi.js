import api from "./axios";

export const getBlogCategories = async () => {
  const response = await api.get("/blog-categories");
  return response.data;
};

export const getBlogs = async (params = {}) => {
  const response = await api.get("/blogs", { params });
  return response.data;
};

export const getBlog = async (slug) => {
  const response = await api.get(`/blogs/${slug}`);
  return response.data;
};
