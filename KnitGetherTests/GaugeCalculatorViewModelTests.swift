import Foundation
import Testing
@testable import KnitGether

@MainActor
struct GaugeCalculatorViewModelTests {
    @Test func saveCurrentGaugeRecordPersistsCalculationWithProjectSnapshot() async throws {
        let repository = GaugeRecordRepositorySpy()
        let project = Self.makeProject()
        let viewModel = GaugeCalculatorViewModel(
            gaugeRecordRepository: repository,
            projectRepository: ProjectRepositoryStub(projects: [project]),
            userDefaults: Self.makeUserDefaults()
        )
        viewModel.sampleWidthCm = "10"
        viewModel.sampleHeightCm = "10"
        viewModel.stitchCount = "22"
        viewModel.rowCount = "30"
        viewModel.targetWidthCm = "40"
        viewModel.targetHeightCm = "55"
        viewModel.needle = "4.0mm circular"
        viewModel.memo = "Measured before blocking."
        viewModel.selectedProject = project

        await viewModel.saveCurrentGaugeRecord(stage: .beforeWash)

        let saved = try #require(repository.savedRecords.last)
        #expect(saved.measurementStage == .beforeWash)
        #expect(saved.projectId == project.id)
        #expect(saved.projectNameSnapshot == "Favorite Cardigan")
        #expect(saved.patternNameSnapshot == "Cozy Shawl")
        #expect(saved.stitchesPer10Cm == 22)
        #expect(saved.rowsPer10Cm == 30)
        #expect(saved.targetStitches == 88)
        #expect(saved.targetRows == 165)
        #expect(viewModel.gaugeRecords.count == 1)
    }

    @Test func loadPatternsExposesPatternDocumentsForGaugeLinking() async throws {
        let pattern = Self.makePattern(title: "Cable Vest")
        let patternRepository = PatternRepositoryStub(patterns: [pattern])
        let viewModel = GaugeCalculatorViewModel(
            gaugeRecordRepository: GaugeRecordRepositorySpy(),
            projectRepository: ProjectRepositoryStub(projects: []),
            patternRepository: patternRepository,
            userDefaults: Self.makeUserDefaults()
        )

        await viewModel.loadPatterns()

        #expect(patternRepository.fetchCallCount == 1)
        #expect(viewModel.availablePatterns.map(\.title) == ["Cable Vest"])
    }

    @Test func saveCurrentGaugeRecordUsesSelectedPatternSnapshot() async throws {
        let repository = GaugeRecordRepositorySpy()
        let pattern = Self.makePattern(title: "Cable Vest")
        let viewModel = GaugeCalculatorViewModel(
            gaugeRecordRepository: repository,
            projectRepository: ProjectRepositoryStub(projects: []),
            patternRepository: PatternRepositoryStub(patterns: [pattern]),
            userDefaults: Self.makeUserDefaults()
        )
        Self.fillValidGaugeInputs(on: viewModel)

        viewModel.selectPattern(pattern)
        await viewModel.saveCurrentGaugeRecord(stage: .beforeWash)

        let saved = try #require(repository.savedRecords.last)
        #expect(saved.projectId == nil)
        #expect(saved.patternNameSnapshot == "Cable Vest")
    }

