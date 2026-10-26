import Foundation

/// Device-local drafts are separate from the sync queue and never trigger a server save.
/// An owner is required so an anonymous/cached project cannot expose another account's draft.
@MainActor
final class ProjectMemoDraftStore {
    static let shared = ProjectMemoDraftStore()
    private let directory: URL

    init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ProjectMemoDrafts", isDirectory: true)
    }

    func text(ownerId: String?, projectId: UUID) -> String? {
        guard let url = fileURL(ownerId: ownerId, projectId: projectId) else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    func update(_ text: String, savedText: String, ownerId: String?, projectId: UUID) throws {
        guard let url = fileURL(ownerId: ownerId, projectId: projectId) else { return }
        if text == savedText {
            try remove(ownerId: ownerId, projectId: projectId)
        } else {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try Data(text.utf8).write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        }
    }

    func remove(ownerId: String?, projectId: UUID) throws {
        guard let url = fileURL(ownerId: ownerId, projectId: projectId),
              FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    private func fileURL(ownerId: String?, projectId: UUID) -> URL? {
        guard let ownerId, !ownerId.isEmpty else { return nil }
        let owner = Data(ownerId.utf8).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "+", with: "-")
        return directory.appendingPathComponent("\(owner).\(projectId.uuidString).txt")
    }
}
