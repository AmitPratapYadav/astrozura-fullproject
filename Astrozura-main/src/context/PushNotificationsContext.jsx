import { createContext, useContext, useEffect, useMemo, useState } from "react";

import api from "../api/axios";
import { useAuth } from "./AuthContext";
import {
  attachForegroundMessageListener,
  deleteStoredPushToken,
  getOrCreatePushToken,
  getStoredPushToken,
  isMessagingSupportedInBrowser,
} from "../lib/firebaseMessaging";

const PushNotificationsContext = createContext(null);

const resolveNotificationLink = (payload) =>
  payload?.fcmOptions?.link ||
  payload?.data?.link ||
  payload?.notification?.click_action ||
  "/live";

const showForegroundNotification = (payload) => {
  if (typeof window === "undefined" || !("Notification" in window) || Notification.permission !== "granted") {
    return;
  }

  const title = payload?.notification?.title || payload?.data?.title || "Astro Zura";
  const body = payload?.notification?.body || payload?.data?.body || "A live update is available.";
  const icon = payload?.notification?.icon || "/vite.svg";
  const link = resolveNotificationLink(payload);
  const notification = new Notification(title, {
    body,
    icon,
    badge: "/vite.svg",
    data: { link },
  });

  notification.onclick = () => {
    window.focus();
    window.location.href = link;
  };
};

export function PushNotificationsProvider({ children }) {
  const { user } = useAuth();

  const [isSupported, setIsSupported] = useState(false);
  const [permission, setPermission] = useState(
    typeof window !== "undefined" && "Notification" in window ? Notification.permission : "default"
  );
  const [isSubscribed, setIsSubscribed] = useState(Boolean(getStoredPushToken()));
  const [isLoading, setIsLoading] = useState(false);
  const [lastMessage, setLastMessage] = useState(null);

  useEffect(() => {
    let cancelled = false;
    let detachListener = null;

    const bootstrap = async () => {
      const supported = await isMessagingSupportedInBrowser();
      if (cancelled) {
        return;
      }

      setIsSupported(supported);
      setPermission(typeof Notification !== "undefined" ? Notification.permission : "default");

      if (!supported) {
        setIsSubscribed(false);
        return;
      }

      try {
        detachListener = await attachForegroundMessageListener((payload) => {
          setLastMessage(payload);
          showForegroundNotification(payload);
          window.dispatchEvent(new CustomEvent("astrozura:push-message", { detail: payload }));
        });
      } catch (error) {
        console.error("Failed to attach foreground push listener", error);
      }

      if (Notification.permission !== "granted") {
        setIsSubscribed(Boolean(getStoredPushToken()));
        return;
      }

      const token = getStoredPushToken();
      if (!token) {
        setIsSubscribed(false);
        return;
      }

      try {
        await api.post("/notifications/live/subscribe", {
          token,
          permission: Notification.permission,
        });
        if (!cancelled) {
          setIsSubscribed(true);
        }
      } catch (error) {
        console.error("Failed to sync existing push token", error);
      }
    };

    void bootstrap();

    return () => {
      cancelled = true;
      if (typeof detachListener === "function") {
        detachListener();
      }
    };
  }, [user?.id]);

  const subscribeToLiveNotifications = async () => {
    setIsLoading(true);
    try {
      const token = await getOrCreatePushToken({ requestPermission: true });
      await api.post("/notifications/live/subscribe", {
        token,
        permission: Notification.permission,
      });
      setPermission(Notification.permission);
      setIsSubscribed(true);
      return {
        success: true,
        message: "Live notifications enabled for this browser.",
      };
    } finally {
      setIsLoading(false);
    }
  };

  const unsubscribeFromLiveNotifications = async () => {
    setIsLoading(true);
    try {
      const token = await deleteStoredPushToken();
      if (token) {
        await api.post("/notifications/live/unsubscribe", { token });
      }
      setIsSubscribed(false);
      return {
        success: true,
        message: "Live notifications disabled for this browser.",
      };
    } finally {
      setIsLoading(false);
    }
  };

  const value = useMemo(
    () => ({
      isSupported,
      permission,
      isSubscribed,
      isLoading,
      lastMessage,
      subscribeToLiveNotifications,
      unsubscribeFromLiveNotifications,
    }),
    [isSupported, permission, isSubscribed, isLoading, lastMessage]
  );

  return <PushNotificationsContext.Provider value={value}>{children}</PushNotificationsContext.Provider>;
}

export const usePushNotifications = () => {
  const context = useContext(PushNotificationsContext);

  if (!context) {
    throw new Error("usePushNotifications must be used within PushNotificationsProvider.");
  }

  return context;
};
