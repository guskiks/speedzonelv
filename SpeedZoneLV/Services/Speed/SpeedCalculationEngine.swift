import Foundation

/// Pure speed mathematics. Kept free of CoreLocation and UI so it can be
/// unit-tested and reused by the demo simulator, the live ride session and
/// the Live Activity publisher.
enum SpeedCalculationEngine {

    /// Average speed in km/h from a measured distance and elapsed time.
    static func averageSpeedKmh(distanceMeters: Double, duration: TimeInterval) -> Double? {
        guard distanceMeters.isFinite, duration.isFinite,
              distanceMeters > 0, duration > 0.2 else {
            return nil
        }
        return (distanceMeters / duration) * 3.6
    }

    /// Projects the final zone average if the driver keeps the current speed.
    static func predictedAverageKmh(
        distanceTravelledMeters: Double,
        totalDistanceMeters: Double,
        elapsed: TimeInterval,
        currentSpeedKmh: Double
    ) -> Double? {
        guard totalDistanceMeters > 0, elapsed > 0.2,
              distanceTravelledMeters.isFinite, currentSpeedKmh.isFinite else {
            return nil
        }

        let remaining = max(totalDistanceMeters - distanceTravelledMeters, 0)
        let currentMetersPerSecond = max(currentSpeedKmh / 3.6, 2)
        let remainingTime = remaining / currentMetersPerSecond
        let totalTime = elapsed + remainingTime
        guard totalTime > 0 else { return nil }

        return ((distanceTravelledMeters + remaining) / totalTime) * 3.6
    }

    /// Average speed required over the remaining distance so that the final
    /// zone average stays at or below `targetAverageKmh` (minus a safety
    /// margin). Returns 0 when the target is already mathematically lost.
    static func recommendedRemainingAverageKmh(
        distanceTravelledMeters: Double,
        totalDistanceMeters: Double,
        elapsed: TimeInterval,
        targetAverageKmh: Double,
        safetyMarginKmh: Double = 0.5
    ) -> Double? {
        guard totalDistanceMeters > 0, elapsed > 0.2 else { return nil }

        let remaining = totalDistanceMeters - distanceTravelledMeters
        guard remaining > 1 else { return nil }

        let targetMetersPerSecond = max(targetAverageKmh - safetyMarginKmh, 1) / 3.6
        let allowedTotalTime = totalDistanceMeters / targetMetersPerSecond
        let allowedRemainingTime = allowedTotalTime - elapsed

        guard allowedRemainingTime > 0 else { return 0 }
        return (remaining / allowedRemainingTime) * 3.6
    }

    static func estimatedRemainingTime(
        remainingDistanceMeters: Double,
        currentSpeedKmh: Double
    ) -> TimeInterval? {
        guard remainingDistanceMeters.isFinite, currentSpeedKmh.isFinite,
              remainingDistanceMeters >= 0, currentSpeedKmh > 2 else {
            return nil
        }
        return remainingDistanceMeters / (currentSpeedKmh / 3.6)
    }

    /// Haversine distance used when raw GPS samples are integrated.
    static func distanceMeters(from start: Coordinate, to end: Coordinate) -> Double {
        start.distance(to: end)
    }
}
