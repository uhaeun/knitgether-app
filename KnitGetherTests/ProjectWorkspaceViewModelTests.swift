import Foundation
import Testing
@testable import KnitGether
#if canImport(UIKit)
import UIKit
#endif

@MainActor
struct ProjectWorkspaceViewModelTests {
    @Test func resetCurrentRowPersistsZeroAndKeepsCounterMetadata() async throws {
        let project = Self.makeProject(currentRow: 12, targetRow: 40, rowInstructions: [
            Self.makeInstruction(rowNumber: 12, text: "K all", skillTags: "K")
        ])
        let repository = ProjectRepositorySpy(project: project)
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: repository,
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy()
        )

        await viewModel.resetCurrentRow()

        #expect(viewModel.currentRow == 0)
        #expect(repository.savedProjects.last?.rowCounter.currentRow == 0)
        #expect(repository.savedProjects.last?.rowCounter.targetRow == 40)
        #expect(repository.savedProjects.last?.rowCounter.rowInstructions.count == 1)
    }

    @Test func completeProjectPersistsFOStatus() async throws {
        let project = Self.makeProject(status: .wip)
        let repository = ProjectRepositorySpy(project: project)
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: repository,
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy()
        )

        await viewModel.completeProject()

        #expect(viewModel.project.status == .fo)
        #expect(repository.savedProjects.last?.status == .fo)
    }

    @Test func unlinkPatternRemovesPatternAndDrawingState() async throws {
        let project = Self.makeProject(patternCopy: Self.makePatternCopy())
        let repository = ProjectRepositorySpy(project: project)
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: repository,
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy()
        )
        viewModel.drawingData = Data("drawing".utf8)

        await viewModel.unlinkPattern()

        #expect(viewModel.project.patternCopy == nil)
        #expect(viewModel.attachedPatternFileURL == nil)
        #expect(viewModel.drawingData == nil)
    }

    @Test func attachManualPatternReturnsFalseAndKeepsExistingPatternWhenSaveFails() async throws {
        let patternCopy = Self.makePatternCopy()
        let project = Self.makeProject(patternCopy: patternCopy)
        let repository = ProjectRepositorySpy(project: project)
        repository.saveError = TestRepositoryError.unsupported
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: repository,
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy()
        )

        let didSave = await viewModel.attachManualPattern(title: "Replacement Pattern")

        #expect(!didSave)
        #expect(viewModel.project.patternCopy?.id == patternCopy.id)
        #expect(viewModel.errorMessage == "수동 도안을 연결하지 못했어요.")
    }

    @Test func resolvedSkillTagsMarksRegisteredAndUnregisteredTags() async throws {
        let project = Self.makeProject(rowInstructions: [
            Self.makeInstruction(rowNumber: 1, text: "K then YO", skillTags: "K,YO")
        ])
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(skills: [
                Self.makeSkill(abbreviation: "K", difficulty: "기초", userLevel: "잘 알아요")
            ]),
            libraryRepository: LibraryRepositorySpy()
        )

        await viewModel.loadRelatedSkills()
        let tags = viewModel.resolvedSkillTags(for: project.rowCounter.rowInstructions[0])

        #expect(tags.map(\.displayTag) == ["K", "YO"])
        #expect(tags[0].isRegistered)
        #expect(tags[0].level == "잘 알아요")
        #expect(!tags[1].isRegistered)
        #expect(tags[1].level == "미등록")
    }

    @Test func currentLearningSkillTagsPrioritizesUnknownAndUnsureCurrentRowSkills() async throws {
        let project = Self.makeProject(currentRow: 4, rowInstructions: [
            Self.makeInstruction(rowNumber: 4, text: "K2TOG, YO, then K", skillTags: "K2TOG,YO,K"),
            Self.makeInstruction(rowNumber: 5, text: "SSK", skillTags: "SSK")
        ])
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(skills: [
                Self.makeSkill(abbreviation: "K2TOG", difficulty: "초급", userLevel: "몰라요"),
                Self.makeSkill(abbreviation: "YO", difficulty: "초급", userLevel: "헷갈려요"),
                Self.makeSkill(abbreviation: "K", difficulty: "기초", userLevel: "잘 알아요"),
                Self.makeSkill(abbreviation: "SSK", difficulty: "초급", userLevel: "몰라요")
            ]),
            libraryRepository: LibraryRepositorySpy()
        )

        await viewModel.loadRelatedSkills()

        #expect(viewModel.currentLearningSkillTags.map(\.displayTag) == ["K2TOG", "YO"])
        #expect(viewModel.currentLearningSkillTags.map(\.level) == ["몰라요", "헷갈려요"])
    }

    @Test func loadRelatedSkillsIncludesAbbreviationsExtractedFromAttachedPDFText() async throws {
#if canImport(UIKit)
        let patternCopy = Self.makePatternCopy()
        let pdfURL = try Self.makeTemporaryPDF(containing: "Body: K2TOG, SSK, YO across the row.")
        let project = Self.makeProject(patternCopy: patternCopy)
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(patternCopyFileURLs: [patternCopy.id: pdfURL]),
            skillRepository: SkillRepositoryFake(skills: [
                Self.makeSkill(abbreviation: "K2TOG", difficulty: "초급", userLevel: "몰라요"),
                Self.makeSkill(abbreviation: "SSK", difficulty: "초급", userLevel: "헷갈려요"),
                Self.makeSkill(abbreviation: "YO", difficulty: "초급", userLevel: "잘 알아요"),
                Self.makeSkill(abbreviation: "K", difficulty: "기초", userLevel: "잘 알아요")
            ]),
            libraryRepository: LibraryRepositorySpy()
        )

        await viewModel.loadRelatedSkills()

        #expect(viewModel.relatedSkills.map(\.abbreviation) == ["K2TOG", "SSK", "YO"])
#endif
    }

    @Test func loadRelatedSkillsIncludesAbbreviationsRecognizedFromScannedPDFImage() async throws {
#if canImport(UIKit) && canImport(Vision)
        let patternCopy = Self.makePatternCopy()
        let pdfURL = try Self.makeTemporaryImagePDF(containing: "K2TOG SSK YO")
        let project = Self.makeProject(patternCopy: patternCopy)
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(patternCopyFileURLs: [patternCopy.id: pdfURL]),
            skillRepository: SkillRepositoryFake(skills: [
                Self.makeSkill(abbreviation: "K2TOG", difficulty: "초급", userLevel: "몰라요"),
                Self.makeSkill(abbreviation: "SSK", difficulty: "초급", userLevel: "헷갈려요"),
                Self.makeSkill(abbreviation: "YO", difficulty: "초급", userLevel: "잘 알아요")
            ]),
            libraryRepository: LibraryRepositorySpy()
        )

        await viewModel.loadRelatedSkills()

        #expect(viewModel.relatedSkills.map(\.abbreviation) == ["K2TOG", "SSK", "YO"])
#endif
    }

    @Test func attachNewPatternCanStoreFileInLibraryBeforeProjectConnection() async throws {
#if canImport(UIKit)
        let sourceURL = try Self.makeTemporaryPDF(containing: "Row 8: K2TOG and YO.")
        let project = Self.makeProject()
        let projectRepository = ProjectRepositorySpy(project: project)
        let storedPattern = Self.makePatternDocument(
            title: sourceURL.deletingPathExtension().lastPathComponent,
            fileName: sourceURL.lastPathComponent
        )
        let importedCopy = Self.makePatternCopy(
            sourcePatternDocumentId: storedPattern.id,
            title: storedPattern.title,
            fileName: storedPattern.fileName
        )
        let patternRepository = PatternRepositorySpy(
            storedPattern: storedPattern,
            importedCopy: importedCopy
        )
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: projectRepository,
            patternRepository: patternRepository,
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy()
        )

        let didAttach = await viewModel.attachNewPattern(fromFileAt: sourceURL, storeInLibrary: true)

        #expect(didAttach)
        #expect(patternRepository.createdPatternFileURLs == [sourceURL])
        #expect(patternRepository.importedPatternIDs == [storedPattern.id])
        #expect(patternRepository.createdProjectOnlyFileURLs.isEmpty)
        #expect(projectRepository.savedProjects.last?.patternCopy?.sourcePatternDocumentId == storedPattern.id)
        #expect(viewModel.project.patternCopy?.titleSnapshot == storedPattern.title)
