import Foundation

@MainActor
final class LocalGaugeTargetRepository: GaugeTargetRepository {
    private let fileURL: URL
    private let fileManager: FileManager
    private var targets: [GaugeTarget]

    init(
        targets: [GaugeTarget]? = nil,
        fileManager: FileManager = .default,
        fileURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultFileURL(fileManager: fileManager)

        if let targets {
            self.targets = targets
        } else {
            self.targets = Self.loadTargets(
                fileURL: self.fileURL,
                fileManager: fileManager
            )
        }
    }

    func fetchGaugeTargets() async throws -> [GaugeTarget] {
        targets.sorted { $0.createdAt > $1.createdAt }
    }

    func saveGaugeTarget(_ target: GaugeTarget) async throws -> GaugeTarget {
        targets.removeAll { $0.id == target.id }
        targets.append(target)
        try persistTargets()
        return target
    }

    func updateGaugeTarget(_ target: GaugeTarget) async throws -> GaugeTarget {
        try await saveGaugeTarget(target)
    }

    func deleteGaugeTarget(id: UUID) async throws {
        targets.removeAll { $0.id == id }
        try persistTargets()
    }

    private func persistTargets() throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(targets)
        try data.write(to: fileURL, options: [.atomic])
    }

    private static func loadTargets(
        fileURL: URL,
        fileManager: FileManager
    ) -> [GaugeTarget] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([GaugeTarget].self, from: data)
        } catch {
            return []
        }
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory

        return baseURL
            .appendingPathComponent("KnitGether", isDirectory: true)
            .appendingPathComponent("gauge-targets.json")
    }
}
