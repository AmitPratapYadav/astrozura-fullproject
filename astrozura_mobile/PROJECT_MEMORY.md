# Astrozura Mobile Project Memory

Last verified: 2026-07-03 (Asia/Calcutta)

This document is the handoff source for continuing Astrozura mobile work in a
new chat or moving the mobile project into the Astrozura full-project
repository. It describes the code that exists in the local working trees, not
only previously discussed plans.

## 1. Critical State Warning

The current mobile integration is not committed.

- Mobile repository: `D:\astrozura_application-1`
- Remote: `https://github.com/AmitPratapYadav/astrozura_application.git`
- Branch: `main`
- HEAD: `e6b3089` (`Merge Sahil integration into main`)
- Remote branch state: `main` matches `origin/main`
- Working tree: approximately 84 tracked changes, 24 tracked deletions, and 66
  untracked files
- Diff size: approximately 6,306 insertions and 41,255 deletions

The large deletions remove legacy hardcoded calculator/report screens and
replace them with shared live screens. They must not be restored without
checking reachability and the new service catalog.

Do not run `git reset --hard`, `git clean`, `git checkout -- .`, or overwrite
this folder from `origin/main`. Commit or archive this working tree before any
merge, pull, branch switch, or repository move.

The full-project repository is also heavily modified and uncommitted:

- Full project: `D:\astrozura-fullproject`
- Remote: `https://github.com/mayurnathoasto/astrozura-fullproject.git`
- Branch: `main`
- HEAD: `ce9440a`
- Modules:
  - Main website: `Astrozura-main`
  - Laravel API: `login_api`
  - Admin panel: `astro-admin-panel-main`
  - Shop website: `ecomm_astrozura`

Never reset that monorepo while integrating the mobile folder.

## 2. Product And Architecture

Astrozura mobile is a Flutter customer application sharing the Laravel backend,
database, authentication, media storage, astrology provider, bookings, Zego
sessions, rituals, blogs, and e-commerce data with the websites.

Primary application areas:

- OTP, password, registration, and Google authentication
- Home discovery and live content
- Astrologer chat/call discovery and booking
- Zego booking sessions and booking messages
- Pooja Anusthan listing, details, booking, and Razorpay payment
- Product catalog, cart, checkout, orders, wishlist, Razorpay, and COD
- Profile, birth details, profile image, bookings, ritual bookings, and orders
- Daily/weekly/monthly horoscope
- Daily Panchang, Chaughadiya, and Hora
- Kundali, matchmaking, reports, numerology, Tarot, and Vedic calculators
- Live blogs opened on the main website

The app is customer-facing. Dormant admin/astrologer-side Flutter code is not
the current cleanup scope.

## 3. Toolchain And Dependencies

Last verified local toolchain:

- Flutter `3.38.5` stable
- Dart `3.10.4`
- Java `21.0.9`
- Dart SDK constraint: `>=3.5.0 <4.0.0`
- App version: `1.0.0+1`

Important Flutter packages:

- `provider`
- `http`
- `shared_preferences`
- `google_sign_in`
- `image_picker`
- `razorpay_flutter`
- `zego_uikit_prebuilt_call`
- `zego_express_engine`
- `zego_plugin_adapter`
- `zego_zim`
- `flutter_svg`
- `url_launcher`

Do not bulk-upgrade Zego or other plugins while completing a release. There
are many newer incompatible package versions and upgrades need isolated
device testing.

## 4. API Configuration

API configuration is in:

- `lib/core/contants/api_constants.dart`
- `lib/core/services/api_client.dart`

`ApiClient` provides:

- JSON requests and response decoding
- optional Sanctum bearer token injection
- 20-second timeout
- one retry for connection errors, timeouts, and HTTP 5xx
- validation/error message extraction
- explicit 401 errors

The production source default was corrected on 2026-07-03 and is now:

```text
https://astrozura.com/apigateway/index.php/api
```

