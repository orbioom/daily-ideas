import Foundation
import SwiftData

/// Pure, static analytics over a set of `Attack`s. No SwiftData, no UI — every
/// function guards against empty inputs and divide-by-zero so callers never crash.
enum AuraEngine {

    // MARK: - Types

    struct MonthPoint: Identifiable {
        let id = UUID()
        let month: Date          // first day of the month
        let count: Int
        let headacheDays: Int
    }

    struct IntensityPoint: Identifiable {
        let id = UUID()
        let date: Date
        let intensity: Int
    }

    struct TriggerRank: Identifiable {
        let id = UUID()
        let trigger: Trigger
        let presentCount: Int
        let fraction: Double     // share of attacks where present, 0…1
        var name: String { trigger.name }
    }

    struct SymptomRank: Identifiable {
        let id = UUID()
        let symptom: Symptom
        let count: Int
        let fraction: Double
        var name: String { symptom.name }
    }

    struct MedEffect: Identifiable {
        let id = UUID()
        let name: String
        let timesTaken: Int
        let avgRelief: Double     // 0…3
    }

    enum OveruseStatus {
        case ok, atRisk
    }

    struct OveruseResult {
        let status: OveruseStatus
        let acuteDays: Int        // distinct days in last 30 with an acute med
        let threshold: Int
    }

    struct Impact {
        let headacheDays: Int     // distinct days with an attack, last 30
        let hoursAffected: Double // total attack hours, last 30 (ongoing capped at now)
    }

    // MARK: - Basic counts

    static func attacksThisMonth(_ attacks: [Attack], now: Date = .now) -> Int {
        let cal = Calendar.current
        return attacks.filter { cal.isDate($0.start, equalTo: now, toGranularity: .month) }.count
    }

    /// Whole days since the most recent attack started, or nil if none logged.
    static func daysSinceLast(_ attacks: [Attack], now: Date = .now) -> Int? {
        guard let last = attacks.map(\.start).max() else { return nil }
        let cal = Calendar.current
        let from = cal.startOfDay(for: last)
        let to = cal.startOfDay(for: now)
        return cal.dateComponents([.day], from: from, to: to).day
    }

    static func avgIntensity(_ attacks: [Attack]) -> Double {
        guard !attacks.isEmpty else { return 0 }
        let total = attacks.reduce(0) { $0 + $1.intensity }
        return Double(total) / Double(attacks.count)
    }

    /// Average duration in minutes across completed attacks (ongoing excluded).
    static func avgDurationMinutes(_ attacks: [Attack]) -> Double? {
        let durations = attacks.compactMap { $0.durationMinutes }
        guard !durations.isEmpty else { return nil }
        return Double(durations.reduce(0, +)) / Double(durations.count)
    }

    // MARK: - Per-month series

    /// One point per month over the last `months` months (oldest → newest).
    static func monthlySeries(_ attacks: [Attack], months: Int = 6, now: Date = .now) -> [MonthPoint] {
        let cal = Calendar.current
        guard let thisMonthStart = cal.dateInterval(of: .month, for: now)?.start else { return [] }
        var out: [MonthPoint] = []
        for back in stride(from: months - 1, through: 0, by: -1) {
            guard let monthStart = cal.date(byAdding: .month, value: -back, to: thisMonthStart) else { continue }
            let inMonth = attacks.filter { cal.isDate($0.start, equalTo: monthStart, toGranularity: .month) }
            let days = Set(inMonth.map { cal.startOfDay(for: $0.start) }).count
            out.append(MonthPoint(month: monthStart, count: inMonth.count, headacheDays: days))
        }
        return out
    }

    /// Intensity points sorted oldest → newest, optionally limited to recent days.
    static func intensitySeries(_ attacks: [Attack], days: Int? = nil, now: Date = .now) -> [IntensityPoint] {
        let cal = Calendar.current
        var source = attacks
        if let days, let cutoff = cal.date(byAdding: .day, value: -days, to: now) {
            source = attacks.filter { $0.start >= cutoff }
        }
        return source
            .sorted { $0.start < $1.start }
            .map { IntensityPoint(date: $0.start, intensity: $0.intensity) }
    }

    // MARK: - Trigger / symptom correlation

