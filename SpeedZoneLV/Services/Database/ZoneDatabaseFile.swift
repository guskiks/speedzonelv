import Foundation

/// Raw JSON representation of the zone file. The file is stored in the app
/// bundle and may be overridden by a newer copy in Documents so the database
/// can be updated without rebuilding the app.
struct ZoneDatabaseFile: Decodable {
    let schemaVersion: Int
    let countryCode: String
    let updatedAt: String
    let disclaimer: String
    let sources: [ZoneSource]
    let zones: [SpeedZone]
}

/// Runtime form of the zone database with load diagnostics for the settings UI.
struct ZoneDatabase {
    let schemaVersion: Int
    let countryCode: String
    let updatedAt: String
    let disclaimer: String
    let sources: [ZoneSource]
    let zones: [SpeedZone]
    let origin: String
    let loadError: String?

    var verifiedZones: [SpeedZone] {
        zones.filter { $0.verification == .verified }
    }

    static let empty = ZoneDatabase(
        schemaVersion: 1,
        countryCode: "LV",
        updatedAt: "—",
        disclaimer: "Datubāze nav ielādēta.",
        sources: [],
        zones: [],
        origin: "Nav ielādēta",
        loadError: nil
    )
}