The previous `https://astrozura.com/api` default returned HTTP 404 and caused
the installed app to lose astrologers, profile data, shop data, reports, and
calculator transport. The corrected gateway returned HTTP 200 for
astrologers, rituals, products, blogs, and location search.

Build-time override remains supported:

```powershell
--dart-define=ASTROZURA_API_BASE_URL=https://astrozura.com/apigateway/index.php/api
```

The old `https://api.astrozura.com/api` host did not resolve in the
2026-07-03 check.

Local-device development can override the base URL:

```powershell
flutter run -d <device-id> --dart-define=ASTROZURA_API_BASE_URL=http://<LAN-IP>:8000/api
```

The previously used LAN address was `192.168.1.3`, but it must be rechecked on
the current network.

## 5. Backend And External Providers

Laravel routes are defined in:

```text
D:\astrozura-fullproject\login_api\routes\api.php
```

Important contract groups:

- Auth: `/send-otp`, `/login`, `/login-password`, `/register`,
  `/auth/google/mobile`, `/logout`
- Profile: `/dashboard/profile`, `/dashboard/profile/update`
- Astrologers: `/astrologers`, `/astrologer/{id}`
- Consultation bookings: `/bookings`, `/bookings/availability`,
  `/my-bookings`
- Session: `/bookings/{id}/session`, `/start`, `/end`, `/ping`, `/extend`
- Messages: `/bookings/{id}/messages`
- Rituals: `/rituals`, `/rituals/{slug}`, `/rituals/{id}/book`,
  `/my-ritual-bookings`
- Shop: `/ecomm/categories`, `/ecomm/products`,
  `/ecomm/products/trending`
- Orders/wishlist: `/dashboard/orders`, `/dashboard/orders/store`,
  `/dashboard/wishlist`
- Payments: `/payments/razorpay/config`, `/order`, `/verify`
- Blogs: `/blogs`, `/blogs/{slug}`

Despite the retained `/prokerala/*` route names, the backend service is
Astrology API, not Prokerala. The source of truth is:

```text
login_api/app/Services/AstrologyApiService.php
login_api/app/Http/Controllers/Api/AstrologyController.php
```

Do not rename or replace the mobile calls with Prokerala assumptions. The old
route names are compatibility names only.

Astrology API currently returns a provider error stating that the subscribed
API key is expired. The Laravel transport returns that provider condition
inside a JSON error response. Successful Panchang, horoscope, reports, and
calculator results require the provider subscription/key to be renewed.

Location search is proxied through:

```text
GET /prokerala/location/search?q=<query>
```

It currently returns live place names and latitude/longitude data. Flutter
uses the shared `LocationSearchField` and stores selected coordinates.

Backend environment contains configuration for:

- Astrology API
- Google Maps
- Google web/mobile OAuth audiences
- Razorpay
- Zego chat/call/live services
- DigitalOcean Spaces through the AWS-compatible filesystem variables

Secrets must stay in backend `.env`, ignored local signing files, the VPS, or
secure CI variables. Never copy backend secrets into Flutter assets or this
document.

## 6. Authentication And Session State

Primary implementation:

```text
lib/core/services/auth_services.dart
lib/features/auth/login_screen.dart
lib/features/auth/otp_verification_screen.dart
```

Current behavior:

- Sanctum token key: `auth_token`
- OTP uses `/send-otp` and `/login`
- `dev_otp` can be displayed by the debug login flow when returned
- Password login uses `/login-password`
- Registration uses `/register`
- Google sends an ID token to `/auth/google/mobile`
- Login flows refresh `ProfileProvider`
- Logout clears local state first and can revoke the server token separately

Google Sign-In currently initializes with the backend web OAuth client as
`serverClientId`. The value can be overridden with:

```powershell
--dart-define=GOOGLE_WEB_CLIENT_ID=<web-client-id>
```

The backend accepts the configured web, Android, and mobile audiences. Google
Console must contain Android OAuth clients for package `com.astrozura.app`
with the debug and release SHA-1 fingerprints listed below.

