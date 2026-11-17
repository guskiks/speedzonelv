import Foundation

/// An official kilometre range that can be used as a starting point for a
/// manually added zone. Templates deliberately contain **no coordinates**:
/// LVC publishes kilometre ranges, not camera endpoint coordinates.
struct ZoneTemplate: Identifiable, Hashable, Sendable {
    let id: String
    let road: String
    let name: String
    let fromKilometer: Double
    let toKilometer: Double
    let suggestedSpeedLimitKmh: Int
    let sourceName: String
    let sourceURL: String?
    let note: String

    var lengthMeters: Double {
        abs(toKilometer - fromKilometer) * 1_000
    }

    var rangeText: String {
        let from = String(format: "%.1f", fromKilometer).replacingOccurrences(of: ".", with: ",")
        let to = String(format: "%.1f", toKilometer).replacingOccurrences(of: ".", with: ",")
        return "\(from)–\(to) km"
    }
}

enum ZoneCatalog {
    static let lvcURL = "https://lvceli.lv/aktuali/25-februari-saks-darboties-jauni-videja-atruma-kontroles-posmi-uz-tallinas-un-liepajas-sosejam"

    /// Official LVC/Sam.gov.lv sections announced for 2026 plus the A7 section
    /// launched in 2023. These are catalog entries, not verified map zones.
    static let officialTemplates: [ZoneTemplate] = [
        ZoneTemplate(
            id: "tpl-a1-vitrupe-svetciems",
            road: "A1",
            name: "Vitrupe–Svētciems",
            fromKilometer: 74.6,
            toKilometer: 81.1,
            suggestedSpeedLimitKmh: 90,
            sourceName: "Latvijas Valsts ceļi",
            sourceURL: lvcURL,
            note: "Oficiālais kilometru diapazons. Koordinātas jāievada manuāli."
        ),
        ZoneTemplate(
            id: "tpl-a9-kagi",
            road: "A9",
            name: "10. km–Kaģi",
            fromKilometer: 9.9,
            toKilometer: 23.1,
            suggestedSpeedLimitKmh: 90,
            sourceName: "Latvijas Valsts ceļi",
            sourceURL: lvcURL,
            note: "Oficiālais kilometru diapazons. Koordinātas jāievada manuāli."
        ),
        ZoneTemplate(
            id: "tpl-a9-blidene-broceni",
            road: "A9",
            name: "Blīdene–Brocēni",
            fromKilometer: 80.0,
            toKilometer: 93.6,
            suggestedSpeedLimitKmh: 90,
            sourceName: "Latvijas Valsts ceļi",
            sourceURL: lvcURL,
            note: "Oficiālais kilometru diapazons. Koordinātas jāievada manuāli."
        ),
        ZoneTemplate(
            id: "tpl-a2-tinuzi",
            road: "A2",
            name: "A2 72,25–77,15 km posms",
            fromKilometer: 72.25,
            toKilometer: 77.15,
            suggestedSpeedLimitKmh: 90,
            sourceName: "Latvijas Valsts ceļi",
            sourceURL: lvcURL,
            note: "Oficiālais kilometru diapazons. Koordinātas jāievada manuāli."
        ),
        ZoneTemplate(
            id: "tpl-a2-94-125",
            road: "A2",
            name: "A2 94,8–125,7 km posms",
            fromKilometer: 94.8,
            toKilometer: 125.7,
            suggestedSpeedLimitKmh: 90,
            sourceName: "Latvijas Valsts ceļi",
            sourceURL: lvcURL,
            note: "Oficiālais kilometru diapazons. Koordinātas jāievada manuāli."
        ),
        ZoneTemplate(
            id: "tpl-a3-stalbe-rubene",
            road: "A3",
            name: "Stalbe–Rubene",
            fromKilometer: 40.1,
            toKilometer: 55.6,
            suggestedSpeedLimitKmh: 90,
            sourceName: "Latvijas Valsts ceļi",
            sourceURL: lvcURL,
            note: "Oficiālais kilometru diapazons. Koordinātas jāievada manuāli."
        ),
        ZoneTemplate(
            id: "tpl-a6-dzelmes-uplejas",
            road: "A6",
            name: "Dzelmes–Uplejas",
            fromKilometer: 66.1,
            toKilometer: 77.0,
            suggestedSpeedLimitKmh: 90,
            sourceName: "Latvijas Valsts ceļi",
            sourceURL: lvcURL,
            note: "Oficiālais kilometru diapazons. Koordinātas jāievada manuāli."
        ),
        ZoneTemplate(
            id: "tpl-a10-tukums",
            road: "A10",
            name: "Tukuma rotācijas apļi",
            fromKilometer: 63.4,
            toKilometer: 68.0,
            suggestedSpeedLimitKmh: 90,
            sourceName: "Latvijas Valsts ceļi",
            sourceURL: lvcURL,
            note: "Oficiālais kilometru diapazons. Koordinātas jāievada manuāli."
        ),
        ZoneTemplate(
            id: "tpl-a4-10-13",
            road: "A4",
            name: "A4 10,1–13,9 km posms",
            fromKilometer: 10.1,
            toKilometer: 13.9,
            suggestedSpeedLimitKmh: 90,
            sourceName: "Latvijas Valsts ceļi",
            sourceURL: lvcURL,
            note: "Oficiālais kilometru diapazons. Koordinātas jāievada manuāli."
        ),
        ZoneTemplate(
            id: "tpl-a4-14-19",
            road: "A4",
            name: "A4 14,5–19,9 km posms",
            fromKilometer: 14.5,
            toKilometer: 19.9,
            suggestedSpeedLimitKmh: 90,
            sourceName: "Latvijas Valsts ceļi",
            sourceURL: lvcURL,
            note: "Oficiālais kilometru diapazons. Koordinātas jāievada manuāli."
        ),
        ZoneTemplate(
            id: "tpl-a5-14-20",
            road: "A5",
            name: "A5 14,2–20,1 km posms",
            fromKilometer: 14.2,
            toKilometer: 20.1,
            suggestedSpeedLimitKmh: 90,
            sourceName: "Latvijas Valsts ceļi",
            sourceURL: lvcURL,
            note: "Oficiālais kilometru diapazons. Koordinātas jāievada manuāli."
        ),
        ZoneTemplate(
            id: "tpl-p80-0-1",
            road: "P80",
            name: "P80 0,5–1,8 km posms",
            fromKilometer: 0.5,
            toKilometer: 1.8,
            suggestedSpeedLimitKmh: 70,
            sourceName: "Latvijas Valsts ceļi",
            sourceURL: lvcURL,
            note: "Oficiālais kilometru diapazons. Pārbaudi vietējo ātruma limitu."
        ),
        ZoneTemplate(
            id: "tpl-p80-40-60",
            road: "P80",
            name: "P80 40,9–60,1 km posms",
            fromKilometer: 40.9,
            toKilometer: 60.1,
            suggestedSpeedLimitKmh: 90,
            sourceName: "Latvijas Valsts ceļi",
            sourceURL: lvcURL,
            note: "Oficiālais kilometru diapazons. Koordinātas jāievada manuāli."
        ),
        ZoneTemplate(
            id: "tpl-a12-61-69",
            road: "A12",
            name: "A12 61,4–69,0 km posms",
            fromKilometer: 61.4,
            toKilometer: 69.0,
            suggestedSpeedLimitKmh: 90,
            sourceName: "Latvijas Valsts ceļi",
            sourceURL: lvcURL,
            note: "Oficiālais kilometru diapazons. Koordinātas jāievada manuāli."
        ),
        ZoneTemplate(
            id: "tpl-a12-106-108",
            road: "A12",
            name: "A12 106,3–108,1 km posms",
            fromKilometer: 106.3,
            toKilometer: 108.1,
            suggestedSpeedLimitKmh: 90,
            sourceName: "Latvijas Valsts ceļi",
            sourceURL: lvcURL,
            note: "Oficiālais kilometru diapazons. Koordinātas jāievada manuāli."
        ),
        ZoneTemplate(
            id: "tpl-p128-13-19",
            road: "P128",
            name: "P128 13,6–19,4 km posms",
            fromKilometer: 13.6,
            toKilometer: 19.4,
            suggestedSpeedLimitKmh: 90,
            sourceName: "Latvijas Valsts ceļi",
            sourceURL: lvcURL,
            note: "Oficiālais kilometru diapazons. Koordinātas jāievada manuāli."
        ),
        ZoneTemplate(
            id: "tpl-a7-tilderi-iecava",
            road: "A7",
            name: "Tilderi–Iecava",
            fromKilometer: 25.3,
            toKilometer: 40.0,
            suggestedSpeedLimitKmh: 90,
            sourceName: "LVC / LSM (2023)",
            sourceURL: "https://eng.lsm.lv/article/economy/transport/27.09.2023-another-set-of-average-speed-cameras-launched-in-latvia.a525529",
            note: "2023. gadā atklātais posms. Koordinātas jāievada manuāli."
        )
    ]
}
