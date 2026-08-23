import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Link } from "react-router-dom";
import { FaBroadcastTower, FaPaperPlane, FaPlay, FaPowerOff, FaVideo } from "react-icons/fa";

import api from "../api/axios";
import Footer from "../components/Footer";
import Navbar from "../components/Navbar";
import { useAuth } from "../context/AuthContext";
import { usePushNotifications } from "../context/PushNotificationsContext";
import { publishLiveStatusChange, subscribeToLiveStatusChanges } from "../lib/liveStatusBroadcast";

const BACKEND_ORIGIN = import.meta.env.VITE_BACKEND_URL || "https://astrozura.com";
let videoSdkPromise = null;

const getVideoSdk = async () => {
  if (!videoSdkPromise) {
    videoSdkPromise = import("@videosdk.live/js-sdk").then((module) => {
      const sdk =
        module.VideoSDK ||
        module.default?.VideoSDK ||
        module.default?.default?.VideoSDK ||
        module.default ||
        module;

      if (typeof sdk?.config !== "function" || typeof sdk?.initMeeting !== "function") {
        throw new Error("VideoSDK live SDK could not be initialized.");
      }

      return sdk;
    });
  }

  return videoSdkPromise;
};

const resolveImageUrl = (path) => {
  if (!path) return "";
  if (path.startsWith("http")) return path;
  return `${BACKEND_ORIGIN}${path.startsWith("/") ? path : `/${path}`}`;
};

const formatLiveTime = (value) =>
  value
    ? new Date(value).toLocaleString("en-IN", {
        dateStyle: "medium",
        timeStyle: "short",
        timeZone: "Asia/Kolkata",
      })
    : "-";

const getVideoSdkPayload = (viewer) => viewer?.viewer?.provider?.videosdk || viewer?.provider?.videosdk || null;
const getViewerRole = (viewer) => viewer?.viewer?.role || viewer?.role || getVideoSdkPayload(viewer)?.role || "viewer";
const getLiveCommentTopic = (liveSessionId) => `ASTROZURA_LIVE_COMMENTS_${liveSessionId}`;
const LIVE_COMMENT_PAYLOAD_TYPE = "astrozura.live.comment.v1";

const buildPubSubCommentPayload = (comment, liveSessionId) => ({
  type: LIVE_COMMENT_PAYLOAD_TYPE,
  live_session_id: liveSessionId,
  comment: {
    id: comment?.id,
    message: comment?.message || "",
    created_at: comment?.created_at || new Date().toISOString(),
    user: {
      id: comment?.user?.id,
      name: comment?.user?.name || "Viewer",
    },
  },
});

const parsePubSubCommentPayload = (pubSubMessage, expectedSessionId) => {
  if (!pubSubMessage?.message) {
    return null;
  }

  let payload;
  try {
    payload = JSON.parse(pubSubMessage.message);
  } catch {
    payload = {
      type: LIVE_COMMENT_PAYLOAD_TYPE,
      live_session_id: expectedSessionId,
      comment: {
        id: pubSubMessage.id,
        message: pubSubMessage.message,
        created_at: pubSubMessage.timestamp || new Date().toISOString(),
        user: {
          id: pubSubMessage.senderId,
          name: pubSubMessage.senderName || "Viewer",
        },
      },
    };
  }

  if (payload?.type !== LIVE_COMMENT_PAYLOAD_TYPE || String(payload.live_session_id) !== String(expectedSessionId)) {
    return null;
  }

  const comment = payload.comment || payload;
  if (!comment?.message) {
    return null;
  }

  return {
    id: comment.id || pubSubMessage.id,
    message: comment.message,
    created_at: comment.created_at || pubSubMessage.timestamp || new Date().toISOString(),
    user: {
      id: comment.user?.id || pubSubMessage.senderId,
      name: comment.user?.name || pubSubMessage.senderName || "Viewer",
    },
  };
};

