import Combine
import Foundation
import Observation

/// Composition root. Owns every long-lived service and wires the live stack
/// together without hiding dependencies inside the views.
@MainActor
@Observable
final class AppEnvironment {
    let settings: AppSettings
    let appearance: AppearanceSettings
    let history: HistoryStore
    let zoneRepository: LocalZoneRepository
    let userZones: UserZoneStore
    let notifications: NotificationManager
    let liveActivity: LiveActivityManager
    let dashboard: DashboardViewModel

    private var cancellables = Set<AnyCancellable>()

    init() {
        let settings = AppSettings()
        let appearance = AppearanceSettings()
        let history = HistoryStore()
        let zoneRepository = LocalZoneRepository()
        let userZones = UserZoneStore()
        let notifications = NotificationManager()
        let liveActivity = LiveActivityManager()
        let dashboard = DashboardViewModel(
            settings: settings,
            notifications: notifications,
            liveActivity: liveActivity
        )

        self.settings = settings
        self.appearance = appearance
        self.history = history
        self.zoneRepository = zoneRepository
        self.userZones = userZones
        self.notifications = notifications
        self.liveActivity = liveActivity
        self.dashboard = dashboard

        ThemeRuntime.shared.appearance = appearance

        dashboard.onMeasurementCompleted = { [weak history] snapshot in
            guard let history, let record = TripRecord(snapshot: snapshot) else { return }
            history.add(record)
        }

        notifications.soundEnabled = settings.soundAlertsEnabled
        refreshZones()
        subscribeToSettings()
    }

    var verifiedZoneCount: Int {
        zoneRepository.database.verifiedZones.count
    }

    var manualZoneCount: Int {
        userZones.zones.count
    }

    var allDetectionZones: [SpeedZone] {
        zoneRepository.database.verifiedZones + userZones.zones
    }

    func bootstrap() {
        dashboard.autoStartIfNeeded()
        Task { @MainActor [weak self] in
            await self?.notifications.refreshAuthorizationStatus()
        }
    }

    func refreshZones() {
        dashboard.updateZones(allDetectionZones)
    }

    func reloadDatabase() {
        zoneRepository.reload()
        refreshZones()
    }

    private func subscribeToSettings() {
        settings.$backgroundTrackingEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                Task { @MainActor in
                    self?.dashboard.setBackgroundTrackingEnabled(enabled)
                }
            }
            .store(in: &cancellables)

        settings.$autoDetectionEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                Task { @MainActor in
                    self?.dashboard.setAutoDetectionEnabled(enabled)
                }
            }
            .store(in: &cancellables)

        settings.$liveActivitiesEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                guard !enabled else { return }
                Task { @MainActor in
                    self?.liveActivity.endAll()
                }
            }
            .store(in: &cancellables)

        settings.$personalTargetOffsetKmh
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.dashboard.settingsDidChange()
                }
            }
            .store(in: &cancellables)

        settings.$soundAlertsEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                Task { @MainActor in
                    self?.notifications.soundEnabled = enabled
                }
            }
            .store(in: &cancellables)

        settings.$notificationsEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                guard enabled else { return }
                Task { @MainActor in
                    await self?.notifications.requestAuthorizationIfNeeded()
                }
            }
            .store(in: &cancellables)

        userZones.$zones
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.refreshZones()
                }
            }
            .store(in: &cancellables)
    }
}
