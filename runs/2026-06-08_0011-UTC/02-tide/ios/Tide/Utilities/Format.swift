import Foundation

enum Format {
    static let time: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()
    static let dayTime: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE d MMM · HH:mm"; return f
    }()
    static let monthYear: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f
    }()
    static let weekday: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f
    }()

    static func signed(_ value: Double) -> String {
        String(format: "%@%.2f", value >= 0 ? "+" : "", value)
    }
}
