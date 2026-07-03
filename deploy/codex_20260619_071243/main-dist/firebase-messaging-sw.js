/* global firebase, importScripts */

importScripts("https://www.gstatic.com/firebasejs/12.3.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/12.3.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCqpOiFJNg3YuQspbXaRNcYCsTVEt8n3Fo",
  authDomain: "astrozura-test.firebaseapp.com",
  projectId: "astrozura-test",
  storageBucket: "astrozura-test.firebasestorage.app",
  messagingSenderId: "116857071207",
  appId: "1:116857071207:web:0877e3f43cd205758256c2",
  measurementId: "G-945TX101PM",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload?.notification?.title || payload?.data?.title || "Astro Zura";
  const body = payload?.notification?.body || payload?.data?.body || "A live update is available.";
  const icon = payload?.notification?.icon || "/vite.svg";
  const link = payload?.fcmOptions?.link || payload?.data?.link || "/live";

  self.registration.showNotification(title, {
    body,
    icon,
    badge: "/vite.svg",
    data: {
      link,
    },
  });
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  const link = event.notification?.data?.link || "/live";

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((windowClients) => {
      for (const client of windowClients) {
        if ("focus" in client) {
          client.navigate(link);
          return client.focus();
        }
      }

      if (clients.openWindow) {
        return clients.openWindow(link);
      }

      return undefined;
    })
  );
});