    @Test func saveCurrentGaugeTargetPersistsDetailedManualMeasurement() async throws {
        let gaugeTargetRepository = GaugeTargetRepositorySpy()
        let pattern = Self.makePattern(title: "Cable Vest")
        let viewModel = GaugeCalculatorViewModel(
            gaugeRecordRepository: GaugeRecordRepositorySpy(),
            gaugeTargetRepository: gaugeTargetRepository,
            projectRepository: ProjectRepositoryStub(projects: []),
            patternRepository: PatternRepositoryStub(patterns: [pattern]),
            userDefaults: Self.makeUserDefaults()
        )
        Self.fillValidGaugeInputs(on: viewModel)
        viewModel.needle = "4.0 mm circular"
        viewModel.memo = "Measured before blocking."
        viewModel.selectPattern(pattern)

        await viewModel.saveCurrentGaugeTarget(washState: .before)

        let target = try #require(gaugeTargetRepository.savedTargets.last)
        #expect(target.name == "Cable Vest 게이지")
        #expect(target.sourcePatternId == pattern.id)
        #expect(target.targetStitches == 22)
        #expect(target.targetWidth == 10)
        #expect(target.targetRows == 30)
        #expect(target.targetHeight == 10)
        #expect(target.swatches.count == 1)
        #expect(target.swatches[0].needleSize == "4.0 mm circular")
        #expect(target.swatches[0].notes == "Measured before blocking.")
        #expect(target.swatches[0].measurements.count == 1)
        #expect(target.swatches[0].measurements[0].method == .manual)
        #expect(target.swatches[0].measurements[0].washState == .before)
        #expect(target.swatches[0].measurements[0].finalStitches == 22)
        #expect(target.swatches[0].measurements[0].finalRows == 30)
        #expect(viewModel.gaugeTargets.count == 1)
        #expect(viewModel.statusMessage == "상세 게이지 측정을 저장했어요.")
    }

    @Test func manualPatternNameOverridesSelectedPatternAndProjectPattern() async throws {
        let repository = GaugeRecordRepositorySpy()
        let project = Self.makeProject()
        let pattern = Self.makePattern(title: "Cable Vest")
        let viewModel = GaugeCalculatorViewModel(
            gaugeRecordRepository: repository,
            projectRepository: ProjectRepositoryStub(projects: [project]),
            patternRepository: PatternRepositoryStub(patterns: [pattern]),
            userDefaults: Self.makeUserDefaults()
        )
        Self.fillValidGaugeInputs(on: viewModel)
        viewModel.selectedProject = project
        viewModel.selectPattern(pattern)

        viewModel.setManualPatternName("  Sleeve Chart  ")
        await viewModel.saveCurrentGaugeRecord(stage: .afterWash)

        let saved = try #require(repository.savedRecords.last)
        #expect(viewModel.selectedPattern == nil)
        #expect(saved.projectId == project.id)
        #expect(saved.projectNameSnapshot == "Favorite Cardigan")
        #expect(saved.patternNameSnapshot == "Sleeve Chart")
    }

    @Test func washComparisonUsesLatestBeforeAndAfterRecords() async throws {
        let repository = GaugeRecordRepositorySpy(records: [
            Self.makeGaugeRecord(stage: .beforeWash, stitchesPer10Cm: 22, rowsPer10Cm: 30, measuredAt: Date(timeIntervalSince1970: 100)),
            Self.makeGaugeRecord(stage: .afterWash, stitchesPer10Cm: 21, rowsPer10Cm: 32, measuredAt: Date(timeIntervalSince1970: 200)),
        ])
        let viewModel = GaugeCalculatorViewModel(
            gaugeRecordRepository: repository,
            projectRepository: ProjectRepositoryStub(projects: []),
            userDefaults: Self.makeUserDefaults()
        )

        await viewModel.loadGaugeRecords()

        let comparison = try #require(viewModel.washComparison)
        #expect(comparison.before.measurementStage == .beforeWash)
        #expect(comparison.after.measurementStage == .afterWash)
        #expect(comparison.stitchDeltaPer10Cm == -1)
        #expect(comparison.rowDeltaPer10Cm == 2)
    }

