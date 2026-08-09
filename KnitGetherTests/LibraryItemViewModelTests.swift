import Foundation
import Testing
@testable import KnitGether

@MainActor
struct LibraryItemViewModelTests {
    @Test func addYarnSavesTrimmedFormAndReloadsYarns() async throws {
        let repository = FakeLibraryRepository()
        let viewModel = YarnLibraryViewModel(libraryRepository: repository)
        var formData = YarnFormData()
        formData.name = "  Soft Merino DK  "
        formData.brand = "  Sample Yarn Co.  "
        formData.colorway = "  Cloud Gray  "
        formData.weight = "  DK  "
        formData.quantity = 5
        formData.notes = "  Reserved for beanie.  "

        let didSave = await viewModel.addYarn(from: formData)

        #expect(didSave)
        #expect(repository.savedYarns.count == 1)
        #expect(repository.savedYarns[0].name == "Soft Merino DK")
        #expect(repository.savedYarns[0].brand == "Sample Yarn Co.")
        #expect(repository.savedYarns[0].colorway == "Cloud Gray")
        #expect(repository.savedYarns[0].weight == "DK")
        #expect(repository.savedYarns[0].quantity == 5)
        #expect(repository.savedYarns[0].notes == "Reserved for beanie.")
        #expect(viewModel.yarns.count == 1)
    }

    @Test func addYarnRejectsMissingName() async throws {
        let repository = FakeLibraryRepository()
        let viewModel = YarnLibraryViewModel(libraryRepository: repository)
        var formData = YarnFormData()
        formData.quantity = 1

        let didSave = await viewModel.addYarn(from: formData)

        #expect(!didSave)
        #expect(repository.savedYarns.isEmpty)
        #expect(viewModel.errorMessage == "실 이름을 입력해 주세요.")
    }

    @Test func deleteYarnDeletesAndReloadsYarns() async throws {
        let yarn = Self.makeYarn()
        let repository = FakeLibraryRepository(yarns: [yarn])
        let viewModel = YarnLibraryViewModel(libraryRepository: repository)
        await viewModel.loadYarns()

        let didDelete = await viewModel.deleteYarn(yarn)

        #expect(didDelete)
        #expect(repository.deletedYarnIDs == [yarn.id])
        #expect(viewModel.yarns.isEmpty)
    }

    @Test func deleteYarnReturnsFalseAndKeepsExistingYarnsWhenDeleteFails() async throws {
        let yarn = Self.makeYarn()
        let repository = FakeLibraryRepository(yarns: [yarn])
        repository.shouldFailDeleteYarn = true
        let viewModel = YarnLibraryViewModel(libraryRepository: repository)
        await viewModel.loadYarns()

        let didDelete = await viewModel.deleteYarn(yarn)

        #expect(!didDelete)
        #expect(viewModel.yarns.map(\.id) == [yarn.id])
        #expect(viewModel.errorMessage == "실을 삭제하지 못했어요.")
    }

    @Test func deletionPresentationKeepsSelectedDetailWhenDeleteFails() {
        let itemId = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!

        let selectedDetailID = LibraryDeletionPresentation.selectedDetailID(
            afterDeleting: itemId,
            didDelete: false,
            currentDetailID: itemId
        )

        #expect(selectedDetailID == itemId)
    }

    @Test func deletionPresentationClearsSelectedDetailOnlyForMatchingSuccessfulDelete() {
        let itemId = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!
        let otherItemId = UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!

        let matchingSelectedDetailID = LibraryDeletionPresentation.selectedDetailID(
            afterDeleting: itemId,
            didDelete: true,
            currentDetailID: itemId
        )
        let otherSelectedDetailID = LibraryDeletionPresentation.selectedDetailID(
            afterDeleting: itemId,
            didDelete: true,
            currentDetailID: otherItemId
        )

        #expect(matchingSelectedDetailID == nil)
        #expect(otherSelectedDetailID == otherItemId)
    }

    @Test func deletionPresentationClearsPendingDeletionOnlyWhenDeleteSucceeds() {
        #expect(!LibraryDeletionPresentation.shouldClearPendingDeletion(didDelete: false))
        #expect(LibraryDeletionPresentation.shouldClearPendingDeletion(didDelete: true))
    }