The app retries Google authentication once after signing out for retryable
stale-session errors and reports cancellation/configuration errors
separately.

Known cleanup:

- `AuthService` still uses direct `http` calls rather than `ApiClient`.
- OTP code still contains production `print` statements.
- Centralize auth requests and remove debug prints before a store release.

## 7. Profile And Media

Shared profile state:

```text
lib/core/providers/profile_provider.dart
```

It refreshes `/dashboard/profile`, caches profile fields, and propagates name,
avatar, phone, birth details, and coordinates to consumers.

Profile images are uploaded as multipart `profile_image` through:

```text
POST /dashboard/profile/update
```

The backend is responsible for storing media in DigitalOcean Spaces. Flutter
never receives storage credentials.

Media URL normalization is centralized in `ApiConstants.storageUrl()`:

- absolute HTTPS and DigitalOcean URLs are preserved
- `/uploads/*` resolves against `https://astrozura.com`, not the API gateway
- `/storage/*` resolves against `https://astrozura.com`, not the API gateway
- other relative paths currently resolve under `/storage`

The avatar is used by the home header, profile, edit profile, and drawer.
Birth-detail completion requires DOB, birth time, place, latitude, and
longitude.

## 8. Navigation And Homepage

Main navigation is an `IndexedStack` in:

```text
lib/features/main_navigation.dart
```

Visible tabs:

- `0`: Home
- `1`: Chat
- `2`: center Services sheet
- `3`: Shop
- `4`: Profile

Hidden/direct indices include orders, bookings, rituals, Panchang modes,
horoscope, reports, and calculator screens. The integer index catalog is
functional but brittle; keep `pages_data.dart` and `MainNavigation.screens`
aligned whenever adding or removing a destination.

Current homepage order:

1. Header and greeting/search
2. Live astrologer carousel
3. Explore Astrozura
4. Live Pooja Anusthan
5. Zodiac horoscope carousel
6. Reports
7. Shop/Pooja/Horoscope banner carousel
8. Calculators
9. Products
10. Panchang
11. Blogs
12. Footer

Implemented homepage behavior:

- Astrologers load from `/astrologers`
- compact cards show avatar, name, featured state, experience, rating, and
  `Book Session`
- Explore uses supplied service artwork
- supplied zodiac assets use exact case-sensitive paths
- banners auto-advance every three seconds and are fully tappable
- products and Pooja use live APIs with constrained titles
- blogs load from `/blogs?per_page=4` and open website routes externally
- notification bell opens an animated local empty-state panel
- Panchang uses saved birthplace coordinates and live API data
- footer uses supplied artwork and Astrozura branding

The banner widget currently uses aspect ratio `2.15`; the supplied artwork is
`450x200` (`2.25`). Correct this if visual cropping is observed.

The notification panel intentionally says `No new notifications yet`; it is
not connected to the newer backend notification routes.

## 9. Service Catalog, Horoscope, Reports, And Calculators

Service metadata:

```text
lib/core/models/other_pages/pages_data.dart
lib/core/models/app_content_catalog.dart
```

Assets:

```text
assets/images/services/
assets/images/reports/
assets/images/calculators/
assets/images/zodiac/
assets/images/banners/
```

Shared live screens:

```text
lib/features/other_pages/horoscope/live_horoscope_screen.dart
lib/features/other_pages/panchang/live_panchang_screen.dart
lib/features/other_pages/calculators/live_vedic_calculator_screen.dart
lib/features/other_pages/calculators/live_numerology_screen.dart
lib/features/other_pages/calculators/live_tarot_screen.dart
lib/features/other_pages/live_matchmaking_report_screen.dart
lib/features/shared/widgets/astrology_result_renderer.dart
lib/features/shared/widgets/location_search_field.dart
```

Panchang is one shared implementation with three modes:

- Daily Panchang
- Chaughadiya
- Hora

The legacy wrapper files now route into this shared screen.

Live Vedic calculator keys currently include:

