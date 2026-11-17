import ActivityKit
import Foundation
import Observation

/// Owns the single Live Activity used for the current measurement.
@MainActor
@Observable
final class LiveActivityManager {
    private(set) var isActive = false
    private(set) var lastError: String?

    private var activity: Activity<SpeedZoneActivityAttributes>?

    var isSystemEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    init() {
        isActive = !Activity<SpeedZoneActivityAttributes>.activities.isEmpty
        activity = Activity<SpeedZoneActivityAttributes>.activities.first
    }

    /// Starts the activity for an approach or active measurement. Calling it
    /// repeatedly simply updates the existing activity.
    func startIfNeeded(snapshot: RideSnapshot, enabled: Bool) {
        guard enabled else { return }
        guard snapshot.phase == .approaching || snapshot.phase == .active else { return }

        if activity != nil {
            update(snapshot: snapshot, enabled: enabled)
            return
        }

        guard isSystemEnabled else {
            lastError = "Live Activity sistēmā nav atļauta."
            return
        }

        let attributes = SpeedZoneActivityAttributes(
            zoneID: snapshot.zone.id,
            zoneName: snapshot.zone.name,
            road: snapshot.zone.road,
            directionLabel: snapshot.zone.directionLabel,
            officialLengthMeters: snapshot.zone.officialLengthMeters
        )

        let content = ActivityContent(
            state: state(from: snapshot),
            staleDate: Date().addingTimeInterval(45)
        )

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            isActive = true
            lastError = nil
        } catch {
            lastError = "Live Activity neizdevās palaist: \(error.localizedDescription)"
        }
    }

    func update(snapshot: RideSnapshot, enabled: Bool) {
        guard enabled, let activity else { return }

        let content = ActivityContent(
            state: state(from: snapshot),
            staleDate: Date().addingTimeInterval(45)
        )

        Task {
            await activity.update(content)
        }
    }

    func end(snapshot: RideSnapshot?, enabled: Bool) {
        guard let activity else {
            isActive = false
            return
        }

        let finalContent: ActivityContent<SpeedZoneActivityAttributes.ContentState>?
        if let snapshot {
            finalContent = ActivityContent(
                state: state(from: snapshot),
                staleDate: Date().addingTimeInterval(8)
            )
        } else {
            finalContent = nil
        }

        Task {
            await activity.end(finalContent, dismissalPolicy: .after(Date().addingTimeInterval(8)))
        }

        self.activity = nil
        isActive = false
    }

    func endAll() {
        Task {
            for activity in Activity<SpeedZoneActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        activity = nil
        isActive = false
    }

    private func state(from snapshot: RideSnapshot) -> SpeedZoneActivityAttributes.ContentState {
        SpeedZoneActivityAttributes.ContentState(
            phase: snapshot.phase.rawValue,
            currentSpeedKmh: snapshot.currentSpeedKmh,
            averageSpeedKmh: snapshot.averageSpeedKmh,
            speedLimitKmh: snapshot.zone.speedLimitKmh,
            targetSpeedKmh: snapshot.targetSpeedKmh,
            predictedAverageKmh: snapshot.predictedAverageKmh,
            remainingDistanceMeters: snapshot.remainingDistanceMeters,
            distanceToEntryMeters: snapshot.distanceToEntryMeters,
            progress: snapshot.progress,
            elapsed: snapshot.elapsed,
            accuracyMeters: snapshot.accuracyMeters,
            isDemo: snapshot.isDemo,
            updatedAt: snapshot.capturedAt
        )
    }
}