    @Test func yarnDetailRowsHideEmptyOptionalMetadataAndKeepQuantity() {
        let yarn = Self.makeYarn(
            brand: "Sample Yarn Co.",
            colorway: nil,
            weight: "DK",
            quantity: 5,
            notes: ""
        )

        let rows = YarnLibraryViewModel.detailRows(for: yarn)

        #expect(rows.map(\.title) == ["브랜드", "굵기", "보유 수량"])
        #expect(rows.map(\.value) == ["Sample Yarn Co.", "DK", "5개"])
    }

    @Test func filteredYarnsMatchesNameBrandColorwayWeightAndNotes() async throws {
        let repository = FakeLibraryRepository(yarns: [
            Self.makeYarn(name: "Soft Merino DK", brand: "Sample Yarn Co.", colorway: "Cloud Gray", weight: "DK", notes: "Reserved for beanie."),
            Self.makeYarn(id: UUID(), name: "Cotton Linen", brand: "Summer Mill", colorway: "Oat", weight: "Sport", notes: "Sleeveless top.")
        ])
        let viewModel = YarnLibraryViewModel(libraryRepository: repository)
        await viewModel.loadYarns()

        viewModel.searchText = "cloud"
        #expect(viewModel.filteredYarns.map(\.name) == ["Soft Merino DK"])

        viewModel.searchText = "summer"
        #expect(viewModel.filteredYarns.map(\.name) == ["Cotton Linen"])

        viewModel.searchText = "top"
        #expect(viewModel.filteredYarns.map(\.name) == ["Cotton Linen"])

        viewModel.searchText = "  "
        #expect(viewModel.filteredYarns.map(\.name) == ["Soft Merino DK", "Cotton Linen"])
    }

    @Test func loadYarnUsagesStoresUsageRecordsAndTotalQuantity() async throws {
        let yarn = Self.makeYarn(quantity: 3)
        let usage = Self.makeYarnUsage(yarnId: yarn.id, quantityUsed: 2)
        let repository = FakeLibraryRepository(yarns: [yarn], yarnUsages: [usage])
        let viewModel = YarnLibraryViewModel(libraryRepository: repository)

        await viewModel.loadYarnUsages(for: yarn)

        #expect(repository.requestedYarnUsageIDs == [yarn.id])
        #expect(viewModel.yarnUsageRecords(for: yarn).map(\.id) == [usage.id])
        #expect(viewModel.totalUsedQuantity(for: yarn) == 2)
    }

    @Test func retryYarnSyncReloadsYarnsAndClearsPendingStatus() async throws {
        let pendingYarn = Self.makeYarn(syncStatus: .pendingUpload)
        let syncedYarn = Self.makeYarn(id: pendingYarn.id, syncStatus: .synced)
        let repository = FakeLibraryRepository(yarns: [pendingYarn])
        repository.yarnFetchResults = [
            [pendingYarn],
            [syncedYarn],
        ]
        let viewModel = YarnLibraryViewModel(libraryRepository: repository)

        await viewModel.loadYarns()
        #expect(viewModel.hasYarnsNeedingSync)

        await viewModel.retrySync()

        #expect(repository.fetchYarnsCallCount == 2)
        #expect(viewModel.yarns.map(\.syncStatus) == [.synced])
        #expect(!viewModel.hasYarnsNeedingSync)
        #expect(!viewModel.isRetryingSync)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func addNeedleSavesTrimmedFormAndReloadsNeedles() async throws {
        let repository = FakeLibraryRepository()
        let viewModel = NeedleLibraryViewModel(libraryRepository: repository)
        var formData = NeedleFormData()
        formData.name = "  Wood Circular Needle  "
        formData.needleType = "  Circular  "
        formData.size = "  5.0 mm  "
        formData.length = "  80 cm  "
        formData.notes = "  Used for cardigan body.  "

        let didSave = await viewModel.addNeedle(from: formData)

        #expect(didSave)
        #expect(repository.savedNeedles.count == 1)
        #expect(repository.savedNeedles[0].name == "Wood Circular Needle")
        #expect(repository.savedNeedles[0].needleType == "Circular")
        #expect(repository.savedNeedles[0].size == "5.0 mm")
        #expect(repository.savedNeedles[0].length == "80 cm")
        #expect(repository.savedNeedles[0].notes == "Used for cardigan body.")
        #expect(viewModel.needles.count == 1)
    }

