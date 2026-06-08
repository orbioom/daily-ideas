import Foundation

enum Format {
    static let dayTime: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE d MMM · HH:mm"; return f
    }()
    static let time: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()
    static let day: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE d MMM"; return f
    }()

    static func minutes(_ m: Double) -> String {
        if m < 1 { return "\(Int((m * 60).rounded()))s" }
        if m < 60 { return "\(Int(m.rounded())) min" }
        let h = Int(m) / 60, mm = Int(m) % 60
        return mm == 0 ? "\(h)h" : "\(h)h \(mm)m"
    }

    static func clock(_ seconds: Double) -> String {
        let s = Int(max(0, seconds.rounded()))
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}
