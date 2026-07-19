import SwiftUI

struct AppFormSection<Content: View>: View {
    let title: String
    let description: String?
    let systemImage: String
    var tint: Color = AppTheme.Color.accent
    private let content: Content

    init(
        title: String,
        description: String? = nil,
        systemImage: String,
        tint: Color = AppTheme.Color.accent,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.description = description
        self.systemImage = systemImage
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppTheme.Color.primaryText)

                    if let description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .background(AppTheme.Color.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
            }
        }
    }
}

struct AppFormDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppTheme.Color.warmDivider)
            .frame(height: 1)
            .padding(.leading, 34)
    }
}

struct AppFormTextFieldRow: View {
    let title: String
    let placeholder: String
    let systemImage: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var minHeight: CGFloat? = nil

    var body: some View {
        HStack(alignment: axis == .vertical ? .top : .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Color.accent)
                .frame(width: 22)
                .padding(.top, axis == .vertical ? 3 : 0)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField(placeholder, text: $text, axis: axis)
                    .font(.body)
                    .foregroundStyle(AppTheme.Color.primaryText)
                    .lineLimit(axis == .vertical ? 4...10 : 1...1)
                    .frame(minHeight: minHeight)
            }
        }
        .padding(.vertical, 12)
    }
}

struct AppFormTextEditorRow: View {
    let title: String
    let placeholder: String
    let systemImage: String
    @Binding var text: String
    var minHeight: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Color.accent)
                    .frame(width: 22)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundStyle(.secondary.opacity(0.55))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                }

                TextEditor(text: $text)
                    .frame(minHeight: minHeight)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(AppTheme.Color.primaryText)
            }
            .padding(8)
            .background(AppTheme.Color.accentSoft.opacity(0.45), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.vertical, 12)
    }
}

struct AppFormToggleRow: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Color.accent)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.Color.primaryText)

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .tint(AppTheme.Color.softAccent)
        .padding(.vertical, 12)
    }
}

struct AppFormStepperRow: View {
    let title: String
    let systemImage: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let suffix: String

    var body: some View {
        Stepper(value: $value, in: range) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Color.accent)
                    .frame(width: 22)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Color.primaryText)

                Spacer()

                Text("\(value)\(suffix)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Color.accent)
            }
        }
        .padding(.vertical, 12)
    }
}

struct AppFormDecimalRow: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    var placeholder = "0"

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Color.accent)
                .frame(width: 22)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Color.primaryText)

            Spacer()

            TextField(placeholder, text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.body.monospacedDigit())
                .foregroundStyle(AppTheme.Color.primaryText)
                .frame(maxWidth: 120)
        }
        .padding(.vertical, 12)
    }
}

struct AppFormStatusBanner: View {
    enum Kind {
        case success
        case error

        var systemImage: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .error:
                return "exclamationmark.triangle.fill"
            }
        }

        var foregroundColor: Color {
            switch self {
            case .success:
                return AppTheme.Color.sage
            case .error:
                return AppTheme.Color.amber
            }
        }

        var backgroundColor: Color {
            switch self {
            case .success:
                return AppTheme.Color.sageSoft
            case .error:
                return AppTheme.Color.amberSoft
            }
        }
    }

    let message: String
    var kind: Kind = .success

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: kind.systemImage)
                .foregroundStyle(kind.foregroundColor)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.Color.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(kind.backgroundColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct AppFormErrorBanner: View {
    let message: String

    var body: some View {
        AppFormStatusBanner(message: message, kind: .error)
    }
}

struct AppFormSubmitBar: View {
    let title: String
    let isDisabled: Bool
    let accessibilityIdentifier: String?
    let action: () -> Void

    init(
        title: String = "저장",
        isDisabled: Bool,
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isDisabled = isDisabled
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
    }

    var body: some View {
        button
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private var button: some View {
        let baseButton = Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(
            isDisabled ? AppTheme.Color.softAccent.opacity(0.45) : AppTheme.Color.softAccent,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .disabled(isDisabled)

        if let accessibilityIdentifier {
            baseButton.accessibilityIdentifier(accessibilityIdentifier)
        } else {
            baseButton
        }
    }
}
