import { useEffect, useState } from "react";
import { Clock3, Pencil, UserRound, X } from "lucide-react";
import { getRecentProfiles, updateRecentProfile } from "../api/recentProfilesApi";
import { useAuth } from "../context/AuthContext";
import { recentProfileDisplayName } from "../utils/recentProfile";

const formatDate = (date) => {
  if (!date) return "-";
  const [year, month, day] = String(date).split("-");
  return year && month && day ? `${day}-${month}-${year}` : date;
};

export default function RecentProfilePicker({
  onSelect,
  buttonLabel = "Choose a recent profile",
  description = "Reuse saved birth details in one tap.",
  className = "",
}) {
  const { user } = useAuth();
  const [open, setOpen] = useState(false);
  const [profiles, setProfiles] = useState([]);
  const [loading, setLoading] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [labelDraft, setLabelDraft] = useState("");
  const [message, setMessage] = useState("");

  useEffect(() => {
    if (!open || !user) return;
    setLoading(true);
    setMessage("");
    getRecentProfiles()
      .then((response) => setProfiles(response?.data || []))
      .catch(() => setMessage("Unable to load recent profiles."))
      .finally(() => setLoading(false));
  }, [open, user]);

  if (!user) return null;

  const handleUse = (profile) => {
    onSelect?.(profile);
    setOpen(false);
  };

  const startEdit = (profile) => {
    setEditingId(profile.id);
    setLabelDraft(profile.profile_label || profile.person_name || "");
  };

  const saveLabel = async (profile) => {
    try {
      const response = await updateRecentProfile(profile.id, { profile_label: labelDraft.trim() || null });
      setProfiles((current) => current.map((item) => (item.id === profile.id ? response.data : item)));
      setEditingId(null);
      setLabelDraft("");
    } catch {
      setMessage("Profile name could not be updated.");
    }
  };

  return (
    <>
      <div className="space-y-1.5">
        <button
          type="button"
          onClick={() => setOpen(true)}
          className={`inline-flex w-full items-center justify-center gap-2 rounded-2xl border border-[#D4A73C]/40 bg-[#fff9e8] px-4 py-2.5 text-sm font-black text-[#7a5205] transition hover:bg-[#fff3cd] ${className}`}
        >
          <Clock3 size={16} />
          {buttonLabel}
        </button>
        {description ? (
          <p className="px-1 text-center text-[11px] font-semibold leading-5 text-slate-500 sm:text-xs">
            {description}
          </p>
        ) : null}
      </div>

      {open ? (
        <div className="fixed inset-0 z-[90] flex items-end justify-center bg-slate-950/55 px-3 py-4 sm:items-center">
          <div className="max-h-[88vh] w-full max-w-3xl overflow-hidden rounded-3xl bg-white shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-100 bg-[#1E3557] px-5 py-4 text-white">
              <div>
                <h3 className="text-lg font-black">Recent Birth Profiles</h3>
                <p className="text-xs font-medium text-white/70">Pick a saved profile to fill this form.</p>
              </div>
              <button type="button" onClick={() => setOpen(false)} className="rounded-full bg-white/10 p-2 hover:bg-white/20">
                <X size={18} />
              </button>
            </div>

            <div className="max-h-[70vh] overflow-y-auto p-4 sm:p-5">
              {message ? <p className="mb-3 rounded-xl bg-rose-50 px-4 py-3 text-sm font-semibold text-rose-700">{message}</p> : null}
              {loading ? <p className="rounded-xl bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-600">Loading profiles...</p> : null}

              {!loading && profiles.length === 0 ? (
                <div className="rounded-2xl border border-dashed border-slate-200 p-6 text-center">
                  <UserRound className="mx-auto text-slate-300" size={34} />
                  <p className="mt-3 text-sm font-semibold text-slate-500">No recent profiles yet. Generate a Kundali, report, or calculator to save one.</p>
                </div>
              ) : null}

              <div className="grid gap-3 sm:grid-cols-2">
                {profiles.map((profile) => (
                  <div key={profile.id} className="rounded-2xl border border-slate-100 bg-[#fbfcff] p-4 shadow-sm">
                    {editingId === profile.id ? (
                      <div className="space-y-2">
                        <input
                          value={labelDraft}
                          onChange={(event) => setLabelDraft(event.target.value)}
                          placeholder="Profile name"
                          className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-[#D4A73C]"
                        />
                        <div className="flex gap-2">
                          <button type="button" onClick={() => saveLabel(profile)} className="rounded-xl bg-[#1E3557] px-3 py-2 text-xs font-bold text-white">
                            Save
                          </button>
                          <button type="button" onClick={() => setEditingId(null)} className="rounded-xl border border-slate-200 px-3 py-2 text-xs font-bold text-slate-600">
                            Cancel
                          </button>
                        </div>
                      </div>
                    ) : (
                      <>
                        <div className="flex items-start justify-between gap-3">
                          <div>
                            <p className="text-base font-black text-[#1E3557]">{recentProfileDisplayName(profile)}</p>
                            <p className="mt-1 text-xs font-semibold text-slate-500">
                              {formatDate(profile.date_of_birth)} at {profile.time_of_birth || "-"}
                            </p>
                          </div>
                          <button type="button" onClick={() => startEdit(profile)} className="rounded-full border border-slate-100 bg-white p-2 text-slate-500 hover:text-[#1E3557]">
                            <Pencil size={14} />
                          </button>
                        </div>
                        <p className="mt-3 line-clamp-2 text-sm font-medium text-slate-600">{profile.place_of_birth || "Birthplace not saved"}</p>
                        <div className="mt-4 flex flex-wrap items-center justify-between gap-2">
                          <span className="rounded-full bg-[#fff8df] px-3 py-1 text-[11px] font-black uppercase tracking-wide text-[#8a650d]">
                            {profile.relation_role || "profile"}
                          </span>
                          <button type="button" onClick={() => handleUse(profile)} className="rounded-xl bg-[#D4A73C] px-4 py-2 text-xs font-black text-[#1E3557]">
                            Use profile
                          </button>
                        </div>
                      </>
                    )}
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      ) : null}
    </>
  );
}
