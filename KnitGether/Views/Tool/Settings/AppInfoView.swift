import SwiftUI

struct AppInfoView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.accentColor)

                    Text("KnitGether")
                        .font(.title2.bold())
                    Text("뜨개 작업 보조 앱")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("앱 정보") {
                LabeledContent("버전", value: "0.1.0 MVP")
                LabeledContent("최소 지원", value: "iOS 16")
                LabeledContent("클라이언트", value: "SwiftUI")
                LabeledContent("서버", value: "NestJS")
                LabeledContent("데이터베이스", value: "PostgreSQL / Prisma")
            }

            Section("주요 기능") {
                Text("도안, 단수 카운터, 작업시간, 재료/도구 창고, 게이지 계산, 스킬 학습, 사전, 진행 사진을 계정 기반 서버 저장 구조로 관리합니다.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("앱 정보")
        .navigationBarTitleDisplayMode(.inline)
    }
}
