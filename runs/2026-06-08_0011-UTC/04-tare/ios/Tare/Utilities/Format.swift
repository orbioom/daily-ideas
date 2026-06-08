import Foundation

enum Format {
    static let dayTime: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE d MMM · HH:mm"; return f
    }()
    static let day: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE d MMM"; return f
    }()
    static let monthDay: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d MMM"; return f
    }()
    static let target: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d MMM yyyy"; return f
    }()
}
