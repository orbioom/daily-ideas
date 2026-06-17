import Foundation

/// Pure value type holding the on/off + accent state of the sequencer grid.
/// Rows == DrumVoice.allCases, columns == step count (16 or 32).
struct StepGrid: Equatable, Codable {
    static let rows = DrumVoice.allCases.count   // 8

    private(set) var stepCount: Int
    /// `cells[track][step]` — true when the step is active.
    private(set) var cells: [[Bool]]
    /// `accents[track][step]` — true when the active step is accented (louder).
    private(set) var accents: [[Bool]]

    init(stepCount: Int = 16) {
        let count = StepGrid.clampStepCount(stepCount)
        self.stepCount = count
        self.cells = Array(repeating: Array(repeating: false, count: count), count: StepGrid.rows)
        self.accents = Array(repeating: Array(repeating: false, count: count), count: StepGrid.rows)
    }

    static func clampStepCount(_ value: Int) -> Int {
        value >= Pro.proStepCount ? Pro.proStepCount : Pro.freeStepCount
    }

    func isActive(track: Int, step: Int) -> Bool {
        guard cells.indices.contains(track), cells[track].indices.contains(step) else { return false }
        return cells[track][step]
    }

    func isAccented(track: Int, step: Int) -> Bool {
        guard accents.indices.contains(track), accents[track].indices.contains(step) else { return false }
        return accents[track][step]
    }

    mutating func toggle(track: Int, step: Int) {
        guard cells.indices.contains(track), cells[track].indices.contains(step) else { return }
        cells[track][step].toggle()
        if !cells[track][step] {
            accents[track][step] = false
        }
    }

    mutating func setActive(_ active: Bool, track: Int, step: Int) {
        guard cells.indices.contains(track), cells[track].indices.contains(step) else { return }
        cells[track][step] = active
        if !active { accents[track][step] = false }
    }

    mutating func toggleAccent(track: Int, step: Int) {
        guard accents.indices.contains(track), accents[track].indices.contains(step) else { return }
        guard isActive(track: track, step: step) else { return }
        accents[track][step].toggle()
    }

    mutating func clear() {
        cells = Array(repeating: Array(repeating: false, count: stepCount), count: StepGrid.rows)
        accents = Array(repeating: Array(repeating: false, count: stepCount), count: StepGrid.rows)
    }

    /// Resize keeping existing data where it overlaps.
    mutating func resize(to newCount: Int) {
        let count = StepGrid.clampStepCount(newCount)
        guard count != stepCount else { return }
        for track in cells.indices {
            cells[track] = StepGrid.resizedRow(cells[track], to: count)
            accents[track] = StepGrid.resizedRow(accents[track], to: count)
        }
        stepCount = count
    }

    private static func resizedRow(_ row: [Bool], to count: Int) -> [Bool] {
        if row.count == count { return row }
        if row.count > count { return Array(row.prefix(count)) }
        return row + Array(repeating: false, count: count - row.count)
    }

    /// Voices that have at least one active step.
    var activeTrackCount: Int {
        cells.reduce(0) { $0 + ($1.contains(true) ? 1 : 0) }
    }
}
