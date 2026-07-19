import SwiftUI

struct SkillTestResultView: View {
    let summary: SkillTestResultSummary
    let skillRepository: any SkillRepository
    var statusMessage: String?
    let doneAction: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let statusMessage {
                    AppFormStatusBanner(message: statusMessage)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("스킬 테스트 완료")
                        .font(.largeTitle.bold())

                    Text("모르는 스킬은 뜨개 애니메이션에서 다시 확인할 수 있어요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                summaryCard

                VStack(spacing: 12) {
                    NavigationLink {
                        SkillToolListView(skillRepository: skillRepository, mode: .navigation)
                    } label: {
                        Label("스킬 창고 보기", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        doneAction()
                    } label: {
                        Text("완료")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .warmScreenBackground()
        .navigationTitle("결과")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("결과 요약")
                .font(.headline)

            Text("전체 \(summary.totalCount)개")
                .font(.title3.bold())

            VStack(alignment: .leading, spacing: 10) {
                resultRow(title: SkillLevelFormatter.unknown, count: summary.unknownCount)
                resultRow(title: SkillLevelFormatter.unsure, count: summary.unsureCount)
                resultRow(title: SkillLevelFormatter.known, count: summary.knownCount)
            }

            Divider()

            Text("가장 많은 상태: \(summary.dominantLevelText)")
                .font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .appCard()
    }

    private func resultRow(title: String, count: Int) -> some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(SkillLevelFormatter.color(for: title))
                    .frame(width: 10, height: 10)

                Text(title)
                    .font(.subheadline)
            }

            Spacer()

            Text("\(count)개")
                .font(.subheadline.bold())
        }
    }
}
