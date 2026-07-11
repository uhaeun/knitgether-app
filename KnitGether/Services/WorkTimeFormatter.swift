import Foundation

enum WorkTimeFormatter {
    static func workTimeText(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let totalMinutes = totalSeconds / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        }

        if minutes > 0 {
            return "\(minutes)분 \(seconds)초"
        }

        return "\(seconds)초"
    }

    static func sessionTimeText(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}
