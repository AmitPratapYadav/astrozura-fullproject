import { useEffect, useMemo, useRef, useState } from "react";
import { Link } from "react-router-dom";
import { FaBroadcastTower, FaPaperPlane, FaPlay, FaPowerOff, FaVideo } from "react-icons/fa";

import api from "../api/axios";
import Footer from "../components/Footer";
import Navbar from "../components/Navbar";
import { useAuth } from "../context/AuthContext";
import { usePushNotifications } from "../context/PushNotificationsContext";
import { publishLiveStatusChange, subscribeToLiveStatusChanges } from "../lib/liveStatusBroadcast";

const ZEGO_BROADCAST_SCENARIO = 8;
const BACKEND_ORIGIN = import.meta.env.VITE_BACKEND_URL || "http://127.0.0.1:8000";
let zegoExpressEnginePromise = null;

const getZegoExpressEngineClass = async () => {
  if (!zegoExpressEnginePromise) {
    zegoExpressEnginePromise = import("zego-express-engine-webrtc").then(
      (module) => module.ZegoExpressEngine
    );
  }

  return zegoExpressEnginePromise;
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
  const engineRef = useRef(null);
  const localStreamRef = useRef(null);
  const playingStreamRef = useRef("");
  const liveRefreshTimerRef = useRef(null);
  const commentRefreshTimerRef = useRef(null);
  const autoJoinRequestedRef = useRef(false);
  const currentSessionIdRef = useRef(null);

  const isFeaturedAstrologer = Boolean(user?.role === "astrologer" && astrologerDetail?.is_featured);
  const isHost = Boolean(viewerConfig?.viewer?.role === "host");
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

  const teardownLiveRoom = () => {
    const engine = engineRef.current;

    if (engine && playingStreamRef.current) {
      try {
        engine.stopPlayingStream(playingStreamRef.current);
      } catch {}
    }

    if (engine && localStreamRef.current) {
      try {
        engine.stopPublishingStream(session?.stream_id || "");
      } catch {}
    }

    if (engine) {
      try {
        if (session?.room_id) {
          engine.logoutRoom(session.room_id);
        }
      } catch {}

      try {
        engine.destroyEngine();
      } catch {}
    }

    if (localStreamRef.current) {
      try {
        localStreamRef.current.getTracks().forEach((track) => track.stop());
      } catch {}
    }

    if (remoteVideoRef.current) {
      remoteVideoRef.current.srcObject = null;
    }

    if (localVideoRef.current) {
      localVideoRef.current.srcObject = null;
    }

    localStreamRef.current = null;
    playingStreamRef.current = "";
    engineRef.current = null;
    setLiveState("idle");
  };

  const connectToLiveSession = async (targetSession, viewer) => {
    const engine = await startEngine(targetSession, {
      zego: viewer.viewer.zego,
    });

    if (viewer.viewer.role === "host") {
      const localStream = await engine.createStream({
        camera: {
          audio: true,
          video: true,
        },
      });

      localStreamRef.current = localStream;
      if (localVideoRef.current) {
        localVideoRef.current.srcObject = localStream;
        await localVideoRef.current.play().catch(() => undefined);
      }

      engine.startPublishingStream(targetSession.stream_id, localStream);
      setLiveState("live");
      setLiveStatus("You are live now.");
      return;
    }

    const remoteStream = await engine.startPlayingStream(targetSession.stream_id).catch(() => null);
    if (remoteStream && remoteVideoRef.current) {
      playingStreamRef.current = targetSession.stream_id;
      remoteVideoRef.current.srcObject = remoteStream;
      await remoteVideoRef.current.play().catch(() => undefined);
    }

    setLiveState("watching");
    setLiveStatus("Watching the live broadcast.");
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

      if (engineRef.current) {
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

    if (sessionChanged && engineRef.current) {
      teardownLiveRoom();
    }

    if (autoJoinRequestedRef.current && user && viewer?.viewer?.zego && (sessionChanged || !engineRef.current)) {
      await connectToLiveSession(current, viewer);
    } else if (!silent && !engineRef.current) {
      setLiveStatus("Active spiritual live session is ready.");
    }

    return current;
  };

  useEffect(() => {
    let cancelled = false;

    const idlePreload =
      typeof window !== "undefined" && "requestIdleCallback" in window
        ? window.requestIdleCallback(() => {
            void getZegoExpressEngineClass().catch((error) => {
              console.error("Failed to preload ZEGO live SDK", error);
            });
          })
        : window.setTimeout(() => {
            void getZegoExpressEngineClass().catch((error) => {
              console.error("Failed to preload ZEGO live SDK", error);
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

  const startEngine = async (currentSession, config) => {
    const ZegoExpressEngine = await getZegoExpressEngineClass();
    const serverList = [config.zego.server_url, config.zego.secondary_server_url].filter(Boolean);
    const engine = new ZegoExpressEngine(config.zego.app_id, serverList, {
      scenario: ZEGO_BROADCAST_SCENARIO,
    });

    engine.setRoomScenario(ZEGO_BROADCAST_SCENARIO);

    engine.on("roomStateUpdate", (_roomId, state, errorCode) => {
      if (state === "CONNECTED") {
        setLiveState("connected");
        setLiveStatus(config.zego.role === "host" ? "Studio connected." : "Live stream connected.");
        return;
      }

      if (state === "CONNECTING") {
        setLiveState("connecting");
        setLiveStatus("Connecting live room...");
        return;
      }

      if (errorCode) {
        setLiveState("error");
        setLiveStatus(`Live room disconnected (${errorCode}).`);
      }
    });

    engine.on("roomStreamUpdate", async (_roomId, updateType, streamList) => {
      if (updateType !== "ADD") {
        return;
      }

      for (const stream of streamList) {
        if (stream.streamID !== currentSession?.stream_id || config.zego.role === "host") {
          continue;
        }

        try {
          const remoteStream = await engine.startPlayingStream(stream.streamID);
          playingStreamRef.current = stream.streamID;
          if (remoteVideoRef.current) {
            remoteVideoRef.current.srcObject = remoteStream;
            await remoteVideoRef.current.play().catch(() => undefined);
          }
          setLiveStatus("Watching the live broadcast.");
        } catch (error) {
          console.error("Failed to play live stream", error);
          setLiveState("error");
          setLiveStatus("Live stream could not be played.");
        }
      }
    });

    await engine.loginRoom(
      currentSession.room_id,
      config.zego.token,
      {
        userID: config.zego.user_id,
        userName: config.zego.user_name,
      },
      {
        userUpdate: true,
      }
    );

    engineRef.current = engine;
    return engine;
  };

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
        role: startedViewer?.role,
        zego: startedViewer?.zego,
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
      if (!viewer?.viewer?.zego) {
        throw new Error("Viewer access could not be prepared.");
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
      setComments((previous) =>
        previous.some((comment) => comment.id === response.data.comment?.id)
          ? previous
          : [...previous, response.data.comment]
      );
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
