import Foundation

protocol GaugeTargetRepository {
    func fetchGaugeTargets() async throws -> [GaugeTarget]
    func saveGaugeTarget(_ target: GaugeTarget) async throws -> GaugeTarget
    func updateGaugeTarget(_ target: GaugeTarget) async throws -> GaugeTarget
    func deleteGaugeTarget(id: UUID) async throws
}
