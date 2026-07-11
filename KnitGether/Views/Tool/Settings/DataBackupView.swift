import SwiftUI
import UniformTypeIdentifiers

struct DataBackupView: View {
    @StateObject private var viewModel: DataBackupExportViewModel
    @StateObject private var importViewModel: DataBackupImportViewModel

    private let sessionStore: AuthSessionStore
    @State private var session: AuthSession?
    @State private var isShowingImportPicker = false

    init(
        sessionStore: AuthSessionStore,
        profileRepository: any ProfileRepository,
        projectRepository: any ProjectRepository,
        patternRepository: any PatternRepository,
        libraryRepository: any LibraryRepository,
        skillRepository: any SkillRepository,
        dictionaryRepository: any DictionaryRepository,
        gaugeRecordRepository: any GaugeRecordRepository,
        progressPhotoRepository: any ProjectProgressPhotoRepository
    ) {
        _viewModel = StateObject(
            wrappedValue: DataBackupExportViewModel(
                profileRepository: profileRepository,
                projectRepository: projectRepository,
                patternRepository: patternRepository,
                libraryRepository: libraryRepository,
                skillRepository: skillRepository,
                dictionaryRepository: dictionaryRepository,
                gaugeRecordRepository: gaugeRecordRepository,
                progressPhotoRepository: progressPhotoRepository
            )
        )
        _importViewModel = StateObject(
            wrappedValue: DataBackupImportViewModel(
                profileRepository: profileRepository,
                projectRepository: projectRepository,
                patternRepository: patternRepository,
                libraryRepository: libraryRepository,
                skillRepository: skillRepository,
                dictionaryRepository: dictionaryRepository,
                gaugeRecordRepository: gaugeRecordRepository,
                progressPhotoRepository: progressPhotoRepository
            )
        )
        self.sessionStore = sessionStore
    }

    var body: some View {
        List {
            Section {
                syncStatusRow
            }
            .listRowStyle()

            Section("백업 파일") {
                Button {
                    Task {
                        await viewModel.exportBackup()
                    }
                } label: {
                    Label(viewModel.isExporting ? "백업 생성 중" : "백업 파일 만들기", systemImage: "square.and.arrow.down")
                }
                .disabled(viewModel.isExporting)

                if let backupFileURL = viewModel.backupFileURL {
                    ShareLink(item: backupFileURL) {
                        Label("백업 파일 저장/공유", systemImage: "square.and.arrow.up")
                    }
                }

                Button {
                    isShowingImportPicker = true
                } label: {
                    Label(importViewModel.isImporting ? "백업 가져오는 중" : "백업 파일 가져오기", systemImage: "square.and.arrow.down.on.square")
                }
                .disabled(importViewModel.isImporting)

                if let statusMessage = viewModel.statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if let statusMessage = importViewModel.statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage = importViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .listRowStyle()

            Section("계정 저장 범위") {
                syncScopeRow(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    title: "서버에 저장",
                    detail: "프로젝트, 도안 메타데이터, 행안내, 작업시간, 실·바늘·도구, 게이지 기록, 스킬, 사전 용어"
                )
                syncScopeRow(
                    icon: "externaldrive.fill",
                    color: .orange,
                    title: "로컬 파일 캐시",
                    detail: "PDF, 진행 사진, 도안 그리기 데이터는 서버에 저장한 뒤 기기 캐시에 다시 내려받습니다."
                )
                syncScopeRow(
                    icon: "wifi.slash",
                    color: .secondary,
                    title: "오프라인 동작",
                    detail: "MVP에서는 서버 연결이 필요합니다. 서버가 꺼져 있으면 새로고침하거나 연결 후 다시 저장해 주세요."
                )
            }
            .listRowStyle()

            Section("저장 정보") {
                LabeledContent("서버 API", value: "NestJS / PostgreSQL")
                LabeledContent("iOS 캐시", value: "Application Support/KnitGether")
                LabeledContent("파일 캐시", value: "RemoteCaches 하위 폴더")
            }
            .listRowStyle()
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.Color.warmBackground)
        .navigationTitle("데이터 백업")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            session = sessionStore.currentSession
        }
        .fileImporter(
            isPresented: $isShowingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportPickerResult(result)
        }
    }

    private var syncStatusRow: some View {
        HStack(spacing: 14) {
            Image(systemName: session == nil ? "person.crop.circle.badge.exclamationmark" : "checkmark.icloud.fill")
                .font(.title2)
                .foregroundStyle(session == nil ? .orange : .green)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(session == nil ? "로그인 정보 없음" : "계정 저장 사용 중")
                    .font(.subheadline.bold())
                Text(session == nil
                     ? "개발 토큰 또는 로그인 후 서버 저장 상태를 확인할 수 있어요."
                     : "현재 계정 기준으로 API 서버에 데이터를 저장합니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func syncScopeRow(
        icon: String,
        color: Color,
        title: String,
        detail: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func handleImportPickerResult(_ result: Result<[URL], Error>) {
        do {
            guard let fileURL = try result.get().first else {
                return
            }

            Task {
                await importViewModel.importBackup(from: fileURL)
            }
        } catch {
            importViewModel.markImportSelectionFailed()
        }
    }
}
