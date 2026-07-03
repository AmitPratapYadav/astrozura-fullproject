import { useState } from "react";
import { UserPlus } from "lucide-react";
import { apiRequest } from "../lib/api";

export default function AddAstrologer() {
  const [formData, setFormData] = useState({
    firstName: "",
    lastName: "",
    email: "",
    password: "",
    experience_years: "",
    languages: "",
    specialities: "",
    chat_price: "",
    call_price: "",
    about_bio: "",
    profile_image: null,
    is_featured: false,
    supports_chat: true,
    supports_call: true,
    is_online: true,
    chat_commission_percentage: "20",
    call_commission_percentage: "20",
    chat_price_10: "", chat_price_15: "", chat_price_20: "", chat_price_30: "",
    call_price_10: "", call_price_15: "", call_price_20: "", call_price_30: "",
    languages_hi: "",
    specialities_hi: "",
    about_bio_hi: "",
  });

  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState(null);

  const handleChange = (e) => {
    if (e.target.name === "profile_image") {
      setFormData({ ...formData, profile_image: e.target.files[0] });
    } else if (e.target.type === "checkbox") {
      setFormData({ ...formData, [e.target.name]: e.target.checked });
    } else {
      setFormData({ ...formData, [e.target.name]: e.target.value });
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setMessage(null);

    try {
      const dataToSubmit = new FormData();
      Object.keys(formData).forEach((key) => {
        if (key.endsWith("_hi") || /^(chat|call)_price_(10|15|20|30)$/.test(key)) return;
        if (formData[key] !== null) {
          const value = ["is_featured", "supports_chat", "supports_call", "is_online"].includes(key)
            ? (formData[key] ? "1" : "0")
            : formData[key];
          dataToSubmit.append(key, value);
        }
      });
      dataToSubmit.append("translations", JSON.stringify({
        hi: {
          languages: formData.languages_hi,
          specialities: formData.specialities_hi,
          about_bio: formData.about_bio_hi,
        },
      }));
      dataToSubmit.append("chat_duration_prices", JSON.stringify(Object.fromEntries([10, 15, 20, 30].map((duration) => [duration, formData[`chat_price_${duration}`]]).filter(([, value]) => value !== ""))));
      dataToSubmit.append("call_duration_prices", JSON.stringify(Object.fromEntries([10, 15, 20, 30].map((duration) => [duration, formData[`call_price_${duration}`]]).filter(([, value]) => value !== ""))));

      const data = await apiRequest("/admin/astrologers/create", {
        method: "POST",
        body: dataToSubmit,
      });

      if (data.success) {
        setMessage({ type: "success", text: "Astrologer created successfully!" });
        setFormData({
          firstName: "",
          lastName: "",
          email: "",
          password: "",
          experience_years: "",
          languages: "",
          specialities: "",
          chat_price: "",
          call_price: "",
          about_bio: "",
          profile_image: null,
          is_featured: false,
          supports_chat: true,
          supports_call: true,
          is_online: true,
          chat_commission_percentage: "20",
          call_commission_percentage: "20",
          chat_price_10: "", chat_price_15: "", chat_price_20: "", chat_price_30: "",
          call_price_10: "", call_price_15: "", call_price_20: "", call_price_30: "",
          languages_hi: "",
          specialities_hi: "",
          about_bio_hi: "",
        });
      } else {
        setMessage({ type: "error", text: data.message || "Failed to create astrologer." });
      }
    } catch (error) {
      console.error(error);
      setMessage({ type: "error", text: "Something went wrong. Check console." });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6 max-w-4xl mx-auto pb-10">
      <div className="flex items-center gap-3">
        <UserPlus size={28} className="text-yellow-600" />
        <h1 className="text-2xl font-bold">Add New Astrologer</h1>
      </div>

      {message && (
        <div className={`p-4 rounded-lg text-sm font-semibold ${message.type === 'success' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
          {message.text}
        </div>
      )}

      <form onSubmit={handleSubmit} className="bg-white p-6 rounded-xl shadow space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Account Details */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold border-b pb-2">Account Details</h3>
            
            <div>
              <label className="block text-sm text-gray-600 mb-1">First Name *</label>
              <input type="text" name="firstName" value={formData.firstName} onChange={handleChange} required className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
            </div>

            <div>
              <label className="block text-sm text-gray-600 mb-1">Last Name</label>
              <input type="text" name="lastName" value={formData.lastName} onChange={handleChange} className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
            </div>

            <div>
              <label className="block text-sm text-gray-600 mb-1">Email Address *</label>
              <input type="email" name="email" value={formData.email} onChange={handleChange} required className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
            </div>

            <div>
              <label className="block text-sm text-gray-600 mb-1">Password *</label>
              <input type="password" name="password" value={formData.password} onChange={handleChange} required minLength={6} className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
            </div>
          </div>

          {/* Professional Details */}
          <div className="space-y-4">
            <h3 className="text-lg font-semibold border-b pb-2">Professional Profile</h3>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-gray-600 mb-1">Experience (Years) *</label>
                <input type="number" name="experience_years" value={formData.experience_years} onChange={handleChange} required className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
              </div>
              
              <div>
                <label className="block text-sm text-gray-600 mb-1">Languages (comma separated)</label>
                <input type="text" name="languages" placeholder="English, Hindi" value={formData.languages} onChange={handleChange} className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
              </div>
            </div>

            <div className="rounded-xl border bg-gray-50 p-4">
              <h3 className="mb-1 font-semibold">Duration Pricing</h3>
              <p className="mb-4 text-xs text-gray-500">Optional total prices. Empty values use the per-minute rate.</p>
              <div className="grid gap-4 sm:grid-cols-2">
                {["chat", "call"].map((mode) => <div key={mode}><p className="mb-2 text-sm font-semibold capitalize">{mode}</p><div className="grid grid-cols-2 gap-2">{[10, 15, 20, 30].map((duration) => <label key={duration} className="text-xs text-gray-500">{duration} minutes<input type="number" min="0" step="0.01" name={`${mode}_price_${duration}`} value={formData[`${mode}_price_${duration}`]} onChange={handleChange} className="mt-1 w-full rounded-lg border bg-white px-3 py-2 text-sm" /></label>)}</div></div>)}
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-gray-600 mb-1">Chat Commission %</label>
                <input type="number" min="0" max="100" step="0.01" name="chat_commission_percentage" value={formData.chat_commission_percentage} onChange={handleChange} className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">Call Commission %</label>
                <input type="number" min="0" max="100" step="0.01" name="call_commission_percentage" value={formData.call_commission_percentage} onChange={handleChange} className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
              </div>
            </div>

            <div className="flex flex-wrap gap-5 rounded-lg bg-gray-50 p-4 text-sm font-medium">
              <label className="flex items-center gap-2"><input type="checkbox" name="supports_chat" checked={formData.supports_chat} onChange={handleChange} /> Available for Chat</label>
              <label className="flex items-center gap-2"><input type="checkbox" name="supports_call" checked={formData.supports_call} onChange={handleChange} /> Available for Call</label>
              <label className="flex items-center gap-2"><input type="checkbox" name="is_online" checked={formData.is_online} onChange={handleChange} /> Online</label>
            </div>

            <div>
              <label className="block text-sm text-gray-600 mb-1">Specialities (comma separated)</label>
              <input type="text" name="specialities" placeholder="Vedic Astrology, Tarot" value={formData.specialities} onChange={handleChange} className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-gray-600 mb-1">Chat Price per min *</label>
                <input type="number" name="chat_price" value={formData.chat_price} onChange={handleChange} required className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
              </div>
              <div>
                <label className="block text-sm text-gray-600 mb-1">Call Price per min *</label>
                <input type="number" name="call_price" value={formData.call_price} onChange={handleChange} required className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" />
              </div>
            </div>
            
          </div>
        </div>

        {/* Full width element */}
        <div className="space-y-4 pt-4 border-t">
          <div>
            <label className="block text-sm text-gray-600 mb-1">Profile Image</label>
            <input type="file" name="profile_image" accept="image/*" onChange={handleChange} className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500 bg-white" />
          </div>

          <div className="grid gap-4 rounded-xl border border-yellow-200 bg-yellow-50 p-4 md:grid-cols-2">
            <div className="md:col-span-2"><h3 className="font-semibold">Hindi Content</h3></div>
            <input name="languages_hi" value={formData.languages_hi} onChange={handleChange} placeholder="Languages in Hindi" className="w-full rounded-lg border px-4 py-2" />
            <input name="specialities_hi" value={formData.specialities_hi} onChange={handleChange} placeholder="Specialities in Hindi" className="w-full rounded-lg border px-4 py-2" />
            <textarea name="about_bio_hi" value={formData.about_bio_hi} onChange={handleChange} rows="3" placeholder="Bio in Hindi" className="w-full rounded-lg border px-4 py-2 md:col-span-2" />
          </div>

          <div>
            <label className="block text-sm text-gray-600 mb-1">About / Bio</label>
            <textarea name="about_bio" value={formData.about_bio} onChange={handleChange} rows="4" className="w-full border rounded-lg px-4 py-2 outline-none focus:border-yellow-500" placeholder="Write a detailed description about the astrologer..."></textarea>
          </div>

          <div className="flex items-center gap-2 mt-2">
            <input type="checkbox" id="is_featured" name="is_featured" checked={formData.is_featured} onChange={handleChange} className="w-4 h-4 text-yellow-500 rounded border-gray-300 focus:ring-yellow-500" />
            <label htmlFor="is_featured" className="text-sm font-medium text-gray-700">Display as Featured Expert on Homepage and Main Profiles</label>
          </div>
        </div>

        <div className="flex justify-end pt-4">
          <button type="submit" disabled={loading} className="bg-yellow-500 hover:bg-yellow-600 text-black px-6 py-2 rounded-lg font-semibold transition disabled:opacity-50">
            {loading ? "Creating..." : "Create Astrologer"}
          </button>
        </div>
      </form>
    </div>
  );
}
