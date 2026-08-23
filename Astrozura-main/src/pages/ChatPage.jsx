import { useEffect, useMemo, useRef, useState } from "react";
import { Link, useLocation, useNavigate, useParams } from "react-router-dom";
import {
  FaArrowLeft,
  FaCamera,
  FaCheckDouble,
  FaClock,
  FaCompress,
  FaComments,
  FaExpand,
  FaPaperclip,
  FaMicrophone,
  FaMicrophoneSlash,
  FaPaperPlane,
  FaPhoneAlt,
  FaPhoneSlash,
  FaPlayCircle,
  FaPowerOff,
  FaRegCircle,
  FaReply,
  FaSpinner,
  FaStop,
  FaTimes,
  FaTrash,
  FaUserCircle,
  FaVolumeUp,
} from "react-icons/fa";
import { ZegoExpressEngine } from "zego-express-engine-webrtc";

import api from "../api/axios";
import { useAuth } from "../context/AuthContext";
import { decryptChatText, encryptChatText } from "../lib/chatCrypto";
import { disconnectReverbEcho, getReverbEcho } from "../lib/reverbEcho";
import {
  endBookingSession,
  extendBookingSession,
  getBookingKundali,
  getBookingSession,
  pingBookingSession,
  startBookingSession,
} from "../api/sessionApi";
import {
  getRitualContextForBooking,
  sendRitualAstrologerResponse,
  sendRitualPaymentRequest,
} from "../api/bookingApi";
import { getDivisionalCharts, getMarriageMatching, searchLocation } from "../api/prokeralaApi";
import MatchDivisionalCharts, {
  MATCH_DIVISIONAL_CHART_TYPES,
  normalizeMatchCharts,
} from "../components/report/MatchDivisionalCharts";

const BACKEND_ORIGIN = import.meta.env.VITE_BACKEND_URL || "https://astrozura.com";
const CLOSED_STATUSES = new Set(["completed", "cancelled", "declined"]);
const ZEGO_STANDARD_VIDEO_CALL_SCENARIO = 4;
const TYPING_NOTIFY_INTERVAL_MS = 1400;
const TYPING_VISIBLE_TIMEOUT_MS = 3000;
const VOICE_NOTE_LIMIT_SECONDS = 300;
const CHAT_SYNC_INTERVAL_CONNECTED_MS = 15000;
const CHAT_SYNC_INTERVAL_FALLBACK_MS = 5000;
const TYPING_SYNC_INTERVAL_FALLBACK_MS = 5000;

const resolveImageUrl = (path) => {
  if (!path) return "";
  if (path.startsWith("http")) return path;
  return `${BACKEND_ORIGIN}${path.startsWith("/") ? path : `/${path}`}`;
};

const formatDateTime = (value) =>
  value
    ? new Date(value).toLocaleString("en-IN", {
      dateStyle: "medium",
      timeStyle: "short",
      timeZone: "Asia/Kolkata",
    })
    : "-";

const formatTime = (value) =>
  value
    ? new Date(value).toLocaleTimeString("en-IN", {
      hour: "2-digit",
      minute: "2-digit",
      timeZone: "Asia/Kolkata",
    })
    : "-";

const normalizeMessageTimestamp = (value) => {
  const timestamp = Number(value);

  if (!Number.isFinite(timestamp) || timestamp <= 0) {
    return Date.now();
  }

  const now = Date.now();
  const futureToleranceMs = 60 * 1000;

  return timestamp > now + futureToleranceMs ? now : timestamp;
};

