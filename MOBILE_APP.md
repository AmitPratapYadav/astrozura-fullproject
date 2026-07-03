# AstroZura Mobile App

The customer-facing Flutter application is part of this workspace at:

```text
D:\astrozura-fullproject\astrozura_mobile
```

Read [`astrozura_mobile/PROJECT_MEMORY.md`](astrozura_mobile/PROJECT_MEMORY.md)
before changing authentication, API contracts, payments, Zego sessions,
signing, or platform configuration.

## Production API

The default API base is:

```text
https://astrozura.com/apigateway/index.php/api
```

Override it for local-device development with:

```powershell
flutter run -d <device-id> `
  --dart-define=ASTROZURA_API_BASE_URL=http://<LAN-IP>:8000/api
```

Legacy `/uploads` and `/storage` media paths resolve against
`https://astrozura.com`; absolute DigitalOcean Spaces URLs are preserved.

## Verification

From `astrozura_mobile`:

```powershell
flutter pub get
flutter test
flutter analyze
flutter build apk --release --split-per-abi
```

The 2026-07-03 gateway-fix build passed and produced an ARM64 APK of
81,731,716 bytes. A local distribution copy is stored under
`deploy/mobile_builds/` and intentionally ignored by Git.

The current Astrology API subscription is expired. The Flutter transport and
Laravel routes are reachable, but Kundali, horoscope, Panchang, reports, and
calculator provider data will remain unavailable or empty until that backend
subscription is renewed.

## Integration Safety

- The original repository at `D:\astrozura_application-1` was not deleted.
- Its dirty pre-merge state was archived under `deploy/mobile_premerge_*`.
- The monorepo copy excludes `.git`, build caches, signing files, keystores,
  device dumps, and local SDK paths.
- Never add backend secrets or Android signing credentials to this folder.
