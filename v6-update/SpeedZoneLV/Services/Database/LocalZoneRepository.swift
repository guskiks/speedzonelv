import Foundation
import Observation

/// Loads the local zone database. The app never invents zones at runtime:
/// an empty file is a valid, honest state.
@MainActor
@Observable
final class LocalZoneRepository {
    private(set) var database: ZoneDatabase

    private let fileManager: FileManager
    private let bundle: Bundle

    init(bundle: Bundle = .main, fileManager: FileManager = .default) {
        self.bundle = bundle
        self.fileManager = fileManager
        self.database = .empty
        prepareDocumentsFolder()
        self.database = loadDatabase()
    }

    /// Re-reads the Documents override, if present, or the bundled file.
    /// Useful after the user drops a new zones_lv.json into the app's
    /// Documents folder via the Files app.
    func reload() {
        database = loadDatabase()
    }

    private func loadDatabase() -> ZoneDatabase {
        let documentsOverride = documentsDatabaseURL()

        if let documentsOverride, fileManager.fileExists(atPath: documentsOverride.path) {
            do {
                let data = try Data(contentsOf: documentsOverride)
                let database = try decode(data: data, origin: "Dokumenti")
                return database
            } catch {
                // Fall back to the bundled database but surface the failure in settings.
                if let fallback = try? loadBundledDatabase() {
                    return ZoneDatabase(
                        schemaVersion: fallback.schemaVersion,
                        countryCode: fallback.countryCode,
                        updatedAt: fallback.updatedAt,
                        disclaimer: fallback.disclaimer,
                        sources: fallback.sources,
                        zones: fallback.zones,
                        origin: fallback.origin,
                        loadError: "Dokumentu datubāzi neizdevās ielādēt: \(error.localizedDescription)"
                    )
                }
                return ZoneDatabase(
                    schemaVersion: 1,
                    countryCode: "LV",
                    updatedAt: "—",
                    disclaimer: "Datubāzi neizdevās ielādēt.",
                    sources: [],
                    zones: [],
                    origin: "Nav ielādēta",
                    loadError: error.localizedDescription
                )
            }
        }

        do {
            return try loadBundledDatabase()
        } catch {
            return ZoneDatabase(
                schemaVersion: 1,
                countryCode: "LV",
                updatedAt: "—",
                disclaimer: "Iebūvēto datubāzi neizdevās ielādēt.",
                sources: [],
                zones: [],
                origin: "Nav ielādēta",
                loadError: error.localizedDescription
            )
        }
    }

    private func loadBundledDatabase() throws -> ZoneDatabase {
        let url = bundle.url(forResource: "zones_lv", withExtension: "json")
            ?? bundle.url(forResource: "zones_lv", withExtension: "json", subdirectory: "Resources")

        guard let url else {
            throw ZoneDatabaseError.missingFile
        }

        let data = try Data(contentsOf: url)
        return try decode(data: data, origin: "Iebūvēta")
    }

    private func decode(data: Data, origin: String) throws -> ZoneDatabase {
        let file: ZoneDatabaseFile
        do {
            file = try JSONDecoder().decode(ZoneDatabaseFile.self, from: data)
        } catch {
            throw ZoneDatabaseError.decoding(error.localizedDescription)
        }

        guard file.schemaVersion == 1 else {
            throw ZoneDatabaseError.unsupportedSchema(file.schemaVersion)
        }

        var identifiers = Set<String>()
        for zone in file.zones {
            guard !identifiers.insert(zone.id).inserted else {
                throw ZoneDatabaseError.duplicateID(zone.id)
            }
            guard zone.start.isValid, zone.end.isValid else {
                throw ZoneDatabaseError.invalidCoordinate(zone.id)
            }
            guard zone.officialLengthMeters > 0 else {
                throw ZoneDatabaseError.invalidLength(zone.id)
            }
            guard (20...160).contains(zone.speedLimitKmh) else {
                throw ZoneDatabaseError.invalidLimit(zone.id)
            }
            guard !zone.source.name.isEmpty else {
                throw ZoneDatabaseError.missingSource(zone.id)
            }
            if zone.verification == .verified, zone.lastVerified == nil {
                throw ZoneDatabaseError.missingVerificationDate(zone.id)
            }
        }

        return ZoneDatabase(
            schemaVersion: file.schemaVersion,
            countryCode: file.countryCode,
            updatedAt: file.updatedAt,
            disclaimer: file.disclaimer,
            sources: file.sources,
            zones: file.zones,
            origin: origin,
            loadError: nil
        )
    }

    private func documentsDatabaseURL() -> URL? {
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documents
            .appendingPathComponent("zones_lv.json", isDirectory: false)
    }

    /// UIFileSharingEnabled exposes the app's Documents folder in Files. iOS
    /// can hide an empty app folder, so create a harmless guide file on first
    /// launch. The bundled database remains the source of truth unless the
    /// user explicitly places a zones_lv.json override here.
    private func prepareDocumentsFolder() {
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let guideURL = documents.appendingPathComponent("SpeedZone-LV-README.txt")
        guard !fileManager.fileExists(atPath: guideURL.path) else { return }

        let text = """
        SpeedZone LV datu mape

        Iebūvētās zonas tiek izmantotas automātiski.
        Šeit ievieto zones_lv.json tikai tad, ja gribi aizvietot iebūvēto datubāzi.
        Lietotnē to var pārlādēt: Iestatījumi → Zonas un datubāze → Pārlādēt datubāzi.
        """

        try? text.write(to: guideURL, atomically: true, encoding: .utf8)
    }
}

enum ZoneDatabaseError: LocalizedError {
    case missingFile
    case decoding(String)
    case unsupportedSchema(Int)
    case duplicateID(String)
    case invalidCoordinate(String)
    case invalidLength(String)
    case invalidLimit(String)
    case missingSource(String)
    case missingVerificationDate(String)

    var errorDescription: String? {
        switch self {
        case .missingFile:
            return "Zonu fails zones_lv.json nav atrasts."
        case .decoding(let message):
            return "JSON kļūda: \(message)"
        case .unsupportedSchema(let version):
            return "Neatbalstīta datubāzes shēma: \(version)."
        case .duplicateID(let id):
            return "Dublikāta zonas ID: \(id)."
        case .invalidCoordinate(let id):
            return "Nederīgas koordinātas zonai \(id)."
        case .invalidLength(let id):
            return "Nederīgs zonas garums zonai \(id)."
        case .invalidLimit(let id):
            return "Nederīgs ātruma limits zonai \(id)."
        case .missingSource(let id):
            return "Zonai \(id) nav datu avota."
        case .missingVerificationDate(let id):
            return "Pārbaudītai zonai \(id) nav pēdējās pārbaudes datuma."
        }
    }
}
