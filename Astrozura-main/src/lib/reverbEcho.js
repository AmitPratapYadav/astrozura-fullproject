import Echo from "laravel-echo";
import Pusher from "pusher-js";

import api from "../api/axios";

let echoInstance = null;
let echoKey = "";

export const getReverbEcho = (chatConfig = {}) => {
  const appKey = chatConfig.app_key || import.meta.env.VITE_REVERB_APP_KEY || "astrozura-reverb";
  const host = chatConfig.host || import.meta.env.VITE_REVERB_HOST || window.location.hostname;
  const port = Number(chatConfig.port || import.meta.env.VITE_REVERB_PORT || 8080);
  const scheme = chatConfig.scheme || import.meta.env.VITE_REVERB_SCHEME || window.location.protocol.replace(":", "") || "https";
  const forceTLS = scheme === "https";
  const nextKey = `${appKey}:${host}:${port}:${scheme}`;

  if (echoInstance && echoKey === nextKey) {
    return echoInstance;
  }

  if (echoInstance) {
    echoInstance.disconnect();
  }

  window.Pusher = Pusher;

  echoInstance = new Echo({
    broadcaster: "reverb",
    key: appKey,
    wsHost: host,
    wsPort: port,
    wssPort: port,
    forceTLS,
    enabledTransports: forceTLS ? ["wss"] : ["ws"],
    disableStats: true,
    authorizer: (channel) => ({
      authorize: (socketId, callback) => {
        api
          .post(chatConfig.auth_endpoint || "/broadcasting/auth", {
            socket_id: socketId,
            channel_name: channel.name,
          })
          .then((response) => callback(false, response.data))
          .catch((error) => callback(true, error));
      },
    }),
  });
  echoKey = nextKey;

  return echoInstance;
};

export const disconnectReverbEcho = () => {
  if (echoInstance) {
    echoInstance.disconnect();
  }
  echoInstance = null;
  echoKey = "";
};
