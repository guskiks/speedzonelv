import Foundation

/// Direction in which a zone is enforced, expressed relative to the stored
/// start/end coordinates. Detection code must never assume forward travel.
enum ZoneDirection: String, Codable, CaseIterable, Sendable {
    case startToEnd
    case endToStart

    var shortLabel: String {
        switch self {
        case .startToEnd: return "Sākums → finišs"
        case .endToStart: return "Finišs → sākums"
        }
    }
}

/// The provenance of a zone. Only `.verified` zones may be used by the
/// production detection engine. `.demo` zones are synthetic UI fixtures.
enum ZoneVerification: String, Codable, Sendable {
    case verified
    case unverified
    case demo

    var label: String {
        switch self {
        case .verified: return "Pārbaudīta"
        case .unverified: return "Nepārbaudīta"
        case .demo: return "Demonstrācija"
        }
    }
}

struct ZoneSource: Codable, Hashable, Sendable {
    let name: String
    let url: String?
    let license: String?
    let retrievedAt: String?
}

/// A Latvian average-speed control section.
///
/// Important: this type describes a zone in the local database. It does not
/// claim that the zone is enforced today; `verification` and `lastVerified`
/// carry that information.
struct SpeedZone: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let road: String
    let direction: ZoneDirection
    let directionDescription: String?
    let start: Coordinate
    let end: Coordinate
    let officialLengthMeters: Double
    let speedLimitKmh: Int
    let source: ZoneSource
    let verification: ZoneVerification
    let lastVerified: String?
    let notes: String?

    var entry: Coordinate {
        direction == .startToEnd ? start : end
    }

    var exit: Coordinate {
        direction == .startToEnd ? end : start
    }

    var lengthKilometers: Double {
        officialLengthMeters / 1_000
    }

    var directionLabel: String {
        directionDescription ?? direction.shortLabel
    }

    var isDemo: Bool {
        verification == .demo
    }

    var isTestCorridor: Bool {
        road == "TEST"
    }

    /// A clearly labelled synthetic zone used only by the interactive demo.
    /// The coordinates intentionally do not describe a real enforcement site.
    static let demo = SpeedZone(
        id: "demo-LV-001",
        name: "Demo kontroles posms",
        road: "DEMO",
        direction: .startToEnd,
        directionDescription: "Demo brauciena virzienā",
        start: Coordinate(latitude: 56.5000, longitude: 24.5000),
        end: Coordinate(latitude: 56.5108, longitude: 24.5000),
        officialLengthMeters: 1_200,
        speedLimitKmh: 90,
        source: ZoneSource(
            name: "Iebūvēts demo scenārijs",
            url: nil,
            license: nil,
            retrievedAt: nil
        ),
        verification: .demo,
        lastVerified: nil,
        notes: "Nav reāla vidējā ātruma kontroles zona. Koordinātas nav saistītas ar konkrētu ceļu."
    )

    /// Creates an explicitly labelled 1 km test corridor from the driver's
    /// current position in the direction of travel. It is never written to the
    /// production database and is only used to test detection, notifications,
    /// background tracking and Live Activities.
    static func gpsTest(from start: Coordinate, headingDegrees: Double) -> SpeedZone {
        let bearing = headingDegrees.isFinite ? headingDegrees : 0
        let end = GeoMath.offset(from: start, bearingDegrees: bearing, distanceMeters: 1_000)
        return SpeedZone(
            id: "gps-test-\(Int(Date().timeIntervalSince1970))",
            name: "GPS testa koridors (1 km)",
            road: "TEST",
            direction: .startToEnd,
            directionDescription: "Pašreizējais braukšanas virziens",
            start: start,
            end: end,
            officialLengthMeters: 1_000,
            speedLimitKmh: 90,
            source: ZoneSource(
                name: "Lietotnē ģenerēts GPS tests",
                url: nil,
                license: nil,
                retrievedAt: nil
            ),
            verification: .demo,
            lastVerified: nil,
            notes: "Nav oficiāla zona. Tests sākas tavā pašreizējā pozīcijā un beidzas pēc 1 km. Izmanto tikai funkciju pārbaudei."
        )
    }
}
