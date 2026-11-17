import Foundation

enum RidePhase: String, Sendable, Equatable {
    case approaching
    case active
    case completed

    var label: String {
        switch self {
        case .approaching: return "Pieejot"
        case .active: return "Aktīva"
        case .completed: return "Pabeigts"
        }
    }
}

/// A single, immutable frame of ride information consumed by the UI and the
/// Live Activity manager.
///
/// The dashboard never calculates speed itself: every value here comes from
/// the speed calculation engine (or the demo simulator that uses the same
/// engine functions).
struct RideSnapshot: Sendable {
    let phase: RidePhase
    let zone: SpeedZone
    let currentSpeedKmh: Double
    let targetSpeedKmh: Int

    /// Average over the measured part of the zone. `nil` while approaching.
    let averageSpeedKmh: Double?
    let startSpeedKmh: Double?

    let distanceTravelledMeters: Double
    let remainingDistanceMeters: Double
    let distanceToEntryMeters: Double?
    let elapsed: TimeInterval
    let estimatedRemainingTime: TimeInterval?

    let predictedAverageKmh: Double?
    let recommendedAverageKmh: Double?

    /// 0...1 along the official zone length.
    let progress: Double
    let accuracyMeters: Double?
    let isDemo: Bool
    let capturedAt: Date

    /// Complete speed trace over the section. Empty while approaching.
    let samples: [SpeedSample]

    var speedLimitKmh: Int { zone.speedLimitKmh }
    var personalOffsetKmh: Int { max(targetSpeedKmh - zone.speedLimitKmh, 0) }

    var currentBand: SpeedBand {
        SpeedBand(speedKmh: currentSpeedKmh, limitKmh: targetSpeedKmh)
    }

    var officialCurrentBand: SpeedBand {
        SpeedBand(speedKmh: currentSpeedKmh, limitKmh: zone.speedLimitKmh)
    }

    var averageBand: SpeedBand {
        SpeedBand(speedKmh: averageSpeedKmh, limitKmh: targetSpeedKmh)
    }

    var officialAverageBand: SpeedBand {
        SpeedBand(speedKmh: averageSpeedKmh, limitKmh: zone.speedLimitKmh)
    }

    var predictedBand: SpeedBand {
        SpeedBand(speedKmh: predictedAverageKmh, limitKmh: targetSpeedKmh)
    }

    var metrics: RideMetrics {
        samples.rideMetrics(
            targetKmh: targetSpeedKmh,
            officialLimitKmh: zone.speedLimitKmh
        )
    }
}
