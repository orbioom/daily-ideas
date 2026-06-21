import Foundation

struct SlideDaily {
    static func seed(for date: Date = Date()) -> UInt64 {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let str = fmt.string(from: date)
        return fnv1a(str)
    }
    static func todayPuzzle() -> SlidePuzzle {
        SlidePuzzle.make(size: 4, seed: seed())
    }
    static func dateString(for date: Date = Date()) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }
    private static func fnv1a(_ s: String) -> UInt64 {
        var hash: UInt64 = 14695981039346656037
        for byte in s.utf8 { hash = (hash ^ UInt64(byte)) &* 1099511628211 }
        return hash
    }
}
