import Foundation

/// One accepted GPS sample inside a measured section. Samples are stored in
/// trip history so the dashboard and history can draw the complete speed curve
/// over the official section length.
struct SpeedSample: Codable, Hashable, Sendable {
    let distanceMeters: Double
    let speedKmh: Double
    let elapsed: TimeInterval
    let timestamp: Date

    init(
        distanceMeters: Double,
        speedKmh: Double,
        elapsed: TimeInterval,
        timestamp: Date
    ) {
        self.distanceMeters = max(distanceMeters.isFinite ? distanceMeters : 0, 0)
        self.speedKmh = max(speedKmh.isFinite ? speedKmh : 0, 0)
        self.elapsed = max(elapsed.isFinite ? elapsed : 0, 0)
        self.timestamp = timestamp
    }
}

/// Presentation-only statistics calculated from the speed trace. None of these
/// values replace the official average measured between the section endpoints.
struct RideMetrics: Sendable {
    let maximumSpeedKmh: Double?
    let minimumSpeedKmh: Double?
    let overTargetFraction: Double?
    let overOfficialLimitFraction: Double?
    let sampleCount: Int

    init(samples: [SpeedSample], targetKmh: Int, officialLimitKmh: Int) {
        let moving = samples.filter { $0.speedKmh >= 3 }

        self.sampleCount = moving.count
        self.maximumSpeedKmh = moving.map(\.speedKmh).max()
        self.minimumSpeedKmh = moving.map(\.speedKmh).min()

        guard !moving.isEmpty else {
            self.overTargetFraction = nil
            self.overOfficialLimitFraction = nil
            return
        }

        let target = Double(targetKmh)
        let official = Double(officialLimitKmh)
        self.overTargetFraction = Double(moving.filter { $0.speedKmh > target + 0.5 }.count) / Double(moving.count)
        self.overOfficialLimitFraction = Double(moving.filter { $0.speedKmh > official + 0.5 }.count) / Double(moving.count)
    }

    var hasData: Bool {
        sampleCount > 0
    }
}

extension Array where Element == SpeedSample {
    func rideMetrics(targetKmh: Int, officialLimitKmh: Int) -> RideMetrics {
        RideMetrics(
            samples: self,
            targetKmh: targetKmh,
            officialLimitKmh: officialLimitKmh
        )
    }
}
