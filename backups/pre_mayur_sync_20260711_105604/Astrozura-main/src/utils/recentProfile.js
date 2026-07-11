export const profileTime = (value) => (value ? String(value).slice(0, 5) : "");

export const buildRecentProfilePayload = ({
  name,
  gender,
  date,
  time,
  place,
  coordinates,
  sourceModule,
  relationRole = "self",
  profileLabel,
  metadata,
}) => ({
  profile_label: profileLabel || undefined,
  person_name: name || undefined,
  gender: gender || undefined,
  date_of_birth: date || undefined,
  time_of_birth: profileTime(time) || undefined,
  place_of_birth: place || undefined,
  coordinates: coordinates || undefined,
  source_module: sourceModule || undefined,
  relation_role: relationRole || undefined,
  metadata: metadata || undefined,
});

export const recentProfileDisplayName = (profile) =>
  profile?.profile_label || profile?.person_name || "Saved birth profile";
