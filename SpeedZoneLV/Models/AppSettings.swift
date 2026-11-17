import Combine
import Foundation

/// User preferences. Persisted immediately to UserDefaults.
@MainActor
final class AppSettings: ObservableObject {
    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Keys.notifications) }
    }

    @Published var soundAlertsEnabled: Bool {
        didSet { defaults.set(soundAlertsEnabled, forKey: Keys.soundAlerts) }
    }

    @Published var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    @Published var keepScreenAwakeDuringRide: Bool {
        didSet { defaults.set(keepScreenAwakeDuringRide, forKey: Keys.keepScreenAwake) }
    }

    /// Automatic approach/entry detection. Turning this off keeps GPS speed
    /// and manual testing available but stops the app from starting a section.
    @Published var autoDetectionEnabled: Bool {
        didSet { defaults.set(autoDetectionEnabled, forKey: Keys.autoDetection) }
    }

    /// Starts GPS monitoring when the app becomes active and permission is
    /// already granted. This is the "auto start" that can be disabled.
    @Published var autoStartEnabled: Bool {
        didSet { defaults.set(autoStartEnabled, forKey: Keys.autoStart) }
    }

    /// Keeps CoreLocation running while the screen is locked / the app is in
    /// the background. Requires "Always" location permission.
    @Published var backgroundTrackingEnabled: Bool {
        didSet { defaults.set(backgroundTrackingEnabled, forKey: Keys.backgroundTracking) }
    }

    @Published var liveActivitiesEnabled: Bool {
        didSet { defaults.set(liveActivitiesEnabled, forKey: Keys.liveActivities) }
    }

    /// A personal target above the posted limit. It is intentionally separate
    /// from the official limit and never changes the official value stored in
    /// zone data. Range is clamped to 0...20 km/h.
    @Published var personalTargetOffsetKmh: Int {
        didSet {
            let clamped = min(max(personalTargetOffsetKmh, 0), 20)
            if clamped != personalTargetOffsetKmh {
                personalTargetOffsetKmh = clamped
            }
            defaults.set(clamped, forKey: Keys.personalOffset)
        }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let notifications = "settings.notificationsEnabled"
        static let soundAlerts = "settings.soundAlertsEnabled"
        static let haptics = "settings.hapticsEnabled"
        static let keepScreenAwake = "settings.keepScreenAwakeDuringRide"
        static let autoDetection = "settings.autoDetectionEnabled"
        static let autoStart = "settings.autoStartEnabled"
        static let backgroundTracking = "settings.backgroundTrackingEnabled"
        static let liveActivities = "settings.liveActivitiesEnabled"
        static let personalOffset = "settings.personalTargetOffsetKmh"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.notificationsEnabled = defaults.object(forKey: Keys.notifications) as? Bool ?? true
        self.soundAlertsEnabled = defaults.object(forKey: Keys.soundAlerts) as? Bool ?? true
        self.hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        self.keepScreenAwakeDuringRide = defaults.object(forKey: Keys.keepScreenAwake) as? Bool ?? true
        self.autoDetectionEnabled = defaults.object(forKey: Keys.autoDetection) as? Bool ?? true
        self.autoStartEnabled = defaults.object(forKey: Keys.autoStart) as? Bool ?? true
        self.backgroundTrackingEnabled = defaults.object(forKey: Keys.backgroundTracking) as? Bool ?? true
        self.liveActivitiesEnabled = defaults.object(forKey: Keys.liveActivities) as? Bool ?? true
        self.personalTargetOffsetKmh = defaults.object(forKey: Keys.personalOffset) as? Int ?? 0
    }

    /// Official limit + personal reserve, capped to a sane maximum.
    func targetSpeedKmh(for officialLimitKmh: Int) -> Int {
        let offset = min(max(personalTargetOffsetKmh, 0), 20)
        return min(officialLimitKmh + offset, 160)
    }

    var personalTargetDescription: String {
        personalTargetOffsetKmh == 0
            ? "Mērķis sakrīt ar oficiālo limitu."
            : "Mērķis ir par +\(personalTargetOffsetKmh) km/h virs oficiālā limita."
    }
}
