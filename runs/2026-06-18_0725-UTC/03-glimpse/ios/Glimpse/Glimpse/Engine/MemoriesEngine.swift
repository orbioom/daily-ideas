import Foundation

/// A resurfaced memory plus the human reason it surfaced.
struct Memory: Identifiable {
    let id: UUID
    let moment: Moment
    let reason: String
    var sortDate: Date { moment.displayDate }
}

/// "On this day" + time-ago resurfacing. Pure over a moment list.
enum MemoriesEngine {
    /// Moments from prior years whose month/day match today.
    static func onThisDay(moments: [Moment], today: Date = Date(), calendar: Calendar = .current) -> [Memory] {
        let todayComps = calendar.dateComponents([.month, .day], from: today)
        let thisYear = calendar.component(.year, from: today)
        return moments.compactMap { moment -> Memory? in
            let date = moment.displayDate
            let comps = calendar.dateComponents([.month, .day, .year], from: date)
            guard comps.month == todayComps.month, comps.day == todayComps.day else { return nil }
            guard let year = comps.year, year < thisYear else { return nil }
            let delta = thisYear - year
            let reason = delta == 1 ? "1 year ago today" : "\(delta) years ago today"
            return Memory(id: moment.id, moment: moment, reason: reason)
        }
        .sorted { $0.sortDate > $1.sortDate }
    }

    /// "N weeks / months ago" resurfacing — picks moments that land close to
    /// round time-ago anchors (1, 2, 4 weeks; 1, 3, 6 months).
    static func timeAgo(moments: [Moment], today: Date = Date(), calendar: Calendar = .current) -> [Memory] {
        let anchors: [(component: Calendar.Component, value: Int, label: String)] = [
            (.weekOfYear, 1, "1 week ago"),
            (.weekOfYear, 2, "2 weeks ago"),
            (.month, 1, "1 month ago"),
            (.month, 3, "3 months ago"),
            (.month, 6, "6 months ago")
        ]
        var results: [Memory] = []
        var usedIds = Set<UUID>()
        for anchor in anchors {
            guard let target = calendar.date(byAdding: anchor.component, value: -anchor.value, to: today) else { continue }
            let targetStart = calendar.startOfDay(for: target)
            // Find the closest moment within +/- 2 days of the anchor.
            let candidate = moments
                .filter { !usedIds.contains($0.id) }
                .map { (moment: $0, dist: abs((calendar.dateComponents([.day], from: targetStart, to: calendar.startOfDay(for: $0.displayDate)).day ?? 99))) }
                .filter { $0.dist <= 2 }
                .min { $0.dist < $1.dist }
            if let candidate {
                usedIds.insert(candidate.moment.id)
                results.append(Memory(id: candidate.moment.id, moment: candidate.moment, reason: anchor.label))
            }
        }
        return results
    }

    /// A single deterministic-per-day "random" pick, weighted toward favorites.
    static func dailyPick(moments: [Moment], today: Date = Date()) -> Memory? {
        guard !moments.isEmpty else { return nil }
        let pool = moments.filter { $0.isFavorite }.isEmpty ? moments : moments.filter { $0.isFavorite }
        // Seed from the day key so the pick is stable across the day.
        let seed = DayKey.key(for: today).hashValue
        let index = abs(seed) % pool.count
        let moment = pool[index]
        return Memory(id: moment.id, moment: moment, reason: "A glimpse worth revisiting")
    }
}
