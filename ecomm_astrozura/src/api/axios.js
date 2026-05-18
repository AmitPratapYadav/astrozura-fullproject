import axios from 'axios';
import {
  TEST_ACCESS_ENABLED,
  TEST_ACCESS_HEADER,
  getTestingAccessPassword,
} from '../lib/testingAccess';

// Create an instance of axios
const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000/api',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

// Add a request interceptor to include the Sanctum token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    if (TEST_ACCESS_ENABLED) {
      const testingPassword = getTestingAccessPassword();
      if (testingPassword) {
        config.headers[TEST_ACCESS_HEADER] = testingPassword;
      }
    }

    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Add a response interceptor to handle 401 Unauthorized
api.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    if (error.response && error.response.status === 401) {
      const isLoginReq = error.config?.url?.includes('/login') || false;
      if (!isLoginReq) {
        localStorage.removeItem('auth_token');
        localStorage.removeItem('user');
        window.dispatchEvent(new Event('auth:unauthorized'));
      }
    }
    return Promise.reject(error);
  }
);

export default api;
