import SwiftUI

struct ProjectStatusGuideView: View {
    private let statuses: [(code: String, name: String, detail: String)] = [
        ("CO", "시작 전", "아직 시작하지 않았거나 코 잡기 전인 뜨개"),
        ("WIP", "진행 중", "현재 작업 중인 뜨개"),
        ("UFO", "잠시 멈춤", "한동안 멈춰두었지만 다시 이어갈 수 있는 뜨개"),
        ("FO", "완성", "마무리까지 끝난 뜨개")
    ]

    var body: some View {
        List {
            Section {
                Text("프로젝트 상태는 작업 목록과 통계에서 현재 진행 단계를 구분하는 기준입니다.")
                    .foregroundStyle(.secondary)
            }

            Section("상태 설명") {
                ForEach(statuses, id: \.code) { status in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(status.code)
                                .font(.headline)
                            Text(status.name)
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                        }

                        Text(status.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("뜨개 상태 설명")
        .navigationBarTitleDisplayMode(.inline)
    }
}
