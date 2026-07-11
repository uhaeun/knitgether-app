import SwiftUI

enum SkillLevelFormatter {
    static let unknown = "몰라요"
    static let unsure = "헷갈려요"
    static let known = "잘 알아요"
    private static let legacyUnsure = "애매해요"

    static let levels = [unknown, unsure, known]

    static func normalizedLevel(_ level: String?) -> String {
        let value = level ?? ""
        if value == legacyUnsure {
            return unsure
        }

        return levels.contains(value) ? value : unknown
    }

    static func levelPriority(_ level: String?) -> Int {
        switch normalizedLevel(level) {
        case unknown:
            return 0
        case unsure:
            return 1
        case known:
            return 2
        default:
            return 0
        }
    }

    static func color(for level: String?) -> Color {
        if level == "미등록" {
            return .gray
        }

        switch normalizedLevel(level) {
        case unknown:
            return .red
        case unsure:
            return .orange
        case known:
            return .green
        default:
            return .gray
        }
    }
}
