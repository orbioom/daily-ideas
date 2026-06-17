import Foundation
import SwiftData

/// Determines which program day comes next in the rotation.
enum Rotation {
    /// The next day to train in `program`, based on how many sessions have been completed.
    static func nextDay(in program: Program, context: ModelContext) -> ProgramDay? {
        let days = program.orderedDays
        guard !days.isEmpty else { return nil }
        let name = program.name
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isComplete && $0.programName == name }
        )
        let completed = (try? context.fetchCount(descriptor)) ?? 0
        let index = completed % days.count
        return days[safe: index] ?? days.first
    }
}
