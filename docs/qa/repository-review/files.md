# 파일별 검토 목록

2026-10-04 기준 공개 커밋 `be4aab5`의 588개 파일과 이번에 추가한 문서 및 생성 도구 3개를 포함한 목록입니다. 비공개 작업 노트와 미반영 학습 편집은 제외했습니다.

텍스트 파일은 전문을 읽어 검색하고 발견한 표현의 문맥을 검토했습니다. 모든 Swift 및 TypeScript 행의 기능 정확성을 검증했다는 뜻은 아닙니다. 이미지 48장은 축소 화면으로 전체 구성을 확인했고, PDF 13개는 전체 페이지의 텍스트를 추출했습니다. 앱 번들 PDF 교체본은 40쪽 전부 렌더링했습니다. 상세 발견 사항과 검증 범위는 [검토 결과](README.md)에 있습니다.

| 파일 | 확인 방법 |
|---|---|
| [.gitattributes](../../../.gitattributes) | 전체 텍스트 검색 |
| [.github/workflows/ci.yml](../../../.github/workflows/ci.yml) | 전체 텍스트 검색 |
| [.github/workflows/qa-gate.yml](../../../.github/workflows/qa-gate.yml) | 전체 텍스트 검색 |
| [.gitignore](../../../.gitignore) | 전체 텍스트 검색 |
| [KnitGether-Info.plist](../../../KnitGether-Info.plist) | 전체 텍스트 검색, plist 파싱 |
| [KnitGether.xcodeproj/project.pbxproj](../../../KnitGether.xcodeproj/project.pbxproj) | 전체 텍스트 검색 |
| [KnitGether.xcodeproj/project.xcworkspace/contents.xcworkspacedata](../../../KnitGether.xcodeproj/project.xcworkspace/contents.xcworkspacedata) | 전체 텍스트 검색, XML 파싱 |
| [KnitGether.xcodeproj/xcshareddata/xcschemes/KnitGether Local Device.xcscheme](../../../KnitGether.xcodeproj/xcshareddata/xcschemes/KnitGether%20Local%20Device.xcscheme) | 전체 텍스트 검색, XML 파싱 |
| [KnitGether.xcodeproj/xcshareddata/xcschemes/KnitGether Local Offline.xcscheme](../../../KnitGether.xcodeproj/xcshareddata/xcschemes/KnitGether%20Local%20Offline.xcscheme) | 전체 텍스트 검색, XML 파싱 |
| [KnitGether.xcodeproj/xcshareddata/xcschemes/KnitGether Local Simulator.xcscheme](../../../KnitGether.xcodeproj/xcshareddata/xcschemes/KnitGether%20Local%20Simulator.xcscheme) | 전체 텍스트 검색, XML 파싱 |
| [KnitGether.xcodeproj/xcshareddata/xcschemes/KnitGether.xcscheme](../../../KnitGether.xcodeproj/xcshareddata/xcschemes/KnitGether.xcscheme) | 전체 텍스트 검색, XML 파싱 |
| [KnitGether/Assets.xcassets/AccentColor.colorset/Contents.json](../../../KnitGether/Assets.xcassets/AccentColor.colorset/Contents.json) | 전체 텍스트 검색, JSON 파싱 |
| [KnitGether/Assets.xcassets/AppIcon.appiconset/Contents.json](../../../KnitGether/Assets.xcassets/AppIcon.appiconset/Contents.json) | 전체 텍스트 검색, JSON 파싱 |
| [KnitGether/Assets.xcassets/Contents.json](../../../KnitGether/Assets.xcassets/Contents.json) | 전체 텍스트 검색, JSON 파싱 |
| [KnitGether/ContentView.swift](../../../KnitGether/ContentView.swift) | 전체 텍스트 검색 |
| [KnitGether/Formatters/SkillLevelFormatter.swift](../../../KnitGether/Formatters/SkillLevelFormatter.swift) | 전체 텍스트 검색 |
| [KnitGether/KnitGetherApp.swift](../../../KnitGether/KnitGetherApp.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/AuthSession.swift](../../../KnitGether/Models/AuthSession.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/DictionaryTerm.swift](../../../KnitGether/Models/DictionaryTerm.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/GaugeRecord.swift](../../../KnitGether/Models/GaugeRecord.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/GaugeTarget.swift](../../../KnitGether/Models/GaugeTarget.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/KnittingProject.swift](../../../KnitGether/Models/KnittingProject.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/Needle.swift](../../../KnitGether/Models/Needle.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/PatternDocument.swift](../../../KnitGether/Models/PatternDocument.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/ProjectMaterialLink.swift](../../../KnitGether/Models/ProjectMaterialLink.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/ProjectPatternCopy.swift](../../../KnitGether/Models/ProjectPatternCopy.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/ProjectProgressPhoto.swift](../../../KnitGether/Models/ProjectProgressPhoto.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/ProjectStatus.swift](../../../KnitGether/Models/ProjectStatus.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/ProjectWorkspaceDisplayMode.swift](../../../KnitGether/Models/ProjectWorkspaceDisplayMode.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/ProjectWorkspaceSheetPosition.swift](../../../KnitGether/Models/ProjectWorkspaceSheetPosition.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/ProjectYarnUsage.swift](../../../KnitGether/Models/ProjectYarnUsage.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/RowCounter.swift](../../../KnitGether/Models/RowCounter.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/RowCounterMode.swift](../../../KnitGether/Models/RowCounterMode.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/RowInstruction.swift](../../../KnitGether/Models/RowInstruction.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/Skill.swift](../../../KnitGether/Models/Skill.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/SkillAnimation.swift](../../../KnitGether/Models/SkillAnimation.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/SkillAnimationFrameSequence.swift](../../../KnitGether/Models/SkillAnimationFrameSequence.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/SyncStatus.swift](../../../KnitGether/Models/SyncStatus.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/ToolItem.swift](../../../KnitGether/Models/ToolItem.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/UserProfile.swift](../../../KnitGether/Models/UserProfile.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/WorkSession.swift](../../../KnitGether/Models/WorkSession.swift) | 전체 텍스트 검색 |
| [KnitGether/Models/Yarn.swift](../../../KnitGether/Models/Yarn.swift) | 전체 텍스트 검색 |
| [KnitGether/Networking/APIClient.swift](../../../KnitGether/Networking/APIClient.swift) | 전체 텍스트 검색 |
| [KnitGether/Networking/APIConfiguration.swift](../../../KnitGether/Networking/APIConfiguration.swift) | 전체 텍스트 검색 |
| [KnitGether/Networking/APIError.swift](../../../KnitGether/Networking/APIError.swift) | 전체 텍스트 검색 |
| [KnitGether/Networking/AuthSessionStore.swift](../../../KnitGether/Networking/AuthSessionStore.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/AppRepositoryContainer.swift](../../../KnitGether/Repositories/AppRepositoryContainer.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Local/LocalGaugeTargetRepository.swift](../../../KnitGether/Repositories/Local/LocalGaugeTargetRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Local/LocalPatternFileStore.swift](../../../KnitGether/Repositories/Local/LocalPatternFileStore.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Local/LocalProjectProgressPhotoFileStore.swift](../../../KnitGether/Repositories/Local/LocalProjectProgressPhotoFileStore.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Local/LocalProjectProgressPhotoRepository.swift](../../../KnitGether/Repositories/Local/LocalProjectProgressPhotoRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Local/LocalSampleRepositories.swift](../../../KnitGether/Repositories/Local/LocalSampleRepositories.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/OfflineFirstDictionaryRepository.swift](../../../KnitGether/Repositories/OfflineFirstDictionaryRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/OfflineFirstLibraryRepository.swift](../../../KnitGether/Repositories/OfflineFirstLibraryRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/OfflineFirstPatternRepository.swift](../../../KnitGether/Repositories/OfflineFirstPatternRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/OfflineFirstProfileRepository.swift](../../../KnitGether/Repositories/OfflineFirstProfileRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/OfflineFirstProjectRepository.swift](../../../KnitGether/Repositories/OfflineFirstProjectRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/OfflineFirstSkillRepository.swift](../../../KnitGether/Repositories/OfflineFirstSkillRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Protocols/AuthRepository.swift](../../../KnitGether/Repositories/Protocols/AuthRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Protocols/DictionaryRepository.swift](../../../KnitGether/Repositories/Protocols/DictionaryRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Protocols/GaugeRecordRepository.swift](../../../KnitGether/Repositories/Protocols/GaugeRecordRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Protocols/GaugeTargetRepository.swift](../../../KnitGether/Repositories/Protocols/GaugeTargetRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Protocols/LibraryRepository.swift](../../../KnitGether/Repositories/Protocols/LibraryRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Protocols/OfflineSyncFlushable.swift](../../../KnitGether/Repositories/Protocols/OfflineSyncFlushable.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Protocols/PatternRepository.swift](../../../KnitGether/Repositories/Protocols/PatternRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Protocols/ProfileRepository.swift](../../../KnitGether/Repositories/Protocols/ProfileRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Protocols/ProjectProgressPhotoRepository.swift](../../../KnitGether/Repositories/Protocols/ProjectProgressPhotoRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Protocols/ProjectRepository.swift](../../../KnitGether/Repositories/Protocols/ProjectRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Protocols/SkillRepository.swift](../../../KnitGether/Repositories/Protocols/SkillRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Remote/RemoteAuthRepository.swift](../../../KnitGether/Repositories/Remote/RemoteAuthRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Remote/RemoteDictionaryRepository.swift](../../../KnitGether/Repositories/Remote/RemoteDictionaryRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Remote/RemoteGaugeRecordRepository.swift](../../../KnitGether/Repositories/Remote/RemoteGaugeRecordRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Remote/RemoteGaugeTargetRepository.swift](../../../KnitGether/Repositories/Remote/RemoteGaugeTargetRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Remote/RemoteLibraryRepository.swift](../../../KnitGether/Repositories/Remote/RemoteLibraryRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Remote/RemotePatternRepository.swift](../../../KnitGether/Repositories/Remote/RemotePatternRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Remote/RemoteProfileRepository.swift](../../../KnitGether/Repositories/Remote/RemoteProfileRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Remote/RemoteProjectProgressPhotoRepository.swift](../../../KnitGether/Repositories/Remote/RemoteProjectProgressPhotoRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Remote/RemoteProjectRepository.swift](../../../KnitGether/Repositories/Remote/RemoteProjectRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Repositories/Remote/RemoteSkillRepository.swift](../../../KnitGether/Repositories/Remote/RemoteSkillRepository.swift) | 전체 텍스트 검색 |
| [KnitGether/Resources/SamplePatterns/README.md](../../../KnitGether/Resources/SamplePatterns/README.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [KnitGether/Resources/SamplePatterns/sample1.pdf](../../../KnitGether/Resources/SamplePatterns/sample1.pdf) | 전체 페이지 텍스트 추출, PDF 구조 확인 및 교체본 전체 페이지 렌더링 |
| [KnitGether/Resources/SamplePatterns/sample2.pdf](../../../KnitGether/Resources/SamplePatterns/sample2.pdf) | 전체 페이지 텍스트 추출, PDF 구조 확인 및 교체본 전체 페이지 렌더링 |
| [KnitGether/Resources/SamplePatterns/sample3.pdf](../../../KnitGether/Resources/SamplePatterns/sample3.pdf) | 전체 페이지 텍스트 추출, PDF 구조 확인 및 교체본 전체 페이지 렌더링 |
| [KnitGether/Resources/SamplePatterns/sample4.pdf](../../../KnitGether/Resources/SamplePatterns/sample4.pdf) | 전체 페이지 텍스트 추출, PDF 구조 확인 및 교체본 전체 페이지 렌더링 |
| [KnitGether/SampleData/SampleData.swift](../../../KnitGether/SampleData/SampleData.swift) | 전체 텍스트 검색 |
| [KnitGether/Services/GaugeAutoCounter.swift](../../../KnitGether/Services/GaugeAutoCounter.swift) | 전체 텍스트 검색 |
| [KnitGether/Services/GaugeTargetInput.swift](../../../KnitGether/Services/GaugeTargetInput.swift) | 전체 텍스트 검색 |
| [KnitGether/Services/ManualMeasurementInput.swift](../../../KnitGether/Services/ManualMeasurementInput.swift) | 전체 텍스트 검색 |
| [KnitGether/Services/PhotoMeasurementSource.swift](../../../KnitGether/Services/PhotoMeasurementSource.swift) | 전체 텍스트 검색 |
| [KnitGether/Services/UserDefaultsKeys.swift](../../../KnitGether/Services/UserDefaultsKeys.swift) | 전체 텍스트 검색 |
| [KnitGether/Services/WorkTimeFormatter.swift](../../../KnitGether/Services/WorkTimeFormatter.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/AuthAccountViewModel.swift](../../../KnitGether/ViewModels/AuthAccountViewModel.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/DataBackupExportViewModel.swift](../../../KnitGether/ViewModels/DataBackupExportViewModel.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/DictionaryViewModel.swift](../../../KnitGether/ViewModels/DictionaryViewModel.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/GaugeCalculatorViewModel.swift](../../../KnitGether/ViewModels/GaugeCalculatorViewModel.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/GaugeMeasureViewModel.swift](../../../KnitGether/ViewModels/GaugeMeasureViewModel.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/HomeDashboardViewModel.swift](../../../KnitGether/ViewModels/HomeDashboardViewModel.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/LibraryItemViewModels.swift](../../../KnitGether/ViewModels/LibraryItemViewModels.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/LibraryViewModel.swift](../../../KnitGether/ViewModels/LibraryViewModel.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/MyKnittingViewModel.swift](../../../KnitGether/ViewModels/MyKnittingViewModel.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/OnboardingViewModel.swift](../../../KnitGether/ViewModels/OnboardingViewModel.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/PatternLibraryViewModel.swift](../../../KnitGether/ViewModels/PatternLibraryViewModel.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/ProfileSettingsViewModel.swift](../../../KnitGether/ViewModels/ProfileSettingsViewModel.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/ProjectFormData.swift](../../../KnitGether/ViewModels/ProjectFormData.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/ProjectWorkspaceViewModel.swift](../../../KnitGether/ViewModels/ProjectWorkspaceViewModel.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/SettingsWorkTimeSummary.swift](../../../KnitGether/ViewModels/SettingsWorkTimeSummary.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/SkillAnimationViewModel.swift](../../../KnitGether/ViewModels/SkillAnimationViewModel.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/SkillFormData.swift](../../../KnitGether/ViewModels/SkillFormData.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/SkillLibraryViewModel.swift](../../../KnitGether/ViewModels/SkillLibraryViewModel.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/SkillTestViewModel.swift](../../../KnitGether/ViewModels/SkillTestViewModel.swift) | 전체 텍스트 검색 |
| [KnitGether/ViewModels/WorkTimerSuppressionStore.swift](../../../KnitGether/ViewModels/WorkTimerSuppressionStore.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Home/HomeView.swift](../../../KnitGether/Views/Home/HomeView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Library/AddSkillView.swift](../../../KnitGether/Views/Library/AddSkillView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Library/LibraryView.swift](../../../KnitGether/Views/Library/LibraryView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Library/NeedleLibraryView.swift](../../../KnitGether/Views/Library/NeedleLibraryView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Library/PatternLibraryView.swift](../../../KnitGether/Views/Library/PatternLibraryView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Library/SkillLibraryView.swift](../../../KnitGether/Views/Library/SkillLibraryView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Library/ToolLibraryView.swift](../../../KnitGether/Views/Library/ToolLibraryView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Library/YarnLibraryView.swift](../../../KnitGether/Views/Library/YarnLibraryView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/AddProjectView.swift](../../../KnitGether/Views/MyKnitting/AddProjectView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/EditProjectView.swift](../../../KnitGether/Views/MyKnitting/EditProjectView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/MyKnittingView.swift](../../../KnitGether/Views/MyKnitting/MyKnittingView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/PatternSelectionView.swift](../../../KnitGether/Views/MyKnitting/PatternSelectionView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/ProjectCardView.swift](../../../KnitGether/Views/MyKnitting/ProjectCardView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/ProjectFormView.swift](../../../KnitGether/Views/MyKnitting/ProjectFormView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/ProjectWorkspaceView.swift](../../../KnitGether/Views/MyKnitting/ProjectWorkspaceView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/Workspace/PatternSupportLookupView.swift](../../../KnitGether/Views/MyKnitting/Workspace/PatternSupportLookupView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/Workspace/ProjectCounterPanelView.swift](../../../KnitGether/Views/MyKnitting/Workspace/ProjectCounterPanelView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/Workspace/ProjectGaugeRecordPanelView.swift](../../../KnitGether/Views/MyKnitting/Workspace/ProjectGaugeRecordPanelView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/Workspace/ProjectMemoPanelView.swift](../../../KnitGether/Views/MyKnitting/Workspace/ProjectMemoPanelView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/Workspace/ProjectNeedlePanelView.swift](../../../KnitGether/Views/MyKnitting/Workspace/ProjectNeedlePanelView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/Workspace/ProjectPatternFocusView.swift](../../../KnitGether/Views/MyKnitting/Workspace/ProjectPatternFocusView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/Workspace/ProjectProgressPhotoPanelView.swift](../../../KnitGether/Views/MyKnitting/Workspace/ProjectProgressPhotoPanelView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/Workspace/ProjectRowGuidePanelView.swift](../../../KnitGether/Views/MyKnitting/Workspace/ProjectRowGuidePanelView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/Workspace/ProjectToolPanelView.swift](../../../KnitGether/Views/MyKnitting/Workspace/ProjectToolPanelView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/Workspace/ProjectWorkSessionListView.swift](../../../KnitGether/Views/MyKnitting/Workspace/ProjectWorkSessionListView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/Workspace/ProjectWorkTimePanelView.swift](../../../KnitGether/Views/MyKnitting/Workspace/ProjectWorkTimePanelView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/Workspace/ProjectWorkspaceHeaderView.swift](../../../KnitGether/Views/MyKnitting/Workspace/ProjectWorkspaceHeaderView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/Workspace/ProjectWorkspaceSummaryView.swift](../../../KnitGether/Views/MyKnitting/Workspace/ProjectWorkspaceSummaryView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/Workspace/ProjectYarnUsagePanelView.swift](../../../KnitGether/Views/MyKnitting/Workspace/ProjectYarnUsagePanelView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/MyKnitting/Workspace/SkillTagChipView.swift](../../../KnitGether/Views/MyKnitting/Workspace/SkillTagChipView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Onboarding/OnboardingView.swift](../../../KnitGether/Views/Onboarding/OnboardingView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Shared/AppAccessibilityID.swift](../../../KnitGether/Views/Shared/AppAccessibilityID.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Shared/AppDetailComponents.swift](../../../KnitGether/Views/Shared/AppDetailComponents.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Shared/AppFormComponents.swift](../../../KnitGether/Views/Shared/AppFormComponents.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Shared/AppInputLimit.swift](../../../KnitGether/Views/Shared/AppInputLimit.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Shared/AppNavigationRow.swift](../../../KnitGether/Views/Shared/AppNavigationRow.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Shared/AppTheme.swift](../../../KnitGether/Views/Shared/AppTheme.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Shared/DocumentScannerView.swift](../../../KnitGether/Views/Shared/DocumentScannerView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Shared/DraggableBottomSheet.swift](../../../KnitGether/Views/Shared/DraggableBottomSheet.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Shared/EmptyStateView.swift](../../../KnitGether/Views/Shared/EmptyStateView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Shared/LibraryItemPhotoContent.swift](../../../KnitGether/Views/Shared/LibraryItemPhotoContent.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Shared/PDFKitView.swift](../../../KnitGether/Views/Shared/PDFKitView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Shared/PencilCanvasView.swift](../../../KnitGether/Views/Shared/PencilCanvasView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Shared/SkillDetailView.swift](../../../KnitGether/Views/Shared/SkillDetailView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Shared/SkillRowView.swift](../../../KnitGether/Views/Shared/SkillRowView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Shared/StatusBadgeView.swift](../../../KnitGether/Views/Shared/StatusBadgeView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Shared/SyncRetryBanner.swift](../../../KnitGether/Views/Shared/SyncRetryBanner.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Shared/SyncStatusBadgeView.swift](../../../KnitGether/Views/Shared/SyncStatusBadgeView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Shared/WorkspaceSectionView.swift](../../../KnitGether/Views/Shared/WorkspaceSectionView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/AuthAccountView.swift](../../../KnitGether/Views/Tool/AuthAccountView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/GaugeCalculator/Measure/GaugeMeasureHubView.swift](../../../KnitGether/Views/Tool/GaugeCalculator/Measure/GaugeMeasureHubView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/GaugeCalculator/Measure/GaugeMeasurementViews.swift](../../../KnitGether/Views/Tool/GaugeCalculator/Measure/GaugeMeasurementViews.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/GaugeCalculator/Measure/GaugeSwatchViews.swift](../../../KnitGether/Views/Tool/GaugeCalculator/Measure/GaugeSwatchViews.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/GaugeCalculator/Measure/GaugeTargetFormView.swift](../../../KnitGether/Views/Tool/GaugeCalculator/Measure/GaugeTargetFormView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/GaugeCalculatorView.swift](../../../KnitGether/Views/Tool/GaugeCalculatorView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/KnitAnimation/KnitAnimationView.swift](../../../KnitGether/Views/Tool/KnitAnimation/KnitAnimationView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/KnitAnimation/SkillAnimationDetailView.swift](../../../KnitGether/Views/Tool/KnitAnimation/SkillAnimationDetailView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/KnitDictionary/KnitDictionaryView.swift](../../../KnitGether/Views/Tool/KnitDictionary/KnitDictionaryView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/ProfileSettingsView.swift](../../../KnitGether/Views/Tool/ProfileSettingsView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/Settings/AppInfoView.swift](../../../KnitGether/Views/Tool/Settings/AppInfoView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/Settings/DataBackupView.swift](../../../KnitGether/Views/Tool/Settings/DataBackupView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/Settings/DataManagementView.swift](../../../KnitGether/Views/Tool/Settings/DataManagementView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/Settings/ProjectStatusGuideView.swift](../../../KnitGether/Views/Tool/Settings/ProjectStatusGuideView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/Settings/SettingsView.swift](../../../KnitGether/Views/Tool/Settings/SettingsView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/Settings/WorkSessionListView.swift](../../../KnitGether/Views/Tool/Settings/WorkSessionListView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/Settings/WorkTimeStatisticsView.swift](../../../KnitGether/Views/Tool/Settings/WorkTimeStatisticsView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/SkillTest/SkillLevelSelectionView.swift](../../../KnitGether/Views/Tool/SkillTest/SkillLevelSelectionView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/SkillTest/SkillTestCardView.swift](../../../KnitGether/Views/Tool/SkillTest/SkillTestCardView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/SkillTest/SkillTestProgressView.swift](../../../KnitGether/Views/Tool/SkillTest/SkillTestProgressView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/SkillTest/SkillTestResultView.swift](../../../KnitGether/Views/Tool/SkillTest/SkillTestResultView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/SkillTest/SkillTestView.swift](../../../KnitGether/Views/Tool/SkillTest/SkillTestView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/SkillToolListView.swift](../../../KnitGether/Views/Tool/SkillToolListView.swift) | 전체 텍스트 검색 |
| [KnitGether/Views/Tool/ToolView.swift](../../../KnitGether/Views/Tool/ToolView.swift) | 전체 텍스트 검색 |
| [KnitGetherQAUITests/CounterSheetPage.swift](../../../KnitGetherQAUITests/CounterSheetPage.swift) | 전체 텍스트 검색 |
| [KnitGetherQAUITests/DEF-15_RegressionTests.swift](../../../KnitGetherQAUITests/DEF-15_RegressionTests.swift) | 전체 텍스트 검색 |
| [KnitGetherQAUITests/KnitGetherQAUITests.swift](../../../KnitGetherQAUITests/KnitGetherQAUITests.swift) | 전체 텍스트 검색 |
| [KnitGetherQAUITests/KnitGetherQAUITestsLaunchTests.swift](../../../KnitGetherQAUITests/KnitGetherQAUITestsLaunchTests.swift) | 전체 텍스트 검색 |
| [KnitGetherQAUITests/MyKnittingPage.swift](../../../KnitGetherQAUITests/MyKnittingPage.swift) | 전체 텍스트 검색 |
| [KnitGetherQAUITests/WorkspacePage.swift](../../../KnitGetherQAUITests/WorkspacePage.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/APIClientTests.swift](../../../KnitGetherTests/APIClientTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/AppRepositoryContainerTests.swift](../../../KnitGetherTests/AppRepositoryContainerTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/AuthAccountViewModelTests.swift](../../../KnitGetherTests/AuthAccountViewModelTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/AuthSessionStoreTests.swift](../../../KnitGetherTests/AuthSessionStoreTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/DataBackupExportViewModelTests.swift](../../../KnitGetherTests/DataBackupExportViewModelTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/DictionaryViewModelTests.swift](../../../KnitGetherTests/DictionaryViewModelTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/GaugeCalculatorViewModelTests.swift](../../../KnitGetherTests/GaugeCalculatorViewModelTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/GaugeMeasureViewModelTests.swift](../../../KnitGetherTests/GaugeMeasureViewModelTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/GaugeMeasurementInputTests.swift](../../../KnitGetherTests/GaugeMeasurementInputTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/HomeDashboardSummaryTests.swift](../../../KnitGetherTests/HomeDashboardSummaryTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/KnitGetherTests.swift](../../../KnitGetherTests/KnitGetherTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/LibraryItemViewModelTests.swift](../../../KnitGetherTests/LibraryItemViewModelTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/LibraryViewModelTests.swift](../../../KnitGetherTests/LibraryViewModelTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/LocalPatternFileStoreTests.swift](../../../KnitGetherTests/LocalPatternFileStoreTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/LocalRepositoryPersistenceTests.swift](../../../KnitGetherTests/LocalRepositoryPersistenceTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/MockURLProtocol.swift](../../../KnitGetherTests/MockURLProtocol.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/MyKnittingViewModelTests.swift](../../../KnitGetherTests/MyKnittingViewModelTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/OfflineFirstGaugeRecordRepositoryTests.swift](../../../KnitGetherTests/OfflineFirstGaugeRecordRepositoryTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/OfflineFirstLibraryRepositoryTests.swift](../../../KnitGetherTests/OfflineFirstLibraryRepositoryTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/OfflineFirstPatternRepositoryTests.swift](../../../KnitGetherTests/OfflineFirstPatternRepositoryTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/OfflineFirstProfileRepositoryTests.swift](../../../KnitGetherTests/OfflineFirstProfileRepositoryTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/OfflineFirstProjectRepositoryTests.swift](../../../KnitGetherTests/OfflineFirstProjectRepositoryTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/OfflineFirstSkillRepositoryTests.swift](../../../KnitGetherTests/OfflineFirstSkillRepositoryTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/OnboardingViewModelTests.swift](../../../KnitGetherTests/OnboardingViewModelTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/PatternLibraryViewModelTests.swift](../../../KnitGetherTests/PatternLibraryViewModelTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/ProfileSettingsViewModelTests.swift](../../../KnitGetherTests/ProfileSettingsViewModelTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/ProjectWorkspaceViewModelTests.swift](../../../KnitGetherTests/ProjectWorkspaceViewModelTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/RemoteAuthRepositoryTests.swift](../../../KnitGetherTests/RemoteAuthRepositoryTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/RemoteDictionaryRepositoryTests.swift](../../../KnitGetherTests/RemoteDictionaryRepositoryTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/RemoteGaugeRecordRepositoryTests.swift](../../../KnitGetherTests/RemoteGaugeRecordRepositoryTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/RemoteGaugeTargetRepositoryTests.swift](../../../KnitGetherTests/RemoteGaugeTargetRepositoryTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/RemoteLibraryRepositoryTests.swift](../../../KnitGetherTests/RemoteLibraryRepositoryTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/RemotePatternRepositoryTests.swift](../../../KnitGetherTests/RemotePatternRepositoryTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/RemoteProfileRepositoryTests.swift](../../../KnitGetherTests/RemoteProfileRepositoryTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/RemoteProjectProgressPhotoRepositoryTests.swift](../../../KnitGetherTests/RemoteProjectProgressPhotoRepositoryTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/RemoteProjectRepositoryTests.swift](../../../KnitGetherTests/RemoteProjectRepositoryTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/RemoteSkillRepositoryTests.swift](../../../KnitGetherTests/RemoteSkillRepositoryTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/SettingsStatisticsTests.swift](../../../KnitGetherTests/SettingsStatisticsTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/SkillAnimationViewModelTests.swift](../../../KnitGetherTests/SkillAnimationViewModelTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/SkillLibraryViewModelTests.swift](../../../KnitGetherTests/SkillLibraryViewModelTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/SkillTestViewModelTests.swift](../../../KnitGetherTests/SkillTestViewModelTests.swift) | 전체 텍스트 검색 |
| [KnitGetherTests/SyncStatusPresentationTests.swift](../../../KnitGetherTests/SyncStatusPresentationTests.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/AuthPage.swift](../../../KnitGetherUITests/AuthPage.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/DictionaryPage.swift](../../../KnitGetherUITests/DictionaryPage.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/GaugeCalculatorPage.swift](../../../KnitGetherUITests/GaugeCalculatorPage.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/KnitGetherAPIClient.swift](../../../KnitGetherUITests/KnitGetherAPIClient.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/KnitGetherUITestCase.swift](../../../KnitGetherUITests/KnitGetherUITestCase.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/KnitGetherUITests.swift](../../../KnitGetherUITests/KnitGetherUITests.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/KnitGetherUITestsLaunchTests.swift](../../../KnitGetherUITests/KnitGetherUITestsLaunchTests.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/LibraryPage.swift](../../../KnitGetherUITests/LibraryPage.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/MainTabBarPage.swift](../../../KnitGetherUITests/MainTabBarPage.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/MyKnittingPage.swift](../../../KnitGetherUITests/MyKnittingPage.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/NeedleLibraryPage.swift](../../../KnitGetherUITests/NeedleLibraryPage.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/OnboardingPage.swift](../../../KnitGetherUITests/OnboardingPage.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/ProjectFormPage.swift](../../../KnitGetherUITests/ProjectFormPage.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/SettingsPage.swift](../../../KnitGetherUITests/SettingsPage.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/SkillTestPage.swift](../../../KnitGetherUITests/SkillTestPage.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/ToolLibraryPage.swift](../../../KnitGetherUITests/ToolLibraryPage.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/ToolPage.swift](../../../KnitGetherUITests/ToolPage.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/UITestPage.swift](../../../KnitGetherUITests/UITestPage.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/WorkspacePage.swift](../../../KnitGetherUITests/WorkspacePage.swift) | 전체 텍스트 검색 |
| [KnitGetherUITests/YarnLibraryPage.swift](../../../KnitGetherUITests/YarnLibraryPage.swift) | 전체 텍스트 검색 |
| [README.md](../../../README.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/dev/06_architecture_audit_2026-07-09.md](../../../docs/dev/06_architecture_audit_2026-07-09.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/dev/07_mvp_feature_parity_2026-07-10.md](../../../docs/dev/07_mvp_feature_parity_2026-07-10.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/dev/08_qa_automation_ids_2026-07-11.md](../../../docs/dev/08_qa_automation_ids_2026-07-11.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/dev/09_local_device_development.md](../../../docs/dev/09_local_device_development.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/dev/architecture.md](../../../docs/dev/architecture.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/dev/modes.md](../../../docs/dev/modes.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/dev/security_review.md](../../../docs/dev/security_review.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/dev/specs/2026-07-04-ios-sync-api-server-design.md](../../../docs/dev/specs/2026-07-04-ios-sync-api-server-design.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/dev/specs/2026-07-05-project-crud-design.md](../../../docs/dev/specs/2026-07-05-project-crud-design.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/dev/specs/2026-07-06-pattern-file-upload-design.md](../../../docs/dev/specs/2026-07-06-pattern-file-upload-design.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/dev/specs/2026-07-07-workspace-ux-restoration-design.md](../../../docs/dev/specs/2026-07-07-workspace-ux-restoration-design.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/dev/specs/2026-07-27-workspace-two-tab-design.md](../../../docs/dev/specs/2026-07-27-workspace-two-tab-design.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/appium-charles-smoke.md](../../../docs/qa/appium-charles-smoke.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/appium_suite_worklog_2026-08-27.md](../../../docs/qa/appium_suite_worklog_2026-08-27.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/fix_cycle_worklog_2026-09-03.md](../../../docs/qa/fix_cycle_worklog_2026-09-03.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/00_project_background.md](../../../docs/qa/portfolio/00_project_background.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/01_test_target_analysis.md](../../../docs/qa/portfolio/01_test_target_analysis.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/02_functional_spec.md](../../../docs/qa/portfolio/02_functional_spec.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/03_quality_risk_map.md](../../../docs/qa/portfolio/03_quality_risk_map.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/04_test_strategy.md](../../../docs/qa/portfolio/04_test_strategy.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/05_test_cases.md](../../../docs/qa/portfolio/05_test_cases.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/06_manual_execution.md](../../../docs/qa/portfolio/06_manual_execution.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/07_api_and_network.md](../../../docs/qa/portfolio/07_api_and_network.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/08_automation_comparison.md](../../../docs/qa/portfolio/08_automation_comparison.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/09_test_case_master.md](../../../docs/qa/portfolio/09_test_case_master.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/10_defect_catalog.md](../../../docs/qa/portfolio/10_defect_catalog.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/11_execution_results.md](../../../docs/qa/portfolio/11_execution_results.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/12_quality_metrics.md](../../../docs/qa/portfolio/12_quality_metrics.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/13_automation_showcase.md](../../../docs/qa/portfolio/13_automation_showcase.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/14_observations.md](../../../docs/qa/portfolio/14_observations.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/15_release_decision.md](../../../docs/qa/portfolio/15_release_decision.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/16_test_charters.md](../../../docs/qa/portfolio/16_test_charters.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/README.md](../../../docs/qa/portfolio/README.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/evidence/0719_DEF-001_auth_FAIL_element-tree.txt](../../../docs/qa/portfolio/evidence/0719_DEF-001_auth_FAIL_element-tree.txt) | 전체 텍스트 검색 |
| [docs/qa/portfolio/evidence/0719_qa_round_1_execution.md](../../../docs/qa/portfolio/evidence/0719_qa_round_1_execution.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/evidence/0727_manual_verification/01_home.png](../../../docs/qa/portfolio/evidence/0727_manual_verification/01_home.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0727_manual_verification/02_library_hub.png](../../../docs/qa/portfolio/evidence/0727_manual_verification/02_library_hub.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0727_manual_verification/03_skill_library.png](../../../docs/qa/portfolio/evidence/0727_manual_verification/03_skill_library.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0727_manual_verification/04_skill_detail.png](../../../docs/qa/portfolio/evidence/0727_manual_verification/04_skill_detail.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0727_manual_verification/05_tool_hub.png](../../../docs/qa/portfolio/evidence/0727_manual_verification/05_tool_hub.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0727_manual_verification/06_navigation.png](../../../docs/qa/portfolio/evidence/0727_manual_verification/06_navigation.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0727_manual_verification/07_animation_list.png](../../../docs/qa/portfolio/evidence/0727_manual_verification/07_animation_list.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0727_manual_verification/08_animation_detail.png](../../../docs/qa/portfolio/evidence/0727_manual_verification/08_animation_detail.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0727_manual_verification/09_settings.png](../../../docs/qa/portfolio/evidence/0727_manual_verification/09_settings.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0727_manual_verification/10_profile_edit.png](../../../docs/qa/portfolio/evidence/0727_manual_verification/10_profile_edit.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0727_manual_verification/11_profile_saved_updatedAt.png](../../../docs/qa/portfolio/evidence/0727_manual_verification/11_profile_saved_updatedAt.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0727_manual_verification/12_work_statistics.png](../../../docs/qa/portfolio/evidence/0727_manual_verification/12_work_statistics.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0727_manual_verification/13_pattern_library.png](../../../docs/qa/portfolio/evidence/0727_manual_verification/13_pattern_library.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0727_manual_verification/14_skill_test.png](../../../docs/qa/portfolio/evidence/0727_manual_verification/14_skill_test.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0727_manual_verification/15_work_session_list.png](../../../docs/qa/portfolio/evidence/0727_manual_verification/15_work_session_list.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0727_manual_verification/README.md](../../../docs/qa/portfolio/evidence/0727_manual_verification/README.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/evidence/0728_DEF-010_workspace-row-instruction_FAIL.png](../../../docs/qa/portfolio/evidence/0728_DEF-010_workspace-row-instruction_FAIL.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0830_DEF-08_app_before_after.png](../../../docs/qa/portfolio/evidence/0830_DEF-08_app_before_after.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0830_DEF-08_repro_500_vs_200.png](../../../docs/qa/portfolio/evidence/0830_DEF-08_repro_500_vs_200.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0830_DEF-10_drawing_loss_before_after.png](../../../docs/qa/portfolio/evidence/0830_DEF-10_drawing_loss_before_after.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0830_DEF-16_login_race_old_build.png](../../../docs/qa/portfolio/evidence/0830_DEF-16_login_race_old_build.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0830_app_home.png](../../../docs/qa/portfolio/evidence/0830_app_home.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0830_appium_tc01_1passed.png](../../../docs/qa/portfolio/evidence/0830_appium_tc01_1passed.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0830_appium_tc02-06_30passed.png](../../../docs/qa/portfolio/evidence/0830_appium_tc02-06_30passed.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0830_charles_app_get_projects_200.png](../../../docs/qa/portfolio/evidence/0830_charles_app_get_projects_200.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0830_github_issues.png](../../../docs/qa/portfolio/evidence/0830_github_issues.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0830_postman_project_create_201.png](../../../docs/qa/portfolio/evidence/0830_postman_project_create_201.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0830_psql_UserAccount_after_tc02.png](../../../docs/qa/portfolio/evidence/0830_psql_UserAccount_after_tc02.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0830_psql_project_after_postman.png](../../../docs/qa/portfolio/evidence/0830_psql_project_after_postman.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/portfolio/evidence/0901_appium_regression3_78cases.txt](../../../docs/qa/portfolio/evidence/0901_appium_regression3_78cases.txt) | 전체 텍스트 검색 |
| [docs/qa/portfolio/evidence/0905_appium_regression4_78cases.txt](../../../docs/qa/portfolio/evidence/0905_appium_regression4_78cases.txt) | 전체 텍스트 검색 |
| [docs/qa/portfolio/evidence/sheets/README.md](../../../docs/qa/portfolio/evidence/sheets/README.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/portfolio/evidence/sheets/observations_cycle3.csv](../../../docs/qa/portfolio/evidence/sheets/observations_cycle3.csv) | 전체 텍스트 검색, CSV 파싱 |
| [docs/qa/portfolio/evidence/sheets/tc_design_api_cases.csv](../../../docs/qa/portfolio/evidence/sheets/tc_design_api_cases.csv) | 전체 텍스트 검색, CSV 파싱 |
| [docs/qa/portfolio/evidence/sheets/tc_design_cycle1_results.csv](../../../docs/qa/portfolio/evidence/sheets/tc_design_cycle1_results.csv) | 전체 텍스트 검색, CSV 파싱 |
| [docs/qa/portfolio/evidence/sheets/tc_design_defect_ledger.csv](../../../docs/qa/portfolio/evidence/sheets/tc_design_defect_ledger.csv) | 전체 텍스트 검색, CSV 파싱 |
| [docs/qa/portfolio/evidence/sheets/tc_design_roadmap.csv](../../../docs/qa/portfolio/evidence/sheets/tc_design_roadmap.csv) | 전체 텍스트 검색, CSV 파싱 |
| [docs/qa/portfolio/evidence/sheets/tc_design_ui_cases.csv](../../../docs/qa/portfolio/evidence/sheets/tc_design_ui_cases.csv) | 전체 텍스트 검색, CSV 파싱 |
| [docs/qa/postman/README.md](../../../docs/qa/postman/README.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/postman/knitgether-local.postman_collection.json](../../../docs/qa/postman/knitgether-local.postman_collection.json) | 전체 텍스트 검색, JSON 파싱 |
| [docs/qa/repository-review/README.md](../../../docs/qa/repository-review/README.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/repository-review/files.md](../../../docs/qa/repository-review/files.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/submission/README.md](../../../docs/qa/submission/README.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/submission/evidence/2026-10-04/01_workspace.png](../../../docs/qa/submission/evidence/2026-10-04/01_workspace.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/01_workspace.xml](../../../docs/qa/submission/evidence/2026-10-04/01_workspace.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/02_drawing_before.png](../../../docs/qa/submission/evidence/2026-10-04/02_drawing_before.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/02_drawing_before.xml](../../../docs/qa/submission/evidence/2026-10-04/02_drawing_before.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/03_replace_warning.png](../../../docs/qa/submission/evidence/2026-10-04/03_replace_warning.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/03_replace_warning.xml](../../../docs/qa/submission/evidence/2026-10-04/03_replace_warning.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/04_cancel_preserved.png](../../../docs/qa/submission/evidence/2026-10-04/04_cancel_preserved.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/04_cancel_preserved.xml](../../../docs/qa/submission/evidence/2026-10-04/04_cancel_preserved.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/05_confirm_replaced.png](../../../docs/qa/submission/evidence/2026-10-04/05_confirm_replaced.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/05_confirm_replaced.xml](../../../docs/qa/submission/evidence/2026-10-04/05_confirm_replaced.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/06_relaunch_replaced.png](../../../docs/qa/submission/evidence/2026-10-04/06_relaunch_replaced.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/06_relaunch_replaced.xml](../../../docs/qa/submission/evidence/2026-10-04/06_relaunch_replaced.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/07_page_before.png](../../../docs/qa/submission/evidence/2026-10-04/07_page_before.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/07_page_before.xml](../../../docs/qa/submission/evidence/2026-10-04/07_page_before.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/08_home_between.png](../../../docs/qa/submission/evidence/2026-10-04/08_home_between.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/08_home_between.xml](../../../docs/qa/submission/evidence/2026-10-04/08_home_between.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/README.md](../../../docs/qa/submission/evidence/2026-10-04/README.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/submission/evidence/2026-10-04/events.jsonl](../../../docs/qa/submission/evidence/2026-10-04/events.jsonl) | 전체 텍스트 검색, JSONL 파싱 |
| [docs/qa/submission/evidence/2026-10-04/failure.png](../../../docs/qa/submission/evidence/2026-10-04/failure.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/failure.xml](../../../docs/qa/submission/evidence/2026-10-04/failure.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/inputs/qa-original.pdf](../../../docs/qa/submission/evidence/2026-10-04/inputs/qa-original.pdf) | 전체 페이지 텍스트 추출, PDF 구조 확인 |
| [docs/qa/submission/evidence/2026-10-04/inputs/qa-replacement.pdf](../../../docs/qa/submission/evidence/2026-10-04/inputs/qa-replacement.pdf) | 전체 페이지 텍스트 추출, PDF 구조 확인 |
| [docs/qa/submission/evidence/2026-10-04/installed-app.json](../../../docs/qa/submission/evidence/2026-10-04/installed-app.json) | 전체 텍스트 검색, JSON 파싱 |
| [docs/qa/submission/evidence/2026-10-04/page-check/07_page_before.png](../../../docs/qa/submission/evidence/2026-10-04/page-check/07_page_before.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/page-check/07_page_before.xml](../../../docs/qa/submission/evidence/2026-10-04/page-check/07_page_before.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/page-check/08_home_between.png](../../../docs/qa/submission/evidence/2026-10-04/page-check/08_home_between.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/page-check/08_home_between.xml](../../../docs/qa/submission/evidence/2026-10-04/page-check/08_home_between.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/page-check/09_page_after_home.png](../../../docs/qa/submission/evidence/2026-10-04/page-check/09_page_after_home.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/page-check/09_page_after_home.xml](../../../docs/qa/submission/evidence/2026-10-04/page-check/09_page_after_home.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/page-check/10_lookup_between.png](../../../docs/qa/submission/evidence/2026-10-04/page-check/10_lookup_between.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/page-check/10_lookup_between.xml](../../../docs/qa/submission/evidence/2026-10-04/page-check/10_lookup_between.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/page-check/events.jsonl](../../../docs/qa/submission/evidence/2026-10-04/page-check/events.jsonl) | 전체 텍스트 검색, JSONL 파싱 |
| [docs/qa/submission/evidence/2026-10-04/page-check/failure.png](../../../docs/qa/submission/evidence/2026-10-04/page-check/failure.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/page-check/failure.xml](../../../docs/qa/submission/evidence/2026-10-04/page-check/failure.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/page-check/inputs/qa-original.pdf](../../../docs/qa/submission/evidence/2026-10-04/page-check/inputs/qa-original.pdf) | 전체 페이지 텍스트 추출, PDF 구조 확인 |
| [docs/qa/submission/evidence/2026-10-04/page-check/inputs/qa-replacement.pdf](../../../docs/qa/submission/evidence/2026-10-04/page-check/inputs/qa-replacement.pdf) | 전체 페이지 텍스트 추출, PDF 구조 확인 |
| [docs/qa/submission/evidence/2026-10-04/page-check/installed-app.json](../../../docs/qa/submission/evidence/2026-10-04/page-check/installed-app.json) | 전체 텍스트 검색, JSON 파싱 |
| [docs/qa/submission/evidence/2026-10-04/page-final/events.jsonl](../../../docs/qa/submission/evidence/2026-10-04/page-final/events.jsonl) | 전체 텍스트 검색, JSONL 파싱 |
| [docs/qa/submission/evidence/2026-10-04/page-final/inputs/qa-original.pdf](../../../docs/qa/submission/evidence/2026-10-04/page-final/inputs/qa-original.pdf) | 전체 페이지 텍스트 추출, PDF 구조 확인 |
| [docs/qa/submission/evidence/2026-10-04/page-final/inputs/qa-replacement.pdf](../../../docs/qa/submission/evidence/2026-10-04/page-final/inputs/qa-replacement.pdf) | 전체 페이지 텍스트 추출, PDF 구조 확인 |
| [docs/qa/submission/evidence/2026-10-04/page-final/installed-app.json](../../../docs/qa/submission/evidence/2026-10-04/page-final/installed-app.json) | 전체 텍스트 검색, JSON 파싱 |
| [docs/qa/submission/evidence/2026-10-04/page-verified/07_page_before.png](../../../docs/qa/submission/evidence/2026-10-04/page-verified/07_page_before.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/page-verified/07_page_before.xml](../../../docs/qa/submission/evidence/2026-10-04/page-verified/07_page_before.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/page-verified/08_home_between.png](../../../docs/qa/submission/evidence/2026-10-04/page-verified/08_home_between.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/page-verified/08_home_between.xml](../../../docs/qa/submission/evidence/2026-10-04/page-verified/08_home_between.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/page-verified/09_page_after_home.png](../../../docs/qa/submission/evidence/2026-10-04/page-verified/09_page_after_home.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/page-verified/09_page_after_home.xml](../../../docs/qa/submission/evidence/2026-10-04/page-verified/09_page_after_home.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/page-verified/10_lookup_between.png](../../../docs/qa/submission/evidence/2026-10-04/page-verified/10_lookup_between.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/page-verified/10_lookup_between.xml](../../../docs/qa/submission/evidence/2026-10-04/page-verified/10_lookup_between.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/page-verified/11_page_after_lookup.png](../../../docs/qa/submission/evidence/2026-10-04/page-verified/11_page_after_lookup.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/page-verified/11_page_after_lookup.xml](../../../docs/qa/submission/evidence/2026-10-04/page-verified/11_page_after_lookup.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/page-verified/12_library_hub.png](../../../docs/qa/submission/evidence/2026-10-04/page-verified/12_library_hub.png) | 이미지 디코딩, 전체 이미지의 축소 화면 확인 |
| [docs/qa/submission/evidence/2026-10-04/page-verified/12_library_hub.xml](../../../docs/qa/submission/evidence/2026-10-04/page-verified/12_library_hub.xml) | 전체 텍스트 검색, XML 파싱 |
| [docs/qa/submission/evidence/2026-10-04/page-verified/events.jsonl](../../../docs/qa/submission/evidence/2026-10-04/page-verified/events.jsonl) | 전체 텍스트 검색, JSONL 파싱 |
| [docs/qa/submission/evidence/2026-10-04/page-verified/inputs/qa-original.pdf](../../../docs/qa/submission/evidence/2026-10-04/page-verified/inputs/qa-original.pdf) | 전체 페이지 텍스트 추출, PDF 구조 확인 |
| [docs/qa/submission/evidence/2026-10-04/page-verified/inputs/qa-replacement.pdf](../../../docs/qa/submission/evidence/2026-10-04/page-verified/inputs/qa-replacement.pdf) | 전체 페이지 텍스트 추출, PDF 구조 확인 |
| [docs/qa/submission/evidence/2026-10-04/page-verified/installed-app.json](../../../docs/qa/submission/evidence/2026-10-04/page-verified/installed-app.json) | 전체 텍스트 검색, JSON 파싱 |
| [docs/qa/submission/portfolio.md](../../../docs/qa/submission/portfolio.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/qa/submission/tools/build_pdf.py](../../../docs/qa/submission/tools/build_pdf.py) | 전체 텍스트 검색, Python 구문 검사 |
| [docs/spec/README.md](../../../docs/spec/README.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/spec/spec_drift_f93aacc.md](../../../docs/spec/spec_drift_f93aacc.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/spec/기능정의서_MVP.md](../../../docs/spec/%EA%B8%B0%EB%8A%A5%EC%A0%95%EC%9D%98%EC%84%9C_MVP.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/spec/기능정의서_도구_설정_홈.md](../../../docs/spec/%EA%B8%B0%EB%8A%A5%EC%A0%95%EC%9D%98%EC%84%9C_%EB%8F%84%EA%B5%AC_%EC%84%A4%EC%A0%95_%ED%99%88.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [docs/spec/원본_v2.2.md](../../../docs/spec/%EC%9B%90%EB%B3%B8_v2.2.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [output/pdf/knitgether_qa_portfolio.pdf](../../../output/pdf/knitgether_qa_portfolio.pdf) | 전체 페이지 텍스트 추출, PDF 구조 확인 |
| [qa/api-probes/README.md](../../../qa/api-probes/README.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [qa/api-probes/newapi_smoke.sh](../../../qa/api-probes/newapi_smoke.sh) | 전체 텍스트 검색 |
| [qa/api-probes/sync08_regression.sh](../../../qa/api-probes/sync08_regression.sh) | 전체 텍스트 검색 |
| [qa/api-tests/.gitignore](../../../qa/api-tests/.gitignore) | 전체 텍스트 검색 |
| [qa/api-tests/README.md](../../../qa/api-tests/README.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [qa/api-tests/conftest.py](../../../qa/api-tests/conftest.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/helpers.py](../../../qa/api-tests/helpers.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/requirements.txt](../../../qa/api-tests/requirements.txt) | 전체 텍스트 검색 |
| [qa/api-tests/test_01_ownership_isolation.py](../../../qa/api-tests/test_01_ownership_isolation.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_02_last_write_wins.py](../../../qa/api-tests/test_02_last_write_wins.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_03_create_idempotency.py](../../../qa/api-tests/test_03_create_idempotency.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_04_delete_cascade.py](../../../qa/api-tests/test_04_delete_cascade.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_05_transaction_atomicity.py](../../../qa/api-tests/test_05_transaction_atomicity.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_06_auth_and_boundaries.py](../../../qa/api-tests/test_06_auth_and_boundaries.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_07_last_worked_at.py](../../../qa/api-tests/test_07_last_worked_at.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_08_network_degradation.py](../../../qa/api-tests/test_08_network_degradation.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_09_transferred_from_06.py](../../../qa/api-tests/test_09_transferred_from_06.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_10_auth_contract.py](../../../qa/api-tests/test_10_auth_contract.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_11_sync_loss_regression.py](../../../qa/api-tests/test_11_sync_loss_regression.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_12_library_crud.py](../../../qa/api-tests/test_12_library_crud.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_13_row_counter_isolation.py](../../../qa/api-tests/test_13_row_counter_isolation.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_14_skill_soft_delete.py](../../../qa/api-tests/test_14_skill_soft_delete.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_15_pattern_copy_file_integrity.py](../../../qa/api-tests/test_15_pattern_copy_file_integrity.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_16_coverage_promotions.py](../../../qa/api-tests/test_16_coverage_promotions.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_17_conflict_timestamp_precision.py](../../../qa/api-tests/test_17_conflict_timestamp_precision.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_18_library_input_limits.py](../../../qa/api-tests/test_18_library_input_limits.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_19_patch_replace_contract.py](../../../qa/api-tests/test_19_patch_replace_contract.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/api-tests/test_20_login_attempt_limit.py](../../../qa/api-tests/test_20_login_attempt_limit.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/.gitignore](../../../qa/appium/.gitignore) | 전체 텍스트 검색 |
| [qa/appium/README.md](../../../qa/appium/README.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [qa/appium/capture_portfolio.py](../../../qa/appium/capture_portfolio.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/conftest.py](../../../qa/appium/conftest.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/make_portfolio_fixtures.py](../../../qa/appium/make_portfolio_fixtures.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/make_sample_patterns.py](../../../qa/appium/make_sample_patterns.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/pages/__init__.py](../../../qa/appium/pages/__init__.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/pages/auth_page.py](../../../qa/appium/pages/auth_page.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/pages/base_page.py](../../../qa/appium/pages/base_page.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/pages/counter_panel_page.py](../../../qa/appium/pages/counter_panel_page.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/pages/home_page.py](../../../qa/appium/pages/home_page.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/pages/library_page.py](../../../qa/appium/pages/library_page.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/pages/my_knitting_page.py](../../../qa/appium/pages/my_knitting_page.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/pages/onboarding_page.py](../../../qa/appium/pages/onboarding_page.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/pages/pattern_panel_page.py](../../../qa/appium/pages/pattern_panel_page.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/pages/project_form_page.py](../../../qa/appium/pages/project_form_page.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/pages/project_info_page.py](../../../qa/appium/pages/project_info_page.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/pages/work_time_panel_page.py](../../../qa/appium/pages/work_time_panel_page.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/pages/workspace_page.py](../../../qa/appium/pages/workspace_page.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/requirements.txt](../../../qa/appium/requirements.txt) | 전체 텍스트 검색 |
| [qa/appium/support/__init__.py](../../../qa/appium/support/__init__.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/support/netgate.py](../../../qa/appium/support/netgate.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/support/paths.py](../../../qa/appium/support/paths.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/support/seed.py](../../../qa/appium/support/seed.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/support/server_api.py](../../../qa/appium/support/server_api.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/support/simctl.py](../../../qa/appium/support/simctl.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/support/texts.py](../../../qa/appium/support/texts.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/__init__.py](../../../qa/appium/tests/__init__.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_def23_background_session.py](../../../qa/appium/tests/test_def23_background_session.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_skill_cache_pruning.py](../../../qa/appium/tests/test_skill_cache_pruning.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_tc01_onboarding.py](../../../qa/appium/tests/test_tc01_onboarding.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_tc02_signup.py](../../../qa/appium/tests/test_tc02_signup.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_tc03_login.py](../../../qa/appium/tests/test_tc03_login.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_tc04_project_create.py](../../../qa/appium/tests/test_tc04_project_create.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_tc05_project_edit.py](../../../qa/appium/tests/test_tc05_project_edit.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_tc06_project_delete.py](../../../qa/appium/tests/test_tc06_project_delete.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_tc07_project_limit.py](../../../qa/appium/tests/test_tc07_project_limit.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_tc08_sort_filter.py](../../../qa/appium/tests/test_tc08_sort_filter.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_tc09_favorite.py](../../../qa/appium/tests/test_tc09_favorite.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_tc10a_workspace_pattern.py](../../../qa/appium/tests/test_tc10a_workspace_pattern.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_tc10b_workspace_counter.py](../../../qa/appium/tests/test_tc10b_workspace_counter.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_tc10c_workspace_info.py](../../../qa/appium/tests/test_tc10c_workspace_info.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_tc11_persistence.py](../../../qa/appium/tests/test_tc11_persistence.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_tc12_library_create.py](../../../qa/appium/tests/test_tc12_library_create.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_tc13_library_edit.py](../../../qa/appium/tests/test_tc13_library_edit.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_tc14_library_delete.py](../../../qa/appium/tests/test_tc14_library_delete.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_tc15_logout.py](../../../qa/appium/tests/test_tc15_logout.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/appium/tests/test_tc16_offline_sync.py](../../../qa/appium/tests/test_tc16_offline_sync.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/mutation/README.md](../../../qa/mutation/README.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [qa/mutation/injections.py](../../../qa/mutation/injections.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/mutation/run_mutation.py](../../../qa/mutation/run_mutation.py) | 전체 텍스트 검색, Python 구문 검사 |
| [qa/tooling-tests/README.md](../../../qa/tooling-tests/README.md) | 전체 텍스트 검색 및 해당 문맥 검토, 링크 검사 |
| [qa/tooling-tests/check-postman.cjs](../../../qa/tooling-tests/check-postman.cjs) | 전체 텍스트 검색 |
| [qa/tooling-tests/test_review_guards.py](../../../qa/tooling-tests/test_review_guards.py) | 전체 텍스트 검색, Python 구문 검사 |
| [server/.env.example](../../../server/.env.example) | 전체 텍스트 검색 |
| [server/docker-compose.yml](../../../server/docker-compose.yml) | 전체 텍스트 검색 |
| [server/nest-cli.json](../../../server/nest-cli.json) | 전체 텍스트 검색, JSON 파싱 |
| [server/package-lock.json](../../../server/package-lock.json) | 전체 텍스트 검색, JSON 파싱 |
| [server/package.json](../../../server/package.json) | 전체 텍스트 검색, JSON 파싱 |
| [server/prisma/migrations/20260705114500_init_project_list/migration.sql](../../../server/prisma/migrations/20260705114500_init_project_list/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260706000000_add_pattern_files/migration.sql](../../../server/prisma/migrations/20260706000000_add_pattern_files/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260706010000_add_project_pattern_copies/migration.sql](../../../server/prisma/migrations/20260706010000_add_project_pattern_copies/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260706020000_add_project_pattern_copy_drawing_storage/migration.sql](../../../server/prisma/migrations/20260706020000_add_project_pattern_copy_drawing_storage/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260706030000_add_row_instructions/migration.sql](../../../server/prisma/migrations/20260706030000_add_row_instructions/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260709010000_add_gauge_records/migration.sql](../../../server/prisma/migrations/20260709010000_add_gauge_records/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260709020000_add_project_schedule_fields/migration.sql](../../../server/prisma/migrations/20260709020000_add_project_schedule_fields/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260709030000_add_skills/migration.sql](../../../server/prisma/migrations/20260709030000_add_skills/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260709040000_add_library_items/migration.sql](../../../server/prisma/migrations/20260709040000_add_library_items/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260709050000_add_user_accounts/migration.sql](../../../server/prisma/migrations/20260709050000_add_user_accounts/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260709060000_add_project_material_snapshots/migration.sql](../../../server/prisma/migrations/20260709060000_add_project_material_snapshots/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260709070000_add_project_yarn_usages/migration.sql](../../../server/prisma/migrations/20260709070000_add_project_yarn_usages/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260709080000_add_project_pattern_copy_file_storage/migration.sql](../../../server/prisma/migrations/20260709080000_add_project_pattern_copy_file_storage/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260709090000_add_gauge_measurement_targets/migration.sql](../../../server/prisma/migrations/20260709090000_add_gauge_measurement_targets/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260709220000_add_tool_items/migration.sql](../../../server/prisma/migrations/20260709220000_add_tool_items/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260709230000_add_project_progress_photos/migration.sql](../../../server/prisma/migrations/20260709230000_add_project_progress_photos/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260710000000_add_dictionary_terms/migration.sql](../../../server/prisma/migrations/20260710000000_add_dictionary_terms/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260711060000_add_system_skill_levels/migration.sql](../../../server/prisma/migrations/20260711060000_add_system_skill_levels/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260711070000_extend_system_skills_from_blog/migration.sql](../../../server/prisma/migrations/20260711070000_extend_system_skills_from_blog/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260729120000_add_dictionary_is_system/migration.sql](../../../server/prisma/migrations/20260729120000_add_dictionary_is_system/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260809122156_add_project_yarn_needle_links/migration.sql](../../../server/prisma/migrations/20260809122156_add_project_yarn_needle_links/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260810160530_add_library_item_photos/migration.sql](../../../server/prisma/migrations/20260810160530_add_library_item_photos/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/20260915124935_add_login_attempt_limit/migration.sql](../../../server/prisma/migrations/20260915124935_add_login_attempt_limit/migration.sql) | 전체 텍스트 검색 |
| [server/prisma/migrations/migration_lock.toml](../../../server/prisma/migrations/migration_lock.toml) | 전체 텍스트 검색 |
| [server/prisma/schema.prisma](../../../server/prisma/schema.prisma) | 전체 텍스트 검색 |
| [server/public/admin.html](../../../server/public/admin.html) | 전체 텍스트 검색 |
| [server/scripts/reset-test-data.ts](../../../server/scripts/reset-test-data.ts) | 전체 텍스트 검색 |
| [server/scripts/seed-system-content.ts](../../../server/scripts/seed-system-content.ts) | 전체 텍스트 검색 |
| [server/src/app.module.ts](../../../server/src/app.module.ts) | 전체 텍스트 검색 |
| [server/src/app.setup.ts](../../../server/src/app.setup.ts) | 전체 텍스트 검색 |
| [server/src/auth/access-token.service.ts](../../../server/src/auth/access-token.service.ts) | 전체 텍스트 검색 |
| [server/src/auth/api-auth.guard.ts](../../../server/src/auth/api-auth.guard.ts) | 전체 텍스트 검색 |
| [server/src/auth/auth-login.dto.ts](../../../server/src/auth/auth-login.dto.ts) | 전체 텍스트 검색 |
| [server/src/auth/auth-register.dto.ts](../../../server/src/auth/auth-register.dto.ts) | 전체 텍스트 검색 |
| [server/src/auth/auth-response.dto.ts](../../../server/src/auth/auth-response.dto.ts) | 전체 텍스트 검색 |
| [server/src/auth/auth.controller.ts](../../../server/src/auth/auth.controller.ts) | 전체 텍스트 검색 |
| [server/src/auth/auth.module.ts](../../../server/src/auth/auth.module.ts) | 전체 텍스트 검색 |
| [server/src/auth/auth.service.ts](../../../server/src/auth/auth.service.ts) | 전체 텍스트 검색 |
| [server/src/auth/current-user.decorator.ts](../../../server/src/auth/current-user.decorator.ts) | 전체 텍스트 검색 |
| [server/src/auth/password.service.ts](../../../server/src/auth/password.service.ts) | 전체 텍스트 검색 |
| [server/src/database/database.module.ts](../../../server/src/database/database.module.ts) | 전체 텍스트 검색 |
| [server/src/database/prisma.service.ts](../../../server/src/database/prisma.service.ts) | 전체 텍스트 검색 |
| [server/src/dictionary/dictionary-response.dto.ts](../../../server/src/dictionary/dictionary-response.dto.ts) | 전체 텍스트 검색 |
| [server/src/dictionary/dictionary-save.dto.ts](../../../server/src/dictionary/dictionary-save.dto.ts) | 전체 텍스트 검색 |
| [server/src/dictionary/dictionary.controller.ts](../../../server/src/dictionary/dictionary.controller.ts) | 전체 텍스트 검색 |
| [server/src/dictionary/dictionary.module.ts](../../../server/src/dictionary/dictionary.module.ts) | 전체 텍스트 검색 |
| [server/src/dictionary/dictionary.service.ts](../../../server/src/dictionary/dictionary.service.ts) | 전체 텍스트 검색 |
| [server/src/gauge-records/gauge-record-response.dto.ts](../../../server/src/gauge-records/gauge-record-response.dto.ts) | 전체 텍스트 검색 |
| [server/src/gauge-records/gauge-record-save.dto.ts](../../../server/src/gauge-records/gauge-record-save.dto.ts) | 전체 텍스트 검색 |
| [server/src/gauge-records/gauge-records.controller.ts](../../../server/src/gauge-records/gauge-records.controller.ts) | 전체 텍스트 검색 |
| [server/src/gauge-records/gauge-records.module.ts](../../../server/src/gauge-records/gauge-records.module.ts) | 전체 텍스트 검색 |
| [server/src/gauge-records/gauge-records.service.ts](../../../server/src/gauge-records/gauge-records.service.ts) | 전체 텍스트 검색 |
| [server/src/gauge-targets/gauge-target-response.dto.ts](../../../server/src/gauge-targets/gauge-target-response.dto.ts) | 전체 텍스트 검색 |
| [server/src/gauge-targets/gauge-target-save.dto.ts](../../../server/src/gauge-targets/gauge-target-save.dto.ts) | 전체 텍스트 검색 |
| [server/src/gauge-targets/gauge-targets.controller.ts](../../../server/src/gauge-targets/gauge-targets.controller.ts) | 전체 텍스트 검색 |
| [server/src/gauge-targets/gauge-targets.module.ts](../../../server/src/gauge-targets/gauge-targets.module.ts) | 전체 텍스트 검색 |
| [server/src/gauge-targets/gauge-targets.service.ts](../../../server/src/gauge-targets/gauge-targets.service.ts) | 전체 텍스트 검색 |
| [server/src/health/health.controller.ts](../../../server/src/health/health.controller.ts) | 전체 텍스트 검색 |
| [server/src/health/health.module.ts](../../../server/src/health/health.module.ts) | 전체 텍스트 검색 |
| [server/src/library/library-response.dto.ts](../../../server/src/library/library-response.dto.ts) | 전체 텍스트 검색 |
| [server/src/library/library-save.dto.ts](../../../server/src/library/library-save.dto.ts) | 전체 텍스트 검색 |
| [server/src/library/library.controller.ts](../../../server/src/library/library.controller.ts) | 전체 텍스트 검색 |
| [server/src/library/library.module.ts](../../../server/src/library/library.module.ts) | 전체 텍스트 검색 |
| [server/src/library/library.service.ts](../../../server/src/library/library.service.ts) | 전체 텍스트 검색 |
| [server/src/listen-options.ts](../../../server/src/listen-options.ts) | 전체 텍스트 검색 |
| [server/src/main.ts](../../../server/src/main.ts) | 전체 텍스트 검색 |
| [server/src/patterns/pattern-create-fields.dto.ts](../../../server/src/patterns/pattern-create-fields.dto.ts) | 전체 텍스트 검색 |
| [server/src/patterns/pattern-response.dto.ts](../../../server/src/patterns/pattern-response.dto.ts) | 전체 텍스트 검색 |
| [server/src/patterns/pattern-update.dto.ts](../../../server/src/patterns/pattern-update.dto.ts) | 전체 텍스트 검색 |
| [server/src/patterns/patterns.controller.ts](../../../server/src/patterns/patterns.controller.ts) | 전체 텍스트 검색 |
| [server/src/patterns/patterns.module.ts](../../../server/src/patterns/patterns.module.ts) | 전체 텍스트 검색 |
| [server/src/patterns/patterns.service.ts](../../../server/src/patterns/patterns.service.ts) | 전체 텍스트 검색 |
| [server/src/patterns/uploaded-pattern-file.ts](../../../server/src/patterns/uploaded-pattern-file.ts) | 전체 텍스트 검색 |
| [server/src/profile/profile-response.dto.ts](../../../server/src/profile/profile-response.dto.ts) | 전체 텍스트 검색 |
| [server/src/profile/profile-save.dto.ts](../../../server/src/profile/profile-save.dto.ts) | 전체 텍스트 검색 |
| [server/src/profile/profile.controller.ts](../../../server/src/profile/profile.controller.ts) | 전체 텍스트 검색 |
| [server/src/profile/profile.module.ts](../../../server/src/profile/profile.module.ts) | 전체 텍스트 검색 |
| [server/src/profile/profile.service.ts](../../../server/src/profile/profile.service.ts) | 전체 텍스트 검색 |
| [server/src/projects/project-response.dto.ts](../../../server/src/projects/project-response.dto.ts) | 전체 텍스트 검색 |
| [server/src/projects/project-save.dto.ts](../../../server/src/projects/project-save.dto.ts) | 전체 텍스트 검색 |
| [server/src/projects/projects.controller.ts](../../../server/src/projects/projects.controller.ts) | 전체 텍스트 검색 |
| [server/src/projects/projects.module.ts](../../../server/src/projects/projects.module.ts) | 전체 텍스트 검색 |
| [server/src/projects/projects.service.ts](../../../server/src/projects/projects.service.ts) | 전체 텍스트 검색 |
| [server/src/skills/skill-animations.controller.ts](../../../server/src/skills/skill-animations.controller.ts) | 전체 텍스트 검색 |
| [server/src/skills/skill-level-save.dto.ts](../../../server/src/skills/skill-level-save.dto.ts) | 전체 텍스트 검색 |
| [server/src/skills/skill-response.dto.ts](../../../server/src/skills/skill-response.dto.ts) | 전체 텍스트 검색 |
| [server/src/skills/skill-save.dto.ts](../../../server/src/skills/skill-save.dto.ts) | 전체 텍스트 검색 |
| [server/src/skills/skills.controller.ts](../../../server/src/skills/skills.controller.ts) | 전체 텍스트 검색 |
| [server/src/skills/skills.module.ts](../../../server/src/skills/skills.module.ts) | 전체 텍스트 검색 |
| [server/src/skills/skills.service.ts](../../../server/src/skills/skills.service.ts) | 전체 텍스트 검색 |
| [server/src/storage/local-file-storage.service.ts](../../../server/src/storage/local-file-storage.service.ts) | 전체 텍스트 검색 |
| [server/src/storage/storage.module.ts](../../../server/src/storage/storage.module.ts) | 전체 텍스트 검색 |
| [server/test/auth-configuration.e2e-spec.ts](../../../server/test/auth-configuration.e2e-spec.ts) | 전체 텍스트 검색 |
| [server/test/auth.e2e-spec.ts](../../../server/test/auth.e2e-spec.ts) | 전체 텍스트 검색 |
| [server/test/dictionary.e2e-spec.ts](../../../server/test/dictionary.e2e-spec.ts) | 전체 텍스트 검색 |
| [server/test/gauge-records.e2e-spec.ts](../../../server/test/gauge-records.e2e-spec.ts) | 전체 텍스트 검색 |
| [server/test/gauge-targets.e2e-spec.ts](../../../server/test/gauge-targets.e2e-spec.ts) | 전체 텍스트 검색 |
| [server/test/health.e2e-spec.ts](../../../server/test/health.e2e-spec.ts) | 전체 텍스트 검색 |
| [server/test/jest-e2e.json](../../../server/test/jest-e2e.json) | 전체 텍스트 검색, JSON 파싱 |
| [server/test/jest.setup-env.ts](../../../server/test/jest.setup-env.ts) | 전체 텍스트 검색 |
| [server/test/library.e2e-spec.ts](../../../server/test/library.e2e-spec.ts) | 전체 텍스트 검색 |
| [server/test/listen-options.e2e-spec.ts](../../../server/test/listen-options.e2e-spec.ts) | 전체 텍스트 검색 |
| [server/test/patterns.e2e-spec.ts](../../../server/test/patterns.e2e-spec.ts) | 전체 텍스트 검색 |
| [server/test/profile.e2e-spec.ts](../../../server/test/profile.e2e-spec.ts) | 전체 텍스트 검색 |
| [server/test/projects.e2e-spec.ts](../../../server/test/projects.e2e-spec.ts) | 전체 텍스트 검색 |
| [server/test/skills.e2e-spec.ts](../../../server/test/skills.e2e-spec.ts) | 전체 텍스트 검색 |
| [server/tsconfig.build.json](../../../server/tsconfig.build.json) | 전체 텍스트 검색, JSON 파싱 |
| [server/tsconfig.json](../../../server/tsconfig.json) | 전체 텍스트 검색, JSON 파싱 |
