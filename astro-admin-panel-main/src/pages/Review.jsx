import { useEffect, useState } from "react";
import { apiRequest } from "../lib/api";

const formatDate = (value) =>
  value
    ? new Date(value).toLocaleString("en-IN", {
        dateStyle: "medium",
        timeStyle: "short",
        timeZone: "Asia/Kolkata",
      })
    : "-";

function Review() {
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [flaggedOnly, setFlaggedOnly] = useState(false);
  const [message, setMessage] = useState("");

  const loadReviews = async () => {
    setLoading(true);
    setMessage("");
    try {
      const response = await apiRequest(`/admin/astrologer-reviews?per_page=80${flaggedOnly ? "&flagged=1" : ""}`);
      setReviews(response.reviews?.data || response.reviews || []);
    } catch (error) {
      setMessage(error.message || "Unable to load reviews.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadReviews();
  }, [flaggedOnly]);

  const deleteReview = async (review) => {
    if (!window.confirm("Delete this review permanently?")) return;

    try {
      await apiRequest(`/admin/astrologer-reviews/${review.id}`, { method: "DELETE" });
      setMessage("Review deleted and astrologer rating summary refreshed.");
      await loadReviews();
    } catch (error) {
      setMessage(error.message || "Unable to delete review.");
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-yellow-500">Moderation</p>
          <h1 className="text-2xl font-bold">Astrologer Reviews</h1>
        </div>
        <button
          type="button"
          onClick={() => setFlaggedOnly((value) => !value)}
          className={`rounded-xl px-5 py-2 text-sm font-bold ${
            flaggedOnly ? "bg-yellow-400 text-black" : "bg-slate-900 text-white"
          }`}
        >
          {flaggedOnly ? "Showing Flagged" : "Show Flagged Only"}
        </button>
      </div>

      {message && (
        <div className="rounded-xl border border-yellow-200 bg-yellow-50 px-4 py-3 text-sm font-semibold text-slate-800">
          {message}
        </div>
      )}

      <div className="overflow-hidden rounded-xl bg-white shadow">
        {loading ? (
          <div className="p-10 text-center text-slate-500">Loading reviews...</div>
        ) : reviews.length ? (
          <div className="overflow-x-auto">
            <table className="min-w-[1000px] w-full text-sm">
              <thead className="bg-slate-100 text-left">
                <tr>
                  {["Client", "Astrologer", "Booking", "Rating", "Review", "Status", "Created", "Action"].map((heading) => (
                    <th key={heading} className="p-4 font-bold text-slate-700">
                      {heading}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {reviews.map((review) => (
                  <tr key={review.id} className="border-t align-top hover:bg-slate-50">
                    <td className="p-4">
                      <p className="font-bold text-slate-900">{review.user?.name || "-"}</p>
                      <p className="text-xs text-slate-500">{review.user?.email || ""}</p>
                    </td>
                    <td className="p-4 font-semibold">{review.astrologer?.name || "-"}</td>
                    <td className="p-4">
                      <p className="font-semibold">{review.booking?.booking_reference || "-"}</p>
                      <p className="text-xs text-slate-500">{formatDate(review.booking?.scheduled_at)}</p>
                    </td>
                    <td className="p-4 font-bold text-yellow-600">{review.rating}/5</td>
                    <td className="max-w-md p-4 text-slate-700">{review.review || "-"}</td>
                    <td className="p-4">
                      <div className="flex flex-col gap-2">
                        {review.is_pinned && <span className="rounded-full bg-blue-100 px-3 py-1 text-xs font-bold text-blue-700">Pinned</span>}
                        {review.is_flagged && <span className="rounded-full bg-red-100 px-3 py-1 text-xs font-bold text-red-700">Flagged</span>}
                        {review.flag_reason && <p className="max-w-xs text-xs text-slate-500">{review.flag_reason}</p>}
                      </div>
                    </td>
                    <td className="p-4 text-slate-500">{formatDate(review.created_at)}</td>
                    <td className="p-4">
                      <button
                        type="button"
                        onClick={() => void deleteReview(review)}
                        className="rounded-lg border border-red-200 px-3 py-2 text-xs font-bold text-red-600 hover:bg-red-50"
                      >
                        Delete
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="p-10 text-center text-slate-500">No reviews found.</div>
        )}
      </div>
    </div>
  );
}

export default Review;
