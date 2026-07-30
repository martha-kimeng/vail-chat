# Vail — Blind Chat & Blind Dates

> _Meet without the mask. Talk. Feel the spark. Then meet for real._

Vail is a mobile app for iOS and Android where people connect anonymously through conversation — no photos, no real names, just words. When both users feel a genuine connection, they signal chemistry mutually. If it's reciprocated, they can plan a blind date, still through the app, before ever seeing each other.

---

## Table of Contents

- [Concept](#concept)
- [Features](#features)
- [Screen Flow](#screen-flow)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Running the App](#running-the-app)
  - [Building for Release](#building-for-release)
- [Design System](#design-system)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Concept

Most dating apps lead with appearance. Vail flips that entirely.

Every user gets an anonymous nickname. There are no profile photos in the chat. Conversation is the only thing on the table. When both people independently signal that they feel chemistry, the app confirms the mutual match and unlocks the next step: planning a blind date — a real-world meeting where they see each other for the first time.

The identity reveal is tied to the date itself, not a swipe.

---

## Features

- **Anonymous profiles** — users sign up with a nickname only, no real name required
- **Blind chat** — text conversations with no photo or identity visible
- **Chemistry signal** — either user can privately tap "Spark"; the other is never told unless they signal it too
- **Mutual match confirmation** — when both signal, the app reveals a first name and unlocks date planning
- **Blind date wizard** — 3-step in-app flow to propose a date type, day, and time
- **Chemistry tab** — dedicated view listing all mutual sparks with quick actions to chat or plan a date
- **Portrait-locked, mobile-first** — designed exclusively for iOS and Android

---

## Screen Flow

```
Onboarding (3 slides)
    │
    ├── Sign Up  ──┐
    └── Sign In  ──┴──► Home
                            │
                            ├── Chats tab
                            │       └── Chat screen
                            │               └── [Spark button] → Chemistry sheet
                            │                                         └── Profile Reveal
                            │                                                   └── Blind Date wizard
                            │
                            └── Chemistry tab
                                    └── [Plan Date] → Blind Date wizard
```

### Screens at a glance

| Screen           | Description                                                             |
| ---------------- | ----------------------------------------------------------------------- |
| Onboarding       | 3 animated slides introducing the concept, with per-slide colour shifts |
| Sign Up          | Nickname + email + password — anonymous by design                       |
| Sign In          | Email + password with forgot-password link                              |
| Home — Chats     | Conversation list with unread badges and "Spark" indicators             |
| Home — Chemistry | Mutual spark cards with Chat and Plan Date CTAs                         |
| Chat             | Bubble-style conversation, chemistry signal button in the app bar       |
| Profile Reveal   | 3-state animated flow: waiting → mutual confirmed → first-name reveal   |
| Blind Date       | Step-by-step wizard: date type → day & time → review → send proposal    |

---

## Tech Stack

| Layer                | Choice                                                                           |
| -------------------- | -------------------------------------------------------------------------------- |
| Framework            | [Flutter](https://flutter.dev) 3.44+                                             |
| Language             | Dart 3.12+                                                                       |
| Navigation           | [go_router](https://pub.dev/packages/go_router) 14.x                             |
| Animations           | [flutter_animate](https://pub.dev/packages/flutter_animate) 4.x                  |
| Typography           | [google_fonts](https://pub.dev/packages/google_fonts) — Playfair Display + Inter |
| Internationalisation | [intl](https://pub.dev/packages/intl) 0.19                                       |
| Platforms            | iOS, Android                                                                     |

---

## Project Structure

```
lib/
├── main.dart                          # App entry point, orientation lock
├── core/
│   ├── theme.dart                     # Palette, text styles, shared widgets
│   └── widgets/
│       └── vail_field.dart            # Reusable labelled form field
├── router/
│   └── app_router.dart                # GoRouter route definitions
└── features/
    ├── onboarding/
    │   └── onboarding_screen.dart     # 3-slide intro PageView
    ├── auth/
    │   ├── sign_up_screen.dart
    │   └── sign_in_screen.dart
    ├── home/
    │   └── home_screen.dart           # Chat list + Chemistry tabs
    ├── chat/
    │   └── chat_screen.dart           # Conversation + Spark signal
    ├── profile/
    │   └── profile_reveal_screen.dart # Waiting → mutual → reveal flow
    └── date/
        └── blind_date_screen.dart     # 3-step blind date wizard
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **3.44 or later**
- Dart **3.12 or later** (bundled with Flutter)
- Xcode 15+ (for iOS builds)
- Android Studio / Android SDK (for Android builds)
- A connected simulator, emulator, or physical device

Verify your Flutter setup:

```bash
flutter doctor
```

### Installation

Clone the repository and fetch dependencies:

```bash
git clone https://github.com/your-org/vail-chat.git
cd vail-chat
flutter pub get
```

### Running the App

```bash
# Run on a connected device or simulator
flutter run

# Run specifically on iOS simulator
flutter run -d iPhone

# Run specifically on Android emulator
flutter run -d emulator
```

The app starts at the onboarding screen. You can navigate through the full flow without a backend — all data is mocked for this initial version.

### Building for Release

**iOS**

```bash
flutter build ios --release
```

Open `ios/Runner.xcworkspace` in Xcode to configure signing and archive.

**Android**

```bash
flutter build apk --release
# or for an app bundle
flutter build appbundle --release
```

---

## Design System

Vail uses a consistent design language across all screens.

**Palette**

| Token          | Value                         | Usage                             |
| -------------- | ----------------------------- | --------------------------------- |
| `rose`         | `#E8516A`                     | Primary brand, CTAs, bubble fill  |
| `roseDark`     | `#C43150`                     | Hover / pressed states            |
| `roseSoft`     | `#FDE8EC`                     | Chip backgrounds, soft highlights |
| `ink`          | `#1A1A2E`                     | Primary text, icons               |
| `inkLight`     | `#3D3D5C`                     | Secondary text, labels            |
| `mist`         | `#F4F4F8`                     | App background                    |
| `heroGradient` | `#1A1A2E → #2D1B3D → #4A1942` | Branded dark screens              |

**Typography**

- **Playfair Display** — display and heading sizes (bold, editorial feel)
- **Inter** — body, labels, UI copy (clean, readable)

**Components**

- `VailGradientBackground` — full-screen dark gradient wrapper
- `VailButton` — primary and outlined CTA button
- `VailField` — labelled text field with icon prefix, used in auth forms

---

## Roadmap

The current codebase is a fully navigable UI shell with mock data. The following are planned for subsequent iterations:

- [ ] Backend integration (authentication, real-time messaging)
- [ ] Push notifications for new messages and chemistry matches
- [ ] In-app date acceptance / counter-proposal flow
- [ ] Location-based venue suggestions for the blind date
- [ ] Report & block functionality
- [ ] Accessibility audit and screen-reader support
- [ ] Localisation (i18n)
- [ ] Dark mode

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "feat: describe your change"`
4. Push to your branch: `git push origin feature/your-feature`
5. Open a pull request

Please follow the existing code style. Run `flutter analyze` before submitting — the project expects zero issues.

---

## License

This project is private and not yet licensed for public distribution. All rights reserved.
