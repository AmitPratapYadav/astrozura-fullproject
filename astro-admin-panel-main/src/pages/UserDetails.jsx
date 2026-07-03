import { ArrowLeft } from "lucide-react";
import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { apiRequest, assetUrl } from "../lib/api";

export default function UserDetails() {
  const { id } = useParams();
  const [data, setData] = useState(null);
  useEffect(() => { apiRequest(`/admin/users/${id}`).then(setData); }, [id]);
  if (!data) return <p>Loading user activity...</p>;
  const { user, summary } = data;
  return <div className="space-y-6">
    <div className="flex items-center gap-3"><Link to="/users"><ArrowLeft /></Link>{user.profile_image ? <img src={assetUrl(user.profile_image)} alt="" className="h-14 w-14 rounded-full object-cover" /> : <div className="flex h-14 w-14 items-center justify-center rounded-full bg-yellow-100 font-bold">{user.name?.[0] || "U"}</div>}<div><h1 className="text-2xl font-bold">{user.name}</h1><p className="text-sm text-gray-500">{user.email || user.phone}</p></div></div>
    <div className="grid grid-cols-2 gap-4 lg:grid-cols-5">{[["Orders", summary.orders], ["Consultations", summary.consultations], ["Rituals", summary.rituals], ["Order spend", `₹${summary.order_spend}`], ["Consultation spend", `₹${summary.consultation_spend}`]].map(([label, value]) => <div key={label} className="rounded-xl bg-white p-4 shadow"><p className="text-xs text-gray-500">{label}</p><p className="mt-2 text-xl font-bold">{value}</p></div>)}</div>
    <Activity title="Orders" rows={user.orders} render={(row) => <><b>{row.order_number}</b><span>{row.status}</span><span>₹{row.total_amount}</span></>} />
    <Activity title="Consultations" rows={user.bookings} render={(row) => <><b>#{row.id} · {row.astrologer?.name || row.astrologer_name}</b><span>{row.consultation_type} · {row.status}</span><span>{row.booking_date} {row.booking_time}</span></>} />
    <Activity title="Pooja Anusthan" rows={user.ritual_bookings} render={(row) => <><b>{row.ritual?.name || "Ritual booking"}</b><span>{row.status}</span><span>{row.preferred_date || "-"}</span></>} />
  </div>;
}

function Activity({ title, rows = [], render }) {
  return <section className="rounded-xl bg-white p-5 shadow"><h2 className="mb-4 text-lg font-bold">{title}</h2><div className="space-y-2">{rows.map((row) => <div key={row.id} className="grid gap-2 rounded-lg border p-3 text-sm md:grid-cols-3">{render(row)}</div>)}{!rows.length && <p className="text-sm text-gray-500">No activity yet.</p>}</div></section>;
}
