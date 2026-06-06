import Foundation
import SwiftData

/// A single counter inside a project — rows, pattern repeats, increases, etc.
/// When `repeatLength` > 0 it also tracks position within a repeating block.
@Model
final class Counter {
    var id: UUID = UUID()
    var name: String = "Rows"
    var value: Int = 0
    var step: Int = 1
    var repeatLength: Int = 0   // 0 = no repeat tracking
    var sortIndex: Int = 0
    var project: Project?

    init(name: String = "Rows", value: Int = 0, step: Int = 1, repeatLength: Int = 0, sortIndex: Int = 0) {
        self.name = name
        self.value = value
        self.step = max(1, step)
        self.repeatLength = max(0, repeatLength)
        self.sortIndex = sortIndex
    }

    /// Increment guarded against overflow.
    func increment() {
        if value < Int.max - step { value += step }
    }
    /// Decrement, never below zero.
    func decrement() {
        value = max(0, value - step)
    }

    /// Whether this counter tracks a repeating block.
    var tracksRepeat: Bool { repeatLength > 0 }

    /// Position within the current repeat (1-based), or nil if not tracking.
    var repeatPosition: Int? {
        guard repeatLength > 0, value > 0 else { return repeatLength > 0 ? 0 : nil }
        return ((value - 1) % repeatLength) + 1
    }
    /// Which repeat number we're on (1-based), or nil.
    var repeatNumber: Int? {
        guard repeatLength > 0 else { return nil }
        return value == 0 ? 0 : ((value - 1) / repeatLength) + 1
    }
    /// 0...1 progress through the current repeat block.
    var repeatProgress: Double {
        guard repeatLength > 0 else { return 0 }
        let pos = value == 0 ? 0 : ((value - 1) % repeatLength) + 1
        return Double(pos) / Double(repeatLength)
    }
}
