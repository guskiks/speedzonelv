import CoreLocation
import Foundation
import Observation

/// A validated, value-type snapshot of one CoreLocation sample. Keeping the
/// session code free of `CLLocation` makes filtering and persistence simpler.
struct GPSFix: Sendable {
    let coordinate: Coordinate
    let horizontalAccuracy: Double
    let speedMetersPerSecond: Double
    let courseDegrees: Double
    let courseAccuracyDegrees: Double
    let speedAccuracyMetersPerSecond: Double
    let timestamp: Date

    init(location: CLLocation) {
        coordinate = Coordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        horizontalAccuracy = location.horizontalAccuracy
        speedMetersPerSecond = location.speed
        courseDegrees = location.course
        courseAccuracyDegrees = location.courseAccuracy
        speedAccuracyMetersPerSecond = location.speedAccuracy
        timestamp = location.timestamp
    }

    var speedKmh: Double {
        guard speedMetersPerSecond.isFinite, speedMetersPerSecond > 0 else { return 0 }
        return speedMetersPerSecond * 3.6
    }

    var hasValidCourse: Bool {
        courseDegrees.isFinite && courseDegrees >= 0 && courseDegrees <= 360
    }
}

/// Rejects bad accuracy, stale, future-dated and physically impossible samples.
/// Small stationary jitter is accepted for the speed display but does not move
/// the anchor point used for distance checks.
struct LocationFilter {
    var maximumHorizontalAccuracy: Double = 60
    var maximumAge: TimeInterval = 8
    var minimumMovementMeters: Double = 1.5
    var maximumPlausibleSpeedMetersPerSecond: Double = 85

    private var anchor: GPSFix?

    mutating func accepts(_ fix: GPSFix, now: Date = Date()) -> Bool {
        guard fix.coordinate.isValid else { return false }
        guard fix.horizontalAccuracy >= 0, fix.horizontalAccuracy <= maximumHorizontalAccuracy else { return false }
        guard fix.timestamp <= now.addingTimeInterval(2) else { return false }
        guard now.timeIntervalSince(fix.timestamp) <= maximumAge else { return false }
        guard fix.speedMetersPerSecond.isFinite, fix.speedMetersPerSecond >= -0.5 else { return false }

        guard let anchor else {
            self.anchor = fix
            return true
        }

        let delta = fix.timestamp.timeIntervalSince(anchor.timestamp)
        guard delta > 0 else { return false }

        let distance = anchor.coordinate.distance(to: fix.coordinate)
        if distance < minimumMovementMeters {
            return true
        }

        let impliedSpeed = distance / delta
        guard impliedSpeed <= maximumPlausibleSpeedMetersPerSecond else { return false }

        self.anchor = fix
        return true
    }

    mutating func reset() {
        anchor = nil
    }
}

