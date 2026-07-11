import Foundation

@MainActor
final class OfflineFirstLibraryRepository: LibraryRepository {
    private let local: LocalLibraryRepository
    private let remote: any LibraryRepository

    init(
        local: LocalLibraryRepository,
        remote: any LibraryRepository
    ) {
        self.local = local
        self.remote = remote
    }

    func fetchYarns() async throws -> [Yarn] {
        await syncPendingChanges()

        do {
            let remoteYarns = try await remote.fetchYarns()
            await local.cacheSyncedYarns(remoteYarns)
        } catch {
            guard shouldDefer(error) else {
                throw error
            }
        }

        return try await local.fetchYarns()
    }

    func saveYarn(_ yarn: Yarn) async throws {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let localYarn = copyYarn(
            yarn,
            syncStatus: localSaveSyncStatus(for: yarn.syncStatus)
        )
        try await local.saveYarn(localYarn)

        let uploadYarn = copyYarn(
            yarn,
            syncStatus: uploadSyncStatus(for: yarn.syncStatus)
        )

        do {
            try await remote.saveYarn(uploadYarn)
            try await cacheServerYarnIfAvailable(fallback: uploadYarn)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    func deleteYarn(id: UUID) async throws {
        let existingYarn = try await local.fetchYarns().first { $0.id == id }
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        try await local.deleteYarn(id: id)

        guard existingYarn?.syncStatus != .localOnly else {
            await local.markYarnDeletionSynced(id: id)
            return
        }

        do {
            try await remote.deleteYarn(id: id)
            await local.markYarnDeletionSynced(id: id)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    func fetchYarnUsages(forProjectId projectId: UUID) async throws -> [ProjectYarnUsage] {
        await syncPendingChanges()

        do {
            let remoteUsages = try await remote.fetchYarnUsages(forProjectId: projectId)
            await local.cacheSyncedYarnUsages(remoteUsages)
        } catch {
            guard shouldDefer(error) else {
                throw error
            }
        }

        return try await local.fetchYarnUsages(forProjectId: projectId)
    }

    func fetchYarnUsages(forYarnId yarnId: UUID) async throws -> [ProjectYarnUsage] {
        await syncPendingChanges()

        do {
            let remoteUsages = try await remote.fetchYarnUsages(forYarnId: yarnId)
            await local.cacheSyncedYarnUsages(remoteUsages)
        } catch {
            guard shouldDefer(error) else {
                throw error
            }
        }

        return try await local.fetchYarnUsages(forYarnId: yarnId)
    }

    func recordYarnUsage(_ usage: ProjectYarnUsage) async throws -> ProjectYarnUsage {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let localUsage = usage.copy(syncStatus: .localOnly)
        let savedUsage = try await local.recordYarnUsage(localUsage)

        do {
            let syncedUsage = try await remote.recordYarnUsage(usage.copy(syncStatus: .localOnly))
            try await local.markYarnUsageSynced(syncedUsage)
            return syncedUsage
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)

            return savedUsage
        }
    }

    func updateYarnUsage(_ usage: ProjectYarnUsage) async throws -> ProjectYarnUsage {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let localUsage = usage.copy(
            syncStatus: usage.syncStatus == .synced ? .pendingUpload : usage.syncStatus
        )
        let savedUsage = try await local.updateYarnUsage(localUsage)

        do {
            let syncedUsage = try await remote.updateYarnUsage(usage)
            try await local.markYarnUsageSynced(syncedUsage)
            return syncedUsage
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)

            return savedUsage
        }
    }

    func deleteYarnUsage(_ usage: ProjectYarnUsage) async throws {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        try await local.deleteYarnUsage(usage)

        guard usage.syncStatus != .localOnly else {
            await local.markYarnUsageDeletionSynced(id: usage.id)
            return
        }

        do {
            try await remote.deleteYarnUsage(usage)
            await local.markYarnUsageDeletionSynced(id: usage.id)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    func fetchNeedles() async throws -> [Needle] {
        await syncPendingChanges()

        do {
            let remoteNeedles = try await remote.fetchNeedles()
            await local.cacheSyncedNeedles(remoteNeedles)
        } catch {
            guard shouldDefer(error) else {
                throw error
            }
        }

        return try await local.fetchNeedles()
    }

    func saveNeedle(_ needle: Needle) async throws {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let localNeedle = copyNeedle(
            needle,
            syncStatus: localSaveSyncStatus(for: needle.syncStatus)
        )
        try await local.saveNeedle(localNeedle)

        let uploadNeedle = copyNeedle(
            needle,
            syncStatus: uploadSyncStatus(for: needle.syncStatus)
        )

        do {
            try await remote.saveNeedle(uploadNeedle)
            try await cacheServerNeedleIfAvailable(fallback: uploadNeedle)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    func deleteNeedle(id: UUID) async throws {
        let existingNeedle = try await local.fetchNeedles().first { $0.id == id }
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        try await local.deleteNeedle(id: id)

        guard existingNeedle?.syncStatus != .localOnly else {
            await local.markNeedleDeletionSynced(id: id)
            return
        }

        do {
            try await remote.deleteNeedle(id: id)
            await local.markNeedleDeletionSynced(id: id)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    func fetchTools() async throws -> [ToolItem] {
        await syncPendingChanges()

        do {
            let remoteTools = try await remote.fetchTools()
            await local.cacheSyncedTools(remoteTools)
        } catch {
            guard shouldDefer(error) else {
                throw error
            }
        }

        return try await local.fetchTools()
    }

    func saveTool(_ tool: ToolItem) async throws {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let localTool = copyTool(
            tool,
            syncStatus: localSaveSyncStatus(for: tool.syncStatus)
        )
        try await local.saveTool(localTool)

        let uploadTool = copyTool(
            tool,
            syncStatus: uploadSyncStatus(for: tool.syncStatus)
        )

        do {
            try await remote.saveTool(uploadTool)
            try await cacheServerToolIfAvailable(fallback: uploadTool)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    func deleteTool(id: UUID) async throws {
        let existingTool = try await local.fetchTools().first { $0.id == id }
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        try await local.deleteTool(id: id)

        guard existingTool?.syncStatus != .localOnly else {
            await local.markToolDeletionSynced(id: id)
            return
        }

        do {
            try await remote.deleteTool(id: id)
            await local.markToolDeletionSynced(id: id)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    func fetchTools(forProjectId projectId: UUID) async throws -> [ToolItem] {
        await syncPendingChanges()

        do {
            let remoteTools = try await remote.fetchTools(forProjectId: projectId)
            await local.cacheSyncedProjectTools(remoteTools, forProjectId: projectId)
        } catch {
            guard shouldDefer(error) else {
                throw error
            }
        }

        return try await local.fetchTools(forProjectId: projectId)
    }

    func linkTool(_ tool: ToolItem, toProjectId projectId: UUID) async throws -> ToolItem {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        let localTool = try await local.linkTool(tool, toProjectId: projectId)

        do {
            let syncedTool = try await remote.linkTool(tool, toProjectId: projectId)
            try await local.markProjectToolLinkedSynced(projectId: projectId, tool: syncedTool)
            return syncedTool
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)

            return localTool
        }
    }

    func unlinkTool(_ tool: ToolItem, fromProjectId projectId: UUID) async throws {
        let rollbackSnapshot = await local.makeRollbackSnapshot()
        try await local.unlinkTool(tool, fromProjectId: projectId)

        do {
            try await remote.unlinkTool(tool, fromProjectId: projectId)
            await local.markProjectToolUnlinkSynced(projectId: projectId, toolId: tool.id)
        } catch {
            try await rollbackLocalChangeIfRejected(rollbackSnapshot, after: error)
        }
    }

    private func syncPendingChanges() async {
        for yarn in await local.pendingYarnsForSync() {
            do {
                if yarn.syncStatus == .pendingDelete {
                    try await remote.deleteYarn(id: yarn.id)
                    await local.markYarnDeletionSynced(id: yarn.id)
                } else {
                    let uploadYarn = copyYarn(
                        yarn,
                        syncStatus: yarn.syncStatus == .pendingUpload ? .synced : .localOnly
                    )
                    try await remote.saveYarn(uploadYarn)
                    try await cacheServerYarnIfAvailable(fallback: uploadYarn)
                }
            } catch {
                await resolveRejectedPendingYarn(yarn, after: error)
            }
        }

        for needle in await local.pendingNeedlesForSync() {
            do {
                if needle.syncStatus == .pendingDelete {
                    try await remote.deleteNeedle(id: needle.id)
                    await local.markNeedleDeletionSynced(id: needle.id)
                } else {
                    let uploadNeedle = copyNeedle(
                        needle,
                        syncStatus: needle.syncStatus == .pendingUpload ? .synced : .localOnly
                    )
                    try await remote.saveNeedle(uploadNeedle)
                    try await cacheServerNeedleIfAvailable(fallback: uploadNeedle)
                }
            } catch {
                await resolveRejectedPendingNeedle(needle, after: error)
            }
        }

        for tool in await local.pendingToolsForSync() {
            do {
                if tool.syncStatus == .pendingDelete {
                    try await remote.deleteTool(id: tool.id)
                    await local.markToolDeletionSynced(id: tool.id)
                } else {
                    let uploadTool = copyTool(
                        tool,
                        syncStatus: tool.syncStatus == .pendingUpload ? .synced : .localOnly
                    )
                    try await remote.saveTool(uploadTool)
                    try await cacheServerToolIfAvailable(fallback: uploadTool)
                }
            } catch {
                await resolveRejectedPendingTool(tool, after: error)
            }
        }

        for link in await local.pendingProjectToolLinksForSync() {
            do {
                guard let tool = try await local.fetchTools().first(where: { $0.id == link.toolId }) else {
                    continue
                }

                if link.syncStatus == .pendingDelete {
                    try await remote.unlinkTool(tool, fromProjectId: link.projectId)
                    await local.markProjectToolUnlinkSynced(projectId: link.projectId, toolId: link.toolId)
                } else {
                    let syncedTool = try await remote.linkTool(tool, toProjectId: link.projectId)
                    try await local.markProjectToolLinkedSynced(projectId: link.projectId, tool: syncedTool)
                }
            } catch {
                await resolveRejectedPendingProjectToolLink(link, after: error)
            }
        }

        for usage in await local.pendingYarnUsagesForSync() {
            do {
                if usage.syncStatus == .pendingDelete {
                    try await remote.deleteYarnUsage(usage)
                    await local.markYarnUsageDeletionSynced(id: usage.id)
                } else if usage.syncStatus == .pendingUpload {
                    let syncedUsage = try await remote.updateYarnUsage(usage)
                    try await local.markYarnUsageSynced(syncedUsage)
                } else {
                    let syncedUsage = try await remote.recordYarnUsage(usage)
                    try await local.markYarnUsageSynced(syncedUsage)
                }
            } catch {
                await resolveRejectedPendingYarnUsage(usage, after: error)
            }
        }
    }

    private func resolveRejectedPendingYarn(
        _ yarn: Yarn,
        after error: Error
    ) async {
        guard !shouldDefer(error) else {
            return
        }

        switch yarn.syncStatus {
        case .localOnly, .pendingDelete:
            await local.discardYarn(id: yarn.id)
        case .pendingUpload:
            do {
                if let serverYarn = try await remote.fetchYarns().first(where: { $0.id == yarn.id }) {
                    try await local.markYarnSynced(serverYarn)
                } else {
                    await local.discardYarn(id: yarn.id)
                }
            } catch {
                if !shouldDefer(error) {
                    await local.discardYarn(id: yarn.id)
                }
            }
        default:
            break
        }
    }

    private func resolveRejectedPendingNeedle(
        _ needle: Needle,
        after error: Error
    ) async {
        guard !shouldDefer(error) else {
            return
        }

        switch needle.syncStatus {
        case .localOnly, .pendingDelete:
            await local.discardNeedle(id: needle.id)
        case .pendingUpload:
            do {
                if let serverNeedle = try await remote.fetchNeedles().first(where: { $0.id == needle.id }) {
                    try await local.markNeedleSynced(serverNeedle)
                } else {
                    await local.discardNeedle(id: needle.id)
                }
            } catch {
                if !shouldDefer(error) {
                    await local.discardNeedle(id: needle.id)
                }
            }
        default:
            break
        }
    }

    private func resolveRejectedPendingTool(
        _ tool: ToolItem,
        after error: Error
    ) async {
        guard !shouldDefer(error) else {
            return
        }

        switch tool.syncStatus {
        case .localOnly, .pendingDelete:
            await local.discardTool(id: tool.id)
        case .pendingUpload:
            do {
                if let serverTool = try await remote.fetchTools().first(where: { $0.id == tool.id }) {
                    try await local.markToolSynced(serverTool)
                } else {
                    await local.discardTool(id: tool.id)
                }
            } catch {
                if !shouldDefer(error) {
                    await local.discardTool(id: tool.id)
                }
            }
        default:
            break
        }
    }

    private func resolveRejectedPendingProjectToolLink(
        _ link: ProjectToolLink,
        after error: Error
    ) async {
        guard !shouldDefer(error) else {
            return
        }

        switch link.syncStatus {
        case .localOnly, .pendingDelete:
            await local.discardProjectToolLink(projectId: link.projectId, toolId: link.toolId)
        case .pendingUpload:
            do {
                if let serverTool = try await remote.fetchTools(forProjectId: link.projectId).first(where: { $0.id == link.toolId }) {
                    try await local.markProjectToolLinkedSynced(projectId: link.projectId, tool: serverTool)
                } else {
                    await local.discardProjectToolLink(projectId: link.projectId, toolId: link.toolId)
                }
            } catch {
                if !shouldDefer(error) {
                    await local.discardProjectToolLink(projectId: link.projectId, toolId: link.toolId)
                }
            }
        default:
            break
        }
    }

    private func resolveRejectedPendingYarnUsage(
        _ usage: ProjectYarnUsage,
        after error: Error
    ) async {
        guard !shouldDefer(error) else {
            return
        }

        switch usage.syncStatus {
        case .localOnly, .pendingDelete:
            await local.discardYarnUsage(id: usage.id)
        case .pendingUpload:
            do {
                if let serverUsage = try await remote.fetchYarnUsages(forProjectId: usage.projectId).first(where: { $0.id == usage.id }) {
                    try await local.markYarnUsageSynced(serverUsage)
                } else {
                    await local.discardYarnUsage(id: usage.id)
                }
            } catch {
                if !shouldDefer(error) {
                    await local.discardYarnUsage(id: usage.id)
                }
            }
        default:
            break
        }
    }

    private func cacheServerYarnIfAvailable(fallback yarn: Yarn) async throws {
        do {
            if let serverYarn = try await remote.fetchYarns().first(where: { $0.id == yarn.id }) {
                try await local.markYarnSynced(serverYarn)
                return
            }
        } catch {
            // Saving already succeeded. Keep the local cache usable even if the follow-up read fails.
        }

        try await local.markYarnSynced(yarn)
    }

    private func cacheServerNeedleIfAvailable(fallback needle: Needle) async throws {
        do {
            if let serverNeedle = try await remote.fetchNeedles().first(where: { $0.id == needle.id }) {
                try await local.markNeedleSynced(serverNeedle)
                return
            }
        } catch {
            // Saving already succeeded. Keep the local cache usable even if the follow-up read fails.
        }

        try await local.markNeedleSynced(needle)
    }

    private func cacheServerToolIfAvailable(fallback tool: ToolItem) async throws {
        do {
            if let serverTool = try await remote.fetchTools().first(where: { $0.id == tool.id }) {
                try await local.markToolSynced(serverTool)
                return
            }
        } catch {
            // Saving already succeeded. Keep the local cache usable even if the follow-up read fails.
        }

        try await local.markToolSynced(tool)
    }

    private func shouldDefer(_ error: Error) -> Bool {
        if error is URLError {
            return true
        }

        if let apiError = error as? APIError,
           let statusCode = apiError.statusCode {
            return statusCode >= 500
        }

        return false
    }

    private func rollbackLocalChangeIfRejected(
        _ snapshot: LocalLibraryRollbackSnapshot,
        after error: Error
    ) async throws {
        guard !shouldDefer(error) else {
            return
        }

        try? await local.restoreRollbackSnapshot(snapshot)
        throw error
    }

    private func localSaveSyncStatus(for syncStatus: SyncStatus) -> SyncStatus {
        switch syncStatus {
        case .synced, .pendingUpload:
            return .pendingUpload
        default:
            return .localOnly
        }
    }

    private func uploadSyncStatus(for syncStatus: SyncStatus) -> SyncStatus {
        syncStatus == .pendingUpload ? .synced : syncStatus
    }

    private func copyYarn(_ yarn: Yarn, syncStatus: SyncStatus) -> Yarn {
        Yarn(
            id: yarn.id,
            ownerId: yarn.ownerId,
            name: yarn.name,
            brand: yarn.brand,
            colorway: yarn.colorway,
            weight: yarn.weight,
            quantity: yarn.quantity,
            notes: yarn.notes,
            createdAt: yarn.createdAt,
            updatedAt: yarn.updatedAt,
            deletedAt: yarn.deletedAt,
            syncStatus: syncStatus
        )
    }

    private func copyNeedle(_ needle: Needle, syncStatus: SyncStatus) -> Needle {
        Needle(
            id: needle.id,
            ownerId: needle.ownerId,
            name: needle.name,
            needleType: needle.needleType,
            size: needle.size,
            length: needle.length,
            notes: needle.notes,
            createdAt: needle.createdAt,
            updatedAt: needle.updatedAt,
            deletedAt: needle.deletedAt,
            syncStatus: syncStatus
        )
    }

    private func copyTool(_ tool: ToolItem, syncStatus: SyncStatus) -> ToolItem {
        ToolItem(
            id: tool.id,
            ownerId: tool.ownerId,
            name: tool.name,
            type: tool.type,
            link: tool.link,
            memo: tool.memo,
            usageCount: tool.usageCount,
            createdAt: tool.createdAt,
            updatedAt: tool.updatedAt,
            deletedAt: tool.deletedAt,
            syncStatus: syncStatus
        )
    }
}
