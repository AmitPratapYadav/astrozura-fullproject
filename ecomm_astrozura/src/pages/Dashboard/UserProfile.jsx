import { useState, useEffect } from "react";
import { useAuth } from "../../context/AuthContext";
import api from "../../api/axios";
import { assetUrl } from "../../utils/assetUrl";

const appendIfPresent = (payload, key, value) => {
  const normalized = typeof value === "string" ? value.trim() : value;
  if (normalized !== "" && normalized !== null && normalized !== undefined) {
    payload.append(key, normalized);
  }
};

export default function UserProfile() {
  const { user, updateUser } = useAuth();
  const [isEditing, setIsEditing] = useState(false);
  const [loading, setLoading] = useState(false);
  const [profileFile, setProfileFile] = useState(null);
  const [profilePreview, setProfilePreview] = useState(assetUrl(user?.profile_image));
  const [addressId, setAddressId] = useState(null);
  const [profile, setProfile] = useState({
    firstName: user?.name?.split(" ")[0] || "",
    lastName: user?.name?.split(" ").slice(1).join(" ") || "",
    email: user?.email || "",
    phone: user?.phone || "",
    address: "",
    city: "",
    state: "",
    pincode: "",
  });

  useEffect(() => {
    if (user) {
      setProfile((current) => ({
        ...current,
        firstName: user.name?.split(" ")[0] || "",
        lastName: user.name?.split(" ").slice(1).join(" ") || "",
        email: user.email || "",
        phone: user.phone || "",
      }));
      setProfilePreview(assetUrl(user.profile_image));
    }
  }, [user]);

  useEffect(() => {
    api.get("/dashboard/addresses")
      .then((response) => {
        const address = (response.data?.data || []).find((item) => item.is_default)
          || response.data?.data?.[0];
        if (!address) return;
        setAddressId(address.id);
        setProfile((current) => ({
          ...current,
          address: address.address_line || "",
          city: address.city || "",
          state: address.state || "",
          pincode: address.postal_code || "",
          phone: current.phone || address.phone || "",
        }));
      })
      .catch(() => {});
  }, []);

  const handleChange = (e) => {
    setProfile({ ...profile, [e.target.name]: e.target.value });
  };

  const handleProfileImageChange = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setProfileFile(file);
    setProfilePreview((current) => {
      if (current?.startsWith("blob:")) URL.revokeObjectURL(current);
      return URL.createObjectURL(file);
    });
  };

  const handleSave = async () => {
    setLoading(true);
    try {
      const payload = new FormData();
      payload.append("name", `${profile.firstName} ${profile.lastName}`.trim());
      appendIfPresent(payload, "phone", profile.phone);
      appendIfPresent(payload, "email", profile.email);
      if (profileFile) {
        payload.append("profile_image", profileFile);
      }

      const response = await api.post("/dashboard/profile/update", payload);

      if (response.data.status === "success") {
        if (profile.address.trim()) {
          const addressPayload = {
            label: "Home",
            recipient_name: `${profile.firstName} ${profile.lastName}`.trim(),
            phone: profile.phone,
            address_line: profile.address,
            city: profile.city,
            state: profile.state,
            postal_code: profile.pincode,
            country: "India",
            is_default: true,
          };
          const addressResponse = addressId
            ? await api.put(`/dashboard/addresses/${addressId}`, addressPayload)
            : await api.post("/dashboard/addresses", addressPayload);
          setAddressId(addressResponse.data?.data?.id || addressId);
        }
        updateUser(response.data.data);
        setProfileFile(null);
        setProfilePreview(assetUrl(response.data.data.profile_image));
        setIsEditing(false);
        alert("Profile updated successfully!");
      }
    } catch (error) {
      console.error("Profile update failed:", error);
      alert(error.response?.data?.message || "Failed to update profile.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-8 animate-fadeIn">
      {/* HEADER */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">My Profile</h2>
          <p className="text-gray-500 mt-1">Update your personal information and contact details.</p>
        </div>
        <button
          onClick={() => isEditing ? handleSave() : setIsEditing(true)}
          className={`px-6 py-2 rounded-xl text-sm font-bold transition-all ${
            isEditing 
            ? "bg-green-500 text-white hover:bg-green-600 shadow-lg shadow-green-200" 
            : "bg-[#1d1d2b] text-white hover:bg-[#2d2d3b]"
          }`}
        >
          {isEditing ? "Save Changes" : "Edit Profile"}
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* LEFT COLUMN: BASIC INFO */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-white rounded-2xl p-6 md:p-8 shadow-sm border border-gray-100 space-y-6">
            <h3 className="text-lg font-bold text-gray-900 border-b border-gray-50 pb-4">Personal Details</h3>
            <div className="flex flex-col gap-5 rounded-2xl border border-dashed border-[#c9a227]/40 bg-[#fff9e8] p-5 sm:flex-row sm:items-center">
              <div className="flex h-24 w-24 items-center justify-center overflow-hidden rounded-2xl bg-white text-3xl font-bold text-[#1d1d2b] shadow-sm">
                {profilePreview ? (
                  <img src={profilePreview} alt={profile.firstName || "User"} className="h-full w-full object-cover" />
                ) : (
                  profile.firstName ? profile.firstName[0].toUpperCase() : "U"
                )}
              </div>
              <div className="flex-1">
                <label className="text-xs font-bold uppercase tracking-wider text-gray-500">Profile Picture</label>
                <p className="mt-1 text-sm text-gray-500">Shown in your AstroZura and shop profile header.</p>
                <input
                  type="file"
                  accept="image/jpeg,image/png,image/jpg,image/gif,image/webp"
                  onChange={handleProfileImageChange}
                  disabled={!isEditing}
                  className="mt-4 block w-full text-sm text-gray-700 file:mr-4 file:rounded-xl file:border-0 file:bg-[#1d1d2b] file:px-5 file:py-2.5 file:text-sm file:font-bold file:text-white disabled:opacity-70"
                />
              </div>
            </div>
            
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
              <div className="space-y-2">
                <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">First Name</label>
                <input
                  type="text"
                  name="firstName"
                  value={profile.firstName}
                  onChange={handleChange}
                  disabled={!isEditing}
                  className="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-[#c9a227] disabled:opacity-70 disabled:cursor-not-allowed transition"
                />
              </div>
              <div className="space-y-2">
                <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">Last Name</label>
                <input
                  type="text"
                  name="lastName"
                  value={profile.lastName}
                  onChange={handleChange}
                  disabled={!isEditing}
                  className="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-[#c9a227] disabled:opacity-70 disabled:cursor-not-allowed transition"
                />
              </div>
              <div className="space-y-2 sm:col-span-2">
                <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">Email Address</label>
                <input
                  type="email"
                  name="email"
                  value={profile.email}
                  disabled={true} // Usually email isn't directly editable
                  className="w-full bg-gray-100 border border-gray-200 rounded-xl px-4 py-3 text-sm opacity-70 cursor-not-allowed transition"
                />
              </div>
              <div className="space-y-2">
                <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">Phone Number</label>
                <input
                  type="tel"
                  name="phone"
                  value={profile.phone}
                  onChange={handleChange}
                  disabled={!isEditing}
                  placeholder="+91 XXXXX XXXXX"
                  className="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-[#c9a227] disabled:opacity-70 disabled:cursor-not-allowed transition"
                />
              </div>
            </div>
          </div>

          <div className="bg-white rounded-2xl p-6 md:p-8 shadow-sm border border-gray-100 space-y-6">
            <h3 className="text-lg font-bold text-gray-900 border-b border-gray-50 pb-4">Shipping Address</h3>
            
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
              <div className="space-y-2 sm:col-span-2">
                <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">Street Address</label>
                <textarea
                  name="address"
                  value={profile.address}
                  onChange={handleChange}
                  disabled={!isEditing}
                  placeholder="Enter your full address"
                  className="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-[#c9a227] disabled:opacity-70 disabled:cursor-not-allowed transition h-24 resize-none"
                />
              </div>
              <div className="space-y-2">
                <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">City</label>
                <input
                  type="text"
                  name="city"
                  value={profile.city}
                  onChange={handleChange}
                  disabled={!isEditing}
                  className="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-[#c9a227] transition"
                />
              </div>
              <div className="space-y-2">
                <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">State</label>
                <input
                  type="text"
                  name="state"
                  value={profile.state}
                  onChange={handleChange}
                  disabled={!isEditing}
                  className="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-[#c9a227] transition"
                />
              </div>
              <div className="space-y-2">
                <label className="text-xs font-bold text-gray-500 uppercase tracking-wider">Pincode</label>
                <input
                  type="text"
                  name="pincode"
                  value={profile.pincode}
                  onChange={handleChange}
                  disabled={!isEditing}
                  className="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:border-[#c9a227] transition"
                />
              </div>
            </div>
          </div>
        </div>

        {/* RIGHT COLUMN: PREVIEW CARD */}
        <div className="space-y-6">
          <div className="bg-[#1d1d2b] rounded-2xl p-8 text-white text-center shadow-xl">
            <div className="mx-auto flex h-24 w-24 items-center justify-center overflow-hidden rounded-full border-4 border-white/10 bg-[#c9a227] text-3xl font-bold shadow-lg">
              {profilePreview ? (
                <img src={profilePreview} alt={profile.firstName || "User"} className="h-full w-full object-cover" />
              ) : (
                profile.firstName ? profile.firstName[0].toUpperCase() : "U"
              )}
            </div>
            <h4 className="mt-6 text-xl font-bold">{profile.firstName} {profile.lastName}</h4>
            <p className="text-gray-400 text-sm mt-1">{profile.email}</p>
            
            <div className="mt-8 grid grid-cols-2 gap-4 border-t border-white/10 pt-8">
              <div>
                <p className="text-xs font-bold text-gray-500 uppercase">Member Since</p>
                <p className="text-sm font-medium mt-1">Oct 2023</p>
              </div>
              <div>
                <p className="text-xs font-bold text-gray-500 uppercase">Status</p>
                <p className="text-sm font-medium mt-1 text-green-400">Verified</p>
              </div>
            </div>
          </div>
          
          <div className="bg-[#c9a227]/10 border border-[#c9a227]/20 rounded-2xl p-6">
            <div className="flex items-center gap-3 mb-3">
              <span className="text-2xl">🔒</span>
              <h4 className="font-bold text-gray-900">Privacy & Security</h4>
            </div>
            <p className="text-xs text-gray-600 leading-relaxed">
              Your data is encrypted and secure. We never share your personal information with third parties.
            </p>
            <button className="mt-4 text-xs font-bold text-[#c9a227] hover:underline">Change Password →</button>
          </div>
        </div>
      </div>
    </div>
  );
}
