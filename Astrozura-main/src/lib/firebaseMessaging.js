import { getApp, getApps, initializeApp } from "firebase/app";
import { deleteToken, getMessaging, getToken, isSupported, onMessage } from "firebase/messaging";

const TOKEN_STORAGE_KEY = "astrozura_live_push_token";

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
  measurementId: import.meta.env.VITE_FIREBASE_MEASUREMENT_ID,
};

const vapidKey = import.meta.env.VITE_FIREBASE_VAPID_KEY;

const hasFirebaseConfig = () =>
  Boolean(
    firebaseConfig.apiKey &&
      firebaseConfig.authDomain &&
      firebaseConfig.projectId &&
      firebaseConfig.storageBucket &&
      firebaseConfig.messagingSenderId &&
      firebaseConfig.appId &&
      vapidKey
  );

const getFirebaseApp = () => {
  if (!hasFirebaseConfig()) {
    throw new Error("Firebase web push is not configured.");
  }

  return getApps().length ? getApp() : initializeApp(firebaseConfig);
};

export const getStoredPushToken = () => {
  if (typeof window === "undefined") {
    return "";
  }

  return window.localStorage.getItem(TOKEN_STORAGE_KEY) || "";
};

const setStoredPushToken = (token) => {
  if (typeof window === "undefined") {
    return;
  }

  if (token) {
    window.localStorage.setItem(TOKEN_STORAGE_KEY, token);
    return;
  }

  window.localStorage.removeItem(TOKEN_STORAGE_KEY);
};

export const isMessagingSupportedInBrowser = async () => {
  if (typeof window === "undefined") {
    return false;
  }

  if (!("Notification" in window) || !("serviceWorker" in navigator)) {
    return false;
  }

  if (!hasFirebaseConfig()) {
    return false;
  }

  return isSupported();
};

export const registerFirebaseMessagingServiceWorker = async () => {
  return navigator.serviceWorker.register("/firebase-messaging-sw.js");
};

export const getMessagingInstance = async () => {
  const supported = await isMessagingSupportedInBrowser();

  if (!supported) {
    throw new Error("Push notifications are not supported in this browser.");
  }

  return getMessaging(getFirebaseApp());
};

export const getOrCreatePushToken = async ({ requestPermission = true } = {}) => {
  if (!hasFirebaseConfig()) {
    throw new Error("Firebase web push is not configured.");
  }

  if (typeof window === "undefined") {
    throw new Error("Push notifications are only available in the browser.");
  }

  if (Notification.permission === "denied") {
    throw new Error("Browser notification permission is blocked.");
  }

  if (requestPermission && Notification.permission === "default") {
    const permission = await Notification.requestPermission();
    if (permission !== "granted") {
      throw new Error("Browser notification permission was not granted.");
    }
  }

  if (Notification.permission !== "granted") {
    throw new Error("Browser notification permission is required.");
  }

  const messaging = await getMessagingInstance();
  const serviceWorkerRegistration = await registerFirebaseMessagingServiceWorker();
  const token = await getToken(messaging, {
    vapidKey,
    serviceWorkerRegistration,
  });

  if (!token) {
    throw new Error("A browser push token could not be created.");
  }

  setStoredPushToken(token);
  return token;
};

export const deleteStoredPushToken = async () => {
  const existingToken = getStoredPushToken();

  try {
    const messaging = await getMessagingInstance();
    await deleteToken(messaging);
  } catch {
    // Ignore SDK cleanup failures. Backend unsubscription will still deactivate the token.
  }

  setStoredPushToken("");
  return existingToken;
};

export const attachForegroundMessageListener = async (callback) => {
  const messaging = await getMessagingInstance();
  return onMessage(messaging, callback);
};
