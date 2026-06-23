import Foundation
import SwiftData

/// Builds the SwiftData container and seeds first-run sample data.
enum PersistenceController {

    static let schema = Schema([
        BreathSession.self,
        MoodEntry.self,
        AppSettings.self,
    ])

    /// Live, on-disk container. Falls back to an in-memory store if disk setup
    /// fails so the app still launches. Returns `nil` only if even the in-memory
    /// store cannot be created, which the app surfaces as a calm error screen
    /// rather than crashing.
    static func makeContainer(inMemory: Bool = false) -> ModelContainer? {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        if let container = try? ModelContainer(for: schema, configurations: [config]) {
            return container
        }
        // Recoverable fallback — never fatalError / try! on launch.
        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try? ModelContainer(for: schema, configurations: [memoryConfig])
    }

    /// A ready-to-use, seeded in-memory container for SwiftUI previews only.
    /// Returns `nil` if the preview sandbox cannot build a store; preview call
    /// sites fall back to a plain view so nothing crashes at runtime.
    @MainActor
    static func previewContainer() -> ModelContainer? {
        guard let container = makeContainer(inMemory: true) else { return nil }
        bootstrap(container.mainContext)
        return container
    }

    /// Ensures a settings row exists and seeds realistic history on first run.
    @MainActor
    static func bootstrap(_ context: ModelContext) {
        ensureSettings(context)
        seedSampleHistoryIfNeeded(context)
    }

    @MainActor
    static func ensureSettings(_ context: ModelContext) {
        let descriptor = FetchDescriptor<AppSettings>()
        let existing = (try? context.fetch(descriptor)) ?? []
        if existing.isEmpty {
            context.insert(AppSettings())
            try? context.save()
        }
    }

    /// Seeds 50+ realistic sessions + mood entries spread across recent weeks so
    /// charts and history are populated on a fresh install.
    @MainActor
    static func seedSampleHistoryIfNeeded(_ context: ModelContext) {
        let sessionCount = (try? context.fetchCount(FetchDescriptor<BreathSession>())) ?? 0
        guard sessionCount == 0 else { return }

        var rng = SeededGenerator(seed: 0xE3B0_C442)
        let calendar = Calendar.current
        let now = Date()
        let patterns = PatternLibrary.all

        // ~58 sessions across the last 45 days, weighted toward recent days.
        var created = 0
        var dayOffset = 0
        while created < 58 && dayOffset < 45 {
            // 0–2 sessions on a given day.
            let perDay = Int(rng.nextDouble() * 2.4)
            for _ in 0..<perDay {
                guard created < 58 else { break }
                guard let dayStart = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
                let minute = 6 * 60 + Int(rng.nextDouble() * 16 * 60) // 6:00–22:00
                let date = calendar.date(bySettingHour: minute / 60,
                                         minute: minute % 60, second: 0, of: dayStart) ?? dayStart
                let pattern = patterns[Int(rng.nextDouble() * Double(patterns.count)) % patterns.count]
                let minutes = [3, 4, 5, 5, 6, 8, 10][Int(rng.nextDouble() * 7) % 7]
                let duration = Double(minutes * 60) * (0.85 + rng.nextDouble() * 0.3)
                let before = 2 + Int(rng.nextDouble() * 3)           // 2–4
                let lift = Int(rng.nextDouble() * 2.4)               // 0–2 improvement
                let after = min(5, before + lift)
                let cycles = max(1, Int(duration / max(4, pattern.cycleSeconds)))
                let session = BreathSession(
                    startedAt: date,
                    durationSeconds: duration,
                    patternID: pattern.id,
                    patternName: pattern.name,
                    styleRaw: pattern.style.rawValue,
                    cyclesCompleted: pattern.isRounds ? pattern.roundCount : cycles,
                    finished: rng.nextDouble() > 0.12,
                    moodBefore: before,
                    moodAfter: after)
                context.insert(session)
                created += 1
            }
            dayOffset += 1
        }

        // Seed ~20 standalone daily mood entries.
        for d in 0..<24 {
            if rng.nextDouble() > 0.25 {
                guard let dayStart = calendar.date(byAdding: .day, value: -d, to: now) else { continue }
                let score = 2 + Int(rng.nextDouble() * 3.2)
                let entry = MoodEntry(date: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: dayStart) ?? dayStart,
                                      score: min(5, max(1, score)))
                context.insert(entry)
            }
        }

        try? context.save()
    }
}

/// Tiny deterministic PRNG so seeded sample data is stable and reproducible.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E37_79B9 : seed }

    mutating func next() -> UInt64 {
        // xorshift64*
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 0x2545_F491_4F6C_DD1D
    }

    mutating func nextDouble() -> Double {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }
}