export default function LiveSessions() {
  const { user } = useAuth();
  const astrologerDetail = user?.astrologer_detail || user?.astrologerDetail || {};
  const {
    isSupported: pushSupported,
    isSubscribed: pushSubscribed,
    isLoading: pushLoading,
    permission: pushPermission,
    subscribeToLiveNotifications,
    unsubscribeFromLiveNotifications,
  } = usePushNotifications();
  const [banner, setBanner] = useState("");
  const [session, setSession] = useState(null);
  const [viewerConfig, setViewerConfig] = useState(null);
  const [comments, setComments] = useState([]);
  const [pendingComments, setPendingComments] = useState([]);
  const [commentDraft, setCommentDraft] = useState("");
  const [loading, setLoading] = useState(true);
  const [joining, setJoining] = useState(false);
  const [hosting, setHosting] = useState(false);
  const [sendingComment, setSendingComment] = useState(false);
  const [liveState, setLiveState] = useState("idle");
  const [liveStatus, setLiveStatus] = useState("No active live session.");

  const localVideoRef = useRef(null);
  const remoteVideoRef = useRef(null);
  const meetingRef = useRef(null);
  const localMediaStreamRef = useRef(null);
  const remoteMediaStreamRef = useRef(null);
  const liveRefreshTimerRef = useRef(null);
  const commentRefreshTimerRef = useRef(null);
  const autoJoinRequestedRef = useRef(false);
  const currentSessionIdRef = useRef(null);
  const pubSubTopicRef = useRef("");
  const pubSubListenersRef = useRef(null);

  const isFeaturedAstrologer = Boolean(user?.role === "astrologer" && astrologerDetail?.is_featured);
  const isHost = Boolean(getViewerRole(viewerConfig) === "host");
  const visibleComments = useMemo(() => {
    const combined = [...comments];

    pendingComments.forEach((pendingComment) => {
      const exists = combined.some(
        (comment) =>
          comment.id === pendingComment.id ||
          (comment.user?.id === pendingComment.user?.id &&
            comment.message === pendingComment.message &&
            Math.abs(new Date(comment.created_at).getTime() - new Date(pendingComment.created_at).getTime()) < 15000)
      );

      if (!exists) {
        combined.push(pendingComment);
      }
    });

    combined.sort((left, right) => new Date(left.created_at).getTime() - new Date(right.created_at).getTime());
    return combined;
  }, [comments, pendingComments]);

  const loadCurrentSession = async () => {
    const response = await api.get("/live-sessions/current");
    setSession(response.data?.session || null);
    return response.data?.session || null;
  };

  const loadViewerConfig = async () => {
    if (!user) {
      setViewerConfig(null);
      return null;
    }

    try {
      const response = await api.get("/live-sessions/current/viewer");
      setViewerConfig(response.data || null);
      return response.data || null;
    } catch (error) {
      setViewerConfig(null);
      return null;
    }
  };

  const loadComments = async (liveSessionId) => {
    if (!liveSessionId) {
      setComments([]);
      setPendingComments([]);
      return;
    }

    const response = await api.get(`/live-sessions/${liveSessionId}/comments`);
    const nextComments = response.data?.comments || [];
    setComments(nextComments);
    setPendingComments((previous) =>
      previous.filter(
        (pendingComment) =>
          !nextComments.some(
            (comment) =>
              comment.user?.id === pendingComment.user?.id &&
              comment.message === pendingComment.message &&
              Math.abs(new Date(comment.created_at).getTime() - new Date(pendingComment.created_at).getTime()) < 15000
          )
      )
    );
  };

  const appendLiveComment = useCallback((incomingComment) => {
    if (!incomingComment?.message) {
      return;
    }

    setPendingComments((previous) =>
      previous.filter(
        (pendingComment) =>
          !(
            pendingComment.id === incomingComment.id ||
            (pendingComment.user?.id === incomingComment.user?.id &&
              pendingComment.message === incomingComment.message &&
              Math.abs(
                new Date(pendingComment.created_at).getTime() - new Date(incomingComment.created_at).getTime()
              ) < 15000)
          )
      )
    );

    setComments((previous) => {
      const exists = previous.some(
        (comment) =>
          comment.id === incomingComment.id ||
          (comment.user?.id === incomingComment.user?.id &&
            comment.message === incomingComment.message &&
            Math.abs(new Date(comment.created_at).getTime() - new Date(incomingComment.created_at).getTime()) < 15000)
      );

      return exists ? previous : [...previous, incomingComment];
    });
  }, []);

  const unsubscribeLiveComments = async (meeting = meetingRef.current) => {
    if (!meeting?.pubSub?.unsubscribe || !pubSubTopicRef.current || !pubSubListenersRef.current) {
      pubSubTopicRef.current = "";
      pubSubListenersRef.current = null;
      return;
    }

    const topic = pubSubTopicRef.current;
    const listeners = pubSubListenersRef.current;
    pubSubTopicRef.current = "";
    pubSubListenersRef.current = null;

    try {
      await meeting.pubSub.unsubscribe(topic, listeners);
    } catch (error) {
      const errorText = String(error?.message || error?.code || error || "").toLowerCase();
      const isAlreadyDisconnected =
        errorText.includes("pubsub_unsubscribe_failed") ||
        errorText.includes("pubsub is not available") ||
        errorText.includes("disconnected state");

      if (!isAlreadyDisconnected) {
        console.error("Failed to unsubscribe live comments", error);
      }
    }
  };

  const subscribeToLiveComments = async (meeting, liveSessionId) => {
    if (!meeting?.pubSub?.subscribe || !liveSessionId) {
      return;
    }

    await unsubscribeLiveComments(meeting);

    const topic = getLiveCommentTopic(liveSessionId);
    const listeners = {
      onMessageReceived: (pubSubMessage) => {
        const incomingComment = parsePubSubCommentPayload(pubSubMessage, liveSessionId);
        appendLiveComment(incomingComment);
      },
      onBatchReceived: (pubSubMessages = []) => {
        pubSubMessages.forEach((pubSubMessage) => {
          const incomingComment = parsePubSubCommentPayload(pubSubMessage, liveSessionId);
          appendLiveComment(incomingComment);
        });
      },
      onOldMessagesReceived: (pubSubMessages = []) => {
        pubSubMessages.forEach((pubSubMessage) => {
          const incomingComment = parsePubSubCommentPayload(pubSubMessage, liveSessionId);
          appendLiveComment(incomingComment);
        });
      },
      onMessageDrop: (info) => {
        console.warn("VideoSDK live comments dropped messages", info);
      },
    };

    try {
      await meeting.pubSub.subscribe(topic, listeners, {
        oldMessageLimit: 0,
        realtimeOverflow: "queue",
        maxQueue: 100,
        newMessageLimit: 20,
      });
      pubSubTopicRef.current = topic;
      pubSubListenersRef.current = listeners;
    } catch (error) {
      console.error("Failed to subscribe live comments through VideoSDK", error);
    }
  };

  const publishLiveComment = async (comment, liveSessionId = session?.id) => {
    const meeting = meetingRef.current;
    if (!meeting?.pubSub?.publish || !comment?.message || !liveSessionId) {
      return;
    }

    try {
      await meeting.pubSub.publish(
        getLiveCommentTopic(liveSessionId),
        JSON.stringify(buildPubSubCommentPayload(comment, liveSessionId)),
        { persist: false }
      );
    } catch (error) {
      console.error("Failed to publish live comment through VideoSDK", error);
    }
  };

  const ensureMediaStream = (mediaStreamRef, videoRef) => {
    if (!mediaStreamRef.current) {
      mediaStreamRef.current = new MediaStream();
    }

    if (videoRef.current && videoRef.current.srcObject !== mediaStreamRef.current) {
      videoRef.current.srcObject = mediaStreamRef.current;
    }

    return mediaStreamRef.current;
  };

  const attachTrackToVideo = (stream, mediaStreamRef, videoRef) => {
    if (!stream?.track || !["audio", "video"].includes(stream.kind)) {
      return;
    }

    const mediaStream = ensureMediaStream(mediaStreamRef, videoRef);
    mediaStream
      .getTracks()
      .filter((track) => track.kind === stream.track.kind)
      .forEach((track) => mediaStream.removeTrack(track));
    mediaStream.addTrack(stream.track);

    if (videoRef.current) {
      videoRef.current.play().catch(() => undefined);
    }
  };

  const detachTrackFromVideo = (stream, mediaStreamRef) => {
    if (!stream?.track || !mediaStreamRef.current) {
      return;
    }

    mediaStreamRef.current
      .getTracks()
      .filter((track) => track.id === stream.track.id)
      .forEach((track) => mediaStreamRef.current.removeTrack(track));
  };

  const bindParticipantStreams = (participant, target) => {
    const mediaStreamRef = target === "local" ? localMediaStreamRef : remoteMediaStreamRef;
    const videoRef = target === "local" ? localVideoRef : remoteVideoRef;

    participant?.streams?.forEach((stream) => {
      attachTrackToVideo(stream, mediaStreamRef, videoRef);
    });

    participant?.on?.("stream-enabled", (stream) => {
      attachTrackToVideo(stream, mediaStreamRef, videoRef);
      if (target === "remote") {
        setLiveState("watching");
        setLiveStatus("Watching the live broadcast.");
      }
    });

    participant?.on?.("stream-disabled", (stream) => {
      detachTrackFromVideo(stream, mediaStreamRef);
    });
  };

  const teardownLiveRoom = () => {
    const meeting = meetingRef.current;

    if (meeting) {
      try {
        void unsubscribeLiveComments(meeting);
        meeting.leave();
      } catch {}
    }

    [localMediaStreamRef, remoteMediaStreamRef].forEach((mediaStreamRef) => {
      mediaStreamRef.current?.getTracks?.().forEach((track) => {
        try {
          track.stop();
        } catch {}
      });
      mediaStreamRef.current = null;
    });

    if (remoteVideoRef.current) {
      remoteVideoRef.current.srcObject = null;
    }

    if (localVideoRef.current) {
      localVideoRef.current.srcObject = null;
    }

    meetingRef.current = null;
    setLiveState("idle");
  };

  const connectToLiveSession = async (targetSession, viewer) => {
    const videoSdk = getVideoSdkPayload(viewer);
    if (!videoSdk) {
      throw new Error("VideoSDK viewer access could not be prepared.");
    }

    teardownLiveRoom();
    setLiveState("connecting");
    setLiveStatus("Connecting live room...");

    const VideoSDK = await getVideoSdk();
    VideoSDK.config(videoSdk.token);

    const role = getViewerRole(viewer);
    const mode = videoSdk.mode || (role === "host" ? "SEND_AND_RECV" : "RECV_ONLY");
    const meeting = VideoSDK.initMeeting({
      meetingId: videoSdk.room_id,
      participantId: videoSdk.participant_id,
      name: user?.name || `${role}-${user?.id || "guest"}`,
      micEnabled: role === "host",
      webcamEnabled: role === "host",
      mode,
      multiStream: true,
      autoConsume: true,
      maxResolution: "hd",
      metaData: {
        role,
        astrozuraLiveSessionId: targetSession.id,
      },
    });

    meetingRef.current = meeting;

    meeting.on("meeting-joined", () => {
      bindParticipantStreams(meeting.localParticipant, "local");
      meeting.participants?.forEach((participant) => bindParticipantStreams(participant, "remote"));
      void subscribeToLiveComments(meeting, targetSession.id);
      setLiveState(role === "host" ? "live" : "watching");
      setLiveStatus(role === "host" ? "You are live now." : "Watching the live broadcast.");
    });

    meeting.on("participant-joined", (participant) => {
      bindParticipantStreams(participant, "remote");
    });

    meeting.on("participant-left", () => {
      if (role !== "host" && remoteMediaStreamRef.current?.getTracks?.().length === 0) {
        setLiveStatus("Waiting for the astrologer video...");
      }
    });

    meeting.on("meeting-left", () => {
      setLiveState("idle");
      setLiveStatus("Live room disconnected.");
    });

    meeting.on("error", (error) => {
      console.error("VideoSDK live room error", error);
      setLiveState("error");
      setLiveStatus("Live room connection failed.");
    });

    await meeting.join();
  };

  const syncLiveSnapshot = async ({ silent = false } = {}) => {
    const current = await loadCurrentSession();
    const nextSessionId = current?.id || null;
    const previousSessionId = currentSessionIdRef.current;
    const sessionChanged = previousSessionId !== nextSessionId;

    currentSessionIdRef.current = nextSessionId;

    if (!current) {
      setSession(null);
      setViewerConfig(null);
      setComments([]);
      setPendingComments([]);

      if (meetingRef.current) {
        teardownLiveRoom();
      }

      setLiveStatus("No active live session right now.");
      if (sessionChanged) {
        publishLiveStatusChange(null);
      }
      return null;
    }

    setSession(current);
    const [_, viewer] = await Promise.all([
      loadComments(current.id),
      user ? loadViewerConfig() : Promise.resolve(null),
    ]);

    if (sessionChanged) {
      publishLiveStatusChange(current);
    }

    if (sessionChanged && meetingRef.current) {
      teardownLiveRoom();
    }

    if (autoJoinRequestedRef.current && user && getVideoSdkPayload(viewer) && (sessionChanged || !meetingRef.current)) {
      await connectToLiveSession(current, viewer);
    } else if (!silent && !meetingRef.current) {
      setLiveStatus("Active spiritual live session is ready.");
    }

    return current;
  };

  useEffect(() => {
    let cancelled = false;

    const idlePreload =
      typeof window !== "undefined" && "requestIdleCallback" in window
        ? window.requestIdleCallback(() => {
            void getVideoSdk().catch((error) => {
              console.error("Failed to preload VideoSDK live SDK", error);
            });
          })
        : window.setTimeout(() => {
            void getVideoSdk().catch((error) => {
              console.error("Failed to preload VideoSDK live SDK", error);
            });
          }, 1200);

    const bootstrap = async () => {
      try {
        setLoading(true);
        await syncLiveSnapshot();
      } catch (error) {
        if (!cancelled) {
          console.error("Failed to load live session", error);
          setLiveStatus("Live session details could not be loaded.");
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    };

    void bootstrap();

    if (liveRefreshTimerRef.current) {
      window.clearInterval(liveRefreshTimerRef.current);
    }

    liveRefreshTimerRef.current = window.setInterval(() => {
      void syncLiveSnapshot({ silent: true }).catch((error) => {
        console.error("Failed to refresh live session", error);
      });
    }, 2000);

    const handlePushMessage = () => {
      void syncLiveSnapshot({ silent: true }).catch((error) => {
        console.error("Failed to refresh live session after push", error);
      });
    };

    const unsubscribeLiveStatus = subscribeToLiveStatusChanges(() => {
      void syncLiveSnapshot({ silent: true }).catch((error) => {
        console.error("Failed to refresh live session after broadcast", error);
      });
    });

    window.addEventListener("astrozura:push-message", handlePushMessage);

    return () => {
      cancelled = true;
      if (liveRefreshTimerRef.current) {
        window.clearInterval(liveRefreshTimerRef.current);
      }
      if (typeof window !== "undefined" && "cancelIdleCallback" in window) {
        window.cancelIdleCallback(idlePreload);
      } else {
        window.clearTimeout(idlePreload);
      }
      unsubscribeLiveStatus();
      window.removeEventListener("astrozura:push-message", handlePushMessage);
    };
  }, [user]);

  useEffect(() => {
    if (commentRefreshTimerRef.current) {
      window.clearInterval(commentRefreshTimerRef.current);
    }

    if (!session?.id) {
      return undefined;
    }

    commentRefreshTimerRef.current = window.setInterval(() => {
      void loadComments(session.id).catch((error) => {
        console.error("Failed to refresh live comments", error);
      });
    }, 1500);

    return () => {
      if (commentRefreshTimerRef.current) {
        window.clearInterval(commentRefreshTimerRef.current);
      }
    };
  }, [session?.id]);

  useEffect(() => {
    if (!banner) return undefined;
    const timer = window.setTimeout(() => setBanner(""), 2500);
    return () => window.clearTimeout(timer);
  }, [banner]);

  useEffect(() => {
    return () => {
      teardownLiveRoom();
      if (liveRefreshTimerRef.current) {
        window.clearInterval(liveRefreshTimerRef.current);
      }
      if (commentRefreshTimerRef.current) {
        window.clearInterval(commentRefreshTimerRef.current);
      }
    };
  }, []);

  const handleStartLive = async () => {
    if (!isFeaturedAstrologer) {
      setBanner("Only featured astrologers can host a live session.");
      return;
    }

    try {
      setHosting(true);
      const response = await api.post("/live-sessions/start", {});
      const startedSession = response.data?.session;
      const startedViewer = response.data?.viewer;

      setSession(startedSession);
      setViewerConfig({
        session: startedSession,
        viewer: startedViewer,
      });
      currentSessionIdRef.current = startedSession?.id || null;
      autoJoinRequestedRef.current = true;
      publishLiveStatusChange(startedSession);
      await connectToLiveSession(startedSession, {
        viewer: startedViewer,
      });
      setBanner("Live session started.");
    } catch (error) {
      console.error("Failed to start live session", error);
      teardownLiveRoom();
      setBanner(error?.response?.data?.message || "Live session could not be started.");
    } finally {
      setHosting(false);
    }
  };

  const handleJoinLive = async () => {
    if (!user) {
      setBanner("Sign in to join the live session.");
      return;
    }

    if (!session) {
      setBanner("No live session is active right now.");
      return;
    }

    try {
      setJoining(true);
      const viewer = await loadViewerConfig();
      if (!getVideoSdkPayload(viewer)) {
        throw new Error("VideoSDK viewer access could not be prepared.");
      }
      autoJoinRequestedRef.current = true;
      await connectToLiveSession(session, viewer);
    } catch (error) {
      console.error("Failed to join live session", error);
      teardownLiveRoom();
      setBanner(error?.response?.data?.message || error?.message || "Live session could not be joined.");
    } finally {
      setJoining(false);
    }
  };

  const handleStopLive = async () => {
    if (!session?.id) {
      return;
    }

    const activeSession = session;

    try {
      const currentMeeting = meetingRef.current;
      if (currentMeeting && isHost) {
        try {
          await currentMeeting.end();
        } catch {
          await currentMeeting.leave().catch(() => undefined);
        }
      }
      teardownLiveRoom();
      autoJoinRequestedRef.current = false;
      currentSessionIdRef.current = null;
      setSession(null);
      setViewerConfig(null);
      setComments([]);
      setPendingComments([]);
      setLiveStatus("No active live session right now.");
      publishLiveStatusChange(null);
      setBanner("Live session stopped.");
      await api.post(`/live-sessions/${activeSession.id}/stop`);
    } catch (error) {
      console.error("Failed to stop live session", error);
      currentSessionIdRef.current = activeSession.id;
      setSession(activeSession);
      publishLiveStatusChange(activeSession);
      void syncLiveSnapshot().catch((syncError) => {
        console.error("Failed to restore live session after stop error", syncError);
      });
      setBanner(error?.response?.data?.message || "Live session could not be stopped.");
    }
  };

  const handleSendComment = async () => {
    const trimmed = commentDraft.trim();
    if (!trimmed || !session?.id) {
      return;
    }

    const optimisticId =
      typeof crypto !== "undefined" && typeof crypto.randomUUID === "function"
        ? `optimistic-${crypto.randomUUID()}`
        : `optimistic-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    const optimisticComment = {
      id: optimisticId,
      message: trimmed,
      created_at: new Date().toISOString(),
      user: {
        id: user?.id,
        name: user?.name || "You",
      },
      is_pending: true,
    };

    try {
      setSendingComment(true);
      setPendingComments((previous) => [...previous, optimisticComment]);
      setCommentDraft("");
      const response = await api.post(`/live-sessions/${session.id}/comments`, {
        message: trimmed,
      });

      setPendingComments((previous) => previous.filter((comment) => comment.id !== optimisticId));
      appendLiveComment(response.data.comment);
      void publishLiveComment(response.data.comment, session.id);
      void loadComments(session.id).catch((syncError) => {
        console.error("Failed to refresh live comments after send", syncError);
      });
    } catch (error) {
      console.error("Failed to send live comment", error);
      setPendingComments((previous) => previous.filter((comment) => comment.id !== optimisticId));
      setCommentDraft((currentValue) => currentValue || trimmed);
      if (error?.response?.status === 422 || error?.response?.status === 404) {
        void syncLiveSnapshot({ silent: true }).catch((syncError) => {
          console.error("Failed to refresh live session after comment failure", syncError);
        });
      }
      setBanner(error?.response?.data?.message || "Comment could not be sent.");
    } finally {
      setSendingComment(false);
    }
  };

  const handleLiveNotificationToggle = async () => {
    try {
      const result = pushSubscribed
        ? await unsubscribeFromLiveNotifications()
        : await subscribeToLiveNotifications();

      setBanner(result.message);
    } catch (error) {
      console.error("Failed to update live notification subscription", error);
      setBanner(error?.message || "Live notification subscription could not be updated.");
    }
  };

  const hostButtonLabel = useMemo(() => {
    if (hosting) return "Starting Live...";
    if (session && isHost) return "Live Studio Ready";
    return "Start Live Broadcast";
  }, [hosting, session, isHost]);

  return (
    <div className="min-h-screen bg-[#FBF7F0]">
      <Navbar />

      {banner && (
        <div className="fixed left-1/2 top-24 z-[70] -translate-x-1/2 rounded-full bg-[#1E3557] px-6 py-3 text-sm font-semibold text-white shadow-lg">
          {banner}
        </div>
      )}

      <section className="bg-[#1E3557] px-4 py-16 text-white md:px-10">
        <div className="mx-auto max-w-7xl">
          <span className="rounded-full border border-white/15 bg-white/10 px-4 py-1.5 text-[11px] font-bold uppercase tracking-[0.22em]">
            Astro Zura Live
          </span>
          <h1 className="mt-6 text-4xl font-black md:text-6xl">Live Spiritual Sessions</h1>
          <p className="mt-5 max-w-2xl text-sm leading-7 text-slate-200 md:text-base">
            Featured astrologers can go live for open guidance, and signed-in users can join, watch, and comment in real time.
          </p>
        </div>
      </section>

      <main className="mx-auto max-w-7xl px-4 py-10 md:px-10">
        {loading ? (
          <div className="flex min-h-[320px] items-center justify-center">
            <div className="h-12 w-12 animate-spin rounded-full border-b-2 border-[#D4A73C]" />
          </div>
        ) : (
          <div className="grid gap-8 xl:grid-cols-[minmax(0,1fr)_360px]">
            <section className="rounded-[2rem] border border-[#E8DEC8] bg-white p-6 shadow-sm">
              <div className="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
                <div>
                  <p className="text-xs font-semibold uppercase tracking-[0.22em] text-[#D4A73C]">
                    {session ? "Live Now" : "Standby"}
                  </p>
                  <h2 className="mt-2 text-3xl font-black text-[#1E3557]">
                    {session?.title || "No featured astrologer is live right now"}
                  </h2>
                  <p className="mt-3 max-w-3xl text-sm leading-7 text-gray-600">
                    {session?.description || "The next live spiritual session will appear here when a featured astrologer starts broadcasting."}
                  </p>
                </div>

                {isFeaturedAstrologer && (
                  <button
                    type="button"
                    onClick={() => void handleStartLive()}
                    disabled={hosting || Boolean(session)}
                    className="inline-flex items-center justify-center gap-2 rounded-2xl bg-[#D4A73C] px-6 py-3 text-sm font-bold text-[#1E3557] transition hover:bg-[#c49530] disabled:cursor-not-allowed disabled:opacity-60"
                  >
                    <FaBroadcastTower />
                    {hostButtonLabel}
                  </button>
                )}
              </div>

              <div className="mt-8 overflow-hidden rounded-[1.75rem] border border-[#E9E3D5] bg-[#0F1D35]">
                <div className="relative aspect-video w-full">
                  {isHost ? (
                    <video ref={localVideoRef} autoPlay muted playsInline className="h-full w-full object-cover" />
                  ) : (
                    <video ref={remoteVideoRef} autoPlay playsInline controls className="h-full w-full bg-black object-cover" />
                  )}

                  {!session && (
                    <div className="absolute inset-0 flex flex-col items-center justify-center gap-4 text-center text-white">
                      <FaVideo className="text-4xl text-[#D4A73C]" />
                      <p className="text-lg font-bold">No live session is active</p>
                      <p className="max-w-md text-sm text-slate-200">
                        Featured astrologers can start a live session from this page. Users will be able to join when the broadcast is live.
                      </p>
                    </div>
                  )}
                </div>
              </div>

              <div className="mt-6 flex flex-wrap gap-3">
                <button
                  type="button"
                  onClick={() => void handleJoinLive()}
                  disabled={!session || !user || joining || liveState === "watching" || liveState === "live"}
                  className="inline-flex items-center justify-center gap-2 rounded-2xl bg-[#1E3557] px-5 py-3 text-sm font-semibold text-white transition hover:bg-[#162744] disabled:cursor-not-allowed disabled:opacity-50"
                >
                  <FaPlay />
                  {joining ? "Joining..." : session ? (user ? "Join Live Session" : "Sign in to Join") : "Waiting for Live"}
                </button>

                {isHost && session && (
                  <button
                    type="button"
                    onClick={() => void handleStopLive()}
                    className="inline-flex items-center justify-center gap-2 rounded-2xl border border-rose-200 px-5 py-3 text-sm font-semibold text-rose-600 transition hover:bg-rose-50"
                  >
                    <FaPowerOff />
                    Stop Live
                  </button>
                )}

                <button
                  type="button"
                  onClick={() => void handleLiveNotificationToggle()}
                  disabled={!pushSupported || pushLoading}
                  className="inline-flex items-center justify-center gap-2 rounded-2xl border border-[#D4A73C]/30 px-5 py-3 text-sm font-semibold text-[#D4A73C] transition hover:bg-[#FFF7E5] disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {pushSupported
                    ? pushLoading
                      ? "Updating Alerts..."
                      : pushSubscribed
                        ? "Disable Live Alerts"
                        : "Notify Me for Live"
                    : "Notifications Unsupported"}
                </button>

                {!user && (
                  <Link
                    to="/login"
                    className="inline-flex items-center justify-center rounded-2xl border border-gray-200 px-5 py-3 text-sm font-semibold text-[#1E3557] transition hover:border-[#D4A73C] hover:text-[#D4A73C]"
                  >
                    Sign in to Join & Comment
                  </Link>
                )}
              </div>

              <div className="mt-5 rounded-2xl bg-[#F8F9FC] px-4 py-3 text-sm text-gray-600">
                {liveStatus}
              </div>
              {pushSupported && (
                <p className="mt-3 text-xs leading-6 text-gray-500">
                  {pushPermission === "denied"
                    ? "Browser notifications are blocked for this site. Enable them in browser settings to receive live-start alerts."
                    : "Subscribe once on this browser to receive Astro Zura live-start notifications."}
                </p>
              )}
            </section>

            <aside className="space-y-6">
              <div className="rounded-[2rem] border border-[#E8DEC8] bg-white p-6 shadow-sm">
                <p className="text-xs font-semibold uppercase tracking-[0.22em] text-[#D4A73C]">Host</p>
                <div className="mt-4 flex items-center gap-4">
                  {session?.astrologer?.profile_image ? (
                    <img
                      src={resolveImageUrl(session.astrologer.profile_image)}
                      alt={session.astrologer.name}
                      className="h-16 w-16 rounded-2xl object-cover"
                    />
                  ) : (
                    <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-[#F6E8BF] text-2xl text-[#1E3557]">
                      <FaBroadcastTower />
                    </div>
                  )}
                  <div>
                    <h3 className="text-xl font-bold text-[#1E3557]">{session?.astrologer?.name || "Featured Astrologer"}</h3>
                    <p className="mt-1 text-sm text-gray-500">{session?.astrologer?.specialities || "Live spiritual guidance"}</p>
                  </div>
                </div>

                <div className="mt-5 grid gap-3 text-sm">
                  <div className="rounded-2xl bg-[#F8F9FC] px-4 py-3">
                    <p className="text-xs uppercase tracking-wide text-gray-400">Started At</p>
                    <p className="mt-1 font-semibold text-[#1E3557]">{formatLiveTime(session?.started_at)}</p>
                  </div>
                  <div className="rounded-2xl bg-[#F8F9FC] px-4 py-3">
                    <p className="text-xs uppercase tracking-wide text-gray-400">Status</p>
                    <p className="mt-1 font-semibold capitalize text-[#1E3557]">{session?.status || "offline"}</p>
                  </div>
                </div>
              </div>

              <div className="rounded-[2rem] border border-[#E8DEC8] bg-white p-6 shadow-sm">
                <h3 className="text-lg font-bold text-[#1E3557]">Live Comments</h3>
                <div className="mt-4 max-h-[340px] space-y-3 overflow-y-auto pr-1">
                  {visibleComments.length > 0 ? (
                    visibleComments.map((comment) => (
                      <div
                        key={comment.id}
                        className={`rounded-2xl border border-gray-100 bg-[#F8F9FC] px-4 py-3 ${
                          comment.is_pending ? "opacity-70" : ""
                        }`}
                      >
                        <div className="flex items-center justify-between gap-3">
                          <p className="text-sm font-bold text-[#1E3557]">{comment.user?.name || "Viewer"}</p>
                          <p className="text-[11px] text-gray-400">{formatLiveTime(comment.created_at)}</p>
                        </div>
                        <p className="mt-2 text-sm leading-6 text-gray-600">{comment.message}</p>
                      </div>
                    ))
                  ) : (
                    <div className="rounded-2xl bg-[#F8F9FC] px-4 py-6 text-center text-sm text-gray-500">
                      No comments yet.
                    </div>
                  )}
                </div>

                {user && session && (
                  <div className="mt-4 flex gap-3">
                    <input
                      type="text"
                      value={commentDraft}
                      onChange={(event) => setCommentDraft(event.target.value)}
                      onKeyDown={(event) => {
                        if (event.key === "Enter") {
                          event.preventDefault();
                          void handleSendComment();
                        }
                      }}
                      placeholder="Share your question or comment..."
                      className="flex-1 rounded-2xl border border-gray-200 bg-[#F8F9FC] px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                    />
                    <button
                      type="button"
                      onClick={() => void handleSendComment()}
                      disabled={!commentDraft.trim()}
                      className="inline-flex h-12 w-12 items-center justify-center rounded-2xl bg-[#D4A73C] text-[#1E3557] disabled:cursor-not-allowed disabled:opacity-50"
                    >
                      <FaPaperPlane />
                    </button>
                  </div>
                )}
              </div>
            </aside>
          </div>
        )}
      </main>

      <Footer />
    </div>
  );
}
