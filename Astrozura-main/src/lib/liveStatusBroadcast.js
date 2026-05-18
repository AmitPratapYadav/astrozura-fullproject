const LIVE_STATUS_EVENT = "astrozura:live-status-changed";
const LIVE_STATUS_STORAGE_KEY = "astrozura:live-status-ping";
const LIVE_STATUS_CHANNEL_NAME = "astrozura-live-status";

let liveStatusChannel = null;

const getBroadcastChannel = () => {
  if (typeof window === "undefined" || typeof BroadcastChannel === "undefined") {
    return null;
  }

  if (!liveStatusChannel) {
    liveStatusChannel = new BroadcastChannel(LIVE_STATUS_CHANNEL_NAME);
  }

  return liveStatusChannel;
};

const normalizePayload = (payload) => ({
  session: payload?.session || null,
  timestamp: payload?.timestamp || Date.now(),
});

const emitWindowEvent = (payload) => {
  if (typeof window === "undefined") {
    return;
  }

  window.dispatchEvent(
    new CustomEvent(LIVE_STATUS_EVENT, {
      detail: payload,
    })
  );
};

export const publishLiveStatusChange = (session) => {
  const payload = normalizePayload({ session });

  emitWindowEvent(payload);

  const channel = getBroadcastChannel();
  if (channel) {
    try {
      channel.postMessage(payload);
    } catch {}
  }

  if (typeof window !== "undefined" && window.localStorage) {
    try {
      window.localStorage.setItem(LIVE_STATUS_STORAGE_KEY, JSON.stringify(payload));
    } catch {}
  }
};

export const subscribeToLiveStatusChanges = (listener) => {
  if (typeof window === "undefined") {
    return () => {};
  }

  const onWindowEvent = (event) => {
    listener(normalizePayload(event?.detail));
  };

  const onStorage = (event) => {
    if (event.key !== LIVE_STATUS_STORAGE_KEY || !event.newValue) {
      return;
    }

    try {
      listener(normalizePayload(JSON.parse(event.newValue)));
    } catch {}
  };

  const channel = getBroadcastChannel();
  const onChannelMessage = (event) => {
    listener(normalizePayload(event?.data));
  };

  window.addEventListener(LIVE_STATUS_EVENT, onWindowEvent);
  window.addEventListener("storage", onStorage);

  if (channel) {
    channel.addEventListener("message", onChannelMessage);
  }

  return () => {
    window.removeEventListener(LIVE_STATUS_EVENT, onWindowEvent);
    window.removeEventListener("storage", onStorage);

    if (channel) {
      channel.removeEventListener("message", onChannelMessage);
    }
  };
};