    /// Triggers ranked by how often they coincide with attacks (fraction = present / total).
    static func triggerCorrelation(_ attacks: [Attack]) -> [TriggerRank] {
        guard !attacks.isEmpty else { return [] }
        let total = Double(attacks.count)
        var counts: [PersistentIdentifier: (Trigger, Int)] = [:]
        for attack in attacks {
            // de-dupe within an attack so one attack counts a trigger once
            var seen = Set<PersistentIdentifier>()
            for t in attack.triggers where !seen.contains(t.persistentModelID) {
                seen.insert(t.persistentModelID)
                if let existing = counts[t.persistentModelID] {
                    counts[t.persistentModelID] = (existing.0, existing.1 + 1)
                } else {
                    counts[t.persistentModelID] = (t, 1)
                }
            }
        }
        return counts.values
            .map { TriggerRank(trigger: $0.0, presentCount: $0.1, fraction: Double($0.1) / total) }
            .sorted { $0.presentCount > $1.presentCount }
    }

    /// Symptoms ranked by frequency across attacks.
    static func symptomFrequency(_ attacks: [Attack]) -> [SymptomRank] {
        guard !attacks.isEmpty else { return [] }
        let total = Double(attacks.count)
        var counts: [PersistentIdentifier: (Symptom, Int)] = [:]
        for attack in attacks {
            var seen = Set<PersistentIdentifier>()
            for s in attack.symptoms where !seen.contains(s.persistentModelID) {
                seen.insert(s.persistentModelID)
                if let existing = counts[s.persistentModelID] {
                    counts[s.persistentModelID] = (existing.0, existing.1 + 1)
                } else {
                    counts[s.persistentModelID] = (s, 1)
                }
            }
        }
        return counts.values
            .map { SymptomRank(symptom: $0.0, count: $0.1, fraction: Double($0.1) / total) }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Medication

    /// Average relief (0…3) per medication name, plus how often it was taken.
    static func medicationEffectiveness(_ attacks: [Attack]) -> [MedEffect] {
        var byName: [String: [Int]] = [:]
        for attack in attacks {
            for med in attack.meds {
                byName[med.name, default: []].append(med.relief.score)
            }
        }
        return byName.map { name, scores in
            let avg = scores.isEmpty ? 0 : Double(scores.reduce(0, +)) / Double(scores.count)
            return MedEffect(name: name, timesTaken: scores.count, avgRelief: avg)
        }
        .sorted { $0.timesTaken > $1.timesTaken }
    }

    /// Medication-overuse-headache risk: distinct days in the last 30 with an
    /// acute med taken. Flags `atRisk` once that count reaches the threshold.
    static func medicationOveruse(_ attacks: [Attack], threshold: Int, now: Date = .now) -> OveruseResult {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -30, to: now) ?? now
        var days = Set<Date>()
        for attack in attacks where attack.start >= cutoff {
            // a dose is "on the attack's start day" — good enough for diary-level tracking
            if attack.meds.contains(where: { $0.isAcute }) {
                days.insert(cal.startOfDay(for: attack.start))
            }
        }
        let count = days.count
        return OveruseResult(status: count >= threshold ? .atRisk : .ok,
                             acuteDays: count,
                             threshold: threshold)
    }

    // MARK: - Distributions

    /// Count of attacks at each intensity 1…10 (always 10 entries).
    static func intensityDistribution(_ attacks: [Attack]) -> [(intensity: Int, count: Int)] {
        var buckets = Array(repeating: 0, count: 11) // index 1…10
        for a in attacks {
            let i = min(max(a.intensity, 1), 10)
            buckets[i] += 1
        }
        return (1...10).map { ($0, buckets[$0]) }
    }

    static func mostCommonType(_ attacks: [Attack]) -> HeadacheType? {
        guard !attacks.isEmpty else { return nil }
        let counts = Dictionary(grouping: attacks, by: { $0.type }).mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key
    }

    static func mostCommonLocation(_ attacks: [Attack]) -> HeadLocation? {
        guard !attacks.isEmpty else { return nil }
        let counts = Dictionary(grouping: attacks, by: { $0.location }).mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key
    }

    // MARK: - Impact (MIDAS-like)

    static func impact(_ attacks: [Attack], now: Date = .now) -> Impact {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .day, value: -30, to: now) ?? now
        let recent = attacks.filter { $0.start >= cutoff }
        let days = Set(recent.map { cal.startOfDay(for: $0.start) }).count
        var minutes = 0
        for a in recent {
            let endpoint = a.end ?? now
            minutes += max(0, Int(endpoint.timeIntervalSince(a.start) / 60))
        }
        return Impact(headacheDays: days, hoursAffected: Double(minutes) / 60.0)
    }

    // MARK: - Ongoing

    /// The single ongoing attack (most recent start) if one exists.
    static func ongoingAttack(_ attacks: [Attack]) -> Attack? {
        attacks.filter { $0.isOngoing }.max { $0.start < $1.start }
    }
}
