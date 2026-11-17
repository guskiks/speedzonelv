import CoreLocation
import Foundation
import Observation
import SwiftUI
import UIKit

/// Central live/demo state machine: CoreLocation → filtering → zone detection
/// → speed calculation → UI, notifications, Live Activity and history.
@MainActor
@Observable
final class DashboardViewModel {
    private(set) var snapshot: RideSnapshot?
    private(set) var isDemoRunning = false
    private(set) var isLiveTracking = false
    private(set) var isGPSTestMode = false
    private(set) var isGPSTestPending = false
    private(set) var lastError: String?
    private(set) var zones: [SpeedZone] = []

    let location = LocationManager()

    /// Called exactly once when a measurement finishes.
    var onMeasurementCompleted: ((RideSnapshot) -> Void)?

    private let settings: AppSettings
    private let notifications: NotificationManager
    private let liveActivity: LiveActivityManager
    private let demo = DemoRideSimulator()

    private var testZone: SpeedZone?
    private var session: LiveSession?
    private var previousFix: GPSFix?
    private var approachCandidate: ZoneCandidate?
    private var lastApproachNotifiedZoneID: String?
    private var lastCompletionDate: Date?
    private var offRouteFixCount = 0

    private struct LiveSession {
        let zone: SpeedZone
        let startedAt: Date
        let entryOffsetMeters: Double
        let startSpeedKmh: Double
        var samples: [SpeedSample]
        var lastSampleDistanceMeters: Double
        var lastSampleElapsed: TimeInterval
        var hasNotifiedGoalExceeded: Bool
    }

    init(
        settings: AppSettings,
        notifications: NotificationManager,
        liveActivity: LiveActivityManager
    ) {
        self.settings = settings
        self.notifications = notifications
        self.liveActivity = liveActivity
        self.isLiveTracking = location.isTracking

        location.onFix = { [weak self] fix in
            self?.handle(fix)
        }
        location.onAuthorizationChange = { [weak self] _ in
            self?.handleAuthorizationChange()
        }
        location.onError = { [weak self] message in
            self?.lastError = message
        }

        demo.onUpdate = { [weak self] snapshot in
            self?.handleDemo(snapshot)
        }
    }

    // MARK: - Public state

    var availableZones: [SpeedZone] {
        var result = zones
        if let testZone {
            result.append(testZone)
        }
        return result
    }

    var currentSpeedKmh: Double {
        location.latestFix?.speedKmh ?? 0
    }

    var statusMessage: String {
        if isDemoRunning { return "Demo" }
        if isGPSTestPending { return "Gaida GPS signālu" }
        if isGPSTestMode { return "GPS tests" }
        if isLiveTracking {
            return location.isTracking ? "GPS aktīvs" : "Gaida atļauju"
        }
        return "Gaidīšana"
    }

    var isWaitingForPermission: Bool {
        isLiveTracking
            && !location.isTracking
            && (location.authorizationStatus == .notDetermined
                || location.authorizationStatus == .denied
                || location.authorizationStatus == .restricted)
    }

    // MARK: - Lifecycle and settings

    func updateZones(_ zones: [SpeedZone]) {
        self.zones = zones
        if let snapshot,
           snapshot.phase == .approaching,
           !availableZones.contains(where: { $0.id == snapshot.zone.id }) {
            self.snapshot = nil
            approachCandidate = nil
            liveActivity.endAll()
        }
    }

