import SwiftUI

enum AppTheme {
    enum Color {
        static let accent = SwiftUI.Color(red: 0.549, green: 0.471, blue: 0.376)
        static let accentSoft = SwiftUI.Color(red: 0.953, green: 0.914, blue: 0.863)
        static let softAccent = SwiftUI.Color(red: 0.737, green: 0.655, blue: 0.596)

        static let warmBackground = SwiftUI.Color(red: 0.965, green: 0.941, blue: 0.910)
        static let cardBackground = SwiftUI.Color.white
        static let warmDivider = SwiftUI.Color(red: 0.941, green: 0.925, blue: 0.898)
        static let knitTexture = SwiftUI.Color(red: 0.929, green: 0.894, blue: 0.855)
        static let primaryText = SwiftUI.Color(red: 0.169, green: 0.149, blue: 0.133)

        static let sage = SwiftUI.Color(red: 0.35, green: 0.55, blue: 0.42)
        static let sageSoft = SwiftUI.Color(red: 0.35, green: 0.55, blue: 0.42).opacity(0.14)

        static let amber = SwiftUI.Color(red: 0.80, green: 0.58, blue: 0.24)
        static let amberSoft = SwiftUI.Color(red: 0.80, green: 0.58, blue: 0.24).opacity(0.15)

        static let rose = SwiftUI.Color(red: 0.76, green: 0.42, blue: 0.46)
        static let roseSoft = SwiftUI.Color(red: 0.76, green: 0.42, blue: 0.46).opacity(0.14)
        static let danger = SwiftUI.Color(red: 0.73, green: 0.23, blue: 0.25)
        static let dangerSoft = SwiftUI.Color(red: 0.73, green: 0.23, blue: 0.25).opacity(0.12)

        static let slate = SwiftUI.Color(red: 0.45, green: 0.47, blue: 0.53)
        static let slateSoft = SwiftUI.Color(red: 0.45, green: 0.47, blue: 0.53).opacity(0.12)

        static let lavender = SwiftUI.Color(red: 0.56, green: 0.50, blue: 0.70)
        static let lavenderSoft = SwiftUI.Color(red: 0.56, green: 0.50, blue: 0.70).opacity(0.14)
    }

    enum Card {
        static let cornerRadius: CGFloat = 20
        static let shadowRadius: CGFloat = 2
        static let shadowY: CGFloat = 1
        static let shadowOpacity: Double = 0.04
    }

    enum Radius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 22
        static let xl: CGFloat = 32
    }

    static func statusColorSoft(for status: ProjectStatus) -> (fg: SwiftUI.Color, bg: SwiftUI.Color) {
        switch status {
        case .planned:
            return (Color.slate, Color.slateSoft)
        case .wip:
            return (Color.sage, Color.sageSoft)
        case .ufo:
            return (Color.amber, Color.amberSoft)
        case .fo:
            return (Color.lavender, Color.lavenderSoft)
        }
    }
}

struct AppCardStyle: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.Card.cornerRadius

    func body(content: Content) -> some View {
        content
            .background(AppTheme.Color.cardBackground, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.Color.warmDivider, lineWidth: 1)
            }
            .shadow(
                color: SwiftUI.Color.black.opacity(AppTheme.Card.shadowOpacity),
                radius: AppTheme.Card.shadowRadius,
                x: 0,
                y: AppTheme.Card.shadowY
            )
    }
}

extension View {
    func appCard(cornerRadius: CGFloat = AppTheme.Card.cornerRadius) -> some View {
        modifier(AppCardStyle(cornerRadius: cornerRadius))
    }

    func warmScreenBackground() -> some View {
        background(AppTheme.Color.warmBackground.ignoresSafeArea())
    }
}
