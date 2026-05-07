import { useEffect } from "react";
import { useSearchParams, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export default function OAuthCallback() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { setAuthFromOAuth } = useAuth();

  useEffect(() => {
    const token = searchParams.get("token");
    const isNew = searchParams.get("is_new") === "true";

    const processLogin = async () => {
      if (token) {
        const success = await setAuthFromOAuth(token);
        if (success) {
          if (isNew) {
            navigate("/user-profile", { replace: true });
          } else {
            const redirectTo = localStorage.getItem("redirect_after_login") || "/";
            localStorage.removeItem("redirect_after_login");
            navigate(redirectTo, { replace: true });
          }
        } else {
          navigate("/login?error=auth_failed");
        }
      } else {
        navigate("/login?error=no_token");
      }
    };

    processLogin();
  }, [searchParams, navigate, setAuthFromOAuth]);

  return (
    <div className="h-screen flex items-center justify-center bg-gray-50">
      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#3b82f6]"></div>
      <span className="ml-3 text-gray-600 font-medium tracking-wide">Authenticating...</span>
    </div>
  );
}
