import { useState } from "react";
import { apiRequest } from "../lib/api";

export default function Offers() {
  const [form, setForm] = useState({ title: "", message: "", action_url: "", expires_at: "" });
  const [status, setStatus] = useState("");
  const submit = async (event) => {
    event.preventDefault();
    setStatus("Sending...");
    try {
      const response = await apiRequest("/admin/offers", { method: "POST", body: form });
      setStatus(`Offer sent to ${response.recipients || response.count || 0} shop users.`);
      setForm({ title: "", message: "", action_url: "", expires_at: "" });
    } catch (error) { setStatus(error.message); }
  };
  return <div className="mx-auto max-w-3xl space-y-6"><div><h1 className="text-2xl font-bold">Offers & Notifications</h1><p className="text-sm text-gray-500">Broadcast an offer to shop notification feeds.</p></div>{status && <div className="rounded-xl bg-white p-4 shadow">{status}</div>}<form onSubmit={submit} className="space-y-5 rounded-xl bg-white p-6 shadow"><div><label className="mb-1 block text-sm font-medium">Title</label><input required value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} className="w-full rounded-lg border p-3" /></div><div><label className="mb-1 block text-sm font-medium">Message</label><textarea required rows="5" value={form.message} onChange={(e) => setForm({ ...form, message: e.target.value })} className="w-full rounded-lg border p-3" /></div><div className="grid gap-4 md:grid-cols-2"><div><label className="mb-1 block text-sm font-medium">Destination URL</label><input value={form.action_url} onChange={(e) => setForm({ ...form, action_url: e.target.value })} placeholder="https://shop.astrozura.com/..." className="w-full rounded-lg border p-3" /></div><div><label className="mb-1 block text-sm font-medium">Expiry</label><input type="datetime-local" value={form.expires_at} onChange={(e) => setForm({ ...form, expires_at: e.target.value })} className="w-full rounded-lg border p-3" /></div></div><button className="rounded-lg bg-yellow-500 px-5 py-3 font-semibold">Broadcast Offer</button></form></div>;
}