- daily Nakshatra predictions
- Mangal Dosha
- Kaal Sarp Dosha
- Sade-Sati
- Pitra Dosha
- Puja suggestion
- Gemstone suggestion
- Rudraksha suggestion
- Vimshottari Dasha
- Char Dasha
- Yogini Dasha
- Varshaphal
- Krishnamurti Paddhati
- Ashtakavarga/Sarvashtakavarga
- Kundali

Numerology, Tarot, Lal Kitab, matchmaking, and detailed report compositions
have dedicated live screens.

Known catalog issue:

- `Palm Reading` currently points to Chat index `1`; no live backend palm
  reading contract is wired. It should be removed, marked unavailable, or
  connected to a real endpoint rather than silently opening Chat.

No fake calculator or report results should be reintroduced. Provider errors
must remain visible.

## 10. Astrologer Booking, Zego, And Messages

Key files:

```text
lib/core/services/astrologer_service.dart
lib/core/services/booking_service.dart
lib/features/astrologer/
lib/features/booking/booking_session_screen.dart
```

Current consultation flow:

1. Load live astrologer/profile/availability data
2. Select chat or call, plan, date, and time
3. Create a pending booking
4. Create Razorpay order with purpose `consultation`
5. Open Razorpay
6. Verify signature/payment
7. Show confirmation only after successful verification

Booking session data comes from `/bookings/{id}/session`. The Flutter parser
must continue accepting numeric values as `num` and converting with
`toInt()`/`toDouble()` because PHP JSON may encode numeric values differently.

Zego call UI is created only when the backend session response provides valid
app ID, token, room ID, and viewer identity. Chat history uses backend booking
messages. Zego credentials remain server-side.

Zego has not been revalidated on a connected device in this 2026-07-03 audit.

## 11. Rituals And Ritual Booking History

Key files:

```text
lib/features/pujaanusthan/
lib/core/models/ritual_booking_model.dart
lib/core/services/ritual_booking_service.dart
```

Current behavior:

- listing loads `/rituals`
- detail loads `/rituals/{slug}`
- related rituals use live response records and media
- cards use stable regions and one-line ellipsized titles
- detail uses native future-date and time selection
- devotee/profile details can be prefilled
- booking posts to `/rituals/{id}/book`
- payment uses Razorpay purpose `ritual`
- My Bookings separately loads `/my-ritual-bookings`
- upcoming and history sections show honest empty/error states

Static Pooja inclusions and process/timeline panels were removed.

## 12. Shop, Orders, Wishlist, And Payments

Key files:

```text
lib/core/services/shop_service.dart
lib/core/services/order_service.dart
lib/core/services/razorpay_service.dart
lib/features/shop/
lib/features/profile/my_orders_page.dart
```

Current product checkout exposes only:

- Razorpay
- Cash on Delivery

Ritual and consultation checkout expose Razorpay only. Razorpay methods such
as UPI, cards, wallets, and net banking are displayed by Razorpay itself, not
as mock app payment methods.

Razorpay purpose values are:

- `product`
- `ritual`
- `consultation`

Product images use live media URLs. Missing media should remain a branded
empty state, not a fake product image.

## 13. Android Configuration And Signing

Android:

- Package/application ID: `com.astrozura.app`
- Namespace: `com.astrozura.app`
- Compile SDK: `36`
- Target SDK: `36`
- NDK: `27.0.12077973`
- Java/Kotlin target: `17`
- App label: `Astrozura`
- Internet, camera, microphone, audio, and Bluetooth permissions are present
- Cleartext traffic is currently enabled for local HTTP development

Release signing uses ignored local files:

```text
android/key.properties
<ignored release keystore>
```

Never commit or share those files.

Android OAuth fingerprints:

