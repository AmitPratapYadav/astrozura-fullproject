import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { apiRequest } from "../lib/api";

const AppContext = createContext(null);

export function AppProvider({ children }) {
  const [adminUser, setAdminUser] = useState(() => {
    const storedUser = localStorage.getItem("admin_user");
    return storedUser ? JSON.parse(storedUser) : null;
  });
  const [token, setToken] = useState(() => localStorage.getItem("admin_token"));
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const init = async () => {
      if (!token) {
        setLoading(false);
        return;
      }

      try {
        const response = await apiRequest("/admin/profile");
        if (response?.success) {
          setAdminUser(response.user);
          localStorage.setItem("admin_user", JSON.stringify(response.user));
        } else {
          localStorage.removeItem("admin_token");
          localStorage.removeItem("admin_user");
          setToken(null);
          setAdminUser(null);
        }
      } catch (error) {
        console.error("Admin session verification failed", error);
        localStorage.removeItem("admin_token");
        localStorage.removeItem("admin_user");
        setToken(null);
        setAdminUser(null);
      } finally {
        setLoading(false);
      }
    };

    void init();
  }, [token]);

  const login = useCallback(async (credentials) => {
    const response = await apiRequest("/admin/login", {
      method: "POST",
      body: credentials,
      requiresAuth: false,
    });

    if (response?.success) {
      localStorage.setItem("admin_token", response.token);
      localStorage.setItem("admin_user", JSON.stringify(response.user));
      setToken(response.token);
      setAdminUser(response.user);
    }

    return response;
  }, []);

  const refreshProfile = useCallback(async () => {
    const response = await apiRequest("/admin/profile");
    if (response?.success) {
      setAdminUser(response.user);
      localStorage.setItem("admin_user", JSON.stringify(response.user));
    }
    return response;
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem("admin_token");
    localStorage.removeItem("admin_user");
    setToken(null);
    setAdminUser(null);
    window.location.href = "/login";
  }, []);

  const value = useMemo(
    () => ({
      adminUser,
      token,
      loading,
      login,
      logout,
      refreshProfile,
      setAdminUser,
    }),
    [adminUser, token, loading, login, logout, refreshProfile]
  );

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useAppContext() {
  return useContext(AppContext);
}
