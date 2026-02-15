# OTW - On The Way

Roadside assistance app for iOS and Android built with **Flutter**, **Firebase**, and **Radar.com**.

## Architecture

- **Flutter** – Cross-platform Customer & Hero apps
- **Firebase Auth** – Phone, email, Google/Apple Sign-In
- **Cloud Firestore** – Users, heroes, jobs, messages
- **Firebase Realtime Database** – Hero locations, presence, typing indicators
- **Cloud Functions** – Dispatch, webhooks, notifications
- **Radar.com** – GPS tracking, geofencing, routing
- **Riverpod** – State management
- **go_router** – Navigation

## Prerequisites

- Flutter SDK (3.0+)
- Node.js 18+ (for Cloud Functions)
- Firebase CLI (`npm install -g firebase-tools`)
- Firebase project: [on-the-way-rebuild](https://console.firebase.google.com/u/0/project/on-the-way-rebuild/overview)
- Radar.com project and publishable key

## Project setup

### 1. Flutter project (if not already created)

From the project root:

```bash
flutter create . --project-name otw_app --org com.otw
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Firebase

- Create/use project **on-the-way-rebuild** in Firebase Console.
- Enable: Authentication, Firestore, Realtime Database, Cloud Messaging.
- Add Android app (package e.g. `com.otw.otw_app`) and iOS app (bundle id).
- Download and add:
  - `google-services.json` → `android/app/`
  - `GoogleService-Info.plist` → `ios/Runner/`
- Add Firebase init (e.g. default Firebase options) in `lib/config/firebase_config.dart` if using a non-default project.

### 4. Radar.com

- Create a project at [Radar](https://radar.com).
- Copy your **publishable key** into `lib/config/radar_config.dart` (replace `prj_live_pk_xxxxxxxxxxxxx`).
- Configure webhooks to your Cloud Functions URLs when deployed.

### 5. Google Maps (for map tiles)

- Enable Maps SDK for Android and iOS in Google Cloud Console.
- Add API key in:
  - Android: `android/app/src/main/AndroidManifest.xml` (see architecture guide).
  - iOS: `ios/Runner/AppDelegate.swift` / Xcode.

### 6. Assets

Ensure these exist (can be empty at first):

- `assets/images/`
- `assets/icons/`

## Run the app

```bash
flutter run
```

## Deploy Cloud Functions

```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

## Project structure (high level)

```
lib/
├── main.dart
├── app.dart
├── config/          # Firebase, Radar, theme, constants
├── models/          # User, Hero, Job, Location, Message, Route, ServiceType
├── services/        # Auth, Firestore, Realtime DB, Radar, Location, Notifications, Routing, Payment
├── providers/       # Auth, Hero, Job, Tracking, Navigation (Riverpod)
├── screens/         # Auth, Customer (home, tracking, chat), Hero (home, navigation)
├── widgets/         # Common, map, job, navigation
└── utils/           # Polyline decoder, location interpolation
functions/           # Cloud Functions (dispatch, webhooks, notifications)
firestore.rules
database.rules.json
firebase.json
```

## Implementation checklist

- [x] Flutter project structure and config
- [x] Models and services (Firebase, Radar, location, notifications)
- [x] Providers (auth, job, hero, tracking, navigation)
- [x] Auth screens (login, signup)
- [x] Customer screens (home, tracking, chat)
- [x] Hero screens (home, navigation)
- [ ] Firebase project wiring (google-services.json, GoogleService-Info.plist)
- [ ] Radar publishable key and webhooks
- [ ] Cloud Functions: dispatch, Radar webhooks, push notifications
- [ ] Service request flow: location picker, price confirmation, create job
- [ ] Hero: available jobs list, accept job, full navigation flow
- [ ] Stripe/payments (optional)
- [ ] Tests and polish

## Links

- [Firebase Console – on-the-way-rebuild](https://console.firebase.google.com/u/0/project/on-the-way-rebuild/overview)
- [GitHub – On-The-Way-Rebuild](https://github.com/mozocode/On-The-Way-Rebuild)
