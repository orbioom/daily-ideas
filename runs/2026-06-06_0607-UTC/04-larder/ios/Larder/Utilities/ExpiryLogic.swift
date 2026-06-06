import Foundation

/// Pure, testable logic for the larder: expiry bucketing, low-stock detection, and
/// shopping-list generation (auto + manual merge with de-dupe). No SwiftData or UI
/// here — callers pass in plain values, so each function is easy to reason about and
/// safe on user paths (no force-unwraps, no unguarded division).
enum ExpiryLogic {

    /// Where an item sits relative to its expiry/best-before date and the user's window.
    enum Bucket: Int, CaseIterable {
        case expired   // date is in the past
        case soon      // within the configured "expiring soon" window
        case fresh     // beyond the window
        case none      // no expiry date set

        var title: String {
            switch self {
            case .expired: return "Expired"
            case .soon:    return "Use soon"
            case .fresh:   return "Fresh"
            case .none:    return "No date"
            }
        }

        /// Paired SF Symbol so expiry is never conveyed by color alone (accessibility).
        var icon: String {
            switch self {
            case .expired: return "exclamationmark.triangle.fill"
            case .soon:    return "clock.fill"
            case .fresh:   return "checkmark.seal.fill"
            case .none:    return "calendar"
            }
        }
    }

    /// Whole days from `today` (start of day) to the `expiry` (start of day).
    /// Negative when already past. `nil` when there is no expiry date.
    static func daysUntil(_ expiry: Date?, from today: Date = .now,
                          calendar: Calendar = .current) -> Int? {
        guard let expiry else { return nil }
        let start = calendar.startOfDay(for: today)
        let end = calendar.startOfDay(for: expiry)
        let comps = calendar.dateComponents([.day], from: start, to: end)
        return comps.day
    }

    /// Buckets an expiry date against the configured soon-window (in days).
    static func bucket(for expiry: Date?, windowDays: Int, from today: Date = .now,
                       calendar: Calendar = .current) -> Bucket {
        guard let days = daysUntil(expiry, from: today, calendar: calendar) else {
            return .none
        }
        if days < 0 { return .expired }
        if days <= max(0, windowDays) { return .soon }
        return .fresh
    }

    /// Short human phrase for a days-until value (monospaced digits in the UI).
    /// e.g. "2 days left", "expired 1 day ago", "today".
    static func relativePhrase(forDaysUntil days: Int?) -> String {
        guard let days else { return "No date" }
        if days == 0 { return "Today" }
        if days > 0 {
            return days == 1 ? "1 day left" : "\(days) days left"
        }
        let ago = -days
        return ago == 1 ? "Expired 1 day ago" : "Expired \(ago) days ago"
    }

    // MARK: - Low stock

    /// True when quantity is at or below the threshold (threshold treated as a floor).
    static func isLowStock(quantity: Double, threshold: Double) -> Bool {
        quantity <= max(0, threshold)
    }

    // MARK: - Shopping list generation

    /// A row presented on the shopping list, after merging auto (low-stock) and manual.
    struct Row: Identifiable, Hashable {
        var id: UUID
        var name: String
        var detail: String
        var isManual: Bool
        var isChecked: Bool
        /// Source item id for auto rows (enables restock on check-off).
        var itemID: UUID?
    }

    /// Builds the displayed shopping list by merging:
    ///   1. persisted manual + already-generated entries (`stored`), and
    ///   2. freshly detected low-stock items (`lowStockItems`),
    /// de-duplicating by normalized name. A stored entry wins over a fresh auto row of
    /// the same name (so a checked state is preserved), and we never emit duplicates.
    ///
    /// `lowStockItems` is a list of (id, name, suggestedDetail) for items currently low.
    static func mergeRows(stored: [Row], lowStockItems: [(id: UUID, name: String, detail: String)]) -> [Row] {
        var byKey: [String: Row] = [:]
        var order: [String] = []

        func key(_ name: String) -> String {
            name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        // Stored entries first — they hold check state and manual rows.
        for row in stored {
            let k = key(row.name)
            guard !k.isEmpty else { continue }
            if byKey[k] == nil { order.append(k) }
            byKey[k] = row
        }

        // Fold in fresh low-stock detections that aren't already represented.
        for low in lowStockItems {
            let k = key(low.name)
            guard !k.isEmpty else { continue }
            if byKey[k] != nil { continue }
            order.append(k)
            byKey[k] = Row(id: UUID(), name: low.name, detail: low.detail,
                           isManual: false, isChecked: false, itemID: low.id)
        }

        return order.compactMap { byKey[$0] }
    }
}
