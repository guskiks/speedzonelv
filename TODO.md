# TODO — SpeedZone LV

Legend: `[x]` implemented, `[ ]` pending, `[~]` partially implemented.

## Environment

- [x] Inspect Windows 11 development machine.
- [x] Confirm no native iOS toolchain exists on Windows.
- [x] Create repo structure and Xcode project.
- [x] Provide a free macOS build path (GitHub Actions).
- [ ] Verify the project compiles on macOS/Xcode 16+.
- [ ] Install on the physical iPhone 14 Pro with a free Apple ID.

## Phase 1 — Architecture and SwiftUI interface

- [x] App entry point and composition root.
- [x] Dark design system, cards, typography, custom tab bar.
- [x] Dashboard: speed gauge, average, limit, prediction, recommendation,
      start speed, elapsed time, remaining distance/time, progress, zone header.
- [x] Approaching / active / completed / idle states.
- [x] Latvian localization of the interface.
- [x] Interactive demo drive (clearly marked DEMO).
- [x] Speed calculation math.
- [x] Local JSON zone database loader + validation + Documents override.
- [x] Database reload button in Settings after replacing the Documents file.
- [x] Local trip history store.
- [x] History screen, empty state, deletion.
- [x] Settings screen, permission status, database provenance.
- [x] App icon and asset catalog.
- [x] Unsigned IPA GitHub Actions workflow.
- [x] README with free signing/build instructions.
- [ ] Visual verification on device, especially Dynamic Island safe areas.
- [ ] Unit tests for `SpeedCalculationEngine` (add a test target in Phase 2).
- [ ] Test empty/malformed database UI states on device.

## Phase 2 — GPS and speed calculation

- [x] `LocationManager` (CLLocationManager, background authorization).
- [~] Authorization onboarding flow (When In Use → Always; requests available, no dedicated walkthrough).
- [x] GPS filtering: horizontalAccuracy, timestamp age, impossible jumps,
      minimum distance/time between accepted samples.
- [x] Live current-speed integration (replaced demo source).
- [x] Distance integration from accepted samples.
- [~] Pause/resume and GPS-loss handling.
- [x] Accuracy indicator and stale-data state in UI.
- [ ] Unit tests with recorded GPX traces.

## Phase 3 — Verified Latvian zone database

- [x] Research official/public average-speed sections (LVC, CSDD, OSM).
- [x] Record source URL, license, retrieval date and verification date for
      every zone.
- [x] Add only verified coordinates; never guess.
- [x] Add directionality handling.
- [ ] Validate stored zone lengths against official figures (no coordinates yet).
- [x] Add database version/update documentation.
- [ ] Optionally support GPX/GeoJSON import for maintenance.

## Phase 4 — Automatic zone detection

- [x] Approach radius and entry notifications.
- [x] Entry-line crossing with direction/bearing check.
- [x] Road/proximity false-positive rejection.
- [x] Exit detection and automatic finish.
- [x] Multiple simultaneous nearby zones.
- [x] Temporary GPS-loss tolerance.
- [ ] State machine tests and route replay tests.

## Phase 5 — Dynamic Island and Live Activities

- [x] Add Widget Extension target to the project.
- [x] `ActivityAttributes` shared between app and widget.
- [x] Compact / minimal / expanded Dynamic Island layouts.
- [x] Lock Screen Live Activity panel.
- [~] Update throttling and battery-aware cadence.
- [ ] Self-updating timer/progress where possible.
- [x] `NSSupportsLiveActivities` in Info.plist.
- [x] Start/end/update lifecycle tied to zone session.
- [ ] Test on iPhone 14 Pro with a free signing profile.

## Phase 6 — Background tracking and notifications

- [x] Background location updates.
- [ ] Persist active measurement across app termination.
- [x] Local notifications: approach, entry, near-limit, exit, completion.
- [x] Optional sound/haptics respecting app settings.
- [x] Notification permission flow.
- [ ] Battery profiling and adaptive accuracy.
- [x] Honest in-app explanation of iOS background limits.

## Phase 7 — History, testing, optimization

- [x] History detail screen and full speed curve.
- [ ] Export measurements.
- [ ] Store verification/source snapshot with each measurement.
- [ ] Demo records cleanup option.
- [ ] End-to-end route tests.
- [ ] Performance, memory, energy audit.
- [ ] Accessibility audit (VoiceOver, Dynamic Type, contrast).
- [~] Final device installation guide and release notes.

## Known limitations of the current build

- The project has not been compiled on macOS or tested on a physical iPhone.
- No verified zone coordinates are present. `zones_lv.json` is intentionally
  empty; official LVC sections exist only as kilometre-range templates.
- Background tracking requires “Always” location permission; iOS may pause or
  terminate the app, and a measurement interrupted mid-section is not saved.
- Live Activities need system permission and cannot run in Expo Go/simulator
  limitations; test on a real device.
- Personal target is an informational preference, not a legal allowance.