#endif
    }

    @Test func attachNewPatternCanKeepFileProjectOnly() async throws {
#if canImport(UIKit)
        let sourceURL = try Self.makeTemporaryPDF(containing: "Row 12: SSK.")
        let project = Self.makeProject()
        let projectRepository = ProjectRepositorySpy(project: project)
        let projectOnlyCopy = Self.makePatternCopy(
            sourcePatternDocumentId: nil,
            title: sourceURL.deletingPathExtension().lastPathComponent,
            fileName: sourceURL.lastPathComponent
        )
        let patternRepository = PatternRepositorySpy(projectOnlyCopy: projectOnlyCopy)
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: projectRepository,
            patternRepository: patternRepository,
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy()
        )

        let didAttach = await viewModel.attachNewPattern(fromFileAt: sourceURL, storeInLibrary: false)

        #expect(didAttach)
        #expect(patternRepository.createdPatternFileURLs.isEmpty)
        #expect(patternRepository.createdProjectOnlyFileURLs == [sourceURL])
        #expect(projectRepository.savedProjects.last?.patternCopy?.sourcePatternDocumentId == nil)
        #expect(viewModel.project.patternCopy?.fileNameSnapshot == sourceURL.lastPathComponent)
#endif
    }

    @Test func loadRelatedSkillsBuildsRowInstructionSuggestionsFromPatternText() async throws {
#if canImport(UIKit)
        let patternCopy = Self.makePatternCopy()
        let pdfURL = try Self.makeTemporaryPDF(containing: """
        Row 8: K2TOG, YO, knit to end.
        Row 9: Purl all stitches.
        Row 10: SSK before marker.
        """)
        let project = Self.makeProject(patternCopy: patternCopy)
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(patternCopyFileURLs: [patternCopy.id: pdfURL]),
            skillRepository: SkillRepositoryFake(skills: [
                Self.makeSkill(abbreviation: "K2TOG", difficulty: "초급", userLevel: "몰라요"),
                Self.makeSkill(abbreviation: "YO", difficulty: "초급", userLevel: "헷갈려요"),
                Self.makeSkill(abbreviation: "SSK", difficulty: "초급", userLevel: "몰라요")
            ]),
            libraryRepository: LibraryRepositorySpy()
        )

        await viewModel.loadRelatedSkills()

        #expect(viewModel.patternRowInstructionSuggestions.map(\.rowNumber) == [8, 10])
        #expect(viewModel.patternRowInstructionSuggestions.map(\.skillTags) == [["K2TOG", "YO"], ["SSK"]])
        #expect(viewModel.patternRowInstructionSuggestions.first?.instructionText == "Row 8: K2TOG, YO, knit to end.")
#endif
    }

    @Test func addPatternRowInstructionSuggestionPersistsRowInstruction() async throws {
#if canImport(UIKit)
        let patternCopy = Self.makePatternCopy()
        let pdfURL = try Self.makeTemporaryPDF(containing: "Row 8: K2TOG, YO, knit to end.")
        let project = Self.makeProject(patternCopy: patternCopy)
        let repository = ProjectRepositorySpy(project: project)
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: repository,
            patternRepository: PatternRepositoryFake(patternCopyFileURLs: [patternCopy.id: pdfURL]),
            skillRepository: SkillRepositoryFake(skills: [
                Self.makeSkill(abbreviation: "K2TOG", difficulty: "초급", userLevel: "몰라요"),
                Self.makeSkill(abbreviation: "YO", difficulty: "초급", userLevel: "헷갈려요")
            ]),
            libraryRepository: LibraryRepositorySpy()
        )

        await viewModel.loadRelatedSkills()
        let suggestion = try #require(viewModel.patternRowInstructionSuggestions.first)
        let didAdd = await viewModel.addRowInstruction(from: suggestion)

        #expect(didAdd)
        #expect(viewModel.rowCounter.rowInstructions.first?.rowNumber == 8)
        #expect(viewModel.rowCounter.rowInstructions.first?.skillTags == "K2TOG,YO")
        #expect(repository.savedProjects.last?.rowCounter.rowInstructions.first?.instructionText == "Row 8: K2TOG, YO, knit to end.")
