import SwiftUI

struct SettingsDataCounts: Hashable {
    let projectCount: Int
    let patternCount: Int
    let yarnCount: Int
    let needleCount: Int
    let toolCount: Int
    let skillCount: Int
    let dictionaryTermCount: Int
    let gaugeRecordCount: Int
    let workSessionCount: Int
    let progressPhotoCount: Int
}

struct DataManagementView: View {
    private let projectRepository: any ProjectRepository
    private let patternRepository: any PatternRepository
    private let libraryRepository: any LibraryRepository
    private let skillRepository: any SkillRepository
    private let dictionaryRepository: any DictionaryRepository
    private let gaugeRecordRepository: any GaugeRecordRepository
    private let progressPhotoRepository: any ProjectProgressPhotoRepository

    @State private var counts: SettingsDataCounts?
    @State private var errorMessage: String?

    init(
        projectRepository: any ProjectRepository,
        patternRepository: any PatternRepository,
        libraryRepository: any LibraryRepository,
        skillRepository: any SkillRepository,
        dictionaryRepository: any DictionaryRepository,
        gaugeRecordRepository: any GaugeRecordRepository,
        progressPhotoRepository: any ProjectProgressPhotoRepository
    ) {
        self.projectRepository = projectRepository
        self.patternRepository = patternRepository
        self.libraryRepository = libraryRepository
        self.skillRepository = skillRepository
        self.dictionaryRepository = dictionaryRepository
        self.gaugeRecordRepository = gaugeRecordRepository
        self.progressPhotoRepository = progressPhotoRepository
    }

    var body: some View {
        List {
            Section {
                Text("현재 계정 또는 로컬 캐시에 저장된 주요 데이터 개수를 확인합니다.")
                    .foregroundStyle(.secondary)
            }
            .listRowStyle()

            Section("데이터 개수") {
                if let counts {
                    LabeledContent("뜨개 프로젝트", value: "\(counts.projectCount)개")
                    LabeledContent("도안", value: "\(counts.patternCount)개")
                    LabeledContent("실", value: "\(counts.yarnCount)개")
                    LabeledContent("바늘", value: "\(counts.needleCount)개")
                    LabeledContent("도구", value: "\(counts.toolCount)개")
                    LabeledContent("스킬", value: "\(counts.skillCount)개")
                    LabeledContent("사전 용어", value: "\(counts.dictionaryTermCount)개")
                    LabeledContent("게이지 기록", value: "\(counts.gaugeRecordCount)개")
                    LabeledContent("작업시간 기록", value: "\(counts.workSessionCount)개")
                    LabeledContent("진행 사진", value: "\(counts.progressPhotoCount)개")
                } else {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("데이터 개수를 불러오는 중이에요.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listRowStyle()

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
                .listRowStyle()
            }

            Section {
                Text("전체 초기화와 계정 전환 캐시 정리는 출시 전 별도 안전장치와 함께 추가해야 합니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .listRowStyle()
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.Color.warmBackground)
        .navigationTitle("데이터 관리")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCounts()
        }
        .refreshable {
            await loadCounts()
        }
    }

    private func loadCounts() async {
        do {
            let projects = try await projectRepository.fetchProjects()
            let patterns = try await patternRepository.fetchPatterns()
            let yarns = try await libraryRepository.fetchYarns()
            let needles = try await libraryRepository.fetchNeedles()
            let tools = try await libraryRepository.fetchTools()
            let skills = try await skillRepository.fetchSkills()
            let terms = try await dictionaryRepository.fetchTerms()
            let gaugeRecords = try await gaugeRecordRepository.fetchGaugeRecords()
            var progressPhotoCount = 0
            for project in projects {
                progressPhotoCount += (try? await progressPhotoRepository.fetchProgressPhotos(projectId: project.id).count) ?? 0
            }

            counts = SettingsDataCounts(
                projectCount: projects.count,
                patternCount: patterns.count,
                yarnCount: yarns.count,
                needleCount: needles.count,
                toolCount: tools.count,
                skillCount: skills.count,
                dictionaryTermCount: terms.count,
                gaugeRecordCount: gaugeRecords.count,
                workSessionCount: projects.reduce(0) { $0 + $1.workSessions.count },
                progressPhotoCount: progressPhotoCount
            )
            errorMessage = nil
        } catch {
            errorMessage = "데이터 개수를 불러오지 못했어요."
        }
    }
}