    @Test func loadGaugeRecordRestoresInputsAndProjectSelection() async throws {
        let project = Self.makeProject()
        let record = GaugeRecord(
            ownerId: project.ownerId,
            projectId: project.id,
            projectNameSnapshot: project.name,
            patternNameSnapshot: project.patternCopy?.titleSnapshot,
            measurementStage: .afterWash,
            sampleWidthCm: 10,
            sampleHeightCm: 8.5,
            stitchCount: 21,
            rowCount: 28.5,
            targetWidthCm: 40,
            targetHeightCm: 55,
            stitchesPer10Cm: 21,
            rowsPer10Cm: 33.529,
            targetStitches: 84,
            targetRows: 184,
            needle: "4.0mm circular",
            memo: "After blocking.",
            measuredAt: Date(timeIntervalSince1970: 300),
            createdAt: Date(timeIntervalSince1970: 300),
            updatedAt: Date(timeIntervalSince1970: 300),
            syncStatus: .synced
        )
        let viewModel = GaugeCalculatorViewModel(
            gaugeRecordRepository: GaugeRecordRepositorySpy(records: [record]),
            projectRepository: ProjectRepositoryStub(projects: [project]),
            userDefaults: Self.makeUserDefaults()
        )
        await viewModel.loadProjects()

        viewModel.loadGaugeRecord(record)

        #expect(viewModel.sampleWidthCm == "10")
        #expect(viewModel.sampleHeightCm == "8.5")
        #expect(viewModel.stitchCount == "21")
        #expect(viewModel.rowCount == "28.5")
        #expect(viewModel.targetWidthCm == "40")
        #expect(viewModel.targetHeightCm == "55")
        #expect(viewModel.needle == "4.0mm circular")
        #expect(viewModel.memo == "After blocking.")
        #expect(viewModel.selectedProject?.id == project.id)
        #expect(viewModel.statusMessage == "세탁 후 게이지를 불러왔어요.")
    }

    @Test func deleteGaugeRecordRemovesRecordFromRepositoryAndList() async throws {
        let record = Self.makeGaugeRecord(
            stage: .beforeWash,
            stitchesPer10Cm: 22,
            rowsPer10Cm: 30,
            measuredAt: Date(timeIntervalSince1970: 100)
        )
        let repository = GaugeRecordRepositorySpy(records: [record])
        let viewModel = GaugeCalculatorViewModel(
            gaugeRecordRepository: repository,
            projectRepository: ProjectRepositoryStub(projects: []),
            userDefaults: Self.makeUserDefaults()
        )
        await viewModel.loadGaugeRecords()

        await viewModel.deleteGaugeRecord(id: record.id)

        #expect(repository.deletedRecordIDs == [record.id])
        #expect(viewModel.gaugeRecords.isEmpty)
    }

    @Test func updateLoadedGaugeRecordSavesChangesWithoutCreatingDuplicateRecord() async throws {
        let record = Self.makeGaugeRecord(
            stage: .beforeWash,
            stitchesPer10Cm: 22,
            rowsPer10Cm: 30,
            measuredAt: Date(timeIntervalSince1970: 100)
        )
        let repository = GaugeRecordRepositorySpy(records: [record])
        let viewModel = GaugeCalculatorViewModel(
            gaugeRecordRepository: repository,
            projectRepository: ProjectRepositoryStub(projects: []),
            userDefaults: Self.makeUserDefaults()
        )
        await viewModel.loadGaugeRecords()
        viewModel.loadGaugeRecord(record)
        viewModel.sampleWidthCm = "12"
        viewModel.sampleHeightCm = "8"
        viewModel.stitchCount = "24"
        viewModel.rowCount = "28"
        viewModel.targetWidthCm = "48"
        viewModel.targetHeightCm = "60"
        viewModel.needle = "5.0mm circular"
        viewModel.memo = "Edited after measuring."

        await viewModel.updateLoadedGaugeRecord()

        let updated = try #require(repository.updatedRecords.last)
        #expect(updated.id == record.id)
        #expect(updated.measurementStage == .beforeWash)
        #expect(updated.sampleWidthCm == 12)
        #expect(updated.sampleHeightCm == 8)
        #expect(updated.stitchCount == 24)
        #expect(updated.rowCount == 28)
        #expect(updated.targetWidthCm == 48)
        #expect(updated.targetHeightCm == 60)
        #expect(updated.stitchesPer10Cm == 20)
        #expect(updated.rowsPer10Cm == 35)
        #expect(updated.targetStitches == 96)
        #expect(updated.targetRows == 210)
        #expect(updated.needle == "5.0mm circular")
        #expect(updated.memo == "Edited after measuring.")
        #expect(updated.measuredAt == record.measuredAt)
        #expect(viewModel.gaugeRecords.count == 1)
        #expect(viewModel.gaugeRecords[0].id == record.id)
        #expect(viewModel.statusMessage == "세탁 전 게이지 기록을 수정했어요.")
    }

