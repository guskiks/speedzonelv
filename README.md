# SpeedZone LV

iPhone app for Latvian average-speed zones. Local-only, no server, no App Store. Build via GitHub Actions → unsigned IPA → sideload with iLoader/AltStore.

## Install
1. **Actions → Build unsigned IPA → Run workflow**
2. Download `SpeedZoneLV-unsigned.ipa` artifact
3. Open in **iLoader** (or AltStore/Sideloadly) → install to iPhone
4. Settings → General → VPN & Device Management → Trust developer
5. Enable Developer Mode on iPhone

---

## Changelog

### v1 (09.11) — Base
- Xcode project, SwiftUI dashboard, GPS tracking, zone detection
- Live Activity + Dynamic Island, notifications, trip history
- Manual zone editor, 6 themes, demo drive
- `zones_lv.json` (empty templates), GitHub Actions build

### v2 (14.11) — Location fixes
- Improved `LocationManager` (accuracy filtering, background updates)
- Better approach/entry/exit detection logic

### v3 (14.11) — Dashboard polish
- `DashboardViewModel` refactor
- Updated dashboard views (SpeedGauge, ZoneHeader, Idle/Completed states)

### v4 (14.11) — Data update
- Added `zones_lv.json` (93 KB, real zone data)
- Synced LocationManager + DashboardViewModel from v3

### v5 (14.11) — Settings overhaul
- Full `SettingsView` rewrite (29 KB)
- `ZoneEditorView` improvements
- Updated dashboard views + ZoneHeaderCard
- New zone import files (`zones_lv_v5.json`, `zones_lv_v5_import.json`)

### v6 (14.11) — Database + polish
- `LocalZoneRepository` (database layer)
- Latest `SettingsView`, `ZoneEditorView`, dashboard views
- Synced LocationManager + DashboardViewModel

### Latest (17.11) — Detection fix
- `ZoneDetectionEngine`: fixed long/winding sections (14 km+)
- `DashboardViewModel` minor updates

---

## Project structure (minimal)
```
SpeedZoneLV/
├── SpeedZoneLV/          # App source (Models, Views, ViewModels, Services)
├── Widgets/              # Live Activity widget
├── .github/workflows/    # build.yml → unsigned IPA
├── zones_lv.json         # Bundled zone database
└── SpeedZoneLV.xcodeproj
```

## Requirements
- iPhone 14 Pro+ (Dynamic Island), iOS 17+
- Free Apple ID (7-day resign with free provisioning)
- GitHub account (free macOS runner minutes)

---

*Personal project. GPS estimates only — traffic signs and law take precedence.*