```text
Debug SHA-1:
C5:5A:20:C9:88:16:1A:D8:3E:C2:CF:F0:38:AD:7D:51:AD:F0:37:14

Debug SHA-256:
10:5B:A2:18:13:28:16:37:45:0C:10:AB:AF:05:0E:5E:70:25:CF:B3:8D:91:55:8D:DC:79:08:CA:25:48:91:40

Release SHA-1:
B5:02:35:02:29:5F:64:A1:71:41:90:6D:B5:10:4E:2C:43:1C:8B:AE

Release SHA-256:
5A:3D:8F:AF:53:E1:FC:E7:9F:F8:23:0D:15:B4:8A:2C:CE:9E:A0:57:F7:91:F6:FE:16:60:3C:E6:5A:46:BD:ED
```

Existing build artifacts:

```text
build/app/outputs/flutter-apk/Astrozura-client-arm64-release.apk
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

The 2026-07-03 gateway-fix arm64 artifact is 81,731,716 bytes (approximately
77.9 MiB) and below the 150 MB target.
The old universal APK is approximately 215 MB and should not be distributed.
The debug APK is approximately 343 MB; that size is expected to be much larger
because of debug symbols and all plugin architectures.

The production APK was rebuilt after correcting the live API base.

Recommended build:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release --split-per-abi `
  --dart-define=ASTROZURA_API_BASE_URL=https://astrozura.com/apigateway/index.php/api
```

Distribute only `app-arm64-v8a-release.apk` for the Redmi/client device.

## 14. Current Verification Results

Executed on 2026-07-03:

- `flutter test`: passed, 5 tests
- `flutter analyze`: no compile errors, but 170 warnings/info; exits non-zero
- `flutter build apk --release --split-per-abi`: passed
- ARM64 release: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `flutter devices`: only Chrome and Edge detected
- Redmi device `db620936`: not connected during this audit
- Release keystore fingerprints: reverified with `keytool`
- Production gateway public endpoints: HTTP 200
- Direct `https://astrozura.com/api/*`: HTTP 404
- Astrology transport: HTTP 200 containing expired-subscription provider error

Current tests cover:

- unique/stable customer service catalog destinations
- Chat label/icon instead of Experts
- media URL behavior
- banner/zodiac asset existence and exact casing
- notification panel opening and closing

Testing is still shallow. There are no comprehensive API, payment, booking,
profile upload, or calculator widget/integration tests.

High-value analyzer cleanup:

- direct `print` calls in auth
- unused fields/methods left after filter/static-screen removal
- async `BuildContext` usage
- deprecated `WillPopScope`
- deprecated `withOpacity`
- dead null-aware expressions

## 15. iOS Status

The repository contains Flutter's generated `ios/` shell, but Astrozura iOS is
not release-ready.

Not yet configured/validated:

- Apple Developer team and signing
- final iOS bundle ID in Xcode
- supported deployment target after CocoaPods resolution
- Google iOS OAuth client and URL scheme
- `GoogleService-Info.plist` or equivalent explicit configuration
- Sign in with Apple and backend Apple-token verification
- camera/microphone/photo permission descriptions
- Zego call behavior and iOS audio session
- Razorpay callback flow on iOS
- production icons/launch screen review
- in-app account deletion required by App Store rules
- App Store privacy declarations and third-party SDK disclosures
- TestFlight/App Store archive

The intended iOS bundle ID is:

```text
com.astrozura.app
```

Windows cannot build or sign iOS. The agreed practical route is a dedicated
Apple Silicon cloud Mac with:

- full administrator access
- SSH
- static IP/hostname
- persistent storage
- current macOS and Xcode
- remote desktop

Hyperbox Mac Mini Agent Workstation was being evaluated because it advertises
Codex, Xcode, SSH, static IP, and remote desktop. Before purchase, verify that
the offered plan is dedicated, has at least 16 GB RAM and 256 GB storage, and
supports the current App Store-required Xcode/iOS SDK.

The available iPhone 14 will test TestFlight builds. It normally will not be
USB-connected to the remote Mac.

## 16. Backend Deployment Context

Production is hosted through CyberPanel/OpenLiteSpeed. Access credentials were
provided previously but are intentionally not recorded here. Obtain them from
the project owner or secure password manager.