const formatCountdown = (seconds) => {
  const safeSeconds = Number.isFinite(seconds) ? Math.max(0, Math.floor(seconds)) : 0;
  const hours = Math.floor(safeSeconds / 3600);
  const mins = Math.floor((safeSeconds % 3600) / 60);
  const secs = safeSeconds % 60;

  if (hours > 0) {
    return `${String(hours).padStart(2, "0")}:${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
  }

  return `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
};

const getRealtimeErrorMessage = (error, fallback) => {
  const code = error?.code ?? error?.response?.data?.code;

  if (code === 6000014) {
    return "Secure chat service is not active yet. Booking details are still available.";
  }

  return error?.message || error?.response?.data?.message || fallback;
};

const getCallErrorMessage = (error) => {
  const code = Number(error?.code ?? error?.response?.data?.code ?? error?.errorCode);

  if (code === 1103064) {
    return "Microphone permission is blocked in the browser. Allow microphone access and try again.";
  }

  if (code === 1103065) {
    return "The microphone is unavailable or already in use by another application.";
  }

  if (code === 1103061) {
    return "The browser could not capture microphone audio. Check device permissions and browser access.";
  }

  return error?.message || "Audio call could not be started.";
};

const ensureMicrophoneAccess = async () => {
  if (!navigator?.mediaDevices?.getUserMedia) {
    throw new Error("This browser does not support microphone capture APIs.");
  }

  let testStream = null;

  try {
    testStream = await navigator.mediaDevices.getUserMedia({
      audio: true,
      video: false,
    });
  } catch (error) {
    const errorName = error?.name;

    if (errorName === "NotAllowedError" || errorName === "SecurityError") {
      throw new Error("Microphone permission is blocked in the browser. Allow microphone access and try again.");
    }

    if (errorName === "NotFoundError") {
      throw new Error("No microphone device was found on this system.");
    }

    if (errorName === "NotReadableError" || errorName === "AbortError") {
      throw new Error("The browser could not capture microphone audio. Check device permissions and browser access.");
    }

    throw error;
  } finally {
    testStream?.getTracks?.().forEach((track) => track.stop());
  }
};

const getBookingId = (params, location) => {
  if (params.bookingId) return params.bookingId;
  const search = new URLSearchParams(location.search);
  return search.get("booking");
};

const formatBirthDetails = (birthDetails) => {
  if (!birthDetails) return [];

  return [
    birthDetails.date_of_birth ? `DOB: ${birthDetails.date_of_birth}` : null,
    birthDetails.time_of_birth ? `Time: ${birthDetails.time_of_birth}` : null,
    birthDetails.place_of_birth ? `Place: ${birthDetails.place_of_birth}` : null,
    birthDetails.gender ? `Gender: ${birthDetails.gender}` : null,
  ].filter(Boolean);
};

const mapStoredMessage = async (message, selfUserId, encryptionKey = "") => {
  const kind = ["image", "pdf", "video", "audio", "file"].includes(message?.message_type) ? message.message_type : "text";
  const mediaUrl = kind !== "text" ? resolveImageUrl(message?.media_url || "") : "";
  const text = kind === "text"
    ? await decryptChatText(message, encryptionKey)
    : message?.text || message?.attachment_name || "Attachment";
  const reply = message?.reply_to_message
    ? {
      id: message.reply_to_message.id,
      senderName: message.reply_to_message.sender_name || "Message",
      senderRole: message.reply_to_message.sender_role || "",
      kind: message.reply_to_message.message_type || "text",
      text: message.reply_to_message.message_type === "text"
        ? await decryptChatText(message.reply_to_message, encryptionKey)
        : message.reply_to_message.attachment_name || "Attachment",
    }
    : null;

  return {
    id: message?.zego_message_id || message?.client_uuid || `db-${message?.id}`,
    dbId: message?.id,
    senderUserId: message?.sender_user_id || "",
    text,
    kind,
    mediaUrl,
    attachmentName: message?.attachment_name || "",
    attachmentMime: message?.attachment_mime || "",
    attachmentSize: message?.attachment_size || 0,
    reply,
    clientUuid: message?.client_uuid || "",
    timestamp: normalizeMessageTimestamp(message?.timestamp),
    readAt: message?.read_at || null,
    isSelf: String(message?.sender_user_id || "") === selfUserId,
  };
};

const cleanKundaliLabel = (value) =>
  String(value || "")
    .replace(/[_-]+/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .replace(/\b\w/g, (letter) => letter.toUpperCase());

const cleanKundaliValue = (value) => {
  if (value === null || value === undefined || value === "") return "-";
  if (typeof value === "boolean") return value ? "Yes" : "No";
  if (typeof value === "number") return Number.isFinite(value) ? String(value) : "-";
  if (typeof value === "string") {
    return value.replace(/<br\s*\/?>/gi, "\n").replace(/<[^>]+>/g, "").trim() || "-";
  }
  if (Array.isArray(value)) {
    return value.map(cleanKundaliValue).filter((item) => item && item !== "-").join(", ") || "-";
  }
  if (typeof value === "object") {
    return cleanKundaliValue(value.name || value.title || value.value || value.report || value.description || "-");
  }
  return String(value);
};

const isPlainObject = (value) => value && typeof value === "object" && !Array.isArray(value);
const isPrimitiveKundaliValue = (value) =>
  value === null || value === undefined || ["string", "number", "boolean"].includes(typeof value);

const hiddenKundaliKeys = new Set([
  "endpoint",
  "provider",
  "provider_payload",
  "provider_sections",
  "raw_response",
  "api_url",
  "status",
]);
const imageKundaliKeys = new Set(["img_url", "image_url", "image", "img", "photo", "picture"]);

const shouldHideKundaliKey = (key, options = {}) => {
  const normalized = String(key || "").toLowerCase();
  if (hiddenKundaliKeys.has(normalized)) return true;
  if (options.hideImageKeys && imageKundaliKeys.has(normalized)) return true;
  return false;
};

const getKundaliEntries = (data, options = {}) =>
  Object.entries(data || {}).filter(([key, value]) => {
    if (shouldHideKundaliKey(key, options)) return false;
    if (value === null || value === undefined || value === "") return false;
    if (Array.isArray(value) && value.length === 0) return false;
    if (isPlainObject(value) && Object.keys(value).length === 0) return false;
    return true;
  });

const findKundaliImageUrl = (data) => {
  if (!isPlainObject(data)) return "";
  const imageEntry = Object.entries(data).find(
    ([key, value]) => imageKundaliKeys.has(String(key || "").toLowerCase()) && typeof value === "string" && value.trim(),
  );
  return imageEntry ? resolveImageUrl(imageEntry[1].trim()) : "";
};

const isFlatObjectArray = (items) =>
  Array.isArray(items) &&
  items.length > 0 &&
  items.every((item) => isPlainObject(item)) &&
  items.every((item) =>
    getKundaliEntries(item).every(
      ([, value]) => isPrimitiveKundaliValue(value) || (Array.isArray(value) && value.every(isPrimitiveKundaliValue)),
    ),
  );

const getFlatTableColumns = (rows) => {
  const columns = [];
  rows.forEach((row) => {
    getKundaliEntries(row).forEach(([key]) => {
      if (!columns.includes(key)) columns.push(key);
    });
  });
  return columns;
};

function KundaliFlatTable({ rows }) {
  const columns = getFlatTableColumns(rows);
  if (!columns.length) return null;

  return (
    <div className="overflow-x-auto rounded-2xl border border-[#E5D3A8] bg-white">
      <table className="w-full min-w-[620px] text-left text-sm">
        <thead className="bg-[#FFF2C1] text-[#6F4A04]">
          <tr>
            {columns.map((column) => (
              <th key={column} className="px-4 py-3 font-black">
                {cleanKundaliLabel(column)}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, index) => (
            <tr key={index} className="border-t border-gray-100 odd:bg-white even:bg-slate-50">
              {columns.map((column) => (
                <td key={column} className="whitespace-pre-line px-4 py-3 align-top text-[#1E3557]">
                  {cleanKundaliValue(row?.[column])}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function KundaliValueGrid({ entries }) {
  if (!entries.length) return null;

  return (
    <div className="grid gap-3 sm:grid-cols-2">
      {entries.map(([key, value]) => (
        <div key={key} className="rounded-2xl border border-[#E8D8B8] bg-white px-4 py-3 shadow-sm">
          <p className="text-xs font-black uppercase tracking-[0.14em] text-[#8A98AE]">{cleanKundaliLabel(key)}</p>
          <p className="mt-1 whitespace-pre-line break-words text-sm font-semibold leading-6 text-[#1E3557]">
            {cleanKundaliValue(value)}
          </p>
        </div>
      ))}
    </div>
  );
}

function CleanKundaliDataView({ data, title, hideImageKeys = false }) {
  if (data === null || data === undefined || data === "") return null;

  if (isPrimitiveKundaliValue(data)) {
    return (
      <div className="rounded-2xl border border-[#E8D8B8] bg-white px-4 py-3 text-sm font-semibold leading-6 text-[#1E3557]">
        {cleanKundaliValue(data)}
      </div>
    );
  }

  if (Array.isArray(data)) {
    if (!data.length) return null;
    if (isFlatObjectArray(data)) {
      return <KundaliFlatTable rows={data} />;
    }

    return (
      <div className="grid gap-3">
        {data.map((item, index) => (
          <div key={index} className="rounded-2xl border border-[#E8D8B8] bg-[#FFFDF7] p-4">
            <p className="mb-3 text-sm font-black text-[#6F4A04]">
              {title ? `${title} ${index + 1}` : `Item ${index + 1}`}
            </p>
            <CleanKundaliDataView data={item} hideImageKeys={hideImageKeys} />
          </div>
        ))}
      </div>
    );
  }

  if (!isPlainObject(data)) return null;

  const entries = getKundaliEntries(data, { hideImageKeys });
  const primitiveEntries = entries.filter(([, value]) => isPrimitiveKundaliValue(value));
  const nestedEntries = entries.filter(([, value]) => !isPrimitiveKundaliValue(value));

  return (
    <div className="space-y-4">
      <KundaliValueGrid entries={primitiveEntries} />
      {nestedEntries.map(([key, value]) => (
        <section key={key} className="overflow-hidden rounded-2xl border border-[#E5D3A8] bg-[#FFF9EC]">
          <h5 className="bg-[#FFF2C1] px-4 py-3 text-sm font-black text-[#6F4A04]">
            {cleanKundaliLabel(key)}
          </h5>
          <div className="p-4">
            <CleanKundaliDataView data={value} title={cleanKundaliLabel(key)} hideImageKeys={hideImageKeys} />
          </div>
        </section>
      ))}
    </div>
  );
}

function KundaliAccordion({ title, description, open, onToggle, children }) {
  return (
    <section className="overflow-hidden rounded-2xl border border-[#E5D3A8] bg-white shadow-sm">
      <button
        type="button"
        onClick={onToggle}
        className="flex w-full flex-col gap-2 bg-[#FFF3C7] px-4 py-4 text-left sm:flex-row sm:items-center sm:justify-between"
      >
        <span>
          <span className="block text-base font-black text-[#1E3557]">{title}</span>
          {description && <span className="mt-1 block text-xs font-semibold text-[#7A6B4A]">{description}</span>}
        </span>
        <span className="rounded-full bg-white px-3 py-1 text-xs font-black text-[#7A4C00]">
          {open ? "Hide" : "Open"}
        </span>
      </button>
      {open && <div className="space-y-4 p-4">{children}</div>}
    </section>
  );
}

function KundaliChartSelector({ charts }) {
  const validCharts = Array.isArray(charts) ? charts.filter((chart) => chart?.chart_svg) : [];
  const [selectedChart, setSelectedChart] = useState(validCharts[0]?.chart_id || validCharts[0]?.label || "");
  const activeChart =
    validCharts.find((chart) => (chart.chart_id || chart.label) === selectedChart) || validCharts[0];

  if (!validCharts.length) {
    return <p className="rounded-2xl bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-500">No chart returned.</p>;
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-2 sm:max-w-sm">
        <label className="text-xs font-black uppercase tracking-[0.16em] text-[#8A98AE]">Select Chart</label>
        <select
          value={activeChart?.chart_id || activeChart?.label || ""}
          onChange={(event) => setSelectedChart(event.target.value)}
          className="rounded-2xl border border-[#E5D3A8] bg-white px-4 py-3 text-sm font-bold text-[#1E3557] outline-none focus:border-[#D4A73C]"
        >
          {validCharts.map((chart) => {
            const value = chart.chart_id || chart.label;
            return (
              <option key={value} value={value}>
                {chart.label || chart.chart_id}
              </option>
            );
          })}
        </select>
      </div>
      {activeChart && (
        <div className="rounded-2xl border border-[#E5D3A8] bg-white p-4">
          <p className="mb-3 text-sm font-black text-[#1E3557]">{activeChart.label || activeChart.chart_id}</p>
          <div
            className="mx-auto max-w-[420px] overflow-hidden [&_svg]:h-auto [&_svg]:w-full"
            dangerouslySetInnerHTML={{ __html: activeChart.chart_svg }}
          />
        </div>
      )}
    </div>
  );
}

function GemstoneSuggestions({ data }) {
  if (!data) return null;
  const groups = isPlainObject(data) ? Object.entries(data) : [];
  if (!groups.length) return <CleanKundaliDataView data={data} />;

  return (
    <div className="grid gap-4 lg:grid-cols-3">
      {groups.map(([type, value]) => (
        <div key={type} className="rounded-2xl border border-[#E5D3A8] bg-[#FFFDF7] p-4">
          <h5 className="mb-3 text-sm font-black uppercase tracking-[0.14em] text-[#6F4A04]">
            {cleanKundaliLabel(type)}
          </h5>
          <CleanKundaliDataView data={value} />
        </div>
      ))}
    </div>
  );
}

function RudrakshaSuggestion({ data }) {
  if (!data) return null;
  const imageUrl = findKundaliImageUrl(data);

  return (
    <div className="rounded-2xl border border-[#E5D3A8] bg-[#FFFDF7] p-4">
      <div className="mb-4 flex flex-col gap-4 sm:flex-row sm:items-start">
        {imageUrl ? (
          <img
            src={imageUrl}
            alt={cleanKundaliValue(data?.name || "Rudraksha")}
            className="h-28 w-28 rounded-2xl border border-[#E5D3A8] bg-white object-contain p-2 shadow-sm"
          />
        ) : (
          <div className="flex h-28 w-28 items-center justify-center rounded-2xl border border-[#E5D3A8] bg-white text-xs font-bold text-[#8A98AE]">
            Image unavailable
          </div>
        )}
        <div className="min-w-0 flex-1">
          <h5 className="text-base font-black text-[#1E3557]">{cleanKundaliValue(data?.name || "Rudraksha")}</h5>
          {data?.recommend && <p className="mt-2 text-sm font-semibold leading-6 text-[#1E3557]">{cleanKundaliValue(data.recommend)}</p>}
        </div>
      </div>
      <CleanKundaliDataView data={data} hideImageKeys />
    </div>
  );
}

const matchSectionTitleMap = {
  "match-birth-details": "Birth Details",
  "match-astro-details": "Astro Details",
  "match-ashtakoot-points": "Ashtakoot Points",
  "match-dashakoot-points": "Dashakoot Points",
  "match-obstructions": "Obstructions",
  "match-manglik-report": "Manglik Report",
  "match-planet-details": "Planet Details",
  match_birth_details: "Birth Details",
  match_astro_details: "Astro Details",
  match_ashtakoot_points: "Ashtakoot Points",
  match_dashakoot_points: "Dashakoot Points",
  match_obstructions: "Obstructions",
  match_manglik_report: "Manglik Report",
  match_planet_details: "Planet Details",
};

const attachMatchCharts = (data, charts) => ({
  ...(data || {}),
  match_charts: charts,
});

const getMatchSectionPayload = (section) => {
  if (!section) return null;
  if (section.data) return section.data;
  if (!section.items || !isPlainObject(section.items)) return section;

  const firstItem = Object.values(section.items)[0];
  if (!firstItem) return null;
  return firstItem?.data || firstItem;
};

const getMatchReportSections = (result) => {
  const source = result?.provider_sections || result?.data?.provider_sections || [];
  if (Array.isArray(source) && source.length) {
    return source
      .map((section, index) => ({
        id: section.id || `match-section-${index}`,
        title: matchSectionTitleMap[section.id] || section.title || `Section ${index + 1}`,
        payload: getMatchSectionPayload(section),
      }))
      .filter((section) => section.payload);
  }

  const fallback = result?.data && isPlainObject(result.data) ? result.data : result;
  return getKundaliEntries(fallback)
    .filter(([key]) => !["message", "exceptions"].includes(String(key).toLowerCase()))
    .map(([key, value]) => ({
      id: key,
      title: matchSectionTitleMap[key] || cleanKundaliLabel(key),
      payload: value,
    }));
};

function MatchmakingResultView({ result }) {
  const [openSection, setOpenSection] = useState("");
  const sections = getMatchReportSections(result);
  const matchData = result?.data && isPlainObject(result.data) ? result.data : result;
  const score = matchData?.guna_milan;
  const message = matchData?.message;
  const exceptions = Array.isArray(matchData?.exceptions) ? matchData.exceptions : [];
  const matchCharts = matchData?.match_charts || result?.match_charts;

  if (!sections.length) {
    return <CleanKundaliDataView data={result?.data || result} />;
  }

  return (
    <div className="space-y-4">
      {(score || message || exceptions.length > 0) && (
        <div className="grid gap-3 rounded-2xl border border-[#EAD79D] bg-[#FFFDF7] p-4 md:grid-cols-3">
          {score && (
            <div className="rounded-2xl border border-[#E8D8B8] bg-white px-4 py-3">
              <p className="text-xs font-black uppercase tracking-[0.14em] text-[#8A98AE]">Guna Milan</p>
              <p className="mt-1 text-xl font-black text-[#1E3557]">
                {cleanKundaliValue(score.total_points)} / {cleanKundaliValue(score.maximum_points || 36)}
              </p>
            </div>
          )}
          {message && (
            <div className="rounded-2xl border border-[#E8D8B8] bg-white px-4 py-3 md:col-span-2">
              <p className="text-xs font-black uppercase tracking-[0.14em] text-[#8A98AE]">
                {cleanKundaliValue(message.type || "Compatibility")}
              </p>
              <p className="mt-1 text-sm font-semibold leading-6 text-[#1E3557]">
                {cleanKundaliValue(message.description || message)}
              </p>
            </div>
          )}
          {exceptions.length > 0 && (
            <div className="rounded-2xl border border-[#E8D8B8] bg-white px-4 py-3 md:col-span-3">
              <p className="text-xs font-black uppercase tracking-[0.14em] text-[#8A98AE]">Important Notes</p>
              <ul className="mt-2 list-disc space-y-1 pl-5 text-sm font-semibold leading-6 text-[#1E3557]">
                {exceptions.map((item, index) => (
                  <li key={index}>{cleanKundaliValue(item)}</li>
                ))}
              </ul>
            </div>
          )}
        </div>
      )}

      {sections.map((section) => (
        <KundaliAccordion
          key={section.id}
          title={section.title}
          open={openSection === section.id}
          onToggle={() => setOpenSection((current) => (current === section.id ? "" : section.id))}
        >
          <CleanKundaliDataView data={section.payload} />
          {section.id === "match-astro-details" && (
            <MatchDivisionalCharts charts={matchCharts} />
          )}
        </KundaliAccordion>
      ))}
    </div>
  );
}

const clientPlanetRows = (planets) => {
  const rows = Array.isArray(planets) ? planets : Object.values(planets || {}).find(Array.isArray) || [];
  return rows.map((planet) => ({
    planet: cleanKundaliValue(planet?.name || planet?.planet || planet?.full_name),
    sign: cleanKundaliValue(planet?.sign || planet?.zodiac || planet?.rasi),
    degree: cleanKundaliValue(planet?.degree || planet?.norm_degree || planet?.full_degree),
    nakshatra: cleanKundaliValue(planet?.nakshatra || planet?.nakshatra_name),
    house: cleanKundaliValue(planet?.house || planet?.house_number),
  }));
};

function ClientKundaliPanel({ data, loading, error }) {
  const [openSection, setOpenSection] = useState("");

  if (loading) {
    return (
      <div className="rounded-3xl border border-gray-200 bg-white p-6 shadow-sm">
        <div className="flex items-center gap-3 text-sm font-semibold text-[#1E3557]">
          <FaSpinner className="animate-spin" />
          Loading client Kundali...
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-3xl border border-red-100 bg-red-50 p-6 text-sm font-semibold text-red-700 shadow-sm">
        {error}
      </div>
    );
  }

  if (!data) return null;

  const birthRows = Object.entries(data.birth_details || {})
    .filter(([, value]) => value !== null && value !== undefined && value !== "")
    .map(([key, value]) => [cleanKundaliLabel(key), cleanKundaliValue(value)]);
  const planets = clientPlanetRows(data.planets);
  const toggleSection = (section) => setOpenSection((current) => (current === section ? "" : section));

  return (
    <div className="rounded-3xl border border-[#EFE3D1] bg-white p-6 shadow-sm">
      <h3 className="text-lg font-black text-[#1E3557]">Client Kundali</h3>
      <p className="mt-1 text-sm text-gray-500">Generated from the birth details saved with this booking.</p>

      {birthRows.length > 0 && (
        <div className="mt-5 grid gap-3 sm:grid-cols-2">
          {birthRows.slice(0, 8).map(([label, value]) => (
            <div key={label} className="rounded-2xl border border-gray-100 bg-[#F8F9FC] px-4 py-3">
              <p className="text-xs font-bold uppercase tracking-wide text-gray-400">{label}</p>
              <p className="mt-1 text-sm font-semibold text-[#1E3557]">{value}</p>
            </div>
          ))}
        </div>
      )}

      <div className="mt-5 space-y-4">
        <KundaliAccordion
          title="Astro Details"
          description="Planet positions and astrology details for the client."
          open={openSection === "astro"}
          onToggle={() => toggleSection("astro")}
        >
          {planets.length > 0 && <KundaliFlatTable rows={planets} />}
          <CleanKundaliDataView data={data.astro_details} />
        </KundaliAccordion>

        <KundaliAccordion
          title="Divisional Charts"
          description="Choose one chart to inspect at a time."
          open={openSection === "charts"}
          onToggle={() => toggleSection("charts")}
        >
          <KundaliChartSelector charts={data.charts} />
        </KundaliAccordion>

        <KundaliAccordion
          title="Life Predictions"
          description="Daily guidance from the saved birth details."
          open={openSection === "predictions"}
          onToggle={() => toggleSection("predictions")}
        >
          <CleanKundaliDataView data={data.predictions} />
        </KundaliAccordion>

        <KundaliAccordion
          title="Vimshottari Dasha"
          description="Current and major planetary periods."
          open={openSection === "dasha"}
          onToggle={() => toggleSection("dasha")}
        >
          <CleanKundaliDataView data={data.dasha} />
        </KundaliAccordion>

        <KundaliAccordion
          title="Gemstone & Rudraksha"
          description="Recommendations and remedies."
          open={openSection === "remedies"}
          onToggle={() => toggleSection("remedies")}
        >
          <section>
            <h5 className="mb-3 text-sm font-black text-[#1E3557]">Gemstone Suggestions</h5>
            <GemstoneSuggestions data={data.gemstones} />
          </section>
          <section>
            <h5 className="mb-3 text-sm font-black text-[#1E3557]">Rudraksha Suggestions</h5>
            <RudrakshaSuggestion data={data.rudraksha} />
          </section>
        </KundaliAccordion>

        <KundaliAccordion
          title="Mangal Dosha"
          open={openSection === "mangal"}
          onToggle={() => toggleSection("mangal")}
        >
          <CleanKundaliDataView data={data.doshas?.mangal} />
        </KundaliAccordion>

        <KundaliAccordion
          title="Pitra Dosha"
          open={openSection === "pitra"}
          onToggle={() => toggleSection("pitra")}
        >
          <CleanKundaliDataView data={data.doshas?.pitra} />
        </KundaliAccordion>

        <KundaliAccordion
          title="Kaal Sarp Dosha"
          open={openSection === "kaal-sarp"}
          onToggle={() => toggleSection("kaal-sarp")}
        >
          <CleanKundaliDataView data={data.doshas?.kaal_sarp} />
        </KundaliAccordion>

        <KundaliAccordion
          title="Krishnamurti Paddhati"
          description="KP planets, house cusps, birth chart, and significators."
          open={openSection === "kp"}
          onToggle={() => toggleSection("kp")}
        >
          <CleanKundaliDataView data={data.kp} />
        </KundaliAccordion>

        <KundaliAccordion
          title="Yogini Dasha"
          description="Current, major, and sub Yogini periods."
          open={openSection === "yogini"}
          onToggle={() => toggleSection("yogini")}
        >
          <CleanKundaliDataView data={data.yogini_dasha} />
        </KundaliAccordion>

        <KundaliAccordion
          title="Pooja Suggestions"
          open={openSection === "pooja"}
          onToggle={() => toggleSection("pooja")}
        >
          <CleanKundaliDataView data={data.puja_suggestions} />
        </KundaliAccordion>
      </div>
    </div>
  );
}

const emptyMatchPerson = {
  name: "",
  dob: "",
  time: "",
  place: "",
  coordinates: "",
};

const normalizeMatchDate = (value) => {
  if (!value) return "";
  const stringValue = String(value).slice(0, 10);
  if (/^\d{4}-\d{2}-\d{2}$/.test(stringValue)) return stringValue;
  const parts = String(value).split(/[-/]/);
  if (parts.length === 3 && parts[2]?.length === 4) {
    const [day, month, year] = parts;
    return `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
  }
  return stringValue;
};

const normalizeMatchTime = (value) => (value ? String(value).slice(0, 5) : "");

const coordinatesFromPlace = (place) => {
  const latitude = place?.coordinates?.latitude ?? place?.latitude ?? place?.lat;
  const longitude = place?.coordinates?.longitude ?? place?.longitude ?? place?.lon ?? place?.lng;
  return latitude !== undefined && longitude !== undefined ? `${latitude},${longitude}` : "";
};

function ChatMatchmakingTool({ clientBirthDetails, clientName = "" }) {
  const [form, setForm] = useState({
    male: { ...emptyMatchPerson },
    female: { ...emptyMatchPerson },
  });
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [placeSearch, setPlaceSearch] = useState({
    person: "",
    results: [],
    loading: false,
  });

  const clientCoordinates =
    clientBirthDetails?.coordinates ||
    (clientBirthDetails?.latitude && clientBirthDetails?.longitude
      ? `${clientBirthDetails.latitude},${clientBirthDetails.longitude}`
      : "");
  const clientProfile = {
    name: clientName || clientBirthDetails?.name || clientBirthDetails?.full_name || "Booked user",
    dob: normalizeMatchDate(clientBirthDetails?.date_of_birth || clientBirthDetails?.dob || ""),
    time: normalizeMatchTime(clientBirthDetails?.time_of_birth || clientBirthDetails?.birth_time || ""),
    place: clientBirthDetails?.birth_place || clientBirthDetails?.place || clientBirthDetails?.location || "",
    coordinates: clientCoordinates,
  };

  const updateField = (person, event) => {
    const { name, value } = event.target;
    setForm((current) => ({
      ...current,
      [person]: {
        ...current[person],
        [name]: value,
      },
    }));
  };

  const importClientAs = (person) => {
    setResult(null);
    setError("");
    setPlaceSearch({ person: "", results: [], loading: false });
    setForm((current) => ({
      ...current,
      [person]: clientProfile,
    }));
  };

  const handlePlaceSearch = async (person, value) => {
    setResult(null);
    setError("");
    setForm((current) => ({
      ...current,
      [person]: {
        ...current[person],
        place: value,
        coordinates: "",
      },
    }));

    if (value.trim().length < 3) {
      setPlaceSearch({ person, results: [], loading: false });
      return;
    }

    try {
      setPlaceSearch({ person, results: [], loading: true });
      const response = await searchLocation(value.trim(), "en");
      setPlaceSearch({
        person,
        results: Array.isArray(response?.data) ? response.data : [],
        loading: false,
      });
    } catch {
      setPlaceSearch({ person, results: [], loading: false });
    }
  };

  const selectPlace = (person, place) => {
    setForm((current) => ({
      ...current,
      [person]: {
        ...current[person],
        place: place?.name || current[person].place,
        coordinates: coordinatesFromPlace(place) || current[person].coordinates,
      },
    }));
    setPlaceSearch({ person: "", results: [], loading: false });
  };

  const buildIso = (date, time) => `${date}T${String(time || "00:00").slice(0, 5)}:00+05:30`;

  const generateMatch = async (event) => {
    event.preventDefault();
    setError("");
    setResult(null);

    if (!form.male.dob || !form.male.time || !form.male.coordinates || !form.female.dob || !form.female.time || !form.female.coordinates) {
      setError("Enter date, time, and coordinates for both Male and Female.");
      return;
    }

    try {
      setLoading(true);
      const boy = {
        coordinates: form.male.coordinates,
        dob: buildIso(form.male.dob, form.male.time),
      };
      const girl = {
        coordinates: form.female.coordinates,
        dob: buildIso(form.female.dob, form.female.time),
      };

      const response = await getMarriageMatching(girl.coordinates, girl.dob, boy.coordinates, boy.dob, {
        girl_timezone: "+05:30",
        boy_timezone: "+05:30",
        la: "en",
        detailed_report: true,
      });

      if (response?.status === "success" && response.data) {
        const [maleChartsResult, femaleChartsResult] = await Promise.allSettled([
          getDivisionalCharts(
            boy.dob,
            boy.coordinates,
            MATCH_DIVISIONAL_CHART_TYPES,
            "north-indian",
            { la: "en" },
          ),
          getDivisionalCharts(
            girl.dob,
            girl.coordinates,
            MATCH_DIVISIONAL_CHART_TYPES,
            "north-indian",
            { la: "en" },
          ),
        ]);

        setResult(attachMatchCharts(response.data, {
          male: maleChartsResult.status === "fulfilled" ? normalizeMatchCharts(maleChartsResult.value) : [],
          female: femaleChartsResult.status === "fulfilled" ? normalizeMatchCharts(femaleChartsResult.value) : [],
        }));
        return;
      }

      setError(response?.message || "Matchmaking result is unavailable.");
    } catch (matchError) {
      setError(matchError?.response?.data?.message || "Unable to generate matchmaking report.");
    } finally {
      setLoading(false);
    }
  };

  const renderPersonFields = (person, title) => (
    <div className="rounded-2xl border border-[#EAD79D] bg-[#FFFDF7] p-4">
      <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h5 className="text-base font-black text-[#1E3557]">{title}</h5>
          <p className="mt-1 text-xs font-semibold text-gray-500">Birth details used for matchmaking.</p>
        </div>
        <button
          type="button"
          onClick={() => importClientAs(person)}
          disabled={!clientProfile.dob || !clientProfile.time || !clientProfile.coordinates}
          className="rounded-xl border border-[#D4A73C] bg-[#FFF8E6] px-4 py-2 text-xs font-black text-[#7A4C00] disabled:cursor-not-allowed disabled:opacity-50"
        >
          Import booked user
        </button>
      </div>
      <div className="grid gap-3 sm:grid-cols-2">
        <div>
          <label className="text-xs font-bold uppercase tracking-wide text-gray-500">Name</label>
          <input
            name="name"
            value={form[person].name}
            onChange={(event) => updateField(person, event)}
            className="mt-1 w-full rounded-xl border px-3 py-2 text-sm"
            placeholder="Name"
          />
        </div>
        <div>
          <label className="text-xs font-bold uppercase tracking-wide text-gray-500">Date of Birth</label>
          <input
            type="date"
            name="dob"
            value={form[person].dob}
            onChange={(event) => updateField(person, event)}
            className="mt-1 w-full rounded-xl border px-3 py-2 text-sm"
          />
        </div>
        <div>
          <label className="text-xs font-bold uppercase tracking-wide text-gray-500">Time of Birth</label>
          <input
            type="time"
            name="time"
            value={form[person].time}
            onChange={(event) => updateField(person, event)}
            className="mt-1 w-full rounded-xl border px-3 py-2 text-sm"
          />
        </div>
        <div className="relative">
          <label className="text-xs font-bold uppercase tracking-wide text-gray-500">Birth Place</label>
          <input
            name="place"
            value={form[person].place}
            onChange={(event) => handlePlaceSearch(person, event.target.value)}
            className="mt-1 w-full rounded-xl border px-3 py-2 text-sm"
            placeholder="Search city, country"
            autoComplete="off"
          />
          {placeSearch.loading && placeSearch.person === person && (
            <div className="absolute right-3 top-9 h-4 w-4 animate-spin rounded-full border-2 border-[#D4A73C] border-t-transparent" />
          )}
          {placeSearch.person === person && placeSearch.results.length > 0 && (
            <div className="absolute z-30 mt-1 max-h-48 w-full overflow-y-auto rounded-xl border border-[#E5D3A8] bg-white shadow-xl">
              {placeSearch.results.map((place, index) => (
                <button
                  key={`${place?.name || "place"}-${index}`}
                  type="button"
                  onClick={() => selectPlace(person, place)}
                  className="block w-full border-b border-slate-100 px-3 py-2 text-left text-xs font-semibold text-[#1E3557] hover:bg-[#FFF8E6] last:border-0"
                >
                  {place?.name || "Unnamed place"}
                </button>
              ))}
            </div>
          )}
        </div>
        <div className="sm:col-span-2">
          <label className="text-xs font-bold uppercase tracking-wide text-gray-500">Coordinates</label>
          <input
            name="coordinates"
            value={form[person].coordinates}
            onChange={(event) => updateField(person, event)}
            className="mt-1 w-full rounded-xl border px-3 py-2 text-sm"
            placeholder="lat,lon"
          />
        </div>
      </div>
    </div>
  );

  return (
    <section className="mt-5 overflow-hidden rounded-3xl border border-[#EAD79D] bg-white shadow-sm">
      <div className="bg-[#FFF3C7] px-5 py-4">
        <h4 className="text-lg font-black text-[#1E3557]">Independent Matchmaking Report</h4>
        <p className="mt-1 text-sm font-semibold text-[#7A6B4A]">
          Import the booked user as Male or Female, then enter the second profile manually.
        </p>
      </div>
      <form onSubmit={generateMatch} className="space-y-4 p-4">
        <div className="grid gap-4 lg:grid-cols-2">
          {renderPersonFields("male", "Male Details")}
          {renderPersonFields("female", "Female Details")}
        </div>
        <button type="submit" disabled={loading} className="w-full rounded-xl bg-[#1E3557] px-5 py-3 text-sm font-bold text-white disabled:opacity-60">
          {loading ? "Generating Matchmaking..." : "Generate Matchmaking"}
        </button>
      </form>
      {error && <div className="mx-4 mb-4 rounded-xl bg-red-50 px-4 py-3 text-sm font-semibold text-red-700">{error}</div>}
      {result && (
        <div className="border-t border-[#EAD79D] p-4">
          <MatchmakingResultView result={result} />
        </div>
      )}
    </section>
  );
}

export default function ChatPage() {
  const { bookingId: routeBookingId } = useParams();
  const location = useLocation();
  const navigate = useNavigate();
  const { user } = useAuth();
  const bookingId = getBookingId({ bookingId: routeBookingId }, location);

  const [booking, setBooking] = useState(null);
  const [session, setSession] = useState(null);
  const [messages, setMessages] = useState([]);
  const [pendingMessages, setPendingMessages] = useState([]);
  const [draft, setDraft] = useState("");
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [pageError, setPageError] = useState("");
  const [banner, setBanner] = useState("");
  const [chatReady, setChatReady] = useState(false);
  const [chatStatus, setChatStatus] = useState("Connecting to room...");
  const [uploadingImage, setUploadingImage] = useState(false);
  const [messageLoadError, setMessageLoadError] = useState("");
  const [counterpartTyping, setCounterpartTyping] = useState(false);
  const [selectedReply, setSelectedReply] = useState(null);
  const [startingSession, setStartingSession] = useState(false);
  const [endingSession, setEndingSession] = useState(false);
  const [extendingDuration, setExtendingDuration] = useState(null);
  const [callLoading, setCallLoading] = useState(false);
  const [callState, setCallState] = useState("idle");
  const [callStatus, setCallStatus] = useState("Audio call is not connected.");
  const [callMuted, setCallMuted] = useState(false);
  const [callAudioBlocked, setCallAudioBlocked] = useState(false);
  const [remoteParticipantCount, setRemoteParticipantCount] = useState(0);
  const [clockNowMs, setClockNowMs] = useState(() => Date.now());
  const [serverClockOffsetMs, setServerClockOffsetMs] = useState(0);
  const [clientKundali, setClientKundali] = useState(null);
  const [clientKundaliLoading, setClientKundaliLoading] = useState(false);
  const [clientKundaliError, setClientKundaliError] = useState("");
  const [isChatFullscreen, setIsChatFullscreen] = useState(false);
  const [hasNewMessages, setHasNewMessages] = useState(false);
  const [recordingState, setRecordingState] = useState("idle");
  const [recordingSeconds, setRecordingSeconds] = useState(0);
  const [recordedAudio, setRecordedAudio] = useState(null);
  const [ritualContext, setRitualContext] = useState(null);
  const [ritualReply, setRitualReply] = useState("");
  const [ritualPaymentAmount, setRitualPaymentAmount] = useState("");
  const [ritualPaymentNote, setRitualPaymentNote] = useState("");
  const [sendingRitualAction, setSendingRitualAction] = useState(false);

  const messageViewportRef = useRef(null);
  const echoChannelRef = useRef(null);
  const echoContextKeyRef = useRef("");
  const zegoEngineRef = useRef(null);
  const localStreamRef = useRef(null);
  const publishedStreamIdRef = useRef("");
  const remoteAudioMapRef = useRef(new Map());
  const activeRemoteStreamsRef = useRef(new Set());
  const pollTimerRef = useRef(null);
  const pingTimerRef = useRef(null);
  const chatSyncTimerRef = useRef(null);
  const typingStatusTimerRef = useRef(null);
  const fileInputRef = useRef(null);
  const shouldStickToBottomRef = useRef(true);
  const previousMessageCountRef = useRef(0);
  const typingClearTimerRef = useRef(null);
  const lastTypingNotifyAtRef = useRef(0);
  const cameraInputRef = useRef(null);
  const mediaRecorderRef = useRef(null);
  const recordingStreamRef = useRef(null);
  const recordingChunksRef = useRef([]);
  const recordingTimerRef = useRef(null);
  const forceScrollToBottomRef = useRef(false);
  const lastMarkedReadKeyRef = useRef("");
  const recordingCancelledRef = useRef(false);

  const isAstrologerViewer =
    user?.id && booking ? Number(user.id) === Number(booking.astrologer_id) : user?.role === "astrologer";
  const counterpart = useMemo(() => {
    if (!booking) return null;
    return isAstrologerViewer ? booking.user : booking.astrologer;
  }, [booking, isAstrologerViewer]);
  const astrologerDetail =
    booking?.astrologer?.astrologer_detail || booking?.astrologer?.astrologerDetail || null;
  const counterpartImage = useMemo(() => {
    if (!booking || !counterpart) return "";
    if (isAstrologerViewer) {
      return resolveImageUrl(counterpart.profile_image || counterpart.avatar || "");
    }

    return resolveImageUrl(
      counterpart?.astrologer_detail?.profile_image ||
        counterpart?.astrologerDetail?.profile_image ||
        counterpart?.profile_image ||
        astrologerDetail?.profile_image ||
        ""
    );
  }, [booking, counterpart, isAstrologerViewer, astrologerDetail]);
  const callEnabled = booking?.consultation_type === "call";
  const currentUserId = user?.id ? String(user.id) : "";
  const viewerZegoId = session?.viewer?.zego_user_id || "";
  const isClosed = CLOSED_STATUSES.has(booking?.status) || session?.state === "closed";
  const chatServiceEnabled = Boolean(session?.chat?.channel_name);
  const canSendChatMessage = Boolean(session?.is_live && !isClosed);
  const canJoinCall = Boolean(callEnabled && session?.can_join && session?.zego?.call);
  const isCallConnected = callState === "live" || callState === "room-connected";
  const backHref = isAstrologerViewer ? "/astrologer/dashboard" : "/my-bookings";
  const scheduledStartLabel = formatDateTime(session?.scheduled_at || booking?.scheduled_at);
  const scheduledEndLabel = formatDateTime(session?.scheduled_end_at || booking?.ends_at);
  const effectiveNowMs = clockNowMs + serverClockOffsetMs;
  const effectiveNow = useMemo(() => new Date(effectiveNowMs), [effectiveNowMs]);
  const displayRemainingSeconds = useMemo(() => {
    if (!session) return 0;

    if (isClosed) {
      return 0;
    }

    const targetTime = session.is_live ? session.scheduled_end_at : session.scheduled_at;
    if (!targetTime) {
      return Math.max(0, Math.floor(session.remaining_seconds || 0));
    }

    const targetMs = new Date(targetTime).getTime();
    if (!Number.isFinite(targetMs)) {
      return Math.max(0, Math.floor(session.remaining_seconds || 0));
    }

    return Math.max(0, Math.floor((targetMs - effectiveNow.getTime()) / 1000));
  }, [effectiveNow, isClosed, session]);
  const sessionTimerLabel = session?.is_live ? "Remaining Time" : "Starts In";
  const showLowTimeWarning = Boolean(session?.is_live && displayRemainingSeconds > 0 && displayRemainingSeconds <= 120);
  const extensionOptions = session?.extension?.options || [];
  const availableExtensionOptions = extensionOptions.filter((option) => option.is_available);
  const isRitualConsultation = booking?.service_context === "ritual-consultation";
  const canSendRitualFollowUp = Boolean(isAstrologerViewer && isRitualConsultation && booking?.status === "completed" && ritualContext?.id);

  useEffect(() => {
    setClientKundali(null);
    setClientKundaliError("");
    setClientKundaliLoading(false);
  }, [booking?.id]);

  const loadClientKundali = async () => {
    if (!booking?.id || !isAstrologerViewer || clientKundaliLoading) return;
    try {
      setClientKundaliLoading(true);
      setClientKundaliError("");
      const response = await getBookingKundali(booking.id);
      setClientKundali(response?.data || null);
    } catch (error) {
      setClientKundali(null);
      setClientKundaliError(error?.response?.data?.message || "Client Kundali is unavailable for this booking.");
    } finally {
      setClientKundaliLoading(false);
    }
  };

  const sessionHeadline = useMemo(() => {
    if (isClosed) {
      return "This consultation has ended.";
    }

    if (callEnabled) {
      if (session?.is_live) {
        return "Audio consultation is live now.";
      }

      if (isAstrologerViewer && session?.can_start) {
        return "Start the call when you are ready.";
      }

      if (!isAstrologerViewer && session?.can_join) {
        return "Waiting for the astrologer to start the call.";
      }

      return "Audio consultation is scheduled.";
    }

    if (chatReady) {
      return "Live chat is active.";
    }

    if (session?.can_join) {
      return "Chat room access is open.";
    }

    return "Chat room access is scheduled.";
  }, [callEnabled, chatReady, isAstrologerViewer, isClosed, session?.can_join, session?.can_start, session?.is_live]);
  const sessionSummary = useMemo(() => {
    if (callEnabled) {
      return `Scheduled start: ${scheduledStartLabel}. Scheduled end: ${scheduledEndLabel}.`;
    }

    if (chatReady) {
      return `Scheduled start: ${scheduledStartLabel}. Scheduled end: ${scheduledEndLabel}. Messages and attachments are live.`;
    }

    return `Scheduled start: ${scheduledStartLabel}. Scheduled end: ${scheduledEndLabel}.`;
  }, [callEnabled, chatReady, scheduledEndLabel, scheduledStartLabel]);
  const callActionLabel = useMemo(() => {
    if (callLoading || callState === "connecting") {
      return "Connecting...";
    }

    if (isCallConnected) {
      return "Audio Call Connected";
    }

    if (!isAstrologerViewer && !session?.is_live) {
      return "Waiting for Astrologer";
    }

    if (callState === "error") {
      return "Reconnect Audio Call";
    }

    return "Join Audio Call";
  }, [callLoading, callState, isAstrologerViewer, isCallConnected, session?.is_live]);

  const visibleMessages = useMemo(
    () => [...messages, ...pendingMessages].sort((left, right) => left.timestamp - right.timestamp),
    [messages, pendingMessages]
  );

  useEffect(() => {
    const viewport = messageViewportRef.current;

    if (!viewport) {
      previousMessageCountRef.current = visibleMessages.length;
      return;
    }

    const wasEmpty = previousMessageCountRef.current === 0;
    const messageWasAdded = visibleMessages.length > previousMessageCountRef.current;
    const latestMessage = visibleMessages[visibleMessages.length - 1];
    const shouldForceScroll = forceScrollToBottomRef.current || latestMessage?.isSelf;

    if (shouldForceScroll || shouldStickToBottomRef.current || wasEmpty) {
      viewport.scrollTop = viewport.scrollHeight;
      setHasNewMessages(false);
      shouldStickToBottomRef.current = true;
    } else if (messageWasAdded && latestMessage && !latestMessage.isSelf) {
      setHasNewMessages(true);
    }

    forceScrollToBottomRef.current = false;
    previousMessageCountRef.current = visibleMessages.length;
  }, [visibleMessages]);

  useEffect(() => {
    if (!isChatFullscreen) return undefined;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";

    return () => {
      document.body.style.overflow = previousOverflow;
    };
  }, [isChatFullscreen]);

  useEffect(() => {
    if (!banner) return undefined;
    const timer = window.setTimeout(() => setBanner(""), 2800);
    return () => window.clearTimeout(timer);
  }, [banner]);

  useEffect(() => {
    if (!visibleMessages.some((message) => message.dbId && !message.isSelf && !message.readAt)) {
      return undefined;
    }

    const timer = window.setTimeout(() => {
      void markVisibleMessagesRead();
    }, 350);

    return () => window.clearTimeout(timer);
  }, [bookingId, currentUserId, visibleMessages]);

  useEffect(() => {
    const timer = window.setInterval(() => setClockNowMs(Date.now()), 1000);
    return () => window.clearInterval(timer);
  }, []);

  const resetMessages = (nextMessages) => {
    setMessages(nextMessages);
  };

  const scrollMessagesToBottom = () => {
    const viewport = messageViewportRef.current;
    shouldStickToBottomRef.current = true;
    forceScrollToBottomRef.current = true;
    setHasNewMessages(false);

    if (viewport) {
      window.requestAnimationFrame(() => {
        viewport.scrollTop = viewport.scrollHeight;
      });
    }
  };

  const handleMessageViewportScroll = () => {
    const viewport = messageViewportRef.current;

    if (!viewport) return;

    const distanceFromBottom = viewport.scrollHeight - viewport.scrollTop - viewport.clientHeight;
    shouldStickToBottomRef.current = distanceFromBottom < 80;
    if (shouldStickToBottomRef.current) {
      setHasNewMessages(false);
    }
  };

  const destroyChatConnection = () => {
    if (echoChannelRef.current && echoContextKeyRef.current) {
      try {
        echoChannelRef.current.unsubscribe?.();
      } catch {
        /* Ignore cleanup failures. */
      }
      disconnectReverbEcho();
    }

    echoChannelRef.current = null;
    echoContextKeyRef.current = "";
    setChatReady(false);
    setChatStatus("Chat room disconnected.");
  };

  const stopAllRemoteAudio = () => {
    remoteAudioMapRef.current.forEach((audioEl) => {
      audioEl.pause();
      audioEl.srcObject = null;
    });
    remoteAudioMapRef.current.clear();
    activeRemoteStreamsRef.current.clear();
    setRemoteParticipantCount(0);
  };

  const destroyCallConnection = (roomId = "") => {
    const engine = zegoEngineRef.current;

    if (engine && publishedStreamIdRef.current) {
      try {
        engine.stopPublishingStream(publishedStreamIdRef.current);
      } catch {
        /* Ignore cleanup failures. */
      }
    }

    if (engine) {
      activeRemoteStreamsRef.current.forEach((streamId) => {
        try {
          engine.stopPlayingStream(streamId);
        } catch {
          /* Ignore cleanup failures. */
        }
      });

      try {
        if (roomId) {
          engine.logoutRoom(roomId);
        }
      } catch {
        /* Ignore cleanup failures. */
      }

      try {
        engine.destroyEngine();
      } catch {
        /* Ignore cleanup failures. */
      }
    }

    if (localStreamRef.current) {
      try {
        localStreamRef.current.getTracks().forEach((track) => track.stop());
      } catch {
        /* Ignore cleanup failures. */
      }
    }

    stopAllRemoteAudio();
    localStreamRef.current = null;
    zegoEngineRef.current = null;
    publishedStreamIdRef.current = "";
    setCallMuted(false);
    setCallAudioBlocked(false);
    setCallState("idle");
    setCallStatus("Audio call is not connected.");
  };

  const teardownRealtime = async () => {
    destroyCallConnection(session?.rooms?.call || "");
    destroyChatConnection();
    disconnectReverbEcho();
  };

  const fetchPersistedMessages = async () => {
    if (!bookingId) {
      return;
    }

    try {
      const response = await api.get(`/bookings/${bookingId}/messages`);
      const normalized = (await Promise.all(
        (response.data?.messages || []).map((message) =>
          mapStoredMessage(message, currentUserId, session?.chat?.encryption_key || "")
        )
      ))
        .filter((message) => message.text || message.mediaUrl)
        .sort((left, right) => left.timestamp - right.timestamp);

      setMessages(normalized);
      setMessageLoadError("");
      setPendingMessages((previous) =>
        previous.filter(
          (pendingMessage) =>
            !normalized.some(
              (storedMessage) =>
                (pendingMessage.clientUuid &&
                  storedMessage.clientUuid &&
                  pendingMessage.clientUuid === storedMessage.clientUuid) ||
                pendingMessage.id === storedMessage.id
            )
        )
      );
    } catch (error) {
      console.error("Failed to load stored chat messages", error);
      setMessageLoadError(error?.response?.data?.message || "Messages could not be loaded.");
      throw error;
    }
  };

  const persistBookingMessage = async ({
    messageType,
    text = "",
    mediaUrl = "",
    attachmentName = "",
    attachmentMime = "",
    attachmentSize = 0,
    clientUuid = "",
    replyToMessageId = null,
  }) => {
    if (!bookingId) {
      return null;
    }

    const payload = {
      message_type: messageType,
      client_uuid:
        clientUuid ||
        (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function"
          ? crypto.randomUUID()
          : `${Date.now()}-${Math.random().toString(36).slice(2)}`),
      reply_to_message_id: replyToMessageId || null,
    };

    if (messageType !== "text") {
      payload.media_url = mediaUrl;
      payload.text = text || attachmentName || "Attachment";
      payload.attachment_name = attachmentName || null;
      payload.attachment_mime = attachmentMime || null;
      payload.attachment_size = attachmentSize || null;
    } else {
      Object.assign(payload, await encryptChatText(text, session?.chat?.encryption_key || ""));
    }

    const response = await api.post(`/bookings/${bookingId}/messages`, payload);
    return response.data?.message
      ? mapStoredMessage(response.data.message, currentUserId, session?.chat?.encryption_key || "")
      : null;
  };

  const createOptimisticMessage = ({ clientUuid, text = "", kind = "text", mediaUrl = "", attachmentName = "", reply = null }) => ({
    id: `optimistic-${clientUuid}`,
    senderUserId: viewerZegoId || currentUserId,
    text: kind === "text" ? text : attachmentName || "Attachment",
    kind,
    mediaUrl,
    attachmentName,
    reply,
    clientUuid,
    timestamp: Date.now(),
    readAt: null,
    isSelf: true,
  });

  const removeOptimisticMessage = (clientUuid) => {
    if (!clientUuid) {
      return;
    }

    setPendingMessages((previous) => previous.filter((message) => message.clientUuid !== clientUuid));
  };

  const sendTypingCommand = (isTyping) => {
    if (!bookingId || !canSendChatMessage) {
      return;
    }

    if (isTyping) {
      const now = Date.now();
      if (now - lastTypingNotifyAtRef.current < TYPING_NOTIFY_INTERVAL_MS) {
        return;
      }
      lastTypingNotifyAtRef.current = now;
    } else {
      lastTypingNotifyAtRef.current = 0;
    }

    try {
      echoChannelRef.current?.whisper?.("typing", {
        booking_id: bookingId,
        sender_id: currentUserId,
        sender_role: session?.viewer?.role || "",
        is_typing: isTyping,
        sent_at: Date.now(),
      });
    } catch (error) {
      console.error("Failed to whisper typing status", error);
    }

    api.post(`/bookings/${bookingId}/typing`, { is_typing: isTyping }).catch((typingError) => {
      console.error("Failed to send typing status", typingError);
    });
  };

  const clearCounterpartTyping = () => {
    setCounterpartTyping(false);
    if (typingClearTimerRef.current) {
      window.clearTimeout(typingClearTimerRef.current);
      typingClearTimerRef.current = null;
    }
  };

  const showCounterpartTyping = () => {
    setCounterpartTyping(true);

    if (typingClearTimerRef.current) {
      window.clearTimeout(typingClearTimerRef.current);
    }

    typingClearTimerRef.current = window.setTimeout(() => {
      setCounterpartTyping(false);
      typingClearTimerRef.current = null;
    }, TYPING_VISIBLE_TIMEOUT_MS);
  };

  const handleDraftChange = (value) => {
    setDraft(value);
    sendTypingCommand(value.trim().length > 0);
  };

  const fetchTypingStatus = async () => {
    if (!bookingId || !canSendChatMessage) {
      clearCounterpartTyping();
      return;
    }

    const response = await api.get(`/bookings/${bookingId}/typing-status`);
    if (response.data?.is_typing) {
      showCounterpartTyping();
    } else {
      clearCounterpartTyping();
    }
  };

  const markVisibleMessagesRead = async () => {
    if (!bookingId || !currentUserId) {
      return;
    }

    const unreadIncomingIds = visibleMessages
      .filter((message) => message.dbId && !message.isSelf && !message.readAt)
      .map((message) => message.dbId)
      .sort((left, right) => Number(left) - Number(right));

    if (!unreadIncomingIds.length) {
      lastMarkedReadKeyRef.current = "";
      return;
    }

    const readKey = unreadIncomingIds.join(",");
    if (lastMarkedReadKeyRef.current === readKey) {
      return;
    }

    lastMarkedReadKeyRef.current = readKey;

    try {
      await api.post(`/bookings/${bookingId}/messages/read`);
      const readAt = Date.now();
      setMessages((previous) =>
        previous.map((message) =>
          unreadIncomingIds.includes(message.dbId) ? { ...message, readAt } : message
        )
      );
    } catch (error) {
      console.error("Failed to mark chat messages as read", error);
      lastMarkedReadKeyRef.current = "";
    }
  };

  const ensureChatConnection = async (currentBooking, currentSession) => {
    if (!currentSession?.chat?.channel_name) {
      if (echoChannelRef.current) {
        destroyChatConnection();
      }
      return;
    }

    const chatConfig = currentSession.chat;
    const roomKey = `${chatConfig.app_key}:${chatConfig.host}:${chatConfig.port}:${chatConfig.channel_name}`;

    if (echoChannelRef.current && echoContextKeyRef.current === roomKey) {
      setChatReady(true);
      setChatStatus(currentSession.is_live ? "Chat connected." : "Waiting for astrologer to start the chat.");
      return;
    }

    destroyChatConnection();

    const echo = getReverbEcho(chatConfig);
    const channel = echo.private(chatConfig.channel_name);
    echoChannelRef.current = channel;
    echoContextKeyRef.current = roomKey;

    channel.listen(".booking.message.created", async (payload) => {
      if (String(payload?.booking_id || "") !== String(currentBooking?.id || bookingId || "")) {
        return;
      }

      const incoming = await mapStoredMessage(payload.message, currentUserId, chatConfig.encryption_key || "");
      setMessages((previous) => [
        ...previous.filter(
          (message) =>
            message.id !== incoming.id &&
            (!message.clientUuid || !incoming.clientUuid || message.clientUuid !== incoming.clientUuid)
        ),
        incoming,
      ].sort((left, right) => left.timestamp - right.timestamp));
      removeOptimisticMessage(incoming.clientUuid);
    });

    channel.listen(".booking.typing", (payload) => {
      if (String(payload?.sender_id || "") === currentUserId) {
        return;
      }

      if (payload?.is_typing) {
        showCounterpartTyping();
      } else {
        clearCounterpartTyping();
      }
    });

    channel.listenForWhisper("typing", (payload) => {
      if (String(payload?.sender_id || "") === currentUserId) {
        return;
      }

      if (payload?.is_typing) {
        showCounterpartTyping();
      } else {
        clearCounterpartTyping();
      }
    });

    channel.listen(".booking.session.changed", () => {
      void refreshSession({ silent: true });
    });

    setChatReady(true);
    setChatStatus(currentSession.is_live ? "Chat connected." : "Waiting for astrologer to start the chat.");
  };

  const playRemoteStream = async (engine, streamId) => {
    if (activeRemoteStreamsRef.current.has(streamId)) {
      return;
    }

    const mediaStream = await engine.startPlayingStream(streamId);
    const audioEl = new Audio();
    audioEl.autoplay = true;
    audioEl.playsInline = true;
    audioEl.srcObject = mediaStream;

    activeRemoteStreamsRef.current.add(streamId);
    remoteAudioMapRef.current.set(streamId, audioEl);
    setRemoteParticipantCount(activeRemoteStreamsRef.current.size);

    try {
      await audioEl.play();
      setCallAudioBlocked(false);
      return { playbackBlocked: false };
    } catch (error) {
      console.warn("Remote audio playback needs user activation", error);
      setCallAudioBlocked(true);
      setCallStatus("Remote audio is ready. Tap Enable Audio to hear the call.");
      return { playbackBlocked: true };
    }
  };

  const stopRemoteStream = (engine, streamId) => {
    try {
      engine.stopPlayingStream(streamId);
    } catch {
      /* Ignore cleanup failures. */
    }

    const audioEl = remoteAudioMapRef.current.get(streamId);
    if (audioEl) {
      audioEl.pause();
      audioEl.srcObject = null;
      remoteAudioMapRef.current.delete(streamId);
    }

    activeRemoteStreamsRef.current.delete(streamId);
    setRemoteParticipantCount(activeRemoteStreamsRef.current.size);
  };

  const connectAudioRoom = async (currentSession) => {
    if (!currentSession?.zego?.call || !currentSession?.rooms?.call) {
      throw new Error("Audio room is not available for this consultation.");
    }

    if (zegoEngineRef.current) {
      return zegoEngineRef.current;
    }

    const callConfig = currentSession.zego.call;
    const serverList = [callConfig.server_url, callConfig.secondary_server_url].filter(Boolean);
    const engine = new ZegoExpressEngine(callConfig.app_id, serverList, {
      scenario: ZEGO_STANDARD_VIDEO_CALL_SCENARIO,
    });

    engine.setRoomScenario(ZEGO_STANDARD_VIDEO_CALL_SCENARIO);

    engine.on("roomStateUpdate", (_roomId, state, errorCode) => {
      if (state === "CONNECTED") {
        setCallState("room-connected");
        setCallStatus("Audio room connected.");
        return;
      }

      if (state === "CONNECTING") {
        setCallState("connecting");
        setCallStatus("Connecting audio room...");
        return;
      }

      if (errorCode) {
        setCallState("error");
        setCallStatus(`Audio room disconnected (${errorCode}).`);
        return;
      }

      setCallState("idle");
      setCallStatus("Audio room disconnected.");
    });

    engine.on("roomUserUpdate", (_roomId, updateType, userList) => {
      if (updateType === "ADD") {
        setRemoteParticipantCount((count) => count + userList.length);
      }

      if (updateType === "DELETE") {
        setRemoteParticipantCount((count) => Math.max(0, count - userList.length));
      }
    });

    engine.on("roomStreamUpdate", async (_roomId, updateType, streamList) => {
      if (updateType === "DELETE") {
        streamList.forEach((stream) => stopRemoteStream(engine, stream.streamID));
        return;
      }

      for (const stream of streamList) {
        if (stream?.user?.userID === currentSession.viewer.zego_user_id) {
          continue;
        }

        try {
          const playback = await playRemoteStream(engine, stream.streamID);
          if (!playback?.playbackBlocked) {
            setCallStatus("Remote participant connected.");
          }
        } catch (error) {
          console.error("Failed to play remote stream", error);
          setCallState("error");
          setCallStatus("Remote audio could not be played.");
        }
      }
    });

    engine.on("publisherStateUpdate", (_streamId, state, errorCode) => {
      if (state === "PUBLISHING") {
        setCallStatus("Publishing microphone audio...");
        return;
      }

      if (state === "PUBLISHING_SUCCESS") {
        setCallState("live");
        setCallStatus("Microphone is live.");
        return;
      }

      if (errorCode) {
        setCallState("error");
        setCallStatus(`Microphone could not publish audio (${errorCode}).`);
      }
    });

    engine.on("playerStateUpdate", (_streamId, state, errorCode) => {
      if (state === "PLAYING") {
        setCallStatus("Connecting remote audio...");
        return;
      }

      if (state === "PLAYING_SUCCESS") {
        setCallStatus("Remote audio connected.");
        return;
      }

      if (errorCode) {
        setCallState("error");
        setCallStatus(`Remote audio could not connect (${errorCode}).`);
      }
    });

    const capability = await engine.checkSystemRequirements("webRTC");

    if (capability?.webRTC === false || capability?.result === false) {
      throw new Error("This browser does not support ZEGO WebRTC calls in the current environment.");
    }

    const loginResult = await engine.loginRoom(
      currentSession.rooms.call,
      callConfig.token,
      {
        userID: callConfig.user_id,
        userName: callConfig.user_name,
      },
      {
        userUpdate: true,
      }
    );

    if (loginResult === false || loginResult?.errorCode) {
      throw new Error(`Audio room login failed${loginResult?.errorCode ? ` (${loginResult.errorCode})` : ""}.`);
    }

    zegoEngineRef.current = engine;
    return engine;
  };

  const startLocalAudio = async (engine, currentSession) => {
    if (localStreamRef.current && publishedStreamIdRef.current) {
      return;
    }

    const localStream = await engine.createStream({
      camera: {
        audio: true,
        video: false,
      },
    });

    localStreamRef.current = localStream;
    const streamId = currentSession.rooms.stream;
    publishedStreamIdRef.current = streamId;
    const publishResult = await engine.startPublishingStream(streamId, localStream);

    if (publishResult === false || publishResult?.errorCode) {
      throw new Error(`Microphone audio publish failed${publishResult?.errorCode ? ` (${publishResult.errorCode})` : ""}.`);
    }

    setCallState("live");
    setCallStatus("Audio call is live.");
  };

  const refreshSession = async (options = {}) => {
    const { silent = false } = options;

    if (!bookingId) {
      setLoading(false);
      setPageError("A valid booking session was not provided.");
      return;
    }

    try {
      if (!silent) {
        setPageError("");
      }

      if (!silent && !loading) {
        setRefreshing(true);
      }

      const response = await getBookingSession(bookingId);
      setBooking(response.booking);
      setSession(response.session);
      if (response.booking?.service_context === "ritual-consultation") {
        try {
          const ritualResponse = await getRitualContextForBooking(bookingId);
          setRitualContext(ritualResponse?.ritual_booking || null);
        } catch (error) {
          console.error("Failed to load ritual context", error);
          setRitualContext(null);
        }
      } else {
        setRitualContext(null);
      }
      if (response.session?.server_now) {
        const serverNowMs = new Date(response.session.server_now).getTime();
        if (Number.isFinite(serverNowMs)) {
          setServerClockOffsetMs(serverNowMs - Date.now());
        }
      }

      if (response.session?.chat?.channel_name) {
        try {
          await ensureChatConnection(response.booking, response.session);
        } catch (error) {
          console.error("Failed to connect chat room", error);
          setChatReady(false);
          setChatStatus(getRealtimeErrorMessage(error, "Secure chat is currently unavailable."));
        }
      } else if (echoChannelRef.current) {
        destroyChatConnection();
      }

      if (CLOSED_STATUSES.has(response.booking?.status) || response.session?.state === "closed") {
        destroyCallConnection(response.session?.rooms?.call || "");
      }
    } catch (error) {
      console.error("Failed to load booking session", error);
      setPageError(getRealtimeErrorMessage(error, "Unable to load this consultation."));
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    void refreshSession();

    pollTimerRef.current = window.setInterval(() => {
      void refreshSession({ silent: true });
    }, 15000);

    return () => {
      if (pollTimerRef.current) {
        window.clearInterval(pollTimerRef.current);
      }
    };
  }, [bookingId]);

  useEffect(() => {
    if (!session?.is_live || isClosed || displayRemainingSeconds > 0) {
      return;
    }

    destroyCallConnection(session?.rooms?.call || "");
    void refreshSession({ silent: true });
  }, [displayRemainingSeconds, isClosed, session?.is_live, session?.rooms?.call]);

  useEffect(() => {
    if (!bookingId) {
      resetMessages([]);
      setPendingMessages([]);
      return;
    }

    resetMessages([]);
    setPendingMessages([]);
    void fetchPersistedMessages().catch((error) => {
      console.error("Failed to load stored chat messages", error);
    });
  }, [bookingId]);

  useEffect(() => {
    if (pingTimerRef.current) {
      window.clearInterval(pingTimerRef.current);
    }

    if (!bookingId || !session?.can_join || isClosed) {
      return undefined;
    }

    pingTimerRef.current = window.setInterval(() => {
      void pingBookingSession(bookingId).catch((error) => {
        console.error("Session ping failed", error);
      });
    }, 20000);

    return () => {
      if (pingTimerRef.current) {
        window.clearInterval(pingTimerRef.current);
      }
    };
  }, [bookingId, session?.can_join, isClosed]);

  useEffect(() => {
    if (chatSyncTimerRef.current) {
      window.clearInterval(chatSyncTimerRef.current);
    }

    if (!bookingId || loading) {
      return undefined;
    }

    const syncInterval = chatReady ? CHAT_SYNC_INTERVAL_CONNECTED_MS : CHAT_SYNC_INTERVAL_FALLBACK_MS;
    chatSyncTimerRef.current = window.setInterval(() => {
      void fetchPersistedMessages().catch((error) => {
        console.error("Stored chat sync failed", error);
      });
    }, syncInterval);

    return () => {
      if (chatSyncTimerRef.current) {
        window.clearInterval(chatSyncTimerRef.current);
      }
    };
  }, [bookingId, chatReady, loading]);

  useEffect(() => {
    if (typingStatusTimerRef.current) {
      window.clearInterval(typingStatusTimerRef.current);
    }

    if (!bookingId || loading || !canSendChatMessage || chatReady) {
      clearCounterpartTyping();
      return undefined;
    }

    typingStatusTimerRef.current = window.setInterval(() => {
      void fetchTypingStatus().catch((error) => {
        console.error("Typing status sync failed", error);
      });
    }, TYPING_SYNC_INTERVAL_FALLBACK_MS);

    return () => {
      if (typingStatusTimerRef.current) {
        window.clearInterval(typingStatusTimerRef.current);
      }
    };
  }, [bookingId, canSendChatMessage, chatReady, loading]);

  useEffect(() => {
    return () => {
      if (chatSyncTimerRef.current) {
        window.clearInterval(chatSyncTimerRef.current);
      }
      if (typingStatusTimerRef.current) {
        window.clearInterval(typingStatusTimerRef.current);
      }
      if (typingClearTimerRef.current) {
        window.clearTimeout(typingClearTimerRef.current);
      }
      void teardownRealtime();
    };
  }, []);

  const handleStartSession = async () => {
    if (!bookingId) return null;

    try {
      setStartingSession(true);
      const response = await startBookingSession(bookingId);
      setBooking(response.booking);
      setSession(response.session);
      void ensureChatConnection(response.booking, response.session).catch((error) => {
        console.error("Failed to reconnect secure chat after start", error);
      });
      setBanner("Consultation started.");
      return response;
    } catch (error) {
      console.error("Failed to start session", error);
      setBanner(error?.response?.data?.message || "Unable to start the consultation.");
      return null;
    } finally {
      setStartingSession(false);
    }
  };

  const handleEndSession = async () => {
    if (!bookingId) return;

    try {
      setEndingSession(true);
      const response = await endBookingSession(bookingId);
      setBooking(response.booking);
      setSession(response.session);
      destroyCallConnection(response.session?.rooms?.call || "");
      setBanner("Consultation ended.");
    } catch (error) {
      console.error("Failed to end session", error);
      setBanner(error?.response?.data?.message || "Unable to end the consultation.");
    } finally {
      setEndingSession(false);
    }
  };

  const refreshRitualContext = async () => {
    if (!bookingId || !isRitualConsultation) return;
    const response = await getRitualContextForBooking(bookingId);
    setRitualContext(response?.ritual_booking || null);
  };

  const handleSendRitualReply = async () => {
    if (!ritualContext?.id || !ritualReply.trim()) return;

    try {
      setSendingRitualAction(true);
      const response = await sendRitualAstrologerResponse(ritualContext.id, {
        message: ritualReply.trim(),
      });
      setRitualContext(response?.ritual_booking || ritualContext);
      setRitualReply("");
      setBanner("Ritual response sent to the user.");
    } catch (error) {
      setBanner(error?.response?.data?.message || "Unable to send ritual response.");
    } finally {
      setSendingRitualAction(false);
    }
  };

  const handleSendRitualPaymentRequest = async () => {
    if (!ritualContext?.id || !Number(ritualPaymentAmount)) return;

    try {
      setSendingRitualAction(true);
      const response = await sendRitualPaymentRequest(ritualContext.id, {
        amount: Number(ritualPaymentAmount),
        message: ritualPaymentNote.trim(),
      });
      setRitualContext(response?.ritual_booking || ritualContext);
      setRitualPaymentAmount("");
      setRitualPaymentNote("");
      setBanner("Ritual payment request sent to the user.");
      await refreshRitualContext();
    } catch (error) {
      setBanner(error?.response?.data?.message || "Unable to send ritual payment request.");
    } finally {
      setSendingRitualAction(false);
    }
  };

  const handleExtendSession = async (duration) => {
    if (!bookingId || !duration) return;

    try {
      setExtendingDuration(duration);
      const response = await extendBookingSession(bookingId, {
        duration,
        payment_method: "mock_extension",
      });
      setBooking(response.booking);
      setSession(response.session);
      setBanner(response.message || `Consultation extended by ${duration} minutes.`);
    } catch (error) {
      console.error("Failed to extend session", error);
      setBanner(error?.response?.data?.message || "Session could not be extended.");
    } finally {
      setExtendingDuration(null);
    }
  };

  const handleSendMessage = async () => {
    const trimmed = draft.trim();

    if (!trimmed || !canSendChatMessage) {
      return;
    }

    const clientUuid =
      typeof crypto !== "undefined" && typeof crypto.randomUUID === "function"
        ? crypto.randomUUID()
        : `${Date.now()}-${Math.random().toString(36).slice(2)}`;

    try {
      setPendingMessages((previous) => [
        ...previous,
        createOptimisticMessage({
          clientUuid,
          text: trimmed,
          kind: "text",
          reply: selectedReply,
        }),
      ]);
      setDraft("");
      const replyToMessageId = selectedReply?.dbId || null;
      setSelectedReply(null);
      sendTypingCommand(false);
      const persistedMessage = await persistBookingMessage({
        messageType: "text",
        text: trimmed,
        clientUuid,
        replyToMessageId,
      });
      if (persistedMessage) {
        setMessages((previous) => [
          ...previous.filter(
            (message) =>
              message.id !== persistedMessage.id &&
              (!message.clientUuid ||
                !persistedMessage.clientUuid ||
                message.clientUuid !== persistedMessage.clientUuid)
          ),
          persistedMessage,
        ].sort((left, right) => left.timestamp - right.timestamp));
        removeOptimisticMessage(clientUuid);
      }

      clearCounterpartTyping();
    } catch (error) {
      console.error("Failed to send message", error);
      removeOptimisticMessage(clientUuid);
      setDraft((currentDraft) => (currentDraft ? currentDraft : trimmed));
      setBanner("Message could not be sent.");
    }
  };

  const uploadAndSendAttachment = async (file, { successMessage = "Attachment sent." } = {}) => {
    if (!file || !canSendChatMessage) {
      return;
    }

    const clientUuid =
      typeof crypto !== "undefined" && typeof crypto.randomUUID === "function"
        ? crypto.randomUUID()
        : `${Date.now()}-${Math.random().toString(36).slice(2)}`;

    try {
      setUploadingImage(true);

      const payload = new FormData();
      payload.append("attachment", file);

      const uploadResponse = await api.post("/media/chat-attachment", payload, {
        headers: {
          Accept: "application/json",
        },
      });

      const attachmentUrl = uploadResponse.data?.url;

      if (!attachmentUrl) {
        throw new Error("Attachment upload did not return a valid URL.");
      }

      const messageType = uploadResponse.data?.message_type || "file";
      const replyToMessageId = selectedReply?.dbId || null;
      setPendingMessages((previous) => [
        ...previous,
        createOptimisticMessage({
          clientUuid,
          kind: messageType,
          mediaUrl: attachmentUrl,
          attachmentName: uploadResponse.data?.name || file.name,
          reply: selectedReply,
        }),
      ]);
      setSelectedReply(null);

      const persistedMessage = await persistBookingMessage({
        messageType,
        mediaUrl: attachmentUrl,
        attachmentName: uploadResponse.data?.name || file.name,
        attachmentMime: uploadResponse.data?.mime || file.type,
        attachmentSize: uploadResponse.data?.size || file.size,
        clientUuid,
        replyToMessageId,
      });
      if (persistedMessage) {
        setMessages((previous) => [
          ...previous.filter(
            (message) =>
              message.id !== persistedMessage.id &&
              (!message.clientUuid ||
                !persistedMessage.clientUuid ||
                message.clientUuid !== persistedMessage.clientUuid)
          ),
          persistedMessage,
        ].sort((left, right) => left.timestamp - right.timestamp));
        removeOptimisticMessage(clientUuid);
      }

      setBanner(successMessage);
    } catch (error) {
      console.error("Failed to send chat attachment", error);
      removeOptimisticMessage(clientUuid);
      setBanner(error?.response?.data?.message || error?.message || "Attachment could not be sent.");
    } finally {
      setUploadingImage(false);
    }
  };

  const handleSendAttachment = async (event) => {
    const file = event.target.files?.[0];
    await uploadAndSendAttachment(file);
    if (fileInputRef.current) {
      fileInputRef.current.value = "";
    }
  };

  const handleSendCameraCapture = async (event) => {
    const file = event.target.files?.[0];
    await uploadAndSendAttachment(file, { successMessage: "Photo sent." });
    if (cameraInputRef.current) {
      cameraInputRef.current.value = "";
    }
  };

  const stopRecordingStream = () => {
    recordingStreamRef.current?.getTracks?.().forEach((track) => track.stop());
    recordingStreamRef.current = null;
  };

  const clearRecordingTimer = () => {
    if (recordingTimerRef.current) {
      window.clearInterval(recordingTimerRef.current);
      recordingTimerRef.current = null;
    }
  };

  const resetVoiceRecording = () => {
    clearRecordingTimer();
    recordingCancelledRef.current = true;
    if (mediaRecorderRef.current && mediaRecorderRef.current.state !== "inactive") {
      try {
        mediaRecorderRef.current.stop();
      } catch {
        /* Ignore recorder cleanup failures. */
      }
    }
    stopRecordingStream();
    mediaRecorderRef.current = null;
    recordingChunksRef.current = [];
    if (recordedAudio?.url) {
      URL.revokeObjectURL(recordedAudio.url);
    }
    setRecordingState("idle");
    setRecordingSeconds(0);
    setRecordedAudio(null);
  };

  const startVoiceRecording = async () => {
    if (!canSendChatMessage || recordingState === "recording") {
      return;
    }

    if (!navigator?.mediaDevices?.getUserMedia || typeof MediaRecorder === "undefined") {
      setBanner("Voice recording is not supported in this browser.");
      return;
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true, video: false });
      const preferredTypes = [
        "audio/webm;codecs=opus",
        "audio/webm",
        "audio/mp4",
        "audio/ogg;codecs=opus",
      ];
      const mimeType = preferredTypes.find((type) => MediaRecorder.isTypeSupported?.(type));
      const recorder = new MediaRecorder(stream, mimeType ? { mimeType } : undefined);

      if (recordedAudio?.url) {
        URL.revokeObjectURL(recordedAudio.url);
      }

      recordingChunksRef.current = [];
      recordingStreamRef.current = stream;
      mediaRecorderRef.current = recorder;
      recordingCancelledRef.current = false;
      setRecordedAudio(null);
      setRecordingSeconds(0);
      setRecordingState("recording");

      recorder.ondataavailable = (event) => {
        if (event.data?.size > 0) {
          recordingChunksRef.current.push(event.data);
        }
      };

      recorder.onstop = () => {
        clearRecordingTimer();
        stopRecordingStream();

        if (recordingCancelledRef.current || !recordingChunksRef.current.length) {
          recordingChunksRef.current = [];
          setRecordingState("idle");
          return;
        }

        const blob = new Blob(recordingChunksRef.current, {
          type: recorder.mimeType || "audio/webm",
        });
        const extension = blob.type.includes("mp4") ? "m4a" : blob.type.includes("ogg") ? "ogg" : "webm";
        const file = new File([blob], `voice-note-${Date.now()}.${extension}`, { type: blob.type || "audio/webm" });
        setRecordedAudio({
          file,
          url: URL.createObjectURL(blob),
        });
        setRecordingState("ready");
      };

      recorder.start();
      recordingTimerRef.current = window.setInterval(() => {
        setRecordingSeconds((seconds) => {
          const nextSeconds = seconds + 1;
          if (nextSeconds >= VOICE_NOTE_LIMIT_SECONDS && mediaRecorderRef.current?.state === "recording") {
            mediaRecorderRef.current.stop();
          }
          return Math.min(nextSeconds, VOICE_NOTE_LIMIT_SECONDS);
        });
      }, 1000);
    } catch (error) {
      const errorName = error?.name;
      if (errorName === "NotAllowedError" || errorName === "SecurityError") {
        setBanner("Microphone permission was blocked. Allow microphone access to record voice notes.");
      } else if (errorName === "NotFoundError") {
        setBanner("No microphone device was found.");
      } else {
        setBanner("Voice recording could not be started.");
      }
      stopRecordingStream();
      clearRecordingTimer();
      setRecordingState("idle");
    }
  };

  const stopVoiceRecording = () => {
    if (mediaRecorderRef.current?.state === "recording") {
      mediaRecorderRef.current.stop();
    }
  };

  const sendVoiceRecording = async () => {
    if (!recordedAudio?.file) {
      return;
    }

    await uploadAndSendAttachment(recordedAudio.file, { successMessage: "Voice note sent." });
    resetVoiceRecording();
  };

  useEffect(() => {
    return () => {
      resetVoiceRecording();
      if (fileInputRef.current) {
        fileInputRef.current.value = "";
      }
      if (cameraInputRef.current) {
        cameraInputRef.current.value = "";
      }
    };
  }, []);

  const handleJoinAudioCall = async () => {
    if (!canJoinCall) {
      setBanner("Audio call is not available yet.");
      return;
    }

    if (isCallConnected || callLoading) {
      return;
    }

    try {
      setCallLoading(true);
      setCallState("connecting");
      setCallStatus("Connecting audio room...");

      let activeSession = session;

      if (!activeSession?.is_live && !isAstrologerViewer) {
        setBanner("Waiting for the astrologer to start the consultation.");
        setCallState("idle");
        setCallStatus("Waiting for the astrologer to start the consultation.");
        return;
      }

      await ensureMicrophoneAccess();

      if (!activeSession?.is_live && isAstrologerViewer && activeSession?.can_start) {
        const started = await handleStartSession();
        if (!started) {
          return;
        }
        activeSession = started.session;
      }

      const engine = await connectAudioRoom(activeSession);
      await startLocalAudio(engine, activeSession);
    } catch (error) {
      console.error("Failed to join audio call", error);
      destroyCallConnection(session?.rooms?.call || "");
      const message = getCallErrorMessage(error);
      setCallState("error");
      setCallStatus(message);
      setBanner(message);
    } finally {
      setCallLoading(false);
    }
  };

  const handleLeaveAudioCall = () => {
    destroyCallConnection(session?.rooms?.call || "");
    setBanner("Audio call disconnected.");
  };

  const handleEnableRemoteAudio = async () => {
    const audioElements = Array.from(remoteAudioMapRef.current.values());

    if (!audioElements.length) {
      setCallAudioBlocked(false);
      setCallStatus("Waiting for remote audio.");
      return;
    }

    try {
      await Promise.all(audioElements.map((audioEl) => audioEl.play()));
      setCallAudioBlocked(false);
      setCallStatus("Remote audio connected.");
    } catch (error) {
      console.error("Failed to enable remote audio", error);
      setBanner("Browser blocked audio playback. Tap again or check site sound permissions.");
    }
  };

  const handleToggleMute = () => {
    if (!zegoEngineRef.current) return;

    const nextMuted = !callMuted;

    try {
      zegoEngineRef.current.muteMicrophone(nextMuted);
      setCallMuted(nextMuted);
      setCallStatus(nextMuted ? "Microphone muted." : "Microphone live.");
    } catch (error) {
      console.error("Failed to toggle microphone", error);
      setBanner("Microphone setting could not be updated.");
    }
  };

  const pageClassName = isChatFullscreen
    ? "fixed inset-0 z-[80] h-[100dvh] overflow-hidden bg-[#f3f5fb] font-sans"
    : "min-h-screen bg-[#f3f5fb] font-sans";
  const contentClassName = isChatFullscreen
    ? "flex h-full flex-col"
    : "mx-auto flex max-w-7xl flex-col gap-6 px-4 py-6 lg:px-8";
  const gridClassName = isChatFullscreen
    ? "min-h-0 flex-1"
    : "grid gap-6 xl:grid-cols-[minmax(0,1fr)_360px] xl:items-start";
  const chatColumnClassName = isChatFullscreen ? "min-h-0 h-full" : "min-w-0 space-y-6";
  const chatSectionClassName = isChatFullscreen
    ? "flex h-full min-h-0 flex-col overflow-hidden rounded-none border-0 bg-white shadow-none"
    : "flex min-h-[70vh] flex-col overflow-hidden rounded-3xl border border-gray-200 bg-white shadow-sm xl:h-[calc(100vh-12.5rem)] xl:min-h-0 xl:max-h-[820px]";
  const chatViewportClassName =
    "relative flex-1 overflow-y-auto bg-[#efe7dc] bg-[radial-gradient(circle_at_12px_12px,rgba(30,53,87,0.08)_1.5px,transparent_1.5px),radial-gradient(circle_at_24px_24px,rgba(212,167,60,0.10)_1px,transparent_1px)] bg-[length:36px_36px] px-3 py-4 sm:px-5 sm:py-5";
  const inputBarStyle = isChatFullscreen
    ? { paddingBottom: "max(1rem, env(safe-area-inset-bottom))" }
    : undefined;

  if (!bookingId) {
    return (
      <div className="min-h-screen bg-[#f7f8fb] flex items-center justify-center px-4">
        <div className="max-w-lg rounded-3xl border border-gray-200 bg-white p-8 text-center shadow-sm">
          <h1 className="text-2xl font-bold text-[#1E3557]">Consultation not found</h1>
          <p className="mt-3 text-sm text-gray-500">
            A booking identifier is required to open a consultation room.
          </p>
          <Link
            to="/my-bookings"
            className="mt-6 inline-flex items-center rounded-xl bg-[#1E3557] px-5 py-3 text-sm font-semibold text-white"
          >
            Go to My Bookings
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className={pageClassName}>
      {banner && (
        <div className={`fixed left-1/2 z-[90] -translate-x-1/2 rounded-full bg-[#1E3557] px-6 py-3 text-sm font-semibold text-white shadow-lg ${isChatFullscreen ? "top-4" : "top-24"}`}>
          {banner}
        </div>
      )}

      {!isChatFullscreen && (
      <div className="border-b border-[#E3E8F3] bg-white">
        <div className="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-4 px-4 py-4 lg:px-8">
          <div className="flex items-center gap-4">
            <button
              type="button"
              onClick={() => navigate(backHref)}
              className="inline-flex h-11 w-11 items-center justify-center rounded-full border border-gray-200 text-[#1E3557] transition hover:border-[#1E3557]"
              aria-label="Go back"
            >
              <FaArrowLeft />
            </button>

            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#D4A73C]">
                Consultation Room
              </p>
              <h1 className="mt-1 text-2xl font-bold text-[#1E3557]">
                {booking?.booking_reference || `Booking #${bookingId}`}
              </h1>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <div className="rounded-2xl border border-gray-200 bg-[#F8F9FC] px-4 py-3 text-sm">
              <p className="text-xs uppercase tracking-wide text-gray-400">Session State</p>
              <p className="mt-1 font-semibold text-[#1E3557] capitalize">{session?.state || "loading"}</p>
            </div>
            <div className="rounded-2xl border border-gray-200 bg-[#F8F9FC] px-4 py-3 text-sm">
              <p className="text-xs uppercase tracking-wide text-gray-400">Time Remaining</p>
              <p className="mt-1 font-semibold text-[#1E3557]">{formatCountdown(displayRemainingSeconds)}</p>
            </div>
            <div className="rounded-2xl border border-gray-200 bg-[#F8F9FC] px-4 py-3 text-sm">
              <p className="text-xs uppercase tracking-wide text-gray-400">Room Refresh</p>
              <p className="mt-1 font-semibold text-[#1E3557]">{refreshing ? "Refreshing..." : "Live"}</p>
            </div>
          </div>
        </div>
      </div>
      )}

      <div className={contentClassName}>
        {!isChatFullscreen && showLowTimeWarning && (
          <div className="rounded-2xl border border-amber-200 bg-amber-50 px-5 py-4 text-sm text-amber-800 shadow-sm">
            <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
              <div>
                <p className="font-semibold">Less than two minutes remain in this consultation.</p>
                <p className="mt-1">
                  The session will automatically close when the booked duration ends.
                  {session?.extension?.can_extend
                    ? " You can extend now because the astrologer has no conflicting booking."
                    : " Extension is unavailable when the astrologer has another booking after this session."}
                </p>
              </div>

              {session?.extension?.can_extend && (
                <div className="flex flex-wrap gap-2">
                  {availableExtensionOptions.slice(0, 3).map((option) => (
                    <button
                      key={option.duration}
                      type="button"
                      onClick={() => void handleExtendSession(option.duration)}
                      disabled={extendingDuration !== null}
                      className="rounded-xl bg-[#1E3557] px-4 py-2 text-xs font-bold text-white transition hover:bg-[#162744] disabled:cursor-not-allowed disabled:opacity-60"
                    >
                      {extendingDuration === option.duration
                        ? "Extending..."
                        : `+${option.duration} min Rs ${option.amount}`}
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}

        {!isChatFullscreen && (
        <div className="rounded-3xl border border-[#D9E3F3] bg-white px-5 py-5 shadow-sm">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#D4A73C]">
                {callEnabled ? "Audio Consultation" : "Chat Consultation"}
              </p>
              <h2 className="mt-2 text-2xl font-bold text-[#1E3557]">{sessionHeadline}</h2>
              <p className="mt-3 max-w-3xl text-sm leading-6 text-gray-600">{sessionSummary}</p>
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              <div className="rounded-2xl bg-[#F8F9FC] px-4 py-3 text-sm">
                <p className="text-xs uppercase tracking-wide text-gray-400">Scheduled Start</p>
                <p className="mt-1 font-semibold text-[#1E3557]">{scheduledStartLabel}</p>
              </div>
              <div className="rounded-2xl bg-[#F8F9FC] px-4 py-3 text-sm">
                <p className="text-xs uppercase tracking-wide text-gray-400">Scheduled End</p>
                <p className="mt-1 font-semibold text-[#1E3557]">{scheduledEndLabel}</p>
              </div>
            </div>
          </div>
        </div>
        )}

        {pageError && (
          <div className="rounded-2xl border border-rose-200 bg-rose-50 px-5 py-4 text-sm text-rose-700 shadow-sm">
            {pageError}
          </div>
        )}

        {loading ? (
          <div className="flex min-h-[60vh] items-center justify-center rounded-3xl border border-gray-200 bg-white shadow-sm">
            <div className="h-12 w-12 animate-spin rounded-full border-b-2 border-[#D4A73C]"></div>
          </div>
        ) : (
          <div className={gridClassName}>
            <div className={chatColumnClassName}>
              <section className={chatSectionClassName}>
              <div className="flex items-center justify-between gap-4 border-b border-gray-100 px-5 py-4">
                <div className="flex items-center gap-3">
                  <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#F6E8BF] text-[#1E3557]">
                    <FaComments />
                  </div>
                  <div>
                    <h2 className="text-lg font-bold text-[#1E3557]">
                      {callEnabled ? "Consultation Messages" : "Live Consultation Chat"}
                    </h2>
                    <p className="text-sm text-gray-500">
                      {callEnabled
                        ? canSendChatMessage
                          ? chatReady
                            ? "Backup chat is ready for notes, links, and image sharing during the call."
                            : "Backup chat is saving messages. Live delivery is reconnecting."
                          : "Use the audio controls on the right. This chat becomes available once the room connects."
                        : chatReady
                          ? chatStatus
                          : canSendChatMessage
                            ? "Messages are saving. Live delivery is reconnecting..."
                            : chatStatus}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <span className="rounded-full bg-[#F8F9FC] px-3 py-1.5 text-xs font-semibold uppercase tracking-wide text-[#1E3557]">
                    {chatReady ? "Live" : chatServiceEnabled ? "Syncing" : "Fallback"}
                  </span>
                  <span className="hidden rounded-full bg-[#F8F9FC] px-3 py-1.5 text-xs font-semibold uppercase tracking-wide text-[#1E3557] sm:inline-flex">
                    {booking?.consultation_type === "call" ? "Backup Chat" : "Chat"}
                  </span>
                  <button
                    type="button"
                    onClick={() => {
                      setIsChatFullscreen((value) => !value);
                      window.setTimeout(scrollMessagesToBottom, 50);
                    }}
                    className="inline-flex h-10 w-10 items-center justify-center rounded-full border border-gray-200 bg-white text-[#1E3557] transition hover:border-[#D4A73C] hover:text-[#D4A73C]"
                    aria-label={isChatFullscreen ? "Exit full screen chat" : "Open full screen chat"}
                  >
                    {isChatFullscreen ? <FaCompress /> : <FaExpand />}
                  </button>
                </div>
              </div>

              <div
                ref={messageViewportRef}
                onScroll={handleMessageViewportScroll}
                className={chatViewportClassName}
              >
                {messageLoadError ? (
                  <div className="mb-4 rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-700">
                    {messageLoadError}
                  </div>
                ) : null}

                {visibleMessages.length > 0 ? (
                  <div className="space-y-4">
                    {visibleMessages.map((message) => (
                      <div
                        key={message.id}
                        className={`flex ${message.isSelf ? "justify-end" : "justify-start"}`}
                      >
                        <div
                          className={`group relative max-w-[82%] rounded-2xl px-4 py-3 text-sm shadow-sm ${message.isSelf
                              ? "bg-[#DCF8C6] text-[#12320C]"
                              : "border border-gray-100 bg-white text-[#1E3557]"
                            }`}
                        >
                          {message.reply && (
                            <div className={`mb-3 rounded-xl border-l-4 px-3 py-2 text-xs ${message.isSelf ? "border-[#1E3557] bg-white/55" : "border-[#D4A73C] bg-[#FFF9EC]"}`}>
                              <p className="font-black">{message.reply.senderName}</p>
                              <p className="mt-1 line-clamp-2 opacity-80">{message.reply.text}</p>
                            </div>
                          )}
                          {message.kind === "image" && message.mediaUrl ? (
                            <a href={message.mediaUrl} target="_blank" rel="noreferrer" className="block">
                              <img
                                src={message.mediaUrl}
                                alt="Chat attachment"
                                className="max-h-64 w-full rounded-2xl object-cover"
                              />
                              <p className={`mt-3 text-xs font-semibold ${message.isSelf ? "text-[#1E3557]" : "text-[#D4A73C]"}`}>
                                Open full image
                              </p>
                            </a>
                          ) : message.kind === "audio" && message.mediaUrl ? (
                            <div className="min-w-[220px] max-w-full rounded-xl bg-white/70 px-3 py-3">
                              <p className="mb-2 text-xs font-black uppercase tracking-wide opacity-70">Voice note</p>
                              <audio controls src={message.mediaUrl} className="w-full max-w-[280px]" />
                            </div>
                          ) : ["pdf", "video", "file"].includes(message.kind) && message.mediaUrl ? (
                            <a href={message.mediaUrl} target="_blank" rel="noreferrer" className="flex items-center gap-3 rounded-xl bg-white/70 px-3 py-3">
                              <span className="flex h-10 w-10 items-center justify-center rounded-lg bg-[#1E3557] text-white">
                                {message.kind === "video" ? <FaPlayCircle /> : <FaPaperclip />}
                              </span>
                              <span className="min-w-0">
                                <span className="block truncate font-bold">{message.attachmentName || "Open attachment"}</span>
                                <span className="text-xs opacity-70">{message.kind.toUpperCase()}</span>
                              </span>
                            </a>
                          ) : (
                            <p className="leading-6">{message.text}</p>
                          )}
                          <div className="mt-2 flex items-center justify-between gap-3">
                            <button
                              type="button"
                              onClick={() => setSelectedReply(message)}
                              className="inline-flex items-center gap-1 text-[11px] font-semibold opacity-0 transition group-hover:opacity-80"
                            >
                              <FaReply />
                              Reply
                            </button>
                            <p className="ml-auto inline-flex items-center gap-1 text-[11px] opacity-60">
                              {formatTime(message.timestamp)}
                              {message.isSelf && (
                                <FaCheckDouble className={message.readAt ? "text-[#2F80ED]" : "text-current"} title={message.readAt ? "Seen" : "Sent"} />
                              )}
                            </p>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : !session?.can_join ? (
                  <div className="flex h-full min-h-[320px] items-center justify-center">
                    <div className="max-w-md text-center">
                      <p className="text-xl font-bold text-[#1E3557]">
                        {isClosed
                          ? "This consultation is closed."
                          : callEnabled
                            ? "The call room is scheduled and not live yet."
                            : "Chat room access is not open yet."}
                      </p>
                      <p className="mt-3 text-sm leading-6 text-gray-500">
                        {isClosed
                          ? "The live connection is no longer active, but the booking summary remains available."
                          : "The astrologer can open the consultation from this screen. Once the booking is live, both participants can use the room."}
                      </p>
                    </div>
                  </div>
                ) : !chatServiceEnabled ? (
                  <div className="flex h-full min-h-[320px] items-center justify-center">
                    <div className="max-w-md text-center">
                      <p className="text-xl font-bold text-[#1E3557]">Chat is ready.</p>
                      <p className="mt-3 text-sm leading-6 text-gray-500">
                        Messages will be saved and synced here while the live delivery service reconnects.
                      </p>
                    </div>
                  </div>
                ) : !chatReady ? (
                  <div className="flex h-full min-h-[320px] items-center justify-center">
                    <div className="max-w-md text-center">
                      <p className="text-xl font-bold text-[#1E3557]">
                        {callEnabled ? "Connecting backup chat..." : "Connecting live chat..."}
                      </p>
                      <p className="mt-3 text-sm leading-6 text-gray-500">
                        {chatStatus}
                      </p>
                    </div>
                  </div>
                ) : (
                  <div className="flex h-full min-h-[320px] items-center justify-center">
                    <div className="max-w-md text-center">
                      <p className="text-xl font-bold text-[#1E3557]">No messages yet</p>
                      <p className="mt-3 text-sm leading-6 text-gray-500">
                        {callEnabled
                          ? "The call is ready. Use this backup chat to share notes, links, and images during the consultation."
                          : "This room is ready. The first message sent here will appear live for both the user and astrologer."}
                      </p>
                    </div>
                  </div>
                )}
                {hasNewMessages && (
                  <button
                    type="button"
                    onClick={scrollMessagesToBottom}
                    className="sticky bottom-3 left-1/2 z-10 mx-auto mt-4 flex -translate-x-1/2 items-center justify-center rounded-full bg-[#1E3557] px-4 py-2 text-xs font-bold text-white shadow-lg"
                  >
                    New messages
                  </button>
                )}
              </div>

              <div className="border-t border-gray-100 px-3 py-3 sm:px-5 sm:py-4" style={inputBarStyle}>
                <div className="mb-2 h-5 text-xs font-semibold text-[#D4A73C]">
                  {counterpartTyping ? `${counterpart?.name || "Other user"} is typing...` : ""}
                </div>
                {recordingState !== "idle" && (
                  <div className="mb-3 rounded-2xl border border-[#D4A73C]/30 bg-[#FFF9EC] px-4 py-3 text-sm">
                    {recordingState === "recording" ? (
                      <div className="flex flex-wrap items-center justify-between gap-3">
                        <div className="flex items-center gap-3 font-black text-[#1E3557]">
                          <span className="h-3 w-3 animate-pulse rounded-full bg-rose-500" />
                          Recording {formatCountdown(recordingSeconds)}
                        </div>
                        <div className="flex items-center gap-2">
                          <button
                            type="button"
                            onClick={stopVoiceRecording}
                            className="inline-flex items-center gap-2 rounded-full bg-[#1E3557] px-4 py-2 text-xs font-bold text-white"
                          >
                            <FaStop />
                            Stop
                          </button>
                          <button
                            type="button"
                            onClick={resetVoiceRecording}
                            className="inline-flex items-center gap-2 rounded-full border border-rose-200 px-4 py-2 text-xs font-bold text-rose-600"
                          >
                            <FaTrash />
                            Cancel
                          </button>
                        </div>
                      </div>
                    ) : (
                      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                        <audio controls src={recordedAudio?.url} className="w-full max-w-sm" />
                        <div className="flex flex-wrap items-center gap-2">
                          <button
                            type="button"
                            onClick={() => void sendVoiceRecording()}
                            disabled={uploadingImage}
                            className="inline-flex items-center gap-2 rounded-full bg-[#D4A73C] px-4 py-2 text-xs font-black text-[#1E3557] disabled:opacity-60"
                          >
                            <FaPaperPlane />
                            Send voice
                          </button>
                          <button
                            type="button"
                            onClick={() => void startVoiceRecording()}
                            disabled={uploadingImage}
                            className="inline-flex items-center gap-2 rounded-full border border-gray-200 bg-white px-4 py-2 text-xs font-bold text-[#1E3557] disabled:opacity-60"
                          >
                            <FaMicrophone />
                            Re-record
                          </button>
                          <button
                            type="button"
                            onClick={resetVoiceRecording}
                            className="inline-flex items-center gap-2 rounded-full border border-rose-200 px-4 py-2 text-xs font-bold text-rose-600"
                          >
                            <FaTrash />
                            Cancel
                          </button>
                        </div>
                      </div>
                    )}
                  </div>
                )}
                {selectedReply && (
                  <div className="mb-3 flex items-start justify-between gap-3 rounded-2xl border border-[#D4A73C]/30 bg-[#FFF9EC] px-4 py-3 text-sm">
                    <div className="min-w-0">
                      <p className="font-black text-[#1E3557]">Replying to {selectedReply.senderUserId === currentUserId ? "your message" : counterpart?.name || "message"}</p>
                      <p className="mt-1 truncate text-gray-600">{selectedReply.text || selectedReply.attachmentName || "Attachment"}</p>
                    </div>
                    <button type="button" onClick={() => setSelectedReply(null)} className="text-[#1E3557]">
                      <FaTimes />
                    </button>
                  </div>
                )}
                <div className="flex items-center gap-2 rounded-2xl border border-gray-200 bg-[#F8F9FC] px-2.5 py-2.5 sm:gap-3 sm:px-4 sm:py-3">
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*,application/pdf,video/mp4,video/webm,video/quicktime,audio/*"
                    onChange={(event) => void handleSendAttachment(event)}
                    className="hidden"
                  />
                  <input
                    ref={cameraInputRef}
                    type="file"
                    accept="image/*"
                    capture="environment"
                    onChange={(event) => void handleSendCameraCapture(event)}
                    className="hidden"
                  />
                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    disabled={!canSendChatMessage || uploadingImage || recordingState === "recording"}
                    className="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-full border border-gray-200 bg-white text-[#1E3557] transition hover:border-[#D4A73C] hover:text-[#D4A73C] disabled:cursor-not-allowed disabled:opacity-50 sm:h-11 sm:w-11"
                    aria-label="Upload attachment"
                  >
                    <FaPaperclip />
                  </button>
                  <button
                    type="button"
                    onClick={() => cameraInputRef.current?.click()}
                    disabled={!canSendChatMessage || uploadingImage || recordingState === "recording"}
                    className="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-full border border-gray-200 bg-white text-[#1E3557] transition hover:border-[#D4A73C] hover:text-[#D4A73C] disabled:cursor-not-allowed disabled:opacity-50 sm:h-11 sm:w-11"
                    aria-label="Take photo"
                  >
                    <FaCamera />
                  </button>
                  <input
                    type="text"
                    value={draft}
                    onChange={(event) => handleDraftChange(event.target.value)}
                    onKeyDown={(event) => {
                      if (event.key === "Enter" && !event.shiftKey) {
                        event.preventDefault();
                        void handleSendMessage();
                      }
                    }}
                    disabled={!canSendChatMessage || uploadingImage || recordingState === "recording"}
                    placeholder={
                      canSendChatMessage
                        ? callEnabled
                          ? "Send a note, link, or follow-up message..."
                          : "Type your message here..."
                        : session?.can_join
                          ? "Connecting live chat..."
                          : "Chat becomes active when the consultation opens."
                    }
                    className="min-w-0 flex-1 bg-transparent text-sm text-[#1E3557] outline-none placeholder:text-gray-400 disabled:cursor-not-allowed"
                  />
                  <button
                    type="button"
                    onClick={() => void startVoiceRecording()}
                    disabled={!canSendChatMessage || uploadingImage || recordingState === "recording"}
                    className="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-full border border-gray-200 bg-white text-[#1E3557] transition hover:border-[#D4A73C] hover:text-[#D4A73C] disabled:cursor-not-allowed disabled:opacity-50 sm:h-11 sm:w-11"
                    aria-label="Record voice note"
                  >
                    <FaMicrophone />
                  </button>
                  <button
                    type="button"
                    onClick={() => void handleSendMessage()}
                    disabled={!canSendChatMessage || uploadingImage || recordingState === "recording" || !draft.trim()}
                    className="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-[#D4A73C] text-[#1E3557] transition hover:bg-[#c49530] disabled:cursor-not-allowed disabled:opacity-50 sm:h-11 sm:w-11"
                  >
                    <FaPaperPlane />
                  </button>
                </div>
              </div>
              </section>

              {!isChatFullscreen && isAstrologerViewer && isRitualConsultation && (
                <section className="rounded-3xl border border-[#EAD79D] bg-white p-5 shadow-sm">
                  <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                    <div>
                      <p className="text-xs font-black uppercase tracking-[0.18em] text-[#D4A73C]">Pooja Anusthan</p>
                      <h2 className="mt-1 text-xl font-black text-[#1E3557]">
                        {ritualContext?.ritual?.name || "Ritual Consultation Follow-up"}
                      </h2>
                      <p className="mt-1 text-sm text-gray-600">
                        Send the user a ritual response after ending the consultation. Add a final amount only when the booking is ready for payment.
                      </p>
                    </div>
                    <span className="rounded-full bg-[#FFF9EC] px-3 py-1 text-xs font-black uppercase text-[#7A4C00]">
                      {ritualContext?.status || "consultation"}
                    </span>
                  </div>

                  {!!ritualContext?.updates?.length && (
                    <div className="mt-5 space-y-3">
                      {ritualContext.updates.map((update) => (
                        <div key={update.id} className="rounded-2xl border border-[#F1E1B8] bg-[#FFF9EC] px-4 py-3">
                          <div className="flex flex-wrap items-center justify-between gap-2">
                            <p className="text-xs font-black uppercase tracking-wide text-[#D4A73C]">
                              {update.type === "payment_request" ? "Payment Request" : "Response"}
                            </p>
                            {Number(update.amount || 0) > 0 && (
                              <span className="rounded-full bg-white px-3 py-1 text-xs font-black text-[#1E3557]">
                                Rs {Number(update.amount).toLocaleString("en-IN")}
                              </span>
                            )}
                          </div>
                          {update.message && <p className="mt-2 text-sm leading-6 text-[#1E3557]">{update.message}</p>}
                        </div>
                      ))}
                    </div>
                  )}

                  {!canSendRitualFollowUp ? (
                    <div className="mt-5 rounded-2xl border border-dashed border-gray-200 bg-[#F8F9FC] px-4 py-4 text-sm text-gray-600">
                      Ritual follow-up unlocks after you end this consultation.
                    </div>
                  ) : (
                    <div className="mt-5 grid gap-5 lg:grid-cols-2">
                      <div className="rounded-2xl border border-gray-100 bg-[#F8F9FC] p-4">
                        <h3 className="font-black text-[#1E3557]">Send Ritual Response</h3>
                        <textarea
                          value={ritualReply}
                          onChange={(event) => setRitualReply(event.target.value)}
                          rows={5}
                          className="mt-3 w-full rounded-2xl border border-gray-200 bg-white px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                          placeholder="Write preparation notes, sankalp guidance, or consultation summary for the user."
                        />
                        <button
                          type="button"
                          disabled={sendingRitualAction || !ritualReply.trim()}
                          onClick={() => void handleSendRitualReply()}
                          className="mt-3 rounded-xl bg-[#1E3557] px-5 py-3 text-sm font-bold text-white disabled:opacity-60"
                        >
                          Send Response
                        </button>
                      </div>

                      <div className="rounded-2xl border border-[#F1E1B8] bg-[#FFF9EC] p-4">
                        <h3 className="font-black text-[#1E3557]">Request Final Payment</h3>
                        <input
                          type="number"
                          min="1"
                          step="0.01"
                          value={ritualPaymentAmount}
                          onChange={(event) => setRitualPaymentAmount(event.target.value)}
                          className="mt-3 w-full rounded-2xl border border-[#EAD79D] bg-white px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                          placeholder="Final amount in Rs"
                        />
                        <textarea
                          value={ritualPaymentNote}
                          onChange={(event) => setRitualPaymentNote(event.target.value)}
                          rows={4}
                          className="mt-3 w-full rounded-2xl border border-[#EAD79D] bg-white px-4 py-3 text-sm outline-none focus:border-[#D4A73C]"
                          placeholder="Optional payment note shown in the user's notification."
                        />
                        <button
                          type="button"
                          disabled={sendingRitualAction || !Number(ritualPaymentAmount)}
                          onClick={() => void handleSendRitualPaymentRequest()}
                          className="mt-3 rounded-xl bg-[#D4A73C] px-5 py-3 text-sm font-black text-[#1E3557] disabled:opacity-60"
                        >
                          Send Payment Request
                        </button>
                      </div>
                    </div>
                  )}
                </section>
              )}

              {!isChatFullscreen && isAstrologerViewer && (
                <section className="rounded-3xl border border-[#EAD79D] bg-[#FFF9EA] p-5 shadow-sm">
                  <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                    <div>
                      <h2 className="text-xl font-black text-[#1E3557]">Detailed Client Kundali</h2>
                      <p className="mt-1 text-sm text-gray-600">Generate the report from birth details supplied with this booking.</p>
                    </div>
                    <button
                      type="button"
                      onClick={() => void loadClientKundali()}
                      disabled={clientKundaliLoading}
                      className="rounded-xl bg-[#1E3557] px-5 py-3 text-sm font-bold text-white disabled:opacity-60"
                    >
                      {clientKundaliLoading
                        ? "Generating..."
                        : clientKundali
                          ? "Refresh Detailed Kundali"
                          : "Generate Detailed Kundali"}
                    </button>
                  </div>
                  {(clientKundaliLoading || clientKundaliError || clientKundali) && (
                    <div className="mt-5">
                      <ClientKundaliPanel data={clientKundali} loading={clientKundaliLoading} error={clientKundaliError} />
                    </div>
                  )}
                </section>
              )}

              {!isChatFullscreen && isAstrologerViewer && (
                <ChatMatchmakingTool
                  clientBirthDetails={booking?.birth_details || clientKundali?.birth_details}
                  clientName={booking?.user?.name || counterpart?.name || ""}
                />
              )}
            </div>

            {!isChatFullscreen && (
            <aside className="flex flex-col gap-6">
              <div className="order-2 rounded-3xl border border-gray-200 bg-white p-6 shadow-sm">
                <div className="flex items-start gap-4">
                  {counterpartImage ? (
                    <img
                      src={counterpartImage}
                      alt={counterpart?.name || "Profile"}
                      className="h-16 w-16 rounded-2xl object-cover"
                    />
                  ) : (
                    <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-[#F6E8BF] text-2xl text-[#1E3557]">
                      <FaUserCircle />
                    </div>
                  )}

                  <div className="min-w-0 flex-1">
                    <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#D4A73C]">
                      {isAstrologerViewer ? "Client" : "Astrologer"}
                    </p>
                    <h3 className="mt-1 text-xl font-bold text-[#1E3557]">{counterpart?.name || "-"}</h3>
                    <p className="mt-1 text-sm text-gray-500">
                      {isAstrologerViewer
                        ? counterpart?.email || counterpart?.phone || "Registered user"
                        : astrologerDetail?.specialities || "Consultation expert"}
                    </p>
                  </div>
                </div>

                <div className="mt-6 grid grid-cols-2 gap-3">
                  <div className="rounded-2xl bg-[#F8F9FC] px-4 py-3">
                    <p className="text-xs uppercase tracking-wide text-gray-400">Scheduled</p>
                    <p className="mt-1 text-sm font-semibold text-[#1E3557]">
                      {formatDateTime(booking?.scheduled_at)}
                    </p>
                  </div>
                  <div className="rounded-2xl bg-[#F8F9FC] px-4 py-3">
                    <p className="text-xs uppercase tracking-wide text-gray-400">Duration</p>
                    <p className="mt-1 text-sm font-semibold text-[#1E3557]">{booking?.duration || 0} min</p>
                  </div>
                  <div className="rounded-2xl bg-[#F8F9FC] px-4 py-3">
                    <p className="text-xs uppercase tracking-wide text-gray-400">Type</p>
                    <p className="mt-1 text-sm font-semibold capitalize text-[#1E3557]">
                      {booking?.consultation_type === "call" ? "Audio Call" : "Chat Consultation"}
                    </p>
                  </div>
                  <div className="rounded-2xl bg-[#F8F9FC] px-4 py-3">
                    <p className="text-xs uppercase tracking-wide text-gray-400">Amount</p>
                    <p className="mt-1 text-sm font-semibold text-[#1E3557]">Rs {booking?.amount || 0}</p>
                  </div>
                </div>

                {booking?.notes && (
                  <div className="mt-4 rounded-2xl border border-gray-100 bg-[#F8F9FC] px-4 py-3 text-sm text-gray-600">
                    {booking.notes}
                  </div>
                )}

                {!!formatBirthDetails(booking?.birth_details).length && (
                  <div className="mt-4 rounded-2xl border border-[#F1E1B8] bg-[#FFF9EC] px-4 py-3">
                    <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#D4A73C]">
                      Birth Details
                    </p>
                    <div className="mt-3 grid gap-2 text-sm text-[#1E3557]">
                      {formatBirthDetails(booking?.birth_details).map((item) => (
                        <p key={item}>{item}</p>
                      ))}
                    </div>
                  </div>
                )}

              </div>

              <div className="order-1 rounded-3xl border border-gray-200 bg-white p-6 shadow-sm">
                <div className="flex items-center gap-3">
                  <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#F6E8BF] text-[#1E3557]">
                    <FaPhoneAlt />
                  </div>
                  <div>
                    <h3 className="text-lg font-bold text-[#1E3557]">Session Controls</h3>
                    <p className="text-sm text-gray-500">
                      {callEnabled ? callStatus : "Live chat consultation controls."}
                    </p>
                  </div>
                </div>

                <div className="mt-5 space-y-3">
                  <div className="flex items-center justify-between rounded-2xl border border-gray-100 bg-[#F8F9FC] px-4 py-3">
                    <div className="flex items-center gap-2 text-sm font-semibold text-[#1E3557]">
                      <FaClock className="text-[#D4A73C]" />
                      {sessionTimerLabel}
                    </div>
                    <span className="text-sm font-bold text-[#1E3557]">
                      {formatCountdown(displayRemainingSeconds)}
                    </span>
                  </div>

                  <div className="flex items-center justify-between rounded-2xl border border-gray-100 bg-[#F8F9FC] px-4 py-3">
                    <div className="flex items-center gap-2 text-sm font-semibold text-[#1E3557]">
                      <FaRegCircle className="text-[#D4A73C]" />
                      Remote Participant
                    </div>
                    <span className="text-sm font-bold text-[#1E3557]">{remoteParticipantCount}</span>
                  </div>

                  {callEnabled && (
                    <>
                      <button
                        type="button"
                        onClick={() => void handleJoinAudioCall()}
                        disabled={!canJoinCall || callLoading || isClosed || isCallConnected}
                        className="flex w-full items-center justify-center gap-2 rounded-2xl bg-[#1E3557] px-5 py-3 text-sm font-semibold text-white transition hover:bg-[#162744] disabled:cursor-not-allowed disabled:opacity-50"
                      >
                        <FaPhoneAlt />
                        {callActionLabel}
                      </button>

                      <div className="grid grid-cols-2 gap-3">
                        {callAudioBlocked && (
                          <button
                            type="button"
                            onClick={() => void handleEnableRemoteAudio()}
                            className="col-span-2 flex items-center justify-center gap-2 rounded-2xl border border-[#D4A73C] bg-[#FFF8E6] px-4 py-3 text-sm font-semibold text-[#1E3557] transition hover:bg-[#FFF1C9]"
                          >
                            <FaVolumeUp />
                            Enable Audio
                          </button>
                        )}

                        <button
                          type="button"
                          onClick={handleToggleMute}
                          disabled={!zegoEngineRef.current || !localStreamRef.current}
                          className="flex items-center justify-center gap-2 rounded-2xl border border-gray-200 px-4 py-3 text-sm font-semibold text-[#1E3557] transition hover:border-[#1E3557] disabled:cursor-not-allowed disabled:opacity-50"
                        >
                          {callMuted ? <FaMicrophoneSlash /> : <FaMicrophone />}
                          {callMuted ? "Unmute" : "Mute"}
                        </button>

                        <button
                          type="button"
                          onClick={handleLeaveAudioCall}
                          disabled={!zegoEngineRef.current}
                          className="flex items-center justify-center gap-2 rounded-2xl border border-rose-200 px-4 py-3 text-sm font-semibold text-rose-600 transition hover:bg-rose-50 disabled:cursor-not-allowed disabled:opacity-50"
                        >
                          <FaPhoneSlash />
                          Leave Call
                        </button>
                      </div>
                    </>
                  )}

                  {!callEnabled && isAstrologerViewer && !session?.is_live && (
                    <button
                      type="button"
                      onClick={() => void handleStartSession()}
                      disabled={!session?.can_start || startingSession || isClosed}
                      className="flex w-full items-center justify-center gap-2 rounded-2xl bg-[#1E3557] px-5 py-3 text-sm font-semibold text-white transition hover:bg-[#162744] disabled:cursor-not-allowed disabled:opacity-50"
                    >
                      <FaPlayCircle />
                      {startingSession ? "Starting..." : "Start Chat"}
                    </button>
                  )}

                  <button
                    type="button"
                    onClick={() => void handleEndSession()}
                    disabled={!session?.can_end || endingSession || isClosed}
                    className="flex w-full items-center justify-center gap-2 rounded-2xl border border-gray-200 px-5 py-3 text-sm font-semibold text-[#1E3557] transition hover:border-[#1E3557] disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    <FaPowerOff />
                    {endingSession ? "Ending..." : "End Consultation"}
                  </button>
                </div>
              </div>
            </aside>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