    func autoStartIfNeeded() {
        guard settings.autoStartEnabled else { return }
        guard !isLiveTracking, !isDemoRunning else { return }
        guard location.canStartTracking else { return }
        startLiveTracking()
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            location.refreshAuthorizationStatus()
            if isLiveTracking, !location.isTracking, location.canStartTracking {
                location.setBackgroundUpdatesEnabled(settings.backgroundTrackingEnabled)
                location.startTracking()
            } else if !isLiveTracking, !isDemoRunning,
                      settings.autoStartEnabled,
                      location.canStartTracking {
                startLiveTracking()
            }
            Task { @MainActor [weak self] in
                await self?.notifications.refreshAuthorizationStatus()
            }
        case .background:
            location.setBackgroundUpdatesEnabled(settings.backgroundTrackingEnabled)
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    func setBackgroundTrackingEnabled(_ enabled: Bool) {
        location.setBackgroundUpdatesEnabled(enabled)
    }

    func setAutoDetectionEnabled(_ enabled: Bool) {
        if !enabled, snapshot?.phase == .approaching {
            snapshot = nil
            approachCandidate = nil
            liveActivity.endAll()
        }
    }

    func settingsDidChange() {
        if !settings.liveActivitiesEnabled {
            liveActivity.endAll()
        }
        location.setBackgroundUpdatesEnabled(settings.backgroundTrackingEnabled)
    }

    // MARK: - Permissions

    func requestLocationPermission() {
        location.requestWhenInUseAuthorization()
    }

    func requestAlwaysPermission() {
        location.requestAlwaysAuthorization()
    }

    func requestNotificationPermission() {
        Task { @MainActor [weak self] in
            await self?.notifications.requestAuthorization()
        }
    }

    // MARK: - Live tracking

    func startLiveTracking() {
        if isDemoRunning {
            stopDemo()
        }

        lastError = nil
        isGPSTestPending = false
        if snapshot?.phase == .completed {
            snapshot = nil
        }

        isLiveTracking = true
        location.setBackgroundUpdatesEnabled(settings.backgroundTrackingEnabled)
        location.setHighAccuracyMode(false)
        location.startTracking()
        UIApplication.shared.isIdleTimerDisabled = settings.keepScreenAwakeDuringRide
    }

    func stopLiveTracking(showInterruption: Bool = true) {
        let hadActiveMeasurement = session != nil

        location.stopTracking()
        location.setHighAccuracyMode(false)
        isLiveTracking = false
        isGPSTestMode = false
        isGPSTestPending = false
        testZone = nil
        session = nil
        previousFix = nil
        approachCandidate = nil
        offRouteFixCount = 0
        liveActivity.endAll()
        UIApplication.shared.isIdleTimerDisabled = false

        if snapshot?.phase != .completed {
            snapshot = nil
        }

        if showInterruption, hadActiveMeasurement {
            lastError = "Mērījums pārtraukts pirms finiša. Daļējs brauciens netiek saglabāts."
            if settings.hapticsEnabled {
                notifications.playHaptic(.warning)
            }
        }
    }

    func startGPSTest() {
        stopDemo()
        lastError = nil

        session = nil
        snapshot = nil
        testZone = nil
        previousFix = nil
        approachCandidate = nil
        offRouteFixCount = 0
        isGPSTestMode = false
        isGPSTestPending = true
        isLiveTracking = true

        location.setBackgroundUpdatesEnabled(settings.backgroundTrackingEnabled)
        location.startTracking()
        UIApplication.shared.isIdleTimerDisabled = settings.keepScreenAwakeDuringRide

        if let fix = location.latestFix,
           fix.timestamp.timeIntervalSinceNow > -12 {
            beginGPSTest(from: fix)
        }
    }

    // MARK: - Demo

    func startDemo() {
        stopLiveTracking(showInterruption: false)
        snapshot = nil
        lastError = nil
        isDemoRunning = true
        UIApplication.shared.isIdleTimerDisabled = settings.keepScreenAwakeDuringRide
        demo.start(
            targetSpeedKmh: settings.targetSpeedKmh(for: SpeedZone.demo.speedLimitKmh)
        )
    }

    func stopDemo() {
        demo.stop()
        isDemoRunning = false
        snapshot = nil
        UIApplication.shared.isIdleTimerDisabled = false
        liveActivity.endAll()
    }

    func clearCompletedMeasurement() {
        guard snapshot?.phase == .completed else { return }
        snapshot = nil
        lastCompletionDate = nil
    }

    // MARK: - GPS handling

    private func handle(_ fix: GPSFix) {
        guard isLiveTracking, !isDemoRunning else { return }

        lastError = nil

        if isGPSTestPending {
            beginGPSTest(from: fix)
            previousFix = fix
            return
        }

        if session != nil {
            updateSession(with: fix)
        } else {
            detectZone(with: fix)
        }

        previousFix = fix
    }

    private func beginGPSTest(from fix: GPSFix) {
        let heading = fix.hasValidCourse ? fix.courseDegrees : 0
        let zone = SpeedZone.gpsTest(from: fix.coordinate, headingDegrees: heading)

        testZone = zone
        isGPSTestMode = true
        isGPSTestPending = false

        beginSession(
            zone: zone,
            startDate: fix.timestamp,
            entryOffsetMeters: 0,
            startSpeedKmh: fix.speedKmh,
            fix: fix,
            notifyEntry: false
        )

        notifications.notifyGPSTestStarted()
        if settings.hapticsEnabled {
            notifications.playHaptic(.success)
        }
    }

    private func detectZone(with fix: GPSFix) {
        guard settings.autoDetectionEnabled else {
            clearApproachIfNeeded()
            return
        }

        if let lastCompletionDate,
           Date().timeIntervalSince(lastCompletionDate) < 10 {
            return
        }

        // Crossing the entry line between two fixes: interpolate the exact
        // crossing time so the elapsed measurement is not late by one sample.
        if let previousFix,
           let candidate = ZoneDetectionEngine.bestApproach(
               zones: availableZones,
               fix: fix,
               previous: previousFix
           ),
           let crossing = ZoneDetectionEngine.entryCrossingDate(
               previous: previousFix,
               current: fix,
               candidate: candidate
           ) {
            print("[Detect] ENTRY_CROSSING zone=\(candidate.zone.name) along=\(candidate.alongZoneMeters)m lateral=\(candidate.lateralMeters)m speed=\(fix.speedKmh)kmh")
            beginSession(
                zone: candidate.zone,
                startDate: crossing,
                entryOffsetMeters: 0,
                startSpeedKmh: fix.speedKmh,
                fix: fix,
                notifyEntry: true
            )
            return
        }

        // The app was opened while already inside a section.
        if let insideCandidate = ZoneDetectionEngine.bestInside(
            zones: availableZones,
            fix: fix,
            previous: previousFix
        ), let insideDistance = ZoneDetectionEngine.insideStartDistance(candidate: insideCandidate) {
            print("[Detect] ALREADY_INSIDE zone=\(insideCandidate.zone.name) insideDistance=\(insideDistance)m lateral=\(insideCandidate.lateralMeters)m")
            beginSession(
                zone: insideCandidate.zone,
                startDate: fix.timestamp,
                entryOffsetMeters: insideDistance,
                startSpeedKmh: fix.speedKmh,
                fix: fix,
                notifyEntry: true
            )
            return
        }

        if let candidate = ZoneDetectionEngine.bestApproach(
            zones: availableZones,
            fix: fix,
            previous: previousFix
        ) {
            print("[Detect] APPROACH zone=\(candidate.zone.name) dist=\(candidate.distanceToEntryMeters)m along=\(candidate.alongZoneMeters)m lateral=\(candidate.lateralMeters)m")
            approachCandidate = candidate
            location.setHighAccuracyMode(true)
            publishApproach(candidate, fix: fix)
        } else {
            clearApproachIfNeeded()
        }
    }

    private func beginSession(
        zone: SpeedZone,
        startDate: Date,
        entryOffsetMeters: Double,
        startSpeedKmh: Double,
        fix: GPSFix,
        notifyEntry: Bool
    ) {
        print("[Session] BEGIN zone=\(zone.name) id=\(zone.id) length=\(zone.officialLengthMeters)m entryOffset=\(entryOffsetMeters)m startSpeed=\(startSpeedKmh)kmh notify=\(notifyEntry)")

        let initialSample = SpeedSample(
            distanceMeters: 0,
            speedKmh: startSpeedKmh,
            elapsed: 0,
            timestamp: startDate
        )

        session = LiveSession(
            zone: zone,
            startedAt: startDate,
            entryOffsetMeters: max(entryOffsetMeters, 0),
            startSpeedKmh: startSpeedKmh,
            samples: [initialSample],
            lastSampleDistanceMeters: 0,
            lastSampleElapsed: 0,
            hasNotifiedGoalExceeded: false
        )

        approachCandidate = nil
        lastApproachNotifiedZoneID = nil
        offRouteFixCount = 0
        location.setHighAccuracyMode(true)

        publishActive(fix: fix, completed: false)
        if let snapshot {
            liveActivity.startIfNeeded(snapshot: snapshot, enabled: settings.liveActivitiesEnabled)
        }

        if notifyEntry {
            notifications.notifyEntry(zone: zone)
        }

        if settings.hapticsEnabled {
            notifications.playHaptic(.success)
        }
    }

    private func updateSession(with fix: GPSFix) {
        guard var session else { return }

        guard let candidate = ZoneDetectionEngine.candidate(
            zone: session.zone,
            fix: fix,
            previous: previousFix
        ) else {
            return
        }

        // Progress is based on along-track distance. Don't cancel for lateral deviation.
        offRouteFixCount = 0

        let alongMeters = candidate.alongZoneMeters
        let travelledMeters = max(alongMeters - session.entryOffsetMeters, 0)
        let elapsed = max(fix.timestamp.timeIntervalSince(session.startedAt), 0)

        print("[Session] UPDATE zone=\(session.zone.name) along=\(alongMeters)m travelled=\(travelledMeters)m elapsed=\(elapsed)s lateral=\(candidate.lateralMeters)m speed=\(fix.speedKmh)kmh")

        if travelledMeters >= session.zone.officialLengthMeters - 2 {
            completeSession(with: fix, travelledMeters: session.zone.officialLengthMeters)
            return
        }

        if shouldAppendSample(
            distanceMeters: travelledMeters,
            elapsed: elapsed,
            session: session
        ) {
            session.samples.append(
                SpeedSample(
                    distanceMeters: travelledMeters,
                    speedKmh: fix.speedKmh,
                    elapsed: elapsed,
                    timestamp: fix.timestamp
                )
            )
            session.lastSampleDistanceMeters = travelledMeters
            session.lastSampleElapsed = elapsed
        }

        self.session = session

        let average = SpeedCalculationEngine.averageSpeedKmh(
            distanceMeters: travelledMeters,
            duration: elapsed
        )
        let target = Double(settings.targetSpeedKmh(for: session.zone.speedLimitKmh))

        if !session.hasNotifiedGoalExceeded,
           let average,
           average > target + 2 {
            session.hasNotifiedGoalExceeded = true
            self.session = session
            notifications.notifyGoalExceeded(
                zone: session.zone,
                averageKmh: average,
                targetKmh: Int(target)
            )
            if settings.hapticsEnabled {
                notifications.playHaptic(.warning)
            }
        }

        publishActive(fix: fix, completed: false)
        if let snapshot {
            liveActivity.update(snapshot: snapshot, enabled: settings.liveActivitiesEnabled)
        }
    }

    private func publishActive(fix: GPSFix, completed: Bool) {
        guard let session else { return }

        let elapsed = max(fix.timestamp.timeIntervalSince(session.startedAt), 0)
        let travelled: Double
        let remaining: Double
        let average: Double?
        let predicted: Double?
        let recommended: Double?

        if completed {
            travelled = session.zone.officialLengthMeters
            remaining = 0
            average = SpeedCalculationEngine.averageSpeedKmh(
                distanceMeters: travelled,
                duration: elapsed
            )
            predicted = average
            recommended = nil
        } else {
            let rawDistance = max(
                session.samples.last?.distanceMeters ?? 0,
                0
            )
            travelled = min(rawDistance, session.zone.officialLengthMeters)
            remaining = max(session.zone.officialLengthMeters - travelled, 0)
            average = SpeedCalculationEngine.averageSpeedKmh(
                distanceMeters: travelled,
                duration: elapsed
            )
            predicted = SpeedCalculationEngine.predictedAverageKmh(
                distanceTravelledMeters: travelled,
                totalDistanceMeters: session.zone.officialLengthMeters,
                elapsed: elapsed,
                currentSpeedKmh: fix.speedKmh
            )
            recommended = SpeedCalculationEngine.recommendedRemainingAverageKmh(
                distanceTravelledMeters: travelled,
                totalDistanceMeters: session.zone.officialLengthMeters,
                elapsed: elapsed,
                targetAverageKmh: Double(settings.targetSpeedKmh(for: session.zone.speedLimitKmh))
            )
        }

        let snapshot = RideSnapshot(
            phase: completed ? .completed : .active,
            zone: session.zone,
            currentSpeedKmh: completed ? 0 : fix.speedKmh,
            targetSpeedKmh: settings.targetSpeedKmh(for: session.zone.speedLimitKmh),
            averageSpeedKmh: average,
            startSpeedKmh: session.startSpeedKmh,
            distanceTravelledMeters: travelled,
            remainingDistanceMeters: remaining,
            distanceToEntryMeters: nil,
            elapsed: elapsed,
            estimatedRemainingTime: completed
                ? nil
                : SpeedCalculationEngine.estimatedRemainingTime(
                    remainingDistanceMeters: remaining,
                    currentSpeedKmh: fix.speedKmh
                ),
            predictedAverageKmh: predicted,
            recommendedAverageKmh: recommended,
            progress: min(max(travelled / session.zone.officialLengthMeters, 0), 1),
            accuracyMeters: fix.horizontalAccuracy,
            isDemo: false,
            capturedAt: fix.timestamp,
            samples: session.samples
        )

        self.snapshot = snapshot
    }

    private func shouldAppendSample(
        distanceMeters: Double,
        elapsed: TimeInterval,
        session: LiveSession
    ) -> Bool {
        if distanceMeters - session.lastSampleDistanceMeters >= 3 {
            return true
        }
        if elapsed - session.lastSampleElapsed >= 1.2 {
            return true
        }
        return false
    }

    private func completeSession(with fix: GPSFix, travelledMeters: Double) {
        guard var session else { return }

        let elapsed = max(fix.timestamp.timeIntervalSince(session.startedAt), 0.5)
        let finalSpeed = fix.speedKmh
        session.samples.append(
            SpeedSample(
                distanceMeters: travelledMeters,
                speedKmh: finalSpeed,
                elapsed: elapsed,
                timestamp: fix.timestamp
            )
        )
        session.lastSampleDistanceMeters = travelledMeters
        session.lastSampleElapsed = elapsed
        self.session = session

        print("[Session] COMPLETE zone=\(session.zone.name) travelled=\(travelledMeters)m elapsed=\(elapsed)s finalSpeed=\(finalSpeed)kmh samples=\(session.samples.count)")

        publishActive(fix: fix, completed: true)

        guard let completedSnapshot = snapshot else { return }

        lastCompletionDate = Date()
        self.session = nil
        approachCandidate = nil

        onMeasurementCompleted?(completedSnapshot)

        let target = completedSnapshot.targetSpeedKmh
        if let average = completedSnapshot.averageSpeedKmh {
            print("[Session] RESULT zone=\(session.zone.name) avg=\(average)kmh target=\(target)kmh")
            if session.zone.isTestCorridor {
                notifications.notifyGPSTestFinished(averageKmh: average)
            } else {
                notifications.notifyFinished(
                    zone: session.zone,
                    averageKmh: average,
                    targetKmh: target
                )
            }

            if settings.hapticsEnabled {
                notifications.playHaptic(.success)
            }
        }

        liveActivity.end(snapshot: completedSnapshot, enabled: settings.liveActivitiesEnabled)

        if session.zone.isTestCorridor {
            location.stopTracking()
            isLiveTracking = false
            isGPSTestMode = false
            testZone = nil
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private func cancelSession(reason: String) {
        print("[Session] CANCELLED reason=\(reason) zone=\(session?.zone.name ?? "none")")
        session = nil
        snapshot = nil
        approachCandidate = nil
        lastError = reason
        liveActivity.endAll()
        if settings.hapticsEnabled {
            notifications.playHaptic(.error)
        }
        if isGPSTestMode {
            stopLiveTracking(showInterruption: false)
        }
    }

    // MARK: - Approach

    private func publishApproach(_ candidate: ZoneCandidate, fix: GPSFix) {
        let zone = candidate.zone
        let distance = max(candidate.distanceToEntryMeters, 0)

        let snapshot = RideSnapshot(
            phase: .approaching,
            zone: zone,
            currentSpeedKmh: fix.speedKmh,
            targetSpeedKmh: settings.targetSpeedKmh(for: zone.speedLimitKmh),
            averageSpeedKmh: nil,
            startSpeedKmh: nil,
            distanceTravelledMeters: 0,
            remainingDistanceMeters: zone.officialLengthMeters,
            distanceToEntryMeters: distance,
            elapsed: 0,
            estimatedRemainingTime: nil,
            predictedAverageKmh: nil,
            recommendedAverageKmh: nil,
            progress: 0,
            accuracyMeters: fix.horizontalAccuracy,
            isDemo: false,
            capturedAt: fix.timestamp,
            samples: []
        )

        self.snapshot = snapshot
        liveActivity.startIfNeeded(snapshot: snapshot, enabled: settings.liveActivitiesEnabled)

        if distance <= 700, lastApproachNotifiedZoneID != zone.id {
            lastApproachNotifiedZoneID = zone.id
            notifications.notifyApproach(zone: zone, distanceMeters: distance)
        }
    }

    private func clearApproachIfNeeded() {
        guard snapshot?.phase == .approaching else { return }
        snapshot = nil
        approachCandidate = nil
        lastApproachNotifiedZoneID = nil
        liveActivity.endAll()
    }

    private func handleAuthorizationChange() {
        if isLiveTracking, location.canStartTracking, !location.isTracking {
            location.setBackgroundUpdatesEnabled(settings.backgroundTrackingEnabled)
            location.startTracking()
        }

        if !location.canStartTracking,
           location.authorizationStatus == .denied {
            lastError = "Atrašanās vietas atļauja liegta. Atver sistēmas iestatījumus."
        }
    }

    // MARK: - Demo callbacks

    private func handleDemo(_ snapshot: RideSnapshot) {
        let wasCompleted = self.snapshot?.phase == .completed
        self.snapshot = snapshot

        switch snapshot.phase {
        case .approaching, .active:
            liveActivity.startIfNeeded(snapshot: snapshot, enabled: settings.liveActivitiesEnabled)
        case .completed:
            isDemoRunning = false
            UIApplication.shared.isIdleTimerDisabled = false
            liveActivity.end(snapshot: snapshot, enabled: settings.liveActivitiesEnabled)
            if !wasCompleted {
                onMeasurementCompleted?(snapshot)
                if settings.hapticsEnabled {
                    notifications.playHaptic(.success)
                }
            }
        }
    }
}