    @Test func addNeedleRejectsMissingRequiredFields() async throws {
        let repository = FakeLibraryRepository()
        let viewModel = NeedleLibraryViewModel(libraryRepository: repository)
        var formData = NeedleFormData()
        formData.name = "Circular Needle"

        let didSave = await viewModel.addNeedle(from: formData)

        #expect(!didSave)
        #expect(repository.savedNeedles.isEmpty)
        #expect(viewModel.errorMessage == "바늘 이름, 종류, 사이즈를 입력해 주세요.")
    }

    @Test func deleteNeedleDeletesAndReloadsNeedles() async throws {
        let needle = Self.makeNeedle()
        let repository = FakeLibraryRepository(needles: [needle])
        let viewModel = NeedleLibraryViewModel(libraryRepository: repository)
        await viewModel.loadNeedles()

        let didDelete = await viewModel.deleteNeedle(needle)

        #expect(didDelete)
        #expect(repository.deletedNeedleIDs == [needle.id])
        #expect(viewModel.needles.isEmpty)
    }

    @Test func deleteNeedleReturnsFalseAndKeepsExistingNeedlesWhenDeleteFails() async throws {
        let needle = Self.makeNeedle()
        let repository = FakeLibraryRepository(needles: [needle])
        repository.shouldFailDeleteNeedle = true
        let viewModel = NeedleLibraryViewModel(libraryRepository: repository)
        await viewModel.loadNeedles()

        let didDelete = await viewModel.deleteNeedle(needle)

        #expect(!didDelete)
        #expect(viewModel.needles.map(\.id) == [needle.id])
        #expect(viewModel.errorMessage == "바늘을 삭제하지 못했어요.")
    }

    @Test func needleDetailRowsHideEmptyLengthAndKeepRequiredMetadata() {
        let needle = Self.makeNeedle(
            needleType: "Circular",
            size: "5.0 mm",
            length: nil,
            notes: ""
        )

        let rows = NeedleLibraryViewModel.detailRows(for: needle)

        #expect(rows.map(\.title) == ["종류", "사이즈"])
        #expect(rows.map(\.value) == ["Circular", "5.0 mm"])
    }

    @Test func filteredNeedlesMatchesNameTypeSizeLengthAndNotes() async throws {
        let repository = FakeLibraryRepository(needles: [
            Self.makeNeedle(name: "Wood Circular Needle", needleType: "Circular", size: "5.0 mm", length: "80 cm", notes: "Cardigan body."),
            Self.makeNeedle(id: UUID(), name: "Steel DPN", needleType: "DPN", size: "2.75 mm", length: "15 cm", notes: "Sleeves.")
        ])
        let viewModel = NeedleLibraryViewModel(libraryRepository: repository)
        await viewModel.loadNeedles()

        viewModel.searchText = "circular"
        #expect(viewModel.filteredNeedles.map(\.name) == ["Wood Circular Needle"])

        viewModel.searchText = "2.75"
        #expect(viewModel.filteredNeedles.map(\.name) == ["Steel DPN"])

        viewModel.searchText = "sleeves"
        #expect(viewModel.filteredNeedles.map(\.name) == ["Steel DPN"])

        viewModel.searchText = "  "
        #expect(viewModel.filteredNeedles.map(\.name) == ["Wood Circular Needle", "Steel DPN"])
    }

