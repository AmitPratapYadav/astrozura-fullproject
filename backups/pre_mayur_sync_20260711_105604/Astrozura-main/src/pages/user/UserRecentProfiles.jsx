import { useEffect, useState } from "react";
import { Clock3, Pencil, Save, Trash2 } from "lucide-react";
import Navbar from "../../components/Navbar";
import Footer from "../../components/Footer";
import UserDashboardSidebar from "../../components/UserDashboardSidebar";
import { deleteRecentProfile, getRecentProfiles, updateRecentProfile } from "../../api/recentProfilesApi";
import { recentProfileDisplayName } from "../../utils/recentProfile";

const formatDate = (date) => {
  if (!date) return "-";
  const [year, month, day] = String(date).split("-");
  return year && month && day ? `${day}-${month}-${year}` : date;
};

export default function UserRecentProfiles() {
  const [profiles, setProfiles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editingId, setEditingId] = useState(null);
  const [labelDraft, setLabelDraft] = useState("");
  const [message, setMessage] = useState("");

  const loadProfiles = () => {
    setLoading(true);
    getRecentProfiles()
      .then((response) => setProfiles(response?.data || []))
      .catch(() => setMessage("Unable to load recent profiles."))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadProfiles();
  }, []);

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
      setMessage("Profile name updated.");
    } catch {
      setMessage("Profile name could not be updated.");
    }
  };

  const removeProfile = async (profile) => {
    try {
      await deleteRecentProfile(profile.id);
      setProfiles((current) => current.filter((item) => item.id !== profile.id));
    } catch {
      setMessage("Profile could not be deleted.");
    }
  };

  return (
    <div className="min-h-screen bg-[#FBF7F0] text-[#1E3557]">
      <Navbar />
      <main className="mx-auto flex max-w-7xl flex-col gap-8 px-4 py-10 md:px-8 lg:flex-row">
        <UserDashboardSidebar />
        <section className="min-w-0 flex-1">
          <div className="rounded-3xl border border-gray-100 bg-white p-6 shadow-sm md:p-8">
            <div className="flex flex-col gap-4 border-b border-slate-100 pb-6 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <p className="text-xs font-black uppercase tracking-[0.22em] text-[#D4A73C]">Saved inputs</p>
                <h1 className="mt-2 text-3xl font-black">Recent Birth Profiles</h1>
                <p className="mt-2 text-sm text-slate-500">Profiles saved from Kundali, matchmaking, reports, and birth-detail calculators.</p>
              </div>
              <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-[#fff8df] text-[#8a650d]">
                <Clock3 size={26} />
              </div>
            </div>

            {message ? <p className="mt-5 rounded-xl bg-[#fff8df] px-4 py-3 text-sm font-semibold text-[#7a5205]">{message}</p> : null}
            {loading ? <p className="mt-6 rounded-xl bg-slate-50 px-4 py-3 text-sm font-semibold text-slate-600">Loading profiles...</p> : null}

            {!loading && profiles.length === 0 ? (
              <div className="mt-6 rounded-2xl border border-dashed border-slate-200 p-8 text-center">
                <p className="text-sm font-semibold text-slate-500">No profiles saved yet. Run a supported calculator or report to create one automatically.</p>
              </div>
            ) : null}

            <div className="mt-6 grid gap-4 md:grid-cols-2">
              {profiles.map((profile) => (
                <article key={profile.id} className="rounded-2xl border border-slate-100 bg-[#fbfcff] p-5 shadow-sm">
                  <div className="flex items-start justify-between gap-4">
                    <div className="min-w-0">
                      {editingId === profile.id ? (
                        <input
                          value={labelDraft}
                          onChange={(event) => setLabelDraft(event.target.value)}
                          placeholder="Profile name"
                          className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm outline-none focus:border-[#D4A73C]"
                        />
                      ) : (
                        <h2 className="truncate text-lg font-black text-[#1E3557]">{recentProfileDisplayName(profile)}</h2>
                      )}
                      <p className="mt-1 text-xs font-bold uppercase tracking-wide text-slate-400">{profile.source_module || "AstroZura"} · {profile.relation_role || "profile"}</p>
                    </div>
                    <div className="flex gap-2">
                      {editingId === profile.id ? (
                        <button type="button" onClick={() => saveLabel(profile)} className="rounded-full bg-[#1E3557] p-2 text-white">
                          <Save size={15} />
                        </button>
                      ) : (
                        <button type="button" onClick={() => startEdit(profile)} className="rounded-full border border-slate-100 bg-white p-2 text-slate-500">
                          <Pencil size={15} />
                        </button>
                      )}
                      <button type="button" onClick={() => removeProfile(profile)} className="rounded-full border border-rose-100 bg-white p-2 text-rose-500">
                        <Trash2 size={15} />
                      </button>
                    </div>
                  </div>

                  <dl className="mt-5 grid gap-3 text-sm sm:grid-cols-2">
                    <div className="rounded-xl bg-white p-3">
                      <dt className="text-[10px] font-black uppercase tracking-wider text-slate-500">Name</dt>
                      <dd className="mt-1 font-bold text-[#1E3557]">{profile.person_name || "-"}</dd>
                    </div>
                    <div className="rounded-xl bg-white p-3">
                      <dt className="text-[10px] font-black uppercase tracking-wider text-slate-500">Birth Date</dt>
                      <dd className="mt-1 font-bold text-[#1E3557]">{formatDate(profile.date_of_birth)}</dd>
                    </div>
                    <div className="rounded-xl bg-white p-3">
                      <dt className="text-[10px] font-black uppercase tracking-wider text-slate-500">Birth Time</dt>
                      <dd className="mt-1 font-bold text-[#1E3557]">{profile.time_of_birth || "-"}</dd>
                    </div>
                    <div className="rounded-xl bg-white p-3">
                      <dt className="text-[10px] font-black uppercase tracking-wider text-slate-500">Used</dt>
                      <dd className="mt-1 font-bold text-[#1E3557]">{profile.usage_count || 1} times</dd>
                    </div>
                  </dl>
                  <p className="mt-4 rounded-xl bg-white p-3 text-sm font-medium text-slate-600">{profile.place_of_birth || "Birthplace not saved"}</p>
                </article>
              ))}
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </div>
  );
}
