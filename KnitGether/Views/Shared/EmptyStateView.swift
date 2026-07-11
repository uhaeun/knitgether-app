import SwiftUI

struct EmptyStateView<ActionLabel: View>: View {
    let title: String
    let description: String
    let systemImage: String?
    let action: (() -> Void)?
    @ViewBuilder let actionLabel: () -> ActionLabel

    init(
        title: String,
        description: String,
        systemImage: String? = nil,
        action: @escaping () -> Void,
        @ViewBuilder actionLabel: @escaping () -> ActionLabel
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.action = action
        self.actionLabel = actionLabel
    }

    init(
        title: String,
        description: String,
        systemImage: String? = nil,
        @ViewBuilder actionLabel: @escaping () -> ActionLabel
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        action = nil
        self.actionLabel = actionLabel
    }

    var body: some View {
        VStack(spacing: 14) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(AppTheme.Color.accent)
                    .frame(width: 52, height: 52)
                    .background(AppTheme.Color.accentSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let action {
                Button(action: action) {
                    actionLabel()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.Color.accent)
            } else {
                actionLabel()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .appCard(cornerRadius: 20)
    }
}

extension EmptyStateView where ActionLabel == EmptyView {
    init(
        title: String,
        description: String,
        systemImage: String? = nil
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        action = nil
        actionLabel = { EmptyView() }
    }
}

struct SectionHeaderView: View {
    let title: String
    let description: String?

    init(_ title: String, description: String? = nil) {
        self.title = title
        self.description = description
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.Color.primaryText.opacity(0.56))

            if let description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