    @Test func reloadAfterAccountChangeFetchesProjectsAndGaugeRecordsAgain() async throws {
        let oldProject = Self.makeProject(name: "Old account project", ownerId: "user-a")
        let newProject = Self.makeProject(name: "New account project", ownerId: "user-b")
        let oldRecord = Self.makeGaugeRecord(ownerId: "user-a", memo: "old")
        let newRecord = Self.makeGaugeRecord(ownerId: "user-b", memo: "new")
        let gaugeRepository = ReloadGaugeRecordRepositoryStub(fetchResults: [
            .success([oldRecord]),
            .success([newRecord]),
        ])
        let projectRepository = ReloadProjectRepositoryStub(fetchResults: [
            .success([oldProject]),
            .success([newProject]),
        ])
        let viewModel = GaugeCalculatorViewModel(
            gaugeRecordRepository: gaugeRepository,
            projectRepository: projectRepository,
            userDefaults: Self.makeUserDefaults()
        )

        await viewModel.loadProjects()
        await viewModel.loadGaugeRecords()
        viewModel.selectedProject = oldProject
        await viewModel.reloadAfterAccountChange()

        #expect(projectRepository.fetchCallCount == 2)
        #expect(gaugeRepository.fetchCallCount == 2)
        #expect(viewModel.availableProjects.map(\.name) == ["New account project"])
        #expect(viewModel.gaugeRecords.map(\.memo) == ["new"])
        #expect(viewModel.selectedProject == nil)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func reloadAfterAccountChangeClearsStaleGaugeDataWhenFetchFails() async throws {
        let oldProject = Self.makeProject(name: "Old account project", ownerId: "user-a")
        let oldRecord = Self.makeGaugeRecord(ownerId: "user-a", memo: "old")
        let gaugeRepository = ReloadGaugeRecordRepositoryStub(fetchResults: [
            .success([oldRecord]),
            .failure(GaugeReloadStubError.fetchFailed),
        ])
        let projectRepository = ReloadProjectRepositoryStub(fetchResults: [
            .success([oldProject]),
            .success([]),
        ])
        let viewModel = GaugeCalculatorViewModel(
            gaugeRecordRepository: gaugeRepository,
            projectRepository: projectRepository,
            userDefaults: Self.makeUserDefaults()
        )

        await viewModel.loadProjects()
        await viewModel.loadGaugeRecords()
        viewModel.selectedProject = oldProject
        await viewModel.reloadAfterAccountChange()

        #expect(viewModel.availableProjects.isEmpty)
        #expect(viewModel.gaugeRecords.isEmpty)
        #expect(viewModel.selectedProject == nil)
        #expect(viewModel.errorMessage == "계정 데이터를 다시 불러오지 못했어요.")
    }

    private static func makeUserDefaults() -> UserDefaults {
        let suiteName = "GaugeCalculatorViewModelTests-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private static func fillValidGaugeInputs(on viewModel: GaugeCalculatorViewModel) {
        viewModel.sampleWidthCm = "10"
        viewModel.sampleHeightCm = "10"
        viewModel.stitchCount = "22"
        viewModel.rowCount = "30"
        viewModel.targetWidthCm = "40"
        viewModel.targetHeightCm = "55"
    }