The live frontend uses the `/apigateway/index.php/api` gateway. Any backend
deployment must preserve that gateway and the existing website OAuth setup.

Local deployment staging/snapshots exist under:

```text
D:\astrozura-fullproject\deploy\
```

Recent local deployment folders include July 3 release and admin profile
snapshots. These are not proof that every dirty backend file is deployed.
Before deploying:

1. Compare the exact local file with the live version.
2. Back up each changed live file.
3. Deploy only scoped files.
4. Run Laravel configuration/route/cache clearing as appropriate.
5. Smoke-test the gateway routes.
6. Do not upload local `.env`.

No new deployment should be inferred only from an old conversation message.

## 17. Highest-Priority Next Work

Do these in order:

1. Preserve the mobile working tree in a dedicated commit/branch.
2. Install the fresh gateway-fix ARM64 APK on the Redmi.
3. Connect the Redmi and smoke-test login, home, profile, shop, rituals,
   bookings, and API error states.
4. Renew/fix the Astrology API subscription before expecting successful
   horoscope, Panchang, report, or calculator results.
5. Re-test Google login with both debug and release signatures.
6. Re-test consultation, ritual, and product Razorpay verification end to end.
7. Re-test Zego session payload parsing and a real booked call.
8. Resolve the Palm Reading placeholder destination.
9. Decide whether notifications remain a local empty state or consume the
    backend `/notifications` routes.
10. Reduce analyzer warnings, starting with auth logging and async context.
11. Begin iOS platform configuration only after a cloud Mac and Apple
    Developer organization account are available.

## 18. Safe Merge Into The Full Project

Recommended destination:

```text
D:\astrozura-fullproject\astrozura_mobile
```

The source was copied to this destination on 2026-07-03 without deleting or
modifying the original repository history. Generated build caches, `.git`,
local signing files, keystores, screenshots, XML device dumps, and old archive
files were excluded from the monorepo copy.

Do not merge unrelated Git histories by copying over the monorepo root. Use
one of these controlled approaches:

### Option A: Keep Separate Repositories

Preferred while mobile work is active. Add a root-level document in the full
project that links to the mobile repository. This avoids mixing independent
release histories.

### Option B: Add Mobile As A Monorepo Folder

1. Commit the current mobile integration in its existing repository.
2. Back up both dirty worktrees.
3. Create `astrozura_mobile/` in a clean integration branch of the full
   project.
4. Copy tracked mobile sources and assets, excluding:
   - `.git/`
   - `build/`
   - `.dart_tool/`
   - local IDE files
   - `android/key.properties`
   - keystores
   - generated platform caches
5. Add and commit the mobile subtree separately.
6. Verify Flutter commands from `astrozura_mobile/`.
7. Never commit backend `.env`, signing files, or cloud credentials.

If preserving mobile Git history is required, use `git subtree` after the
mobile changes are committed. Do not attempt subtree import from the current
dirty state.

## 19. New Chat Continuation Prompt

Use this prompt in a new development chat:

```text
Continue Astrozura mobile development from PROJECT_MEMORY.md in
D:\astrozura-fullproject\astrozura_mobile. Read the memory and inspect git
status before editing. Preserve all current uncommitted work and intentional
legacy deletions. The live Laravel API base and source default are
https://astrozura.com/apigateway/index.php/api. The backend is Astrology API
despite legacy /prokerala route names, and the provider subscription is
currently expired. Run tests and do not expose or commit credentials.
```

## 20. Security Rules

- Never paste VPS, CyberPanel, Apple, Google, Razorpay, Zego, DigitalOcean, or
  keystore passwords into source control.
- Never copy backend service secrets into Flutter.
- Apple and Google client IDs are identifiers; private client secrets and
  signing keys are not.
- Use App Store Connect invitations/API keys rather than sharing an Apple
  Account password.
- Use SSH keys and a dedicated cloud-Mac user.
- Keep release keystore backups outside the repository. Losing the keystore
  can prevent future Android updates under the same signing identity.
