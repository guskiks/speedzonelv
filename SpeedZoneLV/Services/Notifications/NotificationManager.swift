import Foundation
import Observation
import UIKit
import UserNotifications

/// Local notifications and haptics for approach, entry, goal exceeded and
/// completion. Notifications are always optional and never block measurement.
@MainActor
@Observable
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Updated from `AppSettings.soundAlertsEnabled`.
    var soundEnabled = true

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
        Task { @MainActor [weak self] in
            await self?.refreshAuthorizationStatus()
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            await refreshAuthorizationStatus()
            return false
        }
    }

    func requestAuthorizationIfNeeded() async {
        guard authorizationStatus == .notDetermined else { return }
        _ = await requestAuthorization()
    }

    var isAuthorized: Bool {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }

    func notifyApproach(zone: SpeedZone, distanceMeters: Double) {
        schedule(
            identifier: "approach-\(zone.id)",
            title: "Tuvojas vidējā ātruma zona",
            body: "\(zone.road) · \(zone.name). Līdz sākumam \(Fmt.distance(distanceMeters))."
        )
    }

    func notifyEntry(zone: SpeedZone) {
        schedule(
            identifier: "entry-\(zone.id)",
            title: "Mērījums sākts",
            body: "\(zone.road) · \(zone.name). \(Fmt.speedLimit(zone.speedLimitKmh))."
        )
    }

    func notifyGoalExceeded(zone: SpeedZone, averageKmh: Double, targetKmh: Int) {
        schedule(
            identifier: "goal-\(zone.id)",
            title: "Vidējais virs tava mērķa",
            body: "Vidējais \(Fmt.speed(averageKmh)) km/h, mērķis \(targetKmh) km/h. Oficiālais limits \(zone.speedLimitKmh) km/h."
        )
    }

    func notifyFinished(zone: SpeedZone, averageKmh: Double, targetKmh: Int) {
        let comparison: String
        if averageKmh > Double(targetKmh) + 0.5 {
            comparison = "Virs tava mērķa (\(targetKmh) km/h)."
        } else {
            comparison = "Mērķa robežās (\(targetKmh) km/h)."
        }

        schedule(
            identifier: "finished-\(zone.id)-\(Int(Date().timeIntervalSince1970))",
            title: "Posms pabeigts",
            body: "\(zone.road) · \(zone.name). Vidējais \(Fmt.speed(averageKmh)) km/h. \(comparison)"
        )
    }

    func notifyGPSTestStarted() {
        schedule(
            identifier: "gps-test-started",
            title: "GPS tests sākts",
            body: "1 km testa koridors. Brauc taisni, lai pārbaudītu iebraukšanu, ātruma līkni, paziņojumus un Live Activity."
        )
    }

    func notifyGPSTestFinished(averageKmh: Double) {
        schedule(
            identifier: "gps-test-finished-\(Int(Date().timeIntervalSince1970))",
            title: "GPS tests pabeigts",
            body: "Vidējais \(Fmt.speed(averageKmh)) km/h. Tests saglabāts vēsturē."
        )
    }

    // MARK: - Haptics

    func playHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    func playSelectionHaptic() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    // MARK: - Scheduling

    private func schedule(identifier: String, title: String, body: String) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = soundEnabled ? .default : nil
        content.threadIdentifier = "speedzone-lv"

        if soundEnabled {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        center.add(request) { _ in
            // Local notification delivery failures are non-fatal.
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}
