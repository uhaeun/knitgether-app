import SwiftUI

struct SkillTestProgressView: View {
    let progressText: String
    let progressValue: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("진행률")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Spacer()

                Text(progressText)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progressValue)
        }
        .padding()
        .appCard()
    }
}
