import { useEffect, useMemo, useRef, useState } from "react";
import { Eye, EyeOff, Upload } from "lucide-react";
import { useAppContext } from "../context/AppContext";
import { apiRequest, assetUrl } from "../lib/api";

const createPreview = (value) => (value ? URL.createObjectURL(value) : "");
const MAX_PROFILE_IMAGE_SIZE = 5 * 1024 * 1024;
const SUPPORTED_PROFILE_IMAGE_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/gif",
  "image/webp",
]);

export default function Profile() {
  const { adminUser, refreshProfile, setAdminUser } = useAppContext();
  const [form, setForm] = useState({
    first_name: "",
    last_name: "",
    email: "",
    phone: "",
    password: "",
    profile_image: null,
  });
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [preview, setPreview] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const fileInputRef = useRef(null);

  useEffect(() => {
    const hydrate = async () => {
      try {
        const response = await refreshProfile();
        if (response?.success) {
          const [firstName = "", ...rest] = (response.user?.name || "").split(" ");
          setForm((current) => ({
            ...current,
            first_name: firstName,
            last_name: rest.join(" "),
            email: response.user?.email || "",
            phone: response.user?.phone || "",
            password: "",
            profile_image: null,
          }));
          setPreview(response.user?.profile_image ? assetUrl(response.user.profile_image) : "");
        }
      } catch (error) {
        console.error("Failed to load admin profile", error);
      }
    };

    void hydrate();
  }, [refreshProfile]);

  useEffect(() => {
    return () => {
      if (preview.startsWith("blob:")) {
        URL.revokeObjectURL(preview);
      }
    };
  }, [preview]);

  const adminName = useMemo(() => adminUser?.name || "Admin", [adminUser]);

  const handleChange = (event) => {
    const { name, value, files } = event.target;
    if (name === "profile_image") {
      const file = files?.[0] || null;
      if (file && !SUPPORTED_PROFILE_IMAGE_TYPES.has(file.type)) {
        setMessage("Please select a JPG, PNG, GIF, or WebP image.");
        event.target.value = "";
        return;
      }
      if (file && file.size > MAX_PROFILE_IMAGE_SIZE) {
        setMessage("Profile pictures must be 5 MB or smaller.");
        event.target.value = "";
        return;
      }

      setMessage("");
      setForm((current) => ({ ...current, profile_image: file }));
      setPreview(file ? createPreview(file) : assetUrl(adminUser?.profile_image));
      return;
    }

    setForm((current) => ({ ...current, [name]: value }));
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    try {
      setLoading(true);
      setMessage("");
      const payload = new FormData();
      payload.append("firstName", form.first_name);
      payload.append("lastName", form.last_name);
      payload.append("email", form.email);
      payload.append("phone", form.phone);
      if (form.password) {
        payload.append("password", form.password);
      }
      if (form.profile_image) {
        payload.append("profile_image", form.profile_image);
      }

      const response = await apiRequest("/admin/profile/update", {
        method: "POST",
        body: payload,
      });

      if (response?.success) {
        setAdminUser(response.user);
        localStorage.setItem("admin_user", JSON.stringify(response.user));
        setMessage("Admin profile updated successfully.");
        setForm((current) => ({ ...current, password: "", profile_image: null }));
        setPreview(response.user?.profile_image ? assetUrl(response.user.profile_image) : "");
        setShowPassword(false);
        if (fileInputRef.current) {
          fileInputRef.current.value = "";
        }
      } else {
        setMessage(response?.message || "Unable to update the profile.");
      }
    } catch (error) {
      setMessage(error.message || "Unable to update the profile.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Admin Profile</h1>
        <p className="mt-2 text-sm text-gray-500">
          Update the main admin account details, login email, and profile photo.
        </p>
      </div>

      {message && (
        <div className="rounded-2xl bg-white p-4 text-sm shadow text-gray-700">
          {message}
        </div>
      )}

      <div className="grid gap-6 lg:grid-cols-[320px_1fr]">
        <div className="bg-white rounded-2xl shadow p-6">
          <div className="flex flex-col items-center text-center">
            <div className="h-32 w-32 overflow-hidden rounded-full bg-gray-100">
              {preview ? (
                <img src={preview} alt={adminName} className="h-full w-full object-cover" />
              ) : (
                <div className="h-full w-full flex items-center justify-center text-4xl font-black text-yellow-500">
                  {adminName.charAt(0).toUpperCase()}
                </div>
              )}
            </div>
            <h2 className="mt-4 text-xl font-bold">{adminName}</h2>
            <p className="mt-1 text-sm text-gray-500">{adminUser?.email}</p>
            <p className="mt-4 rounded-full bg-yellow-100 px-4 py-2 text-xs font-semibold text-yellow-700">
              General Administrator
            </p>
          </div>
        </div>

        <form onSubmit={handleSubmit} className="bg-white rounded-2xl shadow p-6 space-y-5">
          <div className="grid gap-5 md:grid-cols-2">
            <div>
              <label className="block text-sm font-medium text-gray-600 mb-2">First Name</label>
              <input
                name="first_name"
                value={form.first_name}
                onChange={handleChange}
                className="w-full rounded-xl border px-4 py-3 outline-none focus:border-yellow-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-600 mb-2">Last Name</label>
              <input
                name="last_name"
                value={form.last_name}
                onChange={handleChange}
                className="w-full rounded-xl border px-4 py-3 outline-none focus:border-yellow-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-600 mb-2">Email</label>
              <input
                name="email"
                type="email"
                value={form.email}
                onChange={handleChange}
                className="w-full rounded-xl border px-4 py-3 outline-none focus:border-yellow-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-600 mb-2">Phone</label>
              <input
                name="phone"
                value={form.phone}
                onChange={handleChange}
                className="w-full rounded-xl border px-4 py-3 outline-none focus:border-yellow-500"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-600 mb-2">New Password</label>
              <div className="relative">
                <input
                  name="password"
                  type={showPassword ? "text" : "password"}
                  value={form.password}
                  onChange={handleChange}
                  autoComplete="new-password"
                  minLength={6}
                  placeholder="Leave blank to keep the current password"
                  className="w-full rounded-xl border px-4 py-3 pr-12 outline-none focus:border-yellow-500"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((current) => !current)}
                  className="absolute inset-y-0 right-0 flex w-12 items-center justify-center text-gray-500 hover:text-gray-900"
                  aria-label={showPassword ? "Hide password" : "Show password"}
                >
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
              <p className="mt-1 text-xs text-gray-400">Use at least 6 characters.</p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-600 mb-2">Profile Picture</label>
              <label className="flex min-h-12 cursor-pointer items-center gap-3 rounded-xl border px-4 py-3 transition hover:border-yellow-500">
                <Upload size={18} className="shrink-0 text-yellow-600" />
                <span className="min-w-0 truncate text-sm text-gray-600">
                  {form.profile_image?.name || "Choose a profile picture"}
                </span>
                <input
                  ref={fileInputRef}
                  name="profile_image"
                  type="file"
                  accept=".jpg,.jpeg,.png,.gif,.webp,image/jpeg,image/png,image/gif,image/webp"
                  onChange={handleChange}
                  className="sr-only"
                />
              </label>
              <p className="mt-1 text-xs text-gray-400">JPG, PNG, GIF, or WebP up to 5 MB.</p>
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="rounded-xl bg-yellow-500 px-5 py-3 font-semibold text-black transition hover:bg-yellow-400 disabled:opacity-60"
          >
            {loading ? "Saving..." : "Save Profile Changes"}
          </button>
        </form>
      </div>
    </div>
  );
}
