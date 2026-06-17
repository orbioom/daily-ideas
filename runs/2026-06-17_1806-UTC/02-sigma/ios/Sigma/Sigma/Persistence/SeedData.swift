import Foundation
import SwiftData

/// Seeds realistic sample history entries on first launch, guarded so it runs once.
enum SeedData {
    private static let seededKey = "didSeedHistory"

    /// Sample tape entries: expression / result pairs typical of real calculator use.
    private static let samples: [(String, String)] = [
        ("48 × 1.0825", "51.96"),
        ("(1200 + 350) ÷ 4", "387.5"),
        ("sqrt(2)", "1.41421356"),
        ("15% of 240", "36"),
        ("2 ^ 10", "1,024"),
        ("sin(30)", "0.5"),
        ("log(1000)", "3"),
        ("ln(e)", "1"),
        ("7!", "5,040"),
        ("355 ÷ 113", "3.14159292"),
        ("9.81 × 3.5", "34.335"),
        ("100 − 37.5", "62.5"),
        ("12 × 12", "144"),
        ("(5 + 3) × (9 − 2)", "56"),
        ("256 ÷ 8", "32"),
        ("cos(60)", "0.5"),
        ("tan(45)", "1"),
        ("3.14159 × 4 ^ 2", "50.265"),
        ("1 ÷ 3", "0.33333333"),
        ("18 × 0.075", "1.35"),
        ("89 + 144", "233"),
        ("2.5 ^ 3", "15.625"),
        ("sqrt(144)", "12"),
        ("65 × 1.6", "104"),
        ("(42 − 17) ÷ 5", "5"),
        ("999 + 1", "1,000"),
        ("0.1 + 0.2", "0.3"),
        ("60 × 60 × 24", "86,400"),
        ("180 ÷ 3.14159", "57.29583"),
        ("4 × atan(1)", "180"),
        ("1024 × 1024", "1,048,576"),
        ("33 × 3", "99")
    ]

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: seededKey) else { return }

        // Confirm the store is genuinely empty before seeding.
        let descriptor = FetchDescriptor<CalcEntry>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else {
            defaults.set(true, forKey: seededKey)
            return
        }

        let now = Date.now
        for (offset, sample) in samples.enumerated() {
            // Spread timestamps backward so the tape reads chronologically.
            let timestamp = now.addingTimeInterval(TimeInterval(-offset * 1800))
            let entry = CalcEntry(expression: sample.0, result: sample.1, timestamp: timestamp)
            context.insert(entry)
        }

        try? context.save()
        defaults.set(true, forKey: seededKey)
    }
}
