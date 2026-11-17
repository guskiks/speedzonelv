import Foundation

/// A locally stored, completed measurement.
struct TripRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let zoneID: String
    let zoneName: String
    let road: String
    let startedAt: Date
    let endedAt: Date
    let averageSpeedKmh: Double
    let speedLimitKmh: Int
    let distanceMeters: Double
    let isDemo: Bool

    /// Optional so history written by older builds still decodes.
    let targetSpeedKmh: Int?
    let samples: [SpeedSample]?

    var duration: TimeInterval {
        max(endedAt.timeIntervalSince(startedAt), 0)
    }

    var resolvedTargetSpeedKmh: Int {
        targetSpeedKmh ?? speedLimitKmh
    }

    var speedSamples: [SpeedSample] {
        samples ?? []
    }

    var averageBand: SpeedBand {
        SpeedBand(speedKmh: averageSpeedKmh, limitKmh: resolvedTargetSpeedKmh)
    }

    var officialBand: SpeedBand {
        SpeedBand(speedKmh: averageSpeedKmh, limitKmh: speedLimitKmh)
    }

    var metrics: RideMetrics {
        speedSamples.rideMetrics(
            targetKmh: resolvedTargetSpeedKmh,
            officialLimitKmh: speedLimitKmh
        )
    }

    init(
        id: UUID = UUID(),
        zoneID: String,
        zoneName: String,
        road: String,
        startedAt: Date,
        endedAt: Date,
        averageSpeedKmh: Double,
        speedLimitKmh: Int,
        distanceMeters: Double,
        isDemo: Bool,
        targetSpeedKmh: Int? = nil,
        samples: [SpeedSample]? = nil
    ) {
        self.id = id
        self.zoneID = zoneID
        self.zoneName = zoneName
        self.road = road
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.averageSpeedKmh = averageSpeedKmh
        self.speedLimitKmh = speedLimitKmh
        self.distanceMeters = distanceMeters
        self.isDemo = isDemo
        self.targetSpeedKmh = targetSpeedKmh
        self.samples = samples
    }

    init?(snapshot: RideSnapshot) {
        guard
            snapshot.phase == .completed,
            let average = snapshot.averageSpeedKmh,
            average.isFinite
        else {
            return nil
        }

        let end = snapshot.capturedAt
        self.init(
            zoneID: snapshot.zone.id,
            zoneName: snapshot.zone.name,
            road: snapshot.zone.road,
            startedAt: end.addingTimeInterval(-snapshot.elapsed),
            endedAt: end,
            averageSpeedKmh: average,
            speedLimitKmh: snapshot.zone.speedLimitKmh,
            distanceMeters: snapshot.distanceTravelledMeters,
            isDemo: snapshot.isDemo,
            targetSpeedKmh: snapshot.targetSpeedKmh,
            samples: snapshot.samples
        )
    }
}
