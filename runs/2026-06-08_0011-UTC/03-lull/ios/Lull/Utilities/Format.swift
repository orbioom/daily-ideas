import Foundation

enum Format {
    static let dayTime: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE d MMM · HH:mm"; return f
    }()
    static let weekday: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f
    }()

    static func minutes(_ m: Double) -> String {
        if m < 1 { return "\(Int((m * 60).rounded()))s" }
        return String(format: "%.0f min", m)
    }

    static func minutesPrecise(_ m: Double) -> String {
        String(format: "%.1f", m)
    }
}
