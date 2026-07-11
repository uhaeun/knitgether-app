import Combine
import Foundation

struct HomeDashboardSummary: Hashable {
    let profile: UserProfile?
    let projects: [KnittingProject]

    init(profile: UserProfile?, projects: [KnittingProject]) {
        self.profile = profile
        self.projects = projects
    }

    var displayName: String {
        let name = profile?.displayName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "뜨개러" : name
    }

    var totalProjectCount: Int {
        projects.count
    }

    var inProgressProjectCount: Int {
        projects.filter { $0.status == .wip }.count
    }

    var completedProjectCount: Int {
        projects.filter { $0.status == .fo }.count
    }

    var totalWorkTime: TimeInterval {
        projects.reduce(0) { total, project in
            total + project.totalWorkTime
        }
    }

    var continueProject: KnittingProject? {
        let inProgressProjects = projects.filter { $0.status == .wip }

        return inProgressProjects.sorted { first, second in
            if first.isFavorite != second.isFavorite {
                return first.isFavorite
            }

            return comparableWorkDate(for: first) > comparableWorkDate(for: second)
        }.first
    }

    var recentProjects: [KnittingProject] {
        projects
            .filter { $0.lastWorkedAt != nil }
            .sorted { comparableWorkDate(for: $0) > comparableWorkDate(for: $1) }
            .prefix(3)
            .map { $0 }
    }

    private func comparableWorkDate(for project: KnittingProject) -> Date {
        project.lastWorkedAt ?? project.updatedAt
    }
}

@MainActor
final class HomeDashboardViewModel: ObservableObject {
    @Published private(set) var summary = HomeDashboardSummary(profile: nil, projects: [])
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = false

    private let profileRepository: any ProfileRepository
    private let projectRepository: any ProjectRepository

    init(
        profileRepository: any ProfileRepository,
        projectRepository: any ProjectRepository
    ) {
        self.profileRepository = profileRepository
        self.projectRepository = projectRepository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let profile = try await profileRepository.fetchCurrentProfile()
            let projects = try await projectRepository.fetchProjects()
            summary = HomeDashboardSummary(profile: profile, projects: projects)
            errorMessage = nil
        } catch {
            errorMessage = "홈 정보를 불러오지 못했어요."
        }
    }
}
