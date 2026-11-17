# SpeedZone LV

Native iPhone companion for Latvian average-speed control sections. It is a
private, local-only app: no account, no server, no analytics, no App Store
publication.

> **Status:** The live GPS stack, automatic zone detection, background
> tracking, notifications, Live Activities/Dynamic Island, manual zone
> management, full-section speed curves and selectable design themes are
> implemented in source. The project has **not** been compiled or tested on a
> physical iPhone yet. See `TODO.md`.
>
> **Honesty notes**
> - No real camera coordinates have been invented. `zones_lv.json` stays
>   empty until each zone is verified against a public source. Official LVC
>   kilometre ranges are provided only as editable templates.
> - GPS results are estimates and are never presented as an official
>   enforcement measurement.
> - The iOS app cannot be compiled natively on Windows. See
>   [Building without a Mac](#building-without-a-mac).

---

## What is implemented

- Complete Xcode project (`SpeedZoneLV.xcodeproj`) for iOS 17+ with an app
  target and a Widget Extension target (`SpeedZoneLVWidgets`).
- Dark, premium SwiftUI dashboard in Latvian:
  - live current speed from CoreLocation,
  - average speed in the zone,
  - official speed limit and a separate personal target,
  - predicted finish average,
  - recommended remaining average,
  - starting speed, elapsed time, remaining distance/time,
  - full-section speed curve (Swift Charts),
  - progress bar and all ride metrics.
- Real GPS tracking: authorization handling, accuracy/timestamp/jump filtering,
  background updates, automatic approach/entry/exit detection, and recovery
  when the app opens mid-section.
- A clearly labelled **1 km GPS test corridor** generated from the current
  position and heading.
- An interactive **demo drive** (1.2 km, 90 km/h limit) that exercises the
  entire live dashboard and completion summary.
- Local notifications for approach, entry, exceeded target and finish, plus
  optional haptics and sound.
- Live Activity with Lock Screen panel and Dynamic Island compact/expanded
  layouts, including target speed and approach distance.
- Manual zone editor: coordinates, direction, length, limit, verification,
  source metadata, GPS capture, coordinate swap and validation.
- Official LVC kilometre-range templates (no invented coordinates) and JSON
  import for user zones.
- Personal target offset (0–20 km/h) above the official limit; the official
  limit is always retained and displayed separately.
- Six theme presets plus individual accent, background, card style, density
  and corner controls, and per-element visibility switches.
- Local trip history persisted as JSON, including demo measurements marked
  `DEMO`, with a detail screen and speed curve.
- Privacy: no account, no server, no analytics, no upload.
- GitHub Actions workflow that builds an **unsigned IPA** on a free macOS
  runner.

Screenshots/reference images were not present in the request; the interface
follows the requested premium automotive-dashboard direction.

---

## Project layout

```
SpeedZoneLV/
├── Config/
│   ├── Info.plist                     # location strings, background mode, Live Activities
│   └── WidgetInfo.plist               # widget extension Info.plist
├── Shared/
│   └── SpeedZoneActivityAttributes.swift
├── Widgets/
│   ├── SpeedZoneLVWidgetBundle.swift
│   └── SpeedZoneLiveActivityWidget.swift
├── SpeedZoneLV/
│   ├── App/
│   ├── DesignSystem/
│   ├── Models/
│   ├── Services/
│   │   ├── Database/
│   │   ├── Demo/
│   │   ├── Detection/
│   │   ├── History/
│   │   ├── LiveActivity/
│   │   ├── Location/
│   │   ├── Notifications/
│   │   └── Speed/
│   ├── ViewModels/
│   ├── Views/
│   └── Resources/
├── SpeedZoneLV.xcodeproj
├── project.yml                        # optional XcodeGen definition
├── .github/workflows/build.yml         # free macOS build → unsigned IPA
├── README.md
└── TODO.md
```

The Xcode project uses Xcode 16+ **file-system synchronized groups**. Files
inside `SpeedZoneLV/SpeedZoneLV/` belong to the app target; `Shared/` is
compiled into both the app and the widget extension; `Widgets/` belongs only to
the widget extension. No manual “Add Files” step is needed for new files.

---

## Requirements

- iPhone 14 Pro or newer (Dynamic Island targets; iOS 17+).
- Xcode 16 or newer on macOS for interactive development.
- Free Apple ID for personal-device signing.
- No paid Apple Developer Program membership is required for personal use.

The current development machine is Windows 11, so this repository contains
source, project files and build automation — not a compiled `.ipa`.

---

## Building without a Mac

You do **not** have to buy a Mac, but a macOS machine is required somewhere:
Apple's iOS SDK and codesigning tools only run on macOS. Any claim that an
iOS app can be compiled natively on Windows is false.

### Option A — free GitHub Actions macOS runner (recommended, €0)

The included workflow `.github/workflows/build.yml`:

1. runs on a GitHub-hosted macOS runner,
2. builds `SpeedZoneLV` for `iphoneos` with code signing disabled,
3. packages an **unsigned** IPA artifact.

Steps:

1. Create a GitHub repository and push this folder (public repositories use
   the free macOS minutes allowance; private accounts have a small monthly
   macOS quota).
2. Open **Actions → Build unsigned IPA → Run workflow**.
3. Download the `SpeedZoneLV-unsigned-ipa` artifact.
4. Sign and install it with a free Apple ID as described below.

An unsigned IPA cannot be installed by itself. Signing happens on Windows.

### The app has two targets (app + widget extension)

The project builds **two** products:

| Product | Bundle ID | Purpose |
| --- | --- | --- |
| `SpeedZoneLV.app` | `com.vikto.speedzonelv` | the app |
| `SpeedZoneLVWidgets.appex` | `com.vikto.speedzonelv.widgets` | Live Activity / Dynamic Island UI |

Practical consequences:

- Sideloadly must sign **both** binaries. A free Apple ID can register a Widget
  extension App ID, but you have to create/allow **two App IDs** in the
  provisioning profile, and the widget's bundle ID must be prefixed by the app's
  bundle ID (`…speedzonelv.widgets`). Keep that relation if you rename anything.
- A free account allows only a small number of App IDs per week, so repeated
  bundle-ID changes can hit that limit.
- If signing the extension is refused, delete the `SpeedZoneLVWidgets` target
  from the embed phase or remove the extension, then rebuild: the app still
  works, but Lock Screen Live Activities and Dynamic Island will be missing.
- Live Activities also require **Settings → SpeedZone LV → Live Activities** to
  be enabled, and iOS may hide them while Low Power Mode is on.

### Option B — free Apple ID signing on Windows

Use **Sideloadly** (free) or **AltStore Classic** (free). Both use Apple's
free provisioning with your own Apple ID. This is legitimate personal
sideloading, not a pirated certificate service.

With Sideloadly:

1. Install Apple Devices (or iTunes) from the Microsoft Store.
2. Install Sideloadly from <https://sideloadly.io>.
3. Connect the iPhone, trust the computer, and open Sideloadly.
4. Drag `SpeedZoneLV-unsigned.ipa` into Sideloadly.
5. Enter your Apple ID. Use an **app-specific password** if two-factor
   authentication is enabled; never share your password with anyone.
6. Choose a unique bundle ID prefix if prompted and start.
7. On the iPhone: **Settings → General → VPN & Device Management → Trust**
   the developer certificate.
8. Enable Developer Mode if iOS asks for it
   (**Settings → Privacy & Security → Developer Mode**).

Free-provisioning facts you should plan for:

- The signing certificate expires after **7 days**. Re-sign weekly, or use
  AltStore's automatic refresh over Wi-Fi.
- A free account is limited to a small number of active apps and new App IDs
  per week.
- Free profiles cannot use server-based push notifications, iCloud,
  Associated Domains or other paid capabilities.
- Background location and local Live Activity updates are expected to work
  with a free profile, but they must be verified on the actual device.
- A paid Apple Developer account is **not** required for personal use. It only
  removes the 7-day refresh and unlocks server push and some capabilities.

### Option C — free macOS cloud minutes / borrowed Mac

- **Codemagic** has a free monthly macOS build allowance (no Mac needed).
- GitHub Actions is usually the simplest zero-cost option.
- A friend's Mac with Xcode 16+ also works; select your free Personal Team in
  **Signing & Capabilities** and run on the device.
- macOS virtual machines on non-Apple hardware violate Apple's license and are
  not recommended. Do not use cracked certificates or third-party "signing
  services".

### Opening on macOS

```bash
open SpeedZoneLV.xcodeproj
```

Then:

1. Select the `SpeedZoneLV` target.
2. **Signing & Capabilities → Team → your Personal Team**.
3. Change the bundle identifier if Xcode reports a conflict
   (`com.vikto.speedzonelv` is a placeholder).
4. Choose your iPhone and Run.

If the checked-in project file ever becomes inconvenient, regenerate it with
the declarative definition:

```bash
brew install xcodegen
cd SpeedZoneLV
xcodegen generate
open SpeedZoneLV.xcodeproj
```

The checked-in project uses the Xcode 16+ synchronized-folder format
(`objectVersion 77`). Xcode 15 cannot open it.

---

## Updating the zone database

The app loads `zones_lv.json` in this order:

1. `Documents/zones_lv.json` (user override)
2. bundled `zones_lv.json`

File sharing is enabled, so on the iPhone you can use the Files app
(**On My iPhone → SpeedZone LV → zones_lv.json**) to replace the override JSON
without rebuilding the app. The database is validated on launch; invalid files
fall back to the bundled version and show an error in Settings.

Read `docs/ZONE_DATABASE.md` before adding zones.

---

## What still needs testing

- Compile and run on macOS/Xcode 16+ (this Windows machine cannot do it).
- Visual pass on iPhone 14 Pro / 15 Pro / 16 Pro for safe areas, Dynamic
  Island cutout and long zone names.
- Demo drive: approaching → active → completed, restart, history persistence,
  app relaunch.
- Formatting: Latvian decimal commas, durations, distances.
- Database loader: valid empty file, malformed JSON, Documents override,
  duplicate IDs, invalid coordinates.
- Free-Apple-ID install path with Sideloadly or AltStore.

Phase 2 starts with CoreLocation: authorization flow, filtered background
samples and live speed integration.

---

## Privacy and legal

- All data stays on the device.
- The app does not claim to measure speed officially.
- Only verified zones with a source and verification date may be used for
  detection.
- Traffic signs and Latvian law always take precedence.

Copyright © 2026. Private personal project.