    @Test func retryNeedleSyncReloadsNeedlesAndClearsPendingStatus() async throws {
        let pendingNeedle = Self.makeNeedle(syncStatus: .pendingUpload)
        let syncedNeedle = Self.makeNeedle(id: pendingNeedle.id, syncStatus: .synced)
        let repository = FakeLibraryRepository(needles: [pendingNeedle])
        repository.needleFetchResults = [
            [pendingNeedle],
            [syncedNeedle],
        ]
        let viewModel = NeedleLibraryViewModel(libraryRepository: repository)

        await viewModel.loadNeedles()
        #expect(viewModel.hasNeedlesNeedingSync)

        await viewModel.retrySync()

        #expect(repository.fetchNeedlesCallCount == 2)
        #expect(viewModel.needles.map(\.syncStatus) == [.synced])
        #expect(!viewModel.hasNeedlesNeedingSync)
        #expect(!viewModel.isRetryingSync)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func addToolSavesTrimmedFormAndReloadsTools() async throws {
        let repository = FakeLibraryRepository()
        let viewModel = ToolLibraryViewModel(libraryRepository: repository)
        var formData = ToolFormData()
        formData.name = "  Locking Marker Set  "
        formData.type = "  Marker  "
        formData.link = "  example.com/marker  "
        formData.memo = "  For raglan increases.  "

        let didSave = await viewModel.addTool(from: formData)

        #expect(didSave)
        #expect(repository.savedTools.count == 1)
        #expect(repository.savedTools[0].name == "Locking Marker Set")
        #expect(repository.savedTools[0].type == "Marker")
        #expect(repository.savedTools[0].link == "example.com/marker")
        #expect(repository.savedTools[0].memo == "For raglan increases.")
        #expect(viewModel.tools.count == 1)
    }

    @Test func addToolRejectsMissingRequiredFields() async throws {
        let repository = FakeLibraryRepository()
        let viewModel = ToolLibraryViewModel(libraryRepository: repository)
        var formData = ToolFormData()
        formData.name = "Marker"

        let didSave = await viewModel.addTool(from: formData)

        #expect(!didSave)
        #expect(repository.savedTools.isEmpty)
        #expect(viewModel.errorMessage == "도구 이름과 종류를 입력해 주세요.")
    }

    @Test func deleteToolDeletesAndReloadsTools() async throws {
        let tool = Self.makeTool()
        let repository = FakeLibraryRepository(tools: [tool])
        let viewModel = ToolLibraryViewModel(libraryRepository: repository)
        await viewModel.loadTools()

        let didDelete = await viewModel.deleteTool(tool)

        #expect(didDelete)
        #expect(repository.deletedToolIDs == [tool.id])
        #expect(viewModel.tools.isEmpty)
    }

    @Test func filteredToolsMatchesNameTypeLinkAndMemo() async throws {
        let repository = FakeLibraryRepository(tools: [
            Self.makeTool(name: "Locking Marker Set", type: "Marker", link: "example.com/marker", memo: "Raglan increases."),
            Self.makeTool(id: UUID(), name: "Measuring Tape", type: "Measure", link: nil, memo: "Gauge checks.")
        ])
        let viewModel = ToolLibraryViewModel(libraryRepository: repository)
        await viewModel.loadTools()

        viewModel.searchText = "marker"
        #expect(viewModel.filteredTools.map(\.name) == ["Locking Marker Set"])

        viewModel.searchText = "gauge"
        #expect(viewModel.filteredTools.map(\.name) == ["Measuring Tape"])

        viewModel.searchText = "example"
        #expect(viewModel.filteredTools.map(\.name) == ["Locking Marker Set"])

        viewModel.searchText = "  "
        #expect(viewModel.filteredTools.map(\.name) == ["Locking Marker Set", "Measuring Tape"])
    }

    @Test func retryToolSyncReloadsToolsAndClearsPendingStatus() async throws {
        let pendingTool = Self.makeTool(syncStatus: .pendingUpload)
        let syncedTool = Self.makeTool(id: pendingTool.id, syncStatus: .synced)
        let repository = FakeLibraryRepository(tools: [pendingTool])
        repository.toolFetchResults = [
            [pendingTool],
            [syncedTool],
        ]
        let viewModel = ToolLibraryViewModel(libraryRepository: repository)

        await viewModel.loadTools()
        #expect(viewModel.hasToolsNeedingSync)

        await viewModel.retrySync()

        #expect(repository.fetchToolsCallCount == 2)
        #expect(viewModel.tools.map(\.syncStatus) == [.synced])
        #expect(!viewModel.hasToolsNeedingSync)
        #expect(!viewModel.isRetryingSync)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func toolDetailRowsHideEmptyLinkAndKeepUsageCount() {
        let tool = Self.makeTool(link: nil, usageCount: 2)

        let rows = ToolLibraryViewModel.detailRows(for: tool)

        #expect(rows.map(\.title) == ["종류", "연결 프로젝트"])
        #expect(rows.map(\.value) == ["Marker", "2개"])
    }