    private static func makePattern(title: String) -> PatternDocument {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        return PatternDocument(
            ownerId: "user-a",
            title: title,
            designer: "Test Designer",
            fileName: "\(title).pdf",
            localFilePath: nil,
            pageCount: 8,
            notes: "",
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
    }

    private static func makeProject() -> KnittingProject {
        makeProject(name: "Favorite Cardigan", ownerId: "user-a")
    }

    private static func makeProject(
        name: String,
        ownerId: String
    ) -> KnittingProject {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let projectID = UUID()
        let patternCopy = ProjectPatternCopy(
            id: UUID(),
            ownerId: ownerId,
            projectId: projectID,
            sourcePatternDocumentId: nil,
            titleSnapshot: "Cozy Shawl",
            designerSnapshot: nil,
            fileNameSnapshot: "cozy-shawl.pdf",
            localCopyPath: nil,
            pageCountSnapshot: nil,
            copiedAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
        let rowCounter = RowCounter(
            ownerId: ownerId,
            projectId: projectID,
            name: "Main Counter",
            currentRow: 0,
            targetRow: nil,
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )

        return KnittingProject(
            id: projectID,
            ownerId: ownerId,
            name: name,
            status: .wip,
            isFavorite: false,
            memo: "",
            startDate: now,
            lastWorkedAt: nil,
            patternCopy: patternCopy,
            rowCounter: rowCounter,
            workSessions: [],
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
    }

    private static func makeGaugeRecord(
        stage: GaugeMeasurementStage,
        stitchesPer10Cm: Double,
        rowsPer10Cm: Double,
        measuredAt: Date
    ) -> GaugeRecord {
        makeGaugeRecord(
            ownerId: "user-a",
            stage: stage,
            stitchesPer10Cm: stitchesPer10Cm,
            rowsPer10Cm: rowsPer10Cm,
            measuredAt: measuredAt,
            memo: ""
        )
    }

    private static func makeGaugeRecord(
        ownerId: String,
        memo: String
    ) -> GaugeRecord {
        makeGaugeRecord(
            ownerId: ownerId,
            stage: .beforeWash,
            stitchesPer10Cm: 22,
            rowsPer10Cm: 30,
            measuredAt: Date(timeIntervalSince1970: 300),
            memo: memo
        )
    }

    private static func makeGaugeRecord(
        ownerId: String,
        stage: GaugeMeasurementStage,
        stitchesPer10Cm: Double,
        rowsPer10Cm: Double,
        measuredAt: Date,
        memo: String
    ) -> GaugeRecord {
        GaugeRecord(
            id: UUID(),
            ownerId: ownerId,
            projectId: nil,
            projectNameSnapshot: nil,
            patternNameSnapshot: nil,
            measurementStage: stage,
            sampleWidthCm: 10,
            sampleHeightCm: 10,
            stitchCount: stitchesPer10Cm,
            rowCount: rowsPer10Cm,
            targetWidthCm: 10,
            targetHeightCm: 10,
            stitchesPer10Cm: stitchesPer10Cm,
            rowsPer10Cm: rowsPer10Cm,
            targetStitches: Int(stitchesPer10Cm.rounded()),
            targetRows: Int(rowsPer10Cm.rounded()),
            needle: "",
            memo: memo,
            measuredAt: measuredAt,
            createdAt: measuredAt,
            updatedAt: measuredAt,
            syncStatus: .synced
        )
    }

    final class GaugeRecordRepositorySpy: GaugeRecordRepository {
        var records: [GaugeRecord]
        var savedRecords: [GaugeRecord] = []
        var updatedRecords: [GaugeRecord] = []
        var deletedRecordIDs: [UUID] = []

        init(records: [GaugeRecord] = []) {
            self.records = records
        }

        func fetchGaugeRecords() async throws -> [GaugeRecord] {
            records
        }

        func saveGaugeRecord(_ record: GaugeRecord) async throws -> GaugeRecord {
            savedRecords.append(record)
            records.append(record)
            return record.copy(syncStatus: .synced)
        }

        func updateGaugeRecord(_ record: GaugeRecord) async throws -> GaugeRecord {
            updatedRecords.append(record)
            if let index = records.firstIndex(where: { $0.id == record.id }) {
                records[index] = record
            } else {
                records.append(record)
            }
            return record.copy(syncStatus: .synced)
        }

        func deleteGaugeRecord(id: UUID) async throws {
            deletedRecordIDs.append(id)
            records.removeAll { $0.id == id }
        }
    }

    final class GaugeTargetRepositorySpy: GaugeTargetRepository {
        var targets: [GaugeTarget]
        var savedTargets: [GaugeTarget] = []
        var deletedTargetIDs: [UUID] = []

        init(targets: [GaugeTarget] = []) {
            self.targets = targets
        }

        func fetchGaugeTargets() async throws -> [GaugeTarget] {
            targets
        }

        func saveGaugeTarget(_ target: GaugeTarget) async throws -> GaugeTarget {
            savedTargets.append(target)
            targets.append(target)
            return GaugeTarget(
                id: target.id,
                ownerId: target.ownerId,
                name: target.name,
                targetStitches: target.targetStitches,
                targetWidth: target.targetWidth,
                targetRows: target.targetRows,
                targetHeight: target.targetHeight,
                isQuickMeasure: target.isQuickMeasure,
                gaugeAfterWash: target.gaugeAfterWash,
                recommendedNeedle: target.recommendedNeedle,
                sourcePatternId: target.sourcePatternId,
                createdAt: target.createdAt,
                updatedAt: target.updatedAt,
                syncStatus: .synced,
                swatches: target.swatches
            )
        }

        func deleteGaugeTarget(id: UUID) async throws {
            deletedTargetIDs.append(id)
            targets.removeAll { $0.id == id }
        }
    }

    final class ProjectRepositoryStub: ProjectRepository {
        let projects: [KnittingProject]

        init(projects: [KnittingProject]) {
            self.projects = projects
        }

        func fetchProjects() async throws -> [KnittingProject] {
            projects
        }

        func fetchProject(id: UUID) async throws -> KnittingProject? {
            projects.first { $0.id == id }
        }

        func saveProject(_ project: KnittingProject) async throws {
        }

        func deleteProject(id: UUID) async throws {
        }
    }

    final class PatternRepositoryStub: PatternRepository {
        let patterns: [PatternDocument]
        private(set) var fetchCallCount = 0

        init(patterns: [PatternDocument]) {
            self.patterns = patterns
        }

        func fetchPatterns() async throws -> [PatternDocument] {
            fetchCallCount += 1
            return patterns
        }

        func fetchPattern(id: UUID) async throws -> PatternDocument? {
            patterns.first { $0.id == id }
        }

        func savePattern(_ pattern: PatternDocument) async throws {
        }

        func deletePattern(id: UUID) async throws {
        }

        func createPattern(fromFileAt fileURL: URL) async throws -> PatternDocument {
            throw GaugeReloadStubError.fetchFailed
        }

        func importPattern(_ pattern: PatternDocument, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
            throw GaugeReloadStubError.fetchFailed
        }

        func createProjectPatternCopy(fromFileAt fileURL: URL, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
            throw GaugeReloadStubError.fetchFailed
        }

        func fileURL(for pattern: PatternDocument) -> URL? {
            nil
        }

        func fileURL(for patternCopy: ProjectPatternCopy) -> URL? {
            nil
        }

        func drawingData(for patternCopy: ProjectPatternCopy) async throws -> Data? {
            nil
        }

        func saveDrawingData(_ data: Data, for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy {
            patternCopy
        }

        func deleteDrawingData(for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy {
            patternCopy
        }
    }

    final class ReloadGaugeRecordRepositoryStub: GaugeRecordRepository {
        private var fetchResults: [Result<[GaugeRecord], Error>]
        private(set) var fetchCallCount = 0

        init(fetchResults: [Result<[GaugeRecord], Error>]) {
            self.fetchResults = fetchResults
        }

        func fetchGaugeRecords() async throws -> [GaugeRecord] {
            fetchCallCount += 1
            return try fetchResults.removeFirst().get()
        }

        func saveGaugeRecord(_ record: GaugeRecord) async throws -> GaugeRecord {
            record
        }

        func updateGaugeRecord(_ record: GaugeRecord) async throws -> GaugeRecord {
            record
        }

        func deleteGaugeRecord(id: UUID) async throws {
        }
    }

    final class ReloadProjectRepositoryStub: ProjectRepository {
        private var fetchResults: [Result<[KnittingProject], Error>]
        private(set) var fetchCallCount = 0

        init(fetchResults: [Result<[KnittingProject], Error>]) {
            self.fetchResults = fetchResults
        }

        func fetchProjects() async throws -> [KnittingProject] {
            fetchCallCount += 1
            return try fetchResults.removeFirst().get()
        }

        func fetchProject(id: UUID) async throws -> KnittingProject? {
            nil
        }

        func saveProject(_ project: KnittingProject) async throws {
        }

        func deleteProject(id: UUID) async throws {
        }
    }

    enum GaugeReloadStubError: Error {
        case fetchFailed
    }
}