#endif
    }

    @Test func recordYarnUsageSavesUsageAndRefreshesRemainingYarn() async throws {
        let yarn = Self.makeYarn(quantity: 5)
        let project = Self.makeProject(
            yarnId: yarn.id,
            yarnNameSnapshot: yarn.name,
            yarnBrandSnapshot: yarn.brand,
            yarnColorwaySnapshot: yarn.colorway,
            yarnWeightSnapshot: yarn.weight
        )
        let libraryRepository = LibraryRepositorySpy(yarns: [yarn])
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: libraryRepository
        )

        await viewModel.loadYarnUsage()
        let didRecord = await viewModel.recordYarnUsage(
            quantityUsed: 2,
            memo: "  Sleeve swatch  "
        )

        #expect(didRecord)
        #expect(libraryRepository.recordedYarnUsages.count == 1)
        #expect(libraryRepository.recordedYarnUsages[0].projectId == project.id)
        #expect(libraryRepository.recordedYarnUsages[0].projectNameSnapshot == project.name)
        #expect(libraryRepository.recordedYarnUsages[0].yarnId == yarn.id)
        #expect(libraryRepository.recordedYarnUsages[0].quantityUsed == 2)
        #expect(libraryRepository.recordedYarnUsages[0].memo == "Sleeve swatch")
        #expect(viewModel.yarnUsages.count == 1)
        #expect(viewModel.attachedYarn?.quantity == 3)
        #expect(viewModel.yarnUsageTotal == 2)
    }

    @Test func updateYarnUsageRefreshesAdjustedRemainingYarn() async throws {
        let yarn = Self.makeYarn(quantity: 3)
        let usage = Self.makeYarnUsage(yarnId: yarn.id, quantityUsed: 2)
        let project = Self.makeProject(
            yarnId: yarn.id,
            yarnNameSnapshot: yarn.name,
            yarnBrandSnapshot: yarn.brand,
            yarnColorwaySnapshot: yarn.colorway,
            yarnWeightSnapshot: yarn.weight
        )
        let libraryRepository = LibraryRepositorySpy(yarns: [yarn], yarnUsages: [usage])
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: libraryRepository
        )

        await viewModel.loadYarnUsage()
        let didUpdate = await viewModel.updateYarnUsage(
            usage,
            quantityUsed: 1,
            memo: "  Corrected swatch  "
        )

        #expect(didUpdate)
        #expect(libraryRepository.updatedYarnUsages.count == 1)
        #expect(libraryRepository.updatedYarnUsages[0].projectNameSnapshot == project.name)
        #expect(libraryRepository.updatedYarnUsages[0].quantityUsed == 1)
        #expect(libraryRepository.updatedYarnUsages[0].memo == "Corrected swatch")
        #expect(viewModel.yarnUsages.first?.quantityUsed == 1)
        #expect(viewModel.attachedYarn?.quantity == 4)
        #expect(viewModel.yarnUsageTotal == 1)
    }

    @Test func deleteYarnUsageRefreshesRestoredRemainingYarn() async throws {
        let yarn = Self.makeYarn(quantity: 3)
        let usage = Self.makeYarnUsage(yarnId: yarn.id, quantityUsed: 2)
        let project = Self.makeProject(
            yarnId: yarn.id,
            yarnNameSnapshot: yarn.name,
            yarnBrandSnapshot: yarn.brand,
            yarnColorwaySnapshot: yarn.colorway,
            yarnWeightSnapshot: yarn.weight
        )
        let libraryRepository = LibraryRepositorySpy(yarns: [yarn], yarnUsages: [usage])
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: libraryRepository
        )

        await viewModel.loadYarnUsage()
        let didDelete = await viewModel.deleteYarnUsage(usage)

        #expect(didDelete)
        #expect(libraryRepository.deletedYarnUsages == [usage.id])
        #expect(viewModel.yarnUsages.isEmpty)
        #expect(viewModel.attachedYarn?.quantity == 5)
        #expect(viewModel.yarnUsageTotal == 0)
    }

    @Test func finishWorkSessionDoesNotPersistVeryShortAutomaticSession() async throws {
        let project = Self.makeProject()
        let repository = ProjectRepositorySpy(project: project)
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: repository,
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy()
        )

        viewModel.startWorkSession()
        await viewModel.finishWorkSession()

        #expect(!viewModel.isTrackingTime)
        #expect(viewModel.currentSessionElapsed == 0)
        #expect(repository.savedProjects.isEmpty)
        #expect(viewModel.project.workSessions.isEmpty)
    }

    @Test func recordingWorkSessionCreatesLocalOnlySessionForSyncedProject() throws {
        let project = Self.makeProject(syncStatus: .synced)
        let startedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let endedAt = Date(timeIntervalSince1970: 1_800_003_600)

        let updatedProject = project.recordingWorkSession(
            startedAt: startedAt,
            endedAt: endedAt
        )

        #expect(updatedProject.workSessions.last?.syncStatus == .localOnly)
        #expect(updatedProject.syncStatus == .synced)
    }

    @Test func recordingWorkSessionKeepsLocalProjectSessionLocalOnly() throws {
        let project = Self.makeProject(syncStatus: .localOnly)
        let startedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let endedAt = Date(timeIntervalSince1970: 1_800_003_600)

        let updatedProject = project.recordingWorkSession(
            startedAt: startedAt,
            endedAt: endedAt
        )

        #expect(updatedProject.workSessions.last?.syncStatus == .localOnly)
        #expect(updatedProject.syncStatus == .localOnly)
    }

    @Test func workSessionsByMostRecentSortsSessionsDescending() async throws {
        let olderSession = Self.makeWorkSession(
            id: UUID(uuidString: "44444444-4444-4444-8444-444444444444")!,
            startedAt: Date(timeIntervalSince1970: 1_800_000_000),
            endedAt: Date(timeIntervalSince1970: 1_800_003_600)
        )
        let newerSession = Self.makeWorkSession(
            id: UUID(uuidString: "55555555-5555-4555-8555-555555555555")!,
            startedAt: Date(timeIntervalSince1970: 1_800_010_000),
            endedAt: Date(timeIntervalSince1970: 1_800_011_800)
        )
        let project = Self.makeProject(workSessions: [olderSession, newerSession])
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy()
        )

        #expect(viewModel.workSessionsByMostRecent.map(\.id) == [newerSession.id, olderSession.id])
    }

    @Test func workSessionStatisticsSummarizesTodayTotalAndAverage() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let todaySession = Self.makeWorkSession(
            startedAt: Date(timeIntervalSince1970: 1_800_000_000),
            endedAt: Date(timeIntervalSince1970: 1_800_003_600)
        )
        let yesterdaySession = Self.makeWorkSession(
            startedAt: Date(timeIntervalSince1970: 1_799_900_000),
            endedAt: Date(timeIntervalSince1970: 1_799_901_800)
        )

        let statistics = WorkSessionStatistics(
            sessions: [todaySession, yesterdaySession],
            calendar: calendar,
            referenceDate: Date(timeIntervalSince1970: 1_800_000_500)
        )

        #expect(statistics.sessionCount == 2)
        #expect(statistics.totalDuration == 5_400)
        #expect(statistics.todayDuration == 3_600)
        #expect(statistics.averageDuration == 2_700)
    }

    @Test func updateWorkSessionMemoPersistsTrimmedMemo() async throws {
        let session = Self.makeWorkSession(memo: nil)
        let project = Self.makeProject(workSessions: [session])
        let repository = ProjectRepositorySpy(project: project)
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: repository,
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy()
        )

        let didSave = await viewModel.updateWorkSessionMemo(
            sessionID: session.id,
            memo: "  Sleeve increases  "
        )

        #expect(didSave)
        #expect(repository.savedProjects.last?.workSessions.first?.memo == "Sleeve increases")
        #expect(viewModel.project.workSessions.first?.memo == "Sleeve increases")
    }

    @Test func deleteWorkSessionRemovesSessionAndPersists() async throws {
        let session = Self.makeWorkSession()
        let project = Self.makeProject(workSessions: [session])
        let repository = ProjectRepositorySpy(project: project)
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: repository,
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy()
        )

        let didDelete = await viewModel.deleteWorkSession(sessionID: session.id)

        #expect(didDelete)
        #expect(repository.savedProjects.last?.workSessions.isEmpty == true)
        #expect(viewModel.project.workSessions.isEmpty)
    }

    @Test func loadGaugeRecordsKeepsLinkedRecordsForCurrentProject() async throws {
        let project = Self.makeProject()
        let linkedRecord = Self.makeGaugeRecord(projectId: project.id)
        let otherRecord = Self.makeGaugeRecord(
            id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            projectId: UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!
        )
        let gaugeRecordRepository = GaugeRecordRepositorySpy(records: [otherRecord, linkedRecord])
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy(),
            gaugeRecordRepository: gaugeRecordRepository
        )

        await viewModel.loadGaugeRecords()

        #expect(viewModel.linkedGaugeRecords.map(\.id) == [linkedRecord.id])
    }

    @Test func linkGaugeRecordPersistsProjectSnapshot() async throws {
        let project = Self.makeProject(patternCopy: Self.makePatternCopy())
        let independentRecord = Self.makeGaugeRecord(projectId: nil)
        let gaugeRecordRepository = GaugeRecordRepositorySpy(records: [independentRecord])
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy(),
            gaugeRecordRepository: gaugeRecordRepository
        )

        await viewModel.loadGaugeRecords()
        let didLink = await viewModel.linkGaugeRecord(independentRecord)

        #expect(didLink)
        #expect(gaugeRecordRepository.savedRecords.last?.projectId == project.id)
        #expect(gaugeRecordRepository.savedRecords.last?.projectNameSnapshot == project.name)
        #expect(gaugeRecordRepository.savedRecords.last?.patternNameSnapshot == project.patternCopy?.titleSnapshot)
        #expect(viewModel.linkedGaugeRecords.map(\.id) == [independentRecord.id])
    }

    @Test func unlinkGaugeRecordClearsProjectConnection() async throws {
        let project = Self.makeProject()
        let linkedRecord = Self.makeGaugeRecord(projectId: project.id)
        let gaugeRecordRepository = GaugeRecordRepositorySpy(records: [linkedRecord])
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy(),
            gaugeRecordRepository: gaugeRecordRepository
        )

        await viewModel.loadGaugeRecords()
        let didUnlink = await viewModel.unlinkGaugeRecord(linkedRecord)

        #expect(didUnlink)
        #expect(gaugeRecordRepository.savedRecords.last?.projectId == nil)
        #expect(gaugeRecordRepository.savedRecords.last?.projectNameSnapshot == nil)
        #expect(viewModel.linkedGaugeRecords.isEmpty)
    }

    @Test func loadNeedlesSetsAvailableNeedlesAndAttachedNeedle() async throws {
        let needle = Self.makeNeedle()
        let project = Self.makeProject(
            needleId: needle.id,
            needleNameSnapshot: needle.name,
            needleTypeSnapshot: needle.needleType,
            needleSizeSnapshot: needle.size,
            needleLengthSnapshot: needle.length
        )
        let libraryRepository = LibraryRepositorySpy(needles: [needle])
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: libraryRepository
        )

        await viewModel.loadNeedles()

        #expect(viewModel.availableNeedles == [needle])
        #expect(viewModel.attachedNeedle == needle)
    }

    @Test func attachNeedlePersistsNeedleSnapshot() async throws {
        let needle = Self.makeNeedle()
        let project = Self.makeProject()
        let projectRepository = ProjectRepositorySpy(project: project)
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: projectRepository,
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy(needles: [needle])
        )

        let didAttach = await viewModel.attachNeedle(needle)

        #expect(didAttach)
        #expect(projectRepository.savedProjects.last?.needleId == needle.id)
        #expect(projectRepository.savedProjects.last?.needleNameSnapshot == needle.name)
        #expect(projectRepository.savedProjects.last?.needleTypeSnapshot == needle.needleType)
        #expect(projectRepository.savedProjects.last?.needleSizeSnapshot == needle.size)
        #expect(projectRepository.savedProjects.last?.needleLengthSnapshot == needle.length)
    }

    @Test func unlinkNeedleClearsNeedleSnapshot() async throws {
        let needle = Self.makeNeedle()
        let project = Self.makeProject(
            needleId: needle.id,
            needleNameSnapshot: needle.name,
            needleTypeSnapshot: needle.needleType,
            needleSizeSnapshot: needle.size,
            needleLengthSnapshot: needle.length
        )
        let projectRepository = ProjectRepositorySpy(project: project)
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: projectRepository,
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy(needles: [needle])
        )

        let didUnlink = await viewModel.unlinkNeedle()

        #expect(didUnlink)
        #expect(projectRepository.savedProjects.last?.needleId == nil)
        #expect(projectRepository.savedProjects.last?.needleNameSnapshot == nil)
        #expect(projectRepository.savedProjects.last?.needleTypeSnapshot == nil)
        #expect(projectRepository.savedProjects.last?.needleSizeSnapshot == nil)
        #expect(projectRepository.savedProjects.last?.needleLengthSnapshot == nil)
    }

    @Test func loadToolsSetsAvailableAndLinkedProjectTools() async throws {
        let project = Self.makeProject()
        let availableTool = Self.makeTool()
        let linkedTool = Self.makeTool(
            id: UUID(uuidString: "abababab-abab-4aba-8aba-abababababab")!,
            name: "Measuring Tape"
        )
        let libraryRepository = LibraryRepositorySpy(
            tools: [availableTool, linkedTool],
            projectTools: [project.id: [linkedTool]]
        )
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: libraryRepository
        )

        await viewModel.loadTools()

        #expect(viewModel.availableTools == [availableTool, linkedTool])
        #expect(viewModel.linkedTools == [linkedTool])
        #expect(viewModel.availableToolsForLinking == [availableTool])
    }

    @Test func linkToolConnectsProjectTool() async throws {
        let project = Self.makeProject()
        let tool = Self.makeTool()
        let libraryRepository = LibraryRepositorySpy(tools: [tool])
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: libraryRepository
        )

        await viewModel.loadTools()
        let didLink = await viewModel.linkTool(tool)

        #expect(didLink)
        #expect(libraryRepository.linkedToolIDsByProjectID[project.id] == [tool.id])
        #expect(viewModel.linkedTools.map(\.id) == [tool.id])
        #expect(viewModel.availableToolsForLinking.isEmpty)
    }

    @Test func unlinkToolDisconnectsProjectTool() async throws {
        let project = Self.makeProject()
        let tool = Self.makeTool()
        let libraryRepository = LibraryRepositorySpy(
            tools: [tool],
            projectTools: [project.id: [tool]]
        )
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: libraryRepository
        )

        await viewModel.loadTools()
        let didUnlink = await viewModel.unlinkTool(tool)

        #expect(didUnlink)
        #expect(libraryRepository.unlinkedToolIDsByProjectID[project.id] == [tool.id])
        #expect(viewModel.linkedTools.isEmpty)
        #expect(viewModel.availableToolsForLinking == [tool])
    }

    @Test func loadProgressPhotosSetsProjectPhotos() async throws {
        let project = Self.makeProject()
        let photo = Self.makeProgressPhoto(projectId: project.id)
        let progressPhotoRepository = ProgressPhotoRepositorySpy(photos: [photo])
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy(),
            progressPhotoRepository: progressPhotoRepository
        )

        await viewModel.loadProgressPhotos()

        #expect(progressPhotoRepository.fetchedProjectIDs == [project.id])
        #expect(viewModel.progressPhotos == [photo])
        #expect(viewModel.errorMessage == nil)
    }

    @Test func addProgressPhotoStoresPhotoAndSortsByTakenAtDescending() async throws {
        let project = Self.makeProject()
        let olderPhoto = Self.makeProgressPhoto(
            id: UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!,
            projectId: project.id,
            takenAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let newerPhoto = Self.makeProgressPhoto(
            id: UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!,
            projectId: project.id,
            takenAt: Date(timeIntervalSince1970: 1_800_100_000),
            caption: "Front finished"
        )
        let progressPhotoRepository = ProgressPhotoRepositorySpy(
            photos: [olderPhoto],
            createdPhoto: newerPhoto
        )
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy(),
            progressPhotoRepository: progressPhotoRepository
        )

        await viewModel.loadProgressPhotos()
        let didSave = await viewModel.addProgressPhoto(
            imageData: Data("JPEGDATA".utf8),
            fileName: "front.jpg",
            contentType: "image/jpeg",
            caption: "Front finished",
            takenAt: newerPhoto.takenAt
        )

        #expect(didSave)
        #expect(progressPhotoRepository.createdRequests.count == 1)
        #expect(progressPhotoRepository.createdRequests.first?.projectId == project.id)
        #expect(progressPhotoRepository.createdRequests.first?.caption == "Front finished")
        #expect(viewModel.progressPhotos.map(\.id) == [newerPhoto.id, olderPhoto.id])
    }

    @Test func updateProgressPhotoReplacesExistingPhoto() async throws {
        let project = Self.makeProject()
        let originalPhoto = Self.makeProgressPhoto(projectId: project.id, caption: "Front")
        let updatedPhoto = Self.makeProgressPhoto(
            id: originalPhoto.id,
            projectId: project.id,
            takenAt: Date(timeIntervalSince1970: 1_800_010_000),
            caption: "Front blocked"
        )
        let progressPhotoRepository = ProgressPhotoRepositorySpy(
            photos: [originalPhoto],
            updatedPhoto: updatedPhoto
        )
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy(),
            progressPhotoRepository: progressPhotoRepository
        )

        await viewModel.loadProgressPhotos()
        let didUpdate = await viewModel.updateProgressPhoto(
            originalPhoto,
            caption: "Front blocked",
            takenAt: updatedPhoto.takenAt
        )

        #expect(didUpdate)
        #expect(progressPhotoRepository.updatedRequests.count == 1)
        #expect(progressPhotoRepository.updatedRequests.first?.photo.id == originalPhoto.id)
        #expect(viewModel.progressPhotos == [updatedPhoto])
    }

    @Test func deleteProgressPhotoRemovesPhotoFromWorkspace() async throws {
        let project = Self.makeProject()
        let photo = Self.makeProgressPhoto(projectId: project.id)
        let progressPhotoRepository = ProgressPhotoRepositorySpy(photos: [photo])
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: ProjectRepositorySpy(project: project),
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy(),
            progressPhotoRepository: progressPhotoRepository
        )

        await viewModel.loadProgressPhotos()
        let didDelete = await viewModel.deleteProgressPhoto(photo)

        #expect(didDelete)
        #expect(progressPhotoRepository.deletedPhotoIDs == [photo.id])
        #expect(viewModel.progressPhotos.isEmpty)
    }

    @Test func retrySyncFetchesLatestProjectAndRefreshesWorkspaceState() async throws {
        let pendingProject = Self.makeProject(
            currentRow: 7,
            syncStatus: .pendingUpload
        )
        let syncedProject = pendingProject.copy(
            rowCounter: pendingProject.rowCounter.copy(currentRow: 9),
            syncStatus: .synced
        )
        let repository = ProjectRepositorySpy(project: pendingProject)
        repository.projects = [syncedProject]
        let viewModel = ProjectWorkspaceViewModel(
            project: pendingProject,
            projectRepository: repository,
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy()
        )

        await viewModel.retrySync()

        #expect(repository.fetchProjectCallCount == 1)
        #expect(viewModel.project.syncStatus == .synced)
        #expect(viewModel.currentRow == 9)
        #expect(!viewModel.isRetryingSync)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func incrementRowAppliesFetchedProjectAfterSave() async throws {
        let project = Self.makeProject(currentRow: 4, syncStatus: .localOnly)
        let serverProject = project.copy(
            rowCounter: project.rowCounter.copy(currentRow: 6),
            syncStatus: .synced
        )
        let repository = ProjectRepositorySpy(project: project)
        repository.projectAfterSave = serverProject
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: repository,
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy()
        )

        await viewModel.incrementRow()

        #expect(repository.savedProjects.last?.rowCounter.currentRow == 5)
        #expect(viewModel.currentRow == 6)
        #expect(viewModel.project.syncStatus == .synced)
    }

    @Test func addRowInstructionReturnsFalseAndKeepsRowsWhenRowNumberAlreadyExists() async throws {
        let existingInstruction = Self.makeInstruction(rowNumber: 3, text: "K all", skillTags: "K")
        let project = Self.makeProject(rowInstructions: [existingInstruction])
        let repository = ProjectRepositorySpy(project: project)
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: repository,
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy()
        )

        let didSave = await viewModel.addRowInstruction(
            rowNumber: 3,
            text: "P all",
            skillTags: "P"
        )

        #expect(!didSave)
        #expect(repository.savedProjects.isEmpty)
        #expect(viewModel.rowCounter.rowInstructions.map(\.instructionText) == ["K all"])
        #expect(viewModel.errorMessage == "이미 등록된 행 번호예요.")
    }

    @Test func addBulkRowInstructionsReturnsTrueWhenRowsAreSaved() async throws {
        let project = Self.makeProject(rowInstructions: [])
        let repository = ProjectRepositorySpy(project: project)
        let viewModel = ProjectWorkspaceViewModel(
            project: project,
            projectRepository: repository,
            patternRepository: PatternRepositoryFake(),
            skillRepository: SkillRepositoryFake(),
            libraryRepository: LibraryRepositorySpy()
        )

        let didSave = await viewModel.addBulkRowInstructions(
            startRowNumber: 1,
            lines: "K all\nP all"
        )

        #expect(didSave)
        #expect(viewModel.rowCounter.rowInstructions.map(\.rowNumber) == [1, 2])
        #expect(viewModel.rowCounter.rowInstructions.map(\.instructionText) == ["K all", "P all"])
        #expect(viewModel.errorMessage == nil)
    }

    static func makeProject(
        status: ProjectStatus = .wip,
        currentRow: Int = 4,
        targetRow: Int? = 20,
        patternCopy: ProjectPatternCopy? = nil,
        rowInstructions: [RowInstruction] = [],
        yarnId: UUID? = nil,
        yarnNameSnapshot: String? = nil,
        yarnBrandSnapshot: String? = nil,
        yarnColorwaySnapshot: String? = nil,
        yarnWeightSnapshot: String? = nil,
        needleId: UUID? = nil,
        needleNameSnapshot: String? = nil,
        needleTypeSnapshot: String? = nil,
        needleSizeSnapshot: String? = nil,
        needleLengthSnapshot: String? = nil,
        workSessions: [WorkSession] = [],
        syncStatus: SyncStatus = .synced
    ) -> KnittingProject {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let projectID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
        let rowCounter = RowCounter(
            id: UUID(uuidString: "22222222-2222-4222-8222-222222222222")!,
            ownerId: "user-a",
            projectId: projectID,
            name: "Main Counter",
            mode: rowInstructions.isEmpty ? .simple : .rowGuide,
            sectionName: "Body",
            memo: "Keep marker at side seam.",
            currentRow: currentRow,
            targetRow: targetRow,
            rowInstructions: rowInstructions,
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )

        return KnittingProject(
            id: projectID,
            ownerId: "user-a",
            name: "Favorite Cardigan",
            status: status,
            isFavorite: true,
            memo: "Use smaller needles for ribbing.",
            startDate: now,
            lastWorkedAt: now,
            patternCopy: patternCopy,
            yarnId: yarnId,
            yarnNameSnapshot: yarnNameSnapshot,
            yarnBrandSnapshot: yarnBrandSnapshot,
            yarnColorwaySnapshot: yarnColorwaySnapshot,
            yarnWeightSnapshot: yarnWeightSnapshot,
            needleId: needleId,
            needleNameSnapshot: needleNameSnapshot,
            needleTypeSnapshot: needleTypeSnapshot,
            needleSizeSnapshot: needleSizeSnapshot,
            needleLengthSnapshot: needleLengthSnapshot,
            rowCounter: rowCounter,
            workSessions: workSessions,
            createdAt: now,
            updatedAt: now,
            syncStatus: syncStatus
        )
    }

    static func makeInstruction(
        rowNumber: Int,
        text: String,
        skillTags: String
    ) -> RowInstruction {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        return RowInstruction(
            id: UUID(),
            ownerId: "user-a",
            projectId: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            rowCounterId: UUID(uuidString: "22222222-2222-4222-8222-222222222222")!,
            rowNumber: rowNumber,
            instructionText: text,
            skillTags: skillTags,
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
    }

    static func makeWorkSession(
        id: UUID = UUID(uuidString: "77777777-7777-4777-8777-777777777777")!,
        startedAt: Date = Date(timeIntervalSince1970: 1_800_000_000),
        endedAt: Date? = Date(timeIntervalSince1970: 1_800_003_600),
        memo: String? = "Body"
    ) -> WorkSession {
        WorkSession(
            id: id,
            ownerId: "user-a",
            projectId: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            startedAt: startedAt,
            endedAt: endedAt,
            memo: memo,
            createdAt: startedAt,
            updatedAt: endedAt ?? startedAt,
            syncStatus: .synced
        )
    }

    static func makeGaugeRecord(
        id: UUID = UUID(uuidString: "88888888-8888-4888-8888-888888888888")!,
        projectId: UUID? = nil,
        measuredAt: Date = Date(timeIntervalSince1970: 1_800_000_000)
    ) -> GaugeRecord {
        GaugeRecord(
            id: id,
            ownerId: "user-a",
            projectId: projectId,
            projectNameSnapshot: projectId == nil ? nil : "Favorite Cardigan",
            patternNameSnapshot: nil,
            measurementStage: .beforeWash,
            sampleWidthCm: 10,
            sampleHeightCm: 10,
            stitchCount: 22,
            rowCount: 30,
            targetWidthCm: 50,
            targetHeightCm: 60,
            stitchesPer10Cm: 22,
            rowsPer10Cm: 30,
            targetStitches: 110,
            targetRows: 180,
            needle: "4.0 mm",
            memo: "Main gauge",
            measuredAt: measuredAt,
            createdAt: measuredAt,
            updatedAt: measuredAt,
            syncStatus: .synced
        )
    }

    nonisolated static func makePatternDocument(
        id: UUID = UUID(uuidString: "abababab-abab-4aba-8aba-abababababab")!,
        title: String = "Stored Pattern",
        fileName: String? = "stored-pattern.pdf"
    ) -> PatternDocument {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        return PatternDocument(
            id: id,
            ownerId: "user-a",
            title: title,
            designer: "Sample Designer",
            fileName: fileName,
            localFilePath: fileName,
            pageCount: 4,
            notes: "Stored pattern notes",
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
    }

    nonisolated static func makePatternCopy(
        sourcePatternDocumentId: UUID? = nil,
        title: String = "Manual Pattern",
        fileName: String? = nil
    ) -> ProjectPatternCopy {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        return ProjectPatternCopy(
            id: UUID(uuidString: "33333333-3333-4333-8333-333333333333")!,
            ownerId: "user-a",
            projectId: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            sourcePatternDocumentId: sourcePatternDocumentId,
            titleSnapshot: title,
            designerSnapshot: nil,
            fileNameSnapshot: fileName,
            localCopyPath: nil,
            pageCountSnapshot: nil,
            drawingDataPath: "drawing.pkdrawing",
            drawingUpdatedAt: now,
            copiedAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
    }

#if canImport(UIKit)
    static func makeTemporaryPDF(containing text: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 320, height: 240))
        try renderer.writePDF(to: url) { context in
            context.beginPage()
            (text as NSString).draw(
                at: CGPoint(x: 24, y: 24),
                withAttributes: [.font: UIFont.systemFont(ofSize: 14)]
            )
        }
        return url
    }

    static func makeTemporaryImagePDF(containing text: String) throws -> URL {
        let imageRenderer = UIGraphicsImageRenderer(size: CGSize(width: 1_000, height: 360))
        let image = imageRenderer.image { _ in
            UIColor.white.setFill()
            UIBezierPath(rect: CGRect(x: 0, y: 0, width: 1_000, height: 360)).fill()
            (text as NSString).draw(
                at: CGPoint(x: 72, y: 118),
                withAttributes: [
                    .font: UIFont.boldSystemFont(ofSize: 84),
                    .foregroundColor: UIColor.black
                ]
            )
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 1_000, height: 360))
        try renderer.writePDF(to: url) { context in
            context.beginPage()
            image.draw(in: CGRect(x: 0, y: 0, width: 1_000, height: 360))
        }
        return url
    }
