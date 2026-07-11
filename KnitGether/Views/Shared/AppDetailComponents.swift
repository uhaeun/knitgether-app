import SwiftUI

struct AppDetailHeaderView<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let tint: Color
    @ViewBuilder let trailing: () -> Trailing

    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        tint: Color = AppTheme.Color.accent,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 54, height: 54)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.Color.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)

            trailing()
        }
        .padding(16)
        .appCard(cornerRadius: 20)
    }
}

extension AppDetailHeaderView where Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        tint: Color = AppTheme.Color.accent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
        trailing = { EmptyView() }
    }
}

struct AppDetailInfoRow: View {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = AppTheme.Color.accent

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundStyle(tint)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer(minLength: 12)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Color.primaryText)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 5)
    }
}

struct AppMetricChip: View {
    let text: String
    let systemImage: String
    var tint: Color = AppTheme.Color.accent

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

struct AppSoftPanel<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Color.accentSoft.opacity(0.6), in: RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.Radius.small, style: .continuous)
                    .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
            }
    }
}

extension View {
    func listRowStyle() -> some View {
        listRowInsets(EdgeInsets(top: 7, leading: 18, bottom: 7, trailing: 18))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
