import Combine
import Foundation

/// Locally added zones. They are stored separately from the shipped database
/// so an app update never overwrites the user's own sections.
@MainActor
final class UserZoneStore: ObservableObject {
    @Published private(set) var zones: [SpeedZone] = []
    @Published private(set) var lastError: String?

    private let fileManager: FileManager
    private let storeURL: URL?

    struct ImportSummary {
        let imported: Int
        let skipped: Int
        let errors: [String]
    }

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let directory = base?.appendingPathComponent("SpeedZoneLV", isDirectory: true)
        self.storeURL = directory?.appendingPathComponent("user_zones.json", isDirectory: false)

        load()
    }

    func add(_ zone: SpeedZone) throws {
        let problems = Self.validationProblems(for: zone)
        guard problems.isEmpty else {
            throw UserZoneError.invalid(problems.joined(separator: " "))
        }
        guard !zones.contains(where: { $0.id == zone.id }) else {
            throw UserZoneError.duplicate(zone.id)
        }

        zones.append(zone)
        zones.sort { $0.road.localizedStandardCompare($1.road) == .orderedAscending }
        try save()
    }

    func update(_ zone: SpeedZone) throws {
        let problems = Self.validationProblems(for: zone)
        guard problems.isEmpty else {
            throw UserZoneError.invalid(problems.joined(separator: " "))
        }
        guard let index = zones.firstIndex(where: { $0.id == zone.id }) else {
            throw UserZoneError.notFound(zone.id)
        }

        zones[index] = zone
        zones.sort { $0.road.localizedStandardCompare($1.road) == .orderedAscending }
        try save()
    }

    func delete(_ zone: SpeedZone) {
        zones.removeAll { $0.id == zone.id }
        try? save()
    }

    func removeAll() {
        zones.removeAll()
        try? save()
    }

    /// Imports either a full `zones_lv.json` document or a bare array of zones.
    /// Invalid entries are skipped and reported instead of aborting the whole
    /// import.
    func importJSON(data: Data) -> ImportSummary {
        var importedZones: [SpeedZone] = []
        var decodeError: String?

        do {
            let document = try JSONDecoder().decode(ZoneDatabaseFile.self, from: data)
            importedZones = document.zones
        } catch {
            do {
                importedZones = try JSONDecoder().decode([SpeedZone].self, from: data)
            } catch {
                decodeError = error.localizedDescription
            }
        }

        if let decodeError {
            lastError = "JSON neizdevās nolasīt: \(decodeError)"
            return ImportSummary(imported: 0, skipped: 0, errors: [lastError ?? "Nezināma JSON kļūda."])
        }

        var errors: [String] = []
        var imported = 0
        var skipped = 0

        for zone in importedZones {
            let problems = Self.validationProblems(for: zone)
            guard problems.isEmpty else {
                skipped += 1
                errors.append("\(zone.road) \(zone.name): \(problems.joined(separator: " "))")
                continue
            }

            if let index = zones.firstIndex(where: { $0.id == zone.id }) {
                zones[index] = zone
            } else {
                zones.append(zone)
            }
            imported += 1
        }

        zones.sort { $0.road.localizedStandardCompare($1.road) == .orderedAscending }

        do {
            try save()
            lastError = nil
        } catch {
            lastError = "Importētās zonas neizdevās saglabāt: \(error.localizedDescription)"
        }

        return ImportSummary(imported: imported, skipped: skipped, errors: errors)
    }

    static func validationProblems(for zone: SpeedZone) -> [String] {
        var problems: [String] = []

        if zone.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            problems.append("Nav zonas ID.")
        }
        if zone.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            problems.append("Nav nosaukuma.")
        }
        if zone.road.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            problems.append("Nav ceļa numura.")
        }
        if !zone.start.isValid || !zone.end.isValid {
            problems.append("Koordinātas nav derīgas.")
        }
        if zone.start == zone.end || zone.start.distance(to: zone.end) < 40 {
            problems.append("Sākums un finišs ir pārāk tuvu.")
        }
        if !(40...30_000).contains(zone.officialLengthMeters) {
            problems.append("Posma garumam jābūt 40 m – 30 km.")
        }
        if !(20...160).contains(zone.speedLimitKmh) {
            problems.append("Ātruma limitam jābūt 20–160 km/h.")
        }
        if zone.source.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            problems.append("Nav datu avota.")
        }
        if zone.verification == .verified,
           zone.lastVerified?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
            problems.append("Pārbaudītai zonai vajag pēdējās pārbaudes datumu.")
        }

        return problems
    }

    private func load() {
        guard let storeURL, fileManager.fileExists(atPath: storeURL.path) else { return }

        do {
            let data = try Data(contentsOf: storeURL)
            zones = try JSONDecoder().decode([SpeedZone].self, from: data)
            lastError = nil
        } catch {
            zones = []
            lastError = "Manuālo zonu failu neizdevās nolasīt: \(error.localizedDescription)"
        }
    }

    private func save() throws {
        guard let storeURL else {
            throw UserZoneError.storageUnavailable
        }

        try fileManager.createDirectory(
            at: storeURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(zones)
        try data.write(to: storeURL, options: .atomic)
        lastError = nil
    }
}

enum UserZoneError: LocalizedError {
    case invalid(String)
    case duplicate(String)
    case notFound(String)
    case storageUnavailable

    var errorDescription: String? {
        switch self {
        case .invalid(let message): return message
        case .duplicate(let id): return "Zona ar ID \(id) jau eksistē."
        case .notFound(let id): return "Zona \(id) nav atrasta."
        case .storageUnavailable: return "Nav pieejama lietotnes datu krātuve."
        }
    }
}