    private static func makeYarn(
        id: UUID = UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!,
        name: String = "Soft Merino DK",
        brand: String? = "Sample Yarn Co.",
        colorway: String? = "Cloud Gray",
        weight: String? = "DK",
        quantity: Int = 5,
        notes: String = "Reserved for beanie.",
        syncStatus: SyncStatus = .synced
    ) -> Yarn {
        Yarn(
            id: id,
            ownerId: "user-a",
            name: name,
            brand: brand,
            colorway: colorway,
            weight: weight,
            quantity: quantity,
            notes: notes,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }

    private static func makeNeedle(
        id: UUID = UUID(uuidString: "dddddddd-dddd-4ddd-8ddd-dddddddddddd")!,
        name: String = "Wood Circular Needle",
        needleType: String = "Circular",
        size: String = "5.0 mm",
        length: String? = "80 cm",
        notes: String = "Used for cardigan body.",
        syncStatus: SyncStatus = .synced
    ) -> Needle {
        Needle(
            id: id,
            ownerId: "user-a",
            name: name,
            needleType: needleType,
            size: size,
            length: length,
            notes: notes,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }

    private static func makeYarnUsage(
        id: UUID = UUID(uuidString: "99999999-9999-4999-8999-999999999999")!,
        yarnId: UUID,
        quantityUsed: Int = 2
    ) -> ProjectYarnUsage {
        let now = Date(timeIntervalSince1970: 1_783_731_600)
        return ProjectYarnUsage(
            id: id,
            ownerId: "user-a",
            projectId: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            projectNameSnapshot: "Favorite Cardigan",
            yarnId: yarnId,
            yarnNameSnapshot: "Soft Merino DK",
            quantityUsed: quantityUsed,
            memo: "Sleeve swatch",
            usedAt: now,
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: .synced
        )
    }

    private static func makeTool(
        id: UUID = UUID(uuidString: "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee")!,
        name: String = "Locking Marker Set",
        type: String = "Marker",
        link: String? = "example.com/marker",
        memo: String = "For raglan increases.",
        usageCount: Int = 0,
        syncStatus: SyncStatus = .synced
    ) -> ToolItem {
        let now = Date(timeIntervalSince1970: 1_783_731_600)
        return ToolItem(
            id: id,
            ownerId: "user-a",
            name: name,
            type: type,
            link: link,
            memo: memo,
            usageCount: usageCount,
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: syncStatus
        )
    }
}

@MainActor
private final class FakeLibraryRepository: LibraryRepository {
    var yarns: [Yarn]
    var needles: [Needle]
    var tools: [ToolItem]
    var yarnFetchResults: [[Yarn]] = []
    var needleFetchResults: [[Needle]] = []
    var toolFetchResults: [[ToolItem]] = []
    var fetchYarnsCallCount = 0
    var fetchNeedlesCallCount = 0
    var fetchToolsCallCount = 0
    var savedYarns: [Yarn] = []
    var savedNeedles: [Needle] = []
    var savedTools: [ToolItem] = []
    var yarnUsages: [ProjectYarnUsage]
    var deletedYarnIDs: [UUID] = []
    var deletedNeedleIDs: [UUID] = []
    var deletedToolIDs: [UUID] = []
    var requestedYarnUsageIDs: [UUID] = []
    var shouldFailDeleteYarn = false
    var shouldFailDeleteNeedle = false
    var shouldFailDeleteTool = false

    init(
        yarns: [Yarn] = [],
        needles: [Needle] = [],
        tools: [ToolItem] = [],
        yarnUsages: [ProjectYarnUsage] = []
    ) {
        self.yarns = yarns
        self.needles = needles
        self.tools = tools
        self.yarnUsages = yarnUsages
    }

    func fetchYarns() async throws -> [Yarn] {
        fetchYarnsCallCount += 1
        if !yarnFetchResults.isEmpty {
            yarns = yarnFetchResults.removeFirst()
        }
        return yarns
    }

    func saveYarn(_ yarn: Yarn) async throws {
        savedYarns.append(yarn)
        if let index = yarns.firstIndex(where: { $0.id == yarn.id }) {
            yarns[index] = yarn
        } else {
            yarns.append(yarn)
        }
    }

    func deleteYarn(id: UUID) async throws {
        if shouldFailDeleteYarn {
            throw NSError(domain: "FakeLibraryRepository", code: 1)
        }

        deletedYarnIDs.append(id)
        yarns.removeAll { $0.id == id }
    }

    func fetchYarnUsages(forProjectId projectId: UUID) async throws -> [ProjectYarnUsage] {
        yarnUsages.filter { $0.projectId == projectId }
    }

    func fetchYarnUsages(forYarnId yarnId: UUID) async throws -> [ProjectYarnUsage] {
        requestedYarnUsageIDs.append(yarnId)
        return yarnUsages.filter { $0.yarnId == yarnId }
    }

    func recordYarnUsage(_ usage: ProjectYarnUsage) async throws -> ProjectYarnUsage {
        usage
    }

    func updateYarnUsage(_ usage: ProjectYarnUsage) async throws -> ProjectYarnUsage {
        usage
    }

    func deleteYarnUsage(_ usage: ProjectYarnUsage) async throws {
    }

    func fetchNeedles() async throws -> [Needle] {
        fetchNeedlesCallCount += 1
        if !needleFetchResults.isEmpty {
            needles = needleFetchResults.removeFirst()
        }
        return needles
    }

    func saveNeedle(_ needle: Needle) async throws {
        savedNeedles.append(needle)
        if let index = needles.firstIndex(where: { $0.id == needle.id }) {
            needles[index] = needle
        } else {
            needles.append(needle)
        }
    }

    func deleteNeedle(id: UUID) async throws {
        if shouldFailDeleteNeedle {
            throw NSError(domain: "FakeLibraryRepository", code: 1)
        }

        deletedNeedleIDs.append(id)
        needles.removeAll { $0.id == id }
    }

    func fetchTools() async throws -> [ToolItem] {
        fetchToolsCallCount += 1
        if !toolFetchResults.isEmpty {
            tools = toolFetchResults.removeFirst()
        }
        return tools
    }

    func saveTool(_ tool: ToolItem) async throws {
        savedTools.append(tool)
        if let index = tools.firstIndex(where: { $0.id == tool.id }) {
            tools[index] = tool
        } else {
            tools.append(tool)
        }
    }

    func deleteTool(id: UUID) async throws {
        if shouldFailDeleteTool {
            throw NSError(domain: "FakeLibraryRepository", code: 1)
        }

        deletedToolIDs.append(id)
        tools.removeAll { $0.id == id }
    }

    func fetchTools(forProjectId projectId: UUID) async throws -> [ToolItem] {
        []
    }

    func linkTool(_ tool: ToolItem, toProjectId projectId: UUID) async throws -> ToolItem {
        tool
    }

    func fetchYarnLinks(forProjectId projectId: UUID) async throws -> [ProjectYarnLink] {
        return []
    }

    func linkYarn(_ yarn: Yarn, toProjectId projectId: UUID) async throws -> ProjectYarnLink {
        fatalError("Not needed in this test")
    }

    func unlinkYarn(yarnId: UUID, fromProjectId projectId: UUID) async throws {
        fatalError("Not needed in this test")
    }

    func fetchNeedleLinks(forProjectId projectId: UUID) async throws -> [ProjectNeedleLink] {
        return []
    }

    func linkNeedle(_ needle: Needle, toProjectId projectId: UUID) async throws -> ProjectNeedleLink {
        fatalError("Not needed in this test")
    }

    func unlinkNeedle(needleId: UUID, fromProjectId projectId: UUID) async throws {
        fatalError("Not needed in this test")
    }

    func unlinkTool(_ tool: ToolItem, fromProjectId projectId: UUID) async throws {
    }
}
