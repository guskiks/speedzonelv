import Combine
import Foundation

/// Stores completed measurements as a JSON file in Application Support.
/// This remains a local, private history — nothing is uploaded.
@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var records: [TripRecord] = []

    private let storeURL: URL?
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let directory = base?.appendingPathComponent("SpeedZoneLV", isDirectory: true)
        self.storeURL = directory?.appendingPathComponent("history.json", isDirectory: false)

        load()
    }

    func add(_ record: TripRecord) {
        records.insert(record, at: 0)
        save()
    }

    func delete(_ record: TripRecord) {
        records.removeAll { $0.id == record.id }
        save()
    }

    func removeAll() {
        records.removeAll()
        save()
    }

    private func load() {
        guard let storeURL, fileManager.fileExists(atPath: storeURL.path) else { return }

        do {
            let data = try Data(contentsOf: storeURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            records = try decoder.decode([TripRecord].self, from: data)
        } catch {
            // A corrupt history must never prevent the app from starting.
            records = []
        }
    }

    private func save() {
        guard let storeURL else { return }

        do {
            try fileManager.createDirectory(
                at: storeURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(records)
            try data.write(to: storeURL, options: .atomic)
        } catch {
            // Persistence failures are intentionally non-fatal for the user.
            // Phase 7 adds diagnostics and retry handling.
        }
    }
}
