import ActivityKit
import Foundation

/// Shared by the app and the widget extension. ActivityKit matches the
/// attributes type across both targets.
struct SpeedZoneActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phase: String
        var currentSpeedKmh: Double
        var averageSpeedKmh: Double?
        var speedLimitKmh: Int
        var targetSpeedKmh: Int
        var predictedAverageKmh: Double?
        var remainingDistanceMeters: Double
        var distanceToEntryMeters: Double?
        var progress: Double
        var elapsed: TimeInterval
        var accuracyMeters: Double?
        var isDemo: Bool
        var updatedAt: Date
    }

    var zoneID: String
    var zoneName: String
    var road: String
    var directionLabel: String
    var officialLengthMeters: Double
}
