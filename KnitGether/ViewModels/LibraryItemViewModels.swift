//
//  LibraryItemViewModels.swift
//  KnitGether
//
//  Created by Codex on 7/9/26.
//

import Combine
import Foundation

struct LibraryItemDetailRow: Equatable {
    let title: String
    let value: String
    let systemImage: String
}

enum LibraryDeletionPresentation {
    static func selectedDetailID(
        afterDeleting deletedID: UUID,
        didDelete: Bool,
        currentDetailID: UUID?
    ) -> UUID? {
        guard didDelete, currentDetailID == deletedID else {
            return currentDetailID
        }

        return nil
    }

    static func shouldClearPendingDeletion(didDelete: Bool) -> Bool {
        didDelete
    }
}

struct YarnFormData {
    var name = ""
    var brand = ""
    var colorway = ""
    var weight = ""
    var quantity = 1
    var notes = ""

    init() {
    }

    init(yarn: Yarn) {
        name = yarn.name
        brand = yarn.brand ?? ""
        colorway = yarn.colorway ?? ""
        weight = yarn.weight ?? ""
        quantity = yarn.quantity
        notes = yarn.notes
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedBrand: String? {
        nullableTrimmed(brand)
    }

    var trimmedColorway: String? {
        nullableTrimmed(colorway)
    }

    var trimmedWeight: String? {
        nullableTrimmed(weight)
    }

    var trimmedNotes: String {
        notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        !trimmedName.isEmpty && quantity >= 0
    }

    private func nullableTrimmed(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct NeedleFormData {
    var name = ""
    var needleType = ""
    var size = ""
    var length = ""
    var notes = ""

    init() {
    }

    init(needle: Needle) {
        name = needle.name
        needleType = needle.needleType
        size = needle.size
        length = needle.length ?? ""
        notes = needle.notes
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedNeedleType: String {
        needleType.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedSize: String {
        size.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedLength: String? {
        let trimmed = length.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var trimmedNotes: String {
        notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        !trimmedName.isEmpty && !trimmedNeedleType.isEmpty && !trimmedSize.isEmpty
    }

    /// 표기 통일용 표준 바늘 사이즈. 자유 입력의 편차(5.00mm 등)를 줄이기 위한 퀵픽 목록이다.
    static let standardSizes: [String] = [
        "2.0mm", "2.25mm", "2.5mm", "2.75mm", "3.0mm", "3.25mm", "3.5mm", "3.75mm",
        "4.0mm", "4.5mm", "5.0mm", "5.5mm", "6.0mm", "6.5mm", "7.0mm", "8.0mm",
        "9.0mm", "10.0mm", "12.0mm", "15.0mm"
    ]
}

struct ToolFormData {
    var name = ""
    var type = ""
    var link = ""
    var memo = ""

    init() {
    }

    init(tool: ToolItem) {
        name = tool.name
        type = tool.type
        link = tool.link ?? ""
        memo = tool.memo
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedType: String {
        type.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedLink: String? {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var trimmedMemo: String {
        memo.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        !trimmedName.isEmpty && !trimmedType.isEmpty
    }
}

@MainActor
final class YarnLibraryViewModel: ObservableObject {
    @Published private(set) var yarns: [Yarn] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var yarnUsagesByYarnID: [UUID: [ProjectYarnUsage]] = [:]
    @Published private(set) var isRetryingSync = false
    @Published var searchText = ""

    private let libraryRepository: any LibraryRepository

    init(libraryRepository: any LibraryRepository) {
        self.libraryRepository = libraryRepository
    }

    var filteredYarns: [Yarn] {
        Self.filteredYarns(yarns, matching: searchText)
    }

    var hasYarnsNeedingSync: Bool {
        yarns.contains { $0.syncStatus.needsSync }
    }

    func loadYarns() async {
        do {
            yarns = try await libraryRepository.fetchYarns()
            errorMessage = nil
        } catch {
            errorMessage = "실 창고를 불러오지 못했어요."
        }
    }

    func retrySync() async {
        guard !isRetryingSync else {
            return
        }

        isRetryingSync = true
        await loadYarns()
        isRetryingSync = false
    }

    func loadYarnUsages(for yarn: Yarn) async {
        do {
            yarnUsagesByYarnID[yarn.id] = try await libraryRepository.fetchYarnUsages(forYarnId: yarn.id)
            errorMessage = nil
        } catch {
            errorMessage = "실 사용 내역을 불러오지 못했어요."
        }
    }

    func yarnUsageRecords(for yarn: Yarn) -> [ProjectYarnUsage] {
        yarnUsagesByYarnID[yarn.id] ?? []
    }

    func totalUsedQuantity(for yarn: Yarn) -> Int {
        yarnUsageRecords(for: yarn).reduce(0) { $0 + $1.quantityUsed }
    }

    func addYarn(from formData: YarnFormData) async -> Bool {
        await saveYarn(from: formData, existingYarn: nil)
    }

    func updateYarn(_ yarn: Yarn, from formData: YarnFormData) async -> Bool {
        await saveYarn(from: formData, existingYarn: yarn)
    }

    @discardableResult
    func deleteYarn(_ yarn: Yarn) async -> Bool {
        do {
            try await libraryRepository.deleteYarn(id: yarn.id)
            yarns = try await libraryRepository.fetchYarns()
            errorMessage = nil
            return true
        } catch {
            errorMessage = "실을 삭제하지 못했어요."
            return false
        }
    }

    private func saveYarn(from formData: YarnFormData, existingYarn: Yarn?) async -> Bool {
        guard formData.canSave else {
            errorMessage = "실 이름을 입력해 주세요."
            return false
        }

        let now = Date()
        let yarn = Yarn(
            id: existingYarn?.id ?? UUID(),
            ownerId: existingYarn?.ownerId ?? SampleData.ownerId,
            name: formData.trimmedName,
            brand: formData.trimmedBrand,
            colorway: formData.trimmedColorway,
            weight: formData.trimmedWeight,
            quantity: formData.quantity,
            notes: formData.trimmedNotes,
            createdAt: existingYarn?.createdAt ?? now,
            updatedAt: now,
            deletedAt: existingYarn?.deletedAt,
            syncStatus: existingYarn?.syncStatus ?? .localOnly
        )

        do {
            try await libraryRepository.saveYarn(yarn)
            yarns = try await libraryRepository.fetchYarns()
            errorMessage = nil
            return true
        } catch {
            errorMessage = "실을 저장하지 못했어요."
            return false
        }
    }

    static func filteredYarns(_ yarns: [Yarn], matching searchText: String) -> [Yarn] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return yarns
        }

        return yarns.filter { yarn in
            yarn.name.localizedCaseInsensitiveContains(query)
                || yarn.brand?.localizedCaseInsensitiveContains(query) == true
                || yarn.colorway?.localizedCaseInsensitiveContains(query) == true
                || yarn.weight?.localizedCaseInsensitiveContains(query) == true
                || yarn.notes.localizedCaseInsensitiveContains(query)
        }
    }

    static func detailRows(for yarn: Yarn) -> [LibraryItemDetailRow] {
        [
            detailRow(title: "브랜드", value: yarn.brand, systemImage: "tag"),
            detailRow(title: "색상", value: yarn.colorway, systemImage: "paintpalette"),
            detailRow(title: "굵기", value: yarn.weight, systemImage: "scalemass"),
            LibraryItemDetailRow(title: "보유 수량", value: "\(yarn.quantity)개", systemImage: "number")
        ]
        .compactMap { $0 }
    }

    private static func detailRow(title: String, value: String?, systemImage: String) -> LibraryItemDetailRow? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }

        return LibraryItemDetailRow(title: title, value: trimmed, systemImage: systemImage)
    }
}

@MainActor
final class NeedleLibraryViewModel: ObservableObject {
    @Published private(set) var needles: [Needle] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var isRetryingSync = false
    @Published var searchText = ""

    private let libraryRepository: any LibraryRepository

    init(libraryRepository: any LibraryRepository) {
        self.libraryRepository = libraryRepository
    }

    var filteredNeedles: [Needle] {
        Self.filteredNeedles(needles, matching: searchText)
    }

    var hasNeedlesNeedingSync: Bool {
        needles.contains { $0.syncStatus.needsSync }
    }

    func loadNeedles() async {
        do {
            needles = try await libraryRepository.fetchNeedles()
            errorMessage = nil
        } catch {
            errorMessage = "바늘 창고를 불러오지 못했어요."
        }
    }

    func retrySync() async {
        guard !isRetryingSync else {
            return
        }

        isRetryingSync = true
        await loadNeedles()
        isRetryingSync = false
    }

    func addNeedle(from formData: NeedleFormData) async -> Bool {
        await saveNeedle(from: formData, existingNeedle: nil)
    }

    func updateNeedle(_ needle: Needle, from formData: NeedleFormData) async -> Bool {
        await saveNeedle(from: formData, existingNeedle: needle)
    }

    @discardableResult
    func deleteNeedle(_ needle: Needle) async -> Bool {
        do {
            try await libraryRepository.deleteNeedle(id: needle.id)
            needles = try await libraryRepository.fetchNeedles()
            errorMessage = nil
            return true
        } catch {
            errorMessage = "바늘을 삭제하지 못했어요."
            return false
        }
    }

    private func saveNeedle(from formData: NeedleFormData, existingNeedle: Needle?) async -> Bool {
        guard formData.canSave else {
            errorMessage = "바늘 이름, 종류, 사이즈를 입력해 주세요."
            return false
        }

        let now = Date()
        let needle = Needle(
            id: existingNeedle?.id ?? UUID(),
            ownerId: existingNeedle?.ownerId ?? SampleData.ownerId,
            name: formData.trimmedName,
            needleType: formData.trimmedNeedleType,
            size: formData.trimmedSize,
            length: formData.trimmedLength,
            notes: formData.trimmedNotes,
            createdAt: existingNeedle?.createdAt ?? now,
            updatedAt: now,
            deletedAt: existingNeedle?.deletedAt,
            syncStatus: existingNeedle?.syncStatus ?? .localOnly
        )

        do {
            try await libraryRepository.saveNeedle(needle)
            needles = try await libraryRepository.fetchNeedles()
            errorMessage = nil
            return true
        } catch {
            errorMessage = "바늘을 저장하지 못했어요."
            return false
        }
    }

    static func filteredNeedles(_ needles: [Needle], matching searchText: String) -> [Needle] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return needles
        }

        return needles.filter { needle in
            needle.name.localizedCaseInsensitiveContains(query)
                || needle.needleType.localizedCaseInsensitiveContains(query)
                || needle.size.localizedCaseInsensitiveContains(query)
                || needle.length?.localizedCaseInsensitiveContains(query) == true
                || needle.notes.localizedCaseInsensitiveContains(query)
        }
    }

    static func detailRows(for needle: Needle) -> [LibraryItemDetailRow] {
        [
            LibraryItemDetailRow(title: "종류", value: needle.needleType, systemImage: "square.grid.2x2"),
            LibraryItemDetailRow(title: "사이즈", value: needle.size, systemImage: "ruler"),
            detailRow(title: "길이", value: needle.length, systemImage: "arrow.left.and.right")
        ]
        .compactMap { $0 }
    }

    private static func detailRow(title: String, value: String?, systemImage: String) -> LibraryItemDetailRow? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }

        return LibraryItemDetailRow(title: title, value: trimmed, systemImage: systemImage)
    }
}

@MainActor
final class ToolLibraryViewModel: ObservableObject {
    @Published private(set) var tools: [ToolItem] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var isRetryingSync = false
    @Published var searchText = ""

    private let libraryRepository: any LibraryRepository

    init(libraryRepository: any LibraryRepository) {
        self.libraryRepository = libraryRepository
    }

    var filteredTools: [ToolItem] {
        Self.filteredTools(tools, matching: searchText)
    }

    var hasToolsNeedingSync: Bool {
        tools.contains { $0.syncStatus.needsSync }
    }

    func loadTools() async {
        do {
            tools = try await libraryRepository.fetchTools()
            errorMessage = nil
        } catch {
            errorMessage = "도구 창고를 불러오지 못했어요."
        }
    }

    func retrySync() async {
        guard !isRetryingSync else {
            return
        }

        isRetryingSync = true
        await loadTools()
        isRetryingSync = false
    }

    func addTool(from formData: ToolFormData) async -> Bool {
        await saveTool(from: formData, existingTool: nil)
    }

    func updateTool(_ tool: ToolItem, from formData: ToolFormData) async -> Bool {
        await saveTool(from: formData, existingTool: tool)
    }

    @discardableResult
    func deleteTool(_ tool: ToolItem) async -> Bool {
        do {
            try await libraryRepository.deleteTool(id: tool.id)
            tools = try await libraryRepository.fetchTools()
            errorMessage = nil
            return true
        } catch {
            errorMessage = "도구를 삭제하지 못했어요."
            return false
        }
    }

    private func saveTool(from formData: ToolFormData, existingTool: ToolItem?) async -> Bool {
        guard formData.canSave else {
            errorMessage = "도구 이름과 종류를 입력해 주세요."
            return false
        }

        let now = Date()
        let tool = ToolItem(
            id: existingTool?.id ?? UUID(),
            ownerId: existingTool?.ownerId ?? SampleData.ownerId,
            name: formData.trimmedName,
            type: formData.trimmedType,
            link: formData.trimmedLink,
            memo: formData.trimmedMemo,
            usageCount: existingTool?.usageCount ?? 0,
            createdAt: existingTool?.createdAt ?? now,
            updatedAt: now,
            deletedAt: existingTool?.deletedAt,
            syncStatus: existingTool?.syncStatus ?? .localOnly
        )

        do {
            try await libraryRepository.saveTool(tool)
            tools = try await libraryRepository.fetchTools()
            errorMessage = nil
            return true
        } catch {
            errorMessage = "도구를 저장하지 못했어요."
            return false
        }
    }

    static func filteredTools(_ tools: [ToolItem], matching searchText: String) -> [ToolItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return tools
        }

        return tools.filter { tool in
            tool.name.localizedCaseInsensitiveContains(query)
                || tool.type.localizedCaseInsensitiveContains(query)
                || tool.link?.localizedCaseInsensitiveContains(query) == true
                || tool.memo.localizedCaseInsensitiveContains(query)
        }
    }

    static func detailRows(for tool: ToolItem) -> [LibraryItemDetailRow] {
        [
            LibraryItemDetailRow(title: "종류", value: tool.type, systemImage: "wrench.and.screwdriver"),
            detailRow(title: "링크", value: tool.link, systemImage: "link"),
            LibraryItemDetailRow(title: "연결 프로젝트", value: "\(tool.usageCount)개", systemImage: "folder")
        ]
        .compactMap { $0 }
    }

    private static func detailRow(title: String, value: String?, systemImage: String) -> LibraryItemDetailRow? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }

        return LibraryItemDetailRow(title: title, value: trimmed, systemImage: systemImage)
    }
}
