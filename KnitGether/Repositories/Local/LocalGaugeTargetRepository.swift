import Foundation

@MainActor
final class LocalGaugeTargetRepository: GaugeTargetRepository {
    private var targets: [GaugeTarget]

    init(targets: [GaugeTarget] = []) {
        self.targets = targets
    }

    func fetchGaugeTargets() async throws -> [GaugeTarget] {
        targets.sorted { $0.createdAt > $1.createdAt }
    }

    func saveGaugeTarget(_ target: GaugeTarget) async throws -> GaugeTarget {
        targets.removeAll { $0.id == target.id }
        targets.append(target)
        return target
    }

    func deleteGaugeTarget(id: UUID) async throws {
        targets.removeAll { $0.id == id }
    }
}