@MainActor
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var accuracyAuthorization: CLAccuracyAuthorization
    private(set) var latestFix: GPSFix?
    private(set) var lastFixAt: Date?
    private(set) var isTracking = false
    private(set) var lastError: String?
    private(set) var isLocationServicesEnabled: Bool
    private(set) var backgroundUpdatesEnabled = false

    var onFix: ((GPSFix) -> Void)?
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?
    var onError: ((String) -> Void)?

    private let manager: CLLocationManager
    private var filter = LocationFilter()
    private var isHighAccuracyMode = true
    private let backgroundSessionKey = "speedzone.backgroundSessionRequested"

    override init() {
        let manager = CLLocationManager()
        self.manager = manager
        self.authorizationStatus = manager.authorizationStatus
        self.accuracyAuthorization = manager.accuracyAuthorization
        self.isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()

        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 3
        manager.activityType = .automotiveNavigation
        manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = false
        manager.showsBackgroundLocationIndicator = false

        // iOS may relaunch an app after an OS-terminated significant-location
        // event. This does not bypass the user's force-quit action, but it
        // lets an already-authorized background session recover after normal
        // memory termination or reboot-related relaunch.
        if UserDefaults.standard.bool(forKey: backgroundSessionKey),
           authorizationStatus == .authorizedAlways {
            isTracking = true
            backgroundUpdatesEnabled = true
            manager.allowsBackgroundLocationUpdates = true
            manager.startMonitoringSignificantLocationChanges()
            setHighAccuracyMode(false)
        }
    }

    /// Uses a lighter GPS profile while looking for the next zone and returns
    /// to navigation accuracy for approach and active measurements. This does
    /// not stop location updates, so the next zone can still be detected.
    func setHighAccuracyMode(_ enabled: Bool) {
        isHighAccuracyMode = enabled
        if enabled {
            manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            manager.distanceFilter = 3
            filter.maximumHorizontalAccuracy = 60
        } else {
            manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            manager.distanceFilter = 40
            filter.maximumHorizontalAccuracy = 150
        }
    }

    /// Applies the "keep tracking in background" preference. iOS still
    /// requires "Always" authorization for updates while the app is suspended.
    func setBackgroundUpdatesEnabled(_ enabled: Bool) {
        backgroundUpdatesEnabled = enabled
        manager.allowsBackgroundLocationUpdates = enabled
        manager.showsBackgroundLocationIndicator = enabled
        if enabled, isTracking {
            UserDefaults.standard.set(true, forKey: backgroundSessionKey)
            manager.startMonitoringSignificantLocationChanges()
        } else if !enabled {
            UserDefaults.standard.set(false, forKey: backgroundSessionKey)
            manager.stopMonitoringSignificantLocationChanges()
        }
    }

    var canStartTracking: Bool {
        isLocationServicesEnabled
            && (authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways)
    }

    var hasFullAccuracy: Bool {
        accuracyAuthorization == .fullAccuracy
    }

    var currentSpeedKmh: Double {
        latestFix?.speedKmh ?? 0
    }

    func requestWhenInUseAuthorization() {
        guard authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestWhenInUseAuthorization()
            return
        }
        manager.requestAlwaysAuthorization()
    }

    func startTracking() {
        refreshAuthorizationStatus()

        guard isLocationServicesEnabled else {
            reportError("Atrašanās vietas pakalpojumi ierīcē ir izslēgti.")
            return
        }

        switch authorizationStatus {
        case .notDetermined:
            requestWhenInUseAuthorization()
            return
        case .authorizedAlways, .authorizedWhenInUse:
            break
        case .denied, .restricted:
            reportError("Atrašanās vietas atļauja nav piešķirta.")
            return
        @unknown default:
            reportError("Nezināms atrašanās vietas atļaujas statuss.")
            return
        }

        isTracking = true
        lastError = nil
        filter.reset()
        UserDefaults.standard.set(true, forKey: backgroundSessionKey)
        setHighAccuracyMode(false)
        if backgroundUpdatesEnabled {
            manager.startMonitoringSignificantLocationChanges()
        }
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        isTracking = false
        UserDefaults.standard.set(false, forKey: backgroundSessionKey)
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
        filter.reset()
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = manager.authorizationStatus
        accuracyAuthorization = manager.accuracyAuthorization
        isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()
    }

    private func handle(_ fixes: [GPSFix]) {
        guard isTracking else { return }

        var acceptedAny = false
        for fix in fixes.sorted(by: { $0.timestamp < $1.timestamp }) {
            guard filter.accepts(fix) else { continue }
            acceptedAny = true
            latestFix = fix
            lastFixAt = fix.timestamp
            lastError = nil
            onFix?(fix)
        }

        if acceptedAny {
            lastError = nil
        }
    }

    private func handleAuthorizationChange(status: CLAuthorizationStatus, accuracy: CLAccuracyAuthorization) {
        authorizationStatus = status
        accuracyAuthorization = accuracy
        isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()

        if isTracking {
            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                manager.startUpdatingLocation()
            case .denied, .restricted:
                stopTracking()
                reportError("Atrašanās vietas atļauja tika liegta. Mērījums apturēts.")
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }

        onAuthorizationChange?(status)
    }

    private func reportError(_ message: String) {
        lastError = message
        onError?(message)
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        let accuracy = manager.accuracyAuthorization
        Task { @MainActor [weak self] in
            self?.handleAuthorizationChange(status: status, accuracy: accuracy)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let fixes = locations.map(GPSFix.init(location:))
        guard !fixes.isEmpty else { return }
        Task { @MainActor [weak self] in
            self?.handle(fixes)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let code = (error as? CLError)?.code
        guard code != .locationUnknown else { return }
        let message = error.localizedDescription
        Task { @MainActor [weak self] in
            self?.reportError("GPS kļūda: \(message)")
        }
    }
}