#endif

    static func makeSkill(
        abbreviation: String,
        difficulty: String,
        userLevel: String? = nil
    ) -> Skill {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        return Skill(
            ownerId: "user-a",
            name: "\(abbreviation) stitch",
            abbreviation: abbreviation,
            description: "Test skill",
            category: "Basic",
            difficulty: difficulty,
            userLevel: userLevel,
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
    }

    static func makeYarn(
        id: UUID = UUID(uuidString: "cccccccc-cccc-4ccc-8ccc-cccccccccccc")!,
        quantity: Int = 5
    ) -> Yarn {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        return Yarn(
            id: id,
            ownerId: "user-a",
            name: "Soft Merino DK",
            brand: "Sample Yarn Co.",
            colorway: "Cloud Gray",
            weight: "DK",
            quantity: quantity,
            notes: "Reserved for cardigan.",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: .synced
        )
    }

    static func makeNeedle(
        id: UUID = UUID(uuidString: "dddddddd-dddd-4ddd-8ddd-dddddddddddd")!
    ) -> Needle {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        return Needle(
            id: id,
            ownerId: "user-a",
            name: "ChiaoGoo Red Lace",
            needleType: "Circular",
            size: "4.0 mm",
            length: "80 cm",
            notes: "Main body needle",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: .synced
        )
    }

    static func makeTool(
        id: UUID = UUID(uuidString: "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee")!,
        name: String = "Locking Marker Set"
    ) -> ToolItem {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        return ToolItem(
            id: id,
            ownerId: "user-a",
            name: name,
            type: "Marker",
            link: "example.com/marker",
            memo: "Raglan increases.",
            createdAt: now,
            updatedAt: now,
            deletedAt: nil,
            syncStatus: .synced
        )
    }

    static func makeProgressPhoto(
        id: UUID = UUID(uuidString: "12121212-1212-4212-8212-121212121212")!,
        projectId: UUID,
        takenAt: Date = Date(timeIntervalSince1970: 1_800_000_000),
        caption: String = "Front panel"
    ) -> ProjectProgressPhoto {
        ProjectProgressPhoto(
            id: id,
            ownerId: "user-a",
            projectId: projectId,
            fileName: "front.jpg",
            contentType: "image/jpeg",
            byteSize: 8,
            localFilePath: "Projects/\(projectId.uuidString)/ProgressPhotos/\(id.uuidString)/front.jpg",
            caption: caption,
            takenAt: takenAt,
            createdAt: takenAt,
            updatedAt: takenAt,
            deletedAt: nil,
            syncStatus: .synced
        )
    }

    static func makeYarnUsage(
        id: UUID = UUID(uuidString: "99999999-9999-4999-8999-999999999999")!,
        yarnId: UUID,
        quantityUsed: Int = 2,
        memo: String = "Sleeve swatch"
    ) -> ProjectYarnUsage {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        return ProjectYarnUsage(
            id: id,
            ownerId: "user-a",
            projectId: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!,
            yarnId: yarnId,
            yarnNameSnapshot: "Soft Merino DK",
            quantityUsed: quantityUsed,
            memo: memo,
            usedAt: now,
            createdAt: now,
            updatedAt: now,
            syncStatus: .synced
        )
    }

    final class ProjectRepositorySpy: ProjectRepository {
        var projects: [KnittingProject]
        var projectAfterSave: KnittingProject?
        var saveError: Error?
        var savedProjects: [KnittingProject] = []
        var fetchProjectCallCount = 0

        init(project: KnittingProject) {
            projects = [project]
        }

        func fetchProjects() async throws -> [KnittingProject] {
            projects
        }

        func fetchProject(id: UUID) async throws -> KnittingProject? {
            fetchProjectCallCount += 1
            return projects.first { $0.id == id }
        }

        func saveProject(_ project: KnittingProject) async throws {
            if let saveError {
                throw saveError
            }

            savedProjects.append(project)
            let storedProject = projectAfterSave ?? project
            storeProject(storedProject)
        }

        func deleteProject(id: UUID) async throws {
            projects.removeAll { $0.id == id }
        }

        func saveRowCounter(_ rowCounter: RowCounter, forProjectId projectId: UUID) async throws -> RowCounter {
            if let saveError {
                throw saveError
            }

            guard let project = projects.first(where: { $0.id == projectId }) else {
                throw APIError.requestFailed(
                    statusCode: 404,
                    code: "PROJECT_NOT_FOUND",
                    message: "Project not found."
                )
            }

            let savedProject = project.copy(rowCounter: rowCounter)
            savedProjects.append(savedProject)
            let storedProject = projectAfterSave ?? savedProject
            storeProject(storedProject)
            return storedProject.rowCounter
        }

        func saveWorkSession(_ session: WorkSession, forProjectId projectId: UUID) async throws -> WorkSession {
            if let saveError {
                throw saveError
            }

            guard let project = projects.first(where: { $0.id == projectId }) else {
                throw APIError.requestFailed(
                    statusCode: 404,
                    code: "PROJECT_NOT_FOUND",
                    message: "Project not found."
                )
            }

            let updatedSessions: [WorkSession]
            if project.workSessions.contains(where: { $0.id == session.id }) {
                updatedSessions = project.workSessions.map { $0.id == session.id ? session : $0 }
            } else {
                updatedSessions = project.workSessions + [session]
            }

            let savedProject = project.copy(workSessions: updatedSessions)
            savedProjects.append(savedProject)
            let storedProject = projectAfterSave ?? savedProject
            storeProject(storedProject)
            return storedProject.workSessions.first { $0.id == session.id } ?? session
        }

        func deleteWorkSession(id: UUID, forProjectId projectId: UUID) async throws {
            if let saveError {
                throw saveError
            }

            guard let project = projects.first(where: { $0.id == projectId }) else {
                throw APIError.requestFailed(
                    statusCode: 404,
                    code: "PROJECT_NOT_FOUND",
                    message: "Project not found."
                )
            }

            let savedProject = project.copy(workSessions: project.workSessions.filter { $0.id != id })
            savedProjects.append(savedProject)
            storeProject(projectAfterSave ?? savedProject)
        }

        private func storeProject(_ project: KnittingProject) {
            if let index = projects.firstIndex(where: { $0.id == project.id }) {
                projects[index] = project
            } else {
                projects.append(project)
            }
        }
    }

    final class GaugeRecordRepositorySpy: GaugeRecordRepository {
        var records: [GaugeRecord]
        var savedRecords: [GaugeRecord] = []
        var updatedRecords: [GaugeRecord] = []
        var deletedRecordIDs: [UUID] = []
        var saveError: Error?

        init(records: [GaugeRecord] = []) {
            self.records = records
        }

        func fetchGaugeRecords() async throws -> [GaugeRecord] {
            records
        }

        func saveGaugeRecord(_ record: GaugeRecord) async throws -> GaugeRecord {
            if let saveError {
                throw saveError
            }

            savedRecords.append(record)
            if let index = records.firstIndex(where: { $0.id == record.id }) {
                records[index] = record
            } else {
                records.append(record)
            }
            return record
        }

        func updateGaugeRecord(_ record: GaugeRecord) async throws -> GaugeRecord {
            if let saveError {
                throw saveError
            }

            updatedRecords.append(record)
            if let index = records.firstIndex(where: { $0.id == record.id }) {
                records[index] = record
            } else {
                records.append(record)
            }
            return record
        }

        func deleteGaugeRecord(id: UUID) async throws {
            deletedRecordIDs.append(id)
            records.removeAll { $0.id == id }
        }
    }

    final class ProgressPhotoRepositorySpy: ProjectProgressPhotoRepository {
        struct CreatedRequest {
            let projectId: UUID
            let imageData: Data
            let fileName: String
            let contentType: String
            let caption: String
            let takenAt: Date
        }

        struct UpdatedRequest {
            let photo: ProjectProgressPhoto
            let caption: String
            let takenAt: Date
        }

        var photos: [ProjectProgressPhoto]
        var createdPhoto: ProjectProgressPhoto?
        var updatedPhoto: ProjectProgressPhoto?
        var fetchedProjectIDs: [UUID] = []
        var createdRequests: [CreatedRequest] = []
        var updatedRequests: [UpdatedRequest] = []
        var deletedPhotoIDs: [UUID] = []

        init(
            photos: [ProjectProgressPhoto] = [],
            createdPhoto: ProjectProgressPhoto? = nil,
            updatedPhoto: ProjectProgressPhoto? = nil
        ) {
            self.photos = photos
            self.createdPhoto = createdPhoto
            self.updatedPhoto = updatedPhoto
        }

        func fetchProgressPhotos(projectId: UUID) async throws -> [ProjectProgressPhoto] {
            fetchedProjectIDs.append(projectId)
            return photos.filter { $0.projectId == projectId }
        }

        func createProgressPhoto(
            projectId: UUID,
            imageData: Data,
            fileName: String,
            contentType: String,
            caption: String,
            takenAt: Date
        ) async throws -> ProjectProgressPhoto {
            createdRequests.append(
                CreatedRequest(
                    projectId: projectId,
                    imageData: imageData,
                    fileName: fileName,
                    contentType: contentType,
                    caption: caption,
                    takenAt: takenAt
                )
            )

            let photo = createdPhoto ?? makeProgressPhoto(
                projectId: projectId,
                takenAt: takenAt,
                caption: caption
            )
            photos.append(photo)
            return photo
        }

        func updateProgressPhoto(
            _ photo: ProjectProgressPhoto,
            caption: String,
            takenAt: Date
        ) async throws -> ProjectProgressPhoto {
            updatedRequests.append(UpdatedRequest(photo: photo, caption: caption, takenAt: takenAt))
            let photo = updatedPhoto ?? makeProgressPhoto(
                id: photo.id,
                projectId: photo.projectId,
                takenAt: takenAt,
                caption: caption
            )

            if let index = photos.firstIndex(where: { $0.id == photo.id }) {
                photos[index] = photo
            } else {
                photos.append(photo)
            }

            return photo
        }

        func deleteProgressPhoto(_ photo: ProjectProgressPhoto) async throws {
            deletedPhotoIDs.append(photo.id)
            photos.removeAll { $0.id == photo.id }
        }

        func fileURL(for photo: ProjectProgressPhoto) -> URL? {
            URL(fileURLWithPath: photo.localFilePath ?? "")
        }
    }

    struct PatternRepositoryFake: PatternRepository {
        var patternCopyFileURLs: [UUID: URL] = [:]

        func fetchPatterns() async throws -> [PatternDocument] {
            []
        }

        func fetchPattern(id: UUID) async throws -> PatternDocument? {
            nil
        }

        func savePattern(_ pattern: PatternDocument) async throws {
        }

        func deletePattern(id: UUID) async throws {
        }

        func createPattern(fromFileAt fileURL: URL) async throws -> PatternDocument {
            throw TestRepositoryError.unsupported
        }

        func createPattern(titled title: String, designer: String?, notes: String) async throws -> PatternDocument {
            throw TestRepositoryError.unsupported
        }

        func attachPatternFile(fromFileAt fileURL: URL, to pattern: PatternDocument) async throws -> PatternDocument {
            throw TestRepositoryError.unsupported
        }

        func importPattern(_ pattern: PatternDocument, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
            throw TestRepositoryError.unsupported
        }

        func createProjectPatternCopy(fromFileAt fileURL: URL, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
            throw TestRepositoryError.unsupported
        }

        func fileURL(for pattern: PatternDocument) -> URL? {
            nil
        }

        func fileURL(for patternCopy: ProjectPatternCopy) -> URL? {
            patternCopyFileURLs[patternCopy.id]
        }

        func drawingData(for patternCopy: ProjectPatternCopy) async throws -> Data? {
            nil
        }

        func saveDrawingData(_ data: Data, for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy {
            patternCopy
        }

        func deleteDrawingData(for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy {
            patternCopy.updatingDrawingDataPath(nil)
        }
    }

    @MainActor
    final class PatternRepositorySpy: PatternRepository {
        var patterns: [PatternDocument]
        var patternCopyFileURLs: [UUID: URL]
        var storedPattern: PatternDocument
        var importedCopy: ProjectPatternCopy
        var projectOnlyCopy: ProjectPatternCopy
        var createdPatternFileURLs: [URL] = []
        var createdProjectOnlyFileURLs: [URL] = []
        var importedPatternIDs: [UUID] = []

        init(
            patterns: [PatternDocument] = [],
            patternCopyFileURLs: [UUID: URL] = [:],
            storedPattern: PatternDocument = makePatternDocument(),
            importedCopy: ProjectPatternCopy = makePatternCopy(),
            projectOnlyCopy: ProjectPatternCopy = makePatternCopy()
        ) {
            self.patterns = patterns
            self.patternCopyFileURLs = patternCopyFileURLs
            self.storedPattern = storedPattern
            self.importedCopy = importedCopy
            self.projectOnlyCopy = projectOnlyCopy
        }

        func fetchPatterns() async throws -> [PatternDocument] {
            patterns
        }

        func fetchPattern(id: UUID) async throws -> PatternDocument? {
            patterns.first { $0.id == id }
        }

        func savePattern(_ pattern: PatternDocument) async throws {
            if let index = patterns.firstIndex(where: { $0.id == pattern.id }) {
                patterns[index] = pattern
            } else {
                patterns.append(pattern)
            }
        }

        func deletePattern(id: UUID) async throws {
            patterns.removeAll { $0.id == id }
        }

        func createPattern(fromFileAt fileURL: URL) async throws -> PatternDocument {
            createdPatternFileURLs.append(fileURL)
            if patterns.contains(where: { $0.id == storedPattern.id }) == false {
                patterns.append(storedPattern)
            }
            return storedPattern
        }

        func createPattern(titled title: String, designer: String?, notes: String) async throws -> PatternDocument {
            fatalError("Not needed in this test")
        }

        func attachPatternFile(fromFileAt fileURL: URL, to pattern: PatternDocument) async throws -> PatternDocument {
            fatalError("Not needed in this test")
        }

        func importPattern(_ pattern: PatternDocument, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
            importedPatternIDs.append(pattern.id)
            return importedCopy
        }

        func createProjectPatternCopy(fromFileAt fileURL: URL, forProjectId projectId: UUID) async throws -> ProjectPatternCopy {
            createdProjectOnlyFileURLs.append(fileURL)
            return projectOnlyCopy
        }

        func fileURL(for pattern: PatternDocument) -> URL? {
            pattern.localFilePath.map(URL.init(fileURLWithPath:))
        }

        func fileURL(for patternCopy: ProjectPatternCopy) -> URL? {
            patternCopyFileURLs[patternCopy.id]
        }

        func drawingData(for patternCopy: ProjectPatternCopy) async throws -> Data? {
            nil
        }

        func saveDrawingData(_ data: Data, for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy {
            patternCopy
        }

        func deleteDrawingData(for patternCopy: ProjectPatternCopy) async throws -> ProjectPatternCopy {
            patternCopy.updatingDrawingDataPath(nil)
        }
    }

    struct SkillRepositoryFake: SkillRepository {
        var skills: [Skill] = []

        func fetchSkills() async throws -> [Skill] {
            skills
        }

        func fetchSkill(id: UUID) async throws -> Skill? {
            skills.first { $0.id == id }
        }

        func saveSkill(_ skill: Skill) async throws {
        }

        func deleteSkill(id: UUID) async throws {
        }

        func fetchSkillAnimations() async throws -> [SkillAnimation] {
            []
        }
    }

    final class LibraryRepositorySpy: LibraryRepository {
        var yarns: [Yarn]
        var needles: [Needle]
        var tools: [ToolItem]
        var projectTools: [UUID: [ToolItem]]
        var yarnUsages: [ProjectYarnUsage]
        var recordedYarnUsages: [ProjectYarnUsage] = []
        var updatedYarnUsages: [ProjectYarnUsage] = []
        var deletedYarnUsages: [UUID] = []
        var linkedToolIDsByProjectID: [UUID: [UUID]] = [:]
        var unlinkedToolIDsByProjectID: [UUID: [UUID]] = [:]

        init(
            yarns: [Yarn] = [],
            needles: [Needle] = [],
            tools: [ToolItem] = [],
            projectTools: [UUID: [ToolItem]] = [:],
            yarnUsages: [ProjectYarnUsage] = []
        ) {
            self.yarns = yarns
            self.needles = needles
            self.tools = tools
            self.projectTools = projectTools
            self.yarnUsages = yarnUsages
        }

        func fetchYarns() async throws -> [Yarn] {
            yarns
        }

        func saveYarn(_ yarn: Yarn) async throws {
            if let index = yarns.firstIndex(where: { $0.id == yarn.id }) {
                yarns[index] = yarn
            } else {
                yarns.append(yarn)
            }
        }

        func deleteYarn(id: UUID) async throws {
            yarns.removeAll { $0.id == id }
        }

        func fetchNeedles() async throws -> [Needle] {
            needles
        }

        func saveNeedle(_ needle: Needle) async throws {
            if let index = needles.firstIndex(where: { $0.id == needle.id }) {
                needles[index] = needle
            } else {
                needles.append(needle)
            }
        }

        func deleteNeedle(id: UUID) async throws {
            needles.removeAll { $0.id == id }
        }

        func fetchTools() async throws -> [ToolItem] {
            tools
        }

        func saveTool(_ tool: ToolItem) async throws {
            if let index = tools.firstIndex(where: { $0.id == tool.id }) {
                tools[index] = tool
            } else {
                tools.append(tool)
            }
        }

        func deleteTool(id: UUID) async throws {
            tools.removeAll { $0.id == id }
            for projectId in projectTools.keys {
                projectTools[projectId]?.removeAll { $0.id == id }
            }
        }

        func fetchTools(forProjectId projectId: UUID) async throws -> [ToolItem] {
            projectTools[projectId] ?? []
        }

        func linkTool(_ tool: ToolItem, toProjectId projectId: UUID) async throws -> ToolItem {
            linkedToolIDsByProjectID[projectId, default: []].append(tool.id)

            if projectTools[projectId, default: []].contains(where: { $0.id == tool.id }) == false {
                projectTools[projectId, default: []].append(tool)
            }

            return tool
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
            unlinkedToolIDsByProjectID[projectId, default: []].append(tool.id)
            projectTools[projectId]?.removeAll { $0.id == tool.id }
        }

        func fetchYarnUsages(forProjectId projectId: UUID) async throws -> [ProjectYarnUsage] {
            yarnUsages.filter { $0.projectId == projectId }
        }

        func fetchYarnUsages(forYarnId yarnId: UUID) async throws -> [ProjectYarnUsage] {
            yarnUsages.filter { $0.yarnId == yarnId }
        }

        func recordYarnUsage(_ usage: ProjectYarnUsage) async throws -> ProjectYarnUsage {
            recordedYarnUsages.append(usage)
            yarnUsages.insert(usage, at: 0)

            if let index = yarns.firstIndex(where: { $0.id == usage.yarnId }) {
                let yarn = yarns[index]
                yarns[index] = Yarn(
                    id: yarn.id,
                    ownerId: yarn.ownerId,
                    name: yarn.name,
                    brand: yarn.brand,
                    colorway: yarn.colorway,
                    weight: yarn.weight,
                    quantity: max(0, yarn.quantity - usage.quantityUsed),
                    notes: yarn.notes,
                    createdAt: yarn.createdAt,
                    updatedAt: usage.createdAt,
                    deletedAt: yarn.deletedAt,
                    syncStatus: yarn.syncStatus
                )
            }

            return usage
        }

        func updateYarnUsage(_ usage: ProjectYarnUsage) async throws -> ProjectYarnUsage {
            updatedYarnUsages.append(usage)

            guard let usageIndex = yarnUsages.firstIndex(where: { $0.id == usage.id }) else {
                yarnUsages.insert(usage, at: 0)
                return usage
            }

            let originalUsage = yarnUsages[usageIndex]
            yarnUsages[usageIndex] = usage
            adjustYarnQuantity(
                yarnId: usage.yarnId,
                delta: originalUsage.quantityUsed - usage.quantityUsed,
                updatedAt: usage.updatedAt
            )

            return usage
        }

        func deleteYarnUsage(_ usage: ProjectYarnUsage) async throws {
            deletedYarnUsages.append(usage.id)
            yarnUsages.removeAll { $0.id == usage.id }
            adjustYarnQuantity(
                yarnId: usage.yarnId,
                delta: usage.quantityUsed,
                updatedAt: Date()
            )
        }

        @MainActor
        private func adjustYarnQuantity(yarnId: UUID, delta: Int, updatedAt: Date) {
            guard let index = yarns.firstIndex(where: { $0.id == yarnId }) else {
                return
            }

            let yarn = yarns[index]
            yarns[index] = Yarn(
                id: yarn.id,
                ownerId: yarn.ownerId,
                name: yarn.name,
                brand: yarn.brand,
                colorway: yarn.colorway,
                weight: yarn.weight,
                quantity: max(0, yarn.quantity + delta),
                notes: yarn.notes,
                createdAt: yarn.createdAt,
                updatedAt: updatedAt,
                deletedAt: yarn.deletedAt,
                syncStatus: yarn.syncStatus
            )
        }
    }

    enum TestRepositoryError: Error {
        case unsupported
    }
}
